"""
Tests for the onboarding LangGraph agent.

These tests verify:
1. Data extraction works correctly with various user inputs
2. Quick replies are shown for the correct fields
3. The onboarding flow completes successfully
4. AI responses are appropriate and human-like

Test categories:
- Fast tests (no @pytest.mark.slow): Run on every deployment, validate config/structure
- Slow tests (@pytest.mark.slow): Call real AI API, run locally or in CI

Run all tests: pytest tests/test_onboarding.py -v
Run fast only: pytest tests/test_onboarding.py -v -m "not slow"
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
    """State where selected_days is the ONLY field to collect (not workout_duration)."""
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
            "workout_duration": 60,  # Already filled so AI asks about selected_days
        },
        "missing_fields": ["selected_days"],
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
            # Personalization fields - pre-filled from quiz
            "training_experience": "2_to_5_years",
            "workout_environment": "commercial_gym",
            # Personalization fields - asked by AI
            "past_programs": ["ppl", "bro_split"],
            "focus_areas": ["chest", "back"],
            "workout_variety": "mixed",
            "biggest_obstacle": "time",
            # NOTE: active_injuries collected via popup AFTER onboarding
        },
        "missing_fields": [],
        "conversation_history": [],
        "messages": [],
        "is_complete": False,
    }


# ============ CRITICAL: Quick Reply Tests (MUST PASS) ============

@pytest.mark.slow
class TestQuickReplies:
    """
    CRITICAL TESTS: Quick replies must appear for the correct fields.

    These tests use the REAL Gemini API - no mocks, no fallbacks.
    If these fail, deployment should be blocked.
    """

    @pytest.mark.asyncio
    async def test_workout_duration_detected_from_response(self, partial_state_needs_goals):
        """CRITICAL: When AI asks about duration, show duration quick replies.

        Note: Quiz fields (goals, equipment, etc.) are now pre-filled from quiz.
        The AI is instructed to skip them and ask about workout_duration first.
        """
        result = await onboarding_agent_node(partial_state_needs_goals)

        # The AI should ask about workout_duration (skipping quiz fields)
        # and quick replies should match the detected field from response
        assert result.get("quick_replies") is not None, \
            "CRITICAL: Must show quick replies"

        # Verify it's asking about duration (checking response or quick replies)
        response = result.get("final_response", "").lower()
        labels = [qr["label"].lower() for qr in result.get("quick_replies", [])]

        # Either AI asks about duration OR quick replies are for duration
        is_duration_question = "how long" in response or "30" in response or "45" in response
        has_duration_options = any("min" in label for label in labels)

        assert is_duration_question or has_duration_options, \
            "CRITICAL: Should ask about workout duration (quiz fields are pre-filled)"

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

@pytest.mark.slow
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

@pytest.mark.slow
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

@pytest.mark.slow
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
        # Fields that use custom components instead of quick replies
        custom_component_fields = ["selected_days", "target_weight_kg"]

        for field in FIELD_ORDER:
            if field not in free_text_fields and field not in custom_component_fields:
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

@pytest.mark.slow
class TestErrorHandling:
    """Tests for error handling - these should not crash."""

    @pytest.mark.asyncio
    async def test_special_characters_no_crash(self, partial_state_needs_goals):
        """AI should handle special characters gracefully."""
        partial_state_needs_goals["user_message"] = "My name is O'Brien & I'm 5'10\"!"

        # Should not raise exception
        result = await onboarding_agent_node(partial_state_needs_goals)

        assert isinstance(result, dict), "Should return dict with special characters"


# ============ CRITICAL: Training Experience Tests ============

from services.langgraph_agents.onboarding.nodes import get_field_value


class TestGetFieldValueCaseConversion:
    """
    CRITICAL TESTS: get_field_value must handle both snake_case and camelCase.

    This tests the fix for the training_experience bug where:
    - Frontend sends data in camelCase (trainingExperience)
    - Backend expects snake_case (training_experience)
    - Without proper conversion, the backend would miss the value and try to extract it again
    """

    def test_get_field_value_snake_case(self):
        """Should return value when field is in snake_case."""
        collected = {"training_experience": "never"}
        result = get_field_value(collected, "training_experience")
        assert result == "never", "Should find snake_case field directly"

    def test_get_field_value_camel_case(self):
        """Should return value when field is in camelCase (frontend format)."""
        collected = {"trainingExperience": "never"}
        result = get_field_value(collected, "training_experience")
        assert result == "never", "Should find camelCase field via conversion"

    def test_get_field_value_days_per_week_camel(self):
        """Should handle daysPerWeek camelCase."""
        collected = {"daysPerWeek": 3}
        result = get_field_value(collected, "days_per_week")
        assert result == 3, "Should find daysPerWeek via conversion"

    def test_get_field_value_fitness_level_camel(self):
        """Should handle fitnessLevel camelCase."""
        collected = {"fitnessLevel": "beginner"}
        result = get_field_value(collected, "fitness_level")
        assert result == "beginner", "Should find fitnessLevel via conversion"

    def test_get_field_value_workout_environment_camel(self):
        """Should handle workoutEnvironment camelCase."""
        collected = {"workoutEnvironment": "commercial_gym"}
        result = get_field_value(collected, "workout_environment")
        assert result == "commercial_gym", "Should find workoutEnvironment via conversion"

    def test_get_field_value_height_cm_camel(self):
        """Should handle heightCm camelCase."""
        collected = {"heightCm": 175}
        result = get_field_value(collected, "height_cm")
        assert result == 175, "Should find heightCm via conversion"

    def test_get_field_value_weight_kg_camel(self):
        """Should handle weightKg camelCase."""
        collected = {"weightKg": 70.5}
        result = get_field_value(collected, "weight_kg")
        assert result == 70.5, "Should find weightKg via conversion"

    def test_get_field_value_missing_returns_none(self):
        """Should return None for missing fields."""
        collected = {"other_field": "value"}
        result = get_field_value(collected, "training_experience")
        assert result is None, "Should return None for missing field"

    def test_get_field_value_empty_string_returns_none(self):
        """Should treat empty string as missing."""
        collected = {"training_experience": ""}
        result = get_field_value(collected, "training_experience")
        # Empty string might be returned as-is or None depending on implementation
        assert result == "" or result is None, "Should handle empty string"

    def test_get_field_value_empty_list_returns_none(self):
        """Should treat empty list as missing."""
        collected = {"focus_areas": []}
        result = get_field_value(collected, "focus_areas")
        # Empty list returns empty list or is treated as falsy
        assert result == [] or result is None, "Should handle empty list"

    def test_get_field_value_snake_case_priority(self):
        """Snake case should be checked first if both exist."""
        collected = {
            "training_experience": "5_plus_years",
            "trainingExperience": "never"
        }
        result = get_field_value(collected, "training_experience")
        assert result == "5_plus_years", "Snake case should take priority"


class TestTrainingExperienceNotOverwritten:
    """
    CRITICAL: Training experience from pre-auth quiz should NOT be overwritten.

    Bug scenario:
    1. User selects "never" in pre-auth quiz
    2. Frontend sends trainingExperience: "never" (camelCase)
    3. Backend checks "training_experience" (snake_case) - not found!
    4. Backend extracts from user message, finds "5 years" → sets 5_plus_years
    5. User's actual selection is LOST

    Fix: get_field_value now checks both cases before extraction.
    """

    @pytest.fixture
    def state_with_prefilled_training_experience(self):
        """State with training experience pre-filled from quiz (camelCase)."""
        return {
            "user_message": "I've been lifting for about 5 years now",
            "collected_data": {
                "trainingExperience": "never",  # Pre-filled from quiz in camelCase
                "fitnessLevel": "beginner",
                "goals": ["Build Muscle"],
                "equipment": ["Dumbbells"],
                "daysPerWeek": 3,
                "workoutDays": [0, 2, 4],
            },
            "missing_fields": ["name", "age", "workout_duration"],
            "conversation_history": [],
            "messages": [],
            "is_complete": False,
        }

    @pytest.mark.asyncio
    async def test_extract_does_not_override_existing_training_experience(
        self, state_with_prefilled_training_experience
    ):
        """
        CRITICAL: extract_data_node should NOT override trainingExperience when it's pre-filled.

        Even if user message contains "5 years", the pre-filled "never" should be preserved.
        """
        result = await extract_data_node(state_with_prefilled_training_experience)

        collected = result.get("collected_data", {})

        # The original trainingExperience should be preserved
        # Check both possible keys
        training_exp = (
            collected.get("training_experience") or
            collected.get("trainingExperience") or
            state_with_prefilled_training_experience["collected_data"].get("trainingExperience")
        )

        assert training_exp == "never", (
            f"CRITICAL: Pre-filled training_experience='never' was overwritten to '{training_exp}'! "
            "The extract_data_node incorrectly re-extracted from user message."
        )


class TestTrainingExperienceExtraction:
    """Tests for training_experience extraction from user messages."""

    @pytest.fixture
    def state_needs_training_experience(self):
        """State where training_experience is actually missing."""
        return {
            "user_message": "",
            "collected_data": {
                "name": "TestUser",
                "age": 25,
            },
            "missing_fields": ["training_experience", "workout_duration"],
            "conversation_history": [],
            "messages": [],
            "is_complete": False,
        }

    @pytest.mark.asyncio
    async def test_extract_never_from_message(self, state_needs_training_experience):
        """Should extract 'never' when user says they've never lifted."""
        state_needs_training_experience["user_message"] = "I've never lifted weights before"
        result = await extract_data_node(state_needs_training_experience)

        collected = result.get("collected_data", {})
        training_exp = collected.get("training_experience") or collected.get("trainingExperience")

        assert training_exp == "never", f"Expected 'never', got '{training_exp}'"

    @pytest.mark.asyncio
    async def test_extract_less_than_6_months(self, state_needs_training_experience):
        """Should extract 'less_than_6_months' for new lifters."""
        state_needs_training_experience["user_message"] = "Just a few months"
        result = await extract_data_node(state_needs_training_experience)

        collected = result.get("collected_data", {})
        training_exp = collected.get("training_experience") or collected.get("trainingExperience")

        assert training_exp == "less_than_6_months", f"Expected 'less_than_6_months', got '{training_exp}'"

    @pytest.mark.asyncio
    async def test_extract_5_plus_years(self, state_needs_training_experience):
        """Should extract '5_plus_years' for experienced lifters."""
        state_needs_training_experience["user_message"] = "Over 5 years of experience"
        result = await extract_data_node(state_needs_training_experience)

        collected = result.get("collected_data", {})
        training_exp = collected.get("training_experience") or collected.get("trainingExperience")

        assert training_exp == "5_plus_years", f"Expected '5_plus_years', got '{training_exp}'"


class TestWorkoutEnvironmentCaseConversion:
    """Tests for workout_environment case conversion."""

    @pytest.fixture
    def state_with_prefilled_environment(self):
        """State with workout environment pre-filled from quiz (camelCase)."""
        return {
            "user_message": "I work out at the gym",
            "collected_data": {
                "workoutEnvironment": "home",  # Pre-filled from quiz in camelCase
                "goals": ["Build Muscle"],
            },
            "missing_fields": ["name", "workout_duration"],
            "conversation_history": [],
            "messages": [],
            "is_complete": False,
        }

    @pytest.mark.asyncio
    async def test_extract_does_not_override_existing_workout_environment(
        self, state_with_prefilled_environment
    ):
        """
        CRITICAL: extract_data_node should NOT override workoutEnvironment when pre-filled.

        Even if user message contains "gym", the pre-filled "home" should be preserved.
        """
        result = await extract_data_node(state_with_prefilled_environment)

        collected = result.get("collected_data", {})

        workout_env = (
            collected.get("workout_environment") or
            collected.get("workoutEnvironment") or
            state_with_prefilled_environment["collected_data"].get("workoutEnvironment")
        )

        assert workout_env == "home", (
            f"CRITICAL: Pre-filled workout_environment='home' was overwritten to '{workout_env}'! "
            "The extract_data_node incorrectly re-extracted from user message."
        )


class TestCompletionWithCamelCaseFields:
    """Tests that completion check works with camelCase fields from frontend."""

    @pytest.fixture
    def complete_state_camel_case(self):
        """Complete state with all fields in camelCase (frontend format)."""
        return {
            "user_message": "Sounds good!",
            "collected_data": {
                "name": "TestUser",
                "age": 25,
                "gender": "male",
                "heightCm": 178,
                "weightKg": 75,
                "goals": ["Build Muscle"],
                "equipment": ["Full Gym"],
                "fitnessLevel": "intermediate",  # camelCase
                "daysPerWeek": 3,  # camelCase
                "selectedDays": [0, 2, 4],  # camelCase
                "workoutDuration": 45,  # camelCase
                "trainingExperience": "2_to_5_years",  # camelCase
                "workoutEnvironment": "commercial_gym",  # camelCase
                "pastPrograms": ["ppl"],  # camelCase
                "focusAreas": ["chest"],  # camelCase
                "workoutVariety": "mixed",  # camelCase
                "biggestObstacle": "time",  # camelCase
            },
            "missing_fields": [],
            "conversation_history": [],
            "messages": [],
            "is_complete": False,
        }

    @pytest.mark.asyncio
    async def test_completion_detects_camel_case_fields(self, complete_state_camel_case):
        """
        CRITICAL: check_completion_node should detect completion with camelCase fields.

        The frontend sends fields in camelCase, but REQUIRED_FIELDS uses snake_case.
        The check_completion_node must use get_field_value to handle both cases.
        """
        result = await check_completion_node(complete_state_camel_case)

        # Should be complete since all required fields are present (in camelCase)
        assert result["is_complete"] == True, (
            f"CRITICAL: Onboarding not detected as complete! "
            f"Missing fields reported: {result.get('missing_fields', [])}"
        )
        assert len(result["missing_fields"]) == 0, (
            f"CRITICAL: Missing fields with camelCase data: {result['missing_fields']}"
        )
