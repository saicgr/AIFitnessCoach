-- Migration 2326: repair food_logs rows whose persisted meal macro totals were
-- dropped to 0/NULL while the food_items JSON carried real macros (the
-- "714 kcal · 0g/0g/0g" bug fixed at the write path in this same change set).
-- Only rows with NO macros_unknown item are touched — a genuinely-unknown-macro
-- meal keeps its NULL. Backs up affected rows to _bak_2326_food_logs.
-- Applied 2026-07-22: 7 rows repaired.

DROP TABLE IF EXISTS _bak_2326_food_logs;
CREATE TABLE _bak_2326_food_logs AS
WITH agg AS (
  SELECT fl.id,
         SUM(COALESCE((it->>'protein_g')::numeric,0)) AS sum_p,
         SUM(COALESCE((it->>'carbs_g')::numeric,0)) AS sum_c,
         SUM(COALESCE((it->>'fat_g')::numeric,0)) AS sum_f,
         SUM(COALESCE((it->>'calories')::numeric,0)) AS sum_cal,
         bool_or(COALESCE((it->>'macros_unknown')::boolean,false)) AS any_unknown
    FROM food_logs fl
    CROSS JOIN LATERAL jsonb_array_elements(COALESCE(fl.food_items,'[]'::jsonb)) it
   WHERE fl.deleted_at IS NULL
   GROUP BY fl.id
)
SELECT fl.* FROM food_logs fl JOIN agg a ON a.id = fl.id
 WHERE NOT a.any_unknown
   AND (a.sum_p > 0 OR a.sum_c > 0 OR a.sum_f > 0)
   AND (COALESCE(fl.protein_g,0)=0 AND COALESCE(fl.carbs_g,0)=0 AND COALESCE(fl.fat_g,0)=0);

UPDATE food_logs fl SET
  protein_g = a.sum_p,
  carbs_g = a.sum_c,
  fat_g = a.sum_f,
  total_calories = CASE WHEN COALESCE(fl.total_calories,0)=0 THEN a.sum_cal::int ELSE fl.total_calories END,
  updated_at = NOW()
FROM (
  SELECT fl.id,
         SUM(COALESCE((it->>'protein_g')::numeric,0)) AS sum_p,
         SUM(COALESCE((it->>'carbs_g')::numeric,0)) AS sum_c,
         SUM(COALESCE((it->>'fat_g')::numeric,0)) AS sum_f,
         SUM(COALESCE((it->>'calories')::numeric,0)) AS sum_cal,
         bool_or(COALESCE((it->>'macros_unknown')::boolean,false)) AS any_unknown
    FROM food_logs fl
    CROSS JOIN LATERAL jsonb_array_elements(COALESCE(fl.food_items,'[]'::jsonb)) it
   WHERE fl.deleted_at IS NULL
   GROUP BY fl.id
) a
WHERE fl.id = a.id
  AND NOT a.any_unknown
  AND (a.sum_p > 0 OR a.sum_c > 0 OR a.sum_f > 0)
  AND (COALESCE(fl.protein_g,0)=0 AND COALESCE(fl.carbs_g,0)=0 AND COALESCE(fl.fat_g,0)=0);
