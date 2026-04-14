# Food Nutrition Overrides Research Task File

> **Cleaned 2026-04-13:** 1,199 entries removed because they now exist in the live `food_nutrition_overrides` table. Backup at `food_nutrition_overrides_research.backup-2026-04-13.md`. Remaining: 4,600 TODO items.

## How to Resume This Task

> **Instructions for Claude**: Read this file, filter items where `Status` = `TODO`, then for each batch:
> 1. Web search the food item (manufacturer website, nutritionix.com, myfitnesspal.com, fatsecret.com, openfoodfacts.org)
> 2. Collect ALL nutrition data per 100g (macros + micronutrients)
> 3. Generate SQL INSERT statements for `food_nutrition_overrides` using the schema below
> 4. Update this file: change `TODO` to `DONE` and add `date_completed`
> 5. Work in batches of ~50-100 items per session to keep quality high
> 6. All duplicates have been pre-removed - every item here is confirmed NOT in the database

## Target Table Schema

All values are **per 100g** unless noted. Generate SQL INSERTs with these columns:

```sql
INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g, default_count,
  source, variant_names, notes, restaurant_name, food_category,
  sodium_mg, cholesterol_mg, saturated_fat_g, trans_fat_g,
  potassium_mg, calcium_mg, iron_mg, vitamin_a_ug, vitamin_c_mg,
  vitamin_d_iu, magnesium_mg, zinc_mg, phosphorus_mg, selenium_ug, omega3_g,
  region, country_name, is_active
) VALUES (...) ON CONFLICT (food_name_normalized) DO NOTHING;
```

## Sources to Check (priority order)
1. Manufacturer/brand official website (most accurate)
2. openfoodfacts.org (barcode scanned data)
3. nutritionix.com
4. myfitnesspal.com / fatsecret.com
5. Product label photos (Google Images)

---

## Section 1: Protein Cereals & Granola (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1 | Mr. Iron 30% Protein Cereals Savory Strawberries | Mr. Iron | EU | protein_cereal | H | TODO | 2026-04-07 | | Vegan gluten-free, from product image |
| 2 | Mr. Iron 30% Protein Cereals Chocolate | Mr. Iron | EU | protein_cereal | H | TODO | 2026-04-07 | | |
| 3 | Mr. Iron 30% Protein Cereals Cocoa | Mr. Iron | EU | protein_cereal | H | TODO | 2026-04-07 | | |
| 4 | Mr. Iron 30% Protein Cereals Cinnamon | Mr. Iron | EU | protein_cereal | H | TODO | 2026-04-07 | | |
| 5 | The Protein Works Protein Granola | The Protein Works | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 6 | The Protein Works Protein Porridge | The Protein Works | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 7 | MyProtein Protein Granola Chocolate Caramel | MyProtein | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 8 | MyProtein Protein Granola Peanut Butter | MyProtein | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 9 | Prozis Protein Cereal Chocolate | Prozis | PT | protein_cereal | H | TODO | 2026-04-07 | | |
| 10 | Prozis Protein Cereal Cinnamon | Prozis | PT | protein_cereal | H | TODO | 2026-04-07 | | |
| 11 | Surreal High Protein Cereal Cocoa | Surreal | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 12 | Surreal High Protein Cereal Peanut Butter | Surreal | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 13 | Surreal High Protein Cereal Frosted | Surreal | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 14 | Surreal High Protein Cereal Cinnamon | Surreal | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 15 | Catalina Crunch Keto Cereal Maple Waffle | Catalina Crunch | US | protein_cereal | H | TODO | 2026-04-07 | | |
| 16 | Catalina Crunch Keto Cereal Fruity | Catalina Crunch | US | protein_cereal | H | TODO | 2026-04-07 | | |
| 17 | Magic Spoon Protein Cereal Peanut Butter | Magic Spoon | US | protein_cereal | H | TODO | 2026-04-07 | | |
| 18 | Grandpa Crumble Protein Muesli | Grandpa Crumble | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 19 | BioTechUSA Protein Cereal | BioTechUSA | HU | protein_cereal | H | TODO | 2026-04-07 | | |
| 20 | GOT7 High Protein Cereal Cinnamon | GOT7 Nutrition | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 21 | GOT7 High Protein Cereal Chocolate | GOT7 Nutrition | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 22 | Weetabix Protein Original | Weetabix | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 23 | Weetabix Protein Chocolate | Weetabix | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 24 | Jordans Protein Granola | Jordans | GB | protein_cereal | M | TODO | 2026-04-07 | | |
| 25 | Lizi's High Protein Granola | Lizi's | GB | protein_cereal | M | TODO | 2026-04-07 | | |
| 26 | Quaker Protein Instant Oatmeal Banana Nut | Quaker | US | protein_cereal | M | TODO | 2026-04-07 | | |
| 27 | AMFIT Protein Granola Amazon Brand | AMFIT | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 28 | YFood Protein Crunchy Muesli | YFood | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 29 | Alpro High Protein Granola | Alpro | BE | protein_cereal | M | TODO | 2026-04-07 | | |
| 30 | Protein Mueslii Crunchy Vanilla | Protein Mueslii | NL | protein_cereal | M | TODO | 2026-04-07 | | |
| 31 | IronMaxx Protein Musli | IronMaxx | DE | protein_cereal | M | TODO | 2026-04-07 | | |

## Section 2: Protein Bars - International & Niche (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 32 | Grenade Carb Killa Oreo White | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 33 | Grenade Carb Killa Caramel Chaos | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 34 | Grenade Carb Killa Birthday Cake | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 35 | Grenade Carb Killa Fudged Up | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 36 | PhD Smart Bar Chocolate Brownie | PhD Nutrition | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 37 | ESN Designer Bar Crunchy | ESN | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 38 | ESN Designer Bar Caramel Brownie | ESN | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 39 | BioTechUSA Zero Bar Chocolate Chip Cookies | BioTechUSA | HU | protein_bar | M | TODO | 2026-04-07 | | |
| 40 | BioTechUSA Zero Bar Double Chocolate | BioTechUSA | HU | protein_bar | M | TODO | 2026-04-07 | | |
| 41 | PowerBar Protein Plus 30% Chocolate | PowerBar | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 42 | Aussie Bodies ProteinFX Lo Carb Crisp | Aussie Bodies | AU | protein_bar | M | TODO | 2026-04-07 | | |
| 43 | Nugo Slim Bar Espresso | NuGo | US | protein_bar | L | TODO | 2026-04-07 | | |

## Section 3: Protein Drinks & RTD Shakes (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 44 | NOCCO BCAA Caribbean | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 45 | NOCCO BCAA Juicy Breeze | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 46 | NOCCO BCAA Apple | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 47 | NOCCO BCAA Limon Del Sol | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 48 | NOCCO BCAA Miami Strawberry | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 49 | YFood Ready to Drink Smooth Vanilla | YFood | DE | protein_drink | H | TODO | 2026-04-07 | | |
| 50 | YFood Ready to Drink Fresh Berry | YFood | DE | protein_drink | H | TODO | 2026-04-07 | | |
| 51 | YFood Ready to Drink Classic Choco | YFood | DE | protein_drink | H | TODO | 2026-04-07 | | |
| 52 | Jimmy Joy Plenny Shake Vanilla | Jimmy Joy | NL | protein_drink | M | TODO | 2026-04-07 | | |
| 53 | Jimmy Joy Plenny Shake Chocolate | Jimmy Joy | NL | protein_drink | M | TODO | 2026-04-07 | | |
| 54 | Huel Ready-to-Drink Berry | Huel | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 55 | Huel Ready-to-Drink Banana | Huel | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 56 | Saturo RTD Meal Shake Original | Saturo | AT | protein_drink | M | TODO | 2026-04-07 | | |
| 57 | Saturo RTD Meal Shake Chocolate | Saturo | AT | protein_drink | M | TODO | 2026-04-07 | | |
| 58 | Mana RTD Meal Shake Origin | Mana | CZ | protein_drink | M | TODO | 2026-04-07 | | |
| 59 | Feed Smart Meal Bar Chocolate | Feed | FR | protein_drink | M | TODO | 2026-04-07 | | |
| 60 | Feed Smart Meal Shake Vanilla | Feed | FR | protein_drink | M | TODO | 2026-04-07 | | |
| 61 | Soylent Ready to Drink Original | Soylent | US | protein_drink | M | TODO | 2026-04-07 | | |
| 62 | Soylent Ready to Drink Cafe Mocha | Soylent | US | protein_drink | M | TODO | 2026-04-07 | | |
| 63 | Ka'Chava All-in-One Meal Shake Chocolate | Ka'Chava | US | protein_drink | M | TODO | 2026-04-07 | | |
| 64 | Protein2o Protein Infused Water Mixed Berry | Protein2o | US | protein_drink | M | TODO | 2026-04-07 | | |
| 65 | MyProtein Clear Whey Isolate Peach Tea | MyProtein | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 66 | MyProtein Clear Whey Isolate Lemonade | MyProtein | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 67 | Bulk Powders Complete Protein Shake Strawberry | Bulk | GB | protein_drink | M | TODO | 2026-04-07 | | |
| 68 | Amway Nutrilite Protein Drink Mix | Nutrilite | US | protein_drink | M | TODO | 2026-04-07 | | |
| 69 | Oatly Protein Oat Drink | Oatly | SE | protein_drink | M | TODO | 2026-04-07 | | |

## Section 4: Protein Snacks & Chips (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 70 | Shrewd Food Protein Puffs Baked Cheddar | Shrewd Food | US | protein_snack | H | TODO | 2026-04-07 | | |
| 71 | Shrewd Food Protein Puffs Sriracha | Shrewd Food | US | protein_snack | M | TODO | 2026-04-07 | | |
| 72 | Legendary Foods Protein Pastry Strawberry | Legendary Foods | US | protein_snack | M | TODO | 2026-04-07 | | |
| 73 | The Protein Ball Co Peanut Butter | The Protein Ball Co | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 74 | The Protein Ball Co Lemon Pistachio | The Protein Ball Co | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 75 | Graze Protein Bites Cocoa Vanilla | Graze | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 76 | Graze Protein Oat Bites Honey | Graze | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 77 | Biltong Chief Original South African Biltong | Biltong Chief | ZA | protein_snack | M | TODO | 2026-04-07 | | |
| 78 | Brooklyn Biltong Original | Brooklyn Biltong | US | protein_snack | M | TODO | 2026-04-07 | | |
| 79 | The New Primal Classic Beef Stick | The New Primal | US | protein_snack | M | TODO | 2026-04-07 | | |
| 80 | Peperami Protein Bites | Peperami | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 81 | Protein Puck Original | Protein Puck | US | protein_snack | L | TODO | 2026-04-07 | | |
| 82 | BioTechUSA Protein Chips Salt | BioTechUSA | HU | protein_snack | M | TODO | 2026-04-07 | | |
| 83 | BioTechUSA Protein Chips Cheese | BioTechUSA | HU | protein_snack | M | TODO | 2026-04-07 | | |
| 84 | MyProtein Protein Brownie Chocolate | MyProtein | GB | protein_snack | H | TODO | 2026-04-07 | | |
| 85 | MyProtein Protein Wafer Chocolate Hazelnut | MyProtein | GB | protein_snack | H | TODO | 2026-04-07 | | |
| 86 | Prozis Protein Wafer Chocolate | Prozis | PT | protein_snack | M | TODO | 2026-04-07 | | |
| 87 | IronMaxx Protein Chips Paprika | IronMaxx | DE | protein_snack | M | TODO | 2026-04-07 | | |
| 88 | High Key Protein Cereal Mini Cookies Chocolate | HighKey | US | protein_snack | M | TODO | 2026-04-07 | | |
| 89 | Flapjacked Mighty Muffin Double Chocolate | Flapjacked | US | protein_snack | M | TODO | 2026-04-07 | | |

## Section 5: International Energy Drinks (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 90 | Celsius Sparkling Orange | Celsius | SE | energy_drink | H | TODO | 2026-04-07 | | |
| 91 | Celsius Sparkling Peach Vibe | Celsius | SE | energy_drink | H | TODO | 2026-04-07 | | |
| 92 | Celsius Essentials Sparkling Cherry Limeade | Celsius | SE | energy_drink | M | TODO | 2026-04-07 | | |
| 93 | Celsius On-the-Go Powder Kiwi Guava | Celsius | SE | energy_drink | M | TODO | 2026-04-07 | | |
| 94 | 3D Energy Drink Chrome | 3D Energy | US | energy_drink | L | TODO | 2026-04-07 | | |
| 95 | Hell Energy Drink Classic | Hell | HU | energy_drink | M | TODO | 2026-04-07 | | |
| 96 | Hell Energy Drink Apple | Hell | HU | energy_drink | M | TODO | 2026-04-07 | | |
| 97 | Predator Energy Drink Gold Strike | Predator | NL | energy_drink | L | TODO | 2026-04-07 | | |
| 98 | Carabao Energy Drink Original | Carabao | TH | energy_drink | M | TODO | 2026-04-07 | | |
| 99 | M-150 Energy Drink | M-150 | TH | energy_drink | M | TODO | 2026-04-07 | | |
| 100 | Lipovitan-D Energy Drink | Lipovitan | JP | energy_drink | M | TODO | 2026-04-07 | | |
| 101 | Oronamin C Drink | Otsuka | JP | energy_drink | M | TODO | 2026-04-07 | | |
| 102 | Real Gold Energy Drink | Coca-Cola Japan | JP | energy_drink | L | TODO | 2026-04-07 | | |
| 103 | Aquarius Sports Drink Japan | Coca-Cola Japan | JP | energy_drink | M | TODO | 2026-04-07 | | |
| 104 | Sting Energy Drink Gold Rush | Sting | IN | energy_drink | H | TODO | 2026-04-07 | | |
| 105 | Sting Energy Drink Berry Blast | Sting | IN | energy_drink | H | TODO | 2026-04-07 | | |
| 106 | Tzinga Energy Drink Mango | Tzinga | IN | energy_drink | M | TODO | 2026-04-07 | | |
| 107 | Fast Up Charge Energy Drink | Fast&Up | IN | energy_drink | M | TODO | 2026-04-07 | | |
| 108 | Bournvita Protein Shake RTD | Cadbury | IN | energy_drink | H | TODO | 2026-04-07 | | |

## Section 6: International Protein Powders & Supplements (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 109 | Optimum Nutrition Gold Standard Plant Chocolate Fudge | Optimum Nutrition | US | protein_powder | M | TODO | 2026-04-07 | | per scoop |
| 110 | ESN Designer Whey Vanilla | ESN | DE | protein_powder | M | TODO | 2026-04-07 | | German top seller |
| 111 | ESN Designer Whey Chocolate | ESN | DE | protein_powder | M | TODO | 2026-04-07 | | |
| 112 | Prozis Whey Protein Concentrate Chocolate | Prozis | PT | protein_powder | M | TODO | 2026-04-07 | | |
| 113 | BioTechUSA 100% Pure Whey Biscuit | BioTechUSA | HU | protein_powder | M | TODO | 2026-04-07 | | |
| 114 | Olimp Whey Protein Complex Chocolate | Olimp | PL | protein_powder | M | TODO | 2026-04-07 | | |
| 115 | Reflex Nutrition Instant Whey Chocolate | Reflex | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 116 | Applied Nutrition ISO-XP Chocolate | Applied Nutrition | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 117 | MuscleBlaze Biozyme Whey Protein Rich Chocolate | MuscleBlaze | IN | protein_powder | H | TODO | 2026-04-07 | | India bestseller |
| 118 | AS-IT-IS Whey Protein Unflavored | AS-IT-IS | IN | protein_powder | M | TODO | 2026-04-07 | | |
| 119 | GNC Pro Performance 100% Whey Chocolate | GNC | US | protein_powder | M | TODO | 2026-04-07 | | |
| 120 | Muscle Feast Grass Fed Whey Chocolate | Muscle Feast | US | protein_powder | L | TODO | 2026-04-07 | | |
| 121 | PEScience Select Protein Chocolate Peanut Butter | PEScience | US | protein_powder | L | TODO | 2026-04-07 | | |
| 122 | Mutant Whey Protein Cookies & Cream | Mutant | CA | protein_powder | M | TODO | 2026-04-07 | | |
| 123 | Allmax IsoFlex Pure Whey Chocolate | Allmax | CA | protein_powder | M | TODO | 2026-04-07 | | |

## Section 7: International Yogurt & Dairy (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 124 | Skyr Icelandic Provisions Vanilla | Icelandic Provisions | IS | dairy | H | TODO | 2026-04-07 | | |
| 125 | Skyr Icelandic Provisions Blueberry | Icelandic Provisions | IS | dairy | M | TODO | 2026-04-07 | | |
| 126 | Arla Protein Yogurt Strawberry | Arla | DK | dairy | H | TODO | 2026-04-07 | | |
| 127 | Arla Protein Yogurt Blueberry | Arla | DK | dairy | M | TODO | 2026-04-07 | | |
| 128 | Arla Protein Pudding Chocolate | Arla | DK | dairy | H | TODO | 2026-04-07 | | |
| 129 | Arla Protein Milk Drink Chocolate | Arla | DK | dairy | M | TODO | 2026-04-07 | | |
| 130 | Muller Light Yogurt Strawberry | Muller | DE | dairy | M | TODO | 2026-04-07 | | |
| 131 | Muller Light Yogurt Vanilla | Muller | DE | dairy | M | TODO | 2026-04-07 | | |
| 132 | Epigamia Greek Yogurt Strawberry | Epigamia | IN | dairy | H | TODO | 2026-04-07 | | |
| 133 | Epigamia Greek Yogurt Natural | Epigamia | IN | dairy | H | TODO | 2026-04-07 | | |
| 134 | Epigamia Protein Yogurt Mango | Epigamia | IN | dairy | H | TODO | 2026-04-07 | | |
| 135 | Danone Oikos Pro High Protein Vanilla | Danone | FR | dairy | M | TODO | 2026-04-07 | | |
| 136 | YoPRO High Protein Yogurt Vanilla | YoPRO | AU | dairy | H | TODO | 2026-04-07 | | |
| 137 | YoPRO High Protein Yogurt Strawberry | YoPRO | AU | dairy | M | TODO | 2026-04-07 | | |

## Section 8: International Instant Noodles & Ramen (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 138 | Indomie Soto Mie | Indomie | ID | instant_noodle | M | TODO | 2026-04-07 | | |
| 139 | Samyang Buldak Hot Chicken 2x Spicy | Samyang | KR | instant_noodle | H | TODO | 2026-04-07 | | |
| 140 | Samyang Buldak Hot Chicken Original | Samyang | KR | instant_noodle | H | TODO | 2026-04-07 | | |
| 141 | Samyang Buldak Hot Chicken Carbonara | Samyang | KR | instant_noodle | H | TODO | 2026-04-07 | | |
| 142 | Samyang Buldak Hot Chicken Cheese | Samyang | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 143 | Nongshim Chapagetti | Nongshim | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 144 | Nongshim Neoguri Seafood | Nongshim | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 145 | Ottogi Jin Ramen Spicy | Ottogi | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 146 | Paldo Bibimmyeon | Paldo | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 147 | Maruchan Instant Lunch Chicken | Maruchan | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 148 | Mama Tom Yum Shrimp Instant Noodles | Mama | TH | instant_noodle | H | TODO | 2026-04-07 | | |
| 149 | Mama Creamy Tom Yum | Mama | TH | instant_noodle | M | TODO | 2026-04-07 | | |
| 150 | Yum Yum Tom Yam Kung | Yum Yum | TH | instant_noodle | M | TODO | 2026-04-07 | | |
| 151 | Wai Wai Instant Noodles Chicken | Wai Wai | TH | instant_noodle | M | TODO | 2026-04-07 | | Popular in India/Nepal |
| 152 | Maggi 2-Minute Noodles Masala | Maggi | IN | instant_noodle | H | TODO | 2026-04-07 | | India staple |
| 153 | Maggi Hot Heads Peri Peri | Maggi | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 154 | Yippee Noodles Magic Masala | Yippee | IN | instant_noodle | H | TODO | 2026-04-07 | | |
| 155 | Top Ramen Curry Noodles | Top Ramen | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 156 | Knorr Soupy Noodles Mast Masala | Knorr | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 157 | Prima Taste Laksa La Mian | Prima Taste | SG | instant_noodle | M | TODO | 2026-04-07 | | |

## Section 9: International Chocolate & Confectionery (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 158 | Cadbury 5 Star | Cadbury | IN | chocolate | H | TODO | 2026-04-07 | | |
| 159 | Cadbury Perk | Cadbury | IN | chocolate | M | TODO | 2026-04-07 | | |
| 160 | Kit Kat Matcha (Japan) | Nestle | JP | chocolate | H | TODO | 2026-04-07 | | Japan exclusive |
| 161 | Kit Kat Strawberry Cheesecake (Japan) | Nestle | JP | chocolate | M | TODO | 2026-04-07 | | Japan exclusive |
| 162 | Meiji Chocolate Milk Bar | Meiji | JP | chocolate | M | TODO | 2026-04-07 | | |
| 163 | Lotte Ghana Chocolate Milk | Lotte | KR | chocolate | M | TODO | 2026-04-07 | | |

## Section 10: International Chips & Savory Snacks (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 164 | Lay's American Style Cream & Onion (India) | Lay's | IN | snack | M | TODO | 2026-04-07 | | |
| 165 | Kurkure Chilli Chatka | Kurkure | IN | snack | M | TODO | 2026-04-07 | | |
| 166 | Haldiram's Sev Bhujia | Haldiram's | IN | snack | M | TODO | 2026-04-07 | | |
| 167 | Balaji Wafers Masala | Balaji | IN | snack | M | TODO | 2026-04-07 | | Gujarat brand |
| 168 | Calbee Shrimp Chips Original | Calbee | JP | snack | H | TODO | 2026-04-07 | | |
| 169 | Calbee Jagariko Salad | Calbee | JP | snack | M | TODO | 2026-04-07 | | |
| 170 | Calbee Kappa Ebisen | Calbee | JP | snack | M | TODO | 2026-04-07 | | |
| 171 | Koikeya Karamucho Hot Chili | Koikeya | JP | snack | M | TODO | 2026-04-07 | | |
| 172 | Nongshim Shrimp Crackers | Nongshim | KR | snack | M | TODO | 2026-04-07 | | |
| 173 | Orion Turtle Chips Corn Soup | Orion | KR | snack | M | TODO | 2026-04-07 | | |
| 174 | Shrimp Chips Nongshim Honey | Nongshim | KR | snack | M | TODO | 2026-04-07 | | |
| 175 | Oishi Prawn Crackers | Oishi | PH | snack | M | TODO | 2026-04-07 | | |
| 176 | Jack n Jill Piattos Cheese | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 177 | Mamee Monster Noodle Snack | Mamee | MY | snack | M | TODO | 2026-04-07 | | |
| 178 | Sabritas Ruffles Queso | Sabritas | MX | snack | M | TODO | 2026-04-07 | | |
| 179 | Platanitos Plantain Chips | Various | MX | snack | M | TODO | 2026-04-07 | | |
| 180 | Pipers Crisps Anglesey Sea Salt | Pipers | GB | snack | M | TODO | 2026-04-07 | | Premium UK crisp |
| 181 | Tyrrell's Lightly Sea Salted | Tyrrell's | GB | snack | M | TODO | 2026-04-07 | | |
| 182 | Walkers Cheese & Onion | Walkers | GB | snack | H | TODO | 2026-04-07 | | UK staple |
| 183 | Walkers Prawn Cocktail | Walkers | GB | snack | M | TODO | 2026-04-07 | | |
| 184 | Pom-Bear Original | Pom-Bear | DE | snack | M | TODO | 2026-04-07 | | |
| 185 | Chio Tortillas Wild Paprika | Chio | DE | snack | M | TODO | 2026-04-07 | | |
| 186 | Bissli BBQ | Osem | IL | snack | M | TODO | 2026-04-07 | | |
| 187 | Smith's Original Crinkle Cut | Smith's | AU | snack | M | TODO | 2026-04-07 | | |
| 188 | Red Rock Deli Honey Soy Chicken | Red Rock Deli | AU | snack | M | TODO | 2026-04-07 | | |
| 189 | Bluebird Ready Salted | Bluebird | NZ | snack | M | TODO | 2026-04-07 | | |
| 190 | Simba All Gold Tomato Sauce | Simba | ZA | snack | M | TODO | 2026-04-07 | | |
| 191 | Nik Naks Original Nice | Simba | ZA | snack | M | TODO | 2026-04-07 | | SA snack |

## Section 11: International Beverages - Non-energy (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 192 | Yakult Light | Yakult | JP | beverage | M | TODO | 2026-04-07 | | |
| 193 | Calpis Water (Calpico) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | |
| 194 | Ramune Soda Original | Various | JP | beverage | M | TODO | 2026-04-07 | | |
| 195 | Vita Soy Original | Vita Soy | HK | beverage | M | TODO | 2026-04-07 | | |
| 196 | Vita Lemon Tea | Vita | HK | beverage | M | TODO | 2026-04-07 | | |
| 197 | Mogu Mogu Lychee | Mogu Mogu | TH | beverage | M | TODO | 2026-04-07 | | |
| 198 | Mogu Mogu Mango | Mogu Mogu | TH | beverage | M | TODO | 2026-04-07 | | |
| 199 | Cha Yen Thai Milk Tea (bottled) | Various | TH | beverage | M | TODO | 2026-04-07 | | |
| 200 | Frooti Mango Drink | Parle Agro | IN | beverage | H | TODO | 2026-04-07 | | India iconic |
| 201 | Maaza Mango Drink | Coca-Cola India | IN | beverage | H | TODO | 2026-04-07 | | |
| 202 | Appy Fizz | Parle Agro | IN | beverage | M | TODO | 2026-04-07 | | |
| 203 | Thums Up (Indian Cola) | Coca-Cola India | IN | beverage | M | TODO | 2026-04-07 | | |
| 204 | Limca (Indian Lemon Soda) | Coca-Cola India | IN | beverage | M | TODO | 2026-04-07 | | |
| 205 | Tropicana Mosambi Juice | Tropicana | IN | beverage | M | TODO | 2026-04-07 | | |
| 206 | Real Fruit Power Mixed Fruit | Dabur | IN | beverage | M | TODO | 2026-04-07 | | |
| 207 | Lassi Amul Mango | Amul | IN | beverage | H | TODO | 2026-04-07 | | |
| 208 | Lassi Amul Kesar | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 209 | Buttermilk Amul Masala Chaas | Amul | IN | beverage | H | TODO | 2026-04-07 | | |
| 210 | Fanta Jasmine Peach (Japan) | Coca-Cola Japan | JP | beverage | L | TODO | 2026-04-07 | | Japan exclusive |
| 211 | Soju Chamisul Original | Hite Jinro | KR | beverage | M | TODO | 2026-04-07 | | |
| 212 | Teh Botol Jasmine Tea | Sosro | ID | beverage | M | TODO | 2026-04-07 | | Indonesia staple |
| 213 | Bandung Rose Milk | Various | SG | beverage | M | TODO | 2026-04-07 | | |

## Section 12: International Biscuits & Cookies (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 214 | McVitie's Digestive Original | McVitie's | GB | biscuit | H | TODO | 2026-04-07 | | |
| 215 | McVitie's Digestive Chocolate | McVitie's | GB | biscuit | M | TODO | 2026-04-07 | | |
| 216 | McVitie's Hobnobs Original | McVitie's | GB | biscuit | M | TODO | 2026-04-07 | | |
| 217 | McVitie's Jaffa Cakes | McVitie's | GB | biscuit | H | TODO | 2026-04-07 | | |
| 218 | Britannia Good Day Butter | Britannia | IN | biscuit | H | TODO | 2026-04-07 | | |
| 219 | Britannia Marie Gold | Britannia | IN | biscuit | H | TODO | 2026-04-07 | | |
| 220 | Britannia Bourbon Chocolate Cream | Britannia | IN | biscuit | M | TODO | 2026-04-07 | | |
| 221 | Sunfeast Mom's Magic Cashew & Almond | ITC | IN | biscuit | M | TODO | 2026-04-07 | | |
| 222 | Unibic Choco Chip Cookies | Unibic | IN | biscuit | M | TODO | 2026-04-07 | | |
| 223 | Digestive Biscuit Britannia | Britannia | IN | biscuit | M | TODO | 2026-04-07 | | |
| 224 | Koala March Chocolate | Lotte | JP | biscuit | M | TODO | 2026-04-07 | | |
| 225 | Bourbon Alfort Chocolate | Bourbon | JP | biscuit | M | TODO | 2026-04-07 | | |
| 226 | Country Ma'am Vanilla & Cocoa | Fujiya | JP | biscuit | M | TODO | 2026-04-07 | | |
| 227 | Stroopwafel Daelmans Caramel | Daelmans | NL | biscuit | H | TODO | 2026-04-07 | | Dutch icon |
| 228 | Leibniz Butter Biscuit | Bahlsen | DE | biscuit | M | TODO | 2026-04-07 | | |
| 229 | Bahlsen Choco Leibniz | Bahlsen | DE | biscuit | M | TODO | 2026-04-07 | | |
| 230 | LU Petit Beurre | LU | FR | biscuit | M | TODO | 2026-04-07 | | |
| 231 | Belvita Breakfast Biscuit Honey & Nut | Belvita | FR | biscuit | M | TODO | 2026-04-07 | | |

## Section 13: International Spreads & Condiments (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 232 | Sundrop Peanut Butter Crunchy | Sundrop | IN | spread | H | TODO | 2026-04-07 | | |
| 233 | MyFitness Peanut Butter Chocolate | MyFitness | IN | spread | H | TODO | 2026-04-07 | | India fitness brand |
| 234 | MyFitness Peanut Butter Crunchy Natural | MyFitness | IN | spread | H | TODO | 2026-04-07 | | |
| 235 | The Whole Truth Peanut Butter Crunchy | The Whole Truth | IN | spread | M | TODO | 2026-04-07 | | |
| 236 | Pintola Peanut Butter Classic Crunchy | Pintola | IN | spread | M | TODO | 2026-04-07 | | |
| 237 | Nutralite Mayo Eggless | Nutralite | IN | spread | M | TODO | 2026-04-07 | | |
| 238 | Tahini Al Arz | Al Arz | LB | spread | M | TODO | 2026-04-07 | | |
| 239 | Halva Achva Vanilla | Achva | IL | spread | M | TODO | 2026-04-07 | | |
| 240 | Dulce de Leche Havanna | Havanna | AR | spread | M | TODO | 2026-04-07 | | |
| 241 | Nocciolata Organic Hazelnut Spread | Rigoni di Asiago | IT | spread | M | TODO | 2026-04-07 | | |
| 242 | Bonne Maman Strawberry Jam | Bonne Maman | FR | spread | M | TODO | 2026-04-07 | | |
| 243 | Kimchi Jongga Mat | Jongga | KR | condiment | H | TODO | 2026-04-07 | | per 100g |
| 244 | Japanese Kewpie Mayonnaise | Kewpie | JP | condiment | H | TODO | 2026-04-07 | | |
| 245 | Bulldog Tonkatsu Sauce | Bulldog | JP | condiment | M | TODO | 2026-04-07 | | |
| 246 | Nando's Peri-Peri Sauce Hot | Nando's | ZA | condiment | M | TODO | 2026-04-07 | | |
| 247 | Encona West Indian Hot Pepper Sauce | Encona | GB | condiment | M | TODO | 2026-04-07 | | |
| 248 | Lao Gan Ma Chili Crisp | Lao Gan Ma | CN | condiment | H | TODO | 2026-04-07 | | Viral worldwide |
| 249 | Maggi Hot & Sweet Tomato Chilli Sauce | Maggi | IN | condiment | H | TODO | 2026-04-07 | | India staple |
| 250 | Kissan Mixed Fruit Jam | Kissan | IN | spread | M | TODO | 2026-04-07 | | |

## Section 14: International Frozen & Ready Meals (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 251 | Birds Eye Chicken Chargrilled | Birds Eye | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 252 | Quorn Meat Free Chicken Pieces | Quorn | GB | frozen_meal | H | TODO | 2026-04-07 | | |
| 253 | Quorn Meat Free Mince | Quorn | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 254 | Linda McCartney Vegetarian Sausages | Linda McCartney | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 255 | McCain Oven Chips Straight Cut | McCain | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 256 | Iglo Fish Sticks (Fischstabchen) | Iglo | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 257 | Picard Gratin Dauphinois | Picard | FR | frozen_meal | M | TODO | 2026-04-07 | | |
| 258 | Findus Crispy Pancakes Minced Beef | Findus | SE | frozen_meal | M | TODO | 2026-04-07 | | |
| 259 | MyProtein Protein Meal Prep Pot Chicken Tikka | MyProtein | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 260 | Fuel10K Protein Porridge Pot Chocolate | Fuel10K | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 261 | Haldiram's Ready to Eat Biryani | Haldiram's | IN | ready_meal | M | TODO | 2026-04-07 | | |

## Section 15: International Bread & Bakery (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 262 | Warburtons Medium Sliced White | Warburtons | GB | bread | M | TODO | 2026-04-07 | | |
| 263 | Warburtons Protein Thins | Warburtons | GB | bread | H | TODO | 2026-04-07 | | Protein bread |
| 264 | Hovis Seed Sensations | Hovis | GB | bread | M | TODO | 2026-04-07 | | |
| 265 | Mestemacher Protein Bread | Mestemacher | DE | bread | H | TODO | 2026-04-07 | | |
| 266 | Mestemacher Pumpernickel | Mestemacher | DE | bread | M | TODO | 2026-04-07 | | |
| 267 | Wasa Crispbread Original | Wasa | SE | bread | M | TODO | 2026-04-07 | | |
| 268 | Modern Bread White | Modern | IN | bread | M | TODO | 2026-04-07 | | |
| 269 | Pita Bread Kontos | Kontos | GR | bread | M | TODO | 2026-04-07 | | |
| 270 | Lo Dough Flatbread | Lo Dough | GB | bread | H | TODO | 2026-04-07 | | 29 cal per piece |
| 271 | Protein Tortilla Wrap BFree | BFree | IE | bread | H | TODO | 2026-04-07 | | High protein |
| 272 | Old El Paso Tortilla Wraps | Old El Paso | US | bread | M | TODO | 2026-04-07 | | |
| 273 | Dave's Killer Bread 21 Whole Grains | Dave's Killer Bread | US | bread | M | TODO | 2026-04-07 | | |
| 274 | P28 High Protein Bread | P28 | US | bread | H | TODO | 2026-04-07 | | 28g protein/serving |
| 275 | Hero Bread Zero Net Carb | Hero Bread | US | bread | M | TODO | 2026-04-07 | | |
| 276 | Sola Sweet & Buttery Bread | Sola | US | bread | M | TODO | 2026-04-07 | | |
| 277 | Base Culture Keto Bread | Base Culture | US | bread | M | TODO | 2026-04-07 | | |

## Section 16: Asian Snacks & Treats (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 278 | Mochi Ice Cream Little Moons Mango | Little Moons | GB | dessert | M | TODO | 2026-04-07 | | |
| 279 | Meiji Apollo Strawberry Chocolate | Meiji | JP | chocolate | M | TODO | 2026-04-07 | | |
| 280 | Kinoko no Yama Chocolate Mushroom | Meiji | JP | confectionery | M | TODO | 2026-04-07 | | |
| 281 | Takenoko no Sato Chocolate Bamboo | Meiji | JP | confectionery | M | TODO | 2026-04-07 | | |
| 282 | Umaibo Corn Pottage Stick | Yaokin | JP | snack | M | TODO | 2026-04-07 | | |
| 283 | Yan Yan Chocolate Dip | Meiji | JP | snack | M | TODO | 2026-04-07 | | |
| 284 | Samyang Corn Cheese Ramen | Samyang | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 285 | Crown Butter Waffle | Crown | KR | biscuit | M | TODO | 2026-04-07 | | |
| 286 | Haitai French Pie Apple | Haitai | KR | biscuit | M | TODO | 2026-04-07 | | |
| 287 | Orion Choco Pie Banana | Orion | KR | biscuit | M | TODO | 2026-04-07 | | |
| 288 | White Rabbit Creamy Candy | White Rabbit | CN | confectionery | M | TODO | 2026-04-07 | | Chinese icon |
| 289 | Want Want QQ Gummy Peach | Want Want | TW | confectionery | L | TODO | 2026-04-07 | | |
| 290 | Want Want Senbei Rice Crackers | Want Want | TW | snack | M | TODO | 2026-04-07 | | |
| 291 | Pineapple Cake SunnyHills | SunnyHills | TW | biscuit | M | TODO | 2026-04-07 | | Taiwanese specialty |
| 292 | Jack n Jill Chiz Curls | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 293 | Boy Bawang Cornick Garlic | KSK Food Products | PH | snack | M | TODO | 2026-04-07 | | |
| 294 | SkyFlakes Crackers | M.Y. San | PH | biscuit | M | TODO | 2026-04-07 | | |
| 295 | Milo Nuggets | Nestle | PH | snack | M | TODO | 2026-04-07 | | SE Asia snack |
| 296 | Julie's Peanut Butter Sandwich | Julie's | MY | biscuit | M | TODO | 2026-04-07 | | |
| 297 | Munchy's Lexus Cream Sandwich | Munchy's | MY | biscuit | M | TODO | 2026-04-07 | | |
| 298 | Tao Kae Noi Crispy Seaweed Original | Tao Kae Noi | TH | snack | H | TODO | 2026-04-07 | | |
| 299 | Tao Kae Noi Crispy Seaweed Wasabi | Tao Kae Noi | TH | snack | M | TODO | 2026-04-07 | | |
| 300 | Beng Beng Wafer Chocolate | Mayora | ID | chocolate | M | TODO | 2026-04-07 | | |
| 301 | Kopiko Coffee Candy | Kopiko | ID | confectionery | M | TODO | 2026-04-07 | | |
| 302 | Khong Guan Assorted Biscuits | Khong Guan | SG | biscuit | M | TODO | 2026-04-07 | | SE Asia icon |

## Section 17: Middle Eastern & Turkish Foods (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 303 | Ulker Biskrem Chocolate | Ulker | TR | biscuit | M | TODO | 2026-04-07 | | |
| 304 | Ulker Halley Chocolate Sandwich | Ulker | TR | biscuit | M | TODO | 2026-04-07 | | |
| 305 | Eti Tutku Chocolate Wafer | Eti | TR | biscuit | M | TODO | 2026-04-07 | | |
| 306 | Tahini Halva Plain (per 100g) | Various | TR | confectionery | M | TODO | 2026-04-07 | | |
| 307 | Mastic Gum Elma | Elma | GR | confectionery | L | TODO | 2026-04-07 | | |
| 308 | Al Fakher Dates Filled with Almond | Al Fakher | SA | confectionery | M | TODO | 2026-04-07 | | |
| 309 | Almarai Full Fat Milk 1L | Almarai | SA | dairy | M | TODO | 2026-04-07 | | |
| 310 | Almarai Chocolate Milk | Almarai | SA | dairy | M | TODO | 2026-04-07 | | |
| 311 | Almarai Fresh Juice Orange | Almarai | SA | beverage | M | TODO | 2026-04-07 | | |
| 312 | Nadec Laban (Buttermilk) | Nadec | SA | dairy | M | TODO | 2026-04-07 | | |
| 313 | Vimto Cordial (per serving) | Vimto | GB | beverage | M | TODO | 2026-04-07 | | Huge in Middle East |
| 314 | Ka'ak Bread Ring (Jerusalem) | Various | PS | bread | M | TODO | 2026-04-07 | | |
| 315 | Muhammara Red Pepper Dip | Various | SY | dip | M | TODO | 2026-04-07 | | |

## Section 18: Latin American Foods & Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 316 | Guarana Antarctica Soda | Ambev | BR | beverage | M | TODO | 2026-04-07 | | Brazil national soda |
| 317 | Havanna Alfajor Chocolate | Havanna | AR | confectionery | M | TODO | 2026-04-07 | | |
| 318 | Yerba Mate Taragui (brewed per cup) | Taragui | AR | beverage | M | TODO | 2026-04-07 | | |
| 319 | Modelo Especial Beer | Modelo | MX | beverage | M | TODO | 2026-04-07 | | |
| 320 | Tajin Clasico Seasoning (per tsp) | Tajin | MX | condiment | M | TODO | 2026-04-07 | | |
| 321 | Chamoy Sauce (per tbsp) | Various | MX | condiment | M | TODO | 2026-04-07 | | |
| 322 | Mazapan De La Rosa (per piece) | De La Rosa | MX | confectionery | M | TODO | 2026-04-07 | | |
| 323 | Carlos V Chocolate Bar | Nestle Mexico | MX | chocolate | M | TODO | 2026-04-07 | | |
| 324 | Gansito Marinela | Marinela | MX | biscuit | M | TODO | 2026-04-07 | | |
| 325 | Chifles Plantain Chips (Peru) | Various | PE | snack | M | TODO | 2026-04-07 | | |
| 326 | Lucuma Ice Cream (per scoop) | Various | PE | dessert | L | TODO | 2026-04-07 | | |

## Section 19: African Foods & Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 327 | Nando's Medium PERi-PERi Sauce (per tbsp) | Nando's | ZA | condiment | M | TODO | 2026-04-07 | | |
| 328 | Pronutro Original Cereal | Bokomo | ZA | cereal | M | TODO | 2026-04-07 | | SA breakfast staple |
| 329 | Indomie Chicken Flavor (Nigeria) | Indomie | NG | instant_noodle | M | TODO | 2026-04-07 | | Diff from Indonesian |

## Section 20: Indian Packaged Foods & Brands (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 330 | Threptin Diskettes Chocolate | Raptakos | IN | protein_snack | H | TODO | 2026-04-07 | | India protein classic |
| 331 | Horlicks Health Drink Classic Malt (per serving) | Horlicks | IN | beverage | H | TODO | 2026-04-07 | | |
| 332 | Complan Royale Chocolate (per serving) | Complan | IN | beverage | M | TODO | 2026-04-07 | | |
| 333 | Boost Health Drink (per serving) | Boost | IN | beverage | M | TODO | 2026-04-07 | | |
| 334 | Protinex Original (per serving) | Protinex | IN | protein_powder | H | TODO | 2026-04-07 | | |
| 335 | Ensure Diabetes Care Powder (per serving) | Ensure | IN | protein_powder | M | TODO | 2026-04-07 | | |
| 336 | Dabur Chyawanprash (per tsp) | Dabur | IN | supplement | M | TODO | 2026-04-07 | | |
| 337 | Mother Dairy Paneer (per 100g) | Mother Dairy | IN | dairy | H | TODO | 2026-04-07 | | |
| 338 | Amul Cheese Slice (per slice) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 339 | Amul Butter (per 10g) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 340 | Amul Protein Milkshake Kesar Pista | Amul | IN | protein_drink | H | TODO | 2026-04-07 | | |
| 341 | Paper Boat Thandai | Paper Boat | IN | beverage | M | TODO | 2026-04-07 | | |
| 342 | Bikaji Rasgulla (per piece) | Bikaji | IN | dessert | M | TODO | 2026-04-07 | | |
| 343 | Gits Jalebi Mix (per serving prepared) | Gits | IN | dessert | L | TODO | 2026-04-07 | | |
| 344 | MTR Rava Idli Mix (per serving prepared) | MTR | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 345 | Aashirvaad Multigrain Atta (per roti) | Aashirvaad | IN | staple | H | TODO | 2026-04-07 | | |
| 346 | Saffola Gold Oil (per tbsp) | Saffola | IN | cooking | M | TODO | 2026-04-07 | | |
| 347 | Cornitos Nacho Crisps Cheese & Herbs | Cornitos | IN | snack | M | TODO | 2026-04-07 | | |
| 348 | ACT II Instant Popcorn Butter | ACT II | IN | snack | M | TODO | 2026-04-07 | | |
| 349 | Lijjat Papad (per piece) | Lijjat | IN | snack | M | TODO | 2026-04-07 | | |
| 350 | Everest Kitchen King Masala (per tsp) | Everest | IN | condiment | M | TODO | 2026-04-07 | | |
| 351 | MDH Chana Masala (per tsp) | MDH | IN | condiment | M | TODO | 2026-04-07 | | |
| 352 | Priya Mango Pickle (per tbsp) | Priya | IN | condiment | M | TODO | 2026-04-07 | | |
| 353 | Mother's Recipe Mixed Pickle (per tbsp) | Mother's | IN | condiment | M | TODO | 2026-04-07 | | |
| 354 | Hajmola Candy (per piece) | Dabur | IN | confectionery | L | TODO | 2026-04-07 | | |

## Section 21: European Specialty Foods (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 355 | Camembert Isigny (per 30g) | Isigny | FR | dairy | M | TODO | 2026-04-07 | | |
| 356 | Comte Cheese (per 30g) | Various | FR | dairy | M | TODO | 2026-04-07 | | |
| 357 | Crepe Suzette (per piece) | Various | FR | dessert | M | TODO | 2026-04-07 | | |
| 358 | Danette Chocolate Pudding | Danone | FR | dessert | M | TODO | 2026-04-07 | | |
| 359 | Orangina Sparkling Citrus | Orangina | FR | beverage | M | TODO | 2026-04-07 | | |
| 360 | Grissini Breadsticks (per piece) | Various | IT | bread | M | TODO | 2026-04-07 | | |
| 361 | Manchego Cheese (per 30g) | Various | ES | dairy | M | TODO | 2026-04-07 | | |
| 362 | Gazpacho Alvalle (per serving) | Alvalle | ES | soup | M | TODO | 2026-04-07 | | |
| 363 | Edammer Cheese (per 30g) | Various | NL | dairy | M | TODO | 2026-04-07 | | |
| 364 | Currywurst with Sauce (per serving) | Various | DE | fast_food | M | TODO | 2026-04-07 | | |
| 365 | Pretzel Soft German (per piece) | Various | DE | bread | M | TODO | 2026-04-07 | | |
| 366 | Swedish Meatballs IKEA (per 5 pieces) | IKEA | SE | protein | H | TODO | 2026-04-07 | | |
| 367 | Knackebrod Crispbread (per piece) | Various | SE | bread | M | TODO | 2026-04-07 | | |
| 368 | Kanelbulle Cinnamon Bun (per piece) | Various | SE | bread | M | TODO | 2026-04-07 | | |
| 369 | Smoked Salmon Norwegian (per 30g) | Various | NO | protein | H | TODO | 2026-04-07 | | |
| 370 | Brown Cheese Brunost (per 20g) | Various | NO | dairy | M | TODO | 2026-04-07 | | |
| 371 | Kielbasa Polish Sausage (per link) | Various | PL | protein | M | TODO | 2026-04-07 | | |
| 372 | Paczki Donut (per piece) | Various | PL | dessert | M | TODO | 2026-04-07 | | |
| 373 | Bougatsa Cream Pie (per piece) | Various | GR | dessert | M | TODO | 2026-04-07 | | |

## Section 22: Health & Diet Brands (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 374 | Skinny Food Co Syrup Zero Calorie Maple | Skinny Food Co | GB | condiment | H | TODO | 2026-04-07 | | |
| 375 | Skinny Food Co Syrup Zero Calorie Chocolate | Skinny Food Co | GB | condiment | M | TODO | 2026-04-07 | | |
| 376 | Skinny Food Co Sauce Zero Calorie Ketchup | Skinny Food Co | GB | condiment | M | TODO | 2026-04-07 | | |
| 377 | ChocZero Sugar Free Chocolate Hazelnut Spread | ChocZero | US | spread | M | TODO | 2026-04-07 | | |
| 378 | Good Good Sweet Jam Strawberry | Good Good | IS | spread | M | TODO | 2026-04-07 | | |
| 379 | Choc Shot Hot Chocolate (per serving) | Choc Shot | GB | beverage | M | TODO | 2026-04-07 | | |
| 380 | Slender Chef Protein Pasta (per serving) | Slender Chef | SE | pasta | H | TODO | 2026-04-07 | | |
| 381 | Explore Cuisine Edamame Spaghetti | Explore Cuisine | US | pasta | H | TODO | 2026-04-07 | | |
| 382 | Konjac Noodles (Shirataki) Skinny Pasta | Various | JP | pasta | H | TODO | 2026-04-07 | | Near zero cal |
| 383 | Slendier Slim Pasta Spaghetti | Slendier | AU | pasta | M | TODO | 2026-04-07 | | |
| 384 | Nick's Light Ice Cream Swedish Chocolate | Nick's | SE | dessert | H | TODO | 2026-04-07 | | Low cal ice cream |
| 385 | Nick's Light Ice Cream Peanut Butter Cup | Nick's | SE | dessert | M | TODO | 2026-04-07 | | |
| 386 | Oppo Brothers Salted Caramel Ice Cream | Oppo | GB | dessert | M | TODO | 2026-04-07 | | |
| 387 | Arctic Zero Chocolate Peanut Butter | Arctic Zero | US | dessert | M | TODO | 2026-04-07 | | |
| 388 | Project 7 Low Sugar Gummies | Project 7 | US | confectionery | L | TODO | 2026-04-07 | | |

## Section 23: Plant-Based / Vegan Brands (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 389 | Beyond Meat Beyond Burger (per patty) | Beyond Meat | US | meat_alt | H | TODO | 2026-04-07 | | |
| 390 | Beyond Meat Beyond Sausage Italian (per link) | Beyond Meat | US | meat_alt | M | TODO | 2026-04-07 | | |
| 391 | Oatly Chocolate Oat Milk | Oatly | SE | dairy_alt | M | TODO | 2026-04-07 | | |
| 392 | Alpro Soya Original | Alpro | BE | dairy_alt | M | TODO | 2026-04-07 | | |
| 393 | Alpro Oat Milk Barista | Alpro | BE | dairy_alt | M | TODO | 2026-04-07 | | |
| 394 | Violife Mature Cheddar Slices | Violife | GR | dairy_alt | M | TODO | 2026-04-07 | | |
| 395 | Miyoko's Creamery Cultured Vegan Butter | Miyoko's | US | dairy_alt | M | TODO | 2026-04-07 | | |
| 396 | Ripple Pea Protein Milk Original | Ripple | US | dairy_alt | M | TODO | 2026-04-07 | | |
| 397 | Tofurky Plant-Based Deli Slices Hickory Smoked | Tofurky | US | meat_alt | M | TODO | 2026-04-07 | | |
| 398 | Lightlife Plant-Based Burger | Lightlife | US | meat_alt | M | TODO | 2026-04-07 | | |
| 399 | THIS Isn't Chicken Plant-Based Pieces | THIS | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 400 | THIS Isn't Bacon Plant-Based Rashers | THIS | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 401 | Moving Mountains Plant-Based Burger | Moving Mountains | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 402 | Vivera Plant Steak | Vivera | NL | meat_alt | M | TODO | 2026-04-07 | | |
| 403 | The Vegetarian Butcher No Chicken Chunks | The Vegetarian Butcher | NL | meat_alt | M | TODO | 2026-04-07 | | |
| 404 | Heura Mediterranean Chicken Chunks | Heura | ES | meat_alt | M | TODO | 2026-04-07 | | |
| 405 | Like Meat Like Chicken | Like Meat | DE | meat_alt | M | TODO | 2026-04-07 | | |
| 406 | GoodDot Proteiz (per serving) | GoodDot | IN | meat_alt | M | TODO | 2026-04-07 | | India plant-based pioneer |
| 407 | Blue Tribe Plant-Based Chicken Keema | Blue Tribe | IN | meat_alt | M | TODO | 2026-04-07 | | |

## Section 24: International Rice, Grain & Staple Products (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 408 | Uncle Ben's Ready Rice Basmati | Uncle Ben's | US | staple | M | TODO | 2026-04-07 | | |
| 409 | Nishiki Sushi Rice (cooked per 100g) | Nishiki | JP | staple | M | TODO | 2026-04-07 | | |
| 410 | Bulgur Wheat Cooked (per 100g) | Various | TR | staple | M | TODO | 2026-04-07 | | |
| 411 | Soba Noodles Cooked (per 100g) | Various | JP | staple | M | TODO | 2026-04-07 | | |
| 412 | Udon Noodles Cooked (per 100g) | Various | JP | staple | M | TODO | 2026-04-07 | | |
| 413 | Glass Noodles (Japchae) Cooked (per 100g) | Various | KR | staple | M | TODO | 2026-04-07 | | |
| 414 | Ragi Malt (per serving) | Various | IN | staple | M | TODO | 2026-04-07 | | South Indian health drink |
| 415 | Millet Dosa (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |

## Section 25: Protein Ice Cream & Frozen Treats (10 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 416 | Wheyhey Protein Ice Cream Chocolate | Wheyhey | GB | dessert | M | TODO | 2026-04-07 | | |
| 417 | Wheyhey Protein Ice Cream Banoffee | Wheyhey | GB | dessert | M | TODO | 2026-04-07 | | |
| 418 | Breyers Carb Smart Vanilla | Breyers | US | dessert | M | TODO | 2026-04-07 | | |
| 419 | So Delicious Dairy Free Cashew Milk Salted Caramel | So Delicious | US | dessert | M | TODO | 2026-04-07 | | |
| 420 | Cornetto Classic (per cone) | Wall's | GB | dessert | M | TODO | 2026-04-07 | | |

## Section 26: Meal Replacement & Complete Foods (10 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 421 | AG1 Athletic Greens (per serving) | Athletic Greens | US | supplement | H | TODO | 2026-04-07 | | |
| 422 | Huel Hot & Savoury Mac & Cheese | Huel | GB | meal_replacement | M | TODO | 2026-04-07 | | |
| 423 | Huel Bar Chocolate Orange | Huel | GB | meal_replacement | M | TODO | 2026-04-07 | | |
| 424 | Soylent Squared Bar Chocolate Brownie | Soylent | US | meal_replacement | M | TODO | 2026-04-07 | | |
| 425 | Feed Light Meal Chocolate | Feed | FR | meal_replacement | M | TODO | 2026-04-07 | | |
| 426 | Queal Steady Standard Chocolate | Queal | NL | meal_replacement | L | TODO | 2026-04-07 | | |
| 427 | Ambronite Complete Meal Shake Ginger Apple | Ambronite | FI | meal_replacement | L | TODO | 2026-04-07 | | |
| 428 | Bertrand Classic Organic Meal Shake | Bertrand | DE | meal_replacement | L | TODO | 2026-04-07 | | |

## Section 27: International Coffee Drinks (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 429 | Starbucks Doubleshot Espresso Can | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 430 | Starbucks Frappuccino Mocha Bottle | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 431 | Georgia Coffee Max Coffee (Japan) | Coca-Cola Japan | JP | beverage | M | TODO | 2026-04-07 | | Japanese canned coffee |
| 432 | BOSS Coffee Rainbow Mountain | Suntory | JP | beverage | M | TODO | 2026-04-07 | | |
| 433 | Nescafe Gold Instant Coffee (per cup) | Nescafe | CH | beverage | M | TODO | 2026-04-07 | | |
| 434 | Bru Instant Coffee (per cup) | Bru | IN | beverage | M | TODO | 2026-04-07 | | India popular |
| 435 | Nescafe Classic (India per cup) | Nescafe | IN | beverage | M | TODO | 2026-04-07 | | |
| 436 | Turkish Coffee (per cup) | Various | TR | beverage | M | TODO | 2026-04-07 | | |
| 437 | Costa Coffee RTD Latte Can | Costa | GB | beverage | M | TODO | 2026-04-07 | | |
| 438 | Oatly Barista Oat Latte RTD | Oatly | SE | beverage | M | TODO | 2026-04-07 | | |

## Section 28: Fitness Supplements (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 439 | Creatine HCl Kaged (per serving) | Kaged | US | supplement | M | TODO | 2026-04-07 | | |
| 440 | Pre-Workout Ghost Legend Sour Patch (per serving) | Ghost | US | supplement | M | TODO | 2026-04-07 | | |
| 441 | Pre-Workout Gorilla Mode (per serving) | Gorilla Mind | US | supplement | M | TODO | 2026-04-07 | | |
| 442 | BCAA Scivation Xtend Blue Raspberry (per serving) | Scivation | US | supplement | M | TODO | 2026-04-07 | | |
| 443 | EAA Applied Nutrition (per serving) | Applied Nutrition | GB | supplement | M | TODO | 2026-04-07 | | |
| 444 | Glutamine Powder (per 5g) | Various | US | supplement | L | TODO | 2026-04-07 | | |
| 445 | Fish Oil Triple Strength (per softgel) | Various | US | supplement | M | TODO | 2026-04-07 | | |
| 446 | Multivitamin Animal Pak (per serving) | Universal | US | supplement | M | TODO | 2026-04-07 | | |
| 447 | ZMA Optimum Nutrition (per serving) | Optimum Nutrition | US | supplement | L | TODO | 2026-04-07 | | |
| 448 | Ashwagandha KSM-66 (per capsule) | Various | IN | supplement | M | TODO | 2026-04-07 | | |
| 449 | Mass Gainer Serious Mass Chocolate (per serving) | Optimum Nutrition | US | supplement | M | TODO | 2026-04-07 | | |
| 450 | Casein Protein Gold Standard Chocolate (per scoop) | Optimum Nutrition | US | protein_powder | M | TODO | 2026-04-07 | | |

## Section 29: International Tea & Traditional Drinks (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 451 | Tata Tea Gold (per cup brewed) | Tata | IN | beverage | M | TODO | 2026-04-07 | | |
| 452 | Wagh Bakri Instant Tea Premix (per sachet) | Wagh Bakri | IN | beverage | M | TODO | 2026-04-07 | | |
| 453 | Genmaicha (per cup) | Various | JP | beverage | L | TODO | 2026-04-07 | | |
| 454 | Yuzu Tea (Korean Yuja per cup) | Various | KR | beverage | M | TODO | 2026-04-07 | | |
| 455 | Hibiscus Tea Agua de Jamaica (per cup) | Various | MX | beverage | M | TODO | 2026-04-07 | | |
| 456 | Atole de Chocolate (per cup) | Various | MX | beverage | M | TODO | 2026-04-07 | | |
| 457 | Kombucha GT's Original (per bottle) | GT's | US | beverage | M | TODO | 2026-04-07 | | |
| 458 | Kombucha GT's Gingerade (per bottle) | GT's | US | beverage | M | TODO | 2026-04-07 | | |
| 459 | Turmeric Latte Golden Milk (per cup) | Various | IN | beverage | M | TODO | 2026-04-07 | | |

## Section 30: Fast Food International Chains (30 items)

| # | Food Name | Brand | Country | Restaurant | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|------------|----------|----------|--------|------------|----------------|-------|
| 460 | Jollibee Yumburger | Jollibee | PH | Jollibee | fast_food | M | TODO | 2026-04-07 | | |
| 461 | Nando's Peri-Peri Chicken Thigh | Nando's | ZA | Nando's | fast_food | M | TODO | 2026-04-07 | | |
| 462 | Tim Hortons Original Donut | Tim Hortons | CA | Tim Hortons | fast_food | M | TODO | 2026-04-07 | | |
| 463 | Tim Hortons Timbits (per piece) | Tim Hortons | CA | Tim Hortons | fast_food | M | TODO | 2026-04-07 | | |
| 464 | Harvey's Original Burger | Harvey's | CA | Harvey's | fast_food | M | TODO | 2026-04-07 | | |
| 465 | Mary Brown's Big Mary Chicken Sandwich | Mary Brown's | CA | Mary Brown's | fast_food | M | TODO | 2026-04-07 | | |
| 466 | A2B (Adyar Ananda Bhavan) Ghee Pongal | A2B | IN | A2B | fast_food | M | TODO | 2026-04-07 | | |
| 467 | Barbeque Nation Chicken Starter (per piece) | Barbeque Nation | IN | Barbeque Nation | fast_food | M | TODO | 2026-04-07 | | |
| 468 | Max Burgers Original (Sweden) | Max | SE | Max Burgers | fast_food | M | TODO | 2026-04-07 | | |
| 469 | Hesburger Cheese Burger (Finland) | Hesburger | FI | Hesburger | fast_food | M | TODO | 2026-04-07 | | |
| 470 | Mos Burger Rice Burger Yakiniku | Mos Burger | JP | Mos Burger | fast_food | M | TODO | 2026-04-07 | | |
| 471 | Yoshinoya Beef Bowl Regular | Yoshinoya | JP | Yoshinoya | fast_food | H | TODO | 2026-04-07 | | |
| 472 | CoCo Ichibanya Curry Rice Pork Cutlet | CoCo Ichibanya | JP | CoCo Ichibanya | fast_food | M | TODO | 2026-04-07 | | |
| 473 | Lotteria Teriyaki Burger | Lotteria | KR | Lotteria | fast_food | M | TODO | 2026-04-07 | | |

## Section 31: Trending / Viral Foods (20 items)

| # | Food Name | Brand | Country | Restaurant | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|------------|----------|----------|--------|------------|----------------|-------|
| 474 | Dubai Chocolate Bar Fix Dessert Chocolatier | Fix Dessert | AE | | chocolate | H | TODO | 2026-04-07 | | Viral pistachio kunafa chocolate |
| 475 | Crumbl Cookie Chocolate Chip (per cookie) | Crumbl | US | Crumbl | dessert | H | TODO | 2026-04-07 | | Viral bakery chain |
| 476 | Crumbl Cookie Pink Sugar (per cookie) | Crumbl | US | Crumbl | dessert | M | TODO | 2026-04-07 | | |
| 477 | Crumbl Cookie Biscoff Lava (per cookie) | Crumbl | US | Crumbl | dessert | M | TODO | 2026-04-07 | | |
| 478 | Insomnia Cookies Classic Chocolate Chunk (per cookie) | Insomnia Cookies | US | Insomnia Cookies | dessert | M | TODO | 2026-04-07 | | |
| 479 | Levain Bakery Chocolate Chip Walnut Cookie | Levain Bakery | US | Levain Bakery | dessert | M | TODO | 2026-04-07 | | |
| 480 | Biscoff Ice Cream Ben & Jerry's | Ben & Jerry's | US | | dessert | M | TODO | 2026-04-07 | | |
| 481 | Lotus Biscoff Ice Cream | Lotus | BE | | dessert | M | TODO | 2026-04-07 | | |
| 482 | Doritos Dinamita Chile Limon | Doritos | US | | snack | M | TODO | 2026-04-07 | | |
| 483 | Trader Joe's Everything But The Bagel Seasoning (per tsp) | Trader Joe's | US | | condiment | M | TODO | 2026-04-07 | | |

## Section 32: Australian & New Zealand Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 484 | Weet-Bix Original (per 2 biscuits) | Sanitarium | AU | cereal | H | TODO | 2026-04-07 | | Aus/NZ staple |
| 485 | Weet-Bix Protein (per 2 biscuits) | Sanitarium | AU | cereal | H | TODO | 2026-04-07 | | |
| 486 | Uncle Toby's Quick Oats (per serving) | Uncle Toby's | AU | cereal | M | TODO | 2026-04-07 | | |
| 487 | Dare Iced Coffee Double Espresso | Dare | AU | beverage | M | TODO | 2026-04-07 | | |
| 488 | Cherry Ripe Chocolate Bar | Cadbury | AU | chocolate | M | TODO | 2026-04-07 | | Aus exclusive |
| 489 | Violet Crumble Chocolate Bar | Robern Menz | AU | chocolate | M | TODO | 2026-04-07 | | |
| 490 | Meat Pie Four'N Twenty (per pie) | Four'N Twenty | AU | fast_food | H | TODO | 2026-04-07 | | Aus icon |
| 491 | Sausage Roll Four'N Twenty (per roll) | Four'N Twenty | AU | fast_food | M | TODO | 2026-04-07 | | |
| 492 | L&P Lemon & Paeroa Soda | L&P | NZ | beverage | M | TODO | 2026-04-07 | | NZ icon |
| 493 | Whittaker's Dark Ghana Peppermint | Whittaker's | NZ | chocolate | M | TODO | 2026-04-07 | | |
| 494 | Cookie Time Original Chocolate Chip | Cookie Time | NZ | biscuit | M | TODO | 2026-04-07 | | NZ icon |
| 495 | Barker's Fruit Syrup Boysenberry (per serving) | Barker's | NZ | condiment | L | TODO | 2026-04-07 | | |

## Section 33: Russian & Eastern European Foods (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 496 | Pelmeni Russian Dumplings (per 5 pieces) | Various | RU | snack | M | TODO | 2026-04-07 | | |
| 497 | Blini Russian Pancakes (per piece) | Various | RU | bread | M | TODO | 2026-04-07 | | |
| 498 | Varenyky Ukrainian Dumplings (per 5 pieces) | Various | UA | snack | M | TODO | 2026-04-07 | | |
| 499 | Kvass Ochakovo (per 250ml) | Ochakovo | RU | beverage | M | TODO | 2026-04-07 | | |
| 500 | Zefir Russian Marshmallow (per piece) | Various | RU | confectionery | M | TODO | 2026-04-07 | | |
| 501 | Alyonka Chocolate Bar | Kommunarka | RU | chocolate | M | TODO | 2026-04-07 | | Russian icon |
| 502 | Langos Hungarian Fried Bread (per piece) | Various | HU | bread | M | TODO | 2026-04-07 | | |
| 503 | Kolace Czech Pastry (per piece) | Various | CZ | dessert | M | TODO | 2026-04-07 | | |
| 504 | Cevapcici Balkan Sausage (per 5 pieces) | Various | BA | protein | M | TODO | 2026-04-07 | | |
| 505 | Burek Meat Pie (per piece) | Various | BA | snack | M | TODO | 2026-04-07 | | |
| 506 | Rakija Plum Brandy (per shot) | Various | RS | beverage | L | TODO | 2026-04-07 | | |

## Section 34: Southeast Asian Foods (25 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 507 | Nasi Lemak Coconut Rice (per serving) | Various | MY | rice | H | TODO | 2026-04-07 | | Malaysian national dish |
| 508 | Kaya Toast Set (per serving) | Various | SG | breakfast | M | TODO | 2026-04-07 | | |
| 509 | Chili Crab Singapore (per serving) | Various | SG | protein | M | TODO | 2026-04-07 | | |
| 510 | Som Tum Green Papaya Salad (per serving) | Various | TH | salad | M | TODO | 2026-04-07 | | |
| 511 | Pho Bo Vietnamese Beef (per serving) | Various | VN | noodle | H | TODO | 2026-04-07 | | |
| 512 | Goi Cuon Spring Roll (per roll) | Various | VN | snack | M | TODO | 2026-04-07 | | |
| 513 | Ca Phe Trung Egg Coffee (per cup) | Various | VN | beverage | M | TODO | 2026-04-07 | | |
| 514 | Sinigang Pork (per serving) | Various | PH | soup | M | TODO | 2026-04-07 | | |
| 515 | Mohinga Fish Noodle Soup (per serving) | Various | MM | noodle | M | TODO | 2026-04-07 | | Myanmar national dish |
| 516 | Amok Fish Curry (per serving) | Various | KH | protein | M | TODO | 2026-04-07 | | Cambodian national dish |

## Section 35: Japanese Convenience Store Foods (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 517 | Egg Sandwich Konbini (per pack) | Various | JP | fast_food | M | TODO | 2026-04-07 | | |
| 518 | Japanese Cheesecake Uncle Tetsu (per piece) | Uncle Tetsu | JP | dessert | M | TODO | 2026-04-07 | | |
| 519 | Okonomiyaki (per serving) | Various | JP | snack | M | TODO | 2026-04-07 | | |
| 520 | Gyudon Beef Bowl (per serving) | Various | JP | fast_food | H | TODO | 2026-04-07 | | |
| 521 | Japanese Curry Rice (per serving) | Various | JP | fast_food | M | TODO | 2026-04-07 | | |
| 522 | Mochi Daifuku Red Bean (per piece) | Various | JP | dessert | M | TODO | 2026-04-07 | | |
| 523 | Matcha Kit Kat Mini (per piece) | Nestle | JP | chocolate | M | TODO | 2026-04-07 | | |

## Section 36: Korean Convenience Store & Street Food (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 524 | Kimbap Classic (per roll) | Various | KR | snack | H | TODO | 2026-04-07 | | |
| 525 | Japchae Glass Noodles (per serving) | Various | KR | noodle | M | TODO | 2026-04-07 | | |
| 526 | Hotteok Sweet Pancake (per piece) | Various | KR | dessert | M | TODO | 2026-04-07 | | |
| 527 | Bingsu Patbingsu (per serving) | Various | KR | dessert | M | TODO | 2026-04-07 | | |
| 528 | Samgak Kimbap Triangle (per piece) | Various | KR | snack | M | TODO | 2026-04-07 | | Konbini |
| 529 | Soju Flavored Peach (per shot) | Various | KR | beverage | L | TODO | 2026-04-07 | | |
| 530 | Dakgangjeong Sweet Crispy Chicken (per 100g) | Various | KR | protein | M | TODO | 2026-04-07 | | |

## Section 37: Chinese Staples & Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 531 | Dim Sum Har Gow Shrimp Dumpling (per piece) | Various | CN | snack | H | TODO | 2026-04-07 | | |
| 532 | Dim Sum Siu Mai Pork Dumpling (per piece) | Various | CN | snack | H | TODO | 2026-04-07 | | |
| 533 | Xiao Long Bao Soup Dumpling (per piece) | Various | CN | snack | H | TODO | 2026-04-07 | | |
| 534 | Baozi Steamed Bun Pork (per piece) | Various | CN | snack | M | TODO | 2026-04-07 | | |
| 535 | Congee Rice Porridge Plain (per serving) | Various | CN | breakfast | M | TODO | 2026-04-07 | | |
| 536 | Zongzi Rice Dumpling (per piece) | Various | CN | snack | M | TODO | 2026-04-07 | | |
| 537 | Mooncake Lotus Seed (per piece) | Various | CN | dessert | M | TODO | 2026-04-07 | | |
| 538 | Egg Tart Portuguese Style (per piece) | Various | HK | dessert | M | TODO | 2026-04-07 | | |
| 539 | Soy Milk Sweetened (per 250ml) | Various | CN | beverage | M | TODO | 2026-04-07 | | |
| 540 | Bubble Waffle Egg Puff (per piece) | Various | HK | dessert | M | TODO | 2026-04-07 | | |
| 541 | Master Kong Instant Noodles Braised Beef | Master Kong | CN | instant_noodle | M | TODO | 2026-04-07 | | China #1 brand |
| 542 | Uni-President Instant Noodles Beef | Uni-President | TW | instant_noodle | M | TODO | 2026-04-07 | | |
| 543 | Lao Gan Ma Spicy Diced Chicken Oil | Lao Gan Ma | CN | condiment | M | TODO | 2026-04-07 | | |

## Section 38: Fitness Meal Prep Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 544 | Trifecta Organic Grass-Fed Beef | Trifecta | US | meal_prep | M | TODO | 2026-04-07 | | |
| 545 | Icon Meals Grilled Chicken & Rice | Icon Meals | US | meal_prep | M | TODO | 2026-04-07 | | |
| 546 | My Muscle Chef Chicken Pad Thai | My Muscle Chef | AU | meal_prep | M | TODO | 2026-04-07 | | |
| 547 | My Muscle Chef Beef Bolognese | My Muscle Chef | AU | meal_prep | M | TODO | 2026-04-07 | | |
| 548 | Macro Mike Protein Pancake Mix (per serving) | Macro Mike | AU | breakfast | M | TODO | 2026-04-07 | | |
| 549 | Evolve Plant Based Protein Shake Chocolate | Evolve | US | protein_drink | M | TODO | 2026-04-07 | | |
| 550 | OATHAUS Granola Butter Original | OATHAUS | US | spread | M | TODO | 2026-04-07 | | TikTok viral |

## Section 39: Additional International Niche Items (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 551 | Pocari Sweat Powder (per serving) | Otsuka | JP | sports_drink | M | TODO | 2026-04-07 | | |
| 552 | Aquarius Zero Sports Drink | Coca-Cola Japan | JP | sports_drink | M | TODO | 2026-04-07 | | |
| 553 | Calpis Concentrate (per serving) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | |
| 554 | Ajinomoto Gyoza Frozen (per 5 pieces) | Ajinomoto | JP | frozen_meal | M | TODO | 2026-04-07 | | |
| 555 | CJ Bibigo Mandu Dumplings (per 5 pieces) | CJ | KR | frozen_meal | H | TODO | 2026-04-07 | | |
| 556 | Ottogi Curry Mild (per serving) | Ottogi | KR | ready_meal | M | TODO | 2026-04-07 | | |
| 557 | Vita Plus Dalandan Juice (Philippines) | Vita Plus | PH | beverage | L | TODO | 2026-04-07 | | |
| 558 | Vitamilk Soy Milk Original | Vitamilk | TH | beverage | M | TODO | 2026-04-07 | | |
| 559 | Indomilk Condensed Milk (per tbsp) | Indomilk | ID | dairy | M | TODO | 2026-04-07 | | |
| 560 | Abon (Indonesian Meat Floss per tbsp) | Various | ID | protein | M | TODO | 2026-04-07 | | |
| 561 | Kerupuk Udang Shrimp Crackers (per 5 pieces) | Various | ID | snack | M | TODO | 2026-04-07 | | |
| 562 | Shan Biryani Masala (per serving mix) | Shan | PK | condiment | M | TODO | 2026-04-07 | | |
| 563 | National Achar Gosht Masala (per serving) | National | PK | condiment | L | TODO | 2026-04-07 | | |
| 564 | Tapal Danedar Tea (per cup brewed) | Tapal | PK | beverage | M | TODO | 2026-04-07 | | Pakistan #1 tea |
| 565 | Olper's Full Cream Milk (per 250ml) | Olper's | PK | dairy | M | TODO | 2026-04-07 | | |
| 566 | Nurpur Butter (per 10g) | Nurpur | PK | dairy | M | TODO | 2026-04-07 | | |
| 567 | Dawn Paratha (per piece) | Dawn | PK | bread | M | TODO | 2026-04-07 | | Pakistan frozen |
| 568 | Knorr Noodles Chatpata (Pakistan) | Knorr | PK | instant_noodle | M | TODO | 2026-04-07 | | |
| 569 | Kolson Slanty Chips | Kolson | PK | snack | M | TODO | 2026-04-07 | | |
| 570 | Milo Australia RTD (different formula) | Nestle | AU | beverage | M | TODO | 2026-04-07 | | |
| 571 | Up&Go Liquid Breakfast Chocolate | Sanitarium | AU | meal_replacement | M | TODO | 2026-04-07 | | Aus breakfast staple |
| 572 | Golden Gaytime Ice Cream Bar | Streets | AU | dessert | M | TODO | 2026-04-07 | | Aus icon |
| 573 | Zooper Dooper Ice Block (per stick) | Zooper Dooper | AU | dessert | L | TODO | 2026-04-07 | | |
| 574 | Magnum Double Gold Caramel Billionaire | Magnum | AU | dessert | M | TODO | 2026-04-07 | | |
| 575 | Cottee's Cordial Coola (per serving) | Cottee's | AU | beverage | L | TODO | 2026-04-07 | | |
| 576 | Schweppes Lemon Lime Bitters | Schweppes | AU | beverage | M | TODO | 2026-04-07 | | |

## Section 40: Bonus - More Niche Fitness & International (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 577 | Mr. Iron 30% Protein Cereals Vanilla | Mr. Iron | EU | protein_cereal | H | TODO | 2026-04-07 | | |
| 578 | QNT Protein Joy Bar Cookie Dough | QNT | BE | protein_bar | M | TODO | 2026-04-07 | | |
| 579 | Rawbite Protein Crunchy Almond | Rawbite | DK | protein_bar | M | TODO | 2026-04-07 | | |
| 580 | NOCCO BCAA Focus Black Orange | NOCCO | SE | energy_drink | M | TODO | 2026-04-07 | | |
| 581 | FITAID Energy Drink | FITAID | US | energy_drink | M | TODO | 2026-04-07 | | CrossFit popular |
| 582 | Ryse Fuel Smarties | Ryse | US | energy_drink | M | TODO | 2026-04-07 | | |
| 583 | Raw Nutrition CBUM Thavage Pre-Workout (per serving) | Raw Nutrition | US | supplement | M | TODO | 2026-04-07 | | |
| 584 | 1st Phorm Level-1 Protein Chocolate | 1st Phorm | US | protein_powder | M | TODO | 2026-04-07 | | |
| 585 | Ryse Loaded Protein Cinnamon Toast | Ryse | US | protein_powder | M | TODO | 2026-04-07 | | |
| 586 | G Fuel Energy Formula Blue Ice (per serving) | G Fuel | US | energy_drink | M | TODO | 2026-04-07 | | Gaming/fitness |
| 587 | Snaq Fabriq Chocolate Bar | Snaq Fabriq | RU | protein_bar | M | TODO | 2026-04-07 | | Russian fitness brand |
| 588 | MyProtein Protein Cookie Double Chocolate | MyProtein | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 589 | PhD Smart Plant Bar Choc Toffee Popcorn | PhD Nutrition | GB | protein_bar | M | TODO | 2026-04-07 | | Vegan |
| 590 | Myprotein Vegan Protein Blend Chocolate | MyProtein | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 591 | Fast&Up Whey Advanced Protein Rich Chocolate | Fast&Up | IN | protein_powder | M | TODO | 2026-04-07 | | |
| 592 | OZiva Protein & Herbs for Men Chocolate | OZiva | IN | protein_powder | M | TODO | 2026-04-07 | | India fitness |
| 593 | MuscleBlaze Raw Whey Protein Unflavored | MuscleBlaze | IN | protein_powder | M | TODO | 2026-04-07 | | |

---


## Section 41: UK Supermarket Own Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 594 | Tesco Finest Free Range Chicken Breast (per 100g) | Tesco | GB | protein | H | TODO | 2026-04-07 | | |
| 595 | Tesco Protein Yogurt Strawberry | Tesco | GB | dairy | M | TODO | 2026-04-07 | | |
| 596 | Tesco Plant Chef Meat Free Burgers (per patty) | Tesco | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 597 | Tesco Finest Granola Honey Almond | Tesco | GB | cereal | M | TODO | 2026-04-07 | | |
| 598 | Sainsbury's Be Good to Yourself Prawn Noodles | Sainsbury's | GB | ready_meal | M | TODO | 2026-04-07 | | |
| 599 | Sainsbury's High Protein Greek Style Yogurt | Sainsbury's | GB | dairy | H | TODO | 2026-04-07 | | |
| 600 | Sainsbury's Protein Chicken Wrap | Sainsbury's | GB | fast_food | M | TODO | 2026-04-07 | | |
| 601 | Sainsbury's Free From Chocolate Brownie | Sainsbury's | GB | dessert | L | TODO | 2026-04-07 | | |
| 602 | M&S Count on Us Chicken Noodle Stir Fry | M&S | GB | ready_meal | M | TODO | 2026-04-07 | | |
| 603 | M&S Eat Well Chicken Tikka Rice | M&S | GB | ready_meal | M | TODO | 2026-04-07 | | |
| 604 | M&S Percy Pig Sweets (per 100g) | M&S | GB | confectionery | H | TODO | 2026-04-07 | | UK cult sweet |
| 605 | M&S Colin the Caterpillar Cake (per slice) | M&S | GB | dessert | M | TODO | 2026-04-07 | | |
| 606 | M&S Plant Kitchen No Chicken Kievs (per piece) | M&S | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 607 | Waitrose Essential British Chicken Breast (per 100g) | Waitrose | GB | protein | M | TODO | 2026-04-07 | | |
| 608 | Waitrose Love Life Granola Nuts & Seeds | Waitrose | GB | cereal | M | TODO | 2026-04-07 | | |
| 609 | Aldi Brooklea Protein Yogurt Vanilla | Aldi UK | GB | dairy | H | TODO | 2026-04-07 | | |
| 610 | Aldi Specially Selected Granola Berry | Aldi UK | GB | cereal | M | TODO | 2026-04-07 | | |
| 611 | Lidl Milbona High Protein Yogurt Blueberry | Lidl | GB | dairy | H | TODO | 2026-04-07 | | |
| 612 | Lidl Deluxe Irish Butter (per 10g) | Lidl | GB | dairy | M | TODO | 2026-04-07 | | |
| 613 | Myprotein Protein Bread Rolls (per roll) | MyProtein | GB | bread | H | TODO | 2026-04-07 | | |
| 614 | The Skinny Food Co Not Guilty Low Cal Popcorn | Skinny Food Co | GB | snack | M | TODO | 2026-04-07 | | |
| 615 | Hartley's 10 Cal Jelly Strawberry | Hartley's | GB | dessert | H | TODO | 2026-04-07 | | Diet staple UK |
| 616 | Batchelors Super Noodles Chicken | Batchelors | GB | instant_noodle | M | TODO | 2026-04-07 | | |
| 617 | Pot Noodle Chicken & Mushroom | Pot Noodle | GB | instant_noodle | M | TODO | 2026-04-07 | | |
| 618 | Nando's PERInaise Original (per tbsp) | Nando's | GB | condiment | M | TODO | 2026-04-07 | | |
| 619 | Hellmann's Light Mayo UK (per tbsp) | Hellmann's | GB | condiment | M | TODO | 2026-04-07 | | |
| 620 | Cathedral City Mature Cheddar (per 30g) | Cathedral City | GB | dairy | M | TODO | 2026-04-07 | | |
| 621 | Cathedral City Lighter Cheddar (per 30g) | Cathedral City | GB | dairy | M | TODO | 2026-04-07 | | |
| 622 | Babybel Mini Original (per piece) | Babybel | FR | dairy | M | TODO | 2026-04-07 | | |
| 623 | Babybel Mini Light (per piece) | Babybel | FR | dairy | M | TODO | 2026-04-07 | | |
| 624 | Skyr Arla Protein Strawberry | Arla | DK | dairy | H | TODO | 2026-04-07 | | |
| 625 | Benecol Original Drink (per bottle) | Benecol | FI | dairy | M | TODO | 2026-04-07 | | |
| 626 | Frijj Chocolate Milkshake | Frijj | GB | beverage | M | TODO | 2026-04-07 | | |
| 627 | Ribena Blackcurrant (per serving) | Ribena | GB | beverage | M | TODO | 2026-04-07 | | |
| 628 | Robinsons Fruit Shoot (per bottle) | Robinsons | GB | beverage | L | TODO | 2026-04-07 | | |
| 629 | Irn Bru Original (per can) | Irn Bru | GB | beverage | M | TODO | 2026-04-07 | | Scottish icon |
| 630 | Lucozade Energy Original (per can) | Lucozade | GB | energy_drink | M | TODO | 2026-04-07 | | |
| 631 | Vimto Still (per carton) | Vimto | GB | beverage | M | TODO | 2026-04-07 | | |

## Section 42: German Supermarket & Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 632 | Aldi Süd Milsani Protein Yogurt Natur | Aldi Süd | DE | dairy | H | TODO | 2026-04-07 | | |
| 633 | Aldi Süd GutBio Haferflocken (per serving) | Aldi Süd | DE | cereal | M | TODO | 2026-04-07 | | |
| 634 | Lidl Milbona Magerquark (per 100g) | Lidl | DE | dairy | H | TODO | 2026-04-07 | | German fitness staple |
| 635 | Lidl Milbona Skyr Natur | Lidl | DE | dairy | H | TODO | 2026-04-07 | | |
| 636 | Lidl Protein Pudding Chocolate | Lidl | DE | dairy | H | TODO | 2026-04-07 | | |
| 637 | Ehrmann High Protein Pudding Chocolate | Ehrmann | DE | dairy | H | TODO | 2026-04-07 | | Huge in EU |
| 638 | Ehrmann High Protein Pudding Vanilla | Ehrmann | DE | dairy | H | TODO | 2026-04-07 | | |
| 639 | Ehrmann High Protein Yogurt Raspberry | Ehrmann | DE | dairy | H | TODO | 2026-04-07 | | |
| 640 | Ehrmann High Protein Drink Vanilla | Ehrmann | DE | protein_drink | H | TODO | 2026-04-07 | | |
| 641 | Zott Protein Pudding Caramel | Zott | DE | dairy | M | TODO | 2026-04-07 | | |
| 642 | Dr. Oetker High Protein Pudding Chocolate | Dr. Oetker | DE | dairy | M | TODO | 2026-04-07 | | |
| 643 | Body Attack Power Protein 90 Chocolate | Body Attack | DE | protein_powder | M | TODO | 2026-04-07 | | |
| 644 | More Nutrition Total Protein Chocolate Brownie | More Nutrition | DE | protein_powder | M | TODO | 2026-04-07 | | German fitness influencer brand |
| 645 | Knoppers Milch-Haselnuss-Schnitte (per piece) | Storck | DE | biscuit | M | TODO | 2026-04-07 | | |
| 646 | Duplo Ferrero (per piece) | Ferrero | DE | chocolate | M | TODO | 2026-04-07 | | |
| 647 | Hanuta Ferrero (per piece) | Ferrero | DE | biscuit | M | TODO | 2026-04-07 | | |
| 648 | Giotto Ferrero (per piece) | Ferrero | DE | confectionery | M | TODO | 2026-04-07 | | |
| 649 | Yogurette (per bar) | Ferrero | DE | chocolate | M | TODO | 2026-04-07 | | |
| 650 | Dickmann's Schoko Strolche (per piece) | Storck | DE | confectionery | M | TODO | 2026-04-07 | | |
| 651 | Maoam Bloxx (per piece) | Haribo | DE | confectionery | L | TODO | 2026-04-07 | | |
| 652 | Katjes Grün-Ohr Bärchen (per 100g) | Katjes | DE | confectionery | M | TODO | 2026-04-07 | | Vegan gummies |
| 653 | Hitschler Hitschies (per 100g) | Hitschler | DE | confectionery | L | TODO | 2026-04-07 | | |
| 654 | Funny Frisch Chipsfrisch Ungarisch (per 100g) | Funny Frisch | DE | snack | M | TODO | 2026-04-07 | | Germany #1 chips |
| 655 | Lorenz Crunchips Paprika (per 100g) | Lorenz | DE | snack | M | TODO | 2026-04-07 | | |
| 656 | XOX Erdnussflips (per 100g) | XOX | DE | snack | M | TODO | 2026-04-07 | | |
| 657 | Zentis Aachener Pflümli (per tbsp) | Zentis | DE | spread | M | TODO | 2026-04-07 | | |
| 658 | Müller Milchreis Klassik (per pot) | Müller | DE | dairy | M | TODO | 2026-04-07 | | |
| 659 | Landliebe Griessbrei (per pot) | Landliebe | DE | dairy | M | TODO | 2026-04-07 | | |
| 660 | Alpro Skyr Style Natur | Alpro | DE | dairy_alt | M | TODO | 2026-04-07 | | |
| 661 | Alpro Protein Soy Drink | Alpro | DE | dairy_alt | M | TODO | 2026-04-07 | | |
| 662 | BiFi Original Salami Stick (per piece) | BiFi | DE | protein_snack | M | TODO | 2026-04-07 | | |
| 663 | BiFi Roll (per piece) | BiFi | DE | protein_snack | M | TODO | 2026-04-07 | | |
| 664 | Maggi 5 Minuten Terrine Nudeln Bolognese | Maggi | DE | instant_noodle | M | TODO | 2026-04-07 | | |
| 665 | Iglo Schlemmer-Filet Bordelaise (per piece) | Iglo | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 666 | Meggle Kräuterbutter (per 10g) | Meggle | DE | dairy | M | TODO | 2026-04-07 | | |
| 667 | Kerrygold Irische Butter (per 10g) | Kerrygold | DE | dairy | M | TODO | 2026-04-07 | | |
| 668 | Spezi Cola-Orange (per 330ml) | Paulaner | DE | beverage | M | TODO | 2026-04-07 | | |
| 669 | Brötchen Semmel (per piece) | Various | DE | bread | M | TODO | 2026-04-07 | | |
| 670 | Laugenbrezel Soft (per piece) | Various | DE | bread | M | TODO | 2026-04-07 | | |

## Section 43: International Fast Food - Unique Menu Items (60 items)

| # | Food Name | Brand | Country | Restaurant | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|------------|----------|----------|--------|------------|----------------|-------|
| 671 | McDonald's McAloo Tikki (India) | McDonald's | IN | McDonald's | fast_food | H | TODO | 2026-04-07 | | India exclusive |
| 672 | McDonald's Chicken Maharaja Mac (India) | McDonald's | IN | McDonald's | fast_food | H | TODO | 2026-04-07 | | |
| 673 | McDonald's McSpicy Paneer (India) | McDonald's | IN | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 674 | McDonald's Teriyaki McBurger (Japan) | McDonald's | JP | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 675 | McDonald's Ebi Filet-O (Japan) | McDonald's | JP | McDonald's | fast_food | M | TODO | 2026-04-07 | | Shrimp burger |
| 676 | McDonald's Samurai Pork Burger (Thailand) | McDonald's | TH | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 677 | McDonald's McFlurry Ovomaltine (Brazil) | McDonald's | BR | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 678 | McDonald's Prosperity Burger (Malaysia) | McDonald's | MY | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 679 | KFC Rice Bowl (Asia) | KFC | ID | KFC | fast_food | M | TODO | 2026-04-07 | | |
| 680 | KFC Chizza (Asia) | KFC | PH | KFC | fast_food | M | TODO | 2026-04-07 | | Chicken as pizza base |
| 681 | Domino's Peppy Paneer Pizza India (per slice) | Domino's | IN | Domino's | fast_food | H | TODO | 2026-04-07 | | India #1 pizza |
| 682 | Domino's Burger Pizza India (per slice) | Domino's | IN | Domino's | fast_food | M | TODO | 2026-04-07 | | |
| 683 | Pizza Hut Birizza (India) | Pizza Hut | IN | Pizza Hut | fast_food | M | TODO | 2026-04-07 | | Biryani pizza |
| 684 | Subway 6-inch Turkey Breast | Subway | US | Subway | fast_food | H | TODO | 2026-04-07 | | |
| 685 | Subway 6-inch Chicken Teriyaki | Subway | US | Subway | fast_food | M | TODO | 2026-04-07 | | |
| 686 | Paris Baguette Egg Tart (per piece) | Paris Baguette | KR | Paris Baguette | bakery | M | TODO | 2026-04-07 | | |
| 687 | Paris Baguette Strawberry Cake (per slice) | Paris Baguette | KR | Paris Baguette | bakery | M | TODO | 2026-04-07 | | |
| 688 | Tous les Jours Cloud Bread (per piece) | Tous les Jours | KR | Tous les Jours | bakery | M | TODO | 2026-04-07 | | |
| 689 | 85°C Sea Salt Coffee (per cup) | 85°C | TW | 85°C | beverage | M | TODO | 2026-04-07 | | |
| 690 | 85°C Brioche (per piece) | 85°C | TW | 85°C | bakery | M | TODO | 2026-04-07 | | |
| 691 | MrBeast Burger Original (per burger) | MrBeast | US | MrBeast Burger | fast_food | H | TODO | 2026-04-07 | | Ghost kitchen |
| 692 | Wingstop Garlic Parmesan Boneless Wings (per 6) | Wingstop | US | Wingstop | fast_food | M | TODO | 2026-04-07 | | |
| 693 | Dave's Hot Chicken Dave's #1 Tender (per piece) | Dave's Hot Chicken | US | Dave's Hot Chicken | fast_food | H | TODO | 2026-04-07 | | Viral chain |
| 694 | Jolibee Palabok Fiesta | Jollibee | PH | Jollibee | fast_food | M | TODO | 2026-04-07 | | |
| 695 | Jolibee Peach Mango Pie (per piece) | Jollibee | PH | Jollibee | fast_food | M | TODO | 2026-04-07 | | |
| 696 | Goldilocks Mocha Roll (per slice) | Goldilocks | PH | Goldilocks | bakery | M | TODO | 2026-04-07 | | Filipino bakery chain |
| 697 | Red Ribbon Dedication Cake Mocha (per slice) | Red Ribbon | PH | Red Ribbon | bakery | M | TODO | 2026-04-07 | | Filipino bakery chain |
| 698 | Chowking Lauriat Meal Soy Chicken | Chowking | PH | Chowking | fast_food | M | TODO | 2026-04-07 | | |
| 699 | Ya Kun Kaya Toast Set (per serving) | Ya Kun | SG | Ya Kun | breakfast | M | TODO | 2026-04-07 | | |
| 700 | Old Chang Kee Curry Puff (per piece) | Old Chang Kee | SG | Old Chang Kee | snack | M | TODO | 2026-04-07 | | |
| 701 | Secret Recipe Chocolate Indulgence Cake (per slice) | Secret Recipe | MY | Secret Recipe | dessert | M | TODO | 2026-04-07 | | |
| 702 | Ramly Burger Original (per burger) | Ramly | MY | Various | fast_food | H | TODO | 2026-04-07 | | Malaysian street food icon |
| 703 | Mamak Roti Canai Telur (per piece) | Various | MY | Various | bread | M | TODO | 2026-04-07 | | |
| 704 | CoCo Fresh Tea & Juice Bubble Milk Tea (per M) | CoCo | TW | CoCo | beverage | H | TODO | 2026-04-07 | | |
| 705 | Saladstop! Protein Power Bowl | Saladstop! | SG | Saladstop! | salad | M | TODO | 2026-04-07 | | |
| 706 | Subway India Aloo Patty Sub (6-inch) | Subway | IN | Subway | fast_food | M | TODO | 2026-04-07 | | |
| 707 | WOK to WALK Chicken Teriyaki Noodles | WOK to WALK | NL | WOK to WALK | fast_food | M | TODO | 2026-04-07 | | |
| 708 | Paul French Bakery Pain au Raisin (per piece) | Paul | FR | Paul | bakery | M | TODO | 2026-04-07 | | |
| 709 | Gail's Bakery Cinnamon Bun (per piece) | Gail's | GB | Gail's | bakery | M | TODO | 2026-04-07 | | |
| 710 | Pret a Manger Protein Power Pot | Pret | GB | Pret a Manger | fast_food | H | TODO | 2026-04-07 | | |
| 711 | Pret a Manger Coconut Chicken Soup | Pret | GB | Pret a Manger | soup | M | TODO | 2026-04-07 | | |
| 712 | Tortilla Chicken Burrito | Tortilla | GB | Tortilla | fast_food | M | TODO | 2026-04-07 | | |
| 713 | Nando's Chicken Butterfly Breast | Nando's | GB | Nando's | fast_food | H | TODO | 2026-04-07 | | Different from ZA |

## Section 44: Indian Specific Brands Not Yet Covered (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 714 | Patanjali Doodh Biscuit | Patanjali | IN | biscuit | M | TODO | 2026-04-07 | | |
| 715 | Patanjali Cow's Ghee (per tsp) | Patanjali | IN | dairy | H | TODO | 2026-04-07 | | |
| 716 | Patanjali Atta Noodles | Patanjali | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 717 | Saffola Oats Masala (per serving) | Saffola | IN | cereal | H | TODO | 2026-04-07 | | |
| 718 | Saffola Muesli Crunchy (per serving) | Saffola | IN | cereal | M | TODO | 2026-04-07 | | |
| 719 | True Elements Steel Cut Oats (per serving) | True Elements | IN | cereal | M | TODO | 2026-04-07 | | |
| 720 | Soulfull Ragi Bites Cocoa (per serving) | Soulfull | IN | cereal | M | TODO | 2026-04-07 | | Millet cereal |
| 721 | Slurrp Farm Millet Dosa Mix (per dosa) | Slurrp Farm | IN | breakfast | M | TODO | 2026-04-07 | | |
| 722 | iD Fresh Idli Batter (per idli) | iD Fresh | IN | breakfast | H | TODO | 2026-04-07 | | Fresh batter brand |
| 723 | iD Fresh Parota (per piece) | iD Fresh | IN | bread | M | TODO | 2026-04-07 | | |
| 724 | Eastern Sambar Powder (per tsp) | Eastern | IN | condiment | M | TODO | 2026-04-07 | | South Indian brand |
| 725 | Aachi Chicken 65 Masala (per tsp) | Aachi | IN | condiment | M | TODO | 2026-04-07 | | |
| 726 | Amul Lassi Rose (per 200ml) | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 727 | Amul Kool Cafe (per 200ml) | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 728 | Amul Tru Seltzer (per can) | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 729 | Nandini Curd (per 100g) | Nandini | IN | dairy | M | TODO | 2026-04-07 | | Karnataka brand |
| 730 | Aavin Milk Full Cream (per 250ml) | Aavin | IN | dairy | M | TODO | 2026-04-07 | | Tamil Nadu brand |
| 731 | Milma Curd (per 100g) | Milma | IN | dairy | M | TODO | 2026-04-07 | | Kerala brand |
| 732 | Keventers Milkshake Chocolate (per bottle) | Keventers | IN | beverage | M | TODO | 2026-04-07 | | |
| 733 | Raw Pressery Cold Pressed OJ (per bottle) | Raw Pressery | IN | beverage | M | TODO | 2026-04-07 | | |
| 734 | Epigamia Protein Shake Chocolate (per bottle) | Epigamia | IN | protein_drink | H | TODO | 2026-04-07 | | |
| 735 | Swiggy Instamart House Brand Paneer (per 100g) | Swiggy | IN | dairy | M | TODO | 2026-04-07 | | |
| 736 | BigBasket Fresho Chicken Breast (per 100g) | BigBasket | IN | protein | M | TODO | 2026-04-07 | | |
| 737 | Licious Chicken Breast Boneless (per 100g) | Licious | IN | protein | H | TODO | 2026-04-07 | | India meat delivery |
| 738 | FreshToHome Fish Seer Fish Fillet (per 100g) | FreshToHome | IN | protein | M | TODO | 2026-04-07 | | |
| 739 | ITC Aashirvaad Atta Pizza Base (per base) | ITC | IN | bread | M | TODO | 2026-04-07 | | |
| 740 | ITC Sunfeast YiPPee Power Up Atta Noodles | ITC | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 741 | Snickers India (per bar) | Snickers | IN | chocolate | M | TODO | 2026-04-07 | | |
| 742 | Munch Chocolate (per bar) | Nestle | IN | chocolate | M | TODO | 2026-04-07 | | India exclusive |
| 743 | KitKat India (per 2 finger) | Nestle | IN | chocolate | M | TODO | 2026-04-07 | | |
| 744 | Gems Cadbury (per small pack) | Cadbury | IN | confectionery | L | TODO | 2026-04-07 | | |
| 745 | Pulse Candy (per piece) | DS Group | IN | confectionery | L | TODO | 2026-04-07 | | India's #1 candy |
| 746 | Swad Mixed Mukhwas (per tsp) | Swad | IN | confectionery | L | TODO | 2026-04-07 | | |
| 747 | Crax Corn Ring Masala | DFM Foods | IN | snack | M | TODO | 2026-04-07 | | |
| 748 | Pepsi Max (India per can) | Pepsi | IN | beverage | M | TODO | 2026-04-07 | | |
| 749 | Coca-Cola Zero (India per can) | Coca-Cola | IN | beverage | M | TODO | 2026-04-07 | | |
| 750 | Dawat-E-Khaas Sheermal (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | Mughlai bread |
| 751 | Haldiram's Minute Khana Poha (per serving) | Haldiram's | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 752 | MTR Masala Upma (per serving) | MTR | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 753 | K.C. Das Rosogolla (per piece) | K.C. Das | IN | dessert | M | TODO | 2026-04-07 | | Bengal iconic |
| 754 | Naturals Ice Cream Tender Coconut (per scoop) | Naturals | IN | dessert | M | TODO | 2026-04-07 | | |
| 755 | Baskin Robbins India Mississippi Mud (per scoop) | Baskin Robbins | IN | dessert | M | TODO | 2026-04-07 | | |
| 756 | Havmor Cornetto Disc (per piece) | Havmor | IN | dessert | M | TODO | 2026-04-07 | | Gujarat brand |
| 757 | Kwality Walls Feast Chocolate (per bar) | Kwality Walls | IN | dessert | M | TODO | 2026-04-07 | | |
| 758 | Wagh Bakri Instant Masala Tea (per sachet) | Wagh Bakri | IN | beverage | M | TODO | 2026-04-07 | | |
| 759 | Third Wave Coffee Flat White (per cup) | Third Wave | IN | beverage | M | TODO | 2026-04-07 | | |
| 760 | OZiva Clean Protein Bars Crunchy Peanut | OZiva | IN | protein_bar | M | TODO | 2026-04-07 | | |
| 761 | Raw Protein Whey Isolate Chocolate | Raw | IN | protein_powder | M | TODO | 2026-04-07 | | |
| 762 | Wow! Momo Chicken Momo Steamed (per 6 pieces) | Wow! Momo | IN | snack | H | TODO | 2026-04-07 | | India momo chain |
| 763 | Faasos Wrap Chicken Tikka | Faasos | IN | fast_food | M | TODO | 2026-04-07 | | Delivery brand |
| 764 | Behrouz Biryani Dum Gosht (per serving) | Behrouz | IN | fast_food | M | TODO | 2026-04-07 | | Cloud kitchen |

## Section 45: Japanese & Korean Specific Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 765 | Lawson Karaage-kun Regular (per pack) | Lawson | JP | snack | H | TODO | 2026-04-07 | | Konbini icon |
| 766 | FamilyMart Famichiki (per piece) | FamilyMart | JP | snack | H | TODO | 2026-04-07 | | Japan konbini fried chicken |
| 767 | 7-Eleven Japan Salad Chicken Breast (per pack) | 7-Eleven | JP | protein | H | TODO | 2026-04-07 | | Fitness staple Japan |
| 768 | Yamazaki Lunch Pack Tamago (per pack) | Yamazaki | JP | bread | M | TODO | 2026-04-07 | | |
| 769 | Pasco Shikisai Bread (per piece) | Pasco | JP | bread | M | TODO | 2026-04-07 | | |
| 770 | Yakult 1000 (per bottle) | Yakult | JP | beverage | H | TODO | 2026-04-07 | | Premium version |
| 771 | Glico Pretz Salad (per box) | Glico | JP | snack | M | TODO | 2026-04-07 | | |
| 772 | Calbee Jaga Pokkuru (per bag) | Calbee | JP | snack | M | TODO | 2026-04-07 | | Hokkaido exclusive |
| 773 | Morinaga Caramel (per piece) | Morinaga | JP | confectionery | M | TODO | 2026-04-07 | | |
| 774 | Fujiya Milky Candy (per piece) | Fujiya | JP | confectionery | M | TODO | 2026-04-07 | | |
| 775 | Bourbon Petit Series Chocolate Chip (per pack) | Bourbon | JP | biscuit | M | TODO | 2026-04-07 | | |
| 776 | Tohato Caramel Corn (per 100g) | Tohato | JP | snack | M | TODO | 2026-04-07 | | |
| 777 | Kameda Kaki no Tane Rice Crackers (per 100g) | Kameda | JP | snack | M | TODO | 2026-04-07 | | |
| 778 | Morinaga in Jelly Protein (per pouch) | Morinaga | JP | protein_drink | H | TODO | 2026-04-07 | | Jelly protein drink |
| 779 | Weider in Jelly Energy (per pouch) | Weider Japan | JP | supplement | M | TODO | 2026-04-07 | | |
| 780 | CalorieMate Block Cheese (per block) | Otsuka | JP | meal_replacement | M | TODO | 2026-04-07 | | |
| 781 | CalorieMate Block Chocolate (per block) | Otsuka | JP | meal_replacement | M | TODO | 2026-04-07 | | |
| 782 | SAVAS Whey Protein Cocoa (per scoop) | Meiji | JP | protein_powder | H | TODO | 2026-04-07 | | Japan #1 protein |
| 783 | DNS Protein Whey 100 Chocolate (per scoop) | DNS | JP | protein_powder | M | TODO | 2026-04-07 | | |
| 784 | Asahi Dear Natura Multivitamin (per tablet) | Asahi | JP | supplement | L | TODO | 2026-04-07 | | |
| 785 | Kirin Afternoon Tea Milk Tea (per 500ml) | Kirin | JP | beverage | M | TODO | 2026-04-07 | | |
| 786 | Asahi Mitsuya Cider (per can) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | Japan iconic soda |
| 787 | Calpico Soda (per can) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | |
| 788 | Sapporo Ichiban Miso Ramen | Sapporo Ichiban | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 789 | Cup Noodle Curry (Japan) | Nissin | JP | instant_noodle | M | TODO | 2026-04-07 | | Different from US |
| 790 | Peyoung Yakisoba (per pack) | Maruka | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 791 | CU Convenience Store Triangle Kimbap (per piece) | CU | KR | snack | H | TODO | 2026-04-07 | | Korean konbini |
| 792 | GS25 Chicken Breast Salad | GS25 | KR | protein | H | TODO | 2026-04-07 | | Korean konbini |
| 793 | Emart24 Protein Drink (per bottle) | Emart24 | KR | protein_drink | M | TODO | 2026-04-07 | | |
| 794 | Pulmuone Tofu Extra Firm (per 100g) | Pulmuone | KR | protein | M | TODO | 2026-04-07 | | |
| 795 | CJ CheilJedang Hetbahn Rice (per pack) | CJ | KR | staple | M | TODO | 2026-04-07 | | Instant rice |
| 796 | Dongwon Tuna Can (per can) | Dongwon | KR | protein | M | TODO | 2026-04-07 | | Korea #1 tuna |
| 797 | Beksul Frying Mix (per serving) | CJ | KR | staple | L | TODO | 2026-04-07 | | |
| 798 | Crown Choco Heim (per piece) | Crown | KR | biscuit | M | TODO | 2026-04-07 | | |
| 799 | Lotte Mon Cher Cream Cake (per piece) | Lotte | KR | biscuit | M | TODO | 2026-04-07 | | |
| 800 | Haitai Ace Crackers (per serving) | Haitai | KR | biscuit | M | TODO | 2026-04-07 | | |
| 801 | Maxim Original Mix Coffee (per stick) | Dongsuh | KR | beverage | M | TODO | 2026-04-07 | | Korea #1 instant coffee |
| 802 | Starbucks Korea RTD Latte (per can) | Starbucks | KR | beverage | M | TODO | 2026-04-07 | | |
| 803 | Yakult Korea Light (per bottle) | Yakult | KR | beverage | M | TODO | 2026-04-07 | | |
| 804 | Muscle King Protein Drink (per bottle) | Muscle King | KR | protein_drink | M | TODO | 2026-04-07 | | |
| 805 | hy Protein Yogurt (per 100g) | hy | KR | dairy | M | TODO | 2026-04-07 | | Korean dairy brand |
| 806 | Seoul Milk Low Fat (per 200ml) | Seoul Milk | KR | dairy | M | TODO | 2026-04-07 | | |
| 807 | Nongshim Veggie Garden Chips | Nongshim | KR | snack | M | TODO | 2026-04-07 | | |
| 808 | Ottogi Real Cheese Ramen | Ottogi | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 809 | Paldo Kokomen Spicy Chicken | Paldo | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 810 | Samyang Carbo Buldak Ramen | Samyang | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 811 | Three Squirrels Mixed Nuts (per 30g) | Three Squirrels | CN | snack | M | TODO | 2026-04-07 | | China #1 snack brand |
| 812 | Nongfu Spring Water (per 500ml) | Nongfu | CN | beverage | L | TODO | 2026-04-07 | | China #1 water |
| 813 | Genki Forest Milk Tea Original (per bottle) | Genki Forest | CN | beverage | M | TODO | 2026-04-07 | | |
| 814 | Wahaha AD Calcium Milk (per bottle) | Wahaha | CN | beverage | M | TODO | 2026-04-07 | | Chinese childhood drink |

## Section 46: Southeast Asian Specific Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 815 | Pocky Cookies & Cream (Thailand) | Glico | TH | confectionery | M | TODO | 2026-04-07 | | |
| 816 | Pretz Larb (Thailand) | Glico | TH | snack | M | TODO | 2026-04-07 | | Thai exclusive flavor |
| 817 | Lay's Nori Seaweed (Thailand) | Lay's | TH | snack | M | TODO | 2026-04-07 | | |
| 818 | Mama Pad Kee Mao (Drunken Noodle) | Mama | TH | instant_noodle | M | TODO | 2026-04-07 | | |
| 819 | Mama Green Curry | Mama | TH | instant_noodle | M | TODO | 2026-04-07 | | |
| 820 | Singha Soda Water (per can) | Singha | TH | beverage | L | TODO | 2026-04-07 | | |
| 821 | Thai Tea Number One Brand Powder (per serving) | Cha Tra Mue | TH | beverage | M | TODO | 2026-04-07 | | |
| 822 | Silverqueen Chocolate Cashew (per bar) | Silverqueen | ID | chocolate | M | TODO | 2026-04-07 | | Indonesian icon |
| 823 | Tango Wafer Chocolate (per piece) | Tango | ID | biscuit | M | TODO | 2026-04-07 | | |
| 824 | Good Day Cappuccino Coffee (per bottle) | Good Day | ID | beverage | M | TODO | 2026-04-07 | | |
| 825 | Teh Pucuk Harum Jasmine Tea (per bottle) | Mayora | ID | beverage | M | TODO | 2026-04-07 | | Indonesia #1 tea |
| 826 | Pocari Sweat Indonesia (per bottle) | Otsuka | ID | sports_drink | M | TODO | 2026-04-07 | | |
| 827 | Chitato Original (per 100g) | Indofood | ID | snack | M | TODO | 2026-04-07 | | |
| 828 | Lays Salmon Teriyaki (Indonesia) | Lay's | ID | snack | M | TODO | 2026-04-07 | | |
| 829 | Indomie Hype Abang Adek (per pack) | Indomie | ID | instant_noodle | M | TODO | 2026-04-07 | | Viral Indonesian |
| 830 | Sedaap Mie Goreng (per pack) | Wings | ID | instant_noodle | M | TODO | 2026-04-07 | | |
| 831 | Pop Mie Ayam Bawang Cup | Indofood | ID | instant_noodle | M | TODO | 2026-04-07 | | |
| 832 | Kecap Bango Sweet Soy (per tbsp) | Unilever | ID | condiment | M | TODO | 2026-04-07 | | |
| 833 | Bumbu Racik Nasi Goreng (per sachet) | Indofood | ID | condiment | L | TODO | 2026-04-07 | | |
| 834 | Ultra Milk Full Cream (per 250ml) | Ultra Jaya | ID | dairy | M | TODO | 2026-04-07 | | |
| 835 | Bear Brand Sterilized Milk (per can) | Nestle | ID | dairy | M | TODO | 2026-04-07 | | Popular health drink |
| 836 | Lucky Me Hot Chili Beef | Lucky Me | PH | instant_noodle | M | TODO | 2026-04-07 | | |
| 837 | Zesto Juice Orange (per pack) | Zesto | PH | beverage | M | TODO | 2026-04-07 | | |
| 838 | Piattos Cheese (per 100g) | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 839 | V-Cut BBQ Chips (per 100g) | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 840 | Maggi Mee Goreng (Malaysia) | Maggi | MY | instant_noodle | H | TODO | 2026-04-07 | | Malaysia variant |
| 841 | Cintan Mi Goreng Asli | Cintan | MY | instant_noodle | M | TODO | 2026-04-07 | | |
| 842 | Dutch Lady Milk Full Cream (per 200ml) | Dutch Lady | MY | dairy | M | TODO | 2026-04-07 | | |
| 843 | F&N Orange (per can) | F&N | MY | beverage | M | TODO | 2026-04-07 | | |
| 844 | Mister Potato Crisps Original (per 100g) | Mister Potato | MY | snack | M | TODO | 2026-04-07 | | |
| 845 | MYPROTEIN Malaysia Chicken Breast Strips (per 100g) | MyProtein | MY | protein | M | TODO | 2026-04-07 | | |
| 846 | Ayam Brand Sardines in Tomato Sauce (per can) | Ayam Brand | SG | protein | M | TODO | 2026-04-07 | | |
| 847 | Yeo's Chrysanthemum Tea (per pack) | Yeo's | SG | beverage | M | TODO | 2026-04-07 | | |
| 848 | Myojo Dry Mee Pok (per serving) | Myojo | SG | instant_noodle | M | TODO | 2026-04-07 | | |
| 849 | Prima Taste Singapore Chili Crab La Mian | Prima Taste | SG | instant_noodle | M | TODO | 2026-04-07 | | Premium |
| 850 | Pho Hai Phong Instant Rice Noodle | Vifon | VN | instant_noodle | M | TODO | 2026-04-07 | | |
| 851 | Hao Hao Tom Chua Cay (per pack) | Acecook | VN | instant_noodle | H | TODO | 2026-04-07 | | Vietnam #1 instant noodle |
| 852 | Vinamilk Fresh Milk (per 200ml) | Vinamilk | VN | dairy | M | TODO | 2026-04-07 | | Vietnam #1 dairy |
| 853 | TH True Milk (per 200ml) | TH Group | VN | dairy | M | TODO | 2026-04-07 | | |

## Section 47: Middle East & Turkey Specific Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 854 | Pinar Labne (per 100g) | Pinar | TR | dairy | H | TODO | 2026-04-07 | | Turkish dairy giant |
| 855 | Pinar Beyaz Peynir Feta (per 30g) | Pinar | TR | dairy | M | TODO | 2026-04-07 | | |
| 856 | Ülker Çikolatalı Gofret Wafer (per piece) | Ülker | TR | biscuit | M | TODO | 2026-04-07 | | |
| 857 | Ülker Dido Chocolate Bar | Ülker | TR | chocolate | M | TODO | 2026-04-07 | | |
| 858 | Eti Browni Intense Chocolate Cake | Eti | TR | dessert | M | TODO | 2026-04-07 | | |
| 859 | Eti Burçak Digestive Biscuit | Eti | TR | biscuit | M | TODO | 2026-04-07 | | |
| 860 | Torku Banada Chocolate Spread (per tbsp) | Torku | TR | spread | M | TODO | 2026-04-07 | | Turkish Nutella rival |
| 861 | Dimes Fruit Juice Orange (per 200ml) | Dimes | TR | beverage | M | TODO | 2026-04-07 | | |
| 862 | Uludağ Gazoz (per 330ml) | Uludağ | TR | beverage | M | TODO | 2026-04-07 | | Turkish iconic soda |
| 863 | Turkish Airlines Meal Economy Chicken (per serving) | THY | TR | ready_meal | M | TODO | 2026-04-07 | | |
| 864 | Sütaş Ayran (per 200ml) | Sütaş | TR | beverage | H | TODO | 2026-04-07 | | |
| 865 | Sütaş Kaşar Cheese (per 30g) | Sütaş | TR | dairy | M | TODO | 2026-04-07 | | |
| 866 | Nescafe 3in1 (Turkey per sachet) | Nescafe | TR | beverage | M | TODO | 2026-04-07 | | |
| 867 | Almarai Protein Milk Drink Chocolate | Almarai | SA | protein_drink | H | TODO | 2026-04-07 | | |
| 868 | Almarai Croissant Zaatar (per piece) | Almarai | SA | bread | M | TODO | 2026-04-07 | | |
| 869 | Al Rabie Juice Mango (per 200ml) | Al Rabie | SA | beverage | M | TODO | 2026-04-07 | | |
| 870 | SADAFCO Saudia UHT Milk (per 200ml) | SADAFCO | SA | dairy | M | TODO | 2026-04-07 | | |
| 871 | Al Marai Date Khalas (per 3 pieces) | Almarai | SA | confectionery | M | TODO | 2026-04-07 | | |
| 872 | Al Ain Water (per 500ml) | Al Ain | AE | beverage | L | TODO | 2026-04-07 | | |
| 873 | Rani Float Mango (per can) | Aujan | AE | beverage | M | TODO | 2026-04-07 | | Middle East icon |
| 874 | Tang Orange Powder (per serving) | Tang | AE | beverage | M | TODO | 2026-04-07 | | Huge in ME |
| 875 | Indomie Special Chicken (Middle East variant) | Indomie | AE | instant_noodle | M | TODO | 2026-04-07 | | |
| 876 | Al Fakher Maamoul (per piece) | Al Fakher | AE | biscuit | M | TODO | 2026-04-07 | | |
| 877 | Kiri Cheese Spread (per portion) | Kiri | FR | dairy | M | TODO | 2026-04-07 | | Huge in ME |
| 878 | La Vache qui Rit Cheese Wedge (per piece) | La Vache qui Rit | FR | dairy | M | TODO | 2026-04-07 | | Laughing Cow |
| 879 | Puck Labneh (per tbsp) | Puck | DK | dairy | M | TODO | 2026-04-07 | | Popular in Gulf |
| 880 | Juhayna Milk Full Fat (per 200ml) | Juhayna | EG | dairy | M | TODO | 2026-04-07 | | Egypt #1 dairy |
| 881 | Chipsy Cheese (per 100g) | Chipsy | EG | snack | M | TODO | 2026-04-07 | | Egypt's Lay's |
| 882 | Fayrouz Pineapple (per can) | Heineken | EG | beverage | M | TODO | 2026-04-07 | | Non-alcoholic malt |
| 883 | Birell Non-Alcoholic Malt (per can) | Heineken | EG | beverage | M | TODO | 2026-04-07 | | |
| 884 | Bonjus Mango Juice (per 200ml) | Bonjus | LB | beverage | M | TODO | 2026-04-07 | | |
| 885 | Cortas Rose Water (per tsp) | Cortas | LB | condiment | L | TODO | 2026-04-07 | | |
| 886 | Gardenia Tahini (per tbsp) | Gardenia | LB | spread | M | TODO | 2026-04-07 | | |
| 887 | Chtaura Valley Arak (per shot) | Chtaura | LB | beverage | L | TODO | 2026-04-07 | | |
| 888 | Sana Helwe Sweet Cheese (per 30g) | Various | LB | dairy | M | TODO | 2026-04-07 | | |
| 889 | Ful Medames Canned (per serving) | Various | EG | staple | M | TODO | 2026-04-07 | | Egyptian breakfast |
| 890 | Jachnun Yemenite Bread (per piece) | Various | IL | bread | M | TODO | 2026-04-07 | | |

## Section 48: European Brands & Products (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 891 | Migros M-Classic Birchermüesli (per serving) | Migros | CH | cereal | M | TODO | 2026-04-07 | | Swiss supermarket |
| 892 | Migros Protein Yogurt Nature | Migros | CH | dairy | M | TODO | 2026-04-07 | | |
| 893 | Emmi Caffè Latte (per bottle) | Emmi | CH | beverage | M | TODO | 2026-04-07 | | |
| 894 | Rivella Original (per 330ml) | Rivella | CH | beverage | M | TODO | 2026-04-07 | | Swiss national drink |
| 895 | Cailler Chocolate Milk Bar | Cailler | CH | chocolate | M | TODO | 2026-04-07 | | Swiss premium |
| 896 | Manner Neapolitaner Wafer (per piece) | Manner | AT | biscuit | M | TODO | 2026-04-07 | | Austrian icon |
| 897 | Almdudler Alpine Herb Soda (per 330ml) | Almdudler | AT | beverage | M | TODO | 2026-04-07 | | Austrian national soda |
| 898 | Carrefour Bio Granola Chocolat | Carrefour | FR | cereal | M | TODO | 2026-04-07 | | |
| 899 | Michel et Augustin Petits Cookies | Michel et Augustin | FR | biscuit | M | TODO | 2026-04-07 | | |
| 900 | St Michel Madeleines (per piece) | St Michel | FR | biscuit | M | TODO | 2026-04-07 | | French classic |
| 901 | La Laitière Crème Brûlée (per pot) | Nestlé | FR | dessert | M | TODO | 2026-04-07 | | |
| 902 | Yop Yoplait Strawberry Drink (per bottle) | Yoplait | FR | dairy | M | TODO | 2026-04-07 | | |
| 903 | Albert Heijn Protein Yogurt Naturel | Albert Heijn | NL | dairy | M | TODO | 2026-04-07 | | |
| 904 | Albert Heijn Pindakaas Peanut Butter | Albert Heijn | NL | spread | M | TODO | 2026-04-07 | | Dutch PB staple |
| 905 | Chocomel Chocolate Milk (per 250ml) | Chocomel | NL | beverage | M | TODO | 2026-04-07 | | Dutch icon |
| 906 | Vla Vanilla Custard (per 100ml) | Various | NL | dairy | M | TODO | 2026-04-07 | | Dutch staple |
| 907 | Drop Dutch Licorice (per 100g) | Various | NL | confectionery | M | TODO | 2026-04-07 | | |
| 908 | Fazer Blue Chocolate (per 100g) | Fazer | FI | chocolate | M | TODO | 2026-04-07 | | Finnish icon |
| 909 | Fazer Tyrkisk Peber (per 100g) | Fazer | FI | confectionery | M | TODO | 2026-04-07 | | |
| 910 | Fazer Oat Snack Cocoa | Fazer | FI | snack | M | TODO | 2026-04-07 | | |
| 911 | Kalev Chocolate Tallinn (per 100g) | Kalev | EE | chocolate | M | TODO | 2026-04-07 | | Estonian icon |
| 912 | Laima Riga Black Balsam Chocolate (per 100g) | Laima | LV | chocolate | M | TODO | 2026-04-07 | | Latvian |
| 913 | Kvass Latvijas Balzams (per 330ml) | Latvijas Balzams | LV | beverage | L | TODO | 2026-04-07 | | |
| 914 | ICA Protein Yogurt Natural | ICA | SE | dairy | M | TODO | 2026-04-07 | | Swedish supermarket |
| 915 | Kalles Kaviar Cod Roe Spread (per tbsp) | Kalles | SE | spread | M | TODO | 2026-04-07 | | Swedish icon |
| 916 | Daim Bar (per piece) | Marabou | SE | chocolate | M | TODO | 2026-04-07 | | |
| 917 | Bilar Swedish Car Gummies (per 100g) | Malaco | SE | confectionery | M | TODO | 2026-04-07 | | Swedish icon |
| 918 | Japp Chocolate Bar (per piece) | Marabou | SE | chocolate | M | TODO | 2026-04-07 | | |
| 919 | Smash Snack (per bag) | Nidar | NO | snack | M | TODO | 2026-04-07 | | |
| 920 | Mercadona Hacendado Tortilla Española (per serving) | Hacendado | ES | ready_meal | M | TODO | 2026-04-07 | | Spanish supermarket |
| 921 | Cola Cao Chocolate Drink (per serving) | Cola Cao | ES | beverage | M | TODO | 2026-04-07 | | Spanish icon |
| 922 | Goya Maria Cookies | Goya | ES | biscuit | M | TODO | 2026-04-07 | | |
| 923 | Mulino Bianco Barilla Biscuits Pan di Stelle (per piece) | Mulino Bianco | IT | biscuit | M | TODO | 2026-04-07 | | Italian breakfast icon |
| 924 | Mulino Bianco Macine (per piece) | Mulino Bianco | IT | biscuit | M | TODO | 2026-04-07 | | |
| 925 | Barilla Pasta Spaghetti No.5 (per 100g dry) | Barilla | IT | staple | M | TODO | 2026-04-07 | | |
| 926 | De Cecco Rigatoni (per 100g dry) | De Cecco | IT | staple | M | TODO | 2026-04-07 | | |
| 927 | Buitoni Fresh Tortellini Ricotta (per serving) | Buitoni | IT | pasta | M | TODO | 2026-04-07 | | |
| 928 | Peroni Nastro Azzurro Beer (per 330ml) | Peroni | IT | beverage | L | TODO | 2026-04-07 | | |
| 929 | San Benedetto Iced Tea Peach (per 500ml) | San Benedetto | IT | beverage | M | TODO | 2026-04-07 | | |
| 930 | Loacker Quadratini Napolitaner (per 100g) | Loacker | IT | biscuit | M | TODO | 2026-04-07 | | |
| 931 | Leibniz Pick Up Choco (per piece) | Bahlsen | DE | biscuit | M | TODO | 2026-04-07 | | |
| 932 | Prince Polo Classic (per bar) | Olza | PL | chocolate | M | TODO | 2026-04-07 | | Polish icon |
| 933 | Wedel Ptasie Mleczko (per piece) | Wedel | PL | confectionery | M | TODO | 2026-04-07 | | Polish classic |
| 934 | Żywiec Beer (per 500ml) | Żywiec | PL | beverage | L | TODO | 2026-04-07 | | |

## Section 49: Latin American Specific Brands (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 935 | Bauducco Toast Wheat (per piece) | Bauducco | BR | bread | M | TODO | 2026-04-07 | | Brazil biscuit giant |
| 936 | Bauducco Wafer Chocolate (per piece) | Bauducco | BR | biscuit | M | TODO | 2026-04-07 | | |
| 937 | Toddy Chocolate Powder (per serving) | PepsiCo | BR | beverage | M | TODO | 2026-04-07 | | |
| 938 | Nescau Chocolate Powder (per serving) | Nestle | BR | beverage | M | TODO | 2026-04-07 | | Brazil's Nesquik |
| 939 | Havanna Dulce de Leche (per tbsp) | Havanna | AR | spread | M | TODO | 2026-04-07 | | |
| 940 | La Serenísima Leche Entera (per 200ml) | La Serenísima | AR | dairy | M | TODO | 2026-04-07 | | Argentine #1 dairy |
| 941 | Manaos Cola (per 330ml) | Manaos | AR | beverage | L | TODO | 2026-04-07 | | |
| 942 | Quilmes Beer (per 330ml) | Quilmes | AR | beverage | L | TODO | 2026-04-07 | | Argentine icon |
| 943 | Bon o Bon Chocolate (per piece) | Arcor | AR | confectionery | M | TODO | 2026-04-07 | | |
| 944 | Mantecol Peanut Nougat (per 30g) | Mondelez | AR | confectionery | M | TODO | 2026-04-07 | | |
| 945 | Gamesa Maria Cookies (per serving) | Gamesa | MX | biscuit | M | TODO | 2026-04-07 | | |
| 946 | Bimbo Conchas Pan Dulce (per piece) | Bimbo | MX | bread | M | TODO | 2026-04-07 | | Mexican bakery icon |
| 947 | Maruchan Instant Lunch Habanero Lime (Mexico) | Maruchan | MX | instant_noodle | M | TODO | 2026-04-07 | | |
| 948 | Sabritas Original (per 100g) | Sabritas | MX | snack | M | TODO | 2026-04-07 | | |
| 949 | Totis Chips (per 100g) | Totis | MX | snack | L | TODO | 2026-04-07 | | |
| 950 | Peñafiel Mineral Water Lime (per 600ml) | Peñafiel | MX | beverage | L | TODO | 2026-04-07 | | |
| 951 | Boing Mango Juice (per 500ml) | Pascual | MX | beverage | M | TODO | 2026-04-07 | | |
| 952 | Inca Kola Zero (per can) | Coca-Cola | PE | beverage | M | TODO | 2026-04-07 | | |
| 953 | Club Colombia Beer (per 330ml) | Bavaria | CO | beverage | L | TODO | 2026-04-07 | | |
| 954 | Bocadillo Veleño Guava Paste (per piece) | Various | CO | confectionery | M | TODO | 2026-04-07 | | |
| 955 | Pilsener Beer Ecuador (per 330ml) | SABMiller | EC | beverage | L | TODO | 2026-04-07 | | |
| 956 | Ceviche Peruano (per serving) | Various | PE | protein | H | TODO | 2026-04-07 | | |
| 957 | Causa Limeña (per serving) | Various | PE | snack | M | TODO | 2026-04-07 | | |
| 958 | Francesinha Porto Sandwich (per serving) | Various | PT | fast_food | M | TODO | 2026-04-07 | | |
| 959 | Compal Juice Orange (per 200ml) | Compal | PT | beverage | M | TODO | 2026-04-07 | | Portuguese icon |
| 960 | Delta Café Espresso (per shot) | Delta | PT | beverage | M | TODO | 2026-04-07 | | Portugal #1 coffee |
| 961 | Cachitos Venezuelan Bread (per piece) | Various | VE | bread | M | TODO | 2026-04-07 | | |
| 962 | Salteña Bolivian Empanada (per piece) | Various | BO | snack | M | TODO | 2026-04-07 | | |
| 963 | Gallo Pinto Costa Rican Rice & Beans (per serving) | Various | CR | staple | M | TODO | 2026-04-07 | | |
| 964 | Casado Costa Rican Plate (per serving) | Various | CR | protein | M | TODO | 2026-04-07 | | |

## Section 50: African Brands & Foods (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 965 | Shoprite No Name Brand Maize Meal (per 100g) | Shoprite | ZA | staple | M | TODO | 2026-04-07 | | SA supermarket |
| 966 | Rhodes Fruit Juice Orange (per 200ml) | Rhodes | ZA | beverage | M | TODO | 2026-04-07 | | |
| 967 | Clover Full Cream Milk (per 250ml) | Clover | ZA | dairy | M | TODO | 2026-04-07 | | |
| 968 | Woolworths SA Roasted Chicken Breast (per 100g) | Woolworths SA | ZA | protein | M | TODO | 2026-04-07 | | |
| 969 | Steers Wacky Wednesday Burger | Steers | ZA | fast_food | M | TODO | 2026-04-07 | | SA fast food chain |
| 970 | Spur Ribs (per serving) | Spur | ZA | fast_food | M | TODO | 2026-04-07 | | |
| 971 | Indomie Onion Chicken (Nigeria variant) | Indomie | NG | instant_noodle | M | TODO | 2026-04-07 | | |
| 972 | Dangote Semovita (per 100g) | Dangote | NG | staple | M | TODO | 2026-04-07 | | |
| 973 | Peak Milk Powder (per serving) | Peak | NG | dairy | M | TODO | 2026-04-07 | | |
| 974 | Malt Guinness (per 330ml bottle) | Guinness | NG | beverage | M | TODO | 2026-04-07 | | |
| 975 | Suya Chicken (per stick) | Various | NG | protein | H | TODO | 2026-04-07 | | |
| 976 | Amala with Ewedu (per serving) | Various | NG | staple | M | TODO | 2026-04-07 | | |
| 977 | Brookside Dairy Milk (per 250ml) | Brookside | KE | dairy | M | TODO | 2026-04-07 | | Kenya brand |
| 978 | Githeri (Corn & Beans per serving) | Various | KE | staple | M | TODO | 2026-04-07 | | |
| 979 | Mandazi East African Donut (per piece) | Various | KE | bread | M | TODO | 2026-04-07 | | |
| 980 | Chapati East African (per piece) | Various | KE | bread | M | TODO | 2026-04-07 | | |
| 981 | Samosa East African (per piece) | Various | KE | snack | M | TODO | 2026-04-07 | | |
| 982 | Bunna Ethiopian Coffee (per cup) | Various | ET | beverage | M | TODO | 2026-04-07 | | |
| 983 | Fufu West African (per serving) | Various | GH | staple | M | TODO | 2026-04-07 | | |
| 984 | Melktert Milk Tart (per slice) | Various | ZA | dessert | M | TODO | 2026-04-07 | | |
| 985 | Piri Piri Chicken Mozambique (per piece) | Various | MZ | protein | M | TODO | 2026-04-07 | | |
| 986 | Brochette Rwandan Grilled Meat (per stick) | Various | RW | protein | M | TODO | 2026-04-07 | | |
| 987 | Rolex Uganda Egg Chapati Roll (per piece) | Various | UG | fast_food | M | TODO | 2026-04-07 | | |

## Section 51: More Fitness & Health Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 988 | Grenade Protein Shake Chocolate (RTD) | Grenade | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 989 | PhD Smart Bar Plant Choc Peanut Caramel | PhD Nutrition | GB | protein_bar | M | TODO | 2026-04-07 | | |
| 990 | Myprotein Clear Whey Isolate Mojito | MyProtein | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 991 | Myprotein Protein Pancake Mix (per serving) | MyProtein | GB | breakfast | H | TODO | 2026-04-07 | | |
| 992 | Myprotein Peanut Butter Powder (per serving) | MyProtein | GB | spread | M | TODO | 2026-04-07 | | |
| 993 | Applied Nutrition Critical Mass Gainer (per serving) | Applied Nutrition | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 994 | USN Blue Lab 100% Whey Chocolate | USN | ZA | protein_powder | M | TODO | 2026-04-07 | | South African brand |
| 995 | NPL Platinum Whey Chocolate | NPL | ZA | protein_powder | M | TODO | 2026-04-07 | | |
| 996 | SSA Supplements Whey Pro Vanilla | SSA | ZA | protein_powder | M | TODO | 2026-04-07 | | |
| 997 | Rule 1 Protein Chocolate Fudge (per scoop) | Rule 1 | US | protein_powder | M | TODO | 2026-04-07 | | |
| 998 | Redcon1 MRE Bar Blueberry Cobbler | Redcon1 | US | protein_bar | M | TODO | 2026-04-07 | | |
| 999 | Redcon1 MRE Meal Replacement (per serving) | Redcon1 | US | meal_replacement | M | TODO | 2026-04-07 | | |
| 1000 | JYM Pro JYM Protein Powder Chocolate (per scoop) | JYM | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1001 | Kaged Muscle Pre-Kaged Elite (per serving) | Kaged | US | supplement | M | TODO | 2026-04-07 | | |
| 1002 | Bucked Up Pre-Workout Woke AF (per serving) | Bucked Up | US | supplement | M | TODO | 2026-04-07 | | |
| 1003 | Bloom Nutrition Greens & Superfoods Berry (per serving) | Bloom | US | supplement | H | TODO | 2026-04-07 | | TikTok viral |
| 1004 | Alani Nu Balance Capsules (per serving) | Alani Nu | US | supplement | M | TODO | 2026-04-07 | | |
| 1005 | Liquid I.V. Hydration Multiplier Lemon Lime (per stick) | Liquid I.V. | US | supplement | M | TODO | 2026-04-07 | | |
| 1006 | LMNT Electrolyte Mix Citrus Salt (per stick) | LMNT | US | supplement | H | TODO | 2026-04-07 | | Keto popular |
| 1007 | Nuun Sport Lemon Lime (per tablet) | Nuun | US | supplement | M | TODO | 2026-04-07 | | |
| 1008 | Nutrabolt Xtend Original BCAA Mango (per serving) | Nutrabolt | US | supplement | M | TODO | 2026-04-07 | | |
| 1009 | MuscleTech Nitro-Tech Whey Gold Chocolate (per scoop) | MuscleTech | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1010 | BSN Syntha-6 Chocolate Milkshake (per scoop) | BSN | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1011 | Cellucor Whey Sport Chocolate (per scoop) | Cellucor | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1012 | Naked Whey Protein Unflavored (per scoop) | Naked Nutrition | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1013 | Vega Sport Protein Chocolate (per scoop) | Vega | US | protein_powder | M | TODO | 2026-04-07 | | Plant-based |
| 1014 | Garden of Life Raw Organic Protein Chocolate (per scoop) | Garden of Life | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1015 | Sunwarrior Classic Protein Chocolate (per scoop) | Sunwarrior | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1016 | Muscletech Phase 8 Protein Chocolate (per scoop) | MuscleTech | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1017 | BPI Sports Best Protein Chocolate Brownie (per scoop) | BPI Sports | US | protein_powder | L | TODO | 2026-04-07 | | |
| 1018 | Maxler 100% Golden Whey Chocolate (per scoop) | Maxler | US | protein_powder | L | TODO | 2026-04-07 | | |
| 1019 | Myvegan Pea Protein Isolate (per scoop) | MyProtein | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 1020 | Protein World Slender Blend Chocolate (per serving) | Protein World | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 1021 | SiS Go Energy Gel (per gel) | SiS | GB | supplement | M | TODO | 2026-04-07 | | Running gel |
| 1022 | Maurten Gel 100 (per gel) | Maurten | SE | supplement | M | TODO | 2026-04-07 | | Elite running gel |
| 1023 | Clif Bloks Energy Chews Strawberry (per 3 pieces) | Clif | US | supplement | M | TODO | 2026-04-07 | | |
| 1024 | Tailwind Endurance Fuel (per serving) | Tailwind | US | supplement | M | TODO | 2026-04-07 | | |
| 1025 | Skratch Labs Hydration Mix Lemon Lime (per serving) | Skratch Labs | US | supplement | M | TODO | 2026-04-07 | | |
| 1026 | Mutant Mass Gainer Chocolate (per serving) | Mutant | CA | protein_powder | M | TODO | 2026-04-07 | | |
| 1027 | PVL Iso Sport Whey Chocolate (per scoop) | PVL | CA | protein_powder | M | TODO | 2026-04-07 | | |
| 1028 | Perfect Sports Diesel Whey Chocolate (per scoop) | Perfect Sports | CA | protein_powder | M | TODO | 2026-04-07 | | Canadian brand |
| 1029 | Rivalus Clean Gainer Chocolate (per serving) | Rivalus | CA | protein_powder | L | TODO | 2026-04-07 | | |
| 1030 | Lenny & Larry's Complete Cookie Chocolate Chip (per cookie) | Lenny & Larry's | US | protein_snack | M | TODO | 2026-04-07 | | |
| 1031 | Lenny & Larry's Complete Cookie Birthday Cake | Lenny & Larry's | US | protein_snack | M | TODO | 2026-04-07 | | |
| 1032 | Nick's Sticks Free Range Turkey Snack (per stick) | Nick's Sticks | US | protein_snack | M | TODO | 2026-04-07 | | |
| 1033 | Epic Venison Sea Salt Pepper Bar | Epic | US | protein_snack | M | TODO | 2026-04-07 | | |

## Section 52: International Dairy & Cheese Brands (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1034 | Boursin Garlic & Fine Herbs (per 30g) | Boursin | FR | dairy | M | TODO | 2026-04-07 | | |
| 1035 | Président Brie (per 30g) | Président | FR | dairy | M | TODO | 2026-04-07 | | |
| 1036 | Laughing Cow Light (per wedge) | La Vache qui Rit | FR | dairy | M | TODO | 2026-04-07 | | |
| 1037 | Galbani Fresh Mozzarella (per 100g) | Galbani | IT | dairy | M | TODO | 2026-04-07 | | |
| 1038 | Mascarpone Galbani (per tbsp) | Galbani | IT | dairy | M | TODO | 2026-04-07 | | |
| 1039 | Leerdammer Cheese (per slice) | Leerdammer | NL | dairy | M | TODO | 2026-04-07 | | |
| 1040 | Paneer Amul Fresh (per 100g) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 1041 | Skimmed Milk Amul Taaza (per 250ml) | Amul | IN | dairy | M | TODO | 2026-04-07 | | |
| 1042 | Double Toned Milk Mother Dairy (per 250ml) | Mother Dairy | IN | dairy | M | TODO | 2026-04-07 | | |
| 1043 | Hung Curd Nestlé a+ (per 100g) | Nestlé India | IN | dairy | M | TODO | 2026-04-07 | | |
| 1044 | Greek Yogurt Nestlé a+ (per 100g) | Nestlé India | IN | dairy | M | TODO | 2026-04-07 | | |
| 1045 | Milky Mist Paneer (per 100g) | Milky Mist | IN | dairy | M | TODO | 2026-04-07 | | South Indian brand |
| 1046 | Go Cheese Slice (per slice) | Parag | IN | dairy | M | TODO | 2026-04-07 | | |
| 1047 | Snow Brand Megmilk 6P Cheese (per piece) | Snow Brand | JP | dairy | M | TODO | 2026-04-07 | | |
| 1048 | Meiji Oishii Milk (per 200ml) | Meiji | JP | dairy | M | TODO | 2026-04-07 | | |
| 1049 | Seoul Milk Strawberry (per 200ml) | Seoul Milk | KR | dairy | M | TODO | 2026-04-07 | | |
| 1050 | Maeil Bio Plain Yogurt (per 100g) | Maeil | KR | dairy | M | TODO | 2026-04-07 | | |
| 1051 | Dutch Lady Chocolate Milk (per 200ml) | Dutch Lady | MY | dairy | M | TODO | 2026-04-07 | | |
| 1052 | Greenfields Full Cream Milk (per 250ml) | Greenfields | ID | dairy | M | TODO | 2026-04-07 | | |
| 1053 | Müller Corner Strawberry | Müller | GB | dairy | M | TODO | 2026-04-07 | | |
| 1054 | Yeo Valley Organic Natural Yogurt (per 100g) | Yeo Valley | GB | dairy | M | TODO | 2026-04-07 | | |
| 1055 | Onken Natural Yogurt (per 100g) | Onken | DE | dairy | M | TODO | 2026-04-07 | | |
| 1056 | Skånemejerier Protein Yogurt (per 100g) | Skånemejerier | SE | dairy | M | TODO | 2026-04-07 | | |
| 1057 | Valio Protein Yogurt (per 100g) | Valio | FI | dairy | M | TODO | 2026-04-07 | | |
| 1058 | Danio High Protein Vanilla | Danone | GB | dairy | H | TODO | 2026-04-07 | | |
| 1059 | Danone Actimel Original (per bottle) | Danone | FR | dairy | M | TODO | 2026-04-07 | | |
| 1060 | Yakult Ace Light Korea (per bottle) | Yakult | KR | dairy | M | TODO | 2026-04-07 | | |
| 1061 | Kefir Lifeway Lowfat Plain (per cup) | Lifeway | US | dairy | M | TODO | 2026-04-07 | | |
| 1062 | Icelandic Provisions Skyr Strawberry | Icelandic Provisions | IS | dairy | M | TODO | 2026-04-07 | | |
| 1063 | Olympic Krema Greek Yogurt (per 100g) | Olympic | CA | dairy | M | TODO | 2026-04-07 | | |
| 1064 | Jalna Pot Set Yoghurt (per 100g) | Jalna | AU | dairy | M | TODO | 2026-04-07 | | |

## Section 53: International Sauces, Pastes & Cooking Ingredients (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1065 | S&B Golden Curry Sauce Mix (per serving) | S&B | JP | condiment | M | TODO | 2026-04-07 | | Japanese curry block |
| 1066 | House Vermont Curry Medium (per serving) | House | JP | condiment | M | TODO | 2026-04-07 | | |
| 1067 | Mirin Hon (per tbsp) | Various | JP | condiment | M | TODO | 2026-04-07 | | |
| 1068 | CJ Gochugaru Korean Chili Flakes (per tbsp) | CJ | KR | condiment | M | TODO | 2026-04-07 | | |
| 1069 | Mae Ploy Green Curry Paste (per tbsp) | Mae Ploy | TH | condiment | M | TODO | 2026-04-07 | | |
| 1070 | Mae Ploy Red Curry Paste (per tbsp) | Mae Ploy | TH | condiment | M | TODO | 2026-04-07 | | |
| 1071 | Knorr Aromat Seasoning (per tsp) | Knorr | ZA | condiment | M | TODO | 2026-04-07 | | SA staple |
| 1072 | Chimichurri Sauce (per tbsp) | Various | AR | condiment | M | TODO | 2026-04-07 | | |
| 1073 | Ají Amarillo Paste (per tbsp) | Various | PE | condiment | M | TODO | 2026-04-07 | | |
| 1074 | Ajvar Red Pepper Relish (per tbsp) | Various | RS | condiment | M | TODO | 2026-04-07 | | Balkan staple |
| 1075 | Tkemali Georgian Plum Sauce (per tbsp) | Various | GE | condiment | M | TODO | 2026-04-07 | | |
| 1076 | Mango Chutney Patak's (per tbsp) | Patak's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1077 | Lime Pickle Patak's (per tbsp) | Patak's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1078 | Tikka Masala Paste Patak's (per tbsp) | Patak's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1079 | Nando's Garlic PERInaise (per tbsp) | Nando's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1080 | Henderson's Relish (per tbsp) | Henderson's | GB | condiment | M | TODO | 2026-04-07 | | Sheffield staple |
| 1081 | Colman's English Mustard (per tsp) | Colman's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1082 | Hellmann's Vegan Mayo (per tbsp) | Hellmann's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1083 | Pesto alla Genovese Barilla (per tbsp) | Barilla | IT | condiment | M | TODO | 2026-04-07 | | |
| 1084 | Pomì Passata Tomato Sauce (per 100g) | Pomì | IT | condiment | M | TODO | 2026-04-07 | | |
| 1085 | Ketchup Heinz (per tbsp) | Heinz | US | condiment | M | TODO | 2026-04-07 | | |
| 1086 | Trader Joe's Green Goddess Dressing (per tbsp) | Trader Joe's | US | condiment | M | TODO | 2026-04-07 | | |
| 1087 | Fly by Jing Sichuan Chili Crisp (per tbsp) | Fly by Jing | US | condiment | M | TODO | 2026-04-07 | | Trendy |

## Section 54: International Frozen Foods & Ready Meals (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1088 | Amy's Kitchen Pad Thai (per serving) | Amy's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1089 | Amy's Kitchen Black Bean Enchilada (per serving) | Amy's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1090 | Healthy Choice Power Bowls Chicken Feta | Healthy Choice | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1091 | Tatty's Chicken Pie (per pie) | Tatty's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1092 | Young's Scampi (per serving) | Young's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1093 | Aunt Bessie's Yorkshire Puddings (per piece) | Aunt Bessie's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1094 | Magnum Mini Classic (per piece) | Magnum | NL | dessert | M | TODO | 2026-04-07 | | |
| 1095 | Häagen-Dazs Vanilla (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | | |
| 1096 | Viennetta Vanilla (per slice) | Wall's | GB | dessert | M | TODO | 2026-04-07 | | |
| 1097 | Solero Exotic (per bar) | Wall's | GB | dessert | M | TODO | 2026-04-07 | | |
| 1098 | Calippo Orange (per piece) | Wall's | GB | dessert | L | TODO | 2026-04-07 | | |
| 1099 | Ajinomoto Yakitori Chicken (per serving) | Ajinomoto | JP | frozen_meal | M | TODO | 2026-04-07 | | |
| 1100 | Strong Roots Mixed Root Vegetable Fries (per serving) | Strong Roots | IE | frozen_meal | M | TODO | 2026-04-07 | | |
| 1101 | Cook Frozen Meals Chicken Tikka | Cook | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1102 | Pieminister Moo Pie (per pie) | Pieminister | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1103 | Buitoni Buitoni Gyoza Chicken (per 5 pieces) | Buitoni | FR | frozen_meal | M | TODO | 2026-04-07 | | |
| 1104 | Picard Macarons Assortment (per piece) | Picard | FR | dessert | M | TODO | 2026-04-07 | | |
| 1105 | ITC Kitchen of India Paneer Makhani (per serving) | ITC | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1106 | Tasty Bite Indian Madras Lentils (per serving) | Tasty Bite | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1107 | Maya Kaimal Everyday Dal Turmeric (per serving) | Maya Kaimal | US | ready_meal | M | TODO | 2026-04-07 | | |
| 1108 | Wei-Chuan Pork & Chive Dumplings (per 5 pieces) | Wei-Chuan | TW | frozen_meal | M | TODO | 2026-04-07 | | |
| 1109 | Schar Gluten Free Pizza Base (per base) | Schar | IT | frozen_meal | M | TODO | 2026-04-07 | | |
| 1110 | Quorn Crispy Nuggets (per 5 pieces) | Quorn | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1111 | Fry's Plant-Based Chicken Strips (per 100g) | Fry's | ZA | frozen_meal | M | TODO | 2026-04-07 | | SA plant-based |
| 1112 | Findus Grönsakspytt (per serving) | Findus | SE | frozen_meal | M | TODO | 2026-04-07 | | |
| 1113 | Stouffer's Lasagna with Meat Sauce (per serving) | Stouffer's | US | frozen_meal | M | TODO | 2026-04-07 | | |

## Section 55: More International Snacks & Treats (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1114 | Twix Original (per bar) | Mars | US | chocolate | M | TODO | 2026-04-07 | | |
| 1115 | Snickers Original (per bar) | Mars | US | chocolate | M | TODO | 2026-04-07 | | |
| 1116 | Kit Kat Original (per 4 finger) | Nestle | US | chocolate | M | TODO | 2026-04-07 | | |
| 1117 | Butterfinger Original (per bar) | Ferrero | US | chocolate | M | TODO | 2026-04-07 | | |
| 1118 | Twizzlers Strawberry (per 4 pieces) | Hershey's | US | confectionery | M | TODO | 2026-04-07 | | |
| 1119 | Annie's Cheddar Bunnies (per 50 pieces) | Annie's | US | snack | M | TODO | 2026-04-07 | | |
| 1120 | Skinny Pop Sea Salt (per 100g) | Skinny Pop | US | snack | M | TODO | 2026-04-07 | | |
| 1121 | Boom Chicka Pop Sea Salt (per 100g) | Angie's | US | snack | M | TODO | 2026-04-07 | | |
| 1122 | Sahale Snacks Maple Pecans Glazed Mix (per 30g) | Sahale | US | snack | M | TODO | 2026-04-07 | | |
| 1123 | Sun Chips Original (per 100g) | Frito-Lay | US | snack | M | TODO | 2026-04-07 | | |
| 1124 | Terra Exotic Vegetable Chips (per 100g) | Terra | US | snack | M | TODO | 2026-04-07 | | |
| 1125 | Cadbury Wispa (per bar) | Cadbury | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1126 | Galaxy Smooth Milk (per bar) | Mars | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1127 | Aero Mint Chocolate (per bar) | Nestle | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1128 | Wine Gums Maynards Bassetts (per 100g) | Cadbury | GB | confectionery | M | TODO | 2026-04-07 | | |
| 1129 | Jelly Babies Bassetts (per 100g) | Cadbury | GB | confectionery | M | TODO | 2026-04-07 | | |
| 1130 | Fruit Pastilles Rowntree's (per 100g) | Nestle | GB | confectionery | M | TODO | 2026-04-07 | | |
| 1131 | Mentos Original (per piece) | Perfetti | NL | confectionery | L | TODO | 2026-04-07 | | |
| 1132 | Chupa Chups Strawberry (per lollipop) | Perfetti | ES | confectionery | L | TODO | 2026-04-07 | | |

## Section 56: More International Breads & Breakfast (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1133 | Brioche Pasquier (per piece) | Pasquier | FR | bread | M | TODO | 2026-04-07 | | |
| 1134 | Harry's American Sandwich Bread (per slice) | Harry's | FR | bread | M | TODO | 2026-04-07 | | |
| 1135 | Jacquet Toast Bread (per slice) | Jacquet | FR | bread | M | TODO | 2026-04-07 | | |
| 1136 | Country Harvest Multigrain Bread (per slice) | Country Harvest | CA | bread | M | TODO | 2026-04-07 | | |
| 1137 | Tip Top Wholemeal Bread (per slice) | Tip Top | AU | bread | M | TODO | 2026-04-07 | | |
| 1138 | Helga's Continental Bakehouse Sourdough (per slice) | Helga's | AU | bread | M | TODO | 2026-04-07 | | |
| 1139 | Vogel's Mixed Grain Bread (per slice) | Vogel's | NZ | bread | M | TODO | 2026-04-07 | | |
| 1140 | Kingsmill 50/50 (per slice) | Kingsmill | GB | bread | M | TODO | 2026-04-07 | | |
| 1141 | Burgen Soya & Linseed Bread (per slice) | Burgen | GB | bread | H | TODO | 2026-04-07 | | High protein bread |
| 1142 | Crumpet Warburtons (per piece) | Warburtons | GB | bread | M | TODO | 2026-04-07 | | British icon |
| 1143 | Bagel Thomas' Everything (per piece) | Thomas' | US | bread | M | TODO | 2026-04-07 | | |
| 1144 | Pop-Tarts Frosted Strawberry (per pastry) | Kellogg's | US | breakfast | M | TODO | 2026-04-07 | | |
| 1145 | Eggo Waffles Buttermilk (per 2 waffles) | Kellogg's | US | breakfast | M | TODO | 2026-04-07 | | |
| 1146 | Nature's Path Organic Toaster Pastry (per pastry) | Nature's Path | CA | breakfast | M | TODO | 2026-04-07 | | |
| 1147 | Weetabix Original (per 2 biscuits) | Weetabix | GB | cereal | H | TODO | 2026-04-07 | | |
| 1148 | Shreddies Original (per serving) | Nestle | GB | cereal | M | TODO | 2026-04-07 | | |
| 1149 | Crunchy Nut Cornflakes (per serving) | Kellogg's | GB | cereal | M | TODO | 2026-04-07 | | |
| 1150 | Coco Pops (per serving) | Kellogg's | GB | cereal | M | TODO | 2026-04-07 | | |
| 1151 | Alpen Muesli No Added Sugar (per serving) | Alpen | GB | cereal | M | TODO | 2026-04-07 | | |
| 1152 | Dorset Cereals Simply Delicious Muesli (per serving) | Dorset | GB | cereal | M | TODO | 2026-04-07 | | |
| 1153 | Quaker Oat So Simple Original (per sachet) | Quaker | GB | cereal | M | TODO | 2026-04-07 | | |
| 1154 | Ready Brek Original (per serving) | Weetabix | GB | cereal | M | TODO | 2026-04-07 | | |
| 1155 | Koko Krunch Nestle (per serving) | Nestle | MY | cereal | M | TODO | 2026-04-07 | | SE Asia cereal |
| 1156 | Chocos Kellogg's (per serving) | Kellogg's | IN | cereal | M | TODO | 2026-04-07 | | India popular |

## Section 57: Remaining Items to Hit 1000+ New (240 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1157 | GoMacro Protein Pleasure Bar Peanut Butter Chocolate | GoMacro | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1158 | Pukka Pie Steak & Kidney (per pie) | Pukka | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1159 | Fray Bentos Steak & Kidney Pie (per tin) | Fray Bentos | GB | ready_meal | M | TODO | 2026-04-07 | | |
| 1160 | Baxters Highlander's Broth (per serving) | Baxters | GB | soup | M | TODO | 2026-04-07 | | |
| 1161 | Victoria Fine Foods Marinara (per serving) | Victoria | US | condiment | M | TODO | 2026-04-07 | | |
| 1162 | Annie's Organic Ketchup (per tbsp) | Annie's | US | condiment | L | TODO | 2026-04-07 | | |
| 1163 | Siete Cashew Queso (per tbsp) | Siete | US | condiment | M | TODO | 2026-04-07 | | |
| 1164 | Ithaca Hummus Classic (per tbsp) | Ithaca | US | dip | M | TODO | 2026-04-07 | | |
| 1165 | Tillamook Farmstyle Thick Cut Sharp Cheddar (per slice) | Tillamook | US | dairy | M | TODO | 2026-04-07 | | |
| 1166 | Cabot Seriously Sharp Cheddar (per 30g) | Cabot | US | dairy | M | TODO | 2026-04-07 | | |
| 1167 | Boursin Plant-Based Garlic & Herbs (per 30g) | Boursin | FR | dairy_alt | M | TODO | 2026-04-07 | | |
| 1168 | Nairn's Oat Crackers (per 4 crackers) | Nairn's | GB | snack | M | TODO | 2026-04-07 | | |
| 1169 | Ryvita Crispbread Original (per 2 slices) | Ryvita | GB | bread | M | TODO | 2026-04-07 | | |
| 1170 | Mini Cheddars Original (per bag 25g) | Jacob's | GB | snack | M | TODO | 2026-04-07 | | |
| 1171 | Space Raiders Pickled Onion (per bag) | KP | GB | snack | L | TODO | 2026-04-07 | | |
| 1172 | Monster Munch Roast Beef (per bag 25g) | Walkers | GB | snack | M | TODO | 2026-04-07 | | |
| 1173 | Wotsits Really Cheesy (per bag 17g) | Walkers | GB | snack | M | TODO | 2026-04-07 | | |
| 1174 | Bourbon Cream Biscuit (per biscuit) | Various | GB | biscuit | M | TODO | 2026-04-07 | | |
| 1175 | Bourbon Alfort Mini Chocolate (per piece) | Bourbon | JP | biscuit | M | TODO | 2026-04-07 | | |
| 1176 | Toppo Chocolate (per box) | Lotte | JP | biscuit | M | TODO | 2026-04-07 | | |
| 1177 | Pepero Almond (per box) | Lotte | KR | confectionery | M | TODO | 2026-04-07 | | |
| 1178 | Melona Ice Bar Melon (per bar) | Binggrae | KR | dessert | M | TODO | 2026-04-07 | | |
| 1179 | Samanco Ice Cream Fish (per piece) | Binggrae | KR | dessert | M | TODO | 2026-04-07 | | |
| 1180 | Yuja Tea Korean Citron (per serving) | Various | KR | beverage | M | TODO | 2026-04-07 | | |
| 1181 | Buldak Sauce (bottle per tbsp) | Samyang | KR | condiment | H | TODO | 2026-04-07 | | |
| 1182 | Ssamjang Dipping Paste (per tbsp) | CJ | KR | condiment | M | TODO | 2026-04-07 | | |
| 1183 | Vienna Sausages Libby's (per can) | Libby's | US | protein | L | TODO | 2026-04-07 | | |
| 1184 | Skippy Peanut Butter Creamy (per tbsp) | Skippy | US | spread | M | TODO | 2026-04-07 | | |
| 1185 | RX Nut Butter Chocolate Peanut Butter (per packet) | RX | US | spread | M | TODO | 2026-04-07 | | |
| 1186 | Dave's Killer Bread Powerseed Thin Sliced (per slice) | Dave's | US | bread | M | TODO | 2026-04-07 | | |
| 1187 | Franz Keto Bread (per slice) | Franz | US | bread | M | TODO | 2026-04-07 | | |
| 1188 | Oroweat Keto Bread (per slice) | Oroweat | US | bread | M | TODO | 2026-04-07 | | |
| 1189 | Unbun Keto Bun (per bun) | Unbun | CA | bread | M | TODO | 2026-04-07 | | |
| 1190 | Carbonaut Low Carb Bread (per slice) | Carbonaut | CA | bread | M | TODO | 2026-04-07 | | |
| 1191 | Cobs Bread Cape Seed Loaf (per slice) | Cobs | AU | bread | M | TODO | 2026-04-07 | | |
| 1192 | Bakers Delight Hi-Fibre Lo-GI Bread (per slice) | Bakers Delight | AU | bread | M | TODO | 2026-04-07 | | |
| 1193 | Manna Bread Whole Rye (per slice) | Various | DE | bread | M | TODO | 2026-04-07 | | |
| 1194 | Knäckebröd Crisp Bread Polarbröd (per piece) | Polarbröd | SE | bread | M | TODO | 2026-04-07 | | |
| 1195 | Flatbrød Norwegian Flatbread (per piece) | Various | NO | bread | M | TODO | 2026-04-07 | | |
| 1196 | Dosa Batter iD (per 2 dosa) | iD Fresh | IN | breakfast | H | TODO | 2026-04-07 | | |
| 1197 | Upma Rava MTR (per serving dry mix) | MTR | IN | breakfast | M | TODO | 2026-04-07 | | |
| 1198 | Poha Flattened Rice Thick (per 100g dry) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |
| 1199 | Sabudana (Tapioca Pearls per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1200 | Besan Chickpea Flour (per 100g) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1201 | Moong Dal Split Yellow (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1202 | Chana Dal Split Bengal Gram (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1203 | Toor Dal Pigeon Pea (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1204 | Urad Dal Black Gram (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1205 | Ghee Amul Pure (per tsp) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 1206 | Groundnut Oil Dhara (per tbsp) | Dhara | IN | cooking | M | TODO | 2026-04-07 | | |
| 1207 | Olio Award Winning EVOO (per tbsp) | Various | GR | cooking | M | TODO | 2026-04-07 | | |
| 1208 | MCT Oil Bulletproof (per tbsp) | Bulletproof | US | supplement | M | TODO | 2026-04-07 | | |
| 1209 | Hemp Hearts Manitoba Harvest (per 30g) | Manitoba Harvest | CA | supplement | M | TODO | 2026-04-07 | | |
| 1210 | Flaxseed Meal Bob's Red Mill (per tbsp) | Bob's Red Mill | US | supplement | M | TODO | 2026-04-07 | | |
| 1211 | Matcha Powder Ceremonial (per tsp) | Various | JP | supplement | M | TODO | 2026-04-07 | | |
| 1212 | Wheatgrass Powder (per tsp) | Various | US | supplement | L | TODO | 2026-04-07 | | |
| 1213 | Acai Powder Freeze Dried (per tbsp) | Various | BR | supplement | M | TODO | 2026-04-07 | | |
| 1214 | Maca Powder (per tsp) | Various | PE | supplement | M | TODO | 2026-04-07 | | |
| 1215 | Cacao Nibs Raw (per tbsp) | Various | PE | supplement | M | TODO | 2026-04-07 | | |
| 1216 | Monk Fruit Sweetener Lakanto (per tsp) | Lakanto | JP | condiment | M | TODO | 2026-04-07 | | |
| 1217 | Erythritol Swerve (per tsp) | Swerve | US | condiment | M | TODO | 2026-04-07 | | |
| 1218 | Stevia Drops SweetLeaf (per serving) | SweetLeaf | US | condiment | L | TODO | 2026-04-07 | | |
| 1219 | Sugar Free Syrup Jordan's Skinny Mixes Vanilla (per tbsp) | Jordan's | US | condiment | M | TODO | 2026-04-07 | | |
| 1220 | Torani Sugar Free Vanilla Syrup (per tbsp) | Torani | US | condiment | M | TODO | 2026-04-07 | | |
| 1221 | Monin Sugar Free Hazelnut Syrup (per tbsp) | Monin | FR | condiment | M | TODO | 2026-04-07 | | |
| 1222 | Biscoff Creamy Spread (per tbsp) | Lotus | BE | spread | M | TODO | 2026-04-07 | | |
| 1223 | Sun-Pat Crunchy Peanut Butter (per tbsp) | Sun-Pat | GB | spread | M | TODO | 2026-04-07 | | |
| 1224 | Whole Earth Smooth Peanut Butter (per tbsp) | Whole Earth | GB | spread | M | TODO | 2026-04-07 | | |
| 1225 | Bega Crunchy Peanut Butter (per tbsp) | Bega | AU | spread | M | TODO | 2026-04-07 | | |
| 1226 | Nocciolata Dairy Free Spread (per tbsp) | Rigoni | IT | spread | M | TODO | 2026-04-07 | | |
| 1227 | Lindt Hazelnut Spread (per tbsp) | Lindt | CH | spread | M | TODO | 2026-04-07 | | |
| 1228 | Boost Juice Original Berry Crush (per regular) | Boost Juice | AU | beverage | M | TODO | 2026-04-07 | | |
| 1229 | Guzman y Gomez Chicken Burrito | GYG | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1230 | Zambrero Chicken Power Burrito | Zambrero | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1231 | Pie Face Classic Mince Beef Pie (per pie) | Pie Face | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1232 | Wendy's NZ Classic Burger | Wendy's NZ | NZ | fast_food | M | TODO | 2026-04-07 | | Different from US |
| 1233 | BurgerFuel C.N.C. Burger | BurgerFuel | NZ | fast_food | M | TODO | 2026-04-07 | | NZ chain |
| 1234 | Hell Pizza Lust (per slice) | Hell Pizza | NZ | fast_food | M | TODO | 2026-04-07 | | NZ chain |
| 1235 | Sushiro Maguro Tuna Nigiri (per 2 pieces) | Sushiro | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1236 | Sukiya Gyudon Regular | Sukiya | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1237 | Matsuya Gyudon Regular | Matsuya | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1238 | Mos Burger Natsumi Burger (Seasonal) | Mos Burger | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1239 | Tendon Tenya Tendon Regular | Tendon Tenya | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1240 | Coco Curry House Pork Cutlet Curry | CoCo | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1241 | Two Two Chicken Fried (per piece) | Two Two | KR | fast_food | M | TODO | 2026-04-07 | | |
| 1242 | BHC Chicken Gold King (per piece) | BHC | KR | fast_food | M | TODO | 2026-04-07 | | |
| 1243 | Pelicana Chicken Original (per piece) | Pelicana | KR | fast_food | M | TODO | 2026-04-07 | | |
| 1244 | Baekjeong Korean BBQ Galbi (per 100g) | Baekjeong | KR | fast_food | M | TODO | 2026-04-07 | | |
| 1245 | Tous les Jours Croquette Bread (per piece) | Tous les Jours | KR | bakery | M | TODO | 2026-04-07 | | |
| 1246 | Sulbing Injeolmi Bingsu (per serving) | Sulbing | KR | dessert | M | TODO | 2026-04-07 | | Korean dessert chain |
| 1247 | Baskin Robbins Korea Shooting Star (per scoop) | Baskin Robbins | KR | dessert | M | TODO | 2026-04-07 | | |
| 1248 | Compose Coffee Americano (per cup) | Compose | KR | beverage | M | TODO | 2026-04-07 | | Korea budget coffee |
| 1249 | Ediya Coffee Iced Americano (per cup) | Ediya | KR | beverage | M | TODO | 2026-04-07 | | |
| 1250 | Caffé Bene Iced Caramel Macchiato (per cup) | Caffé Bene | KR | beverage | M | TODO | 2026-04-07 | | |
| 1251 | Din Tai Fung Xiao Long Bao (per 5 pieces) | Din Tai Fung | TW | fast_food | H | TODO | 2026-04-07 | | |
| 1252 | Tim Ho Wan BBQ Pork Bun (per piece) | Tim Ho Wan | HK | fast_food | M | TODO | 2026-04-07 | | Michelin starred |
| 1253 | Heytea Cheese Tea Green (per M) | Heytea | CN | beverage | M | TODO | 2026-04-07 | | China trending |
| 1254 | Luckin Coffee Latte (per cup) | Luckin | CN | beverage | M | TODO | 2026-04-07 | | China #1 coffee |
| 1255 | Mixue Ice Cream (per serving) | Mixue | CN | dessert | M | TODO | 2026-04-07 | | World's largest chain |
| 1256 | Mixue Lemon Tea (per M) | Mixue | CN | beverage | M | TODO | 2026-04-07 | | |
| 1257 | Haidilao Hot Pot Broth Base Tomato (per serving) | Haidilao | CN | condiment | M | TODO | 2026-04-07 | | |
| 1258 | Orion Chocopie (per piece) | Orion | CN | biscuit | M | TODO | 2026-04-07 | | China version |
| 1259 | Wangzai Milk (per 125ml) | Want Want | CN | dairy | M | TODO | 2026-04-07 | | Chinese childhood drink |
| 1260 | Lay's Cucumber Flavor (China) | Lay's | CN | snack | M | TODO | 2026-04-07 | | China exclusive |
| 1261 | Lay's Braised Pork (China) | Lay's | CN | snack | M | TODO | 2026-04-07 | | |
| 1262 | White Rabbit Matcha Candy (per piece) | White Rabbit | CN | confectionery | M | TODO | 2026-04-07 | | |
| 1263 | Guoba Rice Cracker Spicy (per 100g) | Various | CN | snack | M | TODO | 2026-04-07 | | |
| 1264 | Weilong Latiao Spicy Strip (per 100g) | Weilong | CN | snack | H | TODO | 2026-04-07 | | China viral snack |
| 1265 | Old Yanjing Beer (per 330ml) | Yanjing | CN | beverage | L | TODO | 2026-04-07 | | |
| 1266 | Sapporo Premium Beer (per 330ml) | Sapporo | JP | beverage | L | TODO | 2026-04-07 | | |
| 1267 | Tiger Crystal Beer (per 330ml) | Tiger | SG | beverage | L | TODO | 2026-04-07 | | |
| 1268 | Kingfisher Premium Lager (per 330ml) | Kingfisher | IN | beverage | L | TODO | 2026-04-07 | | |
| 1269 | Efes Pilsen (per 330ml) | Efes | TR | beverage | L | TODO | 2026-04-07 | | |
| 1270 | Hite Extra Cold Beer (per 330ml) | Hite | KR | beverage | L | TODO | 2026-04-07 | | |
| 1271 | OB Lager Beer (per 330ml) | OB | KR | beverage | L | TODO | 2026-04-07 | | |
| 1272 | Tooheys New Lager (per 375ml) | Tooheys | AU | beverage | L | TODO | 2026-04-07 | | |
| 1273 | XXXX Gold Lager (per 375ml) | XXXX | AU | beverage | L | TODO | 2026-04-07 | | Queensland icon |
| 1274 | Steinlager Pure (per 330ml) | Steinlager | NZ | beverage | L | TODO | 2026-04-07 | | |
| 1275 | Teh Tarik Singapore (per cup) | Various | SG | beverage | M | TODO | 2026-04-07 | | |
| 1276 | Ice Kacang ABC (per serving) | Various | MY | dessert | M | TODO | 2026-04-07 | | |
| 1277 | Chendol Singapore (per serving) | Various | SG | dessert | M | TODO | 2026-04-07 | | |
| 1278 | Turon Banana Spring Roll Philippines (per piece) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1279 | Ube Halaya Purple Yam Jam (per tbsp) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1280 | Bibingka Rice Cake Philippines (per piece) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1281 | Che Ba Mau Vietnamese Dessert (per serving) | Various | VN | dessert | M | TODO | 2026-04-07 | | |
| 1282 | Khanom Buang Thai Crispy Pancake (per piece) | Various | TH | dessert | M | TODO | 2026-04-07 | | |
| 1283 | Khanom Krok Thai Coconut Pancake (per piece) | Various | TH | dessert | M | TODO | 2026-04-07 | | |
| 1284 | Barfi Kaju Katli (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1285 | Ladoo Motichoor (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1286 | Peda Milk Sweet (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1287 | Kulfi Mango (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1288 | Payasam Kerala Rice Pudding (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1289 | Modak Steamed Sweet (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1290 | Shrikhand Sweet Yogurt (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1291 | Basundi Thick Sweetened Milk (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1292 | Thandai Spiced Milk (per cup) | Various | IN | beverage | M | TODO | 2026-04-07 | | |
| 1293 | Aam Ras Mango Puree (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1294 | Falooda Rose (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1295 | Rabri Thickened Milk Sweet (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1296 | Samosa Aloo (per piece) | Various | IN | snack | H | TODO | 2026-04-07 | | |
| 1297 | Vada Pav Mumbai (per piece) | Various | IN | fast_food | H | TODO | 2026-04-07 | | |
| 1298 | Poori with Aloo (per piece + serving) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |

## Section 58: Items from User Food Log (Missing from DB)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1299 | Oat Milk Latte (per 16oz cup) | Various | US | beverage | H | TODO | 2026-04-07 | | Coffee shop standard |
| 1300 | Carne Apache Mexican Raw Beef Dish (per serving) | Various | MX | protein | H | TODO | 2026-04-07 | | Mexican street food - raw beef cured in lime |
| 1301 | Goobne Oven Crispy Chicken Original (per piece) | Goobne | KR | fast_food | H | TODO | 2026-04-07 | | Korean oven-roasted chicken chain |
| 1302 | Goobne Oven Crispy Chicken Soy Garlic (per piece) | Goobne | KR | fast_food | M | TODO | 2026-04-07 | | |
| 1303 | Elote Cup Mexican Street Corn (per cup) | Various | MX | snack | H | TODO | 2026-04-07 | | Corn with mayo, chili, lime, cheese |

---

## Section 59: From foods_needed.md - Missing Items (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1304 | Hungry Jack's Stunner Meal | Hungry Jack's | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1305 | Concha Mexican Sweet Bread (per piece) | Various | MX | bread | H | TODO | 2026-04-07 | | Pan dulce icon |
| 1306 | Vindaloo Curry (per serving) | Various | IN | curry | H | TODO | 2026-04-07 | | Goan Portuguese-Indian |
| 1307 | Hush Puppy Deep Fried Cornmeal (per piece) | Various | US | snack | M | TODO | 2026-04-07 | | Southern US |
| 1308 | Escargot in Garlic Butter (per 6 pieces) | Various | FR | protein | M | TODO | 2026-04-07 | | |
| 1309 | Gushers Fruit Snack (per pouch) | Betty Crocker | US | confectionery | M | TODO | 2026-04-07 | | |
| 1310 | Radish Raw (per 100g) | Various | US | vegetable | L | TODO | 2026-04-07 | | |
| 1311 | Parsnip Cooked (per 100g) | Various | GB | vegetable | M | TODO | 2026-04-07 | | |
| 1312 | Rutabaga Cooked (per 100g) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 1313 | Beetroot Cooked (per 100g) | Various | GB | vegetable | M | TODO | 2026-04-07 | | |
| 1314 | Pistachios Roasted Salted (per 30g) | Various | US | snack | H | TODO | 2026-04-07 | | |
| 1315 | Durian Fresh (per 100g) | Various | MY | fruit | M | TODO | 2026-04-07 | | |
| 1316 | Strawberry Fresh (per 100g) | Various | US | fruit | H | TODO | 2026-04-07 | | |
| 1317 | Chalupa Taco Bell (per piece) | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | | |
| 1318 | Cayenne Pepper Ground (per tsp) | Various | US | condiment | L | TODO | 2026-04-07 | | |
| 1319 | Hazelnut Raw (per 30g) | Various | TR | snack | M | TODO | 2026-04-07 | | |
| 1320 | Mirepoix (per 100g) | Various | FR | vegetable | L | TODO | 2026-04-07 | | Celery carrot onion mix |
| 1321 | Quiznos Classic Italian Sub (per 8-inch) | Quiznos | US | fast_food | M | TODO | 2026-04-07 | | |
| 1322 | Dunkaroos (per pack) | Betty Crocker | US | snack | M | TODO | 2026-04-07 | | |
| 1323 | Kelp Fries (per serving) | Various | US | snack | M | TODO | 2026-04-07 | | Health food trend |
| 1324 | Dippin' Dots Ice Cream (per serving) | Dippin' Dots | US | dessert | M | TODO | 2026-04-07 | | |
| 1325 | Popsicle Fruit Bar (per bar) | Popsicle | US | dessert | M | TODO | 2026-04-07 | | |
| 1326 | Jelly Belly Jelly Beans (per 35 pieces) | Jelly Belly | US | confectionery | M | TODO | 2026-04-07 | | |
| 1327 | Mocha Coffee Latte (per 16oz) | Various | US | beverage | H | TODO | 2026-04-07 | | |
| 1328 | Negroni Cocktail (per glass) | Various | IT | beverage | M | TODO | 2026-04-07 | | |
| 1329 | Goulash Hungarian (per serving) | Various | HU | soup | M | TODO | 2026-04-07 | | |
| 1330 | Cheddar Bay Biscuit Red Lobster (per piece) | Red Lobster | US | bread | M | TODO | 2026-04-07 | | |
| 1331 | Apricot Fresh (per piece) | Various | TR | fruit | M | TODO | 2026-04-07 | | |

## Section 60: From WRONG_FOOD_MATCHES.md - Generic Entries Needed (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1332 | Water Plain (per 100ml) | Various | US | beverage | H | TODO | 2026-04-07 | | 0 cal - prevents wrong matches |
| 1333 | Salt Table (per tsp) | Various | US | condiment | H | TODO | 2026-04-07 | | 0 cal - prevents wrong matches |
| 1334 | Cola Generic Soda (per can 355ml) | Various | US | beverage | H | TODO | 2026-04-07 | | |
| 1335 | Salad Dressing Generic (per tbsp) | Various | US | condiment | H | TODO | 2026-04-07 | | Prevents dressing→stuffing match |
| 1336 | Custard Dessert (per serving) | Various | GB | dessert | M | TODO | 2026-04-07 | | |

## Section 61: Street Food - Top Priority Countries (200 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1337 | Chuan'r Lamb Skewer Street Grill (per stick) | Various | CN | street_food | H | TODO | 2026-04-07 | | |
| 1338 | Chuan'r Chicken Heart Skewer (per stick) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 1339 | Chuan'r Squid Skewer (per stick) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 1340 | Rou Jia Mo Chinese Meat Burger (per piece) | Various | CN | street_food | H | TODO | 2026-04-07 | | "Chinese hamburger" |
| 1341 | Scallion Pancake Cong You Bing (per piece) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 1342 | Stinky Tofu Chou Doufu Fried (per serving) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 1343 | Boba Tea Street Stand Classic Milk Tea (per cup) | Various | CN | street_food | H | TODO | 2026-04-07 | | |
| 1344 | Malatang Sichuan Hot Pot Street (per serving) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 1345 | Takoyaki Street Stand (per 6 pieces) | Various | JP | street_food | H | TODO | 2026-04-07 | | Osaka icon |
| 1346 | Yakitori Street Grill Chicken Thigh (per stick) | Various | JP | street_food | H | TODO | 2026-04-07 | | |
| 1347 | Yakitori Street Grill Tsukune (per stick) | Various | JP | street_food | M | TODO | 2026-04-07 | | Chicken meatball |
| 1348 | Okonomiyaki Street Stand (per piece) | Various | JP | street_food | M | TODO | 2026-04-07 | | |
| 1349 | Taiyaki Street Cart Red Bean (per piece) | Various | JP | street_food | M | TODO | 2026-04-07 | | |
| 1350 | Crepe Stand Strawberry Cream Harajuku (per piece) | Various | JP | street_food | M | TODO | 2026-04-07 | | |
| 1351 | Karaage Stand Street Fried Chicken (per serving) | Various | JP | street_food | M | TODO | 2026-04-07 | | |
| 1352 | Tteokbokki Street Cart (per serving) | Various | KR | street_food | H | TODO | 2026-04-07 | | |
| 1353 | Korean Corn Dog Street Hotteok (per piece) | Various | KR | street_food | H | TODO | 2026-04-07 | | Cheese-stuffed |
| 1354 | Odeng Fish Cake Street (per stick) | Various | KR | street_food | M | TODO | 2026-04-07 | | |
| 1355 | Hotteok Sweet Pancake Street (per piece) | Various | KR | street_food | M | TODO | 2026-04-07 | | |
| 1356 | Bungeoppang Fish Shaped Waffle (per piece) | Various | KR | street_food | M | TODO | 2026-04-07 | | |
| 1357 | Gyeranppang Egg Bread Street (per piece) | Various | KR | street_food | M | TODO | 2026-04-07 | | |
| 1358 | Doner Box with Fries (per serving) | Various | DE | street_food | H | TODO | 2026-04-07 | | |
| 1359 | Currywurst Stand with Pommes (per serving) | Various | DE | street_food | H | TODO | 2026-04-07 | | |
| 1360 | Bratwurst Stand im Brötchen (per piece) | Various | DE | street_food | M | TODO | 2026-04-07 | | |
| 1361 | Fischbrötchen Bismarck Herring (per piece) | Various | DE | street_food | M | TODO | 2026-04-07 | | North German |
| 1362 | Crepe Stand Nutella Banana (per piece) | Various | FR | street_food | H | TODO | 2026-04-07 | | |
| 1363 | Crepe Stand Ham Cheese Egg (per piece) | Various | FR | street_food | H | TODO | 2026-04-07 | | Galette complète |
| 1364 | Kebab Stand Shawarma Paris (per wrap) | Various | FR | street_food | M | TODO | 2026-04-07 | | |
| 1365 | Baguette Sandwich Jambon Beurre (per piece) | Various | FR | street_food | H | TODO | 2026-04-07 | | France #1 sandwich |
| 1366 | Kebab Van Chicken Doner (per wrap) | Various | GB | street_food | H | TODO | 2026-04-07 | | |
| 1367 | Kebab Van Lamb Doner Meat & Chips | Various | GB | street_food | M | TODO | 2026-04-07 | | |
| 1368 | Jacket Potato Van Cheese & Beans | Various | GB | street_food | M | TODO | 2026-04-07 | | |
| 1369 | Pie & Mash Stand Steak Pie | Various | GB | street_food | M | TODO | 2026-04-07 | | |
| 1370 | Sev Puri Street Cart (per plate) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 1371 | Dahi Puri Street Cart (per plate) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 1372 | Dosa Street Cart Masala (per piece) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 1373 | Egg Roll Kolkata Street (per piece) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 1374 | Mirchi Bajji Chilli Fritter Street (per piece) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 1375 | Chai Street Cart (per cup) | Various | IN | street_food | H | TODO | 2026-04-07 | | Cutting chai |
| 1376 | Tacos de Birria Street (per taco) | Various | MX | street_food | H | TODO | 2026-04-07 | | |
| 1377 | Tacos de Carnitas Street (per taco) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 1378 | Tacos de Barbacoa Street (per taco) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 1379 | Tamales Street Cart Pork (per piece) | Various | MX | street_food | H | TODO | 2026-04-07 | | |
| 1380 | Gorditas Street Cart (per piece) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 1381 | Torta Ahogada Street (per piece) | Various | MX | street_food | M | TODO | 2026-04-07 | | Guadalajara specialty |
| 1382 | Tlayuda Oaxacan Street Pizza (per piece) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 1383 | Churros Street Cart with Chocolate (per 3) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 1384 | Elotes Grilled Corn Street Cart (per ear) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 1385 | Gyros Pork Stand Greece (per wrap) | Various | GR | street_food | H | TODO | 2026-04-07 | | |
| 1386 | Souvlaki Chicken Stand (per stick) | Various | GR | street_food | M | TODO | 2026-04-07 | | |
| 1387 | Thai Grilled Pork Skewer Moo Ping (per stick) | Various | TH | street_food | M | TODO | 2026-04-07 | | |
| 1388 | Bakso Meatball Cart Indonesia (per serving) | Various | ID | street_food | H | TODO | 2026-04-07 | | |
| 1389 | Gorengan Fried Snacks Cart (per piece) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 1390 | Martabak Manis Sweet Pancake (per slice) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 1391 | Nasi Goreng Street Cart (per plate) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 1392 | Satay Street Grill Ayam (per stick) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 1393 | Soto Ayam Street Cart (per bowl) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 1394 | Turkish Simit Street Cart (per piece) | Various | TR | street_food | H | TODO | 2026-04-07 | | |
| 1395 | Turkish Kumpir Stuffed Potato (per piece) | Various | TR | street_food | M | TODO | 2026-04-07 | | |
| 1396 | Turkish Döner Street Wrap (per wrap) | Various | TR | street_food | H | TODO | 2026-04-07 | | |
| 1397 | Turkish Balık Ekmek Fish Sandwich (per piece) | Various | TR | street_food | M | TODO | 2026-04-07 | | Istanbul icon |
| 1398 | Turkish Midye Dolma Stuffed Mussels (per 5) | Various | TR | street_food | M | TODO | 2026-04-07 | | |
| 1399 | Turkish Kokoreç Offal Wrap (per piece) | Various | TR | street_food | M | TODO | 2026-04-07 | | |
| 1400 | Arepas Street Cart Reina Pepiada (per piece) | Various | VE | street_food | M | TODO | 2026-04-07 | | |
| 1401 | Choripán Argentine Sausage Sandwich (per piece) | Various | AR | street_food | M | TODO | 2026-04-07 | | |
| 1402 | Empanada Street Cart Beef Argentina (per piece) | Various | AR | street_food | M | TODO | 2026-04-07 | | |
| 1403 | Pastel Street Cart Carne Brazil (per piece) | Various | BR | street_food | M | TODO | 2026-04-07 | | |
| 1404 | Acarajé Street Stand Bahia (per piece) | Various | BR | street_food | M | TODO | 2026-04-07 | | |
| 1405 | Tapioca Street Cart Coco Brazil (per piece) | Various | BR | street_food | M | TODO | 2026-04-07 | | |
| 1406 | Espetinho Street Grill Chicken (per stick) | Various | BR | street_food | M | TODO | 2026-04-07 | | |
| 1407 | Poutine Street Stand Classic Canada (per serving) | Various | CA | street_food | H | TODO | 2026-04-07 | | |
| 1408 | BeaverTails Pastry Cinnamon Sugar (per piece) | BeaverTails | CA | street_food | M | TODO | 2026-04-07 | | Canadian icon |
| 1409 | Peameal Bacon Sandwich Toronto (per piece) | Various | CA | street_food | M | TODO | 2026-04-07 | | |
| 1410 | Belgian Frites Stand Double Fried (per cone) | Various | BE | street_food | H | TODO | 2026-04-07 | | |
| 1411 | Belgian Waffle Street Cart Brussels (per piece) | Various | BE | street_food | M | TODO | 2026-04-07 | | |
| 1412 | Egyptian Koshari Street Cart (per serving) | Various | EG | street_food | H | TODO | 2026-04-07 | | |
| 1413 | Egyptian Falafel Ta'ameya Cart (per 3 pieces) | Various | EG | street_food | M | TODO | 2026-04-07 | | |
| 1414 | Egyptian Ful Medames Cart (per serving) | Various | EG | street_food | M | TODO | 2026-04-07 | | |
| 1415 | Israeli Falafel Stand in Pita (per pita) | Various | IL | street_food | H | TODO | 2026-04-07 | | |
| 1416 | Israeli Sabich Stand Eggplant Pita (per pita) | Various | IL | street_food | M | TODO | 2026-04-07 | | |
| 1417 | Würstelstand Käsekrainer Vienna (per piece) | Various | AT | street_food | M | TODO | 2026-04-07 | | Cheese sausage |
| 1418 | Würstelstand Bosna Vienna (per piece) | Various | AT | street_food | M | TODO | 2026-04-07 | | |
| 1419 | Shawarma Stand Chicken UAE (per wrap) | Various | AE | street_food | H | TODO | 2026-04-07 | | |
| 1420 | Luqaimat Sweet Dumpling UAE (per 5 pieces) | Various | AE | street_food | M | TODO | 2026-04-07 | | |
| 1421 | Hong Kong Egg Waffle Gai Daan Jai (per piece) | Various | HK | street_food | M | TODO | 2026-04-07 | | |
| 1422 | Hong Kong Fish Ball Curry (per 6 pieces) | Various | HK | street_food | M | TODO | 2026-04-07 | | |
| 1423 | Lángos Hungarian Fried Bread Street (per piece) | Various | HU | street_food | M | TODO | 2026-04-07 | | |
| 1424 | Kürtőskalács Chimney Cake Hungary (per piece) | Various | HU | street_food | M | TODO | 2026-04-07 | | |
| 1425 | Danish Pølse Hot Dog Cart (per piece) | Various | DK | street_food | M | TODO | 2026-04-07 | | Rød pølse |
| 1426 | Colombian Arepa de Huevo (per piece) | Various | CO | street_food | M | TODO | 2026-04-07 | | |
| 1427 | Colombian Empanada Street (per piece) | Various | CO | street_food | M | TODO | 2026-04-07 | | |
| 1428 | Peruvian Anticucho Heart Skewer (per stick) | Various | PE | street_food | M | TODO | 2026-04-07 | | |
| 1429 | Nigerian Suya Beef Skewer Street (per stick) | Various | NG | street_food | M | TODO | 2026-04-07 | | |
| 1430 | Nigerian Akara Bean Fritter (per piece) | Various | NG | street_food | M | TODO | 2026-04-07 | | |
| 1431 | South African Boerewors Roll (per piece) | Various | ZA | street_food | M | TODO | 2026-04-07 | | |
| 1432 | Moroccan Snail Soup Babbouche (per bowl) | Various | MA | street_food | M | TODO | 2026-04-07 | | |
| 1433 | Moroccan Msemen Flatbread (per piece) | Various | MA | street_food | M | TODO | 2026-04-07 | | |
| 1434 | Senegalese Fataya Pastry (per piece) | Various | SN | street_food | M | TODO | 2026-04-07 | | |
| 1435 | Vietnamese Bun Cha Street Hanoi (per serving) | Various | VN | street_food | M | TODO | 2026-04-07 | | |
| 1436 | Vietnamese Banh Xeo Crispy Pancake Street (per piece) | Various | VN | street_food | M | TODO | 2026-04-07 | | |
| 1437 | Filipino Isaw Grilled Intestine (per stick) | Various | PH | street_food | M | TODO | 2026-04-07 | | |
| 1438 | Filipino Kwek Kwek Quail Egg Fritter (per 5) | Various | PH | street_food | M | TODO | 2026-04-07 | | |
| 1439 | Filipino Fishball Street Cart (per 5 pieces) | Various | PH | street_food | M | TODO | 2026-04-07 | | |
| 1440 | Malaysian Satay Kajang (per stick) | Various | MY | street_food | M | TODO | 2026-04-07 | | |
| 1441 | Malaysian Lok Lok Skewer (per stick) | Various | MY | street_food | M | TODO | 2026-04-07 | | |
| 1442 | Malaysian Apam Balik Peanut Pancake (per piece) | Various | MY | street_food | M | TODO | 2026-04-07 | | |
| 1443 | Singaporean Satay Street Chicken (per stick) | Various | SG | street_food | M | TODO | 2026-04-07 | | |
| 1444 | Bangladeshi Fuchka (per 6 pieces) | Various | BD | street_food | M | TODO | 2026-04-07 | | Like pani puri |
| 1445 | Bangladeshi Jhalmuri Puffed Rice Snack (per serving) | Various | BD | street_food | M | TODO | 2026-04-07 | | |
| 1446 | Sri Lankan Kottu Roti Street (per serving) | Various | LK | street_food | M | TODO | 2026-04-07 | | |
| 1447 | Sri Lankan Isso Wade Prawn Fritter (per piece) | Various | LK | street_food | M | TODO | 2026-04-07 | | |
| 1448 | Nepali Momo Buff Steamed (per 8 pieces) | Various | NP | street_food | M | TODO | 2026-04-07 | | |
| 1449 | Nepali Chatamari Rice Crepe (per piece) | Various | NP | street_food | M | TODO | 2026-04-07 | | |
| 1450 | Spanish Churros with Chocolate (per 3 churros) | Various | ES | street_food | M | TODO | 2026-04-07 | | |
| 1451 | Spanish Bocadillo de Calamares (per piece) | Various | ES | street_food | M | TODO | 2026-04-07 | | Madrid icon |
| 1452 | Czech Trdelník Chimney Cake (per piece) | Various | CZ | street_food | M | TODO | 2026-04-07 | | |
| 1453 | Czech Klobása Grilled Sausage (per piece) | Various | CZ | street_food | M | TODO | 2026-04-07 | | |
| 1454 | Polish Zapiekanka Open Baguette (per piece) | Various | PL | street_food | M | TODO | 2026-04-07 | | |
| 1455 | Polish Oscypek Grilled Cheese Street (per piece) | Various | PL | street_food | M | TODO | 2026-04-07 | | |
| 1456 | Russian Pirozhki Fried Pie (per piece) | Various | RU | street_food | M | TODO | 2026-04-07 | | |
| 1457 | Raclette Street Stand Switzerland (per serving) | Various | CH | street_food | M | TODO | 2026-04-07 | | |
| 1458 | Swedish Tunnbrödsrulle Hot Dog Wrap (per piece) | Various | SE | street_food | M | TODO | 2026-04-07 | | |
| 1459 | Finnish Lihapiirakka Meat Pie (per piece) | Various | FI | street_food | M | TODO | 2026-04-07 | | |
| 1460 | Australian Sausage Sizzle (per piece) | Various | AU | street_food | M | TODO | 2026-04-07 | | Bunnings icon |
| 1461 | Australian Halal Snack Pack HSP (per serving) | Various | AU | street_food | M | TODO | 2026-04-07 | | |
| 1462 | Australian Dim Sim Fried (per piece) | Various | AU | street_food | M | TODO | 2026-04-07 | | |
| 1463 | Afghan Bolani Stuffed Flatbread (per piece) | Various | AF | street_food | M | TODO | 2026-04-07 | | |
| 1464 | Afghan Mantu Dumplings (per 5 pieces) | Various | AF | street_food | M | TODO | 2026-04-07 | | |
| 1465 | Ethiopian Sambusa (per piece) | Various | ET | street_food | M | TODO | 2026-04-07 | | |
| 1466 | Tanzanian Zanzibar Pizza (per piece) | Various | TZ | street_food | M | TODO | 2026-04-07 | | |
| 1467 | Kenyan Mutura Blood Sausage (per piece) | Various | KE | street_food | M | TODO | 2026-04-07 | | |
| 1468 | Kenyan Nyama Choma Street Grill (per 100g) | Various | KE | street_food | M | TODO | 2026-04-07 | | |
| 1469 | Lebanese Arayes Grilled Pita (per piece) | Various | LB | street_food | M | TODO | 2026-04-07 | | |
| 1470 | Cambodian Num Pang Sandwich (per piece) | Various | KH | street_food | M | TODO | 2026-04-07 | | |
| 1471 | Myanmar Tea Leaf Salad Lahpet (per serving) | Various | MM | street_food | M | TODO | 2026-04-07 | | |
| 1472 | Laotian Khao Piak Sen Noodle Soup (per serving) | Various | LA | street_food | M | TODO | 2026-04-07 | | |
| 1473 | Georgian Khachapuri Adjarian (per piece) | Various | GE | street_food | H | TODO | 2026-04-07 | | Cheese bread with egg |
| 1474 | Georgian Khinkali Dumplings (per 5 pieces) | Various | GE | street_food | M | TODO | 2026-04-07 | | |
| 1475 | Irish Chip Van Curry Chips (per serving) | Various | IE | street_food | M | TODO | 2026-04-07 | | |
| 1476 | Trinidadian Doubles with Channa (per piece) | Various | TT | street_food | M | TODO | 2026-04-07 | | |
| 1477 | Salvadoran Pupusa Revuelta Street (per piece) | Various | SV | street_food | M | TODO | 2026-04-07 | | |
| 1478 | Haitian Griot Fried Pork (per serving) | Various | HT | street_food | M | TODO | 2026-04-07 | | |
| 1479 | Pakistani Bun Kebab Street (per piece) | Various | PK | street_food | M | TODO | 2026-04-07 | | |
| 1480 | Pakistani Gol Gappay Street Cart (per 6) | Various | PK | street_food | M | TODO | 2026-04-07 | | |
| 1481 | Pakistani Chana Chaat Street (per plate) | Various | PK | street_food | M | TODO | 2026-04-07 | | |
| 1482 | Uzbek Somsa Meat Pastry (per piece) | Various | UZ | street_food | M | TODO | 2026-04-07 | | |
| 1483 | Uzbek Plov Rice Pilaf Street (per serving) | Various | UZ | street_food | M | TODO | 2026-04-07 | | |

## Section 62: From FOOD_LOG_EDGE_CASES.md - Common User Inputs Missing (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1484 | Protein Shake Generic Whey with Milk (per serving) | Various | US | protein_drink | H | TODO | 2026-04-07 | | |
| 1485 | Rice and Dal Combo (per serving) | Various | IN | staple | H | TODO | 2026-04-07 | | Common Indian input |
| 1486 | Steak and Potatoes Dinner (per serving) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 1487 | Noodles and Egg Stir Fry (per serving) | Various | CN | noodle | M | TODO | 2026-04-07 | | |
| 1488 | Momo Steamed Chicken (per 5 pieces) | Various | NP | snack | H | TODO | 2026-04-07 | | |
| 1489 | Momos Fried (per 5 pieces) | Various | IN | snack | H | TODO | 2026-04-07 | | |
| 1490 | Protein Fluff Casein Ice (per serving) | Various | US | dessert | M | TODO | 2026-04-07 | | Fitness trend |
| 1491 | Rice Cake with Peanut Butter (per 2 cakes) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 1492 | Post Workout Shake Generic (per serving) | Various | US | protein_drink | M | TODO | 2026-04-07 | | 2 scoops + milk |
| 1493 | Tagine Lamb with Apricots Couscous (per serving) | Various | MA | protein | M | TODO | 2026-04-07 | | From edge cases |
| 1494 | Khachapuri Georgian Cheese Bread (per piece) | Various | GE | bread | H | TODO | 2026-04-07 | | From edge cases |
| 1495 | Mole Negro with Chicken (per serving) | Various | MX | protein | M | TODO | 2026-04-07 | | |
| 1496 | Pesarattu Green Gram Dosa (per piece) | Various | IN | breakfast | M | TODO | 2026-04-07 | | Andhra specialty |
| 1497 | Thepla Gujarati Flatbread (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |
| 1498 | Aam Ras Mango Pulp with Milk (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 1499 | Chhachh Buttermilk Spiced (per glass) | Various | IN | beverage | M | TODO | 2026-04-07 | | Gujarat specialty |
| 1500 | Parotta Kerala Layered Bread (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |
| 1501 | Appam Kerala Rice Pancake (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |
| 1502 | Fish Curry Kerala Style (per serving) | Various | IN | protein | M | TODO | 2026-04-07 | | |
| 1503 | Poriyal Vegetable Stir Fry (per serving) | Various | IN | vegetable | M | TODO | 2026-04-07 | | |
| 1504 | Curd Rice Thayir Sadam (per serving) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1505 | Appalam Papadum Fried (per piece) | Various | IN | snack | M | TODO | 2026-04-07 | | |
| 1506 | Caramel Frappuccino Grande Starbucks (per cup) | Starbucks | US | beverage | H | TODO | 2026-04-07 | | |
| 1507 | Chipotle Bowl Double Chicken Extra Guac (per bowl) | Chipotle | US | fast_food | H | TODO | 2026-04-07 | | Common user order |
| 1508 | CAVA Bowl Grilled Chicken | CAVA | US | fast_food | M | TODO | 2026-04-07 | | |
| 1509 | Popeyes 3 Piece Chicken Tender | Popeyes | US | fast_food | M | TODO | 2026-04-07 | | |
| 1510 | Jersey Mike's #13 Italian Sub (per regular) | Jersey Mike's | US | fast_food | M | TODO | 2026-04-07 | | |
| 1511 | Charcuterie Board (per serving estimate) | Various | US | snack | M | TODO | 2026-04-07 | | Cheese crackers meat fruit |
| 1512 | IPA Beer Craft (per pint) | Various | US | beverage | M | TODO | 2026-04-07 | | Higher cal than lager |
| 1513 | Red Wine Generic (per glass 150ml) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1514 | Whiskey Shot (per 44ml) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1515 | Margarita Classic (per glass) | Various | MX | beverage | M | TODO | 2026-04-07 | | |
| 1516 | Mimosa Champagne OJ (per glass) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1517 | Boba Tea Taro Large with Tapioca (per cup) | Various | TW | beverage | H | TODO | 2026-04-07 | | |
| 1518 | Açaí Bowl with Granola Banana PB (per bowl) | Various | BR | breakfast | H | TODO | 2026-04-07 | | |
| 1519 | Turkey Avocado Sandwich Whole Wheat (per sandwich) | Various | US | fast_food | M | TODO | 2026-04-07 | | |
| 1520 | Sushi Spicy Tuna Roll (per 8 pieces) | Various | US | fast_food | M | TODO | 2026-04-07 | | |
| 1521 | Buffalo Wings Traditional (per 8 wings) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 1522 | Nachos with Cheese Jalapenos (per serving) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 1523 | Fish Tacos with Mango Salsa (per 2 tacos) | Various | MX | fast_food | M | TODO | 2026-04-07 | | |
| 1524 | BBQ Ribs Half Rack with Cornbread (per serving) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 1525 | Lobster Tail with Butter (per tail) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 1526 | Tonkotsu Ramen Chashu Ajitama (per bowl) | Various | JP | noodle | H | TODO | 2026-04-07 | | Common user input |
| 1527 | Shawarma with Toum Pickled Turnips (per wrap) | Various | LB | fast_food | M | TODO | 2026-04-07 | | |
| 1528 | Golgappa 2 Plates (per 2 plates ~12 pcs) | Various | IN | snack | M | TODO | 2026-04-07 | | Hindi name for pani puri |
| 1529 | Schnitzel with Kartoffelsalat (per serving) | Various | DE | protein | M | TODO | 2026-04-07 | | |
| 1530 | Indian Thali Full Meal (per thali) | Various | IN | fast_food | H | TODO | 2026-04-07 | | Dal paneer aloo rice roti raita |
| 1531 | Korean BBQ Bulgogi with Rice Banchan (per serving) | Various | KR | protein | M | TODO | 2026-04-07 | | |

---

## Section 63: Plain Staples & Homemade Basics (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1532 | Penne Pasta Cooked (per 100g) | Various | IT | staple | M | TODO | 2026-04-07 | | |
| 1533 | Chicken Thigh Grilled Boneless (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 1534 | Ground Beef 80/20 Cooked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 1535 | Ground Beef 90/10 Cooked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 1536 | Ground Turkey 93/7 Cooked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 1537 | Salmon Fillet Baked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 1538 | Steak Ribeye Cooked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 1539 | Steak Sirloin Cooked (per 100g) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 1540 | Buttered Toast (per slice) | Various | US | bread | H | TODO | 2026-04-07 | | Very common input |
| 1541 | Roasted Asparagus (per 100g) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 1542 | Side Salad Mixed Greens (per serving) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 1543 | Pasta with Meat Sauce Bolognese (per serving) | Various | IT | pasta | H | TODO | 2026-04-07 | | |
| 1544 | Chicken Soup Homemade (per serving) | Various | US | soup | M | TODO | 2026-04-07 | | |
| 1545 | Chicken and Rice Simple (per serving) | Various | US | protein | H | TODO | 2026-04-07 | | #1 meal prep combo |

## Section 64: Common Fruits & Vegetables (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1546 | Cherry Fresh (per 100g) | Various | US | fruit | M | TODO | 2026-04-07 | | |
| 1547 | Grapefruit Half (per half) | Various | US | fruit | M | TODO | 2026-04-07 | | |
| 1548 | Garlic Clove Raw (per clove) | Various | US | vegetable | L | TODO | 2026-04-07 | | |
| 1549 | Corn Kernels Cooked (per 100g) | Various | US | vegetable | M | TODO | 2026-04-07 | | |

## Section 65: Everyday Beverages & Coffee (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1550 | Espresso Single Shot | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1551 | Espresso Double Shot | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1552 | Latte Oat Milk 16oz | Various | US | beverage | H | TODO | 2026-04-07 | | |
| 1553 | Cappuccino 12oz | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1554 | Flat White 12oz | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1555 | Starbucks Pike Place Brewed Grande | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 1556 | Starbucks Vanilla Latte Grande | Starbucks | US | beverage | H | TODO | 2026-04-07 | | |
| 1557 | Starbucks Matcha Latte Grande | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 1558 | Starbucks Refresher Strawberry Acai Grande | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 1559 | Starbucks Dragon Drink Grande | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 1560 | Dunkin' Medium Hot Latte | Dunkin' | US | beverage | M | TODO | 2026-04-07 | | |
| 1561 | Dunkin' Charli Cold Foam | Dunkin' | US | beverage | M | TODO | 2026-04-07 | | |
| 1562 | Coca-Cola Zero (per 12oz can) | Coca-Cola | US | beverage | H | TODO | 2026-04-07 | | |
| 1563 | Iced Tea Sweet Southern (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1564 | Hot Chocolate with Marshmallows (per cup) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1565 | Oat Milk Original (per 8oz) | Various | US | dairy_alt | H | TODO | 2026-04-07 | | |
| 1566 | Soy Milk Original (per 8oz) | Various | US | dairy_alt | M | TODO | 2026-04-07 | | |

## Section 66: Dairy, Condiments & Cooking Basics (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1567 | Hellmann's Real Mayo (per tbsp) | Hellmann's | US | condiment | H | TODO | 2026-04-07 | | |
| 1568 | A1 Steak Sauce (per tbsp) | A1 | US | condiment | M | TODO | 2026-04-07 | | |
| 1569 | Butter for Cooking (per tbsp) | Various | US | cooking | H | TODO | 2026-04-07 | | |
| 1570 | Cocoa Powder Unsweetened (per tbsp) | Various | US | baking | M | TODO | 2026-04-07 | | |
| 1571 | Peanut Butter Generic Creamy (per tbsp) | Various | US | spread | H | TODO | 2026-04-07 | | |
| 1572 | Jelly Grape Generic (per tbsp) | Various | US | spread | M | TODO | 2026-04-07 | | |
| 1573 | Jam Strawberry Generic (per tbsp) | Various | US | spread | M | TODO | 2026-04-07 | | |
| 1574 | Hummus Classic (per tbsp) | Various | US | dip | H | TODO | 2026-04-07 | | |
| 1575 | Salsa Tomato (per tbsp) | Various | MX | condiment | M | TODO | 2026-04-07 | | |
| 1576 | Guacamole Fresh (per tbsp) | Various | MX | dip | H | TODO | 2026-04-07 | | |
| 1577 | Queso Dip (per tbsp) | Various | US | dip | M | TODO | 2026-04-07 | | |

## Section 67: Canned Goods & Pantry Staples (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1578 | Canned Pineapple Chunks in Juice (per serving) | Dole | US | fruit | M | TODO | 2026-04-07 | | |
| 1579 | Cashews Roasted Salted (per 30g) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 1580 | Walnuts Halves (per 30g) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 1581 | Mixed Nuts Planters (per 30g) | Planters | US | snack | M | TODO | 2026-04-07 | | |

## Section 68: Frozen Meals, Convenience & Snack Foods (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1582 | Hot Pocket Ham & Cheese (per pocket) | Hot Pockets | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1583 | Hungry-Man Salisbury Steak | Hungry-Man | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1584 | Jimmy Dean Sausage Egg Cheese Croissant (per piece) | Jimmy Dean | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1585 | Bagel Bites Cheese & Pepperoni (per 9 pieces) | Bagel Bites | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1586 | Tater Tots Ore-Ida (per serving) | Ore-Ida | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1587 | Fish Sticks Gorton's (per 6 sticks) | Gorton's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1588 | Corn Dog Frozen (per piece) | Various | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1589 | Mozzarella Sticks Frozen (per 3 sticks) | Various | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1590 | Pop-Tarts Frosted Strawberry (per pastry) | Pop-Tarts | US | breakfast | M | TODO | 2026-04-07 | | |
| 1591 | Little Debbie Oatmeal Creme Pie (per piece) | Little Debbie | US | snack | M | TODO | 2026-04-07 | | |
| 1592 | Little Debbie Cosmic Brownie (per piece) | Little Debbie | US | snack | M | TODO | 2026-04-07 | | |
| 1593 | Hostess Cupcakes Chocolate (per piece) | Hostess | US | snack | M | TODO | 2026-04-07 | | |
| 1594 | Hostess Donettes Mini Powdered (per 3 pieces) | Hostess | US | snack | M | TODO | 2026-04-07 | | |
| 1595 | Little Debbie Swiss Roll (per piece) | Little Debbie | US | snack | M | TODO | 2026-04-07 | | |
| 1596 | Fig Newtons (per 2 cookies) | Nabisco | US | snack | M | TODO | 2026-04-07 | | |
| 1597 | Nutri-Grain Bar Strawberry | Kellogg's | US | snack | M | TODO | 2026-04-07 | | |
| 1598 | Uncrustables PB&J Grape (per piece) | Smucker's | US | snack | M | TODO | 2026-04-07 | | Kids staple |
| 1599 | Lunchables Turkey & Cheddar | Oscar Mayer | US | snack | M | TODO | 2026-04-07 | | |
| 1600 | Baby Carrots (per serving ~85g) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 1601 | Celery with Peanut Butter (per serving) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 1602 | Apple Slices with Caramel Dip (per serving) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 1603 | Pudding Cup Jell-O Chocolate (per cup) | Jell-O | US | dessert | M | TODO | 2026-04-07 | | |
| 1604 | Jell-O Gelatin Strawberry (per cup) | Jell-O | US | dessert | M | TODO | 2026-04-07 | | |
| 1605 | Ramen Cup Noodle Chicken US (per cup) | Nissin | US | instant_noodle | H | TODO | 2026-04-07 | | College staple |
| 1606 | Velveeta Shells & Cheese (per serving) | Velveeta | US | pasta | M | TODO | 2026-04-07 | | |
| 1607 | Chef Boyardee Beef Ravioli (per serving) | Chef Boyardee | US | pasta | M | TODO | 2026-04-07 | | |
| 1608 | SpaghettiOs Original (per serving) | SpaghettiOs | US | pasta | M | TODO | 2026-04-07 | | |
| 1609 | Cup-a-Soup Chicken Noodle (per packet) | Lipton | US | soup | M | TODO | 2026-04-07 | | |

## Section 69: Holiday, Seasonal & Occasion Foods (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1610 | Stuffing Bread Thanksgiving (per serving) | Various | US | staple | M | TODO | 2026-04-07 | | |
| 1611 | Hot Apple Cider (per cup) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 1612 | Christmas Ham Glazed (per 100g) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 1613 | Candy Cane (per piece) | Various | US | confectionery | L | TODO | 2026-04-07 | | |
| 1614 | Easter Chocolate Egg Cadbury (per egg) | Cadbury | US | confectionery | M | TODO | 2026-04-07 | | |
| 1615 | Peeps Marshmallow (per 5 chicks) | Peeps | US | confectionery | L | TODO | 2026-04-07 | | |
| 1616 | Halloween Fun Size Snickers (per piece) | Mars | US | confectionery | M | TODO | 2026-04-07 | | |
| 1617 | Halloween Fun Size M&Ms (per pack) | Mars | US | confectionery | M | TODO | 2026-04-07 | | |
| 1618 | Super Bowl Wings Buffalo (per 6 wings) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 1619 | Game Day 7-Layer Dip (per serving) | Various | US | dip | M | TODO | 2026-04-07 | | |
| 1620 | Birthday Cake Slice Vanilla Frosted (per slice) | Various | US | dessert | H | TODO | 2026-04-07 | | |
| 1621 | Birthday Cake Slice Chocolate (per slice) | Various | US | dessert | M | TODO | 2026-04-07 | | |
| 1622 | Cupcake Frosted Vanilla (per cupcake) | Various | US | dessert | M | TODO | 2026-04-07 | | |
| 1623 | Brownie Homemade (per piece) | Various | US | dessert | H | TODO | 2026-04-07 | | |
| 1624 | Ice Cream Sundae Hot Fudge (per serving) | Various | US | dessert | M | TODO | 2026-04-07 | | |

---
# Batch 1: Cuisine-Specific Food Nutrition Overrides

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|

## Section 70: Chinese Regional Cuisine (150 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1625 | Sesame Chicken | Generic | CN | Entree | H | TODO | 2026-04-07 | | |
| 1626 | Pork Dumplings (steamed, 6 pcs) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | Jiaozi |
| 1627 | Pork Dumplings (pan-fried, 6 pcs) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | Guotie / potstickers |
| 1628 | Shrimp Dumplings (steamed, 4 pcs) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | Har gow |
| 1629 | Custard Bao (1 pc) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Liu sha bao |
| 1630 | Vegetable Bao (1 pc) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | |
| 1631 | Siu Yuk (crispy roast pork belly, per 100g) | Generic | CN | Protein | M | TODO | 2026-04-07 | | |
| 1632 | Zha Jiang Mian | Generic | CN | Noodles | M | TODO | 2026-04-07 | | Beijing-style soybean paste noodles |
| 1633 | Biang Biang Noodles | Generic | CN | Noodles | M | TODO | 2026-04-07 | | Shaanxi wide belt noodles |
| 1634 | Sichuan Boiled Fish (shui zhu yu) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Fish in chili oil broth |
| 1635 | Sichuan Boiled Beef (shui zhu niu rou) | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 1636 | Twice Cooked Pork (hui guo rou) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Sichuan stir-fried pork belly |
| 1637 | Moo Shu Pork | Generic | CN | Entree | M | TODO | 2026-04-07 | | With pancakes |
| 1638 | Walnut Shrimp | Generic | CN | Entree | M | TODO | 2026-04-07 | | With candied walnuts and mayo |
| 1639 | Hunan Chicken | Generic | CN | Entree | M | TODO | 2026-04-07 | | Spicy Hunan-style |
| 1640 | Black Pepper Beef | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 1641 | Ma La Xiang Guo (dry spicy pot) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Sichuan numbing spicy stir-fry |
| 1642 | Hot Pot Broth (spicy, per serving) | Generic | CN | Soup | H | TODO | 2026-04-07 | | Sichuan ma la tang base |
| 1643 | Hot Pot Broth (plain bone, per serving) | Generic | CN | Soup | M | TODO | 2026-04-07 | | |
| 1644 | Hot Pot Sliced Beef (per 100g) | Generic | CN | Protein | M | TODO | 2026-04-07 | | |
| 1645 | Hot Pot Sliced Lamb (per 100g) | Generic | CN | Protein | M | TODO | 2026-04-07 | | |
| 1646 | Stir-Fried Chinese Broccoli (gai lan) | Generic | CN | Vegetable | M | TODO | 2026-04-07 | | With oyster sauce |
| 1647 | Chinese Eggplant with Garlic Sauce | Generic | CN | Vegetable | M | TODO | 2026-04-07 | | Yu xiang qie zi |
| 1648 | Ma Po Eggplant | Generic | CN | Vegetable | M | TODO | 2026-04-07 | | |
| 1649 | Jian Bing (Chinese crepe) | Generic | CN | Breakfast | M | TODO | 2026-04-07 | | Street food breakfast |
| 1650 | Taiwanese Fried Chicken Cutlet | Generic | TW | Snack | M | TODO | 2026-04-07 | | Da ji pai |
| 1651 | Pepper Salt Chicken (yan su ji) | Generic | TW | Snack | M | TODO | 2026-04-07 | | |
| 1652 | Suan La Fen (hot and sour glass noodles) | Generic | CN | Noodles | M | TODO | 2026-04-07 | | Chongqing style |
| 1653 | Liangpi (cold skin noodles) | Generic | CN | Noodles | L | TODO | 2026-04-07 | | Shaanxi street food |
| 1654 | Rou Jia Mo (Chinese hamburger) | Generic | CN | Sandwich | M | TODO | 2026-04-07 | | Shaanxi cumin lamb burger |
| 1655 | Kung Pao Shrimp | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 1656 | Cumin Lamb (zi ran yang rou) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Xinjiang-style |
| 1657 | Lamb Skewers (yang rou chuan, 3 pcs) | Generic | CN | Appetizer | M | TODO | 2026-04-07 | | Xinjiang street food |
| 1658 | Ma La Tang (spicy soup, per bowl) | Generic | CN | Soup | M | TODO | 2026-04-07 | | Build-your-own hot pot soup |
| 1659 | Crispy Five Spice Tofu | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 1660 | Chicken with Black Bean Sauce | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 1661 | Shrimp with Lobster Sauce | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 1662 | Beef with Mixed Vegetables | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 1663 | West Lake Fish (xi hu cu yu) | Generic | CN | Entree | L | TODO | 2026-04-07 | | Zhejiang sweet vinegar fish |
| 1664 | Chairman Mao's Red Braised Pork | Generic | CN | Entree | M | TODO | 2026-04-07 | | Hunan variation |
| 1665 | Chili Oil Wontons (hong you chao shou) | Generic | CN | Appetizer | M | TODO | 2026-04-07 | | Sichuan style |
| 1666 | Hakka Salt Baked Chicken | Generic | CN | Entree | L | TODO | 2026-04-07 | | Yan ju ji |
| 1667 | Smashed Cucumber Salad | Generic | CN | Side | M | TODO | 2026-04-07 | | Pai huang gua |
| 1668 | Wood Ear Mushroom Salad | Generic | CN | Side | L | TODO | 2026-04-07 | | Liang ban mu er |
| 1669 | Glutinous Rice with Chicken (lo mai gai) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Wrapped in lotus leaf |
| 1670 | Taro Puff (wu gok, 1 pc) | Generic | CN | Dim Sum | L | TODO | 2026-04-07 | | Crispy fried taro dumpling |
| 1671 | Stuffed Tofu Skin Roll (fu pei guen) | Generic | CN | Dim Sum | L | TODO | 2026-04-07 | | |
| 1672 | Steamed Chicken Feet with Black Bean | Generic | CN | Dim Sum | L | TODO | 2026-04-07 | | Dim sum classic |
| 1673 | Pan-Fried Chive Dumplings (4 pcs) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Jiu cai he zi |
| 1674 | Sheng Jian Bao (4 pcs) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Shanghai pan-fried soup buns |
| 1675 | Doubanjiang Chicken | Generic | CN | Entree | M | TODO | 2026-04-07 | | Spicy bean paste chicken |

## Section 71: Japanese Cuisine Beyond Basics (120 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1676 | Yellowtail Nigiri (2 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Hamachi |
| 1677 | Shrimp Nigiri (2 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Ebi |
| 1678 | Eel Nigiri (2 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Unagi |
| 1679 | Octopus Nigiri (2 pcs) | Generic | JP | Sushi | L | TODO | 2026-04-07 | | Tako |
| 1680 | Fatty Tuna Nigiri (2 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Toro |
| 1681 | Tuna Sashimi (5 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | |
| 1682 | Spider Roll (8 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Soft shell crab |
| 1683 | Volcano Roll (8 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | |
| 1684 | Cucumber Roll (6 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Kappa maki |
| 1685 | Avocado Roll (6 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | |
| 1686 | Salmon Avocado Roll (8 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | |
| 1687 | Tantanmen (Japanese dan dan noodles) | Generic | JP | Noodles | M | TODO | 2026-04-07 | | Spicy sesame ramen |
| 1688 | Tempura Soba | Generic | JP | Noodles | M | TODO | 2026-04-07 | | |
| 1689 | Japanese Curry Rice | Generic | JP | Entree | H | TODO | 2026-04-07 | | With potato and carrot |
| 1690 | Okonomiyaki (Osaka-style) | Generic | JP | Entree | M | TODO | 2026-04-07 | | Savory pancake |
| 1691 | Teppanyaki Steak | Generic | JP | Entree | M | TODO | 2026-04-07 | | |
| 1692 | Grilled Saba (mackerel) | Generic | JP | Entree | M | TODO | 2026-04-07 | | |
| 1693 | Chirashi Bowl (assorted sashimi over rice) | Generic | JP | Rice Bowl | M | TODO | 2026-04-07 | | |
| 1694 | Japanese Cheesecake (1 slice) | Generic | JP | Dessert | M | TODO | 2026-04-07 | | Fluffy souffle style |
| 1695 | Dango (3 pcs on skewer) | Generic | JP | Dessert | M | TODO | 2026-04-07 | | Rice flour dumplings |
| 1696 | Japanese Milk Bread (shokupan, 1 slice) | Generic | JP | Bakery | M | TODO | 2026-04-07 | | |
| 1697 | Chashu Pork (per 2 slices) | Generic | JP | Topping | M | TODO | 2026-04-07 | | Braised pork belly for ramen |
| 1698 | Ajitama (marinated soft egg, 1 pc) | Generic | JP | Topping | M | TODO | 2026-04-07 | | Ramen egg |
| 1699 | Soba Salad | Generic | JP | Side | L | TODO | 2026-04-07 | | Cold buckwheat noodle salad |
| 1700 | Wagyu Beef Steak (per 100g) | Generic | JP | Entree | L | TODO | 2026-04-07 | | A5 grade |
| 1701 | Karaage Bento | Generic | JP | Bento | M | TODO | 2026-04-07 | | With rice and sides |
| 1702 | Salmon Bento | Generic | JP | Bento | M | TODO | 2026-04-07 | | With rice and sides |
| 1703 | Tamago Sando (egg sandwich) | Generic | JP | Sandwich | M | TODO | 2026-04-07 | | Japanese konbini egg salad |
| 1704 | Fruit Sando (fruit sandwich) | Generic | JP | Sandwich | L | TODO | 2026-04-07 | | Whipped cream and fruit |
| 1705 | Calpis/Calpico (1 cup) | Generic | JP | Beverage | L | TODO | 2026-04-07 | | |
| 1706 | Japanese Rice Crackers (senbei, 3 pcs) | Generic | JP | Snack | M | TODO | 2026-04-07 | | |
| 1707 | Miso Glazed Eggplant (nasu dengaku) | Generic | JP | Side | L | TODO | 2026-04-07 | | |
| 1708 | Hiroshima-style Okonomiyaki | Generic | JP | Entree | M | TODO | 2026-04-07 | | Layered with noodles |
| 1709 | Oyako Nanban | Generic | JP | Entree | L | TODO | 2026-04-07 | | |
| 1710 | Kakigori (shaved ice) | Generic | JP | Dessert | L | TODO | 2026-04-07 | | |
| 1711 | Castella Cake (1 slice) | Generic | JP | Dessert | L | TODO | 2026-04-07 | | Nagasaki sponge cake |
| 1712 | Japanese Hamburg Steak | Generic | JP | Entree | M | TODO | 2026-04-07 | | Hambagu with demi-glace |
| 1713 | Japanese Cream Stew | Generic | JP | Entree | M | TODO | 2026-04-07 | | White stew with chicken |

## Section 72: Korean Cuisine Full (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1714 | Daeji Bulgogi (spicy pork) | Generic | KR | BBQ | H | TODO | 2026-04-07 | | |
| 1715 | Galbi-jjim (braised short ribs) | Generic | KR | Entree | M | TODO | 2026-04-07 | | |
| 1716 | Ramyeon (Korean instant ramen, cooked) | Generic | KR | Noodles | H | TODO | 2026-04-07 | | |
| 1717 | Hobak Bokkeum (stir-fried zucchini) | Generic | KR | Banchan | L | TODO | 2026-04-07 | | |
| 1718 | Jeon - Pajeon (scallion pancake) | Generic | KR | Appetizer | H | TODO | 2026-04-07 | | |
| 1719 | Jeon - Haemul Pajeon (seafood pancake) | Generic | KR | Appetizer | M | TODO | 2026-04-07 | | |
| 1720 | Jeon - Kimchi Jeon (kimchi pancake) | Generic | KR | Appetizer | M | TODO | 2026-04-07 | | |
| 1721 | Jat Juk (pine nut porridge) | Generic | KR | Porridge | L | TODO | 2026-04-07 | | |
| 1722 | Cupbap (rice in a cup) | Generic | KR | Rice | M | TODO | 2026-04-07 | | |
| 1723 | Deopbap (topping rice, various) | Generic | KR | Rice | M | TODO | 2026-04-07 | | |
| 1724 | Gamjajeon (potato pancake) | Generic | KR | Appetizer | L | TODO | 2026-04-07 | | |
| 1725 | Bungeo-ppang Ice Cream | Generic | KR | Dessert | L | TODO | 2026-04-07 | | |
| 1726 | Soondae Gukbap (blood sausage soup) | Generic | KR | Soup | M | TODO | 2026-04-07 | | |
| 1727 | Odeng/Eomuk (fish cake on stick, 1 skewer) | Generic | KR | Snack | M | TODO | 2026-04-07 | | |
| 1728 | Tornado Potato (1 skewer) | Generic | KR | Snack | L | TODO | 2026-04-07 | | Street food |
| 1729 | Gyeran-ppang (egg bread, 1 pc) | Generic | KR | Snack | M | TODO | 2026-04-07 | | Street food |
| 1730 | Haemul Ttukbaegi (seafood hot pot) | Generic | KR | Stew | M | TODO | 2026-04-07 | | |
| 1731 | Korean Cheese Corn | Generic | KR | Side | M | TODO | 2026-04-07 | | Sweet corn with mayo and cheese |
| 1732 | Korean Fish Cake Stir-Fry (eomuk bokkeum) | Generic | KR | Banchan | M | TODO | 2026-04-07 | | |
| 1733 | Soondubu with Rice Set | Generic | KR | Entree | H | TODO | 2026-04-07 | | Restaurant set meal |
| 1734 | Korean BBQ Combo (samgyeopsal set for 1) | Generic | KR | BBQ | H | TODO | 2026-04-07 | | With sides and rice |

## Section 73: Thai Cuisine Full (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1735 | Green Curry with Chicken | Generic | TH | Curry | H | TODO | 2026-04-07 | | Gaeng keow wan |
| 1736 | Green Curry with Shrimp | Generic | TH | Curry | M | TODO | 2026-04-07 | | |
| 1737 | Red Curry with Chicken | Generic | TH | Curry | H | TODO | 2026-04-07 | | Gaeng daeng |
| 1738 | Red Curry with Beef | Generic | TH | Curry | M | TODO | 2026-04-07 | | |
| 1739 | Yellow Curry with Chicken | Generic | TH | Curry | M | TODO | 2026-04-07 | | Gaeng luang |
| 1740 | Jungle Curry (gaeng pa) | Generic | TH | Curry | L | TODO | 2026-04-07 | | No coconut milk |
| 1741 | Drunken Noodles (pad kee mao, chicken) | Generic | TH | Noodles | H | TODO | 2026-04-07 | | Spicy basil noodles |
| 1742 | Drunken Noodles (pad kee mao, beef) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | |
| 1743 | Boat Noodles (kuay teow reua) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | Rich dark broth |
| 1744 | Khao Soi (Northern Thai curry noodle) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | Chiang Mai specialty |
| 1745 | Tom Yum Gai (chicken) | Generic | TH | Soup | M | TODO | 2026-04-07 | | |
| 1746 | Nam Tok (waterfall beef salad) | Generic | TH | Salad | M | TODO | 2026-04-07 | | |
| 1747 | Thai Basil Chicken (pad krapao gai) | Generic | TH | Entree | H | TODO | 2026-04-07 | | With fried egg on rice |
| 1748 | Thai Basil Pork (pad krapao moo) | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 1749 | Garlic Pepper Shrimp | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 1750 | Sweet Chili Fish (pla rad prik) | Generic | TH | Entree | M | TODO | 2026-04-07 | | Fried fish with chili sauce |
| 1751 | Crying Tiger (suea rong hai) | Generic | TH | Entree | M | TODO | 2026-04-07 | | Grilled beef with jaew sauce |
| 1752 | Kao Man Gai (Thai chicken rice) | Generic | TH | Rice | M | TODO | 2026-04-07 | | |
| 1753 | Satay Pork (4 skewers) | Generic | TH | Appetizer | M | TODO | 2026-04-07 | | |
| 1754 | Thai Fish Cakes (tod mun pla, 4 pcs) | Generic | TH | Appetizer | M | TODO | 2026-04-07 | | |
| 1755 | Moo Ping (grilled pork skewers, 3 pcs) | Generic | TH | Street Food | H | TODO | 2026-04-07 | | |
| 1756 | Roti with Banana and Condensed Milk | Generic | TH | Dessert | M | TODO | 2026-04-07 | | Street food |
| 1757 | Thai Custard (sangkaya) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 1758 | Khanom Buang (Thai crispy crepe) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 1759 | Tab Tim Grob (water chestnut in coconut) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 1760 | Thai Iced Coffee | Generic | TH | Beverage | M | TODO | 2026-04-07 | | Oliang |
| 1761 | Pad Prik King (stir-fry with curry paste) | Generic | TH | Entree | M | TODO | 2026-04-07 | | With green beans |
| 1762 | Pla Pao (salt-crusted grilled fish) | Generic | TH | Entree | L | TODO | 2026-04-07 | | |
| 1763 | Gaeng Som (sour curry) | Generic | TH | Curry | L | TODO | 2026-04-07 | | Southern Thai |
| 1764 | Isaan Sausage (sai krok Isaan, 2 pcs) | Generic | TH | Street Food | L | TODO | 2026-04-07 | | Fermented pork sausage |
| 1765 | Panaeng Salmon | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 1766 | Thai Omelette (kai jeow) | Generic | TH | Entree | M | TODO | 2026-04-07 | | Crispy deep-fried omelette |
| 1767 | Steamed Sea Bass with Lime (pla neung manao) | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 1768 | Rad Na (gravy noodles) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | Wide noodles in thick gravy |
| 1769 | Bua Loy (glutinous rice balls in coconut) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 1770 | Luk Chup (mung bean sweets, 3 pcs) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 1771 | Kao Niew Tua Dam (black bean sticky rice) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 1772 | Gaeng Hung Lay (Northern Thai pork curry) | Generic | TH | Curry | L | TODO | 2026-04-07 | | Burmese-influenced |
| 1773 | Thai Pork Neck (kor moo yang) | Generic | TH | Entree | M | TODO | 2026-04-07 | | Grilled with jaew |
| 1774 | Khao Ka Moo (pork leg on rice) | Generic | TH | Rice | M | TODO | 2026-04-07 | | Braised pork trotter |
| 1775 | Bamee Moo Daeng (egg noodle with red pork) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | |
| 1776 | Thai Milk Tea (hot) | Generic | TH | Beverage | M | TODO | 2026-04-07 | | |

## Section 74: Vietnamese Cuisine Full (70 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1777 | Pho Tai (rare beef pho) | Generic | VN | Soup | H | TODO | 2026-04-07 | | |
| 1778 | Pho Dac Biet (special combo pho) | Generic | VN | Soup | H | TODO | 2026-04-07 | | With tendon, tripe, meatball |
| 1779 | Banh Mi Thit (classic pork banh mi) | Generic | VN | Sandwich | H | TODO | 2026-04-07 | | With pate, pickled veg, cilantro |
| 1780 | Banh Mi Trung (fried egg banh mi) | Generic | VN | Sandwich | M | TODO | 2026-04-07 | | |
| 1781 | Banh Mi Xiu Mai (meatball banh mi) | Generic | VN | Sandwich | M | TODO | 2026-04-07 | | |
| 1782 | Banh Mi Chao (pate and butter banh mi) | Generic | VN | Sandwich | M | TODO | 2026-04-07 | | |
| 1783 | Bun Oc (snail noodle soup) | Generic | VN | Soup | L | TODO | 2026-04-07 | | Hanoi specialty |
| 1784 | Bun Mam (fermented fish noodle soup) | Generic | VN | Soup | L | TODO | 2026-04-07 | | Mekong Delta |
| 1785 | Com Tam Suon Bi Cha | Generic | VN | Rice | H | TODO | 2026-04-07 | | Broken rice with pork chop, skin, egg cake |
| 1786 | Banh Khot (mini crispy pancakes) | Generic | VN | Appetizer | M | TODO | 2026-04-07 | | With shrimp |
| 1787 | Bo La Lot (beef in betel leaf, 3 pcs) | Generic | VN | Appetizer | M | TODO | 2026-04-07 | | |
| 1788 | Ca Kho To (caramelized fish in clay pot) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 1789 | Thit Kho (caramelized pork belly with eggs) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 1790 | Suon Nuong (grilled pork chops) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 1791 | Goi Du Du (green papaya salad) | Generic | VN | Salad | M | TODO | 2026-04-07 | | With dried beef |
| 1792 | Goi Ngo Sen (lotus stem salad) | Generic | VN | Salad | L | TODO | 2026-04-07 | | |
| 1793 | Lau (Vietnamese hot pot, per serving) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 1794 | Mi Quang (turmeric noodles, Da Nang) | Generic | VN | Noodles | M | TODO | 2026-04-07 | | Central Vietnamese |
| 1795 | Cao Lau (Hoi An noodles) | Generic | VN | Noodles | L | TODO | 2026-04-07 | | |
| 1796 | Banh Canh (thick noodle soup) | Generic | VN | Soup | M | TODO | 2026-04-07 | | |
| 1797 | Nem Nuong (grilled pork sausage) | Generic | VN | Appetizer | M | TODO | 2026-04-07 | | |
| 1798 | Vietnamese Coffee (ca phe sua da) | Generic | VN | Beverage | H | TODO | 2026-04-07 | | Iced with condensed milk |
| 1799 | Vietnamese Coffee (ca phe den da) | Generic | VN | Beverage | M | TODO | 2026-04-07 | | Iced black |
| 1800 | Vietnamese Coffee (ca phe trung) | Generic | VN | Beverage | M | TODO | 2026-04-07 | | Egg coffee, Hanoi-style |
| 1801 | Vietnamese Coffee (bac xiu) | Generic | VN | Beverage | M | TODO | 2026-04-07 | | White coffee |
| 1802 | Sinh To Bo (avocado smoothie) | Generic | VN | Beverage | M | TODO | 2026-04-07 | | Vietnamese-style with condensed milk |
| 1803 | Nuoc Mia (sugarcane juice) | Generic | VN | Beverage | L | TODO | 2026-04-07 | | |
| 1804 | Che Ba Mau (three-color dessert) | Generic | VN | Dessert | M | TODO | 2026-04-07 | | Beans, jelly, coconut |
| 1805 | Che Chuoi (banana in coconut milk) | Generic | VN | Dessert | L | TODO | 2026-04-07 | | |
| 1806 | Banh Flan (Vietnamese creme caramel) | Generic | VN | Dessert | M | TODO | 2026-04-07 | | With coffee |
| 1807 | Banh Bao (steamed bun, 1 pc) | Generic | VN | Snack | M | TODO | 2026-04-07 | | With pork and egg |
| 1808 | Banh Gio (pyramid rice dumpling, 1 pc) | Generic | VN | Snack | L | TODO | 2026-04-07 | | |
| 1809 | Bun Dau Mam Tom (tofu with shrimp paste) | Generic | VN | Entree | L | TODO | 2026-04-07 | | Hanoi specialty |
| 1810 | Banh Bot Loc (tapioca dumplings, 5 pcs) | Generic | VN | Appetizer | L | TODO | 2026-04-07 | | Hue specialty |
| 1811 | Banh Nam (flat steamed rice cake, 3 pcs) | Generic | VN | Appetizer | L | TODO | 2026-04-07 | | Hue specialty |
| 1812 | Pho Xao (stir-fried pho noodles) | Generic | VN | Noodles | M | TODO | 2026-04-07 | | |
| 1813 | Bo Ne (Vietnamese sizzling steak) | Generic | VN | Entree | M | TODO | 2026-04-07 | | With egg and bread |
| 1814 | Com Ga Xoi Mo (crispy chicken rice) | Generic | VN | Rice | M | TODO | 2026-04-07 | | |
| 1815 | Banh Trang Tron (mixed rice paper snack) | Generic | VN | Snack | L | TODO | 2026-04-07 | | Saigon street food |
| 1816 | Bun Moc (pork ball noodle soup) | Generic | VN | Soup | M | TODO | 2026-04-07 | | |
| 1817 | Rau Muong Xao Toi (stir-fried morning glory) | Generic | VN | Vegetable | M | TODO | 2026-04-07 | | With garlic |
| 1818 | Dau Hu Chien (fried tofu with lemongrass) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 1819 | Banh Cong (shrimp and pork fritter) | Generic | VN | Snack | L | TODO | 2026-04-07 | | |
| 1820 | Bap Xao (Vietnamese corn stir-fry) | Generic | VN | Side | L | TODO | 2026-04-07 | | With dried shrimp and scallion |
| 1821 | Bo Kho (Vietnamese beef stew) | Generic | VN | Soup | M | TODO | 2026-04-07 | | With bread or noodles |
| 1822 | Goi Cuon Tom Thit (spring roll with shrimp/pork) | Generic | VN | Appetizer | H | TODO | 2026-04-07 | | |
| 1823 | Chao (Vietnamese rice porridge) | Generic | VN | Porridge | M | TODO | 2026-04-07 | | |

## Section 75: Indian Regional - North Indian Full (150 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1824 | Malai Tikka (cream marinated chicken, 6 pcs) | Generic | IN | Appetizer | M | TODO | 2026-04-07 | | |
| 1825 | Galawati Kebab (2 pcs) | Generic | IN | Appetizer | M | TODO | 2026-04-07 | | Lucknow melt-in-mouth kebab |
| 1826 | Reshmi Kebab (2 pcs) | Generic | IN | Appetizer | M | TODO | 2026-04-07 | | Cream and egg marinated |
| 1827 | Plain Naan (1 pc) | Generic | IN | Bread | H | TODO | 2026-04-07 | | |
| 1828 | Chapati/Roti (1 pc) | Generic | IN | Bread | H | TODO | 2026-04-07 | | Plain whole wheat flatbread |
| 1829 | Chicken Changezi | Generic | IN | Entree | M | TODO | 2026-04-07 | | Delhi Mughlai style |
| 1830 | Matar Mushroom | Generic | IN | Entree | M | TODO | 2026-04-07 | | Peas and mushroom curry |
| 1831 | Chicken Do Pyaza | Generic | IN | Entree | M | TODO | 2026-04-07 | | Double onion chicken |
| 1832 | Butter Dal (dal fry with butter) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 1833 | Chicken Mughlai | Generic | IN | Entree | M | TODO | 2026-04-07 | | Rich egg-based gravy |
| 1834 | Butter Paneer | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 1835 | Paneer Lababdar | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 1836 | Paranthe Wali Gali Paratha | Generic | IN | Bread | M | TODO | 2026-04-07 | | Delhi street-style stuffed paratha |
| 1837 | Ram Ladoo (6 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Delhi street food moong dal fritter |
| 1838 | Chhole Kulche (Delhi street) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Delhi street food |
| 1839 | Daulat Ki Chaat | Generic | IN | Dessert | L | TODO | 2026-04-07 | | Delhi winter milk foam |
| 1840 | Chole Chawal | Generic | IN | Entree | H | TODO | 2026-04-07 | | Chickpea curry with rice |
| 1841 | Kadhi Chawal | Generic | IN | Entree | M | TODO | 2026-04-07 | | Yogurt curry with rice |
| 1842 | Murgh Musallam | Generic | IN | Entree | L | TODO | 2026-04-07 | | Whole roasted chicken Mughlai |
| 1843 | Mushroom Matar | Generic | IN | Entree | M | TODO | 2026-04-07 | | Mushroom and peas curry |
| 1844 | Mutton Rara | Generic | IN | Entree | M | TODO | 2026-04-07 | | Mutton with keema |
| 1845 | Bedmi Puri with Aloo (2 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Delhi breakfast |
| 1846 | Rabdi Jalebi | Generic | IN | Dessert | M | TODO | 2026-04-07 | | Jalebi with thickened milk |

## Section 76: Indian Regional - South Indian Full (120 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1847 | Mini Idli with Sambar (per bowl) | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 1848 | Vada Sambar | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Vada soaked in sambar |
| 1849 | Sweet Pongal (sakkarai pongal) | Generic | IN | Dessert | M | TODO | 2026-04-07 | | Jaggery rice |
| 1850 | Kerala Parotta (1 pc) | Generic | IN | Bread | M | TODO | 2026-04-07 | | Flaky layered bread |
| 1851 | Kerala Chicken Fry | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 1852 | Kerala Prawn Curry | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 1853 | Kerala Egg Curry | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 1854 | Pachadi (yogurt side dish) | Generic | IN | Side | M | TODO | 2026-04-07 | | Kerala sadya item |
| 1855 | Kerala Sadya Meal (full) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Full banana leaf feast |
| 1856 | Gojju (tamarind curry) | Generic | IN | Side | L | TODO | 2026-04-07 | | Karnataka style |
| 1857 | Chicken Chettinad | Generic | IN | Entree | H | TODO | 2026-04-07 | | Tamil Nadu spicy pepper chicken |
| 1858 | Bisi Bele Hulianna | Generic | IN | Rice | L | TODO | 2026-04-07 | | |
| 1859 | Hyderabadi Mirchi Ka Salan | Generic | IN | Side | M | TODO | 2026-04-07 | | Green chili curry |
| 1860 | Palada Payasam | Generic | IN | Dessert | L | TODO | 2026-04-07 | | Kerala rice flake pudding |
| 1861 | Panagam | Generic | IN | Beverage | L | TODO | 2026-04-07 | | Jaggery ginger drink |
| 1862 | Neer Mor (spiced buttermilk) | Generic | IN | Beverage | M | TODO | 2026-04-07 | | |
| 1863 | Telangana Maamsam (mutton fry) | Generic | IN | Entree | L | TODO | 2026-04-07 | | |
| 1864 | Andhra Pappu (dal with greens) | Generic | IN | Side | M | TODO | 2026-04-07 | | |
| 1865 | Pesarattu Upma | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Moong dosa with upma stuffing |
| 1866 | Podi Idli (gunpowder spice idli) | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 1867 | Ghee Podi Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Dosa with spice powder and ghee |
| 1868 | Paniyaram (sweet, 6 pcs) | Generic | IN | Snack | L | TODO | 2026-04-07 | | |
| 1869 | Parotta Salna | Generic | IN | Entree | M | TODO | 2026-04-07 | | Parotta with spiced gravy |
| 1870 | Kozhi Varuval (Tamil chicken fry) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 1871 | Meen Varuval (Tamil fish fry) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 1872 | Kerala Unniyappam (6 pcs) | Generic | IN | Snack | L | TODO | 2026-04-07 | | Sweet rice and banana balls |
| 1873 | Nei Dosa (ghee dosa) | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 1874 | Chicken Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 1875 | Paneer Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 1876 | Spring Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Chinese-Indian fusion |
| 1877 | Ulundu Vadai (2 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Urad dal vada |
| 1878 | Bajji/Pakoda (banana, 3 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Battered banana fritters |
| 1879 | Avakaya (Andhra mango pickle, per tbsp) | Generic | IN | Condiment | L | TODO | 2026-04-07 | | |
| 1880 | Thogayal (per tbsp) | Generic | IN | Condiment | L | TODO | 2026-04-07 | | Tamil thick chutney |
| 1881 | Kesari (semolina sweet) | Generic | IN | Dessert | M | TODO | 2026-04-07 | | |
| 1882 | Banana Bonda (2 pcs) | Generic | IN | Snack | L | TODO | 2026-04-07 | | Banana fritters |
| 1883 | Uzhunnu Vada (2 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Kerala urad dal vada |

## Section 77: Indian Regional - East & West (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1884 | Machher Jhol (Bengali fish curry) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Everyday fish curry |
| 1885 | Aloo Dum (Bengali-style) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Baby potatoes in gravy |
| 1886 | Fish Fry (Bengali kolkata-style) | Generic | IN | Appetizer | M | TODO | 2026-04-07 | | Crumb-coated fish cutlet |
| 1887 | Sondesh Varieties (nolen gur, 2 pcs) | Generic | IN | Dessert | M | TODO | 2026-04-07 | | Date palm jaggery flavored |
| 1888 | Misti Pulao (sweet rice) | Generic | IN | Rice | L | TODO | 2026-04-07 | | Bengali wedding rice |
| 1889 | Khar (Assamese alkaline dish) | Generic | IN | Side | L | TODO | 2026-04-07 | | |
| 1890 | Goa Fish Curry (Xitt Kodi) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Coconut-based with kokum |
| 1891 | Goan Vindaloo (pork) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Spicy vinegar-based curry |
| 1892 | Goan Vindaloo (chicken) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 1893 | Goan Xacuti (chicken) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Roasted spice coconut curry |
| 1894 | Pork Sorpotel | Generic | IN | Entree | L | TODO | 2026-04-07 | | Goan Portuguese-influenced |
| 1895 | Dal Bafla (MP-style dal baati) | Generic | IN | Entree | L | TODO | 2026-04-07 | | |
| 1896 | Mawa Bati (1 pc) | Generic | IN | Dessert | L | TODO | 2026-04-07 | | MP milk-based sweet |
| 1897 | Alur Chop (potato croquette, 1 pc) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Bengali |
| 1898 | Posto Bora (poppy seed fritters, 4 pcs) | Generic | IN | Side | L | TODO | 2026-04-07 | | Bengali |
| 1899 | Paturi (fish in banana leaf) | Generic | IN | Entree | L | TODO | 2026-04-07 | | Bengali |
| 1900 | Mangsher Chop (mutton cutlet, 1 pc) | Generic | IN | Snack | L | TODO | 2026-04-07 | | Bengali |
| 1901 | Macher Kalia (fish in rich gravy) | Generic | IN | Entree | L | TODO | 2026-04-07 | | Bengali celebration dish |
| 1902 | Koraishutir Kochuri (pea kachori, 1 pc) | Generic | IN | Snack | L | TODO | 2026-04-07 | | Bengali winter special |

## Section 78: Mexican Cuisine Full (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1903 | Birria Tacos (3 pcs) | Generic | MX | Tacos | H | TODO | 2026-04-07 | | With consomme for dipping |
| 1904 | Tacos de Asada (3 pcs) | Generic | MX | Tacos | H | TODO | 2026-04-07 | | Grilled steak |
| 1905 | Tacos de Chorizo (3 pcs) | Generic | MX | Tacos | M | TODO | 2026-04-07 | | |
| 1906 | Tacos de Cabeza (3 pcs) | Generic | MX | Tacos | L | TODO | 2026-04-07 | | Beef head meat |
| 1907 | Tacos de Tripa (3 pcs) | Generic | MX | Tacos | L | TODO | 2026-04-07 | | Tripe |
| 1908 | Cheese Enchiladas (3 pcs) | Generic | MX | Entree | M | TODO | 2026-04-07 | | |
| 1909 | Beef Burrito | Generic | MX | Entree | H | TODO | 2026-04-07 | | |
| 1910 | Chicken Burrito | Generic | MX | Entree | H | TODO | 2026-04-07 | | |
| 1911 | Bean and Cheese Burrito | Generic | MX | Entree | H | TODO | 2026-04-07 | | |
| 1912 | Chicken Tamale (1 pc) | Generic | MX | Entree | H | TODO | 2026-04-07 | | Steamed corn masa |
| 1913 | Sweet Tamale (1 pc) | Generic | MX | Entree | M | TODO | 2026-04-07 | | With raisins or pineapple |
| 1914 | Tamale Verde (1 pc) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Green sauce chicken |
| 1915 | Torta de Jamon | Generic | MX | Sandwich | M | TODO | 2026-04-07 | | Ham sandwich |
| 1916 | Tlacoyos (2 pcs) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Stuffed oval corn cakes |
| 1917 | Flautas (3 pcs) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Rolled and fried tacos |
| 1918 | Aguachile (shrimp) | Generic | MX | Appetizer | M | TODO | 2026-04-07 | | Raw shrimp in chili lime |
| 1919 | Mexican Ceviche (per serving) | Generic | MX | Appetizer | M | TODO | 2026-04-07 | | |
| 1920 | Mexican Rice (per serving) | Generic | MX | Side | H | TODO | 2026-04-07 | | Arroz rojo |
| 1921 | Nopal Salad | Generic | MX | Side | M | TODO | 2026-04-07 | | Cactus paddle salad |
| 1922 | Chips and Salsa (per basket) | Generic | MX | Appetizer | H | TODO | 2026-04-07 | | Restaurant-style |
| 1923 | Chamoyada (mango) | Generic | MX | Beverage | M | TODO | 2026-04-07 | | Frozen fruit with chamoy |
| 1924 | Mexican Hot Chocolate (per cup) | Generic | MX | Beverage | M | TODO | 2026-04-07 | | With cinnamon |
| 1925 | Chimichanga (beef) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Deep-fried burrito |
| 1926 | Taquitos (5 pcs) | Generic | MX | Snack | M | TODO | 2026-04-07 | | Rolled corn tacos, fried |
| 1927 | Cochinita Pibil Tacos (3 pcs) | Generic | MX | Tacos | M | TODO | 2026-04-07 | | Yucatan slow-roasted pork |
| 1928 | Bionico | Generic | MX | Dessert | M | TODO | 2026-04-07 | | Mexican fruit cup with cream |
| 1929 | Mangonada | Generic | MX | Beverage | M | TODO | 2026-04-07 | | Mango smoothie with chamoy |
| 1930 | Corn in a Cup (elote en vaso) | Generic | MX | Side | M | TODO | 2026-04-07 | | Street vendor style |
| 1931 | Migas (Mexican scrambled) | Generic | MX | Breakfast | M | TODO | 2026-04-07 | | Eggs with fried tortilla strips |
| 1932 | Birria Ramen | Generic | MX | Noodles | M | TODO | 2026-04-07 | | Fusion dish |
| 1933 | Tacos Dorados (3 pcs) | Generic | MX | Tacos | M | TODO | 2026-04-07 | | Golden fried tacos |

## Section 79: Italian Cuisine Full (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1934 | Spaghetti Puttanesca | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Olives, capers, anchovy |
| 1935 | Pesto Pasta (basil) | Generic | IT | Pasta | H | TODO | 2026-04-07 | | Genovese pesto |
| 1936 | Aglio e Olio | Generic | IT | Pasta | H | TODO | 2026-04-07 | | Garlic and olive oil |
| 1937 | Penne alla Vodka | Generic | IT | Pasta | H | TODO | 2026-04-07 | | Creamy tomato vodka sauce |
| 1938 | Gnocchi with Tomato Sauce | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 1939 | Gnocchi with Pesto | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 1940 | Gnocchi with Gorgonzola Cream | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 1941 | Antipasto Platter (per serving) | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Cured meats, cheese, olives |
| 1942 | Carpaccio (beef) | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Thin raw beef |
| 1943 | Calamari Fritti | Generic | IT | Appetizer | H | TODO | 2026-04-07 | | Fried squid |
| 1944 | Eggplant Parmigiana | Generic | IT | Entree | M | TODO | 2026-04-07 | | |
| 1945 | Veal Piccata | Generic | IT | Entree | M | TODO | 2026-04-07 | | Lemon caper sauce |
| 1946 | Veal Marsala | Generic | IT | Entree | M | TODO | 2026-04-07 | | Marsala wine sauce |
| 1947 | Chicken Marsala | Generic | IT | Entree | M | TODO | 2026-04-07 | | |
| 1948 | Italian Wedding Soup | Generic | IT | Soup | M | TODO | 2026-04-07 | | With meatballs |
| 1949 | Stracciatella Soup | Generic | IT | Soup | L | TODO | 2026-04-07 | | Italian egg drop soup |
| 1950 | Italian Panini (prosciutto mozzarella) | Generic | IT | Sandwich | M | TODO | 2026-04-07 | | |
| 1951 | Porchetta Sandwich | Generic | IT | Sandwich | M | TODO | 2026-04-07 | | Herb-roasted pork |
| 1952 | Italian Sub/Hero | Generic | IT | Sandwich | H | TODO | 2026-04-07 | | Salami, capicola, provolone |
| 1953 | Italian Espresso (1 shot) | Generic | IT | Beverage | H | TODO | 2026-04-07 | | |
| 1954 | Orecchiette with Broccoli Rabe | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Pugliese |
| 1955 | Linguine with Pesto | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 1956 | Pappardelle with Wild Boar Ragu | Generic | IT | Pasta | L | TODO | 2026-04-07 | | Tuscan |
| 1957 | Rigatoni alla Gricia | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Guanciale and pecorino |
| 1958 | Stuffed Shells (5 pcs) | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Ricotta-filled conchiglioni |
| 1959 | Manicotti (2 pcs) | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Stuffed pasta tubes |
| 1960 | Biscotti (2 pcs) | Generic | IT | Dessert | M | TODO | 2026-04-07 | | Almond twice-baked cookies |
| 1961 | Sfogliatella (1 pc) | Generic | IT | Dessert | L | TODO | 2026-04-07 | | Neapolitan pastry |
| 1962 | Fritto Misto | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Mixed fried seafood |
| 1963 | Crostini (3 pcs) | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Toasted bread with toppings |
| 1964 | Suppli (fried rice balls, 2 pcs) | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Roman-style |
| 1965 | Polenta Fries | Generic | IT | Side | M | TODO | 2026-04-07 | | Fried polenta sticks |
| 1966 | Insalata Mista | Generic | IT | Side | M | TODO | 2026-04-07 | | Mixed Italian salad |
| 1967 | Pizza Bianca (1 slice) | Generic | IT | Pizza | M | TODO | 2026-04-07 | | White pizza |
| 1968 | Amaretti Cookies (3 pcs) | Generic | IT | Dessert | L | TODO | 2026-04-07 | | Almond macaroons |

## Section 80: Mediterranean & Greek (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1969 | Chicken Gyro (sandwich) | Generic | GR | Sandwich | H | TODO | 2026-04-07 | | With tzatziki and pita |
| 1970 | Lamb Gyro (sandwich) | Generic | GR | Sandwich | H | TODO | 2026-04-07 | | |
| 1971 | Gyro Plate (chicken) | Generic | GR | Entree | H | TODO | 2026-04-07 | | With rice and salad |
| 1972 | Chicken Souvlaki (2 skewers) | Generic | GR | Entree | H | TODO | 2026-04-07 | | |
| 1973 | Pork Souvlaki (2 skewers) | Generic | GR | Entree | M | TODO | 2026-04-07 | | |
| 1974 | Saganaki (fried cheese) | Generic | GR | Appetizer | M | TODO | 2026-04-07 | | Flaming cheese |
| 1975 | Greek Lemon Chicken | Generic | GR | Entree | M | TODO | 2026-04-07 | | With potatoes |
| 1976 | Greek Lamb Chops | Generic | GR | Entree | M | TODO | 2026-04-07 | | |
| 1977 | Fasolada (Greek bean soup) | Generic | GR | Soup | M | TODO | 2026-04-07 | | |
| 1978 | Manakish Cheese (1 pc) | Generic | LB | Bread | M | TODO | 2026-04-07 | | |
| 1979 | Gozleme (spinach and cheese) | Generic | TR | Entree | M | TODO | 2026-04-07 | | Stuffed flatbread |
| 1980 | Turkish Manti (per serving) | Generic | TR | Entree | M | TODO | 2026-04-07 | | Tiny dumplings with yogurt |
| 1981 | Turkish Coffee (1 cup) | Generic | TR | Beverage | M | TODO | 2026-04-07 | | |
| 1982 | Falafel Plate (6 pcs with sides) | Generic | IL | Entree | H | TODO | 2026-04-07 | | |
| 1983 | Falafel Pita Sandwich | Generic | IL | Sandwich | H | TODO | 2026-04-07 | | |
| 1984 | Israeli Schnitzel (chicken) | Generic | IL | Entree | M | TODO | 2026-04-07 | | In pita or on plate |
| 1985 | Moroccan Mint Tea (1 cup) | Generic | MA | Beverage | M | TODO | 2026-04-07 | | |
| 1986 | Warak Enab (stuffed vine leaves, 5 pcs) | Generic | LB | Appetizer | M | TODO | 2026-04-07 | | |

## Section 81: Latin American Cuisine (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 1987 | Pastel (fried, 1 pc) | Generic | BR | Snack | M | TODO | 2026-04-07 | | Fried pastry with filling |
| 1988 | Churrasco Plate (mixed meats) | Generic | BR | Entree | M | TODO | 2026-04-07 | | Brazilian BBQ assortment |
| 1989 | Guarana Soda (1 can) | Generic | BR | Beverage | M | TODO | 2026-04-07 | | |
| 1990 | Asado Tira de Costilla (short ribs) | Generic | AR | Entree | M | TODO | 2026-04-07 | | Argentine BBQ ribs |
| 1991 | Argentine Empanada (beef, 1 pc) | Generic | AR | Snack | M | TODO | 2026-04-07 | | |
| 1992 | Argentine Empanada (ham and cheese, 1 pc) | Generic | AR | Snack | M | TODO | 2026-04-07 | | |
| 1993 | Choripan | Generic | AR | Sandwich | M | TODO | 2026-04-07 | | Chorizo sandwich with chimichurri |
| 1994 | Pisco Sour | Generic | PE | Alcohol | M | TODO | 2026-04-07 | | |
| 1995 | Arepa con Huevo (1 pc) | Generic | CO | Breakfast | M | TODO | 2026-04-07 | | Fried arepa with egg inside |
| 1996 | Colombian Empanada (1 pc) | Generic | CO | Snack | M | TODO | 2026-04-07 | | Fried corn empanada |
| 1997 | Chilean Empanada de Pino (1 pc) | Generic | CL | Snack | M | TODO | 2026-04-07 | | Beef with egg and olive |
| 1998 | Cazuela (Chilean, per serving) | Generic | CL | Soup | L | TODO | 2026-04-07 | | Meat and vegetable stew |
| 1999 | Arepa Reina Pepiada (1 pc) | Generic | VE | Sandwich | M | TODO | 2026-04-07 | | Venezuelan chicken avocado arepa |
| 2000 | Arepa de Pabellon (1 pc) | Generic | VE | Sandwich | M | TODO | 2026-04-07 | | Shredded beef, beans, plantain |
| 2001 | Arepa de Jamon y Queso (1 pc) | Generic | VE | Sandwich | M | TODO | 2026-04-07 | | Ham and cheese |
| 2002 | Pabellon Criollo | Generic | VE | Entree | M | TODO | 2026-04-07 | | Shredded beef, rice, beans, plantain |
| 2003 | Tequenos (5 pcs) | Generic | VE | Snack | M | TODO | 2026-04-07 | | Cheese-filled fried sticks |
| 2004 | Pupusa (cheese, 1 pc) | Generic | SV | Bread | M | TODO | 2026-04-07 | | Salvadoran stuffed corn cake |
| 2005 | Baleada (1 pc) | Generic | HN | Bread | M | TODO | 2026-04-07 | | Honduran flour tortilla with beans and cheese |
| 2006 | Ceviche Ecuatoriano | Generic | EC | Appetizer | L | TODO | 2026-04-07 | | With popcorn garnish |
| 2007 | Saltenas (1 pc) | Generic | BO | Snack | L | TODO | 2026-04-07 | | Bolivian juicy empanada |
| 2008 | Tres Golpes (Dominican breakfast) | Generic | DO | Breakfast | L | TODO | 2026-04-07 | | Mangu, eggs, salami, cheese |
| 2009 | Chivito (Uruguayan sandwich) | Generic | UY | Sandwich | L | TODO | 2026-04-07 | | Steak sandwich with eggs and ham |
| 2010 | Chimichurri Steak (per serving) | Generic | AR | Entree | M | TODO | 2026-04-07 | | |
| 2011 | Empanada Saltena (1 pc) | Generic | AR | Snack | M | TODO | 2026-04-07 | | Juicy beef empanada |

## Section 82: African Cuisine (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2012 | Ethiopian Beyaynetu (veggie combo) | Generic | ET | Entree | M | TODO | 2026-04-07 | | Mixed vegetable platter |
| 2013 | Ethiopian Coffee (buna, 1 cup) | Generic | ET | Beverage | M | TODO | 2026-04-07 | | |
| 2014 | Githeri (per serving) | Generic | KE | Entree | L | TODO | 2026-04-07 | | Beans and corn stew |
| 2015 | Mukimo (per serving) | Generic | KE | Side | L | TODO | 2026-04-07 | | Mashed potato with corn and greens |
| 2016 | Kenyan Pilau (per serving) | Generic | KE | Rice | M | TODO | 2026-04-07 | | Spiced rice |
| 2017 | Red Red (per serving) | Generic | GH | Entree | L | TODO | 2026-04-07 | | Bean stew with plantain |
| 2018 | Light Soup (Ghanaian) | Generic | GH | Soup | L | TODO | 2026-04-07 | | Tomato-based soup |
| 2019 | Moroccan Couscous (per serving) | Generic | MA | Entree | M | TODO | 2026-04-07 | | |
| 2020 | Luwombo (per serving) | Generic | UG | Entree | L | TODO | 2026-04-07 | | Steamed banana leaf stew |
| 2021 | Doro Wot with Injera (full plate) | Generic | ET | Entree | M | TODO | 2026-04-07 | | |
| 2022 | Berbere Tibs | Generic | ET | Entree | L | TODO | 2026-04-07 | | Extra spicy |
| 2023 | Cachupa (per serving) | Generic | CV | Entree | L | TODO | 2026-04-07 | | Cape Verdean corn and bean stew |
| 2024 | Fatayer (spinach, 3 pcs) | Generic | LB | Appetizer | M | TODO | 2026-04-07 | | |
| 2025 | Jolof Spaghetti | Generic | NG | Pasta | L | TODO | 2026-04-07 | | Nigerian fusion |

## Section 83: Southeast Asian Cuisine (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2026 | ABC (Ais Batu Campur) | Generic | MY | Dessert | M | TODO | 2026-04-07 | | Malaysian shaved ice |
| 2027 | Asam Laksa (Penang) | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Sour fish noodle soup |
| 2028 | Singapore Chilli Crab (per serving) | Generic | SG | Entree | M | TODO | 2026-04-07 | | Sweet-spicy tomato crab |
| 2029 | Kaya Toast with Eggs | Generic | SG | Breakfast | M | TODO | 2026-04-07 | | With soft-boiled eggs and coffee |
| 2030 | Gudeg (per serving) | Generic | ID | Entree | L | TODO | 2026-04-07 | | Yogyakarta jackfruit stew |
| 2031 | Siomay (6 pcs) | Generic | ID | Snack | M | TODO | 2026-04-07 | | Indonesian fish dumplings |
| 2032 | Martabak Telor (1 slice) | Generic | ID | Snack | M | TODO | 2026-04-07 | | Savory meat-filled pancake |
| 2033 | Pinoy Spaghetti | Generic | PH | Pasta | M | TODO | 2026-04-07 | | Filipino sweet-style |
| 2034 | Com Tam Suon (broken rice, pork chop) | Generic | VN | Rice | M | TODO | 2026-04-07 | | |
| 2035 | Ca Kho To (claypot fish) | Generic | VN | Entree | M | TODO | 2026-04-07 | | Caramelized catfish |
| 2036 | Nasi Lemak Ayam Goreng | Generic | MY | Rice | M | TODO | 2026-04-07 | | With fried chicken |
| 2037 | Curry Mee (Malaysian) | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Coconut curry noodle soup |
| 2038 | Wanton Mee (Malaysian) | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Dry style with char siu |
| 2039 | Chilli Pan Mee | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Dry noodles with chili |
| 2040 | Pempek (fish cake, 4 pcs) | Generic | ID | Snack | L | TODO | 2026-04-07 | | Palembang specialty |

## Section 84: European Cuisine Expanded (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2041 | Soupe a l'Oignon | Generic | FR | Soup | M | TODO | 2026-04-07 | | French onion soup with gruyere |
| 2042 | Pate (per serving) | Generic | FR | Appetizer | L | TODO | 2026-04-07 | | |
| 2043 | Paella de Mariscos (seafood) | Generic | ES | Entree | H | TODO | 2026-04-07 | | |
| 2044 | Croquetas de Jamon (4 pcs) | Generic | ES | Appetizer | M | TODO | 2026-04-07 | | Ham croquettes |
| 2045 | Pintxos (3 pcs assorted) | Generic | ES | Appetizer | M | TODO | 2026-04-07 | | Basque bar snacks |
| 2046 | Sangria (per glass) | Generic | ES | Alcohol | M | TODO | 2026-04-07 | | |
| 2047 | Jamon Iberico (per 50g) | Generic | ES | Appetizer | M | TODO | 2026-04-07 | | |
| 2048 | Chicken Schnitzel | Generic | DE | Entree | M | TODO | 2026-04-07 | | |
| 2049 | Leberkase (1 slice) | Generic | DE | Entree | L | TODO | 2026-04-07 | | Bavarian meatloaf |
| 2050 | Schwarzwalder Kirschtorte (1 slice) | Generic | DE | Dessert | M | TODO | 2026-04-07 | | Black Forest cake |
| 2051 | Swedish Meatballs (8 pcs with sauce) | Generic | SE | Entree | M | TODO | 2026-04-07 | | With lingonberry |
| 2052 | Smørrebrød (open-faced sandwich, 1 pc) | Generic | DK | Sandwich | M | TODO | 2026-04-07 | | Danish open sandwich |
| 2053 | Pierogi (6 pcs, potato and cheese) | Generic | PL | Entree | M | TODO | 2026-04-07 | | |
| 2054 | Pierogi (6 pcs, meat) | Generic | PL | Entree | M | TODO | 2026-04-07 | | |

## Section 85: American Regional & Classic Dishes (150 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2055 | Collard Greens (per serving) | Generic | US | Side | M | TODO | 2026-04-07 | | Slow-cooked with ham hock |
| 2056 | Crawfish Boil (per 1 lb) | Generic | US | Entree | M | TODO | 2026-04-07 | | |
| 2057 | Shrimp Po'Boy | Generic | US | Sandwich | M | TODO | 2026-04-07 | | New Orleans fried shrimp sub |
| 2058 | Muffuletta (half) | Generic | US | Sandwich | M | TODO | 2026-04-07 | | New Orleans olive salad sandwich |
| 2059 | Country Fried Steak | Generic | US | Entree | M | TODO | 2026-04-07 | | Breaded steak with white gravy |
| 2060 | Chicken Fried Chicken | Generic | US | Entree | M | TODO | 2026-04-07 | | |
| 2061 | Fajitas (chicken, per serving) | Generic | US | Entree | H | TODO | 2026-04-07 | | Tex-Mex with peppers and onions |
| 2062 | Fajitas (steak, per serving) | Generic | US | Entree | H | TODO | 2026-04-07 | | |
| 2063 | Queso Dip (per serving) | Generic | US | Appetizer | H | TODO | 2026-04-07 | | Tex-Mex cheese dip |
| 2064 | Breakfast Tacos (egg and bacon, 2 pcs) | Generic | US | Breakfast | H | TODO | 2026-04-07 | | Austin-style |
| 2065 | Breakfast Tacos (egg and chorizo, 2 pcs) | Generic | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2066 | Migas (Tex-Mex) | Generic | US | Breakfast | M | TODO | 2026-04-07 | | Eggs with tortilla chips |
| 2067 | Chimichanga (beef) | Generic | US | Entree | M | TODO | 2026-04-07 | | Deep-fried burrito |
| 2068 | Taquitos (beef, 5 pcs) | Generic | US | Snack | M | TODO | 2026-04-07 | | Rolled tortillas fried |
| 2069 | Sopapillas (3 pcs) | Generic | US | Dessert | M | TODO | 2026-04-07 | | Fried dough with honey |
| 2070 | New York Style Pizza (1 slice) | Generic | US | Pizza | H | TODO | 2026-04-07 | | Thin, foldable |
| 2071 | New York Style Pizza (whole 18 inch) | Generic | US | Pizza | H | TODO | 2026-04-07 | | |
| 2072 | Everything Bagel | Generic | US | Bread | H | TODO | 2026-04-07 | | |
| 2073 | Pastrami Sandwich (Katz's style) | Generic | US | Sandwich | M | TODO | 2026-04-07 | | On rye with mustard |
| 2074 | Egg Cream (per glass) | Generic | US | Beverage | L | TODO | 2026-04-07 | | NYC chocolate soda |
| 2075 | Hot Dish (Minnesota tater tot) | Generic | US | Entree | M | TODO | 2026-04-07 | | Tater tot casserole |
| 2076 | Cheese Curds (fried, per serving) | Generic | US | Appetizer | M | TODO | 2026-04-07 | | Wisconsin classic |
| 2077 | Bratwurst in a Bun | Generic | US | Sandwich | M | TODO | 2026-04-07 | | Wisconsin-style |
| 2078 | Tavern-Style Pizza (1 slice) | Generic | US | Pizza | M | TODO | 2026-04-07 | | Chicago thin cut in squares |
| 2079 | Butter Burger | Generic | US | Sandwich | M | TODO | 2026-04-07 | | Wisconsin-style |
| 2080 | Kansas City BBQ Burnt Ends | Generic | US | Entree | M | TODO | 2026-04-07 | | |
| 2081 | California Burrito | Generic | US | Entree | M | TODO | 2026-04-07 | | With fries inside |
| 2082 | Texas Brisket (per 100g) | Generic | US | BBQ | H | TODO | 2026-04-07 | | Smoked low and slow |
| 2083 | Alabama White Sauce Chicken | Generic | US | BBQ | M | TODO | 2026-04-07 | | Mayo-vinegar sauce |
| 2084 | KC Burnt Ends (per serving) | Generic | US | BBQ | M | TODO | 2026-04-07 | | |
| 2085 | BBQ Brisket Sandwich | Generic | US | Sandwich | H | TODO | 2026-04-07 | | |
| 2086 | Smoked Sausage Link | Generic | US | BBQ | M | TODO | 2026-04-07 | | Texas-style |
| 2087 | Kalua Pig (per serving) | Generic | US | Protein | M | TODO | 2026-04-07 | | |
| 2088 | Shave Ice (Hawaiian) | Generic | US | Dessert | M | TODO | 2026-04-07 | | With azuki bean and mochi |
| 2089 | Tuna Casserole | Generic | US | Entree | M | TODO | 2026-04-07 | | With egg noodles |
| 2090 | Salisbury Steak | Generic | US | Entree | M | TODO | 2026-04-07 | | With mushroom gravy |
| 2091 | Boneless Wings (10 pcs) | Generic | US | Appetizer | H | TODO | 2026-04-07 | | |
| 2092 | Bloomin' Onion | Generic | US | Appetizer | M | TODO | 2026-04-07 | | |
| 2093 | Patty Melt | Generic | US | Sandwich | M | TODO | 2026-04-07 | | Burger on rye with onions |
| 2094 | Chicago Hot Dog | Generic | US | Sandwich | M | TODO | 2026-04-07 | | With all the fixings |
| 2095 | Chili Dog | Generic | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2096 | Coney Island Dog | Generic | US | Sandwich | M | TODO | 2026-04-07 | | Detroit-style |
| 2097 | Philly Roast Pork Sandwich | Generic | US | Sandwich | M | TODO | 2026-04-07 | | With broccoli rabe and provolone |
| 2098 | Nashville Hot Chicken (2 pcs) | Generic | US | Entree | H | TODO | 2026-04-07 | | |
| 2099 | Fried Chicken Biscuit | Generic | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2100 | S'more (1 pc) | Generic | US | Dessert | M | TODO | 2026-04-07 | | |
| 2101 | German Chocolate Cake (1 slice) | Generic | US | Dessert | M | TODO | 2026-04-07 | | |
| 2102 | Etouffee (crawfish) | Generic | US | Entree | M | TODO | 2026-04-07 | | |
| 2103 | Boudin (1 link) | Generic | US | Entree | L | TODO | 2026-04-07 | | Cajun rice sausage |
| 2104 | Andouille Sausage (1 link) | Generic | US | Protein | M | TODO | 2026-04-07 | | |

## Section 86: Trader Joe's Specific Products (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2105 | Unexpected Cheddar (per 1 oz) | Trader Joe's | US | Cheese | H | TODO | 2026-04-07 | | |
| 2106 | Gone Bananas (5 pcs) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | Chocolate covered banana |
| 2107 | Elote Corn Chip Dippers (per serving) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 2108 | Spatchcocked Chicken (per 4 oz) | Trader Joe's | US | Protein | M | TODO | 2026-04-07 | | |
| 2109 | Gyoza Potstickers (7 pcs) | Trader Joe's | US | Frozen Appetizer | H | TODO | 2026-04-07 | | |
| 2110 | Turkey Corn Dogs (1 pc) | Trader Joe's | US | Frozen Entree | M | TODO | 2026-04-07 | | |
| 2111 | Mini Ice Cream Cones (4 pcs) | Trader Joe's | US | Dessert | M | TODO | 2026-04-07 | | Hold The Cone |
| 2112 | Peanut Butter Filled Pretzels (per serving) | Trader Joe's | US | Snack | H | TODO | 2026-04-07 | | |
| 2113 | Cauliflower Pizza Crust (1/3 crust) | Trader Joe's | US | Frozen | M | TODO | 2026-04-07 | | |
| 2114 | Shawarma Chicken Thighs (per 4 oz) | Trader Joe's | US | Frozen Protein | M | TODO | 2026-04-07 | | |
| 2115 | Everything But The Bagel Seasoning (per tsp) | Trader Joe's | US | Seasoning | H | TODO | 2026-04-07 | | |
| 2116 | Frozen Chocolate Croissants (1 pc baked) | Trader Joe's | US | Bakery | M | TODO | 2026-04-07 | | |
| 2117 | Joe-Joe's Cookies (2 pcs) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 2118 | Cowboy Bark (per serving) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 2119 | Soy Chorizo (per 2.5 oz) | Trader Joe's | US | Protein | M | TODO | 2026-04-07 | | Plant-based |
| 2120 | Thai Banana Fritters (4 pcs) | Trader Joe's | US | Frozen Snack | L | TODO | 2026-04-07 | | |
| 2121 | Mini Brie Bites (4 pcs) | Trader Joe's | US | Cheese | M | TODO | 2026-04-07 | | |
| 2122 | Thai Vegetable Gyoza (7 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 2123 | Sublime Ice Cream Sandwiches (1 pc) | Trader Joe's | US | Dessert | M | TODO | 2026-04-07 | | |
| 2124 | Bibimbap Bowl (1 package) | Trader Joe's | US | Frozen Entree | M | TODO | 2026-04-07 | | |
| 2125 | Chicken Soup Dumplings (6 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 2126 | Crunchy Peanut Butter (per 2 tbsp) | Trader Joe's | US | Spread | M | TODO | 2026-04-07 | | |
| 2127 | Triple Ginger Snaps (5 pcs) | Trader Joe's | US | Snack | L | TODO | 2026-04-07 | | |
| 2128 | Organic Ezekiel Bread (1 slice) | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 2129 | Cashew Fiesta Dip (per 2 tbsp) | Trader Joe's | US | Dip | L | TODO | 2026-04-07 | | |
| 2130 | Green Goddess Salad Dressing (per 2 tbsp) | Trader Joe's | US | Condiment | M | TODO | 2026-04-07 | | |
| 2131 | Cheese Crunchies (per serving) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 2132 | Thai Coconut Curry Simmer Sauce (per 1/4 cup) | Trader Joe's | US | Sauce | L | TODO | 2026-04-07 | | |
| 2133 | Vanilla Bean Greek Yogurt (per 6 oz) | Trader Joe's | US | Dairy | M | TODO | 2026-04-07 | | |
| 2134 | Krispy Rice Treat (1 bar) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | Chocolate drizzled |
| 2135 | Banana Bread Mix (prepared, per slice) | Trader Joe's | US | Bakery | L | TODO | 2026-04-07 | | |
| 2136 | Mixed Nut Butter (per 2 tbsp) | Trader Joe's | US | Spread | L | TODO | 2026-04-07 | | |
| 2137 | Bambino Pizza Formaggio (1 pc) | Trader Joe's | US | Frozen Pizza | M | TODO | 2026-04-07 | | Mini cheese pizza |
| 2138 | Tarte aux Champignons (1/4 tart) | Trader Joe's | US | Frozen Entree | L | TODO | 2026-04-07 | | Mushroom tart |
| 2139 | Cornbread Crisps (per serving) | Trader Joe's | US | Snack | L | TODO | 2026-04-07 | | |
| 2140 | Steamed Chicken Soup Dumplings (6 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 2141 | Chicken Quesadilla (1 half) | Trader Joe's | US | Frozen Entree | M | TODO | 2026-04-07 | | |
| 2142 | Everything Ciabatta Rolls (1 roll) | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 2143 | Za'atar Pita Crackers (per serving) | Trader Joe's | US | Snack | L | TODO | 2026-04-07 | | |
| 2144 | Chile Lime Chicken Burgers (1 patty) | Trader Joe's | US | Frozen Protein | M | TODO | 2026-04-07 | | |
| 2145 | Argentinian Red Shrimp (per 4 oz) | Trader Joe's | US | Frozen Protein | M | TODO | 2026-04-07 | | |
| 2146 | Frozen Açaí Puree (1 packet) | Trader Joe's | US | Frozen | M | TODO | 2026-04-07 | | |
| 2147 | Riced Cauliflower (per 1 cup) | Trader Joe's | US | Frozen Vegetable | M | TODO | 2026-04-07 | | |
| 2148 | Everything Croissant Rolls (1 pc baked) | Trader Joe's | US | Bakery | M | TODO | 2026-04-07 | | |
| 2149 | Greek Chickpeas (per 1/2 cup) | Trader Joe's | US | Side | L | TODO | 2026-04-07 | | |
| 2150 | Chicken Cilantro Mini Wontons (7 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 2151 | Scandinavian Swimmers (per serving) | Trader Joe's | US | Snack | L | TODO | 2026-04-07 | | Gummy candies |
| 2152 | Sriracha Baked Tofu (per 3 oz) | Trader Joe's | US | Protein | M | TODO | 2026-04-07 | | |
| 2153 | Korean Beefless Bulgogi (per 1 cup) | Trader Joe's | US | Frozen Entree | L | TODO | 2026-04-07 | | Plant-based |
| 2154 | Organic Super Greens (per 3 cups) | Trader Joe's | US | Produce | M | TODO | 2026-04-07 | | Kale, chard, spinach mix |
| 2155 | Chili Onion Crunch (per tsp) | Trader Joe's | US | Condiment | M | TODO | 2026-04-07 | | |
| 2156 | Turkey Bolognese (per 1/2 cup) | Trader Joe's | US | Sauce | M | TODO | 2026-04-07 | | |
| 2157 | Chimichurri Rice (1 cup) | Trader Joe's | US | Frozen Side | L | TODO | 2026-04-07 | | |
| 2158 | Chocolate Hummus (per 2 tbsp) | Trader Joe's | US | Dip | L | TODO | 2026-04-07 | | |
| 2159 | Chicken Gyoza (7 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 2160 | Protein Patties (plant-based, 1 patty) | Trader Joe's | US | Frozen Protein | M | TODO | 2026-04-07 | | |
| 2161 | Soft Baked Peanut Butter Cookies (1 pc) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 2162 | Organic Açaí Bowl (1 bowl) | Trader Joe's | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 2163 | Chicken Tikka Samosa (2 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 2164 | Umami Seasoning Blend (per tsp) | Trader Joe's | US | Seasoning | L | TODO | 2026-04-07 | | |
| 2165 | Lemon Ricotta Ravioli (1 cup) | Trader Joe's | US | Frozen Pasta | M | TODO | 2026-04-07 | | |

## Section 87: Costco/Kirkland Products (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2166 | Kirkland Organic Eggs (1 large egg) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 2167 | Kirkland Wild Salmon (per 4 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 2168 | Costco Food Court Pizza (1 slice) | Costco/Kirkland | US | Pizza | H | TODO | 2026-04-07 | | Cheese or pepperoni |
| 2169 | Costco Croissants (1 pc) | Costco/Kirkland | US | Bakery | H | TODO | 2026-04-07 | | Butter croissant |
| 2170 | Costco Sheet Cake (1 slice) | Costco/Kirkland | US | Dessert | M | TODO | 2026-04-07 | | White or chocolate |
| 2171 | Kirkland Organic Peanut Butter (per 2 tbsp) | Costco/Kirkland | US | Spread | M | TODO | 2026-04-07 | | |
| 2172 | Kirkland Ground Beef 85/15 (per 4 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 2173 | Kirkland Frozen Berries Mix (per 1 cup) | Costco/Kirkland | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 2174 | Kirkland Frozen Mango (per 1 cup) | Costco/Kirkland | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 2175 | Costco Food Court Chocolate Frozen Yogurt | Costco/Kirkland | US | Dessert | M | TODO | 2026-04-07 | | |
| 2176 | Kirkland Smoked Salmon (per 2 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 2177 | Costco Chicken Wings (per 4 wings) | Costco/Kirkland | US | Deli | M | TODO | 2026-04-07 | | |
| 2178 | Kirkland Breakfast Sausage (2 patties) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 2179 | Kirkland Mini Chocolate Chip Cookies (4 pcs) | Costco/Kirkland | US | Snack | M | TODO | 2026-04-07 | | |
| 2180 | Kirkland Organic Tortillas (1 large) | Costco/Kirkland | US | Bread | M | TODO | 2026-04-07 | | |
| 2181 | Kirkland Quinoa Salad (per 1 cup) | Costco/Kirkland | US | Deli | M | TODO | 2026-04-07 | | |
| 2182 | Costco Bulgogi Beef (per 4 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 2183 | Kirkland Organic Chicken Stock (per 1 cup) | Costco/Kirkland | US | Soup | L | TODO | 2026-04-07 | | |
| 2184 | Costco Chocolate Chip Cookies (1 pc) | Costco/Kirkland | US | Bakery | M | TODO | 2026-04-07 | | |
| 2185 | Costco Cinnamon Pull-Apart (1 piece) | Costco/Kirkland | US | Bakery | M | TODO | 2026-04-07 | | |
| 2186 | Costco Food Court Mocha Freeze | Costco/Kirkland | US | Beverage | M | TODO | 2026-04-07 | | |
| 2187 | Kirkland Organic Milk (per 1 cup) | Costco/Kirkland | US | Dairy | M | TODO | 2026-04-07 | | |
| 2188 | Costco Lobster Ravioli (per 1 cup) | Costco/Kirkland | US | Deli | M | TODO | 2026-04-07 | | |
| 2189 | Kirkland Marinated Artichoke Hearts (per 1/4 cup) | Costco/Kirkland | US | Side | L | TODO | 2026-04-07 | | |
| 2190 | Costco Korean BBQ Short Ribs (per 4 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 2191 | Kirkland Frozen Stir-Fry Vegetables (per 1 cup) | Costco/Kirkland | US | Frozen Vegetable | M | TODO | 2026-04-07 | | |
| 2192 | Kirkland Chocolate Almonds (per 1/4 cup) | Costco/Kirkland | US | Snack | M | TODO | 2026-04-07 | | |
| 2193 | Kirkland Frozen Chicken Pot Stickers (7 pcs) | Costco/Kirkland | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 2194 | Kirkland Organic Eggs (hard boiled, 2 pcs) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 2195 | Kirkland Bagels (1 pc) | Costco/Kirkland | US | Bakery | M | TODO | 2026-04-07 | | |
| 2196 | Costco Food Court Combo Pizza (1 slice) | Costco/Kirkland | US | Pizza | M | TODO | 2026-04-07 | | |
| 2197 | Costco Brownie Bar (1 bar) | Costco/Kirkland | US | Dessert | M | TODO | 2026-04-07 | | |
| 2198 | Kirkland Lamb Rack (per 4 oz) | Costco/Kirkland | US | Protein | L | TODO | 2026-04-07 | | |
| 2199 | Costco Shrimp Cocktail (per 3 oz shrimp) | Costco/Kirkland | US | Appetizer | M | TODO | 2026-04-07 | | |

## Section 88: More Fast Food Complete Menus (200 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2200 | Sausage McGriddle | McDonald's | US | Breakfast | H | TODO | 2026-04-07 | | |
| 2201 | Bacon Egg & Cheese McGriddle | McDonald's | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2202 | Hash Brown (1 pc) | McDonald's | US | Breakfast | H | TODO | 2026-04-07 | | |
| 2203 | Sausage Burrito | McDonald's | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2204 | Crispy Chicken Sandwich | McDonald's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2205 | 10-piece McNuggets | McDonald's | US | Entree | H | TODO | 2026-04-07 | | |
| 2206 | 20-piece McNuggets | McDonald's | US | Entree | M | TODO | 2026-04-07 | | |
| 2207 | Large Fries | McDonald's | US | Side | H | TODO | 2026-04-07 | | |
| 2208 | Medium Fries | McDonald's | US | Side | H | TODO | 2026-04-07 | | |
| 2209 | 10-piece Nuggets | Wendy's | US | Entree | M | TODO | 2026-04-07 | | |
| 2210 | Apple Pecan Salad (full) | Wendy's | US | Salad | M | TODO | 2026-04-07 | | |
| 2211 | Baja Blast (large) | Taco Bell | US | Beverage | H | TODO | 2026-04-07 | | Mountain Dew Baja Blast |
| 2212 | Chicken Fries (9 pcs) | Burger King | US | Snack | M | TODO | 2026-04-07 | | |
| 2213 | Hershey's Pie (1 slice) | Burger King | US | Dessert | M | TODO | 2026-04-07 | | |
| 2214 | Chick-fil-A Original Sandwich | Chick-fil-A | US | Sandwich | H | TODO | 2026-04-07 | | |
| 2215 | Chick-fil-A Spicy Sandwich | Chick-fil-A | US | Sandwich | H | TODO | 2026-04-07 | | |
| 2216 | Chick-fil-A 8-count Nuggets | Chick-fil-A | US | Entree | H | TODO | 2026-04-07 | | |
| 2217 | Chick-fil-A 12-count Nuggets | Chick-fil-A | US | Entree | M | TODO | 2026-04-07 | | |
| 2218 | Chick-fil-A Grilled Nuggets (8-count) | Chick-fil-A | US | Entree | M | TODO | 2026-04-07 | | |
| 2219 | Chick-fil-A Chicken Mini (4-count) | Chick-fil-A | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2220 | Chick-fil-A Chicken Wrap | Chick-fil-A | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2221 | Beef 'n Cheddar (classic) | Arby's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2222 | Chicken Bacon Swiss | Arby's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2223 | Sonic Blast (Oreo, medium) | Sonic | US | Dessert | M | TODO | 2026-04-07 | | |
| 2224 | Cherry Limeade (medium) | Sonic | US | Beverage | M | TODO | 2026-04-07 | | |
| 2225 | Spicy Ketchup Fries (medium) | Whataburger | US | Side | L | TODO | 2026-04-07 | | |
| 2226 | Famous Star with Cheese | Carl's Jr | US | Burger | M | TODO | 2026-04-07 | | |
| 2227 | Sack of 10 Sliders | White Castle | US | Burger | M | TODO | 2026-04-07 | | |
| 2228 | ButterBurger (single) | Culver's | US | Burger | M | TODO | 2026-04-07 | | |
| 2229 | ButterBurger (double) | Culver's | US | Burger | M | TODO | 2026-04-07 | | |
| 2230 | Cheese Curds (regular) | Culver's | US | Appetizer | M | TODO | 2026-04-07 | | |
| 2231 | Concrete Mixer (1 regular) | Culver's | US | Dessert | M | TODO | 2026-04-07 | | Frozen custard |
| 2232 | Cod Fillet Sandwich | Culver's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2233 | Classic Italian Hoagie (regular) | Wawa | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2234 | Sizzli (sausage egg cheese) | Wawa | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2235 | Sub MTO (custom, turkey) | Sheetz | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2236 | Buc-ee's Kolache (1 pc) | Buc-ee's | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2237 | Portillo's Chicago Dog | Portillo's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2238 | Cookout Milkshake | Cookout | US | Dessert | M | TODO | 2026-04-07 | | 40+ flavor options |
| 2239 | Popeyes 3-piece Tenders | Popeyes | US | Entree | M | TODO | 2026-04-07 | | |
| 2240 | Popeyes 2-piece Mixed (leg and thigh) | Popeyes | US | Entree | M | TODO | 2026-04-07 | | |
| 2241 | Zaxby's Wings (5 pcs) | Zaxby's | US | Entree | M | TODO | 2026-04-07 | | |
| 2242 | Del Taco Epic Burrito | Del Taco | US | Entree | M | TODO | 2026-04-07 | | |
| 2243 | Long John Silver's Fish (2 pcs) | Long John Silver's | US | Entree | M | TODO | 2026-04-07 | | Battered cod |
| 2244 | Long John Silver's Hush Puppies (3 pcs) | Long John Silver's | US | Side | M | TODO | 2026-04-07 | | |
| 2245 | Rally's/Checkers Fry Seasoned Fries | Rally's | US | Side | M | TODO | 2026-04-07 | | |
| 2246 | Rally's Big Buford | Rally's | US | Burger | M | TODO | 2026-04-07 | | |
| 2247 | Freddy's Original Double | Freddy's | US | Burger | M | TODO | 2026-04-07 | | |
| 2248 | Freddy's Cheese Sauce and Fries | Freddy's | US | Side | M | TODO | 2026-04-07 | | |
| 2249 | Smashburger Classic Smash (single) | Smashburger | US | Burger | M | TODO | 2026-04-07 | | |
| 2250 | Habit Charburger with Cheese | The Habit | US | Burger | M | TODO | 2026-04-07 | | |
| 2251 | Hardee's Thickburger (1/3 lb) | Hardee's | US | Burger | M | TODO | 2026-04-07 | | |
| 2252 | Chipotle Carnitas Bowl | Chipotle | US | Entree | M | TODO | 2026-04-07 | | |
| 2253 | Chipotle Chips and Guac | Chipotle | US | Side | H | TODO | 2026-04-07 | | |
| 2254 | Chipotle Chips and Queso | Chipotle | US | Side | M | TODO | 2026-04-07 | | |
| 2255 | Subway 6-inch Turkey Breast | Subway | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2256 | Subway 6-inch Italian BMT | Subway | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2257 | Subway 6-inch Chicken Teriyaki | Subway | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2258 | Chili's Chicken Crispers | Chili's | US | Entree | M | TODO | 2026-04-07 | | |
| 2259 | Chili's Big Mouth Burger | Chili's | US | Burger | M | TODO | 2026-04-07 | | |
| 2260 | Chili's Molten Lava Cake | Chili's | US | Dessert | M | TODO | 2026-04-07 | | |
| 2261 | Olive Garden Chicken Parm | Olive Garden | US | Entree | M | TODO | 2026-04-07 | | |
| 2262 | Texas Roadhouse 6 oz Sirloin | Texas Roadhouse | US | Entree | M | TODO | 2026-04-07 | | |
| 2263 | Texas Roadhouse Roll with Cinnamon Butter (1 pc) | Texas Roadhouse | US | Bread | M | TODO | 2026-04-07 | | |
| 2264 | Outback 6 oz Victoria's Filet | Outback | US | Entree | M | TODO | 2026-04-07 | | |

## Section 89: Coffee Shop & Juice/Smoothie Full Menus (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2265 | Starbucks Cake Pop (1 pc) | Starbucks | US | Snack | M | TODO | 2026-04-07 | | |
| 2266 | Starbucks Protein Box (eggs and cheese) | Starbucks | US | Snack | M | TODO | 2026-04-07 | | |
| 2267 | Starbucks Egg Bites (bacon gruyere, 2 pcs) | Starbucks | US | Breakfast | H | TODO | 2026-04-07 | | |
| 2268 | Starbucks Egg Bites (egg white red pepper) | Starbucks | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2269 | Starbucks Double Smoked Bacon Sandwich | Starbucks | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2270 | Starbucks Spinach Feta Wrap | Starbucks | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2271 | Starbucks Banana Nut Bread (1 slice) | Starbucks | US | Bakery | M | TODO | 2026-04-07 | | |
| 2272 | Starbucks Lemon Loaf (1 slice) | Starbucks | US | Bakery | M | TODO | 2026-04-07 | | |
| 2273 | Starbucks Cheese Danish | Starbucks | US | Bakery | M | TODO | 2026-04-07 | | |
| 2274 | Starbucks Iced Caramel Macchiato (grande) | Starbucks | US | Beverage | H | TODO | 2026-04-07 | | |
| 2275 | Starbucks White Mocha (grande, hot) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | |
| 2276 | Starbucks Matcha Latte (grande) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | |
| 2277 | Jamba Juice Aloha Pineapple (medium) | Jamba Juice | US | Smoothie | M | TODO | 2026-04-07 | | |
| 2278 | Jamba Juice PB Chocolate Love (medium) | Jamba Juice | US | Smoothie | M | TODO | 2026-04-07 | | |
| 2279 | Jamba Juice Greens 'n Ginger (medium) | Jamba Juice | US | Smoothie | M | TODO | 2026-04-07 | | |
| 2280 | Smoothie King Lean1 Chocolate (medium) | Smoothie King | US | Smoothie | M | TODO | 2026-04-07 | | |
| 2281 | Smoothie King The Activator Pineapple (medium) | Smoothie King | US | Smoothie | M | TODO | 2026-04-07 | | |
| 2282 | Tropical Smoothie Chicken Bacon Ranch Wrap | Tropical Smoothie | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2283 | Dunkin Wake-Up Wrap (bacon egg cheese) | Dunkin | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2284 | Dunkin Frozen Coffee (medium) | Dunkin | US | Beverage | M | TODO | 2026-04-07 | | |
| 2285 | Tim Hortons Timbits (5 pcs) | Tim Hortons | CA | Dessert | M | TODO | 2026-04-07 | | Donut holes |
| 2286 | Philz Mint Mojito Iced Coffee (medium) | Philz Coffee | US | Beverage | L | TODO | 2026-04-07 | | |
| 2287 | Philz Tesora (medium) | Philz Coffee | US | Beverage | L | TODO | 2026-04-07 | | |
| 2288 | Blue Bottle New Orleans Iced Coffee | Blue Bottle | US | Beverage | L | TODO | 2026-04-07 | | With chicory and milk |
| 2289 | Peet's Coffee Caramel Macchiato (medium) | Peet's Coffee | US | Beverage | M | TODO | 2026-04-07 | | |
| 2290 | Starbucks Dragon Drink (grande) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | Mango dragonfruit with coconut milk |
| 2291 | Starbucks Strawberry Acai Refresher (grande) | Starbucks | US | Beverage | H | TODO | 2026-04-07 | | |
| 2292 | Starbucks Chicken Maple Butter Sandwich | Starbucks | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2293 | Dunkin Croissant Stuffer (ham and swiss) | Dunkin | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2294 | Dunkin Refresher (strawberry dragonfruit, medium) | Dunkin | US | Beverage | M | TODO | 2026-04-07 | | |
| 2295 | Starbucks Cranberry Bliss Bar | Starbucks | US | Snack | L | TODO | 2026-04-07 | | Seasonal |
| 2296 | Dutch Bros Frost (cookie dough, medium) | Dutch Bros | US | Beverage | M | TODO | 2026-04-07 | | Blended |
| 2297 | Starbucks Hot Chocolate (grande) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | |
| 2298 | Panera Bread Bowl (broccoli cheddar) | Panera | US | Soup | M | TODO | 2026-04-07 | | |

## Section 90: Dessert & Ice Cream Chains (60 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2299 | Baskin-Robbins Scoop (1 regular, chocolate) | Baskin-Robbins | US | Dessert | M | TODO | 2026-04-07 | | |
| 2300 | Baskin-Robbins Scoop (1 regular, vanilla) | Baskin-Robbins | US | Dessert | M | TODO | 2026-04-07 | | |
| 2301 | Baskin-Robbins Scoop (1 regular, mint chip) | Baskin-Robbins | US | Dessert | M | TODO | 2026-04-07 | | |
| 2302 | Baskin-Robbins Scoop (1 regular, pralines and cream) | Baskin-Robbins | US | Dessert | M | TODO | 2026-04-07 | | |
| 2303 | Cold Stone Gotta Have It (Founder's Favorite) | Cold Stone | US | Dessert | M | TODO | 2026-04-07 | | |
| 2304 | Cold Stone Love It (Birthday Cake Remix) | Cold Stone | US | Dessert | M | TODO | 2026-04-07 | | |
| 2305 | Cold Stone Like It (Oreo Overload) | Cold Stone | US | Dessert | M | TODO | 2026-04-07 | | |
| 2306 | Dairy Queen Banana Split | Dairy Queen | US | Dessert | M | TODO | 2026-04-07 | | |
| 2307 | Dairy Queen Flamethrower Burger | Dairy Queen | US | Burger | M | TODO | 2026-04-07 | | |
| 2308 | Insomnia Cookie (chocolate chunk, 1 pc) | Insomnia Cookies | US | Dessert | M | TODO | 2026-04-07 | | |
| 2309 | Insomnia Cookie (snickerdoodle, 1 pc) | Insomnia Cookies | US | Dessert | M | TODO | 2026-04-07 | | |
| 2310 | Insomnia Cookie (double chocolate chunk, 1 pc) | Insomnia Cookies | US | Dessert | M | TODO | 2026-04-07 | | |
| 2311 | Nothing Bundt Cake (bundtlet, 1 pc) | Nothing Bundt Cakes | US | Dessert | M | TODO | 2026-04-07 | | |
| 2312 | Nothing Bundt Cake (bundtini, 1 pc) | Nothing Bundt Cakes | US | Dessert | M | TODO | 2026-04-07 | | Bite-size |
| 2313 | Cinnabon Center of the Roll (1 pc) | Cinnabon | US | Dessert | M | TODO | 2026-04-07 | | |
| 2314 | Wetzel's Pretzels Original (1 pc) | Wetzel's Pretzels | US | Snack | M | TODO | 2026-04-07 | | |
| 2315 | Krispy Kreme Strawberry Iced (1 pc) | Krispy Kreme | US | Dessert | M | TODO | 2026-04-07 | | |
| 2316 | Dunkin Blueberry Donut (1 pc) | Dunkin | US | Dessert | M | TODO | 2026-04-07 | | |
| 2317 | Jeni's Splendid (Brambleberry Crisp, per 1/2 cup) | Jeni's | US | Dessert | L | TODO | 2026-04-07 | | |
| 2318 | Jeni's Splendid (Brown Butter Almond Brittle, per 1/2 cup) | Jeni's | US | Dessert | L | TODO | 2026-04-07 | | |
| 2319 | Jeni's Splendid (Gooey Butter Cake, per 1/2 cup) | Jeni's | US | Dessert | L | TODO | 2026-04-07 | | |
| 2320 | Jeni's Splendid (Salty Caramel, per 1/2 cup) | Jeni's | US | Dessert | L | TODO | 2026-04-07 | | |
| 2321 | Salt & Straw (Double Fold Vanilla, per scoop) | Salt & Straw | US | Dessert | L | TODO | 2026-04-07 | | |
| 2322 | Salt & Straw (Honey Lavender, per scoop) | Salt & Straw | US | Dessert | L | TODO | 2026-04-07 | | |
| 2323 | Salt & Straw (Chocolate Gooey Brownie, per scoop) | Salt & Straw | US | Dessert | L | TODO | 2026-04-07 | | |
| 2324 | Duck Donuts Bare Donut (1 pc) | Duck Donuts | US | Dessert | M | TODO | 2026-04-07 | | |
| 2325 | Duck Donuts Chocolate Iced with Sprinkles (1 pc) | Duck Donuts | US | Dessert | M | TODO | 2026-04-07 | | |
| 2326 | Voodoo Doughnut Voodoo Doll (1 pc) | Voodoo Doughnut | US | Dessert | L | TODO | 2026-04-07 | | |
| 2327 | Voodoo Doughnut Old Dirty Bastard (1 pc) | Voodoo Doughnut | US | Dessert | L | TODO | 2026-04-07 | | |
| 2328 | Sprinkles Cupcake (red velvet, 1 pc) | Sprinkles | US | Dessert | L | TODO | 2026-04-07 | | |
| 2329 | Sprinkles Cupcake (dark chocolate, 1 pc) | Sprinkles | US | Dessert | L | TODO | 2026-04-07 | | |
| 2330 | Magnolia Bakery Banana Pudding (per serving) | Magnolia Bakery | US | Dessert | M | TODO | 2026-04-07 | | |
| 2331 | Baked by Melissa Cupcake (1 mini) | Baked by Melissa | US | Dessert | L | TODO | 2026-04-07 | | |
| 2332 | Milk Bar Birthday Cake Truffle (2 pcs) | Milk Bar | US | Dessert | L | TODO | 2026-04-07 | | |

## Section 91: Breakfast Chains (60 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2333 | IHOP Original Buttermilk Pancakes (short stack 3) | IHOP | US | Breakfast | H | TODO | 2026-04-07 | | |
| 2334 | IHOP Harvest Grain 'N Nut Pancakes (short stack) | IHOP | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2335 | IHOP 2x2x2 (2 eggs, 2 bacon, 2 pancakes) | IHOP | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2336 | Denny's Moon Over My Hammy | Denny's | US | Breakfast | M | TODO | 2026-04-07 | | Ham and egg on sourdough |
| 2337 | Denny's Belgian Waffle Slam | Denny's | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2338 | First Watch Elevated Egg Sandwich | First Watch | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2339 | First Watch AM Superfoods Bowl | First Watch | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2340 | Cracker Barrel Uncle Herschel's Breakfast | Cracker Barrel | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2341 | Bob Evans Farmhouse Feast (plate) | Bob Evans | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2342 | Perkins Tremendous Twelve | Perkins | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2343 | Perkins Pancake Platter | Perkins | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2344 | Village Inn Skillet (loaded) | Village Inn | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2345 | First Watch Kale Tonic Juice | First Watch | US | Beverage | M | TODO | 2026-04-07 | | |
| 2346 | Snooze Pineapple Upside Down Pancakes | Snooze | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2347 | Another Broken Egg Lobster Omelette | Another Broken Egg | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2348 | Original Pancake House Dutch Baby | Original Pancake House | US | Breakfast | M | TODO | 2026-04-07 | | German puffed pancake |
| 2349 | Original Pancake House Apple Pancake | Original Pancake House | US | Breakfast | M | TODO | 2026-04-07 | | |
| 2350 | Le Pain Quotidien Tartine (avocado) | Le Pain Quotidien | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2351 | Eggslut Fairfax Sandwich | Eggslut | US | Breakfast | L | TODO | 2026-04-07 | | Soft scrambled egg sandwich |
| 2352 | Eggslut Slut (coddled egg on potato puree) | Eggslut | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2353 | Keke's Breakfast Cafe Traditional Breakfast | Keke's | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2354 | Broken Yolk Big Country Breakfast | Broken Yolk | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2355 | Metro Diner Fried Chicken and Waffles | Metro Diner | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2356 | Tupelo Honey Shrimp and Grits | Tupelo Honey | US | Breakfast | L | TODO | 2026-04-07 | | |
| 2357 | Black Bear Diner Lumberjack Breakfast | Black Bear Diner | US | Breakfast | L | TODO | 2026-04-07 | | |

## Section 92: Salad & Bowl Chains (40 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2358 | CAVA Greens and Grains Bowl (grilled chicken) | CAVA | US | Bowl | M | TODO | 2026-04-07 | | |
| 2359 | CAVA RightRice Bowl | CAVA | US | Bowl | M | TODO | 2026-04-07 | | |
| 2360 | Chipotle Bowl (chicken, white rice, black beans, salsa) | Chipotle | US | Bowl | H | TODO | 2026-04-07 | | Standard build |
| 2361 | Chipotle Lifestyle Bowl (Whole30) | Chipotle | US | Bowl | M | TODO | 2026-04-07 | | |
| 2362 | Chipotle Lifestyle Bowl (Keto) | Chipotle | US | Bowl | M | TODO | 2026-04-07 | | |
| 2363 | Chipotle Tortilla on the side (1 pc) | Chipotle | US | Bread | M | TODO | 2026-04-07 | | |
| 2364 | Freshii Zen Bowl | Freshii | US | Bowl | L | TODO | 2026-04-07 | | |
| 2365 | Freshii Pangoa Bowl | Freshii | US | Bowl | L | TODO | 2026-04-07 | | |
| 2366 | CoreLife Eatery Chicken Power Bowl | CoreLife | US | Bowl | L | TODO | 2026-04-07 | | |
| 2367 | CoreLife Eatery Sriracha Steak Bowl | CoreLife | US | Bowl | L | TODO | 2026-04-07 | | |
| 2368 | Just Salad Crispy Chicken Ranch | Just Salad | US | Salad | L | TODO | 2026-04-07 | | |
| 2369 | Dig Inn Market Plate (chicken, 3 sides) | Dig Inn | US | Bowl | L | TODO | 2026-04-07 | | |
| 2370 | Naya Mediterranean Bowl | Naya | US | Bowl | L | TODO | 2026-04-07 | | |
| 2371 | Cosi TBM Grilled Chicken Flatbread | Cosi | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2372 | Salata Build Your Own Salad (avg build) | Salata | US | Salad | L | TODO | 2026-04-07 | | |
| 2373 | Cava Lamb Meatball Bowl | CAVA | US | Bowl | M | TODO | 2026-04-07 | | |
| 2374 | Honeygrow Stir-Fry (sesame garlic, regular) | Honeygrow | US | Bowl | L | TODO | 2026-04-07 | | |
| 2375 | Honeygrow Honeybar (1 pc) | Honeygrow | US | Dessert | L | TODO | 2026-04-07 | | Fruit and grain bar |
| 2376 | True Food Kitchen Ancient Grains Bowl | True Food Kitchen | US | Bowl | L | TODO | 2026-04-07 | | |
| 2377 | Flower Child Mother Earth Bowl | Flower Child | US | Bowl | L | TODO | 2026-04-07 | | |

## Section 93: Sandwich & Sub Chains (50 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2378 | Jersey Mike's #13 Original Italian (regular) | Jersey Mike's | US | Sandwich | H | TODO | 2026-04-07 | | |
| 2379 | Jersey Mike's #7 Turkey and Provolone (regular) | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2380 | Jersey Mike's #6 Roast Beef and Provolone | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2381 | Jersey Mike's #9 Club Supreme (regular) | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2382 | Jersey Mike's #17 Mike's Famous Philly | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2383 | Jersey Mike's Chicken Bacon Ranch | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2384 | Jimmy John's #1 Pepe | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | Smoked ham, provolone |
| 2385 | Jimmy John's #5 Vito | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | Italian sub |
| 2386 | Jimmy John's #9 Italian Night Club | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2387 | Jimmy John's #4 Turkey Tom | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2388 | Jimmy John's Unwich (lettuce wrap, any) | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | Low carb option |
| 2389 | Jimmy John's Beach Club | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | Turkey and avocado |
| 2390 | Firehouse Subs Smokehouse Beef & Cheddar | Firehouse Subs | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2391 | Firehouse Subs Engineer (medium) | Firehouse Subs | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2392 | Firehouse Subs Hero (medium) | Firehouse Subs | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2393 | Potbelly Turkey Breast (original) | Potbelly | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2394 | Potbelly Chocolate Brownie Cookie (1 pc) | Potbelly | US | Dessert | M | TODO | 2026-04-07 | | |
| 2395 | McAlister's Deli Club (whole) | McAlister's Deli | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2396 | McAlister's Sweet Tea (large) | McAlister's Deli | US | Beverage | M | TODO | 2026-04-07 | | Free refills |
| 2397 | Schlotzsky's The Original (medium) | Schlotzsky's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2398 | Jason's Deli Salad Bar (per plate) | Jason's Deli | US | Salad | M | TODO | 2026-04-07 | | |
| 2399 | Which Wich Elvis (PB, banana, honey) | Which Wich | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2400 | Which Wich Grilled Cheese | Which Wich | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2401 | Penn Station East Coast Subs Philly | Penn Station | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2402 | Penn Station Chicken Teriyaki | Penn Station | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2403 | Penn Station Fresh-Cut Fries (regular) | Penn Station | US | Side | L | TODO | 2026-04-07 | | |
| 2404 | Quiznos Classic Italian (regular) | Quiznos | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2405 | Quiznos Chicken Carbonara | Quiznos | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2406 | Erbert & Gerbert's Boney Billy | Erbert & Gerbert's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2407 | Capriotti's Bobbie (turkey, cranberry, stuffing) | Capriotti's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2408 | Capriotti's Capastrami | Capriotti's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2409 | Publix Chicken Tender Sub (whole) | Publix | US | Sandwich | M | TODO | 2026-04-07 | | Florida cult favorite |
| 2410 | Publix Boar's Head Italian (whole) | Publix | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2411 | Wegmans Danny's Favorite Sub | Wegmans | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2412 | Ike's Love & Sandwiches Matt Cain | Ike's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2413 | Primo Hoagies Italian (regular) | Primo Hoagies | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2414 | Newk's Eatery Shrimp Remoulade | Newk's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2415 | Newk's Eatery Newk's Q | Newk's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 2416 | Earl of Sandwich The Original 1762 | Earl of Sandwich | US | Sandwich | L | TODO | 2026-04-07 | | Hot roast beef |
| 2417 | Lee's Sandwiches Vietnamese Banh Mi | Lee's Sandwiches | US | Sandwich | M | TODO | 2026-04-07 | | |
| 2418 | Portillo's Combo (Italian beef and sausage) | Portillo's | US | Sandwich | M | TODO | 2026-04-07 | | |

## Section 94: Pizza Chains Full (60 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2419 | Domino's Hand Tossed Pepperoni (1 slice, medium) | Domino's | US | Pizza | H | TODO | 2026-04-07 | | |
| 2420 | Domino's Thin Crust Cheese (1 slice, medium) | Domino's | US | Pizza | M | TODO | 2026-04-07 | | |
| 2421 | Domino's Brooklyn Style Pepperoni (1 slice, large) | Domino's | US | Pizza | M | TODO | 2026-04-07 | | |
| 2422 | Domino's Parmesan Bread Bites (8 pcs) | Domino's | US | Bread | M | TODO | 2026-04-07 | | |
| 2423 | Domino's Boneless Wings (8 pcs) | Domino's | US | Appetizer | M | TODO | 2026-04-07 | | |
| 2424 | Pizza Hut Original Pan Cheese (1 slice, medium) | Pizza Hut | US | Pizza | H | TODO | 2026-04-07 | | |
| 2425 | Pizza Hut Original Pan Pepperoni (1 slice, medium) | Pizza Hut | US | Pizza | H | TODO | 2026-04-07 | | |
| 2426 | Pizza Hut Garlic Knots (4 pcs) | Pizza Hut | US | Bread | M | TODO | 2026-04-07 | | |
| 2427 | Pizza Hut WingStreet Traditional (6 pcs) | Pizza Hut | US | Appetizer | M | TODO | 2026-04-07 | | |
| 2428 | Papa John's Original Crust Cheese (1 slice, large) | Papa John's | US | Pizza | H | TODO | 2026-04-07 | | |
| 2429 | Papa John's Original Crust Pepperoni (1 slice, large) | Papa John's | US | Pizza | M | TODO | 2026-04-07 | | |
| 2430 | Papa John's Garlic Sauce (1 cup) | Papa John's | US | Condiment | M | TODO | 2026-04-07 | | |
| 2431 | Papa John's Breadsticks (2 pcs) | Papa John's | US | Bread | M | TODO | 2026-04-07 | | |
| 2432 | Papa John's Papadias (Pepperoni) | Papa John's | US | Sandwich | M | TODO | 2026-04-07 | | Flatbread |
| 2433 | Little Caesars Crazy Bread (2 pcs) | Little Caesars | US | Bread | M | TODO | 2026-04-07 | | |
| 2434 | Little Caesars Italian Cheese Bread (2 pcs) | Little Caesars | US | Bread | M | TODO | 2026-04-07 | | |
| 2435 | Little Caesars Stuffed Crazy Bread (2 pcs) | Little Caesars | US | Bread | M | TODO | 2026-04-07 | | |
| 2436 | Marco's Pizza White Cheezy (1 slice, large) | Marco's Pizza | US | Pizza | M | TODO | 2026-04-07 | | |
| 2437 | MOD Pizza (11 inch, custom avg) | MOD Pizza | US | Pizza | M | TODO | 2026-04-07 | | Build your own |
| 2438 | Blaze Pizza Build Your Own (1 slice, avg) | Blaze Pizza | US | Pizza | M | TODO | 2026-04-07 | | |
| 2439 | Domino's MeatZZa (1 slice, medium) | Domino's | US | Pizza | M | TODO | 2026-04-07 | | |
| 2440 | Domino's Pacific Veggie (1 slice, medium) | Domino's | US | Pizza | M | TODO | 2026-04-07 | | |
| 2441 | Pizza Hut Meat Lover's (1 slice, medium) | Pizza Hut | US | Pizza | M | TODO | 2026-04-07 | | |
| 2442 | Pizza Hut Veggie Lover's (1 slice, medium) | Pizza Hut | US | Pizza | M | TODO | 2026-04-07 | | |
| 2443 | Jet's 8 Corner Pizza (1 slice) | Jet's Pizza | US | Pizza | L | TODO | 2026-04-07 | | Detroit-style |
| 2444 | Round Table King Arthur's Supreme (1 slice, large) | Round Table | US | Pizza | L | TODO | 2026-04-07 | | |
| 2445 | Donatos Pepperoni (1 slice, large) | Donatos | US | Pizza | L | TODO | 2026-04-07 | | Edge-to-edge toppings |
| 2446 | Mountain Mike's Pepperoni (1 slice, large) | Mountain Mike's | US | Pizza | L | TODO | 2026-04-07 | | Crispy curly pepperoni |
| 2447 | Hungry Howie's Cheese (1 slice, medium) | Hungry Howie's | US | Pizza | L | TODO | 2026-04-07 | | Flavored crust |
| 2448 | Cicis Pizza Buffet (avg plate) | Cicis | US | Pizza | L | TODO | 2026-04-07 | | |
| 2449 | Sbarro NY Style Cheese (1 slice) | Sbarro | US | Pizza | M | TODO | 2026-04-07 | | Mall pizza |
| 2450 | Sbarro Stromboli (1 pc) | Sbarro | US | Entree | L | TODO | 2026-04-07 | | |
| 2451 | Sam's Club Pizza (1 slice) | Sam's Club | US | Pizza | M | TODO | 2026-04-07 | | |
| 2452 | Domino's Lava Cake (1 pc) | Domino's | US | Dessert | M | TODO | 2026-04-07 | | |
| 2453 | Papa John's Double Chocolate Chip Brownie (1 pc) | Papa John's | US | Dessert | M | TODO | 2026-04-07 | | |
| 2454 | Little Caesars Pepperoni Crazy Puffs (8 pcs) | Little Caesars | US | Appetizer | L | TODO | 2026-04-07 | | |
| 2455 | DiGiorno Stuffed Crust Supreme (1/6 pizza) | DiGiorno | US | Frozen Pizza | M | TODO | 2026-04-07 | | |
| 2456 | Totino's Party Pizza (1/2 pizza) | Totino's | US | Frozen Pizza | M | TODO | 2026-04-07 | | |
| 2457 | Screamin' Sicilian Bessie's Revenge (1/6 pizza) | Screamin' Sicilian | US | Frozen Pizza | L | TODO | 2026-04-07 | | |
| 2458 | California Pizza Kitchen Frozen BBQ Chicken (1/3 pizza) | CPK | US | Frozen Pizza | M | TODO | 2026-04-07 | | |

## Section 95: Alcohol Complete (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2459 | IPA Beer (average craft, 12 oz) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~200 cal |
| 2460 | Lager Beer (average, 12 oz) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~150 cal |
| 2461 | Stout Beer (average, 12 oz) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~210 cal |
| 2462 | Wheat Beer (average, 12 oz) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~165 cal |
| 2463 | Sour Beer (average craft, 12 oz) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | |
| 2464 | Light Beer (average, 12 oz) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~100 cal |
| 2465 | Coors Light (12 oz) | Molson Coors | US | Alcohol | H | TODO | 2026-04-07 | | |
| 2466 | Miller Lite (12 oz) | Molson Coors | US | Alcohol | M | TODO | 2026-04-07 | | |
| 2467 | Heineken (12 oz) | Heineken | NL | Alcohol | M | TODO | 2026-04-07 | | |
| 2468 | Blue Moon Belgian White (12 oz) | Molson Coors | US | Alcohol | M | TODO | 2026-04-07 | | |
| 2469 | Stella Artois (12 oz) | AB InBev | BE | Alcohol | M | TODO | 2026-04-07 | | |
| 2470 | Cabernet Sauvignon (5 oz glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~125 cal |
| 2471 | Pinot Noir (5 oz glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~120 cal |
| 2472 | Sauvignon Blanc (5 oz glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | |
| 2473 | Rose Wine (5 oz glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~120 cal |
| 2474 | Pinot Grigio (5 oz glass) | Generic | IT | Alcohol | M | TODO | 2026-04-07 | | |
| 2475 | Moscato (5 oz glass) | Generic | IT | Alcohol | M | TODO | 2026-04-07 | | Sweet wine |
| 2476 | White Rum (1.5 oz shot) | Generic | PR | Alcohol | M | TODO | 2026-04-07 | | |
| 2477 | Dark Rum (1.5 oz shot) | Generic | JM | Alcohol | M | TODO | 2026-04-07 | | |
| 2478 | Martini (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~175 cal |
| 2479 | Espresso Martini (per glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~225 cal |
| 2480 | High Noon Vodka Soda (12 oz, any flavor) | High Noon | US | Alcohol | M | TODO | 2026-04-07 | | 100 cal |
| 2481 | Sake (5 oz, hot or cold) | Generic | JP | Alcohol | M | TODO | 2026-04-07 | | ~175 cal |
| 2482 | Bloody Mary (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~200 cal |
| 2483 | Tequila Sunrise (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | |
| 2484 | Tom Collins (per glass) | Generic | US | Alcohol | L | TODO | 2026-04-07 | | |
| 2485 | Vodka Soda (per glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~97 cal |
| 2486 | Gin and Tonic (per glass) | Generic | GB | Alcohol | H | TODO | 2026-04-07 | | ~170 cal |
# Batch 2: Branded & Packaged Food Products (Grocery Store Items)

> **Total items:** 2500
> **Number range:** 5151–7650
> **Generated:** 2026-04-07

## Section 99: Trader Joe's Complete Product Line (120 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2487 | Everything But The Bagel Seasoning | Trader Joe's | US | Condiments | H | TODO | 2026-04-07 | | Iconic seasoning blend |
| 2488 | Gone Bananas Chocolate Covered Banana Slices | Trader Joe's | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 2489 | Spatchcocked Lemon Herb Chicken | Trader Joe's | US | Meat | H | TODO | 2026-04-07 | | |
| 2490 | Pork Gyoza Potstickers | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2491 | Turkey Corn Dogs | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2492 | Mini Hold The Cone Ice Cream Cones | Trader Joe's | US | Frozen Desserts | H | TODO | 2026-04-07 | | |
| 2493 | Peanut Butter Filled Pretzel Nuggets | Trader Joe's | US | Snacks | H | TODO | 2026-04-07 | | |
| 2494 | Shawarma Chicken Thighs | Trader Joe's | US | Meat | M | TODO | 2026-04-07 | | |
| 2495 | Joe-Joe's Chocolate Cream Cookies | Trader Joe's | US | Cookies | H | TODO | 2026-04-07 | | |
| 2496 | Mango Cream Bars | Trader Joe's | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 2497 | Thai Vegetable Gyoza | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2498 | Soy Chorizo | Trader Joe's | US | Plant-Based | H | TODO | 2026-04-07 | | Popular vegan item |
| 2499 | Cowboy Bark Chocolate | Trader Joe's | US | Candy | M | TODO | 2026-04-07 | | Seasonal favorite |
| 2500 | Bamba Peanut Snacks | Trader Joe's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2501 | Cruciferous Crunch Collection | Trader Joe's | US | Produce | M | TODO | 2026-04-07 | | Salad kit |
| 2502 | Umami Seasoning Blend | Trader Joe's | US | Condiments | H | TODO | 2026-04-07 | | |
| 2503 | Chile Lime Seasoning Blend | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | |
| 2504 | 21 Seasoning Salute | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | |
| 2505 | Ube Mochi Pancake & Waffle Mix | Trader Joe's | US | Baking | H | TODO | 2026-04-07 | | Cult following |
| 2506 | Magnifisauce | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | |
| 2507 | Bomba Sauce | Trader Joe's | US | Condiments | H | TODO | 2026-04-07 | | Italian chili sauce |
| 2508 | Korean Beef Short Ribs | Trader Joe's | US | Meat | M | TODO | 2026-04-07 | | |
| 2509 | Cacio e Pepe Pasta | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2510 | Organic Açaí Bowls | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2511 | Steamed Chicken Soup Dumplings | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2512 | Mushroom & Truffle Flatbread | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2513 | Harvest Cinnamon Granola | Trader Joe's | US | Cereal | M | TODO | 2026-04-07 | | |
| 2514 | Chicken Cilantro Mini Wontons | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2515 | Cauliflower Thins | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 2516 | Sriracha Shrimp Bowl | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2517 | Argentinian Red Shrimp | Trader Joe's | US | Seafood | M | TODO | 2026-04-07 | | |
| 2518 | Frozen Butter Croissants | Trader Joe's | US | Frozen Bakery | H | TODO | 2026-04-07 | | |
| 2519 | Chili Onion Crunch | Trader Joe's | US | Condiments | H | TODO | 2026-04-07 | | |
| 2520 | Scallion Pancakes | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2521 | Honey Walnut Shrimp | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2522 | Bibimbap Bowl | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2523 | Zhoug Sauce | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | Yemeni hot sauce |
| 2524 | Danish Kringle Almond | Trader Joe's | US | Bakery | H | TODO | 2026-04-07 | | |
| 2525 | Buffalo Style Chicken Dip | Trader Joe's | US | Dips | M | TODO | 2026-04-07 | | |
| 2526 | Mediterranean Hummus | Trader Joe's | US | Dips | H | TODO | 2026-04-07 | | |
| 2527 | Chicken Breast Tenderloins Frozen | Trader Joe's | US | Meat | H | TODO | 2026-04-07 | | |
| 2528 | Spicy Miso Ramen Bowl | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2529 | Bambino Pizza Formaggio | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | Mini cheese pizza |
| 2530 | Frozen Chocolate Croissants | Trader Joe's | US | Frozen Bakery | H | TODO | 2026-04-07 | | |
| 2531 | Organic Grass-Fed Beef Patties | Trader Joe's | US | Meat | M | TODO | 2026-04-07 | | |
| 2532 | Turkey Bolognese | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2533 | Oat Milk Shelf Stable | Trader Joe's | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 2534 | Thai Tea Mochi Ice Cream | Trader Joe's | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 2535 | Honey Aleppo Sauce | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | |
| 2536 | Protein Patties Plant-Based | Trader Joe's | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 2537 | Organic Stone Ground Corn Tortillas | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 2538 | White Cheddar Corn Puffs | Trader Joe's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2539 | Chicken Spring Rolls | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2540 | Everything Ciabatta Rolls | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 2541 | Banana Bread Mix | Trader Joe's | US | Baking | M | TODO | 2026-04-07 | | |
| 2542 | Mini Brie Bites | Trader Joe's | US | Dairy | M | TODO | 2026-04-07 | | |
| 2543 | Sublime Ice Cream Sandwiches | Trader Joe's | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 2544 | Jalapeño Limeade | Trader Joe's | US | Beverages | L | TODO | 2026-04-07 | | |
| 2545 | Chocolate Hummus | Trader Joe's | US | Snacks | L | TODO | 2026-04-07 | | |
| 2546 | Strawberry Lemonade | Trader Joe's | US | Beverages | M | TODO | 2026-04-07 | | |
| 2547 | Triple Berry O's Cereal | Trader Joe's | US | Cereal | M | TODO | 2026-04-07 | | |
| 2548 | Chicken Shu Mai | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2549 | Japanese Mochi Rice Nuggets | Trader Joe's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2550 | Chimichurri Rice Bowl | Trader Joe's | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 2551 | Kale & Mushroom Turnover | Trader Joe's | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 2552 | Organic Watermelon Jerky | Trader Joe's | US | Snacks | L | TODO | 2026-04-07 | | |
| 2553 | Strawberry Rhubarb Pie | Trader Joe's | US | Frozen Desserts | L | TODO | 2026-04-07 | | |
| 2554 | Chocolate Chip Scone Mix | Trader Joe's | US | Baking | L | TODO | 2026-04-07 | | |
| 2555 | Organic Peanut Butter Creamy | Trader Joe's | US | Spreads | M | TODO | 2026-04-07 | | |
| 2556 | Aussie Style Chocolate Licorice | Trader Joe's | US | Candy | L | TODO | 2026-04-07 | | |

## Section 100: Costco/Kirkland Signature Full Line (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2557 | Food Court Hot Dog & Soda Combo | Costco | US | Food Court | H | TODO | 2026-04-07 | | Iconic $1.50 combo |
| 2558 | Food Court Açaí Bowl | Costco | US | Food Court | H | TODO | 2026-04-07 | | |
| 2559 | Protein Bars Chocolate Brownie | Kirkland Signature | US | Protein Bars | H | TODO | 2026-04-07 | | |
| 2560 | Wild Caught Alaskan Salmon Fillets | Kirkland Signature | US | Seafood | H | TODO | 2026-04-07 | | |
| 2561 | Organic Cage-Free Large Eggs | Kirkland Signature | US | Dairy | H | TODO | 2026-04-07 | | |
| 2562 | Mixed Nuts Salted | Kirkland Signature | US | Snacks | H | TODO | 2026-04-07 | | |
| 2563 | Organic Peanut Butter | Kirkland Signature | US | Spreads | H | TODO | 2026-04-07 | | |
| 2564 | Frozen Organic Blueberries | Kirkland Signature | US | Frozen Fruit | H | TODO | 2026-04-07 | | |
| 2565 | Frozen Organic Strawberries | Kirkland Signature | US | Frozen Fruit | H | TODO | 2026-04-07 | | |
| 2566 | Frozen Mixed Berry Blend | Kirkland Signature | US | Frozen Fruit | H | TODO | 2026-04-07 | | |
| 2567 | Frozen Stir Fry Vegetables | Kirkland Signature | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 2568 | Butter Croissants 12-Pack | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 2569 | Blueberry Muffins 6-Pack | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 2570 | Everything Bagels 6-Pack | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 2571 | Cheese Danish 6-Pack | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 2572 | Half Sheet Cake White | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 2573 | Half Sheet Cake Chocolate | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 2574 | Tiramisu Bar Cake | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 2575 | Whole Chicken Wings | Kirkland Signature | US | Meat | M | TODO | 2026-04-07 | | |
| 2576 | Organic Hummus Singles | Kirkland Signature | US | Dips | M | TODO | 2026-04-07 | | |
| 2577 | Cashew Clusters | Kirkland Signature | US | Snacks | M | TODO | 2026-04-07 | | |
| 2578 | Organic Chicken Stock | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 2579 | Canned Albacore Tuna | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 2580 | Grass-Fed Beef Patties | Kirkland Signature | US | Meat | H | TODO | 2026-04-07 | | |
| 2581 | Organic Quinoa | Kirkland Signature | US | Grains | M | TODO | 2026-04-07 | | |
| 2582 | Walnut Halves | Kirkland Signature | US | Snacks | M | TODO | 2026-04-07 | | |
| 2583 | Dried Mangoes | Kirkland Signature | US | Snacks | H | TODO | 2026-04-07 | | |
| 2584 | Organic Tomato Sauce | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 2585 | Bath Tissue (just kidding) Raspberry Crumble Cookies | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 2586 | Cheese Flight Tray | Kirkland Signature | US | Dairy | M | TODO | 2026-04-07 | | |
| 2587 | Marinated Artichoke Hearts | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 2588 | Master Carve Half Ham | Kirkland Signature | US | Deli | M | TODO | 2026-04-07 | | |
| 2589 | Mini Chocolate Chip Cookies Tub | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 2590 | Bath Tissue Mango Habanero Salsa | Kirkland Signature | US | Condiments | M | TODO | 2026-04-07 | | |
| 2591 | Vanilla Almond Milk | Kirkland Signature | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 2592 | Ground Turkey | Kirkland Signature | US | Meat | M | TODO | 2026-04-07 | | |
| 2593 | Atlantic Salmon Fillets | Kirkland Signature | US | Seafood | H | TODO | 2026-04-07 | | |
| 2594 | Organic Diced Tomatoes | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 2595 | Chocolate Cake Bakery | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 2596 | Tuxedo Mousse Cake | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 2597 | Cinnamon Pull-Apart Bread | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 2598 | Organic Ground Beef 85/15 | Kirkland Signature | US | Meat | H | TODO | 2026-04-07 | | |
| 2599 | Vanilla Greek Yogurt | Kirkland Signature | US | Dairy | M | TODO | 2026-04-07 | | |
| 2600 | Raw Almonds 3lb | Kirkland Signature | US | Snacks | H | TODO | 2026-04-07 | | |
| 2601 | Pistachio Kernels | Kirkland Signature | US | Snacks | M | TODO | 2026-04-07 | | |
| 2602 | Croissant Sandwich Tray | Kirkland Signature | US | Deli | M | TODO | 2026-04-07 | | |
| 2603 | Frozen Acai Packets | Kirkland Signature | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 2604 | Honey Bear 5lb | Kirkland Signature | US | Sweetener | M | TODO | 2026-04-07 | | |
| 2605 | Organic Fruit & Veggie Pouches | Kirkland Signature | US | Baby Food | M | TODO | 2026-04-07 | | |
| 2606 | Protein Shake Chocolate 18-Pack | Kirkland Signature | US | Beverages | H | TODO | 2026-04-07 | | |
| 2607 | Protein Shake Vanilla 18-Pack | Kirkland Signature | US | Beverages | H | TODO | 2026-04-07 | | |

## Section 101: Aldi Exclusive Products (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2608 | Garlic Breadsticks | Mama Cozzi's | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 2609 | White Cheddar Popcorn | Clancy's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2610 | Pretzel Sticks | Clancy's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2611 | Kettle Chips Sea Salt | Clancy's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2612 | Protein Shake Chocolate | Elevation | US | Beverages | M | TODO | 2026-04-07 | | |
| 2613 | Energy Bar Fruit & Nut | Elevation | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 2614 | Chicken Patties Frozen | Fit & Active | US | Frozen Meals | M | TODO | 2026-04-07 | | Aldi brand |
| 2615 | Turkey Burgers Frozen | Fit & Active | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2616 | Light Yogurt Strawberry | Fit & Active | US | Dairy | M | TODO | 2026-04-07 | | |
| 2617 | Cheese Sticks Mozzarella | Fit & Active | US | Dairy | M | TODO | 2026-04-07 | | |
| 2618 | Organic Pasta Sauce Marinara | Simply Nature | US | Condiments | M | TODO | 2026-04-07 | | Aldi brand |
| 2619 | Organic Salsa Medium | Simply Nature | US | Condiments | M | TODO | 2026-04-07 | | |
| 2620 | Organic Applesauce Pouches | Simply Nature | US | Snacks | M | TODO | 2026-04-07 | | |
| 2621 | Organic Peanut Butter Creamy | Simply Nature | US | Spreads | M | TODO | 2026-04-07 | | |
| 2622 | Aged Reserve White Cheddar | Specially Selected | US | Dairy | M | TODO | 2026-04-07 | | Aldi premium |
| 2623 | Ravioli Mushroom Truffle | Specially Selected | US | Pasta | M | TODO | 2026-04-07 | | |
| 2624 | Gluten Free Brownie Mix | liveGfree | US | Baking | M | TODO | 2026-04-07 | | Aldi GF brand |
| 2625 | Gluten Free Pizza Crust | liveGfree | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2626 | Gluten Free Bread Multigrain | liveGfree | US | Bread | M | TODO | 2026-04-07 | | |
| 2627 | Gluten Free Mac & Cheese | liveGfree | US | Pasta | M | TODO | 2026-04-07 | | |
| 2628 | Gluten Free Crackers Sea Salt | liveGfree | US | Snacks | M | TODO | 2026-04-07 | | |
| 2629 | 2% Milk Gallon | Friendly Farms | US | Dairy | H | TODO | 2026-04-07 | | |
| 2630 | Frozen Stir Fry Vegetables | Season's Choice | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 2631 | Frozen Edamame | Season's Choice | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 2632 | Donut Shop K-Cup Medium Roast | Barissimo | US | Beverages | M | TODO | 2026-04-07 | | Aldi coffee |
| 2633 | French Roast Ground Coffee | Barissimo | US | Beverages | M | TODO | 2026-04-07 | | |
| 2634 | Colombian Ground Coffee | Barissimo | US | Beverages | M | TODO | 2026-04-07 | | |
| 2635 | Bavarian Soft Pretzels | Deutsche Küche | US | Frozen Snacks | M | TODO | 2026-04-07 | | German items |
| 2636 | Pork Schnitzel | Deutsche Küche | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2637 | German Chocolate Assortment | Deutsche Küche | US | Candy | M | TODO | 2026-04-07 | | |
| 2638 | Stollen Bites | Deutsche Küche | US | Bakery | L | TODO | 2026-04-07 | | Seasonal |
| 2639 | Entertainer Crackers Water | Savoritz | US | Snacks | M | TODO | 2026-04-07 | | Aldi crackers |
| 2640 | Buttery Round Crackers | Savoritz | US | Snacks | M | TODO | 2026-04-07 | | |
| 2641 | Woven Wheat Crackers | Savoritz | US | Snacks | M | TODO | 2026-04-07 | | |
| 2642 | Yellow Cake Mix | Baker's Corner | US | Baking | M | TODO | 2026-04-07 | | |
| 2643 | Brownie Mix Fudge | Baker's Corner | US | Baking | M | TODO | 2026-04-07 | | |
| 2644 | Organic Baby Spinach | Little Salad Bar | US | Produce | M | TODO | 2026-04-07 | | Aldi produce |
| 2645 | Oat Milk Original | Friendly Farms | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 2646 | Frozen Berry Medley | Season's Choice | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 2647 | Chicken Breast Tenders Frozen | Kirkwood | US | Frozen Meals | H | TODO | 2026-04-07 | | Aldi chicken brand |
| 2648 | Hot Dogs Beef | Parkview | US | Meat | M | TODO | 2026-04-07 | | Aldi meat brand |
| 2649 | Bratwurst Original | Parkview | US | Meat | M | TODO | 2026-04-07 | | |
| 2650 | Bacon Hickory Smoked | Appleton Farms | US | Meat | H | TODO | 2026-04-07 | | Aldi meat brand |
| 2651 | Sliced Ham Honey Deli | Appleton Farms | US | Deli | M | TODO | 2026-04-07 | | |
| 2652 | Frozen Cauliflower Pizza | Earth Grown | US | Plant-Based | M | TODO | 2026-04-07 | | Aldi plant-based |
| 2653 | Veggie Burgers Black Bean | Earth Grown | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 2654 | Chicken-Less Tenders | Earth Grown | US | Plant-Based | M | TODO | 2026-04-07 | | |

## Section 102: Target Good & Gather / Favorite Day (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2655 | Boneless Skinless Chicken Breast | Good & Gather | US | Meat | H | TODO | 2026-04-07 | | Target brand |
| 2656 | Original Hummus | Good & Gather | US | Dips | M | TODO | 2026-04-07 | | |
| 2657 | Medium Salsa | Good & Gather | US | Condiments | M | TODO | 2026-04-07 | | |
| 2658 | Marinara Pasta Sauce | Good & Gather | US | Condiments | M | TODO | 2026-04-07 | | |
| 2659 | Turkey & Cheese Snack Kit | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 2660 | Organic Cage-Free Eggs | Good & Gather | US | Dairy | H | TODO | 2026-04-07 | | |
| 2661 | Organic Baby Spinach | Good & Gather | US | Produce | M | TODO | 2026-04-07 | | |
| 2662 | Organic Peanut Butter Creamy | Good & Gather | US | Spreads | M | TODO | 2026-04-07 | | |
| 2663 | Sea Salt Popcorn | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 2664 | Frozen Mixed Berry Blend | Good & Gather | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 2665 | Protein Snack Box | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 2666 | Organic Apple Sauce Pouches | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 2667 | Frozen Cheese Ravioli | Good & Gather | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2668 | Honey Roasted Cashews | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 2669 | Chocolate Chip Cookies Soft Baked | Favorite Day | US | Cookies | H | TODO | 2026-04-07 | | Target brand |
| 2670 | Vanilla Bean Ice Cream | Favorite Day | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 2671 | Chocolate Fudge Brownie Ice Cream | Favorite Day | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 2672 | Birthday Cake Ice Cream | Favorite Day | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 2673 | Sour Gummy Worms | Favorite Day | US | Candy | M | TODO | 2026-04-07 | | |
| 2674 | Chocolate Chip Muffins 4-Pack | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 2675 | Double Chocolate Cake | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 2676 | Brownie Bites | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 2677 | Butter Croissants | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 2678 | Sugar Cookies Frosted | Favorite Day | US | Cookies | M | TODO | 2026-04-07 | | |
| 2679 | Peanut Butter Cups | Favorite Day | US | Candy | M | TODO | 2026-04-07 | | |
| 2680 | Cookie Dough Bites | Favorite Day | US | Candy | M | TODO | 2026-04-07 | | |
| 2681 | Mint Chip Ice Cream | Favorite Day | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 2682 | Strawberry Cheesecake Ice Cream | Favorite Day | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 2683 | Lemon Cake | Favorite Day | US | Bakery | L | TODO | 2026-04-07 | | |
| 2684 | Cinnamon Coffee Cake | Favorite Day | US | Bakery | L | TODO | 2026-04-07 | | |
| 2685 | Blueberry Muffins 4-Pack | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 2686 | Cheese Danish | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 2687 | Caramel Corn | Favorite Day | US | Snacks | M | TODO | 2026-04-07 | | |
| 2688 | Chocolate Covered Pretzels | Favorite Day | US | Candy | M | TODO | 2026-04-07 | | |
| 2689 | Assorted Macarons | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 2690 | Frozen Fruit Bars Strawberry | Favorite Day | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 2691 | Frozen Fruit Bars Mango | Favorite Day | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 2692 | Ice Cream Sandwiches Vanilla | Favorite Day | US | Frozen Desserts | M | TODO | 2026-04-07 | | |

## Section 103: Walmart Great Value Full Range (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2693 | Canned Whole Kernel Corn | Great Value | US | Canned Goods | H | TODO | 2026-04-07 | | Walmart brand |
| 2694 | Frozen Waffles Buttermilk | Great Value | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 2695 | Cheddar Goldfish-Style Crackers | Great Value | US | Snacks | M | TODO | 2026-04-07 | | |
| 2696 | Large White Eggs 18ct | Great Value | US | Dairy | H | TODO | 2026-04-07 | | |
| 2697 | Spaghetti Pasta | Great Value | US | Pasta | H | TODO | 2026-04-07 | | |
| 2698 | Marinara Pasta Sauce | Great Value | US | Condiments | M | TODO | 2026-04-07 | | |
| 2699 | Real Mayonnaise | Great Value | US | Condiments | M | TODO | 2026-04-07 | | |
| 2700 | Honey Nut Toasted Oats Cereal | Great Value | US | Cereal | H | TODO | 2026-04-07 | | |
| 2701 | Fruit Rings Cereal | Great Value | US | Cereal | M | TODO | 2026-04-07 | | |
| 2702 | Purified Drinking Water 24-Pack | Great Value | US | Beverages | H | TODO | 2026-04-07 | | |
| 2703 | Granulated Sugar 4lb | Great Value | US | Baking | M | TODO | 2026-04-07 | | |
| 2704 | Creamy Peanut Butter | Great Value | US | Spreads | H | TODO | 2026-04-07 | | |
| 2705 | Chunk Light Tuna in Water | Great Value | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 2706 | Mac & Cheese Original | Great Value | US | Pasta | H | TODO | 2026-04-07 | | |
| 2707 | Long Grain White Rice 5lb | Great Value | US | Grains | M | TODO | 2026-04-07 | | |
| 2708 | Hot Dog Buns 8ct | Great Value | US | Bread | M | TODO | 2026-04-07 | | |
| 2709 | Hamburger Buns 8ct | Great Value | US | Bread | M | TODO | 2026-04-07 | | |
| 2710 | Honey 12oz | Great Value | US | Sweetener | M | TODO | 2026-04-07 | | |
| 2711 | Pancake Mix Buttermilk | Great Value | US | Baking | M | TODO | 2026-04-07 | | |
| 2712 | Maple Flavored Syrup | Great Value | US | Condiments | M | TODO | 2026-04-07 | | |

## Section 104: HelloFresh & Meal Kit Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2713 | Creamy Dijon Chicken | HelloFresh | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 2714 | Teriyaki Beef Stir-Fry | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2715 | Figgy Balsamic Pork Chops | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2716 | Thai Coconut Curry Chicken | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2717 | Garlic Herb Butter Steak | HelloFresh | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 2718 | Tuscan Heat Spiced Chicken | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2719 | Crispy Cheddar Chicken | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2720 | Seared Salmon & Salsa Verde | Blue Apron | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 2721 | Spiced Lamb Meatballs | Blue Apron | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2722 | Crispy Chicken Thighs | Blue Apron | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2723 | Seared Steaks & Miso Butter | Blue Apron | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 2724 | Pan-Seared Cod | Blue Apron | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2725 | BBQ Pork Tacos | EveryPlate | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2726 | Cheesy Beef Pasta Bake | EveryPlate | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2727 | Crispy Chicken Milanese | Home Chef | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2728 | Steak Fajita Bowl | Home Chef | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2729 | Keto Chicken Margherita | Factor | US | Prepared Meals | H | TODO | 2026-04-07 | | Ready-to-heat |
| 2730 | Keto Bacon Cheeseburger Bowl | Factor | US | Prepared Meals | H | TODO | 2026-04-07 | | |
| 2731 | Protein Plus Grilled Steak | Factor | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2732 | Vegan & Veggie Coconut Curry | Factor | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2733 | Chef's Choice Salmon Bowl | Factor | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2734 | Steak Peppercorn Prepared | Freshly | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2735 | Chicken Pesto Penne | Freshly | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2736 | Buffalo Chicken Bowl | Freshly | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2737 | Organic Grass-Fed Beef Bowl | Trifecta | US | Prepared Meals | M | TODO | 2026-04-07 | | Fitness-focused |
| 2738 | Grilled Chicken & Veggies | Trifecta | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2739 | Grass-Fed Steak Bowl | Territory Foods | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2740 | Pan-Seared Salmon Bowl | CookUnity | US | Prepared Meals | M | TODO | 2026-04-07 | | Chef-crafted |
| 2741 | Chicken Tikka Bowl | CookUnity | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2742 | Black Bean Burger Kit | Hungryroot | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 2743 | Almond Chickpea Cookie Dough | Hungryroot | US | Snacks | L | TODO | 2026-04-07 | | |
| 2744 | Strawberry + Cherry Smoothie | Daily Harvest | US | Smoothies | H | TODO | 2026-04-07 | | |
| 2745 | Mint + Cacao Smoothie | Daily Harvest | US | Smoothies | M | TODO | 2026-04-07 | | |
| 2746 | Banana + Greens Smoothie | Daily Harvest | US | Smoothies | H | TODO | 2026-04-07 | | |
| 2747 | Flatbread Kabocha + Sage | Daily Harvest | US | Flatbreads | M | TODO | 2026-04-07 | | |
| 2748 | Chocolate + Blueberry Oat Bowl | Daily Harvest | US | Bowls | M | TODO | 2026-04-07 | | |
| 2749 | Broccoli + Cheese Flatbread | Daily Harvest | US | Flatbreads | M | TODO | 2026-04-07 | | |
| 2750 | Ginger + Turmeric Latte | Daily Harvest | US | Beverages | L | TODO | 2026-04-07 | | |
| 2751 | Mango + Papaya Smoothie | Daily Harvest | US | Smoothies | M | TODO | 2026-04-07 | | |
| 2752 | Acai + Cherry Smoothie | Daily Harvest | US | Smoothies | M | TODO | 2026-04-07 | | |
| 2753 | Lemongrass + Coconut Curry | Daily Harvest | US | Bowls | M | TODO | 2026-04-07 | | |
| 2754 | Cinnamon + Banana Oat Bowl | Daily Harvest | US | Bowls | M | TODO | 2026-04-07 | | |

## Section 105: Weight Management Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2755 | Smart Ones Santa Fe Style Rice & Beans | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2756 | Smart Ones Chicken Enchilada Suiza | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2757 | Smart Ones Broccoli & Cheddar Potatoes | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2758 | Smart Ones Meatloaf | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2759 | WW Protein Stix Chocolate Peanut Butter | WW (Weight Watchers) | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 2760 | WW Protein Stix Cookies & Cream | WW (Weight Watchers) | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 2761 | WW Chocolate Cake Snack Bar | WW (Weight Watchers) | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 2762 | WW Ice Cream Bars Chocolate Fudge | WW (Weight Watchers) | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 2763 | WW Ice Cream Bars Salted Caramel | WW (Weight Watchers) | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 2764 | Nutrisystem Hamburger | Nutrisystem | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2765 | Nutrisystem Thick Crust Pizza | Nutrisystem | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2766 | Nutrisystem Chocolate Brownie | Nutrisystem | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 2767 | Nutrisystem Meatball Parmesan Melt | Nutrisystem | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2768 | Nutrisystem Chocolate Shake | Nutrisystem | US | Beverages | M | TODO | 2026-04-07 | | |
| 2769 | Nutrisystem Rotini & Meatballs | Nutrisystem | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2770 | Jenny Craig Chicken Fettuccine | Jenny Craig | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2771 | Jenny Craig Turkey Burger | Jenny Craig | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 2772 | Jenny Craig Chocolate Lava Cake | Jenny Craig | US | Snacks | L | TODO | 2026-04-07 | | |
| 2773 | SlimFast Advanced Nutrition Chocolate Shake | SlimFast | US | Beverages | H | TODO | 2026-04-07 | | |
| 2774 | SlimFast Advanced Nutrition Vanilla Shake | SlimFast | US | Beverages | H | TODO | 2026-04-07 | | |
| 2775 | SlimFast Advanced Nutrition Caramel Shake | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 2776 | SlimFast Keto Fat Bomb Chocolate Shake | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 2777 | SlimFast Keto Fat Bomb Peanut Butter Cup | SlimFast | US | Snacks | M | TODO | 2026-04-07 | | |
| 2778 | SlimFast Bake Shop Chocolatey Crispy Bar | SlimFast | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 2779 | SlimFast Snack Bites Peanut Butter Chocolate | SlimFast | US | Snacks | M | TODO | 2026-04-07 | | |
| 2780 | SlimFast Original Shake Powder Chocolate | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 2781 | Optavia Fueling Chocolate Shake | Optavia | US | Beverages | M | TODO | 2026-04-07 | | |
| 2782 | Optavia Fueling Cinnamon Crunchy O's | Optavia | US | Cereal | L | TODO | 2026-04-07 | | |
| 2783 | Optavia Fueling Zesty Cheddar Cracker | Optavia | US | Snacks | L | TODO | 2026-04-07 | | |
| 2784 | Optavia Fueling Essential Bar Drizzled Chocolate | Optavia | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 2785 | Optavia Fueling Wild Berry Shake | Optavia | US | Beverages | L | TODO | 2026-04-07 | | |
| 2786 | Optavia Fueling Rustic Tomato Herb Penne | Optavia | US | Prepared Meals | L | TODO | 2026-04-07 | | |
| 2787 | Optavia Fueling Mac & Cheese | Optavia | US | Prepared Meals | L | TODO | 2026-04-07 | | |
| 2788 | Medifast Chocolate Shake | Medifast | US | Beverages | L | TODO | 2026-04-07 | | |
| 2789 | Medifast Dutch Chocolate Shake | Medifast | US | Beverages | L | TODO | 2026-04-07 | | |
| 2790 | Medifast Caramel Crunch Bar | Medifast | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 2791 | Smart Ones Lasagna with Meat Sauce | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2792 | SlimFast Diabetic Weight Loss Chocolate Shake | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 2793 | SlimFast High Protein Shake Strawberry | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 2794 | Nutrisystem Cinnamon Raisin Baked Bar | Nutrisystem | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 2795 | Jenny Craig Anytime Bar Lemon Meringue | Jenny Craig | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 2796 | Jenny Craig Chicken Street Tacos | Jenny Craig | US | Prepared Meals | L | TODO | 2026-04-07 | | |
| 2797 | Smart Ones Chicken Mesquite | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2798 | SlimFast Keto Meal Bar Whipped Triple Chocolate | SlimFast | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 2799 | SlimFast Original Shake Strawberry Cream | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 2800 | WW Popcorn Sea Salt | WW (Weight Watchers) | US | Snacks | M | TODO | 2026-04-07 | | |
| 2801 | WW Baked Cheese Crackers | WW (Weight Watchers) | US | Snacks | M | TODO | 2026-04-07 | | |
| 2802 | WW Peanut Butter Chocolate Snack Bar | WW (Weight Watchers) | US | Snack Bars | M | TODO | 2026-04-07 | | |

## Section 106: More Frozen Meal Brands (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2803 | Lasagna with Meat & Sauce Family Size | Stouffer's | US | Frozen Meals | H | TODO | 2026-04-07 | | Classic bestseller |
| 2804 | Macaroni & Cheese Family Size | Stouffer's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2805 | Vegetable Lasagna | Stouffer's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2806 | Beef Pot Pie | Marie Callender's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2807 | Country Fried Chicken Bowl | Marie Callender's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2808 | Power Bowl Korean Beef | Healthy Choice | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2809 | Power Bowl Cauliflower Tikka Masala | Healthy Choice | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2810 | Steamer Grilled Chicken Marinara | Healthy Choice | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2811 | Cafe Steamers Chicken Teriyaki | Lean Cuisine | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2812 | Cafe Steamers Herb Roasted Chicken | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2813 | Features Chicken Enchilada Suiza | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2814 | Features Vermont White Cheddar Mac | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2815 | Salisbury Steak Dinner | Banquet | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2816 | Turkey Dinner | Banquet | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2817 | Fried Chicken Dinner | Banquet | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2818 | Mexican Style Dinner | Banquet | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2819 | Country Fried Steak XXL Dinner | Hungry-Man | US | Frozen Meals | H | TODO | 2026-04-07 | | Large portions |
| 2820 | Boneless Fried Chicken Dinner | Hungry-Man | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2821 | Beer Battered Chicken Dinner | Hungry-Man | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2822 | Protein Bowl Southwest Style | Bird's Eye | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2823 | Steamfresh Broccoli Cuts | Bird's Eye | US | Frozen Veg | H | TODO | 2026-04-07 | | |
| 2824 | Steamfresh Mixed Vegetables | Bird's Eye | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 2825 | Cauliflower Wings Buffalo | Green Giant | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2826 | Veggie Tots Broccoli & Cheese | Green Giant | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 2827 | Riced Cauliflower Original | Green Giant | US | Frozen Veg | H | TODO | 2026-04-07 | | |
| 2828 | Veggie Spirals Zucchini | Green Giant | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 2829 | Cheese Enchilada Whole Meal | Amy's Kitchen | US | Frozen Meals | H | TODO | 2026-04-07 | | Organic brand |
| 2830 | Vegetable Lasagna | Amy's Kitchen | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2831 | Bean & Rice Burrito Non-Dairy | Amy's Kitchen | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2832 | Mac & Cheese | Amy's Kitchen | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2833 | Lamb Saag Bowl | Saffron Road | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 2834 | Awesome Burger | Sweet Earth | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 2835 | Mindful Chik'n | Sweet Earth | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 2836 | Truffle Parmesan Street Burritos | EVOL | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2837 | Chicken Enchilada Bake | EVOL | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2838 | White Cheddar Mac & Cheese | Devour | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2839 | Buffalo Chicken Mac & Cheese | Devour | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2840 | Chicken Carbonara | Devour | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2841 | Meatloaf Dinner | Boston Market | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2842 | Cilantro Lime Chicken Bowl | Kevin's Natural Foods | US | Frozen Meals | H | TODO | 2026-04-07 | | Clean ingredient |
| 2843 | Korean BBQ Chicken | Kevin's Natural Foods | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 2844 | Thai Coconut Chicken | Kevin's Natural Foods | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2845 | Lemongrass Chicken | Kevin's Natural Foods | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2846 | Chicken Enchilada Meal | Real Good Foods | US | Frozen Meals | M | TODO | 2026-04-07 | | Low-carb |
| 2847 | Stuffed Chicken Bacon & Cheese | Real Good Foods | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2848 | Cauliflower Mac & Cheese Bowl | Tattooed Chef | US | Frozen Meals | M | TODO | 2026-04-07 | | Plant-based |
| 2849 | Riced Cauliflower Stir Fry | Tattooed Chef | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2850 | Plant-Based Chik'n Nuggets | Alpha Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 2851 | Plant-Based Mexichik'n Burrito | Alpha Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 2852 | Plant-Based Pizza Puffs | Alpha Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 2853 | Meatball Parmesan Bowl | Stouffer's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2854 | Three Meat & Cheese Flatbread Melts | Stouffer's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2855 | Philly Style Cheesesteak | Stouffer's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2856 | Power Bowl Unwrapped Burrito | Healthy Choice | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2857 | Cafe Steamers Meatball Marinara | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2858 | Features Mango Chicken Sriracha | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2859 | Creamy Tomato Basil Soup | Amy's Kitchen | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 2860 | Indian Mattar Paneer | Amy's Kitchen | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2861 | Beef Bulgogi Mandu | Bibigo | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2862 | Luvo Roasted Cauliflower Mac | Luvo | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 2863 | Plant-Based Chik'n Patties | Alpha Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 2864 | Falafel Bowl | Saffron Road | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 2865 | Roasted Turkey & Vegetables | Boston Market | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 2866 | Smart Ones Pepper Steak | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |

## Section 107: Cereal Brands Complete (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2867 | Multi Grain Cheerios | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 2868 | Cheerios Protein Oats & Honey | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 2869 | Reese's Puffs | General Mills | US | Cereal | H | TODO | 2026-04-07 | | |
| 2870 | Chocolate Chex | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 2871 | Special K Protein | Kellogg's | US | Cereal | M | TODO | 2026-04-07 | | |
| 2872 | Corn Pops | Kellogg's | US | Cereal | M | TODO | 2026-04-07 | | |
| 2873 | Great Grains Banana Nut Crunch | Post | US | Cereal | M | TODO | 2026-04-07 | | |
| 2874 | Alpha-Bits | Post | US | Cereal | L | TODO | 2026-04-07 | | |
| 2875 | Instant Oatmeal Apple Cinnamon | Quaker | US | Cereal | H | TODO | 2026-04-07 | | |
| 2876 | Instant Oatmeal Peaches & Cream | Quaker | US | Cereal | M | TODO | 2026-04-07 | | |
| 2877 | Instant Oatmeal Dinosaur Eggs | Quaker | US | Cereal | M | TODO | 2026-04-07 | | |
| 2878 | Sunrise Crunchy Maple | Nature's Path | US | Cereal | M | TODO | 2026-04-07 | | |
| 2879 | Pumpkin Raisin Crunch | Nature's Path | US | Cereal | L | TODO | 2026-04-07 | | |
| 2880 | EnviroKidz Panda Puffs | Nature's Path | US | Cereal | M | TODO | 2026-04-07 | | |
| 2881 | Puffins Original | Barbara's | US | Cereal | M | TODO | 2026-04-07 | | |
| 2882 | Puffins Peanut Butter | Barbara's | US | Cereal | M | TODO | 2026-04-07 | | |
| 2883 | Organic Cinnamon Crunch | Cascadian Farm | US | Cereal | M | TODO | 2026-04-07 | | |
| 2884 | Organic Honey Oat Granola | Cascadian Farm | US | Cereal | M | TODO | 2026-04-07 | | |
| 2885 | Organic Purely O's | Cascadian Farm | US | Cereal | M | TODO | 2026-04-07 | | |
| 2886 | Old Fashioned Oats | Quaker | US | Cereal | H | TODO | 2026-04-07 | | |
| 2887 | Golden Grahams | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 2888 | Cookie Crisp | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 2889 | Kix Original | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 2890 | Total Whole Grain | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 2891 | Wheaties | General Mills | US | Cereal | M | TODO | 2026-04-07 | | Breakfast of Champions |
| 2892 | Smart Start Original | Kellogg's | US | Cereal | L | TODO | 2026-04-07 | | |
| 2893 | Instant Oatmeal Blueberries & Cream | Quaker | US | Cereal | M | TODO | 2026-04-07 | | |
| 2894 | Instant Oatmeal Honey & Almonds | Quaker | US | Cereal | M | TODO | 2026-04-07 | | |
| 2895 | Quick 1-Minute Oats | Quaker | US | Cereal | H | TODO | 2026-04-07 | | |
| 2896 | Organic Flax Plus Multibran | Nature's Path | US | Cereal | L | TODO | 2026-04-07 | | |
| 2897 | Honey Smacks | Kellogg's | US | Cereal | M | TODO | 2026-04-07 | | |
| 2898 | Grape-Nuts Flakes | Post | US | Cereal | L | TODO | 2026-04-07 | | |
| 2899 | Shredded Wheat Original | Post | US | Cereal | M | TODO | 2026-04-07 | | |
| 2900 | S'mores Cereal | General Mills | US | Cereal | L | TODO | 2026-04-07 | | |
| 2901 | Cinnamon Cheerios | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 2902 | Blueberry Cheerios | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 2903 | Crispix | Kellogg's | US | Cereal | M | TODO | 2026-04-07 | | |
| 2904 | Muesli Blueberry Pecan | Post | US | Cereal | L | TODO | 2026-04-07 | | |

## Section 108: Yogurt & Dairy Brands Complete (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2905 | Activia Blueberry Probiotic Yogurt | Dannon | US | Dairy | M | TODO | 2026-04-07 | | |
| 2906 | Light & Fit Greek Vanilla | Dannon | US | Dairy | H | TODO | 2026-04-07 | | |
| 2907 | Light & Fit Greek Strawberry | Dannon | US | Dairy | H | TODO | 2026-04-07 | | |
| 2908 | Light & Fit Original Peach | Dannon | US | Dairy | M | TODO | 2026-04-07 | | |
| 2909 | Yoplait Light Harvest Peach | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 2910 | Yoplait Light Blueberry Patch | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 2911 | Go-Gurt Strawberry Splash | Yoplait | US | Dairy | H | TODO | 2026-04-07 | | Kids squeezable |
| 2912 | Go-Gurt Berry | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 2913 | Oui French Style Vanilla | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | Glass jar |
| 2914 | Oui French Style Strawberry | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 2915 | Noosa Blueberry | Noosa | US | Dairy | M | TODO | 2026-04-07 | | |
| 2916 | La Yogurt Probiotic Strawberry | La Yogurt | US | Dairy | M | TODO | 2026-04-07 | | |
| 2917 | Brown Cow Cream Top Vanilla | Brown Cow | US | Dairy | M | TODO | 2026-04-07 | | |
| 2918 | Stonyfield Organic Vanilla | Stonyfield | US | Dairy | M | TODO | 2026-04-07 | | |
| 2919 | Wallaby Organic Greek Plain | Wallaby | US | Dairy | M | TODO | 2026-04-07 | | |
| 2920 | Almond Milk Yogurt Vanilla | Kite Hill | US | Dairy Alt | M | TODO | 2026-04-07 | | Plant-based |
| 2921 | Dairy-Free Yogurt Strawberry | Silk | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 2922 | Dairy-Free Yogurt Vanilla | Silk | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 2923 | Coconut Milk Yogurt Vanilla | So Delicious | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 2924 | Coconut Milk Yogurt Strawberry Banana | So Delicious | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 2925 | Cashewmilk Yogurt Vanilla Bean | Forager | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 2926 | Cashewmilk Yogurt Blueberry | Forager | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 2927 | Low Fat Kefir Strawberry | Lifeway | US | Dairy | M | TODO | 2026-04-07 | | |
| 2928 | Low Fat Kefir Blueberry | Lifeway | US | Dairy | M | TODO | 2026-04-07 | | |
| 2929 | Tillamook Extra Sharp Cheddar | Tillamook | US | Dairy | H | TODO | 2026-04-07 | | |
| 2930 | Tillamook Marionberry Pie Ice Cream | Tillamook | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 2931 | Cabot Seriously Sharp Cheddar | Cabot | US | Dairy | H | TODO | 2026-04-07 | | Vermont coop |
| 2932 | Organic Valley Butter | Organic Valley | US | Dairy | M | TODO | 2026-04-07 | | |
| 2933 | Horizon Organic 2% Milk | Horizon | US | Dairy | M | TODO | 2026-04-07 | | |
| 2934 | Borden American Singles | Borden | US | Dairy | M | TODO | 2026-04-07 | | |
| 2935 | Lactaid 2% Reduced Fat Milk | Lactaid | US | Dairy | H | TODO | 2026-04-07 | | |
| 2936 | Lactaid Chocolate Milk | Lactaid | US | Dairy | M | TODO | 2026-04-07 | | |
| 2937 | Stonyfield Organic Kids Strawberry Banana | Stonyfield | US | Dairy | M | TODO | 2026-04-07 | | |
| 2938 | Noosa Coconut | Noosa | US | Dairy | M | TODO | 2026-04-07 | | |
| 2939 | Noosa Salted Caramel | Noosa | US | Dairy | M | TODO | 2026-04-07 | | |
| 2940 | Yoplait Greek 100 Strawberry | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 2941 | Tillamook Colby Jack Cheese | Tillamook | US | Dairy | M | TODO | 2026-04-07 | | |
| 2942 | Cabot White Cheddar Cracker Cuts | Cabot | US | Dairy | M | TODO | 2026-04-07 | | |
| 2943 | Wallaby Organic Aussie Greek Strawberry | Wallaby | US | Dairy | L | TODO | 2026-04-07 | | |
| 2944 | La Yogurt Probiotic Mango | La Yogurt | US | Dairy | M | TODO | 2026-04-07 | | |
| 2945 | Brown Cow Cream Top Chocolate | Brown Cow | US | Dairy | L | TODO | 2026-04-07 | | |
| 2946 | Lifeway Kefir Mango | Lifeway | US | Dairy | M | TODO | 2026-04-07 | | |
| 2947 | Horizon Organic American Singles | Horizon | US | Dairy | M | TODO | 2026-04-07 | | |
| 2948 | Lactaid Ice Cream Vanilla | Lactaid | US | Dairy | M | TODO | 2026-04-07 | | |
| 2949 | Tillamook Mudslide Ice Cream | Tillamook | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 2950 | Dannon Light & Fit Greek Toasted Coconut Vanilla | Dannon | US | Dairy | M | TODO | 2026-04-07 | | |

## Section 109: Snack Brands - Chips/Crackers/Pretzels Complete (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2951 | Lay's Baked Original | Lay's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2952 | Doritos Dinamita Chile Limon | Doritos | US | Snacks | M | TODO | 2026-04-07 | | |
| 2953 | Cheetos Mac 'N Cheese Bold & Cheesy | Cheetos | US | Pasta | M | TODO | 2026-04-07 | | |
| 2954 | Fritos Scoops | Fritos | US | Snacks | M | TODO | 2026-04-07 | | |
| 2955 | Tostitos Queso Dip | Tostitos | US | Dips | M | TODO | 2026-04-07 | | |
| 2956 | Stacy's Simply Naked Pita Chips | Stacy's | US | Snacks | H | TODO | 2026-04-07 | | |
| 2957 | Cheez-It Snap'd | Cheez-It | US | Snacks | M | TODO | 2026-04-07 | | |
| 2958 | Ritz Original Crackers | Ritz | US | Snacks | H | TODO | 2026-04-07 | | |
| 2959 | Good Thins Corn | Good Thins | US | Snacks | M | TODO | 2026-04-07 | | |
| 2960 | Snyder's Pretzel Sticks | Snyder's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2961 | Utz Cheese Balls | Utz | US | Snacks | M | TODO | 2026-04-07 | | |
| 2962 | Kettle Brand Salt & Vinegar | Kettle Brand | US | Snacks | M | TODO | 2026-04-07 | | |
| 2963 | Cape Cod Sea Salt & Vinegar | Cape Cod | US | Snacks | M | TODO | 2026-04-07 | | |
| 2964 | Popcorners Sea Salt | Popcorners | US | Snacks | H | TODO | 2026-04-07 | | |
| 2965 | Popcorners White Cheddar | Popcorners | US | Snacks | M | TODO | 2026-04-07 | | |
| 2966 | Popcorners Kettle Corn | Popcorners | US | Snacks | M | TODO | 2026-04-07 | | |
| 2967 | Boom Chicka Pop Sea Salt | Boom Chicka Pop | US | Snacks | H | TODO | 2026-04-07 | | |
| 2968 | Boom Chicka Pop Sweet & Salty | Boom Chicka Pop | US | Snacks | M | TODO | 2026-04-07 | | |
| 2969 | Hippeas Vegan White Cheddar | Hippeas | US | Snacks | M | TODO | 2026-04-07 | | |
| 2970 | Hippeas Barbecue | Hippeas | US | Snacks | M | TODO | 2026-04-07 | | |
| 2971 | Beanitos Black Bean Chips | Beanitos | US | Snacks | M | TODO | 2026-04-07 | | |
| 2972 | Late July Nacho Chipotle | Late July | US | Snacks | M | TODO | 2026-04-07 | | |
| 2973 | Harvest Snaps Green Pea Lightly Salted | Harvest Snaps | US | Snacks | M | TODO | 2026-04-07 | | |
| 2974 | Harvest Snaps Red Lentil | Harvest Snaps | US | Snacks | M | TODO | 2026-04-07 | | |
| 2975 | Terra Original Exotic Vegetable Chips | Terra | US | Snacks | M | TODO | 2026-04-07 | | |
| 2976 | Lay's Limon | Lay's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2977 | Lay's Dill Pickle | Lay's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2978 | Pringles Wavy Classic Salted | Pringles | US | Snacks | M | TODO | 2026-04-07 | | |
| 2979 | Utz Ripple Original | Utz | US | Snacks | M | TODO | 2026-04-07 | | |
| 2980 | Boulder Canyon Hickory BBQ | Boulder Canyon | US | Snacks | L | TODO | 2026-04-07 | | |
| 2981 | Ritz Cheese Crackers Sandwiches | Ritz | US | Snacks | M | TODO | 2026-04-07 | | |
| 2982 | Cheez-It Grooves Sharp Cheddar | Cheez-It | US | Snacks | M | TODO | 2026-04-07 | | |
| 2983 | Club Original Crackers | Keebler | US | Snacks | M | TODO | 2026-04-07 | | |
| 2984 | Snyder's Sourdough Nibblers | Snyder's | US | Snacks | M | TODO | 2026-04-07 | | |
| 2985 | SkinnyPop Sea Salt & Pepper | SkinnyPop | US | Snacks | M | TODO | 2026-04-07 | | |
| 2986 | Late July Jalapeno Lime | Late July | US | Snacks | M | TODO | 2026-04-07 | | |
| 2987 | Chicken in a Biskit | Nabisco | US | Snacks | M | TODO | 2026-04-07 | | |
| 2988 | Triscuit Reduced Fat | Triscuit | US | Snacks | M | TODO | 2026-04-07 | | |

## Section 110: Cookie & Cracker Brands (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 2989 | Oreo Mint | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 2990 | Oreo Birthday Cake | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 2991 | Oreo Mega Stuf | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 2992 | Nutter Butters | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 2993 | Fig Newtons Original | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 2994 | Teddy Grahams Honey | Nabisco | US | Cookies | H | TODO | 2026-04-07 | | |
| 2995 | Teddy Grahams Chocolate | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 2996 | Belvita Blueberry Breakfast Biscuits | Belvita | US | Cookies | H | TODO | 2026-04-07 | | |
| 2997 | Milano Mint | Pepperidge Farm | US | Cookies | M | TODO | 2026-04-07 | | |
| 2998 | Goldfish Pizza | Pepperidge Farm | US | Crackers | M | TODO | 2026-04-07 | | |
| 2999 | Fudge Stripes | Keebler | US | Cookies | H | TODO | 2026-04-07 | | |
| 3000 | E.L. Fudge | Keebler | US | Cookies | M | TODO | 2026-04-07 | | |
| 3001 | Vienna Fingers | Keebler | US | Cookies | M | TODO | 2026-04-07 | | |
| 3002 | Samoas Girl Scout Cookies | Girl Scout | US | Cookies | H | TODO | 2026-04-07 | | |
| 3003 | Tagalongs Girl Scout Cookies | Girl Scout | US | Cookies | H | TODO | 2026-04-07 | | |
| 3004 | Do-si-dos Girl Scout Cookies | Girl Scout | US | Cookies | M | TODO | 2026-04-07 | | |
| 3005 | Trefoils Girl Scout Cookies | Girl Scout | US | Cookies | M | TODO | 2026-04-07 | | |
| 3006 | Oatmeal Creme Pies | Little Debbie | US | Snack Cakes | H | TODO | 2026-04-07 | | |
| 3007 | Honey Buns | Little Debbie | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 3008 | Star Crunch | Little Debbie | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 3009 | CupCakes Chocolate | Hostess | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 3010 | Donettes Powdered | Hostess | US | Snack Cakes | H | TODO | 2026-04-07 | | |
| 3011 | Donettes Chocolate Frosted | Hostess | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 3012 | Suzy Q's | Hostess | US | Snack Cakes | L | TODO | 2026-04-07 | | |
| 3013 | Complete Cookie Double Chocolate | Lenny & Larry's | US | Cookies | H | TODO | 2026-04-07 | | 16g protein |
| 3014 | Complete Cookie Chocolate Chip | Lenny & Larry's | US | Cookies | H | TODO | 2026-04-07 | | |
| 3015 | Complete Cookie Birthday Cake | Lenny & Larry's | US | Cookies | M | TODO | 2026-04-07 | | |
| 3016 | Complete Cookie Peanut Butter | Lenny & Larry's | US | Cookies | M | TODO | 2026-04-07 | | |
| 3017 | Chocolate Chocolate Chip Cookies | Maxine's Heavenly | US | Cookies | M | TODO | 2026-04-07 | | |
| 3018 | Coconut Macaroon Cookies | Emmy's Organics | US | Cookies | M | TODO | 2026-04-07 | | |
| 3019 | Oreo Mini | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 3020 | Chips Ahoy! Reese's | Chips Ahoy! | US | Cookies | M | TODO | 2026-04-07 | | |
| 3021 | Goldfish Mega Bites Sharp Cheddar | Pepperidge Farm | US | Crackers | M | TODO | 2026-04-07 | | |
| 3022 | Milano Salted Caramel | Pepperidge Farm | US | Cookies | M | TODO | 2026-04-07 | | |
| 3023 | Fudge Stripes Minis | Keebler | US | Cookies | M | TODO | 2026-04-07 | | |
| 3024 | Lemonades Girl Scout Cookies | Girl Scout | US | Cookies | M | TODO | 2026-04-07 | | |
| 3025 | Fudge Covered Nutter Butters | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 3026 | Christmas Tree Brownies | Little Debbie | US | Snack Cakes | M | TODO | 2026-04-07 | | Seasonal |
| 3027 | Belvita Chocolate | Belvita | US | Cookies | M | TODO | 2026-04-07 | | |
| 3028 | Teddy Grahams Cinnamon | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 3029 | Double Chocolate Chip | Tate's Bake Shop | US | Cookies | M | TODO | 2026-04-07 | | |
| 3030 | Oreo Peanut Butter | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 3031 | Chips Ahoy! Soft Baked | Chips Ahoy! | US | Cookies | M | TODO | 2026-04-07 | | |
| 3032 | Honey Bun Big Pack | Little Debbie | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 3033 | Hostess Kazbars Chocolate Caramel | Hostess | US | Snack Cakes | M | TODO | 2026-04-07 | | |

## Section 111: Candy & Chocolate Brands Complete (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3034 | M&M's Caramel | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3035 | M&M's Pretzel | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3036 | M&M's Crispy | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3037 | Snickers Original Bar | Mars | US | Candy | H | TODO | 2026-04-07 | | |
| 3038 | Snickers Almond | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3039 | Snickers Ice Cream Bar | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3040 | Twix Original | Mars | US | Candy | H | TODO | 2026-04-07 | | |
| 3041 | 3 Musketeers | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3042 | Reese's Big Cup | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 3043 | Kit Kat Original | Hershey's | US | Candy | H | TODO | 2026-04-07 | | |
| 3044 | Twizzlers Strawberry | Hershey's | US | Candy | H | TODO | 2026-04-07 | | |
| 3045 | 100 Grand | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 3046 | Nutella B-ready | Ferrero | IT | Candy | M | TODO | 2026-04-07 | | |
| 3047 | Tic Tac Freshmint | Ferrero | IT | Candy | M | TODO | 2026-04-07 | | |
| 3048 | Tic Tac Orange | Ferrero | IT | Candy | M | TODO | 2026-04-07 | | |
| 3049 | Haribo Twin Snakes | Haribo | DE | Candy | M | TODO | 2026-04-07 | | |
| 3050 | Starburst Original | Mars | US | Candy | H | TODO | 2026-04-07 | | |
| 3051 | Skittles Sour | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3052 | Life Savers Five Flavors | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3053 | Nerds Original | Ferrara | US | Candy | H | TODO | 2026-04-07 | | |
| 3054 | Nerds Gummy Clusters | Ferrara | US | Candy | H | TODO | 2026-04-07 | | Viral candy |
| 3055 | Ring Pop | Bazooka | US | Candy | M | TODO | 2026-04-07 | | |
| 3056 | Blow Pop | Charms | US | Candy | M | TODO | 2026-04-07 | | |
| 3057 | Airheads Original | Perfetti Van Melle | US | Candy | M | TODO | 2026-04-07 | | |
| 3058 | Airheads Xtremes Bites | Perfetti Van Melle | US | Candy | M | TODO | 2026-04-07 | | |
| 3059 | Now & Later Original | Ferrara | US | Candy | M | TODO | 2026-04-07 | | |
| 3060 | Dots | Tootsie Roll | US | Candy | M | TODO | 2026-04-07 | | |
| 3061 | Junior Mints | Tootsie Roll | US | Candy | M | TODO | 2026-04-07 | | |
| 3062 | Milk Duds | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 3063 | Raisinets | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 3064 | Goobers Chocolate Peanuts | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 3065 | Sno-Caps | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 3066 | Hot Tamales | Just Born | US | Candy | H | TODO | 2026-04-07 | | |
| 3067 | Jelly Belly Assorted | Jelly Belly | US | Candy | H | TODO | 2026-04-07 | | |
| 3068 | Peeps Original Yellow | Just Born | US | Candy | M | TODO | 2026-04-07 | | Seasonal |
| 3069 | Candy Corn Classic | Brach's | US | Candy | M | TODO | 2026-04-07 | | Seasonal |
| 3070 | Lindt Excellence 85% Dark | Lindt | CH | Candy | M | TODO | 2026-04-07 | | |
| 3071 | Twix Peanut Butter | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3072 | Kit Kat Big Kat | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 3073 | Reese's Fast Break | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 3074 | Trolli Sour Brite Eggs | Trolli | US | Candy | M | TODO | 2026-04-07 | | |
| 3075 | Haribo Happy Cola | Haribo | DE | Candy | M | TODO | 2026-04-07 | | |
| 3076 | Sour Punch Straws | American Licorice | US | Candy | M | TODO | 2026-04-07 | | |
| 3077 | Twizzlers Pull 'N' Peel | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 3078 | Starburst FaveREDs | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3079 | Skittles Tropical | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 3080 | Tootsie Pop | Tootsie Roll | US | Candy | M | TODO | 2026-04-07 | | |
| 3081 | Nerds Rope | Ferrara | US | Candy | M | TODO | 2026-04-07 | | |
| 3082 | SweeTarts Original | Ferrara | US | Candy | M | TODO | 2026-04-07 | | |
| 3083 | SweeTarts Ropes | Ferrara | US | Candy | M | TODO | 2026-04-07 | | |
| 3084 | Butterfinger Peanut Butter Cups | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 3085 | Brach's Jelly Beans Classic | Brach's | US | Candy | M | TODO | 2026-04-07 | | |

## Section 112: Ice Cream Brands Complete (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3086 | Tonight Dough | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3087 | Cookie Dough | Ben & Jerry's | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 3088 | Netflix & Chilll'd | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3089 | Belgian Chocolate | Haagen-Dazs | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3090 | Rum Raisin | Haagen-Dazs | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3091 | Vanilla Bean Gelato | Talenti | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 3092 | Chocolate Fudge Brownie Gelato | Talenti | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3093 | Peanut Butter Fudge Sorbetto | Talenti | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3094 | Cookies and Cream | Blue Bell | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 3095 | Chocolate Peanut Butter Cup | Turkey Hill | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3096 | Forbidden Chocolate | Friendly's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3097 | Cookie Dough | Edy's/Dreyer's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3098 | Bunny Tracks | Blue Bunny | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 3099 | Super Chunky Cookie Dough | Blue Bunny | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3100 | Salty Caramel | Jeni's Splendid | US | Ice Cream | H | TODO | 2026-04-07 | | Premium artisan |
| 3101 | Brambleberry Crisp | Jeni's Splendid | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3102 | Gooey Butter Cake | Jeni's Splendid | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3103 | Brown Butter Almond Brittle | Jeni's Splendid | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3104 | Sea Salt with Caramel Ribbons | Salt & Straw | US | Ice Cream | H | TODO | 2026-04-07 | | Portland-based |
| 3105 | Honey Lavender | Salt & Straw | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3106 | Planet Earth Vanilla | Van Leeuwen | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3107 | Turkish Coffee | McConnell's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3108 | Eureka Lemon & Marionberries | McConnell's | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 3109 | Black Raspberry Chocolate Chip | Graeter's | US | Ice Cream | H | TODO | 2026-04-07 | | French pot process |
| 3110 | Toffee Chocolate Chip | Graeter's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3111 | Coconut Milk Vanilla | So Delicious | US | Ice Cream | M | TODO | 2026-04-07 | | Dairy-free |
| 3112 | Coconut Milk Mocha Almond Fudge | So Delicious | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3113 | Oat Milk Strawberry | Oatly | SE | Ice Cream | M | TODO | 2026-04-07 | | |
| 3114 | Chocolate Hazelnut Fudge | Coconut Bliss | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 3115 | Klondike Bar Original | Klondike | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 3116 | Klondike Bar Reese's | Klondike | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3117 | Drumstick Classic Vanilla | Drumstick | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 3118 | Drumstick Caramel | Drumstick | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3119 | Dove Vanilla Bar | Dove | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3120 | Good Humor Strawberry Shortcake Bar | Good Humor | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 3121 | Good Humor Chocolate Eclair Bar | Good Humor | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3122 | Good Humor Giant King Cone | Good Humor | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3123 | Fudgsicle Original | Popsicle | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 3124 | Fudgsicle No Sugar Added | Popsicle | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3125 | Creamsicle Original | Popsicle | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 3126 | Ben & Jerry's Mint Chocolate Cookie | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3127 | Ben & Jerry's Caramel Cookie Fix | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3128 | Talenti Caramel Cookie Crunch | Talenti | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3129 | Turkey Hill Mint Choc Chip Premium | Turkey Hill | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3130 | Edy's Slow Churned Caramel Delight | Edy's/Dreyer's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3131 | Jeni's Everything Bagel | Jeni's Splendid | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 3132 | Van Leeuwen Chocolate Fudge Brownie | Van Leeuwen | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3133 | Popsicle Original Variety Pack | Popsicle | US | Ice Cream | H | TODO | 2026-04-07 | | |

## Section 113: Beverage Brands - Juice/Water/Tea (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3134 | Simply Orange Pulp Free | Simply | US | Beverages | H | TODO | 2026-04-07 | | |
| 3135 | Naked Mighty Mango Smoothie | Naked Juice | US | Beverages | H | TODO | 2026-04-07 | | |
| 3136 | Naked Green Machine Smoothie | Naked Juice | US | Beverages | H | TODO | 2026-04-07 | | |
| 3137 | Naked Blue Machine Smoothie | Naked Juice | US | Beverages | M | TODO | 2026-04-07 | | |
| 3138 | Naked Strawberry Banana Smoothie | Naked Juice | US | Beverages | M | TODO | 2026-04-07 | | |
| 3139 | Bolthouse Farms Green Goodness | Bolthouse Farms | US | Beverages | M | TODO | 2026-04-07 | | |
| 3140 | Bolthouse Farms Protein Plus Chocolate | Bolthouse Farms | US | Beverages | M | TODO | 2026-04-07 | | |
| 3141 | Bolthouse Farms Berry Boost | Bolthouse Farms | US | Beverages | M | TODO | 2026-04-07 | | |
| 3142 | Ocean Spray Cran-Grape | Ocean Spray | US | Beverages | M | TODO | 2026-04-07 | | |
| 3143 | V8 Original Vegetable Juice | V8 | US | Beverages | H | TODO | 2026-04-07 | | |
| 3144 | V8 Low Sodium | V8 | US | Beverages | M | TODO | 2026-04-07 | | |
| 3145 | V8 +Energy Peach Mango | V8 | US | Beverages | M | TODO | 2026-04-07 | | |
| 3146 | Capri Sun Pacific Cooler | Capri Sun | US | Beverages | M | TODO | 2026-04-07 | | |
| 3147 | Kool-Aid Jammers Cherry | Kool-Aid | US | Beverages | M | TODO | 2026-04-07 | | |
| 3148 | SunnyD Original | SunnyD | US | Beverages | M | TODO | 2026-04-07 | | |
| 3149 | AriZona Mucho Mango | AriZona | US | Beverages | M | TODO | 2026-04-07 | | |
| 3150 | Gold Peak Unsweetened Tea | Gold Peak | US | Beverages | M | TODO | 2026-04-07 | | |
| 3151 | Snapple Apple | Snapple | US | Beverages | M | TODO | 2026-04-07 | | |
| 3152 | Vitaminwater XXX Acai Blueberry Pomegranate | Vitaminwater | US | Beverages | H | TODO | 2026-04-07 | | |
| 3153 | Vitaminwater Power-C Dragonfruit | Vitaminwater | US | Beverages | M | TODO | 2026-04-07 | | |
| 3154 | Vitaminwater Zero Sugar Squeezed | Vitaminwater | US | Beverages | M | TODO | 2026-04-07 | | |
| 3155 | Smartwater Original | Smartwater | US | Beverages | H | TODO | 2026-04-07 | | |
| 3156 | Smartwater Alkaline | Smartwater | US | Beverages | M | TODO | 2026-04-07 | | |
| 3157 | Dasani Purified Water | Dasani | US | Beverages | H | TODO | 2026-04-07 | | |
| 3158 | Aquafina Purified Water | Aquafina | US | Beverages | H | TODO | 2026-04-07 | | |
| 3159 | Fiji Natural Artesian Water | Fiji | FJ | Beverages | H | TODO | 2026-04-07 | | |
| 3160 | Evian Natural Spring Water | Evian | FR | Beverages | H | TODO | 2026-04-07 | | |
| 3161 | Spindrift Grapefruit | Spindrift | US | Beverages | M | TODO | 2026-04-07 | | |
| 3162 | Bai Brasilia Blueberry | Bai | US | Beverages | M | TODO | 2026-04-07 | | |
| 3163 | Bai Costa Rica Clementine | Bai | US | Beverages | M | TODO | 2026-04-07 | | |
| 3164 | Bai Kula Watermelon | Bai | US | Beverages | M | TODO | 2026-04-07 | | |
| 3165 | Simply Limeade | Simply | US | Beverages | M | TODO | 2026-04-07 | | |
| 3166 | Tropicana Strawberry Peach | Tropicana | US | Beverages | M | TODO | 2026-04-07 | | |
| 3167 | Snapple Mango Madness | Snapple | US | Beverages | M | TODO | 2026-04-07 | | |
| 3168 | AriZona Watermelon | AriZona | US | Beverages | M | TODO | 2026-04-07 | | |
| 3169 | Honest Tea Half Tea Half Lemonade | Honest Tea | US | Beverages | M | TODO | 2026-04-07 | | |
| 3170 | Spindrift Pineapple | Spindrift | US | Beverages | M | TODO | 2026-04-07 | | |
| 3171 | Bai Molokai Coconut | Bai | US | Beverages | M | TODO | 2026-04-07 | | |
| 3172 | Bolthouse Farms Carrot Ginger Turmeric | Bolthouse Farms | US | Beverages | M | TODO | 2026-04-07 | | |
| 3173 | V8 +Energy Strawberry Banana | V8 | US | Beverages | M | TODO | 2026-04-07 | | |
| 3174 | Pure Leaf Lemon Tea | Pure Leaf | US | Beverages | M | TODO | 2026-04-07 | | |

## Section 114: Bread & Bakery Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3175 | Delightful Wheat 45cal Bread | Sara Lee | US | Bread | M | TODO | 2026-04-07 | | |
| 3176 | Life 40 Calorie Wheat Bread | Nature's Own | US | Bread | M | TODO | 2026-04-07 | | |
| 3177 | Long Potato Rolls Hot Dog | Martin's | US | Bread | H | TODO | 2026-04-07 | | |
| 3178 | Sweet Hawaiian Rolls | King's Hawaiian | US | Bread | H | TODO | 2026-04-07 | | |
| 3179 | Sweet Hawaiian Slider Buns | King's Hawaiian | US | Bread | H | TODO | 2026-04-07 | | |
| 3180 | English Muffins Original | Bays | US | Bread | M | TODO | 2026-04-07 | | |
| 3181 | Crescent Rolls Original | Pillsbury | US | Bread | H | TODO | 2026-04-07 | | |
| 3182 | Grands Biscuits Southern Homestyle | Pillsbury | US | Bread | H | TODO | 2026-04-07 | | |
| 3183 | Cinnamon Rolls with Icing | Pillsbury | US | Bread | H | TODO | 2026-04-07 | | |
| 3184 | Pie Crust Refrigerated | Pillsbury | US | Baking | M | TODO | 2026-04-07 | | |
| 3185 | Pizza Dough Classic | Pillsbury | US | Baking | M | TODO | 2026-04-07 | | |
| 3186 | Blueberry Muffins Otis Spunkmeyer | Otis Spunkmeyer | US | Bakery | M | TODO | 2026-04-07 | | |
| 3187 | Chocolate Chip Muffins | Otis Spunkmeyer | US | Bakery | M | TODO | 2026-04-07 | | |
| 3188 | Rich Frosted Donuts | Entenmann's | US | Bakery | H | TODO | 2026-04-07 | | |
| 3189 | Crumb Coffee Cake | Entenmann's | US | Bakery | H | TODO | 2026-04-07 | | |
| 3190 | Chocolate Chip Cookies Soft Baked | Entenmann's | US | Bakery | M | TODO | 2026-04-07 | | |
| 3191 | Glazed Pop'ems Donut Holes | Entenmann's | US | Bakery | M | TODO | 2026-04-07 | | |
| 3192 | Entenmann's Little Bites Blueberry Muffins | Entenmann's | US | Bakery | H | TODO | 2026-04-07 | | |
| 3193 | Yodels | Drake's | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 3194 | Flour Tortillas Soft Taco | Mission | US | Bread | H | TODO | 2026-04-07 | | |
| 3195 | Flour Tortillas Burrito Size | Mission | US | Bread | M | TODO | 2026-04-07 | | |
| 3196 | Taco Dinner Kit | Old El Paso | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 3197 | Light Original Flatbread | Flatout | US | Bread | M | TODO | 2026-04-07 | | |
| 3198 | Gluten Free Hamburger Buns | Udi's | US | Bread | M | TODO | 2026-04-07 | | |
| 3199 | Gluten Free Heritage Style Bread | Canyon Bakehouse | US | Bread | M | TODO | 2026-04-07 | | |
| 3200 | 21 Whole Grains & Seeds Bread | Dave's Killer Bread | US | Bread | H | TODO | 2026-04-07 | | |
| 3201 | Good Seed Bread | Dave's Killer Bread | US | Bread | H | TODO | 2026-04-07 | | |
| 3202 | Powerseed Bread | Dave's Killer Bread | US | Bread | M | TODO | 2026-04-07 | | |
| 3203 | Thin-Sliced 21 Whole Grains | Dave's Killer Bread | US | Bread | M | TODO | 2026-04-07 | | |
| 3204 | Everything Bagels | Dave's Killer Bread | US | Bread | M | TODO | 2026-04-07 | | |
| 3205 | Blueberry English Muffins | Thomas' | US | Bread | M | TODO | 2026-04-07 | | |
| 3206 | Whole Wheat English Muffins | Thomas' | US | Bread | M | TODO | 2026-04-07 | | |
| 3207 | Flaky Layers Biscuits Buttermilk | Pillsbury | US | Bread | M | TODO | 2026-04-07 | | |
| 3208 | Sweet Hawaiian Honey Wheat Bread | King's Hawaiian | US | Bread | M | TODO | 2026-04-07 | | |
| 3209 | White Hamburger Buns | Sara Lee | US | Bread | M | TODO | 2026-04-07 | | |

## Section 115: Canned & Jarred Food Brands (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3210 | Condensed Cream of Chicken Soup | Campbell's | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3211 | Chunky Classic Chicken Noodle | Campbell's | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 3212 | Chunky Beef with Country Vegetables | Campbell's | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3213 | Italian Style Wedding Soup | Progresso | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3214 | Beef Ravioli | Chef Boyardee | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 3215 | Beefaroni | Chef Boyardee | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 3216 | Mini Ravioli | Chef Boyardee | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3217 | SpaghettiOs Original | SpaghettiOs | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 3218 | SpaghettiOs with Meatballs | SpaghettiOs | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3219 | Chili with Beans | Hormel | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 3220 | Chili No Beans | Hormel | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3221 | Yellow Rice Mix | Goya | US | Grains | M | TODO | 2026-04-07 | | |
| 3222 | Diced Tomatoes & Green Chilies | Rotel | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 3223 | Organic Diced Tomatoes | Muir Glen | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3224 | Organic Tomato Sauce | Muir Glen | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3225 | Diced Tomatoes | Hunt's | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 3226 | Tomato & Basil Pasta Sauce | Classico | US | Condiments | H | TODO | 2026-04-07 | | |
| 3227 | Roasted Garlic Pasta Sauce | Classico | US | Condiments | M | TODO | 2026-04-07 | | |
| 3228 | Traditional Italian Sauce | Prego | US | Condiments | H | TODO | 2026-04-07 | | |
| 3229 | Meat Flavored Sauce | Prego | US | Condiments | M | TODO | 2026-04-07 | | |
| 3230 | Old World Style Traditional | Ragu | US | Condiments | H | TODO | 2026-04-07 | | |
| 3231 | Chunky Mushroom & Green Pepper | Ragu | US | Condiments | M | TODO | 2026-04-07 | | |
| 3232 | Sockarooni Pasta Sauce | Newman's Own | US | Condiments | M | TODO | 2026-04-07 | | |
| 3233 | Medium Salsa | Newman's Own | US | Condiments | M | TODO | 2026-04-07 | | |
| 3234 | Arrabbiata Sauce | Rao's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3235 | Vodka Sauce | Rao's | US | Condiments | H | TODO | 2026-04-07 | | |
| 3236 | Basilico Sauce | Barilla | IT | Condiments | M | TODO | 2026-04-07 | | |
| 3237 | Tortellini Cheese | Buitoni | IT | Pasta | M | TODO | 2026-04-07 | | |
| 3238 | Ravioli Four Cheese | Buitoni | IT | Pasta | M | TODO | 2026-04-07 | | |
| 3239 | Chunk Light Tuna in Water | StarKist | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 3240 | Albacore White Tuna in Water | StarKist | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 3241 | Tuna Creations Lemon Pepper | StarKist | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3242 | Pink Salmon | Bumble Bee | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3243 | Chunk Light Tuna | Chicken of the Sea | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3244 | Fruit Cocktail in Juice | Del Monte | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3245 | Sliced Peaches in Juice | Del Monte | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3246 | Pineapple Chunks in Juice | Dole | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3247 | Mandarin Oranges | Dole | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3248 | Sweet Peas | Green Giant | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3249 | Whole Kernel Corn | Green Giant | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3250 | Pork & Beans | Van Camp's | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3251 | Condensed Vegetable Soup | Campbell's | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3252 | Chunky Sirloin Burger | Campbell's | US | Canned Goods | M | TODO | 2026-04-07 | | |

## Section 116: Condiment & Sauce Brands (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3253 | Real Mayonnaise | Heinz | US | Condiments | H | TODO | 2026-04-07 | | |
| 3254 | 57 Sauce | Heinz | US | Condiments | M | TODO | 2026-04-07 | | |
| 3255 | Heinz No Sugar Added Ketchup | Heinz | US | Condiments | M | TODO | 2026-04-07 | | |
| 3256 | Crispy Fried Onions | French's | US | Condiments | H | TODO | 2026-04-07 | | |
| 3257 | Vegan Mayo | Hellmann's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3258 | Classic Ketchup | Sir Kensington's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3259 | Unsweetened Ketchup | Primal Kitchen | US | Condiments | M | TODO | 2026-04-07 | | |
| 3260 | Balsamic Dressing | Tessemae's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3261 | Organic Ketchup | Annie's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3262 | Organic Goddess Dressing | Annie's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3263 | Avocado Ranch | Hidden Valley | US | Condiments | M | TODO | 2026-04-07 | | |
| 3264 | Sweet Heat BBQ | Sweet Baby Ray's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3265 | A1 Original Steak Sauce | A1 | US | Condiments | H | TODO | 2026-04-07 | | |
| 3266 | Salsa Picante | Tapatio | MX | Condiments | H | TODO | 2026-04-07 | | |
| 3267 | Sichuan Chili Crisp | Fly By Jing | US | Condiments | M | TODO | 2026-04-07 | | Trending |
| 3268 | Hot Honey | Mike's Hot Honey | US | Condiments | H | TODO | 2026-04-07 | | Viral condiment |
| 3269 | Polynesian Sauce Bottled | Chick-fil-A | US | Condiments | M | TODO | 2026-04-07 | | |
| 3270 | Zax Sauce Bottled | Zaxby's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3271 | Cane's Sauce Bottled | Raising Cane's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3272 | Spicy Brown Mustard | Gulden's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3273 | Teriyaki Marinade & Sauce | Kikkoman | JP | Condiments | M | TODO | 2026-04-07 | | |
| 3274 | Steak Sauce | Primal Kitchen | US | Condiments | M | TODO | 2026-04-07 | | |

## Section 117: Protein Bar Brands Expansion (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3275 | ONE Bar Lemon Cake | ONE | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3276 | GoMacro Banana Oatmeal Chocolate Chip | GoMacro | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3277 | No Cow Chocolate Fudge Brownie | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | Dairy-free |
| 3278 | No Cow Peanut Butter Chocolate Chip | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3279 | No Cow Lemon Meringue Pie | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3280 | No Cow Cookies & Cream | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3281 | Power Crunch Original Peanut Butter Creme | Power Crunch | US | Protein Bars | H | TODO | 2026-04-07 | | Wafer bar |
| 3282 | Power Crunch Chocolate Mint | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3283 | Power Crunch Triple Chocolate | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3284 | Power Crunch French Vanilla Creme | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3285 | Power Crunch Peanut Butter Fudge | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3286 | Aloha Peanut Butter Chocolate Chip | Aloha | US | Protein Bars | M | TODO | 2026-04-07 | | Plant-based |
| 3287 | Aloha Coconut Chocolate Almond | Aloha | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3288 | Aloha Vanilla Almond Crunch | Aloha | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 3289 | NuGo Slim Chocolate Brownie | NuGo | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3290 | NuGo Slim Crunchy Peanut Butter | NuGo | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3291 | Luna Bar Lemon Zest | Luna | US | Protein Bars | M | TODO | 2026-04-07 | | Women-focused |
| 3292 | Builder's Chocolate | Clif | US | Protein Bars | H | TODO | 2026-04-07 | | 20g protein |
| 3293 | Builder's Crunchy Peanut Butter | Clif | US | Protein Bars | H | TODO | 2026-04-07 | | |
| 3294 | Builder's Chocolate Peanut Butter | Clif | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3295 | Builder's Vanilla Almond | Clif | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3296 | ProBar Base Cookie Dough | ProBar | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 3297 | MET-Rx Big 100 Super Cookie Crunch | MET-Rx | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3298 | BSN Protein Crisp Chocolate Crunch | BSN | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3299 | BSN Protein Crisp Peanut Butter Crunch | BSN | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3300 | Health Warrior Chia Bar Chocolate Peanut Butter | Health Warrior | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3301 | ZonePerfect Chocolate Peanut Butter | ZonePerfect | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3302 | ZonePerfect Fudge Graham | ZonePerfect | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3303 | Nature's Bakery Fig Bar Blueberry | Nature's Bakery | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3304 | Nature's Bakery Fig Bar Raspberry | Nature's Bakery | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3305 | Nature's Bakery Fig Bar Original | Nature's Bakery | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3306 | Bobo's Original Oat Bar | Bobo's | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3307 | Bobo's Chocolate Chip Oat Bar | Bobo's | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3308 | Bobo's Lemon Poppyseed Oat Bar | Bobo's | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 3309 | That's It Apple + Mango Bar | That's It | US | Snack Bars | M | TODO | 2026-04-07 | | 2 ingredients |
| 3310 | That's It Apple + Blueberry Bar | That's It | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3311 | LARABAR Banana Bread | LARABAR | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3312 | KIND Maple Glazed Pecan & Sea Salt | KIND | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3313 | KIND Oats & Honey with Toasted Coconut | KIND | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3314 | Munk Pack Coconut White Chip Macadamia | Munk Pack | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3315 | Verb Salted Peanut Butter Bar | Verb | US | Snack Bars | L | TODO | 2026-04-07 | | Caffeinated |
| 3316 | Oatmega Chocolate Brownie | Oatmega | US | Protein Bars | L | TODO | 2026-04-07 | | Omega-3 |
| 3317 | SimplyProtein Peanut Butter Chocolate | SimplyProtein | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3318 | SimplyProtein Lemon | SimplyProtein | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 3319 | Rise Bar Almond Honey | Rise Bar | US | Protein Bars | L | TODO | 2026-04-07 | | 3 ingredients |
| 3320 | Rise Bar Chocolate Coconut | Rise Bar | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 3321 | Garden of Life Sport Chocolate | Garden of Life | US | Protein Bars | M | TODO | 2026-04-07 | | Organic |
| 3322 | Garden of Life Fit High Protein Peanut Butter Chocolate | Garden of Life | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3323 | ONE Bar Cookies & Cream | ONE | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3324 | Power Crunch S'mores | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3325 | No Cow Birthday Cake | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3326 | Aloha Peanut Butter Cup | Aloha | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3327 | KIND Cranberry Almond | KIND | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3328 | Bobo's Peanut Butter Oat Bar | Bobo's | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3329 | Nature's Bakery Fig Bar Peach Apricot | Nature's Bakery | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3330 | Luna Bar Nutz Over Chocolate | Luna | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3331 | Builder's Mint Chocolate | Clif | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3332 | MET-Rx Big 100 Vanilla Caramel Churro | MET-Rx | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3333 | ZonePerfect Strawberry Yogurt | ZonePerfect | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 3334 | That's It Apple + Strawberry Bar | That's It | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 3335 | Health Warrior Chia Bar Coconut | Health Warrior | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 3336 | SimplyProtein Chocolate Chip | SimplyProtein | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 3337 | NuGo Slim Raspberry Truffle | NuGo | US | Protein Bars | L | TODO | 2026-04-07 | | |

## Section 118: Plant-Based & Vegan Products (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3338 | Beyond Sausage Italian | Beyond Meat | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3339 | Beyond Beef Ground | Beyond Meat | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3340 | Beyond Meatballs | Beyond Meat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3341 | Beyond Sausage Brat Original | Beyond Meat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3342 | Impossible Sausage Links Savory | Impossible Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3343 | Impossible Meatballs | Impossible Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3344 | Seven Grain Crispy Tenders | Gardein | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3345 | Ultimate Beefless Burger | Gardein | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3346 | Fishless Filets | Gardein | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3347 | Black Bean Burger | MorningStar Farms | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3348 | Chik Patties Original | MorningStar Farms | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3349 | Veggie Corn Dogs | MorningStar Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3350 | Incogmeato Burger | MorningStar Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3351 | Original Veggie Burger | Boca | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3352 | All American Flame Grilled Burger | Boca | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3353 | Deli Slices Hickory Smoked | Tofurky | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3354 | Plant-Based Roast | Tofurky | US | Plant-Based | M | TODO | 2026-04-07 | | Holiday item |
| 3355 | Classic Smoked Frankfurters | Field Roast | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3356 | Chao Creamy Original Slices | Field Roast | US | Plant-Based | M | TODO | 2026-04-07 | | Plant-based cheese |
| 3357 | Smart Dogs | Lightlife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3358 | Tempeh Original | Lightlife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3359 | Plant-Based Burger | Lightlife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3360 | JUST Egg Folded | JUST Egg | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3361 | JUST Egg Pourable | JUST Egg | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3362 | Classic Cheddar Wheel | Miyoko's | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3363 | European Style Cultured Vegan Butter | Miyoko's | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3364 | Liquid Mozzarella | Miyoko's | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3365 | Epic Mature Cheddar Slices | Violife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3366 | Just Like Parmesan Wedge | Violife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3367 | American Slices | Follow Your Heart | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3368 | Vegenaise Original | Follow Your Heart | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3369 | Cutting Board Mozzarella Shreds | Daiya | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3370 | Cheddar Style Shreds | Daiya | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3371 | Daiya Cheezecake Strawberry | Daiya | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 3372 | Dairy-Free Frozen Dessert Vanilla | So Delicious | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3373 | Oat Milk Creamer Vanilla | So Delicious | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3374 | Silk Oat Yeah Oat Milk Original | Silk | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3375 | Silk Soy Milk Original | Silk | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3376 | Silk Protein Oat Milk | Silk | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3377 | Ripple Unsweetened Pea Milk | Ripple | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3378 | Califia Farms Oat Milk Unsweetened | Califia Farms | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 3379 | Califia Farms Oat Barista Blend | Califia Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3380 | Planet Oat Oat Milk Original | Planet Oat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3381 | Planet Oat Oat Milk Extra Creamy | Planet Oat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3382 | Chobani Oat Milk Plain | Chobani | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3383 | Chobani Oat Milk Extra Creamy | Chobani | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3384 | Good Karma Flaxmilk Unsweetened | Good Karma | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 3385 | Kite Hill Ricotta Alternative | Kite Hill | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3386 | Forager Project Cashew Milk Plain | Forager | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 3387 | Forager Project Half & Half Alternative | Forager | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 3388 | Harmless Harvest Dairy-Free Yogurt Vanilla | Harmless Harvest | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 3389 | Beyond Steak Tips | Beyond Meat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3390 | Impossible Beef Lite Ground | Impossible Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3391 | Gardein Plant-Based Chick'n Scallopini | Gardein | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3392 | MorningStar Farms Grillers Original | MorningStar Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3393 | Tofurky Tempeh Smoky Maple Bacon | Tofurky | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3394 | Lightlife Gimme Lean Sausage | Lightlife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3395 | Silk Nextmilk Whole Fat | Silk | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 3396 | Califia Farms Oat Creamer Vanilla | Califia Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |

## Section 119: Sports & Hydration Products (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3397 | Thirst Quencher Orange | Gatorade | US | Sports Drinks | H | TODO | 2026-04-07 | | |
| 3398 | Gatorade Zero Glacier Cherry | Gatorade | US | Sports Drinks | H | TODO | 2026-04-07 | | |
| 3399 | Gatorade Zero Berry | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 3400 | Gatorade Fit Tropical Mango | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | No sugar added |
| 3401 | Gatorade Fit Cherry Lime | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 3402 | Fast Twitch Tropical Mango | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | Caffeinated |
| 3403 | Fast Twitch Cool Blue | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 3404 | Gx Pod Fruit Punch | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | For Gx bottle |
| 3405 | Powerade Zero Mixed Berry | Powerade | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 3406 | BodyArmor Flash IV Berry | BodyArmor | US | Sports Drinks | M | TODO | 2026-04-07 | | Rapid rehydration |
| 3407 | Liquid IV Acai Berry | Liquid IV | US | Hydration | M | TODO | 2026-04-07 | | |
| 3408 | Liquid IV Concord Grape | Liquid IV | US | Hydration | M | TODO | 2026-04-07 | | |
| 3409 | LMNT Raw Unflavored | LMNT | US | Hydration | M | TODO | 2026-04-07 | | |
| 3410 | Nuun Sport Lemon Lime | Nuun | US | Hydration | H | TODO | 2026-04-07 | | Effervescent tablets |
| 3411 | Nuun Sport Citrus Fruit | Nuun | US | Hydration | M | TODO | 2026-04-07 | | |
| 3412 | Nuun Sport Tropical Punch | Nuun | US | Hydration | M | TODO | 2026-04-07 | | |
| 3413 | Nuun Rest Lemon Chamomile | Nuun | US | Hydration | L | TODO | 2026-04-07 | | |
| 3414 | DripDrop ORS Watermelon | DripDrop | US | Hydration | M | TODO | 2026-04-07 | | Medical grade |
| 3415 | DripDrop ORS Lemon | DripDrop | US | Hydration | M | TODO | 2026-04-07 | | |
| 3416 | Pedialyte Grape | Pedialyte | US | Hydration | H | TODO | 2026-04-07 | | |
| 3417 | Pedialyte Strawberry | Pedialyte | US | Hydration | M | TODO | 2026-04-07 | | |
| 3418 | Pedialyte AdvancedCare Plus Berry Frost | Pedialyte | US | Hydration | M | TODO | 2026-04-07 | | |
| 3419 | Pedialyte Freezer Pops | Pedialyte | US | Hydration | M | TODO | 2026-04-07 | | |
| 3420 | Skratch Labs Sport Hydration Lemon Lime | Skratch Labs | US | Hydration | M | TODO | 2026-04-07 | | Endurance focused |
| 3421 | Skratch Labs Sport Hydration Raspberry Limeade | Skratch Labs | US | Hydration | M | TODO | 2026-04-07 | | |
| 3422 | Skratch Labs Everyday Drink Mix Lemonade | Skratch Labs | US | Hydration | L | TODO | 2026-04-07 | | |
| 3423 | Tailwind Endurance Fuel Berry | Tailwind | US | Hydration | L | TODO | 2026-04-07 | | |
| 3424 | Maurten Drink Mix 320 | Maurten | SE | Hydration | M | TODO | 2026-04-07 | | Pro athlete |
| 3425 | Maurten Gel 100 | Maurten | SE | Gels | M | TODO | 2026-04-07 | | |
| 3426 | Maurten Gel 100 Caf 100 | Maurten | SE | Gels | M | TODO | 2026-04-07 | | Caffeinated |
| 3427 | GU Energy Gel Salted Caramel | GU Energy | US | Gels | H | TODO | 2026-04-07 | | |
| 3428 | GU Energy Gel Chocolate Outrage | GU Energy | US | Gels | M | TODO | 2026-04-07 | | |
| 3429 | GU Energy Gel Tri-Berry | GU Energy | US | Gels | M | TODO | 2026-04-07 | | |
| 3430 | GU Energy Gel Espresso Love | GU Energy | US | Gels | M | TODO | 2026-04-07 | | Caffeinated |
| 3431 | GU Roctane Ultra Endurance Gel Sea Salt Chocolate | GU Energy | US | Gels | M | TODO | 2026-04-07 | | |
| 3432 | Clif Shot Energy Gel Mocha | Clif | US | Gels | M | TODO | 2026-04-07 | | |
| 3433 | Clif Shot Energy Gel Citrus | Clif | US | Gels | M | TODO | 2026-04-07 | | |
| 3434 | Honey Stinger Organic Energy Waffle Honey | Honey Stinger | US | Sports Snacks | H | TODO | 2026-04-07 | | |
| 3435 | Honey Stinger Organic Energy Waffle Chocolate | Honey Stinger | US | Sports Snacks | M | TODO | 2026-04-07 | | |
| 3436 | Honey Stinger Energy Gel Gold | Honey Stinger | US | Gels | M | TODO | 2026-04-07 | | |
| 3437 | Honey Stinger Organic Energy Chews Cherry Blossom | Honey Stinger | US | Sports Snacks | M | TODO | 2026-04-07 | | |
| 3438 | Spring Energy Awesome Sauce Gel | Spring Energy | US | Gels | M | TODO | 2026-04-07 | | Real food gel |
| 3439 | Spring Energy Canaberry Gel | Spring Energy | US | Gels | L | TODO | 2026-04-07 | | |
| 3440 | SiS GO Isotonic Energy Gel Orange | SiS | GB | Gels | M | TODO | 2026-04-07 | | |
| 3441 | SiS GO Electrolyte Lemon & Lime | SiS | GB | Hydration | M | TODO | 2026-04-07 | | |
| 3442 | BioSteel Sports Hydration Mix Blue Raspberry | BioSteel | CA | Hydration | M | TODO | 2026-04-07 | | |
| 3443 | BioSteel Sports Hydration Mix Rainbow Twist | BioSteel | CA | Hydration | M | TODO | 2026-04-07 | | |
| 3444 | Electrolit Electrolyte Beverage Berry | Electrolit | MX | Hydration | H | TODO | 2026-04-07 | | Trending |
| 3445 | Electrolit Electrolyte Beverage Fruit Punch | Electrolit | MX | Hydration | M | TODO | 2026-04-07 | | |
| 3446 | Electrolit Electrolyte Beverage Coconut | Electrolit | MX | Hydration | M | TODO | 2026-04-07 | | |
| 3447 | Essentia Ionized Water | Essentia | US | Beverages | H | TODO | 2026-04-07 | | pH 9.5+ water |
| 3448 | Core Hydration Water | Core | US | Beverages | M | TODO | 2026-04-07 | | |
| 3449 | Propel Powder Packets Grape | Propel | US | Hydration | M | TODO | 2026-04-07 | | |
| 3450 | Gatorade Thirst Quencher Glacier Freeze | Gatorade | US | Sports Drinks | H | TODO | 2026-04-07 | | |
| 3451 | BodyArmor Lyte Blueberry Pomegranate | BodyArmor | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 3452 | Liquid IV Watermelon | Liquid IV | US | Hydration | M | TODO | 2026-04-07 | | |
| 3453 | Nuun Immunity Orange Citrus | Nuun | US | Hydration | M | TODO | 2026-04-07 | | |
| 3454 | GU Energy Gel Vanilla Bean | GU Energy | US | Gels | M | TODO | 2026-04-07 | | |
| 3455 | Honey Stinger Waffle Caramel | Honey Stinger | US | Sports Snacks | M | TODO | 2026-04-07 | | |

---

**END OF FILE**
**Total items: 5151 through 6870 = 1720 items**
**Remaining: 780 items needed (6871–7650) — see continuation sections below**

---

## Section 120: International Grocery Brands (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3456 | Chapagetti Black Bean Noodles | Nongshim | KR | Noodles | M | TODO | 2026-04-07 | | |
| 3457 | Neoguri Spicy Seafood | Nongshim | KR | Noodles | M | TODO | 2026-04-07 | | |
| 3458 | Samyang Buldak Hot Chicken 2X Spicy | Samyang | KR | Noodles | H | TODO | 2026-04-07 | | Viral ramen |
| 3459 | Samyang Buldak Hot Chicken Original | Samyang | KR | Noodles | H | TODO | 2026-04-07 | | |
| 3460 | Samyang Buldak Carbonara | Samyang | KR | Noodles | M | TODO | 2026-04-07 | | |
| 3461 | Samyang Buldak Cheese | Samyang | KR | Noodles | M | TODO | 2026-04-07 | | |
| 3462 | Indomie Mi Goreng Original | Indomie | ID | Noodles | H | TODO | 2026-04-07 | | |
| 3463 | Indomie Mi Goreng BBQ Chicken | Indomie | ID | Noodles | M | TODO | 2026-04-07 | | |
| 3464 | Nissin Top Ramen Beef | Nissin | JP | Noodles | M | TODO | 2026-04-07 | | |
| 3465 | Maruchan Instant Lunch Chicken | Maruchan | US | Noodles | H | TODO | 2026-04-07 | | Budget noodles |
| 3466 | Lotus Biscoff Cookies | Lotus | BE | Cookies | H | TODO | 2026-04-07 | | |
| 3467 | Nutella & Go! Breadsticks | Ferrero | IT | Snacks | H | TODO | 2026-04-07 | | |
| 3468 | Tim Tam Original Chocolate | Arnott's | AU | Cookies | H | TODO | 2026-04-07 | | |
| 3469 | Digestive Biscuits Original | McVitie's | GB | Cookies | M | TODO | 2026-04-07 | | |
| 3470 | McVitie's Jaffa Cakes | McVitie's | GB | Cookies | M | TODO | 2026-04-07 | | |
| 3471 | Maggi 2-Minute Noodles Masala | Maggi | IN | Noodles | H | TODO | 2026-04-07 | | India's #1 instant |
| 3472 | Parle-G Biscuits | Parle | IN | Cookies | H | TODO | 2026-04-07 | | World's best-selling cookie by volume |
| 3473 | Patak's Tikka Masala Simmer Sauce | Patak's | GB | Condiments | H | TODO | 2026-04-07 | | |
| 3474 | Green Curry Paste | Thai Kitchen | TH | Condiments | M | TODO | 2026-04-07 | | |
| 3475 | Red Curry Paste | Thai Kitchen | TH | Condiments | M | TODO | 2026-04-07 | | |
| 3476 | Mochi Ice Cream Mango | My/Mo | JP | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 3477 | Mochi Ice Cream Strawberry | My/Mo | JP | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 3478 | Sriracha Mayo | Kewpie | JP | Condiments | M | TODO | 2026-04-07 | | |
| 3479 | Japanese Mayonnaise | Kewpie | JP | Condiments | H | TODO | 2026-04-07 | | |
| 3480 | Shrimp Chips | Calbee | JP | Snacks | M | TODO | 2026-04-07 | | |
| 3481 | Biscuit Wafer Chocolate | Knoppers | DE | Snacks | M | TODO | 2026-04-07 | | |
| 3482 | Aero Mint Chocolate Bar | Nestle | GB | Candy | M | TODO | 2026-04-07 | | |
| 3483 | Bounty Coconut Bar | Mars | GB | Candy | M | TODO | 2026-04-07 | | |
| 3484 | Stroopwafels Caramel | Daelmans | NL | Cookies | H | TODO | 2026-04-07 | | Dutch classic |
| 3485 | Lays Paprika Chips | Lay's | NL | Snacks | M | TODO | 2026-04-07 | | European flavor |
| 3486 | Manner Wafers Original | Manner | AT | Cookies | M | TODO | 2026-04-07 | | Austrian classic |
| 3487 | Pocky Cookies & Cream | Glico | JP | Snacks | M | TODO | 2026-04-07 | | |
| 3488 | Yan Yan Chocolate Dip | Meiji | JP | Snacks | M | TODO | 2026-04-07 | | |
| 3489 | Pepero Chocolate | Lotte | KR | Snacks | M | TODO | 2026-04-07 | | Korean Pocky |
| 3490 | Shrimp Flavored Chips | Nongshim | KR | Snacks | M | TODO | 2026-04-07 | | |
| 3491 | Banana Kick | Nongshim | KR | Snacks | M | TODO | 2026-04-07 | | |
| 3492 | Calpico Water Original | Calpis | JP | Beverages | M | TODO | 2026-04-07 | | |
| 3493 | Ramune Soda Original | Ramune | JP | Beverages | M | TODO | 2026-04-07 | | |
| 3494 | Leibniz Butter Biscuits | Bahlsen | DE | Cookies | M | TODO | 2026-04-07 | | |
| 3495 | Prince Chocolate Biscuits | LU | FR | Cookies | M | TODO | 2026-04-07 | | |
| 3496 | Vegemite Spread | Bega | AU | Spreads | M | TODO | 2026-04-07 | | Australian icon |
| 3497 | Walkers Cheese & Onion Crisps | Walkers | GB | Snacks | M | TODO | 2026-04-07 | | |
| 3498 | PG Tips Tea Bags | PG Tips | GB | Beverages | M | TODO | 2026-04-07 | | |
| 3499 | Yorkshire Tea Bags | Yorkshire Tea | GB | Beverages | M | TODO | 2026-04-07 | | |
| 3500 | Indomie Soto Mie | Indomie | ID | Noodles | M | TODO | 2026-04-07 | | |
| 3501 | Samyang Buldak Corn | Samyang | KR | Noodles | M | TODO | 2026-04-07 | | |
| 3502 | Nissin Demae Ramen Sesame | Nissin | JP | Noodles | M | TODO | 2026-04-07 | | |

## Section 121: Breakfast & Pantry Staples (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3503 | Eggo Buttermilk Waffles | Kellogg's | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 3504 | Eggo Chocolate Chip Waffles | Kellogg's | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 3505 | Pop-Tarts Frosted Strawberry | Kellogg's | US | Snacks | H | TODO | 2026-04-07 | | |
| 3506 | Pop-Tarts Frosted S'mores | Kellogg's | US | Snacks | M | TODO | 2026-04-07 | | |
| 3507 | Pop-Tarts Frosted Chocolate Fudge | Kellogg's | US | Snacks | M | TODO | 2026-04-07 | | |
| 3508 | Toaster Strudel Strawberry | Pillsbury | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 3509 | Toaster Strudel Apple | Pillsbury | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 3510 | Jimmy Dean Sausage Egg & Cheese Croissant | Jimmy Dean | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 3511 | Jimmy Dean Sausage Egg & Cheese Biscuit | Jimmy Dean | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 3512 | Oscar Mayer Deli Fresh Oven Roasted Turkey | Oscar Mayer | US | Deli | H | TODO | 2026-04-07 | | |
| 3513 | Oscar Mayer Lunchables Cracker Stackers Turkey | Oscar Mayer | US | Snacks | H | TODO | 2026-04-07 | | Kids favorite |
| 3514 | Oscar Mayer Lunchables Pizza | Oscar Mayer | US | Snacks | H | TODO | 2026-04-07 | | |
| 3515 | Oscar Mayer Lunchables Nachos | Oscar Mayer | US | Snacks | M | TODO | 2026-04-07 | | |
| 3516 | Hormel Natural Choice Oven Roasted Turkey | Hormel | US | Deli | M | TODO | 2026-04-07 | | |
| 3517 | Kraft Mac & Cheese Original | Kraft | US | Pasta | H | TODO | 2026-04-07 | | Iconic blue box |
| 3518 | Kraft Mac & Cheese Shapes | Kraft | US | Pasta | M | TODO | 2026-04-07 | | |
| 3519 | Kraft Mac & Cheese Deluxe | Kraft | US | Pasta | M | TODO | 2026-04-07 | | |
| 3520 | Kraft Velveeta Shells & Cheese | Kraft | US | Pasta | H | TODO | 2026-04-07 | | |
| 3521 | Velveeta Block | Kraft | US | Dairy | H | TODO | 2026-04-07 | | |
| 3522 | Jif Natural Creamy Peanut Butter | Jif | US | Spreads | M | TODO | 2026-04-07 | | |
| 3523 | Skippy Super Chunk Peanut Butter | Skippy | US | Spreads | M | TODO | 2026-04-07 | | |
| 3524 | Skippy Natural Creamy Peanut Butter | Skippy | US | Spreads | M | TODO | 2026-04-07 | | |
| 3525 | Smucker's Natural Peanut Butter | Smucker's | US | Spreads | M | TODO | 2026-04-07 | | |
| 3526 | Smucker's Uncrustables PB&J Grape | Smucker's | US | Frozen Meals | H | TODO | 2026-04-07 | | Kids lunch staple |
| 3527 | Smucker's Uncrustables PB&J Strawberry | Smucker's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 3528 | Aunt Jemima Original Pancake Mix | Aunt Jemima | US | Baking | M | TODO | 2026-04-07 | | Now Pearl Milling Co |
| 3529 | Bisquick Original Pancake Mix | Betty Crocker | US | Baking | H | TODO | 2026-04-07 | | |
| 3530 | Betty Crocker Super Moist Yellow Cake Mix | Betty Crocker | US | Baking | H | TODO | 2026-04-07 | | |
| 3531 | Betty Crocker Super Moist Chocolate Cake Mix | Betty Crocker | US | Baking | H | TODO | 2026-04-07 | | |
| 3532 | Betty Crocker Rich & Creamy Chocolate Frosting | Betty Crocker | US | Baking | M | TODO | 2026-04-07 | | |
| 3533 | Duncan Hines Classic Yellow Cake Mix | Duncan Hines | US | Baking | M | TODO | 2026-04-07 | | |
| 3534 | King Arthur Bread Flour | King Arthur | US | Baking | M | TODO | 2026-04-07 | | |
| 3535 | Rice-A-Roni Chicken Flavor | Rice-A-Roni | US | Sides | M | TODO | 2026-04-07 | | |
| 3536 | Knorr Rice Sides Cheddar Broccoli | Knorr | US | Sides | M | TODO | 2026-04-07 | | |
| 3537 | Knorr Pasta Sides Alfredo | Knorr | US | Sides | M | TODO | 2026-04-07 | | |
| 3538 | Knorr Pasta Sides Butter | Knorr | US | Sides | M | TODO | 2026-04-07 | | |
| 3539 | Uncle Ben's Ready Rice White | Uncle Ben's | US | Grains | H | TODO | 2026-04-07 | | Now Ben's Original |
| 3540 | Uncle Ben's Ready Rice Brown | Uncle Ben's | US | Grains | M | TODO | 2026-04-07 | | |
| 3541 | Uncle Ben's Ready Rice Jasmine | Uncle Ben's | US | Grains | M | TODO | 2026-04-07 | | |
| 3542 | Minute Rice White | Minute Rice | US | Grains | M | TODO | 2026-04-07 | | |
| 3543 | Idahoan Four Cheese Mashed | Idahoan | US | Sides | M | TODO | 2026-04-07 | | |
| 3544 | Stove Top Stuffing Chicken | Stove Top | US | Sides | M | TODO | 2026-04-07 | | |
| 3545 | McCormick Chili Seasoning | McCormick | US | Condiments | M | TODO | 2026-04-07 | | |
| 3546 | McCormick Ground Cinnamon | McCormick | US | Condiments | M | TODO | 2026-04-07 | | |
| 3547 | Lawry's Seasoned Salt | Lawry's | US | Condiments | H | TODO | 2026-04-07 | | |
| 3548 | Tony Chachere's Creole Seasoning | Tony Chachere's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3549 | Tajin Clasico Seasoning | Tajin | MX | Condiments | H | TODO | 2026-04-07 | | Trending |
| 3550 | Bragg Liquid Aminos | Bragg | US | Condiments | M | TODO | 2026-04-07 | | |
| 3551 | Tahini Organic | Soom | US | Condiments | M | TODO | 2026-04-07 | | |

## Section 122: Frozen Snacks & Appetizers (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3552 | Lean Pockets Chicken Broccoli & Cheddar | Lean Pockets | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 3553 | Bagel Bites Three Cheese | Bagel Bites | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 3554 | Bagel Bites Pepperoni & Cheese | Bagel Bites | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 3555 | DiGiorno Rising Crust Supreme | DiGiorno | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 3556 | DiGiorno Croissant Crust Pepperoni | DiGiorno | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3557 | Red Baron Classic Crust Four Cheese | Red Baron | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3558 | Red Baron French Bread Pepperoni | Red Baron | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3559 | Jack's Original Pepperoni | Jack's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3560 | California Pizza Kitchen BBQ Chicken | CPK | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3561 | California Pizza Kitchen Margherita | CPK | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3562 | Ore-Ida Golden Fries | Ore-Ida | US | Frozen Sides | H | TODO | 2026-04-07 | | |
| 3563 | Ore-Ida Tater Tots | Ore-Ida | US | Frozen Sides | H | TODO | 2026-04-07 | | |
| 3564 | Ore-Ida Crispy Crowns | Ore-Ida | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 3565 | Ore-Ida Extra Crispy Fast Food Fries | Ore-Ida | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 3566 | McCain Smiles Mashed Potato Shapes | McCain | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 3567 | TGI Fridays Honey BBQ Wings | TGI Friday's | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 3568 | Tyson Chicken Strips | Tyson | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 3569 | Tyson Any'tizers Buffalo Style Chicken Bites | Tyson | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 3570 | Tyson Grilled Chicken Breast Strips | Tyson | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 3571 | Perdue Simply Smart Chicken Breast Tenders | Perdue | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3572 | Perdue Chicken Breast Nuggets | Perdue | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3573 | Gorton's Beer Battered Fish Fillets | Gorton's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3574 | Gorton's Crunchy Breaded Fish Sticks | Gorton's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3575 | Van de Kamp's Fish Sticks | Van de Kamp's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3576 | Mrs. T's Pierogies Potato & Cheddar | Mrs. T's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3577 | Mrs. T's Pierogies Potato & Onion | Mrs. T's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3578 | El Monterey Beef & Bean Burritos | El Monterey | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 3579 | El Monterey Chicken & Cheese Taquitos | El Monterey | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 3580 | Jose Ole Chicken & Cheese Taquitos | Jose Ole | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 3581 | Jose Ole Beef & Cheese Chimichangas | Jose Ole | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3582 | Delimex Chicken & Cheese Taquitos | Delimex | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 3583 | White Castle Sliders Original 6-Pack | White Castle | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3584 | White Castle Sliders Jalapeno Cheeseburger | White Castle | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3585 | Newman's Own Thin & Crispy Margherita | Newman's Own | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3586 | Caulipower Cauliflower Crust Margherita | Caulipower | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3587 | Caulipower Cauliflower Crust Pepperoni | Caulipower | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3588 | Freschetta Naturally Rising Pepperoni | Freschetta | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3589 | Freschetta Brick Oven Pepperoni | Freschetta | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3590 | Farm Rich Mozzarella Sticks | Farm Rich | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 3591 | Farm Rich Jalapeno Peppers | Farm Rich | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 3592 | Farm Rich Mushrooms Breaded | Farm Rich | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 3593 | Eggo Thick & Fluffy Waffles | Kellogg's | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 3594 | Eggo Mini Pancakes | Kellogg's | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 3595 | Hot Pockets Steak & Cheddar | Hot Pockets | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 3596 | DiGiorno Thin Crust Pepperoni | DiGiorno | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3597 | Red Baron Thin Crust Pepperoni | Red Baron | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3598 | Perdue Chicken Plus Nuggets (with veggies) | Perdue | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3599 | El Monterey Signature Chicken Burritos | El Monterey | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3600 | Jose Ole Steak & Cheese Chimichangas | Jose Ole | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3601 | PF Chang's Pork Dumplings | PF Chang's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3602 | Ore-Ida Shoestring Fries | Ore-Ida | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 3603 | Alexia Organic Yukon Select Fries | Alexia | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 3604 | Nathan's Famous Crinkle Cut Fries | Nathan's | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 3605 | Nathan's Famous Jumbo Crinkle Cut Fries | Nathan's | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 3606 | Gorton's Grilled Tilapia | Gorton's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3607 | Applegate Naturals Turkey Hot Dogs | Applegate | US | Meat | M | TODO | 2026-04-07 | | |
| 3608 | Applegate Naturals Uncured Beef Hot Dogs | Applegate | US | Meat | M | TODO | 2026-04-07 | | |
| 3609 | Hebrew National Beef Franks | Hebrew National | US | Meat | H | TODO | 2026-04-07 | | |

## Section 123: Coffee & Energy Drinks (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3610 | Pike Place Roast K-Cup | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 3611 | French Roast K-Cup | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 3612 | Blonde Roast K-Cup | Starbucks | US | Beverages | M | TODO | 2026-04-07 | | |
| 3613 | Frappuccino Mocha Bottled | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 3614 | Frappuccino Vanilla Bottled | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 3615 | Doubleshot Espresso Can | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 3616 | Doubleshot Energy Mocha | Starbucks | US | Beverages | M | TODO | 2026-04-07 | | |
| 3617 | Dunkin' Original Blend K-Cup | Dunkin' | US | Beverages | H | TODO | 2026-04-07 | | |
| 3618 | Dunkin' French Vanilla K-Cup | Dunkin' | US | Beverages | M | TODO | 2026-04-07 | | |
| 3619 | Folgers Classic Roast Ground | Folgers | US | Beverages | H | TODO | 2026-04-07 | | |
| 3620 | Folgers Black Silk Ground | Folgers | US | Beverages | M | TODO | 2026-04-07 | | |
| 3621 | Maxwell House Original Roast | Maxwell House | US | Beverages | M | TODO | 2026-04-07 | | |
| 3622 | Peet's Major Dickason's K-Cup | Peet's | US | Beverages | M | TODO | 2026-04-07 | | |
| 3623 | Peet's Big Bang Medium Roast | Peet's | US | Beverages | M | TODO | 2026-04-07 | | |
| 3624 | Lavazza Super Crema Espresso | Lavazza | IT | Beverages | M | TODO | 2026-04-07 | | |
| 3625 | Lavazza Qualita Oro Ground | Lavazza | IT | Beverages | M | TODO | 2026-04-07 | | |
| 3626 | Illy Classico Whole Bean | Illy | IT | Beverages | M | TODO | 2026-04-07 | | |
| 3627 | Death Wish Coffee Ground | Death Wish | US | Beverages | M | TODO | 2026-04-07 | | Extra strong |
| 3628 | Green Mountain Breakfast Blend K-Cup | Green Mountain | US | Beverages | H | TODO | 2026-04-07 | | |
| 3629 | Green Mountain Nantucket Blend K-Cup | Green Mountain | US | Beverages | M | TODO | 2026-04-07 | | |
| 3630 | Cafe Bustelo Espresso Ground | Cafe Bustelo | US | Beverages | H | TODO | 2026-04-07 | | |
| 3631 | Cafe Bustelo K-Cup | Cafe Bustelo | US | Beverages | M | TODO | 2026-04-07 | | |
| 3632 | Nescafe Clasico Instant Coffee | Nescafe | CH | Beverages | M | TODO | 2026-04-07 | | |
| 3633 | Coffee-mate French Vanilla Creamer | Coffee-mate | US | Dairy | H | TODO | 2026-04-07 | | |
| 3634 | Coffee-mate Hazelnut Creamer | Coffee-mate | US | Dairy | M | TODO | 2026-04-07 | | |
| 3635 | Chobani Coffee Creamer Sweet Cream | Chobani | US | Dairy | M | TODO | 2026-04-07 | | |
| 3636 | Nutpods Original Unsweetened Creamer | Nutpods | US | Dairy Alt | M | TODO | 2026-04-07 | | Dairy-free |
| 3637 | Monster Rehab Tea + Lemonade | Monster | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3638 | Monster Java Mean Bean | Monster | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3639 | Rockstar Original | Rockstar | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3640 | Rockstar Sugar Free | Rockstar | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3641 | Rockstar Recovery Lemonade | Rockstar | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3642 | 5-Hour Energy Original Berry | 5-Hour Energy | US | Energy Drinks | H | TODO | 2026-04-07 | | |
| 3643 | 5-Hour Energy Extra Strength Grape | 5-Hour Energy | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3644 | Bang Energy Cherry Blade Lemonade | Bang | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3645 | Reign Total Body Fuel Lemon HDZ | Reign | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3646 | Reign Total Body Fuel Orange Dreamsicle | Reign | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3647 | Reign Total Body Fuel Melon Mania | Reign | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3648 | C4 Energy Strawberry Watermelon | C4 | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 3649 | ZOA Energy Original | ZOA | US | Energy Drinks | M | TODO | 2026-04-07 | | The Rock's brand |
| 3650 | Coca-Cola Classic 12oz | Coca-Cola | US | Beverages | H | TODO | 2026-04-07 | | |
| 3651 | Coca-Cola Zero Sugar 12oz | Coca-Cola | US | Beverages | H | TODO | 2026-04-07 | | |
| 3652 | Sprite 12oz | Coca-Cola | US | Beverages | H | TODO | 2026-04-07 | | |
| 3653 | Pepsi 12oz | PepsiCo | US | Beverages | H | TODO | 2026-04-07 | | |
| 3654 | 7UP 12oz | Keurig Dr Pepper | US | Beverages | M | TODO | 2026-04-07 | | |
| 3655 | Canada Dry Ginger Ale 12oz | Keurig Dr Pepper | US | Beverages | M | TODO | 2026-04-07 | | |
| 3656 | Mello Yello 12oz | Coca-Cola | US | Beverages | L | TODO | 2026-04-07 | | |
| 3657 | Sierra Mist (Starry) 12oz | PepsiCo | US | Beverages | M | TODO | 2026-04-07 | | |
| 3658 | Olipop Vintage Cola | Olipop | US | Beverages | H | TODO | 2026-04-07 | | Prebiotic soda |
| 3659 | Olipop Strawberry Vanilla | Olipop | US | Beverages | H | TODO | 2026-04-07 | | |
| 3660 | Olipop Orange Squeeze | Olipop | US | Beverages | M | TODO | 2026-04-07 | | |
| 3661 | Olipop Ginger Lemon | Olipop | US | Beverages | M | TODO | 2026-04-07 | | |
| 3662 | Olipop Root Beer | Olipop | US | Beverages | M | TODO | 2026-04-07 | | |
| 3663 | Poppi Strawberry Lemon Prebiotic Soda | Poppi | US | Beverages | H | TODO | 2026-04-07 | | |
| 3664 | Poppi Orange Prebiotic Soda | Poppi | US | Beverages | M | TODO | 2026-04-07 | | |
| 3665 | Poppi Cola Prebiotic Soda | Poppi | US | Beverages | M | TODO | 2026-04-07 | | |
| 3666 | Zevia Zero Calorie Cola | Zevia | US | Beverages | M | TODO | 2026-04-07 | | Stevia sweetened |
| 3667 | Zevia Zero Calorie Ginger Ale | Zevia | US | Beverages | M | TODO | 2026-04-07 | | |
| 3668 | Zevia Zero Calorie Cream Soda | Zevia | US | Beverages | M | TODO | 2026-04-07 | | |
| 3669 | Athletic Brewing Run Wild IPA (NA Beer) | Athletic Brewing | US | Beverages | M | TODO | 2026-04-07 | | Non-alcoholic |
| 3670 | Athletic Brewing Free Wave Hazy IPA | Athletic Brewing | US | Beverages | M | TODO | 2026-04-07 | | |
| 3671 | Heineken 0.0 Non-Alcoholic Beer | Heineken | NL | Beverages | M | TODO | 2026-04-07 | | |
| 3672 | Guinness 0 Non-Alcoholic Stout | Guinness | IE | Beverages | M | TODO | 2026-04-07 | | |
| 3673 | Liquid Death Mountain Water | Liquid Death | US | Beverages | H | TODO | 2026-04-07 | | Trending brand |
| 3674 | Liquid Death Mango Chainsaw | Liquid Death | US | Beverages | M | TODO | 2026-04-07 | | |
| 3675 | Liquid Death Berry It Alive | Liquid Death | US | Beverages | M | TODO | 2026-04-07 | | |

## Section 124: Additional Grocery & Specialty (380 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 3676 | Original Hummus | Sabra | US | Dips | H | TODO | 2026-04-07 | | #1 hummus brand |
| 3677 | Classic Guacamole | Wholly Guacamole | US | Dips | H | TODO | 2026-04-07 | | |
| 3678 | Spicy Guacamole | Wholly Guacamole | US | Dips | M | TODO | 2026-04-07 | | |
| 3679 | Original Guacamole Cups | Good Foods | US | Dips | M | TODO | 2026-04-07 | | |
| 3680 | Buffalo Style Dip | Good Foods | US | Dips | M | TODO | 2026-04-07 | | |
| 3681 | Queso Blanco Dip | Tostitos | US | Dips | M | TODO | 2026-04-07 | | |
| 3682 | Roasted Garlic Hummus | Cedar's | US | Dips | M | TODO | 2026-04-07 | | |
| 3683 | Jalapeño Artichoke Dip | Stonemill Kitchens | US | Dips | M | TODO | 2026-04-07 | | |
| 3684 | Bacon Cheddar Dip | Heluva Good | US | Dips | M | TODO | 2026-04-07 | | |
| 3685 | Everything Hummus | Sabra | US | Dips | M | TODO | 2026-04-07 | | |
| 3686 | Organic Hummus Classic | Hope Foods | US | Dips | M | TODO | 2026-04-07 | | |
| 3687 | Epic Venison Sea Salt Pepper Bar | Epic | US | Snacks | M | TODO | 2026-04-07 | | |
| 3688 | Chomps Italian Style Beef | Chomps | US | Snacks | M | TODO | 2026-04-07 | | |
| 3689 | Blue Diamond Almonds Whole Natural | Blue Diamond | US | Snacks | H | TODO | 2026-04-07 | | |
| 3690 | Blue Diamond Almonds Smokehouse | Blue Diamond | US | Snacks | H | TODO | 2026-04-07 | | |
| 3691 | Blue Diamond Almonds Wasabi & Soy | Blue Diamond | US | Snacks | M | TODO | 2026-04-07 | | |
| 3692 | Blue Diamond Almonds Salt & Vinegar | Blue Diamond | US | Snacks | M | TODO | 2026-04-07 | | |
| 3693 | Planters Mixed Nuts | Planters | US | Snacks | H | TODO | 2026-04-07 | | |
| 3694 | Planters Cashews Salted | Planters | US | Snacks | M | TODO | 2026-04-07 | | |
| 3695 | Planters NUT-rition Heart Healthy Mix | Planters | US | Snacks | M | TODO | 2026-04-07 | | |
| 3696 | Sahale Snacks Glazed Mix Pomegranate | Sahale | US | Snacks | M | TODO | 2026-04-07 | | |
| 3697 | Sun-Maid Raisins | Sun-Maid | US | Snacks | H | TODO | 2026-04-07 | | |
| 3698 | Dang Coconut Chips Original | Dang | US | Snacks | M | TODO | 2026-04-07 | | |
| 3699 | Lesser Evil Himalayan Pink Salt Popcorn | Lesser Evil | US | Snacks | M | TODO | 2026-04-07 | | |
| 3700 | Siete Cashew Queso | Siete | US | Dips | M | TODO | 2026-04-07 | | |
| 3701 | Lily's Salted Caramel Chocolate Bar | Lily's | US | Candy | M | TODO | 2026-04-07 | | |
| 3702 | 88 Acres Seed Butter Chocolate Sunflower | 88 Acres | US | Spreads | L | TODO | 2026-04-07 | | Nut-free |
| 3703 | SunButter Creamy Sunflower Butter | SunButter | US | Spreads | M | TODO | 2026-04-07 | | Nut-free |
| 3704 | Wild Friends Chocolate Peanut Butter | Wild Friends | US | Spreads | L | TODO | 2026-04-07 | | |
| 3705 | Noka Superfood Smoothie Blueberry Beet | Noka | US | Beverages | L | TODO | 2026-04-07 | | |
| 3706 | Annie's Classic Mac & Cheese | Annie's | US | Pasta | H | TODO | 2026-04-07 | | Organic kids |
| 3707 | Annie's White Cheddar Bunny Mac & Cheese | Annie's | US | Pasta | H | TODO | 2026-04-07 | | |
| 3708 | Annie's Cheddar Bunnies Crackers | Annie's | US | Snacks | H | TODO | 2026-04-07 | | |
| 3709 | Annie's Organic Pizza Poppers | Annie's | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 3710 | Mott's Applesauce Original | Mott's | US | Snacks | H | TODO | 2026-04-07 | | |
| 3711 | Mott's Applesauce No Sugar Added | Mott's | US | Snacks | M | TODO | 2026-04-07 | | |
| 3712 | GoGo squeeZ Apple Apple | GoGo squeeZ | US | Snacks | H | TODO | 2026-04-07 | | Kids pouches |
| 3713 | GoGo squeeZ Apple Strawberry | GoGo squeeZ | US | Snacks | M | TODO | 2026-04-07 | | |
| 3714 | Snapea Crisps Caesar | Harvest Snaps | US | Snacks | M | TODO | 2026-04-07 | | |
| 3715 | Sahale Snacks Honey Almonds | Sahale | US | Snacks | M | TODO | 2026-04-07 | | |
| 3716 | That's It Mini Fruit Bars Apple Strawberry | That's It | US | Snacks | L | TODO | 2026-04-07 | | |
| 3717 | Rhythm Superfoods Kale Chips Zesty Nacho | Rhythm | US | Snacks | L | TODO | 2026-04-07 | | |
| 3718 | 365 Organic Peanut Butter Creamy | 365 (Whole Foods) | US | Spreads | M | TODO | 2026-04-07 | | |
| 3719 | 365 Organic Baby Spinach | 365 (Whole Foods) | US | Produce | M | TODO | 2026-04-07 | | |
| 3720 | 365 Organic Eggs Large | 365 (Whole Foods) | US | Dairy | M | TODO | 2026-04-07 | | |
| 3721 | Vital Farms Pasture-Raised Eggs | Vital Farms | US | Dairy | H | TODO | 2026-04-07 | | Premium eggs |
| 3722 | Eggland's Best Eggs Large | Eggland's Best | US | Dairy | H | TODO | 2026-04-07 | | |
| 3723 | Pete and Gerry's Organic Free Range Eggs | Pete and Gerry's | US | Dairy | M | TODO | 2026-04-07 | | |
| 3724 | Nellie's Free Range Eggs | Nellie's | US | Dairy | M | TODO | 2026-04-07 | | |
| 3725 | Kerrygold Pure Irish Butter | Kerrygold | IE | Dairy | H | TODO | 2026-04-07 | | Grass-fed |
| 3726 | Challenge Butter | Challenge | US | Dairy | M | TODO | 2026-04-07 | | |
| 3727 | Plugra European Style Butter | Plugra | US | Dairy | M | TODO | 2026-04-07 | | |
| 3728 | Ghee Organic Original | 4th & Heart | US | Dairy | M | TODO | 2026-04-07 | | |
| 3729 | Ghee Organic | Ancient Organics | US | Dairy | M | TODO | 2026-04-07 | | |
| 3730 | Babybel Original | Babybel | FR | Dairy | H | TODO | 2026-04-07 | | |
| 3731 | Babybel Light | Babybel | FR | Dairy | M | TODO | 2026-04-07 | | |
| 3732 | Laughing Cow Original Swiss | Laughing Cow | FR | Dairy | H | TODO | 2026-04-07 | | |
| 3733 | Laughing Cow Garlic & Herb | Laughing Cow | FR | Dairy | M | TODO | 2026-04-07 | | |
| 3734 | Boursin Garlic & Fine Herbs | Boursin | FR | Dairy | M | TODO | 2026-04-07 | | |
| 3735 | Boursin Basil & Chive | Boursin | FR | Dairy | L | TODO | 2026-04-07 | | |
| 3736 | Sargento Balanced Breaks Cheese & Crackers | Sargento | US | Snacks | M | TODO | 2026-04-07 | | |
| 3737 | Sargento Sharp Cheddar Slices | Sargento | US | Dairy | M | TODO | 2026-04-07 | | |
| 3738 | Sargento Shredded Mexican Blend | Sargento | US | Dairy | M | TODO | 2026-04-07 | | |
| 3739 | Applegate Organic Uncured Turkey Hot Dog | Applegate | US | Meat | M | TODO | 2026-04-07 | | |
| 3740 | Boar's Head Deluxe Ham | Boar's Head | US | Deli | M | TODO | 2026-04-07 | | |
| 3741 | Columbus Italian Dry Salame | Columbus | US | Deli | M | TODO | 2026-04-07 | | |
| 3742 | Hillshire Farm Ultra Thin Oven Roasted Turkey | Hillshire Farm | US | Deli | H | TODO | 2026-04-07 | | |
| 3743 | Hillshire Farm Lit'l Smokies | Hillshire Farm | US | Meat | H | TODO | 2026-04-07 | | |
| 3744 | Aidells Chicken Apple Sausage | Aidells | US | Meat | M | TODO | 2026-04-07 | | |
| 3745 | Aidells Italian Style Sausage | Aidells | US | Meat | M | TODO | 2026-04-07 | | |
| 3746 | Jennie-O Turkey Breast Ground | Jennie-O | US | Meat | H | TODO | 2026-04-07 | | |
| 3747 | Jennie-O Turkey Burgers | Jennie-O | US | Meat | M | TODO | 2026-04-07 | | |
| 3748 | Wright Brand Hickory Smoked Bacon | Wright | US | Meat | H | TODO | 2026-04-07 | | Thick cut |
| 3749 | Hormel Black Label Bacon | Hormel | US | Meat | H | TODO | 2026-04-07 | | |
| 3750 | Pederson's No Sugar Added Bacon | Pederson's | US | Meat | M | TODO | 2026-04-07 | | Whole30 |
| 3751 | Niman Ranch Uncured Applewood Smoked Bacon | Niman Ranch | US | Meat | M | TODO | 2026-04-07 | | |
| 3752 | Simple Mills Crunchy Cookies Chocolate Chip | Simple Mills | US | Cookies | M | TODO | 2026-04-07 | | |
| 3753 | Simple Mills Pizza Dough Mix | Simple Mills | US | Baking | L | TODO | 2026-04-07 | | |
| 3754 | Hu Kitchen Grain-Free Crackers Sea Salt | Hu | US | Snacks | M | TODO | 2026-04-07 | | |
| 3755 | Birch Benders Protein Pancake Mix | Birch Benders | US | Baking | M | TODO | 2026-04-07 | | |
| 3756 | Birch Benders Keto Pancake Mix | Birch Benders | US | Baking | M | TODO | 2026-04-07 | | |
| 3757 | Bob's Red Mill Old Fashioned Oats | Bob's Red Mill | US | Cereal | H | TODO | 2026-04-07 | | |
| 3758 | Bob's Red Mill Organic Steel Cut Oats | Bob's Red Mill | US | Cereal | M | TODO | 2026-04-07 | | |
| 3759 | Bob's Red Mill GF 1 to 1 Baking Flour | Bob's Red Mill | US | Baking | M | TODO | 2026-04-07 | | |
| 3760 | Bob's Red Mill Flaxseed Meal | Bob's Red Mill | US | Baking | M | TODO | 2026-04-07 | | |
| 3761 | Bob's Red Mill Organic Quinoa | Bob's Red Mill | US | Grains | M | TODO | 2026-04-07 | | |
| 3762 | Orgain Organic Protein Powder Vanilla | Orgain | US | Supplements | M | TODO | 2026-04-07 | | |
| 3763 | Vega One All-in-One Shake Chocolate | Vega | US | Supplements | M | TODO | 2026-04-07 | | Plant-based |
| 3764 | Vega Sport Premium Protein Chocolate | Vega | US | Supplements | M | TODO | 2026-04-07 | | |
| 3765 | Garden of Life Raw Organic Protein Vanilla | Garden of Life | US | Supplements | M | TODO | 2026-04-07 | | |
| 3766 | Amazing Grass Green Superfood Original | Amazing Grass | US | Supplements | M | TODO | 2026-04-07 | | |
| 3767 | AG1 Athletic Greens Powder | AG1 | US | Supplements | H | TODO | 2026-04-07 | | Trending supplement |
| 3768 | Muscle Milk Genuine Protein Shake Chocolate | Muscle Milk | US | Beverages | H | TODO | 2026-04-07 | | |
| 3769 | Muscle Milk Genuine Protein Shake Vanilla | Muscle Milk | US | Beverages | M | TODO | 2026-04-07 | | |
| 3770 | Ensure Original Nutrition Shake Vanilla | Ensure | US | Beverages | H | TODO | 2026-04-07 | | |
| 3771 | Ensure Plus Chocolate | Ensure | US | Beverages | M | TODO | 2026-04-07 | | |
| 3772 | Ensure Max Protein Chocolate | Ensure | US | Beverages | M | TODO | 2026-04-07 | | |
| 3773 | Boost Original Chocolate | Boost | US | Beverages | M | TODO | 2026-04-07 | | |
| 3774 | Carnation Breakfast Essentials Classic French Vanilla | Carnation | US | Beverages | M | TODO | 2026-04-07 | | |
| 3775 | Ovaltine Rich Chocolate Mix | Ovaltine | CH | Beverages | M | TODO | 2026-04-07 | | |
| 3776 | Nesquik Chocolate Powder | Nesquik | US | Beverages | H | TODO | 2026-04-07 | | |
| 3777 | Swiss Miss Hot Cocoa Classic | Swiss Miss | US | Beverages | H | TODO | 2026-04-07 | | |
| 3778 | Swiss Miss Hot Cocoa Marshmallow | Swiss Miss | US | Beverages | M | TODO | 2026-04-07 | | |
| 3779 | Ghirardelli Hot Chocolate Double Chocolate | Ghirardelli | US | Beverages | M | TODO | 2026-04-07 | | |
| 3780 | Abuelita Mexican Hot Chocolate | Nestle | MX | Beverages | M | TODO | 2026-04-07 | | |
| 3781 | McCann's Irish Oatmeal Steel Cut | McCann's | IE | Cereal | M | TODO | 2026-04-07 | | |
| 3782 | Kind Healthy Grains Clusters Vanilla Blueberry | KIND | US | Cereal | M | TODO | 2026-04-07 | | |
| 3783 | Purely Elizabeth Original Ancient Grain Granola | Purely Elizabeth | US | Cereal | M | TODO | 2026-04-07 | | |
| 3784 | Back to Nature Granola Classic | Back to Nature | US | Cereal | M | TODO | 2026-04-07 | | |
| 3785 | Ezekiel 4:9 Sprouted Grain English Muffins | Food For Life | US | Bread | M | TODO | 2026-04-07 | | |
| 3786 | Ezekiel 4:9 Sprouted Grain Tortillas | Food For Life | US | Bread | M | TODO | 2026-04-07 | | |
| 3787 | Silver Hills Sprouted Power Bread | Silver Hills | CA | Bread | L | TODO | 2026-04-07 | | |
| 3788 | Base Culture Keto Bread | Base Culture | US | Bread | L | TODO | 2026-04-07 | | |
| 3789 | Angelic Bakehouse Sprouted 7 Grain Bread | Angelic Bakehouse | US | Bread | L | TODO | 2026-04-07 | | |
| 3790 | La Tortilla Factory Low Carb Tortillas | La Tortilla Factory | US | Bread | M | TODO | 2026-04-07 | | |
| 3791 | Crepini Egg Wraps | Crepini | US | Bread | M | TODO | 2026-04-07 | | |
| 3792 | Naan Dippers Original | Stonefire | US | Snacks | M | TODO | 2026-04-07 | | |
| 3793 | Skinny Pop Mini Cakes Cheddar | SkinnyPop | US | Snacks | M | TODO | 2026-04-07 | | |
| 3794 | Smart Sweets Peach Rings | Smart Sweets | US | Candy | M | TODO | 2026-04-07 | | Low sugar |
| 3795 | Yasso Mint Chocolate Chip Frozen Greek Yogurt Bar | Yasso | US | Frozen Desserts | H | TODO | 2026-04-07 | | |
| 3796 | Yasso Chocolate Fudge Frozen Greek Yogurt Bar | Yasso | US | Frozen Desserts | H | TODO | 2026-04-07 | | |
| 3797 | Nick's Light Ice Cream Swedish Strawberry | Nick's | SE | Ice Cream | M | TODO | 2026-04-07 | | Low calorie |
| 3798 | Nick's Light Ice Cream Peanot Butter Cup | Nick's | SE | Ice Cream | M | TODO | 2026-04-07 | | |
| 3799 | Enlightened Keto Collection Chocolate Peanut Butter | Enlightened | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3800 | Arctic Zero Chocolate Peanut Butter | Arctic Zero | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 3801 | Clio Greek Yogurt Bar Chocolate | Clio | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 3802 | Outshine Strawberry Fruit Bars | Outshine | US | Frozen Desserts | H | TODO | 2026-04-07 | | |
| 3803 | Outshine Mango Fruit Bars | Outshine | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 3804 | Dole Whip Frozen Treat Pineapple | Dole | US | Frozen Desserts | M | TODO | 2026-04-07 | | Disney Parks famous |
| 3805 | Dole Fruit Cups Diced Peaches | Dole | US | Snacks | M | TODO | 2026-04-07 | | |
| 3806 | Snack Pack Chocolate Pudding | Snack Pack | US | Snacks | H | TODO | 2026-04-07 | | |
| 3807 | Snack Pack Vanilla Pudding | Snack Pack | US | Snacks | M | TODO | 2026-04-07 | | |
| 3808 | Jell-O Chocolate Pudding Cup | Jell-O | US | Snacks | H | TODO | 2026-04-07 | | |
| 3809 | Jell-O Vanilla Pudding Cup | Jell-O | US | Snacks | M | TODO | 2026-04-07 | | |
| 3810 | Jell-O Strawberry Gelatin Cup | Jell-O | US | Snacks | M | TODO | 2026-04-07 | | |
| 3811 | Kozy Shack Rice Pudding | Kozy Shack | US | Snacks | M | TODO | 2026-04-07 | | |
| 3812 | Kozy Shack Tapioca Pudding | Kozy Shack | US | Snacks | M | TODO | 2026-04-07 | | |
| 3813 | Cool Whip Original | Cool Whip | US | Dairy | H | TODO | 2026-04-07 | | |
| 3814 | Dream Whip Whipped Topping | Dream Whip | US | Baking | L | TODO | 2026-04-07 | | |
| 3815 | Dannon Danimals Strawberry Yogurt | Dannon | US | Dairy | M | TODO | 2026-04-07 | | Kids yogurt |
| 3816 | Dannon Danimals Smoothie Strawberry Banana | Dannon | US | Dairy | M | TODO | 2026-04-07 | | |
| 3817 | Fresh Mozzarella Ball | Galbani | IT | Dairy | M | TODO | 2026-04-07 | | |
| 3818 | BelGioioso Fresh Mozzarella Pearls | BelGioioso | US | Dairy | M | TODO | 2026-04-07 | | |
| 3819 | BelGioioso Burrata | BelGioioso | US | Dairy | M | TODO | 2026-04-07 | | |
| 3820 | Président Brie | Président | FR | Dairy | M | TODO | 2026-04-07 | | |
| 3821 | Alouette Garlic & Herbs Spread | Alouette | FR | Dairy | M | TODO | 2026-04-07 | | |
| 3822 | La Banderita Flour Tortillas | La Banderita | US | Bread | M | TODO | 2026-04-07 | | |
| 3823 | Guerrero White Corn Tortillas | Guerrero | MX | Bread | M | TODO | 2026-04-07 | | |
| 3824 | Mi Rancho Organic Flour Tortillas | Mi Rancho | US | Bread | L | TODO | 2026-04-07 | | |
| 3825 | Schar Gluten Free Multigrain Bread | Schar | IT | Bread | M | TODO | 2026-04-07 | | |
| 3826 | Schar Gluten Free Ciabatta Rolls | Schar | IT | Bread | L | TODO | 2026-04-07 | | |
| 3827 | Three Bridges Egg Bites Uncured Bacon | Three Bridges | US | Dairy | M | TODO | 2026-04-07 | | Starbucks-style |
| 3828 | Kodiak Power Waffles Buttermilk & Vanilla | Kodiak | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 3829 | Good Food Made Simple Chicken Apple Sausage Burrito | Good Food Made Simple | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 3830 | Wyman's Wild Blueberries Frozen | Wyman's | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 3831 | Dole Frozen Pineapple Chunks | Dole | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 3832 | Cascadian Farm Organic Frozen Blueberries | Cascadian Farm | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 3833 | Woodstock Organic Frozen Mango | Woodstock | US | Frozen Fruit | L | TODO | 2026-04-07 | | |
| 3834 | Ben & Jerry's Non-Dairy Chocolate Fudge Brownie | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3835 | Talenti Layers Chocolate Cherry Cheesecake | Talenti | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3836 | Blue Bell Cookie Two Step | Blue Bell | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3837 | Turkey Hill All Natural Vanilla Bean | Turkey Hill | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3838 | Breyers CarbSmart Vanilla | Breyers | US | Ice Cream | M | TODO | 2026-04-07 | | Low carb |
| 3839 | Edy's/Dreyer's Outshine No Sugar Added Bars | Outshine | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 3840 | Good Humor Toasted Almond Bar | Good Humor | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3841 | Jeni's Brown Butter Almond Brittle | Jeni's Splendid | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 3842 | Salt & Straw Strawberry Honey Balsamic | Salt & Straw | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 3843 | Ore-Ida Just Crack an Egg Denver Scramble | Ore-Ida | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 3844 | Weight Watchers Smart Ones Angel Hair Marinara | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3845 | PF Chang's Mongolian Beef | PF Chang's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3846 | Michael Angelo's Lasagna with Meat Sauce | Michael Angelo's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3847 | Bertolli Four Cheese Ravioli | Bertolli | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 3848 | Applegate Naturals Sunday Bacon Pork | Applegate | US | Meat | M | TODO | 2026-04-07 | | |
| 3849 | Columbus Genoa Salame | Columbus | US | Deli | M | TODO | 2026-04-07 | | |
| 3850 | Belgioioso Parmesan Wedge | BelGioioso | US | Dairy | M | TODO | 2026-04-07 | | |
| 3851 | Sargento Pepper Jack Slices | Sargento | US | Dairy | M | TODO | 2026-04-07 | | |
| 3852 | Cracker Barrel Extra Sharp Cheddar | Cracker Barrel | US | Dairy | M | TODO | 2026-04-07 | | |
| 3853 | Borden Shredded Mozzarella | Borden | US | Dairy | M | TODO | 2026-04-07 | | |
| 3854 | Wholly Avocado Smashed Avocado | Wholly Guacamole | US | Dips | M | TODO | 2026-04-07 | | |
| 3855 | Cedars Hommus Original | Cedar's | US | Dips | M | TODO | 2026-04-07 | | |
| 3856 | Tribe Classic Hummus | Tribe | US | Dips | M | TODO | 2026-04-07 | | |
| 3857 | Ithaca Lemon Garlic Hummus | Ithaca | US | Dips | M | TODO | 2026-04-07 | | |
| 3858 | Bitchin' Sauce Original | Bitchin' Sauce | US | Dips | M | TODO | 2026-04-07 | | Almond-based |
| 3859 | San Marzano DOP Tomatoes | Cento | IT | Canned Goods | M | TODO | 2026-04-07 | | |
| 3860 | Tuttorosso Crushed Tomatoes | Tuttorosso | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3861 | Rao's Tomato Basil Sauce | Rao's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3862 | La Morena Chipotle Peppers in Adobo | La Morena | MX | Canned Goods | M | TODO | 2026-04-07 | | |
| 3863 | Hatch Green Chile Diced | Hatch | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3864 | RO*TEL Mild Diced Tomatoes | Rotel | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3865 | Amy's Organic Chunky Tomato Bisque | Amy's Kitchen | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3866 | Pacific Foods Organic Chicken Bone Broth | Pacific Foods | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3867 | Kettle & Fire Bone Broth Chicken | Kettle & Fire | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3868 | Kitchen Basics Unsalted Chicken Stock | Kitchen Basics | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 3869 | Thai Kitchen Lite Coconut Milk | Thai Kitchen | TH | Canned Goods | M | TODO | 2026-04-07 | | |
| 3870 | Aroy-D Coconut Milk | Aroy-D | TH | Canned Goods | M | TODO | 2026-04-07 | | |
| 3871 | Rancho Gordo Heirloom Beans | Rancho Gordo | US | Grains | L | TODO | 2026-04-07 | | Artisan beans |
| 3872 | Wild Planet Wild Albacore Tuna | Wild Planet | US | Canned Goods | M | TODO | 2026-04-07 | | Sustainable |
| 3873 | Safe Catch Elite Wild Tuna | Safe Catch | US | Canned Goods | M | TODO | 2026-04-07 | | Low mercury |
| 3874 | Crofton Bone Broth Protein Chocolate | Ancient Nutrition | US | Supplements | M | TODO | 2026-04-07 | | |
| 3875 | Manitoba Harvest Hemp Hearts | Manitoba Harvest | CA | Pantry | M | TODO | 2026-04-07 | | |
| 3876 | Yellowbird Blue Agave Sriracha | Yellowbird | US | Condiments | M | TODO | 2026-04-07 | | |
| 3877 | Siete Mild Green Enchilada Sauce | Siete | US | Condiments | L | TODO | 2026-04-07 | | |
| 3878 | Primal Kitchen Chipotle Lime Mayo | Primal Kitchen | US | Condiments | M | TODO | 2026-04-07 | | |
| 3879 | Mike's Hot Honey Extra Hot | Mike's Hot Honey | US | Condiments | M | TODO | 2026-04-07 | | |
| 3880 | Truff Hotter Sauce | Truff | US | Condiments | L | TODO | 2026-04-07 | | |
| 3881 | Tessemae's Organic Ranch | Tessemae's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3882 | Mother-in-Law's Gochujang Fermented Chile Paste | Mother-in-Law's | US | Condiments | M | TODO | 2026-04-07 | | |
| 3883 | CJ Gochujang Hot Pepper Paste | CJ | KR | Condiments | M | TODO | 2026-04-07 | | |
| 3884 | Chili Crunch Original | Momofuku | US | Condiments | M | TODO | 2026-04-07 | | David Chang brand |
| 3885 | Everything Sauce | Bitchin' Sauce | US | Condiments | L | TODO | 2026-04-07 | | |
| 3886 | Classico Roasted Red Pepper Alfredo | Classico | US | Condiments | M | TODO | 2026-04-07 | | |
| 3887 | La Colombe Draft Latte Triple Shot | La Colombe | US | Beverages | M | TODO | 2026-04-07 | | |
| 3888 | La Colombe Draft Latte Vanilla | La Colombe | US | Beverages | M | TODO | 2026-04-07 | | |
| 3889 | Silk Oat Yeah Oatmilk Creamer Vanilla | Silk | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 3890 | Califia Farms Better Half Unsweetened | Califia Farms | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 3891 | Oatly Barista Edition Oat Milk | Oatly | SE | Dairy Alt | H | TODO | 2026-04-07 | | |
| 3892 | Chobani Oat Creamer Vanilla | Chobani | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 3893 | Ripple Half & Half Alternative | Ripple | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 3894 | Planet Oat Extra Creamy Oat Milk | Planet Oat | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 3895 | Elmhurst 1925 Oat Milk Barista Edition | Elmhurst | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 3896 | Malk Organic Oat Milk | Malk | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 3897 | Oat Milk Original Shelf Stable | Chobani | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 3898 | Organic Valley Half & Half | Organic Valley | US | Dairy | M | TODO | 2026-04-07 | | |
| 3899 | Stonyfield Organic Smoothie Strawberry | Stonyfield | US | Dairy | M | TODO | 2026-04-07 | | |
| 3900 | Fage Total 0% Greek Yogurt | Fage | GR | Dairy | H | TODO | 2026-04-07 | | |
| 3901 | Fage Total 2% Greek Yogurt | Fage | GR | Dairy | H | TODO | 2026-04-07 | | |
| 3902 | Fage Total 5% Greek Yogurt | Fage | GR | Dairy | M | TODO | 2026-04-07 | | |
| 3903 | Fage TruBlend Strawberry | Fage | GR | Dairy | M | TODO | 2026-04-07 | | |
| 3904 | Icelandic Provisions Vanilla Skyr | Icelandic Provisions | IS | Dairy | M | TODO | 2026-04-07 | | |
| 3905 | Icelandic Provisions Strawberry Skyr | Icelandic Provisions | IS | Dairy | M | TODO | 2026-04-07 | | |
| 3906 | Icelandic Provisions Plain Skyr | Icelandic Provisions | IS | Dairy | M | TODO | 2026-04-07 | | |
| 3907 | Peak Triple Cream Yogurt Vanilla | Peak | US | Dairy | L | TODO | 2026-04-07 | | |
| 3908 | Ellenos Real Greek Yogurt Lemon Curd | Ellenos | US | Dairy | L | TODO | 2026-04-07 | | |
| 3909 | Liberté Classique Vanilla | Liberté | CA | Dairy | L | TODO | 2026-04-07 | | |
| 3910 | Astro Original Vanilla | Astro | CA | Dairy | L | TODO | 2026-04-07 | | |

## Section 120: McDonald's Complete Menu (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 3911 | McDonald's Double Quarter Pounder | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3912 | McDonald's 10pc Chicken McNuggets | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3913 | McDonald's 20pc Chicken McNuggets | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3914 | McDonald's Crispy Chicken Sandwich | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3915 | McDonald's Spicy Crispy Chicken Sandwich | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3916 | McDonald's Sausage McGriddle | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3917 | McDonald's Bacon Egg Cheese McGriddle | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3918 | McDonald's Fruit & Maple Oatmeal | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3919 | McDonald's Small Fries | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3920 | McDonald's Medium Fries | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3921 | McDonald's Large Fries | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3922 | McDonald's Hot Fudge Sundae | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3923 | McDonald's Happy Meal Nuggets 4pc | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3924 | McDonald's Apple Slices | McDonald's | US | fast_food | L | TODO | 2026-04-07 | |  |

## Section 121: Wendy's Complete (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 3925 | Wendy's Son of Baconator | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3926 | Wendy's 10pc Nuggets | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3927 | Wendy's Chili Small | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3928 | Wendy's Chili Large | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3929 | Wendy's Small Fries | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3930 | Wendy's Medium Fries | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3931 | Wendy's Frosty Chocolate Medium | Wendy's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3932 | Wendy's Frosty Vanilla Medium | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3933 | Wendy's Pretzel Pub Bacon Cheeseburger | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 122: Taco Bell Complete (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 3934 | Taco Bell Chips and Nacho Cheese | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3935 | Taco Bell Baja Blast Medium | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3936 | Taco Bell Baja Blast Freeze | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 123: Burger King Complete (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 3937 | Burger King Whopper Jr | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3938 | Burger King Ch'King Original | Burger King | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3939 | Burger King Ch'King Spicy | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3940 | Burger King Bacon King | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3941 | Burger King Chicken Fries | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3942 | Burger King Mozzarella Sticks 4pc | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3943 | Burger King Croissan'wich Sausage Egg Cheese | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 124: Chick-fil-A Complete (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 3944 | Chick-fil-A Deluxe Chicken Sandwich | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3945 | Chick-fil-A 8ct Nuggets | Chick-fil-A | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3946 | Chick-fil-A 12ct Nuggets | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3947 | Chick-fil-A Chick-n-Strips 3ct | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3948 | Chick-fil-A Cool Wrap | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3949 | Chick-fil-A Mac & Cheese | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3950 | Chick-fil-A Milkshake Cookies & Cream | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3951 | Chick-fil-A Chocolate Chunk Cookie | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3952 | Chick-fil-A Lemonade Medium | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 125: More US Fast Food Chains Complete (180 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 3953 | Chipotle Chips and Queso | Chipotle | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3954 | Chipotle Kids Build Your Own | Chipotle | US | fast_food | L | TODO | 2026-04-07 | |  |
| 3955 | Subway 6-inch Turkey Breast | Subway | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3956 | Subway 6-inch Italian BMT | Subway | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3957 | Subway 6-inch Meatball Marinara | Subway | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3958 | Subway 6-inch Chicken Teriyaki | Subway | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3959 | Subway 6-inch Tuna | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3960 | Subway 6-inch Steak and Cheese | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3961 | Subway 6-inch Veggie Delite | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3962 | Subway 6-inch Spicy Italian | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3963 | Subway 6-inch Cold Cut Combo | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3964 | Subway Footlong Turkey Breast | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3965 | Subway Footlong Chicken Teriyaki | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3966 | Subway Breakfast Egg and Cheese 6-inch | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3967 | Subway Breakfast Bacon Egg Cheese 6-inch | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3968 | Subway Apple Slices Side | Subway | US | fast_food | L | TODO | 2026-04-07 | |  |
| 3969 | Subway Chips Side | Subway | US | fast_food | L | TODO | 2026-04-07 | |  |
| 3970 | Domino's Hand Tossed Pepperoni Slice | Domino's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3971 | Domino's Thin Crust Pepperoni Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3972 | Domino's Brooklyn Style Cheese Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3973 | Domino's ExtravaganZZa Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3974 | Domino's MeatZZa Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3975 | Domino's Pacific Veggie Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3976 | Domino's Parmesan Bread Bites | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3977 | Domino's Boneless Chicken 8pc | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3978 | Domino's Hot Buffalo Wings 8pc | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3979 | Domino's Chicken Parm Sandwich | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3980 | Domino's Philly Cheese Steak Sandwich | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3981 | Domino's Lava Crunch Cake | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3982 | Pizza Hut Hand-Tossed Pepperoni Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3983 | Pizza Hut Thin Crust Supreme Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3984 | Pizza Hut Meat Lover's Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3985 | Pizza Hut Veggie Lover's Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3986 | Pizza Hut Detroit-Style Cheese Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3987 | Pizza Hut Detroit-Style Pepperoni Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3988 | Pizza Hut Breadsticks 5pc | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3989 | Pizza Hut Cheese Sticks 5pc | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3990 | Pizza Hut WingStreet Traditional Wings 8pc | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3991 | Pizza Hut WingStreet Boneless Wings 8pc | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3992 | Pizza Hut Personal Pan Cheese | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3993 | Pizza Hut Hershey Triple Chocolate Brownie | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3994 | Popeyes 2pc Chicken Breast and Thigh | Popeyes | US | fast_food | H | TODO | 2026-04-07 | |  |
| 3995 | Popeyes Butterfly Shrimp | Popeyes | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3996 | Popeyes Mac & Cheese | Popeyes | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3997 | Arby's Classic Crispy Chicken | Arby's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3998 | Arby's Buffalo Chicken Slider | Arby's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 3999 | Arby's Curly Fries Small | Arby's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4000 | Arby's Market Fresh Turkey & Swiss Wrap | Arby's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4001 | Sonic SuperSONIC Double Cheeseburger | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4002 | Sonic Popcorn Chicken | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4003 | Sonic Cherry Limeade Medium | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4004 | Sonic Oreo Blast | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4005 | Sonic Reese's Blast | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4006 | Sonic Wacky Pack Kids Meal | Sonic | US | fast_food | L | TODO | 2026-04-07 | |  |
| 4007 | Jack in the Box Ultimate Cheeseburger | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4008 | Jack in the Box 2 Tacos | Jack in the Box | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4009 | Jack in the Box Tiny Tacos 15pc | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4010 | Jack in the Box Curly Fries Small | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4011 | Jack in the Box Egg Rolls 3pc | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4012 | Jack in the Box Mini Churros 5pc | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4013 | Jack in the Box Oreo Shake Medium | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4014 | Whataburger Breakfast on a Bun Sausage | Whataburger | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4015 | Whataburger Spicy Ketchup Packet | Whataburger | US | fast_food | L | TODO | 2026-04-07 | |  |
| 4016 | Culver's ButterBurger The Original Single | Culver's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4017 | Culver's Crinkle Cut Fries Regular | Culver's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4018 | Culver's Concrete Mixer Oreo | Culver's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4019 | Culver's Concrete Mixer Reese's | Culver's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4020 | Culver's Wisconsin Cheese Soup | Culver's | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 126: Casual Dining Chains Complete (140 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4021 | Olive Garden House Salad | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4022 | Olive Garden Chicken Marsala | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4023 | Olive Garden Eggplant Parmigiana | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4024 | Olive Garden Five Cheese Ziti | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4025 | Olive Garden Chocolate Brownie Lasagna | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4026 | Applebee's Boneless Wings Classic Buffalo | Applebee's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4027 | Applebee's Riblet Platter | Applebee's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4028 | Applebee's Mozzarella Sticks | Applebee's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4029 | Applebee's Blue Ribbon Brownie | Applebee's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4030 | Chili's Baby Back Ribs Full Rack | Chili's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4031 | Chili's Chicken Crispers | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4032 | Chili's Oldtimer Burger | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4033 | Chili's Big Mouth Crispy Chicken Sandwich | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4034 | Chili's Texas Cheese Fries | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4035 | Chili's Presidente Margarita | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4036 | Texas Roadhouse 6oz Sirloin | Texas Roadhouse | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4037 | Texas Roadhouse 8oz Sirloin | Texas Roadhouse | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4038 | Texas Roadhouse 12oz Ribeye | Texas Roadhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4039 | Texas Roadhouse Fall Off The Bone Ribs Full | Texas Roadhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4040 | Texas Roadhouse Rolls with Cinnamon Butter | Texas Roadhouse | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4041 | Texas Roadhouse Grilled Shrimp | Texas Roadhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4042 | Red Lobster Sailor's Platter | Red Lobster | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4043 | Outback Steakhouse New York Strip 12oz | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4044 | Outback Steakhouse Victoria's Filet 9oz | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4045 | Outback Steakhouse Outback Special Sirloin 9oz | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4046 | Outback Steakhouse Grilled Chicken on the Barbie | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4047 | Outback Steakhouse Aussie Cheese Fries | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4048 | Outback Steakhouse Chocolate Thunder From Down Under | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4049 | Outback Steakhouse Crispy Shrimp | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4050 | The Cheesecake Factory Avocado Egg Rolls | The Cheesecake Factory | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4051 | The Cheesecake Factory Glamburger | The Cheesecake Factory | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4052 | The Cheesecake Factory Factory Nachos | The Cheesecake Factory | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4053 | The Cheesecake Factory Fresh Strawberry Cheesecake Slice | The Cheesecake Factory | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4054 | The Cheesecake Factory SkinnyLicious Chicken | The Cheesecake Factory | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4055 | Cracker Barrel Fried Okra Side | Cracker Barrel | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4056 | Cracker Barrel Corn Muffin | Cracker Barrel | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4057 | Cracker Barrel Coca-Cola Cake | Cracker Barrel | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4058 | IHOP Original Buttermilk Pancakes Stack | IHOP | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4059 | IHOP Crepes with Nutella | IHOP | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4060 | IHOP 2x2x2 (eggs pancakes choice) | IHOP | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4061 | IHOP Funny Face Pancake Kids | IHOP | US | fast_food | L | TODO | 2026-04-07 | |  |
| 4062 | Denny's Build Your Own Burger | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4063 | Denny's Belgian Waffle Slam | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4064 | Denny's Fit Fare Veggie Skillet | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4065 | Denny's Loaded Nacho Tots | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4066 | Denny's Vanilla Milkshake | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4067 | Buffalo Wild Wings Traditional Wings 10pc Parmesan Garlic | Buffalo Wild Wings | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4068 | Buffalo Wild Wings Traditional Wings 10pc Medium | Buffalo Wild Wings | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4069 | Buffalo Wild Wings Traditional Wings 10pc Mango Habanero | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4070 | Buffalo Wild Wings Traditional Wings 10pc Asian Zing | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4071 | Buffalo Wild Wings Traditional Wings 10pc Blazin | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4072 | Buffalo Wild Wings Boneless Wings 10pc | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4073 | Buffalo Wild Wings Soft Pretzel | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4074 | Buffalo Wild Wings Chocolate Fudge Cake | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4075 | P.F. Chang's Chang's Chicken Lettuce Wraps | P.F. Chang's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4076 | P.F. Chang's Orange Peel Chicken | P.F. Chang's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4077 | P.F. Chang's Dan Dan Noodles | P.F. Chang's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4078 | P.F. Chang's Great Wall of Chocolate Cake | P.F. Chang's | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 127: Coffee Shop Food & Dessert Chains (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4079 | Starbucks Bacon Gouda Egg Bites 2pc | Starbucks | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4080 | Starbucks Spinach Feta Wrap | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4081 | Starbucks Chicken Bacon Panini | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4082 | Starbucks Protein Box Cheese Fruit | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4083 | Starbucks Protein Box Eggs Cheddar | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4084 | Starbucks Banana Nut Bread | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4085 | Starbucks Lemon Loaf | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4086 | Starbucks Pumpkin Bread | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4087 | Starbucks Chocolate Cake Pop | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4088 | Starbucks Double Chocolate Brownie | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4089 | Starbucks Cheese Danish | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4090 | Starbucks Petite Vanilla Scone | Starbucks | US | fast_food | L | TODO | 2026-04-07 | |  |
| 4091 | Baskin-Robbins Jamoca Almond Fudge Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 4092 | Baskin-Robbins Mint Chocolate Chip Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 4093 | Baskin-Robbins Pralines n Cream Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 4094 | Baskin-Robbins Gold Medal Ribbon Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 4095 | Baskin-Robbins Rainbow Sherbet Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 4096 | Cold Stone Creamery Birthday Cake Remix Love It | Cold Stone | US | dessert | M | TODO | 2026-04-07 | |  |
| 4097 | Cold Stone Creamery Peanut Butter Cup Perfection | Cold Stone | US | dessert | M | TODO | 2026-04-07 | |  |
| 4098 | Cold Stone Creamery Founder's Favorite | Cold Stone | US | dessert | M | TODO | 2026-04-07 | |  |
| 4099 | Dairy Queen Oreo Blizzard Medium | Dairy Queen | US | dessert | H | TODO | 2026-04-07 | |  |
| 4100 | Dairy Queen Reese's Blizzard Medium | Dairy Queen | US | dessert | H | TODO | 2026-04-07 | |  |
| 4101 | Dairy Queen Cookie Dough Blizzard Medium | Dairy Queen | US | dessert | M | TODO | 2026-04-07 | |  |
| 4102 | Dairy Queen M&M Blizzard Medium | Dairy Queen | US | dessert | M | TODO | 2026-04-07 | |  |
| 4103 | Dairy Queen Banana Split | Dairy Queen | US | dessert | M | TODO | 2026-04-07 | |  |
| 4104 | Crumbl Cookie Pink Sugar | Crumbl | US | dessert | H | TODO | 2026-04-07 | |  |
| 4105 | Crumbl Cookie Chocolate Chip | Crumbl | US | dessert | H | TODO | 2026-04-07 | |  |
| 4106 | Crumbl Cookie Biscoff Lava | Crumbl | US | dessert | M | TODO | 2026-04-07 | |  |
| 4107 | Crumbl Cookie Churro | Crumbl | US | dessert | M | TODO | 2026-04-07 | |  |
| 4108 | Crumbl Cookie Snickerdoodle | Crumbl | US | dessert | M | TODO | 2026-04-07 | |  |
| 4109 | Insomnia Cookies Classic Chocolate Chunk | Insomnia | US | dessert | M | TODO | 2026-04-07 | |  |
| 4110 | Insomnia Cookies S'mores | Insomnia | US | dessert | M | TODO | 2026-04-07 | |  |
| 4111 | Krispy Kreme Chocolate Iced Custard Filled | Krispy Kreme | US | dessert | M | TODO | 2026-04-07 | |  |
| 4112 | Krispy Kreme Apple Fritter | Krispy Kreme | US | dessert | M | TODO | 2026-04-07 | |  |

## Section 128: Alcohol - Beer, Wine & Cocktails (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4113 | Miller Lite (per 12oz) | Miller | US | beverage | H | TODO | 2026-04-07 | |  |
| 4114 | Coors Light (per 12oz) | Coors | US | beverage | H | TODO | 2026-04-07 | |  |
| 4115 | Modelo Negra (per 12oz) | Modelo | MX | beverage | M | TODO | 2026-04-07 | |  |
| 4116 | Heineken (per 12oz) | Heineken | NL | beverage | H | TODO | 2026-04-07 | |  |
| 4117 | Stella Artois (per 11.2oz) | Stella | BE | beverage | M | TODO | 2026-04-07 | |  |
| 4118 | PBR Pabst Blue Ribbon (per 12oz) | PBR | US | beverage | M | TODO | 2026-04-07 | |  |
| 4119 | Yuengling Traditional Lager (per 12oz) | Yuengling | US | beverage | M | TODO | 2026-04-07 | |  |
| 4120 | Natural Light (per 12oz) | Natural Light | US | beverage | M | TODO | 2026-04-07 | |  |
| 4121 | Blue Moon Belgian White (per 12oz) | Blue Moon | US | beverage | M | TODO | 2026-04-07 | |  |
| 4122 | Sam Adams Boston Lager (per 12oz) | Sam Adams | US | beverage | M | TODO | 2026-04-07 | |  |
| 4123 | Sierra Nevada Pale Ale (per 12oz) | Sierra Nevada | US | beverage | M | TODO | 2026-04-07 | |  |
| 4124 | Lagunitas IPA (per 12oz) | Lagunitas | US | beverage | M | TODO | 2026-04-07 | |  |
| 4125 | Craft IPA Generic (per 16oz pint) | Various | US | beverage | H | TODO | 2026-04-07 | |  |
| 4126 | Craft Hazy IPA Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4127 | Craft Double IPA Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4128 | Craft Stout Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4129 | Craft Wheat Beer Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4130 | Craft Sour/Gose Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4131 | Truly Wild Berry (per 12oz) | Truly | US | beverage | M | TODO | 2026-04-07 | |  |
| 4132 | Truly Pineapple (per 12oz) | Truly | US | beverage | M | TODO | 2026-04-07 | |  |
| 4133 | High Noon Peach Vodka Soda (per 12oz) | High Noon | US | beverage | H | TODO | 2026-04-07 | |  |
| 4134 | High Noon Watermelon (per 12oz) | High Noon | US | beverage | M | TODO | 2026-04-07 | |  |
| 4135 | Athletic Brewing Run Wild IPA Non-Alc (per 12oz) | Athletic | US | beverage | M | TODO | 2026-04-07 | | Non-alcoholic |
| 4136 | Athletic Brewing Free Wave Hazy IPA Non-Alc (per 12oz) | Athletic | US | beverage | M | TODO | 2026-04-07 | | Non-alcoholic |
| 4137 | Red Wine Cabernet Sauvignon (per 5oz glass) | Various | US | beverage | H | TODO | 2026-04-07 | |  |
| 4138 | Red Wine Merlot (per 5oz glass) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4139 | Red Wine Pinot Noir (per 5oz glass) | Various | US | beverage | H | TODO | 2026-04-07 | |  |
| 4140 | Red Wine Malbec (per 5oz glass) | Various | AR | beverage | M | TODO | 2026-04-07 | |  |
| 4141 | Red Wine Zinfandel (per 5oz glass) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4142 | Moscato (per 5oz glass) | Various | IT | beverage | M | TODO | 2026-04-07 | |  |
| 4143 | Margarita Classic (per cocktail) | Various | MX | beverage | H | TODO | 2026-04-07 | |  |
| 4144 | Martini Gin (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4145 | Martini Vodka (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4146 | Espresso Martini (per cocktail) | Various | IT | beverage | H | TODO | 2026-04-07 | |  |
| 4147 | Bloody Mary (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4148 | Tom Collins (per cocktail) | Various | GB | beverage | M | TODO | 2026-04-07 | |  |
| 4149 | Gin and Tonic (per cocktail) | Various | GB | beverage | H | TODO | 2026-04-07 | |  |
| 4150 | Vodka Soda (per cocktail) | Various | US | beverage | H | TODO | 2026-04-07 | | Low cal |
| 4151 | Tequila Sunrise (per cocktail) | Various | MX | beverage | M | TODO | 2026-04-07 | |  |
| 4152 | Dark 'n Stormy (per cocktail) | Various | BM | beverage | M | TODO | 2026-04-07 | |  |
| 4153 | Sangria Red (per glass) | Various | ES | beverage | M | TODO | 2026-04-07 | |  |
| 4154 | Hot Toddy (per cocktail) | Various | GB | beverage | M | TODO | 2026-04-07 | |  |
| 4155 | Frozen Margarita (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4156 | Frozen Daiquiri Strawberry (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4157 | Jägerbomb (per shot+mixer) | Various | DE | beverage | M | TODO | 2026-04-07 | |  |
| 4158 | Lemon Drop Shot | Various | US | beverage | L | TODO | 2026-04-07 | |  |
| 4159 | Vodka Shot (per 1.5oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4160 | Tequila Shot (per 1.5oz) | Various | MX | beverage | M | TODO | 2026-04-07 | |  |
| 4161 | Whiskey Shot (per 1.5oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4162 | Sake Cup (per 6oz) | Various | JP | beverage | M | TODO | 2026-04-07 | |  |

## Section 129: Street Food & Cuisine Expansion - 30+ Countries (200 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4163 | Kebab Koobideh (per 2 skewers) | Various | IR | street_food | H | TODO | 2026-04-07 | |  |
| 4164 | Ghormeh Sabzi (per serving) | Various | IR | street_food | H | TODO | 2026-04-07 | |  |
| 4165 | Zereshk Polo ba Morgh (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 4166 | Tahdig Crispy Rice (per serving) | Various | IR | street_food | H | TODO | 2026-04-07 | |  |
| 4167 | Fesenjan Pomegranate Walnut Stew (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 4168 | Ash Reshteh Noodle Soup (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 4169 | Saffron Ice Cream Bastani (per scoop) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 4170 | Faloodeh Frozen Dessert (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 4171 | Joojeh Kabab Chicken Skewer (per 2) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 4172 | Khoresh Bademjan Eggplant Stew (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 4173 | Sabzi Khordan Herb Plate (per serving) | Various | IR | street_food | L | TODO | 2026-04-07 | |  |
| 4174 | Kashk-e Bademjan Eggplant Dip (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 4175 | Mirza Ghasemi Smoked Eggplant (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 4176 | Masgouf Iraqi Grilled Fish (per serving) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 4177 | Iraqi Dolma Stuffed Vegetables (per 3) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 4178 | Kubba Mosul Fried Meat Ball (per 2) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 4179 | Iraqi Biryani (per serving) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 4180 | Tashreeb Bread Stew (per serving) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 4181 | Kabsa Saudi Rice Chicken (per serving) | Various | SA | street_food | H | TODO | 2026-04-07 | |  |
| 4182 | Mandi Slow Cooked Lamb (per serving) | Various | SA | street_food | H | TODO | 2026-04-07 | |  |
| 4183 | Jareesh Crushed Wheat (per serving) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 4184 | Harees Porridge (per serving) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 4185 | Saleeg White Rice Chicken (per serving) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 4186 | Mutabbaq Stuffed Pancake (per piece) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 4187 | Saudi Shawarma (per wrap) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 4188 | Sambousek Fried Pastry (per 3) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 4189 | Saudi Dates Stuffed Almond (per 3) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 4190 | Mansaf Jordanian Lamb Rice (per serving) | Various | JO | street_food | H | TODO | 2026-04-07 | |  |
| 4191 | Jordanian Falafel in Pita | Various | JO | street_food | M | TODO | 2026-04-07 | |  |
| 4192 | Knafeh Nabulsi Cheese Pastry (per piece) | Various | JO | street_food | M | TODO | 2026-04-07 | |  |
| 4193 | Maqluba Upside Down Rice (per serving) | Various | JO | street_food | M | TODO | 2026-04-07 | |  |
| 4194 | Jordanian Jameed Sauce (per tbsp) | Various | JO | street_food | L | TODO | 2026-04-07 | |  |
| 4195 | Fahsa Shredded Meat (per serving) | Various | YE | street_food | M | TODO | 2026-04-07 | |  |
| 4196 | Bint al Sahn Honey Cake (per slice) | Various | YE | street_food | M | TODO | 2026-04-07 | |  |
| 4197 | Uzbek Plov Rice Pilaf (per serving) | Various | UZ | street_food | H | TODO | 2026-04-07 | |  |
| 4198 | Uzbek Halva (per piece) | Various | UZ | street_food | M | TODO | 2026-04-07 | |  |
| 4199 | Non Uzbek Bread (per piece) | Various | UZ | street_food | M | TODO | 2026-04-07 | |  |
| 4200 | Naryn Cold Noodle Horse Meat (per serving) | Various | UZ | street_food | L | TODO | 2026-04-07 | |  |
| 4201 | Kumys Fermented Mare Milk (per cup) | Various | KZ | street_food | M | TODO | 2026-04-07 | |  |
| 4202 | Baursak Fried Dough (per 3) | Various | KZ | street_food | M | TODO | 2026-04-07 | |  |
| 4203 | Shubat Camel Milk (per cup) | Various | KZ | street_food | L | TODO | 2026-04-07 | |  |
| 4204 | Adjarian Khachapuri Boat (per piece) | Various | GE | street_food | H | TODO | 2026-04-07 | |  |
| 4205 | Imeruli Khachapuri Round (per piece) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 4206 | Khinkali Soup Dumpling (per 5) | Various | GE | street_food | H | TODO | 2026-04-07 | |  |
| 4207 | Churchkhela Grape Walnut (per piece) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 4208 | Mtsvadi Grilled Meat (per skewer) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 4209 | Badrijani Walnut Stuffed Eggplant (per 2) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 4210 | Pkhali Spinach Walnut (per serving) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 4211 | Armenian Khorovats BBQ (per serving) | Various | AM | street_food | H | TODO | 2026-04-07 | |  |
| 4212 | Armenian Dolma Grape Leaf (per 3) | Various | AM | street_food | M | TODO | 2026-04-07 | |  |
| 4213 | Ghapama Stuffed Pumpkin (per serving) | Various | AM | street_food | M | TODO | 2026-04-07 | |  |
| 4214 | Basturma Cured Beef (per 30g) | Various | AM | street_food | M | TODO | 2026-04-07 | |  |
| 4215 | Sujuk Armenian Sausage (per 30g) | Various | AM | street_food | M | TODO | 2026-04-07 | |  |
| 4216 | Mici Romanian Grilled Rolls (per 3) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 4217 | Sarmale Cabbage Rolls (per 3) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 4218 | Mamaliga Polenta (per serving) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 4219 | Cozonac Sweet Bread (per slice) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 4220 | Papanasi Donut Dumplings (per 2) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 4221 | Banitsa Cheese Pastry (per piece) | Various | BG | street_food | M | TODO | 2026-04-07 | |  |
| 4222 | Kebapche Grilled Meat Roll (per 2) | Various | BG | street_food | M | TODO | 2026-04-07 | |  |
| 4223 | Lyutenitsa Pepper Relish (per tbsp) | Various | BG | street_food | M | TODO | 2026-04-07 | |  |
| 4224 | Tarator Cold Soup (per serving) | Various | BG | street_food | M | TODO | 2026-04-07 | |  |
| 4225 | Cevapi Croatian (per 5 pieces) | Various | HR | street_food | M | TODO | 2026-04-07 | |  |
| 4226 | Burek Croatian Meat Pie (per piece) | Various | HR | street_food | M | TODO | 2026-04-07 | |  |
| 4227 | Strukli Cheese Rolls (per 2) | Various | HR | street_food | M | TODO | 2026-04-07 | |  |
| 4228 | Pag Cheese (per 30g) | Various | HR | street_food | M | TODO | 2026-04-07 | |  |
| 4229 | Ajvar Red Pepper Relish (per tbsp) | Various | RS | street_food | M | TODO | 2026-04-07 | |  |
| 4230 | Knedle Plum Dumplings (per 3) | Various | RS | street_food | M | TODO | 2026-04-07 | |  |
| 4231 | Vaca Frita Crispy Beef (per serving) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 4232 | Yuca Frita Fried Cassava (per serving) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 4233 | Cafecito Cuban Coffee (per shot) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 4234 | Batido de Mamey Shake (per glass) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 4235 | Picadillo Cuban Ground Beef (per serving) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 4236 | Flan Cubano (per slice) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 4237 | Mofongo Garlic Plantain (per serving) | Various | PR | street_food | H | TODO | 2026-04-07 | |  |
| 4238 | Pernil Roasted Pork (per serving) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 4239 | Pastelón Plantain Lasagna (per serving) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 4240 | Tembleque Coconut Pudding (per serving) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 4241 | Coquito Coconut Eggnog (per cup) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 4242 | Tostones con Mojito (per serving) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 4243 | Alcapurrias Fritters (per 2) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 4244 | Festival Fried Dumpling (per 2) | Various | JM | street_food | M | TODO | 2026-04-07 | |  |
| 4245 | Bammy Cassava Bread (per piece) | Various | JM | street_food | M | TODO | 2026-04-07 | |  |
| 4246 | Trinidadian Roti Wrap (per piece) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 4247 | Pelau Rice Meat (per serving) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 4248 | Pholourie Fried Balls (per 5) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 4249 | Kurma Sweet Snack (per piece) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 4250 | Sancocho Dominican Stew (per serving) | Various | DO | street_food | M | TODO | 2026-04-07 | |  |
| 4251 | Chimichurri Burger Dominican (per piece) | Various | DO | street_food | M | TODO | 2026-04-07 | |  |
| 4252 | Morir Sonando Orange Milk Drink (per glass) | Various | DO | street_food | M | TODO | 2026-04-07 | |  |
| 4253 | Diri Djon Djon Black Rice (per serving) | Various | HT | street_food | M | TODO | 2026-04-07 | |  |
| 4254 | Soup Joumou Pumpkin Soup (per serving) | Various | HT | street_food | M | TODO | 2026-04-07 | |  |
| 4255 | Borscht Ukrainian (per serving) | Various | UA | street_food | H | TODO | 2026-04-07 | |  |
| 4256 | Varenyky Ukrainian Dumplings (per 5) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |
| 4257 | Deruny Potato Pancakes (per 3) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |
| 4258 | Holubtsi Stuffed Cabbage Rolls (per 2) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |
| 4259 | Pampushky Garlic Bread (per 2) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |
| 4260 | Chicken Kyiv (per piece) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |

## Section 130: Gas Station, Vending, School & Airport (45 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4261 | 7-Eleven Slurpee Cherry Medium | 7-Eleven | US | beverage | M | TODO | 2026-04-07 | |  |
| 4262 | 7-Eleven Taquito Chicken Cheese | 7-Eleven | US | snack | M | TODO | 2026-04-07 | |  |
| 4263 | 7-Eleven Pizza Slice Pepperoni | 7-Eleven | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4264 | Wawa Classic Italian Hoagie | Wawa | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4265 | Wawa Sizzli Sausage Egg Cheese | Wawa | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4266 | Sheetz MTO Sub Italian | Sheetz | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4267 | QuikTrip QT Kitchen Pizza Slice | QuikTrip | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4268 | QuikTrip QT Kitchen Taquito | QuikTrip | US | snack | M | TODO | 2026-04-07 | |  |
| 4269 | Vending Machine Doritos Small Bag | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 4270 | Vending Machine Lay's Small Bag | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 4271 | Vending Machine Nature Valley Bar | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 4272 | Vending Machine Honey Bun | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 4273 | Vending Machine Grandma's Cookies | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 4274 | Vending Machine Famous Amos Cookies | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 4275 | Vending Machine Pop-Tarts | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 4276 | Vending Machine Coke 20oz Bottle | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4277 | Vending Machine Gatorade 20oz | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4278 | School Cafeteria Rectangle Pizza | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4279 | School Cafeteria Corn Dog | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4280 | School Cafeteria Fish Sticks 3pc | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4281 | School Cafeteria Tater Tots | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4282 | School Cafeteria Chocolate Milk Carton | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 4283 | Airport Terminal Grab-and-Go Sandwich | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4284 | Airport Terminal Fruit and Cheese Box | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 4285 | Airport Terminal Hummus and Veggies Box | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 4286 | Airline Economy Chicken Meal | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4287 | Airline Economy Pasta Meal | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4288 | Airline Pretzel Snack Pack | Various | US | snack | L | TODO | 2026-04-07 | |  |
| 4289 | Airline Biscoff Cookie Pack | Various | US | snack | L | TODO | 2026-04-07 | |  |

## Section 131: Juice & Smoothie Chains (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4290 | Jamba Juice Caribbean Passion Medium | Jamba | US | beverage | M | TODO | 2026-04-07 | |  |
| 4291 | Jamba Juice Acai Primo Bowl | Jamba | US | breakfast | M | TODO | 2026-04-07 | |  |
| 4292 | Jamba Juice Greens n Ginger Medium | Jamba | US | beverage | M | TODO | 2026-04-07 | |  |
| 4293 | Jamba Juice PB Galaxy Medium | Jamba | US | beverage | M | TODO | 2026-04-07 | |  |
| 4294 | Jamba Juice Orange Dream Machine Medium | Jamba | US | beverage | M | TODO | 2026-04-07 | |  |
| 4295 | Smoothie King The Activator Strawberry Banana | Smoothie King | US | beverage | M | TODO | 2026-04-07 | |  |
| 4296 | Smoothie King Slim-N-Trim Strawberry | Smoothie King | US | beverage | M | TODO | 2026-04-07 | |  |
| 4297 | Tropical Smoothie Sunrise Sunset | Tropical Smoothie | US | beverage | M | TODO | 2026-04-07 | |  |
| 4298 | Tropical Smoothie Peanut Paradise | Tropical Smoothie | US | beverage | M | TODO | 2026-04-07 | |  |
| 4299 | Nekter Juice Bar Pitaya Bowl | Nekter | US | breakfast | M | TODO | 2026-04-07 | |  |
| 4300 | Pressed Juicery Greens 3 | Pressed Juicery | US | beverage | M | TODO | 2026-04-07 | |  |
| 4301 | Pressed Juicery Freeze Chocolate | Pressed Juicery | US | dessert | M | TODO | 2026-04-07 | |  |
| 4302 | Clean Juice The One Smoothie | Clean Juice | US | beverage | M | TODO | 2026-04-07 | |  |

## Section 132: Sandwich & Sub Chains (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4303 | Jersey Mike's #13 The Original Italian Regular | Jersey Mike's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 4304 | Jersey Mike's #7 Turkey & Provolone Regular | Jersey Mike's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4305 | Jersey Mike's #56 Big Kahuna Cheesesteak Regular | Jersey Mike's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4306 | Jersey Mike's #9 Club Sub Regular | Jersey Mike's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4307 | Jimmy John's #1 Pepe | Jimmy John's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4308 | Jimmy John's #4 Turkey Tom | Jimmy John's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4309 | Jimmy John's #9 Italian Night Club | Jimmy John's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4310 | Jimmy John's Beach Club | Jimmy John's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4311 | Firehouse Subs Hook & Ladder Medium | Firehouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4312 | Firehouse Subs Smokehouse Beef & Cheddar Medium | Firehouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4313 | Potbelly A Wreck Sandwich Original | Potbelly | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4314 | Potbelly Turkey Breast Sandwich Original | Potbelly | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4315 | Schlotzsky's The Original Sandwich Small | Schlotzsky's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4316 | Which Wich Wicked Sandwich | Which Wich | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4317 | Panera Bread Bowl Broccoli Cheddar | Panera | US | fast_food | H | TODO | 2026-04-07 | |  |

## Section 133: Salad & Bowl Chains (10 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4318 | Just Salad Chicken Caesar | Just Salad | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4319 | CoreLife Chicken Power Bowl | CoreLife | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 134: Breakfast Chains (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4320 | First Watch Power Breakfast Quinoa Bowl | First Watch | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4321 | First Watch Elevated Egg Sandwich | First Watch | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4322 | First Watch Kale Tonic Juice | First Watch | US | beverage | M | TODO | 2026-04-07 | |  |
| 4323 | Snooze Pineapple Upside Down Pancakes | Snooze | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4324 | Snooze Breakfast Pot Pie | Snooze | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4325 | Original Pancake House Dutch Baby | OPH | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4326 | Original Pancake House Apple Pancake | OPH | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4327 | Bob Evans Farmhouse Feast | Bob Evans | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4328 | Perkins Tremendous Twelve Breakfast | Perkins | US | fast_food | M | TODO | 2026-04-07 | |  |
| 4329 | Village Inn Pie (per slice) | Village Inn | US | dessert | M | TODO | 2026-04-07 | |  |
## Section 135: Trader Joe's & Costco Complete (85 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4330 | TJ's Gone Bananas Frozen (per 5) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4331 | TJ's Spatchcocked Chicken (per 100g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4332 | TJ's Soy Chorizo (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4333 | TJ's Hashbrowns Frozen (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4334 | TJ's Cowboy Bark (per 30g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4335 | TJ's Triple Ginger Snaps (per 4) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4336 | TJ's Bambas Peanut Snacks (per 100g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4337 | TJ's Cruciferous Crunch (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4338 | TJ's Umami Seasoning (per tsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4339 | TJ's Chile Lime Seasoning (per tsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4340 | TJ's 21 Salute Seasoning (per tsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4341 | TJ's Ube Mochi Pancake Mix (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4342 | TJ's Ube Ice Cream (per 100ml) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4343 | TJ's Magnifisauce (per tbsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4344 | TJ's Bomba Sauce (per tbsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4345 | TJ's Joe-Joe's Chocolate Cream (per 3) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4346 | TJ's Chocolate Lava Cake (per cake) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4347 | TJ's Mango Cream Bars (per bar) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4348 | TJ's Thai Vegetable Gyoza (per 7) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4349 | TJ's Peanut Butter Filled Pretzels (per 30g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4350 | TJ's Cauliflower Pizza Crust (per crust) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4351 | TJ's Shawarma Chicken Thighs (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4352 | TJ's Reduced Guilt Mac & Cheese (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4353 | TJ's Mini Ice Cream Cones (per 4) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4354 | TJ's Hold the Cone Vanilla (per 4) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4355 | TJ's Turkey Corn Dogs (per dog) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4356 | TJ's Cauliflower Gnocchi Frozen (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4357 | TJ's Everything But The Bagel Seasoning (per tsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4358 | TJ's Elote Corn Chip Dippers (per 100g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4359 | TJ's Green Goddess Dressing (per tbsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4360 | TJ's Peanut Butter Pretzel Bites (per 30g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4361 | TJ's Sublime Ice Cream Sandwiches (per piece) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4362 | TJ's Chile Spiced Mango (per 100g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4363 | TJ's Organic Peanut Butter Creamy (per tbsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4364 | TJ's Everything Ciabatta Rolls (per roll) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4365 | TJ's Chicken Gyoza Potstickers (per 7) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4366 | TJ's Pork Gyoza (per 7) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 4367 | Costco Food Court Hot Dog & Soda | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4368 | Costco Food Court Açaí Bowl | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4369 | Costco Food Court Ice Cream Bar | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4370 | Kirkland Atlantic Salmon Fillet (per 100g) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4371 | Kirkland Chicken Breast Boneless (per 100g) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4372 | Kirkland Organic Large Eggs (per egg) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4373 | Kirkland Organic Peanut Butter (per tbsp) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4374 | Kirkland Pesto Basil (per tbsp) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4375 | Kirkland Croissants (per piece) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4376 | Kirkland Muffins Blueberry (per muffin) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4377 | Kirkland Muffins Chocolate (per muffin) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4378 | Kirkland Sheet Cake Chocolate (per slice) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4379 | Kirkland Chicken Wings Frozen (per 4 wings) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4380 | Kirkland Frozen Berries Mixed (per 100g) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 4381 | Kirkland Organic Ground Beef (per 100g) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |

## Section 136: Weight Management & Meal Kit Brands (42 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4382 | WW Smart Ones Santa Fe Rice & Beans | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4383 | WW Smart Ones Three Cheese Ziti | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4384 | WW Smart Ones Broccoli Cheddar Potatoes | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4385 | WW Snack Bar Chocolate Caramel | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4386 | WW Ice Cream Bar Chocolate Fudge | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4387 | Nutrisystem Chocolate Shake | Nutrisystem | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4388 | Nutrisystem Lunch Hamburger | Nutrisystem | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4389 | Nutrisystem Dinner Ravioli | Nutrisystem | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4390 | SlimFast Original Shake French Vanilla | SlimFast | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4391 | SlimFast Keto Shake Fudge Brownie | SlimFast | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4392 | SlimFast Snack Bar Peanut Butter Chocolate | SlimFast | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4393 | Optavia Fueling Chocolate Shake | Optavia | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4394 | Optavia Fueling Cinnamon Crunchy O's | Optavia | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4395 | Optavia Fueling Brownie | Optavia | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4396 | HelloFresh Creamy Garlic Butter Shrimp | HelloFresh | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4397 | HelloFresh BBQ Chicken | HelloFresh | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4398 | HelloFresh Steak Frites | HelloFresh | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4399 | EveryPlate Garlic Herb Chicken | EveryPlate | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4400 | Blue Apron Seared Salmon | Blue | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4401 | Blue Apron Crispy Chicken Thighs | Blue | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4402 | Home Chef Chicken Marsala | Home | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4403 | Factor Keto Chicken Thigh Meal | Factor | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4404 | Factor Steak with Vegetables | Factor | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4405 | Factor Salmon Meal | Factor | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4406 | Daily Harvest Acai Cherry Smoothie | Daily | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4407 | Daily Harvest Tomato Basil Flatbread | Daily | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4408 | Daily Harvest Chocolate Latte Smoothie | Daily | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4409 | CookUnity Chef-Made Chicken Bowl | CookUnity | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 4410 | Territory Foods Grilled Chicken Mediterranean | Territory | US | meal_kit | M | TODO | 2026-04-07 | |  |

## Section 137: Cereal Brands Complete (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4411 | Cheerios Protein (per serving) | General Mills | US | cereal | M | TODO | 2026-04-07 | |  |
| 4412 | Reese's Puffs (per serving) | General Mills | US | cereal | M | TODO | 2026-04-07 | |  |
| 4413 | Corn Pops (per serving) | Kellogg's | US | cereal | M | TODO | 2026-04-07 | |  |
| 4414 | Quaker Instant Oatmeal Apple Cinnamon (per packet) | Quaker | US | cereal | M | TODO | 2026-04-07 | |  |
| 4415 | Quaker Instant Oatmeal Peaches & Cream (per packet) | Quaker | US | cereal | M | TODO | 2026-04-07 | |  |
| 4416 | Quaker Old Fashioned Oats (per serving) | Quaker | US | cereal | H | TODO | 2026-04-07 | |  |
| 4417 | Barbara's Puffins Original (per serving) | Barbara's | US | cereal | M | TODO | 2026-04-07 | |  |
| 4418 | Bob's Red Mill Muesli (per serving) | Bob's Red Mill | US | cereal | M | TODO | 2026-04-07 | |  |
| 4419 | Kind Healthy Grains Granola (per serving) | Kind | US | cereal | M | TODO | 2026-04-07 | |  |

## Section 138: Yogurt Brands Expanded (25 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4420 | Dannon Light & Fit Greek Vanilla (per cup) | Dannon | US | dairy | M | TODO | 2026-04-07 | |  |
| 4421 | Dannon Light & Fit Greek Strawberry (per cup) | Dannon | US | dairy | M | TODO | 2026-04-07 | |  |
| 4422 | Yoplait Oui French Style Vanilla (per jar) | Yoplait | US | dairy | M | TODO | 2026-04-07 | |  |
| 4423 | Brown Cow Cream Top Vanilla (per cup) | Brown Cow | US | dairy | M | TODO | 2026-04-07 | |  |
| 4424 | Lifeway Kefir Low Fat Plain (per cup) | Lifeway | US | dairy | M | TODO | 2026-04-07 | |  |
| 4425 | Lifeway Kefir Strawberry (per cup) | Lifeway | US | dairy | M | TODO | 2026-04-07 | |  |
| 4426 | Kite Hill Almond Milk Yogurt Vanilla (per cup) | Kite Hill | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4427 | Silk Oat Milk Yogurt Strawberry (per cup) | Silk | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4428 | So Delicious Coconut Yogurt Vanilla (per cup) | So Delicious | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4429 | Forager Cashewmilk Yogurt Vanilla (per cup) | Forager | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4430 | Wallaby Organic Greek Plain (per cup) | Wallaby | US | dairy | M | TODO | 2026-04-07 | |  |
| 4431 | Maple Hill Organic Greek Plain (per cup) | Maple Hill | US | dairy | M | TODO | 2026-04-07 | |  |
| 4432 | Icelandic Provisions Skyr Vanilla (per cup) | Icelandic Provisions | IS | dairy | M | TODO | 2026-04-07 | |  |

## Section 139: Chips, Crackers & Snack Brands Complete (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4433 | Stacy's Pita Chips Simply Naked (per 1oz) | Stacy's | US | snack | M | TODO | 2026-04-07 | |  |
| 4434 | Ritz Cheese Sandwich Crackers (per 6 crackers) | Nabisco | US | snack | M | TODO | 2026-04-07 | |  |
| 4435 | Club Crackers Original (per 4 crackers) | Kellogg's | US | snack | M | TODO | 2026-04-07 | |  |
| 4436 | Good Thins Corn (per 40 crisps) | Nabisco | US | snack | M | TODO | 2026-04-07 | |  |
| 4437 | Utz Pub Mix (per 1oz) | Utz | US | snack | M | TODO | 2026-04-07 | |  |
| 4438 | Popcorners White Cheddar (per 1oz) | Popcorners | US | snack | M | TODO | 2026-04-07 | |  |
| 4439 | Hippeas Chickpea Puffs Vegan White Cheddar (per 1oz) | Hippeas | US | snack | M | TODO | 2026-04-07 | |  |
| 4440 | Beanitos Black Bean Chips (per 1oz) | Beanitos | US | snack | M | TODO | 2026-04-07 | |  |
| 4441 | Harvest Snaps Green Pea (per 1oz) | Harvest Snaps | US | snack | M | TODO | 2026-04-07 | |  |
| 4442 | Terra Vegetable Chips Original (per 1oz) | Terra | US | snack | M | TODO | 2026-04-07 | |  |
| 4443 | Boom Chicka Pop Sea Salt Popcorn (per 1oz) | Angie's | US | snack | M | TODO | 2026-04-07 | |  |
| 4444 | Garden of Eatin' Blue Corn Chips (per 1oz) | Garden of Eatin' | US | snack | M | TODO | 2026-04-07 | |  |

## Section 140: Cookie & Candy Brands Complete (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4445 | Nutter Butters (per 2 cookies) | Nabisco | US | biscuit | M | TODO | 2026-04-07 | |  |
| 4446 | Keebler Fudge Stripes (per 3 cookies) | Keebler | US | biscuit | M | TODO | 2026-04-07 | |  |
| 4447 | Keebler E.L. Fudge (per 2 cookies) | Keebler | US | biscuit | M | TODO | 2026-04-07 | |  |
| 4448 | Tate's Bake Shop Chocolate Chip (per 2) | Tate's | US | biscuit | M | TODO | 2026-04-07 | |  |
| 4449 | Snickers Original Bar | Mars | US | confectionery | H | TODO | 2026-04-07 | |  |
| 4450 | Twix Original Bar | Mars | US | confectionery | H | TODO | 2026-04-07 | |  |
| 4451 | Kit Kat Original 4-Finger | Hershey's | US | confectionery | H | TODO | 2026-04-07 | |  |
| 4452 | Mounds Bar | Hershey's | US | confectionery | M | TODO | 2026-04-07 | |  |
| 4453 | PayDay Bar | Hershey's | US | confectionery | M | TODO | 2026-04-07 | |  |
| 4454 | Starburst Original (per 2.07oz) | Mars | US | confectionery | M | TODO | 2026-04-07 | |  |
| 4455 | Twizzlers Strawberry (per 4 twists) | Hershey's | US | confectionery | M | TODO | 2026-04-07 | |  |
| 4456 | Nerds Original Box | Ferrara | US | confectionery | M | TODO | 2026-04-07 | |  |
| 4457 | Airheads Bar | Perfetti | US | confectionery | M | TODO | 2026-04-07 | |  |
| 4458 | Haribo Gold-Bears (per 1.5oz) | Haribo | US | confectionery | M | TODO | 2026-04-07 | |  |

## Section 141: Ice Cream Brands Complete (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4459 | Häagen-Dazs Vanilla (per 100ml) | Häagen-Dazs | US | dessert | H | TODO | 2026-04-07 | |  |
| 4460 | Häagen-Dazs Chocolate (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | |  |
| 4461 | Häagen-Dazs Strawberry (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | |  |
| 4462 | Häagen-Dazs Cookies & Cream (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | |  |
| 4463 | Häagen-Dazs Dulce de Leche (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | |  |
| 4464 | Turkey Hill Original Vanilla (per 100ml) | Turkey Hill | US | dessert | M | TODO | 2026-04-07 | |  |
| 4465 | Jeni's Brambleberry Crisp (per 100ml) | Jeni's | US | dessert | M | TODO | 2026-04-07 | |  |
| 4466 | Jeni's Salted Peanut Butter with Chocolate (per 100ml) | Jeni's | US | dessert | M | TODO | 2026-04-07 | |  |
| 4467 | Van Leeuwen French Vanilla (per 100ml) | Van Leeuwen | US | dessert | M | TODO | 2026-04-07 | |  |
| 4468 | Klondike Bar Original (per bar) | Klondike | US | dessert | M | TODO | 2026-04-07 | |  |
| 4469 | Drumstick Classic Vanilla (per cone) | Nestlé | US | dessert | M | TODO | 2026-04-07 | |  |
| 4470 | Good Humor Strawberry Shortcake Bar | Good Humor | US | dessert | M | TODO | 2026-04-07 | |  |
| 4471 | Fudgsicle Original (per bar) | Popsicle | US | dessert | M | TODO | 2026-04-07 | |  |
| 4472 | Creamsicle Orange (per bar) | Popsicle | US | dessert | M | TODO | 2026-04-07 | |  |
| 4473 | Edy's/Dreyer's Vanilla (per 100ml) | Edy's | US | dessert | M | TODO | 2026-04-07 | |  |
| 4474 | Blue Bunny Bunny Tracks (per 100ml) | Blue Bunny | US | dessert | M | TODO | 2026-04-07 | |  |
| 4475 | Friendly's Forbidden Chocolate (per 100ml) | Friendly's | US | dessert | M | TODO | 2026-04-07 | |  |

## Section 142: Beverage Brands - Juice, Tea, Water (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4476 | Naked Juice Green Machine (per 15.2oz) | Naked | US | beverage | M | TODO | 2026-04-07 | |  |
| 4477 | Naked Juice Mighty Mango (per 15.2oz) | Naked | US | beverage | M | TODO | 2026-04-07 | |  |
| 4478 | Naked Juice Blue Machine (per 15.2oz) | Naked | US | beverage | M | TODO | 2026-04-07 | |  |
| 4479 | Bolthouse Farms Green Goodness (per 15.2oz) | Bolthouse | US | beverage | M | TODO | 2026-04-07 | |  |
| 4480 | Bolthouse Farms Protein Plus Chocolate (per 15.2oz) | Bolthouse | US | beverage | M | TODO | 2026-04-07 | |  |
| 4481 | V8 Original Vegetable Juice (per 8oz) | V8 | US | beverage | M | TODO | 2026-04-07 | |  |
| 4482 | Capri Sun Original (per pouch) | Capri Sun | US | beverage | M | TODO | 2026-04-07 | |  |
| 4483 | Sunny D Original (per 8oz) | Sunny D | US | beverage | M | TODO | 2026-04-07 | |  |
| 4484 | Vitaminwater XXX Acai (per 20oz) | Vitaminwater | US | beverage | M | TODO | 2026-04-07 | |  |
| 4485 | Vitaminwater Zero Sugar Squeezed (per 20oz) | Vitaminwater | US | beverage | M | TODO | 2026-04-07 | |  |
| 4486 | Spindrift Sparkling Lemon (per 12oz) | Spindrift | US | beverage | M | TODO | 2026-04-07 | |  |
| 4487 | Bai Brasilia Blueberry (per 18oz) | Bai | US | beverage | M | TODO | 2026-04-07 | |  |
| 4488 | Fiji Water (per 500ml) | Fiji | FJ | beverage | L | TODO | 2026-04-07 | |  |
| 4489 | Evian Water (per 500ml) | Evian | FR | beverage | L | TODO | 2026-04-07 | |  |
| 4490 | Dasani Water (per 500ml) | Dasani | US | beverage | L | TODO | 2026-04-07 | |  |
| 4491 | Aquafina Water (per 500ml) | Aquafina | US | beverage | L | TODO | 2026-04-07 | |  |

## Section 143: Bread, Canned, Pasta & Condiment Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4492 | Arnold Whole Grain Bread (per slice) | Arnold | US | bread | M | TODO | 2026-04-07 | |  |
| 4493 | Pillsbury Cinnamon Rolls (per roll) | Pillsbury | US | bread | M | TODO | 2026-04-07 | |  |
| 4494 | Pillsbury Grands Biscuits (per biscuit) | Pillsbury | US | bread | M | TODO | 2026-04-07 | |  |
| 4495 | Pillsbury Cookie Dough Chocolate Chip (per serving) | Pillsbury | US | dessert | M | TODO | 2026-04-07 | |  |
| 4496 | Pillsbury Pie Crust (per serving) | Pillsbury | US | baking | L | TODO | 2026-04-07 | |  |
| 4497 | Entenmann's Rich Frosted Donuts (per donut) | Entenmann's | US | dessert | M | TODO | 2026-04-07 | |  |
| 4498 | Entenmann's Crumb Coffee Cake (per slice) | Entenmann's | US | dessert | M | TODO | 2026-04-07 | |  |
| 4499 | Entenmann's Chocolate Chip Cookies (per 3) | Entenmann's | US | dessert | M | TODO | 2026-04-07 | |  |
| 4500 | Old El Paso Taco Shells Hard (per 2 shells) | Old El Paso | US | bread | M | TODO | 2026-04-07 | |  |
| 4501 | Old El Paso Flour Tortillas Soft Taco (per tortilla) | Old El Paso | US | bread | M | TODO | 2026-04-07 | |  |
| 4502 | Campbell's Chunky Sirloin Burger Soup (per serving) | Campbell's | US | soup | M | TODO | 2026-04-07 | |  |
| 4503 | Campbell's Cream of Chicken Soup (per serving) | Campbell's | US | soup | M | TODO | 2026-04-07 | |  |
| 4504 | Progresso Rich & Hearty Chicken Corn Chowder (per serving) | Progresso | US | soup | M | TODO | 2026-04-07 | |  |
| 4505 | Prego Traditional Marinara (per serving) | Prego | US | condiment | M | TODO | 2026-04-07 | |  |
| 4506 | Ragu Old World Style Marinara (per serving) | Ragu | US | condiment | M | TODO | 2026-04-07 | |  |
| 4507 | Newman's Own Marinara (per serving) | Newman's Own | US | condiment | M | TODO | 2026-04-07 | |  |
| 4508 | Classico Tomato & Basil (per serving) | Classico | US | condiment | M | TODO | 2026-04-07 | |  |
| 4509 | StarKist Chunk White Albacore Water (per can) | StarKist | US | protein | M | TODO | 2026-04-07 | |  |
| 4510 | Chicken of the Sea Chunk Light Tuna (per can) | CotS | US | protein | M | TODO | 2026-04-07 | |  |
| 4511 | Goya Chickpeas Canned (per serving) | Goya | US | staple | M | TODO | 2026-04-07 | |  |
| 4512 | Del Monte Fruit Cocktail (per serving) | Del Monte | US | fruit | M | TODO | 2026-04-07 | |  |
| 4513 | Mott's Applesauce Original (per cup) | Mott's | US | fruit | M | TODO | 2026-04-07 | |  |
| 4514 | Hormel Chili No Beans (per serving) | Hormel | US | protein | M | TODO | 2026-04-07 | |  |
| 4515 | Hormel Chili with Beans (per serving) | Hormel | US | protein | M | TODO | 2026-04-07 | |  |
| 4516 | Chef Boyardee Beef Ravioli (per serving) | Chef Boyardee | US | pasta | M | TODO | 2026-04-07 | |  |
| 4517 | Chef Boyardee Beefaroni (per serving) | Chef Boyardee | US | pasta | M | TODO | 2026-04-07 | |  |
| 4518 | SpaghettiOs Original (per serving) | SpaghettiOs | US | pasta | M | TODO | 2026-04-07 | |  |
| 4519 | Velveeta Shells & Cheese (per serving) | Velveeta | US | pasta | M | TODO | 2026-04-07 | |  |
| 4520 | Kraft Mac & Cheese Original (per serving) | Kraft | US | pasta | H | TODO | 2026-04-07 | |  |

## Section 144: Plant-Based & Dairy Alt Brands (25 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4521 | Beyond Meat Beyond Sausage Brat (per link) | Beyond Meat | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4522 | Beyond Meat Beyond Beef Crumbles (per serving) | Beyond Meat | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4523 | Impossible Sausage Links (per 2) | Impossible | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4524 | MorningStar Farms Veggie Burger (per patty) | MorningStar | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4525 | MorningStar Farms Chik'n Nuggets (per 5) | MorningStar | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4526 | MorningStar Farms Sausage Patties (per 2) | MorningStar | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4527 | Boca Original Veggie Burger (per patty) | Boca | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4528 | Gardein Ultimate Plant-Based Burger (per patty) | Gardein | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4529 | Gardein Crispy Chick'n Tenders (per 2) | Gardein | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4530 | Lightlife Smart Ground Crumbles (per serving) | Lightlife | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4531 | Tofurky Deli Slices Hickory Smoked (per 5 slices) | Tofurky | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4532 | Field Roast Sausage Italian (per link) | Field Roast | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 4533 | JUST Egg Plant-Based Scramble (per serving) | JUST | US | meat_alt | H | TODO | 2026-04-07 | |  |
| 4534 | Silk Oat Yeah Oatmilk Original (per 8oz) | Silk | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4535 | Silk Soy Milk Original (per 8oz) | Silk | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4536 | Califia Farms Oat Milk Barista (per 8oz) | Califia | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4537 | Planet Oat Original Oatmilk (per 8oz) | Planet Oat | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4538 | Chobani Oat Milk Plain (per 8oz) | Chobani | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4539 | Good Karma Flaxmilk Original (per 8oz) | Good Karma | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4540 | Daiya Cheddar Style Shreds (per 30g) | Daiya | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 4541 | Violife Epic Mature Cheddar Slices (per slice) | Violife | GR | dairy_alt | M | TODO | 2026-04-07 | |  |

## Section 145: Sports & Hydration Products (25 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4542 | Gatorade Fit Active Berry (per 16.9oz) | Gatorade | US | sports_drink | M | TODO | 2026-04-07 | |  |
| 4543 | Nuun Sport Lemon Lime (per tablet) | Nuun | US | supplement | M | TODO | 2026-04-07 | |  |
| 4544 | Nuun Sport Tri-Berry (per tablet) | Nuun | US | supplement | M | TODO | 2026-04-07 | |  |
| 4545 | Pedialyte Classic Liters (per 8oz) | Pedialyte | US | supplement | M | TODO | 2026-04-07 | |  |
| 4546 | Pedialyte Freezer Pops (per pop) | Pedialyte | US | supplement | M | TODO | 2026-04-07 | |  |
| 4547 | Electrolit Fruit Punch (per 21oz) | Electrolit | MX | supplement | M | TODO | 2026-04-07 | |  |
| 4548 | Electrolit Berry (per 21oz) | Electrolit | MX | supplement | M | TODO | 2026-04-07 | |  |
| 4549 | DripDrop ORS Lemon (per stick) | DripDrop | US | supplement | M | TODO | 2026-04-07 | |  |
| 4550 | Propel Water Berry (per 16.9oz) | Propel | US | beverage | M | TODO | 2026-04-07 | |  |
| 4551 | Essentia Water Ionized (per 20oz) | Essentia | US | beverage | L | TODO | 2026-04-07 | |  |

## Section 146: Frozen Meal Brands Complete (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4552 | DiGiorno Rising Crust Supreme (per slice) | DiGiorno | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4553 | Red Baron Classic Pepperoni (per slice) | Red Baron | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4554 | Red Baron French Bread Pepperoni (per piece) | Red Baron | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4555 | Stouffer's Lasagna with Meat (per serving) | Stouffer's | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4556 | Marie Callender's Country Fried Chicken | Marie Callender's | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4557 | Hungry-Man Salisbury Steak | Hungry-Man | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4558 | Hungry-Man Boneless Fried Chicken | Hungry-Man | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4559 | Banquet Pot Pie Chicken | Banquet | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4560 | Devour Buffalo Chicken Mac & Cheese | Devour | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4561 | Healthy Choice Power Bowl Chicken Feta | Healthy Choice | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4562 | Bird's Eye Protein Blends Chicken Fajita | Bird's Eye | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4563 | Tyson Grilled & Ready Chicken Strips (per serving) | Tyson | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4564 | Ore-Ida Golden Crinkles Fries (per serving) | Ore-Ida | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4565 | Ore-Ida Tater Tots (per serving) | Ore-Ida | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4566 | El Monterey Chicken & Cheese Taquitos (per 3) | El Monterey | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4567 | Jimmy Dean Sausage Egg Cheese Biscuit (per piece) | Jimmy Dean | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4568 | Jimmy Dean Sausage Egg Cheese Croissant (per piece) | Jimmy Dean | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4569 | Bagel Bites Cheese & Pepperoni (per 9) | Bagel Bites | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4570 | Corn Dogs Foster Farms (per dog) | Foster Farms | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4571 | Fish Sticks Gorton's (per 6) | Gorton's | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4572 | Gorton's Grilled Salmon Classic (per fillet) | Gorton's | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4573 | Mozzarella Sticks Farm Rich (per 3) | Farm Rich | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 4574 | Tattooed Chef Riced Cauliflower Bowl | Tattooed Chef | US | frozen_meal | M | TODO | 2026-04-07 | |  |

## Section 147: Condiment & Sauce Brands Complete (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4575 | Heinz 57 Sauce (per tbsp) | Heinz | US | condiment | M | TODO | 2026-04-07 | |  |
| 4576 | French's Crispy Fried Onions (per tbsp) | French's | US | condiment | M | TODO | 2026-04-07 | |  |
| 4577 | Hellmann's Light Mayo (per tbsp) | Hellmann's | US | condiment | M | TODO | 2026-04-07 | |  |
| 4578 | Sir Kensington's Classic Ketchup (per tbsp) | Sir Kensington's | US | condiment | M | TODO | 2026-04-07 | |  |
| 4579 | Kraft Thousand Island (per tbsp) | Kraft | US | condiment | M | TODO | 2026-04-07 | |  |
| 4580 | Ken's Steak House Caesar (per tbsp) | Ken's | US | condiment | M | TODO | 2026-04-07 | |  |
| 4581 | Sweet Baby Ray's Original BBQ (per tbsp) | Sweet Baby Ray's | US | condiment | H | TODO | 2026-04-07 | |  |
| 4582 | Sweet Baby Ray's Honey BBQ (per tbsp) | Sweet Baby Ray's | US | condiment | M | TODO | 2026-04-07 | |  |
| 4583 | Tabasco Original Red (per tsp) | Tabasco | US | condiment | M | TODO | 2026-04-07 | |  |
| 4584 | Fly By Jing Sichuan Chili Crisp (per tbsp) | Fly By Jing | US | condiment | M | TODO | 2026-04-07 | |  |
| 4585 | Mike's Hot Honey (per tbsp) | Mike's | US | condiment | M | TODO | 2026-04-07 | |  |
| 4586 | A1 Steak Sauce (per tbsp) | A1 | US | condiment | M | TODO | 2026-04-07 | |  |
| 4587 | Lea & Perrins Worcestershire (per tsp) | Lea & Perrins | US | condiment | M | TODO | 2026-04-07 | |  |
---

## Section 148: Indian Home-Cooked Staples Missing India-Country Row (50 items)

> Context: audit 2026-04-12 against `food_nutrition_overrides` found these common Indian dishes exist in the DB only under other countries (Kenya / Pakistan / Oman / UAE / Nepal / etc.) or as restaurant-branded rows (Chowrasta, Desi District, Swadeshi) — but NO plain `*_indian` row. Add one canonical `country_name='India'` entry per dish with home-cooked nutrition values (per 100g) so Indian users see them surface first.

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 4588 | Paneer Tikka Masala (home) | Various | IN | curry | H | TODO | 2026-04-12 | | classic North Indian restaurant dish; only restaurant-branded rows exist |
| 4589 | Hakka Noodles (veg) | Various | IN | noodles | H | TODO | 2026-04-12 | | Indo-Chinese street classic |
| 4590 | Hakka Noodles (chicken) | Various | IN | noodles | H | TODO | 2026-04-12 | | non-veg variant |
| 4591 | Schezwan Fried Rice | Various | IN | rice_dish | H | TODO | 2026-04-12 | | Indo-Chinese; spicy |
| 4592 | Veg Fried Rice (Indian restaurant) | Various | IN | rice_dish | H | TODO | 2026-04-12 | | distinct from Chinese fried rice |
| 4593 | Moong Dal Khichdi | Various | IN | rice_dish | H | TODO | 2026-04-12 | | rice + moong dal; staple comfort food |
| 4594 | Paneer Kathi Roll | Various | IN | street_food | H | TODO | 2026-04-12 | | Kolkata-style wrap |
| 4595 | Chicken Kathi Roll | Various | IN | street_food | H | TODO | 2026-04-12 | | Kolkata classic |
| 4596 | Rava Upma | Various | IN | breakfast | H | TODO | 2026-04-12 | | semolina breakfast |
| 4597 | Chaas / Buttermilk (per glass 200ml) | Various | IN | beverage | M | TODO | 2026-04-12 | | thin yogurt drink, tempered |
| 4598 | Methi Thepla (per piece) | Various | IN | bread | M | TODO | 2026-04-12 | | fenugreek flatbread |
| 4599 | Kurkuri Bhindi | Various | IN | vegetable | M | TODO | 2026-04-12 | | crispy fried okra |
| 4600 | Paneer Chilli (dry) | Various | IN | appetizer | H | TODO | 2026-04-12 | | Indo-Chinese paneer |

---

## Progress Summary

| Metric | Count |
|--------|-------|
| **Total items** | ~8800 |
| **TODO** | ~8800 |
| **DUPLICATE** | 0 |
| **DONE** | 0 |

### Coverage: 147 Sections across all categories
- Sections 1-69: International brands, fitness products, street food, user log items, staples, beverages, condiments, frozen meals, holiday foods
- Sections 70-95: World cuisines (Chinese 150, Japanese 120, Korean 100, Thai 80, Vietnamese 70, Indian North 150, Indian South 120, Indian East/West 80, Mexican 100, Italian 100, Mediterranean 80, Latin American 100, African 100, Southeast Asian 100, European 100, American Regional 150), Trader Joe's, Costco, fast food, coffee/juice, dessert/ice cream, breakfast, salad/bowl, sandwich, pizza, alcohol
- Sections 99-119: Branded products (Trader Joe's, Costco, Aldi, Target, Walmart, meal kits, weight mgmt, frozen meals, cereals, yogurt, snacks, cookies, candy, ice cream, beverages, bread, condiments, protein bars, plant-based, sports drinks)
- Sections 120-147: Restaurant menus (McDonald's, Wendy's, Taco Bell, BK, Chick-fil-A, Chipotle, Subway, Domino's, Pizza Hut, Popeyes, Arby's, Sonic, Jack in the Box, Whataburger, Culver's), casual dining (Olive Garden, Applebee's, Chili's, Texas Roadhouse, Red Lobster, Outback, Cheesecake Factory, Cracker Barrel, IHOP, Denny's, BWW, P.F. Chang's), coffee shop food, dessert chains, alcohol complete, street food 30+ countries, gas station/vending/school/airport, juice/smoothie chains, grocery brands complete

### Countries: 90+
### Brands: 1000+
### Sources cross-referenced: All migration SQL files, foods_needed.md, MISSING_GENERIC_FOODS.md, WRONG_FOOD_MATCHES.md, FOOD_LOG_EDGE_CASES.md, FOOD_LOG_TEST_PROMPTS.md, FOODS_BY_WEIGHT.md, street_food_by_country.md, chain_restaurants_by_country.md
