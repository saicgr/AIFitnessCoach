-- Migration 2226: Pregnancy + lactation RDA targets on nutrient_rdas.
-- Source: NIH ODS Dietary Reference Intakes (adult 19-50). Populated only where
-- the value DIFFERS from the non-pregnant female RDA; NULL rows let
-- get_micronutrient_gaps fall back to rda_target_female. Applied to the live DB
-- 2026-06-01 via Supabase MCP.

ALTER TABLE nutrient_rdas ADD COLUMN IF NOT EXISTS rda_target_pregnant DECIMAL(10,2);
ALTER TABLE nutrient_rdas ADD COLUMN IF NOT EXISTS rda_target_lactating DECIMAL(10,2);

UPDATE nutrient_rdas SET rda_target_pregnant = v.preg, rda_target_lactating = v.lact
FROM (VALUES
    ('vitamin_a_ug',   770.0, 1300.0),
    ('vitamin_c_mg',    85.0,  120.0),
    ('vitamin_e_mg',    NULL::numeric,   19.0),
    ('vitamin_k_ug',    90.0,   90.0),
    ('vitamin_b1_mg',    1.4,    1.4),
    ('vitamin_b2_mg',    1.4,    1.6),
    ('vitamin_b3_mg',   18.0,   17.0),
    ('vitamin_b6_mg',    1.9,    2.0),
    ('vitamin_b9_ug',  600.0,  500.0),
    ('vitamin_b12_ug',   2.6,    2.8),
    ('choline_mg',     450.0,  550.0),
    ('iron_mg',         27.0,    9.0),
    ('magnesium_mg',   350.0,  310.0),
    ('zinc_mg',         11.0,   12.0),
    ('selenium_ug',     60.0,   70.0),
    ('iodine_ug',      220.0,  290.0),
    ('copper_mg',        1.0,    1.3),
    ('manganese_mg',     2.0,    2.6),
    ('omega3_g',         1.4,    1.3),
    ('omega6_g',        13.0,   13.0),
    ('fiber_g',         28.0,   29.0),
    ('water_ml',      3000.0, 3800.0)
) AS v(nutrient_key, preg, lact)
WHERE nutrient_rdas.nutrient_key = v.nutrient_key;
