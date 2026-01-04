-- ============================================================================
-- Migration 132: AI Insight Cache Table
-- ============================================================================
-- Stores cached AI-generated insights to avoid repeated API calls.
-- Insights include: weight insights, daily tips, habit suggestions
-- ============================================================================

-- Create the cache table
CREATE TABLE IF NOT EXISTS ai_insight_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key VARCHAR(255) NOT NULL UNIQUE,
    insight TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for quick lookups by cache key
CREATE INDEX IF NOT EXISTS idx_ai_insight_cache_key ON ai_insight_cache(cache_key);

-- Index for expiration cleanup
CREATE INDEX IF NOT EXISTS idx_ai_insight_cache_expires ON ai_insight_cache(expires_at);

-- Grant permissions
GRANT ALL ON ai_insight_cache TO service_role;
GRANT SELECT ON ai_insight_cache TO anon;
GRANT SELECT ON ai_insight_cache TO authenticated;

-- RLS Policies (disabled by default for cache table)
ALTER TABLE ai_insight_cache ENABLE ROW LEVEL SECURITY;

-- Allow service role full access
CREATE POLICY "Service role full access on ai_insight_cache"
    ON ai_insight_cache
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Optional: Cleanup function for expired entries
CREATE OR REPLACE FUNCTION cleanup_expired_insight_cache()
RETURNS void AS $$
BEGIN
    DELETE FROM ai_insight_cache
    WHERE expires_at < NOW() - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute
GRANT EXECUTE ON FUNCTION cleanup_expired_insight_cache() TO service_role;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
