"""Compute achievements (PRs, estimated 1RM gains, weight trend, streaks)
from a freshly-written event row. Annotations are returned to the
events.log endpoint and persisted to `personal_records` (existing table)
so the Timeline aggregator can join them back into entries.

Designed to fail-soft: if any computation throws, returns []. The events
endpoint logs the warning but does NOT fail the user's log on
achievement-side errors.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


# Streak milestones surfaced as standalone achievement rows in Timeline.
STREAK_MILESTONES = {3, 7, 14, 30, 60, 90, 100, 200, 365}

# Weight-loss milestones (lbs lost from baseline)
WEIGHT_MILESTONES_LBS = {5, 10, 15, 20, 25, 30, 50, 75, 100}


async def compute_event_achievements(
    db,
    user_id: str,
    domain: str,
    raw_event_id: str,
    occurred_at: str,
) -> List[Dict[str, Any]]:
    """Top-level dispatcher. Returns a list of achievement dicts attached
    to the event for inline display in the Timeline."""
    try:
        if domain == "workout":
            return await _workout_achievements(db, user_id, raw_event_id, occurred_at)
        if domain == "weight":
            return await _weight_achievements(db, user_id, raw_event_id, occurred_at)
        if domain == "sleep":
            return await _sleep_achievements(db, user_id, raw_event_id, occurred_at)
        return []
    except Exception as e:
        logger.warning(f"[Achievements] dispatcher failed: {e}", exc_info=True)
        return []


# ---------------------------------------------------------------------------
# Workout achievements (PRs + e1RM + streaks)
# ---------------------------------------------------------------------------

def _epley_e1rm(weight_kg: float, reps: int) -> float:
    """Epley formula: 1RM = w × (1 + r/30). Capped at reps=12 (formula
    breaks down for high reps)."""
    if weight_kg <= 0 or reps <= 0:
        return 0.0
    capped_reps = min(reps, 12)
    return round(weight_kg * (1 + capped_reps / 30.0), 2)


async def _workout_achievements(db, user_id: str, workout_id: str, occurred_at: str) -> List[Dict[str, Any]]:
    """Detect strength PRs, e1RM PRs, volume PRs from a freshly-completed workout."""
    achievements: List[Dict[str, Any]] = []

    # Fetch the workout row with exercises_json
    try:
        wresult = db.client.table("workouts").select(
            "id, name, exercises_json, completed_at, user_id"
        ).eq("id", workout_id).single().execute()
    except Exception as e:
        logger.debug(f"[Achievements] workout fetch failed: {e}")
        return []
    workout = wresult.data
    if not workout:
        return []
    exercises = workout.get("exercises_json") or []
    if not isinstance(exercises, list):
        return []

    # Per-exercise: find the heaviest single set this workout, compare to prior PR
    for ex in exercises:
        if not isinstance(ex, dict):
            continue
        ex_name = (ex.get("name") or "").strip()
        if not ex_name:
            continue
        # Walk set_targets if present (our generated workouts) OR sets list
        sets = ex.get("set_targets") or ex.get("sets_log") or ex.get("sets") or []
        if not isinstance(sets, list):
            continue

        max_weight = 0.0
        max_weight_reps = 0
        max_e1rm = 0.0
        for s in sets:
            if not isinstance(s, dict):
                continue
            # Skip warmup sets
            if (s.get("set_type") or "").lower() == "warmup":
                continue
            wkg = s.get("target_weight_kg") or s.get("weight_kg") or s.get("weight") or 0
            reps = s.get("target_reps") or s.get("reps") or s.get("reps_completed") or 0
            try:
                wkg = float(wkg)
                reps = int(reps)
            except Exception:
                continue
            if wkg > max_weight:
                max_weight = wkg
                max_weight_reps = reps
            e1rm = _epley_e1rm(wkg, reps)
            if e1rm > max_e1rm:
                max_e1rm = e1rm

        if max_weight <= 0:
            continue

        # Look up prior PR for this exercise
        prior_weight = await _get_prior_pr(db, user_id, ex_name, "weight")
        prior_e1rm = await _get_prior_pr(db, user_id, ex_name, "e1rm")

        # Strength PR (max single-rep weight beat)
        if prior_weight is None or max_weight > prior_weight + 0.5:  # 0.5kg threshold = 1lb
            improvement = max_weight - (prior_weight or 0)
            await _insert_pr(
                db, user_id, ex_name, "weight",
                value=max_weight, unit="kg", reps=max_weight_reps,
                workout_id=workout_id, achieved_at=occurred_at,
                prior_value=prior_weight,
            )
            achievements.append({
                "kind": "strength_pr",
                "exercise": ex_name,
                "new_value_kg": max_weight,
                "delta_kg": round(improvement, 2),
                "icon": "emoji_events",
                "label": f"🏆 New PR · {ex_name} {max_weight:g} kg",
            })

        # e1RM PR (≥2.5% improvement)
        if max_e1rm > 0 and (prior_e1rm is None or max_e1rm > prior_e1rm * 1.025):
            improvement_pct = ((max_e1rm - (prior_e1rm or max_e1rm)) / max_e1rm) * 100 if prior_e1rm else 0
            await _insert_pr(
                db, user_id, ex_name, "e1rm",
                value=max_e1rm, unit="kg", reps=None,
                workout_id=workout_id, achieved_at=occurred_at,
                prior_value=prior_e1rm,
            )
            achievements.append({
                "kind": "e1rm_pr",
                "exercise": ex_name,
                "new_value_kg": max_e1rm,
                "delta_pct": round(improvement_pct, 1),
                "icon": "trending_up",
                "label": f"📈 New e1RM · {ex_name} {max_e1rm:.1f} kg",
            })

    # Streak milestone check (only when this workout completes a milestone day)
    streak_ach = await _streak_milestone(db, user_id, occurred_at)
    if streak_ach:
        achievements.append(streak_ach)

    return achievements


async def _get_prior_pr(db, user_id: str, exercise_name: str, record_type: str) -> Optional[float]:
    try:
        result = db.client.table("personal_records").select("record_value").eq(
            "user_id", user_id,
        ).eq("exercise_name", exercise_name).eq("record_type", record_type).order(
            "record_value", desc=True,
        ).limit(1).execute()
        if result.data:
            return float(result.data[0]["record_value"])
    except Exception as e:
        logger.debug(f"[Achievements] prior PR lookup failed for {exercise_name}/{record_type}: {e}")
    return None


async def _insert_pr(
    db, user_id: str, exercise_name: str, record_type: str,
    *, value: float, unit: str, reps: Optional[int],
    workout_id: str, achieved_at: str, prior_value: Optional[float],
):
    try:
        improvement_kg = (value - prior_value) if prior_value else value
        improvement_pct = ((value - prior_value) / prior_value * 100) if prior_value else 100.0
        row = {
            "user_id": user_id,
            "exercise_name": exercise_name,
            "record_type": record_type if record_type != "weight" else f"weight_{reps or 1}rm",
            "record_value": value,
            "record_unit": unit,
            "previous_value": prior_value,
            "improvement_percentage": round(improvement_pct, 2),
            "weight_kg": value if record_type == "weight" else None,
            "reps": reps,
            "estimated_1rm_kg": value if record_type == "e1rm" else None,
            "previous_weight_kg": prior_value if record_type == "weight" else None,
            "previous_1rm_kg": prior_value if record_type == "e1rm" else None,
            "improvement_kg": round(improvement_kg, 2),
            "improvement_percent": round(improvement_pct, 2),
            "is_all_time_pr": True,
            "workout_id": workout_id,
            "achieved_at": achieved_at,
        }
        row = {k: v for k, v in row.items() if v is not None}
        db.client.table("personal_records").insert(row).execute()
    except Exception as e:
        logger.warning(f"[Achievements] insert PR failed: {e}", exc_info=True)


async def _streak_milestone(db, user_id: str, occurred_at: str) -> Optional[Dict[str, Any]]:
    """Count consecutive completed-workout days ending today; if it hits a
    milestone, return an achievement chip."""
    try:
        # Pull last 400 days of completed workouts; group by date.
        cutoff = (datetime.fromisoformat(occurred_at.replace("Z", "+00:00")) -
                  timedelta(days=400)).isoformat()
        result = db.client.table("workouts").select("completed_at").eq(
            "user_id", user_id,
        ).eq("is_completed", True).gte("completed_at", cutoff).execute()
        rows = result.data or []
        days = {r["completed_at"][:10] for r in rows if r.get("completed_at")}
        if not days:
            return None
        # Count consecutive days back from today
        today_d = datetime.fromisoformat(occurred_at.replace("Z", "+00:00")).date()
        streak = 0
        cur = today_d
        while cur.isoformat() in days:
            streak += 1
            cur = cur - timedelta(days=1)
        if streak in STREAK_MILESTONES:
            return {
                "kind": "streak_milestone",
                "streak_days": streak,
                "icon": "local_fire_department",
                "label": f"🔥 {streak}-day streak!",
            }
    except Exception as e:
        logger.debug(f"[Achievements] streak check failed: {e}")
    return None


# ---------------------------------------------------------------------------
# Weight achievements
# ---------------------------------------------------------------------------

async def _weight_achievements(db, user_id: str, weight_id: str, occurred_at: str) -> List[Dict[str, Any]]:
    """Detect weight-loss milestones + 7-day trend annotation."""
    try:
        result = db.client.table("body_measurements").select(
            "weight_kg, measured_at"
        ).eq("user_id", user_id).order("measured_at", desc=True).limit(20).execute()
        rows = [r for r in (result.data or []) if r.get("weight_kg")]
        if len(rows) < 1:
            return []

        latest = float(rows[0]["weight_kg"])
        achievements: List[Dict[str, Any]] = []

        # 7-day trend
        seven_day_ago = datetime.fromisoformat(occurred_at.replace("Z", "+00:00")) - timedelta(days=7)
        prior_window = [r for r in rows[1:] if r.get("measured_at") and
                        datetime.fromisoformat(r["measured_at"].replace("Z", "+00:00")) >= seven_day_ago]
        if prior_window:
            prior_avg = sum(float(r["weight_kg"]) for r in prior_window) / len(prior_window)
            delta_kg = latest - prior_avg
            arrow = "↘" if delta_kg < -0.05 else "↗" if delta_kg > 0.05 else "→"
            achievements.append({
                "kind": "weight_trend",
                "delta_kg": round(delta_kg, 2),
                "arrow": arrow,
                "icon": "trending_down" if delta_kg < 0 else "trending_up",
                "label": f"{arrow} {abs(delta_kg):.1f} kg vs 7-day avg",
            })

        # Loss milestone (vs all-time max)
        all_max = max(float(r["weight_kg"]) for r in rows)
        loss_kg = all_max - latest
        loss_lbs = loss_kg * 2.20462
        for milestone in sorted(WEIGHT_MILESTONES_LBS, reverse=True):
            if loss_lbs >= milestone:
                achievements.append({
                    "kind": "weight_milestone",
                    "milestone_lbs": milestone,
                    "loss_lbs": round(loss_lbs, 1),
                    "icon": "emoji_events",
                    "label": f"🎯 Down {milestone} lbs from your peak",
                })
                break

        return achievements
    except Exception as e:
        logger.debug(f"[Achievements] weight check failed: {e}")
        return []


async def _sleep_achievements(db, user_id: str, sleep_id: str, occurred_at: str) -> List[Dict[str, Any]]:
    """Best night this week annotation."""
    try:
        seven_day_ago = (datetime.fromisoformat(occurred_at.replace("Z", "+00:00")) -
                         timedelta(days=7)).isoformat()
        result = db.client.table("workouts").select(
            "duration_minutes, completed_at"
        ).eq("user_id", user_id).eq("type", "sleep").gte(
            "completed_at", seven_day_ago,
        ).order("completed_at", desc=True).execute()
        rows = result.data or []
        if len(rows) < 2:
            return []
        latest = rows[0].get("duration_minutes") or 0
        prior = [r.get("duration_minutes") or 0 for r in rows[1:]]
        avg_prior = sum(prior) / len(prior) if prior else 0
        if latest > avg_prior + 30:  # >30 min more than 7-day avg
            return [{
                "kind": "sleep_best",
                "duration_minutes": latest,
                "icon": "bedtime",
                "label": f"📈 Best sleep this week ({latest // 60}h {latest % 60}m)",
            }]
    except Exception as e:
        logger.debug(f"[Achievements] sleep check failed: {e}")
    return []
