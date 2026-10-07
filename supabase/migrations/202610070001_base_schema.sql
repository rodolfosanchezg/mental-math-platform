-- T02: base schema only. Profile provisioning, access policies and RPCs follow.
BEGIN;

CREATE TABLE public.players (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id uuid UNIQUE NOT NULL REFERENCES auth.users(id),
    username text UNIQUE NOT NULL CHECK (username ~ '^[a-z0-9]{3,24}$'),
    display_name text NOT NULL CHECK (length(btrim(display_name)) > 0),
    current_addition_level text NOT NULL DEFAULT 'S1'
        CHECK (current_addition_level IN ('S1', 'S2', 'S3', 'S4', 'S5')),
    addition_good_streak integer NOT NULL DEFAULT 0 CHECK (addition_good_streak >= 0),
    addition_low_streak integer NOT NULL DEFAULT 0 CHECK (addition_low_streak >= 0),
    current_multiplication_level text NOT NULL DEFAULT 'M1'
        CHECK (current_multiplication_level IN ('M1', 'M2', 'M3', 'M4', 'M5', 'M6')),
    multiplication_good_streak integer NOT NULL DEFAULT 0 CHECK (multiplication_good_streak >= 0),
    multiplication_low_streak integer NOT NULL DEFAULT 0 CHECK (multiplication_low_streak >= 0),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.operations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type text NOT NULL CHECK (type IN ('addition', 'multiplication')),
    operand_a integer NOT NULL CHECK (operand_a > 0),
    operand_b integer NOT NULL CHECK (operand_b > 0),
    result integer NOT NULL,
    level text NOT NULL,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (type, operand_a, operand_b, level),
    CHECK ((type = 'addition' AND level IN ('S1', 'S2', 'S3', 'S4', 'S5'))
        OR (type = 'multiplication' AND level IN ('M1', 'M2', 'M3', 'M4', 'M5', 'M6'))),
    CHECK ((type = 'addition' AND result::bigint = operand_a::bigint + operand_b::bigint)
        OR (type = 'multiplication' AND operand_a >= 2 AND operand_b >= 2
            AND result::bigint = operand_a::bigint * operand_b::bigint))
);

CREATE TABLE public.sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id uuid NOT NULL REFERENCES public.players(id),
    type text NOT NULL CHECK (type IN ('addition', 'multiplication')),
    level text NOT NULL,
    duration_seconds integer NOT NULL DEFAULT 45 CHECK (duration_seconds > 0),
    total_operations integer NOT NULL DEFAULT 0 CHECK (total_operations >= 0),
    correct_answers integer NOT NULL DEFAULT 0 CHECK (correct_answers >= 0),
    incorrect_answers integer NOT NULL DEFAULT 0 CHECK (incorrect_answers >= 0),
    accuracy numeric NOT NULL DEFAULT 0 CHECK (accuracy >= 0 AND accuracy <= 100),
    started_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz,
    CHECK ((type = 'addition' AND level IN ('S1', 'S2', 'S3', 'S4', 'S5'))
        OR (type = 'multiplication' AND level IN ('M1', 'M2', 'M3', 'M4', 'M5', 'M6'))),
    CHECK (total_operations::bigint = correct_answers::bigint + incorrect_answers::bigint),
    CHECK (completed_at IS NULL OR completed_at >= started_at)
);

CREATE TABLE public.session_answers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL REFERENCES public.sessions(id),
    operation_id uuid NOT NULL REFERENCES public.operations(id),
    answer_given integer,
    is_correct boolean NOT NULL,
    response_time_ms integer NOT NULL CHECK (response_time_ms >= 0),
    answered_at timestamptz NOT NULL DEFAULT now(),
    CHECK (answer_given IS NOT NULL OR NOT is_correct)
);

CREATE TABLE public.level_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id uuid NOT NULL REFERENCES public.players(id),
    operation_type text NOT NULL CHECK (operation_type IN ('addition', 'multiplication')),
    previous_level text NOT NULL,
    new_level text NOT NULL,
    reason text NOT NULL CHECK (reason IN ('promotion', 'demotion', 'max_level_reset')),
    session_id uuid NOT NULL REFERENCES public.sessions(id),
    changed_at timestamptz NOT NULL DEFAULT now(),
    CHECK ((operation_type = 'addition'
            AND previous_level IN ('S1', 'S2', 'S3', 'S4', 'S5')
            AND new_level IN ('S1', 'S2', 'S3', 'S4', 'S5'))
        OR (operation_type = 'multiplication'
            AND previous_level IN ('M1', 'M2', 'M3', 'M4', 'M5', 'M6')
            AND new_level IN ('M1', 'M2', 'M3', 'M4', 'M5', 'M6')))
);

CREATE INDEX operations_active_level_idx ON public.operations (type, level) WHERE active;
CREATE INDEX sessions_player_mode_idx ON public.sessions (player_id, type, started_at DESC);
CREATE INDEX session_answers_session_idx ON public.session_answers (session_id);
CREATE INDEX session_answers_operation_idx ON public.session_answers (operation_id);
CREATE INDEX level_history_player_idx ON public.level_history (player_id, changed_at DESC);
CREATE INDEX level_history_session_idx ON public.level_history (session_id);

-- Default Supabase grants must not expose an intermediate schema before T04.
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.level_history ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.players, public.operations, public.sessions,
    public.session_answers, public.level_history FROM anon, authenticated;

COMMIT;
