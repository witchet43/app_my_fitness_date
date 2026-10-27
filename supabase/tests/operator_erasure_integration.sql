-- Test accounts from earlier suites exist. No Auth user is deleted in this test.
set role anon;
do $$
begin
 if has_function_privilege(current_user,
  'public.operator_erasure_preflight(uuid,text)','EXECUTE') then
  raise exception 'Anonymous user can inspect account erasure';
 end if;
end $$;
reset role;
set role authenticated;
do $$
begin
 if has_function_privilege(current_user,
  'public.operator_erasure_preflight(uuid,text)','EXECUTE') then
  raise exception 'Authenticated user can inspect account erasure';
 end if;
end $$;
reset role;

-- Pending user 1 needs a waiting period and explicit operator approval.
set role authenticated;
select set_config('request.jwt.claim.sub',
 '10000000-0000-4000-8000-000000000001',false);
select public.request_account_deletion();
reset role;

set role service_role;
do $$
declare result jsonb;
begin
 select public.operator_erasure_preflight(
  '10000000-0000-4000-8000-000000000001',
  'DEV-ERASURE-TICKET-001') into result;
 if result->>'eligible'<>'false' then
   raise exception 'Missing approval and cooling period was incorrectly accepted';
 end if;
 if not (result->'blockers' ? 'missing_operator_approval') then
   raise exception 'Approval requirement missing';
 end if;
end $$;
reset role;

-- Privileged admin supplies ticket, never the mobile application.
insert into app_private.erasure_approvals(user_id,ticket,reviewer_note)
values('10000000-0000-4000-8000-000000000001',
 'DEV-ERASURE-TICKET-001','Synthetic QA approval; not a real account.');
update app_private.account_deletion_requests
 set requested_at=now()-interval '8 days'
 where user_id='10000000-0000-4000-8000-000000000001';

-- User 1 participated in earlier moderation cases: a privileged erasure
-- should stay BLOCKED despite seven days and an approval ticket.
set role service_role;
do $$
declare result jsonb;
begin
 select public.operator_erasure_preflight(
 '10000000-0000-4000-8000-000000000001',
 'DEV-ERASURE-TICKET-001') into result;
 if result->>'eligible'<>'false' or
   not (result->'blockers' ? 'moderation_retention_review_required') then
  raise exception 'Moderation evidence was not protected';
 end if;
end $$;
reset role;

-- Account 4 has no posts nor direct moderation cases after v7 cleanup,
-- but was once a moderator: moderation_audit.actor_id still references it.
set role authenticated;
select set_config('request.jwt.claim.sub',
 '10000000-0000-4000-8000-000000000004',false);
select public.request_account_deletion();
reset role;
insert into app_private.erasure_approvals(user_id,ticket,reviewer_note)
values('10000000-0000-4000-8000-000000000004',
 'DEV-ERASURE-TICKET-004','Separate operator review of the test account.');
update app_private.account_deletion_requests
 set requested_at=now()-interval '8 days'
 where user_id='10000000-0000-4000-8000-000000000004';
set role service_role;
do $$
declare result jsonb;
begin
 select public.operator_erasure_preflight(
 '10000000-0000-4000-8000-000000000004',
 'DEV-ERASURE-TICKET-004') into result;
 if result->>'eligible'<>'false' or
    not(result->'blockers' ? 'moderation_retention_review_required') then
  raise exception 'Moderator audit references not detected';
 end if;
end $$;
reset role;
