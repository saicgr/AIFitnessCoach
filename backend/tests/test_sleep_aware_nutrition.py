"""
Unit tests for sleep-aware nutrition (Phase E1).

Covers the deterministic recovery -> macro-target adjustment and the
caffeine / alcohol / heavy-meal sleep-risk classifier. Drives the Phase E1
verification matrix + edge cases G35 / G36:

  * a low-recovery day shifts protein up and keeps the FINAL calorie target
    above the deficit floor (and never raises the calorie total),
  * an 8h-sleep / good-recovery day leaves targets unchanged,
  * no recovery data => targets unchanged (G35),
  * a 9pm coffee inside the wind-down window flags,
  * an unknown / decaf item does NOT flag (G36 — no false alarms).
"""
from datetime import datetime

from services.sleep_aware_nutrition import (
    adjust_targets_for_recovery,
    classify_sleep_risk,
    flag_food_items_for_sleep,
)


# Tier dicts shaped exactly like health_activity.get_health_activity_snapshot()
# returns under the "recovery" key.
_LOW = {"score": 22, "tier": "low", "volume_multiplier": 0.55,
        "adjustment": "swap to mobility/recovery, -15% load"}
_GOOD = {"score": 74, "tier": "good", "volume_multiplier": 1.0,
         "adjustment": "as planned"}
_MODERATE = {"score": 52, "tier": "moderate", "volume_multiplier": 0.85,
             "adjustment": "longer rest, trim 1 accessory set"}

# A cutting target set: TDEE ~2400, target 1900 => a 500 kcal/day deficit
# (= ~0.45 kg/wk x 7700 / 7). Macros are kcal-consistent with the 1900 target:
# 165g P (660) + 175g C (700) + 60g F (540) = 1900 kcal.
_CUTTING_TARGETS = {
    "daily_calorie_target": 1900,
    "daily_protein_target_g": 165,
    "daily_carbs_target_g": 175,
    "daily_fat_target_g": 60,
}


# ── Recovery -> target adjustment ──────────────────────────────────────────

def test_low_recovery_shifts_protein_up_and_holds_calories():
    """A low-recovery day raises protein and keeps the calorie total constant
    so the cutting deficit is fully preserved."""
    result = adjust_targets_for_recovery(_CUTTING_TARGETS, _LOW)

    assert result["adjusted"] is True
    assert result["reason"] == "low_recovery"
    assert result["tier"] == "low"

    t = result["targets"]
    # +15% protein for the "low" tier.
    assert t["daily_protein_target_g"] > _CUTTING_TARGETS["daily_protein_target_g"]
    assert t["daily_protein_target_g"] == round(165 * 1.15)  # 190
    assert result["protein_delta_g"] == round(165 * 0.15)    # 25

    # Calorie TOTAL is unchanged => the 500 kcal/day deficit is intact.
    assert t["daily_calorie_target"] == _CUTTING_TARGETS["daily_calorie_target"]
    assert result["calorie_floored"] is False

    # Carbs + fat were trimmed to pay for the extra protein.
    assert t["daily_carbs_target_g"] < _CUTTING_TARGETS["daily_carbs_target_g"]
    assert t["daily_fat_target_g"] < _CUTTING_TARGETS["daily_fat_target_g"]

    # A craving heads-up is surfaced for a low-recovery day.
    assert result["craving_heads_up"]


def test_low_recovery_calorie_total_is_kcal_neutral():
    """The re-allocated macros still sum (within rounding) to the original
    macro-kcal total — the protein bump is paid for out of carbs/fat, never
    by adding calories, so the cutting deficit is preserved."""
    before = (
        _CUTTING_TARGETS["daily_protein_target_g"] * 4
        + _CUTTING_TARGETS["daily_carbs_target_g"] * 4
        + _CUTTING_TARGETS["daily_fat_target_g"] * 9
    )
    result = adjust_targets_for_recovery(_CUTTING_TARGETS, _LOW)
    t = result["targets"]
    after = (
        t["daily_protein_target_g"] * 4
        + t["daily_carbs_target_g"] * 4
        + t["daily_fat_target_g"] * 9
    )
    # Allow a few kcal of integer-rounding slack across three macros.
    assert abs(after - before) <= 12
    # And the stored calorie target itself never moves.
    assert t["daily_calorie_target"] == _CUTTING_TARGETS["daily_calorie_target"]


def test_final_calorie_target_floored_never_clamps_deficit():
    """When the base target is already under the 1200 kcal safety floor the
    FINAL target is floored to 1200 — the floor applies to the target only."""
    aggressive = {
        "daily_calorie_target": 1050,   # below the 1200 floor
        "daily_protein_target_g": 120,
        "daily_carbs_target_g": 80,
        "daily_fat_target_g": 35,
    }
    result = adjust_targets_for_recovery(aggressive, _LOW)
    assert result["adjusted"] is True
    assert result["calorie_floored"] is True
    assert result["targets"]["daily_calorie_target"] == 1200
    # Protein still bumped — the floor doesn't suppress the adjustment.
    assert result["targets"]["daily_protein_target_g"] == round(120 * 1.15)


def test_good_recovery_leaves_targets_unchanged():
    """An 8h-sleep / good-recovery day => no adjustment at all."""
    result = adjust_targets_for_recovery(_CUTTING_TARGETS, _GOOD)
    assert result["adjusted"] is False
    assert result["reason"] == "recovery_ok"
    assert result["targets"] == _CUTTING_TARGETS
    assert result["craving_heads_up"] is None
    assert result["protein_delta_g"] == 0


def test_no_recovery_data_leaves_targets_unchanged():
    """Edge case G35 — no recovery data => targets echoed back verbatim."""
    for missing in (None, {}, {"score": None, "tier": None}):
        result = adjust_targets_for_recovery(_CUTTING_TARGETS, missing)
        assert result["adjusted"] is False
        assert result["reason"] == "no_recovery_data"
        assert result["targets"] == _CUTTING_TARGETS


def test_moderate_recovery_uses_smaller_protein_bump():
    """A moderate tier gets the +10% bump, not the +15% low-tier bump."""
    result = adjust_targets_for_recovery(_CUTTING_TARGETS, _MODERATE)
    assert result["adjusted"] is True
    assert result["targets"]["daily_protein_target_g"] == round(165 * 1.10)


def test_renal_restriction_suppresses_protein_bump():
    """A renal / low-protein dietary restriction suppresses the protein bump
    even on a low-recovery day."""
    result = adjust_targets_for_recovery(
        _CUTTING_TARGETS, _LOW, dietary_restrictions=["Renal diet"]
    )
    assert result["adjusted"] is False
    assert result["reason"] == "restricted"
    assert result["targets"] == _CUTTING_TARGETS


def test_unrelated_restriction_does_not_suppress_bump():
    """A vegan / gluten-free restriction does NOT block the protein bump."""
    result = adjust_targets_for_recovery(
        _CUTTING_TARGETS, _LOW, dietary_restrictions=["vegan", "gluten-free"]
    )
    assert result["adjusted"] is True
    assert result["targets"]["daily_protein_target_g"] > 165


# ── Sleep-risk classifier ──────────────────────────────────────────────────

def test_classify_caffeine_alcohol_heavy_meal():
    assert classify_sleep_risk({"name": "Iced Coffee"})["risk_type"] == "caffeine"
    assert classify_sleep_risk({"name": "Red Wine"})["risk_type"] == "alcohol"
    assert classify_sleep_risk(
        {"name": "Loaded Burrito", "calories": 950}
    )["risk_type"] == "heavy_meal"


def test_classify_unknown_item_is_not_flagged():
    """Edge case G36 — unrecognised content yields no risk type."""
    assert classify_sleep_risk({"name": "Grilled Chicken Salad"})["risk_type"] is None
    assert classify_sleep_risk({"name": "Apple", "calories": 95})["risk_type"] is None
    assert classify_sleep_risk({})["risk_type"] is None


def test_classify_decaf_and_mocktail_clear_the_flag():
    """Decaf coffee and non-alcoholic drinks must NOT trip the flags."""
    assert classify_sleep_risk({"name": "Decaf Latte"})["risk_type"] is None
    assert classify_sleep_risk({"name": "Virgin Mojito"})["risk_type"] is None
    assert classify_sleep_risk({"name": "Non-Alcoholic Beer"})["risk_type"] is None


# ── Wind-down window flagging ──────────────────────────────────────────────

def test_nine_pm_coffee_flags_against_an_11pm_bedtime():
    """A 9pm coffee is ~2h before an 11pm bedtime — inside the 6h caffeine
    wind-down window => flagged."""
    logged = datetime(2026, 5, 21, 21, 0, 0)  # 9:00 PM local
    result = flag_food_items_for_sleep(
        [{"name": "Cold Brew Coffee", "calories": 15}],
        logged,
        "23:00",
    )
    assert result["has_flag"] is True
    assert len(result["flags"]) == 1
    assert result["flags"][0]["risk_type"] == "caffeine"
    assert result["message"]


def test_unknown_item_at_nine_pm_does_not_flag():
    """Edge case G36 — an unknown item logged near bedtime raises no flag."""
    logged = datetime(2026, 5, 21, 21, 0, 0)
    result = flag_food_items_for_sleep(
        [{"name": "Greek Yogurt", "calories": 120}],
        logged,
        "23:00",
    )
    assert result["has_flag"] is False
    assert result["flags"] == []
    assert result["message"] is None


def test_morning_coffee_does_not_flag():
    """An 8am coffee is far outside any wind-down window => no flag."""
    logged = datetime(2026, 5, 21, 8, 0, 0)
    result = flag_food_items_for_sleep(
        [{"name": "Espresso"}],
        logged,
        "23:00",
    )
    assert result["has_flag"] is False


def test_no_bedtime_goal_means_no_flag():
    """Without a bedtime goal we cannot place a wind-down window => no flag."""
    logged = datetime(2026, 5, 21, 21, 0, 0)
    result = flag_food_items_for_sleep([{"name": "Latte"}], logged, None)
    assert result["has_flag"] is False


def test_late_heavy_meal_flags_inside_three_hour_window():
    """A 900 kcal meal logged ~1h before bed is inside the 3h heavy-meal
    window => flagged."""
    logged = datetime(2026, 5, 21, 22, 0, 0)  # 1h before 23:00 bedtime
    result = flag_food_items_for_sleep(
        [{"name": "Double Cheeseburger Combo", "calories": 1100}],
        logged,
        "23:00",
    )
    assert result["has_flag"] is True
    assert result["flags"][0]["risk_type"] == "heavy_meal"


def test_alcohol_outside_window_does_not_flag():
    """A beer at 6pm is >3h before an 11pm bedtime => no alcohol flag."""
    logged = datetime(2026, 5, 21, 18, 0, 0)
    result = flag_food_items_for_sleep(
        [{"name": "IPA Beer"}],
        logged,
        "23:00",
    )
    assert result["has_flag"] is False


if __name__ == "__main__":
    import sys
    import traceback

    fns = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for fn in fns:
        try:
            fn()
            print(f"PASS  {fn.__name__}")
        except Exception:
            failed += 1
            print(f"FAIL  {fn.__name__}")
            traceback.print_exc()
    print(f"\n{len(fns) - failed}/{len(fns)} passed")
    sys.exit(1 if failed else 0)
