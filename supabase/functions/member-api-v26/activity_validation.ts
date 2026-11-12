/** Pure, independently testable B1 boundary validation. No user IDs may be supplied. */
export type ActivityDraft = {
  title: string;
  description: string;
  sport: string;
  city: string;
  starts_at: string;
  capacity: number;
};
export const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function bounded(value: unknown, min: number, max: number): string | null {
  if (typeof value !== "string") return null;
  const text = value.trim();
  return text.length >= min && text.length <= max ? text : null;
}

export function validateActivityDraft(
  value: Record<string, unknown>, nowMs = Date.now(),
): ActivityDraft | null {
  const title = bounded(value.title, 4, 100);
  const description = bounded(value.description, 10, 500);
  const sport = bounded(value.sport, 2, 40);
  const city = bounded(value.city, 2, 100);
  const capacity = value.capacity;
  const rawDate = value.starts_at;
  if (!title || !description || !sport || !city ||
      typeof capacity !== "number" || !Number.isInteger(capacity) ||
      capacity < 1 || capacity > 200 || typeof rawDate !== "string" ||
      !/^\d{4}-\d\d-\d\dT\d\d:\d\d(:\d\d)?(?:\.\d{1,3})?(Z|[+-]\d\d:\d\d)$/.test(rawDate)) {
    return null;
  }
  const time = Date.parse(rawDate);
  if (!Number.isFinite(time) || time <= nowMs + 10 * 60_000 ||
      time > nowMs + 180 * 24 * 60 * 60_000) return null;
  return { title, description, sport, city,
    starts_at: new Date(time).toISOString(), capacity: capacity as number };
}

export function activityRsvpRoute(path: string): string | null {
  const matched = /^\/v1\/activities\/([0-9a-f-]{36})\/rsvp$/.exec(path);
  return matched && uuidPattern.test(matched[1]) ? matched[1] : null;
}

/** B2 paths are exact; callers never provide another member identity. */
export function activityCancelRoute(path: string): string | null {
  const m = /^\/v1\/activities\/([0-9a-f-]{36})\/cancel$/.exec(path);
  return m && uuidPattern.test(m[1]) ? m[1] : null;
}

export function organizerCancelRoute(path: string): string | null {
  const m = /^\/v1\/organizer\/activities\/([0-9a-f-]{36})\/cancel$/.exec(path);
  return m && uuidPattern.test(m[1]) ? m[1] : null;
}

/** The owner admin can curate but cannot act as a member RSVP. */
export function adminCancelRoute(path: string): string | null {
  const m = /^\/v1\/admin\/activities\/([0-9a-f-]{36})\/cancel$/.exec(path);
  return m && uuidPattern.test(m[1]) ? m[1] : null;
}
