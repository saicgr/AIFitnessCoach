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


def _valid_sections(n=3):
    """Build n well-formed sections — the minimum the node now accepts."""
    palette = [
        {"icon": "🎯", "title": "Focus", "content": "Upper body power", "color": "cyan"},
        {"icon": "💪", "title": "Volume", "content": "Heavy compound lifts", "color": "purple"},
        {"icon": "🔋", "title": "Recovery", "content": "Protein and sleep", "color": "orange"},
        {"icon": "🔥", "title": "Tempo", "content": "Slow the lowering", "color": "green"},
    ]
    return [dict(s) for s in palette[:n]]


class TestGenerateInsightsNodeFallback:
    """
    Tests that generate_structured_insights_node returns fallback data
    instead of raising when Gemini fails.

    These verify the fix for the "Expected 2 sections, got 0" production error.

    Contract updates since these tests were written (behavior deliberately
    retired, tests rewritten to assert the CURRENT guarantee — the intent,
    "a bad/absent model response must still yield a complete insight card
    rather than an exception", is unchanged):

      * Minimum section count moved 2 -> 3. The prompt now asks for "3 to 5
        sections total" and the deterministic fallback builds exactly 3, so a
        response with 0, 1 or 2 sections is what now triggers the fallback.
      * Section content truncation moved 10 -> 36 words (a progressive-overload
        sentence citing real weights/reps runs longer than a generic cue).
      * The no-response fallback headline is "Time to get to work".
        "Let's crush this workout!" survives only as the default for a parsed
        dict that omits a headline, so it is asserted there instead.
      * The Gemini seam moved: the node no longer builds its own genai.Client
        and no longer runs its own retry loop. It calls the shared
        services.gemini.constants.gemini_generate_with_retry helper, which
        owns concurrency limiting + transient-error backoff. Patching
        `nodes.genai` targeted a name the module no longer imports.
    """

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_empty_sections_returns_fallback(self, mock_generate):
        """When Gemini returns empty sections array, node should return fallback."""
        mock_generate.return_value = _mock_gemini_response(
            parsed_data={"headline": "Great Workout!", "sections": []}
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert "headline" in result
        assert "sections" in result
        assert "summary" in result
        assert len(result["sections"]) == 3
        # Headline preserved from AI response
        assert result["headline"] == "Great Workout!"

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_single_section_returns_fallback(self, mock_generate):
        """When Gemini returns only 1 section, node should return fallback."""
        mock_generate.return_value = _mock_gemini_response(
            parsed_data={"headline": "Push It!", "sections": _valid_sections(1)}
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["sections"]) == 3
        assert result["headline"] == "Push It!"

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_two_sections_returns_fallback(self, mock_generate):
        """2 sections is now BELOW the minimum and must also fall back.

        Pins the current boundary: the node requires >= 3 sections. Two used to
        be an acceptable response; it no longer is.
        """
        mock_generate.return_value = _mock_gemini_response(
            parsed_data={"headline": "Push It!", "sections": _valid_sections(2)}
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["sections"]) == 3

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_none_response_returns_fallback(self, mock_generate):
        """When Gemini returns None parsed and empty text, node should return fallback."""
        response = MagicMock()
        response.parsed = None
        response.text = ""
        response.candidates = []
        mock_generate.return_value = response

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert "headline" in result
        assert len(result["sections"]) == 3
        assert result["headline"] == "Time to get to work"

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_missing_headline_uses_default(self, mock_generate):
        """A parsed response with sections but no headline gets the stock headline."""
        mock_generate.return_value = _mock_gemini_response(
            parsed_data={"sections": _valid_sections(3)}
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert result["headline"] == "Let's crush this workout!"
        assert len(result["sections"]) == 3

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_gemini_exception_returns_fallback(self, mock_generate):
        """When Gemini throws, node should return fallback rather than propagate."""
        mock_generate.side_effect = Exception("API quota exceeded")

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert "headline" in result
        assert len(result["sections"]) == 3
        assert result["headline"] == "Time to get to work"

    @patch("asyncio.sleep", new_callable=AsyncMock)
    @patch("services.gemini.constants.client")
    async def test_retries_before_fallback(self, mock_client, mock_sleep):
        """A transient Gemini error is retried, and only then does the node fall back.

        The retry loop moved out of the node into the shared
        gemini_generate_with_retry helper, so this drives the REAL helper (the
        node's actual call path) with a patched SDK client instead of asserting
        on a per-node retry counter that no longer exists. The helper's default
        is max_retries=3, i.e. 1 initial attempt + 3 retries = 4 calls, after
        which the error propagates and the node returns its fallback.
        """
        mock_client.aio.models.generate_content = AsyncMock(
            side_effect=Exception("429 rate limit exceeded")  # transient -> retried
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert mock_client.aio.models.generate_content.call_count == 4
        assert len(result["sections"]) == 3
        assert result["headline"] == "Time to get to work"

    @patch("asyncio.sleep", new_callable=AsyncMock)
    @patch("services.gemini.constants.client")
    async def test_non_transient_error_is_not_retried(self, mock_client, mock_sleep):
        """A non-transient error fails fast — one call, then the fallback."""
        mock_client.aio.models.generate_content = AsyncMock(
            side_effect=Exception("invalid api key")  # not in the transient list
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert mock_client.aio.models.generate_content.call_count == 1
        assert len(result["sections"]) == 3

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_success_on_first_try(self, mock_generate):
        """Valid response on first try should return immediately with no retries."""
        mock_generate.return_value = _mock_gemini_response(
            parsed_data={"headline": "Crush It!", "sections": _valid_sections(3)}
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert result["headline"] == "Crush It!"
        assert len(result["sections"]) == 3
        assert result["sections"][0]["title"] == "Focus"
        assert mock_generate.call_count == 1

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_headline_truncated_to_5_words(self, mock_generate):
        """Headlines longer than 5 words should be truncated."""
        mock_generate.return_value = _mock_gemini_response(
            parsed_data={
                "headline": "This Is A Very Long Headline That Exceeds",
                "sections": _valid_sections(3),
            }
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["headline"].split()) <= 5

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_headline_truncated_on_fallback_path_too(self, mock_generate):
        """The 5-word headline cap must hold even when the sections force a fallback.

        REGRESSION GUARD: the fallback carries the model's headline through
        verbatim, so a long headline used to escape the cap (and overflow the
        card) whenever the model returned too few sections.
        """
        mock_generate.return_value = _mock_gemini_response(
            parsed_data={
                "headline": "This Is A Very Long Headline That Exceeds",
                "sections": [],  # forces the fallback
            }
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["sections"]) == 3
        assert len(result["headline"].split()) <= 5

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_section_content_truncated_to_36_words(self, mock_generate):
        """Section content longer than 36 words should be truncated."""
        long_content = " ".join(f"word{i}" for i in range(50))
        sections = _valid_sections(3)
        sections[0]["content"] = long_content
        sections[1]["content"] = "Short"

        mock_generate.return_value = _mock_gemini_response(
            parsed_data={"headline": "Go!", "sections": sections}
        )

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["sections"][0]["content"].split()) == 36
        assert result["sections"][1]["content"] == "Short"

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_fallback_uses_workout_context(self, mock_generate):
        """Fallback sections should reference the workout's focus and duration."""
        mock_generate.side_effect = Exception("timeout")

        state = _make_state(workout_focus="leg day", duration_minutes=60)
        result = await generate_structured_insights_node(state)

        all_content = " ".join(s["content"] for s in result["sections"])
        assert "leg day" in all_content or "60" in all_content

    @patch("services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry")
    async def test_summary_is_valid_json(self, mock_generate):
        """The summary field should be valid JSON matching headline/sections."""
        mock_generate.return_value = _mock_gemini_response(
            parsed_data={"headline": "Go Hard!", "sections": _valid_sections(3)}
        )

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

    @staticmethod
    def _max_output_tokens_in(func):
        """Extract every literal max_output_tokens=N passed inside func's body.

        Resolves the function OBJECT and reads its source via inspect, rather
        than hard-coding a path to services/gemini_service.py. That file is now
        a 43-line backward-compat shim (the implementation moved to
        services/gemini/workout_streaming.py), so the old line-scanner found no
        max_output_tokens at all and the assertion failed on a stale path
        instead of on the real limit. inspect.getsource follows the code
        wherever it lives, so this cannot rot the same way again.
        """
        import ast
        import inspect
        import textwrap

        # Can't textwrap.dedent this: the prompt strings inside these functions
        # contain column-0 lines, so the common prefix is "" and the method's
        # own 4-space indent survives. Re-indent uniformly and wrap in a dummy
        # class instead, which parses regardless of the original base indent.
        src = textwrap.indent(inspect.getsource(func), "    ")
        tree = ast.parse("class _Wrapper:\n" + src)
        found = []
        for node in ast.walk(tree):
            if isinstance(node, ast.keyword) and node.arg == "max_output_tokens":
                if isinstance(node.value, ast.Constant) and isinstance(node.value.value, int):
                    found.append(node.value.value)
        return found

    def test_cached_streaming_token_limit_matches_non_cached(self):
        """
        The cached streaming max_output_tokens must be >= 16384
        to prevent truncation of detailed workouts with set_targets.

        This was the root cause of the production JSON parse error.
        """
        from services.gemini.workout_streaming import WorkoutStreamingMixin

        cached_limits = self._max_output_tokens_in(
            WorkoutStreamingMixin.generate_workout_plan_streaming_cached
        )
        non_cached_limits = self._max_output_tokens_in(
            WorkoutStreamingMixin.generate_workout_plan_streaming
        )

        assert cached_limits, "Could not find max_output_tokens in cached streaming function"
        assert non_cached_limits, "Could not find max_output_tokens in non-cached streaming function"

        cached_token_limit = min(cached_limits)
        assert cached_token_limit >= 16384, (
            f"Cached streaming max_output_tokens={cached_token_limit} is too low. "
            f"Must be >= 16384 to prevent truncation of workouts with set_targets."
        )
        # The name of this test: the cached path must not be capped any lower
        # than the non-cached path it mirrors.
        assert cached_token_limit >= min(non_cached_limits)
