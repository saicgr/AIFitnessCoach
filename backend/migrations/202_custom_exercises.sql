-- Migration: 202_custom_exercises.sql
-- Created: 2025-02-01
-- Purpose: Add custom exercises table for user-defined exercises
-- Features:
--   - Users can create exercises for equipment not in library
--   - Upload images/videos to Supabase Storage
--   - Mark exercises as suitable for warmup/stretch/cooldown
--   - Optional sharing with other users (is_public)

-- ============================================
-- TABLE: custom_exercises
-- ============================================

CREATE TABLE IF NOT EXISTS custom_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Exercise details
    name TEXT NOT NULL,
    description TEXT,
    instructions TEXT,

    -- Classification
    body_part TEXT,  -- 'chest', 'back', 'legs', 'cardio', 'full body', etc.
    target_muscles TEXT[],  -- ['quadriceps', 'glutes']
    secondary_muscles TEXT[],  -- ['calves', 'core']
    equipment TEXT NOT NULL,  -- 'treadmill', 'smith_machine', etc.
    exercise_type TEXT DEFAULT 'strength' CHECK (exercise_type IN ('strength', 'cardio', 'warmup', 'stretch', 'mobility', 'plyometric')),
    movement_type TEXT DEFAULT 'dynamic' CHECK (movement_type IN ('static', 'dynamic', 'isometric')),
    difficulty_level TEXT DEFAULT 'intermediate' CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),

    -- Defaults for workout generation
    default_sets INTEGER DEFAULT 3,
    default_reps INTEGER,  -- NULL for time-based exercises
    default_duration_seconds INTEGER,  -- NULL for rep-based exercises
    default_rest_seconds INTEGER DEFAULT 60,

    -- Media (user uploads to Supabase Storage)
    image_url TEXT,  -- Supabase Storage URL or NULL (show placeholder)
    video_url TEXT,  -- Supabase Storage URL or NULL
    thumbnail_url TEXT,  -- Auto-generated or uploaded thumbnail

    -- Categorization for warmup/stretch algorithm
    is_warmup_suitable BOOLEAN DEFAULT FALSE,
    is_stretch_suitable BOOLEAN DEFAULT FALSE,
    is_cooldown_suitable BOOLEAN DEFAULT FALSE,

    -- Visibility
    is_public BOOLEAN DEFAULT FALSE,  -- Share with other users

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Unique constraint: user can't have duplicate exercise names
    UNIQUE(user_id, name)
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_custom_exercises_user_id
    ON custom_exercises(user_id);

CREATE INDEX IF NOT EXISTS idx_custom_exercises_equipment
    ON custom_exercises(equipment);

CREATE INDEX IF NOT EXISTS idx_custom_exercises_body_part
    ON custom_exercises(body_part);

CREATE INDEX IF NOT EXISTS idx_custom_exercises_exercise_type
    ON custom_exercises(exercise_type);

CREATE INDEX IF NOT EXISTS idx_custom_exercises_is_public
    ON custom_exercises(is_public) WHERE is_public = TRUE;

CREATE INDEX IF NOT EXISTS idx_custom_exercises_warmup_suitable
    ON custom_exercises(is_warmup_suitable) WHERE is_warmup_suitable = TRUE;

CREATE INDEX IF NOT EXISTS idx_custom_exercises_stretch_suitable
    ON custom_exercises(is_stretch_suitable) WHERE is_stretch_suitable = TRUE;

-- GIN index for array searching on target_muscles
CREATE INDEX IF NOT EXISTS idx_custom_exercises_target_muscles
    ON custom_exercises USING GIN(target_muscles);

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE custom_exercises ENABLE ROW LEVEL SECURITY;

-- Users can view their own custom exercises OR public exercises
CREATE POLICY "Users can view own or public custom_exercises"
    ON custom_exercises FOR SELECT
    USING (
        user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        OR is_public = TRUE
    );

-- Users can insert their own custom exercises
CREATE POLICY "Users can insert own custom_exercises"
    ON custom_exercises FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can update their own custom exercises
CREATE POLICY "Users can update own custom_exercises"
    ON custom_exercises FOR UPDATE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can delete their own custom exercises
CREATE POLICY "Users can delete own custom_exercises"
    ON custom_exercises FOR DELETE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Service role has full access
CREATE POLICY "Service role full access custom_exercises"
    ON custom_exercises FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- TRIGGER: Update updated_at on modification
-- ============================================

CREATE OR REPLACE FUNCTION update_custom_exercises_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trigger_custom_exercises_updated_at ON custom_exercises;
CREATE TRIGGER trigger_custom_exercises_updated_at
    BEFORE UPDATE ON custom_exercises
    FOR EACH ROW
    EXECUTE FUNCTION update_custom_exercises_updated_at();

-- ============================================
-- SUPABASE STORAGE BUCKET
-- ============================================

-- Note: Storage bucket creation requires Supabase Dashboard or API
-- This is a placeholder for documentation

-- Bucket: custom-exercise-media
-- Structure: {user_id}/{exercise_id}/image.jpg
--            {user_id}/{exercise_id}/video.mp4
--            {user_id}/{exercise_id}/thumbnail.jpg

-- Storage policies (apply via Supabase Dashboard):
-- 1. Users can upload to their own folder: custom-exercise-media/{user_id}/*
-- 2. Anyone can view public bucket contents
-- 3. Users can delete their own media

-- ============================================
-- VIEW: Combined exercise library (library + custom)
-- ============================================

CREATE OR REPLACE VIEW all_exercises_combined AS
SELECT
    id,
    exercise_name AS name,
    body_part,
    target_muscle,
    secondary_muscles,
    equipment,
    COALESCE(category, 'strength') AS exercise_type,
    'dynamic' AS movement_type,  -- Default for library exercises
    difficulty_level,
    instructions,
    gif_url AS image_url,
    video_s3_path AS video_url,
    NULL::INTEGER AS default_sets,
    NULL::INTEGER AS default_reps,
    NULL::INTEGER AS default_duration_seconds,
    NULL::INTEGER AS default_rest_seconds,
    FALSE AS is_warmup_suitable,
    FALSE AS is_stretch_suitable,
    FALSE AS is_cooldown_suitable,
    FALSE AS is_custom,
    NULL::UUID AS owner_user_id,
    created_at
FROM exercise_library

UNION ALL

SELECT
    id,
    name,
    body_part,
    target_muscles[1] AS target_muscle,  -- Primary muscle
    secondary_muscles,
    equipment,
    exercise_type,
    movement_type,
    difficulty_level,
    instructions,
    image_url,
    video_url,
    default_sets,
    default_reps,
    default_duration_seconds,
    default_rest_seconds,
    is_warmup_suitable,
    is_stretch_suitable,
    is_cooldown_suitable,
    TRUE AS is_custom,
    user_id AS owner_user_id,
    created_at
FROM custom_exercises
WHERE is_public = TRUE;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE custom_exercises IS 'User-created exercises for equipment not in the main library';
COMMENT ON COLUMN custom_exercises.target_muscles IS 'Primary muscles targeted by this exercise';
COMMENT ON COLUMN custom_exercises.secondary_muscles IS 'Secondary muscles engaged during the exercise';
COMMENT ON COLUMN custom_exercises.default_reps IS 'Default rep count (NULL for time-based exercises)';
COMMENT ON COLUMN custom_exercises.default_duration_seconds IS 'Default duration in seconds (NULL for rep-based exercises)';
COMMENT ON COLUMN custom_exercises.is_warmup_suitable IS 'Can this exercise be used as a warmup?';
COMMENT ON COLUMN custom_exercises.is_stretch_suitable IS 'Can this exercise be used as a stretch?';
COMMENT ON COLUMN custom_exercises.is_cooldown_suitable IS 'Can this exercise be used for cooldown?';
COMMENT ON COLUMN custom_exercises.is_public IS 'Share this exercise with other users';
COMMENT ON VIEW all_exercises_combined IS 'Combined view of exercise_library and public custom_exercises';
