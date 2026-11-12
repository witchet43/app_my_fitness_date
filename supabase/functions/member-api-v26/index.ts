// My Fitness Date V27: unprivileged, authenticated Edge API.
// RLS is enforced by forwarding the end user's JWT to PostgREST.
// There is deliberately no service-role key and no public media publishing.
import { resolvePublishableKey, extractApiRoute, memberCorsRequestHeaders } from "./config.ts";
import { activityRsvpRoute, validateActivityDraft } from "./activity_validation.ts";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const publishable = resolvePublishableKey(
  Deno.env.get("SUPABASE_PUBLISHABLE_KEYS"),
  (name) => Deno.env.get(name),
);
// One exact origin per deployment. QA can use a separate Supabase environment
// with an explicit staging origin; production defaults to the real application.
// Never reflect arbitrary Origin headers or use "*".
const configuredOrigin = Deno.env.get("MFD_ALLOWED_ORIGIN") ??
  "https://my-fitness-date.pages.dev";
const origin = /^https:\/\/[a-z0-9.-]+(?::[0-9]{1,5})?$/i.test(configuredOrigin) ||
  /^http:\/\/localhost:[0-9]{2,5}$/i.test(configuredOrigin)
    ? configuredOrigin : "https://my-fitness-date.pages.dev";
const cors = {
  "Access-Control-Allow-Origin": origin,
  "Access-Control-Allow-Headers": memberCorsRequestHeaders,
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Vary": "Origin",
};
const baseHeaders = { ...cors, "Content-Type": "application/json", "Cache-Control": "private, no-store",
  "X-Content-Type-Options": "nosniff", "Referrer-Policy": "no-referrer" };
function json(value: unknown, status = 200): Response {
  return new Response(JSON.stringify(value), { status, headers: baseHeaders });
}
function error(status: number): Response {
  const descriptions: Record<number, string> = {
    400: "Solicitud inválida", 401: "Autenticación requerida",
    403: "No autorizado", 404: "Recurso no disponible", 409: "Conflicto de estado",
    405: "Método no permitido", 413: "Datos demasiado extensos",
    429: "Demasiadas solicitudes", 503: "Servicio no disponible",
  };
  return json({ detail: descriptions[status] ?? descriptions[503] }, status);
}
type Identity = { id: string; email?: string; email_confirmed_at?: string; is_anonymous?: boolean };
async function endpoint(method: string, path: string, token: string, data?: unknown,
  params: Record<string, string> = {}, preference?: string): Promise<Response> {
  const u = new URL(path, SUPABASE_URL);
  for (const [name, value] of Object.entries(params)) u.searchParams.set(name, value);
  const response = await fetch(u, {
    method, headers: {
      "apikey": publishable!, "Authorization": "Bearer " + token,
      "Content-Type": "application/json",
      ...(preference ? { "Prefer": preference } : {}),
    },
    ...(data === undefined ? {} : { body: JSON.stringify(data) }),
  });
  return response;
}
async function forward(resp: Response, fallback: unknown = null): Promise<Response> {
  if (resp.status === 401) return error(401);
  if (resp.status === 403) return error(403);
  if (resp.status === 429) return error(429);
  if (!resp.ok) return error(resp.status === 400 ? 400 : 503);
  if (resp.status === 204) return json(fallback ?? { ok: true });
  const value = await resp.json().catch(() => fallback);
  return json(value ?? fallback);
}
async function verify(token: string): Promise<Identity | null> {
  const r = await endpoint("GET", "/auth/v1/user", token);
  if (!r.ok) return null;
  const identity = await r.json() as Identity;
  return /^[0-9a-f]{8}-[0-9a-f-]{27,}$/.test(identity.id ?? "") &&
    !!identity.email_confirmed_at && identity.is_anonymous !== true ? identity : null;
}
async function body(req: Request): Promise<Record<string, unknown> | null> {
  const size = Number(req.headers.get("content-length") || "0");
  if (size > 16000) return null;
  const raw = await req.text();
  if (raw.length > 16000) return null;
  try {
    const value: unknown = JSON.parse(raw);
    return value && typeof value === "object" && !Array.isArray(value) ?
      value as Record<string, unknown> : null;
  } catch { return null; }
}
async function consents(token: string, id: string): Promise<Array<Record<string, unknown>>> {
  const r = await endpoint("GET", "/rest/v1/member_consents_v26", token, undefined,
    { user_id: "eq." + id, select: "consent_kind,document_version,accepted_at" });
  if (!r.ok) throw new Error("consent unavailable");
  return await r.json();
}
async function datingStatus(token: string, id: string) {
  const r = await endpoint("POST", "/rest/v1/rpc/my_adult_eligibility", token, {});
  if (!r.ok) throw new Error("eligibility unavailable");
  const age = await r.json() as { approved?: boolean; expires_at?: string };
  const legal = await consents(token, id);
  const opted = legal.some((x) => x.consent_kind === "dating" && x.document_version === "dating-v1");
  return { age_verified: age.approved === true, dating_consent: opted,
    enabled: age.approved === true && opted,
    age_expires_at: age.approved === true ? age.expires_at : null };
}
const editable = new Set([
  "display_name", "date_of_birth", "city", "about_me", "headline", "occupation",
  "languages", "hobbies", "life_values", "prompts", "sports", "fitness_goals",
  "achievements", "training_frequency", "dating_intent", "social_visibility",
  "onboarding_complete",
]);
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  const requestedOrigin = req.headers.get("origin");
  if (requestedOrigin && requestedOrigin !== origin) return error(403);
  if (!publishable?.startsWith("sb_publishable_") || !SUPABASE_URL.startsWith("https://")) {
    return error(503);
  }
  if (req.method === "GET" && new URL(req.url).pathname.endsWith("/healthz")) {
    // Verify the actual backend connection and public API key before claiming
    // health; the old health check passed even when every login failed.
    try {
      const response = await fetch(new URL("/auth/v1/settings", SUPABASE_URL), {
        headers: { "apikey": publishable, "Accept": "application/json" },
      });
      if (!response.ok) return error(503);
    } catch {
      return error(503);
    }
    return json({ status: "ok", service: "member-api-v26", dating: "age-verified-only" });
  }
  const authorization = req.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ") || authorization.length > 8300) return error(401);
  const token = authorization.slice(7).trim();
  if (!token) return error(401);
  const identity = await verify(token).catch(() => null);
  if (!identity) return error(401);
  const path = new URL(req.url).pathname;
  const route = extractApiRoute(path);
  if (!route) return error(404);
  try {
    // B1 · Curated catalogue; no users, gyms, private training slots,
    // attendance or organizer emails are returned. RLS also filters events.
    if (route === "/v1/activities" && req.method === "GET") {
      const events = await endpoint("GET", "/rest/v1/sport_events", token,
        undefined, {
          select: "id,title,description,sport,city,starts_at,capacity",
          is_published: "eq.true",
          starts_at: "gt." + new Date().toISOString(),
          order: "starts_at.asc", limit: "25",
        });
      if (!events.ok) return error(503);
      const own = await endpoint("GET", "/rest/v1/event_rsvps", token,
        undefined, { user_id: "eq." + identity.id, select: "event_id" });
      if (!own.ok) return error(503);
      const records = await events.json() as Array<Record<string, unknown>>;
      const joined = new Set(
        (await own.json() as Array<{event_id:string}>).map((r)=>r.event_id));
      return json({ items: records.map((r)=>({ ...r,
        joined: joined.has(String(r.id)) })) });
    }
    if (route === "/v1/me/organizer-status" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/my_activity_organizer_status", token, {});
      if (!response.ok) return error(503);
      return json({ approved: await response.json() === true });
    }
    if (route === "/v1/organizer/activities" && req.method === "POST") {
      const payload = await body(req);
      const data = payload == null ? null : validateActivityDraft(payload);
      if (!data) return error(400);
      // Row creation is subject to the organizer approval RLS policy.
      const response = await endpoint("POST", "/rest/v1/sport_events",
        token, { ...data, organizer_id: identity.id, is_published: true },
        {}, "return=representation");
      if (response.status === 401 || response.status === 403) return error(403);
      if (!response.ok) return error(response.status === 400 ? 400 : 503);
      const rows = await response.json() as Array<Record<string, unknown>>;
      if (rows.length !== 1) return error(503);
      const item = rows[0];
      return json({ activity: {
        id:item.id, title:item.title, description:item.description,
        sport:item.sport, city:item.city, starts_at:item.starts_at,
        capacity:item.capacity, joined:false,
      } }, 201);
    }
    const eventId = activityRsvpRoute(route);
    if (eventId && req.method === "POST") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/confirm_activity_rsvp", token,
        { p_event_id: eventId });
      if (response.status === 401 || response.status === 403) return error(403);
      if (!response.ok) return error(503);
      const status = await response.json();
      if (status === "confirmed" || status === "already_confirmed") {
        return json({ status, event_id: eventId });
      }
      if (status === "full" || status === "not_open") {
        return json({ status }, 409);
      }
      if (status === "profile_required" || status === "consent_required" ||
          status === "not_authenticated") {
        return json({ status }, 403);
      }
      return error(503);
    }
    if (route === "/v1/me/profile") {
      if (req.method === "GET") {
        const r = await endpoint("GET", "/rest/v1/member_profiles_v26", token, undefined,
          { user_id: "eq." + identity.id, select: "*" });
        if (!r.ok) return error(503);
        const entries = await r.json();
        return json({ profile: entries[0] ?? null });
      }
      if (req.method === "PUT") {
        const payload = await body(req);
        if (!payload) return error(400);
        const data: Record<string, unknown> = { user_id: identity.id };
        for (const [k, v] of Object.entries(payload)) if (editable.has(k)) data[k] = v;
        const r = await endpoint("POST", "/rest/v1/member_profiles_v26", token, data,
          { on_conflict: "user_id" }, "resolution=merge-duplicates,return=representation");
        if (!r.ok) return error(r.status === 400 || r.status === 422 ? 400 : 503);
        const result = await r.json();
        return json({ profile: result[0] ?? null });
      }
    }
    if (route === "/v1/me/consents") {
      if (req.method === "GET") return json({ consents: await consents(token, identity.id) });
      if (req.method === "POST") {
        const data = await body(req);
        if (!data || !["terms", "privacy", "community", "dating"].includes(String(data.consent_kind))
          || typeof data.document_version !== "string" || data.document_version.length > 50
          || !data.document_version) return error(400);
        const r = await endpoint("POST", "/rest/v1/member_consents_v26", token,
          { user_id: identity.id, consent_kind: data.consent_kind,
            document_version: data.document_version, source: "member_onboarding" },
          {}, "return=representation");
        if (!r.ok) return error(503);
        return json({ consent: { recorded: true } }, 201);
      }
    }
    if (route === "/v1/me/places") {
      if (req.method === "GET") {
        const r = await endpoint("GET", "/rest/v1/member_training_places_v26", token,
          undefined, { user_id: "eq." + identity.id, select: "*" });
        if (!r.ok) return error(503);
        return json({ places: await r.json() });
      }
      if (req.method === "POST") {
        const data = await body(req);
        if (!data) return error(400);
        const fields = ["venue_kind", "place_name", "city", "general_zone", "is_favorite"];
        const place: Record<string, unknown> = { user_id: identity.id };
        for (const k of fields) if (data[k] !== undefined) place[k] = data[k];
        const r = await endpoint("POST", "/rest/v1/member_training_places_v26", token,
          place, {}, "return=representation");
        if (!r.ok) return error(r.status === 400 ? 400 : 503);
        const values = await r.json();
        return json({ place: values[0] ?? null }, 201);
      }
    }
    if (route.startsWith("/v1/me/places/") && req.method === "DELETE") {
      const id = route.slice("/v1/me/places/".length);
      if (!/^[0-9a-f-]{36}$/.test(id)) return error(400);
      const r = await endpoint("DELETE", "/rest/v1/member_training_places_v26", token,
        undefined, { id: "eq." + id, user_id: "eq." + identity.id });
      return forward(r, { ok: true });
    }
    // Media cannot be published until sanitization, moderation and owner-only
    // preview are deployed. A zero-result list keeps the profile functional.
    if (route === "/v1/me/photos" && req.method === "GET") return json({ photos: [] });
    if (route === "/v1/dating/status" && req.method === "GET") {
      return json(await datingStatus(token, identity.id));
    }
    if (route === "/v1/dating/consent" && req.method === "POST") {
      const reqData = await body(req);
      if (reqData?.opt_in !== true) return error(400);
      const r = await endpoint("POST", "/rest/v1/member_consents_v26", token,
        { user_id: identity.id, consent_kind: "dating",
          document_version: "dating-v1", source: "profile_settings" },
        {}, "return=representation");
      if (!r.ok) return error(503);
      return json({ recorded: true }, 201);
    }
    if (route === "/v1/dating/candidates" && req.method === "GET") {
      const state = await datingStatus(token, identity.id);
      if (!state.enabled) return error(403);
      const r = await endpoint("POST", "/rest/v1/rpc/discover_dating_candidates",
        token, { p_limit: 10 });
      if (!r.ok) return error(r.status === 403 ? 403 : 503);
      const values = await r.json();
      return json({ items: values, count: values.length });
    }
    return error(404);
  } catch (exception) {
    console.error("member-api-v26 internal error", exception instanceof Error ? exception.name : "unknown");
    return error(503);
  }
});
