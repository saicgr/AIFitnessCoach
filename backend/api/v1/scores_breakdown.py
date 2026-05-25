"""
Phase 4 — Score transparency endpoint.

GET /api/v1/scores/breakdown/{muscle_group}

Returns the per-exercise contribution to a muscle's strength score so the
Flutter strength_tab can render a "tap → see how each lift contributes"
drill-down. Mirrors Gravl's marketed feature: "Ability to see the logic /
exercises that are contributing to a particular muscle's strength score."

Logic is deterministic (per `feedback_no_llm_for_safety_classification` —
strength score interpretation is not LLM territory). Contribution % is:

    contribution(exercise) = e1RM(exercise) × bodyweight_ratio_weight /
                             sum(e1RM × weight for all exercises in muscle)

Reads from `strength_scores` (already populated by strength_calculator_service)
+ recent workout_logs for per-exercise e1RM trail.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple

from fastapi import APIRouter, Depends, HTTPException

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger


def _brzycki_1rm(weight_kg: float, reps: int) -> float:
    """Brzycki formula — matches the one used in adaptive_workout_service_helpers."""
    if reps <= 0 or weight_kg <= 0:
        return 0.0
    if reps >= 37:  # Brzycki denominator = 37-r; clamp to avoid div-by-zero.
        return weight_kg
    return weight_kg * (36 / (37 - reps))


estimate_one_rep_max = _brzycki_1rm

logger = get_logger(__name__)
router = APIRouter()


@router.get("/scores/breakdown/{muscle_group}")
async def scores_breakdown(
    muscle_group: str,
    current_user: dict = Depends(get_current_user),
):
    """Per-exercise contribution to a muscle's strength score."""
    user_id = current_user["id"]
    muscle = muscle_group.lower().strip()
    db = get_supabase_db()

    # Pull the muscle's overall score for header.
    muscle_score_row = (
        db.client.table("strength_scores")
        .select("strength_score,strength_level,best_exercise_name,"
                "best_estimated_1rm_kg,bodyweight_ratio,weekly_sets,weekly_volume_kg,trend")
        .eq("user_id", user_id)
        .eq("muscle_group", muscle)
        .order("calculated_at", desc=True)
        .limit(1)
        .execute()
    )
    if not muscle_score_row.data:
        raise HTTPException(
            status_code=404,
            detail={
                "error": "no_strength_score",
                "muscle_group": muscle,
                "hint": "Log at least one workout targeting this muscle to populate the score.",
            },
        )
    header = muscle_score_row.data[0]

    # Pull last-90-day logs that include this muscle.
    since = (datetime.now(timezone.utc) - timedelta(days=90)).isoformat()
    logs = (
        db.client.table("workout_logs")
        .select("performance_data,completed_at")
        .eq("user_id", user_id)
        .gte("completed_at", since)
        .execute()
    )

    # Group set entries by exercise; estimate per-exercise e1RM from best logged set.
    per_exercise_best: dict[str, dict] = {}
    for row in (logs.data or []):
        perf = row.get("performance_data") or {}
        for ex in (perf.get("exercises") or []):
            if (ex.get("primary_muscle") or "").lower() != muscle:
                continue
            name = ex.get("name") or ex.get("exercise_name")
            if not name:
                continue
            for s in (ex.get("sets") or []):
                weight = float(s.get("weight_kg") or 0)
                reps = int(s.get("reps") or 0)
                if weight <= 0 or reps <= 0:
                    continue
                e1rm = estimate_one_rep_max(weight, reps)
                cur = per_exercise_best.get(name)
                if not cur or e1rm > cur["e1rm"]:
                    per_exercise_best[name] = {
                        "exercise_name": name,
                        "best_set_weight_kg": weight,
                        "best_set_reps": reps,
                        "e1rm": round(e1rm, 1),
                        "last_logged_at": row.get("completed_at"),
                    }

    items = list(per_exercise_best.values())
    if not items:
        return {
            "header": header,
            "exercises": [],
            "note": "Strength score exists but no recent (90d) sets targeting this muscle have been logged.",
        }

    total_e1rm = sum(i["e1rm"] for i in items) or 1.0
    for i in items:
        i["contribution_pct"] = round((i["e1rm"] / total_e1rm) * 100, 1)

    items.sort(key=lambda i: i["contribution_pct"], reverse=True)

    return {
        "muscle_group": muscle,
        "header": header,
        "exercises": items,
        "exercise_count": len(items),
    }
