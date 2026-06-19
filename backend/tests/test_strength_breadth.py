"""Pure-logic unit tests for the Strength-Score breadth work (2026-06).

py3.9-safe and DB-free on purpose: imports ONLY the three pure service modules
(exercise_muscle_resolver, strength_population_standards, strength_movement_patterns)
plus StrengthCalculatorService, none of which pull in the FastAPI / feedback.py import
chain that fails on the local py3.9 venv. Run:

    python -m pytest backend/tests/test_strength_breadth.py -q
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from services.exercise_muscle_resolver import (  # noqa: E402
    text_to_muscles, is_machine_equipment, lookup_library_muscles,
)
from services.strength_population_standards import ratio_to_percentile  # noqa: E402
from services.strength_calculator_service import (  # noqa: E402
    StrengthCalculatorService, MuscleGroup,
)


# ── Resolver: the disambiguation cases that a naive substring scan gets wrong ──
def test_hamstring_not_biceps():
    # "biceps femoris" is a hamstring head, must NOT map to biceps.
    m = text_to_muscles("hamstrings (biceps femoris, semitendinosus, semimembranosus)")
    assert "hamstrings" in m
    assert "biceps" not in m


def test_rear_delt_not_shoulders():
    m = text_to_muscles("shoulders (posterior deltoids)")
    assert "rear_delts" in m
    assert "shoulders" not in m


def test_anterior_deltoid_is_shoulders():
    m = text_to_muscles("shoulders (anterior deltoids)")
    assert m == ["shoulders"]


def test_triceps_brachii_not_biceps():
    m = text_to_muscles("triceps (triceps brachii)")
    assert m == ["triceps"]


def test_brachioradialis_is_forearms():
    m = text_to_muscles("forearms (brachioradialis)")
    assert "forearms" in m and "biceps" not in m


def test_lower_back_vs_back():
    m = text_to_muscles("back (latissimus dorsi, erector spinae)")
    assert "back" in m and "lower_back" in m


def test_obliques_distinct_from_core():
    m = text_to_muscles("abdominals (rectus abdominis), obliques (external obliques)")
    assert "core" in m and "obliques" in m


def test_compound_leg_mapping():
    m = text_to_muscles("quadriceps (quadriceps femoris), glutes (gluteus maximus)")
    assert m == ["quads", "glutes"]


def test_adductors():
    m = text_to_muscles("adductors (adductor longus, adductor brevis, adductor magnus)")
    assert m == ["adductors"]


def test_unmappable_dropped():
    # hip flexors / rotator cuff / cardio don't map to a scored group → []
    assert text_to_muscles("hip flexors (iliopsoas)") == []
    assert text_to_muscles("cardio") == []
    assert text_to_muscles("") == []
    assert text_to_muscles(None) == []


# ── Machine flag ──────────────────────────────────────────────────────────────
def test_machine_detection():
    assert is_machine_equipment("Leverage machine")
    assert is_machine_equipment("cable")
    assert is_machine_equipment("Smith Machine")
    assert not is_machine_equipment("barbell")
    assert not is_machine_equipment(None)


# ── Library index lookup (in-memory, no DB) ──────────────────────────────────
def test_lookup_library_muscles():
    index = {
        "leg_press": {"muscles": ["quads", "glutes"], "equipment": "machine"},
    }
    assert lookup_library_muscles("Leg Press", index) == ["quads", "glutes"]
    # loose containment
    assert lookup_library_muscles("45 degree leg press", index) == ["quads", "glutes"]
    assert lookup_library_muscles("bench press", index) == []
    assert lookup_library_muscles("anything", None) == []


# ── Population percentile interpolation ──────────────────────────────────────
def test_percentile_monotonic_and_bounded():
    ladder = {"beginner": 0.5, "novice": 1.0, "intermediate": 1.25,
              "advanced": 1.5, "elite": 2.0}
    p_low = ratio_to_percentile(ladder, 0.4)
    p_mid = ratio_to_percentile(ladder, 1.25)
    p_high = ratio_to_percentile(ladder, 2.5)
    assert p_low is not None and p_mid is not None and p_high is not None
    assert 0 < p_low < p_mid < p_high <= 99
    assert abs(p_mid - 50.0) < 0.01  # intermediate anchor == 50th
    assert ratio_to_percentile({}, 1.0) is None


# ── A2 breadth bonus: composite score can only RISE from the blend (non-decreasing) ──
def _single_best_s1(svc, exercises, bw, gender):
    """Recompute the single-best S1 the old way for comparison."""
    best = 0.0
    best_name = ""
    best_eq = None
    for e in exercises:
        orm = svc.calculate_1rm_average(float(e["weight_kg"]), int(e["reps"]))
        if orm > best:
            best, best_name, best_eq = orm, e["exercise_name"], e.get("equipment")
    _, _, s1 = svc.classify_strength_level(best_name, best, bw, gender, equipment=best_eq)
    return s1


def test_breadth_bonus_never_decreases_score():
    svc = StrengthCalculatorService()
    bw, gender = 80.0, "male"
    # A broad base of moderate chest lifts.
    exercises = [
        {"exercise_name": "bench_press", "weight_kg": 90, "reps": 5, "sets": 3},
        {"exercise_name": "incline_bench_press", "weight_kg": 70, "reps": 8, "sets": 3},
        {"exercise_name": "dumbbell_bench_press", "weight_kg": 30, "reps": 10, "sets": 3},
    ]
    score = svc.compute_composite_muscle_score("chest", exercises, bw, gender)
    breakdown = score.composite_breakdown or {}
    single_best = _single_best_s1(svc, exercises, bw, gender)
    # The blended S1 must be >= single-best S1 (the max() guarantee).
    assert breakdown["s1_rel_strength"] >= round(single_best, 1) - 0.05
    assert breakdown["s1_breadth_exercises"] == 3


def test_sixteen_muscle_groups():
    assert len(list(MuscleGroup)) == 16
    for g in ("rear_delts", "obliques", "adductors", "lower_back"):
        assert g in {m.value for m in MuscleGroup}


if __name__ == "__main__":
    import pytest
    raise SystemExit(pytest.main([__file__, "-q"]))
