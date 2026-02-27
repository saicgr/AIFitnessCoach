"""
Plateau Detection API - Detect exercise and weight plateaus for users.

This module analyzes performance logs and weight metrics to identify stalling:
- Exercise plateaus: 1RM variance < 3% over 4+ sessions
- Weight plateaus: < 0.2kg change over 3+ weeks
- Generates actionable recommendations (wave loading, deload, diet break, etc.)

ENDPOINTS:
- GET /api/v1/plateau/{user_id}/dashboard - Get plateau detection dashboard
"""

from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from collections import defaultdict
import statistics
import logging

from core.supabase_client import get_supabase
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


def get_supabase_client():
    """Get Supabase client for database operations."""
    return get_supabase().client


# =============================================================================
# Helper Functions
# =============================================================================

def _estimate_1rm(weight: float, reps: int) -> float:
    """Estimate 1RM using Epley formula: weight * (1 + reps/30)."""
    if reps <= 0 or weight <= 0:
        return 0.0
    if reps == 1:
        return weight
    return weight * (1 + reps / 30.0)


def _detect_exercise_plateaus(logs: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Group logs by exercise, look at last 4+ sessions per exercise.
    If 1RM variance < 3% across those sessions, it's a plateau.
    """
    if not logs:
        return []

    # Group logs by exercise name
    exercise_sessions: Dict[str, List[Dict]] = defaultdict(list)
    for log in logs:
        name = log.get("exercise_name") or log.get("name", "Unknown")
        weight = log.get("weight") or log.get("weight_kg") or 0
        reps = log.get("reps") or 0
        created_at = log.get("created_at", "")

        if weight > 0 and reps > 0:
            exercise_sessions[name].append({
                "weight": float(weight),
                "reps": int(reps),
                "created_at": created_at,
                "estimated_1rm": _estimate_1rm(float(weight), int(reps)),
            })

    plateaus = []
    strategies = [
        "wave_loading",
        "deload_week",
        "double_progression",
        "rep_range_change",
        "tempo_variation",
    ]

    for exercise_name, sessions in exercise_sessions.items():
        # Sort by date descending, take last 4+ sessions
        sessions.sort(key=lambda s: s["created_at"], reverse=True)

        if len(sessions) < 4:
            continue

        recent = sessions[:8]  # Look at up to 8 recent sessions
        one_rms = [s["estimated_1rm"] for s in recent if s["estimated_1rm"] > 0]

        if len(one_rms) < 4:
            continue

        mean_1rm = statistics.mean(one_rms)
        if mean_1rm == 0:
            continue

        # Calculate coefficient of variation (CV)
        stdev = statistics.stdev(one_rms) if len(one_rms) > 1 else 0
        cv = (stdev / mean_1rm) * 100  # as percentage

        if cv < 3.0:
            # Plateau detected
            sessions_count = len(one_rms)
            strategy_index = hash(exercise_name) % len(strategies)
            plateaus.append({
                "exercise_name": exercise_name,
                "sessions_stalled": sessions_count,
                "current_1rm": round(mean_1rm, 1),
                "variance_percent": round(cv, 2),
                "suggested_strategy": strategies[strategy_index],
            })

    # Sort by sessions stalled descending
    plateaus.sort(key=lambda p: p["sessions_stalled"], reverse=True)
    return plateaus


def _detect_weight_plateau(entries: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Group weight entries by week, check if weight change < 0.2kg over 3+ weeks.
    """
    if not entries:
        return {
            "is_plateaued": False,
            "weeks_stalled": 0,
            "current_weight": None,
            "suggested_action": None,
        }

    # Parse and sort entries by date
    parsed = []
    for entry in entries:
        value = entry.get("value") or entry.get("weight")
        created_at = entry.get("created_at", "")
        if value is not None:
            try:
                parsed.append({
                    "weight": float(value),
                    "created_at": created_at,
                })
            except (ValueError, TypeError):
                continue

    if len(parsed) < 3:
        return {
            "is_plateaued": False,
            "weeks_stalled": 0,
            "current_weight": parsed[0]["weight"] if parsed else None,
            "suggested_action": None,
        }

    # Sort by date descending
    parsed.sort(key=lambda e: e["created_at"], reverse=True)

    # Group by ISO week
    weekly_averages: Dict[str, List[float]] = defaultdict(list)
    for entry in parsed:
        try:
            dt = datetime.fromisoformat(entry["created_at"].replace("Z", "+00:00"))
            week_key = f"{dt.isocalendar()[0]}-W{dt.isocalendar()[1]:02d}"
            weekly_averages[week_key].append(entry["weight"])
        except (ValueError, AttributeError):
            continue

    if len(weekly_averages) < 3:
        return {
            "is_plateaued": False,
            "weeks_stalled": 0,
            "current_weight": parsed[0]["weight"],
            "suggested_action": None,
        }

    # Calculate weekly averages and sort
    week_avgs = []
    for week_key in sorted(weekly_averages.keys(), reverse=True):
        avg = statistics.mean(weekly_averages[week_key])
        week_avgs.append({"week": week_key, "avg_weight": avg})

    # Check recent weeks for plateau (< 0.2kg change across 3+ weeks)
    current_weight = week_avgs[0]["avg_weight"]
    weeks_stalled = 0

    for i in range(1, len(week_avgs)):
        diff = abs(current_weight - week_avgs[i]["avg_weight"])
        if diff < 0.2:
            weeks_stalled += 1
        else:
            break

    is_plateaued = weeks_stalled >= 3

    actions = ["diet_break", "reverse_diet", "increase_cardio", "recalculate_tdee"]
    suggested_action = None
    if is_plateaued:
        action_index = weeks_stalled % len(actions)
        suggested_action = actions[action_index]

    return {
        "is_plateaued": is_plateaued,
        "weeks_stalled": weeks_stalled,
        "current_weight": round(current_weight, 1),
        "suggested_action": suggested_action,
    }


def _generate_recommendations(
    exercise_plateaus: List[Dict[str, Any]],
    weight_plateau: Dict[str, Any],
) -> List[str]:
    """Generate actionable recommendations based on detected plateaus."""
    recommendations = []

    if not exercise_plateaus and not weight_plateau.get("is_plateaued"):
        recommendations.append(
            "No plateaus detected. You're making consistent progress!"
        )
        return recommendations

    # Exercise plateau recommendations
    if exercise_plateaus:
        count = len(exercise_plateaus)
        recommendations.append(
            f"{count} exercise{'s' if count > 1 else ''} showing plateau patterns. "
            "Consider varying your rep ranges or training intensity."
        )

        strategy_explanations = {
            "wave_loading": "Try wave loading: alternate between heavy (3-5 reps) and moderate (8-12 reps) sessions.",
            "deload_week": "Schedule a deload week at 50-60% intensity to allow recovery and supercompensation.",
            "double_progression": "Use double progression: increase reps first, then add weight when you hit the top of the range.",
            "rep_range_change": "Switch rep ranges (e.g., from 5x5 to 3x10) to stimulate new adaptation.",
            "tempo_variation": "Add tempo training (3-1-3-0) to increase time under tension without adding weight.",
        }

        seen_strategies = set()
        for plateau in exercise_plateaus[:3]:  # Top 3 exercises
            strategy = plateau["suggested_strategy"]
            if strategy not in seen_strategies:
                seen_strategies.add(strategy)
                if strategy in strategy_explanations:
                    recommendations.append(strategy_explanations[strategy])

    # Weight plateau recommendations
    if weight_plateau.get("is_plateaued"):
        weeks = weight_plateau.get("weeks_stalled", 0)
        recommendations.append(
            f"Weight has been stagnant for {weeks} weeks. "
            "Your body may have adapted to current caloric intake."
        )

        action_explanations = {
            "diet_break": "Consider a 1-2 week diet break at maintenance calories to reset metabolic adaptation.",
            "reverse_diet": "Gradually increase calories by 50-100/week to boost metabolism before resuming deficit.",
            "increase_cardio": "Add 1-2 low-intensity cardio sessions per week to increase energy expenditure.",
            "recalculate_tdee": "Recalculate your TDEE based on current weight - your needs may have changed.",
        }

        action = weight_plateau.get("suggested_action")
        if action and action in action_explanations:
            recommendations.append(action_explanations[action])

    return recommendations


# =============================================================================
# Endpoints
# =============================================================================

@router.get("/{user_id}/dashboard")
async def get_plateau_dashboard(user_id: str):
    """Detect exercise and weight plateaus for a user."""
    try:
        supabase = get_supabase_client()

        # 1. Exercise plateaus - query performance_logs
        logs_response = (
            supabase.table("performance_logs")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(500)
            .execute()
        )

        exercise_plateaus = _detect_exercise_plateaus(logs_response.data or [])

        # 2. Weight plateau - query weight entries from metrics
        weight_response = (
            supabase.table("metrics")
            .select("*")
            .eq("user_id", user_id)
            .eq("type", "weight")
            .order("created_at", desc=True)
            .limit(30)
            .execute()
        )

        weight_plateau = _detect_weight_plateau(weight_response.data or [])

        # 3. Generate recommendations
        recommendations = _generate_recommendations(exercise_plateaus, weight_plateau)

        # Overall status
        if exercise_plateaus or (weight_plateau and weight_plateau.get("is_plateaued")):
            overall_status = "plateaued"
        else:
            overall_status = "progressing"

        return {
            "exercise_plateaus": exercise_plateaus,
            "weight_plateau": weight_plateau,
            "overall_status": overall_status,
            "recommendations": recommendations,
        }

    except Exception as e:
        logger.error(f"Error detecting plateaus for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to analyze plateau data")
