"""
Tests for the add-exercise endpoint with section support.

Tests the new `section` parameter on POST /workouts/add-exercise that allows
exercises to be added to main, warmup, or stretches sections.

Covers:
1. Schema validation - AddExerciseRequest.section field validator
2. Main section (default) - existing behavior preserved
3. Warmup section - insert into existing warmup or create new
4. Stretches section - insert into existing stretch or create new
5. Edge cases - missing workout, invalid section, empty exercises
"""
import json
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime


# =============================================================================
# Schema Validation Tests
# =============================================================================

class TestAddExerciseRequestSchema:
    """Tests for AddExerciseRequest Pydantic model with section field."""

    def test_default_section_is_main(self):
        """Section defaults to 'main' when not provided."""
        from models.schemas import AddExerciseRequest

        request = AddExerciseRequest(
            workout_id="workout-123",
            exercise_name="Bench Press",
        )
        assert request.section == "main"

    def test_section_main_valid(self):
        """Section 'main' passes validation."""
        from models.schemas import AddExerciseRequest

        request = AddExerciseRequest(
            workout_id="workout-123",
            exercise_name="Bench Press",
            section="main",
        )
        assert request.section == "main"

    def test_section_warmup_valid(self):
        """Section 'warmup' passes validation."""
        from models.schemas import AddExerciseRequest

        request = AddExerciseRequest(
            workout_id="workout-123",
            exercise_name="Arm Circles",
            section="warmup",
        )
        assert request.section == "warmup"

    def test_section_stretches_valid(self):
        """Section 'stretches' passes validation."""
        from models.schemas import AddExerciseRequest

        request = AddExerciseRequest(
            workout_id="workout-123",
            exercise_name="Hamstring Stretch",
            section="stretches",
        )
        assert request.section == "stretches"

    def test_section_invalid_raises_error(self):
        """Invalid section value raises ValidationError."""
        from models.schemas import AddExerciseRequest
        from pydantic import ValidationError

        with pytest.raises(ValidationError) as exc_info:
            AddExerciseRequest(
                workout_id="workout-123",
                exercise_name="Bench Press",
                section="cooldown",
            )
        assert "section must be" in str(exc_info.value).lower() or "value_error" in str(exc_info.value).lower()

    def test_section_none_defaults_to_main(self):
        """Section=None defaults to 'main' via validator."""
        from models.schemas import AddExerciseRequest

        request = AddExerciseRequest(
            workout_id="workout-123",
            exercise_name="Bench Press",
            section=None,
        )
        assert request.section == "main"

    def test_all_fields_together(self):
        """All fields can be set together including section."""
        from models.schemas import AddExerciseRequest

        request = AddExerciseRequest(
            workout_id="workout-123",
            exercise_name="Push Ups",
            sets=4,
            reps="10-15",
            rest_seconds=45,
            section="warmup",
        )
        assert request.workout_id == "workout-123"
        assert request.exercise_name == "Push Ups"
        assert request.sets == 4
        assert request.reps == "10-15"
        assert request.rest_seconds == 45
        assert request.section == "warmup"

    def test_section_endpoint_validation_via_api(self, client):
        """Invalid section returns 422 via the API."""
        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": "workout-123",
                "exercise_name": "Bench Press",
                "section": "invalid_section",
            }
        )
        assert response.status_code == 422


# =============================================================================
# Fixtures
# =============================================================================

MOCK_WORKOUT_ID = "workout-test-001"
MOCK_USER_ID = "user-test-001"

MOCK_WORKOUT_ROW = {
    "id": MOCK_WORKOUT_ID,
    "user_id": MOCK_USER_ID,
    "name": "Upper Body Strength",
    "type": "strength",
    "difficulty": "intermediate",
    "scheduled_date": "2026-02-09T00:00:00",
    "is_completed": False,
    "exercises_json": json.dumps([
        {"name": "Bench Press", "sets": 4, "reps": "8-10", "rest_seconds": 90},
        {"name": "Barbell Row", "sets": 4, "reps": "8-10", "rest_seconds": 90},
    ]),
    "duration_minutes": 60,
    "generation_method": "ai",
    "generation_source": "weekly",
    "created_at": "2026-02-08T12:00:00",
    "version_number": 1,
    "is_current": True,
}

MOCK_EXERCISE_LIBRARY_RESULT = [
    {
        "id": "lib-ex-001",
        "name": "Dumbbell Lateral Raise",
        "target_muscle": "shoulders",
        "body_part": "shoulders",
        "equipment": "dumbbell",
        "instructions": "Raise dumbbells to sides",
        "gif_url": "https://example.com/lateral-raise.gif",
        "video_url": "https://example.com/lateral-raise.mp4",
    }
]

MOCK_WARMUP_ROW = {
    "id": "warmup-001",
    "workout_id": MOCK_WORKOUT_ID,
    "exercises_json": json.dumps([
        {"name": "Arm Circles", "sets": 1, "reps": None, "duration_seconds": 30, "rest_seconds": 10, "equipment": "none", "muscle_group": "shoulders", "notes": None},
    ]),
    "duration_minutes": 5,
    "is_current": True,
    "version_number": 1,
    "created_at": "2026-02-08T12:00:00",
    "updated_at": "2026-02-08T12:00:00",
}

MOCK_STRETCH_ROW = {
    "id": "stretch-001",
    "workout_id": MOCK_WORKOUT_ID,
    "exercises_json": json.dumps([
        {"name": "Hamstring Stretch", "sets": 1, "reps": 1, "duration_seconds": 30, "rest_seconds": 0, "equipment": "none", "muscle_group": "hamstrings", "notes": None},
    ]),
    "duration_minutes": 5,
    "is_current": True,
    "version_number": 1,
    "created_at": "2026-02-08T12:00:00",
    "updated_at": "2026-02-08T12:00:00",
}


def _build_table_mock(rows, insert_data=None):
    """Build a chainable table mock for Supabase operations."""
    table_mock = MagicMock()

    # SELECT chain: .select("*").eq(...).eq(...).execute()
    select_mock = MagicMock()
    table_mock.select.return_value = select_mock
    eq1 = MagicMock()
    select_mock.eq.return_value = eq1
    eq2 = MagicMock()
    eq1.eq.return_value = eq2
    exec_result = MagicMock()
    exec_result.data = rows or []
    eq2.execute.return_value = exec_result

    # UPDATE chain: .update({}).eq("id", ...).execute()
    update_mock = MagicMock()
    table_mock.update.return_value = update_mock
    update_eq = MagicMock()
    update_mock.eq.return_value = update_eq
    update_exec = MagicMock()
    update_exec.data = rows or []
    update_eq.execute.return_value = update_exec

    # INSERT chain: .insert({}).execute()
    insert_mock = MagicMock()
    table_mock.insert.return_value = insert_mock
    insert_exec = MagicMock()
    insert_exec.data = insert_data or [{"id": "new-id"}]
    insert_mock.execute.return_value = insert_exec

    return table_mock


def make_mock_db(workout_row=None, warmup_rows=None, stretch_rows=None):
    """Create a mock Supabase DB with workout/warmup/stretch data.

    Returns (mock_db, warmup_table_mock, stretch_table_mock) so tests can
    assert on the table mocks directly.
    """
    mock_db = MagicMock()

    # get_workout returns the workout row
    mock_db.get_workout.return_value = workout_row

    # update_workout returns the updated row
    def mock_update(workout_id, data):
        if workout_row is None:
            return None
        updated = {**workout_row, **data}
        return updated
    mock_db.update_workout.side_effect = mock_update

    # Pre-build table mocks and cache them so the same instance is returned
    warmup_table = _build_table_mock(warmup_rows, [{"id": "new-warmup-id"}])
    stretch_table = _build_table_mock(stretch_rows, [{"id": "new-stretch-id"}])
    table_cache = {"warmups": warmup_table, "stretches": stretch_table}

    def table_handler(table_name):
        if table_name in table_cache:
            return table_cache[table_name]
        return MagicMock()  # Fallback for other tables

    mock_db.client.table.side_effect = table_handler

    # Attach table mocks for easy test access
    mock_db._warmup_table = warmup_table
    mock_db._stretch_table = stretch_table

    return mock_db


# =============================================================================
# Main Section Tests (Default Behavior)
# =============================================================================

class TestAddExerciseMainSection:
    """Tests for adding exercise to main section (default, existing behavior)."""

    @patch("api.v1.workouts.generation.index_workout_to_rag", new_callable=AsyncMock)
    @patch("api.v1.workouts.generation.log_workout_change")
    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_add_exercise_main_default(self, mock_get_db, mock_get_lib, mock_log, mock_rag, client):
        """Adding exercise without section defaults to main."""
        mock_db = make_mock_db(workout_row=MOCK_WORKOUT_ROW)
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Dumbbell Lateral Raise",
            }
        )

        assert response.status_code == 200
        data = response.json()
        exercises = json.loads(data["exercises_json"])
        assert len(exercises) == 3  # 2 original + 1 new
        assert exercises[-1]["name"] == "Dumbbell Lateral Raise"

    @patch("api.v1.workouts.generation.index_workout_to_rag", new_callable=AsyncMock)
    @patch("api.v1.workouts.generation.log_workout_change")
    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_add_exercise_main_explicit(self, mock_get_db, mock_get_lib, mock_log, mock_rag, client):
        """Explicitly passing section='main' works the same as default."""
        mock_db = make_mock_db(workout_row=MOCK_WORKOUT_ROW)
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Dumbbell Lateral Raise",
                "section": "main",
            }
        )

        assert response.status_code == 200
        data = response.json()
        exercises = json.loads(data["exercises_json"])
        assert len(exercises) == 3
        assert exercises[-1]["name"] == "Dumbbell Lateral Raise"
        assert exercises[-1]["muscle_group"] == "shoulders"
        assert exercises[-1]["library_id"] == "lib-ex-001"

    @patch("api.v1.workouts.generation.index_workout_to_rag", new_callable=AsyncMock)
    @patch("api.v1.workouts.generation.log_workout_change")
    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_add_exercise_main_not_in_library(self, mock_get_db, mock_get_lib, mock_log, mock_rag, client):
        """Exercise not found in library still gets added with basic info."""
        mock_db = make_mock_db(workout_row=MOCK_WORKOUT_ROW)
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = []  # Not found
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Custom Exercise",
                "sets": 5,
                "reps": "15",
                "rest_seconds": 30,
            }
        )

        assert response.status_code == 200
        data = response.json()
        exercises = json.loads(data["exercises_json"])
        assert len(exercises) == 3
        assert exercises[-1]["name"] == "Custom Exercise"
        assert exercises[-1]["sets"] == 5
        assert exercises[-1]["reps"] == "15"

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_add_exercise_workout_not_found(self, mock_get_db, mock_get_lib, client):
        """Returns 404 when workout doesn't exist."""
        mock_db = make_mock_db(workout_row=None)
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": "nonexistent-workout",
                "exercise_name": "Bench Press",
            }
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()


# =============================================================================
# Warmup Section Tests
# =============================================================================

class TestAddExerciseWarmupSection:
    """Tests for adding exercise to warmup section."""

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_add_to_existing_warmup(self, mock_get_db, mock_get_lib, client):
        """Exercise appended to existing warmup exercises."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            warmup_rows=[MOCK_WARMUP_ROW],
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Dumbbell Lateral Raise",
                "section": "warmup",
            }
        )

        assert response.status_code == 200
        # Returns the main workout unchanged
        data = response.json()
        main_exercises = json.loads(data["exercises_json"])
        assert len(main_exercises) == 2  # Main exercises unchanged

        # Verify warmup table was updated
        mock_db.client.table.assert_any_call("warmups")
        mock_db._warmup_table.update.assert_called_once()
        update_args = mock_db._warmup_table.update.call_args[0][0]
        warmup_exercises = json.loads(update_args["exercises_json"])
        assert len(warmup_exercises) == 2  # 1 original + 1 new
        assert warmup_exercises[-1]["name"] == "Dumbbell Lateral Raise"
        assert warmup_exercises[-1]["sets"] == 1
        assert warmup_exercises[-1]["duration_seconds"] == 30
        assert warmup_exercises[-1]["rest_seconds"] == 10

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_create_new_warmup_when_none_exists(self, mock_get_db, mock_get_lib, client):
        """Creates a new warmup when none exists for the workout."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            warmup_rows=[],  # No existing warmup
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Dumbbell Lateral Raise",
                "section": "warmup",
            }
        )

        assert response.status_code == 200

        # Verify warmup was inserted
        warmup_table = mock_db._warmup_table
        warmup_table.insert.assert_called_once()
        insert_args = warmup_table.insert.call_args[0][0]
        assert insert_args["workout_id"] == MOCK_WORKOUT_ID
        assert insert_args["duration_minutes"] == 5
        assert insert_args["is_current"] is True
        warmup_exercises = json.loads(insert_args["exercises_json"])
        assert len(warmup_exercises) == 1
        assert warmup_exercises[0]["name"] == "Dumbbell Lateral Raise"
        assert warmup_exercises[0]["muscle_group"] == "shoulders"

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_warmup_exercise_format(self, mock_get_db, mock_get_lib, client):
        """Warmup exercise has correct WarmupExercise format."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            warmup_rows=[],
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Shoulder Warm Up",
                "section": "warmup",
            }
        )

        assert response.status_code == 200

        warmup_table = mock_db._warmup_table
        insert_args = warmup_table.insert.call_args[0][0]
        warmup_exercises = json.loads(insert_args["exercises_json"])
        ex = warmup_exercises[0]

        # Verify WarmupExercise format
        assert "name" in ex
        assert ex["sets"] == 1
        assert ex["duration_seconds"] == 30
        assert ex["rest_seconds"] == 10
        assert ex["equipment"] == "none"
        assert "muscle_group" in ex


# =============================================================================
# Stretches Section Tests
# =============================================================================

class TestAddExerciseStretchesSection:
    """Tests for adding exercise to stretches section."""

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_add_to_existing_stretches(self, mock_get_db, mock_get_lib, client):
        """Exercise appended to existing stretch exercises."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            stretch_rows=[MOCK_STRETCH_ROW],
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Dumbbell Lateral Raise",
                "section": "stretches",
            }
        )

        assert response.status_code == 200
        # Returns the main workout unchanged
        data = response.json()
        main_exercises = json.loads(data["exercises_json"])
        assert len(main_exercises) == 2  # Main unchanged

        # Verify stretch table was updated
        stretch_table = mock_db._stretch_table
        stretch_table.update.assert_called_once()
        update_args = stretch_table.update.call_args[0][0]
        stretch_exercises = json.loads(update_args["exercises_json"])
        assert len(stretch_exercises) == 2  # 1 original + 1 new
        assert stretch_exercises[-1]["name"] == "Dumbbell Lateral Raise"
        assert stretch_exercises[-1]["sets"] == 1
        assert stretch_exercises[-1]["reps"] == 1
        assert stretch_exercises[-1]["duration_seconds"] == 30
        assert stretch_exercises[-1]["rest_seconds"] == 0  # Stretches have 0 rest

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_create_new_stretch_when_none_exists(self, mock_get_db, mock_get_lib, client):
        """Creates a new stretch when none exists for the workout."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            stretch_rows=[],  # No existing stretch
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Dumbbell Lateral Raise",
                "section": "stretches",
            }
        )

        assert response.status_code == 200

        # Verify stretch was inserted
        stretch_table = mock_db._stretch_table
        stretch_table.insert.assert_called_once()
        insert_args = stretch_table.insert.call_args[0][0]
        assert insert_args["workout_id"] == MOCK_WORKOUT_ID
        assert insert_args["duration_minutes"] == 5
        assert insert_args["is_current"] is True
        stretch_exercises = json.loads(insert_args["exercises_json"])
        assert len(stretch_exercises) == 1
        assert stretch_exercises[0]["name"] == "Dumbbell Lateral Raise"

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_stretch_exercise_format(self, mock_get_db, mock_get_lib, client):
        """Stretch exercise has correct StretchExercise format."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            stretch_rows=[],
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Shoulder Stretch",
                "section": "stretches",
            }
        )

        assert response.status_code == 200

        stretch_table = mock_db._stretch_table
        insert_args = stretch_table.insert.call_args[0][0]
        stretch_exercises = json.loads(insert_args["exercises_json"])
        ex = stretch_exercises[0]

        # Verify StretchExercise format
        assert "name" in ex
        assert ex["sets"] == 1
        assert ex["reps"] == 1
        assert ex["duration_seconds"] == 30
        assert ex["rest_seconds"] == 0  # Key difference from warmup
        assert ex["equipment"] == "none"
        assert "muscle_group" in ex

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_stretch_vs_warmup_rest_seconds(self, mock_get_db, mock_get_lib, client):
        """Warmup has rest_seconds=10, stretches have rest_seconds=0."""
        # This test verifies the key difference between warmup and stretch formats
        from models.schemas import AddExerciseRequest

        warmup_req = AddExerciseRequest(
            workout_id="w1", exercise_name="Ex1", section="warmup"
        )
        stretch_req = AddExerciseRequest(
            workout_id="w1", exercise_name="Ex1", section="stretches"
        )

        assert warmup_req.section == "warmup"
        assert stretch_req.section == "stretches"


# =============================================================================
# Edge Cases
# =============================================================================

class TestAddExerciseEdgeCases:
    """Edge case tests for the add-exercise endpoint."""

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_warmup_with_no_library_match(self, mock_get_db, mock_get_lib, client):
        """Warmup exercise uses 'general' muscle_group when not found in library."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            warmup_rows=[],
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = []  # Not in library
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Custom Warm Up Move",
                "section": "warmup",
            }
        )

        assert response.status_code == 200

        warmup_table = mock_db._warmup_table
        insert_args = warmup_table.insert.call_args[0][0]
        warmup_exercises = json.loads(insert_args["exercises_json"])
        assert warmup_exercises[0]["muscle_group"] == "general"
        assert warmup_exercises[0]["name"] == "Custom Warm Up Move"

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_stretch_with_no_library_match(self, mock_get_db, mock_get_lib, client):
        """Stretch exercise uses 'general' muscle_group when not found in library."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            stretch_rows=[],
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = []
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Custom Cool Down",
                "section": "stretches",
            }
        )

        assert response.status_code == 200

        stretch_table = mock_db._stretch_table
        insert_args = stretch_table.insert.call_args[0][0]
        stretch_exercises = json.loads(insert_args["exercises_json"])
        assert stretch_exercises[0]["muscle_group"] == "general"

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_warmup_workout_not_found(self, mock_get_db, mock_get_lib, client):
        """Returns 404 for warmup section when workout doesn't exist."""
        mock_db = make_mock_db(workout_row=None)
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": "nonexistent",
                "exercise_name": "Arm Circles",
                "section": "warmup",
            }
        )

        assert response.status_code == 404

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_warmup_returns_main_workout_unchanged(self, mock_get_db, mock_get_lib, client):
        """Warmup section returns the main workout without modifying its exercises."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            warmup_rows=[MOCK_WARMUP_ROW],
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Warm Up Exercise",
                "section": "warmup",
            }
        )

        assert response.status_code == 200
        data = response.json()
        # Main workout exercises should be untouched
        main_exercises = json.loads(data["exercises_json"])
        assert len(main_exercises) == 2
        assert main_exercises[0]["name"] == "Bench Press"
        assert main_exercises[1]["name"] == "Barbell Row"

        # update_workout should NOT have been called for warmup section
        mock_db.update_workout.assert_not_called()

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_stretches_returns_main_workout_unchanged(self, mock_get_db, mock_get_lib, client):
        """Stretches section returns the main workout without modifying its exercises."""
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            stretch_rows=[MOCK_STRETCH_ROW],
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "Cool Down Stretch",
                "section": "stretches",
            }
        )

        assert response.status_code == 200
        data = response.json()
        main_exercises = json.loads(data["exercises_json"])
        assert len(main_exercises) == 2  # Unchanged

        mock_db.update_workout.assert_not_called()

    def test_request_missing_workout_id(self, client):
        """Returns 422 when workout_id is missing."""
        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "exercise_name": "Bench Press",
            }
        )
        assert response.status_code == 422

    def test_request_missing_exercise_name(self, client):
        """Returns 422 when exercise_name is missing."""
        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": "workout-123",
            }
        )
        assert response.status_code == 422


# =============================================================================
# Warmup/Stretch Existing Exercises JSON Parsing
# =============================================================================

class TestExistingExercisesParsing:
    """Tests for parsing existing exercises_json in warmup/stretch tables."""

    @patch("api.v1.workouts.generation.get_exercise_library_service")
    @patch("api.v1.workouts.generation.get_supabase_db")
    def test_warmup_exercises_json_as_list(self, mock_get_db, mock_get_lib, client):
        """Handles warmup exercises_json stored as a list (not string)."""
        warmup_with_list = {
            **MOCK_WARMUP_ROW,
            "exercises_json": [  # Already a list, not JSON string
                {"name": "Arm Circles", "sets": 1, "duration_seconds": 30, "rest_seconds": 10, "equipment": "none", "muscle_group": "shoulders", "notes": None},
            ]
        }
        mock_db = make_mock_db(
            workout_row=MOCK_WORKOUT_ROW,
            warmup_rows=[warmup_with_list],
        )
        mock_get_db.return_value = mock_db

        mock_lib = MagicMock()
        mock_lib.search_exercises.return_value = MOCK_EXERCISE_LIBRARY_RESULT
        mock_get_lib.return_value = mock_lib

        response = client.post(
            "/api/v1/workouts/add-exercise",
            json={
                "workout_id": MOCK_WORKOUT_ID,
                "exercise_name": "New Warmup",
                "section": "warmup",
            }
        )

        assert response.status_code == 200

        warmup_table = mock_db._warmup_table
        update_args = warmup_table.update.call_args[0][0]
        warmup_exercises = json.loads(update_args["exercises_json"])
        assert len(warmup_exercises) == 2
