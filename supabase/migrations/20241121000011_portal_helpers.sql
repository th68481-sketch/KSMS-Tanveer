-- ============================================================================
-- KSMS Migration 0011 — Portal lookup + self-activation helpers
-- ============================================================================

-- Public, privacy-safe tenant lookup for staff access requests
create or replace function app.public_tenant_lookup(p_query text)
returns table (id uuid, name text, type tenant_type, city text)
language sql stable security definer set search_path = public as $$
  select t.id, t.name, t.type, t.city
  from public.tenants t
  where t.status = 'ACTIVE'
    and (t.name ilike '%' || p_query || '%' or t.city ilike '%' || p_query || '%')
  order by t.name
  limit 20
$$;

grant execute on function app.public_tenant_lookup(text) to anon, authenticated;

-- Flip INVITED -> ACTIVE on first signed-in use
create or replace function app.activate_my_memberships()
returns int
language plpgsql security definer set search_path = public as $$
declare v_count int;
begin
  with moved as (
    update public.memberships
       set status = 'ACTIVE', activated_at = now()
     where user_id = app.jwt_uid() and status = 'INVITED'
    returning 1
  )
  select count(*) into v_count from moved;
  return v_count;
end;
$$;

grant execute on function app.activate_my_memberships() to authenticated;
