\set ON_ERROR_STOP on
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

DO $$
DECLARE
    user_uuid uuid := gen_random_uuid();
    username_value text := 't03' || substr(replace(user_uuid::text, '-', ''), 1, 20);
    profile public.players%ROWTYPE;
    invalid_email text;
    invalid_uuid uuid;
BEGIN
    INSERT INTO auth.users (id, email, raw_user_meta_data)
        VALUES (user_uuid, username_value || '@mental-math.invalid',
            '{"display_name":"QA T03", "current_addition_level":"S5", "addition_good_streak":99}'::jsonb);
    SELECT * INTO STRICT profile FROM public.players WHERE auth_user_id=user_uuid;
    IF profile.id <> user_uuid OR profile.username <> username_value OR profile.display_name <> 'QA T03'
        OR profile.current_addition_level <> 'S1' OR profile.current_multiplication_level <> 'M1'
        OR profile.addition_good_streak <> 0 OR profile.addition_low_streak <> 0
        OR profile.multiplication_good_streak <> 0 OR profile.multiplication_low_streak <> 0 THEN
        RAISE EXCEPTION 'Profile identity/defaults are incorrect or trust user progression metadata';
    END IF;

    UPDATE auth.users SET email='x' || username_value || '@mental-math.invalid' WHERE id=user_uuid;
    IF (SELECT username FROM public.players WHERE id=user_uuid) <> 'x' || username_value THEN
        RAISE EXCEPTION 'Email rename did not synchronize username';
    END IF;
    IF (SELECT count(*) FROM public.players WHERE auth_user_id=user_uuid) <> 1 THEN
        RAISE EXCEPTION 'Profile duplication';
    END IF;
    BEGIN
        UPDATE public.players SET id=gen_random_uuid() WHERE id=user_uuid;
        RAISE EXCEPTION 'Mismatched UUID allowed';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    FOREACH invalid_email IN ARRAY ARRAY['aa@mental-math.invalid', repeat('a',25) || '@mental-math.invalid',
        'ABC@mental-math.invalid', 'bad_name@mental-math.invalid', 'valid@example.com', '', NULL]
    LOOP
        invalid_uuid := gen_random_uuid();
        BEGIN
            INSERT INTO auth.users(id,email) VALUES (invalid_uuid,invalid_email);
            RAISE EXCEPTION 'Invalid technical email allowed';
        EXCEPTION WHEN check_violation THEN NULL;
        END;
        IF EXISTS (SELECT 1 FROM auth.users WHERE id=invalid_uuid)
            OR EXISTS (SELECT 1 FROM public.players WHERE auth_user_id=invalid_uuid) THEN
            RAISE EXCEPTION 'Failed provisioning was not atomic';
        END IF;
    END LOOP;

    invalid_uuid := gen_random_uuid();
    INSERT INTO auth.users(id,email,raw_user_meta_data)
        VALUES (invalid_uuid, 'z' || username_value || '@mental-math.invalid', '{"display_name":"   "}');
    IF (SELECT display_name FROM public.players WHERE id=invalid_uuid) <> 'z' || username_value THEN
        RAISE EXCEPTION 'Missing display name fallback';
    END IF;
    IF has_function_privilege('anon','public.provision_player_from_auth()','EXECUTE')
        OR has_function_privilege('authenticated','public.provision_player_from_auth()','EXECUTE') THEN
        RAISE EXCEPTION 'Trigger function exposed to client';
    END IF;
END;
$$;

ROLLBACK;
\echo T03 Auth/profile tests PASS - fixtures rolled back
