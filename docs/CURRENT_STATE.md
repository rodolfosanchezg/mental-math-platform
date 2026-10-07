# CURRENT_STATE.md

## Estado

**Architecture / Requirements: CLOSED**  
**Implementation: T01–T02 CLOSED**

## Seguimiento operativo

- TASK: T02 — Esquema base de Supabase.
- OWNER: AURELIO.
- STATUS: CLOSED.
- Última tarea cerrada: T02 (cierre operativo efectivo tras push verificado).
- Commit de cierre de T01: `402af04` (`T01: close repository initialization`).
- Push: exitoso a `origin/main` (GitHub).
- QA T01: Valerio PASS — READY TO CLOSE; sin hallazgos.
- QA T02: Valerio PASS, sin hallazgos; correcciones utilizadas: 0.
- Actualización documental de cierre T01: `f25a071`, pusheada.
- Sincronización T01: HEAD local y `refs/heads/main` remoto coinciden en `f25a071`.
- Correcciones automáticas utilizadas: 0.
- T03–T12: NOT_STARTED.

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

- políticas RLS de acceso multiusuario;
- banco de operaciones cargado;
- usuarios reales de la aplicación;
- frontend funcional (`src/index.html` es solo un placeholder);
- pruebas funcionales ejecutadas.

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
- Documentación de cierre preparada; commit y push se verifican antes de T03.

## Próximo responsable

Senior Developer (Aurelio).

## Próximo objetivo

Verificar commit/push de cierre T02 e iniciar T03 — relación Auth/perfil.

## Regla operativa

Cada cierre de tarea debe actualizar `README.md` y `CURRENT_STATE.md` para reflejar el estado real del repositorio.
