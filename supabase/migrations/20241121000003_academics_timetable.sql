-- ============================================================================
-- KSMS Migration 0003 — Academics: Years, Terms, Classes, Subjects, Staff,
-- Teacher Assignments, Timetable (conflict-safe), Homework
-- ============================================================================

create type homework_status as enum ('DRAFT','PUBLISHED');

create table public.academic_years (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  start_date date not null,
  end_date date not null,
  is_current boolean not null default false,
  created_at timestamptz not null default now(),
  unique (tenant_id, name),
  constraint academic_years_dates check (end_date > start_date)
);

create table public.terms (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  academic_year_id uuid not null references public.academic_years(id) on delete cascade,
  name text not null,
  start_date date not null,
  end_date date not null,
  is_current boolean not null default false,
  unique (academic_year_id, name),
  constraint terms_dates check (end_date > start_date)
);

create table public.grading_scales (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  bounds jsonb not null, -- [{min:90,grade:"A+",remark:"Outstanding"},...]
  unique (tenant_id, name),
  constraint grading_bounds_shape check (jsonb_typeof(bounds) = 'array')
);

create table public.holidays (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid references public.campuses(id) on delete cascade,
  holiday_date date not null,
  name text not null,
  unique (tenant_id, coalesce(campus_id, '00000000-0000-0000-0000-000000000000'::uuid), holiday_date, name)
);

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  numeric_level int not null,
  created_at timestamptz not null default now(),
  unique (tenant_id, name)
);

create table public.sections (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  name text not null,
  capacity int not null default 40,
  created_at timestamptz not null default now(),
  unique (campus_id, class_id, name)
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  code text not null,
  is_elective boolean not null default false,
  unique (tenant_id, code)
);

create table public.staff (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid references public.campuses(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  employee_code text not null,
  full_name text not null,
  designation text,
  qualification text,
  phone text,
  cnic text,
  joined_on date,
  base_salary numeric(12,2),
  status text not null default 'ACTIVE' check (status in ('ACTIVE','ON_LEAVE','LEFT')),
  created_at timestamptz not null default now(),
  unique (tenant_id, employee_code)
);
create index staff_tenant_idx on public.staff (tenant_id);
create unique index staff_user_unique on public.staff (user_id) where user_id is not null;

create table public.teacher_assignments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  academic_year_id uuid not null references public.academic_years(id) on delete cascade,
  term_id uuid references public.terms(id) on delete set null,
  staff_id uuid not null references public.staff(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  section_id uuid not null references public.sections(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  weekly_periods int not null default 6,
  created_at timestamptz not null default now(),
  unique (section_id, subject_id, academic_year_id, coalesce(term_id, '00000000-0000-0000-0000-000000000000'::uuid))
);
create index teacher_assignments_staff_idx on public.teacher_assignments (staff_id);

-- ---------------------------------------------------------------------------
-- Timetable slots + conflict prevention
-- ---------------------------------------------------------------------------
create table public.timetable_slots (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  academic_year_id uuid not null references public.academic_years(id) on delete cascade,
  term_id uuid references public.terms(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  section_id uuid not null references public.sections(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  staff_id uuid not null references public.staff(id) on delete cascade,
  day_of_week int not null check (day_of_week between 1 and 7),
  period int not null check (period between 1 and 12),
  room text not null,
  created_at timestamptz not null default now(),
  unique (section_id, academic_year_id, coalesce(term_id, '00000000-0000-0000-0000-000000000000'::uuid), day_of_week, period)
);
create index timetable_staff_idx on public.timetable_slots (staff_id, day_of_week, period);

create or replace function public.assert_timetable_no_conflict()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_self uuid := coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid);
        v_term uuid := coalesce(new.term_id, '00000000-0000-0000-0000-000000000000'::uuid);
begin
  if exists (
    select 1 from public.timetable_slots t
    where t.id is distinct from v_self
      and t.tenant_id = new.tenant_id
      and t.academic_year_id = new.academic_year_id
      and coalesce(t.term_id, '00000000-0000-0000-0000-000000000000'::uuid) = v_term
      and t.day_of_week = new.day_of_week and t.period = new.period
      and t.staff_id = new.staff_id
  ) then
    raise exception 'TIMETABLE_CONFLICT: teacher already booked in this slot';
  end if;

  if exists (
    select 1 from public.timetable_slots t
    where t.id is distinct from v_self
      and t.tenant_id = new.tenant_id
      and t.academic_year_id = new.academic_year_id
      and coalesce(t.term_id, '00000000-0000-0000-0000-000000000000'::uuid) = v_term
      and t.day_of_week = new.day_of_week and t.period = new.period
      and t.campus_id = new.campus_id
      and lower(t.room) = lower(new.room)
  ) then
    raise exception 'TIMETABLE_CONFLICT: room already occupied in this slot';
  end if;

  if exists (
    select 1 from public.timetable_slots t
    where t.id is distinct from v_self
      and t.tenant_id = new.tenant_id
      and t.academic_year_id = new.academic_year_id
      and coalesce(t.term_id, '00000000-0000-0000-0000-000000000000'::uuid) = v_term
      and t.day_of_week = new.day_of_week and t.period = new.period
      and t.section_id = new.section_id
  ) then
    raise exception 'TIMETABLE_CONFLICT: section already has a lesson in this slot';
  end if;

  return new;
end;
$$;

create trigger timetable_conflict_guard
  before insert or update on public.timetable_slots
  for each row execute function public.assert_timetable_no_conflict();

-- ---------------------------------------------------------------------------
-- Homework
-- ---------------------------------------------------------------------------
create table public.homework (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  academic_year_id uuid not null references public.academic_years(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  section_id uuid not null references public.sections(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  staff_id uuid not null references public.staff(id) on delete cascade,
  title text not null,
  description text,
  assigned_on date not null default current_date,
  due_on date not null,
  attachment_paths text[] not null default '{}',
  status homework_status not null default 'DRAFT',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index homework_section_idx on public.homework (section_id, assigned_on desc);
create trigger homework_touch before update on public.homework
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.academic_years enable row level security;
alter table public.terms enable row level security;
alter table public.grading_scales enable row level security;
alter table public.holidays enable row level security;
alter table public.classes enable row level security;
alter table public.sections enable row level security;
alter table public.subjects enable row level security;
alter table public.staff enable row level security;
alter table public.teacher_assignments enable row level security;
alter table public.timetable_slots enable row level security;
alter table public.homework enable row level security;

-- Reference data: readable by any member of the tenant (incl. parents/students)
create policy academic_years_select on public.academic_years for select to authenticated using (
  tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null)
  or app.is_platform_admin()
);
create policy academic_years_write on public.academic_years for insert to authenticated with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);
create policy academic_years_update on public.academic_years for update to authenticated using (
  app.has_tenant_permission('academics.manage', tenant_id)
) with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);

create policy terms_select on public.terms for select to authenticated using (
  tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null)
  or app.is_platform_admin()
);
create policy terms_write on public.terms for insert to authenticated with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);
create policy terms_update on public.terms for update to authenticated using (
  app.has_tenant_permission('academics.manage', tenant_id)
) with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);

create policy grading_scales_select on public.grading_scales for select to authenticated using (
  tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null)
);
create policy grading_scales_write on public.grading_scales for insert to authenticated with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);
create policy grading_scales_update on public.grading_scales for update to authenticated using (
  app.has_tenant_permission('academics.manage', tenant_id)
) with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);

create policy holidays_select on public.holidays for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  or (campus_id is null and tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null))
);
create policy holidays_write on public.holidays for insert to authenticated with check (
  app.has_tenant_permission('academics.manage', tenant_id)
  and (campus_id is null or app.can_access_campus(tenant_id, campus_id))
);
create policy holidays_delete on public.holidays for delete to authenticated using (
  app.has_tenant_permission('academics.manage', tenant_id)
);

create policy classes_select on public.classes for select to authenticated using (
  tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null)
  or app.is_platform_admin()
);
create policy classes_write on public.classes for insert to authenticated with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);
create policy classes_update on public.classes for update to authenticated using (
  app.has_tenant_permission('academics.manage', tenant_id)
) with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);

create policy sections_select on public.sections for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy sections_write on public.sections for insert to authenticated with check (
  app.has_tenant_permission('academics.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy sections_update on public.sections for update to authenticated using (
  app.has_tenant_permission('academics.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
) with check (
  app.has_tenant_permission('academics.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);

create policy subjects_select on public.subjects for select to authenticated using (
  tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null)
);
create policy subjects_write on public.subjects for insert to authenticated with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);
create policy subjects_update on public.subjects for update to authenticated using (
  app.has_tenant_permission('academics.manage', tenant_id)
) with check (
  app.has_tenant_permission('academics.manage', tenant_id)
);

create policy staff_select on public.staff for select to authenticated using (
  exists (
    select 1 from app.active_memberships() am
    where am.tenant_id = staff.tenant_id and am.role_key not in ('parent','student')
  )
  or user_id = app.jwt_uid()
);
create policy staff_insert on public.staff for insert to authenticated with check (
  app.has_tenant_permission('hr.manage', tenant_id)
);
create policy staff_update on public.staff for update to authenticated using (
  app.has_tenant_permission('hr.manage', tenant_id)
) with check (
  app.has_tenant_permission('hr.manage', tenant_id)
);

create policy teacher_assignments_select on public.teacher_assignments for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy teacher_assignments_write on public.teacher_assignments for insert to authenticated with check (
  app.has_tenant_permission('assignments.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy teacher_assignments_update on public.teacher_assignments for update to authenticated using (
  app.has_tenant_permission('assignments.manage', tenant_id)
) with check (
  app.has_tenant_permission('assignments.manage', tenant_id)
);
create policy teacher_assignments_delete on public.teacher_assignments for delete to authenticated using (
  app.has_tenant_permission('assignments.manage', tenant_id)
);

create policy timetable_select on public.timetable_slots for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy timetable_write on public.timetable_slots for insert to authenticated with check (
  app.has_tenant_permission('timetable.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy timetable_update on public.timetable_slots for update to authenticated using (
  app.has_tenant_permission('timetable.manage', tenant_id)
) with check (
  app.has_tenant_permission('timetable.manage', tenant_id)
);
create policy timetable_delete on public.timetable_slots for delete to authenticated using (
  app.has_tenant_permission('timetable.manage', tenant_id)
);

create policy homework_select on public.homework for select to authenticated using (
  (
    app.has_tenant_permission('students.read', tenant_id)
    and app.can_access_campus(tenant_id, campus_id)
  )
  or exists (
    select 1 from public.teacher_assignments ta
    join public.staff s on s.id = ta.staff_id
    where ta.section_id = homework.section_id and ta.subject_id = homework.subject_id and s.user_id = app.jwt_uid()
  )
  or exists (
    select 1 from public.enrollments e
    where e.section_id = homework.section_id
      and (app.is_self_student(e.student_id) or app.is_guardian_of(e.student_id))
  )
);

create policy homework_insert on public.homework for insert to authenticated with check (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('homework.write', tenant_id)
    or exists (
      select 1 from public.teacher_assignments ta
      join public.staff s on s.id = ta.staff_id
      where ta.section_id = homework.section_id
        and ta.subject_id = homework.subject_id
        and ta.academic_year_id = homework.academic_year_id
        and s.user_id = app.jwt_uid()
    )
  )
);

create policy homework_update on public.homework for update to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('homework.write', tenant_id)
    or exists (
      select 1 from public.teacher_assignments ta
      join public.staff s on s.id = ta.staff_id
      where ta.section_id = homework.section_id
        and ta.subject_id = homework.subject_id
        and s.user_id = app.jwt_uid()
    )
  )
) with check (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('homework.write', tenant_id)
    or exists (
      select 1 from public.teacher_assignments ta
      join public.staff s on s.id = ta.staff_id
      where ta.section_id = homework.section_id
        and ta.subject_id = homework.subject_id
        and s.user_id = app.jwt_uid()
    )
  )
);
