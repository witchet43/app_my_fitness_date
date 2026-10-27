-- V18. Privacy minimization without silent deletion of evidence.
-- Technical retention threshold for *temporary dating throttle counters* only.
-- These records are not safety reports or legal evidence. Other retention
-- periods require policy approval; no automatic deletion of moderation material.

create index if not exists dating_request_counters_retention
 on app_private.dating_request_counters(bucket_start);

create table app_private.privacy_prune_audit(
 id uuid primary key default gen_random_uuid(),
 ticket text not null check(char_length(btrim(ticket)) between 12 and 100),
 dataset text not null check(dataset='dating_request_counters'),
 cutoff timestamptz not null,
 deleted_rows integer not null check(deleted_rows between 0 and 500),
 executed_at timestamptz not null default now()
);
alter table app_private.privacy_prune_audit enable row level security;
revoke all on app_private.privacy_prune_audit from public,anon,authenticated;
grant usage on schema app_private to service_role;
grant select,insert on app_private.privacy_prune_audit to service_role;
grant select,delete on app_private.dating_request_counters to service_role;

grant select on
 app_private.user_notifications,
 app_private.safety_reports,
 app_private.moderation_appeals,
 app_private.moderation_audit,
 app_private.incident_escalations,
 app_private.incident_audit,
 app_private.account_deletion_requests
 to service_role;

-- Even temporary telemetry is kept when a person participated in a case.
-- Release of evidentiary holds requires separate legal/human review.
create function app_private.counter_has_evidence_hold(p_user_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $hold$
 select exists(select 1 from app_private.safety_reports r
    where r.reporter_id=p_user_id or r.subject_user_id=p_user_id)
 or exists(select 1 from app_private.moderation_appeals a
    where a.appellant_id=p_user_id)
 or exists(select 1 from app_private.moderation_audit a
    where a.actor_id=p_user_id)
 or exists(select 1 from app_private.appeal_decision_audit a
    where a.reviewer_id=p_user_id)
 or exists(select 1 from app_private.incident_escalations e
    where e.escalated_by=p_user_id or e.closed_by=p_user_id)
 or exists(select 1 from app_private.incident_audit a
    where a.actor_id=p_user_id);
$hold$;
revoke execute on function app_private.counter_has_evidence_hold(uuid)
 from public,anon,authenticated;
grant execute on function app_private.counter_has_evidence_hold(uuid) to service_role;


-- Read-only inventory. Aggregated counts only; no identities or case details.
create function public.operator_privacy_inventory()
returns jsonb language plpgsql stable security invoker set search_path = ''
as $$
declare v_cutoff timestamptz:=now()-interval '30 days';
begin
 if current_user<>'service_role' then
   raise exception 'Access denied' using errcode='42501';
 end if;
 return jsonb_build_object(
  'dataset','privacy_inventory_v18',
  'generated_at',now(),
  'counters_cutoff',v_cutoff,
  'eligible_dating_counters',(select count(*) from app_private.dating_request_counters
    where bucket_start<v_cutoff
      and not app_private.counter_has_evidence_hold(user_id)),
  'held_dating_counters',(select count(*) from app_private.dating_request_counters
    where bucket_start<v_cutoff
      and app_private.counter_has_evidence_hold(user_id)),
  'retained_notifications',(select count(*) from app_private.user_notifications),
  'retained_safety_reports',(select count(*) from app_private.safety_reports),
  'retained_appeals',(select count(*) from app_private.moderation_appeals),
  'retained_moderation_audit',(select count(*) from app_private.moderation_audit),
  'retained_incident_escalations',(select count(*) from app_private.incident_escalations),
  'retained_incident_audit',(select count(*) from app_private.incident_audit),
  'pending_deletion_requests',(select count(*) from app_private.account_deletion_requests),
  'retention_policy','manual_review_required_for_evidence',
  'dry_run',true
 );
end;
$$;

-- Only the privileged operator can request a bounded purge; never schedule
-- automatically and never prune an event/report/appeal/notification/audit.
create function public.operator_prune_ephemeral_counters(
 p_ticket text,p_confirm text,p_limit integer default 500)
returns jsonb language plpgsql security invoker set search_path = ''
as $$
declare
 v_deleted integer;
 v_cutoff timestamptz:=now()-interval '30 days';
begin
 if current_user<>'service_role' then
   raise exception 'Access denied' using errcode='42501';
 end if;
 if p_ticket is null or char_length(btrim(p_ticket)) not between 12 and 100
    or p_confirm is distinct from 'PRUNE_EXPIRED_DATING_COUNTERS'
    or p_limit is null or p_limit not between 1 and 500 then
   raise exception 'Invalid retention authorization' using errcode='P0001';
 end if;
 with eligible as(
   select c.user_id,c.action,c.bucket_start
   from app_private.dating_request_counters c
   where c.bucket_start<v_cutoff
     and not app_private.counter_has_evidence_hold(c.user_id)
   order by c.bucket_start,c.user_id,c.action
   limit p_limit for update skip locked
 ), removed as(
   delete from app_private.dating_request_counters c using eligible e
   where c.user_id=e.user_id and c.action=e.action
     and c.bucket_start=e.bucket_start returning 1
 )
 select count(*)::integer into v_deleted from removed;

 insert into app_private.privacy_prune_audit(ticket,dataset,cutoff,deleted_rows)
 values(btrim(p_ticket),'dating_request_counters',v_cutoff,v_deleted);
 return jsonb_build_object(
   'deleted_dating_counters',v_deleted,
   'cutoff',v_cutoff,
   'ticket',btrim(p_ticket),
   'evidence_deleted',false,
   'remaining_eligible_dating_counters',(
     select count(*) from app_private.dating_request_counters
       where bucket_start<v_cutoff
         and not app_private.counter_has_evidence_hold(user_id))
 );
end;
$$;
revoke execute on function public.operator_privacy_inventory() from public,anon,authenticated;
revoke execute on function public.operator_prune_ephemeral_counters(text,text,integer)
 from public,anon,authenticated;
grant execute on function public.operator_privacy_inventory() to service_role;
grant execute on function public.operator_prune_ephemeral_counters(text,text,integer)
 to service_role;

create or replace function app_private.my_account_export()
returns jsonb language plpgsql security definer set search_path = '' stable
as $$
declare v_user uuid:=(select auth.uid());
begin
 if v_user is null or not exists(select 1 from auth.users where id=v_user) then
  raise exception 'Sign-in required' using errcode='42501';
 end if;
 return jsonb_build_object(
  'export_version',1,'exported_at',now(),
  'account',(select jsonb_build_object('id',id,'email',email,'created_at',created_at)
             from auth.users where id=v_user),
  'social_profile',(select to_jsonb(s) from public.social_profiles s where s.user_id=v_user),
  'dating_profile',(select to_jsonb(d) from app_private.dating_profiles d where d.user_id=v_user),
  'training_slots',coalesce((select jsonb_agg(to_jsonb(t)) from app_private.training_slots t
             where t.user_id=v_user),'[]'::jsonb),
  'posts',coalesce((select jsonb_agg(to_jsonb(p)) from public.community_posts p
             where p.author_id=v_user),'[]'::jsonb),
  'organized_events',coalesce((select jsonb_agg(to_jsonb(e)) from public.sport_events e
             where e.organizer_id=v_user),'[]'::jsonb),
  'event_rsvps',coalesce((select jsonb_agg(to_jsonb(r)) from public.event_rsvps r
             where r.user_id=v_user),'[]'::jsonb),
  'blocked_user_ids',coalesce((select jsonb_agg(b.blocked_id) from app_private.user_blocks b
             where b.blocker_id=v_user),'[]'::jsonb),
  'own_notifications',coalesce((select jsonb_agg(to_jsonb(n)) from app_private.user_notifications n
             where n.user_id=v_user),'[]'::jsonb),
  'reports_i_submitted',coalesce((select jsonb_agg(jsonb_build_object(
             'id',r.id,'target_type',r.target_type,'reason',r.reason,
             'details',r.details,'status',r.status,'created_at',r.created_at))
             from app_private.safety_reports r where r.reporter_id=v_user),'[]'::jsonb),
  'appeals_i_submitted',coalesce((select jsonb_agg(to_jsonb(a)) from app_private.moderation_appeals a
             where a.appellant_id=v_user),'[]'::jsonb),
  'deletion_request',(select to_jsonb(dr) from app_private.account_deletion_requests dr
             where dr.user_id=v_user),
  'age_review',(select jsonb_build_object(
      'approved',coalesce(v.revoked_at is null and v.expires_at>now(),false),
      'expires_at',v.expires_at,
      'review_reference_withheld',true)
      from app_private.adult_eligibility v where v.user_id=v_user),
  'retention_information',jsonb_build_object(
    'temporary_dating_counters_days',30,
    'moderation_evidence','manual_review_required',
    'notifications','manual_review_required',
    'backup_and_provider_logs','outside_this_export',
    'account_deletion_requires_operator_review',true)
 );
end;
$$;
