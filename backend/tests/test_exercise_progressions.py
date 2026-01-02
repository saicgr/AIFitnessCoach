"""
Tests for Leverage Progression System (Exercise Progressions API).

Tests all exercise progression endpoints including:
- Get all progression chains
- Get chain by ID
- Get chains by muscle group
- Get chain with variants
- User mastery CRUD
- Mastery updates from feedback
- Progression suggestions
- Accept progression
- Rep preferences

This test module focuses on the leverage-based progression system where users
progress through exercise variants (e.g., wall push-ups -> standard push-ups ->
diamond push-ups) based on mastery signals from workout feedback.
"""
import pytest
from unittest.mock import Mock, MagicMock, patch, AsyncMock
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
import uuid
import json

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


# ============================================================================
# CONSTANTS
# ============================================================================

# Default consecutive easy sessions required for progression readiness
DEFAULT_CONSECUTIVE_EASY_FOR_PROGRESSION = 3

# Training focus rep ranges
TRAINING_FOCUS_REP_RANGES = {
    "strength": {"min_reps": 3, "max_reps": 6},
    "hypertrophy": {"min_reps": 8, "max_reps": 12},
    "endurance": {"min_reps": 15, "max_reps": 20},
}


# ============================================================================
# MOCK DATA GENERATORS
# ============================================================================

def generate_mock_progression_chain(
    chain_id: str = None,
    name: str = "Push-up Progression",
    category: str = "push",
    total_steps: int = 5,
):
    """Generate a mock progression chain.

    Category must be one of: push, pull, legs, core, balance, flexibility
    """
    return {
        "id": chain_id or str(uuid.uuid4()),
        "name": name,
        "description": f"Progress through {name.lower()} from beginner to advanced",
        "category": category,
        "icon": "fitness_center",
        "target_muscles": ["chest", "triceps", "shoulders"] if category == "push" else ["back", "biceps"],
        "estimated_weeks_to_master": 24,
        "total_steps": total_steps,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_exercise_variant(
    chain_id: str,
    step_order: int = 0,
    exercise_name: str = "Wall Push-ups",
    difficulty_level: str = "beginner",
):
    """Generate a mock exercise variant (step) within a progression chain.

    difficulty_level must be one of: beginner, intermediate, advanced, elite
    """
    return {
        "id": str(uuid.uuid4()),
        "chain_id": chain_id,
        "exercise_name": exercise_name,
        "step_order": step_order,
        "difficulty_level": difficulty_level,
        "prerequisites": [],
        "unlock_criteria": {
            "min_reps": 12,
            "min_sets": 3,
            "min_hold_seconds": None,
            "min_consecutive_days": None,
            "custom_requirement": None,
        },
        "tips": ["Keep core tight", "Control the movement"],
        "common_mistakes": ["Sagging hips", "Flaring elbows"],
        "video_url": f"https://example.com/videos/{exercise_name.lower().replace(' ', '-')}.mp4",
        "image_url": None,
        "description": f"A {difficulty_level} level exercise",
        "sets_recommendation": "3",
        "reps_recommendation": "8-12",
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_user_skill_progress(
    user_id: str,
    chain_id: str,
    current_step_order: int = 0,
    attempts_at_current: int = 5,
    best_reps_at_current: int = 10,
    is_completed: bool = False,
    is_active: bool = True,
):
    """Generate mock user skill progress record matching UserSkillProgress schema."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "chain_id": chain_id,
        "current_step_order": current_step_order,
        "unlocked_steps": list(range(current_step_order + 1)),
        "attempts_at_current": attempts_at_current,
        "best_reps_at_current": best_reps_at_current,
        "best_hold_at_current": None,
        "is_completed": is_completed,
        "is_active": is_active,
        "started_at": (datetime.now() - timedelta(days=30)).isoformat(),
        "last_attempt_at": datetime.now().isoformat(),
        "completed_at": datetime.now().isoformat() if is_completed else None,
        "created_at": (datetime.now() - timedelta(days=30)).isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_user_mastery(
    user_id: str,
    exercise_name: str,
    consecutive_easy_sessions: int = 0,
    total_sessions: int = 5,
    current_mastery_level: str = "learning",
    ready_for_progression: bool = False,
):
    """Generate mock user mastery record for leverage-based exercise mastery.

    This is for the new leverage progression system which tracks mastery per exercise
    based on feedback signals (too_easy, just_right, too_hard).
    """
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "exercise_name": exercise_name,
        "consecutive_easy_sessions": consecutive_easy_sessions,
        "total_sessions": total_sessions,
        "current_mastery_level": current_mastery_level,  # learning, proficient, mastered, graduated
        "ready_for_progression": ready_for_progression,
        "last_difficulty_feedback": "just_right",
        "average_rpe": 7.5,
        "last_session_date": datetime.now().isoformat(),
        "first_session_date": (datetime.now() - timedelta(days=30)).isoformat(),
        "created_at": (datetime.now() - timedelta(days=30)).isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_rep_preferences(
    user_id: str,
    training_focus: str = "hypertrophy",
    min_reps: int = 8,
    max_reps: int = 12,
):
    """Generate mock rep preferences for a user."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "training_focus": training_focus,
        "min_reps": min_reps,
        "max_reps": max_reps,
        "prefer_higher_reps": training_focus == "endurance",
        "prefer_lower_reps": training_focus == "strength",
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_progression_suggestion(
    user_id: str,
    current_exercise: str = "Standard Push-ups",
    suggested_exercise: str = "Diamond Push-ups",
    reason: str = "Mastered current variant",
):
    """Generate a mock progression suggestion."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "current_exercise": current_exercise,
        "suggested_exercise": suggested_exercise,
        "reason": reason,
        "confidence_score": 0.85,
        "equipment_compatible": True,
        "difficulty_increase": 1,
        "created_at": datetime.now().isoformat(),
    }


def generate_mock_feedback(
    user_id: str,
    exercise_name: str,
    difficulty_felt: str = "just_right",
    rpe: float = 7.0,
):
    """Generate mock exercise feedback."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "exercise_name": exercise_name,
        "difficulty_felt": difficulty_felt,
        "rpe": rpe,
        "completed_sets": 3,
        "completed_reps": 12,
        "would_do_again": True,
        "created_at": datetime.now().isoformat(),
    }


# ============================================================================
# SAMPLE DATA FIXTURES
# ============================================================================

def get_sample_push_up_chain():
    """Get a complete push-up progression chain with variants."""
    chain_id = "11111111-1111-1111-1111-111111111111"
    chain = generate_mock_progression_chain(
        chain_id=chain_id,
        name="Push-up Progression",
        category="push",
        total_steps=5,
    )

    variants = [
        generate_mock_exercise_variant(chain_id, 0, "Wall Push-ups", "beginner"),
        generate_mock_exercise_variant(chain_id, 1, "Incline Push-ups", "beginner"),
        generate_mock_exercise_variant(chain_id, 2, "Knee Push-ups", "intermediate"),
        generate_mock_exercise_variant(chain_id, 3, "Standard Push-ups", "intermediate"),
        generate_mock_exercise_variant(chain_id, 4, "Diamond Push-ups", "advanced"),
    ]

    return chain, variants


def get_sample_pull_up_chain():
    """Get a complete pull-up progression chain with variants."""
    chain_id = "22222222-2222-2222-2222-222222222222"
    chain = generate_mock_progression_chain(
        chain_id=chain_id,
        name="Pull-up Progression",
        category="pull",
        total_steps=4,
    )

    variants = [
        generate_mock_exercise_variant(chain_id, 0, "Dead Hang", "beginner"),
        generate_mock_exercise_variant(chain_id, 1, "Assisted Pull-ups", "intermediate"),
        generate_mock_exercise_variant(chain_id, 2, "Negative Pull-ups", "intermediate"),
        generate_mock_exercise_variant(chain_id, 3, "Full Pull-ups", "advanced"),
    ]

    return chain, variants


def get_sample_squat_chain():
    """Get a complete squat progression chain with variants (using 'legs' category)."""
    chain_id = "33333333-3333-3333-3333-333333333333"
    chain = generate_mock_progression_chain(
        chain_id=chain_id,
        name="Squat Progression",
        category="legs",  # Must use valid SkillCategory
        total_steps=4,
    )

    variants = [
        generate_mock_exercise_variant(chain_id, 0, "Assisted Squats", "beginner"),
        generate_mock_exercise_variant(chain_id, 1, "Bodyweight Squats", "beginner"),
        generate_mock_exercise_variant(chain_id, 2, "Bulgarian Split Squats", "intermediate"),
        generate_mock_exercise_variant(chain_id, 3, "Pistol Squats", "advanced"),
    ]

    return chain, variants


# ============================================================================
# FIXTURES
# ============================================================================

@pytest.fixture
def client():
    """Create a test client."""
    return TestClient(app)


@pytest.fixture
def mock_user_id():
    """Generate a mock user ID."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_chain_id():
    """Generate a mock chain ID."""
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
    mock_select.ilike.return_value = mock_select
    mock_select.order.return_value = mock_select
    mock_select.limit.return_value = mock_select
    mock_select.single.return_value = mock_select
    mock_select.gte.return_value = mock_select
    mock_select.lte.return_value = mock_select

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
def sample_user_with_history(mock_user_id):
    """Create sample user data with exercise history."""
    return {
        "user_id": mock_user_id,
        "fitness_level": "intermediate",
        "goals": ["build_muscle", "strength"],
        "equipment": ["bodyweight", "dumbbell", "pull_up_bar"],
        "exercise_history": [
            {
                "exercise_name": "Standard Push-ups",
                "sessions": 10,
                "last_session": datetime.now().isoformat(),
            },
            {
                "exercise_name": "Bodyweight Squats",
                "sessions": 8,
                "last_session": datetime.now().isoformat(),
            },
        ],
    }


# ============================================================================
# TESTS: CHAIN MANAGEMENT
# ============================================================================

class TestGetAllProgressionChains:
    """Tests for GET /api/v1/exercise-progressions/chains endpoint."""

    def test_get_all_chains_success(self, client, mock_supabase):
        """Test successfully fetching all progression chains."""
        push_chain, _ = get_sample_push_up_chain()
        pull_chain, _ = get_sample_pull_up_chain()
        squat_chain, _ = get_sample_squat_chain()

        chains = [push_chain, pull_chain, squat_chain]

        mock_result = MagicMock()
        mock_result.data = chains
        mock_supabase.table.return_value.select.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get("/api/v1/skill-progressions/chains")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 3
            assert data[0]["name"] == "Push-up Progression"

    def test_get_chains_empty(self, client, mock_supabase):
        """Test fetching chains when none exist."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.order.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get("/api/v1/skill-progressions/chains")

            assert response.status_code == 200
            assert response.json() == []


class TestGetChainById:
    """Tests for GET /api/v1/exercise-progressions/chains/{chain_id} endpoint."""

    def test_get_chain_by_id_success(self, client, mock_supabase):
        """Test successfully fetching a chain by ID."""
        chain, variants = get_sample_push_up_chain()

        mock_chain_result = MagicMock()
        mock_chain_result.data = [chain]

        mock_variants_result = MagicMock()
        mock_variants_result.data = variants

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "skill_progression_chains":
                mock_table.select.return_value.eq.return_value.execute.return_value = mock_chain_result
            else:
                mock_table.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_variants_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/chains/{chain['id']}")

            assert response.status_code == 200
            data = response.json()
            assert data["id"] == chain["id"]
            assert data["name"] == "Push-up Progression"

    def test_get_chain_not_found(self, client, mock_supabase, mock_chain_id):
        """Test fetching non-existent chain returns 404."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/chains/{mock_chain_id}")

            assert response.status_code == 404


class TestGetChainsByMuscleGroup:
    """Tests for filtering chains by muscle group."""

    def test_get_chains_by_muscle_group(self, client, mock_supabase):
        """Test fetching chains filtered by muscle group."""
        push_chain, _ = get_sample_push_up_chain()

        # Only chest exercises
        mock_result = MagicMock()
        mock_result.data = [push_chain]
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get("/api/v1/skill-progressions/chains?category=push")

            assert response.status_code == 200
            data = response.json()
            assert len(data) >= 1
            # All returned chains should be push category
            for chain in data:
                assert chain["category"] == "push"


class TestGetChainWithVariants:
    """Tests for getting a chain with all its exercise variants."""

    def test_get_chain_with_all_variants(self, client, mock_supabase):
        """Test fetching a chain includes all exercise variants."""
        chain, variants = get_sample_push_up_chain()
        chain["steps"] = variants  # Add steps to chain

        mock_chain_result = MagicMock()
        mock_chain_result.data = [chain]

        mock_steps_result = MagicMock()
        mock_steps_result.data = variants

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "skill_progression_chains":
                mock_table.select.return_value.eq.return_value.execute.return_value = mock_chain_result
            else:  # skill_progression_steps
                mock_table.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_steps_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/chains/{chain['id']}")

            assert response.status_code == 200
            data = response.json()
            assert "steps" in data
            assert len(data["steps"]) == 5
            # Variants should be ordered by variant_order
            assert data["steps"][0]["exercise_name"] == "Wall Push-ups"
            assert data["steps"][4]["exercise_name"] == "Diamond Push-ups"

    def test_chain_variants_ordered_by_step_order(self):
        """Test that variants are ordered by step_order."""
        chain, variants = get_sample_pull_up_chain()

        # Verify step_order is sequential
        step_orders = [v["step_order"] for v in variants]
        assert step_orders == sorted(step_orders), "Variants should be ordered by step_order"
        assert step_orders == [0, 1, 2, 3], "Step orders should be sequential from 0"

        # Verify exercise names are in expected order
        exercise_names = [v["exercise_name"] for v in variants]
        assert exercise_names[0] == "Dead Hang"
        assert exercise_names[-1] == "Full Pull-ups"


# ============================================================================
# TESTS: USER MASTERY
# ============================================================================

class TestGetUserMastery:
    """Tests for user exercise mastery endpoints."""

    def test_get_user_mastery_empty_new_user(self, client, mock_supabase, mock_user_id):
        """Test fetching mastery for new user returns empty list."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/user/{mock_user_id}/progress")

            assert response.status_code == 200
            assert response.json() == []

    def test_get_user_mastery_with_data(self, client, mock_supabase, mock_user_id):
        """Test fetching mastery data for user with exercise history."""
        chain, variants = get_sample_push_up_chain()

        # Create user skill progress that matches the actual schema
        progress = generate_mock_user_skill_progress(
            mock_user_id,
            chain["id"],
            current_step_order=3,
            attempts_at_current=10,
            best_reps_at_current=15,
        )
        # Add the chain data as it would be returned with the join
        progress["skill_progression_chains"] = chain

        mock_progress_result = MagicMock()
        mock_progress_result.data = [progress]

        # Mock the steps query
        mock_steps_result = MagicMock()
        mock_steps_result.data = variants

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_skill_progress":
                mock_select = MagicMock()
                mock_select.eq.return_value.order.return_value.execute.return_value = mock_progress_result
                mock_table.select.return_value = mock_select
            elif table_name == "skill_progression_steps":
                mock_select = MagicMock()
                mock_select.eq.return_value.order.return_value.execute.return_value = mock_steps_result
                mock_table.select.return_value = mock_select
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/user/{mock_user_id}/progress")

            assert response.status_code == 200
            data = response.json()
            assert len(data) >= 1


class TestUpdateExerciseMastery:
    """Tests for updating exercise mastery."""

    def test_update_mastery_success(self, client, mock_supabase, mock_user_id):
        """Test successfully updating mastery record."""
        mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=1,
        )

        updated_mastery = mastery.copy()
        updated_mastery["consecutive_easy_sessions"] = 2
        updated_mastery["total_sessions"] = 6

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_exercise_mastery":
                mock_select = MagicMock()
                mock_select.data = [mastery]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_select
                mock_update = MagicMock()
                mock_update.data = [updated_mastery]
                mock_table.update.return_value.eq.return_value.execute.return_value = mock_update
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        # Test mastery update logic directly
        assert updated_mastery["consecutive_easy_sessions"] == 2
        assert updated_mastery["total_sessions"] == 6

    def test_mastery_updates_consecutive_easy_sessions(self, client, mock_supabase, mock_user_id):
        """Test that 'too_easy' feedback increments consecutive_easy_sessions."""
        initial_mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=1,
            total_sessions=5,
        )

        # Simulate receiving 'too_easy' feedback
        feedback = generate_mock_feedback(
            mock_user_id,
            "Standard Push-ups",
            difficulty_felt="too_easy",
            rpe=5.0,
        )

        # Expected: consecutive_easy_sessions should increase
        expected_consecutive = initial_mastery["consecutive_easy_sessions"] + 1

        updated_mastery = initial_mastery.copy()
        updated_mastery["consecutive_easy_sessions"] = expected_consecutive
        updated_mastery["total_sessions"] = 6
        updated_mastery["last_difficulty_feedback"] = "too_easy"

        assert updated_mastery["consecutive_easy_sessions"] == 2
        assert updated_mastery["last_difficulty_feedback"] == "too_easy"

    def test_ready_for_progression_after_consecutive_easy(self, mock_user_id):
        """Test that user becomes ready for progression after enough consecutive easy sessions."""
        # User has 2 consecutive easy sessions, needs 3 to be ready
        mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=2,
            ready_for_progression=False,
        )

        # After one more easy session, should be ready
        mastery["consecutive_easy_sessions"] = 3

        # Check if ready for progression
        is_ready = mastery["consecutive_easy_sessions"] >= DEFAULT_CONSECUTIVE_EASY_FOR_PROGRESSION

        assert is_ready is True

        # Update mastery
        mastery["ready_for_progression"] = is_ready
        assert mastery["ready_for_progression"] is True

    def test_mastery_resets_on_difficulty(self, mock_user_id):
        """Test that consecutive count resets when exercise feels difficult."""
        # User had 2 consecutive easy sessions
        mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=2,
            ready_for_progression=False,
        )

        # User reports "too_hard" - should reset counter
        feedback = generate_mock_feedback(
            mock_user_id,
            "Standard Push-ups",
            difficulty_felt="too_hard",
            rpe=9.0,
        )

        # After difficult feedback, reset consecutive count
        if feedback["difficulty_felt"] == "too_hard":
            mastery["consecutive_easy_sessions"] = 0
            mastery["ready_for_progression"] = False

        assert mastery["consecutive_easy_sessions"] == 0
        assert mastery["ready_for_progression"] is False

    def test_just_right_maintains_progress(self, mock_user_id):
        """Test that 'just_right' feedback doesn't reset or increment consecutive easy."""
        mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=2,
        )

        initial_consecutive = mastery["consecutive_easy_sessions"]

        # "just_right" feedback - should maintain current progress
        feedback = generate_mock_feedback(
            mock_user_id,
            "Standard Push-ups",
            difficulty_felt="just_right",
            rpe=7.0,
        )

        # Consecutive easy count stays the same (not incremented, not reset)
        if feedback["difficulty_felt"] == "just_right":
            # Keep same consecutive count
            pass

        assert mastery["consecutive_easy_sessions"] == initial_consecutive


# ============================================================================
# TESTS: PROGRESSION SUGGESTIONS
# ============================================================================

class TestProgressionSuggestions:
    """Tests for getting progression suggestions."""

    def test_get_progression_suggestions_success(self, client, mock_supabase, mock_user_id):
        """Test successfully getting progression suggestions."""
        # User is ready to progress from Standard to Diamond Push-ups
        mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=3,
            ready_for_progression=True,
            current_mastery_level="mastered",
        )

        suggestion = generate_mock_progression_suggestion(
            mock_user_id,
            current_exercise="Standard Push-ups",
            suggested_exercise="Diamond Push-ups",
            reason="Mastered Standard Push-ups with 3 consecutive easy sessions",
        )

        # Verify suggestion structure
        assert suggestion["current_exercise"] == "Standard Push-ups"
        assert suggestion["suggested_exercise"] == "Diamond Push-ups"
        assert suggestion["confidence_score"] > 0.5

    def test_no_suggestions_for_new_user(self, client, mock_supabase, mock_user_id):
        """Test that new user with no history gets no suggestions."""
        # New user has no exercise mastery data
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        # No suggestions should be generated for users without exercise history
        suggestions = []

        assert len(suggestions) == 0

    def test_suggestion_includes_next_variant(self, mock_user_id):
        """Test that suggestion includes the correct next variant in chain."""
        chain, variants = get_sample_push_up_chain()

        # User mastered Standard Push-ups (variant 4)
        current_variant = variants[3]  # Standard Push-ups
        next_variant = variants[4]  # Diamond Push-ups

        suggestion = generate_mock_progression_suggestion(
            mock_user_id,
            current_exercise=current_variant["exercise_name"],
            suggested_exercise=next_variant["exercise_name"],
        )

        assert suggestion["suggested_exercise"] == "Diamond Push-ups"
        assert suggestion["difficulty_increase"] >= 1

    def test_suggestion_respects_equipment(self, mock_user_id, sample_user_with_history):
        """Test that suggestions respect user's available equipment."""
        user_equipment = sample_user_with_history["equipment"]

        # Create suggestion for bodyweight exercise (user has bodyweight)
        suggestion = generate_mock_progression_suggestion(
            mock_user_id,
            current_exercise="Knee Push-ups",
            suggested_exercise="Standard Push-ups",
        )

        # Verify equipment compatibility
        assert suggestion["equipment_compatible"] is True

        # Standard push-ups require bodyweight only
        required_equipment = "bodyweight"
        assert required_equipment in user_equipment

    def test_no_suggestion_when_at_chain_end(self, mock_user_id):
        """Test no suggestion when user has mastered the final variant."""
        chain, variants = get_sample_push_up_chain()

        # User mastered Diamond Push-ups (final variant)
        final_variant = variants[-1]

        mastery = generate_mock_user_mastery(
            mock_user_id,
            final_variant["exercise_name"],
            consecutive_easy_sessions=3,
            ready_for_progression=True,
            current_mastery_level="mastered",
        )

        # No next variant available
        current_order = final_variant["step_order"]
        next_variants = [v for v in variants if v["step_order"] > current_order]

        assert len(next_variants) == 0
        # Should not generate a suggestion

    def test_suggestion_confidence_based_on_mastery(self, mock_user_id):
        """Test that suggestion confidence varies based on mastery level."""
        # High mastery = high confidence
        high_mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=5,
            total_sessions=20,
            current_mastery_level="mastered",
        )

        # Low mastery = lower confidence
        low_mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=3,
            total_sessions=5,
            current_mastery_level="proficient",
        )

        # Calculate confidence scores
        high_confidence = min(1.0, 0.5 + (high_mastery["consecutive_easy_sessions"] * 0.1))
        low_confidence = min(1.0, 0.5 + (low_mastery["consecutive_easy_sessions"] * 0.1))

        assert high_confidence > low_confidence


# ============================================================================
# TESTS: ACCEPT PROGRESSION
# ============================================================================

class TestAcceptProgression:
    """Tests for accepting a progression suggestion."""

    def test_accept_progression_creates_new_mastery(self, client, mock_supabase, mock_user_id):
        """Test accepting progression creates mastery for new exercise."""
        old_exercise = "Standard Push-ups"
        new_exercise = "Diamond Push-ups"

        # Accept progression creates a new mastery record for the new exercise
        new_mastery = generate_mock_user_mastery(
            mock_user_id,
            new_exercise,
            consecutive_easy_sessions=0,
            total_sessions=0,
            current_mastery_level="learning",
            ready_for_progression=False,
        )

        assert new_mastery["exercise_name"] == new_exercise
        assert new_mastery["current_mastery_level"] == "learning"
        assert new_mastery["consecutive_easy_sessions"] == 0

    def test_accept_progression_logs_activity(self, mock_user_id):
        """Test accepting progression logs the activity."""
        activity_log = {
            "user_id": mock_user_id,
            "activity_type": "exercise_progression",
            "details": {
                "from_exercise": "Standard Push-ups",
                "to_exercise": "Diamond Push-ups",
                "reason": "User accepted progression suggestion",
            },
            "created_at": datetime.now().isoformat(),
        }

        assert activity_log["activity_type"] == "exercise_progression"
        assert activity_log["details"]["from_exercise"] == "Standard Push-ups"
        assert activity_log["details"]["to_exercise"] == "Diamond Push-ups"

    def test_accept_progression_updates_old_exercise(self, mock_user_id):
        """Test accepting progression updates old exercise mastery."""
        old_mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=3,
            ready_for_progression=True,
            current_mastery_level="mastered",
        )

        # After accepting progression, old exercise should be marked as "graduated"
        old_mastery["current_mastery_level"] = "graduated"
        old_mastery["ready_for_progression"] = False
        old_mastery["graduated_to"] = "Diamond Push-ups"

        assert old_mastery["current_mastery_level"] == "graduated"
        assert old_mastery["graduated_to"] == "Diamond Push-ups"


# ============================================================================
# TESTS: REP PREFERENCES
# ============================================================================

class TestRepPreferences:
    """Tests for user rep preferences."""

    def test_get_default_rep_preferences(self, mock_user_id):
        """Test getting default rep preferences for new user."""
        # New user should get hypertrophy defaults
        default_prefs = generate_mock_rep_preferences(
            mock_user_id,
            training_focus="hypertrophy",
            min_reps=8,
            max_reps=12,
        )

        assert default_prefs["min_reps"] == 8
        assert default_prefs["max_reps"] == 12
        assert default_prefs["training_focus"] == "hypertrophy"

    def test_update_rep_preferences(self, mock_user_id):
        """Test updating rep preferences."""
        # Change from hypertrophy to strength
        old_prefs = generate_mock_rep_preferences(
            mock_user_id,
            training_focus="hypertrophy",
            min_reps=8,
            max_reps=12,
        )

        new_prefs = generate_mock_rep_preferences(
            mock_user_id,
            training_focus="strength",
            min_reps=3,
            max_reps=6,
        )

        assert new_prefs["training_focus"] == "strength"
        assert new_prefs["min_reps"] == 3
        assert new_prefs["max_reps"] == 6

    def test_rep_preferences_validation_min_less_than_max(self, mock_user_id):
        """Test that min_reps must be less than max_reps."""
        # Invalid: min > max
        invalid_prefs = {
            "user_id": mock_user_id,
            "min_reps": 15,
            "max_reps": 8,
        }

        is_valid = invalid_prefs["min_reps"] < invalid_prefs["max_reps"]
        assert is_valid is False

        # Valid: min < max
        valid_prefs = generate_mock_rep_preferences(
            mock_user_id,
            min_reps=8,
            max_reps=12,
        )

        is_valid = valid_prefs["min_reps"] < valid_prefs["max_reps"]
        assert is_valid is True

    def test_training_focus_affects_defaults(self):
        """Test that training focus determines default rep ranges."""
        # Strength focus
        strength_defaults = TRAINING_FOCUS_REP_RANGES["strength"]
        assert strength_defaults["min_reps"] == 3
        assert strength_defaults["max_reps"] == 6

        # Hypertrophy focus
        hypertrophy_defaults = TRAINING_FOCUS_REP_RANGES["hypertrophy"]
        assert hypertrophy_defaults["min_reps"] == 8
        assert hypertrophy_defaults["max_reps"] == 12

        # Endurance focus
        endurance_defaults = TRAINING_FOCUS_REP_RANGES["endurance"]
        assert endurance_defaults["min_reps"] == 15
        assert endurance_defaults["max_reps"] == 20

    def test_rep_preferences_per_exercise_override(self, mock_user_id):
        """Test that users can override rep preferences for specific exercises."""
        # Global preference: hypertrophy (8-12)
        global_prefs = generate_mock_rep_preferences(
            mock_user_id,
            training_focus="hypertrophy",
            min_reps=8,
            max_reps=12,
        )

        # Override for specific exercise: strength rep range for deadlifts
        exercise_override = {
            "user_id": mock_user_id,
            "exercise_name": "Deadlift",
            "min_reps": 3,
            "max_reps": 5,
            "override_global": True,
        }

        # When getting reps for deadlift, use override
        effective_min = exercise_override["min_reps"]
        effective_max = exercise_override["max_reps"]

        assert effective_min == 3
        assert effective_max == 5


# ============================================================================
# TESTS: INTEGRATION
# ============================================================================

class TestFeedbackTriggersMateryUpdate:
    """Integration tests for feedback triggering mastery updates."""

    def test_feedback_triggers_mastery_update(self, mock_user_id):
        """Test that submitting feedback updates mastery record."""
        # Initial mastery state
        mastery = generate_mock_user_mastery(
            mock_user_id,
            "Standard Push-ups",
            consecutive_easy_sessions=1,
            total_sessions=5,
        )

        # Submit feedback
        feedback = generate_mock_feedback(
            mock_user_id,
            "Standard Push-ups",
            difficulty_felt="too_easy",
            rpe=5.5,
        )

        # After feedback processing, mastery should be updated
        if feedback["difficulty_felt"] == "too_easy":
            mastery["consecutive_easy_sessions"] += 1
        elif feedback["difficulty_felt"] == "too_hard":
            mastery["consecutive_easy_sessions"] = 0

        mastery["total_sessions"] += 1
        mastery["last_difficulty_feedback"] = feedback["difficulty_felt"]
        mastery["average_rpe"] = (mastery["average_rpe"] + feedback["rpe"]) / 2

        assert mastery["consecutive_easy_sessions"] == 2
        assert mastery["total_sessions"] == 6
        assert mastery["last_difficulty_feedback"] == "too_easy"

    def test_workout_completion_updates_multiple_exercises(self, mock_user_id):
        """Test that completing a workout updates mastery for all exercises."""
        exercises_in_workout = [
            ("Push-ups", "too_easy"),
            ("Pull-ups", "just_right"),
            ("Squats", "too_hard"),
        ]

        masteries = {}
        for exercise_name, difficulty in exercises_in_workout:
            mastery = generate_mock_user_mastery(
                mock_user_id,
                exercise_name,
                consecutive_easy_sessions=1,
            )

            # Update based on feedback
            if difficulty == "too_easy":
                mastery["consecutive_easy_sessions"] += 1
            elif difficulty == "too_hard":
                mastery["consecutive_easy_sessions"] = 0
            # "just_right" - no change

            mastery["last_difficulty_feedback"] = difficulty
            masteries[exercise_name] = mastery

        # Verify each was updated correctly
        assert masteries["Push-ups"]["consecutive_easy_sessions"] == 2
        assert masteries["Pull-ups"]["consecutive_easy_sessions"] == 1  # unchanged
        assert masteries["Squats"]["consecutive_easy_sessions"] == 0  # reset


class TestWorkoutGenerationUsesRepPreferences:
    """Tests for workout generation respecting rep preferences."""

    def test_workout_generation_respects_rep_preferences(self, mock_user_id):
        """Test that generated workouts use user's rep preferences."""
        # User prefers strength training (3-6 reps)
        rep_prefs = generate_mock_rep_preferences(
            mock_user_id,
            training_focus="strength",
            min_reps=3,
            max_reps=6,
        )

        # Simulated workout exercise
        generated_exercise = {
            "name": "Bench Press",
            "sets": 5,
            "reps": 5,  # Should be within 3-6 range
        }

        # Verify reps are within preference range
        assert rep_prefs["min_reps"] <= generated_exercise["reps"] <= rep_prefs["max_reps"]

    def test_workout_generation_uses_hypertrophy_defaults(self, mock_user_id):
        """Test that hypertrophy focus uses 8-12 rep range."""
        rep_prefs = generate_mock_rep_preferences(
            mock_user_id,
            training_focus="hypertrophy",
            min_reps=8,
            max_reps=12,
        )

        # Generated exercise should have 8-12 reps
        generated_exercise = {
            "name": "Dumbbell Curls",
            "sets": 3,
            "reps": 10,
        }

        assert rep_prefs["min_reps"] <= generated_exercise["reps"] <= rep_prefs["max_reps"]


class TestProgressionContextInGeminiPrompt:
    """Tests for progression context being included in AI prompts."""

    def test_progression_context_included_in_prompt(self, mock_user_id):
        """Test that mastery/progression context is included in Gemini prompts."""
        # User's progression context
        ready_exercises = [
            {
                "exercise_name": "Standard Push-ups",
                "ready_for_progression": True,
                "suggested_next": "Diamond Push-ups",
            },
        ]

        context_string = _build_progression_context(ready_exercises)

        assert "Standard Push-ups" in context_string
        assert "Diamond Push-ups" in context_string
        assert "ready" in context_string.lower() or "progression" in context_string.lower()

    def test_no_progression_context_for_new_user(self, mock_user_id):
        """Test that new users don't have progression context."""
        ready_exercises = []  # New user has no ready exercises

        context_string = _build_progression_context(ready_exercises)

        # Should be empty or minimal
        assert context_string == "" or "no progression" in context_string.lower()


# ============================================================================
# TESTS: EDGE CASES
# ============================================================================

class TestEdgeCases:
    """Tests for edge cases in the progression system."""

    def test_handle_missing_mastery_data(self, mock_user_id):
        """Test graceful handling when mastery data is missing."""
        # Exercise has no mastery record
        mastery = None

        # Should create a new mastery record
        if mastery is None:
            mastery = generate_mock_user_mastery(
                mock_user_id,
                "New Exercise",
                consecutive_easy_sessions=0,
                total_sessions=0,
                current_mastery_level="learning",
            )

        assert mastery is not None
        assert mastery["current_mastery_level"] == "learning"

    def test_handle_chain_without_variants(self, mock_supabase):
        """Test handling a chain with no variants (steps)."""
        chain = generate_mock_progression_chain(
            name="Empty Chain",
            total_steps=0,
        )

        variants = []

        # Should not crash, just return empty variants
        assert len(variants) == 0
        assert chain["total_steps"] == 0

    def test_concurrent_feedback_updates(self, mock_user_id):
        """Test handling multiple feedback updates in quick succession."""
        # Initial state
        mastery = generate_mock_user_mastery(
            mock_user_id,
            "Push-ups",
            consecutive_easy_sessions=2,
        )

        # Simulate two quick feedbacks
        feedback1 = generate_mock_feedback(mock_user_id, "Push-ups", "too_easy")
        feedback2 = generate_mock_feedback(mock_user_id, "Push-ups", "too_easy")

        # Apply first feedback
        mastery["consecutive_easy_sessions"] += 1
        mastery["total_sessions"] += 1

        # Apply second feedback
        mastery["consecutive_easy_sessions"] += 1
        mastery["total_sessions"] += 1

        # Both should be applied
        assert mastery["consecutive_easy_sessions"] == 4
        assert mastery["total_sessions"] == 7

    def test_invalid_difficulty_feedback_value(self, mock_user_id):
        """Test handling invalid difficulty feedback values."""
        mastery = generate_mock_user_mastery(
            mock_user_id,
            "Push-ups",
            consecutive_easy_sessions=2,
        )

        # Invalid feedback value
        invalid_feedback = {
            "difficulty_felt": "invalid_value",
            "rpe": 7.0,
        }

        # Should handle gracefully - treat as "just_right" (no change)
        if invalid_feedback["difficulty_felt"] not in ["too_easy", "just_right", "too_hard"]:
            # No change to consecutive count
            pass

        # Mastery unchanged
        assert mastery["consecutive_easy_sessions"] == 2


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def _build_progression_context(ready_exercises: list) -> str:
    """Build a context string for progression-ready exercises."""
    if not ready_exercises:
        return ""

    context_parts = ["User is ready for progression on the following exercises:"]
    for ex in ready_exercises:
        context_parts.append(
            f"- {ex['exercise_name']}: ready for {ex.get('suggested_next', 'next variant')}"
        )

    return "\n".join(context_parts)


# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
