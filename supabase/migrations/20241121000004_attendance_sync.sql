-- ============================================================================
-- KSMS Migration 0004 — Attendance (online + offline sync) 
-- ============================================================================

create type attendance_status as enum ('PRESENT','ABSENT','LATE','LEAVE','EXCUSED');
create type attendance_session_kind as enum ('MORNING','AFTERNOON','CUSTOM');
create type attendance_session_state as enum ('OPEN','LOCKED','APPROVED');

create table public.attendance_sessions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  section_id uuid not null references public.sections(id) on delete cascade,
  academic_year_id uuid not null references public.academic_years(id) on delete cascade,
  session_date date not null,
  session_kind attendance_session_kind not null default 'MORNING',
  status attendance_session_state not null default 'OPEN',
  marked_by uuid references auth.users(id) on delete set null,
  marked_at timestamptz,
  locked_by uuid references auth.users(id) on delete set null,
  locked_at timestamptz,
  unique (campus_id, section_id, session_date, session_kind)
);
create index attendance_sessions_date_idx on public.attendance_sessions (tenant_id, session_date desc);

create table public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  session_id uuid not null references public.attendance_sessions(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  status attendance_status not null,
  remark text,
  correction_reason text,
  correction_count int not null default 0,
  version int not null default 1,
  recorded_by uuid references auth.users(id) on delete set null,
  recorded_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (session_id, student_id)
);
create index attendance_records_student_idx on public.attendance_records (student_id, recorded_at desc);
create trigger attendance_records_touch before update on public.attendance_records
  for each row execute function public.touch_updated_at();

-- Validate status against tenant configuration (if configured)
create or replace function public.assert_attendance_status_allowed()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_allowed jsonb;
begin
  select settings -> 'attendance_statuses' into v_allowed from public.tenants where id = new.tenant_id;
  if v_allowed is not null and jsonb_typeof(v_allowed) = 'array' and jsonb_array_length(v_allowed) > 0 then
    if not exists (select 1 from jsonb_array_elements_text(v_allowed) e where e = new.status::text) then
      raise exception 'ATTENDANCE_STATUS_NOT_CONFIGURED: %', new.status;
    end if;
  end if;
  return new;
end;
$$;
create trigger attendance_status_guard
  before insert or update on public.attendance_records
  for each row execute function public.assert_attendance_status_allowed();

-- Locked/approved sessions: corrections require permission + reason
create or replace function public.assert_attendance_correction()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_state attendance_session_state;
begin
  if tg_op = 'UPDATE' and new.status is distinct from old.status then
    select status into v_state from public.attendance_sessions where id = new.session_id;
    if v_state in ('LOCKED','APPROVED') then
      if not app.has_permission('attendance.correct') or coalesce(new.correction_reason, '') = '' then
        raise exception 'ATTENDANCE_LOCKED: correction requires permission and a documented reason';
      end if;
      new.correction_count := old.correction_count + 1;
    end if;
  end if;
  return new;
end;
$$;
create trigger attendance_correction_guard
  before update on public.attendance_records
  for each row execute function public.assert_attendance_correction();

-- ---------------------------------------------------------------------------
-- Sync ledger (idempotency for offline queue)
-- ---------------------------------------------------------------------------
create table public.sync_operations (
  id uuid primary key, -- = operation_uuid generated on device
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('ATTENDANCE_UPSERT','ATTENDANCE_BATCH')),
  payload jsonb not null,
  client_version int not null default 1,
  status text not null default 'PROCESSED' check (status in ('PROCESSED','CONFLICT','REJECTED')),
  result jsonb not null default '{}'::jsonb,
  received_at timestamptz not null default now()
);
create index sync_operations_user_idx on public.sync_operations (user_id, received_at desc);

-- ---------------------------------------------------------------------------
-- Attendance day summary (per student per month) used by dashboards & portal
-- ---------------------------------------------------------------------------
create or replace view public.attendance_student_monthly
with (security_invoker = true) as
  select r.tenant_id, r.campus_id, r.student_id,
         date_trunc('month', s.session_date) as month,
         count(*) filter (where r.status = 'PRESENT') as present_days,
         count(*) filter (where r.status = 'ABSENT') as absent_days,
         count(*) filter (where r.status = 'LATE') as late_days,
         count(*) filter (where r.status in ('LEAVE','EXCUSED')) as leave_days,
         count(*) as total_days
  from public.attendance_records r
  join public.attendance_sessions s on s.id = r.session_id
  group by 1,2,3,4;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.attendance_sessions enable row level security;
alter table public.attendance_records enable row level security;
alter table public.sync_operations enable row level security;

create policy attendance_sessions_select on public.attendance_sessions for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  or exists (
    select 1 from public.enrollments e
    where e.section_id = attendance_sessions.section_id
      and (app.is_self_student(e.student_id) or app.is_guardian_of(e.student_id))
  )
);

create policy attendance_sessions_insert on public.attendance_sessions for insert to authenticated with check (
  app.has_tenant_permission('attendance.mark', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
  and marked_by = app.jwt_uid()
);

create policy attendance_sessions_update on public.attendance_sessions for update to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('attendance.mark', tenant_id)
    or (app.has_tenant_permission('attendance.read', tenant_id) and exists (
      select 1 from public.teacher_assignments ta
      join public.staff s on s.id = ta.staff_id
      where ta.section_id = attendance_sessions.section_id and s.user_id = app.jwt_uid()
    ))
  )
) with check (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('attendance.mark', tenant_id)
    or (app.has_tenant_permission('attendance.read', tenant_id) and exists (
      select 1 from public.teacher_assignments ta
      join public.staff s on s.id = ta.staff_id
      where ta.section_id = attendance_sessions.section_id and s.user_id = app.jwt_uid()
    ))
  )
);
-- Session state transitions to APPROVED require principal-level review permission
create or replace function public.assert_attendance_session_state()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'APPROVED' and old.status is distinct from 'APPROVED' then
    if not (app.has_permission('attendance.correct') or app.has_role('principal') or app.has_role('tenant_admin')) then
      raise exception 'FORBIDDEN: only principal-level roles approve attendance sessions';
    end if;
    new.approved_by := app.jwt_uid();
    new.approved_at := now();
  end if;
  return new;
end;
$$;
create trigger attendance_session_state_guard
  before update on public.attendance_sessions
  for each row execute function public.assert_attendance_session_state();

create policy attendance_records_select on public.attendance_records for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  or (app.is_self_student(student_id) or app.is_guardian_of(student_id))
);

create policy attendance_records_write on public.attendance_records for insert to authenticated with check (
  app.has_tenant_permission('attendance.mark', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);

create policy attendance_records_update on public.attendance_records for update to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('attendance.mark', tenant_id)
    or exists (
      select 1 from public.attendance_sessions sess
      join public.teacher_assignments ta on ta.section_id = sess.section_id
      join public.staff s on s.id = ta.staff_id
      where sess.id = attendance_records.session_id and s.user_id = app.jwt_uid()
    )
  )
) with check (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('attendance.mark', tenant_id)
    or exists (
      select 1 from public.attendance_sessions sess
      join public.teacher_assignments ta on ta.section_id = sess.section_id
      join public.staff s on s.id = ta.staff_id
      where sess.id = attendance_records.session_id and s.user_id = app.jwt_uid()
    )
  )
);
-- No DELETE policy: corrections are versioned updates, never removals.

create policy sync_operations_select on public.sync_operations for select to authenticated using (
  user_id = app.jwt_uid()
);
-- Writes to sync_operations happen exclusively through the trusted Edge Function.
