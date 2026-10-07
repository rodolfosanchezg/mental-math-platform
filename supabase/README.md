# Supabase

Backend PostgreSQL reproducible; frontend todavía sin conectar.

- `migrations/202610070001_base_schema.sql`: T02, cinco tablas, constraints e índices.
- `migrations/202610070002_auth_players.sql`: T03, aprovisionamiento Auth/perfil.
- `tests/t03_auth_players.sql`: pruebas de aprovisionamiento y validación técnica.
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
ningún cliente puede utilizar todavía las tablas. T03 ya implementa la relación
administrativa Auth/perfil; T04 añadirá las políticas de propiedad/acceso. Los RPC,
el banco real, progreso y records pertenecen a las tareas posteriores.

No reutilizar scripts del prototipo basado en Anonymous Auth/`claim_player()`.

## T03 — aprovisionamiento aplicado

Crear usuarios mediante Authentication → Users en Supabase usando
`<username>@mental-math.invalid`, con username `^[a-z0-9]{3,24}$`.
El trigger crea el perfil automáticamente: no insertar otra fila manualmente.
`raw_user_meta_data.display_name` es opcional; sin él se usa username. Nunca
usar metadata para elegir niveles o rachas. El cambio administrativo de email
sincroniza username; el UUID sigue siendo la identidad de autorización.

Después de aplicar T03 una sola vez, validar con:

```sh
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t03_auth_players.sql
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t02_schema.sql
```

Signup público, Anonymous Auth y Confirm Email siguen OFF según configuración
aprobada. La migración no altera los ajustes del servicio Auth ni crea cuentas
persistentes. Frontend de login/logout pendiente de T08.
