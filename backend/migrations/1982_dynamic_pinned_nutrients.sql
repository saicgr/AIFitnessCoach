-- 1982_dynamic_pinned_nutrients.sql
--
-- Adds the schema needed by the dynamic-pinned-nutrients feature. The
-- "Pinned nutrients" card on the Daily tab used to render a hardcoded
-- list (Vit D / Calcium / Iron / Omega-3) regardless of what was logged.
-- This migration enables computing the list per-day from today's actual
-- intake — so a pizza day surfaces Sodium / Saturated Fat over Omega-3.
--
-- Two columns added:
--   1. users.pinned_nutrients_mode TEXT NOT NULL DEFAULT 'static'
--      'static' = legacy behavior (read from users.pinned_nutrients).
--      'dynamic' = compute top-N nutrients from today's food_logs.
--      Existing users default to 'static' to avoid surprise behavior
--      changes; new accounts get 'dynamic' set in onboarding.
--
--   2. nutrient_rdas.penalty BOOLEAN NOT NULL DEFAULT FALSE
--      Marks "interesting when exceeded" nutrients (sodium, saturated
--      fat, added sugar, cholesterol). Dynamic-pinning logic surfaces
--      these as orange `over_ceiling` chips when today's logs push past
--      the safe ceiling — that's a more actionable signal than a 70%
--      vitamin C reading.

-- ---- users.pinned_nutrients_mode ----
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS pinned_nutrients_mode TEXT NOT NULL DEFAULT 'static'
        CHECK (pinned_nutrients_mode IN ('static', 'dynamic'));

COMMENT ON COLUMN users.pinned_nutrients_mode IS
    'How the Daily-tab pinned nutrients card is populated. ''static'' = read users.pinned_nutrients; ''dynamic'' = compute top-N from today''s food_logs by % of RDA contribution (penalty nutrients can appear when over ceiling).';

-- ---- nutrient_rdas.penalty ----
ALTER TABLE nutrient_rdas
    ADD COLUMN IF NOT EXISTS penalty BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN nutrient_rdas.penalty IS
    'TRUE when this nutrient is "interesting when exceeded" (sodium, saturated fat, added sugar, cholesterol). Dynamic-pinned-nutrient selection surfaces these with status=''over_ceiling'' even if the user hit other RDAs more strongly today.';

-- Seed the standard penalty set. Use ANY() so this works regardless of
-- which exact key form (sodium_mg vs sodium) the table happens to use.
UPDATE nutrient_rdas
SET penalty = TRUE
WHERE nutrient_key = ANY (ARRAY[
    'sodium_mg', 'sodium',
    'saturated_fat_g', 'saturated_fat',
    'added_sugar_g', 'added_sugar',
    'cholesterol_mg', 'cholesterol',
    'trans_fat_g', 'trans_fat'
]);
