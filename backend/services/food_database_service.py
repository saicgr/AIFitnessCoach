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


@dataclass
class ProductNutrients:
    calories_per_100g: float
    protein_per_100g: float
    carbs_per_100g: float
    fat_per_100g: float
    fiber_per_100g: float
    sugar_per_100g: float
    sodium_per_100g: float
    saturated_fat_per_100g: float
    serving_size: Optional[str]
    serving_size_g: Optional[float]
    calories_per_serving: Optional[float]
    protein_per_serving: Optional[float]
    carbs_per_serving: Optional[float]
    fat_per_serving: Optional[float]
    # Micronutrients (from Open Food Facts)
    vitamin_a_100g: Optional[float] = None
    vitamin_c_100g: Optional[float] = None
    vitamin_d_100g: Optional[float] = None
    calcium_100g: Optional[float] = None
    iron_100g: Optional[float] = None
    potassium_100g: Optional[float] = None
    magnesium_100g: Optional[float] = None
    zinc_100g: Optional[float] = None
    # F5 — extended OFF micro extraction (was 8; now the full RDA-tracked set
    # OFF can carry). Units below are the OFF native units we convert at log
    # time to match nutrient_rdas (vit A µg, vit D IU, etc.).
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
        # Only include micronutrients that have values
        for key in ("vitamin_a_100g", "vitamin_c_100g", "vitamin_d_100g",
                     "calcium_100g", "iron_100g", "potassium_100g",
                     "magnesium_100g", "zinc_100g"):
            val = getattr(self, key)
            if val is not None and val > 0:
                d[key] = val
        return d


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
        sodium = self._parse_float(nutriments.get("sodium_100g"))
        saturated_fat = self._parse_float(nutriments.get("saturated-fat_100g"))

        # Micronutrients from Open Food Facts
        vitamin_a = self._parse_float(nutriments.get("vitamin-a_100g"))
        vitamin_c = self._parse_float(nutriments.get("vitamin-c_100g"))
        vitamin_d = self._parse_float(nutriments.get("vitamin-d_100g"))
        calcium = self._parse_float(nutriments.get("calcium_100g"))
        iron = self._parse_float(nutriments.get("iron_100g"))
        potassium = self._parse_float(nutriments.get("potassium_100g"))
        magnesium = self._parse_float(nutriments.get("magnesium_100g"))
        zinc = self._parse_float(nutriments.get("zinc_100g"))
        # F5 — extended micros (OFF native units, mostly grams per 100g except
        # the IU/µg vitamins, converted at log time).
        vit_e = self._parse_float(nutriments.get("vitamin-e_100g"))
        vit_k = self._parse_float(nutriments.get("vitamin-k_100g"))
        vit_b1 = self._parse_float(nutriments.get("vitamin-b1_100g"))
        vit_b2 = self._parse_float(nutriments.get("vitamin-b2_100g"))
        vit_b3 = self._parse_float(nutriments.get("vitamin-pp_100g") or nutriments.get("vitamin-b3_100g"))
        vit_b6 = self._parse_float(nutriments.get("vitamin-b6_100g"))
        vit_b9 = self._parse_float(nutriments.get("vitamin-b9_100g") or nutriments.get("folates_100g"))
        vit_b12 = self._parse_float(nutriments.get("vitamin-b12_100g"))
        selenium = self._parse_float(nutriments.get("selenium_100g"))
        phosphorus = self._parse_float(nutriments.get("phosphorus_100g"))
        copper = self._parse_float(nutriments.get("copper_100g"))
        manganese = self._parse_float(nutriments.get("manganese_100g"))
        iodine = self._parse_float(nutriments.get("iodine_100g"))
        cholesterol = self._parse_float(nutriments.get("cholesterol_100g"))
        omega3 = self._parse_float(nutriments.get("omega-3-fat_100g"))
        omega6 = self._parse_float(nutriments.get("omega-6-fat_100g"))

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
            sodium_per_100g=round(sodium * 1000, 1) if sodium < 10 else round(sodium, 1),
            saturated_fat_per_100g=round(saturated_fat, 1),
            serving_size=serving_size,
            serving_size_g=serving_quantity if serving_quantity > 0 else None,
            calories_per_serving=cals_srv,
            protein_per_serving=prot_srv,
            carbs_per_serving=carbs_srv,
            fat_per_serving=fat_srv,
            vitamin_a_100g=round(vitamin_a, 2) if vitamin_a > 0 else None,
            vitamin_c_100g=round(vitamin_c, 2) if vitamin_c > 0 else None,
            vitamin_d_100g=round(vitamin_d, 2) if vitamin_d > 0 else None,
            calcium_100g=round(calcium, 1) if calcium > 0 else None,
            iron_100g=round(iron, 2) if iron > 0 else None,
            potassium_100g=round(potassium, 1) if potassium > 0 else None,
            magnesium_100g=round(magnesium, 1) if magnesium > 0 else None,
            zinc_100g=round(zinc, 2) if zinc > 0 else None,
            vitamin_e_100g=round(vit_e, 4) if vit_e > 0 else None,
            vitamin_k_100g=round(vit_k, 6) if vit_k > 0 else None,
            vitamin_b1_100g=round(vit_b1, 4) if vit_b1 > 0 else None,
            vitamin_b2_100g=round(vit_b2, 4) if vit_b2 > 0 else None,
            vitamin_b3_100g=round(vit_b3, 4) if vit_b3 > 0 else None,
            vitamin_b6_100g=round(vit_b6, 4) if vit_b6 > 0 else None,
            vitamin_b9_100g=round(vit_b9, 8) if vit_b9 > 0 else None,
            vitamin_b12_100g=round(vit_b12, 8) if vit_b12 > 0 else None,
            selenium_100g=round(selenium, 8) if selenium > 0 else None,
            phosphorus_100g=round(phosphorus, 4) if phosphorus > 0 else None,
            copper_100g=round(copper, 6) if copper > 0 else None,
            manganese_100g=round(manganese, 6) if manganese > 0 else None,
            iodine_100g=round(iodine, 8) if iodine > 0 else None,
            cholesterol_100g=round(cholesterol, 4) if cholesterol > 0 else None,
            omega3_100g=round(omega3, 4) if omega3 > 0 else None,
            omega6_100g=round(omega6, 4) if omega6 > 0 else None,
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

            nutrients = ProductNutrients(
                calories_per_100g=_f("calories_per_100g"),
                protein_per_100g=_f("protein_per_100g"),
                carbs_per_100g=_f("carbs_per_100g"),
                fat_per_100g=_f("fat_per_100g"),
                fiber_per_100g=_f("fiber_per_100g"),
                sugar_per_100g=_f("sugar_per_100g"),
                sodium_per_100g=_f("sodium_mg"),
                saturated_fat_per_100g=_f("saturated_fat_g"),
                serving_size=None,
                serving_size_g=row.get("default_serving_g"),
                calories_per_serving=None,
                protein_per_serving=None,
                carbs_per_serving=None,
                fat_per_serving=None,
                vitamin_a_100g=row.get("vitamin_a_ug"),
                vitamin_c_100g=row.get("vitamin_c_mg"),
                vitamin_d_100g=row.get("vitamin_d_iu"),
                calcium_100g=row.get("calcium_mg"),
                iron_100g=row.get("iron_mg"),
                potassium_100g=row.get("potassium_mg"),
                magnesium_100g=row.get("magnesium_mg"),
                zinc_100g=row.get("zinc_mg"),
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
                .eq("query_hash", f"barcode:{barcode}") \
                .eq("source", "barcode") \
                .gt("expires_at", datetime.utcnow().isoformat()) \
                .limit(1) \
                .execute()

            if result.data and len(result.data) > 0:
                cached_data = result.data[0]["results"]
                # Reconstruct BarcodeProduct from cached dict
                nutrients_data = cached_data.get("nutrients", {})
                nutrients = ProductNutrients(
                    calories_per_100g=nutrients_data.get("calories_per_100g", 0),
                    protein_per_100g=nutrients_data.get("protein_per_100g", 0),
                    carbs_per_100g=nutrients_data.get("carbs_per_100g", 0),
                    fat_per_100g=nutrients_data.get("fat_per_100g", 0),
                    fiber_per_100g=nutrients_data.get("fiber_per_100g", 0),
                    sugar_per_100g=nutrients_data.get("sugar_per_100g", 0),
                    sodium_per_100g=nutrients_data.get("sodium_per_100g", 0),
                    saturated_fat_per_100g=nutrients_data.get("saturated_fat_per_100g", 0),
                    serving_size=nutrients_data.get("serving_size"),
                    serving_size_g=nutrients_data.get("serving_size_g"),
                    calories_per_serving=nutrients_data.get("calories_per_serving"),
                    protein_per_serving=nutrients_data.get("protein_per_serving"),
                    carbs_per_serving=nutrients_data.get("carbs_per_serving"),
                    fat_per_serving=nutrients_data.get("fat_per_serving"),
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
                "query_hash": f"barcode:{barcode}",
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
            from services.usda_food_service import get_usda_food_service

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
                    # Convert USDA food to BarcodeProduct format
                    nutrients = ProductNutrients(
                        calories_per_100g=food.nutrients.calories_per_100g,
                        protein_per_100g=food.nutrients.protein_per_100g,
                        carbs_per_100g=food.nutrients.carbs_per_100g,
                        fat_per_100g=food.nutrients.fat_per_100g,
                        fiber_per_100g=food.nutrients.fiber_per_100g,
                        sugar_per_100g=food.nutrients.sugar_per_100g,
                        sodium_per_100g=food.nutrients.sodium_mg_per_100g,
                        saturated_fat_per_100g=food.nutrients.saturated_fat_per_100g,
                        serving_size=food.nutrients.serving_size,
                        serving_size_g=food.nutrients.serving_size_g,
                        calories_per_serving=None,
                        protein_per_serving=None,
                        carbs_per_serving=None,
                        fat_per_serving=None,
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
