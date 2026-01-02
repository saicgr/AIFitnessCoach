"""
Tests for Skill Progressions API endpoints.

Tests all skill progression endpoints including:
- Get all progression chains
- Get chain with steps
- Get chain steps
- User progress CRUD
- Logging attempts
- Unlocking next step
- Starting a chain
"""
import pytest
from unittest.mock import Mock, MagicMock, patch, AsyncMock
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
import uuid

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


# ============ Mock Data Generators ============

def generate_mock_chain(
    chain_id: str = None,
    name: str = "Push-up Progression",
    category: str = "push",
    total_steps: int = 7,
):
    """Generate a mock progression chain."""
    return {
        "id": chain_id or str(uuid.uuid4()),
        "name": name,
        "description": f"Master the {name.lower()} from beginner to advanced",
        "category": category,
        "icon": "fitness_center",
        "target_muscles": ["chest", "triceps", "shoulders"],
        "estimated_weeks_to_master": 24,
        "total_steps": total_steps,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_step(
    chain_id: str,
    step_order: int = 0,
    exercise_name: str = "Wall Push-ups",
    difficulty_level: str = "beginner",
):
    """Generate a mock progression step."""
    return {
        "id": str(uuid.uuid4()),
        "chain_id": chain_id,
        "exercise_name": exercise_name,
        "step_order": step_order,
        "difficulty_level": difficulty_level,
        "prerequisites": [],
        "unlock_criteria": {
            "min_reps": 15,
            "min_sets": 3,
            "min_hold_seconds": None,
            "min_consecutive_days": None,
            "custom_requirement": None,
        },
        "tips": ["Keep your core engaged", "Control the movement"],
        "common_mistakes": ["Flaring elbows", "Sagging hips"],
        "video_url": "https://example.com/video.mp4",
        "image_url": "https://example.com/image.png",
        "description": f"A {difficulty_level} level exercise",
        "sets_recommendation": "3-4",
        "reps_recommendation": "10-15",
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_progress(
    user_id: str,
    chain_id: str,
    current_step_order: int = 0,
    best_reps: int = 10,
    is_completed: bool = False,
):
    """Generate mock user skill progress."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "chain_id": chain_id,
        "current_step_order": current_step_order,
        "unlocked_steps": list(range(current_step_order + 1)),
        "attempts_at_current": 5,
        "best_reps_at_current": best_reps,
        "best_hold_at_current": None,
        "is_completed": is_completed,
        "is_active": True,
        "started_at": (datetime.now() - timedelta(days=30)).isoformat(),
        "last_attempt_at": datetime.now().isoformat(),
        "completed_at": None,
        "created_at": (datetime.now() - timedelta(days=30)).isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_attempt(
    user_id: str,
    chain_id: str,
    step_order: int = 0,
    reps: int = 12,
    success: bool = True,
):
    """Generate a mock skill attempt log."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "chain_id": chain_id,
        "step_order": step_order,
        "reps": reps,
        "sets": 3,
        "hold_seconds": None,
        "success": success,
        "notes": "Felt good today",
        "attempted_at": datetime.now().isoformat(),
    }


# ============ Fixtures ============

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

    # Mock delete chain
    mock_delete = MagicMock()
    mock_table.delete.return_value = mock_delete
    mock_delete.eq.return_value = mock_delete

    return mock


# ============ Tests: Get All Chains ============

class TestGetAllChains:
    """Tests for GET /api/v1/skill-progressions/chains endpoint."""

    def test_get_all_chains_success(self, client, mock_supabase):
        """Test successfully fetching all progression chains."""
        chains = [
            generate_mock_chain(name="Push-up Progression", category="push"),
            generate_mock_chain(name="Pull-up Progression", category="pull"),
            generate_mock_chain(name="Squat Progression", category="legs"),
        ]

        mock_result = MagicMock()
        mock_result.data = chains
        mock_supabase.table.return_value.select.return_value.order.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get("/api/v1/skill-progressions/chains")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 3
            assert data[0]["name"] == "Push-up Progression"

    def test_get_chains_filtered_by_category(self, client, mock_supabase):
        """Test fetching chains filtered by category."""
        chains = [
            generate_mock_chain(name="Push-up Progression", category="push"),
            generate_mock_chain(name="Diamond Push-up Progression", category="push"),
        ]

        mock_result = MagicMock()
        mock_result.data = chains
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get("/api/v1/skill-progressions/chains?category=push")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 2
            assert all(c["category"] == "push" for c in data)

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


# ============ Tests: Get Chain with Steps ============

class TestGetChainWithSteps:
    """Tests for GET /api/v1/skill-progressions/chains/{chain_id} endpoint."""

    def test_get_chain_with_steps_success(self, client, mock_supabase, mock_chain_id):
        """Test successfully fetching a chain with all its steps."""
        chain = generate_mock_chain(chain_id=mock_chain_id, total_steps=5)
        steps = [
            generate_mock_step(mock_chain_id, 0, "Wall Push-ups", "beginner"),
            generate_mock_step(mock_chain_id, 1, "Incline Push-ups", "beginner"),
            generate_mock_step(mock_chain_id, 2, "Knee Push-ups", "intermediate"),
            generate_mock_step(mock_chain_id, 3, "Full Push-ups", "intermediate"),
            generate_mock_step(mock_chain_id, 4, "Diamond Push-ups", "advanced"),
        ]

        # Mock chain fetch
        mock_chain_result = MagicMock()
        mock_chain_result.data = [chain]

        # Mock steps fetch
        mock_steps_result = MagicMock()
        mock_steps_result.data = steps

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "skill_progression_chains":
                mock_table.select.return_value.eq.return_value.execute.return_value = mock_chain_result
            else:
                mock_table.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_steps_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/chains/{mock_chain_id}")

            assert response.status_code == 200
            data = response.json()
            assert data["id"] == mock_chain_id
            assert len(data["steps"]) == 5
            assert data["steps"][0]["exercise_name"] == "Wall Push-ups"
            assert data["steps"][4]["exercise_name"] == "Diamond Push-ups"

    def test_get_chain_not_found(self, client, mock_supabase, mock_chain_id):
        """Test fetching non-existent chain."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/chains/{mock_chain_id}")

            assert response.status_code == 404


# ============ Tests: Get Chain Steps ============

class TestGetChainSteps:
    """Tests for GET /api/v1/skill-progressions/chains/{chain_id}/steps endpoint."""

    def test_get_chain_steps_success(self, client, mock_supabase, mock_chain_id):
        """Test successfully fetching chain steps."""
        chain = generate_mock_chain(chain_id=mock_chain_id)
        steps = [
            generate_mock_step(mock_chain_id, 0, "Wall Push-ups"),
            generate_mock_step(mock_chain_id, 1, "Incline Push-ups"),
            generate_mock_step(mock_chain_id, 2, "Knee Push-ups"),
        ]

        call_count = [0]

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "skill_progression_chains":
                mock_result = MagicMock()
                mock_result.data = [{"id": mock_chain_id}]
                mock_table.select.return_value.eq.return_value.execute.return_value = mock_result
            else:
                mock_result = MagicMock()
                mock_result.data = steps
                mock_table.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/chains/{mock_chain_id}/steps")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 3
            assert data[0]["step_order"] == 0
            assert data[2]["step_order"] == 2


# ============ Tests: Get User Progress ============

class TestGetUserProgress:
    """Tests for GET /api/v1/skill-progressions/user/{user_id}/progress endpoint."""

    def test_get_user_progress_success(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test successfully fetching user's progress on all chains."""
        chain = generate_mock_chain(chain_id=mock_chain_id)
        progress = generate_mock_progress(mock_user_id, mock_chain_id, current_step_order=2)
        progress["skill_progression_chains"] = chain
        steps = [
            generate_mock_step(mock_chain_id, 2, "Knee Push-ups"),
            generate_mock_step(mock_chain_id, 3, "Full Push-ups"),
        ]

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_skill_progress":
                mock_result = MagicMock()
                mock_result.data = [progress]
                mock_table.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result
            else:
                mock_result = MagicMock()
                mock_result.data = steps
                mock_table.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/user/{mock_user_id}/progress")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 1
            assert data[0]["current_step_order"] == 2
            assert data[0]["chain"]["name"] == "Push-up Progression"

    def test_get_user_progress_empty(self, client, mock_supabase, mock_user_id):
        """Test fetching progress when user hasn't started any chains."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/user/{mock_user_id}/progress")

            assert response.status_code == 200
            assert response.json() == []


# ============ Tests: Start Chain ============

class TestStartChain:
    """Tests for POST /api/v1/skill-progressions/user/{user_id}/start-chain/{chain_id} endpoint."""

    def test_start_chain_success(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test successfully starting a new progression chain."""
        chain = generate_mock_chain(chain_id=mock_chain_id)
        first_step = generate_mock_step(mock_chain_id, 0, "Wall Push-ups")
        created_progress = generate_mock_progress(mock_user_id, mock_chain_id, current_step_order=0)

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "skill_progression_chains":
                mock_result = MagicMock()
                mock_result.data = [chain]
                mock_table.select.return_value.eq.return_value.execute.return_value = mock_result
            elif table_name == "user_skill_progress":
                # For checking existing
                mock_check = MagicMock()
                mock_check.data = []
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_check
                # For insert
                mock_insert = MagicMock()
                mock_insert.data = [created_progress]
                mock_table.insert.return_value.execute.return_value = mock_insert
            elif table_name == "skill_progression_steps":
                mock_result = MagicMock()
                mock_result.data = [first_step]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.skill_progressions.log_user_activity", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/skill-progressions/user/{mock_user_id}/start-chain/{mock_chain_id}"
                )

                assert response.status_code == 200
                data = response.json()
                assert data["success"] is True
                assert "Push-up Progression" in data["message"]
                assert data["first_step"]["exercise_name"] == "Wall Push-ups"

    def test_start_chain_already_started(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test starting a chain that user already started."""
        chain = generate_mock_chain(chain_id=mock_chain_id)
        existing_progress = generate_mock_progress(mock_user_id, mock_chain_id)

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "skill_progression_chains":
                mock_result = MagicMock()
                mock_result.data = [chain]
                mock_table.select.return_value.eq.return_value.execute.return_value = mock_result
            elif table_name == "user_skill_progress":
                mock_result = MagicMock()
                mock_result.data = [existing_progress]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.post(
                f"/api/v1/skill-progressions/user/{mock_user_id}/start-chain/{mock_chain_id}"
            )

            assert response.status_code == 400
            assert "already started" in response.json()["detail"]

    def test_start_chain_not_found(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test starting a non-existent chain."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.post(
                f"/api/v1/skill-progressions/user/{mock_user_id}/start-chain/{mock_chain_id}"
            )

            assert response.status_code == 404


# ============ Tests: Log Attempt ============

class TestLogAttempt:
    """Tests for POST /api/v1/skill-progressions/user/{user_id}/progress/{chain_id}/log-attempt endpoint."""

    def test_log_attempt_success(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test successfully logging an attempt."""
        progress = generate_mock_progress(mock_user_id, mock_chain_id, best_reps=10)
        current_step = generate_mock_step(mock_chain_id, 0, "Wall Push-ups")
        current_step["unlock_criteria"]["min_reps"] = 15

        updated_progress = progress.copy()
        updated_progress["attempts_at_current"] = 6
        updated_progress["best_reps_at_current"] = 12

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_skill_progress":
                mock_select = MagicMock()
                mock_select.data = [progress]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_select
                mock_update = MagicMock()
                mock_update.data = [updated_progress]
                mock_table.update.return_value.eq.return_value.execute.return_value = mock_update
            elif table_name == "skill_progression_steps":
                mock_result = MagicMock()
                mock_result.data = [current_step]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result
            elif table_name == "skill_attempt_logs":
                mock_insert = MagicMock()
                mock_insert.data = [generate_mock_attempt(mock_user_id, mock_chain_id)]
                mock_table.insert.return_value.execute.return_value = mock_insert
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.post(
                f"/api/v1/skill-progressions/user/{mock_user_id}/progress/{mock_chain_id}/log-attempt",
                json={"reps": 12, "sets": 3, "success": True}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert data["is_new_best"] is True

    def test_log_attempt_meets_criteria(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test logging an attempt that meets unlock criteria."""
        progress = generate_mock_progress(mock_user_id, mock_chain_id, best_reps=10)
        current_step = generate_mock_step(mock_chain_id, 0, "Wall Push-ups")
        current_step["unlock_criteria"]["min_reps"] = 15
        next_step = generate_mock_step(mock_chain_id, 1, "Incline Push-ups")

        updated_progress = progress.copy()
        updated_progress["best_reps_at_current"] = 16

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_skill_progress":
                mock_select = MagicMock()
                mock_select.data = [progress]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_select
                mock_update = MagicMock()
                mock_update.data = [updated_progress]
                mock_table.update.return_value.eq.return_value.execute.return_value = mock_update
            elif table_name == "skill_progression_steps":
                def step_eq_side_effect(field, value):
                    mock_eq = MagicMock()
                    if value == 0:
                        mock_eq.execute.return_value = MagicMock(data=[current_step])
                    else:
                        mock_eq.execute.return_value = MagicMock(data=[next_step])
                    return mock_eq

                mock_table.select.return_value.eq.return_value.eq.side_effect = step_eq_side_effect
            elif table_name == "skill_attempt_logs":
                mock_table.insert.return_value.execute.return_value = MagicMock(data=[])
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.post(
                f"/api/v1/skill-progressions/user/{mock_user_id}/progress/{mock_chain_id}/log-attempt",
                json={"reps": 16, "sets": 3, "success": True}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["unlock_criteria_met"] is True
            assert data["can_unlock_next"] is True


# ============ Tests: Unlock Next Step ============

class TestUnlockNextStep:
    """Tests for POST /api/v1/skill-progressions/user/{user_id}/progress/{chain_id}/unlock-next endpoint."""

    def test_unlock_next_step_success(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test successfully unlocking the next step."""
        progress = generate_mock_progress(mock_user_id, mock_chain_id, best_reps=20, current_step_order=0)
        current_step = generate_mock_step(mock_chain_id, 0, "Wall Push-ups")
        current_step["unlock_criteria"]["min_reps"] = 15
        next_step = generate_mock_step(mock_chain_id, 1, "Incline Push-ups")

        updated_progress = progress.copy()
        updated_progress["current_step_order"] = 1
        updated_progress["unlocked_steps"] = [0, 1]
        updated_progress["best_reps_at_current"] = 0

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_skill_progress":
                mock_select = MagicMock()
                mock_select.data = [progress]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_select
                mock_update = MagicMock()
                mock_update.data = [updated_progress]
                mock_table.update.return_value.eq.return_value.execute.return_value = mock_update
            elif table_name == "skill_progression_steps":
                def step_eq_side_effect(field, value):
                    mock_eq = MagicMock()
                    if value == 0:
                        mock_eq.execute.return_value = MagicMock(data=[current_step])
                    else:
                        mock_eq.execute.return_value = MagicMock(data=[next_step])
                    return mock_eq

                mock_table.select.return_value.eq.return_value.eq.side_effect = step_eq_side_effect
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.skill_progressions.log_user_activity", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/skill-progressions/user/{mock_user_id}/progress/{mock_chain_id}/unlock-next"
                )

                assert response.status_code == 200
                data = response.json()
                assert data["success"] is True
                assert "Incline Push-ups" in data["message"]
                assert data["unlocked_step"]["exercise_name"] == "Incline Push-ups"
                assert data["is_chain_completed"] is False

    def test_unlock_next_criteria_not_met(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test unlocking when criteria not met."""
        progress = generate_mock_progress(mock_user_id, mock_chain_id, best_reps=10, current_step_order=0)
        current_step = generate_mock_step(mock_chain_id, 0, "Wall Push-ups")
        current_step["unlock_criteria"]["min_reps"] = 15

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_skill_progress":
                mock_select = MagicMock()
                mock_select.data = [progress]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_select
            elif table_name == "skill_progression_steps":
                mock_result = MagicMock()
                mock_result.data = [current_step]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.post(
                f"/api/v1/skill-progressions/user/{mock_user_id}/progress/{mock_chain_id}/unlock-next"
            )

            assert response.status_code == 400
            assert "criteria not met" in response.json()["detail"]

    def test_unlock_completes_chain(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test unlocking when at last step completes the chain."""
        progress = generate_mock_progress(mock_user_id, mock_chain_id, best_reps=20, current_step_order=4)
        current_step = generate_mock_step(mock_chain_id, 4, "Diamond Push-ups", "advanced")
        current_step["unlock_criteria"]["min_reps"] = 15

        updated_progress = progress.copy()
        updated_progress["is_completed"] = True
        updated_progress["completed_at"] = datetime.now().isoformat()

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_skill_progress":
                mock_select = MagicMock()
                mock_select.data = [progress]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_select
                mock_update = MagicMock()
                mock_update.data = [updated_progress]
                mock_table.update.return_value.eq.return_value.execute.return_value = mock_update
            elif table_name == "skill_progression_steps":
                def step_eq_side_effect(field, value):
                    mock_eq = MagicMock()
                    if value == 4:
                        mock_eq.execute.return_value = MagicMock(data=[current_step])
                    else:
                        # No next step - chain completed
                        mock_eq.execute.return_value = MagicMock(data=[])
                    return mock_eq

                mock_table.select.return_value.eq.return_value.eq.side_effect = step_eq_side_effect
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.skill_progressions.log_user_activity", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/skill-progressions/user/{mock_user_id}/progress/{mock_chain_id}/unlock-next"
                )

                assert response.status_code == 200
                data = response.json()
                assert data["success"] is True
                assert "completed" in data["message"].lower()
                assert data["is_chain_completed"] is True


# ============ Tests: User Skills Summary ============

class TestGetUserSummary:
    """Tests for GET /api/v1/skill-progressions/user/{user_id}/summary endpoint."""

    def test_get_summary_success(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test successfully fetching user skills summary."""
        chain = generate_mock_chain(chain_id=mock_chain_id, total_steps=5)
        progress = generate_mock_progress(mock_user_id, mock_chain_id, current_step_order=2)
        progress["skill_progression_chains"] = chain

        all_chains = [
            generate_mock_chain(name="Push-up Progression"),
            generate_mock_chain(name="Pull-up Progression"),
        ]

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_skill_progress":
                mock_result = MagicMock()
                mock_result.data = [progress]
                mock_table.select.return_value.eq.return_value.execute.return_value = mock_result
            elif table_name == "skill_progression_steps":
                mock_result = MagicMock()
                mock_result.data = [{"exercise_name": "Knee Push-ups"}]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result
            elif table_name == "skill_progression_chains":
                mock_result = MagicMock()
                mock_result.data = all_chains
                mock_table.select.return_value.execute.return_value = mock_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/skill-progressions/user/{mock_user_id}/summary")

            assert response.status_code == 200
            data = response.json()
            assert data["total_chains_started"] == 1
            assert len(data["active_progressions"]) == 1
            assert data["active_progressions"][0]["current_step_name"] == "Knee Push-ups"


# ============ Tests: Delete Progress ============

class TestDeleteProgress:
    """Tests for DELETE /api/v1/skill-progressions/user/{user_id}/progress/{chain_id} endpoint."""

    def test_delete_progress_success(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test successfully deleting progress."""
        progress = generate_mock_progress(mock_user_id, mock_chain_id)

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "skill_attempt_logs":
                mock_table.delete.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(data=[])
            elif table_name == "user_skill_progress":
                mock_result = MagicMock()
                mock_result.data = [progress]
                mock_table.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.skill_progressions.log_user_activity", new_callable=AsyncMock):
                response = client.delete(
                    f"/api/v1/skill-progressions/user/{mock_user_id}/progress/{mock_chain_id}"
                )

                assert response.status_code == 200
                assert response.json()["success"] is True


# ============ Tests: Toggle Active ============

class TestToggleActive:
    """Tests for PUT /api/v1/skill-progressions/user/{user_id}/progress/{chain_id}/toggle-active endpoint."""

    def test_toggle_active_success(self, client, mock_supabase, mock_user_id, mock_chain_id):
        """Test successfully toggling active status."""
        progress = generate_mock_progress(mock_user_id, mock_chain_id)
        updated_progress = progress.copy()
        updated_progress["is_active"] = False

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_skill_progress":
                mock_select = MagicMock()
                mock_select.data = [progress]
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_select
                mock_update = MagicMock()
                mock_update.data = [updated_progress]
                mock_table.update.return_value.eq.return_value.execute.return_value = mock_update
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.skill_progressions.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.put(
                f"/api/v1/skill-progressions/user/{mock_user_id}/progress/{mock_chain_id}/toggle-active?is_active=false"
            )

            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert "paused" in data["message"]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
