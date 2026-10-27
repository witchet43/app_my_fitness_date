-- Real PostgreSQL integration tests: run against a throwaway database only.
insert into auth.users(id) values
 ('10000000-0000-4000-8000-000000000001'),
 ('10000000-0000-4000-8000-000000000002'),
 ('10000000-0000-4000-8000-000000000003'),
 ('10000000-0000-4000-8000-000000000004');

-- Public API must not be callable as anon.
set role anon;
do $$
begin
  if has_function_privilege(current_user,
    'public.discover_dating_candidates(integer)','EXECUTE') then
    raise exception 'anon can execute discovery';
  end if;
end $$;
reset role;

set role authenticated;
-- User A, training Monday 07:00–08:30, same-gym-other-time.
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
select public.save_dating_setup('Usuario A','Querétaro',array['Running'],date '1992-01-01',
  '00000000-0000-4000-8000-000000000001','same_gym_other_time',
  '[{"day":1,"startMinutes":420,"endMinutes":510}]'::jsonb,true);

-- User B, different gym: always eligible despite same clock time.
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
select public.save_dating_setup('Usuario B','Querétaro',array['Pesas'],date '1992-01-01',
  '00000000-0000-4000-8000-000000000002','other_gyms',
  '[]'::jsonb,true);

-- User C, same gym, evening: eligible ONLY when both choose that mode.
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
select public.save_dating_setup('Usuario C','Querétaro',array['HYROX'],date '1992-01-01',
  '00000000-0000-4000-8000-000000000001','same_gym_other_time',
  '[{"day":1,"startMinutes":1080,"endMinutes":1170}]'::jsonb,true);

-- User D, same gym, overlapping morning schedule: always excluded.
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
select public.save_dating_setup('Usuario D','Querétaro',array['Fuerza'],date '1992-01-01',
  '00000000-0000-4000-8000-000000000001','same_gym_other_time',
  '[{"day":1,"startMinutes":480,"endMinutes":560}]'::jsonb,true);

select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare
 v_ids uuid[];
begin
  select array_agg(user_id) into v_ids from public.discover_dating_candidates(20);
  if not '10000000-0000-4000-8000-000000000002'::uuid = any(v_ids)
     or not '10000000-0000-4000-8000-000000000003'::uuid = any(v_ids)
     or '10000000-0000-4000-8000-000000000004'::uuid = any(v_ids) then
    raise exception 'Gym Shield server decision incorrect: %',v_ids;
  end if;
  if has_table_privilege(current_user,'app_private.dating_profiles','SELECT')
     or has_table_privilege(current_user,'app_private.training_slots','SELECT') then
    raise exception 'Private tables exposed to user';
  end if;
end $$;

-- Switching to other_gyms excludes same-gym C immediately.
select public.save_dating_setup('Usuario A','Querétaro',array['Running'],date '1992-01-01',
  '00000000-0000-4000-8000-000000000001','other_gyms',
  '[{"day":1,"startMinutes":420,"endMinutes":510}]'::jsonb,true);
do $$
begin
  if exists(select 1 from public.discover_dating_candidates(20)
            where user_id='10000000-0000-4000-8000-000000000003') then
     raise exception 'Same-gym profile leaked in other_gyms mode';
  end if;
end $$;

-- Block a cross-gym person.
select public.block_user('10000000-0000-4000-8000-000000000002');
do $$
begin
  if exists(select 1 from public.discover_dating_candidates(20)) then
    raise exception 'Blocked candidate leaked';
  end if;
end $$;

-- Disable dating: no more matches, but still an authenticated account.
select public.disable_dating();
do $$
begin
  if exists(select 1 from public.discover_dating_candidates(20)) then
    raise exception 'Disabled dating unexpectedly found profiles';
  end if;
end $$;
reset role;
