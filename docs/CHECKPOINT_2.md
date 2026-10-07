# Checkpoint 2 — T01–T08

CHECKPOINT: 2
COMPLETED THROUGH: T08
STATUS: APPROVED — CONTINUE

Rodolfo aprobó CONTINUE el 2026-10-07. T08 cerró con `db5f020`, push verificado.
El bloque T09–T12 está autorizado. El resto conserva la foto del Checkpoint 2.

## Resumen de Aurelio

- T05: banco completo de 10.412 operaciones activas S1–S5 / M1–M6.
- T06: RPC autenticados para inicio, respuestas y cierre; ownership por auth.uid,
  scoring/totales en PostgreSQL y reintentos idempotentes.
- T07: progreso/historial en transacción de cierre y records personales por modo.
- T08: frontend estático HTML/CSS/JS Vanilla, username/password, email técnico
  interno, validación local, perfil JWT/RLS, errores genéricos y logout.
- Infraestructura: migraciones 202610070004–0006 aplicadas a Supabase; T08 no
  añade migraciones, frameworks, dependencias ni backend propio.
- Estado ejecutable: login/logout real en Chrome y pruebas backend reproducibles.
  La sesión está en memoria y recargar requiere login; Home completo y juego
  siguen pendientes de T09–T12.
- Sin desviaciones de requisitos o arquitectura aprobados.

## Resumen de Valerio

- T05: PASS, verificación exhaustiva del banco y regresión T02–T04.
- T06: PASS, persistencia/scoring/ownership/idempotencia y regresión T02–T05.
- T07: PASS, umbrales, rachas, piso/techo, historial y ranking de records.
  Integración real con RPC: 14 sesiones y 210 respuestas de fixtures con rollback.
- T08: BLOCKED inicial por cuenta ausente; PASS tras completar login/logout
  real, contraseña incorrecta, perfil propio y validación de Chrome real.
- Evidencia previa T08 de contrato, Chrome controlado y servicio público real
  conservada; sin repetir implementación ni pruebas ajenas al bloqueo resuelto.
- FAIL: ninguno. Correcciones automáticas: 0 en T05, T06, T07 y T08.
- Defectos pendientes y nuevos hallazgos de seguridad: ninguno.
- Sesiones Auth utilizadas por QA cerradas; contraseñas/JWT nunca impresos.
- Sin uso de credenciales PG/administrativas para pruebas frontend T08.

## Git

- T05: 53bd124, publicado y verificado.
- T06: d17f501, publicado y verificado.
- T07: 63cdf45, publicado y verificado.
- Este informe forma parte del commit `T08: close frontend authentication`.
  Su hash final y sincronización remota/local se informan tras verificar push.
- Archivos locales de credenciales excluidos; config.js contiene solo URL y
  publishable key, permitidos por D-020.

## Riesgos y límites

- Home/navegación, motor frontend, resultados y flujo end-to-end completos
  pendientes de T09–T12; el juego aún no es utilizable desde la interfaz.
- Sesión solo en memoria, sin persistencia ni refresh automático entre recargas.
- Métricas de tiempo de juego provenientes del cliente según contrato T06.
- Aislamiento entre usuarios respaldado por QA SQL T04; HTTP entre dos cuentas
  no repetido en T08. Integración completa/regresión final pendiente de T12.
- Logout local inmediato; el JWT ya emitido conserva su caducidad del proveedor.

Acción recomendada: CONTINUE.

Decisión recibida: CONTINUE. Aurelio retoma T09.
