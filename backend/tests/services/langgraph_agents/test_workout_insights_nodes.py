"""
Tests for workout insights node functions.

Covers:
- categorize_muscle_group / determine_workout_focus pure logic
- analyze_workout_node async behavior
- generate_structured_insights_node fallback behavior (the fix for
  "Expected 2 sections, got 0" production error)
- Streaming truncation detection logic from generation.py
"""
import pytest
import json
from unittest.mock import AsyncMock, MagicMock, patch

from services.langgraph_agents.workout_insights.nodes import (
    categorize_muscle_group,
    determine_workout_focus,
    generate_structured_insights_node,
    analyze_workout_node,
)


# ============ Pure function tests ============


class TestCategorizeMuscleGroup:
    """Tests for muscle group categorization."""

    def test_empty_muscle_returns_other(self):
        assert categorize_muscle_group("") == "other"
        assert categorize_muscle_group(None) == "other"

    def test_chest_is_upper_push(self):
        assert categorize_muscle_group("chest") == "upper_push"
        assert categorize_muscle_group("Pectoralis Major") == "upper_push"

    def test_shoulder_is_upper_push(self):
        assert categorize_muscle_group("shoulder") == "upper_push"
        assert categorize_muscle_group("Deltoid") == "upper_push"
        assert categorize_muscle_group("triceps") == "upper_push"

    def test_back_is_upper_pull(self):
        assert categorize_muscle_group("back") == "upper_pull"
        assert categorize_muscle_group("Latissimus Dorsi") == "upper_pull"
        assert categorize_muscle_group("biceps") == "upper_pull"

    def test_legs_are_lower(self):
        assert categorize_muscle_group("quadriceps") == "lower"
        assert categorize_muscle_group("hamstrings") == "lower"
        assert categorize_muscle_group("glutes") == "lower"
        assert categorize_muscle_group("calf") == "lower"
        assert categorize_muscle_group("legs") == "lower"

    def test_core_muscles(self):
        assert categorize_muscle_group("core") == "core"
        assert categorize_muscle_group("abs") == "core"
        assert categorize_muscle_group("obliques") == "core"


class TestDetermineWorkoutFocus:
    """Tests for workout focus determination."""

    def test_empty_list_returns_full_body(self):
        assert determine_workout_focus([]) == "full body"

    def test_mostly_lower_is_leg_day(self):
        muscles = ["quadriceps", "hamstrings", "glutes", "calves"]
        assert determine_workout_focus(muscles) == "leg day"

    def test_mostly_push_is_push_day(self):
        muscles = ["chest", "shoulders", "triceps", "chest"]
        assert determine_workout_focus(muscles) == "push day"

    def test_mostly_pull_is_pull_day(self):
        muscles = ["back", "biceps", "lats", "rhomboids"]
        assert determine_workout_focus(muscles) == "pull day"

    def test_mixed_upper_is_upper_body(self):
        muscles = ["chest", "back", "shoulders", "biceps"]
        assert determine_workout_focus(muscles) == "upper body"

    def test_balanced_is_full_body(self):
        muscles = ["chest", "back", "quadriceps", "hamstrings", "core"]
        result = determine_workout_focus(muscles)
        assert result in ["full body", "upper body"]


# ============ Helpers for async tests ============


def _make_state(**overrides):
    """Build a minimal WorkoutInsightsState dict for testing."""
    state = {
        "workout_id": "test-123",
        "workout_name": "Upper Body Strength",
        "exercises": [
            {"name": "Bench Press", "sets": 4, "reps": 8, "primary_muscle": "chest"},
            {"name": "Barbell Rows", "sets": 4, "reps": 8, "primary_muscle": "back"},
            {"name": "Overhead Press", "sets": 3, "reps": 10, "primary_muscle": "shoulder"},
        ],
        "duration_minutes": 45,
        "workout_type": "strength",
        "difficulty": "medium",
        "user_goals": ["build muscle"],
        "fitness_level": "intermediate",
        "target_muscles": ["chest", "back", "shoulder"],
        "exercise_count": 3,
        "total_sets": 11,
        "workout_focus": "upper body",
        "headline": "",
        "sections": [],
        "summary": "",
        "error": None,
    }
    state.update(overrides)
    return state


def _mock_gemini_response(parsed_data=None, raw_text=None):
    """Create a mock Gemini response object."""
    response = MagicMock()
    if parsed_data is not None:
        mock_parsed = MagicMock()
        mock_parsed.model_dump.return_value = parsed_data
        response.parsed = mock_parsed
    else:
        response.parsed = None
    response.text = raw_text or (json.dumps(parsed_data) if parsed_data else None)
    response.candidates = []
    return response


# ============ analyze_workout_node tests ============


class TestAnalyzeWorkoutNode:
    """Tests for the analyze_workout_node function."""

    async def test_determines_focus_and_counts(self):
        state = _make_state()
        result = await analyze_workout_node(state)

        assert result["exercise_count"] == 3
        assert result["total_sets"] == 11
        assert len(result["target_muscles"]) == 3

    async def test_empty_exercises(self):
        state = _make_state(exercises=[])
        result = await analyze_workout_node(state)

        assert result["exercise_count"] == 0
        assert result["total_sets"] == 0
        assert result["workout_focus"] == "full body"


# ============ generate_structured_insights_node tests ============


class TestGenerateInsightsNodeFallback:
    """
    Tests that generate_structured_insights_node returns fallback data
    instead of raising when Gemini fails.

    These verify the fix for the "Expected 2 sections, got 0" production error.
    """

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_empty_sections_returns_fallback(self, mock_settings, mock_genai):
        """When Gemini returns empty sections array, node should return fallback."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={"headline": "Great Workout!", "sections": []}
        )
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert "headline" in result
        assert "sections" in result
        assert "summary" in result
        assert len(result["sections"]) == 2
        # Headline preserved from AI response
        assert result["headline"] == "Great Workout!"

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_single_section_returns_fallback(self, mock_settings, mock_genai):
        """When Gemini returns only 1 section, node should return fallback."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={
                "headline": "Push It!",
                "sections": [
                    {"icon": "🎯", "title": "Focus", "content": "Test", "color": "cyan"}
                ],
            }
        )
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["sections"]) == 2
        assert result["headline"] == "Push It!"

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_none_response_returns_fallback(self, mock_settings, mock_genai):
        """When Gemini returns None parsed and empty text, node should return fallback."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = MagicMock()
        response.parsed = None
        response.text = ""
        response.candidates = []

        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert "headline" in result
        assert len(result["sections"]) == 2
        assert result["headline"] == "Let's crush this workout!"

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_gemini_exception_returns_fallback(self, mock_settings, mock_genai):
        """When Gemini throws, node should return fallback after retries."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(
            side_effect=Exception("API quota exceeded")
        )
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert "headline" in result
        assert len(result["sections"]) == 2
        assert result["headline"] == "Let's crush this workout!"

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_retries_before_fallback(self, mock_settings, mock_genai):
        """Should retry max_retries times before falling back."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={"headline": "Test!", "sections": []}
        )
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        # initial + 2 retries = 3 calls
        assert mock_client.aio.models.generate_content.call_count == 3
        assert len(result["sections"]) == 2

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_success_on_first_try(self, mock_settings, mock_genai):
        """Valid response on first try should return immediately with no retries."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={
                "headline": "Crush It!",
                "sections": [
                    {"icon": "🎯", "title": "Focus", "content": "Upper body power", "color": "cyan"},
                    {"icon": "💪", "title": "Volume", "content": "Heavy compound lifts", "color": "purple"},
                ],
            }
        )
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert result["headline"] == "Crush It!"
        assert len(result["sections"]) == 2
        assert result["sections"][0]["title"] == "Focus"
        assert mock_client.aio.models.generate_content.call_count == 1

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_headline_truncated_to_5_words(self, mock_settings, mock_genai):
        """Headlines longer than 5 words should be truncated."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={
                "headline": "This Is A Very Long Headline That Exceeds",
                "sections": [
                    {"icon": "🎯", "title": "Focus", "content": "Test", "color": "cyan"},
                    {"icon": "💪", "title": "Volume", "content": "Test", "color": "purple"},
                ],
            }
        )
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["headline"].split()) <= 5

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_section_content_truncated_to_10_words(self, mock_settings, mock_genai):
        """Section content longer than 10 words should be truncated."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={
                "headline": "Go!",
                "sections": [
                    {"icon": "🎯", "title": "Focus",
                     "content": "One two three four five six seven eight nine ten eleven twelve",
                     "color": "cyan"},
                    {"icon": "💪", "title": "Volume", "content": "Short", "color": "purple"},
                ],
            }
        )
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["sections"][0]["content"].split()) <= 10
        assert result["sections"][1]["content"] == "Short"

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_fallback_uses_workout_context(self, mock_settings, mock_genai):
        """Fallback sections should reference the workout's focus and duration."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(
            side_effect=Exception("timeout")
        )
        mock_genai.Client.return_value = mock_client

        state = _make_state(workout_focus="leg day", duration_minutes=60)
        result = await generate_structured_insights_node(state)

        all_content = " ".join(s["content"] for s in result["sections"])
        assert "leg day" in all_content or "60" in all_content

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_summary_is_valid_json(self, mock_settings, mock_genai):
        """The summary field should be valid JSON matching headline/sections."""
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={
                "headline": "Go Hard!",
                "sections": [
                    {"icon": "🎯", "title": "Focus", "content": "Push it", "color": "cyan"},
                    {"icon": "💪", "title": "Volume", "content": "Max reps", "color": "purple"},
                ],
            }
        )
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        summary = json.loads(result["summary"])
        assert summary["headline"] == result["headline"]
        assert len(summary["sections"]) == len(result["sections"])


# ============ Streaming truncation detection tests ============


class TestStreamingTruncationDetection:
    """
    Tests for the streaming response truncation detection logic
    used in generation.py (lines 1530-1531).

    This verifies the logic that detects when a Gemini streaming response
    was cut off mid-JSON (e.g., due to max_output_tokens being too low).
    """

    @staticmethod
    def _is_truncated(content: str) -> bool:
        """Replicate the truncation detection logic from generation.py."""
        if not content:
            return False
        stripped = content.rstrip()
        return (
            stripped.endswith((',', '{', '[', ':'))
            or not stripped.endswith(('}', ']'))
        )

    def test_complete_json_not_truncated(self):
        assert not self._is_truncated('{"name": "Workout", "exercises": []}')

    def test_complete_array_not_truncated(self):
        assert not self._is_truncated('[{"name": "Workout"}]')

    def test_trailing_comma_is_truncated(self):
        assert self._is_truncated('{"name": "Workout",')

    def test_trailing_open_brace_is_truncated(self):
        assert self._is_truncated('{"name": "Workout", "set_targets": [{')

    def test_trailing_open_bracket_is_truncated(self):
        assert self._is_truncated('{"exercises": [')

    def test_trailing_colon_is_truncated(self):
        assert self._is_truncated('{"name":')

    def test_mid_string_is_truncated(self):
        assert self._is_truncated('{"name": "Cupid\'s Leg Press')

    def test_real_production_truncation(self):
        """
        Reproduces the actual production error: 3983 chars of JSON cut off
        mid-way through set_targets due to max_output_tokens=4000 in cached streaming.
        """
        truncated = '''{
  "name": "Cupid's Unstoppable Heart Surge",
  "exercises": [
    {
      "name": "Cupid's Leg Press Surge",
      "set_targets": [
        {
          "set_number": 1,
          "set_type": "warmup",
          "target_reps": 12
        },
        {'''
        assert self._is_truncated(truncated)

    def test_empty_content_not_truncated(self):
        assert not self._is_truncated("")


class TestCachedStreamingTokenLimit:
    """
    Verify the cached streaming function uses a sufficient max_output_tokens
    to prevent truncation of workouts with set_targets.
    """

    def test_cached_streaming_token_limit_matches_non_cached(self):
        """
        The cached streaming max_output_tokens must be >= 16384
        to prevent truncation of detailed workouts with set_targets.

        This was the root cause of the production JSON parse error.
        """
        import ast
        import os

        # Read the source file and find max_output_tokens in the cached function
        source_path = os.path.join(
            os.path.dirname(__file__),
            "..", "..", "..",
            "services", "gemini_service.py"
        )
        source_path = os.path.normpath(source_path)

        with open(source_path, "r") as f:
            source = f.read()

        # Find the cached streaming function and its max_output_tokens
        # Look for the pattern within generate_workout_plan_streaming_cached
        in_cached_func = False
        cached_token_limit = None
        non_cached_token_limit = None

        for line in source.splitlines():
            if "async def generate_workout_plan_streaming_cached" in line:
                in_cached_func = True
            elif "async def " in line and in_cached_func:
                break  # Hit next function
            if in_cached_func and "max_output_tokens=" in line and "cached_content" not in line:
                # Extract the numeric value
                token_val = line.split("max_output_tokens=")[1].split(",")[0].split("#")[0].strip()
                cached_token_limit = int(token_val)
                break

        assert cached_token_limit is not None, "Could not find max_output_tokens in cached streaming function"
        assert cached_token_limit >= 16384, (
            f"Cached streaming max_output_tokens={cached_token_limit} is too low. "
            f"Must be >= 16384 to prevent truncation of workouts with set_targets."
        )
