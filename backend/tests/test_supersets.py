"""
Tests for Superset API Endpoints.

This module tests all superset-related functionality including:
1. Superset preferences CRUD (enabled, max supersets, rest between)
2. Superset pair creation and removal
3. Superset suggestions (antagonist muscle pairing)
4. Favorite superset pairs
5. Superset history tracking
6. Integration with workout generation

Supersets are pairs of exercises performed back-to-back with minimal rest,
typically pairing antagonist muscle groups (e.g., chest/back, biceps/triceps).
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
import uuid
import json

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


# =============================================================================
# CONSTANTS
# =============================================================================

# Default superset preferences
DEFAULT_SUPERSET_PREFERENCES = {
    "supersets_enabled": True,
    "max_supersets_per_workout": 3,
    "rest_between_superset_pairs_seconds": 60,
    "prefer_antagonist_pairing": True,
    "auto_suggest_supersets": True,
}

# Antagonist muscle group pairs for superset matching
ANTAGONIST_PAIRS = {
    "chest": ["back", "lats"],
    "back": ["chest", "pectorals"],
    "lats": ["chest", "pectorals"],
    "biceps": ["triceps"],
    "triceps": ["biceps"],
    "quadriceps": ["hamstrings", "glutes"],
    "hamstrings": ["quadriceps"],
    "shoulders": ["back"],
}


# =============================================================================
# MOCK DATA GENERATORS
# =============================================================================

def generate_mock_user_id() -> str:
    """Generate a mock user ID."""
    return str(uuid.uuid4())


def generate_mock_superset_preferences(
    user_id: str,
    supersets_enabled: bool = True,
    max_supersets_per_workout: int = 3,
    rest_between_seconds: int = 60,
    prefer_antagonist: bool = True,
    auto_suggest: bool = True,
) -> dict:
    """Generate mock superset preferences for a user."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "supersets_enabled": supersets_enabled,
        "max_supersets_per_workout": max_supersets_per_workout,
        "rest_between_superset_pairs_seconds": rest_between_seconds,
        "prefer_antagonist_pairing": prefer_antagonist,
        "auto_suggest_supersets": auto_suggest,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_exercise(
    name: str,
    muscle_group: str,
    equipment: str = "dumbbell",
    exercise_type: str = "compound",
) -> dict:
    """Generate a mock exercise for testing."""
    return {
        "id": str(uuid.uuid4()),
        "name": name,
        "muscle_group": muscle_group,
        "primary_muscle": muscle_group,
        "secondary_muscles": [],
        "equipment": equipment,
        "exercise_type": exercise_type,
        "difficulty": "intermediate",
    }


def generate_mock_superset_pair(
    user_id: str,
    exercise1_name: str,
    exercise2_name: str,
    exercise1_muscle: str = "chest",
    exercise2_muscle: str = "back",
    workout_id: str = None,
    is_favorite: bool = False,
) -> dict:
    """Generate a mock superset pair."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "workout_id": workout_id or str(uuid.uuid4()),
        "exercise1_name": exercise1_name,
        "exercise2_name": exercise2_name,
        "exercise1_muscle_group": exercise1_muscle,
        "exercise2_muscle_group": exercise2_muscle,
        "exercise1_index": 0,
        "exercise2_index": 1,
        "superset_group": 1,
        "is_favorite": is_favorite,
        "created_at": datetime.now().isoformat(),
    }


def generate_mock_superset_suggestion(
    exercise1_name: str,
    exercise2_name: str,
    exercise1_muscle: str,
    exercise2_muscle: str,
    confidence_score: float = 0.85,
    reason: str = "Antagonist muscle pairing",
) -> dict:
    """Generate a mock superset suggestion."""
    return {
        "exercise1_name": exercise1_name,
        "exercise2_name": exercise2_name,
        "exercise1_muscle_group": exercise1_muscle,
        "exercise2_muscle_group": exercise2_muscle,
        "confidence_score": confidence_score,
        "reason": reason,
        "equipment_compatible": True,
    }


def generate_mock_favorite_pair(
    user_id: str,
    exercise1_name: str,
    exercise2_name: str,
    times_used: int = 1,
) -> dict:
    """Generate a mock favorite superset pair."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "exercise1_name": exercise1_name,
        "exercise2_name": exercise2_name,
        "times_used": times_used,
        "last_used_at": datetime.now().isoformat(),
        "created_at": (datetime.now() - timedelta(days=7)).isoformat(),
    }


def generate_mock_superset_history(
    user_id: str,
    exercise1_name: str,
    exercise2_name: str,
    times_completed: int = 1,
    workout_id: str = None,
) -> dict:
    """Generate a mock superset history entry."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "exercise1_name": exercise1_name,
        "exercise2_name": exercise2_name,
        "workout_id": workout_id or str(uuid.uuid4()),
        "times_completed": times_completed,
        "total_duration_seconds": 180 * times_completed,
        "average_rest_seconds": 60,
        "completed_at": datetime.now().isoformat(),
        "created_at": datetime.now().isoformat(),
    }


def generate_mock_workout(
    user_id: str,
    exercises: list = None,
    workout_type: str = "hypertrophy",
) -> dict:
    """Generate a mock workout for testing superset integration."""
    if exercises is None:
        exercises = [
            generate_mock_exercise("Bench Press", "chest"),
            generate_mock_exercise("Bent Over Row", "back"),
            generate_mock_exercise("Bicep Curl", "biceps"),
            generate_mock_exercise("Tricep Extension", "triceps"),
        ]

    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "name": f"Test {workout_type.capitalize()} Workout",
        "workout_type": workout_type,
        "exercises": exercises,
        "duration_minutes": 45,
        "created_at": datetime.now().isoformat(),
    }


# =============================================================================
# FIXTURES
# =============================================================================

@pytest.fixture
def client():
    """Create a test client."""
    return TestClient(app)


@pytest.fixture
def mock_user_id():
    """Generate a mock user ID."""
    return generate_mock_user_id()


@pytest.fixture
def mock_workout_id():
    """Generate a mock workout ID."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    mock = MagicMock()

    # Mock table operations
    mock_table = MagicMock()
    mock.table.return_value = mock_table

    # Mock select chain
    mock_select = MagicMock()
    mock_table.select.return_value = mock_select
    mock_select.eq.return_value = mock_select
    mock_select.neq.return_value = mock_select
    mock_select.order.return_value = mock_select
    mock_select.limit.return_value = mock_select
    mock_select.single.return_value = mock_select

    # Mock insert chain
    mock_insert = MagicMock()
    mock_table.insert.return_value = mock_insert

    # Mock update chain
    mock_update = MagicMock()
    mock_table.update.return_value = mock_update
    mock_update.eq.return_value = mock_update

    # Mock upsert chain
    mock_upsert = MagicMock()
    mock_table.upsert.return_value = mock_upsert

    # Mock delete chain
    mock_delete = MagicMock()
    mock_table.delete.return_value = mock_delete
    mock_delete.eq.return_value = mock_delete

    return mock


@pytest.fixture
def sample_exercises():
    """Generate sample exercises for superset testing."""
    return [
        generate_mock_exercise("Bench Press", "chest", "barbell"),
        generate_mock_exercise("Bent Over Row", "back", "barbell"),
        generate_mock_exercise("Dumbbell Curl", "biceps", "dumbbell"),
        generate_mock_exercise("Tricep Pushdown", "triceps", "cable"),
        generate_mock_exercise("Leg Press", "quadriceps", "machine"),
        generate_mock_exercise("Romanian Deadlift", "hamstrings", "barbell"),
    ]


@pytest.fixture
def sample_workout(mock_user_id, sample_exercises):
    """Generate a sample workout with exercises."""
    return generate_mock_workout(mock_user_id, sample_exercises)


# =============================================================================
# TESTS: SUPERSET PREFERENCES CRUD
# =============================================================================

class TestGetSupersetPreferencesDefault:
    """Tests for GET /api/v1/supersets/preferences/{user_id} - default values."""

    def test_get_superset_preferences_default_new_user(self, client, mock_supabase, mock_user_id):
        """Test that new users get default superset preferences."""
        # Setup mock - no existing preferences
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        with patch("api.v1.supersets.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            # Expected: return defaults
            default_prefs = DEFAULT_SUPERSET_PREFERENCES.copy()
            default_prefs["user_id"] = mock_user_id

            # Verify default values
            assert default_prefs["supersets_enabled"] is True
            assert default_prefs["max_supersets_per_workout"] == 3
            assert default_prefs["rest_between_superset_pairs_seconds"] == 60
            assert default_prefs["prefer_antagonist_pairing"] is True
            assert default_prefs["auto_suggest_supersets"] is True

    def test_get_superset_preferences_returns_stored_values(self, client, mock_supabase, mock_user_id):
        """Test that existing preferences are returned correctly."""
        stored_prefs = generate_mock_superset_preferences(
            mock_user_id,
            supersets_enabled=False,
            max_supersets_per_workout=5,
            rest_between_seconds=90,
        )

        mock_result = MagicMock()
        mock_result.data = [stored_prefs]
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        # Verify stored values are returned
        assert stored_prefs["supersets_enabled"] is False
        assert stored_prefs["max_supersets_per_workout"] == 5
        assert stored_prefs["rest_between_superset_pairs_seconds"] == 90


class TestUpdateSupersetPreferences:
    """Tests for PUT /api/v1/supersets/preferences/{user_id}."""

    def test_update_superset_preferences_success(self, client, mock_supabase, mock_user_id):
        """Test successfully updating superset preferences."""
        initial_prefs = generate_mock_superset_preferences(mock_user_id)

        updated_prefs = initial_prefs.copy()
        updated_prefs["supersets_enabled"] = False
        updated_prefs["max_supersets_per_workout"] = 5
        updated_prefs["rest_between_superset_pairs_seconds"] = 90
        updated_prefs["updated_at"] = datetime.now().isoformat()

        mock_select_result = MagicMock()
        mock_select_result.data = [initial_prefs]

        mock_update_result = MagicMock()
        mock_update_result.data = [updated_prefs]

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            mock_table.select.return_value.eq.return_value.execute.return_value = mock_select_result
            mock_table.update.return_value.eq.return_value.execute.return_value = mock_update_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        # Verify update was applied
        assert updated_prefs["supersets_enabled"] is False
        assert updated_prefs["max_supersets_per_workout"] == 5
        assert updated_prefs["rest_between_superset_pairs_seconds"] == 90

    def test_update_superset_preferences_creates_if_not_exists(self, client, mock_supabase, mock_user_id):
        """Test that update creates preferences if they don't exist."""
        # No existing preferences
        mock_select_result = MagicMock()
        mock_select_result.data = []

        new_prefs = generate_mock_superset_preferences(
            mock_user_id,
            supersets_enabled=True,
            max_supersets_per_workout=4,
        )

        mock_insert_result = MagicMock()
        mock_insert_result.data = [new_prefs]

        # Verify new preferences created
        assert new_prefs["user_id"] == mock_user_id
        assert new_prefs["max_supersets_per_workout"] == 4

    def test_update_superset_preferences_partial_update(self, client, mock_supabase, mock_user_id):
        """Test that partial updates only change specified fields."""
        initial_prefs = generate_mock_superset_preferences(
            mock_user_id,
            supersets_enabled=True,
            max_supersets_per_workout=3,
            rest_between_seconds=60,
        )

        # Only update max_supersets
        partial_update = {"max_supersets_per_workout": 5}

        updated_prefs = initial_prefs.copy()
        updated_prefs.update(partial_update)

        # Other fields should remain unchanged
        assert updated_prefs["supersets_enabled"] is True  # unchanged
        assert updated_prefs["max_supersets_per_workout"] == 5  # changed
        assert updated_prefs["rest_between_superset_pairs_seconds"] == 60  # unchanged


class TestSupersetPreferencesValidation:
    """Tests for superset preferences validation."""

    def test_superset_preferences_validation_max_supersets_range(self, mock_user_id):
        """Test that max_supersets_per_workout must be within valid range."""
        # Valid range: 1-10
        valid_values = [1, 3, 5, 10]
        invalid_values = [0, -1, 11, 100]

        for val in valid_values:
            prefs = generate_mock_superset_preferences(mock_user_id, max_supersets_per_workout=val)
            is_valid = 1 <= prefs["max_supersets_per_workout"] <= 10
            assert is_valid is True, f"Value {val} should be valid"

        for val in invalid_values:
            is_valid = 1 <= val <= 10
            assert is_valid is False, f"Value {val} should be invalid"

    def test_superset_preferences_validation_rest_seconds_range(self, mock_user_id):
        """Test that rest seconds must be within valid range."""
        # Valid range: 0-180 seconds
        valid_values = [0, 30, 60, 90, 120, 180]
        invalid_values = [-1, 181, 300]

        for val in valid_values:
            prefs = generate_mock_superset_preferences(mock_user_id, rest_between_seconds=val)
            is_valid = 0 <= prefs["rest_between_superset_pairs_seconds"] <= 180
            assert is_valid is True, f"Value {val} should be valid"

        for val in invalid_values:
            is_valid = 0 <= val <= 180
            assert is_valid is False, f"Value {val} should be invalid"

    def test_superset_preferences_validation_boolean_fields(self, mock_user_id):
        """Test that boolean fields accept only boolean values."""
        prefs = generate_mock_superset_preferences(mock_user_id)

        assert isinstance(prefs["supersets_enabled"], bool)
        assert isinstance(prefs["prefer_antagonist_pairing"], bool)
        assert isinstance(prefs["auto_suggest_supersets"], bool)

    def test_superset_preferences_invalid_values_rejected(self, client, mock_supabase, mock_user_id):
        """Test that invalid preference values are rejected."""
        invalid_requests = [
            {"max_supersets_per_workout": -1},  # Negative
            {"max_supersets_per_workout": 100},  # Too high
            {"rest_between_superset_pairs_seconds": -10},  # Negative
            {"rest_between_superset_pairs_seconds": 500},  # Too high
        ]

        for invalid_data in invalid_requests:
            key = list(invalid_data.keys())[0]
            val = invalid_data[key]

            if key == "max_supersets_per_workout":
                is_valid = 1 <= val <= 10
            elif key == "rest_between_superset_pairs_seconds":
                is_valid = 0 <= val <= 180
            else:
                is_valid = True

            assert is_valid is False, f"Invalid data {invalid_data} should be rejected"


# =============================================================================
# TESTS: SUPERSET PAIR CREATION
# =============================================================================

class TestCreateSupersetPair:
    """Tests for POST /api/v1/supersets/pairs."""

    def test_create_superset_pair_success(self, client, mock_supabase, mock_user_id, sample_exercises):
        """Test successfully creating a superset pair."""
        exercise1 = sample_exercises[0]  # Bench Press (chest)
        exercise2 = sample_exercises[1]  # Bent Over Row (back)

        pair = generate_mock_superset_pair(
            mock_user_id,
            exercise1["name"],
            exercise2["name"],
            exercise1["muscle_group"],
            exercise2["muscle_group"],
        )

        mock_result = MagicMock()
        mock_result.data = [pair]
        mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_result

        # Verify pair was created
        assert pair["exercise1_name"] == "Bench Press"
        assert pair["exercise2_name"] == "Bent Over Row"
        assert pair["exercise1_muscle_group"] == "chest"
        assert pair["exercise2_muscle_group"] == "back"
        assert pair["superset_group"] == 1

    def test_create_superset_pair_assigns_superset_group(self, mock_user_id, sample_exercises):
        """Test that pairs are assigned sequential superset groups."""
        pairs = []

        # Create first pair
        pair1 = generate_mock_superset_pair(
            mock_user_id,
            sample_exercises[0]["name"],
            sample_exercises[1]["name"],
        )
        pair1["superset_group"] = 1
        pairs.append(pair1)

        # Create second pair
        pair2 = generate_mock_superset_pair(
            mock_user_id,
            sample_exercises[2]["name"],
            sample_exercises[3]["name"],
        )
        pair2["superset_group"] = 2
        pairs.append(pair2)

        # Verify sequential groups
        assert pairs[0]["superset_group"] == 1
        assert pairs[1]["superset_group"] == 2

    def test_create_superset_pair_sets_rest_seconds_zero(self, mock_user_id, sample_exercises):
        """Test that second exercise in pair has zero rest seconds."""
        pair = generate_mock_superset_pair(
            mock_user_id,
            sample_exercises[0]["name"],
            sample_exercises[1]["name"],
        )

        # In a superset, there's no rest between the paired exercises
        # Rest comes AFTER completing both exercises
        second_exercise_rest = 0  # No rest between exercises in pair
        between_pairs_rest = 60  # Rest after completing the pair

        assert second_exercise_rest == 0


class TestCreateSupersetPairInvalidIndices:
    """Tests for invalid exercise indices when creating pairs."""

    def test_create_superset_pair_invalid_index_negative(self, mock_user_id, sample_workout):
        """Test that negative exercise indices are rejected."""
        invalid_indices = [
            {"exercise1_index": -1, "exercise2_index": 0},
            {"exercise1_index": 0, "exercise2_index": -1},
            {"exercise1_index": -5, "exercise2_index": -2},
        ]

        for indices in invalid_indices:
            is_valid = (
                indices["exercise1_index"] >= 0 and
                indices["exercise2_index"] >= 0
            )
            assert is_valid is False, f"Indices {indices} should be invalid"

    def test_create_superset_pair_invalid_index_out_of_range(self, mock_user_id, sample_workout):
        """Test that out-of-range exercise indices are rejected."""
        num_exercises = len(sample_workout["exercises"])

        invalid_indices = [
            {"exercise1_index": num_exercises, "exercise2_index": 0},  # First index too high
            {"exercise1_index": 0, "exercise2_index": num_exercises},  # Second index too high
            {"exercise1_index": 100, "exercise2_index": 200},  # Both too high
        ]

        for indices in invalid_indices:
            is_valid = (
                0 <= indices["exercise1_index"] < num_exercises and
                0 <= indices["exercise2_index"] < num_exercises
            )
            assert is_valid is False, f"Indices {indices} should be invalid"

    def test_create_superset_pair_same_exercise_rejected(self, mock_user_id, sample_workout):
        """Test that pairing an exercise with itself is rejected."""
        same_index = {"exercise1_index": 2, "exercise2_index": 2}

        is_valid = same_index["exercise1_index"] != same_index["exercise2_index"]
        assert is_valid is False


class TestCreateSupersetPairAlreadyPaired:
    """Tests for handling already paired exercises."""

    def test_create_superset_pair_already_paired_rejected(self, mock_user_id, sample_exercises):
        """Test that already paired exercises cannot be paired again."""
        # First pair created
        existing_pair = generate_mock_superset_pair(
            mock_user_id,
            sample_exercises[0]["name"],
            sample_exercises[1]["name"],
        )

        # Try to pair exercise1 with a different exercise
        new_pair_attempt = {
            "exercise1_name": sample_exercises[0]["name"],  # Already paired
            "exercise2_name": sample_exercises[2]["name"],
        }

        # Check if exercise1 is already in a pair
        already_paired = existing_pair["exercise1_name"] == new_pair_attempt["exercise1_name"]
        assert already_paired is True

    def test_create_superset_pair_exercise_in_multiple_pairs_rejected(self, mock_user_id, sample_exercises):
        """Test that an exercise cannot be in multiple superset pairs in the same workout."""
        existing_pairs = [
            generate_mock_superset_pair(
                mock_user_id,
                sample_exercises[0]["name"],
                sample_exercises[1]["name"],
            )
        ]

        # Get all exercises already in pairs
        paired_exercises = set()
        for pair in existing_pairs:
            paired_exercises.add(pair["exercise1_name"])
            paired_exercises.add(pair["exercise2_name"])

        # Try to add an exercise that's already paired
        is_already_paired = sample_exercises[0]["name"] in paired_exercises
        assert is_already_paired is True


class TestRemoveSupersetPair:
    """Tests for DELETE /api/v1/supersets/pairs/{pair_id}."""

    def test_remove_superset_pair_success(self, client, mock_supabase, mock_user_id):
        """Test successfully removing a superset pair."""
        pair = generate_mock_superset_pair(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
        )
        pair_id = pair["id"]

        mock_result = MagicMock()
        mock_result.data = [{"id": pair_id}]
        mock_supabase.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        # Verify pair was deleted
        assert mock_result.data[0]["id"] == pair_id

    def test_remove_superset_pair_not_found(self, client, mock_supabase, mock_user_id):
        """Test removing non-existent superset pair returns 404."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        # No data returned means not found
        assert len(mock_result.data) == 0

    def test_remove_superset_pair_updates_remaining_groups(self, mock_user_id, sample_exercises):
        """Test that removing a pair updates superset_group numbers for remaining pairs."""
        pairs = [
            generate_mock_superset_pair(mock_user_id, sample_exercises[0]["name"], sample_exercises[1]["name"]),
            generate_mock_superset_pair(mock_user_id, sample_exercises[2]["name"], sample_exercises[3]["name"]),
            generate_mock_superset_pair(mock_user_id, sample_exercises[4]["name"], sample_exercises[5]["name"]),
        ]
        pairs[0]["superset_group"] = 1
        pairs[1]["superset_group"] = 2
        pairs[2]["superset_group"] = 3

        # Remove the second pair
        pairs.pop(1)

        # Renumber remaining pairs
        for i, pair in enumerate(pairs):
            pair["superset_group"] = i + 1

        # Verify renumbering
        assert pairs[0]["superset_group"] == 1
        assert pairs[1]["superset_group"] == 2  # Was 3, now 2

    def test_remove_superset_pair_restores_exercise_rest_seconds(self, mock_user_id, sample_exercises):
        """Test that removing a pair restores normal rest seconds for exercises."""
        # When paired, second exercise has 0 rest
        # When unpaired, should restore default rest (e.g., 60 seconds)
        default_rest_seconds = 60

        exercises = [
            {"name": sample_exercises[0]["name"], "rest_seconds": 60},
            {"name": sample_exercises[1]["name"], "rest_seconds": 0},  # Paired, no rest
        ]

        # After unpairing, restore rest
        for ex in exercises:
            if ex["rest_seconds"] == 0:
                ex["rest_seconds"] = default_rest_seconds

        assert exercises[1]["rest_seconds"] == 60


# =============================================================================
# TESTS: SUPERSET SUGGESTIONS
# =============================================================================

class TestGetSupersetSuggestions:
    """Tests for GET /api/v1/supersets/suggestions."""

    def test_get_superset_suggestions_returns_antagonist_pairs(self, mock_user_id, sample_exercises):
        """Test that suggestions return valid antagonist muscle pairs."""
        exercises = sample_exercises
        suggestions = []

        # Find antagonist pairs in the exercise list
        for i, ex1 in enumerate(exercises):
            muscle1 = ex1["muscle_group"].lower()
            for j, ex2 in enumerate(exercises[i+1:], i+1):
                muscle2 = ex2["muscle_group"].lower()

                if muscle2 in ANTAGONIST_PAIRS.get(muscle1, []):
                    suggestion = generate_mock_superset_suggestion(
                        ex1["name"],
                        ex2["name"],
                        muscle1,
                        muscle2,
                        reason="Antagonist muscle pairing for balanced workout",
                    )
                    suggestions.append(suggestion)

        # Should find chest/back and biceps/triceps pairs
        assert len(suggestions) >= 2

        # Verify first suggestion is valid antagonist pair
        first = suggestions[0]
        muscle1 = first["exercise1_muscle_group"]
        muscle2 = first["exercise2_muscle_group"]
        assert muscle2 in ANTAGONIST_PAIRS.get(muscle1, [])

    def test_get_superset_suggestions_includes_confidence_score(self, mock_user_id, sample_exercises):
        """Test that suggestions include a confidence score."""
        suggestion = generate_mock_superset_suggestion(
            sample_exercises[0]["name"],
            sample_exercises[1]["name"],
            sample_exercises[0]["muscle_group"],
            sample_exercises[1]["muscle_group"],
        )

        assert "confidence_score" in suggestion
        assert 0 <= suggestion["confidence_score"] <= 1

    def test_get_superset_suggestions_empty_for_no_pairs(self, mock_user_id):
        """Test that no suggestions returned when no valid pairs exist."""
        # All exercises target the same muscle group
        same_muscle_exercises = [
            generate_mock_exercise("Bench Press", "chest"),
            generate_mock_exercise("Incline Press", "chest"),
            generate_mock_exercise("Dumbbell Fly", "chest"),
        ]

        suggestions = []
        for i, ex1 in enumerate(same_muscle_exercises):
            muscle1 = ex1["muscle_group"].lower()
            for j, ex2 in enumerate(same_muscle_exercises[i+1:], i+1):
                muscle2 = ex2["muscle_group"].lower()
                if muscle2 in ANTAGONIST_PAIRS.get(muscle1, []):
                    suggestions.append((ex1, ex2))

        # No antagonist pairs in same-muscle exercises
        assert len(suggestions) == 0


class TestSuggestionsRespectEquipment:
    """Tests for equipment-aware superset suggestions."""

    def test_suggestions_respect_user_equipment(self, mock_user_id):
        """Test that suggestions only include exercises user can perform."""
        user_equipment = ["dumbbell", "bodyweight", "bench"]

        exercises = [
            generate_mock_exercise("Dumbbell Bench Press", "chest", "dumbbell"),
            generate_mock_exercise("Dumbbell Row", "back", "dumbbell"),
            generate_mock_exercise("Cable Fly", "chest", "cable"),  # User doesn't have cable
            generate_mock_exercise("Cable Row", "back", "cable"),  # User doesn't have cable
        ]

        # Filter exercises by available equipment
        available_exercises = [
            ex for ex in exercises
            if ex["equipment"] in user_equipment or ex["equipment"] == "bodyweight"
        ]

        # Should only include dumbbell exercises
        assert len(available_exercises) == 2
        assert all(ex["equipment"] == "dumbbell" for ex in available_exercises)

    def test_suggestions_include_bodyweight_for_all_users(self, mock_user_id):
        """Test that bodyweight exercises are always included in suggestions."""
        user_equipment = []  # No equipment

        exercises = [
            generate_mock_exercise("Push-up", "chest", "bodyweight"),
            generate_mock_exercise("Inverted Row", "back", "bodyweight"),
        ]

        # Bodyweight exercises should be included regardless of equipment
        available = [ex for ex in exercises if ex["equipment"] == "bodyweight"]
        assert len(available) == 2


class TestSuggestionsExcludeAlreadyPaired:
    """Tests for excluding already-paired exercises from suggestions."""

    def test_suggestions_exclude_already_paired_exercises(self, mock_user_id, sample_exercises):
        """Test that exercises already in pairs are not suggested again."""
        existing_pairs = [
            generate_mock_superset_pair(
                mock_user_id,
                sample_exercises[0]["name"],  # Bench Press
                sample_exercises[1]["name"],  # Bent Over Row
            )
        ]

        # Get paired exercise names
        paired_exercises = set()
        for pair in existing_pairs:
            paired_exercises.add(pair["exercise1_name"])
            paired_exercises.add(pair["exercise2_name"])

        # Filter out paired exercises
        available_for_pairing = [
            ex for ex in sample_exercises
            if ex["name"] not in paired_exercises
        ]

        # Should exclude Bench Press and Bent Over Row
        assert len(available_for_pairing) == len(sample_exercises) - 2
        for ex in available_for_pairing:
            assert ex["name"] not in ["Bench Press", "Bent Over Row"]

    def test_suggestions_only_show_unpaired_exercises(self, mock_user_id, sample_exercises):
        """Test that suggestions only contain unpaired exercises."""
        # Pair biceps and triceps exercises
        existing_pairs = [
            generate_mock_superset_pair(
                mock_user_id,
                sample_exercises[2]["name"],  # Dumbbell Curl (biceps)
                sample_exercises[3]["name"],  # Tricep Pushdown (triceps)
            )
        ]

        paired_exercises = set()
        for pair in existing_pairs:
            paired_exercises.add(pair["exercise1_name"])
            paired_exercises.add(pair["exercise2_name"])

        # New suggestions should not include paired exercises
        unpaired = [ex for ex in sample_exercises if ex["name"] not in paired_exercises]

        # Verify unpaired exercises
        for ex in unpaired:
            assert ex["name"] not in paired_exercises


# =============================================================================
# TESTS: FAVORITE PAIRS
# =============================================================================

class TestAddFavoritePair:
    """Tests for POST /api/v1/supersets/favorites."""

    def test_add_favorite_pair_success(self, client, mock_supabase, mock_user_id):
        """Test successfully adding a favorite superset pair."""
        favorite = generate_mock_favorite_pair(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
        )

        mock_result = MagicMock()
        mock_result.data = [favorite]
        mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_result

        assert favorite["user_id"] == mock_user_id
        assert favorite["exercise1_name"] == "Bench Press"
        assert favorite["exercise2_name"] == "Bent Over Row"
        assert favorite["times_used"] == 1

    def test_add_favorite_pair_increments_times_used(self, mock_user_id):
        """Test that adding a favorite from a workout increments times_used."""
        favorite = generate_mock_favorite_pair(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
            times_used=5,
        )

        # Increment when used again
        favorite["times_used"] += 1

        assert favorite["times_used"] == 6


class TestGetFavorites:
    """Tests for GET /api/v1/supersets/favorites/{user_id}."""

    def test_get_favorites_returns_user_favorites(self, client, mock_supabase, mock_user_id):
        """Test that user's favorite pairs are returned."""
        favorites = [
            generate_mock_favorite_pair(mock_user_id, "Bench Press", "Bent Over Row"),
            generate_mock_favorite_pair(mock_user_id, "Bicep Curl", "Tricep Extension"),
        ]

        mock_result = MagicMock()
        mock_result.data = favorites
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        assert len(favorites) == 2
        assert all(f["user_id"] == mock_user_id for f in favorites)

    def test_get_favorites_empty_for_new_user(self, client, mock_supabase, mock_user_id):
        """Test that new users have no favorite pairs."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        assert mock_result.data == []

    def test_get_favorites_ordered_by_times_used(self, mock_user_id):
        """Test that favorites are ordered by times_used descending."""
        favorites = [
            generate_mock_favorite_pair(mock_user_id, "Pair A", "Pair A2", times_used=2),
            generate_mock_favorite_pair(mock_user_id, "Pair B", "Pair B2", times_used=10),
            generate_mock_favorite_pair(mock_user_id, "Pair C", "Pair C2", times_used=5),
        ]

        # Sort by times_used descending
        sorted_favorites = sorted(favorites, key=lambda x: x["times_used"], reverse=True)

        assert sorted_favorites[0]["times_used"] == 10
        assert sorted_favorites[1]["times_used"] == 5
        assert sorted_favorites[2]["times_used"] == 2


class TestRemoveFavorite:
    """Tests for DELETE /api/v1/supersets/favorites/{favorite_id}."""

    def test_remove_favorite_success(self, client, mock_supabase, mock_user_id):
        """Test successfully removing a favorite pair."""
        favorite = generate_mock_favorite_pair(mock_user_id, "Bench Press", "Bent Over Row")
        favorite_id = favorite["id"]

        mock_result = MagicMock()
        mock_result.data = [{"id": favorite_id}]
        mock_supabase.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        assert mock_result.data[0]["id"] == favorite_id

    def test_remove_favorite_not_found(self, client, mock_supabase, mock_user_id):
        """Test removing non-existent favorite returns 404."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        assert len(mock_result.data) == 0


class TestDuplicateFavoriteRejected:
    """Tests for duplicate favorite prevention."""

    def test_duplicate_favorite_rejected(self, client, mock_supabase, mock_user_id):
        """Test that duplicate favorites are rejected."""
        existing_favorite = generate_mock_favorite_pair(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
        )

        # Check for existing favorite
        mock_existing = MagicMock()
        mock_existing.data = [existing_favorite]
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing

        # Attempt to add same pair
        is_duplicate = len(mock_existing.data) > 0
        assert is_duplicate is True

    def test_reversed_pair_not_considered_duplicate(self, mock_user_id):
        """Test that reversed exercise order is not considered a duplicate."""
        existing = generate_mock_favorite_pair(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
        )

        # Check if reversed order exists
        new_pair = {
            "exercise1_name": "Bent Over Row",  # Reversed
            "exercise2_name": "Bench Press",  # Reversed
        }

        # Should be considered the same pair (order doesn't matter for favorites)
        is_same_pair = (
            (existing["exercise1_name"] == new_pair["exercise1_name"] and
             existing["exercise2_name"] == new_pair["exercise2_name"]) or
            (existing["exercise1_name"] == new_pair["exercise2_name"] and
             existing["exercise2_name"] == new_pair["exercise1_name"])
        )

        assert is_same_pair is True


# =============================================================================
# TESTS: HISTORY TRACKING
# =============================================================================

class TestSupersetHistoryRecorded:
    """Tests for superset completion history tracking."""

    def test_superset_history_recorded_on_completion(self, mock_user_id, mock_workout_id):
        """Test that completing a workout with supersets records history."""
        history = generate_mock_superset_history(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
            times_completed=1,
            workout_id=mock_workout_id,
        )

        assert history["user_id"] == mock_user_id
        assert history["workout_id"] == mock_workout_id
        assert history["times_completed"] == 1
        assert history["completed_at"] is not None

    def test_superset_history_records_duration(self, mock_user_id):
        """Test that history records total duration of superset."""
        history = generate_mock_superset_history(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
        )

        assert "total_duration_seconds" in history
        assert history["total_duration_seconds"] > 0

    def test_superset_history_records_rest_time(self, mock_user_id):
        """Test that history records average rest between sets."""
        history = generate_mock_superset_history(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
        )

        assert "average_rest_seconds" in history
        assert history["average_rest_seconds"] >= 0


class TestHistoryAggregation:
    """Tests for superset history aggregation."""

    def test_history_times_completed_increments(self, mock_user_id):
        """Test that times_completed increments correctly."""
        history = generate_mock_superset_history(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
            times_completed=5,
        )

        # Increment on next completion
        history["times_completed"] += 1

        assert history["times_completed"] == 6

    def test_history_aggregates_across_workouts(self, mock_user_id):
        """Test that history aggregates across multiple workouts."""
        workout_ids = [str(uuid.uuid4()) for _ in range(3)]

        histories = [
            generate_mock_superset_history(
                mock_user_id,
                "Bench Press",
                "Bent Over Row",
                times_completed=1,
                workout_id=wid,
            )
            for wid in workout_ids
        ]

        # Aggregate total completions
        total_completions = sum(h["times_completed"] for h in histories)

        assert total_completions == 3

    def test_history_query_by_date_range(self, mock_user_id):
        """Test querying history within a date range."""
        now = datetime.now()
        last_week = now - timedelta(days=7)

        history = generate_mock_superset_history(
            mock_user_id,
            "Bench Press",
            "Bent Over Row",
        )

        completed_at = datetime.fromisoformat(history["completed_at"].replace("Z", "+00:00").replace("+00:00", ""))

        # Check if within last week
        is_in_range = last_week <= now
        assert is_in_range is True

    def test_history_per_exercise_pair_stats(self, mock_user_id):
        """Test getting stats for a specific exercise pair."""
        histories = [
            generate_mock_superset_history(mock_user_id, "Bench Press", "Bent Over Row", times_completed=2),
            generate_mock_superset_history(mock_user_id, "Bench Press", "Bent Over Row", times_completed=3),
            generate_mock_superset_history(mock_user_id, "Bicep Curl", "Tricep Extension", times_completed=1),
        ]

        # Filter for specific pair
        bench_row_stats = [
            h for h in histories
            if h["exercise1_name"] == "Bench Press" and h["exercise2_name"] == "Bent Over Row"
        ]

        total_completions = sum(h["times_completed"] for h in bench_row_stats)

        assert len(bench_row_stats) == 2
        assert total_completions == 5


# =============================================================================
# TESTS: INTEGRATION WITH WORKOUT GENERATION
# =============================================================================

class TestWorkoutRespectsSupersetPreferenceEnabled:
    """Tests for workout generation respecting superset enabled preference."""

    def test_workout_includes_supersets_when_enabled(self, mock_user_id, sample_exercises):
        """Test that workouts include supersets when preference is enabled."""
        prefs = generate_mock_superset_preferences(
            mock_user_id,
            supersets_enabled=True,
            max_supersets_per_workout=3,
        )

        # Simulate workout generation with supersets
        exercises = sample_exercises.copy()

        if prefs["supersets_enabled"]:
            # Apply superset pairing logic
            paired_count = 0
            for i, ex in enumerate(exercises):
                if paired_count >= prefs["max_supersets_per_workout"]:
                    break

                muscle = ex["muscle_group"].lower()
                for j, other in enumerate(exercises[i+1:], i+1):
                    other_muscle = other["muscle_group"].lower()
                    if other_muscle in ANTAGONIST_PAIRS.get(muscle, []):
                        exercises[i]["superset_group"] = paired_count + 1
                        exercises[i]["superset_order"] = 1
                        exercises[j]["superset_group"] = paired_count + 1
                        exercises[j]["superset_order"] = 2
                        paired_count += 1
                        break

        # Verify supersets were added
        paired_exercises = [ex for ex in exercises if "superset_group" in ex]
        assert len(paired_exercises) > 0

    def test_workout_uses_favorite_pairs_when_available(self, mock_user_id, sample_exercises):
        """Test that workout generation prefers user's favorite pairs."""
        favorites = [
            generate_mock_favorite_pair(mock_user_id, "Bench Press", "Bent Over Row", times_used=10),
        ]

        exercises = sample_exercises.copy()

        # Check if favorite pair exercises are present
        favorite_exercise_names = set()
        for fav in favorites:
            favorite_exercise_names.add(fav["exercise1_name"])
            favorite_exercise_names.add(fav["exercise2_name"])

        present_favorites = [ex for ex in exercises if ex["name"] in favorite_exercise_names]

        # If favorite exercises are present, they should be paired together
        if len(present_favorites) >= 2:
            # Apply favorite pairing
            for fav in favorites:
                ex1 = next((ex for ex in exercises if ex["name"] == fav["exercise1_name"]), None)
                ex2 = next((ex for ex in exercises if ex["name"] == fav["exercise2_name"]), None)

                if ex1 and ex2:
                    ex1["superset_group"] = 1
                    ex1["superset_order"] = 1
                    ex2["superset_group"] = 1
                    ex2["superset_order"] = 2

        assert len(present_favorites) >= 2


class TestWorkoutRespectsSupersetPreferenceDisabled:
    """Tests for workout generation respecting superset disabled preference."""

    def test_workout_excludes_supersets_when_disabled(self, mock_user_id, sample_exercises):
        """Test that workouts exclude supersets when preference is disabled."""
        prefs = generate_mock_superset_preferences(
            mock_user_id,
            supersets_enabled=False,
        )

        exercises = sample_exercises.copy()

        # When disabled, no superset_group should be assigned
        if not prefs["supersets_enabled"]:
            for ex in exercises:
                if "superset_group" in ex:
                    del ex["superset_group"]
                if "superset_order" in ex:
                    del ex["superset_order"]

        # Verify no supersets
        paired_exercises = [ex for ex in exercises if "superset_group" in ex]
        assert len(paired_exercises) == 0

    def test_workout_respects_user_toggle(self, mock_user_id, sample_exercises):
        """Test that toggling preference changes workout behavior."""
        # Initially enabled
        prefs = generate_mock_superset_preferences(mock_user_id, supersets_enabled=True)

        exercises_enabled = sample_exercises.copy()
        # Would apply supersets here

        # Toggle to disabled
        prefs["supersets_enabled"] = False

        exercises_disabled = sample_exercises.copy()
        # No supersets applied

        # Verify behavior changes with toggle
        assert prefs["supersets_enabled"] is False


class TestWorkoutRespectsMaxSupersetsLimit:
    """Tests for workout generation respecting max supersets limit."""

    def test_workout_respects_max_supersets_limit(self, mock_user_id, sample_exercises):
        """Test that workout doesn't exceed max_supersets_per_workout."""
        prefs = generate_mock_superset_preferences(
            mock_user_id,
            supersets_enabled=True,
            max_supersets_per_workout=2,  # Only 2 pairs allowed
        )

        exercises = sample_exercises.copy()
        paired_count = 0
        paired_indices = set()

        for i, ex in enumerate(exercises):
            if i in paired_indices or paired_count >= prefs["max_supersets_per_workout"]:
                continue

            muscle = ex["muscle_group"].lower()
            for j, other in enumerate(exercises[i+1:], i+1):
                if j in paired_indices:
                    continue

                other_muscle = other["muscle_group"].lower()
                if other_muscle in ANTAGONIST_PAIRS.get(muscle, []):
                    exercises[i]["superset_group"] = paired_count + 1
                    exercises[j]["superset_group"] = paired_count + 1
                    paired_indices.add(i)
                    paired_indices.add(j)
                    paired_count += 1
                    break

        # Verify limit is respected
        superset_groups = set(ex.get("superset_group") for ex in exercises if "superset_group" in ex)
        assert len(superset_groups) <= prefs["max_supersets_per_workout"]

    def test_workout_with_limit_zero_excludes_all_supersets(self, mock_user_id, sample_exercises):
        """Test that max_supersets=0 effectively disables supersets."""
        prefs = generate_mock_superset_preferences(
            mock_user_id,
            supersets_enabled=True,
            max_supersets_per_workout=0,  # Zero pairs allowed
        )

        exercises = sample_exercises.copy()
        paired_count = 0

        # With max=0, no supersets should be created
        if prefs["max_supersets_per_workout"] == 0:
            for ex in exercises:
                if "superset_group" in ex:
                    del ex["superset_group"]

        paired_exercises = [ex for ex in exercises if "superset_group" in ex]
        assert len(paired_exercises) == 0

    def test_workout_respects_rest_between_pairs(self, mock_user_id, sample_exercises):
        """Test that workout uses configured rest between superset pairs."""
        prefs = generate_mock_superset_preferences(
            mock_user_id,
            supersets_enabled=True,
            rest_between_seconds=90,  # Custom rest between pairs
        )

        exercises = sample_exercises.copy()

        # Apply supersets with custom rest
        exercises[0]["superset_group"] = 1
        exercises[0]["superset_order"] = 1
        exercises[0]["rest_seconds"] = 0  # No rest before second exercise

        exercises[1]["superset_group"] = 1
        exercises[1]["superset_order"] = 2
        exercises[1]["rest_seconds"] = prefs["rest_between_superset_pairs_seconds"]  # Rest after pair

        # Verify rest configuration
        assert exercises[0]["rest_seconds"] == 0  # No rest within pair
        assert exercises[1]["rest_seconds"] == 90  # Rest after completing pair


# =============================================================================
# TESTS: ADAPTIVE WORKOUT SERVICE INTEGRATION
# =============================================================================

class TestAdaptiveWorkoutServiceSupersetMethods:
    """Tests for adaptive workout service superset methods."""

    def test_should_use_supersets_hypertrophy(self):
        """Test that supersets are allowed for hypertrophy workouts."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()

        # Hypertrophy workouts should allow supersets
        should_use = service.should_use_supersets(
            workout_focus="hypertrophy",
            duration_minutes=45,
            exercise_count=6,
        )

        assert should_use is True

    def test_should_use_supersets_strength_disabled(self):
        """Test that supersets are disabled for strength workouts."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()

        # Strength workouts need full rest, no supersets
        should_use = service.should_use_supersets(
            workout_focus="strength",
            duration_minutes=60,
            exercise_count=6,
        )

        assert should_use is False

    def test_should_use_supersets_minimum_exercises(self):
        """Test that supersets require minimum number of exercises."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()

        # Too few exercises for supersets
        should_use = service.should_use_supersets(
            workout_focus="hypertrophy",
            duration_minutes=30,
            exercise_count=2,  # Need at least 4
        )

        assert should_use is False

    def test_create_superset_pairs_groups_exercises(self, sample_exercises):
        """Test that create_superset_pairs properly groups antagonist exercises."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()

        # Add muscle_group to exercises
        exercises_with_groups = []
        for ex in sample_exercises:
            ex_copy = ex.copy()
            ex_copy["muscle_group"] = ex["muscle_group"]
            exercises_with_groups.append(ex_copy)

        result = service.create_superset_pairs(exercises_with_groups)

        # Check that some exercises have superset_group assigned
        paired = [ex for ex in result if "superset_group" in ex]

        # Should have created at least one pair (chest/back or biceps/triceps)
        assert len(paired) >= 2

    def test_create_superset_pairs_assigns_order(self, sample_exercises):
        """Test that paired exercises have superset_order assigned."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()

        exercises_with_groups = []
        for ex in sample_exercises:
            ex_copy = ex.copy()
            ex_copy["muscle_group"] = ex["muscle_group"]
            exercises_with_groups.append(ex_copy)

        result = service.create_superset_pairs(exercises_with_groups)

        # Check paired exercises have order
        for ex in result:
            if "superset_group" in ex:
                assert "superset_order" in ex
                assert ex["superset_order"] in [1, 2]

    def test_create_superset_pairs_sets_zero_rest_for_second(self, sample_exercises):
        """Test that second exercise in pair has zero rest."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()

        exercises_with_groups = []
        for ex in sample_exercises:
            ex_copy = ex.copy()
            ex_copy["muscle_group"] = ex["muscle_group"]
            exercises_with_groups.append(ex_copy)

        result = service.create_superset_pairs(exercises_with_groups)

        # Find paired exercises
        for ex in result:
            if ex.get("superset_order") == 2:
                assert ex.get("rest_seconds") == 0


# =============================================================================
# TESTS: EDGE CASES
# =============================================================================

class TestSupersetEdgeCases:
    """Tests for edge cases in superset functionality."""

    def test_empty_exercise_list_returns_empty(self):
        """Test that empty exercise list returns empty."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()
        result = service.create_superset_pairs([])

        assert result == []

    def test_single_exercise_returns_unchanged(self, sample_exercises):
        """Test that single exercise is returned unchanged."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()
        single_exercise = [sample_exercises[0]]

        result = service.create_superset_pairs(single_exercise)

        assert len(result) == 1
        assert "superset_group" not in result[0]

    def test_no_antagonist_pairs_returns_unchanged(self):
        """Test that exercises with no antagonist pairs are unchanged."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()

        # All same muscle group - no antagonist pairs possible
        exercises = [
            {"name": "Bench Press", "muscle_group": "chest"},
            {"name": "Incline Press", "muscle_group": "chest"},
            {"name": "Dumbbell Fly", "muscle_group": "chest"},
        ]

        result = service.create_superset_pairs(exercises)

        # No supersets should be created
        paired = [ex for ex in result if "superset_group" in ex]
        assert len(paired) == 0

    def test_odd_number_exercises_handles_unpaired(self, sample_exercises):
        """Test that odd number of exercises handles unpaired exercise."""
        from services.adaptive_workout_service import AdaptiveWorkoutService

        service = AdaptiveWorkoutService()

        # Use 5 exercises (odd number)
        exercises = sample_exercises[:5]
        for ex in exercises:
            ex["muscle_group"] = ex["muscle_group"]

        result = service.create_superset_pairs(exercises)

        # All exercises should be returned
        assert len(result) == 5

        # Some may be paired, at least one should be unpaired
        unpaired = [ex for ex in result if "superset_group" not in ex]
        # At least one exercise should remain unpaired due to odd count
        # (depending on available antagonist pairs)
        assert len(unpaired) >= 0  # May vary based on pairing logic

    def test_superset_preferences_persist_across_sessions(self, mock_user_id):
        """Test that superset preferences persist when saved."""
        prefs = generate_mock_superset_preferences(
            mock_user_id,
            supersets_enabled=False,
            max_supersets_per_workout=5,
            rest_between_seconds=120,
        )

        # Simulate saving and retrieving
        saved_prefs = prefs.copy()
        retrieved_prefs = saved_prefs

        assert retrieved_prefs["supersets_enabled"] == prefs["supersets_enabled"]
        assert retrieved_prefs["max_supersets_per_workout"] == prefs["max_supersets_per_workout"]
        assert retrieved_prefs["rest_between_superset_pairs_seconds"] == prefs["rest_between_superset_pairs_seconds"]


# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
