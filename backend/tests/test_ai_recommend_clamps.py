"""
Focused unit tests for the AI "Recommend Targets" safety-clamp + fail-soft logic.

These tests import ONLY the pure helpers from
`api/v1/nutrition/ai_recommend.py` — NOT the whole app. The local .venv is
Python 3.9 while prod is 3.12, and the `api.v1` package __init__ chain uses
3.10+ `X | None` syntax that errors under 3.9. So we load `ai_recommend.py` as
a standalone module via importlib with the two intra-package imports stubbed in
sys.modules, which sidesteps the package __init__ entirely.

Run with:  pytest backend/tests/test_ai_recommend_clamps.py -v
"""
import importlib.util
import os
import sys
import types

import pytest

BACKEND_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)


def _load_ai_recommend():
    """Load ai_recommend.py in isolation.

    `ai_recommend.py` does two intra-package imports at module top:
      - from api.v1.nutrition.models import (...)
      - from api.v1.nutrition.preferences import _active_meal_types
    Importing the real `api.v1.nutrition.preferences` would trigger the
    `api.v1` package __init__ (which fails under py3.9). So we:
      1. Load models.py standalone (it only needs pydantic + stdlib).
      2. Register a tiny stub `preferences` module exposing _active_meal_types.
      3. Register stub parent packages so the absolute imports resolve to our
         pre-seeded modules instead of executing the real package __init__.
    The clamp + baseline + finalize helpers under test are pure and do not touch
    any of the stubbed parents at call time.
    """
    # 1) Real models module, loaded standalone.
    models_path = os.path.join(BACKEND_DIR, "api", "v1", "nutrition", "models.py")
    models_spec = importlib.util.spec_from_file_location(
        "api.v1.nutrition.models", models_path
    )
    models_mod = importlib.util.module_from_spec(models_spec)

    # 2) Stub parent packages (empty, marked as packages) so submodule imports
    #    resolve without running the real __init__.py files.
    for pkg_name in ("api", "api.v1", "api.v1.nutrition"):
        if pkg_name not in sys.modules:
            pkg = types.ModuleType(pkg_name)
            pkg.__path__ = []  # mark as a package
            sys.modules[pkg_name] = pkg

    sys.modules["api.v1.nutrition.models"] = models_mod
    models_spec.loader.exec_module(models_mod)

    # 3) Stub preferences with the real-ish _active_meal_types contract: 4+ meals
    #    include snacks, 3 meals do not. Mirrors the production helper closely
    #    enough for the finalize tests (per-meal even split + keys).
    prefs_stub = types.ModuleType("api.v1.nutrition.preferences")

    def _active_meal_types(prefs):
        n = None
        raw = (prefs or {}).get("meals_per_day")
        if raw is not None:
            try:
                n = int(raw)
            except (TypeError, ValueError):
                n = None
        if n is None:
            pattern = (prefs or {}).get("meal_pattern")
            if isinstance(pattern, str):
                digits = "".join(ch for ch in pattern if ch.isdigit())
                if digits:
                    n = int(digits)
        if n is None:
            n = 4
        if n >= 4:
            return ["breakfast", "lunch", "dinner", "snacks"]
        return ["breakfast", "lunch", "dinner"]

    prefs_stub._active_meal_types = _active_meal_types
    sys.modules["api.v1.nutrition.preferences"] = prefs_stub

    # 4) Load ai_recommend.py itself.
    ar_path = os.path.join(BACKEND_DIR, "api", "v1", "nutrition", "ai_recommend.py")
    ar_spec = importlib.util.spec_from_file_location(
        "api.v1.nutrition.ai_recommend", ar_path
    )
    ar_mod = importlib.util.module_from_spec(ar_spec)
    sys.modules["api.v1.nutrition.ai_recommend"] = ar_mod
    ar_spec.loader.exec_module(ar_mod)
    return ar_mod


AR = _load_ai_recommend()


# =============================================================================
# Clamp tests
# =============================================================================

def test_low_calorie_daily_is_clamped_to_floor_male():
    """A 900 kcal LLM result for a male is floored at 1500 and surfaced."""
    daily, _pm, _h, _b, clamped = AR.clamp_recommendation(
        daily={"calories": 900, "protein_g": 120, "carbs_g": 60, "fat_g": 30},
        per_meal=None,
        per_day_high=None,
        per_day_base=None,
        weight_kg=80.0,
        gender="male",
    )
    assert daily["calories"] == 1500, "male calorie floor must be 1500"
    assert clamped, "clamped[] must be non-empty when a value is adjusted"
    assert any("calorie" in note.lower() for note in clamped)


def test_low_calorie_daily_is_clamped_to_floor_female():
    """A 900 kcal LLM result for a female is floored at 1200."""
    daily, _pm, _h, _b, clamped = AR.clamp_recommendation(
        daily={"calories": 900, "protein_g": 90, "carbs_g": 60, "fat_g": 30},
        per_meal=None,
        per_day_high=None,
        per_day_base=None,
        weight_kg=60.0,
        gender="female",
    )
    assert daily["calories"] == 1200, "female calorie floor must be 1200"
    assert clamped


def test_protein_below_floor_is_raised():
    """Protein below 0.5 g/kg is raised into range, note added."""
    wkg = 80.0
    daily, _pm, _h, _b, clamped = AR.clamp_recommendation(
        daily={"calories": 2000, "protein_g": 20, "carbs_g": 200, "fat_g": 60},
        per_meal=None, per_day_high=None, per_day_base=None,
        weight_kg=wkg, gender="male",
    )
    assert daily["protein_g"] >= int(round(0.5 * wkg))  # >= 40
    assert any("protein" in n.lower() for n in clamped)


def test_protein_above_ceiling_is_lowered():
    """Protein above 2.5 g/kg is lowered into range."""
    wkg = 80.0
    daily, _pm, _h, _b, clamped = AR.clamp_recommendation(
        daily={"calories": 3000, "protein_g": 400, "carbs_g": 200, "fat_g": 80},
        per_meal=None, per_day_high=None, per_day_base=None,
        weight_kg=wkg, gender="male",
    )
    assert daily["protein_g"] <= int(round(2.5 * wkg))  # <= 200
    assert any("protein" in n.lower() for n in clamped)


def test_fat_below_essential_floor_is_raised():
    """Fat below ~0.3 g/kg essential floor is raised and surfaced (mirrors the
    mockup's '38g fell below the essential-fat floor' clamp note)."""
    wkg = 80.0
    daily, _pm, _h, _b, clamped = AR.clamp_recommendation(
        daily={"calories": 2000, "protein_g": 150, "carbs_g": 200, "fat_g": 10},
        per_meal=None, per_day_high=None, per_day_base=None,
        weight_kg=wkg, gender="male",
    )
    assert daily["fat_g"] >= int(round(0.3 * wkg))  # >= 24
    assert any("fat" in n.lower() for n in clamped)


def test_in_range_values_are_not_clamped():
    """A sane recommendation produces an empty clamped[]."""
    wkg = 80.0
    daily, _pm, _h, _b, clamped = AR.clamp_recommendation(
        daily={"calories": 2200, "protein_g": 160, "carbs_g": 220, "fat_g": 70},
        per_meal=None, per_day_high=None, per_day_base=None,
        weight_kg=wkg, gender="male",
    )
    assert daily == {"calories": 2200, "protein_g": 160, "carbs_g": 220, "fat_g": 70}
    assert clamped == []


def test_per_meal_sum_is_clamped():
    """Per-meal blocks summing to an unsafe total are rescaled; keys preserved."""
    per_meal = {
        "breakfast": {"protein_g": 5, "carbs_g": 5, "fat_g": 2},
        "lunch": {"protein_g": 5, "carbs_g": 5, "fat_g": 2},
        "dinner": {"protein_g": 5, "carbs_g": 5, "fat_g": 2},
    }  # sums to tiny calories -> below floor
    _d, pm, _h, _b, clamped = AR.clamp_recommendation(
        daily={"calories": 2000, "protein_g": 150, "carbs_g": 200, "fat_g": 60},
        per_meal=per_meal, per_day_high=None, per_day_base=None,
        weight_kg=80.0, gender="male",
    )
    assert set(pm.keys()) == {"breakfast", "lunch", "dinner"}, "meal keys must be preserved"
    total_cal = sum(4 * m["protein_g"] + 4 * m["carbs_g"] + 9 * m["fat_g"] for m in pm.values())
    assert total_cal >= 1500, "per-meal total must be floored at the male calorie floor"
    assert clamped


def test_carbs_negative_floored_to_zero():
    _d, _pm, _h, _b, clamped = AR.clamp_recommendation(
        daily={"calories": 2000, "protein_g": 150, "carbs_g": -10, "fat_g": 60},
        per_meal=None, per_day_high=None, per_day_base=None,
        weight_kg=80.0, gender="male",
    )
    assert _d["carbs_g"] == 0
    assert any("carb" in n.lower() for n in clamped)


# =============================================================================
# Deterministic baseline tests
# =============================================================================

def test_deterministic_baseline_respects_calorie_floor():
    """An aggressive fat-loss deficit can't push a small female below 1200."""
    base = AR.deterministic_daily_targets(
        weight_kg=50, height_cm=160, age=30, gender="female",
        activity_level="sedentary", nutrition_goal="lose_fat",
        rate_of_change="aggressive", diet_type="balanced",
    )
    assert base["calories"] >= 1200
    assert base["protein_g"] > 0 and base["carbs_g"] > 0 and base["fat_g"] > 0


def test_deterministic_baseline_uses_adaptive_tdee_anchor():
    """When a plausible adaptive TDEE is supplied it anchors maintenance."""
    base = AR.deterministic_daily_targets(
        weight_kg=80, height_cm=180, age=30, gender="male",
        activity_level="moderately_active", nutrition_goal="maintain",
        rate_of_change=None, diet_type="balanced", adaptive_tdee=2600,
    )
    # maintain + adaptive 2600 -> calories near 2600 (no goal adjustment)
    assert 2500 <= base["calories"] <= 2700


# =============================================================================
# Fail-soft (finalize with ai=None) tests
# =============================================================================

def test_fail_soft_returns_low_confidence_deterministic_rec():
    """When the LLM result is None, finalize returns a deterministic rec with
    confidence 'low', all sections populated, and clamps applied."""
    baseline = AR.deterministic_daily_targets(
        weight_kg=80, height_cm=180, age=30, gender="male",
        activity_level="moderately_active", nutrition_goal="maintain",
        rate_of_change=None, diet_type="balanced",
    )
    raw_facts = {
        "weight_kg": 80,
        "gender": "male",
        "baseline": baseline,
        "current_targets": {"calories": 2000, "protein_g": 150, "carbs_g": 200, "fat_g": 65},
        "window_days": 14,
        "logged_days": 3,
        "training_day_names": ["Mon", "Wed", "Fri"],
    }
    rec = AR._finalize_recommendation(
        ai=None,
        raw_facts=raw_facts,
        active_meals=["breakfast", "lunch", "dinner"],
        training_days=[0, 2, 4],
    )
    assert rec.confidence == "low", "fail-soft must surface low confidence"
    assert rec.daily.calories >= 1500, "fail-soft daily still respects the floor"
    assert rec.daily.current.calories == 2000, "current target echoed for delta display"
    assert rec.daily.current.protein_g == 150
    assert set(rec.per_meal.meals.keys()) == {"breakfast", "lunch", "dinner"}
    # per_day high_days must equal the deterministic training-day set (0=Mon..6=Sun)
    assert rec.per_day.high_days == [0, 2, 4]
    assert rec.per_day.bind_to_training_days is True
    assert rec.basis, "basis is never blank"
    assert "Based on 14 days" in rec.basis


def test_finalize_with_llm_clamps_out_of_range_llm_values():
    """A finalize over an out-of-range LLM object clamps daily + flags clamped[]."""
    # Build the LLM response object from the module's own schema.
    ai = AR._AIRecommendationResponse(
        confidence="high",
        basis="Based on 14 days · 12 logged · weight -0.3 kg/wk · trains Mon/Wed/Fri",
        daily=AR._AIDailyBlock(
            calories=900, protein_g=120, carbs_g=60, fat_g=20,
            reasoning="Cutting hard.",
        ),
        per_meal=AR._AIPerMealBlock(enabled_suggested=False, meals={}, reasoning="x"),
        per_day=AR._AIPerDayBlock(enabled_suggested=False, reasoning="y"),
    )
    raw_facts = {
        "weight_kg": 80, "gender": "male", "baseline": {},
        "current_targets": {"calories": 2000, "protein_g": 150, "carbs_g": 200, "fat_g": 65},
        "window_days": 14, "logged_days": 12, "training_day_names": ["Mon", "Wed", "Fri"],
        "weekly_rate_kg": -0.3,
    }
    rec = AR._finalize_recommendation(
        ai=ai,
        raw_facts=raw_facts,
        active_meals=["breakfast", "lunch", "dinner"],
        training_days=[0, 2, 4],
    )
    assert rec.daily.calories == 1500, "out-of-range 900 kcal LLM result clamped to floor"
    assert rec.clamped, "clamped[] must list the adjustment"
    assert rec.confidence == "high", "LLM confidence preserved when in the allowed set"
    # LLM basis is preferred verbatim when present
    assert rec.basis == ai.basis


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))
