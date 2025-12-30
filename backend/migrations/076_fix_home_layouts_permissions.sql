-- ============================================================================
-- Migration 076: Fix Home Layouts Permissions
-- ============================================================================
-- Fixes permission issues with home_layouts and home_layout_templates tables
-- that cause "Failed to load layout" errors.
-- ============================================================================

-- Grant service_role full access to both tables
GRANT ALL ON home_layouts TO service_role;
GRANT ALL ON home_layout_templates TO service_role;

-- Grant execute on functions to service_role
GRANT EXECUTE ON FUNCTION get_or_create_default_layout(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION activate_home_layout(UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION create_layout_from_template(UUID, UUID, VARCHAR) TO service_role;

-- Also grant to anon for public template access
GRANT SELECT ON home_layout_templates TO anon;

-- Ensure templates exist (re-insert if empty)
INSERT INTO home_layout_templates (name, description, tiles, icon, category)
SELECT * FROM (VALUES
-- Minimalist: Focus on essentials
('Minimalist', 'Focus on your workout',
 '[{"id":"t1","type":"nextWorkout","order":0,"size":"full","is_visible":true},{"id":"t2","type":"weeklyProgress","order":1,"size":"half","is_visible":true},{"id":"t3","type":"streakCounter","order":2,"size":"half","is_visible":true}]'::JSONB,
 'spa', 'minimalist'),

-- Performance: Data-driven athlete view
('Performance', 'Data-driven athlete view',
 '[{"id":"t1","type":"fitnessScore","order":0,"size":"full","is_visible":true},{"id":"t2","type":"nextWorkout","order":1,"size":"full","is_visible":true},{"id":"t3","type":"personalRecords","order":2,"size":"full","is_visible":true},{"id":"t4","type":"muscleHeatmap","order":3,"size":"full","is_visible":true}]'::JSONB,
 'analytics', 'performance'),

-- Wellness: Holistic health focus
('Wellness', 'Holistic health focus',
 '[{"id":"t1","type":"moodPicker","order":0,"size":"full","is_visible":true},{"id":"t2","type":"dailyActivity","order":1,"size":"full","is_visible":true},{"id":"t3","type":"nextWorkout","order":2,"size":"full","is_visible":true},{"id":"t4","type":"caloriesSummary","order":3,"size":"half","is_visible":true},{"id":"t5","type":"fasting","order":4,"size":"half","is_visible":true}]'::JSONB,
 'favorite', 'wellness'),

-- Social: Stay connected & motivated
('Social', 'Stay connected & motivated',
 '[{"id":"t1","type":"nextWorkout","order":0,"size":"full","is_visible":true},{"id":"t2","type":"challengeProgress","order":1,"size":"full","is_visible":true},{"id":"t3","type":"socialFeed","order":2,"size":"full","is_visible":true},{"id":"t4","type":"leaderboardRank","order":3,"size":"half","is_visible":true},{"id":"t5","type":"streakCounter","order":4,"size":"half","is_visible":true}]'::JSONB,
 'people', 'social'),

-- Complete: All core features visible
('Complete', 'All core features visible',
 '[{"id":"t1","type":"nextWorkout","order":0,"size":"full","is_visible":true},{"id":"t2","type":"fitnessScore","order":1,"size":"full","is_visible":true},{"id":"t3","type":"moodPicker","order":2,"size":"full","is_visible":true},{"id":"t4","type":"dailyActivity","order":3,"size":"full","is_visible":true},{"id":"t5","type":"quickActions","order":4,"size":"full","is_visible":true},{"id":"t6","type":"weeklyProgress","order":5,"size":"full","is_visible":true},{"id":"t7","type":"weeklyGoals","order":6,"size":"full","is_visible":true},{"id":"t8","type":"weekChanges","order":7,"size":"full","is_visible":true},{"id":"t9","type":"upcomingFeatures","order":8,"size":"full","is_visible":true},{"id":"t10","type":"upcomingWorkouts","order":9,"size":"full","is_visible":true}]'::JSONB,
 'dashboard', 'complete')
) AS v(name, description, tiles, icon, category)
WHERE NOT EXISTS (SELECT 1 FROM home_layout_templates LIMIT 1);

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
