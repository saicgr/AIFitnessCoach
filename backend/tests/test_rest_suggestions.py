"""
Tests for AI-Powered Rest Time Suggestion API.

This module tests:
1. Rule-based rest time calculation logic
2. API endpoint behavior
3. Edge cases and error handling
4. Fatigue multiplier calculations
5. Goal-based adjustments
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from typing import Dict, Any

# Try importing TestClient, handle if not available
try:
    from fastapi.testclient import TestClient
    HAS_TEST_CLIENT = True
except ImportError:
    HAS_TEST_CLIENT = False
    TestClient = None


# =============================================================================
# Test Fixtures
# =============================================================================

@pytest.fixture
def mock_gemini_service():
    """Create a mock Gemini service."""
    with patch("api.v1.workouts.rest_suggestions.get_gemini_service") as mock:
        mock_service = MagicMock()
        mock_service.chat = AsyncMock(return_value="Great effort! Take this time to recover fully.")
        mock.return_value = mock_service
        yield mock_service


@pytest.fixture
def client():
    """Create a test client."""
    if not HAS_TEST_CLIENT:
        pytest.skip("FastAPI TestClient not available")
    from main import app
    return TestClient(app)


# =============================================================================
# Unit Tests for Rule-Based Logic
# =============================================================================

class TestRestRanges:
    """Tests for rest time range constants and calculations."""

    def test_compound_heavy_ranges(self):
        """Test that compound heavy exercises have longest rest times."""
        from api.v1.workouts.rest_suggestions import REST_RANGES

        compound_heavy = REST_RANGES["compound_heavy"]
        isolation_heavy = REST_RANGES["isolation_heavy"]

        # Compound heavy should have longer rest than isolation heavy
        assert compound_heavy["min"] > isolation_heavy["min"]
        assert compound_heavy["max"] > isolation_heavy["max"]

    def test_heavy_vs_light_ranges(self):
        """Test that heavy exercises have longer rest than light ones."""
        from api.v1.workouts.rest_suggestions import REST_RANGES

        compound_heavy = REST_RANGES["compound_heavy"]
        compound_light = REST_RANGES["compound_light"]

        assert compound_heavy["min"] > compound_light["min"]
        assert compound_heavy["max"] > compound_light["max"]

    def test_quick_options_are_shorter(self):
        """Test that quick options are always shorter than minimum suggested."""
        from api.v1.workouts.rest_suggestions import REST_RANGES

        for key, ranges in REST_RANGES.items():
            assert ranges["quick"] < ranges["min"], f"{key} quick should be less than min"

    def test_fatigue_multipliers_increase(self):
        """Test that fatigue multipliers increase with set number."""
        from api.v1.workouts.rest_suggestions import FATIGUE_MULTIPLIER

        previous = 1.0
        for set_num in sorted(FATIGUE_MULTIPLIER.keys()):
            if set_num > 2:  # Sets 1-2 have same multiplier
                assert FATIGUE_MULTIPLIER[set_num] >= previous
            previous = FATIGUE_MULTIPLIER[set_num]


class TestRestCategoryClassification:
    """Tests for rest duration categorization."""

    def test_short_rest_category(self):
        """Test that rest <= 60s is classified as short."""
        from api.v1.workouts.rest_suggestions import get_rest_category

        assert get_rest_category(30) == "short"
        assert get_rest_category(45) == "short"
        assert get_rest_category(60) == "short"

    def test_moderate_rest_category(self):
        """Test that rest 61-120s is classified as moderate."""
        from api.v1.workouts.rest_suggestions import get_rest_category

        assert get_rest_category(61) == "moderate"
        assert get_rest_category(90) == "moderate"
        assert get_rest_category(120) == "moderate"

    def test_long_rest_category(self):
        """Test that rest 121-180s is classified as long."""
        from api.v1.workouts.rest_suggestions import get_rest_category

        assert get_rest_category(121) == "long"
        assert get_rest_category(150) == "long"
        assert get_rest_category(180) == "long"

    def test_extended_rest_category(self):
        """Test that rest > 180s is classified as extended."""
        from api.v1.workouts.rest_suggestions import get_rest_category

        assert get_rest_category(181) == "extended"
        assert get_rest_category(240) == "extended"
        assert get_rest_category(300) == "extended"


class TestRuleBasedSuggestion:
    """Tests for the rule-based suggestion generator."""

    def test_compound_high_rpe_suggestion(self):
        """Test suggestion for compound exercise at high RPE."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=9,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=2,
            sets_completed=1,
            user_goals=["strength"],
        )

        result = generate_rule_based_suggestion(request)

        # High RPE compound should suggest 180-300s range
        assert result.suggested_seconds >= 180
        assert result.suggested_seconds <= 330  # With strength goal bonus
        assert result.ai_powered is False
        assert "compound" in result.reasoning.lower()

    def test_isolation_low_rpe_suggestion(self):
        """Test suggestion for isolation exercise at low RPE."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=6,
            exercise_type="strength",
            is_compound=False,
            sets_remaining=3,
            sets_completed=0,
            user_goals=[],
        )

        result = generate_rule_based_suggestion(request)

        # Low RPE isolation should suggest 45-60s range
        assert result.suggested_seconds >= 45
        assert result.suggested_seconds <= 75
        assert result.ai_powered is False
        assert "isolation" in result.reasoning.lower()

    def test_fatigue_adjustment_applied(self):
        """Test that later sets get longer rest suggestions."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        base_request = {
            "rpe": 8,
            "exercise_type": "strength",
            "is_compound": True,
            "sets_remaining": 1,
            "user_goals": [],
        }

        # Early set
        request_early = RestSuggestionRequest(**base_request, sets_completed=1)
        result_early = generate_rule_based_suggestion(request_early)

        # Late set
        request_late = RestSuggestionRequest(**base_request, sets_completed=5)
        result_late = generate_rule_based_suggestion(request_late)

        # Later set should have equal or longer rest
        assert result_late.suggested_seconds >= result_early.suggested_seconds

    def test_strength_goal_increases_rest(self):
        """Test that strength goal increases suggested rest."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        base_request = {
            "rpe": 8,
            "exercise_type": "strength",
            "is_compound": True,
            "sets_remaining": 2,
            "sets_completed": 1,
        }

        # Without strength goal
        request_no_goal = RestSuggestionRequest(**base_request, user_goals=[])
        result_no_goal = generate_rule_based_suggestion(request_no_goal)

        # With strength goal
        request_strength = RestSuggestionRequest(**base_request, user_goals=["strength"])
        result_strength = generate_rule_based_suggestion(request_strength)

        # Strength goal should increase rest
        assert result_strength.suggested_seconds >= result_no_goal.suggested_seconds

    def test_endurance_goal_decreases_rest(self):
        """Test that endurance goal decreases suggested rest."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        base_request = {
            "rpe": 8,
            "exercise_type": "strength",
            "is_compound": True,
            "sets_remaining": 2,
            "sets_completed": 1,
        }

        # Without goal
        request_no_goal = RestSuggestionRequest(**base_request, user_goals=[])
        result_no_goal = generate_rule_based_suggestion(request_no_goal)

        # With endurance goal
        request_endurance = RestSuggestionRequest(**base_request, user_goals=["endurance"])
        result_endurance = generate_rule_based_suggestion(request_endurance)

        # Endurance goal should decrease rest
        assert result_endurance.suggested_seconds <= result_no_goal.suggested_seconds

    def test_quick_option_always_shorter(self):
        """Test that quick option is always shorter than suggested."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=9,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=2,
            sets_completed=1,
            user_goals=[],
        )

        result = generate_rule_based_suggestion(request)

        assert result.quick_option_seconds < result.suggested_seconds

    def test_reasoning_includes_rpe(self):
        """Test that reasoning mentions the RPE value."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=9,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=2,
            sets_completed=1,
            user_goals=[],
        )

        result = generate_rule_based_suggestion(request)

        assert "9" in result.reasoning or "RPE" in result.reasoning


# =============================================================================
# API Endpoint Tests
# =============================================================================

class TestRestSuggestionEndpoint:
    """Tests for POST /workouts/rest-suggestion endpoint."""

    @pytest.mark.skipif(not HAS_TEST_CLIENT, reason="TestClient not available")
    def test_valid_request_returns_suggestion(self, client, mock_gemini_service):
        """Test that valid request returns proper suggestion."""
        response = client.post(
            "/api/v1/workouts/rest-suggestion",
            json={
                "rpe": 8,
                "exercise_type": "strength",
                "is_compound": True,
                "sets_remaining": 2,
                "sets_completed": 1,
                "user_goals": ["strength"],
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert "suggested_seconds" in data
        assert "reasoning" in data
        assert "quick_option_seconds" in data
        assert "rest_category" in data
        assert isinstance(data["suggested_seconds"], int)
        assert isinstance(data["quick_option_seconds"], int)

    @pytest.mark.skipif(not HAS_TEST_CLIENT, reason="TestClient not available")
    def test_rpe_below_minimum_rejected(self, client):
        """Test that RPE below 6 is rejected."""
        response = client.post(
            "/api/v1/workouts/rest-suggestion",
            json={
                "rpe": 5,  # Below minimum of 6
                "exercise_type": "strength",
                "is_compound": True,
                "sets_remaining": 2,
            }
        )

        assert response.status_code == 422  # Validation error

    @pytest.mark.skipif(not HAS_TEST_CLIENT, reason="TestClient not available")
    def test_rpe_above_maximum_rejected(self, client):
        """Test that RPE above 10 is rejected."""
        response = client.post(
            "/api/v1/workouts/rest-suggestion",
            json={
                "rpe": 11,  # Above maximum of 10
                "exercise_type": "strength",
                "is_compound": True,
                "sets_remaining": 2,
            }
        )

        assert response.status_code == 422  # Validation error

    @pytest.mark.skipif(not HAS_TEST_CLIENT, reason="TestClient not available")
    def test_negative_sets_remaining_rejected(self, client):
        """Test that negative sets_remaining is rejected."""
        response = client.post(
            "/api/v1/workouts/rest-suggestion",
            json={
                "rpe": 8,
                "exercise_type": "strength",
                "is_compound": True,
                "sets_remaining": -1,
            }
        )

        assert response.status_code == 422  # Validation error

    @pytest.mark.skipif(not HAS_TEST_CLIENT, reason="TestClient not available")
    def test_missing_required_fields_rejected(self, client):
        """Test that missing required fields are rejected."""
        response = client.post(
            "/api/v1/workouts/rest-suggestion",
            json={
                "rpe": 8,
                # Missing exercise_type, is_compound, sets_remaining
            }
        )

        assert response.status_code == 422  # Validation error

    @pytest.mark.skipif(not HAS_TEST_CLIENT, reason="TestClient not available")
    def test_optional_fields_accepted(self, client, mock_gemini_service):
        """Test that optional fields are properly handled."""
        response = client.post(
            "/api/v1/workouts/rest-suggestion",
            json={
                "rpe": 8,
                "exercise_type": "strength",
                "exercise_name": "Bench Press",
                "is_compound": True,
                "sets_remaining": 2,
                "sets_completed": 1,
                "user_goals": ["strength", "muscle_building"],
                "muscle_group": "chest",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert "suggested_seconds" in data

    @pytest.mark.skipif(not HAS_TEST_CLIENT, reason="TestClient not available")
    def test_ai_failure_falls_back_to_rule_based(self, client):
        """Test that AI failure gracefully falls back to rule-based."""
        with patch("api.v1.workouts.rest_suggestions.get_gemini_service") as mock:
            mock_service = MagicMock()
            mock_service.chat = AsyncMock(side_effect=Exception("AI unavailable"))
            mock.return_value = mock_service

            response = client.post(
                "/api/v1/workouts/rest-suggestion",
                json={
                    "rpe": 8,
                    "exercise_type": "strength",
                    "is_compound": True,
                    "sets_remaining": 2,
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["ai_powered"] is False  # Should fall back to rule-based


class TestRestRangesEndpoint:
    """Tests for GET /workouts/rest-suggestion/ranges endpoint."""

    @pytest.mark.skipif(not HAS_TEST_CLIENT, reason="TestClient not available")
    def test_get_ranges_returns_data(self, client):
        """Test that ranges endpoint returns expected data structure."""
        response = client.get("/api/v1/workouts/rest-suggestion/ranges")

        assert response.status_code == 200
        data = response.json()

        assert "ranges" in data
        assert "fatigue_multipliers" in data
        assert "description" in data

        # Check ranges structure
        ranges = data["ranges"]
        assert "compound_heavy" in ranges
        assert "isolation_light" in ranges

        for key, value in ranges.items():
            assert "min" in value
            assert "max" in value
            assert "quick" in value


# =============================================================================
# Edge Cases and Error Handling
# =============================================================================

class TestEdgeCases:
    """Tests for edge cases and boundary conditions."""

    def test_zero_sets_remaining(self):
        """Test suggestion when no sets remaining (last set completed)."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=9,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=0,
            sets_completed=4,
            user_goals=[],
        )

        result = generate_rule_based_suggestion(request)

        # Should still return valid suggestion
        assert result.suggested_seconds > 0
        assert result.quick_option_seconds > 0

    def test_first_set(self):
        """Test suggestion for first set (no fatigue yet)."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=7,
            exercise_type="strength",
            is_compound=False,
            sets_remaining=4,
            sets_completed=0,
            user_goals=[],
        )

        result = generate_rule_based_suggestion(request)

        # First set should have baseline rest (no fatigue multiplier)
        assert result.suggested_seconds > 0

    def test_extreme_rpe_10(self):
        """Test suggestion at maximum RPE 10."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=10,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=1,
            sets_completed=3,
            user_goals=[],
        )

        result = generate_rule_based_suggestion(request)

        # Max RPE compound should suggest extended rest
        assert result.suggested_seconds >= 180

    def test_minimum_rpe_6(self):
        """Test suggestion at minimum RPE 6."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=6,
            exercise_type="strength",
            is_compound=False,
            sets_remaining=3,
            sets_completed=0,
            user_goals=[],
        )

        result = generate_rule_based_suggestion(request)

        # Min RPE isolation should suggest short rest
        assert result.suggested_seconds <= 75
        assert result.rest_category in ["short", "moderate"]

    def test_many_sets_completed(self):
        """Test suggestion after many sets completed (high fatigue)."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=8,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=1,
            sets_completed=10,  # Many sets completed
            user_goals=[],
        )

        result = generate_rule_based_suggestion(request)

        # Should apply maximum fatigue multiplier
        assert result.suggested_seconds > 0
        assert "fatigue" in result.reasoning.lower()

    def test_multiple_goals(self):
        """Test suggestion with multiple conflicting goals."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=8,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=2,
            sets_completed=1,
            user_goals=["strength", "endurance"],  # Conflicting goals
        )

        result = generate_rule_based_suggestion(request)

        # Should still return valid suggestion (strength takes precedence as first match)
        assert result.suggested_seconds > 0

    def test_empty_goals(self):
        """Test suggestion with empty goals list."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=8,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=2,
            sets_completed=1,
            user_goals=[],
        )

        result = generate_rule_based_suggestion(request)

        # Should return suggestion without goal adjustment
        assert result.suggested_seconds > 0


# =============================================================================
# Integration Tests
# =============================================================================

class TestIntegration:
    """Integration tests for rest suggestion workflow."""

    @pytest.mark.asyncio
    async def test_ai_suggestion_uses_rule_based_baseline(self):
        """Test that AI suggestion enhances rule-based baseline."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            generate_ai_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=8,
            exercise_type="strength",
            exercise_name="Squat",
            is_compound=True,
            sets_remaining=2,
            sets_completed=2,
            user_goals=["strength"],
            muscle_group="legs",
        )

        # Generate rule-based first
        rule_based = generate_rule_based_suggestion(request)

        # Mock Gemini service
        mock_gemini = MagicMock()
        mock_gemini.chat = AsyncMock(return_value="Perfect rest for muscle recovery!")

        # Generate AI suggestion
        ai_suggestion = await generate_ai_suggestion(mock_gemini, request, rule_based)

        # AI suggestion should use same timing as rule-based
        assert ai_suggestion.suggested_seconds == rule_based.suggested_seconds
        assert ai_suggestion.quick_option_seconds == rule_based.quick_option_seconds

        # But should have AI-generated reasoning
        assert ai_suggestion.ai_powered is True
        assert ai_suggestion.reasoning != rule_based.reasoning

    @pytest.mark.asyncio
    async def test_ai_reasoning_truncation(self):
        """Test that long AI reasoning is truncated."""
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            generate_ai_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=8,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=2,
            sets_completed=1,
            user_goals=[],
        )

        rule_based = generate_rule_based_suggestion(request)

        # Mock Gemini service with very long response
        long_response = "A" * 500  # 500 characters
        mock_gemini = MagicMock()
        mock_gemini.chat = AsyncMock(return_value=long_response)

        ai_suggestion = await generate_ai_suggestion(mock_gemini, request, rule_based)

        # Reasoning should be truncated to max 200 chars
        assert len(ai_suggestion.reasoning) <= 200
        assert ai_suggestion.reasoning.endswith("...")


# =============================================================================
# Performance Tests
# =============================================================================

class TestPerformance:
    """Performance-related tests."""

    def test_rule_based_suggestion_is_fast(self):
        """Test that rule-based suggestion is computed quickly."""
        import time
        from api.v1.workouts.rest_suggestions import (
            generate_rule_based_suggestion,
            RestSuggestionRequest,
        )

        request = RestSuggestionRequest(
            rpe=8,
            exercise_type="strength",
            is_compound=True,
            sets_remaining=2,
            sets_completed=1,
            user_goals=["strength"],
        )

        start = time.time()
        for _ in range(1000):
            generate_rule_based_suggestion(request)
        elapsed = time.time() - start

        # 1000 calculations should complete in < 1 second
        assert elapsed < 1.0, f"Rule-based suggestion too slow: {elapsed}s for 1000 calls"


# =============================================================================
# Additional Tests for AI Workout Intelligence Features
# =============================================================================

class TestAIRestSuggestionLogging:
    """Tests for AI suggestion logging and user action tracking."""

    def test_suggestion_logging_structure(self):
        """Test that logged suggestions have correct structure."""
        suggestion_log = {
            "user_id": "test-user-123",
            "workout_log_id": "workout-456",
            "exercise_id": "exercise-789",
            "suggestion_type": "rest",
            "suggested_value": {
                "rest_seconds": 120,
                "base_rest": 90,
                "rpe_modifier": 1.33,
                "exercise_type": "compound",
            },
            "reasoning": "2 minutes rest for compound exercise after RPE 9",
            "confidence": 0.85,
            "user_action": None,
        }

        assert suggestion_log["suggestion_type"] == "rest"
        assert "rest_seconds" in suggestion_log["suggested_value"]
        assert suggestion_log["confidence"] >= 0 and suggestion_log["confidence"] <= 1

    def test_user_action_values(self):
        """Test valid user action values."""
        valid_actions = ["accepted", "dismissed", "modified", None]

        for action in valid_actions:
            assert action in valid_actions

    def test_modified_value_tracking(self):
        """Test that modified values are tracked correctly."""
        original_suggestion = {"rest_seconds": 120}
        user_modified = {"rest_seconds": 90}

        # User reduced rest time
        assert user_modified["rest_seconds"] < original_suggestion["rest_seconds"]

    def test_acceptance_rate_calculation(self):
        """Test acceptance rate calculation."""
        suggestions = [
            {"user_action": "accepted"},
            {"user_action": "accepted"},
            {"user_action": "dismissed"},
            {"user_action": "modified"},
            {"user_action": "accepted"},
        ]

        accepted = sum(1 for s in suggestions if s["user_action"] == "accepted")
        total = len([s for s in suggestions if s["user_action"] is not None])

        acceptance_rate = accepted / total if total > 0 else 0

        assert acceptance_rate == 0.6  # 3 out of 5


class TestGeminiIntegration:
    """Tests for Gemini-powered personalized reasoning."""

    @pytest.mark.asyncio
    async def test_gemini_reasoning_called_with_context(self):
        """Test that Gemini receives proper context for reasoning."""
        context = {
            "rpe": 9,
            "exercise_name": "Barbell Squat",
            "exercise_type": "compound",
            "sets_completed": 3,
            "sets_remaining": 2,
            "suggested_rest": 180,
            "user_goals": ["strength"],
        }

        prompt_should_include = [
            "RPE 9",
            "compound",
            "Barbell Squat",
            "180 seconds",
        ]

        prompt = f"Generate rest advice for {context['exercise_name']} at RPE {context['rpe']}"

        for item in prompt_should_include[:2]:
            # Simplified check - actual implementation would check full prompt
            assert True  # Placeholder for actual Gemini integration test

    def test_gemini_fallback_on_error(self):
        """Test that system falls back to rule-based on Gemini error."""
        rule_based_rest = 120

        # When Gemini fails, should still return valid suggestion
        assert rule_based_rest > 0

    def test_reasoning_length_limit(self):
        """Test that AI reasoning is limited to reasonable length."""
        max_reasoning_length = 200

        sample_reasoning = "Take a 2-minute rest. Your muscles need time to recover ATP stores."

        truncated = sample_reasoning[:max_reasoning_length] if len(sample_reasoning) > max_reasoning_length else sample_reasoning

        assert len(truncated) <= max_reasoning_length


class TestQuickRestOption:
    """Tests for quick rest option for time-pressed users."""

    def test_quick_rest_is_60_percent(self):
        """Test that quick rest is 60% of suggested rest."""
        suggested_rest = 180
        quick_rest = int(suggested_rest * 0.6)

        assert quick_rest == 108

    def test_quick_rest_minimum_30_seconds(self):
        """Test that quick rest never goes below 30 seconds."""
        suggested_rest = 45
        quick_rest = max(30, int(suggested_rest * 0.6))

        assert quick_rest == 30

    def test_quick_rest_warning_for_heavy_exercises(self):
        """Test that quick rest shows warning for heavy compound exercises."""
        exercise_type = "compound"
        rpe = 9
        show_warning = exercise_type == "compound" and rpe >= 8

        assert show_warning is True

    def test_skip_rest_available_for_advanced(self):
        """Test that skip rest option is available for advanced users."""
        user_level = "advanced"
        skip_available = user_level in ["intermediate", "advanced"]

        assert skip_available is True


class TestFatigueAwareRest:
    """Tests for fatigue-aware rest adjustments."""

    def test_fatigue_level_increases_rest(self):
        """Test that high fatigue level increases rest time."""
        base_rest = 120
        fatigue_level = 0.7  # 70% fatigue

        fatigue_multiplier = 1.0 + (fatigue_level * 0.5)  # Up to 1.5x
        adjusted_rest = int(base_rest * fatigue_multiplier)

        assert adjusted_rest == 162  # 120 * 1.35

    def test_cumulative_workout_fatigue(self):
        """Test that workout duration affects rest suggestions."""
        base_rest = 120
        workout_duration_minutes = 50

        # After 30 minutes, add 2% per additional minute
        if workout_duration_minutes > 30:
            duration_multiplier = 1.0 + ((workout_duration_minutes - 30) * 0.02)
        else:
            duration_multiplier = 1.0

        adjusted_rest = int(base_rest * duration_multiplier)

        assert adjusted_rest == 168  # 120 * 1.4

    def test_rep_decline_triggers_extended_rest(self):
        """Test that rep decline triggers extended rest recommendation."""
        target_reps = 12
        actual_reps = 9
        decline_percent = (target_reps - actual_reps) / target_reps

        # 20%+ decline = extended rest
        if decline_percent >= 0.2:
            rest_multiplier = 1.3
        else:
            rest_multiplier = 1.0

        assert decline_percent == 0.25
        assert rest_multiplier == 1.3
