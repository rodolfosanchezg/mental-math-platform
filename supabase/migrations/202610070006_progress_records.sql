-- T07: progress belongs to the transaction that completes a session.
BEGIN;

CREATE FUNCTION public.apply_completed_session_progress()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE
    profile public.players%ROWTYPE;
    previous_level text;
    next_level text;
    level_number integer;
    maximum integer;
    prefix text;
    good integer;
    low integer;
    change_reason text;
BEGIN
    SELECT * INTO STRICT profile FROM public.players WHERE id=NEW.player_id FOR UPDATE;
    IF NEW.type='addition' THEN
        previous_level:=profile.current_addition_level;
        good:=profile.addition_good_streak; low:=profile.addition_low_streak;
        maximum:=5; prefix:='S';
    ELSE
        previous_level:=profile.current_multiplication_level;
        good:=profile.multiplication_good_streak; low:=profile.multiplication_low_streak;
        maximum:=6; prefix:='M';
    END IF;
    level_number:=substring(previous_level FROM 2)::integer;
    next_level:=previous_level;

    -- Integer comparisons preserve the exact 90%/75% boundaries.
    IF NEW.total_operations>=15 AND NEW.correct_answers::bigint*100>=NEW.total_operations::bigint*90 THEN
        good:=good+1; low:=0;
        IF good>=5 THEN
            good:=0; low:=0;
            IF level_number<maximum THEN
                next_level:=prefix || (level_number+1); change_reason:='promotion';
            ELSE
                change_reason:='max_level_reset';
            END IF;
        END IF;
    ELSIF NEW.accuracy<75 THEN
        low:=low+1; good:=0;
        IF low>=2 AND level_number>1 THEN
            next_level:=prefix || (level_number-1); change_reason:='demotion';
            low:=0; good:=0;
        END IF;
    ELSE
        -- A non-good/non-low session breaks both consecutive streaks,
        -- including >=90% with fewer than 15 submitted operations.
        good:=0; low:=0;
    END IF;

    IF NEW.type='addition' THEN
        UPDATE public.players SET current_addition_level=next_level,
            addition_good_streak=good,addition_low_streak=low WHERE id=NEW.player_id;
    ELSE
        UPDATE public.players SET current_multiplication_level=next_level,
            multiplication_good_streak=good,multiplication_low_streak=low WHERE id=NEW.player_id;
    END IF;
    IF change_reason IS NOT NULL THEN
        INSERT INTO public.level_history(player_id,operation_type,previous_level,new_level,reason,session_id,changed_at)
            VALUES(NEW.player_id,NEW.type,previous_level,next_level,change_reason,NEW.id,NEW.completed_at);
    END IF;
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.apply_completed_session_progress() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER apply_progress_after_session_completion
AFTER UPDATE OF completed_at ON public.sessions
FOR EACH ROW WHEN (OLD.completed_at IS NULL AND NEW.completed_at IS NOT NULL)
EXECUTE FUNCTION public.apply_completed_session_progress();

CREATE FUNCTION public.get_personal_records()
RETURNS SETOF public.sessions LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$
    SELECT DISTINCT ON(s.type) s.* FROM public.sessions s
    JOIN public.players p ON p.id=s.player_id
    WHERE p.auth_user_id=auth.uid() AND s.completed_at IS NOT NULL AND s.total_operations>=10
    ORDER BY s.type,s.accuracy DESC,s.correct_answers DESC,s.total_operations DESC,s.started_at ASC,s.id ASC;
$$;
REVOKE ALL ON FUNCTION public.get_personal_records() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_personal_records() TO authenticated;

CREATE INDEX sessions_personal_records_idx
ON public.sessions(player_id,type,accuracy DESC,correct_answers DESC,total_operations DESC,started_at)
WHERE completed_at IS NOT NULL AND total_operations>=10;

COMMIT;
