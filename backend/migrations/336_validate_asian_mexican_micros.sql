-- Migration 336: Validate Asian, Mexican, and miscellaneous chain micronutrients
-- Validated against published nutrition data from official chain websites and fastfoodnutrition.org
-- All values converted from per-serving to per-100g: value_per_100g = published_value / serving_weight_g * 100
-- Only corrections where DB value was off by >15% from published data
--
-- Chains validated (10): Chipotle, Panda Express, Church's Chicken, El Pollo Loco,
--   Panera Bread, Long John Silver's, Captain D's, Qdoba, Sweetgreen, Jollibee
--
-- Chains skipped (15) - no official per-item micronutrient data published online:
--   Moe's Southwest Grill, McAlister's Deli, Jason's Deli, Potbelly, Baja Fresh,
--   Pei Wei, P.F. Chang's, CAVA, Waba Grill, Noodles & Company, The Halal Guys,
--   Sarku Japan, Teriyaki Madness, Yoshinoya, Benihana
--
-- Items checked: 101 | Items corrected: 92

BEGIN;

-- Chipotle Black Beans: sodium_mg: 152.3->221.2
UPDATE food_nutrition_overrides SET
  sodium_mg = 221.2
WHERE display_name = 'Chipotle Black Beans';

-- Chipotle Pinto Beans: sodium_mg: 152.3->292.0, cholesterol_mg: 0.4->4.4
UPDATE food_nutrition_overrides SET
  sodium_mg = 292.0,
  cholesterol_mg = 4.4
WHERE display_name = 'Chipotle Pinto Beans';

-- Chipotle Cilantro-Lime White Rice: sodium_mg: 395.4->177.0, cholesterol_mg: 18.5->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 177.0,
  cholesterol_mg = 0.0
WHERE display_name = 'Chipotle Cilantro-Lime White Rice';

-- Chipotle Cilantro-Lime Brown Rice: sodium_mg: 400->132.7, saturated_fat_g: 1.23->0.9, cholesterol_mg: 19.6->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 132.7,
  saturated_fat_g = 0.9,
  cholesterol_mg = 0.0
WHERE display_name = 'Chipotle Cilantro-Lime Brown Rice';

-- Chipotle Chicken (Protein): sodium_mg: 505.7->327.4, cholesterol_mg: 57.5->101.8
UPDATE food_nutrition_overrides SET
  sodium_mg = 327.4,
  cholesterol_mg = 101.8
WHERE display_name = 'Chipotle Chicken (Protein)';

-- Chipotle Steak (Protein): saturated_fat_g: 2.23->1.8, cholesterol_mg: 105.7->57.5
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 1.8,
  cholesterol_mg = 57.5
WHERE display_name = 'Chipotle Steak (Protein)';

-- Chipotle Barbacoa Burrito Bowl: saturated_fat_g: 1.61->2.2, cholesterol_mg: 36->53.1
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 2.2,
  cholesterol_mg = 53.1
WHERE display_name = 'Chipotle Barbacoa Burrito Bowl';

-- Chipotle Sofritas Burrito Bowl: cholesterol_mg: 27.8->0.0
UPDATE food_nutrition_overrides SET
  cholesterol_mg = 0.0
WHERE display_name = 'Chipotle Sofritas Burrito Bowl';

-- Chipotle Guacamole (Side): sodium_mg: 504->190.0, saturated_fat_g: 7.7->2.0, cholesterol_mg: 24->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 190.0,
  saturated_fat_g = 2.0,
  cholesterol_mg = 0.0
WHERE display_name = 'Chipotle Guacamole (Side)';

-- Chipotle Sour Cream: sodium_mg: 425.6->52.6, saturated_fat_g: 5.05->12.3, cholesterol_mg: 20.3->70.2
UPDATE food_nutrition_overrides SET
  sodium_mg = 52.6,
  saturated_fat_g = 12.3,
  cholesterol_mg = 70.2
WHERE display_name = 'Chipotle Sour Cream';

-- Chipotle Shredded Cheese: sodium_mg: 530->642.9, saturated_fat_g: 10.28->17.9, cholesterol_mg: 47.1->107.1
UPDATE food_nutrition_overrides SET
  sodium_mg = 642.9,
  saturated_fat_g = 17.9,
  cholesterol_mg = 107.1
WHERE display_name = 'Chipotle Shredded Cheese';

-- Chipotle Queso Blanco (Side): sodium_mg: 525.4->350.9, saturated_fat_g: 5.53->8.8
UPDATE food_nutrition_overrides SET
  sodium_mg = 350.9,
  saturated_fat_g = 8.8
WHERE display_name = 'Chipotle Queso Blanco (Side)';

-- Chipotle Fresh Tomato Salsa (Pico): cholesterol_mg: 5->0.0
UPDATE food_nutrition_overrides SET
  cholesterol_mg = 0.0
WHERE display_name = 'Chipotle Fresh Tomato Salsa (Pico)';

-- Chipotle Tortilla Chips: sodium_mg: 449.6->371.7, saturated_fat_g: 7.24->3.1, cholesterol_mg: 24.1->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 371.7,
  saturated_fat_g = 3.1,
  cholesterol_mg = 0.0
WHERE display_name = 'Chipotle Tortilla Chips';

-- Chipotle Chips & Queso Blanco: sodium_mg: 550->348.0, saturated_fat_g: 3->6.6, cholesterol_mg: 10->22.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 348.0,
  saturated_fat_g = 6.6,
  cholesterol_mg = 22.0
WHERE display_name = 'Chipotle Chips & Queso Blanco';

-- Chipotle Chicken Burrito: sodium_mg: 497.3->216.7, saturated_fat_g: 1.17->1.0, cholesterol_mg: 36.3->24.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 216.7,
  saturated_fat_g = 1.0,
  cholesterol_mg = 24.0
WHERE display_name = 'Chipotle Chicken Burrito';

-- Chipotle Carnitas Burrito: sodium_mg: 493->252.1, saturated_fat_g: 1.4->1.1, cholesterol_mg: 34->14.6
UPDATE food_nutrition_overrides SET
  sodium_mg = 252.1,
  saturated_fat_g = 1.1,
  cholesterol_mg = 14.6
WHERE display_name = 'Chipotle Carnitas Burrito';

-- Chipotle Chicken Quesadilla: saturated_fat_g: 4.47->6.4
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 6.4
WHERE display_name = 'Chipotle Chicken Quesadilla';

-- Chipotle Chicken Burrito Bowl: sodium_mg: 385.6->327.4, saturated_fat_g: 1.5->1.8, cholesterol_mg: 30->101.8
UPDATE food_nutrition_overrides SET
  sodium_mg = 327.4,
  saturated_fat_g = 1.8,
  cholesterol_mg = 101.8
WHERE display_name = 'Chipotle Chicken Burrito Bowl';

-- Chipotle Steak Burrito Bowl: sodium_mg: 498.8->283.2, cholesterol_mg: 36->57.5
UPDATE food_nutrition_overrides SET
  sodium_mg = 283.2,
  cholesterol_mg = 57.5
WHERE display_name = 'Chipotle Steak Burrito Bowl';

-- Chipotle Chicken Tacos (3): sodium_mg: 450->209.0, saturated_fat_g: 4->1.6
UPDATE food_nutrition_overrides SET
  sodium_mg = 209.0,
  saturated_fat_g = 1.6
WHERE display_name = 'Chipotle Chicken Tacos (3)';

-- Chipotle Steak Tacos (3 pcs): sodium_mg: 512->226.7, saturated_fat_g: 2.1->1.8, cholesterol_mg: 40->21.7
UPDATE food_nutrition_overrides SET
  sodium_mg = 226.7,
  saturated_fat_g = 1.8,
  cholesterol_mg = 21.7
WHERE display_name = 'Chipotle Steak Tacos (3 pcs)';

-- Panda Express Orange Chicken: saturated_fat_g: 2.31->3.0, cholesterol_mg: 43.5->51.2
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 3.0,
  cholesterol_mg = 51.2
WHERE display_name = 'Panda Express Orange Chicken';

-- Panda Express Kung Pao Chicken: sodium_mg: 465.4->549.7, cholesterol_mg: 38.2->31.4
UPDATE food_nutrition_overrides SET
  sodium_mg = 549.7,
  cholesterol_mg = 31.4
WHERE display_name = 'Panda Express Kung Pao Chicken';

-- Panda Express Beijing Beef: sodium_mg: 464.4->377.4, cholesterol_mg: 37.8->22.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 377.4,
  cholesterol_mg = 22.0
WHERE display_name = 'Panda Express Beijing Beef';

-- Panda Express Broccoli Beef: sodium_mg: 412.7->337.7, saturated_fat_g: 1.47->1.0, cholesterol_mg: 23.8->7.8
UPDATE food_nutrition_overrides SET
  sodium_mg = 337.7,
  saturated_fat_g = 1.0,
  cholesterol_mg = 7.8
WHERE display_name = 'Panda Express Broccoli Beef';

-- Panda Express Black Pepper Chicken: sodium_mg: 435.6->631.3, saturated_fat_g: 2.96->2.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 631.3,
  saturated_fat_g = 2.0
WHERE display_name = 'Panda Express Black Pepper Chicken';

-- Panda Express Mushroom Chicken: sodium_mg: 430.6->518.5, saturated_fat_g: 2.57->1.5
UPDATE food_nutrition_overrides SET
  sodium_mg = 518.5,
  saturated_fat_g = 1.5
WHERE display_name = 'Panda Express Mushroom Chicken';

-- Panda Express Grilled Teriyaki Chicken: sodium_mg: 597.6->276.5, cholesterol_mg: 72.1->94.1
UPDATE food_nutrition_overrides SET
  sodium_mg = 276.5,
  cholesterol_mg = 94.1
WHERE display_name = 'Panda Express Grilled Teriyaki Chicken';

-- Panda Express Honey Sesame Chicken Breast: sodium_mg: 534->360.0, saturated_fat_g: 2.39->1.7, cholesterol_mg: 46.6->30.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 360.0,
  saturated_fat_g = 1.7,
  cholesterol_mg = 30.0
WHERE display_name = 'Panda Express Honey Sesame Chicken Breast';

-- Panda Express String Bean Chicken Breast: sodium_mg: 425.7->352.2, saturated_fat_g: 1.78->1.3, cholesterol_mg: 28->18.9
UPDATE food_nutrition_overrides SET
  sodium_mg = 352.2,
  saturated_fat_g = 1.3,
  cholesterol_mg = 18.9
WHERE display_name = 'Panda Express String Bean Chicken Breast';

-- Panda Express SweetFire Chicken Breast: sodium_mg: 469.4->225.6, cholesterol_mg: 39.8->27.4
UPDATE food_nutrition_overrides SET
  sodium_mg = 225.6,
  cholesterol_mg = 27.4
WHERE display_name = 'Panda Express SweetFire Chicken Breast';

-- Panda Express Sweet & Sour Chicken Breast: sodium_mg: 520.1->166.7, saturated_fat_g: 1.6->1.9, cholesterol_mg: 41->16.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 166.7,
  saturated_fat_g = 1.9,
  cholesterol_mg = 16.0
WHERE display_name = 'Panda Express Sweet & Sour Chicken Breast';

-- Panda Express Honey Walnut Shrimp: sodium_mg: 340.1->564.5
UPDATE food_nutrition_overrides SET
  sodium_mg = 564.5
WHERE display_name = 'Panda Express Honey Walnut Shrimp';

-- Panda Express Chow Mein: sodium_mg: 524.5->320.5, saturated_fat_g: 1.65->1.3, cholesterol_mg: 22.3->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 320.5,
  saturated_fat_g = 1.3,
  cholesterol_mg = 0.0
WHERE display_name = 'Panda Express Chow Mein';

-- Panda Express Fried Rice: sodium_mg: 440.9->320.5, cholesterol_mg: 28.3->44.9
UPDATE food_nutrition_overrides SET
  sodium_mg = 320.5,
  cholesterol_mg = 44.9
WHERE display_name = 'Panda Express Fried Rice';

-- Panda Express Steamed White Rice: sodium_mg: 391.1->0.0, cholesterol_mg: 19.2->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 0.0,
  cholesterol_mg = 0.0
WHERE display_name = 'Panda Express Steamed White Rice';

-- Panda Express Super Greens: sodium_mg: 395.2->130.3, cholesterol_mg: 19.5->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 130.3,
  cholesterol_mg = 0.0
WHERE display_name = 'Panda Express Super Greens';

-- Panda Express Chicken Potsticker (3 pc): sodium_mg: 445->266.0, saturated_fat_g: 2.52->1.6, cholesterol_mg: 28.5->21.3
UPDATE food_nutrition_overrides SET
  sodium_mg = 266.0,
  saturated_fat_g = 1.6,
  cholesterol_mg = 21.3
WHERE display_name = 'Panda Express Chicken Potsticker (3 pc)';

-- Panda Express Cream Cheese Rangoon (3 pc): sodium_mg: 427.8->264.7, saturated_fat_g: 2.49->7.4, cholesterol_mg: 23.3->51.5
UPDATE food_nutrition_overrides SET
  sodium_mg = 264.7,
  saturated_fat_g = 7.4,
  cholesterol_mg = 51.5
WHERE display_name = 'Panda Express Cream Cheese Rangoon (3 pc)';

-- Panda Express Chili Sauce: sodium_mg: 1500->1785.7
UPDATE food_nutrition_overrides SET
  sodium_mg = 1785.7
WHERE display_name = 'Panda Express Chili Sauce';

-- Panda Express Teriyaki Sauce: sodium_mg: 3200->745.1
UPDATE food_nutrition_overrides SET
  sodium_mg = 745.1
WHERE display_name = 'Panda Express Teriyaki Sauce';

-- Church's Original Chicken Breast: sodium_mg: 601->400.0, saturated_fat_g: 2.3->1.8, cholesterol_mg: 80.5->47.1
UPDATE food_nutrition_overrides SET
  sodium_mg = 400.0,
  saturated_fat_g = 1.8,
  cholesterol_mg = 47.1
WHERE display_name = 'Church''s Original Chicken Breast';

-- Church's Original Chicken Leg: sodium_mg: 617.8->500.0, saturated_fat_g: 3.5->2.5, cholesterol_mg: 88.9->75.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 500.0,
  saturated_fat_g = 2.5,
  cholesterol_mg = 75.0
WHERE display_name = 'Church''s Original Chicken Leg';

-- Church's Honey-Butter Biscuit: sodium_mg: 450->766.7, saturated_fat_g: 8->13.3, cholesterol_mg: 22.5->8.3
UPDATE food_nutrition_overrides SET
  sodium_mg = 766.7,
  saturated_fat_g = 13.3,
  cholesterol_mg = 8.3
WHERE display_name = 'Church''s Honey-Butter Biscuit';

-- Church's Spicy Chicken Breast: saturated_fat_g: 3.2->2.4, cholesterol_mg: 34.4->47.1
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 2.4,
  cholesterol_mg = 47.1
WHERE display_name = 'Church''s Spicy Chicken Breast';

-- Church's Mashed Potatoes & Gravy: sodium_mg: 203.2->511.8, cholesterol_mg: 5.4->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 511.8,
  cholesterol_mg = 0.0
WHERE display_name = 'Church''s Mashed Potatoes & Gravy';

-- Church's Fried Okra: sodium_mg: 422->770.8, saturated_fat_g: 4.8->2.6
UPDATE food_nutrition_overrides SET
  sodium_mg = 770.8,
  saturated_fat_g = 2.6
WHERE display_name = 'Church''s Fried Okra';

-- El Pollo Loco Fire-Grilled Chicken Breast: saturated_fat_g: 1.7->2.0, cholesterol_mg: 46.8->114.8
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 2.0,
  cholesterol_mg = 114.8
WHERE display_name = 'El Pollo Loco Fire-Grilled Chicken Breast';

-- El Pollo Loco Fire-Grilled Chicken Leg: sodium_mg: 473.4->283.3, saturated_fat_g: 2.14->1.7, cholesterol_mg: 45->116.7
UPDATE food_nutrition_overrides SET
  sodium_mg = 283.3,
  saturated_fat_g = 1.7,
  cholesterol_mg = 116.7
WHERE display_name = 'El Pollo Loco Fire-Grilled Chicken Leg';

-- El Pollo Loco Fire-Grilled Chicken Thigh: sodium_mg: 475->266.7, cholesterol_mg: 41.2->150.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 266.7,
  cholesterol_mg = 150.0
WHERE display_name = 'El Pollo Loco Fire-Grilled Chicken Thigh';

-- El Pollo Loco Chicken Taco Al Carbon: sodium_mg: 512->260.0, saturated_fat_g: 2.1->1.5
UPDATE food_nutrition_overrides SET
  sodium_mg = 260.0,
  saturated_fat_g = 1.5
WHERE display_name = 'El Pollo Loco Chicken Taco Al Carbon';

-- El Pollo Loco Black Beans: sodium_mg: 153->100.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 100.0
WHERE display_name = 'El Pollo Loco Black Beans';

-- El Pollo Loco Rice: sodium_mg: 396->228.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 228.0
WHERE display_name = 'El Pollo Loco Rice';

-- Panera Bread Broccoli Cheddar Soup (Bowl): cholesterol_mg: 19.4->15.7
UPDATE food_nutrition_overrides SET
  cholesterol_mg = 15.7
WHERE display_name = 'Panera Bread Broccoli Cheddar Soup (Bowl)';

-- Panera Bread Chicken Noodle Soup (Bowl): sodium_mg: 525.7->400.0, saturated_fat_g: 0.6->0.4, cholesterol_mg: 17.7->31.4
UPDATE food_nutrition_overrides SET
  sodium_mg = 400.0,
  saturated_fat_g = 0.4,
  cholesterol_mg = 31.4
WHERE display_name = 'Panera Bread Chicken Noodle Soup (Bowl)';

-- Panera Bread Creamy Tomato Soup (Bowl): sodium_mg: 508.6->240.0, saturated_fat_g: 2.6->3.1, cholesterol_mg: 12.6->17.1
UPDATE food_nutrition_overrides SET
  sodium_mg = 240.0,
  saturated_fat_g = 3.1,
  cholesterol_mg = 17.1
WHERE display_name = 'Panera Bread Creamy Tomato Soup (Bowl)';

-- Panera Bread Mac & Cheese (Large): sodium_mg: 420->273.7, cholesterol_mg: 26.1->21.1
UPDATE food_nutrition_overrides SET
  sodium_mg = 273.7,
  cholesterol_mg = 21.1
WHERE display_name = 'Panera Bread Mac & Cheese (Large)';

-- Panera Bread Broccoli Cheddar Soup (Cup): cholesterol_mg: 19.4->16.7
UPDATE food_nutrition_overrides SET
  cholesterol_mg = 16.7
WHERE display_name = 'Panera Bread Broccoli Cheddar Soup (Cup)';

-- Panera Bread Chicken Noodle Soup (Cup): sodium_mg: 525->404.2, saturated_fat_g: 0.58->0.4, cholesterol_mg: 17.5->31.2
UPDATE food_nutrition_overrides SET
  sodium_mg = 404.2,
  saturated_fat_g = 0.4,
  cholesterol_mg = 31.2
WHERE display_name = 'Panera Bread Chicken Noodle Soup (Cup)';

-- Panera Bread Creamy Tomato Soup (Cup): sodium_mg: 508.4->241.7, cholesterol_mg: 12.5->18.8
UPDATE food_nutrition_overrides SET
  sodium_mg = 241.7,
  cholesterol_mg = 18.8
WHERE display_name = 'Panera Bread Creamy Tomato Soup (Cup)';

-- Panera Bread Mac & Cheese (Small): sodium_mg: 420->273.9, cholesterol_mg: 26.1->21.7
UPDATE food_nutrition_overrides SET
  sodium_mg = 273.9,
  cholesterol_mg = 21.7
WHERE display_name = 'Panera Bread Mac & Cheese (Small)';

-- Long John Silver's Battered Alaskan Pollock: sodium_mg: 468.8->630.4, saturated_fat_g: 5.7->3.8, trans_fat_g: 0.18->0.5
UPDATE food_nutrition_overrides SET
  sodium_mg = 630.4,
  saturated_fat_g = 3.8,
  trans_fat_g = 0.5
WHERE display_name = 'Long John Silver''s Battered Alaskan Pollock';

-- Long John Silver's Battered Cod: sodium_mg: 378->655.6, cholesterol_mg: 81.8->50.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 655.6,
  cholesterol_mg = 50.0
WHERE display_name = 'Long John Silver''s Battered Cod';

-- Long John Silver's Chicken Tenders (1pc): saturated_fat_g: 6.83->3.3, cholesterol_mg: 100->55.6
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 3.3,
  cholesterol_mg = 55.6
WHERE display_name = 'Long John Silver''s Chicken Tenders (1pc)';

-- Long John Silver's Hushpuppy (1pc): sodium_mg: 420->760.0, cholesterol_mg: 21->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 760.0,
  cholesterol_mg = 0.0
WHERE display_name = 'Long John Silver''s Hushpuppy (1pc)';

-- Long John Silver's Cole Slaw: cholesterol_mg: 5->13.3
UPDATE food_nutrition_overrides SET
  cholesterol_mg = 13.3
WHERE display_name = 'Long John Silver''s Cole Slaw';

-- Long John Silver's Fries: sodium_mg: 362.5->500.0, saturated_fat_g: 2->1.7
UPDATE food_nutrition_overrides SET
  sodium_mg = 500.0,
  saturated_fat_g = 1.7
WHERE display_name = 'Long John Silver''s Fries';

-- Captain D's Batter Dipped Fish (1pc): sodium_mg: 361->695.1, saturated_fat_g: 4.03->9.8, trans_fat_g: 0->1.2, cholesterol_mg: 71.6->61.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 695.1,
  saturated_fat_g = 9.8,
  trans_fat_g = 1.2,
  cholesterol_mg = 61.0
WHERE display_name = 'Captain D''s Batter Dipped Fish (1pc)';

-- Captain D's Chicken Tenders (3pc): sodium_mg: 604.6->776.5, saturated_fat_g: 3.61->2.9, trans_fat_g: 0.19->0.3, cholesterol_mg: 82.3->50.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 776.5,
  saturated_fat_g = 2.9,
  trans_fat_g = 0.3,
  cholesterol_mg = 50.0
WHERE display_name = 'Captain D''s Chicken Tenders (3pc)';

-- Captain D's Grilled White Fish: saturated_fat_g: 0.13->0.3, cholesterol_mg: 80.9->44.1
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 0.3,
  cholesterol_mg = 44.1
WHERE display_name = 'Captain D''s Grilled White Fish';

-- Captain D's Grilled Salmon: cholesterol_mg: 77.3->58.8
UPDATE food_nutrition_overrides SET
  cholesterol_mg = 58.8
WHERE display_name = 'Captain D''s Grilled Salmon';

-- Captain D's French Fries: sodium_mg: 362.5->658.3, saturated_fat_g: 2->2.5
UPDATE food_nutrition_overrides SET
  sodium_mg = 658.3,
  saturated_fat_g = 2.5
WHERE display_name = 'Captain D''s French Fries';

-- Captain D's Hushpuppy (1pc): sodium_mg: 420->600.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 600.0
WHERE display_name = 'Captain D''s Hushpuppy (1pc)';

-- Captain D's Cole Slaw: saturated_fat_g: 2.33->2.0, cholesterol_mg: 4.7->6.7
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 2.0,
  cholesterol_mg = 6.7
WHERE display_name = 'Captain D''s Cole Slaw';

-- Captain D's Crab Cake: sodium_mg: 329->475.0, saturated_fat_g: 1.83->1.2
UPDATE food_nutrition_overrides SET
  sodium_mg = 475.0,
  saturated_fat_g = 1.2
WHERE display_name = 'Captain D''s Crab Cake';

-- Qdoba Grilled Chicken: sodium_mg: 459->230.1, saturated_fat_g: 0.76->0.9, cholesterol_mg: 115.4->92.9
UPDATE food_nutrition_overrides SET
  sodium_mg = 230.1,
  saturated_fat_g = 0.9,
  cholesterol_mg = 92.9
WHERE display_name = 'Qdoba Grilled Chicken';

-- Qdoba Grilled Steak: sodium_mg: 310->168.1, cholesterol_mg: 110->66.4
UPDATE food_nutrition_overrides SET
  sodium_mg = 168.1,
  cholesterol_mg = 66.4
WHERE display_name = 'Qdoba Grilled Steak';

-- Qdoba Flour Tortilla: sodium_mg: 426->690.0, cholesterol_mg: 25.5->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 690.0,
  cholesterol_mg = 0.0
WHERE display_name = 'Qdoba Flour Tortilla';

-- Qdoba Three Cheese Queso: sodium_mg: 505->929.8, saturated_fat_g: 5.25->7.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 929.8,
  saturated_fat_g = 7.0
WHERE display_name = 'Qdoba Three Cheese Queso';

-- Qdoba Mexican Rice: sodium_mg: 395->212.4, saturated_fat_g: 0.8->0.4, cholesterol_mg: 18.8->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 212.4,
  saturated_fat_g = 0.4,
  cholesterol_mg = 0.0
WHERE display_name = 'Qdoba Mexican Rice';

-- Qdoba Guacamole: sodium_mg: 488.5->263.2, saturated_fat_g: 5.25->0.9, cholesterol_mg: 23.4->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 263.2,
  saturated_fat_g = 0.9,
  cholesterol_mg = 0.0
WHERE display_name = 'Qdoba Guacamole';

-- Sweetgreen Harvest Bowl: sodium_mg: 440.2->313.3, saturated_fat_g: 3.1->1.9, cholesterol_mg: 30.3->19.6
UPDATE food_nutrition_overrides SET
  sodium_mg = 313.3,
  saturated_fat_g = 1.9,
  cholesterol_mg = 19.6
WHERE display_name = 'Sweetgreen Harvest Bowl';

-- Sweetgreen Blackened Chicken: saturated_fat_g: 1.92->1.0, cholesterol_mg: 40.5->65.0
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 1.0,
  cholesterol_mg = 65.0
WHERE display_name = 'Sweetgreen Blackened Chicken';

-- Sweetgreen Kale Caesar Salad: sodium_mg: 275->418.2, saturated_fat_g: 1.88->2.8
UPDATE food_nutrition_overrides SET
  sodium_mg = 418.2,
  saturated_fat_g = 2.8
WHERE display_name = 'Sweetgreen Kale Caesar Salad';

-- Sweetgreen Crispy Rice Bowl: sodium_mg: 457->289.5, saturated_fat_g: 1.67->1.3, cholesterol_mg: 34.8->13.2
UPDATE food_nutrition_overrides SET
  sodium_mg = 289.5,
  saturated_fat_g = 1.3,
  cholesterol_mg = 13.2
WHERE display_name = 'Sweetgreen Crispy Rice Bowl';

-- Sweetgreen BBQ Chicken Salad: saturated_fat_g: 2.3->1.1, cholesterol_mg: 22.9->18.9
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 1.1,
  cholesterol_mg = 18.9
WHERE display_name = 'Sweetgreen BBQ Chicken Salad';

-- Jollibee Chickenjoy (1 pc): saturated_fat_g: 4.48->2.7, cholesterol_mg: 30->16.7
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 2.7,
  cholesterol_mg = 16.7
WHERE display_name = 'Jollibee Chickenjoy (1 pc)';

-- Jollibee Chickenjoy Breast (1 pc): sodium_mg: 507.1->314.3, saturated_fat_g: 3.88->2.9
UPDATE food_nutrition_overrides SET
  sodium_mg = 314.3,
  saturated_fat_g = 2.9
WHERE display_name = 'Jollibee Chickenjoy Breast (1 pc)';

-- Jollibee Jolly Spaghetti: cholesterol_mg: 24.9->17.1
UPDATE food_nutrition_overrides SET
  cholesterol_mg = 17.1
WHERE display_name = 'Jollibee Jolly Spaghetti';

-- Jollibee Jolly Crispy Fries (Regular): saturated_fat_g: 2.22->3.5
UPDATE food_nutrition_overrides SET
  saturated_fat_g = 3.5
WHERE display_name = 'Jollibee Jolly Crispy Fries (Regular)';

-- Jollibee Steamed Rice: sodium_mg: 390->0.0, cholesterol_mg: 18.8->0.0
UPDATE food_nutrition_overrides SET
  sodium_mg = 0.0,
  cholesterol_mg = 0.0
WHERE display_name = 'Jollibee Steamed Rice';

COMMIT;
