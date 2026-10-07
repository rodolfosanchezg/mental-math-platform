\set ON_ERROR_STOP on
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='30s';

CREATE FUNCTION pg_temp.expect_error(statement text, expected text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN EXECUTE statement;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE=expected THEN RETURN; END IF;
        RAISE;
    END;
    RAISE EXCEPTION 'Expected rejection (%) for: %',expected,statement;
END;
$$;

DO $$
DECLARE a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid();
BEGIN
    INSERT INTO auth.users(id,email) VALUES
        (a,'qa' || substr(replace(a::text,'-',''),1,20) || '@mental-math.invalid'),
        (b,'qb' || substr(replace(b::text,'-',''),1,20) || '@mental-math.invalid');
    PERFORM set_config('mmp.t06_a',a::text,true);
    PERFORM set_config('mmp.t06_b',b::text,true);
END;
$$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',current_setting('mmp.t06_a'),true) IS NOT NULL;
DO $$
DECLARE s public.sessions%ROWTYPE; m public.sessions%ROWTYPE;
BEGIN
    s:=public.start_game_session('addition'); m:=public.start_game_session('multiplication');
    IF s.player_id<>auth.uid() OR s.level<>'S1' OR s.duration_seconds<>45 OR s.completed_at IS NOT NULL
        OR m.level<>'M1' THEN RAISE EXCEPTION 'Incorrect server session snapshot'; END IF;
    PERFORM set_config('mmp.t06_session',s.id::text,true);
    PERFORM set_config('mmp.t06_empty',m.id::text,true);
    PERFORM pg_temp.expect_error(format('SELECT public.close_game_session(%L)',s.id),'22023');
    PERFORM pg_temp.expect_error('SELECT public.start_game_session(''division'')','22023');
    PERFORM pg_temp.expect_error('SELECT public.start_game_session(NULL)','22023');
END;
$$;
RESET ROLE;
-- Move only the new fixture sessions back to exercise expiry without sleeping.
UPDATE public.sessions SET started_at=started_at-interval '46 seconds'
    WHERE id IN (current_setting('mmp.t06_session')::uuid,current_setting('mmp.t06_empty')::uuid);

SET LOCAL ROLE authenticated;
DO $$
DECLARE
    s uuid:=current_setting('mmp.t06_session')::uuid;
    op uuid;
    wrong_op uuid;
    submission uuid:=gen_random_uuid();
    answer public.session_answers%ROWTYPE;
    closed public.sessions%ROWTYPE;
    closed_again public.sessions%ROWTYPE;
    empty_session public.sessions%ROWTYPE;
BEGIN
    SELECT id INTO STRICT op FROM public.operations WHERE type='addition' AND level='S1' AND operand_a=7 AND operand_b=8;
    SELECT id INTO STRICT wrong_op FROM public.operations WHERE type='multiplication' AND level='M1' AND operand_a=2 AND operand_b=5;
    answer:=public.record_game_answer(s,op,15,100,100,submission);
    IF NOT answer.is_correct OR answer.response_time_ms<>100 THEN RAISE EXCEPTION 'Correct answer not scored'; END IF;
    PERFORM public.record_game_answer(s,op,15,100,100,submission);
    IF (SELECT count(*) FROM public.session_answers WHERE session_id=s)<>1 THEN RAISE EXCEPTION 'Retry duplicated answer'; END IF;
    PERFORM pg_temp.expect_error(format('SELECT public.record_game_answer(%L,%L,99,100,100,%L)',s,op,submission),'22023');
    answer:=public.record_game_answer(s,op,NULL,100,200);
    IF answer.is_correct OR answer.answer_given IS NOT NULL THEN RAISE EXCEPTION 'Empty answer not incorrect/null'; END IF;
    answer:=public.record_game_answer(s,op,99,100,300);
    IF answer.is_correct THEN RAISE EXCEPTION 'Incorrect answer trusted'; END IF;
    PERFORM pg_temp.expect_error(format('SELECT public.record_game_answer(%L,%L,15,-1,400)',s,op),'22023');
    PERFORM pg_temp.expect_error(format('SELECT public.record_game_answer(%L,%L,15,0,45000)',s,op),'22023');
    PERFORM pg_temp.expect_error(format('SELECT public.record_game_answer(%L,%L,15,0,100)',s,op),'22023');
    PERFORM pg_temp.expect_error(format('SELECT public.record_game_answer(%L,%L,15,999,400)',s,op),'22023');
    PERFORM pg_temp.expect_error(format('SELECT public.record_game_answer(%L,%L,15,0,400)',s,wrong_op),'22023');
    PERFORM pg_temp.expect_error(format('SELECT public.record_game_answer(%L,%L,15,0,400)',s,gen_random_uuid()),'22023');
    closed:=public.close_game_session(s);
    IF closed.total_operations<>3 OR closed.correct_answers<>1 OR closed.incorrect_answers<>2
        OR abs(closed.accuracy-100.0/3)>0.000001 OR closed.completed_at IS NULL THEN
        RAISE EXCEPTION 'Incorrect session totals/accuracy'; END IF;
    closed_again:=public.close_game_session(s);
    IF closed_again IS DISTINCT FROM closed THEN RAISE EXCEPTION 'Close is not idempotent'; END IF;
    PERFORM public.record_game_answer(s,op,15,100,100,submission);
    PERFORM pg_temp.expect_error(format('SELECT public.record_game_answer(%L,%L,15,0,400)',s,op),'22023');
    empty_session:=public.close_game_session(current_setting('mmp.t06_empty')::uuid);
    IF empty_session.total_operations<>0 OR empty_session.accuracy<>0 THEN RAISE EXCEPTION 'Empty session division by zero'; END IF;
    IF (SELECT current_addition_level FROM public.players WHERE id=auth.uid())<>'S1' THEN
        RAISE EXCEPTION 'T06 changed progression'; END IF;
    PERFORM set_config('mmp.t06_op',op::text,true);
END;
$$;

SELECT set_config('request.jwt.claim.sub',current_setting('mmp.t06_b'),true) IS NOT NULL;
DO $$
DECLARE s uuid:=current_setting('mmp.t06_session')::uuid; op uuid:=current_setting('mmp.t06_op')::uuid;
BEGIN
    PERFORM pg_temp.expect_error(format('SELECT public.close_game_session(%L)',s),'42501');
    PERFORM pg_temp.expect_error(format('SELECT public.record_game_answer(%L,%L,15,0,400)',s,op),'42501');
    IF EXISTS(SELECT 1 FROM public.sessions WHERE id=s) THEN RAISE EXCEPTION 'Cross session visible'; END IF;
END;
$$;
SELECT set_config('request.jwt.claim.sub','',true) IS NOT NULL;
SELECT pg_temp.expect_error('SELECT public.start_game_session(''addition'')','42501');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.expect_error('SELECT public.start_game_session(''addition'')','42501');
RESET ROLE;
ROLLBACK;
\echo T06 session RPC tests PASS - fixtures rolled back
