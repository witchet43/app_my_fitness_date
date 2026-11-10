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
  if exists (
    select 1
    from pg_proc p
    cross join lateral aclexplode(
      coalesce(p.proacl, acldefault('f', p.proowner))
    ) acl
    where p.oid = 'public.saas_heartbeat_v1()'::regprocedure
      and acl.grantee = 0
      and acl.privilege_type = 'EXECUTE'
  ) then
    raise exception 'Public-role default execute grant must be revoked';
  end if;
end $$;
rollback;
