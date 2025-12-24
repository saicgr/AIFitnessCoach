"""
Tests for Warmup and Stretch Service.

Tests:
- Target muscle extraction
- Warmup generation from library
- Stretch generation from library
- Creating warmups/stretches for workouts
- Version history (SCD2)
- Soft deletion

Run with: pytest backend/tests/test_warmup_stretch_service.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime, timedelta

from services.warmup_stretch_service import (
    WarmupStretchService, get_warmup_stretch_service,
    MUSCLE_KEYWORDS, WARMUP_BY_MUSCLE, STRETCH_BY_MUSCLE
)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase():
    """Create mock Supabase client."""
    mock = MagicMock()
    mock.client = MagicMock()
    return mock


@pytest.fixture
def warmup_service(mock_supabase):
    """Create warmup stretch service with mocked dependencies."""
    with patch("services.warmup_stretch_service.get_supabase") as mock_get:
        mock_get.return_value = mock_supabase
        with patch("services.warmup_stretch_service.get_settings") as mock_settings:
            mock_settings.return_value.gemini_api_key = "test-key"
            mock_settings.return_value.gemini_model = "gemini-2.0-flash"
            service = WarmupStretchService()
            service.supabase = mock_supabase.client
            yield service


@pytest.fixture
def sample_workout_exercises():
    """Sample workout exercises."""
    return [
        {"name": "Bench Press", "muscle_group": "chest", "sets": 4, "reps": 8},
        {"name": "Dumbbell Fly", "primary_muscle": "chest", "sets": 3, "reps": 12},
        {"name": "Tricep Pushdown", "target": "triceps", "sets": 3, "reps": 15},
    ]


@pytest.fixture
def sample_warmup_exercises():
    """Sample warmup exercises from library."""
    return [
        {
            "id": 1,
            "name": "Arm Circles",
            "body_part": "shoulders",
            "target_muscle": "deltoids",
            "equipment": "none",
            "instructions": "Rotate arms in circles",
            "video_url": "https://example.com/arm-circles.mp4",
        },
        {
            "id": 2,
            "name": "Jumping Jacks",
            "body_part": "full body",
            "target_muscle": "cardio",
            "equipment": "none",
            "instructions": "Jump while spreading arms and legs",
            "video_url": "https://example.com/jumping-jacks.mp4",
        },
    ]


@pytest.fixture
def sample_stretch_exercises():
    """Sample stretch exercises from library."""
    return [
        {
            "id": 1,
            "name": "Chest Stretch",
            "body_part": "chest",
            "target_muscle": "pectoralis",
            "equipment": "none",
            "instructions": "Hold arm against wall and rotate",
            "video_url": "https://example.com/chest-stretch.mp4",
        },
        {
            "id": 2,
            "name": "Tricep Stretch",
            "body_part": "arms",
            "target_muscle": "triceps",
            "equipment": "none",
            "instructions": "Reach behind head",
            "video_url": "https://example.com/tricep-stretch.mp4",
        },
    ]


# ============================================================
# TARGET MUSCLE EXTRACTION TESTS
# ============================================================

class TestGetTargetMuscles:
    """Test target muscle extraction from exercises."""

    def test_get_target_muscles_from_muscle_group(self, warmup_service):
        """Test extracting muscles from muscle_group field."""
        exercises = [
            {"name": "Exercise 1", "muscle_group": "chest"},
            {"name": "Exercise 2", "muscle_group": "back"},
        ]

        muscles = warmup_service.get_target_muscles(exercises)

        assert "chest" in muscles
        assert "back" in muscles

    def test_get_target_muscles_from_primary_muscle(self, warmup_service):
        """Test extracting muscles from primary_muscle field."""
        exercises = [
            {"name": "Exercise 1", "primary_muscle": "quadriceps"},
        ]

        muscles = warmup_service.get_target_muscles(exercises)

        assert "quadriceps" in muscles

    def test_get_target_muscles_from_target(self, warmup_service):
        """Test extracting muscles from target field."""
        exercises = [
            {"name": "Exercise 1", "target": "biceps"},
        ]

        muscles = warmup_service.get_target_muscles(exercises)

        assert "biceps" in muscles

    def test_get_target_muscles_from_body_part(self, warmup_service):
        """Test extracting muscles from bodyPart field."""
        exercises = [
            {"name": "Exercise 1", "bodyPart": "shoulders"},
        ]

        muscles = warmup_service.get_target_muscles(exercises)

        assert "shoulders" in muscles

    def test_get_target_muscles_returns_full_body_for_empty(self, warmup_service):
        """Test returns full body when no muscles found."""
        exercises = [
            {"name": "Exercise 1"},  # No muscle info
        ]

        muscles = warmup_service.get_target_muscles(exercises)

        assert muscles == ["full body"]

    def test_get_target_muscles_unique_only(self, warmup_service):
        """Test returns unique muscles only."""
        exercises = [
            {"name": "Exercise 1", "muscle_group": "chest"},
            {"name": "Exercise 2", "muscle_group": "chest"},
        ]

        muscles = warmup_service.get_target_muscles(exercises)

        assert muscles.count("chest") == 1


# ============================================================
# GET WARMUP EXERCISES FROM LIBRARY TESTS
# ============================================================

class TestGetWarmupExercisesFromLibrary:
    """Test getting warmup exercises from library."""

    @pytest.mark.asyncio
    async def test_get_warmup_exercises_success(self, warmup_service, sample_warmup_exercises):
        """Test successfully getting warmup exercises."""
        warmup_service.supabase.table.return_value.select.return_value.execute.return_value = MagicMock(
            data=sample_warmup_exercises
        )

        exercises = await warmup_service.get_warmup_exercises_from_library(
            target_muscles=["chest"],
            limit=4
        )

        assert len(exercises) <= 4
        for ex in exercises:
            assert "name" in ex
            assert "sets" in ex
            assert "duration_seconds" in ex

    @pytest.mark.asyncio
    async def test_get_warmup_exercises_avoids_recent(self, warmup_service, sample_warmup_exercises):
        """Test avoiding recently used exercises."""
        warmup_service.supabase.table.return_value.select.return_value.execute.return_value = MagicMock(
            data=sample_warmup_exercises
        )

        exercises = await warmup_service.get_warmup_exercises_from_library(
            target_muscles=["chest"],
            avoid_exercises=["arm circles"],  # lowercase to test matching
            limit=4
        )

        names_lower = [ex["name"].lower() for ex in exercises]
        assert "arm circles" not in names_lower

    @pytest.mark.asyncio
    async def test_get_warmup_exercises_empty_library(self, warmup_service):
        """Test handling empty library."""
        warmup_service.supabase.table.return_value.select.return_value.execute.return_value = MagicMock(
            data=[]
        )

        exercises = await warmup_service.get_warmup_exercises_from_library(
            target_muscles=["chest"],
            limit=4
        )

        assert exercises == []

    @pytest.mark.asyncio
    async def test_get_warmup_exercises_formats_correctly(self, warmup_service, sample_warmup_exercises):
        """Test exercises are formatted correctly."""
        warmup_service.supabase.table.return_value.select.return_value.execute.return_value = MagicMock(
            data=sample_warmup_exercises
        )

        exercises = await warmup_service.get_warmup_exercises_from_library(
            target_muscles=["chest"],
            limit=4
        )

        for ex in exercises:
            assert ex["sets"] == 1
            assert ex["reps"] == 15
            assert ex["duration_seconds"] == 30
            assert ex["rest_seconds"] == 10


# ============================================================
# GET STRETCH EXERCISES FROM LIBRARY TESTS
# ============================================================

class TestGetStretchExercisesFromLibrary:
    """Test getting stretch exercises from library."""

    @pytest.mark.asyncio
    async def test_get_stretch_exercises_success(self, warmup_service, sample_stretch_exercises):
        """Test successfully getting stretch exercises."""
        warmup_service.supabase.table.return_value.select.return_value.execute.return_value = MagicMock(
            data=sample_stretch_exercises
        )

        exercises = await warmup_service.get_stretch_exercises_from_library(
            target_muscles=["chest"],
            limit=5
        )

        assert len(exercises) <= 5

    @pytest.mark.asyncio
    async def test_get_stretch_exercises_formats_correctly(self, warmup_service, sample_stretch_exercises):
        """Test stretches are formatted correctly."""
        warmup_service.supabase.table.return_value.select.return_value.execute.return_value = MagicMock(
            data=sample_stretch_exercises
        )

        exercises = await warmup_service.get_stretch_exercises_from_library(
            target_muscles=["chest"],
            limit=5
        )

        for ex in exercises:
            assert ex["sets"] == 1
            assert ex["reps"] == 1  # Stretches are held, not repped
            assert ex["duration_seconds"] == 30
            assert ex["rest_seconds"] == 0


# ============================================================
# GET RECENTLY USED WARMUPS TESTS
# ============================================================

class TestGetRecentlyUsedWarmups:
    """Test getting recently used warmups."""

    @pytest.mark.asyncio
    async def test_get_recently_used_warmups_success(self, warmup_service):
        """Test getting recently used warmup names."""
        # Mock workouts response
        warmup_service.supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = MagicMock(
            data=[{"id": 1}, {"id": 2}]
        )

        # Mock warmups response
        warmup_service.supabase.table.return_value.select.return_value.in_.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[
                {"exercises_json": [{"name": "Arm Circles"}, {"name": "Leg Swings"}]},
            ]
        )

        names = await warmup_service.get_recently_used_warmups("user-123", days=7)

        assert "arm circles" in names
        assert "leg swings" in names

    @pytest.mark.asyncio
    async def test_get_recently_used_warmups_no_workouts(self, warmup_service):
        """Test when no recent workouts exist."""
        warmup_service.supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = MagicMock(
            data=[]
        )

        names = await warmup_service.get_recently_used_warmups("user-123", days=7)

        assert names == []


# ============================================================
# GET RECENTLY USED STRETCHES TESTS
# ============================================================

class TestGetRecentlyUsedStretches:
    """Test getting recently used stretches."""

    @pytest.mark.asyncio
    async def test_get_recently_used_stretches_success(self, warmup_service):
        """Test getting recently used stretch names."""
        # Mock workouts response
        warmup_service.supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = MagicMock(
            data=[{"id": 1}]
        )

        # Mock stretches response
        warmup_service.supabase.table.return_value.select.return_value.in_.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[
                {"exercises_json": [{"name": "Chest Stretch"}]},
            ]
        )

        names = await warmup_service.get_recently_used_stretches("user-123", days=7)

        assert "chest stretch" in names


# ============================================================
# CREATE WARMUP FOR WORKOUT TESTS
# ============================================================

class TestCreateWarmupForWorkout:
    """Test creating warmups for workouts."""

    @pytest.mark.asyncio
    async def test_create_warmup_success(self, warmup_service, sample_workout_exercises, sample_warmup_exercises):
        """Test creating warmup for workout."""
        # Mock get recently used
        warmup_service.get_recently_used_warmups = AsyncMock(return_value=[])

        # Mock generate warmup
        warmup_service.generate_warmup = AsyncMock(return_value=[
            {"name": "Arm Circles", "sets": 1, "reps": 15}
        ])

        # Mock insert
        warmup_service.supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(
            data=[{"id": 1, "workout_id": "w1"}]
        )

        result = await warmup_service.create_warmup_for_workout(
            workout_id="w1",
            exercises=sample_workout_exercises,
            duration_minutes=5,
            user_id="user-123"
        )

        assert result is not None
        assert result["workout_id"] == "w1"

    @pytest.mark.asyncio
    async def test_create_warmup_with_injuries(self, warmup_service, sample_workout_exercises):
        """Test creating warmup with injuries."""
        warmup_service.get_recently_used_warmups = AsyncMock(return_value=[])
        warmup_service.generate_warmup = AsyncMock(return_value=[])
        warmup_service.supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(
            data=[{"id": 1}]
        )

        await warmup_service.create_warmup_for_workout(
            workout_id="w1",
            exercises=sample_workout_exercises,
            duration_minutes=5,
            injuries=["back", "shoulder"],
            user_id="user-123"
        )

        # Verify generate_warmup was called with injuries
        warmup_service.generate_warmup.assert_called_once()
        call_args = warmup_service.generate_warmup.call_args
        assert call_args[1].get("injuries") == ["back", "shoulder"] or call_args[0][2] == ["back", "shoulder"]


# ============================================================
# CREATE STRETCHES FOR WORKOUT TESTS
# ============================================================

class TestCreateStretchesForWorkout:
    """Test creating stretches for workouts."""

    @pytest.mark.asyncio
    async def test_create_stretches_success(self, warmup_service, sample_workout_exercises):
        """Test creating stretches for workout."""
        warmup_service.get_recently_used_stretches = AsyncMock(return_value=[])
        warmup_service.generate_stretches = AsyncMock(return_value=[
            {"name": "Chest Stretch", "sets": 1, "duration_seconds": 30}
        ])
        warmup_service.supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(
            data=[{"id": 1, "workout_id": "w1"}]
        )

        result = await warmup_service.create_stretches_for_workout(
            workout_id="w1",
            exercises=sample_workout_exercises,
            duration_minutes=5,
            user_id="user-123"
        )

        assert result is not None


# ============================================================
# GET WARMUP/STRETCHES FOR WORKOUT TESTS
# ============================================================

class TestGetWarmupStretchesForWorkout:
    """Test getting warmup and stretches for workout."""

    def test_get_warmup_for_workout(self, warmup_service):
        """Test getting warmup for workout."""
        warmup_service.supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[{"id": 1, "exercises_json": []}]
        )

        result = warmup_service.get_warmup_for_workout("w1")

        assert result is not None

    def test_get_warmup_for_workout_not_found(self, warmup_service):
        """Test getting non-existent warmup."""
        warmup_service.supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[]
        )

        result = warmup_service.get_warmup_for_workout("w1")

        assert result is None

    def test_get_stretches_for_workout(self, warmup_service):
        """Test getting stretches for workout."""
        warmup_service.supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[{"id": 1, "exercises_json": []}]
        )

        result = warmup_service.get_stretches_for_workout("w1")

        assert result is not None


# ============================================================
# VERSION HISTORY TESTS
# ============================================================

class TestVersionHistory:
    """Test SCD2 version history."""

    def test_get_warmup_version_history(self, warmup_service):
        """Test getting warmup version history."""
        warmup_service.supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(
            data=[
                {"id": 2, "version_number": 2, "is_current": True},
                {"id": 1, "version_number": 1, "is_current": False},
            ]
        )

        history = warmup_service.get_warmup_version_history("w1")

        assert len(history) == 2
        assert history[0]["version_number"] == 2

    def test_get_stretch_version_history(self, warmup_service):
        """Test getting stretch version history."""
        warmup_service.supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(
            data=[
                {"id": 2, "version_number": 2, "is_current": True},
            ]
        )

        history = warmup_service.get_stretch_version_history("w1")

        assert len(history) == 1


# ============================================================
# SOFT DELETE TESTS
# ============================================================

class TestSoftDelete:
    """Test soft deletion."""

    def test_soft_delete_warmup(self, warmup_service):
        """Test soft deleting warmup."""
        warmup_service.supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()

        result = warmup_service.soft_delete_warmup("warmup-1")

        assert result is True
        warmup_service.supabase.table.return_value.update.assert_called_once()

    def test_soft_delete_stretches(self, warmup_service):
        """Test soft deleting stretches."""
        warmup_service.supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()

        result = warmup_service.soft_delete_stretches("stretch-1")

        assert result is True

    def test_soft_delete_warmup_error(self, warmup_service):
        """Test soft delete error handling."""
        warmup_service.supabase.table.return_value.update.side_effect = Exception("Error")

        result = warmup_service.soft_delete_warmup("warmup-1")

        assert result is False


# ============================================================
# REGENERATE TESTS
# ============================================================

class TestRegenerate:
    """Test regenerating warmups/stretches with versioning."""

    @pytest.mark.asyncio
    async def test_regenerate_warmup_creates_new_version(self, warmup_service, sample_workout_exercises):
        """Test regenerating warmup creates new version."""
        # Mock current warmup
        warmup_service.supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data={"id": "old-id", "version_number": 1, "parent_warmup_id": None}
        )

        # Mock generate warmup
        warmup_service.generate_warmup = AsyncMock(return_value=[
            {"name": "New Exercise", "sets": 1}
        ])

        # Mock insert new version
        warmup_service.supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(
            data=[{"id": "new-id", "version_number": 2}]
        )

        # Mock update old version
        warmup_service.supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()

        result = await warmup_service.regenerate_warmup(
            warmup_id="old-id",
            workout_id="w1",
            exercises=sample_workout_exercises,
            duration_minutes=5
        )

        assert result is not None
        assert result["version_number"] == 2


# ============================================================
# COMBINED GENERATION TESTS
# ============================================================

class TestCombinedGeneration:
    """Test generating both warmup and stretches."""

    @pytest.mark.asyncio
    async def test_generate_warmup_and_stretches(self, warmup_service, sample_workout_exercises):
        """Test generating both warmup and stretches."""
        warmup_service.create_warmup_for_workout = AsyncMock(return_value={"id": 1})
        warmup_service.create_stretches_for_workout = AsyncMock(return_value={"id": 2})

        result = await warmup_service.generate_warmup_and_stretches_for_workout(
            workout_id="w1",
            exercises=sample_workout_exercises,
            warmup_duration=5,
            stretch_duration=5,
            user_id="user-123"
        )

        assert "warmup" in result
        assert "stretches" in result
        assert result["warmup"]["id"] == 1
        assert result["stretches"]["id"] == 2


# ============================================================
# MUSCLE KEYWORD MAPPING TESTS
# ============================================================

class TestMuscleKeywordMapping:
    """Test muscle keyword mappings."""

    def test_chest_keywords(self):
        """Test chest muscle keywords."""
        keywords = MUSCLE_KEYWORDS.get("chest", [])
        assert "chest" in keywords
        assert "pectoral" in keywords

    def test_back_keywords(self):
        """Test back muscle keywords."""
        keywords = MUSCLE_KEYWORDS.get("back", [])
        assert "back" in keywords
        assert "lat" in keywords

    def test_full_body_matches_all(self):
        """Test full body matches everything."""
        keywords = MUSCLE_KEYWORDS.get("full body", [])
        assert "" in keywords  # Empty string matches all


# ============================================================
# WARMUP/STRETCH BY MUSCLE MAPPING TESTS
# ============================================================

class TestWarmupStretchByMuscle:
    """Test warmup and stretch mappings by muscle."""

    def test_warmup_by_muscle_exists(self):
        """Test warmup exercises exist for major muscles."""
        assert "chest" in WARMUP_BY_MUSCLE
        assert "back" in WARMUP_BY_MUSCLE
        assert "legs" in WARMUP_BY_MUSCLE
        assert len(WARMUP_BY_MUSCLE["chest"]) > 0

    def test_stretch_by_muscle_exists(self):
        """Test stretch exercises exist for major muscles."""
        assert "chest" in STRETCH_BY_MUSCLE
        assert "back" in STRETCH_BY_MUSCLE
        assert "legs" in STRETCH_BY_MUSCLE
        assert len(STRETCH_BY_MUSCLE["chest"]) > 0


# ============================================================
# SINGLETON TESTS
# ============================================================

class TestSingleton:
    """Test singleton pattern."""

    def test_get_warmup_stretch_service_returns_same_instance(self):
        """Test singleton returns same instance."""
        import services.warmup_stretch_service as module
        module._warmup_stretch_service = None

        with patch("services.warmup_stretch_service.get_supabase"):
            with patch("services.warmup_stretch_service.get_settings") as mock_settings:
                mock_settings.return_value.gemini_api_key = "test-key"
                mock_settings.return_value.gemini_model = "gemini-2.0-flash"

                service1 = get_warmup_stretch_service()
                service2 = get_warmup_stretch_service()

                assert service1 is service2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
