-- Enhance weekly_summaries with nutrition, readiness, measurement, muscle, and mood data
ALTER TABLE weekly_summaries ADD COLUMN IF NOT EXISTS nutrition_adherence_pct FLOAT;
ALTER TABLE weekly_summaries ADD COLUMN IF NOT EXISTS avg_readiness_score INT;
ALTER TABLE weekly_summaries ADD COLUMN IF NOT EXISTS readiness_trend TEXT;
ALTER TABLE weekly_summaries ADD COLUMN IF NOT EXISTS measurement_changes JSONB DEFAULT '{}';
ALTER TABLE weekly_summaries ADD COLUMN IF NOT EXISTS muscle_group_breakdown JSONB DEFAULT '{}';
ALTER TABLE weekly_summaries ADD COLUMN IF NOT EXISTS mood_distribution JSONB DEFAULT '{}';
ALTER TABLE weekly_summaries ADD COLUMN IF NOT EXISTS chat_message_id UUID;
