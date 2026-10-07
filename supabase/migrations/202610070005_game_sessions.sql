-- T06: persist submitted answers only; all ownership/scoring is server-side.
BEGIN;

CREATE FUNCTION public.start_game_session(p_type text)
RETURNS public.sessions LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
    profile public.players%ROWTYPE;
    created_session public.sessions%ROWTYPE;
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
    IF p_type IS NULL OR p_type NOT IN ('addition','multiplication') THEN
        RAISE EXCEPTION 'Invalid operation type' USING ERRCODE='22023';
    END IF;
    SELECT * INTO profile FROM public.players WHERE auth_user_id=auth.uid() FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Profile unavailable' USING ERRCODE='42501'; END IF;
    INSERT INTO public.sessions(player_id,type,level,duration_seconds,started_at)
    VALUES (profile.id,p_type,
        CASE WHEN p_type='addition' THEN profile.current_addition_level ELSE profile.current_multiplication_level END,
        45,clock_timestamp()) RETURNING * INTO created_session;
    RETURN created_session;
END;
$$;

CREATE FUNCTION public.record_game_answer(
    p_session_id uuid, p_operation_id uuid, p_answer_given integer,
    p_response_time_ms integer, p_elapsed_ms integer, p_submission_id uuid DEFAULT gen_random_uuid())
RETURNS public.session_answers LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
    game_session public.sessions%ROWTYPE;
    exercise public.operations%ROWTYPE;
    submitted public.session_answers%ROWTYPE;
    previous_answer_at timestamptz;
    effective_answer_at timestamptz;
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
    SELECT s.* INTO game_session FROM public.sessions s JOIN public.players p ON p.id=s.player_id
        WHERE s.id=p_session_id AND p.auth_user_id=auth.uid() FOR UPDATE OF s;
    IF NOT FOUND THEN RAISE EXCEPTION 'Session unavailable' USING ERRCODE='42501'; END IF;
    IF p_submission_id IS NULL OR p_response_time_ms IS NULL OR p_elapsed_ms IS NULL
        OR p_response_time_ms < 0 OR p_response_time_ms > p_elapsed_ms
        OR p_elapsed_ms < 0 OR p_elapsed_ms >= game_session.duration_seconds * 1000 THEN
        RAISE EXCEPTION 'Invalid submission timing or identity' USING ERRCODE='22023';
    END IF;
    effective_answer_at := game_session.started_at + p_elapsed_ms * interval '1 millisecond';

    -- A client-provided UUID makes retries idempotent, including after close.
    SELECT * INTO submitted FROM public.session_answers WHERE id=p_submission_id;
    IF FOUND THEN
        IF submitted.session_id=p_session_id AND submitted.operation_id=p_operation_id
            AND submitted.answer_given IS NOT DISTINCT FROM p_answer_given
            AND submitted.response_time_ms=p_response_time_ms AND submitted.answered_at=effective_answer_at THEN
            RETURN submitted;
        END IF;
        RAISE EXCEPTION 'Submission identity unavailable' USING ERRCODE='22023';
    END IF;
    IF game_session.completed_at IS NOT NULL THEN
        RAISE EXCEPTION 'Session already completed' USING ERRCODE='22023';
    END IF;
    SELECT * INTO exercise FROM public.operations
        WHERE id=p_operation_id AND active AND type=game_session.type AND level=game_session.level;
    IF NOT FOUND THEN RAISE EXCEPTION 'Operation unavailable for session' USING ERRCODE='22023'; END IF;
    SELECT max(answered_at) INTO previous_answer_at FROM public.session_answers WHERE session_id=p_session_id;
    IF effective_answer_at < coalesce(previous_answer_at,game_session.started_at)
        OR p_response_time_ms * interval '1 millisecond' >
            effective_answer_at - coalesce(previous_answer_at,game_session.started_at) THEN
        RAISE EXCEPTION 'Submission timing out of order' USING ERRCODE='22023';
    END IF;
    INSERT INTO public.session_answers(id,session_id,operation_id,answer_given,is_correct,response_time_ms,answered_at)
    VALUES (p_submission_id,p_session_id,p_operation_id,p_answer_given,
        coalesce(p_answer_given=exercise.result,false),p_response_time_ms,effective_answer_at)
    RETURNING * INTO submitted;
    RETURN submitted;
END;
$$;

CREATE FUNCTION public.close_game_session(p_session_id uuid)
RETURNS public.sessions LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
    game_session public.sessions%ROWTYPE;
    total integer;
    correct integer;
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
    SELECT s.* INTO game_session FROM public.sessions s JOIN public.players p ON p.id=s.player_id
        WHERE s.id=p_session_id AND p.auth_user_id=auth.uid() FOR UPDATE OF s;
    IF NOT FOUND THEN RAISE EXCEPTION 'Session unavailable' USING ERRCODE='42501'; END IF;
    IF game_session.completed_at IS NOT NULL THEN RETURN game_session; END IF;
    IF clock_timestamp() < game_session.started_at + game_session.duration_seconds * interval '1 second' THEN
        RAISE EXCEPTION 'Session time remains' USING ERRCODE='22023';
    END IF;
    SELECT count(*),count(*) FILTER (WHERE is_correct) INTO total,correct
        FROM public.session_answers WHERE session_id=p_session_id;
    UPDATE public.sessions SET total_operations=total,correct_answers=correct,incorrect_answers=total-correct,
        accuracy=CASE WHEN total=0 THEN 0 ELSE 100.0*correct/total END,
        completed_at=clock_timestamp()
        WHERE id=p_session_id RETURNING * INTO game_session;
    RETURN game_session;
END;
$$;

REVOKE ALL ON FUNCTION public.start_game_session(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.record_game_answer(uuid,uuid,integer,integer,integer,uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.close_game_session(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.start_game_session(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_game_answer(uuid,uuid,integer,integer,integer,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.close_game_session(uuid) TO authenticated;

COMMIT;
