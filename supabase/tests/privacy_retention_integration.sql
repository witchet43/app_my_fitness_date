-- Iteration 18: simulated operator retention. No real users or permanent data.
begin;

insert into auth.users(id,email) values
 ('10000000-0000-4000-8000-000000000018','qa-privacy-a@example.invalid'),
 ('10000000-0000-4000-8000-000000000019','qa-privacy-b@example.invalid'),
 ('10000000-0000-4000-8000-000000000020','qa-privacy-c@example.invalid');

insert into app_private.dating_request_counters
(user_id,action,bucket_start,attempts) values
('10000000-0000-4000-8000-000000000018','discover',now()-interval '40 days',1),
('10000000-0000-4000-8000-000000000020','settings',now()-interval '31 days',1),
('10000000-0000-4000-8000-000000000020','discover',now()-interval '40 days',1),
('10000000-0000-4000-8000-000000000020','discover',now(),1);

insert into app_private.safety_reports
(reporter_id,target_type,target_id,subject_user_id,reason,details)
values('10000000-0000-4000-8000-000000000018','user',
       '10000000-0000-4000-8000-000000000019',
       '10000000-0000-4000-8000-000000000019',
       'other','Synthetic evidence that must be retained');

insert into app_private.adult_eligibility
(user_id,expires_at,review_ref)
values('10000000-0000-4000-8000-000000000018',
 now()+interval '10 days','QA18-PRIVATE-REVIEW-ID');

set role anon;
do $$
begin
 if has_function_privilege(current_user,'public.operator_privacy_inventory()','EXECUTE')
  or has_function_privilege(current_user,
    'public.operator_prune_ephemeral_counters(text,text,integer)','EXECUTE') then
  raise exception 'Anon can inspect private retention counts';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub',
 '10000000-0000-4000-8000-000000000018',false);
do $$
declare v jsonb;
begin
 if has_function_privilege(current_user,'public.operator_privacy_inventory()','EXECUTE')
  or has_function_privilege(current_user,
   'public.operator_prune_ephemeral_counters(text,text,integer)','EXECUTE') then
  raise exception 'Normal user has privileged retention access';
 end if;
 if has_table_privilege(current_user,'app_private.privacy_prune_audit','SELECT') then
  raise exception 'Retention audit table exposed';
 end if;
 v:=public.my_account_export();
 if v->'account'->>'id'<>'10000000-0000-4000-8000-000000000018' then
  raise exception 'Export contained another account';
 end if;
 if v->'age_review'->>'approved'<>'true' then
  raise exception 'Own age review status was not included';
 end if;
 if v->'age_review' ? 'review_ref'
    or v::text like '%QA18-PRIVATE-REVIEW-ID%' then
   raise exception 'Sensitive review reference leaked in export';
 end if;
 if v->'retention_information'->>'moderation_evidence'<>'manual_review_required' then
   raise exception 'Retention caveat absent from export';
 end if;
end $$;
reset role;

set role service_role;
do $$
declare v jsonb;
begin
 v:=public.operator_privacy_inventory();
 if (v->>'eligible_dating_counters')::integer<2 or
    (v->>'held_dating_counters')::integer<1 or
    (v->>'retained_safety_reports')::integer<1 or
    v->>'dry_run'<>'true' then
  raise exception 'Retention inventory incomplete: %',v;
 end if;
 begin
  perform public.operator_prune_ephemeral_counters(
   'QA18-REVIEWED-TICKET','INCORRECT',500);
  raise exception 'Counter deletion bypassed explicit confirmation' using errcode='P0002';
 exception when sqlstate 'P0001' then
  if sqlerrm<>'Invalid retention authorization' then raise; end if;
 end;
 begin
  perform public.operator_prune_ephemeral_counters(
   'QA18-REVIEWED-TICKET','PRUNE_EXPIRED_DATING_COUNTERS',501);
  raise exception 'Excessive purge limit accepted' using errcode='P0002';
 exception when sqlstate 'P0001' then
  if sqlerrm<>'Invalid retention authorization' then raise; end if;
 end;

 v:=public.operator_prune_ephemeral_counters(
   'QA18-REVIEWED-TICKET','PRUNE_EXPIRED_DATING_COUNTERS',1);
 if (v->>'deleted_dating_counters')::integer<>1 or v->>'evidence_deleted'<>'false' then
   raise exception 'Bounded prune failed: %',v;
 end if;
 v:=public.operator_prune_ephemeral_counters(
   'QA18-REVIEWED-TICKET','PRUNE_EXPIRED_DATING_COUNTERS',500);
 if (v->>'deleted_dating_counters')::integer<>1 then
   raise exception 'Second batch did not clean exactly one stale record: %',v;
 end if;
 v:=public.operator_prune_ephemeral_counters(
   'QA18-REVIEWED-TICKET','PRUNE_EXPIRED_DATING_COUNTERS',500);
 if (v->>'deleted_dating_counters')::integer<>0 then
   raise exception 'Repeat prune should be idempotent: %',v;
 end if;
 if (select count(*) from app_private.dating_request_counters
  where user_id='10000000-0000-4000-8000-000000000018')<>1 then
   raise exception 'Evidence-linked counter was purged';
 end if;
 if (select count(*) from app_private.dating_request_counters
  where user_id='10000000-0000-4000-8000-000000000020')<>1 then
   raise exception 'Recent clean counter was accidentally removed';
 end if;
 if not exists(select 1 from app_private.safety_reports
  where reporter_id='10000000-0000-4000-8000-000000000018') then
   raise exception 'Safety evidence deleted by retention cleanup';
 end if;
 if (select count(*) from app_private.privacy_prune_audit
  where ticket='QA18-REVIEWED-TICKET')<>3 then
   raise exception 'Privileged prune log incomplete';
 end if;
end $$;
reset role;
rollback;
