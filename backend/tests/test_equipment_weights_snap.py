"""
Unit tests for the `equipment_weights` feature: prescribing set weights that
stay within the discrete set of weights a user actually owns.

Covers:
- `snap_to_weight_list` nearest-of-list behavior (e.g. 12 -> 10 of [5,10,15]).
- `_resolve_available_kg_list`: canonical-key mapping, lbs->kg units bridge,
  kg pass-through, and the fail-open None paths.
- `format_exercise_for_workout`: every prescribed set weight lands inside the
  user's owned set when `equipment_weights` is supplied, and is unchanged
  (fail-open) when it is absent/empty.

Run:
    cd backend && .venv312/bin/python -m pytest tests/test_equipment_weights_snap.py -q
"""
from __future__ import annotations

import pytest

from core.weight_utils import snap_to_weight_list, lbs_to_kg_gym
from services.exercise_rag.formatting import (
    _resolve_available_kg_list,
    format_exercise_for_workout,
)


# --- snap_to_weight_list: the nearest-of-available helper -------------------

def test_snap_picks_nearest_available():
    # nearest of [5,10,15] to 12 -> 10
    assert snap_to_weight_list(12.0, [5.0, 10.0, 15.0], "dumbbell") == 10.0
    # exactly between -> min() picks the first/lower nearest deterministically
    assert snap_to_weight_list(12.5, [10.0, 15.0], "dumbbell") in (10.0, 15.0)
    # at/below zero -> lightest owned
    assert snap_to_weight_list(0.0, [5.0, 10.0, 15.0], "dumbbell") == 5.0
    # above the heaviest -> heaviest owned
    assert snap_to_weight_list(100.0, [5.0, 10.0, 15.0], "dumbbell") == 15.0


def test_snap_empty_list_falls_back_to_increment():
    # No owned list -> increment rounding (legacy behavior), NOT a crash.
    out = snap_to_weight_list(12.3, None, "barbell")
    assert out > 0


# --- _resolve_available_kg_list: mapping + units bridge --------------------

_EW = {
    "dumbbells": [5, 10, 15, 20, 25, 30],
    "kettlebell": [16, 24],
    "barbell": [45, 65, 95, 135],
}


def test_resolve_maps_equipment_type_to_canonical_key_and_converts_lbs():
    kg = _resolve_available_kg_list("dumbbell", _EW, "lbs")
    # Same length, all positive, gym-aware lbs->kg (30lb -> 13.5kg).
    assert kg is not None
    assert len(kg) == 6
    assert kg[-1] == lbs_to_kg_gym(30.0)


def test_resolve_kg_unit_passes_through_without_conversion():
    kg = _resolve_available_kg_list("dumbbell", {"dumbbells": [10, 20, 30]}, "kg")
    assert kg == [10.0, 20.0, 30.0]


def test_resolve_dumbbell_singular_key_tolerated():
    kg = _resolve_available_kg_list("dumbbell", {"dumbbell": [10, 20]}, "kg")
    assert kg == [10.0, 20.0]


def test_resolve_returns_none_for_unmapped_or_missing():
    # bodyweight has no loadable mapping
    assert _resolve_available_kg_list("bodyweight", _EW, "lbs") is None
    # cable not present in the supplied map
    assert _resolve_available_kg_list("cable", _EW, "lbs") is None
    # no map at all (fail-open)
    assert _resolve_available_kg_list("dumbbell", None, "lbs") is None
    assert _resolve_available_kg_list("dumbbell", {}, "lbs") is None


def test_resolve_drops_nonpositive_entries():
    kg = _resolve_available_kg_list("dumbbell", {"dumbbells": [0, -5, 10]}, "kg")
    assert kg == [10.0]


# --- format_exercise_for_workout: end-to-end snapping ----------------------

def _dumbbell_exercise():
    return {
        "name": "Dumbbell Bench Press",
        "equipment": "Dumbbells",
        "target_muscle": "chest",
        "id": "ex-1",
    }


def test_prescribed_weights_stay_within_owned_set():
    kg_set = set(_resolve_available_kg_list("dumbbell", _EW, "lbs"))
    out = format_exercise_for_workout(
        _dumbbell_exercise(),
        "intermediate",
        strength_history={"Dumbbell Bench Press": {"last_weight_kg": 23.0, "last_reps": 8}},
        equipment_weights=_EW,
        weight_unit="lbs",
    )
    assert out["weight_source"] == "owned_equipment"
    # Base weight is one the user owns.
    assert out["weight_kg"] in kg_set
    # EVERY set target (warmup + working) is inside the owned set.
    for st in out["set_targets"]:
        w = st["target_weight_kg"]
        if w and w > 0:
            assert w in kg_set, f"set weight {w} not in owned set {sorted(kg_set)}"


def test_fail_open_without_equipment_weights_is_unchanged():
    history = {"Dumbbell Bench Press": {"last_weight_kg": 23.0, "last_reps": 8}}
    legacy = format_exercise_for_workout(
        _dumbbell_exercise(), "intermediate", strength_history=history
    )
    empty = format_exercise_for_workout(
        _dumbbell_exercise(), "intermediate", strength_history=history,
        equipment_weights={}, weight_unit="lbs",
    )
    # No owned list => historical source preserved, weights identical.
    assert legacy["weight_source"] == "historical"
    assert empty["weight_source"] == "historical"
    assert legacy["weight_kg"] == empty["weight_kg"] == 23.0
    assert [s["target_weight_kg"] for s in legacy["set_targets"]] == \
           [s["target_weight_kg"] for s in empty["set_targets"]]


def test_bodyweight_exercise_ignores_equipment_weights():
    ex = {"name": "Push Up", "equipment": "bodyweight", "target_muscle": "chest", "id": "bw-1"}
    out = format_exercise_for_workout(
        ex, "intermediate", equipment_weights=_EW, weight_unit="lbs"
    )
    # Bodyweight => no loadable mapping; all targets remain 0.
    assert all((s["target_weight_kg"] or 0) == 0 for s in out["set_targets"])


def test_cascade_path_instance_stash_snaps_and_fail_open():
    """The /regenerate-stream cascade formats exercises without going back
    through select_exercises_for_workout, so it relies on the instance stash
    (`_equipment_weights` / `_weight_unit`). Verify both the snap and the
    fail-open (no stash) branches of `_format_exercise_for_workout`.
    """
    from services.exercise_rag.service import ExerciseRAGService

    history = {"Dumbbell Bench Press": {"last_weight_kg": 23.0, "last_reps": 8}}
    kg_set = set(_resolve_available_kg_list("dumbbell", _EW, "lbs"))

    # With stash set (mirrors select_exercises_with_fallback / *_for_workout).
    svc = ExerciseRAGService.__new__(ExerciseRAGService)
    svc._equipment_weights = _EW
    svc._weight_unit = "lbs"
    out = svc._format_exercise_for_workout(
        _dumbbell_exercise(), "intermediate", strength_history=history
    )
    assert out["weight_source"] == "owned_equipment"
    for st in out["set_targets"]:
        w = st["target_weight_kg"]
        if w and w > 0:
            assert w in kg_set

    # Without any stash -> getattr defaults -> legacy behavior (fail-open).
    bare = ExerciseRAGService.__new__(ExerciseRAGService)
    out2 = bare._format_exercise_for_workout(
        _dumbbell_exercise(), "intermediate", strength_history=history
    )
    assert out2["weight_source"] == "historical"


# --- Onboarding persistence + preferences-fallback ------------------------

def test_onboarding_request_accepts_and_merge_persists_equipment_weights():
    """Onboarding `POST /{user_id}/preferences` persists equipment_weights into
    the preferences JSON blob (same mechanism as the other extended fields),
    stored verbatim. Absent => not added (backward-compatible).
    """
    from api.v1.users.models import (
        UserPreferencesRequest,
        merge_extended_fields_into_preferences,
    )

    req = UserPreferencesRequest(equipment_weights=_EW)
    assert req.equipment_weights == _EW
    assert UserPreferencesRequest().equipment_weights is None

    prefs = merge_extended_fields_into_preferences(
        "{}", None, None, None, None, None, equipment_weights=_EW
    )
    assert prefs["equipment_weights"] == _EW  # stored as-is

    prefs_absent = merge_extended_fields_into_preferences("{}", None, None, None, None, None)
    assert "equipment_weights" not in prefs_absent


def test_preferences_fallback_used_when_request_omits_equipment_weights():
    """The generation/regeneration sites fall back to
    preferences['equipment_weights'] when the request body omits it. This
    mirrors the resolution logic at every call site (body wins, else prefs,
    else None) and confirms the resolved list still drives snapping.
    """
    from services.exercise_rag.service import ExerciseRAGService

    def _resolve(body_value, preferences):
        # Same shape used at every endpoint call site.
        return (
            body_value
            if body_value is not None
            else (preferences.get("equipment_weights") if isinstance(preferences, dict) else None)
        )

    # Body omits it, prefs has it -> prefs value wins.
    prefs = {"equipment_weights": _EW}
    resolved = _resolve(None, prefs)
    assert resolved == _EW

    # Body wins over prefs when both present.
    other = {"dumbbells": [40, 50]}
    assert _resolve(other, prefs) == other

    # Neither -> None (fail-open, no snapping).
    assert _resolve(None, {}) is None

    # The resolved-from-prefs value actually snaps prescription.
    svc = ExerciseRAGService.__new__(ExerciseRAGService)
    svc._equipment_weights = resolved
    svc._weight_unit = "lbs"
    kg_set = set(_resolve_available_kg_list("dumbbell", resolved, "lbs"))
    out = svc._format_exercise_for_workout(
        _dumbbell_exercise(), "intermediate",
        strength_history={"Dumbbell Bench Press": {"last_weight_kg": 23.0, "last_reps": 8}},
    )
    assert out["weight_source"] == "owned_equipment"
    for st in out["set_targets"]:
        w = st["target_weight_kg"]
        if w and w > 0:
            assert w in kg_set


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
