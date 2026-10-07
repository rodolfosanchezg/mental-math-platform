export function createNavigation(auth, root) {
  let mode = 'addition';
  let currentScreen = null;
  const screens = [...root.querySelectorAll('[data-screen]')];
  const select = (id) => root.querySelector(`#${id}`);
  function show(name) {
    if (!auth.isAuthenticated()) return;
    if (currentScreen === name) return;
    currentScreen = name;
    for (const screen of screens) screen.hidden = screen.dataset.screen !== name;
    const heading = root.querySelector(`[data-screen="${name}"] h2`);
    heading?.focus();
  }
  function renderHome() {
    const profile = auth.getProfile();
    if (!profile) return;
    // Display name is plain text; never render a technical email as a name.
    const name = String(profile.display_name ?? profile.username ?? '').replace(/[a-z0-9]+@mental-math\.invalid/gi, '').trim();
    select('greeting').textContent = `Hola, ${name || profile.username || ''}`;
    select('addition-level').textContent = profile.current_addition_level;
    select('multiplication-level').textContent = profile.current_multiplication_level;
  }
  function selectMode(nextMode) {
    if (!auth.isAuthenticated()) return;
    mode = nextMode;
    const profile = auth.getProfile();
    select('mode-title').textContent = mode === 'addition' ? 'SUMAS' : 'MULTIPLICACIONES';
    select('mode-level').textContent = mode === 'addition' ? profile.current_addition_level : profile.current_multiplication_level;
    show('pre-game');
  }
  select('addition').addEventListener('click', () => selectMode('addition'));
  select('multiplication').addEventListener('click', () => selectMode('multiplication'));
  select('view-records').addEventListener('click', () => show('records'));
  for (const button of root.querySelectorAll('[data-home]')) button.addEventListener('click', () => { renderHome(); show('home'); });
  auth.subscribe((authenticated) => {
    if (authenticated) { renderHome(); show('home'); }
    else {
      currentScreen = null;
      for (const screen of screens) screen.hidden = true;
      select('greeting').textContent = '';
      select('addition-level').textContent = '';
      select('multiplication-level').textContent = '';
      select('mode-level').textContent = '';
    }
  });
  return { show, renderHome, selectMode, getMode: () => mode };
}
