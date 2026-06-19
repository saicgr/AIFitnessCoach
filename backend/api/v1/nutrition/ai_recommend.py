"""
AI "Recommend Targets" endpoint.

POST /nutrition/ai-recommend-targets

A Full-AI recommendation: the LLM proposes ABSOLUTE Daily / Per-Meal / Per-Day
nutrition targets from the user's assembled context (profile + weight trend +
adaptive-TDEE reference + logging adherence + meal-time distribution + training
schedule). Every value the model returns is then run through a non-negotiable
safety clamp (calorie floor, sane protein/fat/carb g·kg bounds); any value the
clamp adjusts is surfaced in `clamped[]`.

Design:
  - Context assembly REUSES existing services — it does not rebuild profile /
    targets / weight-trend / adherence / training-day logic.
  - The LLM glue mirrors the proven `body_analyzer.generate_program_retune`
    structured-output pattern (Gemini `response_schema` + a final bounded apply).
  - per_day.high_days is computed DETERMINISTICALLY from the user's training
    schedule (gym_profiles.workout_days, 0=Mon..6=Sun) so it always matches the
    backend dynamic-targets resolver — the model only chooses the high/base
    macro values, never the day set.
  - per_meal.meals is keyed ONLY by the user's active meal ids so the keys drop
    straight into per_meal_macro_targets.overrides on the frontend.
  - FAIL-SOFT: if the LLM call/parse fails, a deterministic Mifflin + adaptive
    recommendation is returned with confidence "low". NEVER 500, never blank.
  - Cache/persist: the full response is held in a short-TTL cache keyed by
    user+local-day (the authoritative cache — repeat taps return cached:true
    unless force=true). The daily scalars are ALSO best-effort persisted into the
    existing `weekly_nutrition_recommendations` table (no schema change) so the
    weekly-checkin surface + history see the AI rec.

The clamp + deterministic-baseline helpers are import-safe with no app/Gemini
side effects so the focused unit test can import them directly.
"""
from __future__ import annotations

import json
import logging
from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

from api.v1.nutrition.models import (
    AIRecommendTargetsRequest,
    CurrentDailyTarget,
    DailyTargetBlock,
    MacroTriple,
    NutritionTargetsRecommendation,
    PerDayRecommendation,
    PerMealRecommendation,
)
from api.v1.nutrition.preferences import _active_meal_types

logger = logging.getLogger("nutrition_ai_recommend")

router = APIRouter()

# Canonical 0=Mon..6=Sun day abbreviations for human `basis`/clamp notes.
_DAY_ABBR = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

# Activity multipliers — kept in sync with onboarding.recalculate_nutrition_targets.
_ACTIVITY_MULTIPLIERS = {
    "sedentary": 1.2,
    "lightly_active": 1.375,
    "moderately_active": 1.55,
    "very_active": 1.725,
    "extra_active": 1.9,
}

# Goal → calorie adjustment (kcal/day), in sync with onboarding.
_GOAL_ADJUSTMENTS = {
    "lose_fat": -500,
    "build_muscle": 300,
    "maintain": 0,
    "improve_energy": 0,
    "eat_healthier": 0,
    "recomposition": -200,
}

# Diet → (carb%, protein%, fat%), in sync with onboarding.
_DIET_MACROS = {
    "no_diet": (45, 25, 30),
    "balanced": (45, 25, 30),
    "low_carb": (25, 35, 40),
    "keto": (5, 25, 70),
    "high_protein": (35, 40, 25),
    "mediterranean": (45, 20, 35),
    "vegan": (55, 20, 25),
    "vegetarian": (50, 20, 30),
    "lacto_ovo": (50, 22, 28),
    "pescatarian": (45, 25, 30),
    "flexitarian": (45, 25, 30),
    "part_time_veg": (50, 20, 30),
}


# =============================================================================
# Safety clamps (import-safe; unit-tested directly)
# =============================================================================

def _bound(value: float, lo: float, hi: float) -> int:
    """Clamp `value` into [lo, hi] and round to int. Mirrors
    body_analyzer._bounded but operates on an absolute value (not base+delta)."""
    return int(round(max(lo, min(hi, value))))


def _calorie_floor(gender: Optional[str]) -> int:
    """Absolute minimum daily calories. 1200 (female) / 1500 (male/unknown)."""
    g = (gender or "").strip().lower()
    return 1200 if g in ("female", "f", "woman") else 1500


def _protein_bounds_g(weight_kg: float) -> Tuple[float, float]:
    """Sane protein window in grams for a bodyweight: ~0.5–2.5 g/kg."""
    return 0.5 * weight_kg, 2.5 * weight_kg


def _fat_bounds_g(weight_kg: float, calories: int) -> Tuple[float, float]:
    """Fat window in grams: floor = essential-fat ~0.3 g/kg; ceiling = ~45% kcal."""
    lo = 0.3 * weight_kg
    hi = (0.45 * max(calories, 0)) / 9.0
    if hi < lo:
        # Degenerate (very low calories): keep the essential-fat floor as both
        # bounds so we never invert the clamp window.
        hi = lo
    return lo, hi


def clamp_recommendation(
    *,
    daily: Dict[str, int],
    per_meal: Optional[Dict[str, Dict[str, int]]],
    per_day_high: Optional[Dict[str, int]],
    per_day_base: Optional[Dict[str, int]],
    weight_kg: float,
    gender: Optional[str],
) -> Tuple[Dict[str, int], Optional[Dict[str, Dict[str, int]]], Optional[Dict[str, int]], Optional[Dict[str, int]], List[str]]:
    """Apply the non-negotiable safety clamps to a recommendation in place-free
    form and return (daily, per_meal, high, base, clamped_notes).

    Clamps applied to the DAILY block AND each per-meal block sum AND the per-day
    high/base blocks:
      - calories floored at 1200(F)/1500(M)
      - protein in ~0.5–2.5 g/kg bodyweight
      - fat >= ~0.3 g/kg (essential floor) and <= ~45% of kcal
      - carbs >= 0

    Every value the clamp moves appends a human note to clamped_notes.

    This function is pure (no I/O) so the unit test can import + assert it.
    """
    notes: List[str] = []
    wkg = max(1.0, float(weight_kg or 0))
    p_lo, p_hi = _protein_bounds_g(wkg)
    cal_floor = _calorie_floor(gender)

    # ── Daily ────────────────────────────────────────────────────────────────
    d_cal = int(daily.get("calories") or 0)
    d_p = int(daily.get("protein_g") or 0)
    d_c = int(daily.get("carbs_g") or 0)
    d_f = int(daily.get("fat_g") or 0)

    new_cal = _bound(d_cal, cal_floor, 6000)
    if new_cal != d_cal:
        notes.append(
            f"Daily calories adjusted to {new_cal} — the AI's {d_cal} fell "
            f"{'below the safe floor' if new_cal > d_cal else 'above a sane ceiling'} for you."
        )
    new_p = _bound(d_p, p_lo, p_hi)
    if new_p != d_p:
        notes.append(
            f"Daily protein set to {new_p}g — the AI's {d_p}g was outside the "
            f"safe {int(round(p_lo))}–{int(round(p_hi))}g range for your weight."
        )
    f_lo, f_hi = _fat_bounds_g(wkg, new_cal)
    new_f = _bound(d_f, f_lo, f_hi)
    if new_f != d_f:
        notes.append(
            f"Daily fat set to {new_f}g — the AI's {d_f}g fell "
            f"{'below the essential-fat floor' if new_f > d_f else 'above ~45% of calories'} for you."
        )
    new_c = max(0, d_c)
    if new_c != d_c:
        notes.append(f"Daily carbs floored at 0g (the AI returned {d_c}g).")
    daily_out = {"calories": new_cal, "protein_g": new_p, "carbs_g": new_c, "fat_g": new_f}

    # ── Per-meal (clamp the SUM, not each meal individually) ──────────────────
    per_meal_out: Optional[Dict[str, Dict[str, int]]] = None
    if per_meal:
        per_meal_out = {}
        sum_p = sum(int((m or {}).get("protein_g") or 0) for m in per_meal.values())
        sum_c = sum(int((m or {}).get("carbs_g") or 0) for m in per_meal.values())
        sum_f = sum(int((m or {}).get("fat_g") or 0) for m in per_meal.values())
        sum_cal = 4 * sum_p + 4 * sum_c + 9 * sum_f

        target_p = _bound(sum_p, p_lo, p_hi)
        target_cal = _bound(sum_cal, cal_floor, 6000)
        sf_lo, sf_hi = _fat_bounds_g(wkg, target_cal)
        target_f = _bound(sum_f, sf_lo, sf_hi)
        target_c = max(0, sum_c)

        # Enforce the calorie FLOOR on the per-meal block as a whole. Protein and
        # fat are bounded by g·kg, so a too-low total is corrected by topping up
        # carbs (the free macro) until 4P+4C+9F reaches the floor. A too-high
        # total is already handled because target_cal caps at 6000 and the macro
        # ceilings bind protein/fat.
        macro_cal = 4 * target_p + 4 * target_c + 9 * target_f
        if macro_cal < target_cal:
            target_c += int(round((target_cal - macro_cal) / 4.0))

        # Scale each meal's macros to keep the user's split shape while landing
        # on the clamped totals. If a sum was 0, distribute evenly.
        meal_ids = list(per_meal.keys())
        n = len(meal_ids) or 1

        def _scaled(field: str, sum_val: int, target_val: int) -> Dict[str, int]:
            out: Dict[str, int] = {}
            if sum_val > 0:
                for mid in meal_ids:
                    v = int((per_meal.get(mid) or {}).get(field) or 0)
                    out[mid] = int(round(v * target_val / sum_val))
            else:
                each = int(round(target_val / n))
                for mid in meal_ids:
                    out[mid] = each
            return out

        p_map = _scaled("protein_g", sum_p, target_p)
        c_map = _scaled("carbs_g", sum_c, target_c)
        f_map = _scaled("fat_g", sum_f, target_f)
        for mid in meal_ids:
            per_meal_out[mid] = {
                "protein_g": max(0, p_map.get(mid, 0)),
                "carbs_g": max(0, c_map.get(mid, 0)),
                "fat_g": max(0, f_map.get(mid, 0)),
            }

        if target_p != sum_p or target_f != sum_f or target_c != sum_c or target_cal != sum_cal:
            notes.append(
                "Per-meal split rescaled to keep total protein/fat/calories in a safe range."
            )

    # ── Per-day high / base ───────────────────────────────────────────────────
    def _clamp_day(block: Optional[Dict[str, int]], label: str) -> Optional[Dict[str, int]]:
        if not block:
            return None
        bp = int(block.get("protein_g") or 0)
        bc = int(block.get("carbs_g") or 0)
        bf = int(block.get("fat_g") or 0)
        b_cal = 4 * bp + 4 * bc + 9 * bf

        new_bp = _bound(bp, p_lo, p_hi)
        c_cal = _bound(b_cal, cal_floor, 6000)
        df_lo, df_hi = _fat_bounds_g(wkg, c_cal)
        new_bf = _bound(bf, df_lo, df_hi)
        new_bc = max(0, bc)
        if new_bp != bp or new_bf != bf or new_bc != bc:
            notes.append(
                f"{label.capitalize()}-day macros adjusted to stay within safe protein/fat bounds."
            )
        return {"protein_g": new_bp, "carbs_g": new_bc, "fat_g": new_bf}

    high_out = _clamp_day(per_day_high, "high")
    base_out = _clamp_day(per_day_base, "base")

    return daily_out, per_meal_out, high_out, base_out, notes


# =============================================================================
# Deterministic baseline (fail-soft; import-safe; unit-tested directly)
# =============================================================================

def deterministic_daily_targets(
    *,
    weight_kg: float,
    height_cm: float,
    age: int,
    gender: Optional[str],
    activity_level: Optional[str],
    nutrition_goal: Optional[str],
    rate_of_change: Optional[str],
    diet_type: Optional[str],
    adaptive_tdee: Optional[int] = None,
) -> Dict[str, int]:
    """Mifflin-St Jeor BMR → TDEE (or the adaptive-TDEE reference when present)
    → goal-adjusted calories → macro split. Mirrors
    onboarding.recalculate_nutrition_targets so the fail-soft path matches the
    deterministic "Recalculate from profile" the user already trusts.

    Pure / no I/O — safe to import in tests.
    """
    wkg = float(weight_kg or 70)
    hcm = float(height_cm or 170)
    a = int(age or 30)
    g = (gender or "male").strip().lower()

    if g == "male":
        bmr = int((10 * wkg) + (6.25 * hcm) - (5 * a) + 5)
    else:
        bmr = int((10 * wkg) + (6.25 * hcm) - (5 * a) - 161)

    mult = _ACTIVITY_MULTIPLIERS.get((activity_level or "moderately_active"), 1.55)
    tdee = int(bmr * mult)
    # Prefer the measured adaptive TDEE as the energy anchor when it's available
    # and plausible (the user's real maintenance from logs + weight trend).
    if adaptive_tdee and adaptive_tdee >= 1000:
        tdee = int(adaptive_tdee)

    goal = (nutrition_goal or "maintain")
    adjustment = _GOAL_ADJUSTMENTS.get(goal, 0)

    # Deficit/surplus from selected weekly rate — Wishnofsky 7700 kcal/kg.
    rate_kg = {"slow": 0.25, "moderate": 0.5, "fast": 0.75, "aggressive": 1.0}
    if rate_of_change in rate_kg:
        deficit = round(rate_kg[rate_of_change] * 7700 / 7)
        if goal == "lose_fat":
            adjustment = -deficit
        elif goal == "build_muscle":
            adjustment = deficit // 2

    floor = _calorie_floor(g)
    calories = max(floor, tdee + adjustment)

    carb_pct, protein_pct, fat_pct = _DIET_MACROS.get((diet_type or "balanced"), (45, 25, 30))
    protein = int((calories * protein_pct / 100) / 4)
    carbs = int((calories * carb_pct / 100) / 4)
    fat = int((calories * fat_pct / 100) / 9)

    return {"calories": int(calories), "protein_g": protein, "carbs_g": carbs, "fat_g": fat}


def _split_daily_to_meals(daily: Dict[str, int], meal_ids: List[str]) -> Dict[str, Dict[str, int]]:
    """Even split of the daily P/C/F across the active meals — the deterministic
    fallback per-meal shape (the auto split the dynamic-targets endpoint uses)."""
    n = len(meal_ids) or 1
    p = int(daily.get("protein_g") or 0)
    c = int(daily.get("carbs_g") or 0)
    f = int(daily.get("fat_g") or 0)
    return {
        mid: {
            "protein_g": int(round(p / n)),
            "carbs_g": int(round(c / n)),
            "fat_g": int(round(f / n)),
        }
        for mid in meal_ids
    }


# =============================================================================
# Gemini structured-output schema + call (mirrors generate_program_retune)
# =============================================================================

class _AIMacroTriple(BaseModel):
    protein_g: int = Field(default=0, ge=0)
    carbs_g: int = Field(default=0, ge=0)
    fat_g: int = Field(default=0, ge=0)


class _AIDailyBlock(BaseModel):
    calories: int = Field(default=0, ge=0)
    protein_g: int = Field(default=0, ge=0)
    carbs_g: int = Field(default=0, ge=0)
    fat_g: int = Field(default=0, ge=0)
    reasoning: str = Field(default="", description="Coach-voice reason, <=3 sentences.")


class _AIPerMealBlock(BaseModel):
    enabled_suggested: bool = False
    # Keyed by active meal id (breakfast/lunch/dinner/snacks). The model is told
    # which keys to use; unknown keys are dropped on the server.
    meals: Dict[str, _AIMacroTriple] = Field(default_factory=dict)
    reasoning: str = Field(default="", description="Coach-voice reason, <=3 sentences.")


class _AIPerDayBlock(BaseModel):
    enabled_suggested: bool = False
    high: _AIMacroTriple = Field(default_factory=_AIMacroTriple)
    base: _AIMacroTriple = Field(default_factory=_AIMacroTriple)
    reasoning: str = Field(default="", description="Coach-voice reason, <=3 sentences.")


class _AIRecommendationResponse(BaseModel):
    """The structured object the LLM returns. high_days is NOT modeled here —
    it's computed deterministically from the training schedule server-side."""
    confidence: str = Field(default="medium", description='one of "high" | "medium" | "low"')
    basis: str = Field(default="", description="One-line summary of the data the rec is based on.")
    daily: _AIDailyBlock = Field(default_factory=_AIDailyBlock)
    per_meal: _AIPerMealBlock = Field(default_factory=_AIPerMealBlock)
    per_day: _AIPerDayBlock = Field(default_factory=_AIPerDayBlock)


async def _generate_ai_targets(
    *,
    context: Dict[str, Any],
    active_meals: List[str],
    user_id: Optional[str],
    model: Optional[str] = None,
) -> _AIRecommendationResponse:
    """Ask Gemini for absolute Daily / Per-Meal / Per-Day targets.

    Mirrors body_analyzer.generate_program_retune: response_schema-bound JSON +
    a deterministic-TDEE anchor in the prompt. Raises on failure so the caller
    can fall back deterministically.
    """
    from google.genai import types
    from core.config import get_settings
    from services.gemini.constants import gemini_generate_with_retry

    settings = get_settings()
    model = model or settings.gemini_model

    meal_id_list = ", ".join(active_meals) if active_meals else "breakfast, lunch, dinner"

    prompt = f"""You are a registered-dietitian-grade AI nutrition coach. Propose concrete
nutrition targets for this athlete from their data below. Write the ABSOLUTE numbers
yourself (this is full-AI, not a formula) but stay physiologically sane — a deterministic
Mifflin/adaptive estimate is given as an anchor, not a number to copy.

USER PROFILE:
{json.dumps(context.get("profile", {}), default=str, indent=2)}

CURRENT TARGETS (what they're on now):
{json.dumps(context.get("current_targets", {}), default=str, indent=2)}

DETERMINISTIC REFERENCE ANCHOR (Mifflin BMR→TDEE→goal, and adaptive TDEE from logs+weight):
{json.dumps(context.get("reference", {}), default=str, indent=2)}

WEIGHT TREND:
{json.dumps(context.get("weight_trend", {}), default=str, indent=2)}

LOGGING ADHERENCE + WHEN THEY EAT (meal-time calorie distribution over the window):
{json.dumps(context.get("adherence", {}), default=str, indent=2)}

TRAINING SCHEDULE:
{json.dumps(context.get("training", {}), default=str, indent=2)}

Return JSON matching the schema. Rules:
- daily: absolute calories + protein_g + carbs_g + fat_g. Respect the goal direction
  (deficit for fat loss, surplus for muscle) and the measured weight trend — if they're
  losing faster/slower than their goal rate, correct toward it. Protein supports their
  training volume.
- per_meal.meals: key ONLY by these active meal ids: [{meal_id_list}]. Use NO other keys.
  Bias the split toward HOW THEY ACTUALLY EAT (the meal-time calorie distribution). The
  per-meal protein/carbs/fat MUST sum to the daily numbers. Set enabled_suggested true only
  if a per-meal split would meaningfully help them (e.g. very uneven intake or a protein
  goal they keep missing at certain meals).
- per_day.high / per_day.base: absolute P/C/F for training ("high") vs rest ("base") days —
  steer more carbs to training days, keep protein roughly constant. Do NOT pick which days
  are high; that's bound to their training schedule automatically. Set enabled_suggested true
  only if calorie/carb cycling fits their goal and they train on a fixed schedule.
- confidence: "high" only with >=10 logged days and a clear weight trend; "low" if sparse.
- basis: one line, e.g. "Based on 14 days · 12 logged · weight -0.3 kg/wk · trains Mon/Wed/Fri".
- Each section's reasoning: coach voice, second person, <=3 sentences, no markdown."""

    response = await gemini_generate_with_retry(
        model=model,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=_AIRecommendationResponse,
            max_output_tokens=2048,
            temperature=0.4,
        ),
        user_id=user_id,
        timeout=45.0,
        method_name="nutrition_ai_recommend_targets",
    )

    parsed = response.parsed if hasattr(response, "parsed") and response.parsed else None
    if parsed is None:
        parsed = _AIRecommendationResponse(**json.loads(response.text))
    return parsed


# =============================================================================
# Context assembly (reuses existing services — does not rebuild)
# =============================================================================

def _safe_int(v: Any, default: int = 0) -> int:
    try:
        return int(round(float(v)))
    except (TypeError, ValueError):
        return default


def _compute_training_days(sb, user_id: str) -> List[int]:
    """0=Mon..6=Sun from gym_profiles.workout_days (matches dynamic-targets)."""
    try:
        res = (
            sb.client.table("gym_profiles")
            .select("workout_days")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .maybe_single()
            .execute()
        )
        if res and res.data:
            days = res.data.get("workout_days") or []
            out = sorted({int(d) for d in days if isinstance(d, (int, float)) and 0 <= int(d) <= 6})
            return out
    except Exception as e:
        logger.info(f"[ai_recommend] workout_days unavailable for {user_id}: {e}")
    return []


def _assemble_context(
    sb,
    user_id: str,
    window_days: int,
) -> Tuple[Dict[str, Any], Dict[str, Any], List[str], List[int]]:
    """Pull profile, current targets, weight trend, adaptive TDEE, adherence +
    meal-time distribution, and training days. Returns:
        (context_for_llm, raw_facts, active_meals, training_days)
    raw_facts carries the clamp inputs (weight_kg, gender) + deterministic
    baseline inputs so the caller can both clamp and fail-soft.
    Best-effort throughout — any sub-fetch failure degrades that block only.
    """
    # ── Profile ───────────────────────────────────────────────────────────────
    profile: Dict[str, Any] = {}
    try:
        u = (
            sb.client.table("users")
            .select(
                "weight_kg, height_cm, age, gender, activity_level, primary_goal, "
                "target_weight_kg"
            )
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )
        profile = (u.data if u else {}) or {}
    except Exception as e:
        logger.info(f"[ai_recommend] profile fetch failed for {user_id}: {e}")

    # ── Preferences (current targets + flags + goal/diet/meal pattern) ─────────
    prefs: Dict[str, Any] = {}
    try:
        p = (
            sb.client.table("nutrition_preferences")
            .select("*")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        prefs = (p.data if p else {}) or {}
    except Exception as e:
        logger.info(f"[ai_recommend] prefs fetch failed for {user_id}: {e}")

    active_meals = _active_meal_types(prefs) if prefs else ["breakfast", "lunch", "dinner"]
    training_days = _compute_training_days(sb, user_id)

    current_targets = {
        "calories": _safe_int(prefs.get("target_calories")),
        "protein_g": _safe_int(prefs.get("target_protein_g")),
        "carbs_g": _safe_int(prefs.get("target_carbs_g")),
        "fat_g": _safe_int(prefs.get("target_fat_g")),
        "per_meal_targets_enabled": bool(prefs.get("per_meal_targets_enabled")),
        "per_weekday_targets_enabled": bool(
            (prefs.get("per_weekday_targets") or {}).get("enabled")
            if isinstance(prefs.get("per_weekday_targets"), dict) else False
        ),
        "adjust_calories_for_training": bool(prefs.get("adjust_calories_for_training", True)),
        "adjust_calories_for_rest": bool(prefs.get("adjust_calories_for_rest", False)),
    }

    # ── Weight trend (reuse AdaptiveTDEEService.get_weight_trend) ──────────────
    weight_trend: Dict[str, Any] = {}
    try:
        weight_trend = _assemble_weight_trend(sb, user_id, max(window_days, 14))
    except Exception as e:
        logger.info(f"[ai_recommend] weight trend unavailable for {user_id}: {e}")

    # ── Adaptive TDEE reference (latest stored calc; cheap read) ───────────────
    # Table is `adaptive_nutrition_calculations` (verified live schema). The
    # weekly weight rate comes from _assemble_weight_trend above, not this table.
    adaptive_tdee: Optional[int] = None
    try:
        a = (
            sb.client.table("adaptive_nutrition_calculations")
            .select("calculated_tdee, confidence_level, calculated_at")
            .eq("user_id", user_id)
            .order("calculated_at", desc=True)
            .limit(1)
            .execute()
        )
        if a and a.data:
            adaptive_tdee = _safe_int(a.data[0].get("calculated_tdee")) or None
    except Exception as e:
        logger.info(f"[ai_recommend] adaptive tdee unavailable for {user_id}: {e}")

    # ── Adherence + meal-time distribution from food_logs over the window ──────
    adherence = _assemble_adherence(sb, user_id, window_days, active_meals)

    # Deterministic reference anchor for the prompt.
    baseline = deterministic_daily_targets(
        weight_kg=profile.get("weight_kg") or 70,
        height_cm=profile.get("height_cm") or 170,
        age=profile.get("age") or 30,
        gender=profile.get("gender"),
        activity_level=profile.get("activity_level"),
        nutrition_goal=prefs.get("nutrition_goal") or profile.get("primary_goal"),
        rate_of_change=prefs.get("rate_of_change"),
        diet_type=prefs.get("diet_type"),
        adaptive_tdee=adaptive_tdee,
    )

    context_for_llm = {
        "profile": {
            "weight_kg": profile.get("weight_kg"),
            "height_cm": profile.get("height_cm"),
            "age": profile.get("age"),
            "gender": profile.get("gender"),
            "activity_level": profile.get("activity_level"),
            "goal": prefs.get("nutrition_goal") or profile.get("primary_goal"),
            "rate_of_change": prefs.get("rate_of_change"),
            "target_weight_kg": profile.get("target_weight_kg"),
            "diet_type": prefs.get("diet_type"),
            "active_meals": active_meals,
        },
        "current_targets": current_targets,
        "reference": {
            "mifflin_adaptive_baseline": baseline,
            "adaptive_tdee": adaptive_tdee,
        },
        "weight_trend": weight_trend,
        "adherence": adherence,
        "training": {
            "training_days_mon0": training_days,
            "training_days_names": [_DAY_ABBR[d] for d in training_days],
            "adjust_calories_for_training": current_targets["adjust_calories_for_training"],
        },
    }

    raw_facts = {
        "weight_kg": profile.get("weight_kg") or 70,
        "gender": profile.get("gender"),
        "baseline": baseline,
        "adaptive_tdee": adaptive_tdee,
        "logged_days": adherence.get("logged_days", 0),
        "window_days": window_days,
        "weekly_rate_kg": weight_trend.get("weekly_rate_kg"),
        "training_day_names": [_DAY_ABBR[d] for d in training_days],
        "current_targets": current_targets,
    }

    return context_for_llm, raw_facts, active_meals, training_days


def _assemble_adherence(
    sb,
    user_id: str,
    window_days: int,
    active_meals: List[str],
) -> Dict[str, Any]:
    """Logged-day count + meal-time calorie distribution from food_logs.

    Distribution informs the per-meal split. Best-effort: returns zeros on fault.
    """
    out: Dict[str, Any] = {
        "window_days": window_days,
        "logged_days": 0,
        "avg_daily_calories": 0,
        "meal_calorie_distribution_pct": {},
    }
    try:
        from datetime import timedelta
        since = (datetime.now(timezone.utc) - timedelta(days=window_days)).isoformat()
        res = (
            sb.client.table("food_logs")
            .select("logged_at, meal_type, total_calories")
            .eq("user_id", user_id)
            .gte("logged_at", since)
            .execute()
        )
        rows = (res.data if res else []) or []
        if not rows:
            return out

        days = set()
        total_cal = 0
        by_meal: Dict[str, int] = {}
        for r in rows:
            cal = _safe_int(r.get("total_calories"))
            total_cal += cal
            mt = (r.get("meal_type") or "").strip().lower()
            if mt:
                by_meal[mt] = by_meal.get(mt, 0) + cal
            la = r.get("logged_at")
            if la:
                days.add(str(la)[:10])

        logged_days = len(days)
        out["logged_days"] = logged_days
        out["avg_daily_calories"] = int(round(total_cal / logged_days)) if logged_days else 0

        meal_total = sum(by_meal.values())
        if meal_total > 0:
            dist = {}
            for meal in active_meals:
                dist[meal] = round(100.0 * by_meal.get(meal, 0) / meal_total, 1)
            # carry any non-active bucket too (e.g. snacks logged but 3-meal pattern)
            for meal, v in by_meal.items():
                if meal not in dist:
                    dist[meal] = round(100.0 * v / meal_total, 1)
            out["meal_calorie_distribution_pct"] = dist
    except Exception as e:
        logger.info(f"[ai_recommend] adherence assembly failed for {user_id}: {e}")
    return out


def _assemble_weight_trend(sb, user_id: str, window_days: int) -> Dict[str, Any]:
    """Read weight_logs over the window and reuse AdaptiveTDEEService.get_weight_trend.

    Returns {weekly_rate_kg, direction, confidence, smoothed_weight_kg} or {} when
    there's insufficient data. Best-effort — never raises out.
    """
    from datetime import timedelta
    from services.adaptive_tdee_service import (
        get_adaptive_tdee_service,
        WeightLog,
    )

    since = (datetime.now(timezone.utc) - timedelta(days=window_days)).isoformat()
    res = (
        sb.client.table("weight_logs")
        .select("id, user_id, weight_kg, logged_at, source")
        .eq("user_id", user_id)
        .gte("logged_at", since)
        .order("logged_at", desc=False)
        .execute()
    )
    rows = (res.data if res else []) or []
    logs: List[WeightLog] = []
    for r in rows:
        try:
            la = r.get("logged_at")
            dt = datetime.fromisoformat(str(la).replace("Z", "+00:00")) if la else None
            if dt is None:
                continue
            logs.append(
                WeightLog(
                    id=str(r.get("id") or ""),
                    user_id=user_id,
                    weight_kg=float(r.get("weight_kg")),
                    logged_at=dt,
                    source=r.get("source") or "manual",
                )
            )
        except (TypeError, ValueError):
            continue

    if len(logs) < 2:
        return {}

    svc = get_adaptive_tdee_service()
    trend = svc.get_weight_trend(logs, weeks=max(2, window_days // 7))
    if trend is None:
        return {}
    return {
        "weekly_rate_kg": trend.weekly_rate_kg,
        "direction": trend.trend_direction,
        "confidence": trend.confidence,
        "smoothed_weight_kg": round(trend.smoothed_weight, 1),
    }


# =============================================================================
# Assemble final response (LLM or deterministic) + clamp
# =============================================================================

def _build_basis(raw_facts: Dict[str, Any], llm_basis: Optional[str]) -> str:
    """Prefer the LLM's one-liner; otherwise build a deterministic basis."""
    if llm_basis and llm_basis.strip():
        return llm_basis.strip()
    window = raw_facts.get("window_days", 14)
    logged = raw_facts.get("logged_days", 0)
    parts = [f"Based on {window} days", f"{logged} logged"]
    wr = raw_facts.get("weekly_rate_kg")
    if wr is not None:
        try:
            parts.append(f"weight {float(wr):+.1f} kg/wk")
        except (TypeError, ValueError):
            pass
    tdn = raw_facts.get("training_day_names") or []
    if tdn:
        parts.append("trains " + "/".join(tdn))
    return " · ".join(parts)


def _finalize_recommendation(
    *,
    ai: Optional[_AIRecommendationResponse],
    raw_facts: Dict[str, Any],
    active_meals: List[str],
    training_days: List[int],
    confidence_override: Optional[str] = None,
) -> NutritionTargetsRecommendation:
    """Take the raw LLM object (or None for fail-soft), clamp every value, and
    assemble the LOCKED response contract. Pure aside from time.now()."""
    weight_kg = float(raw_facts.get("weight_kg") or 70)
    gender = raw_facts.get("gender")
    baseline = raw_facts.get("baseline") or {}
    current = raw_facts.get("current_targets") or {}

    # ── Source numbers: LLM if present, else deterministic baseline ────────────
    if ai is not None:
        daily_in = {
            "calories": int(ai.daily.calories),
            "protein_g": int(ai.daily.protein_g),
            "carbs_g": int(ai.daily.carbs_g),
            "fat_g": int(ai.daily.fat_g),
        }
        daily_reason = ai.daily.reasoning
        # per-meal: keep only the active meal keys
        pm_in: Dict[str, Dict[str, int]] = {}
        for mid in active_meals:
            block = ai.per_meal.meals.get(mid)
            if block is not None:
                pm_in[mid] = {
                    "protein_g": int(block.protein_g),
                    "carbs_g": int(block.carbs_g),
                    "fat_g": int(block.fat_g),
                }
        if not pm_in:
            pm_in = _split_daily_to_meals(daily_in, active_meals)
        pm_enabled = bool(ai.per_meal.enabled_suggested)
        pm_reason = ai.per_meal.reasoning
        high_in = {
            "protein_g": int(ai.per_day.high.protein_g),
            "carbs_g": int(ai.per_day.high.carbs_g),
            "fat_g": int(ai.per_day.high.fat_g),
        }
        base_in = {
            "protein_g": int(ai.per_day.base.protein_g),
            "carbs_g": int(ai.per_day.base.carbs_g),
            "fat_g": int(ai.per_day.base.fat_g),
        }
        pd_enabled = bool(ai.per_day.enabled_suggested) and bool(training_days)
        pd_reason = ai.per_day.reasoning
        confidence = (ai.confidence or "medium").strip().lower()
        llm_basis = ai.basis
    else:
        daily_in = dict(baseline)
        daily_reason = (
            "This is the deterministic baseline from your profile (Mifflin BMR, "
            "your activity level, and your goal) — the AI estimate was unavailable, "
            "so these are the safe-formula numbers you can apply or fine-tune."
        )
        pm_in = _split_daily_to_meals(daily_in, active_meals)
        pm_enabled = False
        pm_reason = "Even split across your meals as a starting point."
        # high/base default to the same baseline (no cycling proposed in fallback)
        high_in = {k: baseline.get(k, 0) for k in ("protein_g", "carbs_g", "fat_g")}
        base_in = dict(high_in)
        pd_enabled = False
        pd_reason = "No day cycling proposed in the baseline calculation."
        confidence = "low"
        llm_basis = None

    if confidence not in ("high", "medium", "low"):
        confidence = "medium"
    if confidence_override:
        confidence = confidence_override

    # ── Clamp everything ───────────────────────────────────────────────────────
    daily_c, pm_c, high_c, base_c, clamp_notes = clamp_recommendation(
        daily=daily_in,
        per_meal=pm_in,
        per_day_high=high_in if pd_enabled else None,
        per_day_base=base_in if pd_enabled else None,
        weight_kg=weight_kg,
        gender=gender,
    )

    # ── Assemble LOCKED contract ───────────────────────────────────────────────
    daily_block = DailyTargetBlock(
        calories=daily_c["calories"],
        protein_g=daily_c["protein_g"],
        carbs_g=daily_c["carbs_g"],
        fat_g=daily_c["fat_g"],
        current=CurrentDailyTarget(
            calories=_safe_int(current.get("calories")),
            protein_g=_safe_int(current.get("protein_g")),
            carbs_g=_safe_int(current.get("carbs_g")),
            fat_g=_safe_int(current.get("fat_g")),
        ),
        reasoning=daily_reason or "",
    )

    per_meal_block = PerMealRecommendation(
        enabled_suggested=pm_enabled,
        meals={mid: dict(vals) for mid, vals in (pm_c or {}).items()},
        reasoning=pm_reason or "",
    )

    per_day_block = PerDayRecommendation(
        enabled_suggested=pd_enabled,
        bind_to_training_days=True,
        high_days=list(training_days),
        high=MacroTriple(**(high_c or {"protein_g": 0, "carbs_g": 0, "fat_g": 0})),
        base=MacroTriple(**(base_c or {"protein_g": 0, "carbs_g": 0, "fat_g": 0})),
        reasoning=pd_reason or "",
    )

    return NutritionTargetsRecommendation(
        confidence=confidence,
        basis=_build_basis(raw_facts, llm_basis),
        daily=daily_block,
        per_meal=per_meal_block,
        per_day=per_day_block,
        clamped=clamp_notes,
        generated_at=datetime.now(timezone.utc).isoformat(),
        cached=False,
    )


# =============================================================================
# Cache + persist
# =============================================================================

def _cache():
    """Lazy RedisCache — degrades to in-process when Redis is absent (same
    primitive the gemini services use). Imported lazily so the clamp/baseline
    helpers stay import-safe for the unit test."""
    from core.redis_cache import RedisCache
    return RedisCache(prefix="nutrition_ai_recommend", ttl_seconds=12 * 3600, max_size=500)


def _persist_recommendation(
    sb, user_id: str, window: int, rec: NutritionTargetsRecommendation
) -> None:
    """Durable L2 persist of the FULL rich recommendation into
    nutrition_ai_recommendations (migration 2277), UPSERTed on
    (user_id, rec_date, window_days) so repeat/non-cached calls overwrite rather
    than bloat. Survives Redis outage/restart. Fail-open."""
    try:
        row = {
            "user_id": user_id,
            "rec_date": date.today().isoformat(),
            "window_days": window,
            "payload": rec.model_dump(),
            "confidence": rec.confidence,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        sb.client.table("nutrition_ai_recommendations").upsert(
            row, on_conflict="user_id,rec_date,window_days"
        ).execute()
    except Exception as e:
        logger.info(f"[ai_recommend] durable persist skipped for {user_id}: {e}")


def _read_durable(
    sb, user_id: str, window: int
) -> Optional[NutritionTargetsRecommendation]:
    """L2 read — today's durable recommendation for this window, if any. Used on a
    RedisCache miss so we don't re-pay the LLM after a cache eviction/restart.
    Fail-open (returns None on any fault)."""
    try:
        res = (
            sb.client.table("nutrition_ai_recommendations")
            .select("payload")
            .eq("user_id", user_id)
            .eq("rec_date", date.today().isoformat())
            .eq("window_days", window)
            .limit(1)
            .execute()
        )
        rows = res.data or []
        if rows and rows[0].get("payload"):
            return NutritionTargetsRecommendation(**rows[0]["payload"])
    except Exception as e:
        logger.info(f"[ai_recommend] durable read skipped for {user_id}: {e}")
    return None


# =============================================================================
# Endpoint
# =============================================================================

@router.post("/ai-recommend-targets", response_model=NutritionTargetsRecommendation)
async def ai_recommend_targets(
    request: Request,
    data: AIRecommendTargetsRequest,
    current_user: dict = Depends(get_current_user),
):
    """Full-AI nutrition-target recommendation with safety clamps + fail-soft.

    Ownership is taken from the JWT (body user_id must match). Returns the
    LOCKED NutritionTargetsRecommendation. Never 500s — on LLM failure it
    returns the deterministic baseline with confidence "low".
    """
    try:
        verify_user_ownership(current_user, data.user_id)
        user_id = str(current_user["id"])
        window = max(7, min(int(data.context_window_days or 14), 60))

        cache = _cache()
        cache_key = f"{user_id}:{date.today().isoformat()}:{window}"
        sb = get_supabase_db()

        # ── Cached hit (unless force): L1 RedisCache → L2 durable table ─────────
        if not data.force:
            try:
                cached = await cache.get(cache_key)
            except Exception:
                cached = None
            if cached is not None:
                try:
                    rec = NutritionTargetsRecommendation(**cached)
                    rec.cached = True
                    return rec
                except Exception:
                    pass  # malformed cache → fall through

            # L2: durable read-through survives Redis eviction/restart so we don't
            # re-pay the LLM for a recommendation already generated today.
            durable = _read_durable(sb, user_id, window)
            if durable is not None:
                durable.cached = True
                try:
                    await cache.set(cache_key, durable.model_dump())  # warm L1
                except Exception:
                    pass
                return durable

        context_for_llm, raw_facts, active_meals, training_days = _assemble_context(
            sb, user_id, window
        )

        # ── LLM (fail-soft to deterministic) ───────────────────────────────────
        ai_obj: Optional[_AIRecommendationResponse] = None
        try:
            ai_obj = await _generate_ai_targets(
                context=context_for_llm,
                active_meals=active_meals,
                user_id=user_id,
            )
        except Exception as llm_err:
            logger.warning(
                f"[ai_recommend] LLM failed for {user_id}; deterministic fallback: {llm_err}",
                exc_info=True,
            )
            ai_obj = None

        rec = _finalize_recommendation(
            ai=ai_obj,
            raw_facts=raw_facts,
            active_meals=active_meals,
            training_days=training_days,
        )

        # ── Cache + persist (best-effort) ──────────────────────────────────────
        try:
            await cache.set(cache_key, rec.model_dump())
        except Exception as e:
            logger.info(f"[ai_recommend] cache set skipped for {user_id}: {e}")
        _persist_recommendation(sb, user_id, window, rec)

        rec.cached = False
        return rec
    except Exception as e:
        # Last-resort fail-soft — should be unreachable since the LLM path already
        # falls back, but the contract is "never 500": return a deterministic rec.
        logger.error(f"[ai_recommend] unexpected error: {e}", exc_info=True)
        try:
            baseline = deterministic_daily_targets(
                weight_kg=70, height_cm=170, age=30, gender=None,
                activity_level=None, nutrition_goal="maintain",
                rate_of_change=None, diet_type="balanced",
            )
            return _finalize_recommendation(
                ai=None,
                raw_facts={
                    "weight_kg": 70, "gender": None, "baseline": baseline,
                    "current_targets": {}, "window_days": 14, "logged_days": 0,
                    "training_day_names": [],
                },
                active_meals=["breakfast", "lunch", "dinner"],
                training_days=[],
            )
        except Exception:
            raise safe_internal_error(e, "nutrition_ai_recommend")
