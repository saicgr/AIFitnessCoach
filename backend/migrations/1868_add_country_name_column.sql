ALTER TABLE food_nutrition_overrides
  ADD COLUMN IF NOT EXISTS country_name TEXT;

CREATE INDEX IF NOT EXISTS idx_food_overrides_country_name
  ON food_nutrition_overrides(country_name)
  WHERE country_name IS NOT NULL;
