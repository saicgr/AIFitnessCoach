"""
Tests for USDA FoodData Central API integration.

These tests verify the USDA food service functionality including:
- Food search
- Food lookup by FDC ID
- Nutrient parsing
- Cache behavior
- Error handling
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
import httpx

from services.usda_food_service import (
    USDAFoodService,
    USDAFood,
    USDANutrients,
    USDASearchResult,
    get_usda_food_service,
    NUTRIENT_IDS,
)


# Sample USDA API responses for testing
SAMPLE_SEARCH_RESPONSE = {
    "totalHits": 100,
    "currentPage": 1,
    "totalPages": 4,
    "foods": [
        {
            "fdcId": 2341578,
            "description": "Chicken breast, raw",
            "dataType": "Foundation",
            "foodNutrients": [
                {"nutrientId": 1008, "value": 120},  # Calories
                {"nutrientId": 1003, "value": 22.5},  # Protein
                {"nutrientId": 1004, "value": 2.6},   # Fat
                {"nutrientId": 1005, "value": 0},     # Carbs
                {"nutrientId": 1079, "value": 0},     # Fiber
            ],
            "score": 95.5,
        },
        {
            "fdcId": 1098765,
            "description": "CHICKEN BREAST, GRILLED",
            "dataType": "Branded",
            "brandOwner": "TYSON",
            "brandName": "TYSON",
            "foodNutrients": [
                {"nutrientId": 1008, "value": 130},
                {"nutrientId": 1003, "value": 25},
                {"nutrientId": 1004, "value": 3},
                {"nutrientId": 1005, "value": 1},
            ],
            "servingSize": 112,
            "servingSizeUnit": "g",
            "score": 88.2,
        },
    ],
}

SAMPLE_FOOD_RESPONSE = {
    "fdcId": 2341578,
    "description": "Chicken breast, raw",
    "dataType": "Foundation",
    "foodCategory": "Poultry Products",
    "publicationDate": "2023-04-20",
    "foodNutrients": [
        {"nutrient": {"id": 1008}, "amount": 120},  # Calories
        {"nutrient": {"id": 1003}, "amount": 22.5},  # Protein
        {"nutrient": {"id": 1004}, "amount": 2.6},   # Fat
        {"nutrient": {"id": 1005}, "amount": 0},     # Carbs
        {"nutrient": {"id": 1079}, "amount": 0},     # Fiber
        {"nutrient": {"id": 2000}, "amount": 0},     # Sugar
        {"nutrient": {"id": 1093}, "amount": 65},    # Sodium
        {"nutrient": {"id": 1258}, "amount": 0.6},   # Saturated fat
        {"nutrient": {"id": 1092}, "amount": 334},   # Potassium
        {"nutrient": {"id": 1087}, "amount": 10},    # Calcium
        {"nutrient": {"id": 1089}, "amount": 0.7},   # Iron
    ],
    "servingSize": 100,
    "servingSizeUnit": "g",
}


class TestUSDANutrients:
    """Tests for USDANutrients dataclass."""

    def test_nutrients_default_values(self):
        """Test that nutrients default to 0."""
        nutrients = USDANutrients()
        assert nutrients.calories_per_100g == 0.0
        assert nutrients.protein_per_100g == 0.0
        assert nutrients.carbs_per_100g == 0.0
        assert nutrients.fat_per_100g == 0.0

    def test_nutrients_to_dict(self):
        """Test nutrients conversion to dictionary."""
        nutrients = USDANutrients(
            calories_per_100g=120,
            protein_per_100g=22.5,
            carbs_per_100g=0,
            fat_per_100g=2.6,
        )
        result = nutrients.to_dict()
        assert result["calories_per_100g"] == 120.0
        assert result["protein_per_100g"] == 22.5
        assert result["carbs_per_100g"] == 0.0
        assert result["fat_per_100g"] == 2.6

    def test_get_per_serving_with_serving_size(self):
        """Test per-serving calculation with valid serving size."""
        nutrients = USDANutrients(
            calories_per_100g=100,
            protein_per_100g=20,
            carbs_per_100g=5,
            fat_per_100g=3,
            serving_size_g=50,
        )
        per_serving = nutrients.get_per_serving()
        assert per_serving is not None
        assert per_serving["calories"] == 50.0
        assert per_serving["protein_g"] == 10.0

    def test_get_per_serving_without_serving_size(self):
        """Test that None is returned when no serving size."""
        nutrients = USDANutrients(calories_per_100g=100)
        assert nutrients.get_per_serving() is None


class TestUSDAFood:
    """Tests for USDAFood dataclass."""

    def test_food_to_dict(self):
        """Test food conversion to dictionary."""
        nutrients = USDANutrients(
            calories_per_100g=120,
            protein_per_100g=22.5,
        )
        food = USDAFood(
            fdc_id=2341578,
            description="Chicken breast, raw",
            data_type="Foundation",
            nutrients=nutrients,
        )
        result = food.to_dict()
        assert result["fdc_id"] == 2341578
        assert result["description"] == "Chicken breast, raw"
        assert result["data_type"] == "Foundation"
        assert result["nutrients"]["calories_per_100g"] == 120.0

    def test_to_food_item_dict(self):
        """Test conversion to FoodItem-compatible format."""
        nutrients = USDANutrients(
            calories_per_100g=120,
            protein_per_100g=22.5,
            carbs_per_100g=0,
            fat_per_100g=2.6,
        )
        food = USDAFood(
            fdc_id=2341578,
            description="Chicken breast",
            data_type="Foundation",
            nutrients=nutrients,
        )
        result = food.to_food_item_dict()
        assert result["name"] == "Chicken breast"
        assert result["calories"] == 120
        assert result["protein_g"] == 22.5
        assert result["source"] == "usda"
        assert result["fdc_id"] == 2341578


class TestUSDAFoodService:
    """Tests for USDAFoodService."""

    @pytest.fixture
    def service(self):
        """Create a test service instance."""
        with patch("services.usda_food_service.get_settings") as mock_settings:
            mock_settings.return_value.usda_api_key = "test_api_key"
            mock_settings.return_value.usda_cache_ttl_seconds = 3600
            service = USDAFoodService()
            yield service

    def test_is_configured_with_key(self, service):
        """Test that service is configured when API key is set."""
        assert service._is_configured() is True

    def test_parse_float_valid(self, service):
        """Test parsing valid float values."""
        assert service._parse_float(10.5) == 10.5
        assert service._parse_float("20.3") == 20.3
        assert service._parse_float(0) == 0.0

    def test_parse_float_invalid(self, service):
        """Test parsing invalid values returns default."""
        assert service._parse_float(None) == 0.0
        assert service._parse_float("invalid") == 0.0
        assert service._parse_float(None, default=5.0) == 5.0

    def test_extract_nutrients(self, service):
        """Test nutrient extraction from USDA format."""
        food_nutrients = [
            {"nutrientId": 1008, "value": 120},  # Calories
            {"nutrientId": 1003, "value": 22.5},  # Protein
            {"nutrientId": 1004, "value": 2.6},   # Fat
            {"nutrientId": 1005, "value": 1},     # Carbs
            {"nutrientId": 1093, "value": 65},    # Sodium
        ]
        nutrients = service._extract_nutrients(food_nutrients)
        assert nutrients.calories_per_100g == 120
        assert nutrients.protein_per_100g == 22.5
        assert nutrients.fat_per_100g == 2.6
        assert nutrients.carbs_per_100g == 1
        assert nutrients.sodium_mg_per_100g == 65

    def test_parse_food(self, service):
        """Test parsing USDA food data."""
        food = service._parse_food(SAMPLE_FOOD_RESPONSE)
        assert food.fdc_id == 2341578
        assert food.description == "Chicken breast, raw"
        assert food.data_type == "Foundation"
        assert food.nutrients.calories_per_100g == 120
        assert food.nutrients.protein_per_100g == 22.5

    def test_caching(self, service):
        """Test cache set and get."""
        service._set_cached("test_key", {"data": "test"})
        cached = service._get_cached("test_key")
        assert cached == {"data": "test"}

    def test_cache_expiry(self, service):
        """Test that expired cache returns None."""
        import time
        service._cache["old_key"] = (time.time() - 7200, {"data": "old"})
        assert service._get_cached("old_key") is None

    @pytest.mark.asyncio
    async def test_search_foods_not_configured(self):
        """Test that search raises error when not configured."""
        with patch("services.usda_food_service.get_settings") as mock_settings:
            mock_settings.return_value.usda_api_key = None
            mock_settings.return_value.usda_cache_ttl_seconds = 3600
            service = USDAFoodService()
            with pytest.raises(Exception, match="not configured"):
                await service.search_foods("chicken")

    @pytest.mark.asyncio
    async def test_search_foods_success(self, service):
        """Test successful food search."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = SAMPLE_SEARCH_RESPONSE

        with patch.object(service, "_get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post.return_value = mock_response
            mock_get_client.return_value = mock_client

            result = await service.search_foods("chicken")

            assert result.total_hits == 100
            assert len(result.foods) == 2
            assert result.foods[0].fdc_id == 2341578
            assert result.foods[0].description == "Chicken breast, raw"

    @pytest.mark.asyncio
    async def test_get_food_success(self, service):
        """Test successful food lookup by ID."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = SAMPLE_FOOD_RESPONSE

        with patch.object(service, "_get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get.return_value = mock_response
            mock_get_client.return_value = mock_client

            food = await service.get_food(2341578)

            assert food is not None
            assert food.fdc_id == 2341578
            assert food.description == "Chicken breast, raw"

    @pytest.mark.asyncio
    async def test_get_food_not_found(self, service):
        """Test food lookup returns None for 404."""
        mock_response = MagicMock()
        mock_response.status_code = 404

        with patch.object(service, "_get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get.return_value = mock_response
            mock_get_client.return_value = mock_client

            food = await service.get_food(99999999)
            assert food is None

    @pytest.mark.asyncio
    async def test_rate_limit_handling(self, service):
        """Test that rate limit errors are handled."""
        mock_response = MagicMock()
        mock_response.status_code = 429

        with patch.object(service, "_get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post.return_value = mock_response
            mock_get_client.return_value = mock_client

            with pytest.raises(Exception, match="Rate limit"):
                await service.search_foods("chicken")


class TestSingletonInstance:
    """Test singleton service instance."""

    def test_get_usda_food_service(self):
        """Test that singleton returns same instance."""
        with patch("services.usda_food_service.get_settings") as mock_settings:
            mock_settings.return_value.usda_api_key = "test_key"
            mock_settings.return_value.usda_cache_ttl_seconds = 3600

            # Reset singleton
            import services.usda_food_service as module
            module._usda_service = None

            service1 = get_usda_food_service()
            service2 = get_usda_food_service()
            assert service1 is service2


class TestNutrientIDMapping:
    """Test nutrient ID constants."""

    def test_nutrient_ids_defined(self):
        """Test that all essential nutrient IDs are defined."""
        assert NUTRIENT_IDS["energy_kcal"] == 1008
        assert NUTRIENT_IDS["protein"] == 1003
        assert NUTRIENT_IDS["total_fat"] == 1004
        assert NUTRIENT_IDS["carbohydrates"] == 1005
        assert NUTRIENT_IDS["fiber"] == 1079
        assert NUTRIENT_IDS["sodium"] == 1093
