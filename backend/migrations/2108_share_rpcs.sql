-- Migration 2108: RPCs for the Imports feature.
--
-- 1) share_rate_increment — atomic upsert+increment of the daily counter
--    used by every /share/* endpoint's rate-limit check. Returns the
--    NEW count so the caller can compare against the cap and raise 429.
--
-- 2) share_recent_softhash — returns the id of a `shared_items` row
--    created in the past N seconds whose tags->>'soft_hash' matches the
--    given value. Used by the import-text + fetch-url orchestrators to
--    show a "you just shared this — re-import?" confirmation instead of
--    silently double-creating.

-- ---------------------------------------------------------------------------
-- 1) share_rate_increment
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION share_rate_increment(
    p_user_id UUID,
    p_day     DATE,
    p_bucket  TEXT
)
RETURNS TABLE (count INT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO share_rate_counters (user_id, day_local, bucket, count, updated_at)
    VALUES (p_user_id, p_day, p_bucket, 1, NOW())
    ON CONFLICT (user_id, day_local, bucket)
    DO UPDATE SET
        count = share_rate_counters.count + 1,
        updated_at = NOW();

    RETURN QUERY
        SELECT c.count
        FROM share_rate_counters c
        WHERE c.user_id = p_user_id
          AND c.day_local = p_day
          AND c.bucket = p_bucket;
END;
$$;

REVOKE ALL ON FUNCTION share_rate_increment(UUID, DATE, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION share_rate_increment(UUID, DATE, TEXT) TO authenticated, service_role;


-- ---------------------------------------------------------------------------
-- 2) share_recent_softhash
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION share_recent_softhash(
    p_user_id UUID,
    p_soft_hash TEXT,
    p_window_seconds INT DEFAULT 60
)
RETURNS TABLE (id UUID, created_at TIMESTAMPTZ)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id, s.created_at
    FROM shared_items s
    WHERE s.user_id = p_user_id
      AND s.created_at > NOW() - (p_window_seconds || ' seconds')::INTERVAL
      AND (s.tags ->> 'soft_hash') = p_soft_hash
    ORDER BY s.created_at DESC
    LIMIT 1;
$$;

REVOKE ALL ON FUNCTION share_recent_softhash(UUID, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION share_recent_softhash(UUID, TEXT, INT) TO authenticated, service_role;
