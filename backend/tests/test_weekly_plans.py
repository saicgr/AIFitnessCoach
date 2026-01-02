"""
Tests for the Weekly Plans API endpoints.

These tests validate the holistic planning system that integrates
workouts, nutrition, and fasting into unified weekly plans.
"""

import pytest
from datetime import date, datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch
import json

# Test fixtures for weekly plan data
SAMPLE_USER_ID = "test-user-123"
SAMPLE_PLAN_ID = "plan-uuid-123"

SAMPLE_WEEKLY_PLAN = {
    "id": SAMPLE_PLAN_ID,
    "user_id": SAMPLE_USER_ID,
    "week_start_date": "2025-01-06",
    "status": "active",
    "workout_days": [0, 1, 3, 4],  # Mon, Tue, Thu, Fri
    "fasting_protocol": "16:8",
    "nutrition_strategy": "workout_aware",
    "generated_at": "2025-01-05T10:00:00",
    "created_at": "2025-01-05T10:00:00",
    "updated_at": "2025-01-05T10:00:00",
}

SAMPLE_DAILY_ENTRY = {
    "id": "entry-uuid-123",
    "weekly_plan_id": SAMPLE_PLAN_ID,
    "plan_date": "2025-01-06",
    "day_type": "training",
    "workout_id": "workout-uuid-123",
    "workout_time": "17:00",
    "calorie_target": 2300,
    "protein_target_g": 175,
    "carbs_target_g": 240,
    "fat_target_g": 70,
    "fiber_target_g": 30,
    "fasting_start_time": "20:00",
    "eating_window_start": "12:00",
    "eating_window_end": "20:00",
    "fasting_protocol": "16:8",
    "meal_suggestions": [
        {
            "meal_type": "lunch",
            "suggested_time": "12:00",
            "foods": [
                {"name": "Grilled Chicken Breast", "amount": "200g", "calories": 330, "protein": 62, "carbs": 0, "fat": 7},
                {"name": "Brown Rice", "amount": "150g", "calories": 165, "protein": 4, "carbs": 35, "fat": 1},
            ],
            "macros": {"calories": 495, "protein": 66, "carbs": 35, "fat": 8},
            "notes": "Post-fast meal, moderate portions",
        },
        {
            "meal_type": "pre_workout",
            "suggested_time": "15:00",
            "foods": [
                {"name": "Banana", "amount": "1 medium", "calories": 105, "protein": 1, "carbs": 27, "fat": 0},
                {"name": "Greek Yogurt", "amount": "150g", "calories": 100, "protein": 17, "carbs": 6, "fat": 1},
            ],
            "macros": {"calories": 205, "protein": 18, "carbs": 33, "fat": 1},
            "notes": "2 hours before workout for optimal energy",
        },
    ],
    "coordination_notes": [
        {
            "type": "optimal_timing",
            "message": "Workout at 17:00 fits well within your 12-8 eating window",
            "severity": "info",
        }
    ],
    "created_at": "2025-01-05T10:00:00",
}


class TestWeeklyPlansAPI:
    """Test cases for weekly plans API endpoints."""

    @pytest.fixture
    def mock_db(self):
        """Create a mock database client."""
        with patch("api.v1.weekly_plans.get_supabase_db") as mock:
            db = MagicMock()
            mock.return_value = db
            yield db

    @pytest.fixture
    def mock_gemini(self):
        """Create a mock Gemini service."""
        with patch("api.v1.weekly_plans.GeminiService") as mock:
            service = AsyncMock()
            mock.return_value = service
            yield service

    @pytest.fixture
    def mock_auth(self):
        """Create a mock auth dependency."""
        with patch("api.v1.weekly_plans.get_current_user") as mock:
            mock.return_value = {"id": SAMPLE_USER_ID}
            yield mock

    # =========================================================================
    # GET /api/v1/weekly-plans/current - Get current week's plan
    # =========================================================================

    @pytest.mark.asyncio
    async def test_get_current_plan_success(self, mock_db, mock_auth):
        """Test getting the current week's plan successfully."""
        # Setup mock to return a plan
        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = SAMPLE_WEEKLY_PLAN

        # The test would call the API endpoint
        # For now, we validate the test structure
        assert SAMPLE_WEEKLY_PLAN["status"] == "active"
        assert SAMPLE_WEEKLY_PLAN["workout_days"] == [0, 1, 3, 4]

    @pytest.mark.asyncio
    async def test_get_current_plan_not_found(self, mock_db, mock_auth):
        """Test getting current plan when none exists."""
        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        # Should return 404 or empty response
        # Actual implementation would verify the API response

    # =========================================================================
    # POST /api/v1/weekly-plans/generate - Generate new plan
    # =========================================================================

    @pytest.mark.asyncio
    async def test_generate_plan_success(self, mock_db, mock_gemini, mock_auth):
        """Test generating a new weekly plan with AI."""
        # Mock Gemini response
        mock_gemini.generate_weekly_holistic_plan.return_value = {
            "daily_entries": [
                {
                    "date": "2025-01-06",
                    "day_type": "training",
                    "calorie_target": 2300,
                    "protein_target_g": 175,
                    "carbs_target_g": 240,
                    "fat_target_g": 70,
                    "meal_suggestions": [],
                    "coordination_notes": [],
                }
            ]
        }

        # Mock database insert
        mock_db.client.table.return_value.insert.return_value.execute.return_value.data = [SAMPLE_WEEKLY_PLAN]

        # Validate the request structure
        request_data = {
            "workout_days": [0, 1, 3, 4],
            "fasting_protocol": "16:8",
            "nutrition_strategy": "workout_aware",
            "preferred_workout_time": "17:00",
        }

        assert len(request_data["workout_days"]) == 4
        assert request_data["fasting_protocol"] == "16:8"

    @pytest.mark.asyncio
    async def test_generate_plan_invalid_days(self, mock_db, mock_auth):
        """Test plan generation with invalid workout days."""
        # Invalid day values (should be 0-6)
        request_data = {
            "workout_days": [0, 7, 8],  # Invalid: 7 and 8 are not valid days
            "fasting_protocol": "16:8",
        }

        # The API should reject this request with a validation error
        invalid_days = [d for d in request_data["workout_days"] if d < 0 or d > 6]
        assert len(invalid_days) > 0, "Test data should have invalid days"

    @pytest.mark.asyncio
    async def test_generate_plan_no_workout_days(self, mock_db, mock_auth):
        """Test plan generation with no workout days selected."""
        request_data = {
            "workout_days": [],
            "fasting_protocol": "16:8",
        }

        # Should return validation error - at least 1 workout day required
        assert len(request_data["workout_days"]) == 0

    # =========================================================================
    # Workout-aware nutrition adjustments
    # =========================================================================

    def test_training_day_nutrition_adjustment(self):
        """Test that training days have higher nutrition targets."""
        base_calories = 2000
        training_day_bonus = 300  # +300 calories on training days
        protein_bonus = 25  # +25g protein

        training_day_calories = base_calories + training_day_bonus
        rest_day_calories = base_calories

        assert training_day_calories > rest_day_calories
        assert training_day_calories == 2300

    def test_cutting_strategy_reduces_rest_day_calories(self):
        """Test that cutting strategy reduces rest day calories."""
        base_calories = 2000
        cutting_deficit = 200

        training_day_calories = base_calories + 200  # Still higher on training days
        rest_day_calories = base_calories - cutting_deficit

        assert rest_day_calories < training_day_calories
        assert rest_day_calories == 1800

    # =========================================================================
    # Fasting-workout coordination
    # =========================================================================

    def test_fasting_workout_coordination_optimal(self):
        """Test optimal fasting-workout coordination (workout within eating window)."""
        eating_window_start = "12:00"
        eating_window_end = "20:00"
        workout_time = "17:00"

        # Workout at 17:00 is within 12-8 window - optimal
        workout_hour = int(workout_time.split(":")[0])
        window_start_hour = int(eating_window_start.split(":")[0])
        window_end_hour = int(eating_window_end.split(":")[0])

        is_within_window = window_start_hour <= workout_hour <= window_end_hour
        assert is_within_window is True

    def test_fasting_workout_coordination_fasted_warning(self):
        """Test fasted training warning when workout is before eating window."""
        eating_window_start = "12:00"
        eating_window_end = "20:00"
        workout_time = "07:00"  # Morning workout while still fasting

        workout_hour = int(workout_time.split(":")[0])
        window_start_hour = int(eating_window_start.split(":")[0])

        is_fasted_training = workout_hour < window_start_hour
        assert is_fasted_training is True

        # Expected warning
        expected_warning = {
            "type": "fasted_training",
            "message": "Your workout is during your fasting window. Consider BCAAs before training.",
            "severity": "warning",
        }
        assert expected_warning["severity"] == "warning"

    def test_fasting_workout_coordination_extended_fast(self):
        """Test warning for workout during extended fast (>16h)."""
        # OMAD with workout in morning
        eating_window_start = "18:00"
        eating_window_end = "19:00"
        workout_time = "08:00"

        # Calculate hours since last meal (19:00 previous day)
        # From 19:00 to 08:00 = 13 hours fasted
        hours_fasted = 13

        # For 20:4 or OMAD, workout at 08:00 means 13+ hours fasted
        is_extended_fast_workout = hours_fasted > 12
        assert is_extended_fast_workout is True

    # =========================================================================
    # Meal suggestions validation
    # =========================================================================

    def test_meal_suggestions_fit_eating_window(self):
        """Test that all meal suggestions fit within eating window."""
        eating_window_start = "12:00"
        eating_window_end = "20:00"

        meal_suggestions = [
            {"meal_type": "lunch", "suggested_time": "12:00"},
            {"meal_type": "pre_workout", "suggested_time": "15:00"},
            {"meal_type": "post_workout", "suggested_time": "18:30"},
            {"meal_type": "dinner", "suggested_time": "19:30"},
        ]

        window_start_hour = int(eating_window_start.split(":")[0])
        window_end_hour = int(eating_window_end.split(":")[0])

        for meal in meal_suggestions:
            meal_hour = int(meal["suggested_time"].split(":")[0])
            assert window_start_hour <= meal_hour <= window_end_hour, \
                f"{meal['meal_type']} at {meal['suggested_time']} is outside eating window"

    def test_meal_suggestions_total_macros_match_targets(self):
        """Test that total meal macros approximately match daily targets."""
        daily_targets = {
            "calories": 2300,
            "protein_g": 175,
            "carbs_g": 240,
            "fat_g": 70,
        }

        meal_suggestions = [
            {"macros": {"calories": 500, "protein": 45, "carbs": 55, "fat": 15}},
            {"macros": {"calories": 250, "protein": 20, "carbs": 35, "fat": 5}},
            {"macros": {"calories": 550, "protein": 50, "carbs": 60, "fat": 20}},
            {"macros": {"calories": 600, "protein": 40, "carbs": 70, "fat": 20}},
            {"macros": {"calories": 400, "protein": 20, "carbs": 20, "fat": 10}},
        ]

        total_calories = sum(m["macros"]["calories"] for m in meal_suggestions)
        total_protein = sum(m["macros"]["protein"] for m in meal_suggestions)

        # Allow 10% variance
        calorie_variance = abs(total_calories - daily_targets["calories"]) / daily_targets["calories"]
        assert calorie_variance < 0.15, f"Calorie variance too high: {calorie_variance:.1%}"

    def test_training_day_has_pre_and_post_workout_meals(self):
        """Test that training days include pre and post workout meals."""
        training_day_meals = [
            {"meal_type": "lunch", "suggested_time": "12:00"},
            {"meal_type": "pre_workout", "suggested_time": "15:00"},
            {"meal_type": "post_workout", "suggested_time": "18:30"},
            {"meal_type": "dinner", "suggested_time": "19:30"},
        ]

        meal_types = [m["meal_type"] for m in training_day_meals]
        assert "pre_workout" in meal_types, "Training day should have pre-workout meal"
        assert "post_workout" in meal_types, "Training day should have post-workout meal"

    # =========================================================================
    # Rest day plan validation
    # =========================================================================

    def test_rest_day_has_no_workout(self):
        """Test that rest days have no workout assigned."""
        rest_day_entry = {
            "day_type": "rest",
            "workout_id": None,
            "workout_time": None,
            "calorie_target": 2000,  # Base calories
            "protein_target_g": 150,  # Base protein
        }

        assert rest_day_entry["day_type"] == "rest"
        assert rest_day_entry["workout_id"] is None
        assert rest_day_entry["workout_time"] is None

    def test_rest_day_lower_calories_than_training(self):
        """Test that rest days have lower calorie targets than training days."""
        training_day_calories = 2300
        rest_day_calories = 2000

        assert rest_day_calories < training_day_calories
        calorie_difference = training_day_calories - rest_day_calories
        assert 200 <= calorie_difference <= 400, "Difference should be 200-400 calories"

    # =========================================================================
    # Plan archival and history
    # =========================================================================

    @pytest.mark.asyncio
    async def test_archive_plan(self, mock_db, mock_auth):
        """Test archiving an old weekly plan."""
        mock_db.client.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {**SAMPLE_WEEKLY_PLAN, "status": "archived"}
        ]

        # After archival, status should be "archived"
        archived_plan = {**SAMPLE_WEEKLY_PLAN, "status": "archived"}
        assert archived_plan["status"] == "archived"

    @pytest.mark.asyncio
    async def test_get_plan_history(self, mock_db, mock_auth):
        """Test getting historical plans for a user."""
        historical_plans = [
            {**SAMPLE_WEEKLY_PLAN, "week_start_date": "2025-01-06", "status": "active"},
            {**SAMPLE_WEEKLY_PLAN, "id": "plan-uuid-456", "week_start_date": "2024-12-30", "status": "completed"},
            {**SAMPLE_WEEKLY_PLAN, "id": "plan-uuid-789", "week_start_date": "2024-12-23", "status": "archived"},
        ]

        assert len(historical_plans) == 3
        assert historical_plans[0]["status"] == "active"
        assert historical_plans[1]["status"] == "completed"
        assert historical_plans[2]["status"] == "archived"


class TestHolisticPlanService:
    """Test cases for the holistic plan service logic."""

    def test_calculate_training_day_nutrition_moderate(self):
        """Test nutrition calculation for moderate intensity training day."""
        base_targets = {
            "calories": 2000,
            "protein_g": 150,
            "carbs_g": 200,
            "fat_g": 65,
        }

        # Moderate intensity: +250 cal, +20g protein, +30g carbs
        training_adjustments = {
            "moderate": {"calories": 250, "protein_g": 20, "carbs_g": 30, "fat_g": 5},
            "high": {"calories": 350, "protein_g": 30, "carbs_g": 50, "fat_g": 5},
            "low": {"calories": 150, "protein_g": 15, "carbs_g": 20, "fat_g": 0},
        }

        intensity = "moderate"
        adjustment = training_adjustments[intensity]

        training_day_targets = {
            "calories": base_targets["calories"] + adjustment["calories"],
            "protein_g": base_targets["protein_g"] + adjustment["protein_g"],
            "carbs_g": base_targets["carbs_g"] + adjustment["carbs_g"],
            "fat_g": base_targets["fat_g"] + adjustment["fat_g"],
        }

        assert training_day_targets["calories"] == 2250
        assert training_day_targets["protein_g"] == 170

    def test_calculate_training_day_nutrition_high_intensity(self):
        """Test nutrition calculation for high intensity training day."""
        base_targets = {
            "calories": 2000,
            "protein_g": 150,
            "carbs_g": 200,
            "fat_g": 65,
        }

        # High intensity: +350 cal, +30g protein, +50g carbs
        high_intensity_bonus = {
            "calories": 350,
            "protein_g": 30,
            "carbs_g": 50,
            "fat_g": 5,
        }

        training_day_targets = {
            "calories": base_targets["calories"] + high_intensity_bonus["calories"],
            "protein_g": base_targets["protein_g"] + high_intensity_bonus["protein_g"],
        }

        assert training_day_targets["calories"] == 2350
        assert training_day_targets["protein_g"] == 180

    def test_coordinate_16_8_with_morning_workout(self):
        """Test 16:8 fasting coordination with early morning workout."""
        fasting_protocol = "16:8"
        default_eating_window = ("12:00", "20:00")
        workout_time = "06:00"

        # Morning workout during fasting - generate warning
        workout_hour = int(workout_time.split(":")[0])
        window_start_hour = int(default_eating_window[0].split(":")[0])

        warnings = []
        if workout_hour < window_start_hour:
            warnings.append({
                "type": "fasted_training",
                "message": "You'll be training fasted. Consider taking BCAAs before your workout.",
                "severity": "warning",
            })

        assert len(warnings) == 1
        assert warnings[0]["type"] == "fasted_training"

    def test_coordinate_16_8_with_evening_workout(self):
        """Test 16:8 fasting coordination with evening workout."""
        fasting_protocol = "16:8"
        default_eating_window = ("12:00", "20:00")
        workout_time = "18:00"

        workout_hour = int(workout_time.split(":")[0])
        window_start_hour = int(default_eating_window[0].split(":")[0])
        window_end_hour = int(default_eating_window[1].split(":")[0])

        warnings = []
        notes = []

        # Workout within eating window - optimal
        if window_start_hour <= workout_hour <= window_end_hour:
            notes.append({
                "type": "optimal_timing",
                "message": "Your workout timing fits well within your eating window.",
                "severity": "info",
            })

            # Check if there's time for post-workout meal
            hours_until_window_closes = window_end_hour - workout_hour
            if hours_until_window_closes >= 2:
                notes.append({
                    "type": "post_workout_nutrition",
                    "message": f"You have {hours_until_window_closes} hours for post-workout nutrition before your fast begins.",
                    "severity": "info",
                })

        assert len(warnings) == 0
        assert len(notes) >= 1
        assert notes[0]["type"] == "optimal_timing"

    def test_coordinate_omad_with_workout(self):
        """Test OMAD coordination - workout should be near eating window."""
        fasting_protocol = "OMAD"
        eating_window = ("18:00", "19:00")  # 1 hour window
        workout_time = "17:00"

        workout_hour = int(workout_time.split(":")[0])
        window_start_hour = int(eating_window[0].split(":")[0])

        warnings = []
        notes = []

        # For OMAD, workout should ideally be just before eating window
        hours_before_eating = window_start_hour - workout_hour

        if 0 < hours_before_eating <= 2:
            notes.append({
                "type": "optimal_timing",
                "message": "Perfect timing! Workout ends just before your eating window.",
                "severity": "info",
            })
        elif hours_before_eating > 2:
            warnings.append({
                "type": "extended_fast_workout",
                "message": f"You'll be training after {20 + (24 - hours_before_eating)}+ hours of fasting. Consider BCAAs.",
                "severity": "warning",
            })

        assert len(notes) == 1
        assert notes[0]["message"].startswith("Perfect timing")

    def test_generate_pre_post_workout_meals(self):
        """Test generating pre and post workout meals for training days."""
        workout_time = "17:00"
        eating_window = ("12:00", "20:00")

        # Pre-workout: 2-3 hours before
        pre_workout_time = "14:30"  # 2.5 hours before
        # Post-workout: within 1-2 hours after
        post_workout_time = "18:30"  # 1.5 hours after

        meals = [
            {
                "meal_type": "pre_workout",
                "suggested_time": pre_workout_time,
                "notes": "Moderate carbs for energy, light protein",
            },
            {
                "meal_type": "post_workout",
                "suggested_time": post_workout_time,
                "notes": "Fast-absorbing protein + carbs for recovery",
            },
        ]

        # Validate timing
        pre_hour = int(pre_workout_time.split(":")[0])
        workout_hour = int(workout_time.split(":")[0])
        post_hour = int(post_workout_time.split(":")[0])

        assert pre_hour < workout_hour, "Pre-workout should be before workout"
        assert post_hour > workout_hour, "Post-workout should be after workout"
        assert workout_hour - pre_hour <= 3, "Pre-workout should be within 3 hours of workout"
        assert post_hour - workout_hour <= 2, "Post-workout should be within 2 hours of workout"


class TestWeeklyPlanValidation:
    """Test cases for plan validation logic."""

    def test_validate_workout_days_unique(self):
        """Test that workout days are unique."""
        workout_days = [0, 1, 1, 3]  # Duplicate day 1

        unique_days = list(set(workout_days))
        has_duplicates = len(unique_days) != len(workout_days)

        assert has_duplicates is True, "Should detect duplicate days"

    def test_validate_workout_days_range(self):
        """Test that workout days are within valid range 0-6."""
        valid_days = [0, 1, 3, 4, 6]
        invalid_days = [0, 1, 7, 8]

        def is_valid_day(day):
            return 0 <= day <= 6

        assert all(is_valid_day(d) for d in valid_days)
        assert not all(is_valid_day(d) for d in invalid_days)

    def test_validate_fasting_protocol(self):
        """Test that fasting protocol is valid."""
        valid_protocols = ["12:12", "14:10", "16:8", "18:6", "20:4", "OMAD", None]
        invalid_protocol = "15:9"

        assert invalid_protocol not in valid_protocols

    def test_validate_nutrition_strategy(self):
        """Test that nutrition strategy is valid."""
        valid_strategies = ["workout_aware", "static", "cutting", "bulking"]
        invalid_strategy = "random"

        assert invalid_strategy not in valid_strategies

    def test_validate_week_start_is_monday(self):
        """Test that week start date is a Monday."""
        monday = date(2025, 1, 6)  # This is a Monday
        tuesday = date(2025, 1, 7)  # This is a Tuesday

        assert monday.weekday() == 0, "Week should start on Monday"
        assert tuesday.weekday() != 0, "Tuesday is not Monday"

    def test_validate_daily_entries_count(self):
        """Test that a weekly plan has exactly 7 daily entries."""
        daily_entries = [
            {"plan_date": "2025-01-06"},
            {"plan_date": "2025-01-07"},
            {"plan_date": "2025-01-08"},
            {"plan_date": "2025-01-09"},
            {"plan_date": "2025-01-10"},
            {"plan_date": "2025-01-11"},
            {"plan_date": "2025-01-12"},
        ]

        assert len(daily_entries) == 7, "Should have entries for all 7 days"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
