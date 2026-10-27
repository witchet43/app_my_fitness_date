-- V8: Account privacy export and reversible deletion requests.
-- Explicitly does NOT delete auth.users. Final erase needs a privileged
-- account-deletion runbook and review of moderation/legal retention.

create table app_private.account_deletion_requests (
 user_id uuid primary key references auth.users(id) on delete cascade,
 requested_at timestamptz not null default now()
);
alter table app_private.account_deletion_requests enable row level security;
revoke all on app_private.account_deletion_requests from public,anon,authenticated;

create function app_private.account_is_active(p_user_id uuid)
returns boolean language sql security definer set search_path = '' stable
as $$
 select p_user_id is not null and not exists(
  select 1 from app_private.account_deletion_requests r where r.user_id=p_user_id
 );
$$;

-- Extend the existing social visibility function, preserving reciprocal blocks.
create or replace function app_private.can_see_social_user(p_other_id uuid)
returns boolean language sql security definer set search_path = '' stable
as $$
 select (select auth.uid()) is not null
  and app_private.account_is_active((select auth.uid()))
  and app_private.account_is_active(p_other_id)
  and not exists(
   select 1 from app_private.user_blocks b
   where (b.blocker_id=(select auth.uid()) and b.blocked_id=p_other_id)
      or (b.blocker_id=p_other_id and b.blocked_id=(select auth.uid()))
  );
$$;

-- Moderator privileges are inactive during a pending deletion request.
create or replace function app_private.is_moderator()
returns boolean language sql security definer set search_path = '' stable
as $
 select (select auth.uid()) is not null
  and app_private.account_is_active((select auth.uid()))
  and exists(
    select 1 from app_private.moderators m where m.user_id=(select auth.uid())
  );
$;

-- No new posts/profiles/RSVPs or changes to public profile while deletion is pending.
drop policy social_profiles_create_own on public.social_profiles;
create policy social_profiles_create_own on public.social_profiles
 for insert to authenticated with check(
  (select auth.uid())=user_id and app_private.account_is_active((select auth.uid()))
 );
drop policy social_profiles_edit_own on public.social_profiles;
create policy social_profiles_edit_own on public.social_profiles
 for update to authenticated
 using ((select auth.uid())=user_id and app_private.account_is_active((select auth.uid())))
 with check ((select auth.uid())=user_id and app_private.account_is_active((select auth.uid())));

drop policy community_posts_create_own on public.community_posts;
create policy community_posts_create_own on public.community_posts
 for insert to authenticated with check(
  (select auth.uid())=author_id and app_private.account_is_active((select auth.uid()))
 );
drop policy event_rsvps_join_future_event on public.event_rsvps;
create policy event_rsvps_join_future_event on public.event_rsvps
 for insert to authenticated with check(
  (select auth.uid())=user_id and app_private.account_is_active((select auth.uid()))
  and exists(select 1 from public.sport_events e
    where e.id=event_id and e.starts_at>now())
 );

-- A pending deletion must block both new events and discovery actions.
drop policy sport_events_approved_organizer on public.sport_events;
create policy sport_events_approved_organizer on public.sport_events
 for insert to authenticated with check(
  (select auth.uid())=organizer_id
  and app_private.account_is_active((select auth.uid()))
  and app_private.is_event_organizer()
  and starts_at>now()
 );

create or replace function public.save_dating_setup(
  p_display_name text,p_city text,p_sports text[],p_dob date,
  p_gym_id uuid,p_mode text,p_weekly_slots jsonb,p_dating_enabled boolean
) returns void language plpgsql volatile security invoker set search_path = ''
as $$
begin
 if not app_private.account_is_active((select auth.uid())) then
  raise exception 'ACCOUNT_DELETION_PENDING' using errcode='P0001';
 end if;
 perform app_private.consume_dating_quota('settings',86400,12);
 perform app_private.save_dating_setup(
  p_display_name,p_city,p_sports,p_dob,p_gym_id,p_mode,p_weekly_slots,p_dating_enabled
 );
end;
$$;

create or replace function public.discover_dating_candidates(p_limit integer default 20)
returns table(user_id uuid,display_name text,city text,sports text[])
language plpgsql volatile security invoker set search_path = ''
as $$
begin
 if not app_private.account_is_active((select auth.uid())) then
  raise exception 'ACCOUNT_DELETION_PENDING' using errcode='P0001';
 end if;
 perform app_private.consume_dating_quota('discover',3600,30);
 return query
 select c.user_id,c.display_name,c.city,c.sports
 from app_private.discover_dating_candidates(p_limit) c
 where app_private.account_is_active(c.user_id);
end;
$$;

create function app_private.my_account_status()
returns jsonb language plpgsql security definer set search_path = '' stable
as $$
declare v_user uuid:=(select auth.uid()); v_at timestamptz;
begin
 if v_user is null then raise exception 'Sign-in required'; end if;
 select requested_at into v_at from app_private.account_deletion_requests
 where user_id=v_user;
 return jsonb_build_object('pending',v_at is not null,'requested_at',v_at,
   'earliest_review_at',case when v_at is not null then v_at+interval '7 days' end);
end;
$$;
create function public.my_account_status()
returns jsonb language sql security invoker set search_path = '' stable
as $$ select app_private.my_account_status(); $$;

-- An authenticated data export of only the caller's own records.
-- Technical snapshot, NOT yet a full portability report for managed Auth,
-- backups, server logs, or all audit/legal records.
create function app_private.my_account_export()
returns jsonb language plpgsql security definer set search_path = '' stable
as $$
declare v_user uuid:=(select auth.uid());
begin
 if v_user is null then raise exception 'Sign-in required'; end if;
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
             where dr.user_id=v_user)
 );
end;
$$;
create function public.my_account_export()
returns jsonb language sql security invoker set search_path = '' stable
as $$ select app_private.my_account_export(); $$;

create function app_private.request_account_deletion()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_user uuid:=(select auth.uid());
begin
 if v_user is null then raise exception 'Sign-in required'; end if;
 insert into app_private.account_deletion_requests(user_id)
 values(v_user) on conflict(user_id) do nothing;
 update app_private.dating_profiles
 set dating_enabled=false,updated_at=now()
 where user_id=v_user;
 return app_private.my_account_status();
end;
$$;
create function public.request_account_deletion()
returns jsonb language sql security invoker set search_path = ''
as $$ select app_private.request_account_deletion(); $$;

create function app_private.cancel_account_deletion()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_user uuid:=(select auth.uid());
begin
 if v_user is null then raise exception 'Sign-in required'; end if;
 delete from app_private.account_deletion_requests where user_id=v_user;
 -- Never silently reactivate Dating consent.
 return app_private.my_account_status();
end;
$$;
create function public.cancel_account_deletion()
returns jsonb language sql security invoker set search_path = ''
as $$ select app_private.cancel_account_deletion(); $$;

revoke execute on function app_private.account_is_active(uuid) from public,anon,authenticated;
revoke execute on function app_private.my_account_status() from public,anon,authenticated;
revoke execute on function app_private.my_account_export() from public,anon,authenticated;
revoke execute on function app_private.request_account_deletion() from public,anon,authenticated;
revoke execute on function app_private.cancel_account_deletion() from public,anon,authenticated;
revoke execute on function public.my_account_status() from public,anon,authenticated;
revoke execute on function public.my_account_export() from public,anon,authenticated;
revoke execute on function public.request_account_deletion() from public,anon,authenticated;
revoke execute on function public.cancel_account_deletion() from public,anon,authenticated;
grant execute on function app_private.account_is_active(uuid) to authenticated;
grant execute on function app_private.my_account_status() to authenticated;
grant execute on function app_private.my_account_export() to authenticated;
grant execute on function app_private.request_account_deletion() to authenticated;
grant execute on function app_private.cancel_account_deletion() to authenticated;
grant execute on function public.my_account_status() to authenticated;
grant execute on function public.my_account_export() to authenticated;
grant execute on function public.request_account_deletion() to authenticated;
grant execute on function public.cancel_account_deletion() to authenticated;
revoke execute on function public.save_dating_setup(text,text,text[],date,uuid,text,jsonb,boolean)
 from public,anon,authenticated;
revoke execute on function public.discover_dating_candidates(integer)
 from public,anon,authenticated;
grant execute on function public.save_dating_setup(text,text,text[],date,uuid,text,jsonb,boolean) to authenticated;
grant execute on function public.discover_dating_candidates(integer) to authenticated;
