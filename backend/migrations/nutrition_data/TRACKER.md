# Restaurant Nutrition Data - Master Tracker

## How to Resume
If an agent times out or you need to restart:
1. Run: `grep -c "^(" backend/migrations/nutrition_data/batch*_nutrition.sql` to see how many items each batch has
2. Run: `grep "^-- Restaurant:" backend/migrations/nutrition_data/batch*_nutrition.sql` to see which restaurants are done
3. Tell Claude: "Resume the restaurant nutrition data task. Check TRACKER.md and existing SQL files in backend/migrations/nutrition_data/ to see what's done, then continue from where we left off."

## SQL Format Per Line
Each line in the batch files is a standalone SQL VALUES tuple:
```sql
('normalized_name', 'Display Name', cal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, piece_weight_g, serving_g, 'source', ARRAY['variant1', 'variant2'], 'total_cal notes. {"sodium_mg":X,"cholesterol_mg":X,"sat_fat_g":X,"trans_fat_g":X}'),
```

## Compilation (after all batches done)
Wrap all batch files into migration files:
- `273_overrides_fast_food.sql` = batch1 + batch2 + batch3
- `274_overrides_casual_dining.sql` = batch4 + batch5
- `275_overrides_pizza_coffee_dessert.sql` = batch6 + batch7
- `276_overrides_asian_mexican_misc.sql` = batch8 + batch9 + batch10

Each migration needs this wrapper:
```sql
INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes
) VALUES
-- paste batch lines here (remove trailing comma from last line)
ON CONFLICT (food_name_normalized) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  default_serving_g = EXCLUDED.default_serving_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  notes = EXCLUDED.notes,
  updated_at = NOW();
```

## Serving Weight Defaults
| Category | Default Weight |
|----------|---------------|
| Burger/sandwich | 200g |
| Chicken sandwich | 190g |
| Wrap/burrito | 250g |
| Pizza slice (14") | 150g |
| Pizza slice (12") | 120g |
| Taco (hard) | 80g |
| Taco (soft) | 100g |
| Side salad | 150g |
| Entree salad | 350g |
| Fries (small) | 70g |
| Fries (medium) | 120g |
| Fries (large) | 170g |
| Nuggets (6pc) | 100g |
| Nuggets (10pc) | 165g |
| Drink (small 16oz) | 480ml |
| Drink (medium 21oz) | 630ml |
| Drink (large 32oz) | 960ml |
| Milkshake | 400ml |
| Cookie | 70g |
| Donut | 80g |
| Muffin | 130g |
| Pretzel | 120g |
| Bowl (rice/grain) | 400g |
| Soup (cup) | 240g |
| Soup (bowl) | 350g |
| Wings (6pc) | 180g |
| Wings (12pc) | 360g |
| Quesadilla | 220g |
| Nachos | 300g |
| Sub sandwich (6") | 230g |
| Sub sandwich (12") | 460g |
| Steak (8oz) | 227g |
| Ribs (half rack) | 350g |
| Pancake (1) | 75g |
| Omelette | 250g |
| Pasta entree | 400g |
| Biscuit | 80g |
| Chicken breast (1pc) | 170g |
| Chicken tender (1pc) | 45g |
| Slider | 60g |
| Hot dog | 100g |
| Cinnamon roll | 260g |
| Ice cream scoop | 100g |
| Cheesecake slice | 200g |

## Existing Items (DO NOT DUPLICATE)
McDonald's (16): mcdonalds_chicken_mcnuggets_10pc, mcdonalds_chicken_mcnuggets_6pc, mcdonalds_hot_n_spicy_mcchicken, mcdonalds_spicy_mccrispy, mcdonalds_sausage_egg_cheese_mcgriddles, mcdonalds_steak_egg_mcmuffin, mcdonalds_hash_brown, mcdonalds_french_fries_medium, mcdonalds_cheeseburger, mcdonalds_double_quarter_pounder_cheese, mcdonalds_bacon_side, mcdonalds_sweet_iced_tea_medium, mcdonalds_hot_chocolate_medium, mcdonalds_hot_n_spicy_mcchicken_meal, mcdonalds_chicken_mcnuggets_10pc_meal, mcdonalds_spicy_mccrispy_meal

Taco Bell (10): taco_bell_chicken_quesadilla, taco_bell_cantina_chicken_quesadilla, taco_bell_cinnabon_delights, taco_bell_cinnamon_twists, taco_bell_salted_caramel_churros, taco_bell_franks_redhot_diablo_sauce, taco_bell_volcano_sauce, taco_bell_reduced_fat_sour_cream, taco_bell_chicken_quesadilla_combo, taco_bell_cantina_chicken_quesadilla_meal

Chipotle (5): chipotle_burrito_bowl_chicken, chipotle_chips_and_guacamole, chipotle_chips_and_queso_blanco, chipotle_chicken_tacos, chipotle_red_chimichurri

Panda Express (4): panda_express_bigger_plate, panda_express_teriyaki_sauce, panda_express_chili_sauce, panda_express_soy_sauce

Papa John's (6): papa_johns_philly_cheesesteak_papadia, papa_johns_the_works_pizza, papa_johns_garlic_epic_stuffed_crust_pizza, papa_johns_cinnamon_pull_aparts, papa_johns_special_garlic_sauce, papa_johns_spicy_garlic_sauce

BWW (7): bww_boneless_wings_12ct, bww_hatch_queso, bww_triple_bacon_cheeseburger, bww_ultimate_sampler, bww_triple_choc_cookie_skillet, bww_parmesan_garlic_sauce, bww_bleu_cheese_dressing

Red Robin (7): red_robin_madlove_burger, red_robin_haystack_double, red_robin_a1_steakhouse_burger, red_robin_cookie_dough_mudd_pie, red_robin_oreo_candy_cane_shake, red_robin_strawberry_milkshake, red_robin_creamy_milkshake

Hardee's (4): hardees_big_hot_ham_n_cheese, hardees_crispy_curls_medium, hardees_vanilla_ice_cream_shake, hardees_spicy_chicken_tenders_3pc

Steak 'n Shake (4): steak_n_shake_cheese_fries, steak_n_shake_chicken_fingers_3pc, steak_n_shake_side_cheese_sauce, steak_n_shake_garlic_double

Bob Evans (1): bob_evans_reeses_pb_pie

---

## Batch Assignments & Status

### Batch 1 (batch1_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 1 | McDonald's (expand) | 40-50 | PENDING |
| 2 | Chick-fil-A | 40-50 | PENDING |
| 3 | Starbucks | 50-60 | PENDING |
| 4 | Taco Bell (expand) | 40-50 | PENDING |
| 5 | Wendy's | 40-50 | PENDING |
| 6 | Burger King | 40-50 | PENDING |
| 7 | Subway | 30-40 | PENDING |
| 8 | Dunkin' | 40-50 | PENDING |
| 9 | Domino's | 30-40 | PENDING |
| 10 | Popeyes | 30-40 | PENDING |

### Batch 2 (batch2_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 11 | Pizza Hut | 30-40 | PENDING |
| 12 | KFC | 40-50 | PENDING |
| 13 | Chipotle (expand) | 30-40 | PENDING |
| 14 | Sonic Drive-In | 40-50 | PENDING |
| 15 | Panera Bread | 50-60 | PENDING |
| 16 | Jack in the Box | 40-50 | PENDING |
| 17 | Whataburger | 30-40 | PENDING |
| 18 | Panda Express (expand) | 30-40 | PENDING |
| 19 | Five Guys | 20-30 | PENDING |
| 20 | Raising Cane's | 10-15 | PENDING |

### Batch 3 (batch3_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 21 | Wingstop | 30-40 | PENDING |
| 22 | Zaxby's | 30-40 | PENDING |
| 23 | Little Caesars | 20-30 | PENDING |
| 24 | Jimmy John's | 20-30 | PENDING |
| 25 | Jersey Mike's | 20-30 | PENDING |
| 26 | Chili's | 40-50 | PENDING |
| 27 | Applebee's | 40-50 | PENDING |
| 28 | Olive Garden | 40-50 | PENDING |
| 29 | Buffalo Wild Wings (expand) | 30-40 | PENDING |
| 30 | Red Robin (expand) | 30-40 | PENDING |

### Batch 4 (batch4_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 31 | IHOP | 40-50 | PENDING |
| 32 | Denny's | 40-50 | PENDING |
| 33 | Cracker Barrel | 30-40 | PENDING |
| 34 | Outback Steakhouse | 30-40 | PENDING |
| 35 | Red Lobster | 30-40 | PENDING |
| 36 | Texas Roadhouse | 30-40 | PENDING |
| 37 | TGI Friday's | 30-40 | PENDING |
| 38 | Cheesecake Factory | 40-60 | PENDING |
| 39 | Arby's | 30-40 | PENDING |
| 40 | Hardee's/Carl's Jr (expand) | 30-40 | PENDING |

### Batch 5 (batch5_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 41 | Culver's | 30-40 | PENDING |
| 42 | Firehouse Subs | 20-30 | PENDING |
| 43 | Shake Shack | 20-30 | PENDING |
| 44 | In-N-Out Burger | 10-15 | PENDING |
| 45 | Noodles & Company | 30-40 | PENDING |
| 46 | Waffle House | 20-30 | PENDING |
| 47 | Crumbl Cookies | 10-15 | PENDING |
| 48 | Tropical Smoothie Cafe | 30-40 | PENDING |
| 49 | Portillo's | 20-30 | PENDING |
| 50 | Steak 'n Shake (expand) | 20-30 | PENDING |

### Batch 6 (batch6_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 51 | Papa John's (expand) | 20-30 | PENDING |
| 52 | Papa Murphy's | 20-30 | PENDING |
| 53 | Marco's Pizza | 20-30 | PENDING |
| 54 | MOD Pizza | 20-30 | PENDING |
| 55 | Blaze Pizza | 15-20 | PENDING |
| 56 | Krispy Kreme | 20-30 | PENDING |
| 57 | Baskin-Robbins | 20-30 | PENDING |
| 58 | Cold Stone Creamery | 20-30 | PENDING |
| 59 | Dairy Queen | 40-50 | PENDING |
| 60 | Jamba Juice | 20-30 | PENDING |

### Batch 7 (batch7_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 61 | Smoothie King | 20-30 | PENDING |
| 62 | Dutch Bros | 20-30 | PENDING |
| 63 | Tim Hortons | 30-40 | PENDING |
| 64 | Caribou Coffee | 15-20 | PENDING |
| 65 | Auntie Anne's | 15-20 | PENDING |
| 66 | Cinnabon | 10-15 | PENDING |
| 67 | Wetzel's Pretzels | 10-15 | PENDING |
| 68 | Insomnia Cookies | 10-15 | PENDING |
| 69 | Nothing Bundt Cakes | 10-15 | PENDING |
| 70 | Jollibee | 20-30 | PENDING |

### Batch 8 (batch8_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 71 | Church's Chicken | 20-30 | PENDING |
| 72 | El Pollo Loco | 30-40 | PENDING |
| 73 | Del Taco | 30-40 | PENDING |
| 74 | Moe's Southwest Grill | 20-30 | PENDING |
| 75 | Qdoba | 20-30 | PENDING |
| 76 | Pei Wei | 20-30 | PENDING |
| 77 | P.F. Chang's | 30-40 | PENDING |
| 78 | Sweetgreen | 20-30 | PENDING |
| 79 | Cava | 20-30 | PENDING |
| 80 | Waba Grill | 15-20 | PENDING |

### Batch 9 (batch9_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 81 | Teriyaki Madness | 15-20 | PENDING |
| 82 | Sarku Japan | 10-15 | PENDING |
| 83 | Yoshinoya | 15-20 | PENDING |
| 84 | Halal Guys | 10-15 | PENDING |
| 85 | Captain D's | 20-30 | PENDING |
| 86 | Long John Silver's | 20-30 | PENDING |
| 87 | Checkers/Rally's | 20-30 | PENDING |
| 88 | White Castle | 20-30 | PENDING |
| 89 | Cook Out | 20-30 | PENDING |
| 90 | Bojangles | 20-30 | PENDING |

### Batch 10 (batch10_nutrition.sql)
| # | Restaurant | Target Items | Status |
|---|-----------|-------------|--------|
| 91 | Golden Corral | 20-30 | PENDING |
| 92 | Bob Evans (expand) | 30-40 | PENDING |
| 93 | Perkins | 20-30 | PENDING |
| 94 | McAlister's Deli | 20-30 | PENDING |
| 95 | Jason's Deli | 20-30 | PENDING |
| 96 | Potbelly | 20-30 | PENDING |
| 97 | Baja Fresh | 20-30 | PENDING |
| 98 | Benihana | 20-30 | PENDING |
| 99 | Village Inn | 20-30 | PENDING |
| 100 | Fazoli's | 20-30 | PENDING |

---

## Validation Queries (run after all migrations)
```sql
-- Total count (expect ~5,000-7,000+)
SELECT COUNT(*) FROM food_nutrition_overrides;

-- Per-source distribution
SELECT source, COUNT(*) FROM food_nutrition_overrides GROUP BY source ORDER BY COUNT(*) DESC;

-- Sanity: no impossible calories
SELECT * FROM food_nutrition_overrides WHERE calories_per_100g > 900 OR calories_per_100g < 5;

-- Macro cross-check
SELECT food_name_normalized, calories_per_100g,
  ROUND((protein_per_100g * 4 + carbs_per_100g * 4 + fat_per_100g * 9)::numeric, 1) as calc_cal,
  ABS(calories_per_100g - (protein_per_100g * 4 + carbs_per_100g * 4 + fat_per_100g * 9)) as diff
FROM food_nutrition_overrides
WHERE ABS(calories_per_100g - (protein_per_100g * 4 + carbs_per_100g * 4 + fat_per_100g * 9)) > 50
ORDER BY diff DESC;
```
