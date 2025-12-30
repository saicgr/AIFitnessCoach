"""
Tests for Recipe Suggestion Service and API
============================================
Tests for AI-powered recipe suggestions based on body type, culture, and diet.
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from dataclasses import asdict

from services.recipe_suggestion_service import (
    RecipeSuggestionService,
    RecipeSuggestion,
    RecipeIngredient,
    UserRecipeContext,
    MealType,
    BodyType,
)


# ============================================================================
# FIXTURES
# ============================================================================


@pytest.fixture
def mock_user_context():
    """Sample user context for testing."""
    return UserRecipeContext(
        user_id="test-user-123",
        body_type="mesomorph",
        diet_type="high_protein",
        nutrition_goals=["build_muscle", "eat_healthier"],
        allergies=["peanuts"],
        dietary_restrictions=["halal"],
        disliked_foods=["liver", "anchovies"],
        favorite_cuisines=["indian", "mediterranean"],
        cooking_skill="intermediate",
        cooking_time_minutes=30,
        budget_level="moderate",
        spice_tolerance="medium",
        target_calories=2500,
        target_protein_g=180,
        target_carbs_g=250,
        target_fat_g=80,
    )


@pytest.fixture
def mock_recipe_suggestion():
    """Sample recipe suggestion for testing."""
    return RecipeSuggestion(
        recipe_name="Grilled Chicken Tikka Masala",
        recipe_description="A protein-packed Indian classic with tender spiced chicken",
        cuisine="indian",
        category="dinner",
        ingredients=[
            RecipeIngredient(
                name="chicken breast",
                amount=200,
                unit="g",
                calories=220,
                protein_g=46,
                carbs_g=0,
                fat_g=3,
            ),
            RecipeIngredient(
                name="Greek yogurt",
                amount=100,
                unit="g",
                calories=59,
                protein_g=10,
                carbs_g=4,
                fat_g=0,
            ),
        ],
        instructions=[
            "Marinate chicken in yogurt and spices for 30 minutes",
            "Grill chicken until cooked through",
            "Prepare masala sauce",
            "Combine and serve with basmati rice",
        ],
        servings=2,
        calories_per_serving=450,
        protein_per_serving_g=45,
        carbs_per_serving_g=30,
        fat_per_serving_g=15,
        fiber_per_serving_g=4,
        prep_time_minutes=15,
        cook_time_minutes=25,
        suggestion_reason="High protein for muscle building, matches Indian cuisine preference",
        goal_alignment_score=90,
        cuisine_match_score=100,
        diet_compliance_score=100,
        overall_match_score=95,
    )


@pytest.fixture
def service():
    """Recipe suggestion service instance."""
    return RecipeSuggestionService()


# ============================================================================
# MODEL TESTS
# ============================================================================


class TestRecipeModels:
    """Tests for recipe data models."""

    def test_recipe_ingredient_creation(self):
        """Test RecipeIngredient dataclass."""
        ingredient = RecipeIngredient(
            name="chicken breast",
            amount=200,
            unit="g",
            calories=220,
            protein_g=46,
        )
        assert ingredient.name == "chicken breast"
        assert ingredient.amount == 200
        assert ingredient.calories == 220

    def test_recipe_suggestion_creation(self, mock_recipe_suggestion):
        """Test RecipeSuggestion dataclass."""
        assert mock_recipe_suggestion.recipe_name == "Grilled Chicken Tikka Masala"
        assert mock_recipe_suggestion.cuisine == "indian"
        assert mock_recipe_suggestion.overall_match_score == 95
        assert len(mock_recipe_suggestion.ingredients) == 2

    def test_recipe_suggestion_to_dict(self, mock_recipe_suggestion):
        """Test RecipeSuggestion to_dict method."""
        data = mock_recipe_suggestion.to_dict()
        assert isinstance(data, dict)
        assert data["recipe_name"] == "Grilled Chicken Tikka Masala"
        assert isinstance(data["ingredients"], list)
        assert data["ingredients"][0]["name"] == "chicken breast"

    def test_user_context_creation(self, mock_user_context):
        """Test UserRecipeContext dataclass."""
        assert mock_user_context.body_type == "mesomorph"
        assert "indian" in mock_user_context.favorite_cuisines
        assert "peanuts" in mock_user_context.allergies

    def test_meal_type_enum(self):
        """Test MealType enum values."""
        assert MealType.BREAKFAST.value == "breakfast"
        assert MealType.LUNCH.value == "lunch"
        assert MealType.DINNER.value == "dinner"
        assert MealType.SNACK.value == "snack"
        assert MealType.ANY.value == "any"

    def test_body_type_enum(self):
        """Test BodyType enum values."""
        assert BodyType.ECTOMORPH.value == "ectomorph"
        assert BodyType.MESOMORPH.value == "mesomorph"
        assert BodyType.ENDOMORPH.value == "endomorph"
        assert BodyType.BALANCED.value == "balanced"


# ============================================================================
# SERVICE TESTS
# ============================================================================


class TestRecipeSuggestionService:
    """Tests for RecipeSuggestionService."""

    def test_build_recipe_prompt(self, service, mock_user_context):
        """Test prompt building includes all user context."""
        prompt = service._build_recipe_prompt(
            context=mock_user_context,
            meal_type=MealType.DINNER,
            count=3,
        )

        # Check body type included
        assert "mesomorph" in prompt.lower()

        # Check diet type included
        assert "high_protein" in prompt.lower() or "high protein" in prompt.lower()

        # Check allergies included
        assert "peanuts" in prompt.lower()

        # Check dietary restrictions included
        assert "halal" in prompt.lower()

        # Check cuisines included
        assert "indian" in prompt.lower()

        # Check targets included
        assert "2500" in prompt  # calories
        assert "180" in prompt   # protein

    def test_build_prompt_with_additional_requirements(self, service, mock_user_context):
        """Test prompt includes additional requirements."""
        prompt = service._build_recipe_prompt(
            context=mock_user_context,
            meal_type=MealType.LUNCH,
            count=2,
            additional_requirements="under 400 calories, high fiber",
        )

        assert "under 400 calories" in prompt.lower()
        assert "high fiber" in prompt.lower()

    def test_build_prompt_for_different_body_types(self, service, mock_user_context):
        """Test different body type guidance in prompts."""
        # Ectomorph
        mock_user_context.body_type = "ectomorph"
        prompt_ecto = service._build_recipe_prompt(
            context=mock_user_context,
            meal_type=MealType.ANY,
            count=1,
        )
        assert "calorie-dense" in prompt_ecto.lower() or "fast metabolism" in prompt_ecto.lower()

        # Endomorph
        mock_user_context.body_type = "endomorph"
        prompt_endo = service._build_recipe_prompt(
            context=mock_user_context,
            meal_type=MealType.ANY,
            count=1,
        )
        assert "lower carb" in prompt_endo.lower() or "slower metabolism" in prompt_endo.lower()

    @pytest.mark.asyncio
    async def test_get_user_context_returns_none_on_error(self, service):
        """Test get_user_context handles errors gracefully."""
        with patch("services.recipe_suggestion_service.get_supabase_db") as mock_db:
            mock_db.return_value.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = Exception("DB Error")

            result = await service.get_user_context("test-user")
            assert result is None

    @pytest.mark.asyncio
    async def test_suggest_recipes_validates_count(self, service, mock_user_context):
        """Test that recipe count is respected."""
        with patch.object(service, "get_user_context", return_value=mock_user_context):
            with patch("services.recipe_suggestion_service.client") as mock_client:
                mock_response = MagicMock()
                mock_response.text = '{"recipes": [{"recipe_name": "Test", "recipe_description": "", "cuisine": "indian", "category": "lunch", "ingredients": [], "instructions": [], "servings": 1, "calories_per_serving": 400, "protein_per_serving_g": 30, "carbs_per_serving_g": 40, "fat_per_serving_g": 15, "fiber_per_serving_g": 5, "prep_time_minutes": 10, "cook_time_minutes": 20, "suggestion_reason": "Test", "goal_alignment_score": 80, "cuisine_match_score": 90, "diet_compliance_score": 100, "overall_match_score": 85}]}'
                mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)

                with patch.object(service, "_save_suggestion_session", return_value="session-123"):
                    recipes = await service.suggest_recipes(
                        user_id="test-user",
                        count=1,
                    )

                    assert len(recipes) == 1


# ============================================================================
# PREFERENCE VALIDATION TESTS
# ============================================================================


class TestPreferenceValidation:
    """Tests for preference validation logic."""

    def test_allergy_handling_in_prompt(self, service, mock_user_context):
        """Test that allergies are prominently marked in prompt."""
        mock_user_context.allergies = ["peanuts", "shellfish", "milk"]

        prompt = service._build_recipe_prompt(
            context=mock_user_context,
            meal_type=MealType.DINNER,
            count=1,
        )

        # All allergies should be marked as critical
        assert "peanuts" in prompt.lower()
        assert "shellfish" in prompt.lower()
        assert "milk" in prompt.lower()
        assert "allergy" in prompt.lower()  # Should mention these are allergies

    def test_dietary_restriction_handling(self, service, mock_user_context):
        """Test dietary restrictions are included."""
        mock_user_context.dietary_restrictions = ["vegan", "gluten_free"]

        prompt = service._build_recipe_prompt(
            context=mock_user_context,
            meal_type=MealType.LUNCH,
            count=1,
        )

        assert "vegan" in prompt.lower()
        assert "gluten" in prompt.lower()

    def test_empty_preferences_handled(self, service):
        """Test handling of empty preference lists."""
        context = UserRecipeContext(
            user_id="test",
            body_type="balanced",
            diet_type="balanced",
            nutrition_goals=[],
            allergies=[],
            dietary_restrictions=[],
            disliked_foods=[],
            favorite_cuisines=[],
            cooking_skill="beginner",
            cooking_time_minutes=20,
            budget_level="budget",
            spice_tolerance="mild",
            target_calories=2000,
            target_protein_g=100,
            target_carbs_g=250,
            target_fat_g=70,
        )

        prompt = service._build_recipe_prompt(
            context=context,
            meal_type=MealType.ANY,
            count=3,
        )

        # Should handle empty lists without error
        assert "balanced" in prompt.lower()
        assert "any cuisine" in prompt.lower()  # Default when no cuisines specified


# ============================================================================
# API INTEGRATION TESTS
# ============================================================================


class TestRecipeSuggestionsAPI:
    """Tests for Recipe Suggestions API endpoints."""

    @pytest.mark.asyncio
    async def test_suggest_recipes_endpoint_success(self):
        """Test successful recipe suggestion request."""
        from api.v1.recipe_suggestions import suggest_recipes, SuggestRecipesRequest

        request = SuggestRecipesRequest(
            meal_type="dinner",
            count=2,
            additional_requirements="high protein",
        )

        with patch("api.v1.recipe_suggestions.recipe_suggestion_service") as mock_service:
            mock_suggestion = RecipeSuggestion(
                recipe_name="Test Recipe",
                recipe_description="A test recipe",
                cuisine="indian",
                category="dinner",
                ingredients=[],
                instructions=["Step 1", "Step 2"],
                servings=2,
                calories_per_serving=400,
                protein_per_serving_g=35,
                carbs_per_serving_g=30,
                fat_per_serving_g=15,
                fiber_per_serving_g=5,
                prep_time_minutes=15,
                cook_time_minutes=20,
                suggestion_reason="High protein match",
                goal_alignment_score=85,
                cuisine_match_score=90,
                diet_compliance_score=100,
                overall_match_score=90,
            )
            mock_service.suggest_recipes = AsyncMock(return_value=[mock_suggestion])

            with patch("api.v1.recipe_suggestions.UserContextService"):
                response = await suggest_recipes("test-user-123", request)

            assert response.success
            assert len(response.recipes) == 1
            assert response.recipes[0].recipe_name == "Test Recipe"

    @pytest.mark.asyncio
    async def test_get_cuisines_endpoint(self):
        """Test get cuisines list endpoint."""
        from api.v1.recipe_suggestions import get_cuisines

        with patch("api.v1.recipe_suggestions.recipe_suggestion_service") as mock_service:
            mock_service.get_cuisines_list = AsyncMock(return_value=[
                {"code": "indian", "name": "Indian", "region": "South Asia"},
                {"code": "italian", "name": "Italian", "region": "Europe"},
            ])

            cuisines = await get_cuisines()

            assert len(cuisines) == 2
            assert cuisines[0].code == "indian"

    @pytest.mark.asyncio
    async def test_get_body_types_endpoint(self):
        """Test get body types endpoint."""
        from api.v1.recipe_suggestions import get_body_types

        with patch("api.v1.recipe_suggestions.recipe_suggestion_service") as mock_service:
            mock_service.get_body_types_list = AsyncMock(return_value=[
                {"code": "ectomorph", "name": "Ectomorph", "description": "Lean build"},
                {"code": "mesomorph", "name": "Mesomorph", "description": "Athletic build"},
            ])

            body_types = await get_body_types()

            assert len(body_types) == 2
            assert body_types[0].code == "ectomorph"


# ============================================================================
# EDGE CASE TESTS
# ============================================================================


class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_recipe_with_no_ingredients(self):
        """Test handling recipe with no ingredients."""
        recipe = RecipeSuggestion(
            recipe_name="Empty Recipe",
            recipe_description="Test",
            cuisine="fusion",
            category="snack",
            ingredients=[],
            instructions=[],
            servings=1,
            calories_per_serving=0,
            protein_per_serving_g=0,
            carbs_per_serving_g=0,
            fat_per_serving_g=0,
            fiber_per_serving_g=0,
            prep_time_minutes=0,
            cook_time_minutes=0,
            suggestion_reason="Test",
            goal_alignment_score=0,
            cuisine_match_score=0,
            diet_compliance_score=0,
            overall_match_score=0,
        )
        data = recipe.to_dict()
        assert data["ingredients"] == []

    def test_all_body_types_have_guidance(self, service, mock_user_context):
        """Test all body types produce valid prompts."""
        for body_type in ["ectomorph", "mesomorph", "endomorph", "balanced"]:
            mock_user_context.body_type = body_type
            prompt = service._build_recipe_prompt(
                context=mock_user_context,
                meal_type=MealType.ANY,
                count=1,
            )
            assert body_type in prompt.lower()
            assert len(prompt) > 500  # Should be a substantial prompt

    def test_all_diet_types_have_guidance(self, service, mock_user_context):
        """Test all diet types produce valid prompts."""
        diet_types = ["balanced", "low_carb", "keto", "high_protein", "vegetarian", "vegan", "mediterranean", "paleo"]

        for diet in diet_types:
            mock_user_context.diet_type = diet
            prompt = service._build_recipe_prompt(
                context=mock_user_context,
                meal_type=MealType.ANY,
                count=1,
            )
            # Diet type should be mentioned in prompt
            assert diet.replace("_", " ") in prompt.lower() or diet.replace("_", "-") in prompt.lower() or diet in prompt.lower()


# ============================================================================
# RUN TESTS
# ============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
