export function createResults(auth, navigation, root) {
  const select = id => root.querySelector(`#${id}`);
  let result = null, version = 0, recordsVersion = 0;
  const resultActions = ['play-again', 'switch-mode', 'results-home'];
  const percentage = value => `${Number(value).toFixed(1)}%`;
  const modeName = type => type === 'addition' ? 'Sumas' : 'Multiplicaciones';
  function enablePlay(enabled) { for (const id of resultActions) select(id).disabled = !enabled; }

  async function refreshProgress() {
    if (!result || !auth.isAuthenticated()) return;
    const active = ++version;
    enablePlay(false); select('result-refresh').hidden = true;
    select('level-message').textContent = 'Actualizando nivel…';
    try {
      const [, history] = await Promise.all([auth.refreshProfile(), auth.authenticatedRequest(
        `/rest/v1/level_history?select=reason,new_level&session_id=eq.${result.session.id}`)]);
      if (active !== version || !auth.isAuthenticated()) return;
      navigation.renderHome();
      const change = history[0];
      select('level-message').textContent = !change ? '' : change.reason === 'promotion'
        ? `Subiste a ${change.new_level}.` : change.reason === 'demotion'
          ? `Tu nivel ahora es ${change.new_level}.` : `Mantienes el nivel máximo ${change.new_level}.`;
      enablePlay(true);
    } catch {
      if (active !== version || !auth.isAuthenticated()) return;
      select('level-message').textContent = 'No se pudo actualizar el nivel. Reintenta.';
      select('result-refresh').hidden = false;
    }
  }

  async function showRecords() {
    if (!auth.isAuthenticated()) return;
    navigation.show('records');
    const active = ++recordsVersion;
    select('records-list').replaceChildren();
    select('records-status').textContent = 'Cargando records…';
    select('records-retry').hidden = true;
    try {
      const records = await auth.authenticatedRequest('/rest/v1/rpc/get_personal_records', {});
      if (active !== recordsVersion || !auth.isAuthenticated()) return;
      for (const type of ['addition', 'multiplication']) {
        const section = document.createElement('section');
        const title = document.createElement('h3'); title.textContent = modeName(type); section.append(title);
        const record = records.find(row => row.type === type);
        const description = document.createElement('p');
        description.textContent = record
          ? `Precisión ${percentage(record.accuracy)} · Correctas ${record.correct_answers} · Total ${record.total_operations} · Nivel ${record.level} · ${new Date(record.started_at).toLocaleString('es-CO')}`
          : 'Todavía no tienes un record en este modo.';
        section.append(description); select('records-list').append(section);
      }
      select('records-status').textContent = '';
    } catch {
      if (active !== recordsVersion || !auth.isAuthenticated()) return;
      select('records-status').textContent = 'No se pudieron cargar los records.';
      select('records-retry').hidden = false;
    }
  }

  select('play-again').addEventListener('click', () => { if (result) navigation.selectMode(result.session.type); });
  select('switch-mode').addEventListener('click', () => {
    if (result) navigation.selectMode(result.session.type === 'addition' ? 'multiplication' : 'addition');
  });
  for (const id of ['view-records', 'results-records', 'records-retry']) select(id).addEventListener('click', showRecords);
  select('result-refresh').addEventListener('click', refreshProgress);
  select('review-errors').addEventListener('click', () => {
    if (!result || !auth.isAuthenticated()) return;
    const list = select('error-list'); list.replaceChildren();
    for (const answer of result.answers.filter(row => !row.is_correct)) {
      const item = document.createElement('li'); const op = answer.operation;
      for (const text of [`${op.operand_a} ${op.type === 'addition' ? '+' : '×'} ${op.operand_b}`,
        `Tu respuesta: ${answer.answer_given === null ? '—' : answer.answer_given}`, `Correcta: ${op.result}`]) {
        const line = document.createElement('p'); line.textContent = text; item.append(line);
      }
      list.append(item);
    }
    select('errors-status').textContent = list.children.length ? '' : 'No hubo respuestas incorrectas.';
    navigation.show('errors');
  });
  select('back-results').addEventListener('click', () => { if (result) navigation.show('results'); });
  auth.subscribe(authenticated => {
    if (authenticated) return;
    version += 1; recordsVersion += 1; result = null;
    for (const id of ['error-list', 'records-list']) select(id).replaceChildren();
    for (const id of ['result-total', 'result-correct', 'result-incorrect', 'result-accuracy', 'level-message']) select(id).textContent = '';
  });
  return {
    complete(data) {
      result = data;
      select('result-total').textContent = data.session.total_operations;
      select('result-correct').textContent = data.session.correct_answers;
      select('result-incorrect').textContent = data.session.incorrect_answers;
      select('result-accuracy').textContent = percentage(data.session.accuracy);
      select('switch-mode').textContent = `CAMBIAR A ${data.session.type === 'addition' ? 'MULTIPLICACIONES' : 'SUMAS'}`;
      navigation.show('results'); void refreshProgress();
    },
  };
}
