-- Add mood emoji and notes to readiness_scores for unified wellness check-in
ALTER TABLE readiness_scores ADD COLUMN IF NOT EXISTS mood_emoji VARCHAR(10);
ALTER TABLE readiness_scores ADD COLUMN IF NOT EXISTS notes TEXT;
