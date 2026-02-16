"""
Food Data Curation Pipeline - Configuration

Data Sources:
  USDA FoodData Central: https://fdc.nal.usda.gov/download-datasets
  OpenFood Facts:        https://world.openfoodfacts.org/data
                         https://openfoodfacts.github.io/openfoodfacts-server/api/aws-images-dataset/
  Indian INDB:           Anuvaad INDB 2024.11
  Canadian Nutrient File: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/nutrient-data.html
"""

from pathlib import Path

# ── Base paths ──────────────────────────────────────────────────────────────────
DATA_DIR = Path.home() / "Downloads" / "fitwiz_program_data"
OUTPUT_DIR = Path(__file__).parent / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

# ── Data source paths ───────────────────────────────────────────────────────────
USDA_DIR = DATA_DIR / "FoodData_Central_csv_2025-12-18"
OFF_PARQUET = DATA_DIR / "food.parquet"
INDB_XLSX = DATA_DIR / "Anuvaad_INDB_2024.11.xlsx"
CNF_DIR = DATA_DIR / "cnf-fcen-csv"

# ── USDA target data types (skip branded_food, sub_sample, etc.) ────────────────
USDA_TARGET_DATA_TYPES = frozenset({
    "foundation_food",
    "sr_legacy_food",
    "survey_fndds_food",
})

# ── USDA nutrient ID -> canonical column name ──────────────────────────────────
# Macros (stored as top-level columns, per 100 g)
USDA_MACRO_IDS = {
    1008: "calories",
    1003: "protein",
    1004: "fat",
    1005: "carbs",
    1079: "fiber",
    1063: "sugar",
}

# Micros (stored in micronutrients_per_100g dict)
USDA_MICRO_IDS = {
    1093: "sodium_mg",
    1253: "cholesterol_mg",
    1087: "calcium_mg",
    1089: "iron_mg",
    1092: "potassium_mg",
    1106: "vitamin_a_mcg",
    1162: "vitamin_c_mg",
    1110: "vitamin_d_iu",
    1109: "vitamin_e_mg",
    1175: "vitamin_b6_mg",
    1178: "vitamin_b12_mcg",
    1090: "magnesium_mg",
    1095: "zinc_mg",
    1091: "phosphorus_mg",
}

# USDA amino acid nutrient IDs (stored as bonus micros in mg)
USDA_AMINO_ACID_IDS = {
    1210: "tryptophan_mg",
    1211: "threonine_mg",
    1212: "isoleucine_mg",
    1213: "leucine_mg",
    1214: "lysine_mg",
    1215: "methionine_mg",
    1216: "cystine_mg",
    1217: "phenylalanine_mg",
    1218: "tyrosine_mg",
    1219: "valine_mg",
    1220: "arginine_mg",
    1221: "histidine_mg",
    1222: "alanine_mg",
    1223: "aspartic_acid_mg",
    1224: "glutamic_acid_mg",
    1225: "glycine_mg",
    1226: "proline_mg",
    1227: "serine_mg",
}

# Combined for filtering food_nutrient.csv
USDA_ALL_NUTRIENT_IDS = {**USDA_MACRO_IDS, **USDA_MICRO_IDS, **USDA_AMINO_ACID_IDS}

# Macro column name -> key in USDA_MACRO_IDS values
MACRO_COLUMNS = ["calories", "protein", "fat", "carbs", "fiber", "sugar"]
MICRO_KEYS = list(USDA_MICRO_IDS.values())

# ── Amino acid keys ─────────────────────────────────────────────────────────────
AMINO_ACID_KEYS = [
    "tryptophan_mg", "threonine_mg", "isoleucine_mg", "leucine_mg",
    "lysine_mg", "methionine_mg", "cystine_mg", "phenylalanine_mg",
    "tyrosine_mg", "valine_mg", "arginine_mg", "histidine_mg",
    "alanine_mg", "aspartic_acid_mg", "glutamic_acid_mg", "glycine_mg",
    "proline_mg", "serine_mg",
]

# ── Canadian Nutrient File (CNF) mappings ────────────────────────────────────────
# CNF NutrientID -> canonical macro name
CNF_MACRO_IDS = {
    208: "calories",    # KCAL
    203: "protein",     # PROT
    204: "fat",         # FAT
    205: "carbs",       # CARB
    291: "fiber",       # TDF
    269: "sugar",       # TSUG
}

# CNF NutrientID -> (canonical micro name, multiplier)
CNF_MICRO_IDS = {
    307: ("sodium_mg", 1.0),
    601: ("cholesterol_mg", 1.0),
    301: ("calcium_mg", 1.0),
    303: ("iron_mg", 1.0),
    306: ("potassium_mg", 1.0),
    814: ("vitamin_a_mcg", 1.0),   # RAE
    401: ("vitamin_c_mg", 1.0),
    324: ("vitamin_d_iu", 1.0),    # D-IU
    323: ("vitamin_e_mg", 1.0),    # alpha-tocopherol
    415: ("vitamin_b6_mg", 1.0),
    418: ("vitamin_b12_mcg", 1.0),
    304: ("magnesium_mg", 1.0),
    309: ("zinc_mg", 1.0),
    305: ("phosphorus_mg", 1.0),
}

# CNF extra micros (not in the 14-key canonical set)
CNF_EXTRA_MICRO_IDS = {
    312: ("copper_mg", 1.0),
    315: ("manganese_mg", 1.0),
    317: ("selenium_mcg", 1.0),
    404: ("vitamin_b1_mg", 1.0),   # thiamin
    405: ("vitamin_b2_mg", 1.0),   # riboflavin
    406: ("vitamin_b3_mg", 1.0),   # niacin
    410: ("vitamin_b5_mg", 1.0),   # pantothenic acid
    416: ("vitamin_b7_mcg", 1.0),  # biotin
    417: ("folate_mcg", 1.0),      # total folacin
    430: ("vitamin_k1_mcg", 1.0),  # vitamin K
    862: ("choline_mg", 1.0),
}

# CNF amino acid NutrientIDs -> (canonical name, multiplier)
# CNF stores amino acids in grams; we convert to mg (* 1000)
CNF_AMINO_ACID_IDS = {
    501: ("tryptophan_mg", 1000.0),
    502: ("threonine_mg", 1000.0),
    503: ("isoleucine_mg", 1000.0),
    504: ("leucine_mg", 1000.0),
    505: ("lysine_mg", 1000.0),
    506: ("methionine_mg", 1000.0),
    507: ("cystine_mg", 1000.0),
    508: ("phenylalanine_mg", 1000.0),
    509: ("tyrosine_mg", 1000.0),
    510: ("valine_mg", 1000.0),
    511: ("arginine_mg", 1000.0),
    512: ("histidine_mg", 1000.0),
    513: ("alanine_mg", 1000.0),
    514: ("aspartic_acid_mg", 1000.0),
    515: ("glutamic_acid_mg", 1000.0),
    516: ("glycine_mg", 1000.0),
    517: ("proline_mg", 1000.0),
    518: ("serine_mg", 1000.0),
}

# All CNF nutrient IDs we care about
CNF_ALL_NUTRIENT_IDS = {
    **{k: v for k, v in CNF_MACRO_IDS.items()},
    **{k: v[0] for k, v in CNF_MICRO_IDS.items()},
    **{k: v[0] for k, v in CNF_EXTRA_MICRO_IDS.items()},
    **{k: v[0] for k, v in CNF_AMINO_ACID_IDS.items()},
}

# ── OpenFood Facts nutriment name -> canonical name ────────────────────────────
# The OFF parquet stores nutrition in a `nutriments` column as an array of dicts:
#   [{"name": "energy-kcal", "100g": 617.0, "unit": "kcal"}, ...]
# We map the "name" field to our canonical names.
OFF_MACRO_MAP = {
    "energy-kcal": "calories",
    "proteins": "protein",
    "fat": "fat",
    "carbohydrates": "carbs",
    "fiber": "fiber",
    "sugars": "sugar",
}

OFF_MICRO_MAP = {
    "sodium": ("sodium_mg", 1000.0),       # g -> mg
    "cholesterol": ("cholesterol_mg", 1.0), # already mg in OFF
    "calcium": ("calcium_mg", 1.0),
    "iron": ("iron_mg", 1.0),
    "potassium": ("potassium_mg", 1.0),
    "vitamin-a": ("vitamin_a_mcg", 1.0),
    "vitamin-c": ("vitamin_c_mg", 1.0),
    "vitamin-d": ("vitamin_d_iu", 1.0),
    "vitamin-e": ("vitamin_e_mg", 1.0),
    "vitamin-b6": ("vitamin_b6_mg", 1.0),
    "vitamin-b12": ("vitamin_b12_mcg", 1.0),
    "magnesium": ("magnesium_mg", 1.0),
    "zinc": ("zinc_mg", 1.0),
    "phosphorus": ("phosphorus_mg", 1.0),
}

# Columns to read from the OFF parquet (avoids loading all 110 columns)
OFF_READ_COLUMNS = [
    "product_name",
    "code",
    "brands",
    "categories",
    "nutriscore_grade",
    "completeness",
    "nutriments",
    "serving_size",
    "serving_quantity",
    # New enrichment columns
    "allergens_tags",
    "labels_tags",
    "food_groups_tags",
    "nova_group",
    "traces_tags",
    "images",
    "ingredients_text",
    "nutriscore_score",
]

# ── INDB column map (per-100g columns -> canonical) ────────────────────────────
INDB_MACRO_MAP = {
    "energy_kcal": "calories",
    "protein_g": "protein",
    "carb_g": "carbs",
    "fat_g": "fat",
    "fibre_g": "fiber",
    "freesugar_g": "sugar",
}

# Micros: INDB column -> (canonical micro key, multiplier)
# Units in INDB: mg columns stay as-is, ug columns get appropriate mapping
INDB_MICRO_MAP = {
    "sodium_mg": ("sodium_mg", 1.0),
    "cholesterol_mg": ("cholesterol_mg", 1.0),
    "calcium_mg": ("calcium_mg", 1.0),
    "iron_mg": ("iron_mg", 1.0),
    "potassium_mg": ("potassium_mg", 1.0),
    "vita_ug": ("vitamin_a_mcg", 1.0),       # ug == mcg
    "vitc_mg": ("vitamin_c_mg", 1.0),
    # vitd2_ug + vitd3_ug combined, * 40 for IU  (handled specially)
    "vite_mg": ("vitamin_e_mg", 1.0),
    "vitb6_mg": ("vitamin_b6_mg", 1.0),
    # vitb12 not directly in INDB - skip
    "magnesium_mg": ("magnesium_mg", 1.0),
    "zinc_mg": ("zinc_mg", 1.0),
    "phosphorus_mg": ("phosphorus_mg", 1.0),
}

# Extra INDB micros (not in the 14-key canonical set, stored as bonus keys)
INDB_EXTRA_MICROS = {
    "copper_mg": "copper_mg",
    "selenium_ug": "selenium_mcg",
    "chromium_mg": "chromium_mg",
    "manganese_mg": "manganese_mg",
    "molybdenum_mg": "molybdenum_mg",
    "vitk1_ug": "vitamin_k1_mcg",
    "vitk2_ug": "vitamin_k2_mcg",
    "folate_ug": "folate_mcg",
    "vitb1_mg": "vitamin_b1_mg",
    "vitb2_mg": "vitamin_b2_mg",
    "vitb3_mg": "vitamin_b3_mg",
    "vitb5_mg": "vitamin_b5_mg",
    "vitb7_ug": "vitamin_b7_mcg",
    "vitb9_ug": "vitamin_b9_mcg",
    "carotenoids_ug": "carotenoids_mcg",
    "sfa_mg": "saturated_fat_mg",
    "mufa_mg": "monounsaturated_fat_mg",
    "pufa_mg": "polyunsaturated_fat_mg",
}

# INDB per-serving column prefix
INDB_SERVING_PREFIX = "unit_serving_"

# ── Canonical output schema ────────────────────────────────────────────────────
OUTPUT_COLUMNS = [
    # Identity
    "name",
    "name_normalized",
    "source",              # "usda", "usda_branded", "openfoodfacts", "indb", "cnf"
    "source_id",           # fdc_id / barcode / food_code
    "data_type",           # e.g. "sr_legacy_food", "foundation_food", ...
    "brand",
    "category",
    "food_group",
    # Macros per 100 g
    "calories_per_100g",
    "protein_per_100g",
    "fat_per_100g",
    "carbs_per_100g",
    "fiber_per_100g",
    "sugar_per_100g",
    # Micros per 100 g (JSON dict stored as string)
    "micronutrients_per_100g",
    # Serving info
    "serving_description",
    "serving_weight_g",
    # Macros per serving
    "calories_per_serving",
    "protein_per_serving",
    "fat_per_serving",
    "carbs_per_serving",
    # OFF-specific enrichment fields
    "allergens",            # JSON array: ["nuts","milk","gluten"]
    "diet_labels",          # JSON array: ["vegan","organic","gluten-free"]
    "nova_group",           # Ultra-processing level (1-4)
    "nutriscore_score",     # Numeric health score
    "traces",              # Cross-contamination: ["gluten","nuts"]
    "ingredients_text",     # Full ingredient list string
    "image_url",           # Product photo URL
    # Inflammatory score (computed for all sources)
    "inflammatory_score",
    "inflammatory_category",
    # Debugging / audit columns
    "nutrient_count",       # Total nutrients available
    "micro_count",          # Non-zero micronutrient count
    "has_serving",          # Whether serving info exists
    "data_completeness",    # 0-1 field completeness score
    "processing_notes",     # Warnings from processing
    "source_url",           # Link back to original data source
]

# ── OFF limits ──────────────────────────────────────────────────────────────────
OFF_MAX_FOODS = 500_000
