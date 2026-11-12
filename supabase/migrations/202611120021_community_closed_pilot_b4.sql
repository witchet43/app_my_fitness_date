-- B4 safety gate: owner-MFA-controlled closed pilot enrollment.
begin;

create table app_private.community_pilot_b4 (
  user_id uuid primary key references auth.users(id) on delete cascade,
  active boolean not null default true,
  admitted_by uuid not null references auth.users(id),
  admitted_at timestamptz not null default now(),
  revoked_at timestamptz
);
alter table app_private.community_pilot_b4 enable row level security;
revoke all on app_private.community_pilot_b4 from public,anon,authenticated;

create table app_private.community_pilot_audit_b4 (
  id bigint generated always as identity primary key,
  subject_id uuid not null references auth.users(id),
  administrator_id uuid not null references auth.users(id),
  action text not null check(action in ('admit','revoke')),
  recorded_at timestamptz not null default now()
);
alter table app_private.community_pilot_audit_b4 enable row level security;
revoke all on app_private.community_pilot_audit_b4 from public,anon,authenticated;

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
    select 1 from app_private.community_pilot_b4 x
      where x.user_id=v_user and x.active=true
  ) then return 'pilot_closed'; end if;
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
    and exists (
      select 1 from app_private.community_pilot_b4 allowed
      where allowed.user_id=p.author_id and allowed.active=true
    )
  order by p.created_at desc,p.id desc
  limit least(greatest(coalesce(p_limit,15),1),20);
$$;
revoke all on function public.community_feed_b4(timestamptz,integer)
  from public,anon,authenticated;
grant execute on function public.community_feed_b4(timestamptz,integer)
  to authenticated;

create or replace function public.community_set_participation_b4(p_enabled boolean)
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
      select 1 from app_private.community_pilot_b4 allowed
      where allowed.user_id=v_user and allowed.active=true
    ) then return 'pilot_closed'; end if;
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


create function public.admin_community_pilot_members_b4()
returns table (
  user_id uuid,email text,display_name text,
  active boolean,admitted_at timestamptz
)
language sql stable security definer set search_path=''
as $$
  select a.user_id,u.email,p.display_name,a.active,a.admitted_at
  from app_private.community_pilot_b4 a
  join auth.users u on u.id=a.user_id
  left join public.member_profiles_v26 p on p.user_id=a.user_id
  where app_private.is_brand_owner()
  order by a.admitted_at desc limit 100;
$$;
revoke all on function public.admin_community_pilot_members_b4()
  from public,anon,authenticated;
grant execute on function public.admin_community_pilot_members_b4()
  to authenticated;

create function public.admin_community_admit_pilot_b4(p_email text)
returns text language plpgsql security definer set search_path=''
as $$
declare v_user uuid;
begin
  if not app_private.is_brand_owner() then return 'forbidden'; end if;
  if p_email is null or char_length(btrim(p_email)) not between 5 and 254
     or p_email !~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'
    then return 'invalid'; end if;
  select u.id into v_user from auth.users u
    where lower(u.email)=lower(btrim(p_email))
      and u.email_confirmed_at is not null
    limit 1;
  if v_user is null or exists (
    select 1 from app_private.brand_administrators a
    where a.user_id=v_user and a.active=true
  ) then return 'not_found'; end if;
  insert into app_private.community_pilot_b4(
    user_id,active,admitted_by
  ) values(v_user,true,(select auth.uid()))
  on conflict(user_id) do update set
    active=true,admitted_by=excluded.admitted_by,
    admitted_at=now(),revoked_at=null;
  insert into app_private.community_pilot_audit_b4(
    subject_id,administrator_id,action
  ) values(v_user,(select auth.uid()),'admit');
  return 'admitted';
end;
$$;
revoke all on function public.admin_community_admit_pilot_b4(text)
  from public,anon,authenticated;
grant execute on function public.admin_community_admit_pilot_b4(text)
  to authenticated;

create function public.admin_community_revoke_pilot_b4(p_user_id uuid)
returns text language plpgsql security definer set search_path=''
as $$
begin
  if not app_private.is_brand_owner() then return 'forbidden'; end if;
  update app_private.community_pilot_b4 a
    set active=false,revoked_at=now()
    where a.user_id=p_user_id and a.active=true;
  if not found then return 'not_found'; end if;
  insert into app_private.community_pilot_audit_b4(
    subject_id,administrator_id,action
  ) values(p_user_id,(select auth.uid()),'revoke');
  return 'revoked';
end;
$$;
revoke all on function public.admin_community_revoke_pilot_b4(uuid)
  from public,anon,authenticated;
grant execute on function public.admin_community_revoke_pilot_b4(uuid)
  to authenticated;

commit;
