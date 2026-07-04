-- Migration 2307: Diabetes write-path repair.
--
-- Every diabetes logging insert (glucose, insulin, A1C, carbs) wrote at least
-- one phantom column, so PostgREST rejected the WHOLE insert (42703) — user-
-- logged diabetes data was never persisted. Where a real semantic equivalent
-- exists the CODE is renamed to it (timestamp→recorded_at,
-- glucose_mg_dl→value_mg_dl, a1c_value→value, source→source_device); the
-- fields below have NO equivalent, so we add columns rather than drop
-- user-logged data.
--
-- carb_entries.glucose_before/glucose_after also un-degrades the
-- carb→glucose correlation endpoint (blood-sugar rise per 10g carbs).

BEGIN;

ALTER TABLE insulin_doses ADD COLUMN IF NOT EXISTS dose_type TEXT;
ALTER TABLE insulin_doses ADD COLUMN IF NOT EXISTS associated_meal TEXT;
ALTER TABLE insulin_doses ADD COLUMN IF NOT EXISTS carbs_covered NUMERIC;
ALTER TABLE insulin_doses ADD COLUMN IF NOT EXISTS glucose_before INT;
ALTER TABLE insulin_doses ADD COLUMN IF NOT EXISTS correction_included BOOLEAN DEFAULT FALSE;

ALTER TABLE a1c_records ADD COLUMN IF NOT EXISTS estimated_avg_glucose NUMERIC;
ALTER TABLE a1c_records ADD COLUMN IF NOT EXISTS source TEXT;

ALTER TABLE carb_entries ADD COLUMN IF NOT EXISTS glucose_before INT;
ALTER TABLE carb_entries ADD COLUMN IF NOT EXISTS glucose_after INT;
ALTER TABLE carb_entries ADD COLUMN IF NOT EXISTS insulin_dose NUMERIC;
ALTER TABLE carb_entries ADD COLUMN IF NOT EXISTS food_items JSONB;

ALTER TABLE glucose_readings ADD COLUMN IF NOT EXISTS device_id TEXT;

COMMIT;
