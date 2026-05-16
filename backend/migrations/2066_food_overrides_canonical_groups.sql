-- 2066_food_overrides_canonical_groups.sql
--
-- Phase 1 data view feeding the Phase-2 frontend Region dropdown. For a
-- canonical name like "chicken biryani", this view groups the regional
-- recipe variants ("pakistani chicken biryani", "hyderabadi chicken
-- biryani", "kerala chicken biryani", ...) so the per-item edit sheet can
-- render a "Region" dropdown when a base dish has more than one variant.
--
-- The default-region ordering favours Indian (modal user), then US, then
-- everything else. The frontend treats the first element as the default
-- selection unless the user overrides it.
--
-- The region prefix list is intentionally curated. Names without a known
-- regional prefix get their own group of size 1 (filtered out by the
-- HAVING clause).

CREATE OR REPLACE VIEW food_overrides_regional_groups AS
WITH base_dish AS (
  SELECT
    id,
    food_name_normalized,
    display_name,
    region,
    country_name,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    REGEXP_REPLACE(
      food_name_normalized,
      -- Anchored at start; preserves names that don't start with a region.
      '^(pakistani|indian|hyderabadi|kerala|lucknowi|bengali|punjabi|tamil|south indian|north indian|malabar|goan|kashmiri|sindhi|karachi|bombay|mumbai|chinese|cantonese|szechuan|thai|japanese|korean|vietnamese|filipino|indonesian|malaysian|singaporean|italian|sicilian|tuscan|mexican|tex-mex|french|provencal|greek|turkish|lebanese|moroccan|ethiopian|nigerian|brazilian|peruvian|argentinian|colombian|jamaican|cuban|spanish|portuguese|german|polish|russian|ukrainian|swedish|norwegian|danish|finnish|british|english|scottish|irish|american|cajun|creole|southern|tex|new mexican|hawaiian)\s+',
      ''
    ) AS base_name
  FROM food_nutrition_overrides_canonical
)
SELECT
  base_name,
  COUNT(*) AS variant_count,
  ARRAY_AGG(
    json_build_object(
      'id',            id,
      'normalized',    food_name_normalized,
      'display',       display_name,
      'region',        COALESCE(region, country_name),
      'kcal_per_100g', calories_per_100g,
      'protein_g',     protein_per_100g,
      'carbs_g',       carbs_per_100g,
      'fat_g',         fat_per_100g
    )
    ORDER BY
      -- Default-region preference; lower wins.
      CASE COALESCE(LOWER(region), LOWER(country_name))
        WHEN 'in'             THEN 1
        WHEN 'india'          THEN 1
        WHEN 'us'             THEN 2
        WHEN 'united states'  THEN 2
        WHEN 'gb'             THEN 3
        WHEN 'united kingdom' THEN 3
        ELSE 4
      END,
      display_name
  ) AS variants
FROM base_dish
GROUP BY base_name
HAVING COUNT(*) > 1;  -- Multi-variant base dishes only.

COMMENT ON VIEW food_overrides_regional_groups IS
  'Phase-1 view: groups regional recipe variants by stripped base name. Phase-2 frontend Region dropdown reads this to populate alternates inside the per-item edit sheet.';
