-- V9b: close the cancellation/deletion race and reject stale JWTs after Auth removal.
create or replace function app_private.account_is_active(p_user_id uuid)
returns boolean language sql security definer set search_path = '' stable
as $$
  select p_user_id is not null
    and exists(select 1 from auth.users u where u.id=p_user_id)
    and not exists(select 1 from app_private.account_deletion_requests r
                   where r.user_id=p_user_id);
$$;

alter table app_private.erasure_approvals
 add column processing_at timestamptz;

create or replace function app_private.cancel_account_deletion()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
 v_user uuid:=(select auth.uid());
 v_processing timestamptz;
begin
 if v_user is null then raise exception 'Sign-in required'; end if;
 -- Serialize with the operator's SELECT FOR UPDATE on this approval row.
 -- Cancellation wins -> preflight fails; claim wins -> cancellation fails.
 select processing_at into v_processing from app_private.erasure_approvals a
 where a.user_id=v_user for update;
 if v_processing is not null then
  raise exception 'ERASURE_IN_PROGRESS' using errcode='P0001';
 end if;
 delete from app_private.account_deletion_requests where user_id=v_user;
 -- No automatic reactivation of Dating consent.
 return app_private.my_account_status();
end;
$$;

-- Serialize operator claims per approved ticket. Only the service role
-- can invoke this RPC; the caller needs a ticket previously approved via
-- privileged SQL. Once claimed, the user cannot cancel until an operator
-- explicitly verifies the failure and releases the claim using SQL.
create function app_private.operator_erasure_claim(p_user_id uuid,p_ticket text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
 v_processing timestamptz;
 v_state jsonb;
begin
 if p_user_id is null or p_ticket is null then
  raise exception 'Missing account or ticket';
 end if;

 select processing_at into v_processing from app_private.erasure_approvals a
 where a.user_id=p_user_id and a.ticket=p_ticket for update;

 if v_processing is not null then
  return jsonb_build_object('eligible',false,
    'blockers',jsonb_build_array('erasure_already_claimed'));
 end if;

 v_state := app_private.erasure_preflight(p_user_id,p_ticket);
 if (v_state->>'eligible') is distinct from 'true' then
  return v_state;
 end if;

 update app_private.erasure_approvals
 set processing_at=now() where user_id=p_user_id and ticket=p_ticket;
 return v_state;
end;
$$;

create function public.operator_erasure_claim(p_user_id uuid,p_ticket text)
returns jsonb language sql security invoker set search_path = ''
as $$ select app_private.operator_erasure_claim(p_user_id,p_ticket); $$;

revoke execute on function app_private.operator_erasure_claim(uuid,text)
 from public,anon,authenticated;
revoke execute on function public.operator_erasure_claim(uuid,text)
 from public,anon,authenticated;
grant execute on function app_private.operator_erasure_claim(uuid,text) to service_role;
grant execute on function public.operator_erasure_claim(uuid,text) to service_role;
