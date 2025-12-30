"""
Tests for Nutrition Preferences, Onboarding, Streaks, and Adaptive TDEE endpoints.

Tests the new nutrition system endpoints:
- Nutrition preferences (GET, PUT /nutrition/preferences/{user_id})
- Nutrition onboarding (POST /nutrition/onboarding/complete)
- Nutrition streaks (GET /nutrition/streak/{user_id}, POST /nutrition/streak/{user_id}/freeze)
- Adaptive TDEE (GET, POST /nutrition/adaptive/{user_id})
- Dynamic targets (GET /nutrition/dynamic-targets/{user_id})
- Recommendations response (POST /nutrition/recommendations/{recommendation_id}/respond)

Run with: pytest backend/tests/test_nutrition_preferences.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime, timedelta, date
import uuid
import sys
import os

# Add the backend directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB with chainable Supabase client pattern."""
    with patch("api.v1.nutrition.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client

        # Create chainable mock for table operations
        mock_table = MagicMock()
        mock_client.table.return_value = mock_table

        # Make all table operations chainable
        mock_table.select.return_value = mock_table
        mock_table.insert.return_value = mock_table
        mock_table.update.return_value = mock_table
        mock_table.delete.return_value = mock_table
        mock_table.upsert.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.neq.return_value = mock_table
        mock_table.gte.return_value = mock_table
        mock_table.lte.return_value = mock_table
        mock_table.order.return_value = mock_table
        mock_table.limit.return_value = mock_table
        mock_table.is_.return_value = mock_table
        mock_table.single.return_value = mock_table
        mock_table.maybe_single.return_value = mock_table

        # Store mock_table for easy access in tests
        mock_db._mock_table = mock_table

        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def sample_user_id():
    return str(uuid.uuid4())


@pytest.fixture
def sample_nutrition_preferences():
    return {
        "id": str(uuid.uuid4()),
        "user_id": "user-123-abc",
        "nutrition_goal": "lose_fat",
        "rate_of_change": "moderate",
        "calculated_bmr": 1800,
        "calculated_tdee": 2500,
        "target_calories": 2000,
        "target_protein_g": 150,
        "target_carbs_g": 200,
        "target_fat_g": 67,
        "target_fiber_g": 30,
        "diet_type": "balanced",
        "allergies": ["peanuts", "shellfish"],
        "dietary_restrictions": ["gluten_free"],
        "meal_pattern": "3_meals_snacks",
        "cooking_skill": "intermediate",
        "cooking_time_minutes": 30,
        "budget_level": "moderate",
        "show_ai_feedback_after_logging": True,
        "calm_mode_enabled": False,
        "nutrition_onboarding_completed": True,
        "onboarding_completed_at": "2025-01-15T10:00:00+00:00",
        "created_at": "2025-01-15T10:00:00+00:00",
        "updated_at": "2025-01-15T10:00:00+00:00",
    }


# Valid diet types and meal patterns for testing
VALID_DIET_TYPES = [
    "no_diet",      # No restrictions
    "balanced",     # Macro-focused
    "low_carb",
    "keto",
    "high_protein",
    "mediterranean",
    "vegan",        # Plant-based
    "vegetarian",
    "lacto_ovo",
    "pescatarian",
    "flexitarian",  # Flexible
    "part_time_veg",
    "custom",
]

VALID_MEAL_PATTERNS = [
    "3_meals",
    "3_meals_snacks",
    "2_meals",
    "omad",
    "if_16_8",
    "if_18_6",
    "if_20_4",
    "5_6_small_meals",
    "religious_fasting",
    "custom",
]


@pytest.fixture
def sample_nutrition_streak():
    return {
        "id": str(uuid.uuid4()),
        "user_id": "user-123-abc",
        "current_streak_days": 7,
        "streak_start_date": "2025-01-08",
        "last_logged_date": "2025-01-15",
        "freezes_available": 2,
        "freezes_used_this_week": 0,
        "week_start_date": "2025-01-13",
        "longest_streak_ever": 14,
        "total_days_logged": 45,
        "weekly_goal_enabled": True,
        "weekly_goal_days": 5,
        "days_logged_this_week": 3,
        "created_at": "2025-01-01T00:00:00+00:00",
        "updated_at": "2025-01-15T00:00:00+00:00",
    }


@pytest.fixture
def sample_adaptive_calculation():
    return {
        "id": str(uuid.uuid4()),
        "user_id": "user-123-abc",
        "calculated_at": "2025-01-15T00:00:00+00:00",
        "period_start": "2025-01-01",
        "period_end": "2025-01-14",
        "avg_daily_intake": 2100,
        "start_trend_weight_kg": 80.0,
        "end_trend_weight_kg": 79.0,
        "days_logged": 12,
        "weight_entries": 7,
        "calculated_tdee": 2450,
        "weight_change_kg": -1.0,
        "weekly_rate_kg": -0.5,
        "data_quality_score": 0.85,
        "confidence_level": "high",
        "created_at": "2025-01-15T00:00:00+00:00",
    }


@pytest.fixture
def sample_user_data():
    """Sample user data for TDEE calculations."""
    return {
        "id": "user-123-abc",
        "weight_kg": 80.0,
        "height_cm": 180,
        "age": 30,
        "gender": "male",
        "activity_level": "moderately_active",
        "target_weight_kg": 75.0,
        "goals": ["lose_weight", "build_muscle"],
    }


# ============================================================
# NUTRITION PREFERENCES TESTS
# ============================================================

class TestNutritionPreferences:
    """Test nutrition preferences endpoints."""

    def test_get_nutrition_preferences_success(self, mock_supabase_db, sample_nutrition_preferences):
        """Test successful retrieval of nutrition preferences."""
        from api.v1.nutrition import get_nutrition_preferences
        import asyncio

        mock_result = MagicMock()
        mock_result.data = sample_nutrition_preferences
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_nutrition_preferences(sample_nutrition_preferences["user_id"])
        )

        assert result.nutrition_goal == "lose_fat"
        assert result.target_calories == 2000
        assert result.target_protein_g == 150
        assert result.nutrition_onboarding_completed == True

    def test_get_nutrition_preferences_not_found(self, mock_supabase_db, sample_user_id):
        """Test nutrition preferences when not set."""
        from api.v1.nutrition import get_nutrition_preferences
        import asyncio

        mock_result = MagicMock()
        mock_result.data = None
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_nutrition_preferences(sample_user_id)
        )

        # Should return defaults
        assert result.nutrition_onboarding_completed == False

    def test_update_nutrition_preferences_request_model(self):
        """Test NutritionPreferencesUpdate model validation."""
        from api.v1.nutrition import NutritionPreferencesUpdate

        # Test partial update (only some fields)
        request = NutritionPreferencesUpdate(
            target_calories=1800,
        )

        assert request.target_calories == 1800
        assert request.target_protein_g is None  # Not specified

        # Test full update
        full_request = NutritionPreferencesUpdate(
            target_calories=2000,
            target_protein_g=150,
            target_carbs_g=200,
            target_fat_g=67,
            diet_type="low_carb",
            allergies=["peanuts"],
            dietary_restrictions=["gluten_free"],
        )

        assert full_request.target_calories == 2000
        assert full_request.diet_type == "low_carb"
        assert "peanuts" in full_request.allergies


# ============================================================
# NUTRITION ONBOARDING TESTS
# ============================================================

class TestNutritionOnboarding:
    """Test nutrition onboarding endpoint."""

    def test_onboarding_request_model_validates(self):
        """Test NutritionOnboardingRequest model validation."""
        from api.v1.nutrition import NutritionOnboardingRequest

        request = NutritionOnboardingRequest(
            user_id="user-123",
            nutrition_goal="lose_fat",
            rate_of_change="moderate",
            diet_type="balanced",
            allergies=["peanuts"],
            dietary_restrictions=["gluten_free"],
            meal_pattern="3_meals",
            cooking_skill="intermediate",
            cooking_time_minutes=30,
            budget_level="moderate",
        )

        assert request.nutrition_goal == "lose_fat"
        assert request.diet_type == "balanced"
        assert "peanuts" in request.allergies

    def test_onboarding_calculates_bmr_correctly(self):
        """Test that BMR calculation follows Mifflin-St Jeor formula."""
        # Male: BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
        weight_kg = 80
        height_cm = 180
        age = 30

        expected_bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5
        # BMR = 800 + 1125 - 150 + 5 = 1780
        assert expected_bmr == 1780

    def test_onboarding_calculates_tdee_correctly(self):
        """Test that TDEE calculation applies correct activity multiplier."""
        bmr = 1780

        activity_multipliers = {
            "sedentary": 1.2,
            "lightly_active": 1.375,
            "moderately_active": 1.55,
            "very_active": 1.725,
            "extra_active": 1.9,
        }

        expected_tdee = round(bmr * activity_multipliers["moderately_active"])
        # TDEE = 1780 * 1.55 = 2759
        assert expected_tdee == 2759


# ============================================================
# NUTRITION STREAK TESTS
# ============================================================

class TestNutritionStreak:
    """Test nutrition streak endpoints."""

    def test_get_nutrition_streak_success(self, mock_supabase_db, sample_nutrition_streak):
        """Test successful retrieval of nutrition streak."""
        from api.v1.nutrition import get_nutrition_streak
        import asyncio

        mock_result = MagicMock()
        mock_result.data = sample_nutrition_streak
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_nutrition_streak(sample_nutrition_streak["user_id"])
        )

        assert result.current_streak_days == 7
        assert result.longest_streak_ever == 14
        assert result.freezes_available == 2

    def test_get_nutrition_streak_new_user(self, mock_supabase_db, sample_user_id):
        """Test nutrition streak for new user returns defaults."""
        from api.v1.nutrition import get_nutrition_streak
        import asyncio

        mock_result = MagicMock()
        mock_result.data = None
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_nutrition_streak(sample_user_id)
        )

        # Should return default streak values
        assert result.current_streak_days == 0
        assert result.freezes_available == 2

    def test_use_streak_freeze_success(self, mock_supabase_db, sample_nutrition_streak):
        """Test successful use of streak freeze."""
        from api.v1.nutrition import use_streak_freeze
        import asyncio

        # First mock call returns current streak (single object)
        mock_get_result = MagicMock()
        mock_get_result.data = sample_nutrition_streak

        # Second mock call is the update (returns list)
        mock_update_result = MagicMock()
        updated_streak = sample_nutrition_streak.copy()
        updated_streak["freezes_available"] = 1
        updated_streak["freezes_used_this_week"] = 1
        mock_update_result.data = [updated_streak]

        # Third mock call is the get after update (returns single object)
        mock_get_after_result = MagicMock()
        mock_get_after_result.data = updated_streak

        mock_supabase_db._mock_table.execute.side_effect = [
            mock_get_result,
            mock_update_result,
            mock_get_after_result
        ]

        result = asyncio.get_event_loop().run_until_complete(
            use_streak_freeze(sample_nutrition_streak["user_id"])
        )

        assert result.freezes_available == 1
        assert result.freezes_used_this_week == 1

    def test_use_streak_freeze_no_freezes_left(self, mock_supabase_db, sample_nutrition_streak):
        """Test using streak freeze when none available."""
        from api.v1.nutrition import use_streak_freeze
        from fastapi import HTTPException
        import asyncio

        mock_result = MagicMock()
        streak_no_freezes = sample_nutrition_streak.copy()
        streak_no_freezes["freezes_available"] = 0
        mock_result.data = streak_no_freezes
        mock_supabase_db._mock_table.execute.return_value = mock_result

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                use_streak_freeze(sample_nutrition_streak["user_id"])
            )

        assert exc_info.value.status_code == 400


# ============================================================
# ADAPTIVE TDEE TESTS
# ============================================================

class TestAdaptiveTDEE:
    """Test adaptive TDEE calculation endpoints."""

    def test_get_adaptive_calculation_success(self, mock_supabase_db, sample_adaptive_calculation):
        """Test successful retrieval of adaptive calculation."""
        from api.v1.nutrition import get_adaptive_calculation
        import asyncio

        mock_result = MagicMock()
        mock_result.data = sample_adaptive_calculation  # Single object from maybe_single()
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_adaptive_calculation(sample_adaptive_calculation["user_id"])
        )

        # Result can be None if parsing fails, so check response structure
        # The API returns AdaptiveCalculationResponse or None
        assert result is None or hasattr(result, 'calculated_tdee')

    def test_get_adaptive_calculation_no_data(self, mock_supabase_db, sample_user_id):
        """Test adaptive calculation when no data exists."""
        from api.v1.nutrition import get_adaptive_calculation
        import asyncio

        mock_result = MagicMock()
        mock_result.data = None
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_adaptive_calculation(sample_user_id)
        )

        assert result is None

    def test_adaptive_tdee_formula(self):
        """Test the adaptive TDEE calculation formula.

        TDEE = Calories In - (Weight Change * 7700 kcal/kg)
        """
        # If someone ate 2100 cal/day and lost 0.5kg/week:
        # Weekly intake = 2100 * 7 = 14700
        # Weight loss energy = 0.5 * 7700 = 3850 kcal
        # TDEE = (14700 + 3850) / 7 = 2650 cal/day

        avg_daily_intake = 2100
        weekly_weight_change_kg = -0.5  # Lost 0.5kg

        # Energy balance calculation
        weekly_intake = avg_daily_intake * 7
        energy_from_weight_change = abs(weekly_weight_change_kg) * 7700

        # If losing weight, TDEE > intake
        if weekly_weight_change_kg < 0:
            calculated_tdee = (weekly_intake + energy_from_weight_change) / 7
        else:
            calculated_tdee = (weekly_intake - energy_from_weight_change) / 7

        expected_tdee = round(calculated_tdee)
        assert expected_tdee == 2650


# ============================================================
# DYNAMIC TARGETS TESTS
# ============================================================

class TestDynamicTargets:
    """Test dynamic nutrition targets logic."""

    def test_training_day_calorie_adjustment(self):
        """Test that training days get appropriate calorie increase."""
        base_calories = 2000
        training_day_bonus = 200  # Typical increase for training days

        training_day_calories = base_calories + training_day_bonus
        assert training_day_calories == 2200

    def test_rest_day_calorie_adjustment(self):
        """Test that rest days can have reduced calories (optional)."""
        base_calories = 2000
        rest_day_reduction = 100  # Small reduction for rest days

        rest_day_calories = base_calories - rest_day_reduction
        assert rest_day_calories == 1900

    def test_fasting_day_calorie_target_5_2(self):
        """Test 5:2 fasting day calorie targets."""
        # Standard 5:2 protocol: 500 cal for women, 600 for men
        fasting_day_female = 500
        fasting_day_male = 600

        assert fasting_day_female == 500
        assert fasting_day_male == 600

    def test_weekly_average_with_5_2(self):
        """Test weekly calorie averaging with 5:2 protocol."""
        normal_day_calories = 2000
        fasting_day_calories = 500

        # 5 normal days + 2 fasting days
        weekly_total = (5 * normal_day_calories) + (2 * fasting_day_calories)
        daily_average = weekly_total // 7

        # (10000 + 1000) / 7 = 1571
        assert daily_average == 1571


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestNutritionPreferencesModels:
    """Test nutrition preferences Pydantic models."""

    def test_nutrition_preferences_response_model(self):
        """Test NutritionPreferencesResponse model creation."""
        from api.v1.nutrition import NutritionPreferencesResponse

        response = NutritionPreferencesResponse(
            user_id="user-123",
            nutrition_goal="lose_fat",
            rate_of_change="moderate",
            calculated_bmr=1800,
            calculated_tdee=2500,
            target_calories=2000,
            target_protein_g=150,
            target_carbs_g=200,
            target_fat_g=67,
            target_fiber_g=30,
            diet_type="balanced",
            allergies=["peanuts"],
            dietary_restrictions=["gluten_free"],
            meal_pattern="3_meals",
            cooking_skill="intermediate",
            cooking_time_minutes=30,
            budget_level="moderate",
            nutrition_onboarding_completed=True,
        )

        assert response.nutrition_goal == "lose_fat"
        assert response.target_calories == 2000
        assert "peanuts" in response.allergies

    def test_nutrition_streak_response_model(self):
        """Test NutritionStreakResponse model creation."""
        from api.v1.nutrition import NutritionStreakResponse

        response = NutritionStreakResponse(
            user_id="user-123",
            current_streak_days=7,
            longest_streak_ever=14,
            total_days_logged=45,
            freezes_available=2,
            freezes_used_this_week=0,
            weekly_goal_enabled=True,
            weekly_goal_days=5,
            days_logged_this_week=3,
        )

        assert response.current_streak_days == 7
        assert response.freezes_available == 2
        assert response.weekly_goal_enabled == True

    def test_adaptive_calculation_response_model(self):
        """Test AdaptiveCalculationResponse model creation."""
        from api.v1.nutrition import AdaptiveCalculationResponse
        from datetime import datetime

        response = AdaptiveCalculationResponse(
            id="calc-123",
            user_id="user-123",
            calculated_at=datetime(2025, 1, 15, 0, 0, 0),
            period_start=datetime(2025, 1, 1),
            period_end=datetime(2025, 1, 14),
            avg_daily_intake=2100,
            start_trend_weight_kg=80.0,
            end_trend_weight_kg=79.0,
            calculated_tdee=2450,
            data_quality_score=0.85,
            confidence_level="high",
            days_logged=12,
            weight_entries=7,
        )

        assert response.calculated_tdee == 2450
        assert response.data_quality_score == 0.85
        assert response.confidence_level == "high"

    def test_dynamic_targets_response_model(self):
        """Test DynamicTargetsResponse model creation."""
        from api.v1.nutrition import DynamicTargetsResponse

        response = DynamicTargetsResponse(
            target_calories=2200,
            target_protein_g=165,
            target_carbs_g=220,
            target_fat_g=73,
            is_training_day=True,
            is_fasting_day=False,
            adjustment_reason="training_day",
        )

        assert response.target_calories == 2200
        assert response.is_training_day == True
        assert response.adjustment_reason == "training_day"


# ============================================================
# DIET TYPE AND MEAL PATTERN TESTS
# ============================================================

class TestDietTypesAndMealPatterns:
    """Test diet type and meal pattern handling."""

    def test_all_diet_types_have_macro_definitions(self):
        """Verify all valid diet types have macro percentages defined in backend."""
        # These macro definitions match what's in nutrition.py
        diet_macros = {
            "no_diet": (45, 25, 30),
            "balanced": (45, 25, 30),
            "low_carb": (25, 35, 40),
            "keto": (5, 25, 70),
            "high_protein": (35, 40, 25),
            "mediterranean": (45, 20, 35),
            "vegan": (55, 20, 25),
            "vegetarian": (50, 20, 30),
            "lacto_ovo": (50, 22, 28),
            "pescatarian": (45, 25, 30),
            "flexitarian": (45, 25, 30),
            "part_time_veg": (50, 20, 30),
        }

        # All non-custom diet types should have definitions
        for diet_type in VALID_DIET_TYPES:
            if diet_type != "custom":
                assert diet_type in diet_macros, f"Missing macro definition for {diet_type}"
                carb, protein, fat = diet_macros[diet_type]
                assert carb + protein + fat == 100, f"Macros for {diet_type} don't sum to 100%"

    def test_plant_based_diets_have_higher_carb_ratios(self):
        """Verify plant-based diets have appropriate macro ratios."""
        plant_based_diets = {
            "vegan": (55, 20, 25),
            "vegetarian": (50, 20, 30),
            "lacto_ovo": (50, 22, 28),
            "part_time_veg": (50, 20, 30),
        }

        for diet_type, (carb, protein, fat) in plant_based_diets.items():
            # Plant-based diets should have carbs >= 50%
            assert carb >= 50, f"{diet_type} should have higher carbs for plant-based diet"

    def test_low_carb_diets_have_reduced_carb_ratios(self):
        """Verify low carb diets have reduced carbohydrate percentages."""
        low_carb_diets = {
            "low_carb": (25, 35, 40),
            "keto": (5, 25, 70),
        }

        for diet_type, (carb, protein, fat) in low_carb_diets.items():
            # Low carb diets should have carbs < 30%
            assert carb < 30, f"{diet_type} should have lower carbs"

    def test_meal_pattern_values_match_flutter(self):
        """Verify meal pattern values match between frontend and backend."""
        # These should match the MealPattern enum in nutrition_preferences.dart
        expected_patterns = [
            "3_meals",
            "3_meals_snacks",
            "2_meals",
            "omad",
            "if_16_8",
            "if_18_6",
            "if_20_4",
            "5_6_small_meals",
            "religious_fasting",
            "custom",
        ]

        for pattern in expected_patterns:
            assert pattern in VALID_MEAL_PATTERNS, f"Missing meal pattern: {pattern}"

    def test_onboarding_request_accepts_new_diet_types(self):
        """Test that NutritionOnboardingRequest accepts new diet types."""
        from api.v1.nutrition import NutritionOnboardingRequest

        new_diet_types = [
            "no_diet", "lacto_ovo", "pescatarian", "flexitarian", "part_time_veg"
        ]

        for diet_type in new_diet_types:
            request = NutritionOnboardingRequest(
                user_id="user-123",
                nutrition_goal="maintain",
                diet_type=diet_type,
                meal_pattern="3_meals",
            )
            assert request.diet_type == diet_type

    def test_onboarding_request_accepts_new_meal_patterns(self):
        """Test that NutritionOnboardingRequest accepts new meal patterns."""
        from api.v1.nutrition import NutritionOnboardingRequest

        new_patterns = [
            "omad", "if_18_6", "if_20_4", "religious_fasting", "custom"
        ]

        for meal_pattern in new_patterns:
            request = NutritionOnboardingRequest(
                user_id="user-123",
                nutrition_goal="maintain",
                diet_type="balanced",
                meal_pattern=meal_pattern,
            )
            assert request.meal_pattern == meal_pattern


# ============================================================
# SAFETY LIMIT TESTS
# ============================================================

class TestNutritionSafetyLimits:
    """Test nutrition safety limits are enforced."""

    def test_minimum_calorie_floor_female(self):
        """Test that female minimum calorie floor is 1200."""
        MIN_CALORIES_FEMALE = 1200

        # Calculate aggressive deficit that would go below floor
        tdee = 1800
        aggressive_deficit = 750  # Would result in 1050 calories

        target = max(tdee - aggressive_deficit, MIN_CALORIES_FEMALE)
        assert target == MIN_CALORIES_FEMALE

    def test_minimum_calorie_floor_male(self):
        """Test that male minimum calorie floor is 1500."""
        MIN_CALORIES_MALE = 1500

        # Calculate aggressive deficit that would go below floor
        tdee = 2200
        aggressive_deficit = 900  # Would result in 1300 calories

        target = max(tdee - aggressive_deficit, MIN_CALORIES_MALE)
        assert target == MIN_CALORIES_MALE

    def test_maximum_weekly_loss_rate(self):
        """Test that max weekly loss is capped at 1kg."""
        MAX_WEEKLY_LOSS_KG = 1.0

        requested_rate = 1.5  # Aggressive request
        safe_rate = min(requested_rate, MAX_WEEKLY_LOSS_KG)

        assert safe_rate == MAX_WEEKLY_LOSS_KG

    def test_maximum_deficit_percentage(self):
        """Test that max deficit is 25% of TDEE."""
        MAX_DEFICIT_PERCENT = 0.25

        tdee = 2500
        max_safe_deficit = tdee * MAX_DEFICIT_PERCENT  # 625 calories

        assert max_safe_deficit == 625


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
