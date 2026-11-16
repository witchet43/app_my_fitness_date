-- B13 post-meeting feedback: tests after B11,B12,B13 migrations.
begin;
do $test$
declare n integer;
begin
 if not exists(select 1 from pg_tables where schemaname='app_private'
      and tablename='fitted_signal_moderation_audit_b13' and rowsecurity)
 then raise exception 'Moderation audit must be private RLS'; end if;
 if not exists(select 1 from pg_tables where schemaname='app_private'
      and tablename='fitted_signal_appeals_b13' and rowsecurity)
 then raise exception 'Appeal database must be RLS'; end if;
 if has_table_privilege('anon','app_private.fitted_signal_moderation_audit_b13','SELECT')
   or has_table_privilege('authenticated','app_private.fitted_signal_appeals_b13','SELECT')
 then raise exception 'Sensitive moderation data leaked'; end if;
 if has_function_privilege('anon','public.fitted_moderation_queue_b13(integer)','EXECUTE')
   or has_function_privilege('anon','public.fitted_review_signal_b13(uuid,text,text)','EXECUTE')
 then raise exception 'Anonymous moderation access enabled'; end if;
 if app_private.fitted_can_moderate_b13()
 then raise exception 'Anonymous moderator access'; end if;
 select count(*) into n from public.fitted_moderation_queue_b13(50);
 if n<>0 then raise exception 'Queue should be empty for anonymous caller'; end if;
 if public.fitted_review_signal_b13(null::uuid,'approve','Validar evidencia')<>'forbidden'
 then raise exception 'An anonymous user could approve a trust score'; end if;
 if public.fitted_appeal_signal_b13(null::uuid,'Se cometió un error en mi perfil')<>'invalid'
 then raise exception 'Anonymous appeal accepted'; end if;
 if public.fitted_retract_signal_b13(null::uuid)<>'invalid'
 then raise exception 'Anonymous retraction accepted'; end if;
 if exists(select 1 from public.fitted_my_private_observations_b13())
 then raise exception 'Subjects feedback leaked anonymously'; end if;
 raise notice 'FITTED B13 privacy/moderation/appeals authorization PASS';
end;
$test$;
rollback;
