-- Migration 2310: diabetes medications + glucose alerts write-path repair
-- (column-drift sweep 2026-07-04, see 2306-2309).
--
-- add_medication/update_medication write times_of_day + with_food, and the
-- entire glucose-alerts feature writes notification_method +
-- repeat_interval_minutes — none of these columns existed, so every insert
-- 42703'd and the features never persisted anything. dosage_mg→dosage,
-- is_active→active, threshold_mg_dl→threshold_value are code-side renames.

BEGIN;

ALTER TABLE diabetes_medications ADD COLUMN IF NOT EXISTS times_of_day JSONB DEFAULT '[]'::jsonb;
ALTER TABLE diabetes_medications ADD COLUMN IF NOT EXISTS with_food BOOLEAN;

ALTER TABLE glucose_alerts ADD COLUMN IF NOT EXISTS notification_method TEXT;
ALTER TABLE glucose_alerts ADD COLUMN IF NOT EXISTS repeat_interval_minutes INT;

COMMIT;
