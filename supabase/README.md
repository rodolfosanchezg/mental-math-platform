# Supabase

Backend PostgreSQL reproducible; frontend todavía sin conectar.

## Migraciones aplicadas

1. `202610070001_base_schema.sql` — T02: cinco tablas, constraints e índices.
2. `202610070002_auth_players.sql` — T03: aprovisionamiento Auth/perfil.
3. `202610070003_rls_security.sql` — T04: lectura propia y banco autenticado.
4. `202610070004_operations_bank.sql` — T05: banco completo de operaciones.

Cada migración se aplica una sola vez en este orden, en una transacción.
No borra ni sustituye tablas existentes: ante colisión se detiene. La aplicación
se registra en CURRENT_STATE. No reutilizar scripts del prototipo basado en
Anonymous Auth/`claim_player()`.

## Conexión y validación

Usar `psql` con las variables PG locales protegidas. Nunca pasar contraseñas en
argumentos ni guardar credenciales en Git. `.env.supabase.local` está ignorado;
si se carga en shell, desactivar trazas y exportar sus variables antes de ejecutar
`psql`. Las pruebas requieren conexión administrativa y usan fixtures seguros
únicamente dentro de transacciones que terminan en ROLLBACK.

```sh
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t02_schema.sql
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t03_auth_players.sql
psql -X -w -v ON_ERROR_STOP=1 -f supabase/tests/t04_rls.sql
```

## Usuarios administrativos

Crear usuarios mediante Authentication → Users en Supabase usando
`<username>@mental-math.invalid`, con username `^[a-z0-9]{3,24}$`.
El trigger crea el perfil automáticamente con el mismo UUID y S1/M1, rachas 0:
no insertar otra fila manualmente. `raw_user_meta_data.display_name` es opcional;
sin él se usa username. Nunca usar metadata para elegir niveles o rachas.
El cambio administrativo de email sincroniza username; el UUID sigue siendo
la identidad de autorización.

Signup público, Anonymous Auth y Confirm Email siguen OFF según configuración
aprobada. Las migraciones no alteran los ajustes del servicio Auth ni crean
cuentas persistentes. Frontend login/logout pendiente de T08.

## Acceso después de T04

RLS en las cinco tablas. El cliente authenticated puede leer sus propios datos
personales y el banco operations. anon no tiene acceso. Ninguno de los roles
API puede INSERT/UPDATE/DELETE directamente, incluso sobre datos propios;
la persistencia y progreso se implementarán con RPC que verifican identidad
en T06–T07. Esto evita permitir al cliente alterar niveles o resultados.

T04 valida roles y claims dentro de PostgreSQL; pruebas de UI y flujos completos
quedan para las tareas frontend/integración. El banco T05 contiene 10.412 operaciones activas.

## Verificación del banco T05

Con las variables PG protegidas exportadas:

```sh
python3 tests/t05_operations.py
```

El script usa solo la biblioteca estándar de Python ya disponible como herramienta
de validación; consulta PostgreSQL en lectura y compara exhaustivamente el banco
con las reglas S1–S5 / M1–M6. No introduce dependencias del producto.
