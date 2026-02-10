"""
Tests for the workout insights node fallback behavior.

Covers the fix for:
- workout_insights/nodes.py — Non-critical insights feature crashing instead
  of falling back when Gemini structured output fails.

Specifically tests:
- _build_fallback() deterministic output
- Full node fallback chain: structured → json.loads → double-parse → fallback
"""
import json
from unittest.mock import AsyncMock, MagicMock, patch


# ============ Helper ============


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


# ============ _build_fallback tests ============


class TestBuildFallback:
    """Tests for the _build_fallback deterministic output."""

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_fallback_default_headline(self, mock_settings, mock_genai):
        """When no headline provided, fallback uses default."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(
            side_effect=Exception("fail")
        )
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)
        assert result["headline"] == "Let's crush this workout!"

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_fallback_custom_headline(self, mock_settings, mock_genai):
        """When AI returns a headline but insufficient sections, headline is preserved."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={"headline": "Go Hard!", "sections": []}
        )
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)
        assert result["headline"] == "Go Hard!"

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_fallback_sections_structure(self, mock_settings, mock_genai):
        """Fallback returns 2 sections with icon, title, content, color."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(
            side_effect=Exception("fail")
        )
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["sections"]) == 2
        for section in result["sections"]:
            assert "icon" in section
            assert "title" in section
            assert "content" in section
            assert "color" in section

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_fallback_summary_valid_json(self, mock_settings, mock_genai):
        """Fallback summary field is valid JSON."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(
            side_effect=Exception("fail")
        )
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        summary = json.loads(result["summary"])
        assert "headline" in summary
        assert "sections" in summary


# ============ Full node fallback chain tests ============


class TestInsightsNodeFallback:
    """Tests for the full fallback chain in generate_structured_insights_node."""

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_structured_output_success(self, mock_settings, mock_genai):
        """response.parsed returns valid model -> uses it directly."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

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
        assert mock_client.aio.models.generate_content.call_count == 1

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_direct_json_fallback(self, mock_settings, mock_genai):
        """response.parsed=None, response.text is valid JSON -> json.loads works."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        valid_json = json.dumps({
            "headline": "Push Hard!",
            "sections": [
                {"icon": "🎯", "title": "Focus", "content": "Upper body power", "color": "cyan"},
                {"icon": "💪", "title": "Volume", "content": "Heavy compound lifts", "color": "purple"},
            ],
        })
        response = _mock_gemini_response(parsed_data=None, raw_text=valid_json)
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert result["headline"] == "Push Hard!"
        assert len(result["sections"]) == 2

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_double_stringified_json_fallback(self, mock_settings, mock_genai):
        """response.text is double-stringified -> second json.loads works."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        inner = {
            "headline": "Strong!",
            "sections": [
                {"icon": "🎯", "title": "Focus", "content": "Upper body", "color": "cyan"},
                {"icon": "💪", "title": "Volume", "content": "Max effort", "color": "purple"},
            ],
        }
        # Double-stringified: json.loads first gives a string, second gives dict
        double_str = json.dumps(json.dumps(inner))
        response = _mock_gemini_response(parsed_data=None, raw_text=double_str)
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert result["headline"] == "Strong!"
        assert len(result["sections"]) == 2

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_all_retries_fail_returns_fallback(self, mock_settings, mock_genai):
        """All 3 attempts raise -> deterministic fallback returned (no crash)."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(
            side_effect=Exception("API quota exceeded")
        )
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert result["headline"] == "Let's crush this workout!"
        assert len(result["sections"]) == 2
        # initial + 2 retries = 3 calls
        assert mock_client.aio.models.generate_content.call_count == 3

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_insufficient_sections_uses_fallback(self, mock_settings, mock_genai):
        """Parsed JSON has 1 section after all retries -> fallback used."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={
                "headline": "One Section!",
                "sections": [
                    {"icon": "🎯", "title": "Focus", "content": "Test", "color": "cyan"},
                ],
            }
        )
        mock_client = MagicMock()
        mock_client.aio.models.generate_content = AsyncMock(return_value=response)
        mock_genai.Client.return_value = mock_client

        state = _make_state()
        result = await generate_structured_insights_node(state)

        assert len(result["sections"]) == 2
        # All retries exhausted (1 section each time)
        assert mock_client.aio.models.generate_content.call_count == 3

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_headline_truncation(self, mock_settings, mock_genai):
        """Headline with 7 words -> truncated to 5."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"

        response = _mock_gemini_response(
            parsed_data={
                "headline": "This Is A Very Long Headline Here",
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
        assert result["headline"] == "This Is A Very Long"

    @patch("services.langgraph_agents.workout_insights.nodes.genai")
    @patch("services.langgraph_agents.workout_insights.nodes.settings")
    async def test_content_truncation(self, mock_settings, mock_genai):
        """Section content with 12 words -> truncated to 10."""
        from services.langgraph_agents.workout_insights.nodes import generate_structured_insights_node

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
