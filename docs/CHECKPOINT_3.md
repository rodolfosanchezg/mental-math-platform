# Checkpoint 3 — T01–T12

Este informe conserva la foto del cierre T12. El deployment posterior PAGES,
autorizado por Rodolfo y validado en vivo, figura en README y CURRENT_STATE.

CHECKPOINT: 3
COMPLETED THROUGH: T12
STATUS: WAITING FOR OWNER APPROVAL

T01–T12 CLOSED tras verificar el push del commit de cierre T12. El proyecto
queda en CHECKPOINT_WAIT. v0.1 requiere validación/aprobación final de Rodolfo
y su autorización explícita de cierre.

## Resumen de Aurelio

- T01–T04: estructura, esquema reproducible, Auth/perfil y RLS.
- T05–T08: banco de 10.412 operaciones, sesiones RPC, progreso/records y login/logout.
- T09: Home con perfil/niveles y navegación principal.
- T10: bolsa equilibrada paginada, countdown, 45 s, teclado, feedback y guardado idempotente.
- T11: resultados, errores/vacías, records y nivel actualizado.
- T12: integración y regresión final, matriz de criterios y seguridad HTTP A/B.
- Seis migraciones aplicadas a Supabase; stack HTML/CSS/JS Vanilla y PostgreSQL/RLS.
- Sin frameworks, dependencias adicionales, backend propio ni desviaciones aprobadas.
- Estado utilizable: aplicación estática integrada, ambos modos y flujo completo.
  Ejecutar según README sirviendo únicamente src; no servir archivos locales.

## Resumen de Valerio

- T01–T12: PASS final.
- T08 BLOCKED por falta de cuenta real, resuelto sin corregir implementación.
- T12 FAIL inicial solo por F1 documental; resuelto en Corrección #1, re-review PASS.
- T01–T11: 0 correcciones. T12: 1 corrección exclusivamente documental.
- E2E-A Sumas, E2E-B Multiplicaciones, E2E-C A→logout→B en Chrome real: PASS.
- Cada partida final: 10 respuestas, 8 correctas, 2 incorrectas y 80%.
- SQL T02/T03/T04/T06/T07 con rollback, banco completo y Node Auth/game: PASS.
- HTTP con dos JWT reales: aislamiento propio/cruzado, denegación DML/RPC
  ajenos, banco autenticado, records propios y bloqueo anónimo: PASS.
- Credenciales protegidas e ignoradas; cero firmas privadas/env versionados.
- Ningún defecto abierto ni hallazgo de seguridad pendiente.

## Git

- T08 db5f020; T09 1280412; T10 e5b211f; T11 3c28938: publicados y verificados.
- Este documento pertenece al commit `T12: close integration and regression`.
  El hash final, push y sincronización local/remota se informan al finalizar.
- README y CURRENT_STATE reflejan T01–T12 CLOSED y Checkpoint 3 pendiente.
- Configuración cliente contiene solo URL/publishable key permitidos por D-020;
  .env de Auth A/B y PostgreSQL excluidos de Git.

## Datos de prueba y límites

- Partidas normales de QA permanecen en las cuentas administrativas de prueba;
  no se borraron ni reiniciaron datos. Progreso/records se actualizaron normalmente.
- QA final dejó tres partidas/30 respuestas; además permanece el fixture normal
  B de Multiplicaciones/NULL del test HTTP. Detalle en VALIDATION_V01.
- Fixtures SQL revertidos; sesiones Auth utilizadas por QA cerradas.
- Sesión cliente solo en memoria: recargar requiere login, sin refresh automático.
- Entrada requiere teclado; tiempos de respuesta provienen del cliente y se validan
  por rango/orden; no es un sistema anticheat.
- Logout bloquea acceso local y revoca sesión remota; JWT emitido conserva su caducidad.
- No se desplegó hosting; frontend estático listo para servir según README.

Acción recomendada: VALIDATE AND APPROVE FINAL CLOSURE.

Rodolfo debe realizar o aprobar la validación final y autorizar el cierre de v0.1.
Si solicita FIX o REPLAN, atender esa decisión antes de declarar v0.1 completa.
