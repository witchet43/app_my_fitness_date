-- B5: privacy-first FitDating preference studio, NOT an activation of
-- discovery, chat, matching or an independent age-verification provider.
-- No member/admin can enable sensitive discovery by changing UI preferences.
-- All sensitive data remains in app_private; user-scoped RPC only.
begin;

create table app_private.fitdating_gate_b5 (
  id boolean primary key default true check (id),
  independently_verified_provider_live boolean not null default false,
  independent_verification_audit_approved boolean not null default false,
  moderation_staffed boolean not null default false,
  privacy_review_approved boolean not null default false,
  release_approved boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table app_private.fitdating_gate_b5 enable row level security;
revoke all on app_private.fitdating_gate_b5 from public,anon,authenticated;
insert into app_private.fitdating_gate_b5(id) values(true)
on conflict(id) do nothing;

create or replace function app_private.b5_discovery_open()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((
    select g.independently_verified_provider_live
      and g.independent_verification_audit_approved
      and g.moderation_staffed and g.privacy_review_approved
      and g.release_approved
    from app_private.fitdating_gate_b5 g where g.id
  ),false);
$$;
revoke all on function app_private.b5_discovery_open()
  from public,anon,authenticated;
-- The public invoker wrapper may read only this fail-closed boolean; the
-- private schema is not exposed as a REST resource.
grant execute on function app_private.b5_discovery_open()
  to authenticated;

create table app_private.fitdating_preferences_b5(
  user_id uuid primary key references auth.users(id) on delete cascade,
  relationship_intent text not null default 'serious'
    check(relationship_intent in ('serious','companionship','exploring')),
  sports text[] not null default '{}'::text[],
  lifestyle_frequency text not null default 'flexible'
    check(lifestyle_frequency in ('starting','weekly','frequent','flexible')),
  gym_privacy_mode text not null default 'other_gyms'
    check(gym_privacy_mode in ('other_gyms','same_gym_other_time')),
  participation_requested boolean not null default false,
  updated_at timestamptz not null default now(),
  check(cardinality(sports)<=8)
);
alter table app_private.fitdating_preferences_b5 enable row level security;
revoke all on app_private.fitdating_preferences_b5
  from public,anon,authenticated;

-- Candidate discovery is still disabled while external verification and
-- operational controls are missing. No "test-only" bypass from Flutter.
create or replace function public.discover_dating_candidates(p_limit integer default 20)
returns table(user_id uuid,display_name text,city text,sports text[])
language plpgsql security invoker set search_path = ''
as $$
begin
  if not app_private.b5_discovery_open() then
    return;
  end if;
  if (select auth.uid()) is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
     or p_limit is null or p_limit not between 1 and 10 then
    return;
  end if;
  if not exists (
    select 1 from app_private.fitdating_preferences_b5 p
    where p.user_id=(select auth.uid()) and p.participation_requested
  ) then return; end if;
  if not exists(
    select 1 from app_private.community_pilot_b4 a
    where a.user_id=(select auth.uid()) and a.active
  ) then return; end if;
  if not exists(
    select 1 from public.member_consents_v26 c
    where c.user_id=(select auth.uid())
      and c.consent_kind='dating' and c.document_version='dating-v1'
  ) then return; end if;
  if exists (
    select 1 from app_private.community_suspensions_b4 s
    where s.user_id=(select auth.uid()) and s.active
  ) or exists(
    select 1 from app_private.community_deletion_requests_b4 d
    where d.user_id=(select auth.uid())
  ) then return; end if;
  return query
  select d.user_id,d.display_name,d.city,d.sports
  from app_private.discover_dating_candidates(p_limit) d
  where exists (
    select 1 from app_private.fitdating_preferences_b5 pref
    where pref.user_id=d.user_id and pref.participation_requested
  )
    and exists(
      select 1 from app_private.community_pilot_b4 a
      where a.user_id=d.user_id and a.active
    )
    and exists(
      select 1 from public.member_consents_v26 c
      where c.user_id=d.user_id and c.consent_kind='dating'
        and c.document_version='dating-v1'
    )
    and not exists(
      select 1 from public.community_blocks_b4 b
      where (b.blocker_id=(select auth.uid()) and b.blocked_id=d.user_id)
        or (b.blocker_id=d.user_id and b.blocked_id=(select auth.uid()))
    )
    and not exists(
      select 1 from app_private.community_suspensions_b4 s
      where s.user_id=d.user_id and s.active
    )
    and not exists(
      select 1 from app_private.community_deletion_requests_b4 r
      where r.user_id=d.user_id
    );
end;
$$;
revoke all on function public.discover_dating_candidates(integer)
  from public,anon,authenticated;
grant execute on function public.discover_dating_candidates(integer)
  to authenticated;

create or replace function public.fitdating_status_b5()
returns jsonb
language plpgsql stable security definer set search_path=''
as $$
declare
  v_user uuid := (select auth.uid());
  v_review boolean := false;
  v_consented boolean := false;
  v_member boolean := false;
  v_requested boolean := false;
  v_enabled boolean := false;
  v_intent text := 'serious';
  v_sports text[] := '{}'::text[];
  v_frequency text := 'flexible';
  v_mode text := 'other_gyms';
begin
  if v_user is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
     or not exists(select 1 from auth.users u where u.id=v_user
                   and u.email_confirmed_at is not null)
     or exists(select 1 from app_private.brand_administrators a
               where a.user_id=v_user and a.active)
  then
    return jsonb_build_object('status','not_available','enabled',false);
  end if;
  select coalesce((public.my_adult_eligibility()->>'approved')::boolean,false)
    into v_review;
  select exists(
    select 1 from public.member_consents_v26 c
    where c.user_id=v_user and c.consent_kind='dating'
      and c.document_version='dating-v1'
  ) into v_consented;
  select exists(
    select 1 from app_private.community_pilot_b4 m
    where m.user_id=v_user and m.active
  ) into v_member;
  select p.relationship_intent,p.sports,p.lifestyle_frequency,
         p.gym_privacy_mode,p.participation_requested
  into v_intent,v_sports,v_frequency,v_mode,v_requested
  from app_private.fitdating_preferences_b5 p
  where p.user_id=v_user;
  v_intent:=coalesce(v_intent,'serious');
  v_sports:=coalesce(v_sports,'{}'::text[]);
  v_frequency:=coalesce(v_frequency,'flexible');
  v_mode:=coalesce(v_mode,'other_gyms');
  v_requested:=coalesce(v_requested,false);
  v_enabled := app_private.b5_discovery_open() and v_review
    and v_consented and v_member and v_requested
    and not exists(select 1 from app_private.community_suspensions_b4 s
      where s.user_id=v_user and s.active)
    and not exists(select 1 from app_private.community_deletion_requests_b4 r
      where r.user_id=v_user);
  return jsonb_build_object(
    'status','available','enabled',v_enabled,
    'age_verified',v_review,'dating_consent',v_consented,
    'pilot_member',v_member,
    'independent_provider_ready',false,
    'discovery_release_ready',app_private.b5_discovery_open(),
    'participation_requested',v_requested,
    'relationship_intent',v_intent,
    'sports',to_jsonb(v_sports),
    'lifestyle_frequency',v_frequency,
    'gym_privacy_mode',v_mode);
end;
$$;
revoke all on function public.fitdating_status_b5()
  from public,anon,authenticated;
grant execute on function public.fitdating_status_b5()
  to authenticated;

create or replace function public.fitdating_save_preferences_b5(
  p_intent text,p_sports text[],p_frequency text,
  p_mode text,p_requested boolean
) returns text
language plpgsql security definer set search_path=''
as $$
declare v_user uuid := (select auth.uid());
begin
  if v_user is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
    or not exists(select 1 from auth.users u where u.id=v_user
      and u.email_confirmed_at is not null)
    or exists(select 1 from app_private.brand_administrators a
      where a.user_id=v_user and a.active)
    or exists(select 1 from app_private.community_suspensions_b4 s
      where s.user_id=v_user and s.active)
    or exists(select 1 from app_private.community_deletion_requests_b4 d
      where d.user_id=v_user)
    or not exists(select 1 from public.member_profiles_v26 p
      where p.user_id=v_user and p.onboarding_complete
        and p.date_of_birth<=(current_date-interval '18 years')::date)
  then return 'forbidden'; end if;
  if p_intent is null or p_intent <> all(array['serious','companionship','exploring'])
    or p_frequency is null or p_frequency <> all(array['starting','weekly','frequent','flexible'])
    or p_mode is null or p_mode <> all(array['other_gyms','same_gym_other_time'])
    or p_requested is null
    or p_sports is null or cardinality(p_sports)>8 or
    exists(select 1 from unnest(p_sports) x
      where x is null or x <> all(array[
        'running','cycling','hiking','strength','yoga',
        'hyrox','walking','swimming','other'
      ]))
  then return 'invalid'; end if;
  if p_requested and not exists(
    select 1 from public.member_consents_v26 c
    where c.user_id=v_user and c.consent_kind='dating'
      and c.document_version='dating-v1'
  ) then return 'consent_required'; end if;
  insert into app_private.fitdating_preferences_b5(
    user_id,relationship_intent,sports,lifestyle_frequency,
    gym_privacy_mode,participation_requested)
  values(v_user,p_intent,p_sports,p_frequency,p_mode,p_requested)
  on conflict(user_id) do update set
    relationship_intent=excluded.relationship_intent,
    sports=excluded.sports,
    lifestyle_frequency=excluded.lifestyle_frequency,
    gym_privacy_mode=excluded.gym_privacy_mode,
    participation_requested=excluded.participation_requested,
    updated_at=now();
  -- The legacy discovery table must never inherit UI's requested flag as
  -- actual discoverability. Only the controlled release can set it later.
  update app_private.dating_profiles
    set dating_enabled=false,updated_at=now()
    where user_id=v_user;
  return 'saved';
end;
$$;
revoke all on function public.fitdating_save_preferences_b5(text,text[],text,text,boolean)
  from public,anon,authenticated;
grant execute on function public.fitdating_save_preferences_b5(text,text[],text,text,boolean)
  to authenticated;

create or replace function public.fitdating_disable_b5()
returns text
language plpgsql security definer set search_path=''
as $$
declare v_user uuid := (select auth.uid());
begin
  if v_user is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
  then return 'forbidden'; end if;
  update app_private.fitdating_preferences_b5
    set participation_requested=false,updated_at=now()
    where user_id=v_user;
  update app_private.dating_profiles
    set dating_enabled=false,updated_at=now()
    where user_id=v_user;
  return 'disabled';
end;
$$;
revoke all on function public.fitdating_disable_b5()
  from public,anon,authenticated;
grant execute on function public.fitdating_disable_b5()
  to authenticated;

comment on function public.fitdating_status_b5() is
  'B5: private self-only readiness. Independent identity provider absent; discovery NO-GO.';
comment on table app_private.fitdating_gate_b5 is
  'NO-GO default. Requires independent age verification integration, staffing, privacy QA and release gates.';
commit;
