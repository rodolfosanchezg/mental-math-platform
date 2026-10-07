\set ON_ERROR_STOP on
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

CREATE FUNCTION pg_temp.expect_denied(statement text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE statement;
    EXCEPTION WHEN insufficient_privilege THEN RETURN;
    END;
    RAISE EXCEPTION 'Expected permission denial for: %', statement;
END;
$$;

DO $$
DECLARE
    a uuid := gen_random_uuid();
    b uuid := gen_random_uuid();
    op uuid;
    sa uuid;
    sb uuid;
BEGIN
    INSERT INTO auth.users(id,email) VALUES
        (a,'qa' || substr(replace(a::text,'-',''),1,20) || '@mental-math.invalid'),
        (b,'qb' || substr(replace(b::text,'-',''),1,20) || '@mental-math.invalid');
    INSERT INTO public.operations(type,operand_a,operand_b,result,level)
        VALUES ('addition',7,8,15,'S1') ON CONFLICT (type,operand_a,operand_b,level) DO NOTHING;
    SELECT id INTO STRICT op FROM public.operations
        WHERE type='addition' AND operand_a=7 AND operand_b=8 AND level='S1';
    INSERT INTO public.sessions(player_id,type,level) VALUES (a,'addition','S1') RETURNING id INTO sa;
    INSERT INTO public.sessions(player_id,type,level) VALUES (b,'addition','S1') RETURNING id INTO sb;
    INSERT INTO public.session_answers(session_id,operation_id,answer_given,is_correct,response_time_ms)
        VALUES (sa,op,15,true,100), (sb,op,NULL,false,200);
    INSERT INTO public.level_history(player_id,operation_type,previous_level,new_level,reason,session_id)
        VALUES (a,'addition','S1','S2','promotion',sa), (b,'addition','S1','S2','promotion',sb);
    PERFORM set_config('mmp.qa_a',a::text,true);
    PERFORM set_config('mmp.qa_b',b::text,true);
    PERFORM set_config('mmp.qa_sa',sa::text,true);
    PERFORM set_config('mmp.qa_sb',sb::text,true);
    PERFORM set_config('mmp.qa_op',op::text,true);
END;
$$;

CREATE FUNCTION pg_temp.assert_player_access(own_id uuid, other_id uuid, own_session uuid, other_session uuid)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    table_name text;
    op uuid := current_setting('mmp.qa_op')::uuid;
BEGIN
    IF auth.uid() <> own_id THEN RAISE EXCEPTION 'Test JWT identity mismatch'; END IF;
    IF (SELECT count(*) FROM public.players WHERE id=own_id) <> 1
        OR EXISTS(SELECT 1 FROM public.players WHERE id=other_id)
        OR (SELECT count(*) FROM public.sessions WHERE id=own_session) <> 1
        OR EXISTS(SELECT 1 FROM public.sessions WHERE id=other_session)
        OR (SELECT count(*) FROM public.session_answers WHERE session_id=own_session) <> 1
        OR EXISTS(SELECT 1 FROM public.session_answers WHERE session_id=other_session)
        OR (SELECT count(*) FROM public.level_history WHERE player_id=own_id) <> 1
        OR EXISTS(SELECT 1 FROM public.level_history WHERE player_id=other_id)
        OR NOT EXISTS(SELECT 1 FROM public.operations WHERE id=op) THEN
        RAISE EXCEPTION 'Ownership isolation or authenticated bank access failed';
    END IF;

    FOREACH table_name IN ARRAY ARRAY['players','operations','sessions','session_answers','level_history'] LOOP
        PERFORM pg_temp.expect_denied(format('UPDATE public.%I SET id=id WHERE false',table_name));
        PERFORM pg_temp.expect_denied(format('DELETE FROM public.%I WHERE false',table_name));
        PERFORM pg_temp.expect_denied(format('INSERT INTO public.%I DEFAULT VALUES',table_name));
    END LOOP;
    PERFORM pg_temp.expect_denied(format(
        'INSERT INTO public.sessions(player_id,type,level) VALUES (%L,''addition'',''S1'')',other_id));
    PERFORM pg_temp.expect_denied(format(
        'INSERT INTO public.session_answers(session_id,operation_id,is_correct,response_time_ms) VALUES (%L,%L,false,0)',
        other_session,op));
    PERFORM pg_temp.expect_denied(format('UPDATE public.players SET current_addition_level=''S5'' WHERE id=%L',other_id));
END;
$$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',current_setting('mmp.qa_a'),true) IS NOT NULL AS identity_set;
SELECT pg_temp.assert_player_access(current_setting('mmp.qa_a')::uuid,current_setting('mmp.qa_b')::uuid,
    current_setting('mmp.qa_sa')::uuid,current_setting('mmp.qa_sb')::uuid);
SELECT set_config('request.jwt.claim.sub',current_setting('mmp.qa_b'),true) IS NOT NULL AS identity_set;
SELECT pg_temp.assert_player_access(current_setting('mmp.qa_b')::uuid,current_setting('mmp.qa_a')::uuid,
    current_setting('mmp.qa_sb')::uuid,current_setting('mmp.qa_sa')::uuid);

RESET ROLE;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub','',true) IS NOT NULL AS anonymous_identity_set;
DO $$
DECLARE table_name text;
BEGIN
    IF auth.uid() IS NOT NULL THEN RAISE EXCEPTION 'Anonymous identity not cleared'; END IF;
    FOREACH table_name IN ARRAY ARRAY['players','operations','sessions','session_answers','level_history'] LOOP
        PERFORM pg_temp.expect_denied(format('SELECT * FROM public.%I',table_name));
        PERFORM pg_temp.expect_denied(format('INSERT INTO public.%I DEFAULT VALUES',table_name));
        PERFORM pg_temp.expect_denied(format('UPDATE public.%I SET id=id WHERE false',table_name));
        PERFORM pg_temp.expect_denied(format('DELETE FROM public.%I WHERE false',table_name));
    END LOOP;
END;
$$;
RESET ROLE;
ROLLBACK;
\echo T04 RLS tests PASS - A/B/anonymous fixtures rolled back
