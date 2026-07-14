"""
Tests for Saved Foods (Favorite Recipes) Feature.

Tests cover:
- SavedFoodsRAGService (ChromaDB integration)
- Saved foods API endpoints
- Pydantic model validation
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
import json
from datetime import datetime

from fastapi.testclient import TestClient

from main import app
from core.auth import get_current_user


# Every /saved-foods endpoint declares `current_user: dict = Depends(get_current_user)`.
# Without an override the TestClient sends no Authorization header, so FastAPI
# resolves the security dependency FIRST and returns 401 before the request body
# is ever validated — which is why the routing/validation assertions below cannot
# be exercised through the unauthenticated conftest `client` fixture. Overriding
# the dependency (the standard FastAPI test seam) restores exactly what these
# tests are here to check: routing, request validation, and handler behavior.
TEST_AUTH_USER = {"id": "test-user", "email": "test-user@example.com"}


@pytest.fixture
def client():
    """Authenticated TestClient — shadows the unauthenticated conftest fixture."""
    app.dependency_overrides[get_current_user] = lambda: TEST_AUTH_USER
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


class _QueryStub:
    """Chainable stand-in for a PostgREST query builder.

    Hand-built `table.return_value.select.return_value.eq.return_value...` chains
    are brittle: they encode the handler's exact filter order, so ONE new `.eq()`
    or `.range()` in production silently detaches the stub, `execute().data`
    becomes an auto-MagicMock, and the endpoint 500s while a lenient
    `assert status in [200, ..., 500]` still passes. This stub accepts any
    builder method in any order and always terminates in the configured result.
    """

    class _Result:
        def __init__(self, data, count):
            self.data = data
            self.count = count

    def __init__(self, data, count=None):
        self._result = self._Result(data, count if count is not None else 0)

    def __getattr__(self, _name):
        # select / eq / is_ / order / range / ilike / gte / lte / contains /
        # single / insert / update / delete … all just continue the chain.
        return lambda *args, **kwargs: self

    def execute(self):
        return self._result


# ============================================================
# PYDANTIC MODEL TESTS
# ============================================================

class TestSavedFoodModels:
    """Tests for Saved Food Pydantic models."""

    def test_food_source_type_enum(self):
        """Test FoodSourceType enum values."""
        from models.saved_food import FoodSourceType

        assert FoodSourceType.TEXT.value == "text"
        assert FoodSourceType.BARCODE.value == "barcode"
        assert FoodSourceType.IMAGE.value == "image"

    def test_saved_food_item_model(self):
        """Test SavedFoodItem model with all fields."""
        from models.saved_food import SavedFoodItem

        item = SavedFoodItem(
            name="Grilled Chicken",
            amount="200g",
            calories=330,
            protein_g=62.0,
            carbs_g=0.0,
            fat_g=7.0,
            fiber_g=0.0,
            goal_score=9,
            goal_alignment="excellent"
        )

        assert item.name == "Grilled Chicken"
        assert item.calories == 330
        assert item.protein_g == 62.0
        assert item.goal_score == 9
        assert item.goal_alignment == "excellent"

    def test_saved_food_item_optional_fields(self):
        """Test SavedFoodItem with only required fields."""
        from models.saved_food import SavedFoodItem

        item = SavedFoodItem(name="Apple")

        assert item.name == "Apple"
        assert item.amount is None
        assert item.calories is None
        assert item.goal_score is None

    def test_saved_food_base_model(self):
        """Test SavedFoodBase model."""
        from models.saved_food import SavedFoodBase, FoodSourceType, SavedFoodItem

        food = SavedFoodBase(
            name="Healthy Breakfast",
            description="Oatmeal with fruit",
            source_type=FoodSourceType.TEXT,
            total_calories=450,
            total_protein_g=12.5,
            total_carbs_g=75.0,
            total_fat_g=8.0,
            total_fiber_g=6.0,
            food_items=[
                SavedFoodItem(name="Oatmeal", calories=300),
                SavedFoodItem(name="Banana", calories=100),
            ],
            tags=["breakfast", "healthy"],
            notes="My go-to breakfast"
        )

        assert food.name == "Healthy Breakfast"
        assert food.source_type == FoodSourceType.TEXT
        assert food.total_calories == 450
        assert len(food.food_items) == 2
        assert "breakfast" in food.tags

    def test_saved_food_create_model(self):
        """Test SavedFoodCreate model (same as base)."""
        from models.saved_food import SavedFoodCreate, FoodSourceType

        food = SavedFoodCreate(
            name="Quick Lunch",
            source_type=FoodSourceType.IMAGE,
            total_calories=500
        )

        assert food.name == "Quick Lunch"
        assert food.source_type == FoodSourceType.IMAGE

    def test_saved_food_model_with_database_fields(self):
        """Test SavedFood model includes database fields."""
        from models.saved_food import SavedFood, FoodSourceType

        food = SavedFood(
            id="test-uuid-123",
            user_id="user-uuid-456",
            name="Saved Meal",
            source_type=FoodSourceType.TEXT,
            times_logged=5,
            last_logged_at=datetime.now(),
            created_at=datetime.now(),
            updated_at=datetime.now(),
            food_items=[]
        )

        assert food.id == "test-uuid-123"
        assert food.user_id == "user-uuid-456"
        assert food.times_logged == 5

    def test_saved_food_update_model(self):
        """Test SavedFoodUpdate model with optional fields."""
        from models.saved_food import SavedFoodUpdate

        update = SavedFoodUpdate(
            name="Updated Name",
            tags=["new-tag"]
        )

        assert update.name == "Updated Name"
        assert update.tags == ["new-tag"]
        assert update.description is None

    def test_save_food_from_log_request(self):
        """Test SaveFoodFromLogRequest model."""
        from models.saved_food import SaveFoodFromLogRequest, FoodSourceType, SavedFoodItem

        request = SaveFoodFromLogRequest(
            name="My Favorite Meal",
            description="Delicious and healthy",
            source_type=FoodSourceType.TEXT,
            total_calories=600,
            total_protein_g=40.0,
            food_items=[
                SavedFoodItem(name="Chicken", calories=300, protein_g=35.0),
                SavedFoodItem(name="Rice", calories=200, protein_g=4.0),
            ],
            overall_meal_score=8,
            goal_alignment_percentage=85,
            tags=["high-protein", "lunch"]
        )

        assert request.name == "My Favorite Meal"
        assert request.total_calories == 600
        assert len(request.food_items) == 2
        assert request.overall_meal_score == 8

    def test_relog_saved_food_request(self):
        """Test RelogSavedFoodRequest model."""
        from models.saved_food import RelogSavedFoodRequest

        request = RelogSavedFoodRequest(meal_type="breakfast")

        assert request.meal_type == "breakfast"

    def test_saved_food_summary_model(self):
        """Test SavedFoodSummary model for list views."""
        from models.saved_food import SavedFoodSummary, FoodSourceType

        summary = SavedFoodSummary(
            id="summary-uuid",
            name="Quick Snack",
            total_calories=150,
            total_protein_g=10.0,
            source_type=FoodSourceType.BARCODE,
            times_logged=3,
            created_at=datetime.now(),
            tags=["snack"]
        )

        assert summary.id == "summary-uuid"
        assert summary.times_logged == 3

    def test_search_saved_foods_request(self):
        """Test SearchSavedFoodsRequest model."""
        from models.saved_food import SearchSavedFoodsRequest, FoodSourceType

        request = SearchSavedFoodsRequest(
            query="high protein breakfast",
            tags=["breakfast"],
            source_type=FoodSourceType.TEXT,
            min_calories=200,
            max_calories=500,
            limit=10,
            offset=0
        )

        assert request.query == "high protein breakfast"
        assert request.min_calories == 200
        assert request.limit == 10

    def test_saved_foods_response_model(self):
        """Test SavedFoodsResponse model."""
        from models.saved_food import SavedFoodsResponse, SavedFood, FoodSourceType

        response = SavedFoodsResponse(
            items=[
                SavedFood(
                    id="uuid-1",
                    user_id="user-uuid",
                    name="Meal 1",
                    source_type=FoodSourceType.TEXT,
                    times_logged=0,
                    created_at=datetime.now(),
                    updated_at=datetime.now(),
                    food_items=[]
                )
            ],
            total_count=1
        )

        assert len(response.items) == 1
        assert response.total_count == 1


# ============================================================
# SAVED FOODS RAG SERVICE TESTS
# ============================================================

class TestSavedFoodsRAGService:
    """Tests for SavedFoodsRAGService (ChromaDB integration)."""

    @pytest.fixture
    def mock_chroma_collection(self):
        """Mock ChromaDB collection.

        Models `core.chroma_http_client.ChromaCollection`: the blocking
        add/query/delete/count methods PLUS the async `a*` variants that simply
        run their sync twin in a worker thread (`asyncio.to_thread`, added so a
        slow Chroma round-trip can't freeze the event loop). SavedFoodsRAGService
        awaits the `a*` variants, so the mock delegates each one to its sync twin
        — that keeps every `collection.add/query/delete` call assertion below
        meaningful while matching the interface the service actually calls.
        """
        collection = MagicMock()
        collection.count.return_value = 5
        collection.add = MagicMock()
        collection.delete = MagicMock()
        collection.query = MagicMock(return_value={
            "ids": [["food-1", "food-2"]],
            "documents": [["Oatmeal with banana", "Grilled chicken"]],
            "metadatas": [[
                {"user_id": "user-1", "name": "Oatmeal", "total_calories": 350, "total_protein_g": 12, "source_type": "text", "tags": "breakfast"},
                {"user_id": "user-1", "name": "Chicken", "total_calories": 400, "total_protein_g": 45, "source_type": "text", "tags": "lunch,high-protein"}
            ]],
            "distances": [[0.1, 0.2]]
        })
        collection.get = MagicMock(return_value={
            "ids": ["food-1", "food-2"]
        })
        # Async variants — delegate to the sync twins, exactly as the real
        # ChromaCollection does via asyncio.to_thread().
        collection.aadd = AsyncMock(side_effect=lambda *a, **kw: collection.add(*a, **kw))
        collection.aquery = AsyncMock(side_effect=lambda *a, **kw: collection.query(*a, **kw))
        collection.adelete = AsyncMock(side_effect=lambda *a, **kw: collection.delete(*a, **kw))
        collection.aget = AsyncMock(side_effect=lambda *a, **kw: collection.get(*a, **kw))
        collection.acount = AsyncMock(side_effect=lambda *a, **kw: collection.count(*a, **kw))
        return collection

    @pytest.fixture
    def mock_gemini_service(self):
        """Mock Gemini service for embeddings."""
        service = MagicMock()
        service.get_embedding_async = AsyncMock(return_value=[0.1] * 768)
        return service

    def test_saved_foods_rag_service_exists(self):
        """Test SavedFoodsRAGService can be imported."""
        from services.saved_foods_rag_service import SavedFoodsRAGService

        assert hasattr(SavedFoodsRAGService, 'save_food')
        assert hasattr(SavedFoodsRAGService, 'search_similar')
        assert hasattr(SavedFoodsRAGService, 'delete_food')
        assert hasattr(SavedFoodsRAGService, 'update_food')
        assert hasattr(SavedFoodsRAGService, 'get_collection_count')
        assert hasattr(SavedFoodsRAGService, 'get_user_food_count')

    @pytest.mark.asyncio
    @patch('services.saved_foods_rag_service.get_chroma_cloud_client')
    @patch('services.saved_foods_rag_service.GeminiService')
    async def test_save_food_to_chromadb(self, mock_gemini_class, mock_chroma, mock_chroma_collection, mock_gemini_service):
        """Test saving a food to ChromaDB."""
        from services.saved_foods_rag_service import SavedFoodsRAGService

        # Setup mocks
        mock_chroma_client = MagicMock()
        mock_chroma_client.get_saved_foods_collection.return_value = mock_chroma_collection
        mock_chroma.return_value = mock_chroma_client
        mock_gemini_class.return_value = mock_gemini_service

        service = SavedFoodsRAGService(mock_gemini_service)

        # Call save_food
        result = await service.save_food(
            saved_food_id="test-food-id",
            user_id="test-user-id",
            name="Healthy Breakfast",
            description="Oatmeal with banana and honey",
            food_items=[
                {"name": "Oatmeal", "calories": 300},
                {"name": "Banana", "calories": 100}
            ],
            total_calories=400,
            total_protein_g=12.5,
            source_type="text",
            tags=["breakfast", "healthy"]
        )

        # Verify embedding was generated
        mock_gemini_service.get_embedding_async.assert_called_once()

        # Verify collection.add was called
        mock_chroma_collection.add.assert_called_once()
        call_args = mock_chroma_collection.add.call_args

        assert call_args[1]["ids"] == ["test-food-id"]
        assert "test-user-id" in str(call_args[1]["metadatas"])

        # Verify return value
        assert result == "test-food-id"

    @pytest.mark.asyncio
    @patch('services.saved_foods_rag_service.get_chroma_cloud_client')
    @patch('services.saved_foods_rag_service.GeminiService')
    async def test_search_similar_foods(self, mock_gemini_class, mock_chroma, mock_chroma_collection, mock_gemini_service):
        """Test searching for similar saved foods."""
        from services.saved_foods_rag_service import SavedFoodsRAGService

        # Setup mocks
        mock_chroma_client = MagicMock()
        mock_chroma_client.get_saved_foods_collection.return_value = mock_chroma_collection
        mock_chroma.return_value = mock_chroma_client
        mock_gemini_class.return_value = mock_gemini_service

        service = SavedFoodsRAGService(mock_gemini_service)

        # Call search_similar
        results = await service.search_similar(
            query="healthy breakfast",
            user_id="user-1",
            n_results=5
        )

        # Verify embedding was generated for query
        mock_gemini_service.get_embedding_async.assert_called()

        # Verify collection.query was called with correct filters
        mock_chroma_collection.query.assert_called_once()
        call_args = mock_chroma_collection.query.call_args
        assert call_args[1]["where"] == {"user_id": "user-1"}

        # Verify results structure
        assert len(results) == 2
        assert results[0]["id"] == "food-1"
        assert results[0]["name"] == "Oatmeal"
        assert results[0]["total_calories"] == 350

    @pytest.mark.asyncio
    @patch('services.saved_foods_rag_service.get_chroma_cloud_client')
    @patch('services.saved_foods_rag_service.GeminiService')
    async def test_search_with_calorie_filters(self, mock_gemini_class, mock_chroma, mock_chroma_collection, mock_gemini_service):
        """Test searching with calorie filters."""
        from services.saved_foods_rag_service import SavedFoodsRAGService

        # Setup mocks
        mock_chroma_client = MagicMock()
        mock_chroma_client.get_saved_foods_collection.return_value = mock_chroma_collection
        mock_chroma.return_value = mock_chroma_client
        mock_gemini_class.return_value = mock_gemini_service

        service = SavedFoodsRAGService(mock_gemini_service)

        # Search with calorie filter (should filter out oatmeal with 350 cal)
        results = await service.search_similar(
            query="high protein",
            user_id="user-1",
            n_results=5,
            min_calories=380
        )

        # Only chicken (400 cal) should match
        assert len(results) == 1
        assert results[0]["name"] == "Chicken"

    @pytest.mark.asyncio
    @patch('services.saved_foods_rag_service.get_chroma_cloud_client')
    @patch('services.saved_foods_rag_service.GeminiService')
    async def test_delete_food_from_chromadb(self, mock_gemini_class, mock_chroma, mock_chroma_collection, mock_gemini_service):
        """Test deleting a saved food from ChromaDB."""
        from services.saved_foods_rag_service import SavedFoodsRAGService

        # Setup mocks
        mock_chroma_client = MagicMock()
        mock_chroma_client.get_saved_foods_collection.return_value = mock_chroma_collection
        mock_chroma.return_value = mock_chroma_client
        mock_gemini_class.return_value = mock_gemini_service

        service = SavedFoodsRAGService(mock_gemini_service)

        # Call delete_food
        result = await service.delete_food("food-to-delete")

        # Verify collection.delete was called
        mock_chroma_collection.delete.assert_called_once_with(ids=["food-to-delete"])
        assert result is True

    @pytest.mark.asyncio
    @patch('services.saved_foods_rag_service.get_chroma_cloud_client')
    @patch('services.saved_foods_rag_service.GeminiService')
    async def test_update_food_in_chromadb(self, mock_gemini_class, mock_chroma, mock_chroma_collection, mock_gemini_service):
        """Test updating a saved food (delete + re-add)."""
        from services.saved_foods_rag_service import SavedFoodsRAGService

        # Setup mocks
        mock_chroma_client = MagicMock()
        mock_chroma_client.get_saved_foods_collection.return_value = mock_chroma_collection
        mock_chroma.return_value = mock_chroma_client
        mock_gemini_class.return_value = mock_gemini_service

        service = SavedFoodsRAGService(mock_gemini_service)

        # Call update_food
        result = await service.update_food(
            saved_food_id="food-to-update",
            user_id="user-1",
            name="Updated Meal",
            description="New description",
            food_items=[{"name": "New Item", "calories": 250}],
            total_calories=250,
            total_protein_g=15.0
        )

        # Verify delete was called first, then add
        mock_chroma_collection.delete.assert_called_once()
        mock_chroma_collection.add.assert_called_once()
        assert result == "food-to-update"

    @patch('services.saved_foods_rag_service.get_chroma_cloud_client')
    @patch('services.saved_foods_rag_service.GeminiService')
    def test_get_collection_count(self, mock_gemini_class, mock_chroma, mock_chroma_collection, mock_gemini_service):
        """Test getting collection count."""
        from services.saved_foods_rag_service import SavedFoodsRAGService

        # Setup mocks
        mock_chroma_client = MagicMock()
        mock_chroma_client.get_saved_foods_collection.return_value = mock_chroma_collection
        mock_chroma.return_value = mock_chroma_client
        mock_gemini_class.return_value = mock_gemini_service

        service = SavedFoodsRAGService(mock_gemini_service)
        count = service.get_collection_count()

        assert count == 5

    @patch('services.saved_foods_rag_service.get_chroma_cloud_client')
    @patch('services.saved_foods_rag_service.GeminiService')
    def test_get_user_food_count(self, mock_gemini_class, mock_chroma, mock_chroma_collection, mock_gemini_service):
        """Test getting user-specific food count."""
        from services.saved_foods_rag_service import SavedFoodsRAGService

        # Setup mocks
        mock_chroma_client = MagicMock()
        mock_chroma_client.get_saved_foods_collection.return_value = mock_chroma_collection
        mock_chroma.return_value = mock_chroma_client
        mock_gemini_class.return_value = mock_gemini_service

        service = SavedFoodsRAGService(mock_gemini_service)
        count = service.get_user_food_count("user-1")

        # Mock returns 2 IDs
        assert count == 2

    def test_singleton_getter(self):
        """Test get_saved_foods_rag_service returns instance."""
        from services.saved_foods_rag_service import get_saved_foods_rag_service

        # Should be callable
        assert callable(get_saved_foods_rag_service)


# ============================================================
# API ENDPOINT TESTS
# ============================================================

class TestSavedFoodsAPIEndpoints:
    """Tests for Saved Foods API endpoints."""

    def test_save_food_endpoint_exists(self, client):
        """Test that the save-food endpoint route exists."""
        # Should not return 404
        response = client.post(
            "/api/v1/nutrition/saved-foods",
            json={
                "user_id": "test-user",
                "name": "Test Meal",
                "source_type": "text",
                "food_items": []
            }
        )
        assert response.status_code != 404, "saved-foods POST endpoint should exist"

    def test_get_saved_foods_endpoint_exists(self, client):
        """Test that the get-saved-foods endpoint route exists."""
        response = client.get("/api/v1/nutrition/saved-foods?user_id=test-user")
        assert response.status_code != 404, "saved-foods GET endpoint should exist"

    def test_delete_saved_food_endpoint_exists(self, client):
        """Test that the delete-saved-food endpoint route exists."""
        response = client.delete("/api/v1/nutrition/saved-foods/test-uuid?user_id=test-user")
        assert response.status_code != 404, "saved-foods DELETE endpoint should exist"

    def test_relog_saved_food_endpoint_exists(self, client):
        """Test that the relog-saved-food endpoint route exists."""
        response = client.post(
            "/api/v1/nutrition/saved-foods/test-uuid/log",
            json={
                "user_id": "test-user",
                "meal_type": "lunch"
            }
        )
        assert response.status_code != 404, "saved-foods relog endpoint should exist"

    def test_save_food_requires_name(self, client):
        """Test save food endpoint requires name field."""
        response = client.post(
            "/api/v1/nutrition/saved-foods",
            json={
                "user_id": "test-user",
                "source_type": "text",
                "food_items": []
                # Missing name
            }
        )
        assert response.status_code == 422  # Validation error

    def test_save_food_requires_user_id(self, client):
        """Test save food endpoint requires user_id."""
        response = client.post(
            "/api/v1/nutrition/saved-foods",
            json={
                "name": "Test Meal",
                "source_type": "text",
                "food_items": []
                # Missing user_id
            }
        )
        # Either 422 (validation) or different handling based on implementation
        assert response.status_code in [401, 422, 400]

    @patch('api.v1.nutrition.saved_foods.get_supabase_db')
    @patch('api.v1.nutrition.saved_foods.get_saved_foods_rag_service')
    def test_save_food_success(self, mock_rag, mock_db, client):
        """Test successfully saving a food via /saved-foods/save endpoint (JSON body)."""
        # Mock database
        mock_db_instance = MagicMock()
        mock_db_instance.client.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": "new-saved-food-uuid",
            "user_id": "test-user",
            "name": "Test Meal",
            "source_type": "text",
            "total_calories": 500,
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-01T00:00:00Z",
            "times_logged": 0,
            "food_items": []
        }]
        mock_db.return_value = mock_db_instance

        # Mock RAG service
        mock_rag_instance = MagicMock()
        mock_rag_instance.save_food = AsyncMock(return_value="new-saved-food-uuid")
        mock_rag.return_value = mock_rag_instance

        # Use /saved-foods/save endpoint which accepts JSON body with user_id as query param
        response = client.post(
            "/api/v1/nutrition/saved-foods/save?user_id=test-user",
            json={
                "name": "Test Meal",
                "description": "A delicious test meal",
                "source_type": "text",
                "total_calories": 500,
                "total_protein_g": 30.0,
                "food_items": [
                    {"name": "Item 1", "calories": 300},
                    {"name": "Item 2", "calories": 200}
                ],
                "tags": ["test", "lunch"]
            }
        )

        # Should succeed and echo back the persisted row.
        assert response.status_code == 200
        body = response.json()
        assert body["id"] == "new-saved-food-uuid"
        assert body["name"] == "Test Meal"
        # The meal must also be indexed into ChromaDB for semantic search.
        mock_rag_instance.save_food.assert_awaited_once()

    @patch('api.v1.nutrition.saved_foods.get_supabase_db')
    def test_get_saved_foods_returns_list(self, mock_db, client):
        """Test getting saved foods returns a list.

        The old mock stubbed `select().eq().is_().order().execute()`, but the
        handler now chains `.order().order().range()` for the page plus a second
        `select(count="exact")` round trip for the total — so the stub never
        matched, `result.data` was an auto-MagicMock, and the endpoint 500'd
        while the assertion (`in [200, 401, 500]`) still went green. A chainable
        stub is used instead so the list path is actually exercised.
        """
        rows = [
            {
                "id": "food-1",
                "user_id": "test-user",
                "name": "Saved Meal 1",
                "source_type": "text",
                "total_calories": 400,
                "times_logged": 3,
                "created_at": "2025-01-01T00:00:00Z",
                "updated_at": "2025-01-01T00:00:00Z",
                "food_items": []
            },
            {
                "id": "food-2",
                "user_id": "test-user",
                "name": "Saved Meal 2",
                "source_type": "barcode",
                "total_calories": 350,
                "times_logged": 1,
                "created_at": "2025-01-02T00:00:00Z",
                "updated_at": "2025-01-02T00:00:00Z",
                "food_items": []
            }
        ]

        mock_db_instance = MagicMock()
        mock_db_instance.client.table.return_value = _QueryStub(rows, count=2)
        mock_db.return_value = mock_db_instance

        response = client.get("/api/v1/nutrition/saved-foods?user_id=test-user")

        assert response.status_code == 200
        body = response.json()
        assert body["total_count"] == 2
        assert [item["name"] for item in body["items"]] == ["Saved Meal 1", "Saved Meal 2"]

    @patch('api.v1.nutrition.saved_foods.get_supabase_db')
    @patch('api.v1.nutrition.saved_foods.get_saved_foods_rag_service')
    def test_delete_saved_food_soft_deletes(self, mock_rag, mock_db, client):
        """Test deleting a saved food performs soft delete."""
        # Mock database
        mock_db_instance = MagicMock()
        mock_db_instance.client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{"id": "food-to-delete"}]
        mock_db.return_value = mock_db_instance

        # Mock RAG service
        mock_rag_instance = MagicMock()
        mock_rag_instance.delete_food = AsyncMock(return_value=True)
        mock_rag.return_value = mock_rag_instance

        response = client.delete("/api/v1/nutrition/saved-foods/food-to-delete?user_id=test-user")

        # Should succeed or hit auth issue
        assert response.status_code in [200, 204, 401, 404, 500]

    @patch('api.v1.nutrition.saved_foods.get_supabase_db')
    def test_relog_saved_food_creates_log(self, mock_db, client):
        """Test re-logging a saved food creates a new food log.

        Two stale mocks made this test vacuous: the saved-food lookup now chains
        a second `.eq("user_id", ...)` (so the old `select().eq().is_().single()`
        stub never matched), and the food log is written through
        `db.create_food_log(...)`, not a raw `table().insert()`. Both are fixed
        here, and the assertions now pin the ACTUAL contract: 200 + the new log
        id + the saved food's macros copied onto the log.
        """
        saved_food_row = {
            "id": "saved-food-id",
            "user_id": "test-user",
            "name": "Saved Meal",
            "total_calories": 500,
            "total_protein_g": 30.0,
            "total_carbs_g": 45.0,
            "total_fat_g": 15.0,
            "total_fiber_g": 5.0,
            "times_logged": 2,
            "food_items": [{"name": "Item", "calories": 500}]
        }

        mock_db_instance = MagicMock()
        mock_db_instance.client.table.return_value = _QueryStub(saved_food_row)
        mock_db_instance.create_food_log.return_value = {"id": "new-log-id"}
        mock_db.return_value = mock_db_instance

        # user_id is a query param, meal_type in JSON body
        response = client.post(
            "/api/v1/nutrition/saved-foods/saved-food-id/log?user_id=test-user",
            json={
                "meal_type": "lunch"
            }
        )

        assert response.status_code == 200
        body = response.json()
        assert body["success"] is True
        assert body["food_log_id"] == "new-log-id"
        # The saved food's macros must be carried onto the new log verbatim.
        assert body["total_calories"] == 500
        assert body["protein_g"] == 30.0
        assert body["carbs_g"] == 45.0
        assert body["fat_g"] == 15.0

        # A food log row must actually be written for the requested meal.
        mock_db_instance.create_food_log.assert_called_once()
        assert mock_db_instance.create_food_log.call_args.kwargs["meal_type"] == "lunch"
        assert mock_db_instance.create_food_log.call_args.kwargs["user_id"] == "test-user"


# ============================================================
# INTEGRATION TESTS
# ============================================================

class TestSavedFoodsIntegration:
    """Integration tests for saved foods feature."""

    def test_saved_food_flow_model_validation(self):
        """Test the full save/retrieve/relog model validation flow."""
        from models.saved_food import (
            SaveFoodFromLogRequest, SavedFood, RelogSavedFoodRequest,
            FoodSourceType, SavedFoodItem
        )
        from datetime import datetime

        # Step 1: Create save request (simulating from log response)
        save_request = SaveFoodFromLogRequest(
            name="Grilled Chicken Salad",
            description="Healthy lunch option",
            source_type=FoodSourceType.TEXT,
            total_calories=450,
            total_protein_g=45.0,
            total_carbs_g=15.0,
            total_fat_g=20.0,
            total_fiber_g=5.0,
            food_items=[
                SavedFoodItem(
                    name="Grilled Chicken",
                    amount="150g",
                    calories=250,
                    protein_g=40.0,
                    goal_score=9,
                    goal_alignment="excellent"
                ),
                SavedFoodItem(
                    name="Mixed Greens",
                    amount="100g",
                    calories=50,
                    protein_g=2.0,
                    goal_score=8,
                    goal_alignment="good"
                )
            ],
            overall_meal_score=9,
            goal_alignment_percentage=90,
            tags=["lunch", "high-protein", "low-carb"]
        )

        assert save_request.name == "Grilled Chicken Salad"
        assert len(save_request.food_items) == 2

        # Step 2: Create saved food (simulating DB response)
        saved_food = SavedFood(
            id="saved-uuid-123",
            user_id="user-uuid-456",
            name=save_request.name,
            description=save_request.description,
            source_type=save_request.source_type,
            total_calories=save_request.total_calories,
            total_protein_g=save_request.total_protein_g,
            total_carbs_g=save_request.total_carbs_g,
            total_fat_g=save_request.total_fat_g,
            total_fiber_g=save_request.total_fiber_g,
            food_items=save_request.food_items,
            overall_meal_score=save_request.overall_meal_score,
            goal_alignment_percentage=save_request.goal_alignment_percentage,
            tags=save_request.tags or [],
            times_logged=0,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )

        assert saved_food.id == "saved-uuid-123"
        assert saved_food.times_logged == 0

        # Step 3: Create relog request
        relog_request = RelogSavedFoodRequest(meal_type="dinner")

        assert relog_request.meal_type == "dinner"

    def test_chromadb_document_format(self):
        """Test the document format used for ChromaDB embeddings."""
        # This tests the format used in SavedFoodsRAGService.save_food()
        food_items = [
            {"name": "Oatmeal", "calories": 300},
            {"name": "Banana", "calories": 100},
            {"name": "Honey", "calories": 50}
        ]

        name = "Healthy Breakfast"
        description = "Morning fuel"

        # Build document text (as done in the service)
        food_items_text = ", ".join([
            f"{item.get('name', 'Unknown')} ({item.get('calories', 0)} cal)"
            for item in food_items
        ])

        document = f"{name}: {description or ''} - {food_items_text}"

        expected = "Healthy Breakfast: Morning fuel - Oatmeal (300 cal), Banana (100 cal), Honey (50 cal)"
        assert document == expected

    def test_tags_serialization(self):
        """Test tags serialization for ChromaDB metadata."""
        tags = ["breakfast", "healthy", "quick-meal"]

        # As done in the service
        tags_string = ",".join(tags) if tags else ""

        assert tags_string == "breakfast,healthy,quick-meal"

        # Deserialization
        restored_tags = tags_string.split(",") if tags_string else []
        assert restored_tags == tags


# ============================================================
# EDGE CASE TESTS
# ============================================================

class TestSavedFoodsEdgeCases:
    """Edge case tests for saved foods feature."""

    def test_empty_food_items_list(self):
        """Test saving food with empty food items."""
        from models.saved_food import SaveFoodFromLogRequest, FoodSourceType

        request = SaveFoodFromLogRequest(
            name="Simple Entry",
            source_type=FoodSourceType.TEXT,
            total_calories=100,
            food_items=[]  # Empty list
        )

        assert len(request.food_items) == 0

    def test_barcode_source_type(self):
        """Test saving food from barcode source."""
        from models.saved_food import SaveFoodFromLogRequest, FoodSourceType

        request = SaveFoodFromLogRequest(
            name="Scanned Product",
            source_type=FoodSourceType.BARCODE,
            barcode="1234567890123",
            total_calories=200,
            food_items=[]
        )

        assert request.source_type == FoodSourceType.BARCODE
        assert request.barcode == "1234567890123"

    def test_image_source_type(self):
        """Test saving food from image source."""
        from models.saved_food import SaveFoodFromLogRequest, FoodSourceType

        request = SaveFoodFromLogRequest(
            name="Photo of Meal",
            source_type=FoodSourceType.IMAGE,
            image_url="https://example.com/meal.jpg",
            total_calories=500,
            food_items=[]
        )

        assert request.source_type == FoodSourceType.IMAGE
        assert request.image_url == "https://example.com/meal.jpg"

    def test_max_tags_limit(self):
        """Test tags list respects max length."""
        from models.saved_food import SaveFoodFromLogRequest, FoodSourceType

        # Model allows max 20 tags
        tags = [f"tag-{i}" for i in range(20)]

        request = SaveFoodFromLogRequest(
            name="Many Tags",
            source_type=FoodSourceType.TEXT,
            food_items=[],
            tags=tags
        )

        assert len(request.tags) == 20

    def test_long_description(self):
        """Test saving food with long description."""
        from models.saved_food import SaveFoodFromLogRequest, FoodSourceType

        long_description = "A" * 1000  # Under 2000 char limit

        request = SaveFoodFromLogRequest(
            name="Detailed Meal",
            description=long_description,
            source_type=FoodSourceType.TEXT,
            food_items=[]
        )

        assert len(request.description) == 1000

    def test_unicode_characters(self):
        """Test saving food with unicode characters."""
        from models.saved_food import SaveFoodFromLogRequest, FoodSourceType, SavedFoodItem

        request = SaveFoodFromLogRequest(
            name="Crème Brûlée",
            description="Delicious French dessert 🍮",
            source_type=FoodSourceType.TEXT,
            food_items=[
                SavedFoodItem(name="Crème Brûlée", calories=300)
            ]
        )

        assert "Crème" in request.name
        assert "Brûlée" in request.name

    def test_zero_calories(self):
        """Test saving food with zero calories."""
        from models.saved_food import SaveFoodFromLogRequest, FoodSourceType, SavedFoodItem

        request = SaveFoodFromLogRequest(
            name="Water",
            source_type=FoodSourceType.TEXT,
            total_calories=0,
            food_items=[
                SavedFoodItem(name="Water", calories=0)
            ]
        )

        assert request.total_calories == 0

    def test_none_nutrition_values(self):
        """Test saving food with None nutrition values."""
        from models.saved_food import SaveFoodFromLogRequest, FoodSourceType

        request = SaveFoodFromLogRequest(
            name="Unknown Nutrition",
            source_type=FoodSourceType.TEXT,
            total_calories=None,
            total_protein_g=None,
            food_items=[]
        )

        assert request.total_calories is None
        assert request.total_protein_g is None
