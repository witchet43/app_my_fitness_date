/** B4 input validation on untrusted Edge JSON; database revalidates. */
export const communityUuid =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export const topics = new Set([
  "running", "cycling", "hiking", "gym", "wellness", "other",
]);
export const reportReasons = new Set([
  "harassment", "spam", "privacy", "unsafe", "other",
]);
export const moderationActions = new Set([
  "hide_post", "suspend_user", "dismiss",
]);
const privateDataPattern =
  /(https?:\/\/|www\.|[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}|[0-9]{8,})/i;

export function validateCommunityPost(value: Record<string, unknown>):
  { p_topic: string; p_content: string } | null {
  const topic = value.topic;
  const body = value.content;
  if (typeof topic !== "string" || !topics.has(topic) ||
      typeof body !== "string") return null;
  const trimmed = body.trim();
  if (trimmed.length < 15 || trimmed.length > 480 ||
      privateDataPattern.test(trimmed)) return null;
  return { p_topic: topic, p_content: trimmed };
}

export function validateCommunityReport(value: Record<string, unknown>):
  { p_post_id: string | null; p_user_id: string | null;
    p_reason: string; p_detail: string } | null {
  const post = value.post_id == null ? null : value.post_id;
  const user = value.user_id == null ? null : value.user_id;
  const reason = value.reason;
  const detail = value.detail ?? "";
  if ((post === null) === (user === null) ||
      (post !== null && (typeof post !== "string" || !communityUuid.test(post))) ||
      (user !== null && (typeof user !== "string" || !communityUuid.test(user))) ||
      typeof reason !== "string" || !reportReasons.has(reason) ||
      typeof detail !== "string" || detail.length > 300) return null;
  return {
    p_post_id: post as string | null,
    p_user_id: user as string | null,
    p_reason: reason, p_detail: detail.trim(),
  };
}

export function validateModeration(value: Record<string, unknown>):
  { p_report_id: string; p_action: string; p_note: string } | null {
  const id = value.report_id;
  const action = value.action;
  const note = value.note;
  if (typeof id !== "string" || !communityUuid.test(id) ||
      typeof action !== "string" || !moderationActions.has(action) ||
      typeof note !== "string" || note.trim().length < 5 ||
      note.trim().length > 500) return null;
  return { p_report_id: id, p_action: action, p_note: note.trim() };
}

export function communityRemovePostId(path: string): string | null {
  const match = /^\/v1\/community\/posts\/([0-9a-f-]{36})$/i.exec(path);
  return match && communityUuid.test(match[1]) ? match[1] : null;
}

export function communityFeedCursor(raw: string | null): string | null | false {
  if (raw === null) return null;
  if (raw.length > 35 || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,6})?Z$/.test(raw) ||
      !Number.isFinite(Date.parse(raw))) return false;
  return raw;
}
