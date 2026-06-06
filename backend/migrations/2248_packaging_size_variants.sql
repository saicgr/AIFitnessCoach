-- 2248_packaging_size_variants.sql
-- Fix B4 — seed common KING / SHARE-size packaged-candy variants as DISTINCT
-- rows so a query like "almond joy king size" resolves to the real net weight
-- (91g / 4 pieces) instead of silently matching the standard 45g bar.
--
-- WHY distinct rows: packaging size variants ("King Size", "Share Size") are
-- separate SKUs with their own net weight, NOT loose size adjectives. The base
-- product rows (migration 1576) carry the standard-bar weight; these carry the
-- variant weight. variant_names are DISJOINT from the base rows (the base never
-- lists "king size") so the packaging-qualifier integrity check
-- (food_match_gate.unsatisfied_packaging_qualifiers) treats a base-only match as
-- a mismatch and defers to AI, while these rows satisfy the qualifier exactly.
--
-- Per-100g macros == the base candy (same recipe) — pulled verbatim from the
-- canonical US base rows in 1576. Net weights are researched from
-- manufacturer/retailer listings (hersheyland.com, heb.com), never guessed:
--   Almond Joy King  3.22 oz = 91 g   Snickers King 3.29 oz = 93 g
--   Reese's PB  King 2.8  oz = 79 g   Twix     King 3.02 oz = 86 g
--   Kit Kat    King  3.0  oz = 85 g   Hershey's King 2.6 oz = 74 g
--   M&M's milk Share 3.14 oz = 89 g
--
-- PORTION SEMANTICS: the default logged unit is the WHOLE variant bar/pouch, so
-- default_weight_per_piece_g == default_serving_g and default_count == 1. This
-- matters because _enhance_food_items_with_nutrition_db logs "1 piece =
-- weight_per_piece_g" when the user gives no explicit count — so the per-piece
-- weight MUST be the whole net weight (e.g. 91 g → ~436 cal for "an almond joy
-- king size"), NOT a sub-piece (logging 1 of 4 pieces would 4x-undercount).
--
-- This is a STARTER set, not exhaustive — the runtime auto-capture path
-- (B3: a scanned variant label upserts into food_overrides_user_contributed,
-- promoted by scripts/promote_user_contributed.py) grows it organically.
-- Idempotent: ON CONFLICT (food_name_normalized) DO NOTHING.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

('almond joy king size', 'Almond Joy King Size', 479, 4.1, 59.5, 26.9,
 3.2, 46.0, 91, 91,
 'manufacturer_label', ARRAY['almond joy king size', 'king size almond joy', 'almond joy king'],
 'chocolate', 'Hershey''s', 1,
 '3.22 oz (91 g), 4 internal pieces. ~436 cal for the whole bar. Logged unit = whole king bar.', TRUE),

('snickers king size', 'Snickers King Size', 491, 7.5, 61.0, 23.9,
 2.3, 50.5, 93, 93,
 'manufacturer_label', ARRAY['snickers king size', 'king size snickers', 'snickers share size', 'snickers king'],
 'chocolate', 'Mars', 1,
 '3.29 oz (93 g), 2 internal pieces. ~457 cal for the whole bar. Sold as King/Share Size.', TRUE),

('reeses peanut butter cups king size', 'Reese''s Peanut Butter Cups King Size', 515, 10.2, 55.4, 30.5,
 2.0, 47.0, 79, 79,
 'manufacturer_label', ARRAY['reeses peanut butter cups king size', 'reese''s king size', 'king size reeses', 'reeses king size'],
 'chocolate', 'Hershey''s', 1,
 '2.8 oz (79 g), 4 cups. ~407 cal for the whole pack. Logged unit = whole king pack.', TRUE),

('twix king size', 'Twix King Size', 502, 4.9, 63.7, 25.3,
 0.8, 49.0, 86, 86,
 'manufacturer_label', ARRAY['twix king size', 'king size twix', 'twix king'],
 'chocolate', 'Mars', 1,
 '3.02 oz (86 g), 4 bars. ~432 cal for the whole pack. Logged unit = whole king pack.', TRUE),

('kit kat king size', 'Kit Kat King Size', 518, 6.5, 64.6, 26.0,
 1.5, 49.0, 85, 85,
 'manufacturer_label', ARRAY['kit kat king size', 'king size kit kat', 'kitkat king size', 'kit kat king'],
 'chocolate', 'Hershey''s', 1,
 '3.0 oz (85 g). ~440 cal total. Same wafer recipe as standard bar; king-size pack.', TRUE),

('hersheys milk chocolate king size', 'Hershey''s Milk Chocolate King Size', 512, 7.0, 60.5, 30.2,
 1.2, 54.7, 74, 74,
 'manufacturer_label', ARRAY['hersheys milk chocolate king size', 'hershey king size', 'king size hershey bar', 'hersheys king size'],
 'chocolate', 'Hershey''s', 1,
 '2.6 oz (74 g). ~377 cal total. Same recipe as standard 43 g bar; king-size weight.', TRUE),

('mms milk chocolate share size', 'M&M''s Milk Chocolate Share Size', 492, 4.7, 66.7, 22.0,
 2.0, 61.0, 89, 89,
 'manufacturer_label', ARRAY['mms milk chocolate share size', 'm&m''s share size', 'share size m&ms', 'm&ms share size', 'mms share size'],
 'chocolate', 'Mars', 1,
 '3.14 oz (89 g). ~438 cal total. Same recipe as standard pack; share-size pouch.', TRUE)

ON CONFLICT (food_name_normalized) DO NOTHING;
