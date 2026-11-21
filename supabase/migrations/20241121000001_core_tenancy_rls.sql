-- ============================================================================
-- KSMS Migration 0001 — Core Tenancy, Roles, Access Requests, RLS Foundation
-- ============================================================================

create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type tenant_type as enum ('PRIVATE', 'GOVERNMENT');
create type tenant_status as enum ('ACTIVE', 'SUSPENDED', 'ARCHIVED');
create type access_request_kind as enum ('SCHOOL_REGISTRATION', 'STAFF_ACCESS');
create type access_request_state as enum ('REQUESTED', 'PENDING_REVIEW', 'NEEDS_INFORMATION', 'APPROVED', 'REJECTED');
create type approval_decision as enum ('APPROVE', 'REJECT', 'REQUEST_INFO');
create type membership_state as enum ('INVITED', 'ACTIVE', 'SUSPENDED', 'EXPIRED');
create type role_scope as enum ('PLATFORM', 'GOVERNMENT', 'SCHOOL');

-- ---------------------------------------------------------------------------
-- Tenants & Campuses
-- ---------------------------------------------------------------------------
create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type tenant_type not null default 'PRIVATE',
  status tenant_status not null default 'ACTIVE',
  city text,
  semis_code text,
  gov_province text,
  gov_district text,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null
);
create unique index tenants_semis_unique on public.tenants (semis_code) where semis_code is not null;
create index tenants_type_idx on public.tenants (type, status);

create table public.campuses (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_code text not null,
  name text not null,
  address text,
  city text,
  phone text,
  semis_code text,
  timezone text not null default 'Asia/Karachi',
  is_main boolean not null default false,
  created_at timestamptz not null default now(),
  unique (tenant_id, campus_code)
);
create index campuses_tenant_idx on public.campuses (tenant_id);

-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  phone text,
  locale text not null default 'en' check (locale in ('en','ur')),
  avatar_path text,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','SUSPENDED')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, phone)
  values (new.id,
          coalesce(new.raw_user_meta_data ->> 'full_name', ''),
          new.email,
          new.phone)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Roles / Permissions
-- ---------------------------------------------------------------------------
create table public.roles (
  key text primary key,
  label text not null,
  scope role_scope not null,
  requires_mfa boolean not null default false,
  sort_order int not null default 100
);

create table public.permissions (
  key text primary key,
  description text not null default ''
);

create table public.role_permissions (
  role_key text not null references public.roles(key) on delete cascade,
  permission_key text not null references public.permissions(key) on delete cascade,
  primary key (role_key, permission_key)
);

insert into public.roles (key, label, scope, requires_mfa, sort_order) values
  ('platform_super_admin','Platform Super Admin','PLATFORM',true,10),
  ('government_authority_admin','Government Authority Admin','GOVERNMENT',true,20),
  ('tenant_admin','School Owner / Tenant Admin','SCHOOL',true,30),
  ('principal','Principal / Head Teacher','SCHOOL',true,40),
  ('vice_principal','Vice Principal / Coordinator','SCHOOL',false,50),
  ('registrar','Registrar / Admission Officer','SCHOOL',false,60),
  ('accountant','Accountant / Cashier','SCHOOL',false,70),
  ('teacher','Teacher','SCHOOL',false,80),
  ('hr_officer','HR / Payroll Officer','SCHOOL',false,90),
  ('ops_officer','Librarian / Transport / Inventory','SCHOOL',false,100),
  ('parent','Parent / Guardian','SCHOOL',false,110),
  ('student','Student','SCHOOL',false,120),
  ('auditor','Auditor / Inspector','SCHOOL',false,130);

insert into public.permissions (key, description) values
  ('requests.review.platform','Review private-school access requests'),
  ('requests.review.government','Review government-school access requests'),
  ('tenants.manage','Provision / suspend tenants and campuses'),
  ('gov.registry.read','Read government school registry within jurisdiction'),
  ('gov.reports.read','Read approved government reports'),
  ('school.settings.manage','Manage organization settings'),
  ('campus.manage','Create and edit campuses'),
  ('staff.approve','Approve staff access within organization'),
  ('students.read','View student records'),
  ('students.write','Create / edit student records'),
  ('students.merge','Merge duplicate student records'),
  ('admissions.write','Manage enquiries, applications, admissions'),
  ('guardians.write','Manage guardian links'),
  ('academics.manage','Manage academic years, terms, classes, sections, subjects'),
  ('assignments.manage','Manage teacher assignments'),
  ('timetable.manage','Manage timetables'),
  ('homework.read','Read homework'),
  ('homework.write','Create / edit homework'),
  ('attendance.mark','Mark attendance'),
  ('attendance.correct','Correct attendance with reason'),
  ('attendance.read','Read attendance'),
  ('exams.manage','Manage exams and weightages'),
  ('marks.enter','Enter marks'),
  ('marks.review','Review marks'),
  ('marks.approve','Approve marks'),
  ('results.publish','Publish results and report cards'),
  ('finance.private.view','View private finance'),
  ('finance.collect','Collect payments and issue receipts'),
  ('finance.reverse','Reverse / refund payments'),
  ('finance.discount.approve','Approve discounts / waivers'),
  ('finance.gov.view','View grants, budgets, expenses'),
  ('finance.gov.expense.request','Request expenses'),
  ('finance.gov.expense.approve','Approve expenses'),
  ('hr.manage','Manage staff profiles'),
  ('leave.approve','Approve leave requests'),
  ('payroll.manage','Manage payroll runs'),
  ('library.manage','Manage library'),
  ('transport.manage','Manage transport'),
  ('inventory.manage','Manage inventory'),
  ('notices.compose','Compose targeted notices'),
  ('notifications.read','Read notifications'),
  ('reports.export','Export reports'),
  ('audit.read','Read audit trail'),
  ('settings.read','Read settings & role matrix');

insert into public.role_permissions (role_key, permission_key)
select r.key, p.key
from public.roles r
cross join (values
  ('requests.review.platform'),('tenants.manage'),('settings.read'),('audit.read'),('gov.registry.read')
) as pa(pkey)
where r.key = 'platform_super_admin'
  and p.key = pa.pkey;

insert into public.role_permissions (role_key, permission_key) values
  ('platform_super_admin','requests.review.platform'),
  ('platform_super_admin','tenants.manage'),
  ('government_authority_admin','requests.review.government'),
  ('government_authority_admin','gov.registry.read'),
  ('government_authority_admin','gov.reports.read'),
  ('government_authority_admin','audit.read'),
  ('government_authority_admin','settings.read');

insert into public.role_permissions (role_key, permission_key)
select 'tenant_admin', key from public.permissions
where key in ('school.settings.manage','campus.manage','staff.approve','students.read','students.write','students.merge','admissions.write','guardians.write','academics.manage','assignments.manage','timetable.manage','homework.read','homework.write','attendance.mark','attendance.correct','attendance.read','exams.manage','marks.enter','marks.review','marks.approve','results.publish','finance.private.view','finance.collect','finance.reverse','finance.discount.approve','finance.gov.view','finance.gov.expense.request','hr.manage','leave.approve','payroll.manage','library.manage','transport.manage','inventory.manage','notices.compose','notifications.read','reports.export','audit.read','settings.read');

insert into public.role_permissions (role_key, permission_key)
select 'principal', key from public.permissions
where key in ('students.read','admissions.write','guardians.write','academics.manage','assignments.manage','timetable.manage','homework.read','homework.write','attendance.mark','attendance.correct','attendance.read','exams.manage','marks.enter','marks.review','marks.approve','results.publish','finance.private.view','finance.gov.view','leave.approve','notices.compose','notifications.read','reports.export','audit.read','settings.read');

insert into public.role_permissions (role_key, permission_key)
select 'vice_principal', key from public.permissions
where key in ('students.read','admissions.write','academics.manage','assignments.manage','timetable.manage','homework.read','homework.write','attendance.mark','attendance.read','exams.manage','marks.enter','marks.review','notifications.read','reports.export','settings.read');

insert into public.role_permissions (role_key, permission_key)
select 'registrar', key from public.permissions
where key in ('students.read','students.write','students.merge','admissions.write','guardians.write','notifications.read','reports.export','settings.read');

insert into public.role_permissions (role_key, permission_key)
select 'accountant', key from public.permissions
where key in ('students.read','finance.private.view','finance.collect','finance.discount.approve','notifications.read','reports.export','settings.read');

insert into public.role_permissions (role_key, permission_key)
select 'teacher', key from public.permissions
where key in ('students.read','homework.read','homework.write','attendance.mark','attendance.correct','attendance.read','marks.enter','notifications.read');

insert into public.role_permissions (role_key, permission_key)
select 'hr_officer', key from public.permissions
where key in ('students.read','hr.manage','leave.approve','payroll.manage','notifications.read','reports.export','settings.read');

insert into public.role_permissions (role_key, permission_key)
select 'ops_officer', key from public.permissions
where key in ('library.manage','transport.manage','inventory.manage','notifications.read','settings.read');

insert into public.role_permissions (role_key, permission_key)
select 'parent', key from public.permissions
where key in ('notifications.read','attendance.read','homework.read');

insert into public.role_permissions (role_key, permission_key)
select 'student', key from public.permissions
where key in ('notifications.read','attendance.read','homework.read');

insert into public.role_permissions (role_key, permission_key)
select 'auditor', key from public.permissions
where key in ('students.read','attendance.read','finance.private.view','finance.gov.view','audit.read','reports.export','settings.read');

-- ---------------------------------------------------------------------------
-- Memberships
-- ---------------------------------------------------------------------------
create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  tenant_id uuid references public.tenants(id) on delete cascade,
  status membership_state not null default 'INVITED',
  scopes jsonb not null default '{}'::jsonb,
  expires_at timestamptz,
  invited_by uuid references auth.users(id) on delete set null,
  activated_at timestamptz,
  created_at timestamptz not null default now(),
  constraint memberships_tenant_required check (
    tenant_id is not null or exists (
      select 1 from public.membership_roles mr
      where mr.membership_id = id and mr.role_key in ('platform_super_admin','government_authority_admin')
    )
  )
);
create index memberships_user_idx on public.memberships (user_id);
create index memberships_tenant_idx on public.memberships (tenant_id);
create unique index memberships_unique_user_tenant on public.memberships (user_id, coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid));

create table public.membership_roles (
  membership_id uuid not null references public.memberships(id) on delete cascade,
  role_key text not null references public.roles(key) on delete restrict,
  primary key (membership_id, role_key)
);

create table public.campus_memberships (
  id uuid primary key default gen_random_uuid(),
  membership_id uuid not null references public.memberships(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  unique (membership_id, campus_id)
);
create index campus_memberships_campus_idx on public.campus_memberships (campus_id);

-- ---------------------------------------------------------------------------
-- Access Requests & Approval Actions (append-only)
-- ---------------------------------------------------------------------------
create table public.access_requests (
  id uuid primary key default gen_random_uuid(),
  reference_code text not null unique default upper('KSMS-' || substr(md5(random()::text || clock_timestamp()::text), 1, 8)),
  kind access_request_kind not null,
  state access_request_state not null default 'REQUESTED',
  institution_name text,
  institution_type tenant_type,
  campus_name text,
  city text,
  semis_code text,
  requester_user_id uuid references public.profiles(id) on delete set null,
  requester_name text not null,
  requester_email text not null,
  requester_phone text,
  requested_role text,
  target_tenant_id uuid references public.tenants(id) on delete set null,
  target_campus_id uuid references public.campuses(id) on delete set null,
  details jsonb not null default '{}'::jsonb,
  evidence_paths text[] not null default '{}',
  submitted_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references auth.users(id) on delete set null,
  decision_reason text,
  expires_at timestamptz not null default now() + interval '30 days'
);
create index access_requests_state_idx on public.access_requests (state, submitted_at desc);

create table public.approval_actions (
  id uuid primary key default gen_random_uuid(),
  access_request_id uuid not null references public.access_requests(id) on delete restrict,
  actor uuid references auth.users(id) on delete set null,
  decision approval_decision not null,
  reason text not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Audit events (append-only, cross-cutting)
-- ---------------------------------------------------------------------------
create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete set null,
  campus_id uuid references public.campuses(id) on delete set null,
  actor uuid references auth.users(id) on delete set null,
  action text not null,
  entity text not null,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_events_tenant_time_idx on public.audit_events (tenant_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Common trigger helpers
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.block_mutation()
returns trigger language plpgsql as $$
begin
  raise exception 'KSMS_IMMUTABLE: % on % is not permitted (append-only record)', tg_op, tg_table_name;
end;
$$;

create trigger audit_events_immutable
  before update or delete on public.audit_events
  for each row execute function public.block_mutation();

create trigger approval_actions_immutable
  before update or delete on public.approval_actions
  for each row execute function public.block_mutation();

-- ---------------------------------------------------------------------------
-- app schema — SECURITY DEFINER RLS helpers (fixed search_path, non-recursive)
-- ---------------------------------------------------------------------------
create schema if not exists app;
grant usage on schema app to anon, authenticated;

create or replace function app.jwt_uid() returns uuid
language sql stable security definer set search_path = public as
$$ select auth.uid() $$;

create or replace function app.active_memberships()
returns table (membership_id uuid, tenant_id uuid, campus_id uuid, role_key text, expires_at timestamptz, scopes jsonb)
language sql stable security definer set search_path = public as $$
  select m.id, m.tenant_id, cm.campus_id, r.role_key, m.expires_at, m.scopes
  from public.memberships m
  join public.membership_roles mr on mr.membership_id = m.id
  join public.roles r on r.key = mr.role_key
  left join public.campus_memberships cm on cm.membership_id = m.id
  where m.user_id = app.jwt_uid()
    and m.status = 'ACTIVE'
    and (m.expires_at is null or m.expires_at > now())
$$;

create or replace function app.is_platform_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from app.active_memberships() am where am.role_key = 'platform_super_admin'
  )
$$;

create or replace function app.is_gov_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from app.active_memberships() am where am.role_key = 'government_authority_admin'
  )
$$;

create or replace function app.has_role(p_role text)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from app.active_memberships() am where am.role_key = p_role)
$$;

create or replace function app.has_permission(p_permission text)
returns boolean
language sql stable security definer set search_path = public as $$
  select app.is_platform_admin()
      or exists (
        select 1
        from app.active_memberships() am
        join public.role_permissions rp on rp.role_key = am.role_key
        where rp.permission_key = p_permission
      )
$$;

create or replace function app.has_tenant_permission(p_permission text, p_tenant uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select app.is_platform_admin()
      or exists (
        select 1
        from app.active_memberships() am
        join public.role_permissions rp on rp.role_key = am.role_key
        where am.tenant_id = p_tenant
          and rp.permission_key = p_permission
      )
$$;

create or replace function app.can_access_campus(p_tenant uuid, p_campus uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from app.active_memberships() am
    where am.tenant_id = p_tenant
      and (am.campus_id is null or am.campus_id = p_campus)
  )
$$;

create or replace function app.can_access_gov_tenant(p_tenant uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from app.active_memberships() am
    join public.tenants t on t.id = p_tenant
    where am.role_key = 'government_authority_admin'
      and (
        (am.scopes ? 'all')
        or (am.scopes ? 'provinces' and am.scopes -> 'provinces' ? t.gov_province)
        or (am.scopes ? 'districts' and am.scopes -> 'districts' ? t.gov_district)
      )
  )
$$;

create or replace function app.tenant_type_of(p_tenant uuid)
returns tenant_type
language sql stable security definer set search_path = public as $$
  select type from public.tenants where id = p_tenant
$$;

create or replace function app.write_audit(
  p_action text, p_entity text, p_entity_id uuid default null,
  p_details jsonb default '{}'::jsonb, p_tenant uuid default null, p_campus uuid default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into public.audit_events (tenant_id, campus_id, actor, action, entity, entity_id, details)
  values (p_tenant, p_campus, app.jwt_uid(), p_action, p_entity, p_entity_id, p_details);
end;
$$;

-- Client context RPC: profile + active memberships + campuses (single round trip)
create or replace function app.my_context()
returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'profile', (select to_jsonb(p) from public.profiles p where p.id = app.jwt_uid()),
    'memberships', coalesce((
      select jsonb_agg(jsonb_build_object(
        'membership_id', x.membership_id,
        'tenant_id', x.tenant_id,
        'campus_id', x.campus_id,
        'role_key', x.role_key,
        'scopes', x.scopes,
        'expires_at', x.expires_at
      ))
      from app.active_memberships() x
    ), '[]'::jsonb),
    'permissions', coalesce((
      select jsonb_agg(distinct rp.permission_key)
      from app.active_memberships() am
      join public.role_permissions rp on rp.role_key = am.role_key
    ), '[]'::jsonb)
  )
$$;

grant execute on function app.my_context() to authenticated;

-- Public status lookup without authentication (limited columns only)
create or replace function app.check_status(p_reference text, p_email text)
returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'state', ar.state,
    'kind', ar.kind,
    'institution_name', ar.institution_name,
    'submitted_at', ar.submitted_at,
    'decision_reason', ar.decision_reason,
    'decided_at', ar.decided_at
  )
  from public.access_requests ar
  where ar.reference_code = upper(p_reference)
    and lower(ar.requester_email) = lower(p_email)
$$;

grant execute on function app.check_status(text, text) to anon, authenticated;

-- Records an approval decision (trusted; caller must hold review permission)
create or replace function app.record_approval(
  p_request uuid, p_decision approval_decision, p_reason text
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_kind access_request_kind;
  v_type tenant_type;
begin
  select kind, institution_type into v_kind, v_type from public.access_requests where id = p_request;
  if v_kind is null then
    raise exception 'REQUEST_NOT_FOUND';
  end if;

  if v_kind = 'SCHOOL_REGISTRATION' then
    if v_type = 'PRIVATE' and not app.has_permission('requests.review.platform') then
      raise exception 'FORBIDDEN';
    end if;
    if v_type = 'GOVERNMENT' and not app.has_permission('requests.review.government') then
      raise exception 'FORBIDDEN';
    end if;
  else
    if not app.has_permission('staff.approve') and not app.has_permission('requests.review.platform') then
      raise exception 'FORBIDDEN';
    end if;
  end if;

  update public.access_requests
     set state = case p_decision
                   when 'APPROVE' then 'APPROVED'::access_request_state
                   when 'REJECT' then 'REJECTED'::access_request_state
                   else 'NEEDS_INFORMATION'::access_request_state
                 end,
         decided_at = case when p_decision = 'REQUEST_INFO' then null else now() end,
         decided_by = app.jwt_uid(),
         decision_reason = p_reason
   where id = p_request;

  insert into public.approval_actions (access_request_id, actor, decision, reason)
  values (p_request, app.jwt_uid(), p_decision, p_reason);
end;
$$;

grant execute on function app.record_approval(uuid, approval_decision, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Enable RLS everywhere (deny by default)
-- ---------------------------------------------------------------------------
alter table public.tenants enable row level security;
alter table public.campuses enable row level security;
alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.memberships enable row level security;
alter table public.membership_roles enable row level security;
alter table public.campus_memberships enable row level security;
alter table public.access_requests enable row level security;
alter table public.approval_actions enable row level security;
alter table public.audit_events enable row level security;

-- ---------------------------------------------------------------------------
-- Policies: reference tables readable by any authenticated user
-- ---------------------------------------------------------------------------
create policy roles_read on public.roles for select to authenticated using (true);
create policy permissions_read on public.permissions for select to authenticated using (true);
create policy role_permissions_read on public.role_permissions for select to authenticated using (true);

-- ---------------------------------------------------------------------------
-- Policies: tenants & campuses
-- ---------------------------------------------------------------------------
create policy tenants_select on public.tenants for select to authenticated using (
  app.is_platform_admin()
  or id in (select tenant_id from app.active_memberships() where tenant_id is not null)
  or (app.is_gov_admin() and app.can_access_gov_tenant(id))
);

create policy tenants_insert on public.tenants for insert to authenticated with check (
  app.is_platform_admin()
);

create policy tenants_update on public.tenants for update to authenticated using (
  app.is_platform_admin()
  or (app.has_tenant_permission('school.settings.manage', id) and status = 'ACTIVE')
) with check (
  app.is_platform_admin()
  or (app.has_tenant_permission('school.settings.manage', id) and status = 'ACTIVE')
);
-- No DELETE policy on tenants: deletion only via service role (provisioning cleanup).

create policy campuses_select on public.campuses for select to authenticated using (
  app.is_platform_admin()
  or app.can_access_campus(tenant_id, id)
  or (app.is_gov_admin() and app.can_access_gov_tenant(tenant_id))
);

create policy campuses_write on public.campuses for insert to authenticated with check (
  app.is_platform_admin() or app.has_tenant_permission('campus.manage', tenant_id)
);

create policy campuses_update on public.campuses for update to authenticated using (
  app.is_platform_admin() or app.has_tenant_permission('campus.manage', tenant_id)
) with check (
  app.is_platform_admin() or app.has_tenant_permission('campus.manage', tenant_id)
);

-- ---------------------------------------------------------------------------
-- Policies: profiles (self + co-members)
-- ---------------------------------------------------------------------------
create policy profiles_select on public.profiles for select to authenticated using (
  id = app.jwt_uid()
  or exists (
    select 1
    from app.active_memberships() mine
    join app.active_memberships() theirs on theirs.tenant_id = mine.tenant_id
    where theirs.user_id = profiles.id
  )
  or app.is_platform_admin()
);

create policy profiles_update_self on public.profiles for update to authenticated using (
  id = app.jwt_uid()
) with check (
  id = app.jwt_uid()
);

-- Protect identity & status columns from self-service edits
create or replace function public.guard_profile_columns()
returns trigger language plpgsql as $$
begin
  if new.email is distinct from old.email or new.status is distinct from old.status then
    raise exception 'KSMS_FORBIDDEN: email/status are managed by trusted services';
  end if;
  return new;
end;
$$;

create trigger profiles_guard_update
  before update on public.profiles
  for each row when (pg_trigger_depth() = 0) execute function public.guard_profile_columns();

-- ---------------------------------------------------------------------------
-- Policies: memberships (self read; admins manage)
-- ---------------------------------------------------------------------------
create policy memberships_select on public.memberships for select to authenticated using (
  user_id = app.jwt_uid()
  or app.is_platform_admin()
  or exists (
    select 1 from app.active_memberships() mine
    where mine.tenant_id = memberships.tenant_id
      and exists (
        select 1 from public.role_permissions rp
        where rp.role_key = (select role_key from app.active_memberships() a2 where a2.membership_id = mine.membership_id limit 1)
          and rp.permission_key in ('staff.approve','settings.read','audit.read')
      )
  )
);

create policy membership_roles_select on public.membership_roles for select to authenticated using (
  exists (
    select 1 from public.memberships m
    where m.id = membership_roles.membership_id
      and (m.user_id = app.jwt_uid() or app.is_platform_admin())
  )
  or exists (
    select 1 from app.active_memberships() mine
    where exists (
      select 1 from public.memberships m2
      join public.membership_roles mr2 on mr2.membership_id = m2.id
      where m2.id = membership_roles.membership_id
        and m2.tenant_id = mine.tenant_id
        and mr2.role_key in ('tenant_admin','principal')
    )
  )
);

create policy campus_memberships_select on public.campus_memberships for select to authenticated using (
  exists (
    select 1 from public.memberships m
    where m.id = campus_memberships.membership_id
      and (m.user_id = app.jwt_uid() or app.is_platform_admin())
  )
  or exists (
    select 1 from app.active_memberships() mine
    where exists (
      select 1 from public.memberships m2
      where m2.id = campus_memberships.membership_id
        and m2.tenant_id = mine.tenant_id
    )
  )
);

-- Membership writes happen through the trusted Edge Function (service role).
-- Self-service updates are limited to activation only.
create policy memberships_activate_self on public.memberships for update to authenticated using (
  user_id = app.jwt_uid() and status = 'INVITED'
) with check (
  user_id = app.jwt_uid() and status = 'ACTIVE'
);

-- ---------------------------------------------------------------------------
-- Policies: access requests
-- ---------------------------------------------------------------------------
create policy access_requests_insert_anon on public.access_requests for insert to anon with check (
  requester_user_id is null and kind = 'SCHOOL_REGISTRATION'
);

create policy access_requests_insert_auth on public.access_requests for insert to authenticated with check (
  requester_user_id = app.jwt_uid()
);

create policy access_requests_select on public.access_requests for select to authenticated using (
  requester_user_id = app.jwt_uid()
  or app.is_platform_admin()
  or (app.is_gov_admin() and institution_type = 'GOVERNMENT')
  or exists (
    select 1 from app.active_memberships() mine
    where target_tenant_id = mine.tenant_id
      and exists (
        select 1 from public.role_permissions rp
        where rp.role_key in (select role_key from app.active_memberships() a2 where a2.membership_id = mine.membership_id)
          and rp.permission_key = 'staff.approve'
      )
  )
);

create policy approval_actions_select on public.approval_actions for select to authenticated using (
  app.is_platform_admin()
  or exists (
    select 1 from public.access_requests ar
    where ar.id = approval_actions.access_request_id
      and (ar.requester_user_id = app.jwt_uid()
           or (app.is_gov_admin() and ar.institution_type = 'GOVERNMENT'))
  )
);

create policy audit_events_select on public.audit_events for select to authenticated using (
  app.is_platform_admin()
  or (app.is_gov_admin() and exists (
        select 1 from public.tenants t
        where t.id = audit_events.tenant_id and app.can_access_gov_tenant(t.id)
      ))
  or tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null)
);
