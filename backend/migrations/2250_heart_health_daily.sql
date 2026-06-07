-- Migration 2250: heart_health_daily — daily snapshot of the fused Heart Health Score.
--
-- Samsung-parity "Heart Health Score": a single 0-100 number fusing 7-day sleep,
-- 7-day moderate-vigorous activity, RHR-trend (the cardio-strain proxy that stands in
-- for Samsung's "Vascular load" — we have no BP), and body composition. Computed
-- deterministically in api/v1/health/heart_health.py. This table snapshots the daily
-- result so we can show the trend + the day-over-day delta chip ("▲2") without
-- recomputing history, and so the coach can reference it.
--
-- This is the CHRONIC habit score — distinct from recoveryProvider (acute, today's
-- readiness). components jsonb holds the per-driver breakdown the detail screen renders.
--
-- Idempotent.

CREATE TABLE IF NOT EXISTS heart_health_daily (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    local_date      DATE NOT NULL,

    score           SMALLINT NOT NULL,             -- 0-100
    delta           SMALLINT,                       -- vs previous snapshot (signed)
    components      JSONB NOT NULL DEFAULT '{}'::jsonb,  -- {sleep, activity, cardio_strain, body_comp}

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT heart_health_daily_user_date_uniq UNIQUE (user_id, local_date)
);

CREATE INDEX IF NOT EXISTS idx_heart_health_daily_user_date
    ON heart_health_daily (user_id, local_date DESC);

COMMENT ON TABLE heart_health_daily IS
    'Daily snapshot of the fused 0-100 Heart Health Score (chronic cardiovascular '
    'habit score). components jsonb = per-driver breakdown. Distinct from the acute '
    'recoveryProvider readiness score.';
