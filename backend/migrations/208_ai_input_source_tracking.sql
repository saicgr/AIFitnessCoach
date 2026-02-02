-- Migration: Add AI input source tracking to performance logs
-- This tracks the original text/input that was parsed by AI to create a set
-- Examples: "135*8", "+10", "same", "drop 20"

-- Add ai_input_source column to performance_logs table
ALTER TABLE performance_logs
ADD COLUMN IF NOT EXISTS ai_input_source TEXT;

-- Add comment for documentation
COMMENT ON COLUMN performance_logs.ai_input_source IS 'Original AI input text that created this set (e.g., "135*8", "+10", "same"). NULL if manually entered.';

-- Create index for analytics queries (finding AI-created sets)
CREATE INDEX IF NOT EXISTS idx_performance_logs_ai_input_source
ON performance_logs(ai_input_source)
WHERE ai_input_source IS NOT NULL;
