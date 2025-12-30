-- Migration 064: Percentage-Based 1RM Training System
-- Allows users to store their 1RMs and train at a percentage of their max

-- User-stored 1RMs (manually entered or auto-calculated from workout history)
CREATE TABLE IF NOT EXISTS user_exercise_1rms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  one_rep_max_kg DECIMAL(6,2) NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('manual', 'calculated', 'tested')),
  confidence DECIMAL(3,2) DEFAULT 1.0,  -- 0.0 to 1.0, higher = more confident
  last_tested_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, exercise_name)
);

-- Global training intensity preference (percentage of 1RM to train at)
ALTER TABLE users ADD COLUMN IF NOT EXISTS training_intensity_percent INTEGER DEFAULT 75
  CHECK (training_intensity_percent BETWEEN 50 AND 100);

-- Per-exercise intensity overrides (e.g., user wants 70% for bench but 80% for squat)
CREATE TABLE IF NOT EXISTS exercise_intensity_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  intensity_percent INTEGER NOT NULL CHECK (intensity_percent BETWEEN 50 AND 100),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, exercise_name)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_1rms_user ON user_exercise_1rms(user_id);
CREATE INDEX IF NOT EXISTS idx_user_1rms_exercise ON user_exercise_1rms(user_id, exercise_name);
CREATE INDEX IF NOT EXISTS idx_exercise_intensity_user ON exercise_intensity_overrides(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_intensity_exercise ON exercise_intensity_overrides(user_id, exercise_name);

-- Row Level Security
ALTER TABLE user_exercise_1rms ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_intensity_overrides ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_exercise_1rms
CREATE POLICY user_exercise_1rms_select ON user_exercise_1rms
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY user_exercise_1rms_insert ON user_exercise_1rms
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_exercise_1rms_update ON user_exercise_1rms
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY user_exercise_1rms_delete ON user_exercise_1rms
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for exercise_intensity_overrides
CREATE POLICY exercise_intensity_overrides_select ON exercise_intensity_overrides
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY exercise_intensity_overrides_insert ON exercise_intensity_overrides
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY exercise_intensity_overrides_update ON exercise_intensity_overrides
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY exercise_intensity_overrides_delete ON exercise_intensity_overrides
  FOR DELETE USING (auth.uid() = user_id);

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_1rm_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_user_exercise_1rms_updated_at ON user_exercise_1rms;
CREATE TRIGGER update_user_exercise_1rms_updated_at
  BEFORE UPDATE ON user_exercise_1rms
  FOR EACH ROW EXECUTE FUNCTION update_1rm_updated_at();

DROP TRIGGER IF EXISTS update_exercise_intensity_overrides_updated_at ON exercise_intensity_overrides;
CREATE TRIGGER update_exercise_intensity_overrides_updated_at
  BEFORE UPDATE ON exercise_intensity_overrides
  FOR EACH ROW EXECUTE FUNCTION update_1rm_updated_at();

-- Service role policies (for backend API access)
CREATE POLICY user_exercise_1rms_service_all ON user_exercise_1rms
  FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY exercise_intensity_overrides_service_all ON exercise_intensity_overrides
  FOR ALL TO service_role USING (true) WITH CHECK (true);
