-- ============================================================================
-- KSMS Migration 0008 — HR, Operations, Communications, Notifications
-- ============================================================================

create type staff_attendance_status as enum ('PRESENT','ABSENT','LATE','LEAVE','HALF_DAY');
create type leave_kind as enum ('SICK','CASUAL','ANNUAL','UNPAID','OTHER');
create type leave_state as enum ('PENDING','APPROVED','REJECTED','CANCELLED');
create type payroll_state as enum ('DRAFT','REVIEWED','APPROVED','PAID');
create type loan_state as enum ('OPEN','RETURNED','OVERDUE');
create type maint_state as enum ('OPEN','IN_PROGRESS','RESOLVED');

-- ---------------------------------------------------------------------------
-- Staff attendance & leave
-- ---------------------------------------------------------------------------
create table public.staff_attendance (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  staff_id uuid not null references public.staff(id) on delete cascade,
  work_date date not null,
  status staff_attendance_status not null,
  check_in time,
  check_out time,
  recorded_by uuid references auth.users(id) on delete set null,
  recorded_at timestamptz not null default now(),
  unique (staff_id, work_date)
);
create index staff_attendance_day_idx on public.staff_attendance (tenant_id, work_date desc);

create table public.leave_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  staff_id uuid not null references public.staff(id) on delete cascade,
  kind leave_kind not null,
  from_date date not null,
  to_date date not null,
  reason text not null,
  status leave_state not null default 'PENDING',
  requested_by uuid references auth.users(id) on delete set null,
  decided_by uuid references auth.users(id) on delete set null,
  decided_at timestamptz,
  decision_note text,
  created_at timestamptz not null default now(),
  constraint leave_dates check (to_date >= from_date)
);
create index leave_requests_state_idx on public.leave_requests (tenant_id, status, created_at desc);

create or replace function public.assert_leave_decision()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status and new.status in ('APPROVED','REJECTED') then
    if not app.has_permission('leave.approve') then raise exception 'FORBIDDEN'; end if;
    new.decided_by := app.jwt_uid();
    new.decided_at := now();
  end if;
  return new;
end;
$$;
create trigger leave_decision_guard
  before update on public.leave_requests
  for each row execute function public.assert_leave_decision();

-- ---------------------------------------------------------------------------
-- Payroll (optional, restricted)
-- ---------------------------------------------------------------------------
create table public.payroll_runs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  period text not null,
  status payroll_state not null default 'DRAFT',
  gross_total numeric(14,2) not null default 0,
  deductions_total numeric(14,2) not null default 0,
  net_total numeric(14,2) not null default 0,
  approved_by uuid references auth.users(id) on delete set null,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tenant_id, campus_id, period)
);

create table public.payroll_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  run_id uuid not null references public.payroll_runs(id) on delete cascade,
  staff_id uuid not null references public.staff(id) on delete cascade,
  basic numeric(12,2) not null default 0,
  allowances jsonb not null default '[]'::jsonb,
  deductions jsonb not null default '[]'::jsonb,
  net numeric(12,2) not null default 0,
  unique (run_id, staff_id)
);

create or replace function public.recompute_payroll_totals()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_run uuid := coalesce(new.run_id, old.run_id);
        v_net numeric;
begin
  select coalesce(sum(basic + coalesce((select sum((x->>'amount')::numeric) from jsonb_array_elements(allowances) x), 0)
                        - coalesce((select sum((x->>'amount')::numeric) from jsonb_array_elements(deductions) x), 0)), 0)
    into v_net
  from public.payroll_items where run_id = v_run;

  update public.payroll_runs
     set net_total = v_net,
         gross_total = v_net + deductions_total
   where id = v_run;
  return null;
end;
$$;
create trigger payroll_items_recompute
  after insert or update or delete on public.payroll_items
  for each row execute function public.recompute_payroll_totals();

create or replace function public.assert_payroll_state()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status and new.status in ('APPROVED','PAID') then
    if not app.has_permission('payroll.manage') then raise exception 'FORBIDDEN'; end if;
    if new.status = 'APPROVED' then new.approved_by := app.jwt_uid(); end if;
    if new.status = 'PAID' then new.paid_at := now(); end if;
  end if;
  return new;
end;
$$;
create trigger payroll_state_guard
  before update on public.payroll_runs
  for each row execute function public.assert_payroll_state();

create trigger payroll_runs_no_delete
  before delete on public.payroll_runs
  for each row execute function public.block_mutation();

-- ---------------------------------------------------------------------------
-- Operations: Library, Transport, Inventory, Maintenance
-- ---------------------------------------------------------------------------
create table public.library_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  title text not null,
  author text,
  isbn text,
  category text,
  copies_total int not null default 1 check (copies_total > 0),
  copies_available int not null default 1 check (copies_available >= 0),
  created_at timestamptz not null default now()
);

create table public.library_loans (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  item_id uuid not null references public.library_items(id) on delete cascade,
  borrower_kind text not null check (borrower_kind in ('STUDENT','STAFF')),
  borrower_id uuid not null,
  issued_on date not null default current_date,
  due_on date not null,
  returned_on date,
  fine_amount numeric(10,2) not null default 0,
  status loan_state generated always as (
    case when returned_on is not null then 'RETURNED'
         when due_on < current_date then 'OVERDUE'
         else 'OPEN' end
  ) stored,
  issued_by uuid references auth.users(id) on delete set null
);
create index library_loans_open_idx on public.library_loans (tenant_id, status);

create or replace function public.maintain_library_stock()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_item uuid := coalesce(new.item_id, old.item_id);
        v_delta int := 0;
begin
  if tg_op = 'INSERT' then v_delta := -1; end if;
  if tg_op = 'DELETE' then v_delta := +1; end if;
  if tg_op = 'UPDATE' and old.returned_on is null and new.returned_on is not null then v_delta := +1; end if;
  if tg_op = 'UPDATE' and old.returned_on is not null and new.returned_on is null then v_delta := -1; end if;

  if v_delta <> 0 then
    update public.library_items
       set copies_available = greatest(0, least(copies_total, copies_available + v_delta))
     where id = v_item;
  end if;
  return null;
end;
$$;
create trigger library_stock_guard
  after insert or update or delete on public.library_loans
  for each row execute function public.maintain_library_stock();

create table public.transport_routes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  code text not null,
  name text not null,
  vehicle_no text,
  driver_name text,
  driver_phone text,
  capacity int not null default 30,
  monthly_fee numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  unique (tenant_id, campus_id, code)
);

create table public.transport_assignments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  route_id uuid not null references public.transport_routes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  pickup_point text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (route_id, student_id)
);

create table public.inventory_assets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  tag text not null,
  name text not null,
  category text,
  quantity int not null default 1,
  condition text not null default 'GOOD' check (condition in ('NEW','GOOD','FAIR','DAMAGED')),
  location text,
  acquired_on date,
  notes text,
  created_at timestamptz not null default now(),
  unique (tenant_id, tag)
);

create table public.maintenance_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  asset_id uuid references public.inventory_assets(id) on delete set null,
  title text not null,
  description text,
  status maint_state not null default 'OPEN',
  raised_by uuid references auth.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Communications: notices + notifications
-- ---------------------------------------------------------------------------
create table public.notices (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid references public.campuses(id) on delete cascade,
  title_en text not null,
  title_ur text,
  body_en text not null,
  body_ur text,
  audience jsonb not null default '{}'::jsonb, -- {campuses:[],classes:[],roles:[],all:false}
  channels text[] not null default '{IN_APP}',
  published_by uuid references auth.users(id) on delete set null,
  published_at timestamptz not null default now(),
  expires_at timestamptz
);
create index notices_tenant_idx on public.notices (tenant_id, published_at desc);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  tenant_id uuid references public.tenants(id) on delete cascade,
  kind text not null default 'GENERAL',
  title text not null,
  body text,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create trigger notifications_no_update_data before update on public.notifications
  for each row when (new.title is distinct from old.title or new.user_id is distinct from old.user_id)
  execute function public.block_mutation();

-- Fan-out a notice to user notifications (trusted; called by notice composer client RPC)
create or replace function app.publish_notice(
  p_tenant uuid, p_campus uuid, p_title_en text, p_title_ur text,
  p_body_en text, p_body_ur text, p_audience jsonb
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_notice uuid;
  v_users uuid[];
begin
  if not app.has_tenant_permission('notices.compose', p_tenant) then raise exception 'FORBIDDEN'; end if;
  if p_campus is not null and not app.can_access_campus(p_tenant, p_campus) then raise exception 'FORBIDDEN'; end if;

  insert into public.notices (tenant_id, campus_id, title_en, title_ur, body_en, body_ur, audience, published_by)
  values (p_tenant, p_campus, p_title_en, p_title_ur, p_body_en, p_body_ur, p_audience, app.jwt_uid())
  returning id into v_notice;

  -- Resolve recipients: members of tenant (+ optional campus/role filters)
  select coalesce(array_agg(distinct m.user_id), '{}') into v_users
  from public.memberships m
  join public.membership_roles mr on mr.membership_id = m.id
  where m.tenant_id = p_tenant
    and m.status = 'ACTIVE'
    and (p_audience ? 'all' or not (p_audience ? 'roles')
         or (p_audience ? 'roles' and mr.role_key in (select jsonb_array_elements_text(p_audience -> 'roles'))))
    and (not (p_audience ? 'campuses')
         or exists (
           select 1 from public.campus_memberships cm
           where cm.membership_id = m.id
             and cm.campus_id in (select (x)::uuid from jsonb_array_elements_text(p_audience -> 'campuses') x)
         ));

  if coalesce(array_length(v_users, 1), 0) > 0 then
    insert into public.notifications (user_id, tenant_id, kind, title, body, data)
    select u, p_tenant, 'NOTICE', p_title_en, p_body_en,
           jsonb_build_object('notice_id', v_notice, 'campus_id', p_campus)
    from unnest(v_users) u
    on conflict do nothing;
  end if;

  perform app.write_audit('notices.published','notices',v_notice,
    jsonb_build_object('recipients', coalesce(array_length(v_users,1),0)), p_tenant, p_campus);

  return v_notice;
end;
$$;

grant execute on function app.publish_notice(uuid, uuid, text, text, text, text, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.staff_attendance enable row level security;
alter table public.leave_requests enable row level security;
alter table public.payroll_runs enable row level security;
alter table public.payroll_items enable row level security;
alter table public.library_items enable row level security;
alter table public.library_loans enable row level security;
alter table public.transport_routes enable row level security;
alter table public.transport_assignments enable row level security;
alter table public.inventory_assets enable row level security;
alter table public.maintenance_requests enable row level security;
alter table public.notices enable row level security;
alter table public.notifications enable row level security;

create policy staff_attendance_select on public.staff_attendance for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  or exists (select 1 from public.staff s where s.id = staff_attendance.staff_id and s.user_id = app.jwt_uid())
);
create policy staff_attendance_insert on public.staff_attendance for insert to authenticated with check (
  app.has_tenant_permission('hr.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy staff_attendance_update on public.staff_attendance for update to authenticated using (
  app.has_tenant_permission('hr.manage', tenant_id)
) with check (
  app.has_tenant_permission('hr.manage', tenant_id)
);
create policy staff_attendance_delete on public.staff_attendance for delete to authenticated using (
  app.has_tenant_permission('hr.manage', tenant_id) and work_date = current_date
);

create policy leave_select on public.leave_requests for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  or requested_by = app.jwt_uid()
  or exists (select 1 from public.staff s where s.id = leave_requests.staff_id and s.user_id = app.jwt_uid())
);
create policy leave_insert on public.leave_requests for insert to authenticated with check (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('hr.manage', tenant_id)
    or exists (select 1 from public.staff s where s.id = leave_requests.staff_id and s.user_id = app.jwt_uid())
  )
  and requested_by = app.jwt_uid()
  and status = 'PENDING'
);
create policy leave_update on public.leave_requests for update to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  and (app.has_tenant_permission('leave.approve', tenant_id) or requested_by = app.jwt_uid())
) with check (
  app.can_access_campus(tenant_id, campus_id)
  and (app.has_tenant_permission('leave.approve', tenant_id) or requested_by = app.jwt_uid())
);

create policy payroll_select on public.payroll_runs for select to authenticated using (
  app.has_tenant_permission('payroll.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy payroll_insert on public.payroll_runs for insert to authenticated with check (
  app.has_tenant_permission('payroll.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy payroll_update on public.payroll_runs for update to authenticated using (
  app.has_tenant_permission('payroll.manage', tenant_id)
) with check (
  app.has_tenant_permission('payroll.manage', tenant_id)
);

create policy payroll_items_select on public.payroll_items for select to authenticated using (
  app.has_tenant_permission('payroll.manage', tenant_id)
);
create policy payroll_items_insert on public.payroll_items for insert to authenticated with check (
  app.has_tenant_permission('payroll.manage', tenant_id)
);
create policy payroll_items_update on public.payroll_items for update to authenticated using (
  app.has_tenant_permission('payroll.manage', tenant_id)
) with check (
  app.has_tenant_permission('payroll.manage', tenant_id)
);
create policy payroll_items_delete on public.payroll_items for delete to authenticated using (
  app.has_tenant_permission('payroll.manage', tenant_id)
  and exists (select 1 from public.payroll_runs r where r.id = run_id and r.status = 'DRAFT')
);

create policy library_items_select on public.library_items for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy library_items_write on public.library_items for insert to authenticated with check (
  app.has_tenant_permission('library.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy library_items_update on public.library_items for update to authenticated using (
  app.has_tenant_permission('library.manage', tenant_id)
) with check (
  app.has_tenant_permission('library.manage', tenant_id)
);

create policy library_loans_select on public.library_loans for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy library_loans_insert on public.library_loans for insert to authenticated with check (
  app.has_tenant_permission('library.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy library_loans_update on public.library_loans for update to authenticated using (
  app.has_tenant_permission('library.manage', tenant_id)
  or issued_by = app.jwt_uid()
) with check (
  app.has_tenant_permission('library.manage', tenant_id)
  or issued_by = app.jwt_uid()
);

create policy transport_routes_select on public.transport_routes for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy transport_routes_write on public.transport_routes for insert to authenticated with check (
  app.has_tenant_permission('transport.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy transport_routes_update on public.transport_routes for update to authenticated using (
  app.has_tenant_permission('transport.manage', tenant_id)
) with check (
  app.has_tenant_permission('transport.manage', tenant_id)
);

create policy transport_assignments_select on public.transport_assignments for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  or exists (select 1 from public.students s where s.id = student_id and (app.is_self_student(s.id) or app.is_guardian_of(s.id)))
);
create policy transport_assignments_write on public.transport_assignments for insert to authenticated with check (
  app.has_tenant_permission('transport.manage', tenant_id)
);
create policy transport_assignments_update on public.transport_assignments for update to authenticated using (
  app.has_tenant_permission('transport.manage', tenant_id)
) with check (
  app.has_tenant_permission('transport.manage', tenant_id)
);

create policy inventory_select on public.inventory_assets for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy inventory_write on public.inventory_assets for insert to authenticated with check (
  app.has_tenant_permission('inventory.manage', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy inventory_update on public.inventory_assets for update to authenticated using (
  app.has_tenant_permission('inventory.manage', tenant_id)
) with check (
  app.has_tenant_permission('inventory.manage', tenant_id)
);

create policy maintenance_select on public.maintenance_requests for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy maintenance_insert on public.maintenance_requests for insert to authenticated with check (
  app.can_access_campus(tenant_id, campus_id)
  and raised_by = app.jwt_uid()
);
create policy maintenance_update on public.maintenance_requests for update to authenticated using (
  app.has_tenant_permission('inventory.manage', tenant_id)
  or raised_by = app.jwt_uid()
) with check (
  app.has_tenant_permission('inventory.manage', tenant_id)
  or raised_by = app.jwt_uid()
);

-- Notices: school staff read; parents/students read notices for their campus
create policy notices_select on public.notices for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  or (campus_id is null and tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null))
  or exists (
    select 1 from public.enrollments e
    join public.students s on s.id = e.student_id
    where s.tenant_id = notices.tenant_id and s.campus_id = notices.campus_id
      and (app.is_self_student(s.id) or app.is_guardian_of(s.id))
  )
);

create policy notifications_select_own on public.notifications for select to authenticated using (
  user_id = app.jwt_uid()
);

create policy notifications_update_own on public.notifications for update to authenticated using (
  user_id = app.jwt_uid()
) with check (
  user_id = app.jwt_uid()
);

create policy notifications_delete_own on public.notifications for delete to authenticated using (
  user_id = app.jwt_uid()
);
