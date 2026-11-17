-- Disposable isolated fixture for the account-level AI migration.
-- Real production schemas remain unchanged; this file runs only in CI.
create schema app_private;
create table public.member_profiles_v26(
  user_id uuid primary key references auth.users(id) on delete cascade
);
create table public.fit_ia_settings_v1(
  user_id uuid primary key references auth.users(id) on delete cascade,
  ai_enabled boolean not null default false,
  consented_at timestamptz,
  last_generation_at timestamptz
);
create table public.fit_ia_messages_v1(user_id uuid not null);
create table public.fit_ia_sessions_v1(user_id uuid not null);
create table public.fit_ia_answers_v1(user_id uuid not null);
create table public.fit_ia_summaries_v1(user_id uuid not null);
create table app_private.member_profile_summaries_b17(
  user_id uuid primary key references auth.users(id) on delete cascade,
  summary_es text not null default '',
  summary_en text not null default '',
  summary_mode text not null default 'manual',
  ai_consented boolean not null default false,
  ai_consented_at timestamptz,
  share_consented boolean not null default false,
  manual_summary_es text not null default '',
  manual_summary_en text not null default ''
);
create function app_private.refresh_profile_summary_b17(p_user uuid)
returns void language plpgsql security definer set search_path=''
as $fixture$begin return; end$fixture$;
