-- Fitted v1: deterministic explainable server-side compatibility.
-- Access is restricted to age-verified, consented, discoverable members;
-- return aggregate scores and reason codes, NEVER raw profile answers.
begin;
create function app_private.fitted_score_pair_v1(p_a uuid,p_b uuid)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare
  a jsonb;
  b jsonb;
  cfg jsonb;
  current_version bigint;
  factor text;
  weight integer;
  score numeric;
  earned numeric:=0;
  covered numeric:=0;
  n integer;
  total numeric;
  code text;
  why jsonb:='[]'::jsonb;
  k text;
  aa text;
  bb text;
begin
  if p_a is null or p_b is null or p_a=p_b
     or not app_private.b11_pair_allowed(p_a,p_b)
  then return jsonb_build_object('available',false); end if;
  select r.answers into a from public.member_rhythm_b11 r where r.user_id=p_a;
  select r.answers into b from public.member_rhythm_b11 r where r.user_id=p_b;
  select p.weights,p.version into cfg,current_version
    from app_private.fitted_match_policy p where p.id=true;
  if a is null or b is null or cfg is null then
    return jsonb_build_object('available',false);
  end if;
  for factor,weight in
    select key,value::integer from jsonb_each_text(cfg)
  loop
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
    else
      n:=0;total:=0;
      for k in select unnest(case factor
        when 'lifestyle' then array['weekday','travel']
        when 'rhythm' then array['frequency','training_mode']
        when 'recovery' then array['sleep']
        when 'autonomy' then array['together','train_partner']
        else array[]::text[] end)
      loop
        aa:=a->>k;bb:=b->>k;
        if aa is not null and bb is not null then
          n:=n+1;
          total:=total+case when aa=bb then 1
            when aa='flexible' or bb='flexible' then 0.8
            else 0.45 end;
        end if;
      end loop;
      if n>0 then score:=total/n; end if;
    end if;
    if score is not null then
      covered:=covered+weight;
      earned:=earned+weight*score;
      if score>=0.8 and factor<>'sport' then code:='aligned_'||factor; end if;
      why:=why||jsonb_build_array(code);
    end if;
  end loop;
  if covered<70 or a->>'intent' is null or b->>'intent' is null then
    return jsonb_build_object('available',false,'insufficient_evidence',true);
  end if;
  return jsonb_build_object(
    'available',true,
    'percent',round(100*earned/covered),
    'coverage',covered,
    'reason_codes',why,
    'algorithm','fitted-compatibility-v1',
    'policy_version',current_version
  );
end;
$$;
revoke all on function app_private.fitted_score_pair_v1(uuid,uuid)
 from public,anon,authenticated;

create function public.fitted_match_score_v1(p_user_id uuid)
returns jsonb language plpgsql volatile security definer set search_path=''
as $$
declare
  viewer uuid:=(select auth.uid());
begin
  if viewer is null or p_user_id is null
     or not app_private.b11_pair_allowed(viewer,p_user_id)
     or not exists(
       select 1 from app_private.discover_dating_candidates(30) c
       where c.user_id=p_user_id)
  then return jsonb_build_object('available',false); end if;
  perform app_private.consume_dating_quota('discover',3600,10);
  return app_private.fitted_score_pair_v1(viewer,p_user_id);
end;
$$;
revoke all on function public.fitted_match_score_v1(uuid)
 from public,anon,authenticated;
grant execute on function public.fitted_match_score_v1(uuid) to authenticated;
commit;
