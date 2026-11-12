import assert from 'node:assert/strict';
import test from 'node:test';
import { validateActivityDraft, activityRsvpRoute } from
  '../supabase/functions/member-api-v26/activity_validation';

const now = Date.parse('2026-11-12T12:00:00.000Z');
const valid = {
  title: 'Senderismo del domingo',
  description: 'Caminata recreativa en grupo por la ciudad.',
  sport: 'Senderismo',
  city: 'Querétaro',
  capacity: 20,
  starts_at: '2026-11-15T09:00:00-06:00',
};

test('organizer draft is normalized without accepting forged identity', () => {
  const result = validateActivityDraft({
    ...valid, organizer_id: 'forged', is_published: false,
    city: ' Querétaro ',
  }, now);
  assert.ok(result);
  assert.equal(result.city, 'Querétaro');
  assert.equal(result.starts_at, '2026-11-15T15:00:00.000Z');
  assert.equal(Object.hasOwn(result, 'organizer_id'), false);
  assert.equal(Object.hasOwn(result, 'is_published'), false);
});

test('invalid title, private data, limits and old dates fail closed', () => {
  assert.equal(validateActivityDraft({...valid, title:'x'}, now), null);
  assert.equal(validateActivityDraft({...valid, capacity:0}, now), null);
  assert.equal(validateActivityDraft({...valid, capacity:201}, now), null);
  assert.equal(validateActivityDraft({...valid, capacity:1.5}, now), null);
  assert.equal(validateActivityDraft({...valid, capacity:'20'}, now), null);
  assert.equal(validateActivityDraft({...valid, starts_at:'2026-11-11T11:00:00Z'}, now), null);
  assert.equal(validateActivityDraft({...valid, starts_at:'2027-09-01T11:00:00Z'}, now), null);
  assert.equal(validateActivityDraft({...valid, starts_at:'2026-11-15'}, now), null);
});

test('rsvp route rejects unauthorized paths and malformed UUIDs', () => {
  const id = 'bc8e3ef2-a487-46da-b3d1-d0747607a4bc';
  assert.equal(activityRsvpRoute(`/v1/activities/${id}/rsvp`), id);
  assert.equal(activityRsvpRoute('/v1/activities/nope/rsvp'), null);
  assert.equal(activityRsvpRoute(`/v1/activities/${id}/rsvp/other`), null);
  assert.equal(activityRsvpRoute('/v1/me/activities'), null);
});
