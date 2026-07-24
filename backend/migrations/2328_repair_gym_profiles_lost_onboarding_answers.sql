-- Migration 2328: repair the gym profiles that lost the user's onboarding answers
--
-- Damage done by the bug fixed in 2327 + the onboarding/default builder race:
-- `create_default_profile_if_needed()` won the race against
-- `create_gym_profiles_from_onboarding()` and wrote a placeholder profile from a
-- users row whose preferences had not been saved yet, then the real builder 23505'd
-- on idx_gym_profiles_active_per_user and its data was thrown away. The survivor has
-- workout_days = [] — so the user's active gym has NO training days, and schedule
-- top-up / pre-generation have nothing to place workouts on.
--
-- An empty workout_days on a LIVE profile is only ever this bug: every writer that
-- has real data writes at least one day, and the app has no UI that saves zero days.
-- Those rows were built from an empty preferences read, so duration and split are
-- resynced from the same source in the same pass.
--
-- Idempotent: rows already carrying days are untouched, and re-running matches nothing.

UPDATE gym_profiles g
   SET workout_days = u.preferences->'workout_days',
       duration_minutes = CASE
           WHEN u.preferences->>'workout_duration' ~ '^[0-9]+$'
               THEN (u.preferences->>'workout_duration')::int
           ELSE g.duration_minutes
       END,
       training_split = COALESCE(g.training_split, u.preferences->>'training_split'),
       updated_at = NOW()
  FROM users u
 WHERE u.id = g.user_id
   AND g.archived_at IS NULL
   AND COALESCE(
         jsonb_array_length(
           CASE WHEN jsonb_typeof(g.workout_days) = 'array' THEN g.workout_days ELSE '[]'::jsonb END
         ), 0) = 0
   AND jsonb_typeof(u.preferences->'workout_days') = 'array'
   AND jsonb_array_length(u.preferences->'workout_days') > 0;
