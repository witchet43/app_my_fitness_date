-- My Fitness Date B2: My Activities and safe cancellation lifecycle.
-- Run AFTER 202611120016_activity_rsvp_b1. Staging-only until QA/approval.
-- No exact gym, training schedule, personal address or attendee list is exposed.
begin;

alter table public.event_rsvps
  add column if not exists cancelled_at timestamptz;
alter table public.sport_events
  add column if not exists cancelled_at timestamptz;

create index if not exists event_rsvps_member_lifecycle_b2
  on public.event_rsvps (user_id, cancelled_at, created_at desc);

-- All mutations are RPCs. No user may directly update the reservation's
-- timestamp to resurrect an RSVP without the serialized capacity check.
revoke update, delete on public.event_rsvps from authenticated;
drop policy if exists event_rsvps_leave_own on public.event_rsvps;

create or replace function public.confirm_activity_rsvp(p_event_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_event public.sport_events%rowtype;
  v_confirmed integer;
  v_existing public.event_rsvps%rowtype;
begin
  if v_user is null or
     coalesce(auth.jwt() ->> 'is_anonymous', 'false') = 'true' then
    return 'not_authenticated';
  end if;
  if not exists (
    select 1 from auth.users u
    where u.id = v_user and u.email_confirmed_at is not null
  ) then
    return 'not_authenticated';
  end if;
  if not exists (
    select 1 from public.member_profiles_v26 p
    where p.user_id = v_user and p.onboarding_complete = true
      and p.date_of_birth <= (current_date - interval '18 years')::date
  ) then
    return 'profile_required';
  end if;
  if not exists (
    select 1 from public.member_consents_v26 c
    where c.user_id = v_user and c.consent_kind = 'terms'
      and c.document_version = 'v27-terms-1'
  ) or not exists (
    select 1 from public.member_consents_v26 c
    where c.user_id = v_user and c.consent_kind = 'privacy'
      and c.document_version = 'v27-privacy-1'
  ) then
    return 'consent_required';
  end if;

  -- One FOR UPDATE lock on the parent event serializes confirmation,
  -- capacity reads, cancellation and all concurrent member requests.
  select e.* into v_event
  from public.sport_events e
  where e.id = p_event_id for update;

  if not found or v_event.is_published is distinct from true or
     v_event.cancelled_at is not null or v_event.starts_at <= now() then
    return 'not_open';
  end if;

  select r.* into v_existing
  from public.event_rsvps r
  where r.event_id = p_event_id and r.user_id = v_user;

  if found and v_existing.cancelled_at is null then
    return 'already_confirmed';
  end if;

  select count(*)::integer into v_confirmed
  from public.event_rsvps r
  where r.event_id = p_event_id and r.cancelled_at is null;

  if v_confirmed >= v_event.capacity then
    return 'full';
  end if;

  insert into public.event_rsvps (event_id, user_id, cancelled_at)
  values (p_event_id, v_user, null)
  on conflict (event_id, user_id)
    do update set cancelled_at = null;

  return 'confirmed';
end;
$$;
revoke all on function public.confirm_activity_rsvp(uuid)
  from public, anon, authenticated;
grant execute on function public.confirm_activity_rsvp(uuid)
  to authenticated;

-- Soft cancel keeps a private audit/history. No physical deletion by members.
create or replace function public.cancel_activity_rsvp(p_event_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_event public.sport_events%rowtype;
begin
  if v_user is null or
     coalesce(auth.jwt() ->> 'is_anonymous', 'false') = 'true' then
    return 'not_authenticated';
  end if;
  select e.* into v_event
  from public.sport_events e
  where e.id = p_event_id for update;
  if not found then
    return 'not_confirmed';
  end if;
  if not exists (
    select 1 from public.event_rsvps r
    where r.event_id = p_event_id and r.user_id = v_user
  ) then
    return 'not_confirmed';
  end if;
  if exists (
    select 1 from public.event_rsvps r
    where r.event_id = p_event_id and r.user_id = v_user
      and r.cancelled_at is not null
  ) then
    return 'already_cancelled';
  end if;
  if v_event.starts_at <= now() then
    return 'already_started';
  end if;
  update public.event_rsvps r
  set cancelled_at = now()
  where r.event_id = p_event_id and r.user_id = v_user
    and r.cancelled_at is null;
  return 'cancelled';
end;
$$;
revoke all on function public.cancel_activity_rsvp(uuid)
  from public, anon, authenticated;
grant execute on function public.cancel_activity_rsvp(uuid)
  to authenticated;

-- Do NOT depend on event visibility RLS for the member's private history:
-- canceled and past events must remain visible to THEIR participant only.
create or replace function public.my_activity_reservations()
returns table (
  event_id uuid,
  title text,
  description text,
  sport text,
  city text,
  starts_at timestamptz,
  capacity integer,
  joined_at timestamptz,
  cancelled_at timestamptz,
  event_cancelled boolean
)
language sql stable security definer
set search_path = ''
as $$
  select e.id, e.title, e.description, e.sport, e.city, e.starts_at,
    e.capacity, r.created_at, r.cancelled_at,
    (e.cancelled_at is not null or e.is_published = false)
  from public.event_rsvps r
  inner join public.sport_events e on e.id = r.event_id
  where (select auth.uid()) is not null
    and coalesce(auth.jwt() ->> 'is_anonymous', 'false') <> 'true'
    and r.user_id = (select auth.uid())
  order by e.starts_at desc, r.created_at desc
  limit 100;
$$;
revoke all on function public.my_activity_reservations()
  from public, anon, authenticated;
grant execute on function public.my_activity_reservations()
  to authenticated;

-- The organizer can manage only events they own; no member identity is exposed.
create or replace function public.my_organized_activities()
returns table (
  id uuid,
  title text,
  description text,
  sport text,
  city text,
  starts_at timestamptz,
  capacity integer,
  active_reservations bigint,
  event_cancelled boolean
)
language sql stable security definer
set search_path = ''
as $$
  select e.id, e.title, e.description, e.sport, e.city, e.starts_at,
    e.capacity, (
      select count(*) from public.event_rsvps r
      where r.event_id = e.id and r.cancelled_at is null
    ), (e.cancelled_at is not null)
  from public.sport_events e
  where (select auth.uid()) is not null
    and coalesce(auth.jwt() ->> 'is_anonymous', 'false') <> 'true'
    and e.organizer_id = (select auth.uid())
    and exists (
      select 1 from app_private.event_organizers o
      where o.user_id = (select auth.uid())
    )
  order by e.starts_at desc
  limit 100;
$$;
revoke all on function public.my_organized_activities()
  from public, anon, authenticated;
grant execute on function public.my_organized_activities()
  to authenticated;

create or replace function public.cancel_organized_activity(p_event_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_event public.sport_events%rowtype;
begin
  if v_user is null or
     coalesce(auth.jwt() ->> 'is_anonymous', 'false') = 'true' then
    return 'not_authorized';
  end if;
  if not exists (
    select 1 from app_private.event_organizers o
    where o.user_id = v_user
  ) then
    return 'not_authorized';
  end if;
  select e.* into v_event
  from public.sport_events e
  where e.id = p_event_id and e.organizer_id = v_user
  for update;
  if not found then
    return 'not_authorized';
  end if;
  if v_event.cancelled_at is not null then
    return 'already_cancelled';
  end if;
  if v_event.starts_at <= now() then
    return 'already_started';
  end if;
  update public.sport_events e
  set cancelled_at = now(), is_published = false
  where e.id = p_event_id and e.organizer_id = v_user;
  return 'cancelled';
end;
$$;
revoke all on function public.cancel_organized_activity(uuid)
  from public, anon, authenticated;
grant execute on function public.cancel_organized_activity(uuid)
  to authenticated;

comment on function public.my_activity_reservations() is
  'B2: returns only requesting member reservations, including canceled/past.';
comment on function public.cancel_organized_activity(uuid) is
  'B2: owner-approved organizer can cancel its event; retains member history.';

-- The existing owner is an INDEPENDENT administrative persona, never a
-- member RSVP identity. This allows the owner to curate genuine events and
-- inspect their public appearance without forging a member profile.
create or replace function public.admin_publish_curated_activity(
  p_title text,
  p_description text,
  p_sport text,
  p_city text,
  p_starts_at timestamptz,
  p_capacity integer
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not app_private.is_brand_owner() then
    raise exception 'not authorized' using errcode = '42501';
  end if;
  if char_length(btrim(coalesce(p_title, ''))) not between 4 and 100 or
     char_length(btrim(coalesce(p_description, ''))) not between 10 and 500 or
     char_length(btrim(coalesce(p_sport, ''))) not between 2 and 40 or
     char_length(btrim(coalesce(p_city, ''))) not between 2 and 100 or
     p_capacity not between 1 and 200 or
     p_starts_at is null or
     p_starts_at <= now() + interval '10 minutes' or
     p_starts_at > now() + interval '180 days' then
    raise exception 'invalid activity' using errcode = '22023';
  end if;
  insert into public.sport_events (
    organizer_id, title, description, sport, city,
    starts_at, capacity, is_published
  ) values (
    (select auth.uid()), btrim(p_title), btrim(p_description),
    btrim(p_sport), btrim(p_city), p_starts_at, p_capacity, true
  ) returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.admin_publish_curated_activity(
  text, text, text, text, timestamptz, integer
) from public, anon, authenticated;
grant execute on function public.admin_publish_curated_activity(
  text, text, text, text, timestamptz, integer
) to authenticated;

create or replace function public.admin_curated_activities()
returns table (
  id uuid,
  title text,
  description text,
  sport text,
  city text,
  starts_at timestamptz,
  capacity integer,
  active_reservations bigint,
  event_cancelled boolean
)
language sql stable security definer
set search_path = ''
as $$
  select e.id, e.title, e.description, e.sport, e.city,
    e.starts_at, e.capacity,
    (select count(*) from public.event_rsvps r
      where r.event_id = e.id and r.cancelled_at is null),
    (e.cancelled_at is not null)
  from public.sport_events e
  where app_private.is_brand_owner()
  order by e.starts_at desc
  limit 100;
$$;
revoke all on function public.admin_curated_activities()
  from public, anon, authenticated;
grant execute on function public.admin_curated_activities()
  to authenticated;

create or replace function public.admin_cancel_curated_activity(p_event_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.sport_events%rowtype;
begin
  if not app_private.is_brand_owner() then
    return 'not_authorized';
  end if;
  select e.* into v_event from public.sport_events e
  where e.id = p_event_id for update;
  if not found then
    return 'not_found';
  end if;
  if v_event.cancelled_at is not null then
    return 'already_cancelled';
  end if;
  if v_event.starts_at <= now() then
    return 'already_started';
  end if;
  update public.sport_events e
  set cancelled_at = now(), is_published = false
  where e.id = p_event_id;
  return 'cancelled';
end;
$$;
revoke all on function public.admin_cancel_curated_activity(uuid)
  from public, anon, authenticated;
grant execute on function public.admin_cancel_curated_activity(uuid)
  to authenticated;


commit;
