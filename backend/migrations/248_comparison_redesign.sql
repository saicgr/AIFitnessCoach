-- Migration: 248_comparison_redesign.sql
-- Description: Extend photo_comparisons table to support N-photo layouts,
--              customization settings, AI summaries, and re-editable comparisons
-- Created: 2026-02-16

-- ============================================================================
-- ADD NEW COLUMNS TO photo_comparisons
-- ============================================================================

ALTER TABLE photo_comparisons
  ADD COLUMN IF NOT EXISTS photos_json JSONB,
  ADD COLUMN IF NOT EXISTS layout TEXT DEFAULT 'side_by_side',
  ADD COLUMN IF NOT EXISTS settings_json JSONB,
  ADD COLUMN IF NOT EXISTS exported_image_url TEXT,
  ADD COLUMN IF NOT EXISTS ai_summary TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Add updated_at trigger for photo_comparisons
CREATE OR REPLACE FUNCTION update_photo_comparisons_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_photo_comparisons_updated_at ON photo_comparisons;
CREATE TRIGGER trigger_update_photo_comparisons_updated_at
  BEFORE UPDATE ON photo_comparisons
  FOR EACH ROW EXECUTE FUNCTION update_photo_comparisons_updated_at();

-- Index on layout for filtering
CREATE INDEX IF NOT EXISTS idx_photo_comparisons_layout
  ON photo_comparisons(user_id, layout);

-- Index on updated_at for sorting
CREATE INDEX IF NOT EXISTS idx_photo_comparisons_updated
  ON photo_comparisons(user_id, updated_at DESC);

COMMENT ON COLUMN photo_comparisons.photos_json IS 'Ordered list of photo references: [{photo_id, order, label}]';
COMMENT ON COLUMN photo_comparisons.layout IS 'Layout template: side_by_side, slider, vertical_stack, story, diagonal_split, polaroid, triptych, four_panel, monthly_grid';
COMMENT ON COLUMN photo_comparisons.settings_json IS 'Customization settings: {showLogo, logoPosition, showStats, backgroundColor, exportAspectRatio, ...}';
COMMENT ON COLUMN photo_comparisons.exported_image_url IS 'URL of last exported comparison image';
COMMENT ON COLUMN photo_comparisons.ai_summary IS 'AI-generated progress summary text';
