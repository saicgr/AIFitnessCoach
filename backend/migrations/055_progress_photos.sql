-- Migration: 055_progress_photos.sql
-- Description: Add progress photos tracking for visual progress documentation
-- Created: 2024-12-29

-- ============================================================================
-- PROGRESS PHOTOS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS progress_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Photo information
  photo_url TEXT NOT NULL,
  thumbnail_url TEXT, -- Smaller version for quick loading
  storage_key TEXT NOT NULL, -- S3/Storage key for deletion

  -- View type (required)
  view_type TEXT NOT NULL CHECK (view_type IN ('front', 'side_left', 'side_right', 'back')),

  -- Metadata
  taken_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  body_weight_kg DOUBLE PRECISION, -- Optional weight at time of photo
  notes TEXT,

  -- Link to body measurements (optional)
  measurement_id UUID REFERENCES body_measurements(id) ON DELETE SET NULL,

  -- Photo quality/visibility settings
  is_comparison_ready BOOLEAN DEFAULT true, -- Can be used in before/after
  visibility TEXT DEFAULT 'private' CHECK (visibility IN ('private', 'shared', 'public')),

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_progress_photos_user_id ON progress_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_photos_user_date ON progress_photos(user_id, taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_progress_photos_view_type ON progress_photos(user_id, view_type, taken_at DESC);

-- Enable Row Level Security
ALTER TABLE progress_photos ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS progress_photos_select_policy ON progress_photos;
CREATE POLICY progress_photos_select_policy ON progress_photos
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR visibility = 'public'
    OR (visibility = 'shared' AND auth.role() = 'authenticated')
  );

DROP POLICY IF EXISTS progress_photos_insert_policy ON progress_photos;
CREATE POLICY progress_photos_insert_policy ON progress_photos
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS progress_photos_update_policy ON progress_photos;
CREATE POLICY progress_photos_update_policy ON progress_photos
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS progress_photos_delete_policy ON progress_photos;
CREATE POLICY progress_photos_delete_policy ON progress_photos
  FOR DELETE
  USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS progress_photos_service_policy ON progress_photos;
CREATE POLICY progress_photos_service_policy ON progress_photos
  FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- PHOTO COMPARISONS TABLE (Before/After sets)
-- ============================================================================

CREATE TABLE IF NOT EXISTS photo_comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Before/After photos
  before_photo_id UUID NOT NULL REFERENCES progress_photos(id) ON DELETE CASCADE,
  after_photo_id UUID NOT NULL REFERENCES progress_photos(id) ON DELETE CASCADE,

  -- Comparison metadata
  title TEXT,
  description TEXT,

  -- Stats at comparison time
  weight_change_kg DOUBLE PRECISION,
  days_between INTEGER,

  -- Sharing settings
  is_featured BOOLEAN DEFAULT false,
  visibility TEXT DEFAULT 'private' CHECK (visibility IN ('private', 'shared', 'public')),

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_photo_comparisons_user ON photo_comparisons(user_id);

-- Enable Row Level Security
ALTER TABLE photo_comparisons ENABLE ROW LEVEL SECURITY;

-- RLS Policies for comparisons
DROP POLICY IF EXISTS photo_comparisons_select_policy ON photo_comparisons;
CREATE POLICY photo_comparisons_select_policy ON photo_comparisons
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR visibility = 'public'
  );

DROP POLICY IF EXISTS photo_comparisons_insert_policy ON photo_comparisons;
CREATE POLICY photo_comparisons_insert_policy ON photo_comparisons
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS photo_comparisons_update_policy ON photo_comparisons;
CREATE POLICY photo_comparisons_update_policy ON photo_comparisons
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS photo_comparisons_delete_policy ON photo_comparisons;
CREATE POLICY photo_comparisons_delete_policy ON photo_comparisons
  FOR DELETE
  USING (auth.uid() = user_id);

-- Service role
DROP POLICY IF EXISTS photo_comparisons_service_policy ON photo_comparisons;
CREATE POLICY photo_comparisons_service_policy ON photo_comparisons
  FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_progress_photos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_progress_photos_updated_at ON progress_photos;
CREATE TRIGGER trigger_update_progress_photos_updated_at
  BEFORE UPDATE ON progress_photos
  FOR EACH ROW EXECUTE FUNCTION update_progress_photos_updated_at();

-- ============================================================================
-- HELPFUL VIEWS
-- ============================================================================

-- Latest photos by view type for each user
CREATE OR REPLACE VIEW latest_progress_photos AS
SELECT DISTINCT ON (user_id, view_type)
  id,
  user_id,
  photo_url,
  thumbnail_url,
  view_type,
  taken_at,
  body_weight_kg,
  notes
FROM progress_photos
ORDER BY user_id, view_type, taken_at DESC;

-- Photo count stats per user
CREATE OR REPLACE VIEW progress_photo_stats AS
SELECT
  user_id,
  COUNT(*) as total_photos,
  COUNT(DISTINCT view_type) as view_types_captured,
  MIN(taken_at) as first_photo_date,
  MAX(taken_at) as latest_photo_date,
  COUNT(DISTINCT DATE(taken_at)) as days_with_photos
FROM progress_photos
GROUP BY user_id;

-- Grant select on views
GRANT SELECT ON latest_progress_photos TO authenticated;
GRANT SELECT ON progress_photo_stats TO authenticated;

COMMENT ON TABLE progress_photos IS 'User progress photos for visual tracking';
COMMENT ON TABLE photo_comparisons IS 'Before/after photo comparison pairs';
COMMENT ON VIEW latest_progress_photos IS 'Most recent photo for each view type per user';
COMMENT ON VIEW progress_photo_stats IS 'Photo statistics per user';
