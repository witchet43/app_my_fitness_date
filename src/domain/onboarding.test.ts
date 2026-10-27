import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { isAdult, parseClock } from './onboarding';

const now = new Date('2026-10-26T20:00:00Z');
test('minimum age of 18 on the date', () => {
  assert.equal(isAdult('2008-10-26', now), true);
  assert.equal(isAdult('2008-10-27', now), false);
  assert.equal(isAdult('1990-01-31', now), true);
});
test('reject impossible and malformed dates', () => {
  assert.equal(isAdult('2007-02-29', now), false);
  assert.equal(isAdult('2010-13-01', now), false);
  assert.equal(isAdult('1900-01-01', now), true);
  assert.equal(isAdult('02/01/2000', now), false);
});
test('accept 24:00 for an end time, reject invalid clock', () => {
  assert.equal(parseClock('07:30'), 450);
  assert.equal(parseClock('24:00'), 1440);
  assert.equal(parseClock('24:01'), null);
  assert.equal(parseClock('9:30'), null);
  assert.equal(parseClock('07:60'), null);
});
