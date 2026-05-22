-- Migration 2091: TTL hardening for the DB-table food caches.
--
-- `food_analysis_cache` and `rag_context_cache` (migration 209) cache Gemini
-- food-analysis output keyed by a query hash. The read helper bumps
-- `last_accessed_at` on every hit, so a frequently-queried stale row would be
-- served forever — its nutrition numbers never re-computing even after the
-- model/prompt improves. The read path now rejects rows older than a fixed TTL
-- (30 days for food analysis) so they re-compute.
--
-- This migration guarantees the `created_at` column the TTL check depends on
-- exists. Migration 209 already declares `created_at TIMESTAMPTZ DEFAULT NOW()`
-- on both tables, but some environments ran an earlier variant — these
-- `ADD COLUMN IF NOT EXISTS` statements make the column presence deterministic.
--
-- Idempotent — safe to re-run.

-- ============================================================================
-- food_analysis_cache.created_at — the TTL anchor for get_cached_food_analysis
-- ============================================================================
ALTER TABLE food_analysis_cache
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Backfill any pre-existing rows that have a NULL created_at (column added
-- after rows already existed). Fall back to last_accessed_at so a recently
-- touched row is not immediately treated as expired.
UPDATE food_analysis_cache
  SET created_at = COALESCE(last_accessed_at, NOW())
  WHERE created_at IS NULL;

-- Index for fast TTL filtering / cache-cleanup sweeps of old entries.
CREATE INDEX IF NOT EXISTS idx_food_cache_created
  ON food_analysis_cache(created_at);

-- ============================================================================
-- rag_context_cache.created_at — RAG cache already has an `expires_at` TTL,
-- but ensure created_at exists for parity and cleanup tooling.
-- ============================================================================
ALTER TABLE rag_context_cache
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

UPDATE rag_context_cache
  SET created_at = COALESCE(last_accessed_at, NOW())
  WHERE created_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_rag_cache_created
  ON rag_context_cache(created_at);

-- ============================================================================
-- Documentation
-- ============================================================================
COMMENT ON COLUMN food_analysis_cache.created_at IS
  'Row creation time. The read helper rejects rows older than the analysis TTL '
  '(30 days) so stale Gemini nutrition output re-computes.';
COMMENT ON COLUMN rag_context_cache.created_at IS
  'Row creation time. RAG entries also carry a per-row expires_at TTL.';
