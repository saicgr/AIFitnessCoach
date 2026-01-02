-- Migration: 085_feedback_difficulty_adjustment
-- Description: Track difficulty adjustments applied based on user feedback
-- Date: 2025-12-30

-- Create table to track difficulty adjustments applied based on feedback
CREATE TABLE IF NOT EXISTS difficulty_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    adjustment_score INTEGER NOT NULL CHECK (adjustment_score BETWEEN -2 AND 2),
    feedback_count INTEGER NOT NULL DEFAULT 0,
    too_easy_count INTEGER NOT NULL DEFAULT 0,
    just_right_count INTEGER NOT NULL DEFAULT 0,
    too_hard_count INTEGER NOT NULL DEFAULT 0,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for querying user's adjustment history efficiently
-- Orders by applied_at DESC to quickly fetch most recent adjustments
CREATE INDEX IF NOT EXISTS idx_difficulty_adjustments_user ON difficulty_adjustments(user_id, applied_at DESC);

-- Index for analyzing adjustments by workout
CREATE INDEX IF NOT EXISTS idx_difficulty_adjustments_workout ON difficulty_adjustments(workout_id) WHERE workout_id IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE difficulty_adjustments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can only view their own adjustment history
CREATE POLICY "Users can view own adjustments" ON difficulty_adjustments
    FOR SELECT USING (auth.uid() = user_id);

-- Service role can insert adjustments (backend creates these based on feedback analysis)
CREATE POLICY "Service can insert adjustments" ON difficulty_adjustments
    FOR INSERT WITH CHECK (true);

-- Users can delete their own adjustment history (for data management)
CREATE POLICY "Users can delete own adjustments" ON difficulty_adjustments
    FOR DELETE USING (auth.uid() = user_id);

-- Table documentation
COMMENT ON TABLE difficulty_adjustments IS 'Tracks difficulty adjustments applied based on user feedback';
COMMENT ON COLUMN difficulty_adjustments.adjustment_score IS 'Score from -2 (much easier) to +2 (much harder)';
COMMENT ON COLUMN difficulty_adjustments.feedback_count IS 'Total number of feedback entries analyzed';
COMMENT ON COLUMN difficulty_adjustments.too_easy_count IS 'Number of "too easy" responses in analyzed feedback';
COMMENT ON COLUMN difficulty_adjustments.just_right_count IS 'Number of "just right" responses in analyzed feedback';
COMMENT ON COLUMN difficulty_adjustments.too_hard_count IS 'Number of "too hard" responses in analyzed feedback';
COMMENT ON COLUMN difficulty_adjustments.applied_at IS 'Timestamp when this adjustment was applied';
COMMENT ON COLUMN difficulty_adjustments.workout_id IS 'Optional reference to the workout that triggered this adjustment';
