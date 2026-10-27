-- Trust & safety v5. Development-only; not a substitute for a staffed moderation program.
-- No public table grants for reports, hidden content, or rate counters.

create table app_private.safety_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('user','post','event')),
  target_id uuid not null,
  subject_user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (reason in ('spam','harassment','unsafe','other')),
  details text check (details is null or char_length(details) <= 500),
  status text not null default 'pending'
    check (status in ('pending','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  unique(reporter_id,target_type,target_id)
);
create index safety_reports_pending on app_private.safety_reports(created_at)
  where status = 'pending';
alter table app_private.safety_reports enable row level security;
revoke all on app_private.safety_reports from public,anon,authenticated;

create table app_private.hidden_posts (
  post_id uuid primary key references public.community_posts(id) on delete cascade,
  hidden_at timestamptz not null default now(),
  reason text not null check (char_length(btrim(reason)) between 3 and 200)
);
alter table app_private.hidden_posts enable row level security;
revoke all on app_private.hidden_posts from public,anon,authenticated;

create table app_private.dating_request_counters (
  user_id uuid not null references auth.users(id) on delete cascade,
  action text not null check (action in ('discover','settings')),
  bucket_start timestamptz not null,
  attempts integer not null check (attempts >= 0),
  primary key (user_id,action,bucket_start)
);
alter table app_private.dating_request_counters enable row level security;
revoke all on app_private.dating_request_counters from public,anon,authenticated;

-- All authorization decisions are based on auth.uid(), not user-controlled JWT metadata.
create function app_private.can_see_social_user(p_other_id uuid)
returns boolean language sql security definer set search_path = '' stable
as $$
  select (select auth.uid()) is not null
    and p_other_id is not null
    and not exists (
      select 1 from app_private.user_blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = p_other_id)
         or (b.blocker_id = p_other_id and b.blocked_id = (select auth.uid()))
    );
$$;

create function app_private.can_see_community_post(p_post_id uuid,p_author_id uuid)
returns boolean language sql security definer set search_path = '' stable
as $$
  select app_private.can_see_social_user(p_author_id)
    and not exists(select 1 from app_private.hidden_posts h where h.post_id = p_post_id);
$$;

revoke execute on function app_private.can_see_social_user(uuid) from public,anon,authenticated;
revoke execute on function app_private.can_see_community_post(uuid,uuid) from public,anon,authenticated;
grant execute on function app_private.can_see_social_user(uuid) to authenticated;
grant execute on function app_private.can_see_community_post(uuid,uuid) to authenticated;

-- Replace the former unconditional authenticated READ policies, never add an
-- OR policy that could bypass privacy filtering.
drop policy social_profiles_read_signed_in on public.social_profiles;
create policy social_profiles_read_not_blocked on public.social_profiles
 for select to authenticated using (app_private.can_see_social_user(user_id));

drop policy community_posts_read_signed_in on public.community_posts;
create policy community_posts_read_not_blocked_or_hidden on public.community_posts
 for select to authenticated using (app_private.can_see_community_post(id,author_id));

drop policy sport_events_read_signed_in on public.sport_events;
create policy sport_events_read_not_blocked on public.sport_events
 for select to authenticated using (app_private.can_see_social_user(organizer_id));

-- A report is accepted only for an existing target and never against oneself.
-- Target metadata stays in a private schema. Moderators access this table via
-- privileged Dashboard SQL (no client/admin API is granted here).
create function app_private.submit_safety_report(
  p_target_type text, p_target_id uuid, p_reason text, p_details text default null
) returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_subject uuid;
begin
  if v_actor is null then raise exception 'Sign-in required'; end if;
  if p_target_type not in ('user','post','event') or p_target_type is null
     or p_target_id is null or p_reason not in ('spam','harassment','unsafe','other')
     or p_reason is null or char_length(coalesce(p_details,'')) > 500 then
     raise exception 'Invalid report';
  end if;
  if p_target_type = 'user' then
    select id into v_subject from auth.users where id = p_target_id;
  elsif p_target_type = 'post' then
    select author_id into v_subject from public.community_posts where id = p_target_id;
  else
    select organizer_id into v_subject from public.sport_events where id = p_target_id;
  end if;
  if v_subject is null or v_actor = v_subject then
    raise exception 'Invalid report';
  end if;
  insert into app_private.safety_reports(reporter_id,target_type,target_id,subject_user_id,reason,details)
  values (v_actor,p_target_type,p_target_id,v_subject,p_reason,nullif(btrim(p_details),''))
  on conflict (reporter_id,target_type,target_id) do nothing;
  return true;
end;
$$;

create function public.submit_safety_report(
  p_target_type text, p_target_id uuid, p_reason text, p_details text default null
) returns boolean language sql security invoker set search_path = ''
as $$ select app_private.submit_safety_report(p_target_type,p_target_id,p_reason,p_details); $$;

revoke execute on function app_private.submit_safety_report(text,uuid,text,text) from public,anon,authenticated;
revoke execute on function public.submit_safety_report(text,uuid,text,text) from public,anon,authenticated;
grant execute on function app_private.submit_safety_report(text,uuid,text,text) to authenticated;
grant execute on function public.submit_safety_report(text,uuid,text,text) to authenticated;

-- Throttle repeated probes of gym/time eligibility.
-- This reduces simple enumeration; it does NOT solve Sybil attacks or all
-- inference attacks. Privacy review is still mandatory before public beta.
create function app_private.consume_dating_quota(
  p_action text, p_window_seconds integer, p_max integer
) returns void language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_bucket timestamptz;
  v_hits integer;
begin
  if v_actor is null then raise exception 'Sign-in required'; end if;
  if p_action not in ('discover','settings') or p_action is null
     or p_window_seconds < 60 or p_max < 1 then
    raise exception 'Invalid quota configuration';
  end if;
  v_bucket := to_timestamp(
    floor(extract(epoch from clock_timestamp()) / p_window_seconds) * p_window_seconds
  );
  insert into app_private.dating_request_counters(user_id,action,bucket_start,attempts)
  values(v_actor,p_action,v_bucket,1)
  on conflict(user_id,action,bucket_start)
  do update set attempts = least(app_private.dating_request_counters.attempts + 1,p_max + 1)
  returning attempts into v_hits;
  if v_hits > p_max then
    raise exception 'RATE_LIMITED' using errcode='P0001';
  end if;
end;
$$;
revoke execute on function app_private.consume_dating_quota(text,integer,integer)
  from public,anon,authenticated;
grant execute on function app_private.consume_dating_quota(text,integer,integer)
  to authenticated;

-- The previously exposed public RPCs remain the same, but use volatile
-- wrappers so a quota write is allowed. Private implementations keep their
-- original signature, authorization and return shapes.
create or replace function public.discover_dating_candidates(p_limit integer default 20)
returns table(user_id uuid,display_name text,city text,sports text[])
language plpgsql volatile security invoker set search_path = ''
as $$
begin
  perform app_private.consume_dating_quota('discover',3600,30);
  return query select * from app_private.discover_dating_candidates(p_limit);
end;
$$;

create or replace function public.save_dating_setup(
  p_display_name text,p_city text,p_sports text[],p_dob date,
  p_gym_id uuid,p_mode text,p_weekly_slots jsonb,p_dating_enabled boolean
) returns void language plpgsql volatile security invoker set search_path = ''
as $$
begin
  perform app_private.consume_dating_quota('settings',86400,12);
  perform app_private.save_dating_setup(
    p_display_name,p_city,p_sports,p_dob,p_gym_id,p_mode,p_weekly_slots,p_dating_enabled
  );
end;
$$;

-- Keep privilege boundaries explicit after CREATE OR REPLACE.
revoke execute on function public.discover_dating_candidates(integer)
 from public,anon,authenticated;
revoke execute on function public.save_dating_setup(text,text,text[],date,uuid,text,jsonb,boolean)
 from public,anon,authenticated;
grant execute on function public.discover_dating_candidates(integer) to authenticated;
grant execute on function public.save_dating_setup(text,text,text[],date,uuid,text,jsonb,boolean)
 to authenticated;
