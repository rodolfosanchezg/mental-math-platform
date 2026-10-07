-- T03: only administrative Supabase Auth user creation; public signup stays OFF.
BEGIN;

ALTER TABLE public.players ADD CONSTRAINT players_auth_id_matches CHECK (id = auth_user_id);

CREATE FUNCTION public.provision_player_from_auth()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    technical_username text;
    profile_name text;
BEGIN
    IF NEW.email IS NULL OR NEW.email !~ '^[a-z0-9]{3,24}@mental-math[.]invalid$' THEN
        RAISE EXCEPTION 'Auth user requires an approved technical email' USING ERRCODE = '23514';
    END IF;
    technical_username := split_part(NEW.email, '@', 1);
    profile_name := coalesce(nullif(btrim(NEW.raw_user_meta_data ->> 'display_name'), ''), technical_username);

    INSERT INTO public.players (id, auth_user_id, username, display_name)
    VALUES (NEW.id, NEW.id, technical_username, profile_name)
    ON CONFLICT (auth_user_id) DO UPDATE SET username = EXCLUDED.username;
    RETURN NEW;
END;
$$;

-- Auth triggers can execute this function; API roles cannot call it directly.
REVOKE ALL ON FUNCTION public.provision_player_from_auth() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER provision_player_after_auth_insert
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.provision_player_from_auth();

CREATE TRIGGER sync_player_after_auth_email_update
AFTER UPDATE OF email ON auth.users
FOR EACH ROW WHEN (OLD.email IS DISTINCT FROM NEW.email)
EXECUTE FUNCTION public.provision_player_from_auth();

COMMIT;
