import { supabaseConfig } from './config.js';
import { createAuth, LOGIN_ERROR, USERNAME_PATTERN } from './auth.js';
import { createNavigation } from './navigation.js';
import { createGame } from './game.js';

const auth = createAuth(supabaseConfig);
const form = document.querySelector('#login-form');
const username = document.querySelector('#username');
const password = document.querySelector('#password');
const submit = document.querySelector('#login-submit');
const loginScreen = document.querySelector('#login-screen');
const homeScreen = document.querySelector('#home-screen');
const status = document.querySelector('#status');
const logout = document.querySelector('#logout');
const navigation = createNavigation(auth, homeScreen);
const gameStatus = document.querySelector('#game-status');
const game = createGame({
  api: (path, body) => auth.authenticatedRequest(path, body),
  onState(state) {
    if (!auth.isAuthenticated()) return;
    navigation.show('game');
    document.querySelector('#timer').textContent = state.seconds;
    document.querySelector('#operation').textContent = state.phase === 'countdown' ? state.countdown
      : state.operation ? `${state.operation.operand_a} ${state.operation.type === 'addition' ? '+' : '×'} ${state.operation.operand_b}` : '';
    document.querySelector('#answer').textContent = state.answer;
    document.querySelector('#feedback').textContent = state.symbol;
    document.querySelector('#save-retry').hidden = state.phase !== 'save-error';
    document.querySelector('#game-home').hidden = !['finished', 'start-error'].includes(state.phase);
    gameStatus.textContent = ({ loading: 'Preparando partida…', starting: 'Preparando partida…',
      saving: 'Guardando partida…', 'save-error': 'No se pudo guardar la partida. Reintenta.',
      'start-error': 'No se pudo iniciar la partida.', finished: 'Partida finalizada.' })[state.phase] ?? '';
  },
  async onComplete() {
    try { await auth.refreshProfile(); navigation.renderHome(); } catch { /* Auth handles lost access. */ }
  },
});
document.querySelector('#start').disabled = false;
document.querySelector('#start').addEventListener('click', () => {
  const profile = auth.getProfile();
  if (!profile) return;
  const mode = navigation.getMode();
  void game.start(mode, mode === 'addition' ? profile.current_addition_level : profile.current_multiplication_level);
});
document.querySelector('#save-retry').addEventListener('click', () => game.retry());
window.addEventListener('keydown', (event) => game.handleKey(event));

auth.subscribe((authenticated) => {
  homeScreen.hidden = !authenticated;
  loginScreen.hidden = authenticated;
  password.value = '';
  if (!authenticated) game.cancel();
  if (authenticated) logout.focus();
});

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  if (submit.disabled) return;
  status.textContent = '';
  if (!USERNAME_PATTERN.test(username.value)) {
    status.textContent = 'Usa de 3 a 24 letras minúsculas o números para el usuario.';
    username.focus();
    return;
  }
  submit.disabled = true;
  submit.textContent = 'INICIANDO SESIÓN…';
  const enteredPassword = password.value;
  password.value = '';
  try {
    await auth.signIn(username.value, enteredPassword);
  } catch {
    status.textContent = LOGIN_ERROR;
    password.focus();
  } finally {
    submit.disabled = false;
    submit.textContent = 'INICIAR SESIÓN';
  }
});

logout.addEventListener('click', async () => {
  logout.disabled = true;
  status.textContent = '';
  const revoked = await auth.signOut();
  if (!revoked) status.textContent = 'Sesión cerrada en este dispositivo. No se pudo confirmar el cierre remoto.';
  logout.disabled = false;
  username.focus();
});

// Expired or lost sessions cannot re-enter protected content through history.
window.addEventListener('pageshow', () => { homeScreen.hidden = !auth.isAuthenticated(); });
document.addEventListener('visibilitychange', () => { auth.isAuthenticated(); });
