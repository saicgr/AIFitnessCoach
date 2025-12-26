"""
Tests for Recipe API endpoints.

Tests:
- Recipe CRUD operations
- Recipe ingredient management
- Recipe logging
- Model validation

Run with: pytest backend/tests/test_recipe_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime
import uuid


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_recipe_id():
    return str(uuid.uuid4())


@pytest.fixture
def sample_ingredient_data():
    return {
        "id": str(uuid.uuid4()),
        "recipe_id": "recipe-1",
        "ingredient_order": 0,
        "food_name": "Oats",
        "brand": None,
        "amount": 80.0,
        "unit": "g",
        "amount_grams": 80.0,
        "calories": 280.0,
        "protein_g": 10.0,
        "carbs_g": 50.0,
        "fat_g": 5.0,
        "fiber_g": 8.0,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


@pytest.fixture
def sample_recipe_data(sample_user_id):
    return {
        "id": "recipe-1",
        "user_id": sample_user_id,
        "name": "Oatmeal with Banana",
        "description": "Healthy breakfast",
        "servings": 2,
        "prep_time_minutes": 5,
        "cook_time_minutes": 10,
        "instructions": "Cook oats, add banana",
        "image_url": None,
        "category": "breakfast",
        "cuisine": "American",
        "tags": ["healthy", "quick"],
        "source_type": "manual",
        "source_url": None,
        "is_public": False,
        "calories_per_serving": 350,
        "protein_per_serving_g": 12.0,
        "carbs_per_serving_g": 60.0,
        "fat_per_serving_g": 8.0,
        "fiber_per_serving_g": 6.0,
        "times_logged": 5,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "deleted_at": None,
    }


# ============================================================
# MODEL VALIDATION TESTS (No mocking needed)
# ============================================================

class TestRecipeModels:
    """Test Pydantic model validation."""

    def test_recipe_create_model(self):
        """Test RecipeCreate model validation."""
        from models.recipe import RecipeCreate, RecipeIngredientCreate, RecipeSourceType

        recipe = RecipeCreate(
            name="Test Recipe",
            servings=2,
            source_type=RecipeSourceType.MANUAL,
            ingredients=[
                RecipeIngredientCreate(
                    food_name="Ingredient 1",
                    amount=100.0,
                    unit="g",
                    calories=200.0,
                )
            ],
        )

        assert recipe.name == "Test Recipe"
        assert recipe.servings == 2
        assert len(recipe.ingredients) == 1
        assert recipe.source_type == RecipeSourceType.MANUAL

    def test_recipe_create_with_category(self):
        """Test RecipeCreate with category."""
        from models.recipe import RecipeCreate, RecipeIngredientCreate, RecipeSourceType, RecipeCategory

        recipe = RecipeCreate(
            name="Breakfast Bowl",
            servings=1,
            category=RecipeCategory.BREAKFAST,
            source_type=RecipeSourceType.MANUAL,
            ingredients=[],
        )

        assert recipe.category == RecipeCategory.BREAKFAST

    def test_recipe_ingredient_create_model(self):
        """Test RecipeIngredientCreate model validation."""
        from models.recipe import RecipeIngredientCreate

        ingredient = RecipeIngredientCreate(
            food_name="Oats",
            amount=80.0,
            unit="g",
            calories=280.0,
            protein_g=10.0,
            carbs_g=50.0,
            fat_g=5.0,
            fiber_g=8.0,
        )

        assert ingredient.food_name == "Oats"
        assert ingredient.amount == 80.0
        assert ingredient.calories == 280.0
        assert ingredient.fiber_g == 8.0

    def test_recipe_ingredient_create_minimal(self):
        """Test RecipeIngredientCreate with minimal data."""
        from models.recipe import RecipeIngredientCreate

        ingredient = RecipeIngredientCreate(
            food_name="Salt",
            amount=1.0,
            unit="tsp",
        )

        assert ingredient.food_name == "Salt"
        assert ingredient.calories is None
        assert ingredient.protein_g is None

    def test_log_recipe_request_model(self):
        """Test LogRecipeRequest model validation."""
        from models.recipe import LogRecipeRequest

        request = LogRecipeRequest(
            meal_type="breakfast",
            servings=1.5,
        )

        assert request.meal_type == "breakfast"
        assert request.servings == 1.5

    def test_log_recipe_request_defaults(self):
        """Test LogRecipeRequest default values."""
        from models.recipe import LogRecipeRequest

        request = LogRecipeRequest(meal_type="lunch")

        assert request.servings == 1.0

    def test_recipe_response_model(self):
        """Test Recipe response model."""
        from models.recipe import Recipe, RecipeSourceType

        recipe = Recipe(
            id="recipe-123",
            user_id="user-456",
            name="Test Recipe",
            servings=2,
            source_type=RecipeSourceType.MANUAL,
            is_public=False,
            times_logged=5,
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )

        assert recipe.id == "recipe-123"
        assert recipe.name == "Test Recipe"
        assert recipe.times_logged == 5

    def test_recipe_summary_model(self):
        """Test RecipeSummary model."""
        from models.recipe import RecipeSummary

        summary = RecipeSummary(
            id="recipe-123",
            name="Quick Oatmeal",
            category="breakfast",
            calories_per_serving=350,
            protein_per_serving_g=12.0,
            servings=2,
            ingredient_count=3,
            times_logged=10,
            created_at=datetime.now(),
        )

        assert summary.name == "Quick Oatmeal"
        assert summary.ingredient_count == 3

    def test_recipes_response_model(self):
        """Test RecipesResponse model."""
        from models.recipe import RecipesResponse, RecipeSummary

        summary = RecipeSummary(
            id="recipe-123",
            name="Test",
            servings=1,
            ingredient_count=2,
            times_logged=0,
            created_at=datetime.now(),
        )

        response = RecipesResponse(
            items=[summary],
            total_count=1,
        )

        assert len(response.items) == 1
        assert response.total_count == 1

    def test_log_recipe_response_model(self):
        """Test LogRecipeResponse model."""
        from models.recipe import LogRecipeResponse

        response = LogRecipeResponse(
            success=True,
            food_log_id="log-123",
            recipe_name="Oatmeal",
            servings=1.0,
            total_calories=350,
            protein_g=12.0,
            carbs_g=60.0,
            fat_g=8.0,
        )

        assert response.success is True
        assert response.total_calories == 350

    def test_recipe_update_model(self):
        """Test RecipeUpdate model with partial data."""
        from models.recipe import RecipeUpdate

        update = RecipeUpdate(
            name="Updated Name",
            servings=4,
        )

        assert update.name == "Updated Name"
        assert update.servings == 4
        assert update.description is None


# ============================================================
# ENUM TESTS
# ============================================================

class TestRecipeEnums:
    """Test recipe enum values."""

    def test_recipe_category_values(self):
        """Test RecipeCategory enum values."""
        from models.recipe import RecipeCategory

        assert RecipeCategory.BREAKFAST.value == "breakfast"
        assert RecipeCategory.LUNCH.value == "lunch"
        assert RecipeCategory.DINNER.value == "dinner"
        assert RecipeCategory.SNACK.value == "snack"
        assert RecipeCategory.DESSERT.value == "dessert"
        assert RecipeCategory.DRINK.value == "drink"
        assert RecipeCategory.OTHER.value == "other"

    def test_recipe_source_type_values(self):
        """Test RecipeSourceType enum values."""
        from models.recipe import RecipeSourceType

        assert RecipeSourceType.MANUAL.value == "manual"
        assert RecipeSourceType.IMPORTED.value == "imported"
        assert RecipeSourceType.AI_GENERATED.value == "ai_generated"

    def test_recipe_category_from_string(self):
        """Test creating RecipeCategory from string."""
        from models.recipe import RecipeCategory

        category = RecipeCategory("breakfast")
        assert category == RecipeCategory.BREAKFAST

    def test_recipe_source_type_from_string(self):
        """Test creating RecipeSourceType from string."""
        from models.recipe import RecipeSourceType

        source = RecipeSourceType("manual")
        assert source == RecipeSourceType.MANUAL


# ============================================================
# IMPORT/EXPORT MODELS
# ============================================================

class TestImportExportModels:
    """Test import/export recipe models."""

    def test_import_recipe_request(self):
        """Test ImportRecipeRequest model."""
        from models.recipe import ImportRecipeRequest

        request = ImportRecipeRequest(
            url="https://example.com/recipe",
            servings_override=4,
        )

        assert request.url == "https://example.com/recipe"
        assert request.servings_override == 4

    def test_import_recipe_request_minimal(self):
        """Test ImportRecipeRequest with minimal data."""
        from models.recipe import ImportRecipeRequest

        request = ImportRecipeRequest(url="https://example.com/recipe")

        assert request.url == "https://example.com/recipe"
        assert request.servings_override is None

    def test_import_recipe_response_success(self):
        """Test ImportRecipeResponse for successful import."""
        from models.recipe import ImportRecipeResponse, Recipe, RecipeSourceType

        recipe = Recipe(
            id="recipe-123",
            user_id="user-456",
            name="Imported Recipe",
            servings=4,
            source_type=RecipeSourceType.IMPORTED,
            is_public=False,
            times_logged=0,
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )

        response = ImportRecipeResponse(
            success=True,
            recipe=recipe,
            ingredients_found=5,
            ingredients_with_nutrition=4,
        )

        assert response.success is True
        assert response.recipe.name == "Imported Recipe"
        assert response.ingredients_found == 5

    def test_import_recipe_response_failure(self):
        """Test ImportRecipeResponse for failed import."""
        from models.recipe import ImportRecipeResponse

        response = ImportRecipeResponse(
            success=False,
            error="Could not parse recipe from URL",
        )

        assert response.success is False
        assert response.error == "Could not parse recipe from URL"
        assert response.recipe is None


# ============================================================
# RECIPE INGREDIENT MODEL TESTS
# ============================================================

class TestRecipeIngredientModel:
    """Test RecipeIngredient model."""

    def test_recipe_ingredient_full(self):
        """Test RecipeIngredient with all fields."""
        from models.recipe import RecipeIngredient

        ingredient = RecipeIngredient(
            id="ing-123",
            recipe_id="recipe-456",
            ingredient_order=0,
            food_name="Rolled Oats",
            brand="Quaker",
            amount=80.0,
            unit="g",
            amount_grams=80.0,
            barcode="123456789",
            calories=280.0,
            protein_g=10.0,
            carbs_g=50.0,
            fat_g=5.0,
            fiber_g=8.0,
            sugar_g=1.0,
            notes="Use old-fashioned oats",
            is_optional=False,
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )

        assert ingredient.food_name == "Rolled Oats"
        assert ingredient.brand == "Quaker"
        assert ingredient.is_optional is False

    def test_recipe_ingredient_minimal(self):
        """Test RecipeIngredient with minimal fields."""
        from models.recipe import RecipeIngredient

        ingredient = RecipeIngredient(
            id="ing-123",
            recipe_id="recipe-456",
            ingredient_order=0,
            food_name="Salt",
            amount=1.0,
            unit="tsp",
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )

        assert ingredient.food_name == "Salt"
        assert ingredient.calories is None
        assert ingredient.brand is None


# ============================================================
# VALIDATION TESTS
# ============================================================

class TestValidation:
    """Test model validation constraints."""

    def test_recipe_name_required(self):
        """Test that recipe name is required."""
        from models.recipe import RecipeCreate, RecipeSourceType
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            RecipeCreate(
                servings=1,
                source_type=RecipeSourceType.MANUAL,
                ingredients=[],
            )

    def test_recipe_servings_min(self):
        """Test minimum servings constraint."""
        from models.recipe import RecipeCreate, RecipeSourceType
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            RecipeCreate(
                name="Test",
                servings=0,  # Must be >= 1
                source_type=RecipeSourceType.MANUAL,
                ingredients=[],
            )

    def test_recipe_servings_max(self):
        """Test maximum servings constraint."""
        from models.recipe import RecipeCreate, RecipeSourceType
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            RecipeCreate(
                name="Test",
                servings=101,  # Must be <= 100
                source_type=RecipeSourceType.MANUAL,
                ingredients=[],
            )

    def test_log_recipe_servings_positive(self):
        """Test that log recipe servings must be positive."""
        from models.recipe import LogRecipeRequest
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            LogRecipeRequest(
                meal_type="lunch",
                servings=0,  # Must be > 0
            )

    def test_log_recipe_servings_max(self):
        """Test maximum servings for logging."""
        from models.recipe import LogRecipeRequest
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            LogRecipeRequest(
                meal_type="lunch",
                servings=21,  # Must be <= 20
            )

    def test_ingredient_amount_required(self):
        """Test that ingredient amount is required."""
        from models.recipe import RecipeIngredientCreate
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            RecipeIngredientCreate(
                food_name="Oats",
                unit="g",
                # amount is missing
            )

    def test_ingredient_unit_required(self):
        """Test that ingredient unit is required."""
        from models.recipe import RecipeIngredientCreate
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            RecipeIngredientCreate(
                food_name="Oats",
                amount=100.0,
                # unit is missing
            )


# ============================================================
# MICRONUTRIENT DATA MODEL TESTS
# ============================================================

class TestMicronutrientDataModel:
    """Test MicronutrientData model."""

    def test_micronutrient_data_empty(self):
        """Test empty MicronutrientData."""
        from models.recipe import MicronutrientData

        data = MicronutrientData()

        assert data.vitamin_a_ug is None
        assert data.calcium_mg is None
        assert data.omega3_g is None

    def test_micronutrient_data_with_values(self):
        """Test MicronutrientData with values."""
        from models.recipe import MicronutrientData

        data = MicronutrientData(
            vitamin_a_ug=500.0,
            vitamin_c_mg=60.0,
            calcium_mg=800.0,
            iron_mg=12.0,
            omega3_g=1.5,
        )

        assert data.vitamin_a_ug == 500.0
        assert data.vitamin_c_mg == 60.0
        assert data.calcium_mg == 800.0

    def test_micronutrient_data_non_negative(self):
        """Test that negative values are rejected."""
        from models.recipe import MicronutrientData
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            MicronutrientData(vitamin_a_ug=-100.0)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
