-- Fit-IA v3: free-text dialogue, idempotent turns, preserving the entire
-- existing multiple-choice history in place. Every row is owner-scoped by RLS.
begin;

alter table public.fit_ia_messages_v1
  drop constraint if exists fit_ia_messages_v1_kind_check;
alter table public.fit_ia_messages_v1
  add constraint fit_ia_messages_v1_kind_check
  check (kind in ('question','answer','user_text','assistant_text'));
alter table public.fit_ia_messages_v1
  add column if not exists body text,
  add column if not exists asked text,
  add column if not exists client_key uuid,
  add column if not exists reply_to bigint,
  add column if not exists topic text,
  add column if not exists meaningful boolean not null default false,
  add column if not exists quick_options jsonb,
  add column if not exists brief_es text,
  add column if not exists brief_en text,
  add column if not exists message_locale text;
alter table public.fit_ia_messages_v1
  add constraint fit_ia_v3_body_length check (body is null or char_length(body) between 1 and 1500),
  add constraint fit_ia_v3_brief_length check (
    (brief_es is null or char_length(brief_es)<=1200) and
    (brief_en is null or char_length(brief_en)<=1200)),
  add constraint fit_ia_v3_topic check (
    topic is null or topic ~ '^[a-z_]{3,40}$'),
  add constraint fit_ia_v3_locale check (
    message_locale is null or message_locale in ('es','en')),
  add constraint fit_ia_v3_options check (
    quick_options is null or
    (jsonb_typeof(quick_options)='array' and
      jsonb_array_length(quick_options)=4));
create unique index if not exists fit_ia_v3_client_unique
  on public.fit_ia_messages_v1(user_id,pillar,client_key)
  where client_key is not null and kind='user_text';
create unique index if not exists fit_ia_v3_reply_unique
  on public.fit_ia_messages_v1(user_id,pillar,reply_to)
  where reply_to is not null and kind='assistant_text';
create unique index if not exists fit_ia_v3_intro_unique
  on public.fit_ia_messages_v1(user_id,pillar)
  where reply_to is null and kind='assistant_text';

-- The old 300 questions stay editable in the administrator. They become
-- inspiration/coverage metadata, never the exact mandatory sequence.
create or replace function public.fit_ia_chat_state_v3(p_pillar text)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare u uuid:=auth.uid(); recent jsonb; guide jsonb;
 total int; latest record; brief jsonb; depth jsonb;
begin
 if u is null then raise exception 'authentication_required' using errcode='28000';end if;
 if p_pillar not in ('move','live','relate') then raise exception 'invalid_pillar' using errcode='22023';end if;
 select count(*) into total from public.fit_ia_messages_v1
 where user_id=u and pillar=p_pillar;
 select id,kind,quick_options,brief_es,brief_en,body,reply_to
 into latest from public.fit_ia_messages_v1
 where user_id=u and pillar=p_pillar
 order by id desc limit 1;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',m.id,'role',case when m.kind in ('answer','user_text') then 'user' else 'assistant' end,
  'kind',m.kind,'text',case
    when m.kind in ('user_text','assistant_text') then m.body
    when m.kind='answer' then coalesce(m.answer_es,m.answer_en,'')
    else concat_ws(' ',nullif(m.comment,''),q.prompt_es) end,
  'text_en',case when m.kind='answer' then m.answer_en
    when m.kind='question' then q.prompt_en else m.body end,
  'topic',coalesce(m.topic,q.topic),
  'quick_options',m.quick_options,
  'meaningful',m.meaningful,'created_at',m.created_at
 ) order by m.id),'[]'::jsonb) into recent from (
  select * from public.fit_ia_messages_v1
  where user_id=u and pillar=p_pillar order by id desc limit 120
 ) m left join public.fit_ia_questions_v1 q on q.id=m.question_id;
 select coalesce(jsonb_agg(jsonb_build_object(
   'topic',sample.topic,'es',sample.prompt_es,'en',sample.prompt_en)
   order by sample.topic),'[]'::jsonb) into guide
 from (
  select distinct on (q.topic) q.topic,q.prompt_es,q.prompt_en
  from public.fit_ia_questions_v1 q
  where q.pillar=p_pillar and q.enabled
  order by q.topic,random()
  limit 10
 ) sample;
 select jsonb_build_object('es',latestbrief.brief_es,
   'en',latestbrief.brief_en) into brief
 from (
  select m.brief_es,m.brief_en from public.fit_ia_messages_v1 m
  where m.user_id=u and m.pillar=p_pillar and
    m.kind='assistant_text' and m.brief_es is not null
  order by m.id desc limit 1
 ) latestbrief;
 depth=app_private.fit_ia_depth_v1(u,p_pillar);
 return jsonb_build_object(
  'pillar',p_pillar,'messages',recent,
  'total_messages',total,'has_more',total>120,
  'guide',guide,'depth',depth,
  'brief',coalesce(brief,'{}'::jsonb),
  'needs_response',latest.kind='user_text' or
    not exists(select 1 from public.fit_ia_messages_v1
      where user_id=u and pillar=p_pillar and kind='assistant_text'),
  'reply_to',case when latest.kind='user_text' then latest.id end,
  'quick_options',case when latest.kind='assistant_text'
    then latest.quick_options else null end);
end;$$;

-- User text is committed BEFORE the AI call, so provider outages cannot
-- lose what the user typed. Same client UUID = idempotent resubmission.
create or replace function public.fit_ia_chat_user_v3(
 p_pillar text,p_client_key uuid,p_text text,p_locale text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare u uuid:=auth.uid(); existing bigint; last_kind text;
 last_asked text; saved bigint;
begin
 if u is null then raise exception 'authentication_required' using errcode='28000';end if;
 if p_pillar not in ('move','live','relate') or p_client_key is null or
   p_locale not in ('es','en') or
   length(trim(coalesce(p_text,''))) not between 1 and 1500
 then raise exception 'invalid_message' using errcode='22023';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(u::text||p_pillar));
 select id into existing from public.fit_ia_messages_v1
 where user_id=u and pillar=p_pillar and client_key=p_client_key
 and kind='user_text';
 if existing is not null then
   return jsonb_build_object('status','saved','message_id',existing,'replayed',true);
 end if;
 select kind into last_kind from public.fit_ia_messages_v1
 where user_id=u and pillar=p_pillar and kind in ('user_text','assistant_text')
 order by id desc limit 1;
 if last_kind='user_text' then
   raise exception 'awaiting_agent_reply' using errcode='23514';
 end if;
 if (select count(*) from public.fit_ia_messages_v1
     where user_id=u and kind='user_text' and
       created_at>now()-interval '24 hours')>=120
 then raise exception 'rate_limited' using errcode='22023';end if;
 select body into last_asked from public.fit_ia_messages_v1
 where user_id=u and pillar=p_pillar and kind='assistant_text'
 order by id desc limit 1;
 insert into public.fit_ia_messages_v1(
 user_id,pillar,kind,body,asked,client_key,message_locale)
 values(u,p_pillar,'user_text',trim(p_text),left(last_asked,1000),
 p_client_key,p_locale) returning id into saved;
 return jsonb_build_object('status','saved','message_id',saved,'replayed',false);
end;$$;

-- Only the server (service_role) can commit a generated AI response. The
-- source question is always an AI-generated continuation, never a form item.
create or replace function public.fit_ia_chat_agent_v3(
 p_user uuid,p_pillar text,p_reply_to bigint,
 p_text text,p_locale text,p_options jsonb,
 p_topic text,p_meaningful boolean,p_brief_es text,p_brief_en text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare current_kind text; current_id bigint; existing_id bigint;
 saved_id bigint;
begin
 if auth.role()<>'service_role' then
   raise exception 'server_only' using errcode='42501';end if;
 if p_user is null or p_pillar not in ('move','live','relate') or
   p_locale not in ('es','en') or
   length(trim(coalesce(p_text,''))) not between 20 and 1500 or
   p_topic !~ '^[a-z_]{3,40}$' or
   jsonb_typeof(p_options)<>'array' or jsonb_array_length(p_options)<>4 or
   length(trim(coalesce(p_brief_es,'')))>1200 or
   length(trim(coalesce(p_brief_en,'')))>1200
 then raise exception 'invalid_generated_response' using errcode='22023';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(p_user::text||p_pillar));
 select id into existing_id from public.fit_ia_messages_v1
 where user_id=p_user and pillar=p_pillar and kind='assistant_text'
   and reply_to is not distinct from p_reply_to;
 if existing_id is not null then
   return jsonb_build_object('status','exists','id',existing_id);end if;
 select id,kind into current_id,current_kind from public.fit_ia_messages_v1
 where user_id=p_user and pillar=p_pillar and kind in ('user_text','assistant_text')
 order by id desc limit 1;
 if p_reply_to is null and current_id is not null
    or p_reply_to is not null and
       (current_kind<>'user_text' or current_id<>p_reply_to)
 then raise exception 'stale_turn' using errcode='23514';end if;
 if p_reply_to is not null then
  update public.fit_ia_messages_v1 set meaningful=coalesce(p_meaningful,false),
     topic=p_topic where id=p_reply_to and user_id=p_user
       and pillar=p_pillar and kind='user_text';
 end if;
 insert into public.fit_ia_messages_v1(
  user_id,pillar,kind,body,message_locale,reply_to,topic,
  quick_options,brief_es,brief_en)
 values(p_user,p_pillar,'assistant_text',trim(p_text),p_locale,p_reply_to,
  p_topic,p_options,nullif(trim(p_brief_es),''),
  nullif(trim(p_brief_en),'')) returning id into saved_id;
 return jsonb_build_object('status','saved','id',saved_id);
end;$$;

-- Attribute only MEANINGFUL user-created answers, not nonsense, to depth.
-- Include previously saved curated choices without double-counting.
create or replace function app_private.fit_ia_depth_v1(p_user uuid,p_pillar text)
returns jsonb language sql stable security definer set search_path=''
as $$
with all_evidence as (
 select a.topic from public.fit_ia_answers_v1 a
  where a.user_id=p_user and a.pillar=p_pillar
 union all
 select m.topic from public.fit_ia_messages_v1 m
  where m.user_id=p_user and m.pillar=p_pillar
   and m.kind='user_text' and m.meaningful and m.topic is not null
), stats as (
 select count(*)::int n,count(distinct topic)::int topics from all_evidence
), policy as (
 select medium_answers,medium_topics,strong_answers,strong_topics
 from public.fit_ia_depth_rules_v2 where pillar=p_pillar
)
select jsonb_build_object(
 'level',case when n>=coalesce(policy.strong_answers,10) and
   topics>=coalesce(policy.strong_topics,6) then 'strong'
   when n>=coalesce(policy.medium_answers,4) and
   topics>=coalesce(policy.medium_topics,3) then 'medium' else 'weak' end,
 'answered',n,'topics',topics,
 'next_focus',case when topics<coalesce(policy.medium_topics,3)
   then 'explore' when topics<coalesce(policy.strong_topics,6)
   then 'diversify' else 'deepen' end
) from stats left join policy on true;
$$;

create or replace function public.fit_ia_pillar_brief_v2(p_pillar text)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare u uuid:=auth.uid(); es text; en text; n int; topics int;
begin
 if u is null then raise exception 'authentication_required' using errcode='28000';end if;
 if p_pillar not in ('move','live','relate') then raise exception 'invalid_pillar';end if;
 select m.brief_es,m.brief_en into es,en
 from public.fit_ia_messages_v1 m
 where m.user_id=u and m.pillar=p_pillar and
   m.kind='assistant_text' and m.brief_es is not null
 order by m.id desc limit 1;
 if es is null then
  with relevant as(
   select distinct on(topic) choice_es,choice_en,topic
   from public.fit_ia_answers_v1 where user_id=u and pillar=p_pillar
   order by topic,answered_at desc
  )
  select string_agg(choice_es,' · '),string_agg(choice_en,' · ')
   into es,en from (select * from relevant limit 3) r;
  es=case when es is null then 'Aún no hay respuestas.' else 'Compartiste: '||es end;
  en=case when en is null then 'No answers yet.' else 'You shared: '||en end;
 end if;
 select count(*),count(distinct topic) into n,topics from(
  select topic from public.fit_ia_answers_v1 where user_id=u and pillar=p_pillar
  union all
  select topic from public.fit_ia_messages_v1 where user_id=u and pillar=p_pillar
   and kind='user_text' and meaningful
 ) s;
 return jsonb_build_object('es',es,'en',en,'count',n,'topics',topics);
end;$$;

-- Direct historical evidence panel includes typed responses and legacy data.
create or replace function public.fit_ia_answers_list_v2(p_pillar text)
returns jsonb language sql stable security definer set search_path=''
as $$
 select coalesce(jsonb_agg(jsonb_build_object(
   'question_id',s.question_id,'topic',s.topic,
   'question_es',s.question_es,'question_en',s.question_en,
   'answer_es',s.answer_es,'answer_en',s.answer_en)
 order by s.ts desc,s.sort_id desc),'[]'::jsonb)
 from (
   select a.question_id,a.topic,
      coalesce(a.prompt_snapshot_es,q.prompt_es) question_es,
      coalesce(a.prompt_snapshot_en,q.prompt_en) question_en,
      a.choice_es answer_es,a.choice_en answer_en,
      a.answered_at ts,0::bigint sort_id
   from public.fit_ia_answers_v1 a
   join public.fit_ia_questions_v1 q on q.id=a.question_id
   where a.user_id=(select auth.uid()) and a.pillar=p_pillar
   union all
   select m.id::text,m.topic,coalesce(m.asked,'') as question_es,
     coalesce(m.asked,'') as question_en,
     m.body as answer_es,m.body as answer_en,
     m.created_at ts,m.id
   from public.fit_ia_messages_v1 m where m.user_id=(select auth.uid())
     and m.pillar=p_pillar and m.kind='user_text'
 ) s;
$$;

-- Existing erasure action deletes all old + new chat rows because the
-- free-text dialogue is stored in the same owner-only table.
revoke all on function public.fit_ia_chat_state_v3(text),
 public.fit_ia_chat_user_v3(text,uuid,text,text),
 public.fit_ia_chat_agent_v3(uuid,text,bigint,text,text,jsonb,text,boolean,text,text)
 from public,anon,authenticated;
grant execute on function public.fit_ia_chat_state_v3(text),
 public.fit_ia_chat_user_v3(text,uuid,text,text)
 to authenticated;
grant execute on function public.fit_ia_chat_agent_v3(uuid,text,bigint,text,text,jsonb,text,boolean,text,text)
 to service_role;
commit;