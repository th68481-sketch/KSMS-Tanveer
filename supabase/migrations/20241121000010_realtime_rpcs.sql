-- ============================================================================
-- KSMS Migration 0010 — Realtime, Promotion / Leaving Certificates,
-- Export Logging, Reporting RPCs
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Realtime publication (RLS applies to websocket subscribers as well)
-- ---------------------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;

do $$
begin
  alter publication supabase_realtime add table public.notices;
exception when duplicate_object then null; end $$;

do $$
begin
  alter publication supabase_realtime add table public.homework;
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- Promotion / transfer / withdrawal / leaving certificate
-- ---------------------------------------------------------------------------
create or replace function app.promote_students(
  p_to_year uuid, p_to_class uuid, p_to_section uuid, p_from_enrollments uuid[]
) returns int
language plpgsql security definer set search_path = public as $$
declare
  v_count int := 0; v_tenant uuid; v_campus uuid; e record; v_new uuid;
begin
  if not app.has_permission('students.write') then raise exception 'FORBIDDEN'; end if;

  select tenant_id, campus_id into v_tenant, v_campus
  from public.enrollments where id = p_from_enrollments[1];
  if v_tenant is null then raise exception 'NO_ENROLLMENTS'; end if;
  if not app.can_access_campus(v_tenant, v_campus) then raise exception 'FORBIDDEN'; end if;

  for e in
    select * from public.enrollments
    where id = any(p_from_enrollments) and status = 'ACTIVE' and tenant_id = v_tenant
  loop
    if exists (select 1 from public.enrollments x where x.student_id = e.student_id and x.academic_year_id = p_to_year) then
      continue; -- already promoted / enrolled for the target year
    end if;

    insert into public.enrollments (tenant_id, campus_id, student_id, academic_year_id, class_id, section_id, admission_date, status, previous_enrollment_id)
    values (v_tenant, v_campus, e.student_id, p_to_year, p_to_class, p_to_section, current_date, 'ACTIVE', e.id)
    returning id into v_new;

    update public.enrollments set status = 'PROMOTED' where id = e.id;
    v_count := v_count + 1;
  end loop;

  perform app.write_audit('students.promoted','enrollments',null,
    jsonb_build_object('count', v_count, 'to_year', p_to_year, 'to_section', p_to_section), v_tenant, v_campus);

  return v_count;
end;
$$;

grant execute on function app.promote_students(uuid, uuid, uuid, uuid[]) to authenticated;

create or replace function app.issue_leaving_certificate(
  p_enrollment uuid, p_final_status text, p_reason text
) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_en public.enrollments%rowtype;
  v_lc text;
begin
  if not app.has_permission('students.write') then raise exception 'FORBIDDEN'; end if;
  if p_final_status not in ('TRANSFERRED','WITHDRAWN') then raise exception 'INVALID_STATUS'; end if;

  select * into v_en from public.enrollments where id = p_enrollment;
  if v_en.id is null then raise exception 'ENROLLMENT_NOT_FOUND'; end if;
  if not app.can_access_campus(v_en.tenant_id, v_en.campus_id) then raise exception 'FORBIDDEN'; end if;
  if v_en.leaving_certificate_no is not null then raise exception 'ALREADY_LEFT'; end if;

  v_lc := 'LC-' || to_char(now(),'YYYY') || '-' || upper(substr(md5(random()::text || p_enrollment::text), 1, 8));

  update public.enrollments
     set status = p_final_status,
         leaving_certificate_no = v_lc,
         leaving_date = current_date,
         leaving_reason = p_reason
   where id = p_enrollment;

  update public.students set status = 'ALUMNUS'
  where id = v_en.student_id and not exists (
    select 1 from public.enrollments x where x.student_id = v_en.student_id and x.status = 'ACTIVE' and x.id <> p_enrollment
  );

  perform app.write_audit('students.leaving_certificate_issued','enrollments',p_enrollment,
    jsonb_build_object('certificate', v_lc, 'status', p_final_status, 'reason', p_reason),
    v_en.tenant_id, v_en.campus_id);

  return v_lc;
end;
$$;

grant execute on function app.issue_leaving_certificate(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Export logging (client exports must call this; append-only audit)
-- ---------------------------------------------------------------------------
create or replace function app.log_export(p_tenant uuid, p_entity text, p_details jsonb default '{}'::jsonb)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_tenant is not null and not app.can_access_tenant(p_tenant) then raise exception 'FORBIDDEN'; end if;
  perform app.write_audit('report.exported', p_entity, null,
    jsonb_build_object('format', p_details ->> 'format', 'report', p_details ->> 'report'), p_tenant);
end;
$$;

grant execute on function app.log_export(uuid, text, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Government SEMIS export dataset (row-level filtered)
-- ---------------------------------------------------------------------------
create or replace view public.semis_export
with (security_invoker = true) as
  select t.id as tenant_id, t.name as school_name, t.semis_code,
         c.name as campus_name, c.semis_code as campus_semis_code, c.city,
         (select count(*) from public.enrollments en where en.campus_id = c.id and en.status = 'ACTIVE') as enrolled_students,
         (select count(*) from public.staff st where st.campus_id = c.id and st.status = 'ACTIVE') as active_staff
  from public.tenants t
  join public.campuses c on c.tenant_id = t.id
  where t.type = 'GOVERNMENT';

-- ---------------------------------------------------------------------------
-- Expired access requests helper (callable by scheduled trigger / edge fn)
-- ---------------------------------------------------------------------------
create or replace function app.expire_stale_requests()
returns int
language sql security definer set search_path = public as $$
  with moved as (
    update public.access_requests
       set state = 'REJECTED', decision_reason = 'Auto-expired after 30 days'
     where state in ('REQUESTED','PENDING_REVIEW','NEEDS_INFORMATION')
       and expires_at < now()
    returning 1
  )
  select count(*) from moved
$$;
