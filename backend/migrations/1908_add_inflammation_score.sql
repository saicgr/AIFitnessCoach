-- Add inflammation score and ultra-processed tracking to food logs
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS inflammation_score INTEGER CHECK (inflammation_score >= 1 AND inflammation_score <= 10);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS is_ultra_processed BOOLEAN DEFAULT FALSE;

-- Also ensure image_url column exists (for photo log display in nutrition tab)
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS image_url TEXT;
