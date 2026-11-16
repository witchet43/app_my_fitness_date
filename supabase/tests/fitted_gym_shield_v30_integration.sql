-- Only eligibility-denying logic is added; missing verified information
-- and unapproved same-gym C preferences always fail closed.
do $$
begin
  if has_function_privilege('anon',
      'app_private.fitted_shield_pair_allowed_v30(uuid,uuid)',
      'execute')
     or has_function_privilege('authenticated',
      'app_private.fitted_shield_pair_allowed_v30(uuid,uuid)',
      'execute')
  then raise exception 'Private Gym Shield gate is directly callable'; end if;
  if app_private.fitted_shield_pair_allowed_v30(null,null) then
    raise exception 'Missing users were accepted'; end if;
  if app_private.fitted_shield_pair_allowed_v30(
    '11111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid)
  then raise exception 'Unknown verified venue allowed a pair'; end if;
  if app_private.b11_pair_allowed(
    '11111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid)
  then raise exception 'Ineligible pair was allowed'; end if;
end; $$;
