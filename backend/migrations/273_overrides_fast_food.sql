-- ============================================================================
-- 273_overrides_fast_food.sql
-- Generated: 2026-02-28
-- Total items: 592
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes
) VALUES
-- ============================================================================
-- Batch 1: Restaurant Nutrition Data
-- Restaurants: McDonald's, Chick-fil-A, Starbucks, Taco Bell, Wendy's,
--              Burger King, Subway, Dunkin', Domino's, Popeyes
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, fastfoodnutrition.org,
--          nutritionvalue.org, fatsecret.com, eatthismuch.com, nutritionix.com,
--          snapcalorie.com, calorieking.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================
-- ============================================================================
-- McDONALD'S (expanding beyond existing 16 items)
-- ============================================================================
-- Big Mac: 580 cal, 34g fat, 25g protein, 45g carbs, 3g fiber, 7g sugar per 219g
-- Quarter Pounder with Cheese: 520 cal, 26g fat, 30g protein, 42g carbs, 2g fiber, 10g sugar per 202g
-- McDouble: 390 cal, 20g fat, 22g protein, 32g carbs, 2g fiber, 6g sugar per 147g
-- Double Cheeseburger: 440 cal, 24g fat, 25g protein, 34g carbs, 2g fiber, 6g sugar per 165g
-- Hamburger: 250 cal, 9g fat, 12g protein, 30g carbs, 1g fiber, 5g sugar per 100g
-- McChicken: 390 cal, 21g fat, 14g protein, 38g carbs, 1g fiber, 4g sugar per 143g
-- Filet-O-Fish: 380 cal, 19g fat, 16g protein, 38g carbs, 1g fiber, 4g sugar per 141g
-- McCrispy (Classic): 470 cal, 20g fat, 27g protein, 45g carbs, 1g fiber, 9g sugar per 200g
-- Egg McMuffin: 310 cal, 13g fat, 17g protein, 30g carbs, 2g fiber, 3g sugar per 137g
-- Sausage McMuffin: 400 cal, 25g fat, 14g protein, 29g carbs, 2g fiber, 2g sugar per 115g
-- Sausage McMuffin with Egg: 480 cal, 30g fat, 21g protein, 30g carbs, 2g fiber, 2g sugar per 163g
-- Bacon Egg & Cheese Biscuit: 450 cal, 23g fat, 18g protein, 41g carbs, 2g fiber, 4g sugar per 163g
-- Sausage Biscuit: 460 cal, 30g fat, 11g protein, 37g carbs, 2g fiber, 2g sugar per 120g
-- Hotcakes: 580 cal, 15g fat, 12g protein, 100g carbs, 2g fiber, 45g sugar per 260g
-- French Fries Small: 220 cal, 10g fat, 3g protein, 29g carbs, 3g fiber, 0g sugar per 75g
-- French Fries Large: 480 cal, 23g fat, 7g protein, 64g carbs, 6g fiber, 0g sugar per 150g
-- Apple Pie: 230 cal, 11g fat, 3g protein, 32g carbs, 1g fiber, 14g sugar per 77g
-- McFlurry with OREO (Regular): 510 cal, 17g fat, 12g protein, 80g carbs, 1g fiber, 63g sugar per 285g
-- McFlurry with M&M's (Regular): 630 cal, 23g fat, 14g protein, 96g carbs, 1g fiber, 83g sugar per 305g
-- Vanilla Cone: 200 cal, 5g fat, 5g protein, 33g carbs, 0g fiber, 24g sugar per 142g
-- Chocolate Shake Medium: 630 cal, 16g fat, 14g protein, 109g carbs, 1g fiber, 90g sugar per 444g
-- Coca-Cola Medium: 210 cal, 0g fat, 0g protein, 58g carbs, 0g fiber, 58g sugar per 630ml
-- Sprite Medium: 200 cal, 0g fat, 0g protein, 54g carbs, 0g fiber, 54g sugar per 630ml
-- ============================================================================
-- CHICK-FIL-A
-- ============================================================================
-- Chicken Sandwich: 420 cal, 18g fat, 29g protein, 41g carbs, 1g fiber, 6g sugar per 187g
-- Spicy Chicken Sandwich: 450 cal, 19g fat, 29g protein, 42g carbs, 2g fiber, 6g sugar per 187g
-- Deluxe Chicken Sandwich: 500 cal, 22g fat, 30g protein, 47g carbs, 2g fiber, 8g sugar per 223g
-- Spicy Deluxe Sandwich: 540 cal, 24g fat, 31g protein, 48g carbs, 2g fiber, 8g sugar per 223g
-- Grilled Chicken Sandwich: 390 cal, 12g fat, 28g protein, 44g carbs, 3g fiber, 11g sugar per 208g
-- Chicken Nuggets 8ct: 250 cal, 11g fat, 27g protein, 11g carbs, 0g fiber, 1g sugar per 113g
-- Chicken Nuggets 12ct: 380 cal, 17g fat, 40g protein, 17g carbs, 0g fiber, 1g sugar per 170g
-- Grilled Nuggets 8ct: 130 cal, 3g fat, 25g protein, 1g carbs, 0g fiber, 1g sugar per 113g
-- Chick-n-Strips 3ct: 310 cal, 15g fat, 29g protein, 16g carbs, 0g fiber, 2g sugar per 120g
-- Waffle Fries Medium: 420 cal, 24g fat, 5g protein, 46g carbs, 5g fiber, 1g sugar per 125g
-- Mac & Cheese Medium: 450 cal, 29g fat, 20g protein, 28g carbs, 3g fiber, 3g sugar per 227g
-- Chicken Soup Medium: 340 cal, 10g fat, 24g protein, 36g carbs, 3g fiber, 2g sugar per 397g
-- Chick-fil-A Sauce: 140 cal, 13g fat, 0g protein, 7g carbs, 0g fiber, 6g sugar per 28g
-- Polynesian Sauce: 110 cal, 6g fat, 0g protein, 13g carbs, 0g fiber, 12g sugar per 28g
-- Icedream Cone: 170 cal, 4g fat, 5g protein, 31g carbs, 0g fiber, 24g sugar per 142g
-- Chocolate Milkshake: 590 cal, 22g fat, 14g protein, 87g carbs, 1g fiber, 76g sugar per 482g
-- Chicken Biscuit: 460 cal, 23g fat, 19g protein, 45g carbs, 2g fiber, 6g sugar per 163g
-- 4ct Chick-n-Minis: 360 cal, 13g fat, 20g protein, 41g carbs, 2g fiber, 8g sugar per 132g
-- Egg White Grill: 300 cal, 8g fat, 27g protein, 29g carbs, 1g fiber, 2g sugar per 148g
-- Cobb Salad: 530 cal, 28g fat, 40g protein, 28g carbs, 5g fiber, 6g sugar per 430g
-- Frosted Lemonade: 370 cal, 6g fat, 6g protein, 75g carbs, 0g fiber, 71g sugar per 482g
-- ============================================================================
-- STARBUCKS
-- ============================================================================
-- Caffe Latte Grande (2% milk): 190 cal, 7g fat, 13g protein, 19g carbs, 0g fiber, 17g sugar per 473ml
-- Caramel Macchiato Grande: 250 cal, 7g fat, 10g protein, 35g carbs, 0g fiber, 33g sugar per 473ml
-- Vanilla Sweet Cream Cold Brew Grande: 200 cal, 10g fat, 2g protein, 24g carbs, 0g fiber, 24g sugar per 473ml
-- Caramel Frappuccino Grande: 370 cal, 15g fat, 5g protein, 54g carbs, 0g fiber, 50g sugar per 473ml
-- Mocha Frappuccino Grande: 370 cal, 14g fat, 5g protein, 55g carbs, 1g fiber, 51g sugar per 473ml
-- Java Chip Frappuccino Grande: 440 cal, 18g fat, 6g protein, 63g carbs, 2g fiber, 55g sugar per 473ml
-- White Chocolate Mocha Grande: 430 cal, 16g fat, 12g protein, 59g carbs, 0g fiber, 57g sugar per 473ml
-- Chai Tea Latte Grande: 240 cal, 4.5g fat, 8g protein, 42g carbs, 0g fiber, 42g sugar per 473ml
-- Matcha Creme Frappuccino Grande: 420 cal, 16g fat, 6g protein, 63g carbs, 1g fiber, 61g sugar per 473ml
-- Pumpkin Spice Latte Grande: 390 cal, 14g fat, 14g protein, 52g carbs, 0g fiber, 50g sugar per 473ml
-- Iced White Chocolate Mocha Grande: 420 cal, 15g fat, 11g protein, 61g carbs, 0g fiber, 56g sugar per 473ml
-- Pink Drink Grande: 140 cal, 2.5g fat, 1g protein, 26g carbs, 1g fiber, 24g sugar per 473ml
-- Mango Dragonfruit Lemonade Refresher Grande: 140 cal, 0g fat, 1g protein, 34g carbs, 0g fiber, 30g sugar per 473ml
-- Bacon Gouda Breakfast Sandwich: 370 cal, 19g fat, 18g protein, 32g carbs, 1g fiber, 4g sugar per 138g
-- Tomato Mozzarella on Focaccia: 360 cal, 12g fat, 15g protein, 47g carbs, 2g fiber, 5g sugar per 155g
-- Egg & Cheese Protein Box: 470 cal, 31g fat, 28g protein, 18g carbs, 4g fiber, 8g sugar per 213g
-- Chocolate Croissant: 340 cal, 17g fat, 6g protein, 39g carbs, 2g fiber, 15g sugar per 85g
-- Butter Croissant: 260 cal, 14g fat, 5g protein, 28g carbs, 1g fiber, 5g sugar per 68g
-- Old Fashioned Glazed Doughnut: 480 cal, 27g fat, 5g protein, 56g carbs, 1g fiber, 32g sugar per 113g
-- Vanilla Bean Scone: 480 cal, 18g fat, 7g protein, 71g carbs, 1g fiber, 37g sugar per 128g
-- Blueberry Muffin: 390 cal, 16g fat, 5g protein, 57g carbs, 1g fiber, 31g sugar per 113g
-- Cake Pop (Birthday): 170 cal, 8g fat, 2g protein, 22g carbs, 0g fiber, 18g sugar per 42g
-- ============================================================================
-- TACO BELL (expanding beyond existing items)
-- ============================================================================
-- Chalupa Supreme (Beef): 400 cal, 24g fat, 13g protein, 31g carbs, 2g fiber, 3g sugar per 153g
-- Doritos Locos Tacos: 170 cal, 9g fat, 8g protein, 13g carbs, 3g fiber, 1g sugar per 78g
-- Doritos Locos Tacos Supreme: 190 cal, 11g fat, 8g protein, 14g carbs, 3g fiber, 1g sugar per 92g
-- Soft Taco (Beef): 180 cal, 9g fat, 8g protein, 18g carbs, 3g fiber, 1g sugar per 99g
-- Crunchy Taco: 170 cal, 10g fat, 8g protein, 13g carbs, 3g fiber, 1g sugar per 78g
-- Crunchy Taco Supreme: 190 cal, 11g fat, 8g protein, 14g carbs, 3g fiber, 2g sugar per 92g
-- Soft Taco Supreme: 210 cal, 10g fat, 9g protein, 22g carbs, 3g fiber, 2g sugar per 113g
-- Black Bean Chalupa Supreme: 330 cal, 18g fat, 10g protein, 34g carbs, 5g fiber, 4g sugar per 153g
-- Spicy Potato Soft Taco: 220 cal, 10g fat, 4g protein, 27g carbs, 3g fiber, 2g sugar per 99g
-- Doritos Cheesy Gordita Crunch: 500 cal, 29g fat, 15g protein, 41g carbs, 4g fiber, 4g sugar per 163g
-- Cheesy Gordita Crunch: 500 cal, 29g fat, 15g protein, 41g carbs, 4g fiber, 4g sugar per 163g
-- Grilled Cheese Burrito: 720 cal, 34g fat, 27g protein, 76g carbs, 5g fiber, 4g sugar per 312g
-- Beefy 5-Layer Burrito: 490 cal, 18g fat, 18g protein, 63g carbs, 6g fiber, 3g sugar per 241g
-- Burrito Supreme: 380 cal, 14g fat, 15g protein, 50g carbs, 7g fiber, 4g sugar per 248g
-- Bean Burrito: 370 cal, 10g fat, 14g protein, 55g carbs, 8g fiber, 3g sugar per 198g
-- Cheesy Bean and Rice Burrito: 420 cal, 16g fat, 12g protein, 57g carbs, 5g fiber, 3g sugar per 227g
-- Black Bean Grilled Cheese Burrito: 650 cal, 28g fat, 22g protein, 77g carbs, 8g fiber, 5g sugar per 312g
-- Cheesy Double Beef Burrito: 450 cal, 19g fat, 18g protein, 51g carbs, 4g fiber, 3g sugar per 227g
-- Crunchwrap Supreme: 530 cal, 20g fat, 15g protein, 73g carbs, 6g fiber, 6g sugar per 254g
-- Mexican Pizza: 540 cal, 30g fat, 19g protein, 48g carbs, 7g fiber, 3g sugar per 213g
-- Nacho Fries: 320 cal, 16g fat, 4g protein, 41g carbs, 4g fiber, 0g sugar per 128g
-- Cheesy Roll Up: 180 cal, 10g fat, 7g protein, 15g carbs, 0g fiber, 1g sugar per 57g
-- Nacho Fries Large: 440 cal, 22g fat, 5g protein, 56g carbs, 5g fiber, 0g sugar per 170g
-- 3 Cheese Chicken Flatbread Melt: 310 cal, 14g fat, 16g protein, 30g carbs, 1g fiber, 2g sugar per 128g
-- Nachos BellGrande: 740 cal, 39g fat, 16g protein, 80g carbs, 9g fiber, 5g sugar per 305g
-- Chips and Nacho Cheese Sauce: 220 cal, 12g fat, 3g protein, 25g carbs, 1g fiber, 1g sugar per 57g
-- Chips and Guacamole: 230 cal, 14g fat, 3g protein, 23g carbs, 4g fiber, 1g sugar per 78g
-- Cantina Chicken Bowl: 570 cal, 24g fat, 30g protein, 58g carbs, 7g fiber, 4g sugar per 397g
-- Veggie Bowl: 530 cal, 21g fat, 15g protein, 71g carbs, 10g fiber, 4g sugar per 397g
-- Cheesy Fiesta Potatoes: 230 cal, 14g fat, 3g protein, 24g carbs, 2g fiber, 1g sugar per 113g
-- Pintos N Cheese: 160 cal, 5g fat, 8g protein, 20g carbs, 5g fiber, 1g sugar per 128g
-- Black Beans and Rice: 180 cal, 3g fat, 6g protein, 32g carbs, 4g fiber, 1g sugar per 170g
-- Black Beans: 50 cal, 0g fat, 3g protein, 8g carbs, 3g fiber, 0g sugar per 57g
-- Crispy Chicken Nuggets 10pc: 460 cal, 26g fat, 20g protein, 35g carbs, 2g fiber, 1g sugar per 165g
-- Avocado Ranch Chicken Stacker: 310 cal, 16g fat, 12g protein, 29g carbs, 2g fiber, 2g sugar per 142g
-- Mini Taco Salad: 510 cal, 26g fat, 16g protein, 52g carbs, 6g fiber, 4g sugar per 284g
-- ============================================================================
-- WENDY'S
-- ============================================================================
-- Dave's Single: 570 cal, 34g fat, 30g protein, 40g carbs, 3g fiber, 9g sugar per 244g
-- Dave's Double: 850 cal, 54g fat, 48g protein, 40g carbs, 3g fiber, 9g sugar per 340g
-- Dave's Triple: 1100 cal, 72g fat, 69g protein, 40g carbs, 3g fiber, 9g sugar per 430g
-- Baconator: 950 cal, 62g fat, 59g protein, 40g carbs, 2g fiber, 8g sugar per 344g
-- Jr. Bacon Cheeseburger: 370 cal, 21g fat, 19g protein, 27g carbs, 1g fiber, 6g sugar per 151g
-- Spicy Chicken Sandwich: 500 cal, 19g fat, 28g protein, 53g carbs, 2g fiber, 6g sugar per 213g
-- Classic Chicken Sandwich: 490 cal, 20g fat, 28g protein, 50g carbs, 2g fiber, 5g sugar per 213g
-- Crispy Chicken Sandwich: 330 cal, 16g fat, 14g protein, 33g carbs, 2g fiber, 4g sugar per 143g
-- 10pc Nuggets: 420 cal, 27g fat, 22g protein, 24g carbs, 1g fiber, 0g sugar per 147g
-- Spicy Nuggets 10pc: 430 cal, 27g fat, 22g protein, 26g carbs, 2g fiber, 0g sugar per 147g
-- Natural Cut Fries Medium: 350 cal, 16g fat, 5g protein, 47g carbs, 4g fiber, 0g sugar per 142g
-- Chili Medium: 250 cal, 8g fat, 19g protein, 25g carbs, 5g fiber, 6g sugar per 284g
-- Baked Potato Plain: 270 cal, 0g fat, 7g protein, 63g carbs, 7g fiber, 3g sugar per 284g
-- Baked Potato Sour Cream & Chive: 310 cal, 4g fat, 8g protein, 63g carbs, 7g fiber, 4g sugar per 311g
-- Chocolate Frosty Small: 350 cal, 9g fat, 10g protein, 58g carbs, 0g fiber, 47g sugar per 255g
-- Vanilla Frosty Small: 340 cal, 9g fat, 10g protein, 56g carbs, 0g fiber, 45g sugar per 255g
-- Apple Pecan Salad Full: 560 cal, 24g fat, 38g protein, 52g carbs, 7g fiber, 40g sugar per 397g
-- ============================================================================
-- BURGER KING
-- ============================================================================
-- Whopper: 610 cal, 33g fat, 31g protein, 47g carbs, 4g fiber, 11g sugar per 270g
-- Whopper with Cheese: 700 cal, 40g fat, 35g protein, 48g carbs, 4g fiber, 11g sugar per 290g
-- Double Whopper: 850 cal, 52g fat, 48g protein, 47g carbs, 4g fiber, 11g sugar per 373g
-- Whopper Jr.: 310 cal, 15g fat, 14g protein, 29g carbs, 2g fiber, 7g sugar per 143g
-- Impossible Whopper: 630 cal, 34g fat, 25g protein, 58g carbs, 7g fiber, 12g sugar per 270g
-- Bacon Cheeseburger: 330 cal, 16g fat, 18g protein, 27g carbs, 1g fiber, 6g sugar per 130g
-- Cheeseburger: 280 cal, 13g fat, 14g protein, 27g carbs, 1g fiber, 6g sugar per 113g
-- Original Chicken Sandwich: 660 cal, 40g fat, 22g protein, 54g carbs, 3g fiber, 5g sugar per 209g
-- Spicy Ch'King: 700 cal, 32g fat, 28g protein, 74g carbs, 3g fiber, 10g sugar per 246g
-- Chicken Nuggets 8pc: 340 cal, 21g fat, 16g protein, 20g carbs, 1g fiber, 0g sugar per 120g
-- French Fries Medium: 380 cal, 17g fat, 5g protein, 53g carbs, 4g fiber, 0g sugar per 128g
-- Onion Rings Medium: 370 cal, 18g fat, 5g protein, 48g carbs, 3g fiber, 4g sugar per 113g
-- Mozzarella Sticks 4pc: 300 cal, 16g fat, 12g protein, 28g carbs, 2g fiber, 2g sugar per 85g
-- HERSHEY'S Sundae Pie: 310 cal, 18g fat, 3g protein, 32g carbs, 1g fiber, 19g sugar per 79g
-- Vanilla Shake Medium: 570 cal, 17g fat, 12g protein, 91g carbs, 0g fiber, 79g sugar per 397g
-- ============================================================================
-- SUBWAY
-- ============================================================================
-- 6" Italian B.M.T.: 410 cal, 16g fat, 20g protein, 46g carbs, 3g fiber, 7g sugar per 234g
-- 6" Turkey Breast: 270 cal, 3.5g fat, 18g protein, 43g carbs, 3g fiber, 6g sugar per 220g
-- 6" Subway Club: 310 cal, 5g fat, 24g protein, 43g carbs, 3g fiber, 6g sugar per 241g
-- 6" Steak & Cheese: 380 cal, 11g fat, 25g protein, 44g carbs, 3g fiber, 7g sugar per 258g
-- 6" Chicken Teriyaki: 330 cal, 4.5g fat, 26g protein, 46g carbs, 3g fiber, 12g sugar per 258g
-- 6" Meatball Marinara: 480 cal, 18g fat, 22g protein, 56g carbs, 5g fiber, 12g sugar per 284g
-- 6" Tuna: 450 cal, 22g fat, 19g protein, 44g carbs, 3g fiber, 6g sugar per 234g
-- 6" Cold Cut Combo: 310 cal, 10g fat, 16g protein, 43g carbs, 3g fiber, 6g sugar per 234g
-- 6" Spicy Italian: 470 cal, 23g fat, 20g protein, 46g carbs, 3g fiber, 7g sugar per 234g
-- 6" Veggie Delite: 200 cal, 2g fat, 7g protein, 39g carbs, 3g fiber, 5g sugar per 157g
-- Footlong Italian B.M.T.: 820 cal, 32g fat, 40g protein, 92g carbs, 6g fiber, 14g sugar per 468g
-- Footlong Meatball Marinara: 960 cal, 36g fat, 44g protein, 112g carbs, 10g fiber, 24g sugar per 568g
-- Chocolate Chip Cookie: 210 cal, 10g fat, 2g protein, 30g carbs, 1g fiber, 18g sugar per 45g
-- ============================================================================
-- DUNKIN'
-- ============================================================================
-- Glazed Donut: 260 cal, 12g fat, 3g protein, 33g carbs, 1g fiber, 12g sugar per 74g
-- Chocolate Frosted Donut: 290 cal, 14g fat, 3g protein, 38g carbs, 1g fiber, 18g sugar per 78g
-- Boston Kreme Donut: 280 cal, 12g fat, 3g protein, 39g carbs, 1g fiber, 17g sugar per 99g
-- Jelly Donut: 270 cal, 11g fat, 3g protein, 39g carbs, 1g fiber, 14g sugar per 86g
-- Blueberry Muffin: 460 cal, 16g fat, 6g protein, 73g carbs, 2g fiber, 39g sugar per 152g
-- Everything Bagel: 350 cal, 5g fat, 13g protein, 64g carbs, 3g fiber, 6g sugar per 122g
-- Plain Bagel: 320 cal, 2g fat, 12g protein, 65g carbs, 3g fiber, 6g sugar per 119g
-- Bacon Egg & Cheese Croissant: 550 cal, 33g fat, 19g protein, 42g carbs, 1g fiber, 6g sugar per 173g
-- Sausage Egg & Cheese Croissant: 650 cal, 42g fat, 21g protein, 42g carbs, 1g fiber, 6g sugar per 192g
-- Bacon Egg & Cheese on English Muffin: 360 cal, 17g fat, 18g protein, 33g carbs, 1g fiber, 3g sugar per 147g
-- Hash Browns 6pc: 370 cal, 23g fat, 3g protein, 38g carbs, 3g fiber, 0g sugar per 96g
-- Medium Iced Coffee (with cream and sugar): 260 cal, 6g fat, 2g protein, 49g carbs, 0g fiber, 49g sugar per 680ml
-- Medium Latte: 170 cal, 7g fat, 11g protein, 17g carbs, 0g fiber, 16g sugar per 397g
-- Medium Caramel Swirl Latte: 310 cal, 7g fat, 11g protein, 51g carbs, 0g fiber, 46g sugar per 397g
-- Medium Frozen Coffee: 420 cal, 11g fat, 3g protein, 76g carbs, 1g fiber, 72g sugar per 680ml
-- Medium Charli Cold Brew: 330 cal, 6g fat, 3g protein, 63g carbs, 0g fiber, 63g sugar per 680ml
-- ============================================================================
-- DOMINO'S
-- ============================================================================
-- Hand Tossed Cheese Pizza (14" Large, 1 slice): 280 cal, 10g fat, 12g protein, 36g carbs, 2g fiber, 3g sugar per 113g
-- Hand Tossed Pepperoni Pizza (14" Large, 1 slice): 300 cal, 12g fat, 13g protein, 36g carbs, 2g fiber, 3g sugar per 113g
-- Hand Tossed MeatZZa Pizza (14" Large, 1 slice): 340 cal, 16g fat, 16g protein, 35g carbs, 2g fiber, 3g sugar per 128g
-- Hand Tossed Deluxe Pizza (14" Large, 1 slice): 300 cal, 13g fat, 12g protein, 35g carbs, 2g fiber, 3g sugar per 123g
-- Hand Tossed BBQ Chicken Pizza (14" Large, 1 slice): 290 cal, 9g fat, 14g protein, 39g carbs, 1g fiber, 8g sugar per 123g
-- Medium Hand Tossed Cheese Pizza (12", 1 slice): 210 cal, 7.5g fat, 9g protein, 27g carbs, 1g fiber, 2g sugar per 85g
-- Stuffed Cheesy Bread: 120 cal, 6g fat, 5g protein, 12g carbs, 1g fiber, 1g sugar per 38g
-- Boneless Chicken Wings 8pc: 700 cal, 34g fat, 32g protein, 66g carbs, 3g fiber, 4g sugar per 228g
-- Bread Twists: 200 cal, 8g fat, 5g protein, 27g carbs, 1g fiber, 2g sugar per 57g
-- Pasta in Dish - Chicken Alfredo: 600 cal, 30g fat, 26g protein, 56g carbs, 3g fiber, 4g sugar per 397g
-- Pasta in Dish - Italian Sausage Marinara: 560 cal, 21g fat, 23g protein, 70g carbs, 5g fiber, 8g sugar per 397g
-- Cinnamon Bread Twists: 250 cal, 11g fat, 3g protein, 34g carbs, 1g fiber, 11g sugar per 57g
-- Marbled Cookie Brownie: 200 cal, 9g fat, 2g protein, 28g carbs, 1g fiber, 17g sugar per 51g
-- ============================================================================
-- POPEYES
-- ============================================================================
-- Classic Chicken Sandwich: 700 cal, 42g fat, 28g protein, 50g carbs, 2g fiber, 8g sugar per 200g
-- Spicy Chicken Sandwich: 700 cal, 42g fat, 28g protein, 50g carbs, 2g fiber, 8g sugar per 200g
-- 3pc Chicken Tenders (Mild): 340 cal, 14g fat, 35g protein, 16g carbs, 1g fiber, 0g sugar per 127g
-- 5pc Chicken Tenders (Mild): 570 cal, 23g fat, 58g protein, 27g carbs, 2g fiber, 0g sugar per 212g
-- 2pc Chicken (Breast & Wing, Mild): 440 cal, 26g fat, 35g protein, 16g carbs, 1g fiber, 0g sugar per 178g
-- 2pc Chicken (Leg & Thigh, Mild): 350 cal, 22g fat, 22g protein, 14g carbs, 1g fiber, 0g sugar per 152g
-- Chicken Breast (Mild): 280 cal, 16g fat, 24g protein, 10g carbs, 0g fiber, 0g sugar per 128g
-- Chicken Leg (Mild): 160 cal, 9g fat, 14g protein, 5g carbs, 0g fiber, 0g sugar per 72g
-- Chicken Thigh (Mild): 230 cal, 15g fat, 14g protein, 9g carbs, 1g fiber, 0g sugar per 99g
-- Chicken Wing (Mild): 150 cal, 10g fat, 10g protein, 5g carbs, 0g fiber, 0g sugar per 57g
-- Biscuit: 200 cal, 11g fat, 3g protein, 23g carbs, 1g fiber, 2g sugar per 57g
-- Cajun Fries Regular: 260 cal, 14g fat, 3g protein, 31g carbs, 3g fiber, 0g sugar per 99g
-- Cajun Fries Large: 470 cal, 25g fat, 5g protein, 57g carbs, 5g fiber, 0g sugar per 170g
-- Red Beans & Rice Regular: 230 cal, 6g fat, 8g protein, 34g carbs, 6g fiber, 1g sugar per 142g
-- Mashed Potatoes & Gravy Regular: 110 cal, 4g fat, 1g protein, 18g carbs, 2g fiber, 1g sugar per 142g
-- Coleslaw Regular: 200 cal, 15g fat, 1g protein, 17g carbs, 2g fiber, 13g sugar per 128g
-- Mac & Cheese Regular: 340 cal, 19g fat, 14g protein, 28g carbs, 1g fiber, 4g sugar per 142g
-- Cajun Rice Regular: 170 cal, 5g fat, 7g protein, 25g carbs, 1g fiber, 0g sugar per 113g
-- Apple Pie: 230 cal, 11g fat, 3g protein, 31g carbs, 1g fiber, 14g sugar per 85g
('mcdonalds_big_mac', 'McDonald''s Big Mac', 264.8, 11.4, 20.5, 15.5, 1.4, 3.2, 219, 219, 'mcdonalds.com', ARRAY['big mac', 'bigmac'], '580 cal per sandwich (219g)'),
('mcdonalds_quarter_pounder_cheese', 'McDonald''s Quarter Pounder with Cheese', 257.4, 14.9, 20.8, 12.9, 1.0, 5.0, 202, 202, 'mcdonalds.com', ARRAY['quarter pounder', 'qpc', 'quarter pounder with cheese'], '520 cal per sandwich (202g)'),
('mcdonalds_mcdouble', 'McDonald''s McDouble', 265.3, 15.0, 21.8, 13.6, 1.4, 4.1, 147, 147, 'mcdonalds.com', ARRAY['mcdouble', 'mc double'], '390 cal per sandwich (147g)'),
('mcdonalds_double_cheeseburger', 'McDonald''s Double Cheeseburger', 266.7, 15.2, 20.6, 14.5, 1.2, 3.6, 165, 165, 'mcdonalds.com', ARRAY['double cheeseburger', 'double cheese burger'], '440 cal per sandwich (165g)'),
('mcdonalds_hamburger', 'McDonald''s Hamburger', 250.0, 12.0, 30.0, 9.0, 1.0, 5.0, 100, 100, 'mcdonalds.com', ARRAY['hamburger', 'plain hamburger'], '250 cal per sandwich (100g)'),
('mcdonalds_mcchicken', 'McDonald''s McChicken', 272.7, 9.8, 26.6, 14.7, 0.7, 2.8, 143, 143, 'mcdonalds.com', ARRAY['mcchicken', 'mc chicken'], '390 cal per sandwich (143g)'),
('mcdonalds_filet_o_fish', 'McDonald''s Filet-O-Fish', 269.5, 11.3, 26.9, 13.5, 0.7, 2.8, 141, 141, 'mcdonalds.com', ARRAY['filet o fish', 'fish sandwich', 'filet-o-fish'], '380 cal per sandwich (141g)'),
('mcdonalds_mccrispy', 'McDonald''s McCrispy', 235.0, 13.5, 22.5, 10.0, 0.5, 4.5, 200, 200, 'mcdonalds.com', ARRAY['mccrispy', 'crispy chicken sandwich', 'classic mccrispy'], '470 cal per sandwich (200g)'),
('mcdonalds_egg_mcmuffin', 'McDonald''s Egg McMuffin', 226.3, 12.4, 21.9, 9.5, 1.5, 2.2, 137, 137, 'mcdonalds.com', ARRAY['egg mcmuffin', 'egg mc muffin', 'mcmuffin'], '310 cal per sandwich (137g)'),
('mcdonalds_sausage_mcmuffin', 'McDonald''s Sausage McMuffin', 347.8, 12.2, 25.2, 21.7, 1.7, 1.7, 115, 115, 'mcdonalds.com', ARRAY['sausage mcmuffin', 'sausage mc muffin'], '400 cal per sandwich (115g)'),
('mcdonalds_sausage_mcmuffin_egg', 'McDonald''s Sausage McMuffin with Egg', 294.5, 12.9, 18.4, 18.4, 1.2, 1.2, 163, 163, 'mcdonalds.com', ARRAY['sausage egg mcmuffin', 'sausage mcmuffin with egg'], '480 cal per sandwich (163g)'),
('mcdonalds_bacon_egg_cheese_biscuit', 'McDonald''s Bacon Egg & Cheese Biscuit', 276.1, 11.0, 25.2, 14.1, 1.2, 2.5, 163, 163, 'mcdonalds.com', ARRAY['bacon egg cheese biscuit', 'bec biscuit'], '450 cal per sandwich (163g)'),
('mcdonalds_sausage_biscuit', 'McDonald''s Sausage Biscuit', 383.3, 9.2, 30.8, 25.0, 1.7, 1.7, 120, 120, 'mcdonalds.com', ARRAY['sausage biscuit'], '460 cal per biscuit (120g)'),
('mcdonalds_hotcakes', 'McDonald''s Hotcakes', 223.1, 4.6, 38.5, 5.8, 0.8, 17.3, 260, 260, 'mcdonalds.com', ARRAY['hotcakes', 'pancakes', 'hot cakes'], '580 cal per order with syrup (260g)'),
('mcdonalds_french_fries_small', 'McDonald''s French Fries (Small)', 293.3, 4.0, 38.7, 13.3, 4.0, 0.0, 75, 75, 'mcdonalds.com', ARRAY['small fries', 'small french fries'], '220 cal per small (75g)'),
('mcdonalds_french_fries_large', 'McDonald''s French Fries (Large)', 320.0, 4.7, 42.7, 15.3, 4.0, 0.0, 150, 150, 'mcdonalds.com', ARRAY['large fries', 'large french fries'], '480 cal per large (150g)'),
('mcdonalds_apple_pie', 'McDonald''s Baked Apple Pie', 298.7, 3.9, 41.6, 14.3, 1.3, 18.2, 77, 77, 'mcdonalds.com', ARRAY['apple pie', 'baked apple pie'], '230 cal per pie (77g)'),
('mcdonalds_mcflurry_oreo', 'McDonald''s McFlurry with OREO Cookies', 178.9, 4.2, 28.1, 6.0, 0.4, 22.1, 285, 285, 'mcdonalds.com', ARRAY['mcflurry oreo', 'oreo mcflurry', 'mcflurry'], '510 cal per regular (285g)'),
('mcdonalds_mcflurry_mm', 'McDonald''s McFlurry with M&M''s', 206.6, 4.6, 31.5, 7.5, 0.3, 27.2, 305, 305, 'mcdonalds.com', ARRAY['mcflurry m&m', 'mm mcflurry', 'm&m mcflurry'], '630 cal per regular (305g)'),
('mcdonalds_vanilla_cone', 'McDonald''s Vanilla Cone', 140.8, 3.5, 23.2, 3.5, 0.0, 16.9, 142, 142, 'mcdonalds.com', ARRAY['vanilla cone', 'soft serve cone', 'ice cream cone'], '200 cal per cone (142g)'),
('mcdonalds_chocolate_shake_medium', 'McDonald''s Chocolate Shake (Medium)', 141.9, 3.2, 24.5, 3.6, 0.2, 20.3, 444, 444, 'mcdonalds.com', ARRAY['chocolate shake', 'chocolate milkshake'], '630 cal per medium (444g)'),
('mcdonalds_coca_cola_medium', 'McDonald''s Coca-Cola (Medium)', 33.3, 0.0, 9.2, 0.0, 0.0, 9.2, 630, 630, 'mcdonalds.com', ARRAY['medium coke', 'coca cola medium'], '210 cal per medium 21oz (630ml)'),
('mcdonalds_sprite_medium', 'McDonald''s Sprite (Medium)', 31.7, 0.0, 8.6, 0.0, 0.0, 8.6, 630, 630, 'mcdonalds.com', ARRAY['medium sprite', 'sprite medium'], '200 cal per medium 21oz (630ml)'),
('chickfila_chicken_sandwich', 'Chick-fil-A Chicken Sandwich', 224.6, 15.5, 21.9, 9.6, 0.5, 3.2, 187, 187, 'chick-fil-a.com', ARRAY['chick fil a sandwich', 'chickfila sandwich', 'chicken sandwich'], '420 cal per sandwich (187g)'),
('chickfila_spicy_chicken_sandwich', 'Chick-fil-A Spicy Chicken Sandwich', 240.6, 15.5, 22.5, 10.2, 1.1, 3.2, 187, 187, 'chick-fil-a.com', ARRAY['spicy chicken sandwich', 'chickfila spicy'], '450 cal per sandwich (187g)'),
('chickfila_deluxe_sandwich', 'Chick-fil-A Deluxe Sandwich', 224.2, 13.5, 21.1, 9.9, 0.9, 3.6, 223, 223, 'chick-fil-a.com', ARRAY['deluxe sandwich', 'chickfila deluxe'], '500 cal per sandwich (223g)'),
('chickfila_spicy_deluxe_sandwich', 'Chick-fil-A Spicy Deluxe Sandwich', 242.2, 13.9, 21.5, 10.8, 0.9, 3.6, 223, 223, 'chick-fil-a.com', ARRAY['spicy deluxe', 'spicy deluxe sandwich'], '540 cal per sandwich (223g)'),
('chickfila_grilled_chicken_sandwich', 'Chick-fil-A Grilled Chicken Sandwich', 187.5, 13.5, 21.2, 5.8, 1.4, 5.3, 208, 208, 'chick-fil-a.com', ARRAY['grilled chicken sandwich', 'grilled sandwich'], '390 cal per sandwich (208g)'),
('chickfila_nuggets_8ct', 'Chick-fil-A Nuggets (8 ct)', 221.2, 23.9, 9.7, 9.7, 0.0, 0.9, 14, 113, 'chick-fil-a.com', ARRAY['8 count nuggets', '8ct nuggets', 'chick-fil-a nuggets'], '250 cal per 8 ct (113g)'),
('chickfila_nuggets_12ct', 'Chick-fil-A Nuggets (12 ct)', 223.5, 23.5, 10.0, 10.0, 0.0, 0.6, 14, 170, 'chick-fil-a.com', ARRAY['12 count nuggets', '12ct nuggets'], '380 cal per 12 ct (170g)'),
('chickfila_grilled_nuggets_8ct', 'Chick-fil-A Grilled Nuggets (8 ct)', 115.0, 22.1, 0.9, 2.7, 0.0, 0.9, 14, 113, 'chick-fil-a.com', ARRAY['grilled nuggets', '8ct grilled nuggets'], '130 cal per 8 ct (113g)'),
('chickfila_chicken_strips_3ct', 'Chick-fil-A Chick-n-Strips (3 ct)', 258.3, 24.2, 13.3, 12.5, 0.0, 1.7, 40, 120, 'chick-fil-a.com', ARRAY['chick n strips', 'chicken strips', '3 count strips'], '310 cal per 3 ct (120g)'),
('chickfila_waffle_fries_medium', 'Chick-fil-A Waffle Potato Fries (Medium)', 336.0, 4.0, 36.8, 19.2, 4.0, 0.8, 125, 125, 'chick-fil-a.com', ARRAY['waffle fries', 'medium fries', 'waffle potato fries'], '420 cal per medium (125g)'),
('chickfila_mac_and_cheese', 'Chick-fil-A Mac & Cheese (Medium)', 198.2, 8.8, 12.3, 12.8, 1.3, 1.3, 227, 227, 'chick-fil-a.com', ARRAY['mac and cheese', 'mac n cheese'], '450 cal per medium (227g)'),
('chickfila_chicken_soup', 'Chick-fil-A Chicken Tortilla Soup (Medium)', 85.6, 6.0, 9.1, 2.5, 0.8, 0.5, 397, 397, 'chick-fil-a.com', ARRAY['chicken tortilla soup', 'chicken soup', 'tortilla soup'], '340 cal per medium (397g)'),
('chickfila_sauce', 'Chick-fil-A Sauce', 500.0, 0.0, 25.0, 46.4, 0.0, 21.4, 28, 28, 'chick-fil-a.com', ARRAY['chick fil a sauce', 'cfa sauce', 'chickfila sauce'], '140 cal per packet (28g)'),
('chickfila_polynesian_sauce', 'Chick-fil-A Polynesian Sauce', 392.9, 0.0, 46.4, 21.4, 0.0, 42.9, 28, 28, 'chick-fil-a.com', ARRAY['polynesian sauce', 'poly sauce'], '110 cal per packet (28g)'),
('chickfila_icedream_cone', 'Chick-fil-A Icedream Cone', 119.7, 3.5, 21.8, 2.8, 0.0, 16.9, 142, 142, 'chick-fil-a.com', ARRAY['icedream', 'ice cream cone', 'ice dream'], '170 cal per cone (142g)'),
('chickfila_chocolate_milkshake', 'Chick-fil-A Chocolate Milkshake', 122.4, 2.9, 18.0, 4.6, 0.2, 15.8, 482, 482, 'chick-fil-a.com', ARRAY['chocolate milkshake', 'chocolate shake'], '590 cal per serving (482g)'),
('chickfila_chicken_biscuit', 'Chick-fil-A Chicken Biscuit', 282.2, 11.7, 27.6, 14.1, 1.2, 3.7, 163, 163, 'chick-fil-a.com', ARRAY['chicken biscuit', 'breakfast chicken biscuit'], '460 cal per biscuit (163g)'),
('chickfila_chick_n_minis', 'Chick-fil-A Chick-n-Minis (4 ct)', 272.7, 15.2, 31.1, 9.8, 1.5, 6.1, 33, 132, 'chick-fil-a.com', ARRAY['chick n minis', 'chicken minis', '4 count minis'], '360 cal per 4 ct (132g)'),
('chickfila_egg_white_grill', 'Chick-fil-A Egg White Grill', 202.7, 18.2, 19.6, 5.4, 0.7, 1.4, 148, 148, 'chick-fil-a.com', ARRAY['egg white grill', 'grilled chicken egg white'], '300 cal per sandwich (148g)'),
('chickfila_cobb_salad', 'Chick-fil-A Cobb Salad', 123.3, 9.3, 6.5, 6.5, 1.2, 1.4, 430, 430, 'chick-fil-a.com', ARRAY['cobb salad', 'chickfila cobb salad'], '530 cal with toppings (430g)'),
('chickfila_frosted_lemonade', 'Chick-fil-A Frosted Lemonade', 76.8, 1.2, 15.6, 1.2, 0.0, 14.7, 482, 482, 'chick-fil-a.com', ARRAY['frosted lemonade', 'frozen lemonade'], '370 cal per serving (482g)'),
('starbucks_caffe_latte_grande', 'Starbucks Caffe Latte (Grande)', 40.2, 2.7, 4.0, 1.5, 0.0, 3.6, 473, 473, 'starbucks.com', ARRAY['latte', 'caffe latte', 'grande latte'], '190 cal per grande 16oz (473ml)'),
('starbucks_caramel_macchiato_grande', 'Starbucks Caramel Macchiato (Grande)', 52.9, 2.1, 7.4, 1.5, 0.0, 7.0, 473, 473, 'starbucks.com', ARRAY['caramel macchiato', 'caramel macc'], '250 cal per grande 16oz (473ml)'),
('starbucks_vanilla_cold_brew_grande', 'Starbucks Vanilla Sweet Cream Cold Brew (Grande)', 42.3, 0.4, 5.1, 2.1, 0.0, 5.1, 473, 473, 'starbucks.com', ARRAY['vanilla cold brew', 'sweet cream cold brew', 'vanilla sweet cream cold brew'], '200 cal per grande 16oz (473ml)'),
('starbucks_caramel_frappuccino_grande', 'Starbucks Caramel Frappuccino (Grande)', 78.2, 1.1, 11.4, 3.2, 0.0, 10.6, 473, 473, 'starbucks.com', ARRAY['caramel frappuccino', 'caramel frap', 'caramel frapp'], '370 cal per grande 16oz (473ml)'),
('starbucks_mocha_frappuccino_grande', 'Starbucks Mocha Frappuccino (Grande)', 78.2, 1.1, 11.6, 3.0, 0.2, 10.8, 473, 473, 'starbucks.com', ARRAY['mocha frappuccino', 'mocha frap', 'mocha frapp'], '370 cal per grande 16oz (473ml)'),
('starbucks_java_chip_frappuccino_grande', 'Starbucks Java Chip Frappuccino (Grande)', 93.0, 1.3, 13.3, 3.8, 0.4, 11.6, 473, 473, 'starbucks.com', ARRAY['java chip frappuccino', 'java chip frap'], '440 cal per grande 16oz (473ml)'),
('starbucks_white_chocolate_mocha_grande', 'Starbucks White Chocolate Mocha (Grande)', 90.9, 2.5, 12.5, 3.4, 0.0, 12.1, 473, 473, 'starbucks.com', ARRAY['white chocolate mocha', 'white mocha'], '430 cal per grande 16oz (473ml)'),
('starbucks_chai_tea_latte_grande', 'Starbucks Chai Tea Latte (Grande)', 50.7, 1.7, 8.9, 1.0, 0.0, 8.9, 473, 473, 'starbucks.com', ARRAY['chai latte', 'chai tea latte'], '240 cal per grande 16oz (473ml)'),
('starbucks_matcha_frappuccino_grande', 'Starbucks Matcha Creme Frappuccino (Grande)', 88.8, 1.3, 13.3, 3.4, 0.2, 12.9, 473, 473, 'starbucks.com', ARRAY['matcha frappuccino', 'matcha frap', 'green tea frappuccino'], '420 cal per grande 16oz (473ml)'),
('starbucks_pumpkin_spice_latte_grande', 'Starbucks Pumpkin Spice Latte (Grande)', 82.5, 3.0, 11.0, 3.0, 0.0, 10.6, 473, 473, 'starbucks.com', ARRAY['pumpkin spice latte', 'psl', 'pumpkin latte'], '390 cal per grande 16oz (473ml). Seasonal.'),
('starbucks_iced_white_mocha_grande', 'Starbucks Iced White Chocolate Mocha (Grande)', 88.8, 2.3, 12.9, 3.2, 0.0, 11.8, 473, 473, 'starbucks.com', ARRAY['iced white mocha', 'iced white chocolate mocha'], '420 cal per grande 16oz (473ml)'),
('starbucks_pink_drink_grande', 'Starbucks Pink Drink (Grande)', 29.6, 0.2, 5.5, 0.5, 0.2, 5.1, 473, 473, 'starbucks.com', ARRAY['pink drink', 'strawberry acai lemonade'], '140 cal per grande 16oz (473ml)'),
('starbucks_mango_dragonfruit_grande', 'Starbucks Mango Dragonfruit Lemonade (Grande)', 29.6, 0.2, 7.2, 0.0, 0.0, 6.3, 473, 473, 'starbucks.com', ARRAY['mango dragonfruit', 'dragon drink lemonade'], '140 cal per grande 16oz (473ml)'),
('starbucks_bacon_gouda_sandwich', 'Starbucks Bacon Gouda & Egg Sandwich', 268.1, 13.0, 23.2, 13.8, 0.7, 2.9, 138, 138, 'starbucks.com', ARRAY['bacon gouda', 'bacon gouda sandwich', 'bacon gouda egg sandwich'], '370 cal per sandwich (138g)'),
('starbucks_tomato_mozzarella_focaccia', 'Starbucks Tomato & Mozzarella on Focaccia', 232.3, 9.7, 30.3, 7.7, 1.3, 3.2, 155, 155, 'starbucks.com', ARRAY['tomato mozzarella', 'focaccia sandwich'], '360 cal per sandwich (155g)'),
('starbucks_egg_cheese_protein_box', 'Starbucks Egg & Cheese Protein Box', 220.7, 13.1, 8.5, 14.6, 1.9, 3.8, 213, 213, 'starbucks.com', ARRAY['protein box', 'egg cheese protein box'], '470 cal per box (213g)'),
('starbucks_chocolate_croissant', 'Starbucks Chocolate Croissant', 400.0, 7.1, 45.9, 20.0, 2.4, 17.6, 85, 85, 'starbucks.com', ARRAY['chocolate croissant', 'pain au chocolat'], '340 cal per pastry (85g)'),
('starbucks_butter_croissant', 'Starbucks Butter Croissant', 382.4, 7.4, 41.2, 20.6, 1.5, 7.4, 68, 68, 'starbucks.com', ARRAY['butter croissant', 'plain croissant', 'croissant'], '260 cal per pastry (68g)'),
('starbucks_glazed_doughnut', 'Starbucks Old Fashioned Glazed Doughnut', 424.8, 4.4, 49.6, 23.9, 0.9, 28.3, 113, 113, 'starbucks.com', ARRAY['glazed donut', 'glazed doughnut', 'old fashioned donut'], '480 cal per donut (113g)'),
('starbucks_vanilla_bean_scone', 'Starbucks Vanilla Bean Scone', 375.0, 5.5, 55.5, 14.1, 0.8, 28.9, 128, 128, 'starbucks.com', ARRAY['vanilla scone', 'vanilla bean scone'], '480 cal per scone (128g)'),
('starbucks_blueberry_muffin', 'Starbucks Blueberry Muffin', 345.1, 4.4, 50.4, 14.2, 0.9, 27.4, 113, 113, 'starbucks.com', ARRAY['blueberry muffin'], '390 cal per muffin (113g)'),
('starbucks_birthday_cake_pop', 'Starbucks Birthday Cake Pop', 404.8, 4.8, 52.4, 19.0, 0.0, 42.9, 42, 42, 'starbucks.com', ARRAY['cake pop', 'birthday cake pop'], '170 cal per pop (42g)'),
('taco_bell_chalupa_supreme', 'Taco Bell Chalupa Supreme', 261.4, 8.5, 20.3, 15.7, 1.3, 2.0, 153, 153, 'tacobell.com', ARRAY['chalupa supreme', 'beef chalupa supreme', 'chalupa'], '400 cal per chalupa (153g)'),
('taco_bell_doritos_locos_taco', 'Taco Bell Nacho Cheese Doritos Locos Tacos', 217.9, 10.3, 16.7, 11.5, 3.8, 1.3, 78, 78, 'tacobell.com', ARRAY['doritos locos taco', 'dlt', 'doritos taco', 'nacho cheese doritos locos taco'], '170 cal per taco (78g)'),
('taco_bell_doritos_locos_taco_supreme', 'Taco Bell Doritos Locos Tacos Supreme', 206.5, 8.7, 15.2, 12.0, 3.3, 1.1, 92, 92, 'tacobell.com', ARRAY['doritos locos taco supreme', 'dlt supreme', 'doritos taco supreme'], '190 cal per taco (92g)'),
('taco_bell_soft_taco', 'Taco Bell Soft Taco', 181.8, 8.1, 18.2, 9.1, 3.0, 1.0, 99, 99, 'tacobell.com', ARRAY['soft taco', 'beef soft taco'], '180 cal per taco (99g)'),
('taco_bell_crunchy_taco', 'Taco Bell Crunchy Taco', 217.9, 10.3, 16.7, 12.8, 3.8, 1.3, 78, 78, 'tacobell.com', ARRAY['crunchy taco', 'hard taco', 'beef crunchy taco'], '170 cal per taco (78g)'),
('taco_bell_crunchy_taco_supreme', 'Taco Bell Crunchy Taco Supreme', 206.5, 8.7, 15.2, 12.0, 3.3, 2.2, 92, 92, 'tacobell.com', ARRAY['crunchy taco supreme', 'hard taco supreme'], '190 cal per taco (92g)'),
('taco_bell_soft_taco_supreme', 'Taco Bell Soft Taco Supreme', 185.8, 8.0, 19.5, 8.8, 2.7, 1.8, 113, 113, 'tacobell.com', ARRAY['soft taco supreme'], '210 cal per taco (113g)'),
('taco_bell_black_bean_chalupa_supreme', 'Taco Bell Black Bean Chalupa Supreme', 215.7, 6.5, 22.2, 11.8, 3.3, 2.6, 153, 153, 'tacobell.com', ARRAY['black bean chalupa', 'black bean chalupa supreme', 'veggie chalupa'], '330 cal per chalupa (153g)'),
('taco_bell_spicy_potato_soft_taco', 'Taco Bell Spicy Potato Soft Taco', 222.2, 4.0, 27.3, 10.1, 3.0, 2.0, 99, 99, 'tacobell.com', ARRAY['spicy potato taco', 'potato soft taco'], '220 cal per taco (99g)'),
('taco_bell_doritos_cheesy_gordita_crunch', 'Taco Bell Doritos Cheesy Gordita Crunch', 306.7, 9.2, 25.2, 17.8, 2.5, 2.5, 163, 163, 'tacobell.com', ARRAY['doritos cheesy gordita crunch', 'dcgc'], '500 cal (163g)'),
('taco_bell_cheesy_gordita_crunch', 'Taco Bell Cheesy Gordita Crunch', 306.7, 9.2, 25.2, 17.8, 2.5, 2.5, 163, 163, 'tacobell.com', ARRAY['cheesy gordita crunch', 'gordita crunch'], '500 cal (163g)'),
('taco_bell_grilled_cheese_burrito', 'Taco Bell Grilled Cheese Burrito', 230.8, 8.7, 24.4, 10.9, 1.6, 1.3, 312, 312, 'tacobell.com', ARRAY['grilled cheese burrito', 'gcb'], '720 cal per burrito (312g)'),
('taco_bell_beefy_5_layer_burrito', 'Taco Bell Beefy 5-Layer Burrito', 203.3, 7.5, 26.1, 7.5, 2.5, 1.2, 241, 241, 'tacobell.com', ARRAY['beefy 5 layer', 'beefy five layer burrito', '5 layer burrito'], '490 cal per burrito (241g)'),
('taco_bell_burrito_supreme', 'Taco Bell Burrito Supreme', 153.2, 6.0, 20.2, 5.6, 2.8, 1.6, 248, 248, 'tacobell.com', ARRAY['burrito supreme'], '380 cal per burrito (248g)'),
('taco_bell_bean_burrito', 'Taco Bell Bean Burrito', 186.9, 7.1, 27.8, 5.1, 4.0, 1.5, 198, 198, 'tacobell.com', ARRAY['bean burrito'], '370 cal per burrito (198g)'),
('taco_bell_cheesy_bean_rice_burrito', 'Taco Bell Cheesy Bean and Rice Burrito', 185.0, 5.3, 25.1, 7.0, 2.2, 1.3, 227, 227, 'tacobell.com', ARRAY['cheesy bean and rice', 'cheesy bean rice burrito'], '420 cal per burrito (227g)'),
('taco_bell_black_bean_grilled_cheese_burrito', 'Taco Bell Black Bean Grilled Cheese Burrito', 208.3, 7.1, 24.7, 9.0, 2.6, 1.6, 312, 312, 'tacobell.com', ARRAY['black bean grilled cheese burrito', 'veggie grilled cheese burrito'], '650 cal per burrito (312g)'),
('taco_bell_cheesy_double_beef_burrito', 'Taco Bell Cheesy Double Beef Burrito', 198.2, 7.9, 22.5, 8.4, 1.8, 1.3, 227, 227, 'tacobell.com', ARRAY['cheesy double beef', 'cheesy double beef burrito'], '450 cal per burrito (227g)'),
('taco_bell_crunchwrap_supreme', 'Taco Bell Crunchwrap Supreme', 208.7, 5.9, 28.7, 7.9, 2.4, 2.4, 254, 254, 'tacobell.com', ARRAY['crunchwrap supreme', 'crunchwrap'], '530 cal per crunchwrap (254g)'),
('taco_bell_mexican_pizza', 'Taco Bell Mexican Pizza', 253.5, 8.9, 22.5, 14.1, 3.3, 1.4, 213, 213, 'tacobell.com', ARRAY['mexican pizza'], '540 cal per pizza (213g)'),
('taco_bell_nacho_fries', 'Taco Bell Nacho Fries', 250.0, 3.1, 32.0, 12.5, 3.1, 0.0, 128, 128, 'tacobell.com', ARRAY['nacho fries'], '320 cal per order (128g)'),
('taco_bell_cheesy_roll_up', 'Taco Bell Cheesy Roll Up', 315.8, 12.3, 26.3, 17.5, 0.0, 1.8, 57, 57, 'tacobell.com', ARRAY['cheesy roll up', 'cheese roll up'], '180 cal per roll up (57g)'),
('taco_bell_nacho_fries_large', 'Taco Bell Nacho Fries (Large)', 258.8, 2.9, 32.9, 12.9, 2.9, 0.0, 170, 170, 'tacobell.com', ARRAY['large nacho fries'], '440 cal per large (170g)'),
('taco_bell_3_cheese_chicken_flatbread', 'Taco Bell 3 Cheese Chicken Flatbread Melt', 242.2, 12.5, 23.4, 10.9, 0.8, 1.6, 128, 128, 'tacobell.com', ARRAY['3 cheese chicken flatbread', 'cheese chicken flatbread melt', 'flatbread melt'], '310 cal (128g)'),
('taco_bell_nachos_bellgrande', 'Taco Bell Nachos BellGrande', 242.6, 5.2, 26.2, 12.8, 3.0, 1.6, 305, 305, 'tacobell.com', ARRAY['nachos bellgrande', 'nachos bell grande'], '740 cal per order (305g)'),
('taco_bell_chips_nacho_cheese', 'Taco Bell Chips and Nacho Cheese Sauce', 386.0, 5.3, 43.9, 21.1, 1.8, 1.8, 57, 57, 'tacobell.com', ARRAY['chips and nacho cheese', 'chips and cheese'], '220 cal per order (57g)'),
('taco_bell_chips_guacamole', 'Taco Bell Chips and Guacamole', 294.9, 3.8, 29.5, 17.9, 5.1, 1.3, 78, 78, 'tacobell.com', ARRAY['chips and guac', 'chips and guacamole'], '230 cal per order (78g)'),
('taco_bell_cantina_chicken_bowl', 'Taco Bell Cantina Chicken Bowl', 143.6, 7.6, 14.6, 6.0, 1.8, 1.0, 397, 397, 'tacobell.com', ARRAY['cantina chicken bowl', 'chicken bowl'], '570 cal per bowl (397g)'),
('taco_bell_veggie_bowl', 'Taco Bell Veggie Bowl', 133.5, 3.8, 17.9, 5.3, 2.5, 1.0, 397, 397, 'tacobell.com', ARRAY['veggie bowl', 'vegetarian bowl'], '530 cal per bowl (397g)'),
('taco_bell_cheesy_fiesta_potatoes', 'Taco Bell Cheesy Fiesta Potatoes', 203.5, 2.7, 21.2, 12.4, 1.8, 0.9, 113, 113, 'tacobell.com', ARRAY['cheesy fiesta potatoes', 'fiesta potatoes'], '230 cal per order (113g)'),
('taco_bell_pintos_n_cheese', 'Taco Bell Pintos N Cheese', 125.0, 6.3, 15.6, 3.9, 3.9, 0.8, 128, 128, 'tacobell.com', ARRAY['pintos n cheese', 'pintos and cheese'], '160 cal per order (128g)'),
('taco_bell_black_beans_and_rice', 'Taco Bell Black Beans and Rice', 105.9, 3.5, 18.8, 1.8, 2.4, 0.6, 170, 170, 'tacobell.com', ARRAY['black beans and rice', 'beans and rice'], '180 cal per order (170g)'),
('taco_bell_black_beans', 'Taco Bell Black Beans', 87.7, 5.3, 14.0, 0.0, 5.3, 0.0, 57, 57, 'tacobell.com', ARRAY['black beans', 'side of black beans'], '50 cal per side (57g)'),
('taco_bell_crispy_chicken_nuggets_10pc', 'Taco Bell Crispy Chicken Nuggets (10 pc)', 278.8, 12.1, 21.2, 15.8, 1.2, 0.6, 16.5, 165, 'tacobell.com', ARRAY['chicken nuggets 10pc', 'crispy chicken nuggets', '10 piece nuggets'], '460 cal per 10 pc (165g)'),
('taco_bell_avocado_ranch_chicken_stacker', 'Taco Bell Avocado Ranch Chicken Stacker', 218.3, 8.5, 20.4, 11.3, 1.4, 1.4, 142, 142, 'tacobell.com', ARRAY['avocado ranch chicken stacker', 'chicken stacker'], '310 cal (142g)'),
('taco_bell_mini_taco_salad', 'Taco Bell Mini Taco Salad', 179.6, 5.6, 18.3, 9.2, 2.1, 1.4, 284, 284, 'tacobell.com', ARRAY['mini taco salad', 'taco salad'], '510 cal per salad (284g)'),
('wendys_daves_single', 'Wendy''s Dave''s Single', 233.6, 12.3, 16.4, 13.9, 1.2, 3.7, 244, 244, 'wendys.com', ARRAY['daves single', 'dave''s single', 'single burger'], '570 cal per sandwich (244g)'),
('wendys_daves_double', 'Wendy''s Dave''s Double', 250.0, 14.1, 11.8, 15.9, 0.9, 2.6, 340, 340, 'wendys.com', ARRAY['daves double', 'dave''s double', 'double burger'], '850 cal per sandwich (340g)'),
('wendys_daves_triple', 'Wendy''s Dave''s Triple', 255.8, 16.0, 9.3, 16.7, 0.7, 2.1, 430, 430, 'wendys.com', ARRAY['daves triple', 'dave''s triple', 'triple burger'], '1100 cal per sandwich (430g)'),
('wendys_baconator', 'Wendy''s Baconator', 276.2, 17.2, 11.6, 18.0, 0.6, 2.3, 344, 344, 'wendys.com', ARRAY['baconator'], '950 cal per sandwich (344g)'),
('wendys_jr_bacon_cheeseburger', 'Wendy''s Jr. Bacon Cheeseburger', 245.0, 12.6, 17.9, 13.9, 0.7, 4.0, 151, 151, 'wendys.com', ARRAY['jr bacon cheeseburger', 'junior bacon cheeseburger'], '370 cal per sandwich (151g)'),
('wendys_spicy_chicken_sandwich', 'Wendy''s Spicy Chicken Sandwich', 234.7, 13.1, 24.9, 8.9, 0.9, 2.8, 213, 213, 'wendys.com', ARRAY['spicy chicken sandwich', 'spicy chicken'], '500 cal per sandwich (213g)'),
('wendys_classic_chicken_sandwich', 'Wendy''s Classic Chicken Sandwich', 230.0, 13.1, 23.5, 9.4, 0.9, 2.3, 213, 213, 'wendys.com', ARRAY['classic chicken sandwich'], '490 cal per sandwich (213g)'),
('wendys_crispy_chicken_sandwich', 'Wendy''s Crispy Chicken Sandwich', 230.8, 9.8, 23.1, 11.2, 1.4, 2.8, 143, 143, 'wendys.com', ARRAY['crispy chicken sandwich', 'crispy chicken'], '330 cal per sandwich (143g)'),
('wendys_nuggets_10pc', 'Wendy''s Chicken Nuggets (10 pc)', 285.7, 15.0, 16.3, 18.4, 0.7, 0.0, 15, 147, 'wendys.com', ARRAY['10 piece nuggets', '10pc nuggets', 'chicken nuggets'], '420 cal per 10 pc (147g)'),
('wendys_spicy_nuggets_10pc', 'Wendy''s Spicy Chicken Nuggets (10 pc)', 292.5, 15.0, 17.7, 18.4, 1.4, 0.0, 15, 147, 'wendys.com', ARRAY['spicy nuggets 10pc', '10 piece spicy nuggets'], '430 cal per 10 pc (147g)'),
('wendys_fries_medium', 'Wendy''s Natural-Cut Fries (Medium)', 246.5, 3.5, 33.1, 11.3, 2.8, 0.0, 142, 142, 'wendys.com', ARRAY['medium fries', 'natural cut fries medium'], '350 cal per medium (142g)'),
('wendys_chili_medium', 'Wendy''s Chili (Medium)', 88.0, 6.7, 8.8, 2.8, 1.8, 2.1, 284, 284, 'wendys.com', ARRAY['chili medium', 'wendys chili'], '250 cal per medium (284g)'),
('wendys_baked_potato', 'Wendy''s Baked Potato', 95.1, 2.5, 22.2, 0.0, 2.5, 1.1, 284, 284, 'wendys.com', ARRAY['baked potato', 'plain baked potato'], '270 cal per potato (284g)'),
('wendys_baked_potato_sour_cream', 'Wendy''s Baked Potato (Sour Cream & Chive)', 99.7, 2.6, 20.3, 1.3, 2.3, 1.3, 311, 311, 'wendys.com', ARRAY['sour cream chive potato', 'loaded baked potato'], '310 cal per potato (311g)'),
('wendys_chocolate_frosty_small', 'Wendy''s Chocolate Frosty (Small)', 137.3, 3.9, 22.7, 3.5, 0.0, 18.4, 255, 255, 'wendys.com', ARRAY['chocolate frosty', 'frosty small', 'small frosty'], '350 cal per small (255g)'),
('wendys_vanilla_frosty_small', 'Wendy''s Vanilla Frosty (Small)', 133.3, 3.9, 22.0, 3.5, 0.0, 17.6, 255, 255, 'wendys.com', ARRAY['vanilla frosty', 'vanilla frosty small'], '340 cal per small (255g)'),
('wendys_apple_pecan_salad', 'Wendy''s Apple Pecan Chicken Salad (Full)', 141.1, 9.6, 13.1, 6.0, 1.8, 10.1, 397, 397, 'wendys.com', ARRAY['apple pecan salad', 'apple pecan chicken salad'], '560 cal per full salad (397g)'),
('bk_whopper', 'Burger King Whopper', 225.9, 11.5, 17.4, 12.2, 1.5, 4.1, 270, 270, 'bk.com', ARRAY['whopper', 'burger king whopper'], '610 cal per sandwich (270g)'),
('bk_whopper_cheese', 'Burger King Whopper with Cheese', 241.4, 12.1, 16.6, 13.8, 1.4, 3.8, 290, 290, 'bk.com', ARRAY['whopper with cheese', 'cheese whopper'], '700 cal per sandwich (290g)'),
('bk_double_whopper', 'Burger King Double Whopper', 227.9, 12.9, 12.6, 13.9, 1.1, 2.9, 373, 373, 'bk.com', ARRAY['double whopper'], '850 cal per sandwich (373g)'),
('bk_whopper_jr', 'Burger King Whopper Jr.', 216.8, 9.8, 20.3, 10.5, 1.4, 4.9, 143, 143, 'bk.com', ARRAY['whopper jr', 'whopper junior'], '310 cal per sandwich (143g)'),
('bk_impossible_whopper', 'Burger King Impossible Whopper', 233.3, 9.3, 21.5, 12.6, 2.6, 4.4, 270, 270, 'bk.com', ARRAY['impossible whopper', 'plant based whopper'], '630 cal per sandwich (270g)'),
('bk_bacon_cheeseburger', 'Burger King Bacon Cheeseburger', 253.8, 13.8, 20.8, 12.3, 0.8, 4.6, 130, 130, 'bk.com', ARRAY['bacon cheeseburger', 'bk bacon cheeseburger'], '330 cal per sandwich (130g)'),
('bk_cheeseburger', 'Burger King Cheeseburger', 247.8, 12.4, 23.9, 11.5, 0.9, 5.3, 113, 113, 'bk.com', ARRAY['bk cheeseburger', 'burger king cheeseburger'], '280 cal per sandwich (113g)'),
('bk_original_chicken_sandwich', 'Burger King Original Chicken Sandwich', 315.8, 10.5, 25.8, 19.1, 1.4, 2.4, 209, 209, 'bk.com', ARRAY['original chicken sandwich', 'bk chicken sandwich'], '660 cal per sandwich (209g)'),
('bk_spicy_chking', 'Burger King Spicy Ch''King', 284.6, 11.4, 30.1, 13.0, 1.2, 4.1, 246, 246, 'bk.com', ARRAY['spicy chking', 'spicy chicken king', 'ch king spicy'], '700 cal per sandwich (246g)'),
('bk_chicken_nuggets_8pc', 'Burger King Chicken Nuggets (8 pc)', 283.3, 13.3, 16.7, 17.5, 0.8, 0.0, 15, 120, 'bk.com', ARRAY['8pc chicken nuggets', 'bk nuggets'], '340 cal per 8 pc (120g)'),
('bk_french_fries_medium', 'Burger King French Fries (Medium)', 296.9, 3.9, 41.4, 13.3, 3.1, 0.0, 128, 128, 'bk.com', ARRAY['medium fries', 'bk fries medium'], '380 cal per medium (128g)'),
('bk_onion_rings_medium', 'Burger King Onion Rings (Medium)', 327.4, 4.4, 42.5, 15.9, 2.7, 3.5, 113, 113, 'bk.com', ARRAY['onion rings', 'bk onion rings', 'medium onion rings'], '370 cal per medium (113g)'),
('bk_mozzarella_sticks', 'Burger King Mozzarella Sticks (4 pc)', 352.9, 14.1, 32.9, 18.8, 2.4, 2.4, 21, 85, 'bk.com', ARRAY['mozzarella sticks', 'mozz sticks'], '300 cal per 4 pc (85g)'),
('bk_hersheys_sundae_pie', 'Burger King HERSHEY''S Sundae Pie', 392.4, 3.8, 40.5, 22.8, 1.3, 24.1, 79, 79, 'bk.com', ARRAY['hersheys pie', 'sundae pie', 'chocolate pie'], '310 cal per slice (79g)'),
('bk_vanilla_shake_medium', 'Burger King Vanilla Shake (Medium)', 143.6, 3.0, 22.9, 4.3, 0.0, 19.9, 397, 397, 'bk.com', ARRAY['vanilla shake', 'vanilla milkshake medium'], '570 cal per medium (397g)'),
('subway_6_italian_bmt', 'Subway 6" Italian B.M.T.', 175.2, 8.5, 19.7, 6.8, 1.3, 3.0, 234, 234, 'subway.com', ARRAY['italian bmt 6 inch', '6 inch italian bmt', 'italian bmt'], '410 cal per 6" sub (234g)'),
('subway_6_turkey_breast', 'Subway 6" Turkey Breast', 122.7, 8.2, 19.5, 1.6, 1.4, 2.7, 220, 220, 'subway.com', ARRAY['turkey breast 6 inch', '6 inch turkey', 'turkey sub'], '270 cal per 6" sub (220g)'),
('subway_6_subway_club', 'Subway 6" Subway Club', 128.6, 10.0, 17.8, 2.1, 1.2, 2.5, 241, 241, 'subway.com', ARRAY['subway club 6 inch', '6 inch club'], '310 cal per 6" sub (241g)'),
('subway_6_steak_cheese', 'Subway 6" Steak & Cheese', 147.3, 9.7, 17.1, 4.3, 1.2, 2.7, 258, 258, 'subway.com', ARRAY['steak and cheese 6 inch', '6 inch steak cheese', 'philly steak'], '380 cal per 6" sub (258g)'),
('subway_6_chicken_teriyaki', 'Subway 6" Sweet Onion Chicken Teriyaki', 127.9, 10.1, 17.8, 1.7, 1.2, 4.7, 258, 258, 'subway.com', ARRAY['chicken teriyaki 6 inch', 'sweet onion teriyaki', 'teriyaki sub'], '330 cal per 6" sub (258g)'),
('subway_6_meatball_marinara', 'Subway 6" Meatball Marinara', 169.0, 7.7, 19.7, 6.3, 1.8, 4.2, 284, 284, 'subway.com', ARRAY['meatball marinara 6 inch', '6 inch meatball', 'meatball sub'], '480 cal per 6" sub (284g)'),
('subway_6_tuna', 'Subway 6" Tuna', 192.3, 8.1, 18.8, 9.4, 1.3, 2.6, 234, 234, 'subway.com', ARRAY['tuna 6 inch', '6 inch tuna', 'tuna sub'], '450 cal per 6" sub (234g)'),
('subway_6_cold_cut_combo', 'Subway 6" Cold Cut Combo', 132.5, 6.8, 18.4, 4.3, 1.3, 2.6, 234, 234, 'subway.com', ARRAY['cold cut combo 6 inch', '6 inch cold cut', 'cold cut'], '310 cal per 6" sub (234g)'),
('subway_6_spicy_italian', 'Subway 6" Spicy Italian', 200.9, 8.5, 19.7, 9.8, 1.3, 3.0, 234, 234, 'subway.com', ARRAY['spicy italian 6 inch', '6 inch spicy italian'], '470 cal per 6" sub (234g)'),
('subway_6_veggie_delite', 'Subway 6" Veggie Delite', 127.4, 4.5, 24.8, 1.3, 1.9, 3.2, 157, 157, 'subway.com', ARRAY['veggie delite 6 inch', '6 inch veggie', 'veggie sub'], '200 cal per 6" sub (157g)'),
('subway_footlong_italian_bmt', 'Subway Footlong Italian B.M.T.', 175.2, 8.5, 19.7, 6.8, 1.3, 3.0, 468, 468, 'subway.com', ARRAY['footlong italian bmt', 'footlong bmt', '12 inch italian bmt'], '820 cal per footlong (468g)'),
('subway_footlong_meatball_marinara', 'Subway Footlong Meatball Marinara', 169.0, 7.7, 19.7, 6.3, 1.8, 4.2, 568, 568, 'subway.com', ARRAY['footlong meatball marinara', 'footlong meatball', '12 inch meatball'], '960 cal per footlong (568g)'),
('subway_chocolate_chip_cookie', 'Subway Chocolate Chip Cookie', 466.7, 4.4, 66.7, 22.2, 2.2, 40.0, 45, 45, 'subway.com', ARRAY['chocolate chip cookie', 'subway cookie'], '210 cal per cookie (45g)'),
('dunkin_glazed_donut', 'Dunkin'' Glazed Donut', 351.4, 4.1, 44.6, 16.2, 1.4, 16.2, 74, 74, 'dunkindonuts.com', ARRAY['glazed donut', 'dunkin glazed', 'glazed doughnut'], '260 cal per donut (74g)'),
('dunkin_chocolate_frosted_donut', 'Dunkin'' Chocolate Frosted Donut', 371.8, 3.8, 48.7, 17.9, 1.3, 23.1, 78, 78, 'dunkindonuts.com', ARRAY['chocolate frosted donut', 'chocolate donut'], '290 cal per donut (78g)'),
('dunkin_boston_kreme_donut', 'Dunkin'' Boston Kreme Donut', 282.8, 3.0, 39.4, 12.1, 1.0, 17.2, 99, 99, 'dunkindonuts.com', ARRAY['boston kreme', 'boston cream donut'], '280 cal per donut (99g)'),
('dunkin_jelly_donut', 'Dunkin'' Jelly Donut', 314.0, 3.5, 45.3, 12.8, 1.2, 16.3, 86, 86, 'dunkindonuts.com', ARRAY['jelly donut', 'jelly filled donut'], '270 cal per donut (86g)'),
('dunkin_blueberry_muffin', 'Dunkin'' Blueberry Muffin', 302.6, 3.9, 48.0, 10.5, 1.3, 25.7, 152, 152, 'dunkindonuts.com', ARRAY['blueberry muffin', 'dunkin muffin'], '460 cal per muffin (152g)'),
('dunkin_everything_bagel', 'Dunkin'' Everything Bagel', 286.9, 10.7, 52.5, 4.1, 2.5, 4.9, 122, 122, 'dunkindonuts.com', ARRAY['everything bagel', 'dunkin bagel'], '350 cal per bagel (122g)'),
('dunkin_plain_bagel', 'Dunkin'' Plain Bagel', 268.9, 10.1, 54.6, 1.7, 2.5, 5.0, 119, 119, 'dunkindonuts.com', ARRAY['plain bagel'], '320 cal per bagel (119g)'),
('dunkin_bacon_egg_cheese_croissant', 'Dunkin'' Bacon Egg & Cheese on Croissant', 317.9, 11.0, 24.3, 19.1, 0.6, 3.5, 173, 173, 'dunkindonuts.com', ARRAY['bacon egg cheese croissant', 'bec croissant'], '550 cal per sandwich (173g)'),
('dunkin_sausage_egg_cheese_croissant', 'Dunkin'' Sausage Egg & Cheese on Croissant', 338.5, 10.9, 21.9, 21.9, 0.5, 3.1, 192, 192, 'dunkindonuts.com', ARRAY['sausage egg cheese croissant', 'sec croissant'], '650 cal per sandwich (192g)'),
('dunkin_bec_english_muffin', 'Dunkin'' Bacon Egg & Cheese on English Muffin', 244.9, 12.2, 22.4, 11.6, 0.7, 2.0, 147, 147, 'dunkindonuts.com', ARRAY['bacon egg cheese english muffin', 'bec muffin'], '360 cal per sandwich (147g)'),
('dunkin_hash_browns', 'Dunkin'' Hash Browns (6 pc)', 385.4, 3.1, 39.6, 24.0, 3.1, 0.0, 16, 96, 'dunkindonuts.com', ARRAY['hash browns', 'dunkin hash browns', '6 piece hash browns'], '370 cal per 6 pc (96g)'),
('dunkin_iced_coffee_medium', 'Dunkin'' Medium Iced Coffee (Cream & Sugar)', 38.2, 0.3, 7.2, 0.9, 0.0, 7.2, 680, 680, 'dunkindonuts.com', ARRAY['iced coffee', 'medium iced coffee', 'dunkin iced coffee'], '260 cal per medium 24oz (680ml)'),
('dunkin_latte_medium', 'Dunkin'' Latte (Medium)', 42.8, 2.8, 4.3, 1.8, 0.0, 4.0, 397, 397, 'dunkindonuts.com', ARRAY['latte', 'dunkin latte', 'medium latte'], '170 cal per medium (397g)'),
('dunkin_caramel_swirl_latte', 'Dunkin'' Caramel Swirl Latte (Medium)', 78.1, 2.8, 12.8, 1.8, 0.0, 11.6, 397, 397, 'dunkindonuts.com', ARRAY['caramel swirl latte', 'caramel latte'], '310 cal per medium (397g)'),
('dunkin_frozen_coffee_medium', 'Dunkin'' Frozen Coffee (Medium)', 61.8, 0.4, 11.2, 1.6, 0.1, 10.6, 680, 680, 'dunkindonuts.com', ARRAY['frozen coffee', 'dunkin frozen coffee'], '420 cal per medium 24oz (680ml)'),
('dunkin_charli_cold_brew', 'Dunkin'' Charli Cold Brew (Medium)', 48.5, 0.4, 9.3, 0.9, 0.0, 9.3, 680, 680, 'dunkindonuts.com', ARRAY['charli cold brew', 'charli drink', 'the charli'], '330 cal per medium 24oz (680ml)'),
('dominos_cheese_pizza_large_slice', 'Domino''s Hand Tossed Cheese Pizza (Large Slice)', 247.8, 10.6, 31.9, 8.8, 1.8, 2.7, 113, 113, 'dominos.com', ARRAY['cheese pizza slice', 'large cheese pizza slice', 'dominos cheese pizza'], '280 cal per slice (113g). Large 14" 1/8 pizza.'),
('dominos_pepperoni_pizza_large_slice', 'Domino''s Hand Tossed Pepperoni Pizza (Large Slice)', 265.5, 11.5, 31.9, 10.6, 1.8, 2.7, 113, 113, 'dominos.com', ARRAY['pepperoni pizza slice', 'large pepperoni pizza slice', 'dominos pepperoni'], '300 cal per slice (113g). Large 14" 1/8 pizza.'),
('dominos_meatzza_pizza_large_slice', 'Domino''s MeatZZa Pizza (Large Slice)', 265.6, 12.5, 27.3, 12.5, 1.6, 2.3, 128, 128, 'dominos.com', ARRAY['meatzza pizza', 'meatzza slice', 'meat lovers pizza'], '340 cal per slice (128g). Large 14" 1/8 pizza.'),
('dominos_deluxe_pizza_large_slice', 'Domino''s Deluxe Pizza (Large Slice)', 243.9, 9.8, 28.5, 10.6, 1.6, 2.4, 123, 123, 'dominos.com', ARRAY['deluxe pizza slice', 'dominos deluxe'], '300 cal per slice (123g). Large 14" 1/8 pizza.'),
('dominos_bbq_chicken_pizza_large_slice', 'Domino''s BBQ Chicken Pizza (Large Slice)', 235.8, 11.4, 31.7, 7.3, 0.8, 6.5, 123, 123, 'dominos.com', ARRAY['bbq chicken pizza', 'bbq chicken slice'], '290 cal per slice (123g). Large 14" 1/8 pizza.'),
('dominos_cheese_pizza_medium_slice', 'Domino''s Hand Tossed Cheese Pizza (Medium Slice)', 247.1, 10.6, 31.8, 8.8, 1.2, 2.4, 85, 85, 'dominos.com', ARRAY['medium cheese pizza slice', 'medium cheese slice'], '210 cal per slice (85g). Medium 12" 1/8 pizza.'),
('dominos_stuffed_cheesy_bread', 'Domino''s Stuffed Cheesy Bread (1 piece)', 315.8, 13.2, 31.6, 15.8, 2.6, 2.6, 38, 38, 'dominos.com', ARRAY['stuffed cheesy bread', 'cheesy bread'], '120 cal per piece (38g). 8 pieces per order.'),
('dominos_boneless_wings_8pc', 'Domino''s Boneless Chicken Wings (8 pc)', 307.0, 14.0, 28.9, 14.9, 1.3, 1.8, 28, 228, 'dominos.com', ARRAY['boneless wings', 'boneless chicken', 'dominos boneless wings'], '700 cal per 8 pc (228g). Without dipping sauce.'),
('dominos_bread_twists', 'Domino''s Bread Twists (2 pc)', 350.9, 8.8, 47.4, 14.0, 1.8, 3.5, 28, 57, 'dominos.com', ARRAY['bread twists', 'garlic bread twists'], '200 cal per 2 pc (57g). Served with marinara sauce.'),
('dominos_chicken_alfredo_pasta', 'Domino''s Chicken Alfredo Pasta', 151.1, 6.5, 14.1, 7.6, 0.8, 1.0, 397, 397, 'dominos.com', ARRAY['chicken alfredo pasta', 'alfredo pasta', 'pasta in a dish'], '600 cal per order (397g)'),
('dominos_sausage_marinara_pasta', 'Domino''s Italian Sausage Marinara Pasta', 141.1, 5.8, 17.6, 5.3, 1.3, 2.0, 397, 397, 'dominos.com', ARRAY['sausage marinara pasta', 'marinara pasta'], '560 cal per order (397g)'),
('dominos_cinnamon_bread_twists', 'Domino''s Cinnamon Bread Twists (2 pc)', 438.6, 5.3, 59.6, 19.3, 1.8, 19.3, 57, 57, 'dominos.com', ARRAY['cinnamon twists', 'cinnamon bread twists'], '250 cal per 2 pc (57g). With sweet icing.'),
('dominos_marbled_cookie_brownie', 'Domino''s Marbled Cookie Brownie (1 pc)', 392.2, 3.9, 54.9, 17.6, 2.0, 33.3, 51, 51, 'dominos.com', ARRAY['cookie brownie', 'marbled brownie', 'brownie'], '200 cal per piece (51g). 9 pc per order.'),
('popeyes_chicken_sandwich', 'Popeyes Classic Chicken Sandwich', 350.0, 14.0, 25.0, 21.0, 1.0, 4.0, 200, 200, 'popeyes.com', ARRAY['chicken sandwich', 'popeyes sandwich', 'classic chicken sandwich'], '700 cal per sandwich (200g)'),
('popeyes_spicy_chicken_sandwich', 'Popeyes Spicy Chicken Sandwich', 350.0, 14.0, 25.0, 21.0, 1.0, 4.0, 200, 200, 'popeyes.com', ARRAY['spicy sandwich', 'spicy chicken sandwich'], '700 cal per sandwich (200g)'),
('popeyes_tenders_3pc', 'Popeyes Chicken Tenders (3 pc)', 267.7, 27.6, 12.6, 11.0, 0.8, 0.0, 42, 127, 'popeyes.com', ARRAY['3 piece tenders', 'chicken tenders', '3pc tenders'], '340 cal per 3 pc (127g)'),
('popeyes_tenders_5pc', 'Popeyes Chicken Tenders (5 pc)', 268.9, 27.4, 12.7, 10.8, 0.9, 0.0, 42, 212, 'popeyes.com', ARRAY['5 piece tenders', '5pc tenders'], '570 cal per 5 pc (212g)'),
('popeyes_2pc_chicken_breast_wing', 'Popeyes 2 pc Chicken (Breast & Wing)', 247.2, 19.7, 9.0, 14.6, 0.6, 0.0, 178, 178, 'popeyes.com', ARRAY['2 piece chicken', '2pc breast wing'], '440 cal per 2 pc (178g)'),
('popeyes_2pc_chicken_leg_thigh', 'Popeyes 2 pc Chicken (Leg & Thigh)', 230.3, 14.5, 9.2, 14.5, 0.7, 0.0, 152, 152, 'popeyes.com', ARRAY['2 piece leg thigh', '2pc dark meat'], '350 cal per 2 pc (152g)'),
('popeyes_chicken_breast', 'Popeyes Chicken Breast', 218.8, 18.8, 7.8, 12.5, 0.0, 0.0, 128, 128, 'popeyes.com', ARRAY['chicken breast', 'breast piece'], '280 cal per breast (128g)'),
('popeyes_chicken_leg', 'Popeyes Chicken Leg', 222.2, 19.4, 6.9, 12.5, 0.0, 0.0, 72, 72, 'popeyes.com', ARRAY['chicken leg', 'drumstick'], '160 cal per leg (72g)'),
('popeyes_chicken_thigh', 'Popeyes Chicken Thigh', 232.3, 14.1, 9.1, 15.2, 1.0, 0.0, 99, 99, 'popeyes.com', ARRAY['chicken thigh', 'thigh piece'], '230 cal per thigh (99g)'),
('popeyes_chicken_wing', 'Popeyes Chicken Wing', 263.2, 17.5, 8.8, 17.5, 0.0, 0.0, 57, 57, 'popeyes.com', ARRAY['chicken wing', 'wing piece'], '150 cal per wing (57g)'),
('popeyes_biscuit', 'Popeyes Biscuit', 350.9, 5.3, 40.4, 19.3, 1.8, 3.5, 57, 57, 'popeyes.com', ARRAY['biscuit', 'popeyes biscuit', 'buttermilk biscuit'], '200 cal per biscuit (57g)'),
('popeyes_cajun_fries_regular', 'Popeyes Cajun Fries (Regular)', 262.6, 3.0, 31.3, 14.1, 3.0, 0.0, 99, 99, 'popeyes.com', ARRAY['cajun fries', 'regular fries', 'popeyes fries'], '260 cal per regular (99g)'),
('popeyes_cajun_fries_large', 'Popeyes Cajun Fries (Large)', 276.5, 2.9, 33.5, 14.7, 2.9, 0.0, 170, 170, 'popeyes.com', ARRAY['large cajun fries', 'large fries'], '470 cal per large (170g)'),
('popeyes_red_beans_rice', 'Popeyes Red Beans & Rice (Regular)', 162.0, 5.6, 23.9, 4.2, 4.2, 0.7, 142, 142, 'popeyes.com', ARRAY['red beans and rice', 'red beans rice'], '230 cal per regular (142g)'),
('popeyes_mashed_potatoes_gravy', 'Popeyes Mashed Potatoes & Gravy (Regular)', 77.5, 0.7, 12.7, 2.8, 1.4, 0.7, 142, 142, 'popeyes.com', ARRAY['mashed potatoes', 'mashed potatoes and gravy'], '110 cal per regular (142g)'),
('popeyes_coleslaw', 'Popeyes Coleslaw (Regular)', 156.3, 0.8, 13.3, 11.7, 1.6, 10.2, 128, 128, 'popeyes.com', ARRAY['coleslaw', 'cole slaw'], '200 cal per regular (128g)'),
('popeyes_mac_and_cheese', 'Popeyes Mac & Cheese (Regular)', 239.4, 9.9, 19.7, 13.4, 0.7, 2.8, 142, 142, 'popeyes.com', ARRAY['mac and cheese', 'mac n cheese', 'macaroni and cheese'], '340 cal per regular (142g)'),
('popeyes_cajun_rice', 'Popeyes Cajun Rice (Regular)', 150.4, 6.2, 22.1, 4.4, 0.9, 0.0, 113, 113, 'popeyes.com', ARRAY['cajun rice'], '170 cal per regular (113g)'),
('popeyes_apple_pie', 'Popeyes Cinnamon Apple Pie', 270.6, 3.5, 36.5, 12.9, 1.2, 16.5, 85, 85, 'popeyes.com', ARRAY['apple pie', 'cinnamon apple pie'], '230 cal per pie (85g)'),
-- =============================================
-- BATCH 2: Restaurant Nutrition Data
-- Pizza Hut, KFC, Chipotle, Sonic Drive-In,
-- Panera Bread, Jack in the Box, Whataburger,
-- Panda Express, Five Guys, Raising Cane's
-- =============================================
-- Format: (food_name_normalized, display_name, cal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, piece_weight_g, serving_g, source_url, variant_names, notes)
-- All values per 100g. Micronutrients in notes JSON.
-- =============================================
-- =============================================
-- 1. PIZZA HUT
-- Source: pizzahut.com, fastfoodnutrition.org
-- =============================================
-- Pizza Hut Hand-Tossed Pepperoni Pizza (Medium) - 1 slice ~107g
-- 230 cal, 10g fat, 9g protein, 25g carbs, 2g fiber, 1g sugar, 540mg sodium, 25mg chol, 4g sat fat
-- Pizza Hut Hand-Tossed Cheese Pizza (Medium) - 1 slice ~98g
-- 210 cal, 8g fat, 9g protein, 26g carbs, 2g fiber, 1g sugar, 460mg sodium, 20mg chol, 4g sat fat
-- Pizza Hut Hand-Tossed Supreme Pizza (Medium) - 1 slice ~128g
-- 260 cal, 12g fat, 10g protein, 27g carbs, 2g fiber, 1g sugar, 570mg sodium, 30mg chol, 5g sat fat
-- Pizza Hut Hand-Tossed Meat Lovers Pizza (Medium) - 1 slice ~131g
-- 300 cal, 16g fat, 12g protein, 26g carbs, 2g fiber, 1g sugar, 740mg sodium, 40mg chol, 6g sat fat
-- Pizza Hut Hand-Tossed Veggie Lovers Pizza (Medium) - 1 slice ~118g
-- 200 cal, 7g fat, 8g protein, 27g carbs, 2g fiber, 1g sugar, 430mg sodium, 15mg chol, 3g sat fat
-- Pizza Hut Pan Cheese Pizza (Medium) - 1 slice 110g
-- 290 cal, 14g fat, 12g protein, 28g carbs, 2g fiber, 1g sugar, 590mg sodium, 10mg chol, 6g sat fat
-- Pizza Hut Pan Pepperoni Pizza (Medium) - 1 slice ~110g
-- 250 cal, 12g fat, 9g protein, 26g carbs, 1g fiber, 2g sugar, 590mg sodium, 25mg chol, 4.5g sat fat
-- Pizza Hut Pan Supreme Pizza (Medium) - 1 slice ~130g
-- 280 cal, 14g fat, 11g protein, 27g carbs, 2g fiber, 2g sugar, 630mg sodium, 25mg chol, 5g sat fat
-- Pizza Hut Pan Meat Lovers Pizza (Medium) - 1 slice ~135g
-- 340 cal, 19g fat, 14g protein, 26g carbs, 2g fiber, 2g sugar, 780mg sodium, 40mg chol, 7g sat fat
-- Pizza Hut Stuffed Crust Pepperoni (Large) - 1 slice ~150g
-- 380 cal, 18g fat, 16g protein, 39g carbs, 2g fiber, 3g sugar, 1060mg sodium, 45mg chol, 9g sat fat
-- Pizza Hut Stuffed Crust Cheese (Large) - 1 slice ~145g
-- 340 cal, 14g fat, 16g protein, 38g carbs, 2g fiber, 3g sugar, 900mg sodium, 35mg chol, 7g sat fat
-- Pizza Hut Thin N Crispy Pepperoni (Medium) - 1 slice ~80g
-- 200 cal, 10g fat, 8g protein, 19g carbs, 1g fiber, 1g sugar, 490mg sodium, 25mg chol, 4g sat fat
-- Pizza Hut Hand-Tossed BBQ Chicken Pizza (Medium) - 1 slice ~120g
-- 230 cal, 6g fat, 12g protein, 32g carbs, 1g fiber, 8g sugar, 580mg sodium, 30mg chol, 2.5g sat fat
-- Pizza Hut Hand-Tossed Hawaiian Pizza (Medium) - 1 slice ~118g
-- 220 cal, 7g fat, 10g protein, 28g carbs, 1g fiber, 5g sugar, 530mg sodium, 25mg chol, 3g sat fat
-- Pizza Hut Traditional Bone-In Wings (naked, per wing) - 1 wing ~30g
-- 80 cal, 4.5g fat, 9g protein, 0g carbs, 0g fiber, 0g sugar, 240mg sodium, 45mg chol, 1.5g sat fat
-- Pizza Hut Buffalo Bone-In Wings (per wing) - 1 wing ~33g
-- 100 cal, 6g fat, 9g protein, 2g carbs, 0g fiber, 0g sugar, 410mg sodium, 45mg chol, 2g sat fat
-- Pizza Hut Garlic Parmesan Bone-In Wings (per wing) - 1 wing ~34g
-- 110 cal, 8g fat, 9g protein, 2g carbs, 0g fiber, 0g sugar, 290mg sodium, 45mg chol, 2g sat fat
-- Pizza Hut Boneless Wings (per wing) ~25g
-- 80 cal, 4g fat, 4g protein, 7g carbs, 0g fiber, 0g sugar, 200mg sodium, 10mg chol, 1g sat fat
-- Pizza Hut Breadstick with Cheese - 1 stick 56g
-- 170 cal, 6g fat, 8g protein, 20g carbs, 1g fiber, 2g sugar, 390mg sodium, 15mg chol, 2.5g sat fat
-- Pizza Hut Tuscani Creamy Chicken Alfredo Pasta ~380g
-- 630 cal, 24g fat, 27g protein, 76g carbs, 4g fiber, 4g sugar, 1180mg sodium, 60mg chol, 9g sat fat
-- Pizza Hut Tuscani Meaty Marinara Pasta ~390g
-- 620 cal, 24g fat, 26g protein, 72g carbs, 5g fiber, 8g sugar, 1440mg sodium, 60mg chol, 8g sat fat
-- Pizza Hut Cinnamon Sticks (2 sticks) ~55g
-- 160 cal, 5g fat, 3g protein, 26g carbs, 1g fiber, 9g sugar, 150mg sodium, 0mg chol, 1.5g sat fat
-- Pizza Hut Cinnabon Mini Rolls ~270g
-- 830 cal, 33g fat, 11g protein, 124g carbs, 3g fiber, 64g sugar, 630mg sodium, 35mg chol, 14g sat fat
-- =============================================
-- 2. KFC
-- Source: kfc.com, fastfoodnutrition.org
-- =============================================
-- KFC Original Recipe Chicken Breast - 1 breast ~161g
-- 390 cal, 21g fat, 39g protein, 11g carbs, 2g fiber, 0g sugar, 1190mg sodium, 120mg chol, 4g sat fat
-- KFC Original Recipe Chicken Thigh - 1 thigh ~91g
-- 280 cal, 19g fat, 19g protein, 8g carbs, 1g fiber, 0g sugar, 910mg sodium, 100mg chol, 4.5g sat fat
-- KFC Original Recipe Chicken Drumstick - 1 drumstick ~56g
-- 130 cal, 8g fat, 12g protein, 4g carbs, 1g fiber, 0g sugar, 430mg sodium, 55mg chol, 1.5g sat fat
-- KFC Original Recipe Chicken Wing - 1 wing ~48g
-- 120 cal, 8g fat, 9g protein, 4g carbs, 0g fiber, 0g sugar, 350mg sodium, 45mg chol, 1.5g sat fat
-- KFC Extra Crispy Chicken Breast - 1 breast ~168g
-- 530 cal, 35g fat, 35g protein, 18g carbs, 0g fiber, 1g sugar, 1150mg sodium, 105mg chol, 6g sat fat
-- KFC Extra Crispy Chicken Thigh - 1 thigh ~114g
-- 290 cal, 20g fat, 17g protein, 11g carbs, 0g fiber, 0g sugar, 660mg sodium, 70mg chol, 4g sat fat
-- KFC Extra Crispy Chicken Drumstick - 1 drumstick ~60g
-- 170 cal, 10g fat, 12g protein, 6g carbs, 0g fiber, 0g sugar, 350mg sodium, 45mg chol, 2g sat fat
-- KFC Chicken Sandwich - 1 sandwich ~207g
-- 650 cal, 34g fat, 28g protein, 56g carbs, 2g fiber, 8g sugar, 1640mg sodium, 60mg chol, 6g sat fat
-- KFC Famous Bowl - 1 bowl ~397g
-- 740 cal, 35g fat, 26g protein, 81g carbs, 6g fiber, 2g sugar, 2350mg sodium, 45mg chol, 6g sat fat
-- KFC Chicken Pot Pie - 1 pie ~322g
-- 720 cal, 41g fat, 26g protein, 60g carbs, 7g fiber, 5g sugar, 1750mg sodium, 80mg chol, 25g sat fat
-- KFC Mac & Cheese (individual) - 1 serving ~136g
-- 170 cal, 8g fat, 7g protein, 17g carbs, 0g fiber, 2g sugar, 720mg sodium, 20mg chol, 3g sat fat
-- KFC Mashed Potatoes with Gravy - 1 serving ~153g
-- 130 cal, 5g fat, 2g protein, 19g carbs, 1g fiber, 0g sugar, 510mg sodium, 0mg chol, 1g sat fat
-- KFC Coleslaw - 1 serving ~128g
-- 170 cal, 10g fat, 1g protein, 21g carbs, 3g fiber, 14g sugar, 180mg sodium, 5mg chol, 1.5g sat fat
-- KFC Corn on the Cob - 1 ear ~162g
-- 70 cal, 0.5g fat, 2g protein, 16g carbs, 2g fiber, 4g sugar, 0mg sodium, 0mg chol, 0g sat fat
-- KFC Green Beans - 1 serving ~86g
-- 25 cal, 0g fat, 1g protein, 4g carbs, 2g fiber, 1g sugar, 280mg sodium, 0mg chol, 0g sat fat
-- KFC Biscuit - 1 biscuit ~56g
-- 180 cal, 8g fat, 4g protein, 22g carbs, 1g fiber, 2g sugar, 530mg sodium, 0mg chol, 4g sat fat
-- KFC Chicken Tenders (3 pc) - 3 tenders ~130g
-- 370 cal, 19g fat, 27g protein, 22g carbs, 0g fiber, 0g sugar, 1020mg sodium, 55mg chol, 3g sat fat
-- KFC Chicken Nuggets (8 pc) - 8 nuggets ~128g
-- 340 cal, 20g fat, 17g protein, 22g carbs, 0g fiber, 0g sugar, 790mg sodium, 40mg chol, 3.5g sat fat
-- KFC Spicy Chicken Sandwich - 1 sandwich ~215g
-- 700 cal, 37g fat, 29g protein, 58g carbs, 3g fiber, 8g sugar, 1830mg sodium, 65mg chol, 7g sat fat
-- KFC Chocolate Chip Cookie - 1 cookie ~35g
-- 160 cal, 8g fat, 2g protein, 22g carbs, 1g fiber, 13g sugar, 120mg sodium, 10mg chol, 4g sat fat
-- =============================================
-- 3. CHIPOTLE (expanding beyond existing 5 items)
-- Source: chipotle.com, fastfoodnutrition.org
-- Existing: burrito_bowl_chicken, chips_guac, chips_queso, chicken_tacos, red_chimichurri
-- =============================================
-- Chipotle Chicken Burrito - full burrito ~480g (tortilla+chicken+rice+beans+salsa)
-- 480 cal, 16g fat, 39g protein, 45g carbs, 2g fiber, 1g sugar, 1040mg sodium, 115mg chol, 5g sat fat
-- Chipotle Steak Burrito Bowl - full bowl ~500g
-- 630 cal, 22g fat, 40g protein, 72g carbs, 9g fiber, 5g sugar, 1530mg sodium, 80mg chol, 6g sat fat
-- Chipotle Barbacoa Bowl - full bowl ~500g
-- 645 cal, 23g fat, 40g protein, 72g carbs, 10g fiber, 5g sugar, 1740mg sodium, 85mg chol, 7g sat fat
-- Chipotle Sofritas Bowl - full bowl ~490g
-- 555 cal, 17g fat, 19g protein, 74g carbs, 11g fiber, 6g sugar, 1360mg sodium, 0mg chol, 3g sat fat
-- Chipotle Carnitas Burrito - full burrito ~500g
-- 570 cal, 20g fat, 35g protein, 60g carbs, 7g fiber, 3g sugar, 1540mg sodium, 85mg chol, 7g sat fat
-- Chipotle Steak Tacos (3 soft corn tacos) ~300g
-- 525 cal, 18g fat, 30g protein, 57g carbs, 6g fiber, 3g sugar, 1080mg sodium, 65mg chol, 5g sat fat
-- Chipotle Chicken Quesadilla ~290g
-- 750 cal, 37g fat, 46g protein, 54g carbs, 3g fiber, 2g sugar, 1640mg sodium, 140mg chol, 17g sat fat
-- Chipotle White Rice (side) ~130g
-- 210 cal, 4g fat, 3g protein, 40g carbs, 0g fiber, 0g sugar, 280mg sodium, 0mg chol, 0.5g sat fat
-- Chipotle Brown Rice (side) ~130g
-- 210 cal, 5g fat, 4g protein, 36g carbs, 2g fiber, 0g sugar, 230mg sodium, 0mg chol, 0.5g sat fat
-- Chipotle Black Beans (side) ~130g
-- 130 cal, 1g fat, 8g protein, 22g carbs, 7g fiber, 1g sugar, 210mg sodium, 0mg chol, 0g sat fat
-- Chipotle Pinto Beans (side) ~130g
-- 130 cal, 1g fat, 8g protein, 22g carbs, 7g fiber, 0g sugar, 310mg sodium, 5mg chol, 0g sat fat
-- Chipotle Chicken (protein only) ~113g (4oz)
-- 180 cal, 7g fat, 32g protein, 0g carbs, 0g fiber, 0g sugar, 530mg sodium, 95mg chol, 2g sat fat
-- Chipotle Steak (protein only) ~113g (4oz)
-- 150 cal, 6g fat, 21g protein, 1g carbs, 0g fiber, 0g sugar, 390mg sodium, 65mg chol, 2g sat fat
-- Chipotle Guacamole (side) ~100g
-- 230 cal, 22g fat, 2g protein, 8g carbs, 6g fiber, 1g sugar, 330mg sodium, 0mg chol, 3g sat fat
-- Chipotle Queso Blanco (side) ~57g (2oz)
-- 120 cal, 9g fat, 5g protein, 4g carbs, 0g fiber, 1g sugar, 260mg sodium, 20mg chol, 5g sat fat
-- Chipotle Fresh Tomato Salsa ~112g (4oz)
-- 25 cal, 0g fat, 1g protein, 4g carbs, 1g fiber, 2g sugar, 510mg sodium, 0mg chol, 0g sat fat
-- Chipotle Sour Cream ~57g (2oz)
-- 110 cal, 9g fat, 2g protein, 2g carbs, 0g fiber, 1g sugar, 30mg sodium, 35mg chol, 6g sat fat
-- Chipotle Cheese (shredded) ~28g (1oz)
-- 110 cal, 9g fat, 6g protein, 1g carbs, 0g fiber, 0g sugar, 150mg sodium, 25mg chol, 5g sat fat
-- Chipotle Tortilla Chips (side) ~115g (4oz)
-- 540 cal, 26g fat, 7g protein, 68g carbs, 5g fiber, 1g sugar, 320mg sodium, 0mg chol, 3.5g sat fat
-- =============================================
-- 4. SONIC DRIVE-IN
-- Source: sonicdrivein.com, fastfoodnutrition.org
-- =============================================
-- Sonic Jr. Burger - 1 burger 127g
-- 340 cal, 17g fat, 15g protein, 34g carbs, 1g fiber, 6g sugar, 640mg sodium, 35mg chol, 6g sat fat, 1g trans fat
-- Sonic Cheeseburger (w/ mustard) - 1 burger ~213g
-- 590 cal, 31g fat, 27g protein, 49g carbs, 2g fiber, 10g sugar, 1230mg sodium, 80mg chol, 13g sat fat
-- Sonic Burger (w/ mayo) - 1 burger ~200g
-- 620 cal, 34g fat, 27g protein, 49g carbs, 2g fiber, 10g sugar, 1080mg sodium, 70mg chol, 11g sat fat
-- SuperSONIC Bacon Double Cheeseburger - 1 burger ~348g
-- 1130 cal, 75g fat, 57g protein, 54g carbs, 3g fiber, 12g sugar, 2050mg sodium, 195mg chol, 30g sat fat
-- Sonic Chili Cheese Coney (6") - 1 hot dog ~175g
-- 470 cal, 29g fat, 18g protein, 34g carbs, 2g fiber, 4g sugar, 1240mg sodium, 55mg chol, 12g sat fat
-- Sonic All-American Hot Dog - 1 hot dog ~120g
-- 340 cal, 21g fat, 11g protein, 26g carbs, 1g fiber, 5g sugar, 930mg sodium, 40mg chol, 8g sat fat
-- Sonic Corn Dog - 1 corn dog ~75g
-- 230 cal, 13g fat, 7g protein, 23g carbs, 1g fiber, 6g sugar, 560mg sodium, 20mg chol, 4g sat fat
-- Sonic Crispy Chicken Sandwich - 1 sandwich ~195g
-- 530 cal, 27g fat, 20g protein, 52g carbs, 2g fiber, 9g sugar, 1190mg sodium, 35mg chol, 5g sat fat
-- Sonic Grilled Chicken Sandwich - 1 sandwich ~195g
-- 440 cal, 18g fat, 33g protein, 37g carbs, 2g fiber, 8g sugar, 1060mg sodium, 90mg chol, 4g sat fat
-- Sonic French Fries (medium) - 1 serving ~120g
-- 360 cal, 17g fat, 4g protein, 48g carbs, 3g fiber, 0g sugar, 540mg sodium, 0mg chol, 2.5g sat fat
-- Sonic Onion Rings (medium) - 1 serving ~155g
-- 480 cal, 28g fat, 6g protein, 52g carbs, 3g fiber, 5g sugar, 660mg sodium, 0mg chol, 5g sat fat
-- Sonic Tater Tots (medium) - 1 serving ~120g
-- 390 cal, 21g fat, 3g protein, 46g carbs, 3g fiber, 0g sugar, 680mg sodium, 0mg chol, 3.5g sat fat
-- Sonic Mozzarella Sticks (6pc) - 1 serving ~100g
-- 370 cal, 21g fat, 14g protein, 31g carbs, 2g fiber, 2g sugar, 890mg sodium, 30mg chol, 8g sat fat
-- Sonic Breakfast Burrito (Sausage) - 1 burrito ~200g
-- 500 cal, 29g fat, 18g protein, 39g carbs, 2g fiber, 3g sugar, 1170mg sodium, 175mg chol, 10g sat fat
-- Sonic CroisSONIC Breakfast Sandwich (bacon) - 1 sandwich ~185g
-- 510 cal, 32g fat, 20g protein, 35g carbs, 1g fiber, 5g sugar, 1000mg sodium, 195mg chol, 13g sat fat
-- Sonic Vanilla Shake (medium) ~420g
-- 540 cal, 18g fat, 10g protein, 87g carbs, 0g fiber, 72g sugar, 370mg sodium, 60mg chol, 12g sat fat
-- Sonic Chocolate Shake (medium) ~430g
-- 580 cal, 18g fat, 10g protein, 95g carbs, 1g fiber, 79g sugar, 420mg sodium, 60mg chol, 12g sat fat
-- Sonic Classic Limeade (medium) ~450g
-- 200 cal, 0g fat, 0g protein, 53g carbs, 0g fiber, 51g sugar, 40mg sodium, 0mg chol, 0g sat fat
-- Sonic Ocean Water (medium) ~450g
-- 200 cal, 0g fat, 0g protein, 51g carbs, 0g fiber, 51g sugar, 35mg sodium, 0mg chol, 0g sat fat
-- =============================================
-- 5. PANERA BREAD
-- Source: panerabread.com, fastfoodnutrition.org
-- =============================================
-- Panera Broccoli Cheddar Soup (bowl) ~350g
-- 360 cal, 21g fat, 14g protein, 28g carbs, 3g fiber, 6g sugar, 1090mg sodium, 55mg chol, 12g sat fat
-- Panera Broccoli Cheddar Soup (cup) ~240g
-- 230 cal, 13g fat, 9g protein, 18g carbs, 2g fiber, 4g sugar, 700mg sodium, 35mg chol, 8g sat fat
-- Panera Broccoli Cheddar Soup (bread bowl) ~530g
-- 900 cal, 18g fat, 35g protein, 134g carbs, 8g fiber, 10g sugar, 1880mg sodium, 60mg chol, 14g sat fat
-- Panera Chicken Noodle Soup (cup) ~240g
-- 130 cal, 4g fat, 12g protein, 13g carbs, 0g fiber, 4g sugar, 960mg sodium, 40mg chol, 1g sat fat
-- Panera Chicken Noodle Soup (bowl) ~350g
-- 200 cal, 6g fat, 18g protein, 19g carbs, 1g fiber, 6g sugar, 1480mg sodium, 60mg chol, 1.5g sat fat
-- Panera Creamy Tomato Soup (cup) ~240g
-- 270 cal, 17g fat, 4g protein, 26g carbs, 2g fiber, 13g sugar, 820mg sodium, 35mg chol, 9g sat fat
-- Panera Creamy Tomato Soup (bowl) ~350g
-- 420 cal, 26g fat, 6g protein, 40g carbs, 3g fiber, 20g sugar, 1260mg sodium, 55mg chol, 14g sat fat
-- Panera Mac & Cheese (small) ~230g
-- 440 cal, 23g fat, 17g protein, 41g carbs, 2g fiber, 3g sugar, 1060mg sodium, 50mg chol, 13g sat fat
-- Panera Mac & Cheese (large) ~380g
-- 730 cal, 38g fat, 28g protein, 68g carbs, 3g fiber, 5g sugar, 1760mg sodium, 80mg chol, 21g sat fat
-- Panera Turkey & Cheddar Sandwich (whole) ~400g
-- 780 cal, 45g fat, 41g protein, 52g carbs, 3g fiber, 5g sugar, 1690mg sodium, 100mg chol, 14g sat fat
-- Panera Roasted Turkey, Apple & Cheddar Sandwich (whole) ~380g
-- 710 cal, 29g fat, 35g protein, 73g carbs, 4g fiber, 18g sugar, 1740mg sodium, 85mg chol, 11g sat fat
-- Panera Chipotle Chicken Avocado Melt (whole) ~400g
-- 880 cal, 46g fat, 43g protein, 72g carbs, 6g fiber, 9g sugar, 2090mg sodium, 100mg chol, 16g sat fat
-- Panera Classic Grilled Cheese (whole) ~240g
-- 560 cal, 28g fat, 21g protein, 55g carbs, 2g fiber, 5g sugar, 1190mg sodium, 60mg chol, 15g sat fat
-- Panera Bacon, Egg & Cheese on Ciabatta ~220g
-- 470 cal, 20g fat, 22g protein, 51g carbs, 2g fiber, 5g sugar, 1000mg sodium, 205mg chol, 8g sat fat
-- Panera Caesar Salad (whole) ~240g
-- 330 cal, 23g fat, 11g protein, 22g carbs, 3g fiber, 3g sugar, 690mg sodium, 25mg chol, 5g sat fat
-- Panera Fuji Apple Salad with Chicken (whole) ~360g
-- 550 cal, 29g fat, 31g protein, 43g carbs, 5g fiber, 21g sugar, 930mg sodium, 85mg chol, 8g sat fat
-- Panera Chocolate Chipper Cookie ~98g
-- 440 cal, 22g fat, 5g protein, 59g carbs, 2g fiber, 35g sugar, 310mg sodium, 45mg chol, 13g sat fat
-- Panera Cinnamon Crunch Bagel ~113g
-- 420 cal, 10g fat, 9g protein, 73g carbs, 2g fiber, 28g sugar, 450mg sodium, 0mg chol, 3.5g sat fat
-- Panera Plain Bagel ~104g
-- 290 cal, 1g fat, 11g protein, 58g carbs, 2g fiber, 6g sugar, 500mg sodium, 0mg chol, 0g sat fat
-- Panera French Baguette (1/4) ~100g
-- 270 cal, 1g fat, 10g protein, 54g carbs, 2g fiber, 1g sugar, 640mg sodium, 0mg chol, 0g sat fat
-- =============================================
-- 6. JACK IN THE BOX
-- Source: jackinthebox.com, fastfoodnutrition.org
-- =============================================
-- Jack in the Box Jumbo Jack (w/o cheese) - 1 burger ~228g
-- 490 cal, 23g fat, 26g protein, 44g carbs, 2g fiber, 9g sugar, 770mg sodium, 55mg chol, 8g sat fat
-- Jack in the Box Jumbo Jack with Cheese - 1 burger ~252g
-- 570 cal, 30g fat, 30g protein, 44g carbs, 2g fiber, 9g sugar, 1060mg sodium, 80mg chol, 13g sat fat
-- Jack in the Box Hamburger - 1 burger ~119g
-- 280 cal, 11g fat, 14g protein, 32g carbs, 1g fiber, 6g sugar, 490mg sodium, 30mg chol, 4g sat fat
-- Jack in the Box Classic Buttery Jack - 1 burger ~278g
-- 820 cal, 52g fat, 37g protein, 50g carbs, 2g fiber, 10g sugar, 1250mg sodium, 130mg chol, 21g sat fat
-- Jack in the Box Bacon Ultimate Cheeseburger - 1 burger ~304g
-- 910 cal, 56g fat, 57g protein, 44g carbs, 2g fiber, 10g sugar, 1640mg sodium, 170mg chol, 24g sat fat
-- Jack in the Box Sourdough Jack - 1 burger ~243g
-- 660 cal, 35g fat, 30g protein, 55g carbs, 3g fiber, 10g sugar, 1300mg sodium, 85mg chol, 13g sat fat
-- Jack in the Box Beef Taco (1 taco) - 1 taco ~60g
-- 190 cal, 11g fat, 6g protein, 16g carbs, 2g fiber, 1g sugar, 310mg sodium, 15mg chol, 3.5g sat fat
-- Jack in the Box Monster Taco - 1 taco ~115g
-- 470 cal, 30g fat, 13g protein, 38g carbs, 4g fiber, 3g sugar, 730mg sodium, 30mg chol, 9g sat fat
-- Jack in the Box Cluck Sandwich - 1 sandwich ~200g
-- 490 cal, 21g fat, 27g protein, 48g carbs, 2g fiber, 7g sugar, 1070mg sodium, 50mg chol, 4g sat fat
-- Jack in the Box Spicy Chicken Sandwich - 1 sandwich ~218g
-- 530 cal, 23g fat, 25g protein, 55g carbs, 3g fiber, 8g sugar, 1130mg sodium, 40mg chol, 4g sat fat
-- Jack in the Box Chicken Nuggets (10 pc) - ~165g
-- 450 cal, 26g fat, 22g protein, 30g carbs, 2g fiber, 0g sugar, 990mg sodium, 50mg chol, 5g sat fat
-- Jack in the Box Breakfast Jack - 1 sandwich ~125g
-- 280 cal, 12g fat, 16g protein, 26g carbs, 0g fiber, 3g sugar, 710mg sodium, 200mg chol, 5g sat fat
-- Jack in the Box Grande Sausage Breakfast Burrito - 1 burrito ~330g
-- 1040 cal, 60g fat, 40g protein, 80g carbs, 4g fiber, 5g sugar, 2260mg sodium, 430mg chol, 22g sat fat
-- Jack in the Box Seasoned Curly Fries (medium) - ~130g
-- 380 cal, 22g fat, 5g protein, 42g carbs, 4g fiber, 0g sugar, 840mg sodium, 0mg chol, 4g sat fat
-- Jack in the Box French Fries (medium) - ~120g
-- 330 cal, 15g fat, 4g protein, 44g carbs, 3g fiber, 0g sugar, 430mg sodium, 0mg chol, 2.5g sat fat
-- Jack in the Box Egg Rolls (3 pc) - ~190g
-- 570 cal, 28g fat, 16g protein, 64g carbs, 4g fiber, 8g sugar, 1340mg sodium, 25mg chol, 5g sat fat
-- Jack in the Box Tiny Tacos (10 pc) - ~100g
-- 350 cal, 20g fat, 12g protein, 30g carbs, 3g fiber, 2g sugar, 600mg sodium, 25mg chol, 5g sat fat
-- Jack in the Box Oreo Cookie Shake (medium) ~475g
-- 810 cal, 32g fat, 17g protein, 116g carbs, 1g fiber, 92g sugar, 510mg sodium, 95mg chol, 21g sat fat
-- =============================================
-- 7. WHATABURGER
-- Source: whataburger.com, fastfoodnutrition.org
-- =============================================
-- Whataburger (regular) - 1 burger ~316g
-- 590 cal, 25g fat, 29g protein, 62g carbs, 4g fiber, 12g sugar, 1220mg sodium, 45mg chol, 8g sat fat, 1g trans fat
-- Whataburger Jr. - 1 burger ~165g
-- 340 cal, 15g fat, 16g protein, 34g carbs, 2g fiber, 6g sugar, 730mg sodium, 30mg chol, 5g sat fat
-- Double Meat Whataburger - 1 burger ~419g
-- 840 cal, 41g fat, 47g protein, 62g carbs, 4g fiber, 12g sugar, 1590mg sodium, 110mg chol, 15g sat fat
-- Triple Meat Whataburger - 1 burger ~520g
-- 1070 cal, 57g fat, 65g protein, 62g carbs, 4g fiber, 12g sugar, 1950mg sodium, 175mg chol, 22g sat fat
-- Whataburger Patty Melt - 1 sandwich ~310g
-- 750 cal, 40g fat, 34g protein, 58g carbs, 3g fiber, 8g sugar, 1500mg sodium, 100mg chol, 16g sat fat
-- Whataburger Honey BBQ Chicken Strip Sandwich - 1 sandwich ~280g
-- 730 cal, 32g fat, 34g protein, 73g carbs, 3g fiber, 17g sugar, 1650mg sodium, 65mg chol, 7g sat fat
-- Whataburger Spicy Chicken Sandwich - 1 sandwich ~250g
-- 540 cal, 21g fat, 28g protein, 55g carbs, 3g fiber, 7g sugar, 1380mg sodium, 50mg chol, 4g sat fat
-- Whataburger Grilled Chicken Sandwich - 1 sandwich ~260g
-- 440 cal, 14g fat, 33g protein, 42g carbs, 3g fiber, 7g sugar, 1210mg sodium, 90mg chol, 3g sat fat
-- Whataburger Chicken Strips (3 pc) - ~130g
-- 450 cal, 24g fat, 28g protein, 28g carbs, 1g fiber, 0g sugar, 1320mg sodium, 55mg chol, 4g sat fat
-- Whataburger Honey Butter Chicken Biscuit - 1 biscuit ~156g
-- 560 cal, 33g fat, 13g protein, 51g carbs, 2g fiber, 9g sugar, 1050mg sodium, 30mg chol, 12g sat fat
-- Whataburger Breakfast on a Bun (Sausage) - 1 sandwich ~188g
-- 550 cal, 34g fat, 22g protein, 35g carbs, 1g fiber, 4g sugar, 1120mg sodium, 250mg chol, 13g sat fat
-- Whataburger Sausage, Egg & Cheese Biscuit - 1 sandwich ~210g
-- 690 cal, 44g fat, 25g protein, 43g carbs, 1g fiber, 3g sugar, 1640mg sodium, 270mg chol, 18g sat fat
-- Whataburger French Fries (medium) - ~130g
-- 400 cal, 20g fat, 5g protein, 51g carbs, 4g fiber, 0g sugar, 280mg sodium, 0mg chol, 3g sat fat
-- Whataburger Onion Rings (medium) - ~130g
-- 410 cal, 23g fat, 5g protein, 46g carbs, 2g fiber, 4g sugar, 860mg sodium, 0mg chol, 4g sat fat
-- Whataburger Bacon & Cheese Whataburger - 1 burger ~363g
-- 790 cal, 39g fat, 40g protein, 62g carbs, 4g fiber, 12g sugar, 1690mg sodium, 95mg chol, 15g sat fat
-- =============================================
-- 8. PANDA EXPRESS (expanding beyond existing 4 items)
-- Source: pandaexpress.com, fastfoodnutrition.org
-- Existing: bigger_plate, teriyaki_sauce, chili_sauce, soy_sauce
-- =============================================
-- Panda Express Orange Chicken - 1 entree 162g (5.7oz)
-- 370 cal, 17g fat, 19g protein, 38g carbs, 1g fiber, 14g sugar, 620mg sodium, 60mg chol, 3g sat fat
-- Panda Express Kung Pao Chicken - 1 entree 176g (6.2oz)
-- 290 cal, 19g fat, 16g protein, 14g carbs, 2g fiber, 6g sugar, 970mg sodium, 55mg chol, 3.5g sat fat
-- Panda Express Broccoli Beef - 1 entree 153g (5.4oz)
-- 150 cal, 7g fat, 9g protein, 13g carbs, 2g fiber, 7g sugar, 520mg sodium, 12mg chol, 1.5g sat fat
-- Panda Express Beijing Beef - 1 entree ~180g
-- 470 cal, 26g fat, 16g protein, 42g carbs, 1g fiber, 19g sugar, 660mg sodium, 35mg chol, 5g sat fat
-- Panda Express Honey Walnut Shrimp - 1 entree ~162g
-- 360 cal, 23g fat, 13g protein, 27g carbs, 1g fiber, 14g sugar, 440mg sodium, 55mg chol, 4g sat fat
-- Panda Express Grilled Teriyaki Chicken - 1 entree ~153g
-- 300 cal, 13g fat, 36g protein, 8g carbs, 0g fiber, 5g sugar, 530mg sodium, 120mg chol, 3g sat fat
-- Panda Express String Bean Chicken Breast - 1 entree ~162g
-- 190 cal, 9g fat, 14g protein, 13g carbs, 2g fiber, 6g sugar, 740mg sodium, 40mg chol, 2g sat fat
-- Panda Express Mushroom Chicken - 1 entree ~162g
-- 220 cal, 13g fat, 14g protein, 10g carbs, 1g fiber, 5g sugar, 760mg sodium, 50mg chol, 2.5g sat fat
-- Panda Express SweetFire Chicken Breast - 1 entree ~162g
-- 380 cal, 15g fat, 16g protein, 44g carbs, 1g fiber, 20g sugar, 370mg sodium, 40mg chol, 2.5g sat fat
-- Panda Express Honey Sesame Chicken Breast - 1 entree ~176g
-- 490 cal, 21g fat, 19g protein, 57g carbs, 2g fiber, 28g sugar, 580mg sodium, 50mg chol, 3.5g sat fat
-- Panda Express Black Pepper Chicken - 1 entree ~162g
-- 280 cal, 15g fat, 15g protein, 19g carbs, 2g fiber, 10g sugar, 730mg sodium, 45mg chol, 3g sat fat
-- Panda Express Sweet & Sour Chicken Breast - 1 entree ~162g
-- 300 cal, 13g fat, 13g protein, 34g carbs, 0g fiber, 17g sugar, 260mg sodium, 35mg chol, 2g sat fat
-- Panda Express Chow Mein (side) ~266g (9.4oz)
-- 510 cal, 20g fat, 13g protein, 80g carbs, 6g fiber, 9g sugar, 860mg sodium, 0mg chol, 3.5g sat fat
-- Panda Express Fried Rice (side) ~264g (9.3oz)
-- 520 cal, 16g fat, 11g protein, 85g carbs, 1g fiber, 3g sugar, 850mg sodium, 120mg chol, 3g sat fat
-- Panda Express Steamed White Rice (side) ~252g
-- 380 cal, 0g fat, 7g protein, 87g carbs, 0g fiber, 0g sugar, 0mg sodium, 0mg chol, 0g sat fat
-- Panda Express Super Greens (side) ~198g
-- 90 cal, 3g fat, 6g protein, 10g carbs, 4g fiber, 3g sugar, 320mg sodium, 0mg chol, 0.5g sat fat
-- Panda Express Chicken Egg Roll (1 roll) ~85g
-- 200 cal, 9g fat, 8g protein, 20g carbs, 2g fiber, 2g sugar, 390mg sodium, 15mg chol, 2g sat fat
-- Panda Express Cream Cheese Rangoon (3 pc) ~90g
-- 190 cal, 8g fat, 5g protein, 24g carbs, 0g fiber, 1g sugar, 180mg sodium, 15mg chol, 5g sat fat
-- Panda Express Chicken Potsticker (3 pc) ~100g
-- 220 cal, 9g fat, 9g protein, 24g carbs, 1g fiber, 2g sugar, 340mg sodium, 20mg chol, 2g sat fat
-- =============================================
-- 9. FIVE GUYS
-- Source: fiveguys.com, fastfoodnutrition.org
-- =============================================
-- Five Guys Hamburger (2 patties) - 1 burger 265g
-- 700 cal, 43g fat, 39g protein, 39g carbs, 2g fiber, 8g sugar, 430mg sodium, 125mg chol, 20g sat fat
-- Five Guys Little Hamburger (1 patty) - 1 burger 171g
-- 480 cal, 26g fat, 23g protein, 39g carbs, 2g fiber, 8g sugar, 380mg sodium, 65mg chol, 12g sat fat
-- Five Guys Cheeseburger (2 patties) - 1 burger 303g
-- 840 cal, 55g fat, 47g protein, 40g carbs, 2g fiber, 9g sugar, 1050mg sodium, 165mg chol, 26g sat fat
-- Five Guys Little Cheeseburger (1 patty) - 1 burger 193g
-- 550 cal, 32g fat, 27g protein, 40g carbs, 2g fiber, 9g sugar, 690mg sodium, 85mg chol, 16g sat fat
-- Five Guys Bacon Cheeseburger (2 patties) - 1 burger 317g
-- 920 cal, 62g fat, 51g protein, 40g carbs, 2g fiber, 9g sugar, 1310mg sodium, 180mg chol, 30g sat fat
-- Five Guys Bacon Burger (2 patties) - 1 burger 285g
-- 780 cal, 50g fat, 45g protein, 39g carbs, 2g fiber, 8g sugar, 700mg sodium, 140mg chol, 23g sat fat
-- Five Guys Hot Dog - 1 hot dog 167g
-- 545 cal, 35g fat, 18g protein, 40g carbs, 2g fiber, 8g sugar, 1130mg sodium, 61mg chol, 16g sat fat
-- Five Guys Cheese Dog - 1 hot dog 195g
-- 615 cal, 41g fat, 22g protein, 41g carbs, 2g fiber, 9g sugar, 1440mg sodium, 80mg chol, 20g sat fat
-- Five Guys Bacon Dog - 1 hot dog 183g
-- 625 cal, 42g fat, 22g protein, 40g carbs, 2g fiber, 8g sugar, 1400mg sodium, 75mg chol, 19g sat fat
-- Five Guys Grilled Cheese - 1 sandwich ~200g
-- 470 cal, 26g fat, 18g protein, 41g carbs, 2g fiber, 8g sugar, 715mg sodium, 50mg chol, 14g sat fat
-- Five Guys Veggie Sandwich - 1 sandwich ~200g
-- 280 cal, 15g fat, 10g protein, 39g carbs, 3g fiber, 8g sugar, 420mg sodium, 0mg chol, 6g sat fat
-- Five Guys BLT - 1 sandwich ~175g
-- 490 cal, 33g fat, 18g protein, 39g carbs, 2g fiber, 8g sugar, 830mg sodium, 40mg chol, 13g sat fat
-- Five Guys Regular Fries - 1 serving 411g
-- 620 cal, 30g fat, 9g protein, 78g carbs, 7g fiber, 0g sugar, 90mg sodium, 0mg chol, 6g sat fat
-- Five Guys Little Fries - 1 serving 227g
-- 528 cal, 26g fat, 8g protein, 68g carbs, 6g fiber, 0g sugar, 50mg sodium, 0mg chol, 5g sat fat
-- Five Guys Cajun Fries (regular) - 1 serving 411g
-- 620 cal, 30g fat, 9g protein, 78g carbs, 7g fiber, 0g sugar, 680mg sodium, 0mg chol, 6g sat fat
-- Five Guys Chocolate Milkshake (regular) ~475g
-- 840 cal, 52g fat, 15g protein, 83g carbs, 2g fiber, 69g sugar, 340mg sodium, 155mg chol, 33g sat fat
-- Five Guys Vanilla Milkshake (regular) ~450g
-- 670 cal, 39g fat, 12g protein, 69g carbs, 0g fiber, 57g sugar, 310mg sodium, 125mg chol, 25g sat fat
('pizza_hut_hand_tossed_pepperoni', 'Pizza Hut Hand-Tossed Pepperoni Pizza (Medium Slice)', 214.95, 8.41, 23.36, 9.35, 1.87, 0.93, 107, 107, 'pizzahut.com', ARRAY['pizza hut pepperoni', 'pepperoni pizza hut', 'hand tossed pepperoni'], '230 cal per slice. {"sodium_mg":504,"cholesterol_mg":23,"sat_fat_g":3.74,"trans_fat_g":0.0}'),
('pizza_hut_hand_tossed_cheese', 'Pizza Hut Hand-Tossed Cheese Pizza (Medium Slice)', 214.29, 9.18, 26.53, 8.16, 2.04, 1.02, 98, 98, 'pizzahut.com', ARRAY['pizza hut cheese', 'cheese pizza hut', 'hand tossed cheese'], '210 cal per slice. {"sodium_mg":469,"cholesterol_mg":20,"sat_fat_g":4.08,"trans_fat_g":0.0}'),
('pizza_hut_hand_tossed_supreme', 'Pizza Hut Hand-Tossed Supreme Pizza (Medium Slice)', 203.13, 7.81, 21.09, 9.38, 1.56, 0.78, 128, 128, 'pizzahut.com', ARRAY['pizza hut supreme', 'supreme pizza hut'], '260 cal per slice. {"sodium_mg":445,"cholesterol_mg":23,"sat_fat_g":3.91,"trans_fat_g":0.0}'),
('pizza_hut_hand_tossed_meat_lovers', 'Pizza Hut Hand-Tossed Meat Lovers Pizza (Medium Slice)', 229.01, 9.16, 19.85, 12.21, 1.53, 0.76, 131, 131, 'pizzahut.com', ARRAY['pizza hut meat lovers', 'meat lovers pizza hut'], '300 cal per slice. {"sodium_mg":565,"cholesterol_mg":31,"sat_fat_g":4.58,"trans_fat_g":0.0}'),
('pizza_hut_hand_tossed_veggie_lovers', 'Pizza Hut Hand-Tossed Veggie Lovers Pizza (Medium Slice)', 169.49, 6.78, 22.88, 5.93, 1.69, 0.85, 118, 118, 'pizzahut.com', ARRAY['pizza hut veggie', 'veggie lovers pizza hut', 'veggie pizza hut'], '200 cal per slice. {"sodium_mg":364,"cholesterol_mg":13,"sat_fat_g":2.54,"trans_fat_g":0.0}'),
('pizza_hut_pan_cheese', 'Pizza Hut Pan Cheese Pizza (Medium Slice)', 263.64, 10.91, 25.45, 12.73, 1.82, 0.91, 110, 110, 'pizzahut.com', ARRAY['pizza hut pan cheese', 'pan pizza cheese', 'pan cheese pizza hut'], '290 cal per slice. {"sodium_mg":536,"cholesterol_mg":9,"sat_fat_g":5.45,"trans_fat_g":0.0}'),
('pizza_hut_pan_pepperoni', 'Pizza Hut Pan Pepperoni Pizza (Medium Slice)', 227.27, 8.36, 23.36, 10.91, 0.91, 1.82, 110, 110, 'pizzahut.com', ARRAY['pizza hut pan pepperoni', 'pan pizza pepperoni', 'pan pepperoni pizza hut'], '250 cal per slice. {"sodium_mg":536,"cholesterol_mg":23,"sat_fat_g":4.09,"trans_fat_g":0.0}'),
('pizza_hut_pan_supreme', 'Pizza Hut Pan Supreme Pizza (Medium Slice)', 215.38, 8.46, 20.77, 10.77, 1.54, 1.54, 130, 130, 'pizzahut.com', ARRAY['pizza hut pan supreme', 'pan pizza supreme'], '280 cal per slice. {"sodium_mg":485,"cholesterol_mg":19,"sat_fat_g":3.85,"trans_fat_g":0.0}'),
('pizza_hut_pan_meat_lovers', 'Pizza Hut Pan Meat Lovers Pizza (Medium Slice)', 251.85, 10.37, 19.26, 14.07, 1.48, 1.48, 135, 135, 'pizzahut.com', ARRAY['pizza hut pan meat lovers', 'pan pizza meat lovers'], '340 cal per slice. {"sodium_mg":578,"cholesterol_mg":30,"sat_fat_g":5.19,"trans_fat_g":0.0}'),
('pizza_hut_stuffed_crust_pepperoni', 'Pizza Hut Stuffed Crust Pepperoni Pizza (Large Slice)', 253.33, 10.67, 26.00, 12.00, 1.33, 2.00, 150, 150, 'pizzahut.com', ARRAY['pizza hut stuffed crust pepperoni', 'stuffed crust pepperoni'], '380 cal per slice. {"sodium_mg":707,"cholesterol_mg":30,"sat_fat_g":6.00,"trans_fat_g":0.0}'),
('pizza_hut_stuffed_crust_cheese', 'Pizza Hut Stuffed Crust Cheese Pizza (Large Slice)', 234.48, 11.03, 26.21, 9.66, 1.38, 2.07, 145, 145, 'pizzahut.com', ARRAY['pizza hut stuffed crust cheese', 'stuffed crust cheese'], '340 cal per slice. {"sodium_mg":621,"cholesterol_mg":24,"sat_fat_g":4.83,"trans_fat_g":0.0}'),
('pizza_hut_thin_crispy_pepperoni', 'Pizza Hut Thin N Crispy Pepperoni Pizza (Medium Slice)', 250.00, 10.00, 23.75, 12.50, 1.25, 1.25, 80, 80, 'pizzahut.com', ARRAY['pizza hut thin crust pepperoni', 'thin crispy pepperoni', 'thin n crispy pizza hut'], '200 cal per slice. {"sodium_mg":613,"cholesterol_mg":31,"sat_fat_g":5.00,"trans_fat_g":0.0}'),
('pizza_hut_hand_tossed_bbq_chicken', 'Pizza Hut Hand-Tossed BBQ Chicken Pizza (Medium Slice)', 191.67, 10.00, 26.67, 5.00, 0.83, 6.67, 120, 120, 'pizzahut.com', ARRAY['pizza hut bbq chicken', 'bbq chicken pizza hut'], '230 cal per slice. {"sodium_mg":483,"cholesterol_mg":25,"sat_fat_g":2.08,"trans_fat_g":0.0}'),
('pizza_hut_hand_tossed_hawaiian', 'Pizza Hut Hand-Tossed Hawaiian Pizza (Medium Slice)', 186.44, 8.47, 23.73, 5.93, 0.85, 4.24, 118, 118, 'pizzahut.com', ARRAY['pizza hut hawaiian', 'hawaiian pizza hut', 'ham pineapple pizza hut'], '220 cal per slice. {"sodium_mg":449,"cholesterol_mg":21,"sat_fat_g":2.54,"trans_fat_g":0.0}'),
('pizza_hut_bone_in_wings_naked', 'Pizza Hut Traditional Bone-In Wing (Naked)', 266.67, 30.00, 0.00, 15.00, 0.00, 0.00, 30, 30, 'pizzahut.com', ARRAY['pizza hut wings', 'bone in wings pizza hut', 'naked wings pizza hut'], '80 cal per wing. {"sodium_mg":800,"cholesterol_mg":150,"sat_fat_g":5.00,"trans_fat_g":0.0}'),
('pizza_hut_buffalo_wings', 'Pizza Hut Buffalo Bone-In Wing', 303.03, 27.27, 6.06, 18.18, 0.00, 0.00, 33, 33, 'pizzahut.com', ARRAY['pizza hut buffalo wings', 'hot wings pizza hut', 'buffalo wings pizza hut'], '100 cal per wing. {"sodium_mg":1242,"cholesterol_mg":136,"sat_fat_g":6.06,"trans_fat_g":0.0}'),
('pizza_hut_garlic_parm_wings', 'Pizza Hut Garlic Parmesan Bone-In Wing', 323.53, 26.47, 5.88, 23.53, 0.00, 0.00, 34, 34, 'pizzahut.com', ARRAY['pizza hut garlic parmesan wings', 'garlic parm wings pizza hut'], '110 cal per wing. {"sodium_mg":853,"cholesterol_mg":132,"sat_fat_g":5.88,"trans_fat_g":0.0}'),
('pizza_hut_boneless_wings', 'Pizza Hut Boneless Wing', 320.00, 16.00, 28.00, 16.00, 0.00, 0.00, 25, 25, 'pizzahut.com', ARRAY['pizza hut boneless wings', 'boneless wings pizza hut'], '80 cal per wing. {"sodium_mg":800,"cholesterol_mg":40,"sat_fat_g":4.00,"trans_fat_g":0.0}'),
('pizza_hut_breadstick_cheese', 'Pizza Hut Breadstick with Cheese', 303.57, 14.29, 35.71, 10.71, 1.79, 3.57, 56, 56, 'pizzahut.com', ARRAY['pizza hut breadsticks', 'breadstick pizza hut', 'pizza hut cheese breadstick'], '170 cal per stick. {"sodium_mg":696,"cholesterol_mg":27,"sat_fat_g":4.46,"trans_fat_g":0.0}'),
('pizza_hut_creamy_chicken_alfredo', 'Pizza Hut Tuscani Creamy Chicken Alfredo Pasta', 165.79, 7.11, 20.00, 6.32, 1.05, 1.05, 380, 380, 'pizzahut.com', ARRAY['pizza hut alfredo pasta', 'tuscani alfredo', 'chicken alfredo pizza hut'], '630 cal per serving. {"sodium_mg":311,"cholesterol_mg":16,"sat_fat_g":2.37,"trans_fat_g":0.0}'),
('pizza_hut_meaty_marinara', 'Pizza Hut Tuscani Meaty Marinara Pasta', 158.97, 6.67, 18.46, 6.15, 1.28, 2.05, 390, 390, 'pizzahut.com', ARRAY['pizza hut marinara pasta', 'tuscani marinara', 'meaty marinara pizza hut'], '620 cal per serving. {"sodium_mg":369,"cholesterol_mg":15,"sat_fat_g":2.05,"trans_fat_g":0.0}'),
('pizza_hut_cinnamon_sticks', 'Pizza Hut Cinnamon Sticks (2 pcs)', 290.91, 5.45, 47.27, 9.09, 1.82, 16.36, 55, 55, 'pizzahut.com', ARRAY['pizza hut cinnamon sticks', 'cinnamon sticks pizza hut'], '160 cal per 2 sticks. {"sodium_mg":273,"cholesterol_mg":0,"sat_fat_g":2.73,"trans_fat_g":0.0}'),
('pizza_hut_cinnabon_mini_rolls', 'Pizza Hut Cinnabon Mini Rolls', 307.41, 4.07, 45.93, 12.22, 1.11, 23.70, 270, 270, 'pizzahut.com', ARRAY['pizza hut cinnabon', 'cinnabon rolls pizza hut', 'mini rolls pizza hut'], '830 cal per order. {"sodium_mg":233,"cholesterol_mg":13,"sat_fat_g":5.19,"trans_fat_g":0.0}'),
('kfc_original_recipe_breast', 'KFC Original Recipe Chicken Breast', 242.24, 24.22, 6.83, 13.04, 1.24, 0.00, 161, 161, 'kfc.com', ARRAY['kfc breast', 'kfc original breast', 'original recipe breast'], '390 cal per breast. {"sodium_mg":739,"cholesterol_mg":75,"sat_fat_g":2.48,"trans_fat_g":0.0}'),
('kfc_original_recipe_thigh', 'KFC Original Recipe Chicken Thigh', 307.69, 20.88, 8.79, 20.88, 1.10, 0.00, 91, 91, 'kfc.com', ARRAY['kfc thigh', 'kfc original thigh', 'original recipe thigh'], '280 cal per thigh. {"sodium_mg":1000,"cholesterol_mg":110,"sat_fat_g":4.95,"trans_fat_g":0.0}'),
('kfc_original_recipe_drumstick', 'KFC Original Recipe Chicken Drumstick', 232.14, 21.43, 7.14, 14.29, 1.79, 0.00, 56, 56, 'kfc.com', ARRAY['kfc drumstick', 'kfc drum', 'original recipe drumstick'], '130 cal per drumstick. {"sodium_mg":768,"cholesterol_mg":98,"sat_fat_g":2.68,"trans_fat_g":0.0}'),
('kfc_original_recipe_wing', 'KFC Original Recipe Chicken Wing', 250.00, 18.75, 8.33, 16.67, 0.00, 0.00, 48, 48, 'kfc.com', ARRAY['kfc wing', 'kfc original wing', 'original recipe wing'], '120 cal per wing. {"sodium_mg":729,"cholesterol_mg":94,"sat_fat_g":3.13,"trans_fat_g":0.0}'),
('kfc_extra_crispy_breast', 'KFC Extra Crispy Chicken Breast', 315.48, 20.83, 10.71, 20.83, 0.00, 0.60, 168, 168, 'kfc.com', ARRAY['kfc extra crispy breast', 'extra crispy breast'], '530 cal per breast. {"sodium_mg":685,"cholesterol_mg":63,"sat_fat_g":3.57,"trans_fat_g":0.0}'),
('kfc_extra_crispy_thigh', 'KFC Extra Crispy Chicken Thigh', 254.39, 14.91, 9.65, 17.54, 0.00, 0.00, 114, 114, 'kfc.com', ARRAY['kfc extra crispy thigh', 'extra crispy thigh'], '290 cal per thigh. {"sodium_mg":579,"cholesterol_mg":61,"sat_fat_g":3.51,"trans_fat_g":0.0}'),
('kfc_extra_crispy_drumstick', 'KFC Extra Crispy Chicken Drumstick', 283.33, 20.00, 10.00, 16.67, 0.00, 0.00, 60, 60, 'kfc.com', ARRAY['kfc extra crispy drumstick', 'extra crispy drum'], '170 cal per drumstick. {"sodium_mg":583,"cholesterol_mg":75,"sat_fat_g":3.33,"trans_fat_g":0.0}'),
('kfc_chicken_sandwich', 'KFC Chicken Sandwich', 313.95, 13.53, 27.05, 16.43, 0.97, 3.86, 207, 207, 'kfc.com', ARRAY['kfc sandwich', 'kfc chicken sandwich', 'kfc crispy sandwich'], '650 cal per sandwich. {"sodium_mg":792,"cholesterol_mg":29,"sat_fat_g":2.90,"trans_fat_g":0.0}'),
('kfc_famous_bowl', 'KFC Famous Bowl', 186.40, 6.55, 20.40, 8.82, 1.51, 0.50, 397, 397, 'kfc.com', ARRAY['kfc bowl', 'famous bowl', 'kfc mashed potato bowl'], '740 cal per bowl. {"sodium_mg":592,"cholesterol_mg":11,"sat_fat_g":1.51,"trans_fat_g":0.0}'),
('kfc_chicken_pot_pie', 'KFC Chicken Pot Pie', 223.60, 8.07, 18.63, 12.73, 2.17, 1.55, 322, 322, 'kfc.com', ARRAY['kfc pot pie', 'chicken pot pie kfc'], '720 cal per pie. {"sodium_mg":543,"cholesterol_mg":25,"sat_fat_g":7.76,"trans_fat_g":0.0}'),
('kfc_mac_and_cheese', 'KFC Mac & Cheese', 125.00, 5.15, 12.50, 5.88, 0.00, 1.47, 136, 136, 'kfc.com', ARRAY['kfc mac and cheese', 'kfc macaroni', 'mac cheese kfc'], '170 cal per serving. {"sodium_mg":529,"cholesterol_mg":15,"sat_fat_g":2.21,"trans_fat_g":0.0}'),
('kfc_mashed_potatoes_gravy', 'KFC Mashed Potatoes with Gravy', 84.97, 1.31, 12.42, 3.27, 0.65, 0.00, 153, 153, 'kfc.com', ARRAY['kfc mashed potatoes', 'kfc potatoes gravy'], '130 cal per serving. {"sodium_mg":333,"cholesterol_mg":0,"sat_fat_g":0.65,"trans_fat_g":0.0}'),
('kfc_coleslaw', 'KFC Coleslaw', 132.81, 0.78, 16.41, 7.81, 2.34, 10.94, 128, 128, 'kfc.com', ARRAY['kfc coleslaw', 'kfc cole slaw', 'kfc slaw'], '170 cal per serving. {"sodium_mg":141,"cholesterol_mg":4,"sat_fat_g":1.17,"trans_fat_g":0.0}'),
('kfc_corn_on_cob', 'KFC Corn on the Cob', 43.21, 1.23, 9.88, 0.31, 1.23, 2.47, 162, 162, 'kfc.com', ARRAY['kfc corn', 'corn on cob kfc'], '70 cal per ear. {"sodium_mg":0,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('kfc_green_beans', 'KFC Green Beans', 29.07, 1.16, 4.65, 0.00, 2.33, 1.16, 86, 86, 'kfc.com', ARRAY['kfc green beans', 'kfc beans'], '25 cal per serving. {"sodium_mg":326,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('kfc_biscuit', 'KFC Biscuit', 321.43, 7.14, 39.29, 14.29, 1.79, 3.57, 56, 56, 'kfc.com', ARRAY['kfc biscuit', 'biscuit kfc'], '180 cal per biscuit. {"sodium_mg":946,"cholesterol_mg":0,"sat_fat_g":7.14,"trans_fat_g":0.0}'),
('kfc_chicken_tenders', 'KFC Chicken Tenders (3 pc)', 284.62, 20.77, 16.92, 14.62, 0.00, 0.00, 130, 130, 'kfc.com', ARRAY['kfc tenders', 'kfc strips', 'chicken tenders kfc'], '370 cal per 3 tenders. {"sodium_mg":785,"cholesterol_mg":42,"sat_fat_g":2.31,"trans_fat_g":0.0}'),
('kfc_chicken_nuggets', 'KFC Chicken Nuggets (8 pc)', 265.63, 13.28, 17.19, 15.63, 0.00, 0.00, 128, 128, 'kfc.com', ARRAY['kfc nuggets', 'chicken nuggets kfc'], '340 cal per 8 nuggets. {"sodium_mg":617,"cholesterol_mg":31,"sat_fat_g":2.73,"trans_fat_g":0.0}'),
('kfc_spicy_chicken_sandwich', 'KFC Spicy Chicken Sandwich', 325.58, 13.49, 26.98, 17.21, 1.40, 3.72, 215, 215, 'kfc.com', ARRAY['kfc spicy sandwich', 'kfc spicy chicken'], '700 cal per sandwich. {"sodium_mg":851,"cholesterol_mg":30,"sat_fat_g":3.26,"trans_fat_g":0.0}'),
('kfc_chocolate_chip_cookie', 'KFC Chocolate Chip Cookie', 457.14, 5.71, 62.86, 22.86, 2.86, 37.14, 35, 35, 'kfc.com', ARRAY['kfc cookie', 'kfc chocolate chip cookie'], '160 cal per cookie. {"sodium_mg":343,"cholesterol_mg":29,"sat_fat_g":11.43,"trans_fat_g":0.0}'),
('chipotle_chicken_burrito', 'Chipotle Chicken Burrito', 100.00, 8.13, 9.38, 3.33, 0.42, 0.21, 480, 480, 'chipotle.com', ARRAY['chipotle burrito', 'chipotle chicken burrito', 'burrito chipotle'], '480 cal per burrito. {"sodium_mg":217,"cholesterol_mg":24,"sat_fat_g":1.04,"trans_fat_g":0.0}'),
('chipotle_steak_burrito_bowl', 'Chipotle Steak Burrito Bowl', 126.00, 8.00, 14.40, 4.40, 1.80, 1.00, 500, 500, 'chipotle.com', ARRAY['chipotle steak bowl', 'steak bowl chipotle', 'steak burrito bowl'], '630 cal per bowl. {"sodium_mg":306,"cholesterol_mg":16,"sat_fat_g":1.20,"trans_fat_g":0.0}'),
('chipotle_barbacoa_bowl', 'Chipotle Barbacoa Burrito Bowl', 129.00, 8.00, 14.40, 4.60, 2.00, 1.00, 500, 500, 'chipotle.com', ARRAY['chipotle barbacoa', 'barbacoa bowl chipotle'], '645 cal per bowl. {"sodium_mg":348,"cholesterol_mg":17,"sat_fat_g":1.40,"trans_fat_g":0.0}'),
('chipotle_sofritas_bowl', 'Chipotle Sofritas Burrito Bowl', 113.27, 3.88, 15.10, 3.47, 2.24, 1.22, 490, 490, 'chipotle.com', ARRAY['chipotle sofritas', 'sofritas bowl chipotle', 'tofu bowl chipotle'], '555 cal per bowl. {"sodium_mg":278,"cholesterol_mg":0,"sat_fat_g":0.61,"trans_fat_g":0.0}'),
('chipotle_carnitas_burrito', 'Chipotle Carnitas Burrito', 114.00, 7.00, 12.00, 4.00, 1.40, 0.60, 500, 500, 'chipotle.com', ARRAY['chipotle carnitas', 'carnitas burrito chipotle'], '570 cal per burrito. {"sodium_mg":308,"cholesterol_mg":17,"sat_fat_g":1.40,"trans_fat_g":0.0}'),
('chipotle_steak_tacos', 'Chipotle Steak Tacos (3 pcs)', 175.00, 10.00, 19.00, 6.00, 2.00, 1.00, 300, 300, 'chipotle.com', ARRAY['chipotle steak tacos', 'steak tacos chipotle'], '525 cal for 3 tacos. {"sodium_mg":360,"cholesterol_mg":22,"sat_fat_g":1.67,"trans_fat_g":0.0}'),
('chipotle_chicken_quesadilla', 'Chipotle Chicken Quesadilla', 258.62, 15.86, 18.62, 12.76, 1.03, 0.69, 290, 290, 'chipotle.com', ARRAY['chipotle quesadilla', 'chicken quesadilla chipotle'], '750 cal per quesadilla. {"sodium_mg":566,"cholesterol_mg":48,"sat_fat_g":5.86,"trans_fat_g":0.0}'),
('chipotle_white_rice', 'Chipotle Cilantro-Lime White Rice', 161.54, 2.31, 30.77, 3.08, 0.00, 0.00, 130, 130, 'chipotle.com', ARRAY['chipotle rice', 'chipotle white rice', 'cilantro lime rice'], '210 cal per serving. {"sodium_mg":215,"cholesterol_mg":0,"sat_fat_g":0.38,"trans_fat_g":0.0}'),
('chipotle_brown_rice', 'Chipotle Cilantro-Lime Brown Rice', 161.54, 3.08, 27.69, 3.85, 1.54, 0.00, 130, 130, 'chipotle.com', ARRAY['chipotle brown rice'], '210 cal per serving. {"sodium_mg":177,"cholesterol_mg":0,"sat_fat_g":0.38,"trans_fat_g":0.0}'),
('chipotle_black_beans', 'Chipotle Black Beans', 100.00, 6.15, 16.92, 0.77, 5.38, 0.77, 130, 130, 'chipotle.com', ARRAY['chipotle beans', 'chipotle black beans'], '130 cal per serving. {"sodium_mg":162,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('chipotle_pinto_beans', 'Chipotle Pinto Beans', 100.00, 6.15, 16.92, 0.77, 5.38, 0.00, 130, 130, 'chipotle.com', ARRAY['chipotle pinto beans'], '130 cal per serving. {"sodium_mg":238,"cholesterol_mg":4,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('chipotle_chicken', 'Chipotle Chicken (Protein)', 159.29, 28.32, 0.00, 6.19, 0.00, 0.00, 113, 113, 'chipotle.com', ARRAY['chipotle chicken protein', 'chipotle grilled chicken'], '180 cal per 4oz serving. {"sodium_mg":469,"cholesterol_mg":84,"sat_fat_g":1.77,"trans_fat_g":0.0}'),
('chipotle_steak', 'Chipotle Steak (Protein)', 132.74, 18.58, 0.88, 5.31, 0.00, 0.00, 113, 113, 'chipotle.com', ARRAY['chipotle steak protein'], '150 cal per 4oz serving. {"sodium_mg":345,"cholesterol_mg":58,"sat_fat_g":1.77,"trans_fat_g":0.0}'),
('chipotle_guacamole', 'Chipotle Guacamole (Side)', 230.00, 2.00, 8.00, 22.00, 6.00, 1.00, 100, 100, 'chipotle.com', ARRAY['chipotle guac', 'chipotle guacamole', 'guacamole chipotle'], '230 cal per side. {"sodium_mg":330,"cholesterol_mg":0,"sat_fat_g":3.00,"trans_fat_g":0.0}'),
('chipotle_queso_blanco_side', 'Chipotle Queso Blanco (Side)', 210.53, 8.77, 7.02, 15.79, 0.00, 1.75, 57, 57, 'chipotle.com', ARRAY['chipotle queso', 'chipotle cheese dip'], '120 cal per side. {"sodium_mg":456,"cholesterol_mg":35,"sat_fat_g":8.77,"trans_fat_g":0.0}'),
('chipotle_fresh_tomato_salsa', 'Chipotle Fresh Tomato Salsa (Pico)', 22.32, 0.89, 3.57, 0.00, 0.89, 1.79, 112, 112, 'chipotle.com', ARRAY['chipotle pico de gallo', 'chipotle salsa', 'chipotle pico'], '25 cal per serving. {"sodium_mg":455,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('chipotle_sour_cream', 'Chipotle Sour Cream', 192.98, 3.51, 3.51, 15.79, 0.00, 1.75, 57, 57, 'chipotle.com', ARRAY['chipotle sour cream'], '110 cal per serving. {"sodium_mg":53,"cholesterol_mg":61,"sat_fat_g":10.53,"trans_fat_g":0.0}'),
('chipotle_cheese', 'Chipotle Shredded Cheese', 392.86, 21.43, 3.57, 32.14, 0.00, 0.00, 28, 28, 'chipotle.com', ARRAY['chipotle cheese', 'chipotle shredded cheese'], '110 cal per serving. {"sodium_mg":536,"cholesterol_mg":89,"sat_fat_g":17.86,"trans_fat_g":0.0}'),
('chipotle_tortilla_chips', 'Chipotle Tortilla Chips', 469.57, 6.09, 59.13, 22.61, 4.35, 0.87, 115, 115, 'chipotle.com', ARRAY['chipotle chips', 'chips chipotle'], '540 cal per bag. {"sodium_mg":278,"cholesterol_mg":0,"sat_fat_g":3.04,"trans_fat_g":0.0}'),
('sonic_jr_burger', 'Sonic Jr. Burger', 267.72, 11.81, 26.77, 13.39, 0.79, 4.72, 127, 127, 'sonicdrivein.com', ARRAY['sonic jr burger', 'sonic junior burger'], '340 cal per burger. {"sodium_mg":504,"cholesterol_mg":28,"sat_fat_g":4.72,"trans_fat_g":0.79}'),
('sonic_cheeseburger', 'Sonic Cheeseburger', 276.99, 12.68, 23.00, 14.55, 0.94, 4.69, 213, 213, 'sonicdrivein.com', ARRAY['sonic cheeseburger', 'sonic cheese burger'], '590 cal per burger. {"sodium_mg":577,"cholesterol_mg":38,"sat_fat_g":6.10,"trans_fat_g":0.47}'),
('sonic_burger', 'Sonic Burger', 310.00, 13.50, 24.50, 17.00, 1.00, 5.00, 200, 200, 'sonicdrivein.com', ARRAY['sonic burger', 'sonic hamburger'], '620 cal per burger. {"sodium_mg":540,"cholesterol_mg":35,"sat_fat_g":5.50,"trans_fat_g":0.50}'),
('sonic_supersonic_bacon_double', 'Sonic SuperSONIC Bacon Double Cheeseburger', 324.71, 16.38, 15.52, 21.55, 0.86, 3.45, 348, 348, 'sonicdrivein.com', ARRAY['sonic supersonic', 'supersonic burger', 'supersonic bacon double'], '1130 cal per burger. {"sodium_mg":589,"cholesterol_mg":56,"sat_fat_g":8.62,"trans_fat_g":1.15}'),
('sonic_chili_cheese_coney', 'Sonic Chili Cheese Coney (6 in)', 268.57, 10.29, 19.43, 16.57, 1.14, 2.29, 175, 175, 'sonicdrivein.com', ARRAY['sonic coney', 'sonic chili cheese coney', 'chili cheese hot dog sonic'], '470 cal per 6" coney. {"sodium_mg":709,"cholesterol_mg":31,"sat_fat_g":6.86,"trans_fat_g":0.0}'),
('sonic_all_american_hot_dog', 'Sonic All-American Hot Dog', 283.33, 9.17, 21.67, 17.50, 0.83, 4.17, 120, 120, 'sonicdrivein.com', ARRAY['sonic hot dog', 'sonic all american'], '340 cal per hot dog. {"sodium_mg":775,"cholesterol_mg":33,"sat_fat_g":6.67,"trans_fat_g":0.0}'),
('sonic_corn_dog', 'Sonic Corn Dog', 306.67, 9.33, 30.67, 17.33, 1.33, 8.00, 75, 75, 'sonicdrivein.com', ARRAY['sonic corn dog', 'corn dog sonic'], '230 cal per corn dog. {"sodium_mg":747,"cholesterol_mg":27,"sat_fat_g":5.33,"trans_fat_g":0.0}'),
('sonic_crispy_chicken_sandwich', 'Sonic Crispy Chicken Sandwich', 271.79, 10.26, 26.67, 13.85, 1.03, 4.62, 195, 195, 'sonicdrivein.com', ARRAY['sonic chicken sandwich', 'crispy chicken sonic'], '530 cal per sandwich. {"sodium_mg":610,"cholesterol_mg":18,"sat_fat_g":2.56,"trans_fat_g":0.0}'),
('sonic_grilled_chicken_sandwich', 'Sonic Grilled Chicken Sandwich', 225.64, 16.92, 18.97, 9.23, 1.03, 4.10, 195, 195, 'sonicdrivein.com', ARRAY['sonic grilled chicken', 'grilled chicken sonic'], '440 cal per sandwich. {"sodium_mg":544,"cholesterol_mg":46,"sat_fat_g":2.05,"trans_fat_g":0.0}'),
('sonic_french_fries_medium', 'Sonic French Fries (Medium)', 300.00, 3.33, 40.00, 14.17, 2.50, 0.00, 120, 120, 'sonicdrivein.com', ARRAY['sonic fries', 'sonic french fries', 'fries sonic'], '360 cal per medium. {"sodium_mg":450,"cholesterol_mg":0,"sat_fat_g":2.08,"trans_fat_g":0.0}'),
('sonic_onion_rings', 'Sonic Onion Rings (Medium)', 309.68, 3.87, 33.55, 18.06, 1.94, 3.23, 155, 155, 'sonicdrivein.com', ARRAY['sonic onion rings', 'onion rings sonic'], '480 cal per medium. {"sodium_mg":426,"cholesterol_mg":0,"sat_fat_g":3.23,"trans_fat_g":0.0}'),
('sonic_tots', 'Sonic Tater Tots (Medium)', 325.00, 2.50, 38.33, 17.50, 2.50, 0.00, 120, 120, 'sonicdrivein.com', ARRAY['sonic tots', 'sonic tater tots', 'tots sonic'], '390 cal per medium. {"sodium_mg":567,"cholesterol_mg":0,"sat_fat_g":2.92,"trans_fat_g":0.0}'),
('sonic_mozzarella_sticks', 'Sonic Mozzarella Sticks', 370.00, 14.00, 31.00, 21.00, 2.00, 2.00, 100, 100, 'sonicdrivein.com', ARRAY['sonic mozz sticks', 'sonic mozzarella sticks'], '370 cal per order. {"sodium_mg":890,"cholesterol_mg":30,"sat_fat_g":8.00,"trans_fat_g":0.0}'),
('sonic_breakfast_burrito_sausage', 'Sonic Breakfast Burrito (Sausage)', 250.00, 9.00, 19.50, 14.50, 1.00, 1.50, 200, 200, 'sonicdrivein.com', ARRAY['sonic breakfast burrito', 'sonic sausage burrito'], '500 cal per burrito. {"sodium_mg":585,"cholesterol_mg":88,"sat_fat_g":5.00,"trans_fat_g":0.0}'),
('sonic_croissonic_bacon', 'Sonic CroisSONIC Breakfast Sandwich (Bacon)', 275.68, 10.81, 18.92, 17.30, 0.54, 2.70, 185, 185, 'sonicdrivein.com', ARRAY['sonic croissonic', 'sonic breakfast croissant', 'croissonic bacon'], '510 cal per sandwich. {"sodium_mg":541,"cholesterol_mg":105,"sat_fat_g":7.03,"trans_fat_g":0.0}'),
('sonic_vanilla_shake', 'Sonic Vanilla Shake (Medium)', 128.57, 2.38, 20.71, 4.29, 0.00, 17.14, 420, 420, 'sonicdrivein.com', ARRAY['sonic vanilla shake', 'sonic milkshake', 'vanilla shake sonic'], '540 cal per medium. {"sodium_mg":88,"cholesterol_mg":14,"sat_fat_g":2.86,"trans_fat_g":0.0}'),
('sonic_chocolate_shake', 'Sonic Chocolate Shake (Medium)', 134.88, 2.33, 22.09, 4.19, 0.23, 18.37, 430, 430, 'sonicdrivein.com', ARRAY['sonic chocolate shake', 'chocolate shake sonic'], '580 cal per medium. {"sodium_mg":98,"cholesterol_mg":14,"sat_fat_g":2.79,"trans_fat_g":0.0}'),
('sonic_classic_limeade', 'Sonic Classic Limeade (Medium)', 44.44, 0.00, 11.78, 0.00, 0.00, 11.33, 450, 450, 'sonicdrivein.com', ARRAY['sonic limeade', 'limeade sonic'], '200 cal per medium. {"sodium_mg":9,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('sonic_ocean_water', 'Sonic Ocean Water (Medium)', 44.44, 0.00, 11.33, 0.00, 0.00, 11.33, 450, 450, 'sonicdrivein.com', ARRAY['sonic ocean water', 'ocean water sonic', 'blue coconut drink'], '200 cal per medium. {"sodium_mg":8,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('panera_broccoli_cheddar_soup_bowl', 'Panera Bread Broccoli Cheddar Soup (Bowl)', 102.86, 4.00, 8.00, 6.00, 0.86, 1.71, 350, 350, 'panerabread.com', ARRAY['panera broccoli soup', 'panera broccoli cheddar', 'broccoli cheddar soup panera'], '360 cal per bowl. {"sodium_mg":311,"cholesterol_mg":16,"sat_fat_g":3.43,"trans_fat_g":0.0}'),
('panera_broccoli_cheddar_soup_cup', 'Panera Bread Broccoli Cheddar Soup (Cup)', 95.83, 3.75, 7.50, 5.42, 0.83, 1.67, 240, 240, 'panerabread.com', ARRAY['panera broccoli soup cup', 'panera broccoli cheddar cup'], '230 cal per cup. {"sodium_mg":292,"cholesterol_mg":15,"sat_fat_g":3.33,"trans_fat_g":0.0}'),
('panera_broccoli_cheddar_bread_bowl', 'Panera Bread Broccoli Cheddar Soup (Bread Bowl)', 169.81, 6.60, 25.28, 3.40, 1.51, 1.89, 530, 530, 'panerabread.com', ARRAY['panera bread bowl', 'panera broccoli bread bowl', 'bread bowl panera'], '900 cal per bread bowl. {"sodium_mg":355,"cholesterol_mg":11,"sat_fat_g":2.64,"trans_fat_g":0.0}'),
('panera_chicken_noodle_soup_cup', 'Panera Bread Chicken Noodle Soup (Cup)', 54.17, 5.00, 5.42, 1.67, 0.00, 1.67, 240, 240, 'panerabread.com', ARRAY['panera chicken noodle', 'panera chicken soup', 'chicken noodle panera'], '130 cal per cup. {"sodium_mg":400,"cholesterol_mg":17,"sat_fat_g":0.42,"trans_fat_g":0.0}'),
('panera_chicken_noodle_soup_bowl', 'Panera Bread Chicken Noodle Soup (Bowl)', 57.14, 5.14, 5.43, 1.71, 0.29, 1.71, 350, 350, 'panerabread.com', ARRAY['panera chicken noodle bowl', 'chicken soup panera bowl'], '200 cal per bowl. {"sodium_mg":423,"cholesterol_mg":17,"sat_fat_g":0.43,"trans_fat_g":0.0}'),
('panera_creamy_tomato_soup_cup', 'Panera Bread Creamy Tomato Soup (Cup)', 112.50, 1.67, 10.83, 7.08, 0.83, 5.42, 240, 240, 'panerabread.com', ARRAY['panera tomato soup', 'panera cream of tomato', 'creamy tomato panera'], '270 cal per cup. {"sodium_mg":342,"cholesterol_mg":15,"sat_fat_g":3.75,"trans_fat_g":0.0}'),
('panera_creamy_tomato_soup_bowl', 'Panera Bread Creamy Tomato Soup (Bowl)', 120.00, 1.71, 11.43, 7.43, 0.86, 5.71, 350, 350, 'panerabread.com', ARRAY['panera tomato soup bowl', 'creamy tomato panera bowl'], '420 cal per bowl. {"sodium_mg":360,"cholesterol_mg":16,"sat_fat_g":4.00,"trans_fat_g":0.0}'),
('panera_mac_cheese_small', 'Panera Bread Mac & Cheese (Small)', 191.30, 7.39, 17.83, 10.00, 0.87, 1.30, 230, 230, 'panerabread.com', ARRAY['panera mac and cheese', 'panera mac cheese', 'mac and cheese panera'], '440 cal per small. {"sodium_mg":461,"cholesterol_mg":22,"sat_fat_g":5.65,"trans_fat_g":0.0}'),
('panera_mac_cheese_large', 'Panera Bread Mac & Cheese (Large)', 192.11, 7.37, 17.89, 10.00, 0.79, 1.32, 380, 380, 'panerabread.com', ARRAY['panera mac and cheese large', 'panera mac cheese large'], '730 cal per large. {"sodium_mg":463,"cholesterol_mg":21,"sat_fat_g":5.53,"trans_fat_g":0.0}'),
('panera_turkey_cheddar_sandwich', 'Panera Bread Turkey & Cheddar Sandwich', 195.00, 10.25, 13.00, 11.25, 0.75, 1.25, 400, 400, 'panerabread.com', ARRAY['panera turkey sandwich', 'panera turkey cheddar', 'turkey sandwich panera'], '780 cal per whole sandwich. {"sodium_mg":423,"cholesterol_mg":25,"sat_fat_g":3.50,"trans_fat_g":0.0}'),
('panera_turkey_apple_cheddar', 'Panera Bread Roasted Turkey, Apple & Cheddar Sandwich', 186.84, 9.21, 19.21, 7.63, 1.05, 4.74, 380, 380, 'panerabread.com', ARRAY['panera turkey apple', 'panera turkey apple cheddar', 'turkey apple sandwich panera'], '710 cal per whole sandwich. {"sodium_mg":458,"cholesterol_mg":22,"sat_fat_g":2.89,"trans_fat_g":0.0}'),
('panera_chipotle_chicken_avocado', 'Panera Bread Chipotle Chicken Avocado Melt', 220.00, 10.75, 18.00, 11.50, 1.50, 2.25, 400, 400, 'panerabread.com', ARRAY['panera chipotle chicken', 'panera chicken avocado', 'chipotle avocado panera'], '880 cal per whole sandwich. {"sodium_mg":523,"cholesterol_mg":25,"sat_fat_g":4.00,"trans_fat_g":0.0}'),
('panera_grilled_cheese', 'Panera Bread Classic Grilled Cheese', 233.33, 8.75, 22.92, 11.67, 0.83, 2.08, 240, 240, 'panerabread.com', ARRAY['panera grilled cheese', 'grilled cheese panera'], '560 cal per whole sandwich. {"sodium_mg":496,"cholesterol_mg":25,"sat_fat_g":6.25,"trans_fat_g":0.0}'),
('panera_bacon_egg_cheese_ciabatta', 'Panera Bread Bacon, Egg & Cheese on Ciabatta', 213.64, 10.00, 23.18, 9.09, 0.91, 2.27, 220, 220, 'panerabread.com', ARRAY['panera bacon egg cheese', 'panera breakfast sandwich', 'bacon egg cheese panera'], '470 cal per sandwich. {"sodium_mg":455,"cholesterol_mg":93,"sat_fat_g":3.64,"trans_fat_g":0.0}'),
('panera_caesar_salad', 'Panera Bread Caesar Salad', 137.50, 4.58, 9.17, 9.58, 1.25, 1.25, 240, 240, 'panerabread.com', ARRAY['panera caesar salad', 'caesar salad panera'], '330 cal per whole salad. {"sodium_mg":288,"cholesterol_mg":10,"sat_fat_g":2.08,"trans_fat_g":0.0}'),
('panera_fuji_apple_chicken_salad', 'Panera Bread Fuji Apple Salad with Chicken', 152.78, 8.61, 11.94, 8.06, 1.39, 5.83, 360, 360, 'panerabread.com', ARRAY['panera fuji apple salad', 'panera chicken salad', 'fuji apple salad panera'], '550 cal per whole salad. {"sodium_mg":258,"cholesterol_mg":24,"sat_fat_g":2.22,"trans_fat_g":0.0}'),
('panera_chocolate_chipper_cookie', 'Panera Bread Chocolate Chipper Cookie', 448.98, 5.10, 60.20, 22.45, 2.04, 35.71, 98, 98, 'panerabread.com', ARRAY['panera cookie', 'panera chocolate chip cookie', 'chocolate chipper panera'], '440 cal per cookie. {"sodium_mg":316,"cholesterol_mg":46,"sat_fat_g":13.27,"trans_fat_g":0.0}'),
('panera_cinnamon_crunch_bagel', 'Panera Bread Cinnamon Crunch Bagel', 371.68, 7.96, 64.60, 8.85, 1.77, 24.78, 113, 113, 'panerabread.com', ARRAY['panera cinnamon bagel', 'cinnamon crunch bagel panera', 'panera bagel'], '420 cal per bagel. {"sodium_mg":398,"cholesterol_mg":0,"sat_fat_g":3.10,"trans_fat_g":0.0}'),
('panera_plain_bagel', 'Panera Bread Plain Bagel', 278.85, 10.58, 55.77, 0.96, 1.92, 5.77, 104, 104, 'panerabread.com', ARRAY['panera plain bagel', 'bagel panera'], '290 cal per bagel. {"sodium_mg":481,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('panera_french_baguette', 'Panera Bread French Baguette (Quarter)', 270.00, 10.00, 54.00, 1.00, 2.00, 1.00, 100, 100, 'panerabread.com', ARRAY['panera baguette', 'panera french bread', 'french baguette panera'], '270 cal per quarter baguette. {"sodium_mg":640,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('jack_in_the_box_jumbo_jack', 'Jack in the Box Jumbo Jack', 214.91, 11.40, 19.30, 10.09, 0.88, 3.95, 228, 228, 'jackinthebox.com', ARRAY['jumbo jack', 'jack in the box jumbo jack', 'jitb jumbo jack'], '490 cal per burger. {"sodium_mg":338,"cholesterol_mg":24,"sat_fat_g":3.51,"trans_fat_g":0.44}'),
('jack_in_the_box_jumbo_jack_cheese', 'Jack in the Box Jumbo Jack with Cheese', 226.19, 11.90, 17.46, 11.90, 0.79, 3.57, 252, 252, 'jackinthebox.com', ARRAY['jumbo jack with cheese', 'jumbo jack cheese'], '570 cal per burger. {"sodium_mg":421,"cholesterol_mg":32,"sat_fat_g":5.16,"trans_fat_g":0.40}'),
('jack_in_the_box_hamburger', 'Jack in the Box Hamburger', 235.29, 11.76, 26.89, 9.24, 0.84, 5.04, 119, 119, 'jackinthebox.com', ARRAY['jack in the box hamburger', 'jitb hamburger'], '280 cal per burger. {"sodium_mg":412,"cholesterol_mg":25,"sat_fat_g":3.36,"trans_fat_g":0.42}'),
('jack_in_the_box_classic_buttery_jack', 'Jack in the Box Classic Buttery Jack', 294.96, 13.31, 17.99, 18.71, 0.72, 3.60, 278, 278, 'jackinthebox.com', ARRAY['buttery jack', 'classic buttery jack', 'jitb buttery jack'], '820 cal per burger. {"sodium_mg":450,"cholesterol_mg":47,"sat_fat_g":7.55,"trans_fat_g":0.72}'),
('jack_in_the_box_bacon_ultimate', 'Jack in the Box Bacon Ultimate Cheeseburger', 299.34, 18.75, 14.47, 18.42, 0.66, 3.29, 304, 304, 'jackinthebox.com', ARRAY['bacon ultimate cheeseburger', 'jitb bacon ultimate'], '910 cal per burger. {"sodium_mg":539,"cholesterol_mg":56,"sat_fat_g":7.89,"trans_fat_g":0.66}'),
('jack_in_the_box_sourdough_jack', 'Jack in the Box Sourdough Jack', 271.60, 12.35, 22.63, 14.40, 1.23, 4.12, 243, 243, 'jackinthebox.com', ARRAY['sourdough jack', 'jitb sourdough'], '660 cal per burger. {"sodium_mg":535,"cholesterol_mg":35,"sat_fat_g":5.35,"trans_fat_g":0.41}'),
('jack_in_the_box_beef_taco', 'Jack in the Box Beef Taco', 316.67, 10.00, 26.67, 18.33, 3.33, 1.67, 60, 60, 'jackinthebox.com', ARRAY['jack in the box taco', 'jitb taco', 'jack taco'], '190 cal per taco. {"sodium_mg":517,"cholesterol_mg":25,"sat_fat_g":5.83,"trans_fat_g":0.83}'),
('jack_in_the_box_monster_taco', 'Jack in the Box Monster Taco', 408.70, 11.30, 33.04, 26.09, 3.48, 2.61, 115, 115, 'jackinthebox.com', ARRAY['monster taco jitb', 'jack monster taco'], '470 cal per taco. {"sodium_mg":635,"cholesterol_mg":26,"sat_fat_g":7.83,"trans_fat_g":0.87}'),
('jack_in_the_box_cluck_sandwich', 'Jack in the Box Cluck Sandwich', 245.00, 13.50, 24.00, 10.50, 1.00, 3.50, 200, 200, 'jackinthebox.com', ARRAY['cluck sandwich jitb', 'jack chicken sandwich'], '490 cal per sandwich. {"sodium_mg":535,"cholesterol_mg":25,"sat_fat_g":2.00,"trans_fat_g":0.0}'),
('jack_in_the_box_spicy_chicken', 'Jack in the Box Spicy Chicken Sandwich', 243.12, 11.47, 25.23, 10.55, 1.38, 3.67, 218, 218, 'jackinthebox.com', ARRAY['spicy chicken jitb', 'jacks spicy chicken'], '530 cal per sandwich. {"sodium_mg":518,"cholesterol_mg":18,"sat_fat_g":1.83,"trans_fat_g":0.0}'),
('jack_in_the_box_chicken_nuggets', 'Jack in the Box Chicken Nuggets (10 pc)', 272.73, 13.33, 18.18, 15.76, 1.21, 0.00, 165, 165, 'jackinthebox.com', ARRAY['jitb nuggets', 'jack nuggets', 'chicken nuggets jack in the box'], '450 cal per 10 nuggets. {"sodium_mg":600,"cholesterol_mg":30,"sat_fat_g":3.03,"trans_fat_g":0.0}'),
('jack_in_the_box_breakfast_jack', 'Jack in the Box Breakfast Jack', 224.00, 12.80, 20.80, 9.60, 0.00, 2.40, 125, 125, 'jackinthebox.com', ARRAY['breakfast jack', 'jitb breakfast jack', 'jack breakfast sandwich'], '280 cal per sandwich. {"sodium_mg":568,"cholesterol_mg":160,"sat_fat_g":4.00,"trans_fat_g":0.0}'),
('jack_in_the_box_grande_sausage_burrito', 'Jack in the Box Grande Sausage Breakfast Burrito', 315.15, 12.12, 24.24, 18.18, 1.21, 1.52, 330, 330, 'jackinthebox.com', ARRAY['grande sausage burrito', 'jitb grande burrito', 'jack grande burrito'], '1040 cal per burrito. {"sodium_mg":685,"cholesterol_mg":130,"sat_fat_g":6.67,"trans_fat_g":0.61}'),
('jack_in_the_box_curly_fries', 'Jack in the Box Seasoned Curly Fries (Medium)', 292.31, 3.85, 32.31, 16.92, 3.08, 0.00, 130, 130, 'jackinthebox.com', ARRAY['jitb curly fries', 'jack curly fries', 'seasoned curly fries'], '380 cal per medium. {"sodium_mg":646,"cholesterol_mg":0,"sat_fat_g":3.08,"trans_fat_g":0.0}'),
('jack_in_the_box_french_fries', 'Jack in the Box French Fries (Medium)', 275.00, 3.33, 36.67, 12.50, 2.50, 0.00, 120, 120, 'jackinthebox.com', ARRAY['jitb fries', 'jack fries', 'french fries jack'], '330 cal per medium. {"sodium_mg":358,"cholesterol_mg":0,"sat_fat_g":2.08,"trans_fat_g":0.0}'),
('jack_in_the_box_egg_rolls', 'Jack in the Box Egg Rolls (3 pc)', 300.00, 8.42, 33.68, 14.74, 2.11, 4.21, 190, 190, 'jackinthebox.com', ARRAY['jitb egg rolls', 'jack egg rolls', 'jumbo egg rolls'], '570 cal per 3 egg rolls. {"sodium_mg":705,"cholesterol_mg":13,"sat_fat_g":2.63,"trans_fat_g":0.0}'),
('jack_in_the_box_tiny_tacos', 'Jack in the Box Tiny Tacos (10 pc)', 350.00, 12.00, 30.00, 20.00, 3.00, 2.00, 100, 100, 'jackinthebox.com', ARRAY['tiny tacos jitb', 'jack tiny tacos'], '350 cal per 10 tacos. {"sodium_mg":600,"cholesterol_mg":25,"sat_fat_g":5.00,"trans_fat_g":0.0}'),
('jack_in_the_box_oreo_shake', 'Jack in the Box Oreo Cookie Shake (Medium)', 170.53, 3.58, 24.42, 6.74, 0.21, 19.37, 475, 475, 'jackinthebox.com', ARRAY['jitb oreo shake', 'jack shake', 'oreo shake jack in the box'], '810 cal per medium. {"sodium_mg":107,"cholesterol_mg":20,"sat_fat_g":4.42,"trans_fat_g":0.0}'),
('whataburger_original', 'Whataburger', 186.71, 9.18, 19.62, 7.91, 1.27, 3.80, 316, 316, 'whataburger.com', ARRAY['whataburger', 'whataburger original', 'whataburger classic'], '590 cal per burger. {"sodium_mg":386,"cholesterol_mg":14,"sat_fat_g":2.53,"trans_fat_g":0.32}'),
('whataburger_jr', 'Whataburger Jr.', 206.06, 9.70, 20.61, 9.09, 1.21, 3.64, 165, 165, 'whataburger.com', ARRAY['whataburger jr', 'whataburger junior'], '340 cal per burger. {"sodium_mg":442,"cholesterol_mg":18,"sat_fat_g":3.03,"trans_fat_g":0.30}'),
('whataburger_double_meat', 'Whataburger Double Meat', 200.48, 11.22, 14.80, 9.79, 0.95, 2.86, 419, 419, 'whataburger.com', ARRAY['whataburger double', 'double meat whataburger'], '840 cal per burger. {"sodium_mg":380,"cholesterol_mg":26,"sat_fat_g":3.58,"trans_fat_g":0.48}'),
('whataburger_triple_meat', 'Whataburger Triple Meat', 205.77, 12.50, 11.92, 10.96, 0.77, 2.31, 520, 520, 'whataburger.com', ARRAY['whataburger triple', 'triple meat whataburger'], '1070 cal per burger. {"sodium_mg":375,"cholesterol_mg":34,"sat_fat_g":4.23,"trans_fat_g":0.58}'),
('whataburger_patty_melt', 'Whataburger Patty Melt', 241.94, 10.97, 18.71, 12.90, 0.97, 2.58, 310, 310, 'whataburger.com', ARRAY['whataburger patty melt', 'patty melt whataburger'], '750 cal per sandwich. {"sodium_mg":484,"cholesterol_mg":32,"sat_fat_g":5.16,"trans_fat_g":0.48}'),
('whataburger_honey_bbq_chicken_strip', 'Whataburger Honey BBQ Chicken Strip Sandwich', 260.71, 12.14, 26.07, 11.43, 1.07, 6.07, 280, 280, 'whataburger.com', ARRAY['whataburger honey bbq', 'honey bbq chicken whataburger'], '730 cal per sandwich. {"sodium_mg":589,"cholesterol_mg":23,"sat_fat_g":2.50,"trans_fat_g":0.0}'),
('whataburger_spicy_chicken_sandwich', 'Whataburger Spicy Chicken Sandwich', 216.00, 11.20, 22.00, 8.40, 1.20, 2.80, 250, 250, 'whataburger.com', ARRAY['whataburger spicy chicken', 'spicy chicken whataburger'], '540 cal per sandwich. {"sodium_mg":552,"cholesterol_mg":20,"sat_fat_g":1.60,"trans_fat_g":0.0}'),
('whataburger_grilled_chicken', 'Whataburger Grilled Chicken Sandwich', 169.23, 12.69, 16.15, 5.38, 1.15, 2.69, 260, 260, 'whataburger.com', ARRAY['whataburger grilled chicken', 'grilled chicken whataburger'], '440 cal per sandwich. {"sodium_mg":465,"cholesterol_mg":35,"sat_fat_g":1.15,"trans_fat_g":0.0}'),
('whataburger_chicken_strips', 'Whataburger Chicken Strips (3 pc)', 346.15, 21.54, 21.54, 18.46, 0.77, 0.00, 130, 130, 'whataburger.com', ARRAY['whataburger chicken strips', 'chicken strips whataburger', 'whatachickn'], '450 cal per 3 strips. {"sodium_mg":1015,"cholesterol_mg":42,"sat_fat_g":3.08,"trans_fat_g":0.0}'),
('whataburger_honey_butter_chicken_biscuit', 'Whataburger Honey Butter Chicken Biscuit', 358.97, 8.33, 32.69, 21.15, 1.28, 5.77, 156, 156, 'whataburger.com', ARRAY['whataburger hbcb', 'honey butter chicken biscuit', 'hbcb whataburger'], '560 cal per biscuit. {"sodium_mg":673,"cholesterol_mg":19,"sat_fat_g":7.69,"trans_fat_g":0.0}'),
('whataburger_breakfast_on_bun_sausage', 'Whataburger Breakfast on a Bun (Sausage)', 292.55, 11.70, 18.62, 18.09, 0.53, 2.13, 188, 188, 'whataburger.com', ARRAY['whataburger breakfast on a bun', 'whataburger bob sausage', 'breakfast bun whataburger'], '550 cal per sandwich. {"sodium_mg":596,"cholesterol_mg":133,"sat_fat_g":6.91,"trans_fat_g":0.0}'),
('whataburger_sausage_egg_cheese_biscuit', 'Whataburger Sausage, Egg & Cheese Biscuit', 328.57, 11.90, 20.48, 20.95, 0.48, 1.43, 210, 210, 'whataburger.com', ARRAY['whataburger sausage biscuit', 'sausage egg cheese biscuit whataburger'], '690 cal per biscuit sandwich. {"sodium_mg":781,"cholesterol_mg":129,"sat_fat_g":8.57,"trans_fat_g":0.0}'),
('whataburger_french_fries', 'Whataburger French Fries (Medium)', 307.69, 3.85, 39.23, 15.38, 3.08, 0.00, 130, 130, 'whataburger.com', ARRAY['whataburger fries', 'french fries whataburger'], '400 cal per medium. {"sodium_mg":215,"cholesterol_mg":0,"sat_fat_g":2.31,"trans_fat_g":0.0}'),
('whataburger_onion_rings', 'Whataburger Onion Rings (Medium)', 315.38, 3.85, 35.38, 17.69, 1.54, 3.08, 130, 130, 'whataburger.com', ARRAY['whataburger onion rings', 'onion rings whataburger'], '410 cal per medium. {"sodium_mg":662,"cholesterol_mg":0,"sat_fat_g":3.08,"trans_fat_g":0.0}'),
('whataburger_bacon_cheese', 'Whataburger Bacon & Cheese', 217.63, 11.02, 17.08, 10.74, 1.10, 3.31, 363, 363, 'whataburger.com', ARRAY['whataburger bacon cheese', 'bacon cheese whataburger'], '790 cal per burger. {"sodium_mg":466,"cholesterol_mg":26,"sat_fat_g":4.13,"trans_fat_g":0.41}'),
('panda_express_orange_chicken', 'Panda Express Orange Chicken', 228.40, 11.73, 23.46, 10.49, 0.62, 8.64, 162, 162, 'pandaexpress.com', ARRAY['panda orange chicken', 'orange chicken panda express'], '370 cal per entree. {"sodium_mg":383,"cholesterol_mg":37,"sat_fat_g":1.85,"trans_fat_g":0.0}'),
('panda_express_kung_pao_chicken', 'Panda Express Kung Pao Chicken', 164.77, 9.09, 7.95, 10.80, 1.14, 3.41, 176, 176, 'pandaexpress.com', ARRAY['panda kung pao', 'kung pao chicken panda express'], '290 cal per entree. {"sodium_mg":551,"cholesterol_mg":31,"sat_fat_g":1.99,"trans_fat_g":0.0}'),
('panda_express_broccoli_beef', 'Panda Express Broccoli Beef', 98.04, 5.88, 8.50, 4.58, 1.31, 4.58, 153, 153, 'pandaexpress.com', ARRAY['panda broccoli beef', 'broccoli beef panda express'], '150 cal per entree. {"sodium_mg":340,"cholesterol_mg":8,"sat_fat_g":0.98,"trans_fat_g":0.0}'),
('panda_express_beijing_beef', 'Panda Express Beijing Beef', 261.11, 8.89, 23.33, 14.44, 0.56, 10.56, 180, 180, 'pandaexpress.com', ARRAY['panda beijing beef', 'beijing beef panda express'], '470 cal per entree. {"sodium_mg":367,"cholesterol_mg":19,"sat_fat_g":2.78,"trans_fat_g":0.0}'),
('panda_express_honey_walnut_shrimp', 'Panda Express Honey Walnut Shrimp', 222.22, 8.02, 16.67, 14.20, 0.62, 8.64, 162, 162, 'pandaexpress.com', ARRAY['panda honey walnut shrimp', 'honey walnut shrimp panda'], '360 cal per entree. {"sodium_mg":272,"cholesterol_mg":34,"sat_fat_g":2.47,"trans_fat_g":0.0}'),
('panda_express_grilled_teriyaki_chicken', 'Panda Express Grilled Teriyaki Chicken', 196.08, 23.53, 5.23, 8.50, 0.00, 3.27, 153, 153, 'pandaexpress.com', ARRAY['panda teriyaki chicken', 'grilled teriyaki panda express'], '300 cal per entree. {"sodium_mg":346,"cholesterol_mg":78,"sat_fat_g":1.96,"trans_fat_g":0.0}'),
('panda_express_string_bean_chicken', 'Panda Express String Bean Chicken Breast', 117.28, 8.64, 8.02, 5.56, 1.23, 3.70, 162, 162, 'pandaexpress.com', ARRAY['panda string bean chicken', 'string bean chicken panda'], '190 cal per entree. {"sodium_mg":457,"cholesterol_mg":25,"sat_fat_g":1.23,"trans_fat_g":0.0}'),
('panda_express_mushroom_chicken', 'Panda Express Mushroom Chicken', 135.80, 8.64, 6.17, 8.02, 0.62, 3.09, 162, 162, 'pandaexpress.com', ARRAY['panda mushroom chicken', 'mushroom chicken panda express'], '220 cal per entree. {"sodium_mg":469,"cholesterol_mg":31,"sat_fat_g":1.54,"trans_fat_g":0.0}'),
('panda_express_sweetfire_chicken', 'Panda Express SweetFire Chicken Breast', 234.57, 9.88, 27.16, 9.26, 0.62, 12.35, 162, 162, 'pandaexpress.com', ARRAY['panda sweetfire chicken', 'sweetfire chicken panda express'], '380 cal per entree. {"sodium_mg":228,"cholesterol_mg":25,"sat_fat_g":1.54,"trans_fat_g":0.0}'),
('panda_express_honey_sesame_chicken', 'Panda Express Honey Sesame Chicken Breast', 278.41, 10.80, 32.39, 11.93, 1.14, 15.91, 176, 176, 'pandaexpress.com', ARRAY['panda honey sesame', 'honey sesame chicken panda'], '490 cal per entree. {"sodium_mg":330,"cholesterol_mg":28,"sat_fat_g":1.99,"trans_fat_g":0.0}'),
('panda_express_black_pepper_chicken', 'Panda Express Black Pepper Chicken', 172.84, 9.26, 11.73, 9.26, 1.23, 6.17, 162, 162, 'pandaexpress.com', ARRAY['panda black pepper chicken', 'black pepper chicken panda'], '280 cal per entree. {"sodium_mg":451,"cholesterol_mg":28,"sat_fat_g":1.85,"trans_fat_g":0.0}'),
('panda_express_sweet_sour_chicken', 'Panda Express Sweet & Sour Chicken Breast', 185.19, 8.02, 20.99, 8.02, 0.00, 10.49, 162, 162, 'pandaexpress.com', ARRAY['panda sweet and sour', 'sweet sour chicken panda'], '300 cal per entree. {"sodium_mg":160,"cholesterol_mg":22,"sat_fat_g":1.23,"trans_fat_g":0.0}'),
('panda_express_chow_mein', 'Panda Express Chow Mein', 191.73, 4.89, 30.08, 7.52, 2.26, 3.38, 266, 266, 'pandaexpress.com', ARRAY['panda chow mein', 'chow mein panda express'], '510 cal per side. {"sodium_mg":323,"cholesterol_mg":0,"sat_fat_g":1.32,"trans_fat_g":0.0}'),
('panda_express_fried_rice', 'Panda Express Fried Rice', 196.97, 4.17, 32.20, 6.06, 0.38, 1.14, 264, 264, 'pandaexpress.com', ARRAY['panda fried rice', 'fried rice panda express'], '520 cal per side. {"sodium_mg":322,"cholesterol_mg":45,"sat_fat_g":1.14,"trans_fat_g":0.0}'),
('panda_express_steamed_white_rice', 'Panda Express Steamed White Rice', 150.79, 2.78, 34.52, 0.00, 0.00, 0.00, 252, 252, 'pandaexpress.com', ARRAY['panda white rice', 'steamed rice panda express'], '380 cal per side. {"sodium_mg":0,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('panda_express_super_greens', 'Panda Express Super Greens', 45.45, 3.03, 5.05, 1.52, 2.02, 1.52, 198, 198, 'pandaexpress.com', ARRAY['panda super greens', 'super greens panda express', 'mixed veggies panda'], '90 cal per side. {"sodium_mg":162,"cholesterol_mg":0,"sat_fat_g":0.25,"trans_fat_g":0.0}'),
('panda_express_chicken_egg_roll', 'Panda Express Chicken Egg Roll', 235.29, 9.41, 23.53, 10.59, 2.35, 2.35, 85, 85, 'pandaexpress.com', ARRAY['panda egg roll', 'egg roll panda express'], '200 cal per roll. {"sodium_mg":459,"cholesterol_mg":18,"sat_fat_g":2.35,"trans_fat_g":0.0}'),
('panda_express_cream_cheese_rangoon', 'Panda Express Cream Cheese Rangoon (3 pc)', 211.11, 5.56, 26.67, 8.89, 0.00, 1.11, 90, 90, 'pandaexpress.com', ARRAY['panda rangoon', 'cream cheese rangoon panda', 'crab rangoon panda'], '190 cal per 3 pieces. {"sodium_mg":200,"cholesterol_mg":17,"sat_fat_g":5.56,"trans_fat_g":0.0}'),
('panda_express_chicken_potsticker', 'Panda Express Chicken Potsticker (3 pc)', 220.00, 9.00, 24.00, 9.00, 1.00, 2.00, 100, 100, 'pandaexpress.com', ARRAY['panda potsticker', 'potsticker panda express', 'panda dumpling'], '220 cal per 3 potstickers. {"sodium_mg":340,"cholesterol_mg":20,"sat_fat_g":2.00,"trans_fat_g":0.0}'),
('five_guys_hamburger', 'Five Guys Hamburger', 264.15, 14.72, 14.72, 16.23, 0.75, 3.02, 265, 265, 'fiveguys.com', ARRAY['five guys burger', 'five guys hamburger', '5 guys burger'], '700 cal per burger. {"sodium_mg":162,"cholesterol_mg":47,"sat_fat_g":7.55,"trans_fat_g":0.0}'),
('five_guys_little_hamburger', 'Five Guys Little Hamburger', 280.70, 13.45, 22.81, 15.20, 1.17, 4.68, 171, 171, 'fiveguys.com', ARRAY['five guys little burger', 'five guys small burger', '5 guys little burger'], '480 cal per burger. {"sodium_mg":222,"cholesterol_mg":38,"sat_fat_g":7.02,"trans_fat_g":0.0}'),
('five_guys_cheeseburger', 'Five Guys Cheeseburger', 277.23, 15.51, 13.20, 18.15, 0.66, 2.97, 303, 303, 'fiveguys.com', ARRAY['five guys cheeseburger', '5 guys cheeseburger'], '840 cal per burger. {"sodium_mg":347,"cholesterol_mg":54,"sat_fat_g":8.58,"trans_fat_g":0.0}'),
('five_guys_little_cheeseburger', 'Five Guys Little Cheeseburger', 284.97, 13.99, 20.73, 16.58, 1.04, 4.66, 193, 193, 'fiveguys.com', ARRAY['five guys little cheeseburger', '5 guys little cheeseburger'], '550 cal per burger. {"sodium_mg":358,"cholesterol_mg":44,"sat_fat_g":8.29,"trans_fat_g":0.0}'),
('five_guys_bacon_cheeseburger', 'Five Guys Bacon Cheeseburger', 290.22, 16.09, 12.62, 19.56, 0.63, 2.84, 317, 317, 'fiveguys.com', ARRAY['five guys bacon cheeseburger', '5 guys bacon cheeseburger'], '920 cal per burger. {"sodium_mg":413,"cholesterol_mg":57,"sat_fat_g":9.46,"trans_fat_g":0.0}'),
('five_guys_bacon_burger', 'Five Guys Bacon Burger', 273.68, 15.79, 13.68, 17.54, 0.70, 2.81, 285, 285, 'fiveguys.com', ARRAY['five guys bacon burger', '5 guys bacon burger'], '780 cal per burger. {"sodium_mg":246,"cholesterol_mg":49,"sat_fat_g":8.07,"trans_fat_g":0.0}'),
('five_guys_hot_dog', 'Five Guys Hot Dog', 326.35, 10.78, 23.95, 20.96, 1.20, 4.79, 167, 167, 'fiveguys.com', ARRAY['five guys hot dog', '5 guys hot dog', 'five guys kosher hot dog'], '545 cal per hot dog. {"sodium_mg":677,"cholesterol_mg":37,"sat_fat_g":9.58,"trans_fat_g":0.0}'),
('five_guys_cheese_dog', 'Five Guys Cheese Dog', 315.38, 11.28, 21.03, 21.03, 1.03, 4.62, 195, 195, 'fiveguys.com', ARRAY['five guys cheese dog', '5 guys cheese dog'], '615 cal per cheese dog. {"sodium_mg":738,"cholesterol_mg":41,"sat_fat_g":10.26,"trans_fat_g":0.0}'),
('five_guys_bacon_dog', 'Five Guys Bacon Dog', 341.53, 12.02, 21.86, 22.95, 1.09, 4.37, 183, 183, 'fiveguys.com', ARRAY['five guys bacon dog', '5 guys bacon dog'], '625 cal per bacon dog. {"sodium_mg":765,"cholesterol_mg":41,"sat_fat_g":10.38,"trans_fat_g":0.0}'),
('five_guys_grilled_cheese', 'Five Guys Grilled Cheese', 235.00, 9.00, 20.50, 13.00, 1.00, 4.00, 200, 200, 'fiveguys.com', ARRAY['five guys grilled cheese', '5 guys grilled cheese'], '470 cal per sandwich. {"sodium_mg":358,"cholesterol_mg":25,"sat_fat_g":7.00,"trans_fat_g":0.0}'),
('five_guys_veggie_sandwich', 'Five Guys Veggie Sandwich', 140.00, 5.00, 19.50, 7.50, 1.50, 4.00, 200, 200, 'fiveguys.com', ARRAY['five guys veggie', '5 guys veggie sandwich'], '280 cal per sandwich. {"sodium_mg":210,"cholesterol_mg":0,"sat_fat_g":3.00,"trans_fat_g":0.0}'),
('five_guys_blt', 'Five Guys BLT', 280.00, 10.29, 22.29, 18.86, 1.14, 4.57, 175, 175, 'fiveguys.com', ARRAY['five guys blt', '5 guys blt'], '490 cal per sandwich. {"sodium_mg":474,"cholesterol_mg":23,"sat_fat_g":7.43,"trans_fat_g":0.0}'),
('five_guys_regular_fries', 'Five Guys Regular Fries', 150.85, 2.19, 18.98, 7.30, 1.70, 0.00, 411, 411, 'fiveguys.com', ARRAY['five guys fries', '5 guys fries', 'five guys regular fries'], '620 cal per regular. {"sodium_mg":22,"cholesterol_mg":0,"sat_fat_g":1.46,"trans_fat_g":0.0}'),
('five_guys_little_fries', 'Five Guys Little Fries', 232.60, 3.52, 29.96, 11.45, 2.64, 0.00, 227, 227, 'fiveguys.com', ARRAY['five guys small fries', '5 guys little fries'], '528 cal per small. {"sodium_mg":22,"cholesterol_mg":0,"sat_fat_g":2.20,"trans_fat_g":0.0}'),
('five_guys_cajun_fries', 'Five Guys Cajun Fries (Regular)', 150.85, 2.19, 18.98, 7.30, 1.70, 0.00, 411, 411, 'fiveguys.com', ARRAY['five guys cajun fries', '5 guys cajun fries'], '620 cal per regular. {"sodium_mg":165,"cholesterol_mg":0,"sat_fat_g":1.46,"trans_fat_g":0.0}'),
('five_guys_chocolate_shake', 'Five Guys Chocolate Milkshake', 176.84, 3.16, 17.47, 10.95, 0.42, 14.53, 475, 475, 'fiveguys.com', ARRAY['five guys chocolate shake', '5 guys milkshake', 'five guys shake'], '840 cal per regular. {"sodium_mg":72,"cholesterol_mg":33,"sat_fat_g":6.95,"trans_fat_g":0.0}'),
('five_guys_vanilla_shake', 'Five Guys Vanilla Milkshake', 148.89, 2.67, 15.33, 8.67, 0.00, 12.67, 450, 450, 'fiveguys.com', ARRAY['five guys vanilla shake', '5 guys vanilla shake'], '670 cal per regular. {"sodium_mg":69,"cholesterol_mg":28,"sat_fat_g":5.56,"trans_fat_g":0.0}'),
-- ============================================
-- BATCH 3: Restaurant Nutrition Data (WITH MICRONUTRIENTS)
-- Wingstop, Zaxby's, Little Caesars, Jimmy John's, Jersey Mike's,
-- Chili's, Applebee's, Olive Garden, Buffalo Wild Wings (expand), Red Robin (expand)
-- ============================================
-- ============================================
-- WINGSTOP
-- Source: wingstop.com, fatsecret.com
-- ============================================
-- ============================================
-- ZAXBY'S
-- Source: zaxbys.com, fatsecret.com
-- ============================================
-- ============================================
-- LITTLE CAESARS
-- Source: littlecaesars.com, fatsecret.com
-- ============================================
-- ============================================
-- JIMMY JOHN'S
-- Source: jimmyjohns.com, fatsecret.com
-- ============================================
-- ============================================
-- JERSEY MIKE'S
-- Source: jerseymikes.com, fatsecret.com
-- ============================================
-- ============================================
-- CHILI'S
-- Source: chilis.com, fatsecret.com, nutrition-charts.com
-- ============================================
-- ============================================
-- APPLEBEE'S
-- Source: applebees.com, fatsecret.com
-- ============================================
-- ============================================
-- OLIVE GARDEN
-- Source: olivegarden.com, fatsecret.com, olivegarden-menus.us
-- ============================================
-- ============================================
-- BUFFALO WILD WINGS (expand beyond existing 7 items)
-- Existing: bww_boneless_wings_12ct, bww_hatch_queso, bww_triple_bacon_cheeseburger,
-- bww_ultimate_sampler, bww_triple_choc_cookie_skillet, bww_parmesan_garlic_sauce, bww_bleu_cheese_dressing
-- Source: buffalowildwings.com, fatsecret.com
-- ============================================
-- ============================================
-- RED ROBIN (expand beyond existing 7 items)
-- Existing: red_robin_madlove_burger, red_robin_haystack_double, red_robin_a1_steakhouse_burger,
-- red_robin_cookie_dough_mudd_pie, red_robin_oreo_candy_cane_shake, red_robin_strawberry_milkshake, red_robin_creamy_milkshake
-- Source: redrobin.com, fatsecret.com
-- ============================================
('wingstop_classic_wings_plain_6pc', 'Wingstop Classic Wings Plain (6pc)', 290.3, 32.3, 0.0, 16.1, 0.0, 0.0, 186, 186, 'wingstop.com', ARRAY['wingstop plain wings', 'wingstop classic plain'], '540 cal total for 6pc. {"sodium_mg":96.8,"cholesterol_mg":145.2,"sat_fat_g":4.8,"trans_fat_g":0.0,"calcium_pct":1,"iron_pct":0}'),
('wingstop_classic_wings_lemon_pepper_6pc', 'Wingstop Classic Wings Lemon Pepper (6pc)', 387.1, 32.3, 0.0, 25.8, 0.0, 0.0, 186, 186, 'wingstop.com', ARRAY['wingstop lemon pepper wings', 'wingstop lemon pepper'], '720 cal total for 6pc. {"sodium_mg":838.7,"cholesterol_mg":145.2,"sat_fat_g":6.5,"trans_fat_g":0.0}'),
('wingstop_classic_wings_original_hot_6pc', 'Wingstop Classic Wings Original Hot (6pc)', 322.6, 32.3, 3.2, 22.6, 0.0, 0.0, 186, 186, 'wingstop.com', ARRAY['wingstop hot wings', 'wingstop original hot'], '600 cal total for 6pc. {"sodium_mg":1354.8,"cholesterol_mg":145.2,"sat_fat_g":4.8,"trans_fat_g":0.0}'),
('wingstop_classic_wings_garlic_parm_6pc', 'Wingstop Classic Wings Garlic Parmesan (6pc)', 387.1, 32.3, 3.2, 25.8, 0.0, 0.0, 186, 186, 'wingstop.com', ARRAY['wingstop garlic parmesan wings', 'wingstop garlic parm'], '720 cal total for 6pc. {"sodium_mg":1129.0,"cholesterol_mg":161.3,"sat_fat_g":8.1,"trans_fat_g":0.0}'),
('wingstop_classic_wings_mild_6pc', 'Wingstop Classic Wings Mild (6pc)', 300.0, 32.3, 3.2, 19.4, 0.0, 0.0, 186, 186, 'wingstop.com', ARRAY['wingstop mild wings'], '558 cal total for 6pc. {"sodium_mg":935.5,"cholesterol_mg":145.2,"sat_fat_g":4.8,"trans_fat_g":0.0}'),
('wingstop_classic_wings_hickory_bbq_6pc', 'Wingstop Classic Wings Hickory Smoked BBQ (6pc)', 338.7, 32.3, 12.9, 19.4, 0.0, 6.5, 186, 186, 'wingstop.com', ARRAY['wingstop bbq wings', 'wingstop hickory bbq'], '630 cal total for 6pc. {"sodium_mg":1032.3,"cholesterol_mg":145.2,"sat_fat_g":4.8,"trans_fat_g":0.0}'),
('wingstop_classic_wings_mango_hab_6pc', 'Wingstop Classic Wings Mango Habanero (6pc)', 322.6, 32.3, 12.9, 19.4, 0.0, 8.1, 186, 186, 'wingstop.com', ARRAY['wingstop mango habanero wings'], '600 cal total for 6pc. {"sodium_mg":1064.5,"cholesterol_mg":145.2,"sat_fat_g":4.8,"trans_fat_g":0.0}'),
('wingstop_classic_wings_atomic_6pc', 'Wingstop Classic Wings Atomic (6pc)', 322.6, 32.3, 3.2, 22.6, 0.0, 0.0, 186, 186, 'wingstop.com', ARRAY['wingstop atomic wings'], '600 cal total for 6pc. {"sodium_mg":1548.4,"cholesterol_mg":145.2,"sat_fat_g":4.8,"trans_fat_g":0.0}'),
('wingstop_boneless_wings_plain_6pc', 'Wingstop Boneless Wings Plain (6pc)', 296.3, 14.8, 22.2, 16.7, 0.0, 0.0, 162, 162, 'wingstop.com', ARRAY['wingstop plain boneless', 'wingstop boneless'], '480 cal total for 6pc. {"sodium_mg":851.9,"cholesterol_mg":37.0,"sat_fat_g":3.7,"trans_fat_g":0.0,"calcium_pct":1,"iron_pct":0}'),
('wingstop_boneless_wings_lemon_pepper_6pc', 'Wingstop Boneless Wings Lemon Pepper (6pc)', 407.4, 14.8, 22.2, 25.9, 0.0, 0.0, 162, 162, 'wingstop.com', ARRAY['wingstop lemon pepper boneless'], '660 cal total for 6pc. {"sodium_mg":1222.2,"cholesterol_mg":37.0,"sat_fat_g":5.6,"trans_fat_g":0.0}'),
('wingstop_boneless_wings_garlic_parm_6pc', 'Wingstop Boneless Wings Garlic Parmesan (6pc)', 414.8, 14.8, 22.2, 27.8, 0.0, 0.0, 162, 162, 'wingstop.com', ARRAY['wingstop garlic parmesan boneless'], '672 cal total for 6pc. {"sodium_mg":1259.3,"cholesterol_mg":55.6,"sat_fat_g":7.4,"trans_fat_g":0.0}'),
('wingstop_boneless_wings_original_hot_6pc', 'Wingstop Boneless Wings Original Hot (6pc)', 333.3, 14.8, 22.2, 18.5, 0.0, 0.0, 162, 162, 'wingstop.com', ARRAY['wingstop hot boneless'], '540 cal total for 6pc. {"sodium_mg":1296.3,"cholesterol_mg":37.0,"sat_fat_g":3.7,"trans_fat_g":0.0}'),
('wingstop_boneless_wings_mango_hab_6pc', 'Wingstop Boneless Wings Mango Habanero (6pc)', 351.9, 14.8, 29.6, 18.5, 0.0, 11.1, 162, 162, 'wingstop.com', ARRAY['wingstop mango habanero boneless'], '570 cal total for 6pc. {"sodium_mg":1259.3,"cholesterol_mg":37.0,"sat_fat_g":3.7,"trans_fat_g":0.0}'),
('wingstop_crispy_tenders_3pc', 'Wingstop Crispy Tenders Plain (3pc)', 247.1, 23.5, 14.1, 8.2, 0.6, 0.0, 170, 170, 'wingstop.com', ARRAY['wingstop tenders', 'wingstop chicken tenders'], '420 cal total for 3pc. {"sodium_mg":705.9,"cholesterol_mg":52.9,"sat_fat_g":1.8,"trans_fat_g":0.0}'),
('wingstop_chicken_sandwich_plain', 'Wingstop Chicken Sandwich Plain', 321.1, 16.8, 34.7, 12.6, 1.1, 2.6, 190, 190, 'wingstop.com', ARRAY['wingstop chicken sandwich', 'wingstop sandwich'], '610 cal total. {"sodium_mg":905.3,"cholesterol_mg":28.9,"sat_fat_g":2.1,"trans_fat_g":0.0}'),
('wingstop_chicken_sandwich_hot', 'Wingstop Chicken Sandwich Original Hot', 331.6, 16.8, 35.8, 13.2, 1.1, 2.6, 190, 190, 'wingstop.com', ARRAY['wingstop hot chicken sandwich', 'wingstop spicy sandwich'], '630 cal total. {"sodium_mg":952.6,"cholesterol_mg":28.9,"sat_fat_g":2.6,"trans_fat_g":0.0}'),
('wingstop_seasoned_fries_regular', 'Wingstop Seasoned Fries (Regular)', 261.8, 4.2, 36.1, 11.0, 0.0, 1.6, 191, 191, 'wingstop.com', ARRAY['wingstop fries', 'wingstop regular fries'], '500 cal total. {"sodium_mg":324.6,"cholesterol_mg":0,"sat_fat_g":1.8,"trans_fat_g":0.0,"calcium_pct":5,"iron_pct":11}'),
('wingstop_seasoned_fries_large', 'Wingstop Seasoned Fries (Large)', 261.8, 4.2, 36.1, 11.0, 0.0, 1.6, 350, 350, 'wingstop.com', ARRAY['wingstop large fries'], '916 cal total for large. {"sodium_mg":324.6,"cholesterol_mg":0,"sat_fat_g":1.8,"trans_fat_g":0.0,"calcium_pct":5,"iron_pct":11}'),
('wingstop_cajun_fried_corn', 'Wingstop Cajun Fried Corn', 275.0, 5.0, 33.3, 15.0, 2.5, 3.3, 120, 120, 'wingstop.com', ARRAY['wingstop corn', 'wingstop fried corn'], '330 cal total. {"sodium_mg":483.3,"cholesterol_mg":0,"sat_fat_g":2.5,"trans_fat_g":0.0}'),
('wingstop_coleslaw', 'Wingstop Cole Slaw', 133.3, 1.3, 12.0, 9.3, 2.0, 9.3, 150, 150, 'wingstop.com', ARRAY['wingstop coleslaw', 'wingstop slaw'], '200 cal total. {"sodium_mg":120.0,"cholesterol_mg":6.7,"sat_fat_g":1.3,"trans_fat_g":0.0}'),
('wingstop_veggie_sticks', 'Wingstop Veggie Sticks', 6.7, 0.7, 1.3, 0.0, 0.7, 0.7, 75, 75, 'wingstop.com', ARRAY['wingstop celery carrots', 'wingstop veggie'], '5 cal total. {"sodium_mg":26.7,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('wingstop_ranch_dip', 'Wingstop Ranch Dip', 366.7, 1.7, 3.3, 38.3, 0.0, 1.7, 30, 30, 'wingstop.com', ARRAY['wingstop ranch', 'wingstop ranch dressing'], '110 cal per dip cup. {"sodium_mg":666.7,"cholesterol_mg":16.7,"sat_fat_g":6.7,"trans_fat_g":0.0}'),
('wingstop_blue_cheese_dip', 'Wingstop Blue Cheese Dip', 400.0, 1.7, 3.3, 41.7, 0.0, 1.7, 30, 30, 'wingstop.com', ARRAY['wingstop blue cheese', 'wingstop bleu cheese'], '120 cal per dip cup. {"sodium_mg":700.0,"cholesterol_mg":20.0,"sat_fat_g":8.3,"trans_fat_g":0.0}'),
('wingstop_thigh_bites_regular', 'Wingstop Thigh Bites (Regular)', 270.0, 20.0, 18.3, 15.0, 0.7, 1.0, 300, 300, 'wingstop.com', ARRAY['wingstop thigh bites'], '810 cal total. {"sodium_mg":800.0,"cholesterol_mg":53.3,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('zaxbys_chicken_fingerz_5pc', 'Zaxby''s Chicken Fingerz (5pc)', 284.0, 29.0, 13.0, 13.0, 0.6, 0.6, 169, 169, 'zaxbys.com', ARRAY['zaxbys fingerz', 'zaxbys chicken fingers 5 piece'], '480 cal total for 5pc. {"sodium_mg":1213.0,"cholesterol_mg":85.8,"sat_fat_g":1.8,"trans_fat_g":0.0}'),
('zaxbys_chicken_fingerz_10pc', 'Zaxby''s Chicken Fingerz (10pc)', 284.0, 29.0, 13.0, 13.0, 0.6, 0.6, 338, 338, 'zaxbys.com', ARRAY['zaxbys fingerz 10', 'zaxbys chicken fingers 10 piece'], '960 cal total for 10pc. {"sodium_mg":1213.0,"cholesterol_mg":85.8,"sat_fat_g":1.8,"trans_fat_g":0.0}'),
('zaxbys_chicken_finger_plate_4pc', 'Zaxby''s Chicken Finger Plate (4pc)', 246.7, 10.0, 21.8, 13.3, 1.1, 1.3, 450, 450, 'zaxbys.com', ARRAY['zaxbys finger plate', 'zaxbys 4 piece plate'], '1110 cal total. {"sodium_mg":844.4,"cholesterol_mg":44.4,"sat_fat_g":2.2,"trans_fat_g":0.0}'),
('zaxbys_chicken_finger_plate_6pc', 'Zaxby''s Chicken Finger Plate (6pc)', 260.0, 11.6, 19.8, 15.1, 1.1, 1.3, 550, 550, 'zaxbys.com', ARRAY['zaxbys 6 piece plate'], '1430 cal total. {"sodium_mg":850.9,"cholesterol_mg":47.3,"sat_fat_g":2.5,"trans_fat_g":0.0}'),
('zaxbys_traditional_wings_5pc', 'Zaxby''s Traditional Wings (5pc)', 238.9, 23.9, 6.7, 13.3, 0.0, 0.0, 180, 180, 'zaxbys.com', ARRAY['zaxbys wings', 'zaxbys bone-in wings'], '430 cal total for 5pc. {"sodium_mg":833.3,"cholesterol_mg":105.6,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('zaxbys_traditional_wings_10pc', 'Zaxby''s Traditional Wings (10pc)', 238.9, 23.9, 6.7, 13.3, 0.0, 0.0, 360, 360, 'zaxbys.com', ARRAY['zaxbys wings 10'], '860 cal total for 10pc. {"sodium_mg":833.3,"cholesterol_mg":105.6,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('zaxbys_boneless_wings_things', 'Zaxby''s Boneless Wings & Things', 290.0, 12.4, 21.2, 17.4, 0.8, 2.0, 500, 500, 'zaxbys.com', ARRAY['zaxbys boneless wings and things'], '1450 cal total. {"sodium_mg":880.0,"cholesterol_mg":52.0,"sat_fat_g":3.0,"trans_fat_g":0.0}'),
('zaxbys_traditional_wings_things', 'Zaxby''s Traditional Wings & Things', 288.0, 15.8, 16.8, 17.6, 0.8, 1.6, 500, 500, 'zaxbys.com', ARRAY['zaxbys wings and things'], '1440 cal total. {"sodium_mg":876.0,"cholesterol_mg":64.0,"sat_fat_g":3.4,"trans_fat_g":0.0}'),
('zaxbys_grilled_chicken_sandwich', 'Zaxby''s Grilled Chicken Sandwich', 247.4, 20.0, 18.4, 10.5, 1.1, 3.2, 190, 190, 'zaxbys.com', ARRAY['zaxbys grilled chicken', 'zaxbys grilled sandwich'], '470 cal total. {"sodium_mg":589.5,"cholesterol_mg":50.0,"sat_fat_g":2.1,"trans_fat_g":0.0}'),
('zaxbys_signature_club_sandwich', 'Zaxby''s Signature Club Sandwich', 310.5, 22.6, 18.9, 16.8, 1.1, 3.2, 190, 190, 'zaxbys.com', ARRAY['zaxbys club sandwich', 'zaxbys signature sandwich'], '590 cal total. {"sodium_mg":763.2,"cholesterol_mg":55.3,"sat_fat_g":3.7,"trans_fat_g":0.0}'),
('zaxbys_grilled_cobb_zalad', 'Zaxby''s Grilled Cobb Zalad', 194.3, 16.6, 10.0, 10.0, 2.3, 2.9, 350, 350, 'zaxbys.com', ARRAY['zaxbys cobb salad', 'zaxbys grilled cobb'], '680 cal total. {"sodium_mg":454.3,"cholesterol_mg":40.0,"sat_fat_g":3.1,"trans_fat_g":0.0}'),
('zaxbys_fried_cobb_zalad', 'Zaxby''s Fried Cobb Zalad', 222.9, 15.7, 12.3, 12.9, 2.3, 2.9, 350, 350, 'zaxbys.com', ARRAY['zaxbys fried cobb salad'], '780 cal total. {"sodium_mg":517.1,"cholesterol_mg":42.9,"sat_fat_g":3.4,"trans_fat_g":0.0}'),
('zaxbys_grilled_blue_zalad', 'Zaxby''s Grilled Blue Zalad', 145.7, 12.3, 9.7, 6.9, 2.0, 3.4, 350, 350, 'zaxbys.com', ARRAY['zaxbys blue salad', 'zaxbys grilled blue'], '510 cal total. {"sodium_mg":371.4,"cholesterol_mg":34.3,"sat_fat_g":2.3,"trans_fat_g":0.0}'),
('zaxbys_fried_blue_zalad', 'Zaxby''s Fried Blue Zalad', 194.3, 11.1, 12.3, 11.1, 2.0, 3.4, 350, 350, 'zaxbys.com', ARRAY['zaxbys fried blue salad'], '680 cal total. {"sodium_mg":434.3,"cholesterol_mg":37.1,"sat_fat_g":2.6,"trans_fat_g":0.0}'),
('zaxbys_crinkle_fries_regular', 'Zaxby''s Crinkle Fries (Regular)', 220.0, 3.3, 31.3, 9.3, 2.7, 0.0, 150, 150, 'zaxbys.com', ARRAY['zaxbys fries', 'zaxbys crinkle fries'], '330 cal total. {"sodium_mg":286.7,"cholesterol_mg":0,"sat_fat_g":1.3,"trans_fat_g":0.0}'),
('zaxbys_crinkle_fries_large', 'Zaxby''s Crinkle Fries (Large)', 220.8, 3.3, 31.3, 9.6, 2.7, 0.0, 240, 240, 'zaxbys.com', ARRAY['zaxbys large fries'], '530 cal total. {"sodium_mg":287.5,"cholesterol_mg":0,"sat_fat_g":1.3,"trans_fat_g":0.0}'),
('zaxbys_coleslaw', 'Zaxby''s Cole Slaw', 140.0, 1.0, 13.0, 10.0, 1.0, 11.0, 100, 100, 'zaxbys.com', ARRAY['zaxbys coleslaw', 'zaxbys slaw'], '140 cal per side. {"sodium_mg":160.0,"cholesterol_mg":5.0,"sat_fat_g":1.5,"trans_fat_g":0.0}'),
('zaxbys_tater_chips', 'Zaxby''s Tater Chips', 293.3, 4.3, 22.0, 20.7, 2.0, 0.3, 300, 300, 'zaxbys.com', ARRAY['zaxbys tater chips', 'zaxbys chips'], '880 cal total. {"sodium_mg":553.3,"cholesterol_mg":0,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('zaxbys_chicken_bacon_ranch_fries', 'Zaxby''s Chicken Bacon Ranch Loaded Fries', 282.2, 13.6, 19.6, 17.3, 1.3, 1.3, 450, 450, 'zaxbys.com', ARRAY['zaxbys loaded fries', 'zaxbys bacon ranch fries'], '1270 cal total. {"sodium_mg":600.0,"cholesterol_mg":37.8,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('zaxbys_zax_sauce', 'Zaxby''s Zax Sauce', 500.0, 0.0, 13.3, 50.0, 0.0, 3.3, 30, 30, 'zaxbys.com', ARRAY['zaxbys zax sauce', 'zax sauce'], '150 cal per dip cup. {"sodium_mg":1000.0,"cholesterol_mg":33.3,"sat_fat_g":8.3,"trans_fat_g":0.0}'),
('zaxbys_ranch_sauce', 'Zaxby''s Ranch Sauce', 500.0, 3.3, 6.7, 53.3, 0.0, 3.3, 30, 30, 'zaxbys.com', ARRAY['zaxbys ranch'], '150 cal per dip cup. {"sodium_mg":833.3,"cholesterol_mg":16.7,"sat_fat_g":8.3,"trans_fat_g":0.0}'),
('zaxbys_vanilla_milkshake', 'Zaxby''s Vanilla Milkshake', 142.5, 3.3, 23.5, 4.3, 0.0, 20.0, 400, 400, 'zaxbys.com', ARRAY['zaxbys vanilla shake'], '570 cal total. {"sodium_mg":62.5,"cholesterol_mg":12.5,"sat_fat_g":2.8,"trans_fat_g":0.0}'),
('zaxbys_chocolate_milkshake', 'Zaxby''s Chocolate Milkshake', 148.9, 3.1, 26.4, 4.0, 0.4, 22.2, 450, 450, 'zaxbys.com', ARRAY['zaxbys chocolate shake'], '670 cal total. {"sodium_mg":66.7,"cholesterol_mg":11.1,"sat_fat_g":2.7,"trans_fat_g":0.0}'),
('zaxbys_birthday_cake_milkshake', 'Zaxby''s Birthday Cake Milkshake', 162.2, 2.9, 28.7, 4.2, 0.0, 24.0, 450, 450, 'zaxbys.com', ARRAY['zaxbys birthday cake shake'], '730 cal total. {"sodium_mg":71.1,"cholesterol_mg":11.1,"sat_fat_g":2.7,"trans_fat_g":0.0}'),
('littlecaesars_pepperoni_pizza_slice', 'Little Caesars Pepperoni Pizza (1 slice)', 225.8, 11.3, 25.8, 8.9, 1.6, 2.4, 124, 124, 'littlecaesars.com', ARRAY['little caesars pepperoni', 'little caesars pepperoni pizza'], '280 cal per slice. {"sodium_mg":451.6,"cholesterol_mg":20.2,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('littlecaesars_cheese_pizza_slice', 'Little Caesars Cheese Pizza (1 slice)', 213.7, 10.3, 27.4, 7.7, 0.9, 2.6, 117, 117, 'littlecaesars.com', ARRAY['little caesars cheese', 'little caesars cheese pizza'], '250 cal per slice. {"sodium_mg":401.7,"cholesterol_mg":17.1,"sat_fat_g":3.8,"trans_fat_g":0.0}'),
('littlecaesars_extramostbestest_pepperoni_slice', 'Little Caesars ExtraMostBestest Pepperoni (1 slice)', 238.5, 12.3, 24.6, 10.8, 1.2, 2.3, 130, 130, 'littlecaesars.com', ARRAY['little caesars extramostbestest', 'little caesars extra most bestest'], '310 cal per slice. {"sodium_mg":507.7,"cholesterol_mg":26.9,"sat_fat_g":5.4,"trans_fat_g":0.0}'),
('littlecaesars_italian_sausage_slice', 'Little Caesars Italian Sausage Pizza (1 slice)', 225.4, 11.1, 25.4, 9.5, 1.2, 2.4, 126, 126, 'littlecaesars.com', ARRAY['little caesars sausage', 'little caesars italian sausage'], '284 cal per slice. {"sodium_mg":452.4,"cholesterol_mg":19.8,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('littlecaesars_veggie_pizza_slice', 'Little Caesars Veggie Pizza (1 slice)', 217.8, 10.1, 25.6, 7.8, 1.6, 2.3, 129, 129, 'littlecaesars.com', ARRAY['little caesars veggie', 'little caesars vegetable pizza'], '281 cal per slice. {"sodium_mg":426.4,"cholesterol_mg":15.5,"sat_fat_g":3.5,"trans_fat_g":0.0}'),
('littlecaesars_thin_crust_cheese_slice', 'Little Caesars Thin Crust Cheese (1 slice)', 220.0, 11.1, 16.7, 12.2, 0.6, 1.1, 90, 90, 'littlecaesars.com', ARRAY['little caesars thin crust', 'little caesars thin crust cheese'], '198 cal per slice. {"sodium_mg":466.7,"cholesterol_mg":27.8,"sat_fat_g":5.6,"trans_fat_g":0.0}'),
('littlecaesars_thin_crust_pepperoni_slice', 'Little Caesars Thin Crust Pepperoni (1 slice)', 233.3, 11.1, 15.6, 13.3, 0.6, 1.1, 90, 90, 'littlecaesars.com', ARRAY['little caesars thin crust pepperoni'], '210 cal per slice. {"sodium_mg":511.1,"cholesterol_mg":31.1,"sat_fat_g":6.1,"trans_fat_g":0.0}'),
('littlecaesars_detroit_style_pepperoni_slice', 'Little Caesars Detroit-Style Deep Dish Pepperoni (1 slice)', 252.7, 10.7, 25.3, 12.0, 1.3, 2.0, 150, 150, 'littlecaesars.com', ARRAY['little caesars detroit style', 'little caesars deep dish'], '379 cal per slice. {"sodium_mg":546.7,"cholesterol_mg":26.7,"sat_fat_g":5.3,"trans_fat_g":0.0}'),
('littlecaesars_detroit_style_cheese_slice', 'Little Caesars Detroit-Style Deep Dish Cheese (1 slice)', 238.0, 9.3, 27.3, 10.0, 1.3, 2.0, 150, 150, 'littlecaesars.com', ARRAY['little caesars detroit cheese'], '357 cal per slice. {"sodium_mg":506.7,"cholesterol_mg":23.3,"sat_fat_g":4.7,"trans_fat_g":0.0}'),
('littlecaesars_5meat_feast_slice', 'Little Caesars 5 Meat Feast Pizza (1 slice)', 262.7, 13.3, 24.0, 13.3, 1.3, 2.0, 150, 150, 'littlecaesars.com', ARRAY['little caesars 5 meat', 'little caesars meat feast'], '394 cal per slice. {"sodium_mg":600.0,"cholesterol_mg":30.0,"sat_fat_g":6.0,"trans_fat_g":0.0}'),
('littlecaesars_crazy_bread_1pc', 'Little Caesars Crazy Bread (1 stick)', 250.0, 7.5, 37.5, 7.5, 2.5, 2.5, 40, 40, 'littlecaesars.com', ARRAY['little caesars crazy bread', 'crazy bread'], '100 cal per stick. {"sodium_mg":350.0,"cholesterol_mg":0,"sat_fat_g":1.3,"trans_fat_g":0.0}'),
('littlecaesars_italian_cheese_bread_1pc', 'Little Caesars Italian Cheese Bread (1 stick)', 335.0, 12.5, 30.0, 15.0, 0.8, 1.3, 40, 40, 'littlecaesars.com', ARRAY['little caesars cheese bread', 'italian cheese bread'], '134 cal per stick. {"sodium_mg":600.0,"cholesterol_mg":25.0,"sat_fat_g":6.3,"trans_fat_g":0.0}'),
('littlecaesars_crazy_sauce', 'Little Caesars Crazy Sauce (1 cup)', 37.5, 0.6, 6.9, 0.0, 0.6, 5.0, 80, 80, 'littlecaesars.com', ARRAY['little caesars sauce', 'crazy sauce'], '30 cal per cup. {"sodium_mg":387.5,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('littlecaesars_ranch_sauce', 'Little Caesars Ranch Dipping Sauce', 766.7, 3.3, 6.7, 80.0, 0.0, 3.3, 30, 30, 'littlecaesars.com', ARRAY['little caesars ranch'], '230 cal per cup. {"sodium_mg":1133.3,"cholesterol_mg":33.3,"sat_fat_g":13.3,"trans_fat_g":0.0}'),
('littlecaesars_buffalo_wings_8pc', 'Little Caesars Buffalo Wings (8pc)', 231.1, 20.9, 3.1, 15.6, 0.4, 0.4, 225, 225, 'littlecaesars.com', ARRAY['little caesars buffalo wings', 'little caesars wings'], '520 cal for 8pc. {"sodium_mg":1066.7,"cholesterol_mg":88.9,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('littlecaesars_oven_roasted_wings_8pc', 'Little Caesars Oven Roasted Wings (8pc)', 226.7, 20.9, 1.3, 15.6, 0.0, 0.0, 225, 225, 'littlecaesars.com', ARRAY['little caesars oven roasted wings'], '510 cal for 8pc. {"sodium_mg":933.3,"cholesterol_mg":88.9,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('littlecaesars_garlic_parm_wings_8pc', 'Little Caesars Garlic Parmesan Wings (8pc)', 297.8, 21.8, 2.2, 22.7, 0.0, 0.0, 225, 225, 'littlecaesars.com', ARRAY['little caesars garlic parm wings'], '670 cal for 8pc. {"sodium_mg":1111.1,"cholesterol_mg":93.3,"sat_fat_g":6.2,"trans_fat_g":0.0}'),
('littlecaesars_bbq_wings_8pc', 'Little Caesars BBQ Wings (8pc)', 275.6, 21.3, 14.2, 15.6, 0.4, 8.9, 225, 225, 'littlecaesars.com', ARRAY['little caesars bbq wings'], '620 cal for 8pc. {"sodium_mg":1155.6,"cholesterol_mg":88.9,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('littlecaesars_cookie_dough_brownie_twix', 'Little Caesars Cookie Dough Brownie with Twix', 333.3, 5.0, 42.1, 16.7, 1.7, 29.2, 240, 240, 'littlecaesars.com', ARRAY['little caesars brownie twix', 'little caesars cookie brownie'], '800 cal total. {"sodium_mg":191.7,"cholesterol_mg":20.8,"sat_fat_g":8.3,"trans_fat_g":0.0}'),
('littlecaesars_cookie_dough_brownie_mm', 'Little Caesars Cookie Dough Brownie with M&Ms', 350.0, 5.0, 45.0, 16.7, 1.7, 31.7, 240, 240, 'littlecaesars.com', ARRAY['little caesars brownie mm'], '840 cal total. {"sodium_mg":200.0,"cholesterol_mg":20.8,"sat_fat_g":8.3,"trans_fat_g":0.0}'),
('jimmyjohns_pepe_8in', 'Jimmy John''s #1 The Pepe (8")', 260.9, 12.6, 21.7, 12.6, 0.9, 1.7, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns pepe', 'jimmy johns number 1', 'jj pepe'], '600 cal total. {"sodium_mg":682.6,"cholesterol_mg":28.3,"sat_fat_g":4.3,"trans_fat_g":0.0}'),
('jimmyjohns_big_john_8in', 'Jimmy John''s #2 Big John (8")', 217.4, 11.3, 20.4, 9.1, 0.9, 1.3, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns big john', 'jimmy johns number 2', 'jj big john'], '500 cal total. {"sodium_mg":482.6,"cholesterol_mg":23.9,"sat_fat_g":3.0,"trans_fat_g":0.0}'),
('jimmyjohns_totally_tuna_8in', 'Jimmy John''s #3 Totally Tuna (8")', 278.3, 9.6, 20.4, 17.4, 1.3, 1.3, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns tuna', 'jimmy johns number 3', 'jj totally tuna'], '640 cal total. {"sodium_mg":387.0,"cholesterol_mg":19.6,"sat_fat_g":3.0,"trans_fat_g":0.0}'),
('jimmyjohns_turkey_tom_8in', 'Jimmy John''s #4 Turkey Tom (8")', 208.7, 10.0, 20.9, 8.3, 0.9, 1.3, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns turkey tom', 'jimmy johns number 4', 'jj turkey tom'], '480 cal total. {"sodium_mg":504.3,"cholesterol_mg":17.4,"sat_fat_g":2.2,"trans_fat_g":0.0}'),
('jimmyjohns_vito_8in', 'Jimmy John''s #5 Vito (8")', 291.3, 12.2, 20.4, 18.3, 0.9, 1.3, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns vito', 'jimmy johns number 5', 'jj vito'], '670 cal total. {"sodium_mg":743.5,"cholesterol_mg":34.8,"sat_fat_g":5.2,"trans_fat_g":0.0}'),
('jimmyjohns_the_veggie_8in', 'Jimmy John''s #6 The Veggie (8")', 308.7, 8.7, 23.5, 20.0, 1.7, 2.2, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns veggie', 'jimmy johns number 6', 'jj veggie'], '710 cal total. {"sodium_mg":526.1,"cholesterol_mg":21.7,"sat_fat_g":6.1,"trans_fat_g":0.0}'),
('jimmyjohns_spicy_italian_8in', 'Jimmy John''s #7 Spicy East Coast Italian (8")', 421.7, 23.5, 23.5, 25.7, 2.2, 2.2, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns spicy italian', 'jimmy johns number 7'], '970 cal total. {"sodium_mg":1460.9,"cholesterol_mg":78.3,"sat_fat_g":9.6,"trans_fat_g":0.0}'),
('jimmyjohns_billy_club_8in', 'Jimmy John''s #8 Billy Club (8")', 278.3, 14.3, 20.9, 13.9, 0.9, 2.6, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns billy club', 'jimmy johns number 8'], '640 cal total. {"sodium_mg":769.6,"cholesterol_mg":30.4,"sat_fat_g":3.9,"trans_fat_g":0.0}'),
('jimmyjohns_italian_night_club_8in', 'Jimmy John''s #9 Italian Night Club (8")', 430.4, 19.6, 21.7, 24.3, 1.3, 2.2, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns italian night club', 'jimmy johns number 9'], '990 cal total. {"sodium_mg":1334.8,"cholesterol_mg":58.7,"sat_fat_g":7.8,"trans_fat_g":0.0}'),
('jimmyjohns_beach_club_8in', 'Jimmy John''s #10 Beach Club (8")', 295.7, 17.8, 21.7, 15.2, 1.7, 2.2, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns beach club', 'jimmy johns number 10', 'jj beach club'], '680 cal total. {"sodium_mg":682.6,"cholesterol_mg":28.3,"sat_fat_g":3.9,"trans_fat_g":0.0}'),
('jimmyjohns_country_club_8in', 'Jimmy John''s #11 Country Club (8")', 273.9, 15.2, 21.7, 12.6, 1.3, 1.7, 230, 230, 'jimmyjohns.com', ARRAY['jimmy johns country club', 'jimmy johns number 11'], '630 cal total. {"sodium_mg":721.7,"cholesterol_mg":28.3,"sat_fat_g":3.5,"trans_fat_g":0.0}'),
('jimmyjohns_gargantuan_8in', 'Jimmy John''s J.J. Gargantuan (8")', 400.0, 28.9, 28.9, 18.1, 1.5, 2.2, 270, 270, 'jimmyjohns.com', ARRAY['jimmy johns gargantuan', 'jj gargantuan'], '1080 cal total. {"sodium_mg":1455.6,"cholesterol_mg":72.2,"sat_fat_g":6.3,"trans_fat_g":0.0}'),
('jimmyjohns_little_john_1', 'Jimmy John''s Little John #1', 300.0, 15.0, 25.0, 15.0, 2.0, 2.0, 100, 100, 'jimmyjohns.com', ARRAY['jimmy johns little john 1'], '300 cal. {"sodium_mg":770.0,"cholesterol_mg":30.0,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('jimmyjohns_little_john_2', 'Jimmy John''s Little John #2', 250.0, 13.0, 24.0, 11.0, 2.0, 1.0, 100, 100, 'jimmyjohns.com', ARRAY['jimmy johns little john 2'], '250 cal. {"sodium_mg":560.0,"cholesterol_mg":25.0,"sat_fat_g":3.0,"trans_fat_g":0.0}'),
('jimmyjohns_little_john_3', 'Jimmy John''s Little John #3', 250.0, 10.0, 26.0, 11.0, 3.0, 2.0, 100, 100, 'jimmyjohns.com', ARRAY['jimmy johns little john 3'], '250 cal. {"sodium_mg":590.0,"cholesterol_mg":20.0,"sat_fat_g":3.0,"trans_fat_g":0.0}'),
('jimmyjohns_little_john_4', 'Jimmy John''s Little John #4', 240.0, 12.0, 24.0, 10.0, 2.0, 1.0, 100, 100, 'jimmyjohns.com', ARRAY['jimmy johns little john 4'], '240 cal. {"sodium_mg":580.0,"cholesterol_mg":20.0,"sat_fat_g":2.5,"trans_fat_g":0.0}'),
('jimmyjohns_little_john_blt', 'Jimmy John''s Little John BLT', 300.0, 12.0, 24.0, 16.0, 2.0, 1.0, 100, 100, 'jimmyjohns.com', ARRAY['jimmy johns little john blt'], '300 cal. {"sodium_mg":680.0,"cholesterol_mg":25.0,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('jimmyjohns_pickle', 'Jimmy John''s Jumbo Kosher Dill Pickle', 6.7, 0.7, 1.3, 0.0, 0.0, 0.0, 150, 150, 'jimmyjohns.com', ARRAY['jimmy johns pickle', 'jj pickle'], '10 cal per pickle. {"sodium_mg":580.0,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('jimmyjohns_bbq_chips', 'Jimmy John''s BBQ Jimmy Chips', 500.0, 3.3, 56.7, 26.7, 3.3, 3.3, 30, 30, 'jimmyjohns.com', ARRAY['jimmy johns chips', 'jj chips', 'jimmy chips'], '150 cal per bag. {"sodium_mg":733.3,"cholesterol_mg":0,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('jerseymikes_turkey_provolone_reg', 'Jersey Mike''s #7 Turkey & Provolone (Regular)', 328.0, 18.0, 26.4, 16.4, 1.2, 2.4, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes turkey provolone', 'jersey mikes number 7', 'jersey mikes turkey sub'], '820 cal total. {"sodium_mg":872.0,"cholesterol_mg":32.0,"sat_fat_g":4.4,"trans_fat_g":0.0}'),
('jerseymikes_original_italian_reg', 'Jersey Mike''s #13 The Original Italian (Regular)', 384.0, 18.8, 28.4, 22.0, 1.2, 2.4, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes original italian', 'jersey mikes number 13', 'jersey mikes italian sub'], '960 cal total. {"sodium_mg":1056.0,"cholesterol_mg":44.0,"sat_fat_g":7.2,"trans_fat_g":0.0}'),
('jerseymikes_club_sub_reg', 'Jersey Mike''s #8 Club Sub (Regular)', 464.0, 20.0, 27.2, 31.2, 1.2, 2.0, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes club sub', 'jersey mikes number 8'], '1160 cal total. {"sodium_mg":1160.0,"cholesterol_mg":52.0,"sat_fat_g":8.0,"trans_fat_g":0.0}'),
('jerseymikes_super_sub_reg', 'Jersey Mike''s #5 The Super Sub (Regular)', 324.0, 16.0, 25.6, 17.6, 1.2, 2.0, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes super sub', 'jersey mikes number 5'], '810 cal total. {"sodium_mg":940.0,"cholesterol_mg":36.0,"sat_fat_g":5.2,"trans_fat_g":0.0}'),
('jerseymikes_roast_beef_provolone_reg', 'Jersey Mike''s #6 Roast Beef & Provolone (Regular)', 364.0, 22.4, 28.0, 18.8, 1.2, 2.4, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes roast beef', 'jersey mikes number 6'], '910 cal total. {"sodium_mg":960.0,"cholesterol_mg":40.0,"sat_fat_g":6.4,"trans_fat_g":0.0}'),
('jerseymikes_blt_reg', 'Jersey Mike''s BLT (Regular)', 260.0, 12.0, 26.8, 12.0, 1.6, 2.4, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes blt'], '650 cal total. {"sodium_mg":640.0,"cholesterol_mg":16.0,"sat_fat_g":3.6,"trans_fat_g":0.0}'),
('jerseymikes_ham_provolone_reg', 'Jersey Mike''s #3 Ham & Provolone (Regular)', 296.0, 14.8, 26.0, 14.8, 1.2, 2.4, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes ham provolone', 'jersey mikes number 3'], '740 cal total. {"sodium_mg":840.0,"cholesterol_mg":30.0,"sat_fat_g":4.8,"trans_fat_g":0.0}'),
('jerseymikes_tuna_fish_reg', 'Jersey Mike''s #10 Tuna Fish (Regular)', 368.0, 11.6, 28.0, 22.4, 1.2, 2.0, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes tuna', 'jersey mikes number 10'], '920 cal total. {"sodium_mg":700.0,"cholesterol_mg":22.0,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('jerseymikes_famous_philly_reg', 'Jersey Mike''s #17 Mike''s Famous Philly (Regular)', 356.0, 20.0, 26.8, 20.0, 1.2, 2.8, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes philly', 'jersey mikes famous philly', 'jersey mikes number 17'], '890 cal total. {"sodium_mg":840.0,"cholesterol_mg":48.0,"sat_fat_g":7.2,"trans_fat_g":0.0}'),
('jerseymikes_meatball_marinara_reg', 'Jersey Mike''s #14 Meatball & Cheese (Regular)', 372.0, 16.4, 33.6, 16.4, 2.0, 5.2, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes meatball', 'jersey mikes number 14'], '930 cal total. {"sodium_mg":1040.0,"cholesterol_mg":32.0,"sat_fat_g":6.4,"trans_fat_g":0.0}'),
('jerseymikes_california_club_reg', 'Jersey Mike''s California Club Sub (Regular)', 392.0, 18.0, 25.6, 22.4, 2.0, 2.8, 250, 250, 'jerseymikes.com', ARRAY['jersey mikes california club'], '980 cal total. {"sodium_mg":1120.0,"cholesterol_mg":42.0,"sat_fat_g":6.4,"trans_fat_g":0.0}'),
('jerseymikes_original_italian_bowl', 'Jersey Mike''s #13 The Original Italian (Bowl)', 325.0, 17.5, 6.3, 26.0, 1.0, 1.5, 200, 200, 'jerseymikes.com', ARRAY['jersey mikes italian bowl', 'jersey mikes tub'], '650 cal total. {"sodium_mg":1150.0,"cholesterol_mg":50.0,"sat_fat_g":7.5,"trans_fat_g":0.0}'),
('jerseymikes_fries_5oz', 'Jersey Mike''s French Fries (5 oz)', 218.3, 2.1, 23.8, 13.4, 2.1, 0.7, 142, 142, 'jerseymikes.com', ARRAY['jersey mikes fries', 'jersey mikes french fries'], '310 cal for 5oz. {"sodium_mg":274.6,"cholesterol_mg":0,"sat_fat_g":2.1,"trans_fat_g":0.0}'),
('jerseymikes_chocolate_chunk_cookie', 'Jersey Mike''s Chocolate Chunk Cookie', 373.3, 4.0, 49.3, 18.7, 1.3, 30.7, 75, 75, 'jerseymikes.com', ARRAY['jersey mikes cookie', 'jersey mikes chocolate cookie'], '280 cal per cookie. {"sodium_mg":280.0,"cholesterol_mg":26.7,"sat_fat_g":10.7,"trans_fat_g":0.0}'),
('chilis_oldtimer_with_cheese', 'Chili''s Oldtimer with Cheese', 336.0, 19.2, 17.6, 21.2, 1.2, 3.2, 250, 250, 'chilis.com', ARRAY['chilis oldtimer', 'chilis oldtimer burger'], '840 cal total. {"sodium_mg":644.0,"cholesterol_mg":54.0,"sat_fat_g":8.0,"trans_fat_g":0.8}'),
('chilis_big_mouth_bites', 'Chili''s Big Mouth Bites', 423.3, 21.0, 25.3, 26.7, 1.7, 5.0, 300, 300, 'chilis.com', ARRAY['chilis big mouth bites', 'chilis sliders'], '1270 cal total. {"sodium_mg":680.0,"cholesterol_mg":55.0,"sat_fat_g":10.0,"trans_fat_g":1.3}'),
('chilis_mushroom_swiss_burger', 'Chili''s Mushroom Swiss Burger', 396.0, 20.0, 18.8, 27.2, 1.2, 4.0, 250, 250, 'chilis.com', ARRAY['chilis mushroom swiss'], '990 cal total. {"sodium_mg":588.0,"cholesterol_mg":62.0,"sat_fat_g":10.0,"trans_fat_g":0.8}'),
('chilis_southern_smokehouse_burger', 'Chili''s Southern Smokehouse Burger', 508.0, 20.4, 30.0, 30.0, 2.0, 9.2, 250, 250, 'chilis.com', ARRAY['chilis southern smokehouse'], '1270 cal total. {"sodium_mg":1064.0,"cholesterol_mg":68.0,"sat_fat_g":10.8,"trans_fat_g":1.0}'),
('chilis_boss_burger', 'Chili''s The Boss Burger', 548.0, 27.2, 25.2, 33.2, 2.0, 5.6, 250, 250, 'chilis.com', ARRAY['chilis boss burger', 'chilis the boss'], '1370 cal total. {"sodium_mg":1152.0,"cholesterol_mg":88.0,"sat_fat_g":13.2,"trans_fat_g":1.2}'),
('chilis_crispy_chicken_sandwich', 'Chili''s Crispy Chicken Sandwich', 457.9, 22.1, 31.6, 27.4, 1.6, 3.7, 190, 190, 'chilis.com', ARRAY['chilis crispy chicken', 'chilis chicken sandwich'], '870 cal total. {"sodium_mg":968.4,"cholesterol_mg":42.1,"sat_fat_g":5.3,"trans_fat_g":0.0}'),
('chilis_honey_chipotle_crispers', 'Chili''s Honey-Chipotle Chicken Crispers', 316.7, 11.7, 26.3, 18.7, 1.0, 8.3, 300, 300, 'chilis.com', ARRAY['chilis crispers', 'chilis honey chipotle crispers'], '950 cal total. {"sodium_mg":816.7,"cholesterol_mg":35.0,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('chilis_original_crispers', 'Chili''s Original Chicken Crispers', 440.0, 18.7, 22.3, 29.3, 0.7, 2.0, 300, 300, 'chilis.com', ARRAY['chilis original crispers'], '1320 cal total. {"sodium_mg":1033.3,"cholesterol_mg":40.0,"sat_fat_g":5.3,"trans_fat_g":0.0}'),
('chilis_margarita_grilled_chicken', 'Chili''s Margarita Grilled Chicken', 220.0, 23.0, 20.3, 4.7, 1.7, 2.0, 300, 300, 'chilis.com', ARRAY['chilis margarita chicken', 'chilis grilled chicken'], '660 cal total. {"sodium_mg":770.0,"cholesterol_mg":61.7,"sat_fat_g":1.0,"trans_fat_g":0.0}'),
('chilis_grilled_chicken_fajitas', 'Chili''s Grilled Chicken Fajitas', 171.4, 15.4, 10.3, 7.1, 2.6, 2.9, 350, 350, 'chilis.com', ARRAY['chilis chicken fajitas', 'chilis fajitas'], '600 cal total. {"sodium_mg":542.9,"cholesterol_mg":25.7,"sat_fat_g":1.4,"trans_fat_g":0.0}'),
('chilis_steak_fajitas', 'Chili''s Steak Fajitas', 194.3, 18.0, 10.3, 8.6, 2.6, 2.6, 350, 350, 'chilis.com', ARRAY['chilis steak fajitas'], '680 cal total. {"sodium_mg":600.0,"cholesterol_mg":31.4,"sat_fat_g":2.3,"trans_fat_g":0.0}'),
('chilis_half_rack_ribs_original', 'Chili''s Baby Back Ribs Original BBQ (Half)', 260.0, 16.7, 13.3, 13.3, 0.0, 10.0, 300, 300, 'chilis.com', ARRAY['chilis half rack ribs', 'chilis baby back ribs half'], '780 cal half rack. {"sodium_mg":566.7,"cholesterol_mg":46.7,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('chilis_full_rack_ribs_original', 'Chili''s Baby Back Ribs Original BBQ (Full)', 253.3, 16.0, 13.3, 13.3, 0.0, 10.0, 600, 600, 'chilis.com', ARRAY['chilis full rack ribs'], '1520 cal full rack. {"sodium_mg":560.0,"cholesterol_mg":46.7,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('chilis_skillet_queso', 'Chili''s Skillet Queso with Chips', 321.4, 7.5, 27.5, 20.4, 1.8, 2.1, 280, 280, 'chilis.com', ARRAY['chilis queso', 'chilis skillet queso'], '900 cal total. {"sodium_mg":635.7,"cholesterol_mg":21.4,"sat_fat_g":7.1,"trans_fat_g":0.4}'),
('chilis_southwestern_eggrolls', 'Chili''s Southwestern Eggrolls', 330.0, 9.3, 26.0, 19.3, 3.0, 2.3, 300, 300, 'chilis.com', ARRAY['chilis eggrolls', 'chilis southwestern eggrolls'], '990 cal total. {"sodium_mg":666.7,"cholesterol_mg":20.0,"sat_fat_g":6.7,"trans_fat_g":0.3}'),
('chilis_boneless_wings', 'Chili''s Boneless Wings', 354.5, 14.5, 22.7, 22.7, 0.9, 1.4, 220, 220, 'chilis.com', ARRAY['chilis boneless wings'], '780 cal total. {"sodium_mg":818.2,"cholesterol_mg":31.8,"sat_fat_g":4.5,"trans_fat_g":0.0}'),
('chilis_chicken_enchilada_soup', 'Chili''s Chicken Enchilada Soup', 112.5, 4.6, 10.0, 7.1, 0.8, 1.7, 240, 240, 'chilis.com', ARRAY['chilis enchilada soup'], '270 cal per bowl. {"sodium_mg":437.5,"cholesterol_mg":14.6,"sat_fat_g":2.9,"trans_fat_g":0.0}'),
('chilis_original_chili', 'Chili''s Original Chili', 79.2, 5.0, 5.0, 3.3, 1.3, 1.3, 240, 240, 'chilis.com', ARRAY['chilis chili'], '190 cal per bowl. {"sodium_mg":375.0,"cholesterol_mg":12.5,"sat_fat_g":1.3,"trans_fat_g":0.0}'),
('chilis_santa_fe_chicken_salad', 'Chili''s Santa Fe Chicken Salad', 154.3, 10.0, 6.9, 10.0, 4.3, 3.4, 350, 350, 'chilis.com', ARRAY['chilis santa fe salad'], '540 cal total. {"sodium_mg":414.3,"cholesterol_mg":22.9,"sat_fat_g":3.1,"trans_fat_g":0.0}'),
('chilis_quesadilla_explosion_salad', 'Chili''s Quesadilla Explosion Salad', 382.9, 16.6, 23.7, 23.7, 4.0, 5.1, 350, 350, 'chilis.com', ARRAY['chilis quesadilla salad', 'chilis explosion salad'], '1340 cal total. {"sodium_mg":628.6,"cholesterol_mg":37.1,"sat_fat_g":8.6,"trans_fat_g":0.3}'),
('chilis_classic_ribeye', 'Chili''s Classic Ribeye (10 oz)', 210.0, 23.3, 0.0, 12.3, 0.0, 0.0, 300, 300, 'chilis.com', ARRAY['chilis ribeye', 'chilis steak'], '630 cal total. {"sodium_mg":310.0,"cholesterol_mg":53.3,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('chilis_classic_sirloin_6oz', 'Chili''s Classic Sirloin (6 oz)', 153.3, 20.0, 0.0, 6.7, 0.0, 0.0, 300, 300, 'chilis.com', ARRAY['chilis sirloin'], '460 cal total. {"sodium_mg":266.7,"cholesterol_mg":46.7,"sat_fat_g":2.7,"trans_fat_g":0.0}'),
('chilis_molten_chocolate_cake', 'Chili''s Molten Chocolate Cake', 390.0, 10.0, 52.0, 20.0, 3.0, 36.7, 300, 300, 'chilis.com', ARRAY['chilis molten cake', 'chilis lava cake'], '1170 cal total. {"sodium_mg":200.0,"cholesterol_mg":53.3,"sat_fat_g":10.0,"trans_fat_g":0.0}'),
('chilis_skillet_cookie', 'Chili''s Skillet Chocolate Chip Cookie', 393.3, 8.3, 52.7, 18.3, 1.7, 36.0, 300, 300, 'chilis.com', ARRAY['chilis cookie skillet', 'chilis skillet cookie'], '1180 cal total. {"sodium_mg":233.3,"cholesterol_mg":40.0,"sat_fat_g":10.0,"trans_fat_g":0.0}'),
('chilis_loaded_mashed_potatoes', 'Chili''s Loaded Mashed Potatoes', 200.0, 4.0, 16.0, 12.0, 1.3, 1.3, 150, 150, 'chilis.com', ARRAY['chilis mashed potatoes'], '300 cal per side. {"sodium_mg":400.0,"cholesterol_mg":16.7,"sat_fat_g":5.3,"trans_fat_g":0.0}'),
('applebees_classic_burger', 'Applebee''s Classic Burger', 363.3, 14.3, 31.0, 20.3, 2.0, 3.7, 300, 300, 'applebees.com', ARRAY['applebees classic burger', 'applebees burger'], '1090 cal total. {"sodium_mg":560.0,"cholesterol_mg":36.7,"sat_fat_g":7.7,"trans_fat_g":0.7}'),
('applebees_classic_cheeseburger', 'Applebee''s Classic Cheeseburger', 406.7, 16.7, 31.7, 24.0, 2.0, 3.7, 300, 300, 'applebees.com', ARRAY['applebees cheeseburger'], '1220 cal total. {"sodium_mg":633.3,"cholesterol_mg":43.3,"sat_fat_g":10.0,"trans_fat_g":0.7}'),
('applebees_quesadilla_burger', 'Applebee''s Quesadilla Burger', 451.4, 20.0, 27.1, 29.4, 2.0, 3.7, 350, 350, 'applebees.com', ARRAY['applebees quesadilla burger'], '1580 cal total. {"sodium_mg":742.9,"cholesterol_mg":42.9,"sat_fat_g":11.4,"trans_fat_g":0.9}'),
('applebees_whisky_bacon_burger', 'Applebee''s Whisky Bacon Burger', 454.3, 18.0, 34.0, 27.7, 2.0, 8.6, 350, 350, 'applebees.com', ARRAY['applebees whisky bacon', 'applebees whiskey bacon burger'], '1590 cal total. {"sodium_mg":714.3,"cholesterol_mg":40.0,"sat_fat_g":10.0,"trans_fat_g":0.9}'),
('applebees_chicken_tenders_plate', 'Applebee''s Chicken Tenders Plate', 360.0, 12.3, 30.7, 21.0, 1.3, 2.3, 300, 300, 'applebees.com', ARRAY['applebees chicken tenders'], '1080 cal total. {"sodium_mg":686.7,"cholesterol_mg":26.7,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('applebees_chicken_wonton_tacos', 'Applebee''s Chicken Wonton Tacos', 295.0, 15.0, 29.0, 13.5, 1.5, 5.5, 200, 200, 'applebees.com', ARRAY['applebees wonton tacos'], '590 cal total. {"sodium_mg":775.0,"cholesterol_mg":25.0,"sat_fat_g":3.5,"trans_fat_g":0.0}'),
('applebees_grilled_chicken_breast', 'Applebee''s Grilled Chicken Breast', 183.3, 16.3, 14.3, 7.3, 1.0, 1.3, 300, 300, 'applebees.com', ARRAY['applebees grilled chicken'], '550 cal total. {"sodium_mg":466.7,"cholesterol_mg":40.0,"sat_fat_g":1.7,"trans_fat_g":0.0}'),
('applebees_chicken_parm_fettuccine', 'Applebee''s Chicken Parmesan Fettuccine', 307.5, 14.0, 23.5, 17.8, 2.5, 5.0, 400, 400, 'applebees.com', ARRAY['applebees chicken parm'], '1230 cal total. {"sodium_mg":650.0,"cholesterol_mg":32.5,"sat_fat_g":7.5,"trans_fat_g":0.0}'),
('applebees_bourbon_chicken_shrimp', 'Applebee''s Bourbon Street Chicken & Shrimp', 266.7, 18.7, 15.7, 14.7, 1.3, 3.0, 300, 300, 'applebees.com', ARRAY['applebees bourbon street chicken'], '800 cal total. {"sodium_mg":766.7,"cholesterol_mg":60.0,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('applebees_bourbon_street_steak', 'Applebee''s Bourbon Street Steak', 273.3, 17.3, 15.7, 16.0, 1.0, 3.0, 300, 300, 'applebees.com', ARRAY['applebees bourbon steak', 'applebees steak'], '820 cal total. {"sodium_mg":700.0,"cholesterol_mg":46.7,"sat_fat_g":6.7,"trans_fat_g":0.0}'),
('applebees_sirloin_6oz', 'Applebee''s USDA Select Sirloin (6 oz)', 186.7, 14.0, 14.3, 8.3, 1.0, 1.0, 300, 300, 'applebees.com', ARRAY['applebees sirloin 6oz'], '560 cal total. {"sodium_mg":533.3,"cholesterol_mg":40.0,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('applebees_ribeye', 'Applebee''s Ribeye', 290.0, 25.3, 15.3, 14.3, 0.7, 1.0, 300, 300, 'applebees.com', ARRAY['applebees ribeye'], '870 cal total. {"sodium_mg":500.0,"cholesterol_mg":56.7,"sat_fat_g":6.0,"trans_fat_g":0.0}'),
('applebees_half_rack_ribs', 'Applebee''s Double-Glazed Baby Back Ribs (Half)', 253.3, 14.7, 17.7, 14.0, 0.0, 10.0, 300, 300, 'applebees.com', ARRAY['applebees baby back ribs half'], '760 cal half rack. {"sodium_mg":566.7,"cholesterol_mg":50.0,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('applebees_spinach_artichoke_dip', 'Applebee''s Spinach & Artichoke Dip', 272.2, 5.8, 24.7, 16.9, 2.2, 3.6, 360, 360, 'applebees.com', ARRAY['applebees spinach dip'], '980 cal total. {"sodium_mg":444.4,"cholesterol_mg":16.7,"sat_fat_g":6.9,"trans_fat_g":0.0}'),
('applebees_brew_pub_pretzels', 'Applebee''s Brew Pub Pretzels & Beer Cheese', 290.0, 8.5, 36.5, 12.3, 1.5, 3.0, 400, 400, 'applebees.com', ARRAY['applebees pretzels'], '1160 cal total. {"sodium_mg":600.0,"cholesterol_mg":15.0,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('applebees_oriental_crispy_salad', 'Applebee''s Oriental Chicken Salad (Crispy)', 390.0, 10.0, 29.5, 26.3, 4.5, 14.0, 400, 400, 'applebees.com', ARRAY['applebees oriental salad'], '1560 cal total. {"sodium_mg":475.0,"cholesterol_mg":17.5,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('applebees_caesar_grilled_chicken', 'Applebee''s Caesar Salad (Grilled Chicken)', 271.4, 16.3, 16.0, 16.3, 2.6, 2.3, 350, 350, 'applebees.com', ARRAY['applebees caesar salad'], '950 cal total. {"sodium_mg":514.3,"cholesterol_mg":28.6,"sat_fat_g":5.7,"trans_fat_g":0.0}'),
('applebees_three_cheese_penne', 'Applebee''s Three-Cheese Chicken Penne', 337.5, 19.3, 25.5, 17.8, 2.5, 4.5, 400, 400, 'applebees.com', ARRAY['applebees chicken penne'], '1350 cal total. {"sodium_mg":625.0,"cholesterol_mg":32.5,"sat_fat_g":7.5,"trans_fat_g":0.0}'),
('applebees_double_crunch_shrimp', 'Applebee''s Double Crunch Shrimp', 282.5, 7.0, 34.8, 12.5, 1.3, 1.3, 400, 400, 'applebees.com', ARRAY['applebees double crunch shrimp'], '1130 cal total. {"sodium_mg":475.0,"cholesterol_mg":25.0,"sat_fat_g":2.5,"trans_fat_g":0.0}'),
('applebees_chicken_tortilla_soup', 'Applebee''s Chicken Tortilla Soup (Bowl)', 116.7, 4.6, 10.8, 6.3, 1.3, 2.1, 240, 240, 'applebees.com', ARRAY['applebees tortilla soup'], '280 cal per bowl. {"sodium_mg":416.7,"cholesterol_mg":10.4,"sat_fat_g":2.5,"trans_fat_g":0.0}'),
('applebees_classic_fries', 'Applebee''s Classic Fries', 266.7, 4.0, 35.3, 12.0, 2.7, 0.0, 150, 150, 'applebees.com', ARRAY['applebees fries'], '400 cal total. {"sodium_mg":333.3,"cholesterol_mg":0,"sat_fat_g":2.0,"trans_fat_g":0.0}'),
('applebees_loaded_waffle_fries', 'Applebee''s Brew Pub Loaded Waffle Fries', 387.5, 7.8, 23.5, 28.8, 2.3, 1.3, 400, 400, 'applebees.com', ARRAY['applebees waffle fries', 'applebees loaded fries'], '1550 cal total. {"sodium_mg":587.5,"cholesterol_mg":25.0,"sat_fat_g":12.5,"trans_fat_g":0.0}'),
('olivegarden_breadstick', 'Olive Garden Garlic Breadstick (1)', 350.0, 10.0, 62.5, 6.3, 1.3, 1.3, 40, 40, 'olivegarden.com', ARRAY['olive garden breadstick', 'olive garden bread'], '140 cal per breadstick. {"sodium_mg":650.0,"cholesterol_mg":0,"sat_fat_g":1.3,"trans_fat_g":0.0}'),
('olivegarden_minestrone', 'Olive Garden Minestrone Soup', 45.8, 2.1, 7.1, 0.4, 1.7, 1.3, 240, 240, 'olivegarden.com', ARRAY['olive garden minestrone'], '110 cal per serving. {"sodium_mg":270.8,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('olivegarden_pasta_fagioli', 'Olive Garden Pasta e Fagioli Soup', 62.5, 3.3, 6.7, 2.1, 1.3, 0.8, 240, 240, 'olivegarden.com', ARRAY['olive garden pasta fagioli'], '150 cal per serving. {"sodium_mg":308.3,"cholesterol_mg":4.2,"sat_fat_g":0.8,"trans_fat_g":0.0}'),
('olivegarden_zuppa_toscana', 'Olive Garden Zuppa Toscana Soup', 91.7, 2.9, 6.3, 6.3, 0.8, 0.8, 240, 240, 'olivegarden.com', ARRAY['olive garden zuppa toscana', 'olive garden zuppa'], '220 cal per serving. {"sodium_mg":337.5,"cholesterol_mg":10.4,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('olivegarden_chicken_gnocchi', 'Olive Garden Chicken & Gnocchi Soup', 95.8, 4.6, 9.2, 5.0, 0.4, 0.8, 240, 240, 'olivegarden.com', ARRAY['olive garden chicken gnocchi'], '230 cal per serving. {"sodium_mg":395.8,"cholesterol_mg":10.4,"sat_fat_g":2.9,"trans_fat_g":0.0}'),
('olivegarden_house_salad', 'Olive Garden House Salad (with dressing)', 100.0, 1.3, 8.7, 6.7, 1.3, 2.7, 150, 150, 'olivegarden.com', ARRAY['olive garden salad', 'olive garden house salad'], '150 cal per serving. {"sodium_mg":360.0,"cholesterol_mg":3.3,"sat_fat_g":1.3,"trans_fat_g":0.0}'),
('olivegarden_fettuccine_alfredo', 'Olive Garden Fettuccine Alfredo', 252.5, 7.5, 24.3, 14.0, 1.8, 1.3, 400, 400, 'olivegarden.com', ARRAY['olive garden fettuccine alfredo', 'olive garden alfredo'], '1010 cal total. {"sodium_mg":212.5,"cholesterol_mg":38.8,"sat_fat_g":8.5,"trans_fat_g":0.4}'),
('olivegarden_chicken_alfredo', 'Olive Garden Chicken Alfredo (Crispy)', 314.0, 14.0, 24.6, 22.8, 1.2, 1.6, 500, 500, 'olivegarden.com', ARRAY['olive garden chicken alfredo'], '1570 cal total. {"sodium_mg":340.0,"cholesterol_mg":42.0,"sat_fat_g":9.2,"trans_fat_g":0.4}'),
('olivegarden_spaghetti_marinara', 'Olive Garden Spaghetti with Marinara', 163.3, 4.0, 27.7, 4.0, 1.3, 2.7, 300, 300, 'olivegarden.com', ARRAY['olive garden spaghetti', 'olive garden spaghetti marinara'], '490 cal total. {"sodium_mg":230.0,"cholesterol_mg":0,"sat_fat_g":1.3,"trans_fat_g":0.0}'),
('olivegarden_chicken_parmigiana', 'Olive Garden Chicken Parmigiana', 204.0, 9.8, 21.2, 9.0, 0.8, 2.4, 500, 500, 'olivegarden.com', ARRAY['olive garden chicken parm'], '1020 cal total. {"sodium_mg":380.0,"cholesterol_mg":24.0,"sat_fat_g":3.4,"trans_fat_g":0.0}'),
('olivegarden_tour_of_italy', 'Olive Garden Tour of Italy', 310.0, 14.4, 19.8, 19.4, 1.4, 2.6, 500, 500, 'olivegarden.com', ARRAY['olive garden tour of italy'], '1550 cal total. {"sodium_mg":500.0,"cholesterol_mg":44.0,"sat_fat_g":8.0,"trans_fat_g":0.4}'),
('olivegarden_lasagna_classico', 'Olive Garden Lasagna Classico', 240.0, 11.3, 20.0, 12.0, 1.3, 3.0, 400, 400, 'olivegarden.com', ARRAY['olive garden lasagna'], '960 cal total. {"sodium_mg":375.0,"cholesterol_mg":30.0,"sat_fat_g":5.5,"trans_fat_g":0.3}'),
('olivegarden_five_cheese_ziti', 'Olive Garden Five Cheese Ziti al Forno', 260.0, 8.0, 27.5, 13.5, 1.3, 2.0, 400, 400, 'olivegarden.com', ARRAY['olive garden five cheese ziti'], '1040 cal total. {"sodium_mg":362.5,"cholesterol_mg":22.5,"sat_fat_g":6.8,"trans_fat_g":0.3}'),
('olivegarden_herb_grilled_salmon', 'Olive Garden Herb-Grilled Salmon', 203.3, 16.7, 3.0, 15.0, 1.3, 0.7, 300, 300, 'olivegarden.com', ARRAY['olive garden salmon'], '610 cal total. {"sodium_mg":280.0,"cholesterol_mg":33.3,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('olivegarden_grilled_chicken_margherita', 'Olive Garden Grilled Chicken Margherita', 216.7, 21.7, 5.0, 13.0, 1.7, 1.0, 300, 300, 'olivegarden.com', ARRAY['olive garden chicken margherita'], '650 cal total. {"sodium_mg":356.7,"cholesterol_mg":40.0,"sat_fat_g":4.3,"trans_fat_g":0.0}'),
('olivegarden_fried_mozzarella', 'Olive Garden Fried Mozzarella', 266.7, 11.0, 19.0, 16.3, 1.3, 1.7, 300, 300, 'olivegarden.com', ARRAY['olive garden mozzarella sticks'], '800 cal total. {"sodium_mg":533.3,"cholesterol_mg":23.3,"sat_fat_g":6.7,"trans_fat_g":0.0}'),
('olivegarden_calamari', 'Olive Garden Calamari', 223.3, 8.0, 16.0, 14.0, 0.7, 1.3, 300, 300, 'olivegarden.com', ARRAY['olive garden calamari'], '670 cal total. {"sodium_mg":500.0,"cholesterol_mg":33.3,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('olivegarden_tiramisu', 'Olive Garden Tiramisu', 235.0, 4.0, 27.0, 13.5, 0.5, 20.0, 200, 200, 'olivegarden.com', ARRAY['olive garden tiramisu'], '470 cal total. {"sodium_mg":100.0,"cholesterol_mg":47.5,"sat_fat_g":7.5,"trans_fat_g":0.0}'),
('olivegarden_black_tie_mousse_cake', 'Olive Garden Black Tie Mousse Cake', 375.0, 4.5, 38.0, 25.0, 2.0, 28.0, 200, 200, 'olivegarden.com', ARRAY['olive garden mousse cake'], '750 cal total. {"sodium_mg":125.0,"cholesterol_mg":35.0,"sat_fat_g":14.0,"trans_fat_g":0.0}'),
('olivegarden_strawberry_cream_cake', 'Olive Garden Strawberry Cream Cake', 270.0, 4.5, 34.5, 13.0, 1.0, 24.0, 200, 200, 'olivegarden.com', ARRAY['olive garden strawberry cake'], '540 cal total. {"sodium_mg":110.0,"cholesterol_mg":30.0,"sat_fat_g":7.5,"trans_fat_g":0.0}'),
('olivegarden_warm_italian_doughnuts', 'Olive Garden Warm Italian Doughnuts', 270.0, 6.7, 39.7, 9.3, 2.0, 18.3, 300, 300, 'olivegarden.com', ARRAY['olive garden doughnuts', 'olive garden zeppoli'], '810 cal total. {"sodium_mg":200.0,"cholesterol_mg":16.7,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('bww_traditional_wings_6ct', 'BWW Traditional Wings (6ct)', 238.9, 27.8, 0.0, 13.3, 0.0, 0.0, 180, 180, 'buffalowildwings.com', ARRAY['bww bone in wings 6', 'buffalo wild wings traditional 6'], '430 cal for 6ct. {"sodium_mg":111.1,"cholesterol_mg":94.4,"sat_fat_g":3.9,"trans_fat_g":0.0}'),
('bww_traditional_wings_10ct', 'BWW Traditional Wings (10ct)', 240.0, 29.3, 0.0, 13.7, 0.0, 0.0, 300, 300, 'buffalowildwings.com', ARRAY['bww bone in wings 10', 'buffalo wild wings traditional 10'], '720 cal for 10ct. {"sodium_mg":110.0,"cholesterol_mg":93.3,"sat_fat_g":3.7,"trans_fat_g":0.0}'),
('bww_traditional_wings_20ct', 'BWW Traditional Wings (20ct)', 240.0, 29.3, 0.0, 13.7, 0.0, 0.0, 600, 600, 'buffalowildwings.com', ARRAY['bww bone in wings 20'], '1440 cal for 20ct. {"sodium_mg":110.0,"cholesterol_mg":93.3,"sat_fat_g":3.7,"trans_fat_g":0.0}'),
('bww_boneless_wings_6ct', 'BWW Boneless Wings (6ct)', 211.8, 17.1, 11.8, 11.2, 0.6, 0.0, 170, 170, 'buffalowildwings.com', ARRAY['bww boneless 6', 'buffalo wild wings boneless 6'], '360 cal for 6ct. {"sodium_mg":741.2,"cholesterol_mg":50.0,"sat_fat_g":4.1,"trans_fat_g":0.0}'),
('bww_boneless_wings_10ct', 'BWW Boneless Wings (10ct)', 215.5, 17.0, 12.0, 11.0, 0.4, 0.0, 283, 283, 'buffalowildwings.com', ARRAY['bww boneless 10', 'buffalo wild wings boneless 10'], '610 cal for 10ct. {"sodium_mg":742.0,"cholesterol_mg":49.5,"sat_fat_g":4.2,"trans_fat_g":0.0}'),
('bww_hand_breaded_tenders_3ct', 'BWW Hand-Breaded Chicken Tenders (3ct)', 272.2, 19.4, 18.9, 13.3, 0.6, 0.6, 180, 180, 'buffalowildwings.com', ARRAY['bww chicken tenders'], '490 cal for 3ct. {"sodium_mg":538.9,"cholesterol_mg":38.9,"sat_fat_g":2.8,"trans_fat_g":0.0}'),
('bww_all_american_bacon_cheeseburger', 'BWW All-American Bacon Cheeseburger', 372.0, 22.4, 15.2, 24.4, 0.8, 2.4, 250, 250, 'buffalowildwings.com', ARRAY['bww bacon cheeseburger'], '930 cal total. {"sodium_mg":568.0,"cholesterol_mg":56.0,"sat_fat_g":10.0,"trans_fat_g":0.8}'),
('bww_bbq_bacon_burger', 'BWW BBQ Bacon Burger', 363.3, 19.0, 19.3, 23.3, 1.0, 5.0, 300, 300, 'buffalowildwings.com', ARRAY['bww bbq burger'], '1090 cal total. {"sodium_mg":590.0,"cholesterol_mg":50.0,"sat_fat_g":9.3,"trans_fat_g":0.7}'),
('bww_mushroom_swiss_burger', 'BWW Mushroom Swiss Burger', 384.0, 22.0, 16.4, 25.6, 0.8, 2.0, 250, 250, 'buffalowildwings.com', ARRAY['bww mushroom swiss'], '960 cal total. {"sodium_mg":536.0,"cholesterol_mg":52.0,"sat_fat_g":10.4,"trans_fat_g":0.8}'),
('bww_cheeseburger', 'BWW Cheeseburger', 235.0, 13.5, 17.0, 12.5, 0.5, 2.0, 200, 200, 'buffalowildwings.com', ARRAY['bww cheeseburger'], '470 cal total. {"sodium_mg":445.0,"cholesterol_mg":37.5,"sat_fat_g":5.5,"trans_fat_g":0.5}'),
('bww_buffalo_ranch_chicken_sandwich', 'BWW Buffalo Ranch Chicken Sandwich', 375.0, 16.0, 30.0, 21.0, 1.5, 3.0, 200, 200, 'buffalowildwings.com', ARRAY['bww chicken sandwich'], '750 cal total. {"sodium_mg":825.0,"cholesterol_mg":37.5,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('bww_nashville_hot_chicken_sandwich', 'BWW Nashville Hot Chicken Sandwich', 395.8, 13.8, 27.5, 25.8, 1.3, 2.1, 240, 240, 'buffalowildwings.com', ARRAY['bww nashville hot'], '950 cal total. {"sodium_mg":858.3,"cholesterol_mg":29.2,"sat_fat_g":5.4,"trans_fat_g":0.0}'),
('bww_classic_chicken_wrap', 'BWW Classic Chicken Wrap with Boneless Wings', 268.0, 13.6, 27.2, 11.6, 1.2, 2.4, 250, 250, 'buffalowildwings.com', ARRAY['bww chicken wrap'], '670 cal total. {"sodium_mg":708.0,"cholesterol_mg":28.0,"sat_fat_g":3.6,"trans_fat_g":0.0}'),
('bww_chicken_caesar_salad', 'BWW Chicken Caesar Salad', 247.2, 15.3, 9.2, 16.7, 2.5, 1.7, 360, 360, 'buffalowildwings.com', ARRAY['bww caesar salad'], '890 cal total. {"sodium_mg":436.1,"cholesterol_mg":30.6,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('bww_garden_side_salad', 'BWW Garden Side Salad', 60.0, 3.3, 5.3, 3.0, 1.3, 1.3, 150, 150, 'buffalowildwings.com', ARRAY['bww side salad'], '90 cal total. {"sodium_mg":66.7,"cholesterol_mg":3.3,"sat_fat_g":1.0,"trans_fat_g":0.0}'),
('bww_french_fries', 'BWW French Fries', 210.0, 2.0, 39.0, 5.5, 3.0, 0.0, 200, 200, 'buffalowildwings.com', ARRAY['bww fries'], '420 cal total. {"sodium_mg":325.0,"cholesterol_mg":0,"sat_fat_g":1.0,"trans_fat_g":0.0}'),
('bww_tots', 'BWW Tots (Regular)', 310.0, 2.5, 30.0, 20.0, 2.5, 0.5, 200, 200, 'buffalowildwings.com', ARRAY['bww tater tots'], '620 cal total. {"sodium_mg":475.0,"cholesterol_mg":0,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('bww_mozzarella_sticks', 'BWW Mozzarella Sticks', 206.7, 8.7, 20.0, 10.7, 0.7, 1.3, 150, 150, 'buffalowildwings.com', ARRAY['bww mozzarella sticks'], '310 cal total. {"sodium_mg":473.3,"cholesterol_mg":20.0,"sat_fat_g":4.0,"trans_fat_g":0.0}'),
('bww_beer_battered_onion_rings', 'BWW Beer-Battered Onion Rings', 275.0, 2.5, 32.5, 15.5, 2.0, 3.0, 200, 200, 'buffalowildwings.com', ARRAY['bww onion rings'], '550 cal total. {"sodium_mg":500.0,"cholesterol_mg":0,"sat_fat_g":3.0,"trans_fat_g":0.0}'),
('bww_cheddar_cheese_curds', 'BWW Cheddar Cheese Curds', 353.3, 18.7, 12.0, 25.3, 0.0, 0.7, 150, 150, 'buffalowildwings.com', ARRAY['bww cheese curds'], '530 cal total. {"sodium_mg":626.7,"cholesterol_mg":46.7,"sat_fat_g":10.7,"trans_fat_g":0.0}'),
('bww_mac_and_cheese', 'BWW Mac & Cheese', 245.8, 8.8, 20.8, 13.8, 0.8, 1.3, 240, 240, 'buffalowildwings.com', ARRAY['bww mac cheese'], '590 cal total. {"sodium_mg":416.7,"cholesterol_mg":20.8,"sat_fat_g":7.5,"trans_fat_g":0.0}'),
('bww_chips_salsa', 'BWW Chips & Salsa', 260.0, 4.0, 36.0, 11.0, 2.5, 2.5, 200, 200, 'buffalowildwings.com', ARRAY['bww chips'], '520 cal total. {"sodium_mg":350.0,"cholesterol_mg":0,"sat_fat_g":1.5,"trans_fat_g":0.0}'),
('bww_asian_zing_sauce', 'BWW Asian Zing Sauce (2 fl oz)', 283.3, 1.7, 68.3, 0.0, 0.0, 60.0, 60, 60, 'buffalowildwings.com', ARRAY['bww asian zing'], '170 cal per 2 fl oz. {"sodium_mg":1433.3,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('bww_mango_habanero_sauce', 'BWW Mango Habanero Sauce (2 fl oz)', 266.7, 0.0, 60.0, 1.7, 0.0, 53.3, 60, 60, 'buffalowildwings.com', ARRAY['bww mango habanero'], '160 cal per 2 fl oz. {"sodium_mg":1266.7,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('bww_honey_bbq_sauce', 'BWW Honey BBQ Sauce (2 fl oz)', 233.3, 0.0, 56.7, 0.0, 0.0, 46.7, 60, 60, 'buffalowildwings.com', ARRAY['bww honey bbq'], '140 cal per 2 fl oz. {"sodium_mg":1133.3,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('bww_medium_sauce', 'BWW Medium Sauce (2 fl oz)', 100.0, 1.7, 5.0, 10.0, 0.0, 1.7, 60, 60, 'buffalowildwings.com', ARRAY['bww medium'], '60 cal per 2 fl oz. {"sodium_mg":1600.0,"cholesterol_mg":0,"sat_fat_g":1.7,"trans_fat_g":0.0}'),
('bww_spicy_garlic_sauce', 'BWW Spicy Garlic Sauce (2 fl oz)', 150.0, 1.7, 6.7, 13.3, 0.0, 1.7, 60, 60, 'buffalowildwings.com', ARRAY['bww spicy garlic'], '90 cal per 2 fl oz. {"sodium_mg":1633.3,"cholesterol_mg":0,"sat_fat_g":1.7,"trans_fat_g":0.0}'),
('bww_ranch_dressing_2oz', 'BWW Ranch Dressing (2 fl oz)', 533.3, 1.7, 3.3, 56.7, 0.0, 1.7, 60, 60, 'buffalowildwings.com', ARRAY['bww ranch'], '320 cal per 2 fl oz. {"sodium_mg":733.3,"cholesterol_mg":16.7,"sat_fat_g":8.3,"trans_fat_g":0.0}'),
('red_robin_banzai_burger', 'Red Robin Banzai Burger', 400.0, 15.6, 23.2, 27.2, 1.6, 6.0, 250, 250, 'redrobin.com', ARRAY['red robin banzai'], '1000 cal total. {"sodium_mg":496.0,"cholesterol_mg":36.0,"sat_fat_g":10.8,"trans_fat_g":0.8}'),
('red_robin_bacon_cheeseburger', 'Red Robin Bacon Cheeseburger', 384.0, 16.8, 19.6, 26.8, 1.2, 2.4, 250, 250, 'redrobin.com', ARRAY['red robin bacon cheeseburger'], '960 cal total. {"sodium_mg":560.0,"cholesterol_mg":52.0,"sat_fat_g":11.6,"trans_fat_g":1.2}'),
('red_robin_bacon_cheeseburger_double', 'Red Robin Bacon Cheeseburger (Double)', 430.0, 22.0, 15.7, 30.7, 0.7, 2.0, 300, 300, 'redrobin.com', ARRAY['red robin double bacon cheeseburger'], '1290 cal total. {"sodium_mg":536.7,"cholesterol_mg":60.0,"sat_fat_g":13.3,"trans_fat_g":1.7}'),
('red_robin_gourmet_cheeseburger', 'Red Robin Gourmet Cheeseburger', 344.0, 14.8, 22.8, 21.6, 1.2, 3.6, 250, 250, 'redrobin.com', ARRAY['red robin gourmet'], '860 cal total. {"sodium_mg":504.0,"cholesterol_mg":40.0,"sat_fat_g":9.2,"trans_fat_g":0.8}'),
('red_robin_monster_burger', 'Red Robin Monster Burger', 436.7, 21.7, 20.0, 29.3, 1.3, 3.3, 300, 300, 'redrobin.com', ARRAY['red robin monster'], '1310 cal total. {"sodium_mg":543.3,"cholesterol_mg":63.3,"sat_fat_g":13.3,"trans_fat_g":1.7}'),
('red_robin_turkey_burger', 'Red Robin Turkey Burger', 316.0, 15.6, 16.8, 20.8, 2.0, 4.0, 250, 250, 'redrobin.com', ARRAY['red robin turkey burger'], '790 cal total. {"sodium_mg":504.0,"cholesterol_mg":36.0,"sat_fat_g":8.0,"trans_fat_g":0.4}'),
('red_robin_scorpion_burger', 'Red Robin Scorpion Burger', 360.0, 13.3, 22.7, 24.3, 1.3, 5.3, 300, 300, 'redrobin.com', ARRAY['red robin scorpion'], '1080 cal total. {"sodium_mg":526.7,"cholesterol_mg":40.0,"sat_fat_g":9.3,"trans_fat_g":0.7}'),
('red_robin_avocado_bacon_burger', 'Red Robin Smashed Avocado N Bacon Burger', 376.0, 19.2, 19.6, 24.8, 2.4, 2.4, 250, 250, 'redrobin.com', ARRAY['red robin avocado burger', 'red robin smashed avocado'], '940 cal total. {"sodium_mg":480.0,"cholesterol_mg":48.0,"sat_fat_g":10.4,"trans_fat_g":1.2}'),
('red_robin_california_chicken', 'Red Robin California Chicken Sandwich', 373.7, 26.3, 24.7, 19.5, 2.1, 3.2, 190, 190, 'redrobin.com', ARRAY['red robin california chicken'], '710 cal total. {"sodium_mg":647.4,"cholesterol_mg":42.1,"sat_fat_g":4.7,"trans_fat_g":0.0}'),
('red_robin_whiskey_bbq_chicken_wrap', 'Red Robin Whiskey River BBQ Chicken Wrap', 360.0, 16.8, 33.2, 17.6, 2.0, 6.8, 250, 250, 'redrobin.com', ARRAY['red robin chicken wrap', 'red robin bbq wrap'], '900 cal total. {"sodium_mg":656.0,"cholesterol_mg":32.0,"sat_fat_g":5.6,"trans_fat_g":0.0}'),
('red_robin_teriyaki_chicken_sandwich', 'Red Robin Teriyaki Chicken Sandwich', 390.0, 21.5, 30.0, 21.0, 1.5, 6.0, 200, 200, 'redrobin.com', ARRAY['red robin teriyaki chicken'], '780 cal total. {"sodium_mg":710.0,"cholesterol_mg":42.5,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('red_robin_ensenada_chicken_platter', 'Red Robin Ensenada Chicken Platter', 133.3, 12.7, 7.3, 6.3, 1.3, 1.3, 300, 300, 'redrobin.com', ARRAY['red robin ensenada chicken'], '400 cal total. {"sodium_mg":300.0,"cholesterol_mg":26.7,"sat_fat_g":1.7,"trans_fat_g":0.0}'),
('red_robin_fish_and_chips', 'Red Robin House-Battered Fish & Chips', 358.6, 11.4, 31.8, 20.9, 2.5, 0.7, 449, 449, 'redrobin.com', ARRAY['red robin fish chips', 'red robin fish and chips'], '1610 cal total. {"sodium_mg":356.3,"cholesterol_mg":20.0,"sat_fat_g":3.6,"trans_fat_g":0.0}'),
('red_robin_avo_cobb_salad', 'Red Robin Avo-Cobb-O Salad', 157.1, 14.0, 7.1, 9.1, 3.1, 2.3, 350, 350, 'redrobin.com', ARRAY['red robin cobb salad', 'red robin avo cobb'], '550 cal total. {"sodium_mg":400.0,"cholesterol_mg":34.3,"sat_fat_g":3.7,"trans_fat_g":0.0}'),
('red_robin_simply_grilled_chicken_salad', 'Red Robin Simply Grilled Chicken Salad', 82.9, 10.9, 4.3, 2.9, 1.4, 1.4, 350, 350, 'redrobin.com', ARRAY['red robin grilled chicken salad'], '290 cal total. {"sodium_mg":214.3,"cholesterol_mg":20.0,"sat_fat_g":0.9,"trans_fat_g":0.0}'),
('red_robin_chicken_tortilla_soup_cup', 'Red Robin Chicken Tortilla Soup (Cup)', 70.8, 5.0, 5.4, 3.3, 0.8, 1.3, 240, 240, 'redrobin.com', ARRAY['red robin tortilla soup'], '170 cal per cup. {"sodium_mg":279.2,"cholesterol_mg":10.4,"sat_fat_g":1.3,"trans_fat_g":0.0}'),
('red_robin_french_onion_soup_cup', 'Red Robin French Onion Soup (Cup)', 45.8, 2.5, 2.9, 3.3, 0.4, 1.3, 240, 240, 'redrobin.com', ARRAY['red robin french onion soup'], '110 cal per cup. {"sodium_mg":354.2,"cholesterol_mg":8.3,"sat_fat_g":2.1,"trans_fat_g":0.0}'),
('red_robin_clam_chowder_cup', 'Red Robin Clamdigger''s Clam Chowder (Cup)', 79.2, 1.7, 5.4, 5.4, 0.4, 0.8, 240, 240, 'redrobin.com', ARRAY['red robin clam chowder'], '190 cal per cup. {"sodium_mg":312.5,"cholesterol_mg":12.5,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('red_robin_chili_cup', 'Red Robin Red''s Chili Chili (Cup)', 108.3, 6.3, 8.8, 5.4, 2.5, 1.3, 240, 240, 'redrobin.com', ARRAY['red robin chili'], '260 cal per cup. {"sodium_mg":387.5,"cholesterol_mg":18.8,"sat_fat_g":2.1,"trans_fat_g":0.0}'),
('red_robin_steak_fries', 'Red Robin Bottomless Steak Fries', 233.3, 3.3, 32.0, 10.7, 2.0, 0.0, 150, 150, 'redrobin.com', ARRAY['red robin fries', 'red robin steak fries'], '350 cal per serving. {"sodium_mg":286.7,"cholesterol_mg":0,"sat_fat_g":1.7,"trans_fat_g":0.0}'),
('red_robin_sweet_potato_fries', 'Red Robin Sweet Potato Fries', 225.0, 2.5, 15.0, 11.7, 1.7, 3.3, 120, 120, 'redrobin.com', ARRAY['red robin sweet potato fries'], '270 cal per serving. {"sodium_mg":416.7,"cholesterol_mg":0,"sat_fat_g":2.5,"trans_fat_g":0.0}'),
('red_robin_garlic_fries', 'Red Robin Bottomless Garlic Fries', 286.7, 5.3, 33.3, 14.7, 2.0, 0.7, 150, 150, 'redrobin.com', ARRAY['red robin garlic fries'], '430 cal per serving. {"sodium_mg":413.3,"cholesterol_mg":3.3,"sat_fat_g":3.3,"trans_fat_g":0.0}'),
('red_robin_onion_rings', 'Red Robin Onion Rings', 233.3, 5.0, 50.8, 0.8, 1.7, 3.3, 120, 120, 'redrobin.com', ARRAY['red robin onion rings'], '280 cal per serving. {"sodium_mg":250.0,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('red_robin_chocolate_milkshake', 'Red Robin Chocolate Milkshake', 212.5, 6.5, 30.6, 7.1, 1.0, 22.9, 480, 480, 'redrobin.com', ARRAY['red robin chocolate shake'], '1020 cal total. {"sodium_mg":72.9,"cholesterol_mg":18.8,"sat_fat_g":4.2,"trans_fat_g":0.0}'),
('red_robin_vanilla_milkshake', 'Red Robin Vanilla Milkshake', 191.7, 4.0, 26.3, 8.1, 0.0, 18.8, 480, 480, 'redrobin.com', ARRAY['red robin vanilla shake'], '920 cal total. {"sodium_mg":60.4,"cholesterol_mg":16.7,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('red_robin_oreo_cookie_milkshake', 'Red Robin Oreo Cookie Magic Milkshake (Monster)', 216.7, 4.4, 30.4, 9.0, 0.6, 21.5, 480, 480, 'redrobin.com', ARRAY['red robin oreo shake'], '1040 cal total. {"sodium_mg":72.9,"cholesterol_mg":14.6,"sat_fat_g":5.0,"trans_fat_g":0.0}'),
('red_robin_root_beer_float', 'Red Robin Root Beer Float', 145.0, 2.3, 33.0, 1.8, 0.0, 27.5, 400, 400, 'redrobin.com', ARRAY['red robin root beer float'], '580 cal total. {"sodium_mg":27.5,"cholesterol_mg":5.0,"sat_fat_g":1.0,"trans_fat_g":0.0}'),
('red_robin_buzz_sauce', 'Red Robin Buzz Sauce', 466.7, 0.0, 0.0, 53.3, 0.0, 0.0, 30, 30, 'redrobin.com', ARRAY['red robin buzz', 'red robin buzz wing sauce'], '140 cal per serving. {"sodium_mg":333.3,"cholesterol_mg":16.7,"sat_fat_g":10.0,"trans_fat_g":0.0}'),
('red_robin_whiskey_river_bbq_sauce', 'Red Robin Whiskey River BBQ Sauce', 433.3, 3.3, 100.0, 0.0, 0.0, 83.3, 30, 30, 'redrobin.com', ARRAY['red robin whiskey river sauce'], '130 cal per serving. {"sodium_mg":1333.3,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),
('red_robin_banzai_sauce', 'Red Robin Banzai Sauce', 366.7, 3.3, 90.0, 0.0, 0.0, 73.3, 30, 30, 'redrobin.com', ARRAY['red robin banzai sauce'], '110 cal per serving. {"sodium_mg":1166.7,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}')


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
