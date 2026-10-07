import { supabaseConfig } from './config.js';
import { createAuth, LOGIN_ERROR, USERNAME_PATTERN } from './auth.js';
import { createNavigation } from './navigation.js';

const auth = createAuth(supabaseConfig);
const form = document.querySelector('#login-form');
const username = document.querySelector('#username');
const password = document.querySelector('#password');
const submit = document.querySelector('#login-submit');
const loginScreen = document.querySelector('#login-screen');
const homeScreen = document.querySelector('#home-screen');
const status = document.querySelector('#status');
const logout = document.querySelector('#logout');
createNavigation(auth, homeScreen);

auth.subscribe((authenticated) => {
  homeScreen.hidden = !authenticated;
  loginScreen.hidden = authenticated;
  password.value = '';
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
