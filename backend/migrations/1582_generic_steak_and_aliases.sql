-- ============================================================================
-- Migration 1582: Add generic "steak" entry + common missing generic food aliases
-- Purpose: When users say "medium rare steak" or just "steak", the modifier
-- parser strips "medium rare" and looks up "steak" — this entry ensures a match.
-- Uses sirloin nutritional profile as generic default (most common when unspecified).
-- Also adds other common generic terms that may not have standalone entries.
-- ============================================================================

-- Generic steak → uses sirloin stats (183 cal/100g, 29.2g protein, 6.8g fat)
INSERT INTO food_nutrition_overrides (
    food_name_normalized, display_name, calories_per_100g, protein_per_100g,
    carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g,
    restaurant_name, default_serving_grams, source, alternate_names,
    notes, category, is_verified
) VALUES
    ('steak', 'Steak (Beef, Grilled)', 183.0, 29.2, 0.0, 6.8, 0.0, 0.0,
     NULL, 200, 'usda',
     ARRAY['beef steak', 'grilled steak', 'steak dinner', 'steak medium rare', 'cooked steak'],
     '366 cal per 7oz steak (~200g). Generic beef steak, sirloin-based estimate. Specify cut (ribeye, filet mignon, NY strip) for more accurate results.',
     'proteins', true),

    ('chicken', 'Chicken Breast (Grilled, Skinless)', 165.0, 31.0, 0.0, 3.6, 0.0, 0.0,
     NULL, 120, 'usda',
     ARRAY['plain chicken', 'grilled chicken', 'cooked chicken', 'chicken piece'],
     '198 cal per breast (~120g). Defaults to grilled skinless breast. Specify thigh/wing/drumstick for other cuts.',
     'proteins', true),

    ('fish', 'Fish Fillet (Baked, Generic White Fish)', 105.0, 22.0, 0.0, 1.5, 0.0, 0.0,
     NULL, 170, 'usda',
     ARRAY['white fish', 'fish fillet', 'baked fish', 'grilled fish', 'cooked fish', 'fish piece'],
     '179 cal per fillet (~170g). Generic white fish estimate (tilapia/cod/haddock). Specify species for accuracy.',
     'proteins', true),

    ('rice', 'White Rice (Cooked)', 130.0, 2.7, 28.0, 0.3, 0.4, 0.0,
     NULL, 200, 'usda',
     ARRAY['plain rice', 'cooked rice', 'steamed rice', 'white rice', 'basmati rice cooked'],
     '260 cal per cup cooked (~200g). Generic white rice. Specify brown/jasmine/basmati for variants.',
     'grains', true),

    ('pasta', 'Pasta (Cooked, Plain)', 131.0, 5.0, 25.0, 1.1, 1.8, 0.6,
     NULL, 200, 'usda',
     ARRAY['plain pasta', 'cooked pasta', 'spaghetti cooked', 'penne cooked', 'boiled pasta', 'noodles cooked'],
     '262 cal per cup cooked (~200g). Plain pasta without sauce.',
     'grains', true),

    ('bread', 'Bread (White, 1 Slice)', 265.0, 9.0, 49.0, 3.2, 2.7, 5.0,
     NULL, 30, 'usda',
     ARRAY['white bread', 'slice of bread', 'bread slice', 'toast bread', 'sliced bread'],
     '80 cal per slice (~30g). Standard white bread.',
     'grains', true),

    ('egg', 'Egg (Large, Whole, Cooked)', 155.0, 13.0, 1.1, 11.0, 0.0, 1.1,
     NULL, 50, 'usda',
     ARRAY['boiled egg', 'cooked egg', 'whole egg', 'fried egg', 'scrambled egg'],
     '78 cal per large egg (~50g). Whole egg, cooked any style.',
     'proteins', true),

    ('salad', 'Mixed Green Salad (No Dressing)', 20.0, 1.5, 3.5, 0.2, 1.8, 1.5,
     NULL, 100, 'usda',
     ARRAY['green salad', 'garden salad', 'side salad', 'mixed salad', 'plain salad', 'house salad'],
     '20 cal per cup (~100g). Greens only, no dressing. Add dressing modifier for full calories.',
     'vegetables', true),

    ('soup', 'Soup (Vegetable, Generic)', 45.0, 2.0, 7.0, 1.0, 1.5, 2.0,
     NULL, 250, 'usda_estimated',
     ARRAY['bowl of soup', 'cup of soup', 'vegetable soup', 'broth soup'],
     '113 cal per bowl (~250ml). Generic veg soup. Specify type (tomato/chicken/lentil) for accuracy.',
     'soups', true),

    ('burger', 'Hamburger (Single Patty, Bun)', 250.0, 14.0, 24.0, 11.0, 1.0, 5.0,
     NULL, 150, 'usda_estimated',
     ARRAY['hamburger', 'beef burger', 'plain burger', 'regular burger', 'cheeseburger'],
     '375 cal per burger (~150g). Single patty + bun. Add cheese/bacon modifiers separately.',
     'fast_food', true),

    ('sandwich', 'Sandwich (Turkey & Cheese)', 210.0, 13.0, 22.0, 8.0, 1.5, 3.0,
     NULL, 170, 'usda_estimated',
     ARRAY['regular sandwich', 'deli sandwich', 'lunch sandwich', 'cold sandwich'],
     '357 cal per sandwich (~170g). Generic deli-style. Specify type for accuracy.',
     'fast_food', true),

    ('pizza', 'Pizza Slice (Cheese)', 266.0, 11.0, 33.0, 10.0, 2.0, 3.5,
     NULL, 107, 'usda',
     ARRAY['pizza slice', 'slice of pizza', 'cheese pizza', 'plain pizza', 'regular pizza'],
     '285 cal per slice (~107g). Standard cheese pizza slice.',
     'fast_food', true),

    ('fries', 'French Fries (Medium)', 312.0, 3.4, 41.0, 15.0, 3.8, 0.3,
     NULL, 117, 'usda',
     ARRAY['french fries', 'chips', 'potato fries', 'fried potatoes'],
     '365 cal per medium serving (~117g).',
     'fast_food', true),

    ('noodles', 'Noodles (Cooked, Plain)', 138.0, 4.5, 25.0, 2.0, 1.0, 0.5,
     NULL, 200, 'usda_estimated',
     ARRAY['plain noodles', 'cooked noodles', 'egg noodles cooked', 'ramen noodles plain'],
     '276 cal per cup cooked (~200g). Plain noodles without sauce/broth.',
     'grains', true)

ON CONFLICT (food_name_normalized) WHERE restaurant_name IS NULL
DO UPDATE SET
    alternate_names = EXCLUDED.alternate_names,
    notes = EXCLUDED.notes;
