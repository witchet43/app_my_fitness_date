-- Isolated local PostgreSQL CI only. Run after role bootstrap and heartbeat DDL.
begin;
do $$
declare response jsonb;
begin
  select public.saas_heartbeat_v1() into response;
  if response <> '{"status":"ok"}'::jsonb then
    raise exception 'Unexpected heartbeat response: %', response;
  end if;
  if not has_function_privilege('anon', 'public.saas_heartbeat_v1()', 'EXECUTE') then
    raise exception 'Anonymous readiness role cannot execute heartbeat';
  end if;
  if not has_function_privilege('authenticated', 'public.saas_heartbeat_v1()', 'EXECUTE') then
    raise exception 'Authenticated readiness role cannot execute heartbeat';
  end if;
  if has_function_privilege('public', 'public.saas_heartbeat_v1()', 'EXECUTE') then
    raise exception 'Public-role default execute grant must be revoked';
  end if;
end $$;
rollback;
