"""
Tests for Avoided Exercises and Muscles API endpoints.

This module tests:
1. GET/POST/PUT/DELETE for avoided exercises
2. GET/POST/PUT/DELETE for avoided muscles
3. Helper functions for workout generation
4. Expiry handling for temporary avoidances
"""
import pytest
from datetime import date, timedelta
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient


# Mock UUID for testing
MOCK_USER_ID = "test-user-123"
MOCK_EXERCISE_ID = "avoided-exercise-456"
MOCK_MUSCLE_ID = "avoided-muscle-789"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    with patch("api.v1.exercise_preferences.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


@pytest.fixture
def client():
    """Create a test client."""
    from main import app
    return TestClient(app)


def generate_mock_avoided_exercise(
    exercise_name: str = "Barbell Squat",
    is_temporary: bool = False,
    end_date: str = None,
    reason: str = "Knee injury",
):
    """Generate a mock avoided exercise response."""
    return {
        "id": MOCK_EXERCISE_ID,
        "user_id": MOCK_USER_ID,
        "exercise_name": exercise_name,
        "exercise_id": None,
        "reason": reason,
        "is_temporary": is_temporary,
        "end_date": end_date,
        "created_at": "2024-12-30T12:00:00Z",
        "updated_at": "2024-12-30T12:00:00Z",
    }


def generate_mock_avoided_muscle(
    muscle_group: str = "lower_back",
    is_temporary: bool = False,
    end_date: str = None,
    reason: str = "Herniated disc",
    severity: str = "avoid",
):
    """Generate a mock avoided muscle response."""
    return {
        "id": MOCK_MUSCLE_ID,
        "user_id": MOCK_USER_ID,
        "muscle_group": muscle_group,
        "reason": reason,
        "is_temporary": is_temporary,
        "end_date": end_date,
        "severity": severity,
        "created_at": "2024-12-30T12:00:00Z",
        "updated_at": "2024-12-30T12:00:00Z",
    }


# =============================================================================
# Avoided Exercises Tests
# =============================================================================

class TestGetAvoidedExercises:
    """Tests for GET /exercise-preferences/avoided-exercises/{user_id}"""

    def test_get_avoided_exercises_success(self, client, mock_supabase):
        """Test successful retrieval of avoided exercises."""
        # Setup mock
        mock_result = MagicMock()
        mock_result.data = [
            generate_mock_avoided_exercise("Barbell Squat", reason="Knee injury"),
            generate_mock_avoided_exercise("Deadlift", reason="Back pain"),
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.or_.return_value.order.return_value.execute.return_value = mock_result

        # Make request
        response = client.get(f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}")

        # Verify
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["exercise_name"] == "Barbell Squat"
        assert data[0]["reason"] == "Knee injury"

    def test_get_avoided_exercises_empty(self, client, mock_supabase):
        """Test when user has no avoided exercises."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.or_.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}")

        assert response.status_code == 200
        assert response.json() == []

    def test_get_avoided_exercises_include_expired(self, client, mock_supabase):
        """Test retrieval including expired temporary avoidances."""
        mock_result = MagicMock()
        mock_result.data = [
            generate_mock_avoided_exercise(
                "Barbell Squat",
                is_temporary=True,
                end_date="2024-01-01"  # Expired
            ),
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}?include_expired=true"
        )

        assert response.status_code == 200


class TestAddAvoidedExercise:
    """Tests for POST /exercise-preferences/avoided-exercises/{user_id}"""

    def test_add_avoided_exercise_success(self, client, mock_supabase):
        """Test successfully adding an avoided exercise."""
        # Setup mock for duplicate check
        mock_existing = MagicMock()
        mock_existing.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing

        # Setup mock for insert
        mock_insert = MagicMock()
        mock_insert.data = [generate_mock_avoided_exercise()]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert

        # Make request
        response = client.post(
            f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}",
            json={
                "exercise_name": "Barbell Squat",
                "reason": "Knee injury",
                "is_temporary": False,
            }
        )

        # Verify
        assert response.status_code == 200
        data = response.json()
        assert data["exercise_name"] == "Barbell Squat"
        assert data["reason"] == "Knee injury"

    def test_add_avoided_exercise_duplicate(self, client, mock_supabase):
        """Test adding duplicate avoided exercise fails."""
        mock_existing = MagicMock()
        mock_existing.data = [{"id": "existing-id"}]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing

        response = client.post(
            f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}",
            json={"exercise_name": "Barbell Squat"}
        )

        assert response.status_code == 400
        assert "already in avoidance list" in response.json()["detail"]

    def test_add_temporary_avoided_exercise(self, client, mock_supabase):
        """Test adding a temporary avoided exercise with end date."""
        mock_existing = MagicMock()
        mock_existing.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing

        end_date = (date.today() + timedelta(days=30)).isoformat()
        mock_insert = MagicMock()
        mock_insert.data = [generate_mock_avoided_exercise(
            is_temporary=True,
            end_date=end_date
        )]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert

        response = client.post(
            f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}",
            json={
                "exercise_name": "Barbell Squat",
                "reason": "Recovering from surgery",
                "is_temporary": True,
                "end_date": end_date,
            }
        )

        assert response.status_code == 200
        assert response.json()["is_temporary"] is True


class TestRemoveAvoidedExercise:
    """Tests for DELETE /exercise-preferences/avoided-exercises/{user_id}/{exercise_id}"""

    def test_remove_avoided_exercise_success(self, client, mock_supabase):
        """Test successfully removing an avoided exercise."""
        mock_result = MagicMock()
        mock_result.data = [{"id": MOCK_EXERCISE_ID}]
        mock_supabase.client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.delete(
            f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}/{MOCK_EXERCISE_ID}"
        )

        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_remove_avoided_exercise_not_found(self, client, mock_supabase):
        """Test removing non-existent avoided exercise."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.delete(
            f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}/nonexistent-id"
        )

        assert response.status_code == 404


# =============================================================================
# Avoided Muscles Tests
# =============================================================================

class TestGetAvoidedMuscles:
    """Tests for GET /exercise-preferences/avoided-muscles/{user_id}"""

    def test_get_avoided_muscles_success(self, client, mock_supabase):
        """Test successful retrieval of avoided muscles."""
        mock_result = MagicMock()
        mock_result.data = [
            generate_mock_avoided_muscle("lower_back", reason="Herniated disc"),
            generate_mock_avoided_muscle("shoulders", reason="Rotator cuff injury"),
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.or_.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/exercise-preferences/avoided-muscles/{MOCK_USER_ID}")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["muscle_group"] == "lower_back"

    def test_get_avoided_muscles_empty(self, client, mock_supabase):
        """Test when user has no avoided muscles."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.or_.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/exercise-preferences/avoided-muscles/{MOCK_USER_ID}")

        assert response.status_code == 200
        assert response.json() == []


class TestAddAvoidedMuscle:
    """Tests for POST /exercise-preferences/avoided-muscles/{user_id}"""

    def test_add_avoided_muscle_success(self, client, mock_supabase):
        """Test successfully adding an avoided muscle."""
        mock_existing = MagicMock()
        mock_existing.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing

        mock_insert = MagicMock()
        mock_insert.data = [generate_mock_avoided_muscle()]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert

        response = client.post(
            f"/api/v1/exercise-preferences/avoided-muscles/{MOCK_USER_ID}",
            json={
                "muscle_group": "lower_back",
                "reason": "Herniated disc",
                "severity": "avoid",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["muscle_group"] == "lower_back"
        assert data["severity"] == "avoid"

    def test_add_avoided_muscle_reduce_severity(self, client, mock_supabase):
        """Test adding avoided muscle with 'reduce' severity."""
        mock_existing = MagicMock()
        mock_existing.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing

        mock_insert = MagicMock()
        mock_insert.data = [generate_mock_avoided_muscle(severity="reduce")]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert

        response = client.post(
            f"/api/v1/exercise-preferences/avoided-muscles/{MOCK_USER_ID}",
            json={
                "muscle_group": "shoulders",
                "reason": "Minor strain - being cautious",
                "severity": "reduce",
            }
        )

        assert response.status_code == 200
        assert response.json()["severity"] == "reduce"

    def test_add_avoided_muscle_duplicate(self, client, mock_supabase):
        """Test adding duplicate avoided muscle fails."""
        mock_existing = MagicMock()
        mock_existing.data = [{"id": "existing-id"}]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing

        response = client.post(
            f"/api/v1/exercise-preferences/avoided-muscles/{MOCK_USER_ID}",
            json={"muscle_group": "lower_back"}
        )

        assert response.status_code == 400
        assert "already in avoidance list" in response.json()["detail"]


class TestRemoveAvoidedMuscle:
    """Tests for DELETE /exercise-preferences/avoided-muscles/{user_id}/{muscle_id}"""

    def test_remove_avoided_muscle_success(self, client, mock_supabase):
        """Test successfully removing an avoided muscle."""
        mock_result = MagicMock()
        mock_result.data = [{"id": MOCK_MUSCLE_ID}]
        mock_supabase.client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.delete(
            f"/api/v1/exercise-preferences/avoided-muscles/{MOCK_USER_ID}/{MOCK_MUSCLE_ID}"
        )

        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_remove_avoided_muscle_not_found(self, client, mock_supabase):
        """Test removing non-existent avoided muscle."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.delete(
            f"/api/v1/exercise-preferences/avoided-muscles/{MOCK_USER_ID}/nonexistent-id"
        )

        assert response.status_code == 404


# =============================================================================
# Muscle Groups Endpoint Test
# =============================================================================

class TestGetMuscleGroups:
    """Tests for GET /exercise-preferences/muscle-groups"""

    def test_get_muscle_groups(self, client):
        """Test getting available muscle groups."""
        response = client.get("/api/v1/exercise-preferences/muscle-groups")

        assert response.status_code == 200
        data = response.json()
        assert "muscle_groups" in data
        assert "primary" in data
        assert "secondary" in data
        assert "chest" in data["primary"]
        assert "lower_back" in data["secondary"]


# =============================================================================
# Helper Function Tests
# =============================================================================

class TestHelperFunctions:
    """Tests for helper functions used by workout generation."""

    @pytest.mark.asyncio
    async def test_get_user_avoided_exercises(self, mock_supabase):
        """Test helper function to get avoided exercise names."""
        from api.v1.exercise_preferences import get_user_avoided_exercises

        mock_result = MagicMock()
        mock_result.data = [
            {"exercise_name": "Barbell Squat"},
            {"exercise_name": "Deadlift"},
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.or_.return_value.execute.return_value = mock_result

        result = await get_user_avoided_exercises(MOCK_USER_ID)

        assert len(result) == 2
        assert "Barbell Squat" in result
        assert "Deadlift" in result

    @pytest.mark.asyncio
    async def test_get_user_avoided_muscles(self, mock_supabase):
        """Test helper function to get avoided muscles with severity."""
        from api.v1.exercise_preferences import get_user_avoided_muscles

        mock_result = MagicMock()
        mock_result.data = [
            {"muscle_group": "lower_back", "severity": "avoid"},
            {"muscle_group": "shoulders", "severity": "reduce"},
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.or_.return_value.execute.return_value = mock_result

        result = await get_user_avoided_muscles(MOCK_USER_ID)

        assert len(result) == 2
        assert result[0]["muscle_group"] == "lower_back"
        assert result[0]["severity"] == "avoid"
        assert result[1]["severity"] == "reduce"

    @pytest.mark.asyncio
    async def test_is_exercise_avoided_true(self, mock_supabase):
        """Test checking if specific exercise is avoided."""
        from api.v1.exercise_preferences import is_exercise_avoided

        mock_result = MagicMock()
        mock_result.data = [{"exercise_name": "Barbell Squat"}]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.or_.return_value.execute.return_value = mock_result

        result = await is_exercise_avoided(MOCK_USER_ID, "Barbell Squat")
        assert result is True

    @pytest.mark.asyncio
    async def test_is_muscle_avoided(self, mock_supabase):
        """Test checking if muscle is avoided with severity."""
        from api.v1.exercise_preferences import is_muscle_avoided

        mock_result = MagicMock()
        mock_result.data = [{"muscle_group": "lower_back", "severity": "avoid"}]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.or_.return_value.execute.return_value = mock_result

        is_avoided, severity = await is_muscle_avoided(MOCK_USER_ID, "lower_back")
        assert is_avoided is True
        assert severity == "avoid"


# =============================================================================
# Validation Tests
# =============================================================================

class TestValidation:
    """Tests for request validation."""

    def test_invalid_severity(self, client, mock_supabase):
        """Test that invalid severity is rejected."""
        response = client.post(
            f"/api/v1/exercise-preferences/avoided-muscles/{MOCK_USER_ID}",
            json={
                "muscle_group": "chest",
                "severity": "invalid_severity",
            }
        )

        assert response.status_code == 422  # Validation error

    def test_empty_exercise_name(self, client, mock_supabase):
        """Test that empty exercise name is rejected."""
        response = client.post(
            f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}",
            json={"exercise_name": ""}
        )

        assert response.status_code == 422  # Validation error

    def test_exercise_name_too_long(self, client, mock_supabase):
        """Test that exercise name exceeding max length is rejected."""
        response = client.post(
            f"/api/v1/exercise-preferences/avoided-exercises/{MOCK_USER_ID}",
            json={"exercise_name": "x" * 201}  # Max is 200
        )

        assert response.status_code == 422  # Validation error


# =============================================================================
# Substitute Suggestion Tests
# =============================================================================

class TestSubstituteSuggestions:
    """Tests for the exercise substitution suggestion feature."""

    def test_suggest_substitutes_for_knee_injury(self, client, mock_supabase):
        """Test that substitutes are suggested for knee-related exercises."""
        # Mock the exercise library query
        mock_result = MagicMock()
        mock_result.data = [
            {"name": "Leg Press", "target_muscle": "quadriceps", "equipment": "machine"},
            {"name": "Wall Sit", "target_muscle": "quadriceps", "equipment": "bodyweight"},
        ]
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.neq.return_value.limit.return_value.execute.return_value = mock_result

        response = client.post(
            "/api/v1/exercise-preferences/suggest-substitutes",
            json={
                "exercise_name": "Barbell Squat",
                "reason": "knee injury"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert "substitutes" in data
        assert data["original_exercise"] == "Barbell Squat"
        assert "message" in data

    def test_suggest_substitutes_without_reason(self, client, mock_supabase):
        """Test that substitutes are suggested even without a reason."""
        mock_result = MagicMock()
        mock_result.data = [
            {"name": "Dumbbell Bench Press", "target_muscle": "chest", "equipment": "dumbbell"},
            {"name": "Push-up", "target_muscle": "chest", "equipment": "bodyweight"},
        ]
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.neq.return_value.limit.return_value.execute.return_value = mock_result

        response = client.post(
            "/api/v1/exercise-preferences/suggest-substitutes",
            json={
                "exercise_name": "Barbell Bench Press"
            }
        )

        assert response.status_code == 200

    def test_injury_exercises_endpoint(self, client, mock_supabase):
        """Test getting exercises to avoid for a specific injury type."""
        response = client.get(
            "/api/v1/exercise-preferences/injury-exercises/knee"
        )

        assert response.status_code == 200
        data = response.json()
        assert "injury_type" in data
        assert "exercises_to_avoid" in data
        assert isinstance(data["exercises_to_avoid"], list)
        assert "safe_alternatives_by_muscle" in data

    def test_injury_exercises_unknown_type(self, client, mock_supabase):
        """Test getting exercises for an unknown injury type."""
        response = client.get(
            "/api/v1/exercise-preferences/injury-exercises/unknown_injury"
        )

        # Should still return 200 with empty lists
        assert response.status_code == 200
        data = response.json()
        assert data["exercises_to_avoid"] == []


class TestAutoSubstituteHelpers:
    """Tests for auto-substitution helper functions."""

    @pytest.mark.asyncio
    async def test_get_substitute_exercise(self, mock_supabase):
        """Test finding a substitute for an avoided exercise."""
        from api.v1.workouts.utils import get_substitute_exercise

        # Mock the exercise library query
        mock_result = MagicMock()
        mock_result.data = [
            {"name": "Leg Extension", "target_muscle": "quadriceps", "body_part": "upper legs", "equipment": "machine"},
            {"name": "Step Up", "target_muscle": "quadriceps", "body_part": "upper legs", "equipment": "bodyweight"},
        ]
        mock_supabase.client.table.return_value.select.return_value.or_.return_value.limit.return_value.execute.return_value = mock_result

        with patch("api.v1.workouts.utils.get_supabase_db", return_value=mock_supabase):
            result = await get_substitute_exercise(
                exercise_name="Barbell Squat",
                muscle_group="quadriceps",
                user_id=MOCK_USER_ID,
                avoided_exercises=["barbell squat", "lunge"],
                equipment=["machine", "dumbbell"],
            )

        assert result is not None
        assert result["name"] in ["Leg Extension", "Step Up"]
        assert "substituted_for" in result
        assert result["substituted_for"] == "Barbell Squat"

    @pytest.mark.asyncio
    async def test_get_substitute_filters_avoided(self, mock_supabase):
        """Test that substitutes don't include other avoided exercises."""
        from api.v1.workouts.utils import get_substitute_exercise

        # Return exercises that include an avoided one
        mock_result = MagicMock()
        mock_result.data = [
            {"name": "Lunge", "target_muscle": "quadriceps", "body_part": "upper legs", "equipment": "bodyweight"},
            {"name": "Leg Press", "target_muscle": "quadriceps", "body_part": "upper legs", "equipment": "machine"},
        ]
        mock_supabase.client.table.return_value.select.return_value.or_.return_value.limit.return_value.execute.return_value = mock_result

        with patch("api.v1.workouts.utils.get_supabase_db", return_value=mock_supabase):
            result = await get_substitute_exercise(
                exercise_name="Barbell Squat",
                muscle_group="quadriceps",
                user_id=MOCK_USER_ID,
                avoided_exercises=["barbell squat", "lunge"],  # Lunge is also avoided
                equipment=None,
            )

        # Should return Leg Press, not Lunge
        assert result is not None
        assert result["name"] == "Leg Press"

    @pytest.mark.asyncio
    async def test_auto_substitute_filtered_exercises(self, mock_supabase):
        """Test auto-substituting multiple filtered exercises."""
        from api.v1.workouts.utils import auto_substitute_filtered_exercises

        # Mock substitutes
        mock_result = MagicMock()
        mock_result.data = [
            {"name": "Goblet Squat", "target_muscle": "quadriceps", "body_part": "upper legs", "equipment": "dumbbell"},
        ]
        mock_supabase.client.table.return_value.select.return_value.or_.return_value.limit.return_value.execute.return_value = mock_result

        exercises = [
            {"name": "Bench Press", "muscle_group": "chest", "sets": 3, "reps": "10"},
        ]
        filtered = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps", "sets": 4, "reps": "8"},
        ]

        with patch("api.v1.workouts.utils.get_supabase_db", return_value=mock_supabase):
            result = await auto_substitute_filtered_exercises(
                exercises=exercises.copy(),
                filtered_exercises=filtered,
                user_id=MOCK_USER_ID,
                avoided_exercises=["barbell squat"],
                equipment=["dumbbell"],
            )

        # Should have added a substitute
        assert len(result) == 2
        substitute = next((ex for ex in result if ex.get("substituted_for")), None)
        assert substitute is not None
        assert substitute["substituted_for"] == "Barbell Squat"


class TestInjuryMappings:
    """Tests for injury detection and mapping functions."""

    def test_detect_injury_type_knee(self):
        """Test detecting knee injury from reason text."""
        from api.v1.exercise_preferences import detect_injury_type

        assert detect_injury_type("knee injury") == "knee"
        assert detect_injury_type("my knee hurts") == "knee"
        assert detect_injury_type("I have patella problems") == "knee"
        assert detect_injury_type("ACL surgery recovery") == "knee"

    def test_detect_injury_type_back(self):
        """Test detecting back injury from reason text."""
        from api.v1.exercise_preferences import detect_injury_type

        assert detect_injury_type("lower back pain") == "back"
        assert detect_injury_type("spine issues") == "back"
        assert detect_injury_type("herniated disc") == "back"
        assert detect_injury_type("lumbar problems") == "back"

    def test_detect_injury_type_shoulder(self):
        """Test detecting shoulder injury from reason text."""
        from api.v1.exercise_preferences import detect_injury_type

        assert detect_injury_type("shoulder injury") == "shoulder"
        assert detect_injury_type("rotator cuff tear") == "shoulder"
        assert detect_injury_type("deltoid strain") == "shoulder"

    def test_detect_injury_type_no_match(self):
        """Test that non-injury reasons return None."""
        from api.v1.exercise_preferences import detect_injury_type

        assert detect_injury_type("I just don't like it") is None
        assert detect_injury_type("prefer other exercises") is None
        assert detect_injury_type("") is None

    def test_get_exercise_muscle_group(self):
        """Test getting muscle group for common exercises."""
        from api.v1.exercise_preferences import get_exercise_muscle_group

        assert get_exercise_muscle_group("Barbell Squat") == "quadriceps"
        assert get_exercise_muscle_group("Lunge") == "quadriceps"
        assert get_exercise_muscle_group("Bench Press") == "chest"
        assert get_exercise_muscle_group("Deadlift") == "back"
        assert get_exercise_muscle_group("Shoulder Press") == "shoulders"


class TestSwapSuggestionFiltering:
    """Tests for filtering avoided exercises from swap suggestions."""

    def test_suggestion_request_with_avoided_exercises(self, client, mock_supabase):
        """Test that suggestion request accepts avoided_exercises parameter."""
        # This tests the API schema accepts the new field
        from api.v1.exercise_suggestions import SuggestionRequest

        request = SuggestionRequest(
            user_id=MOCK_USER_ID,
            message="I want an alternative",
            current_exercise={
                "name": "Barbell Squat",
                "sets": 3,
                "reps": 10,
            },
            avoided_exercises=["Lunge", "Walking Lunge", "Bulgarian Split Squat"],
        )

        assert request.avoided_exercises is not None
        assert len(request.avoided_exercises) == 3
        assert "Lunge" in request.avoided_exercises

    def test_state_includes_avoided_exercises(self):
        """Test that suggestion state includes avoided_exercises field."""
        from services.langgraph_agents.exercise_suggestion.state import ExerciseSuggestionState
        import typing

        # Check that avoided_exercises is in the TypedDict
        hints = typing.get_type_hints(ExerciseSuggestionState)
        assert "avoided_exercises" in hints
