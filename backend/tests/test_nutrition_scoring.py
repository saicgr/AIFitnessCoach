"""
Tests for Goal-Based Food Scoring in Nutrition API.

Tests the enhanced Gemini food parsing with goal-based scoring,
AI suggestions, encouragements, warnings, and recommended swaps.
Also tests ChromaDB RAG integration for nutrition knowledge.
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
import json

from fastapi.testclient import TestClient

from main import app
from core.auth import get_current_user


TEST_USER_ID = "test-user"


@pytest.fixture
def client():
    """TestClient with the nutrition routes' auth dependency satisfied.

    POST /api/v1/nutrition/log-text now declares
    `current_user: dict = Depends(get_current_user)` and overwrites
    `body.user_id` with the authenticated id (the endpoint deliberately does not
    trust a client-supplied user_id). An anonymous call is rejected with 401
    before the handler runs, so these tests were asserting 401 == 422/200.

    Overriding the dependency is a fix to HOW the tests call the endpoint —
    every assertion below is unchanged in intent. Shadows conftest's anonymous
    `client` fixture for this module only; the override is popped on teardown so
    it cannot leak into other test modules.
    """
    app.dependency_overrides[get_current_user] = lambda: {
        "id": TEST_USER_ID,
        "auth_id": TEST_USER_ID,
        "email": "nutrition-tests@example.com",
    }
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


def _gemini_response(payload: dict) -> MagicMock:
    """Fake google-genai response object carrying `payload` as its JSON text."""
    response = MagicMock()
    response.text = json.dumps(payload)
    return response


class TestGeminiFoodParsing:
    """Tests for the Gemini food parsing with goal-based scoring.

    PATCH TARGETS UPDATED: `services.gemini_service` is now a re-export shim —
    the implementation moved to the `services.gemini` package, the module-level
    google-genai `client` moved to `services.gemini.constants`, and
    `parse_food_description` (services/gemini/nutrition.py) issues its call
    through `gemini_generate_with_retry`. Patching `services.gemini_service.client`
    therefore raised AttributeError before a single assertion ran. The tests now
    patch the current call seam. What they assert is unchanged.

    Two collaborators of `parse_food_description` are also stubbed so the unit
    test stays hermetic (they are network/DB, not the behavior under test):
      * `_enhance_food_items_with_nutrition_db` — Supabase per-100g lookup, which
        returns items unchanged when nothing matches (what the stub emulates);
      * `_food_text_cache` — the shared (possibly Redis-backed) food-text cache,
        which would otherwise let one run's result satisfy another's assertions.
    """

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

    @pytest.fixture(autouse=True)
    def _isolate_parse_food_description(self):
        """Stub the non-Gemini collaborators of parse_food_description.

        Nutrition-DB enhancement is emulated as "no DB match" (returns the AI
        items untouched — its real behavior when a food name isn't found), and
        the food-text cache is forced to a miss so every test drives the model
        call it patches.
        """
        cache = MagicMock()
        cache.make_key = MagicMock(return_value="test-cache-key")
        cache.get = AsyncMock(return_value=None)
        cache.set = AsyncMock()

        async def _no_db_match(items, *args, **kwargs):
            return items

        with patch('services.gemini.nutrition._food_text_cache', cache), \
             patch(
                 'services.gemini_service.GeminiService._enhance_food_items_with_nutrition_db',
                 new=AsyncMock(side_effect=_no_db_match),
             ):
            yield

    @pytest.mark.asyncio
    @patch('services.gemini.nutrition.gemini_generate_with_retry', new_callable=AsyncMock)
    async def test_parse_food_with_user_goals(self, mock_generate, mock_gemini_response_with_goals):
        """Test food parsing includes goal-based scoring when user has goals."""
        from services.gemini_service import GeminiService

        # Mock Gemini response
        mock_generate.return_value = _gemini_response(mock_gemini_response_with_goals)

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
    @patch('services.gemini.nutrition.gemini_generate_with_retry', new_callable=AsyncMock)
    async def test_parse_food_without_user_goals(self, mock_generate, mock_gemini_response_without_goals):
        """Test food parsing returns basic response when user has no goals."""
        from services.gemini_service import GeminiService

        mock_generate.return_value = _gemini_response(mock_gemini_response_without_goals)

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
    @patch('services.gemini.nutrition.gemini_generate_with_retry', new_callable=AsyncMock)
    async def test_parse_food_with_empty_goals(self, mock_generate, mock_gemini_response_without_goals):
        """Test food parsing with empty goals list behaves like no goals."""
        from services.gemini_service import GeminiService

        mock_generate.return_value = _gemini_response(mock_gemini_response_without_goals)

        service = GeminiService()
        result = await service.parse_food_description(
            description="grilled chicken breast",
            user_goals=[],  # Empty list
            nutrition_targets={}  # Empty dict
        )

        assert result is not None
        assert "food_items" in result


def _mock_db(user_row: dict) -> MagicMock:
    """Supabase-DB stub whose `get_user` returns `user_row`.

    `/log-text` reads the user through
    `db.enrich_user_with_nutrition_targets(db.get_user(id))` — the enrichment
    step (which fills in computed targets) was added after these tests were
    written. A bare MagicMock returns a MagicMock from it, so `user.get("goals")`
    yielded a MagicMock and the goals never reached the analyzer. Emulate it as
    an identity pass-through over the stub row.
    """
    db = MagicMock()
    db.get_user.return_value = user_row
    db.enrich_user_with_nutrition_targets.side_effect = lambda u: u
    db.create_food_log.return_value = {"id": "log-123", "logged_at": "2026-07-13T12:00:00Z"}
    return db


@pytest.fixture
def no_external_calls():
    """Stub /log-text collaborators that would otherwise hit the network.

    None of these are the behavior under test in this module (goal + RAG context
    plumbing); left live they make a real Gemini call (hydration detection) and
    real Supabase reads (calorie bias, per-user food overrides).
    """
    with patch(
        'services.food_analysis.hydration_split.detect_hydration_in_text',
        new=AsyncMock(return_value=None),
    ), patch(
        'api.v1.nutrition.food_logging.get_user_calorie_bias',
        new=AsyncMock(return_value=0),
    ), patch(
        'services.food_override_service.apply_user_food_overrides',
        side_effect=lambda db, user_id, items: (items, {}, 0),
    ):
        yield


class TestLogTextEndpoint:
    """Tests for the /log-text API endpoint.

    ANALYZER SEAM MOVED: /log-text no longer calls `GeminiService()` directly —
    it goes through `get_food_analysis_cache_service().analyze_food(...)`, which
    checks the saved-foods / overrides / common-foods / analysis-cache layers and
    only then falls through to `GeminiService.parse_food_description` with the
    SAME `user_goals` / `nutrition_targets` / `rag_context` arguments. So
    `patch('api.v1.nutrition.nutrition.GeminiService')` blew up with
    AttributeError (nutrition is a package now; the symbol lives in
    `api.v1.nutrition.food_logging`), and patching GeminiService at all would no
    longer intercept anything on this path.

    The tests below therefore assert the same guarantee — the endpoint must load
    the user's goals + targets and forward them to the food analyzer — against
    the current chokepoint.
    """

    @patch('api.v1.nutrition.food_logging.get_supabase_db')
    @patch('api.v1.nutrition.food_logging.get_food_analysis_cache_service')
    def test_log_text_endpoint_exists(self, mock_analyzer_factory, mock_db, client, no_external_calls):
        """Test that the log-text endpoint is accessible.

        Stubbed like the tests below: now that the auth dependency is satisfied,
        the request runs the handler for real — un-stubbed it would fire a live
        Gemini food analysis and attempt a food_logs insert for a nonexistent
        user on every test run.
        """
        mock_db.return_value = _mock_db({"id": TEST_USER_ID, "goals": "[]"})
        mock_analyzer = MagicMock()
        mock_analyzer.analyze_food = AsyncMock(return_value={
            "food_items": [{"name": "Eggs", "calories": 180, "protein_g": 12, "carbs_g": 1, "fat_g": 12}],
            "total_calories": 180,
            "protein_g": 12.0,
            "carbs_g": 1.0,
            "fat_g": 12.0,
            "fiber_g": 0.0,
        })
        mock_analyzer_factory.return_value = mock_analyzer

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

    @patch('api.v1.nutrition.food_logging.get_supabase_db')
    @patch('api.v1.nutrition.food_logging.get_food_analysis_cache_service')
    def test_log_text_with_existing_user_goals(self, mock_analyzer_factory, mock_db, client, no_external_calls):
        """Test log-text uses user goals for scoring when available."""
        # Mock database
        mock_db.return_value = _mock_db({
            "id": "test-user-123",
            "goals": '["build_muscle", "improve_endurance"]',
            "daily_calorie_target": 2500,
            "daily_protein_target_g": 150,
        })

        # Mock the food analyzer (cache service → Gemini)
        mock_analyzer = MagicMock()
        mock_analyzer.analyze_food = AsyncMock(return_value={
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
        mock_analyzer_factory.return_value = mock_analyzer

        response = client.post(
            "/api/v1/nutrition/log-text",
            json={
                "user_id": "test-user-123",
                "description": "2 eggs",
                "meal_type": "breakfast"
            }
        )

        # Verify the analyzer was called with the user's goals + targets
        mock_analyzer.analyze_food.assert_called_once()
        call_kwargs = mock_analyzer.analyze_food.call_args[1]
        assert call_kwargs["user_goals"] == ["build_muscle", "improve_endurance"]
        assert call_kwargs["nutrition_targets"]["daily_protein_target_g"] == 150

    @patch('api.v1.nutrition.food_logging.get_supabase_db')
    @patch('api.v1.nutrition.food_logging.get_food_analysis_cache_service')
    def test_log_text_new_user_no_goals(self, mock_analyzer_factory, mock_db, client, no_external_calls):
        """Test log-text works for new user without goals."""
        # Mock database - new user with no goals
        mock_db.return_value = _mock_db({
            "id": "new-user",
            "goals": "[]",  # Empty goals
            "daily_calorie_target": None,
            "daily_protein_target_g": None,
        })

        # Mock the food analyzer - simpler response
        mock_analyzer = MagicMock()
        mock_analyzer.analyze_food = AsyncMock(return_value={
            "food_items": [{"name": "Toast", "calories": 75, "protein_g": 2, "carbs_g": 14, "fat_g": 1}],
            "total_calories": 75,
            "protein_g": 2.0,
            "carbs_g": 14.0,
            "fat_g": 1.0,
            "fiber_g": 1.0,
            "health_score": 5,
            "ai_suggestion": "Consider adding protein to your breakfast."
        })
        mock_analyzer_factory.return_value = mock_analyzer

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
        # A goal-less user still gets analyzed — just with no goal context.
        mock_analyzer.analyze_food.assert_called_once()
        assert mock_analyzer.analyze_food.call_args[1]["user_goals"] == []


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
        """High protein foods should score high for muscle building goal.

        USED TO ASSERT the literal prompt phrase "High score for high protein".
        That wording was retired when the scoring rubric was rewritten into the
        current compact, numeric form ("- Muscle goals: Need >25g protein for
        score >7") — the rubric got STRICTER, not weaker, so the old string match
        was asserting dead prose.

        The guarantee this protects is unchanged and is what is asserted now: the
        food-scoring prompt must carry an explicit muscle-goal rule that keys the
        score off protein, so a high-protein meal cannot be scored well for a
        muscle-building user by accident. Asserted structurally (a rule line that
        mentions BOTH the muscle goal and a protein threshold) rather than by
        exact sentence, so a future rewording of the same rule doesn't false-alarm
        while a DELETION of the rule still fails the test.
        """
        # This is a logic test - we verify the prompt includes correct criteria
        from services.gemini_service import GeminiService
        import inspect
        import re

        source = inspect.getsource(GeminiService.parse_food_description)

        # Verify scoring criteria mentions muscle building + protein
        assert "build_muscle" in source

        muscle_protein_rules = [
            line for line in source.splitlines()
            if "muscle" in line.lower() and "protein" in line.lower()
        ]
        assert muscle_protein_rules, (
            "Scoring prompt has no rule tying muscle goals to protein"
        )
        assert any(
            re.search(r"(>\s*\d+\s*g|\d+\s*g\+?|high)\s*protein", line, re.IGNORECASE)
            or re.search(r"protein\s*(>|for score)", line, re.IGNORECASE)
            for line in muscle_protein_rules
        ), f"Muscle-goal rule does not key the score off protein: {muscle_protein_rules}"

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
        """Test get_context_for_goals returns formatted string.

        CALL FIXED (not the assertion): the service queries ChromaDB through the
        ASYNC client API — `await self.collection.aquery(...)` — so stubbing the
        old synchronous `collection.query` left an un-awaitable MagicMock and the
        test died with "object MagicMock can't be used in 'await' expression"
        before reaching its assertion. The stub now mirrors the async API.

        The goal-cache collaborator (NutritionDB) is injected as a stub too: on a
        cache miss the service WRITES the retrieved docs back into the shared
        `rag_context` cache, so an un-stubbed nutrition_db would push this test's
        fake documents into the real cache and serve them to live users with the
        build_muscle goal.
        """
        from services.nutrition_rag_service import NutritionRAGService

        # Mock ChromaDB collection (async chroma client: acount/aquery)
        mock_collection = MagicMock()
        mock_collection.count.return_value = 10
        mock_collection.aquery = AsyncMock(return_value={
            "documents": [["[PROTEIN] High protein content...", "[TIPS] Eat slowly..."]],
            "metadatas": [[{"goals": "build_muscle", "category": "protein"}, {"goals": "general", "category": "tips"}]],
            "distances": [[0.1, 0.2]]
        })
        mock_chroma.return_value.get_or_create_collection.return_value = mock_collection

        # Mock Gemini embedding
        mock_gemini = MagicMock()
        mock_gemini.get_embedding_async = AsyncMock(return_value=[0.1] * 768)
        mock_gemini_class.return_value = mock_gemini

        # Stub the goal-context cache (Supabase) — forced miss, writes swallowed.
        mock_nutrition_db = MagicMock()
        mock_nutrition_db.get_cached_rag_context.return_value = None

        service = NutritionRAGService(mock_gemini, mock_nutrition_db)
        context = await service.get_context_for_goals(
            food_description="grilled chicken",
            user_goals=["build_muscle"],
            n_results=3
        )

        # Should return a string
        assert isinstance(context, str)
        # ...built from the retrieved docs, tagged with their category
        assert "[PROTEIN] High protein content..." in context
        mock_collection.aquery.assert_awaited_once()

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
    """Tests for /log-text endpoint with RAG integration.

    Same seam correction as TestLogTextEndpoint: the RAG context now reaches
    Gemini via `cache_service.analyze_food(rag_context=...)` (which passes it
    straight through to `parse_food_description`), so the "Gemini got the RAG
    context" assertions are made against the analyzer call. The guarantees under
    test are unchanged: RAG is consulted IFF the user has goals, it is asked
    about the food the user actually typed, and its output reaches the analyzer.
    """

    @patch('api.v1.nutrition.food_logging.get_supabase_db')
    @patch('api.v1.nutrition.food_logging.get_nutrition_rag_service')
    @patch('api.v1.nutrition.food_logging.get_food_analysis_cache_service')
    def test_log_text_calls_rag_service_when_goals_exist(self, mock_analyzer_factory, mock_rag, mock_db, client, no_external_calls):
        """Test that /log-text calls RAG service when user has goals."""
        # Mock database with user having goals
        mock_db.return_value = _mock_db({
            "id": "test-user",
            "goals": '["build_muscle"]',
            "daily_calorie_target": 2500,
        })

        # Mock RAG service
        mock_rag_instance = MagicMock()
        mock_rag_instance.get_context_for_goals = AsyncMock(return_value="[PROTEIN] High protein is good...")
        mock_rag.return_value = mock_rag_instance

        # Mock the food analyzer (cache service → Gemini)
        mock_analyzer = MagicMock()
        mock_analyzer.analyze_food = AsyncMock(return_value={
            "food_items": [{"name": "Chicken", "calories": 200, "protein_g": 30, "carbs_g": 0, "fat_g": 5}],
            "total_calories": 200,
            "protein_g": 30.0,
            "carbs_g": 0.0,
            "fat_g": 5.0,
            "fiber_g": 0.0,
            "overall_meal_score": 9,
            "health_score": 8,
        })
        mock_analyzer_factory.return_value = mock_analyzer

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

        # Verify the analyzer (→ Gemini) was called with the RAG context
        analyzer_call = mock_analyzer.analyze_food.call_args[1]
        assert analyzer_call["rag_context"] == "[PROTEIN] High protein is good..."

    @patch('api.v1.nutrition.food_logging.get_supabase_db')
    @patch('api.v1.nutrition.food_logging.get_nutrition_rag_service')
    @patch('api.v1.nutrition.food_logging.get_food_analysis_cache_service')
    def test_log_text_skips_rag_when_no_goals(self, mock_analyzer_factory, mock_rag, mock_db, client, no_external_calls):
        """Test that /log-text skips RAG service when user has no goals."""
        # Mock database with user having no goals
        mock_db.return_value = _mock_db({
            "id": "new-user",
            "goals": "[]",
        })

        # Mock RAG service
        mock_rag_instance = MagicMock()
        mock_rag_instance.get_context_for_goals = AsyncMock(return_value="")
        mock_rag.return_value = mock_rag_instance

        # Mock the food analyzer
        mock_analyzer = MagicMock()
        mock_analyzer.analyze_food = AsyncMock(return_value={
            "food_items": [{"name": "Toast", "calories": 75, "protein_g": 2, "carbs_g": 14, "fat_g": 1}],
            "total_calories": 75,
            "protein_g": 2.0,
            "carbs_g": 14.0,
            "fat_g": 1.0,
            "fiber_g": 1.0,
        })
        mock_analyzer_factory.return_value = mock_analyzer

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

        # The analyzer (→ Gemini) should be called with rag_context=None
        analyzer_call = mock_analyzer.analyze_food.call_args[1]
        assert analyzer_call["rag_context"] is None
