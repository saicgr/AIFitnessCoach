"""
Tests for Issue 4 fixes in detect_fatigue:
- Bug A: Units (kg vs lb) — output respects user_workout_unit.
- Bug B: Source — anchors on last actual completed set, not target.
- Bug C: Inverted clamp — reductions never produce numbers >= anchor.
+ All edge cases from plan §4 (warmup, AMRAP, drop, first set, bodyweight,
  min-load, cooldown).

Run:
    backend/.venv/bin/pytest backend/tests/test_fatigue_detection_unit_fix.py -v
"""
from __future__ import annotations

import pytest

from services.fatigue_detection_service_helpers import detect_fatigue, FatigueAlert


def _fatigued_session(weight_kg: float = 45.0):
    """3 working sets where set 3 came in well below target — should
    trigger fatigue (RIR 0 vs target 4 = 4-rir-deviation, plus rep decline).
    """
    return [
        {"reps": 11, "weight": weight_kg, "rir": 4, "target_reps": 11, "target_rir": 4},
        {"reps": 9,  "weight": weight_kg, "rir": 2, "target_reps": 11, "target_rir": 4},
        {"reps": 5,  "weight": weight_kg, "rir": 0, "target_reps": 11, "target_rir": 4},
    ]


# ---------------------------------------------------------------------------
# Bug A — Units
# ---------------------------------------------------------------------------

def test_unit_lb_returns_lb_label_and_lb_number():
    """User in lbs: output unit is 'lb' and the number is the lb value."""
    sets = _fatigued_session(weight_kg=20.4)  # ~45 lb
    alert: FatigueAlert = detect_fatigue(
        session_sets=sets,
        current_weight=20.4,
        exercise_type="compound",
        user_workout_unit="lb",
        user_increment_kg=2.27,  # 5 lb
    )
    assert alert.fatigue_detected is True
    assert alert.weight_unit == "lb"
    assert alert.suggested_weight is not None
    # 20.4 kg ≈ 45 lb. Reduction 5–15% → ~38 lb area.
    assert 30 <= alert.suggested_weight <= 45
    # Back-compat field still in kg.
    assert alert.suggested_weight_kg < 20.4


def test_unit_lbs_alias_normalized_to_lb():
    """Flutter sometimes sends 'lbs'; normalize to 'lb'."""
    sets = _fatigued_session()
    alert = detect_fatigue(sets, 45.0, user_workout_unit="lbs")
    assert alert.weight_unit == "lb"


def test_unit_default_is_kg_when_unset():
    sets = _fatigued_session()
    alert = detect_fatigue(sets, 45.0)
    assert alert.weight_unit == "kg"


# ---------------------------------------------------------------------------
# Bug B — Source: anchor on actual last completed set, not target_weight
# ---------------------------------------------------------------------------

def test_anchor_uses_actual_last_weight_not_target():
    """User actually lifted 30 kg, but progression target said 45 kg.
    Suggestion must reduce from 30 kg, not 45 kg.
    """
    sets = [
        {"reps": 11, "weight": 30.0, "rir": 4, "target_reps": 11, "target_rir": 4, "target_weight": 45.0},
        {"reps": 9,  "weight": 30.0, "rir": 2, "target_reps": 11, "target_rir": 4, "target_weight": 45.0},
        {"reps": 5,  "weight": 30.0, "rir": 0, "target_reps": 11, "target_rir": 4, "target_weight": 45.0},
    ]
    alert = detect_fatigue(sets, current_weight=30.0)
    assert alert.fatigue_detected is True
    # Suggestion must be at or below the ACTUAL anchor (30 kg), never above.
    assert alert.suggested_weight_kg <= 30.0
    assert alert.suggested_weight is not None and alert.suggested_weight <= 30.0


# ---------------------------------------------------------------------------
# Bug C — Inverted clamp
# ---------------------------------------------------------------------------

def test_reduction_never_clamps_upward():
    """30 kg fatigued → suggested must be < 30, not 45 (the target)."""
    sets = [
        {"reps": 11, "weight": 30.0, "rir": 4, "target_reps": 11, "target_rir": 4, "target_weight": 45.0},
        {"reps": 5,  "weight": 30.0, "rir": 0, "target_reps": 11, "target_rir": 4, "target_weight": 45.0},
    ]
    alert = detect_fatigue(sets, 30.0, progression_pattern="pyramidUp")
    assert alert.fatigue_detected is True
    assert alert.suggested_weight_kg < 30.0


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

def test_first_set_only_suppresses():
    sets = [{"reps": 5, "weight": 45.0, "rir": 0, "target_rir": 4}]
    alert = detect_fatigue(sets, 45.0)
    assert alert.fatigue_detected is False


def test_warmup_sets_excluded():
    """Warmup sets must not pollute fatigue math."""
    sets = [
        {"reps": 5,  "weight": 20.0, "is_warmup": True, "target_rir": 4},
        {"reps": 5,  "weight": 20.0, "set_type": "warmup", "target_rir": 4},
        {"reps": 11, "weight": 45.0, "rir": 4, "target_reps": 11, "target_rir": 4},
    ]
    # Only one working set after stripping warmups → suppressed.
    alert = detect_fatigue(sets, 45.0)
    assert alert.fatigue_detected is False


def test_amrap_set_suppresses_alert():
    """target_rir == 0 (AMRAP) → low RIR is expected, not fatigue."""
    sets = [
        {"reps": 11, "weight": 45.0, "rir": 0, "target_reps": 11, "target_rir": 0},
        {"reps": 9,  "weight": 45.0, "rir": 0, "target_reps": 11, "target_rir": 0},
    ]
    alert = detect_fatigue(sets, 45.0)
    assert alert.fatigue_detected is False


def test_drop_set_pattern_suppresses():
    sets = _fatigued_session()
    alert = detect_fatigue(sets, 45.0, progression_pattern="dropSets")
    assert alert.fatigue_detected is False


def test_bodyweight_returns_rep_target_not_weight():
    sets = [
        {"reps": 12, "weight": 0, "rir": 4, "target_reps": 12, "target_rir": 4},
        {"reps": 10, "weight": 0, "rir": 2, "target_reps": 12, "target_rir": 4},
        {"reps": 5,  "weight": 0, "rir": 0, "target_reps": 12, "target_rir": 4},
    ]
    alert = detect_fatigue(sets, 0.0, exercise_type="bodyweight")
    assert alert.fatigue_detected is True
    assert alert.suggested_weight is None
    assert alert.rep_target_reduction is not None
    assert alert.rep_target_reduction < 12


def test_min_load_no_further_reduction():
    """At minimum sane load (≤ 2.5 kg) we recommend rest-pause/stop, not a lower number."""
    sets = [
        {"reps": 11, "weight": 2.5, "rir": 4, "target_reps": 11, "target_rir": 4},
        {"reps": 5,  "weight": 2.5, "rir": 0, "target_reps": 11, "target_rir": 4},
    ]
    alert = detect_fatigue(sets, 2.5)
    assert alert.fatigue_detected is True
    assert alert.suggested_weight_reduction == 0
    assert "rest-pause" in alert.reasoning.lower() or "ending" in alert.reasoning.lower()


def test_cooldown_after_two_dismissals():
    sets = _fatigued_session()
    alert = detect_fatigue(sets, 45.0, consecutive_dismissals=2)
    assert alert.fatigue_detected is False
    assert "paused" in alert.reasoning.lower()


def test_increment_rounding_in_user_unit():
    """suggested_weight in lb is rounded to the user's lb increment, not 2.5 kg."""
    sets = _fatigued_session(weight_kg=20.4)  # ≈45 lb
    alert = detect_fatigue(
        sets, 20.4, user_workout_unit="lb", user_increment_kg=2.27,  # 5 lb
    )
    # The lb value should land on a 5-lb boundary.
    assert alert.suggested_weight is not None
    remainder = alert.suggested_weight % 5.0
    assert remainder < 0.05 or abs(remainder - 5.0) < 0.05, alert.suggested_weight
