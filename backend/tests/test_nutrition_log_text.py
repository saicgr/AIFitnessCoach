"""
Tests for Nutrition log-text endpoint and Gemini JSON parsing.

Tests:
- LogTextRequest validation
- parse_food_description with various Gemini response formats
- _extract_json_robust edge cases (malformed JSON, reversed fields, etc.)
- Full endpoint integration tests

Run with: pytest backend/tests/test_nutrition_log_text.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
import json

from fastapi import BackgroundTasks


# ============================================================
# FIXTURES
# ============================================================
#
# Patch-target note: `api.v1.nutrition` used to be a single module; it is now a
# package, and the /log-text handler lives in `api.v1.nutrition.food_logging`.
# Patching `api.v1.nutrition.<name>` no longer intercepts anything the handler
# resolves (the names aren't even attributes of the package), which is why every
# endpoint test in this file errored at fixture setup. All handler collaborators
# are now patched in the module that actually defines/uses them.
#
# Collaborator note: /log-text no longer calls `GeminiService.parse_food_description`
# directly. Food parsing goes through the food-analysis cache service
# (`get_food_analysis_cache_service().analyze_food(...)`, DB-cache first then
# Gemini). `mock_food_analysis` below stands in for that seam — the guarantees
# under test (a parsed meal is logged and returned; an unparseable meal is a 400;
# a user-fetch or RAG failure still logs the meal) are unchanged.

FOOD_LOGGING = "api.v1.nutrition.food_logging"


@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for nutrition operations."""
    with patch(f"{FOOD_LOGGING}.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        # The handler enriches the user row with nutrition targets before
        # reading goals off it; keep the row the test configured.
        mock_db.enrich_user_with_nutrition_targets.side_effect = lambda user: user
        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_food_analysis():
    """Mock the food-analysis cache service (the /log-text parsing seam)."""
    with patch(f"{FOOD_LOGGING}.get_food_analysis_cache_service") as mock_get_service:
        mock_service = MagicMock()
        mock_service.analyze_food = AsyncMock(return_value=None)
        mock_get_service.return_value = mock_service
        yield mock_service


@pytest.fixture
def mock_nutrition_rag():
    """Mock NutritionRAG service."""
    with patch(f"{FOOD_LOGGING}.get_nutrition_rag_service") as mock_get_rag:
        mock_rag = MagicMock()
        mock_rag.get_context_for_goals = AsyncMock(return_value=None)
        mock_get_rag.return_value = mock_rag
        yield mock_rag


@pytest.fixture(autouse=True)
def isolate_food_logging_side_effects():
    """Neutralize the /log-text collaborators that are not under test here.

    Each of these otherwise reaches out of process (real Supabase, Redis, the
    hydration LLM pre-pass) with its own module-local `get_supabase_db`, so they
    can't be steered by the `mock_supabase_db` fixture. They are exercised by
    their own tests; here they'd only add nondeterminism.

    Also disables the slowapi per-route limiter: these tests invoke the handler
    coroutine directly, and slowapi's wrapper demands a real starlette Request
    when enabled.
    """
    from core.rate_limiter import limiter

    was_enabled = limiter.enabled
    limiter.enabled = False
    with (
        patch(f"{FOOD_LOGGING}.lookup_personal_history_for_foods", new=AsyncMock(return_value=[])),
        patch(f"{FOOD_LOGGING}._is_hydration_tracking_enabled", new=AsyncMock(return_value=False)),
        patch(f"{FOOD_LOGGING}.resolve_timezone", return_value="America/Chicago"),
        patch(f"{FOOD_LOGGING}.get_user_calorie_bias", new=AsyncMock(return_value=0)),
        patch(
            "services.food_override_service.apply_user_food_overrides",
            side_effect=lambda db, user_id, items, **kw: (items, {}, 0),
        ),
        patch(
            "api.v1.nutrition.summaries.invalidate_daily_summary_cache",
            new=AsyncMock(return_value=None),
        ),
        patch(
            "api.v1.home.bootstrap_cache.invalidate_bootstrap_cache",
            new=AsyncMock(return_value=None),
        ),
    ):
        yield
    limiter.enabled = was_enabled


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


def _call_log_text(request_body, sample_user_id):
    """Invoke the /log-text handler directly with the params FastAPI injects."""
    from api.v1.nutrition import log_food_from_text

    return log_food_from_text(
        request_body,
        background_tasks=BackgroundTasks(),
        request=MagicMock(),
        current_user={"id": sample_user_id, "email": "test@example.com"},
    )


@pytest.fixture
def sample_parsed_food():
    """Sample successful Gemini response."""
    return {
        "food_items": [
            {
                "name": "Eggs",
                "amount": "2 large",
                "calories": 150,
                "protein_g": 12.0,
                "carbs_g": 1.2,
                "fat_g": 10.0,
                "fiber_g": 0,
                "goal_score": 8,
                "goal_alignment": "excellent",
                "reason": "High protein content supports muscle building"
            },
            {
                "name": "Dosa",
                "amount": "2 pieces",
                "calories": 200,
                "protein_g": 4.0,
                "carbs_g": 30.0,
                "fat_g": 8.0,
                "fiber_g": 2.0,
                "goal_score": 6,
                "goal_alignment": "good",
                "reason": "Good source of complex carbs"
            },
            {
                "name": "Chicken Curry",
                "amount": "1 serving",
                "calories": 300,
                "protein_g": 25.0,
                "carbs_g": 10.0,
                "fat_g": 18.0,
                "fiber_g": 1.0,
                "goal_score": 7,
                "goal_alignment": "good",
                "reason": "High protein from chicken"
            }
        ],
        "total_calories": 650,
        "protein_g": 41.0,
        "carbs_g": 41.2,
        "fat_g": 36.0,
        "fiber_g": 3.0,
        "overall_meal_score": 7,
        "health_score": 7,
        "goal_alignment_percentage": 75,
        "ai_suggestion": "Great protein intake! Consider adding more vegetables for fiber.",
        "encouragements": ["Excellent protein variety!", "Good portion sizes"],
        "warnings": ["Moderate fat content from curry"],
        "recommended_swap": "Try steamed rice instead of dosa for lower fat."
    }


# ============================================================
# JSON PARSING ROBUSTNESS TESTS
# ============================================================

class TestExtractJsonRobust:
    """Test the _extract_json_robust method with various edge cases."""

    def test_valid_json_direct_parse(self):
        """Test parsing clean, valid JSON."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        valid_json = '''{"food_items": [{"name": "Eggs", "calories": 150}], "total_calories": 150}'''
        result = service._extract_json_robust(valid_json)

        assert result is not None
        assert result["total_calories"] == 150
        assert len(result["food_items"]) == 1

    def test_json_with_markdown_wrapper(self):
        """Test parsing JSON wrapped in markdown code blocks."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        markdown_json = '''```json
{"food_items": [{"name": "Toast", "calories": 100}], "total_calories": 100}
```'''
        result = service._extract_json_robust(markdown_json)

        assert result is not None
        assert result["total_calories"] == 100

    def test_json_with_trailing_commas(self):
        """Test parsing JSON with trailing commas (common Gemini issue)."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        # JSON with trailing commas before closing brackets
        trailing_comma_json = '''{
  "food_items": [
    {
      "name": "Eggs",
      "calories": 150,
    },
  ],
  "total_calories": 150,
}'''
        result = service._extract_json_robust(trailing_comma_json)

        assert result is not None
        assert result["total_calories"] == 150

    def test_json_with_extra_text_before(self):
        """Test parsing JSON with explanatory text before the JSON."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        text_before_json = '''Here's the nutritional analysis:

{"food_items": [{"name": "Salad", "calories": 80}], "total_calories": 80}'''
        result = service._extract_json_robust(text_before_json)

        assert result is not None
        assert result["total_calories"] == 80

    def test_json_with_extra_text_after(self):
        """Test parsing JSON with text after the JSON."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        text_after_json = '''{"food_items": [{"name": "Rice", "calories": 200}], "total_calories": 200}

Note: Values are approximate.'''
        result = service._extract_json_robust(text_after_json)

        assert result is not None
        assert result["total_calories"] == 200

    def test_empty_content(self):
        """Test handling empty content."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        result = service._extract_json_robust("")
        assert result is None

        result = service._extract_json_robust(None)
        assert result is None

    def test_no_json_content(self):
        """Test handling content with no JSON."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        result = service._extract_json_robust("Just some text without any JSON")
        assert result is None

    def test_malformed_reversed_json_recovery(self):
        """Test recovery from malformed JSON (the original bug case)."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        # This simulates the bug where Gemini returned properties in weird order
        # The regex recovery should still extract food items
        malformed_json = '''{
  "food_items": [
    {
      "name": "Eggs",
      "amount": "2 large",
      "calories": 150,
      "protein_g": 12.0,
      "carbs_g": 1.2
    }
  ]
}'''
        result = service._extract_json_robust(malformed_json)

        assert result is not None
        assert len(result.get("food_items", [])) >= 1

    def test_partial_json_recovery(self):
        """Test partial recovery when only food_items array is parseable."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        # Partially valid JSON with food_items array
        partial_json = '''{
  "food_items": [
    {"name": "Eggs", "calories": 150, "protein_g": 12.0, "carbs_g": 1.2, "fat_g": 10.0, "fiber_g": 0}
  ],
  broken_field_here
}'''
        result = service._extract_json_robust(partial_json)

        # Should recover with regex extraction
        if result:
            assert "food_items" in result
            assert len(result["food_items"]) == 1

    def test_nested_objects_extraction(self):
        """Test extraction of properly nested JSON objects."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        nested_json = '''{
  "food_items": [
    {
      "name": "Complex Dish",
      "calories": 400,
      "protein_g": 20.0,
      "carbs_g": 30.0,
      "fat_g": 15.0,
      "fiber_g": 5.0,
      "goal_score": 7,
      "goal_alignment": "good",
      "reason": "Balanced macros"
    }
  ],
  "total_calories": 400,
  "protein_g": 20.0,
  "carbs_g": 30.0,
  "fat_g": 15.0,
  "fiber_g": 5.0,
  "health_score": 8,
  "ai_suggestion": "Great balanced meal!"
}'''
        result = service._extract_json_robust(nested_json)

        assert result is not None
        assert result["total_calories"] == 400
        assert result["health_score"] == 8

    def test_multiple_food_items_recovery(self):
        """Test recovery with multiple food items."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        multi_item_json = '''{
  "food_items": [
    {"name": "Eggs", "calories": 150, "protein_g": 12.0, "carbs_g": 1.2, "fat_g": 10.0, "fiber_g": 0},
    {"name": "Toast", "calories": 100, "protein_g": 3.0, "carbs_g": 20.0, "fat_g": 1.0, "fiber_g": 2.0},
    {"name": "Orange Juice", "calories": 110, "protein_g": 1.0, "carbs_g": 26.0, "fat_g": 0.5, "fiber_g": 0}
  ],
  "total_calories": 360,
  "protein_g": 16.0,
  "carbs_g": 47.2,
  "fat_g": 11.5,
  "fiber_g": 2.0
}'''
        result = service._extract_json_robust(multi_item_json)

        assert result is not None
        assert len(result["food_items"]) == 3
        assert result["total_calories"] == 360


# ============================================================
# LOG TEXT ENDPOINT TESTS
# ============================================================

class TestLogFoodFromText:
    """Test the log_food_from_text endpoint."""

    @pytest.mark.asyncio
    async def test_log_food_from_text_success(
        self, mock_supabase_db, mock_food_analysis, mock_nutrition_rag, sample_user_id, sample_parsed_food
    ):
        """Test successful food logging from text."""
        from api.v1.nutrition import LogTextRequest

        # Setup mocks
        mock_supabase_db.get_user.return_value = {
            "goals": '["build_muscle"]',
            "daily_calorie_target": 2500,
            "daily_protein_target_g": 180,
        }
        mock_food_analysis.analyze_food = AsyncMock(return_value=sample_parsed_food)
        mock_nutrition_rag.get_context_for_goals = AsyncMock(return_value="Sample RAG context")
        mock_supabase_db.create_food_log.return_value = {
            "id": "log-123",
            "user_id": sample_user_id,
            "meal_type": "breakfast",
            **sample_parsed_food
        }

        request = LogTextRequest(
            user_id=sample_user_id,
            description="I ate 2 eggs and 2 dosas with chicken curry",
            meal_type="breakfast"
        )

        result = await _call_log_text(request, sample_user_id)

        assert result.success is True
        assert result.food_log_id == "log-123"
        assert result.total_calories == 650

    @pytest.mark.asyncio
    async def test_log_food_from_text_gemini_failure(
        self, mock_supabase_db, mock_food_analysis, mock_nutrition_rag, sample_user_id
    ):
        """Test handling when the food analyzer fails to parse food."""
        from api.v1.nutrition import LogTextRequest
        from fastapi import HTTPException

        mock_supabase_db.get_user.return_value = {"goals": "[]"}
        mock_food_analysis.analyze_food = AsyncMock(return_value=None)

        request = LogTextRequest(
            user_id=sample_user_id,
            description="some random text",
            meal_type="lunch"
        )

        with pytest.raises(HTTPException) as exc_info:
            await _call_log_text(request, sample_user_id)

        assert exc_info.value.status_code == 400
        assert "Could not parse any food items" in str(exc_info.value.detail)

    @pytest.mark.asyncio
    async def test_log_food_from_text_empty_food_items(
        self, mock_supabase_db, mock_food_analysis, mock_nutrition_rag, sample_user_id
    ):
        """Test handling when the food analyzer returns empty food_items."""
        from api.v1.nutrition import LogTextRequest
        from fastapi import HTTPException

        mock_supabase_db.get_user.return_value = {"goals": "[]"}
        mock_food_analysis.analyze_food = AsyncMock(return_value={"food_items": []})

        request = LogTextRequest(
            user_id=sample_user_id,
            description="nothing",
            meal_type="snack"
        )

        with pytest.raises(HTTPException) as exc_info:
            await _call_log_text(request, sample_user_id)

        assert exc_info.value.status_code == 400

    @pytest.mark.asyncio
    async def test_log_food_from_text_without_user_goals(
        self, mock_supabase_db, mock_food_analysis, mock_nutrition_rag, sample_user_id
    ):
        """Test food logging when user has no fitness goals set."""
        from api.v1.nutrition import LogTextRequest

        simple_parsed_food = {
            "food_items": [
                {"name": "Apple", "calories": 95, "protein_g": 0.5, "carbs_g": 25, "fat_g": 0.3, "fiber_g": 4}
            ],
            "total_calories": 95,
            "protein_g": 0.5,
            "carbs_g": 25,
            "fat_g": 0.3,
            "fiber_g": 4,
            "health_score": 9,
            "ai_suggestion": "Great healthy snack!"
        }

        mock_supabase_db.get_user.return_value = {"goals": "[]"}
        mock_food_analysis.analyze_food = AsyncMock(return_value=simple_parsed_food)
        mock_supabase_db.create_food_log.return_value = {
            "id": "log-456",
            "user_id": sample_user_id,
            **simple_parsed_food
        }

        request = LogTextRequest(
            user_id=sample_user_id,
            description="an apple",
            meal_type="snack"
        )

        result = await _call_log_text(request, sample_user_id)

        assert result.success is True
        assert result.total_calories == 95
        # No goals → no goal-conditioned RAG retrieval is attempted.
        mock_nutrition_rag.get_context_for_goals.assert_not_called()


# ============================================================
# INPUT VALIDATION TESTS
# ============================================================

class TestLogTextRequestValidation:
    """Test LogTextRequest model validation."""

    def test_valid_request(self):
        """Test valid request creation."""
        from api.v1.nutrition import LogTextRequest

        request = LogTextRequest(
            user_id="user-123",
            description="2 scrambled eggs with toast",
            meal_type="breakfast"
        )

        assert request.user_id == "user-123"
        assert request.description == "2 scrambled eggs with toast"
        assert request.meal_type == "breakfast"

    def test_request_with_long_description(self):
        """Test request with long food description."""
        from api.v1.nutrition import LogTextRequest

        long_description = "I had a large breakfast consisting of: " + \
            "3 scrambled eggs with cheese, 2 slices of whole wheat toast with butter and jam, " + \
            "a bowl of oatmeal with banana slices and honey, a cup of Greek yogurt with berries, " + \
            "orange juice, and a cup of black coffee."

        request = LogTextRequest(
            user_id="user-123",
            description=long_description,
            meal_type="breakfast"
        )

        assert len(request.description) > 200
        assert request.meal_type == "breakfast"

    def test_request_with_unicode_food_names(self):
        """Test request with unicode characters in food names."""
        from api.v1.nutrition import LogTextRequest

        request = LogTextRequest(
            user_id="user-123",
            description="I had dosa (ದೋಸೆ) with sambar and chutney",
            meal_type="lunch"
        )

        assert "dosa" in request.description.lower()

    def test_various_meal_types(self):
        """Test various meal type values."""
        from api.v1.nutrition import LogTextRequest

        meal_types = ["breakfast", "lunch", "dinner", "snack", "pre_workout", "post_workout"]

        for meal_type in meal_types:
            request = LogTextRequest(
                user_id="user-123",
                description="some food",
                meal_type=meal_type
            )
            assert request.meal_type == meal_type


# ============================================================
# EDGE CASE TESTS
# ============================================================

class TestEdgeCases:
    """Test edge cases and error scenarios."""

    @pytest.mark.asyncio
    async def test_database_error_on_user_fetch(
        self, mock_supabase_db, mock_food_analysis, mock_nutrition_rag, sample_user_id, sample_parsed_food
    ):
        """Test graceful handling when user fetch fails."""
        from api.v1.nutrition import LogTextRequest

        # User fetch fails but we should still proceed
        mock_supabase_db.get_user.side_effect = Exception("Database error")
        mock_food_analysis.analyze_food = AsyncMock(return_value=sample_parsed_food)
        mock_supabase_db.create_food_log.return_value = {
            "id": "log-789",
            "user_id": sample_user_id,
            **sample_parsed_food
        }

        request = LogTextRequest(
            user_id=sample_user_id,
            description="eggs and toast",
            meal_type="breakfast"
        )

        # Should still succeed, just without personalized analysis
        result = await _call_log_text(request, sample_user_id)
        assert result.success is True
        assert result.food_log_id == "log-789"

    @pytest.mark.asyncio
    async def test_rag_service_failure(
        self, mock_supabase_db, mock_food_analysis, mock_nutrition_rag, sample_user_id, sample_parsed_food
    ):
        """Test graceful handling when RAG service fails."""
        from api.v1.nutrition import LogTextRequest

        mock_supabase_db.get_user.return_value = {"goals": '["lose_weight"]'}
        mock_nutrition_rag.get_context_for_goals = AsyncMock(side_effect=Exception("RAG error"))
        mock_food_analysis.analyze_food = AsyncMock(return_value=sample_parsed_food)
        mock_supabase_db.create_food_log.return_value = {
            "id": "log-101",
            "user_id": sample_user_id,
            **sample_parsed_food
        }

        request = LogTextRequest(
            user_id=sample_user_id,
            description="salad with chicken",
            meal_type="lunch"
        )

        # Should succeed without RAG context
        result = await _call_log_text(request, sample_user_id)
        assert result.success is True
        assert result.food_log_id == "log-101"
        # The RAG lookup was genuinely attempted (user has goals) and it blew up.
        mock_nutrition_rag.get_context_for_goals.assert_awaited_once()

    def test_gemini_response_with_null_values(self):
        """Test handling of null values in Gemini response."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        json_with_nulls = '''{
  "food_items": [
    {"name": "Unknown Food", "calories": 100, "protein_g": null, "carbs_g": null, "fat_g": null, "fiber_g": null}
  ],
  "total_calories": 100,
  "protein_g": null,
  "carbs_g": null,
  "fat_g": null,
  "fiber_g": null,
  "health_score": 5
}'''
        result = service._extract_json_robust(json_with_nulls)

        assert result is not None
        assert result["total_calories"] == 100
        # Null values should be preserved as None
        assert result["protein_g"] is None

    def test_gemini_response_with_float_values(self):
        """Test handling of float values in Gemini response."""
        from services.gemini_service import GeminiService
        service = GeminiService()

        json_with_floats = '''{
  "food_items": [
    {"name": "Precision Food", "calories": 152.5, "protein_g": 12.75, "carbs_g": 1.25, "fat_g": 10.5, "fiber_g": 0.5}
  ],
  "total_calories": 152.5,
  "protein_g": 12.75,
  "carbs_g": 1.25,
  "fat_g": 10.5,
  "fiber_g": 0.5
}'''
        result = service._extract_json_robust(json_with_floats)

        assert result is not None
        assert result["total_calories"] == 152.5
        assert result["protein_g"] == 12.75


# ============================================================
# INTEGRATION-STYLE TESTS (with real GeminiService method)
# ============================================================

class TestGeminiServiceParsing:
    """Test GeminiService food description parsing (method level)."""

    def test_gemini_service_initialization(self):
        """Test that GeminiService can be initialized."""
        from services.gemini_service import GeminiService
        service = GeminiService()
        assert service is not None

    def test_extract_json_robust_exists(self):
        """Test that _extract_json_robust method exists on GeminiService."""
        from services.gemini_service import GeminiService
        service = GeminiService()
        assert hasattr(service, '_extract_json_robust')
        assert callable(service._extract_json_robust)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
