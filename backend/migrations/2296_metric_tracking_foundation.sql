-- Generic per-exercise metric-tracking foundation.
--
-- Applied to prod via the Supabase MCP (migration name
-- `metric_tracking_foundation`) BEFORE 2296_exercise_custom_metric_columns.sql.
-- Recorded here for repo provenance. Additive + idempotent; safe to re-run.
--
-- See: services/metric_registry.py, services/exercise_tracking_metric.py,
-- and the plan .claude/plans/yes-fix-1-peppy-grove.md.

-- Canonical per-set metric bag (any metric key->value in canonical units).
ALTER TABLE performance_logs ADD COLUMN IF NOT EXISTS metrics jsonb;

-- Custom exercises declare their own default tracked metric columns.
ALTER TABLE custom_exercises ADD COLUMN IF NOT EXISTS metric_keys text[];

-- User-defined custom metric definitions (e.g. box_height_cm).
-- NOTE: this table pre-existed (owned by the HEALTH custom-metric feature), so
-- the CREATE no-op'd; 2296_exercise_custom_metric_columns.sql adds the
-- exercise-scope columns (canonical_unit / input_type / scope).
CREATE TABLE IF NOT EXISTS user_custom_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  key text NOT NULL,
  label text NOT NULL,
  unit text,
  canonical_unit text NOT NULL,
  input_type text NOT NULL DEFAULT 'number',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_custom_metrics_user_key_uniq UNIQUE (user_id, key)
);
CREATE INDEX IF NOT EXISTS idx_user_custom_metrics_user ON user_custom_metrics(user_id);

-- Per-user, per-exercise chosen metric columns (live "+ Add column" persistence).
CREATE TABLE IF NOT EXISTS user_exercise_metric_prefs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  exercise_id text NOT NULL,
  metric_keys text[] NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_exercise_metric_prefs_user_ex_uniq UNIQUE (user_id, exercise_id)
);
CREATE INDEX IF NOT EXISTS idx_user_exercise_metric_prefs_user ON user_exercise_metric_prefs(user_id);
