-- Iteration 17: incident escalation + independent oversight.
-- This is operational tooling, not an automated safety officer or SLA guarantee.

create table app_private.incident_escalations (
 report_id uuid primary key references app_private.safety_reports(id) on delete cascade,
 priority text not null check(priority in ('urgent','high','normal')),
 status text not null default 'open' check(status in ('open','closed')),
 escalated_by uuid not null references auth.users(id) on delete restrict,
 escalated_at timestamptz not null default now(),
 escalation_note text not null check(char_length(btrim(escalation_note)) between 10 and 300),
 closed_by uuid references auth.users(id) on delete restrict,
 closed_at timestamptz,
 closure_note text check(closure_note is null or char_length(btrim(closure_note)) between 10 and 300),
 constraint escalation_closure_consistent check(
   (status='open' and closed_by is null and closed_at is null and closure_note is null)
   or (status='closed' and closed_by is not null and closed_at is not null and closure_note is not null)
 )
);
create index incident_escalations_active on app_private.incident_escalations(escalated_at)
 where status='open';
alter table app_private.incident_escalations enable row level security;
revoke all on app_private.incident_escalations from public,anon,authenticated;

create table app_private.incident_audit (
 id uuid primary key default gen_random_uuid(),
 report_id uuid not null references app_private.safety_reports(id) on delete cascade,
 actor_id uuid not null references auth.users(id) on delete restrict,
 action text not null check(action in ('escalated','reviewed')),
 priority text not null check(priority in ('urgent','high','normal')),
 note text not null check(char_length(btrim(note)) between 10 and 300),
 occurred_at timestamptz not null default now()
);
create index incident_audit_recent on app_private.incident_audit(occurred_at desc);
alter table app_private.incident_audit enable row level security;
revoke all on app_private.incident_audit from public,anon,authenticated;

-- Structured urgency: informational goal only, NOT a delivered staffing SLA.
-- Caller receives no reporter identity. Oldest urgent & overdue cases first.
create function app_private.moderator_incident_queue(p_limit integer default 30)
returns table(
 report_id uuid,target_type text,reason text,report_status text,
 reported_at timestamptz,priority text,attention_deadline timestamptz,
 overdue boolean,escalation_status text,target_preview text
)
language plpgsql security definer stable set search_path = ''
as $$
begin
 if not app_private.is_moderator() then
   raise exception 'Access denied' using errcode='42501';
 end if;
 if p_limit is null or p_limit not between 1 and 50 then
   raise exception 'Invalid queue limit';
 end if;
 return query
 select r.id,r.target_type,r.reason,r.status,r.created_at,
   coalesce(e.priority,case r.reason
     when 'unsafe' then 'urgent' when 'harassment' then 'high'
     else 'normal' end),
   r.created_at + (case r.reason
     when 'unsafe' then interval '1 hour'
     when 'harassment' then interval '4 hours'
     when 'spam' then interval '24 hours'
     else interval '48 hours' end),
   clock_timestamp() > r.created_at + (case r.reason
     when 'unsafe' then interval '1 hour'
     when 'harassment' then interval '4 hours'
     when 'spam' then interval '24 hours'
     else interval '48 hours' end),
   coalesce(e.status,'not_escalated'),
   case r.target_type
     when 'post' then (select left(p.body,120) from public.community_posts p where p.id=r.target_id)
     when 'event' then (select left(ev.title,120) from public.sport_events ev where ev.id=r.target_id)
     else (select left(sp.display_name,120) from public.social_profiles sp where sp.user_id=r.target_id)
   end
 from app_private.safety_reports r
 left join app_private.incident_escalations e on e.report_id=r.id
 where r.status in ('pending','reviewing') or e.status='open'
 order by coalesce(e.status='open',false) desc,
          (r.reason='unsafe') desc,
          clock_timestamp() > r.created_at+(case r.reason
              when 'unsafe' then interval '1 hour'
              when 'harassment' then interval '4 hours'
              when 'spam' then interval '24 hours'
              else interval '48 hours' end) desc,
          r.created_at,r.id
 limit p_limit;
end;
$$;
create function public.moderator_incident_queue(p_limit integer default 30)
returns table(
 report_id uuid,target_type text,reason text,report_status text,
 reported_at timestamptz,priority text,attention_deadline timestamptz,
 overdue boolean,escalation_status text,target_preview text
)
language sql security invoker stable set search_path = ''
as $$ select * from app_private.moderator_incident_queue(p_limit); $$;

create function app_private.moderator_escalate_report(
 p_report_id uuid,p_priority text,p_note text
) returns boolean language plpgsql security definer set search_path = ''
as $$
declare
 v_actor uuid:=(select auth.uid());
 v_report app_private.safety_reports%rowtype;
begin
 if not app_private.is_moderator() then raise exception 'Access denied' using errcode='42501'; end if;
 if p_report_id is null or p_priority not in ('urgent','high','normal')
    or p_priority is null or p_note is null
    or char_length(btrim(p_note)) not between 10 and 300 then
  raise exception 'Invalid escalation';
 end if;
 select * into v_report from app_private.safety_reports
   where id=p_report_id for update;
 if not found then raise exception 'Report not found'; end if;
 if v_report.reporter_id=v_actor or v_report.subject_user_id=v_actor then
   raise exception 'CONFLICT_OF_INTEREST' using errcode='42501';
 end if;
 if v_report.status not in ('pending','reviewing') then
   raise exception 'Only active reports can be escalated' using errcode='P0001';
 end if;
 if exists(select 1 from app_private.incident_escalations where report_id=p_report_id) then
   raise exception 'Incident already escalated' using errcode='P0001';
 end if;
 insert into app_private.incident_escalations
   (report_id,priority,escalated_by,escalation_note)
 values(p_report_id,p_priority,v_actor,btrim(p_note));
 insert into app_private.incident_audit(report_id,actor_id,action,priority,note)
 values(p_report_id,v_actor,'escalated',p_priority,btrim(p_note));
 return true;
end;
$$;
create function public.moderator_escalate_report(
 p_report_id uuid,p_priority text,p_note text
) returns boolean language sql security invoker set search_path = ''
as $$ select app_private.moderator_escalate_report(p_report_id,p_priority,p_note); $$;

create function app_private.moderator_review_escalation(
 p_report_id uuid,p_note text
) returns boolean language plpgsql security definer set search_path = ''
as $$
declare
 v_actor uuid:=(select auth.uid());
 v_report app_private.safety_reports%rowtype;
 v_escalation app_private.incident_escalations%rowtype;
begin
 if not app_private.is_moderator() then raise exception 'Access denied' using errcode='42501'; end if;
 if p_report_id is null or p_note is null or
   char_length(btrim(p_note)) not between 10 and 300 then
   raise exception 'Invalid independent review';
 end if;
 select * into v_report from app_private.safety_reports where id=p_report_id for update;
 if not found then raise exception 'Report not found'; end if;
 select * into v_escalation from app_private.incident_escalations
   where report_id=p_report_id for update;
 if not found or v_escalation.status<>'open' then
   raise exception 'No pending escalation' using errcode='P0001';
 end if;
 if v_actor=v_escalation.escalated_by or v_actor=v_report.reporter_id
     or v_actor=v_report.subject_user_id then
   raise exception 'INDEPENDENT_REVIEW_REQUIRED' using errcode='42501';
 end if;
 update app_private.incident_escalations
   set status='closed',closed_by=v_actor,closed_at=now(),closure_note=btrim(p_note)
 where report_id=p_report_id;
 insert into app_private.incident_audit(report_id,actor_id,action,priority,note)
 values(p_report_id,v_actor,'reviewed',v_escalation.priority,btrim(p_note));
 return true;
end;
$$;
create function public.moderator_review_escalation(
 p_report_id uuid,p_note text
) returns boolean language sql security invoker set search_path = ''
as $$ select app_private.moderator_review_escalation(p_report_id,p_note); $$;

-- Refuse self-moderation, and final decisions before independent review.
create or replace function app_private.moderator_decide(
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

  -- An operator must never decide their own report or a report about them.
  if v_report.reporter_id=v_actor or v_report.subject_user_id=v_actor then
    raise exception 'CONFLICT_OF_INTEREST' using errcode='42501';
  end if;
  -- A distinct moderator must sign off on a pending escalation before any
  -- final decision; protective hide/review actions remain possible.
  if p_action in ('dismiss','resolve','restore_post')
     and exists(select 1 from app_private.incident_escalations e
                where e.report_id=v_report.id and e.status='open') then
    raise exception 'INDEPENDENT_REVIEW_REQUIRED' using errcode='P0001';
  end if;

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

create or replace function app_private.erasure_preflight(p_user_id uuid,p_ticket text)
returns jsonb language plpgsql security definer set search_path = '' stable
as $function$
declare
  v_requested timestamptz;
  v_approved timestamptz;
  v_blockers text[]:='{}';
  v_storage_count bigint:=0;
begin
  if p_user_id is null or p_ticket is null then
    raise exception 'Missing deletion target or ticket';
  end if;

  select requested_at into v_requested
    from app_private.account_deletion_requests where user_id=p_user_id;
  if v_requested is null then
    v_blockers:=array_append(v_blockers,'missing_pending_request');
  elsif v_requested>now()-interval '7 days' then
    v_blockers:=array_append(v_blockers,'review_period_not_elapsed');
  end if;

  select approved_at into v_approved from app_private.erasure_approvals
    where user_id=p_user_id and ticket=p_ticket;
  if v_approved is null then
    v_blockers:=array_append(v_blockers,'missing_operator_approval');
  elsif v_requested is not null and v_approved<v_requested then
    v_blockers:=array_append(v_blockers,'stale_operator_approval');
  end if;

  if exists(select 1 from app_private.moderators where user_id=p_user_id)
     or exists(select 1 from app_private.event_organizers where user_id=p_user_id) then
    v_blockers:=array_append(v_blockers,'active_privileged_role');
  end if;

  if exists(
    select 1 from app_private.safety_reports r
    where r.reporter_id=p_user_id or r.subject_user_id=p_user_id
      or (r.target_type='user' and r.target_id=p_user_id)
      or (r.target_type='post' and r.target_id in
         (select id from public.community_posts where author_id=p_user_id))
      or (r.target_type='event' and r.target_id in
         (select id from public.sport_events where organizer_id=p_user_id))
  ) or exists(select 1 from app_private.moderation_audit where actor_id=p_user_id)
    or exists(select 1 from app_private.appeal_decision_audit where reviewer_id=p_user_id)
    or exists(select 1 from app_private.moderation_appeals where appellant_id=p_user_id)
  then
    v_blockers:=array_append(v_blockers,'moderation_retention_review_required');
  end if;

  -- Newly introduced moderation evidence has its own FK chains and cannot be
  -- discarded as an incidental side effect of account erasure.
  if exists(select 1 from app_private.incident_escalations e
     where e.escalated_by=p_user_id or e.closed_by=p_user_id)
    or exists(select 1 from app_private.incident_audit i
     where i.actor_id=p_user_id) then
    v_blockers:=array_append(v_blockers,'incident_retention_review_required');
  end if;

  if exists(
    select 1 from public.event_rsvps r
      join public.sport_events e on e.id=r.event_id
    where e.organizer_id=p_user_id and r.user_id<>p_user_id
      and e.starts_at>now()
  ) then
    v_blockers:=array_append(v_blockers,'active_event_participants');
  end if;

  -- Supabase Storage may not be installed in disposable PostgreSQL CI.
  -- In real Supabase, never directly DELETE FROM storage.objects.
  if to_regclass('storage.objects') is not null then
    execute 'select count(*) from storage.objects where owner_id=$1'
      into v_storage_count using p_user_id::text;
    if v_storage_count>0 then
      v_blockers:=array_append(v_blockers,'storage_objects_owned');
    end if;
  end if;

  return jsonb_build_object(
    'eligible',cardinality(v_blockers)=0,
    'blockers',to_jsonb(v_blockers),
    'requested_at',v_requested,
    'approved_at',v_approved,
    'owned_storage_objects',v_storage_count
  );
end;
$function$;

revoke execute on function app_private.moderator_incident_queue(integer) from public,anon,authenticated;
revoke execute on function public.moderator_incident_queue(integer) from public,anon,authenticated;
revoke execute on function app_private.moderator_escalate_report(uuid,text,text) from public,anon,authenticated;
revoke execute on function public.moderator_escalate_report(uuid,text,text) from public,anon,authenticated;
revoke execute on function app_private.moderator_review_escalation(uuid,text) from public,anon,authenticated;
revoke execute on function public.moderator_review_escalation(uuid,text) from public,anon,authenticated;

grant execute on function app_private.moderator_incident_queue(integer) to authenticated;
grant execute on function public.moderator_incident_queue(integer) to authenticated;
grant execute on function app_private.moderator_escalate_report(uuid,text,text) to authenticated;
grant execute on function public.moderator_escalate_report(uuid,text,text) to authenticated;
grant execute on function app_private.moderator_review_escalation(uuid,text) to authenticated;
grant execute on function public.moderator_review_escalation(uuid,text) to authenticated;
