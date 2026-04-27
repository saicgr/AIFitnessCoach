-- Migration 2035: Backfill empty gym_profiles.workout_days from user prefs
--
-- Context: Until this release, the Add Gym sheet did not pass workout_days
-- when creating a profile, so newly-created gym profiles ended up with the
-- DEFAULT '[]'::jsonb value. The /today endpoint reads the user's GLOBAL
-- preferences.workout_days as a fallback today, but this is changing to
-- prefer per-profile workout_days. Without this backfill, switching to a
-- profile that was created via the old client would silently disable
-- workout-day scheduling (no dots, no auto-generation).
--
-- Fix: For any gym_profile with an empty workout_days array, copy the
-- owning user's preferences->'workout_days' (if any) into the profile.
-- Idempotent — re-running this is a no-op once profiles are populated.

UPDATE gym_profiles gp
SET
    workout_days = COALESCE(u.preferences -> 'workout_days', '[]'::jsonb),
    updated_at = NOW()
FROM users u
WHERE
    gp.user_id = u.id
    AND (gp.workout_days IS NULL OR jsonb_array_length(gp.workout_days) = 0)
    AND u.preferences -> 'workout_days' IS NOT NULL
    AND jsonb_typeof(u.preferences -> 'workout_days') = 'array'
    AND jsonb_array_length(u.preferences -> 'workout_days') > 0;

-- Report how many rows were touched (for migration logs).
DO $$
DECLARE
    backfilled_count INT;
BEGIN
    SELECT COUNT(*) INTO backfilled_count
    FROM gym_profiles gp
    JOIN users u ON gp.user_id = u.id
    WHERE
        gp.workout_days IS NOT NULL
        AND jsonb_array_length(gp.workout_days) > 0
        AND gp.workout_days = COALESCE(u.preferences -> 'workout_days', '[]'::jsonb);
    RAISE NOTICE '[2035] gym_profiles with workout_days now matching user prefs: %', backfilled_count;
END $$;
