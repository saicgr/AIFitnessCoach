-- Migration: Add exercise_queue.used_in_workout_id (finding #280)
--
-- The Queue tab's "N queued" count and Pending list already exclude spent
-- rows (GET /exercise-queue filters `.is_("used_at", "null")`), but nothing
-- records WHICH workout a spent item landed in, so the UI has no way to
-- render "Added to Wed 19 Aug · Posterior Chain Focus" for an "Added to
-- upcoming" section. `_inject_into_section`'s used_at write
-- (api/v1/workouts/preference_engine_helpers.py) already has `next_workout`
-- (id + name + scheduled_date) in scope at the moment it marks the row used,
-- so this column can be populated there with no extra query.

ALTER TABLE exercise_queue
  ADD COLUMN IF NOT EXISTS used_in_workout_id uuid REFERENCES workouts(id);

CREATE INDEX IF NOT EXISTS idx_exercise_queue_used_in_workout_id
  ON exercise_queue (used_in_workout_id);

-- VERIFY: select column_name from information_schema.columns where table_name = 'exercise_queue' and column_name = 'used_in_workout_id'; -- expect 1 row
