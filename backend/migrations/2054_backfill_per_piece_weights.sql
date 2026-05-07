-- Backfill default_weight_per_piece_g for countable foods where the column was NULL.
--
-- Context (2026-05-07): A user logged "8 boneless wings" in the iOS food estimator
-- and got a 2122-kcal estimate (should be ~600 kcal). Root cause traced through
-- the pipeline:
--   L1  Gemini Vision      → guessed weight_per_unit_g = 85g (the bone-in number).
--   L2  parsers.py:441     → batch_lookup_foods("buffalo chicken wings") matched
--                            the BWW Boneless row, BUT default_weight_per_piece_g
--                            was NULL → override branch skipped → Gemini's 85g
--                            stuck → 8 × 85g = 680g, 680g × ~3 kcal/g = 2122 kcal.
--   L3  No sanity gate     → 2122 kcal accepted, written to food_log.
--
-- This migration fixes L2: backfills the per-piece weight on every countable
-- "wing / nugget / meatball / tender / bite" row that was missing it. With this
-- in place, the parser's existing override branch (lines 471-494) takes over
-- and produces `count × per_piece_g` directly from DB-verified data.
--
-- L3 (sanity gate) is a separate code change in parsers.py — see same commit.
-- L1 (prompt) was reverted; prompt-based portion guidance does not scale.
--
-- Idempotent: only updates rows where default_weight_per_piece_g IS NULL.

BEGIN;

-- Boneless wings / breaded chicken bite (≈28g per piece)
-- Includes generic + BWW + Applebee's + boneless variants. The food itself is
-- a breaded ~28g piece of chicken breast, NOT a real wing — different physics.
UPDATE food_nutrition_overrides
   SET default_weight_per_piece_g = 28
 WHERE default_weight_per_piece_g IS NULL
   AND (
       display_name ILIKE '%boneless%wing%'
    OR display_name ILIKE '%boneless%buffalo%'
    OR display_name ILIKE '%boneless%bite%'
    OR display_name ILIKE '%chicken bite%'
    OR food_name_normalized ILIKE '%boneless%wing%'
   );

-- Bone-in chicken wings whole, sauced (≈40g average; drumette ~30g, flat ~50g)
-- The bone is ~40% of mass — the same 100g serving has less edible meat than
-- boneless, which is why kcal/100g is lower (≈230-310 vs ≈280-300).
UPDATE food_nutrition_overrides
   SET default_weight_per_piece_g = 40
 WHERE default_weight_per_piece_g IS NULL
   AND (
       (display_name ILIKE '%wing%' AND display_name NOT ILIKE '%boneless%')
    OR display_name ILIKE 'buffalo wing%'
    OR display_name ILIKE 'buffalo chicken wing%'
    OR display_name ILIKE 'jerk wing%'
    OR display_name ILIKE 'spicy wing%'
   )
   AND food_category NOT IN ('beverage', 'soup');

-- Chicken nugget / popcorn chicken / chicken popper (≈18g per piece)
UPDATE food_nutrition_overrides
   SET default_weight_per_piece_g = 18
 WHERE default_weight_per_piece_g IS NULL
   AND (
       display_name ILIKE '%nugget%'
    OR display_name ILIKE 'popcorn chicken%'
    OR display_name ILIKE 'chicken popper%'
   );

-- Chicken tender / strip / finger (≈45g per piece — larger than nuggets)
UPDATE food_nutrition_overrides
   SET default_weight_per_piece_g = 45
 WHERE default_weight_per_piece_g IS NULL
   AND (
       display_name ILIKE '%chicken tender%'
    OR display_name ILIKE '%chicken strip%'
    OR display_name ILIKE '%chicken finger%'
   );

-- Meatball (≈30g per piece — covers cocktail, Italian, Swedish)
UPDATE food_nutrition_overrides
   SET default_weight_per_piece_g = 30
 WHERE default_weight_per_piece_g IS NULL
   AND display_name ILIKE '%meatball%';

-- Mozzarella stick / cheese stick (≈25g per piece)
UPDATE food_nutrition_overrides
   SET default_weight_per_piece_g = 25
 WHERE default_weight_per_piece_g IS NULL
   AND (
       display_name ILIKE '%mozzarella stick%'
    OR display_name ILIKE '%cheese stick%'
   );

-- Verify nothing broke: any row updated should still have a sensible serving
-- size relative to its per-piece weight (5–30 pieces per serving).
DO $$
DECLARE
  bad_count int;
BEGIN
  SELECT COUNT(*) INTO bad_count
    FROM food_nutrition_overrides
   WHERE default_weight_per_piece_g IS NOT NULL
     AND default_serving_g IS NOT NULL
     AND default_weight_per_piece_g > default_serving_g;
  IF bad_count > 0 THEN
    RAISE NOTICE '⚠ % rows have per_piece_g > serving_g — review manually', bad_count;
  END IF;
END $$;

COMMIT;
