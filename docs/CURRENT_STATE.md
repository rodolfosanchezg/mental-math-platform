# CURRENT_STATE.md

## Estado

**Architecture / Requirements: CLOSED**  
**Implementation: T01–T04 CLOSED; CHECKPOINT_WAIT**

## Seguimiento operativo

- TASK: T04 — RLS y seguridad multiusuario.
- OWNER: AURELIO.
- STATUS: CLOSED.
- Última tarea cerrada: T04 (cierre operativo efectivo tras push verificado).
- CHECKPOINT: 1 — CHECKPOINT_WAIT; requiere CONTINUE / FIX / REPLAN de Rodolfo.
- Commit de cierre T03: `7b02dc4`, push verificado.
- Commit de cierre T02: `c3d314e`, push verificado.
- Commit de cierre de T01: `402af04` (`T01: close repository initialization`).
- Push: exitoso a `origin/main` (GitHub).
- QA T01: Valerio PASS — READY TO CLOSE; sin hallazgos.
- QA T02: Valerio PASS, sin hallazgos; correcciones utilizadas: 0.
- Actualización documental de cierre T01: `f25a071`, pusheada.
- Sincronización T01: HEAD local y `refs/heads/main` remoto coinciden en `f25a071`.
- Correcciones automáticas utilizadas: 0.
- T05–T12: NOT_STARTED.

## Aprobado

- Stack HTML/CSS/JS Vanilla + Supabase.
- Supabase limpio creado.
- Auth inicial configurado.
- Login username/password con email técnico interno.
- Signup público OFF.
- Anonymous Auth OFF.
- Confirm Email OFF.
- Username `^[a-z0-9]{3,24}$`.
- RLS obligatorio.
- Sumas S1–S5 definidas.
- Multiplicaciones M1–M6 definidas.
- Progresión y records definidos.
- Acceptance Criteria y Test Plan alineados.

## No existe todavía

- banco de operaciones cargado;
- usuarios reales de la aplicación;
- frontend funcional (`src/index.html` es solo un placeholder);
- pruebas de frontend y end-to-end ejecutadas.

## Preparación de T01

- Estructura base presente conforme a `PROJECT_STRUCTURE.md`.
- Carpetas reservadas con `.gitkeep`, sin migraciones ni lógica funcional.
- `.gitignore` protege configuración local, credenciales y claves privadas.
- Validación independiente de Valerio: PASS, sin hallazgos.
- Estructura, reglas de ignore, placeholders y revisión por firmas de secretos: PASS.
- `git diff --check`: PASS.
- Supabase inicial verificado documentalmente, sin conexión remota en T01.
- Cierre operativo completado: QA PASS, commit `402af04` y push exitoso.
- Incidente resuelto: el primer push falló por falta de autenticación HTTPS;
  GitHub CLI quedó autenticado y el push pendiente se completó sin repetir QA.

## T02 — CLOSED

- Bloqueo de conexión resuelto mediante variables PG locales protegidas.
- Conectividad administrativa verificada sin mostrar credenciales.
- Migración aplicada: `supabase/migrations/202610070001_base_schema.sql`.
- Cinco tablas del modelo aprobado con PK, FK, defaults, checks e índices.
- RLS habilitado sin políticas y grants de cliente revocados para proteger
  el esquema intermedio; las políticas de propiedad pertenecen a T04.
- Pruebas `supabase/tests/t02_schema.sql`: PASS, fixtures con rollback.
- Sin datos persistentes añadidos por las pruebas; sin banco ni usuarios reales.
- `.env.supabase.local` ignorado por Git y no versionado.
- Sin dependencias nuevas ni cambios a requisitos o arquitectura.
- Commit y push T02 verificados; T03 iniciada.

## T03 — CLOSED

- Migración `202610070002_auth_players.sql` aplicada.
- Trigger seguro para creación administrativa Auth/perfil, UUID compartido.
- Email técnico validado; username derivado y sincronizado ante cambio de email.
- Display name desde metadata opcional, con fallback al username.
- Niveles/rachas iniciales definidos por la base de datos, nunca por metadata.
- Función del trigger con search_path vacío y EXECUTE revocado al cliente.
- Pruebas T03 y regresión T02: PASS con rollback; sin usuarios persistentes.
- Fixtures T02 adaptados al aprovisionamiento automático sin reducir checks.
- QA T03: Valerio PASS sin hallazgos; correcciones utilizadas: 0.
- Commit y push de T03 verificados; T04 iniciada.

## T04 — CLOSED

- Migración `202610070003_rls_security.sql` aplicada.
- Cinco políticas SELECT para authenticated; propiedad derivada de auth.uid().
- Cada usuario lee solo sus players/sessions/answers/history; banco compartido.
- anon sin permisos; INSERT/UPDATE/DELETE directos denegados a ambos roles API.
- Escrituras transaccionales mediante RPC verificadas se implementarán en T06.
- Pruebas A/B/anónimo: PASS con rol real y claims simulados dentro de PostgreSQL.
- Regresión T02/T03: PASS; fixtures revertidos, sin datos persistentes.
- Test T02 actualizado para conservar checks tras habilitar lecturas en T04.
- QA T04: Valerio PASS sin hallazgos; correcciones utilizadas: 0.
- Cierre con commit orientado a T04 y push verificado antes de finalizar.
- T05 no iniciada; resumen combinado en `docs/CHECKPOINT_1.md`.

## Próximo responsable

Rodolfo — decisión del Checkpoint 1.

## Próximo objetivo

Esperar CONTINUE / FIX / REPLAN de Rodolfo. No iniciar T05 antes de la
aprobación explícita del Checkpoint 1.

## Regla operativa

Cada cierre de tarea debe actualizar `README.md` y `CURRENT_STATE.md` para reflejar el estado real del repositorio.
