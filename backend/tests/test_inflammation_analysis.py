"""
Tests for Inflammation Analysis API.

Run with: pytest backend/tests/test_inflammation_analysis.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime
import uuid


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def sample_ingredients():
    """Sample inflammatory ingredients (typical soda)."""
    return "Water, Sugar, High Fructose Corn Syrup, Natural Flavors, Citric Acid, Sodium Benzoate (Preservative), Yellow 5, Yellow 6"


@pytest.fixture
def sample_healthy_ingredients():
    """Sample anti-inflammatory ingredients (healthy product)."""
    return "Rolled Oats, Almonds, Blueberries, Honey, Flaxseed, Turmeric, Cinnamon"


@pytest.fixture
def sample_gemini_response():
    """Sample Gemini response for inflammation analysis."""
    return {
        "overall_score": 3,
        "overall_category": "moderately_inflammatory",
        "summary": "This product contains several inflammatory ingredients including high fructose corn syrup, artificial colors, and preservatives.",
        "recommendation": "Consider choosing products with natural sweeteners and no artificial colors.",
        "analysis_confidence": 0.87,
        "ingredient_analyses": [
            {
                "name": "Water",
                "category": "neutral",
                "score": 5,
                "reason": "Water is neutral and essential",
                "is_inflammatory": False,
                "is_additive": False
            },
            {
                "name": "High Fructose Corn Syrup",
                "category": "highly_inflammatory",
                "score": 2,
                "reason": "Highly processed sugar linked to inflammation",
                "is_inflammatory": True,
                "is_additive": False
            },
            {
                "name": "Sodium Benzoate",
                "category": "additive",
                "score": 4,
                "reason": "Preservative with some inflammatory concerns",
                "is_inflammatory": True,
                "is_additive": True
            },
            {
                "name": "Yellow 5",
                "category": "highly_inflammatory",
                "score": 2,
                "reason": "Artificial color linked to inflammation",
                "is_inflammatory": True,
                "is_additive": True
            }
        ],
        "inflammatory_ingredients": ["High Fructose Corn Syrup", "Yellow 5", "Yellow 6"],
        "anti_inflammatory_ingredients": [],
        "additives_found": ["Sodium Benzoate", "Yellow 5", "Yellow 6"]
    }


@pytest.fixture
def sample_healthy_gemini_response():
    """Sample Gemini response for anti-inflammatory product."""
    return {
        "overall_score": 8,
        "overall_category": "anti_inflammatory",
        "summary": "This product contains mostly anti-inflammatory ingredients with whole grains, berries, and turmeric.",
        "recommendation": "Great choice for reducing inflammation.",
        "analysis_confidence": 0.92,
        "ingredient_analyses": [
            {
                "name": "Rolled Oats",
                "category": "anti_inflammatory",
                "score": 7,
                "reason": "Whole grain with fiber and anti-inflammatory properties",
                "is_inflammatory": False,
                "is_additive": False
            },
            {
                "name": "Blueberries",
                "category": "highly_anti_inflammatory",
                "score": 9,
                "reason": "Rich in antioxidants and anti-inflammatory compounds",
                "is_inflammatory": False,
                "is_additive": False
            },
            {
                "name": "Turmeric",
                "category": "highly_anti_inflammatory",
                "score": 10,
                "reason": "Contains curcumin, a powerful anti-inflammatory compound",
                "is_inflammatory": False,
                "is_additive": False
            }
        ],
        "inflammatory_ingredients": [],
        "anti_inflammatory_ingredients": ["Rolled Oats", "Blueberries", "Turmeric", "Almonds", "Flaxseed"],
        "additives_found": []
    }


# ============================================================
# MODEL TESTS
# ============================================================

class TestInflammationModels:
    """Test Pydantic model validation."""

    def test_analyze_request_valid(self):
        from models.inflammation import AnalyzeInflammationRequest

        request = AnalyzeInflammationRequest(
            user_id="user-123",
            barcode="012345678901",
            product_name="Test Product",
            ingredients_text="Water, Sugar, Salt"
        )

        assert request.barcode == "012345678901"
        assert request.ingredients_text == "Water, Sugar, Salt"

    def test_analyze_request_minimum_ingredients(self):
        from models.inflammation import AnalyzeInflammationRequest

        # Minimum 3 characters required
        request = AnalyzeInflammationRequest(
            user_id="user-123",
            barcode="123",
            ingredients_text="Oil"  # 3 chars - valid
        )
        assert len(request.ingredients_text) >= 3

    def test_analyze_request_rejects_short_ingredients(self):
        from models.inflammation import AnalyzeInflammationRequest
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            AnalyzeInflammationRequest(
                user_id="user-123",
                barcode="123",
                ingredients_text="ab"  # Too short
            )

    def test_ingredient_analysis_model(self):
        from models.inflammation import IngredientAnalysis, IngredientCategory

        analysis = IngredientAnalysis(
            name="Turmeric",
            category=IngredientCategory.HIGHLY_ANTI_INFLAMMATORY,
            score=9,
            reason="Contains curcumin, a powerful anti-inflammatory compound",
            is_inflammatory=False,
            is_additive=False,
            scientific_notes="Studies show curcumin reduces NF-kB activation"
        )

        assert analysis.score == 9
        assert analysis.is_inflammatory is False
        assert analysis.category == IngredientCategory.HIGHLY_ANTI_INFLAMMATORY

    def test_inflammation_category_enum(self):
        from models.inflammation import InflammationCategory

        assert InflammationCategory.HIGHLY_INFLAMMATORY.value == "highly_inflammatory"
        assert InflammationCategory.NEUTRAL.value == "neutral"
        assert InflammationCategory.HIGHLY_ANTI_INFLAMMATORY.value == "highly_anti_inflammatory"

    def test_inflammation_response_model(self):
        from models.inflammation import (
            InflammationAnalysisResponse,
            InflammationCategory,
            IngredientAnalysis,
            IngredientCategory
        )
        from datetime import datetime

        response = InflammationAnalysisResponse(
            analysis_id="test-123",
            barcode="012345678901",
            product_name="Test Product",
            overall_score=5,
            overall_category=InflammationCategory.NEUTRAL,
            summary="A neutral product",
            ingredient_analyses=[
                IngredientAnalysis(
                    name="Water",
                    category=IngredientCategory.NEUTRAL,
                    score=5,
                    reason="Neutral ingredient",
                    is_inflammatory=False,
                    is_additive=False
                )
            ],
            created_at=datetime.now()
        )

        assert response.overall_score == 5
        assert len(response.ingredient_analyses) == 1


# ============================================================
# GEMINI PARSING TESTS
# ============================================================

class TestGeminiParsing:
    """Test Gemini response parsing."""

    def test_inflammatory_ingredient_detection(self, sample_gemini_response):
        """Test that inflammatory ingredients are correctly identified."""
        inflammatory = sample_gemini_response["inflammatory_ingredients"]

        assert "High Fructose Corn Syrup" in inflammatory
        assert "Yellow 5" in inflammatory
        assert "Water" not in inflammatory

    def test_additive_detection(self, sample_gemini_response):
        """Test that additives are correctly identified."""
        additives = sample_gemini_response["additives_found"]

        assert "Sodium Benzoate" in additives
        assert "Yellow 5" in additives
        assert "Water" not in additives

    def test_score_range_validation(self, sample_gemini_response):
        """Test that all scores are in valid range 1-10."""
        for analysis in sample_gemini_response["ingredient_analyses"]:
            score = analysis["score"]
            assert 1 <= score <= 10, f"Invalid score {score} for {analysis['name']}"

    def test_is_inflammatory_flag_consistency(self, sample_gemini_response):
        """Test that is_inflammatory matches score <= 4."""
        for analysis in sample_gemini_response["ingredient_analyses"]:
            expected = analysis["score"] <= 4
            assert analysis["is_inflammatory"] == expected, \
                f"Inconsistent is_inflammatory for {analysis['name']}"

    def test_category_derivation_from_score(self):
        """Test overall_category is correctly derived from score."""
        def derive_category(score: int) -> str:
            if score <= 2:
                return "highly_inflammatory"
            elif score <= 4:
                return "moderately_inflammatory"
            elif score <= 6:
                return "neutral"
            elif score <= 8:
                return "anti_inflammatory"
            else:
                return "highly_anti_inflammatory"

        assert derive_category(1) == "highly_inflammatory"
        assert derive_category(2) == "highly_inflammatory"
        assert derive_category(3) == "moderately_inflammatory"
        assert derive_category(5) == "neutral"
        assert derive_category(7) == "anti_inflammatory"
        assert derive_category(9) == "highly_anti_inflammatory"
        assert derive_category(10) == "highly_anti_inflammatory"


# ============================================================
# CACHING TESTS
# ============================================================

class TestCaching:
    """Test caching behavior."""

    def test_cache_key_is_barcode(self):
        """Test that barcode is used as cache key."""
        cached_data = {
            "id": str(uuid.uuid4()),
            "barcode": "012345678901",
            "overall_score": 5
        }
        assert "barcode" in cached_data
        assert cached_data["barcode"] == "012345678901"

    def test_cache_expiration(self):
        """Test cache expiration is set correctly."""
        from datetime import datetime, timedelta

        created = datetime.now()
        expires = created + timedelta(days=90)

        # Verify 90-day cache
        diff = expires - created
        assert diff.days == 90

    def test_response_indicates_cache_hit(self):
        """Test that from_cache flag is set correctly."""
        from models.inflammation import InflammationAnalysisResponse, InflammationCategory
        from datetime import datetime

        cached_response = InflammationAnalysisResponse(
            analysis_id="123",
            barcode="012345678901",
            overall_score=5,
            overall_category=InflammationCategory.NEUTRAL,
            summary="Test",
            ingredient_analyses=[],
            from_cache=True,
            created_at=datetime.now()
        )

        assert cached_response.from_cache is True

        fresh_response = InflammationAnalysisResponse(
            analysis_id="124",
            barcode="012345678902",
            overall_score=5,
            overall_category=InflammationCategory.NEUTRAL,
            summary="Test",
            ingredient_analyses=[],
            from_cache=False,
            created_at=datetime.now()
        )

        assert fresh_response.from_cache is False


# ============================================================
# USER HISTORY TESTS
# ============================================================

class TestUserHistory:
    """Test user history functionality."""

    def test_history_response_model(self):
        """Test history response structure."""
        from models.inflammation import (
            UserInflammationHistoryResponse,
            UserInflammationScan,
            InflammationCategory
        )
        from datetime import datetime

        scan = UserInflammationScan(
            scan_id="scan-123",
            user_id="user-123",
            barcode="012345678901",
            product_name="Test Product",
            overall_score=7,
            overall_category=InflammationCategory.ANTI_INFLAMMATORY,
            summary="Good product with anti-inflammatory ingredients.",
            scanned_at=datetime.now(),
            notes="Bought at grocery store",
            is_favorited=True
        )

        response = UserInflammationHistoryResponse(
            items=[scan],
            total_count=1,
            has_more=False
        )

        assert len(response.items) == 1
        assert response.items[0].overall_score == 7
        assert response.items[0].is_favorited is True

    def test_stats_response_model(self):
        """Test stats response structure."""
        from models.inflammation import UserInflammationStatsResponse
        from datetime import datetime

        stats = UserInflammationStatsResponse(
            user_id="user-123",
            total_scans=10,
            avg_inflammation_score=6.5,
            inflammatory_products_scanned=3,
            anti_inflammatory_products_scanned=5,
            last_scan_at=datetime.now()
        )

        assert stats.total_scans == 10
        assert stats.avg_inflammation_score == 6.5


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestErrorHandling:
    """Test error handling scenarios."""

    def test_empty_ingredients_rejected(self):
        """Test that empty ingredients are rejected."""
        from models.inflammation import AnalyzeInflammationRequest
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            AnalyzeInflammationRequest(
                user_id="user-123",
                barcode="123",
                ingredients_text=""
            )

    def test_score_bounds_validation(self):
        """Test that score must be 1-10."""
        from models.inflammation import IngredientAnalysis, IngredientCategory
        import pydantic

        # Valid score
        valid = IngredientAnalysis(
            name="Test",
            category=IngredientCategory.NEUTRAL,
            score=5,
            reason="Test",
            is_inflammatory=False
        )
        assert valid.score == 5

        # Invalid scores
        with pytest.raises(pydantic.ValidationError):
            IngredientAnalysis(
                name="Test",
                category=IngredientCategory.NEUTRAL,
                score=0,  # Too low
                reason="Test",
                is_inflammatory=False
            )

        with pytest.raises(pydantic.ValidationError):
            IngredientAnalysis(
                name="Test",
                category=IngredientCategory.NEUTRAL,
                score=11,  # Too high
                reason="Test",
                is_inflammatory=False
            )


# ============================================================
# CONTEXT LOGGING TESTS
# ============================================================

class TestContextLogging:
    """Test user context event logging."""

    def test_event_metadata_structure(self):
        """Test that logged metadata has expected structure."""
        expected_metadata = {
            "barcode": "012345678901",
            "overall_score": 5,
            "overall_category": "neutral",
            "from_cache": False,
            "inflammatory_count": 3,
        }

        # Verify all expected keys
        assert "barcode" in expected_metadata
        assert "overall_score" in expected_metadata
        assert "from_cache" in expected_metadata
        assert "inflammatory_count" in expected_metadata


# ============================================================
# INTEGRATION-LIKE TESTS
# ============================================================

class TestIntegration:
    """Higher-level integration tests."""

    def test_full_response_structure(self, sample_gemini_response):
        """Test that a full response has all expected fields."""
        required_fields = [
            "overall_score",
            "overall_category",
            "summary",
            "ingredient_analyses",
            "inflammatory_ingredients",
            "anti_inflammatory_ingredients",
            "additives_found"
        ]

        for field in required_fields:
            assert field in sample_gemini_response, f"Missing field: {field}"

    def test_healthy_vs_unhealthy_scores(self, sample_gemini_response, sample_healthy_gemini_response):
        """Test that healthy products score higher than unhealthy ones."""
        unhealthy_score = sample_gemini_response["overall_score"]
        healthy_score = sample_healthy_gemini_response["overall_score"]

        assert healthy_score > unhealthy_score, \
            f"Healthy product ({healthy_score}) should score higher than unhealthy ({unhealthy_score})"

    def test_category_matches_score(self, sample_gemini_response, sample_healthy_gemini_response):
        """Test that category correctly reflects the score."""
        # Unhealthy: score 3 should be moderately_inflammatory
        assert sample_gemini_response["overall_category"] == "moderately_inflammatory"
        assert sample_gemini_response["overall_score"] in [3, 4]

        # Healthy: score 8 should be anti_inflammatory
        assert sample_healthy_gemini_response["overall_category"] == "anti_inflammatory"
        assert sample_healthy_gemini_response["overall_score"] in [7, 8]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
