-- My Fitness Date — Brand Administration (DRAFT, no self-provisioning).
-- Independent administrative persona; not a FitDating member or moderator.
-- Must be applied only with reviewed migration and dedicated administrator identity.
-- No real admin is seeded here. All new tables start empty, strictly denied.
-- Assets are PRIVATE until a separate validated release publishes them.
begin;

create table app_private.brand_administrators (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','designer')),
  active boolean not null default true,
  appointed_at timestamptz not null default now(),
  appointed_by uuid references auth.users(id)
);
alter table app_private.brand_administrators enable row level security;
revoke all on app_private.brand_administrators from public, anon, authenticated;

-- Do not assign permissions from editable metadata or email addresses.
-- Real admin credentials must be provisioned separately; using a member
-- account's user_id is explicitly rejected.
create function app_private.is_brand_administrator(p_require_mfa boolean default true)
returns boolean language sql security definer set search_path = '' stable as $$
  select (select auth.uid()) is not null
    and (not p_require_mfa or (select auth.jwt()->>'aal') = 'aal2')
    and exists (
      select 1 from app_private.brand_administrators a
      join auth.users u on u.id = a.user_id
      where a.user_id = (select auth.uid())
        and a.active
        and u.email_confirmed_at is not null
        and not exists (
          select 1 from public.member_profiles_v26 m
          where m.user_id = a.user_id
        )
    );
$$;

create function app_private.is_brand_owner()
returns boolean language sql security definer set search_path = '' stable as $$
  select app_private.is_brand_administrator(true)
    and exists (
      select 1 from app_private.brand_administrators a
      where a.user_id = (select auth.uid()) and a.role = 'owner'
    );
$$;

create function public.brand_admin_status()
returns boolean language sql security invoker set search_path = '' stable as $$
  select app_private.is_brand_administrator(false);
$$;
create function public.brand_admin_session()
returns boolean language sql security invoker set search_path = '' stable as $$
  select app_private.is_brand_administrator(true);
$$;

revoke all on function app_private.is_brand_administrator(boolean) from public, anon, authenticated;
revoke all on function app_private.is_brand_owner() from public, anon, authenticated;
revoke all on function public.brand_admin_status() from public, anon, authenticated;
revoke all on function public.brand_admin_session() from public, anon, authenticated;
grant usage on schema app_private to authenticated;
grant execute on function app_private.is_brand_administrator(boolean) to authenticated;
grant execute on function app_private.is_brand_owner() to authenticated;
grant execute on function public.brand_admin_status() to authenticated;
grant execute on function public.brand_admin_session() to authenticated;

create table public.brand_palettes (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 2 and 70),
  colors jsonb not null check (
    jsonb_typeof(colors) = 'object'
    and pg_column_size(colors) < 2048
    and colors->>'primary' ~ '^#[0-9a-fA-F]{6}$'
    and colors->>'accent' ~ '^#[0-9a-fA-F]{6}$'
    and colors->>'background' ~ '^#[0-9a-fA-F]{6}$'
  ),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
alter table public.brand_palettes enable row level security;
revoke all on public.brand_palettes from public, anon, authenticated;
grant select,insert on public.brand_palettes to authenticated;
create policy brand_palette_admin_read on public.brand_palettes
  for select to authenticated using ((select app_private.is_brand_administrator(true)));
create policy brand_palette_admin_insert on public.brand_palettes
  for insert to authenticated with check (
    (select app_private.is_brand_administrator(true))
    and created_by = (select auth.uid())
  );

create table public.brand_design_drafts (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 2 and 100),
  settings jsonb not null check (
    jsonb_typeof(settings) = 'object'
    and pg_column_size(settings) <= 65536
  ),
  revision integer not null default 1 check (revision between 1 and 1000000),
  created_by uuid not null references auth.users(id),
  updated_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.brand_design_drafts enable row level security;
revoke all on public.brand_design_drafts from public, anon, authenticated;
grant select,insert on public.brand_design_drafts to authenticated;
grant update (title,settings,revision,updated_by,updated_at)
  on public.brand_design_drafts to authenticated;
create policy brand_draft_admin_read on public.brand_design_drafts
  for select to authenticated using ((select app_private.is_brand_administrator(true)));
create policy brand_draft_admin_insert on public.brand_design_drafts
  for insert to authenticated with check (
    (select app_private.is_brand_administrator(true))
    and created_by = (select auth.uid())
    and updated_by = (select auth.uid()) and revision = 1
  );
create policy brand_draft_admin_update on public.brand_design_drafts
  for update to authenticated
  using ((select app_private.is_brand_administrator(true)))
  with check (
    (select app_private.is_brand_administrator(true))
    and updated_by = (select auth.uid())
  );

-- Asset catalogue stores pointers only. No remote/HTML/SVG uploads allowed.
create table public.brand_assets (
  id uuid primary key default gen_random_uuid(),
  asset_kind text not null check (
    asset_kind in ('logo','font','cover_desktop','cover_mobile',
      'login_image','onboarding_image','app_image','icon','illustration')
  ),
  name text not null check (char_length(btrim(name)) between 2 and 100),
  storage_path text not null unique check (char_length(storage_path) between 40 and 260),
  mime_type text not null check (
    mime_type in ('image/png','image/jpeg','image/webp','font/woff2')
  ),
  bytes bigint not null check (bytes between 1 and 8388608),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  check (split_part(storage_path,'/',1)=created_by::text),
  check (
    (asset_kind = 'font' and mime_type = 'font/woff2')
    or (asset_kind <> 'font' and mime_type <> 'font/woff2')
  )
);
alter table public.brand_assets enable row level security;
revoke all on public.brand_assets from public, anon, authenticated;
grant select,insert on public.brand_assets to authenticated;
create policy brand_asset_admin_read on public.brand_assets
  for select to authenticated using ((select app_private.is_brand_administrator(true)));
create policy brand_asset_admin_insert on public.brand_assets
  for insert to authenticated with check (
    (select app_private.is_brand_administrator(true))
    and created_by = (select auth.uid())
  );

-- Release request is not production publication. Requires subsequent
-- auditable CI/approval and asset processing/safe CDN.
create table public.brand_release_requests (
  id uuid primary key default gen_random_uuid(),
  draft_id uuid not null references public.brand_design_drafts(id),
  revision integer not null check(revision > 0),
  status text not null default 'pending_review'
    check(status in ('pending_review','approved','rejected','deployed')),
  requested_by uuid not null references auth.users(id),
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz
);
alter table public.brand_release_requests enable row level security;
revoke all on public.brand_release_requests from public, anon, authenticated;
grant select,insert on public.brand_release_requests to authenticated;
create policy brand_release_owner_read on public.brand_release_requests
  for select to authenticated using ((select app_private.is_brand_owner()));
create policy brand_release_owner_insert on public.brand_release_requests
  for insert to authenticated with check (
    (select app_private.is_brand_owner())
    and requested_by = (select auth.uid())
    and status = 'pending_review' and reviewed_at is null
  );

-- Restrictive media bucket: no public file access, no overwrite or delete.
insert into storage.buckets
  (id,name,public,file_size_limit,allowed_mime_types)
values
  ('mfd-brand-drafts','mfd-brand-drafts',false,8388608,
   array['image/png','image/jpeg','image/webp','font/woff2'])
on conflict (id) do nothing;

create policy mfd_brand_drafts_admin_select on storage.objects
  for select to authenticated using (
    bucket_id = 'mfd-brand-drafts'
    and (select app_private.is_brand_administrator(true))
  );
create policy mfd_brand_drafts_admin_insert on storage.objects
  for insert to authenticated with check (
    bucket_id = 'mfd-brand-drafts'
    and (select app_private.is_brand_administrator(true))
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and lower(name) ~ '\.(png|jpe?g|webp|woff2)$'
  );

-- No INSERT privileges or policies for anon. No privileged client keys.
-- Rollback is a new migration; do not wipe admin settings or assets.
commit;
