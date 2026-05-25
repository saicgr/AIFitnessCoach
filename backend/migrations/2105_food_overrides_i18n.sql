-- Migration 2105: Food Overrides + Recipes i18n
-- Creates per-locale translation tables for food_nutrition_overrides and
-- user_recipes (the central curated recipe table).
--
-- Per-locale rows beyond 'en' must be populated externally
-- (translation provider TBD). DO NOT call Gemini/OpenAI for batch
-- translation per project policy.
--
-- Seeding: backend/scripts/seed_food_i18n_en.py populates:
--   1. Top-1000 most-logged foods from food_nutrition_overrides → locale='en'
--   2. All user_recipes rows → locale='en'
--
-- OFF note: Open Food Facts sourced rows (source='open_food_facts') may carry
-- localized product_name_XX columns in their raw payload. The seed script
-- reads those where available rather than duplicating the English string.
--
-- All statements are idempotent. Run-safe to apply multiple times.


-- ============================================================================
-- Table 1: food_nutrition_overrides_i18n
-- Per-locale display name, description, and serving labels for food rows.
-- food_id is SERIAL (integer PK) from food_nutrition_overrides.
-- ============================================================================

CREATE TABLE IF NOT EXISTS food_nutrition_overrides_i18n (
    food_id                     INTEGER     NOT NULL,
    locale                      TEXT        NOT NULL,
    name                        TEXT        NOT NULL,
    description                 TEXT,
    common_servings_localized   JSONB       NOT NULL DEFAULT '[]'::jsonb,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (food_id, locale)
);

COMMENT ON TABLE food_nutrition_overrides_i18n IS
    'Per-locale name and serving labels for food_nutrition_overrides rows. '
    'food_id soft-references food_nutrition_overrides.id (SERIAL). '
    'Seeded for top-1000 logged foods; full coverage is a follow-up pass. '
    'OFF-sourced foods (source=''open_food_facts'') prefer the localized '
    'product_name_XX field from the original payload over the English copy.';

COMMENT ON COLUMN food_nutrition_overrides_i18n.common_servings_localized IS
    'JSON array of localized serving labels, e.g. '
    '[{"label": "1 bowl", "weight_g": 240}, {"label": "1 cup", "weight_g": 200}]. '
    'Mirrors the source row''s serving vocabulary in the target locale.';

CREATE INDEX IF NOT EXISTS idx_food_nutrition_overrides_i18n_locale
    ON food_nutrition_overrides_i18n (locale);

CREATE INDEX IF NOT EXISTS idx_food_nutrition_overrides_i18n_food_id
    ON food_nutrition_overrides_i18n (food_id);


-- ============================================================================
-- Table 2: recipes_i18n
-- Per-locale name, description, and instruction steps for user_recipes rows.
-- recipe_id is UUID PK from user_recipes.
-- ============================================================================

CREATE TABLE IF NOT EXISTS recipes_i18n (
    recipe_id               UUID        NOT NULL,
    locale                  TEXT        NOT NULL,
    name                    TEXT        NOT NULL,
    description             TEXT,
    instructions_localized  JSONB       NOT NULL DEFAULT '[]'::jsonb,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (recipe_id, locale)
);

COMMENT ON TABLE recipes_i18n IS
    'Per-locale name, description, and step-by-step instructions for user_recipes. '
    'recipe_id soft-references user_recipes.id (UUID). '
    'Seeded for all rows at time of seed script execution (locale=''en'').';

COMMENT ON COLUMN recipes_i18n.instructions_localized IS
    'JSON array of instruction steps, e.g. '
    '[{"step": 1, "text": "Heat pan over medium heat."}, ...]. '
    'Mirrors the source row''s instructions text split into steps.';

CREATE INDEX IF NOT EXISTS idx_recipes_i18n_locale
    ON recipes_i18n (locale);

CREATE INDEX IF NOT EXISTS idx_recipes_i18n_recipe_id
    ON recipes_i18n (recipe_id);
