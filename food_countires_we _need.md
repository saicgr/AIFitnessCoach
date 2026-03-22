# Country Food Override Tracking

---

## Pipeline Instructions (Resume Guide)

**Goal:** 1000 authentic foods per country → SQL migration in `backend/migrations/`

### JSON Format
Every food object must follow this exact structure:
```json
{
  "name": "Food Name",
  "cal": 250,
  "prot": 12.0,
  "carb": 30.0,
  "fat": 8.0,
  "fiber": 2.0,
  "sugar": 3.0,
  "serving_g": 200,
  "piece_g": null,
  "category": "traditional",
  "notes": "Brief cultural/historical description",
  "variants": ["alternative name", "local spelling"]
}
```
- All nutrition values are **per 100g**
- Atwater validation: `cal ≈ prot×4 + carb×4 + fat×9` (±15%)
- `piece_g`: weight per single piece (null if served by weight, not count)
- `category`: traditional, street_food, dessert, beverage, condiment, snack, bread, dairy, etc.
- `variants`: alternate names / transliterations (can be empty array)

### Part Category Guide (200 foods each)
| Part | Focus Categories |
|------|-----------------|
| part1 | Traditional dishes, staples, grains, cereals, legumes, rice, root vegetables |
| part2 | Meat dishes, poultry, game, seafood, fish, soups, stews, curries |
| part3 | Vegetables, salads, side dishes, breads, pastries, dairy, egg dishes |
| part4 | Street food, snacks, appetizers, desserts, sweets, cakes, candies |
| part5 | Beverages (hot/cold/alcoholic), condiments, sauces, pickles, preserved foods |

### Agent Launch Log
All launched agents are recorded in `backend/scripts/country_foods/pipeline_log.json`.
**Before launching any agent**, check this log to avoid duplicates:
```bash
cat backend/scripts/country_foods/pipeline_log.json
# Check if {cc}_part{N} is already in "launched" — if so, skip it
```

### Pipeline Per Country
```
STEP 0: Check pipeline_log.json — skip any parts already listed under "launched"
  python3 -c "
import json
log = json.load(open('backend/scripts/country_foods/pipeline_log.json'))
print(list(log['launched'].keys()))
"

STEP 1: Research (5 parallel agents × 200 foods each = 1000 foods)
  → Log each agent BEFORE launching:
  python3 -c "
import json, datetime
log = json.load(open('backend/scripts/country_foods/pipeline_log.json'))
for key in ['{cc}_part1', '{cc}_part2', ...]:  # only unlaunched parts
    log['launched'][key] = {'status': 'launched', 'launched_at': datetime.datetime.utcnow().isoformat()}
json.dump(log, open('backend/scripts/country_foods/pipeline_log.json', 'w'), indent=2)
"
  → Then launch agents. Each agent writes: backend/scripts/country_foods/{cc}_part{N}.json

STEP 2: Verify all 5 parts exist
  ls backend/scripts/country_foods/{cc}_part*.json | wc -l  # should be 5

STEP 3: Merge + Generate SQL + Cleanup
  cc="xx"  # country code lowercase
  python3 -c "
import json, glob, re

def fix_and_load(path):
    content = open(path).read()
    content = re.sub(r'ENDMARKER.*', '', content, flags=re.DOTALL)
    content = re.sub(r'SENTINEL_END.*', '', content, flags=re.DOTALL)
    fixed = re.sub(r'\"(\w+)\">\s*', r'\"\\1\": ', content)
    try: return json.loads(fixed)
    except:
        last = fixed.rfind(']')
        try: return json.loads(fixed[:last+1])
        except:
            items = []
            for line in fixed.split('\n')[1:]:
                line = line.strip().rstrip(',')
                if line in (']', ''):
                    if items: break
                    continue
                if line.startswith('{'):
                    try: items.append(json.loads(line))
                    except: pass
            return items

cc = '${cc}'
parts = sorted(glob.glob(f'backend/scripts/country_foods/{cc}_part*.json'))
foods = []
for p in parts:
    foods.extend(fix_and_load(p))
lines = ['['] + [json.dumps(f, ensure_ascii=False) + (',' if i < len(foods)-1 else '') for i, f in enumerate(foods)] + [']']
open(f'backend/scripts/country_foods/{cc}.json', 'w').write('\n'.join(lines))
print(f'{cc}: {len(foods)} foods merged')
"
  python backend/scripts/generate_country_overrides.py --country XX
  rm -f backend/scripts/country_foods/${cc}*.json

STEP 4: Update pipeline_log.json completed_sql list, mark ✅ in this file
  python3 -c "
import json
log = json.load(open('backend/scripts/country_foods/pipeline_log.json'))
log['completed_sql'].append('XX')
json.dump(log, open('backend/scripts/country_foods/pipeline_log.json', 'w'), indent=2)
"
```

### How to Check Current State
```bash
# Check pipeline log:
python3 -c "import json; log=json.load(open('backend/scripts/country_foods/pipeline_log.json')); print('Launched:', len(log['launched'])); print('SQL done:', log['completed_sql'])"

# JSON files remaining (countries not yet done):
ls backend/scripts/country_foods/*.json | grep -v pipeline_log | sed 's/_part.*//' | sort -u

# Countries with SQL migrations:
ls backend/migrations/*_overrides_*.sql | sed 's/.*_overrides_//' | sed 's/_.*//' | sort

# Countries with incomplete JSONs (< 5 parts):
for cc in $(ls backend/scripts/country_foods/*_part*.json 2>/dev/null | sed 's/_part[0-9]*.json//' | sed 's|.*/||' | sort -u); do
  count=$(ls backend/scripts/country_foods/${cc}_part*.json 2>/dev/null | wc -l | tr -d ' ')
  echo "$cc: $count/5 parts"
done
```

### Agent Prompt Template (for research agents)
```
Research exactly 200 authentic [COUNTRY_NAME] foods for a nutrition database.
Save the result as a JSON array to: backend/scripts/country_foods/[cc]_part[N].json

Focus on: [PART CATEGORY (see Part Category Guide above)]

JSON format (per 100g values, Atwater check: cal ≈ prot×4 + carb×4 + fat×9 ±15%):
[{"name": "...", "cal": 0, "prot": 0.0, "carb": 0.0, "fat": 0.0, "fiber": 0.0,
  "sugar": 0.0, "serving_g": 200, "piece_g": null, "category": "traditional",
  "notes": "max 15 words", "variants": ["max 2 items"]}]

Requirements:
- Exactly 200 unique foods (no duplicates with other parts)
- Real nutrition values researched from databases (USDA, nutritionix, etc.)
- Include obscure regional dishes, not just famous ones
- notes: max 15 words cultural context
- variants: max 2 alternate names
- Each JSON object on ONE line (compact format)
- Write file first, then summarize
```

### Batch Schedule for Remaining Countries
Process 5 countries per batch (up to 25 agents). After each country has all 5 parts → merge + SQL + delete.
Check pipeline_log.json before each launch to avoid re-launching already-running agents.

**Status as of 2026-03-21:**
- ✅ ALL countries complete (292 SQL migration files generated)
- 🏁 Pipeline COMPLETE

---

## Status Table

| STATUS | CODE | COUNTRY | LANGUAGE |
|--------|------|---------|----------|
| ✅ | AF | Afghanistan | English |
| ✅ | AL | Albania | English |
| ✅ | DZ | Algeria | Arabic |
| ✅ | AS | American Samoa | English |
| ✅ | AD | Andorra | English |
| ✅ | AO | Angola | Portuguese |
| ✅ | AG | Antigua and Barbuda | English |
| ✅ | AR | Argentina | Spanish |
| ✅ | AM | Armenia | English |
| ✅ | AW | Aruba | English |
| ✅ | AU | Australia | English (Regional) |
| ✅ | AT | Austria | German |
| ✅ | AZ | Azerbaijan | English |
| ✅ | BS | Bahamas | English |
| ✅ | BH | Bahrain | Arabic |
| ✅ | BD | Bangladesh | English |
| ✅ | BB | Barbados | English |
| ✅ | BY | Belarus | Russian |
| ✅ | BE | Belgium | Dutch |
| ✅ | BZ | Belize | English |
| ✅ | BJ | Benin | English |
| ✅ | BM | Bermuda | English |
| ✅ | BT | Bhutan | English |
| ✅ | BO | Bolivia | Spanish |
| ✅ | BA | Bosnia and Herzegovina | English |
| ✅ | BW | Botswana | English |
| ✅ | BR | Brazil | Portuguese |
| ✅ | BN | Brunei Darussalam | English |
| ✅ | BG | Bulgaria | English |
| ✅ | BF | Burkina Faso | French |
| ✅ | BI | Burundi | English |
| ✅ | KH | Cambodia | English |
| ✅ | CM | Cameroon | French |
| ✅ | CA | Canada | English (Canada) |
| ✅ | CV | Cape Verde | English |
| ✅ | KY | Cayman Islands | English |
| ✅ | CF | Central African Republic | English |
| ✅ | TD | Chad | Arabic |
| ✅ | CL | Chile | Spanish |
| ✅ | CN | China | Chinese |
| ✅ | CO | Colombia | Spanish |
| ✅ | KM | Comoros | English |
| ✅ | CG | Congo | English |
| ✅ | CR | Costa Rica | Spanish |
| ✅ | HR | Croatia | English |
| ✅ | CU | Cuba | English |
| ✅ | CY | Cyprus | English |
| ✅ | CZ | Czech Republic | English |
| ✅ | CD | Democratic Republic of the Congo | French |
| ✅ | DK | Denmark | Danish |
| ✅ | DJ | Djibouti | English |
| ✅ | DM | Dominica | English |
| ✅ | DO | Dominican Republic | Spanish |
| ✅ | EC | Ecuador | Spanish |
| ✅ | EG | Egypt | Arabic |
| ✅ | SV | El Salvador | Spanish |
| ✅ | GQ | Equatorial Guinea | Spanish |
| ✅ | ER | Eritrea | Arabic |
| ✅ | EE | Estonia | English |
| ✅ | ET | Ethiopia | English |
| ✅ | FO | Faroe Islands | English |
| ✅ | FJ | Fiji | English |
| ✅ | FI | Finland | Finnish |
| ✅ | FR | France | French |
| ✅ | GF | French Guiana | English |
| ✅ | PF | French Polynesia | English |
| ✅ | GA | Gabon | English |
| ✅ | GM | Gambia | English |
| ✅ | GE | Georgia | English |
| ✅ | DE | Germany | German |
| ✅ | GH | Ghana | English (Regional) |
| ✅ | GR | Greece | English |
| ✅ | GL | Greenland | English |
| ✅ | GD | Grenada | English |
| ✅ | GP | Guadeloupe | English |
| ✅ | GU | Guam | English |
| ✅ | GT | Guatemala | Spanish |
| ✅ | GG | Guernsey | English |
| ✅ | GN | Guinea | French |
| ✅ | GW | Guinea-Bissau | English |
| ✅ | GY | Guyana | English |
| ✅ | HT | Haiti | English |
| ✅ | HN | Honduras | Spanish |
| ✅ | HK | Hong Kong | Chinese (Traditional) |
| ✅ | HU | Hungary | English |
| ✅ | IS | Iceland | English |
| ✅ | IN | India | English (Regional) |
| ✅ | ID | Indonesia | Indonesian |
| ✅ | IE | Ireland | English (Regional) |
| ✅ | IM | Isle of Man | English |
| ✅ | IL | Israel | English |
| ✅ | IT | Italy | Italian |
| ✅ | CI | Ivory Coast | French |
| ✅ | JM | Jamaica | English |
| ✅ | JP | Japan | Japanese |
| ✅ | JE | Jersey | English |
| ✅ | JO | Jordan | Arabic |
| ✅ | KZ | Kazakhstan | Russian |
| ✅ | KE | Kenya | English (Regional) |
| ✅ | KI | Kiribati | English |
| ✅ | KR | Korea | Korean |
| ✅ | KW | Kuwait | Arabic |
| ✅ | KG | Kyrgyzstan | English |
| ✅ | LA | Laos | English |
| ✅ | LV | Latvia | English |
| ✅ | LB | Lebanon | Arabic |
| ✅ | LS | Lesotho | English |
| ✅ | LR | Liberia | English |
| ✅ | LY | Libya | Arabic |
| ✅ | LI | Liechtenstein | English |
| ✅ | LT | Lithuania | English |
| ✅ | LU | Luxembourg | English |
| ✅ | MO | Macau | Chinese (Traditional) |
| ✅ | MK | Macedonia | English |
| ✅ | MG | Madagascar | French |
| ✅ | MW | Malawi | English (Regional) |
| ✅ | MY | Malaysia | English |
| ✅ | MV | Maldives | English |
| ✅ | ML | Mali | French |
| ✅ | MT | Malta | English |
| ✅ | MH | Marshall Islands | English |
| ✅ | MQ | Martinique | English |
| ✅ | MR | Mauritania | English |
| ✅ | MU | Mauritius | English |
| ✅ | YT | Mayotte | English |
| ✅ | MX | Mexico | Spanish |
| ✅ | FM | Micronesia | English |
| ✅ | MD | Moldova | English |
| ✅ | MC | Monaco | English |
| ✅ | MN | Mongolia | English |
| ✅ | ME | Montenegro | English |
| ✅ | MA | Morocco | Arabic |
| ✅ | MZ | Mozambique | Portuguese |
| ✅ | MM | Myanmar | English |
| ✅ | NA | Namibia | English |
| ✅ | NP | Nepal | English |
| ✅ | NL | Netherlands | Dutch |
| ✅ | AN | Netherlands Antilles | English |
| ✅ | NC | New Caledonia | English |
| ✅ | NZ | New Zealand | English (Regional) |
| ✅ | NI | Nicaragua | Spanish |
| ✅ | NE | Niger | French |
| ✅ | NG | Nigeria | English (Regional) |
| ✅ | MP | Northern Mariana Islands | English |
| ✅ | NO | Norway | Norwegian |
| ✅ | OM | Oman | Arabic |
| ✅ | PK | Pakistan | English (Regional) |
| ✅ | PA | Panama | Spanish |
| ✅ | PG | Papua New Guinea | English (Regional) |
| ✅ | PY | Paraguay | Spanish |
| ✅ | PE | Peru | Spanish |
| ✅ | PH | Philippines | English (Regional) |
| ✅ | PL | Poland | Polish |
| ✅ | PT | Portugal | Portuguese (Portugal) |
| ✅ | PR | Puerto Rico | Spanish |
| ✅ | QA | Qatar | Arabic |
| ✅ | RE | Reunion | English |
| ✅ | RO | Romania | English |
| ✅ | RU | Russia | Russian |
| ✅ | RW | Rwanda | English (Regional) |
| ✅ | KN | Saint Kitts and Nevis | English |
| ✅ | LC | Saint Lucia | English |
| ✅ | MF | Saint Martin | English |
| ✅ | VC | Saint Vincent and The Grenadines | English |
| ✅ | WS | Samoa | English |
| ✅ | SM | San Marino | English |
| ✅ | ST | Sao Tome and Principe | English |
| ✅ | SA | Saudi Arabia | Arabic |
| ✅ | SN | Senegal | French |
| ✅ | RS | Serbia | English |
| ✅ | SC | Seychelles | English |
| ✅ | SL | Sierra Leone | English |
| ✅ | SG | Singapore | English (Regional) |
| ✅ | SK | Slovakia | English |
| ✅ | SI | Slovenia | English |
| ✅ | SB | Solomon Islands | English |
| ✅ | SO | Somalia | Arabic |
| ✅ | ZA | South Africa | English (Regional) |
| ✅ | ES | Spain | Spanish |
| ✅ | LK | Sri Lanka | English |
| ✅ | SR | Suriname | English |
| ✅ | SZ | Swaziland | English |
| ✅ | SE | Sweden | Swedish |
| ✅ | CH | Switzerland | German |
| ✅ | SY | Syria | Arabic |
| ✅ | TW | Taiwan | Chinese (Traditional) |
| ✅ | TJ | Tajikistan | English |
| ✅ | TZ | Tanzania | English (Regional) |
| ✅ | TH | Thailand | English |
| ✅ | TL | Timor-leste | English |
| ✅ | TG | Togo | English |
| ✅ | TO | Tonga | English |
| ✅ | TT | Trinidad and Tobago | English |
| ✅ | TN | Tunisia | Arabic |
| ✅ | TR | Turkey | Turkish |
| ✅ | TM | Turkmenistan | English |
| ✅ | TC | Turks and Caicos Islands | English |
| ✅ | UG | Uganda | English (Regional) |
| ✅ | UA | Ukraine | Ukrainian |
| ✅ | AE | United Arab Emirates | Arabic |
| ✅ | GB | United Kingdom | English (Regional) |
| ✅ | US | United States | English |
| ✅ | UY | Uruguay | Spanish |
| ✅ | UZ | Uzbekistan | English |
| ✅ | VU | Vanuatu | English |
| ✅ | VE | Venezuela | Spanish |
| ✅ | VN | Vietnam | English |
| ✅ | VI | Virgin Islands, U.S. | English |
| ✅ | EH | Western Sahara | English |
| ✅ | YE | Yemen | Arabic |
| ✅ | ZM | Zambia | English (Regional) |
| ✅ | ZW | Zimbabwe | English (Regional) |
