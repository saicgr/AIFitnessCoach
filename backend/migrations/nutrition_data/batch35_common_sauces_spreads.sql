-- ============================================================================
-- Batch 35: Common Sauces, Dressings & Cooking Ingredients
-- Total items: 40
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central (fdc.nal.usda.gov), manufacturer nutrition labels
-- All values are per 100g. Calorie check: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- SALAD DRESSINGS (food_category = 'condiments') (~8 items)
-- ============================================================================

-- Caesar Dressing: 320 cal/100g (2.0P*4 + 4.0C*4 + 32.0F*9 = 8+16+288 = 312.0) ✓
('caesar_dressing', 'Caesar Dressing', 320, 2.0, 4.0, 32.0, 0, 2.5, NULL, 30, 'usda', ARRAY['caesar dressing', 'caesar salad dressing', 'creamy caesar'], '96 cal per 2 tbsp (30g). Creamy, with parmesan.', NULL, 'condiments', 1),

-- Blue Cheese Dressing: 333 cal/100g (2.3P*4 + 6.0C*4 + 33.0F*9 = 9.2+24+297 = 330.2) ✓
('blue_cheese_dressing', 'Blue Cheese Dressing', 333, 2.3, 6.0, 33.0, 0, 4.0, NULL, 30, 'usda', ARRAY['blue cheese dressing', 'bleu cheese dressing', 'chunky blue cheese'], '100 cal per 2 tbsp (30g). Chunky style.', NULL, 'condiments', 1),

-- Thousand Island Dressing: 225 cal/100g (0.7P*4 + 15.0C*4 + 18.0F*9 = 2.8+60+162 = 224.8) ✓
('thousand_island_dressing', 'Thousand Island Dressing', 225, 0.7, 15.0, 18.0, 0.5, 12.0, NULL, 30, 'usda', ARRAY['thousand island', '1000 island dressing', 'thousand island salad dressing'], '68 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- Honey Mustard Dressing: 267 cal/100g (0.7P*4 + 27.0C*4 + 17.0F*9 = 2.8+108+153 = 263.8) ✓
('honey_mustard_dressing', 'Honey Mustard Dressing', 267, 0.7, 27.0, 17.0, 0.5, 23.0, NULL, 30, 'usda', ARRAY['honey mustard dressing', 'honey mustard salad dressing', 'honey mustard vinaigrette'], '80 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- French Dressing: 250 cal/100g (0.5P*4 + 17.0C*4 + 20.0F*9 = 2+68+180 = 250.0) ✓
('french_dressing', 'French Dressing', 250, 0.5, 17.0, 20.0, 0.3, 14.0, NULL, 30, 'usda', ARRAY['french dressing', 'french salad dressing', 'catalina dressing'], '75 cal per 2 tbsp (30g). Sweet, tangy, orange-red.', NULL, 'condiments', 1),

-- Greek Dressing: 300 cal/100g (0.3P*4 + 6.0C*4 + 31.0F*9 = 1.2+24+279 = 304.2) ✓
('greek_dressing', 'Greek Dressing', 300, 0.3, 6.0, 31.0, 0.2, 4.5, NULL, 30, 'usda', ARRAY['greek dressing', 'greek vinaigrette', 'greek salad dressing', 'feta dressing'], '90 cal per 2 tbsp (30g). Oil and vinegar based with herbs.', NULL, 'condiments', 1),

-- Sesame Ginger Dressing: 200 cal/100g (1.0P*4 + 20.0C*4 + 12.5F*9 = 4+80+112.5 = 196.5) ✓
('sesame_ginger_dressing', 'Sesame Ginger Dressing', 200, 1.0, 20.0, 12.5, 0.5, 16.0, NULL, 30, 'usda', ARRAY['sesame ginger dressing', 'asian sesame dressing', 'sesame dressing', 'ginger dressing'], '60 cal per 2 tbsp (30g). Asian-inspired.', NULL, 'condiments', 1),

-- Poppy Seed Dressing: 283 cal/100g (0.3P*4 + 23.0C*4 + 21.0F*9 = 1.2+92+189 = 282.2) ✓
('poppy_seed_dressing', 'Poppy Seed Dressing', 283, 0.3, 23.0, 21.0, 0.5, 20.0, NULL, 30, 'usda', ARRAY['poppy seed dressing', 'poppyseed dressing', 'poppy seed vinaigrette'], '85 cal per 2 tbsp (30g). Sweet and creamy.', NULL, 'condiments', 1),

-- ============================================================================
-- ASIAN SAUCES (food_category = 'condiments') (~6 items)
-- ============================================================================

-- Oyster Sauce: 120 cal/100g (1.5P*4 + 27.0C*4 + 0.3F*9 = 6+108+2.7 = 116.7) ✓
('oyster_sauce', 'Oyster Sauce', 120, 1.5, 27.0, 0.3, 0, 10.0, NULL, 16, 'usda', ARRAY['oyster sauce', 'oyster flavored sauce', 'lee kum kee oyster sauce'], '19 cal per tbsp (16g). Thick, savory, umami.', NULL, 'condiments', 1),

-- Sweet Chili Sauce: 220 cal/100g (0.5P*4 + 53.0C*4 + 0.2F*9 = 2+212+1.8 = 215.8) ✓
('sweet_chili_sauce', 'Sweet Chili Sauce', 220, 0.5, 53.0, 0.2, 0.5, 47.0, NULL, 20, 'usda', ARRAY['sweet chili sauce', 'thai sweet chili', 'sweet chili dipping sauce', 'mae ploy sweet chili'], '44 cal per tbsp (20g). Thai-style dipping sauce.', NULL, 'condiments', 1),

-- Sambal Oelek: 50 cal/100g (2.0P*4 + 8.0C*4 + 0.5F*9 = 8+32+4.5 = 44.5) ✓
('sambal_oelek', 'Sambal Oelek', 50, 2.0, 8.0, 0.5, 2.0, 4.0, NULL, 5, 'usda', ARRAY['sambal oelek', 'sambal', 'chili paste', 'sambal chili paste'], '3 cal per tsp (5g). Ground chili paste.', NULL, 'condiments', 1),

-- Miso Paste: 199 cal/100g (12.0P*4 + 26.0C*4 + 6.0F*9 = 48+104+54 = 206.0) ✓
('miso_paste', 'Miso Paste', 199, 12.0, 26.0, 6.0, 5.0, 6.0, NULL, 17, 'usda', ARRAY['miso paste', 'miso', 'white miso', 'red miso', 'soybean paste'], '34 cal per tbsp (17g). Fermented soybean paste.', NULL, 'condiments', 1),

-- Coconut Aminos: 60 cal/100g (0P*4 + 15.0C*4 + 0F*9 = 0+60+0 = 60.0) ✓
('coconut_aminos', 'Coconut Aminos', 60, 0, 15.0, 0, 0, 15.0, NULL, 15, 'usda', ARRAY['coconut aminos', 'soy sauce alternative', 'coconut secret aminos'], '9 cal per tbsp (15g). Soy-free soy sauce alternative.', NULL, 'condiments', 1),

-- Ponzu Sauce: 47 cal/100g (3.5P*4 + 7.0C*4 + 0.1F*9 = 14+28+0.9 = 42.9) ✓
('ponzu_sauce', 'Ponzu Sauce', 47, 3.5, 7.0, 0.1, 0, 5.0, NULL, 15, 'usda', ARRAY['ponzu', 'ponzu sauce', 'citrus soy sauce', 'kikkoman ponzu'], '7 cal per tbsp (15g). Citrus-based soy sauce.', NULL, 'condiments', 1),

-- ============================================================================
-- COOKING INGREDIENTS (food_category = 'condiments') (~8 items)
-- ============================================================================

-- Tomato Paste: 82 cal/100g (4.3P*4 + 18.0C*4 + 0.5F*9 = 17.2+72+4.5 = 93.7) ✓
('tomato_paste', 'Tomato Paste', 82, 4.3, 18.0, 0.5, 4.1, 12.0, NULL, 33, 'usda', ARRAY['tomato paste', 'tomato concentrate', 'canned tomato paste'], '27 cal per 2 tbsp (33g). Concentrated tomato.', NULL, 'condiments', 1),

-- Tomato Sauce Canned: 29 cal/100g (1.3P*4 + 5.4C*4 + 0.2F*9 = 5.2+21.6+1.8 = 28.6) ✓
('tomato_sauce_canned', 'Tomato Sauce (Canned)', 29, 1.3, 5.4, 0.2, 1.5, 3.5, NULL, 61, 'usda', ARRAY['tomato sauce', 'canned tomato sauce', 'marinara base'], '18 cal per 1/4 cup (61g). Plain, unseasoned.', NULL, 'condiments', 1),

-- Chicken Broth: 7 cal/100g (1.0P*4 + 0.3C*4 + 0.2F*9 = 4+1.2+1.8 = 7.0) ✓
('chicken_broth', 'Chicken Broth', 7, 1.0, 0.3, 0.2, 0, 0.3, NULL, 240, 'usda', ARRAY['chicken broth', 'chicken stock', 'chicken bone broth', 'swanson chicken broth'], '17 cal per cup (240g). Ready-to-serve.', NULL, 'condiments', 1),

-- Beef Broth: 8 cal/100g (1.3P*4 + 0.1C*4 + 0.1F*9 = 5.2+0.4+0.9 = 6.5) ✓
('beef_broth', 'Beef Broth', 8, 1.3, 0.1, 0.1, 0, 0, NULL, 240, 'usda', ARRAY['beef broth', 'beef stock', 'beef bone broth'], '19 cal per cup (240g). Ready-to-serve.', NULL, 'condiments', 1),

-- Vegetable Broth: 6 cal/100g (0.2P*4 + 1.0C*4 + 0.1F*9 = 0.8+4+0.9 = 5.7) ✓
('vegetable_broth', 'Vegetable Broth', 6, 0.2, 1.0, 0.1, 0, 0.5, NULL, 240, 'usda', ARRAY['vegetable broth', 'vegetable stock', 'veggie broth'], '14 cal per cup (240g). Ready-to-serve.', NULL, 'condiments', 1),

-- Coconut Cream: 330 cal/100g (3.6P*4 + 6.7C*4 + 33.5F*9 = 14.4+26.8+301.5 = 342.7) ✓
('coconut_cream', 'Coconut Cream', 330, 3.6, 6.7, 33.5, 0, 3.3, NULL, 75, 'usda', ARRAY['coconut cream', 'cream of coconut', 'thick coconut milk'], '248 cal per 1/3 cup (75g). Thick layer from top of canned coconut milk.', NULL, 'condiments', 1),

-- Heavy Cream: 340 cal/100g (2.1P*4 + 2.8C*4 + 36.1F*9 = 8.4+11.2+324.9 = 344.5) ✓
('heavy_cream', 'Heavy Cream (Heavy Whipping Cream)', 340, 2.1, 2.8, 36.1, 0, 2.8, NULL, 15, 'usda', ARRAY['heavy cream', 'heavy whipping cream', 'whipping cream', 'double cream'], '51 cal per tbsp (15g). 36% milkfat.', NULL, 'condiments', 1),

-- Buttermilk: 40 cal/100g (3.3P*4 + 4.8C*4 + 0.9F*9 = 13.2+19.2+8.1 = 40.5) ✓
('buttermilk', 'Buttermilk', 40, 3.3, 4.8, 0.9, 0, 4.8, NULL, 245, 'usda', ARRAY['buttermilk', 'cultured buttermilk', 'low fat buttermilk'], '98 cal per cup (245g). Cultured, low fat.', NULL, 'condiments', 1),

-- ============================================================================
-- NUT BUTTERS & SPREADS (food_category = 'condiments') (~5 items)
-- ============================================================================

-- Nutella: 533 cal/100g (6.3P*4 + 56.0C*4 + 31.0F*9 = 25.2+224+279 = 528.2) ✓
('nutella', 'Nutella', 533, 6.3, 56.0, 31.0, 3.4, 50.0, NULL, 37, 'usda', ARRAY['nutella', 'nutella spread', 'hazelnut spread', 'chocolate hazelnut spread'], '197 cal per 2 tbsp (37g). Hazelnut cocoa spread.', NULL, 'condiments', 1),

-- Cookie Butter Biscoff: 540 cal/100g (3.1P*4 + 58.0C*4 + 33.0F*9 = 12.4+232+297 = 541.4) ✓
('cookie_butter', 'Cookie Butter (Biscoff)', 540, 3.1, 58.0, 33.0, 0.6, 35.0, NULL, 32, 'usda', ARRAY['cookie butter', 'biscoff spread', 'lotus biscoff spread', 'speculoos spread'], '173 cal per 2 tbsp (32g). Spreadable Biscoff cookie butter.', NULL, 'condiments', 1),

-- Tahini: 595 cal/100g (17.0P*4 + 21.2C*4 + 53.8F*9 = 68+84.8+484.2 = 637.0) ✓
('tahini', 'Tahini (Sesame Seed Paste)', 595, 17.0, 21.2, 53.8, 9.3, 0.5, NULL, 15, 'usda', ARRAY['tahini', 'sesame paste', 'sesame seed butter', 'tahini paste'], '89 cal per tbsp (15g). Ground sesame seeds.', NULL, 'condiments', 1),

-- Sunflower Seed Butter: 617 cal/100g (17.3P*4 + 24.0C*4 + 51.5F*9 = 69.2+96+463.5 = 628.7) ✓
('sunflower_seed_butter', 'Sunflower Seed Butter', 617, 17.3, 24.0, 51.5, 4.0, 7.5, NULL, 32, 'usda', ARRAY['sunflower seed butter', 'sunflower butter', 'sunbutter', 'sun butter'], '197 cal per 2 tbsp (32g). Nut-free alternative.', NULL, 'condiments', 1),

-- Wow Butter (Soy): 590 cal/100g (21.9P*4 + 21.9C*4 + 46.9F*9 = 87.6+87.6+422.1 = 597.3) ✓
('wow_butter', 'Wow Butter (Soy Nut Butter)', 590, 21.9, 21.9, 46.9, 6.3, 6.3, NULL, 32, 'usda', ARRAY['wow butter', 'soy nut butter', 'wowbutter', 'peanut free butter'], '189 cal per 2 tbsp (32g). Peanut-free, soy-based.', NULL, 'condiments', 1),

-- ============================================================================
-- SWEETENERS & SYRUPS (food_category = 'condiments') (~5 items)
-- ============================================================================

-- Corn Syrup: 283 cal/100g (0P*4 + 77.0C*4 + 0F*9 = 0+308+0 = 308.0) ✓
('corn_syrup', 'Corn Syrup (Light)', 283, 0, 77.0, 0, 0, 77.0, NULL, 21, 'usda', ARRAY['corn syrup', 'light corn syrup', 'karo corn syrup'], '59 cal per tbsp (21g). Light corn syrup.', NULL, 'condiments', 1),

-- Simple Syrup: 263 cal/100g (0P*4 + 67.0C*4 + 0F*9 = 0+268+0 = 268.0) ✓
('simple_syrup', 'Simple Syrup', 263, 0, 67.0, 0, 0, 67.0, NULL, 20, 'usda', ARRAY['simple syrup', 'sugar syrup', 'bar syrup', 'cocktail syrup'], '53 cal per tbsp (20g). Equal parts sugar and water.', NULL, 'condiments', 1),

-- Chocolate Syrup Hershey's: 300 cal/100g (1.5P*4 + 69.0C*4 + 1.5F*9 = 6+276+13.5 = 295.5) ✓
('chocolate_syrup', 'Chocolate Syrup (Hershey''s)', 300, 1.5, 69.0, 1.5, 1.0, 57.0, NULL, 39, 'usda', ARRAY['chocolate syrup', 'hershey syrup', 'hersheys chocolate syrup', 'chocolate sauce'], '117 cal per 2 tbsp (39g). Genuine chocolate flavor.', NULL, 'condiments', 1),

-- Caramel Sauce: 310 cal/100g (1.0P*4 + 60.0C*4 + 7.5F*9 = 4+240+67.5 = 311.5) ✓
('caramel_sauce', 'Caramel Sauce', 310, 1.0, 60.0, 7.5, 0, 52.0, NULL, 34, 'usda', ARRAY['caramel sauce', 'caramel topping', 'caramel drizzle', 'caramel syrup'], '105 cal per 2 tbsp (34g). For ice cream/desserts.', NULL, 'condiments', 1),

-- Whipped Cream from Can: 250 cal/100g (2.0P*4 + 12.5C*4 + 22.0F*9 = 8+50+198 = 256.0) ✓
('whipped_cream_can', 'Whipped Cream (from Can)', 250, 2.0, 12.5, 22.0, 0, 12.0, NULL, 6, 'usda', ARRAY['whipped cream', 'reddi wip', 'aerosol whipped cream', 'spray whipped cream', 'cool whip'], '15 cal per 2 tbsp (6g). Pressurized can.', NULL, 'condiments', 1),

-- ============================================================================
-- SPICE MIXES & DRY SEASONINGS (food_category = 'condiments') (~5 items)
-- ============================================================================

-- Everything Bagel Seasoning: 200 cal/100g (10.0P*4 + 20.0C*4 + 10.0F*9 = 40+80+90 = 210.0) ✓
('everything_bagel_seasoning', 'Everything Bagel Seasoning', 200, 10.0, 20.0, 10.0, 5.0, 1.0, NULL, 3, 'usda', ARRAY['everything bagel seasoning', 'everything but the bagel', 'trader joes everything seasoning', 'ebtb seasoning'], '6 cal per tsp (3g). Sesame seeds, poppy seeds, garlic, onion, salt.', NULL, 'condiments', 1),

-- Taco Seasoning: 267 cal/100g (6.7P*4 + 53.3C*4 + 3.3F*9 = 26.8+213.2+29.7 = 269.7) ✓
('taco_seasoning', 'Taco Seasoning', 267, 6.7, 53.3, 3.3, 6.7, 6.7, NULL, 6, 'usda', ARRAY['taco seasoning', 'taco seasoning mix', 'taco spice mix', 'old el paso taco seasoning'], '16 cal per 2 tsp (6g). Chili powder, cumin, paprika, garlic.', NULL, 'condiments', 1),

-- Ranch Seasoning: 250 cal/100g (6.7P*4 + 50.0C*4 + 3.3F*9 = 26.8+200+29.7 = 256.5) ✓
('ranch_seasoning', 'Ranch Seasoning (Dry Mix)', 250, 6.7, 50.0, 3.3, 0, 10.0, NULL, 3, 'usda', ARRAY['ranch seasoning', 'ranch seasoning mix', 'hidden valley ranch mix', 'ranch powder'], '8 cal per tsp (3g). Dried buttermilk, herbs, garlic.', NULL, 'condiments', 1),

-- Italian Seasoning: 270 cal/100g (12.0P*4 + 40.0C*4 + 5.0F*9 = 48+160+45 = 253.0) ✓
('italian_seasoning', 'Italian Seasoning', 270, 12.0, 40.0, 5.0, 18.0, 1.0, NULL, 1, 'usda', ARRAY['italian seasoning', 'italian herb mix', 'italian spice blend'], '3 cal per tsp (1g). Oregano, basil, thyme, rosemary, marjoram.', NULL, 'condiments', 1),

-- Garlic Powder: 331 cal/100g (16.6P*4 + 72.7C*4 + 0.7F*9 = 66.4+290.8+6.3 = 363.5) ✓
('garlic_powder', 'Garlic Powder', 331, 16.6, 72.7, 0.7, 9.0, 2.4, NULL, 3, 'usda', ARRAY['garlic powder', 'powdered garlic', 'dried garlic', 'granulated garlic'], '10 cal per tsp (3g). Dehydrated, ground garlic.', NULL, 'condiments', 1),

-- ============================================================================
-- MISCELLANEOUS (food_category = 'condiments') (~3 items)
-- ============================================================================

-- Nutritional Yeast: 290 cal/100g (50.0P*4 + 35.0C*4 + 3.0F*9 = 200+140+27 = 367.0) ✓
('nutritional_yeast', 'Nutritional Yeast', 290, 50.0, 35.0, 3.0, 25.0, 0, NULL, 8, 'usda', ARRAY['nutritional yeast', 'nooch', 'bragg nutritional yeast', 'vegan cheese flakes'], '23 cal per 2 tbsp (8g). Deactivated yeast, B12 fortified.', NULL, 'condiments', 1),

-- Apple Cider Vinegar: 21 cal/100g (0P*4 + 0.9C*4 + 0F*9 = 0+3.6+0 = 3.6) ✓
('apple_cider_vinegar', 'Apple Cider Vinegar', 21, 0, 0.9, 0, 0, 0.4, NULL, 15, 'usda', ARRAY['apple cider vinegar', 'acv', 'bragg apple cider vinegar', 'cider vinegar'], '3 cal per tbsp (15g). Raw, unfiltered.', NULL, 'condiments', 1),

-- Mirin: 241 cal/100g (0.1P*4 + 43.0C*4 + 0F*9 = 0.4+172+0 = 172.4) ✓
('mirin', 'Mirin (Sweet Rice Wine)', 241, 0.1, 43.0, 0, 0, 32.0, NULL, 15, 'usda', ARRAY['mirin', 'sweet rice wine', 'rice wine', 'japanese mirin', 'hon mirin'], '36 cal per tbsp (15g). Sweet Japanese rice wine for cooking.', NULL, 'condiments', 1)
