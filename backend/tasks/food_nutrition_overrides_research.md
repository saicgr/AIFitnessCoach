# Food Nutrition Overrides Research Task File

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
| 17 | Catalina Crunch Keto Cereal Maple Waffle | Catalina Crunch | US | protein_cereal | H | TODO | 2026-04-07 | | |
| 18 | Catalina Crunch Keto Cereal Fruity | Catalina Crunch | US | protein_cereal | H | TODO | 2026-04-07 | | |
| 21 | Magic Spoon Protein Cereal Peanut Butter | Magic Spoon | US | protein_cereal | H | TODO | 2026-04-07 | | |
| 24 | Grandpa Crumble Protein Muesli | Grandpa Crumble | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 25 | BioTechUSA Protein Cereal | BioTechUSA | HU | protein_cereal | H | TODO | 2026-04-07 | | |
| 26 | GOT7 High Protein Cereal Cinnamon | GOT7 Nutrition | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 27 | GOT7 High Protein Cereal Chocolate | GOT7 Nutrition | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 28 | Weetabix Protein Original | Weetabix | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 29 | Weetabix Protein Chocolate | Weetabix | GB | protein_cereal | H | TODO | 2026-04-07 | | |
| 31 | Jordans Protein Granola | Jordans | GB | protein_cereal | M | TODO | 2026-04-07 | | |
| 32 | Lizi's High Protein Granola | Lizi's | GB | protein_cereal | M | TODO | 2026-04-07 | | |
| 34 | Quaker Protein Instant Oatmeal Banana Nut | Quaker | US | protein_cereal | M | TODO | 2026-04-07 | | |
| 35 | AMFIT Protein Granola Amazon Brand | AMFIT | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 37 | YFood Protein Crunchy Muesli | YFood | DE | protein_cereal | M | TODO | 2026-04-07 | | |
| 38 | Alpro High Protein Granola | Alpro | BE | protein_cereal | M | TODO | 2026-04-07 | | |
| 39 | Protein Mueslii Crunchy Vanilla | Protein Mueslii | NL | protein_cereal | M | TODO | 2026-04-07 | | |
| 40 | IronMaxx Protein Musli | IronMaxx | DE | protein_cereal | M | TODO | 2026-04-07 | | |

## Section 2: Protein Bars - International & Niche (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 42 | Grenade Carb Killa Oreo White | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 43 | Grenade Carb Killa Caramel Chaos | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 44 | Grenade Carb Killa Birthday Cake | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 46 | Grenade Carb Killa Fudged Up | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 50 | PhD Smart Bar Chocolate Brownie | PhD Nutrition | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 66 | ESN Designer Bar Crunchy | ESN | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 67 | ESN Designer Bar Caramel Brownie | ESN | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 68 | BioTechUSA Zero Bar Chocolate Chip Cookies | BioTechUSA | HU | protein_bar | M | TODO | 2026-04-07 | | |
| 69 | BioTechUSA Zero Bar Double Chocolate | BioTechUSA | HU | protein_bar | M | TODO | 2026-04-07 | | |
| 70 | PowerBar Protein Plus 30% Chocolate | PowerBar | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 75 | Aussie Bodies ProteinFX Lo Carb Crisp | Aussie Bodies | AU | protein_bar | M | TODO | 2026-04-07 | | |
| 88 | Nugo Slim Bar Espresso | NuGo | US | protein_bar | L | TODO | 2026-04-07 | | |

## Section 3: Protein Drinks & RTD Shakes (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 91 | NOCCO BCAA Caribbean | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 92 | NOCCO BCAA Juicy Breeze | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 93 | NOCCO BCAA Apple | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 94 | NOCCO BCAA Limon Del Sol | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 95 | NOCCO BCAA Miami Strawberry | NOCCO | SE | protein_drink | H | TODO | 2026-04-07 | | |
| 96 | YFood Ready to Drink Smooth Vanilla | YFood | DE | protein_drink | H | TODO | 2026-04-07 | | |
| 97 | YFood Ready to Drink Fresh Berry | YFood | DE | protein_drink | H | TODO | 2026-04-07 | | |
| 98 | YFood Ready to Drink Classic Choco | YFood | DE | protein_drink | H | TODO | 2026-04-07 | | |
| 99 | Jimmy Joy Plenny Shake Vanilla | Jimmy Joy | NL | protein_drink | M | TODO | 2026-04-07 | | |
| 100 | Jimmy Joy Plenny Shake Chocolate | Jimmy Joy | NL | protein_drink | M | TODO | 2026-04-07 | | |
| 103 | Huel Ready-to-Drink Berry | Huel | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 104 | Huel Ready-to-Drink Banana | Huel | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 107 | Saturo RTD Meal Shake Original | Saturo | AT | protein_drink | M | TODO | 2026-04-07 | | |
| 108 | Saturo RTD Meal Shake Chocolate | Saturo | AT | protein_drink | M | TODO | 2026-04-07 | | |
| 109 | Mana RTD Meal Shake Origin | Mana | CZ | protein_drink | M | TODO | 2026-04-07 | | |
| 110 | Feed Smart Meal Bar Chocolate | Feed | FR | protein_drink | M | TODO | 2026-04-07 | | |
| 111 | Feed Smart Meal Shake Vanilla | Feed | FR | protein_drink | M | TODO | 2026-04-07 | | |
| 112 | Soylent Ready to Drink Original | Soylent | US | protein_drink | M | TODO | 2026-04-07 | | |
| 113 | Soylent Ready to Drink Cafe Mocha | Soylent | US | protein_drink | M | TODO | 2026-04-07 | | |
| 114 | Ka'Chava All-in-One Meal Shake Chocolate | Ka'Chava | US | protein_drink | M | TODO | 2026-04-07 | | |
| 115 | Protein2o Protein Infused Water Mixed Berry | Protein2o | US | protein_drink | M | TODO | 2026-04-07 | | |
| 116 | MyProtein Clear Whey Isolate Peach Tea | MyProtein | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 117 | MyProtein Clear Whey Isolate Lemonade | MyProtein | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 118 | Bulk Powders Complete Protein Shake Strawberry | Bulk | GB | protein_drink | M | TODO | 2026-04-07 | | |
| 119 | Amway Nutrilite Protein Drink Mix | Nutrilite | US | protein_drink | M | TODO | 2026-04-07 | | |
| 120 | Oatly Protein Oat Drink | Oatly | SE | protein_drink | M | TODO | 2026-04-07 | | |

## Section 4: Protein Snacks & Chips (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 121 | Shrewd Food Protein Puffs Baked Cheddar | Shrewd Food | US | protein_snack | H | TODO | 2026-04-07 | | |
| 122 | Shrewd Food Protein Puffs Sriracha | Shrewd Food | US | protein_snack | M | TODO | 2026-04-07 | | |
| 130 | Legendary Foods Protein Pastry Strawberry | Legendary Foods | US | protein_snack | M | TODO | 2026-04-07 | | |
| 132 | The Protein Ball Co Peanut Butter | The Protein Ball Co | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 133 | The Protein Ball Co Lemon Pistachio | The Protein Ball Co | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 134 | Graze Protein Bites Cocoa Vanilla | Graze | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 135 | Graze Protein Oat Bites Honey | Graze | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 136 | Biltong Chief Original South African Biltong | Biltong Chief | ZA | protein_snack | M | TODO | 2026-04-07 | | |
| 137 | Brooklyn Biltong Original | Brooklyn Biltong | US | protein_snack | M | TODO | 2026-04-07 | | |
| 139 | The New Primal Classic Beef Stick | The New Primal | US | protein_snack | M | TODO | 2026-04-07 | | |
| 140 | Peperami Protein Bites | Peperami | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 141 | Protein Puck Original | Protein Puck | US | protein_snack | L | TODO | 2026-04-07 | | |
| 142 | BioTechUSA Protein Chips Salt | BioTechUSA | HU | protein_snack | M | TODO | 2026-04-07 | | |
| 143 | BioTechUSA Protein Chips Cheese | BioTechUSA | HU | protein_snack | M | TODO | 2026-04-07 | | |
| 144 | MyProtein Protein Brownie Chocolate | MyProtein | GB | protein_snack | H | TODO | 2026-04-07 | | |
| 145 | MyProtein Protein Wafer Chocolate Hazelnut | MyProtein | GB | protein_snack | H | TODO | 2026-04-07 | | |
| 146 | Prozis Protein Wafer Chocolate | Prozis | PT | protein_snack | M | TODO | 2026-04-07 | | |
| 148 | IronMaxx Protein Chips Paprika | IronMaxx | DE | protein_snack | M | TODO | 2026-04-07 | | |
| 149 | High Key Protein Cereal Mini Cookies Chocolate | HighKey | US | protein_snack | M | TODO | 2026-04-07 | | |
| 150 | Flapjacked Mighty Muffin Double Chocolate | Flapjacked | US | protein_snack | M | TODO | 2026-04-07 | | |

## Section 5: International Energy Drinks (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 156 | Celsius Sparkling Orange | Celsius | SE | energy_drink | H | TODO | 2026-04-07 | | |
| 158 | Celsius Sparkling Peach Vibe | Celsius | SE | energy_drink | H | TODO | 2026-04-07 | | |
| 159 | Celsius Essentials Sparkling Cherry Limeade | Celsius | SE | energy_drink | M | TODO | 2026-04-07 | | |
| 160 | Celsius On-the-Go Powder Kiwi Guava | Celsius | SE | energy_drink | M | TODO | 2026-04-07 | | |
| 167 | 3D Energy Drink Chrome | 3D Energy | US | energy_drink | L | TODO | 2026-04-07 | | |
| 176 | Hell Energy Drink Classic | Hell | HU | energy_drink | M | TODO | 2026-04-07 | | |
| 177 | Hell Energy Drink Apple | Hell | HU | energy_drink | M | TODO | 2026-04-07 | | |
| 178 | Predator Energy Drink Gold Strike | Predator | NL | energy_drink | L | TODO | 2026-04-07 | | |
| 179 | Carabao Energy Drink Original | Carabao | TH | energy_drink | M | TODO | 2026-04-07 | | |
| 180 | M-150 Energy Drink | M-150 | TH | energy_drink | M | TODO | 2026-04-07 | | |
| 181 | Lipovitan-D Energy Drink | Lipovitan | JP | energy_drink | M | TODO | 2026-04-07 | | |
| 182 | Oronamin C Drink | Otsuka | JP | energy_drink | M | TODO | 2026-04-07 | | |
| 183 | Real Gold Energy Drink | Coca-Cola Japan | JP | energy_drink | L | TODO | 2026-04-07 | | |
| 185 | Aquarius Sports Drink Japan | Coca-Cola Japan | JP | energy_drink | M | TODO | 2026-04-07 | | |
| 186 | Sting Energy Drink Gold Rush | Sting | IN | energy_drink | H | TODO | 2026-04-07 | | |
| 187 | Sting Energy Drink Berry Blast | Sting | IN | energy_drink | H | TODO | 2026-04-07 | | |
| 188 | Tzinga Energy Drink Mango | Tzinga | IN | energy_drink | M | TODO | 2026-04-07 | | |
| 189 | Fast Up Charge Energy Drink | Fast&Up | IN | energy_drink | M | TODO | 2026-04-07 | | |
| 190 | Bournvita Protein Shake RTD | Cadbury | IN | energy_drink | H | TODO | 2026-04-07 | | |

## Section 6: International Protein Powders & Supplements (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 193 | Optimum Nutrition Gold Standard Plant Chocolate Fudge | Optimum Nutrition | US | protein_powder | M | TODO | 2026-04-07 | | per scoop |
| 199 | ESN Designer Whey Vanilla | ESN | DE | protein_powder | M | TODO | 2026-04-07 | | German top seller |
| 200 | ESN Designer Whey Chocolate | ESN | DE | protein_powder | M | TODO | 2026-04-07 | | |
| 201 | Prozis Whey Protein Concentrate Chocolate | Prozis | PT | protein_powder | M | TODO | 2026-04-07 | | |
| 203 | BioTechUSA 100% Pure Whey Biscuit | BioTechUSA | HU | protein_powder | M | TODO | 2026-04-07 | | |
| 204 | Olimp Whey Protein Complex Chocolate | Olimp | PL | protein_powder | M | TODO | 2026-04-07 | | |
| 205 | Reflex Nutrition Instant Whey Chocolate | Reflex | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 206 | Applied Nutrition ISO-XP Chocolate | Applied Nutrition | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 208 | MuscleBlaze Biozyme Whey Protein Rich Chocolate | MuscleBlaze | IN | protein_powder | H | TODO | 2026-04-07 | | India bestseller |
| 209 | AS-IT-IS Whey Protein Unflavored | AS-IT-IS | IN | protein_powder | M | TODO | 2026-04-07 | | |
| 211 | GNC Pro Performance 100% Whey Chocolate | GNC | US | protein_powder | M | TODO | 2026-04-07 | | |
| 217 | Muscle Feast Grass Fed Whey Chocolate | Muscle Feast | US | protein_powder | L | TODO | 2026-04-07 | | |
| 218 | PEScience Select Protein Chocolate Peanut Butter | PEScience | US | protein_powder | L | TODO | 2026-04-07 | | |
| 219 | Mutant Whey Protein Cookies & Cream | Mutant | CA | protein_powder | M | TODO | 2026-04-07 | | |
| 220 | Allmax IsoFlex Pure Whey Chocolate | Allmax | CA | protein_powder | M | TODO | 2026-04-07 | | |

## Section 7: International Yogurt & Dairy (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 221 | Skyr Icelandic Provisions Vanilla | Icelandic Provisions | IS | dairy | H | TODO | 2026-04-07 | | |
| 222 | Skyr Icelandic Provisions Blueberry | Icelandic Provisions | IS | dairy | M | TODO | 2026-04-07 | | |
| 226 | Arla Protein Yogurt Strawberry | Arla | DK | dairy | H | TODO | 2026-04-07 | | |
| 227 | Arla Protein Yogurt Blueberry | Arla | DK | dairy | M | TODO | 2026-04-07 | | |
| 228 | Arla Protein Pudding Chocolate | Arla | DK | dairy | H | TODO | 2026-04-07 | | |
| 229 | Arla Protein Milk Drink Chocolate | Arla | DK | dairy | M | TODO | 2026-04-07 | | |
| 230 | Muller Light Yogurt Strawberry | Muller | DE | dairy | M | TODO | 2026-04-07 | | |
| 231 | Muller Light Yogurt Vanilla | Muller | DE | dairy | M | TODO | 2026-04-07 | | |
| 232 | Epigamia Greek Yogurt Strawberry | Epigamia | IN | dairy | H | TODO | 2026-04-07 | | |
| 233 | Epigamia Greek Yogurt Natural | Epigamia | IN | dairy | H | TODO | 2026-04-07 | | |
| 234 | Epigamia Protein Yogurt Mango | Epigamia | IN | dairy | H | TODO | 2026-04-07 | | |
| 235 | Danone Oikos Pro High Protein Vanilla | Danone | FR | dairy | M | TODO | 2026-04-07 | | |
| 236 | YoPRO High Protein Yogurt Vanilla | YoPRO | AU | dairy | H | TODO | 2026-04-07 | | |
| 237 | YoPRO High Protein Yogurt Strawberry | YoPRO | AU | dairy | M | TODO | 2026-04-07 | | |

## Section 8: International Instant Noodles & Ramen (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 244 | Indomie Soto Mie | Indomie | ID | instant_noodle | M | TODO | 2026-04-07 | | |
| 245 | Samyang Buldak Hot Chicken 2x Spicy | Samyang | KR | instant_noodle | H | TODO | 2026-04-07 | | |
| 246 | Samyang Buldak Hot Chicken Original | Samyang | KR | instant_noodle | H | TODO | 2026-04-07 | | |
| 247 | Samyang Buldak Hot Chicken Carbonara | Samyang | KR | instant_noodle | H | TODO | 2026-04-07 | | |
| 248 | Samyang Buldak Hot Chicken Cheese | Samyang | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 251 | Nongshim Chapagetti | Nongshim | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 252 | Nongshim Neoguri Seafood | Nongshim | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 253 | Ottogi Jin Ramen Spicy | Ottogi | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 254 | Paldo Bibimmyeon | Paldo | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 258 | Maruchan Instant Lunch Chicken | Maruchan | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 259 | Mama Tom Yum Shrimp Instant Noodles | Mama | TH | instant_noodle | H | TODO | 2026-04-07 | | |
| 260 | Mama Creamy Tom Yum | Mama | TH | instant_noodle | M | TODO | 2026-04-07 | | |
| 261 | Yum Yum Tom Yam Kung | Yum Yum | TH | instant_noodle | M | TODO | 2026-04-07 | | |
| 262 | Wai Wai Instant Noodles Chicken | Wai Wai | TH | instant_noodle | M | TODO | 2026-04-07 | | Popular in India/Nepal |
| 263 | Maggi 2-Minute Noodles Masala | Maggi | IN | instant_noodle | H | TODO | 2026-04-07 | | India staple |
| 264 | Maggi Hot Heads Peri Peri | Maggi | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 265 | Yippee Noodles Magic Masala | Yippee | IN | instant_noodle | H | TODO | 2026-04-07 | | |
| 266 | Top Ramen Curry Noodles | Top Ramen | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 267 | Knorr Soupy Noodles Mast Masala | Knorr | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 270 | Prima Taste Laksa La Mian | Prima Taste | SG | instant_noodle | M | TODO | 2026-04-07 | | |

## Section 9: International Chocolate & Confectionery (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 281 | Cadbury 5 Star | Cadbury | IN | chocolate | H | TODO | 2026-04-07 | | |
| 282 | Cadbury Perk | Cadbury | IN | chocolate | M | TODO | 2026-04-07 | | |
| 295 | Kit Kat Matcha (Japan) | Nestle | JP | chocolate | H | TODO | 2026-04-07 | | Japan exclusive |
| 296 | Kit Kat Strawberry Cheesecake (Japan) | Nestle | JP | chocolate | M | TODO | 2026-04-07 | | Japan exclusive |
| 297 | Meiji Chocolate Milk Bar | Meiji | JP | chocolate | M | TODO | 2026-04-07 | | |
| 298 | Lotte Ghana Chocolate Milk | Lotte | KR | chocolate | M | TODO | 2026-04-07 | | |

## Section 10: International Chips & Savory Snacks (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 301 | Lay's Magic Masala (India) | Lay's | IN | snack | H | TODO | 2026-04-07 | | India flavor |
| 302 | Lay's American Style Cream & Onion (India) | Lay's | IN | snack | M | TODO | 2026-04-07 | | |
| 304 | Kurkure Chilli Chatka | Kurkure | IN | snack | M | TODO | 2026-04-07 | | |
| 306 | Haldiram's Moong Dal | Haldiram's | IN | snack | H | TODO | 2026-04-07 | | |
| 307 | Haldiram's Sev Bhujia | Haldiram's | IN | snack | M | TODO | 2026-04-07 | | |
| 309 | Balaji Wafers Masala | Balaji | IN | snack | M | TODO | 2026-04-07 | | Gujarat brand |
| 310 | Bingo Mad Angles Achari Masti | Bingo | IN | snack | M | TODO | 2026-04-07 | | |
| 311 | Calbee Shrimp Chips Original | Calbee | JP | snack | H | TODO | 2026-04-07 | | |
| 312 | Calbee Jagariko Salad | Calbee | JP | snack | M | TODO | 2026-04-07 | | |
| 313 | Calbee Kappa Ebisen | Calbee | JP | snack | M | TODO | 2026-04-07 | | |
| 314 | Koikeya Karamucho Hot Chili | Koikeya | JP | snack | M | TODO | 2026-04-07 | | |
| 315 | Nongshim Shrimp Crackers | Nongshim | KR | snack | M | TODO | 2026-04-07 | | |
| 316 | Orion Turtle Chips Corn Soup | Orion | KR | snack | M | TODO | 2026-04-07 | | |
| 317 | Honey Butter Chips | Haitai | KR | snack | H | TODO | 2026-04-07 | | Korean viral snack |
| 318 | Shrimp Chips Nongshim Honey | Nongshim | KR | snack | M | TODO | 2026-04-07 | | |
| 319 | Want Want Rice Crackers | Want Want | TW | snack | M | TODO | 2026-04-07 | | |
| 320 | Oishi Prawn Crackers | Oishi | PH | snack | M | TODO | 2026-04-07 | | |
| 321 | Jack n Jill Piattos Cheese | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 322 | Mamee Monster Noodle Snack | Mamee | MY | snack | M | TODO | 2026-04-07 | | |
| 323 | Twisties Cheese | Twisties | MY | snack | M | TODO | 2026-04-07 | | |
| 326 | Sabritas Ruffles Queso | Sabritas | MX | snack | M | TODO | 2026-04-07 | | |
| 327 | Platanitos Plantain Chips | Various | MX | snack | M | TODO | 2026-04-07 | | |
| 328 | Pipers Crisps Anglesey Sea Salt | Pipers | GB | snack | M | TODO | 2026-04-07 | | Premium UK crisp |
| 329 | Tyrrell's Lightly Sea Salted | Tyrrell's | GB | snack | M | TODO | 2026-04-07 | | |
| 330 | Walkers Cheese & Onion | Walkers | GB | snack | H | TODO | 2026-04-07 | | UK staple |
| 331 | Walkers Prawn Cocktail | Walkers | GB | snack | M | TODO | 2026-04-07 | | |
| 332 | Pom-Bear Original | Pom-Bear | DE | snack | M | TODO | 2026-04-07 | | |
| 333 | Chio Tortillas Wild Paprika | Chio | DE | snack | M | TODO | 2026-04-07 | | |
| 334 | Bamba Peanut Snack | Osem | IL | snack | H | TODO | 2026-04-07 | | Israel iconic snack |
| 335 | Bissli BBQ | Osem | IL | snack | M | TODO | 2026-04-07 | | |
| 336 | Smith's Original Crinkle Cut | Smith's | AU | snack | M | TODO | 2026-04-07 | | |
| 337 | Red Rock Deli Honey Soy Chicken | Red Rock Deli | AU | snack | M | TODO | 2026-04-07 | | |
| 338 | Bluebird Ready Salted | Bluebird | NZ | snack | M | TODO | 2026-04-07 | | |
| 339 | Simba All Gold Tomato Sauce | Simba | ZA | snack | M | TODO | 2026-04-07 | | |
| 340 | Nik Naks Original Nice | Simba | ZA | snack | M | TODO | 2026-04-07 | | SA snack |

## Section 11: International Beverages - Non-energy (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 342 | Yakult Light | Yakult | JP | beverage | M | TODO | 2026-04-07 | | |
| 343 | Calpis Water (Calpico) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | |
| 344 | Ramune Soda Original | Various | JP | beverage | M | TODO | 2026-04-07 | | |
| 345 | Vita Soy Original | Vita Soy | HK | beverage | M | TODO | 2026-04-07 | | |
| 346 | Vita Lemon Tea | Vita | HK | beverage | M | TODO | 2026-04-07 | | |
| 347 | Mogu Mogu Lychee | Mogu Mogu | TH | beverage | M | TODO | 2026-04-07 | | |
| 348 | Mogu Mogu Mango | Mogu Mogu | TH | beverage | M | TODO | 2026-04-07 | | |
| 349 | Cha Yen Thai Milk Tea (bottled) | Various | TH | beverage | M | TODO | 2026-04-07 | | |
| 351 | Frooti Mango Drink | Parle Agro | IN | beverage | H | TODO | 2026-04-07 | | India iconic |
| 352 | Maaza Mango Drink | Coca-Cola India | IN | beverage | H | TODO | 2026-04-07 | | |
| 353 | Appy Fizz | Parle Agro | IN | beverage | M | TODO | 2026-04-07 | | |
| 355 | Paper Boat Jaljeera | Paper Boat | IN | beverage | M | TODO | 2026-04-07 | | |
| 356 | Thums Up (Indian Cola) | Coca-Cola India | IN | beverage | M | TODO | 2026-04-07 | | |
| 357 | Limca (Indian Lemon Soda) | Coca-Cola India | IN | beverage | M | TODO | 2026-04-07 | | |
| 358 | Tropicana Mosambi Juice | Tropicana | IN | beverage | M | TODO | 2026-04-07 | | |
| 359 | Real Fruit Power Mixed Fruit | Dabur | IN | beverage | M | TODO | 2026-04-07 | | |
| 360 | Lassi Amul Mango | Amul | IN | beverage | H | TODO | 2026-04-07 | | |
| 361 | Lassi Amul Kesar | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 362 | Buttermilk Amul Masala Chaas | Amul | IN | beverage | H | TODO | 2026-04-07 | | |
| 363 | Fanta Jasmine Peach (Japan) | Coca-Cola Japan | JP | beverage | L | TODO | 2026-04-07 | | Japan exclusive |
| 365 | Soju Chamisul Original | Hite Jinro | KR | beverage | M | TODO | 2026-04-07 | | |
| 367 | Teh Botol Jasmine Tea | Sosro | ID | beverage | M | TODO | 2026-04-07 | | Indonesia staple |
| 368 | Bandung Rose Milk | Various | SG | beverage | M | TODO | 2026-04-07 | | |

## Section 12: International Biscuits & Cookies (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 371 | McVitie's Digestive Original | McVitie's | GB | biscuit | H | TODO | 2026-04-07 | | |
| 372 | McVitie's Digestive Chocolate | McVitie's | GB | biscuit | M | TODO | 2026-04-07 | | |
| 373 | McVitie's Hobnobs Original | McVitie's | GB | biscuit | M | TODO | 2026-04-07 | | |
| 374 | McVitie's Jaffa Cakes | McVitie's | GB | biscuit | H | TODO | 2026-04-07 | | |
| 375 | Rich Tea Biscuits | McVitie's | GB | biscuit | M | TODO | 2026-04-07 | | |
| 380 | Britannia Good Day Butter | Britannia | IN | biscuit | H | TODO | 2026-04-07 | | |
| 381 | Britannia Marie Gold | Britannia | IN | biscuit | H | TODO | 2026-04-07 | | |
| 382 | Britannia Bourbon Chocolate Cream | Britannia | IN | biscuit | M | TODO | 2026-04-07 | | |
| 383 | Sunfeast Dark Fantasy Choco Fills | ITC | IN | biscuit | H | TODO | 2026-04-07 | | |
| 384 | Sunfeast Mom's Magic Cashew & Almond | ITC | IN | biscuit | M | TODO | 2026-04-07 | | |
| 386 | Unibic Choco Chip Cookies | Unibic | IN | biscuit | M | TODO | 2026-04-07 | | |
| 387 | Digestive Biscuit Britannia | Britannia | IN | biscuit | M | TODO | 2026-04-07 | | |
| 388 | Tim Tam Original | Arnott's | AU | biscuit | H | TODO | 2026-04-07 | | Australian icon |
| 389 | Tim Tam Double Coat | Arnott's | AU | biscuit | M | TODO | 2026-04-07 | | |
| 390 | Arnott's Shapes BBQ | Arnott's | AU | biscuit | M | TODO | 2026-04-07 | | |
| 391 | Koala March Chocolate | Lotte | JP | biscuit | M | TODO | 2026-04-07 | | |
| 392 | Bourbon Alfort Chocolate | Bourbon | JP | biscuit | M | TODO | 2026-04-07 | | |
| 393 | Country Ma'am Vanilla & Cocoa | Fujiya | JP | biscuit | M | TODO | 2026-04-07 | | |
| 394 | Choco Pie (Korean) | Lotte | KR | biscuit | H | TODO | 2026-04-07 | | |
| 396 | Stroopwafel Daelmans Caramel | Daelmans | NL | biscuit | H | TODO | 2026-04-07 | | Dutch icon |
| 397 | Leibniz Butter Biscuit | Bahlsen | DE | biscuit | M | TODO | 2026-04-07 | | |
| 398 | Bahlsen Choco Leibniz | Bahlsen | DE | biscuit | M | TODO | 2026-04-07 | | |
| 399 | LU Petit Beurre | LU | FR | biscuit | M | TODO | 2026-04-07 | | |
| 400 | Belvita Breakfast Biscuit Honey & Nut | Belvita | FR | biscuit | M | TODO | 2026-04-07 | | |

## Section 13: International Spreads & Condiments (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 403 | Bovril | Bovril | GB | spread | M | TODO | 2026-04-07 | | |
| 404 | Speculoos Spread (Trader Joe's Cookie Butter) | Trader Joe's | US | spread | M | TODO | 2026-04-07 | | |
| 408 | Sundrop Peanut Butter Crunchy | Sundrop | IN | spread | H | TODO | 2026-04-07 | | |
| 409 | MyFitness Peanut Butter Chocolate | MyFitness | IN | spread | H | TODO | 2026-04-07 | | India fitness brand |
| 410 | MyFitness Peanut Butter Crunchy Natural | MyFitness | IN | spread | H | TODO | 2026-04-07 | | |
| 411 | The Whole Truth Peanut Butter Crunchy | The Whole Truth | IN | spread | M | TODO | 2026-04-07 | | |
| 412 | Pintola Peanut Butter Classic Crunchy | Pintola | IN | spread | M | TODO | 2026-04-07 | | |
| 413 | Nutralite Mayo Eggless | Nutralite | IN | spread | M | TODO | 2026-04-07 | | |
| 414 | Tahini Al Arz | Al Arz | LB | spread | M | TODO | 2026-04-07 | | |
| 415 | Halva Achva Vanilla | Achva | IL | spread | M | TODO | 2026-04-07 | | |
| 416 | Dulce de Leche Havanna | Havanna | AR | spread | M | TODO | 2026-04-07 | | |
| 417 | Nocciolata Organic Hazelnut Spread | Rigoni di Asiago | IT | spread | M | TODO | 2026-04-07 | | |
| 418 | Bonne Maman Strawberry Jam | Bonne Maman | FR | spread | M | TODO | 2026-04-07 | | |
| 422 | Kimchi Jongga Mat | Jongga | KR | condiment | H | TODO | 2026-04-07 | | per 100g |
| 423 | Japanese Kewpie Mayonnaise | Kewpie | JP | condiment | H | TODO | 2026-04-07 | | |
| 424 | Bulldog Tonkatsu Sauce | Bulldog | JP | condiment | M | TODO | 2026-04-07 | | |
| 425 | Nando's Peri-Peri Sauce Hot | Nando's | ZA | condiment | M | TODO | 2026-04-07 | | |
| 426 | Encona West Indian Hot Pepper Sauce | Encona | GB | condiment | M | TODO | 2026-04-07 | | |
| 427 | Lao Gan Ma Chili Crisp | Lao Gan Ma | CN | condiment | H | TODO | 2026-04-07 | | Viral worldwide |
| 429 | Maggi Hot & Sweet Tomato Chilli Sauce | Maggi | IN | condiment | H | TODO | 2026-04-07 | | India staple |
| 430 | Kissan Mixed Fruit Jam | Kissan | IN | spread | M | TODO | 2026-04-07 | | |

## Section 14: International Frozen & Ready Meals (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 431 | Birds Eye Chicken Chargrilled | Birds Eye | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 432 | Birds Eye Fish Fingers | Birds Eye | GB | frozen_meal | H | TODO | 2026-04-07 | | UK staple |
| 433 | Quorn Meat Free Chicken Pieces | Quorn | GB | frozen_meal | H | TODO | 2026-04-07 | | |
| 434 | Quorn Meat Free Mince | Quorn | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 435 | Linda McCartney Vegetarian Sausages | Linda McCartney | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 437 | McCain Oven Chips Straight Cut | McCain | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 439 | Iglo Fish Sticks (Fischstabchen) | Iglo | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 440 | Dr. Oetker Ristorante Pizza Mozzarella | Dr. Oetker | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 442 | Picard Gratin Dauphinois | Picard | FR | frozen_meal | M | TODO | 2026-04-07 | | |
| 443 | Findus Crispy Pancakes Minced Beef | Findus | SE | frozen_meal | M | TODO | 2026-04-07 | | |
| 444 | MyProtein Protein Meal Prep Pot Chicken Tikka | MyProtein | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 445 | Fuel10K Protein Porridge Pot Chocolate | Fuel10K | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 448 | Haldiram's Ready to Eat Biryani | Haldiram's | IN | ready_meal | M | TODO | 2026-04-07 | | |

## Section 15: International Bread & Bakery (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 451 | Warburtons Medium Sliced White | Warburtons | GB | bread | M | TODO | 2026-04-07 | | |
| 452 | Warburtons Protein Thins | Warburtons | GB | bread | H | TODO | 2026-04-07 | | Protein bread |
| 453 | Hovis Seed Sensations | Hovis | GB | bread | M | TODO | 2026-04-07 | | |
| 454 | Mestemacher Protein Bread | Mestemacher | DE | bread | H | TODO | 2026-04-07 | | |
| 455 | Mestemacher Pumpernickel | Mestemacher | DE | bread | M | TODO | 2026-04-07 | | |
| 456 | Wasa Crispbread Original | Wasa | SE | bread | M | TODO | 2026-04-07 | | |
| 458 | Modern Bread White | Modern | IN | bread | M | TODO | 2026-04-07 | | |
| 459 | Pita Bread Kontos | Kontos | GR | bread | M | TODO | 2026-04-07 | | |
| 461 | Lo Dough Flatbread | Lo Dough | GB | bread | H | TODO | 2026-04-07 | | 29 cal per piece |
| 462 | Protein Tortilla Wrap BFree | BFree | IE | bread | H | TODO | 2026-04-07 | | High protein |
| 464 | Old El Paso Tortilla Wraps | Old El Paso | US | bread | M | TODO | 2026-04-07 | | |
| 466 | Dave's Killer Bread 21 Whole Grains | Dave's Killer Bread | US | bread | M | TODO | 2026-04-07 | | |
| 467 | P28 High Protein Bread | P28 | US | bread | H | TODO | 2026-04-07 | | 28g protein/serving |
| 468 | Hero Bread Zero Net Carb | Hero Bread | US | bread | M | TODO | 2026-04-07 | | |
| 469 | Sola Sweet & Buttery Bread | Sola | US | bread | M | TODO | 2026-04-07 | | |
| 470 | Base Culture Keto Bread | Base Culture | US | bread | M | TODO | 2026-04-07 | | |

## Section 16: Asian Snacks & Treats (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 472 | Mochi Ice Cream Little Moons Mango | Little Moons | GB | dessert | M | TODO | 2026-04-07 | | |
| 473 | Hi-Chew Strawberry | Morinaga | JP | confectionery | M | TODO | 2026-04-07 | | |
| 474 | Hi-Chew Grape | Morinaga | JP | confectionery | L | TODO | 2026-04-07 | | |
| 475 | Meiji Apollo Strawberry Chocolate | Meiji | JP | chocolate | M | TODO | 2026-04-07 | | |
| 476 | Kinoko no Yama Chocolate Mushroom | Meiji | JP | confectionery | M | TODO | 2026-04-07 | | |
| 477 | Takenoko no Sato Chocolate Bamboo | Meiji | JP | confectionery | M | TODO | 2026-04-07 | | |
| 479 | Umaibo Corn Pottage Stick | Yaokin | JP | snack | M | TODO | 2026-04-07 | | |
| 480 | Yan Yan Chocolate Dip | Meiji | JP | snack | M | TODO | 2026-04-07 | | |
| 482 | Samyang Corn Cheese Ramen | Samyang | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 483 | Crown Butter Waffle | Crown | KR | biscuit | M | TODO | 2026-04-07 | | |
| 484 | Haitai French Pie Apple | Haitai | KR | biscuit | M | TODO | 2026-04-07 | | |
| 485 | Orion Choco Pie Banana | Orion | KR | biscuit | M | TODO | 2026-04-07 | | |
| 486 | White Rabbit Creamy Candy | White Rabbit | CN | confectionery | M | TODO | 2026-04-07 | | Chinese icon |
| 487 | Want Want QQ Gummy Peach | Want Want | TW | confectionery | L | TODO | 2026-04-07 | | |
| 488 | Want Want Senbei Rice Crackers | Want Want | TW | snack | M | TODO | 2026-04-07 | | |
| 489 | Pineapple Cake SunnyHills | SunnyHills | TW | biscuit | M | TODO | 2026-04-07 | | Taiwanese specialty |
| 490 | Jack n Jill Chiz Curls | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 491 | Boy Bawang Cornick Garlic | KSK Food Products | PH | snack | M | TODO | 2026-04-07 | | |
| 492 | SkyFlakes Crackers | M.Y. San | PH | biscuit | M | TODO | 2026-04-07 | | |
| 493 | Milo Nuggets | Nestle | PH | snack | M | TODO | 2026-04-07 | | SE Asia snack |
| 494 | Julie's Peanut Butter Sandwich | Julie's | MY | biscuit | M | TODO | 2026-04-07 | | |
| 495 | Munchy's Lexus Cream Sandwich | Munchy's | MY | biscuit | M | TODO | 2026-04-07 | | |
| 496 | Tao Kae Noi Crispy Seaweed Original | Tao Kae Noi | TH | snack | H | TODO | 2026-04-07 | | |
| 497 | Tao Kae Noi Crispy Seaweed Wasabi | Tao Kae Noi | TH | snack | M | TODO | 2026-04-07 | | |
| 498 | Beng Beng Wafer Chocolate | Mayora | ID | chocolate | M | TODO | 2026-04-07 | | |
| 499 | Kopiko Coffee Candy | Kopiko | ID | confectionery | M | TODO | 2026-04-07 | | |
| 500 | Khong Guan Assorted Biscuits | Khong Guan | SG | biscuit | M | TODO | 2026-04-07 | | SE Asia icon |

## Section 17: Middle Eastern & Turkish Foods (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 502 | Halloumi Cheese | Various | CY | dairy | H | TODO | 2026-04-07 | | |
| 508 | Ulker Biskrem Chocolate | Ulker | TR | biscuit | M | TODO | 2026-04-07 | | |
| 509 | Ulker Halley Chocolate Sandwich | Ulker | TR | biscuit | M | TODO | 2026-04-07 | | |
| 510 | Eti Tutku Chocolate Wafer | Eti | TR | biscuit | M | TODO | 2026-04-07 | | |
| 511 | Tahini Halva Plain (per 100g) | Various | TR | confectionery | M | TODO | 2026-04-07 | | |
| 512 | Mastic Gum Elma | Elma | GR | confectionery | L | TODO | 2026-04-07 | | |
| 513 | Al Fakher Dates Filled with Almond | Al Fakher | SA | confectionery | M | TODO | 2026-04-07 | | |
| 515 | Almarai Full Fat Milk 1L | Almarai | SA | dairy | M | TODO | 2026-04-07 | | |
| 516 | Almarai Chocolate Milk | Almarai | SA | dairy | M | TODO | 2026-04-07 | | |
| 517 | Almarai Fresh Juice Orange | Almarai | SA | beverage | M | TODO | 2026-04-07 | | |
| 518 | Nadec Laban (Buttermilk) | Nadec | SA | dairy | M | TODO | 2026-04-07 | | |
| 520 | Vimto Cordial (per serving) | Vimto | GB | beverage | M | TODO | 2026-04-07 | | Huge in Middle East |
| 521 | Maamoul Date Cookie | Various | LB | biscuit | M | TODO | 2026-04-07 | | |
| 522 | Ka'ak Bread Ring (Jerusalem) | Various | PS | bread | M | TODO | 2026-04-07 | | |
| 524 | Shawarma Chicken Wrap (per wrap) | Various | AE | fast_food | H | TODO | 2026-04-07 | | Middle East staple |
| 526 | Fattoush Salad (per serving) | Various | LB | salad | M | TODO | 2026-04-07 | | |
| 528 | Muhammara Red Pepper Dip | Various | SY | dip | M | TODO | 2026-04-07 | | |
| 530 | Za'atar Spice Mix (per tsp) | Various | LB | condiment | L | TODO | 2026-04-07 | | |

## Section 18: Latin American Foods & Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 531 | Guarana Antarctica Soda | Ambev | BR | beverage | M | TODO | 2026-04-07 | | Brazil national soda |
| 536 | Havanna Alfajor Chocolate | Havanna | AR | confectionery | M | TODO | 2026-04-07 | | |
| 537 | Empanada de Carne (per piece) | Various | AR | snack | H | TODO | 2026-04-07 | | |
| 538 | Yerba Mate Taragui (brewed per cup) | Taragui | AR | beverage | M | TODO | 2026-04-07 | | |
| 539 | Modelo Especial Beer | Modelo | MX | beverage | M | TODO | 2026-04-07 | | |
| 541 | Tajin Clasico Seasoning (per tsp) | Tajin | MX | condiment | M | TODO | 2026-04-07 | | |
| 543 | Chamoy Sauce (per tbsp) | Various | MX | condiment | M | TODO | 2026-04-07 | | |
| 544 | Mazapan De La Rosa (per piece) | De La Rosa | MX | confectionery | M | TODO | 2026-04-07 | | |
| 545 | Carlos V Chocolate Bar | Nestle Mexico | MX | chocolate | M | TODO | 2026-04-07 | | |
| 546 | Gansito Marinela | Marinela | MX | biscuit | M | TODO | 2026-04-07 | | |
| 547 | Inca Kola (Peru) | Coca-Cola | PE | beverage | M | TODO | 2026-04-07 | | Peru national soda |
| 548 | Chifles Plantain Chips (Peru) | Various | PE | snack | M | TODO | 2026-04-07 | | |
| 549 | Lucuma Ice Cream (per scoop) | Various | PE | dessert | L | TODO | 2026-04-07 | | |
| 550 | Pupusa Revuelta (per piece) | Various | SV | snack | M | TODO | 2026-04-07 | | |

## Section 19: African Foods & Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 553 | Rooibos Tea (brewed per cup) | Various | ZA | beverage | M | TODO | 2026-04-07 | | |
| 554 | Amarula Cream Liqueur | Amarula | ZA | beverage | L | TODO | 2026-04-07 | | |
| 555 | Nando's Medium PERi-PERi Sauce (per tbsp) | Nando's | ZA | condiment | M | TODO | 2026-04-07 | | |
| 556 | Pronutro Original Cereal | Bokomo | ZA | cereal | M | TODO | 2026-04-07 | | SA breakfast staple |
| 557 | Ouma Rusks Buttermilk | Nola | ZA | biscuit | M | TODO | 2026-04-07 | | |
| 561 | Suya Spice Mix (per tsp) | Various | NG | condiment | M | TODO | 2026-04-07 | | |
| 563 | Indomie Chicken Flavor (Nigeria) | Indomie | NG | instant_noodle | M | TODO | 2026-04-07 | | Diff from Indonesian |
| 564 | Malta Guinness | Guinness | NG | beverage | M | TODO | 2026-04-07 | | |
| 569 | Nyama Choma (per 100g) | Various | KE | protein | M | TODO | 2026-04-07 | | |
| 570 | Tusker Lager Beer (Kenya) | EABL | KE | beverage | L | TODO | 2026-04-07 | | |

## Section 20: Indian Packaged Foods & Brands (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 571 | Threptin Diskettes Chocolate | Raptakos | IN | protein_snack | H | TODO | 2026-04-07 | | India protein classic |
| 572 | Horlicks Health Drink Classic Malt (per serving) | Horlicks | IN | beverage | H | TODO | 2026-04-07 | | |
| 573 | Complan Royale Chocolate (per serving) | Complan | IN | beverage | M | TODO | 2026-04-07 | | |
| 574 | Boost Health Drink (per serving) | Boost | IN | beverage | M | TODO | 2026-04-07 | | |
| 575 | Protinex Original (per serving) | Protinex | IN | protein_powder | H | TODO | 2026-04-07 | | |
| 576 | Ensure Diabetes Care Powder (per serving) | Ensure | IN | protein_powder | M | TODO | 2026-04-07 | | |
| 577 | Dabur Chyawanprash (per tsp) | Dabur | IN | supplement | M | TODO | 2026-04-07 | | |
| 579 | Mother Dairy Paneer (per 100g) | Mother Dairy | IN | dairy | H | TODO | 2026-04-07 | | |
| 580 | Amul Cheese Slice (per slice) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 581 | Amul Butter (per 10g) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 583 | Amul Protein Milkshake Kesar Pista | Amul | IN | protein_drink | H | TODO | 2026-04-07 | | |
| 584 | Paper Boat Thandai | Paper Boat | IN | beverage | M | TODO | 2026-04-07 | | |
| 585 | Bikaji Rasgulla (per piece) | Bikaji | IN | dessert | M | TODO | 2026-04-07 | | |
| 587 | Gits Jalebi Mix (per serving prepared) | Gits | IN | dessert | L | TODO | 2026-04-07 | | |
| 588 | MTR Rava Idli Mix (per serving prepared) | MTR | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 589 | Aashirvaad Multigrain Atta (per roti) | Aashirvaad | IN | staple | H | TODO | 2026-04-07 | | |
| 590 | Saffola Gold Oil (per tbsp) | Saffola | IN | cooking | M | TODO | 2026-04-07 | | |
| 591 | Too Yumm Multigrain Chips | Too Yumm | IN | snack | M | TODO | 2026-04-07 | | Baked not fried |
| 592 | Cornitos Nacho Crisps Cheese & Herbs | Cornitos | IN | snack | M | TODO | 2026-04-07 | | |
| 593 | ACT II Instant Popcorn Butter | ACT II | IN | snack | M | TODO | 2026-04-07 | | |
| 594 | Lijjat Papad (per piece) | Lijjat | IN | snack | M | TODO | 2026-04-07 | | |
| 595 | Everest Kitchen King Masala (per tsp) | Everest | IN | condiment | M | TODO | 2026-04-07 | | |
| 596 | MDH Chana Masala (per tsp) | MDH | IN | condiment | M | TODO | 2026-04-07 | | |
| 597 | Priya Mango Pickle (per tbsp) | Priya | IN | condiment | M | TODO | 2026-04-07 | | |
| 598 | Mother's Recipe Mixed Pickle (per tbsp) | Mother's | IN | condiment | M | TODO | 2026-04-07 | | |
| 600 | Hajmola Candy (per piece) | Dabur | IN | confectionery | L | TODO | 2026-04-07 | | |

## Section 21: European Specialty Foods (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 602 | Camembert Isigny (per 30g) | Isigny | FR | dairy | M | TODO | 2026-04-07 | | |
| 603 | Comte Cheese (per 30g) | Various | FR | dairy | M | TODO | 2026-04-07 | | |
| 604 | Croissant Au Beurre (per piece) | Various | FR | bread | H | TODO | 2026-04-07 | | |
| 606 | Crepe Suzette (per piece) | Various | FR | dessert | M | TODO | 2026-04-07 | | |
| 607 | Danette Chocolate Pudding | Danone | FR | dessert | M | TODO | 2026-04-07 | | |
| 608 | Orangina Sparkling Citrus | Orangina | FR | beverage | M | TODO | 2026-04-07 | | |
| 609 | Parmigiano Reggiano (per 30g) | Various | IT | dairy | H | TODO | 2026-04-07 | | |
| 610 | Mozzarella di Bufala (per 100g) | Various | IT | dairy | M | TODO | 2026-04-07 | | |
| 611 | Prosciutto di Parma (per 30g) | Various | IT | protein | M | TODO | 2026-04-07 | | |
| 612 | Grissini Breadsticks (per piece) | Various | IT | bread | M | TODO | 2026-04-07 | | |
| 616 | Manchego Cheese (per 30g) | Various | ES | dairy | M | TODO | 2026-04-07 | | |
| 618 | Churros con Chocolate (per serving) | Various | ES | dessert | M | TODO | 2026-04-07 | | |
| 619 | Gazpacho Alvalle (per serving) | Alvalle | ES | soup | M | TODO | 2026-04-07 | | |
| 621 | Edammer Cheese (per 30g) | Various | NL | dairy | M | TODO | 2026-04-07 | | |
| 623 | Bitterballen (per piece) | Various | NL | snack | M | TODO | 2026-04-07 | | |
| 624 | Bratwurst Sausage (per piece) | Various | DE | protein | H | TODO | 2026-04-07 | | |
| 625 | Currywurst with Sauce (per serving) | Various | DE | fast_food | M | TODO | 2026-04-07 | | |
| 626 | Pretzel Soft German (per piece) | Various | DE | bread | M | TODO | 2026-04-07 | | |
| 630 | Swedish Meatballs IKEA (per 5 pieces) | IKEA | SE | protein | H | TODO | 2026-04-07 | | |
| 631 | Knackebrod Crispbread (per piece) | Various | SE | bread | M | TODO | 2026-04-07 | | |
| 632 | Kanelbulle Cinnamon Bun (per piece) | Various | SE | bread | M | TODO | 2026-04-07 | | |
| 633 | Smoked Salmon Norwegian (per 30g) | Various | NO | protein | H | TODO | 2026-04-07 | | |
| 634 | Brown Cheese Brunost (per 20g) | Various | NO | dairy | M | TODO | 2026-04-07 | | |
| 635 | Pierogi Ruskie (per piece) | Various | PL | snack | M | TODO | 2026-04-07 | | |
| 636 | Kielbasa Polish Sausage (per link) | Various | PL | protein | M | TODO | 2026-04-07 | | |
| 637 | Paczki Donut (per piece) | Various | PL | dessert | M | TODO | 2026-04-07 | | |
| 640 | Bougatsa Cream Pie (per piece) | Various | GR | dessert | M | TODO | 2026-04-07 | | |

## Section 22: Health & Diet Brands (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 641 | Skinny Food Co Syrup Zero Calorie Maple | Skinny Food Co | GB | condiment | H | TODO | 2026-04-07 | | |
| 642 | Skinny Food Co Syrup Zero Calorie Chocolate | Skinny Food Co | GB | condiment | M | TODO | 2026-04-07 | | |
| 643 | Skinny Food Co Sauce Zero Calorie Ketchup | Skinny Food Co | GB | condiment | M | TODO | 2026-04-07 | | |
| 646 | ChocZero Sugar Free Chocolate Hazelnut Spread | ChocZero | US | spread | M | TODO | 2026-04-07 | | |
| 647 | Good Good Sweet Jam Strawberry | Good Good | IS | spread | M | TODO | 2026-04-07 | | |
| 648 | Choc Shot Hot Chocolate (per serving) | Choc Shot | GB | beverage | M | TODO | 2026-04-07 | | |
| 649 | Slender Chef Protein Pasta (per serving) | Slender Chef | SE | pasta | H | TODO | 2026-04-07 | | |
| 650 | Explore Cuisine Edamame Spaghetti | Explore Cuisine | US | pasta | H | TODO | 2026-04-07 | | |
| 653 | Konjac Noodles (Shirataki) Skinny Pasta | Various | JP | pasta | H | TODO | 2026-04-07 | | Near zero cal |
| 654 | Slendier Slim Pasta Spaghetti | Slendier | AU | pasta | M | TODO | 2026-04-07 | | |
| 655 | Nick's Light Ice Cream Swedish Chocolate | Nick's | SE | dessert | H | TODO | 2026-04-07 | | Low cal ice cream |
| 656 | Nick's Light Ice Cream Peanut Butter Cup | Nick's | SE | dessert | M | TODO | 2026-04-07 | | |
| 657 | Oppo Brothers Salted Caramel Ice Cream | Oppo | GB | dessert | M | TODO | 2026-04-07 | | |
| 660 | Arctic Zero Chocolate Peanut Butter | Arctic Zero | US | dessert | M | TODO | 2026-04-07 | | |
| 666 | Project 7 Low Sugar Gummies | Project 7 | US | confectionery | L | TODO | 2026-04-07 | | |

## Section 23: Plant-Based / Vegan Brands (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 671 | Beyond Meat Beyond Burger (per patty) | Beyond Meat | US | meat_alt | H | TODO | 2026-04-07 | | |
| 672 | Beyond Meat Beyond Sausage Italian (per link) | Beyond Meat | US | meat_alt | M | TODO | 2026-04-07 | | |
| 676 | Oatly Chocolate Oat Milk | Oatly | SE | dairy_alt | M | TODO | 2026-04-07 | | |
| 677 | Alpro Soya Original | Alpro | BE | dairy_alt | M | TODO | 2026-04-07 | | |
| 678 | Alpro Oat Milk Barista | Alpro | BE | dairy_alt | M | TODO | 2026-04-07 | | |
| 680 | Violife Mature Cheddar Slices | Violife | GR | dairy_alt | M | TODO | 2026-04-07 | | |
| 681 | Miyoko's Creamery Cultured Vegan Butter | Miyoko's | US | dairy_alt | M | TODO | 2026-04-07 | | |
| 683 | Ripple Pea Protein Milk Original | Ripple | US | dairy_alt | M | TODO | 2026-04-07 | | |
| 685 | Tofurky Plant-Based Deli Slices Hickory Smoked | Tofurky | US | meat_alt | M | TODO | 2026-04-07 | | |
| 686 | Lightlife Plant-Based Burger | Lightlife | US | meat_alt | M | TODO | 2026-04-07 | | |
| 687 | THIS Isn't Chicken Plant-Based Pieces | THIS | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 688 | THIS Isn't Bacon Plant-Based Rashers | THIS | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 689 | Moving Mountains Plant-Based Burger | Moving Mountains | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 690 | Vivera Plant Steak | Vivera | NL | meat_alt | M | TODO | 2026-04-07 | | |
| 691 | The Vegetarian Butcher No Chicken Chunks | The Vegetarian Butcher | NL | meat_alt | M | TODO | 2026-04-07 | | |
| 692 | Heura Mediterranean Chicken Chunks | Heura | ES | meat_alt | M | TODO | 2026-04-07 | | |
| 693 | Like Meat Like Chicken | Like Meat | DE | meat_alt | M | TODO | 2026-04-07 | | |
| 695 | GoodDot Proteiz (per serving) | GoodDot | IN | meat_alt | M | TODO | 2026-04-07 | | India plant-based pioneer |
| 696 | Blue Tribe Plant-Based Chicken Keema | Blue Tribe | IN | meat_alt | M | TODO | 2026-04-07 | | |

## Section 24: International Rice, Grain & Staple Products (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 701 | Uncle Ben's Ready Rice Basmati | Uncle Ben's | US | staple | M | TODO | 2026-04-07 | | |
| 703 | Nishiki Sushi Rice (cooked per 100g) | Nishiki | JP | staple | M | TODO | 2026-04-07 | | |
| 708 | Bulgur Wheat Cooked (per 100g) | Various | TR | staple | M | TODO | 2026-04-07 | | |
| 710 | Teff Grain Cooked (per 100g) | Various | ET | staple | M | TODO | 2026-04-07 | | |
| 713 | Soba Noodles Cooked (per 100g) | Various | JP | staple | M | TODO | 2026-04-07 | | |
| 714 | Udon Noodles Cooked (per 100g) | Various | JP | staple | M | TODO | 2026-04-07 | | |
| 715 | Glass Noodles (Japchae) Cooked (per 100g) | Various | KR | staple | M | TODO | 2026-04-07 | | |
| 717 | Ragi Malt (per serving) | Various | IN | staple | M | TODO | 2026-04-07 | | South Indian health drink |
| 718 | Jowar Roti (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |
| 720 | Millet Dosa (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |

## Section 25: Protein Ice Cream & Frozen Treats (10 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 725 | Wheyhey Protein Ice Cream Chocolate | Wheyhey | GB | dessert | M | TODO | 2026-04-07 | | |
| 726 | Wheyhey Protein Ice Cream Banoffee | Wheyhey | GB | dessert | M | TODO | 2026-04-07 | | |
| 727 | Breyers Carb Smart Vanilla | Breyers | US | dessert | M | TODO | 2026-04-07 | | |
| 728 | So Delicious Dairy Free Cashew Milk Salted Caramel | So Delicious | US | dessert | M | TODO | 2026-04-07 | | |
| 730 | Cornetto Classic (per cone) | Wall's | GB | dessert | M | TODO | 2026-04-07 | | |

## Section 26: Meal Replacement & Complete Foods (10 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 731 | AG1 Athletic Greens (per serving) | Athletic Greens | US | supplement | H | TODO | 2026-04-07 | | |
| 732 | Huel Daily Greens (per serving) | Huel | GB | supplement | M | TODO | 2026-04-07 | | |
| 734 | Huel Hot & Savoury Mac & Cheese | Huel | GB | meal_replacement | M | TODO | 2026-04-07 | | |
| 735 | Huel Bar Chocolate Orange | Huel | GB | meal_replacement | M | TODO | 2026-04-07 | | |
| 736 | Soylent Squared Bar Chocolate Brownie | Soylent | US | meal_replacement | M | TODO | 2026-04-07 | | |
| 737 | Feed Light Meal Chocolate | Feed | FR | meal_replacement | M | TODO | 2026-04-07 | | |
| 738 | Queal Steady Standard Chocolate | Queal | NL | meal_replacement | L | TODO | 2026-04-07 | | |
| 739 | Ambronite Complete Meal Shake Ginger Apple | Ambronite | FI | meal_replacement | L | TODO | 2026-04-07 | | |
| 740 | Bertrand Classic Organic Meal Shake | Bertrand | DE | meal_replacement | L | TODO | 2026-04-07 | | |

## Section 27: International Coffee Drinks (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 741 | Starbucks Doubleshot Espresso Can | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 742 | Starbucks Frappuccino Mocha Bottle | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 743 | Georgia Coffee Max Coffee (Japan) | Coca-Cola Japan | JP | beverage | M | TODO | 2026-04-07 | | Japanese canned coffee |
| 745 | BOSS Coffee Rainbow Mountain | Suntory | JP | beverage | M | TODO | 2026-04-07 | | |
| 746 | Nescafe Gold Instant Coffee (per cup) | Nescafe | CH | beverage | M | TODO | 2026-04-07 | | |
| 747 | Bru Instant Coffee (per cup) | Bru | IN | beverage | M | TODO | 2026-04-07 | | India popular |
| 748 | Nescafe Classic (India per cup) | Nescafe | IN | beverage | M | TODO | 2026-04-07 | | |
| 751 | Turkish Coffee (per cup) | Various | TR | beverage | M | TODO | 2026-04-07 | | |
| 752 | Greek Frappe Coffee (per cup) | Various | GR | beverage | M | TODO | 2026-04-07 | | |
| 753 | Costa Coffee RTD Latte Can | Costa | GB | beverage | M | TODO | 2026-04-07 | | |
| 755 | Oatly Barista Oat Latte RTD | Oatly | SE | beverage | M | TODO | 2026-04-07 | | |

## Section 28: Fitness Supplements (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 758 | Creatine HCl Kaged (per serving) | Kaged | US | supplement | M | TODO | 2026-04-07 | | |
| 760 | Pre-Workout Ghost Legend Sour Patch (per serving) | Ghost | US | supplement | M | TODO | 2026-04-07 | | |
| 761 | Pre-Workout Gorilla Mode (per serving) | Gorilla Mind | US | supplement | M | TODO | 2026-04-07 | | |
| 762 | BCAA Scivation Xtend Blue Raspberry (per serving) | Scivation | US | supplement | M | TODO | 2026-04-07 | | |
| 763 | EAA Applied Nutrition (per serving) | Applied Nutrition | GB | supplement | M | TODO | 2026-04-07 | | |
| 764 | Glutamine Powder (per 5g) | Various | US | supplement | L | TODO | 2026-04-07 | | |
| 765 | Fish Oil Triple Strength (per softgel) | Various | US | supplement | M | TODO | 2026-04-07 | | |
| 766 | Multivitamin Animal Pak (per serving) | Universal | US | supplement | M | TODO | 2026-04-07 | | |
| 767 | ZMA Optimum Nutrition (per serving) | Optimum Nutrition | US | supplement | L | TODO | 2026-04-07 | | |
| 768 | Ashwagandha KSM-66 (per capsule) | Various | IN | supplement | M | TODO | 2026-04-07 | | |
| 769 | Mass Gainer Serious Mass Chocolate (per serving) | Optimum Nutrition | US | supplement | M | TODO | 2026-04-07 | | |
| 770 | Casein Protein Gold Standard Chocolate (per scoop) | Optimum Nutrition | US | protein_powder | M | TODO | 2026-04-07 | | |

## Section 29: International Tea & Traditional Drinks (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 771 | Matcha Latte (per serving) | Various | JP | beverage | H | TODO | 2026-04-07 | | With milk |
| 774 | Tata Tea Gold (per cup brewed) | Tata | IN | beverage | M | TODO | 2026-04-07 | | |
| 775 | Wagh Bakri Instant Tea Premix (per sachet) | Wagh Bakri | IN | beverage | M | TODO | 2026-04-07 | | |
| 776 | Bubble Tea Taro Milk Tea (per 500ml) | Various | TW | beverage | H | TODO | 2026-04-07 | | |
| 778 | Teh Tarik (Malaysian Pulled Tea per cup) | Various | MY | beverage | M | TODO | 2026-04-07 | | |
| 779 | Barley Tea (Mugicha per cup) | Various | JP | beverage | M | TODO | 2026-04-07 | | |
| 780 | Genmaicha (per cup) | Various | JP | beverage | L | TODO | 2026-04-07 | | |
| 781 | Yuzu Tea (Korean Yuja per cup) | Various | KR | beverage | M | TODO | 2026-04-07 | | |
| 782 | Chrysanthemum Tea (per cup) | Various | CN | beverage | L | TODO | 2026-04-07 | | |
| 783 | Hibiscus Tea Agua de Jamaica (per cup) | Various | MX | beverage | M | TODO | 2026-04-07 | | |
| 785 | Atole de Chocolate (per cup) | Various | MX | beverage | M | TODO | 2026-04-07 | | |
| 788 | Kombucha GT's Original (per bottle) | GT's | US | beverage | M | TODO | 2026-04-07 | | |
| 789 | Kombucha GT's Gingerade (per bottle) | GT's | US | beverage | M | TODO | 2026-04-07 | | |
| 790 | Turmeric Latte Golden Milk (per cup) | Various | IN | beverage | M | TODO | 2026-04-07 | | |

## Section 30: Fast Food International Chains (30 items)

| # | Food Name | Brand | Country | Restaurant | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|------------|----------|----------|--------|------------|----------------|-------|
| 793 | Jollibee Yumburger | Jollibee | PH | Jollibee | fast_food | M | TODO | 2026-04-07 | | |
| 795 | Nando's Peri-Peri Chicken Thigh | Nando's | ZA | Nando's | fast_food | M | TODO | 2026-04-07 | | |
| 805 | Tim Hortons Original Donut | Tim Hortons | CA | Tim Hortons | fast_food | M | TODO | 2026-04-07 | | |
| 806 | Tim Hortons Timbits (per piece) | Tim Hortons | CA | Tim Hortons | fast_food | M | TODO | 2026-04-07 | | |
| 807 | Harvey's Original Burger | Harvey's | CA | Harvey's | fast_food | M | TODO | 2026-04-07 | | |
| 808 | Mary Brown's Big Mary Chicken Sandwich | Mary Brown's | CA | Mary Brown's | fast_food | M | TODO | 2026-04-07 | | |
| 810 | A2B (Adyar Ananda Bhavan) Ghee Pongal | A2B | IN | A2B | fast_food | M | TODO | 2026-04-07 | | |
| 812 | Barbeque Nation Chicken Starter (per piece) | Barbeque Nation | IN | Barbeque Nation | fast_food | M | TODO | 2026-04-07 | | |
| 813 | Max Burgers Original (Sweden) | Max | SE | Max Burgers | fast_food | M | TODO | 2026-04-07 | | |
| 814 | Hesburger Cheese Burger (Finland) | Hesburger | FI | Hesburger | fast_food | M | TODO | 2026-04-07 | | |
| 815 | Mos Burger Rice Burger Yakiniku | Mos Burger | JP | Mos Burger | fast_food | M | TODO | 2026-04-07 | | |
| 816 | Yoshinoya Beef Bowl Regular | Yoshinoya | JP | Yoshinoya | fast_food | H | TODO | 2026-04-07 | | |
| 817 | CoCo Ichibanya Curry Rice Pork Cutlet | CoCo Ichibanya | JP | CoCo Ichibanya | fast_food | M | TODO | 2026-04-07 | | |
| 818 | Lotteria Teriyaki Burger | Lotteria | KR | Lotteria | fast_food | M | TODO | 2026-04-07 | | |

## Section 31: Trending / Viral Foods (20 items)

| # | Food Name | Brand | Country | Restaurant | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|------------|----------|----------|--------|------------|----------------|-------|
| 821 | Dubai Chocolate Bar Fix Dessert Chocolatier | Fix Dessert | AE | | chocolate | H | TODO | 2026-04-07 | | Viral pistachio kunafa chocolate |
| 822 | Crumbl Cookie Chocolate Chip (per cookie) | Crumbl | US | Crumbl | dessert | H | TODO | 2026-04-07 | | Viral bakery chain |
| 823 | Crumbl Cookie Pink Sugar (per cookie) | Crumbl | US | Crumbl | dessert | M | TODO | 2026-04-07 | | |
| 824 | Crumbl Cookie Biscoff Lava (per cookie) | Crumbl | US | Crumbl | dessert | M | TODO | 2026-04-07 | | |
| 825 | Boba Guys Classic Milk Tea (per 16oz) | Boba Guys | US | Boba Guys | beverage | M | TODO | 2026-04-07 | | |
| 829 | Insomnia Cookies Classic Chocolate Chunk (per cookie) | Insomnia Cookies | US | Insomnia Cookies | dessert | M | TODO | 2026-04-07 | | |
| 830 | Levain Bakery Chocolate Chip Walnut Cookie | Levain Bakery | US | Levain Bakery | dessert | M | TODO | 2026-04-07 | | |
| 831 | Biscoff Ice Cream Ben & Jerry's | Ben & Jerry's | US | | dessert | M | TODO | 2026-04-07 | | |
| 832 | Lotus Biscoff Ice Cream | Lotus | BE | | dessert | M | TODO | 2026-04-07 | | |
| 835 | Doritos Dinamita Chile Limon | Doritos | US | | snack | M | TODO | 2026-04-07 | | |
| 836 | Trader Joe's Everything But The Bagel Seasoning (per tsp) | Trader Joe's | US | | condiment | M | TODO | 2026-04-07 | | |
| 837 | Trader Joe's Cauliflower Gnocchi | Trader Joe's | US | | frozen_meal | M | TODO | 2026-04-07 | | |

## Section 32: Australian & New Zealand Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 841 | Vegemite on Toast (per serve) | Bega | AU | breakfast | M | TODO | 2026-04-07 | | |
| 842 | Weet-Bix Original (per 2 biscuits) | Sanitarium | AU | cereal | H | TODO | 2026-04-07 | | Aus/NZ staple |
| 843 | Weet-Bix Protein (per 2 biscuits) | Sanitarium | AU | cereal | H | TODO | 2026-04-07 | | |
| 844 | Uncle Toby's Quick Oats (per serving) | Uncle Toby's | AU | cereal | M | TODO | 2026-04-07 | | |
| 845 | Farmers Union Iced Coffee | Farmers Union | AU | beverage | M | TODO | 2026-04-07 | | SA icon |
| 846 | Dare Iced Coffee Double Espresso | Dare | AU | beverage | M | TODO | 2026-04-07 | | |
| 848 | Cherry Ripe Chocolate Bar | Cadbury | AU | chocolate | M | TODO | 2026-04-07 | | Aus exclusive |
| 849 | Violet Crumble Chocolate Bar | Robern Menz | AU | chocolate | M | TODO | 2026-04-07 | | |
| 850 | Meat Pie Four'N Twenty (per pie) | Four'N Twenty | AU | fast_food | H | TODO | 2026-04-07 | | Aus icon |
| 851 | Sausage Roll Four'N Twenty (per roll) | Four'N Twenty | AU | fast_food | M | TODO | 2026-04-07 | | |
| 854 | L&P Lemon & Paeroa Soda | L&P | NZ | beverage | M | TODO | 2026-04-07 | | NZ icon |
| 856 | Whittaker's Dark Ghana Peppermint | Whittaker's | NZ | chocolate | M | TODO | 2026-04-07 | | |
| 857 | Cookie Time Original Chocolate Chip | Cookie Time | NZ | biscuit | M | TODO | 2026-04-07 | | NZ icon |
| 858 | Marmite NZ (different from UK) | Sanitarium | NZ | spread | M | TODO | 2026-04-07 | | |
| 859 | Pineapple Lumps | Cadbury NZ | NZ | confectionery | M | TODO | 2026-04-07 | | NZ classic |
| 860 | Barker's Fruit Syrup Boysenberry (per serving) | Barker's | NZ | condiment | L | TODO | 2026-04-07 | | |

## Section 33: Russian & Eastern European Foods (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 861 | Pelmeni Russian Dumplings (per 5 pieces) | Various | RU | snack | M | TODO | 2026-04-07 | | |
| 862 | Blini Russian Pancakes (per piece) | Various | RU | bread | M | TODO | 2026-04-07 | | |
| 865 | Varenyky Ukrainian Dumplings (per 5 pieces) | Various | UA | snack | M | TODO | 2026-04-07 | | |
| 866 | Kvass Ochakovo (per 250ml) | Ochakovo | RU | beverage | M | TODO | 2026-04-07 | | |
| 867 | Zefir Russian Marshmallow (per piece) | Various | RU | confectionery | M | TODO | 2026-04-07 | | |
| 868 | Ptichye Moloko Bird's Milk Cake (per piece) | Various | RU | confectionery | M | TODO | 2026-04-07 | | |
| 869 | Alyonka Chocolate Bar | Kommunarka | RU | chocolate | M | TODO | 2026-04-07 | | Russian icon |
| 870 | Langos Hungarian Fried Bread (per piece) | Various | HU | bread | M | TODO | 2026-04-07 | | |
| 872 | Kolace Czech Pastry (per piece) | Various | CZ | dessert | M | TODO | 2026-04-07 | | |
| 873 | Cevapcici Balkan Sausage (per 5 pieces) | Various | BA | protein | M | TODO | 2026-04-07 | | |
| 874 | Burek Meat Pie (per piece) | Various | BA | snack | M | TODO | 2026-04-07 | | |
| 875 | Rakija Plum Brandy (per shot) | Various | RS | beverage | L | TODO | 2026-04-07 | | |

## Section 34: Southeast Asian Foods (25 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 876 | Nasi Lemak Coconut Rice (per serving) | Various | MY | rice | H | TODO | 2026-04-07 | | Malaysian national dish |
| 877 | Roti Canai (per piece) | Various | MY | bread | M | TODO | 2026-04-07 | | |
| 878 | Char Kway Teow (per serving) | Various | MY | noodle | M | TODO | 2026-04-07 | | |
| 879 | Bak Kut Teh (per serving) | Various | MY | soup | M | TODO | 2026-04-07 | | |
| 880 | Hainanese Chicken Rice (per plate) | Various | SG | rice | H | TODO | 2026-04-07 | | Singapore national dish |
| 882 | Kaya Toast Set (per serving) | Various | SG | breakfast | M | TODO | 2026-04-07 | | |
| 883 | Chili Crab Singapore (per serving) | Various | SG | protein | M | TODO | 2026-04-07 | | |
| 885 | Som Tum Green Papaya Salad (per serving) | Various | TH | salad | M | TODO | 2026-04-07 | | |
| 886 | Tom Kha Gai (per serving) | Various | TH | soup | M | TODO | 2026-04-07 | | |
| 888 | Pho Bo Vietnamese Beef (per serving) | Various | VN | noodle | H | TODO | 2026-04-07 | | |
| 890 | Goi Cuon Spring Roll (per roll) | Various | VN | snack | M | TODO | 2026-04-07 | | |
| 891 | Ca Phe Trung Egg Coffee (per cup) | Various | VN | beverage | M | TODO | 2026-04-07 | | |
| 892 | Nasi Goreng (per serving) | Various | ID | rice | H | TODO | 2026-04-07 | | |
| 893 | Satay Chicken (per stick) | Various | ID | protein | M | TODO | 2026-04-07 | | |
| 894 | Rendang Beef (per serving) | Various | ID | protein | M | TODO | 2026-04-07 | | |
| 895 | Lumpia Shanghai (per piece) | Various | PH | snack | M | TODO | 2026-04-07 | | |
| 896 | Adobo Chicken (per serving) | Various | PH | protein | H | TODO | 2026-04-07 | | Filipino national dish |
| 897 | Sinigang Pork (per serving) | Various | PH | soup | M | TODO | 2026-04-07 | | |
| 898 | Halo-Halo (per serving) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 899 | Mohinga Fish Noodle Soup (per serving) | Various | MM | noodle | M | TODO | 2026-04-07 | | Myanmar national dish |
| 900 | Amok Fish Curry (per serving) | Various | KH | protein | M | TODO | 2026-04-07 | | Cambodian national dish |

## Section 35: Japanese Convenience Store Foods (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 901 | Onigiri Tuna Mayo (per piece) | Various | JP | snack | H | TODO | 2026-04-07 | | 7-Eleven Japan |
| 902 | Onigiri Salmon (per piece) | Various | JP | snack | H | TODO | 2026-04-07 | | |
| 903 | Onigiri Umeboshi (per piece) | Various | JP | snack | M | TODO | 2026-04-07 | | |
| 904 | Karaage Chicken (per 100g) | Various | JP | protein | H | TODO | 2026-04-07 | | |
| 905 | Nikuman Steamed Pork Bun (per piece) | Various | JP | snack | M | TODO | 2026-04-07 | | |
| 906 | Egg Sandwich Konbini (per pack) | Various | JP | fast_food | M | TODO | 2026-04-07 | | |
| 907 | Japanese Cheesecake Uncle Tetsu (per piece) | Uncle Tetsu | JP | dessert | M | TODO | 2026-04-07 | | |
| 908 | Melon Pan (per piece) | Various | JP | bread | M | TODO | 2026-04-07 | | |
| 909 | Taiyaki Red Bean (per piece) | Various | JP | dessert | M | TODO | 2026-04-07 | | |
| 911 | Okonomiyaki (per serving) | Various | JP | snack | M | TODO | 2026-04-07 | | |
| 912 | Gyudon Beef Bowl (per serving) | Various | JP | fast_food | H | TODO | 2026-04-07 | | |
| 913 | Japanese Curry Rice (per serving) | Various | JP | fast_food | M | TODO | 2026-04-07 | | |
| 914 | Mochi Daifuku Red Bean (per piece) | Various | JP | dessert | M | TODO | 2026-04-07 | | |
| 915 | Matcha Kit Kat Mini (per piece) | Nestle | JP | chocolate | M | TODO | 2026-04-07 | | |

## Section 36: Korean Convenience Store & Street Food (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 917 | Korean Corn Dog (per piece) | Various | KR | snack | H | TODO | 2026-04-07 | | |
| 918 | Kimbap Classic (per roll) | Various | KR | snack | H | TODO | 2026-04-07 | | |
| 922 | Japchae Glass Noodles (per serving) | Various | KR | noodle | M | TODO | 2026-04-07 | | |
| 924 | Hotteok Sweet Pancake (per piece) | Various | KR | dessert | M | TODO | 2026-04-07 | | |
| 925 | Bingsu Patbingsu (per serving) | Various | KR | dessert | M | TODO | 2026-04-07 | | |
| 926 | Samgak Kimbap Triangle (per piece) | Various | KR | snack | M | TODO | 2026-04-07 | | Konbini |
| 928 | Soju Flavored Peach (per shot) | Various | KR | beverage | L | TODO | 2026-04-07 | | |
| 930 | Dakgangjeong Sweet Crispy Chicken (per 100g) | Various | KR | protein | M | TODO | 2026-04-07 | | |

## Section 37: Chinese Staples & Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 931 | Dim Sum Har Gow Shrimp Dumpling (per piece) | Various | CN | snack | H | TODO | 2026-04-07 | | |
| 932 | Dim Sum Siu Mai Pork Dumpling (per piece) | Various | CN | snack | H | TODO | 2026-04-07 | | |
| 933 | Char Siu BBQ Pork (per 100g) | Various | CN | protein | H | TODO | 2026-04-07 | | |
| 934 | Xiao Long Bao Soup Dumpling (per piece) | Various | CN | snack | H | TODO | 2026-04-07 | | |
| 936 | Baozi Steamed Bun Pork (per piece) | Various | CN | snack | M | TODO | 2026-04-07 | | |
| 937 | Congee Rice Porridge Plain (per serving) | Various | CN | breakfast | M | TODO | 2026-04-07 | | |
| 938 | Zongzi Rice Dumpling (per piece) | Various | CN | snack | M | TODO | 2026-04-07 | | |
| 939 | Mooncake Lotus Seed (per piece) | Various | CN | dessert | M | TODO | 2026-04-07 | | |
| 940 | Egg Tart Portuguese Style (per piece) | Various | HK | dessert | M | TODO | 2026-04-07 | | |
| 941 | Pineapple Bun Bo Lo Bao (per piece) | Various | HK | bread | M | TODO | 2026-04-07 | | |
| 942 | Wonton Noodle Soup (per serving) | Various | HK | noodle | M | TODO | 2026-04-07 | | |
| 943 | Soy Milk Sweetened (per 250ml) | Various | CN | beverage | M | TODO | 2026-04-07 | | |
| 944 | Bubble Waffle Egg Puff (per piece) | Various | HK | dessert | M | TODO | 2026-04-07 | | |
| 945 | Master Kong Instant Noodles Braised Beef | Master Kong | CN | instant_noodle | M | TODO | 2026-04-07 | | China #1 brand |
| 946 | Uni-President Instant Noodles Beef | Uni-President | TW | instant_noodle | M | TODO | 2026-04-07 | | |
| 947 | Lao Gan Ma Spicy Diced Chicken Oil | Lao Gan Ma | CN | condiment | M | TODO | 2026-04-07 | | |

## Section 38: Fitness Meal Prep Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 953 | Trifecta Organic Grass-Fed Beef | Trifecta | US | meal_prep | M | TODO | 2026-04-07 | | |
| 954 | Icon Meals Grilled Chicken & Rice | Icon Meals | US | meal_prep | M | TODO | 2026-04-07 | | |
| 956 | My Muscle Chef Chicken Pad Thai | My Muscle Chef | AU | meal_prep | M | TODO | 2026-04-07 | | |
| 957 | My Muscle Chef Beef Bolognese | My Muscle Chef | AU | meal_prep | M | TODO | 2026-04-07 | | |
| 958 | Macro Mike Protein Pancake Mix (per serving) | Macro Mike | AU | breakfast | M | TODO | 2026-04-07 | | |
| 967 | Evolve Plant Based Protein Shake Chocolate | Evolve | US | protein_drink | M | TODO | 2026-04-07 | | |
| 968 | OATHAUS Granola Butter Original | OATHAUS | US | spread | M | TODO | 2026-04-07 | | TikTok viral |

## Section 39: Additional International Niche Items (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 971 | Pocari Sweat Powder (per serving) | Otsuka | JP | sports_drink | M | TODO | 2026-04-07 | | |
| 972 | Aquarius Zero Sports Drink | Coca-Cola Japan | JP | sports_drink | M | TODO | 2026-04-07 | | |
| 973 | Calpis Concentrate (per serving) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | |
| 975 | Ajinomoto Gyoza Frozen (per 5 pieces) | Ajinomoto | JP | frozen_meal | M | TODO | 2026-04-07 | | |
| 976 | CJ Bibigo Mandu Dumplings (per 5 pieces) | CJ | KR | frozen_meal | H | TODO | 2026-04-07 | | |
| 977 | Ottogi Curry Mild (per serving) | Ottogi | KR | ready_meal | M | TODO | 2026-04-07 | | |
| 978 | Vita Plus Dalandan Juice (Philippines) | Vita Plus | PH | beverage | L | TODO | 2026-04-07 | | |
| 980 | Vitamilk Soy Milk Original | Vitamilk | TH | beverage | M | TODO | 2026-04-07 | | |
| 982 | Indomilk Condensed Milk (per tbsp) | Indomilk | ID | dairy | M | TODO | 2026-04-07 | | |
| 983 | Abon (Indonesian Meat Floss per tbsp) | Various | ID | protein | M | TODO | 2026-04-07 | | |
| 984 | Kerupuk Udang Shrimp Crackers (per 5 pieces) | Various | ID | snack | M | TODO | 2026-04-07 | | |
| 985 | Shan Biryani Masala (per serving mix) | Shan | PK | condiment | M | TODO | 2026-04-07 | | |
| 986 | National Achar Gosht Masala (per serving) | National | PK | condiment | L | TODO | 2026-04-07 | | |
| 987 | Tapal Danedar Tea (per cup brewed) | Tapal | PK | beverage | M | TODO | 2026-04-07 | | Pakistan #1 tea |
| 988 | Olper's Full Cream Milk (per 250ml) | Olper's | PK | dairy | M | TODO | 2026-04-07 | | |
| 989 | Nurpur Butter (per 10g) | Nurpur | PK | dairy | M | TODO | 2026-04-07 | | |
| 990 | Dawn Paratha (per piece) | Dawn | PK | bread | M | TODO | 2026-04-07 | | Pakistan frozen |
| 991 | Knorr Noodles Chatpata (Pakistan) | Knorr | PK | instant_noodle | M | TODO | 2026-04-07 | | |
| 992 | Kolson Slanty Chips | Kolson | PK | snack | M | TODO | 2026-04-07 | | |
| 993 | Milo Australia RTD (different formula) | Nestle | AU | beverage | M | TODO | 2026-04-07 | | |
| 994 | Up&Go Liquid Breakfast Chocolate | Sanitarium | AU | meal_replacement | M | TODO | 2026-04-07 | | Aus breakfast staple |
| 995 | Shapes Chicken Crimpy | Arnott's | AU | snack | M | TODO | 2026-04-07 | | |
| 996 | Golden Gaytime Ice Cream Bar | Streets | AU | dessert | M | TODO | 2026-04-07 | | Aus icon |
| 997 | Zooper Dooper Ice Block (per stick) | Zooper Dooper | AU | dessert | L | TODO | 2026-04-07 | | |
| 998 | Magnum Double Gold Caramel Billionaire | Magnum | AU | dessert | M | TODO | 2026-04-07 | | |
| 999 | Cottee's Cordial Coola (per serving) | Cottee's | AU | beverage | L | TODO | 2026-04-07 | | |
| 1000 | Schweppes Lemon Lime Bitters | Schweppes | AU | beverage | M | TODO | 2026-04-07 | | |

## Section 40: Bonus - More Niche Fitness & International (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1001 | Mr. Iron 30% Protein Cereals Vanilla | Mr. Iron | EU | protein_cereal | H | TODO | 2026-04-07 | | |
| 1005 | QNT Protein Joy Bar Cookie Dough | QNT | BE | protein_bar | M | TODO | 2026-04-07 | | |
| 1009 | Rawbite Protein Crunchy Almond | Rawbite | DK | protein_bar | M | TODO | 2026-04-07 | | |
| 1011 | NOCCO BCAA Focus Black Orange | NOCCO | SE | energy_drink | M | TODO | 2026-04-07 | | |
| 1012 | FITAID Energy Drink | FITAID | US | energy_drink | M | TODO | 2026-04-07 | | CrossFit popular |
| 1015 | Ryse Fuel Smarties | Ryse | US | energy_drink | M | TODO | 2026-04-07 | | |
| 1016 | Raw Nutrition CBUM Thavage Pre-Workout (per serving) | Raw Nutrition | US | supplement | M | TODO | 2026-04-07 | | |
| 1017 | 1st Phorm Level-1 Protein Chocolate | 1st Phorm | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1018 | Ryse Loaded Protein Cinnamon Toast | Ryse | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1020 | G Fuel Energy Formula Blue Ice (per serving) | G Fuel | US | energy_drink | M | TODO | 2026-04-07 | | Gaming/fitness |
| 1021 | Snaq Fabriq Chocolate Bar | Snaq Fabriq | RU | protein_bar | M | TODO | 2026-04-07 | | Russian fitness brand |
| 1023 | MyProtein Protein Cookie Double Chocolate | MyProtein | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 1025 | PhD Smart Plant Bar Choc Toffee Popcorn | PhD Nutrition | GB | protein_bar | M | TODO | 2026-04-07 | | Vegan |
| 1026 | Myprotein Vegan Protein Blend Chocolate | MyProtein | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 1028 | Fast&Up Whey Advanced Protein Rich Chocolate | Fast&Up | IN | protein_powder | M | TODO | 2026-04-07 | | |
| 1029 | OZiva Protein & Herbs for Men Chocolate | OZiva | IN | protein_powder | M | TODO | 2026-04-07 | | India fitness |
| 1030 | MuscleBlaze Raw Whey Protein Unflavored | MuscleBlaze | IN | protein_powder | M | TODO | 2026-04-07 | | |

---


## Section 41: UK Supermarket Own Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1031 | Tesco Finest Free Range Chicken Breast (per 100g) | Tesco | GB | protein | H | TODO | 2026-04-07 | | |
| 1032 | Tesco Protein Yogurt Strawberry | Tesco | GB | dairy | M | TODO | 2026-04-07 | | |
| 1033 | Tesco Plant Chef Meat Free Burgers (per patty) | Tesco | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 1034 | Tesco Finest Granola Honey Almond | Tesco | GB | cereal | M | TODO | 2026-04-07 | | |
| 1037 | Sainsbury's Be Good to Yourself Prawn Noodles | Sainsbury's | GB | ready_meal | M | TODO | 2026-04-07 | | |
| 1038 | Sainsbury's High Protein Greek Style Yogurt | Sainsbury's | GB | dairy | H | TODO | 2026-04-07 | | |
| 1039 | Sainsbury's Protein Chicken Wrap | Sainsbury's | GB | fast_food | M | TODO | 2026-04-07 | | |
| 1040 | Sainsbury's Free From Chocolate Brownie | Sainsbury's | GB | dessert | L | TODO | 2026-04-07 | | |
| 1041 | M&S Count on Us Chicken Noodle Stir Fry | M&S | GB | ready_meal | M | TODO | 2026-04-07 | | |
| 1042 | M&S Eat Well Chicken Tikka Rice | M&S | GB | ready_meal | M | TODO | 2026-04-07 | | |
| 1043 | M&S Percy Pig Sweets (per 100g) | M&S | GB | confectionery | H | TODO | 2026-04-07 | | UK cult sweet |
| 1044 | M&S Colin the Caterpillar Cake (per slice) | M&S | GB | dessert | M | TODO | 2026-04-07 | | |
| 1045 | M&S Plant Kitchen No Chicken Kievs (per piece) | M&S | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 1046 | Waitrose Essential British Chicken Breast (per 100g) | Waitrose | GB | protein | M | TODO | 2026-04-07 | | |
| 1047 | Waitrose Love Life Granola Nuts & Seeds | Waitrose | GB | cereal | M | TODO | 2026-04-07 | | |
| 1050 | Aldi Brooklea Protein Yogurt Vanilla | Aldi UK | GB | dairy | H | TODO | 2026-04-07 | | |
| 1052 | Aldi Specially Selected Granola Berry | Aldi UK | GB | cereal | M | TODO | 2026-04-07 | | |
| 1053 | Lidl Milbona High Protein Yogurt Blueberry | Lidl | GB | dairy | H | TODO | 2026-04-07 | | |
| 1055 | Lidl Deluxe Irish Butter (per 10g) | Lidl | GB | dairy | M | TODO | 2026-04-07 | | |
| 1056 | Myprotein Protein Bread Rolls (per roll) | MyProtein | GB | bread | H | TODO | 2026-04-07 | | |
| 1057 | The Skinny Food Co Not Guilty Low Cal Popcorn | Skinny Food Co | GB | snack | M | TODO | 2026-04-07 | | |
| 1059 | Hartley's 10 Cal Jelly Strawberry | Hartley's | GB | dessert | H | TODO | 2026-04-07 | | Diet staple UK |
| 1060 | Batchelors Super Noodles Chicken | Batchelors | GB | instant_noodle | M | TODO | 2026-04-07 | | |
| 1061 | Pot Noodle Chicken & Mushroom | Pot Noodle | GB | instant_noodle | M | TODO | 2026-04-07 | | |
| 1062 | Nando's PERInaise Original (per tbsp) | Nando's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1064 | HP Brown Sauce (per tbsp) | HP | GB | condiment | M | TODO | 2026-04-07 | | |
| 1065 | Branston Pickle (per tbsp) | Branston | GB | condiment | M | TODO | 2026-04-07 | | |
| 1066 | Hellmann's Light Mayo UK (per tbsp) | Hellmann's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1067 | Cathedral City Mature Cheddar (per 30g) | Cathedral City | GB | dairy | M | TODO | 2026-04-07 | | |
| 1068 | Cathedral City Lighter Cheddar (per 30g) | Cathedral City | GB | dairy | M | TODO | 2026-04-07 | | |
| 1069 | Babybel Mini Original (per piece) | Babybel | FR | dairy | M | TODO | 2026-04-07 | | |
| 1070 | Babybel Mini Light (per piece) | Babybel | FR | dairy | M | TODO | 2026-04-07 | | |
| 1072 | Skyr Arla Protein Strawberry | Arla | DK | dairy | H | TODO | 2026-04-07 | | |
| 1073 | Benecol Original Drink (per bottle) | Benecol | FI | dairy | M | TODO | 2026-04-07 | | |
| 1074 | Frijj Chocolate Milkshake | Frijj | GB | beverage | M | TODO | 2026-04-07 | | |
| 1075 | Ribena Blackcurrant (per serving) | Ribena | GB | beverage | M | TODO | 2026-04-07 | | |
| 1076 | Robinsons Fruit Shoot (per bottle) | Robinsons | GB | beverage | L | TODO | 2026-04-07 | | |
| 1077 | Irn Bru Original (per can) | Irn Bru | GB | beverage | M | TODO | 2026-04-07 | | Scottish icon |
| 1078 | Lucozade Sport Orange (per bottle) | Lucozade | GB | sports_drink | M | TODO | 2026-04-07 | | |
| 1079 | Lucozade Energy Original (per can) | Lucozade | GB | energy_drink | M | TODO | 2026-04-07 | | |
| 1080 | Vimto Still (per carton) | Vimto | GB | beverage | M | TODO | 2026-04-07 | | |

## Section 42: German Supermarket & Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1081 | Aldi Süd Milsani Protein Yogurt Natur | Aldi Süd | DE | dairy | H | TODO | 2026-04-07 | | |
| 1082 | Aldi Süd GutBio Haferflocken (per serving) | Aldi Süd | DE | cereal | M | TODO | 2026-04-07 | | |
| 1083 | Lidl Milbona Magerquark (per 100g) | Lidl | DE | dairy | H | TODO | 2026-04-07 | | German fitness staple |
| 1084 | Lidl Milbona Skyr Natur | Lidl | DE | dairy | H | TODO | 2026-04-07 | | |
| 1085 | Lidl Protein Pudding Chocolate | Lidl | DE | dairy | H | TODO | 2026-04-07 | | |
| 1086 | Ehrmann High Protein Pudding Chocolate | Ehrmann | DE | dairy | H | TODO | 2026-04-07 | | Huge in EU |
| 1087 | Ehrmann High Protein Pudding Vanilla | Ehrmann | DE | dairy | H | TODO | 2026-04-07 | | |
| 1088 | Ehrmann High Protein Yogurt Raspberry | Ehrmann | DE | dairy | H | TODO | 2026-04-07 | | |
| 1089 | Ehrmann High Protein Drink Vanilla | Ehrmann | DE | protein_drink | H | TODO | 2026-04-07 | | |
| 1090 | Zott Protein Pudding Caramel | Zott | DE | dairy | M | TODO | 2026-04-07 | | |
| 1091 | Dr. Oetker High Protein Pudding Chocolate | Dr. Oetker | DE | dairy | M | TODO | 2026-04-07 | | |
| 1094 | Body Attack Power Protein 90 Chocolate | Body Attack | DE | protein_powder | M | TODO | 2026-04-07 | | |
| 1095 | More Nutrition Total Protein Chocolate Brownie | More Nutrition | DE | protein_powder | M | TODO | 2026-04-07 | | German fitness influencer brand |
| 1098 | Knoppers Milch-Haselnuss-Schnitte (per piece) | Storck | DE | biscuit | M | TODO | 2026-04-07 | | |
| 1099 | Duplo Ferrero (per piece) | Ferrero | DE | chocolate | M | TODO | 2026-04-07 | | |
| 1100 | Hanuta Ferrero (per piece) | Ferrero | DE | biscuit | M | TODO | 2026-04-07 | | |
| 1101 | Giotto Ferrero (per piece) | Ferrero | DE | confectionery | M | TODO | 2026-04-07 | | |
| 1102 | Mon Chéri (per piece) | Ferrero | DE | chocolate | M | TODO | 2026-04-07 | | |
| 1103 | Yogurette (per bar) | Ferrero | DE | chocolate | M | TODO | 2026-04-07 | | |
| 1104 | Dickmann's Schoko Strolche (per piece) | Storck | DE | confectionery | M | TODO | 2026-04-07 | | |
| 1105 | Maoam Bloxx (per piece) | Haribo | DE | confectionery | L | TODO | 2026-04-07 | | |
| 1106 | Katjes Grün-Ohr Bärchen (per 100g) | Katjes | DE | confectionery | M | TODO | 2026-04-07 | | Vegan gummies |
| 1107 | Hitschler Hitschies (per 100g) | Hitschler | DE | confectionery | L | TODO | 2026-04-07 | | |
| 1108 | Funny Frisch Chipsfrisch Ungarisch (per 100g) | Funny Frisch | DE | snack | M | TODO | 2026-04-07 | | Germany #1 chips |
| 1109 | Lorenz Crunchips Paprika (per 100g) | Lorenz | DE | snack | M | TODO | 2026-04-07 | | |
| 1110 | XOX Erdnussflips (per 100g) | XOX | DE | snack | M | TODO | 2026-04-07 | | |
| 1111 | Zentis Aachener Pflümli (per tbsp) | Zentis | DE | spread | M | TODO | 2026-04-07 | | |
| 1112 | Müller Milchreis Klassik (per pot) | Müller | DE | dairy | M | TODO | 2026-04-07 | | |
| 1113 | Landliebe Griessbrei (per pot) | Landliebe | DE | dairy | M | TODO | 2026-04-07 | | |
| 1114 | Alpro Skyr Style Natur | Alpro | DE | dairy_alt | M | TODO | 2026-04-07 | | |
| 1115 | Alpro Protein Soy Drink | Alpro | DE | dairy_alt | M | TODO | 2026-04-07 | | |
| 1116 | BiFi Original Salami Stick (per piece) | BiFi | DE | protein_snack | M | TODO | 2026-04-07 | | |
| 1117 | BiFi Roll (per piece) | BiFi | DE | protein_snack | M | TODO | 2026-04-07 | | |
| 1118 | Maggi 5 Minuten Terrine Nudeln Bolognese | Maggi | DE | instant_noodle | M | TODO | 2026-04-07 | | |
| 1119 | Iglo Schlemmer-Filet Bordelaise (per piece) | Iglo | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 1121 | Meggle Kräuterbutter (per 10g) | Meggle | DE | dairy | M | TODO | 2026-04-07 | | |
| 1122 | Kerrygold Irische Butter (per 10g) | Kerrygold | DE | dairy | M | TODO | 2026-04-07 | | |
| 1123 | Bionade Holunder (per 330ml) | Bionade | DE | beverage | M | TODO | 2026-04-07 | | |
| 1124 | Fritz Kola (per 330ml) | Fritz | DE | beverage | M | TODO | 2026-04-07 | | German craft cola |
| 1125 | Club-Mate (per 500ml) | Loscher | DE | beverage | M | TODO | 2026-04-07 | | Hacker/startup drink |
| 1126 | Spezi Cola-Orange (per 330ml) | Paulaner | DE | beverage | M | TODO | 2026-04-07 | | |
| 1127 | Mezzo Mix (per 330ml) | Coca-Cola | DE | beverage | M | TODO | 2026-04-07 | | |
| 1128 | Brötchen Semmel (per piece) | Various | DE | bread | M | TODO | 2026-04-07 | | |
| 1129 | Laugenbrezel Soft (per piece) | Various | DE | bread | M | TODO | 2026-04-07 | | |
| 1130 | Döner Kebab (per wrap) | Various | DE | fast_food | H | TODO | 2026-04-07 | | Germany's #1 fast food |

## Section 43: International Fast Food - Unique Menu Items (60 items)

| # | Food Name | Brand | Country | Restaurant | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|------------|----------|----------|--------|------------|----------------|-------|
| 1131 | McDonald's McAloo Tikki (India) | McDonald's | IN | McDonald's | fast_food | H | TODO | 2026-04-07 | | India exclusive |
| 1132 | McDonald's Chicken Maharaja Mac (India) | McDonald's | IN | McDonald's | fast_food | H | TODO | 2026-04-07 | | |
| 1133 | McDonald's McSpicy Paneer (India) | McDonald's | IN | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 1134 | McDonald's Teriyaki McBurger (Japan) | McDonald's | JP | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 1135 | McDonald's Ebi Filet-O (Japan) | McDonald's | JP | McDonald's | fast_food | M | TODO | 2026-04-07 | | Shrimp burger |
| 1136 | McDonald's Samurai Pork Burger (Thailand) | McDonald's | TH | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 1137 | McDonald's McFlurry Ovomaltine (Brazil) | McDonald's | BR | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 1138 | McDonald's Prosperity Burger (Malaysia) | McDonald's | MY | McDonald's | fast_food | M | TODO | 2026-04-07 | | |
| 1139 | KFC Zinger Burger (International) | KFC | GB | KFC | fast_food | H | TODO | 2026-04-07 | | |
| 1140 | KFC Rice Bowl (Asia) | KFC | ID | KFC | fast_food | M | TODO | 2026-04-07 | | |
| 1141 | KFC Chizza (Asia) | KFC | PH | KFC | fast_food | M | TODO | 2026-04-07 | | Chicken as pizza base |
| 1143 | Domino's Peppy Paneer Pizza India (per slice) | Domino's | IN | Domino's | fast_food | H | TODO | 2026-04-07 | | India #1 pizza |
| 1144 | Domino's Burger Pizza India (per slice) | Domino's | IN | Domino's | fast_food | M | TODO | 2026-04-07 | | |
| 1145 | Pizza Hut Birizza (India) | Pizza Hut | IN | Pizza Hut | fast_food | M | TODO | 2026-04-07 | | Biryani pizza |
| 1146 | Subway 6-inch Turkey Breast | Subway | US | Subway | fast_food | H | TODO | 2026-04-07 | | |
| 1147 | Subway 6-inch Chicken Teriyaki | Subway | US | Subway | fast_food | M | TODO | 2026-04-07 | | |
| 1150 | Paris Baguette Egg Tart (per piece) | Paris Baguette | KR | Paris Baguette | bakery | M | TODO | 2026-04-07 | | |
| 1151 | Paris Baguette Strawberry Cake (per slice) | Paris Baguette | KR | Paris Baguette | bakery | M | TODO | 2026-04-07 | | |
| 1152 | Tous les Jours Cloud Bread (per piece) | Tous les Jours | KR | Tous les Jours | bakery | M | TODO | 2026-04-07 | | |
| 1153 | 85°C Sea Salt Coffee (per cup) | 85°C | TW | 85°C | beverage | M | TODO | 2026-04-07 | | |
| 1154 | 85°C Brioche (per piece) | 85°C | TW | 85°C | bakery | M | TODO | 2026-04-07 | | |
| 1155 | MrBeast Burger Original (per burger) | MrBeast | US | MrBeast Burger | fast_food | H | TODO | 2026-04-07 | | Ghost kitchen |
| 1156 | Wingstop Garlic Parmesan Boneless Wings (per 6) | Wingstop | US | Wingstop | fast_food | M | TODO | 2026-04-07 | | |
| 1157 | Dave's Hot Chicken Dave's #1 Tender (per piece) | Dave's Hot Chicken | US | Dave's Hot Chicken | fast_food | H | TODO | 2026-04-07 | | Viral chain |
| 1158 | Dave's Hot Chicken Slider (per piece) | Dave's Hot Chicken | US | Dave's Hot Chicken | fast_food | M | TODO | 2026-04-07 | | |
| 1159 | Waba Grill Chicken Bowl | Waba Grill | US | Waba Grill | fast_food | M | TODO | 2026-04-07 | | Fitness-friendly |
| 1160 | El Pollo Loco Original Pollo Bowl | El Pollo Loco | US | El Pollo Loco | fast_food | M | TODO | 2026-04-07 | | |
| 1161 | Jolibee Palabok Fiesta | Jollibee | PH | Jollibee | fast_food | M | TODO | 2026-04-07 | | |
| 1162 | Jolibee Peach Mango Pie (per piece) | Jollibee | PH | Jollibee | fast_food | M | TODO | 2026-04-07 | | |
| 1163 | Goldilocks Mocha Roll (per slice) | Goldilocks | PH | Goldilocks | bakery | M | TODO | 2026-04-07 | | Filipino bakery chain |
| 1164 | Red Ribbon Dedication Cake Mocha (per slice) | Red Ribbon | PH | Red Ribbon | bakery | M | TODO | 2026-04-07 | | Filipino bakery chain |
| 1165 | Chowking Lauriat Meal Soy Chicken | Chowking | PH | Chowking | fast_food | M | TODO | 2026-04-07 | | |
| 1167 | Ya Kun Kaya Toast Set (per serving) | Ya Kun | SG | Ya Kun | breakfast | M | TODO | 2026-04-07 | | |
| 1168 | Old Chang Kee Curry Puff (per piece) | Old Chang Kee | SG | Old Chang Kee | snack | M | TODO | 2026-04-07 | | |
| 1170 | Secret Recipe Chocolate Indulgence Cake (per slice) | Secret Recipe | MY | Secret Recipe | dessert | M | TODO | 2026-04-07 | | |
| 1171 | Ramly Burger Original (per burger) | Ramly | MY | Various | fast_food | H | TODO | 2026-04-07 | | Malaysian street food icon |
| 1172 | Mamak Roti Canai Telur (per piece) | Various | MY | Various | bread | M | TODO | 2026-04-07 | | |
| 1173 | CoCo Fresh Tea & Juice Bubble Milk Tea (per M) | CoCo | TW | CoCo | beverage | H | TODO | 2026-04-07 | | |
| 1175 | Saladstop! Protein Power Bowl | Saladstop! | SG | Saladstop! | salad | M | TODO | 2026-04-07 | | |
| 1176 | Subway India Aloo Patty Sub (6-inch) | Subway | IN | Subway | fast_food | M | TODO | 2026-04-07 | | |
| 1177 | WOK to WALK Chicken Teriyaki Noodles | WOK to WALK | NL | WOK to WALK | fast_food | M | TODO | 2026-04-07 | | |
| 1178 | Paul French Bakery Pain au Raisin (per piece) | Paul | FR | Paul | bakery | M | TODO | 2026-04-07 | | |
| 1179 | Gail's Bakery Cinnamon Bun (per piece) | Gail's | GB | Gail's | bakery | M | TODO | 2026-04-07 | | |
| 1181 | Pret a Manger Protein Power Pot | Pret | GB | Pret a Manger | fast_food | H | TODO | 2026-04-07 | | |
| 1182 | Pret a Manger Chicken & Avocado Sandwich | Pret | GB | Pret a Manger | fast_food | M | TODO | 2026-04-07 | | |
| 1183 | Pret a Manger Coconut Chicken Soup | Pret | GB | Pret a Manger | soup | M | TODO | 2026-04-07 | | |
| 1185 | Tortilla Chicken Burrito | Tortilla | GB | Tortilla | fast_food | M | TODO | 2026-04-07 | | |
| 1186 | Wahaca Chicken Burrito | Wahaca | GB | Wahaca | fast_food | M | TODO | 2026-04-07 | | |
| 1189 | Nando's Chicken Butterfly Breast | Nando's | GB | Nando's | fast_food | H | TODO | 2026-04-07 | | Different from ZA |

## Section 44: Indian Specific Brands Not Yet Covered (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1191 | Patanjali Doodh Biscuit | Patanjali | IN | biscuit | M | TODO | 2026-04-07 | | |
| 1192 | Patanjali Cow's Ghee (per tsp) | Patanjali | IN | dairy | H | TODO | 2026-04-07 | | |
| 1193 | Patanjali Atta Noodles | Patanjali | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 1194 | Saffola Oats Masala (per serving) | Saffola | IN | cereal | H | TODO | 2026-04-07 | | |
| 1195 | Saffola Muesli Crunchy (per serving) | Saffola | IN | cereal | M | TODO | 2026-04-07 | | |
| 1196 | True Elements Steel Cut Oats (per serving) | True Elements | IN | cereal | M | TODO | 2026-04-07 | | |
| 1197 | Soulfull Ragi Bites Cocoa (per serving) | Soulfull | IN | cereal | M | TODO | 2026-04-07 | | Millet cereal |
| 1198 | Slurrp Farm Millet Dosa Mix (per dosa) | Slurrp Farm | IN | breakfast | M | TODO | 2026-04-07 | | |
| 1199 | iD Fresh Idli Batter (per idli) | iD Fresh | IN | breakfast | H | TODO | 2026-04-07 | | Fresh batter brand |
| 1200 | iD Fresh Parota (per piece) | iD Fresh | IN | bread | M | TODO | 2026-04-07 | | |
| 1202 | Eastern Sambar Powder (per tsp) | Eastern | IN | condiment | M | TODO | 2026-04-07 | | South Indian brand |
| 1203 | Aachi Chicken 65 Masala (per tsp) | Aachi | IN | condiment | M | TODO | 2026-04-07 | | |
| 1204 | Amul Lassi Rose (per 200ml) | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 1205 | Amul Kool Cafe (per 200ml) | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 1206 | Amul Tru Seltzer (per can) | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 1207 | Nandini Curd (per 100g) | Nandini | IN | dairy | M | TODO | 2026-04-07 | | Karnataka brand |
| 1208 | Aavin Milk Full Cream (per 250ml) | Aavin | IN | dairy | M | TODO | 2026-04-07 | | Tamil Nadu brand |
| 1209 | Milma Curd (per 100g) | Milma | IN | dairy | M | TODO | 2026-04-07 | | Kerala brand |
| 1211 | Keventers Milkshake Chocolate (per bottle) | Keventers | IN | beverage | M | TODO | 2026-04-07 | | |
| 1212 | Raw Pressery Cold Pressed OJ (per bottle) | Raw Pressery | IN | beverage | M | TODO | 2026-04-07 | | |
| 1213 | Epigamia Protein Shake Chocolate (per bottle) | Epigamia | IN | protein_drink | H | TODO | 2026-04-07 | | |
| 1214 | Swiggy Instamart House Brand Paneer (per 100g) | Swiggy | IN | dairy | M | TODO | 2026-04-07 | | |
| 1215 | BigBasket Fresho Chicken Breast (per 100g) | BigBasket | IN | protein | M | TODO | 2026-04-07 | | |
| 1216 | Licious Chicken Breast Boneless (per 100g) | Licious | IN | protein | H | TODO | 2026-04-07 | | India meat delivery |
| 1217 | FreshToHome Fish Seer Fish Fillet (per 100g) | FreshToHome | IN | protein | M | TODO | 2026-04-07 | | |
| 1218 | ITC Aashirvaad Atta Pizza Base (per base) | ITC | IN | bread | M | TODO | 2026-04-07 | | |
| 1219 | ITC Sunfeast YiPPee Power Up Atta Noodles | ITC | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 1221 | Snickers India (per bar) | Snickers | IN | chocolate | M | TODO | 2026-04-07 | | |
| 1222 | Munch Chocolate (per bar) | Nestle | IN | chocolate | M | TODO | 2026-04-07 | | India exclusive |
| 1223 | KitKat India (per 2 finger) | Nestle | IN | chocolate | M | TODO | 2026-04-07 | | |
| 1224 | Gems Cadbury (per small pack) | Cadbury | IN | confectionery | L | TODO | 2026-04-07 | | |
| 1225 | Pulse Candy (per piece) | DS Group | IN | confectionery | L | TODO | 2026-04-07 | | India's #1 candy |
| 1226 | Swad Mixed Mukhwas (per tsp) | Swad | IN | confectionery | L | TODO | 2026-04-07 | | |
| 1227 | Crax Corn Ring Masala | DFM Foods | IN | snack | M | TODO | 2026-04-07 | | |
| 1228 | Uncle Chipps Spicy Treat | Uncle Chipps | IN | snack | M | TODO | 2026-04-07 | | |
| 1229 | Pepsi Max (India per can) | Pepsi | IN | beverage | M | TODO | 2026-04-07 | | |
| 1230 | Coca-Cola Zero (India per can) | Coca-Cola | IN | beverage | M | TODO | 2026-04-07 | | |
| 1231 | Dawat-E-Khaas Sheermal (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | Mughlai bread |
| 1232 | Haldiram's Minute Khana Poha (per serving) | Haldiram's | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1233 | MTR Masala Upma (per serving) | MTR | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1237 | K.C. Das Rosogolla (per piece) | K.C. Das | IN | dessert | M | TODO | 2026-04-07 | | Bengal iconic |
| 1238 | Naturals Ice Cream Tender Coconut (per scoop) | Naturals | IN | dessert | M | TODO | 2026-04-07 | | |
| 1239 | Baskin Robbins India Mississippi Mud (per scoop) | Baskin Robbins | IN | dessert | M | TODO | 2026-04-07 | | |
| 1240 | Havmor Cornetto Disc (per piece) | Havmor | IN | dessert | M | TODO | 2026-04-07 | | Gujarat brand |
| 1241 | Kwality Walls Feast Chocolate (per bar) | Kwality Walls | IN | dessert | M | TODO | 2026-04-07 | | |
| 1242 | Wagh Bakri Instant Masala Tea (per sachet) | Wagh Bakri | IN | beverage | M | TODO | 2026-04-07 | | |
| 1244 | Third Wave Coffee Flat White (per cup) | Third Wave | IN | beverage | M | TODO | 2026-04-07 | | |
| 1246 | OZiva Clean Protein Bars Crunchy Peanut | OZiva | IN | protein_bar | M | TODO | 2026-04-07 | | |
| 1247 | Raw Protein Whey Isolate Chocolate | Raw | IN | protein_powder | M | TODO | 2026-04-07 | | |
| 1248 | Wow! Momo Chicken Momo Steamed (per 6 pieces) | Wow! Momo | IN | snack | H | TODO | 2026-04-07 | | India momo chain |
| 1249 | Faasos Wrap Chicken Tikka | Faasos | IN | fast_food | M | TODO | 2026-04-07 | | Delivery brand |
| 1250 | Behrouz Biryani Dum Gosht (per serving) | Behrouz | IN | fast_food | M | TODO | 2026-04-07 | | Cloud kitchen |

## Section 45: Japanese & Korean Specific Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1251 | Lawson Karaage-kun Regular (per pack) | Lawson | JP | snack | H | TODO | 2026-04-07 | | Konbini icon |
| 1252 | FamilyMart Famichiki (per piece) | FamilyMart | JP | snack | H | TODO | 2026-04-07 | | Japan konbini fried chicken |
| 1253 | 7-Eleven Japan Salad Chicken Breast (per pack) | 7-Eleven | JP | protein | H | TODO | 2026-04-07 | | Fitness staple Japan |
| 1254 | Yamazaki Lunch Pack Tamago (per pack) | Yamazaki | JP | bread | M | TODO | 2026-04-07 | | |
| 1255 | Pasco Shikisai Bread (per piece) | Pasco | JP | bread | M | TODO | 2026-04-07 | | |
| 1256 | Yakult 1000 (per bottle) | Yakult | JP | beverage | H | TODO | 2026-04-07 | | Premium version |
| 1258 | Glico Pretz Salad (per box) | Glico | JP | snack | M | TODO | 2026-04-07 | | |
| 1259 | Calbee Jaga Pokkuru (per bag) | Calbee | JP | snack | M | TODO | 2026-04-07 | | Hokkaido exclusive |
| 1260 | Morinaga Caramel (per piece) | Morinaga | JP | confectionery | M | TODO | 2026-04-07 | | |
| 1261 | Fujiya Milky Candy (per piece) | Fujiya | JP | confectionery | M | TODO | 2026-04-07 | | |
| 1262 | Bourbon Petit Series Chocolate Chip (per pack) | Bourbon | JP | biscuit | M | TODO | 2026-04-07 | | |
| 1263 | Tohato Caramel Corn (per 100g) | Tohato | JP | snack | M | TODO | 2026-04-07 | | |
| 1264 | Kameda Kaki no Tane Rice Crackers (per 100g) | Kameda | JP | snack | M | TODO | 2026-04-07 | | |
| 1265 | Morinaga in Jelly Protein (per pouch) | Morinaga | JP | protein_drink | H | TODO | 2026-04-07 | | Jelly protein drink |
| 1266 | Weider in Jelly Energy (per pouch) | Weider Japan | JP | supplement | M | TODO | 2026-04-07 | | |
| 1267 | CalorieMate Block Cheese (per block) | Otsuka | JP | meal_replacement | M | TODO | 2026-04-07 | | |
| 1268 | CalorieMate Block Chocolate (per block) | Otsuka | JP | meal_replacement | M | TODO | 2026-04-07 | | |
| 1269 | SAVAS Whey Protein Cocoa (per scoop) | Meiji | JP | protein_powder | H | TODO | 2026-04-07 | | Japan #1 protein |
| 1270 | DNS Protein Whey 100 Chocolate (per scoop) | DNS | JP | protein_powder | M | TODO | 2026-04-07 | | |
| 1271 | Asahi Dear Natura Multivitamin (per tablet) | Asahi | JP | supplement | L | TODO | 2026-04-07 | | |
| 1273 | Kirin Afternoon Tea Milk Tea (per 500ml) | Kirin | JP | beverage | M | TODO | 2026-04-07 | | |
| 1275 | Asahi Mitsuya Cider (per can) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | Japan iconic soda |
| 1276 | Calpico Soda (per can) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | |
| 1277 | Sapporo Ichiban Miso Ramen | Sapporo Ichiban | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 1279 | Cup Noodle Curry (Japan) | Nissin | JP | instant_noodle | M | TODO | 2026-04-07 | | Different from US |
| 1280 | Peyoung Yakisoba (per pack) | Maruka | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 1281 | CU Convenience Store Triangle Kimbap (per piece) | CU | KR | snack | H | TODO | 2026-04-07 | | Korean konbini |
| 1282 | GS25 Chicken Breast Salad | GS25 | KR | protein | H | TODO | 2026-04-07 | | Korean konbini |
| 1283 | Emart24 Protein Drink (per bottle) | Emart24 | KR | protein_drink | M | TODO | 2026-04-07 | | |
| 1284 | Pulmuone Tofu Extra Firm (per 100g) | Pulmuone | KR | protein | M | TODO | 2026-04-07 | | |
| 1285 | CJ CheilJedang Hetbahn Rice (per pack) | CJ | KR | staple | M | TODO | 2026-04-07 | | Instant rice |
| 1286 | Dongwon Tuna Can (per can) | Dongwon | KR | protein | M | TODO | 2026-04-07 | | Korea #1 tuna |
| 1288 | Beksul Frying Mix (per serving) | CJ | KR | staple | L | TODO | 2026-04-07 | | |
| 1290 | Crown Choco Heim (per piece) | Crown | KR | biscuit | M | TODO | 2026-04-07 | | |
| 1291 | Lotte Mon Cher Cream Cake (per piece) | Lotte | KR | biscuit | M | TODO | 2026-04-07 | | |
| 1292 | Haitai Ace Crackers (per serving) | Haitai | KR | biscuit | M | TODO | 2026-04-07 | | |
| 1293 | Maxim Original Mix Coffee (per stick) | Dongsuh | KR | beverage | M | TODO | 2026-04-07 | | Korea #1 instant coffee |
| 1294 | Starbucks Korea RTD Latte (per can) | Starbucks | KR | beverage | M | TODO | 2026-04-07 | | |
| 1296 | Yakult Korea Light (per bottle) | Yakult | KR | beverage | M | TODO | 2026-04-07 | | |
| 1298 | Muscle King Protein Drink (per bottle) | Muscle King | KR | protein_drink | M | TODO | 2026-04-07 | | |
| 1299 | hy Protein Yogurt (per 100g) | hy | KR | dairy | M | TODO | 2026-04-07 | | Korean dairy brand |
| 1300 | Seoul Milk Low Fat (per 200ml) | Seoul Milk | KR | dairy | M | TODO | 2026-04-07 | | |
| 1301 | Nongshim Veggie Garden Chips | Nongshim | KR | snack | M | TODO | 2026-04-07 | | |
| 1302 | Ottogi Real Cheese Ramen | Ottogi | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 1303 | Paldo Kokomen Spicy Chicken | Paldo | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 1304 | Samyang Carbo Buldak Ramen | Samyang | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 1305 | Three Squirrels Mixed Nuts (per 30g) | Three Squirrels | CN | snack | M | TODO | 2026-04-07 | | China #1 snack brand |
| 1307 | Nongfu Spring Water (per 500ml) | Nongfu | CN | beverage | L | TODO | 2026-04-07 | | China #1 water |
| 1309 | Genki Forest Milk Tea Original (per bottle) | Genki Forest | CN | beverage | M | TODO | 2026-04-07 | | |
| 1310 | Wahaha AD Calcium Milk (per bottle) | Wahaha | CN | beverage | M | TODO | 2026-04-07 | | Chinese childhood drink |

## Section 46: Southeast Asian Specific Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1311 | Pocky Cookies & Cream (Thailand) | Glico | TH | confectionery | M | TODO | 2026-04-07 | | |
| 1312 | Pretz Larb (Thailand) | Glico | TH | snack | M | TODO | 2026-04-07 | | Thai exclusive flavor |
| 1313 | Lay's Nori Seaweed (Thailand) | Lay's | TH | snack | M | TODO | 2026-04-07 | | |
| 1314 | Mama Pad Kee Mao (Drunken Noodle) | Mama | TH | instant_noodle | M | TODO | 2026-04-07 | | |
| 1315 | Mama Green Curry | Mama | TH | instant_noodle | M | TODO | 2026-04-07 | | |
| 1316 | Chang Beer (per can) | Chang | TH | beverage | L | TODO | 2026-04-07 | | |
| 1319 | Singha Soda Water (per can) | Singha | TH | beverage | L | TODO | 2026-04-07 | | |
| 1320 | Thai Tea Number One Brand Powder (per serving) | Cha Tra Mue | TH | beverage | M | TODO | 2026-04-07 | | |
| 1321 | Silverqueen Chocolate Cashew (per bar) | Silverqueen | ID | chocolate | M | TODO | 2026-04-07 | | Indonesian icon |
| 1322 | Tango Wafer Chocolate (per piece) | Tango | ID | biscuit | M | TODO | 2026-04-07 | | |
| 1323 | Good Day Cappuccino Coffee (per bottle) | Good Day | ID | beverage | M | TODO | 2026-04-07 | | |
| 1324 | Teh Pucuk Harum Jasmine Tea (per bottle) | Mayora | ID | beverage | M | TODO | 2026-04-07 | | Indonesia #1 tea |
| 1325 | Pocari Sweat Indonesia (per bottle) | Otsuka | ID | sports_drink | M | TODO | 2026-04-07 | | |
| 1326 | Chitato Original (per 100g) | Indofood | ID | snack | M | TODO | 2026-04-07 | | |
| 1327 | Lays Salmon Teriyaki (Indonesia) | Lay's | ID | snack | M | TODO | 2026-04-07 | | |
| 1328 | Indomie Hype Abang Adek (per pack) | Indomie | ID | instant_noodle | M | TODO | 2026-04-07 | | Viral Indonesian |
| 1329 | Sedaap Mie Goreng (per pack) | Wings | ID | instant_noodle | M | TODO | 2026-04-07 | | |
| 1330 | Pop Mie Ayam Bawang Cup | Indofood | ID | instant_noodle | M | TODO | 2026-04-07 | | |
| 1331 | Kecap Bango Sweet Soy (per tbsp) | Unilever | ID | condiment | M | TODO | 2026-04-07 | | |
| 1332 | Bumbu Racik Nasi Goreng (per sachet) | Indofood | ID | condiment | L | TODO | 2026-04-07 | | |
| 1333 | Ultra Milk Full Cream (per 250ml) | Ultra Jaya | ID | dairy | M | TODO | 2026-04-07 | | |
| 1334 | Bear Brand Sterilized Milk (per can) | Nestle | ID | dairy | M | TODO | 2026-04-07 | | Popular health drink |
| 1337 | Lucky Me Hot Chili Beef | Lucky Me | PH | instant_noodle | M | TODO | 2026-04-07 | | |
| 1339 | Zesto Juice Orange (per pack) | Zesto | PH | beverage | M | TODO | 2026-04-07 | | |
| 1341 | Piattos Cheese (per 100g) | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 1342 | V-Cut BBQ Chips (per 100g) | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 1344 | Maggi Mee Goreng (Malaysia) | Maggi | MY | instant_noodle | H | TODO | 2026-04-07 | | Malaysia variant |
| 1345 | Cintan Mi Goreng Asli | Cintan | MY | instant_noodle | M | TODO | 2026-04-07 | | |
| 1346 | Dutch Lady Milk Full Cream (per 200ml) | Dutch Lady | MY | dairy | M | TODO | 2026-04-07 | | |
| 1348 | F&N Orange (per can) | F&N | MY | beverage | M | TODO | 2026-04-07 | | |
| 1349 | Mister Potato Crisps Original (per 100g) | Mister Potato | MY | snack | M | TODO | 2026-04-07 | | |
| 1350 | MYPROTEIN Malaysia Chicken Breast Strips (per 100g) | MyProtein | MY | protein | M | TODO | 2026-04-07 | | |
| 1351 | Ayam Brand Sardines in Tomato Sauce (per can) | Ayam Brand | SG | protein | M | TODO | 2026-04-07 | | |
| 1353 | Yeo's Chrysanthemum Tea (per pack) | Yeo's | SG | beverage | M | TODO | 2026-04-07 | | |
| 1354 | Myojo Dry Mee Pok (per serving) | Myojo | SG | instant_noodle | M | TODO | 2026-04-07 | | |
| 1355 | Prima Taste Singapore Chili Crab La Mian | Prima Taste | SG | instant_noodle | M | TODO | 2026-04-07 | | Premium |
| 1356 | Tiger Beer (per can) | Tiger | SG | beverage | L | TODO | 2026-04-07 | | |
| 1357 | Pho Hai Phong Instant Rice Noodle | Vifon | VN | instant_noodle | M | TODO | 2026-04-07 | | |
| 1358 | Hao Hao Tom Chua Cay (per pack) | Acecook | VN | instant_noodle | H | TODO | 2026-04-07 | | Vietnam #1 instant noodle |
| 1359 | Vinamilk Fresh Milk (per 200ml) | Vinamilk | VN | dairy | M | TODO | 2026-04-07 | | Vietnam #1 dairy |
| 1360 | TH True Milk (per 200ml) | TH Group | VN | dairy | M | TODO | 2026-04-07 | | |

## Section 47: Middle East & Turkey Specific Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1361 | Pinar Labne (per 100g) | Pinar | TR | dairy | H | TODO | 2026-04-07 | | Turkish dairy giant |
| 1362 | Pinar Beyaz Peynir Feta (per 30g) | Pinar | TR | dairy | M | TODO | 2026-04-07 | | |
| 1363 | Ülker Çikolatalı Gofret Wafer (per piece) | Ülker | TR | biscuit | M | TODO | 2026-04-07 | | |
| 1364 | Ülker Dido Chocolate Bar | Ülker | TR | chocolate | M | TODO | 2026-04-07 | | |
| 1365 | Eti Browni Intense Chocolate Cake | Eti | TR | dessert | M | TODO | 2026-04-07 | | |
| 1366 | Eti Burçak Digestive Biscuit | Eti | TR | biscuit | M | TODO | 2026-04-07 | | |
| 1367 | Torku Banada Chocolate Spread (per tbsp) | Torku | TR | spread | M | TODO | 2026-04-07 | | Turkish Nutella rival |
| 1368 | Dimes Fruit Juice Orange (per 200ml) | Dimes | TR | beverage | M | TODO | 2026-04-07 | | |
| 1369 | Uludağ Gazoz (per 330ml) | Uludağ | TR | beverage | M | TODO | 2026-04-07 | | Turkish iconic soda |
| 1370 | Turkish Airlines Meal Economy Chicken (per serving) | THY | TR | ready_meal | M | TODO | 2026-04-07 | | |
| 1371 | Sütaş Ayran (per 200ml) | Sütaş | TR | beverage | H | TODO | 2026-04-07 | | |
| 1372 | Sütaş Kaşar Cheese (per 30g) | Sütaş | TR | dairy | M | TODO | 2026-04-07 | | |
| 1374 | Nescafe 3in1 (Turkey per sachet) | Nescafe | TR | beverage | M | TODO | 2026-04-07 | | |
| 1375 | Almarai Protein Milk Drink Chocolate | Almarai | SA | protein_drink | H | TODO | 2026-04-07 | | |
| 1377 | Almarai Croissant Zaatar (per piece) | Almarai | SA | bread | M | TODO | 2026-04-07 | | |
| 1378 | Al Rabie Juice Mango (per 200ml) | Al Rabie | SA | beverage | M | TODO | 2026-04-07 | | |
| 1379 | SADAFCO Saudia UHT Milk (per 200ml) | SADAFCO | SA | dairy | M | TODO | 2026-04-07 | | |
| 1380 | Al Marai Date Khalas (per 3 pieces) | Almarai | SA | confectionery | M | TODO | 2026-04-07 | | |
| 1382 | Al Ain Water (per 500ml) | Al Ain | AE | beverage | L | TODO | 2026-04-07 | | |
| 1383 | Rani Float Mango (per can) | Aujan | AE | beverage | M | TODO | 2026-04-07 | | Middle East icon |
| 1384 | Tang Orange Powder (per serving) | Tang | AE | beverage | M | TODO | 2026-04-07 | | Huge in ME |
| 1385 | Indomie Special Chicken (Middle East variant) | Indomie | AE | instant_noodle | M | TODO | 2026-04-07 | | |
| 1386 | Al Fakher Maamoul (per piece) | Al Fakher | AE | biscuit | M | TODO | 2026-04-07 | | |
| 1387 | Kiri Cheese Spread (per portion) | Kiri | FR | dairy | M | TODO | 2026-04-07 | | Huge in ME |
| 1388 | La Vache qui Rit Cheese Wedge (per piece) | La Vache qui Rit | FR | dairy | M | TODO | 2026-04-07 | | Laughing Cow |
| 1389 | Puck Labneh (per tbsp) | Puck | DK | dairy | M | TODO | 2026-04-07 | | Popular in Gulf |
| 1391 | Juhayna Milk Full Fat (per 200ml) | Juhayna | EG | dairy | M | TODO | 2026-04-07 | | Egypt #1 dairy |
| 1392 | Chipsy Cheese (per 100g) | Chipsy | EG | snack | M | TODO | 2026-04-07 | | Egypt's Lay's |
| 1393 | Fayrouz Pineapple (per can) | Heineken | EG | beverage | M | TODO | 2026-04-07 | | Non-alcoholic malt |
| 1394 | Birell Non-Alcoholic Malt (per can) | Heineken | EG | beverage | M | TODO | 2026-04-07 | | |
| 1395 | Bonjus Mango Juice (per 200ml) | Bonjus | LB | beverage | M | TODO | 2026-04-07 | | |
| 1396 | Cortas Rose Water (per tsp) | Cortas | LB | condiment | L | TODO | 2026-04-07 | | |
| 1397 | Gardenia Tahini (per tbsp) | Gardenia | LB | spread | M | TODO | 2026-04-07 | | |
| 1398 | Chtaura Valley Arak (per shot) | Chtaura | LB | beverage | L | TODO | 2026-04-07 | | |
| 1399 | Sana Helwe Sweet Cheese (per 30g) | Various | LB | dairy | M | TODO | 2026-04-07 | | |
| 1400 | Knafeh Nabulsi (per piece) | Various | PS | dessert | M | TODO | 2026-04-07 | | |
| 1405 | Basbousa Semolina Cake (per piece) | Various | EG | dessert | M | TODO | 2026-04-07 | | |
| 1406 | Ful Medames Canned (per serving) | Various | EG | staple | M | TODO | 2026-04-07 | | Egyptian breakfast |
| 1407 | Koshari (per serving) | Various | EG | staple | H | TODO | 2026-04-07 | | Egypt national dish |
| 1409 | Sabich (per sandwich) | Various | IL | fast_food | M | TODO | 2026-04-07 | | Israeli street food |
| 1410 | Jachnun Yemenite Bread (per piece) | Various | IL | bread | M | TODO | 2026-04-07 | | |

## Section 48: European Brands & Products (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1411 | Migros M-Classic Birchermüesli (per serving) | Migros | CH | cereal | M | TODO | 2026-04-07 | | Swiss supermarket |
| 1412 | Migros Protein Yogurt Nature | Migros | CH | dairy | M | TODO | 2026-04-07 | | |
| 1413 | Emmi Caffè Latte (per bottle) | Emmi | CH | beverage | M | TODO | 2026-04-07 | | |
| 1414 | Rivella Original (per 330ml) | Rivella | CH | beverage | M | TODO | 2026-04-07 | | Swiss national drink |
| 1415 | Cailler Chocolate Milk Bar | Cailler | CH | chocolate | M | TODO | 2026-04-07 | | Swiss premium |
| 1416 | Manner Neapolitaner Wafer (per piece) | Manner | AT | biscuit | M | TODO | 2026-04-07 | | Austrian icon |
| 1417 | Almdudler Alpine Herb Soda (per 330ml) | Almdudler | AT | beverage | M | TODO | 2026-04-07 | | Austrian national soda |
| 1418 | Carrefour Bio Granola Chocolat | Carrefour | FR | cereal | M | TODO | 2026-04-07 | | |
| 1419 | Michel et Augustin Petits Cookies | Michel et Augustin | FR | biscuit | M | TODO | 2026-04-07 | | |
| 1420 | St Michel Madeleines (per piece) | St Michel | FR | biscuit | M | TODO | 2026-04-07 | | French classic |
| 1421 | La Laitière Crème Brûlée (per pot) | Nestlé | FR | dessert | M | TODO | 2026-04-07 | | |
| 1422 | Yop Yoplait Strawberry Drink (per bottle) | Yoplait | FR | dairy | M | TODO | 2026-04-07 | | |
| 1423 | Carambar Caramel (per piece) | Carambar | FR | confectionery | M | TODO | 2026-04-07 | | French icon |
| 1424 | Albert Heijn Protein Yogurt Naturel | Albert Heijn | NL | dairy | M | TODO | 2026-04-07 | | |
| 1425 | Albert Heijn Pindakaas Peanut Butter | Albert Heijn | NL | spread | M | TODO | 2026-04-07 | | Dutch PB staple |
| 1426 | Chocomel Chocolate Milk (per 250ml) | Chocomel | NL | beverage | M | TODO | 2026-04-07 | | Dutch icon |
| 1427 | Vla Vanilla Custard (per 100ml) | Various | NL | dairy | M | TODO | 2026-04-07 | | Dutch staple |
| 1428 | Drop Dutch Licorice (per 100g) | Various | NL | confectionery | M | TODO | 2026-04-07 | | |
| 1429 | Fazer Blue Chocolate (per 100g) | Fazer | FI | chocolate | M | TODO | 2026-04-07 | | Finnish icon |
| 1430 | Fazer Tyrkisk Peber (per 100g) | Fazer | FI | confectionery | M | TODO | 2026-04-07 | | |
| 1431 | Fazer Oat Snack Cocoa | Fazer | FI | snack | M | TODO | 2026-04-07 | | |
| 1432 | Kalev Chocolate Tallinn (per 100g) | Kalev | EE | chocolate | M | TODO | 2026-04-07 | | Estonian icon |
| 1433 | Laima Riga Black Balsam Chocolate (per 100g) | Laima | LV | chocolate | M | TODO | 2026-04-07 | | Latvian |
| 1434 | Kvass Latvijas Balzams (per 330ml) | Latvijas Balzams | LV | beverage | L | TODO | 2026-04-07 | | |
| 1435 | ICA Protein Yogurt Natural | ICA | SE | dairy | M | TODO | 2026-04-07 | | Swedish supermarket |
| 1436 | Kalles Kaviar Cod Roe Spread (per tbsp) | Kalles | SE | spread | M | TODO | 2026-04-07 | | Swedish icon |
| 1438 | Daim Bar (per piece) | Marabou | SE | chocolate | M | TODO | 2026-04-07 | | |
| 1439 | Bilar Swedish Car Gummies (per 100g) | Malaco | SE | confectionery | M | TODO | 2026-04-07 | | Swedish icon |
| 1440 | Japp Chocolate Bar (per piece) | Marabou | SE | chocolate | M | TODO | 2026-04-07 | | |
| 1441 | Freia Melkesjokolade (per 100g) | Freia | NO | chocolate | M | TODO | 2026-04-07 | | Norwegian icon |
| 1442 | Kvikk Lunsj Chocolate Bar (per piece) | Freia | NO | chocolate | M | TODO | 2026-04-07 | | Norway's Kit Kat rival |
| 1443 | Smash Snack (per bag) | Nidar | NO | snack | M | TODO | 2026-04-07 | | |
| 1444 | Solo Orange Soda (per 330ml) | Solo | NO | beverage | M | TODO | 2026-04-07 | | Norwegian icon |
| 1445 | Mercadona Hacendado Tortilla Española (per serving) | Hacendado | ES | ready_meal | M | TODO | 2026-04-07 | | Spanish supermarket |
| 1446 | Cola Cao Chocolate Drink (per serving) | Cola Cao | ES | beverage | M | TODO | 2026-04-07 | | Spanish icon |
| 1447 | Nocilla Chocolate Spread (per tbsp) | Nocilla | ES | spread | M | TODO | 2026-04-07 | | Spanish Nutella |
| 1448 | Goya Maria Cookies | Goya | ES | biscuit | M | TODO | 2026-04-07 | | |
| 1449 | Mulino Bianco Barilla Biscuits Pan di Stelle (per piece) | Mulino Bianco | IT | biscuit | M | TODO | 2026-04-07 | | Italian breakfast icon |
| 1450 | Mulino Bianco Macine (per piece) | Mulino Bianco | IT | biscuit | M | TODO | 2026-04-07 | | |
| 1451 | Barilla Pasta Spaghetti No.5 (per 100g dry) | Barilla | IT | staple | M | TODO | 2026-04-07 | | |
| 1452 | De Cecco Rigatoni (per 100g dry) | De Cecco | IT | staple | M | TODO | 2026-04-07 | | |
| 1453 | Buitoni Fresh Tortellini Ricotta (per serving) | Buitoni | IT | pasta | M | TODO | 2026-04-07 | | |
| 1454 | Peroni Nastro Azzurro Beer (per 330ml) | Peroni | IT | beverage | L | TODO | 2026-04-07 | | |
| 1455 | San Benedetto Iced Tea Peach (per 500ml) | San Benedetto | IT | beverage | M | TODO | 2026-04-07 | | |
| 1456 | Loacker Quadratini Napolitaner (per 100g) | Loacker | IT | biscuit | M | TODO | 2026-04-07 | | |
| 1457 | Leibniz Pick Up Choco (per piece) | Bahlsen | DE | biscuit | M | TODO | 2026-04-07 | | |
| 1458 | Prince Polo Classic (per bar) | Olza | PL | chocolate | M | TODO | 2026-04-07 | | Polish icon |
| 1459 | Wedel Ptasie Mleczko (per piece) | Wedel | PL | confectionery | M | TODO | 2026-04-07 | | Polish classic |
| 1460 | Żywiec Beer (per 500ml) | Żywiec | PL | beverage | L | TODO | 2026-04-07 | | |

## Section 49: Latin American Specific Brands (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1461 | Bauducco Toast Wheat (per piece) | Bauducco | BR | bread | M | TODO | 2026-04-07 | | Brazil biscuit giant |
| 1462 | Bauducco Wafer Chocolate (per piece) | Bauducco | BR | biscuit | M | TODO | 2026-04-07 | | |
| 1463 | Toddy Chocolate Powder (per serving) | PepsiCo | BR | beverage | M | TODO | 2026-04-07 | | |
| 1464 | Nescau Chocolate Powder (per serving) | Nestle | BR | beverage | M | TODO | 2026-04-07 | | Brazil's Nesquik |
| 1465 | Havanna Dulce de Leche (per tbsp) | Havanna | AR | spread | M | TODO | 2026-04-07 | | |
| 1466 | La Serenísima Leche Entera (per 200ml) | La Serenísima | AR | dairy | M | TODO | 2026-04-07 | | Argentine #1 dairy |
| 1467 | Manaos Cola (per 330ml) | Manaos | AR | beverage | L | TODO | 2026-04-07 | | |
| 1468 | Quilmes Beer (per 330ml) | Quilmes | AR | beverage | L | TODO | 2026-04-07 | | Argentine icon |
| 1469 | Bon o Bon Chocolate (per piece) | Arcor | AR | confectionery | M | TODO | 2026-04-07 | | |
| 1470 | Mantecol Peanut Nougat (per 30g) | Mondelez | AR | confectionery | M | TODO | 2026-04-07 | | |
| 1471 | Gamesa Maria Cookies (per serving) | Gamesa | MX | biscuit | M | TODO | 2026-04-07 | | |
| 1472 | Bimbo Conchas Pan Dulce (per piece) | Bimbo | MX | bread | M | TODO | 2026-04-07 | | Mexican bakery icon |
| 1474 | Maruchan Instant Lunch Habanero Lime (Mexico) | Maruchan | MX | instant_noodle | M | TODO | 2026-04-07 | | |
| 1475 | Sabritas Original (per 100g) | Sabritas | MX | snack | M | TODO | 2026-04-07 | | |
| 1476 | Barcel Chips Fuego (per 100g) | Barcel | MX | snack | M | TODO | 2026-04-07 | | |
| 1477 | Totis Chips (per 100g) | Totis | MX | snack | L | TODO | 2026-04-07 | | |
| 1478 | Peñafiel Mineral Water Lime (per 600ml) | Peñafiel | MX | beverage | L | TODO | 2026-04-07 | | |
| 1479 | Boing Mango Juice (per 500ml) | Pascual | MX | beverage | M | TODO | 2026-04-07 | | |
| 1480 | Inca Kola Zero (per can) | Coca-Cola | PE | beverage | M | TODO | 2026-04-07 | | |
| 1481 | Club Colombia Beer (per 330ml) | Bavaria | CO | beverage | L | TODO | 2026-04-07 | | |
| 1482 | Bocadillo Veleño Guava Paste (per piece) | Various | CO | confectionery | M | TODO | 2026-04-07 | | |
| 1483 | Ajiaco Bogotano (per serving) | Various | CO | soup | M | TODO | 2026-04-07 | | Colombian staple |
| 1484 | Arepa de Choclo (per piece) | Various | CO | bread | M | TODO | 2026-04-07 | | |
| 1485 | Pilsener Beer Ecuador (per 330ml) | SABMiller | EC | beverage | L | TODO | 2026-04-07 | | |
| 1487 | Ceviche Peruano (per serving) | Various | PE | protein | H | TODO | 2026-04-07 | | |
| 1489 | Anticucho de Corazón (per stick) | Various | PE | protein | M | TODO | 2026-04-07 | | |
| 1490 | Causa Limeña (per serving) | Various | PE | snack | M | TODO | 2026-04-07 | | |
| 1492 | Francesinha Porto Sandwich (per serving) | Various | PT | fast_food | M | TODO | 2026-04-07 | | |
| 1493 | Pastéis de Bacalhau (per piece) | Various | PT | snack | M | TODO | 2026-04-07 | | |
| 1494 | Compal Juice Orange (per 200ml) | Compal | PT | beverage | M | TODO | 2026-04-07 | | Portuguese icon |
| 1495 | Delta Café Espresso (per shot) | Delta | PT | beverage | M | TODO | 2026-04-07 | | Portugal #1 coffee |
| 1496 | Cachitos Venezuelan Bread (per piece) | Various | VE | bread | M | TODO | 2026-04-07 | | |
| 1497 | Pabellón Criollo (per serving) | Various | VE | protein | M | TODO | 2026-04-07 | | Venezuelan national dish |
| 1498 | Salteña Bolivian Empanada (per piece) | Various | BO | snack | M | TODO | 2026-04-07 | | |
| 1499 | Gallo Pinto Costa Rican Rice & Beans (per serving) | Various | CR | staple | M | TODO | 2026-04-07 | | |
| 1500 | Casado Costa Rican Plate (per serving) | Various | CR | protein | M | TODO | 2026-04-07 | | |

## Section 50: African Brands & Foods (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1501 | Shoprite No Name Brand Maize Meal (per 100g) | Shoprite | ZA | staple | M | TODO | 2026-04-07 | | SA supermarket |
| 1503 | Rhodes Fruit Juice Orange (per 200ml) | Rhodes | ZA | beverage | M | TODO | 2026-04-07 | | |
| 1504 | Clover Full Cream Milk (per 250ml) | Clover | ZA | dairy | M | TODO | 2026-04-07 | | |
| 1505 | Woolworths SA Roasted Chicken Breast (per 100g) | Woolworths SA | ZA | protein | M | TODO | 2026-04-07 | | |
| 1506 | Nando's Peri-Peri Chips (per serving) | Nando's | ZA | fast_food | M | TODO | 2026-04-07 | | |
| 1507 | Steers Wacky Wednesday Burger | Steers | ZA | fast_food | M | TODO | 2026-04-07 | | SA fast food chain |
| 1508 | Spur Ribs (per serving) | Spur | ZA | fast_food | M | TODO | 2026-04-07 | | |
| 1509 | Savanna Dry Cider (per 330ml) | Distell | ZA | beverage | L | TODO | 2026-04-07 | | |
| 1510 | Castle Lager (per 340ml) | SAB | ZA | beverage | L | TODO | 2026-04-07 | | |
| 1511 | Indomie Onion Chicken (Nigeria variant) | Indomie | NG | instant_noodle | M | TODO | 2026-04-07 | | |
| 1512 | Dangote Semovita (per 100g) | Dangote | NG | staple | M | TODO | 2026-04-07 | | |
| 1513 | Peak Milk Powder (per serving) | Peak | NG | dairy | M | TODO | 2026-04-07 | | |
| 1514 | Malt Guinness (per 330ml bottle) | Guinness | NG | beverage | M | TODO | 2026-04-07 | | |
| 1517 | Suya Chicken (per stick) | Various | NG | protein | H | TODO | 2026-04-07 | | |
| 1518 | Pounded Yam (per serving) | Various | NG | staple | M | TODO | 2026-04-07 | | |
| 1519 | Amala with Ewedu (per serving) | Various | NG | staple | M | TODO | 2026-04-07 | | |
| 1520 | Ofada Rice (per serving cooked) | Various | NG | staple | M | TODO | 2026-04-07 | | |
| 1521 | Tusker Malt Lager (per 500ml) | EABL | KE | beverage | L | TODO | 2026-04-07 | | |
| 1522 | Brookside Dairy Milk (per 250ml) | Brookside | KE | dairy | M | TODO | 2026-04-07 | | Kenya brand |
| 1523 | Githeri (Corn & Beans per serving) | Various | KE | staple | M | TODO | 2026-04-07 | | |
| 1524 | Mandazi East African Donut (per piece) | Various | KE | bread | M | TODO | 2026-04-07 | | |
| 1525 | Chapati East African (per piece) | Various | KE | bread | M | TODO | 2026-04-07 | | |
| 1526 | Samosa East African (per piece) | Various | KE | snack | M | TODO | 2026-04-07 | | |
| 1529 | Bunna Ethiopian Coffee (per cup) | Various | ET | beverage | M | TODO | 2026-04-07 | | |
| 1531 | Fufu West African (per serving) | Various | GH | staple | M | TODO | 2026-04-07 | | |
| 1536 | Melktert Milk Tart (per slice) | Various | ZA | dessert | M | TODO | 2026-04-07 | | |
| 1537 | Piri Piri Chicken Mozambique (per piece) | Various | MZ | protein | M | TODO | 2026-04-07 | | |
| 1538 | Zanzibar Pizza (per piece) | Various | TZ | snack | M | TODO | 2026-04-07 | | |
| 1539 | Brochette Rwandan Grilled Meat (per stick) | Various | RW | protein | M | TODO | 2026-04-07 | | |
| 1540 | Rolex Uganda Egg Chapati Roll (per piece) | Various | UG | fast_food | M | TODO | 2026-04-07 | | |

## Section 51: More Fitness & Health Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1541 | Grenade Protein Shake Chocolate (RTD) | Grenade | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 1543 | PhD Smart Bar Plant Choc Peanut Caramel | PhD Nutrition | GB | protein_bar | M | TODO | 2026-04-07 | | |
| 1544 | Myprotein Clear Whey Isolate Mojito | MyProtein | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 1545 | Myprotein Protein Pancake Mix (per serving) | MyProtein | GB | breakfast | H | TODO | 2026-04-07 | | |
| 1546 | Myprotein Peanut Butter Powder (per serving) | MyProtein | GB | spread | M | TODO | 2026-04-07 | | |
| 1547 | Applied Nutrition Critical Mass Gainer (per serving) | Applied Nutrition | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 1548 | USN Blue Lab 100% Whey Chocolate | USN | ZA | protein_powder | M | TODO | 2026-04-07 | | South African brand |
| 1549 | NPL Platinum Whey Chocolate | NPL | ZA | protein_powder | M | TODO | 2026-04-07 | | |
| 1550 | SSA Supplements Whey Pro Vanilla | SSA | ZA | protein_powder | M | TODO | 2026-04-07 | | |
| 1551 | Rule 1 Protein Chocolate Fudge (per scoop) | Rule 1 | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1552 | Redcon1 MRE Bar Blueberry Cobbler | Redcon1 | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1553 | Redcon1 MRE Meal Replacement (per serving) | Redcon1 | US | meal_replacement | M | TODO | 2026-04-07 | | |
| 1554 | JYM Pro JYM Protein Powder Chocolate (per scoop) | JYM | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1555 | Kaged Muscle Pre-Kaged Elite (per serving) | Kaged | US | supplement | M | TODO | 2026-04-07 | | |
| 1556 | Bucked Up Pre-Workout Woke AF (per serving) | Bucked Up | US | supplement | M | TODO | 2026-04-07 | | |
| 1557 | Bloom Nutrition Greens & Superfoods Berry (per serving) | Bloom | US | supplement | H | TODO | 2026-04-07 | | TikTok viral |
| 1558 | Alani Nu Balance Capsules (per serving) | Alani Nu | US | supplement | M | TODO | 2026-04-07 | | |
| 1560 | Liquid I.V. Hydration Multiplier Lemon Lime (per stick) | Liquid I.V. | US | supplement | M | TODO | 2026-04-07 | | |
| 1561 | LMNT Electrolyte Mix Citrus Salt (per stick) | LMNT | US | supplement | H | TODO | 2026-04-07 | | Keto popular |
| 1562 | Nuun Sport Lemon Lime (per tablet) | Nuun | US | supplement | M | TODO | 2026-04-07 | | |
| 1563 | Nutrabolt Xtend Original BCAA Mango (per serving) | Nutrabolt | US | supplement | M | TODO | 2026-04-07 | | |
| 1564 | MuscleTech Nitro-Tech Whey Gold Chocolate (per scoop) | MuscleTech | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1565 | BSN Syntha-6 Chocolate Milkshake (per scoop) | BSN | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1566 | Cellucor Whey Sport Chocolate (per scoop) | Cellucor | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1567 | Naked Whey Protein Unflavored (per scoop) | Naked Nutrition | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1568 | Vega Sport Protein Chocolate (per scoop) | Vega | US | protein_powder | M | TODO | 2026-04-07 | | Plant-based |
| 1569 | Garden of Life Raw Organic Protein Chocolate (per scoop) | Garden of Life | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1570 | Sunwarrior Classic Protein Chocolate (per scoop) | Sunwarrior | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1571 | Muscletech Phase 8 Protein Chocolate (per scoop) | MuscleTech | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1572 | BPI Sports Best Protein Chocolate Brownie (per scoop) | BPI Sports | US | protein_powder | L | TODO | 2026-04-07 | | |
| 1573 | Maxler 100% Golden Whey Chocolate (per scoop) | Maxler | US | protein_powder | L | TODO | 2026-04-07 | | |
| 1574 | Myvegan Pea Protein Isolate (per scoop) | MyProtein | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 1575 | Protein World Slender Blend Chocolate (per serving) | Protein World | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 1576 | SiS Go Energy Gel (per gel) | SiS | GB | supplement | M | TODO | 2026-04-07 | | Running gel |
| 1577 | Maurten Gel 100 (per gel) | Maurten | SE | supplement | M | TODO | 2026-04-07 | | Elite running gel |
| 1578 | Clif Bloks Energy Chews Strawberry (per 3 pieces) | Clif | US | supplement | M | TODO | 2026-04-07 | | |
| 1579 | Tailwind Endurance Fuel (per serving) | Tailwind | US | supplement | M | TODO | 2026-04-07 | | |
| 1580 | Skratch Labs Hydration Mix Lemon Lime (per serving) | Skratch Labs | US | supplement | M | TODO | 2026-04-07 | | |
| 1581 | Mutant Mass Gainer Chocolate (per serving) | Mutant | CA | protein_powder | M | TODO | 2026-04-07 | | |
| 1582 | PVL Iso Sport Whey Chocolate (per scoop) | PVL | CA | protein_powder | M | TODO | 2026-04-07 | | |
| 1583 | Perfect Sports Diesel Whey Chocolate (per scoop) | Perfect Sports | CA | protein_powder | M | TODO | 2026-04-07 | | Canadian brand |
| 1584 | Rivalus Clean Gainer Chocolate (per serving) | Rivalus | CA | protein_powder | L | TODO | 2026-04-07 | | |
| 1585 | Lenny & Larry's Complete Cookie Chocolate Chip (per cookie) | Lenny & Larry's | US | protein_snack | M | TODO | 2026-04-07 | | |
| 1586 | Lenny & Larry's Complete Cookie Birthday Cake | Lenny & Larry's | US | protein_snack | M | TODO | 2026-04-07 | | |
| 1587 | Nick's Sticks Free Range Turkey Snack (per stick) | Nick's Sticks | US | protein_snack | M | TODO | 2026-04-07 | | |
| 1588 | Chomps Original Beef Stick (per stick) | Chomps | US | protein_snack | M | TODO | 2026-04-07 | | |
| 1589 | Epic Venison Sea Salt Pepper Bar | Epic | US | protein_snack | M | TODO | 2026-04-07 | | |

## Section 52: International Dairy & Cheese Brands (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1593 | Boursin Garlic & Fine Herbs (per 30g) | Boursin | FR | dairy | M | TODO | 2026-04-07 | | |
| 1594 | Président Brie (per 30g) | Président | FR | dairy | M | TODO | 2026-04-07 | | |
| 1595 | Laughing Cow Light (per wedge) | La Vache qui Rit | FR | dairy | M | TODO | 2026-04-07 | | |
| 1596 | Galbani Fresh Mozzarella (per 100g) | Galbani | IT | dairy | M | TODO | 2026-04-07 | | |
| 1597 | Mascarpone Galbani (per tbsp) | Galbani | IT | dairy | M | TODO | 2026-04-07 | | |
| 1598 | Leerdammer Cheese (per slice) | Leerdammer | NL | dairy | M | TODO | 2026-04-07 | | |
| 1599 | Emmental Cheese (per 30g) | Various | CH | dairy | M | TODO | 2026-04-07 | | |
| 1600 | Gruyère Cheese (per 30g) | Various | CH | dairy | M | TODO | 2026-04-07 | | |
| 1601 | Paneer Amul Fresh (per 100g) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 1603 | Skimmed Milk Amul Taaza (per 250ml) | Amul | IN | dairy | M | TODO | 2026-04-07 | | |
| 1604 | Double Toned Milk Mother Dairy (per 250ml) | Mother Dairy | IN | dairy | M | TODO | 2026-04-07 | | |
| 1605 | Hung Curd Nestlé a+ (per 100g) | Nestlé India | IN | dairy | M | TODO | 2026-04-07 | | |
| 1606 | Greek Yogurt Nestlé a+ (per 100g) | Nestlé India | IN | dairy | M | TODO | 2026-04-07 | | |
| 1607 | Milky Mist Paneer (per 100g) | Milky Mist | IN | dairy | M | TODO | 2026-04-07 | | South Indian brand |
| 1608 | Go Cheese Slice (per slice) | Parag | IN | dairy | M | TODO | 2026-04-07 | | |
| 1609 | Snow Brand Megmilk 6P Cheese (per piece) | Snow Brand | JP | dairy | M | TODO | 2026-04-07 | | |
| 1610 | Meiji Oishii Milk (per 200ml) | Meiji | JP | dairy | M | TODO | 2026-04-07 | | |
| 1611 | Seoul Milk Strawberry (per 200ml) | Seoul Milk | KR | dairy | M | TODO | 2026-04-07 | | |
| 1612 | Maeil Bio Plain Yogurt (per 100g) | Maeil | KR | dairy | M | TODO | 2026-04-07 | | |
| 1613 | Dutch Lady Chocolate Milk (per 200ml) | Dutch Lady | MY | dairy | M | TODO | 2026-04-07 | | |
| 1614 | Greenfields Full Cream Milk (per 250ml) | Greenfields | ID | dairy | M | TODO | 2026-04-07 | | |
| 1616 | Müller Corner Strawberry | Müller | GB | dairy | M | TODO | 2026-04-07 | | |
| 1617 | Yeo Valley Organic Natural Yogurt (per 100g) | Yeo Valley | GB | dairy | M | TODO | 2026-04-07 | | |
| 1618 | Onken Natural Yogurt (per 100g) | Onken | DE | dairy | M | TODO | 2026-04-07 | | |
| 1619 | Skånemejerier Protein Yogurt (per 100g) | Skånemejerier | SE | dairy | M | TODO | 2026-04-07 | | |
| 1620 | Valio Protein Yogurt (per 100g) | Valio | FI | dairy | M | TODO | 2026-04-07 | | |
| 1621 | Danio High Protein Vanilla | Danone | GB | dairy | H | TODO | 2026-04-07 | | |
| 1622 | Danone Actimel Original (per bottle) | Danone | FR | dairy | M | TODO | 2026-04-07 | | |
| 1623 | Yakult Ace Light Korea (per bottle) | Yakult | KR | dairy | M | TODO | 2026-04-07 | | |
| 1624 | Kefir Lifeway Lowfat Plain (per cup) | Lifeway | US | dairy | M | TODO | 2026-04-07 | | |
| 1625 | Icelandic Provisions Skyr Strawberry | Icelandic Provisions | IS | dairy | M | TODO | 2026-04-07 | | |
| 1627 | Olympic Krema Greek Yogurt (per 100g) | Olympic | CA | dairy | M | TODO | 2026-04-07 | | |
| 1628 | Jalna Pot Set Yoghurt (per 100g) | Jalna | AU | dairy | M | TODO | 2026-04-07 | | |
| 1630 | Lewis Road Creamery Chocolate Milk (per 250ml) | Lewis Road | NZ | dairy | M | TODO | 2026-04-07 | | NZ cult product |

## Section 53: International Sauces, Pastes & Cooking Ingredients (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1631 | S&B Golden Curry Sauce Mix (per serving) | S&B | JP | condiment | M | TODO | 2026-04-07 | | Japanese curry block |
| 1632 | House Vermont Curry Medium (per serving) | House | JP | condiment | M | TODO | 2026-04-07 | | |
| 1635 | Mirin Hon (per tbsp) | Various | JP | condiment | M | TODO | 2026-04-07 | | |
| 1638 | CJ Gochugaru Korean Chili Flakes (per tbsp) | CJ | KR | condiment | M | TODO | 2026-04-07 | | |
| 1641 | Mae Ploy Green Curry Paste (per tbsp) | Mae Ploy | TH | condiment | M | TODO | 2026-04-07 | | |
| 1642 | Mae Ploy Red Curry Paste (per tbsp) | Mae Ploy | TH | condiment | M | TODO | 2026-04-07 | | |
| 1645 | Maggi Seasoning Sauce (per tsp) | Maggi | DE | condiment | M | TODO | 2026-04-07 | | German Maggi different from Asian |
| 1646 | Knorr Aromat Seasoning (per tsp) | Knorr | ZA | condiment | M | TODO | 2026-04-07 | | SA staple |
| 1647 | Chimichurri Sauce (per tbsp) | Various | AR | condiment | M | TODO | 2026-04-07 | | |
| 1648 | Ají Amarillo Paste (per tbsp) | Various | PE | condiment | M | TODO | 2026-04-07 | | |
| 1649 | Harissa Paste (per tbsp) | Various | TN | condiment | M | TODO | 2026-04-07 | | |
| 1650 | Berbere Spice Mix (per tsp) | Various | ET | condiment | M | TODO | 2026-04-07 | | |
| 1651 | Ras el Hanout (per tsp) | Various | MA | condiment | M | TODO | 2026-04-07 | | |
| 1653 | Ajvar Red Pepper Relish (per tbsp) | Various | RS | condiment | M | TODO | 2026-04-07 | | Balkan staple |
| 1654 | Tkemali Georgian Plum Sauce (per tbsp) | Various | GE | condiment | M | TODO | 2026-04-07 | | |
| 1656 | Mango Chutney Patak's (per tbsp) | Patak's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1657 | Lime Pickle Patak's (per tbsp) | Patak's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1658 | Tikka Masala Paste Patak's (per tbsp) | Patak's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1659 | Nando's Garlic PERInaise (per tbsp) | Nando's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1660 | Henderson's Relish (per tbsp) | Henderson's | GB | condiment | M | TODO | 2026-04-07 | | Sheffield staple |
| 1661 | Colman's English Mustard (per tsp) | Colman's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1662 | Hellmann's Vegan Mayo (per tbsp) | Hellmann's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1664 | Pesto alla Genovese Barilla (per tbsp) | Barilla | IT | condiment | M | TODO | 2026-04-07 | | |
| 1665 | Pomì Passata Tomato Sauce (per 100g) | Pomì | IT | condiment | M | TODO | 2026-04-07 | | |
| 1666 | Ketchup Heinz (per tbsp) | Heinz | US | condiment | M | TODO | 2026-04-07 | | |
| 1669 | Trader Joe's Green Goddess Dressing (per tbsp) | Trader Joe's | US | condiment | M | TODO | 2026-04-07 | | |
| 1670 | Fly by Jing Sichuan Chili Crisp (per tbsp) | Fly by Jing | US | condiment | M | TODO | 2026-04-07 | | Trendy |

## Section 54: International Frozen Foods & Ready Meals (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1671 | Amy's Kitchen Pad Thai (per serving) | Amy's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1672 | Amy's Kitchen Black Bean Enchilada (per serving) | Amy's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1674 | Healthy Choice Power Bowls Chicken Feta | Healthy Choice | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1675 | Tatty's Chicken Pie (per pie) | Tatty's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1676 | Young's Scampi (per serving) | Young's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1677 | Aunt Bessie's Yorkshire Puddings (per piece) | Aunt Bessie's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1679 | Magnum Mini Classic (per piece) | Magnum | NL | dessert | M | TODO | 2026-04-07 | | |
| 1681 | Häagen-Dazs Vanilla (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | | |
| 1682 | Viennetta Vanilla (per slice) | Wall's | GB | dessert | M | TODO | 2026-04-07 | | |
| 1683 | Solero Exotic (per bar) | Wall's | GB | dessert | M | TODO | 2026-04-07 | | |
| 1684 | Calippo Orange (per piece) | Wall's | GB | dessert | L | TODO | 2026-04-07 | | |
| 1686 | Ajinomoto Yakitori Chicken (per serving) | Ajinomoto | JP | frozen_meal | M | TODO | 2026-04-07 | | |
| 1691 | Strong Roots Mixed Root Vegetable Fries (per serving) | Strong Roots | IE | frozen_meal | M | TODO | 2026-04-07 | | |
| 1692 | Cook Frozen Meals Chicken Tikka | Cook | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1693 | Pieminister Moo Pie (per pie) | Pieminister | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1695 | Buitoni Buitoni Gyoza Chicken (per 5 pieces) | Buitoni | FR | frozen_meal | M | TODO | 2026-04-07 | | |
| 1696 | Picard Macarons Assortment (per piece) | Picard | FR | dessert | M | TODO | 2026-04-07 | | |
| 1698 | ITC Kitchen of India Paneer Makhani (per serving) | ITC | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1699 | Tasty Bite Indian Madras Lentils (per serving) | Tasty Bite | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1700 | Maya Kaimal Everyday Dal Turmeric (per serving) | Maya Kaimal | US | ready_meal | M | TODO | 2026-04-07 | | |
| 1702 | Wei-Chuan Pork & Chive Dumplings (per 5 pieces) | Wei-Chuan | TW | frozen_meal | M | TODO | 2026-04-07 | | |
| 1704 | Schar Gluten Free Pizza Base (per base) | Schar | IT | frozen_meal | M | TODO | 2026-04-07 | | |
| 1705 | Quorn Crispy Nuggets (per 5 pieces) | Quorn | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1706 | Fry's Plant-Based Chicken Strips (per 100g) | Fry's | ZA | frozen_meal | M | TODO | 2026-04-07 | | SA plant-based |
| 1707 | Findus Grönsakspytt (per serving) | Findus | SE | frozen_meal | M | TODO | 2026-04-07 | | |
| 1708 | Gorton's Fish Sticks (per 6 sticks) | Gorton's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1710 | Stouffer's Lasagna with Meat Sauce (per serving) | Stouffer's | US | frozen_meal | M | TODO | 2026-04-07 | | |

## Section 55: More International Snacks & Treats (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1716 | Twix Original (per bar) | Mars | US | chocolate | M | TODO | 2026-04-07 | | |
| 1717 | Snickers Original (per bar) | Mars | US | chocolate | M | TODO | 2026-04-07 | | |
| 1721 | Kit Kat Original (per 4 finger) | Nestle | US | chocolate | M | TODO | 2026-04-07 | | |
| 1722 | Butterfinger Original (per bar) | Ferrero | US | chocolate | M | TODO | 2026-04-07 | | |
| 1723 | Twizzlers Strawberry (per 4 pieces) | Hershey's | US | confectionery | M | TODO | 2026-04-07 | | |
| 1727 | Trolli Sour Brite Crawlers (per 100g) | Ferrara | US | confectionery | L | TODO | 2026-04-07 | | |
| 1732 | Cheez-It Original (per 27 crackers) | Kellogg's | US | snack | M | TODO | 2026-04-07 | | |
| 1734 | Annie's Cheddar Bunnies (per 50 pieces) | Annie's | US | snack | M | TODO | 2026-04-07 | | |
| 1736 | Skinny Pop Sea Salt (per 100g) | Skinny Pop | US | snack | M | TODO | 2026-04-07 | | |
| 1737 | Boom Chicka Pop Sea Salt (per 100g) | Angie's | US | snack | M | TODO | 2026-04-07 | | |
| 1738 | Sahale Snacks Maple Pecans Glazed Mix (per 30g) | Sahale | US | snack | M | TODO | 2026-04-07 | | |
| 1739 | Sun Chips Original (per 100g) | Frito-Lay | US | snack | M | TODO | 2026-04-07 | | |
| 1740 | Terra Exotic Vegetable Chips (per 100g) | Terra | US | snack | M | TODO | 2026-04-07 | | |
| 1746 | Nilla Wafers (per 8 wafers) | Nabisco | US | biscuit | M | TODO | 2026-04-07 | | |
| 1748 | Cadbury Wispa (per bar) | Cadbury | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1750 | Galaxy Smooth Milk (per bar) | Mars | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1752 | Aero Mint Chocolate (per bar) | Nestle | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1754 | Wine Gums Maynards Bassetts (per 100g) | Cadbury | GB | confectionery | M | TODO | 2026-04-07 | | |
| 1755 | Jelly Babies Bassetts (per 100g) | Cadbury | GB | confectionery | M | TODO | 2026-04-07 | | |
| 1756 | Fruit Pastilles Rowntree's (per 100g) | Nestle | GB | confectionery | M | TODO | 2026-04-07 | | |
| 1757 | Mentos Original (per piece) | Perfetti | NL | confectionery | L | TODO | 2026-04-07 | | |
| 1758 | Tic Tac Fresh Mint (per piece) | Ferrero | IT | confectionery | L | TODO | 2026-04-07 | | |
| 1759 | Chupa Chups Strawberry (per lollipop) | Perfetti | ES | confectionery | L | TODO | 2026-04-07 | | |
| 1760 | Tunnock's Caramel Wafer (per piece) | Tunnock's | GB | biscuit | M | TODO | 2026-04-07 | | Scottish icon |

## Section 56: More International Breads & Breakfast (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1761 | Brioche Pasquier (per piece) | Pasquier | FR | bread | M | TODO | 2026-04-07 | | |
| 1762 | Harry's American Sandwich Bread (per slice) | Harry's | FR | bread | M | TODO | 2026-04-07 | | |
| 1763 | Jacquet Toast Bread (per slice) | Jacquet | FR | bread | M | TODO | 2026-04-07 | | |
| 1765 | Country Harvest Multigrain Bread (per slice) | Country Harvest | CA | bread | M | TODO | 2026-04-07 | | |
| 1766 | Tip Top Wholemeal Bread (per slice) | Tip Top | AU | bread | M | TODO | 2026-04-07 | | |
| 1767 | Helga's Continental Bakehouse Sourdough (per slice) | Helga's | AU | bread | M | TODO | 2026-04-07 | | |
| 1768 | Vogel's Mixed Grain Bread (per slice) | Vogel's | NZ | bread | M | TODO | 2026-04-07 | | |
| 1769 | Kingsmill 50/50 (per slice) | Kingsmill | GB | bread | M | TODO | 2026-04-07 | | |
| 1770 | Burgen Soya & Linseed Bread (per slice) | Burgen | GB | bread | H | TODO | 2026-04-07 | | High protein bread |
| 1773 | Crumpet Warburtons (per piece) | Warburtons | GB | bread | M | TODO | 2026-04-07 | | British icon |
| 1775 | Bagel Thomas' Everything (per piece) | Thomas' | US | bread | M | TODO | 2026-04-07 | | |
| 1776 | Pop-Tarts Frosted Strawberry (per pastry) | Kellogg's | US | breakfast | M | TODO | 2026-04-07 | | |
| 1777 | Eggo Waffles Buttermilk (per 2 waffles) | Kellogg's | US | breakfast | M | TODO | 2026-04-07 | | |
| 1778 | Nature's Path Organic Toaster Pastry (per pastry) | Nature's Path | CA | breakfast | M | TODO | 2026-04-07 | | |
| 1781 | Weetabix Original (per 2 biscuits) | Weetabix | GB | cereal | H | TODO | 2026-04-07 | | |
| 1782 | Shreddies Original (per serving) | Nestle | GB | cereal | M | TODO | 2026-04-07 | | |
| 1783 | Crunchy Nut Cornflakes (per serving) | Kellogg's | GB | cereal | M | TODO | 2026-04-07 | | |
| 1784 | Coco Pops (per serving) | Kellogg's | GB | cereal | M | TODO | 2026-04-07 | | |
| 1785 | Alpen Muesli No Added Sugar (per serving) | Alpen | GB | cereal | M | TODO | 2026-04-07 | | |
| 1786 | Dorset Cereals Simply Delicious Muesli (per serving) | Dorset | GB | cereal | M | TODO | 2026-04-07 | | |
| 1787 | Quaker Oat So Simple Original (per sachet) | Quaker | GB | cereal | M | TODO | 2026-04-07 | | |
| 1788 | Ready Brek Original (per serving) | Weetabix | GB | cereal | M | TODO | 2026-04-07 | | |
| 1789 | Koko Krunch Nestle (per serving) | Nestle | MY | cereal | M | TODO | 2026-04-07 | | SE Asia cereal |
| 1790 | Chocos Kellogg's (per serving) | Kellogg's | IN | cereal | M | TODO | 2026-04-07 | | India popular |

## Section 57: Remaining Items to Hit 1000+ New (240 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1794 | GoMacro Protein Pleasure Bar Peanut Butter Chocolate | GoMacro | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1801 | Pukka Pie Steak & Kidney (per pie) | Pukka | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1802 | Fray Bentos Steak & Kidney Pie (per tin) | Fray Bentos | GB | ready_meal | M | TODO | 2026-04-07 | | |
| 1804 | Baxters Highlander's Broth (per serving) | Baxters | GB | soup | M | TODO | 2026-04-07 | | |
| 1808 | Victoria Fine Foods Marinara (per serving) | Victoria | US | condiment | M | TODO | 2026-04-07 | | |
| 1809 | Annie's Organic Ketchup (per tbsp) | Annie's | US | condiment | L | TODO | 2026-04-07 | | |
| 1811 | Siete Cashew Queso (per tbsp) | Siete | US | condiment | M | TODO | 2026-04-07 | | |
| 1812 | Ithaca Hummus Classic (per tbsp) | Ithaca | US | dip | M | TODO | 2026-04-07 | | |
| 1818 | Tillamook Farmstyle Thick Cut Sharp Cheddar (per slice) | Tillamook | US | dairy | M | TODO | 2026-04-07 | | |
| 1819 | Cabot Seriously Sharp Cheddar (per 30g) | Cabot | US | dairy | M | TODO | 2026-04-07 | | |
| 1820 | Boursin Plant-Based Garlic & Herbs (per 30g) | Boursin | FR | dairy_alt | M | TODO | 2026-04-07 | | |
| 1821 | Nairn's Oat Crackers (per 4 crackers) | Nairn's | GB | snack | M | TODO | 2026-04-07 | | |
| 1822 | Ryvita Crispbread Original (per 2 slices) | Ryvita | GB | bread | M | TODO | 2026-04-07 | | |
| 1824 | Jacob's Cream Crackers (per 2 crackers) | Jacob's | GB | snack | M | TODO | 2026-04-07 | | |
| 1825 | Mini Cheddars Original (per bag 25g) | Jacob's | GB | snack | M | TODO | 2026-04-07 | | |
| 1826 | Skips Prawn Cocktail (per bag 17g) | KP | GB | snack | L | TODO | 2026-04-07 | | |
| 1827 | Space Raiders Pickled Onion (per bag) | KP | GB | snack | L | TODO | 2026-04-07 | | |
| 1828 | Monster Munch Roast Beef (per bag 25g) | Walkers | GB | snack | M | TODO | 2026-04-07 | | |
| 1829 | Quavers Cheese (per bag 16g) | Walkers | GB | snack | M | TODO | 2026-04-07 | | |
| 1830 | Wotsits Really Cheesy (per bag 17g) | Walkers | GB | snack | M | TODO | 2026-04-07 | | |
| 1831 | Jammie Dodgers (per biscuit) | Burton's | GB | biscuit | M | TODO | 2026-04-07 | | |
| 1832 | Bourbon Cream Biscuit (per biscuit) | Various | GB | biscuit | M | TODO | 2026-04-07 | | |
| 1833 | Custard Cream Biscuit (per biscuit) | Various | GB | biscuit | M | TODO | 2026-04-07 | | |
| 1834 | Bourbon Alfort Mini Chocolate (per piece) | Bourbon | JP | biscuit | M | TODO | 2026-04-07 | | |
| 1835 | Toppo Chocolate (per box) | Lotte | JP | biscuit | M | TODO | 2026-04-07 | | |
| 1836 | Pepero Almond (per box) | Lotte | KR | confectionery | M | TODO | 2026-04-07 | | |
| 1837 | Melona Ice Bar Melon (per bar) | Binggrae | KR | dessert | M | TODO | 2026-04-07 | | |
| 1838 | Samanco Ice Cream Fish (per piece) | Binggrae | KR | dessert | M | TODO | 2026-04-07 | | |
| 1839 | Dalgona Coffee (per serving homemade) | Various | KR | beverage | M | TODO | 2026-04-07 | | |
| 1841 | Yuja Tea Korean Citron (per serving) | Various | KR | beverage | M | TODO | 2026-04-07 | | |
| 1842 | Buldak Sauce (bottle per tbsp) | Samyang | KR | condiment | H | TODO | 2026-04-07 | | |
| 1843 | Ssamjang Dipping Paste (per tbsp) | CJ | KR | condiment | M | TODO | 2026-04-07 | | |
| 1844 | Spam Classic (per 56g serving) | Hormel | US | protein | M | TODO | 2026-04-07 | | Huge in Asia/Hawaii |
| 1845 | Vienna Sausages Libby's (per can) | Libby's | US | protein | L | TODO | 2026-04-07 | | |
| 1846 | Spam Lite (per 56g serving) | Hormel | US | protein | M | TODO | 2026-04-07 | | |
| 1847 | Skippy Peanut Butter Creamy (per tbsp) | Skippy | US | spread | M | TODO | 2026-04-07 | | |
| 1848 | Jif Peanut Butter Creamy (per tbsp) | Jif | US | spread | M | TODO | 2026-04-07 | | |
| 1850 | RX Nut Butter Chocolate Peanut Butter (per packet) | RX | US | spread | M | TODO | 2026-04-07 | | |
| 1852 | Dave's Killer Bread Powerseed Thin Sliced (per slice) | Dave's | US | bread | M | TODO | 2026-04-07 | | |
| 1853 | Franz Keto Bread (per slice) | Franz | US | bread | M | TODO | 2026-04-07 | | |
| 1854 | Oroweat Keto Bread (per slice) | Oroweat | US | bread | M | TODO | 2026-04-07 | | |
| 1855 | Unbun Keto Bun (per bun) | Unbun | CA | bread | M | TODO | 2026-04-07 | | |
| 1856 | Carbonaut Low Carb Bread (per slice) | Carbonaut | CA | bread | M | TODO | 2026-04-07 | | |
| 1857 | Cobs Bread Cape Seed Loaf (per slice) | Cobs | AU | bread | M | TODO | 2026-04-07 | | |
| 1858 | Bakers Delight Hi-Fibre Lo-GI Bread (per slice) | Bakers Delight | AU | bread | M | TODO | 2026-04-07 | | |
| 1859 | Manna Bread Whole Rye (per slice) | Various | DE | bread | M | TODO | 2026-04-07 | | |
| 1860 | Knäckebröd Crisp Bread Polarbröd (per piece) | Polarbröd | SE | bread | M | TODO | 2026-04-07 | | |
| 1861 | Flatbrød Norwegian Flatbread (per piece) | Various | NO | bread | M | TODO | 2026-04-07 | | |
| 1863 | Dosa Batter iD (per 2 dosa) | iD Fresh | IN | breakfast | H | TODO | 2026-04-07 | | |
| 1864 | Upma Rava MTR (per serving dry mix) | MTR | IN | breakfast | M | TODO | 2026-04-07 | | |
| 1865 | Poha Flattened Rice Thick (per 100g dry) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |
| 1866 | Sabudana (Tapioca Pearls per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1867 | Besan Chickpea Flour (per 100g) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1868 | Moong Dal Split Yellow (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1870 | Chana Dal Split Bengal Gram (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1871 | Toor Dal Pigeon Pea (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1873 | Urad Dal Black Gram (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1874 | Ghee Amul Pure (per tsp) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 1878 | Groundnut Oil Dhara (per tbsp) | Dhara | IN | cooking | M | TODO | 2026-04-07 | | |
| 1882 | Olio Award Winning EVOO (per tbsp) | Various | GR | cooking | M | TODO | 2026-04-07 | | |
| 1884 | MCT Oil Bulletproof (per tbsp) | Bulletproof | US | supplement | M | TODO | 2026-04-07 | | |
| 1885 | Hemp Hearts Manitoba Harvest (per 30g) | Manitoba Harvest | CA | supplement | M | TODO | 2026-04-07 | | |
| 1887 | Flaxseed Meal Bob's Red Mill (per tbsp) | Bob's Red Mill | US | supplement | M | TODO | 2026-04-07 | | |
| 1890 | Moringa Powder (per tsp) | Various | IN | supplement | M | TODO | 2026-04-07 | | |
| 1891 | Matcha Powder Ceremonial (per tsp) | Various | JP | supplement | M | TODO | 2026-04-07 | | |
| 1892 | Wheatgrass Powder (per tsp) | Various | US | supplement | L | TODO | 2026-04-07 | | |
| 1893 | Acai Powder Freeze Dried (per tbsp) | Various | BR | supplement | M | TODO | 2026-04-07 | | |
| 1894 | Maca Powder (per tsp) | Various | PE | supplement | M | TODO | 2026-04-07 | | |
| 1895 | Cacao Nibs Raw (per tbsp) | Various | PE | supplement | M | TODO | 2026-04-07 | | |
| 1901 | Monk Fruit Sweetener Lakanto (per tsp) | Lakanto | JP | condiment | M | TODO | 2026-04-07 | | |
| 1902 | Erythritol Swerve (per tsp) | Swerve | US | condiment | M | TODO | 2026-04-07 | | |
| 1903 | Stevia Drops SweetLeaf (per serving) | SweetLeaf | US | condiment | L | TODO | 2026-04-07 | | |
| 1904 | Sugar Free Syrup Jordan's Skinny Mixes Vanilla (per tbsp) | Jordan's | US | condiment | M | TODO | 2026-04-07 | | |
| 1905 | Torani Sugar Free Vanilla Syrup (per tbsp) | Torani | US | condiment | M | TODO | 2026-04-07 | | |
| 1906 | Monin Sugar Free Hazelnut Syrup (per tbsp) | Monin | FR | condiment | M | TODO | 2026-04-07 | | |
| 1907 | Biscoff Creamy Spread (per tbsp) | Lotus | BE | spread | M | TODO | 2026-04-07 | | |
| 1909 | Sun-Pat Crunchy Peanut Butter (per tbsp) | Sun-Pat | GB | spread | M | TODO | 2026-04-07 | | |
| 1910 | Whole Earth Smooth Peanut Butter (per tbsp) | Whole Earth | GB | spread | M | TODO | 2026-04-07 | | |
| 1911 | Bega Crunchy Peanut Butter (per tbsp) | Bega | AU | spread | M | TODO | 2026-04-07 | | |
| 1917 | Nocciolata Dairy Free Spread (per tbsp) | Rigoni | IT | spread | M | TODO | 2026-04-07 | | |
| 1918 | Lindt Hazelnut Spread (per tbsp) | Lindt | CH | spread | M | TODO | 2026-04-07 | | |
| 1920 | Boost Juice Original Berry Crush (per regular) | Boost Juice | AU | beverage | M | TODO | 2026-04-07 | | |
| 1921 | Guzman y Gomez Chicken Burrito | GYG | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1922 | Zambrero Chicken Power Burrito | Zambrero | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1924 | Pie Face Classic Mince Beef Pie (per pie) | Pie Face | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1925 | Wendy's NZ Classic Burger | Wendy's NZ | NZ | fast_food | M | TODO | 2026-04-07 | | Different from US |
| 1926 | BurgerFuel C.N.C. Burger | BurgerFuel | NZ | fast_food | M | TODO | 2026-04-07 | | NZ chain |
| 1928 | Hell Pizza Lust (per slice) | Hell Pizza | NZ | fast_food | M | TODO | 2026-04-07 | | NZ chain |
| 1930 | Sushiro Maguro Tuna Nigiri (per 2 pieces) | Sushiro | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1931 | Sukiya Gyudon Regular | Sukiya | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1932 | Matsuya Gyudon Regular | Matsuya | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1933 | Mos Burger Natsumi Burger (Seasonal) | Mos Burger | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1934 | Tendon Tenya Tendon Regular | Tendon Tenya | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1935 | Coco Curry House Pork Cutlet Curry | CoCo | JP | fast_food | M | TODO | 2026-04-07 | | |
| 1936 | Isaac Toast Original (Korea) | Isaac Toast | KR | fast_food | H | TODO | 2026-04-07 | | Korean street food chain |
| 1937 | Two Two Chicken Fried (per piece) | Two Two | KR | fast_food | M | TODO | 2026-04-07 | | |
| 1938 | BHC Chicken Gold King (per piece) | BHC | KR | fast_food | M | TODO | 2026-04-07 | | |
| 1939 | Pelicana Chicken Original (per piece) | Pelicana | KR | fast_food | M | TODO | 2026-04-07 | | |
| 1940 | Baekjeong Korean BBQ Galbi (per 100g) | Baekjeong | KR | fast_food | M | TODO | 2026-04-07 | | |
| 1941 | Tous les Jours Croquette Bread (per piece) | Tous les Jours | KR | bakery | M | TODO | 2026-04-07 | | |
| 1942 | Sulbing Injeolmi Bingsu (per serving) | Sulbing | KR | dessert | M | TODO | 2026-04-07 | | Korean dessert chain |
| 1943 | Baskin Robbins Korea Shooting Star (per scoop) | Baskin Robbins | KR | dessert | M | TODO | 2026-04-07 | | |
| 1944 | Compose Coffee Americano (per cup) | Compose | KR | beverage | M | TODO | 2026-04-07 | | Korea budget coffee |
| 1945 | Ediya Coffee Iced Americano (per cup) | Ediya | KR | beverage | M | TODO | 2026-04-07 | | |
| 1946 | Mega Coffee Americano (per cup) | Mega | KR | beverage | M | TODO | 2026-04-07 | | |
| 1947 | Caffé Bene Iced Caramel Macchiato (per cup) | Caffé Bene | KR | beverage | M | TODO | 2026-04-07 | | |
| 1948 | Din Tai Fung Xiao Long Bao (per 5 pieces) | Din Tai Fung | TW | fast_food | H | TODO | 2026-04-07 | | |
| 1950 | Tim Ho Wan BBQ Pork Bun (per piece) | Tim Ho Wan | HK | fast_food | M | TODO | 2026-04-07 | | Michelin starred |
| 1952 | Heytea Cheese Tea Green (per M) | Heytea | CN | beverage | M | TODO | 2026-04-07 | | China trending |
| 1953 | Luckin Coffee Latte (per cup) | Luckin | CN | beverage | M | TODO | 2026-04-07 | | China #1 coffee |
| 1954 | Mixue Ice Cream (per serving) | Mixue | CN | dessert | M | TODO | 2026-04-07 | | World's largest chain |
| 1955 | Mixue Lemon Tea (per M) | Mixue | CN | beverage | M | TODO | 2026-04-07 | | |
| 1956 | Haidilao Hot Pot Broth Base Tomato (per serving) | Haidilao | CN | condiment | M | TODO | 2026-04-07 | | |
| 1958 | Orion Chocopie (per piece) | Orion | CN | biscuit | M | TODO | 2026-04-07 | | China version |
| 1959 | Wangzai Milk (per 125ml) | Want Want | CN | dairy | M | TODO | 2026-04-07 | | Chinese childhood drink |
| 1960 | Lay's Cucumber Flavor (China) | Lay's | CN | snack | M | TODO | 2026-04-07 | | China exclusive |
| 1961 | Lay's Braised Pork (China) | Lay's | CN | snack | M | TODO | 2026-04-07 | | |
| 1962 | White Rabbit Matcha Candy (per piece) | White Rabbit | CN | confectionery | M | TODO | 2026-04-07 | | |
| 1963 | Guoba Rice Cracker Spicy (per 100g) | Various | CN | snack | M | TODO | 2026-04-07 | | |
| 1964 | Weilong Latiao Spicy Strip (per 100g) | Weilong | CN | snack | H | TODO | 2026-04-07 | | China viral snack |
| 1965 | Old Yanjing Beer (per 330ml) | Yanjing | CN | beverage | L | TODO | 2026-04-07 | | |
| 1966 | Tsingtao Beer (per 330ml) | Tsingtao | CN | beverage | L | TODO | 2026-04-07 | | |
| 1967 | Sapporo Premium Beer (per 330ml) | Sapporo | JP | beverage | L | TODO | 2026-04-07 | | |
| 1968 | Asahi Super Dry Beer (per 330ml) | Asahi | JP | beverage | L | TODO | 2026-04-07 | | |
| 1969 | Kirin Ichiban Beer (per 330ml) | Kirin | JP | beverage | L | TODO | 2026-04-07 | | |
| 1970 | Tiger Crystal Beer (per 330ml) | Tiger | SG | beverage | L | TODO | 2026-04-07 | | |
| 1971 | San Miguel Pale Pilsen (per 330ml) | San Miguel | PH | beverage | L | TODO | 2026-04-07 | | |
| 1972 | Bintang Beer (per 330ml) | Bintang | ID | beverage | L | TODO | 2026-04-07 | | |
| 1973 | Kingfisher Premium Lager (per 330ml) | Kingfisher | IN | beverage | L | TODO | 2026-04-07 | | |
| 1974 | Efes Pilsen (per 330ml) | Efes | TR | beverage | L | TODO | 2026-04-07 | | |
| 1975 | Corona Extra (per 330ml) | Corona | MX | beverage | L | TODO | 2026-04-07 | | |
| 1976 | Hite Extra Cold Beer (per 330ml) | Hite | KR | beverage | L | TODO | 2026-04-07 | | |
| 1977 | OB Lager Beer (per 330ml) | OB | KR | beverage | L | TODO | 2026-04-07 | | |
| 1978 | Tooheys New Lager (per 375ml) | Tooheys | AU | beverage | L | TODO | 2026-04-07 | | |
| 1979 | XXXX Gold Lager (per 375ml) | XXXX | AU | beverage | L | TODO | 2026-04-07 | | Queensland icon |
| 1980 | Steinlager Pure (per 330ml) | Steinlager | NZ | beverage | L | TODO | 2026-04-07 | | |
| 1981 | Tui East India Pale Ale (per 330ml) | Tui | NZ | beverage | L | TODO | 2026-04-07 | | |
| 1983 | Teh Tarik Singapore (per cup) | Various | SG | beverage | M | TODO | 2026-04-07 | | |
| 1987 | Ice Kacang ABC (per serving) | Various | MY | dessert | M | TODO | 2026-04-07 | | |
| 1988 | Chendol Singapore (per serving) | Various | SG | dessert | M | TODO | 2026-04-07 | | |
| 1991 | Turon Banana Spring Roll Philippines (per piece) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1993 | Ube Halaya Purple Yam Jam (per tbsp) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1994 | Bibingka Rice Cake Philippines (per piece) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1996 | Che Ba Mau Vietnamese Dessert (per serving) | Various | VN | dessert | M | TODO | 2026-04-07 | | |
| 1998 | Khanom Buang Thai Crispy Pancake (per piece) | Various | TH | dessert | M | TODO | 2026-04-07 | | |
| 1999 | Khanom Krok Thai Coconut Pancake (per piece) | Various | TH | dessert | M | TODO | 2026-04-07 | | |
| 2003 | Barfi Kaju Katli (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2005 | Ladoo Motichoor (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2007 | Peda Milk Sweet (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2009 | Kulfi Mango (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2010 | Payasam Kerala Rice Pudding (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2011 | Modak Steamed Sweet (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2012 | Shrikhand Sweet Yogurt (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2015 | Basundi Thick Sweetened Milk (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2016 | Thandai Spiced Milk (per cup) | Various | IN | beverage | M | TODO | 2026-04-07 | | |
| 2017 | Aam Ras Mango Puree (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2018 | Falooda Rose (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2019 | Rabri Thickened Milk Sweet (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2021 | Samosa Aloo (per piece) | Various | IN | snack | H | TODO | 2026-04-07 | | |
| 2022 | Vada Pav Mumbai (per piece) | Various | IN | fast_food | H | TODO | 2026-04-07 | | |
| 2024 | Chole Bhature (per serving) | Various | IN | fast_food | H | TODO | 2026-04-07 | | |
| 2025 | Masala Dosa (per piece) | Various | IN | breakfast | H | TODO | 2026-04-07 | | |
| 2026 | Medu Vada (per piece) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |
| 2027 | Poori with Aloo (per piece + serving) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |
| 2028 | Aloo Paratha (per piece) | Various | IN | breakfast | H | TODO | 2026-04-07 | | |

## Section 58: Items from User Food Log (Missing from DB)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2032 | Oat Milk Latte (per 16oz cup) | Various | US | beverage | H | TODO | 2026-04-07 | | Coffee shop standard |
| 2033 | Carne Apache Mexican Raw Beef Dish (per serving) | Various | MX | protein | H | TODO | 2026-04-07 | | Mexican street food - raw beef cured in lime |
| 2034 | Goobne Oven Crispy Chicken Original (per piece) | Goobne | KR | fast_food | H | TODO | 2026-04-07 | | Korean oven-roasted chicken chain |
| 2035 | Goobne Oven Crispy Chicken Soy Garlic (per piece) | Goobne | KR | fast_food | M | TODO | 2026-04-07 | | |
| 2036 | Elote Cup Mexican Street Corn (per cup) | Various | MX | snack | H | TODO | 2026-04-07 | | Corn with mayo, chili, lime, cheese |

---

## Section 59: From foods_needed.md - Missing Items (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2041 | Hungry Jack's Whopper (Australia) | Hungry Jack's | AU | fast_food | H | TODO | 2026-04-07 | | Australian Burger King |
| 2042 | Hungry Jack's Stunner Meal | Hungry Jack's | AU | fast_food | M | TODO | 2026-04-07 | | |
| 2043 | Concha Mexican Sweet Bread (per piece) | Various | MX | bread | H | TODO | 2026-04-07 | | Pan dulce icon |
| 2044 | Vindaloo Curry (per serving) | Various | IN | curry | H | TODO | 2026-04-07 | | Goan Portuguese-Indian |
| 2045 | Hush Puppy Deep Fried Cornmeal (per piece) | Various | US | snack | M | TODO | 2026-04-07 | | Southern US |
| 2046 | Pine Nuts (per 30g) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 2047 | Escargot in Garlic Butter (per 6 pieces) | Various | FR | protein | M | TODO | 2026-04-07 | | |
| 2048 | Wasabi Paste (per tsp) | Various | JP | condiment | M | TODO | 2026-04-07 | | |
| 2049 | Gushers Fruit Snack (per pouch) | Betty Crocker | US | confectionery | M | TODO | 2026-04-07 | | |
| 2050 | Radish Raw (per 100g) | Various | US | vegetable | L | TODO | 2026-04-07 | | |
| 2051 | Parsnip Cooked (per 100g) | Various | GB | vegetable | M | TODO | 2026-04-07 | | |
| 2052 | Rutabaga Cooked (per 100g) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 2053 | Beetroot Cooked (per 100g) | Various | GB | vegetable | M | TODO | 2026-04-07 | | |
| 2054 | Pistachios Roasted Salted (per 30g) | Various | US | snack | H | TODO | 2026-04-07 | | |
| 2055 | Durian Fresh (per 100g) | Various | MY | fruit | M | TODO | 2026-04-07 | | |
| 2056 | Strawberry Fresh (per 100g) | Various | US | fruit | H | TODO | 2026-04-07 | | |
| 2057 | Chalupa Taco Bell (per piece) | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | | |
| 2058 | Paella Valenciana (per serving) | Various | ES | rice | H | TODO | 2026-04-07 | | |
| 2059 | Cayenne Pepper Ground (per tsp) | Various | US | condiment | L | TODO | 2026-04-07 | | |
| 2061 | Hazelnut Raw (per 30g) | Various | TR | snack | M | TODO | 2026-04-07 | | |
| 2063 | Mirepoix (per 100g) | Various | FR | vegetable | L | TODO | 2026-04-07 | | Celery carrot onion mix |
| 2064 | Foie Gras (per 30g) | Various | FR | protein | M | TODO | 2026-04-07 | | |
| 2065 | Quiznos Classic Italian Sub (per 8-inch) | Quiznos | US | fast_food | M | TODO | 2026-04-07 | | |
| 2066 | Dunkaroos (per pack) | Betty Crocker | US | snack | M | TODO | 2026-04-07 | | |
| 2067 | Kelp Fries (per serving) | Various | US | snack | M | TODO | 2026-04-07 | | Health food trend |
| 2068 | Dippin' Dots Ice Cream (per serving) | Dippin' Dots | US | dessert | M | TODO | 2026-04-07 | | |
| 2069 | Popsicle Fruit Bar (per bar) | Popsicle | US | dessert | M | TODO | 2026-04-07 | | |
| 2070 | Jelly Belly Jelly Beans (per 35 pieces) | Jelly Belly | US | confectionery | M | TODO | 2026-04-07 | | |
| 2072 | Mocha Coffee Latte (per 16oz) | Various | US | beverage | H | TODO | 2026-04-07 | | |
| 2073 | Negroni Cocktail (per glass) | Various | IT | beverage | M | TODO | 2026-04-07 | | |
| 2074 | Okra Fried (per 100g) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 2075 | Goulash Hungarian (per serving) | Various | HU | soup | M | TODO | 2026-04-07 | | |
| 2076 | Cheddar Bay Biscuit Red Lobster (per piece) | Red Lobster | US | bread | M | TODO | 2026-04-07 | | |
| 2078 | Apricot Fresh (per piece) | Various | TR | fruit | M | TODO | 2026-04-07 | | |
| 2079 | Dahi Vada (per piece) | Various | IN | snack | H | TODO | 2026-04-07 | | |

## Section 60: From WRONG_FOOD_MATCHES.md - Generic Entries Needed (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2081 | Water Plain (per 100ml) | Various | US | beverage | H | TODO | 2026-04-07 | | 0 cal - prevents wrong matches |
| 2082 | Salt Table (per tsp) | Various | US | condiment | H | TODO | 2026-04-07 | | 0 cal - prevents wrong matches |
| 2083 | Black Pepper Ground (per tsp) | Various | US | condiment | H | TODO | 2026-04-07 | | |
| 2085 | Cola Generic Soda (per can 355ml) | Various | US | beverage | H | TODO | 2026-04-07 | | |
| 2086 | Cantaloupe Melon (per 100g) | Various | US | fruit | M | TODO | 2026-04-07 | | Prevents melon→smoothie match |
| 2087 | Salad Dressing Generic (per tbsp) | Various | US | condiment | H | TODO | 2026-04-07 | | Prevents dressing→stuffing match |
| 2088 | Custard Dessert (per serving) | Various | GB | dessert | M | TODO | 2026-04-07 | | |
| 2092 | Candy Generic (per piece) | Various | US | confectionery | M | TODO | 2026-04-07 | | |
| 2093 | Cereal Generic (per serving) | Various | US | cereal | M | TODO | 2026-04-07 | | |

## Section 61: Street Food - Top Priority Countries (200 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2097 | Chuan'r Lamb Skewer Street Grill (per stick) | Various | CN | street_food | H | TODO | 2026-04-07 | | |
| 2098 | Chuan'r Chicken Heart Skewer (per stick) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 2099 | Chuan'r Squid Skewer (per stick) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 2100 | Rou Jia Mo Chinese Meat Burger (per piece) | Various | CN | street_food | H | TODO | 2026-04-07 | | "Chinese hamburger" |
| 2101 | Scallion Pancake Cong You Bing (per piece) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 2102 | Stinky Tofu Chou Doufu Fried (per serving) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 2103 | Tanghulu Candied Hawthorn (per stick) | Various | CN | street_food | M | TODO | 2026-04-07 | | TikTok viral |
| 2104 | Boba Tea Street Stand Classic Milk Tea (per cup) | Various | CN | street_food | H | TODO | 2026-04-07 | | |
| 2105 | Malatang Sichuan Hot Pot Street (per serving) | Various | CN | street_food | M | TODO | 2026-04-07 | | |
| 2106 | Takoyaki Street Stand (per 6 pieces) | Various | JP | street_food | H | TODO | 2026-04-07 | | Osaka icon |
| 2107 | Yakitori Street Grill Chicken Thigh (per stick) | Various | JP | street_food | H | TODO | 2026-04-07 | | |
| 2108 | Yakitori Street Grill Tsukune (per stick) | Various | JP | street_food | M | TODO | 2026-04-07 | | Chicken meatball |
| 2109 | Okonomiyaki Street Stand (per piece) | Various | JP | street_food | M | TODO | 2026-04-07 | | |
| 2110 | Taiyaki Street Cart Red Bean (per piece) | Various | JP | street_food | M | TODO | 2026-04-07 | | |
| 2112 | Crepe Stand Strawberry Cream Harajuku (per piece) | Various | JP | street_food | M | TODO | 2026-04-07 | | |
| 2113 | Karaage Stand Street Fried Chicken (per serving) | Various | JP | street_food | M | TODO | 2026-04-07 | | |
| 2114 | Tteokbokki Street Cart (per serving) | Various | KR | street_food | H | TODO | 2026-04-07 | | |
| 2115 | Korean Corn Dog Street Hotteok (per piece) | Various | KR | street_food | H | TODO | 2026-04-07 | | Cheese-stuffed |
| 2116 | Odeng Fish Cake Street (per stick) | Various | KR | street_food | M | TODO | 2026-04-07 | | |
| 2117 | Hotteok Sweet Pancake Street (per piece) | Various | KR | street_food | M | TODO | 2026-04-07 | | |
| 2118 | Bungeoppang Fish Shaped Waffle (per piece) | Various | KR | street_food | M | TODO | 2026-04-07 | | |
| 2119 | Gyeranppang Egg Bread Street (per piece) | Various | KR | street_food | M | TODO | 2026-04-07 | | |
| 2122 | Doner Box with Fries (per serving) | Various | DE | street_food | H | TODO | 2026-04-07 | | |
| 2123 | Currywurst Stand with Pommes (per serving) | Various | DE | street_food | H | TODO | 2026-04-07 | | |
| 2124 | Bratwurst Stand im Brötchen (per piece) | Various | DE | street_food | M | TODO | 2026-04-07 | | |
| 2125 | Fischbrötchen Bismarck Herring (per piece) | Various | DE | street_food | M | TODO | 2026-04-07 | | North German |
| 2126 | Crepe Stand Nutella Banana (per piece) | Various | FR | street_food | H | TODO | 2026-04-07 | | |
| 2127 | Crepe Stand Ham Cheese Egg (per piece) | Various | FR | street_food | H | TODO | 2026-04-07 | | Galette complète |
| 2128 | Kebab Stand Shawarma Paris (per wrap) | Various | FR | street_food | M | TODO | 2026-04-07 | | |
| 2129 | Baguette Sandwich Jambon Beurre (per piece) | Various | FR | street_food | H | TODO | 2026-04-07 | | France #1 sandwich |
| 2131 | Kebab Van Chicken Doner (per wrap) | Various | GB | street_food | H | TODO | 2026-04-07 | | |
| 2132 | Kebab Van Lamb Doner Meat & Chips | Various | GB | street_food | M | TODO | 2026-04-07 | | |
| 2133 | Jacket Potato Van Cheese & Beans | Various | GB | street_food | M | TODO | 2026-04-07 | | |
| 2134 | Pie & Mash Stand Steak Pie | Various | GB | street_food | M | TODO | 2026-04-07 | | |
| 2137 | Sev Puri Street Cart (per plate) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 2138 | Dahi Puri Street Cart (per plate) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 2141 | Dosa Street Cart Masala (per piece) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 2142 | Egg Roll Kolkata Street (per piece) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 2144 | Mirchi Bajji Chilli Fritter Street (per piece) | Various | IN | street_food | M | TODO | 2026-04-07 | | |
| 2145 | Chai Street Cart (per cup) | Various | IN | street_food | H | TODO | 2026-04-07 | | Cutting chai |
| 2147 | Tacos de Birria Street (per taco) | Various | MX | street_food | H | TODO | 2026-04-07 | | |
| 2148 | Tacos de Carnitas Street (per taco) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 2149 | Tacos de Barbacoa Street (per taco) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 2150 | Tamales Street Cart Pork (per piece) | Various | MX | street_food | H | TODO | 2026-04-07 | | |
| 2151 | Gorditas Street Cart (per piece) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 2152 | Torta Ahogada Street (per piece) | Various | MX | street_food | M | TODO | 2026-04-07 | | Guadalajara specialty |
| 2153 | Tlayuda Oaxacan Street Pizza (per piece) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 2154 | Churros Street Cart with Chocolate (per 3) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 2155 | Elotes Grilled Corn Street Cart (per ear) | Various | MX | street_food | M | TODO | 2026-04-07 | | |
| 2156 | Gyros Pork Stand Greece (per wrap) | Various | GR | street_food | H | TODO | 2026-04-07 | | |
| 2157 | Souvlaki Chicken Stand (per stick) | Various | GR | street_food | M | TODO | 2026-04-07 | | |
| 2161 | Thai Grilled Pork Skewer Moo Ping (per stick) | Various | TH | street_food | M | TODO | 2026-04-07 | | |
| 2165 | Bakso Meatball Cart Indonesia (per serving) | Various | ID | street_food | H | TODO | 2026-04-07 | | |
| 2166 | Gorengan Fried Snacks Cart (per piece) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 2167 | Martabak Manis Sweet Pancake (per slice) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 2168 | Nasi Goreng Street Cart (per plate) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 2169 | Satay Street Grill Ayam (per stick) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 2170 | Soto Ayam Street Cart (per bowl) | Various | ID | street_food | M | TODO | 2026-04-07 | | |
| 2171 | Turkish Simit Street Cart (per piece) | Various | TR | street_food | H | TODO | 2026-04-07 | | |
| 2172 | Turkish Kumpir Stuffed Potato (per piece) | Various | TR | street_food | M | TODO | 2026-04-07 | | |
| 2173 | Turkish Döner Street Wrap (per wrap) | Various | TR | street_food | H | TODO | 2026-04-07 | | |
| 2174 | Turkish Balık Ekmek Fish Sandwich (per piece) | Various | TR | street_food | M | TODO | 2026-04-07 | | Istanbul icon |
| 2175 | Turkish Midye Dolma Stuffed Mussels (per 5) | Various | TR | street_food | M | TODO | 2026-04-07 | | |
| 2176 | Turkish Kokoreç Offal Wrap (per piece) | Various | TR | street_food | M | TODO | 2026-04-07 | | |
| 2177 | Arepas Street Cart Reina Pepiada (per piece) | Various | VE | street_food | M | TODO | 2026-04-07 | | |
| 2178 | Choripán Argentine Sausage Sandwich (per piece) | Various | AR | street_food | M | TODO | 2026-04-07 | | |
| 2179 | Empanada Street Cart Beef Argentina (per piece) | Various | AR | street_food | M | TODO | 2026-04-07 | | |
| 2180 | Pastel Street Cart Carne Brazil (per piece) | Various | BR | street_food | M | TODO | 2026-04-07 | | |
| 2181 | Acarajé Street Stand Bahia (per piece) | Various | BR | street_food | M | TODO | 2026-04-07 | | |
| 2182 | Tapioca Street Cart Coco Brazil (per piece) | Various | BR | street_food | M | TODO | 2026-04-07 | | |
| 2183 | Espetinho Street Grill Chicken (per stick) | Various | BR | street_food | M | TODO | 2026-04-07 | | |
| 2184 | Poutine Street Stand Classic Canada (per serving) | Various | CA | street_food | H | TODO | 2026-04-07 | | |
| 2185 | BeaverTails Pastry Cinnamon Sugar (per piece) | BeaverTails | CA | street_food | M | TODO | 2026-04-07 | | Canadian icon |
| 2186 | Peameal Bacon Sandwich Toronto (per piece) | Various | CA | street_food | M | TODO | 2026-04-07 | | |
| 2187 | Belgian Frites Stand Double Fried (per cone) | Various | BE | street_food | H | TODO | 2026-04-07 | | |
| 2188 | Belgian Waffle Street Cart Brussels (per piece) | Various | BE | street_food | M | TODO | 2026-04-07 | | |
| 2189 | Egyptian Koshari Street Cart (per serving) | Various | EG | street_food | H | TODO | 2026-04-07 | | |
| 2190 | Egyptian Falafel Ta'ameya Cart (per 3 pieces) | Various | EG | street_food | M | TODO | 2026-04-07 | | |
| 2191 | Egyptian Ful Medames Cart (per serving) | Various | EG | street_food | M | TODO | 2026-04-07 | | |
| 2192 | Israeli Falafel Stand in Pita (per pita) | Various | IL | street_food | H | TODO | 2026-04-07 | | |
| 2193 | Israeli Sabich Stand Eggplant Pita (per pita) | Various | IL | street_food | M | TODO | 2026-04-07 | | |
| 2194 | Würstelstand Käsekrainer Vienna (per piece) | Various | AT | street_food | M | TODO | 2026-04-07 | | Cheese sausage |
| 2195 | Würstelstand Bosna Vienna (per piece) | Various | AT | street_food | M | TODO | 2026-04-07 | | |
| 2196 | Shawarma Stand Chicken UAE (per wrap) | Various | AE | street_food | H | TODO | 2026-04-07 | | |
| 2197 | Luqaimat Sweet Dumpling UAE (per 5 pieces) | Various | AE | street_food | M | TODO | 2026-04-07 | | |
| 2198 | Hong Kong Egg Waffle Gai Daan Jai (per piece) | Various | HK | street_food | M | TODO | 2026-04-07 | | |
| 2199 | Hong Kong Fish Ball Curry (per 6 pieces) | Various | HK | street_food | M | TODO | 2026-04-07 | | |
| 2200 | Lángos Hungarian Fried Bread Street (per piece) | Various | HU | street_food | M | TODO | 2026-04-07 | | |
| 2201 | Kürtőskalács Chimney Cake Hungary (per piece) | Various | HU | street_food | M | TODO | 2026-04-07 | | |
| 2202 | Danish Pølse Hot Dog Cart (per piece) | Various | DK | street_food | M | TODO | 2026-04-07 | | Rød pølse |
| 2204 | Colombian Arepa de Huevo (per piece) | Various | CO | street_food | M | TODO | 2026-04-07 | | |
| 2205 | Colombian Empanada Street (per piece) | Various | CO | street_food | M | TODO | 2026-04-07 | | |
| 2208 | Peruvian Anticucho Heart Skewer (per stick) | Various | PE | street_food | M | TODO | 2026-04-07 | | |
| 2209 | Nigerian Suya Beef Skewer Street (per stick) | Various | NG | street_food | M | TODO | 2026-04-07 | | |
| 2210 | Nigerian Akara Bean Fritter (per piece) | Various | NG | street_food | M | TODO | 2026-04-07 | | |
| 2212 | South African Boerewors Roll (per piece) | Various | ZA | street_food | M | TODO | 2026-04-07 | | |
| 2213 | Moroccan Snail Soup Babbouche (per bowl) | Various | MA | street_food | M | TODO | 2026-04-07 | | |
| 2214 | Moroccan Msemen Flatbread (per piece) | Various | MA | street_food | M | TODO | 2026-04-07 | | |
| 2215 | Senegalese Fataya Pastry (per piece) | Various | SN | street_food | M | TODO | 2026-04-07 | | |
| 2217 | Vietnamese Bun Cha Street Hanoi (per serving) | Various | VN | street_food | M | TODO | 2026-04-07 | | |
| 2218 | Vietnamese Banh Xeo Crispy Pancake Street (per piece) | Various | VN | street_food | M | TODO | 2026-04-07 | | |
| 2219 | Filipino Isaw Grilled Intestine (per stick) | Various | PH | street_food | M | TODO | 2026-04-07 | | |
| 2220 | Filipino Kwek Kwek Quail Egg Fritter (per 5) | Various | PH | street_food | M | TODO | 2026-04-07 | | |
| 2221 | Filipino Fishball Street Cart (per 5 pieces) | Various | PH | street_food | M | TODO | 2026-04-07 | | |
| 2222 | Malaysian Satay Kajang (per stick) | Various | MY | street_food | M | TODO | 2026-04-07 | | |
| 2223 | Malaysian Lok Lok Skewer (per stick) | Various | MY | street_food | M | TODO | 2026-04-07 | | |
| 2224 | Malaysian Apam Balik Peanut Pancake (per piece) | Various | MY | street_food | M | TODO | 2026-04-07 | | |
| 2225 | Singaporean Satay Street Chicken (per stick) | Various | SG | street_food | M | TODO | 2026-04-07 | | |
| 2227 | Bangladeshi Fuchka (per 6 pieces) | Various | BD | street_food | M | TODO | 2026-04-07 | | Like pani puri |
| 2228 | Bangladeshi Jhalmuri Puffed Rice Snack (per serving) | Various | BD | street_food | M | TODO | 2026-04-07 | | |
| 2229 | Sri Lankan Kottu Roti Street (per serving) | Various | LK | street_food | M | TODO | 2026-04-07 | | |
| 2230 | Sri Lankan Isso Wade Prawn Fritter (per piece) | Various | LK | street_food | M | TODO | 2026-04-07 | | |
| 2231 | Nepali Momo Buff Steamed (per 8 pieces) | Various | NP | street_food | M | TODO | 2026-04-07 | | |
| 2232 | Nepali Chatamari Rice Crepe (per piece) | Various | NP | street_food | M | TODO | 2026-04-07 | | |
| 2233 | Spanish Churros with Chocolate (per 3 churros) | Various | ES | street_food | M | TODO | 2026-04-07 | | |
| 2234 | Spanish Bocadillo de Calamares (per piece) | Various | ES | street_food | M | TODO | 2026-04-07 | | Madrid icon |
| 2235 | Czech Trdelník Chimney Cake (per piece) | Various | CZ | street_food | M | TODO | 2026-04-07 | | |
| 2236 | Czech Klobása Grilled Sausage (per piece) | Various | CZ | street_food | M | TODO | 2026-04-07 | | |
| 2237 | Polish Zapiekanka Open Baguette (per piece) | Various | PL | street_food | M | TODO | 2026-04-07 | | |
| 2238 | Polish Oscypek Grilled Cheese Street (per piece) | Various | PL | street_food | M | TODO | 2026-04-07 | | |
| 2240 | Russian Pirozhki Fried Pie (per piece) | Various | RU | street_food | M | TODO | 2026-04-07 | | |
| 2241 | Raclette Street Stand Switzerland (per serving) | Various | CH | street_food | M | TODO | 2026-04-07 | | |
| 2242 | Swedish Tunnbrödsrulle Hot Dog Wrap (per piece) | Various | SE | street_food | M | TODO | 2026-04-07 | | |
| 2243 | Finnish Lihapiirakka Meat Pie (per piece) | Various | FI | street_food | M | TODO | 2026-04-07 | | |
| 2244 | Australian Sausage Sizzle (per piece) | Various | AU | street_food | M | TODO | 2026-04-07 | | Bunnings icon |
| 2245 | Australian Halal Snack Pack HSP (per serving) | Various | AU | street_food | M | TODO | 2026-04-07 | | |
| 2246 | Australian Dim Sim Fried (per piece) | Various | AU | street_food | M | TODO | 2026-04-07 | | |
| 2247 | Afghan Bolani Stuffed Flatbread (per piece) | Various | AF | street_food | M | TODO | 2026-04-07 | | |
| 2248 | Afghan Mantu Dumplings (per 5 pieces) | Various | AF | street_food | M | TODO | 2026-04-07 | | |
| 2249 | Ethiopian Sambusa (per piece) | Various | ET | street_food | M | TODO | 2026-04-07 | | |
| 2250 | Tanzanian Zanzibar Pizza (per piece) | Various | TZ | street_food | M | TODO | 2026-04-07 | | |
| 2251 | Kenyan Mutura Blood Sausage (per piece) | Various | KE | street_food | M | TODO | 2026-04-07 | | |
| 2252 | Kenyan Nyama Choma Street Grill (per 100g) | Various | KE | street_food | M | TODO | 2026-04-07 | | |
| 2254 | Lebanese Arayes Grilled Pita (per piece) | Various | LB | street_food | M | TODO | 2026-04-07 | | |
| 2255 | Cambodian Num Pang Sandwich (per piece) | Various | KH | street_food | M | TODO | 2026-04-07 | | |
| 2256 | Myanmar Tea Leaf Salad Lahpet (per serving) | Various | MM | street_food | M | TODO | 2026-04-07 | | |
| 2257 | Laotian Khao Piak Sen Noodle Soup (per serving) | Various | LA | street_food | M | TODO | 2026-04-07 | | |
| 2258 | Georgian Khachapuri Adjarian (per piece) | Various | GE | street_food | H | TODO | 2026-04-07 | | Cheese bread with egg |
| 2259 | Georgian Khinkali Dumplings (per 5 pieces) | Various | GE | street_food | M | TODO | 2026-04-07 | | |
| 2260 | Irish Chip Van Curry Chips (per serving) | Various | IE | street_food | M | TODO | 2026-04-07 | | |
| 2261 | Trinidadian Doubles with Channa (per piece) | Various | TT | street_food | M | TODO | 2026-04-07 | | |
| 2262 | Salvadoran Pupusa Revuelta Street (per piece) | Various | SV | street_food | M | TODO | 2026-04-07 | | |
| 2264 | Haitian Griot Fried Pork (per serving) | Various | HT | street_food | M | TODO | 2026-04-07 | | |
| 2265 | Pakistani Bun Kebab Street (per piece) | Various | PK | street_food | M | TODO | 2026-04-07 | | |
| 2266 | Pakistani Gol Gappay Street Cart (per 6) | Various | PK | street_food | M | TODO | 2026-04-07 | | |
| 2267 | Pakistani Chana Chaat Street (per plate) | Various | PK | street_food | M | TODO | 2026-04-07 | | |
| 2269 | Uzbek Somsa Meat Pastry (per piece) | Various | UZ | street_food | M | TODO | 2026-04-07 | | |
| 2270 | Uzbek Plov Rice Pilaf Street (per serving) | Various | UZ | street_food | M | TODO | 2026-04-07 | | |

## Section 62: From FOOD_LOG_EDGE_CASES.md - Common User Inputs Missing (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2272 | Protein Shake Generic Whey with Milk (per serving) | Various | US | protein_drink | H | TODO | 2026-04-07 | | |
| 2273 | Rice and Dal Combo (per serving) | Various | IN | staple | H | TODO | 2026-04-07 | | Common Indian input |
| 2274 | Steak and Potatoes Dinner (per serving) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 2275 | Noodles and Egg Stir Fry (per serving) | Various | CN | noodle | M | TODO | 2026-04-07 | | |
| 2277 | Momo Steamed Chicken (per 5 pieces) | Various | NP | snack | H | TODO | 2026-04-07 | | |
| 2278 | Momos Fried (per 5 pieces) | Various | IN | snack | H | TODO | 2026-04-07 | | |
| 2280 | Protein Fluff Casein Ice (per serving) | Various | US | dessert | M | TODO | 2026-04-07 | | Fitness trend |
| 2281 | Rice Cake with Peanut Butter (per 2 cakes) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 2282 | Post Workout Shake Generic (per serving) | Various | US | protein_drink | M | TODO | 2026-04-07 | | 2 scoops + milk |
| 2283 | Tagine Lamb with Apricots Couscous (per serving) | Various | MA | protein | M | TODO | 2026-04-07 | | From edge cases |
| 2284 | Khachapuri Georgian Cheese Bread (per piece) | Various | GE | bread | H | TODO | 2026-04-07 | | From edge cases |
| 2285 | Mole Negro with Chicken (per serving) | Various | MX | protein | M | TODO | 2026-04-07 | | |
| 2286 | Pesarattu Green Gram Dosa (per piece) | Various | IN | breakfast | M | TODO | 2026-04-07 | | Andhra specialty |
| 2287 | Thepla Gujarati Flatbread (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |
| 2288 | Aam Ras Mango Pulp with Milk (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2289 | Chhachh Buttermilk Spiced (per glass) | Various | IN | beverage | M | TODO | 2026-04-07 | | Gujarat specialty |
| 2290 | Parotta Kerala Layered Bread (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |
| 2291 | Appam Kerala Rice Pancake (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |
| 2292 | Fish Curry Kerala Style (per serving) | Various | IN | protein | M | TODO | 2026-04-07 | | |
| 2294 | Chicken 65 (per serving) | Various | IN | protein | H | TODO | 2026-04-07 | | |
| 2295 | Mirchi ka Salan (per serving) | Various | IN | curry | M | TODO | 2026-04-07 | | Hyderabadi biryani side |
| 2298 | Poriyal Vegetable Stir Fry (per serving) | Various | IN | vegetable | M | TODO | 2026-04-07 | | |
| 2299 | Curd Rice Thayir Sadam (per serving) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 2300 | Appalam Papadum Fried (per piece) | Various | IN | snack | M | TODO | 2026-04-07 | | |
| 2301 | Caramel Frappuccino Grande Starbucks (per cup) | Starbucks | US | beverage | H | TODO | 2026-04-07 | | |
| 2302 | Chipotle Bowl Double Chicken Extra Guac (per bowl) | Chipotle | US | fast_food | H | TODO | 2026-04-07 | | Common user order |
| 2304 | Chick-fil-A Waffle Fries (per medium) | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | | |
| 2306 | CAVA Bowl Grilled Chicken | CAVA | US | fast_food | M | TODO | 2026-04-07 | | |
| 2307 | Popeyes 3 Piece Chicken Tender | Popeyes | US | fast_food | M | TODO | 2026-04-07 | | |
| 2309 | Jersey Mike's #13 Italian Sub (per regular) | Jersey Mike's | US | fast_food | M | TODO | 2026-04-07 | | |
| 2312 | Charcuterie Board (per serving estimate) | Various | US | snack | M | TODO | 2026-04-07 | | Cheese crackers meat fruit |
| 2313 | IPA Beer Craft (per pint) | Various | US | beverage | M | TODO | 2026-04-07 | | Higher cal than lager |
| 2314 | Red Wine Generic (per glass 150ml) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2316 | Whiskey Shot (per 44ml) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2317 | Margarita Classic (per glass) | Various | MX | beverage | M | TODO | 2026-04-07 | | |
| 2318 | Mimosa Champagne OJ (per glass) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2320 | Mango Lassi (per glass) | Various | IN | beverage | H | TODO | 2026-04-07 | | Very common input |
| 2322 | Boba Tea Taro Large with Tapioca (per cup) | Various | TW | beverage | H | TODO | 2026-04-07 | | |
| 2326 | Açaí Bowl with Granola Banana PB (per bowl) | Various | BR | breakfast | H | TODO | 2026-04-07 | | |
| 2332 | Turkey Avocado Sandwich Whole Wheat (per sandwich) | Various | US | fast_food | M | TODO | 2026-04-07 | | |
| 2335 | Sushi Spicy Tuna Roll (per 8 pieces) | Various | US | fast_food | M | TODO | 2026-04-07 | | |
| 2336 | Buffalo Wings Traditional (per 8 wings) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 2337 | Nachos with Cheese Jalapenos (per serving) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 2340 | Fish Tacos with Mango Salsa (per 2 tacos) | Various | MX | fast_food | M | TODO | 2026-04-07 | | |
| 2341 | BBQ Ribs Half Rack with Cornbread (per serving) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 2342 | Lobster Tail with Butter (per tail) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 2344 | Tonkotsu Ramen Chashu Ajitama (per bowl) | Various | JP | noodle | H | TODO | 2026-04-07 | | Common user input |
| 2345 | Shawarma with Toum Pickled Turnips (per wrap) | Various | LB | fast_food | M | TODO | 2026-04-07 | | |
| 2346 | Golgappa 2 Plates (per 2 plates ~12 pcs) | Various | IN | snack | M | TODO | 2026-04-07 | | Hindi name for pani puri |
| 2347 | Schnitzel with Kartoffelsalat (per serving) | Various | DE | protein | M | TODO | 2026-04-07 | | |
| 2349 | Indian Thali Full Meal (per thali) | Various | IN | fast_food | H | TODO | 2026-04-07 | | Dal paneer aloo rice roti raita |
| 2350 | Korean BBQ Bulgogi with Rice Banchan (per serving) | Various | KR | protein | M | TODO | 2026-04-07 | | |

---

## Section 63: Plain Staples & Homemade Basics (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2356 | Penne Pasta Cooked (per 100g) | Various | IT | staple | M | TODO | 2026-04-07 | | |
| 2364 | Chicken Thigh Grilled Boneless (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 2365 | Ground Beef 80/20 Cooked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 2366 | Ground Beef 90/10 Cooked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 2367 | Ground Turkey 93/7 Cooked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 2368 | Salmon Fillet Baked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 2372 | Steak Ribeye Cooked (per 100g) | Various | US | protein | H | TODO | 2026-04-07 | | |
| 2373 | Steak Sirloin Cooked (per 100g) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 2377 | Buttered Toast (per slice) | Various | US | bread | H | TODO | 2026-04-07 | | Very common input |
| 2385 | Roasted Asparagus (per 100g) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 2386 | Side Salad Mixed Greens (per serving) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 2390 | Pasta with Meat Sauce Bolognese (per serving) | Various | IT | pasta | H | TODO | 2026-04-07 | | |
| 2396 | Ham and Cheese Sandwich (per sandwich) | Various | US | fast_food | M | TODO | 2026-04-07 | | |
| 2397 | Chicken Soup Homemade (per serving) | Various | US | soup | M | TODO | 2026-04-07 | | |
| 2400 | Chicken and Rice Simple (per serving) | Various | US | protein | H | TODO | 2026-04-07 | | #1 meal prep combo |

## Section 64: Common Fruits & Vegetables (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2415 | Cherry Fresh (per 100g) | Various | US | fruit | M | TODO | 2026-04-07 | | |
| 2416 | Grapefruit Half (per half) | Various | US | fruit | M | TODO | 2026-04-07 | | |
| 2418 | Lemon Juice (per tbsp) | Various | US | fruit | L | TODO | 2026-04-07 | | |
| 2419 | Lime Juice (per tbsp) | Various | MX | fruit | L | TODO | 2026-04-07 | | |
| 2420 | Dates Medjool (per piece) | Various | SA | fruit | M | TODO | 2026-04-07 | | |
| 2427 | Garlic Clove Raw (per clove) | Various | US | vegetable | L | TODO | 2026-04-07 | | |
| 2436 | Corn Kernels Cooked (per 100g) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 2440 | Jalapeno Pepper (per pepper) | Various | MX | vegetable | L | TODO | 2026-04-07 | | |

## Section 65: Everyday Beverages & Coffee (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2444 | Espresso Single Shot | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2445 | Espresso Double Shot | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2448 | Latte Oat Milk 16oz | Various | US | beverage | H | TODO | 2026-04-07 | | |
| 2450 | Cappuccino 12oz | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2451 | Flat White 12oz | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2454 | Starbucks Pike Place Brewed Grande | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 2456 | Starbucks Vanilla Latte Grande | Starbucks | US | beverage | H | TODO | 2026-04-07 | | |
| 2458 | Starbucks Matcha Latte Grande | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 2462 | Starbucks Refresher Strawberry Acai Grande | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 2463 | Starbucks Dragon Drink Grande | Starbucks | US | beverage | M | TODO | 2026-04-07 | | |
| 2466 | Dunkin' Medium Hot Latte | Dunkin' | US | beverage | M | TODO | 2026-04-07 | | |
| 2467 | Dunkin' Charli Cold Foam | Dunkin' | US | beverage | M | TODO | 2026-04-07 | | |
| 2469 | Coca-Cola Zero (per 12oz can) | Coca-Cola | US | beverage | H | TODO | 2026-04-07 | | |
| 2475 | Ginger Ale Canada Dry (per 12oz can) | Canada Dry | US | beverage | M | TODO | 2026-04-07 | | |
| 2476 | Lemonade Homemade (per glass) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2478 | Iced Tea Sweet Southern (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2484 | Hot Chocolate with Marshmallows (per cup) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2486 | 2% Reduced Fat Milk (per 8oz) | Various | US | dairy | H | TODO | 2026-04-07 | | |
| 2489 | Oat Milk Original (per 8oz) | Various | US | dairy_alt | H | TODO | 2026-04-07 | | |
| 2490 | Soy Milk Original (per 8oz) | Various | US | dairy_alt | M | TODO | 2026-04-07 | | |

## Section 66: Dairy, Condiments & Cooking Basics (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2507 | Hellmann's Real Mayo (per tbsp) | Hellmann's | US | condiment | H | TODO | 2026-04-07 | | |
| 2518 | A1 Steak Sauce (per tbsp) | A1 | US | condiment | M | TODO | 2026-04-07 | | |
| 2524 | Butter for Cooking (per tbsp) | Various | US | cooking | H | TODO | 2026-04-07 | | |
| 2526 | All-Purpose Flour (per 100g) | Various | US | baking | M | TODO | 2026-04-07 | | |
| 2530 | Cocoa Powder Unsweetened (per tbsp) | Various | US | baking | M | TODO | 2026-04-07 | | |
| 2532 | Vanilla Extract (per tsp) | Various | US | baking | L | TODO | 2026-04-07 | | |
| 2533 | Peanut Butter Generic Creamy (per tbsp) | Various | US | spread | H | TODO | 2026-04-07 | | |
| 2535 | Jelly Grape Generic (per tbsp) | Various | US | spread | M | TODO | 2026-04-07 | | |
| 2536 | Jam Strawberry Generic (per tbsp) | Various | US | spread | M | TODO | 2026-04-07 | | |
| 2537 | Hummus Classic (per tbsp) | Various | US | dip | H | TODO | 2026-04-07 | | |
| 2538 | Salsa Tomato (per tbsp) | Various | MX | condiment | M | TODO | 2026-04-07 | | |
| 2539 | Guacamole Fresh (per tbsp) | Various | MX | dip | H | TODO | 2026-04-07 | | |
| 2540 | Queso Dip (per tbsp) | Various | US | dip | M | TODO | 2026-04-07 | | |

## Section 67: Canned Goods & Pantry Staples (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2541 | Canned Tuna in Water (per can drained) | StarKist | US | protein | H | TODO | 2026-04-07 | | |
| 2550 | Canned Peas (per serving) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 2556 | Canned Peaches in Syrup (per serving) | Del Monte | US | fruit | M | TODO | 2026-04-07 | | |
| 2557 | Canned Pineapple Chunks in Juice (per serving) | Dole | US | fruit | M | TODO | 2026-04-07 | | |
| 2562 | Cashews Roasted Salted (per 30g) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 2563 | Walnuts Halves (per 30g) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 2564 | Mixed Nuts Planters (per 30g) | Planters | US | snack | M | TODO | 2026-04-07 | | |
| 2565 | Peanuts Roasted Salted (per 30g) | Various | US | snack | M | TODO | 2026-04-07 | | |

## Section 68: Frozen Meals, Convenience & Snack Foods (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2576 | Hot Pocket Ham & Cheese (per pocket) | Hot Pockets | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 2578 | Hungry-Man Salisbury Steak | Hungry-Man | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 2583 | Jimmy Dean Sausage Egg Cheese Croissant (per piece) | Jimmy Dean | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 2584 | Bagel Bites Cheese & Pepperoni (per 9 pieces) | Bagel Bites | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 2585 | Tater Tots Ore-Ida (per serving) | Ore-Ida | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 2589 | Fish Sticks Gorton's (per 6 sticks) | Gorton's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 2590 | Corn Dog Frozen (per piece) | Various | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 2592 | Mozzarella Sticks Frozen (per 3 sticks) | Various | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 2593 | Pop-Tarts Frosted Strawberry (per pastry) | Pop-Tarts | US | breakfast | M | TODO | 2026-04-07 | | |
| 2596 | Little Debbie Oatmeal Creme Pie (per piece) | Little Debbie | US | snack | M | TODO | 2026-04-07 | | |
| 2597 | Little Debbie Cosmic Brownie (per piece) | Little Debbie | US | snack | M | TODO | 2026-04-07 | | |
| 2598 | Hostess Cupcakes Chocolate (per piece) | Hostess | US | snack | M | TODO | 2026-04-07 | | |
| 2599 | Hostess Donettes Mini Powdered (per 3 pieces) | Hostess | US | snack | M | TODO | 2026-04-07 | | |
| 2600 | Little Debbie Swiss Roll (per piece) | Little Debbie | US | snack | M | TODO | 2026-04-07 | | |
| 2602 | Fig Newtons (per 2 cookies) | Nabisco | US | snack | M | TODO | 2026-04-07 | | |
| 2603 | Nutri-Grain Bar Strawberry | Kellogg's | US | snack | M | TODO | 2026-04-07 | | |
| 2604 | Uncrustables PB&J Grape (per piece) | Smucker's | US | snack | M | TODO | 2026-04-07 | | Kids staple |
| 2605 | Lunchables Turkey & Cheddar | Oscar Mayer | US | snack | M | TODO | 2026-04-07 | | |
| 2607 | Baby Carrots (per serving ~85g) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 2608 | Celery with Peanut Butter (per serving) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 2609 | Apple Slices with Caramel Dip (per serving) | Various | US | snack | M | TODO | 2026-04-07 | | |
| 2611 | Pudding Cup Jell-O Chocolate (per cup) | Jell-O | US | dessert | M | TODO | 2026-04-07 | | |
| 2612 | Jell-O Gelatin Strawberry (per cup) | Jell-O | US | dessert | M | TODO | 2026-04-07 | | |
| 2613 | Ramen Cup Noodle Chicken US (per cup) | Nissin | US | instant_noodle | H | TODO | 2026-04-07 | | College staple |
| 2615 | Velveeta Shells & Cheese (per serving) | Velveeta | US | pasta | M | TODO | 2026-04-07 | | |
| 2616 | Chef Boyardee Beef Ravioli (per serving) | Chef Boyardee | US | pasta | M | TODO | 2026-04-07 | | |
| 2617 | SpaghettiOs Original (per serving) | SpaghettiOs | US | pasta | M | TODO | 2026-04-07 | | |
| 2618 | Cup-a-Soup Chicken Noodle (per packet) | Lipton | US | soup | M | TODO | 2026-04-07 | | |

## Section 69: Holiday, Seasonal & Occasion Foods (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2622 | Stuffing Bread Thanksgiving (per serving) | Various | US | staple | M | TODO | 2026-04-07 | | |
| 2623 | Cranberry Sauce Canned (per serving) | Ocean Spray | US | condiment | M | TODO | 2026-04-07 | | |
| 2624 | Green Bean Casserole (per serving) | Various | US | vegetable | M | TODO | 2026-04-07 | | |
| 2628 | Eggnog (per 8oz cup) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2629 | Hot Apple Cider (per cup) | Various | US | beverage | M | TODO | 2026-04-07 | | |
| 2630 | Christmas Ham Glazed (per 100g) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 2631 | Gingerbread Cookie (per cookie) | Various | US | dessert | M | TODO | 2026-04-07 | | |
| 2633 | Candy Cane (per piece) | Various | US | confectionery | L | TODO | 2026-04-07 | | |
| 2634 | Easter Chocolate Egg Cadbury (per egg) | Cadbury | US | confectionery | M | TODO | 2026-04-07 | | |
| 2635 | Peeps Marshmallow (per 5 chicks) | Peeps | US | confectionery | L | TODO | 2026-04-07 | | |
| 2636 | Halloween Fun Size Snickers (per piece) | Mars | US | confectionery | M | TODO | 2026-04-07 | | |
| 2637 | Halloween Fun Size M&Ms (per pack) | Mars | US | confectionery | M | TODO | 2026-04-07 | | |
| 2638 | Super Bowl Wings Buffalo (per 6 wings) | Various | US | protein | M | TODO | 2026-04-07 | | |
| 2640 | Game Day 7-Layer Dip (per serving) | Various | US | dip | M | TODO | 2026-04-07 | | |
| 2641 | Birthday Cake Slice Vanilla Frosted (per slice) | Various | US | dessert | H | TODO | 2026-04-07 | | |
| 2642 | Birthday Cake Slice Chocolate (per slice) | Various | US | dessert | M | TODO | 2026-04-07 | | |
| 2643 | Cupcake Frosted Vanilla (per cupcake) | Various | US | dessert | M | TODO | 2026-04-07 | | |
| 2644 | Brownie Homemade (per piece) | Various | US | dessert | H | TODO | 2026-04-07 | | |
| 2646 | Cheesecake New York Style (per slice) | Various | US | dessert | M | TODO | 2026-04-07 | | |
| 2647 | Banana Bread (per slice) | Various | US | dessert | M | TODO | 2026-04-07 | | |
| 2649 | Ice Cream Sundae Hot Fudge (per serving) | Various | US | dessert | M | TODO | 2026-04-07 | | |
| 2650 | Milkshake Chocolate (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | | |

---
# Batch 1: Cuisine-Specific Food Nutrition Overrides

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|

## Section 70: Chinese Regional Cuisine (150 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2655 | Hot and Sour Soup | Generic | CN | Soup | H | TODO | 2026-04-07 | | |
| 2656 | Dan Dan Noodles | Generic | CN | Noodles | H | TODO | 2026-04-07 | | Sichuan spicy sesame noodles |
| 2662 | Mongolian Beef | Generic | CN | Entree | H | TODO | 2026-04-07 | | Sliced beef with scallions and soy |
| 2664 | Sesame Chicken | Generic | CN | Entree | H | TODO | 2026-04-07 | | |
| 2666 | Sweet and Sour Pork | Generic | CN | Entree | H | TODO | 2026-04-07 | | Cantonese gu lao rou |
| 2673 | Pork Dumplings (steamed, 6 pcs) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | Jiaozi |
| 2674 | Pork Dumplings (pan-fried, 6 pcs) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | Guotie / potstickers |
| 2675 | Shrimp Dumplings (steamed, 4 pcs) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | Har gow |
| 2676 | Soup Dumplings (6 pcs) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | Xiao long bao |
| 2677 | Siu Mai (4 pcs) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | Pork and shrimp open-top dumpling |
| 2678 | Char Siu Bao (steamed, 1 pc) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | BBQ pork bun |
| 2679 | Char Siu Bao (baked, 1 pc) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | |
| 2680 | Custard Bao (1 pc) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Liu sha bao |
| 2681 | Vegetable Bao (1 pc) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | |
| 2686 | Turnip Cake (pan-fried, 2 pcs) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Lo bak go |
| 2687 | Cheung Fun (shrimp) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Rice noodle rolls |
| 2688 | Cheung Fun (char siu) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | |
| 2689 | Chicken Feet (dim sum style) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Phoenix claws |
| 2690 | Spare Ribs (black bean sauce, dim sum) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Pai gwat |
| 2691 | Egg Tart (1 pc) | Generic | CN | Dim Sum | H | TODO | 2026-04-07 | | Dan tat |
| 2692 | Sesame Ball (1 pc) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Jian dui |
| 2693 | Spring Roll (fried, 1 pc) | Generic | CN | Appetizer | H | TODO | 2026-04-07 | | |
| 2695 | Crab Rangoon (4 pcs) | Generic | CN | Appetizer | H | TODO | 2026-04-07 | | Cream cheese wonton |
| 2696 | Scallion Pancake | Generic | CN | Appetizer | H | TODO | 2026-04-07 | | Cong you bing |
| 2697 | Char Siu (BBQ pork, per 100g) | Generic | CN | Protein | H | TODO | 2026-04-07 | | Cantonese roast pork |
| 2698 | Siu Yuk (crispy roast pork belly, per 100g) | Generic | CN | Protein | M | TODO | 2026-04-07 | | |
| 2699 | Roast Duck (Cantonese, per 100g) | Generic | CN | Protein | M | TODO | 2026-04-07 | | |
| 2700 | White Cut Chicken (per 100g) | Generic | CN | Protein | M | TODO | 2026-04-07 | | Bai qie ji |
| 2702 | Beef Chow Fun | Generic | CN | Noodles | H | TODO | 2026-04-07 | | Dry-fried flat rice noodles |
| 2704 | Zha Jiang Mian | Generic | CN | Noodles | M | TODO | 2026-04-07 | | Beijing-style soybean paste noodles |
| 2705 | Beef Noodle Soup (Taiwanese) | Generic | TW | Noodles | H | TODO | 2026-04-07 | | Niu rou mian |
| 2706 | Wonton Noodle Soup (Cantonese) | Generic | CN | Noodles | H | TODO | 2026-04-07 | | |
| 2707 | Lanzhou Beef Noodle Soup | Generic | CN | Noodles | M | TODO | 2026-04-07 | | Hand-pulled noodles |
| 2708 | Biang Biang Noodles | Generic | CN | Noodles | M | TODO | 2026-04-07 | | Shaanxi wide belt noodles |
| 2709 | Cold Sesame Noodles | Generic | CN | Noodles | M | TODO | 2026-04-07 | | Liang mian |
| 2710 | Sichuan Boiled Fish (shui zhu yu) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Fish in chili oil broth |
| 2711 | Sichuan Boiled Beef (shui zhu niu rou) | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 2712 | Twice Cooked Pork (hui guo rou) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Sichuan stir-fried pork belly |
| 2713 | Moo Shu Pork | Generic | CN | Entree | M | TODO | 2026-04-07 | | With pancakes |
| 2715 | Lemon Chicken | Generic | CN | Entree | M | TODO | 2026-04-07 | | Cantonese style |
| 2716 | Walnut Shrimp | Generic | CN | Entree | M | TODO | 2026-04-07 | | With candied walnuts and mayo |
| 2717 | Salt and Pepper Shrimp | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 2718 | Salt and Pepper Squid | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 2719 | Hunan Chicken | Generic | CN | Entree | M | TODO | 2026-04-07 | | Spicy Hunan-style |
| 2720 | Black Pepper Beef | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 2721 | Ma La Xiang Guo (dry spicy pot) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Sichuan numbing spicy stir-fry |
| 2722 | Hot Pot Broth (spicy, per serving) | Generic | CN | Soup | H | TODO | 2026-04-07 | | Sichuan ma la tang base |
| 2723 | Hot Pot Broth (plain bone, per serving) | Generic | CN | Soup | M | TODO | 2026-04-07 | | |
| 2724 | Hot Pot Sliced Beef (per 100g) | Generic | CN | Protein | M | TODO | 2026-04-07 | | |
| 2725 | Hot Pot Sliced Lamb (per 100g) | Generic | CN | Protein | M | TODO | 2026-04-07 | | |
| 2726 | Clay Pot Rice (Chinese sausage) | Generic | CN | Rice | M | TODO | 2026-04-07 | | Bo zai fan |
| 2727 | Clay Pot Rice (chicken and mushroom) | Generic | CN | Rice | M | TODO | 2026-04-07 | | |
| 2728 | Steamed Fish (whole, Cantonese-style) | Generic | CN | Entree | M | TODO | 2026-04-07 | | With ginger and scallion |
| 2729 | Stir-Fried Chinese Broccoli (gai lan) | Generic | CN | Vegetable | M | TODO | 2026-04-07 | | With oyster sauce |
| 2731 | Stir-Fried Water Spinach (kong xin cai) | Generic | CN | Vegetable | M | TODO | 2026-04-07 | | |
| 2732 | Chinese Eggplant with Garlic Sauce | Generic | CN | Vegetable | M | TODO | 2026-04-07 | | Yu xiang qie zi |
| 2734 | Ma Po Eggplant | Generic | CN | Vegetable | M | TODO | 2026-04-07 | | |
| 2736 | Corn Soup (Chinese-style) | Generic | CN | Soup | M | TODO | 2026-04-07 | | |
| 2737 | Winter Melon Soup | Generic | CN | Soup | L | TODO | 2026-04-07 | | Dong gua tang |
| 2738 | Tea Egg (1 pc) | Generic | CN | Snack | M | TODO | 2026-04-07 | | Cha ye dan |
| 2740 | Jian Bing (Chinese crepe) | Generic | CN | Breakfast | M | TODO | 2026-04-07 | | Street food breakfast |
| 2742 | Mango Pudding | Generic | CN | Dessert | M | TODO | 2026-04-07 | | Cantonese dim sum dessert |
| 2743 | Red Bean Soup | Generic | CN | Dessert | M | TODO | 2026-04-07 | | Hong dou tang |
| 2746 | Pineapple Bun (bo lo bao, 1 pc) | Generic | CN | Bakery | M | TODO | 2026-04-07 | | HK-style |
| 2747 | Coconut Bun (1 pc) | Generic | CN | Bakery | L | TODO | 2026-04-07 | | |
| 2748 | Wife Cake (1 pc) | Generic | CN | Bakery | L | TODO | 2026-04-07 | | Lo po beng |
| 2753 | Taiwanese Popcorn Chicken (ji pai) | Generic | TW | Snack | M | TODO | 2026-04-07 | | Street food |
| 2754 | Taiwanese Fried Chicken Cutlet | Generic | TW | Snack | M | TODO | 2026-04-07 | | Da ji pai |
| 2755 | Stinky Tofu (fried) | Generic | TW | Snack | L | TODO | 2026-04-07 | | Chou doufu |
| 2756 | Braised Pork Rice (lu rou fan) | Generic | TW | Rice | H | TODO | 2026-04-07 | | Taiwanese comfort food |
| 2757 | Three Cup Chicken (san bei ji) | Generic | TW | Entree | M | TODO | 2026-04-07 | | Basil, soy, sesame oil, rice wine |
| 2758 | Oyster Omelette | Generic | TW | Entree | M | TODO | 2026-04-07 | | O ah jian |
| 2759 | Gua Bao (Taiwanese pork belly bun) | Generic | TW | Snack | M | TODO | 2026-04-07 | | |
| 2760 | Pepper Salt Chicken (yan su ji) | Generic | TW | Snack | M | TODO | 2026-04-07 | | |
| 2761 | Dou Jiang (sweet soy milk, 1 cup) | Generic | CN | Beverage | M | TODO | 2026-04-07 | | Breakfast staple |
| 2762 | Suan La Fen (hot and sour glass noodles) | Generic | CN | Noodles | M | TODO | 2026-04-07 | | Chongqing style |
| 2763 | Liangpi (cold skin noodles) | Generic | CN | Noodles | L | TODO | 2026-04-07 | | Shaanxi street food |
| 2764 | Rou Jia Mo (Chinese hamburger) | Generic | CN | Sandwich | M | TODO | 2026-04-07 | | Shaanxi cumin lamb burger |
| 2765 | Hainanese Chicken Rice | Generic | CN | Rice | H | TODO | 2026-04-07 | | Poached chicken with oily rice |
| 2766 | Kung Pao Shrimp | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 2767 | Cumin Lamb (zi ran yang rou) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Xinjiang-style |
| 2768 | Lamb Skewers (yang rou chuan, 3 pcs) | Generic | CN | Appetizer | M | TODO | 2026-04-07 | | Xinjiang street food |
| 2769 | Ma La Tang (spicy soup, per bowl) | Generic | CN | Soup | M | TODO | 2026-04-07 | | Build-your-own hot pot soup |
| 2770 | Tomato Egg Stir-Fry | Generic | CN | Entree | H | TODO | 2026-04-07 | | Fan qie chao dan, everyday home cooking |
| 2771 | Steamed Egg Custard (zheng dan) | Generic | CN | Side | M | TODO | 2026-04-07 | | |
| 2772 | Crispy Five Spice Tofu | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 2773 | Chicken with Black Bean Sauce | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 2774 | Shrimp with Lobster Sauce | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 2775 | Beef with Mixed Vegetables | Generic | CN | Entree | M | TODO | 2026-04-07 | | |
| 2777 | Lion's Head Meatballs (shi zi tou) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Jiangsu dish |
| 2778 | Beggar's Chicken | Generic | CN | Entree | L | TODO | 2026-04-07 | | Hangzhou clay-wrapped chicken |
| 2779 | West Lake Fish (xi hu cu yu) | Generic | CN | Entree | L | TODO | 2026-04-07 | | Zhejiang sweet vinegar fish |
| 2780 | Dongpo Pork | Generic | CN | Entree | L | TODO | 2026-04-07 | | Hangzhou braised pork belly |
| 2781 | Chairman Mao's Red Braised Pork | Generic | CN | Entree | M | TODO | 2026-04-07 | | Hunan variation |
| 2782 | Smoked Duck (zhang cha ya) | Generic | CN | Entree | L | TODO | 2026-04-07 | | Sichuan tea-smoked duck |
| 2783 | Chili Oil Wontons (hong you chao shou) | Generic | CN | Appetizer | M | TODO | 2026-04-07 | | Sichuan style |
| 2785 | Hakka Salt Baked Chicken | Generic | CN | Entree | L | TODO | 2026-04-07 | | Yan ju ji |
| 2786 | Century Egg with Tofu | Generic | CN | Appetizer | L | TODO | 2026-04-07 | | Pi dan doufu |
| 2787 | Smashed Cucumber Salad | Generic | CN | Side | M | TODO | 2026-04-07 | | Pai huang gua |
| 2788 | Wood Ear Mushroom Salad | Generic | CN | Side | L | TODO | 2026-04-07 | | Liang ban mu er |
| 2789 | Drunken Chicken | Generic | CN | Appetizer | L | TODO | 2026-04-07 | | Zui ji, Shaoxing wine poached |
| 2790 | Zongzi (sticky rice dumpling, 1 pc) | Generic | CN | Snack | M | TODO | 2026-04-07 | | Wrapped in bamboo leaf |
| 2791 | Glutinous Rice with Chicken (lo mai gai) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Wrapped in lotus leaf |
| 2792 | Taro Puff (wu gok, 1 pc) | Generic | CN | Dim Sum | L | TODO | 2026-04-07 | | Crispy fried taro dumpling |
| 2793 | Stuffed Tofu Skin Roll (fu pei guen) | Generic | CN | Dim Sum | L | TODO | 2026-04-07 | | |
| 2794 | Steamed Chicken Feet with Black Bean | Generic | CN | Dim Sum | L | TODO | 2026-04-07 | | Dim sum classic |
| 2795 | Pan-Fried Chive Dumplings (4 pcs) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Jiu cai he zi |
| 2796 | Sheng Jian Bao (4 pcs) | Generic | CN | Dim Sum | M | TODO | 2026-04-07 | | Shanghai pan-fried soup buns |
| 2797 | Doubanjiang Chicken | Generic | CN | Entree | M | TODO | 2026-04-07 | | Spicy bean paste chicken |
| 2798 | Yu Xiang Rou Si (fish-fragrant pork) | Generic | CN | Entree | M | TODO | 2026-04-07 | | Sichuan classic |
| 2799 | Stir-Fried Lotus Root | Generic | CN | Vegetable | L | TODO | 2026-04-07 | | |
| 2800 | Ants Climbing a Tree (ma yi shang shu) | Generic | CN | Noodles | L | TODO | 2026-04-07 | | Sichuan glass noodles with pork |

## Section 71: Japanese Cuisine Beyond Basics (120 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2801 | Salmon Nigiri (2 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | |
| 2802 | Tuna Nigiri (2 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | Maguro |
| 2803 | Yellowtail Nigiri (2 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Hamachi |
| 2804 | Shrimp Nigiri (2 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Ebi |
| 2805 | Eel Nigiri (2 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Unagi |
| 2806 | Octopus Nigiri (2 pcs) | Generic | JP | Sushi | L | TODO | 2026-04-07 | | Tako |
| 2807 | Fatty Tuna Nigiri (2 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Toro |
| 2808 | Salmon Sashimi (5 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | |
| 2809 | Tuna Sashimi (5 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | |
| 2810 | California Roll (8 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | |
| 2811 | Spicy Tuna Roll (8 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | |
| 2812 | Dragon Roll (8 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | Eel and avocado |
| 2813 | Rainbow Roll (8 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | |
| 2814 | Philadelphia Roll (8 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Salmon and cream cheese |
| 2815 | Spider Roll (8 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Soft shell crab |
| 2816 | Volcano Roll (8 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | |
| 2817 | Cucumber Roll (6 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | Kappa maki |
| 2818 | Avocado Roll (6 pcs) | Generic | JP | Sushi | M | TODO | 2026-04-07 | | |
| 2819 | Salmon Avocado Roll (8 pcs) | Generic | JP | Sushi | H | TODO | 2026-04-07 | | |
| 2820 | Shoyu Ramen | Generic | JP | Noodles | H | TODO | 2026-04-07 | | Soy sauce broth |
| 2821 | Miso Ramen | Generic | JP | Noodles | H | TODO | 2026-04-07 | | Sapporo-style |
| 2822 | Shio Ramen | Generic | JP | Noodles | M | TODO | 2026-04-07 | | Salt-based broth |
| 2823 | Tonkotsu Ramen | Generic | JP | Noodles | H | TODO | 2026-04-07 | | Pork bone broth, Hakata-style |
| 2824 | Tsukemen (dipping ramen) | Generic | JP | Noodles | M | TODO | 2026-04-07 | | Cold noodles with hot broth |
| 2825 | Tantanmen (Japanese dan dan noodles) | Generic | JP | Noodles | M | TODO | 2026-04-07 | | Spicy sesame ramen |
| 2826 | Kitsune Udon | Generic | JP | Noodles | H | TODO | 2026-04-07 | | With sweet fried tofu |
| 2827 | Tempura Udon | Generic | JP | Noodles | H | TODO | 2026-04-07 | | |
| 2828 | Nabeyaki Udon | Generic | JP | Noodles | M | TODO | 2026-04-07 | | Hot pot udon |
| 2829 | Zaru Soba (cold buckwheat noodles) | Generic | JP | Noodles | M | TODO | 2026-04-07 | | With dipping sauce |
| 2830 | Tempura Soba | Generic | JP | Noodles | M | TODO | 2026-04-07 | | |
| 2832 | Shrimp Tempura (5 pcs) | Generic | JP | Appetizer | H | TODO | 2026-04-07 | | |
| 2833 | Vegetable Tempura (assorted, 6 pcs) | Generic | JP | Appetizer | M | TODO | 2026-04-07 | | |
| 2834 | Chicken Katsu | Generic | JP | Entree | H | TODO | 2026-04-07 | | Breaded fried chicken cutlet |
| 2836 | Katsu Curry | Generic | JP | Entree | H | TODO | 2026-04-07 | | Cutlet with Japanese curry |
| 2841 | Unadon (eel bowl) | Generic | JP | Rice Bowl | M | TODO | 2026-04-07 | | Grilled eel over rice |
| 2842 | Japanese Curry Rice | Generic | JP | Entree | H | TODO | 2026-04-07 | | With potato and carrot |
| 2843 | Chicken Karaage (6 pcs) | Generic | JP | Appetizer | H | TODO | 2026-04-07 | | Japanese fried chicken |
| 2845 | Okonomiyaki (Osaka-style) | Generic | JP | Entree | M | TODO | 2026-04-07 | | Savory pancake |
| 2846 | Yakitori Chicken Thigh (2 skewers) | Generic | JP | Appetizer | H | TODO | 2026-04-07 | | Momo |
| 2847 | Yakitori Tsukune (2 skewers) | Generic | JP | Appetizer | M | TODO | 2026-04-07 | | Chicken meatball |
| 2848 | Yakitori Negima (2 skewers) | Generic | JP | Appetizer | M | TODO | 2026-04-07 | | Chicken and scallion |
| 2851 | Agedashi Tofu | Generic | JP | Appetizer | M | TODO | 2026-04-07 | | Deep-fried tofu in dashi broth |
| 2853 | Chawanmushi (steamed egg custard) | Generic | JP | Side | M | TODO | 2026-04-07 | | |
| 2859 | Sunomono (cucumber salad) | Generic | JP | Side | M | TODO | 2026-04-07 | | Vinegar-dressed |
| 2860 | Hijiki Seaweed Salad | Generic | JP | Side | M | TODO | 2026-04-07 | | |
| 2861 | Kinpira Gobo (braised burdock root) | Generic | JP | Side | L | TODO | 2026-04-07 | | |
| 2862 | Nikujaga (meat and potato stew) | Generic | JP | Entree | M | TODO | 2026-04-07 | | Japanese comfort food |
| 2863 | Sukiyaki (per serving) | Generic | JP | Entree | M | TODO | 2026-04-07 | | Sweet soy hot pot |
| 2864 | Shabu Shabu (per serving) | Generic | JP | Entree | M | TODO | 2026-04-07 | | Swish-swish hot pot |
| 2865 | Teppanyaki Steak | Generic | JP | Entree | M | TODO | 2026-04-07 | | |
| 2866 | Teriyaki Salmon | Generic | JP | Entree | H | TODO | 2026-04-07 | | |
| 2868 | Grilled Saba (mackerel) | Generic | JP | Entree | M | TODO | 2026-04-07 | | |
| 2869 | Chirashi Bowl (assorted sashimi over rice) | Generic | JP | Rice Bowl | M | TODO | 2026-04-07 | | |
| 2870 | Matcha Latte (hot, 16 oz) | Generic | JP | Beverage | H | TODO | 2026-04-07 | | |
| 2871 | Matcha Ice Cream (1 scoop) | Generic | JP | Dessert | M | TODO | 2026-04-07 | | |
| 2872 | Mochi Ice Cream (1 pc) | Generic | JP | Dessert | H | TODO | 2026-04-07 | | |
| 2875 | Japanese Cheesecake (1 slice) | Generic | JP | Dessert | M | TODO | 2026-04-07 | | Fluffy souffle style |
| 2876 | Dango (3 pcs on skewer) | Generic | JP | Dessert | M | TODO | 2026-04-07 | | Rice flour dumplings |
| 2877 | Melon Pan (1 pc) | Generic | JP | Bakery | M | TODO | 2026-04-07 | | Sweet bread with cookie crust |
| 2879 | Japanese Milk Bread (shokupan, 1 slice) | Generic | JP | Bakery | M | TODO | 2026-04-07 | | |
| 2880 | Curry Pan (fried curry bread, 1 pc) | Generic | JP | Bakery | M | TODO | 2026-04-07 | | |
| 2882 | Menchi Katsu (ground meat cutlet, 1 pc) | Generic | JP | Snack | M | TODO | 2026-04-07 | | |
| 2883 | Omurice (omelette rice) | Generic | JP | Entree | M | TODO | 2026-04-07 | | Ketchup fried rice in egg |
| 2884 | Napolitan Spaghetti | Generic | JP | Noodles | M | TODO | 2026-04-07 | | Japanese-style ketchup pasta |
| 2885 | Hayashi Rice (hashed beef) | Generic | JP | Entree | M | TODO | 2026-04-07 | | Demi-glace over rice |
| 2886 | Tonkotsu Ramen (extra chashu) | Generic | JP | Noodles | M | TODO | 2026-04-07 | | |
| 2887 | Chashu Pork (per 2 slices) | Generic | JP | Topping | M | TODO | 2026-04-07 | | Braised pork belly for ramen |
| 2888 | Ajitama (marinated soft egg, 1 pc) | Generic | JP | Topping | M | TODO | 2026-04-07 | | Ramen egg |
| 2890 | Ochazuke (rice with green tea) | Generic | JP | Rice | L | TODO | 2026-04-07 | | |
| 2891 | Soba Salad | Generic | JP | Side | L | TODO | 2026-04-07 | | Cold buckwheat noodle salad |
| 2892 | Tonjiru (pork miso soup) | Generic | JP | Soup | M | TODO | 2026-04-07 | | Hearty miso soup with pork |
| 2893 | Yaki Onigiri (grilled rice ball, 1 pc) | Generic | JP | Snack | M | TODO | 2026-04-07 | | |
| 2894 | Kakiage (vegetable tempura fritter) | Generic | JP | Appetizer | M | TODO | 2026-04-07 | | |
| 2895 | Wagyu Beef Steak (per 100g) | Generic | JP | Entree | L | TODO | 2026-04-07 | | A5 grade |
| 2896 | Karaage Bento | Generic | JP | Bento | M | TODO | 2026-04-07 | | With rice and sides |
| 2897 | Salmon Bento | Generic | JP | Bento | M | TODO | 2026-04-07 | | With rice and sides |
| 2898 | Katsu Sando (pork cutlet sandwich) | Generic | JP | Sandwich | M | TODO | 2026-04-07 | | |
| 2899 | Tamago Sando (egg sandwich) | Generic | JP | Sandwich | M | TODO | 2026-04-07 | | Japanese konbini egg salad |
| 2900 | Fruit Sando (fruit sandwich) | Generic | JP | Sandwich | L | TODO | 2026-04-07 | | Whipped cream and fruit |
| 2901 | Ramune Soda (1 bottle) | Generic | JP | Beverage | L | TODO | 2026-04-07 | | |
| 2902 | Calpis/Calpico (1 cup) | Generic | JP | Beverage | L | TODO | 2026-04-07 | | |
| 2903 | Japanese Rice Crackers (senbei, 3 pcs) | Generic | JP | Snack | M | TODO | 2026-04-07 | | |
| 2905 | Miso Glazed Eggplant (nasu dengaku) | Generic | JP | Side | L | TODO | 2026-04-07 | | |
| 2906 | Yudofu (simmered tofu) | Generic | JP | Entree | L | TODO | 2026-04-07 | | Kyoto-style hot tofu |
| 2907 | Chicken Nanban | Generic | JP | Entree | M | TODO | 2026-04-07 | | Fried chicken with tartar sauce |
| 2908 | Kakuni (braised pork belly) | Generic | JP | Entree | M | TODO | 2026-04-07 | | Nagasaki-style |
| 2909 | Hiroshima-style Okonomiyaki | Generic | JP | Entree | M | TODO | 2026-04-07 | | Layered with noodles |
| 2910 | Monjayaki | Generic | JP | Entree | L | TODO | 2026-04-07 | | Tokyo-style runny pancake |
| 2911 | Oden (assorted per bowl) | Generic | JP | Entree | M | TODO | 2026-04-07 | | Fish cake stew |
| 2912 | Oyako Nanban | Generic | JP | Entree | L | TODO | 2026-04-07 | | |
| 2914 | Warabimochi | Generic | JP | Dessert | L | TODO | 2026-04-07 | | Bracken starch jelly with kinako |
| 2915 | Kakigori (shaved ice) | Generic | JP | Dessert | L | TODO | 2026-04-07 | | |
| 2916 | Castella Cake (1 slice) | Generic | JP | Dessert | L | TODO | 2026-04-07 | | Nagasaki sponge cake |
| 2917 | Japanese Hamburg Steak | Generic | JP | Entree | M | TODO | 2026-04-07 | | Hambagu with demi-glace |
| 2918 | Ebi Fry (fried shrimp, 3 pcs) | Generic | JP | Entree | M | TODO | 2026-04-07 | | |
| 2919 | Japanese Cream Stew | Generic | JP | Entree | M | TODO | 2026-04-07 | | White stew with chicken |

## Section 72: Korean Cuisine Full (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 2924 | Daeji Bulgogi (spicy pork) | Generic | KR | BBQ | H | TODO | 2026-04-07 | | |
| 2925 | Chadolbaegi (brisket slices, grilled) | Generic | KR | BBQ | M | TODO | 2026-04-07 | | |
| 2926 | Galbi-jjim (braised short ribs) | Generic | KR | Entree | M | TODO | 2026-04-07 | | |
| 2935 | Galbitang (short rib soup) | Generic | KR | Soup | M | TODO | 2026-04-07 | | |
| 2936 | Yukgaejang (spicy beef soup) | Generic | KR | Soup | M | TODO | 2026-04-07 | | |
| 2939 | Dolsot Bibimbap (stone pot) | Generic | KR | Rice | H | TODO | 2026-04-07 | | Hot stone bowl version |
| 2940 | Kimchi Bokkeumbap (kimchi fried rice) | Generic | KR | Rice | H | TODO | 2026-04-07 | | |
| 2943 | Bibim Naengmyeon (spicy cold noodles) | Generic | KR | Noodles | M | TODO | 2026-04-07 | | |
| 2944 | Kalguksu (knife-cut noodle soup) | Generic | KR | Noodles | M | TODO | 2026-04-07 | | |
| 2946 | Jjamppong (spicy seafood noodle soup) | Generic | KR | Noodles | H | TODO | 2026-04-07 | | Korean-Chinese |
| 2947 | Ramyeon (Korean instant ramen, cooked) | Generic | KR | Noodles | H | TODO | 2026-04-07 | | |
| 2953 | Rabokki (ramen + tteokbokki) | Generic | KR | Snack | M | TODO | 2026-04-07 | | |
| 2954 | Korean Corn Dog (1 pc) | Generic | KR | Snack | M | TODO | 2026-04-07 | | Cheese and potato coated |
| 2956 | Bungeoppang (fish-shaped pastry, 1 pc) | Generic | KR | Snack | M | TODO | 2026-04-07 | | Red bean filled |
| 2965 | Musaengchae (spicy radish salad) | Generic | KR | Banchan | M | TODO | 2026-04-07 | | |
| 2966 | Gyeran-jjim (steamed egg) | Generic | KR | Banchan | M | TODO | 2026-04-07 | | |
| 2967 | Gamja Jorim (braised potatoes) | Generic | KR | Banchan | M | TODO | 2026-04-07 | | Soy-glazed |
| 2968 | Myeolchi Bokkeum (stir-fried anchovies) | Generic | KR | Banchan | M | TODO | 2026-04-07 | | |
| 2969 | Eomuk Bokkeum (fish cake stir-fry) | Generic | KR | Banchan | M | TODO | 2026-04-07 | | |
| 2970 | Dubu Jorim (braised tofu) | Generic | KR | Banchan | M | TODO | 2026-04-07 | | |
| 2971 | Oi Sobagi (cucumber kimchi) | Generic | KR | Banchan | L | TODO | 2026-04-07 | | |
| 2972 | Hobak Bokkeum (stir-fried zucchini) | Generic | KR | Banchan | L | TODO | 2026-04-07 | | |
| 2973 | Doraji Namul (bellflower root) | Generic | KR | Banchan | L | TODO | 2026-04-07 | | |
| 2974 | Jeon - Pajeon (scallion pancake) | Generic | KR | Appetizer | H | TODO | 2026-04-07 | | |
| 2975 | Jeon - Haemul Pajeon (seafood pancake) | Generic | KR | Appetizer | M | TODO | 2026-04-07 | | |
| 2976 | Jeon - Kimchi Jeon (kimchi pancake) | Generic | KR | Appetizer | M | TODO | 2026-04-07 | | |
| 2977 | Hobak Juk (pumpkin porridge) | Generic | KR | Porridge | M | TODO | 2026-04-07 | | |
| 2978 | Jat Juk (pine nut porridge) | Generic | KR | Porridge | L | TODO | 2026-04-07 | | |
| 2979 | Dakjuk (chicken porridge) | Generic | KR | Porridge | M | TODO | 2026-04-07 | | |
| 2980 | Tangsuyuk (sweet and sour pork) | Generic | KR | Entree | M | TODO | 2026-04-07 | | Korean-Chinese |
| 2981 | Jeyuk Bokkeum (spicy pork stir-fry) | Generic | KR | Entree | M | TODO | 2026-04-07 | | |
| 2982 | Bossam (boiled pork belly wraps) | Generic | KR | Entree | M | TODO | 2026-04-07 | | |
| 2983 | Jokbal (braised pig's feet) | Generic | KR | Entree | M | TODO | 2026-04-07 | | |
| 2984 | Sundae (blood sausage) | Generic | KR | Snack | M | TODO | 2026-04-07 | | Korean street food |
| 2985 | Dakbal (spicy chicken feet) | Generic | KR | Snack | L | TODO | 2026-04-07 | | |
| 2986 | Cupbap (rice in a cup) | Generic | KR | Rice | M | TODO | 2026-04-07 | | |
| 2987 | Deopbap (topping rice, various) | Generic | KR | Rice | M | TODO | 2026-04-07 | | |
| 2988 | Ssambap (lettuce wrap rice) | Generic | KR | Rice | M | TODO | 2026-04-07 | | |
| 2990 | Cheese Tteokbokki | Generic | KR | Snack | M | TODO | 2026-04-07 | | With melted cheese |
| 2991 | Eomuk Tang (fish cake soup) | Generic | KR | Soup | M | TODO | 2026-04-07 | | Street food |
| 2992 | Bindaetteok (mung bean pancake) | Generic | KR | Appetizer | M | TODO | 2026-04-07 | | |
| 2993 | Gamjajeon (potato pancake) | Generic | KR | Appetizer | L | TODO | 2026-04-07 | | |
| 2994 | Gyeran Bap (egg rice) | Generic | KR | Rice | M | TODO | 2026-04-07 | | Simple comfort food |
| 2995 | Patbingsu (red bean shaved ice) | Generic | KR | Dessert | M | TODO | 2026-04-07 | | |
| 2996 | Bungeo-ppang Ice Cream | Generic | KR | Dessert | L | TODO | 2026-04-07 | | |
| 2997 | Soju (per shot) | Generic | KR | Alcohol | H | TODO | 2026-04-07 | | |
| 2998 | Makgeolli (rice wine, per cup) | Generic | KR | Alcohol | M | TODO | 2026-04-07 | | |
| 3000 | Banana Milk (Binggrae) | Binggrae | KR | Beverage | M | TODO | 2026-04-07 | | |
| 3001 | Soondae Gukbap (blood sausage soup) | Generic | KR | Soup | M | TODO | 2026-04-07 | | |
| 3002 | Dwaeji Gukbap (pork rice soup) | Generic | KR | Soup | M | TODO | 2026-04-07 | | Busan specialty |
| 3003 | Kongguksu (cold soy milk noodles) | Generic | KR | Noodles | L | TODO | 2026-04-07 | | Summer dish |
| 3004 | Gopchang (grilled intestines) | Generic | KR | BBQ | L | TODO | 2026-04-07 | | |
| 3006 | Odeng/Eomuk (fish cake on stick, 1 skewer) | Generic | KR | Snack | M | TODO | 2026-04-07 | | |
| 3007 | Tornado Potato (1 skewer) | Generic | KR | Snack | L | TODO | 2026-04-07 | | Street food |
| 3008 | Gyeran-ppang (egg bread, 1 pc) | Generic | KR | Snack | M | TODO | 2026-04-07 | | Street food |
| 3009 | Nurungji (scorched rice) | Generic | KR | Snack | L | TODO | 2026-04-07 | | Crispy rice from pot bottom |
| 3010 | Haemul Ttukbaegi (seafood hot pot) | Generic | KR | Stew | M | TODO | 2026-04-07 | | |
| 3011 | Ojingeo Bokkeum (spicy squid stir-fry) | Generic | KR | Entree | M | TODO | 2026-04-07 | | |
| 3012 | Nakji Bokkeum (spicy octopus stir-fry) | Generic | KR | Entree | M | TODO | 2026-04-07 | | |
| 3013 | Korean Cheese Corn | Generic | KR | Side | M | TODO | 2026-04-07 | | Sweet corn with mayo and cheese |
| 3014 | Korean Fish Cake Stir-Fry (eomuk bokkeum) | Generic | KR | Banchan | M | TODO | 2026-04-07 | | |
| 3015 | Dakdoritang (spicy chicken stew) | Generic | KR | Stew | M | TODO | 2026-04-07 | | With potatoes |
| 3016 | Ganjang Gejang (raw crab in soy) | Generic | KR | Entree | L | TODO | 2026-04-07 | | |
| 3017 | Yangnyeom Gejang (raw crab in spicy sauce) | Generic | KR | Entree | L | TODO | 2026-04-07 | | |
| 3018 | Bibim Guksu (spicy cold noodles) | Generic | KR | Noodles | M | TODO | 2026-04-07 | | Thin wheat noodles |
| 3019 | Soondubu with Rice Set | Generic | KR | Entree | H | TODO | 2026-04-07 | | Restaurant set meal |
| 3020 | Korean BBQ Combo (samgyeopsal set for 1) | Generic | KR | BBQ | H | TODO | 2026-04-07 | | With sides and rice |

## Section 73: Thai Cuisine Full (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3021 | Green Curry with Chicken | Generic | TH | Curry | H | TODO | 2026-04-07 | | Gaeng keow wan |
| 3022 | Green Curry with Shrimp | Generic | TH | Curry | M | TODO | 2026-04-07 | | |
| 3023 | Red Curry with Chicken | Generic | TH | Curry | H | TODO | 2026-04-07 | | Gaeng daeng |
| 3024 | Red Curry with Beef | Generic | TH | Curry | M | TODO | 2026-04-07 | | |
| 3025 | Yellow Curry with Chicken | Generic | TH | Curry | M | TODO | 2026-04-07 | | Gaeng luang |
| 3026 | Massaman Curry (beef) | Generic | TH | Curry | H | TODO | 2026-04-07 | | With peanuts and potatoes |
| 3027 | Panang Curry (chicken) | Generic | TH | Curry | H | TODO | 2026-04-07 | | |
| 3028 | Panang Curry (beef) | Generic | TH | Curry | M | TODO | 2026-04-07 | | |
| 3029 | Jungle Curry (gaeng pa) | Generic | TH | Curry | L | TODO | 2026-04-07 | | No coconut milk |
| 3033 | Pad See Ew (chicken) | Generic | TH | Noodles | H | TODO | 2026-04-07 | | Wide rice noodles with soy |
| 3034 | Pad See Ew (beef) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | |
| 3035 | Drunken Noodles (pad kee mao, chicken) | Generic | TH | Noodles | H | TODO | 2026-04-07 | | Spicy basil noodles |
| 3036 | Drunken Noodles (pad kee mao, beef) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | |
| 3037 | Boat Noodles (kuay teow reua) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | Rich dark broth |
| 3038 | Pad Woon Sen (glass noodle stir-fry) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | |
| 3039 | Khao Soi (Northern Thai curry noodle) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | Chiang Mai specialty |
| 3040 | Tom Yum Goong (spicy shrimp soup) | Generic | TH | Soup | H | TODO | 2026-04-07 | | |
| 3041 | Tom Yum Gai (chicken) | Generic | TH | Soup | M | TODO | 2026-04-07 | | |
| 3042 | Tom Kha Gai (coconut chicken soup) | Generic | TH | Soup | H | TODO | 2026-04-07 | | |
| 3043 | Tom Kha Goong (coconut shrimp soup) | Generic | TH | Soup | M | TODO | 2026-04-07 | | |
| 3045 | Som Tum (green papaya salad) | Generic | TH | Salad | H | TODO | 2026-04-07 | | |
| 3046 | Larb Gai (minced chicken salad) | Generic | TH | Salad | H | TODO | 2026-04-07 | | Isaan-style |
| 3047 | Larb Moo (minced pork salad) | Generic | TH | Salad | M | TODO | 2026-04-07 | | |
| 3048 | Yum Woon Sen (glass noodle salad) | Generic | TH | Salad | M | TODO | 2026-04-07 | | |
| 3049 | Yum Talay (seafood salad) | Generic | TH | Salad | M | TODO | 2026-04-07 | | |
| 3050 | Nam Tok (waterfall beef salad) | Generic | TH | Salad | M | TODO | 2026-04-07 | | |
| 3051 | Thai Basil Chicken (pad krapao gai) | Generic | TH | Entree | H | TODO | 2026-04-07 | | With fried egg on rice |
| 3052 | Thai Basil Pork (pad krapao moo) | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 3054 | Ginger Chicken (gai pad king) | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 3055 | Garlic Pepper Shrimp | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 3056 | Sweet Chili Fish (pla rad prik) | Generic | TH | Entree | M | TODO | 2026-04-07 | | Fried fish with chili sauce |
| 3057 | Crying Tiger (suea rong hai) | Generic | TH | Entree | M | TODO | 2026-04-07 | | Grilled beef with jaew sauce |
| 3058 | Khao Pad (Thai fried rice, chicken) | Generic | TH | Rice | H | TODO | 2026-04-07 | | |
| 3059 | Khao Pad (Thai fried rice, shrimp) | Generic | TH | Rice | M | TODO | 2026-04-07 | | |
| 3062 | Kao Man Gai (Thai chicken rice) | Generic | TH | Rice | M | TODO | 2026-04-07 | | |
| 3064 | Satay Chicken (4 skewers with peanut sauce) | Generic | TH | Appetizer | H | TODO | 2026-04-07 | | |
| 3065 | Satay Pork (4 skewers) | Generic | TH | Appetizer | M | TODO | 2026-04-07 | | |
| 3066 | Thai Fish Cakes (tod mun pla, 4 pcs) | Generic | TH | Appetizer | M | TODO | 2026-04-07 | | |
| 3068 | Fresh Spring Rolls (poh pia sod, 2 pcs) | Generic | TH | Appetizer | M | TODO | 2026-04-07 | | |
| 3069 | Moo Ping (grilled pork skewers, 3 pcs) | Generic | TH | Street Food | H | TODO | 2026-04-07 | | |
| 3070 | Kai Yang (grilled chicken) | Generic | TH | Entree | M | TODO | 2026-04-07 | | Isaan-style |
| 3073 | Roti with Banana and Condensed Milk | Generic | TH | Dessert | M | TODO | 2026-04-07 | | Street food |
| 3074 | Thai Custard (sangkaya) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 3075 | Khanom Buang (Thai crispy crepe) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 3076 | Tab Tim Grob (water chestnut in coconut) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 3078 | Thai Iced Coffee | Generic | TH | Beverage | M | TODO | 2026-04-07 | | Oliang |
| 3080 | Pad Prik King (stir-fry with curry paste) | Generic | TH | Entree | M | TODO | 2026-04-07 | | With green beans |
| 3081 | Pla Pao (salt-crusted grilled fish) | Generic | TH | Entree | L | TODO | 2026-04-07 | | |
| 3082 | Gaeng Som (sour curry) | Generic | TH | Curry | L | TODO | 2026-04-07 | | Southern Thai |
| 3083 | Isaan Sausage (sai krok Isaan, 2 pcs) | Generic | TH | Street Food | L | TODO | 2026-04-07 | | Fermented pork sausage |
| 3084 | Pad Pak Ruam (mixed vegetable stir-fry) | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 3085 | Khao Kluk Kapi (shrimp paste fried rice) | Generic | TH | Rice | L | TODO | 2026-04-07 | | |
| 3086 | Panaeng Salmon | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 3087 | Thai Omelette (kai jeow) | Generic | TH | Entree | M | TODO | 2026-04-07 | | Crispy deep-fried omelette |
| 3088 | Steamed Sea Bass with Lime (pla neung manao) | Generic | TH | Entree | M | TODO | 2026-04-07 | | |
| 3089 | Rad Na (gravy noodles) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | Wide noodles in thick gravy |
| 3090 | Kuay Jab (rolled noodle soup) | Generic | TH | Noodles | L | TODO | 2026-04-07 | | With pork offal |
| 3091 | Bua Loy (glutinous rice balls in coconut) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 3092 | Luk Chup (mung bean sweets, 3 pcs) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 3093 | Kao Niew Tua Dam (black bean sticky rice) | Generic | TH | Dessert | L | TODO | 2026-04-07 | | |
| 3094 | Gaeng Hung Lay (Northern Thai pork curry) | Generic | TH | Curry | L | TODO | 2026-04-07 | | Burmese-influenced |
| 3095 | Thai Pork Neck (kor moo yang) | Generic | TH | Entree | M | TODO | 2026-04-07 | | Grilled with jaew |
| 3096 | Khao Moo Daeng (red pork on rice) | Generic | TH | Rice | M | TODO | 2026-04-07 | | |
| 3097 | Khao Ka Moo (pork leg on rice) | Generic | TH | Rice | M | TODO | 2026-04-07 | | Braised pork trotter |
| 3098 | Bamee Moo Daeng (egg noodle with red pork) | Generic | TH | Noodles | M | TODO | 2026-04-07 | | |
| 3099 | Thai Milk Tea (hot) | Generic | TH | Beverage | M | TODO | 2026-04-07 | | |
| 3100 | Nom Yen (Thai pink milk) | Generic | TH | Beverage | L | TODO | 2026-04-07 | | Sala flavored milk |

## Section 74: Vietnamese Cuisine Full (70 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3103 | Pho Tai (rare beef pho) | Generic | VN | Soup | H | TODO | 2026-04-07 | | |
| 3104 | Pho Dac Biet (special combo pho) | Generic | VN | Soup | H | TODO | 2026-04-07 | | With tendon, tripe, meatball |
| 3107 | Banh Mi Thit (classic pork banh mi) | Generic | VN | Sandwich | H | TODO | 2026-04-07 | | With pate, pickled veg, cilantro |
| 3108 | Banh Mi Ga (chicken banh mi) | Generic | VN | Sandwich | H | TODO | 2026-04-07 | | |
| 3109 | Banh Mi Trung (fried egg banh mi) | Generic | VN | Sandwich | M | TODO | 2026-04-07 | | |
| 3110 | Banh Mi Xiu Mai (meatball banh mi) | Generic | VN | Sandwich | M | TODO | 2026-04-07 | | |
| 3111 | Banh Mi Chao (pate and butter banh mi) | Generic | VN | Sandwich | M | TODO | 2026-04-07 | | |
| 3115 | Bun Oc (snail noodle soup) | Generic | VN | Soup | L | TODO | 2026-04-07 | | Hanoi specialty |
| 3116 | Bun Mam (fermented fish noodle soup) | Generic | VN | Soup | L | TODO | 2026-04-07 | | Mekong Delta |
| 3118 | Com Tam Suon Bi Cha | Generic | VN | Rice | H | TODO | 2026-04-07 | | Broken rice with pork chop, skin, egg cake |
| 3125 | Banh Khot (mini crispy pancakes) | Generic | VN | Appetizer | M | TODO | 2026-04-07 | | With shrimp |
| 3126 | Bo La Lot (beef in betel leaf, 3 pcs) | Generic | VN | Appetizer | M | TODO | 2026-04-07 | | |
| 3128 | Ca Kho To (caramelized fish in clay pot) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 3129 | Thit Kho (caramelized pork belly with eggs) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 3131 | Suon Nuong (grilled pork chops) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 3133 | Goi Du Du (green papaya salad) | Generic | VN | Salad | M | TODO | 2026-04-07 | | With dried beef |
| 3134 | Goi Ngo Sen (lotus stem salad) | Generic | VN | Salad | L | TODO | 2026-04-07 | | |
| 3136 | Lau (Vietnamese hot pot, per serving) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 3137 | Mi Quang (turmeric noodles, Da Nang) | Generic | VN | Noodles | M | TODO | 2026-04-07 | | Central Vietnamese |
| 3138 | Cao Lau (Hoi An noodles) | Generic | VN | Noodles | L | TODO | 2026-04-07 | | |
| 3139 | Banh Canh (thick noodle soup) | Generic | VN | Soup | M | TODO | 2026-04-07 | | |
| 3140 | Nem Nuong (grilled pork sausage) | Generic | VN | Appetizer | M | TODO | 2026-04-07 | | |
| 3141 | Vietnamese Coffee (ca phe sua da) | Generic | VN | Beverage | H | TODO | 2026-04-07 | | Iced with condensed milk |
| 3142 | Vietnamese Coffee (ca phe den da) | Generic | VN | Beverage | M | TODO | 2026-04-07 | | Iced black |
| 3143 | Vietnamese Coffee (ca phe trung) | Generic | VN | Beverage | M | TODO | 2026-04-07 | | Egg coffee, Hanoi-style |
| 3144 | Vietnamese Coffee (bac xiu) | Generic | VN | Beverage | M | TODO | 2026-04-07 | | White coffee |
| 3145 | Sinh To Bo (avocado smoothie) | Generic | VN | Beverage | M | TODO | 2026-04-07 | | Vietnamese-style with condensed milk |
| 3146 | Nuoc Mia (sugarcane juice) | Generic | VN | Beverage | L | TODO | 2026-04-07 | | |
| 3147 | Che Ba Mau (three-color dessert) | Generic | VN | Dessert | M | TODO | 2026-04-07 | | Beans, jelly, coconut |
| 3148 | Che Chuoi (banana in coconut milk) | Generic | VN | Dessert | L | TODO | 2026-04-07 | | |
| 3150 | Banh Flan (Vietnamese creme caramel) | Generic | VN | Dessert | M | TODO | 2026-04-07 | | With coffee |
| 3152 | Xoi (sticky rice with toppings) | Generic | VN | Breakfast | M | TODO | 2026-04-07 | | With mung bean and fried shallots |
| 3153 | Banh Bao (steamed bun, 1 pc) | Generic | VN | Snack | M | TODO | 2026-04-07 | | With pork and egg |
| 3154 | Banh Gio (pyramid rice dumpling, 1 pc) | Generic | VN | Snack | L | TODO | 2026-04-07 | | |
| 3155 | Bun Dau Mam Tom (tofu with shrimp paste) | Generic | VN | Entree | L | TODO | 2026-04-07 | | Hanoi specialty |
| 3156 | Banh Bot Loc (tapioca dumplings, 5 pcs) | Generic | VN | Appetizer | L | TODO | 2026-04-07 | | Hue specialty |
| 3157 | Banh Nam (flat steamed rice cake, 3 pcs) | Generic | VN | Appetizer | L | TODO | 2026-04-07 | | Hue specialty |
| 3158 | Pho Xao (stir-fried pho noodles) | Generic | VN | Noodles | M | TODO | 2026-04-07 | | |
| 3159 | Bo Ne (Vietnamese sizzling steak) | Generic | VN | Entree | M | TODO | 2026-04-07 | | With egg and bread |
| 3160 | Com Ga Xoi Mo (crispy chicken rice) | Generic | VN | Rice | M | TODO | 2026-04-07 | | |
| 3161 | Banh Trang Tron (mixed rice paper snack) | Generic | VN | Snack | L | TODO | 2026-04-07 | | Saigon street food |
| 3162 | Bun Moc (pork ball noodle soup) | Generic | VN | Soup | M | TODO | 2026-04-07 | | |
| 3164 | Rau Muong Xao Toi (stir-fried morning glory) | Generic | VN | Vegetable | M | TODO | 2026-04-07 | | With garlic |
| 3165 | Dau Hu Chien (fried tofu with lemongrass) | Generic | VN | Entree | M | TODO | 2026-04-07 | | |
| 3166 | Banh Cong (shrimp and pork fritter) | Generic | VN | Snack | L | TODO | 2026-04-07 | | |
| 3167 | Bap Xao (Vietnamese corn stir-fry) | Generic | VN | Side | L | TODO | 2026-04-07 | | With dried shrimp and scallion |
| 3168 | Bo Kho (Vietnamese beef stew) | Generic | VN | Soup | M | TODO | 2026-04-07 | | With bread or noodles |
| 3169 | Goi Cuon Tom Thit (spring roll with shrimp/pork) | Generic | VN | Appetizer | H | TODO | 2026-04-07 | | |
| 3170 | Chao (Vietnamese rice porridge) | Generic | VN | Porridge | M | TODO | 2026-04-07 | | |

## Section 75: Indian Regional - North Indian Full (150 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3173 | Tandoori Chicken (per leg/thigh) | Generic | IN | Entree | H | TODO | 2026-04-07 | | |
| 3174 | Chicken Tikka (6 pcs) | Generic | IN | Appetizer | H | TODO | 2026-04-07 | | |
| 3175 | Malai Tikka (cream marinated chicken, 6 pcs) | Generic | IN | Appetizer | M | TODO | 2026-04-07 | | |
| 3177 | Galawati Kebab (2 pcs) | Generic | IN | Appetizer | M | TODO | 2026-04-07 | | Lucknow melt-in-mouth kebab |
| 3179 | Reshmi Kebab (2 pcs) | Generic | IN | Appetizer | M | TODO | 2026-04-07 | | Cream and egg marinated |
| 3183 | Chole Bhature | Generic | IN | Entree | H | TODO | 2026-04-07 | | Chole with fried bread |
| 3185 | Palak Paneer | Generic | IN | Entree | H | TODO | 2026-04-07 | | Spinach and cottage cheese |
| 3193 | Aloo Paratha (1 pc) | Generic | IN | Bread | H | TODO | 2026-04-07 | | Stuffed potato flatbread |
| 3196 | Methi Paratha (1 pc) | Generic | IN | Bread | M | TODO | 2026-04-07 | | Fenugreek flatbread |
| 3197 | Plain Naan (1 pc) | Generic | IN | Bread | H | TODO | 2026-04-07 | | |
| 3198 | Garlic Naan (1 pc) | Generic | IN | Bread | H | TODO | 2026-04-07 | | |
| 3199 | Butter Naan (1 pc) | Generic | IN | Bread | H | TODO | 2026-04-07 | | |
| 3200 | Cheese Naan (1 pc) | Generic | IN | Bread | M | TODO | 2026-04-07 | | |
| 3201 | Peshwari Naan (1 pc) | Generic | IN | Bread | M | TODO | 2026-04-07 | | Stuffed with nuts and raisins |
| 3202 | Tandoori Roti (1 pc) | Generic | IN | Bread | H | TODO | 2026-04-07 | | Whole wheat bread from tandoor |
| 3203 | Chapati/Roti (1 pc) | Generic | IN | Bread | H | TODO | 2026-04-07 | | Plain whole wheat flatbread |
| 3209 | Chicken Biryani (Hyderabadi) | Generic | IN | Rice | H | TODO | 2026-04-07 | | Dum biryani |
| 3210 | Mutton Biryani (Hyderabadi) | Generic | IN | Rice | H | TODO | 2026-04-07 | | |
| 3211 | Chicken Biryani (Lucknowi) | Generic | IN | Rice | M | TODO | 2026-04-07 | | Awadhi-style |
| 3212 | Veg Biryani | Generic | IN | Rice | M | TODO | 2026-04-07 | | |
| 3213 | Egg Biryani | Generic | IN | Rice | M | TODO | 2026-04-07 | | |
| 3214 | Prawn Biryani | Generic | IN | Rice | M | TODO | 2026-04-07 | | |
| 3222 | Dum Aloo (Kashmiri) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Baby potatoes in yogurt gravy |
| 3226 | Boti Kebab (mutton cubes, 6 pcs) | Generic | IN | Appetizer | M | TODO | 2026-04-07 | | |
| 3227 | Chicken Changezi | Generic | IN | Entree | M | TODO | 2026-04-07 | | Delhi Mughlai style |
| 3229 | Keema Pav | Generic | IN | Entree | M | TODO | 2026-04-07 | | Spiced mince with bread rolls |
| 3244 | Onion Bhaji (4 pcs) | Generic | IN | Snack | H | TODO | 2026-04-07 | | |
| 3245 | Paneer Pakora (4 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | |
| 3246 | Chicken 65 | Generic | IN | Appetizer | H | TODO | 2026-04-07 | | Spicy deep-fried chicken |
| 3247 | Mutton Curry (home-style) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3249 | Matar Mushroom | Generic | IN | Entree | M | TODO | 2026-04-07 | | Peas and mushroom curry |
| 3253 | Dum Aloo (Punjabi) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Potatoes in rich tomato gravy |
| 3254 | Chicken Do Pyaza | Generic | IN | Entree | M | TODO | 2026-04-07 | | Double onion chicken |
| 3255 | Butter Dal (dal fry with butter) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3260 | Pyaaz Ki Kachori | Generic | IN | Snack | L | TODO | 2026-04-07 | | Rajasthani onion pastry |
| 3261 | Dhokla (per piece) | Generic | IN | Snack | H | TODO | 2026-04-07 | | Gujarati steamed chickpea cake |
| 3264 | Fafda with Jalebi | Generic | IN | Snack | M | TODO | 2026-04-07 | | Gujarati breakfast combo |
| 3270 | Chicken Mughlai | Generic | IN | Entree | M | TODO | 2026-04-07 | | Rich egg-based gravy |
| 3271 | Chicken Achari | Generic | IN | Entree | M | TODO | 2026-04-07 | | Pickle-spiced chicken |
| 3272 | Butter Paneer | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3273 | Paneer Lababdar | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3275 | Paranthe Wali Gali Paratha | Generic | IN | Bread | M | TODO | 2026-04-07 | | Delhi street-style stuffed paratha |
| 3276 | Ram Ladoo (6 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Delhi street food moong dal fritter |
| 3277 | Chhole Kulche (Delhi street) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Delhi street food |
| 3278 | Daulat Ki Chaat | Generic | IN | Dessert | L | TODO | 2026-04-07 | | Delhi winter milk foam |
| 3282 | Chole Chawal | Generic | IN | Entree | H | TODO | 2026-04-07 | | Chickpea curry with rice |
| 3284 | Kadhi Chawal | Generic | IN | Entree | M | TODO | 2026-04-07 | | Yogurt curry with rice |
| 3285 | Egg Curry | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3286 | Anda Bhurji (Indian scrambled eggs) | Generic | IN | Entree | M | TODO | 2026-04-07 | | With onion and spices |
| 3287 | Chicken Handi | Generic | IN | Entree | M | TODO | 2026-04-07 | | Cooked in clay pot |
| 3288 | Murgh Musallam | Generic | IN | Entree | L | TODO | 2026-04-07 | | Whole roasted chicken Mughlai |
| 3295 | Boondi Raita (per bowl) | Generic | IN | Side | M | TODO | 2026-04-07 | | |
| 3304 | Mango Lassi | Generic | IN | Beverage | H | TODO | 2026-04-07 | | |
| 3311 | Mushroom Matar | Generic | IN | Entree | M | TODO | 2026-04-07 | | Mushroom and peas curry |
| 3313 | Lauki Chana Dal | Generic | IN | Entree | L | TODO | 2026-04-07 | | Bottle gourd with lentils |
| 3314 | Chicken Saagwala | Generic | IN | Entree | M | TODO | 2026-04-07 | | Chicken with greens |
| 3315 | Mutton Rara | Generic | IN | Entree | M | TODO | 2026-04-07 | | Mutton with keema |
| 3316 | Mughlai Paratha (1 pc) | Generic | IN | Bread | M | TODO | 2026-04-07 | | Egg-stuffed fried paratha |
| 3317 | Bedmi Puri with Aloo (2 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Delhi breakfast |
| 3318 | Rabdi Jalebi | Generic | IN | Dessert | M | TODO | 2026-04-07 | | Jalebi with thickened milk |

## Section 76: Indian Regional - South Indian Full (120 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3321 | Plain Dosa | Generic | IN | Breakfast | H | TODO | 2026-04-07 | | Crispy rice and lentil crepe |
| 3322 | Masala Dosa | Generic | IN | Breakfast | H | TODO | 2026-04-07 | | With potato filling |
| 3323 | Mysore Masala Dosa | Generic | IN | Breakfast | H | TODO | 2026-04-07 | | With red chutney inside |
| 3324 | Rava Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Semolina crepe |
| 3325 | Onion Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 3326 | Paper Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Extra thin and crispy |
| 3327 | Set Dosa (3 pcs) | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Soft spongy dosas |
| 3328 | Ghee Roast Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Crispy with ghee |
| 3331 | Rava Idli (2 pcs) | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Semolina idli |
| 3332 | Mini Idli with Sambar (per bowl) | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 3333 | Medu Vada (2 pcs) | Generic | IN | Breakfast | H | TODO | 2026-04-07 | | Crispy lentil donuts |
| 3334 | Vada Sambar | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Vada soaked in sambar |
| 3335 | Dahi Vada (2 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Vada in yogurt |
| 3338 | Sambar (per bowl) | Generic | IN | Side | H | TODO | 2026-04-07 | | Lentil vegetable stew |
| 3340 | Coconut Chutney (per serving) | Generic | IN | Condiment | H | TODO | 2026-04-07 | | |
| 3342 | Pongal (ven pongal) | Generic | IN | Breakfast | H | TODO | 2026-04-07 | | Rice and lentil with pepper and ghee |
| 3343 | Sweet Pongal (sakkarai pongal) | Generic | IN | Dessert | M | TODO | 2026-04-07 | | Jaggery rice |
| 3350 | Kerala Parotta (1 pc) | Generic | IN | Bread | M | TODO | 2026-04-07 | | Flaky layered bread |
| 3352 | Kerala Chicken Fry | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3354 | Karimeen Pollichathu (pearl spot fish) | Generic | IN | Entree | L | TODO | 2026-04-07 | | Kerala specialty |
| 3355 | Kerala Prawn Curry | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3357 | Kerala Egg Curry | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3359 | Kootu (lentil vegetable stew) | Generic | IN | Side | M | TODO | 2026-04-07 | | |
| 3363 | Pachadi (yogurt side dish) | Generic | IN | Side | M | TODO | 2026-04-07 | | Kerala sadya item |
| 3364 | Kerala Sadya Meal (full) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Full banana leaf feast |
| 3365 | Malabar Biryani (chicken) | Generic | IN | Rice | M | TODO | 2026-04-07 | | Kerala-style with short grain rice |
| 3366 | Thalassery Biryani | Generic | IN | Rice | L | TODO | 2026-04-07 | | North Kerala style |
| 3368 | Ragi Mudde (ragi ball) | Generic | IN | Staple | M | TODO | 2026-04-07 | | Karnataka finger millet ball |
| 3369 | Udupi Sambar | Generic | IN | Side | M | TODO | 2026-04-07 | | Karnataka temple-style |
| 3372 | Benne Dosa | Generic | IN | Breakfast | L | TODO | 2026-04-07 | | Davangere butter dosa |
| 3374 | Gojju (tamarind curry) | Generic | IN | Side | L | TODO | 2026-04-07 | | Karnataka style |
| 3375 | Chicken Chettinad | Generic | IN | Entree | H | TODO | 2026-04-07 | | Tamil Nadu spicy pepper chicken |
| 3376 | Chettinad Fish Curry | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3377 | Chettinad Egg Curry | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3378 | Kuzhi Paniyaram (6 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Fermented rice and lentil balls |
| 3380 | Banana Chips (per serving) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Kerala-style |
| 3381 | Mixture (per serving) | Generic | IN | Snack | M | TODO | 2026-04-07 | | South Indian snack mix |
| 3383 | Gongura Chicken | Generic | IN | Entree | M | TODO | 2026-04-07 | | Andhra sorrel leaf curry |
| 3384 | Gongura Mutton | Generic | IN | Entree | L | TODO | 2026-04-07 | | |
| 3385 | Hyderabadi Haleem | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3388 | Curd Rice | Generic | IN | Rice | H | TODO | 2026-04-07 | | Yogurt rice, thayir sadam |
| 3389 | Tomato Rice | Generic | IN | Rice | M | TODO | 2026-04-07 | | |
| 3390 | Coconut Rice | Generic | IN | Rice | M | TODO | 2026-04-07 | | |
| 3391 | Bisi Bele Hulianna | Generic | IN | Rice | L | TODO | 2026-04-07 | | |
| 3392 | Hyderabadi Mirchi Ka Salan | Generic | IN | Side | M | TODO | 2026-04-07 | | Green chili curry |
| 3394 | Qubani Ka Meetha | Generic | IN | Dessert | L | TODO | 2026-04-07 | | Hyderabadi apricot dessert |
| 3396 | Semiya Payasam | Generic | IN | Dessert | M | TODO | 2026-04-07 | | Vermicelli pudding |
| 3398 | Palada Payasam | Generic | IN | Dessert | L | TODO | 2026-04-07 | | Kerala rice flake pudding |
| 3401 | Panagam | Generic | IN | Beverage | L | TODO | 2026-04-07 | | Jaggery ginger drink |
| 3402 | Neer Mor (spiced buttermilk) | Generic | IN | Beverage | M | TODO | 2026-04-07 | | |
| 3405 | Telangana Maamsam (mutton fry) | Generic | IN | Entree | L | TODO | 2026-04-07 | | |
| 3406 | Andhra Pappu (dal with greens) | Generic | IN | Side | M | TODO | 2026-04-07 | | |
| 3408 | Pesarattu Upma | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Moong dosa with upma stuffing |
| 3409 | Podi Idli (gunpowder spice idli) | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 3410 | Ghee Podi Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Dosa with spice powder and ghee |
| 3411 | Paniyaram (sweet, 6 pcs) | Generic | IN | Snack | L | TODO | 2026-04-07 | | |
| 3412 | Kothu Parotta | Generic | IN | Entree | M | TODO | 2026-04-07 | | Shredded parotta stir-fry |
| 3413 | Parotta Salna | Generic | IN | Entree | M | TODO | 2026-04-07 | | Parotta with spiced gravy |
| 3414 | Kozhi Varuval (Tamil chicken fry) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3415 | Meen Varuval (Tamil fish fry) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3418 | Poriyal (dry vegetable stir-fry) | Generic | IN | Side | M | TODO | 2026-04-07 | | Tamil style with coconut |
| 3419 | Vazhaipoo Vadai (banana flower vada, 2 pcs) | Generic | IN | Snack | L | TODO | 2026-04-07 | | |
| 3420 | Kerala Unniyappam (6 pcs) | Generic | IN | Snack | L | TODO | 2026-04-07 | | Sweet rice and banana balls |
| 3421 | Nei Dosa (ghee dosa) | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 3422 | Egg Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Dosa with egg on top |
| 3423 | Chicken Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 3424 | Paneer Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | |
| 3425 | Podi Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | With gunpowder spice |
| 3426 | Spring Dosa | Generic | IN | Breakfast | M | TODO | 2026-04-07 | | Chinese-Indian fusion |
| 3427 | Masala Vada (2 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Chana dal fritters |
| 3428 | Ulundu Vadai (2 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Urad dal vada |
| 3429 | Bajji/Pakoda (banana, 3 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Battered banana fritters |
| 3431 | Mango Pickle (per tbsp) | Generic | IN | Condiment | M | TODO | 2026-04-07 | | |
| 3432 | Avakaya (Andhra mango pickle, per tbsp) | Generic | IN | Condiment | L | TODO | 2026-04-07 | | |
| 3433 | Thogayal (per tbsp) | Generic | IN | Condiment | L | TODO | 2026-04-07 | | Tamil thick chutney |
| 3434 | Kesari (semolina sweet) | Generic | IN | Dessert | M | TODO | 2026-04-07 | | |
| 3436 | Banana Bonda (2 pcs) | Generic | IN | Snack | L | TODO | 2026-04-07 | | Banana fritters |
| 3437 | Uzhunnu Vada (2 pcs) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Kerala urad dal vada |
| 3439 | Ela Ada (2 pcs) | Generic | IN | Dessert | L | TODO | 2026-04-07 | | Kerala banana leaf wrapped sweet |
| 3440 | Unni Appam (6 pcs) | Generic | IN | Snack | L | TODO | 2026-04-07 | | Kerala sweet rice balls with banana |

## Section 77: Indian Regional - East & West (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3441 | Machher Jhol (Bengali fish curry) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Everyday fish curry |
| 3443 | Chingri Malai Curry (prawn in coconut) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3446 | Aloo Dum (Bengali-style) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Baby potatoes in gravy |
| 3451 | Fish Fry (Bengali kolkata-style) | Generic | IN | Appetizer | M | TODO | 2026-04-07 | | Crumb-coated fish cutlet |
| 3462 | Sondesh Varieties (nolen gur, 2 pcs) | Generic | IN | Dessert | M | TODO | 2026-04-07 | | Date palm jaggery flavored |
| 3463 | Misti Pulao (sweet rice) | Generic | IN | Rice | L | TODO | 2026-04-07 | | Bengali wedding rice |
| 3465 | Khar (Assamese alkaline dish) | Generic | IN | Side | L | TODO | 2026-04-07 | | |
| 3472 | Goa Fish Curry (Xitt Kodi) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Coconut-based with kokum |
| 3473 | Goan Vindaloo (pork) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Spicy vinegar-based curry |
| 3474 | Goan Vindaloo (chicken) | Generic | IN | Entree | M | TODO | 2026-04-07 | | |
| 3475 | Goan Xacuti (chicken) | Generic | IN | Entree | M | TODO | 2026-04-07 | | Roasted spice coconut curry |
| 3476 | Pork Sorpotel | Generic | IN | Entree | L | TODO | 2026-04-07 | | Goan Portuguese-influenced |
| 3481 | Vada Pav (1 pc) | Generic | IN | Snack | H | TODO | 2026-04-07 | | Mumbai street burger |
| 3502 | Dal Bafla (MP-style dal baati) | Generic | IN | Entree | L | TODO | 2026-04-07 | | |
| 3503 | Mawa Bati (1 pc) | Generic | IN | Dessert | L | TODO | 2026-04-07 | | MP milk-based sweet |
| 3507 | Sattu Drink (per glass) | Generic | IN | Beverage | L | TODO | 2026-04-07 | | Bihar cooler |
| 3511 | Alur Chop (potato croquette, 1 pc) | Generic | IN | Snack | M | TODO | 2026-04-07 | | Bengali |
| 3513 | Bhapa Ilish (steamed hilsa) | Generic | IN | Entree | L | TODO | 2026-04-07 | | Bengali delicacy |
| 3514 | Posto Bora (poppy seed fritters, 4 pcs) | Generic | IN | Side | L | TODO | 2026-04-07 | | Bengali |
| 3516 | Paturi (fish in banana leaf) | Generic | IN | Entree | L | TODO | 2026-04-07 | | Bengali |
| 3517 | Mangsher Chop (mutton cutlet, 1 pc) | Generic | IN | Snack | L | TODO | 2026-04-07 | | Bengali |
| 3518 | Macher Kalia (fish in rich gravy) | Generic | IN | Entree | L | TODO | 2026-04-07 | | Bengali celebration dish |
| 3519 | Koraishutir Kochuri (pea kachori, 1 pc) | Generic | IN | Snack | L | TODO | 2026-04-07 | | Bengali winter special |

## Section 78: Mexican Cuisine Full (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3522 | Tacos de Carnitas (3 pcs) | Generic | MX | Tacos | H | TODO | 2026-04-07 | | Slow-cooked pulled pork |
| 3523 | Tacos de Barbacoa (3 pcs) | Generic | MX | Tacos | H | TODO | 2026-04-07 | | Slow-cooked beef cheek |
| 3524 | Birria Tacos (3 pcs) | Generic | MX | Tacos | H | TODO | 2026-04-07 | | With consomme for dipping |
| 3525 | Tacos de Asada (3 pcs) | Generic | MX | Tacos | H | TODO | 2026-04-07 | | Grilled steak |
| 3526 | Tacos de Lengua (3 pcs) | Generic | MX | Tacos | M | TODO | 2026-04-07 | | Beef tongue |
| 3527 | Tacos de Chorizo (3 pcs) | Generic | MX | Tacos | M | TODO | 2026-04-07 | | |
| 3528 | Tacos de Pollo (3 pcs) | Generic | MX | Tacos | H | TODO | 2026-04-07 | | Chicken |
| 3529 | Fish Tacos (3 pcs) | Generic | MX | Tacos | H | TODO | 2026-04-07 | | Battered or grilled |
| 3530 | Shrimp Tacos (3 pcs) | Generic | MX | Tacos | M | TODO | 2026-04-07 | | |
| 3531 | Tacos de Cabeza (3 pcs) | Generic | MX | Tacos | L | TODO | 2026-04-07 | | Beef head meat |
| 3532 | Tacos de Suadero (3 pcs) | Generic | MX | Tacos | M | TODO | 2026-04-07 | | Brisket/rose meat |
| 3533 | Tacos de Tripa (3 pcs) | Generic | MX | Tacos | L | TODO | 2026-04-07 | | Tripe |
| 3535 | Cheese Enchiladas (3 pcs) | Generic | MX | Entree | M | TODO | 2026-04-07 | | |
| 3536 | Enchiladas Suizas (3 pcs) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Creamy tomatillo sauce |
| 3538 | Beef Burrito | Generic | MX | Entree | H | TODO | 2026-04-07 | | |
| 3539 | Chicken Burrito | Generic | MX | Entree | H | TODO | 2026-04-07 | | |
| 3540 | Bean and Cheese Burrito | Generic | MX | Entree | H | TODO | 2026-04-07 | | |
| 3545 | Chicken Tamale (1 pc) | Generic | MX | Entree | H | TODO | 2026-04-07 | | Steamed corn masa |
| 3547 | Sweet Tamale (1 pc) | Generic | MX | Entree | M | TODO | 2026-04-07 | | With raisins or pineapple |
| 3548 | Tamale Verde (1 pc) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Green sauce chicken |
| 3549 | Mole Negro (with chicken) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Oaxacan black mole |
| 3550 | Mole Rojo (with chicken) | Generic | MX | Entree | M | TODO | 2026-04-07 | | |
| 3551 | Mole Verde (with chicken) | Generic | MX | Entree | M | TODO | 2026-04-07 | | |
| 3553 | Pozole Rojo (pork) | Generic | MX | Soup | H | TODO | 2026-04-07 | | Hominy soup |
| 3554 | Pozole Verde | Generic | MX | Soup | M | TODO | 2026-04-07 | | |
| 3556 | Chilaquiles Rojos | Generic | MX | Breakfast | H | TODO | 2026-04-07 | | Fried tortillas in red sauce |
| 3557 | Chilaquiles Verdes | Generic | MX | Breakfast | H | TODO | 2026-04-07 | | With green tomatillo sauce |
| 3559 | Huevos a la Mexicana | Generic | MX | Breakfast | M | TODO | 2026-04-07 | | Scrambled with tomato, onion, chili |
| 3560 | Huevos con Chorizo | Generic | MX | Breakfast | M | TODO | 2026-04-07 | | |
| 3562 | Torta de Milanesa | Generic | MX | Sandwich | M | TODO | 2026-04-07 | | Breaded beef sandwich |
| 3563 | Torta Ahogada | Generic | MX | Sandwich | M | TODO | 2026-04-07 | | Drowned sandwich, Guadalajara |
| 3564 | Torta de Jamon | Generic | MX | Sandwich | M | TODO | 2026-04-07 | | Ham sandwich |
| 3566 | Tlacoyos (2 pcs) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Stuffed oval corn cakes |
| 3567 | Tostadas de Tinga (2 pcs) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Chipotle chicken on crispy tortilla |
| 3568 | Tostada de Ceviche | Generic | MX | Entree | M | TODO | 2026-04-07 | | |
| 3569 | Flautas (3 pcs) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Rolled and fried tacos |
| 3570 | Aguachile (shrimp) | Generic | MX | Appetizer | M | TODO | 2026-04-07 | | Raw shrimp in chili lime |
| 3571 | Mexican Ceviche (per serving) | Generic | MX | Appetizer | M | TODO | 2026-04-07 | | |
| 3573 | Queso Fundido | Generic | MX | Appetizer | M | TODO | 2026-04-07 | | Melted cheese with chorizo |
| 3575 | Esquites (corn in a cup) | Generic | MX | Side | M | TODO | 2026-04-07 | | |
| 3576 | Mexican Rice (per serving) | Generic | MX | Side | H | TODO | 2026-04-07 | | Arroz rojo |
| 3579 | Nopal Salad | Generic | MX | Side | M | TODO | 2026-04-07 | | Cactus paddle salad |
| 3580 | Chips and Salsa (per basket) | Generic | MX | Appetizer | H | TODO | 2026-04-07 | | Restaurant-style |
| 3583 | Flan Napolitano (1 slice) | Generic | MX | Dessert | M | TODO | 2026-04-07 | | |
| 3585 | Chamoyada (mango) | Generic | MX | Beverage | M | TODO | 2026-04-07 | | Frozen fruit with chamoy |
| 3587 | Agua de Jamaica (per glass) | Generic | MX | Beverage | M | TODO | 2026-04-07 | | Hibiscus water |
| 3588 | Agua de Tamarindo | Generic | MX | Beverage | M | TODO | 2026-04-07 | | Tamarind water |
| 3590 | Champurrado (per cup) | Generic | MX | Beverage | M | TODO | 2026-04-07 | | Chocolate atole |
| 3591 | Mexican Hot Chocolate (per cup) | Generic | MX | Beverage | M | TODO | 2026-04-07 | | With cinnamon |
| 3592 | Michelada (per glass) | Generic | MX | Alcohol | M | TODO | 2026-04-07 | | Beer with lime and chili |
| 3594 | Paloma (per glass) | Generic | MX | Alcohol | M | TODO | 2026-04-07 | | Tequila and grapefruit |
| 3595 | Chimichanga (beef) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Deep-fried burrito |
| 3596 | Taquitos (5 pcs) | Generic | MX | Snack | M | TODO | 2026-04-07 | | Rolled corn tacos, fried |
| 3598 | Cochinita Pibil Tacos (3 pcs) | Generic | MX | Tacos | M | TODO | 2026-04-07 | | Yucatan slow-roasted pork |
| 3599 | Papadzules | Generic | MX | Entree | L | TODO | 2026-04-07 | | Yucatan egg enchiladas in pumpkin seed |
| 3600 | Sopa Azteca (tortilla soup) | Generic | MX | Soup | M | TODO | 2026-04-07 | | |
| 3601 | Caldo de Pollo | Generic | MX | Soup | M | TODO | 2026-04-07 | | Mexican chicken soup |
| 3602 | Caldo de Res | Generic | MX | Soup | M | TODO | 2026-04-07 | | Mexican beef soup |
| 3605 | Conchas (1 pc) | Generic | MX | Bakery | M | TODO | 2026-04-07 | | Mexican sweet bread |
| 3606 | Pan de Muerto (1 slice) | Generic | MX | Bakery | L | TODO | 2026-04-07 | | Day of the Dead bread |
| 3607 | Ojo de Buey (1 pc) | Generic | MX | Bakery | L | TODO | 2026-04-07 | | Bull's eye pastry |
| 3608 | Molletes (2 halves) | Generic | MX | Breakfast | M | TODO | 2026-04-07 | | Open-faced bean and cheese |
| 3609 | Bionico | Generic | MX | Dessert | M | TODO | 2026-04-07 | | Mexican fruit cup with cream |
| 3610 | Mangonada | Generic | MX | Beverage | M | TODO | 2026-04-07 | | Mango smoothie with chamoy |
| 3611 | Corn in a Cup (elote en vaso) | Generic | MX | Side | M | TODO | 2026-04-07 | | Street vendor style |
| 3614 | Migas (Mexican scrambled) | Generic | MX | Breakfast | M | TODO | 2026-04-07 | | Eggs with fried tortilla strips |
| 3615 | Huarache (1 pc) | Generic | MX | Entree | M | TODO | 2026-04-07 | | Large oval shaped masa |
| 3616 | Birria Ramen | Generic | MX | Noodles | M | TODO | 2026-04-07 | | Fusion dish |
| 3618 | Chiles en Nogada | Generic | MX | Entree | L | TODO | 2026-04-07 | | Stuffed chile with walnut cream |
| 3619 | Mole de Olla | Generic | MX | Soup | L | TODO | 2026-04-07 | | Brothy mole soup |
| 3620 | Tacos Dorados (3 pcs) | Generic | MX | Tacos | M | TODO | 2026-04-07 | | Golden fried tacos |

## Section 79: Italian Cuisine Full (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3622 | Cacio e Pepe | Generic | IT | Pasta | H | TODO | 2026-04-07 | | Pecorino and black pepper |
| 3623 | Pasta all'Amatriciana | Generic | IT | Pasta | H | TODO | 2026-04-07 | | Guanciale and tomato |
| 3625 | Spaghetti Puttanesca | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Olives, capers, anchovy |
| 3626 | Pesto Pasta (basil) | Generic | IT | Pasta | H | TODO | 2026-04-07 | | Genovese pesto |
| 3627 | Spaghetti alle Vongole | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Clam pasta |
| 3629 | Pasta Bolognese (ragu) | Generic | IT | Pasta | H | TODO | 2026-04-07 | | Meat sauce |
| 3630 | Aglio e Olio | Generic | IT | Pasta | H | TODO | 2026-04-07 | | Garlic and olive oil |
| 3631 | Pasta alla Norma | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Eggplant and ricotta salata |
| 3632 | Penne alla Vodka | Generic | IT | Pasta | H | TODO | 2026-04-07 | | Creamy tomato vodka sauce |
| 3636 | Ravioli (cheese, 6 pcs) | Generic | IT | Pasta | M | TODO | 2026-04-07 | | In marinara |
| 3637 | Ravioli (meat, 6 pcs) | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 3638 | Tortellini in Brodo | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Stuffed pasta in broth |
| 3639 | Gnocchi with Tomato Sauce | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 3640 | Gnocchi with Pesto | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 3641 | Gnocchi with Gorgonzola Cream | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 3642 | Risotto alla Milanese (saffron) | Generic | IT | Rice | M | TODO | 2026-04-07 | | |
| 3645 | Risotto al Limone | Generic | IT | Rice | L | TODO | 2026-04-07 | | Lemon risotto |
| 3648 | Pizza Marinara (1 slice) | Generic | IT | Pizza | M | TODO | 2026-04-07 | | Tomato, garlic, oregano, no cheese |
| 3649 | Pizza Quattro Formaggi (1 slice) | Generic | IT | Pizza | M | TODO | 2026-04-07 | | Four cheese |
| 3650 | Pizza Diavola (1 slice) | Generic | IT | Pizza | M | TODO | 2026-04-07 | | Spicy salami |
| 3651 | Pizza Prosciutto e Funghi (1 slice) | Generic | IT | Pizza | M | TODO | 2026-04-07 | | Ham and mushroom |
| 3652 | Pizza Capricciosa (1 slice) | Generic | IT | Pizza | M | TODO | 2026-04-07 | | |
| 3655 | Antipasto Platter (per serving) | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Cured meats, cheese, olives |
| 3657 | Carpaccio (beef) | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Thin raw beef |
| 3658 | Prosciutto e Melone | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Ham with cantaloupe |
| 3659 | Calamari Fritti | Generic | IT | Appetizer | H | TODO | 2026-04-07 | | Fried squid |
| 3661 | Saltimbocca alla Romana | Generic | IT | Entree | M | TODO | 2026-04-07 | | Veal with prosciutto and sage |
| 3663 | Eggplant Parmigiana | Generic | IT | Entree | M | TODO | 2026-04-07 | | |
| 3664 | Veal Piccata | Generic | IT | Entree | M | TODO | 2026-04-07 | | Lemon caper sauce |
| 3665 | Veal Marsala | Generic | IT | Entree | M | TODO | 2026-04-07 | | Marsala wine sauce |
| 3666 | Chicken Marsala | Generic | IT | Entree | M | TODO | 2026-04-07 | | |
| 3670 | Italian Wedding Soup | Generic | IT | Soup | M | TODO | 2026-04-07 | | With meatballs |
| 3671 | Pasta e Fagioli | Generic | IT | Soup | M | TODO | 2026-04-07 | | Pasta and bean soup |
| 3672 | Stracciatella Soup | Generic | IT | Soup | L | TODO | 2026-04-07 | | Italian egg drop soup |
| 3683 | Italian Panini (prosciutto mozzarella) | Generic | IT | Sandwich | M | TODO | 2026-04-07 | | |
| 3684 | Porchetta Sandwich | Generic | IT | Sandwich | M | TODO | 2026-04-07 | | Herb-roasted pork |
| 3685 | Italian Sub/Hero | Generic | IT | Sandwich | H | TODO | 2026-04-07 | | Salami, capicola, provolone |
| 3687 | Garlic Bread (2 pcs) | Generic | IT | Bread | H | TODO | 2026-04-07 | | |
| 3692 | Aperol Spritz | Generic | IT | Alcohol | H | TODO | 2026-04-07 | | |
| 3693 | Italian Espresso (1 shot) | Generic | IT | Beverage | H | TODO | 2026-04-07 | | |
| 3696 | Orecchiette with Broccoli Rabe | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Pugliese |
| 3697 | Bucatini all'Amatriciana | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 3698 | Linguine with Pesto | Generic | IT | Pasta | M | TODO | 2026-04-07 | | |
| 3699 | Pappardelle with Wild Boar Ragu | Generic | IT | Pasta | L | TODO | 2026-04-07 | | Tuscan |
| 3700 | Rigatoni alla Gricia | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Guanciale and pecorino |
| 3701 | Stuffed Shells (5 pcs) | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Ricotta-filled conchiglioni |
| 3702 | Manicotti (2 pcs) | Generic | IT | Pasta | M | TODO | 2026-04-07 | | Stuffed pasta tubes |
| 3704 | Vitello Tonnato | Generic | IT | Appetizer | L | TODO | 2026-04-07 | | Cold veal with tuna sauce |
| 3705 | Biscotti (2 pcs) | Generic | IT | Dessert | M | TODO | 2026-04-07 | | Almond twice-baked cookies |
| 3706 | Sfogliatella (1 pc) | Generic | IT | Dessert | L | TODO | 2026-04-07 | | Neapolitan pastry |
| 3707 | Bombolone (1 pc) | Generic | IT | Dessert | M | TODO | 2026-04-07 | | Italian filled donut |
| 3708 | Zabaglione | Generic | IT | Dessert | L | TODO | 2026-04-07 | | Egg and wine custard |
| 3709 | Fritto Misto | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Mixed fried seafood |
| 3710 | Crostini (3 pcs) | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Toasted bread with toppings |
| 3711 | Suppli (fried rice balls, 2 pcs) | Generic | IT | Appetizer | M | TODO | 2026-04-07 | | Roman-style |
| 3713 | Polenta Fries | Generic | IT | Side | M | TODO | 2026-04-07 | | Fried polenta sticks |
| 3714 | Insalata Mista | Generic | IT | Side | M | TODO | 2026-04-07 | | Mixed Italian salad |
| 3716 | Calzone (whole) | Generic | IT | Pizza | M | TODO | 2026-04-07 | | Folded stuffed pizza |
| 3718 | Pizza Bianca (1 slice) | Generic | IT | Pizza | M | TODO | 2026-04-07 | | White pizza |
| 3720 | Amaretti Cookies (3 pcs) | Generic | IT | Dessert | L | TODO | 2026-04-07 | | Almond macaroons |

## Section 80: Mediterranean & Greek (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3721 | Chicken Gyro (sandwich) | Generic | GR | Sandwich | H | TODO | 2026-04-07 | | With tzatziki and pita |
| 3722 | Lamb Gyro (sandwich) | Generic | GR | Sandwich | H | TODO | 2026-04-07 | | |
| 3723 | Gyro Plate (chicken) | Generic | GR | Entree | H | TODO | 2026-04-07 | | With rice and salad |
| 3724 | Chicken Souvlaki (2 skewers) | Generic | GR | Entree | H | TODO | 2026-04-07 | | |
| 3725 | Pork Souvlaki (2 skewers) | Generic | GR | Entree | M | TODO | 2026-04-07 | | |
| 3726 | Lamb Souvlaki (2 skewers) | Generic | GR | Entree | M | TODO | 2026-04-07 | | |
| 3730 | Tiropita (1 piece) | Generic | GR | Appetizer | M | TODO | 2026-04-07 | | Cheese pie |
| 3734 | Saganaki (fried cheese) | Generic | GR | Appetizer | M | TODO | 2026-04-07 | | Flaming cheese |
| 3735 | Greek Lemon Chicken | Generic | GR | Entree | M | TODO | 2026-04-07 | | With potatoes |
| 3736 | Greek Lamb Chops | Generic | GR | Entree | M | TODO | 2026-04-07 | | |
| 3737 | Avgolemono Soup | Generic | GR | Soup | M | TODO | 2026-04-07 | | Egg-lemon chicken soup |
| 3738 | Fasolada (Greek bean soup) | Generic | GR | Soup | M | TODO | 2026-04-07 | | |
| 3740 | Galaktoboureko (1 piece) | Generic | GR | Dessert | M | TODO | 2026-04-07 | | Custard-filled filo |
| 3745 | Fattoush Salad | Generic | LB | Salad | M | TODO | 2026-04-07 | | With fried pita |
| 3749 | Manakish Cheese (1 pc) | Generic | LB | Bread | M | TODO | 2026-04-07 | | |
| 3750 | Hummus Plate (with pita) | Generic | LB | Appetizer | H | TODO | 2026-04-07 | | |
| 3755 | Turkish Pide (meat) | Generic | TR | Entree | M | TODO | 2026-04-07 | | Boat-shaped flatbread |
| 3756 | Gozleme (spinach and cheese) | Generic | TR | Entree | M | TODO | 2026-04-07 | | Stuffed flatbread |
| 3757 | Turkish Manti (per serving) | Generic | TR | Entree | M | TODO | 2026-04-07 | | Tiny dumplings with yogurt |
| 3762 | Turkish Coffee (1 cup) | Generic | TR | Beverage | M | TODO | 2026-04-07 | | |
| 3765 | Falafel Plate (6 pcs with sides) | Generic | IL | Entree | H | TODO | 2026-04-07 | | |
| 3766 | Falafel Pita Sandwich | Generic | IL | Sandwich | H | TODO | 2026-04-07 | | |
| 3767 | Sabich (pita sandwich) | Generic | IL | Sandwich | M | TODO | 2026-04-07 | | Eggplant and egg in pita |
| 3768 | Hummus Plate (Israeli-style with meat) | Generic | IL | Entree | M | TODO | 2026-04-07 | | Masabacha with lamb |
| 3769 | Israeli Schnitzel (chicken) | Generic | IL | Entree | M | TODO | 2026-04-07 | | In pita or on plate |
| 3770 | Israeli Salad | Generic | IL | Salad | M | TODO | 2026-04-07 | | Diced cucumber and tomato |
| 3772 | Malawach (1 pc) | Generic | IL | Bread | L | TODO | 2026-04-07 | | Yemenite flaky bread |
| 3773 | Koshari | Generic | EG | Entree | M | TODO | 2026-04-07 | | Egyptian rice, lentil, pasta mix |
| 3774 | Ful Medames | Generic | EG | Breakfast | M | TODO | 2026-04-07 | | Stewed fava beans |
| 3779 | Couscous with Seven Vegetables | Generic | MA | Entree | M | TODO | 2026-04-07 | | |
| 3780 | Couscous with Lamb | Generic | MA | Entree | M | TODO | 2026-04-07 | | |
| 3782 | Harira Soup | Generic | MA | Soup | M | TODO | 2026-04-07 | | Tomato lentil soup |
| 3784 | Lamb Kofta (3 pcs) | Generic | MA | Entree | M | TODO | 2026-04-07 | | |
| 3785 | Moroccan Mint Tea (1 cup) | Generic | MA | Beverage | M | TODO | 2026-04-07 | | |
| 3790 | Kousa Mahshi (stuffed zucchini, 3 pcs) | Generic | LB | Entree | M | TODO | 2026-04-07 | | |
| 3791 | Warak Enab (stuffed vine leaves, 5 pcs) | Generic | LB | Appetizer | M | TODO | 2026-04-07 | | |
| 3799 | Mixed Grill Plate (Mediterranean) | Generic | LB | Entree | M | TODO | 2026-04-07 | | Kafta, chicken, lamb |
| 3800 | Rice Pilaf (Middle Eastern) | Generic | LB | Side | M | TODO | 2026-04-07 | | With vermicelli |

## Section 81: Latin American Cuisine (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3809 | Pastel (fried, 1 pc) | Generic | BR | Snack | M | TODO | 2026-04-07 | | Fried pastry with filling |
| 3810 | Churrasco Plate (mixed meats) | Generic | BR | Entree | M | TODO | 2026-04-07 | | Brazilian BBQ assortment |
| 3811 | Guarana Soda (1 can) | Generic | BR | Beverage | M | TODO | 2026-04-07 | | |
| 3813 | Asado Tira de Costilla (short ribs) | Generic | AR | Entree | M | TODO | 2026-04-07 | | Argentine BBQ ribs |
| 3814 | Argentine Empanada (beef, 1 pc) | Generic | AR | Snack | M | TODO | 2026-04-07 | | |
| 3815 | Argentine Empanada (ham and cheese, 1 pc) | Generic | AR | Snack | M | TODO | 2026-04-07 | | |
| 3816 | Milanesa de Pollo | Generic | AR | Entree | M | TODO | 2026-04-07 | | Argentine breaded chicken |
| 3817 | Milanesa Napolitana | Generic | AR | Entree | M | TODO | 2026-04-07 | | With tomato, ham, cheese |
| 3819 | Choripan | Generic | AR | Sandwich | M | TODO | 2026-04-07 | | Chorizo sandwich with chimichurri |
| 3820 | Dulce de Leche (per tbsp) | Generic | AR | Condiment | M | TODO | 2026-04-07 | | |
| 3832 | Pisco Sour | Generic | PE | Alcohol | M | TODO | 2026-04-07 | | |
| 3835 | Arepa de Queso (1 pc) | Generic | CO | Bread | M | TODO | 2026-04-07 | | Cheese corn cake |
| 3836 | Arepa con Huevo (1 pc) | Generic | CO | Breakfast | M | TODO | 2026-04-07 | | Fried arepa with egg inside |
| 3837 | Colombian Empanada (1 pc) | Generic | CO | Snack | M | TODO | 2026-04-07 | | Fried corn empanada |
| 3845 | Yuca Frita (fried cassava) | Generic | CU | Side | M | TODO | 2026-04-07 | | |
| 3849 | Medianoche Sandwich | Generic | CU | Sandwich | M | TODO | 2026-04-07 | | Sweet bread Cuban sandwich |
| 3850 | Pastelito de Guayaba (1 pc) | Generic | CU | Dessert | M | TODO | 2026-04-07 | | Guava pastry |
| 3856 | Oxtail Stew (Caribbean) | Generic | JM | Entree | M | TODO | 2026-04-07 | | |
| 3857 | Curry Goat (Jamaican) | Generic | JM | Entree | M | TODO | 2026-04-07 | | |
| 3858 | Rice and Peas (Jamaican) | Generic | JM | Side | M | TODO | 2026-04-07 | | With coconut milk and kidney beans |
| 3861 | Sorrel Drink (per glass) | Generic | JM | Beverage | L | TODO | 2026-04-07 | | Hibiscus and ginger |
| 3862 | Pastel de Choclo | Generic | CL | Entree | M | TODO | 2026-04-07 | | Chilean corn pie with meat |
| 3863 | Chilean Empanada de Pino (1 pc) | Generic | CL | Snack | M | TODO | 2026-04-07 | | Beef with egg and olive |
| 3864 | Cazuela (Chilean, per serving) | Generic | CL | Soup | L | TODO | 2026-04-07 | | Meat and vegetable stew |
| 3866 | Arepa Reina Pepiada (1 pc) | Generic | VE | Sandwich | M | TODO | 2026-04-07 | | Venezuelan chicken avocado arepa |
| 3867 | Arepa de Pabellon (1 pc) | Generic | VE | Sandwich | M | TODO | 2026-04-07 | | Shredded beef, beans, plantain |
| 3868 | Arepa de Jamon y Queso (1 pc) | Generic | VE | Sandwich | M | TODO | 2026-04-07 | | Ham and cheese |
| 3870 | Pabellon Criollo | Generic | VE | Entree | M | TODO | 2026-04-07 | | Shredded beef, rice, beans, plantain |
| 3871 | Tequenos (5 pcs) | Generic | VE | Snack | M | TODO | 2026-04-07 | | Cheese-filled fried sticks |
| 3873 | Arroz con Gandules | Generic | PR | Rice | M | TODO | 2026-04-07 | | Puerto Rican rice with pigeon peas |
| 3876 | Pupusa (cheese, 1 pc) | Generic | SV | Bread | M | TODO | 2026-04-07 | | Salvadoran stuffed corn cake |
| 3877 | Pupusa Revuelta (1 pc) | Generic | SV | Bread | M | TODO | 2026-04-07 | | Cheese, bean, pork |
| 3878 | Baleada (1 pc) | Generic | HN | Bread | M | TODO | 2026-04-07 | | Honduran flour tortilla with beans and cheese |
| 3879 | Gallo Pinto | Generic | CR | Entree | M | TODO | 2026-04-07 | | Costa Rican rice and beans |
| 3880 | Empanada de Verde (1 pc) | Generic | EC | Snack | L | TODO | 2026-04-07 | | Ecuadorian green plantain empanada |
| 3881 | Ceviche Ecuatoriano | Generic | EC | Appetizer | L | TODO | 2026-04-07 | | With popcorn garnish |
| 3882 | Saltenas (1 pc) | Generic | BO | Snack | L | TODO | 2026-04-07 | | Bolivian juicy empanada |
| 3883 | Tres Golpes (Dominican breakfast) | Generic | DO | Breakfast | L | TODO | 2026-04-07 | | Mangu, eggs, salami, cheese |
| 3884 | Mangu (mashed plantain) | Generic | DO | Side | L | TODO | 2026-04-07 | | Dominican breakfast staple |
| 3885 | Chivito (Uruguayan sandwich) | Generic | UY | Sandwich | L | TODO | 2026-04-07 | | Steak sandwich with eggs and ham |
| 3887 | Chimichurri Steak (per serving) | Generic | AR | Entree | M | TODO | 2026-04-07 | | |
| 3888 | Empanada Saltena (1 pc) | Generic | AR | Snack | M | TODO | 2026-04-07 | | Juicy beef empanada |
| 3890 | Flan de Coco | Generic | PR | Dessert | M | TODO | 2026-04-07 | | Coconut flan |
| 3893 | Arroz con Pollo (Latin, per serving) | Generic | PE | Entree | M | TODO | 2026-04-07 | | Green rice with chicken |
| 3894 | Chicha Morada (per glass) | Generic | PE | Beverage | L | TODO | 2026-04-07 | | Purple corn drink |
| 3896 | Tamal Colombiano (1 pc) | Generic | CO | Entree | L | TODO | 2026-04-07 | | |
| 3897 | Sopa Paraguaya (1 piece) | Generic | PY | Bread | L | TODO | 2026-04-07 | | Paraguayan corn bread |
| 3898 | Caldo de Gallina | Generic | PE | Soup | L | TODO | 2026-04-07 | | Peruvian hen soup |
| 3899 | Carne en Bistec (Colombian) | Generic | CO | Entree | L | TODO | 2026-04-07 | | |

## Section 82: African Cuisine (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 3910 | Pounded Yam (per serving) | Generic | NG | Staple | M | TODO | 2026-04-07 | | Swallow food |
| 3911 | Eba (garri, per serving) | Generic | NG | Staple | M | TODO | 2026-04-07 | | Cassava swallow |
| 3913 | Ofada Rice (per serving) | Generic | NG | Rice | M | TODO | 2026-04-07 | | Local brown rice |
| 3915 | Efo Riro (vegetable soup) | Generic | NG | Soup | M | TODO | 2026-04-07 | | Yoruba spinach stew |
| 3929 | Ethiopian Beyaynetu (veggie combo) | Generic | ET | Entree | M | TODO | 2026-04-07 | | Mixed vegetable platter |
| 3930 | Ethiopian Coffee (buna, 1 cup) | Generic | ET | Beverage | M | TODO | 2026-04-07 | | |
| 3932 | Nyama Choma (grilled beef, per 100g) | Generic | KE | Protein | M | TODO | 2026-04-07 | | Kenyan BBQ |
| 3934 | Sukuma Wiki (collard greens) | Generic | KE | Side | M | TODO | 2026-04-07 | | |
| 3937 | Githeri (per serving) | Generic | KE | Entree | L | TODO | 2026-04-07 | | Beans and corn stew |
| 3938 | Mukimo (per serving) | Generic | KE | Side | L | TODO | 2026-04-07 | | Mashed potato with corn and greens |
| 3939 | Kenyan Pilau (per serving) | Generic | KE | Rice | M | TODO | 2026-04-07 | | Spiced rice |
| 3940 | Nyama Choma (goat, per 100g) | Generic | KE | Protein | M | TODO | 2026-04-07 | | |
| 3948 | Pap (per serving) | Generic | ZA | Staple | M | TODO | 2026-04-07 | | South African maize porridge |
| 3955 | Red Red (per serving) | Generic | GH | Entree | L | TODO | 2026-04-07 | | Bean stew with plantain |
| 3957 | Light Soup (Ghanaian) | Generic | GH | Soup | L | TODO | 2026-04-07 | | Tomato-based soup |
| 3958 | Groundnut Soup (per serving) | Generic | GH | Soup | L | TODO | 2026-04-07 | | Peanut soup |
| 3960 | Yassa Poulet | Generic | SN | Entree | M | TODO | 2026-04-07 | | Lemon onion chicken |
| 3964 | Moroccan Couscous (per serving) | Generic | MA | Entree | M | TODO | 2026-04-07 | | |
| 3967 | Tanzanian Pilau | Generic | TZ | Rice | L | TODO | 2026-04-07 | | |
| 3970 | Luwombo (per serving) | Generic | UG | Entree | L | TODO | 2026-04-07 | | Steamed banana leaf stew |
| 3972 | Ewedu Soup (jute leaf) | Generic | NG | Soup | L | TODO | 2026-04-07 | | Yoruba soup |
| 3973 | Banga Soup (palm nut) | Generic | NG | Soup | L | TODO | 2026-04-07 | | |
| 3974 | Tuwo Shinkafa (rice swallow) | Generic | NG | Staple | L | TODO | 2026-04-07 | | Northern Nigerian |
| 3977 | Doro Wot with Injera (full plate) | Generic | ET | Entree | M | TODO | 2026-04-07 | | |
| 3978 | Berbere Tibs | Generic | ET | Entree | L | TODO | 2026-04-07 | | Extra spicy |
| 3980 | Genfo (Ethiopian porridge) | Generic | ET | Breakfast | L | TODO | 2026-04-07 | | |
| 3982 | Malva Pudding (1 serving) | Generic | ZA | Dessert | L | TODO | 2026-04-07 | | South African sponge cake |
| 3984 | Samp and Beans (per serving) | Generic | ZA | Side | L | TODO | 2026-04-07 | | |
| 3986 | Poulet DG | Generic | CM | Entree | L | TODO | 2026-04-07 | | Cameroonian chicken with plantain |
| 3988 | Mchuzi wa Samaki (fish curry) | Generic | TZ | Entree | L | TODO | 2026-04-07 | | Swahili coconut fish |
| 3989 | Muamba de Galinha | Generic | AO | Entree | L | TODO | 2026-04-07 | | Angolan chicken palm oil stew |
| 3990 | Cachupa (per serving) | Generic | CV | Entree | L | TODO | 2026-04-07 | | Cape Verdean corn and bean stew |
| 3993 | Wali na Maharage (rice and beans) | Generic | TZ | Entree | L | TODO | 2026-04-07 | | |
| 3994 | Fatayer (spinach, 3 pcs) | Generic | LB | Appetizer | M | TODO | 2026-04-07 | | |
| 3995 | Mkate wa Sinia (1 slice) | Generic | TZ | Bread | L | TODO | 2026-04-07 | | Swahili rice bread |
| 3996 | Mielie Bread (1 slice) | Generic | ZA | Bread | L | TODO | 2026-04-07 | | Corn bread |
| 3999 | Jolof Spaghetti | Generic | NG | Pasta | L | TODO | 2026-04-07 | | Nigerian fusion |
| 4000 | Ewa Agoyin (mashed beans with sauce) | Generic | NG | Entree | L | TODO | 2026-04-07 | | Lagos street food |

## Section 83: Southeast Asian Cuisine (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4001 | Nasi Lemak | Generic | MY | Rice | H | TODO | 2026-04-07 | | Coconut rice with sambal, egg, peanuts |
| 4002 | Char Kway Teow | Generic | MY | Noodles | H | TODO | 2026-04-07 | | Stir-fried flat noodles with shrimp |
| 4005 | Roti Canai (2 pcs) | Generic | MY | Bread | H | TODO | 2026-04-07 | | Flaky flatbread with dhal |
| 4009 | ABC (Ais Batu Campur) | Generic | MY | Dessert | M | TODO | 2026-04-07 | | Malaysian shaved ice |
| 4010 | Mee Goreng Mamak | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Indian Muslim fried noodles |
| 4011 | Nasi Goreng (Malaysian) | Generic | MY | Rice | H | TODO | 2026-04-07 | | |
| 4012 | Hokkien Mee (KL-style) | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Dark soy braised noodles |
| 4013 | Asam Laksa (Penang) | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Sour fish noodle soup |
| 4014 | Nasi Kandar (mixed rice) | Generic | MY | Rice | M | TODO | 2026-04-07 | | With curries and sides |
| 4015 | Banana Leaf Rice | Generic | MY | Rice | M | TODO | 2026-04-07 | | With curries on banana leaf |
| 4016 | Hainanese Chicken Rice (Singapore) | Generic | SG | Rice | H | TODO | 2026-04-07 | | |
| 4017 | Singapore Chilli Crab (per serving) | Generic | SG | Entree | M | TODO | 2026-04-07 | | Sweet-spicy tomato crab |
| 4019 | Kaya Toast with Eggs | Generic | SG | Breakfast | M | TODO | 2026-04-07 | | With soft-boiled eggs and coffee |
| 4021 | Hokkien Mee (Singapore) | Generic | SG | Noodles | M | TODO | 2026-04-07 | | Prawn broth noodles |
| 4022 | Bak Kut Teh (per serving) | Generic | SG | Soup | M | TODO | 2026-04-07 | | Peppery pork rib soup |
| 4023 | Char Siu Rice (Singapore) | Generic | SG | Rice | M | TODO | 2026-04-07 | | BBQ pork on rice |
| 4024 | Roti Prata (2 pcs) | Generic | SG | Bread | M | TODO | 2026-04-07 | | Singapore-style roti canai |
| 4025 | Nasi Goreng (Indonesian) | Generic | ID | Rice | H | TODO | 2026-04-07 | | With fried egg and krupuk |
| 4026 | Mie Goreng (Indonesian) | Generic | ID | Noodles | H | TODO | 2026-04-07 | | |
| 4028 | Gado-Gado | Generic | ID | Salad | M | TODO | 2026-04-07 | | Vegetables with peanut sauce |
| 4029 | Soto Ayam (chicken soup) | Generic | ID | Soup | M | TODO | 2026-04-07 | | Turmeric chicken soup |
| 4030 | Rawon (beef black nut soup) | Generic | ID | Soup | L | TODO | 2026-04-07 | | East Javanese |
| 4031 | Gudeg (per serving) | Generic | ID | Entree | L | TODO | 2026-04-07 | | Yogyakarta jackfruit stew |
| 4033 | Siomay (6 pcs) | Generic | ID | Snack | M | TODO | 2026-04-07 | | Indonesian fish dumplings |
| 4035 | Nasi Padang (mixed rice) | Generic | ID | Rice | M | TODO | 2026-04-07 | | Padang-style with rendang and sides |
| 4036 | Sate Ayam (chicken satay, 6 sticks) | Generic | ID | Appetizer | M | TODO | 2026-04-07 | | |
| 4037 | Sate Kambing (goat satay, 6 sticks) | Generic | ID | Appetizer | L | TODO | 2026-04-07 | | |
| 4038 | Nasi Uduk (coconut rice, Jakarta) | Generic | ID | Rice | M | TODO | 2026-04-07 | | |
| 4039 | Martabak Manis (1 slice) | Generic | ID | Dessert | M | TODO | 2026-04-07 | | Sweet stuffed thick pancake |
| 4040 | Martabak Telor (1 slice) | Generic | ID | Snack | M | TODO | 2026-04-07 | | Savory meat-filled pancake |
| 4041 | Ayam Goreng (Indonesian fried chicken) | Generic | ID | Entree | M | TODO | 2026-04-07 | | |
| 4042 | Ayam Penyet (smashed fried chicken) | Generic | ID | Entree | M | TODO | 2026-04-07 | | With sambal |
| 4043 | Tempeh Goreng (fried tempeh, 4 pcs) | Generic | ID | Side | M | TODO | 2026-04-07 | | |
| 4044 | Tahu Goreng (fried tofu, 4 pcs) | Generic | ID | Side | M | TODO | 2026-04-07 | | |
| 4047 | Sinigang na Baboy (pork sour soup) | Generic | PH | Soup | H | TODO | 2026-04-07 | | Tamarind-based |
| 4048 | Sinigang na Hipon (shrimp) | Generic | PH | Soup | M | TODO | 2026-04-07 | | |
| 4049 | Kare-Kare (oxtail peanut stew) | Generic | PH | Entree | M | TODO | 2026-04-07 | | |
| 4053 | Lumpia Shanghai (fried, 5 pcs) | Generic | PH | Appetizer | H | TODO | 2026-04-07 | | Filipino spring rolls |
| 4056 | Halo-Halo | Generic | PH | Dessert | H | TODO | 2026-04-07 | | Shaved ice with toppings and ube |
| 4057 | Leche Flan (1 slice) | Generic | PH | Dessert | M | TODO | 2026-04-07 | | Filipino creme caramel |
| 4064 | Ube Halaya (per serving) | Generic | PH | Dessert | M | TODO | 2026-04-07 | | Purple yam jam |
| 4066 | Pinoy Spaghetti | Generic | PH | Pasta | M | TODO | 2026-04-07 | | Filipino sweet-style |
| 4067 | Crispy Pata (per serving) | Generic | PH | Entree | M | TODO | 2026-04-07 | | Deep-fried pork knuckle |
| 4069 | Bicol Express | Generic | PH | Entree | M | TODO | 2026-04-07 | | Pork in coconut chili |
| 4072 | Com Tam Suon (broken rice, pork chop) | Generic | VN | Rice | M | TODO | 2026-04-07 | | |
| 4074 | Ca Kho To (claypot fish) | Generic | VN | Entree | M | TODO | 2026-04-07 | | Caramelized catfish |
| 4075 | Che (Vietnamese, assorted) | Generic | VN | Dessert | M | TODO | 2026-04-07 | | Sweet dessert soup |
| 4077 | Lahpet Thoke (tea leaf salad) | Generic | MM | Salad | L | TODO | 2026-04-07 | | Burmese fermented tea leaf |
| 4078 | Shan Noodles | Generic | MM | Noodles | L | TODO | 2026-04-07 | | Burmese rice noodles with tomato |
| 4079 | Fish Amok (per serving) | Generic | KH | Entree | L | TODO | 2026-04-07 | | Cambodian coconut fish curry |
| 4080 | Lok Lak (per serving) | Generic | KH | Entree | L | TODO | 2026-04-07 | | Cambodian stir-fried beef |
| 4081 | Num Pang (Cambodian sandwich) | Generic | KH | Sandwich | L | TODO | 2026-04-07 | | |
| 4082 | Khao Piak Sen (Lao noodle soup) | Generic | LA | Soup | L | TODO | 2026-04-07 | | |
| 4083 | Nasi Lemak Ayam Goreng | Generic | MY | Rice | M | TODO | 2026-04-07 | | With fried chicken |
| 4084 | Mee Rebus | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Yellow noodles in sweet potato gravy |
| 4085 | Curry Mee (Malaysian) | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Coconut curry noodle soup |
| 4086 | Wanton Mee (Malaysian) | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Dry style with char siu |
| 4087 | Teh Tarik (per glass) | Generic | MY | Beverage | M | TODO | 2026-04-07 | | Pulled milk tea |
| 4088 | Milo Dinosaur | Generic | MY | Beverage | M | TODO | 2026-04-07 | | Iced Milo with Milo powder |
| 4089 | Nasi Goreng Kampung | Generic | MY | Rice | M | TODO | 2026-04-07 | | Village-style fried rice |
| 4090 | Ayam Percik (grilled chicken) | Generic | MY | Entree | M | TODO | 2026-04-07 | | Spiced coconut grilled |
| 4093 | Chilli Pan Mee | Generic | MY | Noodles | M | TODO | 2026-04-07 | | Dry noodles with chili |
| 4094 | Claypot Chicken Rice | Generic | MY | Rice | M | TODO | 2026-04-07 | | |
| 4095 | Es Teler (per glass) | Generic | ID | Dessert | L | TODO | 2026-04-07 | | Indonesian coconut fruit drink |
| 4096 | Soto Betawi (Jakarta beef soup) | Generic | ID | Soup | L | TODO | 2026-04-07 | | Coconut milk beef soup |
| 4097 | Nasi Kuning (yellow rice) | Generic | ID | Rice | L | TODO | 2026-04-07 | | Turmeric coconut rice |
| 4098 | Pempek (fish cake, 4 pcs) | Generic | ID | Snack | L | TODO | 2026-04-07 | | Palembang specialty |
| 4100 | Lontong Sayur | Generic | ID | Rice | L | TODO | 2026-04-07 | | Rice cake in coconut vegetable curry |

## Section 84: European Cuisine Expanded (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4105 | Croque Madame | Generic | FR | Sandwich | M | TODO | 2026-04-07 | | Croque monsieur with fried egg |
| 4107 | Cassoulet | Generic | FR | Entree | L | TODO | 2026-04-07 | | Bean and meat casserole |
| 4109 | Steak Frites | Generic | FR | Entree | H | TODO | 2026-04-07 | | Steak with French fries |
| 4110 | Soupe a l'Oignon | Generic | FR | Soup | M | TODO | 2026-04-07 | | French onion soup with gruyere |
| 4111 | Tarte Tatin (1 slice) | Generic | FR | Dessert | M | TODO | 2026-04-07 | | Upside-down apple tart |
| 4123 | Pate (per serving) | Generic | FR | Appetizer | L | TODO | 2026-04-07 | | |
| 4126 | Macaron (1 pc) | Generic | FR | Dessert | M | TODO | 2026-04-07 | | |
| 4127 | Paella Valenciana | Generic | ES | Entree | H | TODO | 2026-04-07 | | With rabbit and snails |
| 4128 | Paella de Mariscos (seafood) | Generic | ES | Entree | H | TODO | 2026-04-07 | | |
| 4132 | Croquetas de Jamon (4 pcs) | Generic | ES | Appetizer | M | TODO | 2026-04-07 | | Ham croquettes |
| 4134 | Pulpo a la Gallega | Generic | ES | Appetizer | M | TODO | 2026-04-07 | | Galician-style octopus |
| 4135 | Pintxos (3 pcs assorted) | Generic | ES | Appetizer | M | TODO | 2026-04-07 | | Basque bar snacks |
| 4136 | Sangria (per glass) | Generic | ES | Alcohol | M | TODO | 2026-04-07 | | |
| 4137 | Tinto de Verano (per glass) | Generic | ES | Alcohol | M | TODO | 2026-04-07 | | Red wine and lemon soda |
| 4138 | Churros con Chocolate | Generic | ES | Dessert | M | TODO | 2026-04-07 | | Spanish dipping chocolate |
| 4139 | Jamon Iberico (per 50g) | Generic | ES | Appetizer | M | TODO | 2026-04-07 | | |
| 4140 | Pan con Tomate | Generic | ES | Bread | M | TODO | 2026-04-07 | | Bread with tomato |
| 4143 | Chicken Schnitzel | Generic | DE | Entree | M | TODO | 2026-04-07 | | |
| 4148 | Leberkase (1 slice) | Generic | DE | Entree | L | TODO | 2026-04-07 | | Bavarian meatloaf |
| 4156 | Weisswurst (2 pcs) | Generic | DE | Breakfast | L | TODO | 2026-04-07 | | Bavarian white sausage |
| 4157 | Schwarzwalder Kirschtorte (1 slice) | Generic | DE | Dessert | M | TODO | 2026-04-07 | | Black Forest cake |
| 4160 | Cottage Pie | Generic | GB | Entree | M | TODO | 2026-04-07 | | Beef mince with mashed potato |
| 4163 | Sunday Roast (beef) | Generic | GB | Entree | M | TODO | 2026-04-07 | | With Yorkshire pudding |
| 4164 | Toad in the Hole | Generic | GB | Entree | L | TODO | 2026-04-07 | | Sausages in Yorkshire pudding batter |
| 4169 | Eton Mess | Generic | GB | Dessert | L | TODO | 2026-04-07 | | Meringue, cream, strawberry |
| 4170 | Treacle Tart (1 slice) | Generic | GB | Dessert | L | TODO | 2026-04-07 | | |
| 4171 | Ploughman's Lunch | Generic | GB | Entree | L | TODO | 2026-04-07 | | Cheese, pickle, bread, salad |
| 4172 | Chip Butty | Generic | GB | Sandwich | L | TODO | 2026-04-07 | | French fry sandwich |
| 4173 | Beans on Toast | Generic | GB | Breakfast | M | TODO | 2026-04-07 | | |
| 4174 | Bitterballen (6 pcs) | Generic | NL | Appetizer | M | TODO | 2026-04-07 | | Dutch meat croquettes |
| 4177 | Erwtensoep (per bowl) | Generic | NL | Soup | L | TODO | 2026-04-07 | | Dutch split pea soup |
| 4179 | Oliebollen (2 pcs) | Generic | NL | Dessert | L | TODO | 2026-04-07 | | Dutch donuts |
| 4181 | Swedish Meatballs (8 pcs with sauce) | Generic | SE | Entree | M | TODO | 2026-04-07 | | With lingonberry |
| 4183 | Smørrebrød (open-faced sandwich, 1 pc) | Generic | DK | Sandwich | M | TODO | 2026-04-07 | | Danish open sandwich |
| 4187 | Pierogi (6 pcs, potato and cheese) | Generic | PL | Entree | M | TODO | 2026-04-07 | | |
| 4188 | Pierogi (6 pcs, meat) | Generic | PL | Entree | M | TODO | 2026-04-07 | | |
| 4192 | Chicken Kiev | Generic | UA | Entree | M | TODO | 2026-04-07 | | Butter-stuffed breaded chicken |

## Section 85: American Regional & Classic Dishes (150 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4201 | Southern Fried Chicken (2 pcs) | Generic | US | Entree | H | TODO | 2026-04-07 | | Bone-in breast and thigh |
| 4202 | Biscuits and Gravy | Generic | US | Breakfast | H | TODO | 2026-04-07 | | With sausage gravy |
| 4203 | Shrimp and Grits | Generic | US | Entree | M | TODO | 2026-04-07 | | Lowcountry classic |
| 4204 | Collard Greens (per serving) | Generic | US | Side | M | TODO | 2026-04-07 | | Slow-cooked with ham hock |
| 4206 | Fried Catfish (per fillet) | Generic | US | Entree | M | TODO | 2026-04-07 | | Cornmeal-crusted |
| 4207 | Hush Puppies (5 pcs) | Generic | US | Side | M | TODO | 2026-04-07 | | Fried cornmeal balls |
| 4210 | Jambalaya (per serving) | Generic | US | Rice | M | TODO | 2026-04-07 | | Cajun rice dish |
| 4211 | Crawfish Boil (per 1 lb) | Generic | US | Entree | M | TODO | 2026-04-07 | | |
| 4212 | Peach Cobbler | Generic | US | Dessert | M | TODO | 2026-04-07 | | |
| 4213 | Banana Pudding | Generic | US | Dessert | M | TODO | 2026-04-07 | | Southern-style with vanilla wafers |
| 4214 | Sweet Tea (per glass) | Generic | US | Beverage | H | TODO | 2026-04-07 | | |
| 4216 | Red Beans and Rice | Generic | US | Entree | M | TODO | 2026-04-07 | | With andouille sausage |
| 4217 | Hoppin' John | Generic | US | Entree | L | TODO | 2026-04-07 | | Black-eyed peas and rice |
| 4218 | Shrimp Po'Boy | Generic | US | Sandwich | M | TODO | 2026-04-07 | | New Orleans fried shrimp sub |
| 4219 | Oyster Po'Boy | Generic | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4220 | Muffuletta (half) | Generic | US | Sandwich | M | TODO | 2026-04-07 | | New Orleans olive salad sandwich |
| 4221 | Chicken and Waffles | Generic | US | Breakfast | H | TODO | 2026-04-07 | | |
| 4222 | Country Fried Steak | Generic | US | Entree | M | TODO | 2026-04-07 | | Breaded steak with white gravy |
| 4223 | Fried Okra (per serving) | Generic | US | Side | M | TODO | 2026-04-07 | | |
| 4225 | Chicken Fried Chicken | Generic | US | Entree | M | TODO | 2026-04-07 | | |
| 4226 | Fajitas (chicken, per serving) | Generic | US | Entree | H | TODO | 2026-04-07 | | Tex-Mex with peppers and onions |
| 4227 | Fajitas (steak, per serving) | Generic | US | Entree | H | TODO | 2026-04-07 | | |
| 4228 | Queso Dip (per serving) | Generic | US | Appetizer | H | TODO | 2026-04-07 | | Tex-Mex cheese dip |
| 4230 | Breakfast Tacos (egg and bacon, 2 pcs) | Generic | US | Breakfast | H | TODO | 2026-04-07 | | Austin-style |
| 4231 | Breakfast Tacos (egg and chorizo, 2 pcs) | Generic | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4232 | Migas (Tex-Mex) | Generic | US | Breakfast | M | TODO | 2026-04-07 | | Eggs with tortilla chips |
| 4233 | Chimichanga (beef) | Generic | US | Entree | M | TODO | 2026-04-07 | | Deep-fried burrito |
| 4234 | Taquitos (beef, 5 pcs) | Generic | US | Snack | M | TODO | 2026-04-07 | | Rolled tortillas fried |
| 4235 | Sopapillas (3 pcs) | Generic | US | Dessert | M | TODO | 2026-04-07 | | Fried dough with honey |
| 4238 | Lobster Roll (Connecticut, hot butter) | Generic | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4239 | Lobster Roll (Maine, cold mayo) | Generic | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4241 | New York Style Pizza (1 slice) | Generic | US | Pizza | H | TODO | 2026-04-07 | | Thin, foldable |
| 4242 | New York Style Pizza (whole 18 inch) | Generic | US | Pizza | H | TODO | 2026-04-07 | | |
| 4244 | Bagel with Lox | Generic | US | Breakfast | M | TODO | 2026-04-07 | | Smoked salmon, cream cheese, capers |
| 4245 | Everything Bagel | Generic | US | Bread | H | TODO | 2026-04-07 | | |
| 4246 | Black and White Cookie (1 pc) | Generic | US | Dessert | M | TODO | 2026-04-07 | | New York classic |
| 4247 | Pastrami Sandwich (Katz's style) | Generic | US | Sandwich | M | TODO | 2026-04-07 | | On rye with mustard |
| 4248 | Egg Cream (per glass) | Generic | US | Beverage | L | TODO | 2026-04-07 | | NYC chocolate soda |
| 4249 | New York Cheesecake (1 slice) | Generic | US | Dessert | H | TODO | 2026-04-07 | | |
| 4251 | Chicago Deep Dish Pizza (1 slice) | Generic | US | Pizza | H | TODO | 2026-04-07 | | |
| 4252 | Hot Dish (Minnesota tater tot) | Generic | US | Entree | M | TODO | 2026-04-07 | | Tater tot casserole |
| 4253 | Cheese Curds (fried, per serving) | Generic | US | Appetizer | M | TODO | 2026-04-07 | | Wisconsin classic |
| 4254 | Bratwurst in a Bun | Generic | US | Sandwich | M | TODO | 2026-04-07 | | Wisconsin-style |
| 4255 | Tavern-Style Pizza (1 slice) | Generic | US | Pizza | M | TODO | 2026-04-07 | | Chicago thin cut in squares |
| 4256 | Butter Burger | Generic | US | Sandwich | M | TODO | 2026-04-07 | | Wisconsin-style |
| 4257 | Cincinnati Chili (3-way) | Generic | US | Entree | M | TODO | 2026-04-07 | | Chili, spaghetti, cheese |
| 4258 | St. Louis Ribs (half rack) | Generic | US | Entree | M | TODO | 2026-04-07 | | |
| 4259 | Kansas City BBQ Burnt Ends | Generic | US | Entree | M | TODO | 2026-04-07 | | |
| 4260 | California Burrito | Generic | US | Entree | M | TODO | 2026-04-07 | | With fries inside |
| 4261 | Fish Tacos (Baja-style, 3 pcs) | Generic | US | Tacos | M | TODO | 2026-04-07 | | San Diego style |
| 4263 | Mission-Style Burrito | Generic | US | Entree | H | TODO | 2026-04-07 | | SF-style with rice and beans |
| 4265 | Cioppino | Generic | US | Soup | L | TODO | 2026-04-07 | | SF Italian-American fish stew |
| 4266 | In-N-Out Animal Style Fries | In-N-Out | US | Side | H | TODO | 2026-04-07 | | |
| 4267 | Texas Brisket (per 100g) | Generic | US | BBQ | H | TODO | 2026-04-07 | | Smoked low and slow |
| 4269 | Memphis Dry Rub Ribs (half rack) | Generic | US | BBQ | M | TODO | 2026-04-07 | | |
| 4270 | Alabama White Sauce Chicken | Generic | US | BBQ | M | TODO | 2026-04-07 | | Mayo-vinegar sauce |
| 4271 | KC Burnt Ends (per serving) | Generic | US | BBQ | M | TODO | 2026-04-07 | | |
| 4272 | BBQ Brisket Sandwich | Generic | US | Sandwich | H | TODO | 2026-04-07 | | |
| 4274 | Smoked Sausage Link | Generic | US | BBQ | M | TODO | 2026-04-07 | | Texas-style |
| 4275 | BBQ Ribs (baby back, half rack) | Generic | US | BBQ | H | TODO | 2026-04-07 | | |
| 4282 | Plate Lunch (chicken katsu) | Generic | US | Entree | M | TODO | 2026-04-07 | | Hawaiian with mac salad |
| 4283 | Kalua Pig (per serving) | Generic | US | Protein | M | TODO | 2026-04-07 | | |
| 4285 | Shave Ice (Hawaiian) | Generic | US | Dessert | M | TODO | 2026-04-07 | | With azuki bean and mochi |
| 4292 | Tuna Casserole | Generic | US | Entree | M | TODO | 2026-04-07 | | With egg noodles |
| 4294 | Salisbury Steak | Generic | US | Entree | M | TODO | 2026-04-07 | | With mushroom gravy |
| 4297 | Corndog (1 pc) | Generic | US | Snack | M | TODO | 2026-04-07 | | |
| 4303 | Wedge Salad | Generic | US | Salad | M | TODO | 2026-04-07 | | Iceberg with blue cheese and bacon |
| 4304 | Buffalo Wings (10 pcs) | Generic | US | Appetizer | H | TODO | 2026-04-07 | | With blue cheese dip |
| 4305 | Boneless Wings (10 pcs) | Generic | US | Appetizer | H | TODO | 2026-04-07 | | |
| 4306 | Mozzarella Sticks (6 pcs) | Generic | US | Appetizer | H | TODO | 2026-04-07 | | |
| 4308 | Jalapeño Poppers (6 pcs) | Generic | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4309 | Fried Pickles (per serving) | Generic | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4310 | Bloomin' Onion | Generic | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4316 | Patty Melt | Generic | US | Sandwich | M | TODO | 2026-04-07 | | Burger on rye with onions |
| 4319 | Chicago Hot Dog | Generic | US | Sandwich | M | TODO | 2026-04-07 | | With all the fixings |
| 4320 | Chili Dog | Generic | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4321 | Coney Island Dog | Generic | US | Sandwich | M | TODO | 2026-04-07 | | Detroit-style |
| 4322 | Philly Roast Pork Sandwich | Generic | US | Sandwich | M | TODO | 2026-04-07 | | With broccoli rabe and provolone |
| 4323 | Fried Chicken Sandwich (Nashville Hot) | Generic | US | Sandwich | H | TODO | 2026-04-07 | | |
| 4324 | Nashville Hot Chicken (2 pcs) | Generic | US | Entree | H | TODO | 2026-04-07 | | |
| 4326 | Fried Chicken Biscuit | Generic | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4340 | S'more (1 pc) | Generic | US | Dessert | M | TODO | 2026-04-07 | | |
| 4341 | Funnel Cake | Generic | US | Dessert | M | TODO | 2026-04-07 | | Fair food |
| 4342 | Bread Pudding (per serving) | Generic | US | Dessert | M | TODO | 2026-04-07 | | |
| 4345 | German Chocolate Cake (1 slice) | Generic | US | Dessert | M | TODO | 2026-04-07 | | |
| 4346 | Lemon Meringue Pie (1 slice) | Generic | US | Dessert | M | TODO | 2026-04-07 | | |
| 4348 | Etouffee (crawfish) | Generic | US | Entree | M | TODO | 2026-04-07 | | |
| 4349 | Boudin (1 link) | Generic | US | Entree | L | TODO | 2026-04-07 | | Cajun rice sausage |
| 4350 | Andouille Sausage (1 link) | Generic | US | Protein | M | TODO | 2026-04-07 | | |

## Section 86: Trader Joe's Specific Products (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4352 | Cauliflower Gnocchi | Trader Joe's | US | Frozen Side | H | TODO | 2026-04-07 | | |
| 4354 | Unexpected Cheddar (per 1 oz) | Trader Joe's | US | Cheese | H | TODO | 2026-04-07 | | |
| 4355 | Gone Bananas (5 pcs) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | Chocolate covered banana |
| 4357 | Elote Corn Chip Dippers (per serving) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 4359 | Spatchcocked Chicken (per 4 oz) | Trader Joe's | US | Protein | M | TODO | 2026-04-07 | | |
| 4360 | Palak Paneer (1 package) | Trader Joe's | US | Frozen Entree | M | TODO | 2026-04-07 | | |
| 4362 | Gyoza Potstickers (7 pcs) | Trader Joe's | US | Frozen Appetizer | H | TODO | 2026-04-07 | | |
| 4363 | Turkey Corn Dogs (1 pc) | Trader Joe's | US | Frozen Entree | M | TODO | 2026-04-07 | | |
| 4364 | Mini Ice Cream Cones (4 pcs) | Trader Joe's | US | Dessert | M | TODO | 2026-04-07 | | Hold The Cone |
| 4365 | Mochi Ice Cream (1 pc) | Trader Joe's | US | Dessert | M | TODO | 2026-04-07 | | |
| 4366 | Peanut Butter Filled Pretzels (per serving) | Trader Joe's | US | Snack | H | TODO | 2026-04-07 | | |
| 4368 | Cauliflower Pizza Crust (1/3 crust) | Trader Joe's | US | Frozen | M | TODO | 2026-04-07 | | |
| 4369 | Shawarma Chicken Thighs (per 4 oz) | Trader Joe's | US | Frozen Protein | M | TODO | 2026-04-07 | | |
| 4373 | Everything But The Bagel Seasoning (per tsp) | Trader Joe's | US | Seasoning | H | TODO | 2026-04-07 | | |
| 4375 | Frozen Chocolate Croissants (1 pc baked) | Trader Joe's | US | Bakery | M | TODO | 2026-04-07 | | |
| 4377 | Joe-Joe's Cookies (2 pcs) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 4378 | Cowboy Bark (per serving) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 4379 | Soy Chorizo (per 2.5 oz) | Trader Joe's | US | Protein | M | TODO | 2026-04-07 | | Plant-based |
| 4380 | Thai Banana Fritters (4 pcs) | Trader Joe's | US | Frozen Snack | L | TODO | 2026-04-07 | | |
| 4383 | Mini Brie Bites (4 pcs) | Trader Joe's | US | Cheese | M | TODO | 2026-04-07 | | |
| 4384 | Thai Vegetable Gyoza (7 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 4388 | Sublime Ice Cream Sandwiches (1 pc) | Trader Joe's | US | Dessert | M | TODO | 2026-04-07 | | |
| 4389 | Bibimbap Bowl (1 package) | Trader Joe's | US | Frozen Entree | M | TODO | 2026-04-07 | | |
| 4391 | Chicken Soup Dumplings (6 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 4392 | Crunchy Peanut Butter (per 2 tbsp) | Trader Joe's | US | Spread | M | TODO | 2026-04-07 | | |
| 4393 | Triple Ginger Snaps (5 pcs) | Trader Joe's | US | Snack | L | TODO | 2026-04-07 | | |
| 4396 | Organic Ezekiel Bread (1 slice) | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 4397 | Cashew Fiesta Dip (per 2 tbsp) | Trader Joe's | US | Dip | L | TODO | 2026-04-07 | | |
| 4398 | Green Goddess Salad Dressing (per 2 tbsp) | Trader Joe's | US | Condiment | M | TODO | 2026-04-07 | | |
| 4399 | Cheese Crunchies (per serving) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 4401 | Thai Coconut Curry Simmer Sauce (per 1/4 cup) | Trader Joe's | US | Sauce | L | TODO | 2026-04-07 | | |
| 4403 | Garlic Naan (1 pc) | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 4404 | Vanilla Bean Greek Yogurt (per 6 oz) | Trader Joe's | US | Dairy | M | TODO | 2026-04-07 | | |
| 4405 | Krispy Rice Treat (1 bar) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | Chocolate drizzled |
| 4406 | Banana Bread Mix (prepared, per slice) | Trader Joe's | US | Bakery | L | TODO | 2026-04-07 | | |
| 4409 | Chocolate Lava Cake (1 pc) | Trader Joe's | US | Dessert | M | TODO | 2026-04-07 | | |
| 4411 | Mixed Nut Butter (per 2 tbsp) | Trader Joe's | US | Spread | L | TODO | 2026-04-07 | | |
| 4412 | Chicken Shawarma (per 3 oz) | Trader Joe's | US | Frozen Protein | M | TODO | 2026-04-07 | | |
| 4413 | Bambino Pizza Formaggio (1 pc) | Trader Joe's | US | Frozen Pizza | M | TODO | 2026-04-07 | | Mini cheese pizza |
| 4414 | Tarte aux Champignons (1/4 tart) | Trader Joe's | US | Frozen Entree | L | TODO | 2026-04-07 | | Mushroom tart |
| 4415 | Cornbread Crisps (per serving) | Trader Joe's | US | Snack | L | TODO | 2026-04-07 | | |
| 4416 | Steamed Chicken Soup Dumplings (6 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 4417 | Chicken Quesadilla (1 half) | Trader Joe's | US | Frozen Entree | M | TODO | 2026-04-07 | | |
| 4419 | Everything Ciabatta Rolls (1 roll) | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 4420 | Za'atar Pita Crackers (per serving) | Trader Joe's | US | Snack | L | TODO | 2026-04-07 | | |
| 4421 | Chile Lime Chicken Burgers (1 patty) | Trader Joe's | US | Frozen Protein | M | TODO | 2026-04-07 | | |
| 4422 | Argentinian Red Shrimp (per 4 oz) | Trader Joe's | US | Frozen Protein | M | TODO | 2026-04-07 | | |
| 4423 | Frozen Açaí Puree (1 packet) | Trader Joe's | US | Frozen | M | TODO | 2026-04-07 | | |
| 4425 | Riced Cauliflower (per 1 cup) | Trader Joe's | US | Frozen Vegetable | M | TODO | 2026-04-07 | | |
| 4427 | Everything Croissant Rolls (1 pc baked) | Trader Joe's | US | Bakery | M | TODO | 2026-04-07 | | |
| 4428 | Greek Chickpeas (per 1/2 cup) | Trader Joe's | US | Side | L | TODO | 2026-04-07 | | |
| 4429 | Chicken Cilantro Mini Wontons (7 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 4431 | Scandinavian Swimmers (per serving) | Trader Joe's | US | Snack | L | TODO | 2026-04-07 | | Gummy candies |
| 4433 | Sriracha Baked Tofu (per 3 oz) | Trader Joe's | US | Protein | M | TODO | 2026-04-07 | | |
| 4434 | Korean Beefless Bulgogi (per 1 cup) | Trader Joe's | US | Frozen Entree | L | TODO | 2026-04-07 | | Plant-based |
| 4435 | Organic Super Greens (per 3 cups) | Trader Joe's | US | Produce | M | TODO | 2026-04-07 | | Kale, chard, spinach mix |
| 4436 | Chili Onion Crunch (per tsp) | Trader Joe's | US | Condiment | M | TODO | 2026-04-07 | | |
| 4437 | Turkey Bolognese (per 1/2 cup) | Trader Joe's | US | Sauce | M | TODO | 2026-04-07 | | |
| 4439 | Chimichurri Rice (1 cup) | Trader Joe's | US | Frozen Side | L | TODO | 2026-04-07 | | |
| 4440 | Chocolate Hummus (per 2 tbsp) | Trader Joe's | US | Dip | L | TODO | 2026-04-07 | | |
| 4441 | Chicken Gyoza (7 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 4442 | Protein Patties (plant-based, 1 patty) | Trader Joe's | US | Frozen Protein | M | TODO | 2026-04-07 | | |
| 4444 | Danish Kringle (1/8 ring) | Trader Joe's | US | Bakery | M | TODO | 2026-04-07 | | |
| 4445 | Soft Baked Peanut Butter Cookies (1 pc) | Trader Joe's | US | Snack | M | TODO | 2026-04-07 | | |
| 4446 | Organic Açaí Bowl (1 bowl) | Trader Joe's | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 4447 | Chicken Tikka Samosa (2 pcs) | Trader Joe's | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 4448 | Umami Seasoning Blend (per tsp) | Trader Joe's | US | Seasoning | L | TODO | 2026-04-07 | | |
| 4449 | Lemon Ricotta Ravioli (1 cup) | Trader Joe's | US | Frozen Pasta | M | TODO | 2026-04-07 | | |

## Section 87: Costco/Kirkland Products (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4454 | Kirkland Organic Eggs (1 large egg) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 4458 | Kirkland Wild Salmon (per 4 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 4461 | Costco Food Court Chicken Bake (1 pc) | Costco/Kirkland | US | Entree | H | TODO | 2026-04-07 | | |
| 4462 | Costco Food Court Pizza (1 slice) | Costco/Kirkland | US | Pizza | H | TODO | 2026-04-07 | | Cheese or pepperoni |
| 4463 | Costco Food Court Hot Dog (1 pc) | Costco/Kirkland | US | Entree | H | TODO | 2026-04-07 | | With soda |
| 4466 | Costco Croissants (1 pc) | Costco/Kirkland | US | Bakery | H | TODO | 2026-04-07 | | Butter croissant |
| 4469 | Costco Sheet Cake (1 slice) | Costco/Kirkland | US | Dessert | M | TODO | 2026-04-07 | | White or chocolate |
| 4475 | Kirkland Organic Peanut Butter (per 2 tbsp) | Costco/Kirkland | US | Spread | M | TODO | 2026-04-07 | | |
| 4480 | Kirkland Ground Beef 85/15 (per 4 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 4481 | Kirkland Frozen Berries Mix (per 1 cup) | Costco/Kirkland | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 4482 | Kirkland Frozen Mango (per 1 cup) | Costco/Kirkland | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 4486 | Costco Food Court Churro (1 pc) | Costco/Kirkland | US | Dessert | M | TODO | 2026-04-07 | | |
| 4487 | Costco Food Court Chocolate Frozen Yogurt | Costco/Kirkland | US | Dessert | M | TODO | 2026-04-07 | | |
| 4488 | Kirkland Smoked Salmon (per 2 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 4491 | Costco Chicken Wings (per 4 wings) | Costco/Kirkland | US | Deli | M | TODO | 2026-04-07 | | |
| 4494 | Kirkland Breakfast Sausage (2 patties) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 4496 | Kirkland Mini Chocolate Chip Cookies (4 pcs) | Costco/Kirkland | US | Snack | M | TODO | 2026-04-07 | | |
| 4497 | Kirkland Organic Tortillas (1 large) | Costco/Kirkland | US | Bread | M | TODO | 2026-04-07 | | |
| 4498 | Kirkland Quinoa Salad (per 1 cup) | Costco/Kirkland | US | Deli | M | TODO | 2026-04-07 | | |
| 4499 | Costco Bulgogi Beef (per 4 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 4500 | Kirkland Organic Chicken Stock (per 1 cup) | Costco/Kirkland | US | Soup | L | TODO | 2026-04-07 | | |
| 4501 | Costco Chocolate Chip Cookies (1 pc) | Costco/Kirkland | US | Bakery | M | TODO | 2026-04-07 | | |
| 4502 | Costco Cinnamon Pull-Apart (1 piece) | Costco/Kirkland | US | Bakery | M | TODO | 2026-04-07 | | |
| 4505 | Costco Food Court Mocha Freeze | Costco/Kirkland | US | Beverage | M | TODO | 2026-04-07 | | |
| 4507 | Kirkland Organic Milk (per 1 cup) | Costco/Kirkland | US | Dairy | M | TODO | 2026-04-07 | | |
| 4508 | Costco Lobster Ravioli (per 1 cup) | Costco/Kirkland | US | Deli | M | TODO | 2026-04-07 | | |
| 4509 | Kirkland Marinated Artichoke Hearts (per 1/4 cup) | Costco/Kirkland | US | Side | L | TODO | 2026-04-07 | | |
| 4510 | Costco Korean BBQ Short Ribs (per 4 oz) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 4511 | Kirkland Frozen Stir-Fry Vegetables (per 1 cup) | Costco/Kirkland | US | Frozen Vegetable | M | TODO | 2026-04-07 | | |
| 4512 | Kirkland Chocolate Almonds (per 1/4 cup) | Costco/Kirkland | US | Snack | M | TODO | 2026-04-07 | | |
| 4514 | Kirkland Frozen Chicken Pot Stickers (7 pcs) | Costco/Kirkland | US | Frozen Appetizer | M | TODO | 2026-04-07 | | |
| 4515 | Kirkland Organic Eggs (hard boiled, 2 pcs) | Costco/Kirkland | US | Protein | M | TODO | 2026-04-07 | | |
| 4517 | Kirkland Bagels (1 pc) | Costco/Kirkland | US | Bakery | M | TODO | 2026-04-07 | | |
| 4521 | Costco Food Court Combo Pizza (1 slice) | Costco/Kirkland | US | Pizza | M | TODO | 2026-04-07 | | |
| 4524 | Costco Brownie Bar (1 bar) | Costco/Kirkland | US | Dessert | M | TODO | 2026-04-07 | | |
| 4527 | Kirkland Lamb Rack (per 4 oz) | Costco/Kirkland | US | Protein | L | TODO | 2026-04-07 | | |
| 4528 | Costco Shrimp Cocktail (per 3 oz shrimp) | Costco/Kirkland | US | Appetizer | M | TODO | 2026-04-07 | | |

## Section 88: More Fast Food Complete Menus (200 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4531 | Egg McMuffin | McDonald's | US | Breakfast | H | TODO | 2026-04-07 | | |
| 4532 | Sausage McMuffin with Egg | McDonald's | US | Breakfast | H | TODO | 2026-04-07 | | |
| 4533 | Sausage McGriddle | McDonald's | US | Breakfast | H | TODO | 2026-04-07 | | |
| 4534 | Bacon Egg & Cheese McGriddle | McDonald's | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4535 | Hash Brown (1 pc) | McDonald's | US | Breakfast | H | TODO | 2026-04-07 | | |
| 4537 | Sausage Burrito | McDonald's | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4538 | Big Mac | McDonald's | US | Burger | H | TODO | 2026-04-07 | | |
| 4539 | Quarter Pounder with Cheese | McDonald's | US | Burger | H | TODO | 2026-04-07 | | |
| 4540 | Double Quarter Pounder with Cheese | McDonald's | US | Burger | H | TODO | 2026-04-07 | | |
| 4542 | Crispy Chicken Sandwich | McDonald's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4543 | Filet-O-Fish | McDonald's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4544 | 10-piece McNuggets | McDonald's | US | Entree | H | TODO | 2026-04-07 | | |
| 4545 | 20-piece McNuggets | McDonald's | US | Entree | M | TODO | 2026-04-07 | | |
| 4546 | McFlurry (Oreo, regular) | McDonald's | US | Dessert | H | TODO | 2026-04-07 | | |
| 4547 | McFlurry (M&M, regular) | McDonald's | US | Dessert | M | TODO | 2026-04-07 | | |
| 4549 | Large Fries | McDonald's | US | Side | H | TODO | 2026-04-07 | | |
| 4550 | Medium Fries | McDonald's | US | Side | H | TODO | 2026-04-07 | | |
| 4551 | Vanilla Cone | McDonald's | US | Dessert | M | TODO | 2026-04-07 | | |
| 4552 | Chocolate Shake (medium) | McDonald's | US | Beverage | M | TODO | 2026-04-07 | | |
| 4553 | Dave's Single | Wendy's | US | Burger | H | TODO | 2026-04-07 | | |
| 4554 | Dave's Double | Wendy's | US | Burger | H | TODO | 2026-04-07 | | |
| 4556 | Spicy Chicken Sandwich | Wendy's | US | Sandwich | H | TODO | 2026-04-07 | | |
| 4557 | Jr. Bacon Cheeseburger | Wendy's | US | Burger | H | TODO | 2026-04-07 | | |
| 4558 | Classic Chicken Sandwich | Wendy's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4559 | Chocolate Frosty (small) | Wendy's | US | Dessert | H | TODO | 2026-04-07 | | |
| 4560 | Vanilla Frosty (small) | Wendy's | US | Dessert | M | TODO | 2026-04-07 | | |
| 4564 | 10-piece Nuggets | Wendy's | US | Entree | M | TODO | 2026-04-07 | | |
| 4565 | Apple Pecan Salad (full) | Wendy's | US | Salad | M | TODO | 2026-04-07 | | |
| 4566 | Crunchwrap Supreme | Taco Bell | US | Entree | H | TODO | 2026-04-07 | | |
| 4567 | Mexican Pizza | Taco Bell | US | Entree | H | TODO | 2026-04-07 | | |
| 4568 | Cheesy Gordita Crunch | Taco Bell | US | Entree | H | TODO | 2026-04-07 | | |
| 4569 | Chalupa Supreme (beef) | Taco Bell | US | Entree | M | TODO | 2026-04-07 | | |
| 4570 | Baja Blast (large) | Taco Bell | US | Beverage | H | TODO | 2026-04-07 | | Mountain Dew Baja Blast |
| 4571 | Doritos Locos Taco (1 pc) | Taco Bell | US | Taco | H | TODO | 2026-04-07 | | |
| 4572 | Crunchy Taco (1 pc) | Taco Bell | US | Taco | H | TODO | 2026-04-07 | | |
| 4573 | Soft Taco (beef, 1 pc) | Taco Bell | US | Taco | H | TODO | 2026-04-07 | | |
| 4574 | Bean Burrito | Taco Bell | US | Entree | M | TODO | 2026-04-07 | | |
| 4576 | Nachos BellGrande | Taco Bell | US | Entree | M | TODO | 2026-04-07 | | |
| 4577 | Chicken Quesadilla | Taco Bell | US | Entree | M | TODO | 2026-04-07 | | |
| 4578 | Burrito Supreme (beef) | Taco Bell | US | Entree | M | TODO | 2026-04-07 | | |
| 4579 | Cinnamon Twists | Taco Bell | US | Dessert | M | TODO | 2026-04-07 | | |
| 4580 | Cheesy Bean and Rice Burrito | Taco Bell | US | Entree | M | TODO | 2026-04-07 | | |
| 4582 | Whopper with Cheese | Burger King | US | Burger | H | TODO | 2026-04-07 | | |
| 4583 | Double Whopper | Burger King | US | Burger | M | TODO | 2026-04-07 | | |
| 4584 | Impossible Whopper | Burger King | US | Burger | M | TODO | 2026-04-07 | | Plant-based |
| 4585 | Original Chicken Sandwich | Burger King | US | Sandwich | M | TODO | 2026-04-07 | | Ch'King |
| 4586 | Chicken Fries (9 pcs) | Burger King | US | Snack | M | TODO | 2026-04-07 | | |
| 4588 | Hershey's Pie (1 slice) | Burger King | US | Dessert | M | TODO | 2026-04-07 | | |
| 4589 | Chick-fil-A Original Sandwich | Chick-fil-A | US | Sandwich | H | TODO | 2026-04-07 | | |
| 4590 | Chick-fil-A Spicy Sandwich | Chick-fil-A | US | Sandwich | H | TODO | 2026-04-07 | | |
| 4593 | Chick-fil-A 8-count Nuggets | Chick-fil-A | US | Entree | H | TODO | 2026-04-07 | | |
| 4594 | Chick-fil-A 12-count Nuggets | Chick-fil-A | US | Entree | M | TODO | 2026-04-07 | | |
| 4595 | Chick-fil-A Grilled Nuggets (8-count) | Chick-fil-A | US | Entree | M | TODO | 2026-04-07 | | |
| 4596 | Chick-fil-A Waffle Fries (medium) | Chick-fil-A | US | Side | H | TODO | 2026-04-07 | | |
| 4597 | Chick-fil-A Waffle Fries (large) | Chick-fil-A | US | Side | M | TODO | 2026-04-07 | | |
| 4601 | Chick-fil-A Chicken Mini (4-count) | Chick-fil-A | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4604 | Chick-fil-A Chicken Wrap | Chick-fil-A | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4605 | Beef 'n Cheddar (classic) | Arby's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4606 | Classic Roast Beef | Arby's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4607 | Curly Fries (medium) | Arby's | US | Side | M | TODO | 2026-04-07 | | |
| 4608 | Jamocha Shake (medium) | Arby's | US | Beverage | M | TODO | 2026-04-07 | | |
| 4609 | Mozzarella Sticks (4 pcs) | Arby's | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4610 | Chicken Bacon Swiss | Arby's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4611 | Sonic Blast (Oreo, medium) | Sonic | US | Dessert | M | TODO | 2026-04-07 | | |
| 4612 | Chili Cheese Coney | Sonic | US | Entree | M | TODO | 2026-04-07 | | |
| 4613 | Ocean Water (large) | Sonic | US | Beverage | M | TODO | 2026-04-07 | | Coconut Sprite |
| 4615 | Mozzarella Sticks (Sonic, 5 pcs) | Sonic | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4616 | Cherry Limeade (medium) | Sonic | US | Beverage | M | TODO | 2026-04-07 | | |
| 4617 | Patty Melt | Whataburger | US | Burger | M | TODO | 2026-04-07 | | |
| 4620 | Spicy Ketchup Fries (medium) | Whataburger | US | Side | L | TODO | 2026-04-07 | | |
| 4621 | Jumbo Jack | Jack in the Box | US | Burger | M | TODO | 2026-04-07 | | |
| 4623 | Curly Fries (medium) | Jack in the Box | US | Side | M | TODO | 2026-04-07 | | |
| 4624 | Egg Rolls (3 pcs) | Jack in the Box | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4625 | Famous Star with Cheese | Carl's Jr | US | Burger | M | TODO | 2026-04-07 | | |
| 4626 | Western Bacon Cheeseburger | Carl's Jr | US | Burger | M | TODO | 2026-04-07 | | |
| 4627 | Original Slider (1 pc) | White Castle | US | Burger | M | TODO | 2026-04-07 | | |
| 4628 | Cheese Slider (1 pc) | White Castle | US | Burger | M | TODO | 2026-04-07 | | |
| 4629 | Sack of 10 Sliders | White Castle | US | Burger | M | TODO | 2026-04-07 | | |
| 4630 | ButterBurger (single) | Culver's | US | Burger | M | TODO | 2026-04-07 | | |
| 4631 | ButterBurger (double) | Culver's | US | Burger | M | TODO | 2026-04-07 | | |
| 4632 | Cheese Curds (regular) | Culver's | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4633 | Concrete Mixer (1 regular) | Culver's | US | Dessert | M | TODO | 2026-04-07 | | Frozen custard |
| 4635 | Cod Fillet Sandwich | Culver's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4636 | Classic Italian Hoagie (regular) | Wawa | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4637 | Sizzli (sausage egg cheese) | Wawa | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4638 | Gobbler (turkey bowl) | Wawa | US | Entree | M | TODO | 2026-04-07 | | |
| 4639 | Meatball Hoagie | Wawa | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4640 | Sub MTO (custom, turkey) | Sheetz | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4641 | Boom Boom Shrimp | Sheetz | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4644 | Buc-ee's Kolache (1 pc) | Buc-ee's | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4646 | Portillo's Chicago Dog | Portillo's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4649 | Cookout Milkshake | Cookout | US | Dessert | M | TODO | 2026-04-07 | | 40+ flavor options |
| 4653 | Popeyes 3-piece Tenders | Popeyes | US | Entree | M | TODO | 2026-04-07 | | |
| 4654 | Popeyes 2-piece Mixed (leg and thigh) | Popeyes | US | Entree | M | TODO | 2026-04-07 | | |
| 4655 | Popeyes Cajun Fries (regular) | Popeyes | US | Side | M | TODO | 2026-04-07 | | |
| 4657 | Popeyes Red Beans and Rice | Popeyes | US | Side | M | TODO | 2026-04-07 | | |
| 4662 | Zaxby's Wings (5 pcs) | Zaxby's | US | Entree | M | TODO | 2026-04-07 | | |
| 4664 | Bojangles Bo-Berry Biscuit (1 pc) | Bojangles | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4666 | Del Taco Epic Burrito | Del Taco | US | Entree | M | TODO | 2026-04-07 | | |
| 4667 | Del Taco Crinkle Cut Fries | Del Taco | US | Side | M | TODO | 2026-04-07 | | |
| 4669 | Long John Silver's Fish (2 pcs) | Long John Silver's | US | Entree | M | TODO | 2026-04-07 | | Battered cod |
| 4670 | Long John Silver's Hush Puppies (3 pcs) | Long John Silver's | US | Side | M | TODO | 2026-04-07 | | |
| 4671 | Rally's/Checkers Fry Seasoned Fries | Rally's | US | Side | M | TODO | 2026-04-07 | | |
| 4672 | Rally's Big Buford | Rally's | US | Burger | M | TODO | 2026-04-07 | | |
| 4674 | Steak 'n Shake Milkshake (regular) | Steak 'n Shake | US | Dessert | M | TODO | 2026-04-07 | | |
| 4675 | Freddy's Original Double | Freddy's | US | Burger | M | TODO | 2026-04-07 | | |
| 4676 | Freddy's Cheese Sauce and Fries | Freddy's | US | Side | M | TODO | 2026-04-07 | | |
| 4677 | Smashburger Classic Smash (single) | Smashburger | US | Burger | M | TODO | 2026-04-07 | | |
| 4678 | Habit Charburger with Cheese | The Habit | US | Burger | M | TODO | 2026-04-07 | | |
| 4680 | Hardee's Thickburger (1/3 lb) | Hardee's | US | Burger | M | TODO | 2026-04-07 | | |
| 4685 | Chipotle Carnitas Bowl | Chipotle | US | Entree | M | TODO | 2026-04-07 | | |
| 4687 | Chipotle Chips and Guac | Chipotle | US | Side | H | TODO | 2026-04-07 | | |
| 4688 | Chipotle Chips and Queso | Chipotle | US | Side | M | TODO | 2026-04-07 | | |
| 4690 | Subway 6-inch Turkey Breast | Subway | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4691 | Subway 6-inch Italian BMT | Subway | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4692 | Subway 6-inch Chicken Teriyaki | Subway | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4704 | Chili's Baby Back Ribs (full rack) | Chili's | US | Entree | M | TODO | 2026-04-07 | | |
| 4705 | Chili's Chicken Crispers | Chili's | US | Entree | M | TODO | 2026-04-07 | | |
| 4706 | Chili's Big Mouth Burger | Chili's | US | Burger | M | TODO | 2026-04-07 | | |
| 4708 | Chili's Molten Lava Cake | Chili's | US | Dessert | M | TODO | 2026-04-07 | | |
| 4709 | Applebee's Boneless Wings | Applebee's | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4711 | Olive Garden Breadstick (1 pc) | Olive Garden | US | Bread | M | TODO | 2026-04-07 | | |
| 4713 | Olive Garden Chicken Parm | Olive Garden | US | Entree | M | TODO | 2026-04-07 | | |
| 4717 | Red Lobster Ultimate Feast | Red Lobster | US | Entree | M | TODO | 2026-04-07 | | |
| 4720 | Texas Roadhouse 6 oz Sirloin | Texas Roadhouse | US | Entree | M | TODO | 2026-04-07 | | |
| 4721 | Texas Roadhouse Roll with Cinnamon Butter (1 pc) | Texas Roadhouse | US | Bread | M | TODO | 2026-04-07 | | |
| 4723 | Outback 6 oz Victoria's Filet | Outback | US | Entree | M | TODO | 2026-04-07 | | |
| 4724 | Cheesecake Factory Avocado Egg Rolls | Cheesecake Factory | US | Appetizer | M | TODO | 2026-04-07 | | |
| 4726 | Cheesecake Factory Glamburger | Cheesecake Factory | US | Burger | M | TODO | 2026-04-07 | | |
| 4730 | Buffalo Wild Wings Traditional Wings (6 pcs) | Buffalo Wild Wings | US | Appetizer | M | TODO | 2026-04-07 | | |

## Section 89: Coffee Shop & Juice/Smoothie Full Menus (80 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4731 | Starbucks Cake Pop (1 pc) | Starbucks | US | Snack | M | TODO | 2026-04-07 | | |
| 4732 | Starbucks Protein Box (eggs and cheese) | Starbucks | US | Snack | M | TODO | 2026-04-07 | | |
| 4733 | Starbucks Egg Bites (bacon gruyere, 2 pcs) | Starbucks | US | Breakfast | H | TODO | 2026-04-07 | | |
| 4734 | Starbucks Egg Bites (egg white red pepper) | Starbucks | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4737 | Starbucks Double Smoked Bacon Sandwich | Starbucks | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4738 | Starbucks Spinach Feta Wrap | Starbucks | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4743 | Starbucks Banana Nut Bread (1 slice) | Starbucks | US | Bakery | M | TODO | 2026-04-07 | | |
| 4744 | Starbucks Lemon Loaf (1 slice) | Starbucks | US | Bakery | M | TODO | 2026-04-07 | | |
| 4745 | Starbucks Cheese Danish | Starbucks | US | Bakery | M | TODO | 2026-04-07 | | |
| 4747 | Starbucks Pink Drink (grande) | Starbucks | US | Beverage | H | TODO | 2026-04-07 | | Strawberry acai refresher with coconut milk |
| 4748 | Starbucks Caramel Frappuccino (grande) | Starbucks | US | Beverage | H | TODO | 2026-04-07 | | |
| 4749 | Starbucks Mocha Frappuccino (grande) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | |
| 4751 | Starbucks Iced Caramel Macchiato (grande) | Starbucks | US | Beverage | H | TODO | 2026-04-07 | | |
| 4752 | Starbucks Pumpkin Spice Latte (grande) | Starbucks | US | Beverage | H | TODO | 2026-04-07 | | Seasonal |
| 4753 | Starbucks White Mocha (grande, hot) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | |
| 4754 | Starbucks Matcha Latte (grande) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | |
| 4760 | Jamba Juice Aloha Pineapple (medium) | Jamba Juice | US | Smoothie | M | TODO | 2026-04-07 | | |
| 4761 | Jamba Juice Caribbean Passion (medium) | Jamba Juice | US | Smoothie | M | TODO | 2026-04-07 | | |
| 4762 | Jamba Juice PB Chocolate Love (medium) | Jamba Juice | US | Smoothie | M | TODO | 2026-04-07 | | |
| 4763 | Jamba Juice Greens 'n Ginger (medium) | Jamba Juice | US | Smoothie | M | TODO | 2026-04-07 | | |
| 4766 | Smoothie King Lean1 Chocolate (medium) | Smoothie King | US | Smoothie | M | TODO | 2026-04-07 | | |
| 4767 | Smoothie King The Activator Pineapple (medium) | Smoothie King | US | Smoothie | M | TODO | 2026-04-07 | | |
| 4770 | Tropical Smoothie Chicken Bacon Ranch Wrap | Tropical Smoothie | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4772 | Dunkin Munchkins (5 pcs) | Dunkin | US | Dessert | M | TODO | 2026-04-07 | | Donut holes |
| 4774 | Dunkin Wake-Up Wrap (bacon egg cheese) | Dunkin | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4777 | Dunkin Frozen Coffee (medium) | Dunkin | US | Beverage | M | TODO | 2026-04-07 | | |
| 4781 | Tim Hortons Double Double Coffee (medium) | Tim Hortons | CA | Beverage | M | TODO | 2026-04-07 | | Double cream double sugar |
| 4782 | Tim Hortons Timbits (5 pcs) | Tim Hortons | CA | Dessert | M | TODO | 2026-04-07 | | Donut holes |
| 4783 | Tim Hortons French Vanilla (medium) | Tim Hortons | CA | Beverage | M | TODO | 2026-04-07 | | |
| 4784 | Tim Hortons Iced Capp (medium) | Tim Hortons | CA | Beverage | M | TODO | 2026-04-07 | | |
| 4786 | Tim Hortons Everything Bagel | Tim Hortons | CA | Breakfast | M | TODO | 2026-04-07 | | |
| 4787 | Philz Mint Mojito Iced Coffee (medium) | Philz Coffee | US | Beverage | L | TODO | 2026-04-07 | | |
| 4788 | Philz Tesora (medium) | Philz Coffee | US | Beverage | L | TODO | 2026-04-07 | | |
| 4789 | Blue Bottle New Orleans Iced Coffee | Blue Bottle | US | Beverage | L | TODO | 2026-04-07 | | With chicory and milk |
| 4790 | Peet's Coffee Caramel Macchiato (medium) | Peet's Coffee | US | Beverage | M | TODO | 2026-04-07 | | |
| 4794 | Starbucks Dragon Drink (grande) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | Mango dragonfruit with coconut milk |
| 4795 | Starbucks Strawberry Acai Refresher (grande) | Starbucks | US | Beverage | H | TODO | 2026-04-07 | | |
| 4796 | Starbucks Java Chip Frappuccino (grande) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | |
| 4798 | Starbucks Chicken Maple Butter Sandwich | Starbucks | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4799 | Dunkin Croissant Stuffer (ham and swiss) | Dunkin | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4800 | Dunkin Refresher (strawberry dragonfruit, medium) | Dunkin | US | Beverage | M | TODO | 2026-04-07 | | |
| 4801 | Starbucks Cranberry Bliss Bar | Starbucks | US | Snack | L | TODO | 2026-04-07 | | Seasonal |
| 4802 | Dutch Bros Frost (cookie dough, medium) | Dutch Bros | US | Beverage | M | TODO | 2026-04-07 | | Blended |
| 4803 | Starbucks Hot Chocolate (grande) | Starbucks | US | Beverage | M | TODO | 2026-04-07 | | |
| 4807 | Panera Bread Bowl (broccoli cheddar) | Panera | US | Soup | M | TODO | 2026-04-07 | | |

## Section 90: Dessert & Ice Cream Chains (60 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4811 | Baskin-Robbins Scoop (1 regular, chocolate) | Baskin-Robbins | US | Dessert | M | TODO | 2026-04-07 | | |
| 4812 | Baskin-Robbins Scoop (1 regular, vanilla) | Baskin-Robbins | US | Dessert | M | TODO | 2026-04-07 | | |
| 4813 | Baskin-Robbins Scoop (1 regular, mint chip) | Baskin-Robbins | US | Dessert | M | TODO | 2026-04-07 | | |
| 4814 | Baskin-Robbins Scoop (1 regular, pralines and cream) | Baskin-Robbins | US | Dessert | M | TODO | 2026-04-07 | | |
| 4815 | Cold Stone Gotta Have It (Founder's Favorite) | Cold Stone | US | Dessert | M | TODO | 2026-04-07 | | |
| 4816 | Cold Stone Love It (Birthday Cake Remix) | Cold Stone | US | Dessert | M | TODO | 2026-04-07 | | |
| 4817 | Cold Stone Like It (Oreo Overload) | Cold Stone | US | Dessert | M | TODO | 2026-04-07 | | |
| 4819 | Dairy Queen Blizzard (Oreo, medium) | Dairy Queen | US | Dessert | H | TODO | 2026-04-07 | | |
| 4820 | Dairy Queen Blizzard (Cookie Dough, medium) | Dairy Queen | US | Dessert | M | TODO | 2026-04-07 | | |
| 4821 | Dairy Queen Blizzard (Reese's PB Cup, medium) | Dairy Queen | US | Dessert | M | TODO | 2026-04-07 | | |
| 4822 | Dairy Queen Blizzard (Heath, medium) | Dairy Queen | US | Dessert | M | TODO | 2026-04-07 | | |
| 4825 | Dairy Queen Banana Split | Dairy Queen | US | Dessert | M | TODO | 2026-04-07 | | |
| 4826 | Dairy Queen Flamethrower Burger | Dairy Queen | US | Burger | M | TODO | 2026-04-07 | | |
| 4833 | Insomnia Cookie (chocolate chunk, 1 pc) | Insomnia Cookies | US | Dessert | M | TODO | 2026-04-07 | | |
| 4834 | Insomnia Cookie (snickerdoodle, 1 pc) | Insomnia Cookies | US | Dessert | M | TODO | 2026-04-07 | | |
| 4835 | Insomnia Cookie (double chocolate chunk, 1 pc) | Insomnia Cookies | US | Dessert | M | TODO | 2026-04-07 | | |
| 4836 | Nothing Bundt Cake (bundtlet, 1 pc) | Nothing Bundt Cakes | US | Dessert | M | TODO | 2026-04-07 | | |
| 4837 | Nothing Bundt Cake (bundtini, 1 pc) | Nothing Bundt Cakes | US | Dessert | M | TODO | 2026-04-07 | | Bite-size |
| 4840 | Cinnabon Center of the Roll (1 pc) | Cinnabon | US | Dessert | M | TODO | 2026-04-07 | | |
| 4844 | Wetzel's Pretzels Original (1 pc) | Wetzel's Pretzels | US | Snack | M | TODO | 2026-04-07 | | |
| 4848 | Krispy Kreme Strawberry Iced (1 pc) | Krispy Kreme | US | Dessert | M | TODO | 2026-04-07 | | |
| 4851 | Dunkin Blueberry Donut (1 pc) | Dunkin | US | Dessert | M | TODO | 2026-04-07 | | |
| 4853 | Jeni's Splendid (Brambleberry Crisp, per 1/2 cup) | Jeni's | US | Dessert | L | TODO | 2026-04-07 | | |
| 4854 | Jeni's Splendid (Brown Butter Almond Brittle, per 1/2 cup) | Jeni's | US | Dessert | L | TODO | 2026-04-07 | | |
| 4855 | Jeni's Splendid (Gooey Butter Cake, per 1/2 cup) | Jeni's | US | Dessert | L | TODO | 2026-04-07 | | |
| 4856 | Jeni's Splendid (Salty Caramel, per 1/2 cup) | Jeni's | US | Dessert | L | TODO | 2026-04-07 | | |
| 4857 | Salt & Straw (Double Fold Vanilla, per scoop) | Salt & Straw | US | Dessert | L | TODO | 2026-04-07 | | |
| 4858 | Salt & Straw (Honey Lavender, per scoop) | Salt & Straw | US | Dessert | L | TODO | 2026-04-07 | | |
| 4859 | Salt & Straw (Chocolate Gooey Brownie, per scoop) | Salt & Straw | US | Dessert | L | TODO | 2026-04-07 | | |
| 4862 | Duck Donuts Bare Donut (1 pc) | Duck Donuts | US | Dessert | M | TODO | 2026-04-07 | | |
| 4863 | Duck Donuts Chocolate Iced with Sprinkles (1 pc) | Duck Donuts | US | Dessert | M | TODO | 2026-04-07 | | |
| 4864 | Voodoo Doughnut Voodoo Doll (1 pc) | Voodoo Doughnut | US | Dessert | L | TODO | 2026-04-07 | | |
| 4865 | Voodoo Doughnut Old Dirty Bastard (1 pc) | Voodoo Doughnut | US | Dessert | L | TODO | 2026-04-07 | | |
| 4866 | Sprinkles Cupcake (red velvet, 1 pc) | Sprinkles | US | Dessert | L | TODO | 2026-04-07 | | |
| 4867 | Sprinkles Cupcake (dark chocolate, 1 pc) | Sprinkles | US | Dessert | L | TODO | 2026-04-07 | | |
| 4868 | Magnolia Bakery Banana Pudding (per serving) | Magnolia Bakery | US | Dessert | M | TODO | 2026-04-07 | | |
| 4869 | Baked by Melissa Cupcake (1 mini) | Baked by Melissa | US | Dessert | L | TODO | 2026-04-07 | | |
| 4870 | Milk Bar Birthday Cake Truffle (2 pcs) | Milk Bar | US | Dessert | L | TODO | 2026-04-07 | | |

## Section 91: Breakfast Chains (60 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4871 | IHOP Original Buttermilk Pancakes (short stack 3) | IHOP | US | Breakfast | H | TODO | 2026-04-07 | | |
| 4872 | IHOP Harvest Grain 'N Nut Pancakes (short stack) | IHOP | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4879 | IHOP 2x2x2 (2 eggs, 2 bacon, 2 pancakes) | IHOP | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4883 | Denny's Moon Over My Hammy | Denny's | US | Breakfast | M | TODO | 2026-04-07 | | Ham and egg on sourdough |
| 4885 | Denny's Belgian Waffle Slam | Denny's | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4895 | First Watch Elevated Egg Sandwich | First Watch | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4897 | First Watch AM Superfoods Bowl | First Watch | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4899 | Cracker Barrel Country Boy Breakfast | Cracker Barrel | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4900 | Cracker Barrel Uncle Herschel's Breakfast | Cracker Barrel | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4901 | Cracker Barrel Buttermilk Pancakes (3 stack) | Cracker Barrel | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4903 | Cracker Barrel Chicken and Dumplings | Cracker Barrel | US | Entree | M | TODO | 2026-04-07 | | |
| 4905 | Bob Evans Sunshine Skillet | Bob Evans | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4906 | Bob Evans Farmhouse Feast (plate) | Bob Evans | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4907 | Bob Evans Stacked & Stuffed Hotcakes | Bob Evans | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4909 | Perkins Tremendous Twelve | Perkins | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4910 | Perkins Pancake Platter | Perkins | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4911 | Village Inn Skillet (loaded) | Village Inn | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4913 | First Watch Kale Tonic Juice | First Watch | US | Beverage | M | TODO | 2026-04-07 | | |
| 4915 | Snooze Pineapple Upside Down Pancakes | Snooze | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4918 | Another Broken Egg Lobster Omelette | Another Broken Egg | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4919 | Original Pancake House Dutch Baby | Original Pancake House | US | Breakfast | M | TODO | 2026-04-07 | | German puffed pancake |
| 4920 | Original Pancake House Apple Pancake | Original Pancake House | US | Breakfast | M | TODO | 2026-04-07 | | |
| 4921 | Le Pain Quotidien Tartine (avocado) | Le Pain Quotidien | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4922 | Le Pain Quotidien Granola Bowl | Le Pain Quotidien | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4923 | Eggslut Fairfax Sandwich | Eggslut | US | Breakfast | L | TODO | 2026-04-07 | | Soft scrambled egg sandwich |
| 4924 | Eggslut Slut (coddled egg on potato puree) | Eggslut | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4925 | Keke's Breakfast Cafe Traditional Breakfast | Keke's | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4926 | Broken Yolk Big Country Breakfast | Broken Yolk | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4927 | Metro Diner Fried Chicken and Waffles | Metro Diner | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4929 | Tupelo Honey Shrimp and Grits | Tupelo Honey | US | Breakfast | L | TODO | 2026-04-07 | | |
| 4930 | Black Bear Diner Lumberjack Breakfast | Black Bear Diner | US | Breakfast | L | TODO | 2026-04-07 | | |

## Section 92: Salad & Bowl Chains (40 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4937 | CAVA Greens and Grains Bowl (grilled chicken) | CAVA | US | Bowl | M | TODO | 2026-04-07 | | |
| 4940 | CAVA RightRice Bowl | CAVA | US | Bowl | M | TODO | 2026-04-07 | | |
| 4943 | Chipotle Bowl (chicken, white rice, black beans, salsa) | Chipotle | US | Bowl | H | TODO | 2026-04-07 | | Standard build |
| 4944 | Chipotle Lifestyle Bowl (Whole30) | Chipotle | US | Bowl | M | TODO | 2026-04-07 | | |
| 4945 | Chipotle Lifestyle Bowl (Keto) | Chipotle | US | Bowl | M | TODO | 2026-04-07 | | |
| 4946 | Chipotle Queso Blanco (per serving) | Chipotle | US | Side | M | TODO | 2026-04-07 | | |
| 4947 | Chipotle Tortilla on the side (1 pc) | Chipotle | US | Bread | M | TODO | 2026-04-07 | | |
| 4948 | Freshii Zen Bowl | Freshii | US | Bowl | L | TODO | 2026-04-07 | | |
| 4949 | Freshii Pangoa Bowl | Freshii | US | Bowl | L | TODO | 2026-04-07 | | |
| 4950 | CoreLife Eatery Chicken Power Bowl | CoreLife | US | Bowl | L | TODO | 2026-04-07 | | |
| 4951 | CoreLife Eatery Sriracha Steak Bowl | CoreLife | US | Bowl | L | TODO | 2026-04-07 | | |
| 4955 | Just Salad Crispy Chicken Ranch | Just Salad | US | Salad | L | TODO | 2026-04-07 | | |
| 4956 | Dig Inn Market Plate (chicken, 3 sides) | Dig Inn | US | Bowl | L | TODO | 2026-04-07 | | |
| 4958 | Naya Mediterranean Bowl | Naya | US | Bowl | L | TODO | 2026-04-07 | | |
| 4959 | Cosi TBM Grilled Chicken Flatbread | Cosi | US | Sandwich | L | TODO | 2026-04-07 | | |
| 4964 | Salata Build Your Own Salad (avg build) | Salata | US | Salad | L | TODO | 2026-04-07 | | |
| 4966 | Cava Lamb Meatball Bowl | CAVA | US | Bowl | M | TODO | 2026-04-07 | | |
| 4967 | Honeygrow Stir-Fry (sesame garlic, regular) | Honeygrow | US | Bowl | L | TODO | 2026-04-07 | | |
| 4968 | Honeygrow Honeybar (1 pc) | Honeygrow | US | Dessert | L | TODO | 2026-04-07 | | Fruit and grain bar |
| 4969 | True Food Kitchen Ancient Grains Bowl | True Food Kitchen | US | Bowl | L | TODO | 2026-04-07 | | |
| 4970 | Flower Child Mother Earth Bowl | Flower Child | US | Bowl | L | TODO | 2026-04-07 | | |

## Section 93: Sandwich & Sub Chains (50 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 4971 | Jersey Mike's #13 Original Italian (regular) | Jersey Mike's | US | Sandwich | H | TODO | 2026-04-07 | | |
| 4972 | Jersey Mike's #7 Turkey and Provolone (regular) | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4973 | Jersey Mike's #6 Roast Beef and Provolone | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4974 | Jersey Mike's #9 Club Supreme (regular) | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4975 | Jersey Mike's #17 Mike's Famous Philly | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4976 | Jersey Mike's Chicken Bacon Ranch | Jersey Mike's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4977 | Jimmy John's #1 Pepe | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | Smoked ham, provolone |
| 4978 | Jimmy John's #5 Vito | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | Italian sub |
| 4979 | Jimmy John's #9 Italian Night Club | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4980 | Jimmy John's #4 Turkey Tom | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4981 | Jimmy John's Unwich (lettuce wrap, any) | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | Low carb option |
| 4982 | Jimmy John's Beach Club | Jimmy John's | US | Sandwich | M | TODO | 2026-04-07 | | Turkey and avocado |
| 4983 | Firehouse Subs Hook & Ladder (medium) | Firehouse Subs | US | Sandwich | M | TODO | 2026-04-07 | | Smoked turkey and ham |
| 4984 | Firehouse Subs Smokehouse Beef & Cheddar | Firehouse Subs | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4985 | Firehouse Subs Engineer (medium) | Firehouse Subs | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4986 | Firehouse Subs Hero (medium) | Firehouse Subs | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4989 | Potbelly Turkey Breast (original) | Potbelly | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4990 | Potbelly Chocolate Brownie Cookie (1 pc) | Potbelly | US | Dessert | M | TODO | 2026-04-07 | | |
| 4991 | McAlister's Deli Club (whole) | McAlister's Deli | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4992 | McAlister's Deli Spud Max (loaded baked potato) | McAlister's Deli | US | Entree | M | TODO | 2026-04-07 | | |
| 4993 | McAlister's Sweet Tea (large) | McAlister's Deli | US | Beverage | M | TODO | 2026-04-07 | | Free refills |
| 4994 | Schlotzsky's The Original (medium) | Schlotzsky's | US | Sandwich | M | TODO | 2026-04-07 | | |
| 4998 | Jason's Deli Salad Bar (per plate) | Jason's Deli | US | Salad | M | TODO | 2026-04-07 | | |
| 4999 | Which Wich Elvis (PB, banana, honey) | Which Wich | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5000 | Which Wich Grilled Cheese | Which Wich | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5001 | Penn Station East Coast Subs Philly | Penn Station | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5002 | Penn Station Chicken Teriyaki | Penn Station | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5003 | Penn Station Fresh-Cut Fries (regular) | Penn Station | US | Side | L | TODO | 2026-04-07 | | |
| 5004 | Quiznos Classic Italian (regular) | Quiznos | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5005 | Quiznos Chicken Carbonara | Quiznos | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5006 | Erbert & Gerbert's Boney Billy | Erbert & Gerbert's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5007 | Capriotti's Bobbie (turkey, cranberry, stuffing) | Capriotti's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5008 | Capriotti's Capastrami | Capriotti's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5010 | Publix Chicken Tender Sub (whole) | Publix | US | Sandwich | M | TODO | 2026-04-07 | | Florida cult favorite |
| 5011 | Publix Boar's Head Italian (whole) | Publix | US | Sandwich | M | TODO | 2026-04-07 | | |
| 5012 | Wegmans Danny's Favorite Sub | Wegmans | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5013 | Ike's Love & Sandwiches Matt Cain | Ike's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5014 | Primo Hoagies Italian (regular) | Primo Hoagies | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5015 | Newk's Eatery Shrimp Remoulade | Newk's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5016 | Newk's Eatery Newk's Q | Newk's | US | Sandwich | L | TODO | 2026-04-07 | | |
| 5017 | Earl of Sandwich The Original 1762 | Earl of Sandwich | US | Sandwich | L | TODO | 2026-04-07 | | Hot roast beef |
| 5018 | Lee's Sandwiches Vietnamese Banh Mi | Lee's Sandwiches | US | Sandwich | M | TODO | 2026-04-07 | | |
| 5020 | Portillo's Combo (Italian beef and sausage) | Portillo's | US | Sandwich | M | TODO | 2026-04-07 | | |

## Section 94: Pizza Chains Full (60 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 5022 | Domino's Hand Tossed Pepperoni (1 slice, medium) | Domino's | US | Pizza | H | TODO | 2026-04-07 | | |
| 5023 | Domino's Thin Crust Cheese (1 slice, medium) | Domino's | US | Pizza | M | TODO | 2026-04-07 | | |
| 5024 | Domino's Brooklyn Style Pepperoni (1 slice, large) | Domino's | US | Pizza | M | TODO | 2026-04-07 | | |
| 5026 | Domino's Parmesan Bread Bites (8 pcs) | Domino's | US | Bread | M | TODO | 2026-04-07 | | |
| 5027 | Domino's Boneless Wings (8 pcs) | Domino's | US | Appetizer | M | TODO | 2026-04-07 | | |
| 5031 | Pizza Hut Original Pan Cheese (1 slice, medium) | Pizza Hut | US | Pizza | H | TODO | 2026-04-07 | | |
| 5032 | Pizza Hut Original Pan Pepperoni (1 slice, medium) | Pizza Hut | US | Pizza | H | TODO | 2026-04-07 | | |
| 5036 | Pizza Hut Garlic Knots (4 pcs) | Pizza Hut | US | Bread | M | TODO | 2026-04-07 | | |
| 5037 | Pizza Hut WingStreet Traditional (6 pcs) | Pizza Hut | US | Appetizer | M | TODO | 2026-04-07 | | |
| 5038 | Papa John's Original Crust Cheese (1 slice, large) | Papa John's | US | Pizza | H | TODO | 2026-04-07 | | |
| 5039 | Papa John's Original Crust Pepperoni (1 slice, large) | Papa John's | US | Pizza | M | TODO | 2026-04-07 | | |
| 5040 | Papa John's Garlic Sauce (1 cup) | Papa John's | US | Condiment | M | TODO | 2026-04-07 | | |
| 5041 | Papa John's Breadsticks (2 pcs) | Papa John's | US | Bread | M | TODO | 2026-04-07 | | |
| 5042 | Papa John's Papadias (Pepperoni) | Papa John's | US | Sandwich | M | TODO | 2026-04-07 | | Flatbread |
| 5043 | Little Caesars Hot-N-Ready (1 slice) | Little Caesars | US | Pizza | H | TODO | 2026-04-07 | | Cheese pepperoni |
| 5044 | Little Caesars Crazy Bread (2 pcs) | Little Caesars | US | Bread | M | TODO | 2026-04-07 | | |
| 5045 | Little Caesars Italian Cheese Bread (2 pcs) | Little Caesars | US | Bread | M | TODO | 2026-04-07 | | |
| 5046 | Little Caesars Stuffed Crazy Bread (2 pcs) | Little Caesars | US | Bread | M | TODO | 2026-04-07 | | |
| 5048 | Marco's Pizza White Cheezy (1 slice, large) | Marco's Pizza | US | Pizza | M | TODO | 2026-04-07 | | |
| 5049 | MOD Pizza (11 inch, custom avg) | MOD Pizza | US | Pizza | M | TODO | 2026-04-07 | | Build your own |
| 5052 | Blaze Pizza Build Your Own (1 slice, avg) | Blaze Pizza | US | Pizza | M | TODO | 2026-04-07 | | |
| 5056 | Domino's MeatZZa (1 slice, medium) | Domino's | US | Pizza | M | TODO | 2026-04-07 | | |
| 5057 | Domino's Pacific Veggie (1 slice, medium) | Domino's | US | Pizza | M | TODO | 2026-04-07 | | |
| 5058 | Pizza Hut Meat Lover's (1 slice, medium) | Pizza Hut | US | Pizza | M | TODO | 2026-04-07 | | |
| 5059 | Pizza Hut Veggie Lover's (1 slice, medium) | Pizza Hut | US | Pizza | M | TODO | 2026-04-07 | | |
| 5060 | Jet's 8 Corner Pizza (1 slice) | Jet's Pizza | US | Pizza | L | TODO | 2026-04-07 | | Detroit-style |
| 5061 | Round Table King Arthur's Supreme (1 slice, large) | Round Table | US | Pizza | L | TODO | 2026-04-07 | | |
| 5062 | Donatos Pepperoni (1 slice, large) | Donatos | US | Pizza | L | TODO | 2026-04-07 | | Edge-to-edge toppings |
| 5063 | Mountain Mike's Pepperoni (1 slice, large) | Mountain Mike's | US | Pizza | L | TODO | 2026-04-07 | | Crispy curly pepperoni |
| 5064 | Hungry Howie's Cheese (1 slice, medium) | Hungry Howie's | US | Pizza | L | TODO | 2026-04-07 | | Flavored crust |
| 5065 | Cicis Pizza Buffet (avg plate) | Cicis | US | Pizza | L | TODO | 2026-04-07 | | |
| 5066 | Sbarro NY Style Cheese (1 slice) | Sbarro | US | Pizza | M | TODO | 2026-04-07 | | Mall pizza |
| 5067 | Sbarro Stromboli (1 pc) | Sbarro | US | Entree | L | TODO | 2026-04-07 | | |
| 5069 | Sam's Club Pizza (1 slice) | Sam's Club | US | Pizza | M | TODO | 2026-04-07 | | |
| 5070 | Domino's Lava Cake (1 pc) | Domino's | US | Dessert | M | TODO | 2026-04-07 | | |
| 5071 | Papa John's Double Chocolate Chip Brownie (1 pc) | Papa John's | US | Dessert | M | TODO | 2026-04-07 | | |
| 5072 | Little Caesars Pepperoni Crazy Puffs (8 pcs) | Little Caesars | US | Appetizer | L | TODO | 2026-04-07 | | |
| 5073 | DiGiorno Rising Crust Pepperoni (1/6 pizza) | DiGiorno | US | Frozen Pizza | M | TODO | 2026-04-07 | | |
| 5074 | DiGiorno Stuffed Crust Supreme (1/6 pizza) | DiGiorno | US | Frozen Pizza | M | TODO | 2026-04-07 | | |
| 5075 | Tombstone Original Pepperoni (1/5 pizza) | Tombstone | US | Frozen Pizza | M | TODO | 2026-04-07 | | |
| 5076 | Red Baron Classic Crust Pepperoni (1/5 pizza) | Red Baron | US | Frozen Pizza | M | TODO | 2026-04-07 | | |
| 5077 | Totino's Party Pizza (1/2 pizza) | Totino's | US | Frozen Pizza | M | TODO | 2026-04-07 | | |
| 5079 | Screamin' Sicilian Bessie's Revenge (1/6 pizza) | Screamin' Sicilian | US | Frozen Pizza | L | TODO | 2026-04-07 | | |
| 5080 | California Pizza Kitchen Frozen BBQ Chicken (1/3 pizza) | CPK | US | Frozen Pizza | M | TODO | 2026-04-07 | | |

## Section 95: Alcohol Complete (100 items)

| # | Food Name | Brand/Restaurant | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-----------------|---------|----------|----------|--------|------------|----------------|-------|
| 5081 | IPA Beer (average craft, 12 oz) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~200 cal |
| 5082 | Lager Beer (average, 12 oz) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~150 cal |
| 5083 | Stout Beer (average, 12 oz) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~210 cal |
| 5084 | Wheat Beer (average, 12 oz) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~165 cal |
| 5085 | Sour Beer (average craft, 12 oz) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | |
| 5086 | Light Beer (average, 12 oz) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~100 cal |
| 5088 | Coors Light (12 oz) | Molson Coors | US | Alcohol | H | TODO | 2026-04-07 | | |
| 5089 | Miller Lite (12 oz) | Molson Coors | US | Alcohol | M | TODO | 2026-04-07 | | |
| 5090 | Corona Extra (12 oz) | Grupo Modelo | MX | Alcohol | H | TODO | 2026-04-07 | | |
| 5091 | Modelo Especial (12 oz) | Grupo Modelo | MX | Alcohol | H | TODO | 2026-04-07 | | |
| 5092 | Heineken (12 oz) | Heineken | NL | Alcohol | M | TODO | 2026-04-07 | | |
| 5093 | Guinness Draught (12 oz) | Guinness | IE | Alcohol | M | TODO | 2026-04-07 | | |
| 5094 | Blue Moon Belgian White (12 oz) | Molson Coors | US | Alcohol | M | TODO | 2026-04-07 | | |
| 5095 | Stella Artois (12 oz) | AB InBev | BE | Alcohol | M | TODO | 2026-04-07 | | |
| 5096 | Michelob Ultra (12 oz) | Anheuser-Busch | US | Alcohol | H | TODO | 2026-04-07 | | 95 cal |
| 5097 | Cabernet Sauvignon (5 oz glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~125 cal |
| 5099 | Pinot Noir (5 oz glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~120 cal |
| 5101 | Sauvignon Blanc (5 oz glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | |
| 5102 | Rose Wine (5 oz glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~120 cal |
| 5105 | Pinot Grigio (5 oz glass) | Generic | IT | Alcohol | M | TODO | 2026-04-07 | | |
| 5107 | Moscato (5 oz glass) | Generic | IT | Alcohol | M | TODO | 2026-04-07 | | Sweet wine |
| 5110 | Gin (1.5 oz shot) | Generic | GB | Alcohol | M | TODO | 2026-04-07 | | |
| 5111 | White Rum (1.5 oz shot) | Generic | PR | Alcohol | M | TODO | 2026-04-07 | | |
| 5112 | Dark Rum (1.5 oz shot) | Generic | JM | Alcohol | M | TODO | 2026-04-07 | | |
| 5113 | Tequila Blanco (1.5 oz shot) | Generic | MX | Alcohol | H | TODO | 2026-04-07 | | |
| 5114 | Tequila Reposado (1.5 oz shot) | Generic | MX | Alcohol | M | TODO | 2026-04-07 | | |
| 5120 | Old Fashioned (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~150 cal |
| 5121 | Martini (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~175 cal |
| 5126 | Pina Colada (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~490 cal |
| 5127 | Long Island Iced Tea (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~290 cal |
| 5128 | Moscow Mule (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~175 cal |
| 5129 | Aperol Spritz (per glass) | Generic | IT | Alcohol | H | TODO | 2026-04-07 | | ~125 cal |
| 5130 | Espresso Martini (per glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~225 cal |
| 5131 | Paloma (per glass) | Generic | MX | Alcohol | M | TODO | 2026-04-07 | | ~200 cal |
| 5133 | Truly Hard Seltzer (12 oz, any flavor) | Truly | US | Alcohol | M | TODO | 2026-04-07 | | 100 cal |
| 5134 | High Noon Vodka Soda (12 oz, any flavor) | High Noon | US | Alcohol | M | TODO | 2026-04-07 | | 100 cal |
| 5135 | Sake (5 oz, hot or cold) | Generic | JP | Alcohol | M | TODO | 2026-04-07 | | ~175 cal |
| 5136 | Soju (1 bottle, 360ml) | Generic | KR | Alcohol | M | TODO | 2026-04-07 | | ~400 cal |
| 5137 | Baileys Irish Cream (1.5 oz) | Baileys | IE | Alcohol | M | TODO | 2026-04-07 | | ~140 cal |
| 5139 | Amaretto (1.5 oz) | Generic | IT | Alcohol | L | TODO | 2026-04-07 | | |
| 5142 | Bloody Mary (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | ~200 cal |
| 5143 | Tequila Sunrise (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | |
| 5144 | Tom Collins (per glass) | Generic | US | Alcohol | L | TODO | 2026-04-07 | | |
| 5145 | Whiskey Sour (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | |
| 5146 | Mai Tai (per glass) | Generic | US | Alcohol | M | TODO | 2026-04-07 | | |
| 5147 | Irish Coffee (per glass) | Generic | IE | Alcohol | L | TODO | 2026-04-07 | | |
| 5148 | Rum and Coke (per glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | |
| 5149 | Vodka Soda (per glass) | Generic | US | Alcohol | H | TODO | 2026-04-07 | | ~97 cal |
| 5150 | Gin and Tonic (per glass) | Generic | GB | Alcohol | H | TODO | 2026-04-07 | | ~170 cal |
# Batch 2: Branded & Packaged Food Products (Grocery Store Items)

> **Total items:** 2500
> **Number range:** 5151–7650
> **Generated:** 2026-04-07

## Section 99: Trader Joe's Complete Product Line (120 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5152 | Cauliflower Gnocchi | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | Low-carb alternative |
| 5153 | Everything But The Bagel Seasoning | Trader Joe's | US | Condiments | H | TODO | 2026-04-07 | | Iconic seasoning blend |
| 5156 | Gone Bananas Chocolate Covered Banana Slices | Trader Joe's | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 5158 | Elote Corn Chip Dippers | Trader Joe's | US | Snacks | H | TODO | 2026-04-07 | | |
| 5160 | Spatchcocked Lemon Herb Chicken | Trader Joe's | US | Meat | H | TODO | 2026-04-07 | | |
| 5161 | Palak Paneer | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | Indian frozen meal |
| 5163 | Pork Gyoza Potstickers | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5164 | Turkey Corn Dogs | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5165 | Mini Hold The Cone Ice Cream Cones | Trader Joe's | US | Frozen Desserts | H | TODO | 2026-04-07 | | |
| 5166 | Peanut Butter Filled Pretzel Nuggets | Trader Joe's | US | Snacks | H | TODO | 2026-04-07 | | |
| 5168 | Cauliflower Pizza Crust | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5169 | Shawarma Chicken Thighs | Trader Joe's | US | Meat | M | TODO | 2026-04-07 | | |
| 5172 | Reduced Guilt Mac & Cheese | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | Lower calorie option |
| 5173 | Joe-Joe's Chocolate Cream Cookies | Trader Joe's | US | Cookies | H | TODO | 2026-04-07 | | |
| 5174 | Chocolate Lava Cake | Trader Joe's | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 5175 | Mango Cream Bars | Trader Joe's | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 5176 | Thai Vegetable Gyoza | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5177 | Soy Chorizo | Trader Joe's | US | Plant-Based | H | TODO | 2026-04-07 | | Popular vegan item |
| 5179 | Cowboy Bark Chocolate | Trader Joe's | US | Candy | M | TODO | 2026-04-07 | | Seasonal favorite |
| 5180 | Triple Ginger Snaps | Trader Joe's | US | Cookies | M | TODO | 2026-04-07 | | |
| 5182 | Bamba Peanut Snacks | Trader Joe's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5183 | Lobster Ravioli | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5184 | Cruciferous Crunch Collection | Trader Joe's | US | Produce | M | TODO | 2026-04-07 | | Salad kit |
| 5185 | Green Goddess Salad Dressing | Trader Joe's | US | Condiments | H | TODO | 2026-04-07 | | Viral TikTok item |
| 5186 | Umami Seasoning Blend | Trader Joe's | US | Condiments | H | TODO | 2026-04-07 | | |
| 5187 | Chile Lime Seasoning Blend | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | |
| 5188 | 21 Seasoning Salute | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | |
| 5189 | Ube Mochi Pancake & Waffle Mix | Trader Joe's | US | Baking | H | TODO | 2026-04-07 | | Cult following |
| 5190 | Ube Ice Cream | Trader Joe's | US | Frozen Desserts | H | TODO | 2026-04-07 | | |
| 5191 | Magnifisauce | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | |
| 5192 | Bomba Sauce | Trader Joe's | US | Condiments | H | TODO | 2026-04-07 | | Italian chili sauce |
| 5194 | Korean Beef Short Ribs | Trader Joe's | US | Meat | M | TODO | 2026-04-07 | | |
| 5195 | Cacio e Pepe Pasta | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5196 | Organic Açaí Bowls | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5198 | Chana Masala | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5199 | Steamed Chicken Soup Dumplings | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5201 | Mushroom & Truffle Flatbread | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5203 | Harvest Cinnamon Granola | Trader Joe's | US | Cereal | M | TODO | 2026-04-07 | | |
| 5205 | Everything But The Bagel Smoked Salmon | Trader Joe's | US | Seafood | M | TODO | 2026-04-07 | | |
| 5207 | Chicken Cilantro Mini Wontons | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5208 | Cauliflower Thins | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 5209 | Sriracha Shrimp Bowl | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5210 | Argentinian Red Shrimp | Trader Joe's | US | Seafood | M | TODO | 2026-04-07 | | |
| 5211 | Frozen Butter Croissants | Trader Joe's | US | Frozen Bakery | H | TODO | 2026-04-07 | | |
| 5212 | Chili Onion Crunch | Trader Joe's | US | Condiments | H | TODO | 2026-04-07 | | |
| 5214 | Scallion Pancakes | Trader Joe's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5215 | Honey Walnut Shrimp | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5216 | Bibimbap Bowl | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5217 | Zhoug Sauce | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | Yemeni hot sauce |
| 5219 | Danish Kringle Almond | Trader Joe's | US | Bakery | H | TODO | 2026-04-07 | | |
| 5222 | Garlic Naan | Trader Joe's | US | Bread | H | TODO | 2026-04-07 | | |
| 5223 | Buffalo Style Chicken Dip | Trader Joe's | US | Dips | M | TODO | 2026-04-07 | | |
| 5224 | Mediterranean Hummus | Trader Joe's | US | Dips | H | TODO | 2026-04-07 | | |
| 5225 | Chicken Breast Tenderloins Frozen | Trader Joe's | US | Meat | H | TODO | 2026-04-07 | | |
| 5226 | Spicy Miso Ramen Bowl | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5227 | Bambino Pizza Formaggio | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | Mini cheese pizza |
| 5228 | Frozen Chocolate Croissants | Trader Joe's | US | Frozen Bakery | H | TODO | 2026-04-07 | | |
| 5229 | Organic Grass-Fed Beef Patties | Trader Joe's | US | Meat | M | TODO | 2026-04-07 | | |
| 5230 | Turkey Bolognese | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5232 | Oat Milk Shelf Stable | Trader Joe's | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 5233 | Thai Tea Mochi Ice Cream | Trader Joe's | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 5234 | Plantain Chips | Trader Joe's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5235 | Honey Aleppo Sauce | Trader Joe's | US | Condiments | M | TODO | 2026-04-07 | | |
| 5236 | Protein Patties Plant-Based | Trader Joe's | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 5237 | Organic Stone Ground Corn Tortillas | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 5238 | White Cheddar Corn Puffs | Trader Joe's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5239 | Chicken Spring Rolls | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5243 | Everything Ciabatta Rolls | Trader Joe's | US | Bread | M | TODO | 2026-04-07 | | |
| 5247 | Banana Bread Mix | Trader Joe's | US | Baking | M | TODO | 2026-04-07 | | |
| 5248 | Mini Brie Bites | Trader Joe's | US | Dairy | M | TODO | 2026-04-07 | | |
| 5249 | Sublime Ice Cream Sandwiches | Trader Joe's | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 5250 | Jalapeño Limeade | Trader Joe's | US | Beverages | L | TODO | 2026-04-07 | | |
| 5251 | Chocolate Hummus | Trader Joe's | US | Snacks | L | TODO | 2026-04-07 | | |
| 5252 | Strawberry Lemonade | Trader Joe's | US | Beverages | M | TODO | 2026-04-07 | | |
| 5255 | Triple Berry O's Cereal | Trader Joe's | US | Cereal | M | TODO | 2026-04-07 | | |
| 5256 | Chicken Shu Mai | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5257 | Japanese Mochi Rice Nuggets | Trader Joe's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5258 | Chimichurri Rice Bowl | Trader Joe's | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 5259 | Kale & Mushroom Turnover | Trader Joe's | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 5260 | Organic Watermelon Jerky | Trader Joe's | US | Snacks | L | TODO | 2026-04-07 | | |
| 5261 | Strawberry Rhubarb Pie | Trader Joe's | US | Frozen Desserts | L | TODO | 2026-04-07 | | |
| 5263 | Chocolate Chip Scone Mix | Trader Joe's | US | Baking | L | TODO | 2026-04-07 | | |
| 5265 | Chicken Shawarma Bowl | Trader Joe's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5269 | Organic Peanut Butter Creamy | Trader Joe's | US | Spreads | M | TODO | 2026-04-07 | | |
| 5270 | Aussie Style Chocolate Licorice | Trader Joe's | US | Candy | L | TODO | 2026-04-07 | | |

## Section 100: Costco/Kirkland Signature Full Line (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5271 | Food Court Hot Dog & Soda Combo | Costco | US | Food Court | H | TODO | 2026-04-07 | | Iconic $1.50 combo |
| 5274 | Food Court Chicken Bake | Costco | US | Food Court | H | TODO | 2026-04-07 | | |
| 5275 | Food Court Açaí Bowl | Costco | US | Food Court | H | TODO | 2026-04-07 | | |
| 5276 | Food Court Mango Smoothie | Costco | US | Food Court | M | TODO | 2026-04-07 | | |
| 5277 | Food Court Churro | Costco | US | Food Court | H | TODO | 2026-04-07 | | |
| 5282 | Protein Bars Chocolate Brownie | Kirkland Signature | US | Protein Bars | H | TODO | 2026-04-07 | | |
| 5286 | Wild Caught Alaskan Salmon Fillets | Kirkland Signature | US | Seafood | H | TODO | 2026-04-07 | | |
| 5287 | Boneless Skinless Chicken Breast | Kirkland Signature | US | Meat | H | TODO | 2026-04-07 | | |
| 5288 | Organic Cage-Free Large Eggs | Kirkland Signature | US | Dairy | H | TODO | 2026-04-07 | | |
| 5290 | Mixed Nuts Salted | Kirkland Signature | US | Snacks | H | TODO | 2026-04-07 | | |
| 5295 | Organic Peanut Butter | Kirkland Signature | US | Spreads | H | TODO | 2026-04-07 | | |
| 5297 | Frozen Organic Blueberries | Kirkland Signature | US | Frozen Fruit | H | TODO | 2026-04-07 | | |
| 5298 | Frozen Organic Strawberries | Kirkland Signature | US | Frozen Fruit | H | TODO | 2026-04-07 | | |
| 5299 | Frozen Mixed Berry Blend | Kirkland Signature | US | Frozen Fruit | H | TODO | 2026-04-07 | | |
| 5300 | Frozen Stir Fry Vegetables | Kirkland Signature | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 5302 | Butter Croissants 12-Pack | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 5303 | Blueberry Muffins 6-Pack | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 5304 | Everything Bagels 6-Pack | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 5305 | Cheese Danish 6-Pack | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 5306 | Half Sheet Cake White | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 5307 | Half Sheet Cake Chocolate | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 5308 | Tiramisu Bar Cake | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 5310 | Whole Chicken Wings | Kirkland Signature | US | Meat | M | TODO | 2026-04-07 | | |
| 5311 | Pesto Genovese | Kirkland Signature | US | Condiments | M | TODO | 2026-04-07 | | |
| 5312 | Organic Hummus Singles | Kirkland Signature | US | Dips | M | TODO | 2026-04-07 | | |
| 5313 | Cashew Clusters | Kirkland Signature | US | Snacks | M | TODO | 2026-04-07 | | |
| 5316 | Organic Chicken Stock | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 5317 | Canned Albacore Tuna | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 5318 | Grass-Fed Beef Patties | Kirkland Signature | US | Meat | H | TODO | 2026-04-07 | | |
| 5321 | Organic Quinoa | Kirkland Signature | US | Grains | M | TODO | 2026-04-07 | | |
| 5323 | Walnut Halves | Kirkland Signature | US | Snacks | M | TODO | 2026-04-07 | | |
| 5324 | Dried Mangoes | Kirkland Signature | US | Snacks | H | TODO | 2026-04-07 | | |
| 5328 | Organic Tomato Sauce | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 5329 | Bath Tissue (just kidding) Raspberry Crumble Cookies | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 5330 | Cheese Flight Tray | Kirkland Signature | US | Dairy | M | TODO | 2026-04-07 | | |
| 5331 | Marinated Artichoke Hearts | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 5335 | Master Carve Half Ham | Kirkland Signature | US | Deli | M | TODO | 2026-04-07 | | |
| 5336 | Parmigiano Reggiano Wedge | Kirkland Signature | US | Dairy | H | TODO | 2026-04-07 | | |
| 5338 | Mini Chocolate Chip Cookies Tub | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 5341 | Bath Tissue Mango Habanero Salsa | Kirkland Signature | US | Condiments | M | TODO | 2026-04-07 | | |
| 5343 | Vanilla Almond Milk | Kirkland Signature | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 5345 | Ground Turkey | Kirkland Signature | US | Meat | M | TODO | 2026-04-07 | | |
| 5346 | Atlantic Salmon Fillets | Kirkland Signature | US | Seafood | H | TODO | 2026-04-07 | | |
| 5348 | Organic Diced Tomatoes | Kirkland Signature | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 5350 | Chocolate Cake Bakery | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 5351 | Tuxedo Mousse Cake | Kirkland Signature | US | Bakery | H | TODO | 2026-04-07 | | |
| 5352 | Cinnamon Pull-Apart Bread | Kirkland Signature | US | Bakery | M | TODO | 2026-04-07 | | |
| 5353 | Organic Ground Beef 85/15 | Kirkland Signature | US | Meat | H | TODO | 2026-04-07 | | |
| 5354 | Vanilla Greek Yogurt | Kirkland Signature | US | Dairy | M | TODO | 2026-04-07 | | |
| 5355 | Organic Strawberry Spread | Kirkland Signature | US | Spreads | M | TODO | 2026-04-07 | | |
| 5356 | Raw Almonds 3lb | Kirkland Signature | US | Snacks | H | TODO | 2026-04-07 | | |
| 5357 | Pistachio Kernels | Kirkland Signature | US | Snacks | M | TODO | 2026-04-07 | | |
| 5362 | Croissant Sandwich Tray | Kirkland Signature | US | Deli | M | TODO | 2026-04-07 | | |
| 5364 | Frozen Acai Packets | Kirkland Signature | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 5365 | Honey Bear 5lb | Kirkland Signature | US | Sweetener | M | TODO | 2026-04-07 | | |
| 5366 | Organic Fruit & Veggie Pouches | Kirkland Signature | US | Baby Food | M | TODO | 2026-04-07 | | |
| 5367 | Protein Shake Chocolate 18-Pack | Kirkland Signature | US | Beverages | H | TODO | 2026-04-07 | | |
| 5368 | Protein Shake Vanilla 18-Pack | Kirkland Signature | US | Beverages | H | TODO | 2026-04-07 | | |

## Section 101: Aldi Exclusive Products (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5374 | Garlic Breadsticks | Mama Cozzi's | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 5377 | White Cheddar Popcorn | Clancy's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5379 | Pretzel Sticks | Clancy's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5382 | Kettle Chips Sea Salt | Clancy's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5386 | Protein Shake Chocolate | Elevation | US | Beverages | M | TODO | 2026-04-07 | | |
| 5387 | Energy Bar Fruit & Nut | Elevation | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 5388 | Chicken Patties Frozen | Fit & Active | US | Frozen Meals | M | TODO | 2026-04-07 | | Aldi brand |
| 5389 | Turkey Burgers Frozen | Fit & Active | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5390 | Light Yogurt Strawberry | Fit & Active | US | Dairy | M | TODO | 2026-04-07 | | |
| 5391 | Cheese Sticks Mozzarella | Fit & Active | US | Dairy | M | TODO | 2026-04-07 | | |
| 5392 | Organic Pasta Sauce Marinara | Simply Nature | US | Condiments | M | TODO | 2026-04-07 | | Aldi brand |
| 5393 | Organic Salsa Medium | Simply Nature | US | Condiments | M | TODO | 2026-04-07 | | |
| 5394 | Organic Applesauce Pouches | Simply Nature | US | Snacks | M | TODO | 2026-04-07 | | |
| 5395 | Organic Peanut Butter Creamy | Simply Nature | US | Spreads | M | TODO | 2026-04-07 | | |
| 5399 | Aged Reserve White Cheddar | Specially Selected | US | Dairy | M | TODO | 2026-04-07 | | Aldi premium |
| 5401 | Pesto Genovese | Specially Selected | US | Condiments | M | TODO | 2026-04-07 | | |
| 5402 | Ravioli Mushroom Truffle | Specially Selected | US | Pasta | M | TODO | 2026-04-07 | | |
| 5404 | Gluten Free Brownie Mix | liveGfree | US | Baking | M | TODO | 2026-04-07 | | Aldi GF brand |
| 5405 | Gluten Free Pizza Crust | liveGfree | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5406 | Gluten Free Bread Multigrain | liveGfree | US | Bread | M | TODO | 2026-04-07 | | |
| 5407 | Gluten Free Mac & Cheese | liveGfree | US | Pasta | M | TODO | 2026-04-07 | | |
| 5408 | Gluten Free Crackers Sea Salt | liveGfree | US | Snacks | M | TODO | 2026-04-07 | | |
| 5410 | 2% Milk Gallon | Friendly Farms | US | Dairy | H | TODO | 2026-04-07 | | |
| 5416 | Frozen Stir Fry Vegetables | Season's Choice | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 5418 | Frozen Edamame | Season's Choice | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 5419 | Donut Shop K-Cup Medium Roast | Barissimo | US | Beverages | M | TODO | 2026-04-07 | | Aldi coffee |
| 5420 | French Roast Ground Coffee | Barissimo | US | Beverages | M | TODO | 2026-04-07 | | |
| 5421 | Colombian Ground Coffee | Barissimo | US | Beverages | M | TODO | 2026-04-07 | | |
| 5422 | Bavarian Soft Pretzels | Deutsche Küche | US | Frozen Snacks | M | TODO | 2026-04-07 | | German items |
| 5423 | Pork Schnitzel | Deutsche Küche | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5424 | German Chocolate Assortment | Deutsche Küche | US | Candy | M | TODO | 2026-04-07 | | |
| 5425 | Stollen Bites | Deutsche Küche | US | Bakery | L | TODO | 2026-04-07 | | Seasonal |
| 5426 | Entertainer Crackers Water | Savoritz | US | Snacks | M | TODO | 2026-04-07 | | Aldi crackers |
| 5427 | Buttery Round Crackers | Savoritz | US | Snacks | M | TODO | 2026-04-07 | | |
| 5428 | Woven Wheat Crackers | Savoritz | US | Snacks | M | TODO | 2026-04-07 | | |
| 5432 | Yellow Cake Mix | Baker's Corner | US | Baking | M | TODO | 2026-04-07 | | |
| 5433 | Brownie Mix Fudge | Baker's Corner | US | Baking | M | TODO | 2026-04-07 | | |
| 5434 | Organic Baby Spinach | Little Salad Bar | US | Produce | M | TODO | 2026-04-07 | | Aldi produce |
| 5437 | Oat Milk Original | Friendly Farms | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 5438 | Frozen Berry Medley | Season's Choice | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 5440 | Chicken Breast Tenders Frozen | Kirkwood | US | Frozen Meals | H | TODO | 2026-04-07 | | Aldi chicken brand |
| 5442 | Hot Dogs Beef | Parkview | US | Meat | M | TODO | 2026-04-07 | | Aldi meat brand |
| 5443 | Bratwurst Original | Parkview | US | Meat | M | TODO | 2026-04-07 | | |
| 5445 | Bacon Hickory Smoked | Appleton Farms | US | Meat | H | TODO | 2026-04-07 | | Aldi meat brand |
| 5447 | Sliced Ham Honey Deli | Appleton Farms | US | Deli | M | TODO | 2026-04-07 | | |
| 5448 | Frozen Cauliflower Pizza | Earth Grown | US | Plant-Based | M | TODO | 2026-04-07 | | Aldi plant-based |
| 5449 | Veggie Burgers Black Bean | Earth Grown | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 5450 | Chicken-Less Tenders | Earth Grown | US | Plant-Based | M | TODO | 2026-04-07 | | |

## Section 102: Target Good & Gather / Favorite Day (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5451 | Boneless Skinless Chicken Breast | Good & Gather | US | Meat | H | TODO | 2026-04-07 | | Target brand |
| 5453 | Original Hummus | Good & Gather | US | Dips | M | TODO | 2026-04-07 | | |
| 5454 | Medium Salsa | Good & Gather | US | Condiments | M | TODO | 2026-04-07 | | |
| 5455 | Marinara Pasta Sauce | Good & Gather | US | Condiments | M | TODO | 2026-04-07 | | |
| 5457 | Turkey & Cheese Snack Kit | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 5458 | Organic Cage-Free Eggs | Good & Gather | US | Dairy | H | TODO | 2026-04-07 | | |
| 5462 | Organic Baby Spinach | Good & Gather | US | Produce | M | TODO | 2026-04-07 | | |
| 5466 | Organic Peanut Butter Creamy | Good & Gather | US | Spreads | M | TODO | 2026-04-07 | | |
| 5467 | Sea Salt Popcorn | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 5470 | Frozen Mixed Berry Blend | Good & Gather | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 5473 | Protein Snack Box | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 5474 | Organic Apple Sauce Pouches | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 5477 | Frozen Cheese Ravioli | Good & Gather | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5479 | Honey Roasted Cashews | Good & Gather | US | Snacks | M | TODO | 2026-04-07 | | |
| 5481 | Chocolate Chip Cookies Soft Baked | Favorite Day | US | Cookies | H | TODO | 2026-04-07 | | Target brand |
| 5482 | Vanilla Bean Ice Cream | Favorite Day | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 5483 | Chocolate Fudge Brownie Ice Cream | Favorite Day | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 5484 | Birthday Cake Ice Cream | Favorite Day | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 5487 | Sour Gummy Worms | Favorite Day | US | Candy | M | TODO | 2026-04-07 | | |
| 5488 | Chocolate Chip Muffins 4-Pack | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 5489 | Double Chocolate Cake | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 5490 | Brownie Bites | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 5491 | Butter Croissants | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 5492 | Sugar Cookies Frosted | Favorite Day | US | Cookies | M | TODO | 2026-04-07 | | |
| 5493 | Peanut Butter Cups | Favorite Day | US | Candy | M | TODO | 2026-04-07 | | |
| 5495 | Cookie Dough Bites | Favorite Day | US | Candy | M | TODO | 2026-04-07 | | |
| 5497 | Mint Chip Ice Cream | Favorite Day | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 5498 | Strawberry Cheesecake Ice Cream | Favorite Day | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 5499 | Lemon Cake | Favorite Day | US | Bakery | L | TODO | 2026-04-07 | | |
| 5500 | Cinnamon Coffee Cake | Favorite Day | US | Bakery | L | TODO | 2026-04-07 | | |
| 5501 | Blueberry Muffins 4-Pack | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 5503 | Cheese Danish | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 5504 | Caramel Corn | Favorite Day | US | Snacks | M | TODO | 2026-04-07 | | |
| 5506 | Chocolate Covered Pretzels | Favorite Day | US | Candy | M | TODO | 2026-04-07 | | |
| 5507 | Assorted Macarons | Favorite Day | US | Bakery | M | TODO | 2026-04-07 | | |
| 5508 | Frozen Fruit Bars Strawberry | Favorite Day | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 5509 | Frozen Fruit Bars Mango | Favorite Day | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 5510 | Ice Cream Sandwiches Vanilla | Favorite Day | US | Frozen Desserts | M | TODO | 2026-04-07 | | |

## Section 103: Walmart Great Value Full Range (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5511 | Canned Whole Kernel Corn | Great Value | US | Canned Goods | H | TODO | 2026-04-07 | | Walmart brand |
| 5520 | Frozen Waffles Buttermilk | Great Value | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 5523 | Cheddar Goldfish-Style Crackers | Great Value | US | Snacks | M | TODO | 2026-04-07 | | |
| 5525 | 2% Reduced Fat Milk | Great Value | US | Dairy | H | TODO | 2026-04-07 | | |
| 5526 | Large White Eggs 18ct | Great Value | US | Dairy | H | TODO | 2026-04-07 | | |
| 5530 | Spaghetti Pasta | Great Value | US | Pasta | H | TODO | 2026-04-07 | | |
| 5532 | Marinara Pasta Sauce | Great Value | US | Condiments | M | TODO | 2026-04-07 | | |
| 5533 | Tomato Ketchup | Great Value | US | Condiments | H | TODO | 2026-04-07 | | |
| 5535 | Real Mayonnaise | Great Value | US | Condiments | M | TODO | 2026-04-07 | | |
| 5537 | Honey Nut Toasted Oats Cereal | Great Value | US | Cereal | H | TODO | 2026-04-07 | | |
| 5539 | Fruit Rings Cereal | Great Value | US | Cereal | M | TODO | 2026-04-07 | | |
| 5542 | Purified Drinking Water 24-Pack | Great Value | US | Beverages | H | TODO | 2026-04-07 | | |
| 5544 | Granulated Sugar 4lb | Great Value | US | Baking | M | TODO | 2026-04-07 | | |
| 5546 | Creamy Peanut Butter | Great Value | US | Spreads | H | TODO | 2026-04-07 | | |
| 5548 | Chunk Light Tuna in Water | Great Value | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 5552 | Mac & Cheese Original | Great Value | US | Pasta | H | TODO | 2026-04-07 | | |
| 5560 | Long Grain White Rice 5lb | Great Value | US | Grains | M | TODO | 2026-04-07 | | |
| 5563 | Hot Dog Buns 8ct | Great Value | US | Bread | M | TODO | 2026-04-07 | | |
| 5564 | Hamburger Buns 8ct | Great Value | US | Bread | M | TODO | 2026-04-07 | | |
| 5567 | Honey 12oz | Great Value | US | Sweetener | M | TODO | 2026-04-07 | | |
| 5568 | Pancake Mix Buttermilk | Great Value | US | Baking | M | TODO | 2026-04-07 | | |
| 5569 | Maple Flavored Syrup | Great Value | US | Condiments | M | TODO | 2026-04-07 | | |

## Section 104: HelloFresh & Meal Kit Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5571 | Firecracker Meatballs | HelloFresh | US | Meal Kit | H | TODO | 2026-04-07 | | Popular recipe |
| 5572 | Creamy Dijon Chicken | HelloFresh | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 5573 | One-Pan Southwest Chicken | HelloFresh | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 5574 | Parmesan Crusted Chicken | HelloFresh | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 5575 | Teriyaki Beef Stir-Fry | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5576 | Figgy Balsamic Pork Chops | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5578 | Thai Coconut Curry Chicken | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5579 | Garlic Herb Butter Steak | HelloFresh | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 5580 | Tuscan Heat Spiced Chicken | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5581 | Crispy Cheddar Chicken | HelloFresh | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5582 | Seared Salmon & Salsa Verde | Blue Apron | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 5583 | Spiced Lamb Meatballs | Blue Apron | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5584 | Crispy Chicken Thighs | Blue Apron | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5585 | Seared Steaks & Miso Butter | Blue Apron | US | Meal Kit | H | TODO | 2026-04-07 | | |
| 5586 | Pan-Seared Cod | Blue Apron | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5588 | BBQ Pork Tacos | EveryPlate | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5589 | Cheesy Beef Pasta Bake | EveryPlate | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5590 | Honey Garlic Chicken | EveryPlate | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5591 | Garlic Butter Shrimp | Home Chef | US | Meal Kit | H | TODO | 2026-04-07 | | Kroger partnership |
| 5592 | Crispy Chicken Milanese | Home Chef | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5594 | Steak Fajita Bowl | Home Chef | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5595 | Keto Chicken Margherita | Factor | US | Prepared Meals | H | TODO | 2026-04-07 | | Ready-to-heat |
| 5596 | Keto Bacon Cheeseburger Bowl | Factor | US | Prepared Meals | H | TODO | 2026-04-07 | | |
| 5598 | Protein Plus Grilled Steak | Factor | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5599 | Vegan & Veggie Coconut Curry | Factor | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5600 | Chef's Choice Salmon Bowl | Factor | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5601 | Steak Peppercorn Prepared | Freshly | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5602 | Chicken Pesto Penne | Freshly | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5603 | Buffalo Chicken Bowl | Freshly | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5604 | Organic Grass-Fed Beef Bowl | Trifecta | US | Prepared Meals | M | TODO | 2026-04-07 | | Fitness-focused |
| 5605 | Grilled Chicken & Veggies | Trifecta | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5607 | Grass-Fed Steak Bowl | Territory Foods | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5609 | Pan-Seared Salmon Bowl | CookUnity | US | Prepared Meals | M | TODO | 2026-04-07 | | Chef-crafted |
| 5611 | Chicken Tikka Bowl | CookUnity | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5613 | Black Bean Burger Kit | Hungryroot | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 5614 | Almond Chickpea Cookie Dough | Hungryroot | US | Snacks | L | TODO | 2026-04-07 | | |
| 5615 | Strawberry + Cherry Smoothie | Daily Harvest | US | Smoothies | H | TODO | 2026-04-07 | | |
| 5616 | Mint + Cacao Smoothie | Daily Harvest | US | Smoothies | M | TODO | 2026-04-07 | | |
| 5620 | Banana + Greens Smoothie | Daily Harvest | US | Smoothies | H | TODO | 2026-04-07 | | |
| 5621 | Flatbread Kabocha + Sage | Daily Harvest | US | Flatbreads | M | TODO | 2026-04-07 | | |
| 5622 | Chocolate + Blueberry Oat Bowl | Daily Harvest | US | Bowls | M | TODO | 2026-04-07 | | |
| 5623 | Broccoli + Cheese Flatbread | Daily Harvest | US | Flatbreads | M | TODO | 2026-04-07 | | |
| 5624 | Ginger + Turmeric Latte | Daily Harvest | US | Beverages | L | TODO | 2026-04-07 | | |
| 5625 | Mango + Papaya Smoothie | Daily Harvest | US | Smoothies | M | TODO | 2026-04-07 | | |
| 5626 | Acai + Cherry Smoothie | Daily Harvest | US | Smoothies | M | TODO | 2026-04-07 | | |
| 5628 | Lemongrass + Coconut Curry | Daily Harvest | US | Bowls | M | TODO | 2026-04-07 | | |
| 5630 | Cinnamon + Banana Oat Bowl | Daily Harvest | US | Bowls | M | TODO | 2026-04-07 | | |

## Section 105: Weight Management Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5632 | Smart Ones Three Cheese Ziti Marinara | WW (Weight Watchers) | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5633 | Smart Ones Santa Fe Style Rice & Beans | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5634 | Smart Ones Chicken Enchilada Suiza | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5635 | Smart Ones Broccoli & Cheddar Potatoes | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5636 | Smart Ones Meatloaf | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5637 | WW Protein Stix Chocolate Peanut Butter | WW (Weight Watchers) | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 5638 | WW Protein Stix Cookies & Cream | WW (Weight Watchers) | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 5639 | WW Chocolate Cake Snack Bar | WW (Weight Watchers) | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 5640 | WW Ice Cream Bars Chocolate Fudge | WW (Weight Watchers) | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 5641 | WW Ice Cream Bars Salted Caramel | WW (Weight Watchers) | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 5643 | Nutrisystem Hamburger | Nutrisystem | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5645 | Nutrisystem Thick Crust Pizza | Nutrisystem | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5646 | Nutrisystem Chocolate Brownie | Nutrisystem | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 5649 | Nutrisystem Meatball Parmesan Melt | Nutrisystem | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5650 | Nutrisystem Chocolate Shake | Nutrisystem | US | Beverages | M | TODO | 2026-04-07 | | |
| 5651 | Nutrisystem Rotini & Meatballs | Nutrisystem | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5652 | Jenny Craig Chicken Fettuccine | Jenny Craig | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5653 | Jenny Craig Turkey Burger | Jenny Craig | US | Prepared Meals | M | TODO | 2026-04-07 | | |
| 5655 | Jenny Craig Chocolate Lava Cake | Jenny Craig | US | Snacks | L | TODO | 2026-04-07 | | |
| 5656 | SlimFast Advanced Nutrition Chocolate Shake | SlimFast | US | Beverages | H | TODO | 2026-04-07 | | |
| 5657 | SlimFast Advanced Nutrition Vanilla Shake | SlimFast | US | Beverages | H | TODO | 2026-04-07 | | |
| 5658 | SlimFast Advanced Nutrition Caramel Shake | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 5659 | SlimFast Keto Fat Bomb Chocolate Shake | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 5660 | SlimFast Keto Fat Bomb Peanut Butter Cup | SlimFast | US | Snacks | M | TODO | 2026-04-07 | | |
| 5661 | SlimFast Bake Shop Chocolatey Crispy Bar | SlimFast | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 5662 | SlimFast Snack Bites Peanut Butter Chocolate | SlimFast | US | Snacks | M | TODO | 2026-04-07 | | |
| 5663 | SlimFast Original Shake Powder Chocolate | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 5664 | Optavia Fueling Chocolate Shake | Optavia | US | Beverages | M | TODO | 2026-04-07 | | |
| 5665 | Optavia Fueling Cinnamon Crunchy O's | Optavia | US | Cereal | L | TODO | 2026-04-07 | | |
| 5666 | Optavia Fueling Zesty Cheddar Cracker | Optavia | US | Snacks | L | TODO | 2026-04-07 | | |
| 5667 | Optavia Fueling Essential Bar Drizzled Chocolate | Optavia | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 5668 | Optavia Fueling Wild Berry Shake | Optavia | US | Beverages | L | TODO | 2026-04-07 | | |
| 5669 | Optavia Fueling Rustic Tomato Herb Penne | Optavia | US | Prepared Meals | L | TODO | 2026-04-07 | | |
| 5670 | Optavia Fueling Mac & Cheese | Optavia | US | Prepared Meals | L | TODO | 2026-04-07 | | |
| 5671 | Medifast Chocolate Shake | Medifast | US | Beverages | L | TODO | 2026-04-07 | | |
| 5672 | Medifast Dutch Chocolate Shake | Medifast | US | Beverages | L | TODO | 2026-04-07 | | |
| 5673 | Medifast Caramel Crunch Bar | Medifast | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 5674 | Smart Ones Chicken Oriental | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5675 | Smart Ones Lasagna with Meat Sauce | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5676 | Smart Ones Pasta with Swedish Meatballs | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5677 | SlimFast Diabetic Weight Loss Chocolate Shake | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 5678 | SlimFast High Protein Shake Strawberry | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 5680 | Nutrisystem Cinnamon Raisin Baked Bar | Nutrisystem | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 5681 | Jenny Craig Anytime Bar Lemon Meringue | Jenny Craig | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 5682 | Jenny Craig Chicken Street Tacos | Jenny Craig | US | Prepared Meals | L | TODO | 2026-04-07 | | |
| 5684 | Smart Ones Chicken Mesquite | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5685 | SlimFast Keto Meal Bar Whipped Triple Chocolate | SlimFast | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 5686 | SlimFast Original Shake Strawberry Cream | SlimFast | US | Beverages | M | TODO | 2026-04-07 | | |
| 5687 | WW Popcorn Sea Salt | WW (Weight Watchers) | US | Snacks | M | TODO | 2026-04-07 | | |
| 5688 | WW Baked Cheese Crackers | WW (Weight Watchers) | US | Snacks | M | TODO | 2026-04-07 | | |
| 5689 | WW Peanut Butter Chocolate Snack Bar | WW (Weight Watchers) | US | Snack Bars | M | TODO | 2026-04-07 | | |

## Section 106: More Frozen Meal Brands (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5691 | Lasagna with Meat & Sauce Family Size | Stouffer's | US | Frozen Meals | H | TODO | 2026-04-07 | | Classic bestseller |
| 5692 | Macaroni & Cheese Family Size | Stouffer's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5696 | Salisbury Steak | Stouffer's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5697 | Vegetable Lasagna | Stouffer's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5699 | Turkey Pot Pie | Marie Callender's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5700 | Beef Pot Pie | Marie Callender's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5702 | Country Fried Chicken Bowl | Marie Callender's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5704 | Power Bowl Chicken Feta & Farro | Healthy Choice | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5705 | Power Bowl Korean Beef | Healthy Choice | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5706 | Power Bowl Adobo Chicken | Healthy Choice | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5707 | Power Bowl Cauliflower Tikka Masala | Healthy Choice | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5708 | Steamer Grilled Chicken Marinara | Healthy Choice | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5711 | Cafe Steamers Chicken Teriyaki | Lean Cuisine | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5712 | Cafe Steamers Herb Roasted Chicken | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5713 | Features Chicken Enchilada Suiza | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5714 | Features Vermont White Cheddar Mac | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5718 | Salisbury Steak Dinner | Banquet | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5719 | Turkey Dinner | Banquet | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5720 | Fried Chicken Dinner | Banquet | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5721 | Mexican Style Dinner | Banquet | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5722 | Country Fried Steak XXL Dinner | Hungry-Man | US | Frozen Meals | H | TODO | 2026-04-07 | | Large portions |
| 5723 | Boneless Fried Chicken Dinner | Hungry-Man | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5724 | Beer Battered Chicken Dinner | Hungry-Man | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5726 | Protein Bowl Southwest Style | Bird's Eye | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5727 | Steamfresh Broccoli Cuts | Bird's Eye | US | Frozen Veg | H | TODO | 2026-04-07 | | |
| 5728 | Steamfresh Mixed Vegetables | Bird's Eye | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 5729 | Cauliflower Wings Buffalo | Green Giant | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5730 | Veggie Tots Broccoli & Cheese | Green Giant | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 5731 | Riced Cauliflower Original | Green Giant | US | Frozen Veg | H | TODO | 2026-04-07 | | |
| 5732 | Cauliflower Pizza Crust | Green Giant | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5733 | Veggie Spirals Zucchini | Green Giant | US | Frozen Veg | M | TODO | 2026-04-07 | | |
| 5734 | Cheese Enchilada Whole Meal | Amy's Kitchen | US | Frozen Meals | H | TODO | 2026-04-07 | | Organic brand |
| 5735 | Vegetable Lasagna | Amy's Kitchen | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5736 | Bean & Rice Burrito Non-Dairy | Amy's Kitchen | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5737 | Mac & Cheese | Amy's Kitchen | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5742 | Lamb Saag Bowl | Saffron Road | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 5744 | Awesome Burger | Sweet Earth | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 5745 | Mindful Chik'n | Sweet Earth | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 5746 | Truffle Parmesan Street Burritos | EVOL | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5747 | Chicken Enchilada Bake | EVOL | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5748 | White Cheddar Mac & Cheese | Devour | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5749 | Buffalo Chicken Mac & Cheese | Devour | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5750 | Chicken Carbonara | Devour | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5753 | Meatloaf Dinner | Boston Market | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5755 | Cilantro Lime Chicken Bowl | Kevin's Natural Foods | US | Frozen Meals | H | TODO | 2026-04-07 | | Clean ingredient |
| 5756 | Korean BBQ Chicken | Kevin's Natural Foods | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 5757 | Thai Coconut Chicken | Kevin's Natural Foods | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5758 | Lemongrass Chicken | Kevin's Natural Foods | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5759 | Chicken Enchilada Meal | Real Good Foods | US | Frozen Meals | M | TODO | 2026-04-07 | | Low-carb |
| 5761 | Stuffed Chicken Bacon & Cheese | Real Good Foods | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5762 | Cauliflower Mac & Cheese Bowl | Tattooed Chef | US | Frozen Meals | M | TODO | 2026-04-07 | | Plant-based |
| 5765 | Riced Cauliflower Stir Fry | Tattooed Chef | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5766 | Plant-Based Chik'n Nuggets | Alpha Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 5767 | Plant-Based Mexichik'n Burrito | Alpha Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 5768 | Plant-Based Pizza Puffs | Alpha Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 5769 | Meatball Parmesan Bowl | Stouffer's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5771 | Three Meat & Cheese Flatbread Melts | Stouffer's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5772 | Philly Style Cheesesteak | Stouffer's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5775 | Power Bowl Unwrapped Burrito | Healthy Choice | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5776 | Cafe Steamers Meatball Marinara | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5777 | Features Mango Chicken Sriracha | Lean Cuisine | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5779 | Creamy Tomato Basil Soup | Amy's Kitchen | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 5780 | Indian Mattar Paneer | Amy's Kitchen | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5781 | Chicken & Vegetable Steamed Dumplings | Bibigo | US | Frozen Meals | H | TODO | 2026-04-07 | | Korean brand |
| 5782 | Beef Bulgogi Mandu | Bibigo | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5783 | Luvo Roasted Cauliflower Mac | Luvo | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 5787 | Plant-Based Chik'n Patties | Alpha Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 5788 | Falafel Bowl | Saffron Road | US | Frozen Meals | L | TODO | 2026-04-07 | | |
| 5789 | Roasted Turkey & Vegetables | Boston Market | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 5790 | Smart Ones Pepper Steak | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |

## Section 107: Cereal Brands Complete (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5793 | Apple Cinnamon Cheerios | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5794 | Multi Grain Cheerios | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5795 | Cheerios Protein Oats & Honey | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5799 | Trix | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5800 | Reese's Puffs | General Mills | US | Cereal | H | TODO | 2026-04-07 | | |
| 5801 | Rice Chex | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5802 | Corn Chex | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5803 | Wheat Chex | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5804 | Chocolate Chex | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5815 | Special K Protein | Kellogg's | US | Cereal | M | TODO | 2026-04-07 | | |
| 5816 | Corn Pops | Kellogg's | US | Cereal | M | TODO | 2026-04-07 | | |
| 5819 | Honey Bunches of Oats with Almonds | Post | US | Cereal | H | TODO | 2026-04-07 | | |
| 5820 | Honey Bunches of Oats Honey Roasted | Post | US | Cereal | H | TODO | 2026-04-07 | | |
| 5821 | Great Grains Banana Nut Crunch | Post | US | Cereal | M | TODO | 2026-04-07 | | |
| 5825 | Alpha-Bits | Post | US | Cereal | L | TODO | 2026-04-07 | | |
| 5827 | Instant Oatmeal Apple Cinnamon | Quaker | US | Cereal | H | TODO | 2026-04-07 | | |
| 5828 | Instant Oatmeal Peaches & Cream | Quaker | US | Cereal | M | TODO | 2026-04-07 | | |
| 5829 | Instant Oatmeal Dinosaur Eggs | Quaker | US | Cereal | M | TODO | 2026-04-07 | | |
| 5833 | Cap'n Crunch Crunch Berries | Quaker | US | Cereal | H | TODO | 2026-04-07 | | |
| 5835 | Heritage Flakes | Nature's Path | US | Cereal | M | TODO | 2026-04-07 | | Organic |
| 5836 | Sunrise Crunchy Maple | Nature's Path | US | Cereal | M | TODO | 2026-04-07 | | |
| 5837 | Pumpkin Raisin Crunch | Nature's Path | US | Cereal | L | TODO | 2026-04-07 | | |
| 5838 | EnviroKidz Panda Puffs | Nature's Path | US | Cereal | M | TODO | 2026-04-07 | | |
| 5839 | Puffins Original | Barbara's | US | Cereal | M | TODO | 2026-04-07 | | |
| 5840 | Puffins Peanut Butter | Barbara's | US | Cereal | M | TODO | 2026-04-07 | | |
| 5841 | Organic Cinnamon Crunch | Cascadian Farm | US | Cereal | M | TODO | 2026-04-07 | | |
| 5842 | Organic Honey Oat Granola | Cascadian Farm | US | Cereal | M | TODO | 2026-04-07 | | |
| 5843 | Organic Purely O's | Cascadian Farm | US | Cereal | M | TODO | 2026-04-07 | | |
| 5844 | Instant Oatmeal Original | Quaker | US | Cereal | H | TODO | 2026-04-07 | | |
| 5845 | Old Fashioned Oats | Quaker | US | Cereal | H | TODO | 2026-04-07 | | |
| 5849 | Golden Grahams | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5850 | Cookie Crisp | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5851 | Kix Original | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5852 | Total Whole Grain | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5853 | Wheaties | General Mills | US | Cereal | M | TODO | 2026-04-07 | | Breakfast of Champions |
| 5855 | Smart Start Original | Kellogg's | US | Cereal | L | TODO | 2026-04-07 | | |
| 5856 | Instant Oatmeal Blueberries & Cream | Quaker | US | Cereal | M | TODO | 2026-04-07 | | |
| 5857 | Instant Oatmeal Honey & Almonds | Quaker | US | Cereal | M | TODO | 2026-04-07 | | |
| 5858 | Quick 1-Minute Oats | Quaker | US | Cereal | H | TODO | 2026-04-07 | | |
| 5859 | Organic Flax Plus Multibran | Nature's Path | US | Cereal | L | TODO | 2026-04-07 | | |
| 5860 | Honey Smacks | Kellogg's | US | Cereal | M | TODO | 2026-04-07 | | |
| 5862 | Grape-Nuts Flakes | Post | US | Cereal | L | TODO | 2026-04-07 | | |
| 5864 | Shredded Wheat Original | Post | US | Cereal | M | TODO | 2026-04-07 | | |
| 5865 | S'mores Cereal | General Mills | US | Cereal | L | TODO | 2026-04-07 | | |
| 5866 | Cinnamon Cheerios | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5867 | Blueberry Cheerios | General Mills | US | Cereal | M | TODO | 2026-04-07 | | |
| 5869 | Crispix | Kellogg's | US | Cereal | M | TODO | 2026-04-07 | | |
| 5870 | Muesli Blueberry Pecan | Post | US | Cereal | L | TODO | 2026-04-07 | | |

## Section 108: Yogurt & Dairy Brands Complete (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5873 | Activia Blueberry Probiotic Yogurt | Dannon | US | Dairy | M | TODO | 2026-04-07 | | |
| 5874 | Light & Fit Greek Vanilla | Dannon | US | Dairy | H | TODO | 2026-04-07 | | |
| 5875 | Light & Fit Greek Strawberry | Dannon | US | Dairy | H | TODO | 2026-04-07 | | |
| 5876 | Light & Fit Original Peach | Dannon | US | Dairy | M | TODO | 2026-04-07 | | |
| 5882 | Yoplait Light Harvest Peach | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 5883 | Yoplait Light Blueberry Patch | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 5884 | Go-Gurt Strawberry Splash | Yoplait | US | Dairy | H | TODO | 2026-04-07 | | Kids squeezable |
| 5885 | Go-Gurt Berry | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 5886 | Oui French Style Vanilla | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | Glass jar |
| 5887 | Oui French Style Strawberry | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 5890 | Noosa Blueberry | Noosa | US | Dairy | M | TODO | 2026-04-07 | | |
| 5892 | La Yogurt Probiotic Strawberry | La Yogurt | US | Dairy | M | TODO | 2026-04-07 | | |
| 5893 | Brown Cow Cream Top Vanilla | Brown Cow | US | Dairy | M | TODO | 2026-04-07 | | |
| 5895 | Stonyfield Organic Vanilla | Stonyfield | US | Dairy | M | TODO | 2026-04-07 | | |
| 5896 | Wallaby Organic Greek Plain | Wallaby | US | Dairy | M | TODO | 2026-04-07 | | |
| 5897 | Almond Milk Yogurt Vanilla | Kite Hill | US | Dairy Alt | M | TODO | 2026-04-07 | | Plant-based |
| 5899 | Dairy-Free Yogurt Strawberry | Silk | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 5900 | Dairy-Free Yogurt Vanilla | Silk | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 5901 | Coconut Milk Yogurt Vanilla | So Delicious | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 5902 | Coconut Milk Yogurt Strawberry Banana | So Delicious | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 5903 | Cashewmilk Yogurt Vanilla Bean | Forager | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 5904 | Cashewmilk Yogurt Blueberry | Forager | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 5906 | Low Fat Kefir Strawberry | Lifeway | US | Dairy | M | TODO | 2026-04-07 | | |
| 5907 | Low Fat Kefir Blueberry | Lifeway | US | Dairy | M | TODO | 2026-04-07 | | |
| 5912 | Tillamook Medium Cheddar Block | Tillamook | US | Dairy | H | TODO | 2026-04-07 | | |
| 5913 | Tillamook Extra Sharp Cheddar | Tillamook | US | Dairy | H | TODO | 2026-04-07 | | |
| 5914 | Tillamook Vanilla Bean Ice Cream | Tillamook | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 5915 | Tillamook Marionberry Pie Ice Cream | Tillamook | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 5916 | Cabot Seriously Sharp Cheddar | Cabot | US | Dairy | H | TODO | 2026-04-07 | | Vermont coop |
| 5917 | Cabot Extra Sharp Cheddar | Cabot | US | Dairy | M | TODO | 2026-04-07 | | |
| 5922 | Organic Valley Grassmilk | Organic Valley | US | Dairy | L | TODO | 2026-04-07 | | |
| 5923 | Organic Valley Butter | Organic Valley | US | Dairy | M | TODO | 2026-04-07 | | |
| 5925 | Horizon Organic 2% Milk | Horizon | US | Dairy | M | TODO | 2026-04-07 | | |
| 5926 | Horizon Organic Chocolate Milk | Horizon | US | Dairy | M | TODO | 2026-04-07 | | |
| 5927 | Borden American Singles | Borden | US | Dairy | M | TODO | 2026-04-07 | | |
| 5929 | Lactaid 2% Reduced Fat Milk | Lactaid | US | Dairy | H | TODO | 2026-04-07 | | |
| 5930 | Lactaid Chocolate Milk | Lactaid | US | Dairy | M | TODO | 2026-04-07 | | |
| 5932 | Stonyfield Organic Kids Strawberry Banana | Stonyfield | US | Dairy | M | TODO | 2026-04-07 | | |
| 5933 | Noosa Coconut | Noosa | US | Dairy | M | TODO | 2026-04-07 | | |
| 5934 | Noosa Salted Caramel | Noosa | US | Dairy | M | TODO | 2026-04-07 | | |
| 5936 | Yoplait Greek 100 Strawberry | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |
| 5937 | Tillamook Colby Jack Cheese | Tillamook | US | Dairy | M | TODO | 2026-04-07 | | |
| 5938 | Cabot White Cheddar Cracker Cuts | Cabot | US | Dairy | M | TODO | 2026-04-07 | | |
| 5940 | Wallaby Organic Aussie Greek Strawberry | Wallaby | US | Dairy | L | TODO | 2026-04-07 | | |
| 5941 | La Yogurt Probiotic Mango | La Yogurt | US | Dairy | M | TODO | 2026-04-07 | | |
| 5942 | Brown Cow Cream Top Chocolate | Brown Cow | US | Dairy | L | TODO | 2026-04-07 | | |
| 5943 | Lifeway Kefir Mango | Lifeway | US | Dairy | M | TODO | 2026-04-07 | | |
| 5945 | Horizon Organic American Singles | Horizon | US | Dairy | M | TODO | 2026-04-07 | | |
| 5946 | Lactaid Ice Cream Vanilla | Lactaid | US | Dairy | M | TODO | 2026-04-07 | | |
| 5947 | Tillamook Mudslide Ice Cream | Tillamook | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 5948 | Tillamook Oregon Strawberry Ice Cream | Tillamook | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 5949 | Dannon Light & Fit Greek Toasted Coconut Vanilla | Dannon | US | Dairy | M | TODO | 2026-04-07 | | |
| 5950 | Yoplait Original Mixed Berry | Yoplait | US | Dairy | M | TODO | 2026-04-07 | | |

## Section 109: Snack Brands - Chips/Crackers/Pretzels Complete (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 5957 | Lay's Baked Original | Lay's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5962 | Doritos Dinamita Chile Limon | Doritos | US | Snacks | M | TODO | 2026-04-07 | | |
| 5965 | Cheetos Mac 'N Cheese Bold & Cheesy | Cheetos | US | Pasta | M | TODO | 2026-04-07 | | |
| 5967 | Fritos Scoops | Fritos | US | Snacks | M | TODO | 2026-04-07 | | |
| 5971 | Tostitos Queso Dip | Tostitos | US | Dips | M | TODO | 2026-04-07 | | |
| 5974 | SunChips Original | SunChips | US | Snacks | H | TODO | 2026-04-07 | | |
| 5977 | Funyuns Onion Flavored Rings | Funyuns | US | Snacks | M | TODO | 2026-04-07 | | |
| 5979 | Stacy's Simply Naked Pita Chips | Stacy's | US | Snacks | H | TODO | 2026-04-07 | | |
| 5980 | Stacy's Parmesan Garlic & Herb Pita Chips | Stacy's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5985 | Pringles Pizza | Pringles | US | Snacks | M | TODO | 2026-04-07 | | |
| 5986 | Cheez-It Original | Cheez-It | US | Snacks | H | TODO | 2026-04-07 | | |
| 5987 | Cheez-It White Cheddar | Cheez-It | US | Snacks | M | TODO | 2026-04-07 | | |
| 5988 | Cheez-It Extra Toasty | Cheez-It | US | Snacks | H | TODO | 2026-04-07 | | |
| 5989 | Cheez-It Snap'd | Cheez-It | US | Snacks | M | TODO | 2026-04-07 | | |
| 5990 | Ritz Original Crackers | Ritz | US | Snacks | H | TODO | 2026-04-07 | | |
| 5994 | Good Thins Corn | Good Thins | US | Snacks | M | TODO | 2026-04-07 | | |
| 5997 | Snyder's Pretzel Sticks | Snyder's | US | Snacks | M | TODO | 2026-04-07 | | |
| 5999 | Utz Cheese Balls | Utz | US | Snacks | M | TODO | 2026-04-07 | | |
| 6002 | Kettle Brand Salt & Vinegar | Kettle Brand | US | Snacks | M | TODO | 2026-04-07 | | |
| 6004 | Cape Cod Sea Salt & Vinegar | Cape Cod | US | Snacks | M | TODO | 2026-04-07 | | |
| 6006 | Popcorners Sea Salt | Popcorners | US | Snacks | H | TODO | 2026-04-07 | | |
| 6007 | Popcorners White Cheddar | Popcorners | US | Snacks | M | TODO | 2026-04-07 | | |
| 6008 | Popcorners Kettle Corn | Popcorners | US | Snacks | M | TODO | 2026-04-07 | | |
| 6009 | Boom Chicka Pop Sea Salt | Boom Chicka Pop | US | Snacks | H | TODO | 2026-04-07 | | |
| 6010 | Boom Chicka Pop Sweet & Salty | Boom Chicka Pop | US | Snacks | M | TODO | 2026-04-07 | | |
| 6014 | Hippeas Vegan White Cheddar | Hippeas | US | Snacks | M | TODO | 2026-04-07 | | |
| 6015 | Hippeas Barbecue | Hippeas | US | Snacks | M | TODO | 2026-04-07 | | |
| 6016 | Beanitos Black Bean Chips | Beanitos | US | Snacks | M | TODO | 2026-04-07 | | |
| 6018 | Late July Nacho Chipotle | Late July | US | Snacks | M | TODO | 2026-04-07 | | |
| 6020 | Harvest Snaps Green Pea Lightly Salted | Harvest Snaps | US | Snacks | M | TODO | 2026-04-07 | | |
| 6021 | Harvest Snaps Red Lentil | Harvest Snaps | US | Snacks | M | TODO | 2026-04-07 | | |
| 6025 | PopChips BBQ | PopChips | US | Snacks | M | TODO | 2026-04-07 | | |
| 6027 | Terra Original Exotic Vegetable Chips | Terra | US | Snacks | M | TODO | 2026-04-07 | | |
| 6029 | Lay's Limon | Lay's | US | Snacks | M | TODO | 2026-04-07 | | |
| 6030 | Lay's Dill Pickle | Lay's | US | Snacks | M | TODO | 2026-04-07 | | |
| 6033 | Pringles Wavy Classic Salted | Pringles | US | Snacks | M | TODO | 2026-04-07 | | |
| 6035 | Utz Ripple Original | Utz | US | Snacks | M | TODO | 2026-04-07 | | |
| 6036 | Boulder Canyon Hickory BBQ | Boulder Canyon | US | Snacks | L | TODO | 2026-04-07 | | |
| 6038 | Ritz Cheese Crackers Sandwiches | Ritz | US | Snacks | M | TODO | 2026-04-07 | | |
| 6040 | Cheez-It Grooves Sharp Cheddar | Cheez-It | US | Snacks | M | TODO | 2026-04-07 | | |
| 6041 | Club Original Crackers | Keebler | US | Snacks | M | TODO | 2026-04-07 | | |
| 6042 | Snyder's Sourdough Nibblers | Snyder's | US | Snacks | M | TODO | 2026-04-07 | | |
| 6045 | SkinnyPop Sea Salt & Pepper | SkinnyPop | US | Snacks | M | TODO | 2026-04-07 | | |
| 6047 | Late July Jalapeno Lime | Late July | US | Snacks | M | TODO | 2026-04-07 | | |
| 6049 | Chicken in a Biskit | Nabisco | US | Snacks | M | TODO | 2026-04-07 | | |
| 6050 | Triscuit Reduced Fat | Triscuit | US | Snacks | M | TODO | 2026-04-07 | | |

## Section 110: Cookie & Cracker Brands (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6053 | Oreo Golden | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 6054 | Oreo Mint | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 6056 | Oreo Birthday Cake | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 6057 | Oreo Mega Stuf | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 6060 | Chips Ahoy! Chunky | Chips Ahoy! | US | Cookies | M | TODO | 2026-04-07 | | |
| 6061 | Nutter Butters | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 6062 | Nilla Wafers | Nabisco | US | Cookies | H | TODO | 2026-04-07 | | |
| 6063 | Fig Newtons Original | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 6064 | Teddy Grahams Honey | Nabisco | US | Cookies | H | TODO | 2026-04-07 | | |
| 6065 | Teddy Grahams Chocolate | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 6068 | Belvita Blueberry Breakfast Biscuits | Belvita | US | Cookies | H | TODO | 2026-04-07 | | |
| 6072 | Milano Mint | Pepperidge Farm | US | Cookies | M | TODO | 2026-04-07 | | |
| 6075 | Goldfish Pizza | Pepperidge Farm | US | Crackers | M | TODO | 2026-04-07 | | |
| 6076 | Goldfish Colors | Pepperidge Farm | US | Crackers | M | TODO | 2026-04-07 | | |
| 6079 | Fudge Stripes | Keebler | US | Cookies | H | TODO | 2026-04-07 | | |
| 6080 | E.L. Fudge | Keebler | US | Cookies | M | TODO | 2026-04-07 | | |
| 6081 | Vienna Fingers | Keebler | US | Cookies | M | TODO | 2026-04-07 | | |
| 6083 | Samoas Girl Scout Cookies | Girl Scout | US | Cookies | H | TODO | 2026-04-07 | | |
| 6084 | Tagalongs Girl Scout Cookies | Girl Scout | US | Cookies | H | TODO | 2026-04-07 | | |
| 6085 | Do-si-dos Girl Scout Cookies | Girl Scout | US | Cookies | M | TODO | 2026-04-07 | | |
| 6086 | Trefoils Girl Scout Cookies | Girl Scout | US | Cookies | M | TODO | 2026-04-07 | | |
| 6087 | Oatmeal Creme Pies | Little Debbie | US | Snack Cakes | H | TODO | 2026-04-07 | | |
| 6088 | Cosmic Brownies | Little Debbie | US | Snack Cakes | H | TODO | 2026-04-07 | | |
| 6089 | Swiss Rolls | Little Debbie | US | Snack Cakes | H | TODO | 2026-04-07 | | |
| 6090 | Nutty Buddy Bars | Little Debbie | US | Snack Cakes | H | TODO | 2026-04-07 | | |
| 6091 | Zebra Cakes | Little Debbie | US | Snack Cakes | H | TODO | 2026-04-07 | | |
| 6092 | Honey Buns | Little Debbie | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 6093 | Star Crunch | Little Debbie | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 6095 | Ho Hos | Hostess | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 6096 | Ding Dongs | Hostess | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 6097 | CupCakes Chocolate | Hostess | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 6098 | Donettes Powdered | Hostess | US | Snack Cakes | H | TODO | 2026-04-07 | | |
| 6099 | Donettes Chocolate Frosted | Hostess | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 6100 | Suzy Q's | Hostess | US | Snack Cakes | L | TODO | 2026-04-07 | | |
| 6101 | Complete Cookie Double Chocolate | Lenny & Larry's | US | Cookies | H | TODO | 2026-04-07 | | 16g protein |
| 6102 | Complete Cookie Chocolate Chip | Lenny & Larry's | US | Cookies | H | TODO | 2026-04-07 | | |
| 6103 | Complete Cookie Birthday Cake | Lenny & Larry's | US | Cookies | M | TODO | 2026-04-07 | | |
| 6104 | Complete Cookie Peanut Butter | Lenny & Larry's | US | Cookies | M | TODO | 2026-04-07 | | |
| 6105 | Chocolate Chocolate Chip Cookies | Maxine's Heavenly | US | Cookies | M | TODO | 2026-04-07 | | |
| 6106 | Coconut Macaroon Cookies | Emmy's Organics | US | Cookies | M | TODO | 2026-04-07 | | |
| 6113 | Oreo Mini | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 6114 | Chips Ahoy! Reese's | Chips Ahoy! | US | Cookies | M | TODO | 2026-04-07 | | |
| 6115 | Goldfish Mega Bites Sharp Cheddar | Pepperidge Farm | US | Crackers | M | TODO | 2026-04-07 | | |
| 6116 | Milano Salted Caramel | Pepperidge Farm | US | Cookies | M | TODO | 2026-04-07 | | |
| 6117 | Fudge Stripes Minis | Keebler | US | Cookies | M | TODO | 2026-04-07 | | |
| 6118 | Lemonades Girl Scout Cookies | Girl Scout | US | Cookies | M | TODO | 2026-04-07 | | |
| 6119 | Fudge Covered Nutter Butters | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 6120 | Christmas Tree Brownies | Little Debbie | US | Snack Cakes | M | TODO | 2026-04-07 | | Seasonal |
| 6121 | Belvita Chocolate | Belvita | US | Cookies | M | TODO | 2026-04-07 | | |
| 6122 | Teddy Grahams Cinnamon | Nabisco | US | Cookies | M | TODO | 2026-04-07 | | |
| 6123 | Snickerdoodle Cookie | Lenny & Larry's | US | Cookies | M | TODO | 2026-04-07 | | |
| 6124 | Double Chocolate Chip | Tate's Bake Shop | US | Cookies | M | TODO | 2026-04-07 | | |
| 6127 | Oreo Peanut Butter | Oreo | US | Cookies | M | TODO | 2026-04-07 | | |
| 6128 | Chips Ahoy! Soft Baked | Chips Ahoy! | US | Cookies | M | TODO | 2026-04-07 | | |
| 6129 | Honey Bun Big Pack | Little Debbie | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 6130 | Hostess Kazbars Chocolate Caramel | Hostess | US | Snack Cakes | M | TODO | 2026-04-07 | | |

## Section 111: Candy & Chocolate Brands Complete (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6134 | M&M's Caramel | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6135 | M&M's Pretzel | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6136 | M&M's Crispy | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6137 | Snickers Original Bar | Mars | US | Candy | H | TODO | 2026-04-07 | | |
| 6138 | Snickers Almond | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6139 | Snickers Ice Cream Bar | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6140 | Twix Original | Mars | US | Candy | H | TODO | 2026-04-07 | | |
| 6142 | 3 Musketeers | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6151 | Reese's Big Cup | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 6152 | Kit Kat Original | Hershey's | US | Candy | H | TODO | 2026-04-07 | | |
| 6155 | York Peppermint Pattie | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 6160 | Twizzlers Strawberry | Hershey's | US | Candy | H | TODO | 2026-04-07 | | |
| 6163 | 100 Grand | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 6164 | Crunch Bar | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 6166 | Nutella B-ready | Ferrero | IT | Candy | M | TODO | 2026-04-07 | | |
| 6168 | Tic Tac Freshmint | Ferrero | IT | Candy | M | TODO | 2026-04-07 | | |
| 6169 | Tic Tac Orange | Ferrero | IT | Candy | M | TODO | 2026-04-07 | | |
| 6173 | Trolli Sour Brite Crawlers | Trolli | US | Candy | H | TODO | 2026-04-07 | | |
| 6174 | Haribo Goldbears | Haribo | DE | Candy | H | TODO | 2026-04-07 | | |
| 6175 | Haribo Twin Snakes | Haribo | DE | Candy | M | TODO | 2026-04-07 | | |
| 6177 | Starburst Original | Mars | US | Candy | H | TODO | 2026-04-07 | | |
| 6178 | Skittles Original | Mars | US | Candy | H | TODO | 2026-04-07 | | |
| 6179 | Skittles Sour | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6180 | Life Savers Five Flavors | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6184 | Nerds Original | Ferrara | US | Candy | H | TODO | 2026-04-07 | | |
| 6185 | Nerds Gummy Clusters | Ferrara | US | Candy | H | TODO | 2026-04-07 | | Viral candy |
| 6187 | Ring Pop | Bazooka | US | Candy | M | TODO | 2026-04-07 | | |
| 6188 | Blow Pop | Charms | US | Candy | M | TODO | 2026-04-07 | | |
| 6189 | Airheads Original | Perfetti Van Melle | US | Candy | M | TODO | 2026-04-07 | | |
| 6190 | Airheads Xtremes Bites | Perfetti Van Melle | US | Candy | M | TODO | 2026-04-07 | | |
| 6191 | Now & Later Original | Ferrara | US | Candy | M | TODO | 2026-04-07 | | |
| 6192 | Dots | Tootsie Roll | US | Candy | M | TODO | 2026-04-07 | | |
| 6193 | Junior Mints | Tootsie Roll | US | Candy | M | TODO | 2026-04-07 | | |
| 6194 | Milk Duds | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 6195 | Raisinets | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 6196 | Goobers Chocolate Peanuts | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 6197 | Sno-Caps | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 6198 | Hot Tamales | Just Born | US | Candy | H | TODO | 2026-04-07 | | |
| 6200 | Jelly Belly Assorted | Jelly Belly | US | Candy | H | TODO | 2026-04-07 | | |
| 6201 | Peeps Original Yellow | Just Born | US | Candy | M | TODO | 2026-04-07 | | Seasonal |
| 6202 | Candy Corn Classic | Brach's | US | Candy | M | TODO | 2026-04-07 | | Seasonal |
| 6204 | Lindt Excellence 85% Dark | Lindt | CH | Candy | M | TODO | 2026-04-07 | | |
| 6209 | Twix Peanut Butter | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6210 | Kit Kat Big Kat | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 6211 | Reese's Fast Break | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 6215 | Trolli Sour Brite Eggs | Trolli | US | Candy | M | TODO | 2026-04-07 | | |
| 6216 | Haribo Happy Cola | Haribo | DE | Candy | M | TODO | 2026-04-07 | | |
| 6217 | Sour Punch Straws | American Licorice | US | Candy | M | TODO | 2026-04-07 | | |
| 6218 | Twizzlers Pull 'N' Peel | Hershey's | US | Candy | M | TODO | 2026-04-07 | | |
| 6219 | Starburst FaveREDs | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6220 | Skittles Tropical | Mars | US | Candy | M | TODO | 2026-04-07 | | |
| 6221 | Tootsie Pop | Tootsie Roll | US | Candy | M | TODO | 2026-04-07 | | |
| 6222 | Nerds Rope | Ferrara | US | Candy | M | TODO | 2026-04-07 | | |
| 6223 | SweeTarts Original | Ferrara | US | Candy | M | TODO | 2026-04-07 | | |
| 6224 | SweeTarts Ropes | Ferrara | US | Candy | M | TODO | 2026-04-07 | | |
| 6225 | Butterfinger Peanut Butter Cups | Ferrero | US | Candy | M | TODO | 2026-04-07 | | |
| 6229 | Brach's Jelly Beans Classic | Brach's | US | Candy | M | TODO | 2026-04-07 | | |

## Section 112: Ice Cream Brands Complete (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6231 | Half Baked | Ben & Jerry's | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6232 | Cherry Garcia | Ben & Jerry's | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6233 | Phish Food | Ben & Jerry's | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6234 | Americone Dream | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6235 | Tonight Dough | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6236 | Chocolate Fudge Brownie | Ben & Jerry's | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6237 | Cookie Dough | Ben & Jerry's | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6238 | Strawberry Cheesecake | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6239 | Netflix & Chilll'd | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6244 | Dulce de Leche | Haagen-Dazs | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6245 | Cookies & Cream | Haagen-Dazs | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6246 | Belgian Chocolate | Haagen-Dazs | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6247 | Rum Raisin | Haagen-Dazs | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6248 | Sea Salt Caramel Gelato | Talenti | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6249 | Mediterranean Mint Gelato | Talenti | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6250 | Vanilla Bean Gelato | Talenti | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6251 | Chocolate Fudge Brownie Gelato | Talenti | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6252 | Peanut Butter Fudge Sorbetto | Talenti | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6253 | Homemade Vanilla | Blue Bell | US | Ice Cream | H | TODO | 2026-04-07 | | Texas favorite |
| 6254 | Dutch Chocolate | Blue Bell | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6255 | Cookies and Cream | Blue Bell | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6256 | The Great Divide | Blue Bell | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6257 | Natural Vanilla | Breyers | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6258 | Cookies & Cream | Breyers | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6260 | Vanilla Bean | Turkey Hill | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6261 | Chocolate Peanut Butter Cup | Turkey Hill | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6262 | Forbidden Chocolate | Friendly's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6264 | Cookie Dough | Edy's/Dreyer's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6265 | Bunny Tracks | Blue Bunny | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6266 | Super Chunky Cookie Dough | Blue Bunny | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6267 | Salty Caramel | Jeni's Splendid | US | Ice Cream | H | TODO | 2026-04-07 | | Premium artisan |
| 6268 | Brambleberry Crisp | Jeni's Splendid | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6269 | Gooey Butter Cake | Jeni's Splendid | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6270 | Brown Butter Almond Brittle | Jeni's Splendid | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6271 | Sea Salt with Caramel Ribbons | Salt & Straw | US | Ice Cream | H | TODO | 2026-04-07 | | Portland-based |
| 6272 | Honey Lavender | Salt & Straw | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6273 | Planet Earth Vanilla | Van Leeuwen | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6275 | Earl Grey Tea | Van Leeuwen | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6276 | Turkish Coffee | McConnell's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6277 | Eureka Lemon & Marionberries | McConnell's | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 6278 | Black Raspberry Chocolate Chip | Graeter's | US | Ice Cream | H | TODO | 2026-04-07 | | French pot process |
| 6279 | Toffee Chocolate Chip | Graeter's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6280 | Coconut Milk Vanilla | So Delicious | US | Ice Cream | M | TODO | 2026-04-07 | | Dairy-free |
| 6281 | Coconut Milk Mocha Almond Fudge | So Delicious | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6282 | Oat Milk Strawberry | Oatly | SE | Ice Cream | M | TODO | 2026-04-07 | | |
| 6284 | Chocolate Hazelnut Fudge | Coconut Bliss | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 6288 | Klondike Bar Original | Klondike | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6289 | Klondike Bar Reese's | Klondike | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6290 | Drumstick Classic Vanilla | Drumstick | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6291 | Drumstick Caramel | Drumstick | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6292 | Dove Vanilla Bar | Dove | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6293 | Good Humor Strawberry Shortcake Bar | Good Humor | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6294 | Good Humor Chocolate Eclair Bar | Good Humor | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6295 | Good Humor Giant King Cone | Good Humor | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6296 | Fudgsicle Original | Popsicle | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6297 | Fudgsicle No Sugar Added | Popsicle | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6298 | Creamsicle Original | Popsicle | US | Ice Cream | H | TODO | 2026-04-07 | | |
| 6299 | Ben & Jerry's Mint Chocolate Cookie | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6300 | Ben & Jerry's Caramel Cookie Fix | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6301 | Haagen-Dazs Butter Pecan | Haagen-Dazs | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6302 | Haagen-Dazs Mint Chip | Haagen-Dazs | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6303 | Talenti Caramel Cookie Crunch | Talenti | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6306 | Turkey Hill Mint Choc Chip Premium | Turkey Hill | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6307 | Edy's Slow Churned Caramel Delight | Edy's/Dreyer's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6308 | Jeni's Everything Bagel | Jeni's Splendid | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 6309 | Van Leeuwen Chocolate Fudge Brownie | Van Leeuwen | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 6310 | Popsicle Original Variety Pack | Popsicle | US | Ice Cream | H | TODO | 2026-04-07 | | |

## Section 113: Beverage Brands - Juice/Water/Tea (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6315 | Fruit Punch | Minute Maid | US | Beverages | M | TODO | 2026-04-07 | | |
| 6317 | Simply Orange Pulp Free | Simply | US | Beverages | H | TODO | 2026-04-07 | | |
| 6320 | Naked Mighty Mango Smoothie | Naked Juice | US | Beverages | H | TODO | 2026-04-07 | | |
| 6321 | Naked Green Machine Smoothie | Naked Juice | US | Beverages | H | TODO | 2026-04-07 | | |
| 6322 | Naked Blue Machine Smoothie | Naked Juice | US | Beverages | M | TODO | 2026-04-07 | | |
| 6323 | Naked Strawberry Banana Smoothie | Naked Juice | US | Beverages | M | TODO | 2026-04-07 | | |
| 6324 | Bolthouse Farms Green Goodness | Bolthouse Farms | US | Beverages | M | TODO | 2026-04-07 | | |
| 6325 | Bolthouse Farms Protein Plus Chocolate | Bolthouse Farms | US | Beverages | M | TODO | 2026-04-07 | | |
| 6326 | Bolthouse Farms Berry Boost | Bolthouse Farms | US | Beverages | M | TODO | 2026-04-07 | | |
| 6328 | Ocean Spray Cran-Grape | Ocean Spray | US | Beverages | M | TODO | 2026-04-07 | | |
| 6329 | V8 Original Vegetable Juice | V8 | US | Beverages | H | TODO | 2026-04-07 | | |
| 6330 | V8 Low Sodium | V8 | US | Beverages | M | TODO | 2026-04-07 | | |
| 6332 | V8 +Energy Peach Mango | V8 | US | Beverages | M | TODO | 2026-04-07 | | |
| 6336 | Capri Sun Pacific Cooler | Capri Sun | US | Beverages | M | TODO | 2026-04-07 | | |
| 6338 | Kool-Aid Jammers Cherry | Kool-Aid | US | Beverages | M | TODO | 2026-04-07 | | |
| 6340 | SunnyD Original | SunnyD | US | Beverages | M | TODO | 2026-04-07 | | |
| 6343 | AriZona Mucho Mango | AriZona | US | Beverages | M | TODO | 2026-04-07 | | |
| 6345 | Gold Peak Unsweetened Tea | Gold Peak | US | Beverages | M | TODO | 2026-04-07 | | |
| 6349 | Snapple Peach Tea | Snapple | US | Beverages | H | TODO | 2026-04-07 | | |
| 6351 | Snapple Apple | Snapple | US | Beverages | M | TODO | 2026-04-07 | | |
| 6352 | Vitaminwater XXX Acai Blueberry Pomegranate | Vitaminwater | US | Beverages | H | TODO | 2026-04-07 | | |
| 6353 | Vitaminwater Power-C Dragonfruit | Vitaminwater | US | Beverages | M | TODO | 2026-04-07 | | |
| 6354 | Vitaminwater Zero Sugar Squeezed | Vitaminwater | US | Beverages | M | TODO | 2026-04-07 | | |
| 6355 | Smartwater Original | Smartwater | US | Beverages | H | TODO | 2026-04-07 | | |
| 6356 | Smartwater Alkaline | Smartwater | US | Beverages | M | TODO | 2026-04-07 | | |
| 6357 | Dasani Purified Water | Dasani | US | Beverages | H | TODO | 2026-04-07 | | |
| 6358 | Aquafina Purified Water | Aquafina | US | Beverages | H | TODO | 2026-04-07 | | |
| 6359 | Fiji Natural Artesian Water | Fiji | FJ | Beverages | H | TODO | 2026-04-07 | | |
| 6360 | Evian Natural Spring Water | Evian | FR | Beverages | H | TODO | 2026-04-07 | | |
| 6371 | Spindrift Grapefruit | Spindrift | US | Beverages | M | TODO | 2026-04-07 | | |
| 6374 | Bai Brasilia Blueberry | Bai | US | Beverages | M | TODO | 2026-04-07 | | |
| 6375 | Bai Costa Rica Clementine | Bai | US | Beverages | M | TODO | 2026-04-07 | | |
| 6376 | Bai Kula Watermelon | Bai | US | Beverages | M | TODO | 2026-04-07 | | |
| 6377 | Simply Limeade | Simply | US | Beverages | M | TODO | 2026-04-07 | | |
| 6378 | Tropicana Strawberry Peach | Tropicana | US | Beverages | M | TODO | 2026-04-07 | | |
| 6381 | Snapple Mango Madness | Snapple | US | Beverages | M | TODO | 2026-04-07 | | |
| 6384 | AriZona Watermelon | AriZona | US | Beverages | M | TODO | 2026-04-07 | | |
| 6385 | Honest Tea Half Tea Half Lemonade | Honest Tea | US | Beverages | M | TODO | 2026-04-07 | | |
| 6386 | Spindrift Pineapple | Spindrift | US | Beverages | M | TODO | 2026-04-07 | | |
| 6387 | Bai Molokai Coconut | Bai | US | Beverages | M | TODO | 2026-04-07 | | |
| 6388 | Bolthouse Farms Carrot Ginger Turmeric | Bolthouse Farms | US | Beverages | M | TODO | 2026-04-07 | | |
| 6389 | V8 +Energy Strawberry Banana | V8 | US | Beverages | M | TODO | 2026-04-07 | | |
| 6390 | Pure Leaf Lemon Tea | Pure Leaf | US | Beverages | M | TODO | 2026-04-07 | | |

## Section 114: Bread & Bakery Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6391 | Honey Wheat Bread | Sara Lee | US | Bread | H | TODO | 2026-04-07 | | |
| 6393 | Delightful Wheat 45cal Bread | Sara Lee | US | Bread | M | TODO | 2026-04-07 | | |
| 6397 | Honey Wheat Bread | Nature's Own | US | Bread | H | TODO | 2026-04-07 | | |
| 6398 | Butterbread | Nature's Own | US | Bread | H | TODO | 2026-04-07 | | |
| 6399 | Life 40 Calorie Wheat Bread | Nature's Own | US | Bread | M | TODO | 2026-04-07 | | |
| 6401 | Potato Rolls | Martin's | US | Bread | H | TODO | 2026-04-07 | | Best burger buns |
| 6402 | Long Potato Rolls Hot Dog | Martin's | US | Bread | H | TODO | 2026-04-07 | | |
| 6403 | Sweet Hawaiian Rolls | King's Hawaiian | US | Bread | H | TODO | 2026-04-07 | | |
| 6404 | Sweet Hawaiian Slider Buns | King's Hawaiian | US | Bread | H | TODO | 2026-04-07 | | |
| 6405 | Original English Muffins | Thomas' | US | Bread | H | TODO | 2026-04-07 | | |
| 6406 | Cinnamon Raisin English Muffins | Thomas' | US | Bread | M | TODO | 2026-04-07 | | |
| 6407 | Plain Bagels | Thomas' | US | Bread | H | TODO | 2026-04-07 | | |
| 6408 | Everything Bagels | Thomas' | US | Bread | H | TODO | 2026-04-07 | | |
| 6409 | English Muffins Original | Bays | US | Bread | M | TODO | 2026-04-07 | | |
| 6410 | Crescent Rolls Original | Pillsbury | US | Bread | H | TODO | 2026-04-07 | | |
| 6411 | Grands Biscuits Southern Homestyle | Pillsbury | US | Bread | H | TODO | 2026-04-07 | | |
| 6412 | Cinnamon Rolls with Icing | Pillsbury | US | Bread | H | TODO | 2026-04-07 | | |
| 6414 | Pie Crust Refrigerated | Pillsbury | US | Baking | M | TODO | 2026-04-07 | | |
| 6415 | Pizza Dough Classic | Pillsbury | US | Baking | M | TODO | 2026-04-07 | | |
| 6416 | Blueberry Muffins Otis Spunkmeyer | Otis Spunkmeyer | US | Bakery | M | TODO | 2026-04-07 | | |
| 6417 | Chocolate Chip Muffins | Otis Spunkmeyer | US | Bakery | M | TODO | 2026-04-07 | | |
| 6418 | Rich Frosted Donuts | Entenmann's | US | Bakery | H | TODO | 2026-04-07 | | |
| 6419 | Crumb Coffee Cake | Entenmann's | US | Bakery | H | TODO | 2026-04-07 | | |
| 6420 | Chocolate Chip Cookies Soft Baked | Entenmann's | US | Bakery | M | TODO | 2026-04-07 | | |
| 6421 | Glazed Pop'ems Donut Holes | Entenmann's | US | Bakery | M | TODO | 2026-04-07 | | |
| 6422 | Entenmann's Little Bites Blueberry Muffins | Entenmann's | US | Bakery | H | TODO | 2026-04-07 | | |
| 6423 | Ring Dings | Drake's | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 6424 | Yodels | Drake's | US | Snack Cakes | M | TODO | 2026-04-07 | | |
| 6425 | Flour Tortillas Soft Taco | Mission | US | Bread | H | TODO | 2026-04-07 | | |
| 6426 | Corn Tortillas | Mission | US | Bread | H | TODO | 2026-04-07 | | |
| 6427 | Carb Balance Whole Wheat Tortillas | Mission | US | Bread | H | TODO | 2026-04-07 | | Low carb popular |
| 6428 | Flour Tortillas Burrito Size | Mission | US | Bread | M | TODO | 2026-04-07 | | |
| 6429 | Stand 'N Stuff Taco Shells | Old El Paso | US | Bread | M | TODO | 2026-04-07 | | |
| 6430 | Taco Dinner Kit | Old El Paso | US | Meal Kit | M | TODO | 2026-04-07 | | |
| 6431 | Crunchy Taco Shells | Old El Paso | US | Bread | M | TODO | 2026-04-07 | | |
| 6434 | Light Original Flatbread | Flatout | US | Bread | M | TODO | 2026-04-07 | | |
| 6436 | Gluten Free Hamburger Buns | Udi's | US | Bread | M | TODO | 2026-04-07 | | |
| 6437 | Gluten Free White Sandwich Bread | Udi's | US | Bread | M | TODO | 2026-04-07 | | |
| 6439 | Gluten Free Heritage Style Bread | Canyon Bakehouse | US | Bread | M | TODO | 2026-04-07 | | |
| 6440 | 21 Whole Grains & Seeds Bread | Dave's Killer Bread | US | Bread | H | TODO | 2026-04-07 | | |
| 6441 | Good Seed Bread | Dave's Killer Bread | US | Bread | H | TODO | 2026-04-07 | | |
| 6442 | Powerseed Bread | Dave's Killer Bread | US | Bread | M | TODO | 2026-04-07 | | |
| 6444 | Thin-Sliced 21 Whole Grains | Dave's Killer Bread | US | Bread | M | TODO | 2026-04-07 | | |
| 6445 | Everything Bagels | Dave's Killer Bread | US | Bread | M | TODO | 2026-04-07 | | |
| 6446 | Blueberry English Muffins | Thomas' | US | Bread | M | TODO | 2026-04-07 | | |
| 6447 | Whole Wheat English Muffins | Thomas' | US | Bread | M | TODO | 2026-04-07 | | |
| 6448 | Flaky Layers Biscuits Buttermilk | Pillsbury | US | Bread | M | TODO | 2026-04-07 | | |
| 6449 | Sweet Hawaiian Honey Wheat Bread | King's Hawaiian | US | Bread | M | TODO | 2026-04-07 | | |
| 6450 | White Hamburger Buns | Sara Lee | US | Bread | M | TODO | 2026-04-07 | | |

## Section 115: Canned & Jarred Food Brands (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6454 | Condensed Cream of Chicken Soup | Campbell's | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6455 | Chunky Classic Chicken Noodle | Campbell's | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6456 | Chunky Beef with Country Vegetables | Campbell's | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6459 | Italian Style Wedding Soup | Progresso | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6462 | Beef Ravioli | Chef Boyardee | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6463 | Beefaroni | Chef Boyardee | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6464 | Mini Ravioli | Chef Boyardee | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6465 | SpaghettiOs Original | SpaghettiOs | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6466 | SpaghettiOs with Meatballs | SpaghettiOs | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6467 | Chili with Beans | Hormel | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6468 | Chili No Beans | Hormel | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6469 | SPAM Classic | Hormel | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6470 | SPAM Lite | Hormel | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6477 | Adobo All Purpose Seasoning | Goya | US | Condiments | H | TODO | 2026-04-07 | | |
| 6478 | Sazon Seasoning | Goya | US | Condiments | M | TODO | 2026-04-07 | | |
| 6479 | Yellow Rice Mix | Goya | US | Grains | M | TODO | 2026-04-07 | | |
| 6480 | Diced Tomatoes & Green Chilies | Rotel | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6481 | Organic Diced Tomatoes | Muir Glen | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6482 | Organic Tomato Sauce | Muir Glen | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6483 | Tomato Sauce | Hunt's | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6484 | Diced Tomatoes | Hunt's | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6486 | Tomato & Basil Pasta Sauce | Classico | US | Condiments | H | TODO | 2026-04-07 | | |
| 6487 | Roasted Garlic Pasta Sauce | Classico | US | Condiments | M | TODO | 2026-04-07 | | |
| 6488 | Traditional Italian Sauce | Prego | US | Condiments | H | TODO | 2026-04-07 | | |
| 6489 | Meat Flavored Sauce | Prego | US | Condiments | M | TODO | 2026-04-07 | | |
| 6490 | Old World Style Traditional | Ragu | US | Condiments | H | TODO | 2026-04-07 | | |
| 6491 | Chunky Mushroom & Green Pepper | Ragu | US | Condiments | M | TODO | 2026-04-07 | | |
| 6493 | Sockarooni Pasta Sauce | Newman's Own | US | Condiments | M | TODO | 2026-04-07 | | |
| 6495 | Medium Salsa | Newman's Own | US | Condiments | M | TODO | 2026-04-07 | | |
| 6497 | Arrabbiata Sauce | Rao's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6498 | Vodka Sauce | Rao's | US | Condiments | H | TODO | 2026-04-07 | | |
| 6502 | Protein+ Spaghetti | Barilla | IT | Pasta | M | TODO | 2026-04-07 | | |
| 6503 | Basilico Sauce | Barilla | IT | Condiments | M | TODO | 2026-04-07 | | |
| 6504 | Rigatoni | De Cecco | IT | Pasta | M | TODO | 2026-04-07 | | |
| 6506 | Tortellini Cheese | Buitoni | IT | Pasta | M | TODO | 2026-04-07 | | |
| 6507 | Ravioli Four Cheese | Buitoni | IT | Pasta | M | TODO | 2026-04-07 | | |
| 6508 | Chunk Light Tuna in Water | StarKist | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6509 | Albacore White Tuna in Water | StarKist | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6510 | Tuna Creations Lemon Pepper | StarKist | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6511 | Chunk Light Tuna in Water | Bumble Bee | US | Canned Goods | H | TODO | 2026-04-07 | | |
| 6512 | Pink Salmon | Bumble Bee | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6513 | Chunk Light Tuna | Chicken of the Sea | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6516 | Fruit Cocktail in Juice | Del Monte | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6517 | Sliced Peaches in Juice | Del Monte | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6518 | Pineapple Chunks in Juice | Dole | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6519 | Mandarin Oranges | Dole | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6520 | Sweet Peas | Green Giant | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6521 | Whole Kernel Corn | Green Giant | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6524 | Pork & Beans | Van Camp's | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6526 | Condensed Vegetable Soup | Campbell's | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6527 | Chunky Sirloin Burger | Campbell's | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6529 | Tomato Basil Soup | Progresso | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 6530 | SPAM Teriyaki | Hormel | US | Canned Goods | M | TODO | 2026-04-07 | | |

## Section 116: Condiment & Sauce Brands (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6531 | Tomato Ketchup | Heinz | US | Condiments | H | TODO | 2026-04-07 | | |
| 6533 | Real Mayonnaise | Heinz | US | Condiments | H | TODO | 2026-04-07 | | |
| 6534 | 57 Sauce | Heinz | US | Condiments | M | TODO | 2026-04-07 | | |
| 6536 | Heinz No Sugar Added Ketchup | Heinz | US | Condiments | M | TODO | 2026-04-07 | | |
| 6538 | Crispy Fried Onions | French's | US | Condiments | H | TODO | 2026-04-07 | | |
| 6539 | Real Mayonnaise | Hellmann's | US | Condiments | H | TODO | 2026-04-07 | | |
| 6540 | Light Mayonnaise | Hellmann's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6542 | Vegan Mayo | Hellmann's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6543 | Real Mayonnaise | Duke's | US | Condiments | H | TODO | 2026-04-07 | | Southern favorite |
| 6544 | Classic Ketchup | Sir Kensington's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6550 | Unsweetened Ketchup | Primal Kitchen | US | Condiments | M | TODO | 2026-04-07 | | |
| 6552 | Green Goddess Dressing | Primal Kitchen | US | Condiments | M | TODO | 2026-04-07 | | |
| 6553 | Balsamic Dressing | Tessemae's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6554 | Organic Ketchup | Annie's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6555 | Organic Goddess Dressing | Annie's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6564 | Avocado Ranch | Hidden Valley | US | Condiments | M | TODO | 2026-04-07 | | |
| 6571 | Sweet Heat BBQ | Sweet Baby Ray's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6572 | Original Bar-B-Q Sauce | Stubb's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6573 | Spicy Bar-B-Q Sauce | Stubb's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6576 | A1 Original Steak Sauce | A1 | US | Condiments | H | TODO | 2026-04-07 | | |
| 6578 | Original Red Pepper Sauce | Tabasco | US | Condiments | H | TODO | 2026-04-07 | | |
| 6579 | Chipotle Pepper Sauce | Tabasco | US | Condiments | M | TODO | 2026-04-07 | | |
| 6580 | Original Cayenne Pepper Sauce | Frank's RedHot | US | Condiments | H | TODO | 2026-04-07 | | |
| 6581 | Buffalo Wings Sauce | Frank's RedHot | US | Condiments | H | TODO | 2026-04-07 | | |
| 6584 | Salsa Picante | Tapatio | MX | Condiments | H | TODO | 2026-04-07 | | |
| 6589 | Sichuan Chili Crisp | Fly By Jing | US | Condiments | M | TODO | 2026-04-07 | | Trending |
| 6590 | Hot Honey | Mike's Hot Honey | US | Condiments | H | TODO | 2026-04-07 | | Viral condiment |
| 6591 | Sriracha Hot Chili Sauce | Huy Fong | US | Condiments | H | TODO | 2026-04-07 | | Rooster sauce |
| 6594 | Polynesian Sauce Bottled | Chick-fil-A | US | Condiments | M | TODO | 2026-04-07 | | |
| 6595 | Zax Sauce Bottled | Zaxby's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6596 | Cane's Sauce Bottled | Raising Cane's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6598 | Spicy Brown Mustard | Gulden's | US | Condiments | M | TODO | 2026-04-07 | | |
| 6603 | Teriyaki Marinade & Sauce | Kikkoman | JP | Condiments | M | TODO | 2026-04-07 | | |
| 6608 | Steak Sauce | Primal Kitchen | US | Condiments | M | TODO | 2026-04-07 | | |

## Section 117: Protein Bar Brands Expansion (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6616 | ONE Bar Lemon Cake | ONE | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6619 | GoMacro Banana Oatmeal Chocolate Chip | GoMacro | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6621 | No Cow Chocolate Fudge Brownie | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | Dairy-free |
| 6622 | No Cow Peanut Butter Chocolate Chip | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6623 | No Cow Lemon Meringue Pie | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6624 | No Cow Cookies & Cream | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6625 | Power Crunch Original Peanut Butter Creme | Power Crunch | US | Protein Bars | H | TODO | 2026-04-07 | | Wafer bar |
| 6626 | Power Crunch Chocolate Mint | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6627 | Power Crunch Triple Chocolate | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6628 | Power Crunch French Vanilla Creme | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6629 | Power Crunch Peanut Butter Fudge | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6630 | Aloha Peanut Butter Chocolate Chip | Aloha | US | Protein Bars | M | TODO | 2026-04-07 | | Plant-based |
| 6632 | Aloha Coconut Chocolate Almond | Aloha | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6633 | Aloha Vanilla Almond Crunch | Aloha | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 6634 | NuGo Slim Chocolate Brownie | NuGo | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6636 | NuGo Slim Crunchy Peanut Butter | NuGo | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6637 | Luna Bar Lemon Zest | Luna | US | Protein Bars | M | TODO | 2026-04-07 | | Women-focused |
| 6639 | Luna Bar Chocolate Peppermint Stick | Luna | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6640 | Builder's Chocolate | Clif | US | Protein Bars | H | TODO | 2026-04-07 | | 20g protein |
| 6641 | Builder's Crunchy Peanut Butter | Clif | US | Protein Bars | H | TODO | 2026-04-07 | | |
| 6642 | Builder's Chocolate Peanut Butter | Clif | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6643 | Builder's Vanilla Almond | Clif | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6644 | ProBar Base Cookie Dough | ProBar | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 6648 | MET-Rx Big 100 Super Cookie Crunch | MET-Rx | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6650 | BSN Protein Crisp Chocolate Crunch | BSN | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6651 | BSN Protein Crisp Peanut Butter Crunch | BSN | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6654 | Health Warrior Chia Bar Chocolate Peanut Butter | Health Warrior | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6655 | ZonePerfect Chocolate Peanut Butter | ZonePerfect | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6656 | ZonePerfect Fudge Graham | ZonePerfect | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6658 | Nature's Bakery Fig Bar Blueberry | Nature's Bakery | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6659 | Nature's Bakery Fig Bar Raspberry | Nature's Bakery | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6660 | Nature's Bakery Fig Bar Original | Nature's Bakery | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6661 | Bobo's Original Oat Bar | Bobo's | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6662 | Bobo's Chocolate Chip Oat Bar | Bobo's | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6663 | Bobo's Lemon Poppyseed Oat Bar | Bobo's | US | Snack Bars | L | TODO | 2026-04-07 | | |
| 6664 | That's It Apple + Mango Bar | That's It | US | Snack Bars | M | TODO | 2026-04-07 | | 2 ingredients |
| 6665 | That's It Apple + Blueberry Bar | That's It | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6668 | LARABAR Chocolate Chip Brownie | LARABAR | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6669 | LARABAR Banana Bread | LARABAR | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6677 | KIND Maple Glazed Pecan & Sea Salt | KIND | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6678 | KIND Oats & Honey with Toasted Coconut | KIND | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6680 | Munk Pack Coconut White Chip Macadamia | Munk Pack | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6682 | Verb Salted Peanut Butter Bar | Verb | US | Snack Bars | L | TODO | 2026-04-07 | | Caffeinated |
| 6683 | Oatmega Chocolate Brownie | Oatmega | US | Protein Bars | L | TODO | 2026-04-07 | | Omega-3 |
| 6684 | SimplyProtein Peanut Butter Chocolate | SimplyProtein | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6685 | SimplyProtein Lemon | SimplyProtein | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 6686 | Rise Bar Almond Honey | Rise Bar | US | Protein Bars | L | TODO | 2026-04-07 | | 3 ingredients |
| 6687 | Rise Bar Chocolate Coconut | Rise Bar | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 6688 | Garden of Life Sport Chocolate | Garden of Life | US | Protein Bars | M | TODO | 2026-04-07 | | Organic |
| 6689 | Garden of Life Fit High Protein Peanut Butter Chocolate | Garden of Life | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6690 | ONE Bar Cookies & Cream | ONE | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6691 | Power Crunch S'mores | Power Crunch | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6692 | No Cow Birthday Cake | No Cow | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6693 | Aloha Peanut Butter Cup | Aloha | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6697 | KIND Cranberry Almond | KIND | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6698 | Bobo's Peanut Butter Oat Bar | Bobo's | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6699 | Nature's Bakery Fig Bar Peach Apricot | Nature's Bakery | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6700 | Luna Bar Nutz Over Chocolate | Luna | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6701 | Builder's Mint Chocolate | Clif | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6703 | MET-Rx Big 100 Vanilla Caramel Churro | MET-Rx | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6704 | ZonePerfect Strawberry Yogurt | ZonePerfect | US | Protein Bars | M | TODO | 2026-04-07 | | |
| 6705 | That's It Apple + Strawberry Bar | That's It | US | Snack Bars | M | TODO | 2026-04-07 | | |
| 6706 | Health Warrior Chia Bar Coconut | Health Warrior | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 6708 | SimplyProtein Chocolate Chip | SimplyProtein | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 6709 | GoMacro Mocha Chocolate Chip | GoMacro | US | Protein Bars | L | TODO | 2026-04-07 | | |
| 6710 | NuGo Slim Raspberry Truffle | NuGo | US | Protein Bars | L | TODO | 2026-04-07 | | |

## Section 118: Plant-Based & Vegan Products (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6711 | Beyond Burger | Beyond Meat | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6712 | Beyond Sausage Italian | Beyond Meat | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6713 | Beyond Beef Ground | Beyond Meat | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6715 | Beyond Meatballs | Beyond Meat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6716 | Beyond Sausage Brat Original | Beyond Meat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6717 | Impossible Burger | Impossible Foods | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6718 | Impossible Sausage Links Savory | Impossible Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6720 | Impossible Meatballs | Impossible Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6722 | Seven Grain Crispy Tenders | Gardein | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6723 | Ultimate Beefless Burger | Gardein | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6724 | Fishless Filets | Gardein | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6725 | Black Bean Burger | MorningStar Farms | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6726 | Chik Patties Original | MorningStar Farms | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6727 | Veggie Corn Dogs | MorningStar Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6728 | Incogmeato Burger | MorningStar Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6729 | Original Veggie Burger | Boca | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6730 | All American Flame Grilled Burger | Boca | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6732 | Deli Slices Hickory Smoked | Tofurky | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6733 | Plant-Based Roast | Tofurky | US | Plant-Based | M | TODO | 2026-04-07 | | Holiday item |
| 6734 | Classic Smoked Frankfurters | Field Roast | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6736 | Chao Creamy Original Slices | Field Roast | US | Plant-Based | M | TODO | 2026-04-07 | | Plant-based cheese |
| 6737 | Smart Dogs | Lightlife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6738 | Tempeh Original | Lightlife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6739 | Plant-Based Burger | Lightlife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6740 | JUST Egg Folded | JUST Egg | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6741 | JUST Egg Pourable | JUST Egg | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6742 | Classic Cheddar Wheel | Miyoko's | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6743 | European Style Cultured Vegan Butter | Miyoko's | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6745 | Liquid Mozzarella | Miyoko's | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6746 | Epic Mature Cheddar Slices | Violife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6747 | Just Like Parmesan Wedge | Violife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6749 | American Slices | Follow Your Heart | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6750 | Vegenaise Original | Follow Your Heart | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6751 | Cutting Board Mozzarella Shreds | Daiya | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6752 | Cheddar Style Shreds | Daiya | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6753 | Daiya Cheezecake Strawberry | Daiya | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 6754 | Dairy-Free Frozen Dessert Vanilla | So Delicious | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6755 | Oat Milk Creamer Vanilla | So Delicious | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6756 | Silk Oat Yeah Oat Milk Original | Silk | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6758 | Silk Soy Milk Original | Silk | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6760 | Silk Protein Oat Milk | Silk | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6761 | Ripple Original Pea Milk | Ripple | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6762 | Ripple Unsweetened Pea Milk | Ripple | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6767 | Califia Farms Oat Milk Unsweetened | Califia Farms | US | Plant-Based | H | TODO | 2026-04-07 | | |
| 6770 | Califia Farms Oat Barista Blend | Califia Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6771 | Planet Oat Oat Milk Original | Planet Oat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6772 | Planet Oat Oat Milk Extra Creamy | Planet Oat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6773 | Chobani Oat Milk Plain | Chobani | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6774 | Chobani Oat Milk Extra Creamy | Chobani | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6775 | Good Karma Flaxmilk Unsweetened | Good Karma | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 6776 | Kite Hill Ricotta Alternative | Kite Hill | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6778 | Forager Project Cashew Milk Plain | Forager | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 6779 | Forager Project Half & Half Alternative | Forager | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 6781 | Harmless Harvest Dairy-Free Yogurt Vanilla | Harmless Harvest | US | Plant-Based | L | TODO | 2026-04-07 | | |
| 6782 | Beyond Steak Tips | Beyond Meat | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6783 | Impossible Beef Lite Ground | Impossible Foods | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6784 | Gardein Plant-Based Chick'n Scallopini | Gardein | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6785 | MorningStar Farms Grillers Original | MorningStar Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6786 | Tofurky Tempeh Smoky Maple Bacon | Tofurky | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6787 | Lightlife Gimme Lean Sausage | Lightlife | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6788 | Silk Nextmilk Whole Fat | Silk | US | Plant-Based | M | TODO | 2026-04-07 | | |
| 6790 | Califia Farms Oat Creamer Vanilla | Califia Farms | US | Plant-Based | M | TODO | 2026-04-07 | | |

## Section 119: Sports & Hydration Products (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6791 | Thirst Quencher Lemon Lime | Gatorade | US | Sports Drinks | H | TODO | 2026-04-07 | | |
| 6792 | Thirst Quencher Orange | Gatorade | US | Sports Drinks | H | TODO | 2026-04-07 | | |
| 6793 | Thirst Quencher Fruit Punch | Gatorade | US | Sports Drinks | H | TODO | 2026-04-07 | | |
| 6794 | Thirst Quencher Cool Blue | Gatorade | US | Sports Drinks | H | TODO | 2026-04-07 | | |
| 6795 | Gatorade Zero Glacier Cherry | Gatorade | US | Sports Drinks | H | TODO | 2026-04-07 | | |
| 6797 | Gatorade Zero Berry | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 6798 | Gatorade Fit Tropical Mango | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | No sugar added |
| 6799 | Gatorade Fit Cherry Lime | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 6800 | Fast Twitch Tropical Mango | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | Caffeinated |
| 6801 | Fast Twitch Cool Blue | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 6802 | Gx Pod Fruit Punch | Gatorade | US | Sports Drinks | M | TODO | 2026-04-07 | | For Gx bottle |
| 6805 | Powerade Zero Mixed Berry | Powerade | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 6810 | BodyArmor Flash IV Berry | BodyArmor | US | Sports Drinks | M | TODO | 2026-04-07 | | Rapid rehydration |
| 6814 | Liquid IV Acai Berry | Liquid IV | US | Hydration | M | TODO | 2026-04-07 | | |
| 6815 | Liquid IV Concord Grape | Liquid IV | US | Hydration | M | TODO | 2026-04-07 | | |
| 6820 | LMNT Raw Unflavored | LMNT | US | Hydration | M | TODO | 2026-04-07 | | |
| 6822 | Nuun Sport Lemon Lime | Nuun | US | Hydration | H | TODO | 2026-04-07 | | Effervescent tablets |
| 6823 | Nuun Sport Citrus Fruit | Nuun | US | Hydration | M | TODO | 2026-04-07 | | |
| 6824 | Nuun Sport Tropical Punch | Nuun | US | Hydration | M | TODO | 2026-04-07 | | |
| 6825 | Nuun Rest Lemon Chamomile | Nuun | US | Hydration | L | TODO | 2026-04-07 | | |
| 6826 | DripDrop ORS Watermelon | DripDrop | US | Hydration | M | TODO | 2026-04-07 | | Medical grade |
| 6827 | DripDrop ORS Lemon | DripDrop | US | Hydration | M | TODO | 2026-04-07 | | |
| 6828 | Pedialyte Grape | Pedialyte | US | Hydration | H | TODO | 2026-04-07 | | |
| 6829 | Pedialyte Strawberry | Pedialyte | US | Hydration | M | TODO | 2026-04-07 | | |
| 6830 | Pedialyte AdvancedCare Plus Berry Frost | Pedialyte | US | Hydration | M | TODO | 2026-04-07 | | |
| 6831 | Pedialyte Freezer Pops | Pedialyte | US | Hydration | M | TODO | 2026-04-07 | | |
| 6832 | Skratch Labs Sport Hydration Lemon Lime | Skratch Labs | US | Hydration | M | TODO | 2026-04-07 | | Endurance focused |
| 6833 | Skratch Labs Sport Hydration Raspberry Limeade | Skratch Labs | US | Hydration | M | TODO | 2026-04-07 | | |
| 6834 | Skratch Labs Everyday Drink Mix Lemonade | Skratch Labs | US | Hydration | L | TODO | 2026-04-07 | | |
| 6836 | Tailwind Endurance Fuel Berry | Tailwind | US | Hydration | L | TODO | 2026-04-07 | | |
| 6837 | Maurten Drink Mix 320 | Maurten | SE | Hydration | M | TODO | 2026-04-07 | | Pro athlete |
| 6838 | Maurten Gel 100 | Maurten | SE | Gels | M | TODO | 2026-04-07 | | |
| 6839 | Maurten Gel 100 Caf 100 | Maurten | SE | Gels | M | TODO | 2026-04-07 | | Caffeinated |
| 6840 | GU Energy Gel Salted Caramel | GU Energy | US | Gels | H | TODO | 2026-04-07 | | |
| 6841 | GU Energy Gel Chocolate Outrage | GU Energy | US | Gels | M | TODO | 2026-04-07 | | |
| 6842 | GU Energy Gel Tri-Berry | GU Energy | US | Gels | M | TODO | 2026-04-07 | | |
| 6843 | GU Energy Gel Espresso Love | GU Energy | US | Gels | M | TODO | 2026-04-07 | | Caffeinated |
| 6844 | GU Roctane Ultra Endurance Gel Sea Salt Chocolate | GU Energy | US | Gels | M | TODO | 2026-04-07 | | |
| 6845 | Clif Shot Energy Gel Mocha | Clif | US | Gels | M | TODO | 2026-04-07 | | |
| 6846 | Clif Shot Energy Gel Citrus | Clif | US | Gels | M | TODO | 2026-04-07 | | |
| 6847 | Honey Stinger Organic Energy Waffle Honey | Honey Stinger | US | Sports Snacks | H | TODO | 2026-04-07 | | |
| 6848 | Honey Stinger Organic Energy Waffle Chocolate | Honey Stinger | US | Sports Snacks | M | TODO | 2026-04-07 | | |
| 6849 | Honey Stinger Energy Gel Gold | Honey Stinger | US | Gels | M | TODO | 2026-04-07 | | |
| 6850 | Honey Stinger Organic Energy Chews Cherry Blossom | Honey Stinger | US | Sports Snacks | M | TODO | 2026-04-07 | | |
| 6851 | Spring Energy Awesome Sauce Gel | Spring Energy | US | Gels | M | TODO | 2026-04-07 | | Real food gel |
| 6852 | Spring Energy Canaberry Gel | Spring Energy | US | Gels | L | TODO | 2026-04-07 | | |
| 6853 | SiS GO Isotonic Energy Gel Orange | SiS | GB | Gels | M | TODO | 2026-04-07 | | |
| 6854 | SiS GO Electrolyte Lemon & Lime | SiS | GB | Hydration | M | TODO | 2026-04-07 | | |
| 6855 | BioSteel Sports Hydration Mix Blue Raspberry | BioSteel | CA | Hydration | M | TODO | 2026-04-07 | | |
| 6856 | BioSteel Sports Hydration Mix Rainbow Twist | BioSteel | CA | Hydration | M | TODO | 2026-04-07 | | |
| 6857 | Electrolit Electrolyte Beverage Berry | Electrolit | MX | Hydration | H | TODO | 2026-04-07 | | Trending |
| 6858 | Electrolit Electrolyte Beverage Fruit Punch | Electrolit | MX | Hydration | M | TODO | 2026-04-07 | | |
| 6859 | Electrolit Electrolyte Beverage Coconut | Electrolit | MX | Hydration | M | TODO | 2026-04-07 | | |
| 6860 | Essentia Ionized Water | Essentia | US | Beverages | H | TODO | 2026-04-07 | | pH 9.5+ water |
| 6861 | Core Hydration Water | Core | US | Beverages | M | TODO | 2026-04-07 | | |
| 6864 | Propel Powder Packets Grape | Propel | US | Hydration | M | TODO | 2026-04-07 | | |
| 6865 | Gatorade Thirst Quencher Glacier Freeze | Gatorade | US | Sports Drinks | H | TODO | 2026-04-07 | | |
| 6866 | BodyArmor Lyte Blueberry Pomegranate | BodyArmor | US | Sports Drinks | M | TODO | 2026-04-07 | | |
| 6867 | Liquid IV Watermelon | Liquid IV | US | Hydration | M | TODO | 2026-04-07 | | |
| 6868 | Nuun Immunity Orange Citrus | Nuun | US | Hydration | M | TODO | 2026-04-07 | | |
| 6869 | GU Energy Gel Vanilla Bean | GU Energy | US | Gels | M | TODO | 2026-04-07 | | |
| 6870 | Honey Stinger Waffle Caramel | Honey Stinger | US | Sports Snacks | M | TODO | 2026-04-07 | | |

---

**END OF FILE**
**Total items: 5151 through 6870 = 1720 items**
**Remaining: 780 items needed (6871–7650) — see continuation sections below**

---

## Section 120: International Grocery Brands (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6873 | Pocky Matcha | Glico | JP | Snacks | M | TODO | 2026-04-07 | | |
| 6874 | Hi-Chew Strawberry | Morinaga | JP | Candy | H | TODO | 2026-04-07 | | |
| 6875 | Hi-Chew Mango | Morinaga | JP | Candy | M | TODO | 2026-04-07 | | |
| 6876 | Hi-Chew Grape | Morinaga | JP | Candy | M | TODO | 2026-04-07 | | |
| 6878 | Chapagetti Black Bean Noodles | Nongshim | KR | Noodles | M | TODO | 2026-04-07 | | |
| 6879 | Neoguri Spicy Seafood | Nongshim | KR | Noodles | M | TODO | 2026-04-07 | | |
| 6880 | Samyang Buldak Hot Chicken 2X Spicy | Samyang | KR | Noodles | H | TODO | 2026-04-07 | | Viral ramen |
| 6881 | Samyang Buldak Hot Chicken Original | Samyang | KR | Noodles | H | TODO | 2026-04-07 | | |
| 6882 | Samyang Buldak Carbonara | Samyang | KR | Noodles | M | TODO | 2026-04-07 | | |
| 6883 | Samyang Buldak Cheese | Samyang | KR | Noodles | M | TODO | 2026-04-07 | | |
| 6884 | Indomie Mi Goreng Original | Indomie | ID | Noodles | H | TODO | 2026-04-07 | | |
| 6885 | Indomie Mi Goreng BBQ Chicken | Indomie | ID | Noodles | M | TODO | 2026-04-07 | | |
| 6889 | Nissin Top Ramen Beef | Nissin | JP | Noodles | M | TODO | 2026-04-07 | | |
| 6890 | Maruchan Instant Lunch Chicken | Maruchan | US | Noodles | H | TODO | 2026-04-07 | | Budget noodles |
| 6893 | Lotus Biscoff Cookies | Lotus | BE | Cookies | H | TODO | 2026-04-07 | | |
| 6895 | Nutella Hazelnut Spread | Ferrero | IT | Spreads | H | TODO | 2026-04-07 | | |
| 6896 | Nutella & Go! Breadsticks | Ferrero | IT | Snacks | H | TODO | 2026-04-07 | | |
| 6897 | Tim Tam Original Chocolate | Arnott's | AU | Cookies | H | TODO | 2026-04-07 | | |
| 6899 | Digestive Biscuits Original | McVitie's | GB | Cookies | M | TODO | 2026-04-07 | | |
| 6900 | McVitie's Jaffa Cakes | McVitie's | GB | Cookies | M | TODO | 2026-04-07 | | |
| 6908 | Maggi Seasoning Sauce | Maggi | CH | Condiments | M | TODO | 2026-04-07 | | |
| 6909 | Maggi 2-Minute Noodles Masala | Maggi | IN | Noodles | H | TODO | 2026-04-07 | | India's #1 instant |
| 6910 | Parle-G Biscuits | Parle | IN | Cookies | H | TODO | 2026-04-07 | | World's best-selling cookie by volume |
| 6911 | Haldiram's Aloo Bhujia | Haldiram's | IN | Snacks | M | TODO | 2026-04-07 | | |
| 6912 | Haldiram's Mixture | Haldiram's | IN | Snacks | M | TODO | 2026-04-07 | | |
| 6915 | Patak's Tikka Masala Simmer Sauce | Patak's | GB | Condiments | H | TODO | 2026-04-07 | | |
| 6919 | Coconut Milk Canned | Thai Kitchen | TH | Canned Goods | H | TODO | 2026-04-07 | | |
| 6920 | Green Curry Paste | Thai Kitchen | TH | Condiments | M | TODO | 2026-04-07 | | |
| 6921 | Red Curry Paste | Thai Kitchen | TH | Condiments | M | TODO | 2026-04-07 | | |
| 6924 | Yakult Probiotic Drink | Yakult | JP | Dairy | H | TODO | 2026-04-07 | | |
| 6925 | Mochi Ice Cream Mango | My/Mo | JP | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 6926 | Mochi Ice Cream Strawberry | My/Mo | JP | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 6928 | Sriracha Mayo | Kewpie | JP | Condiments | M | TODO | 2026-04-07 | | |
| 6929 | Japanese Mayonnaise | Kewpie | JP | Condiments | H | TODO | 2026-04-07 | | |
| 6930 | Prawn Crackers | Calbee | JP | Snacks | M | TODO | 2026-04-07 | | |
| 6931 | Shrimp Chips | Calbee | JP | Snacks | M | TODO | 2026-04-07 | | |
| 6934 | Biscuit Wafer Chocolate | Knoppers | DE | Snacks | M | TODO | 2026-04-07 | | |
| 6935 | Aero Mint Chocolate Bar | Nestle | GB | Candy | M | TODO | 2026-04-07 | | |
| 6936 | Bounty Coconut Bar | Mars | GB | Candy | M | TODO | 2026-04-07 | | |
| 6940 | Stroopwafels Caramel | Daelmans | NL | Cookies | H | TODO | 2026-04-07 | | Dutch classic |
| 6941 | Lays Paprika Chips | Lay's | NL | Snacks | M | TODO | 2026-04-07 | | European flavor |
| 6942 | Manner Wafers Original | Manner | AT | Cookies | M | TODO | 2026-04-07 | | Austrian classic |
| 6943 | Pocky Cookies & Cream | Glico | JP | Snacks | M | TODO | 2026-04-07 | | |
| 6944 | Meiji Hello Panda Chocolate | Meiji | JP | Snacks | M | TODO | 2026-04-07 | | |
| 6945 | Yan Yan Chocolate Dip | Meiji | JP | Snacks | M | TODO | 2026-04-07 | | |
| 6946 | Koala's March Chocolate | Lotte | JP | Snacks | M | TODO | 2026-04-07 | | |
| 6947 | Pepero Chocolate | Lotte | KR | Snacks | M | TODO | 2026-04-07 | | Korean Pocky |
| 6948 | Choco Pie | Lotte | KR | Snacks | M | TODO | 2026-04-07 | | |
| 6949 | Shrimp Flavored Chips | Nongshim | KR | Snacks | M | TODO | 2026-04-07 | | |
| 6950 | Banana Kick | Nongshim | KR | Snacks | M | TODO | 2026-04-07 | | |
| 6951 | Calpico Water Original | Calpis | JP | Beverages | M | TODO | 2026-04-07 | | |
| 6952 | Ramune Soda Original | Ramune | JP | Beverages | M | TODO | 2026-04-07 | | |
| 6955 | Leibniz Butter Biscuits | Bahlsen | DE | Cookies | M | TODO | 2026-04-07 | | |
| 6956 | Prince Chocolate Biscuits | LU | FR | Cookies | M | TODO | 2026-04-07 | | |
| 6957 | Milo Chocolate Malt Drink | Nestle | AU | Beverages | M | TODO | 2026-04-07 | | |
| 6958 | Vegemite Spread | Bega | AU | Spreads | M | TODO | 2026-04-07 | | Australian icon |
| 6959 | Walkers Cheese & Onion Crisps | Walkers | GB | Snacks | M | TODO | 2026-04-07 | | |
| 6960 | HP Brown Sauce | HP | GB | Condiments | M | TODO | 2026-04-07 | | |
| 6961 | PG Tips Tea Bags | PG Tips | GB | Beverages | M | TODO | 2026-04-07 | | |
| 6962 | Yorkshire Tea Bags | Yorkshire Tea | GB | Beverages | M | TODO | 2026-04-07 | | |
| 6963 | Bonne Maman Strawberry Preserves | Bonne Maman | FR | Spreads | H | TODO | 2026-04-07 | | |
| 6964 | Bonne Maman Raspberry Preserves | Bonne Maman | FR | Spreads | M | TODO | 2026-04-07 | | |
| 6965 | Bonne Maman Four Fruits Preserves | Bonne Maman | FR | Spreads | M | TODO | 2026-04-07 | | |
| 6967 | Indomie Soto Mie | Indomie | ID | Noodles | M | TODO | 2026-04-07 | | |
| 6968 | Samyang Buldak Corn | Samyang | KR | Noodles | M | TODO | 2026-04-07 | | |
| 6970 | Nissin Demae Ramen Sesame | Nissin | JP | Noodles | M | TODO | 2026-04-07 | | |

## Section 121: Breakfast & Pantry Staples (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 6971 | Eggo Homestyle Waffles | Kellogg's | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 6972 | Eggo Buttermilk Waffles | Kellogg's | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 6973 | Eggo Blueberry Waffles | Kellogg's | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 6974 | Eggo Chocolate Chip Waffles | Kellogg's | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 6975 | Pop-Tarts Frosted Strawberry | Kellogg's | US | Snacks | H | TODO | 2026-04-07 | | |
| 6977 | Pop-Tarts Frosted S'mores | Kellogg's | US | Snacks | M | TODO | 2026-04-07 | | |
| 6978 | Pop-Tarts Frosted Blueberry | Kellogg's | US | Snacks | M | TODO | 2026-04-07 | | |
| 6979 | Pop-Tarts Frosted Chocolate Fudge | Kellogg's | US | Snacks | M | TODO | 2026-04-07 | | |
| 6980 | Pop-Tarts Frosted Cherry | Kellogg's | US | Snacks | M | TODO | 2026-04-07 | | |
| 6981 | Toaster Strudel Strawberry | Pillsbury | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 6982 | Toaster Strudel Apple | Pillsbury | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 6984 | Jimmy Dean Sausage Egg & Cheese Croissant | Jimmy Dean | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 6985 | Jimmy Dean Sausage Egg & Cheese Biscuit | Jimmy Dean | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 6992 | Oscar Mayer Beef Bologna | Oscar Mayer | US | Deli | M | TODO | 2026-04-07 | | |
| 6993 | Oscar Mayer Deli Fresh Oven Roasted Turkey | Oscar Mayer | US | Deli | H | TODO | 2026-04-07 | | |
| 6994 | Oscar Mayer Lunchables Cracker Stackers Turkey | Oscar Mayer | US | Snacks | H | TODO | 2026-04-07 | | Kids favorite |
| 6995 | Oscar Mayer Lunchables Pizza | Oscar Mayer | US | Snacks | H | TODO | 2026-04-07 | | |
| 6996 | Oscar Mayer Lunchables Nachos | Oscar Mayer | US | Snacks | M | TODO | 2026-04-07 | | |
| 6998 | Hormel Natural Choice Oven Roasted Turkey | Hormel | US | Deli | M | TODO | 2026-04-07 | | |
| 7000 | Kraft Mac & Cheese Original | Kraft | US | Pasta | H | TODO | 2026-04-07 | | Iconic blue box |
| 7001 | Kraft Mac & Cheese Shapes | Kraft | US | Pasta | M | TODO | 2026-04-07 | | |
| 7002 | Kraft Mac & Cheese Deluxe | Kraft | US | Pasta | M | TODO | 2026-04-07 | | |
| 7003 | Kraft Velveeta Shells & Cheese | Kraft | US | Pasta | H | TODO | 2026-04-07 | | |
| 7004 | Velveeta Block | Kraft | US | Dairy | H | TODO | 2026-04-07 | | |
| 7009 | Jif Crunchy Peanut Butter | Jif | US | Spreads | H | TODO | 2026-04-07 | | |
| 7010 | Jif Natural Creamy Peanut Butter | Jif | US | Spreads | M | TODO | 2026-04-07 | | |
| 7012 | Skippy Super Chunk Peanut Butter | Skippy | US | Spreads | M | TODO | 2026-04-07 | | |
| 7013 | Skippy Natural Creamy Peanut Butter | Skippy | US | Spreads | M | TODO | 2026-04-07 | | |
| 7014 | Smucker's Strawberry Jam | Smucker's | US | Spreads | H | TODO | 2026-04-07 | | |
| 7016 | Smucker's Natural Peanut Butter | Smucker's | US | Spreads | M | TODO | 2026-04-07 | | |
| 7017 | Smucker's Uncrustables PB&J Grape | Smucker's | US | Frozen Meals | H | TODO | 2026-04-07 | | Kids lunch staple |
| 7018 | Smucker's Uncrustables PB&J Strawberry | Smucker's | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 7019 | Mrs. Butterworth's Original Syrup | Mrs. Butterworth's | US | Condiments | M | TODO | 2026-04-07 | | |
| 7020 | Aunt Jemima Original Pancake Mix | Aunt Jemima | US | Baking | M | TODO | 2026-04-07 | | Now Pearl Milling Co |
| 7021 | Bisquick Original Pancake Mix | Betty Crocker | US | Baking | H | TODO | 2026-04-07 | | |
| 7022 | Betty Crocker Super Moist Yellow Cake Mix | Betty Crocker | US | Baking | H | TODO | 2026-04-07 | | |
| 7023 | Betty Crocker Super Moist Chocolate Cake Mix | Betty Crocker | US | Baking | H | TODO | 2026-04-07 | | |
| 7024 | Betty Crocker Rich & Creamy Chocolate Frosting | Betty Crocker | US | Baking | M | TODO | 2026-04-07 | | |
| 7025 | Duncan Hines Classic Yellow Cake Mix | Duncan Hines | US | Baking | M | TODO | 2026-04-07 | | |
| 7029 | King Arthur Bread Flour | King Arthur | US | Baking | M | TODO | 2026-04-07 | | |
| 7030 | Crisco Vegetable Shortening | Crisco | US | Baking | M | TODO | 2026-04-07 | | |
| 7032 | PAM Original Cooking Spray | PAM | US | Cooking Oil | H | TODO | 2026-04-07 | | |
| 7037 | Rice-A-Roni Chicken Flavor | Rice-A-Roni | US | Sides | M | TODO | 2026-04-07 | | |
| 7039 | Knorr Rice Sides Cheddar Broccoli | Knorr | US | Sides | M | TODO | 2026-04-07 | | |
| 7040 | Knorr Pasta Sides Alfredo | Knorr | US | Sides | M | TODO | 2026-04-07 | | |
| 7041 | Knorr Pasta Sides Butter | Knorr | US | Sides | M | TODO | 2026-04-07 | | |
| 7042 | Uncle Ben's Ready Rice White | Uncle Ben's | US | Grains | H | TODO | 2026-04-07 | | Now Ben's Original |
| 7043 | Uncle Ben's Ready Rice Brown | Uncle Ben's | US | Grains | M | TODO | 2026-04-07 | | |
| 7044 | Uncle Ben's Ready Rice Jasmine | Uncle Ben's | US | Grains | M | TODO | 2026-04-07 | | |
| 7045 | Minute Rice White | Minute Rice | US | Grains | M | TODO | 2026-04-07 | | |
| 7047 | Idahoan Four Cheese Mashed | Idahoan | US | Sides | M | TODO | 2026-04-07 | | |
| 7048 | Stove Top Stuffing Chicken | Stove Top | US | Sides | M | TODO | 2026-04-07 | | |
| 7050 | McCormick Chili Seasoning | McCormick | US | Condiments | M | TODO | 2026-04-07 | | |
| 7052 | McCormick Ground Cinnamon | McCormick | US | Condiments | M | TODO | 2026-04-07 | | |
| 7054 | Old Bay Seasoning | McCormick | US | Condiments | H | TODO | 2026-04-07 | | Maryland icon |
| 7055 | Lawry's Seasoned Salt | Lawry's | US | Condiments | H | TODO | 2026-04-07 | | |
| 7056 | Tony Chachere's Creole Seasoning | Tony Chachere's | US | Condiments | M | TODO | 2026-04-07 | | |
| 7057 | Tajin Clasico Seasoning | Tajin | MX | Condiments | H | TODO | 2026-04-07 | | Trending |
| 7058 | Bragg Liquid Aminos | Bragg | US | Condiments | M | TODO | 2026-04-07 | | |
| 7068 | Tahini Organic | Soom | US | Condiments | M | TODO | 2026-04-07 | | |
| 7070 | Harissa Paste | DEA | TN | Condiments | M | TODO | 2026-04-07 | | North African chili |

## Section 122: Frozen Snacks & Appetizers (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 7075 | Party Pizza Combination | Totino's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7080 | Lean Pockets Chicken Broccoli & Cheddar | Lean Pockets | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 7081 | Bagel Bites Three Cheese | Bagel Bites | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 7082 | Bagel Bites Pepperoni & Cheese | Bagel Bites | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 7083 | DiGiorno Rising Crust Pepperoni | DiGiorno | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 7084 | DiGiorno Rising Crust Supreme | DiGiorno | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 7085 | DiGiorno Rising Crust Four Cheese | DiGiorno | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 7086 | DiGiorno Stuffed Crust Pepperoni | DiGiorno | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7087 | DiGiorno Croissant Crust Pepperoni | DiGiorno | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7088 | Red Baron Classic Crust Pepperoni | Red Baron | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 7089 | Red Baron Classic Crust Four Cheese | Red Baron | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7090 | Red Baron French Bread Pepperoni | Red Baron | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7091 | Tombstone Original Pepperoni | Tombstone | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7092 | Tombstone Original Supreme | Tombstone | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7093 | Jack's Original Pepperoni | Jack's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7094 | California Pizza Kitchen BBQ Chicken | CPK | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7095 | California Pizza Kitchen Margherita | CPK | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7096 | Ore-Ida Golden Fries | Ore-Ida | US | Frozen Sides | H | TODO | 2026-04-07 | | |
| 7097 | Ore-Ida Tater Tots | Ore-Ida | US | Frozen Sides | H | TODO | 2026-04-07 | | |
| 7098 | Ore-Ida Crispy Crowns | Ore-Ida | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 7099 | Ore-Ida Extra Crispy Fast Food Fries | Ore-Ida | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 7102 | McCain Smiles Mashed Potato Shapes | McCain | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 7105 | TGI Fridays Honey BBQ Wings | TGI Friday's | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 7108 | Tyson Chicken Strips | Tyson | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 7109 | Tyson Any'tizers Boneless Chicken Bites | Tyson | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 7110 | Tyson Any'tizers Buffalo Style Chicken Bites | Tyson | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 7111 | Tyson Grilled Chicken Breast Strips | Tyson | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 7112 | Perdue Simply Smart Chicken Breast Tenders | Perdue | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7113 | Perdue Chicken Breast Nuggets | Perdue | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7114 | Gorton's Beer Battered Fish Fillets | Gorton's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7115 | Gorton's Crunchy Breaded Fish Sticks | Gorton's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7116 | Van de Kamp's Fish Sticks | Van de Kamp's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7117 | Mrs. T's Pierogies Potato & Cheddar | Mrs. T's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7118 | Mrs. T's Pierogies Potato & Onion | Mrs. T's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7119 | El Monterey Beef & Bean Burritos | El Monterey | US | Frozen Meals | H | TODO | 2026-04-07 | | |
| 7120 | El Monterey Chicken & Cheese Taquitos | El Monterey | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 7121 | Jose Ole Chicken & Cheese Taquitos | Jose Ole | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 7122 | Jose Ole Beef & Cheese Chimichangas | Jose Ole | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7123 | Delimex Chicken & Cheese Taquitos | Delimex | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 7124 | White Castle Sliders Original 6-Pack | White Castle | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7125 | White Castle Sliders Jalapeno Cheeseburger | White Castle | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7132 | Newman's Own Thin & Crispy Margherita | Newman's Own | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7133 | Caulipower Cauliflower Crust Margherita | Caulipower | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7134 | Caulipower Cauliflower Crust Pepperoni | Caulipower | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7136 | Freschetta Naturally Rising Pepperoni | Freschetta | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7137 | Freschetta Brick Oven Pepperoni | Freschetta | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7139 | Farm Rich Mozzarella Sticks | Farm Rich | US | Frozen Snacks | H | TODO | 2026-04-07 | | |
| 7140 | Farm Rich Jalapeno Peppers | Farm Rich | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 7141 | Farm Rich Mushrooms Breaded | Farm Rich | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 7145 | Eggo Thick & Fluffy Waffles | Kellogg's | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 7146 | Eggo Mini Pancakes | Kellogg's | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 7147 | Hot Pockets Steak & Cheddar | Hot Pockets | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 7148 | DiGiorno Thin Crust Pepperoni | DiGiorno | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7149 | Red Baron Thin Crust Pepperoni | Red Baron | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7151 | Perdue Chicken Plus Nuggets (with veggies) | Perdue | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7152 | El Monterey Signature Chicken Burritos | El Monterey | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7153 | Jose Ole Steak & Cheese Chimichangas | Jose Ole | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7154 | PF Chang's Pork Dumplings | PF Chang's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7155 | Ore-Ida Shoestring Fries | Ore-Ida | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 7158 | Alexia Organic Yukon Select Fries | Alexia | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 7160 | Nathan's Famous Crinkle Cut Fries | Nathan's | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 7161 | Nathan's Famous Jumbo Crinkle Cut Fries | Nathan's | US | Frozen Sides | M | TODO | 2026-04-07 | | |
| 7162 | Gorton's Grilled Tilapia | Gorton's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7163 | SeaPak Popcorn Shrimp | SeaPak | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7164 | SeaPak Butterfly Shrimp | SeaPak | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7166 | Applegate Naturals Turkey Hot Dogs | Applegate | US | Meat | M | TODO | 2026-04-07 | | |
| 7167 | Applegate Naturals Uncured Beef Hot Dogs | Applegate | US | Meat | M | TODO | 2026-04-07 | | |
| 7168 | Hebrew National Beef Franks | Hebrew National | US | Meat | H | TODO | 2026-04-07 | | |
| 7169 | Ball Park Beef Franks | Ball Park | US | Meat | H | TODO | 2026-04-07 | | |
| 7170 | Nathan's Famous Beef Franks | Nathan's | US | Meat | M | TODO | 2026-04-07 | | |

## Section 123: Coffee & Energy Drinks (100 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 7171 | Pike Place Roast K-Cup | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 7172 | French Roast K-Cup | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 7173 | Blonde Roast K-Cup | Starbucks | US | Beverages | M | TODO | 2026-04-07 | | |
| 7174 | Frappuccino Mocha Bottled | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 7175 | Frappuccino Vanilla Bottled | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 7176 | Doubleshot Espresso Can | Starbucks | US | Beverages | H | TODO | 2026-04-07 | | |
| 7177 | Doubleshot Energy Mocha | Starbucks | US | Beverages | M | TODO | 2026-04-07 | | |
| 7179 | Dunkin' Original Blend K-Cup | Dunkin' | US | Beverages | H | TODO | 2026-04-07 | | |
| 7180 | Dunkin' French Vanilla K-Cup | Dunkin' | US | Beverages | M | TODO | 2026-04-07 | | |
| 7183 | Folgers Classic Roast Ground | Folgers | US | Beverages | H | TODO | 2026-04-07 | | |
| 7184 | Folgers Black Silk Ground | Folgers | US | Beverages | M | TODO | 2026-04-07 | | |
| 7185 | Maxwell House Original Roast | Maxwell House | US | Beverages | M | TODO | 2026-04-07 | | |
| 7186 | Peet's Major Dickason's K-Cup | Peet's | US | Beverages | M | TODO | 2026-04-07 | | |
| 7187 | Peet's Big Bang Medium Roast | Peet's | US | Beverages | M | TODO | 2026-04-07 | | |
| 7188 | Lavazza Super Crema Espresso | Lavazza | IT | Beverages | M | TODO | 2026-04-07 | | |
| 7189 | Lavazza Qualita Oro Ground | Lavazza | IT | Beverages | M | TODO | 2026-04-07 | | |
| 7190 | Illy Classico Whole Bean | Illy | IT | Beverages | M | TODO | 2026-04-07 | | |
| 7191 | Death Wish Coffee Ground | Death Wish | US | Beverages | M | TODO | 2026-04-07 | | Extra strong |
| 7192 | Green Mountain Breakfast Blend K-Cup | Green Mountain | US | Beverages | H | TODO | 2026-04-07 | | |
| 7193 | Green Mountain Nantucket Blend K-Cup | Green Mountain | US | Beverages | M | TODO | 2026-04-07 | | |
| 7194 | Cafe Bustelo Espresso Ground | Cafe Bustelo | US | Beverages | H | TODO | 2026-04-07 | | |
| 7195 | Cafe Bustelo K-Cup | Cafe Bustelo | US | Beverages | M | TODO | 2026-04-07 | | |
| 7196 | Nescafe Clasico Instant Coffee | Nescafe | CH | Beverages | M | TODO | 2026-04-07 | | |
| 7197 | International Delight French Vanilla Creamer | International Delight | US | Dairy | H | TODO | 2026-04-07 | | |
| 7198 | International Delight Caramel Macchiato Creamer | International Delight | US | Dairy | M | TODO | 2026-04-07 | | |
| 7199 | Coffee-mate French Vanilla Creamer | Coffee-mate | US | Dairy | H | TODO | 2026-04-07 | | |
| 7200 | Coffee-mate Hazelnut Creamer | Coffee-mate | US | Dairy | M | TODO | 2026-04-07 | | |
| 7201 | Chobani Coffee Creamer Sweet Cream | Chobani | US | Dairy | M | TODO | 2026-04-07 | | |
| 7202 | Nutpods Original Unsweetened Creamer | Nutpods | US | Dairy Alt | M | TODO | 2026-04-07 | | Dairy-free |
| 7211 | Monster Rehab Tea + Lemonade | Monster | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7212 | Monster Java Mean Bean | Monster | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7213 | Rockstar Original | Rockstar | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7214 | Rockstar Sugar Free | Rockstar | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7215 | Rockstar Recovery Lemonade | Rockstar | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7216 | 5-Hour Energy Original Berry | 5-Hour Energy | US | Energy Drinks | H | TODO | 2026-04-07 | | |
| 7217 | 5-Hour Energy Extra Strength Grape | 5-Hour Energy | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7218 | Bang Energy Rainbow Unicorn | Bang | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7220 | Bang Energy Cherry Blade Lemonade | Bang | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7221 | Reign Total Body Fuel Lemon HDZ | Reign | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7222 | Reign Total Body Fuel Orange Dreamsicle | Reign | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7223 | Reign Total Body Fuel Melon Mania | Reign | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7225 | C4 Energy Frozen Bombsicle | C4 | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7226 | C4 Energy Strawberry Watermelon | C4 | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7227 | ZOA Energy Original | ZOA | US | Energy Drinks | M | TODO | 2026-04-07 | | The Rock's brand |
| 7228 | ZOA Energy Wild Orange | ZOA | US | Energy Drinks | M | TODO | 2026-04-07 | | |
| 7229 | Coca-Cola Classic 12oz | Coca-Cola | US | Beverages | H | TODO | 2026-04-07 | | |
| 7231 | Coca-Cola Zero Sugar 12oz | Coca-Cola | US | Beverages | H | TODO | 2026-04-07 | | |
| 7232 | Sprite 12oz | Coca-Cola | US | Beverages | H | TODO | 2026-04-07 | | |
| 7234 | Pepsi 12oz | PepsiCo | US | Beverages | H | TODO | 2026-04-07 | | |
| 7241 | 7UP 12oz | Keurig Dr Pepper | US | Beverages | M | TODO | 2026-04-07 | | |
| 7243 | Canada Dry Ginger Ale 12oz | Keurig Dr Pepper | US | Beverages | M | TODO | 2026-04-07 | | |
| 7246 | Mello Yello 12oz | Coca-Cola | US | Beverages | L | TODO | 2026-04-07 | | |
| 7247 | Sierra Mist (Starry) 12oz | PepsiCo | US | Beverages | M | TODO | 2026-04-07 | | |
| 7252 | Olipop Vintage Cola | Olipop | US | Beverages | H | TODO | 2026-04-07 | | Prebiotic soda |
| 7253 | Olipop Strawberry Vanilla | Olipop | US | Beverages | H | TODO | 2026-04-07 | | |
| 7254 | Olipop Orange Squeeze | Olipop | US | Beverages | M | TODO | 2026-04-07 | | |
| 7255 | Olipop Ginger Lemon | Olipop | US | Beverages | M | TODO | 2026-04-07 | | |
| 7256 | Olipop Root Beer | Olipop | US | Beverages | M | TODO | 2026-04-07 | | |
| 7257 | Poppi Strawberry Lemon Prebiotic Soda | Poppi | US | Beverages | H | TODO | 2026-04-07 | | |
| 7258 | Poppi Orange Prebiotic Soda | Poppi | US | Beverages | M | TODO | 2026-04-07 | | |
| 7259 | Poppi Cola Prebiotic Soda | Poppi | US | Beverages | M | TODO | 2026-04-07 | | |
| 7260 | Zevia Zero Calorie Cola | Zevia | US | Beverages | M | TODO | 2026-04-07 | | Stevia sweetened |
| 7261 | Zevia Zero Calorie Ginger Ale | Zevia | US | Beverages | M | TODO | 2026-04-07 | | |
| 7262 | Zevia Zero Calorie Cream Soda | Zevia | US | Beverages | M | TODO | 2026-04-07 | | |
| 7263 | Athletic Brewing Run Wild IPA (NA Beer) | Athletic Brewing | US | Beverages | M | TODO | 2026-04-07 | | Non-alcoholic |
| 7264 | Athletic Brewing Free Wave Hazy IPA | Athletic Brewing | US | Beverages | M | TODO | 2026-04-07 | | |
| 7265 | Heineken 0.0 Non-Alcoholic Beer | Heineken | NL | Beverages | M | TODO | 2026-04-07 | | |
| 7266 | Guinness 0 Non-Alcoholic Stout | Guinness | IE | Beverages | M | TODO | 2026-04-07 | | |
| 7267 | Liquid Death Mountain Water | Liquid Death | US | Beverages | H | TODO | 2026-04-07 | | Trending brand |
| 7269 | Liquid Death Mango Chainsaw | Liquid Death | US | Beverages | M | TODO | 2026-04-07 | | |
| 7270 | Liquid Death Berry It Alive | Liquid Death | US | Beverages | M | TODO | 2026-04-07 | | |

## Section 124: Additional Grocery & Specialty (380 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date | Assigned | Notes |
|---|-----------|-------|---------|----------|----------|--------|------|----------|-------|
| 7271 | Original Hummus | Sabra | US | Dips | H | TODO | 2026-04-07 | | #1 hummus brand |
| 7272 | Roasted Red Pepper Hummus | Sabra | US | Dips | H | TODO | 2026-04-07 | | |
| 7273 | Classic Guacamole | Sabra | US | Dips | M | TODO | 2026-04-07 | | |
| 7274 | Roasted Garlic Hummus | Sabra | US | Dips | M | TODO | 2026-04-07 | | |
| 7275 | Supremely Spicy Hummus | Sabra | US | Dips | M | TODO | 2026-04-07 | | |
| 7276 | Classic Guacamole | Wholly Guacamole | US | Dips | H | TODO | 2026-04-07 | | |
| 7277 | Spicy Guacamole | Wholly Guacamole | US | Dips | M | TODO | 2026-04-07 | | |
| 7278 | Original Guacamole Cups | Good Foods | US | Dips | M | TODO | 2026-04-07 | | |
| 7279 | Buffalo Style Dip | Good Foods | US | Dips | M | TODO | 2026-04-07 | | |
| 7280 | Queso Blanco Dip | Tostitos | US | Dips | M | TODO | 2026-04-07 | | |
| 7281 | Roasted Garlic Hummus | Cedar's | US | Dips | M | TODO | 2026-04-07 | | |
| 7282 | Jalapeño Artichoke Dip | Stonemill Kitchens | US | Dips | M | TODO | 2026-04-07 | | |
| 7285 | Bacon Cheddar Dip | Heluva Good | US | Dips | M | TODO | 2026-04-07 | | |
| 7289 | Everything Hummus | Sabra | US | Dips | M | TODO | 2026-04-07 | | |
| 7290 | Organic Hummus Classic | Hope Foods | US | Dips | M | TODO | 2026-04-07 | | |
| 7295 | Epic Venison Sea Salt Pepper Bar | Epic | US | Snacks | M | TODO | 2026-04-07 | | |
| 7296 | Chomps Original Beef Stick | Chomps | US | Snacks | M | TODO | 2026-04-07 | | Whole30 approved |
| 7297 | Chomps Italian Style Beef | Chomps | US | Snacks | M | TODO | 2026-04-07 | | |
| 7301 | Blue Diamond Almonds Whole Natural | Blue Diamond | US | Snacks | H | TODO | 2026-04-07 | | |
| 7302 | Blue Diamond Almonds Smokehouse | Blue Diamond | US | Snacks | H | TODO | 2026-04-07 | | |
| 7303 | Blue Diamond Almonds Wasabi & Soy | Blue Diamond | US | Snacks | M | TODO | 2026-04-07 | | |
| 7304 | Blue Diamond Almonds Salt & Vinegar | Blue Diamond | US | Snacks | M | TODO | 2026-04-07 | | |
| 7306 | Planters Mixed Nuts | Planters | US | Snacks | H | TODO | 2026-04-07 | | |
| 7307 | Planters Cashews Salted | Planters | US | Snacks | M | TODO | 2026-04-07 | | |
| 7308 | Planters NUT-rition Heart Healthy Mix | Planters | US | Snacks | M | TODO | 2026-04-07 | | |
| 7309 | Sahale Snacks Glazed Mix Pomegranate | Sahale | US | Snacks | M | TODO | 2026-04-07 | | |
| 7314 | Sun-Maid Raisins | Sun-Maid | US | Snacks | H | TODO | 2026-04-07 | | |
| 7315 | Bare Baked Crunchy Apple Chips | Bare | US | Snacks | M | TODO | 2026-04-07 | | |
| 7317 | Dang Coconut Chips Original | Dang | US | Snacks | M | TODO | 2026-04-07 | | |
| 7318 | Lesser Evil Himalayan Pink Salt Popcorn | Lesser Evil | US | Snacks | M | TODO | 2026-04-07 | | |
| 7322 | Siete Cashew Queso | Siete | US | Dips | M | TODO | 2026-04-07 | | |
| 7329 | Lily's Salted Caramel Chocolate Bar | Lily's | US | Candy | M | TODO | 2026-04-07 | | |
| 7333 | 88 Acres Seed Butter Chocolate Sunflower | 88 Acres | US | Spreads | L | TODO | 2026-04-07 | | Nut-free |
| 7334 | SunButter Creamy Sunflower Butter | SunButter | US | Spreads | M | TODO | 2026-04-07 | | Nut-free |
| 7335 | Wild Friends Chocolate Peanut Butter | Wild Friends | US | Spreads | L | TODO | 2026-04-07 | | |
| 7336 | Noka Superfood Smoothie Blueberry Beet | Noka | US | Beverages | L | TODO | 2026-04-07 | | |
| 7337 | Annie's Classic Mac & Cheese | Annie's | US | Pasta | H | TODO | 2026-04-07 | | Organic kids |
| 7338 | Annie's White Cheddar Bunny Mac & Cheese | Annie's | US | Pasta | H | TODO | 2026-04-07 | | |
| 7339 | Annie's Cheddar Bunnies Crackers | Annie's | US | Snacks | H | TODO | 2026-04-07 | | |
| 7341 | Annie's Organic Pizza Poppers | Annie's | US | Frozen Snacks | M | TODO | 2026-04-07 | | |
| 7344 | Mott's Applesauce Original | Mott's | US | Snacks | H | TODO | 2026-04-07 | | |
| 7345 | Mott's Applesauce No Sugar Added | Mott's | US | Snacks | M | TODO | 2026-04-07 | | |
| 7346 | GoGo squeeZ Apple Apple | GoGo squeeZ | US | Snacks | H | TODO | 2026-04-07 | | Kids pouches |
| 7347 | GoGo squeeZ Apple Strawberry | GoGo squeeZ | US | Snacks | M | TODO | 2026-04-07 | | |
| 7351 | Snapea Crisps Caesar | Harvest Snaps | US | Snacks | M | TODO | 2026-04-07 | | |
| 7354 | Sahale Snacks Honey Almonds | Sahale | US | Snacks | M | TODO | 2026-04-07 | | |
| 7355 | That's It Mini Fruit Bars Apple Strawberry | That's It | US | Snacks | L | TODO | 2026-04-07 | | |
| 7356 | Rhythm Superfoods Kale Chips Zesty Nacho | Rhythm | US | Snacks | L | TODO | 2026-04-07 | | |
| 7360 | 365 Organic Peanut Butter Creamy | 365 (Whole Foods) | US | Spreads | M | TODO | 2026-04-07 | | |
| 7362 | 365 Organic Baby Spinach | 365 (Whole Foods) | US | Produce | M | TODO | 2026-04-07 | | |
| 7363 | 365 Organic Eggs Large | 365 (Whole Foods) | US | Dairy | M | TODO | 2026-04-07 | | |
| 7367 | Vital Farms Pasture-Raised Eggs | Vital Farms | US | Dairy | H | TODO | 2026-04-07 | | Premium eggs |
| 7368 | Eggland's Best Eggs Large | Eggland's Best | US | Dairy | H | TODO | 2026-04-07 | | |
| 7369 | Pete and Gerry's Organic Free Range Eggs | Pete and Gerry's | US | Dairy | M | TODO | 2026-04-07 | | |
| 7370 | Nellie's Free Range Eggs | Nellie's | US | Dairy | M | TODO | 2026-04-07 | | |
| 7371 | Kerrygold Pure Irish Butter | Kerrygold | IE | Dairy | H | TODO | 2026-04-07 | | Grass-fed |
| 7372 | Kerrygold Dubliner Cheese | Kerrygold | IE | Dairy | M | TODO | 2026-04-07 | | |
| 7373 | Challenge Butter | Challenge | US | Dairy | M | TODO | 2026-04-07 | | |
| 7374 | Plugra European Style Butter | Plugra | US | Dairy | M | TODO | 2026-04-07 | | |
| 7375 | Ghee Organic Original | 4th & Heart | US | Dairy | M | TODO | 2026-04-07 | | |
| 7376 | Ghee Organic | Ancient Organics | US | Dairy | M | TODO | 2026-04-07 | | |
| 7377 | Babybel Original | Babybel | FR | Dairy | H | TODO | 2026-04-07 | | |
| 7378 | Babybel Light | Babybel | FR | Dairy | M | TODO | 2026-04-07 | | |
| 7379 | Laughing Cow Original Swiss | Laughing Cow | FR | Dairy | H | TODO | 2026-04-07 | | |
| 7380 | Laughing Cow Garlic & Herb | Laughing Cow | FR | Dairy | M | TODO | 2026-04-07 | | |
| 7381 | Boursin Garlic & Fine Herbs | Boursin | FR | Dairy | M | TODO | 2026-04-07 | | |
| 7382 | Boursin Basil & Chive | Boursin | FR | Dairy | L | TODO | 2026-04-07 | | |
| 7383 | Sargento Balanced Breaks Cheese & Crackers | Sargento | US | Snacks | M | TODO | 2026-04-07 | | |
| 7384 | Sargento Sharp Cheddar Slices | Sargento | US | Dairy | M | TODO | 2026-04-07 | | |
| 7386 | Sargento Shredded Mexican Blend | Sargento | US | Dairy | M | TODO | 2026-04-07 | | |
| 7388 | Applegate Organic Uncured Turkey Hot Dog | Applegate | US | Meat | M | TODO | 2026-04-07 | | |
| 7390 | Boar's Head Ovengold Turkey Breast | Boar's Head | US | Deli | H | TODO | 2026-04-07 | | Premium deli |
| 7391 | Boar's Head Deluxe Ham | Boar's Head | US | Deli | M | TODO | 2026-04-07 | | |
| 7393 | Boar's Head Pepperoni | Boar's Head | US | Deli | M | TODO | 2026-04-07 | | |
| 7394 | Columbus Italian Dry Salame | Columbus | US | Deli | M | TODO | 2026-04-07 | | |
| 7396 | Hillshire Farm Ultra Thin Oven Roasted Turkey | Hillshire Farm | US | Deli | H | TODO | 2026-04-07 | | |
| 7397 | Hillshire Farm Lit'l Smokies | Hillshire Farm | US | Meat | H | TODO | 2026-04-07 | | |
| 7398 | Aidells Chicken Apple Sausage | Aidells | US | Meat | M | TODO | 2026-04-07 | | |
| 7399 | Aidells Italian Style Sausage | Aidells | US | Meat | M | TODO | 2026-04-07 | | |
| 7401 | Jennie-O Turkey Breast Ground | Jennie-O | US | Meat | H | TODO | 2026-04-07 | | |
| 7402 | Jennie-O Turkey Burgers | Jennie-O | US | Meat | M | TODO | 2026-04-07 | | |
| 7405 | Butterball Ground Turkey 93/7 | Butterball | US | Meat | H | TODO | 2026-04-07 | | |
| 7406 | Wright Brand Hickory Smoked Bacon | Wright | US | Meat | H | TODO | 2026-04-07 | | Thick cut |
| 7407 | Oscar Mayer Naturally Hardwood Smoked Bacon | Oscar Mayer | US | Meat | H | TODO | 2026-04-07 | | |
| 7408 | Hormel Black Label Bacon | Hormel | US | Meat | H | TODO | 2026-04-07 | | |
| 7409 | Smithfield Thick Cut Bacon | Smithfield | US | Meat | M | TODO | 2026-04-07 | | |
| 7410 | Pederson's No Sugar Added Bacon | Pederson's | US | Meat | M | TODO | 2026-04-07 | | Whole30 |
| 7411 | Niman Ranch Uncured Applewood Smoked Bacon | Niman Ranch | US | Meat | M | TODO | 2026-04-07 | | |
| 7414 | Simple Mills Crunchy Cookies Chocolate Chip | Simple Mills | US | Cookies | M | TODO | 2026-04-07 | | |
| 7415 | Simple Mills Pizza Dough Mix | Simple Mills | US | Baking | L | TODO | 2026-04-07 | | |
| 7416 | Mary's Gone Crackers Original | Mary's Gone Crackers | US | Snacks | M | TODO | 2026-04-07 | | GF organic |
| 7417 | Hu Kitchen Grain-Free Crackers Sea Salt | Hu | US | Snacks | M | TODO | 2026-04-07 | | |
| 7419 | Birch Benders Protein Pancake Mix | Birch Benders | US | Baking | M | TODO | 2026-04-07 | | |
| 7420 | Birch Benders Keto Pancake Mix | Birch Benders | US | Baking | M | TODO | 2026-04-07 | | |
| 7421 | Bob's Red Mill Old Fashioned Oats | Bob's Red Mill | US | Cereal | H | TODO | 2026-04-07 | | |
| 7422 | Bob's Red Mill Organic Steel Cut Oats | Bob's Red Mill | US | Cereal | M | TODO | 2026-04-07 | | |
| 7423 | Bob's Red Mill GF 1 to 1 Baking Flour | Bob's Red Mill | US | Baking | M | TODO | 2026-04-07 | | |
| 7425 | Bob's Red Mill Flaxseed Meal | Bob's Red Mill | US | Baking | M | TODO | 2026-04-07 | | |
| 7426 | Bob's Red Mill Organic Quinoa | Bob's Red Mill | US | Grains | M | TODO | 2026-04-07 | | |
| 7427 | Orgain Organic Protein Shake Chocolate | Orgain | US | Beverages | M | TODO | 2026-04-07 | | |
| 7428 | Orgain Organic Protein Powder Vanilla | Orgain | US | Supplements | M | TODO | 2026-04-07 | | |
| 7429 | Vega One All-in-One Shake Chocolate | Vega | US | Supplements | M | TODO | 2026-04-07 | | Plant-based |
| 7430 | Vega Sport Premium Protein Chocolate | Vega | US | Supplements | M | TODO | 2026-04-07 | | |
| 7431 | Garden of Life Raw Organic Protein Vanilla | Garden of Life | US | Supplements | M | TODO | 2026-04-07 | | |
| 7432 | Amazing Grass Green Superfood Original | Amazing Grass | US | Supplements | M | TODO | 2026-04-07 | | |
| 7433 | AG1 Athletic Greens Powder | AG1 | US | Supplements | H | TODO | 2026-04-07 | | Trending supplement |
| 7436 | Muscle Milk Genuine Protein Shake Chocolate | Muscle Milk | US | Beverages | H | TODO | 2026-04-07 | | |
| 7437 | Muscle Milk Genuine Protein Shake Vanilla | Muscle Milk | US | Beverages | M | TODO | 2026-04-07 | | |
| 7438 | Ensure Original Nutrition Shake Vanilla | Ensure | US | Beverages | H | TODO | 2026-04-07 | | |
| 7439 | Ensure Plus Chocolate | Ensure | US | Beverages | M | TODO | 2026-04-07 | | |
| 7440 | Ensure Max Protein Chocolate | Ensure | US | Beverages | M | TODO | 2026-04-07 | | |
| 7441 | Boost Original Chocolate | Boost | US | Beverages | M | TODO | 2026-04-07 | | |
| 7444 | Carnation Breakfast Essentials Classic French Vanilla | Carnation | US | Beverages | M | TODO | 2026-04-07 | | |
| 7445 | Ovaltine Rich Chocolate Mix | Ovaltine | CH | Beverages | M | TODO | 2026-04-07 | | |
| 7446 | Nesquik Chocolate Powder | Nesquik | US | Beverages | H | TODO | 2026-04-07 | | |
| 7447 | Swiss Miss Hot Cocoa Classic | Swiss Miss | US | Beverages | H | TODO | 2026-04-07 | | |
| 7448 | Swiss Miss Hot Cocoa Marshmallow | Swiss Miss | US | Beverages | M | TODO | 2026-04-07 | | |
| 7449 | Ghirardelli Hot Chocolate Double Chocolate | Ghirardelli | US | Beverages | M | TODO | 2026-04-07 | | |
| 7450 | Abuelita Mexican Hot Chocolate | Nestle | MX | Beverages | M | TODO | 2026-04-07 | | |
| 7451 | McCann's Irish Oatmeal Steel Cut | McCann's | IE | Cereal | M | TODO | 2026-04-07 | | |
| 7453 | Kind Healthy Grains Clusters Vanilla Blueberry | KIND | US | Cereal | M | TODO | 2026-04-07 | | |
| 7454 | Purely Elizabeth Original Ancient Grain Granola | Purely Elizabeth | US | Cereal | M | TODO | 2026-04-07 | | |
| 7456 | Back to Nature Granola Classic | Back to Nature | US | Cereal | M | TODO | 2026-04-07 | | |
| 7457 | Ezekiel 4:9 Sprouted Whole Grain Bread | Food For Life | US | Bread | H | TODO | 2026-04-07 | | |
| 7458 | Ezekiel 4:9 Sprouted Grain English Muffins | Food For Life | US | Bread | M | TODO | 2026-04-07 | | |
| 7459 | Ezekiel 4:9 Sprouted Grain Tortillas | Food For Life | US | Bread | M | TODO | 2026-04-07 | | |
| 7460 | Ezekiel 4:9 Cinnamon Raisin Bread | Food For Life | US | Bread | M | TODO | 2026-04-07 | | |
| 7461 | Silver Hills Sprouted Power Bread | Silver Hills | CA | Bread | L | TODO | 2026-04-07 | | |
| 7462 | Base Culture Keto Bread | Base Culture | US | Bread | L | TODO | 2026-04-07 | | |
| 7463 | Angelic Bakehouse Sprouted 7 Grain Bread | Angelic Bakehouse | US | Bread | L | TODO | 2026-04-07 | | |
| 7464 | La Tortilla Factory Low Carb Tortillas | La Tortilla Factory | US | Bread | M | TODO | 2026-04-07 | | |
| 7466 | Crepini Egg Wraps | Crepini | US | Bread | M | TODO | 2026-04-07 | | |
| 7470 | Naan Dippers Original | Stonefire | US | Snacks | M | TODO | 2026-04-07 | | |
| 7471 | Skinny Pop Mini Cakes Cheddar | SkinnyPop | US | Snacks | M | TODO | 2026-04-07 | | |
| 7472 | Smart Sweets Peach Rings | Smart Sweets | US | Candy | M | TODO | 2026-04-07 | | Low sugar |
| 7473 | Yasso Mint Chocolate Chip Frozen Greek Yogurt Bar | Yasso | US | Frozen Desserts | H | TODO | 2026-04-07 | | |
| 7474 | Yasso Chocolate Fudge Frozen Greek Yogurt Bar | Yasso | US | Frozen Desserts | H | TODO | 2026-04-07 | | |
| 7477 | Nick's Light Ice Cream Swedish Strawberry | Nick's | SE | Ice Cream | M | TODO | 2026-04-07 | | Low calorie |
| 7478 | Nick's Light Ice Cream Peanot Butter Cup | Nick's | SE | Ice Cream | M | TODO | 2026-04-07 | | |
| 7479 | Enlightened Keto Collection Chocolate Peanut Butter | Enlightened | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 7481 | Arctic Zero Chocolate Peanut Butter | Arctic Zero | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 7482 | Clio Greek Yogurt Bar Chocolate | Clio | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 7483 | Outshine Strawberry Fruit Bars | Outshine | US | Frozen Desserts | H | TODO | 2026-04-07 | | |
| 7484 | Outshine Mango Fruit Bars | Outshine | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 7486 | Dole Whip Frozen Treat Pineapple | Dole | US | Frozen Desserts | M | TODO | 2026-04-07 | | Disney Parks famous |
| 7487 | Dole Fruit Cups Diced Peaches | Dole | US | Snacks | M | TODO | 2026-04-07 | | |
| 7489 | Snack Pack Chocolate Pudding | Snack Pack | US | Snacks | H | TODO | 2026-04-07 | | |
| 7490 | Snack Pack Vanilla Pudding | Snack Pack | US | Snacks | M | TODO | 2026-04-07 | | |
| 7491 | Jell-O Chocolate Pudding Cup | Jell-O | US | Snacks | H | TODO | 2026-04-07 | | |
| 7492 | Jell-O Vanilla Pudding Cup | Jell-O | US | Snacks | M | TODO | 2026-04-07 | | |
| 7493 | Jell-O Strawberry Gelatin Cup | Jell-O | US | Snacks | M | TODO | 2026-04-07 | | |
| 7494 | Kozy Shack Rice Pudding | Kozy Shack | US | Snacks | M | TODO | 2026-04-07 | | |
| 7495 | Kozy Shack Tapioca Pudding | Kozy Shack | US | Snacks | M | TODO | 2026-04-07 | | |
| 7496 | Cool Whip Original | Cool Whip | US | Dairy | H | TODO | 2026-04-07 | | |
| 7498 | Dream Whip Whipped Topping | Dream Whip | US | Baking | L | TODO | 2026-04-07 | | |
| 7499 | Dannon Danimals Strawberry Yogurt | Dannon | US | Dairy | M | TODO | 2026-04-07 | | Kids yogurt |
| 7500 | Dannon Danimals Smoothie Strawberry Banana | Dannon | US | Dairy | M | TODO | 2026-04-07 | | |
| 7501 | Land O'Lakes Half & Half | Land O'Lakes | US | Dairy | M | TODO | 2026-04-07 | | |
| 7509 | Fresh Mozzarella Ball | Galbani | IT | Dairy | M | TODO | 2026-04-07 | | |
| 7510 | BelGioioso Fresh Mozzarella Pearls | BelGioioso | US | Dairy | M | TODO | 2026-04-07 | | |
| 7511 | BelGioioso Burrata | BelGioioso | US | Dairy | M | TODO | 2026-04-07 | | |
| 7512 | Président Brie | Président | FR | Dairy | M | TODO | 2026-04-07 | | |
| 7513 | Alouette Garlic & Herbs Spread | Alouette | FR | Dairy | M | TODO | 2026-04-07 | | |
| 7514 | La Banderita Flour Tortillas | La Banderita | US | Bread | M | TODO | 2026-04-07 | | |
| 7515 | Guerrero White Corn Tortillas | Guerrero | MX | Bread | M | TODO | 2026-04-07 | | |
| 7516 | Mi Rancho Organic Flour Tortillas | Mi Rancho | US | Bread | L | TODO | 2026-04-07 | | |
| 7517 | Schar Gluten Free Multigrain Bread | Schar | IT | Bread | M | TODO | 2026-04-07 | | |
| 7518 | Schar Gluten Free Ciabatta Rolls | Schar | IT | Bread | L | TODO | 2026-04-07 | | |
| 7519 | Three Bridges Egg Bites Uncured Bacon | Three Bridges | US | Dairy | M | TODO | 2026-04-07 | | Starbucks-style |
| 7520 | Kodiak Power Waffles Buttermilk & Vanilla | Kodiak | US | Frozen Breakfast | H | TODO | 2026-04-07 | | |
| 7521 | Good Food Made Simple Chicken Apple Sausage Burrito | Good Food Made Simple | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 7524 | Wyman's Wild Blueberries Frozen | Wyman's | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 7525 | Dole Frozen Pineapple Chunks | Dole | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 7526 | Cascadian Farm Organic Frozen Blueberries | Cascadian Farm | US | Frozen Fruit | M | TODO | 2026-04-07 | | |
| 7528 | Woodstock Organic Frozen Mango | Woodstock | US | Frozen Fruit | L | TODO | 2026-04-07 | | |
| 7530 | Ben & Jerry's Non-Dairy Chocolate Fudge Brownie | Ben & Jerry's | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 7531 | Talenti Layers Chocolate Cherry Cheesecake | Talenti | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 7532 | Blue Bell Cookie Two Step | Blue Bell | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 7533 | Turkey Hill All Natural Vanilla Bean | Turkey Hill | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 7535 | Breyers CarbSmart Vanilla | Breyers | US | Ice Cream | M | TODO | 2026-04-07 | | Low carb |
| 7536 | Edy's/Dreyer's Outshine No Sugar Added Bars | Outshine | US | Frozen Desserts | M | TODO | 2026-04-07 | | |
| 7537 | Good Humor Toasted Almond Bar | Good Humor | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 7539 | Jeni's Brown Butter Almond Brittle | Jeni's Splendid | US | Ice Cream | M | TODO | 2026-04-07 | | |
| 7540 | Salt & Straw Strawberry Honey Balsamic | Salt & Straw | US | Ice Cream | L | TODO | 2026-04-07 | | |
| 7541 | Ore-Ida Just Crack an Egg Denver Scramble | Ore-Ida | US | Frozen Breakfast | M | TODO | 2026-04-07 | | |
| 7542 | Weight Watchers Smart Ones Angel Hair Marinara | WW (Weight Watchers) | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7543 | PF Chang's Mongolian Beef | PF Chang's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7544 | Michael Angelo's Lasagna with Meat Sauce | Michael Angelo's | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7545 | Bertolli Four Cheese Ravioli | Bertolli | US | Frozen Meals | M | TODO | 2026-04-07 | | |
| 7547 | Applegate Naturals Sunday Bacon Pork | Applegate | US | Meat | M | TODO | 2026-04-07 | | |
| 7548 | Columbus Genoa Salame | Columbus | US | Deli | M | TODO | 2026-04-07 | | |
| 7549 | Belgioioso Parmesan Wedge | BelGioioso | US | Dairy | M | TODO | 2026-04-07 | | |
| 7550 | Sargento Pepper Jack Slices | Sargento | US | Dairy | M | TODO | 2026-04-07 | | |
| 7552 | Cracker Barrel Extra Sharp Cheddar | Cracker Barrel | US | Dairy | M | TODO | 2026-04-07 | | |
| 7555 | Borden Shredded Mozzarella | Borden | US | Dairy | M | TODO | 2026-04-07 | | |
| 7556 | Wholly Avocado Smashed Avocado | Wholly Guacamole | US | Dips | M | TODO | 2026-04-07 | | |
| 7557 | Cedars Hommus Original | Cedar's | US | Dips | M | TODO | 2026-04-07 | | |
| 7558 | Tribe Classic Hummus | Tribe | US | Dips | M | TODO | 2026-04-07 | | |
| 7559 | Ithaca Lemon Garlic Hummus | Ithaca | US | Dips | M | TODO | 2026-04-07 | | |
| 7560 | Bitchin' Sauce Original | Bitchin' Sauce | US | Dips | M | TODO | 2026-04-07 | | Almond-based |
| 7564 | San Marzano DOP Tomatoes | Cento | IT | Canned Goods | M | TODO | 2026-04-07 | | |
| 7565 | Tuttorosso Crushed Tomatoes | Tuttorosso | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 7566 | Rao's Tomato Basil Sauce | Rao's | US | Condiments | M | TODO | 2026-04-07 | | |
| 7567 | La Morena Chipotle Peppers in Adobo | La Morena | MX | Canned Goods | M | TODO | 2026-04-07 | | |
| 7568 | Hatch Green Chile Diced | Hatch | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 7569 | RO*TEL Mild Diced Tomatoes | Rotel | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 7570 | Amy's Organic Chunky Tomato Bisque | Amy's Kitchen | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 7571 | Pacific Foods Organic Chicken Bone Broth | Pacific Foods | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 7573 | Kettle & Fire Bone Broth Chicken | Kettle & Fire | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 7576 | Kitchen Basics Unsalted Chicken Stock | Kitchen Basics | US | Canned Goods | M | TODO | 2026-04-07 | | |
| 7578 | Thai Kitchen Lite Coconut Milk | Thai Kitchen | TH | Canned Goods | M | TODO | 2026-04-07 | | |
| 7579 | Aroy-D Coconut Milk | Aroy-D | TH | Canned Goods | M | TODO | 2026-04-07 | | |
| 7583 | Rancho Gordo Heirloom Beans | Rancho Gordo | US | Grains | L | TODO | 2026-04-07 | | Artisan beans |
| 7584 | Wild Planet Wild Albacore Tuna | Wild Planet | US | Canned Goods | M | TODO | 2026-04-07 | | Sustainable |
| 7585 | Safe Catch Elite Wild Tuna | Safe Catch | US | Canned Goods | M | TODO | 2026-04-07 | | Low mercury |
| 7589 | Crofton Bone Broth Protein Chocolate | Ancient Nutrition | US | Supplements | M | TODO | 2026-04-07 | | |
| 7590 | Manitoba Harvest Hemp Hearts | Manitoba Harvest | CA | Pantry | M | TODO | 2026-04-07 | | |
| 7597 | Yellowbird Blue Agave Sriracha | Yellowbird | US | Condiments | M | TODO | 2026-04-07 | | |
| 7599 | Siete Mild Green Enchilada Sauce | Siete | US | Condiments | L | TODO | 2026-04-07 | | |
| 7601 | Primal Kitchen Chipotle Lime Mayo | Primal Kitchen | US | Condiments | M | TODO | 2026-04-07 | | |
| 7602 | Mike's Hot Honey Extra Hot | Mike's Hot Honey | US | Condiments | M | TODO | 2026-04-07 | | |
| 7604 | Truff Hotter Sauce | Truff | US | Condiments | L | TODO | 2026-04-07 | | |
| 7605 | Tessemae's Organic Ranch | Tessemae's | US | Condiments | M | TODO | 2026-04-07 | | |
| 7607 | Mother-in-Law's Gochujang Fermented Chile Paste | Mother-in-Law's | US | Condiments | M | TODO | 2026-04-07 | | |
| 7608 | CJ Gochujang Hot Pepper Paste | CJ | KR | Condiments | M | TODO | 2026-04-07 | | |
| 7610 | Lao Gan Ma Spicy Chili Crisp | Lao Gan Ma | CN | Condiments | H | TODO | 2026-04-07 | | Chinese chili oil |
| 7611 | Chili Crunch Original | Momofuku | US | Condiments | M | TODO | 2026-04-07 | | David Chang brand |
| 7612 | Everything Sauce | Bitchin' Sauce | US | Condiments | L | TODO | 2026-04-07 | | |
| 7613 | Classico Roasted Red Pepper Alfredo | Classico | US | Condiments | M | TODO | 2026-04-07 | | |
| 7618 | La Colombe Draft Latte Triple Shot | La Colombe | US | Beverages | M | TODO | 2026-04-07 | | |
| 7619 | La Colombe Draft Latte Vanilla | La Colombe | US | Beverages | M | TODO | 2026-04-07 | | |
| 7624 | Silk Oat Yeah Oatmilk Creamer Vanilla | Silk | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 7625 | Califia Farms Better Half Unsweetened | Califia Farms | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 7626 | Oatly Barista Edition Oat Milk | Oatly | SE | Dairy Alt | H | TODO | 2026-04-07 | | |
| 7627 | Chobani Oat Creamer Vanilla | Chobani | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 7628 | Ripple Half & Half Alternative | Ripple | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 7629 | Planet Oat Extra Creamy Oat Milk | Planet Oat | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 7630 | Elmhurst 1925 Oat Milk Barista Edition | Elmhurst | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 7631 | Malk Organic Oat Milk | Malk | US | Dairy Alt | L | TODO | 2026-04-07 | | |
| 7632 | Oat Milk Original Shelf Stable | Chobani | US | Dairy Alt | M | TODO | 2026-04-07 | | |
| 7634 | Organic Valley Half & Half | Organic Valley | US | Dairy | M | TODO | 2026-04-07 | | |
| 7635 | Stonyfield Organic Smoothie Strawberry | Stonyfield | US | Dairy | M | TODO | 2026-04-07 | | |
| 7636 | Fage Total 0% Greek Yogurt | Fage | GR | Dairy | H | TODO | 2026-04-07 | | |
| 7637 | Fage Total 2% Greek Yogurt | Fage | GR | Dairy | H | TODO | 2026-04-07 | | |
| 7638 | Fage Total 5% Greek Yogurt | Fage | GR | Dairy | M | TODO | 2026-04-07 | | |
| 7639 | Fage TruBlend Strawberry | Fage | GR | Dairy | M | TODO | 2026-04-07 | | |
| 7640 | Icelandic Provisions Vanilla Skyr | Icelandic Provisions | IS | Dairy | M | TODO | 2026-04-07 | | |
| 7641 | Icelandic Provisions Strawberry Skyr | Icelandic Provisions | IS | Dairy | M | TODO | 2026-04-07 | | |
| 7642 | Icelandic Provisions Plain Skyr | Icelandic Provisions | IS | Dairy | M | TODO | 2026-04-07 | | |
| 7646 | Peak Triple Cream Yogurt Vanilla | Peak | US | Dairy | L | TODO | 2026-04-07 | | |
| 7647 | Ellenos Real Greek Yogurt Lemon Curd | Ellenos | US | Dairy | L | TODO | 2026-04-07 | | |
| 7648 | Liberté Classique Vanilla | Liberté | CA | Dairy | L | TODO | 2026-04-07 | | |
| 7649 | Astro Original Vanilla | Astro | CA | Dairy | L | TODO | 2026-04-07 | | |

## Section 120: McDonald's Complete Menu (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 7653 | McDonald's Double Quarter Pounder | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7655 | McDonald's Filet-O-Fish | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7656 | McDonald's 10pc Chicken McNuggets | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7657 | McDonald's 20pc Chicken McNuggets | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7659 | McDonald's Crispy Chicken Sandwich | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7660 | McDonald's Spicy Crispy Chicken Sandwich | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7663 | McDonald's Sausage McGriddle | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7664 | McDonald's Bacon Egg Cheese McGriddle | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7669 | McDonald's Fruit & Maple Oatmeal | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7670 | McDonald's Small Fries | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7671 | McDonald's Medium Fries | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7672 | McDonald's Large Fries | McDonald's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7676 | McDonald's Hot Fudge Sundae | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7679 | McDonald's Happy Meal Nuggets 4pc | McDonald's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7680 | McDonald's Apple Slices | McDonald's | US | fast_food | L | TODO | 2026-04-07 | |  |

## Section 121: Wendy's Complete (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 7686 | Wendy's Son of Baconator | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7689 | Wendy's 10pc Nuggets | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7691 | Wendy's Chili Small | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7692 | Wendy's Chili Large | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7695 | Wendy's Small Fries | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7696 | Wendy's Medium Fries | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7697 | Wendy's Frosty Chocolate Medium | Wendy's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7698 | Wendy's Frosty Vanilla Medium | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7700 | Wendy's Pretzel Pub Bacon Cheeseburger | Wendy's | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 122: Taco Bell Complete (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 7708 | Taco Bell Beefy 5-Layer Burrito | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7713 | Taco Bell Power Menu Bowl | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7715 | Taco Bell Chips and Nacho Cheese | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7716 | Taco Bell Quesarito | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7719 | Taco Bell Baja Blast Medium | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7720 | Taco Bell Baja Blast Freeze | Taco Bell | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 123: Burger King Complete (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 7722 | Burger King Whopper Jr | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7723 | Burger King Double Whopper | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7724 | Burger King Impossible Whopper | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7725 | Burger King Ch'King Original | Burger King | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7726 | Burger King Ch'King Spicy | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7727 | Burger King Bacon King | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7728 | Burger King Original Chicken Sandwich | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7729 | Burger King Chicken Fries | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7732 | Burger King Mozzarella Sticks 4pc | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7733 | Burger King Croissan'wich Sausage Egg Cheese | Burger King | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 124: Chick-fil-A Complete (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 7736 | Chick-fil-A Original Chicken Sandwich | Chick-fil-A | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7738 | Chick-fil-A Deluxe Chicken Sandwich | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7741 | Chick-fil-A 8ct Nuggets | Chick-fil-A | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7742 | Chick-fil-A 12ct Nuggets | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7744 | Chick-fil-A Chick-n-Strips 3ct | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7745 | Chick-fil-A Cool Wrap | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7747 | Chick-fil-A Mac & Cheese | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7751 | Chick-fil-A Milkshake Cookies & Cream | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7752 | Chick-fil-A Chocolate Chunk Cookie | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7755 | Chick-fil-A Lemonade Medium | Chick-fil-A | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 125: More US Fast Food Chains Complete (180 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 7772 | Chipotle Chips | Chipotle | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7774 | Chipotle Chips and Queso | Chipotle | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7775 | Chipotle Kids Build Your Own | Chipotle | US | fast_food | L | TODO | 2026-04-07 | |  |
| 7776 | Subway 6-inch Turkey Breast | Subway | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7777 | Subway 6-inch Italian BMT | Subway | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7778 | Subway 6-inch Meatball Marinara | Subway | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7779 | Subway 6-inch Chicken Teriyaki | Subway | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7780 | Subway 6-inch Tuna | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7781 | Subway 6-inch Steak and Cheese | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7782 | Subway 6-inch Veggie Delite | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7783 | Subway 6-inch Spicy Italian | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7784 | Subway 6-inch Cold Cut Combo | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7786 | Subway Footlong Turkey Breast | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7789 | Subway Footlong Chicken Teriyaki | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7790 | Subway Breakfast Egg and Cheese 6-inch | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7791 | Subway Breakfast Bacon Egg Cheese 6-inch | Subway | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7794 | Subway Apple Slices Side | Subway | US | fast_food | L | TODO | 2026-04-07 | |  |
| 7795 | Subway Chips Side | Subway | US | fast_food | L | TODO | 2026-04-07 | |  |
| 7797 | Domino's Hand Tossed Pepperoni Slice | Domino's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7798 | Domino's Thin Crust Pepperoni Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7799 | Domino's Brooklyn Style Cheese Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7801 | Domino's ExtravaganZZa Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7802 | Domino's MeatZZa Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7803 | Domino's Pacific Veggie Slice | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7805 | Domino's Parmesan Bread Bites | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7808 | Domino's Boneless Chicken 8pc | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7809 | Domino's Hot Buffalo Wings 8pc | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7812 | Domino's Chicken Parm Sandwich | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7813 | Domino's Philly Cheese Steak Sandwich | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7815 | Domino's Lava Crunch Cake | Domino's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7818 | Pizza Hut Hand-Tossed Pepperoni Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7819 | Pizza Hut Thin Crust Supreme Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7821 | Pizza Hut Meat Lover's Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7822 | Pizza Hut Veggie Lover's Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7823 | Pizza Hut Detroit-Style Cheese Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7824 | Pizza Hut Detroit-Style Pepperoni Slice | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7825 | Pizza Hut Breadsticks 5pc | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7826 | Pizza Hut Cheese Sticks 5pc | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7827 | Pizza Hut WingStreet Traditional Wings 8pc | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7828 | Pizza Hut WingStreet Boneless Wings 8pc | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7829 | Pizza Hut Personal Pan Cheese | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7831 | Pizza Hut Hershey Triple Chocolate Brownie | Pizza Hut | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7834 | Popeyes 2pc Chicken Breast and Thigh | Popeyes | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7836 | Popeyes Butterfly Shrimp | Popeyes | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7838 | Popeyes Red Beans and Rice | Popeyes | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7842 | Popeyes Mac & Cheese | Popeyes | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7847 | Arby's Classic Crispy Chicken | Arby's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7848 | Arby's Buffalo Chicken Slider | Arby's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7849 | Arby's Curly Fries Small | Arby's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7854 | Arby's Market Fresh Turkey & Swiss Wrap | Arby's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7857 | Sonic SuperSONIC Double Cheeseburger | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7858 | Sonic Popcorn Chicken | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7864 | Sonic Cherry Limeade Medium | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7865 | Sonic Oreo Blast | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7866 | Sonic Reese's Blast | Sonic | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7867 | Sonic Wacky Pack Kids Meal | Sonic | US | fast_food | L | TODO | 2026-04-07 | |  |
| 7869 | Jack in the Box Ultimate Cheeseburger | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7871 | Jack in the Box Spicy Chicken Sandwich | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7872 | Jack in the Box 2 Tacos | Jack in the Box | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7873 | Jack in the Box Tiny Tacos 15pc | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7874 | Jack in the Box Curly Fries Small | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7875 | Jack in the Box Egg Rolls 3pc | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7876 | Jack in the Box Mini Churros 5pc | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7877 | Jack in the Box Oreo Shake Medium | Jack in the Box | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7882 | Whataburger Breakfast on a Bun Sausage | Whataburger | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7884 | Whataburger Taquito with Cheese | Whataburger | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7886 | Whataburger Spicy Ketchup Packet | Whataburger | US | fast_food | L | TODO | 2026-04-07 | |  |
| 7888 | Culver's ButterBurger The Original Single | Culver's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7893 | Culver's Crinkle Cut Fries Regular | Culver's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7894 | Culver's Concrete Mixer Oreo | Culver's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7895 | Culver's Concrete Mixer Reese's | Culver's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7896 | Culver's Wisconsin Cheese Soup | Culver's | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 126: Casual Dining Chains Complete (140 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 7898 | Olive Garden Breadstick (per stick) | Olive Garden | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7899 | Olive Garden Zuppa Toscana Soup | Olive Garden | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7901 | Olive Garden House Salad | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7902 | Olive Garden Tour of Italy | Olive Garden | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7905 | Olive Garden Lasagna Classico | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7906 | Olive Garden Shrimp Scampi | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7907 | Olive Garden Chicken Marsala | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7908 | Olive Garden Eggplant Parmigiana | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7909 | Olive Garden Five Cheese Ziti | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7911 | Olive Garden Chocolate Brownie Lasagna | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7912 | Olive Garden Black Tie Mousse Cake | Olive Garden | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7913 | Applebee's Boneless Wings Classic Buffalo | Applebee's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7914 | Applebee's Riblet Platter | Applebee's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7918 | Applebee's Neighborhood Nachos | Applebee's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7919 | Applebee's Mozzarella Sticks | Applebee's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7921 | Applebee's Triple Chocolate Meltdown | Applebee's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7922 | Applebee's Blue Ribbon Brownie | Applebee's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7923 | Chili's Baby Back Ribs Full Rack | Chili's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7924 | Chili's Chicken Crispers | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7925 | Chili's Oldtimer Burger | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7927 | Chili's Big Mouth Crispy Chicken Sandwich | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7929 | Chili's Texas Cheese Fries | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7930 | Chili's Presidente Margarita | Chili's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7933 | Texas Roadhouse 6oz Sirloin | Texas Roadhouse | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7934 | Texas Roadhouse 8oz Sirloin | Texas Roadhouse | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7935 | Texas Roadhouse 12oz Ribeye | Texas Roadhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7939 | Texas Roadhouse Fall Off The Bone Ribs Full | Texas Roadhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7941 | Texas Roadhouse Rolls with Cinnamon Butter | Texas Roadhouse | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7945 | Texas Roadhouse Grilled Shrimp | Texas Roadhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7954 | Red Lobster Ultimate Feast | Red Lobster | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7955 | Red Lobster Sailor's Platter | Red Lobster | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7956 | Outback Steakhouse Bloomin' Onion | Outback Steakhouse | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7957 | Outback Steakhouse Alice Springs Chicken | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7958 | Outback Steakhouse New York Strip 12oz | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7959 | Outback Steakhouse Victoria's Filet 9oz | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7960 | Outback Steakhouse Outback Special Sirloin 9oz | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7961 | Outback Steakhouse Grilled Chicken on the Barbie | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7962 | Outback Steakhouse Aussie Cheese Fries | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7963 | Outback Steakhouse Chocolate Thunder From Down Under | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7965 | Outback Steakhouse Crispy Shrimp | Outback Steakhouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7966 | The Cheesecake Factory Avocado Egg Rolls | The Cheesecake Factory | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7968 | The Cheesecake Factory Glamburger | The Cheesecake Factory | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7969 | The Cheesecake Factory Factory Nachos | The Cheesecake Factory | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7972 | The Cheesecake Factory Fresh Strawberry Cheesecake Slice | The Cheesecake Factory | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7974 | The Cheesecake Factory SkinnyLicious Chicken | The Cheesecake Factory | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7977 | Cracker Barrel Country Boy Breakfast | Cracker Barrel | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7981 | Cracker Barrel Fried Okra Side | Cracker Barrel | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7983 | Cracker Barrel Corn Muffin | Cracker Barrel | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7984 | Cracker Barrel Coca-Cola Cake | Cracker Barrel | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7986 | IHOP Original Buttermilk Pancakes Stack | IHOP | US | fast_food | H | TODO | 2026-04-07 | |  |
| 7990 | IHOP Crepes with Nutella | IHOP | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7994 | IHOP 2x2x2 (eggs pancakes choice) | IHOP | US | fast_food | M | TODO | 2026-04-07 | |  |
| 7995 | IHOP Funny Face Pancake Kids | IHOP | US | fast_food | L | TODO | 2026-04-07 | |  |
| 7999 | Denny's Build Your Own Burger | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8001 | Denny's Belgian Waffle Slam | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8002 | Denny's Fit Fare Veggie Skillet | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8003 | Denny's Loaded Nacho Tots | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8004 | Denny's Vanilla Milkshake | Denny's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8005 | Buffalo Wild Wings Traditional Wings 10pc Parmesan Garlic | Buffalo Wild Wings | US | fast_food | H | TODO | 2026-04-07 | |  |
| 8006 | Buffalo Wild Wings Traditional Wings 10pc Medium | Buffalo Wild Wings | US | fast_food | H | TODO | 2026-04-07 | |  |
| 8007 | Buffalo Wild Wings Traditional Wings 10pc Mango Habanero | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8008 | Buffalo Wild Wings Traditional Wings 10pc Asian Zing | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8009 | Buffalo Wild Wings Traditional Wings 10pc Blazin | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8010 | Buffalo Wild Wings Boneless Wings 10pc | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8011 | Buffalo Wild Wings Mozzarella Sticks | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8012 | Buffalo Wild Wings Cheese Curds | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8013 | Buffalo Wild Wings Soft Pretzel | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8014 | Buffalo Wild Wings Chocolate Fudge Cake | Buffalo Wild Wings | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8015 | P.F. Chang's Chang's Chicken Lettuce Wraps | P.F. Chang's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 8016 | P.F. Chang's Dynamite Shrimp | P.F. Chang's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 8017 | P.F. Chang's Mongolian Beef | P.F. Chang's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 8019 | P.F. Chang's Orange Peel Chicken | P.F. Chang's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8020 | P.F. Chang's Crispy Honey Chicken | P.F. Chang's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8023 | P.F. Chang's Dan Dan Noodles | P.F. Chang's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8024 | P.F. Chang's Great Wall of Chocolate Cake | P.F. Chang's | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 127: Coffee Shop Food & Dessert Chains (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 8025 | Starbucks Bacon Gouda Egg Bites 2pc | Starbucks | US | fast_food | H | TODO | 2026-04-07 | |  |
| 8029 | Starbucks Spinach Feta Wrap | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8030 | Starbucks Chicken Bacon Panini | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8031 | Starbucks Protein Box Cheese Fruit | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8032 | Starbucks Protein Box Eggs Cheddar | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8036 | Starbucks Banana Nut Bread | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8037 | Starbucks Lemon Loaf | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8038 | Starbucks Pumpkin Bread | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8040 | Starbucks Chocolate Cake Pop | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8042 | Starbucks Double Chocolate Brownie | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8043 | Starbucks Cheese Danish | Starbucks | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8044 | Starbucks Petite Vanilla Scone | Starbucks | US | fast_food | L | TODO | 2026-04-07 | |  |
| 8045 | Baskin-Robbins Jamoca Almond Fudge Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 8046 | Baskin-Robbins Mint Chocolate Chip Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 8047 | Baskin-Robbins Pralines n Cream Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 8048 | Baskin-Robbins Gold Medal Ribbon Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 8049 | Baskin-Robbins Rainbow Sherbet Scoop | Baskin-Robbins | US | dessert | M | TODO | 2026-04-07 | |  |
| 8050 | Cold Stone Creamery Birthday Cake Remix Love It | Cold Stone | US | dessert | M | TODO | 2026-04-07 | |  |
| 8051 | Cold Stone Creamery Peanut Butter Cup Perfection | Cold Stone | US | dessert | M | TODO | 2026-04-07 | |  |
| 8052 | Cold Stone Creamery Founder's Favorite | Cold Stone | US | dessert | M | TODO | 2026-04-07 | |  |
| 8053 | Dairy Queen Oreo Blizzard Medium | Dairy Queen | US | dessert | H | TODO | 2026-04-07 | |  |
| 8054 | Dairy Queen Reese's Blizzard Medium | Dairy Queen | US | dessert | H | TODO | 2026-04-07 | |  |
| 8055 | Dairy Queen Cookie Dough Blizzard Medium | Dairy Queen | US | dessert | M | TODO | 2026-04-07 | |  |
| 8056 | Dairy Queen M&M Blizzard Medium | Dairy Queen | US | dessert | M | TODO | 2026-04-07 | |  |
| 8059 | Dairy Queen Banana Split | Dairy Queen | US | dessert | M | TODO | 2026-04-07 | |  |
| 8060 | Crumbl Cookie Pink Sugar | Crumbl | US | dessert | H | TODO | 2026-04-07 | |  |
| 8061 | Crumbl Cookie Chocolate Chip | Crumbl | US | dessert | H | TODO | 2026-04-07 | |  |
| 8062 | Crumbl Cookie Biscoff Lava | Crumbl | US | dessert | M | TODO | 2026-04-07 | |  |
| 8063 | Crumbl Cookie Churro | Crumbl | US | dessert | M | TODO | 2026-04-07 | |  |
| 8064 | Crumbl Cookie Snickerdoodle | Crumbl | US | dessert | M | TODO | 2026-04-07 | |  |
| 8065 | Insomnia Cookies Classic Chocolate Chunk | Insomnia | US | dessert | M | TODO | 2026-04-07 | |  |
| 8066 | Insomnia Cookies S'mores | Insomnia | US | dessert | M | TODO | 2026-04-07 | |  |
| 8068 | Nothing Bundt Cakes Chocolate Chocolate Chip Bundtlet | Nothing Bundt | US | dessert | M | TODO | 2026-04-07 | |  |
| 8070 | Nothing Bundt Cakes Red Velvet Bundtlet | Nothing Bundt | US | dessert | M | TODO | 2026-04-07 | |  |
| 8081 | Krispy Kreme Chocolate Iced Custard Filled | Krispy Kreme | US | dessert | M | TODO | 2026-04-07 | |  |
| 8082 | Krispy Kreme Apple Fritter | Krispy Kreme | US | dessert | M | TODO | 2026-04-07 | |  |

## Section 128: Alcohol - Beer, Wine & Cocktails (80 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 8087 | Miller Lite (per 12oz) | Miller | US | beverage | H | TODO | 2026-04-07 | |  |
| 8088 | Coors Light (per 12oz) | Coors | US | beverage | H | TODO | 2026-04-07 | |  |
| 8089 | Michelob Ultra (per 12oz) | Michelob | US | beverage | H | TODO | 2026-04-07 | | Low cal beer |
| 8090 | Corona Extra (per 12oz) | Corona | MX | beverage | H | TODO | 2026-04-07 | |  |
| 8091 | Modelo Especial (per 12oz) | Modelo | MX | beverage | H | TODO | 2026-04-07 | |  |
| 8092 | Modelo Negra (per 12oz) | Modelo | MX | beverage | M | TODO | 2026-04-07 | |  |
| 8093 | Heineken (per 12oz) | Heineken | NL | beverage | H | TODO | 2026-04-07 | |  |
| 8094 | Stella Artois (per 11.2oz) | Stella | BE | beverage | M | TODO | 2026-04-07 | |  |
| 8095 | Guinness Draught (per 14.9oz) | Guinness | IE | beverage | M | TODO | 2026-04-07 | |  |
| 8096 | Dos Equis Lager (per 12oz) | Dos Equis | MX | beverage | M | TODO | 2026-04-07 | |  |
| 8097 | PBR Pabst Blue Ribbon (per 12oz) | PBR | US | beverage | M | TODO | 2026-04-07 | |  |
| 8098 | Yuengling Traditional Lager (per 12oz) | Yuengling | US | beverage | M | TODO | 2026-04-07 | |  |
| 8099 | Natural Light (per 12oz) | Natural Light | US | beverage | M | TODO | 2026-04-07 | |  |
| 8100 | Blue Moon Belgian White (per 12oz) | Blue Moon | US | beverage | M | TODO | 2026-04-07 | |  |
| 8101 | Sam Adams Boston Lager (per 12oz) | Sam Adams | US | beverage | M | TODO | 2026-04-07 | |  |
| 8102 | Sierra Nevada Pale Ale (per 12oz) | Sierra Nevada | US | beverage | M | TODO | 2026-04-07 | |  |
| 8103 | Lagunitas IPA (per 12oz) | Lagunitas | US | beverage | M | TODO | 2026-04-07 | |  |
| 8104 | Craft IPA Generic (per 16oz pint) | Various | US | beverage | H | TODO | 2026-04-07 | |  |
| 8105 | Craft Hazy IPA Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8106 | Craft Double IPA Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8107 | Craft Stout Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8108 | Craft Wheat Beer Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8109 | Craft Sour/Gose Generic (per 16oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8114 | Truly Wild Berry (per 12oz) | Truly | US | beverage | M | TODO | 2026-04-07 | |  |
| 8115 | Truly Pineapple (per 12oz) | Truly | US | beverage | M | TODO | 2026-04-07 | |  |
| 8116 | High Noon Peach Vodka Soda (per 12oz) | High Noon | US | beverage | H | TODO | 2026-04-07 | |  |
| 8117 | High Noon Watermelon (per 12oz) | High Noon | US | beverage | M | TODO | 2026-04-07 | |  |
| 8118 | Athletic Brewing Run Wild IPA Non-Alc (per 12oz) | Athletic | US | beverage | M | TODO | 2026-04-07 | | Non-alcoholic |
| 8119 | Athletic Brewing Free Wave Hazy IPA Non-Alc (per 12oz) | Athletic | US | beverage | M | TODO | 2026-04-07 | | Non-alcoholic |
| 8120 | Red Wine Cabernet Sauvignon (per 5oz glass) | Various | US | beverage | H | TODO | 2026-04-07 | |  |
| 8121 | Red Wine Merlot (per 5oz glass) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8122 | Red Wine Pinot Noir (per 5oz glass) | Various | US | beverage | H | TODO | 2026-04-07 | |  |
| 8123 | Red Wine Malbec (per 5oz glass) | Various | AR | beverage | M | TODO | 2026-04-07 | |  |
| 8124 | Red Wine Zinfandel (per 5oz glass) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8129 | Rosé Wine (per 5oz glass) | Various | FR | beverage | H | TODO | 2026-04-07 | |  |
| 8132 | Moscato (per 5oz glass) | Various | IT | beverage | M | TODO | 2026-04-07 | |  |
| 8133 | Margarita Classic (per cocktail) | Various | MX | beverage | H | TODO | 2026-04-07 | |  |
| 8135 | Old Fashioned (per cocktail) | Various | US | beverage | H | TODO | 2026-04-07 | |  |
| 8137 | Martini Gin (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8138 | Martini Vodka (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8141 | Pina Colada (per cocktail) | Various | PR | beverage | M | TODO | 2026-04-07 | |  |
| 8142 | Long Island Iced Tea (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8143 | Moscow Mule (per cocktail) | Various | US | beverage | H | TODO | 2026-04-07 | |  |
| 8144 | Whiskey Sour (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8145 | Mai Tai (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8146 | Paloma (per cocktail) | Various | MX | beverage | M | TODO | 2026-04-07 | |  |
| 8147 | Aperol Spritz (per cocktail) | Various | IT | beverage | H | TODO | 2026-04-07 | |  |
| 8148 | Espresso Martini (per cocktail) | Various | IT | beverage | H | TODO | 2026-04-07 | |  |
| 8149 | Bloody Mary (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8150 | Tom Collins (per cocktail) | Various | GB | beverage | M | TODO | 2026-04-07 | |  |
| 8151 | Gin and Tonic (per cocktail) | Various | GB | beverage | H | TODO | 2026-04-07 | |  |
| 8152 | Vodka Soda (per cocktail) | Various | US | beverage | H | TODO | 2026-04-07 | | Low cal |
| 8153 | Rum and Coke (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8154 | Tequila Sunrise (per cocktail) | Various | MX | beverage | M | TODO | 2026-04-07 | |  |
| 8155 | Dark 'n Stormy (per cocktail) | Various | BM | beverage | M | TODO | 2026-04-07 | |  |
| 8156 | Sangria Red (per glass) | Various | ES | beverage | M | TODO | 2026-04-07 | |  |
| 8157 | Michelada (per glass) | Various | MX | beverage | M | TODO | 2026-04-07 | |  |
| 8158 | Irish Coffee (per cocktail) | Various | IE | beverage | M | TODO | 2026-04-07 | |  |
| 8159 | Hot Toddy (per cocktail) | Various | GB | beverage | M | TODO | 2026-04-07 | |  |
| 8160 | Frozen Margarita (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8161 | Frozen Daiquiri Strawberry (per cocktail) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8162 | Jägerbomb (per shot+mixer) | Various | DE | beverage | M | TODO | 2026-04-07 | |  |
| 8163 | Lemon Drop Shot | Various | US | beverage | L | TODO | 2026-04-07 | |  |
| 8164 | Vodka Shot (per 1.5oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8165 | Tequila Shot (per 1.5oz) | Various | MX | beverage | M | TODO | 2026-04-07 | |  |
| 8166 | Whiskey Shot (per 1.5oz) | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8167 | Sake Cup (per 6oz) | Various | JP | beverage | M | TODO | 2026-04-07 | |  |

## Section 129: Street Food & Cuisine Expansion - 30+ Countries (200 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 8168 | Kebab Koobideh (per 2 skewers) | Various | IR | street_food | H | TODO | 2026-04-07 | |  |
| 8169 | Ghormeh Sabzi (per serving) | Various | IR | street_food | H | TODO | 2026-04-07 | |  |
| 8170 | Zereshk Polo ba Morgh (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 8171 | Tahdig Crispy Rice (per serving) | Various | IR | street_food | H | TODO | 2026-04-07 | |  |
| 8172 | Fesenjan Pomegranate Walnut Stew (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 8173 | Ash Reshteh Noodle Soup (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 8175 | Saffron Ice Cream Bastani (per scoop) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 8176 | Faloodeh Frozen Dessert (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 8177 | Joojeh Kabab Chicken Skewer (per 2) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 8178 | Khoresh Bademjan Eggplant Stew (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 8180 | Sabzi Khordan Herb Plate (per serving) | Various | IR | street_food | L | TODO | 2026-04-07 | |  |
| 8181 | Kashk-e Bademjan Eggplant Dip (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 8182 | Mirza Ghasemi Smoked Eggplant (per serving) | Various | IR | street_food | M | TODO | 2026-04-07 | |  |
| 8183 | Masgouf Iraqi Grilled Fish (per serving) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 8184 | Iraqi Dolma Stuffed Vegetables (per 3) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 8185 | Kubba Mosul Fried Meat Ball (per 2) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 8186 | Iraqi Biryani (per serving) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 8187 | Tashreeb Bread Stew (per serving) | Various | IQ | street_food | M | TODO | 2026-04-07 | |  |
| 8188 | Kabsa Saudi Rice Chicken (per serving) | Various | SA | street_food | H | TODO | 2026-04-07 | |  |
| 8189 | Mandi Slow Cooked Lamb (per serving) | Various | SA | street_food | H | TODO | 2026-04-07 | |  |
| 8190 | Jareesh Crushed Wheat (per serving) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 8191 | Harees Porridge (per serving) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 8192 | Saleeg White Rice Chicken (per serving) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 8193 | Mutabbaq Stuffed Pancake (per piece) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 8194 | Saudi Shawarma (per wrap) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 8195 | Sambousek Fried Pastry (per 3) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 8196 | Arabic Coffee Qahwa (per cup) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 8197 | Saudi Dates Stuffed Almond (per 3) | Various | SA | street_food | M | TODO | 2026-04-07 | |  |
| 8198 | Mansaf Jordanian Lamb Rice (per serving) | Various | JO | street_food | H | TODO | 2026-04-07 | |  |
| 8199 | Jordanian Falafel in Pita | Various | JO | street_food | M | TODO | 2026-04-07 | |  |
| 8200 | Knafeh Nabulsi Cheese Pastry (per piece) | Various | JO | street_food | M | TODO | 2026-04-07 | |  |
| 8201 | Maqluba Upside Down Rice (per serving) | Various | JO | street_food | M | TODO | 2026-04-07 | |  |
| 8202 | Jordanian Jameed Sauce (per tbsp) | Various | JO | street_food | L | TODO | 2026-04-07 | |  |
| 8204 | Fahsa Shredded Meat (per serving) | Various | YE | street_food | M | TODO | 2026-04-07 | |  |
| 8207 | Bint al Sahn Honey Cake (per slice) | Various | YE | street_food | M | TODO | 2026-04-07 | |  |
| 8208 | Uzbek Plov Rice Pilaf (per serving) | Various | UZ | street_food | H | TODO | 2026-04-07 | |  |
| 8213 | Uzbek Halva (per piece) | Various | UZ | street_food | M | TODO | 2026-04-07 | |  |
| 8214 | Non Uzbek Bread (per piece) | Various | UZ | street_food | M | TODO | 2026-04-07 | |  |
| 8215 | Naryn Cold Noodle Horse Meat (per serving) | Various | UZ | street_food | L | TODO | 2026-04-07 | |  |
| 8217 | Kazy Horse Sausage (per 100g) | Various | KZ | street_food | M | TODO | 2026-04-07 | |  |
| 8218 | Kumys Fermented Mare Milk (per cup) | Various | KZ | street_food | M | TODO | 2026-04-07 | |  |
| 8219 | Baursak Fried Dough (per 3) | Various | KZ | street_food | M | TODO | 2026-04-07 | |  |
| 8220 | Shubat Camel Milk (per cup) | Various | KZ | street_food | L | TODO | 2026-04-07 | |  |
| 8221 | Adjarian Khachapuri Boat (per piece) | Various | GE | street_food | H | TODO | 2026-04-07 | |  |
| 8222 | Imeruli Khachapuri Round (per piece) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 8223 | Khinkali Soup Dumpling (per 5) | Various | GE | street_food | H | TODO | 2026-04-07 | |  |
| 8224 | Churchkhela Grape Walnut (per piece) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 8225 | Lobio Red Bean Stew (per serving) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 8226 | Mtsvadi Grilled Meat (per skewer) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 8227 | Badrijani Walnut Stuffed Eggplant (per 2) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 8228 | Pkhali Spinach Walnut (per serving) | Various | GE | street_food | M | TODO | 2026-04-07 | |  |
| 8230 | Tkemali Plum Sauce (per tbsp) | Various | GE | street_food | L | TODO | 2026-04-07 | |  |
| 8231 | Armenian Khorovats BBQ (per serving) | Various | AM | street_food | H | TODO | 2026-04-07 | |  |
| 8233 | Armenian Dolma Grape Leaf (per 3) | Various | AM | street_food | M | TODO | 2026-04-07 | |  |
| 8234 | Ghapama Stuffed Pumpkin (per serving) | Various | AM | street_food | M | TODO | 2026-04-07 | |  |
| 8237 | Basturma Cured Beef (per 30g) | Various | AM | street_food | M | TODO | 2026-04-07 | |  |
| 8238 | Sujuk Armenian Sausage (per 30g) | Various | AM | street_food | M | TODO | 2026-04-07 | |  |
| 8239 | Mici Romanian Grilled Rolls (per 3) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 8240 | Sarmale Cabbage Rolls (per 3) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 8241 | Mamaliga Polenta (per serving) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 8242 | Cozonac Sweet Bread (per slice) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 8243 | Papanasi Donut Dumplings (per 2) | Various | RO | street_food | M | TODO | 2026-04-07 | |  |
| 8244 | Shopska Salad (per serving) | Various | BG | street_food | M | TODO | 2026-04-07 | |  |
| 8245 | Banitsa Cheese Pastry (per piece) | Various | BG | street_food | M | TODO | 2026-04-07 | |  |
| 8246 | Kebapche Grilled Meat Roll (per 2) | Various | BG | street_food | M | TODO | 2026-04-07 | |  |
| 8247 | Lyutenitsa Pepper Relish (per tbsp) | Various | BG | street_food | M | TODO | 2026-04-07 | |  |
| 8248 | Tarator Cold Soup (per serving) | Various | BG | street_food | M | TODO | 2026-04-07 | |  |
| 8249 | Cevapi Croatian (per 5 pieces) | Various | HR | street_food | M | TODO | 2026-04-07 | |  |
| 8250 | Burek Croatian Meat Pie (per piece) | Various | HR | street_food | M | TODO | 2026-04-07 | |  |
| 8251 | Strukli Cheese Rolls (per 2) | Various | HR | street_food | M | TODO | 2026-04-07 | |  |
| 8252 | Pag Cheese (per 30g) | Various | HR | street_food | M | TODO | 2026-04-07 | |  |
| 8255 | Ajvar Red Pepper Relish (per tbsp) | Various | RS | street_food | M | TODO | 2026-04-07 | |  |
| 8257 | Knedle Plum Dumplings (per 3) | Various | RS | street_food | M | TODO | 2026-04-07 | |  |
| 8259 | Vaca Frita Crispy Beef (per serving) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 8262 | Yuca Frita Fried Cassava (per serving) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 8263 | Cafecito Cuban Coffee (per shot) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 8264 | Batido de Mamey Shake (per glass) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 8266 | Picadillo Cuban Ground Beef (per serving) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 8267 | Flan Cubano (per slice) | Various | CU | street_food | M | TODO | 2026-04-07 | |  |
| 8268 | Mofongo Garlic Plantain (per serving) | Various | PR | street_food | H | TODO | 2026-04-07 | |  |
| 8269 | Arroz con Gandules (per serving) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 8270 | Pernil Roasted Pork (per serving) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 8271 | Pastelón Plantain Lasagna (per serving) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 8272 | Tembleque Coconut Pudding (per serving) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 8273 | Coquito Coconut Eggnog (per cup) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 8274 | Tostones con Mojito (per serving) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 8275 | Alcapurrias Fritters (per 2) | Various | PR | street_food | M | TODO | 2026-04-07 | |  |
| 8278 | Jamaican Beef Patty (per piece) | Various | JM | street_food | H | TODO | 2026-04-07 | |  |
| 8279 | Festival Fried Dumpling (per 2) | Various | JM | street_food | M | TODO | 2026-04-07 | |  |
| 8280 | Bammy Cassava Bread (per piece) | Various | JM | street_food | M | TODO | 2026-04-07 | |  |
| 8285 | Sorrel Drink (per glass) | Various | JM | street_food | M | TODO | 2026-04-07 | |  |
| 8287 | Bake and Shark (per piece) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 8288 | Trinidadian Roti Wrap (per piece) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 8289 | Pelau Rice Meat (per serving) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 8290 | Callaloo Soup (per serving) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 8291 | Pholourie Fried Balls (per 5) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 8292 | Kurma Sweet Snack (per piece) | Various | TT | street_food | M | TODO | 2026-04-07 | |  |
| 8294 | Sancocho Dominican Stew (per serving) | Various | DO | street_food | M | TODO | 2026-04-07 | |  |
| 8295 | Chimichurri Burger Dominican (per piece) | Various | DO | street_food | M | TODO | 2026-04-07 | |  |
| 8296 | Morir Sonando Orange Milk Drink (per glass) | Various | DO | street_food | M | TODO | 2026-04-07 | |  |
| 8298 | Diri Djon Djon Black Rice (per serving) | Various | HT | street_food | M | TODO | 2026-04-07 | |  |
| 8301 | Soup Joumou Pumpkin Soup (per serving) | Various | HT | street_food | M | TODO | 2026-04-07 | |  |
| 8302 | Borscht Ukrainian (per serving) | Various | UA | street_food | H | TODO | 2026-04-07 | |  |
| 8303 | Varenyky Ukrainian Dumplings (per 5) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |
| 8304 | Deruny Potato Pancakes (per 3) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |
| 8305 | Holubtsi Stuffed Cabbage Rolls (per 2) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |
| 8306 | Salo Cured Pork Fat (per 30g) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |
| 8307 | Pampushky Garlic Bread (per 2) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |
| 8308 | Chicken Kyiv (per piece) | Various | UA | street_food | M | TODO | 2026-04-07 | |  |

## Section 130: Gas Station, Vending, School & Airport (45 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 8311 | 7-Eleven Slurpee Cherry Medium | 7-Eleven | US | beverage | M | TODO | 2026-04-07 | |  |
| 8313 | 7-Eleven Taquito Chicken Cheese | 7-Eleven | US | snack | M | TODO | 2026-04-07 | |  |
| 8314 | 7-Eleven Pizza Slice Pepperoni | 7-Eleven | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8318 | Wawa Classic Italian Hoagie | Wawa | US | fast_food | H | TODO | 2026-04-07 | |  |
| 8320 | Wawa Sizzli Sausage Egg Cheese | Wawa | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8322 | Sheetz MTO Sub Italian | Sheetz | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8329 | QuikTrip QT Kitchen Pizza Slice | QuikTrip | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8330 | QuikTrip QT Kitchen Taquito | QuikTrip | US | snack | M | TODO | 2026-04-07 | |  |
| 8332 | Vending Machine Doritos Small Bag | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 8333 | Vending Machine Lay's Small Bag | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 8334 | Vending Machine Nature Valley Bar | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 8335 | Vending Machine Honey Bun | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 8336 | Vending Machine Grandma's Cookies | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 8337 | Vending Machine Famous Amos Cookies | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 8338 | Vending Machine Pop-Tarts | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 8339 | Vending Machine Coke 20oz Bottle | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8340 | Vending Machine Gatorade 20oz | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8341 | School Cafeteria Rectangle Pizza | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8343 | School Cafeteria Corn Dog | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8345 | School Cafeteria Fish Sticks 3pc | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8346 | School Cafeteria Tater Tots | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8347 | School Cafeteria Chocolate Milk Carton | Various | US | beverage | M | TODO | 2026-04-07 | |  |
| 8348 | Airport Terminal Grab-and-Go Sandwich | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8349 | Airport Terminal Fruit and Cheese Box | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 8350 | Airport Terminal Hummus and Veggies Box | Various | US | snack | M | TODO | 2026-04-07 | |  |
| 8351 | Airline Economy Chicken Meal | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8352 | Airline Economy Pasta Meal | Various | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8353 | Airline Pretzel Snack Pack | Various | US | snack | L | TODO | 2026-04-07 | |  |
| 8354 | Airline Biscoff Cookie Pack | Various | US | snack | L | TODO | 2026-04-07 | |  |

## Section 131: Juice & Smoothie Chains (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 8355 | Jamba Juice Caribbean Passion Medium | Jamba | US | beverage | M | TODO | 2026-04-07 | |  |
| 8356 | Jamba Juice Acai Primo Bowl | Jamba | US | breakfast | M | TODO | 2026-04-07 | |  |
| 8357 | Jamba Juice Greens n Ginger Medium | Jamba | US | beverage | M | TODO | 2026-04-07 | |  |
| 8358 | Jamba Juice PB Galaxy Medium | Jamba | US | beverage | M | TODO | 2026-04-07 | |  |
| 8359 | Jamba Juice Orange Dream Machine Medium | Jamba | US | beverage | M | TODO | 2026-04-07 | |  |
| 8361 | Smoothie King The Activator Strawberry Banana | Smoothie King | US | beverage | M | TODO | 2026-04-07 | |  |
| 8363 | Smoothie King Slim-N-Trim Strawberry | Smoothie King | US | beverage | M | TODO | 2026-04-07 | |  |
| 8366 | Tropical Smoothie Sunrise Sunset | Tropical Smoothie | US | beverage | M | TODO | 2026-04-07 | |  |
| 8367 | Tropical Smoothie Peanut Paradise | Tropical Smoothie | US | beverage | M | TODO | 2026-04-07 | |  |
| 8371 | Nekter Juice Bar Pitaya Bowl | Nekter | US | breakfast | M | TODO | 2026-04-07 | |  |
| 8372 | Pressed Juicery Greens 3 | Pressed Juicery | US | beverage | M | TODO | 2026-04-07 | |  |
| 8373 | Pressed Juicery Freeze Chocolate | Pressed Juicery | US | dessert | M | TODO | 2026-04-07 | |  |
| 8374 | Clean Juice The One Smoothie | Clean Juice | US | beverage | M | TODO | 2026-04-07 | |  |

## Section 132: Sandwich & Sub Chains (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 8375 | Jersey Mike's #13 The Original Italian Regular | Jersey Mike's | US | fast_food | H | TODO | 2026-04-07 | |  |
| 8376 | Jersey Mike's #7 Turkey & Provolone Regular | Jersey Mike's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8377 | Jersey Mike's #56 Big Kahuna Cheesesteak Regular | Jersey Mike's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8378 | Jersey Mike's #9 Club Sub Regular | Jersey Mike's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8379 | Jimmy John's #1 Pepe | Jimmy John's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8380 | Jimmy John's #4 Turkey Tom | Jimmy John's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8381 | Jimmy John's #9 Italian Night Club | Jimmy John's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8382 | Jimmy John's Beach Club | Jimmy John's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8383 | Firehouse Subs Hook & Ladder Medium | Firehouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8384 | Firehouse Subs Smokehouse Beef & Cheddar Medium | Firehouse | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8385 | Potbelly A Wreck Sandwich Original | Potbelly | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8386 | Potbelly Turkey Breast Sandwich Original | Potbelly | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8390 | Schlotzsky's The Original Sandwich Small | Schlotzsky's | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8392 | Which Wich Wicked Sandwich | Which Wich | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8393 | Panera Bread Bowl Broccoli Cheddar | Panera | US | fast_food | H | TODO | 2026-04-07 | |  |

## Section 133: Salad & Bowl Chains (10 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 8403 | Just Salad Chicken Caesar | Just Salad | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8404 | CoreLife Chicken Power Bowl | CoreLife | US | fast_food | M | TODO | 2026-04-07 | |  |

## Section 134: Breakfast Chains (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 8406 | First Watch Power Breakfast Quinoa Bowl | First Watch | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8407 | First Watch Elevated Egg Sandwich | First Watch | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8408 | First Watch Kale Tonic Juice | First Watch | US | beverage | M | TODO | 2026-04-07 | |  |
| 8410 | Snooze Pineapple Upside Down Pancakes | Snooze | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8411 | Snooze Breakfast Pot Pie | Snooze | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8412 | Original Pancake House Dutch Baby | OPH | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8413 | Original Pancake House Apple Pancake | OPH | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8414 | Bob Evans Rise & Shine Breakfast | Bob Evans | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8415 | Bob Evans Farmhouse Feast | Bob Evans | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8416 | Perkins Tremendous Twelve Breakfast | Perkins | US | fast_food | M | TODO | 2026-04-07 | |  |
| 8417 | Village Inn Pie (per slice) | Village Inn | US | dessert | M | TODO | 2026-04-07 | |  |
## Section 135: Trader Joe's & Costco Complete (85 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10152 | TJ's Gone Bananas Frozen (per 5) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10155 | TJ's Spatchcocked Chicken (per 100g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10158 | TJ's Soy Chorizo (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10159 | TJ's Hashbrowns Frozen (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10160 | TJ's Cowboy Bark (per 30g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10161 | TJ's Triple Ginger Snaps (per 4) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10163 | TJ's Bambas Peanut Snacks (per 100g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10164 | TJ's Cruciferous Crunch (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10165 | TJ's Umami Seasoning (per tsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10166 | TJ's Chile Lime Seasoning (per tsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10167 | TJ's 21 Salute Seasoning (per tsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10168 | TJ's Ube Mochi Pancake Mix (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10169 | TJ's Ube Ice Cream (per 100ml) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10170 | TJ's Magnifisauce (per tbsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10171 | TJ's Bomba Sauce (per tbsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10172 | TJ's Joe-Joe's Chocolate Cream (per 3) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10173 | TJ's Chocolate Lava Cake (per cake) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10174 | TJ's Mango Cream Bars (per bar) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10175 | TJ's Thai Vegetable Gyoza (per 7) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10176 | TJ's Peanut Butter Filled Pretzels (per 30g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10178 | TJ's Cauliflower Pizza Crust (per crust) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10179 | TJ's Shawarma Chicken Thighs (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10180 | TJ's Reduced Guilt Mac & Cheese (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10181 | TJ's Mini Ice Cream Cones (per 4) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10182 | TJ's Hold the Cone Vanilla (per 4) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10183 | TJ's Turkey Corn Dogs (per dog) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10187 | TJ's Cauliflower Gnocchi Frozen (per serving) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10188 | TJ's Everything But The Bagel Seasoning (per tsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10190 | TJ's Elote Corn Chip Dippers (per 100g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10191 | TJ's Green Goddess Dressing (per tbsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10192 | TJ's Peanut Butter Pretzel Bites (per 30g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10193 | TJ's Sublime Ice Cream Sandwiches (per piece) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10195 | TJ's Chile Spiced Mango (per 100g) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10197 | TJ's Organic Peanut Butter Creamy (per tbsp) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10198 | TJ's Everything Ciabatta Rolls (per roll) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10199 | TJ's Chicken Gyoza Potstickers (per 7) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10200 | TJ's Pork Gyoza (per 7) | Trader Joe's | US | grocery | H | TODO | 2026-04-07 | |  |
| 10201 | Costco Food Court Hot Dog & Soda | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10204 | Costco Food Court Chicken Bake | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10205 | Costco Food Court Açaí Bowl | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10207 | Costco Food Court Churro | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10208 | Costco Food Court Ice Cream Bar | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10215 | Kirkland Atlantic Salmon Fillet (per 100g) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10216 | Kirkland Chicken Breast Boneless (per 100g) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10217 | Kirkland Organic Large Eggs (per egg) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10219 | Kirkland Organic Peanut Butter (per tbsp) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10222 | Kirkland Pesto Basil (per tbsp) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10224 | Kirkland Croissants (per piece) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10225 | Kirkland Muffins Blueberry (per muffin) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10226 | Kirkland Muffins Chocolate (per muffin) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10227 | Kirkland Bagels Everything (per bagel) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10229 | Kirkland Sheet Cake Chocolate (per slice) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10233 | Kirkland Chicken Wings Frozen (per 4 wings) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10234 | Kirkland Frozen Berries Mixed (per 100g) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |
| 10235 | Kirkland Organic Ground Beef (per 100g) | Kirkland/Costco | US | grocery | H | TODO | 2026-04-07 | |  |

## Section 136: Weight Management & Meal Kit Brands (42 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10237 | WW Smart Ones Santa Fe Rice & Beans | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10238 | WW Smart Ones Three Cheese Ziti | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10239 | WW Smart Ones Broccoli Cheddar Potatoes | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10241 | WW Snack Bar Chocolate Caramel | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10242 | WW Ice Cream Bar Chocolate Fudge | WW | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10245 | Nutrisystem Chocolate Shake | Nutrisystem | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10246 | Nutrisystem Lunch Hamburger | Nutrisystem | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10247 | Nutrisystem Dinner Ravioli | Nutrisystem | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10249 | SlimFast Original Shake French Vanilla | SlimFast | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10250 | SlimFast Keto Shake Fudge Brownie | SlimFast | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10251 | SlimFast Snack Bar Peanut Butter Chocolate | SlimFast | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10252 | Optavia Fueling Chocolate Shake | Optavia | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10253 | Optavia Fueling Cinnamon Crunchy O's | Optavia | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10254 | Optavia Fueling Brownie | Optavia | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10256 | HelloFresh Creamy Garlic Butter Shrimp | HelloFresh | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10258 | HelloFresh BBQ Chicken | HelloFresh | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10259 | HelloFresh One-Pan Southwest Chicken | HelloFresh | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10260 | HelloFresh Steak Frites | HelloFresh | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10262 | EveryPlate Garlic Herb Chicken | EveryPlate | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10263 | Blue Apron Seared Salmon | Blue | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10264 | Blue Apron Crispy Chicken Thighs | Blue | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10265 | Home Chef Chicken Marsala | Home | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10267 | Factor Keto Chicken Thigh Meal | Factor | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10268 | Factor Steak with Vegetables | Factor | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10269 | Factor Salmon Meal | Factor | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10272 | Daily Harvest Acai Cherry Smoothie | Daily | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10273 | Daily Harvest Tomato Basil Flatbread | Daily | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10274 | Daily Harvest Chocolate Latte Smoothie | Daily | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10275 | CookUnity Chef-Made Chicken Bowl | CookUnity | US | meal_kit | M | TODO | 2026-04-07 | |  |
| 10277 | Territory Foods Grilled Chicken Mediterranean | Territory | US | meal_kit | M | TODO | 2026-04-07 | |  |

## Section 137: Cereal Brands Complete (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10281 | Cheerios Protein (per serving) | General Mills | US | cereal | M | TODO | 2026-04-07 | |  |
| 10285 | Trix (per serving) | General Mills | US | cereal | M | TODO | 2026-04-07 | |  |
| 10286 | Reese's Puffs (per serving) | General Mills | US | cereal | M | TODO | 2026-04-07 | |  |
| 10296 | Corn Pops (per serving) | Kellogg's | US | cereal | M | TODO | 2026-04-07 | |  |
| 10305 | Cap'n Crunch Crunch Berries (per serving) | Quaker | US | cereal | M | TODO | 2026-04-07 | |  |
| 10308 | Quaker Instant Oatmeal Apple Cinnamon (per packet) | Quaker | US | cereal | M | TODO | 2026-04-07 | |  |
| 10309 | Quaker Instant Oatmeal Peaches & Cream (per packet) | Quaker | US | cereal | M | TODO | 2026-04-07 | |  |
| 10310 | Quaker Old Fashioned Oats (per serving) | Quaker | US | cereal | H | TODO | 2026-04-07 | |  |
| 10311 | Quaker Steel Cut Oats (per serving) | Quaker | US | cereal | M | TODO | 2026-04-07 | |  |
| 10313 | Barbara's Puffins Original (per serving) | Barbara's | US | cereal | M | TODO | 2026-04-07 | |  |
| 10314 | Cascadian Farm Organic Granola Oats & Honey (per serving) | Cascadian Farm | US | cereal | M | TODO | 2026-04-07 | |  |
| 10315 | Bob's Red Mill Muesli (per serving) | Bob's Red Mill | US | cereal | M | TODO | 2026-04-07 | |  |
| 10316 | Kind Healthy Grains Granola (per serving) | Kind | US | cereal | M | TODO | 2026-04-07 | |  |

## Section 138: Yogurt Brands Expanded (25 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10320 | Dannon Light & Fit Greek Vanilla (per cup) | Dannon | US | dairy | M | TODO | 2026-04-07 | |  |
| 10321 | Dannon Light & Fit Greek Strawberry (per cup) | Dannon | US | dairy | M | TODO | 2026-04-07 | |  |
| 10326 | Yoplait Oui French Style Vanilla (per jar) | Yoplait | US | dairy | M | TODO | 2026-04-07 | |  |
| 10330 | Brown Cow Cream Top Vanilla (per cup) | Brown Cow | US | dairy | M | TODO | 2026-04-07 | |  |
| 10333 | Lifeway Kefir Low Fat Plain (per cup) | Lifeway | US | dairy | M | TODO | 2026-04-07 | |  |
| 10334 | Lifeway Kefir Strawberry (per cup) | Lifeway | US | dairy | M | TODO | 2026-04-07 | |  |
| 10335 | Kite Hill Almond Milk Yogurt Vanilla (per cup) | Kite Hill | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10336 | Silk Oat Milk Yogurt Strawberry (per cup) | Silk | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10337 | So Delicious Coconut Yogurt Vanilla (per cup) | So Delicious | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10338 | Forager Cashewmilk Yogurt Vanilla (per cup) | Forager | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10340 | Wallaby Organic Greek Plain (per cup) | Wallaby | US | dairy | M | TODO | 2026-04-07 | |  |
| 10341 | Maple Hill Organic Greek Plain (per cup) | Maple Hill | US | dairy | M | TODO | 2026-04-07 | |  |
| 10342 | Icelandic Provisions Skyr Vanilla (per cup) | Icelandic Provisions | IS | dairy | M | TODO | 2026-04-07 | |  |

## Section 139: Chips, Crackers & Snack Brands Complete (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10360 | Stacy's Pita Chips Simply Naked (per 1oz) | Stacy's | US | snack | M | TODO | 2026-04-07 | |  |
| 10365 | Cheez-It Original (per 1oz) | Kellogg's | US | snack | H | TODO | 2026-04-07 | |  |
| 10366 | Cheez-It White Cheddar (per 1oz) | Kellogg's | US | snack | M | TODO | 2026-04-07 | |  |
| 10372 | Ritz Cheese Sandwich Crackers (per 6 crackers) | Nabisco | US | snack | M | TODO | 2026-04-07 | |  |
| 10373 | Club Crackers Original (per 4 crackers) | Kellogg's | US | snack | M | TODO | 2026-04-07 | |  |
| 10374 | Good Thins Corn (per 40 crisps) | Nabisco | US | snack | M | TODO | 2026-04-07 | |  |
| 10377 | Utz Pub Mix (per 1oz) | Utz | US | snack | M | TODO | 2026-04-07 | |  |
| 10379 | Popcorners White Cheddar (per 1oz) | Popcorners | US | snack | M | TODO | 2026-04-07 | |  |
| 10380 | Hippeas Chickpea Puffs Vegan White Cheddar (per 1oz) | Hippeas | US | snack | M | TODO | 2026-04-07 | |  |
| 10381 | Beanitos Black Bean Chips (per 1oz) | Beanitos | US | snack | M | TODO | 2026-04-07 | |  |
| 10382 | Harvest Snaps Green Pea (per 1oz) | Harvest Snaps | US | snack | M | TODO | 2026-04-07 | |  |
| 10383 | Terra Vegetable Chips Original (per 1oz) | Terra | US | snack | M | TODO | 2026-04-07 | |  |
| 10387 | Boom Chicka Pop Sea Salt Popcorn (per 1oz) | Angie's | US | snack | M | TODO | 2026-04-07 | |  |
| 10390 | Garden of Eatin' Blue Corn Chips (per 1oz) | Garden of Eatin' | US | snack | M | TODO | 2026-04-07 | |  |

## Section 140: Cookie & Candy Brands Complete (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10396 | Oreo Golden (per 3 cookies) | Nabisco | US | biscuit | M | TODO | 2026-04-07 | |  |
| 10398 | Chips Ahoy Chunky (per 1 cookie) | Nabisco | US | biscuit | M | TODO | 2026-04-07 | |  |
| 10399 | Nutter Butters (per 2 cookies) | Nabisco | US | biscuit | M | TODO | 2026-04-07 | |  |
| 10400 | Nilla Wafers (per 8 wafers) | Nabisco | US | biscuit | M | TODO | 2026-04-07 | |  |
| 10402 | Girl Scout Samoas (per 2 cookies) | Girl Scouts | US | biscuit | M | TODO | 2026-04-07 | | Seasonal |
| 10403 | Girl Scout Tagalongs (per 2 cookies) | Girl Scouts | US | biscuit | M | TODO | 2026-04-07 | | Seasonal |
| 10404 | Keebler Fudge Stripes (per 3 cookies) | Keebler | US | biscuit | M | TODO | 2026-04-07 | |  |
| 10405 | Keebler E.L. Fudge (per 2 cookies) | Keebler | US | biscuit | M | TODO | 2026-04-07 | |  |
| 10407 | Tate's Bake Shop Chocolate Chip (per 2) | Tate's | US | biscuit | M | TODO | 2026-04-07 | |  |
| 10408 | M&Ms Original (per 1.69oz) | Mars | US | confectionery | H | TODO | 2026-04-07 | |  |
| 10411 | Snickers Original Bar | Mars | US | confectionery | H | TODO | 2026-04-07 | |  |
| 10412 | Twix Original Bar | Mars | US | confectionery | H | TODO | 2026-04-07 | |  |
| 10414 | 3 Musketeers Bar | Mars | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10420 | Kit Kat Original 4-Finger | Hershey's | US | confectionery | H | TODO | 2026-04-07 | |  |
| 10422 | Mounds Bar | Hershey's | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10423 | York Peppermint Pattie | Hershey's | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10424 | PayDay Bar | Hershey's | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10425 | Butterfinger Bar | Ferrero | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10427 | 100 Grand Bar | Ferrero | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10428 | Skittles Original (per 2.17oz) | Mars | US | confectionery | H | TODO | 2026-04-07 | |  |
| 10429 | Starburst Original (per 2.07oz) | Mars | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10432 | Twizzlers Strawberry (per 4 twists) | Hershey's | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10434 | Nerds Original Box | Ferrara | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10435 | Airheads Bar | Perfetti | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10436 | Trolli Sour Brite Crawlers (per 1oz) | Ferrara | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10437 | Haribo Gold-Bears (per 1.5oz) | Haribo | US | confectionery | M | TODO | 2026-04-07 | |  |
| 10440 | Candy Corn (per 30 pieces) | Brach's | US | confectionery | L | TODO | 2026-04-07 | | Seasonal |

## Section 141: Ice Cream Brands Complete (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10449 | Häagen-Dazs Vanilla (per 100ml) | Häagen-Dazs | US | dessert | H | TODO | 2026-04-07 | |  |
| 10450 | Häagen-Dazs Chocolate (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | |  |
| 10451 | Häagen-Dazs Strawberry (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | |  |
| 10452 | Häagen-Dazs Cookies & Cream (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | |  |
| 10453 | Häagen-Dazs Dulce de Leche (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | |  |
| 10459 | Turkey Hill Original Vanilla (per 100ml) | Turkey Hill | US | dessert | M | TODO | 2026-04-07 | |  |
| 10460 | Tillamook Oregon Strawberry (per 100ml) | Tillamook | US | dessert | M | TODO | 2026-04-07 | |  |
| 10461 | Jeni's Brambleberry Crisp (per 100ml) | Jeni's | US | dessert | M | TODO | 2026-04-07 | |  |
| 10462 | Jeni's Salted Peanut Butter with Chocolate (per 100ml) | Jeni's | US | dessert | M | TODO | 2026-04-07 | |  |
| 10463 | Van Leeuwen French Vanilla (per 100ml) | Van Leeuwen | US | dessert | M | TODO | 2026-04-07 | |  |
| 10464 | Klondike Bar Original (per bar) | Klondike | US | dessert | M | TODO | 2026-04-07 | |  |
| 10465 | Drumstick Classic Vanilla (per cone) | Nestlé | US | dessert | M | TODO | 2026-04-07 | |  |
| 10467 | Good Humor Strawberry Shortcake Bar | Good Humor | US | dessert | M | TODO | 2026-04-07 | |  |
| 10468 | Fudgsicle Original (per bar) | Popsicle | US | dessert | M | TODO | 2026-04-07 | |  |
| 10469 | Creamsicle Orange (per bar) | Popsicle | US | dessert | M | TODO | 2026-04-07 | |  |
| 10470 | Edy's/Dreyer's Vanilla (per 100ml) | Edy's | US | dessert | M | TODO | 2026-04-07 | |  |
| 10471 | Blue Bunny Bunny Tracks (per 100ml) | Blue Bunny | US | dessert | M | TODO | 2026-04-07 | |  |
| 10472 | Friendly's Forbidden Chocolate (per 100ml) | Friendly's | US | dessert | M | TODO | 2026-04-07 | |  |

## Section 142: Beverage Brands - Juice, Tea, Water (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10479 | Naked Juice Green Machine (per 15.2oz) | Naked | US | beverage | M | TODO | 2026-04-07 | |  |
| 10480 | Naked Juice Mighty Mango (per 15.2oz) | Naked | US | beverage | M | TODO | 2026-04-07 | |  |
| 10481 | Naked Juice Blue Machine (per 15.2oz) | Naked | US | beverage | M | TODO | 2026-04-07 | |  |
| 10482 | Bolthouse Farms Green Goodness (per 15.2oz) | Bolthouse | US | beverage | M | TODO | 2026-04-07 | |  |
| 10483 | Bolthouse Farms Protein Plus Chocolate (per 15.2oz) | Bolthouse | US | beverage | M | TODO | 2026-04-07 | |  |
| 10484 | V8 Original Vegetable Juice (per 8oz) | V8 | US | beverage | M | TODO | 2026-04-07 | |  |
| 10487 | Capri Sun Original (per pouch) | Capri Sun | US | beverage | M | TODO | 2026-04-07 | |  |
| 10490 | Sunny D Original (per 8oz) | Sunny D | US | beverage | M | TODO | 2026-04-07 | |  |
| 10496 | Snapple Peach Tea (per 16oz) | Snapple | US | beverage | M | TODO | 2026-04-07 | |  |
| 10498 | Vitaminwater XXX Acai (per 20oz) | Vitaminwater | US | beverage | M | TODO | 2026-04-07 | |  |
| 10499 | Vitaminwater Zero Sugar Squeezed (per 20oz) | Vitaminwater | US | beverage | M | TODO | 2026-04-07 | |  |
| 10503 | Spindrift Sparkling Lemon (per 12oz) | Spindrift | US | beverage | M | TODO | 2026-04-07 | |  |
| 10505 | Bai Brasilia Blueberry (per 18oz) | Bai | US | beverage | M | TODO | 2026-04-07 | |  |
| 10508 | Fiji Water (per 500ml) | Fiji | FJ | beverage | L | TODO | 2026-04-07 | |  |
| 10509 | Evian Water (per 500ml) | Evian | FR | beverage | L | TODO | 2026-04-07 | |  |
| 10510 | Dasani Water (per 500ml) | Dasani | US | beverage | L | TODO | 2026-04-07 | |  |
| 10511 | Aquafina Water (per 500ml) | Aquafina | US | beverage | L | TODO | 2026-04-07 | |  |

## Section 143: Bread, Canned, Pasta & Condiment Brands (60 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10516 | Arnold Whole Grain Bread (per slice) | Arnold | US | bread | M | TODO | 2026-04-07 | |  |
| 10517 | Martin's Potato Rolls (per roll) | Martin's | US | bread | M | TODO | 2026-04-07 | |  |
| 10522 | Pillsbury Crescent Rolls (per roll) | Pillsbury | US | bread | M | TODO | 2026-04-07 | |  |
| 10523 | Pillsbury Cinnamon Rolls (per roll) | Pillsbury | US | bread | M | TODO | 2026-04-07 | |  |
| 10524 | Pillsbury Grands Biscuits (per biscuit) | Pillsbury | US | bread | M | TODO | 2026-04-07 | |  |
| 10525 | Pillsbury Cookie Dough Chocolate Chip (per serving) | Pillsbury | US | dessert | M | TODO | 2026-04-07 | |  |
| 10526 | Pillsbury Pie Crust (per serving) | Pillsbury | US | baking | L | TODO | 2026-04-07 | |  |
| 10527 | Entenmann's Rich Frosted Donuts (per donut) | Entenmann's | US | dessert | M | TODO | 2026-04-07 | |  |
| 10528 | Entenmann's Crumb Coffee Cake (per slice) | Entenmann's | US | dessert | M | TODO | 2026-04-07 | |  |
| 10529 | Entenmann's Chocolate Chip Cookies (per 3) | Entenmann's | US | dessert | M | TODO | 2026-04-07 | |  |
| 10533 | Old El Paso Taco Shells Hard (per 2 shells) | Old El Paso | US | bread | M | TODO | 2026-04-07 | |  |
| 10534 | Old El Paso Flour Tortillas Soft Taco (per tortilla) | Old El Paso | US | bread | M | TODO | 2026-04-07 | |  |
| 10536 | Campbell's Chunky Sirloin Burger Soup (per serving) | Campbell's | US | soup | M | TODO | 2026-04-07 | |  |
| 10538 | Campbell's Cream of Chicken Soup (per serving) | Campbell's | US | soup | M | TODO | 2026-04-07 | |  |
| 10539 | Progresso Rich & Hearty Chicken Corn Chowder (per serving) | Progresso | US | soup | M | TODO | 2026-04-07 | |  |
| 10541 | Barilla Spaghetti No.5 (per 2oz dry) | Barilla | IT | staple | M | TODO | 2026-04-07 | |  |
| 10542 | Barilla Penne Rigate (per 2oz dry) | Barilla | IT | staple | M | TODO | 2026-04-07 | |  |
| 10545 | Prego Traditional Marinara (per serving) | Prego | US | condiment | M | TODO | 2026-04-07 | |  |
| 10546 | Ragu Old World Style Marinara (per serving) | Ragu | US | condiment | M | TODO | 2026-04-07 | |  |
| 10548 | Newman's Own Marinara (per serving) | Newman's Own | US | condiment | M | TODO | 2026-04-07 | |  |
| 10549 | Classico Tomato & Basil (per serving) | Classico | US | condiment | M | TODO | 2026-04-07 | |  |
| 10551 | StarKist Chunk White Albacore Water (per can) | StarKist | US | protein | M | TODO | 2026-04-07 | |  |
| 10552 | Bumble Bee Solid White Albacore (per can) | Bumble Bee | US | protein | M | TODO | 2026-04-07 | |  |
| 10553 | Chicken of the Sea Chunk Light Tuna (per can) | CotS | US | protein | M | TODO | 2026-04-07 | |  |
| 10558 | Goya Chickpeas Canned (per serving) | Goya | US | staple | M | TODO | 2026-04-07 | |  |
| 10561 | Del Monte Fruit Cocktail (per serving) | Del Monte | US | fruit | M | TODO | 2026-04-07 | |  |
| 10563 | Mott's Applesauce Original (per cup) | Mott's | US | fruit | M | TODO | 2026-04-07 | |  |
| 10564 | Hormel Chili No Beans (per serving) | Hormel | US | protein | M | TODO | 2026-04-07 | |  |
| 10565 | Hormel Chili with Beans (per serving) | Hormel | US | protein | M | TODO | 2026-04-07 | |  |
| 10566 | Chef Boyardee Beef Ravioli (per serving) | Chef Boyardee | US | pasta | M | TODO | 2026-04-07 | |  |
| 10567 | Chef Boyardee Beefaroni (per serving) | Chef Boyardee | US | pasta | M | TODO | 2026-04-07 | |  |
| 10568 | SpaghettiOs Original (per serving) | SpaghettiOs | US | pasta | M | TODO | 2026-04-07 | |  |
| 10569 | Spam Classic (per 2oz serving) | Spam | US | protein | M | TODO | 2026-04-07 | |  |
| 10570 | Spam Lite (per 2oz serving) | Spam | US | protein | M | TODO | 2026-04-07 | |  |
| 10571 | Velveeta Shells & Cheese (per serving) | Velveeta | US | pasta | M | TODO | 2026-04-07 | |  |
| 10572 | Kraft Mac & Cheese Original (per serving) | Kraft | US | pasta | H | TODO | 2026-04-07 | |  |

## Section 144: Plant-Based & Dairy Alt Brands (25 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10574 | Beyond Meat Beyond Sausage Brat (per link) | Beyond Meat | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10575 | Beyond Meat Beyond Beef Crumbles (per serving) | Beyond Meat | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10579 | Impossible Sausage Links (per 2) | Impossible | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10580 | MorningStar Farms Veggie Burger (per patty) | MorningStar | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10581 | MorningStar Farms Chik'n Nuggets (per 5) | MorningStar | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10582 | MorningStar Farms Sausage Patties (per 2) | MorningStar | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10583 | Boca Original Veggie Burger (per patty) | Boca | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10584 | Gardein Ultimate Plant-Based Burger (per patty) | Gardein | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10585 | Gardein Crispy Chick'n Tenders (per 2) | Gardein | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10586 | Lightlife Smart Ground Crumbles (per serving) | Lightlife | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10587 | Tofurky Deli Slices Hickory Smoked (per 5 slices) | Tofurky | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10588 | Field Roast Sausage Italian (per link) | Field Roast | US | meat_alt | M | TODO | 2026-04-07 | |  |
| 10589 | JUST Egg Plant-Based Scramble (per serving) | JUST | US | meat_alt | H | TODO | 2026-04-07 | |  |
| 10590 | Silk Oat Yeah Oatmilk Original (per 8oz) | Silk | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10591 | Silk Soy Milk Original (per 8oz) | Silk | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10592 | Califia Farms Oat Milk Barista (per 8oz) | Califia | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10593 | Planet Oat Original Oatmilk (per 8oz) | Planet Oat | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10594 | Chobani Oat Milk Plain (per 8oz) | Chobani | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10595 | Good Karma Flaxmilk Original (per 8oz) | Good Karma | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10596 | Daiya Cheddar Style Shreds (per 30g) | Daiya | US | dairy_alt | M | TODO | 2026-04-07 | |  |
| 10597 | Violife Epic Mature Cheddar Slices (per slice) | Violife | GR | dairy_alt | M | TODO | 2026-04-07 | |  |

## Section 145: Sports & Hydration Products (25 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10598 | Gatorade Thirst Quencher Lemon Lime (per 20oz) | Gatorade | US | sports_drink | H | TODO | 2026-04-07 | |  |
| 10599 | Gatorade Thirst Quencher Fruit Punch (per 20oz) | Gatorade | US | sports_drink | M | TODO | 2026-04-07 | |  |
| 10600 | Gatorade Thirst Quencher Cool Blue (per 20oz) | Gatorade | US | sports_drink | M | TODO | 2026-04-07 | |  |
| 10603 | Gatorade Fit Active Berry (per 16.9oz) | Gatorade | US | sports_drink | M | TODO | 2026-04-07 | |  |
| 10614 | Nuun Sport Lemon Lime (per tablet) | Nuun | US | supplement | M | TODO | 2026-04-07 | |  |
| 10615 | Nuun Sport Tri-Berry (per tablet) | Nuun | US | supplement | M | TODO | 2026-04-07 | |  |
| 10616 | Pedialyte Classic Liters (per 8oz) | Pedialyte | US | supplement | M | TODO | 2026-04-07 | |  |
| 10617 | Pedialyte Freezer Pops (per pop) | Pedialyte | US | supplement | M | TODO | 2026-04-07 | |  |
| 10618 | Electrolit Fruit Punch (per 21oz) | Electrolit | MX | supplement | M | TODO | 2026-04-07 | |  |
| 10619 | Electrolit Berry (per 21oz) | Electrolit | MX | supplement | M | TODO | 2026-04-07 | |  |
| 10620 | DripDrop ORS Lemon (per stick) | DripDrop | US | supplement | M | TODO | 2026-04-07 | |  |
| 10621 | Propel Water Berry (per 16.9oz) | Propel | US | beverage | M | TODO | 2026-04-07 | |  |
| 10622 | Essentia Water Ionized (per 20oz) | Essentia | US | beverage | L | TODO | 2026-04-07 | |  |

## Section 146: Frozen Meal Brands Complete (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10624 | DiGiorno Rising Crust Pepperoni (per slice) | DiGiorno | US | frozen_meal | H | TODO | 2026-04-07 | |  |
| 10625 | DiGiorno Rising Crust Supreme (per slice) | DiGiorno | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10626 | DiGiorno Stuffed Crust Pepperoni (per slice) | DiGiorno | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10627 | Red Baron Classic Pepperoni (per slice) | Red Baron | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10628 | Red Baron French Bread Pepperoni (per piece) | Red Baron | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10629 | Tombstone Original Pepperoni (per slice) | Tombstone | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10636 | Lean Cuisine Vermont White Cheddar Mac & Cheese | Lean Cuisine | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10638 | Stouffer's Lasagna with Meat (per serving) | Stouffer's | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10642 | Marie Callender's Country Fried Chicken | Marie Callender's | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10643 | Hungry-Man Salisbury Steak | Hungry-Man | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10644 | Hungry-Man Boneless Fried Chicken | Hungry-Man | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10645 | Banquet Pot Pie Chicken | Banquet | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10648 | Devour Buffalo Chicken Mac & Cheese | Devour | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10651 | Healthy Choice Power Bowl Chicken Feta | Healthy Choice | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10653 | Bird's Eye Protein Blends Chicken Fajita | Bird's Eye | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10654 | Green Giant Cauliflower Gnocchi | Green Giant | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10657 | Tyson Grilled & Ready Chicken Strips (per serving) | Tyson | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10658 | Ore-Ida Golden Crinkles Fries (per serving) | Ore-Ida | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10659 | Ore-Ida Tater Tots (per serving) | Ore-Ida | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10662 | El Monterey Chicken & Cheese Taquitos (per 3) | El Monterey | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10663 | Jimmy Dean Sausage Egg Cheese Biscuit (per piece) | Jimmy Dean | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10664 | Jimmy Dean Sausage Egg Cheese Croissant (per piece) | Jimmy Dean | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10665 | Eggo Homestyle Waffles (per 2) | Eggo | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10666 | Eggo Blueberry Waffles (per 2) | Eggo | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10667 | Bagel Bites Cheese & Pepperoni (per 9) | Bagel Bites | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10668 | Corn Dogs Foster Farms (per dog) | Foster Farms | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10669 | Fish Sticks Gorton's (per 6) | Gorton's | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10670 | Gorton's Grilled Salmon Classic (per fillet) | Gorton's | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10671 | Mozzarella Sticks Farm Rich (per 3) | Farm Rich | US | frozen_meal | M | TODO | 2026-04-07 | |  |
| 10672 | Tattooed Chef Riced Cauliflower Bowl | Tattooed Chef | US | frozen_meal | M | TODO | 2026-04-07 | |  |

## Section 147: Condiment & Sauce Brands Complete (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 10673 | Heinz Tomato Ketchup (per tbsp) | Heinz | US | condiment | H | TODO | 2026-04-07 | |  |
| 10675 | Heinz 57 Sauce (per tbsp) | Heinz | US | condiment | M | TODO | 2026-04-07 | |  |
| 10677 | French's Crispy Fried Onions (per tbsp) | French's | US | condiment | M | TODO | 2026-04-07 | |  |
| 10678 | Hellmann's Real Mayonnaise (per tbsp) | Hellmann's | US | condiment | H | TODO | 2026-04-07 | |  |
| 10679 | Hellmann's Light Mayo (per tbsp) | Hellmann's | US | condiment | M | TODO | 2026-04-07 | |  |
| 10680 | Duke's Real Mayonnaise (per tbsp) | Duke's | US | condiment | M | TODO | 2026-04-07 | | Southern icon |
| 10681 | Sir Kensington's Classic Ketchup (per tbsp) | Sir Kensington's | US | condiment | M | TODO | 2026-04-07 | |  |
| 10689 | Kraft Thousand Island (per tbsp) | Kraft | US | condiment | M | TODO | 2026-04-07 | |  |
| 10692 | Ken's Steak House Caesar (per tbsp) | Ken's | US | condiment | M | TODO | 2026-04-07 | |  |
| 10694 | Sweet Baby Ray's Original BBQ (per tbsp) | Sweet Baby Ray's | US | condiment | H | TODO | 2026-04-07 | |  |
| 10695 | Sweet Baby Ray's Honey BBQ (per tbsp) | Sweet Baby Ray's | US | condiment | M | TODO | 2026-04-07 | |  |
| 10699 | Tabasco Original Red (per tsp) | Tabasco | US | condiment | M | TODO | 2026-04-07 | |  |
| 10703 | Fly By Jing Sichuan Chili Crisp (per tbsp) | Fly By Jing | US | condiment | M | TODO | 2026-04-07 | |  |
| 10704 | Mike's Hot Honey (per tbsp) | Mike's | US | condiment | M | TODO | 2026-04-07 | |  |
| 10705 | A1 Steak Sauce (per tbsp) | A1 | US | condiment | M | TODO | 2026-04-07 | |  |
| 10706 | Lea & Perrins Worcestershire (per tsp) | Lea & Perrins | US | condiment | M | TODO | 2026-04-07 | |  |
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
