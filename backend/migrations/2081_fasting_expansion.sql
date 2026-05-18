-- Migration 2081: Fasting feature expansion
-- Adds custom weekly schedule (Task G) + pause/resume + undo-end + edit-past (Task I)

-- ===== Task G: custom weekly fasting schedule =====
-- weekly_schedule: JSONB map of weekday "0".."6" (Mon..Sun) -> protocol descriptor.
-- A missing/null entry = eating/rest day. Each value is an object:
--   { "protocol": "16:8", "custom_fasting_hours": null }
ALTER TABLE fasting_preferences
    ADD COLUMN IF NOT EXISTS weekly_schedule JSONB;

-- ===== Task I: pause / resume an active fast =====
-- paused_at: timestamp the fast was paused (NULL = not currently paused).
-- accumulated_paused_seconds: running total of suspended seconds across pauses.
ALTER TABLE fasting_records
    ADD COLUMN IF NOT EXISTS paused_at TIMESTAMPTZ;

ALTER TABLE fasting_records
    ADD COLUMN IF NOT EXISTS accumulated_paused_seconds INTEGER NOT NULL DEFAULT 0;
