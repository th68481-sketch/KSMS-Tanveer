-- ============================================================================
-- KSMS Migration 0005 — Examinations, Marks, Report Cards
-- ============================================================================

create type exam_kind as enum ('UNIT','MIDTERM','FINAL','CUSTOM');
create type exam_status as enum ('DRAFT','SCHEDULED','ACTIVE','CLOSED');
create type mark_state as enum ('DRAFT','REVIEWED','APPROVED','PUBLISHED');
create type report_card_state as enum ('DRAFT','PUBLISHED');

create table public.exams (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  academic_year_id uuid not null references public.academic_years(id) on delete cascade,
  term_id uuid references public.terms(id) on delete set null,
  name text not null,
  kind exam_kind not null default 'UNIT',
  grading_scale_id uuid references public.grading_scales(id) on delete set null,
  start_date date,
  end_date date,
  status exam_status not null default 'DRAFT',
  result_published boolean not null default false,
  created_at timestamptz not null default now(),
  unique (tenant_id, campus_id, name, academic_year_id)
);

create table public.exam_subjects (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  max_marks numeric(6,2) not null check (max_marks > 0),
  passing_marks numeric(6,2) not null default 40 check (passing_marks >= 0),
  weightage numeric(5,2) not null default 100 check (weightage >= 0),
  exam_date date,
  unique (exam_id, class_id, subject_id)
);

create table public.marks (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  exam_subject_id uuid not null references public.exam_subjects(id) on delete cascade,
  enrollment_id uuid not null references public.enrollments(id) on delete cascade,
  obtained numeric(6,2),
  grade text,
  remarks text,
  state mark_state not null default 'DRAFT',
  entered_by uuid references auth.users(id) on delete set null,
  entered_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  version int not null default 1,
  updated_at timestamptz not null default now(),
  unique (exam_subject_id, enrollment_id)
);
create index marks_enrollment_idx on public.marks (enrollment_id);
create trigger marks_touch before update on public.marks
  for each row execute function public.touch_updated_at();

-- Append-only amendment trail
create table public.marks_amendments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  mark_id uuid not null references public.marks(id) on delete cascade,
  old_value numeric(6,2),
  new_value numeric(6,2),
  reason text not null,
  performed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create trigger marks_amendments_immutable
  before update or delete on public.marks_amendments
  for each row execute function public.block_mutation();

-- Mark state machine guard
create or replace function public.assert_mark_state_transition()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if new.state not in ('DRAFT','REVIEWED') then
      raise exception 'INVALID_MARK_STATE: new marks must start as DRAFT';
    end if;
    return new;
  end if;

  if new.state = old.state and new.obtained is not distinct from old.obtained then
    return new;
  end if;

  if new.state = 'PUBLISHED' and old.state <> 'PUBLISHED' then
    if current_setting('app.publishing', true) is distinct from 'on' then
      raise exception 'FORBIDDEN: publication happens only through the trusted publish flow';
    end if;
    return new;
  end if;

  case new.state
    when 'DRAFT' then
      null; -- editing own draft
    when 'REVIEWED' then
      if not app.has_permission('marks.review') then raise exception 'FORBIDDEN: review permission required'; end if;
      new.reviewed_by := app.jwt_uid();
      new.reviewed_at := now();
    when 'APPROVED' then
      if not app.has_permission('marks.approve') then raise exception 'FORBIDDEN: approval permission required'; end if;
      new.approved_by := app.jwt_uid();
      new.approved_at := now();
    else
      raise exception 'INVALID_MARK_STATE';
  end case;

  -- demoting state requires higher privilege
  if (array_position(array['DRAFT','REVIEWED','APPROVED','PUBLISHED'], old.state::text)
      > array_position(array['DRAFT','REVIEWED','APPROVED','PUBLISHED'], new.state::text)) then
    if not (app.has_permission('marks.approve') or app.has_permission('marks.review')) then
      raise exception 'FORBIDDEN: cannot demote mark state';
    end if;
  end if;

  new.version := old.version + 1;
  return new;
end;
$$;
create trigger marks_state_guard
  before insert or update on public.marks
  for each row execute function public.assert_mark_state_transition();

-- ---------------------------------------------------------------------------
-- Publish results (trusted, atomic): marks -> PUBLISHED + report cards
-- ---------------------------------------------------------------------------
create or replace function app.grade_for(p_tenant uuid, p_scale uuid, p_pct numeric)
returns text
language plpgsql stable security definer set search_path = public as $$
declare v_bounds jsonb; r record;
begin
  if p_pct is null then return null; end if;
  select bounds into v_bounds
  from public.grading_scales
  where id = p_scale
     or (p_scale is null and tenant_id = p_tenant)
  order by (id = p_scale) desc nulls last
  limit 1;

  if v_bounds is null then return null; end if;
  for r in select * from jsonb_array_elements(v_bounds) order by (value->>'min')::numeric desc loop
    if p_pct >= (r.value->>'min')::numeric then return r.value->>'grade'; end if;
  end loop;
  return null;
end;
$$;

create or replace function app.publish_exam_results(p_exam uuid)
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_tenant uuid; v_campus uuid; v_scale uuid; v_count int := 0; e record; m record;
  v_total_obtained numeric; v_total_max numeric; v_pct numeric; v_grade text;
  v_term_id uuid; v_section uuid;
begin
  if not app.has_permission('results.publish') then raise exception 'FORBIDDEN'; end if;

  select tenant_id, campus_id, grading_scale_id, term_id into v_tenant, v_campus, v_scale, v_term_id
  from public.exams where id = p_exam;
  if v_tenant is null then raise exception 'EXAM_NOT_FOUND'; end if;
  if not app.can_access_campus(v_tenant, v_campus) then raise exception 'FORBIDDEN'; end if;

  perform set_config('app.publishing', 'on', true);

  update public.marks set state = 'PUBLISHED'
  where exam_subject_id in (select id from public.exam_subjects where exam_id = p_exam)
    and state = 'APPROVED';

  for e in
    select distinct en.id as enrollment_id, en.section_id, en.campus_id
    from public.enrollments en
    join public.exam_subjects es on es.class_id = en.class_id
    where es.exam_id = p_exam and en.status = 'ACTIVE'
  loop
    v_total_obtained := 0; v_total_max := 0; v_pct := null; v_grade := null;
    for m in
      select ms.obtained, es.max_marks, es.weightage
      from public.marks ms
      join public.exam_subjects es on es.id = ms.exam_subject_id
      where ms.enrollment_id = e.enrollment_id and ms.state = 'PUBLISHED'
    loop
      v_total_obtained := v_total_obtained + coalesce(m.obtained, 0) * (m.weightage / 100.0);
      v_total_max := v_total_max + m.max_marks * (m.weightage / 100.0);
    end loop;

    if v_total_max > 0 then
      v_pct := round(v_total_obtained / v_total_max * 100, 2);
      v_grade := app.grade_for(v_tenant, v_scale, v_pct);
    end if;

    insert into public.report_cards (tenant_id, campus_id, enrollment_id, exam_id, totals, percentage, grade, status, published_at, published_by)
    values (v_tenant, e.campus_id, e.enrollment_id, p_exam,
            jsonb_build_object('obtained', v_total_obtained, 'max', v_total_max),
            v_pct, v_grade, 'PUBLISHED', now(), app.jwt_uid())
    on conflict (exam_id, enrollment_id) do update
      set totals = excluded.totals, percentage = excluded.percentage, grade = excluded.grade,
          status = 'PUBLISHED', published_at = now(), published_by = app.jwt_uid();
    v_count := v_count + 1;
  end loop;

  update public.exams set result_published = true, status = 'CLOSED' where id = p_exam;

  perform app.write_audit('exams.results_published','exams',p_exam,
    jsonb_build_object('report_cards', v_count), v_tenant, v_campus);

  perform set_config('app.publishing', 'off', true);
  return v_count;
end;
$$;

grant execute on function app.publish_exam_results(uuid) to authenticated;

-- Amend a published mark (append-only trail; requires marks.approve)
create or replace function app.amend_mark(p_mark uuid, p_new_value numeric, p_reason text)
returns void
language plpgsql security definer set search_path = public as $$
declare v_old numeric; v_tenant uuid; v_row public.marks%rowtype;
begin
  if not app.has_permission('marks.approve') then raise exception 'FORBIDDEN'; end if;
  if coalesce(p_reason,'') = '' then raise exception 'AMENDMENT_REQUIRES_REASON'; end if;

  select * into v_row from public.marks where id = p_mark;
  if v_row.id is null then raise exception 'MARK_NOT_FOUND'; end if;
  if not app.can_access_campus(v_row.tenant_id, v_row.campus_id) then raise exception 'FORBIDDEN'; end if;

  v_old := v_row.obtained;

  perform set_config('app.publishing', 'on', true);
  update public.marks set obtained = p_new_value, version = version + 1 where id = p_mark;
  perform set_config('app.publishing', 'off', true);

  insert into public.marks_amendments (tenant_id, mark_id, old_value, new_value, reason, performed_by)
  values (v_row.tenant_id, p_mark, v_old, p_new_value, p_reason, app.jwt_uid());

  perform app.write_audit('marks.amended','marks',p_mark,
    jsonb_build_object('from', v_old, 'to', p_new_value, 'reason', p_reason), v_row.tenant_id, v_row.campus_id);
end;
$$;

grant execute on function app.amend_mark(uuid, numeric, text) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.exams enable row level security;
alter table public.exam_subjects enable row level security;
alter table public.marks enable row level security;
alter table public.marks_amendments enable row level security;
alter table public.report_cards enable row level security;

create policy exams_select on public.exams for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  or (app.is_gov_admin() and app.can_access_gov_tenant(tenant_id))
);
create policy exams_write on public.exams for insert to authenticated with check (
  app.has_tenant_permission('exams.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy exams_update on public.exams for update to authenticated using (
  app.has_tenant_permission('exams.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
) with check (
  app.has_tenant_permission('exams.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy exams_delete on public.exams for delete to authenticated using (
  app.has_tenant_permission('exams.manage', tenant_id) and not result_published and status = 'DRAFT'
);

create policy exam_subjects_select on public.exam_subjects for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy exam_subjects_write on public.exam_subjects for insert to authenticated with check (
  app.has_tenant_permission('exams.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy exam_subjects_update on public.exam_subjects for update to authenticated using (
  app.has_tenant_permission('exams.manage', tenant_id)
) with check (
  app.has_tenant_permission('exams.manage', tenant_id)
);
create policy exam_subjects_delete on public.exam_subjects for delete to authenticated using (
  app.has_tenant_permission('exams.manage', tenant_id)
  and not exists (select 1 from public.marks m where m.exam_subject_id = exam_subjects.id)
);

-- Teacher identity helper (inline)
create or replace function app.my_staff_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select id from public.staff where user_id = app.jwt_uid()
$$;

create policy marks_select on public.marks for select to authenticated using (
  (
    app.has_tenant_permission('marks.enter', tenant_id)
    or app.has_tenant_permission('marks.review', tenant_id)
    or app.has_tenant_permission('marks.approve', tenant_id)
    or app.has_tenant_permission('results.publish', tenant_id)
  )
  and app.can_access_campus(tenant_id, campus_id)
  or exists (
    select 1 from public.exam_subjects es
    join public.teacher_assignments ta on ta.subject_id = es.subject_id and ta.class_id = es.class_id
    join public.staff s on s.id = ta.staff_id
    where es.id = marks.exam_subject_id and s.user_id = app.jwt_uid()
  )
  or exists (
    select 1
    from public.report_cards rc
    where rc.exam_id = (select exam_id from public.exam_subjects where id = marks.exam_subject_id)
      and (app.is_guardian_of((select student_id from public.enrollments where id = marks.enrollment_id))
           or app.is_self_student((select student_id from public.enrollments where id = marks.enrollment_id)))
  )
  or (app.is_gov_admin() and app.can_access_gov_tenant(tenant_id))
);

create policy marks_insert on public.marks for insert to authenticated with check (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('marks.enter', tenant_id)
    or exists (
      select 1 from public.exam_subjects es
      join public.teacher_assignments ta on ta.subject_id = es.subject_id and ta.class_id = es.class_id
      join public.staff s on s.id = ta.staff_id
      where es.id = marks.exam_subject_id and s.user_id = app.jwt_uid()
    )
  )
  and entered_by = app.jwt_uid()
  and state in ('DRAFT','REVIEWED')
);

create policy marks_update on public.marks for update to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('marks.enter', tenant_id)
    or app.has_tenant_permission('marks.review', tenant_id)
    or app.has_tenant_permission('marks.approve', tenant_id)
    or exists (
      select 1 from public.exam_subjects es
      join public.teacher_assignments ta on ta.subject_id = es.subject_id and ta.class_id = es.class_id
      join public.staff s on s.id = ta.staff_id
      where es.id = marks.exam_subject_id and s.user_id = app.jwt_uid()
    )
  )
) with check (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('marks.enter', tenant_id)
    or app.has_tenant_permission('marks.review', tenant_id)
    or app.has_tenant_permission('marks.approve', tenant_id)
    or exists (
      select 1 from public.exam_subjects es
      join public.teacher_assignments ta on ta.subject_id = es.subject_id and ta.class_id = es.class_id
      join public.staff s on s.id = ta.staff_id
      where es.id = marks.exam_subject_id and s.user_id = app.jwt_uid()
    )
  )
);

create policy marks_amendments_select on public.marks_amendments for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);

create policy report_cards_select on public.report_cards for select to authenticated using (
  (
    app.has_tenant_permission('students.read', tenant_id)
    and app.can_access_campus(tenant_id, campus_id)
  )
  or (status = 'PUBLISHED' and (
        app.is_guardian_of((select student_id from public.enrollments where id = enrollment_id))
     or app.is_self_student((select student_id from public.enrollments where id = enrollment_id))
  ))
  or (app.is_gov_admin() and app.can_access_gov_tenant(tenant_id))
);
