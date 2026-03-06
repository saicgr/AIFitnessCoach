-- Add data_source, food_log_id, and user_email columns to food_reports
ALTER TABLE food_reports ADD COLUMN IF NOT EXISTS data_source TEXT;
ALTER TABLE food_reports ADD COLUMN IF NOT EXISTS food_log_id UUID;
ALTER TABLE food_reports ADD COLUMN IF NOT EXISTS user_email TEXT;
