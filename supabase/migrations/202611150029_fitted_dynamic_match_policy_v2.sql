-- Fitted v2: supported editable match factors; distance remains a filter.
-- Existing policy data and audit history are preserved.
begin;

create or replace function app_private.valid_fitted_match_weights(p jsonb)
returns boolean language plpgsql immutable set search_path=''
as $$
declare
  key text;
  value text;
  total integer:=0;
  enabled integer:=0;
begin
  if p is null or jsonb_typeof(p)<>'object' then return false; end if;
  for key,value in select e.key,e.value from jsonb_each_text(p) e loop
    if key not in ('intent','lifestyle','rhythm','recovery','autonomy',
                    'sport','interests','social','competition') or
       value !~ '^(0|[1-9][0-9]?|100)$' then return false; end if;
    total:=total+value::integer;
    if value::integer>0 then enabled:=enabled+1; end if;
  end loop;
  return total=100 and enabled>=3;
end;
$$;

alter table app_private.fitted_match_policy
  add column if not exists max_distance_km integer;
alter table app_private.fitted_match_policy
  drop constraint if exists fitted_match_policy_max_distance_km_check;
alter table app_private.fitted_match_policy
  add constraint fitted_match_policy_max_distance_km_check
  check(max_distance_km is null or max_distance_km between 5 and 250);

create or replace function public.admin_fitted_match_policy_get()
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare cfg app_private.fitted_match_policy%rowtype;
begin
  if (select auth.uid()) is null or not app_private.is_brand_owner()
  then return jsonb_build_object('status','forbidden'); end if;
  select * into cfg from app_private.fitted_match_policy where id=true;
  return jsonb_build_object(
    'status','ok','version',cfg.version,'weights',cfg.weights,
    'max_distance_km',cfg.max_distance_km,
    'supported_factors',jsonb_build_array(
       'intent','lifestyle','rhythm','recovery','autonomy',
       'sport','interests','social','competition'),
    'algorithm','fitted-compatibility-v2',
    'discovery_enabled',false);
end;
$$;

-- Same RPC with an optional distance filter. Filter changes are versioned
-- and audited just like weights. This is not a location-sharing mechanism.
create or replace function public.admin_fitted_match_policy_save(
  p_weights jsonb,p_expected_version bigint,
  p_max_distance_km integer default null
)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare cfg app_private.fitted_match_policy%rowtype;
begin
  if (select auth.uid()) is null or not app_private.is_brand_owner()
  then return jsonb_build_object('status','forbidden'); end if;
  if not app_private.valid_fitted_match_weights(p_weights)
    or (p_max_distance_km is not null and
        (p_max_distance_km<5 or p_max_distance_km>250))
  then return jsonb_build_object('status','invalid'); end if;
  select * into strict cfg from app_private.fitted_match_policy
    where id=true for update;
  if p_expected_version is distinct from cfg.version then
    return jsonb_build_object('status','conflict','version',cfg.version);
  end if;
  update app_private.fitted_match_policy
  set version=cfg.version+1,weights=p_weights,
    max_distance_km=p_max_distance_km,
    updated_by=(select auth.uid()),updated_at=now()
  where id=true;
  insert into app_private.fitted_match_policy_audit
    (version,weights,changed_by)
  values(cfg.version+1,p_weights,(select auth.uid()));
  return jsonb_build_object(
    'status','saved','version',cfg.version+1,
    'weights',p_weights,'max_distance_km',p_max_distance_km,
    'algorithm','fitted-compatibility-v2','discovery_enabled',false);
end;
$$;
revoke all on function public.admin_fitted_match_policy_save(
  jsonb,bigint,integer) from public,anon,authenticated;
grant execute on function public.admin_fitted_match_policy_save(
  jsonb,bigint,integer) to authenticated;

-- Remove old 2-arg writer only after new RPC is available; there must be
-- one audited route for modifications to the current policy.
drop function public.admin_fitted_match_policy_save(jsonb,bigint);

create or replace function app_private.fitted_score_pair_v1(p_a uuid,p_b uuid)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare
  a jsonb;
  b jsonb;
  ar public.member_rhythm_b11%rowtype;
  br public.member_rhythm_b11%rowtype;
  cfg jsonb;
  current_version bigint;
  factor text;
  weight integer;
  score numeric;
  earned numeric:=0;
  covered numeric:=0;
  scored_factors integer:=0;
  n integer;
  total numeric;
  code text;
  reasons jsonb:='[]'::jsonb;
  contributions jsonb:='{}'::jsonb;
  k text;
  aa text;
  bb text;
  common_count integer;
  combined_count integer;
begin
  if p_a is null or p_b is null or p_a=p_b
    or not app_private.b11_pair_allowed(p_a,p_b)
  then return jsonb_build_object('available',false); end if;
  select * into ar from public.member_rhythm_b11 r where r.user_id=p_a;
  select * into br from public.member_rhythm_b11 r where r.user_id=p_b;
  a:=ar.answers;b:=br.answers;
  select p.weights,p.version into cfg,current_version
    from app_private.fitted_match_policy p where p.id=true;
  if a is null or b is null or cfg is null or
     not app_private.valid_fitted_match_weights(cfg)
  then return jsonb_build_object('available',false); end if;

  for factor,weight in select key,value::integer
      from jsonb_each_text(cfg)
  loop
    if weight<=0 then continue; end if;
    score:=null;
    code:='discuss_'||factor;
    if factor='intent' then
      aa:=a->>'intent';bb:=b->>'intent';
      if aa is not null and bb is not null then
        score:=case when aa=bb then 1
          when aa=any(array['long_term','open_to_serious','intentional'])
           and bb=any(array['long_term','open_to_serious','intentional'])
          then 0.85 else 0.25 end;
      end if;
    elsif factor='sport' then
      aa:=a->>'sport';bb:=b->>'sport';
      if aa is not null and bb is not null then
        score:=case when aa=bb then 1 else 0.75 end;
        if aa<>bb then code:='complementary_sports'; end if;
      end if;
    elsif factor='interests' then
      select count(*) into common_count from
        (select unnest(ar.interests) intersect
         select unnest(br.interests)) shared;
      select count(*) into combined_count from
        (select unnest(ar.interests) union
         select unnest(br.interests)) either;
      if cardinality(ar.interests)>0 and
         cardinality(br.interests)>0 and combined_count>0
      then
        score:=0.35+0.65*(common_count::numeric/combined_count);
        if common_count>0 then code:='aligned_interests'; end if;
      end if;
    else
      n:=0;total:=0;
      for k in select unnest(case factor
        when 'lifestyle' then array['weekday','travel']
        when 'rhythm' then array['frequency','training_mode']
        when 'recovery' then array['sleep']
        when 'autonomy' then array['together','train_partner']
        when 'social' then array['weekday','alcohol']
        when 'competition' then array['competitions','training_mode']
        else array[]::text[] end)
      loop
        aa:=a->>k;bb:=b->>k;
        if aa is not null and bb is not null then
          n:=n+1;
          total:=total+case when aa=bb then 1
            when aa='flexible' or bb='flexible' then 0.8
            else 0.45 end;
          if aa=bb then
            if k='sleep' and aa='early_bird' then
              code:='shared_early_sleep';
            elsif k='weekday' and aa='home' then
              code:='shared_quiet_weekdays';
            elsif k='together' and aa='balanced' then
              code:='shared_independence_balance';
            elsif k='frequency' and aa=bb then
              code:='shared_training_frequency';
            end if;
          end if;
        end if;
      end loop;
      if n>0 then score:=total/n; end if;
    end if;
    if score is not null then
      covered:=covered+weight;earned:=earned+weight*score;
      scored_factors:=scored_factors+1;
      contributions:=contributions||jsonb_build_object(
        factor,jsonb_build_object('weight',weight,
          'alignment',round(score*100),'earned',round(score*weight,2)));
      if code='discuss_'||factor and score>=0.8 then
        code:='aligned_'||factor; end if;
      reasons:=reasons||jsonb_build_array(code);
    end if;
  end loop;
  -- Fail closed when substantial evidence or relationship intent is missing.
  if covered<70 or scored_factors<3 or
     a->>'intent' is null or b->>'intent' is null then
    return jsonb_build_object('available',false,
      'insufficient_evidence',true,'coverage',covered);
  end if;
  return jsonb_build_object(
    'available',true,'percent',round(100*earned/covered),
    'coverage',covered,'contributions',contributions,
    'reason_codes',reasons,'algorithm','fitted-compatibility-v2',
    'policy_version',current_version);
end;
$$;

commit;
