-- Fitted B14: negative test suite for personal government ID processing.
begin;
do $t$
declare n integer;
begin
 if (select public from storage.buckets where id='mfd-age-proof') is distinct from false
 then raise exception 'Age evidence must use a private bucket'; end if;
 if (select file_size_limit from storage.buckets where id='mfd-age-proof')<>5242880
 then raise exception 'Age files need a hard size limit'; end if;
 if not exists(select 1 from pg_tables where schemaname='app_private'
      and tablename='age_review_requests_b14' and rowsecurity)
 then raise exception 'Age review request RLS is missing'; end if;
 if has_table_privilege('anon','app_private.age_review_requests_b14','select')
   or has_table_privilege('authenticated','app_private.age_review_audit_b14','select')
 then raise exception 'Age evidence audit leaked to clients'; end if;
 if exists(select 1 from pg_policies where schemaname='storage'
    and tablename='objects' and policyname like 'mfd_age_%'
    and roles @> array['anon'::name])
 then raise exception 'Anonymous age storage policy exists'; end if;
 if has_function_privilege('anon','public.admin_age_decide_b14(uuid,text,date,boolean,boolean,date,text)','execute')
   or has_function_privilege('anon','public.admin_dating_launch_b14(boolean,boolean,boolean,boolean,text)','execute')
 then raise exception 'Anonymous age or dating release permission'; end if;
 if app_private.manual_dating_live_b14() or app_private.b5_discovery_open()
 then raise exception 'Dating must fail closed before an operator takes responsibility'; end if;
 if public.age_start_review_b14(false)->>'status'<>'consent_required'
 then raise exception 'Age proof must have separate consent'; end if;
 if public.age_start_review_b14(true)->>'status'<>'not_available'
 then raise exception 'Anonymous account should not be reviewed'; end if;
 if public.age_review_status_b14()->>'status'<>'not_available'
 then raise exception 'Age status leaked to anon'; end if;
 if public.age_submit_review_b14(null::uuid)<>'not_available'
 then raise exception 'Anonymous request submission'; end if;
 if public.admin_age_decide_b14(null,'approved',current_date-interval '30 years',true,true,
   null,'No se permite')<>'forbidden'
 then raise exception 'Anonymous decision on an identity'; end if;
 if public.admin_dating_launch_b14(true,true,true,true,
    'No se permite realizar esta acción por esta cuenta')<>'forbidden'
 then raise exception 'Anonymous launch approval'; end if;
 select count(*) into n from public.admin_age_queue_b14();
 if n<>0 then raise exception 'Anonymous identity review queue exposed'; end if;
 if public.dating_manual_status_b14()->>'enabled'<>'false'
 then raise exception 'Manual program must stay disabled by default'; end if;
 raise notice 'B14 private document review and launch negative tests PASS';
end;
$t$;
rollback;