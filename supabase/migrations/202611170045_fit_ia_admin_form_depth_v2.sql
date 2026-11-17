-- Fit-IA admin-curated questions and configurable depth, with manual form
-- using the same owner-only answer store and explicit AAL2 admin authorization.
begin;
create table if not exists public.fit_ia_depth_rules_v2(
 pillar text primary key check (pillar in ('move','live','relate')),
 medium_answers smallint not null check (medium_answers between 1 and 50),
 medium_topics smallint not null check (medium_topics between 1 and 10),
 strong_answers smallint not null check (strong_answers between 2 and 100),
 strong_topics smallint not null check (strong_topics between 2 and 10),
 updated_at timestamptz not null default now(),
 updated_by uuid references auth.users(id),
 constraint depth_strict_increase check(
   strong_answers>medium_answers and strong_topics>medium_topics
 )
);
insert into public.fit_ia_depth_rules_v2
(pillar,medium_answers,medium_topics,strong_answers,strong_topics)
values ('move',4,3,10,6),('live',4,3,10,6),('relate',4,3,10,6)
on conflict(pillar) do nothing;
alter table public.fit_ia_depth_rules_v2 enable row level security;
revoke all on public.fit_ia_depth_rules_v2 from public,anon,authenticated;
grant select on public.fit_ia_depth_rules_v2 to authenticated;
create policy fit_ia_depth_rules_owner_read_v2 on public.fit_ia_depth_rules_v2
for select to authenticated using (true);
-- Rules are public product configuration, NOT private user answers;
-- only admins with validated MFA may write via RPC.

create or replace function app_private.fit_ia_depth_v1(p_user uuid,p_pillar text)
returns jsonb language sql stable security definer set search_path=''
as $$
with stats as (
 select count(*)::int n,count(distinct topic)::int topics
 from public.fit_ia_answers_v1
 where user_id=p_user and pillar=p_pillar
), policy as(
 select medium_answers,medium_topics,strong_answers,strong_topics
 from public.fit_ia_depth_rules_v2
 where pillar=p_pillar
)
select jsonb_build_object(
 'level',case when n>=coalesce(policy.strong_answers,10)
  and topics>=coalesce(policy.strong_topics,6) then 'strong'
  when n>=coalesce(policy.medium_answers,4)
  and topics>=coalesce(policy.medium_topics,3) then 'medium'
  else 'weak' end,
 'answered',n,'topics',topics,
 'next_focus',case when topics<coalesce(policy.medium_topics,3)
  then 'explore' when topics<coalesce(policy.strong_topics,6)
  then 'diversify' else 'deepen' end
) from stats left join policy on true;
$$;

-- Return up to 10 topic-diverse, unanswered questions in an ordinary form.
-- Do not modify the active conversation pending question.
create or replace function public.fit_ia_form_v2(p_pillar text)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare u uuid:=auth.uid(); items jsonb;
begin
 if u is null then raise exception 'authentication_required' using errcode='28000'; end if;
 if p_pillar not in ('move','live','relate') then raise exception 'invalid_pillar'; end if;
 with remaining as (
   select q.*,row_number() over(partition by q.topic order by random()) rn
   from public.fit_ia_questions_v1 q
   where q.pillar=p_pillar and q.enabled
    and not exists(select 1 from public.fit_ia_answers_v1 a
      where a.user_id=u and a.question_id=q.id)
 ), chosen as (
   select * from remaining order by rn,random() limit 10
 )
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'topic',topic,
  'es',prompt_es,'en',prompt_en,'choices_es',choices_es,
  'choices_en',choices_en)),'[]'::jsonb) into items from chosen;
 return jsonb_build_object('pillar',p_pillar,'questions',items,
   'depth',app_private.fit_ia_depth_v1(u,p_pillar));
end;$$;

-- Form mode uses an atomic multiple-choice submission; each entry must point
-- to an enabled published question from the chosen pillar.
-- No client-provided labels or user IDs are ever trusted.
create or replace function public.fit_ia_submit_form_v2(
 p_pillar text,p_answers jsonb)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare u uuid:=auth.uid(); r jsonb; q public.fit_ia_questions_v1%rowtype;
 idx int; key text; es text; en text; saved int:=0;
begin
 if u is null then raise exception 'authentication_required' using errcode='28000'; end if;
 if p_pillar not in ('move','live','relate') or
   jsonb_typeof(p_answers) is distinct from 'array' or
   jsonb_array_length(p_answers) not between 1 and 10 then
   raise exception 'invalid_form' using errcode='22023';
 end if;
 if (select count(distinct item->>'question_id')
     from jsonb_array_elements(p_answers) item)<>jsonb_array_length(p_answers) then
   raise exception 'duplicate_question' using errcode='22023';
 end if;
 for r in select value from jsonb_array_elements(p_answers) loop
   key=r->>'choice_key';
   if key is null or key!~'^opt_[1-4]$' then
     raise exception 'invalid_choice' using errcode='22023'; end if;
   select * into q from public.fit_ia_questions_v1
    where id=r->>'question_id' and pillar=p_pillar and enabled;
   if not found then raise exception 'question_not_available' using errcode='22023'; end if;
   if exists(select 1 from public.fit_ia_answers_v1
        where user_id=u and question_id=q.id) then
     raise exception 'already_answered' using errcode='23514'; end if;
   idx=substring(key from 5)::int-1;
   es=q.choices_es->idx->>'label'; en=q.choices_en->idx->>'label';
   if es is null or en is null then raise exception 'invalid_choice';end if;
   insert into public.fit_ia_answers_v1
     (user_id,question_id,pillar,topic,choice_key,choice_es,choice_en)
     values(u,q.id,p_pillar,q.topic,key,es,en);
   insert into public.fit_ia_messages_v1
     (user_id,pillar,kind,question_id,answer_es,answer_en)
     values(u,p_pillar,'answer',q.id,es,en);
   update public.fit_ia_sessions_v1 set current_question_id=null,updated_at=now()
     where user_id=u and pillar=p_pillar and current_question_id=q.id;
   saved=saved+1;
 end loop;
 return jsonb_build_object('saved',saved,'depth',
   app_private.fit_ia_depth_v1(u,p_pillar));
end;$$;

-- Full, private answers for current user's right-hand summary.
create or replace function public.fit_ia_answers_list_v2(p_pillar text)
returns jsonb language sql stable security definer set search_path=''
as $$
 select coalesce(jsonb_agg(jsonb_build_object('question_id',a.question_id,
    'topic',a.topic,'question_es',q.prompt_es,'question_en',q.prompt_en,
    'answer_es',a.choice_es,'answer_en',a.choice_en)
    order by a.answered_at desc,a.question_id desc),'[]'::jsonb)
 from public.fit_ia_answers_v1 a
 join public.fit_ia_questions_v1 q on q.id=a.question_id
 where a.user_id=(select auth.uid()) and a.pillar=p_pillar
   and p_pillar in ('move','live','relate');
$$;
-- This RPC is safe only for authenticated owner; no user_id argument.
-- Returns a small factual sentence built exclusively from selected answers.
create or replace function public.fit_ia_pillar_brief_v2(p_pillar text)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare u uuid:=auth.uid(); es text; en text; n int; topics int;
begin
 if u is null then raise exception 'authentication_required' using errcode='28000'; end if;
 if p_pillar not in ('move','live','relate') then raise exception 'invalid_pillar'; end if;
 with relevant as (
 select distinct on (topic) choice_es,choice_en,topic
 from public.fit_ia_answers_v1 where user_id=u and pillar=p_pillar
 order by topic,answered_at desc
 ), top_three as (
 select choice_es,choice_en from relevant order by topic limit 3
 )
 select string_agg(choice_es,' · '),string_agg(choice_en,' · ')
 into es,en from top_three;
 select count(*),count(distinct topic) into n,topics
 from public.fit_ia_answers_v1 where user_id=u and pillar=p_pillar;
 return jsonb_build_object(
   'es',case when n=0 then 'Aún no hay respuestas. Comienza cuando quieras.'
    else 'Lo que has compartido hasta ahora: '||es||'.' end,
   'en',case when n=0 then 'No answers yet. Start when you feel like it.'
    else 'What you have shared so far: '||en||'.' end,
   'count',n,'topics',topics
 );
end;$$;

-- MFA-backed administration. Never rely on editable user_metadata/email.
create or replace function public.fit_ia_admin_list_v2(p_pillar text)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare records jsonb; rule jsonb;
begin
 if not app_private.is_brand_administrator(true) then
   raise exception 'admin_mfa_required' using errcode='42501'; end if;
 if p_pillar not in ('move','live','relate') then raise exception 'invalid_pillar';end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',id,'pillar',pillar,'topic',topic,
  'prompt_es',prompt_es,'prompt_en',prompt_en,
  'choices_es',choices_es,'choices_en',choices_en,'enabled',enabled)
  order by id),'[]'::jsonb) into records
 from public.fit_ia_questions_v1 where pillar=p_pillar;
 select to_jsonb(r)-'updated_by' into rule from public.fit_ia_depth_rules_v2 r
  where pillar=p_pillar;
 return jsonb_build_object('questions',records,'rule',rule);
end;$$;

create or replace function public.fit_ia_admin_save_question_v2(
 p_id text,p_topic text,p_prompt_es text,p_prompt_en text,
 p_choices_es jsonb,p_choices_en jsonb,p_enabled boolean)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_pillar text; i int;
begin
 if not app_private.is_brand_administrator(true) then
  raise exception 'admin_mfa_required' using errcode='42501';end if;
 select q.pillar into v_pillar from public.fit_ia_questions_v1 q where q.id=p_id;
 if v_pillar is null then raise exception 'unknown_question';end if;
 if p_topic is null or p_topic!~'^[a-z_]{3,40}$' or
  length(trim(coalesce(p_prompt_es,''))) not between 15 and 250 or
  length(trim(coalesce(p_prompt_en,''))) not between 15 and 250 or
  p_choices_es is null or p_choices_en is null or
  jsonb_typeof(p_choices_es)<>'array' or jsonb_typeof(p_choices_en)<>'array' or
  jsonb_array_length(p_choices_es)<>4 or jsonb_array_length(p_choices_en)<>4
 then raise exception 'invalid_question' using errcode='22023';end if;
 for i in 0..3 loop
  if p_choices_es->i->>'key'<>('opt_'||(i+1)::text) or
     p_choices_en->i->>'key'<>('opt_'||(i+1)::text) or
     length(trim(coalesce(p_choices_es->i->>'label',''))) not between 2 and 90 or
     length(trim(coalesce(p_choices_en->i->>'label',''))) not between 2 and 90
  then raise exception 'invalid_option' using errcode='22023';end if;
 end loop;
 if p_enabled is null then raise exception 'invalid_enabled';end if;
 if not p_enabled and (select count(*) from public.fit_ia_questions_v1
   where enabled and pillar=v_pillar)<=1 then
   raise exception 'at_least_one_question_required';end if;
 update public.fit_ia_questions_v1 set topic=p_topic,
  prompt_es=trim(p_prompt_es),prompt_en=trim(p_prompt_en),
  choices_es=p_choices_es,choices_en=p_choices_en,enabled=p_enabled
  where id=p_id;
 return jsonb_build_object('saved',true,'id',p_id);
end;$$;

create or replace function public.fit_ia_admin_save_depth_v2(
 p_pillar text,p_medium_answers int,p_medium_topics int,
 p_strong_answers int,p_strong_topics int)
returns jsonb language plpgsql security definer set search_path=''
as $$
begin
 if not app_private.is_brand_administrator(true) then
   raise exception 'admin_mfa_required' using errcode='42501';end if;
 if p_pillar not in ('move','live','relate') or
   p_medium_answers not between 1 and 50 or
   p_medium_topics not between 1 and 9 or
   p_strong_answers not between 2 and 100 or
   p_strong_topics not between 2 and 10 or
   p_strong_answers<=p_medium_answers or
   p_strong_topics<=p_medium_topics
 then raise exception 'invalid_depth_rule' using errcode='22023';end if;
 update public.fit_ia_depth_rules_v2 set
   medium_answers=p_medium_answers,medium_topics=p_medium_topics,
   strong_answers=p_strong_answers,strong_topics=p_strong_topics,
   updated_at=now(),updated_by=auth.uid()
   where pillar=p_pillar;
 return jsonb_build_object('saved',true);
end;$$;
-- Restrict API surface with explicit EXECUTE grants only.
revoke all on function public.fit_ia_form_v2(text),
 public.fit_ia_submit_form_v2(text,jsonb),
 public.fit_ia_answers_list_v2(text),
 public.fit_ia_pillar_brief_v2(text),
 public.fit_ia_admin_list_v2(text),
 public.fit_ia_admin_save_question_v2(text,text,text,text,jsonb,jsonb,boolean),
 public.fit_ia_admin_save_depth_v2(text,integer,integer,integer,integer)
 from public,anon;
grant execute on function public.fit_ia_form_v2(text),
 public.fit_ia_submit_form_v2(text,jsonb),
 public.fit_ia_answers_list_v2(text),
 public.fit_ia_pillar_brief_v2(text),
 public.fit_ia_admin_list_v2(text),
 public.fit_ia_admin_save_question_v2(text,text,text,text,jsonb,jsonb,boolean),
 public.fit_ia_admin_save_depth_v2(text,integer,integer,integer,integer)
 to authenticated;
commit;