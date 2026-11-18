import { parseClock } from './onboarding';
import type { Weekday, WeeklySlot } from './gymShield';

/** Form data only. Numeric backend intervals are built AFTER validation. */
export interface ScheduleDraft {
  id: number;
  day: number;
  start: string;
  end: string;
}

export type ScheduleValidation =
  | { ok: true; slots: WeeklySlot[] }
  | { ok: false; error: string };

export function parseScheduleDrafts(
  drafts: ScheduleDraft[],
  required: boolean,
): ScheduleValidation {
  if (drafts.length > 14) {
    return { ok: false, error: 'Máximo 14 bloques semanales.' };
  }
  if (required && drafts.length === 0) {
    return { ok: false, error: 'Registra al menos un horario para tu gimnasio.' };
  }
  const slots: WeeklySlot[] = [];
  for (const entry of drafts) {
    const startMinutes = parseClock(entry.start);
    const endMinutes = parseClock(entry.end);
    if (!Number.isInteger(entry.day) || entry.day < 0 || entry.day > 6
      || startMinutes === null || endMinutes === null
      || startMinutes >= endMinutes || startMinutes >= 1440) {
      return { ok: false, error: 'Revisa el día y el formato HH:MM de cada horario.' };
    }
    const day = entry.day as Weekday;
    if (slots.some(s => s.day === day && s.startMinutes < endMinutes && startMinutes < s.endMinutes)) {
      return { ok: false, error: 'Hay bloques superpuestos para el mismo día.' };
    }
    slots.push({ day, startMinutes, endMinutes });
  }
  return { ok: true, slots: slots.sort((a,b)=>a.day-b.day || a.startMinutes-b.startMinutes) };
}
