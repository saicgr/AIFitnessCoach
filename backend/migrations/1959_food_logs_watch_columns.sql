-- Migration: Add watch-sync columns to food_logs
-- Purpose: watch_sync.py inserts food_name / raw_input / input_type but these
-- columns were never added. Inserts from the watch path were silently failing
-- with "column does not exist" (42703).

ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS food_name TEXT;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS raw_input TEXT;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS input_type VARCHAR(20);

COMMENT ON COLUMN food_logs.food_name IS 'Single-item display name when logged via watch/voice/text (not JSONB).';
COMMENT ON COLUMN food_logs.raw_input IS 'Original user input (voice transcript or typed text) before AI parsing.';
COMMENT ON COLUMN food_logs.input_type IS 'Source input type: voice, text, barcode, image.';
