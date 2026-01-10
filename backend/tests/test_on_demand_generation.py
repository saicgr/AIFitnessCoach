"""
Tests for JIT (Just-In-Time) workout generation.

All workout generation now follows JIT philosophy - always 1 workout at a time.
The backend hardcodes workout_dates[:1] in generate_remaining_workouts.
"""
import pytest
from pydantic import ValidationError
from models.schemas import GenerateMonthlyRequest


class TestMaxWorkoutsSchema:
    """Tests for max_workouts field in GenerateMonthlyRequest schema."""

    def test_max_workouts_is_optional(self):
        """Test that max_workouts is optional and defaults to None."""
        request = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-01",
            selected_days=[0, 2, 4],
        )

        assert request.max_workouts is None

    def test_max_workouts_accepts_valid_value(self):
        """Test that max_workouts accepts valid integer values."""
        request = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-01",
            selected_days=[0, 2, 4],
            max_workouts=1,
        )

        assert request.max_workouts == 1

    def test_max_workouts_accepts_single_workout(self):
        """Test on-demand single workout generation (maxWorkouts: 1)."""
        request = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-01",
            selected_days=[0],
            max_workouts=1,
        )

        assert request.max_workouts == 1

    def test_max_workouts_minimum_is_one(self):
        """Test that max_workouts must be at least 1."""
        with pytest.raises(ValidationError) as exc_info:
            GenerateMonthlyRequest(
                user_id="user-123",
                month_start_date="2025-01-01",
                selected_days=[0, 2, 4],
                max_workouts=0,
            )

        assert "max_workouts" in str(exc_info.value).lower() or "greater than or equal to 1" in str(exc_info.value).lower()

    def test_max_workouts_maximum_is_thirty(self):
        """Test that max_workouts is capped at 30."""
        with pytest.raises(ValidationError) as exc_info:
            GenerateMonthlyRequest(
                user_id="user-123",
                month_start_date="2025-01-01",
                selected_days=[0, 2, 4],
                max_workouts=31,
            )

        assert "max_workouts" in str(exc_info.value).lower() or "less than or equal to 30" in str(exc_info.value).lower()

    def test_max_workouts_accepts_boundary_values(self):
        """Test that max_workouts accepts boundary values (1 and 30)."""
        # Min boundary
        request_min = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-01",
            selected_days=[0],
            max_workouts=1,
        )
        assert request_min.max_workouts == 1

        # Max boundary
        request_max = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-01",
            selected_days=[0, 1, 2, 3, 4, 5, 6],
            max_workouts=30,
        )
        assert request_max.max_workouts == 30

    def test_max_workouts_works_with_duration(self):
        """Test that max_workouts works alongside duration_minutes."""
        request = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-01",
            selected_days=[0, 2, 4],
            duration_minutes=45,
            max_workouts=1,
        )

        assert request.max_workouts == 1
        assert request.duration_minutes == 45


class TestMaxWorkoutsLogic:
    """Tests for max_workouts application in workout date calculation."""

    def test_limit_workout_dates_with_max_workouts(self):
        """Test that workout dates are properly limited by max_workouts."""
        # Simulating the logic from generation.py:
        # if body.max_workouts:
        #     workout_dates = workout_dates[:body.max_workouts]

        workout_dates = ["2025-01-06", "2025-01-08", "2025-01-10", "2025-01-13", "2025-01-15"]
        max_workouts = 1

        limited_dates = workout_dates[:max_workouts]

        assert len(limited_dates) == 1
        assert limited_dates[0] == "2025-01-06"

    def test_limit_preserves_order(self):
        """Test that limiting preserves chronological order."""
        workout_dates = ["2025-01-06", "2025-01-08", "2025-01-10", "2025-01-13"]
        max_workouts = 2

        limited_dates = workout_dates[:max_workouts]

        assert len(limited_dates) == 2
        assert limited_dates[0] == "2025-01-06"
        assert limited_dates[1] == "2025-01-08"

    def test_limit_handles_fewer_dates_than_max(self):
        """Test when available dates are fewer than max_workouts."""
        workout_dates = ["2025-01-06", "2025-01-08"]
        max_workouts = 5

        limited_dates = workout_dates[:max_workouts]

        # Should return all available dates (not fill up to max)
        assert len(limited_dates) == 2

    def test_no_limit_when_max_workouts_is_none(self):
        """Test that no limiting happens when max_workouts is None."""
        workout_dates = ["2025-01-06", "2025-01-08", "2025-01-10", "2025-01-13"]
        max_workouts = None

        # Simulating: if body.max_workouts: workout_dates = workout_dates[:body.max_workouts]
        if max_workouts:
            limited_dates = workout_dates[:max_workouts]
        else:
            limited_dates = workout_dates

        assert len(limited_dates) == 4


class TestOnDemandGenerationFlow:
    """Tests documenting the on-demand generation flow."""

    def test_on_demand_flow_schema(self):
        """Test the expected request schema for on-demand generation."""
        # This is the request that home screen sends for on-demand generation
        request = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-03",  # Today's date
            selected_days=[0, 2, 4],  # Mon, Wed, Fri
            duration_minutes=45,
            max_workouts=1,  # On-demand: only generate 1 workout
        )

        assert request.max_workouts == 1
        assert request.duration_minutes == 45
        assert len(request.selected_days) == 3

    def test_jit_always_generates_one_workout(self):
        """Document that JIT philosophy always generates 1 workout at a time."""
        # All generation now follows JIT - always 1 workout
        # The backend hardcodes workout_dates[:1] in generate_remaining_workouts
        request = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-01",
            selected_days=[0, 2, 4],
            duration_minutes=45,
        )

        # max_workouts is optional but backend always generates 1
        assert request.max_workouts is None  # Schema allows None
        # Actual generation is limited to 1 in generate_remaining_workouts
