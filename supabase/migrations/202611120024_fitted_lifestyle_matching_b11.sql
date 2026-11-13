-- B11: first real, owner-persisted lifestyle profile + server-gated dating core.
-- Never opens public romantic discovery. Independent age review, operator
-- moderation, privacy review and release must be approved externally.
-- No gym identifiers/times or partner-private lifestyle values leave RPCs.
begin;

create or replace function public.b11_safe_answers(p jsonb)
returns boolean language plpgsql immutable set search_path=''
as $$
declare e record; v text; allowed text[];
begin
 if p is null or jsonb_typeof(p)<>'object' or pg_column_size(p)>4096 then
   return false;
 end if;
 for e in select key,value from jsonb_each(p) loop
   if jsonb_typeof(e.value)<>'string' then return false; end if;
   v:=e.value #>> '{}';
   allowed:=case e.key
     when 'sport' then array['running','strength','cycling','hyrox','crossfit','boxing','yoga','pilates','barre','swimming','hiking','climbing','racket','walking','other']
     when 'frequency' then array['flexible','two_three','four_five','six_plus']
     when 'window' then array['early_morning','morning','midday','evening','flexible']
     when 'training_mode' then array['recreational','consistent','focused','competitive']
     when 'training_with' then array['solo','friends','partner','mixed']
     when 'competitions' then array['never','sometimes','regularly']
     when 'weekday' then array['home','sometimes_out','often_out']
     when 'sleep' then array['early_bird','flexible','night_owl']
     when 'alcohol' then array['prefer_not','none','occasional','social','frequent']
     when 'food' then array['prefer_not','unrestricted','vegetarian','vegan','other']
     when 'travel' then array['flexible','train_away','rest_and_disconnect']
     when 'intent' then array['long_term','open_to_serious','intentional','exploring']
     when 'together' then array['balanced','more_together','independent']
     when 'train_partner' then array['often','sometimes','rarely','separately']
     when 'active_importance' then array['not_required','nice_to_have','important']
     else null::text[]
   end;
   if allowed is null or not (v = any(allowed)) then return false; end if;
 end loop;
 return true;
end;
$$;
revoke all on function public.b11_safe_answers(jsonb) from public,anon;
grant execute on function public.b11_safe_answers(jsonb) to authenticated;

create table public.member_rhythm_b11(
 user_id uuid primary key references auth.users(id) on delete cascade,
 answers jsonb not null default '{}'::jsonb check(public.b11_safe_answers(answers)),
 additional_sports text[] not null default '{}'::text[]
   check(cardinality(additional_sports)<=7 and additional_sports <@ array['running','strength','cycling','hyrox','crossfit','boxing','yoga','pilates','barre','swimming','hiking','climbing','racket','walking','other']::text[]),
 weekends text[] not null default '{}'::text[]
   check(cardinality(weekends)<=6 and weekends <@ array['early_training','brunch','nightlife','outdoors','recovery','family']::text[]),
 interests text[] not null default '{}'::text[]
   check(cardinality(interests)<=10 and interests <@ array['music','art','writing','gaming','cooking','pets','concerts','outdoors','books','culture']::text[]),
 challenge text not null default '' check(char_length(challenge)<=100),
 weeknight text not null default '' check(char_length(weeknight)<=120),
 support text not null default '' check(char_length(support)<=120),
 updated_at timestamptz not null default now()
);
alter table public.member_rhythm_b11 enable row level security;
revoke all on public.member_rhythm_b11 from public,anon,authenticated;
grant select,insert,update,delete on public.member_rhythm_b11 to authenticated;

-- Consent is required on every read and write. Owner can never select a
-- different member's preferences, even by direct PostgREST calls.
create policy b11_rhythm_select on public.member_rhythm_b11
 for select to authenticated
 using (user_id=(select auth.uid()) and exists(
   select 1 from public.member_consents_v26 c
   where c.user_id=(select auth.uid()) and c.consent_kind='dating'
     and c.document_version='dating-v1'
 ));
create policy b11_rhythm_insert on public.member_rhythm_b11
 for insert to authenticated with check(
   user_id=(select auth.uid()) and exists(
     select 1 from public.member_consents_v26 c
     where c.user_id=(select auth.uid()) and c.consent_kind='dating'
       and c.document_version='dating-v1'
   )
 );
create policy b11_rhythm_update on public.member_rhythm_b11
 for update to authenticated
 using(user_id=(select auth.uid()))
 with check(user_id=(select auth.uid()) and exists(
   select 1 from public.member_consents_v26 c
   where c.user_id=(select auth.uid()) and c.consent_kind='dating'
     and c.document_version='dating-v1'
 ));
create policy b11_rhythm_delete on public.member_rhythm_b11
 for delete to authenticated using(user_id=(select auth.uid()));

create table app_private.fitdating_likes_b11(
 liker_id uuid not null references auth.users(id) on delete cascade,
 liked_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(liker_id,liked_id),check(liker_id<>liked_id)
);
create index fitdating_likes_recent_b11 on app_private.fitdating_likes_b11(liker_id,created_at);
create table app_private.fitdating_matches_b11(
 id uuid primary key default gen_random_uuid(),
 low_user uuid not null references auth.users(id) on delete cascade,
 high_user uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 unique(low_user,high_user),check(low_user<high_user)
);
create table app_private.fitdating_messages_b11(
 id uuid primary key default gen_random_uuid(),
 match_id uuid not null references app_private.fitdating_matches_b11(id) on delete cascade,
 sender_id uuid not null references auth.users(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 1 and 1200),
 created_at timestamptz not null default now()
);
create index fitdating_messages_match_b11
 on app_private.fitdating_messages_b11(match_id,created_at);
create table app_private.fitdating_reports_b11(
 id uuid primary key default gen_random_uuid(),
 match_id uuid not null references app_private.fitdating_matches_b11(id),
 reporter_id uuid not null references auth.users(id),
 reason text not null check(reason in ('harassment','spam','impersonation','unsafe','other')),
 detail text not null default '' check(char_length(detail)<=500),
 created_at timestamptz not null default now()
);
alter table app_private.fitdating_likes_b11 enable row level security;
alter table app_private.fitdating_matches_b11 enable row level security;
alter table app_private.fitdating_messages_b11 enable row level security;
alter table app_private.fitdating_reports_b11 enable row level security;
revoke all on app_private.fitdating_likes_b11,
 app_private.fitdating_matches_b11,app_private.fitdating_messages_b11,
 app_private.fitdating_reports_b11 from public,anon,authenticated;

-- Both sides need an independently vetted adult attestation, explicit dating
-- consent, closed-pilot admission and no pending deletion/suspension.
-- Saving B5 preferences leaves discovery OFF. This private transition is
-- the ONLY B11 way to activate, once ALL independent release gates are true.
create function app_private.b11_activation_ready(p_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select p_id is not null and app_private.b5_discovery_open()
   and app_private.adult_eligible(p_id)
   and app_private.account_is_active(p_id)
   and exists(select 1 from auth.users u
     where u.id=p_id and u.email_confirmed_at is not null)
   and not exists(select 1 from app_private.brand_administrators a
     where a.user_id=p_id and a.active)
   and exists(select 1 from app_private.community_pilot_b4 m
     where m.user_id=p_id and m.active)
   and exists(select 1 from app_private.fitdating_preferences_b5 p
     where p.user_id=p_id and p.participation_requested)
   and exists(select 1 from public.member_consents_v26 c
     where c.user_id=p_id and c.consent_kind='dating'
       and c.document_version='dating-v1')
   and exists(select 1 from public.member_profiles_v26 m
     where m.user_id=p_id and m.onboarding_complete
       and m.date_of_birth<=(current_date-interval '18 years')::date)
   and exists(select 1 from public.member_rhythm_b11 r where r.user_id=p_id)
   and not exists(select 1 from app_private.community_suspensions_b4 s
     where s.user_id=p_id and s.active)
   and not exists(select 1 from app_private.community_deletion_requests_b4 d
     where d.user_id=p_id);
$$;

create function app_private.b11_activate(p_gym_id uuid,p_weekly_slots jsonb default '[]'::jsonb)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=(select auth.uid());
 mode_value text; sport_values text[];
 name_value text; city_value text; dob_value date;
begin
 if me is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
   or not app_private.b11_activation_ready(me)
 then return 'not_eligible'; end if;
 -- Legacy gym fixtures were created for SQL tests, not real people.
 if p_gym_id is null or not exists (
   select 1 from public.gyms g where g.id=p_gym_id
     and g.name !~* '^[[:space:]]*Gym Demo'
 ) then return 'gym_unavailable'; end if;
 select p.gym_privacy_mode,p.sports into mode_value,sport_values
 from app_private.fitdating_preferences_b5 p where p.user_id=me;
 select p.display_name,p.city,p.date_of_birth
 into name_value,city_value,dob_value from public.member_profiles_v26 p
 where p.user_id=me;
 if mode_value is null or name_value is null or city_value is null
   or dob_value is null or sport_values is null
 then return 'profile_required'; end if;
 if p_weekly_slots is null or jsonb_typeof(p_weekly_slots)<>'array'
   or jsonb_array_length(p_weekly_slots)>14
 then return 'invalid_schedule'; end if;
 if mode_value='same_gym_other_time'
    and jsonb_array_length(p_weekly_slots)=0
 then return 'schedule_required'; end if;
 if mode_value='other_gyms' and jsonb_array_length(p_weekly_slots)<>0
 then return 'invalid_schedule'; end if;
 perform app_private.save_dating_setup(
   name_value,city_value,sport_values,dob_value,
   p_gym_id,mode_value,p_weekly_slots,true);
 return 'activated';
end;
$$;

create function app_private.b11_member_eligible(p_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select p_id is not null and app_private.b5_discovery_open()
 and app_private.adult_eligible(p_id)
 and exists(select 1 from auth.users u where u.id=p_id and u.email_confirmed_at is not null)
 and not exists(select 1 from app_private.brand_administrators a
   where a.user_id=p_id and a.active)
 and exists(select 1 from app_private.community_pilot_b4 a
   where a.user_id=p_id and a.active)
 and exists(select 1 from app_private.fitdating_preferences_b5 p
   where p.user_id=p_id and p.participation_requested)
 and exists(select 1 from app_private.dating_profiles p
   where p.user_id=p_id and p.dating_enabled)
 and exists(select 1 from public.member_rhythm_b11 r where r.user_id=p_id)
 and exists(select 1 from public.member_consents_v26 c
   where c.user_id=p_id and c.consent_kind='dating'
     and c.document_version='dating-v1')
 and not exists(select 1 from app_private.community_suspensions_b4 s
   where s.user_id=p_id and s.active)
 and not exists(select 1 from app_private.community_deletion_requests_b4 d
   where d.user_id=p_id)
 and not exists(select 1 from app_private.account_deletion_requests d
   where d.user_id=p_id);
$$;

create function app_private.b11_pair_allowed(p_a uuid,p_b uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select p_a is not null and p_b is not null and p_a<>p_b
   and app_private.b11_member_eligible(p_a)
   and app_private.b11_member_eligible(p_b)
   and not exists(select 1 from app_private.user_blocks b
      where (b.blocker_id=p_a and b.blocked_id=p_b)
         or (b.blocker_id=p_b and b.blocked_id=p_a))
   and not exists(select 1 from public.community_blocks_b4 b
      where (b.blocker_id=p_a and b.blocked_id=p_b)
         or (b.blocker_id=p_b and b.blocked_id=p_a));
$$;

-- Only opaque, explainable reason codes leave private preferences; no
-- percentages, gym IDs, coordinates, schedules, DOB or full lifestyle answers.
create function app_private.b11_reasons(p_viewer uuid,p_subject uuid)
returns jsonb language sql stable security definer set search_path=''
as $$
 select jsonb_build_array(
  case when a.answers->>'sleep'=b.answers->>'sleep'
    then 'sleep_similar' else 'sleep_discuss' end,
  case when a.answers->>'weekday'=b.answers->>'weekday'
    then 'weekday_similar' else 'weekday_discuss' end,
  case when a.answers->>'intent'=b.answers->>'intent'
    then 'intent_aligned' else 'intent_discuss' end,
  case when a.answers->>'together'=b.answers->>'together'
    then 'autonomy_aligned' else 'autonomy_discuss' end,
  case when a.answers->>'frequency'=b.answers->>'frequency'
    then 'training_similar' else 'training_respect' end,
  case when a.answers->>'sport'=b.answers->>'sport'
    then 'sport_shared_low' else 'sport_different_ok' end)
 from public.member_rhythm_b11 a,public.member_rhythm_b11 b
 where a.user_id=p_viewer and b.user_id=p_subject
$$;

create function app_private.b11_candidates(p_limit integer default 10)
returns table(user_id uuid,display_name text,city text,sports text[],reason_codes jsonb)
language plpgsql volatile security definer set search_path=''
as $$
declare me uuid:=(select auth.uid());
begin
 if me is null or not app_private.b11_member_eligible(me)
   or p_limit is null or p_limit not between 1 and 10 then return; end if;
 perform app_private.consume_dating_quota('discover',3600,10);
 return query
 select c.user_id,c.display_name,c.city,c.sports,
   coalesce(app_private.b11_reasons(me,c.user_id),'[]'::jsonb)
 from app_private.discover_dating_candidates(30) c
 where app_private.b11_pair_allowed(me,c.user_id)
   and exists(select 1 from public.member_rhythm_b11 r where r.user_id=c.user_id)
   and exists(select 1 from public.member_rhythm_b11 r where r.user_id=me)
 order by c.user_id
 limit p_limit;
end;
$$;

create function app_private.b11_like(p_user_id uuid)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=(select auth.uid()); is_match boolean;
begin
 if me is null or not app_private.b11_pair_allowed(me,p_user_id) then
   return 'not_available'; end if;
 if not exists(select 1 from app_private.discover_dating_candidates(10) c
               where c.user_id=p_user_id) then return 'not_available'; end if;
 if (select count(*) from app_private.fitdating_likes_b11
     where liker_id=me and created_at>now()-interval '24 hours')>=20 then
   return 'rate_limited'; end if;
 insert into app_private.fitdating_likes_b11(liker_id,liked_id)
 values(me,p_user_id) on conflict do nothing;
 select exists(select 1 from app_private.fitdating_likes_b11 l
   where l.liker_id=p_user_id and l.liked_id=me) into is_match;
 if is_match then
   insert into app_private.fitdating_matches_b11(low_user,high_user)
   values(least(me,p_user_id),greatest(me,p_user_id))
   on conflict(low_user,high_user) do nothing;
 end if;
 return case when is_match then 'matched' else 'liked' end;
end;
$$;

create function app_private.b11_my_matches()
returns table(id uuid,other_user_id uuid,display_name text,created_at timestamptz)
language sql stable security definer set search_path=''
as $$
 select m.id,
   case when m.low_user=(select auth.uid()) then m.high_user else m.low_user end,
   p.display_name,m.created_at
 from app_private.fitdating_matches_b11 m
 join app_private.dating_profiles p on p.user_id=
   case when m.low_user=(select auth.uid()) then m.high_user else m.low_user end
 where ((select auth.uid())=m.low_user or (select auth.uid())=m.high_user)
   and app_private.b11_pair_allowed(m.low_user,m.high_user)
 order by m.created_at desc
 limit 50
$$;

create function app_private.b11_my_messages(p_match uuid)
returns table(id uuid,sender_id uuid,body text,created_at timestamptz)
language sql stable security definer set search_path=''
as $$
 select msg.id,msg.sender_id,msg.body,msg.created_at
 from app_private.fitdating_matches_b11 m
 join app_private.fitdating_messages_b11 msg on msg.match_id=m.id
 where m.id=p_match
   and ((select auth.uid())=m.low_user or (select auth.uid())=m.high_user)
   and app_private.b11_pair_allowed(m.low_user,m.high_user)
 order by msg.created_at desc
 limit 100
$$;

create function app_private.b11_send(p_match uuid,p_body text)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=(select auth.uid()); a uuid; b uuid;
begin
 if me is null or p_body is null or char_length(btrim(p_body)) not between 1 and 1200
   or p_match is null then return 'invalid'; end if;
 select low_user,high_user into a,b
 from app_private.fitdating_matches_b11 where id=p_match;
 if a is null or (me<>a and me<>b) or not app_private.b11_pair_allowed(a,b)
 then return 'not_available'; end if;
 if (select count(*) from app_private.fitdating_messages_b11
     where sender_id=me and created_at>now()-interval '1 hour')>=30
 then return 'rate_limited'; end if;
 insert into app_private.fitdating_messages_b11(match_id,sender_id,body)
 values(p_match,me,btrim(p_body));
 return 'sent';
end;
$$;

-- Reports remain possible for participants after the release gate closes.
-- This preserves the path to safety escalation; never return report contents.
create function app_private.b11_report(p_match uuid,p_reason text,p_detail text default '')
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=(select auth.uid()); a uuid; b uuid;
begin
 if me is null or p_match is null
  or p_reason not in ('harassment','spam','impersonation','unsafe','other')
  or char_length(coalesce(p_detail,''))>500
 then return 'invalid'; end if;
 select low_user,high_user into a,b from app_private.fitdating_matches_b11
 where id=p_match;
 if a is null or (me<>a and me<>b) then return 'not_available'; end if;
 if (select count(*) from app_private.fitdating_reports_b11
     where reporter_id=me and created_at>now()-interval '1 day')>=10
 then return 'rate_limited'; end if;
 insert into app_private.fitdating_reports_b11(match_id,reporter_id,reason,detail)
 values(p_match,me,p_reason,coalesce(p_detail,''));
 -- Reuse the EXISTING B4 moderation queue (owner/operator auditable),
 -- otherwise dating reports would be invisible to staffed moderators.
 insert into public.community_reports_b4(reporter_id,subject_id,reason,detail)
 values(me,case when me=a then b else a end,
   case when p_reason='impersonation' then 'other' else p_reason end,
   left(case when p_reason='impersonation'
     then '[Suplantación] ' || coalesce(p_detail,'')
     else coalesce(p_detail,'') end,300));
 insert into app_private.user_blocks(blocker_id,blocked_id)
 values(me,case when me=a then b else a end)
 on conflict do nothing;
 return 'reported_and_blocked';
end;
$$;

create function app_private.b11_date_ideas(p_match uuid)
returns text[] language plpgsql stable security definer set search_path=''
as $$
declare me uuid:=(select auth.uid()); a uuid; b uuid; active_sports text[];
begin
 select low_user,high_user into a,b from app_private.fitdating_matches_b11
 where id=p_match;
 if me is null or a is null or (me<>a and me<>b)
   or not app_private.b11_pair_allowed(a,b)
 then return '{}'::text[]; end if;
 select array_agg(distinct x) into active_sports
 from public.member_rhythm_b11 r,
 lateral unnest(array[r.answers->>'sport']) as x
 where r.user_id in (a,b);
 if active_sports && array['yoga','pilates']::text[]
 then return array['yoga_brunch','museum_walk']; end if;
 if active_sports && array['hiking','walking']::text[]
 then return array['walk_coffee','outdoor_market']; end if;
 return array['walk_coffee','museum_walk'];
end;
$$;

-- Exposed wrappers are invokers with no direct private table access. The
-- operational checks happen in app_private code and use the calling JWT.
create function public.fitdating_candidates_b11(p_limit integer default 10)
returns table(user_id uuid,display_name text,city text,sports text[],reason_codes jsonb)
language sql security invoker set search_path='' as $$
 select * from app_private.b11_candidates(p_limit)
$$;
create function public.fitdating_like_b11(p_user_id uuid)
returns text language sql security invoker set search_path='' as $$
 select app_private.b11_like(p_user_id)
$$;
create function public.fitdating_my_matches_b11()
returns table(id uuid,other_user_id uuid,display_name text,created_at timestamptz)
language sql security invoker set search_path='' as $$
 select * from app_private.b11_my_matches()
$$;
create function public.fitdating_my_messages_b11(p_match uuid)
returns table(id uuid,sender_id uuid,body text,created_at timestamptz)
language sql security invoker set search_path='' as $$
 select * from app_private.b11_my_messages(p_match)
$$;
create function public.fitdating_send_b11(p_match uuid,p_body text)
returns text language sql security invoker set search_path='' as $$
 select app_private.b11_send(p_match,p_body)
$$;
create function public.fitdating_report_b11(p_match uuid,p_reason text,p_detail text default '')
returns text language sql security invoker set search_path='' as $$
 select app_private.b11_report(p_match,p_reason,p_detail)
$$;
create function public.fitdating_date_ideas_b11(p_match uuid)
returns text[] language sql security invoker set search_path='' as $$
 select app_private.b11_date_ideas(p_match)
$$;

-- Catalog curation is ONLY for a verified AAL2 brand owner. The gym
-- name/city are public catalog values, never a user's private association.
create table app_private.b11_gym_catalog_audit(
 id bigint generated always as identity primary key,
 admin_id uuid not null references auth.users(id),
 gym_id uuid not null references public.gyms(id),
 created_at timestamptz not null default now()
);
alter table app_private.b11_gym_catalog_audit enable row level security;
revoke all on app_private.b11_gym_catalog_audit
 from public,anon,authenticated;

create function app_private.b11_admin_register_gym(p_name text,p_city text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare
 actor uuid := (select auth.uid());
 found uuid;
 name_value text := btrim(coalesce(p_name,''));
 city_value text := btrim(coalesce(p_city,''));
begin
 if actor is null or not app_private.is_brand_owner()
 then raise exception 'MFA administrator required' using errcode='42501'; end if;
 if char_length(name_value) not between 3 and 120
   or char_length(city_value) not between 2 and 100
   or name_value ~* '^[[:space:]]*(Gym Demo|Test|Prueba|Ficticio)'
 then raise exception 'Invalid curated venue'; end if;
 perform pg_advisory_xact_lock(
   hashtext('mfd-gym-catalog'),
   hashtext(lower(name_value)||'|'||lower(city_value)));
 select g.id into found from public.gyms g
 where lower(btrim(g.name))=lower(name_value)
   and lower(btrim(g.city))=lower(city_value);
 if found is not null then return found; end if;
 insert into public.gyms(name,city) values(name_value,city_value)
 returning id into found;
 insert into app_private.b11_gym_catalog_audit(admin_id,gym_id)
 values(actor,found);
 return found;
end;
$$;
create function public.admin_b11_register_gym(p_name text,p_city text)
returns uuid language sql security invoker set search_path=''
as $$
 select app_private.b11_admin_register_gym(p_name,p_city)
$$;
revoke all on function app_private.b11_admin_register_gym(text,text),
 public.admin_b11_register_gym(text,text) from public,anon,authenticated;
grant execute on function app_private.b11_admin_register_gym(text,text),
 public.admin_b11_register_gym(text,text) to authenticated;

-- Do not lie about discovery: all release controls plus the REAL private
-- gym activation and persisted rhythm must be satisfied, not just a toggle.
create or replace function public.fitdating_status_b5()
returns jsonb
language plpgsql stable security definer set search_path=''
as $$
declare
  v_user uuid := (select auth.uid());
  v_review boolean := false;
  v_consented boolean := false;
  v_member boolean := false;
  v_requested boolean := false;
  v_enabled boolean := false;
  v_intent text := 'serious';
  v_sports text[] := '{}'::text[];
  v_frequency text := 'flexible';
  v_mode text := 'other_gyms';
begin
  if v_user is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
     or not exists(select 1 from auth.users u where u.id=v_user
                   and u.email_confirmed_at is not null)
     or exists(select 1 from app_private.brand_administrators a
               where a.user_id=v_user and a.active)
  then
    return jsonb_build_object('status','not_available','enabled',false);
  end if;
  select coalesce((public.my_adult_eligibility()->>'approved')::boolean,false)
    into v_review;
  select exists(
    select 1 from public.member_consents_v26 c
    where c.user_id=v_user and c.consent_kind='dating'
      and c.document_version='dating-v1'
  ) into v_consented;
  select exists(
    select 1 from app_private.community_pilot_b4 m
    where m.user_id=v_user and m.active
  ) into v_member;
  select p.relationship_intent,p.sports,p.lifestyle_frequency,
         p.gym_privacy_mode,p.participation_requested
  into v_intent,v_sports,v_frequency,v_mode,v_requested
  from app_private.fitdating_preferences_b5 p
  where p.user_id=v_user;
  v_intent:=coalesce(v_intent,'serious');
  v_sports:=coalesce(v_sports,'{}'::text[]);
  v_frequency:=coalesce(v_frequency,'flexible');
  v_mode:=coalesce(v_mode,'other_gyms');
  v_requested:=coalesce(v_requested,false);
  v_enabled := app_private.b11_member_eligible(v_user);
  return jsonb_build_object(
    'status','available','enabled',v_enabled,
    'age_verified',v_review,'dating_consent',v_consented,
    'pilot_member',v_member,
    'independent_provider_ready',coalesce((select
      g.independently_verified_provider_live and
      g.independent_verification_audit_approved
    from app_private.fitdating_gate_b5 g where g.id),false),
    'discovery_release_ready',app_private.b5_discovery_open(),
    'gym_setup_required',app_private.b11_activation_ready(v_user) and not v_enabled,
    'participation_requested',v_requested,
    'relationship_intent',v_intent,
    'sports',to_jsonb(v_sports),
    'lifestyle_frequency',v_frequency,
    'gym_privacy_mode',v_mode);
end;
$$;

-- Authenticated entrypoint to activate a REAL, independently approved member.
-- The invoker wrapper cannot bypass private security/eligibility checks.
create function public.fitdating_activate_b11(
  p_gym_id uuid,p_weekly_slots jsonb default '[]'::jsonb)
returns text language sql security invoker set search_path=''
as $$
 select app_private.b11_activate(p_gym_id,p_weekly_slots)
$$;
revoke all on function app_private.b11_activation_ready(uuid),
 app_private.b11_activate(uuid,jsonb) from public,anon,authenticated;
grant execute on function app_private.b11_activate(uuid,jsonb)
 to authenticated;
revoke all on function public.fitdating_activate_b11(uuid,jsonb)
 from public,anon,authenticated;
grant execute on function public.fitdating_activate_b11(uuid,jsonb)
 to authenticated;

-- Explicit withdrawal clears the newly persisted lifestyle fields.
-- Match/chat evidence is retained under existing policy/erasure review until
-- legal retention is approved; no former participant remains discoverable.
create or replace function public.fitdating_disable_b5()
returns text language plpgsql security definer set search_path=''
as $$
declare v_user uuid:=(select auth.uid()); v_deleted integer:=0;
begin
 if v_user is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
 then return 'forbidden'; end if;
 update app_private.fitdating_preferences_b5
 set participation_requested=false,updated_at=now()
 where user_id=v_user;
 update app_private.dating_profiles
 set dating_enabled=false,updated_at=now()
 where user_id=v_user;
 delete from public.member_rhythm_b11 where user_id=v_user;
 delete from public.member_consents_v26
 where user_id=v_user and consent_kind='dating';
 get diagnostics v_deleted=row_count;
 if v_deleted>0 then
   insert into app_private.fitdating_consent_withdrawals_b5(user_id,document_version)
   values(v_user,'dating-v1');
 end if;
 return 'disabled';
end;
$$;
revoke all on function public.fitdating_disable_b5()
  from public,anon,authenticated;
grant execute on function public.fitdating_disable_b5()
  to authenticated;

revoke all on function app_private.b11_member_eligible(uuid),
 app_private.b11_pair_allowed(uuid,uuid),app_private.b11_reasons(uuid,uuid)
 from public,anon,authenticated;
revoke all on function app_private.b11_candidates(integer),
 app_private.b11_like(uuid),app_private.b11_my_matches(),
 app_private.b11_my_messages(uuid),app_private.b11_send(uuid,text),
 app_private.b11_report(uuid,text,text),app_private.b11_date_ideas(uuid)
 from public,anon,authenticated;
grant execute on function app_private.b11_candidates(integer),
 app_private.b11_like(uuid),app_private.b11_my_matches(),
 app_private.b11_my_messages(uuid),app_private.b11_send(uuid,text),
 app_private.b11_report(uuid,text,text),app_private.b11_date_ideas(uuid)
 to authenticated;
revoke all on function public.fitdating_candidates_b11(integer),
 public.fitdating_like_b11(uuid),public.fitdating_my_matches_b11(),
 public.fitdating_my_messages_b11(uuid),public.fitdating_send_b11(uuid,text),
 public.fitdating_report_b11(uuid,text,text),public.fitdating_date_ideas_b11(uuid)
 from public,anon,authenticated;
grant execute on function public.fitdating_candidates_b11(integer),
 public.fitdating_like_b11(uuid),public.fitdating_my_matches_b11(),
 public.fitdating_my_messages_b11(uuid),public.fitdating_send_b11(uuid,text),
 public.fitdating_report_b11(uuid,text,text),public.fitdating_date_ideas_b11(uuid)
 to authenticated;
commit;
