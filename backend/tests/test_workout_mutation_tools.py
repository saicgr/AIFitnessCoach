"""
Tests for Issue 3 in-workout AI-coach mutation tools.

Covers the strict envelope shape, success path, and the documented edge
cases for each tool in
``services/langgraph_agents/tools/workout_mutation_tools.py``.

Run with: pytest backend/tests/test_workout_mutation_tools.py -v
"""
import sys
import os
import uuid
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.langgraph_agents.tools.workout_mutation_tools import (
    swap_single_exercise,
    log_set,
    create_superset,
    break_superset,
    reorder_exercises,
)


# ─── helpers ────────────────────────────────────────────────────────────────


def _wid() -> str:
    return str(uuid.uuid4())


def _sample_workout(workout_id: str, *, type_: str = "strength"):
    """Build a minimal workout row with 4 exercises."""
    return {
        "id": workout_id,
        "user_id": str(uuid.uuid4()),
        "type": type_,
        "last_modified_at": "2026-05-08T00:00:00Z",
        "exercises_json": [
            {"exercise_id": "e1", "name": "Squat", "equipment": "Barbell"},
            {"exercise_id": "e2", "name": "Bench Press", "equipment": "Barbell"},
            {"exercise_id": "e3", "name": "Row", "equipment": "Barbell"},
            {"exercise_id": "e4", "name": "Push-up", "equipment": "Bodyweight"},
        ],
    }


def _patch_db(workout, *, performance_logs=None, update_calls=None):
    """Patch get_supabase_db to return a controllable mock."""
    db = MagicMock()
    db.get_workout.return_value = workout

    # performance_logs query chain
    plog_chain = MagicMock()
    plog_chain.select.return_value = plog_chain
    plog_chain.eq.return_value = plog_chain
    plog_chain.order.return_value = plog_chain
    plog_chain.limit.return_value = plog_chain
    result = MagicMock()
    result.data = performance_logs or []
    plog_chain.execute.return_value = result

    table_mock = MagicMock(return_value=plog_chain)
    db.client.table = table_mock

    if update_calls is not None:
        def _upd(_id, data):
            update_calls.append(data)
            return {"id": _id}
        db.update_workout.side_effect = _upd
    else:
        db.update_workout.return_value = {"id": workout["id"]}

    return db


# ─── envelope shape ─────────────────────────────────────────────────────────


def test_envelope_shape_invalid_uuid():
    out = swap_single_exercise.invoke(
        {"workout_id": "nope", "old_exercise_name": "Squat", "new_exercise_name": "Lunge"}
    )
    assert out["success"] is False
    assert out["action_data"]["action"] == "swap_exercise"
    assert "summary_text" in out and "requires_confirmation" in out


# ─── swap_single_exercise ───────────────────────────────────────────────────


def test_swap_single_exercise_success():
    wid = _wid()
    db = _patch_db(_sample_workout(wid))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = swap_single_exercise.invoke(
            {"workout_id": wid, "old_exercise_name": "Squat", "new_exercise_name": "Lunge"}
        )
    assert out["success"] is True
    assert out["requires_confirmation"] is True
    assert out["action_data"]["old"] == "Squat"
    assert out["action_data"]["new"] == "Lunge"


def test_swap_single_exercise_not_in_workout():
    wid = _wid()
    db = _patch_db(_sample_workout(wid))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = swap_single_exercise.invoke(
            {"workout_id": wid, "old_exercise_name": "Deadlift", "new_exercise_name": "Lunge"}
        )
    assert out["success"] is False


# ─── log_set ────────────────────────────────────────────────────────────────


def test_log_set_bodyweight_no_weight_required():
    wid = _wid()
    db = _patch_db(_sample_workout(wid))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = log_set.invoke({
            "workout_id": wid,
            "exercise_id": "e4",
            "set_index": 1,
            "reps": 12,
        })
    assert out["success"] is True
    assert out["action_data"]["is_bodyweight"] is True
    assert out["action_data"]["weight_kg"] is None


def test_log_set_lbs_to_kg_conversion():
    wid = _wid()
    db = _patch_db(_sample_workout(wid))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = log_set.invoke({
            "workout_id": wid,
            "exercise_id": "e1",
            "set_index": 1,
            "weight": 100.0,
            "reps": 5,
            "weight_unit": "lb",
        })
    assert out["success"] is True
    # 100 lb ≈ 45.36 kg
    assert abs(out["action_data"]["weight_kg"] - 45.359237) < 0.001


def test_log_set_override_required_when_existing():
    wid = _wid()
    db = _patch_db(
        _sample_workout(wid),
        performance_logs=[{"id": 1, "set_number": 3, "weight_kg": 40, "reps_completed": 8}],
    )
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = log_set.invoke({
            "workout_id": wid,
            "exercise_id": "e1",
            "set_index": 3,
            "weight": 90,
            "reps": 6,
            "weight_unit": "lb",
        })
    assert out["success"] is True
    assert out["requires_confirmation"] is True
    assert "Override" in out["summary_text"]


def test_log_set_bilateral_side():
    wid = _wid()
    db = _patch_db(_sample_workout(wid))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = log_set.invoke({
            "workout_id": wid,
            "exercise_id": "e1",
            "set_index": 1,
            "weight": 50,
            "reps": 10,
            "side": "L",
            "weight_unit": "lb",
        })
    assert out["success"] is True
    assert out["action_data"]["side"] == "L"
    assert "L side only" in out["summary_text"]


# ─── create_superset ────────────────────────────────────────────────────────


def test_create_superset_adjacent():
    wid = _wid()
    workout = _sample_workout(wid)
    updates = []
    db = _patch_db(workout, update_calls=updates)
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = create_superset.invoke({"workout_id": wid, "exercise_ids": ["e1", "e2"]})
    assert out["success"] is True
    assert out["action_data"]["reordered"] is False
    assert "superset_group_id" in out["action_data"]
    assert len(updates) == 1


def test_create_superset_non_adjacent_reorders():
    wid = _wid()
    db = _patch_db(_sample_workout(wid))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = create_superset.invoke({"workout_id": wid, "exercise_ids": ["e1", "e4"]})
    assert out["success"] is True
    assert out["action_data"]["reordered"] is True
    assert "Reordered" in out["summary_text"]


def test_create_superset_amrap_blocked():
    wid = _wid()
    db = _patch_db(_sample_workout(wid, type_="AMRAP"))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = create_superset.invoke({"workout_id": wid, "exercise_ids": ["e1", "e2"]})
    assert out["success"] is False
    assert out["action_data"]["suggest_convert_to_circuit"] is True


def test_create_superset_triset():
    wid = _wid()
    db = _patch_db(_sample_workout(wid))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = create_superset.invoke(
            {"workout_id": wid, "exercise_ids": ["e1", "e2", "e3"]}
        )
    assert out["success"] is True


# ─── break_superset ─────────────────────────────────────────────────────────


def test_break_superset_stale():
    wid = _wid()
    db = _patch_db(_sample_workout(wid))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = break_superset.invoke(
            {"workout_id": wid, "superset_group_id": "stale-group-id"}
        )
    assert out["success"] is False
    assert "current_groups" in out["action_data"]


def test_break_superset_success():
    wid = _wid()
    workout = _sample_workout(wid)
    workout["exercises_json"][0]["superset_group_id"] = "g1"
    workout["exercises_json"][1]["superset_group_id"] = "g1"
    db = _patch_db(workout)
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = break_superset.invoke(
            {"workout_id": wid, "superset_group_id": "g1"}
        )
    assert out["success"] is True
    assert "Squat" in out["summary_text"]


# ─── reorder_exercises ──────────────────────────────────────────────────────


def test_reorder_exercises_success():
    wid = _wid()
    db = _patch_db(_sample_workout(wid))
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = reorder_exercises.invoke(
            {"workout_id": wid, "new_order": ["e4", "e1", "e2", "e3"]}
        )
    assert out["success"] is True
    assert out["action_data"]["new_order_names"][0] == "Push-up"


def test_reorder_exercises_pins_in_progress():
    wid = _wid()
    workout = _sample_workout(wid)
    workout["exercises_json"][1]["in_progress"] = True
    db = _patch_db(workout)
    with patch(
        "services.langgraph_agents.tools.workout_mutation_tools.get_supabase_db",
        return_value=db,
    ):
        out = reorder_exercises.invoke(
            {"workout_id": wid, "new_order": ["e4", "e3", "e2", "e1"]}
        )
    assert out["success"] is True
    assert out["action_data"]["kept_in_progress"] is True
    # Bench Press (e2, in_progress) keeps its slot index 1.
    assert out["action_data"]["new_order_names"][1] == "Bench Press"
