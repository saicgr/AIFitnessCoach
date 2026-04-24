-- Diabetes (glycemic load) + FODMAP tracking for logged foods.
--
-- Why now: the inflammation_score column (migration 1908) proved users want
-- health-condition-specific scores visible on every logged item. Users with
-- diabetes / pre-diabetes / IBS have been asking for:
--   • glycemic_load — single integer summarising blood-sugar impact per
--     serving (GL = GI × carbs_g / 100). <10 low, 10–19 medium, 20+ high.
--   • fodmap_rating — Monash-style 'low' / 'medium' / 'high' categorical.
--   • fodmap_reason — short text explaining the trigger ingredients.
--
-- These get populated by Gemini at the same time as inflammation_score, so
-- there's no extra vision call. Downstream UI (menu analysis, food history,
-- nutrition surfaces) renders them as tappable pills backed by
-- score_explain_sheet.dart.

ALTER TABLE public.food_logs
    ADD COLUMN IF NOT EXISTS glycemic_load INTEGER
        CHECK (glycemic_load IS NULL OR (glycemic_load >= 0 AND glycemic_load <= 60));

ALTER TABLE public.food_logs
    ADD COLUMN IF NOT EXISTS fodmap_rating TEXT
        CHECK (fodmap_rating IS NULL OR fodmap_rating IN ('low', 'medium', 'high'));

ALTER TABLE public.food_logs
    ADD COLUMN IF NOT EXISTS fodmap_reason TEXT;

COMMENT ON COLUMN public.food_logs.glycemic_load IS
    'Per-serving glycemic load (GI × carbs_g / 100). <10 low, 10-19 medium, 20+ high. Null = not computed.';
COMMENT ON COLUMN public.food_logs.fodmap_rating IS
    'Monash-style FODMAP classification: low | medium | high. Null = not classified.';
COMMENT ON COLUMN public.food_logs.fodmap_reason IS
    'Short explanation of the primary FODMAP trigger(s), e.g. "contains onion, garlic".';

-- Indexes for filter queries in food-history and menu-analysis surfaces.
-- Users with diabetes / IBS will frequently filter by these; without indexes
-- the food_logs table scan cost climbs fast as log history grows.
CREATE INDEX IF NOT EXISTS idx_food_logs_glycemic_load
    ON public.food_logs (glycemic_load)
    WHERE glycemic_load IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_food_logs_fodmap_rating
    ON public.food_logs (fodmap_rating)
    WHERE fodmap_rating IS NOT NULL;
