-- Migration: Fix Security Definer Views
-- Created: 2025-12-26
-- Description: Fix SECURITY DEFINER views and enable RLS on nutrient_rdas table
--
-- Issues being fixed:
-- 1. Views defined with SECURITY DEFINER bypass RLS of the querying user
-- 2. nutrient_rdas table doesn't have RLS enabled
--
-- Solution: Recreate views with SECURITY INVOKER (default) which respects
-- the permissions and RLS policies of the querying user

-- ============================================================
-- FIX: recipes_with_stats VIEW
-- ============================================================

DROP VIEW IF EXISTS recipes_with_stats;
CREATE VIEW recipes_with_stats
WITH (security_invoker = true)
AS
SELECT
    r.*,
    COUNT(ri.id) AS ingredient_count,
    COALESCE(r.prep_time_minutes, 0) + COALESCE(r.cook_time_minutes, 0) AS total_time_minutes
FROM user_recipes r
LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
WHERE r.deleted_at IS NULL
GROUP BY r.id;

COMMENT ON VIEW recipes_with_stats IS 'Recipes with ingredient count and total time - uses SECURITY INVOKER';

-- ============================================================
-- FIX: popular_community_recipes VIEW
-- ============================================================

DROP VIEW IF EXISTS popular_community_recipes;
CREATE VIEW popular_community_recipes
WITH (security_invoker = true)
AS
SELECT *
FROM user_recipes
WHERE is_public = TRUE
AND deleted_at IS NULL
ORDER BY times_logged DESC, created_at DESC
LIMIT 100;

COMMENT ON VIEW popular_community_recipes IS 'Popular public recipes - uses SECURITY INVOKER';

-- ============================================================
-- FIX: active_saved_foods VIEW
-- ============================================================

DROP VIEW IF EXISTS active_saved_foods;
CREATE VIEW active_saved_foods
WITH (security_invoker = true)
AS
SELECT *
FROM saved_foods
WHERE deleted_at IS NULL;

COMMENT ON VIEW active_saved_foods IS 'Non-deleted saved foods - uses SECURITY INVOKER';

-- ============================================================
-- FIX: saved_foods_with_stats VIEW
-- ============================================================

DROP VIEW IF EXISTS saved_foods_with_stats;
CREATE VIEW saved_foods_with_stats
WITH (security_invoker = true)
AS
SELECT
    sf.*,
    COALESCE(sf.times_logged, 0) as log_count
FROM saved_foods sf
WHERE sf.deleted_at IS NULL;

COMMENT ON VIEW saved_foods_with_stats IS 'Saved foods with usage stats - uses SECURITY INVOKER';

-- ============================================================
-- FIX: user_friends VIEW (using user_connections table)
-- ============================================================

DROP VIEW IF EXISTS user_friends;
CREATE VIEW user_friends
WITH (security_invoker = true)
AS
SELECT
    uc.id,
    uc.follower_id as user_id,
    uc.following_id as friend_id,
    uc.status,
    uc.created_at,
    u.name as friend_display_name,
    u.avatar_url as friend_avatar_url
FROM user_connections uc
JOIN users u ON u.id = uc.following_id
WHERE uc.connection_type = 'friend';

COMMENT ON VIEW user_friends IS 'Friend connections with details - uses SECURITY INVOKER';

-- ============================================================
-- FIX: challenge_retry_chains VIEW
-- NOTE: retry_count and retried_from_challenge_id columns don't exist
-- Just drop this orphaned view
-- ============================================================

DROP VIEW IF EXISTS challenge_retry_chains;
-- View not recreated: retry columns don't exist in workout_challenges table

-- ============================================================
-- FIX: pending_challenges_with_users VIEW
-- ============================================================

DROP VIEW IF EXISTS pending_challenges_with_users;
CREATE VIEW pending_challenges_with_users
WITH (security_invoker = true)
AS
SELECT
    c.*,
    from_user.name AS from_user_name,
    from_user.avatar_url AS from_user_avatar,
    to_user.name AS to_user_name,
    to_user.avatar_url AS to_user_avatar
FROM workout_challenges c
JOIN users from_user ON from_user.id = c.from_user_id
JOIN users to_user ON to_user.id = c.to_user_id
WHERE c.status = 'pending'
    AND c.expires_at > NOW();

COMMENT ON VIEW pending_challenges_with_users IS 'Pending challenges with user details - uses SECURITY INVOKER';

-- ============================================================
-- FIX: latest_body_measurements VIEW
-- ============================================================

DROP VIEW IF EXISTS latest_body_measurements;
CREATE VIEW latest_body_measurements
WITH (security_invoker = true)
AS
SELECT DISTINCT ON (user_id)
    *
FROM body_measurements
ORDER BY user_id, measured_at DESC;

COMMENT ON VIEW latest_body_measurements IS 'Most recent body measurement per user - uses SECURITY INVOKER';

-- ============================================================
-- FIX: popular_shared_workouts VIEW
-- Uses workout_shares and activity_feed tables (not shared_workouts)
-- ============================================================

DROP VIEW IF EXISTS popular_shared_workouts;
CREATE VIEW popular_shared_workouts
WITH (security_invoker = true)
AS
SELECT
    ws.*,
    af.activity_data,
    u.name AS creator_name,
    u.avatar_url AS creator_avatar
FROM workout_shares ws
JOIN activity_feed af ON af.id = ws.activity_id
JOIN users u ON u.id = ws.shared_by
ORDER BY ws.share_count DESC, ws.created_at DESC
LIMIT 100;

COMMENT ON VIEW popular_shared_workouts IS 'Popular shared workouts - uses SECURITY INVOKER';

-- ============================================================
-- FIX: saved_workouts_with_source VIEW
-- Uses saved_workouts table with source_user_id
-- ============================================================

DROP VIEW IF EXISTS saved_workouts_with_source;
CREATE VIEW saved_workouts_with_source
WITH (security_invoker = true)
AS
SELECT
    sw.*,
    u.name AS source_user_name,
    u.avatar_url AS source_user_avatar
FROM saved_workouts sw
LEFT JOIN users u ON u.id = sw.source_user_id;

COMMENT ON VIEW saved_workouts_with_source IS 'Saved workouts with source user details - uses SECURITY INVOKER';

-- ============================================================
-- FIX: challenge_leaderboard VIEW
-- ============================================================

DROP VIEW IF EXISTS challenge_leaderboard;
CREATE VIEW challenge_leaderboard
WITH (security_invoker = true)
AS
SELECT
    u.id AS user_id,
    u.name,
    u.avatar_url,
    COUNT(*) FILTER (WHERE c.did_beat = true) AS challenges_won,
    COUNT(*) FILTER (WHERE c.did_beat = false) AS challenges_lost,
    COUNT(*) AS total_challenges_completed
FROM users u
LEFT JOIN workout_challenges c ON c.to_user_id = u.id
WHERE c.status = 'completed'
GROUP BY u.id, u.name, u.avatar_url
ORDER BY challenges_won DESC;

COMMENT ON VIEW challenge_leaderboard IS 'Challenge wins/losses leaderboard - uses SECURITY INVOKER';

-- ============================================================
-- FIX: upcoming_scheduled_workouts VIEW
-- ============================================================

DROP VIEW IF EXISTS upcoming_scheduled_workouts;
CREATE VIEW upcoming_scheduled_workouts
WITH (security_invoker = true)
AS
SELECT *
FROM scheduled_workouts
WHERE status = 'scheduled'
    AND scheduled_date >= CURRENT_DATE
ORDER BY scheduled_date ASC, scheduled_time ASC NULLS LAST;

COMMENT ON VIEW upcoming_scheduled_workouts IS 'Upcoming scheduled workouts - uses SECURITY INVOKER';

-- ============================================================
-- FIX: Enable RLS on nutrient_rdas table
-- ============================================================

-- Enable RLS
ALTER TABLE nutrient_rdas ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any (to make migration idempotent)
DROP POLICY IF EXISTS "Anyone can view nutrient RDAs" ON nutrient_rdas;
DROP POLICY IF EXISTS "Service role can manage nutrient RDAs" ON nutrient_rdas;

-- nutrient_rdas is reference data that everyone should be able to read
-- but only admins should be able to modify

-- Policy: Anyone can read nutrient RDAs (it's reference data)
CREATE POLICY "Anyone can view nutrient RDAs"
    ON nutrient_rdas FOR SELECT
    USING (true);

-- Policy: Only service role can insert/update/delete (admin operations)
-- Regular users cannot modify this table
CREATE POLICY "Service role can manage nutrient RDAs"
    ON nutrient_rdas FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

COMMENT ON TABLE nutrient_rdas IS 'Reference data for recommended daily allowances - RLS enabled, read-only for users';
