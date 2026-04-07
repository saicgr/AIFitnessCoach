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
| 22 | Magic Spoon Protein Cereal Cinnamon Roll | Magic Spoon | US | protein_cereal | H | TODO | 2026-04-07 | | |
| 23 | Magic Spoon Protein Cereal Blueberry Muffin | Magic Spoon | US | protein_cereal | H | TODO | 2026-04-07 | | |
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
| 41 | Grenade Carb Killa White Chocolate Cookie | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 42 | Grenade Carb Killa Oreo White | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 43 | Grenade Carb Killa Caramel Chaos | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 44 | Grenade Carb Killa Birthday Cake | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 45 | Grenade Carb Killa Dark Chocolate Mint | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 46 | Grenade Carb Killa Fudged Up | Grenade | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 47 | Fulfil Vitamin & Protein Bar Chocolate Salted Caramel | Fulfil | IE | protein_bar | H | TODO | 2026-04-07 | | |
| 48 | Fulfil Vitamin & Protein Bar White Choc Cookie Dough | Fulfil | IE | protein_bar | H | TODO | 2026-04-07 | | |
| 49 | Fulfil Vitamin & Protein Bar Peanut & Caramel | Fulfil | IE | protein_bar | H | TODO | 2026-04-07 | | |
| 50 | PhD Smart Bar Chocolate Brownie | PhD Nutrition | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 51 | PhD Smart Bar White Chocolate Blondie | PhD Nutrition | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 52 | PhD Smart Bar Dark Chocolate Raspberry | PhD Nutrition | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 57 | Barebells Protein Bar White Salty Peanut | Barebells | SE | protein_bar | H | TODO | 2026-04-07 | | |
| 58 | Barebells Soft Protein Bar Caramel Choco | Barebells | SE | protein_bar | H | TODO | 2026-04-07 | | |
| 59 | Mars Hi Protein Bar | Mars | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 60 | Snickers Hi Protein Bar | Snickers | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 61 | Bounty Hi Protein Bar | Bounty | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 62 | Milky Way Hi Protein Bar | Milky Way | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 63 | Twix Hi Protein Bar | Twix | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 64 | Maximuscle Protein Bar Millionaires Shortbread | Maximuscle | GB | protein_bar | M | TODO | 2026-04-07 | | |
| 65 | Nocco BCAA Protein Bar Lemon | Nocco | SE | protein_bar | M | TODO | 2026-04-07 | | |
| 66 | ESN Designer Bar Crunchy | ESN | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 67 | ESN Designer Bar Caramel Brownie | ESN | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 68 | BioTechUSA Zero Bar Chocolate Chip Cookies | BioTechUSA | HU | protein_bar | M | TODO | 2026-04-07 | | |
| 69 | BioTechUSA Zero Bar Double Chocolate | BioTechUSA | HU | protein_bar | M | TODO | 2026-04-07 | | |
| 70 | PowerBar Protein Plus 30% Chocolate | PowerBar | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 71 | Multipower 53% Protein Bar Chocolate | Multipower | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 73 | Musashi High Protein Bar Dark Choc Salted Caramel | Musashi | AU | protein_bar | M | TODO | 2026-04-07 | | |
| 74 | Musashi High Protein Bar Peanut Butter | Musashi | AU | protein_bar | M | TODO | 2026-04-07 | | |
| 75 | Aussie Bodies ProteinFX Lo Carb Crisp | Aussie Bodies | AU | protein_bar | M | TODO | 2026-04-07 | | |
| 76 | Body Science BSc High Protein Bar Peanut Butter | Body Science | AU | protein_bar | M | TODO | 2026-04-07 | | |
| 77 | Ritebite Max Protein Bar Choco Fudge | RiteBite | IN | protein_bar | H | TODO | 2026-04-07 | | |
| 78 | Ritebite Max Protein Bar Peanut Butter | RiteBite | IN | protein_bar | H | TODO | 2026-04-07 | | |
| 79 | Yoga Bar Protein Bar Almond Fudge | Yoga Bar | IN | protein_bar | H | TODO | 2026-04-07 | | |
| 80 | Yoga Bar Protein Bar Cranberry | Yoga Bar | IN | protein_bar | H | TODO | 2026-04-07 | | |
| 81 | MuscleBlaze Protein Bar Choco Delight | MuscleBlaze | IN | protein_bar | H | TODO | 2026-04-07 | | |
| 82 | MuscleBlaze Protein Bar Peanut Butter | MuscleBlaze | IN | protein_bar | H | TODO | 2026-04-07 | | |
| 83 | HYP Lean Protein Bar Espresso | HYP | IN | protein_bar | M | TODO | 2026-04-07 | | |
| 84 | Misfits Vegan Protein Bar Chocolate Caramel | Misfits | GB | protein_bar | M | TODO | 2026-04-07 | | |
| 85 | Misfits Vegan Protein Bar Cookie Dough | Misfits | GB | protein_bar | M | TODO | 2026-04-07 | | |
| 86 | Battle Bites Protein Bar Toffee Apple | Battle Bites | GB | protein_bar | M | TODO | 2026-04-07 | | |
| 87 | Dymatize Elite Protein Bar Chocolate Peanut Butter | Dymatize | US | protein_bar | M | TODO | 2026-04-07 | | |
| 88 | Nugo Slim Bar Espresso | NuGo | US | protein_bar | L | TODO | 2026-04-07 | | |
| 90 | ProBar Base Protein Bar Cookie Dough | ProBar | US | protein_bar | L | TODO | 2026-04-07 | | |

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
| 128 | Wilde Protein Chips Nashville Hot | Wilde | US | protein_snack | M | TODO | 2026-04-07 | | |
| 129 | Wilde Protein Chips Sea Salt & Vinegar | Wilde | US | protein_snack | M | TODO | 2026-04-07 | | |
| 130 | Legendary Foods Protein Pastry Strawberry | Legendary Foods | US | protein_snack | M | TODO | 2026-04-07 | | |
| 131 | Legendary Foods Protein Pastry Brown Sugar Cinnamon | Legendary Foods | US | protein_snack | M | TODO | 2026-04-07 | | |
| 132 | The Protein Ball Co Peanut Butter | The Protein Ball Co | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 133 | The Protein Ball Co Lemon Pistachio | The Protein Ball Co | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 134 | Graze Protein Bites Cocoa Vanilla | Graze | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 135 | Graze Protein Oat Bites Honey | Graze | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 136 | Biltong Chief Original South African Biltong | Biltong Chief | ZA | protein_snack | M | TODO | 2026-04-07 | | |
| 137 | Brooklyn Biltong Original | Brooklyn Biltong | US | protein_snack | M | TODO | 2026-04-07 | | |
| 138 | Country Archer Zero Sugar Beef Jerky | Country Archer | US | protein_snack | M | TODO | 2026-04-07 | | |
| 139 | The New Primal Classic Beef Stick | The New Primal | US | protein_snack | M | TODO | 2026-04-07 | | |
| 140 | Peperami Protein Bites | Peperami | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 141 | Protein Puck Original | Protein Puck | US | protein_snack | L | TODO | 2026-04-07 | | |
| 142 | BioTechUSA Protein Chips Salt | BioTechUSA | HU | protein_snack | M | TODO | 2026-04-07 | | |
| 143 | BioTechUSA Protein Chips Cheese | BioTechUSA | HU | protein_snack | M | TODO | 2026-04-07 | | |
| 144 | MyProtein Protein Brownie Chocolate | MyProtein | GB | protein_snack | H | TODO | 2026-04-07 | | |
| 145 | MyProtein Protein Wafer Chocolate Hazelnut | MyProtein | GB | protein_snack | H | TODO | 2026-04-07 | | |
| 146 | Prozis Protein Wafer Chocolate | Prozis | PT | protein_snack | M | TODO | 2026-04-07 | | |
| 147 | Prozis Protein Chips Sour Cream | Prozis | PT | protein_snack | M | TODO | 2026-04-07 | | |
| 148 | IronMaxx Protein Chips Paprika | IronMaxx | DE | protein_snack | M | TODO | 2026-04-07 | | |
| 149 | High Key Protein Cereal Mini Cookies Chocolate | HighKey | US | protein_snack | M | TODO | 2026-04-07 | | |
| 150 | Flapjacked Mighty Muffin Double Chocolate | Flapjacked | US | protein_snack | M | TODO | 2026-04-07 | | |

## Section 5: International Energy Drinks (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 152 | Monster Energy Ultra Fiesta Mango | Monster | US | energy_drink | M | TODO | 2026-04-07 | | |
| 153 | Monster Energy Ultra Watermelon | Monster | US | energy_drink | M | TODO | 2026-04-07 | | |
| 154 | Monster Energy Juiced Mango Loco | Monster | US | energy_drink | M | TODO | 2026-04-07 | | |
| 155 | Monster Energy Rehab Peach Tea | Monster | US | energy_drink | M | TODO | 2026-04-07 | | |
| 156 | Celsius Sparkling Orange | Celsius | SE | energy_drink | H | TODO | 2026-04-07 | | |
| 158 | Celsius Sparkling Peach Vibe | Celsius | SE | energy_drink | H | TODO | 2026-04-07 | | |
| 159 | Celsius Essentials Sparkling Cherry Limeade | Celsius | SE | energy_drink | M | TODO | 2026-04-07 | | |
| 160 | Celsius On-the-Go Powder Kiwi Guava | Celsius | SE | energy_drink | M | TODO | 2026-04-07 | | |
| 166 | C4 Smart Energy Cotton Candy | C4 | US | energy_drink | M | TODO | 2026-04-07 | | |
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
| 202 | Scitec Nutrition 100% Whey Protein Chocolate | Scitec | HU | protein_powder | M | TODO | 2026-04-07 | | |
| 203 | BioTechUSA 100% Pure Whey Biscuit | BioTechUSA | HU | protein_powder | M | TODO | 2026-04-07 | | |
| 204 | Olimp Whey Protein Complex Chocolate | Olimp | PL | protein_powder | M | TODO | 2026-04-07 | | |
| 205 | Reflex Nutrition Instant Whey Chocolate | Reflex | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 206 | Applied Nutrition ISO-XP Chocolate | Applied Nutrition | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 207 | Bulk Powders Pure Whey Protein Chocolate | Bulk | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 208 | MuscleBlaze Biozyme Whey Protein Rich Chocolate | MuscleBlaze | IN | protein_powder | H | TODO | 2026-04-07 | | India bestseller |
| 209 | AS-IT-IS Whey Protein Unflavored | AS-IT-IS | IN | protein_powder | M | TODO | 2026-04-07 | | |
| 210 | Nakpro Whey Protein Chocolate | Nakpro | IN | protein_powder | M | TODO | 2026-04-07 | | |
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
| 250 | Shin Ramyun Black | Nongshim | KR | instant_noodle | H | TODO | 2026-04-07 | | |
| 251 | Nongshim Chapagetti | Nongshim | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 252 | Nongshim Neoguri Seafood | Nongshim | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 253 | Ottogi Jin Ramen Spicy | Ottogi | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 254 | Paldo Bibimmyeon | Paldo | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 255 | Nissin Cup Noodles Chicken | Nissin | JP | instant_noodle | H | TODO | 2026-04-07 | | |
| 256 | Nissin Cup Noodles Seafood | Nissin | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 257 | Nissin Demae Ramen Tonkotsu | Nissin | JP | instant_noodle | M | TODO | 2026-04-07 | | |
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
| 268 | Cup Noodles Mazedaar Masala | Nissin India | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 269 | Koka Laksa Singapore Noodles | Koka | SG | instant_noodle | M | TODO | 2026-04-07 | | |
| 270 | Prima Taste Laksa La Mian | Prima Taste | SG | instant_noodle | M | TODO | 2026-04-07 | | |

## Section 9: International Chocolate & Confectionery (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 271 | Lindt Excellence 85% Dark Chocolate | Lindt | CH | chocolate | H | TODO | 2026-04-07 | | |
| 273 | Lindt Lindor Milk Chocolate Truffle | Lindt | CH | chocolate | M | TODO | 2026-04-07 | | per piece |
| 274 | Toblerone Milk Chocolate | Toblerone | CH | chocolate | M | TODO | 2026-04-07 | | |
| 278 | Cadbury Dairy Milk Fruit & Nut | Cadbury | GB | chocolate | M | TODO | 2026-04-07 | | |
| 279 | Cadbury Dairy Milk Silk Oreo | Cadbury | IN | chocolate | H | TODO | 2026-04-07 | | India variant |
| 280 | Cadbury Dairy Milk Silk Bubbly | Cadbury | IN | chocolate | M | TODO | 2026-04-07 | | |
| 281 | Cadbury 5 Star | Cadbury | IN | chocolate | H | TODO | 2026-04-07 | | |
| 282 | Cadbury Perk | Cadbury | IN | chocolate | M | TODO | 2026-04-07 | | |
| 283 | Amul Dark Chocolate 55% | Amul | IN | chocolate | H | TODO | 2026-04-07 | | |
| 286 | Kinder Bueno White | Ferrero | IT | chocolate | M | TODO | 2026-04-07 | | |
| 287 | Kinder Joy (per egg) | Ferrero | IT | chocolate | M | TODO | 2026-04-07 | | |
| 289 | Ritter Sport Whole Hazelnuts | Ritter Sport | DE | chocolate | M | TODO | 2026-04-07 | | |
| 290 | Ritter Sport Dark Whole Hazelnuts | Ritter Sport | DE | chocolate | M | TODO | 2026-04-07 | | |
| 293 | Pocky Chocolate | Glico | JP | confectionery | H | TODO | 2026-04-07 | | |
| 294 | Pocky Strawberry | Glico | JP | confectionery | M | TODO | 2026-04-07 | | |
| 295 | Kit Kat Matcha (Japan) | Nestle | JP | chocolate | H | TODO | 2026-04-07 | | Japan exclusive |
| 296 | Kit Kat Strawberry Cheesecake (Japan) | Nestle | JP | chocolate | M | TODO | 2026-04-07 | | Japan exclusive |
| 297 | Meiji Chocolate Milk Bar | Meiji | JP | chocolate | M | TODO | 2026-04-07 | | |
| 298 | Lotte Ghana Chocolate Milk | Lotte | KR | chocolate | M | TODO | 2026-04-07 | | |
| 300 | Turkish Delight Hazer Baba Rose | Hazer Baba | TR | confectionery | M | TODO | 2026-04-07 | | |

## Section 10: International Chips & Savory Snacks (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 301 | Lay's Magic Masala (India) | Lay's | IN | snack | H | TODO | 2026-04-07 | | India flavor |
| 302 | Lay's American Style Cream & Onion (India) | Lay's | IN | snack | M | TODO | 2026-04-07 | | |
| 304 | Kurkure Chilli Chatka | Kurkure | IN | snack | M | TODO | 2026-04-07 | | |
| 306 | Haldiram's Moong Dal | Haldiram's | IN | snack | H | TODO | 2026-04-07 | | |
| 307 | Haldiram's Sev Bhujia | Haldiram's | IN | snack | M | TODO | 2026-04-07 | | |
| 308 | Bikano Bikaneri Bhujia | Bikano | IN | snack | M | TODO | 2026-04-07 | | |
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
| 354 | Paper Boat Aam Panna | Paper Boat | IN | beverage | M | TODO | 2026-04-07 | | |
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
| 366 | Makgeolli Korean Rice Wine | Various | KR | beverage | M | TODO | 2026-04-07 | | |
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
| 385 | Hide & Seek Chocolate Chip Cookie | Parle | IN | biscuit | H | TODO | 2026-04-07 | | |
| 386 | Unibic Choco Chip Cookies | Unibic | IN | biscuit | M | TODO | 2026-04-07 | | |
| 387 | Digestive Biscuit Britannia | Britannia | IN | biscuit | M | TODO | 2026-04-07 | | |
| 388 | Tim Tam Original | Arnott's | AU | biscuit | H | TODO | 2026-04-07 | | Australian icon |
| 389 | Tim Tam Double Coat | Arnott's | AU | biscuit | M | TODO | 2026-04-07 | | |
| 390 | Arnott's Shapes BBQ | Arnott's | AU | biscuit | M | TODO | 2026-04-07 | | |
| 391 | Koala March Chocolate | Lotte | JP | biscuit | M | TODO | 2026-04-07 | | |
| 392 | Bourbon Alfort Chocolate | Bourbon | JP | biscuit | M | TODO | 2026-04-07 | | |
| 393 | Country Ma'am Vanilla & Cocoa | Fujiya | JP | biscuit | M | TODO | 2026-04-07 | | |
| 394 | Choco Pie (Korean) | Lotte | KR | biscuit | H | TODO | 2026-04-07 | | |
| 395 | Pepperidge Farm Milano Double Dark Chocolate | Pepperidge Farm | US | biscuit | M | TODO | 2026-04-07 | | |
| 396 | Stroopwafel Daelmans Caramel | Daelmans | NL | biscuit | H | TODO | 2026-04-07 | | Dutch icon |
| 397 | Leibniz Butter Biscuit | Bahlsen | DE | biscuit | M | TODO | 2026-04-07 | | |
| 398 | Bahlsen Choco Leibniz | Bahlsen | DE | biscuit | M | TODO | 2026-04-07 | | |
| 399 | LU Petit Beurre | LU | FR | biscuit | M | TODO | 2026-04-07 | | |
| 400 | Belvita Breakfast Biscuit Honey & Nut | Belvita | FR | biscuit | M | TODO | 2026-04-07 | | |

## Section 13: International Spreads & Condiments (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 401 | Vegemite | Bega | AU | spread | H | TODO | 2026-04-07 | | Australian icon |
| 403 | Bovril | Bovril | GB | spread | M | TODO | 2026-04-07 | | |
| 404 | Speculoos Spread (Trader Joe's Cookie Butter) | Trader Joe's | US | spread | M | TODO | 2026-04-07 | | |
| 405 | Pip & Nut Almond Butter Smooth | Pip & Nut | GB | spread | M | TODO | 2026-04-07 | | |
| 406 | Meridian Peanut Butter Smooth No Added Sugar | Meridian | GB | spread | M | TODO | 2026-04-07 | | |
| 407 | MyProtein Peanut Butter Smooth | MyProtein | GB | spread | M | TODO | 2026-04-07 | | |
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
| 419 | Sambal Oelek Huy Fong | Huy Fong | US | condiment | M | TODO | 2026-04-07 | | |
| 422 | Kimchi Jongga Mat | Jongga | KR | condiment | H | TODO | 2026-04-07 | | per 100g |
| 423 | Japanese Kewpie Mayonnaise | Kewpie | JP | condiment | H | TODO | 2026-04-07 | | |
| 424 | Bulldog Tonkatsu Sauce | Bulldog | JP | condiment | M | TODO | 2026-04-07 | | |
| 425 | Nando's Peri-Peri Sauce Hot | Nando's | ZA | condiment | M | TODO | 2026-04-07 | | |
| 426 | Encona West Indian Hot Pepper Sauce | Encona | GB | condiment | M | TODO | 2026-04-07 | | |
| 427 | Lao Gan Ma Chili Crisp | Lao Gan Ma | CN | condiment | H | TODO | 2026-04-07 | | Viral worldwide |
| 428 | Lee Kum Kee Oyster Sauce | Lee Kum Kee | HK | condiment | M | TODO | 2026-04-07 | | |
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
| 436 | Charlie Bigham's Chicken Tikka Masala | Charlie Bigham's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 437 | McCain Oven Chips Straight Cut | McCain | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 438 | Frosta Chicken Tikka Masala | Frosta | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 439 | Iglo Fish Sticks (Fischstabchen) | Iglo | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 440 | Dr. Oetker Ristorante Pizza Mozzarella | Dr. Oetker | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 441 | Wagner Big Pizza Supreme | Wagner | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 442 | Picard Gratin Dauphinois | Picard | FR | frozen_meal | M | TODO | 2026-04-07 | | |
| 443 | Findus Crispy Pancakes Minced Beef | Findus | SE | frozen_meal | M | TODO | 2026-04-07 | | |
| 444 | MyProtein Protein Meal Prep Pot Chicken Tikka | MyProtein | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 445 | Fuel10K Protein Porridge Pot Chocolate | Fuel10K | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 446 | MTR Ready to Eat Rajma Masala | MTR | IN | ready_meal | H | TODO | 2026-04-07 | | |
| 447 | MTR Ready to Eat Paneer Butter Masala | MTR | IN | ready_meal | H | TODO | 2026-04-07 | | |
| 448 | Haldiram's Ready to Eat Biryani | Haldiram's | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 449 | Gits Ready to Eat Dal Makhani | Gits | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 450 | McCain Aloo Tikki (India) | McCain | IN | frozen_meal | M | TODO | 2026-04-07 | | |

## Section 15: International Bread & Bakery (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 451 | Warburtons Medium Sliced White | Warburtons | GB | bread | M | TODO | 2026-04-07 | | |
| 452 | Warburtons Protein Thins | Warburtons | GB | bread | H | TODO | 2026-04-07 | | Protein bread |
| 453 | Hovis Seed Sensations | Hovis | GB | bread | M | TODO | 2026-04-07 | | |
| 454 | Mestemacher Protein Bread | Mestemacher | DE | bread | H | TODO | 2026-04-07 | | |
| 455 | Mestemacher Pumpernickel | Mestemacher | DE | bread | M | TODO | 2026-04-07 | | |
| 456 | Wasa Crispbread Original | Wasa | SE | bread | M | TODO | 2026-04-07 | | |
| 457 | Britannia Whole Wheat Bread | Britannia | IN | bread | M | TODO | 2026-04-07 | | |
| 458 | Modern Bread White | Modern | IN | bread | M | TODO | 2026-04-07 | | |
| 459 | Pita Bread Kontos | Kontos | GR | bread | M | TODO | 2026-04-07 | | |
| 460 | Naan Bread Stonefire | Stonefire | US | bread | M | TODO | 2026-04-07 | | |
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
| 471 | Mochi Ice Cream Little Moons Passion Fruit | Little Moons | GB | dessert | H | TODO | 2026-04-07 | | Viral TikTok |
| 472 | Mochi Ice Cream Little Moons Mango | Little Moons | GB | dessert | M | TODO | 2026-04-07 | | |
| 473 | Hi-Chew Strawberry | Morinaga | JP | confectionery | M | TODO | 2026-04-07 | | |
| 474 | Hi-Chew Grape | Morinaga | JP | confectionery | L | TODO | 2026-04-07 | | |
| 475 | Meiji Apollo Strawberry Chocolate | Meiji | JP | chocolate | M | TODO | 2026-04-07 | | |
| 476 | Kinoko no Yama Chocolate Mushroom | Meiji | JP | confectionery | M | TODO | 2026-04-07 | | |
| 477 | Takenoko no Sato Chocolate Bamboo | Meiji | JP | confectionery | M | TODO | 2026-04-07 | | |
| 478 | Calbee Potato Chips Consomme | Calbee | JP | snack | M | TODO | 2026-04-07 | | |
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
| 501 | Labneh (strained yogurt) | Various | LB | dairy | H | TODO | 2026-04-07 | | per 100g |
| 502 | Halloumi Cheese | Various | CY | dairy | H | TODO | 2026-04-07 | | |
| 503 | Kunafa (Knafeh per piece) | Various | PS | dessert | M | TODO | 2026-04-07 | | |
| 504 | Baklava (per piece) | Various | TR | dessert | H | TODO | 2026-04-07 | | |
| 505 | Simit (Turkish Sesame Bagel) | Various | TR | bread | H | TODO | 2026-04-07 | | |
| 506 | Lahmacun (Turkish Pizza) | Various | TR | bread | M | TODO | 2026-04-07 | | |
| 507 | Ayran (Turkish Yogurt Drink) | Various | TR | beverage | H | TODO | 2026-04-07 | | |
| 508 | Ulker Biskrem Chocolate | Ulker | TR | biscuit | M | TODO | 2026-04-07 | | |
| 509 | Ulker Halley Chocolate Sandwich | Ulker | TR | biscuit | M | TODO | 2026-04-07 | | |
| 510 | Eti Tutku Chocolate Wafer | Eti | TR | biscuit | M | TODO | 2026-04-07 | | |
| 511 | Tahini Halva Plain (per 100g) | Various | TR | confectionery | M | TODO | 2026-04-07 | | |
| 512 | Mastic Gum Elma | Elma | GR | confectionery | L | TODO | 2026-04-07 | | |
| 513 | Al Fakher Dates Filled with Almond | Al Fakher | SA | confectionery | M | TODO | 2026-04-07 | | |
| 514 | Bateel Organic Medjool Dates | Bateel | AE | confectionery | M | TODO | 2026-04-07 | | |
| 515 | Almarai Full Fat Milk 1L | Almarai | SA | dairy | M | TODO | 2026-04-07 | | |
| 516 | Almarai Chocolate Milk | Almarai | SA | dairy | M | TODO | 2026-04-07 | | |
| 517 | Almarai Fresh Juice Orange | Almarai | SA | beverage | M | TODO | 2026-04-07 | | |
| 518 | Nadec Laban (Buttermilk) | Nadec | SA | dairy | M | TODO | 2026-04-07 | | |
| 519 | Nido Powdered Milk (per serving) | Nestle | AE | dairy | M | TODO | 2026-04-07 | | Popular in ME |
| 520 | Vimto Cordial (per serving) | Vimto | GB | beverage | M | TODO | 2026-04-07 | | Huge in Middle East |
| 521 | Maamoul Date Cookie | Various | LB | biscuit | M | TODO | 2026-04-07 | | |
| 522 | Ka'ak Bread Ring (Jerusalem) | Various | PS | bread | M | TODO | 2026-04-07 | | |
| 523 | Manakish Zaatar | Various | LB | bread | M | TODO | 2026-04-07 | | |
| 524 | Shawarma Chicken Wrap (per wrap) | Various | AE | fast_food | H | TODO | 2026-04-07 | | Middle East staple |
| 525 | Falafel (per piece) | Various | EG | snack | H | TODO | 2026-04-07 | | |
| 526 | Fattoush Salad (per serving) | Various | LB | salad | M | TODO | 2026-04-07 | | |
| 527 | Tabbouleh (per serving) | Various | LB | salad | M | TODO | 2026-04-07 | | |
| 528 | Muhammara Red Pepper Dip | Various | SY | dip | M | TODO | 2026-04-07 | | |
| 529 | Baba Ganoush (per serving) | Various | LB | dip | M | TODO | 2026-04-07 | | |
| 530 | Za'atar Spice Mix (per tsp) | Various | LB | condiment | L | TODO | 2026-04-07 | | |

## Section 18: Latin American Foods & Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 531 | Guarana Antarctica Soda | Ambev | BR | beverage | M | TODO | 2026-04-07 | | Brazil national soda |
| 532 | Acai Bowl Frozen Pack (per 100g) | Various | BR | frozen_meal | H | TODO | 2026-04-07 | | |
| 533 | Pao de Queijo (per piece) | Various | BR | bread | M | TODO | 2026-04-07 | | |
| 534 | Brigadeiro (per piece) | Various | BR | confectionery | M | TODO | 2026-04-07 | | |
| 535 | Coxinha (per piece) | Various | BR | snack | M | TODO | 2026-04-07 | | |
| 536 | Havanna Alfajor Chocolate | Havanna | AR | confectionery | M | TODO | 2026-04-07 | | |
| 537 | Empanada de Carne (per piece) | Various | AR | snack | H | TODO | 2026-04-07 | | |
| 538 | Yerba Mate Taragui (brewed per cup) | Taragui | AR | beverage | M | TODO | 2026-04-07 | | |
| 539 | Modelo Especial Beer | Modelo | MX | beverage | M | TODO | 2026-04-07 | | |
| 540 | Jarritos Tamarind Soda | Jarritos | MX | beverage | M | TODO | 2026-04-07 | | |
| 541 | Tajin Clasico Seasoning (per tsp) | Tajin | MX | condiment | M | TODO | 2026-04-07 | | |
| 542 | Valentina Hot Sauce | Valentina | MX | condiment | M | TODO | 2026-04-07 | | |
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
| 551 | Biltong (South African Dried Beef per 100g) | Various | ZA | protein_snack | H | TODO | 2026-04-07 | | |
| 552 | Droewors (South African Dried Sausage) | Various | ZA | protein_snack | M | TODO | 2026-04-07 | | |
| 553 | Rooibos Tea (brewed per cup) | Various | ZA | beverage | M | TODO | 2026-04-07 | | |
| 554 | Amarula Cream Liqueur | Amarula | ZA | beverage | L | TODO | 2026-04-07 | | |
| 555 | Nando's Medium PERi-PERi Sauce (per tbsp) | Nando's | ZA | condiment | M | TODO | 2026-04-07 | | |
| 556 | Pronutro Original Cereal | Bokomo | ZA | cereal | M | TODO | 2026-04-07 | | SA breakfast staple |
| 557 | Ouma Rusks Buttermilk | Nola | ZA | biscuit | M | TODO | 2026-04-07 | | |
| 558 | Jollof Rice (per serving) | Various | NG | rice | H | TODO | 2026-04-07 | | West African staple |
| 559 | Puff Puff (per piece) | Various | NG | snack | M | TODO | 2026-04-07 | | |
| 560 | Chin Chin (Nigerian Fried Snack) | Various | NG | snack | M | TODO | 2026-04-07 | | |
| 561 | Suya Spice Mix (per tsp) | Various | NG | condiment | M | TODO | 2026-04-07 | | |
| 562 | Gari (Cassava Flakes per 100g) | Various | NG | staple | M | TODO | 2026-04-07 | | |
| 563 | Indomie Chicken Flavor (Nigeria) | Indomie | NG | instant_noodle | M | TODO | 2026-04-07 | | Diff from Indonesian |
| 564 | Malta Guinness | Guinness | NG | beverage | M | TODO | 2026-04-07 | | |
| 565 | Peak Evaporated Milk (per serving) | Peak | NG | dairy | M | TODO | 2026-04-07 | | |
| 566 | Injera (Ethiopian Flatbread per piece) | Various | ET | bread | M | TODO | 2026-04-07 | | |
| 567 | Doro Wot (per serving) | Various | ET | curry | M | TODO | 2026-04-07 | | |
| 568 | Ugali (per serving) | Various | KE | staple | M | TODO | 2026-04-07 | | East African staple |
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
| 578 | Mother Dairy Mishti Doi | Mother Dairy | IN | dairy | M | TODO | 2026-04-07 | | |
| 579 | Mother Dairy Paneer (per 100g) | Mother Dairy | IN | dairy | H | TODO | 2026-04-07 | | |
| 580 | Amul Cheese Slice (per slice) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 581 | Amul Butter (per 10g) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 582 | Amul Dark Chocolate 75% | Amul | IN | chocolate | M | TODO | 2026-04-07 | | |
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
| 599 | Parachute Coconut Oil (per tbsp) | Parachute | IN | cooking | M | TODO | 2026-04-07 | | |
| 600 | Hajmola Candy (per piece) | Dabur | IN | confectionery | L | TODO | 2026-04-07 | | |

## Section 21: European Specialty Foods (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 601 | Brie Cheese President (per 30g) | President | FR | dairy | M | TODO | 2026-04-07 | | |
| 602 | Camembert Isigny (per 30g) | Isigny | FR | dairy | M | TODO | 2026-04-07 | | |
| 603 | Comte Cheese (per 30g) | Various | FR | dairy | M | TODO | 2026-04-07 | | |
| 604 | Croissant Au Beurre (per piece) | Various | FR | bread | H | TODO | 2026-04-07 | | |
| 605 | Pain au Chocolat (per piece) | Various | FR | bread | H | TODO | 2026-04-07 | | |
| 606 | Crepe Suzette (per piece) | Various | FR | dessert | M | TODO | 2026-04-07 | | |
| 607 | Danette Chocolate Pudding | Danone | FR | dessert | M | TODO | 2026-04-07 | | |
| 608 | Orangina Sparkling Citrus | Orangina | FR | beverage | M | TODO | 2026-04-07 | | |
| 609 | Parmigiano Reggiano (per 30g) | Various | IT | dairy | H | TODO | 2026-04-07 | | |
| 610 | Mozzarella di Bufala (per 100g) | Various | IT | dairy | M | TODO | 2026-04-07 | | |
| 611 | Prosciutto di Parma (per 30g) | Various | IT | protein | M | TODO | 2026-04-07 | | |
| 612 | Grissini Breadsticks (per piece) | Various | IT | bread | M | TODO | 2026-04-07 | | |
| 613 | Panettone (per slice) | Various | IT | bread | M | TODO | 2026-04-07 | | |
| 614 | Tiramisu (per serving) | Various | IT | dessert | M | TODO | 2026-04-07 | | |
| 615 | San Pellegrino Aranciata | San Pellegrino | IT | beverage | M | TODO | 2026-04-07 | | |
| 616 | Manchego Cheese (per 30g) | Various | ES | dairy | M | TODO | 2026-04-07 | | |
| 617 | Jamon Serrano (per 30g) | Various | ES | protein | M | TODO | 2026-04-07 | | |
| 618 | Churros con Chocolate (per serving) | Various | ES | dessert | M | TODO | 2026-04-07 | | |
| 619 | Gazpacho Alvalle (per serving) | Alvalle | ES | soup | M | TODO | 2026-04-07 | | |
| 620 | Gouda Cheese (per 30g) | Various | NL | dairy | M | TODO | 2026-04-07 | | |
| 621 | Edammer Cheese (per 30g) | Various | NL | dairy | M | TODO | 2026-04-07 | | |
| 622 | Frikandel (per piece) | Various | NL | snack | M | TODO | 2026-04-07 | | |
| 623 | Bitterballen (per piece) | Various | NL | snack | M | TODO | 2026-04-07 | | |
| 624 | Bratwurst Sausage (per piece) | Various | DE | protein | H | TODO | 2026-04-07 | | |
| 625 | Currywurst with Sauce (per serving) | Various | DE | fast_food | M | TODO | 2026-04-07 | | |
| 626 | Pretzel Soft German (per piece) | Various | DE | bread | M | TODO | 2026-04-07 | | |
| 627 | Apfelstrudel (per serving) | Various | AT | dessert | M | TODO | 2026-04-07 | | |
| 628 | Wiener Schnitzel (per serving) | Various | AT | protein | M | TODO | 2026-04-07 | | |
| 629 | Sachertorte (per slice) | Various | AT | dessert | M | TODO | 2026-04-07 | | |
| 630 | Swedish Meatballs IKEA (per 5 pieces) | IKEA | SE | protein | H | TODO | 2026-04-07 | | |
| 631 | Knackebrod Crispbread (per piece) | Various | SE | bread | M | TODO | 2026-04-07 | | |
| 632 | Kanelbulle Cinnamon Bun (per piece) | Various | SE | bread | M | TODO | 2026-04-07 | | |
| 633 | Smoked Salmon Norwegian (per 30g) | Various | NO | protein | H | TODO | 2026-04-07 | | |
| 634 | Brown Cheese Brunost (per 20g) | Various | NO | dairy | M | TODO | 2026-04-07 | | |
| 635 | Pierogi Ruskie (per piece) | Various | PL | snack | M | TODO | 2026-04-07 | | |
| 636 | Kielbasa Polish Sausage (per link) | Various | PL | protein | M | TODO | 2026-04-07 | | |
| 637 | Paczki Donut (per piece) | Various | PL | dessert | M | TODO | 2026-04-07 | | |
| 638 | Feta Cheese Greek (per 30g) | Various | GR | dairy | H | TODO | 2026-04-07 | | |
| 639 | Spanakopita (per piece) | Various | GR | snack | M | TODO | 2026-04-07 | | |
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
| 667 | Lily's Milk Chocolate Style Bar | Lily's | US | chocolate | M | TODO | 2026-04-07 | | |
| 668 | Hu Kitchen Dark Chocolate Almond Butter | Hu Kitchen | US | chocolate | M | TODO | 2026-04-07 | | |

## Section 23: Plant-Based / Vegan Brands (30 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 671 | Beyond Meat Beyond Burger (per patty) | Beyond Meat | US | meat_alt | H | TODO | 2026-04-07 | | |
| 672 | Beyond Meat Beyond Sausage Italian (per link) | Beyond Meat | US | meat_alt | M | TODO | 2026-04-07 | | |
| 674 | Impossible Chicken Nuggets (per 5 pieces) | Impossible Foods | US | meat_alt | M | TODO | 2026-04-07 | | |
| 676 | Oatly Chocolate Oat Milk | Oatly | SE | dairy_alt | M | TODO | 2026-04-07 | | |
| 677 | Alpro Soya Original | Alpro | BE | dairy_alt | M | TODO | 2026-04-07 | | |
| 678 | Alpro Oat Milk Barista | Alpro | BE | dairy_alt | M | TODO | 2026-04-07 | | |
| 679 | Alpro Greek Style Yogurt Plain | Alpro | BE | dairy_alt | M | TODO | 2026-04-07 | | |
| 680 | Violife Mature Cheddar Slices | Violife | GR | dairy_alt | M | TODO | 2026-04-07 | | |
| 681 | Miyoko's Creamery Cultured Vegan Butter | Miyoko's | US | dairy_alt | M | TODO | 2026-04-07 | | |
| 682 | Silk Ultra Protein Milk Chocolate | Silk | US | dairy_alt | M | TODO | 2026-04-07 | | |
| 683 | Ripple Pea Protein Milk Original | Ripple | US | dairy_alt | M | TODO | 2026-04-07 | | |
| 684 | Gardein Ultimate Plant-Based Chicken Tenders | Gardein | US | meat_alt | M | TODO | 2026-04-07 | | |
| 685 | Tofurky Plant-Based Deli Slices Hickory Smoked | Tofurky | US | meat_alt | M | TODO | 2026-04-07 | | |
| 686 | Lightlife Plant-Based Burger | Lightlife | US | meat_alt | M | TODO | 2026-04-07 | | |
| 687 | THIS Isn't Chicken Plant-Based Pieces | THIS | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 688 | THIS Isn't Bacon Plant-Based Rashers | THIS | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 689 | Moving Mountains Plant-Based Burger | Moving Mountains | GB | meat_alt | M | TODO | 2026-04-07 | | |
| 690 | Vivera Plant Steak | Vivera | NL | meat_alt | M | TODO | 2026-04-07 | | |
| 691 | The Vegetarian Butcher No Chicken Chunks | The Vegetarian Butcher | NL | meat_alt | M | TODO | 2026-04-07 | | |
| 692 | Heura Mediterranean Chicken Chunks | Heura | ES | meat_alt | M | TODO | 2026-04-07 | | |
| 693 | Like Meat Like Chicken | Like Meat | DE | meat_alt | M | TODO | 2026-04-07 | | |
| 694 | Vezlay Vegan Seekh Kebab (per piece) | Vezlay | IN | meat_alt | M | TODO | 2026-04-07 | | |
| 695 | GoodDot Proteiz (per serving) | GoodDot | IN | meat_alt | M | TODO | 2026-04-07 | | India plant-based pioneer |
| 696 | Blue Tribe Plant-Based Chicken Keema | Blue Tribe | IN | meat_alt | M | TODO | 2026-04-07 | | |
| 697 | Tempeh (per 100g) | Various | ID | protein | H | TODO | 2026-04-07 | | |
| 698 | Tofu Firm (per 100g) | Various | JP | protein | H | TODO | 2026-04-07 | | |
| 699 | Edamame Shelled (per 100g) | Various | JP | protein | H | TODO | 2026-04-07 | | |
| 700 | Seitan (per 100g) | Various | CN | protein | H | TODO | 2026-04-07 | | |

## Section 24: International Rice, Grain & Staple Products (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 701 | Uncle Ben's Ready Rice Basmati | Uncle Ben's | US | staple | M | TODO | 2026-04-07 | | |
| 702 | Tilda Pure Basmati Rice (cooked per 100g) | Tilda | GB | staple | M | TODO | 2026-04-07 | | |
| 703 | Nishiki Sushi Rice (cooked per 100g) | Nishiki | JP | staple | M | TODO | 2026-04-07 | | |
| 704 | Daawat Basmati Rice (cooked per 100g) | Daawat | IN | staple | M | TODO | 2026-04-07 | | |
| 705 | Kohinoor Basmati Rice (cooked per 100g) | Kohinoor | IN | staple | M | TODO | 2026-04-07 | | |
| 706 | Quinoa Cooked (per 100g) | Various | PE | staple | H | TODO | 2026-04-07 | | |
| 707 | Couscous Cooked (per 100g) | Various | MA | staple | M | TODO | 2026-04-07 | | |
| 708 | Bulgur Wheat Cooked (per 100g) | Various | TR | staple | M | TODO | 2026-04-07 | | |
| 709 | Freekeh Cooked (per 100g) | Various | LB | staple | M | TODO | 2026-04-07 | | |
| 710 | Teff Grain Cooked (per 100g) | Various | ET | staple | M | TODO | 2026-04-07 | | |
| 711 | Polenta Cooked (per 100g) | Various | IT | staple | M | TODO | 2026-04-07 | | |
| 712 | Farro Cooked (per 100g) | Various | IT | staple | M | TODO | 2026-04-07 | | |
| 713 | Soba Noodles Cooked (per 100g) | Various | JP | staple | M | TODO | 2026-04-07 | | |
| 714 | Udon Noodles Cooked (per 100g) | Various | JP | staple | M | TODO | 2026-04-07 | | |
| 715 | Glass Noodles (Japchae) Cooked (per 100g) | Various | KR | staple | M | TODO | 2026-04-07 | | |
| 716 | Rice Noodles (Pho) Cooked (per 100g) | Various | VN | staple | M | TODO | 2026-04-07 | | |
| 717 | Ragi Malt (per serving) | Various | IN | staple | M | TODO | 2026-04-07 | | South Indian health drink |
| 718 | Jowar Roti (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |
| 719 | Bajra Roti (per piece) | Various | IN | bread | M | TODO | 2026-04-07 | | |
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
| 733 | Huel Hot & Savoury Thai Green Curry | Huel | GB | meal_replacement | M | TODO | 2026-04-07 | | |
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
| 744 | UCC Black Coffee Can | UCC | JP | beverage | M | TODO | 2026-04-07 | | |
| 745 | BOSS Coffee Rainbow Mountain | Suntory | JP | beverage | M | TODO | 2026-04-07 | | |
| 746 | Nescafe Gold Instant Coffee (per cup) | Nescafe | CH | beverage | M | TODO | 2026-04-07 | | |
| 747 | Bru Instant Coffee (per cup) | Bru | IN | beverage | M | TODO | 2026-04-07 | | India popular |
| 748 | Nescafe Classic (India per cup) | Nescafe | IN | beverage | M | TODO | 2026-04-07 | | |
| 749 | Filter Coffee (South Indian per cup) | Various | IN | beverage | H | TODO | 2026-04-07 | | With milk |
| 750 | Vietnamese Coffee Ca Phe Sua Da (per cup) | Various | VN | beverage | M | TODO | 2026-04-07 | | With condensed milk |
| 751 | Turkish Coffee (per cup) | Various | TR | beverage | M | TODO | 2026-04-07 | | |
| 752 | Greek Frappe Coffee (per cup) | Various | GR | beverage | M | TODO | 2026-04-07 | | |
| 753 | Costa Coffee RTD Latte Can | Costa | GB | beverage | M | TODO | 2026-04-07 | | |
| 754 | Illy RTD Cold Brew | Illy | IT | beverage | M | TODO | 2026-04-07 | | |
| 755 | Oatly Barista Oat Latte RTD | Oatly | SE | beverage | M | TODO | 2026-04-07 | | |

## Section 28: Fitness Supplements (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 756 | Creatine Monohydrate Optimum Nutrition (per 5g) | Optimum Nutrition | US | supplement | H | TODO | 2026-04-07 | | |
| 758 | Creatine HCl Kaged (per serving) | Kaged | US | supplement | M | TODO | 2026-04-07 | | |
| 759 | Pre-Workout C4 Original Fruit Punch (per serving) | C4 | US | supplement | M | TODO | 2026-04-07 | | |
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
| 772 | Chai Tea Latte (per serving prepared) | Various | IN | beverage | H | TODO | 2026-04-07 | | |
| 773 | Masala Chai (homemade per cup) | Various | IN | beverage | H | TODO | 2026-04-07 | | With milk & sugar |
| 774 | Tata Tea Gold (per cup brewed) | Tata | IN | beverage | M | TODO | 2026-04-07 | | |
| 775 | Wagh Bakri Instant Tea Premix (per sachet) | Wagh Bakri | IN | beverage | M | TODO | 2026-04-07 | | |
| 776 | Bubble Tea Taro Milk Tea (per 500ml) | Various | TW | beverage | H | TODO | 2026-04-07 | | |
| 777 | Bubble Tea Brown Sugar Boba Milk (per 500ml) | Various | TW | beverage | H | TODO | 2026-04-07 | | |
| 778 | Teh Tarik (Malaysian Pulled Tea per cup) | Various | MY | beverage | M | TODO | 2026-04-07 | | |
| 779 | Barley Tea (Mugicha per cup) | Various | JP | beverage | M | TODO | 2026-04-07 | | |
| 780 | Genmaicha (per cup) | Various | JP | beverage | L | TODO | 2026-04-07 | | |
| 781 | Yuzu Tea (Korean Yuja per cup) | Various | KR | beverage | M | TODO | 2026-04-07 | | |
| 782 | Chrysanthemum Tea (per cup) | Various | CN | beverage | L | TODO | 2026-04-07 | | |
| 783 | Hibiscus Tea Agua de Jamaica (per cup) | Various | MX | beverage | M | TODO | 2026-04-07 | | |
| 784 | Horchata (per cup) | Various | MX | beverage | M | TODO | 2026-04-07 | | |
| 785 | Atole de Chocolate (per cup) | Various | MX | beverage | M | TODO | 2026-04-07 | | |
| 786 | Kefir Plain (per 100ml) | Various | RU | beverage | H | TODO | 2026-04-07 | | |
| 787 | Kvass (per 250ml) | Various | RU | beverage | M | TODO | 2026-04-07 | | |
| 788 | Kombucha GT's Original (per bottle) | GT's | US | beverage | M | TODO | 2026-04-07 | | |
| 789 | Kombucha GT's Gingerade (per bottle) | GT's | US | beverage | M | TODO | 2026-04-07 | | |
| 790 | Turmeric Latte Golden Milk (per cup) | Various | IN | beverage | M | TODO | 2026-04-07 | | |

## Section 30: Fast Food International Chains (30 items)

| # | Food Name | Brand | Country | Restaurant | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|------------|----------|----------|--------|------------|----------------|-------|
| 792 | Jollibee Jolly Spaghetti | Jollibee | PH | Jollibee | fast_food | M | TODO | 2026-04-07 | | |
| 793 | Jollibee Yumburger | Jollibee | PH | Jollibee | fast_food | M | TODO | 2026-04-07 | | |
| 795 | Nando's Peri-Peri Chicken Thigh | Nando's | ZA | Nando's | fast_food | M | TODO | 2026-04-07 | | |
| 796 | Nando's Spicy Rice Side | Nando's | ZA | Nando's | fast_food | M | TODO | 2026-04-07 | | |
| 797 | Greggs Sausage Roll | Greggs | GB | Greggs | fast_food | H | TODO | 2026-04-07 | | UK icon |
| 798 | Greggs Vegan Sausage Roll | Greggs | GB | Greggs | fast_food | M | TODO | 2026-04-07 | | |
| 799 | Greggs Steak Bake | Greggs | GB | Greggs | fast_food | M | TODO | 2026-04-07 | | |
| 800 | Greggs Chicken Bake | Greggs | GB | Greggs | fast_food | M | TODO | 2026-04-07 | | |
| 801 | Wetherspoons Fish and Chips | Wetherspoons | GB | Wetherspoons | fast_food | M | TODO | 2026-04-07 | | |
| 802 | Leon Chargrilled Chicken Hot Box | Leon | GB | Leon | fast_food | M | TODO | 2026-04-07 | | |
| 803 | Itsu Chicken Gyoza (per 6) | Itsu | GB | Itsu | fast_food | M | TODO | 2026-04-07 | | |
| 805 | Tim Hortons Original Donut | Tim Hortons | CA | Tim Hortons | fast_food | M | TODO | 2026-04-07 | | |
| 806 | Tim Hortons Timbits (per piece) | Tim Hortons | CA | Tim Hortons | fast_food | M | TODO | 2026-04-07 | | |
| 807 | Harvey's Original Burger | Harvey's | CA | Harvey's | fast_food | M | TODO | 2026-04-07 | | |
| 808 | Mary Brown's Big Mary Chicken Sandwich | Mary Brown's | CA | Mary Brown's | fast_food | M | TODO | 2026-04-07 | | |
| 809 | Saravana Bhavan Mini Tiffin | Saravana Bhavan | IN | Saravana Bhavan | fast_food | M | TODO | 2026-04-07 | | Indian chain |
| 810 | A2B (Adyar Ananda Bhavan) Ghee Pongal | A2B | IN | A2B | fast_food | M | TODO | 2026-04-07 | | |
| 812 | Barbeque Nation Chicken Starter (per piece) | Barbeque Nation | IN | Barbeque Nation | fast_food | M | TODO | 2026-04-07 | | |
| 813 | Max Burgers Original (Sweden) | Max | SE | Max Burgers | fast_food | M | TODO | 2026-04-07 | | |
| 814 | Hesburger Cheese Burger (Finland) | Hesburger | FI | Hesburger | fast_food | M | TODO | 2026-04-07 | | |
| 815 | Mos Burger Rice Burger Yakiniku | Mos Burger | JP | Mos Burger | fast_food | M | TODO | 2026-04-07 | | |
| 816 | Yoshinoya Beef Bowl Regular | Yoshinoya | JP | Yoshinoya | fast_food | H | TODO | 2026-04-07 | | |
| 817 | CoCo Ichibanya Curry Rice Pork Cutlet | CoCo Ichibanya | JP | CoCo Ichibanya | fast_food | M | TODO | 2026-04-07 | | |
| 818 | Lotteria Teriyaki Burger | Lotteria | KR | Lotteria | fast_food | M | TODO | 2026-04-07 | | |
| 819 | BBQ Chicken Golden Original (Korea) | BBQ Chicken | KR | BBQ Chicken | fast_food | M | TODO | 2026-04-07 | | |
| 820 | Kyochon Honey Original Chicken (per piece) | Kyochon | KR | Kyochon | fast_food | H | TODO | 2026-04-07 | | Korean fried chicken |

## Section 31: Trending / Viral Foods (20 items)

| # | Food Name | Brand | Country | Restaurant | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|------------|----------|----------|--------|------------|----------------|-------|
| 821 | Dubai Chocolate Bar Fix Dessert Chocolatier | Fix Dessert | AE | | chocolate | H | TODO | 2026-04-07 | | Viral pistachio kunafa chocolate |
| 822 | Crumbl Cookie Chocolate Chip (per cookie) | Crumbl | US | Crumbl | dessert | H | TODO | 2026-04-07 | | Viral bakery chain |
| 823 | Crumbl Cookie Pink Sugar (per cookie) | Crumbl | US | Crumbl | dessert | M | TODO | 2026-04-07 | | |
| 824 | Crumbl Cookie Biscoff Lava (per cookie) | Crumbl | US | Crumbl | dessert | M | TODO | 2026-04-07 | | |
| 825 | Boba Guys Classic Milk Tea (per 16oz) | Boba Guys | US | Boba Guys | beverage | M | TODO | 2026-04-07 | | |
| 826 | Gong Cha Brown Sugar Milk Tea (per M) | Gong Cha | TW | Gong Cha | beverage | H | TODO | 2026-04-07 | | |
| 827 | Tiger Sugar Brown Sugar Boba (per M) | Tiger Sugar | TW | Tiger Sugar | beverage | H | TODO | 2026-04-07 | | |
| 828 | Xing Fu Tang Brown Sugar Boba | Xing Fu Tang | TW | Xing Fu Tang | beverage | M | TODO | 2026-04-07 | | |
| 829 | Insomnia Cookies Classic Chocolate Chunk (per cookie) | Insomnia Cookies | US | Insomnia Cookies | dessert | M | TODO | 2026-04-07 | | |
| 830 | Levain Bakery Chocolate Chip Walnut Cookie | Levain Bakery | US | Levain Bakery | dessert | M | TODO | 2026-04-07 | | |
| 831 | Biscoff Ice Cream Ben & Jerry's | Ben & Jerry's | US | | dessert | M | TODO | 2026-04-07 | | |
| 832 | Lotus Biscoff Ice Cream | Lotus | BE | | dessert | M | TODO | 2026-04-07 | | |
| 835 | Doritos Dinamita Chile Limon | Doritos | US | | snack | M | TODO | 2026-04-07 | | |
| 836 | Trader Joe's Everything But The Bagel Seasoning (per tsp) | Trader Joe's | US | | condiment | M | TODO | 2026-04-07 | | |
| 837 | Trader Joe's Cauliflower Gnocchi | Trader Joe's | US | | frozen_meal | M | TODO | 2026-04-07 | | |
| 838 | Trader Joe's Orange Chicken | Trader Joe's | US | | frozen_meal | M | TODO | 2026-04-07 | | |
| 839 | Costco Rotisserie Chicken (per 100g) | Kirkland | US | | protein | H | TODO | 2026-04-07 | | |
| 840 | Costco Kirkland Protein Bar Chocolate Brownie | Kirkland | US | | protein_bar | H | TODO | 2026-04-07 | | |

## Section 32: Australian & New Zealand Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 841 | Vegemite on Toast (per serve) | Bega | AU | breakfast | M | TODO | 2026-04-07 | | |
| 842 | Weet-Bix Original (per 2 biscuits) | Sanitarium | AU | cereal | H | TODO | 2026-04-07 | | Aus/NZ staple |
| 843 | Weet-Bix Protein (per 2 biscuits) | Sanitarium | AU | cereal | H | TODO | 2026-04-07 | | |
| 844 | Uncle Toby's Quick Oats (per serving) | Uncle Toby's | AU | cereal | M | TODO | 2026-04-07 | | |
| 845 | Farmers Union Iced Coffee | Farmers Union | AU | beverage | M | TODO | 2026-04-07 | | SA icon |
| 846 | Dare Iced Coffee Double Espresso | Dare | AU | beverage | M | TODO | 2026-04-07 | | |
| 847 | Bundaberg Ginger Beer | Bundaberg | AU | beverage | M | TODO | 2026-04-07 | | |
| 848 | Cherry Ripe Chocolate Bar | Cadbury | AU | chocolate | M | TODO | 2026-04-07 | | Aus exclusive |
| 849 | Violet Crumble Chocolate Bar | Robern Menz | AU | chocolate | M | TODO | 2026-04-07 | | |
| 850 | Meat Pie Four'N Twenty (per pie) | Four'N Twenty | AU | fast_food | H | TODO | 2026-04-07 | | Aus icon |
| 851 | Sausage Roll Four'N Twenty (per roll) | Four'N Twenty | AU | fast_food | M | TODO | 2026-04-07 | | |
| 852 | Lamington (per piece) | Various | AU | dessert | M | TODO | 2026-04-07 | | |
| 853 | Pavlova (per serving) | Various | NZ | dessert | M | TODO | 2026-04-07 | | |
| 854 | L&P Lemon & Paeroa Soda | L&P | NZ | beverage | M | TODO | 2026-04-07 | | NZ icon |
| 855 | Whittaker's Creamy Milk Chocolate | Whittaker's | NZ | chocolate | M | TODO | 2026-04-07 | | NZ top brand |
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
| 863 | Syrniki Cottage Cheese Pancakes (per piece) | Various | RU | breakfast | M | TODO | 2026-04-07 | | |
| 864 | Borscht (per serving) | Various | UA | soup | M | TODO | 2026-04-07 | | |
| 865 | Varenyky Ukrainian Dumplings (per 5 pieces) | Various | UA | snack | M | TODO | 2026-04-07 | | |
| 866 | Kvass Ochakovo (per 250ml) | Ochakovo | RU | beverage | M | TODO | 2026-04-07 | | |
| 867 | Zefir Russian Marshmallow (per piece) | Various | RU | confectionery | M | TODO | 2026-04-07 | | |
| 868 | Ptichye Moloko Bird's Milk Cake (per piece) | Various | RU | confectionery | M | TODO | 2026-04-07 | | |
| 869 | Alyonka Chocolate Bar | Kommunarka | RU | chocolate | M | TODO | 2026-04-07 | | Russian icon |
| 870 | Langos Hungarian Fried Bread (per piece) | Various | HU | bread | M | TODO | 2026-04-07 | | |
| 871 | Trdelnik Czech Chimney Cake (per piece) | Various | CZ | dessert | M | TODO | 2026-04-07 | | |
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
| 881 | Laksa (per serving) | Various | SG | noodle | M | TODO | 2026-04-07 | | |
| 882 | Kaya Toast Set (per serving) | Various | SG | breakfast | M | TODO | 2026-04-07 | | |
| 883 | Chili Crab Singapore (per serving) | Various | SG | protein | M | TODO | 2026-04-07 | | |
| 884 | Pad Thai (per serving) | Various | TH | noodle | H | TODO | 2026-04-07 | | |
| 885 | Som Tum Green Papaya Salad (per serving) | Various | TH | salad | M | TODO | 2026-04-07 | | |
| 886 | Tom Kha Gai (per serving) | Various | TH | soup | M | TODO | 2026-04-07 | | |
| 887 | Mango Sticky Rice (per serving) | Various | TH | dessert | M | TODO | 2026-04-07 | | |
| 888 | Pho Bo Vietnamese Beef (per serving) | Various | VN | noodle | H | TODO | 2026-04-07 | | |
| 889 | Banh Mi Pork (per sandwich) | Various | VN | fast_food | H | TODO | 2026-04-07 | | |
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
| 910 | Takoyaki (per 6 pieces) | Various | JP | snack | H | TODO | 2026-04-07 | | |
| 911 | Okonomiyaki (per serving) | Various | JP | snack | M | TODO | 2026-04-07 | | |
| 912 | Gyudon Beef Bowl (per serving) | Various | JP | fast_food | H | TODO | 2026-04-07 | | |
| 913 | Japanese Curry Rice (per serving) | Various | JP | fast_food | M | TODO | 2026-04-07 | | |
| 914 | Mochi Daifuku Red Bean (per piece) | Various | JP | dessert | M | TODO | 2026-04-07 | | |
| 915 | Matcha Kit Kat Mini (per piece) | Nestle | JP | chocolate | M | TODO | 2026-04-07 | | |

## Section 36: Korean Convenience Store & Street Food (15 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 916 | Tteokbokki Rice Cakes (per serving) | Various | KR | snack | H | TODO | 2026-04-07 | | |
| 917 | Korean Corn Dog (per piece) | Various | KR | snack | H | TODO | 2026-04-07 | | |
| 918 | Kimbap Classic (per roll) | Various | KR | snack | H | TODO | 2026-04-07 | | |
| 919 | Bibimbap (per serving) | Various | KR | rice | H | TODO | 2026-04-07 | | |
| 920 | Kimchi Jjigae (per serving) | Various | KR | soup | M | TODO | 2026-04-07 | | |
| 921 | Sundubu Jjigae (per serving) | Various | KR | soup | M | TODO | 2026-04-07 | | |
| 922 | Japchae Glass Noodles (per serving) | Various | KR | noodle | M | TODO | 2026-04-07 | | |
| 923 | Korean Fried Chicken (per piece) | Various | KR | protein | H | TODO | 2026-04-07 | | |
| 924 | Hotteok Sweet Pancake (per piece) | Various | KR | dessert | M | TODO | 2026-04-07 | | |
| 925 | Bingsu Patbingsu (per serving) | Various | KR | dessert | M | TODO | 2026-04-07 | | |
| 926 | Samgak Kimbap Triangle (per piece) | Various | KR | snack | M | TODO | 2026-04-07 | | Konbini |
| 928 | Soju Flavored Peach (per shot) | Various | KR | beverage | L | TODO | 2026-04-07 | | |
| 929 | Korean BBQ Samgyeopsal Pork Belly (per 100g) | Various | KR | protein | H | TODO | 2026-04-07 | | |
| 930 | Dakgangjeong Sweet Crispy Chicken (per 100g) | Various | KR | protein | M | TODO | 2026-04-07 | | |

## Section 37: Chinese Staples & Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 931 | Dim Sum Har Gow Shrimp Dumpling (per piece) | Various | CN | snack | H | TODO | 2026-04-07 | | |
| 932 | Dim Sum Siu Mai Pork Dumpling (per piece) | Various | CN | snack | H | TODO | 2026-04-07 | | |
| 933 | Char Siu BBQ Pork (per 100g) | Various | CN | protein | H | TODO | 2026-04-07 | | |
| 934 | Xiao Long Bao Soup Dumpling (per piece) | Various | CN | snack | H | TODO | 2026-04-07 | | |
| 935 | Jianbing Chinese Crepe (per piece) | Various | CN | breakfast | M | TODO | 2026-04-07 | | |
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
| 948 | Lee Kum Kee Hoisin Sauce (per tbsp) | Lee Kum Kee | HK | condiment | M | TODO | 2026-04-07 | | |
| 949 | Li Jinji Soy Sauce (per tbsp) | Lee Kum Kee | HK | condiment | M | TODO | 2026-04-07 | | |
| 950 | Vitasoy Soy Milk Chocolate (per 250ml) | Vitasoy | HK | beverage | M | TODO | 2026-04-07 | | |

## Section 38: Fitness Meal Prep Brands (20 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 951 | Freshly Steak Peppercorn | Freshly | US | meal_prep | M | TODO | 2026-04-07 | | |
| 952 | Freshly Chicken Pesto | Freshly | US | meal_prep | M | TODO | 2026-04-07 | | |
| 953 | Trifecta Organic Grass-Fed Beef | Trifecta | US | meal_prep | M | TODO | 2026-04-07 | | |
| 954 | Icon Meals Grilled Chicken & Rice | Icon Meals | US | meal_prep | M | TODO | 2026-04-07 | | |
| 955 | Muscle Meals 2 Go Chicken Stir Fry | Muscle Meals 2 Go | US | meal_prep | L | TODO | 2026-04-07 | | |
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
| 974 | Meiji Bulgaria Yogurt Plain | Meiji | JP | dairy | M | TODO | 2026-04-07 | | |
| 975 | Ajinomoto Gyoza Frozen (per 5 pieces) | Ajinomoto | JP | frozen_meal | M | TODO | 2026-04-07 | | |
| 976 | CJ Bibigo Mandu Dumplings (per 5 pieces) | CJ | KR | frozen_meal | H | TODO | 2026-04-07 | | |
| 977 | Ottogi Curry Mild (per serving) | Ottogi | KR | ready_meal | M | TODO | 2026-04-07 | | |
| 978 | Vita Plus Dalandan Juice (Philippines) | Vita Plus | PH | beverage | L | TODO | 2026-04-07 | | |
| 979 | Dutch Mill Yogurt Drink Strawberry | Dutch Mill | TH | dairy | M | TODO | 2026-04-07 | | |
| 980 | Vitamilk Soy Milk Original | Vitamilk | TH | beverage | M | TODO | 2026-04-07 | | |
| 981 | ABC Kecap Manis Sweet Soy Sauce (per tbsp) | ABC | ID | condiment | M | TODO | 2026-04-07 | | |
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
| 1002 | Mr. Iron Protein Bar Chocolate | Mr. Iron | EU | protein_bar | H | TODO | 2026-04-07 | | |
| 1003 | Nutrend Protein Bar | Nutrend | CZ | protein_bar | M | TODO | 2026-04-07 | | |
| 1004 | Nutrend Excelent Protein Bar Marzipan | Nutrend | CZ | protein_bar | M | TODO | 2026-04-07 | | |
| 1005 | QNT Protein Joy Bar Cookie Dough | QNT | BE | protein_bar | M | TODO | 2026-04-07 | | |
| 1006 | Amix Low-Carb Protein Bar 33% | Amix | CZ | protein_bar | M | TODO | 2026-04-07 | | |
| 1007 | Peak Punk Protein Bar Cacao Hazelnut | Peak Punk | CH | protein_bar | M | TODO | 2026-04-07 | | |
| 1008 | FAST Protein Bar Caramel | FAST | FI | protein_bar | M | TODO | 2026-04-07 | | |
| 1009 | Rawbite Protein Crunchy Almond | Rawbite | DK | protein_bar | M | TODO | 2026-04-07 | | |
| 1010 | Leader Protein Bar Chocolate | Leader | FI | protein_bar | M | TODO | 2026-04-07 | | |
| 1011 | NOCCO BCAA Focus Black Orange | NOCCO | SE | energy_drink | M | TODO | 2026-04-07 | | |
| 1012 | FITAID Energy Drink | FITAID | US | energy_drink | M | TODO | 2026-04-07 | | CrossFit popular |
| 1015 | Ryse Fuel Smarties | Ryse | US | energy_drink | M | TODO | 2026-04-07 | | |
| 1016 | Raw Nutrition CBUM Thavage Pre-Workout (per serving) | Raw Nutrition | US | supplement | M | TODO | 2026-04-07 | | |
| 1017 | 1st Phorm Level-1 Protein Chocolate | 1st Phorm | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1018 | Ryse Loaded Protein Cinnamon Toast | Ryse | US | protein_powder | M | TODO | 2026-04-07 | | |
| 1020 | G Fuel Energy Formula Blue Ice (per serving) | G Fuel | US | energy_drink | M | TODO | 2026-04-07 | | Gaming/fitness |
| 1021 | Snaq Fabriq Chocolate Bar | Snaq Fabriq | RU | protein_bar | M | TODO | 2026-04-07 | | Russian fitness brand |
| 1022 | Bombbar Protein Bar Chocolate | Bombbar | RU | protein_bar | M | TODO | 2026-04-07 | | Russian fitness brand |
| 1023 | MyProtein Protein Cookie Double Chocolate | MyProtein | GB | protein_snack | M | TODO | 2026-04-07 | | |
| 1024 | MyProtein Layered Protein Bar Cookies & Cream | MyProtein | GB | protein_bar | M | TODO | 2026-04-07 | | |
| 1025 | PhD Smart Plant Bar Choc Toffee Popcorn | PhD Nutrition | GB | protein_bar | M | TODO | 2026-04-07 | | Vegan |
| 1026 | Myprotein Vegan Protein Blend Chocolate | MyProtein | GB | protein_powder | M | TODO | 2026-04-07 | | |
| 1027 | Nutrabox Whey Protein Chocolate | Nutrabox | IN | protein_powder | M | TODO | 2026-04-07 | | Indian brand |
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
| 1035 | Tesco Finest Sourdough Bread (per slice) | Tesco | GB | bread | M | TODO | 2026-04-07 | | |
| 1036 | Sainsbury's Taste the Difference Chicken Tikka Masala | Sainsbury's | GB | ready_meal | M | TODO | 2026-04-07 | | |
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
| 1048 | Asda Extra Special Sourdough Pizza Margherita (per slice) | Asda | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1049 | Asda Smart Price Baked Beans | Asda | GB | staple | L | TODO | 2026-04-07 | | |
| 1050 | Aldi Brooklea Protein Yogurt Vanilla | Aldi UK | GB | dairy | H | TODO | 2026-04-07 | | |
| 1051 | Aldi Protein Bar Chocolate Orange | Aldi UK | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 1052 | Aldi Specially Selected Granola Berry | Aldi UK | GB | cereal | M | TODO | 2026-04-07 | | |
| 1053 | Lidl Milbona High Protein Yogurt Blueberry | Lidl | GB | dairy | H | TODO | 2026-04-07 | | |
| 1054 | Lidl Protein Bar Crispy Caramel | Lidl | GB | protein_bar | H | TODO | 2026-04-07 | | |
| 1055 | Lidl Deluxe Irish Butter (per 10g) | Lidl | GB | dairy | M | TODO | 2026-04-07 | | |
| 1056 | Myprotein Protein Bread Rolls (per roll) | MyProtein | GB | bread | H | TODO | 2026-04-07 | | |
| 1057 | The Skinny Food Co Not Guilty Low Cal Popcorn | Skinny Food Co | GB | snack | M | TODO | 2026-04-07 | | |
| 1058 | The Skinny Food Co Protein Bar Millionaire's Shortbread | Skinny Food Co | GB | protein_bar | M | TODO | 2026-04-07 | | |
| 1059 | Hartley's 10 Cal Jelly Strawberry | Hartley's | GB | dessert | H | TODO | 2026-04-07 | | Diet staple UK |
| 1060 | Batchelors Super Noodles Chicken | Batchelors | GB | instant_noodle | M | TODO | 2026-04-07 | | |
| 1061 | Pot Noodle Chicken & Mushroom | Pot Noodle | GB | instant_noodle | M | TODO | 2026-04-07 | | |
| 1062 | Nando's PERInaise Original (per tbsp) | Nando's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1063 | Heinz Baked Beans (UK per serving) | Heinz | GB | staple | H | TODO | 2026-04-07 | | UK breakfast staple |
| 1064 | HP Brown Sauce (per tbsp) | HP | GB | condiment | M | TODO | 2026-04-07 | | |
| 1065 | Branston Pickle (per tbsp) | Branston | GB | condiment | M | TODO | 2026-04-07 | | |
| 1066 | Hellmann's Light Mayo UK (per tbsp) | Hellmann's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1067 | Cathedral City Mature Cheddar (per 30g) | Cathedral City | GB | dairy | M | TODO | 2026-04-07 | | |
| 1068 | Cathedral City Lighter Cheddar (per 30g) | Cathedral City | GB | dairy | M | TODO | 2026-04-07 | | |
| 1069 | Babybel Mini Original (per piece) | Babybel | FR | dairy | M | TODO | 2026-04-07 | | |
| 1070 | Babybel Mini Light (per piece) | Babybel | FR | dairy | M | TODO | 2026-04-07 | | |
| 1071 | Fage Total 0% Plain | Fage | GR | dairy | H | TODO | 2026-04-07 | | Popular in UK/EU |
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
| 1092 | Weider Low Carb High Protein Bar Strawberry | Weider | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 1093 | Weider Low Carb High Protein Bar Chocolate | Weider | DE | protein_bar | M | TODO | 2026-04-07 | | |
| 1094 | Body Attack Power Protein 90 Chocolate | Body Attack | DE | protein_powder | M | TODO | 2026-04-07 | | |
| 1095 | More Nutrition Total Protein Chocolate Brownie | More Nutrition | DE | protein_powder | M | TODO | 2026-04-07 | | German fitness influencer brand |
| 1096 | More Nutrition Chunky Flavour Chocolate Chip Cookie Dough | More Nutrition | DE | supplement | M | TODO | 2026-04-07 | | Flavor powder |
| 1097 | Corny Protein Bar Chocolate Crunch | Corny | DE | protein_bar | M | TODO | 2026-04-07 | | |
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
| 1120 | FRoSTA Pasta Penne Arrabiata | FRoSTA | DE | frozen_meal | M | TODO | 2026-04-07 | | |
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
| 1142 | Pizza Hut Stuffed Crust Pizza Pepperoni (per slice) | Pizza Hut | US | Pizza Hut | fast_food | M | TODO | 2026-04-07 | | |
| 1143 | Domino's Peppy Paneer Pizza India (per slice) | Domino's | IN | Domino's | fast_food | H | TODO | 2026-04-07 | | India #1 pizza |
| 1144 | Domino's Burger Pizza India (per slice) | Domino's | IN | Domino's | fast_food | M | TODO | 2026-04-07 | | |
| 1145 | Pizza Hut Birizza (India) | Pizza Hut | IN | Pizza Hut | fast_food | M | TODO | 2026-04-07 | | Biryani pizza |
| 1146 | Subway 6-inch Turkey Breast | Subway | US | Subway | fast_food | H | TODO | 2026-04-07 | | |
| 1147 | Subway 6-inch Chicken Teriyaki | Subway | US | Subway | fast_food | M | TODO | 2026-04-07 | | |
| 1148 | Subway Paneer Tikka Sub (India 6-inch) | Subway | IN | Subway | fast_food | M | TODO | 2026-04-07 | | |
| 1149 | Paris Baguette Garlic Cream Cheese Bread (per piece) | Paris Baguette | KR | Paris Baguette | bakery | H | TODO | 2026-04-07 | | |
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
| 1166 | Hawker Chan Soy Sauce Chicken Rice (per plate) | Hawker Chan | SG | Hawker Chan | fast_food | M | TODO | 2026-04-07 | | Michelin starred |
| 1167 | Ya Kun Kaya Toast Set (per serving) | Ya Kun | SG | Ya Kun | breakfast | M | TODO | 2026-04-07 | | |
| 1168 | Old Chang Kee Curry Puff (per piece) | Old Chang Kee | SG | Old Chang Kee | snack | M | TODO | 2026-04-07 | | |
| 1169 | A&W Root Beer Float (Malaysia) | A&W | MY | A&W | beverage | M | TODO | 2026-04-07 | | |
| 1170 | Secret Recipe Chocolate Indulgence Cake (per slice) | Secret Recipe | MY | Secret Recipe | dessert | M | TODO | 2026-04-07 | | |
| 1171 | Ramly Burger Original (per burger) | Ramly | MY | Various | fast_food | H | TODO | 2026-04-07 | | Malaysian street food icon |
| 1172 | Mamak Roti Canai Telur (per piece) | Various | MY | Various | bread | M | TODO | 2026-04-07 | | |
| 1173 | CoCo Fresh Tea & Juice Bubble Milk Tea (per M) | CoCo | TW | CoCo | beverage | H | TODO | 2026-04-07 | | |
| 1174 | The Alley Brown Sugar Deerioca Milk (per M) | The Alley | TW | The Alley | beverage | M | TODO | 2026-04-07 | | |
| 1175 | Saladstop! Protein Power Bowl | Saladstop! | SG | Saladstop! | salad | M | TODO | 2026-04-07 | | |
| 1176 | Subway India Aloo Patty Sub (6-inch) | Subway | IN | Subway | fast_food | M | TODO | 2026-04-07 | | |
| 1177 | WOK to WALK Chicken Teriyaki Noodles | WOK to WALK | NL | WOK to WALK | fast_food | M | TODO | 2026-04-07 | | |
| 1178 | Paul French Bakery Pain au Raisin (per piece) | Paul | FR | Paul | bakery | M | TODO | 2026-04-07 | | |
| 1179 | Gail's Bakery Cinnamon Bun (per piece) | Gail's | GB | Gail's | bakery | M | TODO | 2026-04-07 | | |
| 1180 | EAT. Chicken Caesar Wrap | EAT. | GB | EAT. | fast_food | M | TODO | 2026-04-07 | | |
| 1181 | Pret a Manger Protein Power Pot | Pret | GB | Pret a Manger | fast_food | H | TODO | 2026-04-07 | | |
| 1182 | Pret a Manger Chicken & Avocado Sandwich | Pret | GB | Pret a Manger | fast_food | M | TODO | 2026-04-07 | | |
| 1183 | Pret a Manger Coconut Chicken Soup | Pret | GB | Pret a Manger | soup | M | TODO | 2026-04-07 | | |
| 1184 | Franco Manca Pizza Margherita (per pizza) | Franco Manca | GB | Franco Manca | fast_food | M | TODO | 2026-04-07 | | |
| 1185 | Tortilla Chicken Burrito | Tortilla | GB | Tortilla | fast_food | M | TODO | 2026-04-07 | | |
| 1186 | Wahaca Chicken Burrito | Wahaca | GB | Wahaca | fast_food | M | TODO | 2026-04-07 | | |
| 1187 | Wagamama Chicken Katsu Curry | Wagamama | GB | Wagamama | fast_food | H | TODO | 2026-04-07 | | |
| 1188 | Wagamama Chicken Ramen | Wagamama | GB | Wagamama | fast_food | M | TODO | 2026-04-07 | | |
| 1189 | Nando's Chicken Butterfly Breast | Nando's | GB | Nando's | fast_food | H | TODO | 2026-04-07 | | Different from ZA |
| 1190 | Nando's Macho Peas | Nando's | GB | Nando's | fast_food | M | TODO | 2026-04-07 | | |

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
| 1201 | Catch Italian Seasoning (per tsp) | Catch | IN | condiment | L | TODO | 2026-04-07 | | |
| 1202 | Eastern Sambar Powder (per tsp) | Eastern | IN | condiment | M | TODO | 2026-04-07 | | South Indian brand |
| 1203 | Aachi Chicken 65 Masala (per tsp) | Aachi | IN | condiment | M | TODO | 2026-04-07 | | |
| 1204 | Amul Lassi Rose (per 200ml) | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 1205 | Amul Kool Cafe (per 200ml) | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 1206 | Amul Tru Seltzer (per can) | Amul | IN | beverage | M | TODO | 2026-04-07 | | |
| 1207 | Nandini Curd (per 100g) | Nandini | IN | dairy | M | TODO | 2026-04-07 | | Karnataka brand |
| 1208 | Aavin Milk Full Cream (per 250ml) | Aavin | IN | dairy | M | TODO | 2026-04-07 | | Tamil Nadu brand |
| 1209 | Milma Curd (per 100g) | Milma | IN | dairy | M | TODO | 2026-04-07 | | Kerala brand |
| 1210 | Verka Lassi Sweet (per 200ml) | Verka | IN | beverage | M | TODO | 2026-04-07 | | Punjab brand |
| 1211 | Keventers Milkshake Chocolate (per bottle) | Keventers | IN | beverage | M | TODO | 2026-04-07 | | |
| 1212 | Raw Pressery Cold Pressed OJ (per bottle) | Raw Pressery | IN | beverage | M | TODO | 2026-04-07 | | |
| 1213 | Epigamia Protein Shake Chocolate (per bottle) | Epigamia | IN | protein_drink | H | TODO | 2026-04-07 | | |
| 1214 | Swiggy Instamart House Brand Paneer (per 100g) | Swiggy | IN | dairy | M | TODO | 2026-04-07 | | |
| 1215 | BigBasket Fresho Chicken Breast (per 100g) | BigBasket | IN | protein | M | TODO | 2026-04-07 | | |
| 1216 | Licious Chicken Breast Boneless (per 100g) | Licious | IN | protein | H | TODO | 2026-04-07 | | India meat delivery |
| 1217 | FreshToHome Fish Seer Fish Fillet (per 100g) | FreshToHome | IN | protein | M | TODO | 2026-04-07 | | |
| 1218 | ITC Aashirvaad Atta Pizza Base (per base) | ITC | IN | bread | M | TODO | 2026-04-07 | | |
| 1219 | ITC Sunfeast YiPPee Power Up Atta Noodles | ITC | IN | instant_noodle | M | TODO | 2026-04-07 | | |
| 1220 | Cadbury Bournville Dark Chocolate Rich Cocoa | Cadbury | IN | chocolate | M | TODO | 2026-04-07 | | |
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
| 1234 | Kitchen of India Butter Chicken (per serving) | Kitchen of India | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1235 | Kohinoor Ready to Eat Rajma Chawal (per serving) | Kohinoor | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1236 | Bikanervala Cham Cham (per piece) | Bikanervala | IN | dessert | M | TODO | 2026-04-07 | | |
| 1237 | K.C. Das Rosogolla (per piece) | K.C. Das | IN | dessert | M | TODO | 2026-04-07 | | Bengal iconic |
| 1238 | Naturals Ice Cream Tender Coconut (per scoop) | Naturals | IN | dessert | M | TODO | 2026-04-07 | | |
| 1239 | Baskin Robbins India Mississippi Mud (per scoop) | Baskin Robbins | IN | dessert | M | TODO | 2026-04-07 | | |
| 1240 | Havmor Cornetto Disc (per piece) | Havmor | IN | dessert | M | TODO | 2026-04-07 | | Gujarat brand |
| 1241 | Kwality Walls Feast Chocolate (per bar) | Kwality Walls | IN | dessert | M | TODO | 2026-04-07 | | |
| 1242 | Wagh Bakri Instant Masala Tea (per sachet) | Wagh Bakri | IN | beverage | M | TODO | 2026-04-07 | | |
| 1243 | Chai Point Masala Chai (per cup) | Chai Point | IN | beverage | M | TODO | 2026-04-07 | | Indian tea chain |
| 1244 | Third Wave Coffee Flat White (per cup) | Third Wave | IN | beverage | M | TODO | 2026-04-07 | | |
| 1245 | Blue Tokai Cold Brew (per bottle) | Blue Tokai | IN | beverage | M | TODO | 2026-04-07 | | |
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
| 1257 | Meiji R-1 Yogurt Drink (per bottle) | Meiji | JP | dairy | M | TODO | 2026-04-07 | | |
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
| 1272 | Suntory Iyemon Green Tea (per 500ml) | Suntory | JP | beverage | M | TODO | 2026-04-07 | | |
| 1273 | Kirin Afternoon Tea Milk Tea (per 500ml) | Kirin | JP | beverage | M | TODO | 2026-04-07 | | |
| 1274 | Itoen Oi Ocha Green Tea (per 500ml) | Itoen | JP | beverage | M | TODO | 2026-04-07 | | |
| 1275 | Asahi Mitsuya Cider (per can) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | Japan iconic soda |
| 1276 | Calpico Soda (per can) | Asahi | JP | beverage | M | TODO | 2026-04-07 | | |
| 1277 | Sapporo Ichiban Miso Ramen | Sapporo Ichiban | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 1278 | Myojo Charumera Soy Sauce | Myojo | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 1279 | Cup Noodle Curry (Japan) | Nissin | JP | instant_noodle | M | TODO | 2026-04-07 | | Different from US |
| 1280 | Peyoung Yakisoba (per pack) | Maruka | JP | instant_noodle | M | TODO | 2026-04-07 | | |
| 1281 | CU Convenience Store Triangle Kimbap (per piece) | CU | KR | snack | H | TODO | 2026-04-07 | | Korean konbini |
| 1282 | GS25 Chicken Breast Salad | GS25 | KR | protein | H | TODO | 2026-04-07 | | Korean konbini |
| 1283 | Emart24 Protein Drink (per bottle) | Emart24 | KR | protein_drink | M | TODO | 2026-04-07 | | |
| 1284 | Pulmuone Tofu Extra Firm (per 100g) | Pulmuone | KR | protein | M | TODO | 2026-04-07 | | |
| 1285 | CJ CheilJedang Hetbahn Rice (per pack) | CJ | KR | staple | M | TODO | 2026-04-07 | | Instant rice |
| 1286 | Dongwon Tuna Can (per can) | Dongwon | KR | protein | M | TODO | 2026-04-07 | | Korea #1 tuna |
| 1287 | Sempio Soy Sauce (per tbsp) | Sempio | KR | condiment | M | TODO | 2026-04-07 | | |
| 1288 | Beksul Frying Mix (per serving) | CJ | KR | staple | L | TODO | 2026-04-07 | | |
| 1289 | Nongshim Onion Rings (per 100g) | Nongshim | KR | snack | M | TODO | 2026-04-07 | | |
| 1290 | Crown Choco Heim (per piece) | Crown | KR | biscuit | M | TODO | 2026-04-07 | | |
| 1291 | Lotte Mon Cher Cream Cake (per piece) | Lotte | KR | biscuit | M | TODO | 2026-04-07 | | |
| 1292 | Haitai Ace Crackers (per serving) | Haitai | KR | biscuit | M | TODO | 2026-04-07 | | |
| 1293 | Maxim Original Mix Coffee (per stick) | Dongsuh | KR | beverage | M | TODO | 2026-04-07 | | Korea #1 instant coffee |
| 1294 | Starbucks Korea RTD Latte (per can) | Starbucks | KR | beverage | M | TODO | 2026-04-07 | | |
| 1295 | Jeju Hallabong Orange Juice (per 250ml) | Various | KR | beverage | M | TODO | 2026-04-07 | | |
| 1296 | Yakult Korea Light (per bottle) | Yakult | KR | beverage | M | TODO | 2026-04-07 | | |
| 1297 | Bodeum Protein Bar Sweet Potato | Bodeum | KR | protein_bar | M | TODO | 2026-04-07 | | Korean fitness brand |
| 1298 | Muscle King Protein Drink (per bottle) | Muscle King | KR | protein_drink | M | TODO | 2026-04-07 | | |
| 1299 | hy Protein Yogurt (per 100g) | hy | KR | dairy | M | TODO | 2026-04-07 | | Korean dairy brand |
| 1300 | Seoul Milk Low Fat (per 200ml) | Seoul Milk | KR | dairy | M | TODO | 2026-04-07 | | |
| 1301 | Nongshim Veggie Garden Chips | Nongshim | KR | snack | M | TODO | 2026-04-07 | | |
| 1302 | Ottogi Real Cheese Ramen | Ottogi | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 1303 | Paldo Kokomen Spicy Chicken | Paldo | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 1304 | Samyang Carbo Buldak Ramen | Samyang | KR | instant_noodle | M | TODO | 2026-04-07 | | |
| 1305 | Three Squirrels Mixed Nuts (per 30g) | Three Squirrels | CN | snack | M | TODO | 2026-04-07 | | China #1 snack brand |
| 1306 | Bestore Dried Mango (per 100g) | Bestore | CN | snack | M | TODO | 2026-04-07 | | |
| 1307 | Nongfu Spring Water (per 500ml) | Nongfu | CN | beverage | L | TODO | 2026-04-07 | | China #1 water |
| 1308 | Genki Forest Sparkling Water Peach (per can) | Genki Forest | CN | beverage | H | TODO | 2026-04-07 | | Zero cal trending |
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
| 1317 | Ichitan Green Tea Original (per bottle) | Ichitan | TH | beverage | M | TODO | 2026-04-07 | | |
| 1318 | Oishi Green Tea Honey Lemon (per bottle) | Oishi | TH | beverage | M | TODO | 2026-04-07 | | |
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
| 1335 | Jollibee Burger Steak (Philippines) | Jollibee | PH | fast_food | M | TODO | 2026-04-07 | | |
| 1336 | Lucky Me Instant Pancit Canton Original | Lucky Me | PH | instant_noodle | H | TODO | 2026-04-07 | | Philippines #1 |
| 1337 | Lucky Me Hot Chili Beef | Lucky Me | PH | instant_noodle | M | TODO | 2026-04-07 | | |
| 1338 | C2 Apple Green Tea (per 500ml) | C2 | PH | beverage | M | TODO | 2026-04-07 | | |
| 1339 | Zesto Juice Orange (per pack) | Zesto | PH | beverage | M | TODO | 2026-04-07 | | |
| 1340 | Alaska Evaporated Milk (per serving) | Alaska | PH | dairy | M | TODO | 2026-04-07 | | |
| 1341 | Piattos Cheese (per 100g) | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 1342 | V-Cut BBQ Chips (per 100g) | Jack n Jill | PH | snack | M | TODO | 2026-04-07 | | |
| 1343 | Gardenia White Bread (per slice) | Gardenia | MY | bread | M | TODO | 2026-04-07 | | SE Asia bread leader |
| 1344 | Maggi Mee Goreng (Malaysia) | Maggi | MY | instant_noodle | H | TODO | 2026-04-07 | | Malaysia variant |
| 1345 | Cintan Mi Goreng Asli | Cintan | MY | instant_noodle | M | TODO | 2026-04-07 | | |
| 1346 | Dutch Lady Milk Full Cream (per 200ml) | Dutch Lady | MY | dairy | M | TODO | 2026-04-07 | | |
| 1347 | Yeo's Soy Milk (per 250ml) | Yeo's | MY | beverage | M | TODO | 2026-04-07 | | |
| 1348 | F&N Orange (per can) | F&N | MY | beverage | M | TODO | 2026-04-07 | | |
| 1349 | Mister Potato Crisps Original (per 100g) | Mister Potato | MY | snack | M | TODO | 2026-04-07 | | |
| 1350 | MYPROTEIN Malaysia Chicken Breast Strips (per 100g) | MyProtein | MY | protein | M | TODO | 2026-04-07 | | |
| 1351 | Ayam Brand Sardines in Tomato Sauce (per can) | Ayam Brand | SG | protein | M | TODO | 2026-04-07 | | |
| 1352 | Pokka Green Tea Jasmine (per can) | Pokka | SG | beverage | M | TODO | 2026-04-07 | | |
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
| 1373 | Tat Tomato Paste Salça (per tbsp) | Tat | TR | condiment | M | TODO | 2026-04-07 | | |
| 1374 | Nescafe 3in1 (Turkey per sachet) | Nescafe | TR | beverage | M | TODO | 2026-04-07 | | |
| 1375 | Almarai Protein Milk Drink Chocolate | Almarai | SA | protein_drink | H | TODO | 2026-04-07 | | |
| 1376 | Almarai Greek Yogurt Plain | Almarai | SA | dairy | M | TODO | 2026-04-07 | | |
| 1377 | Almarai Croissant Zaatar (per piece) | Almarai | SA | bread | M | TODO | 2026-04-07 | | |
| 1378 | Al Rabie Juice Mango (per 200ml) | Al Rabie | SA | beverage | M | TODO | 2026-04-07 | | |
| 1379 | SADAFCO Saudia UHT Milk (per 200ml) | SADAFCO | SA | dairy | M | TODO | 2026-04-07 | | |
| 1380 | Al Marai Date Khalas (per 3 pieces) | Almarai | SA | confectionery | M | TODO | 2026-04-07 | | |
| 1381 | Americana Chicken Nuggets (per 5 pieces) | Americana | AE | frozen_meal | M | TODO | 2026-04-07 | | Gulf region brand |
| 1382 | Al Ain Water (per 500ml) | Al Ain | AE | beverage | L | TODO | 2026-04-07 | | |
| 1383 | Rani Float Mango (per can) | Aujan | AE | beverage | M | TODO | 2026-04-07 | | Middle East icon |
| 1384 | Tang Orange Powder (per serving) | Tang | AE | beverage | M | TODO | 2026-04-07 | | Huge in ME |
| 1385 | Indomie Special Chicken (Middle East variant) | Indomie | AE | instant_noodle | M | TODO | 2026-04-07 | | |
| 1386 | Al Fakher Maamoul (per piece) | Al Fakher | AE | biscuit | M | TODO | 2026-04-07 | | |
| 1387 | Kiri Cheese Spread (per portion) | Kiri | FR | dairy | M | TODO | 2026-04-07 | | Huge in ME |
| 1388 | La Vache qui Rit Cheese Wedge (per piece) | La Vache qui Rit | FR | dairy | M | TODO | 2026-04-07 | | Laughing Cow |
| 1389 | Puck Labneh (per tbsp) | Puck | DK | dairy | M | TODO | 2026-04-07 | | Popular in Gulf |
| 1390 | Puck Cream Cheese (per tbsp) | Puck | DK | dairy | M | TODO | 2026-04-07 | | |
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
| 1401 | Sellou Moroccan Energy Balls (per piece) | Various | MA | confectionery | M | TODO | 2026-04-07 | | |
| 1402 | Harira Moroccan Soup (per serving) | Various | MA | soup | M | TODO | 2026-04-07 | | |
| 1403 | Brik Tunisian Pastry (per piece) | Various | TN | snack | M | TODO | 2026-04-07 | | |
| 1404 | Mahalabia Middle Eastern Milk Pudding (per serving) | Various | EG | dessert | M | TODO | 2026-04-07 | | |
| 1405 | Basbousa Semolina Cake (per piece) | Various | EG | dessert | M | TODO | 2026-04-07 | | |
| 1406 | Ful Medames Canned (per serving) | Various | EG | staple | M | TODO | 2026-04-07 | | Egyptian breakfast |
| 1407 | Koshari (per serving) | Various | EG | staple | H | TODO | 2026-04-07 | | Egypt national dish |
| 1408 | Shakshuka (per serving) | Various | IL | breakfast | H | TODO | 2026-04-07 | | |
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
| 1437 | Marabou Milk Chocolate (per 100g) | Marabou | SE | chocolate | M | TODO | 2026-04-07 | | Swedish icon |
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
| 1473 | Bimbo White Bread (per slice) | Bimbo | MX | bread | M | TODO | 2026-04-07 | | |
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
| 1486 | Encebollado Ecuadorian Fish Soup (per serving) | Various | EC | soup | M | TODO | 2026-04-07 | | |
| 1487 | Ceviche Peruano (per serving) | Various | PE | protein | H | TODO | 2026-04-07 | | |
| 1488 | Lomo Saltado (per serving) | Various | PE | protein | M | TODO | 2026-04-07 | | |
| 1489 | Anticucho de Corazón (per stick) | Various | PE | protein | M | TODO | 2026-04-07 | | |
| 1490 | Causa Limeña (per serving) | Various | PE | snack | M | TODO | 2026-04-07 | | |
| 1491 | Pastel de Nata Portuguese Egg Tart (per piece) | Various | PT | dessert | H | TODO | 2026-04-07 | | |
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
| 1502 | Koo Baked Beans (per serving) | Koo | ZA | staple | M | TODO | 2026-04-07 | | SA icon |
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
| 1515 | Kilishi Nigerian Beef Jerky (per 100g) | Various | NG | protein_snack | M | TODO | 2026-04-07 | | |
| 1516 | Egusi Soup (per serving) | Various | NG | soup | M | TODO | 2026-04-07 | | |
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
| 1527 | Shiro Wot Ethiopian Chickpea Stew (per serving) | Various | ET | protein | M | TODO | 2026-04-07 | | |
| 1528 | Kitfo Ethiopian Tartare (per serving) | Various | ET | protein | M | TODO | 2026-04-07 | | |
| 1529 | Bunna Ethiopian Coffee (per cup) | Various | ET | beverage | M | TODO | 2026-04-07 | | |
| 1530 | Thieboudienne Senegalese Fish Rice (per serving) | Various | SN | protein | M | TODO | 2026-04-07 | | |
| 1531 | Fufu West African (per serving) | Various | GH | staple | M | TODO | 2026-04-07 | | |
| 1532 | Kelewele Ghanaian Fried Plantain (per serving) | Various | GH | snack | M | TODO | 2026-04-07 | | |
| 1533 | Waakye Ghanaian Rice & Beans (per serving) | Various | GH | staple | M | TODO | 2026-04-07 | | |
| 1534 | Bobotie South African (per serving) | Various | ZA | protein | M | TODO | 2026-04-07 | | |
| 1535 | Koeksister (per piece) | Various | ZA | dessert | M | TODO | 2026-04-07 | | SA braided donut |
| 1536 | Melktert Milk Tart (per slice) | Various | ZA | dessert | M | TODO | 2026-04-07 | | |
| 1537 | Piri Piri Chicken Mozambique (per piece) | Various | MZ | protein | M | TODO | 2026-04-07 | | |
| 1538 | Zanzibar Pizza (per piece) | Various | TZ | snack | M | TODO | 2026-04-07 | | |
| 1539 | Brochette Rwandan Grilled Meat (per stick) | Various | RW | protein | M | TODO | 2026-04-07 | | |
| 1540 | Rolex Uganda Egg Chapati Roll (per piece) | Various | UG | fast_food | M | TODO | 2026-04-07 | | |

## Section 51: More Fitness & Health Brands (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1541 | Grenade Protein Shake Chocolate (RTD) | Grenade | GB | protein_drink | H | TODO | 2026-04-07 | | |
| 1542 | Grenade Carb Killa Spread White Chocolate (per tbsp) | Grenade | GB | spread | M | TODO | 2026-04-07 | | |
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
| 1559 | Vital Proteins Collagen Peptides (per scoop) | Vital Proteins | US | supplement | H | TODO | 2026-04-07 | | |
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
| 1590 | Orgain Organic Protein Bar Chocolate Chip Cookie Dough | Orgain | US | protein_bar | M | TODO | 2026-04-07 | | |

## Section 52: International Dairy & Cheese Brands (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1591 | Philadelphia Cream Cheese Original (per tbsp) | Philadelphia | US | dairy | M | TODO | 2026-04-07 | | |
| 1592 | Philadelphia Light Cream Cheese (per tbsp) | Philadelphia | US | dairy | M | TODO | 2026-04-07 | | |
| 1593 | Boursin Garlic & Fine Herbs (per 30g) | Boursin | FR | dairy | M | TODO | 2026-04-07 | | |
| 1594 | Président Brie (per 30g) | Président | FR | dairy | M | TODO | 2026-04-07 | | |
| 1595 | Laughing Cow Light (per wedge) | La Vache qui Rit | FR | dairy | M | TODO | 2026-04-07 | | |
| 1596 | Galbani Fresh Mozzarella (per 100g) | Galbani | IT | dairy | M | TODO | 2026-04-07 | | |
| 1597 | Mascarpone Galbani (per tbsp) | Galbani | IT | dairy | M | TODO | 2026-04-07 | | |
| 1598 | Leerdammer Cheese (per slice) | Leerdammer | NL | dairy | M | TODO | 2026-04-07 | | |
| 1599 | Emmental Cheese (per 30g) | Various | CH | dairy | M | TODO | 2026-04-07 | | |
| 1600 | Gruyère Cheese (per 30g) | Various | CH | dairy | M | TODO | 2026-04-07 | | |
| 1601 | Paneer Amul Fresh (per 100g) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 1602 | Cottage Cheese Amul (per 100g) | Amul | IN | dairy | M | TODO | 2026-04-07 | | |
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
| 1615 | Cimory Yogurt Drink Strawberry (per bottle) | Cimory | ID | dairy | M | TODO | 2026-04-07 | | |
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
| 1626 | Liberte Greek Yogurt Plain (per 100g) | Liberte | CA | dairy | M | TODO | 2026-04-07 | | |
| 1627 | Olympic Krema Greek Yogurt (per 100g) | Olympic | CA | dairy | M | TODO | 2026-04-07 | | |
| 1628 | Jalna Pot Set Yoghurt (per 100g) | Jalna | AU | dairy | M | TODO | 2026-04-07 | | |
| 1629 | Chobani Flip Almond Coco Loco (per pot) | Chobani | AU | dairy | M | TODO | 2026-04-07 | | Australia variant |
| 1630 | Lewis Road Creamery Chocolate Milk (per 250ml) | Lewis Road | NZ | dairy | M | TODO | 2026-04-07 | | NZ cult product |

## Section 53: International Sauces, Pastes & Cooking Ingredients (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1631 | S&B Golden Curry Sauce Mix (per serving) | S&B | JP | condiment | M | TODO | 2026-04-07 | | Japanese curry block |
| 1632 | House Vermont Curry Medium (per serving) | House | JP | condiment | M | TODO | 2026-04-07 | | |
| 1633 | Kikkoman Soy Sauce (per tbsp) | Kikkoman | JP | condiment | H | TODO | 2026-04-07 | | |
| 1634 | Yamasa Soy Sauce (per tbsp) | Yamasa | JP | condiment | M | TODO | 2026-04-07 | | |
| 1635 | Mirin Hon (per tbsp) | Various | JP | condiment | M | TODO | 2026-04-07 | | |
| 1636 | Rice Vinegar (per tbsp) | Various | JP | condiment | L | TODO | 2026-04-07 | | |
| 1637 | Ottogi Sesame Oil (per tbsp) | Ottogi | KR | condiment | M | TODO | 2026-04-07 | | |
| 1638 | CJ Gochugaru Korean Chili Flakes (per tbsp) | CJ | KR | condiment | M | TODO | 2026-04-07 | | |
| 1639 | Sriracha Huy Fong Original (per tsp) | Huy Fong | US | condiment | H | TODO | 2026-04-07 | | |
| 1640 | Mae Ploy Sweet Chili Sauce (per tbsp) | Mae Ploy | TH | condiment | M | TODO | 2026-04-07 | | |
| 1641 | Mae Ploy Green Curry Paste (per tbsp) | Mae Ploy | TH | condiment | M | TODO | 2026-04-07 | | |
| 1642 | Mae Ploy Red Curry Paste (per tbsp) | Mae Ploy | TH | condiment | M | TODO | 2026-04-07 | | |
| 1643 | Cock Brand Oyster Sauce (per tbsp) | Cock Brand | TH | condiment | M | TODO | 2026-04-07 | | |
| 1644 | Squid Brand Fish Sauce (per tbsp) | Squid Brand | TH | condiment | M | TODO | 2026-04-07 | | |
| 1645 | Maggi Seasoning Sauce (per tsp) | Maggi | DE | condiment | M | TODO | 2026-04-07 | | German Maggi different from Asian |
| 1646 | Knorr Aromat Seasoning (per tsp) | Knorr | ZA | condiment | M | TODO | 2026-04-07 | | SA staple |
| 1647 | Chimichurri Sauce (per tbsp) | Various | AR | condiment | M | TODO | 2026-04-07 | | |
| 1648 | Ají Amarillo Paste (per tbsp) | Various | PE | condiment | M | TODO | 2026-04-07 | | |
| 1649 | Harissa Paste (per tbsp) | Various | TN | condiment | M | TODO | 2026-04-07 | | |
| 1650 | Berbere Spice Mix (per tsp) | Various | ET | condiment | M | TODO | 2026-04-07 | | |
| 1651 | Ras el Hanout (per tsp) | Various | MA | condiment | M | TODO | 2026-04-07 | | |
| 1652 | Zhug Green Hot Sauce (per tbsp) | Various | YE | condiment | M | TODO | 2026-04-07 | | |
| 1653 | Ajvar Red Pepper Relish (per tbsp) | Various | RS | condiment | M | TODO | 2026-04-07 | | Balkan staple |
| 1654 | Tkemali Georgian Plum Sauce (per tbsp) | Various | GE | condiment | M | TODO | 2026-04-07 | | |
| 1655 | Adjika Georgian Chili Paste (per tsp) | Various | GE | condiment | M | TODO | 2026-04-07 | | |
| 1656 | Mango Chutney Patak's (per tbsp) | Patak's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1657 | Lime Pickle Patak's (per tbsp) | Patak's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1658 | Tikka Masala Paste Patak's (per tbsp) | Patak's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1659 | Nando's Garlic PERInaise (per tbsp) | Nando's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1660 | Henderson's Relish (per tbsp) | Henderson's | GB | condiment | M | TODO | 2026-04-07 | | Sheffield staple |
| 1661 | Colman's English Mustard (per tsp) | Colman's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1662 | Hellmann's Vegan Mayo (per tbsp) | Hellmann's | GB | condiment | M | TODO | 2026-04-07 | | |
| 1663 | Dijon Mustard Maille (per tsp) | Maille | FR | condiment | M | TODO | 2026-04-07 | | |
| 1664 | Pesto alla Genovese Barilla (per tbsp) | Barilla | IT | condiment | M | TODO | 2026-04-07 | | |
| 1665 | Pomì Passata Tomato Sauce (per 100g) | Pomì | IT | condiment | M | TODO | 2026-04-07 | | |
| 1666 | Ketchup Heinz (per tbsp) | Heinz | US | condiment | M | TODO | 2026-04-07 | | |
| 1667 | Yellow Mustard French's (per tsp) | French's | US | condiment | M | TODO | 2026-04-07 | | |
| 1668 | Chick-fil-A Sauce (per packet) | Chick-fil-A | US | condiment | M | TODO | 2026-04-07 | | |
| 1669 | Trader Joe's Green Goddess Dressing (per tbsp) | Trader Joe's | US | condiment | M | TODO | 2026-04-07 | | |
| 1670 | Fly by Jing Sichuan Chili Crisp (per tbsp) | Fly by Jing | US | condiment | M | TODO | 2026-04-07 | | Trendy |

## Section 54: International Frozen Foods & Ready Meals (40 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1671 | Amy's Kitchen Pad Thai (per serving) | Amy's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1672 | Amy's Kitchen Black Bean Enchilada (per serving) | Amy's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1673 | Lean Cuisine Chicken Teriyaki | Lean Cuisine | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1674 | Healthy Choice Power Bowls Chicken Feta | Healthy Choice | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1675 | Tatty's Chicken Pie (per pie) | Tatty's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1676 | Young's Scampi (per serving) | Young's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1677 | Aunt Bessie's Yorkshire Puddings (per piece) | Aunt Bessie's | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1678 | Iceland Ready Meal Chicken Tikka Masala | Iceland | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1679 | Magnum Mini Classic (per piece) | Magnum | NL | dessert | M | TODO | 2026-04-07 | | |
| 1680 | Ben & Jerry's Half Baked (per 100ml) | Ben & Jerry's | US | dessert | M | TODO | 2026-04-07 | | |
| 1681 | Häagen-Dazs Vanilla (per 100ml) | Häagen-Dazs | US | dessert | M | TODO | 2026-04-07 | | |
| 1682 | Viennetta Vanilla (per slice) | Wall's | GB | dessert | M | TODO | 2026-04-07 | | |
| 1683 | Solero Exotic (per bar) | Wall's | GB | dessert | M | TODO | 2026-04-07 | | |
| 1684 | Calippo Orange (per piece) | Wall's | GB | dessert | L | TODO | 2026-04-07 | | |
| 1685 | Bibigo Steamed Dumplings Chicken (per 4 pieces) | CJ | KR | frozen_meal | M | TODO | 2026-04-07 | | |
| 1686 | Ajinomoto Yakitori Chicken (per serving) | Ajinomoto | JP | frozen_meal | M | TODO | 2026-04-07 | | |
| 1687 | Trader Joe's Mandarin Orange Chicken (per serving) | Trader Joe's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1688 | Trader Joe's Chicken Tikka Masala (per serving) | Trader Joe's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1689 | Real Good Foods Chicken Enchiladas (per serving) | Real Good | US | frozen_meal | M | TODO | 2026-04-07 | | Low carb |
| 1690 | Saffron Road Chicken Tikka Masala (per serving) | Saffron Road | US | frozen_meal | M | TODO | 2026-04-07 | | Halal |
| 1691 | Strong Roots Mixed Root Vegetable Fries (per serving) | Strong Roots | IE | frozen_meal | M | TODO | 2026-04-07 | | |
| 1692 | Cook Frozen Meals Chicken Tikka | Cook | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1693 | Pieminister Moo Pie (per pie) | Pieminister | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1694 | Oetker Casa di Mama Pizza Pepperoni (per slice) | Dr. Oetker | DE | frozen_meal | M | TODO | 2026-04-07 | | |
| 1695 | Buitoni Buitoni Gyoza Chicken (per 5 pieces) | Buitoni | FR | frozen_meal | M | TODO | 2026-04-07 | | |
| 1696 | Picard Macarons Assortment (per piece) | Picard | FR | dessert | M | TODO | 2026-04-07 | | |
| 1697 | Gits Paneer Tikka Masala (per serving) | Gits | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1698 | ITC Kitchen of India Paneer Makhani (per serving) | ITC | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1699 | Tasty Bite Indian Madras Lentils (per serving) | Tasty Bite | IN | ready_meal | M | TODO | 2026-04-07 | | |
| 1700 | Maya Kaimal Everyday Dal Turmeric (per serving) | Maya Kaimal | US | ready_meal | M | TODO | 2026-04-07 | | |
| 1701 | Bibigo Korean BBQ Sauce (per tbsp) | CJ | KR | condiment | M | TODO | 2026-04-07 | | |
| 1702 | Wei-Chuan Pork & Chive Dumplings (per 5 pieces) | Wei-Chuan | TW | frozen_meal | M | TODO | 2026-04-07 | | |
| 1703 | Ling Ling Potstickers Chicken (per 5 pieces) | Ling Ling | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1704 | Schar Gluten Free Pizza Base (per base) | Schar | IT | frozen_meal | M | TODO | 2026-04-07 | | |
| 1705 | Quorn Crispy Nuggets (per 5 pieces) | Quorn | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1706 | Fry's Plant-Based Chicken Strips (per 100g) | Fry's | ZA | frozen_meal | M | TODO | 2026-04-07 | | SA plant-based |
| 1707 | Findus Grönsakspytt (per serving) | Findus | SE | frozen_meal | M | TODO | 2026-04-07 | | |
| 1708 | Gorton's Fish Sticks (per 6 sticks) | Gorton's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1709 | Marie Callender's Chicken Pot Pie (per pie) | Marie Callender's | US | frozen_meal | M | TODO | 2026-04-07 | | |
| 1710 | Stouffer's Lasagna with Meat Sauce (per serving) | Stouffer's | US | frozen_meal | M | TODO | 2026-04-07 | | |

## Section 55: More International Snacks & Treats (50 items)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 1711 | Oreo Original (per 3 cookies) | Oreo | US | biscuit | H | TODO | 2026-04-07 | | |
| 1712 | Oreo Double Stuf (per 2 cookies) | Oreo | US | biscuit | M | TODO | 2026-04-07 | | |
| 1713 | Oreo Thins (per 4 cookies) | Oreo | US | biscuit | M | TODO | 2026-04-07 | | |
| 1714 | Chips Ahoy Original (per 3 cookies) | Chips Ahoy | US | biscuit | M | TODO | 2026-04-07 | | |
| 1715 | Nutter Butter Peanut Sandwich Cookies (per 2) | Nabisco | US | biscuit | M | TODO | 2026-04-07 | | |
| 1716 | Twix Original (per bar) | Mars | US | chocolate | M | TODO | 2026-04-07 | | |
| 1717 | Snickers Original (per bar) | Mars | US | chocolate | M | TODO | 2026-04-07 | | |
| 1718 | M&M's Peanut (per 100g) | Mars | US | chocolate | M | TODO | 2026-04-07 | | |
| 1719 | Reese's Peanut Butter Cups (per 2 pack) | Hershey's | US | chocolate | H | TODO | 2026-04-07 | | |
| 1720 | Hershey's Milk Chocolate Bar (per bar) | Hershey's | US | chocolate | M | TODO | 2026-04-07 | | |
| 1721 | Kit Kat Original (per 4 finger) | Nestle | US | chocolate | M | TODO | 2026-04-07 | | |
| 1722 | Butterfinger Original (per bar) | Ferrero | US | chocolate | M | TODO | 2026-04-07 | | |
| 1723 | Twizzlers Strawberry (per 4 pieces) | Hershey's | US | confectionery | M | TODO | 2026-04-07 | | |
| 1724 | Swedish Fish Original (per 100g) | Mondelez | US | confectionery | M | TODO | 2026-04-07 | | |
| 1725 | Sour Patch Kids Original (per 100g) | Mondelez | US | confectionery | M | TODO | 2026-04-07 | | |
| 1726 | Mike and Ike Original (per 100g) | Just Born | US | confectionery | L | TODO | 2026-04-07 | | |
| 1727 | Trolli Sour Brite Crawlers (per 100g) | Ferrara | US | confectionery | L | TODO | 2026-04-07 | | |
| 1728 | Welch's Fruit Snacks Mixed Fruit (per pouch) | Welch's | US | confectionery | M | TODO | 2026-04-07 | | |
| 1729 | Goldfish Cheddar Crackers (per 55 pieces) | Pepperidge Farm | US | snack | M | TODO | 2026-04-07 | | |
| 1730 | Ritz Crackers Original (per 5 crackers) | Ritz | US | snack | M | TODO | 2026-04-07 | | |
| 1731 | Wheat Thins Original (per 16 crackers) | Nabisco | US | snack | M | TODO | 2026-04-07 | | |
| 1732 | Cheez-It Original (per 27 crackers) | Kellogg's | US | snack | M | TODO | 2026-04-07 | | |
| 1733 | Triscuit Original (per 6 crackers) | Nabisco | US | snack | M | TODO | 2026-04-07 | | |
| 1734 | Annie's Cheddar Bunnies (per 50 pieces) | Annie's | US | snack | M | TODO | 2026-04-07 | | |
| 1735 | Pirate's Booty Aged White Cheddar (per 100g) | Pirate Brands | US | snack | M | TODO | 2026-04-07 | | |
| 1736 | Skinny Pop Sea Salt (per 100g) | Skinny Pop | US | snack | M | TODO | 2026-04-07 | | |
| 1737 | Boom Chicka Pop Sea Salt (per 100g) | Angie's | US | snack | M | TODO | 2026-04-07 | | |
| 1738 | Sahale Snacks Maple Pecans Glazed Mix (per 30g) | Sahale | US | snack | M | TODO | 2026-04-07 | | |
| 1739 | Sun Chips Original (per 100g) | Frito-Lay | US | snack | M | TODO | 2026-04-07 | | |
| 1740 | Terra Exotic Vegetable Chips (per 100g) | Terra | US | snack | M | TODO | 2026-04-07 | | |
| 1741 | Lay's Classic (per 100g) | Lay's | US | snack | M | TODO | 2026-04-07 | | |
| 1742 | Kettle Brand Sea Salt (per 100g) | Kettle Brand | US | snack | M | TODO | 2026-04-07 | | |
| 1743 | Tostitos Scoops (per 100g) | Tostitos | US | snack | M | TODO | 2026-04-07 | | |
| 1744 | Nabisco Premium Saltine Crackers (per 5) | Nabisco | US | snack | M | TODO | 2026-04-07 | | |
| 1745 | Graham Crackers Honey Maid (per 2 sheets) | Nabisco | US | biscuit | M | TODO | 2026-04-07 | | |
| 1746 | Nilla Wafers (per 8 wafers) | Nabisco | US | biscuit | M | TODO | 2026-04-07 | | |
| 1747 | Cadbury Twirl (per bar) | Cadbury | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1748 | Cadbury Wispa (per bar) | Cadbury | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1749 | Cadbury Flake (per bar) | Cadbury | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1750 | Galaxy Smooth Milk (per bar) | Mars | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1751 | Terry's Chocolate Orange Segment (per segment) | Terry's | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1752 | Aero Mint Chocolate (per bar) | Nestle | GB | chocolate | M | TODO | 2026-04-07 | | |
| 1753 | Maltesers (per 100g) | Mars | GB | chocolate | M | TODO | 2026-04-07 | | |
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
| 1764 | Dempster's Whole Wheat Bread (per slice) | Dempster's | CA | bread | M | TODO | 2026-04-07 | | |
| 1765 | Country Harvest Multigrain Bread (per slice) | Country Harvest | CA | bread | M | TODO | 2026-04-07 | | |
| 1766 | Tip Top Wholemeal Bread (per slice) | Tip Top | AU | bread | M | TODO | 2026-04-07 | | |
| 1767 | Helga's Continental Bakehouse Sourdough (per slice) | Helga's | AU | bread | M | TODO | 2026-04-07 | | |
| 1768 | Vogel's Mixed Grain Bread (per slice) | Vogel's | NZ | bread | M | TODO | 2026-04-07 | | |
| 1769 | Kingsmill 50/50 (per slice) | Kingsmill | GB | bread | M | TODO | 2026-04-07 | | |
| 1770 | Burgen Soya & Linseed Bread (per slice) | Burgen | GB | bread | H | TODO | 2026-04-07 | | High protein bread |
| 1771 | Genius Gluten Free White Bread (per slice) | Genius | GB | bread | M | TODO | 2026-04-07 | | |
| 1772 | Schär Gluten Free White Bread (per slice) | Schär | IT | bread | M | TODO | 2026-04-07 | | |
| 1773 | Crumpet Warburtons (per piece) | Warburtons | GB | bread | M | TODO | 2026-04-07 | | British icon |
| 1774 | English Muffin Thomas' (per piece) | Thomas' | US | bread | M | TODO | 2026-04-07 | | |
| 1775 | Bagel Thomas' Everything (per piece) | Thomas' | US | bread | M | TODO | 2026-04-07 | | |
| 1776 | Pop-Tarts Frosted Strawberry (per pastry) | Kellogg's | US | breakfast | M | TODO | 2026-04-07 | | |
| 1777 | Eggo Waffles Buttermilk (per 2 waffles) | Kellogg's | US | breakfast | M | TODO | 2026-04-07 | | |
| 1778 | Nature's Path Organic Toaster Pastry (per pastry) | Nature's Path | CA | breakfast | M | TODO | 2026-04-07 | | |
| 1779 | Cheerios Honey Nut (per serving) | General Mills | US | cereal | M | TODO | 2026-04-07 | | |
| 1780 | Cinnamon Toast Crunch (per serving) | General Mills | US | cereal | M | TODO | 2026-04-07 | | |
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
| 1791 | Nature Valley Protein Bar Peanut Butter Dark Chocolate | Nature Valley | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1792 | Clif Builder's Protein Bar Chocolate Peanut Butter | Clif | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1793 | Kind Protein Bar Crunchy Peanut Butter | Kind | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1794 | GoMacro Protein Pleasure Bar Peanut Butter Chocolate | GoMacro | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1795 | No Cow Protein Bar Chocolate Fudge Brownie | No Cow | US | protein_bar | M | TODO | 2026-04-07 | | Dairy free |
| 1796 | Clif Whey Protein Bar Peanut Butter Chocolate | Clif | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1797 | Power Crunch Protein Bar Triple Chocolate | Power Crunch | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1798 | Aloha Plant Based Protein Bar Chocolate Chip Cookie | Aloha | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1799 | Skout Organic Protein Bar Chocolate Peanut Butter | Skout | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1800 | Nugo Protein Bar Chocolate Chocolate Chip | NuGo | US | protein_bar | M | TODO | 2026-04-07 | | |
| 1801 | Pukka Pie Steak & Kidney (per pie) | Pukka | GB | frozen_meal | M | TODO | 2026-04-07 | | |
| 1802 | Fray Bentos Steak & Kidney Pie (per tin) | Fray Bentos | GB | ready_meal | M | TODO | 2026-04-07 | | |
| 1803 | Heinz Cream of Tomato Soup (per serving) | Heinz | GB | soup | M | TODO | 2026-04-07 | | |
| 1804 | Baxters Highlander's Broth (per serving) | Baxters | GB | soup | M | TODO | 2026-04-07 | | |
| 1805 | Campbell's Cream of Mushroom Soup (per serving) | Campbell's | US | soup | M | TODO | 2026-04-07 | | |
| 1806 | Progresso Light Chicken Noodle Soup (per serving) | Progresso | US | soup | M | TODO | 2026-04-07 | | |
| 1807 | Rao's Marinara Sauce (per serving) | Rao's | US | condiment | M | TODO | 2026-04-07 | | |
| 1808 | Victoria Fine Foods Marinara (per serving) | Victoria | US | condiment | M | TODO | 2026-04-07 | | |
| 1809 | Annie's Organic Ketchup (per tbsp) | Annie's | US | condiment | L | TODO | 2026-04-07 | | |
| 1810 | Primal Kitchen Avocado Oil Mayo (per tbsp) | Primal Kitchen | US | condiment | M | TODO | 2026-04-07 | | |
| 1811 | Siete Cashew Queso (per tbsp) | Siete | US | condiment | M | TODO | 2026-04-07 | | |
| 1812 | Ithaca Hummus Classic (per tbsp) | Ithaca | US | dip | M | TODO | 2026-04-07 | | |
| 1813 | Sabra Hummus Classic (per tbsp) | Sabra | US | dip | M | TODO | 2026-04-07 | | |
| 1814 | Good Foods Chunky Guacamole (per tbsp) | Good Foods | US | dip | M | TODO | 2026-04-07 | | |
| 1815 | Dannon Light & Fit Greek Yogurt Vanilla | Dannon | US | dairy | M | TODO | 2026-04-07 | | |
| 1816 | Stonyfield Organic Whole Milk Yogurt Plain | Stonyfield | US | dairy | M | TODO | 2026-04-07 | | |
| 1817 | Maple Hill Organic Greek Yogurt Plain | Maple Hill | US | dairy | M | TODO | 2026-04-07 | | |
| 1818 | Tillamook Farmstyle Thick Cut Sharp Cheddar (per slice) | Tillamook | US | dairy | M | TODO | 2026-04-07 | | |
| 1819 | Cabot Seriously Sharp Cheddar (per 30g) | Cabot | US | dairy | M | TODO | 2026-04-07 | | |
| 1820 | Boursin Plant-Based Garlic & Herbs (per 30g) | Boursin | FR | dairy_alt | M | TODO | 2026-04-07 | | |
| 1821 | Nairn's Oat Crackers (per 4 crackers) | Nairn's | GB | snack | M | TODO | 2026-04-07 | | |
| 1822 | Ryvita Crispbread Original (per 2 slices) | Ryvita | GB | bread | M | TODO | 2026-04-07 | | |
| 1823 | Carr's Table Water Crackers (per 5 crackers) | Carr's | GB | snack | M | TODO | 2026-04-07 | | |
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
| 1840 | Sikhye Korean Rice Drink (per 250ml) | Various | KR | beverage | M | TODO | 2026-04-07 | | |
| 1841 | Yuja Tea Korean Citron (per serving) | Various | KR | beverage | M | TODO | 2026-04-07 | | |
| 1842 | Buldak Sauce (bottle per tbsp) | Samyang | KR | condiment | H | TODO | 2026-04-07 | | |
| 1843 | Ssamjang Dipping Paste (per tbsp) | CJ | KR | condiment | M | TODO | 2026-04-07 | | |
| 1844 | Spam Classic (per 56g serving) | Hormel | US | protein | M | TODO | 2026-04-07 | | Huge in Asia/Hawaii |
| 1845 | Vienna Sausages Libby's (per can) | Libby's | US | protein | L | TODO | 2026-04-07 | | |
| 1846 | Spam Lite (per 56g serving) | Hormel | US | protein | M | TODO | 2026-04-07 | | |
| 1847 | Skippy Peanut Butter Creamy (per tbsp) | Skippy | US | spread | M | TODO | 2026-04-07 | | |
| 1848 | Jif Peanut Butter Creamy (per tbsp) | Jif | US | spread | M | TODO | 2026-04-07 | | |
| 1849 | Justin's Almond Butter Classic (per tbsp) | Justin's | US | spread | M | TODO | 2026-04-07 | | |
| 1850 | RX Nut Butter Chocolate Peanut Butter (per packet) | RX | US | spread | M | TODO | 2026-04-07 | | |
| 1851 | Trader Joe's Cookie Butter (per tbsp) | Trader Joe's | US | spread | M | TODO | 2026-04-07 | | |
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
| 1862 | Lefse Norwegian Potato Flatbread (per piece) | Various | NO | bread | M | TODO | 2026-04-07 | | |
| 1863 | Dosa Batter iD (per 2 dosa) | iD Fresh | IN | breakfast | H | TODO | 2026-04-07 | | |
| 1864 | Upma Rava MTR (per serving dry mix) | MTR | IN | breakfast | M | TODO | 2026-04-07 | | |
| 1865 | Poha Flattened Rice Thick (per 100g dry) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |
| 1866 | Sabudana (Tapioca Pearls per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1867 | Besan Chickpea Flour (per 100g) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1868 | Moong Dal Split Yellow (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1869 | Rajma Red Kidney Beans (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1870 | Chana Dal Split Bengal Gram (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1871 | Toor Dal Pigeon Pea (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1872 | Masoor Dal Red Lentils (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1873 | Urad Dal Black Gram (per 100g dry) | Various | IN | staple | M | TODO | 2026-04-07 | | |
| 1874 | Ghee Amul Pure (per tsp) | Amul | IN | dairy | H | TODO | 2026-04-07 | | |
| 1875 | Coconut Oil Virgin Cold Pressed (per tbsp) | Various | IN | cooking | M | TODO | 2026-04-07 | | |
| 1876 | Mustard Oil Kachi Ghani (per tbsp) | Various | IN | cooking | M | TODO | 2026-04-07 | | |
| 1877 | Rice Bran Oil Fortune (per tbsp) | Fortune | IN | cooking | M | TODO | 2026-04-07 | | |
| 1878 | Groundnut Oil Dhara (per tbsp) | Dhara | IN | cooking | M | TODO | 2026-04-07 | | |
| 1879 | Sesame Oil Idhayam (per tbsp) | Idhayam | IN | cooking | M | TODO | 2026-04-07 | | |
| 1880 | Avocado Oil Chosen Foods (per tbsp) | Chosen Foods | US | cooking | M | TODO | 2026-04-07 | | |
| 1881 | Extra Virgin Olive Oil Bertolli (per tbsp) | Bertolli | IT | cooking | M | TODO | 2026-04-07 | | |
| 1882 | Olio Award Winning EVOO (per tbsp) | Various | GR | cooking | M | TODO | 2026-04-07 | | |
| 1883 | Flaxseed Oil Cold Pressed (per tbsp) | Various | CA | cooking | M | TODO | 2026-04-07 | | |
| 1884 | MCT Oil Bulletproof (per tbsp) | Bulletproof | US | supplement | M | TODO | 2026-04-07 | | |
| 1885 | Hemp Hearts Manitoba Harvest (per 30g) | Manitoba Harvest | CA | supplement | M | TODO | 2026-04-07 | | |
| 1886 | Chia Seeds Organic (per tbsp) | Various | MX | supplement | M | TODO | 2026-04-07 | | |
| 1887 | Flaxseed Meal Bob's Red Mill (per tbsp) | Bob's Red Mill | US | supplement | M | TODO | 2026-04-07 | | |
| 1888 | Psyllium Husk Powder (per tbsp) | Various | IN | supplement | M | TODO | 2026-04-07 | | |
| 1889 | Spirulina Powder (per tsp) | Various | US | supplement | M | TODO | 2026-04-07 | | |
| 1890 | Moringa Powder (per tsp) | Various | IN | supplement | M | TODO | 2026-04-07 | | |
| 1891 | Matcha Powder Ceremonial (per tsp) | Various | JP | supplement | M | TODO | 2026-04-07 | | |
| 1892 | Wheatgrass Powder (per tsp) | Various | US | supplement | L | TODO | 2026-04-07 | | |
| 1893 | Acai Powder Freeze Dried (per tbsp) | Various | BR | supplement | M | TODO | 2026-04-07 | | |
| 1894 | Maca Powder (per tsp) | Various | PE | supplement | M | TODO | 2026-04-07 | | |
| 1895 | Cacao Nibs Raw (per tbsp) | Various | PE | supplement | M | TODO | 2026-04-07 | | |
| 1896 | Nutritional Yeast Bragg's (per tbsp) | Bragg's | US | supplement | M | TODO | 2026-04-07 | | |
| 1897 | Apple Cider Vinegar Bragg's (per tbsp) | Bragg's | US | condiment | M | TODO | 2026-04-07 | | |
| 1898 | Manuka Honey Comvita UMF 15+ (per tsp) | Comvita | NZ | spread | M | TODO | 2026-04-07 | | |
| 1899 | Maple Syrup Pure Grade A (per tbsp) | Various | CA | condiment | M | TODO | 2026-04-07 | | |
| 1900 | Agave Nectar (per tbsp) | Various | MX | condiment | M | TODO | 2026-04-07 | | |
| 1901 | Monk Fruit Sweetener Lakanto (per tsp) | Lakanto | JP | condiment | M | TODO | 2026-04-07 | | |
| 1902 | Erythritol Swerve (per tsp) | Swerve | US | condiment | M | TODO | 2026-04-07 | | |
| 1903 | Stevia Drops SweetLeaf (per serving) | SweetLeaf | US | condiment | L | TODO | 2026-04-07 | | |
| 1904 | Sugar Free Syrup Jordan's Skinny Mixes Vanilla (per tbsp) | Jordan's | US | condiment | M | TODO | 2026-04-07 | | |
| 1905 | Torani Sugar Free Vanilla Syrup (per tbsp) | Torani | US | condiment | M | TODO | 2026-04-07 | | |
| 1906 | Monin Sugar Free Hazelnut Syrup (per tbsp) | Monin | FR | condiment | M | TODO | 2026-04-07 | | |
| 1907 | Biscoff Creamy Spread (per tbsp) | Lotus | BE | spread | M | TODO | 2026-04-07 | | |
| 1908 | Pip & Nut Coconut Almond Butter (per tbsp) | Pip & Nut | GB | spread | M | TODO | 2026-04-07 | | |
| 1909 | Sun-Pat Crunchy Peanut Butter (per tbsp) | Sun-Pat | GB | spread | M | TODO | 2026-04-07 | | |
| 1910 | Whole Earth Smooth Peanut Butter (per tbsp) | Whole Earth | GB | spread | M | TODO | 2026-04-07 | | |
| 1911 | Bega Crunchy Peanut Butter (per tbsp) | Bega | AU | spread | M | TODO | 2026-04-07 | | |
| 1912 | Pics Peanut Butter Smooth (per tbsp) | Pic's | NZ | spread | M | TODO | 2026-04-07 | | NZ icon |
| 1913 | Fix & Fogg Peanut Butter Smooth (per tbsp) | Fix & Fogg | NZ | spread | M | TODO | 2026-04-07 | | |
| 1914 | Meridian Cashew Butter (per tbsp) | Meridian | GB | spread | M | TODO | 2026-04-07 | | |
| 1915 | Protein Spread Grenade White Chocolate (per tbsp) | Grenade | GB | spread | M | TODO | 2026-04-07 | | |
| 1916 | WOW Butter Soy Nut Butter (per tbsp) | WOW Butter | CA | spread | M | TODO | 2026-04-07 | | Nut-free |
| 1917 | Nocciolata Dairy Free Spread (per tbsp) | Rigoni | IT | spread | M | TODO | 2026-04-07 | | |
| 1918 | Lindt Hazelnut Spread (per tbsp) | Lindt | CH | spread | M | TODO | 2026-04-07 | | |
| 1919 | Cadbury Dairy Milk Freddo (per bar) | Cadbury | AU | chocolate | M | TODO | 2026-04-07 | | |
| 1920 | Boost Juice Original Berry Crush (per regular) | Boost Juice | AU | beverage | M | TODO | 2026-04-07 | | |
| 1921 | Guzman y Gomez Chicken Burrito | GYG | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1922 | Zambrero Chicken Power Burrito | Zambrero | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1923 | Oporto Double Bondi Burger | Oporto | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1924 | Pie Face Classic Mince Beef Pie (per pie) | Pie Face | AU | fast_food | M | TODO | 2026-04-07 | | |
| 1925 | Wendy's NZ Classic Burger | Wendy's NZ | NZ | fast_food | M | TODO | 2026-04-07 | | Different from US |
| 1926 | BurgerFuel C.N.C. Burger | BurgerFuel | NZ | fast_food | M | TODO | 2026-04-07 | | NZ chain |
| 1927 | Tank Juice Classic Green Smoothie (per regular) | Tank | NZ | beverage | M | TODO | 2026-04-07 | | |
| 1928 | Hell Pizza Lust (per slice) | Hell Pizza | NZ | fast_food | M | TODO | 2026-04-07 | | NZ chain |
| 1929 | Kura Sushi Salmon Nigiri (per 2 pieces) | Kura | JP | fast_food | M | TODO | 2026-04-07 | | |
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
| 1949 | Din Tai Fung Fried Rice with Shrimp | Din Tai Fung | TW | fast_food | M | TODO | 2026-04-07 | | |
| 1950 | Tim Ho Wan BBQ Pork Bun (per piece) | Tim Ho Wan | HK | fast_food | M | TODO | 2026-04-07 | | Michelin starred |
| 1951 | Yifang Fruit Tea Passion Fruit (per M) | Yifang | TW | beverage | M | TODO | 2026-04-07 | | |
| 1952 | Heytea Cheese Tea Green (per M) | Heytea | CN | beverage | M | TODO | 2026-04-07 | | China trending |
| 1953 | Luckin Coffee Latte (per cup) | Luckin | CN | beverage | M | TODO | 2026-04-07 | | China #1 coffee |
| 1954 | Mixue Ice Cream (per serving) | Mixue | CN | dessert | M | TODO | 2026-04-07 | | World's largest chain |
| 1955 | Mixue Lemon Tea (per M) | Mixue | CN | beverage | M | TODO | 2026-04-07 | | |
| 1956 | Haidilao Hot Pot Broth Base Tomato (per serving) | Haidilao | CN | condiment | M | TODO | 2026-04-07 | | |
| 1957 | Master Kong Green Tea (per 500ml) | Master Kong | CN | beverage | M | TODO | 2026-04-07 | | |
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
| 1982 | Thai Iced Tea Homemade (per cup) | Various | TH | beverage | M | TODO | 2026-04-07 | | |
| 1983 | Teh Tarik Singapore (per cup) | Various | SG | beverage | M | TODO | 2026-04-07 | | |
| 1984 | Bandrek Indonesian Ginger Drink (per cup) | Various | ID | beverage | M | TODO | 2026-04-07 | | |
| 1985 | Wedang Jahe Indonesian Ginger Tea (per cup) | Various | ID | beverage | M | TODO | 2026-04-07 | | |
| 1986 | Cendol (per serving) | Various | MY | dessert | M | TODO | 2026-04-07 | | |
| 1987 | Ice Kacang ABC (per serving) | Various | MY | dessert | M | TODO | 2026-04-07 | | |
| 1988 | Chendol Singapore (per serving) | Various | SG | dessert | M | TODO | 2026-04-07 | | |
| 1989 | Es Teler Indonesian Fruit Drink (per serving) | Various | ID | dessert | M | TODO | 2026-04-07 | | |
| 1990 | Es Campur Indonesian Mixed Ice (per serving) | Various | ID | dessert | M | TODO | 2026-04-07 | | |
| 1991 | Turon Banana Spring Roll Philippines (per piece) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1992 | Leche Flan Filipino (per slice) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1993 | Ube Halaya Purple Yam Jam (per tbsp) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1994 | Bibingka Rice Cake Philippines (per piece) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1995 | Puto Filipino Steamed Cake (per piece) | Various | PH | dessert | M | TODO | 2026-04-07 | | |
| 1996 | Che Ba Mau Vietnamese Dessert (per serving) | Various | VN | dessert | M | TODO | 2026-04-07 | | |
| 1997 | Banh Tet Vietnamese Sticky Rice Cake (per slice) | Various | VN | dessert | M | TODO | 2026-04-07 | | |
| 1998 | Khanom Buang Thai Crispy Pancake (per piece) | Various | TH | dessert | M | TODO | 2026-04-07 | | |
| 1999 | Khanom Krok Thai Coconut Pancake (per piece) | Various | TH | dessert | M | TODO | 2026-04-07 | | |
| 2000 | Kheer Indian Rice Pudding (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2001 | Gulab Jamun (per piece) | Various | IN | dessert | H | TODO | 2026-04-07 | | |
| 2002 | Jalebi (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2003 | Barfi Kaju Katli (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2004 | Rasgulla (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2005 | Ladoo Motichoor (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2006 | Mysore Pak (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2007 | Peda Milk Sweet (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2008 | Gajar Ka Halwa Carrot Pudding (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2009 | Kulfi Mango (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2010 | Payasam Kerala Rice Pudding (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2011 | Modak Steamed Sweet (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2012 | Shrikhand Sweet Yogurt (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2013 | Cham Cham Bengali Sweet (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2014 | Puran Poli Maharashtrian (per piece) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2015 | Basundi Thick Sweetened Milk (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2016 | Thandai Spiced Milk (per cup) | Various | IN | beverage | M | TODO | 2026-04-07 | | |
| 2017 | Aam Ras Mango Puree (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2018 | Falooda Rose (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2019 | Rabri Thickened Milk Sweet (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2020 | Mishti Doi Bengali Sweet Yogurt (per serving) | Various | IN | dessert | M | TODO | 2026-04-07 | | |
| 2021 | Samosa Aloo (per piece) | Various | IN | snack | H | TODO | 2026-04-07 | | |
| 2022 | Vada Pav Mumbai (per piece) | Various | IN | fast_food | H | TODO | 2026-04-07 | | |
| 2023 | Pav Bhaji (per serving) | Various | IN | fast_food | H | TODO | 2026-04-07 | | |
| 2024 | Chole Bhature (per serving) | Various | IN | fast_food | H | TODO | 2026-04-07 | | |
| 2025 | Masala Dosa (per piece) | Various | IN | breakfast | H | TODO | 2026-04-07 | | |
| 2026 | Medu Vada (per piece) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |
| 2027 | Poori with Aloo (per piece + serving) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |
| 2028 | Aloo Paratha (per piece) | Various | IN | breakfast | H | TODO | 2026-04-07 | | |
| 2029 | Paneer Paratha (per piece) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |
| 2030 | Gobi Paratha (per piece) | Various | IN | breakfast | M | TODO | 2026-04-07 | | |

## Section 58: Items from User Food Log (Missing from DB)

| # | Food Name | Brand | Country | Category | Priority | Status | Date Added | Date Completed | Notes |
|---|-----------|-------|---------|----------|----------|--------|------------|----------------|-------|
| 2031 | Weisswein White Wine (per glass 150ml) | Various | DE | beverage | H | TODO | 2026-04-07 | | German white wine |
| 2032 | Oat Milk Latte (per 16oz cup) | Various | US | beverage | H | TODO | 2026-04-07 | | Coffee shop standard |
| 2033 | Carne Apache Mexican Raw Beef Dish (per serving) | Various | MX | protein | H | TODO | 2026-04-07 | | Mexican street food - raw beef cured in lime |
| 2034 | Goobne Oven Crispy Chicken Original (per piece) | Goobne | KR | fast_food | H | TODO | 2026-04-07 | | Korean oven-roasted chicken chain |
| 2035 | Goobne Oven Crispy Chicken Soy Garlic (per piece) | Goobne | KR | fast_food | M | TODO | 2026-04-07 | | |
| 2036 | Elote Cup Mexican Street Corn (per cup) | Various | MX | snack | H | TODO | 2026-04-07 | | Corn with mayo, chili, lime, cheese |
| 2037 | Esquites Mexican Corn Cup (per cup) | Various | MX | snack | M | TODO | 2026-04-07 | | Off-the-cob version of elote |
| 2038 | Mac and Cheese with Spam and Kimchi (per serving) | Various | US | fast_food | H | TODO | 2026-04-07 | | Korean-American fusion dish |
| 2039 | Spam Musubi (per piece) | Various | US | snack | H | TODO | 2026-04-07 | | Hawaiian staple |
| 2040 | Kimchi Fried Rice (per serving) | Various | KR | rice | H | TODO | 2026-04-07 | | |

---

## Progress Summary

| Metric | Count |
|--------|-------|
| **Total items** | 1909 |
| **TODO** | 1909 |
| **DUPLICATE** | 0 (all removed) |
| **DONE** | 0 |

### Sections
| # | Section | Items | Focus |
|---|---------|-------|-------|
| 1-40 | Original sections (cleaned) | ~899 | Protein bars/cereals, energy drinks, noodles, chocolate, snacks, beverages, biscuits, spreads, frozen meals, bread, Asian/ME/LatAm/African/EU/Plant-based/Fitness/Meal prep |
| 41 | UK Supermarket Own Brands | 50 | Tesco, Sainsbury's, M&S, Waitrose, Asda, Aldi, Lidl |
| 42 | German Supermarket & Brands | 50 | Aldi Süd, Lidl, Ehrmann, Ferrero DE, Funny Frisch, Fritz Kola |
| 43 | International Fast Food Unique Items | 60 | McDonald's India/Japan, Paris Baguette, Pret, Wagamama, MrBeast |
| 44 | Indian Specific Brands | 60 | Patanjali, Saffola, iD Fresh, Licious, MTR, Wow Momo |
| 45 | Japanese & Korean Specific | 60 | Konbini items, SAVAS, Lawson, FamilyMart, CU, GS25, Genki Forest |
| 46 | Southeast Asian Specific | 50 | Lucky Me, Silverqueen, Gardenia, Hao Hao, Vinamilk |
| 47 | Middle East & Turkey Specific | 50 | Pinar, Ülker, Almarai, Americana, Egyptian/Lebanese brands |
| 48 | European Brands & Products | 50 | Migros, Fazer, Marabou, Freia, Carrefour, Mulino Bianco |
| 49 | Latin American Specific | 40 | Bauducco, Bimbo, Havanna, Peruvian/Colombian dishes |
| 50 | African Brands & Foods | 40 | Shoprite, Koo, Nigerian staples, East African dishes |
| 51 | More Fitness & Health | 50 | Bloom, Vital Proteins, LMNT, running gels, SA protein brands |
| 52 | International Dairy & Cheese | 40 | Philadelphia, Boursin, Galbani, Korean/Japanese dairy |
| 53 | Sauces, Pastes & Cooking | 40 | Kikkoman, Sriracha, Mae Ploy, global condiments |
| 54 | Frozen Foods & Ready Meals | 40 | Amy's, Lean Cuisine, Bibigo, Trader Joe's frozen |
| 55 | More International Snacks | 50 | Oreo, Reese's, UK chocolates, Cadbury bars |
| 56 | Breads & Breakfast | 30 | Intl bread brands, UK cereals, breakfast items |
| 57 | Remaining (oils, superfoods, desserts, street food) | 240 | Cooking oils, supplements, Indian sweets, Asian desserts, beer, fast food chains |

### Countries covered (65+)
AR, AT, AU, BA, BE, BO, BR, CA, CH, CN, CO, CR, DE, DK, EC, EE, EG, ES, ET, FI, FR, GB, GE, GH, GR, HK, HU, ID, IE, IL, IN, IS, IT, JP, KE, KH, KR, LB, LV, MA, MM, MX, MY, MZ, NG, NL, NO, NZ, PE, PH, PK, PL, PS, PT, RS, RU, RW, SA, SE, SG, SN, TH, TN, TR, TW, TZ, UA, UG, US, VE, VN, YE, ZA

### Brands covered
500+ unique brands across fitness, supermarket own-label, artisan, restaurant, convenience store, and traditional categories
