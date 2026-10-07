import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { supabaseConfig as config } from '../src/js/config.js';

class ValidationError extends Error {}
function check(value, message) { if (!value) throw new ValidationError(message); }
async function credentials(filename) {
  const text = await readFile(filename, 'utf8');
  const values = {};
  for (const line of text.split(/\r?\n/)) {
    const match = line.match(/^\s*(?:export\s+)?(AUTH_TEST_USERNAME|AUTH_TEST_PASSWORD)\s*=\s*(.*?)\s*$/);
    if (match) values[match[1]] = match[2].replace(/^(['"])(.*)\1$/, '$2');
  }
  check(/^[a-z0-9]{3,24}$/.test(values.AUTH_TEST_USERNAME ?? '') && values.AUTH_TEST_PASSWORD, 'Missing protected test credentials');
  return values;
}
async function request(user, path, method = 'GET', body) {
  const headers = { apikey: config.publishableKey };
  if (user) headers.Authorization = `Bearer ${user.token}`;
  if (body) headers['Content-Type'] = 'application/json';
  const response = await fetch(config.url + path, { method, headers, body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(15000) });
  return { status: response.status, data: response.status === 204 ? null : await response.json() };
}
function single(data) { return Array.isArray(data) ? data[0] : data; }
const users = [];
try {
  for (const path of ['.env.auth-test.local', '.env.auth-test-user2.local']) {
    const c = await credentials(path);
    const response = await request(null, '/auth/v1/token?grant_type=password', 'POST', {
      email: `${c.AUTH_TEST_USERNAME}@mental-math.invalid`, password: c.AUTH_TEST_PASSWORD,
    });
    check(response.status === 200 && response.data.access_token, 'Test account login failed');
    users.push({ token: response.data.access_token, id: response.data.user.id });
  }
  check(users[0].id !== users[1].id, 'Two independent accounts required');

  // Ordinary gameplay fixture only when B has none; no admin writes or cleanup.
  let bSessions = await request(users[1], '/rest/v1/sessions?select=id,player_id&limit=1');
  check(bSessions.status === 200, 'B session read failed');
  if (!bSessions.data.length) {
    const started = await request(users[1], '/rest/v1/rpc/start_game_session', 'POST', { p_type: 'multiplication' });
    check(started.status === 200, 'B fixture start failed');
    const session = single(started.data);
    const bank = await request(users[1], `/rest/v1/operations?select=id&type=eq.multiplication&level=eq.${session.level}&active=eq.true&limit=1`);
    check(bank.status === 200 && bank.data.length, 'B fixture bank unavailable');
    const submitted = await request(users[1], '/rest/v1/rpc/record_game_answer', 'POST', {
      p_session_id: session.id, p_operation_id: bank.data[0].id, p_answer_given: null,
      p_response_time_ms: 0, p_elapsed_ms: 0, p_submission_id: randomUUID(),
    });
    check(submitted.status === 200, 'B fixture submission failed');
    console.log('B had no sessions; one ordinary QA session/NULL answer created. Waiting for 45s expiry.');
    await new Promise(resolve => setTimeout(resolve, Math.max(0,
      Date.parse(session.started_at) + session.duration_seconds * 1000 - Date.now()) + 300));
    const closed = await request(users[1], '/rest/v1/rpc/close_game_session', 'POST', { p_session_id: session.id });
    check(closed.status === 200, 'B fixture close failed');
  }

  for (let index = 0; index < 2; index++) {
    const own = users[index], other = users[1 - index];
    const profile = await request(own, '/rest/v1/players?select=id,auth_user_id');
    check(profile.status === 200 && profile.data.length === 1 && profile.data[0].auth_user_id === own.id, 'Own profile isolation failed');
    for (const [table, filter] of [['players', `id=eq.${other.id}`], ['sessions', `player_id=eq.${other.id}`],
      ['level_history', `player_id=eq.${other.id}`]]) {
      const response = await request(own, `/rest/v1/${table}?select=id&${filter}`);
      check(response.status === 200 && response.data.length === 0, 'Cross-user read isolation failed');
    }
    const otherSessions = await request(other, '/rest/v1/sessions?select=id,player_id&limit=1');
    check(otherSessions.status === 200 && otherSessions.data.length, 'Real sessions required for both users');
    const sessionId = otherSessions.data[0].id;
    const answers = await request(own, `/rest/v1/session_answers?select=id&session_id=eq.${sessionId}`);
    check(answers.status === 200 && answers.data.length === 0, 'Cross-user answer isolation failed');
    const close = await request(own, '/rest/v1/rpc/close_game_session', 'POST', { p_session_id: sessionId });
    check(close.status === 403, 'Cross-user session close permitted');
    for (const table of ['players', 'sessions', 'session_answers', 'level_history', 'operations']) {
      for (const method of ['POST', 'PATCH', 'DELETE']) {
        const denied = await request(own, `/rest/v1/${table}?id=eq.${other.id}`, method,
          method === 'DELETE' ? undefined : { id: other.id });
        check(denied.status === 403, 'Direct client mutation permitted');
      }
    }
    const records = await request(own, '/rest/v1/rpc/get_personal_records', 'POST', {});
    check(records.status === 200 && records.data.every(row => row.player_id === own.id && row.total_operations >= 10
      && row.completed_at), 'Record ownership/eligibility failed');
    const bank = await request(own, '/rest/v1/operations?select=id&limit=1');
    check(bank.status === 200 && bank.data.length, 'Authenticated bank access failed');
  }
  for (const table of ['players', 'sessions', 'session_answers', 'level_history', 'operations']) {
    const denied = await request(null, `/rest/v1/${table}?select=id&limit=1`);
    check([401, 403].includes(denied.status), 'Anonymous data access permitted');
  }
  console.log('PASS: two real accounts, own/cross reads, cross RPC denial, all DML denied, records and anonymous isolation');
} catch (error) {
  process.exitCode = 1;
  console.error('T12 validation failed; sensitive request/response values suppressed:',
    error instanceof ValidationError ? error.message : 'Network or local configuration error');
} finally {
  for (const user of users) {
    try { check((await request(user, '/auth/v1/logout?scope=local', 'POST')).status === 204, 'QA logout failed'); }
    catch { console.error('Remote QA logout unavailable; values suppressed'); process.exitCode = 1; }
  }
}
