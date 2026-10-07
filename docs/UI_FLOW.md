# UI_FLOW.md

## 1. Login

```text
MENTAL MATH
Usuario      [________]
Contraseña   [________]
[ INICIAR SESIÓN ]
```

No mostrar:
- crear cuenta;
- email;
- recuperar contraseña.

Error de autenticación debe ser genérico y no revelar si username o password fue el incorrecto.

## 2. Home

```text
Hola, <display_name>

Sumas: Sx
[ SUMAS ]

Multiplicaciones: Mx
[ MULTIPLICACIONES ]

[ VER RECORDS ]   [ LOGOUT ]
```

## 3. Pre-juego

```text
SUMAS
Nivel S2

[ START ]
```

Luego: `3`, `2`, `1`.

## 4. Juego

```text
45                         <- esquina superior izquierda

              28 + 5
                 3         <- respuesta parcial
```

Feedback breve ✓ / ✗.

## 5. Resultados

```text
TIEMPO TERMINADO

Operaciones     24
Correctas       20
Incorrectas      4
Precisión      83.3%

[mensaje de nivel si aplica]

[ OTRO JUEGO ]
[ CAMBIAR A MULTIPLICACIONES ]
[ REVISAR ERRORES ]
[ VER RECORDS ]
```

## 6. Revisar errores

Cada elemento:

```text
7 × 8
Tu respuesta: 42
Correcta: 56
```

Respuesta vacía:

```text
9 × 6
Tu respuesta: —
Correcta: 54
```

## 7. Records

Mostrar record personal de Sumas y de Multiplicaciones, con al menos precisión, correctas, total, nivel y fecha.
