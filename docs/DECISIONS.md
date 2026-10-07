# DECISIONS.md

## Decisiones aprobadas v0.1

### D-001 — Stack
HTML5 + CSS3 + JavaScript Vanilla + Supabase Auth/PostgreSQL/RLS.

### D-002 — Duración inicial
45 segundos, diseñada para ser configurable en versiones futuras.

### D-003 — Cuenta regresiva
3-2-1 antes de iniciar el temporizador.

### D-004 — Entrada
Durante juego: números, Enter y Backspace. Backspace podrá eliminarse en una versión futura para aumentar dificultad.

### D-005 — Feedback
✓/✗ breve, aproximadamente 250–400 ms.

### D-006 — Revisión posterior
La respuesta correcta no se muestra durante la partida; los errores se revisan al finalizar.

### D-007 — Banco
Bolsa aleatoria equilibrada, sin repetición hasta agotarla.

### D-008 — Progresión
>=90% y >=15 operaciones = buena partida; 5 buenas consecutivas = promoción. <75% dos veces consecutivas = descenso. 75–89.99% rompe rachas.

### D-009 — Records
Precisión como criterio principal; mínimo 10 operaciones; desempate por correctas y luego total.

### D-010 — Sumas
Máximo S5.

### D-011 — Multiplicaciones
Máximo M6; factores hasta 16.

### D-012 — Auth visible
Login visible mediante `username + password`.

### D-013 — Email técnico interno
El frontend transforma determinísticamente `username` a un email técnico interno y autentica con Supabase email/password.

Formato aprobado: `<username>@mental-math.invalid`.

### D-014 — Username
Solo letras minúsculas `a-z` y números `0-9`, longitud 3–24. Regex: `^[a-z0-9]{3,24}$`.

### D-015 — Creación de usuarios
Solo administrativa desde Supabase. No existe `Crear cuenta`.

### D-016 — Recuperación de contraseña
No existe en v0.1; reset administrativo.

### D-017 — Auth Supabase
Email/password habilitado, public signup OFF, Anonymous Auth OFF, Confirm Email OFF para cuentas técnicas administradas.

### D-018 — Identidad de seguridad
La autorización se basa en `auth.uid()`, nunca en username.

### D-019 — RLS
Obligatorio en `players`, `sessions`, `session_answers`, `level_history`. `operations` es lectura para authenticated y no modificable desde frontend.

### D-020 — API keys
Frontend usa Project URL + publishable key. Secret/service_role nunca se expone al navegador ni al repositorio.

### D-021 — Fuente de verdad
Los documentos aprobados gobiernan implementación. Cambios materiales requieren actualización documental previa y aprobación del usuario.
