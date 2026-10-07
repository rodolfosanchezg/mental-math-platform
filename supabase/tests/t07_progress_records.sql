\set ON_ERROR_STOP on
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='30s';

CREATE FUNCTION pg_temp.complete_fixture(player uuid, mode text, total integer, correct integer)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE session_uuid uuid; before_profile public.players%ROWTYPE; after_profile public.players%ROWTYPE;
BEGIN
    SELECT * INTO STRICT before_profile FROM public.players WHERE id=player;
    INSERT INTO public.sessions(player_id,type,level,total_operations,correct_answers,incorrect_answers,accuracy,started_at)
    VALUES(player,mode,CASE WHEN mode='addition' THEN before_profile.current_addition_level ELSE before_profile.current_multiplication_level END,
        total,correct,total-correct,CASE WHEN total=0 THEN 0 ELSE 100.0*correct/total END,clock_timestamp()-interval '1 minute')
    RETURNING id INTO session_uuid;
    UPDATE public.sessions SET completed_at=clock_timestamp() WHERE id=session_uuid;
    SELECT * INTO STRICT after_profile FROM public.players WHERE id=player;
    IF mode='addition' AND (after_profile.current_multiplication_level,after_profile.multiplication_good_streak,after_profile.multiplication_low_streak)
        IS DISTINCT FROM (before_profile.current_multiplication_level,before_profile.multiplication_good_streak,before_profile.multiplication_low_streak) THEN
        RAISE EXCEPTION 'Addition affected multiplication';
    ELSIF mode='multiplication' AND (after_profile.current_addition_level,after_profile.addition_good_streak,after_profile.addition_low_streak)
        IS DISTINCT FROM (before_profile.current_addition_level,before_profile.addition_good_streak,before_profile.addition_low_streak) THEN
        RAISE EXCEPTION 'Multiplication affected addition';
    END IF;
    RETURN session_uuid;
END;
$$;

CREATE FUNCTION pg_temp.assert_progress(player uuid,mode text,level_value text,good integer,low integer)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE p public.players%ROWTYPE;
BEGIN
    SELECT * INTO STRICT p FROM public.players WHERE id=player;
    IF mode='addition' AND (p.current_addition_level,p.addition_good_streak,p.addition_low_streak)
        IS DISTINCT FROM (level_value,good,low) THEN RAISE EXCEPTION 'Addition progression mismatch'; END IF;
    IF mode='multiplication' AND (p.current_multiplication_level,p.multiplication_good_streak,p.multiplication_low_streak)
        IS DISTINCT FROM (level_value,good,low) THEN RAISE EXCEPTION 'Multiplication progression mismatch'; END IF;
END;
$$;

DO $$
DECLARE
    player uuid:=gen_random_uuid();
    record_player uuid:=gen_random_uuid();
    other_player uuid:=gen_random_uuid();
    mode text; prefix text; maximum integer; session_uuid uuid; i integer;
    winning_addition uuid; winning_multiplication uuid;
BEGIN
    INSERT INTO auth.users(id,email) VALUES
        (player,'qp' || substr(replace(player::text,'-',''),1,20) || '@mental-math.invalid'),
        (record_player,'qr' || substr(replace(record_player::text,'-',''),1,20) || '@mental-math.invalid'),
        (other_player,'qo' || substr(replace(other_player::text,'-',''),1,20) || '@mental-math.invalid');
    FOREACH mode IN ARRAY ARRAY['addition','multiplication'] LOOP
        prefix:=CASE WHEN mode='addition' THEN 'S' ELSE 'M' END;
        maximum:=CASE WHEN mode='addition' THEN 5 ELSE 6 END;
        FOR i IN 1..4 LOOP PERFORM pg_temp.complete_fixture(player,mode,15,14); END LOOP;
        PERFORM pg_temp.assert_progress(player,mode,prefix||'1',4,0);
        -- Accurate but fewer than 15 breaks consecutiveness; no promotion.
        PERFORM pg_temp.complete_fixture(player,mode,14,14);
        PERFORM pg_temp.assert_progress(player,mode,prefix||'1',0,0);
        FOR i IN 1..5 LOOP session_uuid:=pg_temp.complete_fixture(player,mode,20,18); END LOOP;
        PERFORM pg_temp.assert_progress(player,mode,prefix||'2',0,0);
        IF NOT EXISTS(SELECT 1 FROM public.level_history WHERE session_id=session_uuid AND reason='promotion'
            AND previous_level=prefix||'1' AND new_level=prefix||'2') THEN RAISE EXCEPTION 'Promotion history missing'; END IF;
        -- UPDATE on an already completed session must not reapply progression.
        UPDATE public.sessions SET completed_at=completed_at WHERE id=session_uuid;
        IF (SELECT count(*) FROM public.level_history WHERE session_id=session_uuid)<>1 THEN RAISE EXCEPTION 'Duplicate progression'; END IF;
        PERFORM pg_temp.complete_fixture(player,mode,20,18);
        PERFORM pg_temp.assert_progress(player,mode,prefix||'2',1,0);
        PERFORM pg_temp.complete_fixture(player,mode,4,3); -- exactly 75%
        PERFORM pg_temp.assert_progress(player,mode,prefix||'2',0,0);
        PERFORM pg_temp.complete_fixture(player,mode,10000,8999); -- 89.99%
        PERFORM pg_temp.assert_progress(player,mode,prefix||'2',0,0);
        PERFORM pg_temp.complete_fixture(player,mode,10000,7499); -- 74.99%
        PERFORM pg_temp.assert_progress(player,mode,prefix||'2',0,1);
        session_uuid:=pg_temp.complete_fixture(player,mode,4,2);
        PERFORM pg_temp.assert_progress(player,mode,prefix||'1',0,0);
        IF NOT EXISTS(SELECT 1 FROM public.level_history WHERE session_id=session_uuid AND reason='demotion') THEN
            RAISE EXCEPTION 'Demotion history missing'; END IF;
        PERFORM pg_temp.complete_fixture(player,mode,4,2);
        PERFORM pg_temp.complete_fixture(player,mode,4,2);
        PERFORM pg_temp.assert_progress(player,mode,prefix||'1',0,2);
        -- No level change at the floor, so R-027 does not reset the low streak.
        PERFORM pg_temp.complete_fixture(player,mode,14,14);
        PERFORM pg_temp.assert_progress(player,mode,prefix||'1',0,0);
        IF mode='addition' THEN UPDATE public.players SET current_addition_level='S5',addition_good_streak=4 WHERE id=player;
        ELSE UPDATE public.players SET current_multiplication_level='M6',multiplication_good_streak=4 WHERE id=player; END IF;
        session_uuid:=pg_temp.complete_fixture(player,mode,20,18);
        PERFORM pg_temp.assert_progress(player,mode,prefix||maximum,0,0);
        IF NOT EXISTS(SELECT 1 FROM public.level_history WHERE session_id=session_uuid AND reason='max_level_reset'
            AND previous_level=new_level) THEN RAISE EXCEPTION 'Max-level reset missing'; END IF;
    END LOOP;

    -- Completed record fixtures bypass progression to isolate ranking tests.
    INSERT INTO public.sessions(player_id,type,level,total_operations,correct_answers,incorrect_answers,accuracy,started_at,completed_at)
    VALUES(record_player,'addition','S1',9,9,0,100,now()-interval '3 minutes',now()),
        (record_player,'addition','S1',10,8,2,80,now()-interval '3 minutes',now()),
        (record_player,'addition','S1',20,18,2,90,now()-interval '3 minutes',now()),
        (other_player,'addition','S1',20,20,0,100,now()-interval '3 minutes',now());
    INSERT INTO public.sessions(player_id,type,level,total_operations,correct_answers,incorrect_answers,accuracy,started_at,completed_at)
    VALUES(record_player,'addition','S1',30,27,3,90,now()-interval '2 minutes',now()) RETURNING id INTO winning_addition;
    INSERT INTO public.sessions(player_id,type,level,total_operations,correct_answers,incorrect_answers,accuracy,started_at,completed_at)
    VALUES(record_player,'addition','S1',30,27,3,90,now()-interval '1 minute',now()),
        (record_player,'multiplication','M1',10,0,10,0,now()-interval '2 minutes',now());
    INSERT INTO public.sessions(player_id,type,level,total_operations,correct_answers,incorrect_answers,accuracy,started_at,completed_at)
    VALUES(record_player,'multiplication','M1',20,0,20,0,now()-interval '2 minutes',now()) RETURNING id INTO winning_multiplication;
    INSERT INTO public.sessions(player_id,type,level,total_operations,correct_answers,incorrect_answers,accuracy)
    VALUES(record_player,'addition','S1',20,20,0,100); -- incomplete excluded
    PERFORM set_config('mmp.t07_record_player',record_player::text,true);
    PERFORM set_config('mmp.t07_addition',winning_addition::text,true);
    PERFORM set_config('mmp.t07_multiplication',winning_multiplication::text,true);
END;
$$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',current_setting('mmp.t07_record_player'),true) IS NOT NULL;
DO $$
BEGIN
    IF (SELECT count(*) FROM public.get_personal_records())<>2
        OR NOT EXISTS(SELECT 1 FROM public.get_personal_records() WHERE id=current_setting('mmp.t07_addition')::uuid)
        OR NOT EXISTS(SELECT 1 FROM public.get_personal_records() WHERE id=current_setting('mmp.t07_multiplication')::uuid) THEN
        RAISE EXCEPTION 'Personal record eligibility/ranking/isolation mismatch';
    END IF;
    IF has_function_privilege('authenticated','public.apply_completed_session_progress()','EXECUTE')
        OR has_function_privilege('anon','public.get_personal_records()','EXECUTE') THEN
        RAISE EXCEPTION 'Insecure function grants'; END IF;
END;
$$;
RESET ROLE;
ROLLBACK;
\echo T07 progression and records tests PASS - fixtures rolled back
