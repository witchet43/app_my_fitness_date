-- FITTED B12: Pulso Real / private, two-sided post-meeting signals.
-- No public accusation / "lie score". No automated disclosure to other members.
-- PostgreSQL functions remain fail-closed while FitDating release gate is closed.
begin;

create table if not exists app_private.fitted_meetups_b12 (
  match_id uuid not null references app_private.fitdating_matches_b11(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  confirmed_at timestamptz not null default now(),
  primary key(match_id,user_id)
);
alter table app_private.fitted_meetups_b12 enable row level security;
revoke all on app_private.fitted_meetups_b12 from public,anon,authenticated;

create table if not exists app_private.fitted_signals_b12 (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references app_private.fitdating_matches_b11(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid not null references auth.users(id) on delete cascade,
  dimension text not null check(dimension in ('move','live','relate')),
  observation text not null check(observation in ('aligned','unclear','not_aligned')),
  moderation_state text not null default 'pending' check(
    moderation_state in ('pending','approved','rejected','appealed','removed')),
  created_at timestamptz not null default now(),
  unique(match_id,author_id,dimension),
  check(author_id<>subject_id)
);
create index if not exists fitted_signals_review_b12
  on app_private.fitted_signals_b12(moderation_state,created_at);
alter table app_private.fitted_signals_b12 enable row level security;
revoke all on app_private.fitted_signals_b12 from public,anon,authenticated;

-- Separate opt-in for post-date reputation processing; either participant can
-- revoke it and erase their own or about-them observations.
create table if not exists app_private.fitted_pulse_consents_b12 (
  user_id uuid primary key references auth.users(id) on delete cascade,
  accepted_at timestamptz not null default now(),
  document_version text not null default 'pulso-real-v1'
);
alter table app_private.fitted_pulse_consents_b12 enable row level security;
revoke all on app_private.fitted_pulse_consents_b12 from public,anon,authenticated;

create or replace function public.fitted_consent_b12(p_accept boolean)
returns text language plpgsql security definer set search_path=''
as $
declare me uuid:=auth.uid();
begin
  if me is null or p_accept is null then return 'not_available'; end if;
  if p_accept then
    if not app_private.b11_member_eligible(me) then return 'not_available'; end if;
    insert into app_private.fitted_pulse_consents_b12(user_id)
      values(me) on conflict(user_id) do update set accepted_at=now();
    return 'accepted';
  end if;
  delete from app_private.fitted_pulse_consents_b12 where user_id=me;
  delete from app_private.fitted_signals_b12 where author_id=me or subject_id=me;
  delete from app_private.fitted_meetups_b12 where user_id=me;
  return 'withdrawn';
end;
$;

-- Callers never supply the target identity: derive it from server-side match.
create or replace function public.fitted_confirm_meetup_b12(p_match uuid)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); a uuid; b uuid; match_at timestamptz;
begin
  if me is null or p_match is null then return 'not_available'; end if;
  select m.low_user,m.high_user,m.created_at into a,b,match_at
    from app_private.fitdating_matches_b11 m where m.id=p_match;
  if a is null or me not in (a,b)
    or not app_private.b11_pair_allowed(a,b)
    or match_at<=app_private.b11_pair_epoch(a,b) then
    return 'not_available';
  end if;
  if not exists(select 1 from app_private.fitted_pulse_consents_b12
      where user_id=me) then return 'consent_required'; end if;
  insert into app_private.fitted_meetups_b12(match_id,user_id)
    values(p_match,me) on conflict do nothing;
  if (select count(*) from app_private.fitted_meetups_b12
      where match_id=p_match)=2 then return 'both_confirmed'; end if;
  return 'waiting_other';
end;
$$;

create or replace function public.fitted_signal_status_b12(p_match uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); a uuid; b uuid; match_at timestamptz;
begin
  if me is null or p_match is null then return '{"available":false}'::jsonb; end if;
  select m.low_user,m.high_user,m.created_at into a,b,match_at
    from app_private.fitdating_matches_b11 m where m.id=p_match;
  if a is null or me not in (a,b)
    or not app_private.b11_pair_allowed(a,b)
    or match_at<=app_private.b11_pair_epoch(a,b)
  then return '{"available":false}'::jsonb; end if;
  return jsonb_build_object(
    'available',true,
    'my_confirmation',exists(select 1 from app_private.fitted_meetups_b12
      where match_id=p_match and user_id=me),
    'both_confirmed',(select count(*)=2 from app_private.fitted_meetups_b12
      where match_id=p_match),
    'my_observations',(select count(*) from app_private.fitted_signals_b12
      where match_id=p_match and author_id=me),
    'my_consent',exists(select 1 from app_private.fitted_pulse_consents_b12
      where user_id=me),
    'both_consented',(select count(*)=2 from app_private.fitted_pulse_consents_b12
      where user_id in (a,b)),
    'public_visible',false
  );
end;
$$;

create or replace function public.fitted_submit_signal_b12(
  p_match uuid,p_dimension text,p_observation text)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); a uuid; b uuid; match_at timestamptz;
  other_id uuid;
begin
  if me is null or p_match is null
    or p_dimension not in ('move','live','relate')
    or p_observation not in ('aligned','unclear','not_aligned')
  then return 'invalid'; end if;
  select m.low_user,m.high_user,m.created_at into a,b,match_at
    from app_private.fitdating_matches_b11 m where m.id=p_match;
  if a is null or me not in (a,b)
    or not app_private.b11_pair_allowed(a,b)
    or match_at<=app_private.b11_pair_epoch(a,b)
  then return 'not_available'; end if;
  if (select count(*) from app_private.fitted_pulse_consents_b12
      where user_id in(a,b))<>2 then return 'consent_required'; end if;
  if (select count(*) from app_private.fitted_meetups_b12
      where match_id=p_match)<>2 then return 'meeting_not_confirmed'; end if;
  other_id:=case when me=a then b else a end;
  insert into app_private.fitted_signals_b12(
    match_id,author_id,subject_id,dimension,observation)
  values(p_match,me,other_id,p_dimension,p_observation)
  on conflict(match_id,author_id,dimension) do nothing;
  if not found then return 'already_submitted'; end if;
  return 'pending_moderation';
end;
$$;

revoke all on function public.fitted_consent_b12(boolean),
 public.fitted_confirm_meetup_b12(uuid),
 public.fitted_signal_status_b12(uuid),
 public.fitted_submit_signal_b12(uuid,text,text)
 from public,anon,authenticated;
grant execute on function public.fitted_consent_b12(boolean),
 public.fitted_confirm_meetup_b12(uuid),
 public.fitted_signal_status_b12(uuid),
 public.fitted_submit_signal_b12(uuid,text,text) to authenticated;
comment on table app_private.fitted_signals_b12 is
 'Owner-submitted subjective post-meeting feedback. Never make public without independent review, consent and appeal procedures.';
commit;
