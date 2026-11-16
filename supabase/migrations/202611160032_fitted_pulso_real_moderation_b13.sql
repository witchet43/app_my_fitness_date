-- FITTED B13: private human moderation, appeal, deletion and retention.
-- No public reputation. A record is a subjective signal, never a proved lie.
begin;

create table app_private.fitted_signal_moderation_audit_b13 (
  id uuid primary key default gen_random_uuid(),
  signal_id uuid not null references app_private.fitted_signals_b12(id) on delete cascade,
  moderator_id uuid references auth.users(id) on delete set null,
  prior_state text not null,
  next_state text not null,
  reason text not null check(char_length(btrim(reason)) between 5 and 500),
  acted_at timestamptz not null default now()
);
create index fitted_signal_audit_idx_b13
  on app_private.fitted_signal_moderation_audit_b13(signal_id,acted_at);
alter table app_private.fitted_signal_moderation_audit_b13 enable row level security;
revoke all on app_private.fitted_signal_moderation_audit_b13
  from public,anon,authenticated;

create table app_private.fitted_signal_appeals_b13 (
  id uuid primary key default gen_random_uuid(),
  signal_id uuid not null references app_private.fitted_signals_b12(id) on delete cascade,
  subject_id uuid not null references auth.users(id) on delete cascade,
  statement text not null check(char_length(btrim(statement)) between 10 and 500),
  status text not null default 'pending'
    check(status in ('pending','resolved')),
  submitted_at timestamptz not null default now(),
  resolved_at timestamptz,
  unique(signal_id,subject_id)
);
create index fitted_signal_appeal_queue_b13
  on app_private.fitted_signal_appeals_b13(status,submitted_at);
alter table app_private.fitted_signal_appeals_b13 enable row level security;
revoke all on app_private.fitted_signal_appeals_b13 from public,anon,authenticated;

-- Authorize only an appointed moderator or an AAL2 brand administrator.
-- The owner account alone, without MFA, cannot decide reputation cases.
create function app_private.fitted_can_moderate_b13()
returns boolean language sql stable security definer set search_path=''
as $$
  select app_private.is_moderator() or public.brand_admin_session();
$$;
revoke all on function app_private.fitted_can_moderate_b13()
  from public,anon,authenticated;

create function public.fitted_moderation_queue_b13(p_limit integer default 30)
returns table(
  id uuid,dimension text,observation text,review_state text,
  author_id uuid,subject_id uuid,created_at timestamptz,
  appeal_note text)
language sql stable security definer set search_path=''
as $$
  select s.id,s.dimension,s.observation,s.moderation_state,
         s.author_id,s.subject_id,s.created_at,
         a.statement
    from app_private.fitted_signals_b12 s
    left join app_private.fitted_signal_appeals_b13 a
      on a.signal_id=s.id and a.status='pending'
   where app_private.fitted_can_moderate_b13()
     and s.moderation_state in ('pending','appealed')
   order by s.created_at asc
   limit least(greatest(coalesce(p_limit,30),1),50);
$$;

create function public.fitted_review_signal_b13(
  p_signal uuid,p_decision text,p_note text)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); previous text; next_state text;
begin
  if me is null or not app_private.fitted_can_moderate_b13()
  then return 'forbidden'; end if;
  if p_signal is null or p_decision not in ('approve','reject','remove')
    or p_note is null or char_length(btrim(p_note)) not between 5 and 500
  then return 'invalid'; end if;
  select s.moderation_state into previous
    from app_private.fitted_signals_b12 s
   where s.id=p_signal for update;
  if previous is null then return 'not_found'; end if;
  if previous not in ('pending','appealed','approved')
     or (previous='approved' and p_decision<>'remove')
  then return 'invalid_state'; end if;
  next_state:=case p_decision
    when 'approve' then 'approved'
    when 'reject' then 'rejected'
    else 'removed' end;
  update app_private.fitted_signals_b12
     set moderation_state=next_state where id=p_signal;
  update app_private.fitted_signal_appeals_b13
     set status='resolved',resolved_at=now()
   where signal_id=p_signal and status='pending';
  insert into app_private.fitted_signal_moderation_audit_b13(
    signal_id,moderator_id,prior_state,next_state,reason)
  values(p_signal,me,previous,next_state,btrim(p_note));
  return 'resolved';
end;
$$;

-- Only the subject sees their own approved/appealed observations, with
-- no reporter identity. Subject may appeal independently of active dating.
create function public.fitted_my_private_observations_b13()
returns table(
  id uuid,dimension text,observation text,
  review_state text,created_at timestamptz,appeal_pending boolean)
language sql stable security definer set search_path=''
as $$
  select s.id,s.dimension,s.observation,s.moderation_state,
         s.created_at,
         exists(select 1 from app_private.fitted_signal_appeals_b13 a
                where a.signal_id=s.id and a.status='pending')
    from app_private.fitted_signals_b12 s
   where s.subject_id=auth.uid()
     and s.moderation_state in ('approved','appealed')
     and exists(select 1 from app_private.fitted_pulse_consents_b12 c
       where c.user_id=auth.uid())
   order by s.created_at desc limit 50;
$$;

create function public.fitted_appeal_signal_b13(
  p_signal uuid,p_statement text)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); current_state text;
begin
  if me is null or p_signal is null or p_statement is null
    or char_length(btrim(p_statement)) not between 10 and 500
  then return 'invalid'; end if;
  select s.moderation_state into current_state
    from app_private.fitted_signals_b12 s
   where s.id=p_signal and s.subject_id=me for update;
  if current_state is null then return 'not_available'; end if;
  if current_state='appealed' then return 'already_appealed'; end if;
  if current_state<>'approved' then return 'not_available'; end if;
  insert into app_private.fitted_signal_appeals_b13(
    signal_id,subject_id,statement)
  values(p_signal,me,btrim(p_statement))
  on conflict(signal_id,subject_id)
    do update set statement=excluded.statement,status='pending',
      submitted_at=now(),resolved_at=null;
  update app_private.fitted_signals_b12
    set moderation_state='appealed' where id=p_signal;
  return 'appeal_requested';
end;
$$;

-- A user may retract their own subjective evaluation at any time;
-- the target cannot delete other people's reports except by withdrawal
-- of the separate reputation consent (existing B12 erasure semantics).
create function public.fitted_retract_signal_b13(p_signal uuid)
returns text language plpgsql security definer set search_path=''
as $$
begin
  if auth.uid() is null or p_signal is null then return 'invalid'; end if;
  delete from app_private.fitted_signals_b12
    where id=p_signal and author_id=auth.uid();
  return case when found then 'deleted' else 'not_available' end;
end;
$$;

-- Retention operation: callable only through trusted service owner.
-- Schedule/operate only after privacy counsel defines documented retention
-- and safety-preservation exceptions; never alter unrelated reports.
create function app_private.fitted_prune_older_than_b13(
  p_days integer default 180)
returns integer language plpgsql security definer set search_path=''
as $$
declare n integer;
begin
  if p_days<90 or p_days>365 then
    raise exception 'Retention policy out of approved range';
  end if;
  delete from app_private.fitted_signals_b12
    where created_at < now()-make_interval(days=>p_days)
      and moderation_state not in ('appealed');
  get diagnostics n=row_count;
  return n;
end;
$$;
revoke all on function app_private.fitted_prune_older_than_b13(integer)
  from public,anon,authenticated;

revoke all on function public.fitted_moderation_queue_b13(integer),
 public.fitted_review_signal_b13(uuid,text,text),
 public.fitted_my_private_observations_b13(),
 public.fitted_appeal_signal_b13(uuid,text),
 public.fitted_retract_signal_b13(uuid)
 from public,anon,authenticated;
grant execute on function public.fitted_moderation_queue_b13(integer),
 public.fitted_review_signal_b13(uuid,text,text),
 public.fitted_my_private_observations_b13(),
 public.fitted_appeal_signal_b13(uuid,text),
 public.fitted_retract_signal_b13(uuid)
 to authenticated;
commit;
