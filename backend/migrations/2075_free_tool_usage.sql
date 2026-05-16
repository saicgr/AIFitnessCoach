-- 2075_free_tool_usage.sql
--
-- IP-based usage tracking for unauthenticated /api/v1/free-tools/* endpoints
-- (ai-food-photo, ai-workout-generator, ai-roast-routine).
--
-- Stores SHA-256-hashed IP + tool name + timestamp. Hashing keeps raw IPs
-- out of the DB while still allowing per-IP rate-limit lookups within a
-- 24h sliding window.
--
-- TTL: rows older than 25h have no purpose. A daily cleanup job
-- (or pg_cron) can `DELETE FROM free_tool_usage WHERE used_at < NOW() - INTERVAL '25 hours'`.

BEGIN;

CREATE TABLE IF NOT EXISTS public.free_tool_usage (
  id BIGSERIAL PRIMARY KEY,
  ip_hash TEXT NOT NULL,
  tool TEXT NOT NULL,
  used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT free_tool_usage_tool_chk CHECK (
    tool IN ('ai-food-photo', 'ai-workout-generator', 'ai-roast-routine')
  )
);

CREATE INDEX IF NOT EXISTS free_tool_usage_lookup_idx
  ON public.free_tool_usage (ip_hash, tool, used_at DESC);

-- Optional secondary index used by the daily TTL cleanup job.
CREATE INDEX IF NOT EXISTS free_tool_usage_used_at_idx
  ON public.free_tool_usage (used_at);

COMMIT;
