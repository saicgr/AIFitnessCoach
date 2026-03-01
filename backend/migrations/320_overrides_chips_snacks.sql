-- 320_overrides_chips_snacks.sql
-- Popular chip and snack brand items: Lay's/Frito-Lay, Pringles, Takis, Kettle Brand,
-- Cape Cod, Goldfish, Pirate's Booty, Smartfood, SkinnyPop, BoomChickaPop, Veggie Straws,
-- Popchips, Cheetos Asteroids, Funyuns.
-- Sources: nutritionix.com, calorieking.com, fatsecret.com, myfooddiary.com, eatthismuch.com,
-- nutritionvalue.org, official brand sites (lays.com, cheetos.com, pringles.com, tostitos.com, etc.)
-- All values per 100g, computed from per-serving (28g or 30g) label data.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ==========================================
-- LAY'S POTATO CHIPS
-- ==========================================

-- Lay's Classic: 160 cal / 28g = 571 cal/100g. USDA/nutritionvalue: 564 cal/100g, 7.1P, 52.9C, 35.3F, 3.5 fiber, 0 sugar.
('lays_classic', 'Lay''s Classic Potato Chips', 564, 7.1, 52.9, 35.3,
 3.5, 0.0, 28, NULL,
 'lays', ARRAY['lays classic', 'lay''s original', 'lays potato chips', 'lays regular', 'lay''s classic potato chips'],
 'chips_snacks', 'Lay''s', 1, '564 cal/100g. Per 28g bag: 160 cal. Potatoes, palm olein oil, salt.', TRUE),

-- Lay's Barbecue: 160 cal / 28g. Per 100g: 571 cal, 7.1P, 53.6C, 35.7F, 3.6 fiber, 7.1 sugar.
('lays_barbecue', 'Lay''s Barbecue Potato Chips', 571, 7.1, 53.6, 35.7,
 3.6, 7.1, 28, NULL,
 'lays', ARRAY['lays bbq', 'lay''s barbecue', 'lays barbecue chips', 'lay''s bbq potato chips'],
 'chips_snacks', 'Lay''s', 1, '571 cal/100g. Per 28g bag: 160 cal. Barbecue seasoned potato chips.', TRUE),

-- Lay's Sour Cream & Onion: 160 cal / 28g. Per 100g: 571 cal, 7.1P, 53.6C, 35.7F, 3.6 fiber, 3.6 sugar.
('lays_sour_cream_onion', 'Lay''s Sour Cream & Onion Potato Chips', 571, 7.1, 53.6, 35.7,
 3.6, 3.6, 28, NULL,
 'lays', ARRAY['lays sour cream and onion', 'lay''s sour cream onion', 'lays sco', 'lay''s sour cream & onion chips'],
 'chips_snacks', 'Lay''s', 1, '571 cal/100g. Per 28g bag: 160 cal. Sour cream & onion flavored.', TRUE),

-- Lay's Salt & Vinegar: 160 cal / 28g. Per 100g: 566 cal, 6.3P, 53.5C, 34.6F, 3.1 fiber, 3.1 sugar.
('lays_salt_vinegar', 'Lay''s Salt & Vinegar Potato Chips', 566, 6.3, 53.5, 34.6,
 3.1, 3.1, 28, NULL,
 'lays', ARRAY['lays salt and vinegar', 'lay''s salt & vinegar', 'lays s&v', 'lay''s salt vinegar chips'],
 'chips_snacks', 'Lay''s', 1, '566 cal/100g. Per 28g bag: 160 cal. Salt & vinegar seasoned.', TRUE),

-- Lay's Kettle Cooked Original: 150 cal / 28g = 536 cal/100g. 2P, 17C, 9F per 28g.
('lays_kettle_cooked', 'Lay''s Kettle Cooked Original Potato Chips', 536, 7.1, 60.7, 32.1,
 3.6, 3.6, 28, NULL,
 'lays', ARRAY['lays kettle cooked', 'lay''s kettle cooked original', 'lays kettle chips', 'lay''s kettle cooked potato chips'],
 'chips_snacks', 'Lay''s', 1, '536 cal/100g. Per 28g bag: 150 cal. Extra crunchy kettle cooked.', TRUE),

-- ==========================================
-- DORITOS
-- ==========================================

-- Doritos Nacho Cheese: per 100g from USDA: 500 cal, 7.1P, 57.1C, 28.6F, 3.6 fiber, 3.6 sugar.
('doritos_nacho_cheese', 'Doritos Nacho Cheese Tortilla Chips', 500, 7.1, 57.1, 28.6,
 3.6, 3.6, 28, NULL,
 'doritos', ARRAY['doritos nacho cheese', 'doritos nacho', 'nacho cheese doritos', 'doritos original'],
 'chips_snacks', 'Doritos', 1, '500 cal/100g. Per 28g bag: 140 cal. Nacho cheese flavored tortilla chips.', TRUE),

-- Doritos Cool Ranch: per 100g: 536 cal, 7.1P, 64.3C, 28.6F, 3.6 fiber, 3.6 sugar.
('doritos_cool_ranch', 'Doritos Cool Ranch Tortilla Chips', 536, 7.1, 64.3, 28.6,
 3.6, 3.6, 28, NULL,
 'doritos', ARRAY['doritos cool ranch', 'cool ranch doritos', 'doritos ranch'],
 'chips_snacks', 'Doritos', 1, '536 cal/100g. Per 28g bag: 150 cal. Cool ranch flavored tortilla chips.', TRUE),

-- Doritos Spicy Sweet Chili: 150 cal / 28g. 2P, 18C, 7F per 28g => 536/100g.
('doritos_spicy_sweet_chili', 'Doritos Spicy Sweet Chili Tortilla Chips', 536, 7.1, 64.3, 25.0,
 3.6, 3.6, 28, NULL,
 'doritos', ARRAY['doritos spicy sweet chili', 'doritos sweet chili', 'spicy sweet chili doritos'],
 'chips_snacks', 'Doritos', 1, '536 cal/100g. Per 28g bag: 150 cal. Spicy sweet chili flavored.', TRUE),

-- Doritos Flamin' Hot: 150 cal / 28g. 2P, 17C, 8F per 28g.
('doritos_flamin_hot', 'Doritos Flamin'' Hot Nacho Tortilla Chips', 536, 7.1, 60.7, 28.6,
 3.6, 1.8, 28, NULL,
 'doritos', ARRAY['doritos flamin hot', 'flamin hot doritos', 'doritos flamin'' hot nacho'],
 'chips_snacks', 'Doritos', 1, '536 cal/100g. Per 28g bag: 150 cal. Flamin'' hot nacho flavored.', TRUE),

-- ==========================================
-- CHEETOS
-- ==========================================

-- Cheetos Crunchy: 160 cal / 28g. 2P, 15C, 10F, 1 fiber, 1 sugar per 28g.
('cheetos_crunchy', 'Cheetos Crunchy Cheese Flavored Snacks', 571, 7.1, 53.6, 35.7,
 3.6, 3.6, 28, NULL,
 'cheetos', ARRAY['cheetos crunchy', 'cheetos original', 'crunchy cheetos', 'cheetos cheese'],
 'chips_snacks', 'Cheetos', 1, '571 cal/100g. Per 28g bag: 160 cal. Crunchy cheese flavored corn snacks.', TRUE),

-- Cheetos Puffs: 160 cal / 28g. 2P, 16C, 10F, 0.5 fiber, 1 sugar per 28g.
('cheetos_puffs', 'Cheetos Puffs Cheese Flavored Snacks', 571, 7.1, 57.1, 35.7,
 1.8, 3.6, 28, NULL,
 'cheetos', ARRAY['cheetos puffs', 'cheetos cheese puffs', 'puffed cheetos'],
 'chips_snacks', 'Cheetos', 1, '571 cal/100g. Per 28g bag: 160 cal. Puffy cheese flavored corn snacks.', TRUE),

-- Cheetos Flamin' Hot Crunchy: 170 cal / 28g. 1P, 15C, 11F, 0.5 fiber, 0 sugar per 28g.
('cheetos_flamin_hot_crunchy', 'Cheetos Flamin'' Hot Crunchy', 607, 3.6, 53.6, 39.3,
 1.8, 0.0, 28, NULL,
 'cheetos', ARRAY['cheetos flamin hot', 'hot cheetos', 'flamin hot cheetos', 'cheetos flamin'' hot crunchy', 'flaming hot cheetos'],
 'chips_snacks', 'Cheetos', 1, '607 cal/100g. Per 28g bag: 170 cal. Flamin'' hot crunchy cheese snacks.', TRUE),

-- Cheetos Flamin' Hot Limon: 160 cal / 28g. 1P, 15C, 11F, 1 fiber, 0 sugar per 28g.
('cheetos_flamin_hot_limon', 'Cheetos Flamin'' Hot Limon Crunchy', 571, 3.6, 53.6, 39.3,
 3.6, 0.0, 28, NULL,
 'cheetos', ARRAY['cheetos flamin hot limon', 'hot cheetos limon', 'cheetos flamin'' hot limon', 'cheetos lime'],
 'chips_snacks', 'Cheetos', 1, '571 cal/100g. Per 28g bag: 160 cal. Flamin'' hot with lime seasoning.', TRUE),

-- ==========================================
-- FRITOS
-- ==========================================

-- Fritos Original Corn Chips: 160 cal / 28g. 2P, 15C, 10F, 1 fiber, 0 sugar per 28g.
('fritos_original', 'Fritos Original Corn Chips', 571, 7.1, 53.6, 35.7,
 3.6, 0.0, 28, NULL,
 'fritos', ARRAY['fritos original', 'fritos corn chips', 'fritos regular', 'fritos plain'],
 'chips_snacks', 'Fritos', 1, '571 cal/100g. Per 28g bag: 160 cal. Corn, corn oil, salt. Simple 3-ingredient chip.', TRUE),

-- Fritos Chili Cheese: 160 cal / 28g. 2P, 16C, 10F, 1 fiber, 1 sugar per 28g.
('fritos_chili_cheese', 'Fritos Chili Cheese Flavored Corn Chips', 571, 7.1, 57.1, 35.7,
 3.6, 3.6, 28, NULL,
 'fritos', ARRAY['fritos chili cheese', 'chili cheese fritos', 'fritos chili cheese corn chips'],
 'chips_snacks', 'Fritos', 1, '571 cal/100g. Per 28g bag: 160 cal. Chili cheese flavored corn chips.', TRUE),

-- ==========================================
-- TOSTITOS
-- ==========================================

-- Tostitos Scoops: 140 cal / 28g. 2P, 19C, 7F, 1 fiber, 0 sugar per 28g.
('tostitos_scoops', 'Tostitos Scoops! Tortilla Chips', 500, 7.1, 67.9, 25.0,
 3.6, 0.0, 28, NULL,
 'tostitos', ARRAY['tostitos scoops', 'tostitos scoops tortilla chips', 'tostitos scoop chips'],
 'chips_snacks', 'Tostitos', 1, '500 cal/100g. Per 28g bag: 140 cal. Bowl-shaped tortilla chips for dipping.', TRUE),

-- Tostitos Restaurant Style: 140 cal / 28g. 2P, 18C, 7F, 1 fiber, 0 sugar per 28g.
('tostitos_restaurant_style', 'Tostitos Original Restaurant Style Tortilla Chips', 500, 7.1, 64.3, 25.0,
 3.6, 0.0, 28, NULL,
 'tostitos', ARRAY['tostitos restaurant style', 'tostitos original', 'tostitos restaurant style tortilla chips'],
 'chips_snacks', 'Tostitos', 1, '500 cal/100g. Per 28g bag: 140 cal. Classic restaurant-style tortilla chips.', TRUE),

-- Tostitos Hint of Lime: 150 cal / 28g. 2P, 19C, 7F, 1 fiber, 0 sugar per 28g.
('tostitos_hint_of_lime', 'Tostitos Hint of Lime Tortilla Chips', 536, 7.1, 67.9, 25.0,
 3.6, 0.0, 28, NULL,
 'tostitos', ARRAY['tostitos hint of lime', 'tostitos lime', 'tostitos lime chips', 'tostitos hint of lime tortilla chips'],
 'chips_snacks', 'Tostitos', 1, '536 cal/100g. Per 28g bag: 150 cal. Lime-seasoned tortilla chips.', TRUE),

-- ==========================================
-- RUFFLES
-- ==========================================

-- Ruffles Original: 160 cal / 28g. 2P, 15C, 10F, 1 fiber, 1 sugar per 28g.
('ruffles_original', 'Ruffles Original Potato Chips', 571, 7.1, 53.6, 35.7,
 3.6, 3.6, 28, NULL,
 'ruffles', ARRAY['ruffles original', 'ruffles potato chips', 'ruffles regular', 'ruffles ridged chips'],
 'chips_snacks', 'Ruffles', 1, '571 cal/100g. Per 28g bag: 160 cal. Ridged potato chips.', TRUE),

-- Ruffles Cheddar & Sour Cream: 160 cal / 28g. 2P, 15C, 10F per 28g.
('ruffles_cheddar_sour_cream', 'Ruffles Cheddar & Sour Cream Potato Chips', 571, 7.1, 53.6, 35.7,
 3.6, 3.6, 28, NULL,
 'ruffles', ARRAY['ruffles cheddar and sour cream', 'ruffles cheddar sour cream', 'ruffles cheddar & sour cream chips'],
 'chips_snacks', 'Ruffles', 1, '571 cal/100g. Per 28g bag: 160 cal. Cheddar & sour cream flavored ridged chips.', TRUE),

-- Ruffles Flamin' Hot: 150 cal / 28g. 2P, 16C, 10F per 28g.
('ruffles_flamin_hot', 'Ruffles Flamin'' Hot Potato Chips', 536, 7.1, 57.1, 35.7,
 3.6, 3.6, 28, NULL,
 'ruffles', ARRAY['ruffles flamin hot', 'ruffles flamin'' hot', 'hot ruffles', 'ruffles flaming hot'],
 'chips_snacks', 'Ruffles', 1, '536 cal/100g. Per 28g bag: 150 cal. Flamin'' hot flavored ridged chips.', TRUE),

-- ==========================================
-- SUNCHIPS
-- ==========================================

-- SunChips Harvest Cheddar: 140 cal / 28g. 2P, 19C, 6F, 2 fiber, 2 sugar per 28g.
('sunchips_harvest_cheddar', 'SunChips Harvest Cheddar Whole Grain Snacks', 500, 7.1, 67.9, 21.4,
 7.1, 7.1, 28, NULL,
 'sunchips', ARRAY['sunchips harvest cheddar', 'sun chips harvest cheddar', 'sunchips cheddar', 'harvest cheddar sun chips'],
 'chips_snacks', 'SunChips', 1, '500 cal/100g. Per 28g bag: 140 cal. Multigrain snacks with harvest cheddar.', TRUE),

-- SunChips Garden Salsa: 140 cal / 28g. 2P, 18C, 6F, 2 fiber, 2 sugar per 28g.
('sunchips_garden_salsa', 'SunChips Garden Salsa Whole Grain Snacks', 500, 7.1, 64.3, 21.4,
 7.1, 7.1, 28, NULL,
 'sunchips', ARRAY['sunchips garden salsa', 'sun chips garden salsa', 'sunchips salsa', 'garden salsa sun chips'],
 'chips_snacks', 'SunChips', 1, '500 cal/100g. Per 28g bag: 140 cal. Multigrain snacks with garden salsa.', TRUE),

-- ==========================================
-- PRINGLES
-- ==========================================

-- Pringles Original: 150 cal / 28g. 1P, 16C, 9F, 0.5 fiber, 0 sugar per 28g.
('pringles_original', 'Pringles Original Potato Crisps', 536, 3.6, 57.1, 32.1,
 1.8, 0.0, 28, NULL,
 'pringles', ARRAY['pringles original', 'pringles regular', 'pringles classic', 'original pringles'],
 'chips_snacks', 'Pringles', 1, '536 cal/100g. Per 28g (15 crisps): 150 cal. Stackable potato crisps.', TRUE),

-- Pringles Sour Cream & Onion: 150 cal / 28g. 1P, 16C, 9F, 0.5 fiber, 0.5 sugar per 28g.
('pringles_sour_cream_onion', 'Pringles Sour Cream & Onion Potato Crisps', 536, 3.6, 57.1, 32.1,
 1.8, 1.8, 28, NULL,
 'pringles', ARRAY['pringles sour cream and onion', 'pringles sour cream onion', 'pringles sco'],
 'chips_snacks', 'Pringles', 1, '536 cal/100g. Per 28g (15 crisps): 150 cal. Sour cream & onion flavored.', TRUE),

-- Pringles Cheddar Cheese: 150 cal / 28g. 1P, 16C, 9F per 28g.
('pringles_cheddar_cheese', 'Pringles Cheddar Cheese Potato Crisps', 536, 3.6, 57.1, 32.1,
 1.8, 0.0, 28, NULL,
 'pringles', ARRAY['pringles cheddar cheese', 'pringles cheddar', 'cheddar pringles', 'pringles cheese'],
 'chips_snacks', 'Pringles', 1, '536 cal/100g. Per 28g (15 crisps): 150 cal. Cheddar cheese flavored.', TRUE),

-- Pringles BBQ: 150 cal / 28g. 1P, 16C, 9F, 0.5 fiber, 1 sugar per 28g.
('pringles_bbq', 'Pringles BBQ Potato Crisps', 536, 3.6, 57.1, 32.1,
 1.8, 3.6, 28, NULL,
 'pringles', ARRAY['pringles bbq', 'pringles barbecue', 'bbq pringles', 'pringles barbeque'],
 'chips_snacks', 'Pringles', 1, '536 cal/100g. Per 28g (14 crisps): 150 cal. BBQ flavored potato crisps.', TRUE),

-- ==========================================
-- TAKIS
-- ==========================================

-- Takis Fuego: 150 cal / 28g. 2P, 17C, 8F, 1 fiber, 1 sugar per 28g.
('takis_fuego', 'Takis Fuego Hot Chili Pepper & Lime Rolled Tortilla Chips', 536, 7.1, 60.7, 28.6,
 3.6, 3.6, 28, NULL,
 'takis', ARRAY['takis fuego', 'takis', 'takis hot chili lime', 'fuego takis', 'takis red'],
 'chips_snacks', 'Takis', 1, '536 cal/100g. Per 28g bag: 150 cal. Hot chili pepper & lime rolled tortilla chips.', TRUE),

-- Takis Blue Heat: 150 cal / 28g. 2P, 17C, 8F, 1 fiber, 1 sugar per 28g.
('takis_blue_heat', 'Takis Blue Heat Hot Chili Pepper Rolled Tortilla Chips', 536, 7.1, 60.7, 28.6,
 3.6, 3.6, 28, NULL,
 'takis', ARRAY['takis blue heat', 'blue takis', 'takis blue', 'takis blue heat hot chili pepper'],
 'chips_snacks', 'Takis', 1, '536 cal/100g. Per 28g bag: 150 cal. Hot chili pepper rolled tortilla chips.', TRUE),

-- Takis Nitro: 150 cal / 28g. 2P, 17C, 8F, 1 fiber, 1 sugar per 28g.
('takis_nitro', 'Takis Nitro Habanero & Lime Rolled Tortilla Chips', 536, 7.1, 60.7, 28.6,
 3.6, 3.6, 28, NULL,
 'takis', ARRAY['takis nitro', 'takis habanero', 'takis nitro habanero lime', 'nitro takis'],
 'chips_snacks', 'Takis', 1, '536 cal/100g. Per 28g bag: 150 cal. Habanero & lime rolled tortilla chips.', TRUE),

-- ==========================================
-- KETTLE BRAND
-- ==========================================

-- Kettle Brand Sea Salt: 150 cal / 28g. 2P, 15C, 9F per 28g.
('kettle_brand_sea_salt', 'Kettle Brand Sea Salt Potato Chips', 536, 7.1, 53.6, 32.1,
 3.6, 0.0, 28, NULL,
 'kettle_brand', ARRAY['kettle brand sea salt', 'kettle chips sea salt', 'kettle brand original', 'kettle sea salt chips'],
 'chips_snacks', 'Kettle Brand', 1, '536 cal/100g. Per 28g bag: 150 cal. Kettle cooked with sea salt.', TRUE),

-- Kettle Brand Backyard BBQ: 140 cal / 28g. 2P, 16C, 8F, 2 fiber, 1 sugar per 28g.
('kettle_brand_backyard_bbq', 'Kettle Brand Backyard Barbeque Potato Chips', 500, 7.1, 57.1, 28.6,
 7.1, 3.6, 28, NULL,
 'kettle_brand', ARRAY['kettle brand backyard bbq', 'kettle chips bbq', 'kettle brand barbeque', 'kettle bbq chips'],
 'chips_snacks', 'Kettle Brand', 1, '500 cal/100g. Per 28g bag: 140 cal. Backyard barbeque kettle cooked.', TRUE),

-- ==========================================
-- CAPE COD
-- ==========================================

-- Cape Cod Original: 140 cal / 28g. 2P, 15C, 8F, 1 fiber, 0 sugar per 28g.
('cape_cod_original', 'Cape Cod Original Kettle Cooked Potato Chips', 500, 7.1, 53.6, 28.6,
 3.6, 0.0, 28, NULL,
 'cape_cod', ARRAY['cape cod original', 'cape cod chips', 'cape cod kettle cooked', 'cape cod potato chips'],
 'chips_snacks', 'Cape Cod', 1, '500 cal/100g. Per 28g bag: 140 cal. Kettle cooked potato chips.', TRUE),

-- Cape Cod Reduced Fat: 130 cal / 28g. 2P, 16C, 6F, 1 fiber, 0 sugar per 28g.
('cape_cod_reduced_fat', 'Cape Cod 40% Less Fat Original Kettle Cooked Potato Chips', 464, 7.1, 57.1, 21.4,
 3.6, 0.0, 28, NULL,
 'cape_cod', ARRAY['cape cod reduced fat', 'cape cod less fat', 'cape cod 40% less fat', 'cape cod light', 'cape cod reduced fat chips'],
 'chips_snacks', 'Cape Cod', 1, '464 cal/100g. Per 28g bag: 130 cal. 40% less fat than regular potato chips.', TRUE),

-- ==========================================
-- GOLDFISH
-- ==========================================

-- Goldfish Cheddar: 140 cal / 30g. 3P, 20C, 5F, 1 fiber, 0 sugar per 30g (55 pieces).
('goldfish_cheddar', 'Goldfish Cheddar Baked Snack Crackers', 467, 10.0, 66.7, 16.7,
 3.3, 0.0, 30, NULL,
 'goldfish', ARRAY['goldfish cheddar', 'goldfish crackers', 'pepperidge farm goldfish', 'goldfish original cheddar', 'cheddar goldfish'],
 'chips_snacks', 'Goldfish', 1, '467 cal/100g. Per 30g bag (55 pieces): 140 cal. Baked cheddar snack crackers.', TRUE),

-- Goldfish Flavor Blasted Xtra Cheddar: 140 cal / 30g. 3P, 19C, 5F, 1 fiber, 1 sugar per 30g.
('goldfish_flavor_blasted', 'Goldfish Flavor Blasted Xtra Cheddar Crackers', 467, 10.0, 63.3, 16.7,
 3.3, 3.3, 30, NULL,
 'goldfish', ARRAY['goldfish flavor blasted', 'goldfish xtra cheddar', 'flavor blasted goldfish', 'goldfish extra cheddar'],
 'chips_snacks', 'Goldfish', 1, '467 cal/100g. Per 30g bag (51 pieces): 140 cal. Extra cheddar flavor blasted.', TRUE),

-- ==========================================
-- PIRATE'S BOOTY
-- ==========================================

-- Pirate's Booty Aged White Cheddar: 130 cal / 28g. 2P, 19C, 5F, 0 fiber, 1 sugar per 28g.
('pirates_booty', 'Pirate''s Booty Aged White Cheddar', 464, 7.1, 67.9, 17.9,
 0.0, 3.6, 28, NULL,
 'pirates_booty', ARRAY['pirates booty', 'pirate''s booty', 'pirate booty', 'pirates booty white cheddar', 'pirate''s booty aged white cheddar'],
 'chips_snacks', 'Pirate''s Booty', 1, '464 cal/100g. Per 28g bag: 130 cal. Baked rice & corn puffs with aged white cheddar.', TRUE),

-- ==========================================
-- SMARTFOOD
-- ==========================================

-- Smartfood White Cheddar Popcorn: 160 cal / 28g. 3P, 15C, 10F, 2 fiber, 2 sugar per 28g.
('smartfood_white_cheddar', 'Smartfood White Cheddar Cheese Popcorn', 571, 10.7, 53.6, 35.7,
 7.1, 7.1, 28, NULL,
 'smartfood', ARRAY['smartfood white cheddar', 'smartfood popcorn', 'smartfood white cheddar popcorn', 'white cheddar smartfood'],
 'chips_snacks', 'Smartfood', 1, '571 cal/100g. Per 28g bag: 160 cal. White cheddar cheese flavored popcorn.', TRUE),

-- ==========================================
-- SKINNYPOP
-- ==========================================

-- SkinnyPop Original Popcorn: 150 cal / 28g. 2P, 15C, 10F, 2 fiber, 0 sugar per 28g.
('skinnypop_original', 'SkinnyPop Original Popcorn', 536, 7.1, 53.6, 35.7,
 7.1, 0.0, 28, NULL,
 'skinnypop', ARRAY['skinnypop', 'skinny pop', 'skinnypop original', 'skinny pop popcorn', 'skinnypop original popcorn'],
 'chips_snacks', 'SkinnyPop', 1, '536 cal/100g. Per 28g bag: 150 cal. Popcorn, sunflower oil, salt. Simple ingredients.', TRUE),

-- ==========================================
-- ANGIE'S BOOMCHICKAPOP
-- ==========================================

-- BoomChickaPop Sweet & Salty Kettle Corn: 140 cal / 28g. 1P, 18C, 8F, 2 fiber, 8 sugar per 28g.
('boomchickapop_sweet_salty', 'Angie''s BoomChickaPop Sweet & Salty Kettle Corn', 500, 3.6, 64.3, 28.6,
 7.1, 28.6, 28, NULL,
 'boomchickapop', ARRAY['boomchickapop', 'boom chicka pop', 'angie''s boomchickapop', 'boomchickapop sweet and salty', 'boomchickapop kettle corn'],
 'chips_snacks', 'Angie''s BoomChickaPop', 1, '500 cal/100g. Per 28g bag: 140 cal. Sweet & salty kettle corn popcorn.', TRUE),

-- ==========================================
-- VEGGIE STRAWS
-- ==========================================

-- Sensible Portions Garden Veggie Straws Sea Salt: 130 cal / 28g. 1P, 17C, 7F, 0 fiber, 1 sugar per 28g.
('veggie_straws', 'Sensible Portions Garden Veggie Straws Sea Salt', 464, 3.6, 60.7, 25.0,
 0.0, 3.6, 28, NULL,
 'sensible_portions', ARRAY['veggie straws', 'veggie straw chips', 'garden veggie straws', 'sensible portions veggie straws', 'vegetable straws'],
 'chips_snacks', 'Sensible Portions', 1, '464 cal/100g. Per 28g bag (38 straws): 130 cal. Vegetable and potato snack.', TRUE),

-- ==========================================
-- POPCHIPS
-- ==========================================

-- Popchips Sea Salt: 130 cal / 28g. 1P, 21C, 4.5F, 1 fiber, 1 sugar per 28g.
('popchips_sea_salt', 'Popchips Sea Salt Potato Chips', 464, 3.6, 75.0, 16.1,
 3.6, 3.6, 28, NULL,
 'popchips', ARRAY['popchips sea salt', 'popchips', 'pop chips', 'popchips original', 'popped chips sea salt'],
 'chips_snacks', 'Popchips', 1, '464 cal/100g. Per 28g bag: 130 cal. Popped (never fried) potato chips.', TRUE),

-- ==========================================
-- CHEETOS ASTEROIDS
-- ==========================================

-- Cheetos Flavor Shots Flamin' Hot Asteroids: 200 cal / 35g. 2P, 19C, 13F, 0.5 fiber, 0 sugar per 35g.
('cheetos_flamin_hot_asteroids', 'Cheetos Flamin'' Hot Asteroids Flavor Shots', 571, 5.7, 54.3, 37.1,
 1.4, 0.0, 35, NULL,
 'cheetos', ARRAY['cheetos asteroids', 'hot cheetos asteroids', 'cheetos flamin hot asteroids', 'cheetos flavor shots asteroids'],
 'chips_snacks', 'Cheetos', 1, '571 cal/100g. Per 35g bag: 200 cal. Flamin'' hot asteroids-shaped corn puffs.', TRUE),

-- ==========================================
-- FUNYUNS
-- ==========================================

-- Funyuns Onion Flavored Rings: 140 cal / 28g. 2P, 19C, 6F, 1 fiber, 1 sugar per 28g.
('funyuns_original', 'Funyuns Onion Flavored Rings', 500, 7.1, 67.9, 21.4,
 3.6, 3.6, 28, NULL,
 'funyuns', ARRAY['funyuns', 'funyuns onion rings', 'fun yuns', 'funyuns original', 'onion flavored rings'],
 'chips_snacks', 'Funyuns', 1, '500 cal/100g. Per 28g bag (13 rings): 140 cal. Onion flavored ring snacks.', TRUE)

ON CONFLICT (food_name_normalized)
DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_serving_g = EXCLUDED.default_serving_g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  notes = EXCLUDED.notes,
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  is_active = TRUE,
  updated_at = NOW();
