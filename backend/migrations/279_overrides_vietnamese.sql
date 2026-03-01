-- ============================================================================
-- 279_overrides_vietnamese.sql
-- Generated: 2026-02-28
-- Total items: 33
--
-- Vietnamese cuisine food nutrition overrides.
-- All values are per 100g of prepared/served food.
-- Sources: fatsecret.com, snapcalorie.com, nutritionix.com, eatthismuch.com,
--          sparkrecipes.com, myfitnesspal.com, USDA FoodData Central
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes,
  restaurant_name, food_category, default_count
) VALUES

-- =====================================================
-- SOUPS
-- Pho and other Vietnamese soups are broth-heavy.
-- Per-100g values are LOW because the dish is mostly water.
-- Typical pho bowl: 600-800g total.
-- Sources: fatsecret.com, nutritionix.com, snapcalorie.com
-- =====================================================

-- Pho Bo: ~72 cal/100g (fatsecret). Bowl ~700g = ~500 cal. 33g pro, 54g carb, 12g fat per bowl.
('pho_bo', 'Pho Bo (Beef Pho)', 72.0, 4.7, 7.7, 1.7, 0.3, 0.5, NULL, 700, 'vietnamese_cuisine',
 ARRAY['pho bo', 'beef pho', 'pho tai', 'pho chin', 'pho dac biet', 'vietnamese beef noodle soup'],
 '72 cal/100g. Typical bowl ~700g = ~504 cal. Broth-heavy, high water content.',
 NULL, 'vietnamese', 1),

-- Pho Ga: Slightly lighter than beef pho. ~65 cal/100g. Bowl ~700g = ~455 cal.
('pho_ga', 'Pho Ga (Chicken Pho)', 65.0, 4.3, 7.5, 1.4, 0.2, 0.4, NULL, 700, 'vietnamese_cuisine',
 ARRAY['pho ga', 'chicken pho', 'pho ga ta', 'vietnamese chicken noodle soup'],
 '65 cal/100g. Typical bowl ~700g = ~455 cal. Leaner than beef pho.',
 NULL, 'vietnamese', 1),

-- Bun Bo Hue: Richer/fattier broth than pho, with lemongrass and shrimp paste.
-- ~90 cal/100g. Bowl ~650g = ~585 cal. More protein from beef shank + pork.
('bun_bo_hue', 'Bun Bo Hue (Spicy Beef Noodle Soup)', 90.0, 5.4, 9.2, 3.2, 0.4, 0.6, NULL, 650, 'vietnamese_cuisine',
 ARRAY['bun bo hue', 'hue beef noodle', 'spicy beef noodle soup', 'bun bo'],
 '90 cal/100g. Bowl ~650g = ~585 cal. Richer broth with lemongrass and shrimp paste.',
 NULL, 'vietnamese', 1),

-- Hu Tieu: Clear pork/seafood broth, lighter than pho.
-- ~70 cal/100g. Bowl ~600g = ~420 cal. 28g pro, 49g carb, 11g fat per bowl.
('hu_tieu', 'Hu Tieu (Clear Noodle Soup)', 70.0, 4.7, 8.2, 1.8, 0.3, 0.5, NULL, 600, 'vietnamese_cuisine',
 ARRAY['hu tieu', 'hu tieu nam vang', 'hu tieu mi', 'clear noodle soup', 'vietnamese pork noodle soup'],
 '70 cal/100g. Bowl ~600g = ~420 cal. Clear pork and seafood broth.',
 NULL, 'vietnamese', 1),

-- Canh Chua: Sour tamarind soup with fish/shrimp, vegetables.
-- ~60 cal/100g (snapcalorie: 141 cal/cup = ~237g). Bowl ~500g = ~300 cal.
('canh_chua', 'Canh Chua (Vietnamese Sour Soup)', 60.0, 6.0, 4.0, 2.0, 0.8, 1.5, NULL, 500, 'vietnamese_cuisine',
 ARRAY['canh chua', 'canh chua ca', 'canh chua tom', 'sour soup', 'tamarind soup', 'sweet and sour soup'],
 '60 cal/100g. Bowl ~500g = ~300 cal. Tamarind-based with fish/shrimp and vegetables.',
 NULL, 'vietnamese', 1),

-- =====================================================
-- SANDWICHES
-- Banh Mi is a dense sandwich: bread, protein, pickled veg, pate.
-- Sources: snapcalorie.com, calories-info.com, nutritionix.com
-- =====================================================

-- Banh Mi (classic pork): ~205 cal/100g (calories-info.com). Sandwich ~350g = ~718 cal.
-- 7.7g pro, 23.7g carb, 9g fat per 100g.
('banh_mi_pork', 'Banh Mi Thit (Pork Banh Mi)', 205.0, 8.5, 24.0, 8.5, 1.2, 3.0, 350, 350, 'vietnamese_cuisine',
 ARRAY['banh mi', 'banh mi thit', 'pork banh mi', 'vietnamese sandwich', 'vietnamese sub', 'banh mi dac biet'],
 '205 cal/100g. One sandwich ~350g = ~718 cal. Baguette with pork, pate, pickled veg.',
 NULL, 'sandwiches', 1),

-- Banh Mi Ga (chicken): Slightly leaner than pork version.
('banh_mi_chicken', 'Banh Mi Ga (Chicken Banh Mi)', 195.0, 10.0, 23.0, 7.0, 1.2, 3.0, 350, 350, 'vietnamese_cuisine',
 ARRAY['banh mi ga', 'chicken banh mi', 'vietnamese chicken sandwich'],
 '195 cal/100g. One sandwich ~350g = ~683 cal. Baguette with chicken, pickled veg.',
 NULL, 'sandwiches', 1),

-- Banh Mi Thit Nuong (grilled pork): Slightly higher fat from char-grilled meat.
('banh_mi_thit_nuong', 'Banh Mi Thit Nuong (Grilled Pork Banh Mi)', 215.0, 9.5, 23.5, 9.0, 1.2, 3.5, 350, 350, 'vietnamese_cuisine',
 ARRAY['banh mi thit nuong', 'grilled pork banh mi', 'bbq pork banh mi'],
 '215 cal/100g. One sandwich ~350g = ~753 cal. Char-grilled pork with baguette.',
 NULL, 'sandwiches', 1),

-- Banh Mi Chay (tofu/vegetarian): Lower cal, less fat.
('banh_mi_tofu', 'Banh Mi Chay (Tofu/Vegetarian Banh Mi)', 175.0, 7.0, 25.0, 5.5, 1.5, 3.0, 320, 320, 'vietnamese_cuisine',
 ARRAY['banh mi chay', 'tofu banh mi', 'vegetarian banh mi', 'vegan banh mi'],
 '175 cal/100g. One sandwich ~320g = ~560 cal. Tofu or mock meat with pickled veg.',
 NULL, 'sandwiches', 1),

-- =====================================================
-- RICE DISHES
-- Sources: comtambbq.com, snapcalorie.com, myfitnesspal.com
-- =====================================================

-- Com Tam (broken rice with grilled pork chop): Plate ~450g.
-- Rice ~260 cal (200g), pork chop ~280 cal (120g), extras ~100 cal.
-- Per 100g of the full plate: ~142 cal.
('com_tam', 'Com Tam Suon (Broken Rice with Grilled Pork)', 142.0, 8.0, 17.5, 4.5, 0.5, 0.5, NULL, 450, 'vietnamese_cuisine',
 ARRAY['com tam', 'com tam suon', 'broken rice', 'com tam suon bi cha', 'broken rice grilled pork'],
 '142 cal/100g. Plate ~450g = ~639 cal. Broken rice with grilled pork chop, egg, pickled veg.',
 NULL, 'rice', 1),

-- Com Ga (chicken rice): Vietnamese-style, ~200 cal/100g for the plated dish.
-- Serving ~400g = ~800 cal (rice cooked in chicken fat is calorie-dense).
('com_ga', 'Com Ga (Vietnamese Chicken Rice)', 165.0, 8.5, 20.0, 5.5, 0.3, 0.3, NULL, 400, 'vietnamese_cuisine',
 ARRAY['com ga', 'com ga hoi an', 'chicken rice', 'vietnamese chicken rice'],
 '165 cal/100g. Plate ~400g = ~660 cal. Seasoned rice with poached or roasted chicken.',
 NULL, 'rice', 1),

-- Com Chien (fried rice): ~174 cal/100g (snapcalorie). Serving ~350g = ~609 cal.
('com_chien', 'Com Chien (Vietnamese Fried Rice)', 174.0, 5.5, 22.0, 7.0, 0.8, 0.5, NULL, 350, 'vietnamese_cuisine',
 ARRAY['com chien', 'vietnamese fried rice', 'com chien duong chau', 'fried rice vietnamese'],
 '174 cal/100g. Plate ~350g = ~609 cal. Wok-fried rice with egg, vegetables, protein.',
 NULL, 'rice', 1),

-- =====================================================
-- NOODLE DISHES (non-soup)
-- Sources: snapcalorie.com, sparkrecipes.com, nutritionix.com
-- =====================================================

-- Bun Cha: Grilled pork patties + belly served with vermicelli and dipping broth.
-- ~150 cal/100g (snapcalorie: 355 cal per cup ~237g). Serving ~450g = ~675 cal.
('bun_cha', 'Bun Cha (Hanoi Grilled Pork with Noodles)', 150.0, 7.5, 17.5, 5.5, 0.8, 2.0, NULL, 450, 'vietnamese_cuisine',
 ARRAY['bun cha', 'bun cha hanoi', 'grilled pork noodles', 'bun cha nem'],
 '150 cal/100g. Serving ~450g = ~675 cal. Grilled pork patties with rice vermicelli and dipping broth.',
 NULL, 'noodles', 1),

-- Bun Thit Nuong: Vermicelli bowl with grilled pork, herbs, nuoc cham.
-- ~130 cal/100g. Bowl ~500g = ~650 cal. (nutritionix: 460 cal per 350g serving)
('bun_thit_nuong', 'Bun Thit Nuong (Grilled Pork Vermicelli Bowl)', 130.0, 6.5, 16.0, 4.5, 1.0, 1.5, NULL, 500, 'vietnamese_cuisine',
 ARRAY['bun thit nuong', 'grilled pork vermicelli', 'vietnamese noodle bowl', 'bun thit nuong cha gio'],
 '130 cal/100g. Bowl ~500g = ~650 cal. Rice vermicelli with grilled pork, herbs, fish sauce dressing.',
 NULL, 'noodles', 1),

-- Mi Xao (stir-fried noodles): ~155 cal/100g. Plate ~380g = ~589 cal.
-- (sparkrecipes: 521 cal per serving beef version ~336g)
('mi_xao', 'Mi Xao (Vietnamese Stir-Fried Noodles)', 155.0, 7.5, 18.0, 6.0, 1.0, 1.0, NULL, 380, 'vietnamese_cuisine',
 ARRAY['mi xao', 'mi xao gion', 'mi xao mem', 'stir fried noodles vietnamese', 'chow mein vietnamese', 'crispy noodles vietnamese'],
 '155 cal/100g. Plate ~380g = ~589 cal. Egg noodles stir-fried with vegetables and protein.',
 NULL, 'noodles', 1),

-- =====================================================
-- ROLLS & WRAPS
-- Sources: nutriscan.app, snapcalorie.com, sparkrecipes.com
-- =====================================================

-- Goi Cuon (fresh spring rolls): ~105 cal/100g. Each roll ~120g.
-- (nutriscan: 150 cal/100g with shrimp/pork; NHLBI: 55 cal per small roll ~60g)
('goi_cuon', 'Goi Cuon (Fresh Spring Rolls)', 105.0, 5.5, 15.0, 2.5, 1.0, 1.5, 120, 240, 'vietnamese_cuisine',
 ARRAY['goi cuon', 'fresh spring rolls', 'summer rolls', 'rice paper rolls', 'vietnamese spring rolls', 'salad rolls'],
 '105 cal/100g. Each roll ~120g = ~126 cal. Rice paper with shrimp, pork, vermicelli, herbs.',
 NULL, 'vietnamese', 2),

-- Cha Gio (fried spring rolls): ~250 cal/100g. Each roll ~60g.
-- (snapcalorie: deep fried, ~150 cal per 60g roll)
('cha_gio', 'Cha Gio (Vietnamese Fried Spring Rolls)', 250.0, 8.0, 22.0, 14.5, 1.2, 1.0, 60, 240, 'vietnamese_cuisine',
 ARRAY['cha gio', 'fried spring rolls', 'egg rolls vietnamese', 'nem ran', 'imperial rolls', 'vietnamese egg rolls'],
 '250 cal/100g. Each roll ~60g = ~150 cal. Deep-fried rice paper rolls with pork, shrimp, vegetables.',
 NULL, 'vietnamese', 4),

-- Bo Bia (jicama rolls): Fresh rolls with Chinese sausage, jicama, egg.
-- ~120 cal/100g. Each roll ~100g = ~120 cal. (inlivo: ~86 cal per roll)
('bo_bia', 'Bo Bia (Jicama Spring Rolls)', 120.0, 4.5, 14.0, 5.0, 1.5, 2.0, 100, 200, 'vietnamese_cuisine',
 ARRAY['bo bia', 'jicama rolls', 'chinese sausage spring rolls', 'bo bia cuon'],
 '120 cal/100g. Each roll ~100g = ~120 cal. Rice paper with jicama, carrot, Chinese sausage, egg.',
 NULL, 'vietnamese', 2),

-- =====================================================
-- CURRY
-- Sources: Various recipe sites, snapcalorie.com
-- =====================================================

-- Ca Ri Ga (Vietnamese chicken curry): Coconut milk base, potatoes, chicken.
-- ~110 cal/100g. Serving ~400g = ~440 cal. (delightfulplate: 365 cal per bowl ~330g)
('ca_ri_ga', 'Ca Ri Ga (Vietnamese Chicken Curry)', 110.0, 6.5, 7.0, 6.5, 1.0, 1.5, NULL, 400, 'vietnamese_cuisine',
 ARRAY['ca ri ga', 'vietnamese chicken curry', 'cari ga', 'vietnamese curry', 'curry ga'],
 '110 cal/100g. Serving ~400g = ~440 cal. Coconut milk curry with chicken, potatoes, carrots.',
 NULL, 'vietnamese', 1),

-- =====================================================
-- GRILLED MEATS (standalone, no rice/noodles)
-- Sources: sparkrecipes.com, fitclick.com, snapcalorie.com
-- =====================================================

-- Thit Nuong (grilled pork): ~195 cal/100g for marinated grilled pork shoulder/loin.
-- (sparkrecipes: 173 cal per ~89g serving meat only = ~194 cal/100g)
('thit_nuong', 'Thit Nuong (Vietnamese Grilled Pork)', 195.0, 22.0, 5.0, 9.5, 0.0, 3.5, NULL, 150, 'vietnamese_cuisine',
 ARRAY['thit nuong', 'thit heo nuong', 'grilled pork vietnamese', 'lemongrass pork', 'vietnamese bbq pork'],
 '195 cal/100g. Serving ~150g = ~293 cal. Lemongrass-marinated grilled pork.',
 NULL, 'vietnamese', 1),

-- Bo Luc Lac (shaking beef): ~185 cal/100g for the beef with sauce (no rice).
-- (skinnytaste: 376 cal per serving ~200g = ~188/100g)
('bo_luc_lac', 'Bo Luc Lac (Shaking Beef)', 185.0, 22.0, 4.0, 9.0, 0.3, 1.5, NULL, 200, 'vietnamese_cuisine',
 ARRAY['bo luc lac', 'shaking beef', 'bo luc lac vietnamese', 'cube steak vietnamese', 'lac beef'],
 '185 cal/100g. Serving ~200g = ~370 cal. Cubed beef seared with garlic, soy, served with watercress.',
 NULL, 'vietnamese', 1),

-- Ga Nuong (grilled chicken): ~175 cal/100g for marinated grilled chicken.
-- Based on grilled chicken thigh with lemongrass marinade.
('ga_nuong', 'Ga Nuong (Vietnamese Grilled Chicken)', 175.0, 24.0, 3.0, 7.5, 0.0, 2.0, NULL, 180, 'vietnamese_cuisine',
 ARRAY['ga nuong', 'ga nuong xa', 'grilled chicken vietnamese', 'lemongrass chicken', 'vietnamese bbq chicken'],
 '175 cal/100g. Serving ~180g = ~315 cal. Lemongrass-marinated grilled chicken.',
 NULL, 'vietnamese', 1),

-- =====================================================
-- SNACKS, SIDES & BREAKFAST
-- Sources: snapcalorie.com, myfitnesspal.com, fitclick.com
-- =====================================================

-- Xoi (sticky rice, plain): ~190 cal/100g cooked.
-- (nutritionix: 190 cal per serving ~100g). Serving ~200g.
('xoi', 'Xoi (Vietnamese Sticky Rice)', 190.0, 4.5, 40.0, 1.5, 0.8, 0.3, NULL, 200, 'vietnamese_cuisine',
 ARRAY['xoi', 'sticky rice', 'xoi vo', 'xoi man', 'xoi gac', 'glutinous rice', 'vietnamese sticky rice'],
 '190 cal/100g. Serving ~200g = ~380 cal. Steamed glutinous rice, plain base value.',
 NULL, 'vietnamese', 1),

-- Xoi Man (savory sticky rice with toppings): ~210 cal/100g.
-- (snapcalorie: 467 cal per serving ~222g = ~210/100g)
('xoi_man', 'Xoi Man (Savory Sticky Rice)', 210.0, 6.5, 28.0, 8.0, 0.8, 0.5, NULL, 250, 'vietnamese_cuisine',
 ARRAY['xoi man', 'savory sticky rice', 'xoi thap cam', 'sticky rice with toppings'],
 '210 cal/100g. Serving ~250g = ~525 cal. Sticky rice with Chinese sausage, egg, pork floss.',
 NULL, 'vietnamese', 1),

-- Banh Cuon (steamed rice rolls): ~125 cal/100g.
-- (snapcalorie: steamed rice sheet with pork filling). Serving ~300g.
('banh_cuon', 'Banh Cuon (Steamed Rice Rolls)', 125.0, 5.0, 18.0, 3.5, 0.5, 0.5, NULL, 300, 'vietnamese_cuisine',
 ARRAY['banh cuon', 'steamed rice rolls', 'banh cuon nong', 'banh cuon thit', 'vietnamese rice crepe'],
 '125 cal/100g. Serving ~300g = ~375 cal. Thin steamed rice sheets with pork and mushroom filling.',
 NULL, 'vietnamese', 1),

-- Banh Xeo (Vietnamese crepe): ~175 cal/100g.
-- (sparkrecipes: 229 cal per crepe ~130g = ~176/100g for a moderate version)
('banh_xeo', 'Banh Xeo (Vietnamese Sizzling Crepe)', 175.0, 7.0, 16.0, 9.5, 1.0, 1.5, 200, 200, 'vietnamese_cuisine',
 ARRAY['banh xeo', 'vietnamese crepe', 'sizzling crepe', 'vietnamese pancake', 'banh xeo tom thit'],
 '175 cal/100g. Each crepe ~200g = ~350 cal. Crispy turmeric crepe with shrimp, pork, bean sprouts.',
 NULL, 'vietnamese', 1),

-- =====================================================
-- DESSERTS & DRINKS
-- Sources: cafely.com, snapcalorie.com, recipe sites
-- =====================================================

-- Che (sweet dessert soup, average across types): ~100 cal/100g.
-- (diversivore: che ba mau ~417 cal per 400g glass = ~104/100g. Lighter mung bean: 127 cal/250g)
('che', 'Che (Vietnamese Sweet Dessert Soup)', 100.0, 2.0, 18.0, 2.5, 1.0, 12.0, NULL, 300, 'vietnamese_cuisine',
 ARRAY['che', 'che ba mau', 'che dau xanh', 'che bap', 'che thai', 'che chuoi', 'vietnamese sweet soup', 'vietnamese dessert'],
 '100 cal/100g. Serving ~300g = ~300 cal. Average across che varieties (mung bean, corn, three-color).',
 NULL, 'desserts', 1),

-- Che Dau Xanh (mung bean sweet soup): Lighter variety.
-- (delightfulplate: 127 cal per serving ~250g = ~51/100g; but denser portions ~80/100g)
('che_dau_xanh', 'Che Dau Xanh (Mung Bean Sweet Soup)', 75.0, 2.5, 13.0, 1.0, 1.5, 8.0, NULL, 300, 'vietnamese_cuisine',
 ARRAY['che dau xanh', 'mung bean sweet soup', 'mung bean dessert', 'che dau xanh nep'],
 '75 cal/100g. Serving ~300g = ~225 cal. Light mung bean dessert soup with coconut milk.',
 NULL, 'desserts', 1),

-- Ca Phe Sua Da (Vietnamese iced coffee with condensed milk):
-- ~50 cal/100ml. Standard glass ~240ml = ~120 cal.
-- (cafely: ~193 cal per serving with 3 tbsp condensed milk; lighter at 2 tbsp = ~120 cal)
('ca_phe_sua_da', 'Ca Phe Sua Da (Vietnamese Iced Coffee)', 50.0, 1.5, 8.5, 1.5, 0.0, 8.0, NULL, 240, 'vietnamese_cuisine',
 ARRAY['ca phe sua da', 'vietnamese iced coffee', 'vietnamese coffee', 'cafe sua da', 'ca phe da', 'iced coffee condensed milk'],
 '50 cal/100ml. Glass ~240ml = ~120 cal. Strong drip coffee with sweetened condensed milk over ice.',
 NULL, 'drinks', 1),

-- Ca Phe Den Da (Vietnamese black iced coffee, no milk):
-- ~5 cal/100ml (essentially black coffee). Glass ~240ml.
('ca_phe_den_da', 'Ca Phe Den Da (Vietnamese Black Iced Coffee)', 5.0, 0.3, 0.5, 0.0, 0.0, 0.0, NULL, 240, 'vietnamese_cuisine',
 ARRAY['ca phe den', 'ca phe den da', 'black vietnamese coffee', 'vietnamese black coffee', 'cafe den'],
 '5 cal/100ml. Glass ~240ml = ~12 cal. Strong black drip coffee over ice, no milk or sugar.',
 NULL, 'drinks', 1),

-- =====================================================
-- ADDITIONAL POPULAR ITEMS
-- =====================================================

-- Bun Rieu (crab tomato noodle soup): ~75 cal/100g.
-- Tomato-based broth with crab paste, tofu, vermicelli. Bowl ~600g.
('bun_rieu', 'Bun Rieu (Crab Tomato Noodle Soup)', 75.0, 4.5, 8.5, 2.5, 0.5, 1.5, NULL, 600, 'vietnamese_cuisine',
 ARRAY['bun rieu', 'bun rieu cua', 'crab noodle soup', 'tomato crab soup vietnamese'],
 '75 cal/100g. Bowl ~600g = ~450 cal. Tomato-based broth with crab paste, tofu, rice vermicelli.',
 NULL, 'vietnamese', 1),

-- Banh Trang Nuong (Vietnamese rice paper pizza/grilled rice paper):
-- ~280 cal/100g. Each piece ~80g.
('banh_trang_nuong', 'Banh Trang Nuong (Grilled Rice Paper)', 280.0, 8.0, 30.0, 14.0, 0.5, 1.0, 80, 80, 'vietnamese_cuisine',
 ARRAY['banh trang nuong', 'grilled rice paper', 'vietnamese pizza', 'rice paper pizza'],
 '280 cal/100g. Each piece ~80g = ~224 cal. Grilled rice paper with egg, dried shrimp, scallions, chili.',
 NULL, 'vietnamese', 1),

-- Goi Ga (Vietnamese chicken salad): ~95 cal/100g.
-- Shredded chicken with cabbage, herbs, nuoc cham. Serving ~250g.
('goi_ga', 'Goi Ga (Vietnamese Chicken Salad)', 95.0, 10.0, 6.0, 3.5, 1.2, 2.5, NULL, 250, 'vietnamese_cuisine',
 ARRAY['goi ga', 'vietnamese chicken salad', 'chicken cabbage salad vietnamese', 'goi ga bap cai'],
 '95 cal/100g. Serving ~250g = ~238 cal. Shredded chicken with cabbage, herbs, fried shallots, nuoc cham.',
 NULL, 'salads', 1)

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
  restaurant_name = EXCLUDED.restaurant_name,
  food_category = EXCLUDED.food_category,
  default_count = EXCLUDED.default_count,
  updated_at = NOW();
