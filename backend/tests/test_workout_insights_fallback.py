"""
Tests for the workout insights node fallback behavior.

Covers the fix for:
- workout_insights/nodes.py — Non-critical insights feature crashing instead
  of falling back when Gemini structured output fails.

Specifically tests:
- _build_fallback() deterministic output
- Full node fallback chain: structured → json.loads → double-parse → fallback

HOW THESE TESTS CALL THE NODE (updated 2026-07):
The node no longer builds its own `genai.Client()` — it delegates every Gemini
call to the centralized `services.gemini.constants.gemini_generate_with_retry`
helper (semaphore + exponential backoff on transient errors, imported into
`nodes` by name). The old patch target `nodes.genai` no longer exists, so these
tests patch `nodes.gemini_generate_with_retry` instead. Only HOW the node is
driven changed; what each test guarantees is unchanged.
"""
import json
from unittest.mock import AsyncMock, MagicMock, patch


# ============ Helper ============

PATCH_TARGET = "services.langgraph_agents.workout_insights.nodes.gemini_generate_with_retry"


def _make_state(**overrides):
    """Build a minimal WorkoutInsightsState dict for testing."""
    state = {
        "workout_id": "test-123",
        "workout_name": "Upper Body Strength",
        "exercises": [
            {"name": "Bench Press", "sets": 4, "reps": 8, "primary_muscle": "chest"},
            {"name": "Barbell Rows", "sets": 4, "reps": 8, "primary_muscle": "back"},
        ],
        "duration_minutes": 45,
        "workout_type": "strength",
        "difficulty": "medium",
        "user_goals": ["build muscle"],
        "fitness_level": "intermediate",
        "target_muscles": ["chest", "back"],
        "exercise_count": 2,
        "total_sets": 8,
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


def _sections(n=3):
    """n valid AI sections (the node requires >= 3 to accept AI output)."""
    palette = [
        {"icon": "🎯", "title": "Focus", "content": "Upper body power on Bench Press", "color": "cyan"},
        {"icon": "💪", "title": "Volume", "content": "Heavy compound lifts on Barbell Rows", "color": "purple"},
        {"icon": "🔋", "title": "Recovery", "content": "Protein and sleep after this session", "color": "orange"},
        {"icon": "⚡", "title": "Tempo", "content": "Three second lowering on every rep", "color": "green"},
    ]
    return [dict(s) for s in palette[:n]]


# ============ _build_fallback tests ============


class TestBuildFallback:
    """Tests for the _build_fallback deterministic output."""

    async def test_fallback_default_headline(self):
        """When no headline is available, fallback uses its default headline.

        RETIRED ASSERTION: this used to assert "Let's crush this workout!".
        The deterministic fallback's default headline was rewritten to
        "Time to get to work" when the insights prompt was personalized
        (43a496c9). The guarantee under test is unchanged: a total Gemini
        failure still yields the deterministic fallback headline, never a
        crash and never an empty headline.
        """
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        with patch(PATCH_TARGET, new=AsyncMock(side_effect=Exception("fail"))):
            result = await generate_structured_insights_node(_make_state())

        assert result["headline"] == "Time to get to work"

    async def test_fallback_custom_headline(self):
        """When AI returns a headline but insufficient sections, headline is preserved."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        response = _mock_gemini_response(
            parsed_data={"headline": "Go Hard!", "sections": []}
        )
        with patch(PATCH_TARGET, new=AsyncMock(return_value=response)):
            result = await generate_structured_insights_node(_make_state())

        assert result["headline"] == "Go Hard!"

    async def test_fallback_sections_structure(self):
        """Fallback returns 3 sections with icon, title, content, color.

        RETIRED ASSERTION: this used to assert exactly 2 fallback sections.
        The node's own acceptance floor is now 3 sections (AI output with
        fewer is rejected), so the deterministic fallback was widened to 3 —
        a 2-section fallback would not satisfy the node's own contract.
        The guarantee under test is unchanged: every fallback section is fully
        formed (icon/title/content/color) so the UI never renders a blank card.
        """
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        with patch(PATCH_TARGET, new=AsyncMock(side_effect=Exception("fail"))):
            result = await generate_structured_insights_node(_make_state())

        assert len(result["sections"]) == 3
        for section in result["sections"]:
            assert "icon" in section
            assert "title" in section
            assert "content" in section
            assert "color" in section

    async def test_fallback_summary_valid_json(self):
        """Fallback summary field is valid JSON."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        with patch(PATCH_TARGET, new=AsyncMock(side_effect=Exception("fail"))):
            result = await generate_structured_insights_node(_make_state())

        summary = json.loads(result["summary"])
        assert "headline" in summary
        assert "sections" in summary
        assert summary["headline"] == result["headline"]
        assert summary["sections"] == result["sections"]


# ============ Full node fallback chain tests ============


class TestInsightsNodeFallback:
    """Tests for the full fallback chain in generate_structured_insights_node."""

    async def test_structured_output_success(self):
        """response.parsed returns valid model -> uses it directly."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        sections = _sections(3)
        response = _mock_gemini_response(
            parsed_data={"headline": "Crush It!", "sections": sections}
        )
        mock_generate = AsyncMock(return_value=response)
        with patch(PATCH_TARGET, new=mock_generate):
            result = await generate_structured_insights_node(_make_state())

        assert result["headline"] == "Crush It!"
        assert result["sections"] == sections
        assert mock_generate.call_count == 1

    async def test_direct_json_fallback(self):
        """response.parsed=None, response.text is valid JSON -> json.loads works."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        sections = _sections(3)
        valid_json = json.dumps({"headline": "Push Hard!", "sections": sections})
        response = _mock_gemini_response(parsed_data=None, raw_text=valid_json)

        with patch(PATCH_TARGET, new=AsyncMock(return_value=response)):
            result = await generate_structured_insights_node(_make_state())

        assert result["headline"] == "Push Hard!"
        assert result["sections"] == sections

    async def test_double_stringified_json_fallback(self):
        """response.text is double-stringified -> second json.loads works."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        sections = _sections(3)
        inner = {"headline": "Strong!", "sections": sections}
        # Double-stringified: json.loads first gives a string, second gives dict
        double_str = json.dumps(json.dumps(inner))
        response = _mock_gemini_response(parsed_data=None, raw_text=double_str)

        with patch(PATCH_TARGET, new=AsyncMock(return_value=response)):
            result = await generate_structured_insights_node(_make_state())

        assert result["headline"] == "Strong!"
        assert result["sections"] == sections

    async def test_all_retries_fail_returns_fallback(self):
        """Gemini raises after exhausting its retries -> deterministic fallback (no crash).

        RETIRED ASSERTION: this used to assert the node itself issued 3
        generate_content calls (its own hand-rolled `max_retries = 2` loop).
        Retry/backoff now lives in the shared `gemini_generate_with_retry`
        helper, which the node calls exactly once and which raises only after
        its own retries are exhausted. The guarantee under test is unchanged:
        when generation ultimately fails, the node returns the deterministic
        fallback instead of propagating the exception.
        """
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_generate = AsyncMock(side_effect=Exception("API quota exceeded"))
        with patch(PATCH_TARGET, new=mock_generate):
            result = await generate_structured_insights_node(_make_state())

        assert result["headline"] == "Time to get to work"
        assert len(result["sections"]) == 3
        assert mock_generate.call_count == 1

    async def test_insufficient_sections_uses_fallback(self):
        """Parsed JSON has too few sections -> deterministic fallback used.

        RETIRED ASSERTION: the section floor is now 3 (was 2), and the node no
        longer re-prompts Gemini on a thin response (it calls the shared retry
        helper once). The guarantee under test is unchanged: a too-thin AI
        response is never shipped to the user — the fallback fills it out.
        """
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        response = _mock_gemini_response(
            parsed_data={"headline": "One Section!", "sections": _sections(1)}
        )
        mock_generate = AsyncMock(return_value=response)
        with patch(PATCH_TARGET, new=mock_generate):
            result = await generate_structured_insights_node(_make_state())

        assert len(result["sections"]) == 3
        # Fallback sections, not the single AI one
        assert result["sections"][0]["title"] == "Today's Target"
        assert mock_generate.call_count == 1

    async def test_headline_truncation(self):
        """Headline with 7 words -> truncated to 5."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        response = _mock_gemini_response(
            parsed_data={
                "headline": "This Is A Very Long Headline Here",
                "sections": _sections(3),
            }
        )
        with patch(PATCH_TARGET, new=AsyncMock(return_value=response)):
            result = await generate_structured_insights_node(_make_state())

        assert len(result["headline"].split()) <= 5
        assert result["headline"] == "This Is A Very Long"

    async def test_content_truncation(self):
        """Over-long section content is word-capped; short content is left alone.

        RETIRED ASSERTION: the cap used to be 10 words. It was raised to 36
        because a personalized PR/progressive-overload section legitimately
        cites weights and reps ("You pressed 175lb x 5 on Bench last session —
        open with 180lb x 5 today...") and was being cut mid-sentence at 10
        words. The guarantee under test is unchanged: content is bounded so a
        rambling model response can't overflow the insight card, and content
        already within the bound is returned verbatim.
        """
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        long_content = " ".join(f"word{i}" for i in range(1, 41))  # 40 words
        sections = _sections(3)
        sections[0]["content"] = long_content
        sections[1]["content"] = "Short"

        response = _mock_gemini_response(
            parsed_data={"headline": "Go!", "sections": sections}
        )
        with patch(PATCH_TARGET, new=AsyncMock(return_value=response)):
            result = await generate_structured_insights_node(_make_state())

        assert len(result["sections"][0]["content"].split()) == 36
        assert result["sections"][0]["content"] == " ".join(f"word{i}" for i in range(1, 37))
        assert result["sections"][1]["content"] == "Short"
