-- Migration 2253: nutrient_rdas.is_antioxidant — flag the dietary antioxidants.
--
-- Powers the Antioxidant rollup (api/v1/nutrition/micronutrients.py): sum the flagged
-- nutrients' intake vs their combined RDA targets to produce a 0-100 antioxidant score
-- + 14-day trend. We track these from REAL logged food (food_logs columns), so this is
-- stronger than a wrist-optical proxy like Samsung's Antioxidant Index.
--
-- Antioxidant set (NIH ODS / classic dietary antioxidants): vitamin A (as carotenoids),
-- vitamin C, vitamin E, selenium, zinc, copper, manganese.
--
-- Idempotent: ADD COLUMN IF NOT EXISTS + keyed UPDATE.

ALTER TABLE nutrient_rdas ADD COLUMN IF NOT EXISTS is_antioxidant BOOLEAN NOT NULL DEFAULT false;

UPDATE nutrient_rdas
SET is_antioxidant = true
WHERE nutrient_key IN (
    'vitamin_a_ug',
    'vitamin_c_mg',
    'vitamin_e_mg',
    'selenium_ug',
    'zinc_mg',
    'copper_mg',
    'manganese_mg'
);

COMMENT ON COLUMN nutrient_rdas.is_antioxidant IS
    'True for dietary antioxidants (vit A/C/E, selenium, zinc, copper, manganese). '
    'Summed vs combined RDA to produce the Antioxidant rollup score.';
