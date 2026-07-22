"""
Food Database Service - Open Food Facts API Integration with caching and USDA fallback.
"""

import httpx
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from dataclasses import dataclass
from core import branding
from core.logger import get_logger

logger = get_logger(__name__)

OFF_API_BASE_URL = "https://world.openfoodfacts.org/api/v2"
OFF_USER_AGENT = f"AIFitnessCoach/1.0 ({branding.SUPPORT_EMAIL})"

# Bump when the cached nutrient shape changes so stale rows are never served.
# v2: rows written before this carry no micronutrients at all, and a sodium value
# that the old magnitude heuristic left 1000x low for salt/bouillon/seasoning —
# serving them for the rest of their 30-day TTL would keep logging bad nutrition.
BARCODE_CACHE_KEY_VERSION = "v2"

# OFF `_100g` contract: Open Food Facts' `<nutrient>_100g` field is ALREADY
# NORMALISED TO GRAMS for every weight nutrient (sodium + all micronutrients),
# whatever unit the contributor entered. The sibling `<nutrient>_unit` describes
# the AS-ENTERED `<nutrient>_value` pair — NOT `_100g`. Applying a unit factor to
# `_100g` therefore DOUBLE-CONVERTS: an as-entered "mg" would scale the already-
# grams `_100g` down another 1000x. So we trust `_100g` as grams and never read
# `_unit`. (Verified live: barcode 0038000138416 → iron_100g=0.00107 g with
# iron_unit="g"; across ~250 products every micronutrient `_unit` API v2 returned
# was "g".) An earlier magnitude heuristic ("a small number must be grams")
# under-reported sodium 1000x for salt/bouillon/seasoning — that too is gone.

# Every micronutrient field on ProductNutrients holds GRAMS per 100g (OFF's
# native unit); every food_logs column wants mg / µg / IU. This table is the one
# place that conversion is defined:
#   field -> (create_food_log kwarg, factor from GRAMS, decimal places)
# 1 g = 1_000 mg = 1_000_000 µg. Vitamin D's column is IU and 1 µg of
# cholecalciferol = 40 IU, so grams -> IU is 1_000_000 × 40 = 40_000_000.
# The completeness check below refuses to import if a micronutrient is ever added
# to ProductNutrients without an entry here — that is how 8 nutrients previously
# shipped with no conversion at all, understated by 1,000x to 1,000,000x.
MICRONUTRIENT_LOG_FIELDS: Dict[str, Any] = {
    "vitamin_a_100g":   ("vitamin_a_ug", 1_000_000.0, 2),
    "vitamin_c_100g":   ("vitamin_c_mg", 1_000.0, 2),
    "vitamin_d_100g":   ("vitamin_d_iu", 40_000_000.0, 1),
    "calcium_100g":     ("calcium_mg", 1_000.0, 1),
    "iron_100g":        ("iron_mg", 1_000.0, 2),
    "potassium_100g":   ("potassium_mg", 1_000.0, 1),
    "magnesium_100g":   ("magnesium_mg", 1_000.0, 1),
    "zinc_100g":        ("zinc_mg", 1_000.0, 2),
    "vitamin_e_100g":   ("vitamin_e_mg", 1_000.0, 3),
    "vitamin_k_100g":   ("vitamin_k_ug", 1_000_000.0, 2),
    "vitamin_b1_100g":  ("vitamin_b1_mg", 1_000.0, 3),
    "vitamin_b2_100g":  ("vitamin_b2_mg", 1_000.0, 3),
    "vitamin_b3_100g":  ("vitamin_b3_mg", 1_000.0, 3),
    "vitamin_b6_100g":  ("vitamin_b6_mg", 1_000.0, 3),
    "vitamin_b9_100g":  ("vitamin_b9_ug", 1_000_000.0, 2),
    "vitamin_b12_100g": ("vitamin_b12_ug", 1_000_000.0, 2),
    "selenium_100g":    ("selenium_ug", 1_000_000.0, 2),
    "phosphorus_100g":  ("phosphorus_mg", 1_000.0, 3),
    "copper_100g":      ("copper_mg", 1_000.0, 3),
    "manganese_100g":   ("manganese_mg", 1_000.0, 3),
    "iodine_100g":      ("iodine_ug", 1_000_000.0, 2),
    "cholesterol_100g": ("cholesterol_mg", 1_000.0, 3),
    "omega3_100g":      ("omega3_g", 1.0, 3),
    "omega6_100g":      ("omega6_g", 1.0, 3),
}


@dataclass
class ProductNutrients:
    calories_per_100g: float
    protein_per_100g: float
    carbs_per_100g: float
    fat_per_100g: float
    fiber_per_100g: float
    sugar_per_100g: float
    # Sodium is the one nutrient carried in MILLIGRAMS per 100g (it is written
    # straight into food_logs.sodium_mg). Optional because a product OFF has no
    # sodium figure for must read as "unknown", not as a fabricated 0 mg.
    sodium_per_100g: Optional[float]
    saturated_fat_per_100g: float
    serving_size: Optional[str]
    serving_size_g: Optional[float]
    calories_per_serving: Optional[float]
    protein_per_serving: Optional[float]
    carbs_per_serving: Optional[float]
    fat_per_serving: Optional[float]
    # Micronutrients — ALWAYS GRAMS per 100g, whatever the source (OFF native,
    # or normalized into grams from the override table's µg/mg/IU columns and
    # from USDA's mg/µg). One unit for the whole surface is what makes the single
    # MICRONUTRIENT_LOG_FIELDS conversion at log time correct for every path.
    vitamin_a_100g: Optional[float] = None
    vitamin_c_100g: Optional[float] = None
    vitamin_d_100g: Optional[float] = None
    calcium_100g: Optional[float] = None
    iron_100g: Optional[float] = None
    potassium_100g: Optional[float] = None
    magnesium_100g: Optional[float] = None
    zinc_100g: Optional[float] = None
    # F5 — extended OFF micro extraction (was 8; now the full RDA-tracked set
    # OFF can carry). Same grams-per-100g contract as the eight above.
    vitamin_e_100g: Optional[float] = None
    vitamin_k_100g: Optional[float] = None
    vitamin_b1_100g: Optional[float] = None
    vitamin_b2_100g: Optional[float] = None
    vitamin_b3_100g: Optional[float] = None
    vitamin_b6_100g: Optional[float] = None
    vitamin_b9_100g: Optional[float] = None
    vitamin_b12_100g: Optional[float] = None
    selenium_100g: Optional[float] = None
    phosphorus_100g: Optional[float] = None
    copper_100g: Optional[float] = None
    manganese_100g: Optional[float] = None
    iodine_100g: Optional[float] = None
    cholesterol_100g: Optional[float] = None
    omega3_100g: Optional[float] = None
    omega6_100g: Optional[float] = None

    @classmethod
    def micronutrient_fields(cls) -> tuple:
        """Names of the micronutrient fields (all GRAMS per 100g).

        Derived from the dataclass rather than hand-listed so `to_dict`, the
        cache reader and the log-time conversion table can never drift apart —
        a hand-listed subset in `to_dict` is what stripped micros out of the
        cache and made a second scan of the same barcode log different numbers.
        """
        return tuple(
            f for f in cls.__dataclass_fields__
            if f.endswith("_100g") and not f.endswith("_per_100g")
        )

    def to_dict(self) -> Dict[str, Any]:
        d = {
            "calories_per_100g": self.calories_per_100g,
            "protein_per_100g": self.protein_per_100g,
            "carbs_per_100g": self.carbs_per_100g,
            "fat_per_100g": self.fat_per_100g,
            "fiber_per_100g": self.fiber_per_100g,
            "sugar_per_100g": self.sugar_per_100g,
            "sodium_per_100g": self.sodium_per_100g,
            "saturated_fat_per_100g": self.saturated_fat_per_100g,
            "serving_size": self.serving_size,
            "serving_size_g": self.serving_size_g,
            "calories_per_serving": self.calories_per_serving,
            "protein_per_serving": self.protein_per_serving,
            "carbs_per_serving": self.carbs_per_serving,
            "fat_per_serving": self.fat_per_serving,
        }
        # Every micronutrient that has a value — this dict IS what gets cached,
        # so anything omitted here is silently lost on the next scan.
        for key in self.micronutrient_fields():
            val = getattr(self, key)
            if val is not None and val > 0:
                d[key] = val
        return d


def unmapped_micronutrients() -> list:
    """Micronutrient fields on ProductNutrients with no grams->column mapping.

    Exposed so a unit test can `assert not unmapped_micronutrients()`. It is NOT
    raised at import: barcode.py imports this module and main.py mounts
    barcode.py, so a bare `raise` here would take the ENTIRE API down on boot
    over a mapping gap. And the failure mode is mild — the log-time loop iterates
    MICRONUTRIENT_LOG_FIELDS (not the dataclass), so an unmapped field is simply
    skipped, never written unconverted into a column. A boot crash is a wildly
    disproportionate response; a loud error log is the right severity.
    """
    return [
        f for f in ProductNutrients.micronutrient_fields()
        if f not in MICRONUTRIENT_LOG_FIELDS
    ]


_UNMAPPED_MICROS = unmapped_micronutrients()
if _UNMAPPED_MICROS:
    logger.error(
        "MICRONUTRIENT_LOG_FIELDS is missing a grams->column conversion for: "
        f"{', '.join(_UNMAPPED_MICROS)}. These nutrients will not be logged "
        "until a mapping is added."
    )


@dataclass
class BarcodeProduct:
    barcode: str
    product_name: str
    brand: Optional[str]
    categories: Optional[str]
    image_url: Optional[str]
    image_thumb_url: Optional[str]
    nutrients: ProductNutrients
    nutriscore_grade: Optional[str]
    nova_group: Optional[int]
    ingredients_text: Optional[str]
    allergens: Optional[str]
    ecoscore_grade: Optional[str] = None
    labels_tags: Optional[list] = None
    additives_tags: Optional[list] = None

    def to_dict(self) -> Dict[str, Any]:
        d = {
            "barcode": self.barcode,
            "product_name": self.product_name,
            "brand": self.brand,
            "categories": self.categories,
            "image_url": self.image_url,
            "image_thumb_url": self.image_thumb_url,
            "nutrients": self.nutrients.to_dict(),
            "nutriscore_grade": self.nutriscore_grade,
            "nova_group": self.nova_group,
            "ingredients_text": self.ingredients_text,
            "allergens": self.allergens,
        }
        if self.ecoscore_grade:
            d["ecoscore_grade"] = self.ecoscore_grade
        if self.labels_tags:
            d["labels_tags"] = self.labels_tags
        if self.additives_tags:
            d["additives_tags"] = self.additives_tags
        return d


class FoodDatabaseService:
    def __init__(self):
        self._http_client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._http_client is None or self._http_client.is_closed:
            self._http_client = httpx.AsyncClient(
                timeout=httpx.Timeout(20.0, connect=5.0),  # Increased from 10s to 20s
                headers={"User-Agent": OFF_USER_AGENT, "Accept": "application/json"}
            )
        return self._http_client

    async def close(self):
        if self._http_client is not None:
            await self._http_client.aclose()
            self._http_client = None

    def _parse_float(self, value: Any, default: float = 0.0) -> float:
        if value is None:
            return default
        try:
            return float(value)
        except (ValueError, TypeError):
            return default

    def _off_grams_per_100g(self, nutriments: Dict[str, Any], *keys: str) -> Optional[float]:
        """Read an OFF nutrient as GRAMS per 100g from its `_100g` field.

        Contract (see the OFF `_100g` note above): OFF's `<key>_100g` is ALREADY
        grams for every weight nutrient, regardless of the as-entered `_unit`, so
        we return it verbatim — applying a unit factor here would double-convert.
        We deliberately do NOT consult `_unit`: it only ever described the sibling
        `_value`, and gating on it silently dropped legitimate values (sodium →
        NULL) whenever the unit string was "iu"/"% dv"/absent, a regression from
        products that previously reported those nutrients fine.

        Returns None when OFF carries no value for any of `keys`. A 0 under one
        synonym key is treated as absent so it cannot shadow a real value under
        the next key (vitamin-b9_100g:0 must fall through to folates_100g); the
        downstream `x or None` collapses 0 to None anyway, so nothing is lost.
        """
        for key in keys:
            raw = nutriments.get(f"{key}_100g")
            if raw is None:
                continue
            try:
                value = float(raw)
            except (TypeError, ValueError):
                continue
            if value == 0:
                continue
            return value
        return None

    def _parse_nutrients(self, nutriments: Dict[str, Any], product: Dict[str, Any]) -> ProductNutrients:
        calories = self._parse_float(nutriments.get("energy-kcal_100g"))
        if calories == 0:
            energy_kj = self._parse_float(nutriments.get("energy_100g"))
            calories = energy_kj / 4.184 if energy_kj > 0 else 0

        protein = self._parse_float(nutriments.get("proteins_100g"))
        carbs = self._parse_float(nutriments.get("carbohydrates_100g"))
        fat = self._parse_float(nutriments.get("fat_100g"))
        fiber = self._parse_float(nutriments.get("fiber_100g"))
        sugar = self._parse_float(nutriments.get("sugars_100g"))
        saturated_fat = self._parse_float(nutriments.get("saturated-fat_100g"))

        # Sodium and every micronutrient go through the declared-unit reader:
        # OFF publishes the unit per nutrient, so there is never a reason to
        # infer one from how big the number looks.
        grams = self._off_grams_per_100g
        sodium = grams(nutriments, "sodium")

        # Micronutrients from Open Food Facts — GRAMS per 100g, NOT rounded here.
        # Vitamin A/D and zinc are ~0.0009 g, so rounding at gram scale flattened
        # them to 0.0 and destroyed them before the g -> mg/µg conversion at log
        # time ever ran. Convert first, round last.
        vitamin_a = grams(nutriments, "vitamin-a")
        vitamin_c = grams(nutriments, "vitamin-c")
        vitamin_d = grams(nutriments, "vitamin-d")
        calcium = grams(nutriments, "calcium")
        iron = grams(nutriments, "iron")
        potassium = grams(nutriments, "potassium")
        magnesium = grams(nutriments, "magnesium")
        zinc = grams(nutriments, "zinc")
        # F5 — extended micros. Same grams-per-100g contract; the alternate keys
        # are OFF's synonyms (niacin is filed under `vitamin-pp`, folate under
        # `folates` on older entries).
        vit_e = grams(nutriments, "vitamin-e")
        vit_k = grams(nutriments, "vitamin-k")
        vit_b1 = grams(nutriments, "vitamin-b1")
        vit_b2 = grams(nutriments, "vitamin-b2")
        vit_b3 = grams(nutriments, "vitamin-pp", "vitamin-b3")
        vit_b6 = grams(nutriments, "vitamin-b6")
        vit_b9 = grams(nutriments, "vitamin-b9", "folates")
        vit_b12 = grams(nutriments, "vitamin-b12")
        selenium = grams(nutriments, "selenium")
        phosphorus = grams(nutriments, "phosphorus")
        copper = grams(nutriments, "copper")
        manganese = grams(nutriments, "manganese")
        iodine = grams(nutriments, "iodine")
        cholesterol = grams(nutriments, "cholesterol")
        omega3 = grams(nutriments, "omega-3-fat")
        omega6 = grams(nutriments, "omega-6-fat")

        serving_size = product.get("serving_size")
        serving_quantity = self._parse_float(product.get("serving_quantity"))

        cals_srv = prot_srv = carbs_srv = fat_srv = None
        if serving_quantity and serving_quantity > 0:
            mult = serving_quantity / 100.0
            cals_srv = round(calories * mult, 1)
            prot_srv = round(protein * mult, 1)
            carbs_srv = round(carbs * mult, 1)
            fat_srv = round(fat * mult, 1)

        return ProductNutrients(
            calories_per_100g=round(calories, 1),
            protein_per_100g=round(protein, 1),
            carbs_per_100g=round(carbs, 1),
            fat_per_100g=round(fat, 1),
            fiber_per_100g=round(fiber, 1),
            sugar_per_100g=round(sugar, 1),
            # 1 g = 1000 mg. `sodium` is already grams (declared unit applied),
            # so this is the only sodium conversion — no magnitude test.
            sodium_per_100g=round(sodium * 1000, 1) if sodium is not None else None,
            saturated_fat_per_100g=round(saturated_fat, 1),
            serving_size=serving_size,
            serving_size_g=serving_quantity if serving_quantity > 0 else None,
            calories_per_serving=cals_srv,
            protein_per_serving=prot_srv,
            carbs_per_serving=carbs_srv,
            fat_per_serving=fat_srv,
            vitamin_a_100g=vitamin_a or None,
            vitamin_c_100g=vitamin_c or None,
            vitamin_d_100g=vitamin_d or None,
            calcium_100g=calcium or None,
            iron_100g=iron or None,
            potassium_100g=potassium or None,
            magnesium_100g=magnesium or None,
            zinc_100g=zinc or None,
            vitamin_e_100g=vit_e or None,
            vitamin_k_100g=vit_k or None,
            vitamin_b1_100g=vit_b1 or None,
            vitamin_b2_100g=vit_b2 or None,
            vitamin_b3_100g=vit_b3 or None,
            vitamin_b6_100g=vit_b6 or None,
            vitamin_b9_100g=vit_b9 or None,
            vitamin_b12_100g=vit_b12 or None,
            selenium_100g=selenium or None,
            phosphorus_100g=phosphorus or None,
            copper_100g=copper or None,
            manganese_100g=manganese or None,
            iodine_100g=iodine or None,
            cholesterol_100g=cholesterol or None,
            omega3_100g=omega3 or None,
            omega6_100g=omega6 or None,
        )

    def _is_valid_barcode(self, barcode: str) -> bool:
        """Validate that the barcode looks like a real barcode (numeric, proper length)."""
        # Barcodes should be numeric and between 8-14 digits
        # UPC-A: 12 digits, EAN-13: 13 digits, UPC-E: 8 digits, EAN-8: 8 digits
        if not barcode:
            return False
        if not barcode.isdigit():
            return False
        if len(barcode) < 8 or len(barcode) > 14:
            return False
        return True

    @staticmethod
    def _normalize_barcode(barcode: str) -> str:
        """Normalize scanned codes so DB/OFF lookups collide.

        UPC-A is 12 digits; the same product is stored as EAN-13 (13 digits)
        with a leading zero in most databases (including Open Food Facts and our
        `food_nutrition_overrides.barcode`). So we left-pad a 12-digit UPC-A to
        13 with a leading 0. Other lengths (EAN-8, EAN-13, ITF-14) pass through.
        """
        b = (barcode or "").strip().replace(" ", "").replace("-", "")
        if len(b) == 12 and b.isdigit():
            return "0" + b
        return b

    def _lookup_override_by_barcode(
        self, barcode: str, country: Optional[str] = None
    ) -> Optional["BarcodeProduct"]:
        """F1 — try the verified `food_nutrition_overrides.barcode` match FIRST.

        Short-circuits the OFF/USDA round-trip when the community-curated table
        already has this exact code (migration 2224 added the column + index).
        When several rows share a code, prefer the one matching the user's
        country, else the first. Returns None on no match / any error — the
        caller then falls through to OFF.
        """
        try:
            from core.db import get_supabase_db
            db = get_supabase_db()
            q = (
                db.client.table("food_nutrition_overrides")
                .select("*")
                .eq("barcode", barcode)
                .limit(10)
                .execute()
            )
            rows = [r for r in (q.data or []) if r.get("is_active", True)]
            if not rows:
                return None
            row = rows[0]
            if country and len(rows) > 1:
                for r in rows:
                    rc = (r.get("country_name") or "").lower()
                    if rc and country.lower() in rc:
                        row = r
                        break

            # food_nutrition_overrides stores per-100g macros + micros.
            def _f(k):
                v = row.get(k)
                try:
                    return float(v) if v is not None else 0.0
                except (TypeError, ValueError):
                    return 0.0

            def _of(k):
                """Optional read — a NULL column stays NULL, never a fabricated 0."""
                v = row.get(k)
                try:
                    return float(v) if v is not None else None
                except (TypeError, ValueError):
                    return None

            # This table stores micros in DISPLAY units (µg / mg / IU) while
            # ProductNutrients carries GRAMS, so normalize on the way in.
            # Skipping this would make the single grams->column conversion at log
            # time fire on an already-converted number (1,000,000x over-report).
            _MG = 0.001        # 1 mg = 0.001 g
            _UG = 0.000001     # 1 µg = 0.000001 g
            _IU_VIT_D = _UG / 40.0   # 40 IU of vitamin D = 1 µg cholecalciferol

            def _g(k, unit_in_grams):
                v = _of(k)
                return v * unit_in_grams if v else None

            nutrients = ProductNutrients(
                calories_per_100g=_f("calories_per_100g"),
                protein_per_100g=_f("protein_per_100g"),
                carbs_per_100g=_f("carbs_per_100g"),
                fat_per_100g=_f("fat_per_100g"),
                fiber_per_100g=_f("fiber_per_100g"),
                sugar_per_100g=_f("sugar_per_100g"),
                sodium_per_100g=_of("sodium_mg"),
                saturated_fat_per_100g=_f("saturated_fat_g"),
                serving_size=None,
                serving_size_g=row.get("default_serving_g"),
                calories_per_serving=None,
                protein_per_serving=None,
                carbs_per_serving=None,
                fat_per_serving=None,
                vitamin_a_100g=_g("vitamin_a_ug", _UG),
                vitamin_c_100g=_g("vitamin_c_mg", _MG),
                vitamin_d_100g=_g("vitamin_d_iu", _IU_VIT_D),
                calcium_100g=_g("calcium_mg", _MG),
                iron_100g=_g("iron_mg", _MG),
                potassium_100g=_g("potassium_mg", _MG),
                magnesium_100g=_g("magnesium_mg", _MG),
                zinc_100g=_g("zinc_mg", _MG),
                # The override table carries the extended set too — pass it
                # through rather than dropping curated data on the floor.
                vitamin_e_100g=_g("vitamin_e_mg", _MG),
                vitamin_k_100g=_g("vitamin_k_ug", _UG),
                vitamin_b1_100g=_g("vitamin_b1_mg", _MG),
                vitamin_b2_100g=_g("vitamin_b2_mg", _MG),
                vitamin_b3_100g=_g("vitamin_b3_mg", _MG),
                vitamin_b6_100g=_g("vitamin_b6_mg", _MG),
                vitamin_b9_100g=_g("vitamin_b9_ug", _UG),
                vitamin_b12_100g=_g("vitamin_b12_ug", _UG),
                selenium_100g=_g("selenium_ug", _UG),
                phosphorus_100g=_g("phosphorus_mg", _MG),
                copper_100g=_g("copper_mg", _MG),
                manganese_100g=_g("manganese_mg", _MG),
                cholesterol_100g=_g("cholesterol_mg", _MG),
                omega3_100g=_g("omega3_g", 1.0),
                omega6_100g=_g("omega6_g", 1.0),
            )
            logger.info(
                f"[Barcode] verified override hit for {barcode} "
                f"({row.get('display_name') or row.get('food_name_normalized')})"
            )
            return BarcodeProduct(
                barcode=barcode,
                product_name=row.get("display_name") or row.get("food_name_normalized") or "Unknown Product",
                brand=row.get("restaurant_name"),
                categories=row.get("food_category"),
                image_url=None,
                image_thumb_url=None,
                nutrients=nutrients,
                nutriscore_grade=None,
                nova_group=None,
                ingredients_text=None,
                allergens=None,
            )
        except Exception as e:
            logger.debug(f"[Barcode] override-by-barcode lookup skipped for {barcode}: {e}")
            return None

    async def lookup_barcode(
        self, barcode: str, country: Optional[str] = None
    ) -> Optional[BarcodeProduct]:
        """
        Look up a barcode with caching, verified-override short-circuit, and
        USDA fallback.

        Flow:
        0. Normalize the code (UPC-A 12 → EAN-13 13).
        1. Verified `food_nutrition_overrides.barcode` match (F1) — short-circuit.
        2. Check cache.
        3. Try Open Food Facts API.
        4. If not found, try USDA as fallback.
        5. Cache the result for future lookups.
        """
        barcode = self._normalize_barcode(barcode)
        if not barcode:
            logger.warning("Empty barcode provided")
            return None

        # Validate barcode format
        if not self._is_valid_barcode(barcode):
            logger.warning(f"Invalid barcode format: {barcode[:50]}...")
            return None

        # 1. Verified override short-circuit (community-curated, highest trust).
        override_hit = self._lookup_override_by_barcode(barcode, country=country)
        if override_hit:
            return override_hit

        # 2. Check cache
        cached = self._get_cached_barcode(barcode)
        if cached:
            logger.info(f"Cache hit for barcode: {barcode}")
            return cached

        logger.info(f"Looking up barcode: {barcode}")

        # 3. Try Open Food Facts
        result = await self._lookup_open_food_facts(barcode)
        from_off = result is not None

        # 4. If not found, try USDA fallback
        if not result:
            result = await self._lookup_usda_barcode(barcode)

        # 3b. Gap 2 — serving-size arbitration. OFF often reports a flat 100g
        # default that is not the real label serving; resolve a realistic one
        # by cross-checking USDA + (only if still ambiguous) a cheap LLM call.
        # Runs only on a cache MISS with a suspicious serving, then the result
        # is cached below — so this fires at most once per product.
        if result:
            await self._resolve_serving_size(result, barcode, from_off=from_off)

        # 4. Cache the result (30-day TTL)
        if result:
            self._cache_barcode_result(barcode, result)

        return result

    async def _resolve_serving_size(
        self, product: "BarcodeProduct", barcode: str, *, from_off: bool
    ) -> None:
        """Gap 2 — fix OFF's suspicious ~100g default serving in place.

        No-op when the product already carries a credible (non-100g) serving.
        Otherwise gathers candidates from the other DB (USDA when the primary
        was OFF) and resolves deterministically, falling back to one cheap
        Flash-Lite call only when every candidate is missing/100g. Best-effort:
        any failure leaves the original serving untouched.
        """
        try:
            from services.food_analysis.serving_arbitration import (
                _is_suspicious,
                pick_deterministic_serving,
                resolve_serving_with_llm,
            )

            nutr = product.nutrients
            if not _is_suspicious(nutr.serving_size_g):
                return  # already a credible label serving — trust it

            candidates = [{
                "source": "off" if from_off else "usda",
                "serving_size_g": nutr.serving_size_g,
                "serving_label": nutr.serving_size,
            }]

            # Cross-check the OTHER database for a real serving. When the primary
            # was OFF (the usual case), USDA frequently has the true label serving.
            if from_off:
                try:
                    usda_product = await self._lookup_usda_barcode(barcode)
                    if usda_product:
                        candidates.append({
                            "source": "usda",
                            "serving_size_g": usda_product.nutrients.serving_size_g,
                            "serving_label": usda_product.nutrients.serving_size,
                        })
                except Exception as e:
                    logger.debug(f"USDA serving cross-check skipped: {e}")

            resolved = pick_deterministic_serving(candidates)
            if resolved is None:
                resolved = await resolve_serving_with_llm(
                    product_name=product.product_name,
                    brand=product.brand,
                    candidates=candidates,
                    categories=product.categories,
                )
            if resolved and resolved.get("serving_size_g"):
                nutr.serving_size_g = float(resolved["serving_size_g"])
                if resolved.get("serving_label"):
                    nutr.serving_size = resolved["serving_label"]
                logger.info(
                    f"[ServingArbiter] barcode {barcode}: serving resolved to "
                    f"{nutr.serving_size_g}g via {resolved.get('source')}"
                )
        except Exception as e:
            logger.warning(f"[ServingArbiter] resolution skipped for {barcode}: {e}")

    def _get_cached_barcode(self, barcode: str) -> Optional[BarcodeProduct]:
        """Check food_search_cache for barcode result."""
        try:
            from core.db import get_supabase_db
            db = get_supabase_db()

            result = db.client.table("food_search_cache") \
                .select("results") \
                .eq("query_hash", f"barcode:{BARCODE_CACHE_KEY_VERSION}:{barcode}") \
                .eq("source", "barcode") \
                .gt("expires_at", datetime.utcnow().isoformat()) \
                .limit(1) \
                .execute()

            if result.data and len(result.data) > 0:
                cached_data = result.data[0]["results"]
                # Reconstruct BarcodeProduct from cached dict. Restore EVERY
                # micronutrient the cache holds (derived from the dataclass, so a
                # new nutrient is picked up automatically) — a partial rebuild is
                # why scanning the same barcode twice logged different nutrition
                # the second time.
                nutrients_data = cached_data.get("nutrients", {})
                micro_kwargs = {
                    f: nutrients_data.get(f)
                    for f in ProductNutrients.micronutrient_fields()
                }
                nutrients = ProductNutrients(
                    calories_per_100g=nutrients_data.get("calories_per_100g", 0),
                    protein_per_100g=nutrients_data.get("protein_per_100g", 0),
                    carbs_per_100g=nutrients_data.get("carbs_per_100g", 0),
                    fat_per_100g=nutrients_data.get("fat_per_100g", 0),
                    fiber_per_100g=nutrients_data.get("fiber_per_100g", 0),
                    sugar_per_100g=nutrients_data.get("sugar_per_100g", 0),
                    sodium_per_100g=nutrients_data.get("sodium_per_100g"),
                    saturated_fat_per_100g=nutrients_data.get("saturated_fat_per_100g", 0),
                    serving_size=nutrients_data.get("serving_size"),
                    serving_size_g=nutrients_data.get("serving_size_g"),
                    calories_per_serving=nutrients_data.get("calories_per_serving"),
                    protein_per_serving=nutrients_data.get("protein_per_serving"),
                    carbs_per_serving=nutrients_data.get("carbs_per_serving"),
                    fat_per_serving=nutrients_data.get("fat_per_serving"),
                    **micro_kwargs,
                )
                return BarcodeProduct(
                    barcode=cached_data.get("barcode", barcode),
                    product_name=cached_data.get("product_name", "Unknown"),
                    brand=cached_data.get("brand"),
                    categories=cached_data.get("categories"),
                    image_url=cached_data.get("image_url"),
                    image_thumb_url=cached_data.get("image_thumb_url"),
                    nutrients=nutrients,
                    nutriscore_grade=cached_data.get("nutriscore_grade"),
                    nova_group=cached_data.get("nova_group"),
                    ingredients_text=cached_data.get("ingredients_text"),
                    allergens=cached_data.get("allergens"),
                    # Cached by to_dict() but previously never read back, so the
                    # second scan lost the eco/labels/additives badges.
                    ecoscore_grade=cached_data.get("ecoscore_grade"),
                    labels_tags=cached_data.get("labels_tags"),
                    additives_tags=cached_data.get("additives_tags"),
                )
        except Exception as e:
            logger.warning(f"Cache lookup failed: {e}", exc_info=True)
        return None

    def _cache_barcode_result(self, barcode: str, product: BarcodeProduct):
        """Store barcode result in cache (30-day TTL)."""
        try:
            from core.db import get_supabase_db
            db = get_supabase_db()

            expires_at = datetime.utcnow() + timedelta(days=30)

            db.client.table("food_search_cache").upsert({
                "query_hash": f"barcode:{BARCODE_CACHE_KEY_VERSION}:{barcode}",
                "query_text": barcode,
                "source": "barcode",
                "results": product.to_dict(),
                "expires_at": expires_at.isoformat(),
            }, on_conflict="query_hash").execute()

            logger.info(f"Cached barcode result: {barcode}")
        except Exception as e:
            logger.warning(f"Failed to cache barcode: {e}", exc_info=True)

    async def _lookup_open_food_facts(self, barcode: str) -> Optional[BarcodeProduct]:
        """Look up barcode in Open Food Facts database."""
        try:
            client = await self._get_client()
            url = f"{OFF_API_BASE_URL}/product/{barcode}"
            params = {
                # F5 — `nutriments` returns ALL per-100g nutrient keys OFF has
                # for the product (vitamins/minerals/fatty acids included), so
                # the extended micro extraction works without enumerating each
                # micro field here.
                "fields": "code,product_name,brands,categories,image_url,image_small_url,"
                         "nutriments,serving_size,serving_quantity,nutriscore_grade,"
                         "nova_group,ingredients_text,allergens,"
                         "ecoscore_grade,labels_tags,additives_tags"
            }

            response = await client.get(url, params=params)

            if response.status_code == 404:
                logger.info(f"Product not found in OFF for barcode: {barcode}")
                return None

            response.raise_for_status()
            data = response.json()

            if data.get("status") != 1:
                logger.info(f"Product not found in OFF database for barcode: {barcode}")
                return None

            product = data.get("product", {})
            if not product:
                logger.warning(f"Empty product data for barcode: {barcode}")
                return None

            product_name = product.get("product_name") or product.get("product_name_en") or "Unknown Product"
            nutriments = product.get("nutriments", {})
            nutrients = self._parse_nutrients(nutriments, product)

            nova_group = product.get("nova_group")
            if nova_group:
                try:
                    nova_group = int(nova_group)
                except (ValueError, TypeError):
                    nova_group = None

            # Parse labels tags — strip language prefixes like "en:"
            raw_labels = product.get("labels_tags")
            labels_tags = None
            if raw_labels and isinstance(raw_labels, list):
                labels_tags = [
                    tag.split(":")[-1].replace("-", " ").title()
                    for tag in raw_labels
                    if isinstance(tag, str) and tag.strip()
                ]
                labels_tags = labels_tags if labels_tags else None

            # Parse additives tags — strip language prefixes
            raw_additives = product.get("additives_tags")
            additives_tags = None
            if raw_additives and isinstance(raw_additives, list):
                additives_tags = [
                    tag.split(":")[-1].upper()
                    for tag in raw_additives
                    if isinstance(tag, str) and tag.strip()
                ]
                additives_tags = additives_tags if additives_tags else None

            result = BarcodeProduct(
                barcode=barcode,
                product_name=product_name,
                brand=product.get("brands"),
                categories=product.get("categories"),
                image_url=product.get("image_url"),
                image_thumb_url=product.get("image_small_url"),
                nutrients=nutrients,
                nutriscore_grade=product.get("nutriscore_grade"),
                nova_group=nova_group,
                ingredients_text=product.get("ingredients_text"),
                allergens=product.get("allergens"),
                ecoscore_grade=product.get("ecoscore_grade"),
                labels_tags=labels_tags,
                additives_tags=additives_tags,
            )

            logger.info(f"Found product in OFF: {product_name} (barcode: {barcode})")
            return result

        except httpx.TimeoutException:
            logger.error(f"Timeout looking up barcode in OFF: {barcode}", exc_info=True)
            raise Exception("Request timed out. Please try again.")
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error looking up barcode {barcode}: {e}", exc_info=True)
            raise Exception(f"API error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"Error looking up barcode {barcode}: {e}", exc_info=True)
            raise

    async def _lookup_usda_barcode(self, barcode: str) -> Optional[BarcodeProduct]:
        """Search USDA for products matching this barcode (gtin_upc)."""
        try:
            from services.usda_food_service import get_usda_food_service, NUTRIENT_IDS

            usda = get_usda_food_service()

            # Check if USDA is configured
            if not usda._is_configured():
                logger.info("USDA API not configured, skipping fallback")
                return None

            # Search USDA branded foods by barcode
            result = await usda.search_branded_foods(query=barcode, page_size=5)

            # Find exact barcode match (gtin_upc field)
            for food in result.foods:
                if food.gtin_upc == barcode:
                    un = food.nutrients
                    present = un.present_nutrient_ids or set()

                    # USDA already fetched every micronutrient below — it used to
                    # be parsed and then thrown away, so a USDA-only product
                    # logged zero vitamins. USDA reports in mg / µg / g and this
                    # dataclass is GRAMS per 100g, so scale on the way in.
                    _MG = 0.001        # 1 mg = 0.001 g
                    _UG = 0.000001     # 1 µg = 0.000001 g

                    def _u(usda_key: str, value: float, unit_in_grams: float):
                        """None unless USDA actually reported this nutrient.

                        The USDANutrients floats default to 0.0 whether USDA
                        measured a zero or never carried the nutrient at all;
                        `present_nutrient_ids` is the only way to tell, and
                        logging an unmeasured nutrient as 0 would fake a
                        deficiency in RDA tracking.
                        """
                        nid = NUTRIENT_IDS.get(usda_key)
                        if nid is None or nid not in present or not value:
                            return None
                        return value * unit_in_grams

                    # Convert USDA food to BarcodeProduct format
                    nutrients = ProductNutrients(
                        calories_per_100g=un.calories_per_100g,
                        protein_per_100g=un.protein_per_100g,
                        carbs_per_100g=un.carbs_per_100g,
                        fat_per_100g=un.fat_per_100g,
                        fiber_per_100g=un.fiber_per_100g,
                        sugar_per_100g=un.sugar_per_100g,
                        sodium_per_100g=(
                            un.sodium_mg_per_100g
                            if NUTRIENT_IDS["sodium"] in present else None
                        ),
                        saturated_fat_per_100g=un.saturated_fat_per_100g,
                        serving_size=un.serving_size,
                        serving_size_g=un.serving_size_g,
                        calories_per_serving=None,
                        protein_per_serving=None,
                        carbs_per_serving=None,
                        fat_per_serving=None,
                        vitamin_a_100g=_u("vitamin_a", un.vitamin_a_mcg_per_100g, _UG),
                        vitamin_c_100g=_u("vitamin_c", un.vitamin_c_mg_per_100g, _MG),
                        vitamin_d_100g=_u("vitamin_d", un.vitamin_d_mcg_per_100g, _UG),
                        calcium_100g=_u("calcium", un.calcium_mg_per_100g, _MG),
                        iron_100g=_u("iron", un.iron_mg_per_100g, _MG),
                        potassium_100g=_u("potassium", un.potassium_mg_per_100g, _MG),
                        magnesium_100g=_u("magnesium", un.magnesium_mg_per_100g, _MG),
                        zinc_100g=_u("zinc", un.zinc_mg_per_100g, _MG),
                        vitamin_e_100g=_u("vitamin_e", un.vitamin_e_mg_per_100g, _MG),
                        vitamin_k_100g=_u("vitamin_k", un.vitamin_k_ug_per_100g, _UG),
                        vitamin_b1_100g=_u("vitamin_b1", un.vitamin_b1_mg_per_100g, _MG),
                        vitamin_b2_100g=_u("vitamin_b2", un.vitamin_b2_mg_per_100g, _MG),
                        vitamin_b3_100g=_u("vitamin_b3", un.vitamin_b3_mg_per_100g, _MG),
                        vitamin_b6_100g=_u("vitamin_b6", un.vitamin_b6_mg_per_100g, _MG),
                        vitamin_b9_100g=_u("folate", un.folate_mcg_per_100g, _UG),
                        vitamin_b12_100g=_u("vitamin_b12", un.vitamin_b12_mcg_per_100g, _UG),
                        selenium_100g=_u("selenium", un.selenium_ug_per_100g, _UG),
                        phosphorus_100g=_u("phosphorus", un.phosphorus_mg_per_100g, _MG),
                        copper_100g=_u("copper", un.copper_mg_per_100g, _MG),
                        manganese_100g=_u("manganese", un.manganese_mg_per_100g, _MG),
                        # USDA has no iodine nutrient id — stays unknown.
                        iodine_100g=None,
                        cholesterol_100g=_u("cholesterol", un.cholesterol_mg_per_100g, _MG),
                        # Already summed from the individual fatty-acid ids, so a
                        # non-zero total means at least one id was present.
                        omega3_100g=un.omega3_g_per_100g or None,
                        omega6_100g=un.omega6_g_per_100g or None,
                    )

                    result = BarcodeProduct(
                        barcode=barcode,
                        product_name=food.description,
                        brand=food.brand_owner or food.brand_name,
                        categories=food.food_category,
                        image_url=None,  # USDA doesn't provide images
                        image_thumb_url=None,
                        nutrients=nutrients,
                        nutriscore_grade=None,
                        nova_group=None,
                        ingredients_text=food.ingredients,
                        allergens=None,
                    )

                    logger.info(f"Found product in USDA: {food.description} (barcode: {barcode})")
                    return result

            logger.info(f"Barcode not found in USDA: {barcode}")
            return None

        except Exception as e:
            logger.warning(f"USDA fallback failed: {e}", exc_info=True)
            return None


_food_database_service: Optional[FoodDatabaseService] = None


def get_food_database_service() -> FoodDatabaseService:
    global _food_database_service
    if _food_database_service is None:
        _food_database_service = FoodDatabaseService()
    return _food_database_service
