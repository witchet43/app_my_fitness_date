-- Run after V4 integration tests. Four synthetic auth.users and two social
-- profiles / one post / one future event are present.
set role anon;
do $$
begin
 if has_function_privilege(current_user,'public.submit_safety_report(text,uuid,text,text)','EXECUTE')
    or has_table_privilege(current_user,'app_private.safety_reports','SELECT') then
   raise exception 'Safety reports exposed to anonymous users';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare
  v_post uuid;
  v_event uuid;
begin
 select id into v_post from public.community_posts limit 1;
 select id into v_event from public.sport_events limit 1;
 if v_post is null or v_event is null then raise exception 'Social fixtures absent'; end if;
 if not public.submit_safety_report('post',v_post,'harassment','Prueba de denuncia')
    or not public.submit_safety_report('event',v_event,'unsafe',null)
    or not public.submit_safety_report('user','10000000-0000-4000-8000-000000000001'::uuid,'spam',null)
 then raise exception 'Report submission failed'; end if;
 -- Duplicate report is idempotent.
 perform public.submit_safety_report('post',v_post,'harassment','Prueba de denuncia');
end $$;
reset role;

do $$
begin
 if (select count(*) from app_private.safety_reports) <> 3 then
  raise exception 'Expected 3 private reports, got %',
   (select count(*) from app_private.safety_reports);
 end if;
end $$;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
select public.block_user('10000000-0000-4000-8000-000000000001'::uuid);
do $$
begin
 if exists(select 1 from public.community_posts
           where author_id='10000000-0000-4000-8000-000000000001'::uuid)
  or exists(select 1 from public.sport_events
           where organizer_id='10000000-0000-4000-8000-000000000001'::uuid)
  or exists(select 1 from public.social_profiles
           where user_id='10000000-0000-4000-8000-000000000001'::uuid)
 then raise exception 'Blocked user remains visible'; end if;
end $$;

-- Blocking is bidirectional for all social public surfaces.
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
begin
 if exists(select 1 from public.social_profiles
           where user_id='10000000-0000-4000-8000-000000000002'::uuid)
 then raise exception 'Bidirectional block did not apply'; end if;
end $$;
reset role;

-- Moderators can hide a post using privileged SQL only.
insert into app_private.hidden_posts(post_id,reason)
select id,'Pending admin review' from public.community_posts limit 1;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
begin
 if exists(select 1 from public.community_posts)
 then raise exception 'Moderated post remains visible'; end if;
 if has_table_privilege(current_user,'app_private.hidden_posts','SELECT')
   or has_table_privilege(current_user,'app_private.safety_reports','SELECT')
 then raise exception 'Private moderation tables exposed'; end if;
end $$;
reset role;

-- Quota: 30 discoveries per hour, then deny on 31st. No dating profiles
-- required for a request to be counted.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
do $$
declare i int;
begin
 for i in 1..30 loop
  perform * from public.discover_dating_candidates(1);
 end loop;
 begin
  perform * from public.discover_dating_candidates(1);
  raise exception 'Extra discovery unexpectedly succeeded' using errcode='P0002';
 exception
  when sqlstate 'P0001' then
    if sqlerrm <> 'RATE_LIMITED' then raise; end if;
 end;
end $$;

-- Limits are per account; another user can still make a discovery request.
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
do $$
begin
 perform * from public.discover_dating_candidates(1);
end $$;
reset role;
