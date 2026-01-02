"""
Tests for Enhanced Demo Preview and Try Workout functionality.

These tests verify the new demo system that allows users to:
1. Preview their personalized workout plan without authentication
2. Get specific day workouts from the preview
3. Try one workout before subscribing
4. Track which exercises/workouts were previewed

This directly addresses the complaint:
"One of those apps where you answer a bunch of questions to get a 'tailored plan',
but then hit a paywall to even see how the app works"
"""

import pytest
from httpx import AsyncClient
from datetime import datetime
import uuid


class TestPreviewWorkoutDay:
    """Tests for the GET /api/v1/demo/preview-workout/{day} endpoint."""

    @pytest.mark.asyncio
    async def test_get_preview_workout_day_1(self, client: AsyncClient):
        """Test getting day 1 workout from preview."""
        response = await client.get(
            "/api/v1/demo/preview-workout/1",
            params={"fitness_level": "intermediate"}
        )

        assert response.status_code == 200
        data = response.json()

        assert "workout" in data
        workout = data["workout"]
        assert workout["day"] == 1
        assert "name" in workout
        assert "exercises" in workout
        assert len(workout["exercises"]) > 0

        # Check exercise details
        for exercise in workout["exercises"]:
            assert "name" in exercise
            assert "sets" in exercise
            assert "reps" in exercise
            assert "instructions" in exercise
            assert "rest_seconds" in exercise

        # Check preview info
        assert "preview_info" in data
        assert data["preview_info"]["is_preview"] is True
        assert "full_access_features" in data["preview_info"]
        assert "cta" in data["preview_info"]

    @pytest.mark.asyncio
    async def test_get_preview_workout_day_3(self, client: AsyncClient):
        """Test getting day 3 workout (should be different from day 1)."""
        day1_response = await client.get("/api/v1/demo/preview-workout/1")
        day3_response = await client.get("/api/v1/demo/preview-workout/3")

        assert day1_response.status_code == 200
        assert day3_response.status_code == 200

        day1_workout = day1_response.json()["workout"]
        day3_workout = day3_response.json()["workout"]

        # Different days should have different focus
        assert day1_workout["name"] != day3_workout["name"]

    @pytest.mark.asyncio
    async def test_get_preview_workout_invalid_day(self, client: AsyncClient):
        """Test that invalid day numbers are rejected."""
        # Day 0
        response = await client.get("/api/v1/demo/preview-workout/0")
        assert response.status_code == 400

        # Day 8
        response = await client.get("/api/v1/demo/preview-workout/8")
        assert response.status_code == 400

        # Negative day
        response = await client.get("/api/v1/demo/preview-workout/-1")
        assert response.status_code in [400, 422]

    @pytest.mark.asyncio
    async def test_get_preview_workout_with_session_tracking(self, client: AsyncClient):
        """Test that session_id enables interaction tracking."""
        session_id = str(uuid.uuid4())

        response = await client.get(
            "/api/v1/demo/preview-workout/2",
            params={"session_id": session_id}
        )

        assert response.status_code == 200

        # The preview should be logged, verify via the previewed exercises endpoint
        previewed_response = await client.get(
            f"/api/v1/demo/exercises-previewed/{session_id}"
        )

        assert previewed_response.status_code == 200
        # May have interactions if DB is available
        data = previewed_response.json()
        assert "session_id" in data
        assert data["session_id"] == session_id

    @pytest.mark.asyncio
    async def test_get_preview_workout_different_fitness_levels(self, client: AsyncClient):
        """Test that fitness levels affect workout parameters."""
        beginner = await client.get(
            "/api/v1/demo/preview-workout/1",
            params={"fitness_level": "beginner"}
        )
        advanced = await client.get(
            "/api/v1/demo/preview-workout/1",
            params={"fitness_level": "advanced"}
        )

        assert beginner.status_code == 200
        assert advanced.status_code == 200

        beginner_workout = beginner.json()["workout"]
        advanced_workout = advanced.json()["workout"]

        # Beginner should have longer rest periods
        beginner_ex = beginner_workout["exercises"][0]
        advanced_ex = advanced_workout["exercises"][0]

        assert beginner_ex["rest_seconds"] >= advanced_ex["rest_seconds"]

    @pytest.mark.asyncio
    async def test_get_preview_workout_includes_warmup_cooldown(self, client: AsyncClient):
        """Test that preview workouts include warmup and cooldown."""
        response = await client.get("/api/v1/demo/preview-workout/1")

        assert response.status_code == 200
        workout = response.json()["workout"]

        assert "warmup" in workout
        assert "cooldown" in workout
        assert workout["warmup"]["duration_minutes"] > 0
        assert "exercises" in workout["warmup"]
        assert workout["cooldown"]["duration_minutes"] > 0


class TestTryWorkout:
    """Tests for the try workout functionality."""

    @pytest.mark.asyncio
    async def test_start_try_workout(self, client: AsyncClient):
        """Test starting a try workout."""
        session_id = str(uuid.uuid4())

        response = await client.post(
            "/api/v1/demo/try-workout",
            json={
                "session_id": session_id,
                "workout_id": "demo-beginner-full-body",
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "started"
        assert "workout" in data
        assert "try_token" in data
        assert "expires_in_minutes" in data
        assert data["expires_in_minutes"] == 60
        assert "instructions" in data
        assert "preview_limitations" in data
        assert "upgrade_cta" in data

    @pytest.mark.asyncio
    async def test_start_try_workout_fallback_workout(self, client: AsyncClient):
        """Test that invalid workout_id falls back to a valid workout."""
        session_id = str(uuid.uuid4())

        response = await client.post(
            "/api/v1/demo/try-workout",
            json={
                "session_id": session_id,
                "workout_id": "non-existent-workout",
            }
        )

        assert response.status_code == 200
        data = response.json()

        # Should still work with fallback
        assert data["status"] == "started"
        assert "workout" in data

    @pytest.mark.asyncio
    async def test_try_workout_limit_enforcement(self, client: AsyncClient):
        """Test that users can only try a limited number of workouts."""
        session_id = str(uuid.uuid4())

        # First try - should work
        response1 = await client.post(
            "/api/v1/demo/try-workout",
            json={
                "session_id": session_id,
                "workout_id": "demo-beginner-full-body",
            }
        )
        assert response1.status_code == 200
        assert response1.json()["status"] == "started"

        # Second try - should still work (one retry allowed)
        response2 = await client.post(
            "/api/v1/demo/try-workout",
            json={
                "session_id": session_id,
                "workout_id": "demo-hiit-blast",
            }
        )
        assert response2.status_code == 200
        # May be started or limit_reached depending on policy

        # Third try - should be limited
        response3 = await client.post(
            "/api/v1/demo/try-workout",
            json={
                "session_id": session_id,
                "workout_id": "demo-upper-strength",
            }
        )
        assert response3.status_code == 200
        data = response3.json()
        assert data["status"] == "limit_reached"
        assert "cta" in data

    @pytest.mark.asyncio
    async def test_complete_try_workout(self, client: AsyncClient):
        """Test completing a try workout."""
        session_id = str(uuid.uuid4())

        # Start a workout
        await client.post(
            "/api/v1/demo/try-workout",
            json={
                "session_id": session_id,
                "workout_id": "demo-beginner-full-body",
            }
        )

        # Complete the workout
        response = await client.post(
            "/api/v1/demo/try-workout/complete",
            json={
                "session_id": session_id,
                "workout_id": "demo-beginner-full-body",
                "duration_seconds": 1200,
                "exercises_completed": 5,
                "exercises_total": 6,
                "feedback": "just_right",
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "completed"
        assert "summary" in data
        assert data["summary"]["exercises_completed"] == 5
        assert data["summary"]["exercises_total"] == 6
        assert "completion_rate" in data["summary"]
        assert "motivation" in data
        assert "conversion_offer" in data
        assert "next_steps" in data

    @pytest.mark.asyncio
    async def test_complete_try_workout_perfect_completion(self, client: AsyncClient):
        """Test motivation message for perfect workout completion."""
        session_id = str(uuid.uuid4())

        response = await client.post(
            "/api/v1/demo/try-workout/complete",
            json={
                "session_id": session_id,
                "workout_id": "demo-beginner-full-body",
                "duration_seconds": 1800,
                "exercises_completed": 6,
                "exercises_total": 6,
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["summary"]["completion_rate"] == 100.0
        assert "Perfect" in data["motivation"] or "completed every" in data["motivation"]


class TestExercisesPreviewed:
    """Tests for the exercises previewed tracking endpoint."""

    @pytest.mark.asyncio
    async def test_get_previewed_exercises_empty_session(self, client: AsyncClient):
        """Test getting previewed exercises for a new session."""
        session_id = str(uuid.uuid4())

        response = await client.get(
            f"/api/v1/demo/exercises-previewed/{session_id}"
        )

        assert response.status_code == 200
        data = response.json()

        assert data["session_id"] == session_id
        assert "exercises_viewed" in data
        assert "workouts_viewed" in data
        assert "total_interactions" in data

    @pytest.mark.asyncio
    async def test_get_previewed_exercises_after_preview(self, client: AsyncClient):
        """Test that preview interactions are tracked."""
        session_id = str(uuid.uuid4())

        # View a preview workout
        await client.get(
            f"/api/v1/demo/preview-workout/1",
            params={"session_id": session_id}
        )

        # Check previewed exercises
        response = await client.get(
            f"/api/v1/demo/exercises-previewed/{session_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["session_id"] == session_id

    @pytest.mark.asyncio
    async def test_get_previewed_exercises_after_try_workout(self, client: AsyncClient):
        """Test that try workout interactions are tracked."""
        session_id = str(uuid.uuid4())

        # Start a try workout
        await client.post(
            "/api/v1/demo/try-workout",
            json={
                "session_id": session_id,
                "workout_id": "demo-beginner-full-body",
            }
        )

        # Complete it
        await client.post(
            "/api/v1/demo/try-workout/complete",
            json={
                "session_id": session_id,
                "workout_id": "demo-beginner-full-body",
                "duration_seconds": 900,
                "exercises_completed": 4,
                "exercises_total": 6,
            }
        )

        # Check previewed exercises
        response = await client.get(
            f"/api/v1/demo/exercises-previewed/{session_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["try_workout_completed"] is True
        assert data["try_workout_summary"] is not None


class TestDemoSessionTracking:
    """Tests for demo session tracking and conversion."""

    @pytest.mark.asyncio
    async def test_demo_interaction_logging(self, client: AsyncClient):
        """Test that demo interactions are properly logged."""
        session_id = str(uuid.uuid4())

        # Log various interactions
        interactions = [
            {"action_type": "screen_view", "screen": "home", "duration_seconds": 10},
            {"action_type": "screen_view", "screen": "exercise_library", "duration_seconds": 30},
            {"action_type": "feature_tap", "feature": "ai_coach", "metadata": {"was_locked": True}},
        ]

        for interaction in interactions:
            response = await client.post(
                "/api/v1/demo/interaction",
                json={"session_id": session_id, **interaction}
            )
            assert response.status_code == 200
            assert response.json()["status"] == "logged"

    @pytest.mark.asyncio
    async def test_full_demo_conversion_flow(self, client: AsyncClient):
        """Test the complete demo-to-signup conversion flow."""
        session_id = str(uuid.uuid4())

        # 1. Start demo session
        start_response = await client.post(
            "/api/v1/demo/session/start",
            json={
                "session_id": session_id,
                "quiz_data": {"goal": "build_muscle", "level": "intermediate"},
            }
        )
        assert start_response.status_code == 200

        # 2. Generate preview plan
        preview_response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["build_muscle"],
                "fitness_level": "intermediate",
                "equipment": ["dumbbells", "barbell"],
                "days_per_week": 4,
                "session_id": session_id,
            }
        )
        assert preview_response.status_code == 200

        # 3. View specific day workout
        day_response = await client.get(
            "/api/v1/demo/preview-workout/1",
            params={"session_id": session_id}
        )
        assert day_response.status_code == 200

        # 4. Try a workout
        try_response = await client.post(
            "/api/v1/demo/try-workout",
            json={
                "session_id": session_id,
                "workout_id": "demo-beginner-full-body",
            }
        )
        assert try_response.status_code == 200

        # 5. Complete try workout
        complete_response = await client.post(
            "/api/v1/demo/try-workout/complete",
            json={
                "session_id": session_id,
                "workout_id": "demo-beginner-full-body",
                "duration_seconds": 1500,
                "exercises_completed": 6,
                "exercises_total": 6,
            }
        )
        assert complete_response.status_code == 200
        assert "conversion_offer" in complete_response.json()

        # 6. Convert session (simulate signup)
        user_id = str(uuid.uuid4())
        convert_response = await client.post(
            "/api/v1/demo/session/convert",
            json={
                "session_id": session_id,
                "user_id": user_id,
                "trigger": "try_workout_complete",
            }
        )
        assert convert_response.status_code == 200
        assert convert_response.json()["status"] == "converted"

    @pytest.mark.asyncio
    async def test_preview_plan_generates_full_4_weeks(self, client: AsyncClient):
        """Test that preview plan includes 4 weeks of structure."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["build_muscle"],
                "fitness_level": "intermediate",
                "equipment": ["dumbbells"],
                "days_per_week": 3,
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["plan"]["weeks"] == 4
        assert "program_structure" in data["plan"]
        structure = data["plan"]["program_structure"]
        assert "week_1" in structure
        assert "week_2" in structure
        assert "week_3" in structure
        assert "week_4" in structure


class TestPreviewPlanQuality:
    """Tests to ensure preview plan quality matches paid generation."""

    @pytest.mark.asyncio
    async def test_preview_includes_personalization_data(self, client: AsyncClient):
        """Test that preview plan includes personalization info."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["lose_weight", "build_muscle"],
                "fitness_level": "beginner",
                "equipment": ["dumbbells", "resistance_bands"],
                "days_per_week": 4,
                "training_split": "upper_lower",
            }
        )

        assert response.status_code == 200
        data = response.json()

        personalization = data["personalization"]
        assert personalization["goal_match"] is True
        assert personalization["equipment_match"] is True
        assert personalization["fitness_level"] == "beginner"
        assert personalization["total_exercises"] > 0

    @pytest.mark.asyncio
    async def test_preview_includes_social_proof(self, client: AsyncClient):
        """Test that preview plan includes social proof data."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["build_muscle"],
                "fitness_level": "intermediate",
                "equipment": ["dumbbells"],
                "days_per_week": 3,
            }
        )

        assert response.status_code == 200
        data = response.json()

        social_proof = data["social_proof"]
        assert "similar_users" in social_proof
        assert social_proof["similar_users"] > 0
        assert "success_rate" in social_proof
        assert social_proof["success_rate"] > 0

    @pytest.mark.asyncio
    async def test_preview_exercises_have_proper_structure(self, client: AsyncClient):
        """Test that preview exercises have full structure."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["build_muscle"],
                "fitness_level": "intermediate",
                "equipment": ["dumbbells", "barbell"],
                "days_per_week": 3,
            }
        )

        assert response.status_code == 200
        data = response.json()

        for workout_day in data["plan"]["workout_days"]:
            assert "name" in workout_day
            assert "focus_muscles" in workout_day
            assert len(workout_day["focus_muscles"]) > 0
            assert "exercises" in workout_day
            assert len(workout_day["exercises"]) > 0
            assert "duration_minutes" in workout_day
            assert "estimated_calories" in workout_day

            for exercise in workout_day["exercises"]:
                assert "name" in exercise
                assert "sets" in exercise
                assert "reps" in exercise
                assert "muscle_group" in exercise
