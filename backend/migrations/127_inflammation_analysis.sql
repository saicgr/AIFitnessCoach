-- Migration: 127_inflammation_analysis.sql
-- Description: Food inflammation analysis from barcode ingredient scans
-- Created: 2026-01-01

-- ============================================================================
-- INFLAMMATION ANALYSIS TABLE (Cached by barcode)
-- ============================================================================

CREATE TABLE IF NOT EXISTS food_inflammation_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Product identification (cache key)
    barcode VARCHAR(50) NOT NULL,
    product_name VARCHAR(500),

    -- Raw input from Open Food Facts
    ingredients_text TEXT NOT NULL,

    -- Overall product score (1 = highly inflammatory, 10 = highly anti-inflammatory)
    overall_score INTEGER NOT NULL CHECK (overall_score BETWEEN 1 AND 10),
    overall_category VARCHAR(30) NOT NULL,
    -- Categories: 'highly_inflammatory', 'moderately_inflammatory', 'neutral',
    -- 'anti_inflammatory', 'highly_anti_inflammatory'

    -- AI-generated summary
    summary TEXT NOT NULL,
    recommendation TEXT,

    -- Detailed per-ingredient analysis (JSON array)
    -- Structure: [{name, category, score, reason, is_inflammatory, is_additive}]
    ingredient_analyses JSONB NOT NULL DEFAULT '[]',

    -- Flagged concerns for quick access
    inflammatory_ingredients TEXT[] DEFAULT '{}',
    anti_inflammatory_ingredients TEXT[] DEFAULT '{}',
    additives_found TEXT[] DEFAULT '{}',

    -- Metadata
    model_version VARCHAR(50) DEFAULT 'gemini-2.0-flash',
    analysis_confidence DECIMAL(3,2) CHECK (analysis_confidence BETWEEN 0 AND 1),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '90 days'
);

-- ============================================================================
-- USER INFLAMMATION HISTORY (Per-user scan history)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_inflammation_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    analysis_id UUID NOT NULL REFERENCES food_inflammation_analyses(id) ON DELETE CASCADE,

    -- User-specific context
    notes TEXT,
    is_favorited BOOLEAN DEFAULT FALSE,

    -- Timestamps
    scanned_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Cache lookup by barcode (most common query)
CREATE UNIQUE INDEX IF NOT EXISTS idx_inflammation_barcode
    ON food_inflammation_analyses(barcode);

-- Index on expires_at for filtering non-expired analyses
-- Note: Cannot use NOW() in partial index as it requires IMMUTABLE function
CREATE INDEX IF NOT EXISTS idx_inflammation_expires_at
    ON food_inflammation_analyses(expires_at DESC);

-- User history queries
CREATE INDEX IF NOT EXISTS idx_user_inflammation_scans_user
    ON user_inflammation_scans(user_id, scanned_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_inflammation_scans_favorited
    ON user_inflammation_scans(user_id)
    WHERE is_favorited = TRUE;

-- JSONB queries on ingredient analyses
CREATE INDEX IF NOT EXISTS idx_inflammation_ingredients_gin
    ON food_inflammation_analyses USING GIN (ingredient_analyses);

-- Category filtering
CREATE INDEX IF NOT EXISTS idx_inflammation_category
    ON food_inflammation_analyses(overall_category);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE food_inflammation_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_inflammation_scans ENABLE ROW LEVEL SECURITY;

-- Analyses are public (cached globally) - anyone can read
DROP POLICY IF EXISTS inflammation_analyses_select_policy ON food_inflammation_analyses;
CREATE POLICY inflammation_analyses_select_policy
    ON food_inflammation_analyses FOR SELECT
    USING (true);

-- Only service role can insert/update/delete analyses
DROP POLICY IF EXISTS inflammation_analyses_service_policy ON food_inflammation_analyses;
CREATE POLICY inflammation_analyses_service_policy
    ON food_inflammation_analyses FOR ALL
    USING (auth.role() = 'service_role');

-- Users can only see/manage their own scan history
DROP POLICY IF EXISTS user_inflammation_scans_select_policy ON user_inflammation_scans;
CREATE POLICY user_inflammation_scans_select_policy
    ON user_inflammation_scans FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS user_inflammation_scans_insert_policy ON user_inflammation_scans;
CREATE POLICY user_inflammation_scans_insert_policy
    ON user_inflammation_scans FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_inflammation_scans_update_policy ON user_inflammation_scans;
CREATE POLICY user_inflammation_scans_update_policy
    ON user_inflammation_scans FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS user_inflammation_scans_delete_policy ON user_inflammation_scans;
CREATE POLICY user_inflammation_scans_delete_policy
    ON user_inflammation_scans FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- User's scan history with analysis details
CREATE OR REPLACE VIEW user_inflammation_history AS
SELECT
    uis.id AS scan_id,
    uis.user_id,
    uis.scanned_at,
    uis.notes,
    uis.is_favorited,
    fia.barcode,
    fia.product_name,
    fia.overall_score,
    fia.overall_category,
    fia.summary,
    fia.inflammatory_ingredients,
    fia.anti_inflammatory_ingredients
FROM user_inflammation_scans uis
JOIN food_inflammation_analyses fia ON fia.id = uis.analysis_id
ORDER BY uis.scanned_at DESC;

-- Aggregated user inflammation stats
CREATE OR REPLACE VIEW user_inflammation_stats AS
SELECT
    uis.user_id,
    COUNT(*) AS total_scans,
    ROUND(AVG(fia.overall_score), 1) AS avg_inflammation_score,
    COUNT(*) FILTER (WHERE fia.overall_category IN ('highly_inflammatory', 'moderately_inflammatory')) AS inflammatory_products_scanned,
    COUNT(*) FILTER (WHERE fia.overall_category IN ('anti_inflammatory', 'highly_anti_inflammatory')) AS anti_inflammatory_products_scanned,
    MAX(uis.scanned_at) AS last_scan_at
FROM user_inflammation_scans uis
JOIN food_inflammation_analyses fia ON fia.id = uis.analysis_id
GROUP BY uis.user_id;

-- Grant permissions on views
GRANT SELECT ON user_inflammation_history TO authenticated;
GRANT SELECT ON user_inflammation_stats TO authenticated;

-- ============================================================================
-- CLEANUP FUNCTION (for expired analyses without user references)
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_expired_inflammation_analyses()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete analyses that have expired and have no user references
    DELETE FROM food_inflammation_analyses fia
    WHERE fia.expires_at < NOW()
      AND NOT EXISTS (
          SELECT 1 FROM user_inflammation_scans uis
          WHERE uis.analysis_id = fia.id
      );

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE food_inflammation_analyses IS 'Cached AI analysis of ingredient inflammation properties, keyed by barcode';
COMMENT ON TABLE user_inflammation_scans IS 'User-specific history of barcode scans for inflammation analysis';
COMMENT ON COLUMN food_inflammation_analyses.overall_score IS '1-10 scale: 1=highly inflammatory, 10=highly anti-inflammatory';
COMMENT ON COLUMN food_inflammation_analyses.ingredient_analyses IS 'JSON array of per-ingredient analysis results';
COMMENT ON VIEW user_inflammation_history IS 'User scan history joined with analysis details';
COMMENT ON VIEW user_inflammation_stats IS 'Aggregated inflammation statistics per user';
