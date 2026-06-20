"""Edge-case tests for the selection + prescription robustness guards.

Covers the deterministic, in-memory, fail-open guards added to harden exercise
selection + prescription against degenerate / unsafe / nonsensical plans:

  A1  filter_by_avoided_muscles down-ranks (keeps) instead of emptying the pool
      when every candidate hits an avoided muscle, and is byte-identical to the
      legacy hard-exclude when no floor is requested (fail-open).
  A2  select_exercises_with_fallback never returns < min_floor — even when
      safety_mode.build_plan raises (mocked) — by padding from the last-resort set.
  A3  ensure_complete_workout time right-sizing bumps sets when under-filled and
      reduces the stated duration when the constrained pool genuinely can't fill.
  B   an only-50-lb-dumbbell beginner gets sane reps (not an absurd load), and an
      only-5-lb squat gets higher reps + tempo (verified via formatting).
  C   a 0-push-up user gets a regression preferred from the in-memory pool.
  E1  validate_in_memory drops hallucinated / unavailable / duplicate / injury-
      violating moves.
  FAIL-OPEN  an unconstrained profile produces identical output.
  TIMING     the new guards add only a few ms.

Run:
    cd backend && .venv312/bin/python -m pytest \
        tests/test_generation_edge_cases_selection.py -q
"""
from __future__ import annotations

import time

import pytest


# ===========================================================================
# A1 — fail-soft avoided-muscle filter
# ===========================================================================
from services.exercise_rag.filters import filter_by_avoided_muscles


def _all_chest_pool():
    # Every candidate's PRIMARY or body_part is chest, plus one with chest only
    # as a secondary muscle (the least-bad rescue candidate).
    return [
        {"name": "Bench Press", "target_muscle": "chest", "body_part": "chest",
         "secondary_muscles": [], "similarity": 0.9},
        {"name": "Incline Press", "target_muscle": "chest", "body_part": "chest",
         "secondary_muscles": [], "similarity": 0.8},
        {"name": "Cable Fly", "target_muscle": "chest", "body_part": "chest",
         "secondary_muscles": [], "similarity": 0.7},
        {"name": "Dip", "target_muscle": "triceps", "body_part": "arms",
         "secondary_muscles": [{"muscle": "chest", "involvement": 0.4}], "similarity": 0.6},
    ]


def test_a1_downranks_instead_of_emptying_when_floor_requested():
    avoided = {"avoid": ["chest"], "reduce": []}
    kept, primary, secondary, collapsed = filter_by_avoided_muscles(
        _all_chest_pool(), avoided, target=4
    )
    # Pool would be EMPTY with a hard exclude (every row hits chest). With a
    # floor it must not be empty.
    assert len(kept) > 0
    assert collapsed is True
    # The least-bad (secondary-only) candidate should be among the keeps and the
    # down-ranked ones carry the marker.
    assert all(k.get("avoided_muscle_downranked") for k in kept)
    # The secondary-only "Dip" is kept with a milder penalty -> it ranks first.
    assert kept[0]["name"] == "Dip"


def test_a1_fail_open_legacy_behavior_without_floor():
    # No floor (default) -> exact legacy hard-exclude; an all-chest pool empties.
    avoided = {"avoid": ["chest"], "reduce": []}
    kept, primary, secondary, collapsed = filter_by_avoided_muscles(
        _all_chest_pool(), avoided
    )
    assert kept == []
    assert collapsed is False
    assert primary == 3 and secondary == 1


def test_a1_partial_pool_unaffected_when_above_floor():
    # A mixed pool with enough non-avoided survivors is unchanged by the rescue.
    pool = [
        {"name": "Bench Press", "target_muscle": "chest", "body_part": "chest",
         "secondary_muscles": [], "similarity": 0.9},
        {"name": "Squat", "target_muscle": "legs", "body_part": "thighs",
         "secondary_muscles": [], "similarity": 0.8},
        {"name": "Row", "target_muscle": "back", "body_part": "back",
         "secondary_muscles": [], "similarity": 0.7},
        {"name": "Curl", "target_muscle": "biceps", "body_part": "arms",
         "secondary_muscles": [], "similarity": 0.6},
    ]
    kept, primary, secondary, collapsed = filter_by_avoided_muscles(
        pool, {"avoid": ["chest"], "reduce": []}, target=1
    )
    assert collapsed is False
    assert "Bench Press" not in {k["name"] for k in kept}
    assert len(kept) == 3


# ===========================================================================
# A2 — cascade never returns < min_floor, even when safety_mode raises
# ===========================================================================
@pytest.mark.asyncio
async def test_a2_pads_to_floor_when_safety_mode_raises(monkeypatch):
    from services.exercise_rag.service import ExerciseRAGService

    svc = ExerciseRAGService.__new__(ExerciseRAGService)

    # Every RAG tier returns nothing.
    async def _empty(*a, **k):
        return []

    async def _empty_substr(*a, **k):
        return []

    svc.select_exercises_for_workout = _empty  # type: ignore
    svc._fetch_by_name_substrings = _empty_substr  # type: ignore

    # Force safety_mode.build_plan to RAISE so only the deterministic padding
    # can satisfy the floor.
    import services.exercise_rag.safety_mode as sm

    async def _boom(*a, **k):
        raise RuntimeError("DB outage")

    monkeypatch.setattr(sm, "build_plan", _boom)

    result, tier = await svc.select_exercises_with_fallback(
        focus_area="chest",
        equipment=["dumbbells"],
        fitness_level="beginner",
        goals=["hypertrophy"],
        count=6,
        min_floor=4,
        duration_minutes=45,
    )
    assert tier == "safety_mode_fallback"
    assert len(result) >= 4, f"expected >= floor, got {len(result)}"
    # The padded items are tagged so completeness marks the workout degraded.
    assert any(ex.get("_padded") for ex in result)


# ===========================================================================
# A3 — time right-sizing
# ===========================================================================
from api.v1.workouts.exercise_target import estimate_total_minutes
from services.workout_completeness import ensure_complete_workout


def _ex(name, sets=3, reps=10, rest=60):
    return {"name": name, "sets": sets, "reps": reps, "rest_seconds": rest,
            "muscle_group": "chest", "equipment": "Dumbbells"}


@pytest.mark.asyncio
async def test_a3_underfill_bumps_sets_for_constrained_pool():
    # 2 light exercises, requested 45 min, bodyweight-only (constrained) pool.
    exercises = [_ex("Push Up", sets=2, reps=10, rest=45),
                 _ex("Plank", sets=2, reps=10, rest=45)]
    before = estimate_total_minutes(exercises)
    out, reason = await ensure_complete_workout(
        list(exercises),
        target=2, floor=2, focus_area="chest",
        equipment=["bodyweight"], fitness_level="beginner",
        duration_minutes=45, candidate_pool_size=4,
    )
    after = estimate_total_minutes(out)
    # Sets were bumped to add volume (or stated duration reduced if impossible).
    total_sets_before = sum(e["sets"] for e in exercises)
    total_sets_after = sum(e["sets"] for e in out)
    reduced = any(e.get("_adjusted_duration_minutes") for e in out)
    assert total_sets_after > total_sets_before or reduced
    assert after >= before


@pytest.mark.asyncio
async def test_a3_underfill_reduces_duration_when_unfillable():
    # A single short bodyweight exercise can't fill 60 min; stated duration drops.
    exercises = [_ex("Plank", sets=2, reps=8, rest=30)]
    out, reason = await ensure_complete_workout(
        list(exercises),
        target=1, floor=1, focus_area="core",
        equipment=["bodyweight"], fitness_level="beginner",
        duration_minutes=60, candidate_pool_size=1,
    )
    assert any(e.get("_adjusted_duration_minutes") for e in out)
    assert out[0]["_adjusted_duration_minutes"] < 60


@pytest.mark.asyncio
async def test_a3_overfill_trims():
    # An over-stuffed short session should be trimmed toward the band.
    exercises = [_ex(f"Ex{i}", sets=5, reps=15, rest=120) for i in range(6)]
    before = estimate_total_minutes(exercises)
    out, reason = await ensure_complete_workout(
        list(exercises),
        target=6, floor=3, focus_area="full_body",
        equipment=["dumbbells", "barbell", "bench"], fitness_level="intermediate",
        duration_minutes=20,
    )
    after = estimate_total_minutes(out)
    assert after < before


# ===========================================================================
# B — only-50-lb-dumbbell beginner gets sane reps not an absurd prescription
# ===========================================================================
from services.exercise_rag.formatting import format_exercise_for_workout


def test_b_too_heavy_owned_weight_caps_reps_and_notes():
    # Beginner isolation defaults to ~12 reps. With only a 50 lb dumbbell the
    # load snaps too heavy, so reps are pulled DOWN toward the movement's floor
    # (never below the type's min) and a caution note is surfaced.
    default = format_exercise_for_workout(
        {"name": "Dumbbell Lateral Raise", "equipment": "Dumbbells",
         "target_muscle": "shoulders", "id": "x"},
        "beginner",
        equipment_weights={"dumbbells": [10]},  # in-band 10 lb -> normal reps
        weight_unit="lbs",
    )
    out = format_exercise_for_workout(
        {"name": "Dumbbell Lateral Raise", "equipment": "Dumbbells",
         "target_muscle": "shoulders", "id": "x"},
        "beginner",
        equipment_weights={"dumbbells": [50]},  # 50 lb only -> too heavy
        weight_unit="lbs",
    )
    # Reps reduced vs the in-band prescription, and a caution note added.
    assert out["reps"] < default["reps"]
    assert "heavier than ideal" in out["notes"]
    assert "heavier than ideal" not in default["notes"]


def test_b_too_light_owned_weight_raises_reps_and_notes():
    out = format_exercise_for_workout(
        {"name": "Dumbbell Goblet Squat", "equipment": "Dumbbells",
         "target_muscle": "legs", "id": "y"},
        "beginner",
        goals=["strength"],  # strength normally forces 3-6 reps...
        equipment_weights={"dumbbells": [5]},  # ...but 5 lb squat is too light
        weight_unit="lbs",
    )
    assert out["reps"] >= 12  # sane-load override beats the strength rep scheme
    assert "lighter than ideal" in out["notes"]


def test_b_fail_open_in_band_no_note():
    out = format_exercise_for_workout(
        {"name": "Dumbbell Bench Press", "equipment": "Dumbbells",
         "target_muscle": "chest", "id": "z"},
        "intermediate",
        strength_history={"Dumbbell Bench Press": {"last_weight_kg": 20.0, "last_reps": 8}},
        equipment_weights={"dumbbells": [10, 15, 20, 25, 30]},
        weight_unit="lbs",
    )
    assert "lighter than ideal" not in out["notes"]
    assert "heavier than ideal" not in out["notes"]


# ===========================================================================
# C — capacity-aware regression
# ===========================================================================
from services.exercise_rag.selection_pipeline import apply_capacity_aware_regression


def test_c_zero_pushup_user_prefers_regression():
    pool = [
        {"name": "Standard Push Up", "similarity": 0.9},
        {"name": "Wall Push Up", "similarity": 0.5},
        {"name": "Knee Push Up", "similarity": 0.4},
        {"name": "Dumbbell Curl", "similarity": 0.8},
    ]
    out = apply_capacity_aware_regression(pool, {"pushup": 0}, "beginner")
    names = [c["name"] for c in out]
    assert names.index("Wall Push Up") < names.index("Standard Push Up")


def test_c_advanced_user_prefers_progression():
    pool = [
        {"name": "Standard Push Up", "similarity": 0.6},
        {"name": "Archer Push Up", "similarity": 0.5},
    ]
    out = apply_capacity_aware_regression(pool, {"pushup": 45}, "advanced")
    assert out[0]["name"] == "Archer Push Up"


def test_c_fail_open_no_capacity():
    pool = [{"name": "Standard Push Up", "similarity": 0.9}]
    assert apply_capacity_aware_regression(list(pool), None, "beginner") == pool


# ===========================================================================
# E1 — in-memory validator drops/swaps bad moves
# ===========================================================================
from services.workout_safety_validator import validate_in_memory


def _e1_pool():
    return [
        {"name": "Barbell Bench Press", "id": "p1", "equipment": "Barbell", "muscle_group": "chest"},
        {"name": "Dumbbell Bench Press", "id": "p2", "equipment": "Dumbbells", "muscle_group": "chest"},
        {"name": "Cable Row", "id": "p3", "equipment": "Cable", "muscle_group": "back"},
    ]


def test_e1_drops_hallucinated_and_dups_and_swaps_equipment():
    gen = [
        {"name": "Quantum Mega Press", "id": "h1", "equipment": "Dumbbells", "muscle_group": "chest"},
        {"name": "Cable Row", "id": "p3", "equipment": "Cable", "muscle_group": "back"},
        {"name": "Cable Row", "id": "p3", "equipment": "Cable", "muscle_group": "back"},  # dup
    ]
    cleaned, notes = validate_in_memory(
        gen, library_pool=_e1_pool(), equipment=["dumbbells", "cable"], injuries=[]
    )
    names = [c["name"] for c in cleaned]
    # Hallucination replaced by a same-pattern available press; dup dropped.
    assert "Quantum Mega Press" not in names
    assert "Dumbbell Bench Press" in names
    assert names.count("Cable Row") == 1


def test_e1_equipment_unavailable_swapped():
    gen = [{"name": "Barbell Bench Press", "id": "p1", "equipment": "Barbell", "muscle_group": "chest"}]
    cleaned, notes = validate_in_memory(
        gen, library_pool=_e1_pool(), equipment=["dumbbells"], injuries=[]
    )
    assert [c["name"] for c in cleaned] == ["Dumbbell Bench Press"]
    assert any("equipment unavailable" in n for n in notes)


def test_e1_injury_violating_dropped_when_no_substitute():
    gen = [{"name": "Barbell Back Squat", "id": "p1", "equipment": "Barbell", "muscle_group": "legs"}]
    cleaned, notes = validate_in_memory(
        gen, library_pool=_e1_pool(), equipment=["barbell"], injuries=["knee"]
    )
    # No safe squat substitute in the pool -> the lone slip is dropped, not shipped.
    assert all("squat" not in c["name"].lower() for c in cleaned)


def test_e1_fail_open_empty_pool_keeps_clean_list():
    gen = [{"name": "Dumbbell Bench Press", "id": "p2", "equipment": "Dumbbells", "muscle_group": "chest"}]
    cleaned, notes = validate_in_memory(gen, library_pool=[], equipment=["dumbbells"], injuries=[])
    assert [c["name"] for c in cleaned] == ["Dumbbell Bench Press"]


# ===========================================================================
# FAIL-OPEN — unconstrained profile is byte-identical
# ===========================================================================
def test_fail_open_formatting_unchanged_without_equipment_weights():
    ex = {"name": "Dumbbell Bench Press", "equipment": "Dumbbells",
          "target_muscle": "chest", "id": "z"}
    history = {"Dumbbell Bench Press": {"last_weight_kg": 23.0, "last_reps": 8}}
    legacy = format_exercise_for_workout(ex, "intermediate", strength_history=history)
    # No equipment_weights, no capacity -> the B/sane-load guard never engages.
    assert "lighter than ideal" not in legacy["notes"]
    assert "heavier than ideal" not in legacy["notes"]
    assert legacy["weight_source"] == "historical"


@pytest.mark.asyncio
async def test_fail_open_completeness_no_duration_is_noop():
    # duration_minutes=None -> the time pass is skipped entirely.
    exercises = [_ex("Bench", sets=3, reps=10), _ex("Row", sets=3, reps=10)]
    out, reason = await ensure_complete_workout(
        list(exercises), target=2, floor=2, focus_area="chest",
        equipment=["dumbbells", "barbell", "cable", "bench"],
    )
    # Sets untouched (no time guard ran).
    assert [e["sets"] for e in out] == [3, 3]
    assert reason is None


# ===========================================================================
# TIMING — the new in-memory guards are cheap
# ===========================================================================
def test_timing_guards_are_fast():
    pool = [
        {"name": f"Dumbbell Bench Press {i}", "id": f"p{i}", "equipment": "Dumbbells",
         "muscle_group": "chest", "similarity": 0.5} for i in range(40)
    ]
    gen = list(pool[:8])
    t0 = time.perf_counter()
    for _ in range(200):
        validate_in_memory(gen, library_pool=pool, equipment=["dumbbells"], injuries=["knee"])
        apply_capacity_aware_regression([dict(c) for c in pool], {"pushup": 0}, "beginner")
        filter_by_avoided_muscles([dict(c) for c in pool], {"avoid": ["chest"], "reduce": []}, target=6)
    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    per_iter_ms = elapsed_ms / 200.0
    # Three guards over a 40-candidate pool, 200×: comfortably a few ms/iter.
    assert per_iter_ms < 15.0, f"guards too slow: {per_iter_ms:.2f} ms/iter"


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
