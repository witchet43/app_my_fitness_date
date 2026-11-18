-- V9: Operator-only deletion preflight. Destructive Auth action is deliberately
-- absent from SQL; only the Auth Admin API may perform the final deletion.
-- This procedure is never callable from a normal user session.
create table app_private.erasure_approvals(
  user_id uuid primary key references auth.users(id) on delete cascade,
  ticket text not null unique check(char_length(btrim(ticket)) between 10 and 100),
  reviewer_note text not null check(char_length(btrim(reviewer_note)) between 15 and 500),
  approved_at timestamptz not null default now()
);
alter table app_private.erasure_approvals enable row level security;
revoke all on app_private.erasure_approvals from public,anon,authenticated;

create function app_private.erasure_preflight(p_user_id uuid,p_ticket text)
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

-- The private function is callable only by the service role. Neither
-- authenticated users nor moderators can approve or inspect other accounts.
revoke execute on function app_private.erasure_preflight(uuid,text) from public,anon,authenticated;
grant usage on schema app_private to service_role;
grant execute on function app_private.erasure_preflight(uuid,text) to service_role;
create function public.operator_erasure_preflight(p_user_id uuid,p_ticket text)
returns jsonb language sql security invoker set search_path = '' stable
as $$ select app_private.erasure_preflight(p_user_id,p_ticket); $$;
revoke execute on function public.operator_erasure_preflight(uuid,text) from public,anon,authenticated;
grant execute on function public.operator_erasure_preflight(uuid,text) to service_role;
