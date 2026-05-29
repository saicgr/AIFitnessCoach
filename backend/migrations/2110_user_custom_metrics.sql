-- Migration 2110: User-defined custom metrics.
--
-- Lets a user define an arbitrary metric (own label, unit, and whether
-- higher/lower/neutral is "good"), log values over time, and read history
-- so the app can show it as a stat with a trend.
--
-- user_custom_metrics holds the definition (one row per metric per user,
-- uniquely keyed by a url-safe slug). user_custom_metric_logs holds the
-- time series of logged values. Logs cascade-delete with their definition.

CREATE TABLE IF NOT EXISTS user_custom_metrics (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    key             TEXT NOT NULL,                       -- url-safe slug derived from label
    label           TEXT NOT NULL,                       -- user-facing display label
    unit            TEXT,                                -- optional unit (e.g. "ml", "hrs", "reps")
    good_direction  TEXT NOT NULL DEFAULT 'neutral',     -- which way the trend is "good"
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT user_custom_metrics_good_direction_chk CHECK (
        good_direction IN ('higher', 'lower', 'neutral')
    ),
    CONSTRAINT user_custom_metrics_user_key_uniq UNIQUE (user_id, key)
);

CREATE INDEX IF NOT EXISTS user_custom_metrics_user_idx
    ON user_custom_metrics (user_id);

CREATE TABLE IF NOT EXISTS user_custom_metric_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_id       UUID NOT NULL REFERENCES user_custom_metrics(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    value           DOUBLE PRECISION NOT NULL,
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS user_custom_metric_logs_metric_recorded_idx
    ON user_custom_metric_logs (metric_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS user_custom_metric_logs_user_idx
    ON user_custom_metric_logs (user_id);

-- RLS — every row is private to its user.
ALTER TABLE user_custom_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_custom_metrics_select_own ON user_custom_metrics;
CREATE POLICY user_custom_metrics_select_own
    ON user_custom_metrics FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_custom_metrics_insert_own ON user_custom_metrics;
CREATE POLICY user_custom_metrics_insert_own
    ON user_custom_metrics FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_custom_metrics_update_own ON user_custom_metrics;
CREATE POLICY user_custom_metrics_update_own
    ON user_custom_metrics FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_custom_metrics_delete_own ON user_custom_metrics;
CREATE POLICY user_custom_metrics_delete_own
    ON user_custom_metrics FOR DELETE
    USING (user_id = auth.uid());

ALTER TABLE user_custom_metric_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_custom_metric_logs_select_own ON user_custom_metric_logs;
CREATE POLICY user_custom_metric_logs_select_own
    ON user_custom_metric_logs FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_custom_metric_logs_insert_own ON user_custom_metric_logs;
CREATE POLICY user_custom_metric_logs_insert_own
    ON user_custom_metric_logs FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_custom_metric_logs_update_own ON user_custom_metric_logs;
CREATE POLICY user_custom_metric_logs_update_own
    ON user_custom_metric_logs FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_custom_metric_logs_delete_own ON user_custom_metric_logs;
CREATE POLICY user_custom_metric_logs_delete_own
    ON user_custom_metric_logs FOR DELETE
    USING (user_id = auth.uid());
