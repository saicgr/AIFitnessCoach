-- Migration: 505_recipe_versions.sql
-- Description: Recipe edit history with full snapshots + revert support.
--   Trigger on user_recipes UPDATE captures OLD row + ingredients into recipe_versions and
--   bumps version_number. Reverts create a NEW version representing the revert (no destructive history loss).
-- Created: 2026-04-14

CREATE TABLE IF NOT EXISTS recipe_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES user_recipes(id) ON DELETE CASCADE,
    version_number INT NOT NULL,

    -- Whole-recipe snapshot incl. ingredients array, so detail/diff/revert never need a join
    recipe_snapshot JSONB NOT NULL,

    -- Optional human or AI-generated summary like "+2 ingredients, renamed"
    change_summary TEXT,

    edited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    edited_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (recipe_id, version_number)
);

CREATE INDEX IF NOT EXISTS idx_recipe_versions_recipe
    ON recipe_versions (recipe_id, version_number DESC);

ALTER TABLE recipe_versions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own + public recipe versions" ON recipe_versions;
CREATE POLICY "Users read own + public recipe versions"
    ON recipe_versions FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM user_recipes r
        WHERE r.id = recipe_id AND (r.user_id = auth.uid() OR r.is_public = TRUE)
    ));

DROP POLICY IF EXISTS "Service role full access recipe versions" ON recipe_versions;
CREATE POLICY "Service role full access recipe versions"
    ON recipe_versions FOR ALL TO service_role
    USING (TRUE) WITH CHECK (TRUE);

-- Trigger function: snapshot OLD recipe + its ingredients into a new version row before UPDATE.
-- Skips if user_recipes.auto_snapshot_versions flag exists and is FALSE (added later via settings).
CREATE OR REPLACE FUNCTION snapshot_recipe_version()
RETURNS TRIGGER
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    next_version INT;
    ingredients_json JSONB;
    snapshot JSONB;
    summary TEXT;
BEGIN
    -- Skip when only computed nutrition / updated_at changed (recalculate_recipe_nutrition()
    -- from migration 039 updates the per-serving columns; we don't want a version per ingredient edit).
    -- Snapshot only when a user-meaningful column actually changed.
    IF NEW.name IS NOT DISTINCT FROM OLD.name
       AND NEW.description IS NOT DISTINCT FROM OLD.description
       AND NEW.servings IS NOT DISTINCT FROM OLD.servings
       AND NEW.prep_time_minutes IS NOT DISTINCT FROM OLD.prep_time_minutes
       AND NEW.cook_time_minutes IS NOT DISTINCT FROM OLD.cook_time_minutes
       AND NEW.instructions IS NOT DISTINCT FROM OLD.instructions
       AND NEW.image_url IS NOT DISTINCT FROM OLD.image_url
       AND NEW.category IS NOT DISTINCT FROM OLD.category
       AND NEW.cuisine IS NOT DISTINCT FROM OLD.cuisine
       AND NEW.tags IS NOT DISTINCT FROM OLD.tags
       AND NEW.is_public IS NOT DISTINCT FROM OLD.is_public THEN
        RETURN NEW;
    END IF;

    -- Honor the per-recipe auto_snapshot_versions flag (added in migration 510)
    BEGIN
        IF NEW.auto_snapshot_versions = FALSE THEN
            RETURN NEW;
        END IF;
    EXCEPTION WHEN undefined_column THEN
        -- Column not yet added; default behavior is to snapshot
        NULL;
    END;

    -- Get next version number for this recipe
    SELECT COALESCE(MAX(version_number), 0) + 1
        INTO next_version
        FROM recipe_versions
        WHERE recipe_id = OLD.id;

    -- Aggregate ingredients into the snapshot
    SELECT COALESCE(jsonb_agg(to_jsonb(ri) ORDER BY ri.ingredient_order), '[]'::jsonb)
        INTO ingredients_json
        FROM recipe_ingredients ri
        WHERE ri.recipe_id = OLD.id;

    snapshot := to_jsonb(OLD) || jsonb_build_object('ingredients', ingredients_json);

    -- Lightweight change summary (UI may overwrite later with an AI-generated one)
    IF OLD.name IS DISTINCT FROM NEW.name THEN
        summary := 'Renamed';
    ELSIF OLD.servings IS DISTINCT FROM NEW.servings THEN
        summary := 'Servings changed: ' || OLD.servings || ' -> ' || NEW.servings;
    ELSE
        summary := 'Recipe updated';
    END IF;

    INSERT INTO recipe_versions (recipe_id, version_number, recipe_snapshot, change_summary, edited_by)
        VALUES (OLD.id, next_version, snapshot, summary, NEW.user_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_snapshot_recipe_version ON user_recipes;
CREATE TRIGGER trg_snapshot_recipe_version
    BEFORE UPDATE ON user_recipes
    FOR EACH ROW EXECUTE FUNCTION snapshot_recipe_version();

-- Helper: cap retained versions at 50 per recipe (service may invoke this on edits)
CREATE OR REPLACE FUNCTION prune_recipe_versions(p_recipe_id UUID, p_keep INT DEFAULT 50)
RETURNS INT
SECURITY DEFINER SET search_path = public
AS $$
DECLARE deleted_count INT;
BEGIN
    WITH ranked AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY version_number DESC) AS rn
        FROM recipe_versions WHERE recipe_id = p_recipe_id
    )
    DELETE FROM recipe_versions
        WHERE id IN (SELECT id FROM ranked WHERE rn > p_keep);
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION prune_recipe_versions TO authenticated;

COMMENT ON TABLE recipe_versions IS
    'Append-only edit history of user_recipes (incl. ingredients) for diff + revert.';
