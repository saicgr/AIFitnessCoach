-- Migration: 043_workout_gallery.sql
-- Description: Add workout gallery for shareable workout recap images
-- Created: 2025-12-26

-- ============================================
-- WORKOUT GALLERY IMAGES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS workout_gallery_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_log_id UUID REFERENCES workout_logs(id) ON DELETE SET NULL,

    -- Image data
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    template_type VARCHAR(50) NOT NULL CHECK (template_type IN ('stats', 'prs', 'photo_overlay', 'motivational')),

    -- Workout snapshot (denormalized for display even if workout deleted)
    workout_name VARCHAR(255),
    duration_seconds INT,
    calories INT,
    total_volume_kg DECIMAL(10,2),
    total_sets INT,
    total_reps INT,
    exercises_count INT,

    -- Optional user photo (for photo_overlay template)
    user_photo_url TEXT,

    -- PRs/achievements captured (for prs template)
    prs_data JSONB DEFAULT '[]',
    achievements_data JSONB DEFAULT '[]',

    -- Sharing tracking
    shared_to_feed BOOLEAN DEFAULT FALSE,
    shared_externally BOOLEAN DEFAULT FALSE,
    external_shares_count INT DEFAULT 0,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ  -- Soft delete
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_workout_gallery_user ON workout_gallery_images(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_gallery_workout ON workout_gallery_images(workout_log_id);
CREATE INDEX IF NOT EXISTS idx_workout_gallery_created ON workout_gallery_images(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workout_gallery_template ON workout_gallery_images(template_type);
CREATE INDEX IF NOT EXISTS idx_workout_gallery_not_deleted ON workout_gallery_images(user_id) WHERE deleted_at IS NULL;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE workout_gallery_images ENABLE ROW LEVEL SECURITY;

-- Users can view their own gallery images
CREATE POLICY "Users can view own gallery images" ON workout_gallery_images
    FOR SELECT USING (auth.uid()::text = user_id::text);

-- Users can insert their own gallery images
CREATE POLICY "Users can insert own gallery images" ON workout_gallery_images
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

-- Users can update their own gallery images
CREATE POLICY "Users can update own gallery images" ON workout_gallery_images
    FOR UPDATE USING (auth.uid()::text = user_id::text);

-- Users can delete their own gallery images
CREATE POLICY "Users can delete own gallery images" ON workout_gallery_images
    FOR DELETE USING (auth.uid()::text = user_id::text);

-- ============================================
-- UPDATED_AT TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION update_workout_gallery_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS workout_gallery_updated_at ON workout_gallery_images;
CREATE TRIGGER workout_gallery_updated_at
    BEFORE UPDATE ON workout_gallery_images
    FOR EACH ROW
    EXECUTE FUNCTION update_workout_gallery_updated_at();

-- ============================================
-- STORAGE BUCKET (Note: Run this in Supabase dashboard)
-- ============================================
-- Create storage bucket 'workout-recaps' with:
-- - Public access for image URLs
-- - Max file size: 5MB
-- - Allowed MIME types: image/png, image/jpeg
-- Path structure: {user_id}/{workout_log_id}/{template_type}_{timestamp}.png

-- Storage policies (run in Supabase SQL editor):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('workout-recaps', 'workout-recaps', true);
--
-- CREATE POLICY "Users can upload workout recaps"
-- ON storage.objects FOR INSERT TO authenticated
-- WITH CHECK (bucket_id = 'workout-recaps' AND (storage.foldername(name))[1] = auth.uid()::text);
--
-- CREATE POLICY "Users can view workout recaps"
-- ON storage.objects FOR SELECT TO authenticated
-- USING (bucket_id = 'workout-recaps');
--
-- CREATE POLICY "Users can delete own workout recaps"
-- ON storage.objects FOR DELETE TO authenticated
-- USING (bucket_id = 'workout-recaps' AND (storage.foldername(name))[1] = auth.uid()::text);
