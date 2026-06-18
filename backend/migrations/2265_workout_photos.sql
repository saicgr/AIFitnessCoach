-- Migration: 2265_workout_photos.sql
-- Description: Casual per-workout photos (gym selfie / lift snapshot) captured
--              optionally at workout completion. Foundation for the shareables
--              photo-first flow + slideshow/Strava-photo features.
--              Modeled on progress_photos (migration 055) — same S3 storage_key
--              pattern, presigned-URL serving, and RLS shape.
-- Created: 2026-06-18

-- ============================================================================
-- WORKOUT PHOTOS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS workout_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Optional link to the workout this photo was taken for. Nullable so a photo
  -- can be captured even when the completion screen has no persisted workout id.
  workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,

  -- Photo information
  photo_url TEXT NOT NULL,            -- Public/base S3 URL (presigned on read)
  thumbnail_url TEXT,                 -- Optional smaller version for quick loading
  storage_key TEXT NOT NULL,          -- S3 key for presigning + deletion

  -- Metadata
  taken_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  caption TEXT,

  -- Visibility (mirrors progress_photos)
  visibility TEXT DEFAULT 'private' CHECK (visibility IN ('private', 'shared', 'public')),

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workout_photos_user_date ON workout_photos(user_id, taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_workout_photos_workout ON workout_photos(workout_id);

-- Enable Row Level Security
ALTER TABLE workout_photos ENABLE ROW LEVEL SECURITY;

-- RLS Policies (consistent with progress_photos)
DROP POLICY IF EXISTS workout_photos_select_policy ON workout_photos;
CREATE POLICY workout_photos_select_policy ON workout_photos
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR visibility = 'public'
    OR (visibility = 'shared' AND auth.role() = 'authenticated')
  );

DROP POLICY IF EXISTS workout_photos_insert_policy ON workout_photos;
CREATE POLICY workout_photos_insert_policy ON workout_photos
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS workout_photos_update_policy ON workout_photos;
CREATE POLICY workout_photos_update_policy ON workout_photos
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS workout_photos_delete_policy ON workout_photos;
CREATE POLICY workout_photos_delete_policy ON workout_photos
  FOR DELETE
  USING (auth.uid() = user_id);

-- Service role can manage all (backend uses the service key)
DROP POLICY IF EXISTS workout_photos_service_policy ON workout_photos;
CREATE POLICY workout_photos_service_policy ON workout_photos
  FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_workout_photos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_workout_photos_updated_at ON workout_photos;
CREATE TRIGGER trigger_update_workout_photos_updated_at
  BEFORE UPDATE ON workout_photos
  FOR EACH ROW EXECUTE FUNCTION update_workout_photos_updated_at();

COMMENT ON TABLE workout_photos IS 'Casual per-workout photos (gym selfie / lift snapshot) captured optionally at completion';
