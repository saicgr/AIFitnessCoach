-- Migration: 062_exercise_library_unilateral.sql
-- Description: Add is_unilateral and default_hold_seconds to exercise_library table
-- This enables filtering library exercises by unilateral status and specifying hold times for stretches

-- Add is_unilateral column to exercise_library
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS is_unilateral BOOLEAN DEFAULT false;

-- Add default_hold_seconds for stretching/mobility exercises
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_hold_seconds INTEGER;

-- Create index for filtering unilateral exercises
CREATE INDEX IF NOT EXISTS idx_exercise_library_unilateral ON exercise_library(is_unilateral) WHERE is_unilateral = true;

-- Update existing exercises based on known unilateral patterns
-- Single-arm exercises
UPDATE exercise_library
SET is_unilateral = true
WHERE exercise_name ILIKE '%single arm%'
   OR exercise_name ILIKE '%single-arm%'
   OR exercise_name ILIKE '%one arm%'
   OR exercise_name ILIKE '%one-arm%'
   OR exercise_name ILIKE '%unilateral%';

-- Single-leg exercises
UPDATE exercise_library
SET is_unilateral = true
WHERE exercise_name ILIKE '%single leg%'
   OR exercise_name ILIKE '%single-leg%'
   OR exercise_name ILIKE '%one leg%'
   OR exercise_name ILIKE '%one-leg%';

-- Alternating exercises (typically unilateral)
UPDATE exercise_library
SET is_unilateral = true
WHERE exercise_name ILIKE '%alternating%';

-- Lunge variations (unilateral)
UPDATE exercise_library
SET is_unilateral = true
WHERE exercise_name ILIKE '%lunge%'
   AND exercise_name NOT ILIKE '%double%';

-- Step-up variations (unilateral)
UPDATE exercise_library
SET is_unilateral = true
WHERE exercise_name ILIKE '%step up%'
   OR exercise_name ILIKE '%step-up%';

-- Bulgarian split squat (unilateral)
UPDATE exercise_library
SET is_unilateral = true
WHERE exercise_name ILIKE '%bulgarian%'
   OR exercise_name ILIKE '%split squat%';

-- Pistol squat (unilateral)
UPDATE exercise_library
SET is_unilateral = true
WHERE exercise_name ILIKE '%pistol%';

-- Single dumbbell friendly exercises are often unilateral
UPDATE exercise_library
SET is_unilateral = true
WHERE single_dumbbell_friendly = true
  AND is_unilateral = false;

-- Set default hold_seconds for stretching exercises (category = 'Stretching' or 'Yoga')
UPDATE exercise_library
SET default_hold_seconds = 30
WHERE (category ILIKE '%stretch%' OR category ILIKE '%yoga%' OR category ILIKE '%flexibility%')
  AND default_hold_seconds IS NULL;

-- Add comments
COMMENT ON COLUMN exercise_library.is_unilateral IS 'Whether exercise works one side at a time (single-arm, single-leg)';
COMMENT ON COLUMN exercise_library.default_hold_seconds IS 'Default hold duration for static stretches and yoga poses';
