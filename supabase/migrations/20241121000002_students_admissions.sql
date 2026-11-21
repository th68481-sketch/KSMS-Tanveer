-- ============================================================================
-- KSMS Migration 0002 — Students, Guardians, Admissions, Documents
-- ============================================================================

create type student_status as enum ('ACTIVE','PROMOTED','TRANSFERRED','WITHDRAWN','GRADUATED','ALUMNUS','LEFT');
create type admission_stage as enum ('ENQUIRY','APPLIED','DOCUMENTS_PENDING','UNDER_REVIEW','APPROVED','REJECTED','ENROLLED','WITHDRAWN');
create type guardian_relationship as enum ('FATHER','MOTHER','GUARDIAN','OTHER');
create type document_owner_kind as enum ('STUDENT','STAFF','ACCESS_REQUEST','EXPENSE','OTHER');

-- ---------------------------------------------------------------------------
-- Documents (private storage metadata; used by admissions, HR, expenses)
-- ---------------------------------------------------------------------------
create table public.documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  campus_id uuid references public.campuses(id) on delete cascade,
  owner_kind document_owner_kind not null,
  owner_id uuid not null,
  bucket text not null default 'private-documents',
  path text not null,
  filename text not null,
  mime_type text,
  size_bytes bigint,
  sha256 text,
  uploaded_by uuid references auth.users(id) on delete set null,
  uploaded_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index documents_owner_idx on public.documents (owner_kind, owner_id);

-- ---------------------------------------------------------------------------
-- Students
-- ---------------------------------------------------------------------------
create table public.students (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  admission_no text not null,
  full_name text not null,
  name_parts jsonb not null default '{}'::jsonb,
  gender text not null check (gender in ('MALE','FEMALE','OTHER')),
  date_of_birth date not null,
  birth_cert_no text,
  b_form_no text,
  religion text,
  blood_group text,
  address text,
  photo_path text,
  user_id uuid references auth.users(id) on delete set null,
  status student_status not null default 'ACTIVE',
  merged_into uuid references public.students(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, admission_no)
);
create index students_tenant_name_idx on public.students (tenant_id, lower(full_name));
create index students_tenant_campus_idx on public.students (tenant_id, campus_id);
create trigger students_touch before update on public.students
  for each row execute function public.touch_updated_at();

create or replace function public.gen_admission_no()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_seq bigint;
begin
  if new.admission_no is not null and new.admission_no <> '' then return new; end if;
  select coalesce(max(nullif(split_part(admission_no,'-',1),'')::bigint), 0) + 1
    into v_seq
  from public.students where tenant_id = new.tenant_id and admission_no like '%-%';
  new.admission_no := lpad(v_seq::text, 5, '0');
  return new;
end;
$$;
create trigger students_gen_no before insert on public.students
  for each row execute function public.gen_admission_no();

-- ---------------------------------------------------------------------------
-- Guardians & links
-- ---------------------------------------------------------------------------
create table public.guardians (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  full_name text not null,
  cnic text,
  phone text not null,
  email text,
  occupation text,
  address text,
  user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (tenant_id, phone)
);
create index guardians_tenant_idx on public.guardians (tenant_id);
create index guardians_user_idx on public.guardians (user_id);

create table public.student_guardians (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  guardian_id uuid not null references public.guardians(id) on delete cascade,
  relationship guardian_relationship not null,
  is_primary boolean not null default false,
  can_pickup boolean not null default false,
  portal_access boolean not null default false,
  verified boolean not null default false,
  verification_method text check (verification_method in ('CNIC_MATCH','IN_PERSON','DOCUMENT','NONE')),
  created_at timestamptz not null default now(),
  unique (student_id, guardian_id)
);
create index student_guardians_tenant_idx on public.student_guardians (tenant_id);
create unique index student_guardians_one_primary on public.student_guardians (student_id) where is_primary;

-- ---------------------------------------------------------------------------
-- Admissions pipeline
-- ---------------------------------------------------------------------------
create table public.admissions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  application_no text not null,
  stage admission_stage not null default 'ENQUIRY',
  student_id uuid references public.students(id) on delete set null,
  applicant_name text not null,
  applicant_dob date,
  applicant_gender text check (applicant_gender in ('MALE','FEMALE','OTHER')),
  guardian_name text,
  guardian_phone text,
  guardian_cnic text,
  class_applied_id uuid,
  academic_year_id uuid,
  checklist jsonb not null default '{}'::jsonb,
  details jsonb not null default '{}'::jsonb,
  assigned_to uuid references auth.users(id) on delete set null,
  decided_by uuid references auth.users(id) on delete set null,
  decided_at timestamptz,
  decision_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, application_no)
);
create index admissions_tenant_stage_idx on public.admissions (tenant_id, stage, created_at desc);

create or replace function public.gen_application_no()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_seq bigint;
begin
  if new.application_no is not null and new.application_no <> '' then return new; end if;
  select coalesce(max(nullif(split_part(application_no,'-',2),'')::bigint),0) + 1
    into v_seq
  from public.admissions where tenant_id = new.tenant_id;
  new.application_no := 'APP-' || lpad(v_seq::text, 6, '0');
  return new;
end;
$$;
create trigger admissions_gen_no before insert on public.admissions
  for each row execute function public.gen_application_no();

-- ---------------------------------------------------------------------------
-- Enrollments (historical record per year/class/section)
-- ---------------------------------------------------------------------------
create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  academic_year_id uuid,
  class_id uuid,
  section_id uuid,
  roll_no int,
  admission_date date not null default current_date,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','COMPLETED','PROMOTED','TRANSFERRED','WITHDRAWN')),
  previous_enrollment_id uuid references public.enrollments(id) on delete set null,
  leaving_certificate_no text,
  leaving_date date,
  leaving_reason text,
  created_at timestamptz not null default now(),
  unique (student_id, academic_year_id)
);
create index enrollments_tenant_year_idx on public.enrollments (tenant_id, academic_year_id);
create index enrollments_section_idx on public.enrollments (section_id);
create unique index enrollments_roll_unique on public.enrollments (section_id, roll_no) where roll_no is not null and status = 'ACTIVE';

-- ---------------------------------------------------------------------------
-- RLS helper: portal scoping
-- ---------------------------------------------------------------------------
create or replace function app.my_children_ids()
returns setof uuid
language sql stable security definer set search_path = public as $$
  select sg.student_id
  from public.student_guardians sg
  join public.guardians g on g.id = sg.guardian_id
  where g.user_id = app.jwt_uid() and sg.portal_access
$$;

create or replace function app.my_student_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select id from public.students where user_id = app.jwt_uid()
$$;

create or replace function app.is_guardian_of(p_student uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.student_guardians sg
    join public.guardians g on g.id = sg.guardian_id
    where sg.student_id = p_student and g.user_id = app.jwt_uid() and sg.portal_access
  )
$$;

create or replace function app.is_self_student(p_student uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.students s where s.id = p_student and s.user_id = app.jwt_uid())
$$;

-- ---------------------------------------------------------------------------
-- Duplicate detection (trigram similarity)
-- ---------------------------------------------------------------------------
create or replace function app.find_duplicate_students(
  p_tenant uuid, p_name text, p_dob date default null, p_b_form text default null
) returns setof public.students
language sql stable security definer set search_path = public as $$
  select s.* from public.students s
  where s.tenant_id = p_tenant
    and s.merged_into is null
    and (
      (p_b_form is not null and s.b_form_no = p_b_form)
      or (p_dob is not null and s.date_of_birth = p_dob and similarity(lower(s.full_name), lower(p_name)) > 0.6)
      or similarity(lower(s.full_name), lower(p_name)) > 0.85
    )
  order by similarity(lower(s.full_name), lower(p_name)) desc
$$;

grant execute on function app.find_duplicate_students(uuid, text, date, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Merge duplicate students (trusted; requires students.merge)
-- ---------------------------------------------------------------------------
create or replace function app.merge_students(p_keep uuid, p_duplicate uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare v_tenant uuid;
begin
  if not app.has_permission('students.merge') then
    raise exception 'FORBIDDEN';
  end if;

  select tenant_id into v_tenant from public.students where id = p_keep;
  if v_tenant is null then raise exception 'STUDENT_NOT_FOUND'; end if;

  if not exists (select 1 from public.students d where d.id = p_duplicate and d.tenant_id = v_tenant and d.merged_into is null and d.id <> p_keep) then
    raise exception 'INVALID_MERGE_SOURCE';
  end if;

  update public.student_guardians set student_id = p_keep where student_id = p_duplicate;
  update public.admissions set student_id = p_keep where student_id = p_duplicate;
  update public.enrollments e set student_id = p_keep
    where e.student_id = p_duplicate
      and not exists (select 1 from public.enrollments x where x.student_id = p_keep and x.academic_year_id = e.academic_year_id);
  delete from public.enrollments where student_id = p_duplicate;
  update public.students set merged_into = p_keep, status = 'LEFT' where id = p_duplicate;

  perform app.write_audit('students.merge','students',p_keep,
    jsonb_build_object('merged_from', p_duplicate), v_tenant);
end;
$$;

grant execute on function app.merge_students(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Finalize admission -> student + enrollment + guardian links (atomic)
-- ---------------------------------------------------------------------------
create or replace function app.finalize_admission(
  p_admission uuid, p_class uuid, p_section uuid, p_academic_year uuid, p_roll int default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_adm public.admissions%rowtype;
  v_student uuid;
  v_enrollment uuid;
  v_guardian uuid;
  v_adm_no text;
begin
  if not app.has_permission('admissions.write') then raise exception 'FORBIDDEN'; end if;

  select * into v_adm from public.admissions where id = p_admission;
  if v_adm.id is null then raise exception 'ADMISSION_NOT_FOUND'; end if;
  if v_adm.stage <> 'APPROVED' then raise exception 'ADMISSION_NOT_APPROVED'; end if;
  if v_adm.student_id is not null then return v_adm.student_id; end if;

  if not app.can_access_campus(v_adm.tenant_id, v_adm.campus_id) then raise exception 'FORBIDDEN'; end if;

  loop
    v_adm_no := 'ADM-' || to_char(now(),'YYMMDD') || '-' || substr(md5(random()::text), 1, 6);
    begin
      insert into public.students (tenant_id, campus_id, admission_no, full_name, gender, date_of_birth, b_form_no, address)
      values (v_adm.tenant_id, v_adm.campus_id, v_adm_no, v_adm.applicant_name,
              coalesce(v_adm.applicant_gender,'OTHER'), v_adm.applicant_dob, v_adm.guardian_cnic, v_adm.details ->> 'address')
      returning id into v_student;
      exit;
    exception when unique_violation then
      continue;
    end;
  end loop;

  insert into public.enrollments (tenant_id, campus_id, student_id, academic_year_id, class_id, section_id, roll_no)
  values (v_adm.tenant_id, v_adm.campus_id, v_student, p_academic_year, p_class, p_section, p_roll)
  returning id into v_enrollment;

  if v_adm.guardian_name is not null and v_adm.guardian_phone is not null then
    insert into public.guardians (tenant_id, full_name, phone, cnic)
    values (v_adm.tenant_id, v_adm.guardian_name, v_adm.guardian_phone, v_adm.guardian_cnic)
    on conflict (tenant_id, phone) do update set full_name = excluded.full_name
    returning id into v_guardian;

    insert into public.student_guardians (tenant_id, student_id, guardian_id, relationship, is_primary, can_pickup, portal_access, verified)
    values (v_adm.tenant_id, v_student, v_guardian,
            case when v_adm.details ->> 'relationship' in ('FATHER','MOTHER','GUARDIAN','OTHER')
                 then (v_adm.details ->> 'relationship')::guardian_relationship else 'GUARDIAN' end,
            true, true, true, false)
    on conflict (student_id, guardian_id) do nothing;
  end if;

  update public.admissions
     set stage = 'ENROLLED', student_id = v_student, decided_by = app.jwt_uid(), decided_at = now()
   where id = p_admission;

  perform app.write_audit('admissions.finalized','students',v_student,
    jsonb_build_object('admission', p_admission, 'enrollment', v_enrollment), v_adm.tenant_id, v_adm.campus_id);

  return v_student;
end;
$$;

grant execute on function app.finalize_admission(uuid, uuid, uuid, uuid, int) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.documents enable row level security;
alter table public.students enable row level security;
alter table public.guardians enable row level security;
alter table public.student_guardians enable row level security;
alter table public.admissions enable row level security;
alter table public.enrollments enable row level security;

create policy documents_select on public.documents for select to authenticated using (
  uploaded_by = app.jwt_uid()
  or (tenant_id is not null and app.can_access_campus(tenant_id, campus_id))
  or (owner_kind = 'ACCESS_REQUEST' and exists (
        select 1 from public.access_requests ar
        where ar.id = documents.owner_id
          and (ar.requester_user_id = app.jwt_uid() or app.is_platform_admin()
               or (app.is_gov_admin() and ar.institution_type = 'GOVERNMENT'))
      ))
);

create policy documents_insert on public.documents for insert to authenticated with check (
  uploaded_by = app.jwt_uid()
  and (
    (owner_kind = 'ACCESS_REQUEST' and tenant_id is null)
    or (tenant_id is not null and app.can_access_campus(tenant_id, campus_id))
  )
);

create policy documents_soft_delete on public.documents for update to authenticated using (
  uploaded_by = app.jwt_uid()
  or (tenant_id is not null and app.can_access_campus(tenant_id, campus_id))
) with check (
  uploaded_by = app.jwt_uid()
  or (tenant_id is not null and app.can_access_campus(tenant_id, campus_id))
);

create policy students_select on public.students for select to authenticated using (
  (
    app.has_tenant_permission('students.read', tenant_id)
    and app.can_access_campus(tenant_id, campus_id)
  )
  or app.is_self_student(id)
  or app.is_guardian_of(id)
  or (app.is_gov_admin() and app.can_access_gov_tenant(tenant_id))
);

create policy students_insert on public.students for insert to authenticated with check (
  app.has_tenant_permission('students.write', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);

create policy students_update on public.students for update to authenticated using (
  app.has_tenant_permission('students.write', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
) with check (
  app.has_tenant_permission('students.write', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
-- No DELETE policy: students are withdrawn / merged, never hard-deleted by clients.

create policy guardians_select on public.guardians for select to authenticated using (
  app.has_tenant_permission('students.read', tenant_id)
  or user_id = app.jwt_uid()
);

create policy guardians_write on public.guardians for insert to authenticated with check (
  app.has_tenant_permission('guardians.write', tenant_id)
);

create policy guardians_update on public.guardians for update to authenticated using (
  app.has_tenant_permission('guardians.write', tenant_id)
) with check (
  app.has_tenant_permission('guardians.write', tenant_id)
);

create policy student_guardians_select on public.student_guardians for select to authenticated using (
  app.has_tenant_permission('students.read', tenant_id)
  or exists (select 1 from public.guardians g where g.id = guardian_id and g.user_id = app.jwt_uid())
);

create policy student_guardians_write on public.student_guardians for insert to authenticated with check (
  app.has_tenant_permission('guardians.write', tenant_id)
);

create policy student_guardians_update on public.student_guardians for update to authenticated using (
  app.has_tenant_permission('guardians.write', tenant_id)
) with check (
  app.has_tenant_permission('guardians.write', tenant_id)
);

create policy admissions_select on public.admissions for select to authenticated using (
  (
    app.has_tenant_permission('students.read', tenant_id)
    and app.can_access_campus(tenant_id, campus_id)
  )
  or assigned_to = app.jwt_uid()
  or (app.is_gov_admin() and app.can_access_gov_tenant(tenant_id))
);

create policy admissions_insert on public.admissions for insert to authenticated with check (
  app.has_tenant_permission('admissions.write', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);

create policy admissions_update on public.admissions for update to authenticated using (
  app.has_tenant_permission('admissions.write', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
) with check (
  app.has_tenant_permission('admissions.write', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);

create policy enrollments_select on public.enrollments for select to authenticated using (
  (
    app.has_tenant_permission('students.read', tenant_id)
    and app.can_access_campus(tenant_id, campus_id)
  )
  or exists (select 1 from public.students s where s.id = student_id and (app.is_self_student(s.id) or app.is_guardian_of(s.id)))
  or (app.is_gov_admin() and app.can_access_gov_tenant(tenant_id))
);

create policy enrollments_insert on public.enrollments for insert to authenticated with check (
  app.has_tenant_permission('students.write', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);

create policy enrollments_update on public.enrollments for update to authenticated using (
  app.has_tenant_permission('students.write', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
) with check (
  app.has_tenant_permission('students.write', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
