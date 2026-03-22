# Street Food by Country — Tracking & Pipeline

---

## Section 1: Pipeline Instructions (Resume Guide)

**Goal:** Research street food vendor/stall items for each of 213 countries. One row per vendor type per country. Uses same 33-column `food_nutrition_overrides` format as chain restaurants. `restaurant_name` = vendor/stall type, `food_category` = "street_food".

### How to Check Current State

```bash
# See what's been launched
cat backend/scripts/street_foods/pipeline_log.json | python3 -c "
import json, sys
log = json.load(sys.stdin)
for key, val in sorted(log.get('launched', {}).items()):
    print(f'{key}: {val[\"status\"]}')
"

# Count completed vs remaining
python3 -c "
import json
log = json.load(open('backend/scripts/street_foods/pipeline_log.json'))
launched = log.get('launched', {})
done = sum(1 for v in launched.values() if v['status'] == 'done')
wip = sum(1 for v in launched.values() if v['status'] == 'launched')
print(f'Done: {done}, In progress: {wip}, Total launched: {len(launched)}')
"

# Check if a country already has street food in existing migrations
grep -ri "street_food" backend/scripts/country_foods/{cc}*.json 2>/dev/null | head -5
```

### Pipeline Per Vendor+Country

```
STEP 0: Check pipeline_log.json — skip any {vendor_slug}_{cc} already listed
  python3 -c "
import json
log = json.load(open('backend/scripts/street_foods/pipeline_log.json'))
print(list(log['launched'].keys()))
"

  ALSO check existing country food migrations for street_food category:
  grep -c "street_food" backend/scripts/country_foods/{cc}*.json 2>/dev/null
  # If the country already has 20+ street_food entries, cross-reference to avoid dupes

STEP 1: Mark status BEFORE launching agent
  → Set status to ⏳ in the status table below
  → Log to pipeline_log.json:
  python3 -c "
import json, datetime
log = json.load(open('backend/scripts/street_foods/pipeline_log.json'))
key = '{vendor_slug}_{cc}'  # e.g. 'pani_puri_cart_in'
log['launched'][key] = {
    'status': 'launched',
    'launched_at': datetime.datetime.utcnow().isoformat(),
    'vendor_type': '{vendor_type}',
    'country': '{country_name}',
    'cc': '{cc}'
}
json.dump(log, open('backend/scripts/street_foods/pipeline_log.json', 'w'), indent=2)
"

STEP 2: Agent researches street food items and writes JSON
  → Output: backend/scripts/street_foods/{vendor_slug}_{cc}.json
  → Agent MUST use the JSON format in Section 2 (all 33 columns)
  → Agent MUST check existing country_foods/{cc}*.json for duplicates
  → Agent MUST check existing migration SQL files for duplicates:
      grep -ri "{item_name}" backend/migrations/*overrides*.sql 2>/dev/null

STEP 3: Merge + generate SQL
  cc="xx"
  python3 -c "
import json, glob, re

# Load all street food JSON files for this country
files = glob.glob(f'backend/scripts/street_foods/*_{cc}.json')
all_items = []
for f in files:
    items = json.load(open(f))
    all_items.extend(items)

# Check against existing country foods for duplicates
existing_files = glob.glob(f'backend/scripts/country_foods/{cc}*.json')
existing_names = set()
for ef in existing_files:
    for item in json.load(open(ef)):
        existing_names.add(item.get('name', '').lower().replace(' ', '_'))

# Deduplicate
seen = set()
unique = []
for item in all_items:
    key = item['food_name_normalized']
    base_name = key.rsplit('_', 1)[0]  # remove country suffix
    if key not in seen and base_name not in existing_names:
        seen.add(key)
        unique.append(item)

print(f'Total unique NEW items for {cc}: {len(unique)}')
print(f'Skipped {len(all_items) - len(unique)} duplicates')
"

STEP 4: Mark status as ✅
  → Update status table: ⏳ → ✅
  → Update pipeline_log.json: status → 'done'
  python3 -c "
import json, datetime
log = json.load(open('backend/scripts/street_foods/pipeline_log.json'))
key = '{vendor_slug}_{cc}'
log['launched'][key]['status'] = 'done'
log['launched'][key]['completed_at'] = datetime.datetime.utcnow().isoformat()
json.dump(log, open('backend/scripts/street_foods/pipeline_log.json', 'w'), indent=2)
"
```

### SQL Generation Notes

- **Migration naming:** `{next_migration_number}_street_{vendor_slug}_{cc}.sql`
- **Upsert pattern:** Use `ON CONFLICT (food_name_normalized) DO UPDATE`
- **`restaurant_name`:** Vendor/stall type (e.g., "Pani Puri Cart", "Takoyaki Stand")
- **`food_category`:** Always `"street_food"`
- **`source`:** `"research"` (no official vendor website)
- **All values per 100g**

### Agent Launch Rules

1. **ALWAYS check `pipeline_log.json` before launching** — skip if already `launched` or `done`
2. **ALWAYS check existing country food files** for `category: "street_food"` entries to avoid dupes
3. **ALWAYS mark ⏳ BEFORE launching**
4. **Max 5 parallel agents** at a time
5. **Group by country, not vendor type** — one agent per country researches ALL vendor types for that country
6. **Priority order:** Top 30 countries first (Section 6), then alphabetical

---

## Section 2: JSON Format (All 33 Columns from `food_nutrition_overrides`)

Columns sourced from migrations 270, 277, 324, 1646.

Every item in `backend/scripts/street_foods/{vendor_slug}_{cc}.json` must use this exact format:

```json
{
  "food_name_normalized": "pani_puri_cart_pani_puri_in",
  "display_name": "Pani Puri (Street Cart)",
  "calories_per_100g": 180,
  "protein_per_100g": 3.5,
  "carbs_per_100g": 28.0,
  "fat_per_100g": 6.2,
  "fiber_per_100g": 2.1,
  "sugar_per_100g": 1.8,
  "default_serving_g": 150,
  "default_weight_per_piece_g": 25,
  "source": "research",
  "variant_names": ["golgappa", "puchka", "gup chup"],
  "notes": "Hollow wheat balls filled with spiced water, potato, chickpeas. Ubiquitous Indian street food.",
  "is_active": true,
  "food_category": "street_food",
  "restaurant_name": "Pani Puri Cart",
  "default_count": 6,
  "region": "IN",
  "sodium_mg": 320,
  "cholesterol_mg": 0,
  "saturated_fat_g": 1.2,
  "trans_fat_g": 0.3,
  "potassium_mg": 150,
  "calcium_mg": 25,
  "iron_mg": 1.5,
  "vitamin_a_ug": 10,
  "vitamin_c_mg": 3.0,
  "vitamin_d_iu": 0,
  "magnesium_mg": 18,
  "zinc_mg": 0.6,
  "phosphorus_mg": 55,
  "selenium_ug": 5,
  "omega3_g": 0.05
}
```

### Column Reference

| # | Column | Type | Source Migration | Street Food Notes |
|---|--------|------|-----------------|-------------------|
| 1 | `food_name_normalized` | TEXT NOT NULL UNIQUE | 270 | `{vendor_slug}_{item_slug}_{cc}` |
| 2 | `display_name` | TEXT NOT NULL | 270 | "{Item Name} (Street Cart/Stand)" |
| 3 | `calories_per_100g` | REAL NOT NULL | 270 | Atwater: ≈ prot×4 + carb×4 + fat×9 (±15%) |
| 4 | `protein_per_100g` | REAL NOT NULL | 270 | |
| 5 | `carbs_per_100g` | REAL NOT NULL | 270 | |
| 6 | `fat_per_100g` | REAL NOT NULL | 270 | |
| 7 | `fiber_per_100g` | REAL NOT NULL DEFAULT 0 | 270 | |
| 8 | `sugar_per_100g` | REAL DEFAULT NULL | 270 | |
| 9 | `default_weight_per_piece_g` | REAL DEFAULT NULL | 270 | Per piece if count-based (e.g., 25g per puri) |
| 10 | `default_serving_g` | REAL DEFAULT NULL | 270 | Typical street serving |
| 11 | `source` | TEXT DEFAULT 'manual' | 270 | Always `"research"` for street food |
| 12 | `notes` | TEXT DEFAULT NULL | 270 | Cultural context, preparation method |
| 13 | `variant_names` | TEXT[] DEFAULT NULL | 270 | Regional names, transliterations |
| 14 | `is_active` | BOOLEAN NOT NULL DEFAULT TRUE | 270 | |
| 15 | `food_category` | TEXT DEFAULT NULL | 277 | Always `"street_food"` |
| 16 | `restaurant_name` | TEXT DEFAULT NULL | 277 | Vendor/stall type name |
| 17 | `default_count` | INTEGER DEFAULT 1 | 277 | e.g., 6 for 6 pieces of pani puri |
| 18 | `region` | TEXT | 1646 | ISO 3166-1 alpha-2 (NULL if cross-country) |
| 19-33 | Micronutrients | REAL DEFAULT NULL | 324 | Set null if unknown, research when possible |

### Naming Conventions

- `food_name_normalized`: `{vendor_slug}_{item_slug}_{cc}` — e.g., `takoyaki_stand_takoyaki_jp`, `doner_stand_doner_kebab_de`
- `vendor_slug`: lowercase, underscores — `pani_puri_cart`, `takoyaki_stand`, `taco_stand`, `doner_stand`
- `item_slug`: lowercase, underscores — `pani_puri`, `takoyaki`, `al_pastor_taco`
- `restaurant_name`: Human-readable vendor type — "Pani Puri Cart", "Takoyaki Stand", "Taco Stand"
- `source`: Always `"research"` (no official website for street vendors)

---

## Section 3: Dedup Strategy

### Within-Country Dedup

- **Same item, multiple vendor types:** ONE entry per distinct item. Example: if both "Chaat Stand" and "Pani Puri Cart" sell pani puri, create ONE `pani_puri_cart_pani_puri_in` entry.
- **Vendor type determines `restaurant_name`:** Use the MOST COMMON vendor type for that item.

### Cross-Country Dedup

| Scenario | Action | Example |
|----------|--------|---------|
| Same food, same nutrition, multiple countries | ONE entry with `region = NULL` | Hot dog (universal) |
| Same food, different preparation/nutrition | Country-specific entry with `_{cc}` | Corn on the cob (grilled in MX, boiled in US) |
| Unique to one country | Entry with `region = '{CC}'` and `_{cc}` suffix | Takoyaki (JP only) |

### Checking Existing Data (Country Foods + food_nutrition_overrides Table)

**CRITICAL:** Street food items may already exist in TWO places:
1. **Country food JSON files** — `backend/scripts/country_foods/{cc}*.json` with `category: "street_food"`
2. **`food_nutrition_overrides` table** — already deployed to Supabase via migrations

Before adding street food items, agents MUST check BOTH:

```bash
# 1. Check existing street food in country food JSON files
python3 -c "
import json, glob
files = glob.glob('backend/scripts/country_foods/{cc}*.json')
street_foods = []
for f in files:
    for item in json.load(open(f)):
        if item.get('category') == 'street_food':
            street_foods.append(item['name'])
print(f'Existing street foods in JSON for {cc}: {len(street_foods)}')
for sf in sorted(street_foods):
    print(f'  - {sf}')
"

# 2. Check existing items in food_nutrition_overrides migrations for this country
grep -ri "street_food\|street food" backend/migrations/*overrides*{cc}*.sql 2>/dev/null | head -20

# 3. Check ALL migration files for the food name (it may exist without street_food category)
# Example: search for "pani_puri" or "takoyaki" across all migrations
grep -ri "{food_name}" backend/migrations/*.sql 2>/dev/null | head -10

# 4. Check the country override migration specifically
grep -ri "{food_name}" backend/migrations/*overrides_{cc}*.sql 2>/dev/null | head -10
```

If an item already exists in EITHER the country food JSON files OR the deployed `food_nutrition_overrides` migrations, do NOT add it again. Only add items that are:
1. Missing entirely from both country food files AND migration SQL files
2. Vendor-specific preparations that are meaningfully different from existing entries (e.g., "Taco Stand Al Pastor" with different nutrition than generic "Al Pastor Taco" in country foods)
3. Items where the existing entry lacks the 15 micronutrient columns (migration 324) — in this case, create a NEW entry with the vendor-specific name, don't try to update the old one

---

## Section 4: Master Status Table (One Row Per Vendor Type Per Country)

### Legend
- ✅ = Done (items researched, JSON written, SQL generated)
- ⏳ = Agent currently working
- (blank) = Not started

Sorted by country code (alphabetical). PRIORITY = research order (1–30 by street food culture richness, blank = lower priority).

| STATUS | CODE | COUNTRY | VENDOR TYPE | EST. ITEMS | MIGRATION | PRIORITY |
|--------|------|---------|-------------|-----------|-----------|----------|
|  | AE | United Arab Emirates | Falafel Cart | ~3 | — | 30 |
|  | AE | United Arab Emirates | Luqaimat Stand | ~2 | — | 30 |
|  | AE | United Arab Emirates | Shawarma Stand | ~4 | — | 30 |
|  | AF | Afghanistan | Bolani Stand | ~3 | — |  |
|  | AF | Afghanistan | Kebab Grill | ~4 | — |  |
|  | AR | Argentina | Alfajor Cart | ~2 | — |  |
|  | AR | Argentina | Choripán Stand | ~2 | — |  |
|  | AR | Argentina | Empanada Cart | ~4 | — |  |
|  | AT | Austria | Würstelstand | ~5 | — |  |
|  | AU | Australia | Dim Sim Cart | ~2 | — | 25 |
|  | AU | Australia | Fairy Floss / Dagwood Dog Cart | ~2 | — | 25 |
|  | AU | Australia | Halal Snack Pack Stand | ~3 | — | 25 |
|  | AU | Australia | Meat Pie Cart | ~3 | — | 25 |
|  | AU | Australia | Sausage Sizzle Stand | ~2 | — | 25 |
|  | BD | Bangladesh | Fuchka Cart | ~4 | — |  |
|  | BD | Bangladesh | Jhalmuri Stand | ~3 | — |  |
|  | BE | Belgium | Frites Stand | ~4 | — |  |
|  | BE | Belgium | Waffle Cart | ~3 | — |  |
|  | BR | Brazil | Acaraje Stand | ~3 | — | 13 |
|  | BR | Brazil | Acai Stand | ~3 | — | 13 |
|  | BR | Brazil | Churro Cart | ~2 | — | 13 |
|  | BR | Brazil | Coxinha Stand | ~3 | — | 13 |
|  | BR | Brazil | Espetinho Grill | ~4 | — | 13 |
|  | BR | Brazil | Pastel Cart | ~4 | — | 13 |
|  | BR | Brazil | Tapioca Cart | ~4 | — | 13 |
|  | CA | Canada | BeaverTails Cart | ~3 | — | 24 |
|  | CA | Canada | Hot Dog Cart | ~3 | — | 24 |
|  | CA | Canada | Peameal Bacon Stand | ~2 | — | 24 |
|  | CA | Canada | Poutine Stand | ~4 | — | 24 |
|  | CH | Switzerland | Raclette Stand | ~2 | — |  |
|  | CL | Chile | Completo Stand | ~3 | — |  |
|  | CL | Chile | Empanada Cart | ~3 | — |  |
|  | CN | China | Baozi Steamer Cart | ~5 | — | 2 |
|  | CN | China | Boba Tea Stand | ~4 | — | 2 |
|  | CN | China | Chuan'r / Skewer Grill | ~8 | — | 2 |
|  | CN | China | Dim Sum Cart | ~8 | — | 2 |
|  | CN | China | Jianbing Cart | ~3 | — | 2 |
|  | CN | China | Noodle Cart | ~5 | — | 2 |
|  | CN | China | Rou Jia Mo Stand | ~3 | — | 2 |
|  | CN | China | Scallion Pancake Cart | ~2 | — | 2 |
|  | CN | China | Stinky Tofu Stand | ~2 | — | 2 |
|  | CN | China | Tanghulu Cart | ~2 | — | 2 |
|  | CO | Colombia | Arepa Stand | ~4 | — |  |
|  | CO | Colombia | Empanada Cart | ~3 | — |  |
|  | CZ | Czech Republic | Klobása Stand | ~3 | — |  |
|  | CZ | Czech Republic | Trdelník Stand | ~2 | — |  |
|  | DE | Germany | Bratwurst Stand | ~4 | — | 11 |
|  | DE | Germany | Currywurst Stand | ~3 | — | 11 |
|  | DE | Germany | Doner Kebab Stand | ~6 | — | 11 |
|  | DE | Germany | Fischbrötchen Stand | ~3 | — | 11 |
|  | DE | Germany | Pommes Frites Stand | ~3 | — | 11 |
|  | DE | Germany | Pretzel Cart | ~2 | — | 11 |
|  | DK | Denmark | Pølsevogn (Hot Dog Cart) | ~3 | — |  |
|  | EG | Egypt | Falafel / Ta'ameya Cart | ~3 | — | 10 |
|  | EG | Egypt | Ful Medames Cart | ~2 | — | 10 |
|  | EG | Egypt | Koshari Cart | ~3 | — | 10 |
|  | EG | Egypt | Shawarma Stand | ~3 | — | 10 |
|  | EG | Egypt | Sugar Cane Juice Cart | ~1 | — | 10 |
|  | EG | Egypt | Sweet Potato Cart | ~1 | — | 10 |
|  | ES | Spain | Bocadillo Stand | ~3 | — | 26 |
|  | ES | Spain | Castañas (Chestnut) Cart | ~1 | — | 26 |
|  | ES | Spain | Churro Stand | ~2 | — | 26 |
|  | ES | Spain | Empanada Cart | ~3 | — | 26 |
|  | FI | Finland | Lihapiirakka Cart | ~2 | — |  |
|  | FR | France | Baguette Sandwich Cart | ~3 | — | 16 |
|  | FR | France | Chestnut Cart | ~1 | — | 16 |
|  | FR | France | Crepe Stand | ~5 | — | 16 |
|  | FR | France | Galette Stand | ~4 | — | 16 |
|  | FR | France | Gaufre (Waffle) Cart | ~2 | — | 16 |
|  | FR | France | Kebab Stand | ~4 | — | 16 |
|  | GB | United Kingdom | Crepe Stand | ~3 | — | 12 |
|  | GB | United Kingdom | Fish & Chips Van | ~4 | — | 12 |
|  | GB | United Kingdom | Hot Dog Cart | ~2 | — | 12 |
|  | GB | United Kingdom | Jacket Potato Van | ~3 | — | 12 |
|  | GB | United Kingdom | Kebab Van | ~5 | — | 12 |
|  | GB | United Kingdom | Pie & Mash Stand | ~3 | — | 12 |
|  | GR | Greece | Gyros Stand | ~4 | — | 23 |
|  | GR | Greece | Loukoumades Cart | ~2 | — | 23 |
|  | GR | Greece | Souvlaki Stand | ~3 | — | 23 |
|  | HK | Hong Kong | Egg Waffle Stand | ~2 | — |  |
|  | HK | Hong Kong | Fish Ball Cart | ~3 | — |  |
|  | HK | Hong Kong | Stinky Tofu Stand | ~2 | — |  |
|  | HU | Hungary | Kürtőskalács Stand | ~2 | — |  |
|  | HU | Hungary | Lángos Stand | ~3 | — |  |
|  | ID | Indonesia | Bakso Cart | ~3 | — | 8 |
|  | ID | Indonesia | Bubur Ayam Cart | ~2 | — | 8 |
|  | ID | Indonesia | Es Cendol Cart | ~2 | — | 8 |
|  | ID | Indonesia | Gorengan (Fritter) Cart | ~5 | — | 8 |
|  | ID | Indonesia | Martabak Stand | ~3 | — | 8 |
|  | ID | Indonesia | Nasi Goreng Cart | ~3 | — | 8 |
|  | ID | Indonesia | Satay Grill | ~4 | — | 8 |
|  | ID | Indonesia | Soto Cart | ~3 | — | 8 |
|  | IE | Ireland | Chip Van | ~3 | — |  |
|  | IL | Israel | Falafel Stand | ~4 | — |  |
|  | IL | Israel | Sabich Stand | ~2 | — |  |
|  | IL | Israel | Shawarma Stand | ~3 | — |  |
|  | IN | India | Bhel Puri Stand | ~4 | — | 1 |
|  | IN | India | Chaat Stand | ~10 | — | 1 |
|  | IN | India | Chai Cart | ~3 | — | 1 |
|  | IN | India | Chole Bhature Stand | ~2 | — | 1 |
|  | IN | India | Dosa Cart | ~8 | — | 1 |
|  | IN | India | Egg Roll Cart | ~3 | — | 1 |
|  | IN | India | Jalebi Stand | ~2 | — | 1 |
|  | IN | India | Kulfi Cart | ~3 | — | 1 |
|  | IN | India | Lassi Stand | ~3 | — | 1 |
|  | IN | India | Momos Cart | ~4 | — | 1 |
|  | IN | India | Pani Puri / Golgappa Cart | ~5 | — | 1 |
|  | IN | India | Paratha Stand | ~6 | — | 1 |
|  | IN | India | Pav Bhaji Cart | ~2 | — | 1 |
|  | IN | India | Samosa Cart | ~3 | — | 1 |
|  | IN | India | Vada Pav Stall | ~4 | — | 1 |
|  | IT | Italy | Arancini Stand | ~3 | — | 19 |
|  | IT | Italy | Gelato Cart | ~5 | — | 19 |
|  | IT | Italy | Piadina Stand | ~3 | — | 19 |
|  | IT | Italy | Pizza al Taglio Stand | ~4 | — | 19 |
|  | IT | Italy | Porchetta Stand | ~2 | — | 19 |
|  | IT | Italy | Supplì / Fritto Stand | ~3 | — | 19 |
|  | JM | Jamaica | Jerk Stand | ~4 | — |  |
|  | JM | Jamaica | Patty Cart | ~2 | — |  |
|  | JO | Jordan | Falafel Stand | ~3 | — |  |
|  | JO | Jordan | Shawarma Stand | ~3 | — |  |
|  | JP | Japan | Crepe Stand | ~4 | — | 5 |
|  | JP | Japan | Dango Stand | ~3 | — | 5 |
|  | JP | Japan | Ikayaki Stand | ~2 | — | 5 |
|  | JP | Japan | Kakigori Stand | ~2 | — | 5 |
|  | JP | Japan | Karaage Stand | ~2 | — | 5 |
|  | JP | Japan | Okonomiyaki Stand | ~3 | — | 5 |
|  | JP | Japan | Ramen Cart (Yatai) | ~5 | — | 5 |
|  | JP | Japan | Taiyaki Stand | ~2 | — | 5 |
|  | JP | Japan | Takoyaki Stand | ~3 | — | 5 |
|  | JP | Japan | Yakitori Stand | ~5 | — | 5 |
|  | KE | Kenya | Maize Cart | ~2 | — |  |
|  | KE | Kenya | Nyama Choma Grill | ~3 | — |  |
|  | KR | South Korea | Bungeoppang Stand | ~2 | — | 7 |
|  | KR | South Korea | Hotteok Stand | ~2 | — | 7 |
|  | KR | South Korea | Kimbap Cart | ~3 | — | 7 |
|  | KR | South Korea | Korean Fried Chicken Stand | ~3 | — | 7 |
|  | KR | South Korea | Odeng / Fish Cake Stand | ~3 | — | 7 |
|  | KR | South Korea | Tornado Potato Stand | ~2 | — | 7 |
|  | KR | South Korea | Tteokbokki Cart | ~4 | — | 7 |
|  | KR | South Korea | Twigim (Fritter) Cart | ~4 | — | 7 |
|  | LB | Lebanon | Manoushe Stand | ~3 | — |  |
|  | LB | Lebanon | Shawarma Stand | ~4 | — |  |
|  | MA | Morocco | Harira Cart | ~2 | — |  |
|  | MA | Morocco | Msemen Stand | ~2 | — |  |
|  | MA | Morocco | Snail Cart | ~2 | — |  |
|  | MX | Mexico | Agua Fresca Cart | ~4 | — | 3 |
|  | MX | Mexico | Churro Cart | ~2 | — | 3 |
|  | MX | Mexico | Elote / Esquites Cart | ~3 | — | 3 |
|  | MX | Mexico | Gordita Stand | ~3 | — | 3 |
|  | MX | Mexico | Huarache Stand | ~2 | — | 3 |
|  | MX | Mexico | Quesadilla Stand | ~3 | — | 3 |
|  | MX | Mexico | Taco Stand | ~12 | — | 3 |
|  | MX | Mexico | Tamales Cart | ~5 | — | 3 |
|  | MX | Mexico | Tlayuda Stand | ~3 | — | 3 |
|  | MX | Mexico | Torta Stand | ~4 | — | 3 |
|  | MY | Malaysia | Apam Balik Stand | ~2 | — | 15 |
|  | MY | Malaysia | Cendol Cart | ~2 | — | 15 |
|  | MY | Malaysia | Char Kway Teow Stand | ~2 | — | 15 |
|  | MY | Malaysia | Lok Lok Stand | ~5 | — | 15 |
|  | MY | Malaysia | Nasi Lemak Stand | ~3 | — | 15 |
|  | MY | Malaysia | Roti Canai Stall | ~4 | — | 15 |
|  | MY | Malaysia | Satay Grill | ~3 | — | 15 |
|  | NG | Nigeria | Akara Cart | ~2 | — | 17 |
|  | NG | Nigeria | Puff Puff Cart | ~2 | — | 17 |
|  | NG | Nigeria | Roasted Corn Cart | ~1 | — | 17 |
|  | NG | Nigeria | Roasted Plantain Stand | ~2 | — | 17 |
|  | NG | Nigeria | Suya Grill | ~4 | — | 17 |
|  | NL | Netherlands | Herring Cart | ~3 | — | 27 |
|  | NL | Netherlands | Poffertjes Stand | ~2 | — | 27 |
|  | NL | Netherlands | Stroopwafel Stand | ~2 | — | 27 |
|  | NO | Norway | Pølse Stand | ~3 | — |  |
|  | NZ | New Zealand | Fish & Chips Van | ~3 | — |  |
|  | NZ | New Zealand | Pie Cart | ~3 | — |  |
|  | PE | Peru | Anticucho Grill | ~3 | — |  |
|  | PE | Peru | Ceviche Cart | ~3 | — |  |
|  | PE | Peru | Picarones Cart | ~2 | — |  |
|  | PH | Philippines | Balut Cart | ~2 | — | 9 |
|  | PH | Philippines | Banana Cue / Turon Cart | ~3 | — | 9 |
|  | PH | Philippines | Fish Ball Cart | ~4 | — | 9 |
|  | PH | Philippines | Halo Halo Stand | ~2 | — | 9 |
|  | PH | Philippines | Isaw / Grilled Innards Stand | ~5 | — | 9 |
|  | PH | Philippines | Kwek Kwek Stand | ~2 | — | 9 |
|  | PH | Philippines | Taho Cart | ~2 | — | 9 |
|  | PK | Pakistan | Bun Kebab Stand | ~3 | — | 18 |
|  | PK | Pakistan | Chaat Stand | ~8 | — | 18 |
|  | PK | Pakistan | Lassi Stand | ~2 | — | 18 |
|  | PK | Pakistan | Nihari Cart | ~2 | — | 18 |
|  | PK | Pakistan | Paratha Roll Stand | ~3 | — | 18 |
|  | PK | Pakistan | Samosa / Pakora Cart | ~4 | — | 18 |
|  | PL | Poland | Obwarzanek Cart | ~2 | — | 28 |
|  | PL | Poland | Zapiekanka Stand | ~3 | — | 28 |
|  | PT | Portugal | Bifana Stand | ~2 | — |  |
|  | PT | Portugal | Pastéis de Nata Cart | ~2 | — |  |
|  | RO | Romania | Covrigi (Pretzel) Cart | ~2 | — |  |
|  | RU | Russia | Blini Stand | ~3 | — |  |
|  | RU | Russia | Pirozhki Cart | ~3 | — |  |
|  | RU | Russia | Shawarma Stand | ~3 | — |  |
|  | SA | Saudi Arabia | Falafel Cart | ~3 | — | 20 |
|  | SA | Saudi Arabia | Fresh Juice Stand | ~3 | — | 20 |
|  | SA | Saudi Arabia | Mutabbaq Stand | ~2 | — | 20 |
|  | SA | Saudi Arabia | Samosa Cart | ~2 | — | 20 |
|  | SA | Saudi Arabia | Shawarma Stand | ~4 | — | 20 |
|  | SE | Sweden | Tunnbrödsrulle Stand | ~2 | — | 29 |
|  | SG | Singapore | Carrot Cake Stand | ~2 | — | 22 |
|  | SG | Singapore | Ice Kachang Cart | ~2 | — | 22 |
|  | SG | Singapore | Muah Chee Cart | ~1 | — | 22 |
|  | SG | Singapore | Popiah Stand | ~2 | — | 22 |
|  | SG | Singapore | Satay Grill | ~3 | — | 22 |
|  | TH | Thailand | Fried Insect Cart | ~3 | — | 4 |
|  | TH | Thailand | Grilled Meat Skewer Stand | ~4 | — | 4 |
|  | TH | Thailand | Khao Man Gai Cart | ~2 | — | 4 |
|  | TH | Thailand | Mango Sticky Rice Cart | ~2 | — | 4 |
|  | TH | Thailand | Noodle Boat | ~5 | — | 4 |
|  | TH | Thailand | Pad Thai Cart | ~3 | — | 4 |
|  | TH | Thailand | Roti Cart | ~3 | — | 4 |
|  | TH | Thailand | Satay Grill | ~3 | — | 4 |
|  | TH | Thailand | Som Tam Cart | ~3 | — | 4 |
|  | TH | Thailand | Thai Iced Tea Cart | ~2 | — | 4 |
|  | TR | Turkey | Ayran Cart | ~1 | — | 6 |
|  | TR | Turkey | Balik Ekmek Boat | ~2 | — | 6 |
|  | TR | Turkey | Doner Kebab Stand | ~6 | — | 6 |
|  | TR | Turkey | Gozleme Stand | ~3 | — | 6 |
|  | TR | Turkey | Kestane (Chestnut) Cart | ~1 | — | 6 |
|  | TR | Turkey | Kokorec Stand | ~2 | — | 6 |
|  | TR | Turkey | Lahmacun Stand | ~2 | — | 6 |
|  | TR | Turkey | Mısır (Corn) Cart | ~2 | — | 6 |
|  | TR | Turkey | Simit Cart | ~2 | — | 6 |
|  | TT | Trinidad and Tobago | Doubles Stand | ~3 | — |  |
|  | TW | Taiwan | Night Market Stalls | ~15 | — |  |
|  | UA | Ukraine | Varenyky Stand | ~3 | — |  |
|  | VE | Venezuela | Arepa Stand | ~4 | — |  |
|  | VN | Vietnam | Banh Mi Cart | ~4 | — | 14 |
|  | VN | Vietnam | Bun Cha Stand | ~3 | — | 14 |
|  | VN | Vietnam | Pho Cart | ~3 | — | 14 |
|  | ZA | South Africa | Biltong Stand | ~3 | — | 21 |
|  | ZA | South Africa | Boerewors Roll Stand | ~3 | — | 21 |
|  | ZA | South Africa | Bunny Chow Stand | ~3 | — | 21 |
|  | ZA | South Africa | Gatsby Stand | ~3 | — | 21 |
|  | ZA | South Africa | Koeksister Cart | ~2 | — | 21 |
|  | ZA | South Africa | Vetkoek Stand | ~2 | — | 21 |

_New rows added as research identifies additional vendor types per country._

## Section 5: Agent Prompt Template

Use this template when launching research agents for street food per country:

```
You are a nutrition research agent for the FitWiz fitness app.

## Task
Research street food vendor/stall items for {COUNTRY_NAME} ({CC}).

## Rules
1. Research ALL common street food vendor types in {COUNTRY_NAME}.
   Group items by vendor type (e.g., "Taco Stand", "Pani Puri Cart").

2. CHECK EXISTING: Before adding any item, verify it's not already in:
   - backend/scripts/country_foods/{cc}*.json (look for category: "street_food")
   - backend/migrations/*overrides*.sql (grep for the food name — it may exist in the
     food_nutrition_overrides table even without "street_food" category)
   - If an item exists in EITHER location, SKIP it — do not duplicate

3. For each item, provide ALL 33 columns in this JSON format:
{JSON_FORMAT}

4. Key field values:
   - restaurant_name: Vendor/stall type (e.g., "Pani Puri Cart", "Takoyaki Stand")
   - food_category: ALWAYS "street_food"
   - source: ALWAYS "research"
   - region: "{CC}" (ISO alpha-2)

5. All nutrition values MUST be per 100g:
   - For street food, use academic sources, government food databases, and nutrition research papers
   - Cross-reference multiple sources since street food varies widely
   - Use AVERAGE values from typical street vendor preparation

6. Naming: food_name_normalized = "{vendor_slug}_{item_slug}_{cc}"
   - Example: "taco_stand_al_pastor_mx", "doner_stand_doner_kebab_de"

7. Include cultural context in notes: preparation method, when/where typically eaten,
   cultural significance.

8. variant_names: Include ALL local/regional names and transliterations.
   - Example for pani puri: ["golgappa", "puchka", "gup chup", "phulki"]

9. Output: Write a JSON array to backend/scripts/street_foods/{cc}_street_foods.json

## Expected Output
A JSON array of {EST_ITEMS} items, each with all 33 columns.
Organized by vendor type, covering all common street food in {COUNTRY_NAME}.
```

---

_Last updated: 2026-03-21_
_Maintained by: Claude for FitWiz Project_
