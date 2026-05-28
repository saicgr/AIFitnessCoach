-- Migration 2202 — workouts.scheduled_local_time (HH:MM).
--
-- Adds a nullable HH:MM string the user/planner can set per workout so the
-- pre-workout T-30 card and pre-workout fuel card can compute "minutes until
-- workout" against the user's local time. We deliberately store as text
-- (HH:MM) — NOT a timestamp — because the workout's scheduled date already
-- lives in `scheduled_for_date` and the user's timezone is read separately.
--
-- Idempotent.

ALTER TABLE workouts
    ADD COLUMN IF NOT EXISTS scheduled_local_time text;

COMMENT ON COLUMN workouts.scheduled_local_time IS
    'Optional user-set start time in local 24h HH:MM. NULL = no fixed time.';
