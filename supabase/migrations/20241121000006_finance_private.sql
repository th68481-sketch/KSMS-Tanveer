-- ============================================================================
-- KSMS Migration 0006 — Private Finance: Fee Heads, Plans, Discounts,
-- Invoices, Payments, Receipts, Allocations, Reversals, Reconciliation
-- ============================================================================

create type fee_frequency as enum ('MONTHLY','TERM','ANNUAL','ONE_TIME');
create type discount_kind as enum ('SIBLING','SCHOLARSHIP','WAIVER','STAFF_CHILD','OTHER');
create type discount_state as enum ('PENDING','APPROVED','REJECTED','EXPIRED');
create type invoice_status as enum ('DRAFT','ISSUED','PARTIALLY_PAID','PAID','VOID');
create type payment_method as enum ('CASH','BANK_TRANSFER','CHEQUE','DIGITAL');
create type payment_state as enum ('CLEARED','REVERSED');

-- ---------------------------------------------------------------------------
-- Fee structure
-- ---------------------------------------------------------------------------
create table public.fee_heads (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  code text not null,
  is_recurring boolean not null default true,
  default_amount numeric(12,2) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (tenant_id, code)
);

create table public.fee_plans (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  class_id uuid references public.classes(id) on delete set null,
  name text not null,
  frequency fee_frequency not null default 'MONTHLY',
  effective_from date not null default current_date,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (tenant_id, campus_id, name)
);

create table public.fee_plan_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  plan_id uuid not null references public.fee_plans(id) on delete cascade,
  fee_head_id uuid not null references public.fee_heads(id) on delete restrict,
  amount numeric(12,2) not null check (amount >= 0),
  unique (plan_id, fee_head_id)
);

create table public.discounts_waivers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  kind discount_kind not null,
  scope text not null default 'PERCENT' check (scope in ('PERCENT','FIXED')),
  value numeric(12,2) not null check (value > 0),
  reason text not null,
  status discount_state not null default 'PENDING',
  requested_by uuid references auth.users(id) on delete set null,
  approver uuid references auth.users(id) on delete set null,
  decided_at timestamptz,
  valid_from date not null default current_date,
  valid_to date,
  created_at timestamptz not null default now()
);
create index discounts_student_idx on public.discounts_waivers (student_id);

-- ---------------------------------------------------------------------------
-- Invoices
-- ---------------------------------------------------------------------------
create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  invoice_no text not null,
  student_id uuid not null references public.students(id) on delete restrict,
  enrollment_id uuid references public.enrollments(id) on delete set null,
  billing_period text not null,
  issue_date date not null default current_date,
  due_date date not null,
  status invoice_status not null default 'DRAFT',
  gross_total numeric(12,2) not null default 0 check (gross_total >= 0),
  discount_total numeric(12,2) not null default 0 check (discount_total >= 0),
  paid_total numeric(12,2) not null default 0 check (paid_total >= 0),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, invoice_no)
);
create index invoices_student_idx on public.invoices (student_id, issue_date desc);
create index invoices_status_idx on public.invoices (tenant_id, status);
create trigger invoices_touch before update on public.invoices
  for each row execute function public.touch_updated_at();

create table public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  fee_head_id uuid not null references public.fee_heads(id) on delete restrict,
  description text not null,
  amount numeric(12,2) not null check (amount >= 0)
);
create index invoice_items_invoice_idx on public.invoice_items (invoice_id);

-- Keep invoice totals in sync with items
create or replace function public.recompute_invoice_gross()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_invoice uuid := coalesce(new.invoice_id, old.invoice_id);
begin
  update public.invoices i
     set gross_total = coalesce((select sum(amount) from public.invoice_items where invoice_id = v_invoice), 0)
   where i.id = v_invoice;
  return null;
end;
$$;
create trigger invoice_items_recompute
  after insert or update or delete on public.invoice_items
  for each row execute function public.recompute_invoice_gross();

-- Government tenants never raise tuition invoices
create or replace function public.assert_invoice_tenant_mode()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if app.tenant_type_of(new.tenant_id) = 'GOVERNMENT' then
    raise exception 'GOV_TENANT_NO_INVOICES: government tenants use grants, budgets and expenses';
  end if;
  return new;
end;
$$;
create trigger invoices_mode_guard
  before insert on public.invoices
  for each row execute function public.assert_invoice_tenant_mode();

-- ---------------------------------------------------------------------------
-- Payments, receipts, allocations (financial truth — immutable)
-- ---------------------------------------------------------------------------
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  receipt_no text not null,
  student_id uuid not null references public.students(id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  method payment_method not null,
  reference_no text,
  paid_at timestamptz not null default now(),
  received_by uuid references auth.users(id) on delete set null,
  status payment_state not null default 'CLEARED',
  reversal_of uuid references public.payments(id) on delete set null,
  reversal_reason text,
  created_at timestamptz not null default now(),
  unique (tenant_id, receipt_no)
);
create index payments_student_idx on public.payments (student_id, paid_at desc);
create index payments_day_idx on public.payments (tenant_id, campus_id, paid_at);

create table public.receipts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  payment_id uuid not null references public.payments(id) on delete cascade,
  snapshot jsonb not null,
  issued_by uuid references auth.users(id) on delete set null,
  issued_at timestamptz not null default now(),
  unique (payment_id)
);

create table public.allocations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  payment_id uuid not null references public.payments(id) on delete cascade,
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  allocated_at timestamptz not null default now()
);
create index allocations_invoice_idx on public.allocations (invoice_id);

-- Immutable financial ledger: updates only via trusted reversal RPC
create or replace function public.assert_payments_immutable()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if app.is_platform_admin() then return new; end if;
  if app.has_permission('finance.reverse') and new.status in ('CLEARED','REVERSED') then
    return new;
  end if;
  raise exception 'FINANCE_IMMUTABLE: payments change only via trusted reversal flow';
end;
$$;
create trigger payments_immutability
  before update on public.payments
  for each row execute function public.assert_payments_immutable();

create trigger payments_no_delete
  before delete on public.payments
  for each row execute function public.block_mutation();

create trigger invoices_no_delete
  before delete on public.invoices
  for each row execute function public.block_mutation();

create trigger receipts_no_delete
  before delete on public.receipts
  for each row execute function public.block_mutation();

create trigger allocations_no_delete
  before delete on public.allocations
  for each row execute function public.block_mutation();

-- ---------------------------------------------------------------------------
-- Reverse a payment: creates reversal payment + negative allocations, fixes invoices
-- ---------------------------------------------------------------------------
create or replace function app.reverse_payment(p_payment uuid, p_reason text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v public.payments%rowtype;
  v_reversal uuid;
  a record;
begin
  if not app.has_permission('finance.reverse') then raise exception 'FORBIDDEN'; end if;
  if coalesce(p_reason,'') = '' then raise exception 'REVERSAL_REQUIRES_REASON'; end if;

  select * into v from public.payments where id = p_payment;
  if v.id is null then raise exception 'PAYMENT_NOT_FOUND'; end if;
  if not app.can_access_campus(v.tenant_id, v.campus_id) then raise exception 'FORBIDDEN'; end if;
  if v.status = 'REVERSED' then raise exception 'ALREADY_REVERSED'; end if;

  insert into public.payments (tenant_id, campus_id, receipt_no, student_id, amount, method, reference_no, received_by, status, reversal_of, reversal_reason)
  values (v.tenant_id, v.campus_id, v.receipt_no || '-R', v.student_id, v.amount, v.method, v.reference_no, app.jwt_uid(), 'CLEARED', v.id, p_reason)
  returning id into v_reversal;

  insert into public.receipts (tenant_id, payment_id, snapshot, issued_by)
  select v.tenant_id, v_reversal,
         jsonb_build_object('kind','REVERSAL','original_receipt', v.receipt_no, 'reason', p_reason,
                            'amount', v.amount, 'student_id', v.student_id),
         app.jwt_uid()
  where not exists (select 1 from public.receipts where payment_id = v_reversal);

  -- Negative allocations reverse invoice paid totals
  for a in select * from public.allocations where payment_id = v.id loop
    insert into public.allocations (tenant_id, payment_id, invoice_id, amount)
    values (v.tenant_id, v_reversal, a.invoice_id, -a.amount);
  end loop;

  update public.payments set status = 'REVERSED' where id = p_payment;

  perform app.write_audit('finance.payment_reversed','payments',p_payment,
    jsonb_build_object('reversal', v_reversal, 'reason', p_reason), v.tenant_id, v.campus_id);

  return v_reversal;
end;
$$;

grant execute on function app.reverse_payment(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Collect a payment with allocations (trusted; validates totals)
-- ---------------------------------------------------------------------------
create or replace function app.collect_payment(
  p_tenant uuid, p_campus uuid, p_student uuid, p_amount numeric,
  p_method payment_method, p_reference_no text default null,
  p_allocations jsonb default '[]'::jsonb, p_invoice uuid default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_payment uuid; v_receipt uuid; v_no text; a jsonb; v_alloc_total numeric := 0;
  v_receipt_no text;
begin
  if not app.has_tenant_permission('finance.collect', p_tenant) then raise exception 'FORBIDDEN'; end if;
  if not app.can_access_campus(p_tenant, p_campus) then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;

  if p_allocations <> '[]'::jsonb then
    for a in select * from jsonb_array_elements(p_allocations) loop
      v_alloc_total := v_alloc_total + (a.value ->> 'amount')::numeric;
    end loop;
    if v_alloc_total > p_amount then
      raise exception 'ALLOCATION_EXCEEDS_PAYMENT';
    end if;
  end if;

  loop
    v_receipt_no := 'RCP-' || to_char(now(),'YYMMDD') || '-' || upper(substr(md5(random()::text), 1, 5));
    begin
      insert into public.payments (tenant_id, campus_id, receipt_no, student_id, amount, method, reference_no, received_by)
      values (p_tenant, p_campus, v_receipt_no, p_student, p_amount, p_method, p_reference_no, app.jwt_uid())
      returning id into v_payment;
      exit;
    exception when unique_violation then
      continue;
    end;
  end loop;

  if p_allocations <> '[]'::jsonb then
    for a in select * from jsonb_array_elements(p_allocations) loop
      insert into public.allocations (tenant_id, payment_id, invoice_id, amount)
      values (p_tenant, v_payment, (a.value ->> 'invoice_id')::uuid, (a.value ->> 'amount')::numeric);
    end loop;
  elsif p_invoice is not null then
    insert into public.allocations (tenant_id, payment_id, invoice_id, amount)
    values (p_tenant, v_payment, p_invoice, p_amount);
  end if;

  insert into public.receipts (tenant_id, payment_id, snapshot, issued_by)
  values (p_tenant, v_payment,
          jsonb_build_object('kind','PAYMENT','receipt_no', v_receipt_no, 'amount', p_amount,
                             'method', p_method, 'paid_at', now(), 'student_id', p_student,
                             'allocations', p_allocations),
          app.jwt_uid())
  returning id into v_receipt;

  perform app.write_audit('finance.payment_collected','payments',v_payment,
    jsonb_build_object('amount', p_amount, 'method', p_method), p_tenant, p_campus);

  return jsonb_build_object('payment_id', v_payment, 'receipt_id', v_receipt, 'receipt_no', v_receipt_no);
end;
$$;

grant execute on function app.collect_payment(uuid, uuid, uuid, numeric, payment_method, text, jsonb, uuid) to authenticated;

-- Allocation + invoice status maintenance
create or replace function public.maintain_invoice_status()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_invoice uuid := coalesce(new.invoice_id, old.invoice_id);
        v_paid numeric; v_gross numeric; v_disc numeric; v_state invoice_status;
begin
  select coalesce(sum(amount),0) into v_paid from public.allocations where invoice_id = v_invoice;
  select gross_total into v_gross from public.invoices where id = v_invoice;

  if exists (
    select 1
    from public.allocations al
    join public.payments p on p.id = al.payment_id
    where al.invoice_id = v_invoice and p.status = 'CLEARED' and al.amount > 0
  ) then
    select coalesce(sum(case when p.status='CLEARED' then al.amount else 0 end),0)
      into v_paid
    from public.allocations al join public.payments p on p.id = al.payment_id
    where al.invoice_id = v_invoice;
  else
    v_paid := 0;
  end if;

  select coalesce(sum(
    case dw.scope when 'PERCENT' then least(ii.amount, ii.amount * dw.value / 100)
                  else dw.value end), 0)
  into v_disc
  from public.invoice_items ii
  join public.invoices i on i.id = ii.invoice_id
  join public.discounts_waivers dw on dw.student_id = i.student_id
    and dw.tenant_id = i.tenant_id and dw.status = 'APPROVED'
    and current_date between dw.valid_from and coalesce(dw.valid_to, current_date + 36500)
  where ii.invoice_id = v_invoice;
  v_disc := least(coalesce(v_disc,0), v_gross);

  if v_paid <= 0 then v_state := 'ISSUED';
  elsif v_paid >= (v_gross - v_disc) then v_state := 'PAID';
  else v_state := 'PARTIALLY_PAID'; end if;

  update public.invoices
     set paid_total = greatest(v_paid, 0),
         discount_total = v_disc,
         status = case when status = 'VOID' then status else v_state end
   where id = v_invoice;
  return null;
end;
$$;
create trigger allocations_maintain_invoice
  after insert or update or delete on public.allocations
  for each row execute function public.maintain_invoice_status();

-- ---------------------------------------------------------------------------
-- Reconciliation view (per cashier per day)
-- ---------------------------------------------------------------------------
create or replace view public.finance_day_reconciliation
with (security_invoker = true) as
  select p.tenant_id, p.campus_id, p.paid_at::date as day,
         p.received_by,
         p.method,
         count(*) as txn_count,
         sum(case when p.status = 'CLEARED' and p.reversal_of is null then p.amount else 0 end) as collected,
         sum(case when p.reversal_of is not null then -p.amount else 0 end) as reversed
  from public.payments p
  group by 1,2,3,4,5;

-- ---------------------------------------------------------------------------
-- Generate invoices for a plan (trusted; one invoice per student/period)
-- ---------------------------------------------------------------------------
create or replace function app.generate_invoices(
  p_tenant uuid, p_campus uuid, p_plan uuid, p_period text, p_due date
) returns int
language plpgsql security definer set search_path = public as $$
declare
  v_class uuid; v_count int := 0;
  e record; it record; v_invoice uuid; v_no text;
  v_gross numeric;
begin
  if not app.has_tenant_permission('finance.collect', p_tenant) then raise exception 'FORBIDDEN'; end if;
  if not app.can_access_campus(p_tenant, p_campus) then raise exception 'FORBIDDEN'; end if;

  select class_id into v_class from public.fee_plans where id = p_plan and tenant_id = p_tenant;
  if v_class is null then raise exception 'PLAN_NOT_FOUND'; end if;

  for e in
    select en.id as enrollment_id, en.student_id
    from public.enrollments en
    join public.students s on s.id = en.student_id
    where en.tenant_id = p_tenant and en.campus_id = p_campus
      and en.status = 'ACTIVE' and s.status = 'ACTIVE'
      and (v_class is null or en.class_id = v_class)
      and not exists (
        select 1 from public.invoices i
        where i.student_id = en.student_id and i.billing_period = p_period
      )
  loop
    loop
      v_no := 'INV-' || to_char(now(),'YYMM') || '-' || upper(substr(md5(random()::text || e.student_id::text), 1, 6));
      begin
        insert into public.invoices (tenant_id, campus_id, invoice_no, student_id, enrollment_id, billing_period, due_date, status, created_by)
        values (p_tenant, p_campus, v_no, e.student_id, e.enrollment_id, p_period, p_due, 'ISSUED', app.jwt_uid())
        returning id into v_invoice;
        exit;
      exception when unique_violation then
        continue;
      end;
    end loop;

    v_gross := 0;
    for it in select * from public.fee_plan_items where plan_id = p_plan loop
      insert into public.invoice_items (tenant_id, invoice_id, fee_head_id, description, amount)
      values (p_tenant, v_invoice, it.fee_head_id,
              (select name from public.fee_heads where id = it.fee_head_id), it.amount);
      v_gross := v_gross + it.amount;
    end loop;

    update public.invoices set gross_total = v_gross where id = v_invoice;
    v_count := v_count + 1;
  end loop;

  perform app.write_audit('finance.invoices_generated','invoices',null,
    jsonb_build_object('plan', p_plan, 'period', p_period, 'count', v_count), p_tenant, p_campus);

  return v_count;
end;
$$;

grant execute on function app.generate_invoices(uuid, uuid, uuid, text, date) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.fee_heads enable row level security;
alter table public.fee_plans enable row level security;
alter table public.fee_plan_items enable row level security;
alter table public.discounts_waivers enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.payments enable row level security;
alter table public.receipts enable row level security;
alter table public.allocations enable row level security;

create policy fee_heads_select on public.fee_heads for select to authenticated using (
  tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null)
);
create policy fee_heads_write on public.fee_heads for insert to authenticated with check (
  app.has_tenant_permission('finance.collect', tenant_id)
);
create policy fee_heads_update on public.fee_heads for update to authenticated using (
  app.has_tenant_permission('finance.collect', tenant_id)
) with check (
  app.has_tenant_permission('finance.collect', tenant_id)
);

create policy fee_plans_select on public.fee_plans for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy fee_plans_write on public.fee_plans for insert to authenticated with check (
  app.has_tenant_permission('finance.collect', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);
create policy fee_plans_update on public.fee_plans for update to authenticated using (
  app.has_tenant_permission('finance.collect', tenant_id)
) with check (
  app.has_tenant_permission('finance.collect', tenant_id)
);

create policy fee_plan_items_select on public.fee_plan_items for select to authenticated using (
  tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null)
);
create policy fee_plan_items_write on public.fee_plan_items for insert to authenticated with check (
  app.has_tenant_permission('finance.collect', tenant_id)
);
create policy fee_plan_items_update on public.fee_plan_items for update to authenticated using (
  app.has_tenant_permission('finance.collect', tenant_id)
) with check (
  app.has_tenant_permission('finance.collect', tenant_id)
);
create policy fee_plan_items_delete on public.fee_plan_items for delete to authenticated using (
  app.has_tenant_permission('finance.collect', tenant_id)
);

-- Parents/students see their own invoices (read-only)
create policy invoices_select on public.invoices for select to authenticated using (
  (
    app.has_tenant_permission('finance.private.view', tenant_id)
    and app.can_access_campus(tenant_id, campus_id)
  )
  or exists (select 1 from public.students s where s.id = student_id and (app.is_self_student(s.id) or app.is_guardian_of(s.id)))
);

create policy invoices_insert on public.invoices for insert to authenticated with check (
  app.has_tenant_permission('finance.collect', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
);

create policy invoices_update on public.invoices for update to authenticated using (
  app.has_tenant_permission('finance.collect', tenant_id)
) with check (
  app.has_tenant_permission('finance.collect', tenant_id)
);

create policy invoice_items_select on public.invoice_items for select to authenticated using (
  exists (select 1 from public.invoices i where i.id = invoice_items.invoice_id and (
    (app.has_tenant_permission('finance.private.view', i.tenant_id) and app.can_access_campus(i.tenant_id, i.campus_id))
    or exists (select 1 from public.students s where s.id = i.student_id and (app.is_self_student(s.id) or app.is_guardian_of(s.id)))
  ))
);
create policy invoice_items_write on public.invoice_items for insert to authenticated with check (
  app.has_tenant_permission('finance.collect', tenant_id)
);
create policy invoice_items_update on public.invoice_items for update to authenticated using (
  app.has_tenant_permission('finance.collect', tenant_id)
) with check (
  app.has_tenant_permission('finance.collect', tenant_id)
);
create policy invoice_items_delete on public.invoice_items for delete to authenticated using (
  app.has_tenant_permission('finance.collect', tenant_id)
);

create policy payments_select on public.payments for select to authenticated using (
  (
    app.has_tenant_permission('finance.private.view', tenant_id)
    and app.can_access_campus(tenant_id, campus_id)
  )
  or exists (select 1 from public.students s where s.id = student_id and (app.is_self_student(s.id) or app.is_guardian_of(s.id)))
);

create policy payments_insert on public.payments for insert to authenticated with check (
  app.has_tenant_permission('finance.collect', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
  and received_by = app.jwt_uid()
  and status = 'CLEARED'
  and reversal_of is null
);

create policy receipts_select on public.receipts for select to authenticated using (
  exists (select 1 from public.payments p where p.id = receipts.payment_id and (
    (app.has_tenant_permission('finance.private.view', p.tenant_id) and app.can_access_campus(p.tenant_id, p.campus_id))
    or exists (select 1 from public.students s where s.id = p.student_id and (app.is_self_student(s.id) or app.is_guardian_of(s.id)))
  ))
);

create policy receipts_insert on public.receipts for insert to authenticated with check (
  exists (select 1 from public.payments p where p.id = receipts.payment_id and p.received_by = app.jwt_uid())
);

create policy allocations_select on public.allocations for select to authenticated using (
  tenant_id in (select tenant_id from app.active_memberships() where tenant_id is not null)
  or exists (
    select 1 from public.payments p
    where p.id = allocations.payment_id
      and (app.is_self_student(p.student_id) or app.is_guardian_of(p.student_id))
  )
);

create policy allocations_insert on public.allocations for insert to authenticated with check (
  exists (select 1 from public.payments p where p.id = allocations.payment_id and p.received_by = app.jwt_uid())
  and amount > 0
);
-- No update/delete policies: allocations are immutable (reversals are negative rows).

create policy discounts_select on public.discounts_waivers for select to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
);
create policy discounts_insert on public.discounts_waivers for insert to authenticated with check (
  app.has_tenant_permission('finance.collect', tenant_id)
  and app.can_access_campus(tenant_id, campus_id)
  and status = 'PENDING'
  and requested_by = app.jwt_uid()
);
create policy discounts_update on public.discounts_waivers for update to authenticated using (
  app.can_access_campus(tenant_id, campus_id)
  and (
    app.has_tenant_permission('finance.discount.approve', tenant_id)
    or app.has_tenant_permission('finance.collect', tenant_id)
  )
) with check (
  app.can_access_campus(tenant_id, campus_id)
  and (
    (app.has_tenant_permission('finance.discount.approve', tenant_id)
      or (app.has_tenant_permission('finance.collect', tenant_id) and status = 'PENDING' and approver is null))
  )
);
-- Discount approval with amount/limits is enforced by trigger below.
create or replace function public.assert_discount_decision()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status and new.status in ('APPROVED','REJECTED') then
    if not app.has_permission('finance.discount.approve') then
      raise exception 'FORBIDDEN: only finance approvers decide discounts';
    end if;
    if coalesce(old.reason,'') = '' then raise exception 'REASON_REQUIRED'; end if;
    new.approver := app.jwt_uid();
    new.decided_at := now();
  end if;
  return new;
end;
$$;
create trigger discounts_decision_guard
  before update on public.discounts_waivers
  for each row execute function public.assert_discount_decision();
