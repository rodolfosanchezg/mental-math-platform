# Checkpoint 1 — T01–T04

CHECKPOINT: 1
COMPLETED THROUGH: T04
STATUS: WAITING FOR OWNER APPROVAL

El estado operativo del proyecto es CHECKPOINT_WAIT tras verificar el push del
commit de cierre T04. T01–T04 están CLOSED; T05–T12 siguen NOT_STARTED.

## Resumen de Aurelio

- T01: estructura inicial, ignore seguro y documentación; QA PASS previo.
- T02: cinco tablas PostgreSQL, constraints, defaults, FK, unicidad e índices.
- T03: trigger seguro de aprovisionamiento administrativo Auth/perfil, UUID
  compartido, username técnico validado, S1/M1 y rachas cero.
- T04: cinco políticas RLS SELECT; datos propios por auth.uid(), banco
  compartido para authenticated, anon sin acceso y escrituras directas denegadas.
- Tres migraciones aplicadas en orden al proyecto Supabase configurado.
- Estado ejecutable: pruebas SQL administrativas reproducibles; frontend
  placeholder, banco vacío, sin cuentas reales persistentes ni RPC de juego.
- No se añadieron dependencias, frameworks ni herramientas.
- Sin desviaciones del stack o arquitectura aprobados.

## Resumen de Valerio

- T01: PASS previo confirmado por Rodolfo; no se repitió QA.
- T02: PASS independiente de esquema, relaciones, constraints, defaults e índices.
- T03: PASS independiente de aprovisionamiento, UUID, validación y atomicidad.
- T04: PASS independiente de aislamiento A/B/anónimo y banco solo lectura.
- FAIL: ninguno; iteraciones de corrección automática: 0 en cada tarea.
- Regresión T02–T03 tras aplicar T04: PASS.
- Fixtures transaccionales con ROLLBACK; cero usuarios Auth y cero filas en las
  cinco tablas después de la validación.
- Defectos pendientes y hallazgos de seguridad: ninguno en el alcance validado.
- Scripts preparados: supabase/tests/t02_schema.sql, t03_auth_players.sql y
  t04_rls.sql; QA no editó código ni migraciones.

## Git

- T01: 402af04; normalización documental f25a071, ambos publicados.
- T02: c3d314e, publicado y verificado.
- T03: 7b02dc4, publicado y verificado.
- T04: este documento forma parte del commit `T04: close RLS and multi-user security`.
  Su hash final y la igualdad de HEAD remoto/local se informan al verificar push.
- Credenciales PG locales ignoradas y excluidas de todos los commits.

## Riesgos y límites

- Pruebas de seguridad con roles reales PostgreSQL y claims simulados;
  flujos de Auth/API con JWT real y UI quedan para tareas posteriores.
- Ajustes iniciales del servicio Auth respaldados documentalmente; las
  migraciones no modifican signup, Anonymous Auth ni Confirm Email.
- Escrituras del cliente solo se habilitarán mediante los RPC que verifican
  identidad de T06–T07. No usar permisos directos para alterar progreso.
- Banco, lógica de juego, progresión, records y frontend aún pendientes.
- Ningún riesgo técnico bloqueante ni desviación arquitectónica detectados.

Acción recomendada: CONTINUE.

Rodolfo debe responder CONTINUE, FIX o REPLAN. No iniciar T05 hasta su decisión.
