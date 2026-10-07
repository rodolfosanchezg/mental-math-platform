# ACCEPTANCE_CRITERIA.md

## Autenticación y seguridad

- **AC-A01** Login acepta username válido + password correcto y permite entrar al Home.
- **AC-A02** Username inválido por regex no se envía a autenticación.
- **AC-A03** La UI no muestra signup, email ni forgot password.
- **AC-A04** Password incorrecto/usuario inexistente no revela cuál dato falló.
- **AC-A05** Logout invalida la sesión del cliente y bloquea pantallas protegidas.
- **AC-A06** Usuario A no puede leer/modificar `players`, `sessions`, `session_answers` o `level_history` de B.
- **AC-A07** Un usuario autenticado puede leer `operations` pero no mutarlas desde el cliente.
- **AC-A08** Un usuario no autenticado no puede acceder a datos personales.

## Juego

- **AC-G01** Start ejecuta 3-2-1 y luego inicia 45 s.
- **AC-G02** Solo 0–9, Enter y Backspace afectan la respuesta durante juego.
- **AC-G03** Enter vacío registra incorrecta con `answer_given = NULL`.
- **AC-G04** Enter siempre avanza a otra operación mientras quede tiempo.
- **AC-G05** ✓/✗ aparece brevemente sin impedir nueva entrada.
- **AC-G06** A 0 s se descarta cualquier texto no enviado.
- **AC-G07** El contador está arriba a la izquierda y no se muestra contador de ejercicios.
- **AC-G08** No se repite una operación antes de agotar la bolsa del nivel.
- **AC-G09** Al agotar la bolsa se puede volver a usar cualquier operación tras nueva mezcla.

## Banco Sumas

- **AC-S01** S1 cumple operandos 1–9 y resultado 4–18.
- **AC-S02** S2 contiene 2 dígitos + 1 dígito sin acarreo.
- **AC-S03** S3 contiene 2 dígitos + 1 dígito con acarreo.
- **AC-S04** S4 contiene 2 dígitos + 2 dígitos sin acarreo en unidades ni decenas.
- **AC-S05** S5 contiene 2 dígitos + 2 dígitos con al menos un acarreo.
- **AC-S06** Ninguna suma usa 0 como operando; números con dígito 0 sí pueden aparecer.
- **AC-S07** Versiones conmutadas se consideran operaciones distintas.

## Banco Multiplicación

- **AC-M01** Ninguna multiplicación contiene factor 0 o 1.
- **AC-M02** M1 corresponde a 2/5/10 con otro factor 2–10.
- **AC-M03** M2 corresponde a 2/3/4/5/10 con otro factor 2–10.
- **AC-M04** M3 corresponde a 2/3/4/5/6/7/10 con otro factor 2–10.
- **AC-M05** M4 contiene factores 2–10.
- **AC-M06** M5 contiene factores 2–12.
- **AC-M07** M6 contiene factores 2–16.
- **AC-M08** Versiones conmutadas son distintas.

## Persistencia y progreso

- **AC-P01** Cada sesión guarda modo, nivel, duración, totales, precisión y timestamps.
- **AC-P02** Cada respuesta enviada guarda operación, respuesta/null, corrección y tiempo de respuesta.
- **AC-P03** >=90% con >=15 operaciones incrementa good streak.
- **AC-P04** 75–89.99% reinicia ambas rachas sin cambiar nivel.
- **AC-P05** <75% incrementa low streak y rompe good streak.
- **AC-P06** 5 buenas consecutivas promocionan y reinician rachas.
- **AC-P07** 2 bajas consecutivas descienden y reinician rachas, excepto S1/M1.
- **AC-P08** S5/M6 no pueden promover; al completar 5 buenas se mantienen y reinician racha.
- **AC-P09** Todo cambio de nivel se registra en `level_history`.

## Resultados y records

- **AC-R01** Resultados muestran total, correctas, incorrectas y accuracy.
- **AC-R02** Revisar errores incluye incorrectas y vacías con respuesta correcta.
- **AC-R03** Records se calculan por usuario y por modo.
- **AC-R04** Sesiones con <10 operaciones no son elegibles.
- **AC-R05** Ranking: accuracy, correctas, total.
