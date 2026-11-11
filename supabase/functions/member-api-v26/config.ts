// Only non-privileged, publishable keys may be used from this Edge Function.
// Supabase's SUPABASE_PUBLISHABLE_KEYS maps names (e.g. "default") to the
// names of environment variables holding actual keys.
export function resolvePublishableKey(
  json: string | undefined,
  readEnv: (name: string) => string | undefined,
): string | undefined {
  if (!json) return undefined;
  let names: unknown;
  try {
    names = JSON.parse(json);
  } catch {
    return undefined;
  }
  if (!names || typeof names !== "object") return undefined;
  const keyName = (names as Record<string, unknown>)["default"];
  if (typeof keyName !== "string" || !/^SUPABASE_[A-Z0-9_]+$/.test(keyName)) {
    return undefined;
  }
  const value = readEnv(keyName);
  return value?.startsWith("sb_publishable_") ? value : undefined;
}

export function extractApiRoute(path: string): string | null {
  // Some proxies include /functions/v1/ before the app's /v1/* endpoint.
  const i = path.lastIndexOf("/v1/");
  return i === -1 ? null : path.slice(i);
}
