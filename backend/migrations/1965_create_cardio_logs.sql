-- Migration: 1965_create_cardio_logs.sql
-- Description: First-class home for cardio sessions imported from Strava,
-- Peloton, Garmin FIT, Apple Health, Fitbit, Nike Run Club, Runkeeper, and
-- MapMyRun — plus manual entries and the strength-import cardio by-products
-- (e.g. Hevy's "Running" rows). Designed as a sibling to workout_history_imports:
-- strength goes there, cardio goes here, same dedup + provenance conventions.

CREATE TABLE IF NOT EXISTS cardio_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    performed_at TIMESTAMPTZ NOT NULL,
    activity_type TEXT NOT NULL
      CHECK (activity_type IN (
        'run', 'trail_run', 'treadmill', 'walk', 'hike',
        'cycle', 'indoor_cycle', 'mountain_bike', 'gravel_bike',
        'row', 'erg',
        'swim', 'open_water_swim',
        'elliptical', 'stair', 'stepmill',
        'ski_erg', 'skate_ski', 'nordic_ski', 'downhill_ski', 'snowboard',
        'yoga', 'pilates',
        'hiit', 'boxing', 'kickboxing',
        'other'
      )),
    duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
    distance_m NUMERIC(10, 2) CHECK (distance_m IS NULL OR distance_m >= 0),
    elevation_gain_m NUMERIC(8, 2) CHECK (elevation_gain_m IS NULL OR elevation_gain_m >= 0),

    avg_heart_rate INTEGER CHECK (avg_heart_rate IS NULL OR (avg_heart_rate BETWEEN 20 AND 260)),
    max_heart_rate INTEGER CHECK (max_heart_rate IS NULL OR (max_heart_rate BETWEEN 20 AND 260)),
    avg_pace_seconds_per_km NUMERIC(8, 2) CHECK (avg_pace_seconds_per_km IS NULL OR avg_pace_seconds_per_km > 0),
    avg_speed_mps NUMERIC(8, 3) CHECK (avg_speed_mps IS NULL OR avg_speed_mps >= 0),
    avg_watts INTEGER CHECK (avg_watts IS NULL OR avg_watts >= 0),
    max_watts INTEGER CHECK (max_watts IS NULL OR max_watts >= 0),
    avg_cadence INTEGER CHECK (avg_cadence IS NULL OR avg_cadence >= 0),
    avg_stroke_rate INTEGER CHECK (avg_stroke_rate IS NULL OR avg_stroke_rate >= 0),
    training_effect NUMERIC(3, 1) CHECK (training_effect IS NULL OR (training_effect BETWEEN 0 AND 10)),
    vo2max_estimate NUMERIC(5, 2) CHECK (vo2max_estimate IS NULL OR vo2max_estimate > 0),

    calories INTEGER CHECK (calories IS NULL OR calories >= 0),
    rpe NUMERIC(3, 1) CHECK (rpe IS NULL OR (rpe BETWEEN 0 AND 10)),
    notes TEXT,
    gps_polyline TEXT,                       -- encoded polyline for map render; can be megabytes
    splits_json JSONB,                       -- per-km / per-mile split breakdown when source has it

    source_app TEXT NOT NULL,                -- 'strava' | 'peloton' | 'garmin' | 'apple_health' | 'fitbit' | 'nike' | 'mapmyrun' | 'runkeeper' | 'hevy' | 'fitbod' | 'manual' | 'ai_parsed'
    source_external_id TEXT,                 -- Strava activity_id / Peloton workout_id / Garmin activity_id — for webhook dedup
    source_row_hash TEXT NOT NULL,           -- sha256 for file-import dedup
    import_job_id UUID,
    sync_account_id UUID,                    -- FK to oauth_sync_accounts when streamed via sync; NULL for file imports

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- If max_heart_rate is set and avg_heart_rate is set, max must be >= avg.
    CHECK (
        avg_heart_rate IS NULL
        OR max_heart_rate IS NULL
        OR max_heart_rate >= avg_heart_rate
    )
);

-- Dedup indexes: one for hash-based (file imports), one for external_id (OAuth sync).
CREATE UNIQUE INDEX IF NOT EXISTS uq_cardio_logs_user_hash
  ON cardio_logs (user_id, source_row_hash);

CREATE UNIQUE INDEX IF NOT EXISTS uq_cardio_logs_user_provider_external
  ON cardio_logs (user_id, source_app, source_external_id)
  WHERE source_external_id IS NOT NULL;

-- Query indexes for the history screen + per-type PR queries.
CREATE INDEX IF NOT EXISTS idx_cardio_logs_user_time
  ON cardio_logs (user_id, performed_at DESC);

CREATE INDEX IF NOT EXISTS idx_cardio_logs_user_type_time
  ON cardio_logs (user_id, activity_type, performed_at DESC);

CREATE INDEX IF NOT EXISTS idx_cardio_logs_job
  ON cardio_logs (import_job_id)
  WHERE import_job_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_cardio_logs_sync_account
  ON cardio_logs (sync_account_id)
  WHERE sync_account_id IS NOT NULL;

-- RLS.
ALTER TABLE cardio_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own cardio logs"
  ON cardio_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own cardio logs"
  ON cardio_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own cardio logs"
  ON cardio_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users delete own cardio logs"
  ON cardio_logs FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role full access cardio logs"
  ON cardio_logs FOR ALL
  USING (auth.role() = 'service_role');

-- updated_at trigger — reuses the existing helper function pattern.
CREATE OR REPLACE FUNCTION update_cardio_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_cardio_logs_updated_at ON cardio_logs;
CREATE TRIGGER trigger_update_cardio_logs_updated_at
    BEFORE UPDATE ON cardio_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_cardio_logs_updated_at();

COMMENT ON TABLE cardio_logs IS
  'Cardio sessions from Strava/Peloton/Garmin/Apple Health/Fitbit imports + manual entries. Sibling to workout_history_imports for strength.';
COMMENT ON COLUMN cardio_logs.source_row_hash IS
  'sha256(user_id|source_app|performed_at|activity_type|round(duration_seconds,0)|round(distance_m,0)). Enables idempotent re-import.';
COMMENT ON COLUMN cardio_logs.source_external_id IS
  'Provider-native activity ID — Strava activity_id / Peloton workout_id. Dedupes OAuth-synced vs file-imported duplicates.';
