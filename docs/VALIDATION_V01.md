# Validación v0.1 — T12

TASK: T12
OWNER: AURELIO
STATUS: CLOSED
QA RESULT: PASS
CORRECTION ITERATION: 1

La matriz conserva requisitos/criterios aprobados. Valerio completó validación
funcional/seguridad/regresión y E2E final con PASS. Resultado global inicial FAIL
por F1 documental; Corrección #1 exclusivamente documental aprobada por Valerio.
No se cambió implementación ni se repitieron pruebas funcionales sin necesidad.

| Criterios | Evidencia reproducible |
| --- | --- |
| AC-A01–A05 | QA real Chrome T08/T09; contrato tests/t08_auth.test.mjs; sesión en memoria, login/logout y error genérico |
| AC-A06–A08 | supabase/tests/t04_rls.sql y tests/t12_security.mjs con dos JWT reales, lectura propia/cruzada, DML/RPC denegados y anon |
| AC-G01–G09 | tests/t10_game.test.mjs, Chrome T10 real ambos modos y tests/t11_browser.html; countdown, 45s, teclado, bolsa y descarte |
| AC-S01–S07 / AC-M01–M08 | tests/t05_operations.py, conjunto completo de 10.412 operaciones |
| AC-P01–P02 | supabase/tests/t06_sessions.sql y Chrome real T10/T11: respuestas, timestamps, tiempos, scoring, cierre y retry |
| AC-P03–P09 | supabase/tests/t07_progress_records.sql, límites exactos, mínimo15, rachas, piso/techo, historia y modos independientes; integración QA T07 |
| AC-R01–R05 | supabase/tests/t07_progress_records.sql y Chrome T11 real: resultados, errores/vacías, mínimo10 y record elegible |

## Validaciones del desarrollador T12

- Contrato Auth/motor Node: PASS.
- Regresión SQL T02/T03/T04/T06/T07: PASS, fixtures con ROLLBACK.
- Banco completo S1–S5/M1–M6: PASS.
- Dos cuentas HTTP reales: datos propios/lectura cruzada/records/anon PASS;
  POST/PATCH/DELETE a tablas y cierre RPC de sesión ajena rechazados.
- B no tenía sesiones: fixture de juego normal de Multiplicaciones con respuesta
  NULL y cierre tras 45 s, conservado en cuenta QA. Sin limpieza destructiva.
- Credenciales locales ignoradas, valores y JWT nunca impresos.

## Comandos

```sh
node --experimental-default-type=module --test tests/t08_auth.test.mjs tests/t10_game.test.mjs
node --experimental-default-type=module tests/t12_security.mjs
```

El test HTTP lee únicamente .env.auth-test.local/.env.auth-test-user2.local y la
configuración pública. Si B no tiene partidas, crea una sesión normal de QA con
una respuesta NULL, espera su vencimiento y cierra. Las partidas quedan en la
cuenta administrativa de prueba; las sesiones Auth se cierran al finalizar.

Con las variables PG administrativas protegidas, ejecutar por separado:

```sh
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t02_schema.sql
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t03_auth_players.sql
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t04_rls.sql
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t06_sessions.sql
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t07_progress_records.sql
python3 tests/t05_operations.py
```

No servir la raíz del repositorio ni archivos .env en HTTP. Servir solo src.

## QA final independiente completada

Valerio ejecutó E2E-A Sumas, E2E-B Multiplicaciones y E2E-C cambio A→logout→B
en Chrome contra Supabase real: PASS. Resultados, errores/vacías, records propios,
HOME y logout coinciden con el backend. SQL/banco/HTTP A/B/Node: PASS. Ningún
defecto funcional o de seguridad observado; fixtures y secretos protegidos.

Partidas QA finales conservadas:

- A Sumas: 15a03c3e-77fc-4963-92d9-6b295fe39eea.
- A Multiplicaciones: 638d8916-bb1f-4808-a8d9-f5410608bb60.
- B Sumas: 5088f930-c9ed-45ac-8b8b-0499aabd096c.

Cada una tiene 10 respuestas, 8 correctas y 2 incorrectas, precisión 80%.
Son 30 respuestas persistentes; progreso/records de cuentas QA actualizados
normalmente. Sin limpieza destructiva; sesiones Auth utilizadas cerradas.
Los fixtures SQL se revirtieron y preservaron los datos persistentes existentes.

F1: README y Supabase README tenían frases de etapas anteriores; CURRENT_STATE
mezclaba estados T12 y conservaba HEAD T09. Corrección #1 sincroniza los cuatro
documentos operativos con T01–T11 integrados, T12 READY_FOR_REREVIEW y último
commit cerrado/pusheado previo T11 3c28938. Código funcional sin cambios.

Re-review documental: PASS, F1 resuelto y ningún defecto pendiente. T12 cierra
con QA PASS, documentación, commit y push verificado. Checkpoint 3 requiere
validación/aprobación final de Rodolfo; este documento no declara v0.1 finalizada
sin esa decisión.
