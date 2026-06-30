-- 2301_readiness_pre_workout_gauges.sql
--
-- Persist the pre-workout "Quick check-in" gauges (Sleep + Readiness, 0-10)
-- that the reshape-for-readiness flow collects. Until now these raw scores were
-- used only transiently to reshape the session and then DISCARDED — never
-- stored, never seen by the AI coach.
--
-- We reuse `readiness_scores` (the table the coach already reads in
-- user_state_assembler + daily_insight) rather than a new table, and store the
-- raw 0-10 values in dedicated columns so they don't collide with the existing
-- Hooper 1-7 `sleep_quality` scale.

ALTER TABLE readiness_scores
  ADD COLUMN IF NOT EXISTS pre_workout_sleep_0_10 INTEGER
    CHECK (pre_workout_sleep_0_10 BETWEEN 0 AND 10),
  ADD COLUMN IF NOT EXISTS pre_workout_readiness_0_10 INTEGER
    CHECK (pre_workout_readiness_0_10 BETWEEN 0 AND 10),
  ADD COLUMN IF NOT EXISTS pre_workout_checkin_at TIMESTAMPTZ;
