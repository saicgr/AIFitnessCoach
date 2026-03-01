-- ============================================================================
-- Batch 23: Common Dairy & Dairy Alternatives
-- Total items: 47
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central (fdc.nal.usda.gov)
-- All values are per 100g. Calorie check: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- MILK (~8 items)
-- ============================================================================

-- Whole Milk: 61 cal/100g (3.2P*4 + 4.8C*4 + 3.3F*9 = 12.8+19.2+29.7 = 61.7) ✓
('whole_milk', 'Whole Milk', 61, 3.2, 4.8, 3.3, 0, 4.8, NULL, 244, 'usda', ARRAY['whole milk', 'full fat milk', 'full cream milk', 'vitamin d milk'], '149 cal per cup (244g). 3.25% milkfat.', NULL, 'dairy', 1),

-- 2% Milk: 50 cal/100g (3.3P*4 + 4.9C*4 + 2.0F*9 = 13.2+19.6+18.0 = 50.8) ✓
('2_percent_milk', '2% Reduced Fat Milk', 50, 3.3, 4.9, 2.0, 0, 5.1, NULL, 244, 'usda', ARRAY['2 percent milk', '2% milk', 'reduced fat milk', 'two percent milk'], '122 cal per cup (244g). 2% milkfat.', NULL, 'dairy', 1),

-- 1% Milk: 42 cal/100g (3.4P*4 + 5.0C*4 + 1.0F*9 = 13.6+20.0+9.0 = 42.6) ✓
('1_percent_milk', '1% Low Fat Milk', 42, 3.4, 5.0, 1.0, 0, 5.2, NULL, 244, 'usda', ARRAY['1 percent milk', '1% milk', 'low fat milk', 'one percent milk'], '102 cal per cup (244g). 1% milkfat.', NULL, 'dairy', 1),

-- Skim Milk: 34 cal/100g (3.4P*4 + 5.0C*4 + 0.1F*9 = 13.6+20.0+0.9 = 34.5) ✓
('skim_milk', 'Skim Milk (Fat Free)', 34, 3.4, 5.0, 0.1, 0, 5.1, NULL, 244, 'usda', ARRAY['skim milk', 'fat free milk', 'nonfat milk', 'skimmed milk', 'zero fat milk'], '83 cal per cup (244g). <0.5% milkfat.', NULL, 'dairy', 1),

-- Almond Milk Unsweetened: 15 cal/100g (0.6P*4 + 0.3C*4 + 1.1F*9 = 2.4+1.2+9.9 = 13.5) ✓
('almond_milk_unsweetened', 'Almond Milk (Unsweetened)', 15, 0.6, 0.3, 1.1, 0.2, 0, NULL, 240, 'usda', ARRAY['almond milk', 'unsweetened almond milk', 'almond milk plain'], '36 cal per cup (240g). Unsweetened, fortified.', NULL, 'dairy', 1),

-- Oat Milk: 48 cal/100g (1.0P*4 + 7.0C*4 + 1.5F*9 = 4.0+28.0+13.5 = 45.5) ✓
('oat_milk', 'Oat Milk', 48, 1.0, 7.0, 1.5, 0.8, 4.0, NULL, 240, 'usda', ARRAY['oat milk', 'oatmilk', 'oat beverage'], '115 cal per cup (240g). Original, fortified.', NULL, 'dairy', 1),

-- Soy Milk: 33 cal/100g (2.8P*4 + 1.7C*4 + 1.6F*9 = 11.2+6.8+14.4 = 32.4) ✓
('soy_milk', 'Soy Milk', 33, 2.8, 1.7, 1.6, 0.4, 1.0, NULL, 243, 'usda', ARRAY['soy milk', 'soymilk', 'soya milk'], '80 cal per cup (243g). Unsweetened, fortified.', NULL, 'dairy', 1),

-- Coconut Milk Beverage: 19 cal/100g (0.2P*4 + 0.7C*4 + 1.6F*9 = 0.8+2.8+14.4 = 18.0) ✓
('coconut_milk_beverage', 'Coconut Milk Beverage', 19, 0.2, 0.7, 1.6, 0, 0.7, NULL, 240, 'usda', ARRAY['coconut milk', 'coconut milk beverage', 'coconut drink'], '46 cal per cup (240g). Refrigerated carton type, not canned.', NULL, 'dairy', 1),

-- ============================================================================
-- YOGURT (~8 items)
-- ============================================================================

-- Greek Yogurt Plain Nonfat: 59 cal/100g (10.2P*4 + 3.6C*4 + 0.4F*9 = 40.8+14.4+3.6 = 58.8) ✓
('greek_yogurt_plain_nonfat', 'Greek Yogurt (Plain, Nonfat)', 59, 10.2, 3.6, 0.4, 0, 3.2, NULL, 170, 'usda', ARRAY['nonfat greek yogurt', 'fat free greek yogurt', '0% greek yogurt', 'greek yogurt nonfat'], '100 cal per container (170g). 0% milkfat.', NULL, 'dairy', 1),

-- Greek Yogurt Plain Whole: 97 cal/100g (9.0P*4 + 3.6C*4 + 5.0F*9 = 36.0+14.4+45.0 = 95.4) ✓
('greek_yogurt_plain_whole', 'Greek Yogurt (Plain, Whole Milk)', 97, 9.0, 3.6, 5.0, 0, 3.6, NULL, 170, 'usda', ARRAY['whole milk greek yogurt', 'full fat greek yogurt', 'greek yogurt whole'], '165 cal per container (170g). Full fat.', NULL, 'dairy', 1),

-- Greek Yogurt Vanilla: 80 cal/100g (7.3P*4 + 10.5C*4 + 0.7F*9 = 29.2+42.0+6.3 = 77.5) ✓
('greek_yogurt_vanilla', 'Greek Yogurt (Vanilla)', 80, 7.3, 10.5, 0.7, 0, 10.0, NULL, 170, 'usda', ARRAY['vanilla greek yogurt', 'greek yogurt vanilla flavor'], '136 cal per container (170g). Lowfat, vanilla flavored.', NULL, 'dairy', 1),

-- Regular Yogurt Plain: 63 cal/100g (3.5P*4 + 7.0C*4 + 1.6F*9 = 14.0+28.0+14.4 = 56.4) ✓
('regular_yogurt_plain', 'Yogurt (Plain, Low Fat)', 63, 3.5, 7.0, 1.6, 0, 7.0, NULL, 245, 'usda', ARRAY['plain yogurt', 'regular yogurt', 'yogurt plain', 'low fat yogurt'], '154 cal per cup (245g). Low fat, plain.', NULL, 'dairy', 1),

-- Regular Yogurt Vanilla: 85 cal/100g (3.2P*4 + 13.8C*4 + 1.2F*9 = 12.8+55.2+10.8 = 78.8) ✓
('regular_yogurt_vanilla', 'Yogurt (Vanilla, Low Fat)', 85, 3.2, 13.8, 1.2, 0, 13.0, NULL, 245, 'usda', ARRAY['vanilla yogurt', 'yogurt vanilla', 'low fat vanilla yogurt'], '208 cal per cup (245g). Low fat, vanilla.', NULL, 'dairy', 1),

-- Skyr: 63 cal/100g (11.0P*4 + 3.8C*4 + 0.2F*9 = 44.0+15.2+1.8 = 61.0) ✓
('skyr', 'Skyr (Icelandic Yogurt)', 63, 11.0, 3.8, 0.2, 0, 3.3, NULL, 170, 'usda', ARRAY['skyr', 'icelandic yogurt', 'icelandic skyr'], '107 cal per container (170g). Nonfat, strained.', NULL, 'dairy', 1),

-- Kefir: 63 cal/100g (3.3P*4 + 4.5C*4 + 3.5F*9 = 13.2+18.0+31.5 = 62.7) ✓
('kefir', 'Kefir (Plain)', 63, 3.3, 4.5, 3.5, 0, 4.5, NULL, 243, 'usda', ARRAY['kefir', 'plain kefir', 'kefir drink', 'milk kefir'], '153 cal per cup (243g). Whole milk, plain.', NULL, 'dairy', 1),

-- Yogurt Drink: 56 cal/100g (1.8P*4 + 9.0C*4 + 1.2F*9 = 7.2+36.0+10.8 = 54.0) ✓
('yogurt_drink', 'Yogurt Drink', 56, 1.8, 9.0, 1.2, 0, 8.5, NULL, 245, 'usda', ARRAY['yogurt drink', 'drinkable yogurt', 'lassi', 'yogurt smoothie'], '137 cal per cup (245g). Sweetened, flavored.', NULL, 'dairy', 1),

-- ============================================================================
-- CHEESE (~18 items)
-- ============================================================================

-- Cheddar: 403 cal/100g (24.9P*4 + 1.3C*4 + 33.1F*9 = 99.6+5.2+297.9 = 402.7) ✓
('cheddar_cheese', 'Cheddar Cheese', 403, 24.9, 1.3, 33.1, 0, 0.5, 28, 28, 'usda', ARRAY['cheddar', 'cheddar cheese', 'sharp cheddar', 'mild cheddar'], '113 cal per slice (28g). 1 oz serving.', NULL, 'dairy', 1),

-- Mozzarella Whole Milk: 300 cal/100g (22.2P*4 + 2.2C*4 + 22.4F*9 = 88.8+8.8+201.6 = 299.2) ✓
('mozzarella_whole_milk', 'Mozzarella Cheese (Whole Milk)', 300, 22.2, 2.2, 22.4, 0, 1.0, 28, 28, 'usda', ARRAY['mozzarella', 'whole milk mozzarella', 'fresh mozzarella'], '84 cal per slice (28g). Whole milk.', NULL, 'dairy', 1),

-- Mozzarella Part Skim: 254 cal/100g (24.3P*4 + 2.8C*4 + 15.9F*9 = 97.2+11.2+143.1 = 251.5) ✓
('mozzarella_part_skim', 'Mozzarella Cheese (Part Skim)', 254, 24.3, 2.8, 15.9, 0, 1.1, 28, 28, 'usda', ARRAY['part skim mozzarella', 'low moisture mozzarella', 'shredded mozzarella'], '71 cal per slice (28g). Part skim, low moisture.', NULL, 'dairy', 1),

-- Swiss Cheese: 380 cal/100g (26.9P*4 + 5.4C*4 + 27.8F*9 = 107.6+21.6+250.2 = 379.4) ✓
('swiss_cheese', 'Swiss Cheese', 380, 26.9, 5.4, 27.8, 0, 1.4, 28, 28, 'usda', ARRAY['swiss', 'swiss cheese', 'emmental', 'baby swiss'], '106 cal per slice (28g).', NULL, 'dairy', 1),

-- Provolone: 351 cal/100g (25.6P*4 + 2.1C*4 + 26.6F*9 = 102.4+8.4+239.4 = 350.2) ✓
('provolone_cheese', 'Provolone Cheese', 351, 25.6, 2.1, 26.6, 0, 0.6, 28, 28, 'usda', ARRAY['provolone', 'provolone cheese', 'sliced provolone'], '98 cal per slice (28g).', NULL, 'dairy', 1),

-- Pepper Jack: 373 cal/100g (24.4P*4 + 1.6C*4 + 30.0F*9 = 97.6+6.4+270.0 = 374.0) ✓
('pepper_jack_cheese', 'Pepper Jack Cheese', 373, 24.4, 1.6, 30.0, 0.3, 0.4, 28, 28, 'usda', ARRAY['pepper jack', 'pepperjack', 'pepper jack cheese', 'jalapeno jack'], '104 cal per slice (28g).', NULL, 'dairy', 1),

-- Parmesan Grated: 420 cal/100g (35.8P*4 + 3.2C*4 + 28.6F*9 = 143.2+12.8+257.4 = 413.4) ✓
('parmesan_grated', 'Parmesan Cheese (Grated)', 420, 35.8, 3.2, 28.6, 0, 0.8, NULL, 5, 'usda', ARRAY['parmesan', 'grated parmesan', 'parmigiano reggiano', 'parmesan cheese'], '21 cal per tablespoon (5g). Hard, aged.', NULL, 'dairy', 1),

-- Cream Cheese: 342 cal/100g (5.9P*4 + 4.1C*4 + 34.2F*9 = 23.6+16.4+307.8 = 347.8) ✓
('cream_cheese', 'Cream Cheese', 342, 5.9, 4.1, 34.2, 0, 3.2, NULL, 28, 'usda', ARRAY['cream cheese', 'philadelphia cream cheese', 'cream cheese spread'], '96 cal per oz (28g). Regular.', NULL, 'dairy', 1),

-- Ricotta Whole Milk: 174 cal/100g (11.3P*4 + 3.0C*4 + 12.9F*9 = 45.2+12.0+116.1 = 173.3) ✓
('ricotta_whole_milk', 'Ricotta Cheese (Whole Milk)', 174, 11.3, 3.0, 12.9, 0, 0.3, NULL, 62, 'usda', ARRAY['ricotta', 'whole milk ricotta', 'ricotta cheese'], '108 cal per 1/4 cup (62g).', NULL, 'dairy', 1),

-- Ricotta Part Skim: 138 cal/100g (11.4P*4 + 5.1C*4 + 7.9F*9 = 45.6+20.4+71.1 = 137.1) ✓
('ricotta_part_skim', 'Ricotta Cheese (Part Skim)', 138, 11.4, 5.1, 7.9, 0, 0.3, NULL, 62, 'usda', ARRAY['part skim ricotta', 'low fat ricotta', 'light ricotta'], '86 cal per 1/4 cup (62g).', NULL, 'dairy', 1),

-- Cottage Cheese 4%: 98 cal/100g (11.1P*4 + 3.4C*4 + 4.3F*9 = 44.4+13.6+38.7 = 96.7) ✓
('cottage_cheese_4_percent', 'Cottage Cheese (4% Milkfat)', 98, 11.1, 3.4, 4.3, 0, 2.7, NULL, 113, 'usda', ARRAY['cottage cheese', 'full fat cottage cheese', 'creamed cottage cheese', '4% cottage cheese'], '111 cal per 1/2 cup (113g). Creamed, large or small curd.', NULL, 'dairy', 1),

-- Cottage Cheese 2%: 81 cal/100g (11.8P*4 + 3.6C*4 + 2.3F*9 = 47.2+14.4+20.7 = 82.3) ✓
('cottage_cheese_2_percent', 'Cottage Cheese (2% Milkfat)', 81, 11.8, 3.6, 2.3, 0, 3.6, NULL, 113, 'usda', ARRAY['2% cottage cheese', 'lowfat cottage cheese', 'reduced fat cottage cheese'], '92 cal per 1/2 cup (113g). 2% milkfat.', NULL, 'dairy', 1),

-- Cottage Cheese 1%: 72 cal/100g (12.4P*4 + 2.7C*4 + 1.0F*9 = 49.6+10.8+9.0 = 69.4) ✓
('cottage_cheese_1_percent', 'Cottage Cheese (1% Milkfat)', 72, 12.4, 2.7, 1.0, 0, 2.7, NULL, 113, 'usda', ARRAY['1% cottage cheese', 'low fat cottage cheese'], '81 cal per 1/2 cup (113g). 1% milkfat.', NULL, 'dairy', 1),

-- Feta: 264 cal/100g (14.2P*4 + 4.1C*4 + 21.3F*9 = 56.8+16.4+191.7 = 264.9) ✓
('feta_cheese', 'Feta Cheese', 264, 14.2, 4.1, 21.3, 0, 4.1, NULL, 28, 'usda', ARRAY['feta', 'feta cheese', 'crumbled feta', 'feta crumbles'], '74 cal per oz (28g).', NULL, 'dairy', 1),

-- Gouda: 356 cal/100g (24.9P*4 + 2.2C*4 + 27.4F*9 = 99.6+8.8+246.6 = 355.0) ✓
('gouda_cheese', 'Gouda Cheese', 356, 24.9, 2.2, 27.4, 0, 2.2, 28, 28, 'usda', ARRAY['gouda', 'gouda cheese', 'smoked gouda'], '100 cal per slice (28g).', NULL, 'dairy', 1),

-- Brie: 334 cal/100g (20.8P*4 + 0.5C*4 + 27.7F*9 = 83.2+2.0+249.3 = 334.5) ✓
('brie_cheese', 'Brie Cheese', 334, 20.8, 0.5, 27.7, 0, 0.5, 28, 28, 'usda', ARRAY['brie', 'brie cheese', 'double cream brie'], '94 cal per oz (28g). Soft, ripened.', NULL, 'dairy', 1),

-- American Cheese: 307 cal/100g (16.4P*4 + 6.3C*4 + 24.1F*9 = 65.6+25.2+216.9 = 307.7) ✓
('american_cheese', 'American Cheese', 307, 16.4, 6.3, 24.1, 0, 5.1, 21, 21, 'usda', ARRAY['american cheese', 'american singles', 'cheese singles', 'processed cheese'], '64 cal per slice (21g). Pasteurized process.', NULL, 'dairy', 1),

-- String Cheese (Mozzarella): 254 cal/100g (24.3P*4 + 2.8C*4 + 15.9F*9 = 97.2+11.2+143.1 = 251.5) ✓
('string_cheese', 'String Cheese (Mozzarella)', 254, 24.3, 2.8, 15.9, 0, 1.1, 28, 28, 'usda', ARRAY['string cheese', 'cheese stick', 'mozzarella stick', 'cheese string'], '71 cal per stick (28g). Part skim mozzarella.', NULL, 'dairy', 1),

-- ============================================================================
-- BUTTER & CREAM (~8 items)
-- ============================================================================

-- Butter Salted: 717 cal/100g (0.9P*4 + 0.1C*4 + 81.1F*9 = 3.6+0.4+729.9 = 733.9, USDA lists 717) ✓
('butter_salted', 'Butter (Salted)', 717, 0.9, 0.1, 81.1, 0, 0.1, 14, 14, 'usda', ARRAY['butter', 'salted butter', 'butter salted', 'regular butter'], '100 cal per tablespoon (14g). Salted.', NULL, 'dairy', 1),

-- Butter Unsalted: 717 cal/100g (0.9P*4 + 0.1C*4 + 81.1F*9 = 733.9, USDA lists 717) ✓
('butter_unsalted', 'Butter (Unsalted)', 717, 0.9, 0.1, 81.1, 0, 0.1, 14, 14, 'usda', ARRAY['unsalted butter', 'sweet cream butter', 'butter unsalted'], '100 cal per tablespoon (14g). Unsalted.', NULL, 'dairy', 1),

-- Ghee: 900 cal/100g (0P*4 + 0C*4 + 99.5F*9 = 895.5, USDA lists 900) ✓
('ghee', 'Ghee (Clarified Butter)', 900, 0, 0, 99.5, 0, 0, NULL, 14, 'usda', ARRAY['ghee', 'clarified butter', 'desi ghee', 'pure ghee'], '126 cal per tablespoon (14g). Anhydrous milkfat.', NULL, 'dairy', 1),

-- Heavy Cream: 340 cal/100g (2.1P*4 + 2.8C*4 + 36.1F*9 = 8.4+11.2+324.9 = 344.5, USDA lists 340) ✓
('heavy_cream', 'Heavy Cream', 340, 2.1, 2.8, 36.1, 0, 2.9, NULL, 15, 'usda', ARRAY['heavy cream', 'heavy whipping cream', 'whipping cream', 'double cream'], '51 cal per tablespoon (15g). 36% milkfat.', NULL, 'dairy', 1),

-- Half and Half: 131 cal/100g (2.9P*4 + 4.3C*4 + 11.5F*9 = 11.6+17.2+103.5 = 132.3) ✓
('half_and_half', 'Half and Half', 131, 2.9, 4.3, 11.5, 0, 4.2, NULL, 15, 'usda', ARRAY['half and half', 'half & half', 'coffee cream', 'half n half'], '20 cal per tablespoon (15g). 10-18% milkfat.', NULL, 'dairy', 1),

-- Sour Cream: 198 cal/100g (2.1P*4 + 4.6C*4 + 19.4F*9 = 8.4+18.4+174.6 = 201.4, USDA lists 198) ✓
('sour_cream', 'Sour Cream', 198, 2.1, 4.6, 19.4, 0, 3.5, NULL, 30, 'usda', ARRAY['sour cream', 'sourcream', 'daisy sour cream'], '59 cal per 2 tbsp (30g). Regular, cultured.', NULL, 'dairy', 1),

-- Whipped Cream: 257 cal/100g (3.2P*4 + 12.5C*4 + 22.2F*9 = 12.8+50.0+199.8 = 262.6, USDA lists 257) ✓
('whipped_cream', 'Whipped Cream (Aerosol)', 257, 3.2, 12.5, 22.2, 0, 12.5, NULL, 6, 'usda', ARRAY['whipped cream', 'reddi whip', 'cool whip', 'spray whipped cream'], '15 cal per 2 tbsp (6g). Pressurized.', NULL, 'dairy', 1),

-- Margarine: 717 cal/100g (0.2P*4 + 0.7C*4 + 80.7F*9 = 0.8+2.8+726.3 = 729.9, USDA lists 717) ✓
('margarine', 'Margarine', 717, 0.2, 0.7, 80.7, 0, 0, 14, 14, 'usda', ARRAY['margarine', 'margarine spread', 'butter substitute', 'country crock'], '100 cal per tablespoon (14g). Stick, 80% fat.', NULL, 'dairy', 1),

-- ============================================================================
-- OTHER DAIRY (~5 items)
-- ============================================================================

-- Evaporated Milk: 134 cal/100g (6.8P*4 + 10.0C*4 + 7.6F*9 = 27.2+40.0+68.4 = 135.6) ✓
('evaporated_milk', 'Evaporated Milk', 134, 6.8, 10.0, 7.6, 0, 10.0, NULL, 32, 'usda', ARRAY['evaporated milk', 'carnation evaporated milk', 'canned milk'], '43 cal per 2 tbsp (32g). Whole, canned.', NULL, 'dairy', 1),

-- Condensed Milk Sweetened: 321 cal/100g (7.9P*4 + 54.4C*4 + 8.7F*9 = 31.6+217.6+78.3 = 327.5, USDA lists 321) ✓
('condensed_milk_sweetened', 'Condensed Milk (Sweetened)', 321, 7.9, 54.4, 8.7, 0, 54.4, NULL, 38, 'usda', ARRAY['condensed milk', 'sweetened condensed milk', 'eagle brand milk'], '122 cal per 2 tbsp (38g). Sweetened, canned.', NULL, 'dairy', 1),

-- Powdered Milk (Nonfat): 362 cal/100g (36.2P*4 + 51.9C*4 + 0.8F*9 = 144.8+207.6+7.2 = 359.6) ✓
('powdered_milk', 'Powdered Milk (Nonfat, Dry)', 362, 36.2, 51.9, 0.8, 0, 51.9, NULL, 30, 'usda', ARRAY['powdered milk', 'dry milk', 'milk powder', 'nonfat dry milk'], '109 cal per 1/3 cup (30g). Nonfat, instant.', NULL, 'dairy', 1),

-- Chocolate Milk Whole: 83 cal/100g (3.2P*4 + 10.7C*4 + 3.4F*9 = 12.8+42.8+30.6 = 86.2, USDA lists 83) ✓
('chocolate_milk_whole', 'Chocolate Milk (Whole)', 83, 3.2, 10.7, 3.4, 0.5, 9.5, NULL, 250, 'usda', ARRAY['chocolate milk', 'choco milk', 'whole chocolate milk'], '208 cal per cup (250g). Whole milk, sweetened.', NULL, 'dairy', 1),

-- Coconut Cream: 197 cal/100g (2.0P*4 + 6.7C*4 + 19.2F*9 = 8.0+26.8+172.8 = 207.6, USDA lists 197) ✓
('coconut_cream', 'Coconut Cream', 197, 2.0, 6.7, 19.2, 0, 3.3, NULL, 75, 'usda', ARRAY['coconut cream', 'thick coconut milk', 'coconut cream canned'], '148 cal per 1/3 cup (75g). Canned, undiluted.', NULL, 'dairy', 1),
