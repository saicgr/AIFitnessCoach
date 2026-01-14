-- Migration 153: Stats Gallery
-- Creates stats_gallery table for shareable stats images

-- ============================================================================
-- Stats Gallery Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS stats_gallery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    template_type TEXT NOT NULL CHECK (template_type IN ('overview', 'achievements', 'prs')),
    stats_snapshot JSONB,
    date_range_start DATE,
    date_range_end DATE,
    prs_data JSONB DEFAULT '[]'::jsonb,
    achievements_data JSONB DEFAULT '[]'::jsonb,
    shared_to_feed BOOLEAN DEFAULT FALSE,
    shared_externally BOOLEAN DEFAULT FALSE,
    external_shares_count INTEGER DEFAULT 0,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_stats_gallery_user_id ON stats_gallery(user_id);
CREATE INDEX IF NOT EXISTS idx_stats_gallery_created_at ON stats_gallery(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stats_gallery_template_type ON stats_gallery(template_type);
CREATE INDEX IF NOT EXISTS idx_stats_gallery_deleted_at ON stats_gallery(deleted_at) WHERE deleted_at IS NULL;

-- Add comment
COMMENT ON TABLE stats_gallery IS 'Stores shareable stats images for social sharing';

-- ============================================================================
-- Row Level Security
-- ============================================================================

ALTER TABLE stats_gallery ENABLE ROW LEVEL SECURITY;

-- Users can view their own stats gallery images
CREATE POLICY "Users can view own stats gallery"
    ON stats_gallery
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own stats gallery images
CREATE POLICY "Users can insert own stats gallery"
    ON stats_gallery
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own stats gallery images
CREATE POLICY "Users can update own stats gallery"
    ON stats_gallery
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete (soft delete) their own stats gallery images
CREATE POLICY "Users can delete own stats gallery"
    ON stats_gallery
    FOR DELETE
    USING (auth.uid() = user_id);

-- Service role can manage all stats gallery images
CREATE POLICY "Service role full access to stats gallery"
    ON stats_gallery
    FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================================================
-- Updated At Trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION update_stats_gallery_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_stats_gallery_updated_at ON stats_gallery;
CREATE TRIGGER trigger_stats_gallery_updated_at
    BEFORE UPDATE ON stats_gallery
    FOR EACH ROW
    EXECUTE FUNCTION update_stats_gallery_updated_at();

-- ============================================================================
-- Grant Permissions
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON stats_gallery TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON stats_gallery TO service_role;
