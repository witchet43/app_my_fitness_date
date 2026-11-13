-- B11: defensive SQL assertions for the final real FITTED candidate.
-- Runs with postgres in ephemeral CI only, never against live customer data.
begin;
do $audit$
declare permits boolean;
begin
 if not public.b11_safe_answers('{"sport":"running","sleep":"early_bird","intent":"long_term"}'::jsonb) then
   raise exception 'Correct lifestyle JSON rejected';
 end if;
 if public.b11_safe_answers('{"sport":"running","gym_id":"secret"}'::jsonb) then
   raise exception 'Gym ID accepted in public lifestyle profile';
 end if;
 if public.b11_safe_answers('{"sport":"running","frequency":"my_private_time"}'::jsonb) then
   raise exception 'Unreviewed preference code accepted';
 end if;
 select rowsecurity into permits from pg_tables
 where schemaname='public' and tablename='member_rhythm_b11';
 if permits is distinct from true then
   raise exception 'Owner lifestyle RLS must be enabled';
 end if;
 if has_table_privilege('anon','public.member_rhythm_b11','SELECT')
    or has_table_privilege('anon','public.member_rhythm_b11','INSERT')
 then raise exception 'Anonymous rhythm access must remain denied'; end if;
 if has_table_privilege('authenticated','app_private.fitdating_messages_b11','SELECT')
    or has_table_privilege('authenticated','app_private.fitdating_matches_b11','SELECT')
 then raise exception 'Private messages or matches directly readable'; end if;
 if has_function_privilege('anon','public.fitdating_candidates_b11(integer)','EXECUTE')
    or has_function_privilege('anon','public.fitdating_send_b11(uuid,text)','EXECUTE')
 then raise exception 'Anonymous RPC callable'; end if;
 if has_function_privilege('authenticated','app_private.b11_pair_allowed(uuid,uuid)','EXECUTE')
 then raise exception 'Internal eligibility helper callable by clients'; end if;
 if (select app_private.b5_discovery_open()) then
   raise exception 'Dating must stay disabled absent independent review';
 end if;
 if (select count(*) from public.fitdating_candidates_b11(10))<>0 then
   raise exception 'No candidate rows allowed when readiness is false';
 end if;
 if public.fitdating_like_b11('00000000-0000-0000-0000-000000000001'::uuid)
    <> 'not_available' then raise exception 'Unauthenticated like should fail closed'; end if;
 if public.fitdating_send_b11('00000000-0000-0000-0000-000000000001'::uuid,'x')
    <> 'invalid' then raise exception 'Unauthenticated send should fail closed'; end if;
 raise notice 'B11 owner-only profile, closed gate, no cross-user reads, no anon chat: PASS';
end;
$audit$;
rollback;
