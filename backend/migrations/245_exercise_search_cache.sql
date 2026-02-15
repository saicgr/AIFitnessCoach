-- Migration: 245_exercise_search_cache.sql
-- Description: Caching layer for hybrid exercise search (fuzzy + semantic) results
-- Created: 2026-02-14

-- ============================================================================
-- EXERCISE SEARCH CACHE TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_search_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Query identification
    query_hash TEXT NOT NULL UNIQUE,     -- SHA256(normalized query + filters)
    query_text TEXT NOT NULL,             -- Original query text for debugging
    filters_json JSONB DEFAULT '{}',     -- Equipment, body_parts filters used

    -- Cached results
    results JSONB NOT NULL DEFAULT '[]', -- Array of exercise search results
    result_count INTEGER DEFAULT 0,      -- Number of results cached

    -- Cache management
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours',
    hit_count INTEGER DEFAULT 0,         -- Track cache hits for analytics
    last_hit_at TIMESTAMPTZ
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Primary lookup index on query hash
CREATE INDEX IF NOT EXISTS idx_exercise_search_cache_hash
    ON exercise_search_cache(query_hash);

-- Index for cache expiration cleanup
CREATE INDEX IF NOT EXISTS idx_exercise_search_cache_expires
    ON exercise_search_cache(expires_at);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE exercise_search_cache ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read cache (shared data)
CREATE POLICY "Authenticated users can read exercise search cache"
    ON exercise_search_cache FOR SELECT
    TO authenticated
    USING (TRUE);

-- Service role has full access (for cache management)
CREATE POLICY "Service role has full access to exercise search cache"
    ON exercise_search_cache FOR ALL
    TO service_role
    USING (true) WITH CHECK (true);

-- ============================================================================
-- FUNCTIONS: CACHE MANAGEMENT
-- ============================================================================

-- Lookup and record cache hit
CREATE OR REPLACE FUNCTION lookup_exercise_search_cache(p_query_hash TEXT)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    cached_results JSONB;
BEGIN
    UPDATE exercise_search_cache
    SET
        hit_count = hit_count + 1,
        last_hit_at = NOW()
    WHERE query_hash = p_query_hash
      AND expires_at > NOW()
    RETURNING results INTO cached_results;

    RETURN cached_results;
END;
$$ LANGUAGE plpgsql;

-- Insert or update cache entry
CREATE OR REPLACE FUNCTION upsert_exercise_search_cache(
    p_query_hash TEXT,
    p_query_text TEXT,
    p_filters_json JSONB,
    p_results JSONB,
    p_ttl_hours INTEGER DEFAULT 24
)
RETURNS exercise_search_cache
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result exercise_search_cache;
BEGIN
    INSERT INTO exercise_search_cache (
        query_hash,
        query_text,
        filters_json,
        results,
        result_count,
        expires_at
    )
    VALUES (
        p_query_hash,
        p_query_text,
        p_filters_json,
        p_results,
        jsonb_array_length(p_results),
        NOW() + (p_ttl_hours || ' hours')::INTERVAL
    )
    ON CONFLICT (query_hash) DO UPDATE SET
        results = p_results,
        result_count = jsonb_array_length(p_results),
        filters_json = p_filters_json,
        expires_at = NOW() + (p_ttl_hours || ' hours')::INTERVAL,
        created_at = NOW()
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Clean expired cache entries
CREATE OR REPLACE FUNCTION clean_expired_exercise_search_cache()
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM exercise_search_cache WHERE expires_at < NOW();
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION lookup_exercise_search_cache TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE exercise_search_cache IS 'Cache layer for hybrid exercise search (fuzzy + semantic). Reduces embedding API calls and ChromaDB queries.';
COMMENT ON COLUMN exercise_search_cache.query_hash IS 'SHA256 hash of normalized query + filter params for fast lookup';
COMMENT ON COLUMN exercise_search_cache.filters_json IS 'JSON object of filter parameters used (equipment, body_parts)';
COMMENT ON COLUMN exercise_search_cache.results IS 'JSON array of merged exercise search results with relevance scores';
COMMENT ON COLUMN exercise_search_cache.hit_count IS 'Number of times this cache entry has been accessed';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
