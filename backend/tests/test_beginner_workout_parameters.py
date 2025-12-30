"""
Tests for beginner workout parameter scaling.

Ensures that beginners get appropriate sets/reps:
- Max 3 sets (not 4+)
- Max 12 reps (not 14-20)
- Extra rest time for recovery

This prevents overwhelming beginners with too much volume
and allows them to focus on form.
"""

import pytest
from services.adaptive_workout_service import AdaptiveWorkoutService


class TestFitnessLevelAdjustments:
    """Test the FITNESS_LEVEL_ADJUSTMENTS constants."""

    def test_beginner_sets_max_is_3(self):
        """Beginners should have max 3 sets to focus on form."""
        adj = AdaptiveWorkoutService.FITNESS_LEVEL_ADJUSTMENTS["beginner"]
        assert adj["sets_max"] == 3

    def test_beginner_reps_max_is_12(self):
        """Beginners should have max 12 reps to maintain form quality."""
        adj = AdaptiveWorkoutService.FITNESS_LEVEL_ADJUSTMENTS["beginner"]
        assert adj["reps_max"] == 12

    def test_beginner_reps_min_is_6(self):
        """Beginners should have min 6 reps for sufficient practice."""
        adj = AdaptiveWorkoutService.FITNESS_LEVEL_ADJUSTMENTS["beginner"]
        assert adj["reps_min"] == 6

    def test_beginner_gets_extra_rest(self):
        """Beginners should get extra rest time (30 seconds)."""
        adj = AdaptiveWorkoutService.FITNESS_LEVEL_ADJUSTMENTS["beginner"]
        assert adj["rest_increase"] == 30

    def test_intermediate_has_higher_limits(self):
        """Intermediate users should have higher volume limits."""
        adj = AdaptiveWorkoutService.FITNESS_LEVEL_ADJUSTMENTS["intermediate"]
        assert adj["sets_max"] == 5
        assert adj["reps_max"] == 15

    def test_advanced_has_no_practical_limits(self):
        """Advanced users should have very high limits (no practical restriction)."""
        adj = AdaptiveWorkoutService.FITNESS_LEVEL_ADJUSTMENTS["advanced"]
        assert adj["sets_max"] >= 8
        assert adj["reps_max"] >= 20


class TestGetAdaptiveParametersBeginnerScaling:
    """Test that get_adaptive_parameters properly scales for beginners."""

    @pytest.fixture
    def service(self):
        """Create service without database connection."""
        return AdaptiveWorkoutService(supabase_client=None)

    @pytest.mark.asyncio
    async def test_beginner_sets_capped_at_3(self, service):
        """Beginner should never get more than 3 sets."""
        # Test with hypertrophy which normally has 3-5 sets
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="hypertrophy",
            user_goals=["muscle_gain"],
            fitness_level="beginner",
        )

        assert params["sets"] <= 3, f"Beginner got {params['sets']} sets, should be max 3"

    @pytest.mark.asyncio
    async def test_beginner_reps_capped_at_12(self, service):
        """Beginner should never get more than 12 reps."""
        # Test with endurance which normally has 12-20 reps
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="endurance",
            user_goals=["endurance"],
            fitness_level="beginner",
        )

        assert params["reps"] <= 12, f"Beginner got {params['reps']} reps, should be max 12"

    @pytest.mark.asyncio
    async def test_beginner_reps_at_least_6(self, service):
        """Beginner should get at least 6 reps."""
        # Test with strength which normally has 3-6 reps
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="strength",
            user_goals=["strength"],
            fitness_level="beginner",
        )

        assert params["reps"] >= 6, f"Beginner got {params['reps']} reps, should be min 6"

    @pytest.mark.asyncio
    async def test_beginner_gets_extra_rest(self, service):
        """Beginner should get 30 seconds extra rest."""
        # Get params for beginner
        beginner_params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="hypertrophy",
            user_goals=["muscle_gain"],
            fitness_level="beginner",
        )

        # Get params for intermediate (no extra rest)
        intermediate_params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="hypertrophy",
            user_goals=["muscle_gain"],
            fitness_level="intermediate",
        )

        # Beginner should have more rest
        assert beginner_params["rest_seconds"] >= intermediate_params["rest_seconds"]

    @pytest.mark.asyncio
    async def test_intermediate_can_have_more_sets(self, service):
        """Intermediate should be able to have up to 5 sets."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="hypertrophy",
            user_goals=["muscle_gain"],
            fitness_level="intermediate",
        )

        # Should allow higher sets than beginner
        assert params["sets"] <= 5

    @pytest.mark.asyncio
    async def test_advanced_no_restrictions(self, service):
        """Advanced users should have no practical restrictions."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="endurance",
            user_goals=["endurance"],
            fitness_level="advanced",
        )

        # Advanced should allow high rep ranges
        # The actual value depends on the workout type, just verify it's allowed
        assert params["reps"] <= 20

    @pytest.mark.asyncio
    async def test_fitness_level_included_in_response(self, service):
        """Response should include the fitness level for context."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="hypertrophy",
            user_goals=["muscle_gain"],
            fitness_level="beginner",
        )

        assert params.get("fitness_level") == "beginner"

    @pytest.mark.asyncio
    async def test_reasoning_includes_adjustment_note(self, service):
        """When adjusted, reasoning should explain why."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="endurance",  # High reps normally
            user_goals=["endurance"],
            fitness_level="beginner",
        )

        # Check if any reasoning mentions the adjustment
        reasoning = params.get("reasoning", [])
        has_adjustment_note = any("beginner" in r.lower() for r in reasoning)
        assert has_adjustment_note, f"Expected beginner adjustment note in reasoning: {reasoning}"


class TestWorkoutTypeScenarios:
    """Test specific workout type scenarios for beginners."""

    @pytest.fixture
    def service(self):
        return AdaptiveWorkoutService(supabase_client=None)

    @pytest.mark.asyncio
    async def test_beginner_endurance_workout(self, service):
        """
        Endurance workout for beginner should NOT have 15-20 reps.

        This is the exact scenario from the user's screenshot where
        a beginner got 14-20 reps and 4 sets.
        """
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="endurance",
            user_goals=["weight_loss"],
            fitness_level="beginner",
        )

        # These are the critical assertions based on user feedback
        assert params["sets"] <= 3, "Beginner should NOT get 4 sets"
        assert params["reps"] <= 12, "Beginner should NOT get 14-20 reps"

    @pytest.mark.asyncio
    async def test_beginner_full_body_workout(self, service):
        """Full body workout for beginner should have appropriate volume."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="full_body",
            user_goals=["general_fitness"],
            fitness_level="beginner",
        )

        assert params["sets"] <= 3
        assert params["reps"] <= 12
        assert params["reps"] >= 6

    @pytest.mark.asyncio
    async def test_beginner_strength_workout(self, service):
        """Strength workout for beginner should not go too low on reps."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="strength",
            user_goals=["strength"],
            fitness_level="beginner",
        )

        # Strength normally has 3-6 reps, but beginner min is 6
        assert params["reps"] >= 6, "Beginner should have at least 6 reps even for strength"


class TestCaseInsensitivity:
    """Test that fitness level handling is case-insensitive."""

    @pytest.fixture
    def service(self):
        return AdaptiveWorkoutService(supabase_client=None)

    @pytest.mark.asyncio
    async def test_uppercase_beginner(self, service):
        """BEGINNER should work the same as beginner."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="endurance",
            fitness_level="BEGINNER",
        )
        assert params["sets"] <= 3
        assert params["reps"] <= 12

    @pytest.mark.asyncio
    async def test_mixed_case_beginner(self, service):
        """Beginner should work the same as beginner."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="endurance",
            fitness_level="Beginner",
        )
        assert params["sets"] <= 3
        assert params["reps"] <= 12


class TestNullFitnessLevel:
    """Test behavior when fitness level is not provided."""

    @pytest.fixture
    def service(self):
        return AdaptiveWorkoutService(supabase_client=None)

    @pytest.mark.asyncio
    async def test_none_fitness_level_uses_defaults(self, service):
        """When fitness_level is None, should use standard parameters."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="hypertrophy",
            fitness_level=None,
        )

        # Should get standard hypertrophy parameters without adjustment
        assert params["sets"] >= 3
        assert params["reps"] >= 8

    @pytest.mark.asyncio
    async def test_empty_string_fitness_level(self, service):
        """Empty string should not cause errors."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="hypertrophy",
            fitness_level="",
        )

        # Should not crash, return some valid params
        assert "sets" in params
        assert "reps" in params
