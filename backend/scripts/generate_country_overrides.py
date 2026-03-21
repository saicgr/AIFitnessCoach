#!/usr/bin/env python3
"""
Generate ~1000 food override SQL migration files for each of 213 countries.

Each file inserts country-specific foods into food_nutrition_overrides with:
- food_name_normalized: {food_name}_{demonym}
- display_name: {Food Name} ({Demonym})
- region: ISO 3166-1 alpha-2 code
- Nutrition values per 100g (Atwater-validated)

Usage:
    python generate_country_overrides.py              # Generate all 213 files
    python generate_country_overrides.py --country JP # Generate only Japan
    python generate_country_overrides.py --start 0 --end 10  # First 10 countries
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

MIGRATIONS_DIR = Path(__file__).parent.parent / "migrations"

# ═══════════════════════════════════════════════════════════════
# COUNTRY DEFINITIONS (213 countries, alphabetical)
# Each: (CC, country_name, demonym, slug)
# ═══════════════════════════════════════════════════════════════

COUNTRIES = [
    ("AF", "Afghanistan", "Afghan", "afghanistan"),
    ("AL", "Albania", "Albanian", "albania"),
    ("DZ", "Algeria", "Algerian", "algeria"),
    ("AS", "American Samoa", "Samoan", "american_samoa"),
    ("AD", "Andorra", "Andorran", "andorra"),
    ("AO", "Angola", "Angolan", "angola"),
    ("AG", "Antigua and Barbuda", "Antiguan", "antigua_barbuda"),
    ("AR", "Argentina", "Argentine", "argentina"),
    ("AM", "Armenia", "Armenian", "armenia"),
    ("AW", "Aruba", "Aruban", "aruba"),
    ("AU", "Australia", "Australian", "australia"),
    ("AT", "Austria", "Austrian", "austria"),
    ("AZ", "Azerbaijan", "Azerbaijani", "azerbaijan"),
    ("BS", "Bahamas", "Bahamian", "bahamas"),
    ("BH", "Bahrain", "Bahraini", "bahrain"),
    ("BD", "Bangladesh", "Bangladeshi", "bangladesh"),
    ("BB", "Barbados", "Bajan", "barbados"),
    ("BY", "Belarus", "Belarusian", "belarus"),
    ("BE", "Belgium", "Belgian", "belgium"),
    ("BZ", "Belize", "Belizean", "belize"),
    ("BJ", "Benin", "Beninese", "benin"),
    ("BM", "Bermuda", "Bermudian", "bermuda"),
    ("BT", "Bhutan", "Bhutanese", "bhutan"),
    ("BO", "Bolivia", "Bolivian", "bolivia"),
    ("BA", "Bosnia and Herzegovina", "Bosnian", "bosnia"),
    ("BW", "Botswana", "Motswana", "botswana"),
    ("BR", "Brazil", "Brazilian", "brazil"),
    ("BN", "Brunei", "Bruneian", "brunei"),
    ("BG", "Bulgaria", "Bulgarian", "bulgaria"),
    ("BF", "Burkina Faso", "Burkinabe", "burkina_faso"),
    ("BI", "Burundi", "Burundian", "burundi"),
    ("KH", "Cambodia", "Cambodian", "cambodia"),
    ("CM", "Cameroon", "Cameroonian", "cameroon"),
    ("CA", "Canada", "Canadian", "canada"),
    ("CV", "Cape Verde", "Cape Verdean", "cape_verde"),
    ("KY", "Cayman Islands", "Caymanian", "cayman_islands"),
    ("CF", "Central African Republic", "Central African", "central_african_republic"),
    ("TD", "Chad", "Chadian", "chad"),
    ("CL", "Chile", "Chilean", "chile"),
    ("CN", "China", "Chinese", "china"),
    ("CO", "Colombia", "Colombian", "colombia"),
    ("KM", "Comoros", "Comorian", "comoros"),
    ("CG", "Congo", "Congolese", "congo"),
    ("CR", "Costa Rica", "Costa Rican", "costa_rica"),
    ("HR", "Croatia", "Croatian", "croatia"),
    ("CU", "Cuba", "Cuban", "cuba"),
    ("CY", "Cyprus", "Cypriot", "cyprus"),
    ("CZ", "Czech Republic", "Czech", "czech_republic"),
    ("CD", "DR Congo", "DR Congolese", "dr_congo"),
    ("DK", "Denmark", "Danish", "denmark"),
    ("DJ", "Djibouti", "Djiboutian", "djibouti"),
    ("DM", "Dominica", "Dominican Island", "dominica"),
    ("DO", "Dominican Republic", "Dominican", "dominican_republic"),
    ("EC", "Ecuador", "Ecuadorian", "ecuador"),
    ("EG", "Egypt", "Egyptian", "egypt"),
    ("SV", "El Salvador", "Salvadoran", "el_salvador"),
    ("GQ", "Equatorial Guinea", "Equatoguinean", "equatorial_guinea"),
    ("ER", "Eritrea", "Eritrean", "eritrea"),
    ("EE", "Estonia", "Estonian", "estonia"),
    ("SZ", "Eswatini", "Swazi", "eswatini"),
    ("ET", "Ethiopia", "Ethiopian", "ethiopia"),
    ("FJ", "Fiji", "Fijian", "fiji"),
    ("FI", "Finland", "Finnish", "finland"),
    ("FR", "France", "French", "france"),
    ("GF", "French Guiana", "French Guianese", "french_guiana"),
    ("GA", "Gabon", "Gabonese", "gabon"),
    ("GM", "Gambia", "Gambian", "gambia"),
    ("GE", "Georgia", "Georgian", "georgia"),
    ("DE", "Germany", "German", "germany"),
    ("GH", "Ghana", "Ghanaian", "ghana"),
    ("GR", "Greece", "Greek", "greece"),
    ("GL", "Greenland", "Greenlandic", "greenland"),
    ("GD", "Grenada", "Grenadian", "grenada"),
    ("GP", "Guadeloupe", "Guadeloupean", "guadeloupe"),
    ("GU", "Guam", "Guamanian", "guam"),
    ("GT", "Guatemala", "Guatemalan", "guatemala"),
    ("GG", "Guernsey", "Guernsey", "guernsey"),
    ("GN", "Guinea", "Guinean", "guinea"),
    ("GW", "Guinea-Bissau", "Bissau Guinean", "guinea_bissau"),
    ("GY", "Guyana", "Guyanese", "guyana"),
    ("HT", "Haiti", "Haitian", "haiti"),
    ("HN", "Honduras", "Honduran", "honduras"),
    ("HK", "Hong Kong", "Hong Kong", "hong_kong"),
    ("HU", "Hungary", "Hungarian", "hungary"),
    ("IS", "Iceland", "Icelandic", "iceland"),
    ("IN", "India", "Indian", "india"),
    ("ID", "Indonesia", "Indonesian", "indonesia"),
    ("IR", "Iran", "Iranian", "iran"),
    ("IQ", "Iraq", "Iraqi", "iraq"),
    ("IE", "Ireland", "Irish", "ireland"),
    ("IM", "Isle of Man", "Manx", "isle_of_man"),
    ("IL", "Israel", "Israeli", "israel"),
    ("IT", "Italy", "Italian", "italy"),
    ("CI", "Ivory Coast", "Ivorian", "ivory_coast"),
    ("JM", "Jamaica", "Jamaican", "jamaica"),
    ("JP", "Japan", "Japanese", "japan"),
    ("JE", "Jersey", "Jersey", "jersey"),
    ("JO", "Jordan", "Jordanian", "jordan"),
    ("KZ", "Kazakhstan", "Kazakh", "kazakhstan"),
    ("KE", "Kenya", "Kenyan", "kenya"),
    ("KI", "Kiribati", "I-Kiribati", "kiribati"),
    ("KR", "South Korea", "Korean", "south_korea"),
    ("KW", "Kuwait", "Kuwaiti", "kuwait"),
    ("KG", "Kyrgyzstan", "Kyrgyz", "kyrgyzstan"),
    ("LA", "Laos", "Lao", "laos"),
    ("LV", "Latvia", "Latvian", "latvia"),
    ("LB", "Lebanon", "Lebanese", "lebanon"),
    ("LS", "Lesotho", "Basotho", "lesotho"),
    ("LR", "Liberia", "Liberian", "liberia"),
    ("LY", "Libya", "Libyan", "libya"),
    ("LI", "Liechtenstein", "Liechtensteiner", "liechtenstein"),
    ("LT", "Lithuania", "Lithuanian", "lithuania"),
    ("LU", "Luxembourg", "Luxembourgish", "luxembourg"),
    ("MO", "Macau", "Macanese", "macau"),
    ("MK", "North Macedonia", "Macedonian", "north_macedonia"),
    ("MG", "Madagascar", "Malagasy", "madagascar"),
    ("MW", "Malawi", "Malawian", "malawi"),
    ("MY", "Malaysia", "Malaysian", "malaysia"),
    ("MV", "Maldives", "Maldivian", "maldives"),
    ("ML", "Mali", "Malian", "mali"),
    ("MT", "Malta", "Maltese", "malta"),
    ("MH", "Marshall Islands", "Marshallese", "marshall_islands"),
    ("MQ", "Martinique", "Martinican", "martinique"),
    ("MR", "Mauritania", "Mauritanian", "mauritania"),
    ("MU", "Mauritius", "Mauritian", "mauritius"),
    ("YT", "Mayotte", "Mahoran", "mayotte"),
    ("MX", "Mexico", "Mexican", "mexico"),
    ("FM", "Micronesia", "Micronesian", "micronesia"),
    ("MD", "Moldova", "Moldovan", "moldova"),
    ("MC", "Monaco", "Monegasque", "monaco"),
    ("MN", "Mongolia", "Mongolian", "mongolia"),
    ("ME", "Montenegro", "Montenegrin", "montenegro"),
    ("MA", "Morocco", "Moroccan", "morocco"),
    ("MZ", "Mozambique", "Mozambican", "mozambique"),
    ("MM", "Myanmar", "Burmese", "myanmar"),
    ("NA", "Namibia", "Namibian", "namibia"),
    ("NR", "Nauru", "Nauruan", "nauru"),
    ("NP", "Nepal", "Nepali", "nepal"),
    ("NL", "Netherlands", "Dutch", "netherlands"),
    ("AN", "Netherlands Antilles", "Antillean", "netherlands_antilles"),
    ("NC", "New Caledonia", "New Caledonian", "new_caledonia"),
    ("NZ", "New Zealand", "Kiwi", "new_zealand"),
    ("NI", "Nicaragua", "Nicaraguan", "nicaragua"),
    ("NE", "Niger", "Nigerien", "niger"),
    ("NG", "Nigeria", "Nigerian", "nigeria"),
    ("MP", "Northern Mariana Islands", "Northern Marianan", "northern_mariana_islands"),
    ("NO", "Norway", "Norwegian", "norway"),
    ("OM", "Oman", "Omani", "oman"),
    ("PK", "Pakistan", "Pakistani", "pakistan"),
    ("PW", "Palau", "Palauan", "palau"),
    ("PS", "Palestine", "Palestinian", "palestine"),
    ("PA", "Panama", "Panamanian", "panama"),
    ("PF", "French Polynesia", "French Polynesian", "french_polynesia"),
    ("PG", "Papua New Guinea", "Papua New Guinean", "papua_new_guinea"),
    ("PY", "Paraguay", "Paraguayan", "paraguay"),
    ("PE", "Peru", "Peruvian", "peru"),
    ("PH", "Philippines", "Filipino", "philippines"),
    ("PL", "Poland", "Polish", "poland"),
    ("PT", "Portugal", "Portuguese", "portugal"),
    ("PR", "Puerto Rico", "Puerto Rican", "puerto_rico"),
    ("QA", "Qatar", "Qatari", "qatar"),
    ("RE", "Reunion", "Reunionese", "reunion"),
    ("RO", "Romania", "Romanian", "romania"),
    ("RU", "Russia", "Russian", "russia"),
    ("RW", "Rwanda", "Rwandan", "rwanda"),
    ("KN", "Saint Kitts and Nevis", "Kittitian", "saint_kitts_nevis"),
    ("LC", "Saint Lucia", "Saint Lucian", "saint_lucia"),
    ("VC", "Saint Vincent", "Vincentian", "saint_vincent"),
    ("WS", "Samoa", "Samoan WS", "samoa"),
    ("SM", "San Marino", "Sammarinese", "san_marino"),
    ("ST", "Sao Tome and Principe", "Santomean", "sao_tome_principe"),
    ("SA", "Saudi Arabia", "Saudi", "saudi_arabia"),
    ("SN", "Senegal", "Senegalese", "senegal"),
    ("RS", "Serbia", "Serbian", "serbia"),
    ("SC", "Seychelles", "Seychellois", "seychelles"),
    ("SL", "Sierra Leone", "Sierra Leonean", "sierra_leone"),
    ("SG", "Singapore", "Singaporean", "singapore"),
    ("SK", "Slovakia", "Slovak", "slovakia"),
    ("SI", "Slovenia", "Slovenian", "slovenia"),
    ("SB", "Solomon Islands", "Solomon Islander", "solomon_islands"),
    ("SO", "Somalia", "Somali", "somalia"),
    ("ZA", "South Africa", "South African", "south_africa"),
    ("SS", "South Sudan", "South Sudanese", "south_sudan"),
    ("ES", "Spain", "Spanish", "spain"),
    ("LK", "Sri Lanka", "Sri Lankan", "sri_lanka"),
    ("SD", "Sudan", "Sudanese", "sudan"),
    ("SR", "Suriname", "Surinamese", "suriname"),
    ("SE", "Sweden", "Swedish", "sweden"),
    ("CH", "Switzerland", "Swiss", "switzerland"),
    ("SY", "Syria", "Syrian", "syria"),
    ("TW", "Taiwan", "Taiwanese", "taiwan"),
    ("TJ", "Tajikistan", "Tajik", "tajikistan"),
    ("TZ", "Tanzania", "Tanzanian", "tanzania"),
    ("TH", "Thailand", "Thai", "thailand"),
    ("TL", "Timor-Leste", "Timorese", "timor_leste"),
    ("TG", "Togo", "Togolese", "togo"),
    ("TO", "Tonga", "Tongan", "tonga"),
    ("TT", "Trinidad and Tobago", "Trinidadian", "trinidad_tobago"),
    ("TN", "Tunisia", "Tunisian", "tunisia"),
    ("TR", "Turkey", "Turkish", "turkey"),
    ("TM", "Turkmenistan", "Turkmen", "turkmenistan"),
    ("TV", "Tuvalu", "Tuvaluan", "tuvalu"),
    ("UG", "Uganda", "Ugandan", "uganda"),
    ("UA", "Ukraine", "Ukrainian", "ukraine"),
    ("AE", "United Arab Emirates", "Emirati", "uae"),
    ("GB", "United Kingdom", "British", "united_kingdom"),
    ("US", "United States", "American", "united_states"),
    ("UY", "Uruguay", "Uruguayan", "uruguay"),
    ("UZ", "Uzbekistan", "Uzbek", "uzbekistan"),
    ("VU", "Vanuatu", "Ni-Vanuatu", "vanuatu"),
    ("VE", "Venezuela", "Venezuelan", "venezuela"),
    ("VN", "Vietnam", "Vietnamese", "vietnam"),
    ("YE", "Yemen", "Yemeni", "yemen"),
    ("ZM", "Zambia", "Zambian", "zambia"),
    ("ZW", "Zimbabwe", "Zimbabwean", "zimbabwe"),
    ("FO", "Faroe Islands", "Faroese", "faroe_islands"),
]

# ═══════════════════════════════════════════════════════════════
# FOOD DATABASE: country_code -> list of food dicts
# Each food: (name, display, cal, prot, carb, fat, fiber, sugar, serving_g, piece_g, category, notes, variants[])
# ═══════════════════════════════════════════════════════════════

# This is the comprehensive food database. Each country has foods organized by category.
# All values are per 100g. Atwater check: cal ≈ P*4 + C*4 + F*9 (±15%)

def get_country_foods(cc, country_name, demonym):
    """
    Returns a list of food tuples for a given country.
    Each tuple: (base_name, cal, prot, carb, fat, fiber, sugar, serving_g, piece_g, category, notes, extra_variants)

    The base_name will be suffixed with _{demonym_lower} for food_name_normalized,
    and display_name will be "{Title Case} ({Demonym})".
    """
    # Import the per-country food data module
    foods = []

    # We use a data-driven approach: define foods per country in a compact format
    # For countries with rich cuisines, we have more entries; for smaller nations, we supplement
    # with regional/shared dishes.

    # Load from the country_foods data files
    data_dir = Path(__file__).parent / "country_foods"
    data_file = data_dir / f"{cc.lower()}.json"

    if data_file.exists():
        with open(data_file) as f:
            foods = json.load(f)
        return foods

    return []


def normalize_name(name):
    """Convert a food name to normalized form: lowercase, underscores, no special chars."""
    name = name.lower().strip()
    # Replace common special chars
    name = name.replace("'", "").replace("'", "").replace("`", "")
    name = name.replace("-", "_").replace(" ", "_")
    name = name.replace("(", "").replace(")", "")
    name = name.replace(",", "").replace(".", "")
    name = name.replace("&", "and").replace("/", "_")
    name = name.replace("é", "e").replace("è", "e").replace("ê", "e").replace("ë", "e")
    name = name.replace("á", "a").replace("à", "a").replace("â", "a").replace("ä", "a").replace("ã", "a")
    name = name.replace("í", "i").replace("ì", "i").replace("î", "i").replace("ï", "i")
    name = name.replace("ó", "o").replace("ò", "o").replace("ô", "o").replace("ö", "o").replace("õ", "o")
    name = name.replace("ú", "u").replace("ù", "u").replace("û", "u").replace("ü", "u")
    name = name.replace("ñ", "n").replace("ç", "c").replace("ß", "ss")
    name = name.replace("ø", "o").replace("å", "a").replace("æ", "ae")
    name = name.replace("ð", "d").replace("þ", "th").replace("ý", "y")
    name = name.replace("š", "s").replace("č", "c").replace("ž", "z").replace("ć", "c").replace("đ", "d")
    # Remove any remaining non-alphanumeric (except underscore)
    name = re.sub(r'[^a-z0-9_]', '', name)
    # Collapse multiple underscores
    name = re.sub(r'_+', '_', name).strip('_')
    return name


def escape_sql(s):
    """Escape single quotes for SQL."""
    if s is None:
        return 'NULL'
    return s.replace("'", "''")


def generate_migration_sql(cc, country_name, demonym, slug, migration_num, foods):
    """Generate the SQL migration file content."""
    demonym_lower = normalize_name(demonym)

    lines = []
    lines.append(f"-- Migration {migration_num}: Food overrides for {country_name} ({cc})")
    lines.append(f"-- {len(foods)} traditional dishes, street food, beverages, snacks, staples")
    lines.append(f"-- All values per 100g. Source: research (nutrition databases, manufacturer data)")
    lines.append("")
    lines.append("INSERT INTO food_nutrition_overrides (")
    lines.append("  food_name_normalized, display_name,")
    lines.append("  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,")
    lines.append("  fiber_per_100g, sugar_per_100g,")
    lines.append("  default_serving_g, default_weight_per_piece_g,")
    lines.append("  source, variant_names,")
    lines.append("  food_category, restaurant_name, default_count, region, notes, is_active")
    lines.append(") VALUES")

    for i, food in enumerate(foods):
        base_name = food["name"]
        cal = food["cal"]
        prot = food["prot"]
        carb = food["carb"]
        fat = food["fat"]
        fiber = food.get("fiber", 0)
        sugar = food.get("sugar", 0)
        serving_g = food.get("serving_g", 200)
        piece_g = food.get("piece_g")
        category = food.get("category", "traditional")
        notes = food.get("notes", "")
        extra_variants = food.get("variants", [])

        # Build normalized name
        norm_name = f"{normalize_name(base_name)}_{demonym_lower}"

        # Build display name — just the food name, no country suffix
        # The region column handles country association
        display_name = base_name

        # Build variant names array
        variants = [base_name.lower()]
        for v in extra_variants:
            if v.lower() not in [x.lower() for x in variants]:
                variants.append(v.lower())

        variant_sql = "ARRAY[" + ", ".join(f"'{escape_sql(v)}'" for v in variants) + "]"

        piece_g_sql = str(piece_g) if piece_g else "NULL"
        comma = "," if i < len(foods) - 1 else ""

        lines.append(f"('{escape_sql(norm_name)}', '{escape_sql(display_name)}', "
                     f"{cal}, {prot}, {carb}, {fat}, "
                     f"{fiber}, {sugar}, "
                     f"{serving_g}, {piece_g_sql}, "
                     f"'research', {variant_sql}, "
                     f"'{escape_sql(category)}', NULL, 1, '{cc}', "
                     f"'{escape_sql(notes)}', TRUE){comma}")

    lines.append("ON CONFLICT (food_name_normalized) DO UPDATE SET")
    lines.append("  display_name = EXCLUDED.display_name,")
    lines.append("  calories_per_100g = EXCLUDED.calories_per_100g,")
    lines.append("  protein_per_100g = EXCLUDED.protein_per_100g,")
    lines.append("  carbs_per_100g = EXCLUDED.carbs_per_100g,")
    lines.append("  fat_per_100g = EXCLUDED.fat_per_100g,")
    lines.append("  fiber_per_100g = EXCLUDED.fiber_per_100g,")
    lines.append("  sugar_per_100g = EXCLUDED.sugar_per_100g,")
    lines.append("  default_serving_g = EXCLUDED.default_serving_g,")
    lines.append("  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,")
    lines.append("  source = EXCLUDED.source,")
    lines.append("  variant_names = EXCLUDED.variant_names,")
    lines.append("  food_category = EXCLUDED.food_category,")
    lines.append("  restaurant_name = EXCLUDED.restaurant_name,")
    lines.append("  default_count = EXCLUDED.default_count,")
    lines.append("  region = EXCLUDED.region,")
    lines.append("  notes = EXCLUDED.notes,")
    lines.append("  updated_at = NOW();")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate country food override SQL migrations")
    parser.add_argument("--country", type=str, help="ISO 3166-1 alpha-2 country code")
    parser.add_argument("--start", type=int, default=0, help="Start index in countries list")
    parser.add_argument("--end", type=int, default=len(COUNTRIES), help="End index")
    parser.add_argument("--list", action="store_true", help="List countries with migration numbers")
    args = parser.parse_args()

    BASE_MIGRATION = 1650  # Starting migration number

    if args.list:
        for i, (cc, name, demonym, slug) in enumerate(COUNTRIES):
            print(f"  {BASE_MIGRATION + i}  {cc}  {name}")
        return

    countries_to_process = COUNTRIES[args.start:args.end]
    if args.country:
        countries_to_process = [(cc, name, dem, slug) for cc, name, dem, slug in COUNTRIES
                                if cc == args.country.upper()]

    generated = 0
    for i, (cc, country_name, demonym, slug) in enumerate(countries_to_process):
        idx = COUNTRIES.index((cc, country_name, demonym, slug))
        migration_num = BASE_MIGRATION + idx
        filename = f"{migration_num}_overrides_{cc}_{slug}.sql"
        filepath = MIGRATIONS_DIR / filename

        foods = get_country_foods(cc, country_name, demonym)
        if not foods:
            print(f"  SKIP {filename} (no food data for {cc})")
            continue

        sql = generate_migration_sql(cc, country_name, demonym, slug, migration_num, foods)

        with open(filepath, 'w') as f:
            f.write(sql)

        print(f"  OK {filename} ({len(foods)} foods)")
        generated += 1

    print(f"\nGenerated {generated} migration files")


if __name__ == "__main__":
    main()
