-- Add notes column to food_logs table for user annotations
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS notes TEXT;
