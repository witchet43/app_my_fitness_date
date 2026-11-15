-- Gym Shield v30: stronger reciprocal privacy constraints on the verified
-- primary gym. A preference is NOT authorization to enable matching.
-- Private per-place names and schedules NEVER leave the database.
begin;

create or replace function app_private.fitted_shield_pair_allowed_v30(
  p_a uuid,p_b uuid
) returns boolean
language sql stable security definer set search_path=''
as $$
with
  gyms as (
    select
      (select d.gym_id from app_private.dating_profiles d
        where d.user_id=p_a and d.dating_enabled) a_gym,
      (select d.gym_id from app_private.dating_profiles d
        where d.user_id=p_b and d.dating_enabled) b_gym
  ),
  modes as (
    select
      coalesce((select s.match_mode
        from app_private.fitted_shield_preferences_v28 s
        where s.user_id=p_a),'exclude_same_gym') a_mode,
      coalesce((select s.match_mode
        from app_private.fitted_shield_preferences_v28 s
        where s.user_id=p_b),'exclude_same_gym') b_mode
  )
select
  p_a is not null and p_b is not null and p_a<>p_b
  and exists(select 1 from app_private.dating_profiles d
    where d.user_id=p_a and d.dating_enabled)
  and exists(select 1 from app_private.dating_profiles d
    where d.user_id=p_b and d.dating_enabled)
  and coalesce((
    select case
      -- No verified primary gym means no justified venue safety decision.
      when g.a_gym is null or g.b_gym is null then false
      when g.a_gym<>g.b_gym then true
      -- A always excludes: never infer consent from the other member.
      when m.a_mode='exclude_same_gym'
        or m.b_mode='exclude_same_gym' then false
      -- C remains a stored preference only, pending independent safety
      -- approval. This guard must never activate same-time discovery.
      when m.a_mode='include_same_time'
        or m.b_mode='include_same_time' then false
      -- Both have to opt into B. Unknown routines are unsafe.
      when m.a_mode='different_time' and m.b_mode='different_time'
        and exists(select 1
          from app_private.fitted_training_windows_v28 w
          where w.user_id=p_a)
        and exists(select 1
          from app_private.fitted_training_windows_v28 w
          where w.user_id=p_b)
        and not exists(
          select 1 from app_private.fitted_training_windows_v28 x
          join app_private.fitted_training_windows_v28 y
            on x.weekday=y.weekday and x.window_code=y.window_code
          where x.user_id=p_a and y.user_id=p_b)
      then true
      else false
    end
    from gyms g cross join modes m
  ),false);
$$;

-- Keep legacy eligibility, blocks, age/consent and all other safeguards.
-- This additional predicate can only DENY existing candidates.
create or replace function app_private.b11_pair_allowed(p_a uuid,p_b uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select p_a is not null and p_b is not null and p_a<>p_b
   and app_private.b11_member_eligible(p_a)
   and app_private.b11_member_eligible(p_b)
   and app_private.fitted_shield_pair_allowed_v30(p_a,p_b)
   and not exists(select 1 from app_private.user_blocks b
      where (b.blocker_id=p_a and b.blocked_id=p_b)
         or (b.blocker_id=p_b and b.blocked_id=p_a))
   and not exists(select 1 from public.community_blocks_b4 b
      where (b.blocker_id=p_a and b.blocked_id=p_b)
         or (b.blocker_id=p_b and b.blocked_id=p_a));
$$;
revoke all on function app_private.fitted_shield_pair_allowed_v30(uuid,uuid)
from public,anon,authenticated;

commit;
