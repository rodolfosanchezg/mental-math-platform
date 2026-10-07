export function createBag(operations, random = Math.random) {
  if (!operations.length) throw new Error('No hay operaciones disponibles.');
  let remaining = [];
  return () => {
    if (!remaining.length) {
      remaining = [...operations];
      for (let i = remaining.length - 1; i > 0; i--) {
        const j = Math.floor(random() * (i + 1));
        [remaining[i], remaining[j]] = [remaining[j], remaining[i]];
      }
    }
    return remaining.pop();
  };
}

export async function loadOperations(api, type, level) {
  const all = [];
  for (let offset = 0; ; offset += 1000) {
    const page = await api(`/rest/v1/operations?select=id,type,level,operand_a,operand_b,result&active=eq.true&type=eq.${type}&level=eq.${level}&order=id&limit=1000&offset=${offset}`);
    if (!Array.isArray(page)) throw new Error('No se pudo cargar el banco.');
    all.push(...page);
    if (page.length < 1000) return all;
  }
}

export function createGame({ api, onState, onComplete, now = () => performance.now(),
  delay = (ms) => new Promise(resolve => setTimeout(resolve, ms)),
  interval = setInterval, clearIntervalFn = clearInterval,
  timeout = setTimeout, clearTimeoutFn = clearTimeout, uuid = () => crypto.randomUUID() }) {
  let phase = 'idle', version = 0, tickTimer, feedbackTimer;
  let session, bag, operation, answer = '', symbol = '', startTime = 0, previousElapsed = 0;
  let submissions = [], saved = [], savedIndex = 0;
  const emit = (extra = {}) => onState({ phase, operation, answer, symbol,
    seconds: session ? Math.max(0, Math.ceil((session.duration_seconds * 1000 - (now() - startTime)) / 1000)) : 45, ...extra });
  const rpc = async (name, body) => {
    const result = await api(`/rest/v1/rpc/${name}`, body);
    if (Array.isArray(result)) {
      if (result.length !== 1) throw new Error('Resultado de partida no disponible.');
      return result[0];
    }
    if (!result || typeof result !== 'object') throw new Error('Resultado de partida no disponible.');
    return result;
  };

  async function persist() {
    if (phase !== 'saving' && phase !== 'save-error') return;
    const active = version;
    phase = 'saving'; emit({ seconds: 0 });
    try {
      while (savedIndex < submissions.length) {
        const item = submissions[savedIndex];
        const response = await rpc('record_game_answer', item.payload);
        if (active !== version) return;
        saved.push({ ...response, operation: item.operation });
        savedIndex += 1;
      }
      const result = await rpc('close_game_session', { p_session_id: session.id });
      if (active !== version) return;
      phase = 'finished'; emit({ seconds: 0 });
      onComplete({ session: result, answers: saved });
    } catch {
      if (active !== version) return;
      phase = 'save-error'; emit({ seconds: 0 });
    }
  }

  function finish() {
    if (phase !== 'running') return;
    clearIntervalFn(tickTimer); clearTimeoutFn(feedbackTimer);
    answer = ''; symbol = ''; operation = null;
    phase = 'saving'; void persist();
  }

  const game = {
    async start(type, level) {
      if (!['idle', 'finished', 'start-error'].includes(phase)) return;
      const active = ++version;
      phase = 'loading'; session = null; operation = null; answer = ''; symbol = '';
      submissions = []; saved = []; savedIndex = 0; previousElapsed = 0; emit();
      try {
        let operations = await loadOperations(api, type, level);
        if (active !== version) return;
        bag = createBag(operations);
        for (let count = 3; count > 0; count--) {
          phase = 'countdown'; emit({ countdown: count }); await delay(1000);
          if (active !== version) return;
        }
        phase = 'starting'; emit();
        session = await rpc('start_game_session', { p_type: type });
        if (active !== version) return;
        // The server owns the frozen level, including changes on another device.
        if (session.level !== level) {
          operations = await loadOperations(api, type, session.level);
          if (active !== version) return;
          bag = createBag(operations);
        }
        startTime = now(); phase = 'running'; operation = bag(); emit();
        tickTimer = interval(() => {
          if (now() - startTime >= session.duration_seconds * 1000) finish(); else emit();
        }, 30);
      } catch {
        if (active === version) { phase = 'start-error'; operation = null; emit(); }
      }
    },
    handleKey(event) {
      if (phase !== 'running') return;
      event.preventDefault();
      if (now() - startTime >= session.duration_seconds * 1000) { finish(); return; }
      if (event.ctrlKey || event.metaKey || event.altKey) return;
      if (/^[0-9]$/.test(event.key)) {
        // Match PostgreSQL integer storage; every valid exercise result fits.
        if (answer.length < 10 && Number(answer + event.key) <= 2147483647) answer += event.key;
      } else if (event.key === 'Backspace') answer = answer.slice(0, -1);
      else if (event.key === 'Enter') {
        const elapsed = Math.floor(now() - startTime);
        const given = answer === '' ? null : Number(answer);
        submissions.push({ operation, payload: { p_session_id: session.id, p_operation_id: operation.id,
          p_answer_given: given, p_response_time_ms: elapsed - previousElapsed,
          p_elapsed_ms: elapsed, p_submission_id: uuid() } });
        previousElapsed = elapsed;
        symbol = given === operation.result ? '✓' : '✗';
        clearTimeoutFn(feedbackTimer);
        feedbackTimer = timeout(() => { symbol = ''; if (phase === 'running') emit(); }, 350);
        answer = ''; operation = bag();
      } else return;
      emit();
    },
    retry: () => { if (phase === 'save-error') void persist(); },
    cancel() {
      version += 1; clearIntervalFn(tickTimer); clearTimeoutFn(feedbackTimer);
      phase = 'idle'; session = null; operation = null; submissions = []; saved = []; answer = ''; symbol = '';
    },
  };
  return game;
}
