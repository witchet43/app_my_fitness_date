-- Run ONLY in disposable CI PostgreSQL; this file simulates a fake auth.users
-- row removal to test stale JWT behavior. Never run this simulation in Supabase.
set role anon;
do $$
begin
 if has_function_privilege(current_user,
  'public.operator_erasure_claim(uuid,text)','EXECUTE') then
  raise exception 'Anon can start privileged erasure';
 end if;
end $$;
reset role;
set role authenticated;
do $$
begin
 if has_function_privilege(current_user,
  'public.operator_erasure_claim(uuid,text)','EXECUTE') then
  raise exception 'Regular user can start privileged erasure';
 end if;
end $$;
reset role;

insert into auth.users(id) values('10000000-0000-4000-8000-000000000006');
set role authenticated;
select set_config('request.jwt.claim.sub',
 '10000000-0000-4000-8000-000000000006',false);
select public.request_account_deletion();
reset role;

insert into app_private.erasure_approvals(user_id,ticket,reviewer_note)
values('10000000-0000-4000-8000-000000000006',
 'DEV-ERASURE-TICKET-006','Synthetic approval for locking and cascade tests.');
update app_private.account_deletion_requests
 set requested_at=now()-interval '8 days'
 where user_id='10000000-0000-4000-8000-000000000006';

set role service_role;
do $$
declare state jsonb;
begin
 select public.operator_erasure_claim(
 '10000000-0000-4000-8000-000000000006',
 'DEV-ERASURE-TICKET-006') into state;
 if state->>'eligible'<>'true' then
  raise exception 'Approved clean fake account failed claim: %',state;
 end if;
 select public.operator_erasure_claim(
 '10000000-0000-4000-8000-000000000006',
 'DEV-ERASURE-TICKET-006') into state;
 if state->>'eligible'<>'false' or
  not(state->'blockers' ? 'erasure_already_claimed') then
  raise exception 'Second claim was not blocked';
 end if;
end $$;
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub',
 '10000000-0000-4000-8000-000000000006',false);
do $$
begin
 begin
  perform public.cancel_account_deletion();
  raise exception 'User could cancel after erasure claim' using errcode='P0002';
 exception when sqlstate 'P0001' then
  if sqlerrm<>'ERASURE_IN_PROGRESS' then raise; end if;
 end;
end $$;
reset role;

-- Disposable auth shim only: simulate successful Auth Admin deletion.
delete from auth.users where id='10000000-0000-4000-8000-000000000006';

-- Simulate the same old signed JWT. It must not see community content.
set role authenticated;
select set_config('request.jwt.claim.sub',
 '10000000-0000-4000-8000-000000000006',false);
do $$
begin
 if exists(select 1 from public.community_posts) or
    exists(select 1 from public.social_profiles) or
    exists(select 1 from public.sport_events) then
  raise exception 'Deleted Auth account can still read social data';
 end if;
 if app_private.account_is_active(
  '10000000-0000-4000-8000-000000000006') then
  raise exception 'Deleted Auth identity still considered active';
 end if;
end $$;
reset role;
