-- V7: Private in-app moderation notices and one appeal per hidden post.
-- No emails/push notifications or external user enrolment.

create table app_private.user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('post_hidden','post_restored','appeal_decided')),
  message text not null check (char_length(message) between 5 and 200),
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index user_notifications_owner_recent
  on app_private.user_notifications(user_id,created_at desc);
alter table app_private.user_notifications enable row level security;
revoke all on app_private.user_notifications from public,anon,authenticated;

create table app_private.moderation_appeals (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null unique references app_private.safety_reports(id) on delete cascade,
  post_id uuid not null references public.community_posts(id) on delete cascade,
  appellant_id uuid not null references auth.users(id) on delete cascade,
  statement text not null check(char_length(btrim(statement)) between 20 and 500),
  status text not null default 'pending' check(status in ('pending','upheld','overturned')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  unique(appellant_id,post_id)
);
create index moderation_appeals_pending
  on app_private.moderation_appeals(created_at) where status='pending';
alter table app_private.moderation_appeals enable row level security;
revoke all on app_private.moderation_appeals from public,anon,authenticated;

create table app_private.appeal_decision_audit (
  id uuid primary key default gen_random_uuid(),
  appeal_id uuid not null references app_private.moderation_appeals(id) on delete cascade,
  reviewer_id uuid not null references auth.users(id) on delete restrict,
  decision text not null check(decision in ('upheld','overturned')),
  note text not null check(char_length(btrim(note)) between 10 and 300),
  occurred_at timestamptz not null default now(),
  unique(appeal_id)
);
alter table app_private.appeal_decision_audit enable row level security;
revoke all on app_private.appeal_decision_audit from public,anon,authenticated;

-- Audited post-hide/post-restore actions produce a private owner notification.
create function app_private.notify_moderation_action()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_owner uuid;
begin
  if new.action not in ('hide_post','restore_post') then return new; end if;
  select r.subject_user_id into v_owner
    from app_private.safety_reports r where r.id=new.report_id and r.target_type='post';
  if v_owner is not null then
    insert into app_private.user_notifications(user_id,kind,message)
    values (
      v_owner,
      case when new.action='hide_post' then 'post_hidden' else 'post_restored' end,
      case when new.action='hide_post'
        then 'Una publicación tuya fue ocultada por moderación. Puedes revisar si es apelable.'
        else 'Se registró una restauración de tu publicación tras una revisión.' end
    );
  end if;
  return new;
end;
$$;
create trigger notify_moderation_audit_action
  after insert on app_private.moderation_audit
  for each row execute function app_private.notify_moderation_action();

create function app_private.my_notifications(p_limit integer default 30)
returns table(id uuid,kind text,message text,created_at timestamptz,read_at timestamptz)
language plpgsql security definer set search_path = '' stable
as $$
declare v_user uuid := (select auth.uid());
begin
 if v_user is null then raise exception 'Sign-in required'; end if;
 if p_limit is null or p_limit not between 1 and 50 then raise exception 'Invalid page size'; end if;
 return query select n.id,n.kind,n.message,n.created_at,n.read_at
 from app_private.user_notifications n where n.user_id=v_user
 order by n.created_at desc,n.id limit p_limit;
end;
$$;
create function public.my_notifications(p_limit integer default 30)
returns table(id uuid,kind text,message text,created_at timestamptz,read_at timestamptz)
language sql security invoker set search_path = '' stable
as $$ select * from app_private.my_notifications(p_limit); $$;

create function app_private.mark_notification_read(p_notification_id uuid)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_actor uuid := (select auth.uid());
begin
 if v_actor is null then raise exception 'Sign-in required'; end if;
 update app_private.user_notifications
 set read_at=coalesce(read_at,now())
 where id=p_notification_id and user_id=v_actor;
 return found;
end;
$$;
create function public.mark_notification_read(p_notification_id uuid)
returns boolean language sql security invoker set search_path = ''
as $$ select app_private.mark_notification_read(p_notification_id); $$;

-- Only posts belonging to the caller, currently hidden, with an audited hide
-- action qualify; never expose reporter IDs, reasons or moderator notes.
create function app_private.my_appealable_posts()
returns table(report_id uuid,post_id uuid,appeal_status text,hidden_at timestamptz)
language plpgsql security definer set search_path = '' stable
as $$
declare v_actor uuid := (select auth.uid());
begin
 if v_actor is null then raise exception 'Sign-in required'; end if;
 return query
 select distinct on (r.target_id)
    r.id,r.target_id,a.status,h.hidden_at
 from app_private.safety_reports r
 join app_private.hidden_posts h on h.post_id=r.target_id
 join app_private.moderation_audit audit on audit.report_id=r.id
   and audit.action='hide_post'
 left join app_private.moderation_appeals a
   on a.post_id=r.target_id and a.appellant_id=v_actor
 where r.target_type='post' and r.subject_user_id=v_actor
 order by r.target_id,audit.occurred_at desc,audit.id desc;
end;
$$;
create function public.my_appealable_posts()
returns table(report_id uuid,post_id uuid,appeal_status text,hidden_at timestamptz)
language sql security invoker set search_path = '' stable
as $$ select * from app_private.my_appealable_posts(); $$;

create function app_private.submit_moderation_appeal(p_report_id uuid,p_statement text)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare
 v_actor uuid := (select auth.uid());
 v_post uuid;
begin
 if v_actor is null then raise exception 'Sign-in required'; end if;
 if p_report_id is null or p_statement is null
    or char_length(btrim(p_statement)) not between 20 and 500 then
    raise exception 'Invalid appeal';
 end if;
 select r.target_id into v_post from app_private.safety_reports r
 where r.id=p_report_id and r.target_type='post' and r.subject_user_id=v_actor;
 if v_post is null
    or not exists(select 1 from app_private.hidden_posts h where h.post_id=v_post)
    or not exists(select 1 from app_private.moderation_audit a
                  where a.report_id=p_report_id and a.action='hide_post') then
    raise exception 'Appeal is not available';
 end if;
 if exists(select 1 from app_private.moderation_appeals a
           where a.appellant_id=v_actor and a.post_id=v_post) then
    raise exception 'Appeal already submitted';
 end if;
 insert into app_private.moderation_appeals(report_id,post_id,appellant_id,statement)
 values(p_report_id,v_post,v_actor,btrim(p_statement));
 return true;
end;
$$;
create function public.submit_moderation_appeal(p_report_id uuid,p_statement text)
returns boolean language sql security invoker set search_path = ''
as $$ select app_private.submit_moderation_appeal(p_report_id,p_statement); $$;

-- All moderator queries authorize against a private role table on each RPC.
create function app_private.moderator_list_appeals(
 p_status text default 'pending',p_limit integer default 30)
returns table(appeal_id uuid,post_id uuid,statement text,status text,
              created_at timestamptz,post_preview text)
language plpgsql security definer set search_path = '' stable
as $$
begin
 if not app_private.is_moderator() then
  raise exception 'Access denied' using errcode='42501';
 end if;
 if p_status is null or p_status not in ('pending','upheld','overturned','all')
    or p_limit is null or p_limit not between 1 and 50 then
  raise exception 'Invalid appeal filters';
 end if;
 return query select a.id,a.post_id,a.statement,a.status,a.created_at,
  left(p.body,160)
 from app_private.moderation_appeals a
 left join public.community_posts p on p.id=a.post_id
 where p_status='all' or a.status=p_status
 order by a.created_at desc,a.id limit p_limit;
end;
$$;
create function public.moderator_list_appeals(
 p_status text default 'pending',p_limit integer default 30)
returns table(appeal_id uuid,post_id uuid,statement text,status text,
              created_at timestamptz,post_preview text)
language sql security invoker set search_path = '' stable
as $$ select * from app_private.moderator_list_appeals(p_status,p_limit); $$;

create function app_private.moderator_decide_appeal(
 p_appeal_id uuid,p_decision text,p_note text)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare
 v_actor uuid := (select auth.uid());
 v_appeal app_private.moderation_appeals%rowtype;
begin
 if not app_private.is_moderator() then
  raise exception 'Access denied' using errcode='42501';
 end if;
 if p_appeal_id is null or p_decision not in ('upheld','overturned')
    or p_decision is null or p_note is null
    or char_length(btrim(p_note)) not between 10 and 300 then
  raise exception 'Invalid appeal decision';
 end if;
 select * into v_appeal from app_private.moderation_appeals a
 where a.id=p_appeal_id for update;
 if not found or v_appeal.status <> 'pending' then
  raise exception 'Appeal not pending';
 end if;
 if v_appeal.appellant_id=v_actor
    or exists(
     select 1 from app_private.moderation_audit m
     where m.report_id=v_appeal.report_id and m.action='hide_post'
       and m.actor_id=v_actor
    ) then
  raise exception 'Independent reviewer required' using errcode='42501';
 end if;

 update app_private.moderation_appeals
 set status=p_decision,decided_at=now()
 where id=v_appeal.id;

 if p_decision='overturned' then
  -- Keep the post hidden if a SEPARATE report on this post has an
  -- outstanding last action 'hide_post' (not later 'restore_post').
  if not exists(
    select 1 from app_private.safety_reports r
    where r.target_type='post' and r.target_id=v_appeal.post_id
      and r.id<>v_appeal.report_id
      and (
       select ma.action from app_private.moderation_audit ma
       where ma.report_id=r.id and ma.action in ('hide_post','restore_post')
       order by ma.occurred_at desc,ma.id desc limit 1
      )='hide_post'
  ) then
    delete from app_private.hidden_posts where post_id=v_appeal.post_id;
  end if;
 end if;

 insert into app_private.appeal_decision_audit
   (appeal_id,reviewer_id,decision,note)
 values(v_appeal.id,v_actor,p_decision,btrim(p_note));
 insert into app_private.user_notifications(user_id,kind,message)
 values(v_appeal.appellant_id,'appeal_decided',
   case when p_decision='overturned'
     then 'Tu apelación fue aceptada. Revisa el estado de tu publicación; podrían existir otras restricciones.'
     else 'Tu apelación fue revisada y la decisión original se mantiene.' end);
 return true;
end;
$$;
create function public.moderator_decide_appeal(
 p_appeal_id uuid,p_decision text,p_note text)
returns boolean language sql security invoker set search_path = ''
as $$ select app_private.moderator_decide_appeal(p_appeal_id,p_decision,p_note); $$;

-- No client can see private records, create notifications, read appeals of
-- others, change their status or invoke an administrative function as anon.
revoke execute on all functions in schema app_private from public,anon,authenticated;
revoke execute on function public.my_notifications(integer) from public,anon,authenticated;
revoke execute on function public.mark_notification_read(uuid) from public,anon,authenticated;
revoke execute on function public.my_appealable_posts() from public,anon,authenticated;
revoke execute on function public.submit_moderation_appeal(uuid,text) from public,anon,authenticated;
revoke execute on function public.moderator_list_appeals(text,integer) from public,anon,authenticated;
revoke execute on function public.moderator_decide_appeal(uuid,text,text) from public,anon,authenticated;

-- Restore all earlier intended private function grants (some existing
-- RLS policies and RPC wrappers reference them as authenticated invokers).
grant execute on all functions in schema app_private to authenticated;
grant execute on function public.my_notifications(integer) to authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;
grant execute on function public.my_appealable_posts() to authenticated;
grant execute on function public.submit_moderation_appeal(uuid,text) to authenticated;
grant execute on function public.moderator_list_appeals(text,integer) to authenticated;
grant execute on function public.moderator_decide_appeal(uuid,text,text) to authenticated;
