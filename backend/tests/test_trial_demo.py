"""
Tests for Demo and Trial API endpoints.

These tests verify the demo preview and trial functionality
that allows users to experience the app before signing up.

This addresses the complaint:
"One of those apps where you answer a bunch of questions to get a 'tailored plan',
but then hit a paywall to even see how the app works"
"""

import pytest
from httpx import AsyncClient
from datetime import datetime
import uuid


class TestDemoPreviewPlan:
    """Tests for the preview plan generation endpoint."""

    @pytest.mark.asyncio
    async def test_generate_preview_plan_basic(self, client: AsyncClient):
        """Test generating a basic preview plan."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["build_muscle"],
                "fitness_level": "intermediate",
                "equipment": ["dumbbells", "barbell"],
                "days_per_week": 3,
                "training_split": "push_pull_legs",
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert "session_id" in data
        assert "plan" in data
        assert data["plan"]["days_per_week"] == 3
        assert len(data["plan"]["workout_days"]) == 3

    @pytest.mark.asyncio
    async def test_generate_preview_plan_with_session_id(self, client: AsyncClient):
        """Test that provided session_id is used."""
        session_id = str(uuid.uuid4())

        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["lose_weight"],
                "fitness_level": "beginner",
                "equipment": ["bodyweight"],
                "days_per_week": 2,
                "session_id": session_id,
            }
        )

        assert response.status_code == 200
        assert response.json()["session_id"] == session_id

    @pytest.mark.asyncio
    async def test_generate_preview_plan_exercises_not_empty(self, client: AsyncClient):
        """Test that exercises are returned for each day."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["increase_strength"],
                "fitness_level": "advanced",
                "equipment": ["dumbbells", "barbell", "cable_machine"],
                "days_per_week": 4,
            }
        )

        assert response.status_code == 200
        data = response.json()

        for day in data["plan"]["workout_days"]:
            assert "exercises" in day
            assert len(day["exercises"]) > 0

            for exercise in day["exercises"]:
                assert "name" in exercise
                assert "sets" in exercise
                assert "reps" in exercise

    @pytest.mark.asyncio
    async def test_generate_preview_plan_different_splits(self, client: AsyncClient):
        """Test plan generation with different training splits."""
        splits = ["push_pull_legs", "upper_lower", "full_body"]

        for split in splits:
            response = await client.post(
                "/api/v1/demo/generate-preview-plan",
                json={
                    "goals": ["build_muscle"],
                    "fitness_level": "intermediate",
                    "equipment": ["dumbbells"],
                    "days_per_week": 3,
                    "training_split": split,
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["plan"]["training_split"] == split

    @pytest.mark.asyncio
    async def test_generate_preview_plan_includes_personalization(self, client: AsyncClient):
        """Test that personalization info is included."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["build_muscle"],
                "fitness_level": "beginner",
                "equipment": ["dumbbells", "barbell"],
                "days_per_week": 3,
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert "personalization" in data
        assert data["personalization"]["goal_match"] is True
        assert data["personalization"]["fitness_level"] == "beginner"
        assert "total_exercises" in data["personalization"]

    @pytest.mark.asyncio
    async def test_generate_preview_plan_includes_social_proof(self, client: AsyncClient):
        """Test that social proof is included."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["lose_weight"],
                "fitness_level": "intermediate",
                "equipment": ["bodyweight"],
                "days_per_week": 4,
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert "social_proof" in data
        assert "similar_users" in data["social_proof"]
        assert "success_rate" in data["social_proof"]


class TestDemoSession:
    """Tests for demo session management."""

    @pytest.mark.asyncio
    async def test_start_new_session(self, client: AsyncClient):
        """Test starting a new demo session."""
        response = await client.post(
            "/api/v1/demo/session/start",
            json={
                "quiz_data": {"goal": "build_muscle"},
                "device_info": {"platform": "ios", "version": "1.0.0"},
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert "session_id" in data
        assert data["status"] in ["active", "resumed"]

    @pytest.mark.asyncio
    async def test_resume_existing_session(self, client: AsyncClient):
        """Test resuming an existing session."""
        # Start session
        start_response = await client.post(
            "/api/v1/demo/session/start",
            json={"quiz_data": {"goal": "lose_weight"}}
        )
        session_id = start_response.json()["session_id"]

        # Resume with more data
        resume_response = await client.post(
            "/api/v1/demo/session/start",
            json={
                "session_id": session_id,
                "quiz_data": {"goal": "lose_weight", "level": "beginner"},
            }
        )

        assert resume_response.status_code == 200
        assert resume_response.json()["session_id"] == session_id

    @pytest.mark.asyncio
    async def test_get_session_details(self, client: AsyncClient):
        """Test getting session details."""
        # Start session
        start_response = await client.post(
            "/api/v1/demo/session/start",
            json={"quiz_data": {"goal": "build_muscle"}}
        )
        session_id = start_response.json()["session_id"]

        # Get session
        get_response = await client.get(f"/api/v1/demo/session/{session_id}")

        assert get_response.status_code == 200
        data = get_response.json()
        assert "session" in data
        assert data["session"]["session_id"] == session_id


class TestDemoInteractions:
    """Tests for demo interaction logging."""

    @pytest.mark.asyncio
    async def test_log_screen_view(self, client: AsyncClient):
        """Test logging a screen view."""
        response = await client.post(
            "/api/v1/demo/interaction",
            json={
                "session_id": str(uuid.uuid4()),
                "action_type": "screen_view",
                "screen": "exercise_library",
                "duration_seconds": 30,
            }
        )

        assert response.status_code == 200
        assert response.json()["status"] == "logged"

    @pytest.mark.asyncio
    async def test_log_feature_tap(self, client: AsyncClient):
        """Test logging a feature tap."""
        response = await client.post(
            "/api/v1/demo/interaction",
            json={
                "session_id": str(uuid.uuid4()),
                "action_type": "feature_tap",
                "feature": "ai_coach_chat",
                "metadata": {"was_locked": True},
            }
        )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_log_workout_preview(self, client: AsyncClient):
        """Test logging a workout preview."""
        response = await client.post(
            "/api/v1/demo/interaction",
            json={
                "session_id": str(uuid.uuid4()),
                "action_type": "workout_preview",
                "screen": "personalized_preview",
                "metadata": {"workout_day": 1, "exercises_viewed": 5},
            }
        )

        assert response.status_code == 200


class TestSampleWorkouts:
    """Tests for sample workout retrieval."""

    @pytest.mark.asyncio
    async def test_get_sample_workouts(self, client: AsyncClient):
        """Test getting sample workouts."""
        response = await client.get("/api/v1/demo/sample-workouts")

        assert response.status_code == 200
        data = response.json()

        assert "workouts" in data
        assert len(data["workouts"]) >= 3

        for workout in data["workouts"]:
            assert "id" in workout
            assert "name" in workout
            assert "exercises" in workout
            assert len(workout["exercises"]) > 0

    @pytest.mark.asyncio
    async def test_get_sample_workouts_with_level(self, client: AsyncClient):
        """Test getting sample workouts filtered by level."""
        response = await client.get(
            "/api/v1/demo/sample-workouts",
            params={"fitness_level": "beginner"}
        )

        assert response.status_code == 200
        data = response.json()
        assert "workouts" in data

    @pytest.mark.asyncio
    async def test_sample_workouts_include_count(self, client: AsyncClient):
        """Test that sample workouts include total count."""
        response = await client.get("/api/v1/demo/sample-workouts")

        assert response.status_code == 200
        data = response.json()
        assert "total_available" in data
        assert data["total_available"] > 1000  # We have 1700+ exercises


class TestSessionConversion:
    """Tests for session conversion tracking."""

    @pytest.mark.asyncio
    async def test_convert_session(self, client: AsyncClient):
        """Test converting a demo session to a user."""
        # Start session
        start_response = await client.post(
            "/api/v1/demo/session/start",
            json={"quiz_data": {"goal": "build_muscle"}}
        )
        session_id = start_response.json()["session_id"]

        # Convert session
        user_id = str(uuid.uuid4())
        convert_response = await client.post(
            "/api/v1/demo/session/convert",
            json={
                "session_id": session_id,
                "user_id": user_id,
                "trigger": "paywall_skip",
            }
        )

        assert convert_response.status_code == 200
        assert convert_response.json()["status"] == "converted"

    @pytest.mark.asyncio
    async def test_convert_session_records_duration(self, client: AsyncClient):
        """Test that conversion records session duration."""
        # Start session
        start_response = await client.post(
            "/api/v1/demo/session/start",
            json={"quiz_data": {"goal": "build_muscle"}}
        )
        session_id = start_response.json()["session_id"]

        # Log some interactions to simulate time passing
        await client.post(
            "/api/v1/demo/interaction",
            json={
                "session_id": session_id,
                "action_type": "screen_view",
                "screen": "home",
                "duration_seconds": 60,
            }
        )

        # Convert session
        user_id = str(uuid.uuid4())
        convert_response = await client.post(
            "/api/v1/demo/session/convert",
            json={
                "session_id": session_id,
                "user_id": user_id,
                "trigger": "sign_up_button",
            }
        )

        assert convert_response.status_code == 200
        # Duration should be calculated
        assert "session_duration_seconds" in convert_response.json()


class TestConversionAnalytics:
    """Tests for conversion analytics endpoints."""

    @pytest.mark.asyncio
    async def test_get_conversion_analytics(self, client: AsyncClient):
        """Test getting conversion analytics."""
        response = await client.get("/api/v1/demo/analytics/conversion")

        assert response.status_code == 200
        data = response.json()
        assert "period_days" in data
        assert "funnel_data" in data

    @pytest.mark.asyncio
    async def test_get_feature_analytics(self, client: AsyncClient):
        """Test getting feature engagement analytics."""
        response = await client.get("/api/v1/demo/analytics/features")

        assert response.status_code == 200
        data = response.json()
        assert "features" in data
