-- Requires bootstrap + v1 migration + v2 migration + initial integration tests.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare dob date;
begin
 select public.my_dating_birthdate() into dob;
 if dob is distinct from date '1992-01-01' then
   raise exception 'DOB not returned correctly for owner: %', dob;
 end if;
 if has_table_privilege(current_user,'app_private.dating_profiles','SELECT') then
   raise exception 'Direct access to private DOB is open';
 end if;
end $$;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
do $$
declare dob date;
begin
 select public.my_dating_birthdate() into dob;
 if dob is distinct from date '1992-01-01' then
   raise exception 'Own DOB inaccessible';
 end if;
end $$;
reset role;
set role anon;
do $$
begin
 if has_function_privilege(current_user,'public.my_dating_birthdate()','EXECUTE') then
  raise exception 'Anon can access private birthdate';
 end if;
end $$;
reset role;
