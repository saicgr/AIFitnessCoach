-- Migration 2313: neat_reminder_preferences — add the 3 API-model fields with
-- no schema home (2026-07-04 drift sweep). The rest of the API model maps
-- semantically onto existing columns (enabled→reminders_enabled,
-- frequency→reminder_interval_minutes, start/end_time→work_hours_*,
-- active_days→weekend_reminders, skip_if_active→smart_reminders) — that
-- remap happens in api/v1/neat_endpoints.py so the reminder engine (which
-- reads the real columns) actually honors what users save. Before this,
-- every preference save 42703'd and reads silently returned defaults.

BEGIN;

ALTER TABLE neat_reminder_preferences ADD COLUMN IF NOT EXISTS active_threshold_minutes INT DEFAULT 5;
ALTER TABLE neat_reminder_preferences ADD COLUMN IF NOT EXISTS quiet_during_workout BOOLEAN DEFAULT TRUE;
ALTER TABLE neat_reminder_preferences ADD COLUMN IF NOT EXISTS reminder_message_style TEXT DEFAULT 'encouraging';

COMMIT;
