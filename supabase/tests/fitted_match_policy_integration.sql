-- Fitted private match policy + fail-closed score regression tests.
do $$
declare
 cfg jsonb;
 version_no bigint;
 actual boolean;
begin
 select weights,version into cfg,version_no
 from app_private.fitted_match_policy where id=true;
 if cfg is null or version_no<1
    or not app_private.valid_fitted_match_weights(cfg)
 then raise exception 'Invalid Fitted match policy seed'; end if;
 if app_private.valid_fitted_match_weights(
   '{"intent":99,"lifestyle":20,"rhythm":20,"recovery":15,"autonomy":10,"sport":10}'::jsonb)
 then raise exception 'Weights exceeding 100 accepted'; end if;
 if app_private.valid_fitted_match_weights(
   '{"intent":25,"lifestyle":20,"rhythm":20,"recovery":15,"autonomy":10,"sport":10,"unsupported":0}'::jsonb)
 then raise exception 'Unknown factor accepted'; end if;
 if has_function_privilege('anon','public.fitted_match_score_v1(uuid)','execute')
 then raise exception 'Anonymous match score access granted'; end if;
 if not has_function_privilege(
   'authenticated','public.fitted_match_score_v1(uuid)','execute')
 then raise exception 'Authenticated match score unavailable'; end if;
 if (app_private.fitted_score_pair_v1(
   '11111111-1111-1111-1111-111111111111'::uuid,
   '22222222-2222-2222-2222-222222222222'::uuid)->>'available')::boolean
 then raise exception 'Ineligible pair received compatibility score'; end if;
end;
$$;
