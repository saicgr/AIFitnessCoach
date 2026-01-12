-- Migration 141: Add food image storage to food_logs
-- Stores S3 image URLs and tracks source type (text vs image)

-- Add image storage columns to food_logs
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS image_storage_key VARCHAR(500);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS source_type VARCHAR(20) DEFAULT 'text';

-- Index for querying by source type (e.g., find all image-based logs)
CREATE INDEX IF NOT EXISTS idx_food_logs_source_type ON food_logs(source_type);

-- Comment: The food_items JSONB column already stores whatever fields the API returns,
-- so the new weight/count fields (weight_g, unit, count, weight_per_unit_g)
-- will automatically be included without schema changes.
