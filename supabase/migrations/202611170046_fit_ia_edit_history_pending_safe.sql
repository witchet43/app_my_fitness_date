-- Preserve answer evidence when an admin edits a published question.
begin;
alter table public.fit_ia_answers_v1
 add column if not exists prompt_snapshot_es text,
 add column if not exists prompt_snapshot_en text;
update public.fit_ia_answers_v1 a
  set prompt_snapshot_es=q.prompt_es,prompt_snapshot_en=q.prompt_en
  from public.fit_ia_questions_v1 q
  where q.id=a.question_id and a.prompt_snapshot_es is null;

create or replace function app_private.fit_ia_answer_snapshot_v2()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
 select q.prompt_es,q.prompt_en
 into new.prompt_snapshot_es,new.prompt_snapshot_en
 from public.fit_ia_questions_v1 q where q.id=new.question_id;
 if new.prompt_snapshot_es is null or new.prompt_snapshot_en is null then
   raise exception 'invalid_question' using errcode='22023';
 end if;
 return new;
end;$$;
drop trigger if exists fit_ia_answer_snapshot_v2 on public.fit_ia_answers_v1;
create trigger fit_ia_answer_snapshot_v2
 before insert on public.fit_ia_answers_v1
 for each row execute function app_private.fit_ia_answer_snapshot_v2();

create or replace function public.fit_ia_answers_list_v2(p_pillar text)
returns jsonb language sql stable security definer set search_path=''
as $$
 select coalesce(jsonb_agg(jsonb_build_object(
   'question_id',a.question_id,'topic',a.topic,
   'question_es',coalesce(a.prompt_snapshot_es,q.prompt_es),
   'question_en',coalesce(a.prompt_snapshot_en,q.prompt_en),
   'answer_es',a.choice_es,'answer_en',a.choice_en)
   order by a.answered_at desc,a.question_id desc),'[]'::jsonb)
 from public.fit_ia_answers_v1 a
 join public.fit_ia_questions_v1 q on q.id=a.question_id
 where a.user_id=(select auth.uid()) and a.pillar=p_pillar
   and p_pillar in ('move','live','relate');
$$;

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
  -- A question may have been disabled in the administrator catalogue
  -- while a user was away. Replace it safely, never strand the conversation.
  if v_existing is not null then
    if exists(select 1 from public.fit_ia_questions_v1
      where id=v_existing and enabled) and not exists(
      select 1 from public.fit_ia_answers_v1
      where user_id=v_uid and question_id=v_existing) then
      return public.fit_ia_state_v1(p_pillar);
    end if;
    update public.fit_ia_sessions_v1 set current_question_id=null,
      updated_at=now() where user_id=v_uid and pillar=p_pillar;
  end if;
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
commit;