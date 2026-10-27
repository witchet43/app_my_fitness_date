-- my_fitness_date v4: social community and curated sports events.
-- Intentionally independent from private dating profiles and Gym Shield.
-- Private gym/time/romantic attributes NEVER belong in these tables.

create table public.social_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 2 and 60),
  city text not null check (char_length(btrim(city)) between 2 and 100),
  sports text[] not null default '{}'::text[]
    check (cardinality(sports) <= 10),
  created_at timestamptz not null default now()
);
alter table public.social_profiles enable row level security;
revoke all on public.social_profiles from public, anon, authenticated;
grant select on public.social_profiles to authenticated;
grant insert (user_id, display_name, city, sports) on public.social_profiles to authenticated;
grant update (display_name, city, sports) on public.social_profiles to authenticated;

create policy social_profiles_read_signed_in on public.social_profiles
  for select to authenticated using (true);
create policy social_profiles_create_own on public.social_profiles
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy social_profiles_edit_own on public.social_profiles
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create table public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.social_profiles(user_id) on delete cascade,
  sport text not null check (char_length(btrim(sport)) between 2 and 40),
  body text not null check (char_length(btrim(body)) between 4 and 500),
  created_at timestamptz not null default now()
);
create index community_posts_recent on public.community_posts (created_at desc);
alter table public.community_posts enable row level security;
revoke all on public.community_posts from public, anon, authenticated;
grant select, delete on public.community_posts to authenticated;
grant insert (author_id, sport, body) on public.community_posts to authenticated;

create policy community_posts_read_signed_in on public.community_posts
  for select to authenticated using (true);
create policy community_posts_create_own on public.community_posts
  for insert to authenticated with check ((select auth.uid()) = author_id);
create policy community_posts_delete_own on public.community_posts
  for delete to authenticated using ((select auth.uid()) = author_id);

-- Organizers are approved only via privileged administration, never user metadata.
create table app_private.event_organizers (
  user_id uuid primary key references auth.users(id) on delete cascade,
  approved_at timestamptz not null default now()
);
alter table app_private.event_organizers enable row level security;
revoke all on app_private.event_organizers from public, anon, authenticated;

-- This non-exposed, read-only helper is used by RLS on sport_events.
create function app_private.is_event_organizer()
returns boolean language sql security definer set search_path = '' stable
as $$
  select (select auth.uid()) is not null
    and exists(select 1 from app_private.event_organizers
      where user_id = (select auth.uid()));
$$;
revoke execute on function app_private.is_event_organizer() from public, anon, authenticated;
grant execute on function app_private.is_event_organizer() to authenticated;

create table public.sport_events (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.social_profiles(user_id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 4 and 100),
  description text not null check (char_length(btrim(description)) between 10 and 500),
  sport text not null check (char_length(btrim(sport)) between 2 and 40),
  city text not null check (char_length(btrim(city)) between 2 and 100),
  starts_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index sport_events_upcoming on public.sport_events (starts_at);
alter table public.sport_events enable row level security;
revoke all on public.sport_events from public, anon, authenticated;
grant select on public.sport_events to authenticated;
grant insert (organizer_id,title,description,sport,city,starts_at)
  on public.sport_events to authenticated;

create policy sport_events_read_signed_in on public.sport_events
  for select to authenticated using (true);
create policy sport_events_approved_organizer on public.sport_events
  for insert to authenticated
  with check (
    (select auth.uid()) = organizer_id
    and app_private.is_event_organizer()
    and starts_at > now()
  );

create table public.event_rsvps (
  event_id uuid not null references public.sport_events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(event_id,user_id)
);
create index event_rsvps_user on public.event_rsvps (user_id);
alter table public.event_rsvps enable row level security;
revoke all on public.event_rsvps from public, anon, authenticated;
grant select, delete on public.event_rsvps to authenticated;
grant insert (event_id,user_id) on public.event_rsvps to authenticated;

create policy event_rsvps_own_read on public.event_rsvps
  for select to authenticated using ((select auth.uid()) = user_id);
create policy event_rsvps_join_future_event on public.event_rsvps
  for insert to authenticated with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.sport_events e
      where e.id = event_id and e.starts_at > now()
    )
  );
create policy event_rsvps_leave_own on public.event_rsvps
  for delete to authenticated using ((select auth.uid()) = user_id);

-- No direct access to app_private.dating_profiles, training_slots,
-- user_blocks or the organizer approval list is added by this migration.
