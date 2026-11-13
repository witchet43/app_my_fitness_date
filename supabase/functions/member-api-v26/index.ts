// My Fitness Date V27: unprivileged, authenticated Edge API.
// RLS is enforced by forwarding the end user's JWT to PostgREST.
// There is deliberately no service-role key and no public media publishing.
import { resolvePublishableKey, extractApiRoute, memberCorsRequestHeaders } from "./config.ts";
import { activityRsvpRoute, activityCancelRoute, organizerCancelRoute, adminCancelRoute, validateActivityDraft } from "./activity_validation.ts";
import { communityUuid, validateCommunityPost, validateCommunityReport, validateModeration, communityRemovePostId, communityFeedCursor, adminAnnouncementId } from "./community_validation.ts";
import { validateDatingPreferencesB5 } from "./dating_validation.ts";
import { validateRhythmB11 } from "./rhythm_validation_b11.ts";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const localQa = Deno.env.get("MFD_LOCAL_QA") === "true" &&
  /^http:\/\/(?:kong|127\.0\.0\.1|localhost|host\.docker\.internal)(?::[0-9]+)?\/?/i.test(SUPABASE_URL);
const qaAnon = localQa ? Deno.env.get("SUPABASE_ANON_KEY") : undefined;
const publishable = resolvePublishableKey(
  Deno.env.get("SUPABASE_PUBLISHABLE_KEYS"),
  (name) => Deno.env.get(name),
) ?? (localQa && qaAnon?.startsWith("eyJ") ? qaAnon : undefined);
// One exact origin per deployment. QA can use a separate Supabase environment
// with an explicit staging origin; production defaults to the real application.
// Never reflect arbitrary Origin headers or use "*".
const configuredOrigin = Deno.env.get("MFD_ALLOWED_ORIGIN") ??
  "https://my-fitness-date.pages.dev";
const origin = /^https:\/\/[a-z0-9.-]+(?::[0-9]{1,5})?$/i.test(configuredOrigin) ||
  /^http:\/\/localhost:[0-9]{2,5}$/i.test(configuredOrigin)
    ? configuredOrigin : "https://my-fitness-date.pages.dev";
// Explicit preview origin is trusted for the isolated B2 QA site only.
// Browser Authorization headers remain required and roles enforced in SQL.
const allowedOrigins = new Set([
  origin,
  "https://b2-preview.my-fitness-date.pages.dev",
  "https://b3-preview.my-fitness-date.pages.dev",
  "https://b4-preview.my-fitness-date.pages.dev",
  "https://b5-preview.my-fitness-date.pages.dev",
  "https://b8-preview.my-fitness-date.pages.dev",
  "https://b9-preview.my-fitness-date.pages.dev",
  "https://b10-preview.my-fitness-date.pages.dev",
  "https://b11-preview.my-fitness-date.pages.dev",
  ...(localQa ? ["http://127.0.0.1:5173"] : []),
]);
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
async function datingStatus(token: string, _id: string) {
  // B5 is the server-authoritative gate. Client consent alone can NEVER enable
  // matchmaking: independent age verification and moderation remain NO-GO.
  const r = await endpoint("POST",
    "/rest/v1/rpc/fitdating_status_b5", token, {});
  if (!r.ok) throw new Error("dating status unavailable");
  const value = await r.json();
  if (value == null || typeof value !== "object") {
    throw new Error("invalid dating status");
  }
  return value as Record<string, unknown>;
}
const editable = new Set([
  "display_name", "date_of_birth", "city", "about_me", "headline", "occupation",
  "languages", "hobbies", "life_values", "prompts", "sports", "fitness_goals",
  "achievements", "training_frequency", "dating_intent", "social_visibility",
  "onboarding_complete",
]);
async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    const requestedOrigin = req.headers.get("origin");
    // QA previews must pass their own exact allowlisted origin; never use *.
    if (requestedOrigin && !allowedOrigins.has(requestedOrigin)) return error(403);
    return new Response(null, {
      status: 204,
      headers: requestedOrigin
        ? { ...cors, "Access-Control-Allow-Origin": requestedOrigin }
        : cors,
    });
  }
  const requestedOrigin = req.headers.get("origin");
  if (requestedOrigin && !allowedOrigins.has(requestedOrigin)) return error(403);
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
        undefined, { user_id: "eq." + identity.id, cancelled_at: "is.null", select: "event_id" });
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
    // B2: private RSVP lifecycle via SECURITY DEFINER RPC; no participant IDs.
    if (route === "/v1/me/activities" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/my_activity_reservations", token, {});
      if (!response.ok) return error(response.status === 403 ? 403 : 503);
      const items = await response.json();
      return json({ items: Array.isArray(items) ? items : [] });
    }
    const cancelMyEventId = activityCancelRoute(route);
    if (cancelMyEventId && req.method === "POST") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/cancel_activity_rsvp", token,
        { p_event_id: cancelMyEventId });
      if (!response.ok) return error(response.status === 403 ? 403 : 503);
      const status = await response.json();
      if (status === "cancelled" || status === "already_cancelled") {
        return json({ status, event_id: cancelMyEventId });
      }
      if (status === "already_started") return json({ status }, 409);
      if (status === "not_confirmed" || status === "not_authenticated") {
        return json({ status }, 403);
      }
      return error(503);
    }
    if (route === "/v1/organizer/activities" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/my_organized_activities", token, {});
      if (!response.ok) return error(response.status === 403 ? 403 : 503);
      const items = await response.json();
      return json({ items: Array.isArray(items) ? items : [] });
    }
    const cancelOrganizedId = organizerCancelRoute(route);
    if (cancelOrganizedId && req.method === "POST") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/cancel_organized_activity", token,
        { p_event_id: cancelOrganizedId });
      if (!response.ok) return error(response.status === 403 ? 403 : 503);
      const status = await response.json();
      if (status === "cancelled" || status === "already_cancelled") {
        return json({ status, event_id: cancelOrganizedId });
      }
      if (status === "already_started") return json({ status }, 409);
      if (status === "not_authorized") return json({ status }, 403);
      return error(503);
    }
    // B2: owner MFA/AAL2 can curate genuine activities without assuming a
    // member identity. Permission is verified in DB on EVERY mutation.
    if (route === "/v1/admin/activities" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/admin_curated_activities", token, {});
      if (!response.ok) return error(response.status === 403 ? 403 : 503);
      const items = await response.json();
      return json({ items: Array.isArray(items) ? items : [] });
    }
    if (route === "/v1/admin/activities" && req.method === "POST") {
      const bodyData = await body(req);
      const data = bodyData == null ? null : validateActivityDraft(bodyData);
      if (!data) return error(400);
      const response = await endpoint("POST",
        "/rest/v1/rpc/admin_publish_curated_activity", token, {
          p_title: data.title, p_description: data.description,
          p_sport: data.sport, p_city: data.city,
          p_starts_at: data.starts_at, p_capacity: data.capacity,
        });
      if (response.status === 401 || response.status === 403) return error(403);
      if (!response.ok) return error(response.status === 400 ? 400 : 503);
      const id = await response.json();
      return json({ activity: { id, ...data } }, 201);
    }
    const adminCancelId = adminCancelRoute(route);
    if (adminCancelId && req.method === "POST") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/admin_cancel_curated_activity", token,
        { p_event_id: adminCancelId });
      if (response.status === 401 || response.status === 403) return error(403);
      if (!response.ok) return error(503);
      const status = await response.json();
      if (status === "cancelled" || status === "already_cancelled") {
        return json({ status, event_id: adminCancelId });
      }
      if (status === "already_started") return json({ status }, 409);
      if (status === "not_authorized" || status === "not_found") {
        return json({ status }, 403);
      }
      return error(503);
    }
    // B4: authenticated, separately consented member community. Every RPC
    // rechecks actor, age, consent, content visibility and block relationships.
    if (route === "/v1/community/status" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_status_b4", token, {});
      if (!response.ok) return error(503);
      return json({ status: await response.json() });
    }
    if (route === "/v1/community/feed" && req.method === "GET") {
      const before = communityFeedCursor(new URL(req.url).searchParams.get("before"));
      if (before === false) return error(400);
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_feed_b4", token,
        { p_before: before, p_limit: 15 });
      if (!response.ok) return error(response.status === 403 ? 403 : 503);
      const items = await response.json();
      return json({ items: Array.isArray(items) ? items : [] });
    }
    if (route === "/v1/community/posts" && req.method === "POST") {
      const data = await body(req);
      const values = data && validateCommunityPost(data);
      if (!values) return error(400);
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_publish_b4", token, values);
      if (!response.ok) return error(response.status === 403 ? 403 : 503);
      const item = await response.json() as {status?: string; id?: string};
      if (item.status === "published") {
        return json({ status: "published", id: item.id }, 201);
      }
      if (item.status === "rate_limited") return json({status:item.status},429);
      if (item.status === "invalid") return json({status:item.status},400);
      return json({status:item.status??"forbidden"},403);
    }
    const removeId = communityRemovePostId(route);
    if (removeId && req.method === "DELETE") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_remove_post_b4", token,
        {p_post_id:removeId});
      if (!response.ok) return error(503);
      const status = await response.json();
      return status === "removed" ? json({status}) : json({status},403);
    }
    if (route === "/v1/community/blocks" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_my_blocks_b4", token, {});
      if (!response.ok) return error(503);
      const items = await response.json();
      return json({items:Array.isArray(items)?items:[]});
    }
    if (route === "/v1/community/block" && req.method === "POST") {
      const data = await body(req);
      if (!data || typeof data.user_id !== "string" ||
          !communityUuid.test(data.user_id) ||
          typeof data.blocked !== "boolean") return error(400);
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_block_b4",token,
        {p_user_id:data.user_id,p_block:data.blocked});
      if (!response.ok) return error(503);
      const status = await response.json();
      if (status === "blocked" || status === "unblocked") return json({status});
      if (status === "rate_limited") return json({status},429);
      return json({status},403);
    }
    if (route === "/v1/community/report" && req.method === "POST") {
      const data = await body(req);
      const values = data && validateCommunityReport(data);
      if (!values) return error(400);
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_report_b4",token,values);
      if (!response.ok) return error(503);
      const status = await response.json();
      if (status === "reported" || status === "already_reported") {
        return json({status},status === "reported" ? 201 : 200);
      }
      if (status === "rate_limited") return json({status},429);
      return json({status},403);
    }
    if (route === "/v1/me/community/participation" &&
        req.method === "POST") {
      const data=await body(req);
      if (!data || typeof data.enabled!=="boolean") return error(400);
      const response=await endpoint("POST",
        "/rest/v1/rpc/community_set_participation_b4",
        token,{p_enabled:data.enabled});
      if (!response.ok) return error(503);
      const status=await response.json();
      if (status==="enabled" || status==="disabled") return json({status});
      if (status==="consent_required") return json({status},403);
      return json({status},403);
    }
    if (route === "/v1/me/community/posts" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_my_post_history_b4",token,{});
      if (!response.ok) return error(503);
      const items = await response.json();
      return json({items:Array.isArray(items)?items:[]});
    }
    if (route === "/v1/me/community/deletion" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_deletion_status_b4",token,{});
      if (!response.ok) return error(503);
      return json({status:await response.json()});
    }
    if (route === "/v1/me/community/deletion" && req.method === "POST") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/community_request_deletion_b4",token,{});
      if (!response.ok) return error(503);
      const status = await response.json();
      return status === "pending" ? json({status}) : json({status},403);
    }
    // Moderator is an independent owner with verified MFA (AAL2).
    // No reporter ID is included in the moderation queue payload.
    if (route === "/v1/admin/community/announcements" &&
        req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/admin_community_announcements_b4",token,{});
      if (!response.ok) return error(503);
      const items=await response.json();
      return json({items:Array.isArray(items)?items:[]});
    }
    if (route === "/v1/admin/community/announcements" &&
        req.method === "POST") {
      const data=await body(req);
      const values=data && validateCommunityPost(data);
      if (!values) return error(400);
      const response=await endpoint("POST",
        "/rest/v1/rpc/admin_community_publish_b4",token,values);
      if (!response.ok) return error(503);
      const item=await response.json() as {status?:string;id?:string};
      if (item.status==="published") return json(item,201);
      if (item.status==="rate_limited") return json(item,429);
      if (item.status==="invalid") return json(item,400);
      return json(item,403);
    }
    const announcementId=adminAnnouncementId(route);
    if (announcementId && req.method==="DELETE") {
      const response=await endpoint("POST",
        "/rest/v1/rpc/admin_community_remove_announcement_b4",
        token,{p_post_id:announcementId});
      if (!response.ok) return error(503);
      const status=await response.json();
      return status==="removed" ? json({status}) : json({status},403);
    }
    if (route === "/v1/admin/community/pilot" && req.method === "GET") {
      const response=await endpoint("POST",
        "/rest/v1/rpc/admin_community_pilot_members_b4",token,{});
      if (!response.ok) return error(503);
      const items=await response.json();
      return json({items:Array.isArray(items)?items:[]});
    }
    if (route === "/v1/admin/community/pilot" && req.method === "POST") {
      const data=await body(req);
      if (!data || typeof data.email!=="string" ||
          data.email.length<5 || data.email.length>254 ||
          !/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/i.test(data.email.trim())) {
        return error(400);
      }
      const response=await endpoint("POST",
        "/rest/v1/rpc/admin_community_admit_pilot_b4",token,
        {p_email:data.email.trim()});
      if (!response.ok) return error(503);
      const status=await response.json();
      return status==="admitted" ? json({status}) : json({status},403);
    }
    if (route === "/v1/admin/community/pilot/revoke" &&
        req.method === "POST") {
      const data=await body(req);
      if (!data || typeof data.user_id!=="string" ||
          !communityUuid.test(data.user_id)) return error(400);
      const response=await endpoint("POST",
        "/rest/v1/rpc/admin_community_revoke_pilot_b4",token,
        {p_user_id:data.user_id});
      if (!response.ok) return error(503);
      const status=await response.json();
      return status==="revoked" ? json({status}) : json({status},403);
    }
    if (route === "/v1/admin/community/reports" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/admin_community_queue_b4",token,{});
      if (!response.ok) return error(response.status === 403 ? 403 : 503);
      const items = await response.json();
      return json({items:Array.isArray(items)?items:[]});
    }
    if (route === "/v1/admin/community/resolve" && req.method === "POST") {
      const data = await body(req);
      const values = data && validateModeration(data);
      if (!values) return error(400);
      const response = await endpoint("POST",
        "/rest/v1/rpc/admin_community_resolve_b4",token,values);
      if (!response.ok) return error(503);
      const status = await response.json();
      if (status === "resolved") return json({status});
      if (status === "already_reviewed") return json({status},409);
      return json({status},403);
    }
    if (route === "/v1/admin/community/deletions" && req.method === "GET") {
      const response = await endpoint("POST",
        "/rest/v1/rpc/admin_community_deletion_queue_b4",token,{});
      if (!response.ok) return error(response.status === 403 ? 403 : 503);
      const items = await response.json();
      return json({items:Array.isArray(items)?items:[]});
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
    // B11 real owner-only lifestyle persistence. A private profile requires
    // separate dating consent and is never discoverable merely by saving it.
    if (route === "/v1/dating/rhythm" && req.method === "GET") {
      const r = await endpoint("GET", "/rest/v1/member_rhythm_b11", token,
        undefined, { user_id: "eq." + identity.id,
          select: "answers,additional_sports,weekends,interests,challenge,weeknight,support,updated_at" });
      if (!r.ok) return error(r.status === 403 ? 403 : 503);
      const rows = await r.json() as Array<Record<string,unknown>>;
      return json({ profile: rows[0] ?? null });
    }
    if (route === "/v1/dating/rhythm" && req.method === "PUT") {
      const input = await body(req);
      const draft = validateRhythmB11(input);
      if (!draft) return error(400);
      const r = await endpoint("POST", "/rest/v1/member_rhythm_b11",
        token, {user_id:identity.id,...draft},
        {on_conflict:"user_id"}, "resolution=merge-duplicates,return=representation");
      if (!r.ok) return error(r.status === 400 ? 400 : 403);
      const rows = await r.json() as Array<Record<string,unknown>>;
      return json({profile:rows[0] ?? null});
    }
    // All live candidate, matching and chat RPCs check the independent
    // external age review, staffed moderation and release flag IN DATABASE.
    // Catalog contains only names published by the operator. Never surface
    // the three synthetic Gym Demo fixtures from old local integration tests.
    if (route === "/v1/dating/b11/gyms" && req.method === "GET") {
      const state = await datingStatus(token,identity.id);
      if (state.discovery_release_ready !== true) return error(403);
      const r = await endpoint("GET","/rest/v1/gyms",token,undefined,
        {select:"id,name,city",order:"name.asc",limit:"100"});
      if(!r.ok)return error(503);
      const values=await r.json() as Array<Record<string,unknown>>;
      const verified=values.filter(x=>
        typeof x.id==="string" && typeof x.name==="string" &&
        typeof x.city==="string" &&
        !/^\s*gym demo/i.test(x.name));
      return json({items:verified});
    }
    if (route === "/v1/dating/b11/activate" && req.method === "POST") {
      const data=await body(req);
      const gymId=data?.gym_id;
      const slots=data?.weekly_slots;
      if(typeof gymId!=="string" ||
         !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(gymId) ||
         !Array.isArray(slots) || slots.length>14 ||
         slots.some(x=>{
           if(!x||typeof x!=="object"||Array.isArray(x))return true;
           const item=x as Record<string,unknown>;
           if(Object.keys(item).some(k=>
             !["day","startMinutes","endMinutes"].includes(k)))return true;
           const day=item.day,start=item.startMinutes,end=item.endMinutes;
           return !Number.isInteger(day)||!Number.isInteger(start)||
             !Number.isInteger(end)||
             (day as number)<0||(day as number)>6||
             (start as number)<0||(end as number)>1440||
             (start as number)>=(end as number);
         }))return error(400);
      const r=await endpoint("POST","/rest/v1/rpc/fitdating_activate_b11",
        token,{p_gym_id:gymId,p_weekly_slots:slots});
      if(!r.ok)return error(r.status===401||r.status===403?403:503);
      const value=await r.json();
      if(value==="activated")return json({status:"activated"});
      if(value==="not_eligible")return error(403);
      if(["gym_unavailable","profile_required","schedule_required",
          "invalid_schedule"].includes(String(value)))
        return json({status:value},409);
      return error(403);
    }
    if (route === "/v1/dating/b11/candidates" && req.method === "GET") {
      const state = await datingStatus(token, identity.id);
      if(state.enabled !== true) return error(403);
      const r = await endpoint("POST",
        "/rest/v1/rpc/fitdating_candidates_b11",token,{p_limit:10});
      if(!r.ok) return error(r.status===403 ? 403 : 503);
      const values = await r.json() as unknown[];
      return json({items:values,count:values.length});
    }
    if (route === "/v1/dating/b11/like" && req.method === "POST") {
      const input=await body(req);
      const id=String(input?.user_id??"");
      if(!/^[a-f0-9-]{36}$/i.test(id))return error(400);
      const r=await endpoint("POST",
        "/rest/v1/rpc/fitdating_like_b11",token,{p_user_id:id});
      if(!r.ok)return error(403);
      const status=await r.json();
      return status==="matched"||status==="liked"
        ? json({status})
        : error(status==="rate_limited"?429:403);
    }
    if (route === "/v1/dating/b11/matches" && req.method === "GET") {
      const state=await datingStatus(token,identity.id);
      if(state.enabled!==true)return error(403);
      const r=await endpoint("POST",
        "/rest/v1/rpc/fitdating_my_matches_b11",token,{});
      if(!r.ok)return error(403);
      return json({items:await r.json()});
    }
    // Scope every chat access to a UUID match. Ownership, mutual consent,
    // blocking and moderation are rechecked inside each SECURITY DEFINER.
    const b11Match=/^\/v1\/dating\/b11\/matches\/([0-9a-f-]{36})\/(messages|report|ideas)$/i.exec(route);
    if(b11Match){
      const matchId=b11Match[1];
      const kind=b11Match[2];
      if(kind==="messages"&&req.method==="GET"){
        const r=await endpoint("POST",
          "/rest/v1/rpc/fitdating_my_messages_b11",token,{p_match:matchId});
        if(!r.ok)return error(403);
        return json({items:await r.json()});
      }
      if(kind==="messages"&&req.method==="POST"){
        const payload=await body(req);
        if(typeof payload?.body!=="string" || payload.body.trim().length<1 ||
          payload.body.length>1200)return error(400);
        const r=await endpoint("POST",
          "/rest/v1/rpc/fitdating_send_b11",token,
          {p_match:matchId,p_body:payload.body.trim()});
        if(!r.ok)return error(403);
        const status=await r.json();
        return status==="sent"?json({status})
          :error(status==="rate_limited"?429:403);
      }
      if(kind==="report"&&req.method==="POST"){
        const payload=await body(req);
        const reason=payload?.reason;
        const detail=payload?.detail??"";
        if(typeof reason!=="string" ||
          !["harassment","spam","impersonation","unsafe","other"].includes(reason)
          ||typeof detail!=="string"||detail.length>500)return error(400);
        const r=await endpoint("POST",
          "/rest/v1/rpc/fitdating_report_b11",token,
          {p_match:matchId,p_reason:reason,p_detail:detail});
        if(!r.ok)return error(403);
        const status=await r.json();
        return status==="reported_and_blocked"?json({status})
          :error(status==="rate_limited"?429:403);
      }
      if(kind==="ideas"&&req.method==="GET"){
        const r=await endpoint("POST",
          "/rest/v1/rpc/fitdating_date_ideas_b11",token,{p_match:matchId});
        if(!r.ok)return error(403);
        const codes=await r.json();
        return json({items:Array.isArray(codes)?codes:[]});
      }
      return error(405);
    }
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
    if (route === "/v1/dating/preferences" && req.method === "POST") {
      const raw = await body(req);
      const draft = validateDatingPreferencesB5(raw);
      if (!draft) return error(400);
      const result = await endpoint("POST",
        "/rest/v1/rpc/fitdating_save_preferences_b5", token, draft);
      if (result.status === 401 || result.status === 403) return error(403);
      if (!result.ok) return error(503);
      const status = await result.json();
      if (status === "saved") return json({ status: "saved" });
      if (status === "consent_required") return json({ status }, 403);
      if (status === "invalid") return json({ status }, 400);
      return error(403);
    }
    if (route === "/v1/dating/disable" && req.method === "POST") {
      const result = await endpoint("POST",
        "/rest/v1/rpc/fitdating_disable_b5", token, {});
      if (result.status === 401 || result.status === 403) return error(403);
      if (!result.ok) return error(503);
      const status = await result.json();
      return status === "disabled"
        ? json({ status: "disabled" }) : error(403);
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
}

Deno.serve(async (req: Request): Promise<Response> => {
  const response = await handleRequest(req);
  const requestingOrigin = req.headers.get("origin");
  if (!requestingOrigin || !allowedOrigins.has(requestingOrigin)) {
    return response;
  }
  const headers = new Headers(response.headers);
  headers.set("Access-Control-Allow-Origin", requestingOrigin);
  return new Response(response.body, { status: response.status, headers });
});
