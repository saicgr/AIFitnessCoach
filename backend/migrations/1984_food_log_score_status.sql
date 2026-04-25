-- 1984_food_log_score_status.sql
--
-- Adds `score_status` to food_logs so the UI can distinguish between
-- "scoring hasn't run yet" (NULL → still queued for Gemini enrichment),
-- "scoring complete" ('ok'), and "scoring failed" ('unavailable' →
-- Gemini was unreachable / refused / returned garbage).
--
-- Why this matters: per the project's "no silent degradation" memory
-- rule, missing scoring fields should not silently render as blank
-- chips. With this column, the Inflammation/NOVA/FODMAP chips on the
-- meal detail sheet can render in three distinct states:
--
--   NULL         → "Scoring..." spinner (background enrichment running)
--   'ok'         → render whatever values are present; null individual
--                  fields mean Gemini decided that field is N/A for the
--                  food (e.g. FODMAP for grilled chicken)
--   'unavailable'→ greyed pills with a retry icon, tooltip explaining
--                  AI was unreachable
--
-- Populated by `services/food_score_enrichment.py::enrich_food_log_scores`
-- after every /log-direct write that didn't supply scores upstream.

ALTER TABLE food_logs
    ADD COLUMN IF NOT EXISTS score_status TEXT
        CHECK (score_status IS NULL OR score_status IN ('ok', 'unavailable', 'pending'));

COMMENT ON COLUMN food_logs.score_status IS
    'NULL = enrichment not yet run; ''ok'' = enrichment completed (individual NULL columns mean Gemini said N/A); ''unavailable'' = Gemini failed, UI shows retry affordance; ''pending'' = explicitly queued (reserved for future synchronous-with-progress flows).';
