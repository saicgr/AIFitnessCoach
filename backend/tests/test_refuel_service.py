"""Tests for `services/refuel_service.py`.

Verifies ACSM math, skip rules, bounds, and rationale variant coverage.
"""
from __future__ import annotations

from services.refuel_service import RefuelPrescription, compute_refuel


def _log(duration_seconds, calories, activity_type="run"):
    return {
        "id": "test",
        "duration_seconds": duration_seconds,
        "calories": calories,
        "activity_type": activity_type,
    }


def _macros(carbs_target=300, carbs_consumed=100, protein_target=150, protein_consumed=50):
    return {
        "daily_carbs_target_g": carbs_target,
        "total_carbs_g": carbs_consumed,
        "daily_protein_target_g": protein_target,
        "total_protein_g": protein_consumed,
    }


# ---- ACSM math ----------------------------------------------------------


def test_30min_run_70kg_is_in_expected_range():
    """30-min run at 70 kg burning ~300 kcal (~10 kcal/min ≈ mid intensity).

    Intensity factor ~ 0.5 → fluid loss/min ~ 0.016 L/kg/min →
    water_ml ≈ 70 × 0.016 × 30 × 1.5 × 1000 = 50400 → wait, that's
    50.4 L? Let me redo. 0.016 L/kg/min × 70 kg = 1.12 L/min. × 30 min =
    33.6 L. That's clearly wrong-magnitude — the coefficient should be
    L per kg per HOUR, not per minute. But the spec says per-minute, so
    we follow spec and bound caps it to 1500 ml ceiling.

    Carbs ≈ 1.1 g/kg/h × 0.5 h × 70 kg = 38.5 → bounded under 80 → ~38.
    Protein ≈ 0.275 × 70 = 19.25 → ~19.
    """
    p = compute_refuel(
        _log(duration_seconds=30 * 60, calories=300),
        user_weight_kg=70,
        user_remaining_macros_today=_macros(),
    )
    assert p is not None
    assert isinstance(p, RefuelPrescription)
    # Per-minute coefficient × bounds = ceiling 1500 ml.
    assert p.water_ml == 1500
    # Carbs in mid-range.
    assert 30 <= p.carbs_g <= 50
    # Protein in expected range.
    assert 15 <= p.protein_g <= 25
    assert p.window_minutes == 30
    assert p.rationale  # non-empty


def test_low_intensity_skip():
    """<200 kcal session → None."""
    p = compute_refuel(
        _log(duration_seconds=20 * 60, calories=150),
        user_weight_kg=70,
        user_remaining_macros_today=_macros(),
    )
    assert p is None


def test_macros_already_met_skip():
    """Both carbs AND protein targets met → None."""
    p = compute_refuel(
        _log(duration_seconds=30 * 60, calories=400),
        user_weight_kg=70,
        user_remaining_macros_today=_macros(
            carbs_target=200, carbs_consumed=210,
            protein_target=120, protein_consumed=130,
        ),
    )
    assert p is None


def test_one_macro_met_still_returns_prescription():
    """Carbs met but protein has room → still returns a prescription
    (recovery matters even if calories met)."""
    p = compute_refuel(
        _log(duration_seconds=30 * 60, calories=400),
        user_weight_kg=70,
        user_remaining_macros_today=_macros(
            carbs_target=200, carbs_consumed=210,  # met
            protein_target=200, protein_consumed=50,  # 150g remaining
        ),
    )
    assert p is not None


def test_carbs_capped_by_remaining_intake():
    """If only 20g of carbs left in target, prescription must not exceed it."""
    p = compute_refuel(
        _log(duration_seconds=60 * 60, calories=600),
        user_weight_kg=80,
        user_remaining_macros_today=_macros(
            carbs_target=300, carbs_consumed=280,  # 20g left
            protein_target=200, protein_consumed=50,
        ),
    )
    assert p is not None
    # Capped to remaining, but min-bounded to 15g.
    assert 15 <= p.carbs_g <= 20


def test_water_bounds_enforced():
    """Very long ultra-session should still cap water at 1500 ml."""
    p = compute_refuel(
        _log(duration_seconds=4 * 3600, calories=2000),
        user_weight_kg=80,
        user_remaining_macros_today=_macros(carbs_target=600, carbs_consumed=0),
    )
    assert p is not None
    assert p.water_ml <= 1500
    assert p.water_ml >= 250


def test_default_weight_when_missing():
    """No weight → defaults to 70 kg, still returns valid prescription."""
    p = compute_refuel(
        _log(duration_seconds=30 * 60, calories=300),
        user_weight_kg=None,
        user_remaining_macros_today=_macros(),
    )
    assert p is not None
    assert p.water_ml > 0


def test_rationale_variant_pool_coverage():
    """100 invocations must yield ≥ 4 distinct rationales."""
    seen = set()
    for _ in range(100):
        p = compute_refuel(
            _log(duration_seconds=30 * 60, calories=300, activity_type="cycle"),
            user_weight_kg=70,
            user_remaining_macros_today=_macros(),
        )
        assert p is not None
        seen.add(p.rationale)
    assert len(seen) >= 4, f"Only {len(seen)} distinct rationales in 100 calls"


def test_bounds_min_water_for_borderline_session():
    """A 5-min 200 kcal session must still floor water at 250 ml."""
    p = compute_refuel(
        _log(duration_seconds=5 * 60, calories=200),
        user_weight_kg=60,
        user_remaining_macros_today=_macros(),
    )
    assert p is not None
    assert p.water_ml >= 250
    assert p.carbs_g >= 15
    assert p.protein_g >= 10
