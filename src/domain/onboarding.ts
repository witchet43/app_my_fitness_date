/** Date/time helpers for demo signup. Server validation is authoritative. */
export function isAdult(value: string, today = new Date()): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [year, month, day] = value.split('-').map(Number);
  const parsed = new Date(Date.UTC(year, month - 1, day));
  if (parsed.getUTCFullYear() !== year || parsed.getUTCMonth() !== month - 1
      || parsed.getUTCDate() !== day || year < 1900) return false;
  const utcToday = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()));
  const eighteenthBirthday = new Date(Date.UTC(year + 18, month - 1, day));
  return eighteenthBirthday <= utcToday;
}

export function parseClock(value: string): number | null {
  if (!/^\d{2}:\d{2}$/.test(value)) return null;
  const [hour, minute] = value.split(':').map(Number);
  if (hour < 0 || hour > 24 || minute > 59 || (hour === 24 && minute !== 0)) return null;
  return hour * 60 + minute;
}
