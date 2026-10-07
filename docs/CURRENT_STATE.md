# CURRENT_STATE.md

## Estado

**Architecture / Requirements: CLOSED**  
**Implementation: T01–T04 CLOSED; T05 CLOSED; T06 CLOSED; T07 CLOSED**

## Seguimiento operativo

- TASK: T07 — Motor de progresión y records.
- OWNER: AURELIO.
- STATUS: CLOSED.
- Última tarea cerrada: T07 (efectivo tras verificar push de cierre).
- Commit T06: `d17f501`, push verificado.
- Commit T05: `53bd124`, push verificado.
- Commit T04: `e07db34`, push verificado.
- CHECKPOINT 1: aprobado por Rodolfo mediante CONTINUE el 2026-10-07.
- Commit de cierre T03: `7b02dc4`, push verificado.
- Commit de cierre T02: `c3d314e`, push verificado.
- Commit de cierre de T01: `402af04` (`T01: close repository initialization`).
- Push: exitoso a `origin/main` (GitHub).
- QA T01: Valerio PASS — READY TO CLOSE; sin hallazgos.
- QA T02: Valerio PASS, sin hallazgos; correcciones utilizadas: 0.
- Actualización documental de cierre T01: `f25a071`, pusheada.
- Sincronización T01: HEAD local y `refs/heads/main` remoto coinciden en `f25a071`.
- Correcciones automáticas utilizadas: 0.
- T08–T12: NOT_STARTED.

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
- Checkpoint 1 aprobado; resumen en `docs/CHECKPOINT_1.md`.

## T05 — CLOSED

- Migración `202610070004_operations_bank.sql` aplicada, sin alterar datos existentes.
- 10.412 operaciones activas y únicas: 9.798 sumas y 614 multiplicaciones.
- S1 78; S2 810; S3 810; S4 1980; S5 6120.
- M1 45; M2 65; M3 77; M4 81; M5 121; M6 225.
- `tests/t05_operations.py`: verificación exhaustiva del conjunto real PASS.
- Regresión T02/T03/T04 PASS; fixtures T02 adaptados al banco existente.
- Sin lógica de bolsa/juego ni RPC implementadas fuera de alcance.
- QA T05: Valerio PASS sin hallazgos; correcciones utilizadas: 0.

## T06 — CLOSED

- Migración `202610070005_game_sessions.sql` aplicada.
- RPC autenticados start_game_session, record_game_answer, close_game_session.
- Propietario derivado de auth.uid(); snapshot de nivel y duración 45 s.
- Operación activa del modo/nivel; scoring y totales calculados en PostgreSQL.
- Respuesta NULL incorrecta; tiempos no negativos y anteriores a 45.000 ms.
- UUID de submission y bloqueo de fila garantizan reintentos idempotentes.
- Cierre tras vencimiento; no recibe texto pendiente; no acepta respuestas nuevas tras cierre.
- Métricas de tiempo medidas por cliente, validadas por rango/orden, no anticheat.
- Pruebas T06 PASS; regresión T02–T05 PASS; fixtures revertidos.
- Progresión/records pendientes de T07; sin frontend adelantado.
- QA T06: Valerio PASS, sin hallazgos funcionales/de seguridad; correcciones: 0.

## T07 — CLOSED

- Migración `202610070006_progress_records.sql` aplicada.
- Trigger de primera finalización: progreso/historial en la transacción de cierre.
- Rachas por modo; bloqueo de perfil para serializar cambios concurrentes.
- Cinco buenas promueven; dos bajas descienden fuera del piso; máximos reinician.
- Sesiones no buenas/no bajas rompen ambas rachas por la regla de consecutividad,
  incluyendo precisión >=90% con menos de 15 operaciones.
- En el piso no hay cambio de nivel ni reinicio por R-027; low streak permanece.
- Records personales calculados desde sesiones completas, mínimo 10 operaciones,
  precisión/correctas/total, y antigüedad para estabilidad de empates completos.
- Pruebas T07 y regresión T06 PASS con rollback, sin fixtures persistentes.
- QA T07: Valerio PASS sin hallazgos; correcciones utilizadas: 0.
- Integración QA real: 14 sesiones / 210 respuestas, promociones y descensos
  en ambos modos y cierres idempotentes; fixtures revertidos.

## Próximo responsable

Senior Developer (Aurelio).

## Próximo objetivo

Verificar push de cierre T07 e iniciar T08.

## Regla operativa

Cada cierre de tarea debe actualizar `README.md` y `CURRENT_STATE.md` para reflejar el estado real del repositorio.
