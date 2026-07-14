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
import asyncio

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from types import SimpleNamespace
from datetime import datetime


# ============================================================
# FIXTURES
# ============================================================

class FakeQueryBuilder:
    """Chainable stand-in for the supabase-py / postgrest query builder.

    The real builder returns `self` from every filter method and only performs
    work on `.execute()`. Modelling that faithfully (instead of hand-wiring
    `table.return_value.select.return_value.order.return_value...` MagicMock
    chains) means a test declares WHAT the DB returns, not the exact order in
    which the endpoint happened to chain its filters — so a harmless refactor
    of the query (e.g. adding an `.eq("is_active", True)`) no longer silently
    turns the mocked result into an un-iterable MagicMock.

    Set `.rows` for the payload every `.execute()` returns, `.rows_by_table`
    to vary it per table, or `.error` to make `.execute()` raise.
    """

    def __init__(self):
        self.rows: list = []
        self.rows_by_table: dict = {}
        self.error: Exception | None = None
        self.last_table: str | None = None
        self.calls: list = []

    def table(self, name):
        self.last_table = name
        self.calls.append(("table", name))
        return self

    def select(self, *args, **kwargs):
        self.calls.append(("select", args))
        return self

    def eq(self, *args):
        self.calls.append(("eq", args))
        return self

    def ilike(self, *args):
        self.calls.append(("ilike", args))
        return self

    def or_(self, *args):
        self.calls.append(("or_", args))
        return self

    def order(self, *args, **kwargs):
        self.calls.append(("order", args))
        return self

    def range(self, *args):
        self.calls.append(("range", args))
        return self

    def limit(self, *args):
        self.calls.append(("limit", args))
        return self

    def execute(self):
        if self.error is not None:
            raise self.error
        rows = self.rows_by_table.get(self.last_table, self.rows)
        return SimpleNamespace(data=list(rows))


@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for library operations.

    `api/v1/library.py` became the `api.v1.library` PACKAGE, so
    `get_supabase_db` is no longer an attribute of the package namespace — the
    `exercises` and `programs` submodules each import it directly. Patching the
    old `api.v1.library.get_supabase_db` target raised `AttributeError: module
    'api.v1.library' does not have the attribute 'get_supabase_db'`, which is
    what errored out every endpoint test in this file. Patch the real call
    sites instead.
    """
    with patch("api.v1.library.exercises.get_supabase_db") as mock_ex_db, \
         patch("api.v1.library.programs.get_supabase_db") as mock_prog_db:
        mock_db = MagicMock()
        mock_db.client = FakeQueryBuilder()
        mock_ex_db.return_value = mock_db
        mock_prog_db.return_value = mock_db
        yield mock_db


@pytest.fixture(autouse=True)
def clear_library_ref_cache():
    """The filter-options payload is memoized in a process-global 1h cache.

    Without clearing it, `test_get_filter_options` would be served whatever a
    previous test (or a previous run in the same process) had cached instead of
    recomputing from the mocked rows.
    """
    from api.v1.library.exercises import _LIBRARY_REF_CACHE

    _LIBRARY_REF_CACHE._local.clear()
    yield
    _LIBRARY_REF_CACHE._local.clear()


@pytest.fixture
def sample_exercise_row():
    """A row as `exercise_library_cleaned` actually returns it today.

    Two columns changed type since this fixture was written and the old shape
    no longer validates against `LibraryExercise`:
      - `secondary_muscles` is a JSONB array (was a comma-joined string)
      - `difficulty_level` is text ('Beginner'/'Intermediate'/…, was an int)
    `display_body_part` is the view's SQL-computed body-part bucket (it fixes
    ordering bugs in the Python `normalize_body_part` fallback).
    """
    return {
        "id": "ex-123",
        "name": "Bench Press",
        "original_name": "Bench Press_Male",
        "body_part": "Chest",
        "display_body_part": "Chest",
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
def sample_program_row():
    """A row as `branded_programs` actually returns it today.

    The library program endpoints were repointed from the old `programs` table
    to `branded_programs`, which renamed the columns this fixture used to send:
      program_name -> name, program_category -> category,
      program_subcategory -> split_type, short_description -> tagline.
    There is no `tags`/`session_duration_minutes`/`celebrity_name` column —
    `tags` is derived from `goals` and session duration is estimated from
    `sessions_per_week` (see `row_to_library_program`).
    """
    return {
        "id": "prog-123",
        "name": "12-Week Muscle Builder",
        "category": "Goal-Based",
        "split_type": "Hypertrophy",
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "goals": ["Muscle Building"],
        "description": "A comprehensive 12-week program for building muscle mass.",
        "tagline": "Build muscle in 12 weeks",
        "is_active": True,
        "is_featured": False,
        "is_premium": False,
        "requires_gym": True,
        "icon_name": "dumbbell",
        "color_hex": "#FF5722",
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

def _list_exercises(**overrides):
    """Call the `list_exercises` endpoint coroutine directly.

    Every filter/pagination parameter is declared with a `Query(...)` default.
    FastAPI resolves those at request time, but a DIRECT call leaves the
    parameter bound to the `Query` sentinel object — which is truthy, so
    `body_parts.split(",") if body_parts else []` would explode on it. Passing
    each one explicitly is what a real request does.
    """
    from fastapi import Response
    from api.v1.library.exercises import list_exercises

    kwargs = dict(
        body_parts=None, equipment=None, exercise_types=None, categories=None,
        difficulty=None, search=None, goals=None, suitable_for=None,
        avoid_if=None, limit=2000, offset=0,
    )
    kwargs.update(overrides)
    return asyncio.get_event_loop().run_until_complete(
        list_exercises(Response(), **kwargs)
    )


class TestExerciseEndpoints:
    """Test exercise-related endpoints."""

    def test_get_body_parts(self, mock_supabase_db, sample_exercise_row):
        """Test getting body parts list."""
        from api.v1.library.exercises import get_body_parts
        import asyncio

        mock_supabase_db.client.rows = [sample_exercise_row]

        result = asyncio.get_event_loop().run_until_complete(
            get_body_parts()
        )

        assert isinstance(result, list)
        assert all("name" in bp and "count" in bp for bp in result)
        assert result == [{"name": "Chest", "count": 1}]

    def test_get_equipment_types(self, mock_supabase_db, sample_exercise_row):
        """Test getting equipment types."""
        from api.v1.library.exercises import get_equipment_types
        import asyncio

        mock_supabase_db.client.rows = [sample_exercise_row]

        result = asyncio.get_event_loop().run_until_complete(
            get_equipment_types()
        )

        assert isinstance(result, list)
        assert any(eq["name"] == "Barbell" for eq in result)

    def test_get_exercise_types(self, mock_supabase_db, sample_exercise_row):
        """Test getting exercise types."""
        from api.v1.library.exercises import get_exercise_types
        import asyncio

        mock_supabase_db.client.rows = [sample_exercise_row]

        result = asyncio.get_event_loop().run_until_complete(
            get_exercise_types()
        )

        assert isinstance(result, list)
        assert all("name" in et and "count" in et for et in result)
        assert result == [{"name": "Strength", "count": 1}]

    def test_get_filter_options(self, mock_supabase_db, sample_exercise_row):
        """Test getting all filter options."""
        from fastapi import Response
        from api.v1.library.exercises import get_filter_options
        import asyncio

        mock_supabase_db.client.rows = [sample_exercise_row]

        result = asyncio.get_event_loop().run_until_complete(
            get_filter_options(Response())
        )

        assert "body_parts" in result
        assert "equipment" in result
        assert "exercise_types" in result
        assert "goals" in result
        assert "suitable_for" in result
        assert "avoid_if" in result
        # Counts are derived from the DB columns, not re-derived at runtime.
        assert result["goals"] == [
            {"name": "Muscle Building", "count": 1},
            {"name": "Testosterone Boost", "count": 1},
        ]
        assert result["avoid_if"] == [{"name": "Stresses Shoulders", "count": 1}]
        assert result["total_exercises"] == 1

    def test_list_exercises_no_filters(self, mock_supabase_db, sample_exercise_row):
        """Test listing exercises without filters."""
        mock_supabase_db.client.rows = [sample_exercise_row]

        result = _list_exercises()

        assert len(result) == 1
        assert result[0].name == "Bench Press"

    def test_list_exercises_with_body_part_filter(self, mock_supabase_db, sample_exercise_row):
        """Test listing exercises with body part filter."""
        mock_supabase_db.client.rows = [sample_exercise_row]

        result = _list_exercises(body_parts="Chest")

        assert len(result) == 1

    def test_list_exercises_body_part_filter_excludes_other_parts(self, mock_supabase_db, sample_exercise_row):
        """The body-part filter must actually EXCLUDE non-matching rows."""
        mock_supabase_db.client.rows = [sample_exercise_row]

        result = _list_exercises(body_parts="Quadriceps")

        assert len(result) == 0

    def test_list_exercises_with_goals_filter(self, mock_supabase_db, sample_exercise_row):
        """Test listing exercises with goals filter."""
        mock_supabase_db.client.rows = [sample_exercise_row]

        result = _list_exercises(goals="Muscle Building")

        assert len(result) == 1

    def test_list_exercises_with_avoid_filter(self, mock_supabase_db, sample_exercise_row):
        """Test listing exercises with avoid filter (exclusion)."""
        mock_supabase_db.client.rows = [sample_exercise_row]

        result = _list_exercises(avoid_if="Stresses Shoulders")

        # Should be excluded because exercise has "Stresses Shoulders" in avoid_if
        assert len(result) == 0

    def test_get_exercises_grouped(self, mock_supabase_db, sample_exercise_row):
        """Test getting exercises grouped by body part."""
        from api.v1.library.exercises import get_exercises_grouped
        import asyncio

        mock_supabase_db.client.rows = [sample_exercise_row]

        result = asyncio.get_event_loop().run_until_complete(
            get_exercises_grouped(limit_per_group=10)
        )

        assert isinstance(result, list)
        assert all(hasattr(g, 'body_part') and hasattr(g, 'exercises') for g in result)
        assert len(result) == 1
        assert result[0].body_part == "Chest"
        assert result[0].count == 1
        assert result[0].exercises[0].name == "Bench Press"

    def test_get_exercise_found(self, mock_supabase_db, sample_exercise_row):
        """Test getting a single exercise by ID."""
        from api.v1.library.exercises import get_exercise
        import asyncio

        mock_supabase_db.client.rows = [sample_exercise_row]

        result = asyncio.get_event_loop().run_until_complete(
            get_exercise("ex-123", accept_language=None)
        )

        assert result.id == "ex-123"
        assert result.name == "Bench Press"

    def test_get_exercise_not_found(self, mock_supabase_db):
        """Test getting a non-existent exercise.

        404 requires BOTH lookups to miss: the endpoint tries the cleaned view
        first, then falls back to the `exercise_library` base table.
        """
        from api.v1.library.exercises import get_exercise
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.client.rows = []

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_exercise("nonexistent", accept_language=None)
            )

        assert exc_info.value.status_code == 404


# ============================================================
# PROGRAM ENDPOINTS TESTS
# ============================================================

class TestProgramEndpoints:
    """Test program-related endpoints."""

    def test_get_program_categories(self, mock_supabase_db, sample_program_row):
        """Test getting program categories."""
        from api.v1.library.programs import get_program_categories
        import asyncio

        mock_supabase_db.client.rows = [sample_program_row]

        result = asyncio.get_event_loop().run_until_complete(
            get_program_categories()
        )

        assert isinstance(result, list)
        assert any(cat["name"] == "Goal-Based" for cat in result)

    def test_list_programs_no_filters(self, mock_supabase_db, sample_program_row):
        """Test listing programs without filters."""
        from api.v1.library.programs import list_programs
        import asyncio

        mock_supabase_db.client.rows = [sample_program_row]

        result = asyncio.get_event_loop().run_until_complete(
            list_programs(limit=50, offset=0)
        )

        assert len(result) == 1
        assert result[0].name == "12-Week Muscle Builder"

    def test_list_programs_only_returns_active(self, mock_supabase_db, sample_program_row):
        """Retired/unpublished programs must never reach the library.

        Every `branded_programs` read is gated on `is_active = True`; this pins
        that filter so a refactor can't silently drop it and start listing
        deactivated programs.
        """
        from api.v1.library.programs import list_programs
        import asyncio

        mock_supabase_db.client.rows = [sample_program_row]

        asyncio.get_event_loop().run_until_complete(
            list_programs(limit=50, offset=0)
        )

        assert ("eq", ("is_active", True)) in mock_supabase_db.client.calls

    def test_list_programs_with_category_filter(self, mock_supabase_db, sample_program_row):
        """Test listing programs with category filter."""
        from api.v1.library.programs import list_programs
        import asyncio

        mock_supabase_db.client.rows = [sample_program_row]

        result = asyncio.get_event_loop().run_until_complete(
            list_programs(category="Goal-Based", limit=50, offset=0)
        )

        assert len(result) == 1
        assert ("eq", ("category", "Goal-Based")) in mock_supabase_db.client.calls

    def test_list_programs_with_search(self, mock_supabase_db, sample_program_row):
        """Test listing programs with search filter."""
        from api.v1.library.programs import list_programs
        import asyncio

        mock_supabase_db.client.rows = [sample_program_row]

        result = asyncio.get_event_loop().run_until_complete(
            list_programs(search="muscle", limit=50, offset=0)
        )

        assert len(result) == 1
        assert ("ilike", ("name", "%muscle%")) in mock_supabase_db.client.calls

    def test_get_programs_grouped(self, mock_supabase_db, sample_program_row):
        """Test getting programs grouped by category."""
        from api.v1.library.programs import get_programs_grouped
        import asyncio

        mock_supabase_db.client.rows = [sample_program_row]

        result = asyncio.get_event_loop().run_until_complete(
            get_programs_grouped(limit_per_group=10)
        )

        assert isinstance(result, list)
        assert all(hasattr(g, 'category') and hasattr(g, 'programs') for g in result)
        assert len(result) == 1
        assert result[0].category == "Goal-Based"
        assert result[0].count == 1

    def test_get_program_found(self, mock_supabase_db, sample_program_row):
        """Test getting a single program by ID.

        This used to assert `"workouts" in result`. The endpoint now reads
        `branded_programs`, which has NO `workouts` column — a curated program's
        sessions live in `program_variant_weeks` (per-variant, per-week) and are
        served by the program-schedule endpoints, not by this metadata lookup.
        The guarantee this test protects is the branded_programs -> API field
        mapping (split_type -> subcategory, tagline -> short_description,
        goals -> tags), which is what the library detail screen renders.
        """
        from api.v1.library.programs import get_program
        import asyncio

        mock_supabase_db.client.rows = [sample_program_row]

        result = asyncio.get_event_loop().run_until_complete(
            get_program("prog-123")
        )

        assert result["id"] == "prog-123"
        assert result["name"] == "12-Week Muscle Builder"
        assert result["category"] == "Goal-Based"
        assert result["subcategory"] == "Hypertrophy"       # <- split_type
        assert result["short_description"] == "Build muscle in 12 weeks"  # <- tagline
        assert result["tags"] == ["Muscle Building"]        # <- goals
        assert result["duration_weeks"] == 12
        assert result["sessions_per_week"] == 4

    def test_get_program_not_found(self, mock_supabase_db):
        """Test getting a non-existent program."""
        from api.v1.library.programs import get_program
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.client.rows = []

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
        assert result.secondary_muscles == ["Triceps", "Anterior Deltoid"]
        assert result.difficulty_level == "Intermediate"
        assert result.avoid_if == ["Stresses Shoulders"]

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
        """Test converting a `branded_programs` row.

        The source table changed (`programs` -> `branded_programs`), which
        renamed the columns: program_name -> name, program_category -> category,
        program_subcategory -> split_type, short_description -> tagline. Same
        contract, new column names — the LibraryProgram shape is unchanged.
        """
        from api.v1.library import row_to_library_program

        result = row_to_library_program(sample_program_row)

        assert result.id == "prog-123"
        assert result.name == "12-Week Muscle Builder"
        assert result.category == "Goal-Based"
        assert result.duration_weeks == 12
        assert result.subcategory == "Hypertrophy"
        assert result.short_description == "Build muscle in 12 weeks"
        assert result.tags == ["Muscle Building"]
        assert result.goals == ["Muscle Building"]


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestErrorHandling:
    """Test error handling across endpoints."""

    def test_list_exercises_database_error(self, mock_supabase_db):
        """Test handling database errors in list exercises."""
        from fastapi import HTTPException

        mock_supabase_db.client.error = Exception("Database error")

        with pytest.raises(HTTPException) as exc_info:
            _list_exercises()

        assert exc_info.value.status_code == 500
        # The driver message must not leak to the client (safe_internal_error).
        assert "Database error" not in str(exc_info.value.detail)

    def test_list_programs_database_error(self, mock_supabase_db):
        """Test handling database errors in list programs."""
        from api.v1.library.programs import list_programs
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.client.error = Exception("Connection failed")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                list_programs(limit=50, offset=0)
            )

        assert exc_info.value.status_code == 500
        assert "Connection failed" not in str(exc_info.value.detail)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
