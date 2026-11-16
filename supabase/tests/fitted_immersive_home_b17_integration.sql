-- B17 security and automatic summary lifecycle. Disposable CI database only.
begin;
do $tests$
declare n integer; status text;
begin
 if (select rowsecurity from pg_tables where schemaname='app_private'
   and tablename='member_profile_summaries_b17') is distinct from true then
   raise exception 'AI summaries require private RLS'; end if;
 if has_table_privilege('anon','app_private.member_profile_summaries_b17','select')
   or has_table_privilege('authenticated','app_private.member_profile_summaries_b17','select')
 then raise exception 'Summary source leaked'; end if;
 if has_function_privilege('authenticated',
   'public.fitted_summary_save_ai_b17(uuid,text,text,timestamptz)','execute')
 then raise exception 'Client can forge AI provenance'; end if;
 if public.fitted_summary_consent_b17(true,true)<>'not_available'
 then raise exception 'Anonymous AI consent permitted'; end if;
 if public.fitted_photo_review_b17(null,'approved','No permission')<>'forbidden'
 then raise exception 'Anonymous photo moderator permitted'; end if;
 if public.fitted_candidate_card_b17(null)->>'visible'<>'false'
 then raise exception 'Anonymous candidate summary exposed'; end if;
 if public.fitted_my_summary_b17()->>'available'<>'false'
 then raise exception 'Summary exposed anonymously'; end if;
 if not exists(select 1 from pg_policies where schemaname='storage'
   and tablename='objects' and policyname='mfd_photo_matches_b17') then
   raise exception 'Private approved candidate photo rule missing'; end if;
 raise notice 'B17 private AI summary and candidate gate PASS';
end;
$tests$;

insert into auth.users(id,email,email_confirmed_at) values
 ('00000000-0000-4000-8000-0000000017a1','member17@example.invalid',now()),
 ('00000000-0000-4000-8000-0000000017ad','admin17@example.invalid',now());
insert into app_private.brand_administrators(user_id,role)
 values('00000000-0000-4000-8000-0000000017ad','owner');
insert into public.member_profiles_v26(
 user_id,display_name,date_of_birth,city,sports,life_values,hobbies,
 onboarding_complete)
values('00000000-0000-4000-8000-0000000017a1','Alex',
 date '1990-01-01','Querétaro',array['running'],array['honestidad'],
 array['café'],true);
do $check$
declare text_es text;
begin
 select summary_es into text_es from app_private.member_profile_summaries_b17
  where user_id='00000000-0000-4000-8000-0000000017a1';
 if text_es not like '%running%' or text_es not like '%honestidad%'
 then raise exception 'Profile trigger did not create truthful summary: %',text_es;
 end if;
end;
$check$;
update public.member_profiles_v26 set sports=array['ciclismo']
where user_id='00000000-0000-4000-8000-0000000017a1';
do $check$
declare s text;
begin
 select summary_es into s from app_private.member_profile_summaries_b17
 where user_id='00000000-0000-4000-8000-0000000017a1';
 if s not like '%ciclismo%' or s like '%running%' then
   raise exception 'Profile summary not refreshed after save'; end if;
end;
$check$;

set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000017a1',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $check$
begin
 if public.fitted_summary_consent_b17(true,true)<>'updated' then
   raise exception 'Owner could not consent'; end if;
 if (public.fitted_my_summary_b17()->>'ai_consented')::boolean is distinct from true then
   raise exception 'Owner AI consent not saved'; end if;
 if public.fitted_summary_context_b17()->>'available'<>'true' then
   raise exception 'Whitelisted AI context denied to owner'; end if;
 if public.fitted_summary_save_ai_b17(auth.uid(),
   repeat('English safe test. ',10),repeat('English safe test. ',10),now())
   <>'forbidden' then raise exception 'User forged AI summary'; end if;
 if public.fitted_photo_review_b17(null,'approved','Member attempt')<>'forbidden'
 then raise exception 'User approved another image'; end if;
end;
$check$;
reset role;

-- A member cannot insert an already approved photo or self-approve it.
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000017a1',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
insert into public.member_media_v26(user_id,object_key,position,moderation_state)
values('00000000-0000-4000-8000-0000000017a1',
 '00000000-0000-4000-8000-0000000017a1/00000000-0000-4000-8000-000000017001.png',
 0,'approved');
do $check$
declare st text; photo_id uuid;
begin
 select moderation_state,id into st,photo_id from public.member_media_v26
 where user_id=auth.uid();
 if st<>'pending' then raise exception 'Member self-approved photo insert'; end if;
 begin
   update public.member_media_v26 set moderation_state='approved'
   where id=photo_id;
   raise exception 'Member self-approved photo update';
 exception when insufficient_privilege then null;
 when others then
   if sqlerrm='Member self-approved photo update' then raise; end if;
 end;
end;
$check$;
reset role;

-- Moderation required; reviewer AAL1 must be unable to approve.
insert into storage.objects(bucket_id,name,owner_id,metadata)
 values('mfd-profile-private',
 '00000000-0000-4000-8000-0000000017a1/00000000-0000-4000-8000-000000017001.png',
 '00000000-0000-4000-8000-0000000017a1',
 '{"mimetype":"image/png","size":22000}'::jsonb);
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000017ad',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $check$
declare id_val uuid; outcome text;
begin
 -- Queue is MFA-guarded, returning no records in AAL1.
 if (select count(*) from public.fitted_photo_review_queue_b17())<>0 then
    raise exception 'MFA bypass on photo queue'; end if;
end;
$check$;
reset role;
rollback;