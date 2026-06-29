-- 2299: distance tracking for cardio / carry / run stations.
--
-- Per-set logged distance (SkiErg 1000 m, Sled Push 50 m, Farmers Carry 50 m,
-- run distance, etc.) for the distance + cardio tracker. Nullable + idempotent
-- — strength / bodyweight / timed sets leave it NULL. Duration for these
-- stations rides on the existing performance_logs.set_duration_seconds column.
--
-- Applied to prod (hpbzfahijszqmgsybuor) via MCP apply_migration.

ALTER TABLE performance_logs
    ADD COLUMN IF NOT EXISTS distance_meters double precision;

COMMENT ON COLUMN performance_logs.distance_meters IS
    'Logged distance in meters for distance-tracked sets (cardio machines, sleds, loaded carries, runs). NULL for weight/bodyweight/timed sets.';
