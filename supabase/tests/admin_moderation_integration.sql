-- Requires social + safety tests and V6 migration.
-- Synthetic accounts 100...001–100...004 exist from existing test setup.

set role anon;
do $$
begin
 if has_function_privilege(current_user,'public.is_moderator()','EXECUTE')
    or has_function_privilege(current_user,'public.moderator_decide(uuid,text,text)','EXECUTE')
    or has_schema_privilege(current_user,'app_private','USAGE') then
   raise exception 'Anonymous user can access moderation surface';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
do $$
begin
 if public.is_moderator() then raise exception 'User 3 is unexpectedly a moderator'; end if;
 begin
   perform * from public.moderator_list_reports('all',30);
   raise exception 'Non-moderator read reports' using errcode='P0002';
 exception
   when insufficient_privilege then null;
 end;
 begin
   perform public.moderator_decide(gen_random_uuid(),'dismiss','Not authorized');
   raise exception 'Non-moderator made a decision' using errcode='P0002';
 exception
   when insufficient_privilege then null;
 end;
 if has_table_privilege(current_user,'app_private.moderators','INSERT')
    or has_table_privilege(current_user,'app_private.moderation_audit','UPDATE') then
   raise exception 'Direct moderation grants leaked';
 end if;
end $$;
reset role;

-- A privileged administrator appoints user 4, not via an API callable by user 4.
insert into app_private.moderators(user_id)
values('10000000-0000-4000-8000-000000000004');

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
do $$
declare
 v_report uuid; v_post uuid; v_count integer;
begin
 if not public.is_moderator() then raise exception 'Moderator missing membership'; end if;
 select count(*) into v_count from public.moderator_list_reports('all',30);
 if v_count <> 3 then raise exception 'Expected three reports, got %',v_count; end if;
 select report_id,target_id into v_report,v_post
 from public.moderator_list_reports('pending',30)
 where target_type='post' limit 1;
 if v_report is null or v_post is null then
   raise exception 'Expected pending post report';
 end if;

 -- User 1's post was hidden by the v5 test. Restore, then hide again.
 if not public.moderator_decide(v_report,'restore_post','Restore for review') then
   raise exception 'Restore did not succeed';
 end if;
 if not public.moderator_decide(v_report,'hide_post','Inappropriate content') then
   raise exception 'Hide did not succeed';
 end if;
 if not public.moderator_decide(v_report,'review','Need second review') then
   raise exception 'Review did not succeed';
 end if;
 if not public.moderator_decide(v_report,'dismiss','No policy breach') then
   raise exception 'Dismiss did not succeed';
 end if;
 select count(*) into v_count from public.moderator_recent_actions(20);
 if v_count <> 4 then raise exception 'Expected four audited actions, got %',v_count; end if;
 if exists(select 1 from public.moderator_list_reports('pending',30)
           where report_id=v_report) then
   raise exception 'Dismissed report still pending';
 end if;
 begin
   perform public.moderator_decide(v_report,'hide_post','ab');
   raise exception 'Short note accepted' using errcode='P0002';
 exception
   when raise_exception then
      if sqlerrm = 'Short note accepted' then raise; end if;
 end;
end $$;
reset role;

-- Inspect privileged audit / hide state after SECURITY DEFINER actions.
do $$
declare v_report uuid;
begin
 select id into v_report from app_private.safety_reports
 where target_type='post' limit 1;
 if (select count(*) from app_private.moderation_audit
     where report_id=v_report) <> 4 then
   raise exception 'Audit log incomplete';
 end if;
 if not exists(select 1 from app_private.hidden_posts h
   join app_private.safety_reports r on r.target_id=h.post_id
   where r.id=v_report) then
   raise exception 'Hide state not retained';
 end if;
end $$;

-- Once membership is revoked, old login no longer permits actions.
delete from app_private.moderators
where user_id='10000000-0000-4000-8000-000000000004';
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
do $$
begin
 if public.is_moderator() then raise exception 'Revoked membership still active'; end if;
 begin
   perform * from public.moderator_recent_actions(20);
   raise exception 'Revoked moderator read audit' using errcode='P0002';
 exception
   when insufficient_privilege then null;
 end;
end $$;
reset role;
