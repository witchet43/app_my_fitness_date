-- V16. Server-side adult eligibility gate. Operator attestations are only valid
-- after an independent, external age review. No documents are uploaded to app.
-- A self-declared DOB alone must NEVER unlock romantic discovery.

create table app_private.adult_eligibility (
  user_id uuid primary key references auth.users(id) on delete cascade,
  approved_at timestamptz not null default now(),
  expires_at timestamptz not null,
  review_ref text not null check (length(btrim(review_ref)) between 12 and 120),
  revoked_at timestamptz,
  constraint eligible_interval check (expires_at>approved_at)
);
create index adult_eligibility_valid_until on app_private.adult_eligibility(expires_at)
  where revoked_at is null;
alter table app_private.adult_eligibility enable row level security;
revoke all on app_private.adult_eligibility from public,anon,authenticated;

create function app_private.adult_eligible(p_user_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
 select p_user_id is not null
 and app_private.account_is_active(p_user_id)
 and exists (
   select 1 from app_private.adult_eligibility v
   where v.user_id=p_user_id and v.revoked_at is null
     and v.approved_at<=now() and v.expires_at>now()
 );
$$;

create function app_private.my_adult_eligibility()
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare
 v_user uuid := (select auth.uid());
 v_expiry timestamptz;
 v_approved boolean := false;
begin
 if v_user is null then raise exception 'Sign-in required'; end if;
 select v.expires_at,v.revoked_at is null and v.expires_at>now()
   into v_expiry,v_approved
 from app_private.adult_eligibility v where v.user_id=v_user;
 return jsonb_build_object(
  'approved',coalesce(v_approved,false) and app_private.adult_eligible(v_user),
  'expires_at',case when coalesce(v_approved,false) then v_expiry else null end,
  'source','external_operator_review'
 );
end;
$$;

create function public.my_adult_eligibility()
returns jsonb language sql stable security invoker set search_path = ''
as $$ select app_private.my_adult_eligibility(); $$;

-- Service-role-only approval after independent age verification conducted
-- OFF-PLATFORM. A ticket/reference is opaque, never a document/ID number.
create function app_private.operator_set_adult_eligibility(
 p_user_id uuid,p_review_ref text,p_expires_at timestamptz,p_approve boolean)
returns boolean language plpgsql security definer set search_path = ''
as $$
begin
 if p_user_id is null or p_approve is null or p_review_ref is null
    or length(btrim(p_review_ref)) not between 12 and 120 then
   raise exception 'Invalid operator decision';
 end if;
 if not exists(select 1 from auth.users where id=p_user_id) then
   raise exception 'Unknown user';
 end if;
 if p_approve then
   if p_expires_at is null or p_expires_at<=now()
      or p_expires_at>now()+interval '180 days' then
     raise exception 'Invalid eligibility expiration';
   end if;
   insert into app_private.adult_eligibility
     (user_id,approved_at,expires_at,review_ref,revoked_at)
   values (p_user_id,now(),p_expires_at,btrim(p_review_ref),null)
   on conflict(user_id) do update
     set approved_at=now(),expires_at=excluded.expires_at,
       review_ref=excluded.review_ref,revoked_at=null;
 else
   update app_private.adult_eligibility set revoked_at=now(),
     review_ref=btrim(p_review_ref) where user_id=p_user_id;
   update app_private.dating_profiles set dating_enabled=false,updated_at=now()
     where user_id=p_user_id;
 end if;
 return true;
end;
$$;

create function public.operator_set_adult_eligibility(
 p_user_id uuid,p_review_ref text,p_expires_at timestamptz,p_approve boolean)
returns boolean language sql security invoker set search_path = ''
as $$
 select app_private.operator_set_adult_eligibility(
  p_user_id,p_review_ref,p_expires_at,p_approve);
$$;

-- Turn off all previous Dating consent until verified by an authorized operator.
update app_private.dating_profiles set dating_enabled=false,updated_at=now()
where not app_private.adult_eligible(user_id);

create or replace function app_private.save_dating_setup(
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
  if p_dating_enabled and not app_private.adult_eligible(v_user) then
    raise exception 'AGE_REVIEW_REQUIRED' using errcode='P0001';
  end if;
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

create or replace function app_private.discover_dating_candidates(p_limit integer default 20)
returns table (user_id uuid, display_name text, city text, sports text[])
language plpgsql security definer set search_path = '' stable
as $$
declare v_user uuid := (select auth.uid());
begin
  if v_user is null then raise exception 'Sign-in required'; end if;
  if not app_private.adult_eligible(v_user) then
    raise exception 'AGE_REVIEW_REQUIRED' using errcode='P0001';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 30 then
    raise exception 'Invalid page size';
  end if;

  return query
  select c.user_id, c.display_name, c.city, c.sports
  from app_private.dating_profiles c
  join app_private.dating_profiles me on me.user_id = v_user
  where me.dating_enabled and c.dating_enabled
    and app_private.adult_eligible(c.user_id)
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

-- Preserve existing account deletion gate and quota while lowering hourly
-- discovery requests. No exact exclusion reason is returned to callers.
create or replace function public.discover_dating_candidates(p_limit integer default 20)
returns table(user_id uuid,display_name text,city text,sports text[])
language plpgsql volatile security invoker set search_path = ''
as $$
begin
 if not app_private.account_is_active((select auth.uid())) then
  raise exception 'ACCOUNT_DELETION_PENDING' using errcode='P0001';
 end if;
 if not app_private.adult_eligible((select auth.uid())) then
  raise exception 'AGE_REVIEW_REQUIRED' using errcode='P0001';
 end if;
 if p_limit is null or p_limit not between 1 and 10 then
  raise exception 'Invalid page size';
 end if;
 perform app_private.consume_dating_quota('discover',3600,10);
 return query
 select c.user_id,c.display_name,c.city,c.sports
 from app_private.discover_dating_candidates(p_limit) c
 where app_private.account_is_active(c.user_id)
   and app_private.adult_eligible(c.user_id);
end;
$$;

revoke execute on function app_private.adult_eligible(uuid) from public,anon,authenticated;
revoke execute on function app_private.my_adult_eligibility() from public,anon,authenticated;
revoke execute on function app_private.operator_set_adult_eligibility(uuid,text,timestamptz,boolean)
 from public,anon,authenticated;
revoke execute on function public.my_adult_eligibility() from public,anon,authenticated;
revoke execute on function public.operator_set_adult_eligibility(uuid,text,timestamptz,boolean)
 from public,anon,authenticated;
grant execute on function app_private.adult_eligible(uuid) to authenticated;
grant execute on function app_private.my_adult_eligibility() to authenticated;
grant execute on function public.my_adult_eligibility() to authenticated;
grant execute on function app_private.operator_set_adult_eligibility(uuid,text,timestamptz,boolean)
 to service_role;
grant execute on function public.operator_set_adult_eligibility(uuid,text,timestamptz,boolean)
 to service_role;
