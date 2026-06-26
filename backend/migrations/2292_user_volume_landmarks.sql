-- Migration: 2292_user_volume_landmarks.sql
-- Created: 2026-06-26
-- Purpose: Dr-Yaad audit #6 — EARNED, per-user adaptive volume landmarks. The
--          static MEV/MAV/MRV constants (workout_validator_phase2.VOLUME_LANDMARKS,
--          Renaissance-Periodization population defaults) are a starting point;
--          this table lets the engine learn that THIS user handles vertical-pull
--          volume well but their elbow flexors get hot fast — assertive where it
--          has data (confidence ↑), conservative (falls back to static) where it
--          doesn't. Populated by volume_learning_service from weekly_volume_tracking
--          + strain_history + progress, recomputed in the background on completion.

CREATE TABLE IF NOT EXISTS user_volume_landmarks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL,
    muscle      TEXT NOT NULL,
    mev         SMALLINT,
    mav         SMALLINT,
    mrv         SMALLINT,
    confidence  NUMERIC NOT NULL DEFAULT 0,   -- 0 (use static) .. 1 (fully trusted)
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, muscle)
);

CREATE INDEX IF NOT EXISTS idx_user_volume_landmarks_user
  ON user_volume_landmarks (user_id);
