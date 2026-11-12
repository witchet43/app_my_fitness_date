-- B4 My Fitness Date: privacy-first community and human moderation.
-- QA preview only. No matching, chat, DMs, external links or public attendee lists.
begin;

create table public.community_posts_b4 (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  topic text not null check (topic in ('running','cycling','hiking','gym','wellness','other')),
  content text not null check (char_length(btrim(content)) between 15 and 480),
  status text not null default 'visible'
    check (status in ('visible','hidden','removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index community_posts_b4_feed_idx
  on public.community_posts_b4 (created_at desc,id desc)
  where status='visible';
create index community_posts_b4_author_idx
  on public.community_posts_b4 (author_id,created_at desc);
alter table public.community_posts_b4 enable row level security;
revoke all on public.community_posts_b4 from public,anon,authenticated;

create table public.community_blocks_b4 (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id,blocked_id),
  check (blocker_id<>blocked_id)
);
create index community_blocks_b4_reverse on
  public.community_blocks_b4 (blocked_id,blocker_id);
alter table public.community_blocks_b4 enable row level security;
revoke all on public.community_blocks_b4 from public,anon,authenticated;

create table public.community_reports_b4 (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  post_id uuid references public.community_posts_b4(id) on delete set null,
  subject_id uuid references auth.users(id) on delete set null,
  reason text not null
    check (reason in ('harassment','spam','privacy','unsafe','other')),
  detail text not null default '' check (char_length(detail)<=300),
  status text not null default 'pending'
    check (status in ('pending','resolved','dismissed')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  resolution text,
  -- An object deleted later may null the corresponding FK. New reports
  -- still require exactly one target through the RPC transaction.
  check (post_id is null or subject_id is null)
);
-- Idempotency is per active target, with separate indexes for profiles/posts.
create unique index community_report_b4_post_unique
  on public.community_reports_b4 (reporter_id,post_id) where post_id is not null;
create unique index community_report_b4_profile_unique
  on public.community_reports_b4 (reporter_id,subject_id) where subject_id is not null;
create index community_report_b4_queue_idx
  on public.community_reports_b4 (status,created_at);
alter table public.community_reports_b4 enable row level security;
revoke all on public.community_reports_b4 from public,anon,authenticated;

create table app_private.community_moderation_audit_b4 (
  id bigint generated always as identity primary key,
  moderator_id uuid not null references auth.users(id),
  report_id uuid not null references public.community_reports_b4(id),
  action text not null check (action in ('hide_post','suspend_user','dismiss')),
  note text not null check (char_length(note) between 5 and 500),
  recorded_at timestamptz not null default now()
);
alter table app_private.community_moderation_audit_b4 enable row level security;
revoke all on app_private.community_moderation_audit_b4 from public,anon,authenticated;

create table app_private.community_suspensions_b4 (
  user_id uuid primary key references auth.users(id) on delete cascade,
  active boolean not null default true,
  suspended_by uuid not null references auth.users(id),
  report_id uuid references public.community_reports_b4(id),
  suspended_at timestamptz not null default now()
);
alter table app_private.community_suspensions_b4 enable row level security;
revoke all on app_private.community_suspensions_b4 from public,anon,authenticated;

create table app_private.community_deletion_requests_b4 (
  user_id uuid primary key references auth.users(id) on delete cascade,
  requested_at timestamptz not null default now(),
  status text not null default 'pending' check (status in ('pending','in_review')),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id)
);
alter table app_private.community_deletion_requests_b4 enable row level security;
revoke all on app_private.community_deletion_requests_b4 from public,anon,authenticated;

-- A community opt-out is independent of the irreversible account deletion request.
create table app_private.community_participation_b4 (
  user_id uuid primary key references auth.users(id) on delete cascade,
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table app_private.community_participation_b4 enable row level security;
revoke all on app_private.community_participation_b4
  from public,anon,authenticated;

-- Guards include all required consents and self-declared adult status.
-- These do NOT replace independent age verification required for dating/beta.
create function app_private.community_actor_b4()
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

create function public.community_status_b4()
returns text language sql stable security definer set search_path=''
as $$
  select app_private.community_actor_b4();
$$;
revoke all on function public.community_status_b4()
  from public,anon,authenticated;
grant execute on function public.community_status_b4() to authenticated;

-- Paginated feed returns ONLY opted-in author name, topic and post; never
-- birthday/email/gym/attendee list. Either side's block excludes content.
create function public.community_feed_b4(
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

create function public.community_publish_b4(
  p_topic text,p_content text
)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_user uuid := (select auth.uid()); v_status text;v_id uuid;
begin
  v_status:=app_private.community_actor_b4();
  if v_status<>'available' then
    return jsonb_build_object('status',v_status); end if;
  if p_topic is null or p_topic <> all(array[
    'running','cycling','hiking','gym','wellness','other'
  ]) or p_content is null or char_length(btrim(p_content)) not between 15 and 480
  or p_content ~* '(https?://|www\.|[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}|[[:digit:]]{8,})'
  then return jsonb_build_object('status','invalid'); end if;
  -- Database-backed throttling. First iteration: 3 posts per hour.
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,405));
  if (select count(*) from public.community_posts_b4 p
      where p.author_id=v_user
        and p.created_at > now()-interval '1 hour')>=3 then
    return jsonb_build_object('status','rate_limited'); end if;
  insert into public.community_posts_b4(author_id,topic,content)
    values(v_user,p_topic,btrim(p_content)) returning id into v_id;
  return jsonb_build_object('status','published','id',v_id);
end;
$$;
revoke all on function public.community_publish_b4(text,text)
  from public,anon,authenticated;
grant execute on function public.community_publish_b4(text,text)
  to authenticated;

create function public.community_remove_post_b4(p_post_id uuid)
returns text language plpgsql security definer set search_path=''
as $$
declare v_user uuid:=(select auth.uid());
begin
  if app_private.community_actor_b4()<>'available'
    then return 'forbidden'; end if;
  update public.community_posts_b4 p
  set status='removed',updated_at=now()
  where p.id=p_post_id and p.author_id=v_user and p.status='visible';
  if found then return 'removed'; end if;
  return 'not_found';
end;
$$;
revoke all on function public.community_remove_post_b4(uuid)
  from public,anon,authenticated;
grant execute on function public.community_remove_post_b4(uuid)
  to authenticated;

create function public.community_block_b4(
  p_user_id uuid,p_block boolean default true
)
returns text language plpgsql security definer set search_path=''
as $$
declare v_user uuid := (select auth.uid());
begin
  if app_private.community_actor_b4()<>'available'
    then return 'forbidden'; end if;
  if p_user_id is null or p_user_id=v_user or not exists (
    select 1 from public.member_profiles_v26 p where p.user_id=p_user_id
      and p.onboarding_complete=true
  ) then return 'not_found'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,406));
  if p_block then
    if (select count(*) from public.community_blocks_b4 b
      where b.blocker_id=v_user and b.created_at>now()-interval '1 day')>=30
      then return 'rate_limited'; end if;
    insert into public.community_blocks_b4(blocker_id,blocked_id)
      values(v_user,p_user_id) on conflict do nothing;
    return 'blocked';
  else
    delete from public.community_blocks_b4 b
      where b.blocker_id=v_user and b.blocked_id=p_user_id;
    return 'unblocked';
  end if;
end;
$$;
revoke all on function public.community_block_b4(uuid,boolean)
  from public,anon,authenticated;
grant execute on function public.community_block_b4(uuid,boolean)
  to authenticated;

create function public.community_my_blocks_b4()
returns table (blocked_id uuid,display_name text)
language sql stable security definer set search_path=''
as $$
  select b.blocked_id,p.display_name
    from public.community_blocks_b4 b
    left join public.member_profiles_v26 p on p.user_id=b.blocked_id
    where app_private.community_actor_b4()='available'
      and b.blocker_id=(select auth.uid())
    order by b.created_at desc limit 100;
$$;
revoke all on function public.community_my_blocks_b4()
  from public,anon,authenticated;
grant execute on function public.community_my_blocks_b4()
  to authenticated;

create function public.community_report_b4(
  p_post_id uuid,p_user_id uuid,p_reason text,p_detail text default ''
)
returns text language plpgsql security definer set search_path=''
as $$
declare v_user uuid := (select auth.uid());v_subject uuid;
begin
  if app_private.community_actor_b4()<>'available'
    then return 'forbidden'; end if;
  if (p_post_id is null)=(p_user_id is null)
    or p_reason is null or p_reason <> all(array[
      'harassment','spam','privacy','unsafe','other'
    ]) or char_length(coalesce(p_detail,''))>300 then
      return 'invalid'; end if;
  if p_post_id is not null then
    select p.author_id into v_subject from public.community_posts_b4 p
      where p.id=p_post_id;
  else
    select p.user_id into v_subject from public.member_profiles_v26 p
      where p.user_id=p_user_id and p.onboarding_complete=true;
  end if;
  if v_subject is null or v_subject=v_user then return 'not_found'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,407));
  if (select count(*) from public.community_reports_b4 r
    where r.reporter_id=v_user and r.created_at>now()-interval '1 day')>=10
    then return 'rate_limited'; end if;
  insert into public.community_reports_b4(
    reporter_id,post_id,subject_id,reason,detail
  ) values(v_user,p_post_id,p_user_id,p_reason,coalesce(p_detail,''))
    on conflict do nothing;
  if not found then return 'already_reported'; end if;
  return 'reported';
end;
$$;
revoke all on function public.community_report_b4(uuid,uuid,text,text)
  from public,anon,authenticated;
grant execute on function public.community_report_b4(uuid,uuid,text,text)
  to authenticated;

create function public.community_my_post_history_b4()
returns table (
  id uuid,topic text,content text,status text,created_at timestamptz
)
language sql stable security definer set search_path=''
as $$
  select p.id,p.topic,p.content,p.status,p.created_at
    from public.community_posts_b4 p
    where (select auth.uid()) is not null
      and p.author_id=(select auth.uid())
    order by p.created_at desc limit 100;
$$;
revoke all on function public.community_my_post_history_b4()
  from public,anon,authenticated;
grant execute on function public.community_my_post_history_b4()
  to authenticated;


-- Owner may create GENUINE official notices without adopting a member persona.
-- Published notices are real content entered by the proprietor, not fixtures.
create table app_private.community_announcement_audit_b4 (
  id bigint generated always as identity primary key,
  owner_id uuid not null references auth.users(id),
  post_id uuid not null references public.community_posts_b4(id),
  action text not null check(action in ('publish','remove')),
  created_at timestamptz not null default now()
);
alter table app_private.community_announcement_audit_b4 enable row level security;
revoke all on app_private.community_announcement_audit_b4
  from public,anon,authenticated;

create function public.admin_community_publish_b4(
  p_topic text,p_content text
)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_user uuid:=(select auth.uid());v_id uuid;
begin
  if not app_private.is_brand_owner() then
    return jsonb_build_object('status','forbidden'); end if;
  if p_topic is null or p_topic<>all(array[
    'running','cycling','hiking','gym','wellness','other'
  ]) or p_content is null or char_length(btrim(p_content)) not between 15 and 480
     or p_content ~* '(https?://|www\.|[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}|[[:digit:]]{8,})'
    then return jsonb_build_object('status','invalid'); end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,408));
  if (select count(*) from public.community_posts_b4 p
    where p.author_id=v_user and p.created_at>now()-interval '1 day')>=5
    then return jsonb_build_object('status','rate_limited'); end if;
  insert into public.community_posts_b4(author_id,topic,content)
    values(v_user,p_topic,btrim(p_content)) returning id into v_id;
  insert into app_private.community_announcement_audit_b4(
    owner_id,post_id,action
  ) values(v_user,v_id,'publish');
  return jsonb_build_object('status','published','id',v_id);
end;
$$;
revoke all on function public.admin_community_publish_b4(text,text)
  from public,anon,authenticated;
grant execute on function public.admin_community_publish_b4(text,text)
  to authenticated;

create function public.admin_community_announcements_b4()
returns table (
  id uuid,topic text,content text,status text,created_at timestamptz
)
language sql stable security definer set search_path=''
as $$
  select p.id,p.topic,p.content,p.status,p.created_at
  from public.community_posts_b4 p
  where app_private.is_brand_owner()
    and p.author_id=(select auth.uid())
  order by p.created_at desc limit 50;
$$;
revoke all on function public.admin_community_announcements_b4()
  from public,anon,authenticated;
grant execute on function public.admin_community_announcements_b4()
  to authenticated;

create function public.admin_community_remove_announcement_b4(p_post_id uuid)
returns text language plpgsql security definer set search_path=''
as $$
begin
  if not app_private.is_brand_owner() then return 'forbidden'; end if;
  update public.community_posts_b4 p
    set status='removed',updated_at=now()
    where p.id=p_post_id and p.author_id=(select auth.uid())
      and p.status='visible';
  if not found then return 'not_found'; end if;
  insert into app_private.community_announcement_audit_b4(
    owner_id,post_id,action
  ) values((select auth.uid()),p_post_id,'remove');
  return 'removed';
end;
$$;
revoke all on function public.admin_community_remove_announcement_b4(uuid)
  from public,anon,authenticated;
grant execute on function public.admin_community_remove_announcement_b4(uuid)
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

-- Owner MFA/AAL2 only; reporting identities remain private from members.
create function public.admin_community_queue_b4()
returns table (
  id uuid,post_id uuid,subject_id uuid,subject_name text,
  reason text,detail text,post_excerpt text,created_at timestamptz
)
language sql stable security definer set search_path=''
as $$
  select r.id,r.post_id,coalesce(r.subject_id,p.author_id),
    m.display_name,r.reason,r.detail,
    left(coalesce(p.content,''),180),r.created_at
  from public.community_reports_b4 r
  left join public.community_posts_b4 p on p.id=r.post_id
  left join public.member_profiles_v26 m
    on m.user_id=coalesce(r.subject_id,p.author_id)
  where app_private.is_brand_owner() and r.status='pending'
  order by r.created_at asc limit 50;
$$;
revoke all on function public.admin_community_queue_b4()
  from public,anon,authenticated;
grant execute on function public.admin_community_queue_b4()
  to authenticated;

create function public.admin_community_resolve_b4(
  p_report_id uuid,p_action text,p_note text
)
returns text language plpgsql security definer set search_path=''
as $$
declare v_report public.community_reports_b4%rowtype;v_subject uuid;
begin
  if not app_private.is_brand_owner() then return 'forbidden'; end if;
  if p_action is null or p_action <> all(array[
    'hide_post','suspend_user','dismiss'
  ]) or p_note is null or char_length(btrim(p_note)) not between 5 and 500
    then return 'invalid'; end if;
  select * into v_report from public.community_reports_b4 r
    where r.id=p_report_id for update;
  if not found then return 'not_found'; end if;
  if v_report.status<>'pending' then return 'already_reviewed'; end if;
  if p_action='hide_post' and v_report.post_id is null
    then return 'invalid'; end if;
  if p_action='hide_post' then
    update public.community_posts_b4 p set status='hidden',
      updated_at=now() where p.id=v_report.post_id and p.status='visible';
  end if;
  if p_action='suspend_user' then
    if v_report.post_id is not null then
      select p.author_id into v_subject from public.community_posts_b4 p
        where p.id=v_report.post_id;
    else
      v_subject:=v_report.subject_id;
    end if;
    if v_subject is null then return 'not_found'; end if;
    if v_subject=(select auth.uid()) then return 'invalid'; end if;
    insert into app_private.community_suspensions_b4(
      user_id,suspended_by,report_id
    ) values(v_subject,(select auth.uid()),p_report_id)
    on conflict(user_id) do update
      set active=true,suspended_by=excluded.suspended_by,
          report_id=excluded.report_id,suspended_at=now();
    update public.community_posts_b4 p
      set status='hidden',updated_at=now()
      where p.author_id=v_subject and p.status='visible';
  end if;
  update public.community_reports_b4 r
    set status=case when p_action='dismiss' then 'dismissed' else 'resolved' end,
      reviewed_at=now(),reviewed_by=(select auth.uid()),resolution=p_action
    where r.id=p_report_id;
  insert into app_private.community_moderation_audit_b4(
    moderator_id,report_id,action,note
  ) values((select auth.uid()),p_report_id,p_action,btrim(p_note));
  return 'resolved';
end;
$$;
revoke all on function public.admin_community_resolve_b4(uuid,text,text)
  from public,anon,authenticated;
grant execute on function public.admin_community_resolve_b4(uuid,text,text)
  to authenticated;

-- Deletion is a human-managed request, NEVER an unverified claim that
-- auth files/backups/logs were already erased. The request immediately
-- prevents new posts and hides the requester's existing public content.
create function public.community_request_deletion_b4()
returns text language plpgsql security definer set search_path=''
as $$
declare v_user uuid:=(select auth.uid());
begin
  if v_user is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
    then return 'not_authenticated'; end if;
  if exists(select 1 from app_private.brand_administrators a
      where a.user_id=v_user and a.active=true)
    then return 'forbidden'; end if;
  insert into app_private.community_deletion_requests_b4(user_id)
    values(v_user) on conflict do nothing;
  update public.community_posts_b4 p set status='removed',
    updated_at=now() where p.author_id=v_user and p.status='visible';
  return 'pending';
end;
$$;
revoke all on function public.community_request_deletion_b4()
  from public,anon,authenticated;
grant execute on function public.community_request_deletion_b4()
  to authenticated;

create function public.community_deletion_status_b4()
returns text language sql stable security definer set search_path=''
as $$
  select coalesce((select d.status from app_private.community_deletion_requests_b4 d
    where d.user_id=(select auth.uid())), 'none');
$$;
revoke all on function public.community_deletion_status_b4()
  from public,anon,authenticated;
grant execute on function public.community_deletion_status_b4()
  to authenticated;

create function public.admin_community_deletion_queue_b4()
returns table (user_id uuid,requested_at timestamptz,status text)
language sql stable security definer set search_path=''
as $$
  select d.user_id,d.requested_at,d.status
  from app_private.community_deletion_requests_b4 d
  where app_private.is_brand_owner()
  order by d.requested_at asc limit 50;
$$;
revoke all on function public.admin_community_deletion_queue_b4()
  from public,anon,authenticated;
grant execute on function public.admin_community_deletion_queue_b4()
  to authenticated;

comment on function public.community_request_deletion_b4() is
  'Queues a human-managed account deletion request; does NOT erase auth, backups or logs.';
comment on table public.community_posts_b4 is
  'B4 QA-gated member posts; only RPCs can access, moderated and block-filtered.';
commit;
