-- B1 · My Fitness Date: curated sports activities with atomic, private RSVP.
-- Staged migration only. NOT applied to the hosted production database.
-- Supersedes direct RSVP INSERT access so capacity cannot be bypassed.
-- Requires the already-deployed V26 member profile/consent schema.

begin;

-- Organizers are approved in app_private.event_organizers by an operator.
-- Do not require publishing the organizer's member profile to a social feed.
alter table public.sport_events
  drop constraint if exists sport_events_organizer_id_fkey;
alter table public.sport_events
  add constraint sport_events_organizer_id_fkey
  foreign key (organizer_id) references auth.users(id) on delete cascade;

alter table public.sport_events
  add column if not exists capacity integer not null default 24,
  add column if not exists is_published boolean not null default false;
alter table public.sport_events
  add constraint sport_events_capacity_valid check (capacity between 1 and 200);
create index if not exists sport_events_public_upcoming_b1
  on public.sport_events(starts_at, id)
  where is_published = true;

-- Only curated/published FUTURE events can be discovered by a member.
drop policy if exists sport_events_read_signed_in on public.sport_events;
create policy sport_events_curated_upcoming_b1
  on public.sport_events for select to authenticated
  using (is_published = true and starts_at > now());

-- Approved organizer may create a complete, published activity. The approval
-- record is private and cannot be forged through user_metadata.
revoke insert on public.sport_events from authenticated;
grant insert (organizer_id, title, description, sport, city, starts_at,
  capacity, is_published) on public.sport_events to authenticated;
drop policy if exists sport_events_approved_organizer on public.sport_events;
create policy sport_events_approved_organizer_b1
  on public.sport_events for insert to authenticated
  with check (
    (select auth.uid()) = organizer_id
    and app_private.is_event_organizer()
    and starts_at > now() + interval '10 minutes'
    and starts_at <= now() + interval '180 days'
    and is_published = true
    and exists (
      select 1 from public.member_profiles_v26 p
      where p.user_id = (select auth.uid())
        and p.onboarding_complete = true
        and p.date_of_birth <= (current_date - interval '18 years')::date
    )
  );

-- Do not permit a direct Data API INSERT that would bypass a capacity check.
drop policy if exists event_rsvps_join_future_event on public.event_rsvps;
revoke insert on public.event_rsvps from authenticated;
revoke insert (event_id, user_id) on public.event_rsvps
  from authenticated;

-- Consent versions follow the currently deployed v27 legal documents.\n-- Updating legal versions requires a reviewed DB/API change: fail closed.\n\n-- Explicitly granted owner-only RPC. SECURITY DEFINER is necessary for
-- counting participants across RLS rows, and is tightly limited by auth.uid,
-- a verified non-anonymous user, membership eligibility and one event lock.
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
begin
  if v_user is null or coalesce(auth.jwt() ->> 'is_anonymous', 'false') = 'true' then
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
    where p.user_id = v_user
      and p.onboarding_complete = true
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

  -- SERIALIZE all confirmations for the same event. Check capacity and insert
  -- in one transaction. Independent reservations cannot overbook the event.
  select e.* into v_event from public.sport_events e
    where e.id = p_event_id for update;
  if not found or v_event.is_published is distinct from true
     or v_event.starts_at <= now() then
    return 'not_open';
  end if;
  if exists (
    select 1 from public.event_rsvps r
    where r.event_id = p_event_id and r.user_id = v_user
  ) then
    return 'already_confirmed';
  end if;
  select count(*)::integer into v_confirmed from public.event_rsvps r
    where r.event_id = p_event_id;
  if v_confirmed >= v_event.capacity then
    return 'full';
  end if;
  insert into public.event_rsvps (event_id, user_id)
    values (p_event_id, v_user)
    on conflict (event_id, user_id) do nothing;
  return 'confirmed';
end;
$$;
revoke all on function public.confirm_activity_rsvp(uuid)
  from public, anon, authenticated;
grant execute on function public.confirm_activity_rsvp(uuid)
  to authenticated;

-- Status is boolean, never an exposed list of privileged organizers.
create or replace function public.my_activity_organizer_status()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and coalesce(auth.jwt() ->> 'is_anonymous', 'false') <> 'true'
    and exists (
      select 1 from app_private.event_organizers o
      where o.user_id = (select auth.uid())
    );
$$;
revoke all on function public.my_activity_organizer_status()
  from public, anon, authenticated;
grant execute on function public.my_activity_organizer_status()
  to authenticated;

comment on function public.confirm_activity_rsvp(uuid) is
  'B1: locked, idempotent private RSVP; never reveals other participants.';

commit;
