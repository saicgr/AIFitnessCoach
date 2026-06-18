-- Migration 2263: Feature-request comments (in-app board → Canny parity)
-- Adds threaded discussion to the in-app feature-voting board (built on migration 046).
-- Mirrors the threaded-comment shape of 2079_roadmap_comment_threads.sql, but
-- auth-keyed (user_id) instead of email-keyed, to match the in-app board.

-- ===================================
-- Table: feature_request_comments
-- ===================================
CREATE TABLE IF NOT EXISTS feature_request_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_id UUID NOT NULL REFERENCES feature_requests(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    author_name TEXT,                               -- denormalized display name (nullable; team comments may set this)
    body TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
    parent_id UUID REFERENCES feature_request_comments(id) ON DELETE CASCADE,
    depth INTEGER NOT NULL DEFAULT 0 CHECK (depth BETWEEN 0 AND 9), -- threading cap, like 2079
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,        -- soft-moderation
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feature_comments_feature_id ON feature_request_comments(feature_id);
CREATE INDEX IF NOT EXISTS idx_feature_comments_parent_id ON feature_request_comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_feature_comments_created_at ON feature_request_comments(created_at);

-- ===================================
-- Denormalized comment_count on feature_requests
-- ===================================
ALTER TABLE feature_requests
    ADD COLUMN IF NOT EXISTS comment_count INTEGER NOT NULL DEFAULT 0;

-- ===================================
-- Function: maintain comment_count (mirror update_feature_vote_count)
-- ===================================
CREATE OR REPLACE FUNCTION update_feature_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE feature_requests
        SET comment_count = comment_count + 1, updated_at = NOW()
        WHERE id = NEW.feature_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE feature_requests
        SET comment_count = GREATEST(comment_count - 1, 0), updated_at = NOW()
        WHERE id = OLD.feature_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_feature_comment_count ON feature_request_comments;
CREATE TRIGGER trigger_update_feature_comment_count
    AFTER INSERT OR DELETE ON feature_request_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_feature_comment_count();

-- Backfill comment_count for any pre-existing rows (idempotent / safe on empty table).
UPDATE feature_requests fr
SET comment_count = COALESCE((
    SELECT COUNT(*) FROM feature_request_comments c
    WHERE c.feature_id = fr.id AND c.is_hidden = FALSE
), 0);

-- ===================================
-- Row Level Security
-- ===================================
ALTER TABLE feature_request_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Everyone can view feature comments" ON feature_request_comments;
CREATE POLICY "Everyone can view feature comments"
    ON feature_request_comments FOR SELECT
    USING (is_hidden = FALSE);

DROP POLICY IF EXISTS "Users can create feature comments" ON feature_request_comments;
CREATE POLICY "Users can create feature comments"
    ON feature_request_comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own feature comments" ON feature_request_comments;
CREATE POLICY "Users can delete their own feature comments"
    ON feature_request_comments FOR DELETE
    USING (auth.uid() = user_id);

-- ===================================
-- Documentation
-- ===================================
COMMENT ON TABLE feature_request_comments IS 'Threaded discussion on in-app feature-request board (migration 046); auth-keyed.';
COMMENT ON COLUMN feature_request_comments.depth IS 'Threading depth 0..9 (cap mirrors public roadmap 2079).';
COMMENT ON COLUMN feature_requests.comment_count IS 'Denormalized count of non-hidden comments (maintained by trigger).';
