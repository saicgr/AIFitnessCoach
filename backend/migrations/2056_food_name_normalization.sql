-- Migration 2056: Food name normalization across recipe / saved-food / grocery surfaces.
--
-- Why: saving "Idli", "idli", and "Idlis" creates 3 separate rows in user_recipes,
-- saved_foods, and grocery_list_items today because only `user_food_overrides` uses
-- normalize_food_name (Python-side). This migration introduces an IMMUTABLE SQL
-- normalizer + lemmatizer + GENERATED STORED columns + unique indexes so dedupe is
-- enforced at the DB layer, can't drift from the Python implementation, and doesn't
-- require backend insert paths to remember to compute the normalized form.
--
-- Approach: GENERATED ALWAYS AS (normalize_food_name_sql(<raw>)) STORED on each
-- surface. Postgres recomputes on every UPDATE of the source column; backfill happens
-- automatically when the column is added. Backend only ever READS the *_normalized
-- columns (for the pre-insert dedupe SELECT) — never writes them.

-- ─── Required extension ─────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS unaccent;

-- ─── Lemmatization helper ────────────────────────────────────────
-- Handles common food plurals: irregular overrides for Indian / global cuisine
-- where suffix rules fail (idlis → idli, curries → curry), then generic English
-- suffix rules (-ies → -y, -es → -, -s → -). Marked IMMUTABLE so it's usable in
-- GENERATED columns and unique indexes.
CREATE OR REPLACE FUNCTION lemmatize_food_word(w TEXT) RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE AS $$
BEGIN
  IF w IS NULL OR length(w) = 0 THEN RETURN w; END IF;
  -- Irregular / known-cuisine overrides first.
  CASE w
    WHEN 'idlis'    THEN RETURN 'idli';
    WHEN 'samosas'  THEN RETURN 'samosa';
    WHEN 'parathas' THEN RETURN 'paratha';
    WHEN 'chutneys' THEN RETURN 'chutney';
    WHEN 'rotis'    THEN RETURN 'roti';
    WHEN 'curries'  THEN RETURN 'curry';
    WHEN 'tomatoes' THEN RETURN 'tomato';
    WHEN 'potatoes' THEN RETURN 'potato';
    WHEN 'cookies'  THEN RETURN 'cookie';
    WHEN 'brownies' THEN RETURN 'brownie';
    WHEN 'berries'  THEN RETURN 'berry';
    WHEN 'cherries' THEN RETURN 'cherry';
    WHEN 'leaves'   THEN RETURN 'leaf';
    WHEN 'loaves'   THEN RETURN 'loaf';
    WHEN 'knives'   THEN RETURN 'knife';
    ELSE NULL;
  END CASE;
  -- Generic suffix rules.
  IF w ~ 'ies$' AND length(w) > 4 THEN
    RETURN regexp_replace(w, 'ies$', 'y');
  ELSIF w ~ '(ses|xes|zes|ches|shes)$' THEN
    RETURN regexp_replace(w, 'es$', '');
  ELSIF w ~ 's$' AND w !~ '(ss|us|is)$' AND length(w) > 3 THEN
    RETURN regexp_replace(w, 's$', '');
  END IF;
  RETURN w;
END $$;

-- ─── Main normalizer ─────────────────────────────────────────────
-- 1. lower-case
-- 2. strip diacritics via unaccent (Crème Brûlée → Creme Brulee)
-- 3. drop everything outside [a-z0-9 ]
-- 4. split into words, lemmatize each, rejoin
-- 5. collapse whitespace + trim
-- IMMUTABLE so it can be used in GENERATED STORED columns and indexes.
CREATE OR REPLACE FUNCTION normalize_food_name_sql(name TEXT) RETURNS TEXT
LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
  SELECT trim(BOTH ' ' FROM
    coalesce(
      (
        SELECT string_agg(lemmatize_food_word(w), ' ')
        FROM unnest(
          regexp_split_to_array(
            regexp_replace(
              lower(unaccent(coalesce(name, ''))),
              '[^a-z0-9 ]', ' ', 'g'
            ),
            '\s+'
          )
        ) AS w
        WHERE w <> ''
      ),
      ''
    )
  )
$$;

-- ─── Generated stored columns on every food-name surface ────────
-- These backfill automatically on column-add (Postgres computes for each row).

ALTER TABLE user_recipes
  ADD COLUMN IF NOT EXISTS name_normalized TEXT
  GENERATED ALWAYS AS (normalize_food_name_sql(name)) STORED;

ALTER TABLE recipe_ingredients
  ADD COLUMN IF NOT EXISTS food_name_normalized TEXT
  GENERATED ALWAYS AS (normalize_food_name_sql(food_name)) STORED;

ALTER TABLE saved_foods
  ADD COLUMN IF NOT EXISTS name_normalized TEXT
  GENERATED ALWAYS AS (normalize_food_name_sql(name)) STORED;

ALTER TABLE grocery_list_items
  ADD COLUMN IF NOT EXISTS ingredient_name_normalized TEXT
  GENERATED ALWAYS AS (normalize_food_name_sql(ingredient_name)) STORED;

-- ─── Indexes ─────────────────────────────────────────────────────
-- Unique-per-user dedupe on recipes + saved foods (soft-deleted rows excluded).
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_recipes_user_name_norm
  ON user_recipes(user_id, name_normalized) WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_saved_foods_user_name_norm
  ON saved_foods(user_id, name_normalized)  WHERE deleted_at IS NULL;

-- Lookup index for grocery list aggregation (NOT unique — quantities sum).
CREATE INDEX IF NOT EXISTS idx_grocery_items_list_name_norm
  ON grocery_list_items(list_id, ingredient_name_normalized);

-- Lookup index for ingredient search across recipes.
CREATE INDEX IF NOT EXISTS idx_recipe_ing_name_norm
  ON recipe_ingredients(food_name_normalized);
