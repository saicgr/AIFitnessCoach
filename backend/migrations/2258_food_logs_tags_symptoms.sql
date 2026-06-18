-- 2258_food_logs_tags_symptoms.sql
--
-- Nutrition overhaul (Phase 2A) — capture-layer signal columns on food_logs.
--
-- Two open-vocabulary text[] columns feeding the correlation engine + Journal:
--   * tags     — user food tags applied after logging (Phase 7): dairy / gluten
--                / spicy / probiotic / fried / high_fodmap + custom free-text.
--                Chips are a convenience, NOT a closed whitelist (per the
--                no-hardcoded-enumerations rule). Auto-derived suggestions +
--                custom allowed.
--   * symptoms — structured post-meal feelings (Phase 5): bloated / sluggish /
--                energized / foggy / nauseous / good_digestion + custom. Same
--                open-vocab stance; the free-text `notes` column already exists.
--
-- Both NULLABLE — fail-open: a meal logged before this migration, or by any
-- path that never sets them, stays NULL and never blocks logging or breaks the
-- correlation RPCs (which treat absent tags/symptoms as "no signal").
--
-- GIN indexes back the array-containment / overlap predicates the correlation
-- RPCs use (`tags && ARRAY[...]`, `symptoms @> ARRAY[...]`).

ALTER TABLE food_logs
    ADD COLUMN IF NOT EXISTS tags     text[],
    ADD COLUMN IF NOT EXISTS symptoms text[];

COMMENT ON COLUMN food_logs.tags IS
    'Open-vocab user food tags (dairy/gluten/spicy/probiotic/fried/custom). '
    'NULL = untagged. Feeds get_food_patterns tag buckets + get_digestion_patterns.';
COMMENT ON COLUMN food_logs.symptoms IS
    'Open-vocab post-meal feelings (bloated/sluggish/energized/foggy/custom). '
    'NULL = no check-in. Feeds per-symptom correlation counts.';

-- GIN indexes for array overlap / containment correlation queries. Partial
-- (WHERE col IS NOT NULL) so the index only carries rows that actually have a
-- signal — the vast majority of legacy rows are NULL.
CREATE INDEX IF NOT EXISTS idx_food_logs_tags_gin
    ON food_logs USING GIN (tags)
    WHERE tags IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_food_logs_symptoms_gin
    ON food_logs USING GIN (symptoms)
    WHERE symptoms IS NOT NULL;
