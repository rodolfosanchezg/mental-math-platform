# Mental Math Platform — v0.1

Plataforma web educativa para desarrollar fluidez en cálculo mental mediante sesiones cronometradas de sumas y multiplicaciones.

## Estado

**Requisitos y arquitectura: cerrados.**  
**Implementación: T01–T07 CLOSED, QA PASS.**

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
frontend sigue siendo un placeholder; no hay lógica de juego implementada.
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
