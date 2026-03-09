-- Migration 1599: Add "large" variant names to Sam's Club pizza entries
-- Fixes search not finding "Sam's club large pizza combo"

UPDATE food_nutrition_overrides
SET variant_names = array_cat(variant_names, ARRAY[
    'sams club large pizza combo',
    'sam''s club large pizza combo',
    'sams club large combo pizza',
    'sam''s club large combo pizza',
    'sams club large pizza'
])
WHERE food_name_normalized = 'sams_club_combo_pizza_slice';

UPDATE food_nutrition_overrides
SET variant_names = array_cat(variant_names, ARRAY[
    'sams club large pepperoni pizza',
    'sam''s club large pepperoni pizza',
    'sams club large pizza pepperoni'
])
WHERE food_name_normalized = 'sams_club_pepperoni_pizza_slice';

UPDATE food_nutrition_overrides
SET variant_names = array_cat(variant_names, ARRAY[
    'sams club large cheese pizza',
    'sam''s club large cheese pizza'
])
WHERE food_name_normalized = 'sams_club_cheese_pizza_slice';
