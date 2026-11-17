-- Disposable integration test only. Use with test bootstrap/migrations; rollback.
begin;
insert into auth.users(id,email) values
  ('10000000-0000-4000-8000-000000000144','account-ai-a@example.test'),
  ('10000000-0000-4000-8000-000000000145','account-ai-b@example.test');
set role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000144',false);
do $test$
declare pref jsonb; result jsonb; forbidden boolean:=false;
begin
  pref:=public.fitted_ai_account_preference_v1();
  if pref->>'configured'<>'false' or pref->>'enabled'<>'false' then
    raise exception 'AI must be off and unset before first choice';
  end if;
  begin
    perform public.fit_ia_set_consent_v1(true);
  exception when sqlstate '42501' then forbidden:=true;
  end;
  if not forbidden then raise exception 'Legacy Fit-IA skipped first choice'; end if;
  result:=public.fitted_set_ai_account_preference_v1(true,'onboarding');
  if result->>'status'<>'saved' or result->>'enabled'<>'true' then
    raise exception 'First choice was not saved';
  end if;
  pref:=public.fitted_ai_account_preference_v1();
  if pref->>'configured'<>'true' or pref->>'enabled'<>'true' then
    raise exception 'First choice not retained';
  end if;
  result:=public.fitted_set_ai_account_preference_v1(false,'onboarding');
  if result->>'status'<>'already_configured'
    or result->>'enabled'<>'true' then
    raise exception 'Second first-login choice overwrote prior decision';
  end if;
  if not (select ai_enabled from public.fit_ia_settings_v1
     where user_id=auth.uid()) then raise exception 'Fit-IA not synchronized'; end if;
  result:=public.fitted_set_ai_account_preference_v1(false,'settings');
  if result->>'enabled'<>'false' then raise exception 'AI revocation not saved'; end if;
  if (select ai_enabled from public.fit_ia_settings_v1
     where user_id=auth.uid()) then raise exception 'Fit-IA still active'; end if;
  if not public.fit_ia_delete_my_data_v1() then
    raise exception 'Fit-IA deletion did not succeed'; end if;
  if (public.fitted_ai_account_preference_v1()->>'enabled')<>'false' then
    raise exception 'Deletion changed the account-wide preference';
  end if;
end $test$;
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000145',false);
do $test$
begin
  if (public.fitted_ai_account_preference_v1()->>'configured')<>'false'
    or exists(select 1 from public.fitted_ai_account_preferences_v1)
  then raise exception 'Foreign AI preference was exposed'; end if;
  if has_table_privilege('authenticated',
    'public.fitted_ai_account_preferences_v1','INSERT')
    or has_table_privilege('authenticated',
    'public.fitted_ai_account_preferences_v1','UPDATE')
  then raise exception 'Direct preference editing bypass is possible'; end if;
end $test$;
reset role;
rollback;
