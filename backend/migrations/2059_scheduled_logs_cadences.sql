-- Migration 2057: Rich scheduling cadences for `scheduled_recipe_logs`.
--
-- Adds cadence shapes the meal long-press menu needs (per-meal scheduling
-- spec from the plan):
--   1. Once (specific date+time)            ← ScheduleKind 'once' (NEW)
--   2. Tomorrow only                        ← shortcut for #1
--   3. Daily                                ← already supported
--   4. Daily until <date>                   ← until_date column (NEW)
--   5. Weekdays                             ← already supported
--   6. Weekly on <weekday>                  ← already supported (custom)
--   7. Just this week                       ← is_temporary_week_only (NEW)
--   8. Alternate days this week             ← is_temporary_week_only + days
--   9. Alternate days every week            ← already supported (custom)
--  10. Custom days + optional end date      ← until_date (NEW)
--  11. Every N days                         ← interval_days column (NEW)
--
-- The worker (backend/jobs/scheduled_meal_logs_worker.py) is updated in the
-- same change to honor these columns when computing next_fire_at + when
-- deciding whether to disable a schedule.

ALTER TABLE scheduled_recipe_logs
  ADD COLUMN IF NOT EXISTS until_date DATE,
  ADD COLUMN IF NOT EXISTS interval_days INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS is_temporary_week_only BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS week_end_date DATE,
  ADD COLUMN IF NOT EXISTS occurrences_remaining INT;

-- Drop the old kind CHECK constraint and re-add with 'once' allowed.
ALTER TABLE scheduled_recipe_logs DROP CONSTRAINT IF EXISTS scheduled_recipe_logs_schedule_kind_check;
ALTER TABLE scheduled_recipe_logs ADD CONSTRAINT scheduled_recipe_logs_schedule_kind_check
  CHECK (
    schedule_kind IS NULL
    OR schedule_kind = ANY (ARRAY['daily','weekdays','weekends','custom','once']::text[])
  );

-- interval_days must be in [1, 365] — sane upper bound prevents accidental
-- "every 100000 days" rows that would silently never fire.
ALTER TABLE scheduled_recipe_logs DROP CONSTRAINT IF EXISTS scheduled_recipe_logs_interval_days_check;
ALTER TABLE scheduled_recipe_logs ADD CONSTRAINT scheduled_recipe_logs_interval_days_check
  CHECK (interval_days >= 1 AND interval_days <= 365);

-- Comment documenting the worker contract so future readers know where the
-- cadence math lives.
COMMENT ON COLUMN scheduled_recipe_logs.until_date IS
  'Inclusive last calendar day this schedule may fire on. NULL = no end. '
  'Consulted by the worker_advance_schedule path: once next_fire_at would '
  'exceed until_date, the schedule auto-disables.';
COMMENT ON COLUMN scheduled_recipe_logs.interval_days IS
  'For "every N days" cadences. 1 (default) = matches days_of_week as today. '
  '>1 = after each fire, advance by this many days before checking days_of_week '
  'for the next match.';
COMMENT ON COLUMN scheduled_recipe_logs.is_temporary_week_only IS
  'When true, the schedule auto-disables after the last selected day in the '
  'CURRENT calendar week (Mon..Sun). Used for "just this week" + "alternate '
  'days this week" cadences. week_end_date should be set to the Sunday of '
  'the week the schedule was created in.';
COMMENT ON COLUMN scheduled_recipe_logs.occurrences_remaining IS
  'Optional fire-count cap. Decrements on every fire; auto-disables at 0. '
  'NULL = no cap. Useful for "fire 3 times then stop" patterns.';
