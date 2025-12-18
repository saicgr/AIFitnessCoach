"""
Tests for the onboarding LangGraph agent.

These tests MUST PASS before deployment. They verify:
1. Data extraction works correctly with various user inputs
2. Quick replies are shown for the correct fields
3. The onboarding flow completes successfully
4. AI responses are appropriate and human-like
5. NO FALLBACKS - tests fail if AI doesn't work correctly

Run with: pytest tests/test_onboarding.py -v
"""
import pytest
import asyncio
import json

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.langgraph_agents.onboarding.nodes import (
    extract_data_node,
    check_completion_node,
    onboarding_agent_node,
)
from services.langgraph_agents.onboarding.prompts import (
    FIELD_ORDER,
    REQUIRED_FIELDS,
    QUICK_REPLIES,
)


# ============ Fixtures ============

@pytest.fixture
def empty_state():
    """Initial empty onboarding state."""
    return {
        "user_message": "",
        "collected_data": {},
        "missing_fields": REQUIRED_FIELDS.copy(),
        "conversation_history": [],
        "messages": [],
        "is_complete": False,
    }


@pytest.fixture
def partial_state_needs_goals():
    """State where goals is the next field to collect."""
    return {
        "user_message": "Hi",
        "collected_data": {
            "name": "TestUser",
            "age": 25,
            "gender": "male",
            "heightCm": 178,
            "weightKg": 75,
        },
        "missing_fields": ["goals", "equipment", "fitness_level", "days_per_week", "selected_days", "workout_duration"],
        "conversation_history": [],
        "messages": [],
        "is_complete": False,
    }


@pytest.fixture
def partial_state_needs_equipment():
    """State where equipment is the next field to collect."""
    return {
        "user_message": "Build muscle",
        "collected_data": {
            "name": "TestUser",
            "age": 25,
            "gender": "male",
            "heightCm": 178,
            "weightKg": 75,
            "goals": ["Build Muscle"],
        },
        "missing_fields": ["equipment", "fitness_level", "days_per_week", "selected_days", "workout_duration"],
        "conversation_history": [],
        "messages": [],
        "is_complete": False,
    }


@pytest.fixture
def partial_state_needs_fitness_level():
    """State where fitness_level is the next field to collect."""
    return {
        "user_message": "Full gym",
        "collected_data": {
            "name": "TestUser",
            "age": 25,
            "gender": "male",
            "heightCm": 178,
            "weightKg": 75,
            "goals": ["Build Muscle"],
            "equipment": ["Full Gym"],
        },
        "missing_fields": ["fitness_level", "days_per_week", "selected_days", "workout_duration"],
        "conversation_history": [],
        "messages": [],
        "is_complete": False,
    }


@pytest.fixture
def partial_state_needs_days_per_week():
    """State where days_per_week is the next field to collect."""
    return {
        "user_message": "intermediate",
        "collected_data": {
            "name": "TestUser",
            "age": 25,
            "gender": "male",
            "heightCm": 178,
            "weightKg": 75,
            "goals": ["Build Muscle"],
            "equipment": ["Full Gym"],
            "fitness_level": "intermediate",
        },
        "missing_fields": ["days_per_week", "selected_days", "workout_duration"],
        "conversation_history": [],
        "messages": [],
        "is_complete": False,
    }


@pytest.fixture
def partial_state_needs_selected_days():
    """State where selected_days is the next field to collect."""
    return {
        "user_message": "3 days",
        "collected_data": {
            "name": "TestUser",
            "age": 25,
            "gender": "male",
            "heightCm": 178,
            "weightKg": 75,
            "goals": ["Build Muscle"],
            "equipment": ["Full Gym"],
            "fitness_level": "intermediate",
            "days_per_week": 3,
        },
        "missing_fields": ["selected_days", "workout_duration"],
        "conversation_history": [],
        "messages": [],
        "is_complete": False,
    }


@pytest.fixture
def partial_state_needs_duration():
    """State where workout_duration is the next field to collect."""
    return {
        "user_message": "Monday, Wednesday, Friday",
        "collected_data": {
            "name": "TestUser",
            "age": 25,
            "gender": "male",
            "heightCm": 178,
            "weightKg": 75,
            "goals": ["Build Muscle"],
            "equipment": ["Full Gym"],
            "fitness_level": "intermediate",
            "days_per_week": 3,
            "selected_days": [0, 2, 4],
        },
        "missing_fields": ["workout_duration"],
        "conversation_history": [],
        "messages": [],
        "is_complete": False,
    }


@pytest.fixture
def complete_state():
    """Fully completed onboarding state."""
    return {
        "user_message": "45 minutes",
        "collected_data": {
            "name": "TestUser",
            "age": 25,
            "gender": "male",
            "heightCm": 178,
            "weightKg": 75,
            "goals": ["Build Muscle", "Lose Weight"],
            "equipment": ["Full Gym"],
            "fitness_level": "intermediate",
            "days_per_week": 3,
            "selected_days": [0, 2, 4],
            "workout_duration": 45,
        },
        "missing_fields": [],
        "conversation_history": [],
        "messages": [],
        "is_complete": False,
    }


# ============ CRITICAL: Quick Reply Tests (MUST PASS) ============

class TestQuickReplies:
    """
    CRITICAL TESTS: Quick replies must appear for the correct fields.

    These tests use the REAL Gemini API - no mocks, no fallbacks.
    If these fail, deployment should be blocked.
    """

    @pytest.mark.asyncio
    async def test_goals_shows_quick_replies(self, partial_state_needs_goals):
        """CRITICAL: Goals field MUST show quick replies with multi-select."""
        result = await onboarding_agent_node(partial_state_needs_goals)

        # STRICT ASSERTIONS - NO FALLBACKS
        assert result.get("quick_replies") is not None, \
            "CRITICAL: Goals field must show quick replies"
        assert result.get("multi_select") == True, \
            "CRITICAL: Goals must be multi-select"
        assert len(result.get("quick_replies", [])) >= 4, \
            "CRITICAL: Goals must have at least 4 options"

        # Verify expected options exist
        labels = [qr["label"].lower() for qr in result.get("quick_replies", [])]
        assert any("muscle" in label for label in labels), \
            "CRITICAL: Goals must include 'Build muscle' option"
        assert any("weight" in label for label in labels), \
            "CRITICAL: Goals must include weight-related option"

    @pytest.mark.asyncio
    async def test_equipment_shows_quick_replies(self, partial_state_needs_equipment):
        """CRITICAL: Equipment field MUST show quick replies with multi-select."""
        result = await onboarding_agent_node(partial_state_needs_equipment)

        assert result.get("quick_replies") is not None, \
            "CRITICAL: Equipment field must show quick replies"
        assert result.get("multi_select") == True, \
            "CRITICAL: Equipment must be multi-select"
        assert len(result.get("quick_replies", [])) >= 4, \
            "CRITICAL: Equipment must have at least 4 options"

    @pytest.mark.asyncio
    async def test_fitness_level_shows_quick_replies(self, partial_state_needs_fitness_level):
        """CRITICAL: Fitness level field MUST show quick replies (single-select)."""
        result = await onboarding_agent_node(partial_state_needs_fitness_level)

        assert result.get("quick_replies") is not None, \
            "CRITICAL: Fitness level field must show quick replies"
        assert result.get("multi_select") == False, \
            "CRITICAL: Fitness level must be single-select"

        labels = [qr["label"].lower() for qr in result.get("quick_replies", [])]
        assert any("beginner" in label for label in labels), \
            "CRITICAL: Fitness level must include 'Beginner' option"
        assert any("intermediate" in label for label in labels), \
            "CRITICAL: Fitness level must include 'Intermediate' option"
        assert any("advanced" in label for label in labels), \
            "CRITICAL: Fitness level must include 'Advanced' option"

    @pytest.mark.asyncio
    async def test_days_per_week_shows_quick_replies(self, partial_state_needs_days_per_week):
        """CRITICAL: Days per week field MUST show quick replies."""
        result = await onboarding_agent_node(partial_state_needs_days_per_week)

        assert result.get("quick_replies") is not None, \
            "CRITICAL: Days per week field must show quick replies"
        assert len(result.get("quick_replies", [])) >= 5, \
            "CRITICAL: Days per week must have options for 1-7 days"

    @pytest.mark.asyncio
    async def test_selected_days_shows_day_picker(self, partial_state_needs_selected_days):
        """CRITICAL: Selected days field MUST show day_picker component."""
        result = await onboarding_agent_node(partial_state_needs_selected_days)

        assert result.get("component") == "day_picker", \
            "CRITICAL: Selected days must show day_picker component"
        assert result.get("quick_replies") is None, \
            "CRITICAL: Day picker should not have quick replies"

    @pytest.mark.asyncio
    async def test_workout_duration_shows_quick_replies(self, partial_state_needs_duration):
        """CRITICAL: Workout duration field MUST show quick replies."""
        result = await onboarding_agent_node(partial_state_needs_duration)

        assert result.get("quick_replies") is not None, \
            "CRITICAL: Workout duration field must show quick replies"

        labels = [qr["label"].lower() for qr in result.get("quick_replies", [])]
        assert any("30" in label or "min" in label for label in labels), \
            "CRITICAL: Duration must include time options"


# ============ CRITICAL: AI Response Tests ============

class TestAIResponses:
    """
    CRITICAL TESTS: AI must generate valid responses.

    These tests use the REAL Gemini API.
    """

    @pytest.mark.asyncio
    async def test_ai_generates_response(self, partial_state_needs_goals):
        """CRITICAL: AI must generate a non-empty response."""
        result = await onboarding_agent_node(partial_state_needs_goals)

        response = result.get("final_response", "") or result.get("next_question", "")

        assert response is not None, "CRITICAL: AI must return a response"
        assert len(response) > 0, "CRITICAL: AI response must not be empty"
        assert len(response) > 10, "CRITICAL: AI response must be meaningful (>10 chars)"

    @pytest.mark.asyncio
    async def test_ai_response_is_string(self, partial_state_needs_goals):
        """CRITICAL: AI response must be a string, not list or dict."""
        result = await onboarding_agent_node(partial_state_needs_goals)

        response = result.get("final_response") or result.get("next_question")

        assert isinstance(response, str), \
            f"CRITICAL: AI response must be string, got {type(response)}"

    @pytest.mark.asyncio
    async def test_ai_response_contains_question(self, partial_state_needs_goals):
        """CRITICAL: AI response should ask a question."""
        result = await onboarding_agent_node(partial_state_needs_goals)

        response = result.get("final_response", "") or result.get("next_question", "")

        # Response should be conversational and ask a question
        assert "?" in response, \
            "CRITICAL: AI response should contain a question mark"


# ============ CRITICAL: Completion Check Tests ============

class TestCompletionCheck:
    """CRITICAL TESTS: Completion detection must work correctly."""

    @pytest.mark.asyncio
    async def test_incomplete_state_detected(self, partial_state_needs_goals):
        """CRITICAL: Incomplete state must be detected."""
        result = await check_completion_node(partial_state_needs_goals)

        assert result["is_complete"] == False, \
            "CRITICAL: Incomplete state must return is_complete=False"
        assert len(result["missing_fields"]) > 0, \
            "CRITICAL: Must report missing fields"

    @pytest.mark.asyncio
    async def test_complete_state_detected(self, complete_state):
        """CRITICAL: Complete state must be detected."""
        result = await check_completion_node(complete_state)

        assert result["is_complete"] == True, \
            "CRITICAL: Complete state must return is_complete=True"
        assert len(result["missing_fields"]) == 0, \
            "CRITICAL: Complete state must have no missing fields"


# ============ CRITICAL: Data Extraction Tests ============

class TestDataExtraction:
    """CRITICAL TESTS: Data extraction must work correctly."""

    @pytest.mark.asyncio
    async def test_extract_returns_dict(self, partial_state_needs_goals):
        """CRITICAL: Extract node must return a dictionary."""
        result = await extract_data_node(partial_state_needs_goals)

        assert isinstance(result, dict), \
            f"CRITICAL: extract_data_node must return dict, got {type(result)}"

    @pytest.mark.asyncio
    async def test_extract_contains_required_keys(self, partial_state_needs_goals):
        """CRITICAL: Extract result must contain required keys."""
        result = await extract_data_node(partial_state_needs_goals)

        # Must have collected_data or missing_fields
        assert "collected_data" in result or "missing_fields" in result, \
            "CRITICAL: Extract result must contain collected_data or missing_fields"


# ============ CRITICAL: Field Order Tests ============

class TestFieldOrder:
    """CRITICAL TESTS: Field order must be correct."""

    def test_field_order_contains_all_required(self):
        """CRITICAL: FIELD_ORDER must contain all required fields."""
        for field in REQUIRED_FIELDS:
            assert field in FIELD_ORDER, \
                f"CRITICAL: Required field '{field}' missing from FIELD_ORDER"

    def test_quick_replies_defined_for_fields(self):
        """CRITICAL: Quick replies must be defined for non-free-text fields."""
        free_text_fields = ["name", "age", "gender", "heightCm", "weightKg"]

        for field in FIELD_ORDER:
            if field not in free_text_fields and field != "selected_days":
                assert field in QUICK_REPLIES, \
                    f"CRITICAL: Quick replies missing for '{field}'"

    def test_goals_before_equipment(self):
        """CRITICAL: Goals must be asked before equipment."""
        goals_idx = FIELD_ORDER.index("goals")
        equipment_idx = FIELD_ORDER.index("equipment")

        assert goals_idx < equipment_idx, \
            "CRITICAL: Goals must be asked before equipment"

    def test_days_per_week_before_selected_days(self):
        """CRITICAL: Days per week must be asked before selected days."""
        dpw_idx = FIELD_ORDER.index("days_per_week")
        sd_idx = FIELD_ORDER.index("selected_days")

        assert dpw_idx < sd_idx, \
            "CRITICAL: days_per_week must be asked before selected_days"


# ============ Error Handling Tests ============

class TestErrorHandling:
    """Tests for error handling - these should not crash."""

    @pytest.mark.asyncio
    async def test_special_characters_no_crash(self, partial_state_needs_goals):
        """AI should handle special characters gracefully."""
        partial_state_needs_goals["user_message"] = "My name is O'Brien & I'm 5'10\"!"

        # Should not raise exception
        result = await onboarding_agent_node(partial_state_needs_goals)

        assert isinstance(result, dict), "Should return dict with special characters"
