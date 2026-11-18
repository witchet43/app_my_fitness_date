-- my_fitness_date: first private dating backend.
-- Only public RPC wrappers are exposed through the Data API.
-- All private functions use explicit auth.uid() scope and empty search_path.
create extension if not exists pgcrypto with schema extensions;
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;
grant usage on schema app_private to authenticated;

create table public.gyms (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 3 and 120),
  city text not null check (length(btrim(city)) between 2 and 100)
);
alter table public.gyms enable row level security;
revoke all on public.gyms from anon, authenticated;
grant select on public.gyms to authenticated;
create policy gyms_catalog_authenticated on public.gyms for select to authenticated using (true);

-- These are synthetic, non-commercial names only, for integration testing.
insert into public.gyms (id, name, city) values
('00000000-0000-4000-8000-000000000001','Gym Demo Norte','Querétaro'),
('00000000-0000-4000-8000-000000000002','Gym Demo Centro','Querétaro'),
('00000000-0000-4000-8000-000000000003','Gym Demo Sur','Querétaro');

create table app_private.dating_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (length(btrim(display_name)) between 2 and 60),
  city text not null check (length(btrim(city)) between 2 and 100),
  sports text[] not null default '{}'::text[],
  date_of_birth date not null,
  gym_id uuid not null references public.gyms(id),
  mode text not null check (mode in ('other_gyms','same_gym_other_time')),
  dating_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);
create index dating_active_gym on app_private.dating_profiles (gym_id, updated_at desc)
where dating_enabled;

create table app_private.training_slots (
  user_id uuid not null references app_private.dating_profiles(user_id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6),
  start_minute smallint not null check (start_minute between 0 and 1439),
  end_minute smallint not null check (end_minute between 1 and 1440),
  constraint valid_interval check (start_minute < end_minute),
  primary key (user_id, weekday, start_minute, end_minute)
);
create index training_slots_user_day on app_private.training_slots (user_id, weekday);

create table app_private.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  primary key (blocker_id, blocked_id),
  constraint no_self_block check (blocker_id <> blocked_id)
);
create index user_blocks_reverse on app_private.user_blocks (blocked_id, blocker_id);

-- No direct user access to private tables, even to their own rows. Use restricted RPCs.
alter table app_private.dating_profiles enable row level security;
alter table app_private.training_slots enable row level security;
alter table app_private.user_blocks enable row level security;
revoke all on all tables in schema app_private from public, anon, authenticated;
revoke all on all sequences in schema app_private from public, anon, authenticated;

-- SECURITY DEFINER stays in NON-exposed app_private; public wrapper is INVOKER.
create function app_private.save_dating_setup(
  p_display_name text, p_city text, p_sports text[], p_dob date,
  p_gym_id uuid, p_mode text, p_weekly_slots jsonb,
  p_dating_enabled boolean
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_slot jsonb;
  v_day int;
  v_start int;
  v_end int;
begin
  if v_user is null then raise exception 'Sign-in required'; end if;
  if p_dob is null or p_dob > (current_date - interval '18 years')::date
     or p_dob < date '1900-01-01' then
    raise exception 'Adult eligibility not satisfied';
  end if;
  if p_gym_id is null or not exists (select 1 from public.gyms where id = p_gym_id) then
    raise exception 'Unknown gym';
  end if;
  if p_mode is null or p_mode not in ('other_gyms','same_gym_other_time') then
    raise exception 'Invalid privacy mode';
  end if;
  if p_display_name is null or length(btrim(p_display_name)) not between 2 and 60
     or p_city is null or length(btrim(p_city)) not between 2 and 100 then
    raise exception 'Invalid profile';
  end if;
  if p_sports is null or cardinality(p_sports) > 10 then
    raise exception 'Invalid sports';
  end if;
  if exists (select 1 from unnest(p_sports) s where s is null or length(btrim(s)) not between 2 and 40) then
    raise exception 'Invalid sport label';
  end if;
  if p_weekly_slots is null or jsonb_typeof(p_weekly_slots) <> 'array'
     or jsonb_array_length(p_weekly_slots) > 14 then
    raise exception 'Invalid weekly slots';
  end if;
  if p_dating_enabled is null then
    raise exception 'Missing dating consent';
  end if;
  if p_dating_enabled and p_mode = 'same_gym_other_time'
     and jsonb_array_length(p_weekly_slots) = 0 then
    raise exception 'A schedule is required for this mode';
  end if;

  -- Validate every slot BEFORE modifying current settings.
  for v_slot in select value from jsonb_array_elements(p_weekly_slots)
  loop
    if jsonb_typeof(v_slot) <> 'object'
       or not (v_slot ? 'day' and v_slot ? 'startMinutes' and v_slot ? 'endMinutes')
       or (v_slot->>'day') !~ '^[0-6]$'
       or (v_slot->>'startMinutes') !~ '^[0-9]{1,4}$'
       or (v_slot->>'endMinutes') !~ '^[0-9]{1,4}$' then
      raise exception 'Invalid weekly slot';
    end if;
    v_day := (v_slot->>'day')::integer;
    v_start := (v_slot->>'startMinutes')::integer;
    v_end := (v_slot->>'endMinutes')::integer;
    if v_start < 0 or v_start >= v_end or v_end > 1440 then
      raise exception 'Invalid slot interval';
    end if;
  end loop;

  insert into app_private.dating_profiles
    (user_id, display_name, city, sports, date_of_birth, gym_id, mode, dating_enabled, updated_at)
  values (v_user, btrim(p_display_name), btrim(p_city), p_sports, p_dob, p_gym_id, p_mode, p_dating_enabled, now())
  on conflict (user_id) do update set
    display_name = excluded.display_name, city = excluded.city,
    sports = excluded.sports, date_of_birth = excluded.date_of_birth,
    gym_id = excluded.gym_id, mode = excluded.mode,
    dating_enabled = excluded.dating_enabled, updated_at = now();

  delete from app_private.training_slots where user_id = v_user;
  insert into app_private.training_slots (user_id, weekday, start_minute, end_minute)
  select distinct v_user, (s.value->>'day')::smallint,
    (s.value->>'startMinutes')::smallint, (s.value->>'endMinutes')::smallint
  from jsonb_array_elements(p_weekly_slots) as s(value);
end;
$$;

create function app_private.my_dating_setup()
returns table (display_name text, city text, sports text[], gym_id uuid, mode text,
  dating_enabled boolean, weekly_slots jsonb)
language sql security definer set search_path = '' stable
as $$
  select d.display_name, d.city, d.sports, d.gym_id, d.mode, d.dating_enabled,
    coalesce(
      (select jsonb_agg(jsonb_build_object('day',t.weekday,'startMinutes',t.start_minute,
        'endMinutes',t.end_minute) order by t.weekday,t.start_minute)
       from app_private.training_slots t where t.user_id = d.user_id),
      '[]'::jsonb)
  from app_private.dating_profiles d where d.user_id = (select auth.uid());
$$;

create function app_private.disable_dating()
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if (select auth.uid()) is null then raise exception 'Sign-in required'; end if;
  update app_private.dating_profiles set dating_enabled = false, updated_at = now()
  where user_id = (select auth.uid());
end;
$$;

create function app_private.block_user(p_blocked_user_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_user uuid := (select auth.uid());
begin
  if v_user is null then raise exception 'Sign-in required'; end if;
  if p_blocked_user_id is null or p_blocked_user_id = v_user then
    raise exception 'Invalid account';
  end if;
  insert into app_private.user_blocks(blocker_id, blocked_id)
  values (v_user, p_blocked_user_id) on conflict do nothing;
end;
$$;

create function app_private.discover_dating_candidates(p_limit integer default 20)
returns table (user_id uuid, display_name text, city text, sports text[])
language plpgsql security definer set search_path = '' stable
as $$
declare v_user uuid := (select auth.uid());
begin
  if v_user is null then raise exception 'Sign-in required'; end if;
  if p_limit is null or p_limit < 1 or p_limit > 30 then
    raise exception 'Invalid page size';
  end if;

  return query
  select c.user_id, c.display_name, c.city, c.sports
  from app_private.dating_profiles c
  join app_private.dating_profiles me on me.user_id = v_user
  where me.dating_enabled and c.dating_enabled
    and c.user_id <> v_user
    and not exists (
      select 1 from app_private.user_blocks b
      where (b.blocker_id = v_user and b.blocked_id = c.user_id)
         or (b.blocker_id = c.user_id and b.blocked_id = v_user)
    )
    and (
      c.gym_id <> me.gym_id
      or (
        me.mode = 'same_gym_other_time'
        and c.mode = 'same_gym_other_time'
        and exists (select 1 from app_private.training_slots t where t.user_id = v_user)
        and exists (select 1 from app_private.training_slots t where t.user_id = c.user_id)
        and not exists (
          select 1 from app_private.training_slots a
          join app_private.training_slots b
            on a.weekday = b.weekday
           and b.user_id = c.user_id
          where a.user_id = v_user
            and a.start_minute < b.end_minute + 30
            and b.start_minute < a.end_minute + 30
        )
      )
    )
  order by c.updated_at desc, c.user_id
  limit p_limit;
end;
$$;

-- Public API endpoints are SECURITY INVOKER, forwarding only authenticated user's calls.
create function public.save_dating_setup(
  p_display_name text, p_city text, p_sports text[], p_dob date,
  p_gym_id uuid, p_mode text, p_weekly_slots jsonb,
  p_dating_enabled boolean
) returns void language sql security invoker set search_path = ''
as $$
  select app_private.save_dating_setup(p_display_name,p_city,p_sports,p_dob,
    p_gym_id,p_mode,p_weekly_slots,p_dating_enabled);
$$;

create function public.my_dating_setup()
returns table(display_name text, city text, sports text[], gym_id uuid, mode text,
  dating_enabled boolean, weekly_slots jsonb)
language sql security invoker set search_path = '' stable
as $$ select * from app_private.my_dating_setup(); $$;

create function public.disable_dating()
returns void language sql security invoker set search_path = ''
as $$ select app_private.disable_dating(); $$;

create function public.block_user(p_blocked_user_id uuid)
returns void language sql security invoker set search_path = ''
as $$ select app_private.block_user(p_blocked_user_id); $$;

create function public.discover_dating_candidates(p_limit integer default 20)
returns table(user_id uuid, display_name text, city text, sports text[])
language sql security invoker set search_path = '' stable
as $$ select * from app_private.discover_dating_candidates(p_limit); $$;

-- Explicitly revoke function defaults, including on PRIVATE impl functions.
revoke execute on all functions in schema app_private from public, anon, authenticated;
revoke execute on function public.save_dating_setup(text,text,text[],date,uuid,text,jsonb,boolean) from public, anon, authenticated;
revoke execute on function public.my_dating_setup() from public, anon, authenticated;
revoke execute on function public.disable_dating() from public, anon, authenticated;
revoke execute on function public.block_user(uuid) from public, anon, authenticated;
revoke execute on function public.discover_dating_candidates(integer) from public, anon, authenticated;
grant execute on all functions in schema app_private to authenticated;
grant execute on function public.save_dating_setup(text,text,text[],date,uuid,text,jsonb,boolean) to authenticated;
grant execute on function public.my_dating_setup() to authenticated;
grant execute on function public.disable_dating() to authenticated;
grant execute on function public.block_user(uuid) to authenticated;
grant execute on function public.discover_dating_candidates(integer) to authenticated;
