# REQUIREMENTS.md

## 1. Objetivo

Crear una plataforma web sencilla para mejorar fluidez, precisión y cálculo mental elemental mediante sesiones de sumas y multiplicaciones.

## 2. Alcance v0.1

### R-001 — Autenticación obligatoria
El usuario debe iniciar sesión antes de acceder al Home.

### R-002 — Credenciales visibles
La interfaz solicitará `username` y `password`. No mostrará ni solicitará email.

### R-003 — Sin creación de cuenta
La aplicación no tendrá opción de registro. Los usuarios serán creados manualmente en Supabase.

### R-004 — Sin recuperación de contraseña
v0.1 no tendrá flujo "Forgot password". El reset será administrativo desde Supabase.

### R-005 — Home
Tras autenticarse, el usuario verá su nombre/perfil, nivel actual de Sumas, nivel actual de Multiplicaciones, botones `SUMAS`, `MULTIPLICACIONES`, `VER RECORDS` y `LOGOUT`.

### R-006 — Inicio de juego
Al seleccionar Sumas o Multiplicaciones se mostrará el nivel actual y un botón `START`.

### R-007 — Cuenta regresiva
Al pulsar `START`, se mostrará `3 - 2 - 1` y luego comenzará la sesión.

### R-008 — Duración
La duración inicial será de 45 segundos. La arquitectura debe permitir duraciones futuras distintas.

### R-009 — Operación en pantalla
Durante la sesión se mostrará una sola operación grande en el centro de la pantalla y el valor escrito debajo.

### R-010 — Teclas funcionales
Durante la sesión solo serán funcionales `0-9`, `Enter` y `Backspace`.

### R-011 — Enter vacío
`Enter` puede pulsarse sin haber escrito números. La respuesta se registra como incorrecta y `answer_given = null`.

### R-012 — Flujo continuo
Correcta o incorrecta, cada pulsación válida de `Enter` avanza a la siguiente operación.

### R-013 — Feedback inmediato
Se mostrará brevemente `✓` o `✗` durante aproximadamente 250–400 ms sin bloquear el flujo.

### R-014 — Fin de tiempo
Cuando el temporizador llegue a cero, cualquier respuesta no enviada se descarta y la sesión finaliza.

### R-015 — Temporizador visible
El temporizador estará visible en la esquina superior izquierda.

### R-016 — Sin contador de ejercicios
La cantidad de operaciones realizadas no se mostrará durante la partida.

### R-017 — Resultados
Al finalizar se mostrarán: total de operaciones, aciertos, incorrectas y porcentaje de certeza.

### R-018 — Acciones post-partida
La pantalla de resultados tendrá: `OTRO JUEGO`, `CAMBIAR A <OPERACIÓN CONTRARIA>`, `REVISAR ERRORES` y `VER RECORDS`.

### R-019 — Revisión de errores
Debe mostrar respuestas incorrectas y vacías, incluyendo operación, respuesta dada y respuesta correcta.

### R-020 — Historial
Cada sesión y cada respuesta enviada deben almacenarse.

### R-021 — Tiempo de respuesta
Cada respuesta debe almacenar su tiempo de respuesta en milisegundos.

### R-022 — Niveles automáticos
El sistema determina automáticamente el nivel. El usuario no selecciona nivel en v0.1.

### R-023 — Nivel inicial
Un usuario nuevo comienza en `S1` y `M1`.

### R-024 — Promoción
Una sesión es "buena" si tiene precisión >=90% y al menos 15 operaciones. Cinco sesiones buenas consecutivas promueven un nivel.

### R-025 — Zona neutra
Una sesión con precisión entre 75% y 89.99% mantiene nivel y rompe ambas rachas.

### R-026 — Dificultad
Una sesión con precisión <75% cuenta como sesión de dificultad. Dos consecutivas producen descenso, salvo en S1/M1.

### R-027 — Reinicio de rachas
Al subir o bajar de nivel, ambas rachas del modo se reinician a cero.

### R-028 — Nivel máximo
En S5/M6, cinco buenas partidas consecutivas no crean un nivel nuevo: se mantiene el nivel y se reinicia la racha.

### R-029 — Historial de niveles
Cada cambio de nivel se almacenará con nivel anterior, nuevo, motivo, sesión y fecha.

### R-030 — Bolsa equilibrada
Cada nivel usará una bolsa aleatoria equilibrada. No se repite una operación hasta agotar la bolsa disponible del nivel.

### R-031 — Repetición tras agotamiento
Al agotarse la bolsa, se vuelve a mezclar y pueden reaparecer operaciones.

### R-032 — Errores sin prioridad en v0.1
Una respuesta incorrecta no altera el orden de la bolsa actual. Priorización adaptativa queda fuera de v0.1.

### R-033 — Operaciones conmutadas
`7+8` y `8+7` son ejercicios diferentes. `7×8` y `8×7` también.

### R-034 — Cero en sumas
`0` no puede ser operando. Sí pueden aparecer números que contengan el dígito cero, por ejemplo `20+7`.

### R-035 — Uno en sumas
El operando `1` está permitido.

### R-036 — Cero y uno en multiplicaciones
No se permiten factores `0` ni `1`.

### R-037 — Banco real
Las operaciones se almacenarán en una tabla real de Supabase.

### R-038 — Records
Existirá un record personal separado para Sumas y Multiplicaciones.

### R-039 — Elegibilidad de record
Una sesión necesita al menos 10 operaciones para competir por record.

### R-040 — Ranking de record
Orden: mayor precisión; empate → más correctas; nuevo empate → más operaciones.

### R-041 — Seguridad multiusuario
Cada usuario solo puede acceder a sus propios datos de progreso, sesiones, respuestas y records.

### R-042 — Banco compartido
Los usuarios autenticados pueden leer el banco de operaciones, pero no modificarlo desde el cliente.

### R-043 — Logout
El usuario debe poder cerrar sesión y perder acceso a las pantallas protegidas.

## 3. Restricciones

- Frontend v0.1: HTML/CSS/JavaScript Vanilla.
- No React, Next.js, Express ni backend propio salvo que un requisito futuro lo justifique.
- No signup público.
- No Anonymous Auth.
- No `service_role`/secret key en frontend.
- No dificultad adaptativa en v0.1.
- No records globales en v0.1.
- No selección manual de tabla específica en v0.1.
