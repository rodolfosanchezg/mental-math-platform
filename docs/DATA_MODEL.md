# DATA_MODEL.md

## 1. Principio

Supabase Auth administra credenciales y sesión. Las tablas públicas almacenan datos de aplicación y se vinculan con `auth.users.id`.

## 2. Entidades

### players
- `id` UUID PK
- `auth_user_id` UUID UNIQUE NOT NULL → `auth.users.id`
- `username` TEXT UNIQUE NOT NULL
- `display_name` TEXT NOT NULL
- `current_addition_level` TEXT NOT NULL default `S1`
- `addition_good_streak` INT NOT NULL default 0
- `addition_low_streak` INT NOT NULL default 0
- `current_multiplication_level` TEXT NOT NULL default `M1`
- `multiplication_good_streak` INT NOT NULL default 0
- `multiplication_low_streak` INT NOT NULL default 0
- `created_at` TIMESTAMPTZ NOT NULL

Constraints:
- username `^[a-z0-9]{3,24}$`;
- addition level ∈ S1..S5;
- multiplication level ∈ M1..M6;
- streaks >=0.

### operations
- `id` UUID PK
- `type` (`addition` | `multiplication`)
- `operand_a` INT
- `operand_b` INT
- `result` INT
- `level` TEXT
- `active` BOOLEAN default true
- `created_at`

Debe existir unicidad lógica al menos sobre `(type, operand_a, operand_b, level)`.

### sessions
- `id` UUID PK
- `player_id` UUID FK
- `type`
- `level`
- `duration_seconds`
- `total_operations`
- `correct_answers`
- `incorrect_answers`
- `accuracy`
- `started_at`
- `completed_at`

El nivel queda congelado en la sesión aunque el jugador cambie después.

### session_answers
- `id` UUID PK
- `session_id` UUID FK
- `operation_id` UUID FK
- `answer_given` INT NULL
- `is_correct` BOOLEAN
- `response_time_ms` INT
- `answered_at`

`answer_given = NULL` representa Enter vacío.

### level_history
- `id` UUID PK
- `player_id` UUID FK
- `operation_type`
- `previous_level`
- `new_level`
- `reason` (`promotion`, `demotion`, opcionalmente `max_level_reset`)
- `session_id` UUID FK
- `changed_at`

## 3. Relaciones

`auth.users 1—1 players`  
`players 1—N sessions`  
`sessions 1—N session_answers`  
`operations 1—N session_answers`  
`players 1—N level_history`

## 4. Records

No se requiere tabla `records` en v0.1. Se calculan dinámicamente desde `sessions` filtradas por usuario, modo y `total_operations >= 10`.

## 5. Seguridad

- RLS obligatorio en datos personales.
- Toda política de propiedad se deriva de `auth.uid()` → `players.auth_user_id`.
- `operations`: SELECT para authenticated; sin INSERT/UPDATE/DELETE desde cliente.
- Nunca confiar en `player_id` proporcionado por el navegador sin verificar ownership.
