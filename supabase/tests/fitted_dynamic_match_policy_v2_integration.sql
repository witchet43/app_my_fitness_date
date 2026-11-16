-- V2 policy integrity, strict supported catalogue and private access.
do $$
declare
 cfg jsonb;
 val bigint;
begin
 select weights,version into cfg,val
 from app_private.fitted_match_policy where id=true;
 if not app_private.valid_fitted_match_weights(cfg) then
   raise exception 'Existing policy not supported after migration';
 end if;
 if not app_private.valid_fitted_match_weights(
   '{"intent":40,"lifestyle":35,"interests":25}'::jsonb) then
   raise exception 'Supported additions incorrectly rejected';
 end if;
 if app_private.valid_fitted_match_weights(
   '{"intent":50,"lifestyle":50}'::jsonb) then
   raise exception 'Only two factors accepted';
 end if;
 if app_private.valid_fitted_match_weights(
   '{"intent":40,"lifestyle":35,"fabricated":25}'::jsonb) then
   raise exception 'Unknown factor allowed';
 end if;
 if app_private.valid_fitted_match_weights(
   '{"intent":40,"lifestyle":35,"sport":24}'::jsonb) then
   raise exception 'Invalid total accepted';
 end if;
 if has_function_privilege('anon',
      'public.admin_fitted_match_policy_save(jsonb,bigint,integer)',
      'execute') then
   raise exception 'Anonymous policy editing allowed';
 end if;
 if not has_function_privilege('authenticated',
      'public.admin_fitted_match_policy_save(jsonb,bigint,integer)',
      'execute') then
   raise exception 'Admin policy editing RPC missing';
 end if;
 if (public.admin_fitted_match_policy_save(
       '{"intent":40,"lifestyle":35,"interests":25}'::jsonb,
        val,50)->>'status') <> 'forbidden'
 then raise exception 'Anonymous policy save not denied'; end if;
 if (app_private.fitted_score_pair_v1(
   '11111111-1111-1111-1111-111111111111'::uuid,
   '22222222-2222-2222-2222-222222222222'::uuid)->>'available')::boolean
 then raise exception 'Ineligible pair received score'; end if;
end;
$$;
