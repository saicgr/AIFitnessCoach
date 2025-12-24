"""
Tests for Library API endpoints.

Tests:
- Exercise listing and filtering
- Exercise body parts and equipment
- Exercise grouping
- Single exercise retrieval
- Program listing and filtering
- Program categories
- Single program retrieval

Run with: pytest backend/tests/test_library_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for library operations."""
    with patch("api.v1.library.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def sample_exercise_row():
    return {
        "id": "ex-123",
        "name": "Bench Press",
        "original_name": "Bench Press_Male",
        "body_part": "Chest",
        "equipment": "Barbell",
        "target_muscle": "Pectoralis Major",
        "secondary_muscles": "Triceps, Anterior Deltoid",
        "instructions": "Lie on bench, lower bar to chest, press up",
        "difficulty_level": 3,
        "category": "Strength",
        "gif_url": "https://example.com/bench-press.gif",
        "video_url": "s3://ai-fitness-coach/VERTICAL VIDEOS/Chest/bench_press.mp4",
        "image_url": "https://example.com/bench-press.jpg",
        "goals": ["Muscle Building", "Testosterone Boost"],
        "suitable_for": ["Gym"],
        "avoid_if": ["Stresses Shoulders"],
    }


@pytest.fixture
def sample_program_row():
    return {
        "id": "prog-123",
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
    }


# ============================================================
# HELPER FUNCTION TESTS
# ============================================================

class TestHelperFunctions:
    """Test helper functions."""

    def test_normalize_body_part_chest(self):
        """Test normalizing chest-related muscles."""
        from api.v1.library import normalize_body_part

        assert normalize_body_part("Pectoralis Major") == "Chest"
        assert normalize_body_part("chest") == "Chest"

    def test_normalize_body_part_back(self):
        """Test normalizing back-related muscles."""
        from api.v1.library import normalize_body_part

        assert normalize_body_part("Latissimus Dorsi") == "Back"
        assert normalize_body_part("rhomboids") == "Back"
        assert normalize_body_part("trapezius") == "Back"

    def test_normalize_body_part_legs(self):
        """Test normalizing leg-related muscles."""
        from api.v1.library import normalize_body_part

        assert normalize_body_part("Quadriceps") == "Quadriceps"
        assert normalize_body_part("Hamstrings") == "Hamstrings"
        assert normalize_body_part("Glutes") == "Glutes"
        assert normalize_body_part("Gastrocnemius") == "Calves"

    def test_normalize_body_part_arms(self):
        """Test normalizing arm-related muscles."""
        from api.v1.library import normalize_body_part

        assert normalize_body_part("Biceps Brachii") == "Biceps"
        assert normalize_body_part("Triceps") == "Triceps"
        assert normalize_body_part("Forearm Flexors") == "Forearms"

    def test_normalize_body_part_other(self):
        """Test normalizing unknown muscles."""
        from api.v1.library import normalize_body_part

        assert normalize_body_part(None) == "Other"
        assert normalize_body_part("Unknown Muscle") == "Other"

    def test_derive_exercise_type_strength(self):
        """Test deriving exercise type for strength."""
        from api.v1.library import derive_exercise_type

        assert derive_exercise_type("s3://videos/Chest/bench.mp4", "Chest") == "Strength"
        assert derive_exercise_type("", "Chest") == "Strength"

    def test_derive_exercise_type_yoga(self):
        """Test deriving exercise type for yoga."""
        from api.v1.library import derive_exercise_type

        assert derive_exercise_type("s3://videos/Yoga/downward_dog.mp4", "Core") == "Yoga"

    def test_derive_exercise_type_cardio(self):
        """Test deriving exercise type for cardio."""
        from api.v1.library import derive_exercise_type

        assert derive_exercise_type("s3://videos/HIIT/burpees.mp4", "Core") == "Cardio"

    def test_derive_goals(self):
        """Test deriving fitness goals from exercise info."""
        from api.v1.library import derive_goals

        goals = derive_goals("Barbell Squat", "Quadriceps", "Quadriceps", "")
        assert "Testosterone Boost" in goals

        goals = derive_goals("Jump Squat", "Quadriceps", "Quadriceps", "")
        assert "Fat Burn" in goals

        goals = derive_goals("Bicep Curl", "Biceps", "Biceps", "")
        assert "Muscle Building" in goals

    def test_derive_suitable_for(self):
        """Test deriving suitability from exercise info."""
        from api.v1.library import derive_suitable_for

        suitable = derive_suitable_for("Wall Push-up", "Chest", "Bodyweight", "")
        assert "Beginner Friendly" in suitable

        suitable = derive_suitable_for("Chair Squat", "Quadriceps", "Bodyweight", "")
        assert "Senior Friendly" in suitable

    def test_derive_avoids(self):
        """Test deriving avoid conditions from exercise info."""
        from api.v1.library import derive_avoids

        avoids = derive_avoids("Squat", "Quadriceps", "Barbell")
        assert "Stresses Knees" in avoids

        avoids = derive_avoids("Deadlift", "Back", "Barbell")
        assert "Stresses Lower Back" in avoids

        avoids = derive_avoids("Overhead Press", "Shoulders", "Barbell")
        assert "Stresses Shoulders" in avoids


# ============================================================
# EXERCISE ENDPOINTS TESTS
# ============================================================

class TestExerciseEndpoints:
    """Test exercise-related endpoints."""

    def test_get_body_parts(self, mock_supabase_db, sample_exercise_row):
        """Test getting body parts list."""
        from api.v1.library import get_body_parts
        import asyncio

        # Mock pagination
        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        # Second call returns empty (pagination complete)
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = [mock_result, mock_empty]

        result = asyncio.get_event_loop().run_until_complete(
            get_body_parts()
        )

        assert isinstance(result, list)
        assert all("name" in bp and "count" in bp for bp in result)

    def test_get_equipment_types(self, mock_supabase_db, sample_exercise_row):
        """Test getting equipment types."""
        from api.v1.library import get_equipment_types
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = [mock_result, mock_empty]

        result = asyncio.get_event_loop().run_until_complete(
            get_equipment_types()
        )

        assert isinstance(result, list)
        assert any(eq["name"] == "Barbell" for eq in result)

    def test_get_exercise_types(self, mock_supabase_db, sample_exercise_row):
        """Test getting exercise types."""
        from api.v1.library import get_exercise_types
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = [mock_result, mock_empty]

        result = asyncio.get_event_loop().run_until_complete(
            get_exercise_types()
        )

        assert isinstance(result, list)
        assert all("name" in et and "count" in et for et in result)

    def test_get_filter_options(self, mock_supabase_db, sample_exercise_row):
        """Test getting all filter options."""
        from api.v1.library import get_filter_options
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = [mock_result, mock_empty]

        result = asyncio.get_event_loop().run_until_complete(
            get_filter_options()
        )

        assert "body_parts" in result
        assert "equipment" in result
        assert "exercise_types" in result
        assert "goals" in result
        assert "suitable_for" in result
        assert "avoid_if" in result

    def test_list_exercises_no_filters(self, mock_supabase_db, sample_exercise_row):
        """Test listing exercises without filters."""
        from api.v1.library import list_exercises
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            list_exercises()
        )

        assert len(result) == 1
        assert result[0].name == "Bench Press"

    def test_list_exercises_with_body_part_filter(self, mock_supabase_db, sample_exercise_row):
        """Test listing exercises with body part filter."""
        from api.v1.library import list_exercises
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = [mock_result, mock_empty]

        result = asyncio.get_event_loop().run_until_complete(
            list_exercises(body_parts="Chest")
        )

        assert len(result) == 1

    def test_list_exercises_with_goals_filter(self, mock_supabase_db, sample_exercise_row):
        """Test listing exercises with goals filter."""
        from api.v1.library import list_exercises
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = [mock_result, mock_empty]

        result = asyncio.get_event_loop().run_until_complete(
            list_exercises(goals="Muscle Building")
        )

        assert len(result) == 1

    def test_list_exercises_with_avoid_filter(self, mock_supabase_db, sample_exercise_row):
        """Test listing exercises with avoid filter (exclusion)."""
        from api.v1.library import list_exercises
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = [mock_result, mock_empty]

        result = asyncio.get_event_loop().run_until_complete(
            list_exercises(avoid_if="Stresses Shoulders")
        )

        # Should be excluded because exercise has "Stresses Shoulders" in avoid_if
        assert len(result) == 0

    def test_get_exercises_grouped(self, mock_supabase_db, sample_exercise_row):
        """Test getting exercises grouped by body part."""
        from api.v1.library import get_exercises_grouped
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = [mock_result, mock_empty]

        result = asyncio.get_event_loop().run_until_complete(
            get_exercises_grouped()
        )

        assert isinstance(result, list)
        assert all(hasattr(g, 'body_part') and hasattr(g, 'exercises') for g in result)

    def test_get_exercise_found(self, mock_supabase_db, sample_exercise_row):
        """Test getting a single exercise by ID."""
        from api.v1.library import get_exercise
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_exercise_row]

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_exercise("ex-123")
        )

        assert result.id == "ex-123"
        assert result.name == "Bench Press"

    def test_get_exercise_not_found(self, mock_supabase_db):
        """Test getting a non-existent exercise."""
        from api.v1.library import get_exercise
        from fastapi import HTTPException
        import asyncio

        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_empty

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_exercise("nonexistent")
            )

        assert exc_info.value.status_code == 404


# ============================================================
# PROGRAM ENDPOINTS TESTS
# ============================================================

class TestProgramEndpoints:
    """Test program-related endpoints."""

    def test_get_program_categories(self, mock_supabase_db, sample_program_row):
        """Test getting program categories."""
        from api.v1.library import get_program_categories
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_program_row]

        mock_supabase_db.client.table.return_value.select.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_program_categories()
        )

        assert isinstance(result, list)
        assert any(cat["name"] == "Goal-Based" for cat in result)

    def test_list_programs_no_filters(self, mock_supabase_db, sample_program_row):
        """Test listing programs without filters."""
        from api.v1.library import list_programs
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_program_row]

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            list_programs()
        )

        assert len(result) == 1
        assert result[0].name == "12-Week Muscle Builder"

    def test_list_programs_with_category_filter(self, mock_supabase_db, sample_program_row):
        """Test listing programs with category filter."""
        from api.v1.library import list_programs
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_program_row]

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            list_programs(category="Goal-Based")
        )

        assert len(result) == 1

    def test_list_programs_with_search(self, mock_supabase_db, sample_program_row):
        """Test listing programs with search filter."""
        from api.v1.library import list_programs
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_program_row]

        mock_supabase_db.client.table.return_value.select.return_value.ilike.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            list_programs(search="muscle")
        )

        assert len(result) == 1

    def test_get_programs_grouped(self, mock_supabase_db, sample_program_row):
        """Test getting programs grouped by category."""
        from api.v1.library import get_programs_grouped
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_program_row]

        mock_supabase_db.client.table.return_value.select.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_programs_grouped()
        )

        assert isinstance(result, list)
        assert all(hasattr(g, 'category') and hasattr(g, 'programs') for g in result)

    def test_get_program_found(self, mock_supabase_db, sample_program_row):
        """Test getting a single program by ID."""
        from api.v1.library import get_program
        import asyncio

        program_with_workouts = {**sample_program_row, "workouts": [{"day": 1, "exercises": []}]}
        mock_result = MagicMock()
        mock_result.data = [program_with_workouts]

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_program("prog-123")
        )

        assert result["id"] == "prog-123"
        assert result["name"] == "12-Week Muscle Builder"
        assert "workouts" in result

    def test_get_program_not_found(self, mock_supabase_db):
        """Test getting a non-existent program."""
        from api.v1.library import get_program
        from fastapi import HTTPException
        import asyncio

        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_empty

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_program("nonexistent")
            )

        assert exc_info.value.status_code == 404


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestLibraryModels:
    """Test Pydantic model validation."""

    def test_library_exercise_model(self):
        """Test LibraryExercise model."""
        from api.v1.library import LibraryExercise

        exercise = LibraryExercise(
            id="ex-123",
            name="Bench Press",
            original_name="Bench Press_Male",
            body_part="Chest",
            equipment="Barbell"
        )

        assert exercise.id == "ex-123"
        assert exercise.name == "Bench Press"
        assert exercise.target_muscle is None  # Optional

    def test_library_program_model(self):
        """Test LibraryProgram model."""
        from api.v1.library import LibraryProgram

        program = LibraryProgram(
            id="prog-123",
            name="Muscle Builder",
            category="Goal-Based"
        )

        assert program.id == "prog-123"
        assert program.duration_weeks is None  # Optional

    def test_exercises_by_body_part_model(self):
        """Test ExercisesByBodyPart model."""
        from api.v1.library import ExercisesByBodyPart, LibraryExercise

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
        assert len(grouped.exercises) == 1

    def test_programs_by_category_model(self):
        """Test ProgramsByCategory model."""
        from api.v1.library import ProgramsByCategory, LibraryProgram

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
        assert len(grouped.programs) == 1


# ============================================================
# ROW CONVERSION TESTS
# ============================================================

class TestRowConversion:
    """Test row to model conversion functions."""

    def test_row_to_library_exercise_from_cleaned_view(self, sample_exercise_row):
        """Test converting row from cleaned view."""
        from api.v1.library import row_to_library_exercise

        result = row_to_library_exercise(sample_exercise_row, from_cleaned_view=True)

        assert result.id == "ex-123"
        assert result.name == "Bench Press"
        assert result.original_name == "Bench Press_Male"
        assert result.body_part == "Chest"
        assert result.goals == ["Muscle Building", "Testosterone Boost"]

    def test_row_to_library_exercise_from_base_table(self):
        """Test converting row from base table."""
        from api.v1.library import row_to_library_exercise

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

    def test_row_to_library_program(self, sample_program_row):
        """Test converting program row."""
        from api.v1.library import row_to_library_program

        result = row_to_library_program(sample_program_row)

        assert result.id == "prog-123"
        assert result.name == "12-Week Muscle Builder"
        assert result.category == "Goal-Based"
        assert result.duration_weeks == 12


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestErrorHandling:
    """Test error handling across endpoints."""

    def test_list_exercises_database_error(self, mock_supabase_db):
        """Test handling database errors in list exercises."""
        from api.v1.library import list_exercises
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = Exception("Database error")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                list_exercises()
            )

        assert exc_info.value.status_code == 500

    def test_list_programs_database_error(self, mock_supabase_db):
        """Test handling database errors in list programs."""
        from api.v1.library import list_programs
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.client.table.return_value.select.return_value.order.return_value.range.return_value.execute.side_effect = Exception("Connection failed")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                list_programs()
            )

        assert exc_info.value.status_code == 500


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
