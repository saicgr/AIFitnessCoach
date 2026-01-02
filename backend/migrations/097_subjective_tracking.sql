-- Migration: Subjective Results Tracking
-- Purpose: Allow users to track how they "feel" before/after workouts
-- This enables personalized insights like "Your mood improved 23% since starting"

-- Create the main subjective feedback table
CREATE TABLE IF NOT EXISTS workout_subjective_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_id UUID REFERENCES generated_workouts(id) ON DELETE CASCADE,

  -- Pre-workout check-in (1-5 scale)
  mood_before INTEGER CHECK (mood_before IS NULL OR mood_before BETWEEN 1 AND 5),
  energy_before INTEGER CHECK (energy_before IS NULL OR energy_before BETWEEN 1 AND 5),
  sleep_quality INTEGER CHECK (sleep_quality IS NULL OR sleep_quality BETWEEN 1 AND 5),
  stress_level INTEGER CHECK (stress_level IS NULL OR stress_level BETWEEN 1 AND 5),

  -- Post-workout check-in (1-5 scale)
  mood_after INTEGER CHECK (mood_after IS NULL OR mood_after BETWEEN 1 AND 5),
  energy_after INTEGER CHECK (energy_after IS NULL OR energy_after BETWEEN 1 AND 5),
  confidence_level INTEGER CHECK (confidence_level IS NULL OR confidence_level BETWEEN 1 AND 5),
  soreness_level INTEGER CHECK (soreness_level IS NULL OR soreness_level BETWEEN 1 AND 5),

  -- Qualitative feedback
  feeling_stronger BOOLEAN DEFAULT FALSE,
  notes TEXT,

  -- Metadata
  pre_checkin_at TIMESTAMPTZ,
  post_checkin_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE workout_subjective_feedback IS 'Tracks subjective user feedback before and after workouts to measure "feel results"';
COMMENT ON COLUMN workout_subjective_feedback.mood_before IS 'Pre-workout mood: 1=awful, 2=low, 3=neutral, 4=good, 5=great';
COMMENT ON COLUMN workout_subjective_feedback.mood_after IS 'Post-workout mood: 1=awful, 2=low, 3=neutral, 4=good, 5=great';
COMMENT ON COLUMN workout_subjective_feedback.energy_before IS 'Pre-workout energy: 1=exhausted, 2=tired, 3=okay, 4=energized, 5=pumped';
COMMENT ON COLUMN workout_subjective_feedback.energy_after IS 'Post-workout energy: 1=drained, 2=tired, 3=good, 4=energized, 5=amazing';
COMMENT ON COLUMN workout_subjective_feedback.sleep_quality IS 'Last night sleep: 1=terrible, 2=poor, 3=okay, 4=good, 5=excellent';
COMMENT ON COLUMN workout_subjective_feedback.stress_level IS 'Current stress: 1=very stressed, 2=stressed, 3=normal, 4=calm, 5=very calm';
COMMENT ON COLUMN workout_subjective_feedback.confidence_level IS 'Feeling stronger/confident: 1=not at all, 5=very confident';
COMMENT ON COLUMN workout_subjective_feedback.soreness_level IS 'Muscle soreness: 1=none, 2=mild, 3=moderate, 4=high, 5=very sore';
COMMENT ON COLUMN workout_subjective_feedback.feeling_stronger IS 'Toggle: Do you feel stronger after this workout?';

-- Row Level Security
ALTER TABLE workout_subjective_feedback ENABLE ROW LEVEL SECURITY;

-- Users can only manage their own feedback
CREATE POLICY "Users can manage own subjective feedback"
  ON workout_subjective_feedback
  FOR ALL
  USING (auth.uid() = user_id);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_subjective_user_id ON workout_subjective_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_subjective_workout_id ON workout_subjective_feedback(workout_id);
CREATE INDEX IF NOT EXISTS idx_subjective_created_at ON workout_subjective_feedback(user_id, created_at DESC);

-- Index for trends queries (mood before vs after)
CREATE INDEX IF NOT EXISTS idx_subjective_trends ON workout_subjective_feedback(user_id, created_at, mood_before, mood_after);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_subjective_feedback_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_subjective_feedback_updated_at
  BEFORE UPDATE ON workout_subjective_feedback
  FOR EACH ROW
  EXECUTE FUNCTION update_subjective_feedback_updated_at();

-- Add daily subjective tracking for non-workout days
-- This allows tracking mood/energy even without a workout
CREATE TABLE IF NOT EXISTS daily_subjective_checkin (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  check_date DATE NOT NULL DEFAULT CURRENT_DATE,

  -- Daily check-in metrics (1-5 scale)
  morning_mood INTEGER CHECK (morning_mood IS NULL OR morning_mood BETWEEN 1 AND 5),
  morning_energy INTEGER CHECK (morning_energy IS NULL OR morning_energy BETWEEN 1 AND 5),
  sleep_quality INTEGER CHECK (sleep_quality IS NULL OR sleep_quality BETWEEN 1 AND 5),
  stress_level INTEGER CHECK (stress_level IS NULL OR stress_level BETWEEN 1 AND 5),

  -- Evening reflection (optional)
  evening_mood INTEGER CHECK (evening_mood IS NULL OR evening_mood BETWEEN 1 AND 5),
  overall_day_rating INTEGER CHECK (overall_day_rating IS NULL OR overall_day_rating BETWEEN 1 AND 5),

  -- Notes
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- One check-in per day per user
  UNIQUE(user_id, check_date)
);

COMMENT ON TABLE daily_subjective_checkin IS 'Daily mood/energy tracking independent of workouts for holistic wellness view';

-- RLS for daily check-ins
ALTER TABLE daily_subjective_checkin ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own daily checkins"
  ON daily_subjective_checkin
  FOR ALL
  USING (auth.uid() = user_id);

-- Index for daily queries
CREATE INDEX IF NOT EXISTS idx_daily_subjective_user_date ON daily_subjective_checkin(user_id, check_date DESC);
