-- Inflammation triggers (structured) + added-sugar tracking for logged foods.
--
-- Why now: migration 1908 added the numeric inflammation_score and 1977 added
-- diabetes/FODMAP. Users kept asking "why is THIS dish inflammatory?" — the
-- numeric score alone doesn't answer that. Free-text `inflammation_reason`
-- was considered but rejected in favour of a structured tag array so the UI
-- can render labelled chip-badges (Deep-fried / Refined flour / Added sugar)
-- in the Score Explain sheet and so filters like "show me only dishes with
-- no seed-oil triggers" remain tractable down the road.
--
-- Added sugar was previously folded into total carbs and made invisible —
-- but it's the single most actionable signal for a nutrition app, so it
-- now lives as a first-class column alongside the other health signals.
--
-- Both columns are populated by Gemini at the same time as the existing
-- health scores (vision_service.analyze_food_from_s3_keys); no extra
-- inference cost. See feedback_multiscore_display.md for the UI spec that
-- rides on top of these columns.

ALTER TABLE public.food_logs
    ADD COLUMN IF NOT EXISTS inflammation_triggers TEXT[];

ALTER TABLE public.food_logs
    ADD COLUMN IF NOT EXISTS added_sugar_g NUMERIC
        CHECK (added_sugar_g IS NULL OR added_sugar_g >= 0);

COMMENT ON COLUMN public.food_logs.inflammation_triggers IS
    '1-3 structured tags naming the drivers of inflammation_score, e.g. {deep_fried, refined_flour}. Null = not computed.';

COMMENT ON COLUMN public.food_logs.added_sugar_g IS
    'Grams of added sugar per serving (excludes naturally-occurring sugars in whole fruit/dairy). WHO adult daily limit is 25g.';

-- Partial index only on rows with added sugar set so the index stays tight;
-- users with low-sugar diets will filter on this column frequently as this
-- rolls into food history queries.
CREATE INDEX IF NOT EXISTS idx_food_logs_added_sugar
    ON public.food_logs (added_sugar_g)
    WHERE added_sugar_g IS NOT NULL;
