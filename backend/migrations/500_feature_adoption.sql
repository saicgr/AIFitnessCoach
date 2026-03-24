-- Feature adoption tracking for retention analytics
-- Tracks first use of key features to identify high-retention patterns

CREATE TABLE IF NOT EXISTS feature_adoption (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feature_key TEXT NOT NULL,
    first_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    use_count INTEGER NOT NULL DEFAULT 1,
    last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, feature_key)
);

-- Index for fast lookups by user
CREATE INDEX IF NOT EXISTS idx_feature_adoption_user_id ON feature_adoption(user_id);

-- RLS policies (users can only access their own data)
ALTER TABLE feature_adoption ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own feature adoption"
    ON feature_adoption FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feature adoption"
    ON feature_adoption FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own feature adoption"
    ON feature_adoption FOR UPDATE
    USING (auth.uid() = user_id);
