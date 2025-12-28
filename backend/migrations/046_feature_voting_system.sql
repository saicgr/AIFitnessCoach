-- Migration 046: Feature Voting System (Robinhood-style)
-- Creates tables for feature requests and voting functionality

-- ===================================
-- Table: feature_requests
-- ===================================
CREATE TABLE IF NOT EXISTS feature_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN (
        'workout', 'social', 'analytics', 'nutrition',
        'coaching', 'ui_ux', 'integration', 'other'
    )),
    status TEXT NOT NULL DEFAULT 'voting' CHECK (status IN (
        'voting', 'planned', 'in_progress', 'released'
    )),
    vote_count INTEGER DEFAULT 0,
    release_date TIMESTAMP WITH TIME ZONE, -- For countdown timer (admin-set only)
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_feature_requests_status ON feature_requests(status);
CREATE INDEX IF NOT EXISTS idx_feature_requests_vote_count ON feature_requests(vote_count DESC);
CREATE INDEX IF NOT EXISTS idx_feature_requests_created_by ON feature_requests(created_by);
CREATE INDEX IF NOT EXISTS idx_feature_requests_created_at ON feature_requests(created_at DESC);

-- ===================================
-- Table: feature_votes
-- ===================================
CREATE TABLE IF NOT EXISTS feature_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feature_id UUID NOT NULL REFERENCES feature_requests(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, feature_id) -- One vote per user per feature
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_feature_votes_user_id ON feature_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_votes_feature_id ON feature_votes(feature_id);

-- ===================================
-- Function: Update vote count on feature_requests
-- ===================================
CREATE OR REPLACE FUNCTION update_feature_vote_count()
RETURNS TRIGGER AS $$
BEGIN
    -- Update vote_count on feature_requests table
    IF TG_OP = 'INSERT' THEN
        UPDATE feature_requests
        SET vote_count = vote_count + 1, updated_at = NOW()
        WHERE id = NEW.feature_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE feature_requests
        SET vote_count = GREATEST(vote_count - 1, 0), updated_at = NOW()
        WHERE id = OLD.feature_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update vote count
DROP TRIGGER IF EXISTS trigger_update_feature_vote_count ON feature_votes;
CREATE TRIGGER trigger_update_feature_vote_count
    AFTER INSERT OR DELETE ON feature_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_feature_vote_count();

-- ===================================
-- Function: Limit user to 2 suggestions
-- ===================================
CREATE OR REPLACE FUNCTION check_user_suggestion_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM feature_requests WHERE created_by = NEW.created_by) >= 2 THEN
        RAISE EXCEPTION 'User has reached the maximum of 2 feature suggestions';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to enforce 2-suggestion limit
DROP TRIGGER IF EXISTS enforce_suggestion_limit ON feature_requests;
CREATE TRIGGER enforce_suggestion_limit
    BEFORE INSERT ON feature_requests
    FOR EACH ROW
    EXECUTE FUNCTION check_user_suggestion_limit();

-- ===================================
-- Function: Update updated_at timestamp
-- ===================================
CREATE OR REPLACE FUNCTION update_feature_request_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS trigger_feature_request_updated_at ON feature_requests;
CREATE TRIGGER trigger_feature_request_updated_at
    BEFORE UPDATE ON feature_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_feature_request_updated_at();

-- ===================================
-- Row Level Security (RLS)
-- ===================================

-- Enable RLS
ALTER TABLE feature_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_votes ENABLE ROW LEVEL SECURITY;

-- Feature Requests: Everyone can read, only authenticated users can create
DROP POLICY IF EXISTS "Everyone can view feature requests" ON feature_requests;
CREATE POLICY "Everyone can view feature requests"
    ON feature_requests FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Authenticated users can create feature requests" ON feature_requests;
CREATE POLICY "Authenticated users can create feature requests"
    ON feature_requests FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- Only admins or the creator can update/delete (for now, restrict to prevent abuse)
DROP POLICY IF EXISTS "Creators can update their own feature requests" ON feature_requests;
CREATE POLICY "Creators can update their own feature requests"
    ON feature_requests FOR UPDATE
    USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "Creators can delete their own feature requests" ON feature_requests;
CREATE POLICY "Creators can delete their own feature requests"
    ON feature_requests FOR DELETE
    USING (auth.uid() = created_by);

-- Feature Votes: Everyone can read, users can create/delete their own votes
DROP POLICY IF EXISTS "Everyone can view feature votes" ON feature_votes;
CREATE POLICY "Everyone can view feature votes"
    ON feature_votes FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can create votes" ON feature_votes;
CREATE POLICY "Users can create votes"
    ON feature_votes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own votes" ON feature_votes;
CREATE POLICY "Users can delete their own votes"
    ON feature_votes FOR DELETE
    USING (auth.uid() = user_id);

-- ===================================
-- Sample Data (optional - for testing)
-- ===================================
-- Uncomment to insert sample features

/*
INSERT INTO feature_requests (title, description, category, status, created_by) VALUES
('Social Workout Sharing', 'Share workout plans with friends and see their progress', 'social', 'voting', NULL),
('Meal Plan Integration', 'AI-generated meal plans that complement your workout program', 'nutrition', 'voting', NULL),
('Advanced Analytics Dashboard', 'Detailed charts showing strength progression, volume trends, and performance metrics', 'analytics', 'planned', NULL);

-- Set release date for planned feature (admin would do this manually)
UPDATE feature_requests
SET release_date = NOW() + INTERVAL '7 days'
WHERE title = 'Advanced Analytics Dashboard';
*/

-- ===================================
-- Comments for documentation
-- ===================================
COMMENT ON TABLE feature_requests IS 'Stores user-suggested features and admin-planned features';
COMMENT ON TABLE feature_votes IS 'Stores user votes for feature requests';
COMMENT ON COLUMN feature_requests.vote_count IS 'Denormalized count of votes (updated by trigger)';
COMMENT ON COLUMN feature_requests.release_date IS 'Expected release date (admin-set only, triggers countdown timer)';
COMMENT ON COLUMN feature_requests.status IS 'Feature lifecycle: voting -> planned -> in_progress -> released';
