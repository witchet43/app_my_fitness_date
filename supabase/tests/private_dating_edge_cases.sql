-- Additional server-only edge tests, executed after the principal integration suite.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);

-- Fail closed for underage DOB. Existing profile must remain disabled after rejected mutation.
do $$
begin
  begin
    perform public.save_dating_setup('Usuario A','Querétaro',array['Running'],date '2016-10-26',
      '00000000-0000-4000-8000-000000000001','same_gym_other_time',
      '[{"day":1,"startMinutes":420,"endMinutes":510}]'::jsonb,true);
    raise exception 'ERROR: underage settings were accepted';
  exception
    when others then
      if sqlerrm = 'ERROR: underage settings were accepted' then raise; end if;
  end;
  if exists(select 1 from public.discover_dating_candidates(20)) then
    raise exception 'Failed validation unexpectedly re-enabled discovery';
  end if;
end $$;

-- Re-enable A and verify reciprocal privacy: C does not opt into same gym.
select public.save_dating_setup('Usuario A','Querétaro',array['Running'],date '1992-01-01',
  '00000000-0000-4000-8000-000000000001','same_gym_other_time',
  '[{"day":1,"startMinutes":420,"endMinutes":510}]'::jsonb,true);
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
select public.save_dating_setup('Usuario C','Querétaro',array['HYROX'],date '1992-01-01',
  '00000000-0000-4000-8000-000000000001','other_gyms',
  '[]'::jsonb,true);
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
begin
  if exists(select 1 from public.discover_dating_candidates(20)
      where user_id='10000000-0000-4000-8000-000000000003') then
    raise exception 'Reciprocal mode protection failed';
  end if;
end $$;

-- Same-gym users exactly 29m apart must be filtered, 30m apart may be shown.
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
select public.save_dating_setup('Usuario C','Querétaro',array['HYROX'],date '1992-01-01',
  '00000000-0000-4000-8000-000000000001','same_gym_other_time',
  '[{"day":1,"startMinutes":539,"endMinutes":620}]'::jsonb,true);
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
begin
  if exists(select 1 from public.discover_dating_candidates(20)
      where user_id='10000000-0000-4000-8000-000000000003') then
    raise exception '29-minute gap was incorrectly allowed';
  end if;
end $$;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
select public.save_dating_setup('Usuario C','Querétaro',array['HYROX'],date '1992-01-01',
  '00000000-0000-4000-8000-000000000001','same_gym_other_time',
  '[{"day":1,"startMinutes":540,"endMinutes":620}]'::jsonb,true);
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare j jsonb;
begin
  if not exists(select 1 from public.discover_dating_candidates(20)
      where user_id='10000000-0000-4000-8000-000000000003') then
    raise exception '30-minute gap incorrectly excluded';
  end if;
  select to_jsonb(x) into j from public.discover_dating_candidates(20) x
  where x.user_id='10000000-0000-4000-8000-000000000003';
  if j ? 'gym_id' or j ? 'date_of_birth' or j ? 'weekly_slots' or j ? 'mode' then
    raise exception 'Sensitive properties exposed in result: %',j;
  end if;
end $$;
reset role;
