-- B12 private post-date trust: negative and privilege assertions.
begin;
do $audit$
begin
  if has_table_privilege('anon','app_private.fitted_signals_b12','SELECT')
    or has_table_privilege('authenticated','app_private.fitted_signals_b12','SELECT')
    or has_table_privilege('authenticated','app_private.fitted_meetups_b12','INSERT')
  then raise exception 'Pulse private tables leaked'; end if;
  if has_function_privilege('anon','public.fitted_submit_signal_b12(uuid,text,text)','EXECUTE')
    or has_function_privilege('anon','public.fitted_signal_status_b12(uuid)','EXECUTE')
  then raise exception 'Anonymous reputation call permitted'; end if;
  if not (select rowsecurity from pg_tables
      where schemaname='app_private' and tablename='fitted_signals_b12')
  then raise exception 'RLS missing'; end if;
  if public.fitted_confirm_meetup_b12(null::uuid)<>'not_available'
  then raise exception 'Anonymous fake meeting accepted'; end if;
  if public.fitted_submit_signal_b12(null::uuid,'move','not_aligned')<>'invalid'
  then raise exception 'Anonymous feedback accepted'; end if;
  if public.fitted_consent_b12(true)<>'not_available'
  then raise exception 'Anonymous consent accepted'; end if;
  if (public.fitted_signal_status_b12(null::uuid)->>'available')<>'false'
  then raise exception 'Private signal status exposed'; end if;
  if exists(select 1 from app_private.fitted_signals_b12)
  then raise exception 'Unexpected signal data'; end if;
  raise notice 'B12 Pulso Real private, no anonymous access, unreviewed reputation invisible PASS';
end;
$audit$;
rollback;
