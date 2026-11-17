-- Brand Studio: catalogue 0 is the silver F; 1..20 are original vectors.
-- Owner can save no more than 50 palettes, even with concurrent requests.
begin;

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

  if coalesce(p_settings->>'logo','') !~ '^catalog:([0-9]|1[0-9]|20)$'
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

create or replace function app_private.enforce_brand_palette_limit()
returns trigger language plpgsql security invoker set search_path = ''
as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(22016,
    pg_catalog.hashtext(new.created_by::text));
  if (select count(*) from public.brand_palettes
      where created_by = new.created_by) >= 50 then
    raise exception 'Límite de 50 paletas guardadas por administrador'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists brand_palettes_limit_50 on public.brand_palettes;
create trigger brand_palettes_limit_50
before insert on public.brand_palettes
for each row execute function app_private.enforce_brand_palette_limit();

grant delete on public.brand_palettes to authenticated;
drop policy if exists brand_palette_owner_delete on public.brand_palettes;
create policy brand_palette_owner_delete on public.brand_palettes
for delete to authenticated using (
  created_by = (select auth.uid())
  and (select app_private.is_brand_administrator(true))
);

comment on function app_private.enforce_brand_palette_limit() is
  'Per-owner bound of 50 saved palettes with serialized inserts.';

commit;
