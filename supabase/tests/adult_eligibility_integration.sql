-- V16: one closed-by-default adult gate. Synthetic users only.
-- Can be run in disposable CI and in managed DEV inside BEGIN/ROLLBACK.
begin;
insert into auth.users(id,email) values
 ('10000000-0000-4000-8000-000000000009','qa16-a@example.invalid'),
 ('10000000-0000-4000-8000-000000000010','qa16-b@example.invalid');

set role anon;
do $$
begin
 if has_function_privilege(current_user,'public.my_adult_eligibility()','EXECUTE')
    or has_function_privilege(current_user,
       'public.operator_set_adult_eligibility(uuid,text,timestamptz,boolean)','EXECUTE') then
  raise exception 'Age review API exposed to anonymous callers';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000009',false);
do $$
begin
 if has_function_privilege(current_user,
     'public.operator_set_adult_eligibility(uuid,text,timestamptz,boolean)','EXECUTE')
    or has_table_privilege(current_user,'app_private.adult_eligibility','INSERT') then
   raise exception 'User could self-approve age';
 end if;
 if (public.my_adult_eligibility()->>'approved')<>'false' then
   raise exception 'New account has adult approval without review';
 end if;
 begin
   perform public.save_dating_setup('QA Runner A','Querétaro',array['Running'],
      date '1992-01-01','00000000-0000-4000-8000-000000000001',
      'other_gyms','[]'::jsonb,true);
   raise exception 'Unreviewed age allowed dating' using errcode='P0002';
 exception when sqlstate 'P0001' then
   if sqlerrm<>'AGE_REVIEW_REQUIRED' then raise; end if;
 end;
 begin
   perform * from public.discover_dating_candidates(10);
   raise exception 'Unreviewed account can discover dating' using errcode='P0002';
 exception when sqlstate 'P0001' then
   if sqlerrm<>'AGE_REVIEW_REQUIRED' then raise; end if;
 end;
end $$;
reset role;

-- Only trusted operator can approve off-platform reviewed adults. No ID
-- documents or exact DOB are stored in the approval table.
set role service_role;
select public.operator_set_adult_eligibility(
 '10000000-0000-4000-8000-000000000009',
 'QA16-reviewed-adult-A',now()+interval '30 days',true);
select public.operator_set_adult_eligibility(
 '10000000-0000-4000-8000-000000000010',
 'QA16-reviewed-adult-B',now()+interval '30 days',true);
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000009',false);
select public.save_dating_setup('QA Runner A','Querétaro',array['Running'],
 date '1992-01-01','00000000-0000-4000-8000-000000000001',
 'same_gym_other_time','[{"day":1,"startMinutes":420,"endMinutes":510}]'::jsonb,true);
do $$
begin
 if (public.my_adult_eligibility()->>'approved') <> 'true' then
   raise exception 'Own verification status did not update';
 end if;
 if public.my_adult_eligibility() ? 'review_ref' then
   raise exception 'Review reference leaked to client';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000010',false);
select public.save_dating_setup('QA Runner B','Querétaro',array['Running'],
 date '1992-01-01','00000000-0000-4000-8000-000000000001',
 'same_gym_other_time','[{"day":1,"startMinutes":539,"endMinutes":620}]'::jsonb,true);
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000009',false);
do $$
begin
 if exists(select 1 from public.discover_dating_candidates(10)
 where user_id='10000000-0000-4000-8000-000000000010') then
   raise exception 'Same-gym 29-minute gap was exposed';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000010',false);
select public.save_dating_setup('QA Runner B','Querétaro',array['Running'],
 date '1992-01-01','00000000-0000-4000-8000-000000000001',
 'same_gym_other_time','[{"day":1,"startMinutes":540,"endMinutes":620}]'::jsonb,true);
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000009',false);
do $$
begin
 if not exists(select 1 from public.discover_dating_candidates(10)
 where user_id='10000000-0000-4000-8000-000000000010') then
   raise exception 'Mutually opted-in 30-minute gap wrongly rejected';
 end if;
 begin
   perform * from public.discover_dating_candidates(11);
   raise exception 'Oversized candidate page accepted' using errcode='P0002';
 exception when sqlstate 'P0001' then
   if sqlerrm<>'Invalid page size' then raise; end if;
 end;
end $$;
reset role;

-- A revoked candidate must disappear even if dating_enabled was true.
set role service_role;
select public.operator_set_adult_eligibility(
 '10000000-0000-4000-8000-000000000010',
 'QA16-revoked-review-B',null,false);
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000009',false);
do $$
begin
 if exists(select 1 from public.discover_dating_candidates(10)
 where user_id='10000000-0000-4000-8000-000000000010') then
   raise exception 'Revoked candidate still discoverable';
 end if;
end $$;
reset role;

-- Expiry must fail even if a profile still has dating_enabled=true.
update app_private.adult_eligibility
set approved_at=now()-interval '2 days',expires_at=now()-interval '1 hour'
where user_id='10000000-0000-4000-8000-000000000009';
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000009',false);
do $$
begin
 if (public.my_adult_eligibility()->>'approved')<>'false' then
  raise exception 'Expired review still approved';
 end if;
 begin
  perform * from public.discover_dating_candidates(10);
  raise exception 'Expired age review can discover' using errcode='P0002';
 exception when sqlstate 'P0001' then
  if sqlerrm<>'AGE_REVIEW_REQUIRED' then raise; end if;
 end;
end $$;
reset role;
rollback;
