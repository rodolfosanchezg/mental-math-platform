import test from 'node:test';
import assert from 'node:assert/strict';
import { createBag, createGame, loadOperations } from '../src/js/game.js';

test('balanced bag consumes every distinct ID and remixes only after exhaustion', () => {
  const operations = Array.from({ length: 78 }, (_, id) => ({ id }));
  const next = createBag(operations, () => 0.25);
  for (let cycle = 0; cycle < 3; cycle++) {
    const seen = new Set(Array.from({ length: 78 }, () => next().id));
    assert.equal(seen.size, 78);
  }
  assert.throws(() => createBag([]));
});

test('operation loader reads every page beyond the Data API row limit', async () => {
  const calls = [];
  const all = await loadOperations(async (path) => {
    calls.push(path);
    const offset = Number(new URL(`https://fixture${path}`).searchParams.get('offset'));
    return Array.from({ length: offset < 2000 ? 1000 : 15 }, (_, i) => ({ id: offset + i }));
  }, 'addition', 'S4');
  assert.equal(all.length, 2015);
  assert.equal(new Set(all.map(row => row.id)).size, 2015);
  assert.equal(calls.length, 3);
});

test('countdown, keyboard, nonblocking feedback, expiry discard and retry UUIDs', async () => {
  let time = 0, tick, feedback, latest, completed, serial = 0, failOnce = true;
  const states = [], recorded = [], attempts = [];
  const operations = [1, 2].map(id => ({ id: String(id), type: 'addition', level: 'S1', operand_a: 7, operand_b: 8, result: 15 }));
  const game = createGame({
    now: () => time, delay: async ms => { time += ms; },
    interval: fn => { tick = fn; return 1; }, clearIntervalFn: () => {},
    timeout: (fn, ms) => { assert.equal(ms, 350); feedback = fn; return 1; }, clearTimeoutFn: () => {},
    uuid: () => `submission-${++serial}`,
    onState: state => { latest = state; states.push(state); }, onComplete: value => { completed = value; },
    api: async (path, body) => {
      if (path.includes('/operations?')) return operations;
      if (path.includes('/start_game_session')) return { id: 'game', type: 'addition', level: 'S1', duration_seconds: 1 };
      if (path.includes('/record_game_answer')) {
        attempts.push({ ...body });
        if (failOnce) { failOnce = false; throw new Error('simulated response lost'); }
        recorded.push(body);
        return { is_correct: body.p_answer_given === 15, answer_given: body.p_answer_given };
      }
      return { id: 'game', total_operations: recorded.length };
    },
  });
  const key = value => game.handleKey({ key: value, preventDefault() {} });
  await game.start('addition', 'S1');
  assert.deepEqual(states.filter(s => s.phase === 'countdown').map(s => s.countdown), [3, 2, 1]);
  assert.equal(time, 3000); assert.equal(latest.phase, 'running');
  time = 3100;
  key('a'); key(' '); key('-'); assert.equal(latest.answer, '');
  key('1'); key('9'); key('Backspace'); key('5'); key('Enter');
  assert.equal(latest.symbol, '✓'); assert.equal(latest.answer, '');
  time = 3200; key('Enter'); assert.equal(latest.symbol, '✗');
  key('8'); assert.equal(latest.answer, '8'); feedback(); assert.equal(latest.symbol, '');
  time = 4000; key('Enter'); // At expiry the unsent 8 must not become a submission.
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(latest.phase, 'save-error'); assert.equal(latest.answer, '');
  game.retry(); await new Promise(resolve => setImmediate(resolve));
  assert.equal(latest.phase, 'finished'); assert.equal(completed.session.total_operations, 2);
  assert.equal(recorded[0].p_answer_given, 15); assert.equal(recorded[1].p_answer_given, null);
  assert.equal(recorded[0].p_elapsed_ms, 100); assert.equal(recorded[1].p_response_time_ms, 100);
  assert.equal(attempts[0].p_submission_id, attempts[1].p_submission_id);
  assert.notEqual(recorded[0].p_operation_id, recorded[1].p_operation_id);
  key('Enter'); tick(); assert.equal(recorded.length, 2);
});

test('cancellation during countdown never starts or resurrects a session', async () => {
  let release, count = 0;
  const game = createGame({ api: async () => { count++; return [{ id: 1 }]; },
    onState() {}, onComplete() {}, delay: () => new Promise(resolve => { release = resolve; }) });
  const start = game.start('addition', 'S1');
  await new Promise(resolve => setImmediate(resolve));
  game.cancel(); release(); await start;
  assert.equal(count, 1);
});
