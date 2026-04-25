-- Migration: Seed workout-time + consistency-workouts achievement tiers +
-- add trophy-trigger helper functions.
-- Created: 2026-04-24
-- Purpose:
--   trophy_triggers.py fires FK errors on every workout completion because
--   10 achievement IDs (5 consistency_workouts_* tiers + 5 time_workout_*
--   tiers) are hardcoded there but were never seeded into achievement_types.
--   Two helper Postgres RPCs (`count_muscle_group_exercises`,
--   `get_user_volume_stats`) are also referenced but do not exist — the
--   trophy-triggers caller has a fallback that queries a non-existent
--   `workout_sets` table, so the errors compound silently.
--
--   This migration:
--     1. Inserts the 10 missing achievement_types rows (idempotent via ON
--        CONFLICT DO NOTHING).
--     2. Creates `count_muscle_group_exercises(user, muscle)` — counts
--        distinct exercises the user has logged whose primary_muscle
--        matches the given group.
--     3. Creates `get_user_volume_stats(user)` — returns total sets, reps,
--        and weight lifted (lbs, to match the trophy thresholds) from
--        performance_logs. weight_kg is converted to lbs inside the fn so
--        callers can use the result directly.

-- =====================================================================
-- 1. Seed achievement_types rows
-- =====================================================================

INSERT INTO achievement_types (
    id, name, description, category, icon, tier, points,
    threshold_value, threshold_unit, is_repeatable
) VALUES
-- Total workouts completed (consistency_workouts_*). Thresholds come from
-- trophy_triggers.py:check_consistency_achievements (lines 537-543).
('consistency_workouts_bronze',   'Ten Down',          'Complete 10 total workouts',       'consistency', '🎯', 'bronze',   50,    10, 'workouts', false),
('consistency_workouts_silver',   'Half a Hundred',    'Complete 50 total workouts',       'consistency', '🎯', 'silver',  150,    50, 'workouts', false),
('consistency_workouts_gold',     'Two Hundred Club',  'Complete 200 total workouts',      'consistency', '🏆', 'gold',    400,   200, 'workouts', false),
('consistency_workouts_platinum', 'Five Hundred Strong','Complete 500 total workouts',     'consistency', '🏆', 'platinum',800,   500, 'workouts', false),
('consistency_workouts_diamond',  'Thousand Workouts', 'Complete 1000 total workouts',     'consistency', '💎', 'platinum',2000, 1000, 'workouts', false),

-- Time under the bar (time_workout_*). Thresholds come from
-- trophy_triggers.py:check_time_achievements (lines 359-364), stored in
-- hours.
('time_workout_bronze',           'First Day Done',    'Log 24 total hours of training',   'time',        '⏱️', 'bronze',   50,    24, 'hours',    false),
('time_workout_silver',           'Hundred Hour Hustle','Log 100 total hours of training', 'time',        '⏱️', 'silver',  150,   100, 'hours',    false),
('time_workout_gold',             'Quarter K Grind',   'Log 250 total hours of training',  'time',        '⏱️', 'gold',    400,   250, 'hours',    false),
('time_workout_platinum',         'Five Hundred Club', 'Log 500 total hours of training',  'time',        '⏱️', 'platinum',800,   500, 'hours',    false),
('time_workout_diamond',          'Thousand Hour Titan','Log 1000 total hours of training','time',        '💎', 'platinum',2000, 1000, 'hours',    false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================================
-- 2. count_muscle_group_exercises — used by check_exercise_mastery_achievements
-- =====================================================================

-- Returns the count of distinct exercise names the user has logged in
-- performance_logs whose `exercises.primary_muscle` matches the requested
-- muscle group (case-insensitive). performance_logs rows only exist for
-- completed sets, so no extra completion filter is needed.
CREATE OR REPLACE FUNCTION public.count_muscle_group_exercises(
    p_user_id UUID,
    p_muscle_group TEXT
) RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT COUNT(DISTINCT pl.exercise_name)::INTEGER
    FROM public.performance_logs pl
    JOIN public.exercises e
      ON LOWER(e.name) = LOWER(pl.exercise_name)
   WHERE pl.user_id = p_user_id
     AND LOWER(e.primary_muscle) = LOWER(p_muscle_group);
$$;

COMMENT ON FUNCTION public.count_muscle_group_exercises(UUID, TEXT) IS
'Count of distinct exercises the user has logged for a given primary
muscle group. Source of truth: performance_logs JOIN exercises.';

-- =====================================================================
-- 3. get_user_volume_stats — used by check_volume_achievements
-- =====================================================================

-- Returns total volume across the user's performance_logs. Converts kg
-- to lbs in-function because the trophy thresholds in trophy_triggers.py
-- are lbs-denominated (volume_weight_* tiers at 25000 / 250000 / 1M / 5M
-- lbs). One set = one performance_logs row.
CREATE OR REPLACE FUNCTION public.get_user_volume_stats(
    p_user_id UUID
) RETURNS TABLE(
    total_sets        INTEGER,
    total_reps        BIGINT,
    total_weight_lbs  DOUBLE PRECISION
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    COUNT(*)::INTEGER                                       AS total_sets,
    COALESCE(SUM(pl.reps_completed), 0)::BIGINT             AS total_reps,
    COALESCE(
      SUM(pl.reps_completed * pl.weight_kg * 2.20462),
      0
    )::DOUBLE PRECISION                                     AS total_weight_lbs
  FROM public.performance_logs pl
  WHERE pl.user_id = p_user_id;
$$;

COMMENT ON FUNCTION public.get_user_volume_stats(UUID) IS
'Total sets / reps / lbs lifted across all performance_logs for a user.
Weight is converted from stored kg to lbs here so trophy thresholds
(which are lbs-denominated) can compare directly.';

-- =====================================================================
-- 4. count_mutual_follows — used by check_social_achievements
-- =====================================================================

-- Social "friend count" on this app is mutual-follow semantics: user A and
-- user B are friends iff each follows the other with status='active' in
-- user_connections. The old `friends` table referenced by trophy_triggers
-- never existed in this schema; the (partially-committed) fix that swapped
-- to `user_connections` kept `.eq("user_id", …).eq("status", "accepted")`
-- but user_connections has no `user_id` column and no `'accepted'` status
-- (see migrations/028_social_features.sql:9-30 — columns are
-- follower_id / following_id / status CHECK 'active|blocked|muted').
-- This RPC makes the intent explicit and keeps the trophy-trigger call
-- site a single round-trip.
CREATE OR REPLACE FUNCTION public.count_mutual_follows(
    p_user_id UUID
) RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT COUNT(DISTINCT a.following_id)::INTEGER
  FROM public.user_connections a
  JOIN public.user_connections b
    ON b.follower_id = a.following_id
   AND b.following_id = a.follower_id
   AND b.status = 'active'
  WHERE a.follower_id = p_user_id
    AND a.status = 'active';
$$;

COMMENT ON FUNCTION public.count_mutual_follows(UUID) IS
'Number of mutual-follow relationships (both directions active) for a user.
Source of truth: user_connections (status=active). Used for social_friends_*
trophies.';

-- =====================================================================
-- 5. Permissions
-- =====================================================================

GRANT EXECUTE ON FUNCTION public.count_muscle_group_exercises(UUID, TEXT)
    TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_user_volume_stats(UUID)
    TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.count_mutual_follows(UUID)
    TO authenticated, service_role;
