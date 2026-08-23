"""Regression gate — E2E register #190.

The audit found that /api/v1/workouts/quick (the endpoint the app's "Quick
Generate" button actually hits — workouts_signature_body.dart:159 ->
quick_workout_provider.dart:487-490) never looked at favorite_exercises or
exercise_queue at all, even though /generate, /generate-stream and mood
generation all wire those signals into exercise_rag's
apply_favorites_boost / extract_queued_exercises.

This test proves, through the real HTTP endpoint (only Gemini + the DB are
mocked), that:
  1. A queued exercise is GUARANTEED to appear in the persisted workout even
     when the mocked Gemini response omits it (mirrors extract_queued_exercises
     treating the queue as guaranteed inclusion, not just a prompt nudge).
  2. A favorite exercise is surfaced to Gemini via an explicit "USER
     FAVORITES" prompt instruction (mirrors apply_favorites_boost — a ranking
     boost, not a hard guarantee, so it is proven via the prompt, not a forced
     append).

Run:
    cd backend && .venv312/bin/python -m pytest tests/test_quick_favorites_queue.py -v
"""
from __future__ import annotations

import json as _json
from typing import Any, Dict
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from main import app
from core.auth import get_current_user
import api.v1.workouts.quick as quick_mod


# Library pool the fake exercise-library service hands back for every focus
# term build_library_pool asks for. Includes the user's favorite (Goblet
# Squat) and queued (Kettlebell Swing) exercises plus two plain ones so the
# pool isn't trivially just those two.
_LIBRARY_POOL = [
    {"name": "Goblet Squat", "sets": 3, "reps": 10, "rest_seconds": 60,
     "equipment": "dumbbell", "muscle_group": "legs"},
    {"name": "Kettlebell Swing", "sets": 3, "reps": 15, "rest_seconds": 45,
     "equipment": "kettlebell", "muscle_group": "full_body"},
    {"name": "Push Up", "sets": 3, "reps": 12, "rest_seconds": 45,
     "equipment": "bodyweight", "muscle_group": "chest"},
    {"name": "Plank", "sets": 3, "reps": 1, "rest_seconds": 30,
     "equipment": "bodyweight", "muscle_group": "core"},
]


@pytest.mark.asyncio
async def test_quick_generate_honours_favorites_and_queue():
    user_id = "33333333-3333-3333-3333-333333333333"
    captured: Dict[str, Any] = {}

    fake_db = MagicMock()
    fake_db.get_user.return_value = {
        "id": user_id, "fitness_level": "intermediate", "equipment": ["dumbbell", "kettlebell"],
    }

    def _create_workout(payload):
        captured["exercises"] = payload["exercises_json"]
        return {
            "id": "44444444-4444-4444-4444-444444444444",
            "user_id": user_id, "name": payload["name"], "type": payload["type"],
            "difficulty": payload["difficulty"],
            "scheduled_date": payload["scheduled_date"],
            "exercises_json": payload["exercises_json"],
            "duration_minutes": payload["duration_minutes"],
        }

    fake_db.create_workout.side_effect = _create_workout

    # Gemini deliberately OMITS both the favorite and the queued exercise —
    # proves the favorite is only ever a prompt-level boost (checked via the
    # captured prompt) while the queued exercise must be force-restored by
    # the endpoint itself.
    gemini_payload = {
        "name": "Quick Full Body", "type": "full_body", "difficulty": "intermediate",
        "exercises": [
            {"name": "Push Up", "muscle_group": "chest", "target_muscle": "chest",
             "sets": 3, "reps": 12, "rest_seconds": 45},
            {"name": "Plank", "muscle_group": "core", "target_muscle": "core",
             "sets": 3, "reps": 1, "hold_seconds": 30},
        ],
    }
    gemini_response = MagicMock()
    gemini_response.text = _json.dumps(gemini_payload)

    async def _fake_gemini(*args, **kwargs):
        captured["prompt"] = kwargs.get("contents")
        return gemini_response

    fake_lib_svc = MagicMock()
    fake_lib_svc.get_exercises_for_workout.return_value = list(_LIBRARY_POOL)

    app.dependency_overrides[get_current_user] = lambda: {"id": user_id}
    try:
        with patch.object(quick_mod, "get_supabase_db", return_value=fake_db), \
             patch.object(quick_mod, "get_active_gym_profile", return_value=None), \
             patch.object(quick_mod, "get_active_gym_profile_id", return_value=None), \
             patch.object(quick_mod, "get_user_avoided_exercises",
                          AsyncMock(return_value=[])), \
             patch.object(quick_mod, "get_user_avoided_muscles",
                          AsyncMock(return_value={"avoid": [], "reduce": []})), \
             patch.object(quick_mod, "get_user_progression_pace",
                          AsyncMock(return_value="medium")), \
             patch.object(quick_mod, "get_user_rep_preferences",
                          AsyncMock(return_value={"training_focus": "balanced",
                                                  "min_reps": 8, "max_reps": 12})), \
             patch.object(quick_mod, "get_user_progression_context",
                          AsyncMock(return_value={"mastery_context": ""})), \
             patch.object(quick_mod, "get_active_injuries_with_muscles",
                          AsyncMock(return_value={"injuries": [], "avoided_muscles": []})), \
             patch.object(quick_mod, "get_user_favorite_exercises",
                          AsyncMock(return_value=["Goblet Squat"])), \
             patch.object(quick_mod, "get_user_exercise_queue",
                          AsyncMock(return_value=[{
                              "name": "Kettlebell Swing",
                              "target_muscle_group": "full_body",
                              "priority": 0,
                          }])), \
             patch.object(quick_mod, "log_workout_change", MagicMock()), \
             patch.object(quick_mod, "index_workout_to_rag", MagicMock()), \
             patch.object(quick_mod, "track_quick_workout_usage",
                          AsyncMock(return_value=None)), \
             patch("services.exercise_library_service.get_exercise_library_service",
                   return_value=fake_lib_svc), \
             patch("services.gemini.constants.gemini_generate_with_retry",
                   AsyncMock(side_effect=_fake_gemini)):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as ac:
                resp = await ac.post(
                    "/api/v1/workouts/quick",
                    json={"user_id": user_id, "duration": 15, "focus": "full_body",
                          "source": "button"},
                )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert resp.status_code == 200, resp.text

    # 1. Queue is a GUARANTEE — Gemini's response omitted "Kettlebell Swing"
    #    entirely, but it must still land in the persisted workout.
    persisted = captured.get("exercises")
    assert persisted is not None, "workout was never persisted"
    names = [e.get("name") for e in persisted]
    assert "Kettlebell Swing" in names, (
        f"queued exercise was not force-included when Gemini omitted it: {names}"
    )

    # 2. Favorites are a BOOST surfaced to the model, not a forced append —
    #    proven via the prompt Gemini actually received.
    prompt = captured.get("prompt") or ""
    assert "USER FAVORITES" in prompt
    assert "Goblet Squat" in prompt
    assert "USER QUEUED THESE EXERCISES" in prompt
    assert "Kettlebell Swing" in prompt
