-- B4 additive consent withdrawal (after executed 019 migration).
-- Historical migration 019 remains immutable. Existing posts stay removed.
begin;

-- A community opt-out is independent of the irreversible account deletion request.
create table if not exists app_private.community_participation_b4 (
  user_id uuid primary key references auth.users(id) on delete cascade,
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table app_private.community_participation_b4 enable row level security;
revoke all on app_private.community_participation_b4
  from public,anon,authenticated;

create or replace function app_private.community_actor_b4()
returns text language plpgsql stable security definer set search_path=''
as $$
declare v_user uuid := (select auth.uid());
begin
  if v_user is null or coalesce(auth.jwt()->>'is_anonymous','false')='true' then
    return 'not_authenticated';
  end if;
  if not exists (
    select 1 from auth.users u where u.id=v_user
      and u.email_confirmed_at is not null
  ) then return 'not_authenticated'; end if;
  if exists (
    select 1 from app_private.brand_administrators a
      where a.user_id=v_user and a.active=true
  ) then return 'admin_separate'; end if;
  if exists (
    select 1 from app_private.community_deletion_requests_b4 d
      where d.user_id=v_user
  ) then return 'deletion_pending'; end if;
  if exists (
    select 1 from app_private.community_suspensions_b4 s
      where s.user_id=v_user and s.active=true
  ) then return 'suspended'; end if;
  if exists (
    select 1 from app_private.community_participation_b4 x
      where x.user_id=v_user and x.enabled=false
  ) then return 'opted_out'; end if;
  if not exists (
    select 1 from public.member_profiles_v26 p
    where p.user_id=v_user and p.onboarding_complete=true
      and p.date_of_birth <= (current_date - interval '18 years')::date
  ) then return 'profile_required'; end if;
  if not exists (
    select 1 from public.member_consents_v26 c
    where c.user_id=v_user and c.consent_kind='terms'
      and c.document_version='v27-terms-1'
  ) or not exists (
    select 1 from public.member_consents_v26 c
    where c.user_id=v_user and c.consent_kind='privacy'
      and c.document_version='v27-privacy-1'
  ) then return 'legal_required'; end if;
  if not exists (
    select 1 from public.member_consents_v26 c
    where c.user_id=v_user and c.consent_kind='community'
      and c.document_version='community-v1'
  ) then return 'consent_required'; end if;
  return 'available';
end;
$$;
revoke all on function app_private.community_actor_b4()
  from public,anon,authenticated;

-- Paginated feed returns ONLY opted-in author name, topic and post; never
-- birthday/email/gym/attendee list. Either side's block excludes content.
create or replace function public.community_feed_b4(
  p_before timestamptz default null,p_limit integer default 15
)
returns table (
  id uuid,author_id uuid,author_name text,topic text,
  content text,created_at timestamptz,is_mine boolean,is_official boolean
)
language sql stable security definer set search_path=''
as $$
  select p.id,p.author_id,
    coalesce(m.display_name,'Equipo My Fitness Date'),p.topic,p.content,
    p.created_at,(p.author_id=(select auth.uid())) as is_mine,
    (a.user_id is not null) as is_official
  from public.community_posts_b4 p
    left join public.member_profiles_v26 m on m.user_id=p.author_id
    left join app_private.brand_administrators a
      on a.user_id=p.author_id and a.active=true
  where app_private.community_actor_b4()='available'
    and (m.user_id is not null or a.user_id is not null)
    and p.status='visible'
    and (p_before is null or p.created_at<p_before)
    and not exists (
      select 1 from public.community_blocks_b4 b
      where (b.blocker_id=(select auth.uid()) and b.blocked_id=p.author_id)
         or (b.blocked_id=(select auth.uid()) and b.blocker_id=p.author_id)
    )
    and not exists (
      select 1 from app_private.community_suspensions_b4 s
      where s.user_id=p.author_id and s.active=true
    )
    and not exists (
      select 1 from app_private.community_deletion_requests_b4 d
      where d.user_id=p.author_id
    )
    and not exists (
      select 1 from app_private.community_participation_b4 x
      where x.user_id=p.author_id and x.enabled=false
    )
  order by p.created_at desc,p.id desc
  limit least(greatest(coalesce(p_limit,15),1),20);
$$;
revoke all on function public.community_feed_b4(timestamptz,integer)
  from public,anon,authenticated;
grant execute on function public.community_feed_b4(timestamptz,integer)
  to authenticated;

-- Withdraw social participation without deleting the entire account.
-- Older public posts stay removed even if the user opts in again.
create function public.community_set_participation_b4(p_enabled boolean)
returns text language plpgsql security definer set search_path=''
as $$
declare v_user uuid:=(select auth.uid());
begin
  if v_user is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
    then return 'not_authenticated'; end if;
  if p_enabled is null then return 'invalid'; end if;
  if exists(select 1 from app_private.brand_administrators a
      where a.user_id=v_user and a.active=true)
    then return 'forbidden'; end if;
  if exists(select 1 from app_private.community_deletion_requests_b4 d
      where d.user_id=v_user)
    then return 'deletion_pending'; end if;
  if p_enabled then
    if not exists (
      select 1 from public.member_profiles_v26 p
      where p.user_id=v_user and p.onboarding_complete=true
        and p.date_of_birth <= (current_date - interval '18 years')::date
    ) or not exists (
      select 1 from public.member_consents_v26 c
      where c.user_id=v_user and c.consent_kind='community'
        and c.document_version='community-v1'
    ) or not exists (
      select 1 from public.member_consents_v26 c
      where c.user_id=v_user and c.consent_kind='terms'
        and c.document_version='v27-terms-1'
    ) or not exists (
      select 1 from public.member_consents_v26 c
      where c.user_id=v_user and c.consent_kind='privacy'
        and c.document_version='v27-privacy-1'
    ) then return 'consent_required'; end if;
  end if;
  insert into app_private.community_participation_b4(
    user_id,enabled,updated_at
  ) values(v_user,p_enabled,now())
    on conflict(user_id) do update
      set enabled=excluded.enabled,updated_at=excluded.updated_at;
  if not p_enabled then
    update public.community_posts_b4 p
      set status='removed',updated_at=now()
      where p.author_id=v_user and p.status='visible';
  end if;
  return case when p_enabled then 'enabled' else 'disabled' end;
end;
$$;
revoke all on function public.community_set_participation_b4(boolean)
  from public,anon,authenticated;
grant execute on function public.community_set_participation_b4(boolean)
  to authenticated;

commit;
