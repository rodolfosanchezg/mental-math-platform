import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createAuth, LOGIN_ERROR } from '../src/js/auth.js';

const config = { url: 'https://example.supabase.co', publishableKey: 'sb_publishable_fixture' };
const userId = '00000000-0000-0000-0000-000000000001';
const tokenResponse = { access_token: 'fixture-access-token', expires_in: 3600, user: { id: userId } };
const profileResponse = [{ id: userId, auth_user_id: userId }];
const reply = (value, status = 200) => ({ ok: status < 400, status, json: async () => value });

function fixture(responses) {
  const calls = [];
  let time = 1000;
  let expiry;
  const auth = createAuth(config, {
    now: () => time,
    setTimer: (fn) => { expiry = fn; return 1; }, clearTimer: () => {},
    fetchImpl: async (url, options) => {
      calls.push({ url, options });
      const response = responses.shift();
      if (response instanceof Error) throw response;
      return typeof response === 'function' ? response() : response;
    },
  });
  return { auth, calls, expire: () => expiry(), advance: (value) => { time += value; } };
}

test('invalid usernames and empty password never contact Supabase', async () => {
  const f = fixture([]);
  for (const username of ['AAa', 'a a', 'a_a', 'a-a', 'áaa', 'aa', 'a'.repeat(25)]) {
    await assert.rejects(f.auth.signIn(username, 'fixture-password'), { message: LOGIN_ERROR });
  }
  await assert.rejects(f.auth.signIn('valid123', ''), { message: LOGIN_ERROR });
  assert.equal(f.calls.length, 0);
});

test('username/password login and profile read use separate application key and user JWT', async () => {
  const f = fixture([reply(tokenResponse), reply(profileResponse), reply(null, 204)]);
  const changes = [];
  f.auth.subscribe((state) => changes.push(state));
  await f.auth.signIn('valid123', 'fixture-password');
  assert.equal(f.auth.isAuthenticated(), true);
  assert.deepEqual(JSON.parse(f.calls[0].options.body), { email: 'valid123@mental-math.invalid', password: 'fixture-password' });
  assert.equal(f.calls[0].options.headers.apikey, config.publishableKey);
  assert.equal(f.calls[0].options.headers.Authorization, undefined);
  assert.equal(f.calls[1].options.headers.Authorization, 'Bearer fixture-access-token');
  assert.ok(!f.calls[1].url.includes('auth_user_id=') && !f.calls[1].url.includes('username='));
  assert.equal(await f.auth.signOut(), true);
  assert.equal(f.auth.isAuthenticated(), false);
  assert.ok(f.calls[2].url.endsWith('/logout?scope=local'));
  assert.equal(changes.at(-1), false);
});

test('credential, rate limit, server and network failures have the same generic message', async () => {
  for (const status of [400, 401, 404, 429, 500]) {
    const f = fixture([reply({ msg: 'technical@email.invalid internal error' }, status)]);
    await assert.rejects(f.auth.signIn('valid123', 'fixture-password'), { message: LOGIN_ERROR });
    assert.equal(f.auth.isAuthenticated(), false);
  }
  const f = fixture([new Error('network details')]);
  await assert.rejects(f.auth.signIn('valid123', 'fixture-password'), { message: LOGIN_ERROR });
});

test('missing/cross-user profiles cannot enter the authenticated screen', async () => {
  for (const profiles of [[], [{ id: userId, auth_user_id: 'other' }], [...profileResponse, ...profileResponse]]) {
    const f = fixture([reply(tokenResponse), reply(profiles), reply(null, 204)]);
    await assert.rejects(f.auth.signIn('valid123', 'fixture-password'), { message: LOGIN_ERROR });
    assert.equal(f.auth.isAuthenticated(), false);
    assert.ok(f.calls.at(-1).url.includes('/logout'));
  }
});

test('expiry and failed remote logout clear local access', async () => {
  const f = fixture([reply(tokenResponse), reply(profileResponse), new Error('offline')]);
  await f.auth.signIn('valid123', 'fixture-password');
  assert.equal(await f.auth.signOut(), false);
  assert.equal(f.auth.isAuthenticated(), false);
  const expired = fixture([reply(tokenResponse), reply(profileResponse)]);
  await expired.auth.signIn('valid123', 'fixture-password');
  expired.advance(3600000);
  assert.equal(expired.auth.isAuthenticated(), false);
  const timer = fixture([reply(tokenResponse), reply(profileResponse)]);
  await timer.auth.signIn('valid123', 'fixture-password');
  timer.expire();
  assert.equal(timer.auth.isAuthenticated(), false);
});

test('logout during a pending login prevents late authenticated state', async () => {
  let resolve;
  const pending = new Promise((done) => { resolve = done; });
  const f = fixture([() => pending, reply(profileResponse), reply(null, 204)]);
  const login = f.auth.signIn('valid123', 'fixture-password');
  await f.auth.signOut();
  resolve(reply(tokenResponse));
  await assert.rejects(login, { message: LOGIN_ERROR });
  assert.equal(f.auth.isAuthenticated(), false);
});

test('UI exposes username/password/logout only; protected section starts hidden', async () => {
  const html = await readFile(new URL('../src/index.html', import.meta.url), 'utf8');
  assert.match(html, /id="home-screen"[^>]+hidden/);
  assert.match(html, /name="username"/);
  assert.match(html, /type="password"/);
  assert.match(html, /id="logout"/);
  assert.doesNotMatch(html, /mental-math\.invalid|type="email"|crear cuenta|forgot|recuperar contraseña/i);
});
