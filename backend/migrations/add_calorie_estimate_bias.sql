-- Migration: Add calorie estimate bias to nutrition preferences
-- This allows users to adjust AI calorie estimates up or down
-- Values: -2 (much less), -1 (less), 0 (default), 1 (more), 2 (much more)

ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS calorie_estimate_bias INTEGER DEFAULT 0;
