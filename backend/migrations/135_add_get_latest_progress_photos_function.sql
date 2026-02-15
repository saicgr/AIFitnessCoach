-- ============================================================================
-- Migration 135: Add get_latest_progress_photos function
-- ============================================================================
-- Creates the RPC function that the backend expects for fetching
-- the latest progress photo for each view type per user.
-- ============================================================================

-- Create the function to get latest progress photos
CREATE OR REPLACE FUNCTION get_latest_progress_photos(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  photo_url TEXT,
  thumbnail_url TEXT,
  view_type TEXT,
  taken_at TIMESTAMP WITH TIME ZONE,
  body_weight_kg DOUBLE PRECISION,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  storage_key TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT ON (view_type)
    id,
    user_id,
    photo_url,
    thumbnail_url,
    view_type,
    taken_at,
    body_weight_kg,
    notes,
    created_at,
    storage_key
  FROM progress_photos
  WHERE user_id = p_user_id
  ORDER BY view_type, taken_at DESC;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_latest_progress_photos(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_latest_progress_photos(UUID) TO service_role;

COMMENT ON FUNCTION get_latest_progress_photos IS 'Get the latest progress photo for each view type for a user';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
