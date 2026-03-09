-- 1644_create_verified_foods_table.sql
-- Creates the verified_foods table: quality-filtered items from food_database (528K).
-- Three-tier search: overrides (hand-curated) > verified_foods (quality-checked) > food_database (raw).
-- Requires pg_trgm extension (already enabled).

-- ═══════════════════════════════════════════════
-- TABLE
-- ═══════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS verified_foods (
  id BIGSERIAL PRIMARY KEY,
  food_name_normalized TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,

  -- Macros per 100g
  calories_per_100g REAL,
  protein_per_100g REAL,
  carbs_per_100g REAL,
  fat_per_100g REAL,
  fiber_per_100g REAL,
  sugar_per_100g REAL,

  -- Serving info
  default_serving_g REAL,
  default_weight_per_piece_g REAL,
  default_count INT DEFAULT 1,

  -- Source & categorization
  source TEXT NOT NULL,  -- 'usda_lab', 'usda_branded', 'off_verified'
  source_id TEXT,        -- original FDC ID or OFF barcode
  variant_names TEXT[],
  food_category TEXT,
  brand TEXT,

  -- Verification metadata
  verification_level TEXT NOT NULL DEFAULT 'manufacturer_verified',
  data_completeness_score REAL DEFAULT 0,
  last_verified_at TIMESTAMPTZ DEFAULT NOW(),

  -- Micronutrients per 100g (optional)
  sodium_mg REAL,
  cholesterol_mg REAL,
  saturated_fat_g REAL,
  potassium_mg REAL,
  calcium_mg REAL,
  iron_mg REAL,
  vitamin_a_ug REAL,
  vitamin_c_mg REAL,
  vitamin_d_iu REAL,

  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_verified_foods_name_trgm
  ON verified_foods USING gin (food_name_normalized gin_trgm_ops)
  WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_verified_foods_brand
  ON verified_foods(brand)
  WHERE brand IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_verified_foods_category
  ON verified_foods(food_category)
  WHERE food_category IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_verified_foods_verification
  ON verified_foods(verification_level);

CREATE INDEX IF NOT EXISTS idx_verified_foods_variant_names
  ON verified_foods USING gin(variant_names)
  WHERE variant_names IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_verified_foods_completeness
  ON verified_foods(data_completeness_score DESC)
  WHERE is_active = TRUE;

-- ═══════════════════════════════════════════════
-- SEARCH RPC
-- ═══════════════════════════════════════════════

CREATE OR REPLACE FUNCTION search_verified_foods(
  query TEXT, lim INT DEFAULT 20, off_set INT DEFAULT 0
) RETURNS TABLE(
  id BIGINT,
  food_name_normalized TEXT,
  display_name TEXT,
  calories_per_100g REAL,
  protein_per_100g REAL,
  carbs_per_100g REAL,
  fat_per_100g REAL,
  fiber_per_100g REAL,
  sugar_per_100g REAL,
  default_serving_g REAL,
  default_weight_per_piece_g REAL,
  source TEXT,
  brand TEXT,
  food_category TEXT,
  verification_level TEXT,
  variant_names TEXT[],
  similarity_score REAL
) AS $$
BEGIN
  SET LOCAL work_mem = '16MB';
  RETURN QUERY
  SELECT
    vf.id,
    vf.food_name_normalized,
    vf.display_name,
    vf.calories_per_100g,
    vf.protein_per_100g,
    vf.carbs_per_100g,
    vf.fat_per_100g,
    vf.fiber_per_100g,
    vf.sugar_per_100g,
    vf.default_serving_g,
    vf.default_weight_per_piece_g,
    vf.source,
    vf.brand,
    vf.food_category,
    vf.verification_level,
    vf.variant_names,
    similarity(vf.food_name_normalized, lower(query)) AS similarity_score
  FROM verified_foods vf
  WHERE vf.is_active = TRUE
    AND vf.food_name_normalized % lower(query)
  ORDER BY
    CASE vf.verification_level
      WHEN 'lab_verified' THEN 0
      WHEN 'manufacturer_verified' THEN 1
      WHEN 'community_verified' THEN 2
    END,
    similarity(vf.food_name_normalized, lower(query)) DESC,
    vf.display_name ASC
  LIMIT lim OFFSET off_set;
END;
$$ LANGUAGE plpgsql STABLE;
