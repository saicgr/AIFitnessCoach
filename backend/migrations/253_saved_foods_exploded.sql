-- Migration 253: saved_foods_exploded view + search_food_database_unified RPC
-- Purpose: Expose both composite saved meals and their individual items for food search
-- Created: 2026-02-16
--
-- Prerequisites:
--   - saved_foods table with columns: id (uuid), user_id (uuid), name, calories,
--     protein_g, carbs_g, fat_g, fiber_g, source_type, times_logged,
--     food_items (jsonb array), deleted_at
--   - search_food_database(TEXT, INT, INT) function (from food_database_rpc.sql)

-- ============================================================================
-- VIEW: saved_foods_exploded
-- UNIONs composite (full meal) rows and their individual food items.
-- Individual items are only extracted when food_items has more than one element.
-- ============================================================================

CREATE OR REPLACE VIEW saved_foods_exploded AS

  -- Part 1: Original composite rows (full meal)
  SELECT
    sf.id                 AS saved_food_id,
    sf.user_id,
    sf.name               AS name,
    sf.total_calories     AS calories,
    sf.total_protein_g    AS protein_g,
    sf.total_carbs_g      AS carbs_g,
    sf.total_fat_g        AS fat_g,
    sf.total_fiber_g      AS fiber_g,
    sf.source_type        AS source_type,
    sf.times_logged       AS times_logged,
    TRUE                  AS is_composite,
    NULL::INT             AS item_index
  FROM saved_foods sf
  WHERE sf.deleted_at IS NULL

UNION ALL

  -- Part 2: Individual items extracted from food_items JSONB array
  -- Only explode meals that have more than one item
  SELECT
    sf.id                               AS saved_food_id,
    sf.user_id,
    (t.item->>'name')::TEXT             AS name,
    (t.item->>'calories')::INTEGER      AS calories,
    (t.item->>'protein_g')::DECIMAL     AS protein_g,
    (t.item->>'carbs_g')::DECIMAL       AS carbs_g,
    (t.item->>'fat_g')::DECIMAL         AS fat_g,
    (t.item->>'fiber_g')::DECIMAL       AS fiber_g,
    sf.source_type                      AS source_type,
    sf.times_logged                     AS times_logged,
    FALSE                               AS is_composite,
    (t.item_index - 1)::INT             AS item_index   -- convert 1-based ordinality to 0-based
  FROM saved_foods sf,
       jsonb_array_elements(sf.food_items) WITH ORDINALITY AS t(item, item_index)
  WHERE sf.deleted_at IS NULL
    AND jsonb_array_length(sf.food_items) > 1;

COMMENT ON VIEW saved_foods_exploded IS
  'Exploded view of saved_foods: composite (full meal) rows plus individual items extracted '
  'from food_items JSONB. Individual items are only shown when the meal has more than one item. '
  'item_index is 0-based; is_composite = TRUE for the original meal row.';


-- ============================================================================
-- FUNCTION: search_food_database_unified
-- Unified food search that merges curated food_database results with the
-- caller's personal saved foods (composite meals + individual items).
-- ============================================================================

CREATE OR REPLACE FUNCTION search_food_database_unified(
    search_query   TEXT,
    p_user_id      UUID    DEFAULT NULL,
    result_limit   INT     DEFAULT 20,
    result_offset  INT     DEFAULT 0
)
RETURNS TABLE (
    id                 TEXT,
    name               TEXT,
    source             TEXT,
    brand              TEXT,
    category           TEXT,
    calories_per_100g  REAL,
    protein_per_100g   REAL,
    fat_per_100g       REAL,
    carbs_per_100g     REAL,
    fiber_per_100g     REAL,
    sugar_per_100g     REAL,
    serving_description TEXT,
    serving_weight_g   REAL,
    similarity_score   REAL
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Fast path: no user context, just delegate to the base function
    IF p_user_id IS NULL THEN
        RETURN QUERY
        SELECT
            sfd.id::TEXT,
            sfd.name,
            sfd.source,
            sfd.brand,
            sfd.category,
            sfd.calories_per_100g,
            sfd.protein_per_100g,
            sfd.fat_per_100g,
            sfd.carbs_per_100g,
            sfd.fiber_per_100g,
            sfd.sugar_per_100g,
            sfd.serving_description,
            sfd.serving_weight_g,
            sfd.similarity_score
        FROM search_food_database(search_query, result_limit, result_offset) sfd;

        RETURN;
    END IF;

    -- Full path: merge curated DB results with personal saved foods
    RETURN QUERY
    WITH curated AS (
        -- Curated food database results (pass full limit; final sort re-ranks everything)
        SELECT
            sfd.id::TEXT           AS id,
            sfd.name               AS name,
            sfd.source             AS source,
            sfd.brand              AS brand,
            sfd.category           AS category,
            sfd.calories_per_100g  AS calories_per_100g,
            sfd.protein_per_100g   AS protein_per_100g,
            sfd.fat_per_100g       AS fat_per_100g,
            sfd.carbs_per_100g     AS carbs_per_100g,
            sfd.fiber_per_100g     AS fiber_per_100g,
            sfd.sugar_per_100g     AS sugar_per_100g,
            sfd.serving_description AS serving_description,
            sfd.serving_weight_g   AS serving_weight_g,
            sfd.similarity_score   AS similarity_score
        FROM search_food_database(search_query, result_limit, result_offset) sfd
    ),
    saved AS (
        -- Personal saved food matches (composite meals + individual items)
        SELECT
            sfe.saved_food_id::TEXT  AS id,
            sfe.name                 AS name,
            -- source distinguishes full meal from individual item
            CASE WHEN sfe.is_composite THEN 'saved' ELSE 'saved_item' END AS source,
            NULL::TEXT               AS brand,
            NULL::TEXT               AS category,
            -- Use absolute macro values as per-serving values
            ABS(sfe.calories)::REAL  AS calories_per_100g,
            ABS(sfe.protein_g)::REAL AS protein_per_100g,
            ABS(sfe.fat_g)::REAL     AS fat_per_100g,
            ABS(sfe.carbs_g)::REAL   AS carbs_per_100g,
            ABS(sfe.fiber_g)::REAL   AS fiber_per_100g,
            0.0::REAL                AS sugar_per_100g,
            'per serving'::TEXT      AS serving_description,
            NULL::REAL               AS serving_weight_g,
            -- Slight ranking boost for personal items so they surface ahead of generic matches
            0.85::REAL               AS similarity_score
        FROM saved_foods_exploded sfe
        WHERE sfe.user_id = p_user_id
          AND LOWER(sfe.name) LIKE LOWER('%' || search_query || '%')
    )
    -- Merge both sets, rank by similarity_score, then apply pagination
    SELECT
        u.id,
        u.name,
        u.source,
        u.brand,
        u.category,
        u.calories_per_100g,
        u.protein_per_100g,
        u.fat_per_100g,
        u.carbs_per_100g,
        u.fiber_per_100g,
        u.sugar_per_100g,
        u.serving_description,
        u.serving_weight_g,
        u.similarity_score
    FROM (
        SELECT * FROM curated
        UNION ALL
        SELECT * FROM saved
    ) u
    ORDER BY u.similarity_score DESC
    LIMIT result_limit
    OFFSET result_offset;
END;
$$;

COMMENT ON FUNCTION search_food_database_unified IS
  'Unified food search combining curated food_database results with the user''s personal '
  'saved foods (composite meals and individual items). When p_user_id is NULL the function '
  'delegates directly to search_food_database. Personal items receive a fixed similarity_score '
  'of 0.85 to boost them above generic matches. Returns id as TEXT to accommodate both '
  'BIGINT food_database ids and UUID saved_foods ids.';

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION search_food_database_unified(TEXT, UUID, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION search_food_database_unified(TEXT, UUID, INT, INT) TO service_role;

-- ============================================================================
-- INDEXES (support the saved_foods_exploded WHERE clause)
-- ============================================================================

-- Index to speed up the user_id + deleted_at filter in the view / unified search
CREATE INDEX IF NOT EXISTS idx_saved_foods_user_deleted
    ON saved_foods(user_id, deleted_at)
    WHERE deleted_at IS NULL;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
