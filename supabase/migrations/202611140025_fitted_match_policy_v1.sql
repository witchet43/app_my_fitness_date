-- Fitted v1 · operator-controlled scoring weights. Does not enable dating.
-- All exposed calls require the existing AAL2/owner role predicate.
begin;

create table if not exists app_private.fitted_match_policy (
  id boolean primary key default true check(id),
  version bigint not null default 1 check(version>=1),
  weights jsonb not null,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);
alter table app_private.fitted_match_policy enable row level security;
revoke all on app_private.fitted_match_policy from public,anon,authenticated;

create table if not exists app_private.fitted_match_policy_audit (
  version bigint primary key,
  weights jsonb not null,
  changed_by uuid not null references auth.users(id),
  changed_at timestamptz not null default now()
);
alter table app_private.fitted_match_policy_audit enable row level security;
revoke all on app_private.fitted_match_policy_audit from public,anon,authenticated;

create function app_private.valid_fitted_match_weights(p jsonb)
returns boolean language sql immutable security invoker set search_path=''
as $$
  select p is not null and jsonb_typeof(p)='object'
    and (select count(*) from jsonb_object_keys(p))=6
    and not exists (
      select 1 from jsonb_object_keys(p) as k(key)
      where k.key <> all(array['intent','lifestyle','rhythm','recovery','autonomy','sport'])
    )
    and not exists (
      select 1 from jsonb_each_text(p) as w(k,v)
      where w.v !~ '^(0|[1-9][0-9]?|100)$'
    )
    and (select coalesce(sum(value::integer),0)
      from jsonb_each_text(p))=100;
$$;
revoke all on function app_private.valid_fitted_match_weights(jsonb) from public,anon,authenticated;

insert into app_private.fitted_match_policy (id,version,weights)
values (true,1,'{"intent":25,"lifestyle":20,"rhythm":20,"recovery":15,"autonomy":10,"sport":10}'::jsonb)
on conflict (id) do nothing;

create function public.admin_fitted_match_policy_get()
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare cfg app_private.fitted_match_policy%rowtype;
begin
  if (select auth.uid()) is null or not app_private.is_brand_owner() then
    return jsonb_build_object('status','forbidden');
  end if;
  select * into cfg from app_private.fitted_match_policy where id=true;
  return jsonb_build_object(
    'status','ok','version',cfg.version,'weights',cfg.weights,
    'algorithm','fitted-compatibility-v1','discovery_enabled',false);
end;
$$;

create function public.admin_fitted_match_policy_save(
  p_weights jsonb,p_expected_version bigint
)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare cfg app_private.fitted_match_policy%rowtype;
begin
  if (select auth.uid()) is null or not app_private.is_brand_owner() then
    return jsonb_build_object('status','forbidden');
  end if;
  if not app_private.valid_fitted_match_weights(p_weights) then
    return jsonb_build_object('status','invalid');
  end if;
  select * into strict cfg from app_private.fitted_match_policy
    where id=true for update;
  if p_expected_version is distinct from cfg.version then
    return jsonb_build_object('status','conflict','version',cfg.version);
  end if;
  update app_private.fitted_match_policy set
    version=cfg.version+1,weights=p_weights,
    updated_by=(select auth.uid()),updated_at=now()
  where id=true;
  insert into app_private.fitted_match_policy_audit
    (version,weights,changed_by)
  values(cfg.version+1,p_weights,(select auth.uid()));
  return jsonb_build_object(
    'status','saved','version',cfg.version+1,
    'weights',p_weights,'algorithm','fitted-compatibility-v1',
    'discovery_enabled',false);
end;
$$;

revoke all on function public.admin_fitted_match_policy_get(),
  public.admin_fitted_match_policy_save(jsonb,bigint)
  from public,anon,authenticated;
grant execute on function public.admin_fitted_match_policy_get(),
  public.admin_fitted_match_policy_save(jsonb,bigint)
  to authenticated;

commit;
