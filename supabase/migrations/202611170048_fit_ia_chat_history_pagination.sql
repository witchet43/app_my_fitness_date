-- Historic curated prompt snapshots + owner-only pagination for lifelong chat.
begin;
-- Legacy question messages were previously rendered from the editable bank.
-- Freeze the actual prompts in their own historical message rows.
update public.fit_ia_messages_v1 m
set body=left(concat_ws(' ',nullif(m.comment,''),q.prompt_es),1500),
    asked=q.prompt_en
from public.fit_ia_questions_v1 q
where m.kind='question' and m.question_id=q.id
  and m.body is null;

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
    else concat_ws(' ',nullif(m.comment,''),coalesce(m.body,q.prompt_es)) end,
  'text_en',case when m.kind='answer' then m.answer_en
    when m.kind='question' then coalesce(m.asked,q.prompt_en)
      else m.body end,
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

create or replace function public.fit_ia_chat_older_v3(
 p_pillar text,p_before bigint)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare u uuid:=auth.uid(); page jsonb; older boolean; first_id bigint;
begin
 if u is null then raise exception 'authentication_required' using errcode='28000';end if;
 if p_pillar not in ('move','live','relate') or p_before is null or p_before<1
 then raise exception 'invalid_page' using errcode='22023';end if;
 with chunk as (
  select * from public.fit_ia_messages_v1
  where user_id=u and pillar=p_pillar and id<p_before
  order by id desc limit 80
 )
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',m.id,'role',case when m.kind in ('answer','user_text')
      then 'user' else 'assistant' end,
  'kind',m.kind,'text',case
    when m.kind in ('user_text','assistant_text') then m.body
    when m.kind='answer' then coalesce(m.answer_es,m.answer_en,'')
    else coalesce(m.body,q.prompt_es) end,
  'text_en',case
    when m.kind='answer' then m.answer_en
    when m.kind='question' then coalesce(m.asked,q.prompt_en)
    else m.body end,
  'topic',coalesce(m.topic,q.topic),
  'quick_options',m.quick_options,'created_at',m.created_at
 ) order by m.id),'[]'::jsonb) into page
 from chunk m left join public.fit_ia_questions_v1 q on q.id=m.question_id;
 select min((element->>'id')::bigint) into first_id
 from jsonb_array_elements(page) element;
 select exists(select 1 from public.fit_ia_messages_v1
    where user_id=u and pillar=p_pillar and id<first_id)
 into older;
 return jsonb_build_object('messages',page,'has_more',coalesce(older,false));
end;$$;

revoke all on function public.fit_ia_chat_older_v3(text,bigint)
 from public,anon;
grant execute on function public.fit_ia_chat_older_v3(text,bigint)
 to authenticated;
commit;