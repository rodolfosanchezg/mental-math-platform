\set ON_ERROR_STOP on
-- Administrative fixtures are isolated in this transaction and never persisted.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

CREATE FUNCTION pg_temp.expect_rejected(statement text, expected_state text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE statement;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = expected_state THEN RETURN; END IF;
        RAISE;
    END;
    RAISE EXCEPTION 'Expected rejection (%) for: %', expected_state, statement;
END;
$$;

DO $$
DECLARE
    user_id uuid := gen_random_uuid();
    player_uuid uuid;
    operation_uuid uuid;
    session_uuid uuid;
    profile public.players%ROWTYPE;
    game_session public.sessions%ROWTYPE;
    table_count integer;
BEGIN
    SELECT count(*) INTO table_count FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname IN
        ('players', 'operations', 'sessions', 'session_answers', 'level_history')
        AND c.relkind = 'r' AND c.relrowsecurity;
    IF table_count <> 5 THEN RAISE EXCEPTION 'Missing tables or default RLS'; END IF;

    INSERT INTO auth.users (id, email) VALUES
        (user_id, 't02' || substr(replace(user_id::text, '-', ''), 1, 20) || '@mental-math.invalid');
    -- Works before and after T03 automatic provisioning.
    INSERT INTO public.players (id, auth_user_id, username, display_name)
        VALUES (user_id, user_id, 't02' || substr(replace(user_id::text, '-', ''), 1, 20), 'T02 fixture')
        ON CONFLICT (auth_user_id) DO NOTHING;
    SELECT * INTO STRICT profile FROM public.players WHERE auth_user_id=user_id;
    player_uuid := profile.id;
    IF profile.current_addition_level <> 'S1' OR profile.current_multiplication_level <> 'M1'
        OR profile.addition_good_streak <> 0 OR profile.addition_low_streak <> 0
        OR profile.multiplication_good_streak <> 0 OR profile.multiplication_low_streak <> 0
        OR profile.created_at IS NULL THEN
        RAISE EXCEPTION 'Incorrect player defaults';
    END IF;

    PERFORM pg_temp.expect_rejected(format(
        'INSERT INTO public.players(id, auth_user_id, username, display_name) VALUES (%L, %L, %L, %L)',
        user_id, user_id, 'duplicate', 'duplicate'), '23505');
    PERFORM pg_temp.expect_rejected(format(
        'INSERT INTO public.players(id, auth_user_id, username, display_name) SELECT value,value,''orphan'',''orphan'' FROM (SELECT %L::uuid AS value) fixture',
        gen_random_uuid()), '23503');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.players SET username=%L WHERE id=%L', 'Bad_Name', player_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.players SET username=%L WHERE id=%L', 'aa', player_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.players SET username=%L WHERE id=%L', repeat('a', 25), player_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.players SET current_addition_level=%L WHERE id=%L', 'S6', player_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.players SET current_multiplication_level=%L WHERE id=%L', 'M7', player_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.players SET addition_good_streak=-1 WHERE id=%L', player_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.players SET multiplication_low_streak=-1 WHERE id=%L', player_uuid), '23514');

    INSERT INTO public.operations(type, operand_a, operand_b, result, level)
        VALUES ('addition', 7, 8, 15, 'S1') RETURNING id INTO operation_uuid;
    -- Commuted operands and the same operands in different levels remain distinct.
    INSERT INTO public.operations(type, operand_a, operand_b, result, level)
        VALUES ('addition', 8, 7, 15, 'S1'), ('multiplication', 2, 5, 10, 'M1'),
            ('multiplication', 2, 5, 10, 'M2');
    PERFORM pg_temp.expect_rejected(
        'INSERT INTO public.operations(type, operand_a, operand_b, result, level) VALUES (''addition'',7,8,15,''S1'')', '23505');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.operations SET operand_a=0 WHERE id=%L', operation_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.operations SET result=99 WHERE id=%L', operation_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.operations SET level=''M1'' WHERE id=%L', operation_uuid), '23514');
    PERFORM pg_temp.expect_rejected(
        'INSERT INTO public.operations(type, operand_a, operand_b, result, level) VALUES (''multiplication'',1,5,5,''M1'')', '23514');

    INSERT INTO public.sessions(player_id, type, level)
        VALUES (player_uuid, 'addition', 'S1') RETURNING * INTO game_session;
    session_uuid := game_session.id;
    IF game_session.duration_seconds <> 45 OR game_session.total_operations <> 0
        OR game_session.correct_answers <> 0 OR game_session.incorrect_answers <> 0
        OR game_session.accuracy <> 0 OR game_session.completed_at IS NOT NULL THEN
        RAISE EXCEPTION 'Incorrect session defaults';
    END IF;
    UPDATE public.players SET current_addition_level='S2' WHERE id=player_uuid;
    IF (SELECT level FROM public.sessions WHERE id=session_uuid) <> 'S1' THEN
        RAISE EXCEPTION 'Session level did not remain frozen';
    END IF;
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.sessions SET player_id=%L WHERE id=%L', gen_random_uuid(), session_uuid), '23503');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.sessions SET duration_seconds=0 WHERE id=%L', session_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.sessions SET total_operations=1 WHERE id=%L', session_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.sessions SET accuracy=101 WHERE id=%L', session_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.sessions SET completed_at=started_at - interval ''1 second'' WHERE id=%L', session_uuid), '23514');

    INSERT INTO public.session_answers(session_id, operation_id, answer_given, is_correct, response_time_ms)
        VALUES (session_uuid, operation_uuid, NULL, false, 0),
            (session_uuid, operation_uuid, 15, true, 1000);
    PERFORM pg_temp.expect_rejected(format(
        'INSERT INTO public.session_answers(session_id,operation_id,is_correct,response_time_ms) VALUES (%L,%L,true,0)',
        session_uuid, operation_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'INSERT INTO public.session_answers(session_id,operation_id,is_correct,response_time_ms) VALUES (%L,%L,false,-1)',
        session_uuid, operation_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'INSERT INTO public.session_answers(session_id,operation_id,is_correct,response_time_ms) VALUES (%L,%L,false,0)',
        session_uuid, gen_random_uuid()), '23503');

    INSERT INTO public.level_history(player_id, operation_type, previous_level, new_level, reason, session_id)
        VALUES (player_uuid, 'addition', 'S1', 'S2', 'promotion', session_uuid);
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.level_history SET reason=''unknown'' WHERE player_id=%L', player_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.level_history SET new_level=''M2'' WHERE player_id=%L', player_uuid), '23514');
    PERFORM pg_temp.expect_rejected(format(
        'UPDATE public.level_history SET session_id=%L WHERE player_id=%L', gen_random_uuid(), player_uuid), '23503');

    IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public') THEN
        RAISE EXCEPTION 'Access policies belong to T04';
    END IF;
    IF has_table_privilege('anon', 'public.players', 'SELECT')
        OR has_table_privilege('authenticated', 'public.operations', 'SELECT') THEN
        RAISE EXCEPTION 'Intermediate schema exposed to client';
    END IF;
END;
$$;

ROLLBACK;
\echo T02 schema tests PASS - fixtures rolled back
