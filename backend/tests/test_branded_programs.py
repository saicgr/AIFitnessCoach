"""
Tests for Branded Programs and User Program Assignments API.

Tests the following endpoints:
- GET  /api/v1/programs/branded - List all branded programs
- GET  /api/v1/programs/branded/{program_id} - Get single branded program details
- POST /api/v1/programs/assign/{user_id} - Assign a program to user
- GET  /api/v1/programs/user/{user_id}/current - Get user's current active program
- GET  /api/v1/programs/user/{user_id}/history - Get user's program history
- PATCH /api/v1/programs/user/{user_id}/rename - Rename current program
- PATCH /api/v1/programs/user/{user_id}/complete - Mark program as completed
- GET  /api/v1/programs/featured - Get featured programs for home screen
- GET  /api/v1/programs/categories - List all categories

Run with: pytest tests/test_branded_programs.py -v
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime
from fastapi.testclient import TestClient
import uuid

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


# ============ Mock Data Generators ============

def generate_mock_branded_program(
    program_id: str = None,
    name: str = "Test Program",
    category: str = "strength",
    difficulty: str = "intermediate",
    is_featured: bool = False,
    is_premium: bool = False,
    popularity_score: int = 100,
):
    """Generate a mock branded program."""
    return {
        "id": program_id or str(uuid.uuid4()),
        "name": name,
        "description": f"{name} is a comprehensive workout program.",
        "category": category,
        "subcategory": "general",
        "difficulty": difficulty,
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "equipment_required": ["dumbbells", "barbell"],
        "goals": ["Build Muscle", "Build Strength"],
        "tags": ["strength", "muscle"],
        "image_url": "https://example.com/image.jpg",
        "thumbnail_url": "https://example.com/thumb.jpg",
        "is_featured": is_featured,
        "is_premium": is_premium,
        "popularity_score": popularity_score,
        "workouts": {
            "weekly_structure": [
                {"day": 1, "workout_name": "Day 1", "exercises": []},
                {"day": 2, "workout_name": "Day 2", "exercises": []},
            ]
        },
        "overview": "Program overview here.",
        "author": "Test Author",
        "source_url": None,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    }


def generate_mock_user_assignment(
    user_id: str,
    assignment_id: str = None,
    branded_program_id: str = None,
    custom_program_name: str = None,
    program_name: str = "My Program",
    is_active: bool = True,
    week_number: int = 1,
    completed_at: str = None,
):
    """Generate a mock user program assignment."""
    now = datetime.utcnow().isoformat()
    return {
        "id": assignment_id or str(uuid.uuid4()),
        "user_id": user_id,
        "branded_program_id": branded_program_id,
        "custom_program_name": custom_program_name,
        "program_name": program_name,
        "started_at": now,
        "completed_at": completed_at,
        "is_active": is_active,
        "week_number": week_number,
        "created_at": now,
        "updated_at": now,
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
def mock_program_id():
    """Generate a mock program ID."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client with chained methods."""
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
    mock_select.range.return_value = mock_select
    mock_select.single.return_value = mock_select

    # Mock insert chain
    mock_insert = MagicMock()
    mock_table.insert.return_value = mock_insert

    # Mock update chain
    mock_update = MagicMock()
    mock_table.update.return_value = mock_update
    mock_update.eq.return_value = mock_update

    # Mock RPC
    mock_rpc = MagicMock()
    mock.rpc.return_value = mock_rpc

    return mock


# ============ Tests: Get Branded Programs ============

class TestGetBrandedPrograms:
    """Tests for GET /api/v1/programs/branded endpoint."""

    def test_get_branded_programs(self, client, mock_supabase):
        """Test listing all branded programs."""
        programs = [
            generate_mock_branded_program(name="Program 1", popularity_score=200),
            generate_mock_branded_program(name="Program 2", popularity_score=100),
        ]

        mock_result = MagicMock()
        mock_result.data = programs
        mock_supabase.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get("/api/v1/programs/branded")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 2
            assert data[0]["name"] == "Program 1"

    def test_get_branded_programs_with_filters(self, client, mock_supabase):
        """Test category/difficulty filtering for branded programs."""
        programs = [
            generate_mock_branded_program(
                name="Strength Program",
                category="strength",
                difficulty="advanced"
            ),
        ]

        mock_result = MagicMock()
        mock_result.data = programs
        # Chain: select -> eq (category) -> eq (difficulty) -> order -> range -> execute
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(
                "/api/v1/programs/branded",
                params={"category": "strength", "difficulty": "advanced"}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 1
            assert data[0]["category"] == "strength"
            assert data[0]["difficulty"] == "advanced"

    def test_get_branded_programs_empty(self, client, mock_supabase):
        """Test listing branded programs when none exist."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get("/api/v1/programs/branded")

            assert response.status_code == 200
            assert response.json() == []


# ============ Tests: Get Featured Programs ============

class TestGetFeaturedPrograms:
    """Tests for GET /api/v1/programs/featured endpoint."""

    def test_get_featured_programs(self, client, mock_supabase):
        """Test getting featured programs for home screen."""
        featured_programs = [
            generate_mock_branded_program(name="Featured 1", is_featured=True),
            generate_mock_branded_program(name="Featured 2", is_featured=True),
        ]
        popular_programs = [
            generate_mock_branded_program(name="Popular 1", popularity_score=500),
        ]
        new_programs = [
            generate_mock_branded_program(name="New Release 1"),
        ]

        # Setup mock returns for the three queries
        mock_featured_result = MagicMock()
        mock_featured_result.data = featured_programs

        mock_popular_result = MagicMock()
        mock_popular_result.data = popular_programs

        mock_new_result = MagicMock()
        mock_new_result.data = new_programs

        # The endpoint makes 3 separate queries
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_featured_result
        mock_supabase.table.return_value.select.return_value.order.return_value.limit.return_value.execute.return_value = mock_popular_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get("/api/v1/programs/featured")

            assert response.status_code == 200
            data = response.json()
            assert "featured" in data
            assert "popular" in data
            assert "new_releases" in data


# ============ Tests: Get Single Program ============

class TestGetSingleProgram:
    """Tests for GET /api/v1/programs/branded/{program_id} endpoint."""

    def test_get_single_program(self, client, mock_supabase, mock_program_id):
        """Test getting a single branded program by ID."""
        program = generate_mock_branded_program(
            program_id=mock_program_id,
            name="Ultimate Strength Builder"
        )

        mock_result = MagicMock()
        mock_result.data = program
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(f"/api/v1/programs/branded/{mock_program_id}")

            assert response.status_code == 200
            data = response.json()
            assert data["id"] == mock_program_id
            assert data["name"] == "Ultimate Strength Builder"

    def test_get_nonexistent_program(self, client, mock_supabase, mock_program_id):
        """Test 404 for invalid/nonexistent program ID."""
        mock_result = MagicMock()
        mock_result.data = None
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(f"/api/v1/programs/branded/{mock_program_id}")

            assert response.status_code == 404
            assert "not found" in response.json()["detail"].lower()


# ============ Tests: Assign Branded Program ============

class TestAssignBrandedProgram:
    """Tests for POST /api/v1/programs/assign/{user_id} endpoint."""

    def test_assign_branded_program(self, client, mock_supabase, mock_user_id, mock_program_id):
        """Test assigning a branded program to user."""
        branded_program = {"id": mock_program_id, "name": "Ultimate Strength Builder"}
        assignment = generate_mock_user_assignment(
            user_id=mock_user_id,
            branded_program_id=mock_program_id,
            program_name="Ultimate Strength Builder",
        )

        # Mock user exists check
        mock_user_result = MagicMock()
        mock_user_result.data = {"id": mock_user_id}

        # Mock branded program fetch
        mock_program_result = MagicMock()
        mock_program_result.data = branded_program

        # Mock deactivate existing programs (update)
        mock_deactivate = MagicMock()

        # Mock insert new assignment
        mock_insert_result = MagicMock()
        mock_insert_result.data = [assignment]

        # Mock RPC for increment popularity
        mock_rpc = MagicMock()
        mock_rpc.execute.return_value = MagicMock()
        mock_supabase.rpc.return_value = mock_rpc

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            # Setup the chain of calls
            mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                mock_user_result,
                mock_program_result,
            ]
            mock_supabase.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value = mock_deactivate
            mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_insert_result

            with patch("api.v1.programs.user_context_service.log_event", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/programs/assign/{mock_user_id}",
                    json={"branded_program_id": mock_program_id}
                )

                assert response.status_code == 200
                data = response.json()
                assert data["user_id"] == mock_user_id
                assert data["branded_program_id"] == mock_program_id
                assert data["program_name"] == "Ultimate Strength Builder"
                assert data["is_active"] is True

    def test_assign_custom_program(self, client, mock_supabase, mock_user_id):
        """Test assigning a program with custom name only (no branded program)."""
        custom_name = "My Custom Training Plan"
        assignment = generate_mock_user_assignment(
            user_id=mock_user_id,
            custom_program_name=custom_name,
            program_name=custom_name,
        )

        # Mock user exists check
        mock_user_result = MagicMock()
        mock_user_result.data = {"id": mock_user_id}

        # Mock deactivate existing programs
        mock_deactivate = MagicMock()

        # Mock insert new assignment
        mock_insert_result = MagicMock()
        mock_insert_result.data = [assignment]

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_user_result
            mock_supabase.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value = mock_deactivate
            mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_insert_result

            with patch("api.v1.programs.user_context_service.log_event", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/programs/assign/{mock_user_id}",
                    json={"custom_program_name": custom_name}
                )

                assert response.status_code == 200
                data = response.json()
                assert data["program_name"] == custom_name
                assert data["custom_program_name"] == custom_name
                assert data["branded_program_id"] is None

    def test_assign_program_with_custom_name(self, client, mock_supabase, mock_user_id, mock_program_id):
        """Test assigning branded program with a custom name override."""
        branded_program = {"id": mock_program_id, "name": "Ultimate Strength Builder"}
        custom_name = "My Strength Journey"
        assignment = generate_mock_user_assignment(
            user_id=mock_user_id,
            branded_program_id=mock_program_id,
            custom_program_name=custom_name,
            program_name=custom_name,
        )

        # Mock user exists check
        mock_user_result = MagicMock()
        mock_user_result.data = {"id": mock_user_id}

        # Mock branded program fetch
        mock_program_result = MagicMock()
        mock_program_result.data = branded_program

        # Mock deactivate existing programs
        mock_deactivate = MagicMock()

        # Mock insert new assignment
        mock_insert_result = MagicMock()
        mock_insert_result.data = [assignment]

        # Mock RPC for increment popularity
        mock_rpc = MagicMock()
        mock_rpc.execute.return_value = MagicMock()
        mock_supabase.rpc.return_value = mock_rpc

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                mock_user_result,
                mock_program_result,
            ]
            mock_supabase.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value = mock_deactivate
            mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_insert_result

            with patch("api.v1.programs.user_context_service.log_event", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/programs/assign/{mock_user_id}",
                    json={
                        "branded_program_id": mock_program_id,
                        "custom_program_name": custom_name
                    }
                )

                assert response.status_code == 200
                data = response.json()
                assert data["program_name"] == custom_name
                assert data["branded_program_id"] == mock_program_id
                assert data["custom_program_name"] == custom_name

    def test_assign_program_missing_params(self, client, mock_user_id):
        """Test assigning program without required parameters returns 400."""
        response = client.post(
            f"/api/v1/programs/assign/{mock_user_id}",
            json={}
        )

        assert response.status_code == 400
        assert "branded_program_id or custom_program_name" in response.json()["detail"].lower()


# ============ Tests: Get Current Program ============

class TestGetCurrentProgram:
    """Tests for GET /api/v1/programs/user/{user_id}/current endpoint."""

    def test_get_current_program(self, client, mock_supabase, mock_user_id):
        """Test getting user's active program."""
        assignment = generate_mock_user_assignment(
            user_id=mock_user_id,
            program_name="My Active Program",
            is_active=True,
            week_number=3,
        )

        mock_result = MagicMock()
        mock_result.data = assignment
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(f"/api/v1/programs/user/{mock_user_id}/current")

            assert response.status_code == 200
            data = response.json()
            assert data["user_id"] == mock_user_id
            assert data["program_name"] == "My Active Program"
            assert data["is_active"] is True
            assert data["week_number"] == 3

    def test_get_current_program_none(self, client, mock_supabase, mock_user_id):
        """Test getting current program when none exists."""
        mock_result = MagicMock()
        mock_result.data = None

        # Mock to raise an exception for "no rows" case
        def raise_no_rows(*args, **kwargs):
            raise Exception("0 rows returned")

        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.side_effect = raise_no_rows

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(f"/api/v1/programs/user/{mock_user_id}/current")

            # Should return null/None, not error
            assert response.status_code == 200
            assert response.json() is None


# ============ Tests: Get Program History ============

class TestGetProgramHistory:
    """Tests for GET /api/v1/programs/user/{user_id}/history endpoint."""

    def test_get_program_history(self, client, mock_supabase, mock_user_id):
        """Test getting user's program history."""
        now = datetime.utcnow().isoformat()
        assignments = [
            generate_mock_user_assignment(
                user_id=mock_user_id,
                program_name="Current Program",
                is_active=True,
            ),
            generate_mock_user_assignment(
                user_id=mock_user_id,
                program_name="Old Program 1",
                is_active=False,
                completed_at=now,
            ),
            generate_mock_user_assignment(
                user_id=mock_user_id,
                program_name="Old Program 2",
                is_active=False,
                completed_at=now,
            ),
        ]

        mock_result = MagicMock()
        mock_result.data = assignments
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(f"/api/v1/programs/user/{mock_user_id}/history")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 3
            assert data[0]["program_name"] == "Current Program"

    def test_get_program_history_exclude_active(self, client, mock_supabase, mock_user_id):
        """Test getting program history excluding active programs."""
        now = datetime.utcnow().isoformat()
        assignments = [
            generate_mock_user_assignment(
                user_id=mock_user_id,
                program_name="Old Program 1",
                is_active=False,
                completed_at=now,
            ),
        ]

        mock_result = MagicMock()
        mock_result.data = assignments
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(
                f"/api/v1/programs/user/{mock_user_id}/history",
                params={"include_active": False}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 1
            assert data[0]["is_active"] is False

    def test_get_program_history_empty(self, client, mock_supabase, mock_user_id):
        """Test getting program history when none exists."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(f"/api/v1/programs/user/{mock_user_id}/history")

            assert response.status_code == 200
            assert response.json() == []


# ============ Tests: Rename Program ============

class TestRenameProgram:
    """Tests for PATCH /api/v1/programs/user/{user_id}/rename endpoint."""

    def test_rename_program(self, client, mock_supabase, mock_user_id):
        """Test renaming the current program."""
        old_name = "Original Name"
        new_name = "Renamed Program"
        assignment_id = str(uuid.uuid4())

        current_assignment = generate_mock_user_assignment(
            user_id=mock_user_id,
            assignment_id=assignment_id,
            program_name=old_name,
        )

        updated_assignment = generate_mock_user_assignment(
            user_id=mock_user_id,
            assignment_id=assignment_id,
            program_name=new_name,
            custom_program_name=new_name,
        )

        # Mock find current active program
        mock_current = MagicMock()
        mock_current.data = current_assignment

        # Mock update result
        mock_update = MagicMock()
        mock_update.data = [updated_assignment]

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = mock_current
            mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update

            with patch("api.v1.programs.user_context_service.log_event", new_callable=AsyncMock):
                response = client.patch(
                    f"/api/v1/programs/user/{mock_user_id}/rename",
                    json={"custom_program_name": new_name}
                )

                assert response.status_code == 200
                data = response.json()
                assert data["program_name"] == new_name
                assert data["custom_program_name"] == new_name

    def test_rename_program_no_active(self, client, mock_supabase, mock_user_id):
        """Test renaming when no active program exists."""
        mock_result = MagicMock()
        mock_result.data = None
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.patch(
                f"/api/v1/programs/user/{mock_user_id}/rename",
                json={"custom_program_name": "New Name"}
            )

            assert response.status_code == 404
            assert "no active program" in response.json()["detail"].lower()

    def test_rename_program_empty_name(self, client, mock_user_id):
        """Test renaming with empty name returns 400."""
        response = client.patch(
            f"/api/v1/programs/user/{mock_user_id}/rename",
            json={"custom_program_name": ""}
        )

        assert response.status_code == 400
        assert "cannot be empty" in response.json()["detail"].lower()


# ============ Tests: Complete Program ============

class TestCompleteProgram:
    """Tests for PATCH /api/v1/programs/user/{user_id}/complete endpoint."""

    def test_complete_program(self, client, mock_supabase, mock_user_id):
        """Test marking a program as completed."""
        assignment_id = str(uuid.uuid4())
        current_assignment = generate_mock_user_assignment(
            user_id=mock_user_id,
            assignment_id=assignment_id,
            program_name="Program to Complete",
            is_active=True,
        )

        now = datetime.utcnow().isoformat()
        completed_assignment = generate_mock_user_assignment(
            user_id=mock_user_id,
            assignment_id=assignment_id,
            program_name="Program to Complete",
            is_active=False,
            completed_at=now,
        )

        # Mock find current active program
        mock_current = MagicMock()
        mock_current.data = current_assignment

        # Mock update result
        mock_update = MagicMock()
        mock_update.data = [completed_assignment]

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = mock_current
            mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update

            with patch("api.v1.programs.user_context_service.log_event", new_callable=AsyncMock):
                response = client.patch(
                    f"/api/v1/programs/user/{mock_user_id}/complete"
                )

                assert response.status_code == 200
                data = response.json()
                assert data["is_active"] is False
                assert data["completed_at"] is not None

    def test_complete_program_no_active(self, client, mock_supabase, mock_user_id):
        """Test completing when no active program exists."""
        mock_result = MagicMock()
        mock_result.data = None
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.patch(
                f"/api/v1/programs/user/{mock_user_id}/complete"
            )

            assert response.status_code == 404
            assert "no active program" in response.json()["detail"].lower()


# ============ Tests: Get Categories ============

class TestGetCategories:
    """Tests for GET /api/v1/programs/categories endpoint."""

    def test_get_categories(self, client, mock_supabase):
        """Test listing all program categories."""
        category_data = [
            {"category": "strength"},
            {"category": "hypertrophy"},
            {"category": "weight_loss"},
            {"category": "athletic"},
            {"category": "strength"},  # duplicate to test dedup
        ]

        mock_result = MagicMock()
        mock_result.data = category_data
        mock_supabase.table.return_value.select.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get("/api/v1/programs/categories")

            assert response.status_code == 200
            data = response.json()
            # Should be deduplicated and sorted
            assert len(data) == 4
            assert "strength" in data
            assert "hypertrophy" in data
            assert data == sorted(data)  # Verify sorted

    def test_get_categories_empty(self, client, mock_supabase):
        """Test getting categories when no programs exist."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get("/api/v1/programs/categories")

            assert response.status_code == 200
            assert response.json() == []


# ============ Tests: Model Validation ============

class TestProgramModels:
    """Tests for program-related model validation."""

    def test_branded_program_required_fields(self):
        """Test BrandedProgram model has required fields."""
        from api.v1.programs import BrandedProgram

        program = BrandedProgram(
            id="test-id",
            name="Test Program",
        )

        assert program.id == "test-id"
        assert program.name == "Test Program"
        assert program.is_featured is False  # default
        assert program.is_premium is False  # default
        assert program.equipment_required == []  # default
        assert program.goals == []  # default
        assert program.tags == []  # default

    def test_program_assign_request_validation(self):
        """Test ProgramAssignRequest validation."""
        from api.v1.programs import ProgramAssignRequest

        # Valid with branded_program_id
        request1 = ProgramAssignRequest(branded_program_id="prog-123")
        assert request1.branded_program_id == "prog-123"
        assert request1.custom_program_name is None

        # Valid with custom_program_name
        request2 = ProgramAssignRequest(custom_program_name="My Custom Program")
        assert request2.branded_program_id is None
        assert request2.custom_program_name == "My Custom Program"

        # Valid with both
        request3 = ProgramAssignRequest(
            branded_program_id="prog-123",
            custom_program_name="Custom Name"
        )
        assert request3.branded_program_id == "prog-123"
        assert request3.custom_program_name == "Custom Name"

    def test_user_program_assignment_fields(self):
        """Test UserProgramAssignment model has all required fields."""
        from api.v1.programs import UserProgramAssignment

        now = datetime.utcnow().isoformat()
        assignment = UserProgramAssignment(
            id="assign-123",
            user_id="user-123",
            program_name="Test Program",
            started_at=now,
            created_at=now,
            updated_at=now,
        )

        assert assignment.id == "assign-123"
        assert assignment.user_id == "user-123"
        assert assignment.program_name == "Test Program"
        assert assignment.is_active is True  # default
        assert assignment.week_number == 1  # default
        assert assignment.branded_program_id is None
        assert assignment.custom_program_name is None
        assert assignment.completed_at is None


# ============ Tests: Edge Cases ============

class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_pagination_params(self, client, mock_supabase):
        """Test pagination parameters work correctly."""
        programs = [generate_mock_branded_program(name=f"Program {i}") for i in range(5)]

        mock_result = MagicMock()
        mock_result.data = programs
        mock_supabase.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(
                "/api/v1/programs/branded",
                params={"limit": 5, "offset": 10}
            )

            assert response.status_code == 200
            # Verify range was called with correct params
            mock_supabase.table.return_value.select.return_value.order.return_value.range.assert_called_with(10, 14)

    def test_featured_filter(self, client, mock_supabase):
        """Test is_featured filter works correctly."""
        programs = [generate_mock_branded_program(is_featured=True)]

        mock_result = MagicMock()
        mock_result.data = programs
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(
                "/api/v1/programs/branded",
                params={"is_featured": True}
            )

            assert response.status_code == 200
            assert len(response.json()) == 1
            assert response.json()[0]["is_featured"] is True

    def test_premium_filter(self, client, mock_supabase):
        """Test is_premium filter works correctly."""
        programs = [generate_mock_branded_program(is_premium=True)]

        mock_result = MagicMock()
        mock_result.data = programs
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        with patch("api.v1.programs.get_supabase") as mock_get_supabase:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_supabase.return_value = mock_db

            response = client.get(
                "/api/v1/programs/branded",
                params={"is_premium": True}
            )

            assert response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
