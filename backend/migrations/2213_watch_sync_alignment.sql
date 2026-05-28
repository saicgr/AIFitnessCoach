-- 2213_watch_sync_alignment.sql
-- Single table for the watch_sync goals endpoint: per-user hydration target.
-- Callsite: api/v1/watch_sync.py:278 (read of daily_goal_ml).
--
-- Fasting alignment is handled as a code-only fix in watch_sync.py
-- (rename of "fasting_sessions" → "fasting_records" + matching column rename).
--
-- Idempotent.

CREATE TABLE IF NOT EXISTS hydration_settings (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_goal_ml   integer NOT NULL DEFAULT 2000,
  reminder_enabled boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE hydration_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS hydration_settings_owner ON hydration_settings;
CREATE POLICY hydration_settings_owner ON hydration_settings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
