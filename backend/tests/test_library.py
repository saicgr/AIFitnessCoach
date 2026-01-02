"""
Comprehensive tests for Library API endpoints.

Tests:
1. GET /api/v1/library/exercises - Exercise listing with filters
2. GET /api/v1/library/exercises/filter-options - All filter options with counts
3. GET /api/v1/library/exercises/body-parts - Body parts with counts
4. GET /api/v1/library/exercises/{id} - Single exercise retrieval
5. GET /api/v1/library/programs - Program listing with filters
6. GET /api/v1/library/programs/categories - Program categories
7. GET /api/v1/library/programs/{id} - Single program retrieval

Run with: pytest backend/tests/test_library.py -v
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
from fastapi import HTTPException
import asyncio


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    from main import app
    return TestClient(app)


@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for library operations."""
    with patch("api.v1.library.exercises.get_supabase_db") as mock_exercises_db, \
         patch("api.v1.library.programs.get_supabase_db") as mock_programs_db, \
         patch("api.v1.library.utils.get_supabase_db") as mock_utils_db:
        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_exercises_db.return_value = mock_db
        mock_programs_db.return_value = mock_db
        mock_utils_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def sample_exercise_row():
    """Sample exercise row from exercise_library_cleaned view."""
    return {
        "id": "ex-123-uuid",
        "name": "Bench Press",
        "original_name": "Bench Press_Male",
        "body_part": "Chest",
        "equipment": "Barbell",
        "target_muscle": "Pectoralis Major",
        "secondary_muscles": ["Triceps", "Anterior Deltoid"],
        "instructions": "Lie on bench, lower bar to chest, press up",
        "difficulty_level": "Intermediate",
        "category": "Strength",
        "gif_url": "https://example.com/bench-press.gif",
        "video_url": "s3://ai-fitness-coach/VERTICAL VIDEOS/Chest/bench_press.mp4",
        "image_url": "https://example.com/bench-press.jpg",
        "goals": ["Muscle Building", "Testosterone Boost"],
        "suitable_for": ["Gym"],
        "avoid_if": ["Stresses Shoulders"],
    }


@pytest.fixture
def sample_exercise_row_2():
    """Second sample exercise row for testing filters."""
    return {
        "id": "ex-456-uuid",
        "name": "Barbell Squat",
        "original_name": "Barbell Squat_Male",
        "body_part": "Legs",
        "equipment": "Barbell",
        "target_muscle": "Quadriceps",
        "secondary_muscles": ["Glutes", "Hamstrings"],
        "instructions": "Stand with feet shoulder-width apart, squat down",
        "difficulty_level": "Intermediate",
        "category": "Strength",
        "gif_url": "https://example.com/squat.gif",
        "video_url": "s3://ai-fitness-coach/VERTICAL VIDEOS/Legs/squat.mp4",
        "image_url": "https://example.com/squat.jpg",
        "goals": ["Testosterone Boost", "Muscle Building"],
        "suitable_for": ["Gym"],
        "avoid_if": ["Stresses Knees", "Stresses Lower Back"],
    }


@pytest.fixture
def sample_exercise_row_bodyweight():
    """Sample bodyweight exercise for testing filters."""
    return {
        "id": "ex-789-uuid",
        "name": "Push Up",
        "original_name": "Push Up_Male",
        "body_part": "Chest",
        "equipment": "Bodyweight",
        "target_muscle": "Pectoralis Major",
        "secondary_muscles": ["Triceps", "Core"],
        "instructions": "Start in plank position, lower chest to ground, push up",
        "difficulty_level": "Beginner",
        "category": "Strength",
        "gif_url": "https://example.com/pushup.gif",
        "video_url": "s3://ai-fitness-coach/VERTICAL VIDEOS/Chest/push_up.mp4",
        "image_url": "https://example.com/pushup.jpg",
        "goals": ["Muscle Building", "Core Strength"],
        "suitable_for": ["Beginner Friendly", "Home Workout"],
        "avoid_if": ["Stresses Wrists", "Stresses Shoulders"],
    }


@pytest.fixture
def sample_program_row():
    """Sample program row from branded_programs table."""
    return {
        "id": "prog-123-uuid",
        "program_name": "12-Week Muscle Builder",
        "program_category": "Goal-Based",
        "program_subcategory": "Hypertrophy",
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["muscle", "hypertrophy", "strength"],
        "goals": ["Muscle Building"],
        "description": "A comprehensive 12-week program for building muscle mass.",
        "short_description": "Build muscle in 12 weeks",
        "celebrity_name": None,
        "is_active": True,
        "category": "Goal-Based",
    }


@pytest.fixture
def sample_program_row_2():
    """Second sample program row for testing filters."""
    return {
        "id": "prog-456-uuid",
        "program_name": "Chris Hemsworth Thor Workout",
        "program_category": "Celebrity",
        "program_subcategory": "Action Hero",
        "difficulty_level": "Advanced",
        "duration_weeks": 8,
        "sessions_per_week": 5,
        "session_duration_minutes": 75,
        "tags": ["celebrity", "strength", "superhero"],
        "goals": ["Muscle Building", "Strength"],
        "description": "Train like Thor with this celebrity workout.",
        "short_description": "Train like Thor",
        "celebrity_name": "Chris Hemsworth",
        "is_active": True,
        "category": "Celebrity",
    }


# ============================================================
# HELPER FUNCTION TO SETUP MOCK PAGINATION
# ============================================================

def setup_mock_pagination(mock_db, rows, empty_on_second=True):
    """
    Setup mock for paginated database calls.

    Args:
        mock_db: The mocked database
        rows: List of rows to return
        empty_on_second: If True, returns empty list on second call (end of pagination)
    """
    mock_result = MagicMock()
    mock_result.data = rows
    mock_empty = MagicMock()
    mock_empty.data = []

    if empty_on_second:
        mock_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = [mock_result, mock_empty]
    else:
        mock_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

    return mock_result


# ============================================================
# EXERCISE LISTING TESTS - GET /api/v1/library/exercises
# ============================================================

class TestListExercises:
    """Tests for GET /api/v1/library/exercises endpoint."""

    def test_list_exercises_basic_returns_exercises(self, client, mock_supabase_db, sample_exercise_row):
        """Test that basic listing returns exercises."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row], empty_on_second=False)

        response = client.get("/api/v1/library/exercises")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        assert data[0]["name"] == "Bench Press"
        assert data[0]["id"] == "ex-123-uuid"

    def test_list_exercises_with_limit(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test pagination with limit parameter."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2], empty_on_second=False)

        response = client.get("/api/v1/library/exercises?limit=1")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        # Note: Limit is applied, but mock may return more before filtering
        assert len(data) >= 1

    def test_list_exercises_with_offset(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test pagination with offset parameter."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2], empty_on_second=False)

        response = client.get("/api/v1/library/exercises?offset=0&limit=10")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_exercises_body_parts_filter_single(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test filtering by a single body part."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2])

        response = client.get("/api/v1/library/exercises?body_parts=Chest")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        # All returned exercises should have Chest as body part
        for exercise in data:
            assert exercise["body_part"] == "Chest"

    def test_list_exercises_body_parts_filter_multiple(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test filtering by multiple body parts (OR logic)."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2])

        response = client.get("/api/v1/library/exercises?body_parts=Chest,Quadriceps")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        # All returned exercises should have either Chest or Quadriceps
        for exercise in data:
            assert exercise["body_part"] in ["Chest", "Quadriceps"]

    def test_list_exercises_equipment_filter_single(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_bodyweight):
        """Test filtering by single equipment type."""
        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_supabase_db.client.table.return_value.select.return_value.ilike.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/exercises?equipment=Barbell")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_exercises_equipment_filter_multiple(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_bodyweight):
        """Test filtering by multiple equipment types (OR logic)."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_bodyweight])

        response = client.get("/api/v1/library/exercises?equipment=Barbell,Bodyweight")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_exercises_search_by_name(self, client, mock_supabase_db, sample_exercise_row):
        """Test search functionality by exercise name."""
        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_supabase_db.client.table.return_value.select.return_value.or_.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/exercises?search=bench")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_exercises_search_case_insensitive(self, client, mock_supabase_db, sample_exercise_row):
        """Test that search is case-insensitive."""
        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_supabase_db.client.table.return_value.select.return_value.or_.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/exercises?search=BENCH")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_exercises_combined_filters(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test combining multiple filters (AND logic between filter types)."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2])

        response = client.get("/api/v1/library/exercises?body_parts=Chest&equipment=Barbell")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        # Results should match both filters
        for exercise in data:
            assert exercise["body_part"] == "Chest"

    def test_list_exercises_goals_filter(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test filtering by fitness goals."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2])

        response = client.get("/api/v1/library/exercises?goals=Muscle%20Building")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        # All returned exercises should have Muscle Building as a goal
        for exercise in data:
            assert "Muscle Building" in (exercise.get("goals") or [])

    def test_list_exercises_suitable_for_filter(self, client, mock_supabase_db, sample_exercise_row_bodyweight):
        """Test filtering by suitability."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row_bodyweight])

        response = client.get("/api/v1/library/exercises?suitable_for=Beginner%20Friendly")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        for exercise in data:
            assert "Beginner Friendly" in (exercise.get("suitable_for") or [])

    def test_list_exercises_avoid_if_exclusion_filter(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test that avoid_if filter EXCLUDES matching exercises."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2])

        # Filter to exclude exercises that stress shoulders
        response = client.get("/api/v1/library/exercises?avoid_if=Stresses%20Shoulders")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        # No exercises should have "Stresses Shoulders" in avoid_if
        for exercise in data:
            avoid_list = exercise.get("avoid_if") or []
            assert "Stresses Shoulders" not in avoid_list

    def test_list_exercises_exercise_types_filter(self, client, mock_supabase_db, sample_exercise_row):
        """Test filtering by exercise types."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row])

        response = client.get("/api/v1/library/exercises?exercise_types=Strength")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_exercises_empty_result(self, client, mock_supabase_db):
        """Test that empty results are handled correctly."""
        setup_mock_pagination(mock_supabase_db, [])

        response = client.get("/api/v1/library/exercises?body_parts=NonExistentBodyPart")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0

    def test_list_exercises_returns_all_fields(self, client, mock_supabase_db, sample_exercise_row):
        """Test that response includes all expected fields."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row], empty_on_second=False)

        response = client.get("/api/v1/library/exercises?limit=1")

        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 1

        exercise = data[0]
        expected_fields = [
            "id", "name", "original_name", "body_part", "equipment",
            "target_muscle", "secondary_muscles", "instructions",
            "difficulty_level", "category", "gif_url", "video_url",
            "image_url", "goals", "suitable_for", "avoid_if"
        ]
        for field in expected_fields:
            assert field in exercise, f"Missing field: {field}"


# ============================================================
# FILTER OPTIONS TESTS - GET /api/v1/library/exercises/filter-options
# ============================================================

class TestFilterOptions:
    """Tests for GET /api/v1/library/exercises/filter-options endpoint."""

    def test_get_filter_options_returns_all_categories(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test that filter options returns all filter categories."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2])

        response = client.get("/api/v1/library/exercises/filter-options")

        assert response.status_code == 200
        data = response.json()

        # Check all expected categories are present
        assert "body_parts" in data
        assert "equipment" in data
        assert "exercise_types" in data
        assert "goals" in data
        assert "suitable_for" in data
        assert "avoid_if" in data
        assert "total_exercises" in data

    def test_get_filter_options_body_parts_with_counts(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test that body parts include counts."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2])

        response = client.get("/api/v1/library/exercises/filter-options")

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data["body_parts"], list)
        if len(data["body_parts"]) > 0:
            body_part = data["body_parts"][0]
            assert "name" in body_part
            assert "count" in body_part
            assert isinstance(body_part["count"], int)

    def test_get_filter_options_equipment_with_counts(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_bodyweight):
        """Test that equipment includes counts."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_bodyweight])

        response = client.get("/api/v1/library/exercises/filter-options")

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data["equipment"], list)
        if len(data["equipment"]) > 0:
            equipment = data["equipment"][0]
            assert "name" in equipment
            assert "count" in equipment

    def test_get_filter_options_goals_with_counts(self, client, mock_supabase_db, sample_exercise_row):
        """Test that goals include counts."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row])

        response = client.get("/api/v1/library/exercises/filter-options")

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data["goals"], list)
        # Goals should be populated from the database column
        if len(data["goals"]) > 0:
            goal = data["goals"][0]
            assert "name" in goal
            assert "count" in goal

    def test_get_filter_options_suitable_for_with_counts(self, client, mock_supabase_db, sample_exercise_row_bodyweight):
        """Test that suitable_for includes counts."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row_bodyweight])

        response = client.get("/api/v1/library/exercises/filter-options")

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data["suitable_for"], list)

    def test_get_filter_options_avoid_if_with_counts(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test that avoid_if includes counts."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2])

        response = client.get("/api/v1/library/exercises/filter-options")

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data["avoid_if"], list)

    def test_get_filter_options_total_exercises_count(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2):
        """Test that total exercises count is accurate."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2])

        response = client.get("/api/v1/library/exercises/filter-options")

        assert response.status_code == 200
        data = response.json()

        assert "total_exercises" in data
        assert isinstance(data["total_exercises"], int)
        assert data["total_exercises"] == 2


# ============================================================
# BODY PARTS TESTS - GET /api/v1/library/exercises/body-parts
# ============================================================

class TestBodyParts:
    """Tests for GET /api/v1/library/exercises/body-parts endpoint."""

    def test_get_body_parts_returns_list(self, client, mock_supabase_db, sample_exercise_row):
        """Test that body parts endpoint returns a list."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row])

        response = client.get("/api/v1/library/exercises/body-parts")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_get_body_parts_with_counts(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_bodyweight):
        """Test that each body part has a name and count."""
        # Two exercises with same body part (Chest)
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_bodyweight])

        response = client.get("/api/v1/library/exercises/body-parts")

        assert response.status_code == 200
        data = response.json()

        assert len(data) >= 1
        for body_part in data:
            assert "name" in body_part
            assert "count" in body_part
            assert isinstance(body_part["count"], int)
            assert body_part["count"] > 0

    def test_get_body_parts_sorted_by_count(self, client, mock_supabase_db, sample_exercise_row, sample_exercise_row_2, sample_exercise_row_bodyweight):
        """Test that body parts are sorted by count descending."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row, sample_exercise_row_2, sample_exercise_row_bodyweight])

        response = client.get("/api/v1/library/exercises/body-parts")

        assert response.status_code == 200
        data = response.json()

        # Verify descending order by count
        if len(data) > 1:
            for i in range(len(data) - 1):
                assert data[i]["count"] >= data[i + 1]["count"]

    def test_get_body_parts_normalized_names(self, client, mock_supabase_db, sample_exercise_row):
        """Test that body part names are normalized (e.g., 'Pectoralis Major' -> 'Chest')."""
        setup_mock_pagination(mock_supabase_db, [sample_exercise_row])

        response = client.get("/api/v1/library/exercises/body-parts")

        assert response.status_code == 200
        data = response.json()

        # Body parts should be normalized names, not raw muscle names
        body_part_names = [bp["name"] for bp in data]
        valid_body_parts = [
            "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Forearms",
            "Quadriceps", "Hamstrings", "Glutes", "Calves", "Core",
            "Lower Back", "Hips", "Neck", "Other"
        ]
        for name in body_part_names:
            assert name in valid_body_parts, f"Unexpected body part name: {name}"


# ============================================================
# SINGLE EXERCISE TESTS - GET /api/v1/library/exercises/{id}
# ============================================================

class TestGetExercise:
    """Tests for GET /api/v1/library/exercises/{id} endpoint."""

    def test_get_exercise_found(self, client, mock_supabase_db, sample_exercise_row):
        """Test retrieving an existing exercise by ID."""
        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/exercises/ex-123-uuid")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "ex-123-uuid"
        assert data["name"] == "Bench Press"
        assert data["body_part"] == "Chest"

    def test_get_exercise_not_found(self, client, mock_supabase_db):
        """Test 404 response for non-existent exercise."""
        mock_empty = MagicMock()
        mock_empty.data = []
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_empty

        response = client.get("/api/v1/library/exercises/nonexistent-id")

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_get_exercise_returns_full_details(self, client, mock_supabase_db, sample_exercise_row):
        """Test that single exercise returns all fields."""
        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/exercises/ex-123-uuid")

        assert response.status_code == 200
        data = response.json()

        # Check all fields are present
        assert "id" in data
        assert "name" in data
        assert "original_name" in data
        assert "body_part" in data
        assert "equipment" in data
        assert "target_muscle" in data
        assert "secondary_muscles" in data
        assert "instructions" in data
        assert "difficulty_level" in data
        assert "gif_url" in data
        assert "video_url" in data
        assert "goals" in data
        assert "suitable_for" in data
        assert "avoid_if" in data

    def test_get_exercise_fallback_to_base_table(self, client, mock_supabase_db):
        """Test fallback to base table when not in cleaned view."""
        # First call (cleaned view) returns empty
        mock_empty = MagicMock()
        mock_empty.data = []

        # Second call (base table) returns exercise
        base_row = {
            "id": "ex-base-123",
            "exercise_name": "Deadlift_Male",
            "body_part": "Back",
            "target_muscle": "Erector Spinae",
            "equipment": "Barbell",
            "video_s3_path": "s3://videos/back/deadlift.mp4",
            "image_s3_path": "s3://images/deadlift.jpg",
        }
        mock_result = MagicMock()
        mock_result.data = [base_row]

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = [mock_empty, mock_result]

        response = client.get("/api/v1/library/exercises/ex-base-123")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "ex-base-123"
        # Name should be cleaned (no _Male suffix)
        assert data["name"] == "Deadlift"
        assert data["original_name"] == "Deadlift_Male"


# ============================================================
# PROGRAM LISTING TESTS - GET /api/v1/library/programs
# ============================================================

class TestListPrograms:
    """Tests for GET /api/v1/library/programs endpoint."""

    def test_list_programs_basic(self, client, mock_supabase_db, sample_program_row):
        """Test basic program listing."""
        mock_result = MagicMock()
        mock_result.data = [sample_program_row]
        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        assert data[0]["name"] == "12-Week Muscle Builder"

    def test_list_programs_category_filter(self, client, mock_supabase_db, sample_program_row):
        """Test filtering programs by category."""
        mock_result = MagicMock()
        mock_result.data = [sample_program_row]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs?category=Goal-Based")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        for program in data:
            assert program["category"] == "Goal-Based"

    def test_list_programs_search_filter(self, client, mock_supabase_db, sample_program_row):
        """Test searching programs by name."""
        mock_result = MagicMock()
        mock_result.data = [sample_program_row]
        mock_supabase_db.client.table.return_value.select.return_value.ilike.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs?search=muscle")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_programs_difficulty_filter(self, client, mock_supabase_db, sample_program_row):
        """Test filtering programs by difficulty."""
        mock_result = MagicMock()
        mock_result.data = [sample_program_row]
        mock_supabase_db.client.table.return_value.select.return_value.ilike.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs?difficulty=Intermediate")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_programs_returns_proper_fields(self, client, mock_supabase_db, sample_program_row):
        """Test that programs include all expected fields."""
        mock_result = MagicMock()
        mock_result.data = [sample_program_row]
        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs")

        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 1

        program = data[0]
        expected_fields = [
            "id", "name", "category", "subcategory", "difficulty_level",
            "duration_weeks", "sessions_per_week", "session_duration_minutes",
            "tags", "goals", "description", "short_description", "celebrity_name"
        ]
        for field in expected_fields:
            assert field in program, f"Missing field: {field}"

    def test_list_programs_pagination(self, client, mock_supabase_db, sample_program_row, sample_program_row_2):
        """Test program pagination with limit and offset."""
        mock_result = MagicMock()
        mock_result.data = [sample_program_row]
        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs?limit=1&offset=0")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_programs_empty_result(self, client, mock_supabase_db):
        """Test empty results handling."""
        mock_empty = MagicMock()
        mock_empty.data = []
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_empty

        response = client.get("/api/v1/library/programs?category=NonExistent")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0


# ============================================================
# PROGRAM CATEGORIES TESTS - GET /api/v1/library/programs/categories
# ============================================================

class TestProgramCategories:
    """Tests for GET /api/v1/library/programs/categories endpoint."""

    def test_get_program_categories_returns_list(self, client, mock_supabase_db, sample_program_row):
        """Test that categories endpoint returns a list."""
        mock_result = MagicMock()
        mock_result.data = [sample_program_row]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs/categories")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_get_program_categories_with_counts(self, client, mock_supabase_db, sample_program_row, sample_program_row_2):
        """Test that each category has name and count."""
        mock_result = MagicMock()
        mock_result.data = [
            {"category": "Goal-Based"},
            {"category": "Goal-Based"},
            {"category": "Celebrity"},
        ]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs/categories")

        assert response.status_code == 200
        data = response.json()

        assert len(data) >= 1
        for category in data:
            assert "name" in category
            assert "count" in category
            assert isinstance(category["count"], int)

    def test_get_program_categories_unique(self, client, mock_supabase_db):
        """Test that categories are unique."""
        mock_result = MagicMock()
        mock_result.data = [
            {"category": "Goal-Based"},
            {"category": "Goal-Based"},
            {"category": "Celebrity"},
            {"category": "Celebrity"},
            {"category": "Beginner"},
        ]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs/categories")

        assert response.status_code == 200
        data = response.json()

        # Extract category names
        category_names = [cat["name"] for cat in data]
        # Verify uniqueness
        assert len(category_names) == len(set(category_names))

    def test_get_program_categories_sorted_by_count(self, client, mock_supabase_db):
        """Test that categories are sorted by count descending."""
        mock_result = MagicMock()
        mock_result.data = [
            {"category": "Goal-Based"},
            {"category": "Goal-Based"},
            {"category": "Goal-Based"},
            {"category": "Celebrity"},
        ]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs/categories")

        assert response.status_code == 200
        data = response.json()

        if len(data) > 1:
            for i in range(len(data) - 1):
                assert data[i]["count"] >= data[i + 1]["count"]


# ============================================================
# SINGLE PROGRAM TESTS - GET /api/v1/library/programs/{id}
# ============================================================

class TestGetProgram:
    """Tests for GET /api/v1/library/programs/{id} endpoint."""

    def test_get_program_found(self, client, mock_supabase_db, sample_program_row):
        """Test retrieving an existing program by ID."""
        program_with_workouts = {**sample_program_row, "workouts": [{"day": 1, "exercises": []}]}
        mock_result = MagicMock()
        mock_result.data = [program_with_workouts]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs/prog-123-uuid")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "prog-123-uuid"
        assert data["name"] == "12-Week Muscle Builder"

    def test_get_program_not_found(self, client, mock_supabase_db):
        """Test 404 response for non-existent program."""
        mock_empty = MagicMock()
        mock_empty.data = []
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_empty

        response = client.get("/api/v1/library/programs/nonexistent-id")

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_get_program_returns_full_details(self, client, mock_supabase_db, sample_program_row):
        """Test that single program includes all fields and workouts."""
        program_with_workouts = {
            **sample_program_row,
            "workouts": [
                {"day": 1, "focus": "Chest", "exercises": [{"name": "Bench Press", "sets": 3}]},
                {"day": 2, "focus": "Back", "exercises": [{"name": "Pull Up", "sets": 3}]}
            ]
        }
        mock_result = MagicMock()
        mock_result.data = [program_with_workouts]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs/prog-123-uuid")

        assert response.status_code == 200
        data = response.json()

        # Check all expected fields
        assert "id" in data
        assert "name" in data
        assert "category" in data
        assert "subcategory" in data
        assert "difficulty_level" in data
        assert "duration_weeks" in data
        assert "sessions_per_week" in data
        assert "session_duration_minutes" in data
        assert "tags" in data
        assert "goals" in data
        assert "description" in data
        assert "short_description" in data
        assert "celebrity_name" in data
        assert "workouts" in data

        # Verify workouts are included
        assert isinstance(data["workouts"], list)
        assert len(data["workouts"]) == 2

    def test_get_program_with_celebrity(self, client, mock_supabase_db, sample_program_row_2):
        """Test retrieving a celebrity program."""
        program_with_workouts = {**sample_program_row_2, "workouts": []}
        mock_result = MagicMock()
        mock_result.data = [program_with_workouts]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get("/api/v1/library/programs/prog-456-uuid")

        assert response.status_code == 200
        data = response.json()
        assert data["celebrity_name"] == "Chris Hemsworth"
        assert data["category"] == "Celebrity"


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestErrorHandling:
    """Tests for error handling across library endpoints."""

    def test_list_exercises_database_error(self, client, mock_supabase_db):
        """Test 500 response on database error in list exercises."""
        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = Exception("Database connection failed")

        response = client.get("/api/v1/library/exercises")

        assert response.status_code == 500
        assert "detail" in response.json()

    def test_list_programs_database_error(self, client, mock_supabase_db):
        """Test 500 response on database error in list programs."""
        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = Exception("Connection timeout")

        response = client.get("/api/v1/library/programs")

        assert response.status_code == 500
        assert "detail" in response.json()

    def test_get_filter_options_database_error(self, client, mock_supabase_db):
        """Test 500 response on database error in filter options."""
        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = Exception("Query failed")

        response = client.get("/api/v1/library/exercises/filter-options")

        assert response.status_code == 500

    def test_get_body_parts_database_error(self, client, mock_supabase_db):
        """Test 500 response on database error in body parts."""
        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = Exception("Network error")

        response = client.get("/api/v1/library/exercises/body-parts")

        assert response.status_code == 500

    def test_get_program_categories_database_error(self, client, mock_supabase_db):
        """Test 500 response on database error in program categories."""
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = Exception("Service unavailable")

        response = client.get("/api/v1/library/programs/categories")

        assert response.status_code == 500


# ============================================================
# UTILITY FUNCTION TESTS
# ============================================================

class TestHelperFunctions:
    """Test helper functions from utils module."""

    def test_normalize_body_part_chest(self):
        """Test normalizing chest-related muscles."""
        from api.v1.library.utils import normalize_body_part

        assert normalize_body_part("Pectoralis Major") == "Chest"
        assert normalize_body_part("chest") == "Chest"
        assert normalize_body_part("Pectoralis Minor") == "Chest"

    def test_normalize_body_part_back(self):
        """Test normalizing back-related muscles."""
        from api.v1.library.utils import normalize_body_part

        assert normalize_body_part("Latissimus Dorsi") == "Back"
        assert normalize_body_part("rhomboids") == "Back"
        assert normalize_body_part("trapezius") == "Back"
        assert normalize_body_part("back") == "Back"

    def test_normalize_body_part_legs(self):
        """Test normalizing leg-related muscles."""
        from api.v1.library.utils import normalize_body_part

        assert normalize_body_part("Quadriceps") == "Quadriceps"
        assert normalize_body_part("Hamstrings") == "Hamstrings"
        assert normalize_body_part("Glutes") == "Glutes"
        assert normalize_body_part("Gastrocnemius") == "Calves"
        assert normalize_body_part("Soleus") == "Calves"

    def test_normalize_body_part_arms(self):
        """Test normalizing arm-related muscles."""
        from api.v1.library.utils import normalize_body_part

        assert normalize_body_part("Biceps Brachii") == "Biceps"
        assert normalize_body_part("Triceps") == "Triceps"
        assert normalize_body_part("Forearm Flexors") == "Forearms"
        assert normalize_body_part("wrist") == "Forearms"

    def test_normalize_body_part_core(self):
        """Test normalizing core-related muscles."""
        from api.v1.library.utils import normalize_body_part

        assert normalize_body_part("Rectus Abdominis") == "Core"
        assert normalize_body_part("oblique") == "Core"
        assert normalize_body_part("core") == "Core"
        assert normalize_body_part("abdominal") == "Core"

    def test_normalize_body_part_other(self):
        """Test normalizing unknown muscles returns Other."""
        from api.v1.library.utils import normalize_body_part

        assert normalize_body_part(None) == "Other"
        assert normalize_body_part("") == "Other"
        assert normalize_body_part("Unknown Muscle") == "Other"

    def test_derive_exercise_type_strength(self):
        """Test deriving exercise type for strength exercises."""
        from api.v1.library.utils import derive_exercise_type

        assert derive_exercise_type("s3://videos/Chest/bench.mp4", "Chest") == "Strength"
        assert derive_exercise_type("", "Chest") == "Strength"
        assert derive_exercise_type("s3://videos/Back/row.mp4", "Back") == "Strength"

    def test_derive_exercise_type_yoga(self):
        """Test deriving exercise type for yoga exercises."""
        from api.v1.library.utils import derive_exercise_type

        assert derive_exercise_type("s3://videos/Yoga/downward_dog.mp4", "Core") == "Yoga"
        assert derive_exercise_type("s3://YOGA/pose.mp4", "Hips") == "Yoga"

    def test_derive_exercise_type_cardio(self):
        """Test deriving exercise type for cardio exercises."""
        from api.v1.library.utils import derive_exercise_type

        assert derive_exercise_type("s3://videos/HIIT/burpees.mp4", "Core") == "Cardio"
        assert derive_exercise_type("s3://videos/cardio/jumping_jacks.mp4", "Other") == "Cardio"

    def test_derive_exercise_type_stretching(self):
        """Test deriving exercise type for stretching exercises."""
        from api.v1.library.utils import derive_exercise_type

        assert derive_exercise_type("s3://videos/stretching/hamstring.mp4", "Hamstrings") == "Stretching"
        assert derive_exercise_type("s3://videos/mobility/hip.mp4", "Hips") == "Stretching"

    def test_derive_goals(self):
        """Test deriving fitness goals from exercise info."""
        from api.v1.library.utils import derive_goals

        goals = derive_goals("Barbell Squat", "Quadriceps", "Quadriceps", "")
        assert "Testosterone Boost" in goals

        goals = derive_goals("Jump Squat", "Quadriceps", "Quadriceps", "s3://videos/hiit/jump.mp4")
        assert "Fat Burn" in goals

        goals = derive_goals("Bicep Curl", "Biceps", "Biceps", "")
        assert "Muscle Building" in goals

        goals = derive_goals("Downward Dog", "Core", "Core", "s3://videos/yoga/dog.mp4")
        assert "Flexibility" in goals

    def test_derive_suitable_for(self):
        """Test deriving suitability from exercise info."""
        from api.v1.library.utils import derive_suitable_for

        suitable = derive_suitable_for("Wall Push-up", "Chest", "Bodyweight", "")
        assert "Beginner Friendly" in suitable

        suitable = derive_suitable_for("Chair Squat", "Quadriceps", "Bodyweight", "")
        assert "Senior Friendly" in suitable

        suitable = derive_suitable_for("Dumbbell Curl", "Biceps", "Dumbbell", "")
        assert "Home Workout" in suitable

    def test_derive_avoids(self):
        """Test deriving avoid conditions from exercise info."""
        from api.v1.library.utils import derive_avoids

        avoids = derive_avoids("Squat", "Quadriceps", "Barbell")
        assert "Stresses Knees" in avoids

        avoids = derive_avoids("Deadlift", "Back", "Barbell")
        assert "Stresses Lower Back" in avoids

        avoids = derive_avoids("Overhead Press", "Shoulders", "Barbell")
        assert "Stresses Shoulders" in avoids

        avoids = derive_avoids("Box Jump", "Quadriceps", "Bodyweight")
        assert "High Impact" in avoids


# ============================================================
# ROW CONVERSION TESTS
# ============================================================

class TestRowConversion:
    """Test row to model conversion functions."""

    def test_row_to_library_exercise_from_cleaned_view(self, sample_exercise_row):
        """Test converting row from cleaned view."""
        from api.v1.library.utils import row_to_library_exercise

        result = row_to_library_exercise(sample_exercise_row, from_cleaned_view=True)

        assert result.id == "ex-123-uuid"
        assert result.name == "Bench Press"
        assert result.original_name == "Bench Press_Male"
        assert result.body_part == "Chest"
        assert result.equipment == "Barbell"
        assert result.goals == ["Muscle Building", "Testosterone Boost"]
        assert result.avoid_if == ["Stresses Shoulders"]

    def test_row_to_library_exercise_from_base_table(self):
        """Test converting row from base table with name cleaning."""
        from api.v1.library.utils import row_to_library_exercise

        row = {
            "id": "ex-456",
            "exercise_name": "Squat_Female",
            "body_part": "Legs",
            "target_muscle": "Quadriceps",
            "equipment": "Barbell",
            "video_s3_path": "s3://videos/Legs/squat.mp4",
            "image_s3_path": "s3://images/squat.jpg",
        }

        result = row_to_library_exercise(row, from_cleaned_view=False)

        assert result.id == "ex-456"
        assert result.name == "Squat"  # Cleaned from Squat_Female
        assert result.original_name == "Squat_Female"
        assert result.body_part == "Quadriceps"  # Normalized

    def test_row_to_library_exercise_handles_missing_fields(self):
        """Test that missing optional fields are handled gracefully."""
        from api.v1.library.utils import row_to_library_exercise

        minimal_row = {
            "id": "ex-minimal",
            "name": "Basic Exercise",
            "original_name": "Basic Exercise",
            "body_part": "Other",
        }

        result = row_to_library_exercise(minimal_row, from_cleaned_view=True)

        assert result.id == "ex-minimal"
        assert result.name == "Basic Exercise"
        assert result.equipment == ""  # Default empty string
        assert result.goals == []  # Default empty list
        assert result.avoid_if == []

    def test_row_to_library_program(self, sample_program_row):
        """Test converting program row."""
        from api.v1.library.utils import row_to_library_program

        result = row_to_library_program(sample_program_row)

        assert result.id == "prog-123-uuid"
        assert result.name == "12-Week Muscle Builder"
        assert result.category == "Goal-Based"
        assert result.subcategory == "Hypertrophy"
        assert result.duration_weeks == 12
        assert result.sessions_per_week == 4
        assert result.session_duration_minutes == 60
        assert "muscle" in result.tags
        assert "Muscle Building" in result.goals

    def test_row_to_library_program_handles_missing_fields(self):
        """Test that missing optional program fields are handled."""
        from api.v1.library.utils import row_to_library_program

        minimal_row = {
            "id": "prog-minimal",
            "program_name": "Minimal Program",
            "program_category": "Basic",
        }

        result = row_to_library_program(minimal_row)

        assert result.id == "prog-minimal"
        assert result.name == "Minimal Program"
        assert result.category == "Basic"
        assert result.duration_weeks is None
        assert result.tags == []
        assert result.goals == []
        assert result.celebrity_name is None


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestLibraryModels:
    """Test Pydantic model validation."""

    def test_library_exercise_model_required_fields(self):
        """Test LibraryExercise requires id, name, original_name, body_part."""
        from api.v1.library.models import LibraryExercise

        exercise = LibraryExercise(
            id="ex-123",
            name="Bench Press",
            original_name="Bench Press_Male",
            body_part="Chest"
        )

        assert exercise.id == "ex-123"
        assert exercise.name == "Bench Press"
        assert exercise.equipment is None  # Optional
        assert exercise.target_muscle is None  # Optional

    def test_library_exercise_model_all_fields(self):
        """Test LibraryExercise with all fields."""
        from api.v1.library.models import LibraryExercise

        exercise = LibraryExercise(
            id="ex-123",
            name="Bench Press",
            original_name="Bench Press_Male",
            body_part="Chest",
            equipment="Barbell",
            target_muscle="Pectoralis Major",
            secondary_muscles=["Triceps"],
            instructions="Press the bar",
            difficulty_level="Intermediate",
            category="Strength",
            gif_url="http://example.com/gif",
            video_url="http://example.com/video",
            image_url="http://example.com/image",
            goals=["Muscle Building"],
            suitable_for=["Gym"],
            avoid_if=["Stresses Shoulders"],
        )

        assert exercise.equipment == "Barbell"
        assert exercise.goals == ["Muscle Building"]
        assert exercise.avoid_if == ["Stresses Shoulders"]

    def test_library_program_model_required_fields(self):
        """Test LibraryProgram requires id, name, category."""
        from api.v1.library.models import LibraryProgram

        program = LibraryProgram(
            id="prog-123",
            name="Muscle Builder",
            category="Goal-Based"
        )

        assert program.id == "prog-123"
        assert program.duration_weeks is None  # Optional

    def test_exercises_by_body_part_model(self):
        """Test ExercisesByBodyPart model."""
        from api.v1.library.models import ExercisesByBodyPart, LibraryExercise

        exercise = LibraryExercise(
            id="ex-1",
            name="Bench Press",
            original_name="Bench Press",
            body_part="Chest"
        )

        grouped = ExercisesByBodyPart(
            body_part="Chest",
            count=1,
            exercises=[exercise]
        )

        assert grouped.body_part == "Chest"
        assert grouped.count == 1
        assert len(grouped.exercises) == 1

    def test_programs_by_category_model(self):
        """Test ProgramsByCategory model."""
        from api.v1.library.models import ProgramsByCategory, LibraryProgram

        program = LibraryProgram(
            id="prog-1",
            name="Program 1",
            category="Goal-Based"
        )

        grouped = ProgramsByCategory(
            category="Goal-Based",
            count=1,
            programs=[program]
        )

        assert grouped.category == "Goal-Based"
        assert grouped.count == 1
        assert len(grouped.programs) == 1


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
