/** B5 payload validation; the client cannot supply identity or eligibility. */
export type PrivateDatingPreferencesB5 = {
  p_intent: "serious" | "companionship" | "exploring";
  p_sports: string[];
  p_frequency: "starting" | "weekly" | "frequent" | "flexible";
  p_mode: "other_gyms" | "same_gym_other_time";
  p_requested: boolean;
};

export const datingSportsB5 = Object.freeze([
  "running","cycling","hiking","strength","yoga",
  "hyrox","walking","swimming","other",
]);
const intents = new Set(["serious","companionship","exploring"]);
const frequencies = new Set(["starting","weekly","frequent","flexible"]);
const modes = new Set(["other_gyms","same_gym_other_time"]);
const sports = new Set(datingSportsB5);

export function validateDatingPreferencesB5(
  raw: unknown,
): PrivateDatingPreferencesB5 | null {
  if (typeof raw !== "object" || raw === null || Array.isArray(raw)) return null;
  const input = raw as Record<string,unknown>;
  const intent = input.intent;
  const frequency = input.frequency;
  const mode = input.mode;
  const requested = input.requested;
  const activities = input.sports;
  if (typeof intent !== "string" || !intents.has(intent) ||
      typeof frequency !== "string" || !frequencies.has(frequency) ||
      typeof mode !== "string" || !modes.has(mode) ||
      typeof requested !== "boolean" ||
      !Array.isArray(activities) || activities.length > 8 ||
      activities.some((value:unknown) =>
        typeof value !== "string" || !sports.has(value)) ||
      new Set(activities).size !== activities.length) {
    return null;
  }
  return {
    p_intent: intent as PrivateDatingPreferencesB5["p_intent"],
    p_frequency: frequency as PrivateDatingPreferencesB5["p_frequency"],
    p_mode: mode as PrivateDatingPreferencesB5["p_mode"],
    p_requested: requested,
    p_sports: activities as string[],
  };
}
