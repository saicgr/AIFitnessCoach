# Chain Restaurants by Country — Tracking & Pipeline

---

## Section 1: Pipeline Instructions (Resume Guide)

**Goal:** Research country-EXCLUSIVE chain restaurant menu items for each of 213 countries. One row per chain per country. Items already in the US chain DB (Big Mac, Whopper, etc.) are SKIPPED — only country-exclusive items are added.

### How to Check Current State

```bash
# See what's been launched
cat backend/scripts/chain_foods/pipeline_log.json | python3 -c "
import json, sys
log = json.load(sys.stdin)
for key, val in sorted(log.get('launched', {}).items()):
    print(f'{key}: {val[\"status\"]}')
"

# Count completed vs remaining
python3 -c "
import json
log = json.load(open('backend/scripts/chain_foods/pipeline_log.json'))
launched = log.get('launched', {})
done = sum(1 for v in launched.values() if v['status'] == 'done')
wip = sum(1 for v in launched.values() if v['status'] == 'launched')
print(f'Done: {done}, In progress: {wip}, Total launched: {len(launched)}')
"

# Check status table in this file for ⏳ / ✅ markers
grep -c '⏳\|✅' chain_restaurants_by_country.md
```

### Pipeline Per Chain+Country

```
STEP 0: Check pipeline_log.json — skip any {chain}_{cc} already listed
  python3 -c "
import json
log = json.load(open('backend/scripts/chain_foods/pipeline_log.json'))
print(list(log['launched'].keys()))
"

STEP 1: Mark status BEFORE launching agent
  → Set status to ⏳ in the status table below
  → Log to pipeline_log.json:
  python3 -c "
import json, datetime
log = json.load(open('backend/scripts/chain_foods/pipeline_log.json'))
key = '{chain_slug}_{cc}'  # e.g. 'mcdonalds_in'
log['launched'][key] = {
    'status': 'launched',
    'launched_at': datetime.datetime.utcnow().isoformat(),
    'chain': '{chain_name}',
    'country': '{country_name}',
    'cc': '{cc}'
}
json.dump(log, open('backend/scripts/chain_foods/pipeline_log.json', 'w'), indent=2)
"

STEP 2: Agent researches country-exclusive items and writes JSON
  → Output: backend/scripts/chain_foods/{chain_slug}_{cc}.json
  → Agent MUST use the JSON format in Section 2 (all 33 columns)
  → Agent MUST skip global items already in US DB (Big Mac, Whopper, etc.)

STEP 3: Merge + generate SQL
  cc="xx"
  python3 -c "
import json, glob, re

# Load all chain JSON files for this country
files = glob.glob(f'backend/scripts/chain_foods/*_{cc}.json')
all_items = []
for f in files:
    items = json.load(open(f))
    all_items.extend(items)

# Deduplicate by food_name_normalized
seen = set()
unique = []
for item in all_items:
    key = item['food_name_normalized']
    if key not in seen:
        seen.add(key)
        unique.append(item)

print(f'Total unique items for {cc}: {len(unique)}')

# Generate SQL (same pattern as country food overrides)
# ... SQL generation logic here ...
"

STEP 4: Mark status as ✅
  → Update status table: ⏳ → ✅
  → Update pipeline_log.json: status → 'done'
  python3 -c "
import json, datetime
log = json.load(open('backend/scripts/chain_foods/pipeline_log.json'))
key = '{chain_slug}_{cc}'
log['launched'][key]['status'] = 'done'
log['launched'][key]['completed_at'] = datetime.datetime.utcnow().isoformat()
json.dump(log, open('backend/scripts/chain_foods/pipeline_log.json', 'w'), indent=2)
"
```

### SQL Generation Notes

- **Migration naming:** `{next_migration_number}_chain_{chain_slug}_{cc}.sql` (e.g., `1870_chain_mcdonalds_in.sql`)
- **Upsert pattern:** Use `ON CONFLICT (food_name_normalized) DO UPDATE` to handle re-runs
- **Column order:** Must match the INSERT column list in migration 273 + 277 + 324 + 1646 columns
- **All values per 100g** — convert from per-serving using `(value / serving_g) * 100`

### Agent Launch Rules

1. **ALWAYS check `pipeline_log.json` before launching** — if `{chain}_{cc}` is already `launched` or `done`, SKIP
2. **ALWAYS mark ⏳ BEFORE launching** — prevents duplicate agents
3. **Max 5 parallel agents** at a time (same as country foods)
4. **Priority order:** Top 30 countries first (Section 6), then alphabetical
5. **Split large chains:** If a chain has 50+ exclusive items in a country, split into 2 agents

---

## Section 2: JSON Format (All 33 Columns from `food_nutrition_overrides`)

Columns sourced from migrations 270, 277, 324, 1646.

Every item in `backend/scripts/chain_foods/{chain_slug}_{cc}.json` must use this exact format:

```json
{
  "food_name_normalized": "mcdonalds_mcaloo_tikki_in",
  "display_name": "McDonald's McAloo Tikki Burger",
  "calories_per_100g": 232,
  "protein_per_100g": 5.8,
  "carbs_per_100g": 28.8,
  "fat_per_100g": 10.3,
  "fiber_per_100g": 1.7,
  "sugar_per_100g": 4.1,
  "default_serving_g": 146,
  "default_weight_per_piece_g": 146,
  "source": "mcdonalds.co.in",
  "variant_names": ["mcaloo tikki", "aloo tikki burger mcd"],
  "notes": "India-exclusive potato patty burger",
  "is_active": true,
  "food_category": "burgers",
  "restaurant_name": "McDonald's",
  "default_count": 1,
  "region": "IN",
  "sodium_mg": 560,
  "cholesterol_mg": 25,
  "saturated_fat_g": 4.1,
  "trans_fat_g": 0.2,
  "potassium_mg": 180,
  "calcium_mg": 80,
  "iron_mg": 2.1,
  "vitamin_a_ug": 15,
  "vitamin_c_mg": 1.5,
  "vitamin_d_iu": 0,
  "magnesium_mg": 22,
  "zinc_mg": 1.0,
  "phosphorus_mg": 120,
  "selenium_ug": 12,
  "omega3_g": 0.1
}
```

### Column Reference

| # | Column | Type | Source Migration | Notes |
|---|--------|------|-----------------|-------|
| 1 | `food_name_normalized` | TEXT NOT NULL UNIQUE | 270 | `{chain_slug}_{item_slug}_{cc}` for exclusive items |
| 2 | `display_name` | TEXT NOT NULL | 270 | User-facing: "McDonald's McAloo Tikki Burger" |
| 3 | `calories_per_100g` | REAL NOT NULL | 270 | Atwater: ≈ prot×4 + carb×4 + fat×9 (±15%) |
| 4 | `protein_per_100g` | REAL NOT NULL | 270 | |
| 5 | `carbs_per_100g` | REAL NOT NULL | 270 | |
| 6 | `fat_per_100g` | REAL NOT NULL | 270 | |
| 7 | `fiber_per_100g` | REAL NOT NULL DEFAULT 0 | 270 | |
| 8 | `sugar_per_100g` | REAL DEFAULT NULL | 270 | |
| 9 | `default_weight_per_piece_g` | REAL DEFAULT NULL | 270 | Weight of one piece |
| 10 | `default_serving_g` | REAL DEFAULT NULL | 270 | Typical serving size |
| 11 | `source` | TEXT DEFAULT 'manual' | 270 | Chain's country domain (e.g., `mcdonalds.co.in`) |
| 12 | `notes` | TEXT DEFAULT NULL | 270 | Brief description, exclusivity note |
| 13 | `variant_names` | TEXT[] DEFAULT NULL | 270 | Alternate names/local spellings |
| 14 | `is_active` | BOOLEAN NOT NULL DEFAULT TRUE | 270 | |
| 15 | `food_category` | TEXT DEFAULT NULL | 277 | burgers, chicken, pizza, drinks, breakfast, etc. |
| 16 | `restaurant_name` | TEXT DEFAULT NULL | 277 | Clean chain name: "McDonald's", "KFC", etc. |
| 17 | `default_count` | INTEGER DEFAULT 1 | 277 | e.g., 6 for 6pc nuggets |
| 18 | `region` | TEXT | 1646 | ISO 3166-1 alpha-2 code (NULL for global items) |
| 19 | `sodium_mg` | REAL DEFAULT NULL | 324 | |
| 20 | `cholesterol_mg` | REAL DEFAULT NULL | 324 | |
| 21 | `saturated_fat_g` | REAL DEFAULT NULL | 324 | |
| 22 | `trans_fat_g` | REAL DEFAULT NULL | 324 | |
| 23 | `potassium_mg` | REAL DEFAULT NULL | 324 | |
| 24 | `calcium_mg` | REAL DEFAULT NULL | 324 | |
| 25 | `iron_mg` | REAL DEFAULT NULL | 324 | |
| 26 | `vitamin_a_ug` | REAL DEFAULT NULL | 324 | |
| 27 | `vitamin_c_mg` | REAL DEFAULT NULL | 324 | |
| 28 | `vitamin_d_iu` | REAL DEFAULT NULL | 324 | |
| 29 | `magnesium_mg` | REAL DEFAULT NULL | 324 | |
| 30 | `zinc_mg` | REAL DEFAULT NULL | 324 | |
| 31 | `phosphorus_mg` | REAL DEFAULT NULL | 324 | |
| 32 | `selenium_ug` | REAL DEFAULT NULL | 324 | |
| 33 | `omega3_g` | REAL DEFAULT NULL | 324 | |

### Naming Conventions

- `food_name_normalized`: `{chain_slug}_{item_slug}_{cc}` — e.g., `mcdonalds_mcaloo_tikki_in`, `kfc_rice_bowl_jp`
- `chain_slug`: lowercase, underscores — `mcdonalds`, `burger_king`, `kfc`, `pizza_hut`, `taco_bell`
- `item_slug`: lowercase, underscores, no special chars — `mcaloo_tikki`, `teriyaki_mcburger`
- `{cc}`: ISO 3166-1 alpha-2 lowercase — `in`, `jp`, `gb`, `de`
- Global items (Big Mac, etc.) have NO `_{cc}` suffix and `region = NULL`
- `source`: Use chain's country-specific domain — `mcdonalds.co.in`, `kfc.co.jp`, `burgerking.de`

### Validation Rules

1. **Atwater check:** `calories_per_100g ≈ protein_per_100g×4 + carbs_per_100g×4 + fat_per_100g×9` (±15%)
2. **Per 100g:** All macro/micro values MUST be per 100g, not per serving
3. **Serving conversion:** `per_100g_value = (per_serving_value / serving_weight_g) × 100`
4. **Micronutrients:** Set to `null` if unknown, but TRY to fill from chain nutrition PDFs
5. **No duplicates:** Check `food_name_normalized` is unique globally

---

## Section 3: Dedup Strategy

### Global vs Country-Exclusive Items

| Type | `food_name_normalized` | `region` | Example |
|------|----------------------|----------|---------|
| **Global item** (same everywhere) | `mcdonalds_big_mac` | `NULL` | Big Mac — same recipe worldwide |
| **Country-exclusive item** | `mcdonalds_mcaloo_tikki_in` | `IN` | McAloo Tikki — India only |
| **Same item, different nutrition** | `mcdonalds_coca_cola_jp` | `JP` | Coke in Japan (different sugar formula) |

### Rules

1. **Skip global items:** Big Mac, Whopper, KFC Original Recipe, Subway Italian BMT, etc. — these are already in migrations 272–295, 1578, 1581, 1583. Agents MUST NOT re-add them.
2. **Country-exclusive items only:** Items that exist ONLY in that country's menu or have significantly different recipes/nutrition.
3. **Reformulated items:** If the same-named item has >10% different calories in another country (e.g., different oil, different sugar), create a country-specific entry with `_{cc}` suffix.
4. **Regional limited-time items:** Include if they've been on the menu for >1 year (not seasonal promos).
5. **Cross-country dedup:** If India and Pakistan both have McAloo Tikki with identical nutrition, create ONE entry with `region = 'IN'` and note the overlap in `notes`. Do NOT create a `_pk` duplicate.

### Checking Existing DB Before Adding

```bash
# Check if an item already exists in migrations
grep -ri "food_name_normalized" backend/migrations/27[2-9]*.sql backend/migrations/1578*.sql backend/migrations/1581*.sql backend/migrations/1583*.sql | grep -i "big_mac"
```

---

## Section 4: Master Status Table (One Row Per Chain Per Country)

### Legend
- ✅ = Done (items researched, JSON written, SQL generated)
- ⏳ = Agent currently working
- (blank) = Not started

Sorted by country code (alphabetical). PRIORITY = research order (1–30 by fast food market size, blank = lower priority).

| STATUS | CODE | COUNTRY | CHAIN | EST. EXCLUSIVE ITEMS | MIGRATION | PRIORITY |
|--------|------|---------|-------|---------------------|-----------|----------|
|  | AE | United Arab Emirates | Burger King | ~10 | — | 17 |
|  | AE | United Arab Emirates | Domino's | ~10 | — | 17 |
|  | AE | United Arab Emirates | KFC | ~10 | — | 17 |
|  | AE | United Arab Emirates | McDonald's | ~15 | — | 17 |
|  | AE | United Arab Emirates | Shake Shack | ~10 | — | 17 |
|  | AE | United Arab Emirates | Starbucks | ~10 | — | 17 |
|  | AE | United Arab Emirates | Subway | ~10 | — | 17 |
|  | AF | Afghanistan | KFC | ~5 | — |  |
|  | AL | Albania | McDonald's | ~5 | — |  |
|  | AR | Argentina | Burger King | ~10 | — |  |
|  | AR | Argentina | KFC | ~5 | — |  |
|  | AR | Argentina | McDonald's | ~15 | — |  |
|  | AR | Argentina | Starbucks | ~10 | — |  |
|  | AT | Austria | Burger King | ~10 | — |  |
|  | AT | Austria | KFC | ~5 | — |  |
|  | AT | Austria | McDonald's | ~10 | — |  |
|  | AU | Australia | Domino's | ~15 | — | 8 |
|  | AU | Australia | Hungry Jack's | ~25 | — | 8 |
|  | AU | Australia | KFC | ~15 | — | 8 |
|  | AU | Australia | McDonald's | ~20 | — | 8 |
|  | AU | Australia | Nando's | ~15 | — | 8 |
|  | AU | Australia | Pizza Hut | ~10 | — | 8 |
|  | AU | Australia | Starbucks | ~10 | — | 8 |
|  | AU | Australia | Subway | ~10 | — | 8 |
|  | BD | Bangladesh | KFC | ~10 | — |  |
|  | BD | Bangladesh | Pizza Hut | ~5 | — |  |
|  | BE | Belgium | Burger King | ~10 | — |  |
|  | BE | Belgium | KFC | ~5 | — |  |
|  | BE | Belgium | McDonald's | ~10 | — |  |
|  | BR | Brazil | Bob's | ~25 | — | 10 |
|  | BR | Brazil | Burger King | ~15 | — | 10 |
|  | BR | Brazil | Domino's | ~10 | — | 10 |
|  | BR | Brazil | KFC | ~10 | — | 10 |
|  | BR | Brazil | McDonald's | ~25 | — | 10 |
|  | BR | Brazil | Pizza Hut | ~10 | — | 10 |
|  | BR | Brazil | Starbucks | ~15 | — | 10 |
|  | BR | Brazil | Subway | ~10 | — | 10 |
|  | CA | Canada | Burger King | ~10 | — | 7 |
|  | CA | Canada | Domino's | ~10 | — | 7 |
|  | CA | Canada | KFC | ~10 | — | 7 |
|  | CA | Canada | McDonald's | ~15 | — | 7 |
|  | CA | Canada | Popeyes | ~10 | — | 7 |
|  | CA | Canada | Starbucks | ~10 | — | 7 |
|  | CA | Canada | Subway | ~10 | — | 7 |
|  | CA | Canada | Tim Hortons | ~40 | — | 7 |
|  | CH | Switzerland | McDonald's | ~10 | — |  |
|  | CL | Chile | Burger King | ~5 | — |  |
|  | CL | Chile | KFC | ~5 | — |  |
|  | CL | Chile | McDonald's | ~10 | — |  |
|  | CN | China | Burger King | ~10 | — | 2 |
|  | CN | China | Domino's | ~10 | — | 2 |
|  | CN | China | Dunkin' | ~10 | — | 2 |
|  | CN | China | KFC | ~40 | — | 2 |
|  | CN | China | McDonald's | ~35 | — | 2 |
|  | CN | China | Pizza Hut | ~20 | — | 2 |
|  | CN | China | Starbucks | ~25 | — | 2 |
|  | CN | China | Subway | ~10 | — | 2 |
|  | CO | Colombia | Burger King | ~5 | — |  |
|  | CO | Colombia | KFC | ~5 | — |  |
|  | CO | Colombia | McDonald's | ~10 | — |  |
|  | CZ | Czech Republic | Burger King | ~5 | — |  |
|  | CZ | Czech Republic | KFC | ~10 | — |  |
|  | CZ | Czech Republic | McDonald's | ~10 | — |  |
|  | DE | Germany | Burger King | ~15 | — | 5 |
|  | DE | Germany | Domino's | ~10 | — | 5 |
|  | DE | Germany | Dunkin' | ~10 | — | 5 |
|  | DE | Germany | KFC | ~10 | — | 5 |
|  | DE | Germany | McDonald's | ~20 | — | 5 |
|  | DE | Germany | Starbucks | ~15 | — | 5 |
|  | DE | Germany | Subway | ~10 | — | 5 |
|  | DK | Denmark | Burger King | ~5 | — |  |
|  | DK | Denmark | McDonald's | ~10 | — |  |
|  | DZ | Algeria | KFC | ~5 | — |  |
|  | EG | Egypt | Burger King | ~10 | — | 26 |
|  | EG | Egypt | Domino's | ~10 | — | 26 |
|  | EG | Egypt | KFC | ~10 | — | 26 |
|  | EG | Egypt | McDonald's | ~15 | — | 26 |
|  | EG | Egypt | Pizza Hut | ~10 | — | 26 |
|  | ES | Spain | Burger King | ~10 | — | 14 |
|  | ES | Spain | Domino's | ~10 | — | 14 |
|  | ES | Spain | KFC | ~10 | — | 14 |
|  | ES | Spain | McDonald's | ~15 | — | 14 |
|  | ES | Spain | Starbucks | ~10 | — | 14 |
|  | ES | Spain | Subway | ~10 | — | 14 |
|  | FI | Finland | Burger King | ~5 | — |  |
|  | FI | Finland | Hesburger | ~20 | — |  |
|  | FI | Finland | McDonald's | ~10 | — |  |
|  | FR | France | Burger King | ~15 | — | 6 |
|  | FR | France | Domino's | ~10 | — | 6 |
|  | FR | France | KFC | ~10 | — | 6 |
|  | FR | France | McDonald's | ~25 | — | 6 |
|  | FR | France | Pizza Hut | ~10 | — | 6 |
|  | FR | France | Starbucks | ~15 | — | 6 |
|  | FR | France | Subway | ~10 | — | 6 |
|  | GB | United Kingdom | Burger King | ~10 | — | 4 |
|  | GB | United Kingdom | Costa Coffee | ~20 | — | 4 |
|  | GB | United Kingdom | Domino's | ~15 | — | 4 |
|  | GB | United Kingdom | Greggs | ~40 | — | 4 |
|  | GB | United Kingdom | KFC | ~15 | — | 4 |
|  | GB | United Kingdom | McDonald's | ~20 | — | 4 |
|  | GB | United Kingdom | Nando's | ~25 | — | 4 |
|  | GB | United Kingdom | Pizza Hut | ~10 | — | 4 |
|  | GB | United Kingdom | Starbucks | ~15 | — | 4 |
|  | GB | United Kingdom | Subway | ~10 | — | 4 |
|  | GR | Greece | KFC | ~5 | — |  |
|  | GR | Greece | McDonald's | ~10 | — |  |
|  | HK | Hong Kong | KFC | ~15 | — |  |
|  | HK | Hong Kong | McDonald's | ~25 | — |  |
|  | HU | Hungary | Burger King | ~5 | — |  |
|  | HU | Hungary | KFC | ~5 | — |  |
|  | HU | Hungary | McDonald's | ~10 | — |  |
|  | ID | Indonesia | Burger King | ~10 | — | 19 |
|  | ID | Indonesia | Domino's | ~10 | — | 19 |
|  | ID | Indonesia | Jollibee | ~10 | — | 19 |
|  | ID | Indonesia | KFC | ~20 | — | 19 |
|  | ID | Indonesia | McDonald's | ~25 | — | 19 |
|  | ID | Indonesia | Pizza Hut | ~15 | — | 19 |
|  | ID | Indonesia | Starbucks | ~15 | — | 19 |
|  | IE | Ireland | Burger King | ~5 | — |  |
|  | IE | Ireland | KFC | ~5 | — |  |
|  | IE | Ireland | McDonald's | ~10 | — |  |
|  | IL | Israel | Burger King | ~10 | — |  |
|  | IL | Israel | KFC | ~5 | — |  |
|  | IL | Israel | McDonald's | ~15 | — |  |
|  | IN | India | Burger King | ~15 | — | 9 |
|  | IN | India | Domino's | ~35 | — | 9 |
|  | IN | India | Dunkin' | ~15 | — | 9 |
|  | IN | India | KFC | ~25 | — | 9 |
|  | IN | India | McDonald's | ~30 | — | 9 |
|  | IN | India | Pizza Hut | ~20 | — | 9 |
|  | IN | India | Starbucks | ~20 | — | 9 |
|  | IN | India | Subway | ~15 | — | 9 |
|  | IN | India | Taco Bell | ~10 | — | 9 |
|  | IN | India | Wendy's | ~5 | — | 9 |
|  | IT | Italy | Burger King | ~10 | — | 13 |
|  | IT | Italy | Domino's | ~10 | — | 13 |
|  | IT | Italy | KFC | ~5 | — | 13 |
|  | IT | Italy | McDonald's | ~20 | — | 13 |
|  | IT | Italy | Starbucks | ~15 | — | 13 |
|  | IT | Italy | Subway | ~10 | — | 13 |
|  | JM | Jamaica | KFC | ~10 | — |  |
|  | JO | Jordan | McDonald's | ~10 | — |  |
|  | JP | Japan | Burger King | ~10 | — | 3 |
|  | JP | Japan | CoCo Ichibanya | ~20 | — | 3 |
|  | JP | Japan | Domino's | ~15 | — | 3 |
|  | JP | Japan | KFC | ~20 | — | 3 |
|  | JP | Japan | Lotteria | ~20 | — | 3 |
|  | JP | Japan | McDonald's | ~40 | — | 3 |
|  | JP | Japan | MOS Burger | ~30 | — | 3 |
|  | JP | Japan | Starbucks | ~25 | — | 3 |
|  | JP | Japan | Subway | ~10 | — | 3 |
|  | JP | Japan | Yoshinoya | ~25 | — | 3 |
|  | KE | Kenya | KFC | ~10 | — |  |
|  | KR | South Korea | Burger King | ~10 | — | 11 |
|  | KR | South Korea | Domino's | ~15 | — | 11 |
|  | KR | South Korea | KFC | ~15 | — | 11 |
|  | KR | South Korea | Lotteria | ~25 | — | 11 |
|  | KR | South Korea | McDonald's | ~25 | — | 11 |
|  | KR | South Korea | Pizza Hut | ~10 | — | 11 |
|  | KR | South Korea | Starbucks | ~20 | — | 11 |
|  | KR | South Korea | Subway | ~10 | — | 11 |
|  | KZ | Kazakhstan | KFC | ~5 | — |  |
|  | KZ | Kazakhstan | McDonald's | ~5 | — |  |
|  | LB | Lebanon | McDonald's | ~10 | — |  |
|  | MA | Morocco | McDonald's | ~10 | — |  |
|  | MX | Mexico | Burger King | ~10 | — | 12 |
|  | MX | Mexico | Carl's Jr | ~10 | — | 12 |
|  | MX | Mexico | Domino's | ~15 | — | 12 |
|  | MX | Mexico | KFC | ~10 | — | 12 |
|  | MX | Mexico | McDonald's | ~15 | — | 12 |
|  | MX | Mexico | Starbucks | ~10 | — | 12 |
|  | MX | Mexico | Subway | ~10 | — | 12 |
|  | MY | Malaysia | Burger King | ~10 | — | 22 |
|  | MY | Malaysia | KFC | ~15 | — | 22 |
|  | MY | Malaysia | McDonald's | ~20 | — | 22 |
|  | MY | Malaysia | Nando's | ~10 | — | 22 |
|  | MY | Malaysia | Pizza Hut | ~10 | — | 22 |
|  | MY | Malaysia | Starbucks | ~15 | — | 22 |
|  | MY | Malaysia | Subway | ~10 | — | 22 |
|  | NG | Nigeria | Chicken Republic | ~20 | — | 25 |
|  | NG | Nigeria | Domino's | ~10 | — | 25 |
|  | NG | Nigeria | KFC | ~10 | — | 25 |
|  | NG | Nigeria | Mr Biggs | ~15 | — | 25 |
|  | NL | Netherlands | Burger King | ~10 | — | 28 |
|  | NL | Netherlands | Domino's | ~10 | — | 28 |
|  | NL | Netherlands | FEBO | ~20 | — | 28 |
|  | NL | Netherlands | KFC | ~10 | — | 28 |
|  | NL | Netherlands | McDonald's | ~15 | — | 28 |
|  | NL | Netherlands | Subway | ~10 | — | 28 |
|  | NO | Norway | McDonald's | ~10 | — |  |
|  | NZ | New Zealand | KFC | ~10 | — |  |
|  | NZ | New Zealand | McDonald's | ~15 | — |  |
|  | PE | Peru | KFC | ~5 | — |  |
|  | PE | Peru | McDonald's | ~10 | — |  |
|  | PH | Philippines | Burger King | ~10 | — | 21 |
|  | PH | Philippines | Domino's | ~10 | — | 21 |
|  | PH | Philippines | Jollibee | ~35 | — | 21 |
|  | PH | Philippines | KFC | ~15 | — | 21 |
|  | PH | Philippines | McDonald's | ~20 | — | 21 |
|  | PH | Philippines | Pizza Hut | ~10 | — | 21 |
|  | PH | Philippines | Starbucks | ~10 | — | 21 |
|  | PK | Pakistan | Burger King | ~10 | — | 27 |
|  | PK | Pakistan | Domino's | ~10 | — | 27 |
|  | PK | Pakistan | KFC | ~15 | — | 27 |
|  | PK | Pakistan | McDonald's | ~20 | — | 27 |
|  | PK | Pakistan | Pizza Hut | ~10 | — | 27 |
|  | PK | Pakistan | Subway | ~10 | — | 27 |
|  | PL | Poland | Burger King | ~10 | — | 30 |
|  | PL | Poland | Domino's | ~10 | — | 30 |
|  | PL | Poland | KFC | ~10 | — | 30 |
|  | PL | Poland | McDonald's | ~15 | — | 30 |
|  | PL | Poland | Subway | ~10 | — | 30 |
|  | PT | Portugal | KFC | ~5 | — |  |
|  | PT | Portugal | McDonald's | ~10 | — |  |
|  | RO | Romania | KFC | ~10 | — |  |
|  | RO | Romania | McDonald's | ~10 | — |  |
|  | RU | Russia | Burger King | ~15 | — | 15 |
|  | RU | Russia | Domino's | ~10 | — | 15 |
|  | RU | Russia | KFC | ~15 | — | 15 |
|  | RU | Russia | Subway | ~10 | — | 15 |
|  | RU | Russia | Vkusno i Tochka | ~40 | — | 15 |
|  | SA | Saudi Arabia | Al Baik | ~25 | — | 16 |
|  | SA | Saudi Arabia | Burger King | ~10 | — | 16 |
|  | SA | Saudi Arabia | Domino's | ~10 | — | 16 |
|  | SA | Saudi Arabia | KFC | ~15 | — | 16 |
|  | SA | Saudi Arabia | McDonald's | ~20 | — | 16 |
|  | SA | Saudi Arabia | Starbucks | ~10 | — | 16 |
|  | SA | Saudi Arabia | Subway | ~10 | — | 16 |
|  | SE | Sweden | Burger King | ~10 | — | 29 |
|  | SE | Sweden | KFC | ~5 | — | 29 |
|  | SE | Sweden | Max Burgers | ~25 | — | 29 |
|  | SE | Sweden | McDonald's | ~15 | — | 29 |
|  | SE | Sweden | Subway | ~10 | — | 29 |
|  | SG | Singapore | Burger King | ~10 | — | 23 |
|  | SG | Singapore | Jollibee | ~10 | — | 23 |
|  | SG | Singapore | KFC | ~10 | — | 23 |
|  | SG | Singapore | McDonald's | ~20 | — | 23 |
|  | SG | Singapore | Starbucks | ~15 | — | 23 |
|  | SG | Singapore | Subway | ~10 | — | 23 |
|  | TH | Thailand | Burger King | ~10 | — | 20 |
|  | TH | Thailand | KFC | ~15 | — | 20 |
|  | TH | Thailand | McDonald's | ~20 | — | 20 |
|  | TH | Thailand | MK Restaurants | ~20 | — | 20 |
|  | TH | Thailand | Pizza Hut | ~10 | — | 20 |
|  | TH | Thailand | Starbucks | ~15 | — | 20 |
|  | TH | Thailand | Subway | ~10 | — | 20 |
|  | TR | Turkey | Burger King | ~15 | — | 18 |
|  | TR | Turkey | Domino's | ~10 | — | 18 |
|  | TR | Turkey | KFC | ~10 | — | 18 |
|  | TR | Turkey | McDonald's | ~15 | — | 18 |
|  | TR | Turkey | Starbucks | ~10 | — | 18 |
|  | TR | Turkey | Subway | ~10 | — | 18 |
|  | TW | Taiwan | KFC | ~10 | — |  |
|  | TW | Taiwan | McDonald's | ~20 | — |  |
|  | TW | Taiwan | MOS Burger | ~15 | — |  |
|  | UA | Ukraine | KFC | ~5 | — |  |
|  | UA | Ukraine | McDonald's | ~10 | — |  |
| ✅ | US | United States | Applebee's | 35+ | 274 | 1 |
| ✅ | US | United States | Baskin-Robbins | 20+ | 275 | 1 |
| ✅ | US | United States | Burger King | 40+ | 273 | 1 |
| ✅ | US | United States | Cheesecake Factory | 40+ | 274 | 1 |
| ✅ | US | United States | Chick-fil-A | 50+ | 273 | 1 |
| ✅ | US | United States | Chili's | 35+ | 274 | 1 |
| ✅ | US | United States | Chipotle | 20+ | 273 | 1 |
| ✅ | US | United States | Cold Stone | 15+ | 275 | 1 |
| ✅ | US | United States | Cracker Barrel | 25+ | 274 | 1 |
| ✅ | US | United States | Dairy Queen | 25+ | 275 | 1 |
| ✅ | US | United States | Del Taco | 20+ | 276 | 1 |
| ✅ | US | United States | Denny's | 30+ | 274 | 1 |
| ✅ | US | United States | Domino's | 40+ | 273 | 1 |
| ✅ | US | United States | Dunkin' | 50+ | 273 | 1 |
| ✅ | US | United States | Five Guys | 25+ | 274 | 1 |
| ✅ | US | United States | IHOP | 30+ | 274 | 1 |
| ✅ | US | United States | Jack in the Box | 30+ | 276 | 1 |
| ✅ | US | United States | KFC | 30+ | 273 | 1 |
| ✅ | US | United States | Krispy Kreme | 15+ | 275 | 1 |
| ✅ | US | United States | Little Caesars | 15+ | 275 | 1 |
| ✅ | US | United States | McDonald's | 80+ | 273 | 1 |
| ✅ | US | United States | Olive Garden | 35+ | 274 | 1 |
| ✅ | US | United States | Outback Steakhouse | 30+ | 274 | 1 |
| ✅ | US | United States | Panda Express | 20+ | 276 | 1 |
| ✅ | US | United States | Papa John's | 20+ | 275 | 1 |
| ✅ | US | United States | Pizza Hut | 35+ | 273 | 1 |
| ✅ | US | United States | Popeyes | 30+ | 273 | 1 |
| ✅ | US | United States | Qdoba | 15+ | 276 | 1 |
| ✅ | US | United States | Red Lobster | 25+ | 274 | 1 |
| ✅ | US | United States | Sonic | 40+ | 273 | 1 |
| ✅ | US | United States | Starbucks | 60+ | 273 | 1 |
| ✅ | US | United States | Subway | 35+ | 273 | 1 |
| ✅ | US | United States | Taco Bell | 50+ | 273 | 1 |
| ✅ | US | United States | TGI Friday's | 30+ | 274 | 1 |
| ✅ | US | United States | Wendy's | 45+ | 273 | 1 |
| ✅ | US | United States | Wingstop | 15+ | 276 | 1 |
|  | VN | Vietnam | Jollibee | ~10 | — |  |
|  | VN | Vietnam | KFC | ~10 | — |  |
|  | VN | Vietnam | McDonald's | ~10 | — |  |
|  | ZA | South Africa | Burger King | ~10 | — | 24 |
|  | ZA | South Africa | KFC | ~15 | — | 24 |
|  | ZA | South Africa | McDonald's | ~15 | — | 24 |
|  | ZA | South Africa | Nando's | ~25 | — | 24 |
|  | ZA | South Africa | Starbucks | ~10 | — | 24 |
|  | ZA | South Africa | Steers | ~20 | — | 24 |
|  | ZA | South Africa | Subway | ~10 | — | 24 |
|  | ZA | South Africa | Chicken Licken | ~20 | — | 24 |
|  | ZA | South Africa | Wimpy | ~25 | — | 24 |
|  | ZA | South Africa | Spur | ~20 | — | 24 |
|  | ZA | South Africa | Debonairs Pizza | ~15 | — | 24 |
|  | AE | United Arab Emirates | Pret a Manger | ~10 | — | 17 |
|  | AE | United Arab Emirates | Raising Cane's | ~10 | — | 17 |
|  | AE | United Arab Emirates | P.F. Chang's | ~10 | — | 17 |
|  | AE | United Arab Emirates | Herfy | ~5 | — | 17 |
|  | AE | United Arab Emirates | Wagamama | ~10 | — | 17 |
|  | AE | United Arab Emirates | TGI Friday's | ~10 | — | 17 |
|  | AU | Australia | Chatime | ~15 | — | 8 |
|  | AU | Australia | Gong Cha | ~10 | — | 8 |
|  | AU | Australia | Wingstop | ~10 | — | 8 |
|  | BR | Brazil | Giraffas | ~25 | — | 10 |
|  | BR | Brazil | Spoleto | ~20 | — | 10 |
|  | BR | Brazil | Madero | ~15 | — | 10 |
|  | BR | Brazil | Habib's | ~25 | — | 10 |
|  | BR | Brazil | Outback Steakhouse | ~10 | — | 10 |
|  | CA | Canada | Pret a Manger | ~5 | — | 7 |
|  | CA | Canada | Paris Baguette | ~10 | — | 7 |
|  | CA | Canada | Chatime | ~15 | — | 7 |
|  | CA | Canada | Dairy Queen | ~15 | — | 7 |
|  | CA | Canada | Papa John's | ~10 | — | 7 |
|  | CA | Canada | Little Caesars | ~10 | — | 7 |
|  | CA | Canada | Baskin-Robbins | ~10 | — | 7 |
|  | CN | China | Mixue | ~50 | — | 2 |
|  | CN | China | Luckin Coffee | ~50 | — | 2 |
|  | CN | China | Wallace (Hua Lai Shi) | ~50 | — | 2 |
|  | CN | China | Dicos (De Ke Shi) | ~30 | — | 2 |
|  | CN | China | Chagee | ~40 | — | 2 |
|  | CN | China | Auntea Jenny | ~40 | — | 2 |
|  | CN | China | Paris Baguette | ~15 | — | 2 |
|  | CN | China | Tous les Jours | ~10 | — | 2 |
|  | DE | Germany | Nordsee | ~25 | — | 5 |
|  | DE | Germany | Pret a Manger | ~5 | — | 5 |
|  | DE | Germany | Simit Sarayi | ~5 | — | 5 |
|  | EG | Egypt | TGI Friday's | ~5 | — | 26 |
|  | ES | Spain | Pret a Manger | ~5 | — | 14 |
|  | FR | France | Pret a Manger | ~10 | — | 6 |
|  | FR | France | Paris Baguette | ~5 | — | 6 |
|  | GB | United Kingdom | Pret a Manger | ~30 | — | 4 |
|  | GB | United Kingdom | Wagamama | ~20 | — | 4 |
|  | GB | United Kingdom | Wingstop | ~15 | — | 4 |
|  | GB | United Kingdom | Papa John's | ~15 | — | 4 |
|  | GB | United Kingdom | Krispy Kreme | ~10 | — | 4 |
|  | GB | United Kingdom | Chatime | ~10 | — | 4 |
|  | GB | United Kingdom | Simit Sarayi | ~5 | — | 4 |
|  | ID | Indonesia | Mixue | ~30 | — | 19 |
|  | ID | Indonesia | Richeese Factory | ~20 | — | 19 |
|  | ID | Indonesia | Chatime | ~15 | — | 19 |
|  | ID | Indonesia | Wingstop | ~10 | — | 19 |
|  | ID | Indonesia | The Pizza Company | ~5 | — | 19 |
|  | IN | India | Pret a Manger | ~10 | — | 9 |
|  | IN | India | Haldiram's | ~15 | — | 9 |
|  | IN | India | Wow! Momo | ~20 | — | 9 |
|  | IN | India | Chai Point | ~10 | — | 9 |
|  | IN | India | Baskin-Robbins | ~15 | — | 9 |
|  | IN | India | Chatime | ~10 | — | 9 |
|  | IT | Italy | Pret a Manger | ~5 | — | 13 |
|  | JP | Japan | Matsuya | ~30 | — | 3 |
|  | JP | Japan | Ootoya | ~15 | — | 3 |
|  | JP | Japan | Sukiya | ~30 | — | 3 |
|  | JP | Japan | Mixue | ~15 | — | 3 |
|  | JP | Japan | Paris Baguette | ~5 | — | 3 |
|  | JP | Japan | Baskin-Robbins | ~20 | — | 3 |
|  | JP | Japan | Krispy Kreme | ~10 | — | 3 |
|  | JP | Japan | Gong Cha | ~15 | — | 3 |
|  | JP | Japan | Denny's | ~15 | — | 3 |
|  | JP | Japan | Outback Steakhouse | ~10 | — | 3 |
|  | KR | South Korea | BBQ Chicken | ~25 | — | 11 |
|  | KR | South Korea | BHC Chicken | ~25 | — | 11 |
|  | KR | South Korea | Pelicana Chicken | ~20 | — | 11 |
|  | KR | South Korea | Nene Chicken | ~20 | — | 11 |
|  | KR | South Korea | Kyochon Chicken | ~15 | — | 11 |
|  | KR | South Korea | Paris Baguette | ~30 | — | 11 |
|  | KR | South Korea | Tous les Jours | ~20 | — | 11 |
|  | KR | South Korea | Gong Cha | ~15 | — | 11 |
|  | KR | South Korea | Baskin-Robbins | ~20 | — | 11 |
|  | KR | South Korea | Papa John's | ~10 | — | 11 |
|  | KR | South Korea | TGI Friday's | ~10 | — | 11 |
|  | KR | South Korea | Outback Steakhouse | ~10 | — | 11 |
|  | MX | Mexico | Wingstop | ~15 | — | 12 |
|  | MX | Mexico | Little Caesars | ~15 | — | 12 |
|  | MX | Mexico | IHOP | ~10 | — | 12 |
|  | MX | Mexico | Denny's | ~10 | — | 12 |
|  | MX | Mexico | P.F. Chang's | ~5 | — | 12 |
|  | MX | Mexico | Papa John's | ~10 | — | 12 |
|  | MX | Mexico | Dairy Queen | ~10 | — | 12 |
|  | MX | Mexico | Sukiya | ~10 | — | 12 |
|  | MY | Malaysia | Mixue | ~20 | — | 22 |
|  | MY | Malaysia | Chagee | ~15 | — | 22 |
|  | MY | Malaysia | Chatime | ~15 | — | 22 |
|  | MY | Malaysia | Gong Cha | ~10 | — | 22 |
|  | MY | Malaysia | Wingstop | ~10 | — | 22 |
|  | MY | Malaysia | Richeese Factory | ~10 | — | 22 |
|  | MY | Malaysia | Tous les Jours | ~5 | — | 22 |
|  | MY | Malaysia | The Pizza Company | ~5 | — | 22 |
|  | NG | Nigeria | Debonairs Pizza | ~10 | — | 25 |
|  | NL | Netherlands | Wingstop | ~10 | — | 28 |
|  | NL | Netherlands | Pret a Manger | ~5 | — | 28 |
|  | NL | Netherlands | Simit Sarayi | ~5 | — | 28 |
|  | PH | Philippines | Chowking | ~25 | — | 21 |
|  | PH | Philippines | Mang Inasal | ~25 | — | 21 |
|  | PH | Philippines | Greenwich Pizza | ~15 | — | 21 |
|  | PH | Philippines | Goldilocks | ~15 | — | 21 |
|  | PH | Philippines | Mixue | ~15 | — | 21 |
|  | PH | Philippines | Wingstop | ~10 | — | 21 |
|  | PH | Philippines | Chatime | ~10 | — | 21 |
|  | PK | Pakistan | Baskin-Robbins | ~5 | — | 27 |
|  | SA | Saudi Arabia | Herfy | ~25 | — | 16 |
|  | SA | Saudi Arabia | Raising Cane's | ~15 | — | 16 |
|  | SA | Saudi Arabia | TGI Friday's | ~10 | — | 16 |
|  | SA | Saudi Arabia | Papa John's | ~10 | — | 16 |
|  | SA | Saudi Arabia | Baskin-Robbins | ~10 | — | 16 |
|  | SA | Saudi Arabia | Krispy Kreme | ~10 | — | 16 |
|  | SA | Saudi Arabia | P.F. Chang's | ~5 | — | 16 |
|  | SA | Saudi Arabia | Pret a Manger | ~5 | — | 16 |
|  | SG | Singapore | Mixue | ~15 | — | 23 |
|  | SG | Singapore | Chagee | ~10 | — | 23 |
|  | SG | Singapore | Paris Baguette | ~10 | — | 23 |
|  | SG | Singapore | Chatime | ~10 | — | 23 |
|  | SG | Singapore | Gong Cha | ~10 | — | 23 |
|  | SG | Singapore | Wingstop | ~10 | — | 23 |
|  | SG | Singapore | Pret a Manger | ~5 | — | 23 |
|  | SE | Sweden | Simit Sarayi | ~5 | — | 29 |
|  | TH | Thailand | Mixue | ~20 | — | 20 |
|  | TH | Thailand | Sukiya | ~10 | — | 20 |
|  | TH | Thailand | The Pizza Company | ~20 | — | 20 |
|  | TH | Thailand | Chatime | ~10 | — | 20 |
|  | TH | Thailand | Baskin-Robbins | ~10 | — | 20 |
|  | TH | Thailand | Dairy Queen | ~10 | — | 20 |
|  | TR | Turkey | Simit Sarayi | ~15 | — | 18 |
|  | TR | Turkey | Kofteci Yusuf | ~10 | — | 18 |

_New rows added as chains are confirmed to operate in additional countries._

---

## Section 5: Agent Prompt Template

Use this template when launching research agents for a specific chain+country combo:

```
You are a nutrition research agent for the Zealova fitness app.

## Task
Research country-EXCLUSIVE menu items for {CHAIN_NAME} in {COUNTRY_NAME} ({CC}).

## Rules
1. ONLY include items that are EXCLUSIVE to {COUNTRY_NAME} or have significantly different
   recipes/nutrition compared to the US menu. DO NOT include global items like:
   - McDonald's: Big Mac, Quarter Pounder, McChicken, McNuggets, Filet-O-Fish, Egg McMuffin
   - KFC: Original Recipe, Zinger, Popcorn Chicken, Coleslaw
   - Burger King: Whopper, Chicken Royale, Onion Rings
   - Subway: Italian BMT, Meatball Marinara, Turkey Breast
   - Starbucks: Caffe Latte, Cappuccino, Frappuccino (base flavors)
   - (etc. — skip anything available in the US with same recipe)

2. Research the chain's COUNTRY-SPECIFIC website: {CHAIN_DOMAIN}
   - Look for nutrition PDFs, allergen guides, menu pages
   - Cross-reference with local food blogs, nutrition databases

3. For each item, provide ALL 33 columns in this JSON format:
{JSON_FORMAT}

4. All nutrition values MUST be per 100g:
   - Convert: per_100g = (per_serving_value / serving_weight_g) × 100
   - Validate: calories ≈ protein×4 + carbs×4 + fat×9 (±15%)

5. Micronutrients: Fill from chain nutrition PDFs when available. Set to null if unknown.

6. Naming: food_name_normalized = "{chain_slug}_{item_slug}_{cc}"
   - Example: "mcdonalds_mcaloo_tikki_in"

7. Output: Write a JSON array to backend/scripts/chain_foods/{chain_slug}_{cc}.json

## Expected Output
A JSON array of {EST_ITEMS} items, each with all 33 columns.
```

---

_Last updated: 2026-03-21_
_Maintained by: Claude for Zealova Project_
