-- my_fitness_date V6: explicit moderator membership, scoped review RPC and audit trail.
-- This is DEV-only, and does not automatically appoint any moderator.

create table app_private.moderators (
  user_id uuid primary key references auth.users(id) on delete cascade,
  appointed_at timestamptz not null default now()
);
alter table app_private.moderators enable row level security;
revoke all on app_private.moderators from public,anon,authenticated;

create table app_private.moderation_audit (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null,
  actor_id uuid not null,
  action text not null check (action in ('review','dismiss','resolve','hide_post','restore_post')),
  previous_status text not null,
  resulting_status text not null,
  note text not null check (char_length(btrim(note)) between 5 and 200),
  occurred_at timestamptz not null default now()
);
create index moderation_audit_recent on app_private.moderation_audit(occurred_at desc);
alter table app_private.moderation_audit enable row level security;
revoke all on app_private.moderation_audit from public,anon,authenticated;

-- Private implementations use auth.uid() and never trust user_metadata or
-- client-supplied identities. Public wrappers stay SECURITY INVOKER.
create function app_private.is_moderator()
returns boolean language sql security definer set search_path = '' stable
as $$
 select (select auth.uid()) is not null
   and exists(
     select 1 from app_private.moderators m
     where m.user_id = (select auth.uid())
   );
$$;

create function public.is_moderator()
returns boolean language sql security invoker set search_path = '' stable
as $$ select app_private.is_moderator(); $$;

create function app_private.moderator_list_reports(
  p_status text default 'pending', p_limit integer default 30
)
returns table(
 report_id uuid,target_type text,target_id uuid,reason text,details text,
 status text,created_at timestamptz,target_preview text
)
language plpgsql security definer set search_path = '' stable
as $$
begin
  if not app_private.is_moderator() then
    raise exception 'Access denied' using errcode='42501';
  end if;
  if p_status is null or p_status not in ('pending','reviewing','resolved','dismissed','all')
    or p_limit is null or p_limit < 1 or p_limit > 50 then
    raise exception 'Invalid report filters';
  end if;

  return query
  select r.id,r.target_type,r.target_id,r.reason,r.details,r.status,r.created_at,
    case r.target_type
      when 'post' then (select left(p.body,160) from public.community_posts p
                        where p.id=r.target_id)
      when 'event' then (select left(e.title,160) from public.sport_events e
                         where e.id=r.target_id)
      when 'user' then (select left(sp.display_name,160) from public.social_profiles sp
                        where sp.user_id=r.target_id)
    end as target_preview
  from app_private.safety_reports r
  where p_status='all' or r.status=p_status
  order by r.created_at desc,r.id
  limit p_limit;
end;
$$;

create function public.moderator_list_reports(
  p_status text default 'pending', p_limit integer default 30
)
returns table(
 report_id uuid,target_type text,target_id uuid,reason text,details text,
 status text,created_at timestamptz,target_preview text
)
language sql security invoker set search_path = '' stable
as $$ select * from app_private.moderator_list_reports(p_status,p_limit); $$;

create function app_private.moderator_decide(
  p_report_id uuid,p_action text,p_note text
) returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_report app_private.safety_reports%rowtype;
  v_next text;
begin
  if not app_private.is_moderator() then
    raise exception 'Access denied' using errcode='42501';
  end if;
  if p_report_id is null or p_action is null
     or p_action not in ('review','dismiss','resolve','hide_post','restore_post')
     or p_note is null or char_length(btrim(p_note)) not between 5 and 200 then
    raise exception 'Invalid moderation decision';
  end if;

  select * into v_report from app_private.safety_reports r
  where r.id=p_report_id for update;
  if not found then raise exception 'Report not found'; end if;

  if p_action in ('hide_post','restore_post') and v_report.target_type <> 'post' then
    raise exception 'Only a post can be hidden or restored';
  end if;

  if p_action = 'review' then
    v_next := 'reviewing';
  elsif p_action = 'dismiss' then
    v_next := 'dismissed';
  else
    v_next := 'resolved';
  end if;

  if p_action = 'hide_post' then
    if not exists(select 1 from public.community_posts p where p.id=v_report.target_id) then
      raise exception 'Post no longer exists';
    end if;
    insert into app_private.hidden_posts(post_id,reason)
    values(v_report.target_id,left(btrim(p_note),200))
    on conflict (post_id) do update set reason=excluded.reason,hidden_at=now();
  elsif p_action = 'restore_post' then
    delete from app_private.hidden_posts where post_id=v_report.target_id;
  end if;

  update app_private.safety_reports set status=v_next where id=v_report.id;
  insert into app_private.moderation_audit
   (report_id,actor_id,action,previous_status,resulting_status,note)
  values(v_report.id,v_actor,p_action,v_report.status,v_next,btrim(p_note));

  return true;
end;
$$;

create function public.moderator_decide(
  p_report_id uuid,p_action text,p_note text
) returns boolean language sql security invoker set search_path = ''
as $$ select app_private.moderator_decide(p_report_id,p_action,p_note); $$;

create function app_private.moderator_recent_actions(p_limit integer default 20)
returns table(report_id uuid,action text,previous_status text,resulting_status text,
              note text,occurred_at timestamptz)
language plpgsql security definer set search_path = '' stable
as $$
begin
 if not app_private.is_moderator() then
   raise exception 'Access denied' using errcode='42501';
 end if;
 if p_limit is null or p_limit < 1 or p_limit > 50 then
   raise exception 'Invalid audit page size';
 end if;
 return query
 select a.report_id,a.action,a.previous_status,a.resulting_status,a.note,a.occurred_at
 from app_private.moderation_audit a
 order by a.occurred_at desc,a.id
 limit p_limit;
end;
$$;

create function public.moderator_recent_actions(p_limit integer default 20)
returns table(report_id uuid,action text,previous_status text,resulting_status text,
              note text,occurred_at timestamptz)
language sql security invoker set search_path = '' stable
as $$ select * from app_private.moderator_recent_actions(p_limit); $$;

-- Remove PUBLIC defaults from every new function. Private implementations
-- are callable only with the authenticated role and enforce moderator membership.
revoke execute on function app_private.is_moderator() from public,anon,authenticated;
revoke execute on function public.is_moderator() from public,anon,authenticated;
revoke execute on function app_private.moderator_list_reports(text,integer) from public,anon,authenticated;
revoke execute on function public.moderator_list_reports(text,integer) from public,anon,authenticated;
revoke execute on function app_private.moderator_decide(uuid,text,text) from public,anon,authenticated;
revoke execute on function public.moderator_decide(uuid,text,text) from public,anon,authenticated;
revoke execute on function app_private.moderator_recent_actions(integer) from public,anon,authenticated;
revoke execute on function public.moderator_recent_actions(integer) from public,anon,authenticated;

grant execute on function app_private.is_moderator() to authenticated;
grant execute on function public.is_moderator() to authenticated;
grant execute on function app_private.moderator_list_reports(text,integer) to authenticated;
grant execute on function public.moderator_list_reports(text,integer) to authenticated;
grant execute on function app_private.moderator_decide(uuid,text,text) to authenticated;
grant execute on function public.moderator_decide(uuid,text,text) to authenticated;
grant execute on function app_private.moderator_recent_actions(integer) to authenticated;
grant execute on function public.moderator_recent_actions(integer) to authenticated;

-- No role is seeded; grant membership only using privileged SQL with an
-- existing auth.users(id). Never through an app-facing RPC or user metadata.
