# TEST_PLAN.md

## 1. Objetivo

Validar independientemente requisitos funcionales, reglas pedagógicas, persistencia, autenticación y RLS antes de aprobar v0.1.

## 2. Estrategia

### P0 — Bloqueantes
- Auth/login/logout.
- Aislamiento RLS A/B.
- Escrituras de sesión/respuestas.
- Progresión de niveles.
- Reglas del banco.

### P1 — Alta
- UI/teclado/temporizador.
- resultados/revisión de errores.
- records.

### P2 — Media
- mensajes visuales y estados secundarios.

## 3. Datos mínimos de prueba

Crear administrativamente dos usuarios:
- `playera`
- `playerb`

Ambos con perfiles independientes y niveles iniciales S1/M1.

## 4. Casos críticos

### TC-001 Login válido
Credenciales correctas → Home del usuario correcto.

### TC-002 Username inválido
Probar mayúsculas, espacio, `_`, `-`, tildes, 2 caracteres y 25 caracteres → rechazo local.

### TC-003 Credenciales inválidas
No debe revelar si falla usuario o contraseña.

### TC-004 Logout
Logout → sesión cerrada y rutas/pantallas privadas inaccesibles.

### TC-005 RLS lectura cruzada
Autenticado como A intentar leer filas de B → 0 filas/denegado.

### TC-006 RLS escritura cruzada
A intenta crear/modificar sesión de B → denegado.

### TC-007 Banco solo lectura
Authenticated puede leer `operations`; UPDATE/INSERT/DELETE desde cliente → denegado.

### TC-008 Cuenta regresiva y temporizador
3-2-1 → 45 s → 0 s; no inicia antes.

### TC-009 Teclas
Letras, signos, flechas, espacio no alteran respuesta; Backspace sí.

### TC-010 Enter vacío
Crea respuesta incorrecta con `NULL` y continúa.

### TC-011 Bolsa
Consumir banco completo sin repetición; siguiente operación tras agotamiento proviene de bolsa remezclada.

### TC-012 Clasificación S1–S5
Generar/verificar todos los registros contra reglas de `GAME_RULES.md`.

### TC-013 Clasificación M1–M6
Verificar factores y exclusión de 0/1.

### TC-014 Umbral 90%
Probar 89.99%, 90% y >=90% con 14 vs 15 operaciones.

### TC-015 Umbral 75%
Probar 74.99%, 75%, 89.99%.

### TC-016 Promoción
Cinco buenas consecutivas → +1 nivel y streaks 0.

### TC-017 Descenso
Dos <75% consecutivas → -1 nivel y streaks 0.

### TC-018 Piso
En S1/M1 dos bajas → permanece.

### TC-019 Techo
En S5/M6 cinco buenas → permanece y rachas 0.

### TC-020 Historial
Promoción/descenso genera `level_history` asociado a sesión.

### TC-021 Record mínimo
9 operaciones con 100% no compite; 10 operaciones con 100% sí.

### TC-022 Desempate
Misma precisión → más correctas; empate → más total.

### TC-023 Errores
Pantalla incluye incorrectas y vacías; no incluye correctas.

### TC-024 Fin de tiempo
Número parcialmente escrito a 0 s no se registra como respuesta.

## 5. Pruebas end-to-end

### E2E-A — Sumas
Login → Home → Sumas → START → partida → resultados → revisar errores → records → otro juego → logout.

### E2E-B — Multiplicaciones
Mismo flujo en Multiplicaciones.

### E2E-C — Multiusuario
Jugar con A, logout, jugar con B, verificar separación total de resultados/records/progreso.

## 6. Criterio de salida

- 100% de P0 PASS.
- No defectos críticos/altos abiertos.
- Todos los AC de autenticación, seguridad, progresión y banco cubiertos.
