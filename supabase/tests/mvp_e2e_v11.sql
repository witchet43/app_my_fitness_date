-- Iteration 11: end-to-end business workflow using 2 disposable auth identities.
-- CI runs this after V9b on a throwaway Postgres instance.
-- On Supabase DEV only run as BEGIN...ROLLBACK; never commit synthetic auth.users.
begin;

insert into auth.users (id,email) values
 ('10000000-0000-4000-8000-000000000007','qa-11-a@example.invalid'),
 ('10000000-0000-4000-8000-000000000008','qa-11-b@example.invalid');

set role anon;
do $$
begin
 if has_table_privilege(current_user,'public.community_posts','SELECT') or
    has_table_privilege(current_user,'public.sport_events','SELECT') or
    has_function_privilege(current_user,'public.discover_dating_candidates(integer)','EXECUTE') then
   raise exception 'E2E: anonymous user has authenticated API access';
 end if;
end $$;
reset role;

-- QA A: start as a social user, without activating dating.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000007',false);
insert into public.social_profiles (user_id,display_name,city,sports)
values ('10000000-0000-4000-8000-000000000007','QA Atleta A','Querétaro',array['Running']);
insert into public.community_posts(author_id,sport,body)
values ('10000000-0000-4000-8000-000000000007','Running',
 'Entrenamiento de desarrollo V11 sin datos reales.');
do $$
begin
 if exists(select 1 from public.discover_dating_candidates(10)) then
  raise exception 'E2E: social-only account appeared in dating';
 end if;
 if (public.my_account_status()->>'pending')<>'false' then
  raise exception 'E2E: new social account erroneously pending deletion';
 end if;
end $$;
reset role;

-- QA B: independent account can participate in community.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000008',false);
insert into public.social_profiles (user_id,display_name,city,sports)
values ('10000000-0000-4000-8000-000000000008','QA Atleta B','Querétaro',array['Pesas']);
do $$
begin
 if not exists(select 1 from public.community_posts
  where author_id='10000000-0000-4000-8000-000000000007') then
  raise exception 'E2E: authenticated feed cannot see existing content';
 end if;
 if (public.my_account_export()->'account'->>'id') <>
  '10000000-0000-4000-8000-000000000008' then
  raise exception 'E2E: switched identity exported account A';
 end if;
end $$;
reset role;

-- Only an operator grants event organizer role; QA A publishes one event.
insert into app_private.event_organizers(user_id)
values ('10000000-0000-4000-8000-000000000007');
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000007',false);
insert into public.sport_events(organizer_id,title,description,sport,city,starts_at)
values ('10000000-0000-4000-8000-000000000007',
 'QA V11 Running','Carrera de prueba sin participantes reales',
 'Running','Querétaro',now()+interval '4 days');
reset role;

-- QA B registers attendance. The organizer cannot view their RSVP.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000008',false);
insert into public.event_rsvps(event_id,user_id)
select e.id,'10000000-0000-4000-8000-000000000008'
from public.sport_events e where e.title='QA V11 Running';
do $$
begin
 if (select count(*) from public.event_rsvps
  where user_id='10000000-0000-4000-8000-000000000008')<>1 then
  raise exception 'E2E: participant cannot see their own RSVP';
 end if;
end $$;
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000007',false);
do $$
begin
 if exists(select 1 from public.event_rsvps
  where user_id='10000000-0000-4000-8000-000000000008') then
  raise exception 'E2E: organizer can see a different member RSVP';
 end if;
end $$;

-- Gym Shield: both opt into same-gym-other-time. A trains 07:00-08:30 Monday.
select public.save_dating_setup('QA Atleta A','Querétaro',array['Running'],
 date '1991-01-01','00000000-0000-4000-8000-000000000001',
 'same_gym_other_time',
 '[{"day":1,"startMinutes":420,"endMinutes":510}]'::jsonb,true);
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000008',false);
-- At 08:59 B is 29 minutes away, so same-gym matching must be excluded.
select public.save_dating_setup('QA Atleta B','Querétaro',array['Pesas'],
 date '1991-01-01','00000000-0000-4000-8000-000000000001',
 'same_gym_other_time',
 '[{"day":1,"startMinutes":539,"endMinutes":600}]'::jsonb,true);
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000007',false);
do $$
begin
 if exists(select 1 from public.discover_dating_candidates(10)
  where user_id='10000000-0000-4000-8000-000000000008') then
  raise exception 'E2E: Gym Shield allowed same-gym 29-minute gap';
 end if;
end $$;
reset role;

-- Exactly 30 minutes is permitted when BOTH opted in.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000008',false);
select public.save_dating_setup('QA Atleta B','Querétaro',array['Pesas'],
 date '1991-01-01','00000000-0000-4000-8000-000000000001',
 'same_gym_other_time',
 '[{"day":1,"startMinutes":540,"endMinutes":600}]'::jsonb,true);
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000007',false);
do $$
declare candidate jsonb;
begin
 select to_jsonb(c) into candidate
 from public.discover_dating_candidates(10) c
 where c.user_id='10000000-0000-4000-8000-000000000008';
 if candidate is null then raise exception 'E2E: 30-minute gap excluded'; end if;
 if candidate ?| array['gym_id','date_of_birth','weekly_slots','start_minute','end_minute','email','mode'] then
  raise exception 'E2E: Gym Shield leaked private schedule fields';
 end if;
end $$;
reset role;

-- QA B withdraws consent for same-gym matching, exclusion becomes immediate.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000008',false);
select public.save_dating_setup('QA Atleta B','Querétaro',array['Pesas'],
 date '1991-01-01','00000000-0000-4000-8000-000000000001',
 'other_gyms','[]'::jsonb,true);
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000007',false);
do $$
begin
 if exists(select 1 from public.discover_dating_candidates(10)
  where user_id='10000000-0000-4000-8000-000000000008') then
  raise exception 'E2E: reciprocal consent withdrawal ignored';
 end if;
end $$;
reset role;

-- Different gyms can appear despite overlapping schedules.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000008',false);
select public.save_dating_setup('QA Atleta B','Querétaro',array['Pesas'],
 date '1991-01-01','00000000-0000-4000-8000-000000000002',
 'other_gyms',
 '[{"day":1,"startMinutes":420,"endMinutes":510}]'::jsonb,true);
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000007',false);
do $$
begin
 if not exists(select 1 from public.discover_dating_candidates(10)
  where user_id='10000000-0000-4000-8000-000000000008') then
  raise exception 'E2E: different gym unexpectedly excluded';
 end if;
end $$;

-- User B requests account deletion: their dating visibility, social access
-- and any new participation are forbidden immediately.
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000008',false);
select public.request_account_deletion();
do $$
begin
 if (public.my_account_status()->>'pending') <> 'true' then
  raise exception 'E2E: deletion status not persisted';
 end if;
 begin
  insert into public.community_posts(author_id,sport,body)
  values ('10000000-0000-4000-8000-000000000008',
    'Running','This should be rejected while deletion pending.');
  raise exception 'E2E: pending account can still publish' using errcode='P0002';
 exception when insufficient_privilege then null;
 end;
end $$;
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000007',false);
do $$
begin
 if exists(select 1 from public.social_profiles
  where user_id='10000000-0000-4000-8000-000000000008') then
  raise exception 'E2E: pending account social profile visible';
 end if;
 if exists(select 1 from public.discover_dating_candidates(10)
  where user_id='10000000-0000-4000-8000-000000000008') then
  raise exception 'E2E: pending account still eligible for dating';
 end if;
end $$;
reset role;

-- Roll back ALL synthetic identities, events, posts, holds and counters.
rollback;
