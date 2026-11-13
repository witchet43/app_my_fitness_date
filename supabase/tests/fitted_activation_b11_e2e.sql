-- CRITICAL: EPHEMERAL POSTGRES CI ONLY. Never apply to a hosted database!
-- The flags below are artificial transactional fixtures, NOT external
-- verification or staffed moderation evidence. Everything is rolled back.
begin;
insert into auth.users(id,email,email_confirmed_at) values
 ('00000000-0000-4000-8000-0000000011ad','b11-operator@example.invalid',now()),
 ('00000000-0000-4000-8000-0000000011a1','b11-a@example.invalid',now()),
 ('00000000-0000-4000-8000-0000000011b2','b11-b@example.invalid',now()),
 ('00000000-0000-4000-8000-0000000011c3','b11-c@example.invalid',now());

insert into app_private.brand_administrators(user_id,role)
values('00000000-0000-4000-8000-0000000011ad','owner');

-- No user can forge administrative gym entries at AAL1, even an appointed owner.
set role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-0000000011ad',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $assert$
begin
 begin
   perform public.admin_b11_register_gym('Training Campus','Test City');
   raise exception 'AAL1 administrator could create a gym';
 exception when insufficient_privilege then null;
 end;
end;
$assert$;
select set_config('request.jwt.claims','{"aal":"aal2"}',false);
select public.admin_b11_register_gym('QA Local Gym East','Querétaro');
select public.admin_b11_register_gym('QA Local Gym West','Querétaro');
reset role;

-- The two adult members are real local JWT test identities, never hosted users.
insert into public.member_profiles_v26(
  user_id,display_name,city,date_of_birth,onboarding_complete)
values
 ('00000000-0000-4000-8000-0000000011a1',
  'QA Fit A','Querétaro',date '1991-04-10',true),
 ('00000000-0000-4000-8000-0000000011b2',
  'QA Fit B','Querétaro',date '1992-08-20',true);
insert into public.member_consents_v26(
 user_id,consent_kind,document_version,source)
values
 ('00000000-0000-4000-8000-0000000011a1','dating','dating-v1','profile_settings'),
 ('00000000-0000-4000-8000-0000000011b2','dating','dating-v1','profile_settings');
insert into app_private.community_pilot_b4(user_id,admitted_by) values
 ('00000000-0000-4000-8000-0000000011a1','00000000-0000-4000-8000-0000000011ad'),
 ('00000000-0000-4000-8000-0000000011b2','00000000-0000-4000-8000-0000000011ad');
insert into app_private.adult_eligibility(
 user_id,approved_at,expires_at,review_ref) values
 ('00000000-0000-4000-8000-0000000011a1',now(),now()+interval '30 days','LOCAL-AGE-ATTEST-A'),
 ('00000000-0000-4000-8000-0000000011b2',now(),now()+interval '30 days','LOCAL-AGE-ATTEST-B');
insert into app_private.fitdating_preferences_b5(
 user_id,relationship_intent,sports,lifestyle_frequency,
 gym_privacy_mode,participation_requested)
values
 ('00000000-0000-4000-8000-0000000011a1','serious',
  array['running'],'weekly','other_gyms',true),
 ('00000000-0000-4000-8000-0000000011b2','serious',
  array['yoga'],'weekly','other_gyms',true);
insert into public.member_rhythm_b11(user_id,answers) values
 ('00000000-0000-4000-8000-0000000011a1',
 '{"sport":"running","frequency":"two_three","sleep":"early_bird","weekday":"home","intent":"long_term","together":"balanced"}'),
 ('00000000-0000-4000-8000-0000000011b2',
 '{"sport":"yoga","frequency":"two_three","sleep":"early_bird","weekday":"home","intent":"long_term","together":"balanced"}');

-- Mandatory production gates are FALSE; even previously verified adults cannot
-- become discoverable on self-request.
set role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-0000000011a1',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $assert$
begin
 if (public.fitdating_status_b5()->>'enabled')::boolean then
   raise exception 'B5 claimed discovery enabled before release';
 end if;
 if public.fitdating_activate_b11(
   (select g.id from public.gyms g where g.name='QA Local Gym East'),'[]'::jsonb)
   <> 'not_eligible' then
   raise exception 'User activated romantic discovery before external gates';
 end if;
 if (select count(*) from public.member_rhythm_b11 r
   where r.user_id='00000000-0000-4000-8000-0000000011b2')<>0 then
   raise exception 'BOLA: A read the private rhythm of B';
 end if;
end;
$assert$;
reset role;

-- ONLY IN THIS ROLLBACK-ONLY FIXTURE: simulate external approvals for
-- validating the AUTHORIZED state transitions. This is not production signoff.
update app_private.fitdating_gate_b5 set
 independently_verified_provider_live=true,
 independent_verification_audit_approved=true,
 moderation_staffed=true,
 privacy_review_approved=true,
 release_approved=true
where id=true;

set role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-0000000011a1',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $assert$
begin
 if (public.fitdating_status_b5()->>'enabled')::boolean then
   raise exception 'Global approval alone activated private gym profile';
 end if;
 if (public.fitdating_status_b5()->>'gym_setup_required')::boolean is distinct from true then
   raise exception 'Expected explicit private Gym Shield setup';
 end if;
 if public.fitdating_activate_b11(
    '00000000-0000-4000-8000-000000000001','[]'::jsonb)
    <> 'gym_unavailable' then
   raise exception 'Demo gym was accepted for real dating';
 end if;
 if public.fitdating_activate_b11(
   (select g.id from public.gyms g where g.name='QA Local Gym East'),
   '[]'::jsonb) <> 'activated' then
   raise exception 'Safe mode A activation failed after required approvals';
 end if;
 if (public.fitdating_status_b5()->>'enabled')::boolean is distinct from true then
   raise exception 'Actual activated user is not reported as enabled';
 end if;
end;
$assert$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-0000000011b2',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $assert$
begin
 if public.fitdating_activate_b11(
   (select g.id from public.gyms g where g.name='QA Local Gym West'),
   '[]'::jsonb) <> 'activated' then
   raise exception 'B activation failed';
 end if;
end;
$assert$;
reset role;

-- A and B share a life rhythm, but NOT a sport: that must NOT prevent matching.
set role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-0000000011a1',false);
do $assert$
begin
 if not exists(select 1 from public.fitdating_candidates_b11(10) c
   where c.user_id='00000000-0000-4000-8000-0000000011b2'
     and c.reason_codes ? 'sport_different_ok') then
   raise exception 'Different-sport compatible adult was not discoverable';
 end if;
 if public.fitdating_like_b11(
  '00000000-0000-4000-8000-0000000011b2')<>'liked' then
   raise exception 'First mutual-match step did not record like';
 end if;
end;
$assert$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-0000000011b2',false);
do $assert$
begin
 if public.fitdating_like_b11(
  '00000000-0000-4000-8000-0000000011a1')<>'matched' then
   raise exception 'Reciprocal like did not create match';
 end if;
end;
$assert$;
reset role;

-- Only the ephemeral PostgreSQL operator may inspect internal match IDs.
-- An outsider learns the UUID here solely as an adversarial BOLA fixture.
select set_config('qa.b11.match_id',
  (select m.id::text from app_private.fitdating_matches_b11 m limit 1),
  false);

-- C must never read or send messages despite possessing a signed-in JWT.
set role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-0000000011c3',false);
do $assert$
declare mid uuid;
begin
 mid:=current_setting('qa.b11.match_id')::uuid;
 if exists(select 1 from public.fitdating_my_messages_b11(mid)) then
   raise exception 'BOLA: C read someone else''s chat';
 end if;
 if public.fitdating_send_b11(mid,'Forbidden')<>'not_available' then
   raise exception 'BOLA: C sent to someone else''s match';
 end if;
end;
$assert$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-0000000011a1',false);
do $assert$
declare mid uuid;
begin
 mid:=current_setting('qa.b11.match_id')::uuid;
 if public.fitdating_send_b11(mid,'Hello from A')<>'sent' then
   raise exception 'First real private chat message failed';
 end if;
 if not exists(select 1 from public.fitdating_my_messages_b11(mid)
   where body='Hello from A') then
   raise exception 'Mutual chat not visible to participant';
 end if;
 if public.fitdating_report_b11(mid,'unsafe','Unsafe behavior')<>'reported_and_blocked' then
   raise exception 'Safety report did not block the other user';
 end if;
 if exists(select 1 from public.fitdating_my_messages_b11(mid)) then
   raise exception 'Chat remained accessible after safety block';
 end if;
end;
$assert$;
reset role;

-- Consent revocation must immediately remove the private rhythm and
-- deny the member any future discovery/messaging.
set role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-0000000011b2',false);
do $assert$
begin
 if public.fitdating_disable_b5()<>'disabled' then
   raise exception 'B5 consent revocation failed';
 end if;
 if (public.fitdating_status_b5()->>'enabled')::boolean then
   raise exception 'Revoked account was still visible';
 end if;
end;
$assert$;
reset role;

do $assert$
begin
 if exists(select 1 from public.member_rhythm_b11
   where user_id='00000000-0000-4000-8000-0000000011b2') then
   raise exception 'Consent withdrawal retained private rhythm';
 end if;
 if not exists(select 1 from public.community_reports_b4
   where reporter_id='00000000-0000-4000-8000-0000000011a1'
     and subject_id='00000000-0000-4000-8000-0000000011b2') then
   raise exception 'Safety report was not routed to moderation queue';
 end if;
 raise notice 'B11 E2E authorization, mutuality, Gym Shield, block, revocation PASS';
end;
$assert$;
rollback;
