-- Migration: 068_fitness_scores_enhancement.sql
-- Description: Add trend tracking columns to fitness_scores table
-- Created: 2024-12-30

-- ============================================================================
-- ADD MISSING COLUMNS TO FITNESS_SCORES
-- ============================================================================

-- Add previous_score column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'fitness_scores' AND column_name = 'previous_score'
  ) THEN
    ALTER TABLE fitness_scores ADD COLUMN previous_score INTEGER;
  END IF;
END $$;

-- Add score_change column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'fitness_scores' AND column_name = 'score_change'
  ) THEN
    ALTER TABLE fitness_scores ADD COLUMN score_change INTEGER;
  END IF;
END $$;

-- Add trend column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'fitness_scores' AND column_name = 'trend'
  ) THEN
    ALTER TABLE fitness_scores ADD COLUMN trend TEXT CHECK (trend IN ('improving', 'maintaining', 'declining')) DEFAULT 'maintaining';
  END IF;
END $$;

-- Add calculated_at column if not exists (separate from created_at)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'fitness_scores' AND column_name = 'calculated_at'
  ) THEN
    ALTER TABLE fitness_scores ADD COLUMN calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

-- ============================================================================
-- ADD MISSING COLUMNS TO NUTRITION_SCORES
-- ============================================================================

-- Add previous_score column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'nutrition_scores' AND column_name = 'previous_score'
  ) THEN
    ALTER TABLE nutrition_scores ADD COLUMN previous_score INTEGER;
  END IF;
END $$;

-- Add calculated_at column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'nutrition_scores' AND column_name = 'calculated_at'
  ) THEN
    ALTER TABLE nutrition_scores ADD COLUMN calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON COLUMN fitness_scores.previous_score IS 'Previous overall fitness score for trend calculation';
COMMENT ON COLUMN fitness_scores.score_change IS 'Change from previous score (positive = improvement)';
COMMENT ON COLUMN fitness_scores.trend IS 'Score trend: improving, maintaining, or declining';
COMMENT ON COLUMN fitness_scores.calculated_at IS 'When this score was calculated';
COMMENT ON COLUMN nutrition_scores.previous_score IS 'Previous week nutrition score for comparison';
COMMENT ON COLUMN nutrition_scores.calculated_at IS 'When this score was calculated';
