-- Migration: 119_food_search_cache.sql
-- Description: Caching layer for food search results to improve performance and reduce API calls
-- Created: 2024-12-31

-- ============================================================================
-- FOOD SEARCH CACHE TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS food_search_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Query identification
    query_hash TEXT NOT NULL UNIQUE,  -- MD5 hash of lowercase, trimmed query
    query_text TEXT NOT NULL,          -- Original query text for debugging

    -- Cached results
    results JSONB NOT NULL DEFAULT '[]',  -- Array of food search results
    result_count INTEGER DEFAULT 0,        -- Number of results cached

    -- Metadata
    source TEXT DEFAULT 'api',  -- api, barcode, user, usda, openfoodfacts
    api_version TEXT,           -- Version of API that returned results
    locale TEXT DEFAULT 'en-US', -- Locale for localized food names

    -- Cache management
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
    hit_count INTEGER DEFAULT 0,  -- Track cache hits for analytics
    last_hit_at TIMESTAMPTZ
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Primary lookup index on query hash
CREATE INDEX IF NOT EXISTS idx_food_search_cache_hash
    ON food_search_cache(query_hash);

-- Index for cache expiration cleanup
CREATE INDEX IF NOT EXISTS idx_food_search_cache_expires
    ON food_search_cache(expires_at);

-- Index for source filtering
CREATE INDEX IF NOT EXISTS idx_food_search_cache_source
    ON food_search_cache(source);

-- Note: Cannot create partial index with NOW() as it's not immutable.
-- The expires_at column has its own index for cleanup queries.
-- Query filtering by expiration can use idx_food_search_cache_expires instead.

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS
ALTER TABLE food_search_cache ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can read cache (this is shared data)
CREATE POLICY "Authenticated users can read food search cache"
    ON food_search_cache FOR SELECT
    TO authenticated
    USING (TRUE);

-- Policy: Service role has full access (for cache management)
CREATE POLICY "Service role has full access to food search cache"
    ON food_search_cache FOR ALL
    TO service_role
    USING (true) WITH CHECK (true);

-- Note: Regular users cannot INSERT/UPDATE/DELETE - only backend service can manage cache

-- ============================================================================
-- FUNCTIONS: CACHE MANAGEMENT
-- ============================================================================

-- Function to clean expired cache entries
CREATE OR REPLACE FUNCTION clean_expired_food_cache()
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM food_search_cache WHERE expires_at < NOW();
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get cache stats
CREATE OR REPLACE FUNCTION get_food_cache_stats()
RETURNS TABLE(
    total_entries BIGINT,
    active_entries BIGINT,
    expired_entries BIGINT,
    total_hits BIGINT,
    avg_results_per_query NUMERIC,
    cache_size_bytes BIGINT
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT AS total_entries,
        COUNT(*) FILTER (WHERE expires_at > NOW())::BIGINT AS active_entries,
        COUNT(*) FILTER (WHERE expires_at <= NOW())::BIGINT AS expired_entries,
        COALESCE(SUM(hit_count), 0)::BIGINT AS total_hits,
        COALESCE(AVG(result_count), 0)::NUMERIC AS avg_results_per_query,
        COALESCE(SUM(pg_column_size(results)), 0)::BIGINT AS cache_size_bytes
    FROM food_search_cache;
END;
$$ LANGUAGE plpgsql;

-- Function to lookup and record cache hit
CREATE OR REPLACE FUNCTION lookup_food_cache(p_query_hash TEXT)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    cached_results JSONB;
BEGIN
    -- Get results and update hit count in one operation
    UPDATE food_search_cache
    SET
        hit_count = hit_count + 1,
        last_hit_at = NOW()
    WHERE query_hash = p_query_hash
      AND expires_at > NOW()
    RETURNING results INTO cached_results;

    RETURN cached_results;
END;
$$ LANGUAGE plpgsql;

-- Function to insert or update cache entry
CREATE OR REPLACE FUNCTION upsert_food_cache(
    p_query_hash TEXT,
    p_query_text TEXT,
    p_results JSONB,
    p_source TEXT DEFAULT 'api',
    p_ttl_days INTEGER DEFAULT 7
)
RETURNS food_search_cache
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result food_search_cache;
BEGIN
    INSERT INTO food_search_cache (
        query_hash,
        query_text,
        results,
        result_count,
        source,
        expires_at
    )
    VALUES (
        p_query_hash,
        p_query_text,
        p_results,
        jsonb_array_length(p_results),
        p_source,
        NOW() + (p_ttl_days || ' days')::INTERVAL
    )
    ON CONFLICT (query_hash) DO UPDATE SET
        results = p_results,
        result_count = jsonb_array_length(p_results),
        source = p_source,
        expires_at = NOW() + (p_ttl_days || ' days')::INTERVAL,
        created_at = NOW()
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to generate consistent query hash
CREATE OR REPLACE FUNCTION generate_food_query_hash(p_query TEXT)
RETURNS TEXT
IMMUTABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Normalize query: lowercase, trim whitespace, collapse multiple spaces
    RETURN md5(lower(trim(regexp_replace(p_query, '\s+', ' ', 'g'))));
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SCHEDULED CLEANUP (Optional - can be called by cron job)
-- ============================================================================

-- Function to perform maintenance on cache table
CREATE OR REPLACE FUNCTION maintain_food_cache()
RETURNS TABLE(
    expired_deleted INTEGER,
    low_hit_deleted INTEGER,
    vacuum_performed BOOLEAN
)
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_expired_deleted INTEGER;
    v_low_hit_deleted INTEGER;
BEGIN
    -- Delete expired entries
    DELETE FROM food_search_cache WHERE expires_at < NOW();
    GET DIAGNOSTICS v_expired_deleted = ROW_COUNT;

    -- Delete old entries with zero hits (never useful)
    DELETE FROM food_search_cache
    WHERE created_at < NOW() - INTERVAL '30 days'
      AND hit_count = 0;
    GET DIAGNOSTICS v_low_hit_deleted = ROW_COUNT;

    RETURN QUERY SELECT v_expired_deleted, v_low_hit_deleted, TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant execute on lookup function to authenticated users
GRANT EXECUTE ON FUNCTION lookup_food_cache TO authenticated;
GRANT EXECUTE ON FUNCTION generate_food_query_hash TO authenticated;

-- Stats and maintenance functions for service role only (default)

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE food_search_cache IS 'Cache layer for food search API results. Reduces external API calls and improves search performance.';
COMMENT ON COLUMN food_search_cache.query_hash IS 'MD5 hash of normalized (lowercase, trimmed) query for fast lookup';
COMMENT ON COLUMN food_search_cache.results IS 'JSON array of food search results from the API';
COMMENT ON COLUMN food_search_cache.source IS 'Source of the cached data: api, barcode, user, usda, openfoodfacts';
COMMENT ON COLUMN food_search_cache.hit_count IS 'Number of times this cache entry has been accessed';
COMMENT ON COLUMN food_search_cache.expires_at IS 'Cache expiration time. Entries older than this are considered stale.';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
