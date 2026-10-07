export const USERNAME_PATTERN = /^[a-z0-9]{3,24}$/;
export const LOGIN_ERROR = 'No se pudo iniciar sesión. Revisa tus credenciales e inténtalo de nuevo.';

export function createAuth(config, {
  fetchImpl = globalThis.fetch.bind(globalThis), now = Date.now,
  setTimer = setTimeout, clearTimer = clearTimeout,
} = {}) {
  let session = null;
  let expiryTimer = null;
  let generation = 0;
  const listeners = new Set();

  function clearSession() {
    clearTimer(expiryTimer);
    expiryTimer = null;
    session = null;
    for (const listener of listeners) listener(false);
  }

  async function request(path, { token, body } = {}) {
    const headers = { apikey: config.publishableKey };
    if (token) headers.Authorization = `Bearer ${token}`;
    if (body) headers['Content-Type'] = 'application/json';
    const response = await fetchImpl(`${config.url}${path}`, {
      method: body || path.includes('/logout') ? 'POST' : 'GET',
      headers, body: body ? JSON.stringify(body) : undefined,
      cache: 'no-store', signal: AbortSignal.timeout(15000),
    });
    if (!response.ok) throw new Error(LOGIN_ERROR);
    return response.status === 204 ? null : response.json();
  }

  async function revoke(token) {
    if (token) await request('/auth/v1/logout?scope=local', { token });
  }

  const api = {
    subscribe(listener) {
      listeners.add(listener);
      listener(api.isAuthenticated());
      return () => listeners.delete(listener);
    },
    isAuthenticated() {
      if (session && session.expiresAt <= now()) {
        generation += 1;
        clearSession();
      }
      return session !== null;
    },
    async signIn(username, password) {
      if (!USERNAME_PATTERN.test(username) || typeof password !== 'string' || password.length === 0) {
        throw new Error(LOGIN_ERROR);
      }
      const attempt = ++generation;
      clearSession();
      let token;
      try {
        const result = await request('/auth/v1/token?grant_type=password', {
          body: { email: `${username}@mental-math.invalid`, password },
        });
        token = result.access_token;
        if (typeof token !== 'string' || !token || !result.user?.id || !Number.isFinite(result.expires_in)) {
          throw new Error(LOGIN_ERROR);
        }
        const expiresAt = now() + result.expires_in * 1000;
        // Server RLS determines which profile can be returned; username never authorizes.
        const profiles = await request('/rest/v1/players?select=id,auth_user_id&limit=2', { token });
        if (attempt !== generation || expiresAt <= now() || !Array.isArray(profiles) || profiles.length !== 1
            || profiles[0].auth_user_id !== result.user.id || profiles[0].id !== result.user.id) {
          throw new Error(LOGIN_ERROR);
        }
        session = { token, expiresAt };
        expiryTimer = setTimer(() => { generation += 1; clearSession(); }, expiresAt - now());
        for (const listener of listeners) listener(true);
      } catch {
        if (attempt === generation) clearSession();
        await revoke(token).catch(() => {});
        throw new Error(LOGIN_ERROR);
      }
    },
    async signOut() {
      const token = session?.token;
      generation += 1;
      // Hide protected content immediately, including when the network is unavailable.
      clearSession();
      try { await revoke(token); return true; } catch { return false; }
    },
  };
  return api;
}
