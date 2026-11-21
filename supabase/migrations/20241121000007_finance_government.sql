-- ============================================================================
-- KSMS Migration 0007 — Government Finance: Grants, Budgets, Expenses
-- ============================================================================

create type grant_status as enum ('RECEIVED','ACTIVE','CLOSED');
create type budget_state as enum ('DRAFT','APPROVED','REVISED');
create type expense_state as enum ('SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','PAID');

create table public.grants (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  source text not null,
  title text not null,
  amount numeric(14,2) not null check (amount >= 0),
  fiscal_year text not null,
  status grant_status not null default 'RECEIVED',
  received_at date not null default current_date,
  notes text,
  created_at timestamptz not null default now()
);
create index grants_tenant_year_idx on public.grants (tenant_id, fiscal_year);

create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  grant_id uuid references public.grants(id) on delete set null,
  head text not null,
  fiscal_year text not null,
  allocated numeric(14,2) not null check (allocated >= 0),
  state budget_state not null default 'DRAFT',
  revised_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tenant_id, campus_id, head, fiscal_year)
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  budget_id uuid references public.budgets(id) on delete set null,
  title text not null,
  description text,
  amount numeric(14,2) not null check (amount > 0),
  expense_date date not null default current_date,
  state expense_state not null default 'SUBMITTED',
  requested_by uuid references auth.users(id) on delete set null,
  request_note text,
  evidence_paths text[] not null default '{}',
  approval_chain jsonb not null default '[]'::jsonb,
  approved_at timestamptz,
  approved_by uuid references auth.users(id) on delete set null,
  rejection_reason text,
  paid_at timestamptz,
  paid_reference text,
  created_at timestamptz not null default now()
);
create index expenses_tenant_state_idx on public.expenses (tenant_id, state, created_at desc);

-- Approval chain enforcement: multi-step approval recorded in approval_chain
create or replace function public.assert_expense_transition()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_step jsonb;
begin
  if new.state = old.state and new.approval_chain is not distinct from old.approval_chain then
    return new;
  end if;

  if new.state in ('APPROVED','REJECTED','UNDER_REVIEW') and old.state in ('SUBMITTED','UNDER_REVIEW') then
    if not app.has_permission('finance.gov.expense.approve') then
      raise exception 'FORBIDDEN: approval permission required';
    end if;
    v_step := jsonb_build_object('state', new.state, 'by', app.jwt_uid(), 'at', now(),
                                 'note', coalesce(new.rejection_reason, ''));
    new.approval_chain := old.approval_chain || jsonb_build_array(v_step);

    if new.state = 'APPROVED' then
      new.approved_by := app.jwt_uid();
      new.approved_at := now();
    end if;
  end if;

  if new.state = 'PAID' and old.state <> 'APPROVED' then
    raise exception 'INVALID_EXPENSE_STATE: only approved expenses can be marked paid';
  end if;

  return new;
end;
$$;
create trigger expenses_state_guard
  before update on public.expenses
  for each row execute function public.assert_expense_transition();

create trigger expenses_no_delete
  before delete on public.expenses
  for each row execute function public.block_mutation();

create or replace view public.budget_utilization
with (security_invoker = true) as
  select b.tenant_id, b.campus_id, b.fiscal_year, b.head,
         b.allocated,
         coalesce(sum(e.amount) filter (where e.state in ('APPROVED','PAID')), 0) as committed,
         b.allocated - coalesce(sum(e.amount) filter (where e.state in ('APPROVED','PAID')), 0) as remaining
  from public.budgets b
  left join public.expenses e on e.budget_id = b.id
  group by b.id, b.tenant_id, b.campus_id, b.fiscal_year, b.head, b.allocated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.grants enable row level security;
alter table public.budgets enable row level security;
alter table public.expenses enable row level security;

create policy grants_select on public.grants for select to authenticated using (
  app.has_tenant_permission('finance.gov.view', tenant_id)
  and app.can_access_gov_tenant(tenant_id)
);
create policy grants_write on public.grants for insert to authenticated with check (
  app.has_tenant_permission('finance.gov.expense.approve', tenant_id)
  and app.can_access_gov_tenant(tenant_id)
);
create policy grants_update on public.grants for update to authenticated using (
  app.has_tenant_permission('finance.gov.expense.approve', tenant_id)
) with check (
  app.has_tenant_permission('finance.gov.expense.approve', tenant_id)
);

create policy budgets_select on public.budgets for select to authenticated using (
  app.has_tenant_permission('finance.gov.view', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy budgets_write on public.budgets for insert to authenticated with check (
  app.has_tenant_permission('finance.gov.expense.approve', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy budgets_update on public.budgets for update to authenticated using (
  app.has_tenant_permission('finance.gov.expense.approve', tenant_id)
) with check (
  app.has_tenant_permission('finance.gov.expense.approve', tenant_id)
);

create policy expenses_select on public.expenses for select to authenticated using (
  app.has_tenant_permission('finance.gov.view', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
  or (requested_by = app.jwt_uid())
);

create policy expenses_insert on public.expenses for insert to authenticated with check (
  app.has_tenant_permission('finance.gov.expense.request', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
  and requested_by = app.jwt_uid()
  and state = 'SUBMITTED'
);

create policy expenses_update on public.expenses for update to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('finance.gov.expense.approve', tenant_id)
    or (requested_by = app.jwt_uid() and state = 'SUBMITTED')
  )
) with check (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('finance.gov.expense.approve', tenant_id)
    or (requested_by = app.jwt_uid() and state = 'SUBMITTED')
  )
);
