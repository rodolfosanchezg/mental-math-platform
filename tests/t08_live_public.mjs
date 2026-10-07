import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { supabaseConfig } from '../src/js/config.js';

// One nonexistent account: no administrator credentials or persistent fixtures.
const headers = { apikey: supabaseConfig.publishableKey, 'Content-Type': 'application/json' };
const response = await fetch(`${supabaseConfig.url}/auth/v1/token?grant_type=password`, {
  method: 'POST', headers, signal: AbortSignal.timeout(15000),
  body: JSON.stringify({ email: `qa${randomUUID().replaceAll('-', '').slice(0, 20)}@mental-math.invalid`, password: randomUUID() }),
});
assert.equal(response.status, 400, 'Expected rejected nonexistent account; values suppressed');
const result = await response.json();
assert.equal(result.error_code, 'invalid_credentials', 'Expected generic invalid credentials');
const settings = await fetch(`${supabaseConfig.url}/auth/v1/settings`, { headers, signal: AbortSignal.timeout(15000) });
assert.equal(settings.status, 200, 'Public API key must be accepted');
const settingsBody = await settings.json();
assert.equal(settingsBody.disable_signup, true);
assert.equal(settingsBody.external.email, true);
assert.equal(settingsBody.external.anonymous_users, false);
const personal = await fetch(`${supabaseConfig.url}/rest/v1/players?select=id`, { headers, signal: AbortSignal.timeout(15000) });
assert.ok([401, 403].includes(personal.status), 'Anonymous profile access must be denied');
console.log('PASS: public configuration, real Auth invalid credentials, signup/anonymous disabled, anonymous RLS denial');
