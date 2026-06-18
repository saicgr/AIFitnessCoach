"""
Progress Pros & Cons — cross-session AI analysis (H).

Upgrades the deterministic `_ExerciseInsightsCard` (hand-written switch-cases on
trend) into a GENUINE LLM analysis grounded ONLY in data that already exists:
per-session exercise history (the `exercise_workout_history` view), the pure PR
history/statistics helpers, and per-muscle `strength_scores`. NEVER invents
numbers — same strict contract as the recap.

Two scopes:
  * per-exercise (`exercise_name` set) — trend/PRs/frequency for ONE lift.
  * whole-body (`exercise_name` None) — aggregate across muscles + top exercises.

Edge: <2 sessions → has_history=False, a minimal "keep logging" message, NO
hallucinated trend. Cached in-process (short TTL) so it refreshes as sessions land.
"""

from __future__ import annotations

import time
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from pydantic import BaseModel, Field

from core.logger import get_logger
from services.personal_records_service import personal_records_service

logger = get_logger(__name__)

# window token -> lookback days.
_WINDOW_DAYS = {"8w": 56, "6m": 180, "1y": 365, "all": 3650}

# In-process TTL cache keyed (user_id, exercise_name|'all', window). Short TTL so
# the report refreshes as new sessions land but repeat opens are instant + free.
_CACHE_TTL_SECONDS = 30 * 60
_cache: Dict[Tuple[str, str, str], Tuple[float, Dict[str, Any]]] = {}


def _cache_get(key: Tuple[str, str, str]) -> Optional[Dict[str, Any]]:
    hit = _cache.get(key)
    if not hit:
        return None
    ts, value = hit
    if time.time() - ts > _CACHE_TTL_SECONDS:
        _cache.pop(key, None)
        return None
    return value


def _cache_put(key: Tuple[str, str, str], value: Dict[str, Any]) -> None:
    _cache[key] = (time.time(), value)


# ---------------------------------------------------------------------------
# LLM response schema
# ---------------------------------------------------------------------------

class ProgressAnalysisPayload(BaseModel):
    """Structured progress pros/cons (Gemini response_schema)."""
    pros: List[str] = Field(default_factory=list, description="What's going well, each grounded in a real number.")
    cons: List[str] = Field(default_factory=list, description="What's stalling/declining, each grounded.")
    plateaus: List[str] = Field(default_factory=list, description="Specific plateaus (lift/muscle flat for N weeks).")
    next_focus: List[str] = Field(default_factory=list, description="Concrete next actions tied to the data.")
    summary_markdown: str = Field(..., description="2-4 sentence human summary, no emojis.")


# ---------------------------------------------------------------------------
# Grounding (reuse existing data sources — NO new tables)
# ---------------------------------------------------------------------------

def _fetch_exercise_sessions(
    db, user_id: str, exercise_name: str, gym_profile_id: Optional[str], days: int
) -> List[Dict[str, Any]]:
    """Per-session rows for ONE exercise from the exercise_workout_history view.

    Returns newest-first list of {date, volume_kg, max_weight_kg, est_1rm_kg,
    sets, reps, avg_rpe}.
    """
    start = (datetime.now(timezone.utc).date() - timedelta(days=days)).isoformat()
    q = (
        db.client.from_("exercise_workout_history")
        .select(
            "workout_date, total_volume_kg, max_weight_kg, estimated_1rm_kg, "
            "sets_completed, total_reps, avg_rpe, gym_profile_id"
        )
        .eq("user_id", user_id)
        .ilike("exercise_name", exercise_name.lower())
        .gte("workout_date", start)
        .order("workout_date", desc=True)
    )
    if gym_profile_id:
        q = q.eq("gym_profile_id", gym_profile_id)
    rows = q.execute().data or []
    return [
        {
            "date": r.get("workout_date"),
            "volume_kg": float(r.get("total_volume_kg") or 0),
            "max_weight_kg": float(r.get("max_weight_kg") or 0),
            "est_1rm_kg": float(r.get("estimated_1rm_kg") or 0) if r.get("estimated_1rm_kg") else None,
            "sets": int(r.get("sets_completed") or 0),
            "reps": int(r.get("total_reps") or 0),
            "avg_rpe": float(r.get("avg_rpe") or 0) if r.get("avg_rpe") else None,
        }
        for r in rows
    ]


def _trend_from_sessions(sessions: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Deterministic trend (oldest→newest) over a session list (no LLM).

    Compares the earliest vs latest non-zero 1RM (or max weight fallback).
    """
    if len(sessions) < 2:
        return {"direction": "no_data", "percent_change": 0.0}
    ordered = sorted(sessions, key=lambda s: s.get("date") or "")
    metric = "est_1rm_kg"
    vals = [s.get(metric) for s in ordered if s.get(metric)]
    if len(vals) < 2:
        metric = "max_weight_kg"
        vals = [s.get(metric) for s in ordered if s.get(metric)]
    if len(vals) < 2 or vals[0] <= 0:
        return {"direction": "maintaining", "percent_change": 0.0, "metric": metric}
    pct = round((vals[-1] - vals[0]) / vals[0] * 100, 1)
    if pct >= 2.5:
        direction = "improving"
    elif pct <= -2.5:
        direction = "declining"
    else:
        direction = "maintaining"
    return {
        "direction": direction,
        "percent_change": pct,
        "metric": metric,
        "start_value": round(vals[0], 1),
        "current_value": round(vals[-1], 1),
    }


def _fetch_all_prs(db, user_id: str) -> List[Dict[str, Any]]:
    """All current PR rows for the user (for the pure PR statistics helpers)."""
    try:
        rows = (
            db.client.from_("exercise_personal_records")
            .select("exercise_name, record_type, record_value, improvement_percent, achieved_at")
            .eq("user_id", user_id)
            .eq("is_current_record", True)
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[progress] PR fetch failed: {e}")
        return []
    # Adapt to the shape the pure helpers expect (estimated_1rm_kg from 1RM rows).
    adapted = []
    for r in rows:
        rtype = (r.get("record_type") or "").lower()
        adapted.append(
            {
                "exercise_name": r.get("exercise_name"),
                "estimated_1rm_kg": float(r.get("record_value") or 0) if rtype in ("best_1rm", "1rm") else 0.0,
                "improvement_percent": r.get("improvement_percent"),
                "achieved_at": r.get("achieved_at"),
            }
        )
    return adapted


def _fetch_muscle_scores(db, user_id: str) -> List[Dict[str, Any]]:
    """Per-muscle strength scores (trend, weekly sets/volume) for whole-body scope."""
    try:
        rows = (
            db.client.from_("strength_scores")
            .select("muscle_group, strength_score, strength_level, trend, score_change, weekly_sets, weekly_volume_kg, is_establishing")
            .eq("user_id", user_id)
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[progress] strength_scores fetch failed: {e}")
        return []
    return rows


def _fetch_top_exercises(db, user_id: str, days: int, limit: int = 8) -> List[str]:
    """Most-frequent exercises in the window (for whole-body per-exercise trends)."""
    start = (datetime.now(timezone.utc).date() - timedelta(days=days)).isoformat()
    try:
        rows = (
            db.client.from_("exercise_workout_history")
            .select("exercise_name")
            .eq("user_id", user_id)
            .gte("workout_date", start)
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[progress] top-exercise fetch failed: {e}")
        return []
    counts: Dict[str, int] = {}
    for r in rows:
        n = r.get("exercise_name")
        if n:
            counts[n] = counts.get(n, 0) + 1
    return [n for n, _ in sorted(counts.items(), key=lambda x: x[1], reverse=True)[:limit]]


# ---------------------------------------------------------------------------
# Grounding text builders
# ---------------------------------------------------------------------------

def _build_exercise_grounding(
    db, user_id: str, exercise_name: str, gym_profile_id: Optional[str], days: int
) -> Tuple[str, bool]:
    """Grounding block + has_history for a single-exercise analysis."""
    sessions = _fetch_exercise_sessions(db, user_id, exercise_name, gym_profile_id, days)
    if len(sessions) < 2:
        return "", False

    trend = _trend_from_sessions(sessions)
    pr_rows = _fetch_all_prs(db, user_id)
    pr_hist = personal_records_service.get_exercise_pr_history(exercise_name, pr_rows)

    recent = sorted(sessions, key=lambda s: s.get("date") or "", reverse=True)[:6]
    sess_lines = "\n".join(
        f"- {s['date']}: {s['sets']} sets, {s['reps']} reps, top {s['max_weight_kg']:.0f}kg"
        + (f", est 1RM {s['est_1rm_kg']:.0f}kg" if s.get("est_1rm_kg") else "")
        for s in recent
    )

    lines = [
        f"EXERCISE: {exercise_name}",
        f"Sessions in window: {len(sessions)}",
        f"Trend ({trend.get('metric','1rm')}): {trend['direction']}, "
        f"{trend['percent_change']:+.1f}%"
        + (f" ({trend.get('start_value')}kg → {trend.get('current_value')}kg)" if trend.get('start_value') else ""),
    ]
    if pr_hist.get("total_prs"):
        cur = pr_hist.get("current_pr") or {}
        lines.append(
            f"PRs: {pr_hist['total_prs']} total; current best 1RM "
            f"~{cur.get('estimated_1rm_kg', 0):.0f}kg"
            + (f"; total improvement {pr_hist.get('total_improvement_percent')}%" if pr_hist.get("total_improvement_percent") else "")
        )
    lines.append("Recent sessions:\n" + sess_lines)
    return "\n".join(lines), True


def _build_wholebody_grounding(
    db, user_id: str, gym_profile_id: Optional[str], days: int
) -> Tuple[str, bool]:
    """Grounding block + has_history for the whole-body progress report."""
    muscles = _fetch_muscle_scores(db, user_id)
    top_ex = _fetch_top_exercises(db, user_id, days)
    pr_rows = _fetch_all_prs(db, user_id)
    pr_stats = personal_records_service.get_pr_statistics(pr_rows, period_days=days)

    # Per-top-exercise trend (bounded — already capped at 8 names).
    ex_trends = []
    for name in top_ex:
        sessions = _fetch_exercise_sessions(db, user_id, name, gym_profile_id, days)
        if len(sessions) >= 2:
            t = _trend_from_sessions(sessions)
            ex_trends.append(f"- {name}: {t['direction']} ({t['percent_change']:+.1f}%), {len(sessions)} sessions")

    if not muscles and not ex_trends:
        return "", False

    lines: List[str] = ["WHOLE-BODY PROGRESS"]
    if muscles:
        mline = "\n".join(
            f"- {m.get('muscle_group')}: score {m.get('strength_score')} ({m.get('strength_level')}), "
            f"trend {m.get('trend')}, {m.get('weekly_sets')} sets/wk"
            + (" [establishing]" if m.get("is_establishing") else "")
            for m in muscles[:12]
        )
        lines.append("Muscle strength scores:\n" + mline)
    if ex_trends:
        lines.append("Top exercises:\n" + "\n".join(ex_trends))
    if pr_stats.get("total_prs"):
        lines.append(
            f"PRs: {pr_stats['total_prs']} total, {pr_stats.get('prs_this_period', 0)} in window; "
            f"most improved: {pr_stats.get('most_improved_exercise') or 'n/a'}"
            + (f" ({pr_stats.get('best_improvement_percent')}%)" if pr_stats.get("best_improvement_percent") else "")
        )
    return "\n".join(lines), True


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------

def _empty_result(has_history: bool) -> Dict[str, Any]:
    """The <2-session / no-data response — honest, no hallucinated trend."""
    msg = "Keep logging — once you've got a couple of sessions in, I can break down what's working and what's stalling."
    return {
        "pros": [],
        "cons": [],
        "plateaus": [],
        "next_focus": ["Log at least two sessions so progress can be analyzed."],
        "summary_markdown": msg,
        "has_history": has_history,
        "is_fallback": True,
    }


async def generate_progress_analysis(
    gemini_service,
    db,
    user_id: str,
    exercise_name: Optional[str],
    gym_profile_id: Optional[str],
    window: str = "8w",
    force: bool = False,
) -> Dict[str, Any]:
    """Generate (or return cached) cross-session progress pros & cons.

    Returns a dict matching the endpoint contract PLUS `cached`/`generated_at`,
    which the endpoint fills. Never raises — fails open to the deterministic
    empty/minimal result.
    """
    window = window if window in _WINDOW_DAYS else "8w"
    days = _WINDOW_DAYS[window]
    scope_key = (exercise_name or "all").lower()
    cache_key = (str(user_id), scope_key, window)

    if not force:
        cached = _cache_get(cache_key)
        if cached is not None:
            out = dict(cached)
            out["cached"] = True
            return out

    # --- Grounding ---
    try:
        if exercise_name:
            grounding, has_history = _build_exercise_grounding(
                db, user_id, exercise_name, gym_profile_id, days
            )
        else:
            grounding, has_history = _build_wholebody_grounding(
                db, user_id, gym_profile_id, days
            )
    except Exception as e:
        logger.warning(f"[progress] grounding failed: {e}")
        grounding, has_history = "", False

    if not has_history:
        result = _empty_result(has_history=False)
        _cache_put(cache_key, result)
        out = dict(result)
        out["cached"] = False
        return out

    # --- LLM ---
    from google.genai import types
    from services.gemini.constants import gemini_generate_with_retry

    scope_label = exercise_name if exercise_name else "the user's overall training"
    system_prompt = (
        "You are an elite strength coach producing a cross-session PROGRESS "
        "analysis. Use ONLY the grounded numbers provided — NEVER invent trends, "
        "percentages, PRs, or sessions. Be specific and honest; cite the actual "
        "figures. No emojis. Each pro/con/plateau is one short sentence grounded "
        "in a real number; next_focus items are concrete actions tied to the data."
    )
    user_prompt = f"""Analyze progress for {scope_label} over the last {window}.

GROUNDED DATA (use only these numbers):
{grounding}

Return:
- pros: what's genuinely improving (lift/muscle up X%, PRs, consistency). Empty if nothing.
- cons: what's stalling or declining (flat/declining lifts, under-trained muscles). Empty if nothing.
- plateaus: specific lifts/muscles that are flat (name + how long/flat).
- next_focus: 1-3 concrete next actions tied to the data above.
- summary_markdown: 2-4 sentence plain-English summary."""

    try:
        response = await gemini_generate_with_retry(
            model=gemini_service.model,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                response_mime_type="application/json",
                response_schema=ProgressAnalysisPayload,
                temperature=0.5,
                max_output_tokens=900,
            ),
            timeout=30,
            method_name="progress_analysis",
        )
        parsed = response.parsed
        if not parsed:
            raise ValueError("Empty progress analysis response")
        result = parsed.model_dump()
        result["has_history"] = True
        result["is_fallback"] = False
    except Exception as e:
        logger.warning(f"[progress] LLM failed, deterministic fallback: {e}")
        result = _deterministic_progress(exercise_name, grounding)

    _cache_put(cache_key, result)
    out = dict(result)
    out["cached"] = False
    return out


def _deterministic_progress(exercise_name: Optional[str], grounding: str) -> Dict[str, Any]:
    """No-LLM fallback so the card is never blank. Honest, minimal, grounded.

    Parses the trend line out of the grounding text (it's the deterministic
    trend we computed) rather than inventing anything.
    """
    pros: List[str] = []
    cons: List[str] = []
    plateaus: List[str] = []
    for line in grounding.splitlines():
        low = line.lower()
        if "trend" in low and "improving" in low:
            pros.append(line.strip("- ").strip())
        elif "trend" in low and "declining" in low:
            cons.append(line.strip("- ").strip())
        elif "trend" in low and "maintaining" in low:
            plateaus.append(line.strip("- ").strip())
    scope = exercise_name or "your training"
    summary = (
        f"Here's where {scope} stands based on your logged sessions. "
        "Keep logging for a sharper read as more data lands."
    )
    return {
        "pros": pros[:4],
        "cons": cons[:4],
        "plateaus": plateaus[:4],
        "next_focus": ["Add a small load or rep increase on your strongest lift next session."],
        "summary_markdown": summary,
        "has_history": True,
        "is_fallback": True,
    }
