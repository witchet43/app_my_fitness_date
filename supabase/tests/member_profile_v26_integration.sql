-- Disposable Postgres CI only. Two-account adversarial RLS test for V26.
begin;
insert into auth.users(id,email) values
 ('10000000-0000-4000-8000-000000000007','v26-a@example.test'),
 ('10000000-0000-4000-8000-000000000008','v26-b@example.test');

set role anon;
do $$ begin
  if has_table_privilege(current_user,'public.member_profiles_v26','SELECT')
    or has_table_privilege(current_user,'public.member_training_places_v26','SELECT')
    or has_table_privilege(current_user,'public.member_media_v26','SELECT')
    or has_table_privilege(current_user,'public.member_consents_v26','SELECT')
  then raise exception 'V26 anonymous has access to a private table'; end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000007',false);
insert into public.member_profiles_v26 (
 user_id,display_name,city,date_of_birth,sports,about_me,dating_intent,
 social_visibility,onboarding_complete
) values (
 '10000000-0000-4000-8000-000000000007','Atleta Uno','Querétaro',
 date '1995-01-02', array['Running'], 'Me encanta correr',
 'relationship','members',true);
insert into public.member_training_places_v26 (
 user_id,venue_kind,place_name,city,general_zone
) values (
 '10000000-0000-4000-8000-000000000007',
 'studio','Studio Solo Mio','Querétaro','Sur');
insert into public.member_consents_v26 (user_id,consent_kind,document_version)
values (
 '10000000-0000-4000-8000-000000000007','privacy','draft-v26');
insert into public.member_media_v26 (user_id,object_key)
values (
 '10000000-0000-4000-8000-000000000007',
 '10000000-0000-4000-8000-000000000007/photo-1.jpg');

-- Foreign owner fields are rejected on INSERT, with user B as requester later.
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000008',false);
do $$ begin
 if exists(select 1 from public.member_profiles_v26) then
   raise exception 'V26 user B read another member profile';
 end if;
 if exists(select 1 from public.member_training_places_v26) then
   raise exception 'V26 user B read the private studio';
 end if;
 if exists(select 1 from public.member_media_v26) then
   raise exception 'V26 user B read pending photo metadata';
 end if;
 if exists(select 1 from public.member_consents_v26) then
   raise exception 'V26 user B read another member consent';
 end if;
 if exists(select 1 from storage.objects
           where bucket_id='mfd-profile-private') then
   raise exception 'V26 user B read another member storage object';
 end if;
end $$;
-- An unauthorized owner switch cannot change A's data.
update public.member_profiles_v26 set display_name='Compromised'
where user_id='10000000-0000-4000-8000-000000000007';

reset role;
set role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000007',false);
do $$ begin
 if (select display_name from public.member_profiles_v26
     where user_id='10000000-0000-4000-8000-000000000007') <> 'Atleta Uno' then
   raise exception 'V26 foreign update bypassed profile RLS';
 end if;
 if not exists(select 1 from public.member_training_places_v26) then
   raise exception 'V26 member cannot see own place';
 end if;
end $$;
reset role;
rollback;
