# SUPABASE_SETUP.md

## Estado aprobado

El proyecto Supabase limpio ya fue creado y la configuración inicial de Auth fue completada.

## Configuración objetivo

### Authentication
- Email/password: ON
- Allow new users to sign up: OFF
- Anonymous sign-ins: OFF
- Confirm Email: OFF

### Identidad técnica
Username visible:

```text
maria23
```

Email técnico interno:

```text
maria23@mental-math.invalid
```

La aplicación nunca muestra ni solicita este email.

### Username
Regex obligatoria:

```text
^[a-z0-9]{3,24}$
```

### API keys
Frontend:
- Project URL
- publishable key

Nunca frontend:
- secret key
- service_role

## Orden de implementación de backend

1. Crear migración de tablas.
2. Crear constraints e índices.
3. Configurar RLS/policies.
4. Crear funciones/RPC transaccionales necesarias.
5. Cargar banco de operaciones.
6. Ejecutar pruebas SQL/RLS.
7. Crear usuarios administrativos de prueba.
8. Crear/asociar `players`.
9. Repetir pruebas A/B.
10. Solo después conectar frontend.

## Creación manual de usuario

Después de que el esquema definitivo exista:
1. Authentication → Users → Add/Create user.
2. Email = `<username>@mental-math.invalid`.
3. Definir password.
4. Crear/asociar perfil `players` con `auth_user_id` del usuario.
5. `username` debe respetar regex.
6. `display_name` puede contener el nombre amigable mostrado en Home.
7. S1/M1 y rachas 0.

## RLS objetivo

- `players`: usuario solo su fila.
- `sessions`: usuario solo sesiones cuyo player le pertenece.
- `session_answers`: solo respuestas de sesiones propias.
- `level_history`: solo historial propio.
- `operations`: SELECT para authenticated; sin mutación desde cliente.

## Prueba mínima antes de frontend

Con `playera` y `playerb`:
- A puede consultar A.
- A no puede consultar B.
- A no puede insertar/actualizar datos cuyo owner sea B.
- B cumple simétricamente.
- ambos pueden leer `operations`.
- ninguno puede modificar `operations` desde cliente.
