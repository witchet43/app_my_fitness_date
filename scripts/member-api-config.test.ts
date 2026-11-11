import assert from 'node:assert/strict';
import test from 'node:test';
import { resolvePublishableKey, extractApiRoute } from '../supabase/functions/member-api-v26/config';

test('Supabase default is an env name; resolves actual publishable key', () => {
  const lookup = (name: string) =>
    name === 'SUPABASE_PUBLISHABLE_KEY' ? 'sb_publishable_test_public_only' : undefined;
  assert.equal(
    resolvePublishableKey('{"default":"SUPABASE_PUBLISHABLE_KEY"}', lookup),
    'sb_publishable_test_public_only',
  );
});

test('do not treat the environment variable name itself as an API key', () => {
  assert.equal(resolvePublishableKey('{"default":"SUPABASE_PUBLISHABLE_KEY"}', () => undefined), undefined);
});

test('invalid, missing, private or malformed config fails closed', () => {
  const cases = ['', 'not-json', '{"default":123}', '{"default":"EXTERNAL_SECRET"}',
    '{"default":"SUPABASE_SERVICE_ROLE_KEY"}'];
  for (const item of cases) {
    assert.equal(resolvePublishableKey(item, () => 'unsafe-private-value'), undefined);
  }
  assert.equal(resolvePublishableKey(
    '{"default":"SUPABASE_PUBLISHABLE_KEY"}', () => 'sb_secret_must_not_be_used'), undefined);
});

test('resolve final business API version marker when proxy has its own version', () => {
  assert.equal(extractApiRoute('/member-api-v26/v1/me/consents'), '/v1/me/consents');
  assert.equal(extractApiRoute('/functions/v1/member-api-v26/v1/me/profile'), '/v1/me/profile');
  assert.equal(extractApiRoute('/functions/v1/member-api-v26/v1/dating/status'), '/v1/dating/status');
  assert.equal(extractApiRoute('/healthz'), null);
});
