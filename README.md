# Mental Math Platform — v0.1

Plataforma web educativa para desarrollar fluidez en cálculo mental mediante sesiones cronometradas de sumas y multiplicaciones.

## Estado

**Requisitos y arquitectura: cerrados.**  
**Implementación: T01–T08 CLOSED; T09 CLOSED.**

**Supabase: esquema base, aprovisionamiento Auth/perfil y RLS aplicados.**

T01 deja preparada la estructura del repositorio y cuenta con QA PASS. El commit
`402af04` y la actualización documental `f25a071` están publicados en GitHub.
T02 — esquema base de Supabase está aplicado: `players`, `operations`,
`sessions`, `session_answers` y `level_history`, con constraints e índices.
Las pruebas SQL transaccionales pasaron y sus fixtures se revirtieron.
Valerio verificó independientemente el esquema y emitió PASS sin hallazgos.

T03 está aplicada y validada por Valerio sin hallazgos: crear un Auth User
administrativo con email técnico válido
crea su perfil automáticamente con el mismo UUID, S1/M1 y rachas cero. El
frontend implementa login/logout; no hay lógica de juego implementada.
Las tablas tienen RLS
y políticas de lectura de datos propios basadas en `auth.uid()`. El banco admite
lectura autenticada; el rol anónimo carece de acceso. Las escrituras directas de
cliente permanecen revocadas; T06 añade RPC autenticados para iniciar sesiones,
registrar respuestas y cerrar con totales calculados en PostgreSQL.

T04 obtuvo QA PASS sin hallazgos. Rodolfo aprobó CONTINUE en el Checkpoint 1;
El banco T05 está cargado y QA PASS. T06 tiene QA PASS sin hallazgos funcionales o de seguridad. T07 está aplicada
y tiene QA PASS: el cierre actualiza progreso/historial transaccionalmente
y get_personal_records devuelve los mejores resultados propios por modo. Resumen de ese checkpoint: `docs/CHECKPOINT_1.md`.

El banco contiene 10.412 operaciones activas (S1–S5 / M1–M6), verificadas
exhaustivamente por el desarrollador. La bolsa equilibrada pertenece a T10.

T08 implementa username/password con Supabase Auth, errores genéricos y logout.
La pantalla autenticada mínima valida la frontera de acceso; el Home y sus botones
corresponden a T09. Solo URL y publishable key forman parte de `src/js/config.js`,
según D-020; ninguna credencial administrativa se carga en el navegador.

## Ejecutar frontend T08

```sh
node tools/configure-public.mjs
python3 -m http.server 8000 --bind 127.0.0.1 --directory src
```

El primer comando lee únicamente `.env.supabase.public.local` (ignorado), genera
la configuración pública y no imprime valores. Abrir http://127.0.0.1:8000.
No servir la raíz del repositorio, donde se encuentran los archivos locales.
El producto sigue siendo estático y no requiere Node/Python en producción.

La sesión se conserva solo en memoria hasta su expiración; recargar requiere
login. Logout elimina acceso local inmediatamente y solicita cierre remoto del
usuario. No hay signup ni recuperación; las cuentas se crean administrativamente.
Valerio validó login, sesión, perfil propio, contraseña incorrecta y logout contra
Supabase real y en Chrome: QA PASS, sin hallazgos. Las credenciales de la cuenta
administrativa de prueba permanecen en `.env.auth-test.local`, ignorado por Git.

## Validar T08

```sh
node --experimental-default-type=module --test tests/t08_auth.test.mjs
node --experimental-default-type=module tests/t08_live_public.mjs
```

`tests/t08_browser.html` valida la interfaz en Chrome con respuestas controladas;
servir solo copias de src y ese fixture en un directorio temporal, sin .env.
T08 cerrado con `db5f020`. Rodolfo aprobó CONTINUE en Checkpoint 2.
T09 muestra perfil, niveles y navegación Home/modos/records; START y contenido
de records se completarán en T10/T11. QA T09 PASS sin hallazgos.

Las instrucciones de aplicación y validación están en `supabase/README.md`.

## Estructura inicial

La distribución de carpetas sigue `docs/PROJECT_STRUCTURE.md`: `src/` para el
frontend estático, `assets/` para recursos, `supabase/migrations/` para futuras
migraciones, `supabase/tests/` para pruebas del backend y `tests/` para pruebas
generales. No se requiere instalar dependencias ni herramientas adicionales en T01.

Los archivos `.env` locales, credenciales administrativas y claves privadas no se
versionan. Si se crea `.env.example`, debe contener únicamente valores de ejemplo
sin secretos. Solo Project URL y publishable key pueden utilizarse en el futuro
cliente según `docs/DECISIONS.md`.

## Stack aprobado

- HTML5
- CSS3
- JavaScript Vanilla
- Supabase Auth
- Supabase PostgreSQL
- Row Level Security (RLS)
- Git / GitHub

## Documentación fuente de verdad

- `docs/REQUIREMENTS.md`
- `docs/DECISIONS.md`
- `docs/ARCHITECTURE.md`
- `docs/DATA_MODEL.md`
- `docs/GAME_RULES.md`
- `docs/UI_FLOW.md`
- `docs/ACCEPTANCE_CRITERIA.md`
- `docs/TEST_PLAN.md`
- `docs/SUPABASE_SETUP.md`
- `docs/ROADMAP.md`
- `docs/CURRENT_STATE.md`
- `docs/PROJECT_STRUCTURE.md`

## Regla de gobierno

La documentación aprobada es la fuente de verdad. Ninguna tarea de implementación puede modificar silenciosamente requisitos, reglas de juego, seguridad o arquitectura.
