-- Migration: 506_recipe_share_links.sql
-- Description: Public shareable links for recipes.
--   slug is a short URL-safe id; clients build links like fitwiz.app/r/{slug}.
--   Resolution requires both is_public=TRUE on the recipe AND an active share row.
-- Created: 2026-04-14

CREATE TABLE IF NOT EXISTS recipe_share_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL UNIQUE REFERENCES user_recipes(id) ON DELETE CASCADE,
    slug TEXT NOT NULL UNIQUE
        CHECK (char_length(slug) BETWEEN 4 AND 20 AND slug ~ '^[A-Za-z0-9_-]+$'),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    view_count INT DEFAULT 0,
    save_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_recipe_share_slug ON recipe_share_links (slug);

ALTER TABLE recipe_share_links ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read share links" ON recipe_share_links;
CREATE POLICY "Public read share links"
    ON recipe_share_links FOR SELECT
    USING (TRUE);

DROP POLICY IF EXISTS "Owner inserts share link" ON recipe_share_links;
CREATE POLICY "Owner inserts share link"
    ON recipe_share_links FOR INSERT
    WITH CHECK (created_by = auth.uid()
                AND EXISTS (SELECT 1 FROM user_recipes r WHERE r.id = recipe_id AND r.user_id = auth.uid()));

DROP POLICY IF EXISTS "Owner deletes share link" ON recipe_share_links;
CREATE POLICY "Owner deletes share link"
    ON recipe_share_links FOR DELETE
    USING (created_by = auth.uid());

DROP POLICY IF EXISTS "Service role full access share links" ON recipe_share_links;
CREATE POLICY "Service role full access share links"
    ON recipe_share_links FOR ALL TO service_role
    USING (TRUE) WITH CHECK (TRUE);

-- RPC for the public resolver: increments view_count atomically and returns recipe + slug
CREATE OR REPLACE FUNCTION resolve_recipe_share(p_slug TEXT)
RETURNS TABLE (
    recipe_id UUID,
    slug TEXT,
    view_count INT,
    save_count INT,
    is_public BOOLEAN
)
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    UPDATE recipe_share_links sl
        SET view_count = sl.view_count + 1
        FROM user_recipes r
        WHERE sl.slug = p_slug AND sl.recipe_id = r.id AND r.is_public = TRUE
        RETURNING sl.recipe_id, sl.slug, sl.view_count, sl.save_count, r.is_public;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION resolve_recipe_share TO anon, authenticated;

CREATE OR REPLACE FUNCTION increment_recipe_share_save(p_slug TEXT)
RETURNS VOID
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    UPDATE recipe_share_links SET save_count = save_count + 1 WHERE slug = p_slug;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION increment_recipe_share_save TO authenticated;

COMMENT ON TABLE recipe_share_links IS
    'Maps a short slug to a public recipe. Slug + is_public both required for resolution.';
