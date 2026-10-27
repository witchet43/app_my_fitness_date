// DEV operator-only. Never call this function from the mobile application.
// The caller must possess the protected service-role key AND an approved ticket.
const url = Deno.env.get('SUPABASE_URL');
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
  });
}
function validUuid(value: unknown): value is string {
  return typeof value === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}
Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  if (!url || !serviceKey) return json({ error: 'Server configuration missing' }, 503);
  // Gateway validates JWT; this explicitly refuses normal user JWTs.
  if (request.headers.get('Authorization') !== 'Bearer ' + serviceKey)
    return json({ error: 'Forbidden' }, 403);
  let body: { user_id?: unknown; ticket?: unknown; confirm?: unknown };
  try { body = await request.json(); }
  catch { return json({ error: 'Invalid request' }, 400); }
  if (!validUuid(body.user_id) ||
    typeof body.ticket !== 'string' || body.ticket.length < 10 ||
    body.ticket.length > 100 ||
    body.confirm !== 'DELETE_ACCOUNT_PERMANENTLY') {
    return json({ error: 'Invalid confirmation parameters' }, 400);
  }
  const headers = {
    apikey: serviceKey, Authorization: 'Bearer ' + serviceKey,
    'Content-Type': 'application/json',
  };
  let preflight: Response;
  try {
    preflight = await fetch(url + '/rest/v1/rpc/operator_erasure_preflight', {
      method: 'POST', headers,
      body: JSON.stringify({ p_user_id: body.user_id, p_ticket: body.ticket }),
    });
  } catch {
    return json({ error: 'Preflight unavailable; no account deleted' }, 503);
  }
  if (!preflight.ok) return json({ error: 'Preflight failed; no account deleted' }, 503);
  const eligibility = await preflight.json() as { eligible?: boolean; blockers?: string[] };
  if (eligibility.eligible !== true) {
    return json({ error: 'Deletion blocked; no account deleted', blockers: eligibility.blockers ?? [] }, 409);
  }
  // Supabase Auth Admin REST API: never DELETE FROM auth.users.
  let removed: Response;
  try {
    removed = await fetch(url + '/auth/v1/admin/users/' + body.user_id, {
      method: 'DELETE', headers,
    });
  } catch {
    return json({ error: 'Auth service error; verify status manually' }, 502);
  }
  if (!removed.ok) {
    return json({ error: 'Auth deletion failed', status: removed.status }, 409);
  }
  // Existing access tokens can survive until expiration: do not claim
  // immediate universal revocation after successful Auth deletion.
  const check = await fetch(url + '/auth/v1/admin/users/' + body.user_id, {
    method: 'GET', headers,
  }).catch(() => null);
  if (!check || check.status !== 404) {
    return json({ auth_delete_accepted: true, verified_absent: false,
      message: 'Manual verification required' }, 202);
  }
  return json({ auth_delete_accepted: true, verified_absent: true });
});
