-- Per-user food overrides: when a user corrects cal/P/C/F on a logged food
-- item (via the Adjust Portion sheet), we remember that correction so the
-- next time the same food is detected (by any log path — image, text,
-- direct), we apply the user's numbers before writing the log.
--
-- Match key priority:
--   1. `food_item_id` — stable ID from Gemini / library when present.
--   2. `food_name_normalized` — lower().strip() + collapsed whitespace.
--
-- Two partial unique indexes enforce "at most one override per user per
-- conceptual food" without requiring a nullable column in a composite
-- unique constraint (Postgres treats NULL as distinct in unique indexes).

CREATE TABLE IF NOT EXISTS user_food_overrides (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_item_id          TEXT,
    food_name_normalized  TEXT NOT NULL,
    display_name          TEXT NOT NULL,
    -- Absolute values for ONE serving of the user's corrected portion.
    calories              INTEGER NOT NULL,
    protein_g             NUMERIC NOT NULL DEFAULT 0,
    carbs_g               NUMERIC NOT NULL DEFAULT 0,
    fat_g                 NUMERIC NOT NULL DEFAULT 0,
    -- Reference serving dimensions so we can scale when the next log has a
    -- different portion. All optional — when NULL we apply the override 1:1
    -- regardless of portion (trusts the user's absolute number).
    reference_weight_g    NUMERIC,
    reference_count       NUMERIC,
    reference_unit        TEXT,
    -- Audit counters
    edit_count            INTEGER NOT NULL DEFAULT 1,
    first_edited_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_edited_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One override per user per food_item_id (when the ID is known).
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_food_overrides_user_id
    ON user_food_overrides(user_id, food_item_id)
    WHERE food_item_id IS NOT NULL;

-- Fallback: one override per user per normalized name (when no ID).
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_food_overrides_user_name
    ON user_food_overrides(user_id, food_name_normalized)
    WHERE food_item_id IS NULL;

-- For listing the user's most recent corrections (future UI: "your
-- personalized foods").
CREATE INDEX IF NOT EXISTS idx_user_food_overrides_user_recent
    ON user_food_overrides(user_id, last_edited_at DESC);

ALTER TABLE user_food_overrides ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own food overrides" ON user_food_overrides;
CREATE POLICY "Users can view own food overrides" ON user_food_overrides
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own food overrides" ON user_food_overrides;
CREATE POLICY "Users can insert own food overrides" ON user_food_overrides
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own food overrides" ON user_food_overrides;
CREATE POLICY "Users can update own food overrides" ON user_food_overrides
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own food overrides" ON user_food_overrides;
CREATE POLICY "Users can delete own food overrides" ON user_food_overrides
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Service role manages food overrides" ON user_food_overrides;
CREATE POLICY "Service role manages food overrides" ON user_food_overrides
    FOR ALL USING (auth.role() = 'service_role');

COMMENT ON TABLE user_food_overrides IS 'Per-user cal/P/C/F corrections applied to future logs of the same food.';
COMMENT ON COLUMN user_food_overrides.food_item_id IS 'Stable ID from Gemini / library when present; preferred match key.';
COMMENT ON COLUMN user_food_overrides.food_name_normalized IS 'Fallback match key: lower(), trim, single-space. Must match normalize_food_name() in backend/utils/food_naming.py.';
COMMENT ON COLUMN user_food_overrides.reference_weight_g IS 'Reference portion weight for scaling future logs. NULL = apply 1:1.';
COMMENT ON COLUMN user_food_overrides.reference_count IS 'Reference portion count (e.g. 2 cookies). NULL = apply 1:1 by weight or absolute.';
