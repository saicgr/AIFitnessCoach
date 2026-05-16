-- 2070_enrichment_attempts_tracking.sql
--
-- Phase-1 fix-up: switch from pre-write rejection to write-then-validate-
-- then-cleanup, with a hard retry cap so failed rows don't infinitely
-- consume Gemini calls.
--
-- Background (audit log 2026-05-13): the original backfill rejected items
-- with validator ERROR findings BEFORE writing to DB. Bad items stayed
-- enrichment_backfilled_at=NULL and re-fetched on every script run. The
-- model at temperature=0.1 is near-deterministic, so the same row would
-- fail the same way over and over — paying Gemini cost each time.
--
-- New columns:
--   enrichment_attempts        — incremented on every Gemini-completed
--                                 enrichment, regardless of validator outcome.
--                                 The fetch query caps at < 3 so a row that
--                                 fails 3 times stops retrying.
--   enrichment_last_violation  — concatenated list of validator findings on
--                                 the most recent attempt. Surfaces in the
--                                 audit script + lets us SELECT bad rows
--                                 to refine validator rules.

ALTER TABLE food_nutrition_overrides
  ADD COLUMN IF NOT EXISTS enrichment_attempts SMALLINT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS enrichment_last_violation TEXT;

-- Replace the old "pending" partial index with a retry-aware one.
DROP INDEX IF EXISTS idx_food_overrides_enrichment_pending;

CREATE INDEX IF NOT EXISTS idx_food_overrides_enrichment_retryable
  ON food_nutrition_overrides(id)
  WHERE enrichment_backfilled_at IS NULL AND enrichment_attempts < 3;

-- Separate index for "exhausted retries" (audit-script lookup target)
CREATE INDEX IF NOT EXISTS idx_food_overrides_enrichment_exhausted
  ON food_nutrition_overrides(id)
  WHERE enrichment_backfilled_at IS NULL AND enrichment_attempts >= 3;

COMMENT ON COLUMN food_nutrition_overrides.enrichment_attempts IS
  'Number of Gemini enrichment attempts for this row. Capped at 3 by the backfill fetch query — rows at 3 are parked for human review or rule change.';
COMMENT ON COLUMN food_nutrition_overrides.enrichment_last_violation IS
  'Concatenated validator findings from the most recent attempt. NULL when the most recent write passed validation.';
