-- Private Gym Shield v28 regression checks.
do $$
declare r jsonb;
begin
  if has_table_privilege('anon',
      'app_private.fitted_shield_preferences_v28','SELECT')
    or has_table_privilege('authenticated',
      'app_private.fitted_training_windows_v28','SELECT')
    or has_table_privilege('anon',
      'app_private.fitted_training_windows_v28','INSERT')
  then raise exception 'Private training locations exposed'; end if;
  if has_function_privilege('anon',
      'public.fitted_shield_save_v28(text,jsonb)','EXECUTE')
    or has_function_privilege('anon',
      'public.fitted_shield_get_v28()','EXECUTE')
  then raise exception 'Anonymous Gym Shield RPC access'; end if;
  if not has_function_privilege('authenticated',
      'public.fitted_shield_save_v28(text,jsonb)','EXECUTE')
  then raise exception 'Member Shield configuration inaccessible'; end if;
  r:=public.fitted_shield_get_v28();
  if r->>'status' <> 'not_available' then
    raise exception 'Unauthenticated get was accepted'; end if;
  r:=public.fitted_shield_save_v28('include_same_time','[]'::jsonb);
  if r->>'status' <> 'not_available' then
    raise exception 'Unauthenticated C-mode save was accepted'; end if;
end;
$$;
