# GAME_RULES.md

## 1. Sesión

1. Usuario autenticado selecciona Sumas o Multiplicaciones.
2. Se muestra nivel actual y `START`.
3. Cuenta regresiva 3-2-1.
4. Temporizador inicia en 45 s.
5. Se consumen operaciones de la bolsa equilibrada.
6. `Enter` registra respuesta y avanza.
7. En 0 s finaliza inmediatamente.
8. Se guarda sesión, respuestas, progreso y posible cambio de nivel.

## 2. Sumas S1–S5

### S1 — un dígito + un dígito
- `a,b ∈ 1..9`
- `4 <= a+b <= 18`
- excluye sumas extremadamente fáciles con resultado <4.

Ejemplos: `1+3`, `4+5`, `8+7`, `9+9`.

### S2 — dos dígitos + un dígito, sin acarreo
- un operando `10..99`;
- otro `1..9`;
- suma de unidades <=9.

Ejemplos: `23+4`, `6+31`, `70+8`.

### S3 — dos dígitos + un dígito, con acarreo
- un operando `10..99`;
- otro `1..9`;
- suma de unidades >=10.

Ejemplos: `28+5`, `9+36`, `58+7`.

### S4 — dos dígitos + dos dígitos, sin acarreo
- ambos `10..99`;
- unidades suman <=9;
- decenas suman <=9.

Ejemplos: `23+45`, `31+26`, `42+17`.

### S5 — dos dígitos + dos dígitos, con al menos un acarreo
- ambos `10..99`;
- existe al menos una columna que genera acarreo, incluyendo posible centena.

Ejemplos: `28+35`, `47+68`, `76+29`, `89+87`.

### Regla del cero
`0` no puede ser operando independiente. Números como `20`, `30`, `40` sí están permitidos si cumplen el nivel.

## 3. Multiplicaciones M1–M6

No se permiten factores 0 ni 1.

### M1
Al menos uno de los factores pertenece a `{2,5,10}` y el otro está en `2..10`.

### M2
Al menos uno pertenece a `{2,3,4,5,10}` y el otro está en `2..10`.

### M3
Al menos uno pertenece a `{2,3,4,5,6,7,10}` y el otro está en `2..10`.

### M4
`a,b ∈ 2..10`.

### M5
`a,b ∈ 2..12`.

### M6
`a,b ∈ 2..16`.

Las versiones conmutadas son ejercicios distintos.

## 4. Bolsa aleatoria equilibrada

Para cada modo/nivel:
1. cargar todas las operaciones activas;
2. mezclar;
3. consumir una a una;
4. no reinsertar por acierto/error;
5. al agotarse, volver a mezclar el conjunto completo.

## 5. Progresión

### Buena partida
- precisión >=90%;
- al menos 15 operaciones.

Cinco buenas consecutivas → subir un nivel.

### Zona neutra
75% <= precisión <90% → mantener nivel y poner ambas rachas en 0.

### Partida de dificultad
Precisión <75% → incrementar racha baja y romper racha buena.

Dos bajas consecutivas → bajar un nivel, excepto S1/M1.

### Cambio de nivel
Promoción o descenso reinicia ambas rachas del modo a cero.

### Nivel máximo
S5/M6 + cinco buenas consecutivas → mantener nivel, reiniciar rachas y registrar evento `max_level_reset` si se implementa ese motivo.

## 6. Records

Por usuario y por modo.

Una sesión es elegible si tiene >=10 operaciones.

Orden:
1. precisión descendente;
2. correctas descendente;
3. total de operaciones descendente;
4. si sigue empatado, puede conservarse el record más antiguo para estabilidad.
