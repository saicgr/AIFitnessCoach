-- 1646_add_region_column.sql
-- Adds a region (ISO 3166-1 alpha-2 country code) column to food_nutrition_overrides
-- to support country-specific food entries (213K+ global foods).

ALTER TABLE food_nutrition_overrides
  ADD COLUMN IF NOT EXISTS region TEXT;

CREATE INDEX IF NOT EXISTS idx_food_overrides_region
  ON food_nutrition_overrides(region)
  WHERE region IS NOT NULL;
