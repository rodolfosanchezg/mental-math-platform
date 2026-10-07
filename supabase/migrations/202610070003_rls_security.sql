-- T04: client reads use auth.uid(); writes remain reserved for verified RPCs.
BEGIN;

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.players, public.operations, public.sessions,
    public.session_answers, public.level_history TO authenticated;

CREATE POLICY players_read_own ON public.players
FOR SELECT TO authenticated
USING (auth_user_id = (SELECT auth.uid()));

CREATE POLICY operations_read_authenticated ON public.operations
FOR SELECT TO authenticated USING (true);

CREATE POLICY sessions_read_own ON public.sessions
FOR SELECT TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.players p
    WHERE p.id = sessions.player_id AND p.auth_user_id = (SELECT auth.uid())
));

CREATE POLICY session_answers_read_own ON public.session_answers
FOR SELECT TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.sessions s
    JOIN public.players p ON p.id = s.player_id
    WHERE s.id = session_answers.session_id AND p.auth_user_id = (SELECT auth.uid())
));

CREATE POLICY level_history_read_own ON public.level_history
FOR SELECT TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.players p
    WHERE p.id = level_history.player_id AND p.auth_user_id = (SELECT auth.uid())
));

-- No INSERT/UPDATE/DELETE grants or policies for API roles. T06 supplies RPCs
-- that verify ownership and keep persistence/progression transactional.
COMMIT;
