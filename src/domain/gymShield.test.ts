import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import {
  isEligibleForDating,
  isValidSlot,
  schedulesAreSeparated,
  type DatingProfile,
  type WeeklySlot,
} from './gymShield';

const morning: WeeklySlot[] = [{ day: 1, startMinutes: 420, endMinutes: 510 }];
const evening: WeeklySlot[] = [{ day: 1, startMinutes: 1080, endMinutes: 1170 }];

function profile(overrides: Partial<DatingProfile> = {}): DatingProfile {
  return {
    id: 'a', displayName: 'Persona A', gymId: 'gym-1',
    mode: 'same_gym_other_time', datingEnabled: true,
    weeklySlots: morning, ...overrides,
  };
}

test('different gyms are eligible regardless of schedule', () => {
  assert.equal(isEligibleForDating(profile({ mode: 'other_gyms' }), profile({ id: 'b', gymId: 'gym-2', mode: 'other_gyms' })), true);
});

test('the strict filter excludes all same-gym candidates', () => {
  assert.equal(isEligibleForDating(profile({ mode: 'other_gyms' }), profile({ id: 'b', weeklySlots: evening })), false);
});

test('both users must opt in to different hours at the same gym', () => {
  assert.equal(isEligibleForDating(profile(), profile({ id: 'b', weeklySlots: evening })), true);
  assert.equal(isEligibleForDating(profile(), profile({ id: 'b', weeklySlots: evening, mode: 'other_gyms' })), false);
});

test('overlapping intervals in the same weekday are excluded', () => {
  assert.equal(isEligibleForDating(profile(), profile({ id: 'b', weeklySlots: [{ day: 1, startMinutes: 480, endMinutes: 570 }] })), false);
});

test('different days are accepted even with equal clock times', () => {
  assert.equal(isEligibleForDating(profile(), profile({ id: 'b', weeklySlots: [{ day: 2, startMinutes: 420, endMinutes: 510 }] })), true);
});

test('the 30-minute safety buffer blocks adjacent sessions', () => {
  assert.equal(schedulesAreSeparated(morning, [{ day: 1, startMinutes: 539, endMinutes: 600 }]), false);
  assert.equal(schedulesAreSeparated(morning, [{ day: 1, startMinutes: 540, endMinutes: 600 }]), true);
});

test('incomplete or invalid schedules fail closed for same-gym candidates', () => {
  assert.equal(isEligibleForDating(profile(), profile({ id: 'b', weeklySlots: [] })), false);
  assert.equal(isValidSlot({ day: 1, startMinutes: 1400, endMinutes: 60 }), false);
  assert.equal(schedulesAreSeparated(morning, [{ day: 1, startMinutes: 1400, endMinutes: 60 }]), false);
});

test('disabled dating, missing gym identity, same user or blocks are excluded', () => {
  assert.equal(isEligibleForDating(profile(), profile()), false);
  assert.equal(isEligibleForDating(profile(), profile({ id: 'b', gymId: null })), false);
  assert.equal(isEligibleForDating(profile(), profile({ id: 'b', datingEnabled: false })), false);
  assert.equal(isEligibleForDating(profile({ blockedIds: ['b'] }), profile({ id: 'b', gymId: 'gym-2' })), false);
  assert.equal(isEligibleForDating(profile(), profile({ id: 'b', gymId: 'gym-2', blockedIds: ['a'] })), false);
});

test('same-gym multiple weekly sessions fail if any day overlaps', () => {
  const laterOnMonday = [{ day: 1, startMinutes: 1080, endMinutes: 1170 }, { day: 3, startMinutes: 420, endMinutes: 470 }] as WeeklySlot[];
  assert.equal(schedulesAreSeparated([{ day: 1, startMinutes: 420, endMinutes: 510 }, { day: 3, startMinutes: 420, endMinutes: 510 }], laterOnMonday), false);
});
