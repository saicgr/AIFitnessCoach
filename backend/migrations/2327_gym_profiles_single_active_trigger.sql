-- Migration 2327: make "one active gym profile per user" a DB-enforced invariant
-- instead of a constraint every writer has to remember to honour.
--
-- THE INCIDENT (2026-07-23, Sentry PYTHON-FASTAPI-6V)
--   duplicate key value violates unique constraint "idx_gym_profiles_active_per_user"
--   in api.v1.users.profile.update_user
--
-- Two independent code paths mint an is_active=true profile for the same user and
-- NEITHER deactivates an existing one:
--   1. create_gym_profiles_from_onboarding()  (users/onboarding.py) — runs when
--      onboarding_completed flips true.
--   2. create_default_profile_if_needed()     (gym_profiles.py) — runs from
--      GET /gym-profiles/active when the user has no live profile.
-- The app fires both concurrently at the end of onboarding. Whoever loses the race
-- 23505s, so the user keeps the OTHER path's profile — for user 6bd62ca5 that was a
-- placeholder with workout_days=[] and duration 45 while their answers said
-- [0,1,2] and 60. A crash that silently discards the user's onboarding answers.
--
-- The application race is fixed separately (both paths now share one upsert-based
-- builder keyed on (user_id, name)). This trigger is the chokepoint that makes the
-- invariant unbreakable for EVERY writer, present and future: activating a profile
-- deactivates the user's other live profiles in the same statement, so the partial
-- unique index can never be violated by an app write again.

CREATE OR REPLACE FUNCTION gym_profiles_enforce_single_active()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- An archived gym can never be the active one (idx_gym_profiles_active_per_user
    -- already excludes it; this stops a writer from parking is_active=true on a row
    -- that is invisible to every picker).
    IF NEW.archived_at IS NOT NULL THEN
        NEW.is_active := false;
        RETURN NEW;
    END IF;

    -- Activating this profile demotes the user's other live profiles first, so the
    -- partial unique index sees exactly one candidate row.
    UPDATE gym_profiles
       SET is_active = false,
           updated_at = NOW()
     WHERE user_id = NEW.user_id
       AND is_active = true
       AND archived_at IS NULL
       AND id IS DISTINCT FROM NEW.id;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION gym_profiles_enforce_single_active() IS
    'Chokepoint for the one-active-gym-per-user invariant. Any write that sets '
    'is_active=true demotes the user''s other live profiles in the same statement, '
    'so idx_gym_profiles_active_per_user can never be violated by an app write. '
    'Archived rows are forced inactive. Added after the 2026-07-23 onboarding 23505.';

DROP TRIGGER IF EXISTS trg_gym_profiles_single_active ON gym_profiles;
CREATE TRIGGER trg_gym_profiles_single_active
    BEFORE INSERT OR UPDATE ON gym_profiles
    FOR EACH ROW
    WHEN (NEW.is_active IS TRUE)
    EXECUTE FUNCTION gym_profiles_enforce_single_active();

-- The demotion UPDATE above writes is_active=false, which does not satisfy the
-- trigger's WHEN clause, so there is no recursion.
