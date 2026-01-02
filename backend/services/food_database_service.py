"""
Food Database Service - Open Food Facts API Integration.
"""

import httpx
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
                timeout=httpx.Timeout(10.0, connect=5.0),
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

    async def lookup_barcode(self, barcode: str) -> Optional[BarcodeProduct]:
        barcode = barcode.strip().replace(" ", "").replace("-", "")
        if not barcode:
            logger.warning("Empty barcode provided")
            return None

        logger.info(f"Looking up barcode: {barcode}")

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
                logger.info(f"Product not found for barcode: {barcode}")
                return None

            response.raise_for_status()
            data = response.json()

            if data.get("status") != 1:
                logger.info(f"Product not found in database for barcode: {barcode}")
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

            logger.info(f"Successfully found product: {product_name} (barcode: {barcode})")
            return result

        except httpx.TimeoutException:
            logger.error(f"Timeout looking up barcode: {barcode}")
            raise Exception("Request timed out. Please try again.")
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error looking up barcode {barcode}: {e}")
            raise Exception(f"API error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"Error looking up barcode {barcode}: {e}")
            raise


_food_database_service: Optional[FoodDatabaseService] = None


def get_food_database_service() -> FoodDatabaseService:
    global _food_database_service
    if _food_database_service is None:
        _food_database_service = FoodDatabaseService()
    return _food_database_service
