-- B18: candidate summaries, uploaded portraits and private browsing fail closed.
begin;
do $tests$
declare value jsonb;
begin
 if has_function_privilege('anon',
     'public.fitted_candidate_showcase_b18(uuid)','execute') then
   raise exception 'Anonymous candidate showcase execution'; end if;
 if not has_function_privilege('authenticated',
     'public.fitted_candidate_showcase_b18(uuid)','execute') then
   raise exception 'Auth showcase missing'; end if;
 value:=public.fitted_candidate_showcase_b18(
   '00000000-0000-4000-8000-000000000001'::uuid);
 if value->>'available'<>'false' then
   raise exception 'Unverified viewer saw a candidate'; end if;
 if value ? 'photo_key' or value ? 'summary_es' then
   raise exception 'Unverified candidate private media or biography leaked'; end if;
 if exists(select 1 from pg_policies
   where schemaname='storage' and tablename='objects'
    and policyname='mfd_photo_matches_b17'
    and qual not like '%fitted_photo_viewable_b17%') then
   raise exception 'Approved photo access policy altered'; end if;
 raise notice 'B18 candidate photo/summary privacy constraints PASS';
end;
$tests$;
rollback;