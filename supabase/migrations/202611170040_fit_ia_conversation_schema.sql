-- Fit-IA v1: 3 private conversational profile pillars; no public answers.
-- Questions are curated public catalogue, responses private and owner-scoped.
begin;

create table if not exists public.fit_ia_questions_v1 (
  id text primary key check (id ~ '^(move|live|relate)_[0-9]{3}$'),
  pillar text not null check (pillar in ('move','live','relate')),
  topic text not null check (topic ~ '^[a-z_]{3,40}$'),
  prompt_es text not null check (char_length(prompt_es) between 15 and 250),
  prompt_en text not null check (char_length(prompt_en) between 15 and 250),
  choices_es jsonb not null check (
    jsonb_typeof(choices_es)='array' and jsonb_array_length(choices_es)=4),
  choices_en jsonb not null check (
    jsonb_typeof(choices_en)='array' and jsonb_array_length(choices_en)=4),
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists fit_ia_questions_pillar_topic
on public.fit_ia_questions_v1(pillar,topic) where enabled;

create table if not exists public.fit_ia_settings_v1 (
  user_id uuid primary key references auth.users(id) on delete cascade,
  ai_enabled boolean not null default false,
  consented_at timestamptz,
  last_generation_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.fit_ia_answers_v1 (
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id text not null references public.fit_ia_questions_v1(id),
  pillar text not null check (pillar in ('move','live','relate')),
  topic text not null,
  choice_key text not null check (choice_key ~ '^opt_[1-4]$'),
  choice_es text not null,
  choice_en text not null,
  answered_at timestamptz not null default now(),
  primary key(user_id,question_id)
);
create index if not exists fit_ia_answers_user_pillar
on public.fit_ia_answers_v1(user_id,pillar,answered_at desc);

create table if not exists public.fit_ia_sessions_v1(
  user_id uuid not null references auth.users(id) on delete cascade,
  pillar text not null check (pillar in ('move','live','relate')),
  current_question_id text references public.fit_ia_questions_v1(id),
  updated_at timestamptz not null default now(),
  primary key(user_id,pillar)
);
create table if not exists public.fit_ia_messages_v1 (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  pillar text not null check (pillar in ('move','live','relate')),
  kind text not null check (kind in ('question','answer')),
  question_id text references public.fit_ia_questions_v1(id),
  comment text not null default '' check (char_length(comment)<=240),
  answer_es text,
  answer_en text,
  created_at timestamptz not null default now()
);
create index if not exists fit_ia_messages_user_pillar
on public.fit_ia_messages_v1(user_id,pillar,id desc);

create table if not exists public.fit_ia_summaries_v1(
  user_id uuid primary key references auth.users(id) on delete cascade,
  summary_es text not null check (char_length(summary_es) between 100 and 1800),
  summary_en text not null check (char_length(summary_en) between 100 and 1800),
  revision text not null,
  updated_at timestamptz not null default now()
);

alter table public.fit_ia_questions_v1 enable row level security;
alter table public.fit_ia_settings_v1 enable row level security;
alter table public.fit_ia_answers_v1 enable row level security;
alter table public.fit_ia_sessions_v1 enable row level security;
alter table public.fit_ia_messages_v1 enable row level security;
alter table public.fit_ia_summaries_v1 enable row level security;

revoke all on public.fit_ia_questions_v1,public.fit_ia_settings_v1,
  public.fit_ia_answers_v1,public.fit_ia_sessions_v1,
  public.fit_ia_messages_v1,public.fit_ia_summaries_v1 from public,anon,authenticated;
grant select on public.fit_ia_questions_v1,public.fit_ia_settings_v1,
  public.fit_ia_answers_v1,public.fit_ia_sessions_v1,
  public.fit_ia_messages_v1,public.fit_ia_summaries_v1 to authenticated;

create policy fit_ia_catalog_read_v1 on public.fit_ia_questions_v1
  for select to authenticated using (enabled);
create policy fit_ia_settings_owner_read_v1 on public.fit_ia_settings_v1
  for select to authenticated using (user_id=(select auth.uid()));
create policy fit_ia_answers_owner_read_v1 on public.fit_ia_answers_v1
  for select to authenticated using (user_id=(select auth.uid()));
create policy fit_ia_sessions_owner_read_v1 on public.fit_ia_sessions_v1
  for select to authenticated using (user_id=(select auth.uid()));
create policy fit_ia_messages_owner_read_v1 on public.fit_ia_messages_v1
  for select to authenticated using (user_id=(select auth.uid()));
create policy fit_ia_summaries_owner_read_v1 on public.fit_ia_summaries_v1
  for select to authenticated using (user_id=(select auth.uid()));

-- Unique data owner only. External model use has a separate explicit consent.
create or replace function public.fit_ia_set_consent_v1(p_enabled boolean)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid();
begin
  if v_uid is null then raise exception 'authentication_required' using errcode='28000'; end if;
  if p_enabled is null then raise exception 'invalid_consent'; end if;
  insert into public.fit_ia_settings_v1(user_id,ai_enabled,consented_at)
  values(v_uid,p_enabled,case when p_enabled then now() end)
  on conflict(user_id) do update set
    ai_enabled=excluded.ai_enabled,
    consented_at=excluded.consented_at;
  return jsonb_build_object('ai_enabled',p_enabled);
end;
$$;

-- A normalized, transparent coverage assessment; not a score of the person.
create or replace function app_private.fit_ia_depth_v1(p_user uuid,p_pillar text)
returns jsonb language sql stable security definer set search_path=''
as $$
  with stats as (
    select count(*)::int n,count(distinct topic)::int topics
    from public.fit_ia_answers_v1
    where user_id=p_user and pillar=p_pillar
  )
  select jsonb_build_object(
    'level',case when n>=10 and topics>=6 then 'strong'
      when n>=4 and topics>=3 then 'medium' else 'weak' end,
    'answered',n,'topics',topics,
    'next_focus',case when n<4 then 'explore'
      when topics<6 then 'diversify' else 'deepen' end
  ) from stats;
$$;

-- Re-open the session with history + exactly one pending question.
create or replace function public.fit_ia_state_v1(p_pillar text)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_pending text; v_history jsonb; v_question jsonb;
  v_ai boolean; v_summary jsonb;
begin
  if v_uid is null then raise exception 'authentication_required' using errcode='28000'; end if;
  if p_pillar not in ('move','live','relate') then
    raise exception 'invalid_pillar' using errcode='22023';
  end if;
  select current_question_id into v_pending from public.fit_ia_sessions_v1
    where user_id=v_uid and pillar=p_pillar;
  select jsonb_build_object('id',id,'pillar',pillar,'topic',topic,
    'es',prompt_es,'en',prompt_en,'choices_es',choices_es,'choices_en',choices_en)
    into v_question
    from public.fit_ia_questions_v1 where id=v_pending and enabled;
  select coalesce(jsonb_agg(
    jsonb_build_object('id',m.id,'kind',m.kind,'comment',m.comment,
      'question_id',m.question_id,'answer_es',m.answer_es,
      'answer_en',m.answer_en,'es',q.prompt_es,'en',q.prompt_en)
      order by m.id), '[]'::jsonb)
    into v_history
    from (
      select * from public.fit_ia_messages_v1
      where user_id=v_uid and pillar=p_pillar order by id desc limit 36
    ) m left join public.fit_ia_questions_v1 q on q.id=m.question_id;
  select ai_enabled into v_ai from public.fit_ia_settings_v1 where user_id=v_uid;
  select jsonb_build_object('summary_es',summary_es,'summary_en',summary_en,
    'revision',revision,'updated_at',updated_at)
    into v_summary from public.fit_ia_summaries_v1 where user_id=v_uid;
  return jsonb_build_object('pillar',p_pillar,
    'ai_enabled',coalesce(v_ai,false),
    'depth',app_private.fit_ia_depth_v1(v_uid,p_pillar),
    'question',v_question,'messages',v_history,'summary',v_summary);
end;
$$;

-- Adaptive, random-within-topic selection. At most one unanswered question
-- per pillar; follow-up on a recent topic while discovering missing dimensions.
create or replace function public.fit_ia_next_v1(
  p_pillar text,p_reaction text default '')
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_existing text; v_next text;
  v_recent_topic text; v_comment text; v_choice_count int;
begin
  if v_uid is null then raise exception 'authentication_required' using errcode='28000'; end if;
  if p_pillar not in ('move','live','relate') then
    raise exception 'invalid_pillar' using errcode='22023';
  end if;
  insert into public.fit_ia_sessions_v1(user_id,pillar) values(v_uid,p_pillar)
    on conflict(user_id,pillar) do nothing;
  select current_question_id into v_existing
    from public.fit_ia_sessions_v1
    where user_id=v_uid and pillar=p_pillar for update;
  if v_existing is not null then return public.fit_ia_state_v1(p_pillar); end if;
  select topic into v_recent_topic from public.fit_ia_answers_v1
    where user_id=v_uid and pillar=p_pillar
    order by answered_at desc,question_id desc limit 1;
  select q.id into v_next from public.fit_ia_questions_v1 q
    where q.pillar=p_pillar and q.enabled and not exists(
      select 1 from public.fit_ia_answers_v1 a
      where a.user_id=v_uid and a.question_id=q.id
    )
    order by
      (select count(*) from public.fit_ia_answers_v1 a
         where a.user_id=v_uid and a.pillar=p_pillar and a.topic=q.topic)
      + case when q.topic=v_recent_topic then -0.6 else 0 end
      + random()*1.7
    limit 1;
  if v_next is not null then
    v_comment=left(regexp_replace(coalesce(p_reaction,''),'[\r\n\t]+',' ','g'),200);
    insert into public.fit_ia_messages_v1(
      user_id,pillar,kind,question_id,comment)
      values(v_uid,p_pillar,'question',v_next,v_comment);
    update public.fit_ia_sessions_v1
      set current_question_id=v_next,updated_at=now()
      where user_id=v_uid and pillar=p_pillar;
  end if;
  return public.fit_ia_state_v1(p_pillar);
end;
$$;

-- Multiple choice answers only. A selected choice is checked against the
-- authoritative bank; free-text and client-supplied descriptions are ignored.
create or replace function public.fit_ia_answer_v1(
  p_pillar text,p_question_id text,p_choice_key text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_session text;
  v_q public.fit_ia_questions_v1%rowtype; v_index int;
  v_es text; v_en text;
begin
  if v_uid is null then raise exception 'authentication_required' using errcode='28000'; end if;
  if p_pillar not in ('move','live','relate')
    or p_choice_key !~ '^opt_[1-4]$' then
    raise exception 'invalid_choice' using errcode='22023';
  end if;
  select current_question_id into v_session
    from public.fit_ia_sessions_v1
    where user_id=v_uid and pillar=p_pillar for update;
  if v_session is null or v_session<>p_question_id then
    raise exception 'stale_question' using errcode='23514';
  end if;
  select * into v_q from public.fit_ia_questions_v1
    where id=p_question_id and pillar=p_pillar and enabled;
  if not found then raise exception 'invalid_question' using errcode='23514'; end if;
  v_index=substring(p_choice_key from 5)::int-1;
  v_es=v_q.choices_es->v_index->>'label';
  v_en=v_q.choices_en->v_index->>'label';
  if coalesce(v_es,'')='' or coalesce(v_en,'')='' then
    raise exception 'invalid_choice' using errcode='22023'; end if;
  insert into public.fit_ia_answers_v1(
    user_id,question_id,pillar,topic,choice_key,choice_es,choice_en)
    values(v_uid,p_question_id,p_pillar,v_q.topic,p_choice_key,v_es,v_en)
    on conflict(user_id,question_id) do nothing;
  if not found then raise exception 'already_answered' using errcode='23514';end if;
  insert into public.fit_ia_messages_v1(
    user_id,pillar,kind,question_id,answer_es,answer_en)
    values(v_uid,p_pillar,'answer',p_question_id,v_es,v_en);
  update public.fit_ia_sessions_v1
    set current_question_id=null,updated_at=now()
    where user_id=v_uid and pillar=p_pillar;
  return jsonb_build_object('status','saved','chosen_es',v_es,'chosen_en',v_en,
    'pillar',p_pillar,'topic',v_q.topic,
    'depth',app_private.fit_ia_depth_v1(v_uid,p_pillar));
end;
$$;

create or replace function public.fit_ia_overview_v1()
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_ai boolean;
begin
  if v_uid is null then raise exception 'authentication_required' using errcode='28000'; end if;
  select ai_enabled into v_ai from public.fit_ia_settings_v1 where user_id=v_uid;
  return jsonb_build_object('move',app_private.fit_ia_depth_v1(v_uid,'move'),
    'live',app_private.fit_ia_depth_v1(v_uid,'live'),
    'relate',app_private.fit_ia_depth_v1(v_uid,'relate'),
    'ai_enabled',coalesce(v_ai,false));
end;
$$;

-- Summaries see only selected labels and catalog questions, never private
-- addresses, locations, exact schedules, user-generated content or photos.
create or replace function public.fit_ia_summary_context_v1()
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_ai boolean; v_data jsonb; v_revision text;
begin
  if v_uid is null then raise exception 'authentication_required' using errcode='28000'; end if;
  select ai_enabled into v_ai from public.fit_ia_settings_v1 where user_id=v_uid;
  if not coalesce(v_ai,false) then
    return jsonb_build_object('available',false,'reason','consent_required');
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'pillar',a.pillar,'topic',a.topic,
    'question_es',q.prompt_es,'answer_es',a.choice_es,
    'question_en',q.prompt_en,'answer_en',a.choice_en)
    order by a.answered_at,a.question_id),'[]'::jsonb)
    into v_data from public.fit_ia_answers_v1 a
      join public.fit_ia_questions_v1 q on q.id=a.question_id
    where a.user_id=v_uid;
  select md5(coalesce(string_agg(question_id||':'||choice_key,'|'
    order by question_id),'none'))
    into v_revision from public.fit_ia_answers_v1 where user_id=v_uid;
  return jsonb_build_object('available',true,'revision',v_revision,
    'answers',v_data,
    'count',jsonb_array_length(v_data));
end;
$$;

-- Atomic per-user model usage limiter. Avoid repeated paid completions.
create or replace function public.fit_ia_allow_summary_v1()
returns boolean language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_enabled boolean; v_last timestamptz;
begin
  if v_uid is null then return false; end if;
  insert into public.fit_ia_settings_v1(user_id) values(v_uid)
    on conflict(user_id) do nothing;
  select ai_enabled,last_generation_at into v_enabled,v_last
    from public.fit_ia_settings_v1 where user_id=v_uid for update;
  if not v_enabled or v_last>now()-interval '10 minutes'
    or (select count(*) from public.fit_ia_answers_v1 where user_id=v_uid)<5
  then return false; end if;
  update public.fit_ia_settings_v1 set last_generation_at=now()
    where user_id=v_uid;
  return true;
end;
$$;

create or replace function public.fit_ia_store_ai_summary_v1(
  p_user uuid,p_revision text,p_es text,p_en text)
returns text language plpgsql security definer set search_path=''
as $$
declare v_current text; v_consent boolean;
begin
  if auth.role()<>'service_role' then return 'forbidden'; end if;
  if char_length(coalesce(p_es,'')) not between 100 and 1800 or
     char_length(coalesce(p_en,'')) not between 100 and 1800 then
    return 'invalid'; end if;
  select ai_enabled into v_consent from public.fit_ia_settings_v1
    where user_id=p_user;
  select md5(coalesce(string_agg(question_id||':'||choice_key,'|'
    order by question_id),'none'))
    into v_current from public.fit_ia_answers_v1 where user_id=p_user;
  if not coalesce(v_consent,false) or v_current<>p_revision
    then return 'stale_or_no_consent'; end if;
  insert into public.fit_ia_summaries_v1(
    user_id,summary_es,summary_en,revision)
    values(p_user,p_es,p_en,p_revision)
  on conflict(user_id) do update set
    summary_es=excluded.summary_es,summary_en=excluded.summary_en,
    revision=excluded.revision,updated_at=now();
  return 'saved';
end;
$$;

-- User-controlled deletion, independent from account removal.
create or replace function public.fit_ia_delete_my_data_v1()
returns boolean language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid();
begin
  if v_uid is null then raise exception 'authentication_required' using errcode='28000'; end if;
  delete from public.fit_ia_messages_v1 where user_id=v_uid;
  delete from public.fit_ia_sessions_v1 where user_id=v_uid;
  delete from public.fit_ia_answers_v1 where user_id=v_uid;
  delete from public.fit_ia_summaries_v1 where user_id=v_uid;
  delete from public.fit_ia_settings_v1 where user_id=v_uid;
  return true;
end;
$$;

revoke all on function public.fit_ia_set_consent_v1(boolean),
  public.fit_ia_state_v1(text),public.fit_ia_next_v1(text,text),
  public.fit_ia_answer_v1(text,text,text),
  public.fit_ia_overview_v1(),public.fit_ia_summary_context_v1(),
  public.fit_ia_allow_summary_v1(),
  public.fit_ia_store_ai_summary_v1(uuid,text,text,text),
  public.fit_ia_delete_my_data_v1() from public,anon;
grant execute on function public.fit_ia_set_consent_v1(boolean),
  public.fit_ia_state_v1(text),public.fit_ia_next_v1(text,text),
  public.fit_ia_answer_v1(text,text,text),
  public.fit_ia_overview_v1(),public.fit_ia_summary_context_v1(),
  public.fit_ia_allow_summary_v1(),public.fit_ia_delete_my_data_v1()
  to authenticated;
revoke all on function public.fit_ia_store_ai_summary_v1(uuid,text,text,text)
  from authenticated;
grant execute on function public.fit_ia_store_ai_summary_v1(uuid,text,text,text)
  to service_role;

comment on table public.fit_ia_answers_v1 is
  'Private selected statements only. Not automatically shared, matched or public.';
comment on function app_private.fit_ia_depth_v1(uuid,text) is
  'Depth coverage (weak/medium/strong), never a quality judgment or percentage';
commit;
