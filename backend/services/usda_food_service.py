"""
USDA FoodData Central API Integration Service.

Provides comprehensive food database search and nutrient data retrieval
from the USDA FoodData Central API.

API Documentation: https://fdc.nal.usda.gov/api-guide.html
"""

import httpx
import time
from typing import Optional, Dict, Any, List
from dataclasses import dataclass, field
from enum import Enum
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)

# USDA API Configuration
USDA_API_BASE_URL = "https://api.nal.usda.gov/fdc/v1"
USDA_USER_AGENT = "FitWiz/1.0 (fitness app)"

# USDA Nutrient IDs for key nutrients
NUTRIENT_IDS = {
    "energy_kcal": 1008,        # Energy (kcal)
    "protein": 1003,            # Protein
    "total_fat": 1004,          # Total lipid (fat)
    "carbohydrates": 1005,      # Carbohydrate, by difference
    "fiber": 1079,              # Fiber, total dietary
    "sugar": 2000,              # Sugars, total including NLEA
    "sodium": 1093,             # Sodium, Na
    "saturated_fat": 1258,      # Fatty acids, total saturated
    "cholesterol": 1253,        # Cholesterol
    "calcium": 1087,            # Calcium, Ca
    "iron": 1089,               # Iron, Fe
    "potassium": 1092,          # Potassium, K
    "vitamin_a": 1106,          # Vitamin A, RAE
    "vitamin_c": 1162,          # Vitamin C, total ascorbic acid
    "vitamin_d": 1114,          # Vitamin D (D2 + D3)
    "vitamin_b12": 1178,        # Vitamin B-12
    "folate": 1177,             # Folate, total
    "magnesium": 1090,          # Magnesium, Mg
    "zinc": 1095,               # Zinc, Zn
    "trans_fat": 1257,          # Fatty acids, total trans
    "monounsaturated_fat": 1292,  # Fatty acids, total monounsaturated
    "polyunsaturated_fat": 1293,  # Fatty acids, total polyunsaturated
}


class FoodDataType(str, Enum):
    """Types of food data available in USDA database."""
    BRANDED = "Branded"
    FOUNDATION = "Foundation"
    SR_LEGACY = "SR Legacy"
    SURVEY_FNDDS = "Survey (FNDDS)"
    EXPERIMENTAL = "Experimental"


@dataclass
class USDANutrients:
    """Comprehensive nutrient data from USDA."""
    # Macronutrients (per 100g)
    calories_per_100g: float = 0.0
    protein_per_100g: float = 0.0
    carbs_per_100g: float = 0.0
    fat_per_100g: float = 0.0
    fiber_per_100g: float = 0.0
    sugar_per_100g: float = 0.0

    # Fats breakdown
    saturated_fat_per_100g: float = 0.0
    trans_fat_per_100g: float = 0.0
    monounsaturated_fat_per_100g: float = 0.0
    polyunsaturated_fat_per_100g: float = 0.0
    cholesterol_mg_per_100g: float = 0.0

    # Minerals
    sodium_mg_per_100g: float = 0.0
    potassium_mg_per_100g: float = 0.0
    calcium_mg_per_100g: float = 0.0
    iron_mg_per_100g: float = 0.0
    magnesium_mg_per_100g: float = 0.0
    zinc_mg_per_100g: float = 0.0

    # Vitamins
    vitamin_a_mcg_per_100g: float = 0.0
    vitamin_c_mg_per_100g: float = 0.0
    vitamin_d_mcg_per_100g: float = 0.0
    vitamin_b12_mcg_per_100g: float = 0.0
    folate_mcg_per_100g: float = 0.0

    # Serving info
    serving_size: Optional[str] = None
    serving_size_g: Optional[float] = None
    household_serving_text: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "calories_per_100g": round(self.calories_per_100g, 1),
            "protein_per_100g": round(self.protein_per_100g, 1),
            "carbs_per_100g": round(self.carbs_per_100g, 1),
            "fat_per_100g": round(self.fat_per_100g, 1),
            "fiber_per_100g": round(self.fiber_per_100g, 1),
            "sugar_per_100g": round(self.sugar_per_100g, 1),
            "saturated_fat_per_100g": round(self.saturated_fat_per_100g, 1),
            "trans_fat_per_100g": round(self.trans_fat_per_100g, 1),
            "monounsaturated_fat_per_100g": round(self.monounsaturated_fat_per_100g, 1),
            "polyunsaturated_fat_per_100g": round(self.polyunsaturated_fat_per_100g, 1),
            "cholesterol_mg_per_100g": round(self.cholesterol_mg_per_100g, 1),
            "sodium_mg_per_100g": round(self.sodium_mg_per_100g, 1),
            "potassium_mg_per_100g": round(self.potassium_mg_per_100g, 1),
            "calcium_mg_per_100g": round(self.calcium_mg_per_100g, 1),
            "iron_mg_per_100g": round(self.iron_mg_per_100g, 1),
            "magnesium_mg_per_100g": round(self.magnesium_mg_per_100g, 1),
            "zinc_mg_per_100g": round(self.zinc_mg_per_100g, 1),
            "vitamin_a_mcg_per_100g": round(self.vitamin_a_mcg_per_100g, 1),
            "vitamin_c_mg_per_100g": round(self.vitamin_c_mg_per_100g, 1),
            "vitamin_d_mcg_per_100g": round(self.vitamin_d_mcg_per_100g, 1),
            "vitamin_b12_mcg_per_100g": round(self.vitamin_b12_mcg_per_100g, 1),
            "folate_mcg_per_100g": round(self.folate_mcg_per_100g, 1),
            "serving_size": self.serving_size,
            "serving_size_g": self.serving_size_g,
            "household_serving_text": self.household_serving_text,
        }

    def get_per_serving(self) -> Optional[Dict[str, float]]:
        """Calculate nutrient values per serving if serving size is available."""
        if not self.serving_size_g or self.serving_size_g <= 0:
            return None

        multiplier = self.serving_size_g / 100.0
        return {
            "calories": round(self.calories_per_100g * multiplier, 1),
            "protein_g": round(self.protein_per_100g * multiplier, 1),
            "carbs_g": round(self.carbs_per_100g * multiplier, 1),
            "fat_g": round(self.fat_per_100g * multiplier, 1),
            "fiber_g": round(self.fiber_per_100g * multiplier, 1),
            "sugar_g": round(self.sugar_per_100g * multiplier, 1),
            "sodium_mg": round(self.sodium_mg_per_100g * multiplier, 1),
        }


@dataclass
class USDAFood:
    """Complete food item from USDA database."""
    fdc_id: int
    description: str
    data_type: str
    brand_owner: Optional[str] = None
    brand_name: Optional[str] = None
    ingredients: Optional[str] = None
    food_category: Optional[str] = None
    gtin_upc: Optional[str] = None  # Barcode
    publication_date: Optional[str] = None
    nutrients: USDANutrients = field(default_factory=USDANutrients)
    score: Optional[float] = None  # Search relevance score

    def to_dict(self) -> Dict[str, Any]:
        return {
            "fdc_id": self.fdc_id,
            "description": self.description,
            "data_type": self.data_type,
            "brand_owner": self.brand_owner,
            "brand_name": self.brand_name,
            "ingredients": self.ingredients,
            "food_category": self.food_category,
            "gtin_upc": self.gtin_upc,
            "publication_date": self.publication_date,
            "nutrients": self.nutrients.to_dict(),
            "nutrients_per_serving": self.nutrients.get_per_serving(),
            "score": self.score,
        }

    def to_food_item_dict(self) -> Dict[str, Any]:
        """Convert to format compatible with existing FoodItem model."""
        serving = self.nutrients.get_per_serving()

        # Use per-serving values if available, otherwise per-100g
        if serving:
            return {
                "name": self.description,
                "amount": self.nutrients.serving_size or "100g",
                "calories": int(serving["calories"]),
                "protein_g": serving["protein_g"],
                "carbs_g": serving["carbs_g"],
                "fat_g": serving["fat_g"],
                "fiber_g": serving.get("fiber_g"),
                "source": "usda",
                "fdc_id": self.fdc_id,
            }
        else:
            return {
                "name": self.description,
                "amount": "100g",
                "calories": int(self.nutrients.calories_per_100g),
                "protein_g": self.nutrients.protein_per_100g,
                "carbs_g": self.nutrients.carbs_per_100g,
                "fat_g": self.nutrients.fat_per_100g,
                "fiber_g": self.nutrients.fiber_per_100g,
                "source": "usda",
                "fdc_id": self.fdc_id,
            }


@dataclass
class USDASearchResult:
    """Search result from USDA API."""
    foods: List[USDAFood]
    total_hits: int
    current_page: int
    total_pages: int


class USDAFoodService:
    """
    Service for interacting with USDA FoodData Central API.

    Features:
    - Food search with fuzzy matching
    - Complete nutrient data retrieval
    - Support for branded, foundation, and SR Legacy foods
    - In-memory caching to reduce API calls
    - Rate limit handling
    """

    def __init__(self):
        self._http_client: Optional[httpx.AsyncClient] = None
        self._cache: Dict[str, tuple] = {}  # {key: (timestamp, data)}
        self._settings = get_settings()

    @property
    def api_key(self) -> Optional[str]:
        return self._settings.usda_api_key

    @property
    def cache_ttl(self) -> int:
        return self._settings.usda_cache_ttl_seconds

    def _is_configured(self) -> bool:
        """Check if USDA API is configured."""
        return bool(self.api_key)

    async def _get_client(self) -> httpx.AsyncClient:
        """Get or create HTTP client."""
        if self._http_client is None or self._http_client.is_closed:
            self._http_client = httpx.AsyncClient(
                timeout=httpx.Timeout(15.0, connect=5.0),
                headers={
                    "User-Agent": USDA_USER_AGENT,
                    "Accept": "application/json",
                }
            )
        return self._http_client

    async def close(self):
        """Close HTTP client."""
        if self._http_client is not None:
            await self._http_client.aclose()
            self._http_client = None

    def _get_cached(self, key: str) -> Optional[Any]:
        """Get cached data if not expired."""
        if key in self._cache:
            timestamp, data = self._cache[key]
            if time.time() - timestamp < self.cache_ttl:
                logger.debug(f"Cache hit for key: {key}")
                return data
            else:
                del self._cache[key]
        return None

    def _set_cached(self, key: str, data: Any):
        """Cache data with timestamp."""
        self._cache[key] = (time.time(), data)

        # Clean old cache entries (keep only last 1000)
        if len(self._cache) > 1000:
            sorted_keys = sorted(self._cache.keys(),
                               key=lambda k: self._cache[k][0])
            for old_key in sorted_keys[:100]:
                del self._cache[old_key]

    def _parse_float(self, value: Any, default: float = 0.0) -> float:
        """Safely parse float value."""
        if value is None:
            return default
        try:
            return float(value)
        except (ValueError, TypeError):
            return default

    def _extract_nutrients(self, food_nutrients: List[Dict]) -> USDANutrients:
        """Extract nutrients from USDA food nutrients array."""
        nutrients = USDANutrients()

        nutrient_map = {}
        for fn in food_nutrients:
            nutrient_id = fn.get("nutrientId") or (fn.get("nutrient", {}).get("id"))
            if nutrient_id:
                nutrient_map[nutrient_id] = self._parse_float(fn.get("value") or fn.get("amount"))

        # Map USDA nutrient IDs to our fields
        nutrients.calories_per_100g = nutrient_map.get(NUTRIENT_IDS["energy_kcal"], 0.0)
        nutrients.protein_per_100g = nutrient_map.get(NUTRIENT_IDS["protein"], 0.0)
        nutrients.carbs_per_100g = nutrient_map.get(NUTRIENT_IDS["carbohydrates"], 0.0)
        nutrients.fat_per_100g = nutrient_map.get(NUTRIENT_IDS["total_fat"], 0.0)
        nutrients.fiber_per_100g = nutrient_map.get(NUTRIENT_IDS["fiber"], 0.0)
        nutrients.sugar_per_100g = nutrient_map.get(NUTRIENT_IDS["sugar"], 0.0)

        nutrients.saturated_fat_per_100g = nutrient_map.get(NUTRIENT_IDS["saturated_fat"], 0.0)
        nutrients.trans_fat_per_100g = nutrient_map.get(NUTRIENT_IDS["trans_fat"], 0.0)
        nutrients.monounsaturated_fat_per_100g = nutrient_map.get(NUTRIENT_IDS["monounsaturated_fat"], 0.0)
        nutrients.polyunsaturated_fat_per_100g = nutrient_map.get(NUTRIENT_IDS["polyunsaturated_fat"], 0.0)
        nutrients.cholesterol_mg_per_100g = nutrient_map.get(NUTRIENT_IDS["cholesterol"], 0.0)

        nutrients.sodium_mg_per_100g = nutrient_map.get(NUTRIENT_IDS["sodium"], 0.0)
        nutrients.potassium_mg_per_100g = nutrient_map.get(NUTRIENT_IDS["potassium"], 0.0)
        nutrients.calcium_mg_per_100g = nutrient_map.get(NUTRIENT_IDS["calcium"], 0.0)
        nutrients.iron_mg_per_100g = nutrient_map.get(NUTRIENT_IDS["iron"], 0.0)
        nutrients.magnesium_mg_per_100g = nutrient_map.get(NUTRIENT_IDS["magnesium"], 0.0)
        nutrients.zinc_mg_per_100g = nutrient_map.get(NUTRIENT_IDS["zinc"], 0.0)

        nutrients.vitamin_a_mcg_per_100g = nutrient_map.get(NUTRIENT_IDS["vitamin_a"], 0.0)
        nutrients.vitamin_c_mg_per_100g = nutrient_map.get(NUTRIENT_IDS["vitamin_c"], 0.0)
        nutrients.vitamin_d_mcg_per_100g = nutrient_map.get(NUTRIENT_IDS["vitamin_d"], 0.0)
        nutrients.vitamin_b12_mcg_per_100g = nutrient_map.get(NUTRIENT_IDS["vitamin_b12"], 0.0)
        nutrients.folate_mcg_per_100g = nutrient_map.get(NUTRIENT_IDS["folate"], 0.0)

        return nutrients

    def _parse_food(self, food_data: Dict, include_score: bool = False) -> USDAFood:
        """Parse USDA food data into USDAFood object."""
        # Extract nutrients
        food_nutrients = food_data.get("foodNutrients", [])
        nutrients = self._extract_nutrients(food_nutrients)

        # Extract serving size info
        serving_size = food_data.get("servingSize")
        serving_unit = food_data.get("servingSizeUnit", "g")
        if serving_size:
            nutrients.serving_size = f"{serving_size}{serving_unit}"
            if serving_unit.lower() == "g":
                nutrients.serving_size_g = self._parse_float(serving_size)

        household_serving = food_data.get("householdServingFullText")
        if household_serving:
            nutrients.household_serving_text = household_serving

        # Build food object
        food = USDAFood(
            fdc_id=food_data.get("fdcId"),
            description=food_data.get("description", "Unknown Food"),
            data_type=food_data.get("dataType", "Unknown"),
            brand_owner=food_data.get("brandOwner"),
            brand_name=food_data.get("brandName"),
            ingredients=food_data.get("ingredients"),
            food_category=food_data.get("foodCategory") or food_data.get("brandedFoodCategory"),
            gtin_upc=food_data.get("gtinUpc"),
            publication_date=food_data.get("publicationDate"),
            nutrients=nutrients,
        )

        if include_score and "score" in food_data:
            food.score = food_data["score"]

        return food

    async def search_foods(
        self,
        query: str,
        page_size: int = 25,
        page_number: int = 1,
        data_types: Optional[List[str]] = None,
        brand_owner: Optional[str] = None,
        require_all_words: bool = False,
    ) -> USDASearchResult:
        """
        Search USDA FoodData Central for foods matching query.

        Args:
            query: Search query (food name)
            page_size: Number of results per page (max 50)
            page_number: Page number (1-based)
            data_types: Filter by data types (e.g., ["Branded", "Foundation"])
            brand_owner: Filter by brand owner
            require_all_words: If True, all words must match

        Returns:
            USDASearchResult with matching foods

        Raises:
            Exception if API not configured or request fails
        """
        if not self._is_configured():
            logger.error("USDA API key not configured")
            raise Exception("USDA API is not configured. Please set USDA_API_KEY.")

        query = query.strip()
        if not query:
            logger.warning("Empty search query provided")
            return USDASearchResult(foods=[], total_hits=0, current_page=1, total_pages=0)

        # Check cache
        cache_key = f"search:{query}:{page_size}:{page_number}:{data_types}:{brand_owner}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        logger.info(f"Searching USDA foods for: {query} (page {page_number}, size {page_size})")

        # Build request body
        request_body = {
            "query": query,
            "pageSize": min(page_size, 50),
            "pageNumber": page_number,
            "sortBy": "dataType.keyword",
            "sortOrder": "asc",
            "requireAllWords": require_all_words,
        }

        if data_types:
            request_body["dataType"] = data_types

        if brand_owner:
            request_body["brandOwner"] = brand_owner

        try:
            client = await self._get_client()
            url = f"{USDA_API_BASE_URL}/foods/search"

            response = await client.post(
                url,
                params={"api_key": self.api_key},
                json=request_body
            )

            if response.status_code == 429:
                logger.warning("USDA API rate limit reached")
                raise Exception("Rate limit exceeded. Please try again later.")

            response.raise_for_status()
            data = response.json()

            # Parse foods
            foods = []
            for food_data in data.get("foods", []):
                try:
                    food = self._parse_food(food_data, include_score=True)
                    foods.append(food)
                except Exception as e:
                    logger.warning(f"Failed to parse food: {e}")
                    continue

            total_hits = data.get("totalHits", 0)
            total_pages = data.get("totalPages", 0)

            result = USDASearchResult(
                foods=foods,
                total_hits=total_hits,
                current_page=page_number,
                total_pages=total_pages,
            )

            # Cache result
            self._set_cached(cache_key, result)

            logger.info(f"Found {len(foods)} foods out of {total_hits} total matches")
            return result

        except httpx.TimeoutException:
            logger.error(f"Timeout searching USDA for: {query}")
            raise Exception("Request timed out. Please try again.")
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error searching USDA: {e}")
            raise Exception(f"API error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"Error searching USDA: {e}")
            raise

    async def get_food(self, fdc_id: int) -> Optional[USDAFood]:
        """
        Get complete food details by FDC ID.

        Args:
            fdc_id: USDA FoodData Central ID

        Returns:
            USDAFood with complete nutrient data, or None if not found
        """
        if not self._is_configured():
            logger.error("USDA API key not configured")
            raise Exception("USDA API is not configured. Please set USDA_API_KEY.")

        # Check cache
        cache_key = f"food:{fdc_id}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        logger.info(f"Fetching USDA food by FDC ID: {fdc_id}")

        try:
            client = await self._get_client()
            url = f"{USDA_API_BASE_URL}/food/{fdc_id}"

            response = await client.get(
                url,
                params={"api_key": self.api_key}
            )

            if response.status_code == 404:
                logger.info(f"Food not found for FDC ID: {fdc_id}")
                return None

            if response.status_code == 429:
                logger.warning("USDA API rate limit reached")
                raise Exception("Rate limit exceeded. Please try again later.")

            response.raise_for_status()
            data = response.json()

            food = self._parse_food(data)

            # Cache result
            self._set_cached(cache_key, food)

            logger.info(f"Successfully fetched food: {food.description}")
            return food

        except httpx.TimeoutException:
            logger.error(f"Timeout fetching USDA food: {fdc_id}")
            raise Exception("Request timed out. Please try again.")
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error fetching USDA food: {e}")
            if e.response.status_code == 404:
                return None
            raise Exception(f"API error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"Error fetching USDA food: {e}")
            raise

    async def get_foods_batch(self, fdc_ids: List[int]) -> List[USDAFood]:
        """
        Get multiple foods by FDC IDs in a single request.

        Args:
            fdc_ids: List of USDA FoodData Central IDs (max 20)

        Returns:
            List of USDAFood objects
        """
        if not self._is_configured():
            logger.error("USDA API key not configured")
            raise Exception("USDA API is not configured. Please set USDA_API_KEY.")

        if not fdc_ids:
            return []

        # Limit to 20 IDs per request
        fdc_ids = fdc_ids[:20]

        logger.info(f"Fetching {len(fdc_ids)} USDA foods in batch")

        try:
            client = await self._get_client()
            url = f"{USDA_API_BASE_URL}/foods"

            response = await client.post(
                url,
                params={"api_key": self.api_key},
                json={"fdcIds": fdc_ids}
            )

            if response.status_code == 429:
                logger.warning("USDA API rate limit reached")
                raise Exception("Rate limit exceeded. Please try again later.")

            response.raise_for_status()
            data = response.json()

            foods = []
            for food_data in data:
                try:
                    food = self._parse_food(food_data)
                    foods.append(food)
                    # Cache individual foods
                    self._set_cached(f"food:{food.fdc_id}", food)
                except Exception as e:
                    logger.warning(f"Failed to parse food in batch: {e}")
                    continue

            logger.info(f"Successfully fetched {len(foods)} foods in batch")
            return foods

        except httpx.TimeoutException:
            logger.error("Timeout fetching USDA foods batch")
            raise Exception("Request timed out. Please try again.")
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error fetching USDA foods batch: {e}")
            raise Exception(f"API error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"Error fetching USDA foods batch: {e}")
            raise

    async def search_branded_foods(
        self,
        query: str,
        page_size: int = 25,
    ) -> USDASearchResult:
        """Search only branded foods (processed/packaged foods)."""
        return await self.search_foods(
            query=query,
            page_size=page_size,
            data_types=["Branded"],
        )

    async def search_foundation_foods(
        self,
        query: str,
        page_size: int = 25,
    ) -> USDASearchResult:
        """Search foundation foods (basic/whole foods with detailed nutrients)."""
        return await self.search_foods(
            query=query,
            page_size=page_size,
            data_types=["Foundation"],
        )

    async def search_sr_legacy_foods(
        self,
        query: str,
        page_size: int = 25,
    ) -> USDASearchResult:
        """Search SR Legacy foods (USDA Standard Reference)."""
        return await self.search_foods(
            query=query,
            page_size=page_size,
            data_types=["SR Legacy"],
        )

    async def search_all_types(
        self,
        query: str,
        page_size: int = 25,
    ) -> USDASearchResult:
        """Search all food types with preference for Foundation and SR Legacy."""
        return await self.search_foods(
            query=query,
            page_size=page_size,
            data_types=["Foundation", "SR Legacy", "Branded"],
        )


# Singleton instance
_usda_service: Optional[USDAFoodService] = None


def get_usda_food_service() -> USDAFoodService:
    """Get singleton USDA food service instance."""
    global _usda_service
    if _usda_service is None:
        _usda_service = USDAFoodService()
    return _usda_service
