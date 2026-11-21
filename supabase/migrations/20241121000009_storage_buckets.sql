-- ============================================================================
-- KSMS Migration 0009 — Private Storage Buckets + Policies
-- ============================================================================

-- Tenant-wide access helper for storage path resolution
create or replace function app.can_access_tenant(p_tenant uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from app.active_memberships() where tenant_id = p_tenant)
$$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('private-documents', 'private-documents', false, 15728640,
        array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set file_size_limit = excluded.file_size_limit;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 2097152, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set file_size_limit = excluded.file_size_limit;

-- Path conventions:
--   private-documents/ar/{access_request_id}/{filename}      -> access-request evidence
--   private-documents/tenants/{tenant_id}/{kind}/{id}/{fn}   -> tenant documents
--   avatars/{user_id}/{filename}                             -> profile photos

-- INSERT
create policy ksms_storage_insert on storage.objects for insert to authenticated with check (
  bucket_id = 'private-documents'
  and (
    (
      (storage.foldername(name))[1] = 'ar'
      and exists (
        select 1 from public.access_requests ar
        where ar.id::text = (storage.foldername(name))[2]
          and (ar.requester_user_id = app.jwt_uid()
               or app.has_tenant_permission('students.read', ar.target_tenant_id)
               or app.is_platform_admin())
      )
    )
    or (
      (storage.foldername(name))[1] = 'tenants'
      and app.can_access_tenant(((storage.foldername(name))[2])::uuid)
    )
  )
);

create policy ksms_storage_insert_anon on storage.objects for insert to anon with check (
  bucket_id = 'private-documents'
  and (storage.foldername(name))[1] = 'ar'
  and (storage.foldername(name))[2] is not null
);

create policy ksms_avatars_insert on storage.objects for insert to authenticated with check (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = app.jwt_uid()::text
);

-- SELECT (read via signed URLs or downloads)
create policy ksms_storage_select on storage.objects for select to authenticated using (
  bucket_id = 'private-documents'
  and (
    (
      (storage.foldername(name))[1] = 'ar'
      and exists (
        select 1 from public.access_requests ar
        where ar.id::text = (storage.foldername(name))[2]
          and (ar.requester_user_id = app.jwt_uid()
               or app.is_platform_admin()
               or (app.is_gov_admin()
                   and ar.institution_type = 'GOVERNMENT'
                   and app.has_permission('requests.review.government')))
      )
    )
    or (
      (storage.foldername(name))[1] = 'tenants'
      and app.can_access_tenant(((storage.foldername(name))[2])::uuid)
    )
  )
);

create policy ksms_avatars_select on storage.objects for select to authenticated using (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = app.jwt_uid()::text
);

-- UPDATE (replace) & DELETE (only uploader or platform admin)
create policy ksms_storage_update on storage.objects for update to authenticated using (
  bucket_id = 'private-documents'
  and (
    (
      (storage.foldername(name))[1] = 'ar'
      and exists (
        select 1 from public.access_requests ar
        where ar.id::text = (storage.foldername(name))[2]
          and (ar.requester_user_id = app.jwt_uid() or app.is_platform_admin())
      )
    )
    or (
      (storage.foldername(name))[1] = 'tenants'
      and app.can_access_tenant(((storage.foldername(name))[2])::uuid)
    )
  )
) with check (
  bucket_id = 'private-documents'
);

create policy ksms_storage_delete on storage.objects for delete to authenticated using (
  bucket_id = 'private-documents'
  and (
    (
      (storage.foldername(name))[1] = 'ar'
      and exists (
        select 1 from public.access_requests ar
        where ar.id::text = (storage.foldername(name))[2]
          and (ar.requester_user_id = app.jwt_uid() or app.is_platform_admin())
      )
    )
    or (
      (storage.foldername(name))[1] = 'tenants'
      and app.has_tenant_permission('settings.read', ((storage.foldername(name))[2])::uuid)
    )
  )
);

create policy ksms_avatars_update on storage.objects for update to authenticated using (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = app.jwt_uid()::text
) with check (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = app.jwt_uid()::text
);
