-- SaaS Factory heartbeat v1: public, low-cost, strictly read-only.
-- Exposes no tenant or user data. The API layer queries this RPC.
create or replace function public.saas_heartbeat_v1()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object('status', 'ok');
$$;

-- Do not leave the default EXECUTE grant to all PostgreSQL roles.
revoke all on function public.saas_heartbeat_v1() from public;
grant execute on function public.saas_heartbeat_v1() to anon, authenticated;

comment on function public.saas_heartbeat_v1()
is 'Safe, read-only readiness probe. Returns no private information.';
