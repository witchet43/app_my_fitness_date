-- Run after V6 integration tests. User 1 owns hidden post, User 3
-- reported it, User 4 originally hid it then lost moderator membership.
set role anon;
do $$
begin
 if has_function_privilege(current_user,'public.my_notifications(integer)','EXECUTE')
 or has_function_privilege(current_user,'public.submit_moderation_appeal(uuid,text)','EXECUTE')
 or has_function_privilege(current_user,'public.moderator_decide_appeal(uuid,text,text)','EXECUTE')
 or has_schema_privilege(current_user,'app_private','USAGE') then
   raise exception 'Appeal/notification endpoints exposed to anon';
 end if;
end $$;
reset role;

-- Only a privileged DB operator can appoint/revoke moderator membership.
insert into app_private.moderators(user_id)
 values('10000000-0000-4000-8000-000000000004'),
       ('10000000-0000-4000-8000-000000000002');

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
do $$
declare v_report uuid;
begin
 select report_id into v_report from public.moderator_list_reports('all',30)
 where target_type='post' limit 1;
 perform public.moderator_decide(v_report,'restore_post','Test restored content');
 perform public.moderator_decide(v_report,'hide_post','Test hide to enable appeal');
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
do $$
begin
 if exists(select 1 from public.my_notifications(30)) or
    exists(select 1 from public.my_appealable_posts()) then
  raise exception 'Reporter received owner-only moderation information';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare v_report uuid;v_count integer;
begin
 select count(*) into v_count from public.my_notifications(30);
 if v_count<2 then raise exception 'Owner must receive hide & restore notices: %',v_count; end if;
 if not exists(select 1 from public.my_notifications(30) where kind='post_hidden')
    or not exists(select 1 from public.my_notifications(30) where kind='post_restored') then
  raise exception 'Required notice kinds missing';
 end if;
 select report_id into v_report from public.my_appealable_posts() limit 1;
 if v_report is null then raise exception 'Own hidden post unavailable to appeal'; end if;
 if not public.submit_moderation_appeal(v_report,
   'La publicación no incumple las normas; solicito una segunda revisión.') then
   raise exception 'Owner appeal rejected';
 end if;
 begin
  perform public.submit_moderation_appeal(v_report,
   'Segunda solicitud de apelación no debe permitirse.');
  raise exception 'Duplicate appeal accepted' using errcode='P0002';
 exception
  when sqlstate 'P0001' then
   if sqlerrm<>'Appeal already submitted' then raise; end if;
 end;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
do $$
declare v_report uuid;
begin
 select id into v_report from app_private.safety_reports limit 1;
 exception when insufficient_privilege then
 -- Never reveal report table directly to a user.
 null;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
do $$
declare v_appeal uuid;
begin
 select appeal_id into v_appeal from public.moderator_list_appeals('pending',30) limit 1;
 if v_appeal is null then raise exception 'Pending appeal not visible to moderator'; end if;
 begin
  perform public.moderator_decide_appeal(v_appeal,'overturned',
     'The first moderator cannot review their own hiding decision');
  raise exception 'Original moderator decided appeal' using errcode='P0002';
 exception when insufficient_privilege then null;
 end;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare v_appeal uuid; v_count integer;
begin
 select appeal_id into v_appeal from public.moderator_list_appeals('pending',30) limit 1;
 if v_appeal is null then raise exception 'Pending appeal missing'; end if;
 if not public.moderator_decide_appeal(v_appeal,'overturned',
  'Independent reviewer agrees to restore this publication.') then
  raise exception 'Appeal could not be overturned';
 end if;
 select count(*) into v_count from public.moderator_list_appeals('overturned',30);
 if v_count<>1 then raise exception 'Resolved appeal not listed'; end if;
 begin
  perform public.moderator_decide_appeal(v_appeal,'upheld','Decision must be final');
  raise exception 'Second decision accepted' using errcode='P0002';
 exception when sqlstate 'P0001' then
  if sqlerrm<>'Appeal not pending' then raise; end if;
 end;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare v_notice uuid;v_count integer;
begin
 select count(*) into v_count from public.my_notifications(30);
 if v_count<3 then raise exception 'Appeal decision notice missing: %',v_count; end if;
 select id into v_notice from public.my_notifications(30)
 where kind='appeal_decided' limit 1;
 if v_notice is null then raise exception 'Decision notice absent'; end if;
 if not public.mark_notification_read(v_notice) then
  raise exception 'Cannot read own notification';
 end if;
 if not exists(select 1 from public.my_notifications(30)
  where id=v_notice and read_at is not null) then
  raise exception 'Read marker missing';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
do $$
declare v_notice uuid;
begin
 -- A known ID still cannot be marked by another account.
 select id into v_notice from public.my_notifications(30) limit 1;
 if v_notice is not null then raise exception 'Foreign inbox exposed'; end if;
 if public.mark_notification_read('e1111111-1111-4111-8111-111111111111') then
  raise exception 'Foreign read accepted';
 end if;
end $$;
reset role;

do $$
begin
 if (select count(*) from app_private.appeal_decision_audit)<>1
  or (select count(*) from app_private.moderation_appeals where status='overturned')<>1
  or (select count(*) from app_private.user_notifications)<3 then
  raise exception 'Private moderation workflow incomplete';
 end if;
 if exists(select 1 from app_private.hidden_posts) then
  raise exception 'Overturned single-report post must be restored';
 end if;
end $$;
delete from app_private.moderators
 where user_id in ('10000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000002');
