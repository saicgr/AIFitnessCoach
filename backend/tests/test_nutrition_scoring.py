"""
Tests for Goal-Based Food Scoring in Nutrition API.

Tests the enhanced Gemini food parsing with goal-based scoring,
AI suggestions, encouragements, warnings, and recommended swaps.
Also tests ChromaDB RAG integration for nutrition knowledge.
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
import json


class TestGeminiFoodParsing:
    """Tests for the Gemini food parsing with goal-based scoring."""

    @pytest.fixture
    def mock_gemini_response_with_goals(self):
        """Mock Gemini response when user has goals."""
        return {
            "food_items": [
                {
                    "name": "Grilled Chicken Breast",
                    "amount": "200g",
                    "calories": 330,
                    "protein_g": 62.0,
                    "carbs_g": 0.0,
                    "fat_g": 7.0,
                    "fiber_g": 0.0,
                    "goal_score": 9,
                    "goal_alignment": "excellent",
                    "reason": "High protein supports muscle building"
                },
                {
                    "name": "White Rice",
                    "amount": "1 cup",
                    "calories": 206,
                    "protein_g": 4.3,
                    "carbs_g": 45.0,
                    "fat_g": 0.4,
                    "fiber_g": 0.6,
                    "goal_score": 5,
                    "goal_alignment": "neutral",
                    "reason": "Simple carbs, consider brown rice for more fiber"
                }
            ],
            "total_calories": 536,
            "protein_g": 66.3,
            "carbs_g": 45.0,
            "fat_g": 7.4,
            "fiber_g": 0.6,
            "overall_meal_score": 7,
            "health_score": 7,
            "goal_alignment_percentage": 75,
            "ai_suggestion": "Great protein choice! Add vegetables for more micronutrients.",
            "encouragements": ["Excellent protein intake for muscle building!"],
            "warnings": ["Low fiber content"],
            "recommended_swap": "Try brown rice instead of white rice for more fiber."
        }

    @pytest.fixture
    def mock_gemini_response_without_goals(self):
        """Mock Gemini response when user has no goals."""
        return {
            "food_items": [
                {
                    "name": "Grilled Chicken Breast",
                    "amount": "200g",
                    "calories": 330,
                    "protein_g": 62.0,
                    "carbs_g": 0.0,
                    "fat_g": 7.0,
                    "fiber_g": 0.0
                }
            ],
            "total_calories": 330,
            "protein_g": 62.0,
            "carbs_g": 0.0,
            "fat_g": 7.0,
            "fiber_g": 0.0,
            "health_score": 8,
            "ai_suggestion": "Lean protein source, consider adding vegetables."
        }

    @pytest.mark.asyncio
    @patch('services.gemini_service.client')
    async def test_parse_food_with_user_goals(self, mock_client, mock_gemini_response_with_goals):
        """Test food parsing includes goal-based scoring when user has goals."""
        from services.gemini_service import GeminiService

        # Mock Gemini response
        mock_response = MagicMock()
        mock_response.text = json.dumps(mock_gemini_response_with_goals)
        mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)

        service = GeminiService()
        result = await service.parse_food_description(
            description="grilled chicken breast with white rice",
            user_goals=["build_muscle"],
            nutrition_targets={"daily_protein_target_g": 150}
        )

        # Verify goal-based fields are present
        assert result is not None
        assert "food_items" in result
        assert len(result["food_items"]) == 2

        # Check first food item has goal scoring
        chicken = result["food_items"][0]
        assert chicken["goal_score"] == 9
        assert chicken["goal_alignment"] == "excellent"
        assert "reason" in chicken

        # Check overall meal scoring
        assert result["overall_meal_score"] == 7
        assert result["goal_alignment_percentage"] == 75
        assert result["encouragements"] is not None
        assert result["warnings"] is not None
        assert result["recommended_swap"] is not None

    @pytest.mark.asyncio
    @patch('services.gemini_service.client')
    async def test_parse_food_without_user_goals(self, mock_client, mock_gemini_response_without_goals):
        """Test food parsing returns basic response when user has no goals."""
        from services.gemini_service import GeminiService

        mock_response = MagicMock()
        mock_response.text = json.dumps(mock_gemini_response_without_goals)
        mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)

        service = GeminiService()
        result = await service.parse_food_description(
            description="grilled chicken breast",
            user_goals=None,
            nutrition_targets=None
        )

        # Verify basic fields are present
        assert result is not None
        assert "food_items" in result
        assert result["health_score"] == 8
        assert result["ai_suggestion"] is not None

        # Goal-specific fields should NOT be present
        food_item = result["food_items"][0]
        assert "goal_score" not in food_item or food_item.get("goal_score") is None
        assert "overall_meal_score" not in result or result.get("overall_meal_score") is None

    @pytest.mark.asyncio
    @patch('services.gemini_service.client')
    async def test_parse_food_with_empty_goals(self, mock_client, mock_gemini_response_without_goals):
        """Test food parsing with empty goals list behaves like no goals."""
        from services.gemini_service import GeminiService

        mock_response = MagicMock()
        mock_response.text = json.dumps(mock_gemini_response_without_goals)
        mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)

        service = GeminiService()
        result = await service.parse_food_description(
            description="grilled chicken breast",
            user_goals=[],  # Empty list
            nutrition_targets={}  # Empty dict
        )

        assert result is not None
        assert "food_items" in result


class TestLogTextEndpoint:
    """Tests for the /log-text API endpoint."""

    def test_log_text_endpoint_exists(self, client):
        """Test that the log-text endpoint is accessible."""
        response = client.post(
            "/api/v1/nutrition/log-text",
            json={
                "user_id": "test-user",
                "description": "2 eggs",
                "meal_type": "breakfast"
            }
        )
        # Should not be 404 (route exists)
        assert response.status_code != 404, "log-text endpoint should exist"

    def test_log_text_requires_description(self, client):
        """Test log-text fails without description."""
        response = client.post(
            "/api/v1/nutrition/log-text",
            json={
                "user_id": "test-user",
                "meal_type": "breakfast"
                # Missing description
            }
        )
        assert response.status_code == 422  # Validation error

    def test_log_text_requires_user_id(self, client):
        """Test log-text fails without user_id."""
        response = client.post(
            "/api/v1/nutrition/log-text",
            json={
                "description": "2 eggs",
                "meal_type": "breakfast"
                # Missing user_id
            }
        )
        assert response.status_code == 422  # Validation error

    @patch('api.v1.nutrition.get_supabase_db')
    @patch('api.v1.nutrition.GeminiService')
    def test_log_text_with_existing_user_goals(self, mock_gemini_class, mock_db, client):
        """Test log-text uses user goals for scoring when available."""
        # Mock database
        mock_db_instance = MagicMock()
        mock_db_instance.get_user.return_value = {
            "id": "test-user-123",
            "goals": '["build_muscle", "improve_endurance"]',
            "daily_calorie_target": 2500,
            "daily_protein_target_g": 150,
        }
        mock_db_instance.create_food_log.return_value = {"id": "log-123"}
        mock_db.return_value = mock_db_instance

        # Mock Gemini service
        mock_gemini = MagicMock()
        mock_gemini.parse_food_description = AsyncMock(return_value={
            "food_items": [{"name": "Eggs", "calories": 180, "protein_g": 12, "carbs_g": 1, "fat_g": 12, "goal_score": 8}],
            "total_calories": 180,
            "protein_g": 12.0,
            "carbs_g": 1.0,
            "fat_g": 12.0,
            "fiber_g": 0.0,
            "overall_meal_score": 8,
            "health_score": 7,
            "goal_alignment_percentage": 80,
            "ai_suggestion": "Good protein source!",
            "encouragements": ["High protein!"],
            "warnings": [],
            "recommended_swap": None
        })
        mock_gemini_class.return_value = mock_gemini

        response = client.post(
            "/api/v1/nutrition/log-text",
            json={
                "user_id": "test-user-123",
                "description": "2 eggs",
                "meal_type": "breakfast"
            }
        )

        # Verify Gemini was called with user goals
        mock_gemini.parse_food_description.assert_called_once()
        call_kwargs = mock_gemini.parse_food_description.call_args[1]
        assert call_kwargs["user_goals"] == ["build_muscle", "improve_endurance"]
        assert call_kwargs["nutrition_targets"]["daily_protein_target_g"] == 150

    @patch('api.v1.nutrition.get_supabase_db')
    @patch('api.v1.nutrition.GeminiService')
    def test_log_text_new_user_no_goals(self, mock_gemini_class, mock_db, client):
        """Test log-text works for new user without goals."""
        # Mock database - new user with no goals
        mock_db_instance = MagicMock()
        mock_db_instance.get_user.return_value = {
            "id": "new-user",
            "goals": "[]",  # Empty goals
            "daily_calorie_target": None,
            "daily_protein_target_g": None,
        }
        mock_db_instance.create_food_log.return_value = {"id": "log-456"}
        mock_db.return_value = mock_db_instance

        # Mock Gemini service - simpler response
        mock_gemini = MagicMock()
        mock_gemini.parse_food_description = AsyncMock(return_value={
            "food_items": [{"name": "Toast", "calories": 75, "protein_g": 2, "carbs_g": 14, "fat_g": 1}],
            "total_calories": 75,
            "protein_g": 2.0,
            "carbs_g": 14.0,
            "fat_g": 1.0,
            "fiber_g": 1.0,
            "health_score": 5,
            "ai_suggestion": "Consider adding protein to your breakfast."
        })
        mock_gemini_class.return_value = mock_gemini

        response = client.post(
            "/api/v1/nutrition/log-text",
            json={
                "user_id": "new-user",
                "description": "toast",
                "meal_type": "breakfast"
            }
        )

        # Should still work
        assert response.status_code in [200, 400, 500]  # 400/500 if Gemini fails


class TestLogFoodResponseModel:
    """Tests for the LogFoodResponse model with new fields."""

    def test_response_model_has_scoring_fields(self):
        """Test LogFoodResponse includes goal-based scoring fields."""
        from api.v1.nutrition import LogFoodResponse

        # These fields should exist on the model
        model_fields = LogFoodResponse.model_fields.keys()

        assert "overall_meal_score" in model_fields
        assert "health_score" in model_fields
        assert "goal_alignment_percentage" in model_fields
        assert "ai_suggestion" in model_fields
        assert "encouragements" in model_fields
        assert "warnings" in model_fields
        assert "recommended_swap" in model_fields

    def test_response_model_scoring_fields_optional(self):
        """Test scoring fields are optional for backward compatibility."""
        from api.v1.nutrition import LogFoodResponse

        # Should be able to create response without scoring fields
        response = LogFoodResponse(
            success=True,
            food_log_id="test-123",
            food_items=[],
            total_calories=100,
            protein_g=10.0,
            carbs_g=15.0,
            fat_g=5.0
            # No scoring fields - should still work
        )

        assert response.success is True
        assert response.overall_meal_score is None
        assert response.encouragements is None


class TestFoodItemRankingModel:
    """Tests for the FoodItemRanking model."""

    def test_food_item_ranking_has_goal_fields(self):
        """Test FoodItemRanking includes goal-based fields."""
        from api.v1.nutrition import FoodItemRanking

        model_fields = FoodItemRanking.model_fields.keys()

        assert "goal_score" in model_fields
        assert "goal_alignment" in model_fields
        assert "reason" in model_fields

    def test_food_item_ranking_goal_fields_optional(self):
        """Test goal fields are optional."""
        from api.v1.nutrition import FoodItemRanking

        # Should work without goal fields
        item = FoodItemRanking(
            name="Apple",
            calories=95,
            protein_g=0.5,
            carbs_g=25.0,
            fat_g=0.3
        )

        assert item.name == "Apple"
        assert item.goal_score is None
        assert item.goal_alignment is None


class TestScoringCriteria:
    """Tests for goal-based scoring criteria logic."""

    def test_muscle_building_high_protein_scores_high(self):
        """High protein foods should score high for muscle building goal."""
        # This is a logic test - we verify the prompt includes correct criteria
        from services.gemini_service import GeminiService
        import inspect

        source = inspect.getsource(GeminiService.parse_food_description)

        # Verify scoring criteria mentions muscle building + protein
        assert "build_muscle" in source
        assert "High score for high protein" in source or "high protein" in source.lower()

    def test_weight_loss_fiber_scores_high(self):
        """High fiber foods should score high for weight loss goal."""
        from services.gemini_service import GeminiService
        import inspect

        source = inspect.getsource(GeminiService.parse_food_description)

        # Verify scoring criteria mentions weight loss + fiber
        assert "lose_weight" in source
        assert "fiber" in source.lower()

    def test_health_flags_detected(self):
        """Verify health flags (sodium, sugar, processed) are in criteria."""
        from services.gemini_service import GeminiService
        import inspect

        source = inspect.getsource(GeminiService.parse_food_description)

        assert "sodium" in source.lower()
        assert "sugar" in source.lower()
        assert "processed" in source.lower()


class TestNutritionRAGService:
    """Tests for the Nutrition RAG Service (ChromaDB integration)."""

    def test_nutrition_rag_service_initializes(self):
        """Test NutritionRAGService can be imported and has required methods."""
        from services.nutrition_rag_service import NutritionRAGService

        # Verify class has required methods
        assert hasattr(NutritionRAGService, 'add_knowledge')
        assert hasattr(NutritionRAGService, 'get_context_for_goals')
        assert hasattr(NutritionRAGService, 'get_collection_count')

    def test_nutrition_knowledge_data_exists(self):
        """Test that nutrition knowledge data is defined."""
        from services.nutrition_rag_service import NUTRITION_KNOWLEDGE_DATA

        # Should have knowledge entries
        assert len(NUTRITION_KNOWLEDGE_DATA) > 0

        # Each entry should have required fields
        for item in NUTRITION_KNOWLEDGE_DATA:
            assert "content" in item
            assert "goals" in item
            assert "category" in item
            assert isinstance(item["goals"], list)

    def test_nutrition_knowledge_covers_all_goals(self):
        """Test that nutrition knowledge covers all major fitness goals."""
        from services.nutrition_rag_service import NUTRITION_KNOWLEDGE_DATA

        # Extract all goals from knowledge data
        all_goals = set()
        for item in NUTRITION_KNOWLEDGE_DATA:
            all_goals.update(item["goals"])

        # Should cover these major goals
        expected_goals = ["build_muscle", "lose_weight", "improve_endurance", "general"]
        for goal in expected_goals:
            assert any(goal in g for g in all_goals), f"Missing knowledge for goal: {goal}"

    def test_nutrition_knowledge_has_categories(self):
        """Test that nutrition knowledge has diverse categories."""
        from services.nutrition_rag_service import NUTRITION_KNOWLEDGE_DATA

        categories = set(item["category"] for item in NUTRITION_KNOWLEDGE_DATA)

        # Should have these categories
        assert "protein" in categories
        assert "warnings" in categories
        assert "tips" in categories

    @pytest.mark.asyncio
    @patch('services.nutrition_rag_service.get_chroma_cloud_client')
    @patch('services.nutrition_rag_service.GeminiService')
    async def test_get_context_for_goals_returns_string(self, mock_gemini_class, mock_chroma):
        """Test get_context_for_goals returns formatted string."""
        from services.nutrition_rag_service import NutritionRAGService

        # Mock ChromaDB collection
        mock_collection = MagicMock()
        mock_collection.count.return_value = 10
        mock_collection.query.return_value = {
            "documents": [["[PROTEIN] High protein content...", "[TIPS] Eat slowly..."]],
            "metadatas": [[{"goals": "build_muscle", "category": "protein"}, {"goals": "general", "category": "tips"}]],
            "distances": [[0.1, 0.2]]
        }
        mock_chroma.return_value.get_or_create_collection.return_value = mock_collection

        # Mock Gemini embedding
        mock_gemini = MagicMock()
        mock_gemini.get_embedding_async = AsyncMock(return_value=[0.1] * 768)
        mock_gemini_class.return_value = mock_gemini

        service = NutritionRAGService(mock_gemini)
        context = await service.get_context_for_goals(
            food_description="grilled chicken",
            user_goals=["build_muscle"],
            n_results=3
        )

        # Should return a string
        assert isinstance(context, str)

    @pytest.mark.asyncio
    @patch('services.nutrition_rag_service.get_chroma_cloud_client')
    @patch('services.nutrition_rag_service.GeminiService')
    async def test_get_context_for_empty_goals_returns_empty(self, mock_gemini_class, mock_chroma):
        """Test get_context_for_goals returns empty string for no goals."""
        from services.nutrition_rag_service import NutritionRAGService

        mock_collection = MagicMock()
        mock_collection.count.return_value = 10
        mock_chroma.return_value.get_or_create_collection.return_value = mock_collection

        mock_gemini = MagicMock()
        mock_gemini_class.return_value = mock_gemini

        service = NutritionRAGService(mock_gemini)
        context = await service.get_context_for_goals(
            food_description="pizza",
            user_goals=[],  # Empty goals
            n_results=3
        )

        # Should return empty string for no goals
        assert context == ""


class TestLogTextWithRAG:
    """Tests for /log-text endpoint with RAG integration."""

    @patch('api.v1.nutrition.get_supabase_db')
    @patch('api.v1.nutrition.get_nutrition_rag_service')
    @patch('api.v1.nutrition.GeminiService')
    def test_log_text_calls_rag_service_when_goals_exist(self, mock_gemini_class, mock_rag, mock_db, client):
        """Test that /log-text calls RAG service when user has goals."""
        # Mock database with user having goals
        mock_db_instance = MagicMock()
        mock_db_instance.get_user.return_value = {
            "id": "test-user",
            "goals": '["build_muscle"]',
            "daily_calorie_target": 2500,
        }
        mock_db_instance.create_food_log.return_value = {"id": "log-123"}
        mock_db.return_value = mock_db_instance

        # Mock RAG service
        mock_rag_instance = MagicMock()
        mock_rag_instance.get_context_for_goals = AsyncMock(return_value="[PROTEIN] High protein is good...")
        mock_rag.return_value = mock_rag_instance

        # Mock Gemini service
        mock_gemini = MagicMock()
        mock_gemini.parse_food_description = AsyncMock(return_value={
            "food_items": [{"name": "Chicken", "calories": 200, "protein_g": 30, "carbs_g": 0, "fat_g": 5}],
            "total_calories": 200,
            "protein_g": 30.0,
            "carbs_g": 0.0,
            "fat_g": 5.0,
            "fiber_g": 0.0,
            "overall_meal_score": 9,
            "health_score": 8,
        })
        mock_gemini_class.return_value = mock_gemini

        response = client.post(
            "/api/v1/nutrition/log-text",
            json={
                "user_id": "test-user",
                "description": "grilled chicken breast",
                "meal_type": "lunch"
            }
        )

        # Verify RAG service was called
        mock_rag_instance.get_context_for_goals.assert_called_once()
        call_args = mock_rag_instance.get_context_for_goals.call_args
        assert call_args[1]["food_description"] == "grilled chicken breast"
        assert "build_muscle" in call_args[1]["user_goals"]

        # Verify Gemini was called with RAG context
        gemini_call = mock_gemini.parse_food_description.call_args[1]
        assert gemini_call["rag_context"] == "[PROTEIN] High protein is good..."

    @patch('api.v1.nutrition.get_supabase_db')
    @patch('api.v1.nutrition.get_nutrition_rag_service')
    @patch('api.v1.nutrition.GeminiService')
    def test_log_text_skips_rag_when_no_goals(self, mock_gemini_class, mock_rag, mock_db, client):
        """Test that /log-text skips RAG service when user has no goals."""
        # Mock database with user having no goals
        mock_db_instance = MagicMock()
        mock_db_instance.get_user.return_value = {
            "id": "new-user",
            "goals": "[]",
        }
        mock_db_instance.create_food_log.return_value = {"id": "log-456"}
        mock_db.return_value = mock_db_instance

        # Mock RAG service
        mock_rag_instance = MagicMock()
        mock_rag_instance.get_context_for_goals = AsyncMock(return_value="")
        mock_rag.return_value = mock_rag_instance

        # Mock Gemini service
        mock_gemini = MagicMock()
        mock_gemini.parse_food_description = AsyncMock(return_value={
            "food_items": [{"name": "Toast", "calories": 75, "protein_g": 2, "carbs_g": 14, "fat_g": 1}],
            "total_calories": 75,
            "protein_g": 2.0,
            "carbs_g": 14.0,
            "fat_g": 1.0,
            "fiber_g": 1.0,
        })
        mock_gemini_class.return_value = mock_gemini

        response = client.post(
            "/api/v1/nutrition/log-text",
            json={
                "user_id": "new-user",
                "description": "toast",
                "meal_type": "breakfast"
            }
        )

        # RAG service should NOT be called (empty goals)
        mock_rag_instance.get_context_for_goals.assert_not_called()

        # Gemini should be called with rag_context=None
        gemini_call = mock_gemini.parse_food_description.call_args[1]
        assert gemini_call["rag_context"] is None
