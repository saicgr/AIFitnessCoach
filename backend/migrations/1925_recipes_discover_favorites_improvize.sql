-- Migration 1925: Discover + Favorites + Improvize
-- Adds curated-recipe catalog, recipe favorites join table, and improvize fork lineage.
--
-- Changes:
-- 1. user_recipes.user_id becomes NULLable so curated rows can exist without an owner
-- 2. user_recipes gains is_curated, source_recipe_id (+denormalized name/user_id), slug
-- 3. CHECK constraint: user_id IS NOT NULL OR is_curated = TRUE
-- 4. SELECT RLS expanded to include is_curated = TRUE
-- 5. favorite_recipes join table with RLS (mirrors favorite_exercises pattern from 058)
--
-- Applied via Supabase MCP on 2026-04-15.

-- 1. user_recipes: allow NULL user_id for curated rows + new columns
ALTER TABLE user_recipes ALTER COLUMN user_id DROP NOT NULL;

ALTER TABLE user_recipes
  ADD COLUMN IF NOT EXISTS is_curated BOOLEAN DEFAULT FALSE NOT NULL,
  ADD COLUMN IF NOT EXISTS source_recipe_id UUID REFERENCES user_recipes(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS source_recipe_name TEXT,
  ADD COLUMN IF NOT EXISTS source_recipe_user_id UUID,
  ADD COLUMN IF NOT EXISTS slug TEXT;

-- CHECK constraint: either a user owns the row, OR it is a curated row (system-owned)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_recipes_owner_or_curated'
  ) THEN
    ALTER TABLE user_recipes
      ADD CONSTRAINT user_recipes_owner_or_curated
      CHECK (user_id IS NOT NULL OR is_curated = TRUE);
  END IF;
END $$;

-- Indexes for new query paths
CREATE INDEX IF NOT EXISTS idx_recipes_curated
  ON user_recipes (is_curated, category, times_logged DESC)
  WHERE is_curated = TRUE AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_recipes_source
  ON user_recipes (source_recipe_id)
  WHERE source_recipe_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_recipes_curated_slug
  ON user_recipes (slug)
  WHERE is_curated = TRUE AND deleted_at IS NULL;

-- 2. Update SELECT RLS policy to include curated rows
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname
    FROM pg_policies
    WHERE tablename = 'user_recipes' AND cmd = 'SELECT'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON user_recipes', pol.policyname);
  END LOOP;
END $$;

CREATE POLICY "Users can view own, public, or curated recipes"
  ON user_recipes FOR SELECT
  USING (
    user_id = auth.uid()
    OR is_public = TRUE
    OR is_curated = TRUE
  );

-- 3. favorite_recipes join table (mirrors favorite_exercises pattern from 058)
CREATE TABLE IF NOT EXISTS favorite_recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipe_id UUID NOT NULL REFERENCES user_recipes(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, recipe_id)
);

CREATE INDEX IF NOT EXISTS idx_favorite_recipes_user
  ON favorite_recipes(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_favorite_recipes_recipe
  ON favorite_recipes(recipe_id);

ALTER TABLE favorite_recipes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own favorite_recipes" ON favorite_recipes;
CREATE POLICY "Users can view own favorite_recipes"
  ON favorite_recipes FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can add own favorite_recipes" ON favorite_recipes;
CREATE POLICY "Users can add own favorite_recipes"
  ON favorite_recipes FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can remove own favorite_recipes" ON favorite_recipes;
CREATE POLICY "Users can remove own favorite_recipes"
  ON favorite_recipes FOR DELETE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Service role full access favorite_recipes" ON favorite_recipes;
CREATE POLICY "Service role full access favorite_recipes"
  ON favorite_recipes FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

GRANT SELECT, INSERT, DELETE ON favorite_recipes TO authenticated;
