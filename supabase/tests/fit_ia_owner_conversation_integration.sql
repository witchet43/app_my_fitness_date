-- Disposable integration test ONLY (wraps all auth/users/data in rollback).
-- Must not run as part of user-facing conversations.
begin;
insert into auth.users(id,email) values
 ('10000000-0000-4000-8000-000000000131','fit-ia-a@example.test'),
 ('10000000-0000-4000-8000-000000000132','fit-ia-b@example.test');

set role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000131',false);
do $test$
declare st jsonb; q_id text; a jsonb; other_count bigint; other_ai boolean;
begin
  st=public.fit_ia_next_v1('move','Bienvenido');
  q_id=st->'question'->>'id';
  if q_id is null or (st->'depth'->>'level')<>'weak'
     or st->>'ai_enabled'<>'false' then
    raise exception 'Initial private Fit-IA chat failed: %',st;
  end if;
  a=public.fit_ia_answer_v1('move',q_id,'opt_1');
  if a->>'status'<>'saved' or a->>'chosen_es' is null then
    raise exception 'Selected answer not durably saved';
  end if;
  st=public.fit_ia_next_v1('move','Gracias por compartirlo.');
  if st->'question'->>'id'=q_id then
    raise exception 'Answered question repeated';
  end if;
  if (st->'depth'->>'answered')::integer<>1 then
    raise exception 'Answer depth not incremented';
  end if;
  -- The account-level first-choice gate precedes legacy Fit-IA controls.
  perform public.fitted_set_ai_account_preference_v1(true,'onboarding');
  a=public.fit_ia_set_consent_v1(true);
  if a->>'ai_enabled'<>'true' then
    raise exception 'Explicit opt-in failed';
  end if;
  st=public.fit_ia_state_v1('move');
  if st->>'ai_enabled'<>'true' then
    raise exception 'Consent did not persist';
  end if;
end $test$;

reset role;
set role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000132',false);
do $test$
declare overview jsonb; own_count bigint;
begin
  select count(*) into own_count from public.fit_ia_answers_v1;
  if own_count<>0 then
    raise exception 'Foreign user read private answers';
  end if;
  if exists(select 1 from public.fit_ia_messages_v1) then
    raise exception 'Foreign user read private chat';
  end if;
  overview=public.fit_ia_overview_v1();
  if (overview->'move'->>'answered')::integer<>0 then
    raise exception 'Owner overview leaked another user';
  end if;
end $test$;

reset role;
set role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000131',false);
do $test$
begin
  if not public.fit_ia_delete_my_data_v1() then
    raise exception 'Owner deletion failed';
  end if;
  if exists(select 1 from public.fit_ia_answers_v1)
    or exists(select 1 from public.fit_ia_messages_v1)
    or exists(select 1 from public.fit_ia_summaries_v1) then
    raise exception 'Delete did not remove private data';
  end if;
end $test$;
reset role;
rollback;