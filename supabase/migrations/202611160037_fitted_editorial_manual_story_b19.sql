-- FITTED B19: an author-owned manual story or an opt-in AI-written story.
-- No user is ever automatically switched to AI or made public by this migration.
alter table app_private.member_profile_summaries_b17
 add column if not exists manual_summary_es text not null default '',
 add column if not exists manual_summary_en text not null default '';
alter table app_private.member_profile_summaries_b17
 drop constraint if exists member_profile_summaries_b17_summary_mode_check;
alter table app_private.member_profile_summaries_b17
 add constraint member_profile_summaries_b17_summary_mode_check
 check(summary_mode in ('manual','editorial','ai'));

create or replace function app_private.refresh_profile_summary_b17(p_user uuid)
returns void language plpgsql security definer set search_path=''
as $refresh$
declare p public.member_profiles_v26%rowtype;
 s app_private.member_profile_summaries_b17%rowtype;
 sport_s text; interests_s text; values_s text; goals_s text;
 es text; en text;
begin
 select * into p from public.member_profiles_v26 where user_id=p_user;
 if p.user_id is null then return; end if;
 select * into s from app_private.member_profile_summaries_b17 where user_id=p_user;
 if s.user_id is null then
   insert into app_private.member_profile_summaries_b17
    (user_id,summary_mode,summary_es,summary_en)
   values(p_user,'manual','','') on conflict(user_id) do nothing;
   return;
 end if;
 if s.ai_consented is distinct from true then
   -- Manual text survives any subsequent changes to basic profile or pillars.
   update app_private.member_profile_summaries_b17
    set summary_mode='manual',
     summary_es=coalesce(nullif(manual_summary_es,''),nullif(manual_summary_en,''),''),
     summary_en=coalesce(nullif(manual_summary_en,''),nullif(manual_summary_es,''),''),
     updated_at=now()
   where user_id=p_user;
   return;
 end if;
 -- This is a factual, explicitly labelled *editorial fallback* only,
 -- never displayed as AI. The actual AI writer is separately consented.
 sport_s:=nullif(array_to_string(p.sports[1:5],', '),'');
 interests_s:=nullif(array_to_string(p.hobbies[1:5],', '),'');
 values_s:=nullif(array_to_string(p.life_values[1:5],', '),'');
 goals_s:=nullif(array_to_string(p.fitness_goals[1:4],', '),'');
 es:=coalesce(nullif(split_part(p.display_name,' ',1),''),'Esta persona')||
   case when sport_s is null then '' else ' disfruta actividades como '||sport_s||'.' end||
   case when interests_s is null then '' else ' Entre sus intereses menciona '||interests_s||'.' end||
   case when values_s is null then '' else ' En su perfil destaca valores como '||values_s||'.' end||
   case when goals_s is null then '' else ' Entre sus objetivos figuran '||goals_s||'.' end||
   case when p.dating_intent='relationship' then ' Busca una relación estable.'
        when p.dating_intent='companionship' then ' Le interesa la compañía y la amistad.'
        when p.dating_intent='open_to_explore' then ' Está abierto a conocer personas.'
        else '' end;
 en:=coalesce(nullif(split_part(p.display_name,' ',1),''),'This member')||
   case when sport_s is null then '' else ' enjoys activities such as '||sport_s||'.' end||
   case when interests_s is null then '' else ' Lists interests including '||interests_s||'.' end||
   case when values_s is null then '' else ' Lists values such as '||values_s||'.' end||
   case when goals_s is null then '' else ' Fitness goals include '||goals_s||'.' end||
   case when p.dating_intent is null then ''
     else ' Looking to meet people with compatible intentions.' end;
 update app_private.member_profile_summaries_b17
   set summary_mode='editorial',summary_es=left(es,1500),
       summary_en=left(en,1500),updated_at=now()
 where user_id=p_user and ai_consented;
end;
$refresh$;

create or replace function public.fitted_save_manual_summary_b19(
 p_text text,p_locale text)
returns text language plpgsql security definer set search_path=''
as $save$
declare me uuid:=auth.uid(); result text;
begin
 if me is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
   or not exists(select 1 from public.member_profiles_v26 where user_id=me)
 then return 'not_available'; end if;
 if p_locale not in ('es','en') or p_text is null then return 'invalid'; end if;
 result:=trim(regexp_replace(p_text,'[ \t]+',' ','g'));
 if char_length(result) not between 80 and 1600 or
   result ~* '(https?://|www[.]|@[a-z0-9_]+|[0-9]{3}[- .][0-9]{3}[- .][0-9]{4})'
 then return 'invalid'; end if;
 insert into app_private.member_profile_summaries_b17(user_id,summary_mode)
 values(me,'manual') on conflict(user_id) do nothing;
 if exists(select 1 from app_private.member_profile_summaries_b17
   where user_id=me and ai_consented) then return 'ai_active'; end if;
 update app_private.member_profile_summaries_b17
  set manual_summary_es=case when p_locale='es' then result else manual_summary_es end,
      manual_summary_en=case when p_locale='en' then result else manual_summary_en end,
      summary_es=case when p_locale='es' then result
            else coalesce(nullif(manual_summary_es,''),result) end,
      summary_en=case when p_locale='en' then result
            else coalesce(nullif(manual_summary_en,''),result) end,
      summary_mode='manual',updated_at=now()
 where user_id=me and not ai_consented;
 if not found then return 'ai_active'; end if;
 return 'saved';
end;
$save$;
revoke all on function public.fitted_save_manual_summary_b19(text,text)
 from public,anon,authenticated;
grant execute on function public.fitted_save_manual_summary_b19(text,text)
 to authenticated;

create or replace function public.fitted_summary_consent_b17(p_ai boolean,p_share boolean)
returns text language plpgsql security definer set search_path=''
as $consent$
declare me uuid:=auth.uid();
begin
 if me is null or p_ai is null or p_share is null
   or coalesce(auth.jwt()->>'is_anonymous','false')='true'
   or not exists(select 1 from public.member_profiles_v26 where user_id=me)
 then return 'not_available'; end if;
 insert into app_private.member_profile_summaries_b17
  (user_id,ai_consented,ai_consented_at,share_consented,summary_mode)
 values(me,p_ai,case when p_ai then now() else null end,p_share,
       case when p_ai then 'editorial' else 'manual' end)
 on conflict(user_id) do update
  set ai_consented=excluded.ai_consented,
      ai_consented_at=excluded.ai_consented_at,
      share_consented=excluded.share_consented;
 perform app_private.refresh_profile_summary_b17(me);
 return 'updated';
end;
$consent$;

create or replace function public.fitted_my_summary_b17()
returns jsonb language plpgsql stable security definer set search_path=''
as $mine$
declare me uuid:=auth.uid(); s app_private.member_profile_summaries_b17%rowtype;
begin
 if me is null or coalesce(auth.jwt()->>'is_anonymous','false')='true' then
   return jsonb_build_object('available',false);
 end if;
 select * into s from app_private.member_profile_summaries_b17
 where user_id=me;
 return jsonb_build_object(
   'available',s.user_id is not null,
   'summary_es',case when coalesce(s.ai_consented,false)
       then coalesce(s.summary_es,'')
       else coalesce(nullif(s.manual_summary_es,''),
                     nullif(s.manual_summary_en,''),'') end,
   'summary_en',case when coalesce(s.ai_consented,false)
       then coalesce(s.summary_en,'')
       else coalesce(nullif(s.manual_summary_en,''),
                     nullif(s.manual_summary_es,''),'') end,
   'manual_summary_es',coalesce(s.manual_summary_es,''),
   'manual_summary_en',coalesce(s.manual_summary_en,''),
   'mode',case when coalesce(s.ai_consented,false)
     then coalesce(s.summary_mode,'editorial') else 'manual' end,
   'ai_consented',coalesce(s.ai_consented,false),
   'share_consented',coalesce(s.share_consented,false),
   'updated_at',s.updated_at);
end;
$mine$;

-- Rich *minimum necessary* personal context. Excludes DOB, city, location
-- data, gym IDs, specific training time slots and identifiable contact fields.
create or replace function public.fitted_summary_context_b17()
returns jsonb language plpgsql stable security definer set search_path=''
as $context$
declare me uuid:=auth.uid(); s app_private.member_profile_summaries_b17%rowtype;
 p public.member_profiles_v26%rowtype; r public.member_rhythm_b11%rowtype;
begin
 if me is null then return jsonb_build_object('available',false); end if;
 select * into s from app_private.member_profile_summaries_b17 where user_id=me;
 if s.user_id is null or s.ai_consented is distinct from true
   or coalesce(auth.jwt()->>'is_anonymous','false')='true'
 then return jsonb_build_object('available',false,'consent_required',true); end if;
 select * into p from public.member_profiles_v26 where user_id=me;
 if p.user_id is null then return jsonb_build_object('available',false); end if;
 select * into r from public.member_rhythm_b11 where user_id=me;
 return jsonb_build_object(
   'available',true,'revision',s.updated_at,
   'name',left(coalesce(p.display_name,''),45),
   'headline',left(coalesce(p.headline,''),120),
   'about_me',left(coalesce(p.about_me,''),600),
   'occupation',left(coalesce(p.occupation,''),100),
   'sports',coalesce(to_jsonb(p.sports[1:8]),'[]'::jsonb),
   'hobbies',coalesce(to_jsonb(p.hobbies[1:8]),'[]'::jsonb),
   'values',coalesce(to_jsonb(p.life_values[1:8]),'[]'::jsonb),
   'goals',coalesce(to_jsonb(p.fitness_goals[1:6]),'[]'::jsonb),
   'achievements',coalesce(to_jsonb(p.achievements[1:4]),'[]'::jsonb),
   'languages',coalesce(to_jsonb(p.languages[1:5]),'[]'::jsonb),
   'frequency',left(coalesce(p.training_frequency,''),60),
   'intent',left(coalesce(p.dating_intent,''),60),
   'activities',coalesce(to_jsonb(r.additional_sports[1:8]),'[]'::jsonb),
   'weekends',coalesce(to_jsonb(r.weekends[1:6]),'[]'::jsonb),
   'interests',coalesce(to_jsonb(r.interests[1:8]),'[]'::jsonb),
   'challenge',left(coalesce(r.challenge,''),180),
   'weeknight',left(coalesce(r.weeknight,''),180),
   'support',left(coalesce(r.support,''),180),
   'rhythm',coalesce((select jsonb_object_agg(key,value)
     from jsonb_each_text(coalesce(r.answers,'{}'::jsonb))
     where key in ('sport','frequency','training_mode','training_with',
       'competitions','weekday','sleep','travel','intent','together',
       'train_partner','active_importance')),'{}'::jsonb));
end;
$context$;

create or replace function public.fitted_summary_save_ai_b17(
 p_user uuid,p_es text,p_en text,p_revision timestamptz)
returns text language plpgsql security definer set search_path=''
as $ai$
begin
 if current_setting('role',true) is distinct from 'service_role'
 then return 'forbidden'; end if;
 if p_user is null or p_revision is null or p_es is null or p_en is null
   or char_length(p_es) not between 180 and 1600
   or char_length(p_en) not between 180 and 1600
   or p_es ~* '(https?://|www[.]|@[a-z0-9_]+|[0-9]{3}[- .][0-9]{3}[- .][0-9]{4})'
   or p_en ~* '(https?://|www[.]|@[a-z0-9_]+|[0-9]{3}[- .][0-9]{3}[- .][0-9]{4})'
 then return 'invalid'; end if;
 update app_private.member_profile_summaries_b17
  set summary_es=trim(p_es),summary_en=trim(p_en),
      summary_mode='ai',updated_at=now()
 where user_id=p_user and ai_consented and updated_at=p_revision;
 if not found then return 'stale_or_not_consented'; end if;
 return 'saved';
end;
$ai$;

-- Respect both explicit sharing consent AND member visibility; a public-facing
-- story is never exposed merely because it was drafted locally.
create or replace function public.fitted_candidate_showcase_b18(p_user uuid)
returns jsonb language plpgsql stable security definer set search_path=''
as $show$
declare viewer uuid:=auth.uid(); result jsonb;
begin
 if viewer is null or p_user is null or viewer=p_user
   or not app_private.b11_member_eligible(viewer)
   or not app_private.b11_member_eligible(p_user)
   or not exists(select 1 from app_private.b11_candidates(25) c
     where c.user_id=p_user)
 then return jsonb_build_object('available',false); end if;
 select jsonb_build_object(
  'available',true,
  'summary_es',left(case when s.ai_consented then s.summary_es else
      coalesce(nullif(s.manual_summary_es,''),nullif(s.manual_summary_en,''),'') end,1600),
  'summary_en',left(case when s.ai_consented then s.summary_en else
      coalesce(nullif(s.manual_summary_en,''),nullif(s.manual_summary_es,''),'') end,1600),
  'photo_key',(
     select m.object_key from public.member_media_v26 m
     where m.user_id=p_user and m.position=0 and
       m.moderation_state='approved'
       and app_private.fitted_photo_viewable_b17(m.object_key)
     limit 1
  )
 ) into result
 from app_private.member_profile_summaries_b17 s
 join public.member_profiles_v26 p on p.user_id=s.user_id
 where s.user_id=p_user and s.share_consented
   and p.social_visibility='members';
 return coalesce(result,jsonb_build_object('available',false));
end;
$show$;
revoke all on function public.fitted_candidate_showcase_b18(uuid)
 from public,anon,authenticated;
grant execute on function public.fitted_candidate_showcase_b18(uuid) to authenticated;
