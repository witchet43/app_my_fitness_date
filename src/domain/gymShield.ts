/**
 * Pure preview of Gym Shield eligibility.
 *
 * IMPORTANT: This code runs in a demonstration client. In production, the
 * backend must perform filtering before returning any dating candidates.
 * Do not expose gym identifiers or schedules in API responses to users.
 */

export type Weekday = 0 | 1 | 2 | 3 | 4 | 5 | 6;
export type GymShieldMode = 'other_gyms' | 'same_gym_other_time';

export interface WeeklySlot {
  day: Weekday;
  /** Minutes after midnight; inclusive. Overnight slots are not supported in MVP. */
  startMinutes: number;
  /** Minutes after midnight; exclusive. */
  endMinutes: number;
}

export interface DatingProfile {
  id: string;
  displayName: string;
  gymId: string | null;
  mode: GymShieldMode;
  datingEnabled: boolean;
  weeklySlots: WeeklySlot[];
  blockedIds?: string[];
}

export const DEFAULT_BUFFER_MINUTES = 30;

export function isValidSlot(slot: WeeklySlot): boolean {
  return Number.isInteger(slot.day)
    && slot.day >= 0
    && slot.day <= 6
    && Number.isInteger(slot.startMinutes)
    && Number.isInteger(slot.endMinutes)
    && slot.startMinutes >= 0
    && slot.endMinutes <= 1440
    && slot.startMinutes < slot.endMinutes;
}

export function schedulesAreSeparated(
  first: WeeklySlot[],
  second: WeeklySlot[],
  bufferMinutes: number = DEFAULT_BUFFER_MINUTES,
): boolean {
  if (!first.length || !second.length) return false;
  if (!Number.isInteger(bufferMinutes) || bufferMinutes < 0) return false;
  if (![...first, ...second].every(isValidSlot)) return false;

  for (const a of first) {
    for (const b of second) {
      if (a.day !== b.day) continue;
      // A gap of exactly bufferMinutes is allowed. Any shorter gap is blocked.
      const gap = Math.max(b.startMinutes - a.endMinutes, a.startMinutes - b.endMinutes);
      if (gap < bufferMinutes) return false;
    }
  }

  return true;
}

/**
 * This function returns a boolean only, never an exclusion reason. Restrict
 * who can request a recommendation and protect the inputs on the server.
 */
export function isEligibleForDating(
  viewer: DatingProfile,
  candidate: DatingProfile,
  bufferMinutes: number = DEFAULT_BUFFER_MINUTES,
): boolean {
  if (!viewer.datingEnabled || !candidate.datingEnabled) return false;
  if (!viewer.id || !candidate.id || viewer.id === candidate.id) return false;
  if (viewer.blockedIds?.includes(candidate.id) || candidate.blockedIds?.includes(viewer.id)) return false;
  if (!viewer.gymId?.trim() || !candidate.gymId?.trim()) return false;
  if (viewer.gymId !== candidate.gymId) return true;

  // Same-gym matching is opt-in and symmetric.
  if (viewer.mode !== 'same_gym_other_time' || candidate.mode !== 'same_gym_other_time') {
    return false;
  }

  return schedulesAreSeparated(viewer.weeklySlots, candidate.weeklySlots, bufferMinutes);
}
