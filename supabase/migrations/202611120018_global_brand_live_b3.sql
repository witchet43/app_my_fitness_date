-- B3: public active brand configuration: no manual review, no CI per edit.
-- Atomic expected-version edits, MFA owner only; anonymous read of sanitized
-- values. History, rollback, immutable public assets and safe defaults.
begin;

create table if not exists public.mfd_brand_live (
  id boolean primary key default true check (id),
  version bigint not null default 0 check (version >= 0),
  settings jsonb not null check (jsonb_typeof(settings) = 'object'),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);
alter table public.mfd_brand_live enable row level security;
revoke all on public.mfd_brand_live from public, anon, authenticated;
grant select on public.mfd_brand_live to anon, authenticated;
drop policy if exists mfd_brand_live_public_read on public.mfd_brand_live;
create policy mfd_brand_live_public_read on public.mfd_brand_live
  for select to anon, authenticated using (id = true);

insert into public.mfd_brand_live (id, version, settings)
values (true, 0, jsonb_build_object(
  'name','My Fitness Date',
  'tagline','Conexiones con intención.',
  'title','Tu próxima conexión también puede compartir tu ritmo.',
  'description','Muestra quién eres, lo que te apasiona y cómo vives el deporte.',
  'paletteName','Original',
  'colors',jsonb_build_object(
    'primary','#FF617B','accent','#C8FF6B','background','#0A0D16'),
  'font','Arial','logo','catalog:0','media','{}'::jsonb,
  'mode','dark','layout','editorial'
))
on conflict (id) do nothing;

create table if not exists app_private.mfd_brand_history (
  version bigint primary key check (version >= 0),
  settings jsonb not null,
  changed_by uuid references auth.users(id),
  changed_at timestamptz not null default now(),
  restored_from bigint
);
alter table app_private.mfd_brand_history enable row level security;
revoke all on app_private.mfd_brand_history from public, anon, authenticated;
insert into app_private.mfd_brand_history (version, settings)
select version, settings from public.mfd_brand_live
on conflict (version) do nothing;

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
) values (
  'mfd-brand-live', 'mfd-brand-live', true, 4194304,
  array['image/png','image/jpeg','image/webp']
) on conflict (id) do nothing;

drop policy if exists mfd_brand_live_admin_upload on storage.objects;
create policy mfd_brand_live_admin_upload on storage.objects
  for insert to authenticated with check (
    bucket_id = 'mfd-brand-live'
    and (select app_private.is_brand_owner())
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and lower(name) ~ '\.(png|jpe?g|webp)$'
  );
-- Public objects are immutable. No member, anonymous or admin client update/
-- delete permissions are created. Existing object versions remain rollback-safe.

create or replace function app_private.is_safe_mfd_public_asset(p_url text)
returns boolean
language sql immutable security invoker
set search_path = ''
as $$
  select coalesce(p_url, '') ~
    '^https://jtrdvnwbxpfdnbzasvcj\.supabase\.co/storage/v1/object/public/mfd-brand-live/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[a-zA-Z0-9_-]{4,100}\.(png|jpg|webp)$';
$$;
revoke all on function app_private.is_safe_mfd_public_asset(text)
  from public, anon, authenticated;

create or replace function app_private.valid_mfd_brand(p_settings jsonb)
returns boolean
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_key text;
  v_value text;
begin
  if p_settings is null or jsonb_typeof(p_settings) <> 'object'
     or pg_column_size(p_settings) > 8192 then
    return false;
  end if;
  for v_key in select jsonb_object_keys(p_settings) loop
    if v_key <> all(array[
      'name','tagline','title','description','paletteName',
      'colors','font','logo','media','mode','layout'
    ]) then return false; end if;
  end loop;
  if char_length(btrim(coalesce(p_settings->>'name',''))) not between 2 and 60 or
     char_length(coalesce(p_settings->>'tagline','')) not between 2 and 120 or
     char_length(coalesce(p_settings->>'title','')) not between 8 and 180 or
     char_length(coalesce(p_settings->>'description','')) not between 10 and 600 or
     char_length(coalesce(p_settings->>'paletteName','')) not between 2 and 70 or
     coalesce(p_settings->>'font','') <> all(array['Georgia','Palatino','Garamond','Arial']) or
     coalesce(p_settings->>'mode','') <> all(array['dark','light']) or
     coalesce(p_settings->>'layout','') <> all(array['editorial','minimal'])
  then return false; end if;

  if jsonb_typeof(p_settings->'colors') <> 'object' or
     coalesce(p_settings->'colors'->>'primary','') !~ '^#[0-9a-fA-F]{6}$' or
     coalesce(p_settings->'colors'->>'accent','') !~ '^#[0-9a-fA-F]{6}$' or
     coalesce(p_settings->'colors'->>'background','') !~ '^#[0-9a-fA-F]{6}$'
  then return false; end if;

  if coalesce(p_settings->>'logo','') !~ '^catalog:[0-9]$'
     and not app_private.is_safe_mfd_public_asset(p_settings->>'logo')
  then return false; end if;

  if jsonb_typeof(p_settings->'media') <> 'object' or
     (select count(*) from jsonb_object_keys(p_settings->'media')) > 3
  then return false; end if;

  for v_key,v_value in
    select key,value from jsonb_each_text(p_settings->'media')
  loop
    if v_key <> all(array['cover_desktop','cover_mobile','app_image'])
      or not app_private.is_safe_mfd_public_asset(v_value)
    then return false; end if;
  end loop;
  return true;
end;
$$;
revoke all on function app_private.valid_mfd_brand(jsonb)
  from public, anon, authenticated;

create or replace function public.brand_set_live(
  p_settings jsonb, p_expected_version bigint
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_current public.mfd_brand_live%rowtype;
  v_next bigint;
begin
  if not app_private.is_brand_owner() then
    return jsonb_build_object('status','forbidden');
  end if;
  if not app_private.valid_mfd_brand(p_settings) then
    return jsonb_build_object('status','invalid');
  end if;
  select * into strict v_current
    from public.mfd_brand_live where id=true for update;
  if p_expected_version is distinct from v_current.version then
    return jsonb_build_object('status','conflict','version',v_current.version);
  end if;
  v_next := v_current.version+1;
  update public.mfd_brand_live set
    version=v_next,settings=p_settings,
    updated_by=(select auth.uid()),updated_at=now()
  where id=true;
  insert into app_private.mfd_brand_history
    (version,settings,changed_by)
  values (v_next,p_settings,(select auth.uid()));
  return jsonb_build_object('status','saved','version',v_next,'settings',p_settings);
end;
$$;
revoke all on function public.brand_set_live(jsonb,bigint)
  from public,anon,authenticated;
grant execute on function public.brand_set_live(jsonb,bigint)
  to authenticated;

create or replace function public.brand_history_live()
returns table (
  version bigint, changed_at timestamptz, restored_from bigint
)
language sql stable security definer set search_path = ''
as $$
  select h.version,h.changed_at,h.restored_from
  from app_private.mfd_brand_history h
  where app_private.is_brand_owner()
  order by h.version desc limit 30;
$$;
revoke all on function public.brand_history_live()
  from public,anon,authenticated;
grant execute on function public.brand_history_live() to authenticated;

create or replace function public.brand_restore_live(
  p_version bigint,p_expected_version bigint
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_current public.mfd_brand_live%rowtype;
  v_previous jsonb;
  v_next bigint;
begin
  if not app_private.is_brand_owner() then
    return jsonb_build_object('status','forbidden');
  end if;
  select * into strict v_current from public.mfd_brand_live
    where id=true for update;
  if v_current.version is distinct from p_expected_version then
    return jsonb_build_object('status','conflict','version',v_current.version);
  end if;
  select h.settings into v_previous
    from app_private.mfd_brand_history h where h.version=p_version;
  if not found then return jsonb_build_object('status','not_found'); end if;
  if not app_private.valid_mfd_brand(v_previous) then
    return jsonb_build_object('status','invalid'); end if;
  v_next := v_current.version+1;
  update public.mfd_brand_live set
    version=v_next,settings=v_previous,
    updated_by=(select auth.uid()),updated_at=now()
  where id=true;
  insert into app_private.mfd_brand_history
    (version,settings,changed_by,restored_from)
  values (v_next,v_previous,(select auth.uid()),p_version);
  return jsonb_build_object('status','saved','version',v_next,
    'settings',v_previous);
end;
$$;
revoke all on function public.brand_restore_live(bigint,bigint)
  from public,anon,authenticated;
grant execute on function public.brand_restore_live(bigint,bigint)
  to authenticated;

comment on table public.mfd_brand_live is
  'Public, sanitized active brand. Owner AAL2 writes only through CAS RPC; no approval or deployment per edit.';
commit;
