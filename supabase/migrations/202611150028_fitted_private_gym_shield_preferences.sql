-- Fitted v28: private training-place windows and configurable gym boundaries.
-- This is preference storage, NOT a grant to reveal gym data or launch dating.
begin;

create table if not exists app_private.fitted_shield_preferences_v28(
  user_id uuid primary key references auth.users(id) on delete cascade,
  match_mode text not null default 'exclude_same_gym'
    check(match_mode in ('exclude_same_gym','different_time','include_same_time')),
  updated_at timestamptz not null default now()
);
create table if not exists app_private.fitted_training_windows_v28(
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id uuid not null references public.member_training_places_v26(id)
    on delete cascade,
  weekday smallint not null check(weekday between 0 and 6),
  window_code text not null check(window_code in
    ('early','morning','midday','evening')),
  primary key(user_id,place_id,weekday,window_code)
);
create index if not exists fitted_training_windows_owner_v28
  on app_private.fitted_training_windows_v28(user_id,place_id);

alter table app_private.fitted_shield_preferences_v28 enable row level security;
alter table app_private.fitted_training_windows_v28 enable row level security;
revoke all on app_private.fitted_shield_preferences_v28,
  app_private.fitted_training_windows_v28 from public,anon,authenticated;

create or replace function public.fitted_shield_get_v28()
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare me uuid:=(select auth.uid());
begin
  if me is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
     or not exists(select 1 from public.member_profiles_v26 p
                   where p.user_id=me)
  then
    return jsonb_build_object('status','not_available');
  end if;
  return jsonb_build_object(
    'status','ok',
    'mode',coalesce((select s.match_mode
      from app_private.fitted_shield_preferences_v28 s
      where s.user_id=me),'exclude_same_gym'),
    'windows',coalesce((select jsonb_agg(
      jsonb_build_object('place_id',w.place_id,'day',w.weekday,
        'window',w.window_code)
      order by w.place_id,w.weekday,w.window_code)
      from app_private.fitted_training_windows_v28 w
      where w.user_id=me),'[]'::jsonb),
    -- A/B legacy dating gates remain intact. C is a stored privacy choice,
    -- not permission to show exact same-gym+time members until safety review.
    'matching_live',false
  );
end;
$$;

create or replace function public.fitted_shield_save_v28(
  p_mode text,p_windows jsonb
)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare
  me uuid:=(select auth.uid());
  e jsonb;
  candidate text;
  item_place uuid;
  item_day integer;
  item_window text;
begin
  if me is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
     or not exists(select 1 from public.member_profiles_v26 p
       where p.user_id=me)
  then return jsonb_build_object('status','not_available'); end if;
  if p_mode is null or p_mode not in
      ('exclude_same_gym','different_time','include_same_time')
     or p_windows is null or jsonb_typeof(p_windows)<>'array'
     or jsonb_array_length(p_windows)>28
  then return jsonb_build_object('status','invalid'); end if;
  -- Validate ALL entries before mutating either table.
  for e in select value from jsonb_array_elements(p_windows)
  loop
    if jsonb_typeof(e)<>'object'
      or (select count(*) from jsonb_object_keys(e))<>3
    then return jsonb_build_object('status','invalid'); end if;
    candidate:=e->>'place_id';
    if candidate is null or
      candidate !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then return jsonb_build_object('status','invalid'); end if;
    item_place:=candidate::uuid;
    if not exists(select 1 from public.member_training_places_v26 p
                  where p.id=item_place and p.user_id=me)
    then return jsonb_build_object('status','invalid_place'); end if;
    if jsonb_typeof(e->'day')<>'number' or (e->>'day') !~ '^[0-6]$'
    then return jsonb_build_object('status','invalid'); end if;
    item_day:=(e->>'day')::integer;
    item_window:=e->>'window';
    if item_window not in ('early','morning','midday','evening')
    then return jsonb_build_object('status','invalid'); end if;
  end loop;

  insert into app_private.fitted_shield_preferences_v28(
    user_id,match_mode,updated_at
  ) values(me,p_mode,now())
  on conflict(user_id) do update
    set match_mode=excluded.match_mode,updated_at=now();
  delete from app_private.fitted_training_windows_v28 where user_id=me;
  insert into app_private.fitted_training_windows_v28(
      user_id,place_id,weekday,window_code)
  select distinct me,(v.value->>'place_id')::uuid,
    (v.value->>'day')::smallint,v.value->>'window'
  from jsonb_array_elements(p_windows) as v(value);
  return jsonb_build_object('status','saved','mode',p_mode,
    'windows_saved',(select count(*) from
      app_private.fitted_training_windows_v28 w where w.user_id=me),
    'matching_live',false);
end;
$$;
revoke all on function public.fitted_shield_get_v28(),
  public.fitted_shield_save_v28(text,jsonb) from public,anon,authenticated;
grant execute on function public.fitted_shield_get_v28(),
  public.fitted_shield_save_v28(text,jsonb) to authenticated;

commit;
