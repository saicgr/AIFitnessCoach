-- Migration 254: Preserve valuable data when users delete their accounts
-- Instead of CASCADE-deleting everything, re-assign food logs, workouts,
-- and feedback to a sentinel "deleted_user" so the data remains available
-- for analytics and future improvements.
--
-- Approach:
--   1. Create a sentinel user with a well-known UUID
--   2. BEFORE DELETE trigger on public.users re-assigns rows in key tables
--   3. All other tables still CASCADE-delete normally (privacy cleanup)

-- ============================================================================
-- 1. Sentinel user: a permanent row that "owns" orphaned data
-- ============================================================================
DO $$
BEGIN
    -- Use a well-known UUID for the deleted/anonymous user
    INSERT INTO public.users (id, username, name, onboarding_completed, fitness_level, goals, equipment)
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        '_deleted_user_',
        'Deleted User',
        TRUE,
        'N/A',
        'N/A',
        'N/A'
    )
    ON CONFLICT (id) DO NOTHING;
END;
$$;

-- ============================================================================
-- 2. BEFORE DELETE trigger: re-assign valuable data to sentinel user
-- ============================================================================
CREATE OR REPLACE FUNCTION preserve_user_data_before_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    sentinel_id UUID := '00000000-0000-0000-0000-000000000000';
BEGIN
    -- Skip if we're deleting the sentinel user itself
    IF OLD.id = sentinel_id THEN
        RETURN OLD;
    END IF;

    -- ── Food data ──────────────────────────────────────────────
    -- Saved foods (recipes / favorites)
    UPDATE saved_foods
       SET user_id = sentinel_id
     WHERE user_id = OLD.id;

    -- Daily food logs
    UPDATE food_logs
       SET user_id = sentinel_id
     WHERE user_id = OLD.id;

    -- ── Workout data ───────────────────────────────────────────
    -- AI-generated workout plans
    UPDATE generated_workouts
       SET user_id = sentinel_id
     WHERE user_id = OLD.id;

    -- Workout instances
    UPDATE workouts
       SET user_id = sentinel_id
     WHERE user_id = OLD.id;

    -- Workout completion logs (sets, reps, weights)
    UPDATE workout_logs
       SET user_id = sentinel_id
     WHERE user_id = OLD.id;

    -- Detailed performance logs (per-set tracking)
    UPDATE performance_logs
       SET user_id = sentinel_id
     WHERE user_id = OLD.id;

    -- ── Feedback / reviews ─────────────────────────────────────
    -- Post-workout feedback (difficulty, enjoyment)
    UPDATE workout_feedback
       SET user_id = sentinel_id
     WHERE user_id = OLD.id;

    -- Subjective feedback (energy, soreness, mood)
    UPDATE workout_subjective_feedback
       SET user_id = sentinel_id
     WHERE user_id = OLD.id;

    -- Exercise-level feedback
    UPDATE exercise_feedback
       SET user_id = sentinel_id
     WHERE user_id = OLD.id;

    -- Allow the DELETE to proceed; CASCADE will clean up everything else
    RETURN OLD;
END;
$$;

-- The trigger MUST fire BEFORE DELETE so the re-assignment happens
-- before FK cascades wipe the rows
CREATE OR REPLACE TRIGGER trigger_preserve_user_data
    BEFORE DELETE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION preserve_user_data_before_delete();

-- ============================================================================
-- 3. Protect the sentinel user from accidental deletion
-- ============================================================================
CREATE OR REPLACE FUNCTION prevent_sentinel_user_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.id = '00000000-0000-0000-0000-000000000000' THEN
        RAISE EXCEPTION 'Cannot delete the sentinel deleted_user account';
    END IF;
    RETURN OLD;
END;
$$;

-- This trigger fires BEFORE the preservation trigger (alphabetical order)
-- so it blocks deletion of the sentinel itself
CREATE OR REPLACE TRIGGER trigger_aa_prevent_sentinel_delete
    BEFORE DELETE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION prevent_sentinel_user_delete();

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
