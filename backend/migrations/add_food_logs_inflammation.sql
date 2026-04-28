-- Persist inflammation score on food logs so users can see the score AFTER
-- they finish logging (it currently only renders during the logging sheet
-- and disappears when the sheet closes). Also stores the raw signals so the
-- daily report can call out specific contributors (e.g. "+UPF: chips").
--
-- Idempotent — safe to re-run.

ALTER TABLE food_logs
  ADD COLUMN IF NOT EXISTS inflammation_score SMALLINT,
  ADD COLUMN IF NOT EXISTS inflammation_signals JSONB;

CREATE INDEX IF NOT EXISTS idx_food_logs_user_date_inflammation
  ON food_logs (user_id, logged_at DESC)
  WHERE inflammation_score IS NOT NULL;
