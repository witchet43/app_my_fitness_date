-- End-to-end V17 incident tests, all transient.
begin;
insert into auth.users(id) values
('10000000-0000-4000-8000-000000000011'),
('10000000-0000-4000-8000-000000000012'),
('10000000-0000-4000-8000-000000000013'),
('10000000-0000-4000-8000-000000000014');

insert into app_private.safety_reports
 (id,reporter_id,target_type,target_id,subject_user_id,reason,status,created_at)
values
 ('17000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000012','user',
  '10000000-0000-4000-8000-000000000011',
  '10000000-0000-4000-8000-000000000011','unsafe','pending',now()-interval '2 hours'),
 ('17000000-0000-4000-8000-000000000002',
  '10000000-0000-4000-8000-000000000012','user',
  '10000000-0000-4000-8000-000000000013',
  '10000000-0000-4000-8000-000000000013','spam','pending',now());
insert into app_private.moderators(user_id) values
 ('10000000-0000-4000-8000-000000000013'),
 ('10000000-0000-4000-8000-000000000014');

set role anon;
do $$
begin
 if has_function_privilege(current_user,'public.moderator_incident_queue(integer)','EXECUTE')
 or has_function_privilege(current_user,'public.moderator_escalate_report(uuid,text,text)','EXECUTE')
 or has_function_privilege(current_user,'public.moderator_review_escalation(uuid,text)','EXECUTE') then
  raise exception 'Anonymous can call incident APIs';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000012',false);
do $$
begin
 if has_table_privilege(current_user,'app_private.incident_audit','SELECT')
 or has_table_privilege(current_user,'app_private.incident_escalations','INSERT') then
  raise exception 'Incident tables exposed to ordinary users';
 end if;
 begin
  perform * from public.moderator_incident_queue(30);
  raise exception 'Reporter read moderation queue' using errcode='P0002';
 exception when insufficient_privilege then null;
 end;
 begin
  perform public.moderator_escalate_report(gen_random_uuid(),'urgent','Unauthorized request');
  raise exception 'Reporter escalated' using errcode='P0002';
 exception when insufficient_privilege then null;
 end;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000013',false);
do $$
declare v_unsafe uuid;v_spam uuid;
begin
 select id into v_unsafe from app_private.safety_reports where false;
exception when insufficient_privilege then null;
end $$;
do $$
declare
 v_unsafe uuid;v_spam uuid;
begin
 select q.report_id into v_unsafe from public.moderator_incident_queue(30) q
 where q.report_id='17000000-0000-4000-8000-000000000001'
 limit 1;
 select q.report_id into v_spam from public.moderator_incident_queue(30) q
 where q.report_id='17000000-0000-4000-8000-000000000002'
 limit 1;
 if v_unsafe is null or v_spam is null then raise exception 'Incident queue incomplete'; end if;
 if not exists(select 1 from public.moderator_incident_queue(30) q
     where q.report_id=v_unsafe and q.priority='urgent' and q.overdue) then
  raise exception 'Unsafe overdue report not prioritized';
 end if;
 if not exists(select 1 from public.moderator_incident_queue(30) q
     where q.report_id=v_spam and q.priority='normal' and not q.overdue) then
  raise exception 'Fresh spam case incorrectly urgent';
 end if;
 begin
  perform public.moderator_decide(v_spam,'dismiss','Conflict of interest review');
  raise exception 'Subject moderator dismissed own case' using errcode='P0002';
 exception when insufficient_privilege then null;
 end;
 if not public.moderator_escalate_report(v_unsafe,'urgent',
    'Urgent safety incident for independent review') then
  raise exception 'Escalation not created';
 end if;
 if not exists(select 1 from public.moderator_incident_queue(30) q
     where q.report_id=v_unsafe and q.escalation_status='open') then
  raise exception 'Open escalation absent from priority queue';
 end if;
 begin
  perform public.moderator_escalate_report(v_unsafe,'urgent','Repeat escalation attempt');
  raise exception 'Duplicate escalation was accepted' using errcode='P0002';
 exception when sqlstate 'P0001' then
  if sqlerrm<>'Incident already escalated' then raise; end if;
 end;
 begin
  perform public.moderator_decide(v_unsafe,'dismiss','Premature final decision');
  raise exception 'Pending escalation closed without review' using errcode='P0002';
 exception when sqlstate 'P0001' then
  if sqlerrm<>'INDEPENDENT_REVIEW_REQUIRED' then raise; end if;
 end;
 begin
  perform public.moderator_review_escalation(v_unsafe,'Self-review disallowed');
  raise exception 'Escalator approved own review' using errcode='P0002';
 exception when insufficient_privilege then null;
 end;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000014',false);
do $$
declare v_unsafe uuid;
begin
 select report_id into v_unsafe from public.moderator_incident_queue(30)
 where reason='unsafe' and escalation_status='open' limit 1;
 if v_unsafe is null then raise exception 'Independent moderator did not see incident'; end if;
 if not public.moderator_review_escalation(v_unsafe,
  'Second moderator reviewed evidence and approved next step') then
  raise exception 'Independent review did not close escalation';
 end if;
 begin
   perform public.moderator_review_escalation(v_unsafe,'Second redundant closure');
   raise exception 'Duplicate independent review accepted' using errcode='P0002';
 exception when sqlstate 'P0001' then
   if sqlerrm<>'No pending escalation' then raise; end if;
 end;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000013',false);
do $$
declare v_unsafe uuid;
begin
 select q.report_id into v_unsafe from public.moderator_incident_queue(30) q
 where q.reason='unsafe' and q.escalation_status='closed' limit 1;
 if v_unsafe is null then raise exception 'Independent review missing'; end if;
 if not public.moderator_decide(v_unsafe,'resolve','Evidence reviewed by second moderator') then
  raise exception 'After review decision rejected';
 end if;
end $$;
reset role;

do $$
begin
 if (select count(*) from app_private.incident_audit
  where report_id in (select id from app_private.safety_reports
   where reporter_id='10000000-0000-4000-8000-000000000012'))<>2 then
  raise exception 'Incident audit should have escalation and independent review';
 end if;
 if not exists(select 1 from app_private.incident_escalations
  where escalated_by<>closed_by and status='closed' and closed_at is not null) then
  raise exception 'Independent reviewer was not persisted';
 end if;
end $$;

-- Operator preflight must account for an incident reviewer even if they were
-- never a subject/reporter of a safety report.
insert into auth.users(id) values('10000000-0000-4000-8000-000000000015');
insert into app_private.account_deletion_requests(user_id,requested_at)
values('10000000-0000-4000-8000-000000000015',now()-interval '8 days');
insert into app_private.erasure_approvals(user_id,ticket,reviewer_note)
values('10000000-0000-4000-8000-000000000015',
 'QA17-ERASURE-REVIEWER-15','Synthetic incident reviewer evidence retention test.');
insert into app_private.incident_audit(report_id,actor_id,action,priority,note)
values('17000000-0000-4000-8000-000000000001',
 '10000000-0000-4000-8000-000000000015',
 'reviewed','urgent','Independent synthetic review evidence.');
set role service_role;
do $$
declare v jsonb;
begin
 select public.operator_erasure_preflight(
  '10000000-0000-4000-8000-000000000015',
  'QA17-ERASURE-REVIEWER-15') into v;
 if v->>'eligible' <> 'false'
   or not(v->'blockers' ? 'incident_retention_review_required') then
  raise exception 'Erasure preflight ignored reviewer evidence: %',v;
 end if;
end $$;
reset role;

rollback;
