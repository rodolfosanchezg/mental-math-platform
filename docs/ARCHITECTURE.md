# ARCHITECTURE.md

## 1. Arquitectura aprobada

```text
Browser
  |
  | HTML/CSS/JavaScript Vanilla
  |
  +--> Supabase Auth
  |      username visible -> technical email -> password
  |
  +--> Supabase Data API / RPC
         |
         +--> PostgreSQL
         +--> RLS
```

No existe backend propio en v0.1.

## 2. Frontend conceptual

Módulos recomendados:

- `auth` — login/logout/sesión.
- `ui` — navegación y renderizado.
- `game` — ciclo de partida.
- `timer` — cuenta regresiva y 45 s.
- `operations` — carga y bolsa equilibrada.
- `scoring` — respuesta local/feedback y datos a persistir.
- `progress` — lectura del nivel y resultado del cierre de sesión.
- `records` — consulta del mejor resultado personal.
- `supabase` — cliente y llamadas al backend.

La separación puede implementarse con archivos JS simples, sin framework.

## 3. Autenticación

La UI recibe:

```text
username
password
```

Valida username con `^[a-z0-9]{3,24}$` y genera:

```text
<username>@mental-math.invalid
```

Luego usa Supabase Auth email/password.

La identidad de autorización es `auth.uid()`.

## 4. Creación de usuarios

Fuera del frontend:
1. administrador crea Auth User en Supabase con email técnico y password;
2. crea/asocia `players` con mismo `auth.users.id`, username y display_name;
3. niveles iniciales S1/M1.

La implementación puede automatizar la creación del perfil mediante trigger seguro o procedimiento administrativo, pero debe preservar esta relación 1:1.

## 5. Seguridad

- signup público OFF;
- anonymous OFF;
- confirm email OFF;
- RLS en tablas personales;
- operaciones solo lectura para usuario autenticado;
- publishable key permitida en cliente;
- secret/service_role exclusivamente administración/entorno seguro;
- el frontend no puede elegir otro propietario para leer/escribir datos.

## 6. Backend lógico

La lógica crítica de persistencia/progreso debería ejecutarse transaccionalmente en PostgreSQL/RPC para evitar inconsistencias:

- iniciar sesión de juego;
- registrar respuestas;
- cerrar sesión;
- calcular totales/accuracy;
- actualizar rachas/nivel;
- insertar `level_history`;
- obtener record.

El frontend coordina; el backend protege invariantes.

## 7. Hosting

Frontend estático compatible con GitHub Pages u hosting estático equivalente. Supabase opera como backend administrado.

## 8. No requerido

- microservicios;
- servidor Node/Express;
- React/Next.js;
- API propia;
- cache distribuida;
- colas.
