-- Audit trail for user-authored edits to food-log nutrition values.
-- One row per edited field per item — so a single item edit of cal+protein
-- produces two rows. This lets us analyze per-field accuracy drift over time
-- and surface a per-meal edit history in the UI.

CREATE TABLE IF NOT EXISTS food_log_edits (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    food_log_id       UUID NOT NULL REFERENCES food_logs(id) ON DELETE CASCADE,
    user_id           UUID NOT NULL,
    food_item_index   INTEGER NOT NULL,
    food_item_name    TEXT NOT NULL,
    food_item_id      TEXT,
    edited_field      TEXT NOT NULL CHECK (edited_field IN ('calories', 'protein_g', 'carbs_g', 'fat_g')),
    previous_value    NUMERIC NOT NULL,
    updated_value     NUMERIC NOT NULL,
    edit_source       TEXT NOT NULL CHECK (edit_source IN ('pre_save_log_meal', 'post_save_nutrition_screen')),
    edited_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_food_log_edits_user_id ON food_log_edits(user_id);
CREATE INDEX IF NOT EXISTS idx_food_log_edits_food_log_id ON food_log_edits(food_log_id);
CREATE INDEX IF NOT EXISTS idx_food_log_edits_edited_at ON food_log_edits(edited_at DESC);

ALTER TABLE food_log_edits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own food log edits" ON food_log_edits;
CREATE POLICY "Users can view own food log edits" ON food_log_edits
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own food log edits" ON food_log_edits;
CREATE POLICY "Users can insert own food log edits" ON food_log_edits
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Service role manages food log edits" ON food_log_edits;
CREATE POLICY "Service role manages food log edits" ON food_log_edits
    FOR ALL USING (auth.role() = 'service_role');

COMMENT ON TABLE food_log_edits IS 'Audit trail for per-field edits to food-log items (cal/P/C/F). One row per edit per field.';
COMMENT ON COLUMN food_log_edits.food_item_index IS 'Position in food_logs.food_items JSONB array at edit time.';
COMMENT ON COLUMN food_log_edits.edit_source IS 'Where the edit originated: pre_save_log_meal (before first save) or post_save_nutrition_screen (editing existing log).';
