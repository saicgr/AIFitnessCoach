-- 2064_food_overrides_enrichment_columns.sql
--
-- Phase 1 of the food-scan latency cut (60s → 2-3s).
-- Adds 9 enrichment columns to food_nutrition_overrides so that scan-time
-- responses can read inflammation/FODMAP/glycemic/health-rating fields
-- straight from the row instead of paying a Gemini call per scan. Backfilled
-- by `backend/scripts/backfill_override_enrichment.py` against the existing
-- 198,818 rows.
--
-- coach_tip is intentionally NOT a column here — it depends on the user's
-- remaining macro budget at scan time and stays runtime-generated.
--
-- enrichment_backfilled_at + the partial index together form the
-- resumability spine: the backfill script processes rows where the
-- timestamp is NULL and stamps NOW() on each successful 50-row chunk, so
-- the script can be killed/restarted at any time with no duplicate work.

ALTER TABLE food_nutrition_overrides
  ADD COLUMN IF NOT EXISTS inflammation_score      SMALLINT,
  ADD COLUMN IF NOT EXISTS inflammation_triggers   TEXT[],
  ADD COLUMN IF NOT EXISTS glycemic_load           INTEGER,
  ADD COLUMN IF NOT EXISTS fodmap_rating           TEXT,
  ADD COLUMN IF NOT EXISTS fodmap_reason           TEXT,
  ADD COLUMN IF NOT EXISTS added_sugar_g           REAL,
  ADD COLUMN IF NOT EXISTS is_ultra_processed      BOOLEAN,
  ADD COLUMN IF NOT EXISTS rating                  TEXT,
  ADD COLUMN IF NOT EXISTS rating_reason           TEXT,
  ADD COLUMN IF NOT EXISTS enrichment_backfilled_at TIMESTAMPTZ;

-- Range checks. Done as separate ALTERs (NOT in CHECK on ADD COLUMN) so we
-- can re-run idempotently — Postgres has no IF NOT EXISTS for CHECK constraints,
-- so we wrap in a DO block.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'food_overrides_inflammation_score_range'
  ) THEN
    ALTER TABLE food_nutrition_overrides
      ADD CONSTRAINT food_overrides_inflammation_score_range
      CHECK (inflammation_score IS NULL OR (inflammation_score BETWEEN 0 AND 10));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'food_overrides_fodmap_rating_enum'
  ) THEN
    ALTER TABLE food_nutrition_overrides
      ADD CONSTRAINT food_overrides_fodmap_rating_enum
      CHECK (fodmap_rating IS NULL OR fodmap_rating IN ('low', 'medium', 'high'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'food_overrides_rating_enum'
  ) THEN
    ALTER TABLE food_nutrition_overrides
      ADD CONSTRAINT food_overrides_rating_enum
      CHECK (rating IS NULL OR rating IN ('green', 'yellow', 'red'));
  END IF;
END $$;

-- Resumability index — partial so it stays tiny as backfill progresses.
CREATE INDEX IF NOT EXISTS idx_food_overrides_enrichment_pending
  ON food_nutrition_overrides(id) WHERE enrichment_backfilled_at IS NULL;

COMMENT ON COLUMN food_nutrition_overrides.inflammation_score IS
  '0-10. 0-3 anti-inflammatory, 4-6 neutral/mild, 7-10 highly inflammatory.';
COMMENT ON COLUMN food_nutrition_overrides.inflammation_triggers IS
  'Short-tag drivers of the inflammation score, e.g. {seed_oil, refined_flour, omega3_rich}.';
COMMENT ON COLUMN food_nutrition_overrides.glycemic_load IS
  'GL = GI × carbs_per_100g / 100. NULL when carbs < 2 g per 100 g.';
COMMENT ON COLUMN food_nutrition_overrides.fodmap_rating IS
  'Monash classification. low | medium | high.';
COMMENT ON COLUMN food_nutrition_overrides.fodmap_reason IS
  '≤ 6 words naming the trigger ingredient(s). NULL only when fodmap_rating = low.';
COMMENT ON COLUMN food_nutrition_overrides.added_sugar_g IS
  'Per 100 g. Excludes naturally-occurring whole-fruit/whole-dairy sugar.';
COMMENT ON COLUMN food_nutrition_overrides.is_ultra_processed IS
  'True iff NOVA Group 4. Single-ingredient whole foods are false.';
COMMENT ON COLUMN food_nutrition_overrides.rating IS
  'green | yellow | red traffic-light health rating.';
COMMENT ON COLUMN food_nutrition_overrides.rating_reason IS
  '≤ 8 word explanation of the rating, surfaced in the UI badge tooltip.';
COMMENT ON COLUMN food_nutrition_overrides.enrichment_backfilled_at IS
  'Set by backfill_override_enrichment.py per 50-row chunk. NULL = needs backfill.';
