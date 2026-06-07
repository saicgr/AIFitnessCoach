-- Migration 2249: vitals_daily — nightly overnight bio-signals for the Vitals feature.
--
-- Samsung-parity "Vitals": five overnight signals (resting HR, HRV RMSSD, respiratory
-- rate, SpO2, skin-temperature delta) synced from HealthKit / Health Connect by the
-- client, one row per user per local night. Baselines + deviation (z-score vs the
-- trailing 28 days) are computed server-side in api/v1/health/vitals.py — this table
-- only stores raw readings. Any signal the wearable did not provide stays NULL (we
-- never fabricate; the UI shows a per-signal "needs a compatible wearable" state).
--
-- These four signals (HRV / respiratory / SpO2 / skin-temp) were dropped from the
-- Health Connect scope 2026-05-07 because nothing surfaced them. The Vitals screen is
-- the user-facing surface that re-justifies them; Android reads are re-enabled behind
-- a feature flag pending the Health Connect declaration resubmission.
--
-- Idempotent: CREATE TABLE / INDEX IF NOT EXISTS are safe to re-run.

CREATE TABLE IF NOT EXISTS vitals_daily (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    local_date      DATE NOT NULL,

    resting_hr        SMALLINT,        -- bpm
    hrv_rmssd         NUMERIC(6,2),    -- ms
    respiratory_rate  NUMERIC(5,2),    -- breaths/min
    spo2              NUMERIC(5,2),    -- %
    skin_temp_delta   NUMERIC(5,2),    -- °C delta vs the wearable's own baseline

    source          TEXT,             -- e.g. 'apple_health', 'health_connect'
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT vitals_daily_user_date_uniq UNIQUE (user_id, local_date)
);

CREATE INDEX IF NOT EXISTS idx_vitals_daily_user_date
    ON vitals_daily (user_id, local_date DESC);

COMMENT ON TABLE vitals_daily IS
    'Nightly overnight bio-signals (RHR, HRV, respiratory rate, SpO2, skin-temp delta) '
    'synced from HealthKit/Health Connect. One row per user per local night. Baselines '
    'and deviation are computed in api/v1/health/vitals.py; NULL = signal not provided.';
