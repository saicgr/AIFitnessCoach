-- Migration: Menu Analyses (Save-as-artifact for menu scans)
-- Created: 2026-04-23
-- Description: Persists a menu/buffet analysis so users can reopen it
--              later without re-scanning. Powers "Saved Menus" history
--              screen + feeds the menu_items ChromaDB collection for
--              cross-menu similarity recall in the recommendation
--              algorithm.

CREATE TABLE IF NOT EXISTS menu_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Optional user-chosen label for the saved analysis
    -- e.g. "Indian place near work", "Hotel breakfast spread"
    title TEXT,
    restaurant_name TEXT,

    analysis_type TEXT NOT NULL CHECK (analysis_type IN ('plate', 'menu', 'buffet')),

    -- Full structured menu (sections[] with dishes[]) as returned by
    -- the Gemini vision pipeline. Stored verbatim so we can re-render
    -- the sheet identically on reopen, including coach tips + ratings.
    sections JSONB NOT NULL,

    -- Flat denormalized dish list for cheap lookups + filtering
    -- without parsing sections every time.
    food_items JSONB NOT NULL DEFAULT '[]',

    -- S3 URLs of the menu pages the user uploaded. Strip across the
    -- header of the sheet when reopened. May be empty if the source
    -- images have aged out of S3.
    menu_photo_urls TEXT[] DEFAULT '{}',

    elapsed_seconds NUMERIC(6,2),

    -- Pin in the Saved Menus grid (shows first, stays on top)
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,

    -- Usage tracking so we can show "opened 3 times" and surface
    -- frequently-used menus first in the history grid.
    times_opened INTEGER NOT NULL DEFAULT 0,
    last_opened_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE menu_analyses IS
    'Persisted menu/buffet analysis results so users can reopen a scan '
    'without re-running Gemini. Feeds the menu_items ChromaDB collection.';

-- ============================================================
-- INDEXES
-- ============================================================

-- Primary access path: list a user's menus newest-first, pinned on top.
CREATE INDEX IF NOT EXISTS idx_menu_analyses_user_pinned_recent
    ON menu_analyses (user_id, is_pinned DESC, last_opened_at DESC NULLS LAST, created_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_menu_analyses_user_created
    ON menu_analyses (user_id, created_at DESC)
    WHERE deleted_at IS NULL;

-- Restaurant-name search for future "have I scanned this place before?" flow.
CREATE INDEX IF NOT EXISTS idx_menu_analyses_restaurant_name
    ON menu_analyses (user_id, lower(restaurant_name))
    WHERE deleted_at IS NULL AND restaurant_name IS NOT NULL;

-- ============================================================
-- ROW-LEVEL SECURITY
-- ============================================================

ALTER TABLE menu_analyses ENABLE ROW LEVEL SECURITY;

-- Users can only see their own menu analyses.
DROP POLICY IF EXISTS menu_analyses_select_own ON menu_analyses;
CREATE POLICY menu_analyses_select_own
    ON menu_analyses FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS menu_analyses_insert_own ON menu_analyses;
CREATE POLICY menu_analyses_insert_own
    ON menu_analyses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS menu_analyses_update_own ON menu_analyses;
CREATE POLICY menu_analyses_update_own
    ON menu_analyses FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS menu_analyses_delete_own ON menu_analyses;
CREATE POLICY menu_analyses_delete_own
    ON menu_analyses FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================
-- AUTO-UPDATE `updated_at`
-- ============================================================

CREATE OR REPLACE FUNCTION menu_analyses_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public;

DROP TRIGGER IF EXISTS trg_menu_analyses_updated_at ON menu_analyses;
CREATE TRIGGER trg_menu_analyses_updated_at
    BEFORE UPDATE ON menu_analyses
    FOR EACH ROW EXECUTE FUNCTION menu_analyses_touch_updated_at();
