import assert from 'node:assert/strict';
import test from 'node:test';
import { activityCancelRoute, organizerCancelRoute } from
  '../supabase/functions/member-api-v26/activity_validation';

const uuid = 'bc8e3ef2-a487-46da-b3d1-d0747607a4bc';

test('B2 cancellation routes require exact UUID and do not admit user IDs', () => {
  assert.equal(activityCancelRoute(`/v1/activities/${uuid}/cancel`), uuid);
  assert.equal(organizerCancelRoute(`/v1/organizer/activities/${uuid}/cancel`), uuid);
  assert.equal(activityCancelRoute('/v1/activities/nope/cancel'), null);
  assert.equal(organizerCancelRoute(`/v1/organizer/activities/${uuid}/cancel/other`), null);
  assert.equal(activityCancelRoute('/v1/me/activities'), null);
});

test('B2 venue information is not accepted as a public event route', () => {
  assert.equal(activityCancelRoute('/v1/me/places/' + uuid), null);
  assert.equal(organizerCancelRoute('/v1/me/places/' + uuid), null);
});
