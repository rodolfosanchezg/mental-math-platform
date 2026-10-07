# Supabase

Backend PostgreSQL reproducible; frontend todavía sin conectar.

- `migrations/202610070001_base_schema.sql`: T02, cinco tablas, constraints e índices.
- `tests/t02_schema.sql`: fixtures administrativas y pruebas negativas, siempre con rollback.

## Aplicación

Usar `psql` con las variables PG configuradas localmente y protegidas. Nunca
pasar contraseñas en argumentos ni guardar credenciales en Git. El archivo local
`.env.supabase.local` está ignorado; si se carga en shell, desactivar trazas y
exportar sus variables antes de ejecutar `psql`.

```sh
psql -X -w -v ON_ERROR_STOP=1 -f supabase/migrations/202610070001_base_schema.sql
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t02_schema.sql
```

La migración se aplica una sola vez sobre un esquema sin estas tablas, dentro de
una transacción. No borra ni sustituye tablas existentes: ante una colisión,
se detiene. Aplicar las futuras migraciones en orden de nombre y registrar su
aplicación en CURRENT_STATE. Las pruebas requieren conexión administrativa:
crean fixtures únicamente dentro de una transacción que termina en ROLLBACK.

## Estado T02

Migración aplicada al proyecto configurado; pruebas del desarrollador y QA PASS.
RLS habilitado sin políticas y permisos de `anon`/`authenticated` revocados:
ningún cliente puede utilizar todavía las tablas. T03 implementará la relación
administrativa Auth/perfil y T04 las políticas de propiedad/acceso. Los RPC,
el banco real, progreso y records pertenecen a las tareas posteriores.

No reutilizar scripts del prototipo basado en Anonymous Auth/`claim_player()`.
