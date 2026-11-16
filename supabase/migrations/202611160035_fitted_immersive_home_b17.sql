-- B17 FITTED immersive profile + privacy-respecting public summary and avatar.
-- All public-facing profile material is gated; save != publish.
begin;

create table app_private.member_profile_summaries_b17(
  user_id uuid primary key references auth.users(id) on delete cascade,
  summary_es text not null default '',
  summary_en text not null default '',
  summary_mode text not null default 'editorial'
    check(summary_mode in ('editorial','ai')),
  ai_consented boolean not null default false,
  ai_consented_at timestamptz,
  share_consented boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table app_private.member_profile_summaries_b17 enable row level security;
revoke all on app_private.member_profile_summaries_b17 from public,anon,authenticated;
comment on table app_private.member_profile_summaries_b17 is
  'A user-owned synopsis; private until explicit publishing consent and eligibility. No birthdays, venues, locations or schedules.';

create function app_private.refresh_profile_summary_b17(p_user uuid)
returns void language plpgsql security definer set search_path=''
as $fn$
declare p record; move_s text; values_s text; hobbies_s text;
  intention text; es text; en text;
begin
  select * into p from public.member_profiles_v26 where user_id=p_user;
  if p.user_id is null then return; end if;
  move_s:=nullif(array_to_string(p.sports[1:2],', '),'');
  values_s:=nullif(array_to_string(p.life_values[1:2],', '),'');
  hobbies_s:=nullif(array_to_string(p.hobbies[1:2],', '),'');
  intention:=case p.dating_intent
    when 'relationship' then 'una relación estable'
    when 'companionship' then 'conexiones de amistad y compañía'
    when 'open_to_explore' then 'conocer a alguien con respeto'
    else null end;
  es:=left(
    coalesce(nullif(split_part(p.display_name,' ',1),''),'Esta persona')||
    ' comparte su estilo de vida con autenticidad.'||
    case when move_s is not null then ' Disfruta '||move_s||'.' else '' end||
    case when hobbies_s is not null then ' Entre sus intereses están '||hobbies_s||'.' else '' end||
    case when values_s is not null then ' Valora '||values_s||'.' else '' end||
    case when intention is not null then ' Le interesa '||intention||'.' else '' end,
    520);
  en:=left(
    coalesce(nullif(split_part(p.display_name,' ',1),''),'This member')||
    ' shares their lifestyle authentically.'||
    case when move_s is not null then ' Enjoys '||move_s||'.' else '' end||
    case when hobbies_s is not null then ' Interests include '||hobbies_s||'.' else '' end||
    case when values_s is not null then ' Values '||values_s||'.' else '' end||
    case when intention is not null then ' Interested in meaningful connections.' else '' end,
    520);
  insert into app_private.member_profile_summaries_b17(
    user_id,summary_es,summary_en,summary_mode,updated_at)
  values(p_user,es,en,'editorial',now())
  on conflict(user_id) do update set summary_es=excluded.summary_es,
    summary_en=excluded.summary_en,summary_mode='editorial',updated_at=now();
end;
$fn$;
revoke all on function app_private.refresh_profile_summary_b17(uuid) from public,anon,authenticated;

create function app_private.profile_changed_refresh_b17()
returns trigger language plpgsql security definer set search_path=''
as $fn$
begin
 perform app_private.refresh_profile_summary_b17(new.user_id);
 return new;
end;
$fn$;
revoke all on function app_private.profile_changed_refresh_b17() from public,anon,authenticated;
create trigger fitted_profile_changed_b17
after insert or update of display_name,sports,hobbies,life_values,dating_intent
on public.member_profiles_v26 for each row
execute function app_private.profile_changed_refresh_b17();

-- Changes to saved pillar answers also invalidate and refresh the synopsis.
create trigger fitted_rhythm_changed_b17
after insert or update of answers,additional_sports,weekends,interests,
 challenge,weeknight,support
on public.member_rhythm_b11 for each row
execute function app_private.profile_changed_refresh_b17();

create function public.fitted_my_summary_b17()
returns jsonb language plpgsql stable security definer set search_path=''
as $fn$
declare me uuid:=auth.uid(); s app_private.member_profile_summaries_b17%rowtype;
begin
 if me is null then return jsonb_build_object('available',false); end if;
 select * into s from app_private.member_profile_summaries_b17
 where user_id=me;
 return jsonb_build_object('available',s.user_id is not null,
   'summary_es',coalesce(s.summary_es,''),
   'summary_en',coalesce(s.summary_en,''),
   'mode',coalesce(s.summary_mode,'editorial'),
   'ai_consented',coalesce(s.ai_consented,false),
   'share_consented',coalesce(s.share_consented,false),
   'updated_at',s.updated_at);
end;
$fn$;

create function public.fitted_summary_consent_b17(p_ai boolean,p_share boolean)
returns text language plpgsql security definer set search_path=''
as $fn$
declare me uuid:=auth.uid();
begin
 if me is null or p_ai is null or p_share is null
   or coalesce(auth.jwt()->>'is_anonymous','false')='true'
   or not exists(select 1 from public.member_profiles_v26 where user_id=me)
 then return 'not_available'; end if;
 insert into app_private.member_profile_summaries_b17(user_id,ai_consented,ai_consented_at,share_consented)
 values(me,p_ai,case when p_ai then now() else null end,p_share)
 on conflict(user_id) do update set ai_consented=p_ai,
   ai_consented_at=case when p_ai then now() else null end,
   share_consented=p_share;
 return 'updated';
end;
$fn$;

-- Whitelist: never send DOB, email, exact city, venue, gym or schedule to AI.
create function public.fitted_summary_context_b17()
returns jsonb language plpgsql stable security definer set search_path=''
as $fn$
declare me uuid:=auth.uid(); s app_private.member_profile_summaries_b17%rowtype;
  p record; r record;
begin
 if me is null then return jsonb_build_object('available',false); end if;
 select * into s from app_private.member_profile_summaries_b17 where user_id=me;
 if s.ai_consented is distinct from true then
   return jsonb_build_object('available',false,'consent_required',true); end if;
 select * into p from public.member_profiles_v26 where user_id=me;
 if p.user_id is null then return jsonb_build_object('available',false); end if;
 select * into r from public.member_rhythm_b11 where user_id=me;
 return jsonb_build_object('available',true,'revision',s.updated_at,
   'name',left(coalesce(p.display_name,''),45),
   'headline',left(coalesce(p.headline,''),120),
   'sports',coalesce(to_jsonb(p.sports[1:4]),'[]'::jsonb),
   'hobbies',coalesce(to_jsonb(p.hobbies[1:4]),'[]'::jsonb),
   'values',coalesce(to_jsonb(p.life_values[1:4]),'[]'::jsonb),
   'goals',coalesce(to_jsonb(p.fitness_goals[1:3]),'[]'::jsonb),
   'intent',p.dating_intent,
   'rhythm',coalesce((select jsonb_object_agg(key,value)
      from jsonb_each_text(coalesce(r.answers,'{}'::jsonb))
      where key in ('sport','frequency','training_mode','weekday',
        'intent','together','train_partner','travel')),'{}'::jsonb));
end;
$fn$;

-- Only service role may stamp AI provenance. User JWT cannot forge an AI badge.
create function public.fitted_summary_save_ai_b17(
 p_user uuid,p_es text,p_en text,p_revision timestamptz)
returns text language plpgsql security definer set search_path=''
as $fn$
begin
 if current_setting('role',true) is distinct from 'service_role' then
   return 'forbidden'; end if;
 if p_user is null or p_revision is null or p_es is null or p_en is null
  or char_length(p_es) not between 70 and 560
  or char_length(p_en) not between 70 and 560
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
$fn$;

-- Existing metadata table was owner-only, but the client previously had no
-- functional media API. Harden it before exposing the new upload path.
alter table public.member_media_v26 drop constraint member_media_v26_check;
alter table public.member_media_v26 add constraint member_media_v26_check
 check(object_key ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](jpg|png)$'
   and split_part(object_key,'/',1)=user_id::text);
create function app_private.fitted_media_guard_b17()
returns trigger language plpgsql set search_path=''
as $fn$
begin
 if tg_op='INSERT' then
   if current_user not in ('postgres','service_role') then
     new.moderation_state='pending';
   end if;
 elsif tg_op='UPDATE' then
   if current_user not in ('postgres','service_role') then
     if old.user_id<>new.user_id or old.object_key<>new.object_key
       or old.moderation_state<>new.moderation_state
     then raise exception 'member cannot approve or transfer a photo'; end if;
   end if;
 end if;
 return new;
end;
$fn$;
create trigger fitted_media_guard_b17
before insert or update on public.member_media_v26
for each row execute function app_private.fitted_media_guard_b17();

create table app_private.fitted_photo_audit_b17(
  id bigint generated always as identity primary key,
  photo_id uuid not null,
  member_id uuid not null,
  reviewer_id uuid not null,
  decision text not null check(decision in ('approved','rejected')),
  reason text not null,
  created_at timestamptz not null default now()
);
alter table app_private.fitted_photo_audit_b17 enable row level security;
revoke all on app_private.fitted_photo_audit_b17 from public,anon,authenticated;

create function public.fitted_photo_review_queue_b17()
returns table(id uuid,user_id uuid,display_name text,object_key text,created_at timestamptz)
language sql stable security definer set search_path=''
as $fn$
 select m.id,m.user_id,p.display_name,m.object_key,m.created_at
 from public.member_media_v26 m
 join public.member_profiles_v26 p on p.user_id=m.user_id
 where app_private.is_brand_administrator(true) and m.moderation_state='pending'
 order by m.created_at asc limit 50;
$fn$;
create function public.fitted_photo_review_b17(p_photo uuid,p_decision text,p_note text)
returns text language plpgsql security definer set search_path=''
as $fn$
declare photo public.member_media_v26%rowtype; reviewer uuid:=auth.uid();
begin
 if not app_private.is_brand_administrator(true) then return 'forbidden'; end if;
 if p_photo is null or p_decision not in ('approved','rejected')
 or char_length(trim(coalesce(p_note,''))) not between 8 and 400 then return 'invalid'; end if;
 select * into photo from public.member_media_v26 where id=p_photo for update;
 if photo.id is null or photo.moderation_state<>'pending' then
   return 'not_available'; end if;
 if p_decision='approved' and not exists(select 1 from storage.objects o
    where o.bucket_id='mfd-profile-private' and o.name=photo.object_key
    and o.metadata->>'mimetype' in ('image/png','image/jpeg')
    and coalesce((o.metadata->>'size')::bigint,6000000)<=5242880)
 then return 'media_not_verified'; end if;
 update public.member_media_v26 set moderation_state=p_decision where id=photo.id;
 insert into app_private.fitted_photo_audit_b17(
   photo_id,member_id,reviewer_id,decision,reason)
 values(photo.id,photo.user_id,reviewer,p_decision,trim(p_note));
 return p_decision;
end;
$fn$;

-- An approved photo is accessible only to another eligible adult, with a
-- currently active dating release, owner opt-in and reciprocal block checks.
create function app_private.fitted_photo_viewable_b17(p_key text)
returns boolean language plpgsql stable security definer set search_path=''
as $fn$
declare viewer uuid:=auth.uid(); owner_id uuid;
begin
 if viewer is null or p_key !~
   '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/' then
   return false; end if;
 owner_id:=split_part(p_key,'/',1)::uuid;
 if viewer=owner_id then return true; end if;
 if not app_private.b11_member_eligible(viewer)
    or not app_private.b11_member_eligible(owner_id) then return false; end if;
 if exists(select 1 from public.community_blocks_b4 b
   where (b.blocker_id=viewer and b.blocked_id=owner_id)
      or (b.blocker_id=owner_id and b.blocked_id=viewer)) then return false; end if;
 return exists(select 1
    from public.member_media_v26 m
    join public.member_profiles_v26 p on p.user_id=m.user_id
    where m.user_id=owner_id and m.object_key=p_key
      and m.position=0 and m.moderation_state='approved'
      and p.social_visibility='members'
      and exists(select 1 from app_private.member_profile_summaries_b17 s
        where s.user_id=owner_id and s.share_consented));
end;
$fn$;
revoke all on function app_private.fitted_photo_viewable_b17(text) from public,anon;
grant execute on function app_private.fitted_photo_viewable_b17(text) to authenticated;

create policy mfd_photo_admin_approved_b17 on storage.objects for select
to authenticated using(bucket_id='mfd-profile-private' and
  app_private.is_brand_administrator(true) and exists(
    select 1 from public.member_media_v26 m where m.object_key=name));
create policy mfd_photo_matches_b17 on storage.objects for select
to authenticated using(bucket_id='mfd-profile-private' and
  app_private.fitted_photo_viewable_b17(name));

create function public.fitted_candidate_card_b17(p_target uuid)
returns jsonb language plpgsql stable security definer set search_path=''
as $fn$
declare viewer uuid:=auth.uid(); s record; m record;
begin
 if viewer is null or p_target is null or viewer=p_target
  or not app_private.b11_member_eligible(viewer)
  or not app_private.b11_member_eligible(p_target) then
   return jsonb_build_object('visible',false); end if;
 if exists(select 1 from public.community_blocks_b4 b
    where (b.blocker_id=viewer and b.blocked_id=p_target)
       or (b.blocker_id=p_target and b.blocked_id=viewer)) then
   return jsonb_build_object('visible',false); end if;
 if not exists(select 1 from app_private.b11_candidates(10) c
    where c.user_id=p_target) then
   return jsonb_build_object('visible',false); end if;
 select s.summary_es,s.summary_en,s.summary_mode into s
 from app_private.member_profile_summaries_b17 s
 join public.member_profiles_v26 p on p.user_id=s.user_id
 where s.user_id=p_target and s.share_consented
   and p.social_visibility='members';
 if s.summary_es is null then
   return jsonb_build_object('visible',true,'summary_es','','summary_en','');
 end if;
 select object_key into m
 from public.member_media_v26
 where user_id=p_target and position=0 and moderation_state='approved' limit 1;
 return jsonb_build_object('visible',true,
   'summary_es',s.summary_es,'summary_en',s.summary_en,
   'mode',s.summary_mode,'photo_key',m.object_key);
end;
$fn$;

revoke all on function public.fitted_my_summary_b17(),
 public.fitted_summary_consent_b17(boolean,boolean),
 public.fitted_summary_context_b17(),
 public.fitted_photo_review_queue_b17(),
 public.fitted_photo_review_b17(uuid,text,text),
 public.fitted_candidate_card_b17(uuid)
from public,anon,authenticated;
grant execute on function public.fitted_my_summary_b17(),
 public.fitted_summary_consent_b17(boolean,boolean),
 public.fitted_summary_context_b17(),
 public.fitted_photo_review_queue_b17(),
 public.fitted_photo_review_b17(uuid,text,text),
 public.fitted_candidate_card_b17(uuid)
to authenticated;
revoke all on function public.fitted_summary_save_ai_b17(uuid,text,text,timestamptz)
from public,anon,authenticated;
grant execute on function public.fitted_summary_save_ai_b17(uuid,text,text,timestamptz)
to service_role;

-- Build honest initial summaries from already consented profile fields.
select app_private.refresh_profile_summary_b17(user_id)
from public.member_profiles_v26;
commit;