-- Account-wide Fitted AI preference: one explicit choice, auditable and revocable.
-- Replaces inconsistent per-feature AI switches; sharing/dating permissions stay separate.
begin;

create table if not exists public.fitted_ai_account_preferences_v1 (
  user_id uuid primary key references auth.users(id) on delete cascade,
  enabled boolean not null,
  source text not null check (source in ('onboarding','settings')),
  chosen_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1 check (version >= 1)
);
alter table public.fitted_ai_account_preferences_v1 enable row level security;
revoke all on public.fitted_ai_account_preferences_v1 from public,anon,authenticated;
grant select on public.fitted_ai_account_preferences_v1 to authenticated;
create policy fitted_ai_preference_read_own_v1
  on public.fitted_ai_account_preferences_v1 for select to authenticated
  using (user_id=(select auth.uid()));

create table if not exists app_private.fitted_ai_account_events_v1 (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  enabled boolean not null,
  source text not null check (source in ('onboarding','settings')),
  recorded_at timestamptz not null default now()
);
create index if not exists fitted_ai_account_events_owner_time_v1
  on app_private.fitted_ai_account_events_v1(user_id,recorded_at desc);
alter table app_private.fitted_ai_account_events_v1 enable row level security;
revoke all on app_private.fitted_ai_account_events_v1 from public,anon,authenticated;

-- No prior feature consent authorizes newly introduced account-wide AI uses.
-- Existing accounts must explicitly select a new unified preference.
-- Fail closed during the transition; keep manual summaries and conversations.
update public.fit_ia_settings_v1 set ai_enabled=false,consented_at=null;
update app_private.member_profile_summaries_b17
  set ai_consented=false,ai_consented_at=null
  where ai_consented=true;

create or replace function public.fitted_ai_account_preference_v1()
returns jsonb language plpgsql stable security definer set search_path=''
as $pref$
declare v_uid uuid:=auth.uid();
  pref public.fitted_ai_account_preferences_v1%rowtype;
begin
  if v_uid is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
  then raise exception 'authentication_required' using errcode='28000'; end if;
  select * into pref from public.fitted_ai_account_preferences_v1 where user_id=v_uid;
  return jsonb_build_object(
    'configured',pref.user_id is not null,
    'enabled',coalesce(pref.enabled,false),
    'source',pref.source,'version',pref.version,
    'updated_at',pref.updated_at);
end;
$pref$;
revoke all on function public.fitted_ai_account_preference_v1()
  from public,anon,authenticated;
grant execute on function public.fitted_ai_account_preference_v1()
  to authenticated;

create or replace function public.fitted_set_ai_account_preference_v1(
  p_enabled boolean,p_source text default 'settings')
returns jsonb language plpgsql security definer set search_path=''
as $set$
declare v_uid uuid:=auth.uid(); v_status text;
  pref public.fitted_ai_account_preferences_v1%rowtype;
begin
  if v_uid is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
  then raise exception 'authentication_required' using errcode='28000'; end if;
  if p_enabled is null or p_source not in ('onboarding','settings')
  then raise exception 'invalid_ai_preference' using errcode='22023'; end if;
  insert into public.fitted_ai_account_preferences_v1(user_id,enabled,source)
    values(v_uid,p_enabled,p_source)
  on conflict (user_id) do update set
    enabled=excluded.enabled,
    source=excluded.source,
    updated_at=now(),
    version=public.fitted_ai_account_preferences_v1.version+1
  where p_source='settings'
  returning * into pref;
  if pref.user_id is null then
    -- A second first-login prompt on another device cannot overwrite a choice.
    select * into pref from public.fitted_ai_account_preferences_v1
      where user_id=v_uid;
    v_status:='already_configured';
  else
    v_status:='saved';
    insert into app_private.fitted_ai_account_events_v1(user_id,enabled,source)
      values(v_uid,pref.enabled,p_source);
  end if;
  -- Keep the two legacy backends in lockstep with the global decision.
  insert into public.fit_ia_settings_v1(user_id,ai_enabled,consented_at)
    values(v_uid,pref.enabled,case when pref.enabled then now() end)
  on conflict (user_id) do update set
    ai_enabled=excluded.ai_enabled,
    consented_at=excluded.consented_at;
  insert into app_private.member_profile_summaries_b17(
      user_id,ai_consented,ai_consented_at,summary_mode)
    values(v_uid,pref.enabled,
      case when pref.enabled then now() end,
      case when pref.enabled then 'editorial' else 'manual' end)
  on conflict (user_id) do update set
    ai_consented=excluded.ai_consented,
    ai_consented_at=excluded.ai_consented_at;
  if exists (select 1 from public.member_profiles_v26 where user_id=v_uid)
  then perform app_private.refresh_profile_summary_b17(v_uid); end if;
  return jsonb_build_object('status',v_status,'configured',true,
    'enabled',pref.enabled,'version',pref.version,
    'source',pref.source,'updated_at',pref.updated_at);
end;
$set$;
revoke all on function public.fitted_set_ai_account_preference_v1(boolean,text)
  from public,anon,authenticated;
grant execute on function public.fitted_set_ai_account_preference_v1(boolean,text)
  to authenticated;

-- Compatibility entrypoint for old Fit-IA clients: always global.
create or replace function public.fit_ia_set_consent_v1(p_enabled boolean)
returns jsonb language plpgsql security definer set search_path=''
as $legacyfit$
declare result jsonb; v_uid uuid:=auth.uid();
begin
  if not exists (select 1 from public.fitted_ai_account_preferences_v1
    where user_id=v_uid) then
    raise exception 'first_login_ai_choice_required' using errcode='42501';
  end if;
  result:=public.fitted_set_ai_account_preference_v1(p_enabled,'settings');
  return jsonb_build_object('ai_enabled',result->'enabled',
    'account_wide',true,'status',result->>'status');
end;
$legacyfit$;

-- Profile visibility remains independently selectable; its AI toggle
-- now changes the SAME account-wide preference, never a second flag.
create or replace function public.fitted_summary_consent_b17(
  p_ai boolean,p_share boolean)
returns text language plpgsql security definer set search_path=''
as $legacyprofile$
declare v_uid uuid:=auth.uid(); v_enabled boolean;
begin
  if v_uid is null or p_ai is null or p_share is null
    or coalesce(auth.jwt()->>'is_anonymous','false')='true'
    or not exists (select 1 from public.member_profiles_v26 where user_id=v_uid)
  then return 'not_available'; end if;
  select enabled into v_enabled from public.fitted_ai_account_preferences_v1
    where user_id=v_uid;
  if not found then return 'first_login_ai_choice_required'; end if;
  if v_enabled is distinct from p_ai then
    perform public.fitted_set_ai_account_preference_v1(p_ai,'settings');
  end if;
  insert into app_private.member_profile_summaries_b17(
    user_id,share_consented,summary_mode)
    values(v_uid,p_share,case when p_ai then 'editorial' else 'manual' end)
  on conflict(user_id) do update set
    share_consented=excluded.share_consented;
  return 'updated';
end;
$legacyprofile$;

-- Erasing private conversations does not silently change the global AI choice.
create or replace function public.fit_ia_delete_my_data_v1()
returns boolean language plpgsql security definer set search_path=''
as $delete$
declare v_uid uuid:=auth.uid();
begin
  if v_uid is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
  then raise exception 'authentication_required' using errcode='28000'; end if;
  delete from public.fit_ia_messages_v1 where user_id=v_uid;
  delete from public.fit_ia_sessions_v1 where user_id=v_uid;
  delete from public.fit_ia_answers_v1 where user_id=v_uid;
  delete from public.fit_ia_summaries_v1 where user_id=v_uid;
  update public.fit_ia_settings_v1 set last_generation_at=null
    where user_id=v_uid;
  return true;
end;
$delete$;
revoke all on function public.fit_ia_delete_my_data_v1() from public,anon;
grant execute on function public.fit_ia_delete_my_data_v1() to authenticated;

comment on table public.fitted_ai_account_preferences_v1 is
  'Owner-only global opt-in: one choice gates all external generative AI use. No public profile sharing.';
commit;
