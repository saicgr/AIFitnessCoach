-- 2296: Phase C corrective migration for the generic per-set metric feature.
--
-- The Phase A "CREATE TABLE IF NOT EXISTS user_custom_metrics(... canonical_unit,
-- input_type)" silently no-op'd because user_custom_metrics ALREADY existed as
-- the HEALTH custom-metric table (migration 2110: id, user_id, key, label, unit,
-- good_direction, is_active). So the per-set tracking columns the registry
-- contract expects were never added.
--
-- This adds them, plus a `scope` discriminator so exercise metric definitions
-- (scope='exercise') do not pollute the health custom-metric list (scope='health',
-- the default for every existing + future health row). Non-destructive / idempotent.
--
-- Applied to prod 2026-06-29 via Supabase MCP apply_migration.

ALTER TABLE user_custom_metrics
  ADD COLUMN IF NOT EXISTS canonical_unit text,
  ADD COLUMN IF NOT EXISTS input_type     text,
  ADD COLUMN IF NOT EXISTS scope          text NOT NULL DEFAULT 'health';

CREATE INDEX IF NOT EXISTS idx_user_custom_metrics_user_scope
  ON user_custom_metrics (user_id, scope);
