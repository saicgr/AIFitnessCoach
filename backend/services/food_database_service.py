"""
Food Database Service - Open Food Facts API Integration with caching and USDA fallback.
"""

import httpx
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from dataclasses import dataclass
from core.logger import get_logger

logger = get_logger(__name__)

OFF_API_BASE_URL = "https://world.openfoodfacts.org/api/v2"
OFF_USER_AGENT = "AIFitnessCoach/1.0 (contact@fitwiz.com)"


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

    def to_dict(self) -> Dict[str, Any]:
        return {
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

    def to_dict(self) -> Dict[str, Any]:
        return {
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

    async def lookup_barcode(self, barcode: str) -> Optional[BarcodeProduct]:
        """
        Look up a barcode with caching and USDA fallback.

        Flow:
        1. Check cache first (instant if cached)
        2. Try Open Food Facts API
        3. If not found, try USDA as fallback
        4. Cache the result for future lookups
        """
        barcode = barcode.strip().replace(" ", "").replace("-", "")
        if not barcode:
            logger.warning("Empty barcode provided")
            return None

        # Validate barcode format
        if not self._is_valid_barcode(barcode):
            logger.warning(f"Invalid barcode format: {barcode[:50]}...")
            return None

        # 1. Check cache first
        cached = self._get_cached_barcode(barcode)
        if cached:
            logger.info(f"Cache hit for barcode: {barcode}")
            return cached

        logger.info(f"Looking up barcode: {barcode}")

        # 2. Try Open Food Facts
        result = await self._lookup_open_food_facts(barcode)

        # 3. If not found, try USDA fallback
        if not result:
            result = await self._lookup_usda_barcode(barcode)

        # 4. Cache the result (30-day TTL)
        if result:
            self._cache_barcode_result(barcode, result)

        return result

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
            logger.warning(f"Cache lookup failed: {e}")
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
            logger.warning(f"Failed to cache barcode: {e}")

    async def _lookup_open_food_facts(self, barcode: str) -> Optional[BarcodeProduct]:
        """Look up barcode in Open Food Facts database."""
        try:
            client = await self._get_client()
            url = f"{OFF_API_BASE_URL}/product/{barcode}"
            params = {
                "fields": "code,product_name,brands,categories,image_url,image_small_url,"
                         "nutriments,serving_size,serving_quantity,nutriscore_grade,"
                         "nova_group,ingredients_text,allergens"
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
            )

            logger.info(f"Found product in OFF: {product_name} (barcode: {barcode})")
            return result

        except httpx.TimeoutException:
            logger.error(f"Timeout looking up barcode in OFF: {barcode}")
            raise Exception("Request timed out. Please try again.")
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error looking up barcode {barcode}: {e}")
            raise Exception(f"API error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"Error looking up barcode {barcode}: {e}")
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
            logger.warning(f"USDA fallback failed: {e}")
            return None


_food_database_service: Optional[FoodDatabaseService] = None


def get_food_database_service() -> FoodDatabaseService:
    global _food_database_service
    if _food_database_service is None:
        _food_database_service = FoodDatabaseService()
    return _food_database_service
