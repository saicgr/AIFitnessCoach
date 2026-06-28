"""
Adaptive nutrition weekly auto-adjust job + shared apply helpers.
=================================================================

The adaptive TDEE engine already exists (services/adaptive_tdee_service.py:
energy-balance TDEE from 14d intake + weight trend, EMA-smoothed, with a
0-1 data-quality score). The gap this module closes: the recommended target
was never WRITTEN back to nutrition_preferences.target_calories.

This module provides the write side, used in two places:

  1. One-tap apply — POST /nutrition/adaptive/{user_id}/apply (api/v1/nutrition/
     adaptive.py) recomputes the latest recommendation and applies it on demand.

  2. Weekly sweep — for users who opted in (nutrition_preferences
     .auto_adjust_weekly = true, migration 2296), `run_full_sweep` recomputes the
     adaptive TDEE and APPLIES the new target ONLY when the service's
     data-quality score is high (>= CONFIDENCE_THRESHOLD = 0.6). Below that it
     leaves a pending weekly recommendation instead of silently applying a
     low-confidence number.

Everything here is a pure function over a Supabase client (`db.client`), so the
endpoint, the cron entrypoint, and the unit tests all drive the same code.

`user_id` is ALWAYS public.users.id (the app id), NOT auth_id — same as every
other nutrition table (food_logs / weight_logs / nutrition_preferences all key
on public.users.id).

Scheduling: run via the `fitwiz-adaptive-weekly` Render cron (render.yaml) as
`python -m services.adaptive_weekly_job`. See the `__main__` guard below.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from services.adaptive_tdee_service import (
    FoodLogSummary,
    WeightLog,
    get_adaptive_tdee_service,
)

logger = logging.getLogger(__name__)


# Data-quality / confidence floor for the UNATTENDED weekly auto-apply. The
# service's data_quality_score is 0-1 (food-logging consistency 0.50 + weight
# frequency 0.30 + time span 0.20). 0.6 ≈ "logged most days for ~10+ days with a
# handful of weigh-ins" — enough signal to move someone's calorie target without
# a human in the loop. Below this the job leaves a pending recommendation.
CONFIDENCE_THRESHOLD = 0.6

# Default trailing window for the energy-balance read (days).
DEFAULT_WINDOW_DAYS = 14

# Below this absolute kcal delta an auto-adjust is noise — skip the write so the
# weekly job doesn't churn the target by ±10 kcal every Monday.
MIN_MEANINGFUL_DELTA_KCAL = 25


# ---------------------------------------------------------------------------
# 1. Recompute the adaptive TDEE for one user (reuses the existing service).
# ---------------------------------------------------------------------------

def recompute_adaptive_tdee(
    db,
    user_id: str,
    *,
    days: int = DEFAULT_WINDOW_DAYS,
    now: Optional[datetime] = None,
) -> Optional[Dict[str, Any]]:
    """Recompute the energy-balance TDEE for a user over the trailing `days`.

    Pulls daily food-log summaries + weigh-ins and runs them through the
    existing `AdaptiveTDEEService.calculate_tdee_with_confidence` — we do NOT
    re-implement the TDEE math here.

    Returns a dict {tdee, data_quality_score, confidence_level, avg_daily_intake,
    weight_change_kg, days_analyzed, food_logs_count, weight_logs_count} or None
    when there is insufficient data (the service returns None below its minimum
    food/weight log thresholds).
    """
    now = now or datetime.now(timezone.utc)
    since = now - timedelta(days=days)
    since_iso = since.strftime("%Y-%m-%dT00:00:00")

    # --- Food logs → one FoodLogSummary per local-ish calendar day ----------
    try:
        food_res = (
            db.client.table("food_logs")
            .select("logged_at, total_calories, protein_g, carbs_g, fat_g")
            .eq("user_id", str(user_id))
            .is_("deleted_at", "null")
            .gte("logged_at", since_iso)
            .execute()
        )
        food_rows = food_res.data or []
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[AdaptiveWeekly] food_logs fetch failed user={user_id}: {e}")
        food_rows = []

    daily: Dict[Any, Dict[str, float]] = {}
    for row in food_rows:
        raw = row.get("logged_at")
        if not raw:
            continue
        try:
            d = datetime.fromisoformat(str(raw).replace("Z", "+00:00")).date()
        except (ValueError, TypeError):
            continue
        bucket = daily.setdefault(
            d, {"cal": 0.0, "protein": 0.0, "carbs": 0.0, "fat": 0.0}
        )
        bucket["cal"] += float(row.get("total_calories") or 0)
        bucket["protein"] += float(row.get("protein_g") or 0)
        bucket["carbs"] += float(row.get("carbs_g") or 0)
        bucket["fat"] += float(row.get("fat_g") or 0)

    food_summaries: List[FoodLogSummary] = [
        FoodLogSummary(
            date=d,
            total_calories=int(round(v["cal"])),
            protein_g=v["protein"],
            carbs_g=v["carbs"],
            fat_g=v["fat"],
        )
        for d, v in sorted(daily.items())
    ]

    # --- Weight logs --------------------------------------------------------
    try:
        weight_res = (
            db.client.table("weight_logs")
            .select("id, weight_kg, logged_at")
            .eq("user_id", str(user_id))
            .gte("logged_at", since_iso)
            .order("logged_at", desc=False)
            .execute()
        )
        weight_rows = weight_res.data or []
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[AdaptiveWeekly] weight_logs fetch failed user={user_id}: {e}")
        weight_rows = []

    weight_logs: List[WeightLog] = []
    for row in weight_rows:
        raw = row.get("logged_at")
        try:
            logged_at = datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
            weight_kg = float(row["weight_kg"])
        except (ValueError, TypeError, KeyError):
            continue
        weight_logs.append(
            WeightLog(
                id=str(row.get("id", "")),
                user_id=str(user_id),
                weight_kg=weight_kg,
                logged_at=logged_at,
            )
        )

    svc = get_adaptive_tdee_service()
    calc = svc.calculate_tdee_with_confidence(food_summaries, weight_logs, days=days)
    if calc is None:
        return None

    quality = calc.data_quality_score
    confidence = "low" if quality < 0.4 else "medium" if quality < 0.7 else "high"
    return {
        "tdee": calc.tdee,
        "data_quality_score": quality,
        "confidence_level": confidence,
        "avg_daily_intake": calc.avg_daily_intake,
        "weight_change_kg": calc.weight_change_kg,
        "days_analyzed": calc.days_analyzed,
        "food_logs_count": calc.food_logs_count,
        "weight_logs_count": calc.weight_logs_count,
    }


# ---------------------------------------------------------------------------
# 2. Turn a TDEE + the user's goal into a recommended target + macro split.
# ---------------------------------------------------------------------------

def compute_recommended_targets(tdee: int, prefs: Dict[str, Any]) -> Dict[str, Any]:
    """Derive the recommended calorie target + macro split from TDEE + goal.

    Mirrors the goal-based adjustment in
    api/v1/nutrition/weekly_recommendations.generate_weekly_recommendation so the
    apply path and the surfaced recommendation agree:
      * fat-loss goal  → TDEE - 500
      * muscle-gain    → TDEE + 250
      * maintain       → TDEE
    Macros use a balanced 30P / 40C / 30F split. Goal matching is substring-based
    so it tolerates the several goal spellings in the wild (lose_fat / lose_weight,
    build_muscle / gain_muscle, etc.).

    Returns {recommended_calories, recommended_protein_g, recommended_carbs_g,
    recommended_fat_g, goal, target_rate_per_week}.
    """
    goal = str(prefs.get("nutrition_goal") or "maintain").lower()

    if "lose" in goal or "fat" in goal or "cut" in goal:
        recommended = tdee - 500
        rate = -0.5
    elif "gain" in goal or "muscle" in goal or "build" in goal or "bulk" in goal:
        recommended = tdee + 250
        rate = 0.25
    else:  # maintain / recomp / anything else
        recommended = tdee
        rate = 0.0

    # Never recommend a dangerously low floor (mirrors the service MIN_TDEE-ish
    # guard the calculate endpoint applies).
    recommended = max(1000, int(recommended))

    protein = int((recommended * 0.30) / 4)  # 4 kcal/g
    carbs = int((recommended * 0.40) / 4)    # 4 kcal/g
    fat = int((recommended * 0.30) / 9)      # 9 kcal/g

    return {
        "recommended_calories": recommended,
        "recommended_protein_g": protein,
        "recommended_carbs_g": carbs,
        "recommended_fat_g": fat,
        "goal": goal,
        "target_rate_per_week": rate,
    }


# ---------------------------------------------------------------------------
# 3. Apply a recommendation to nutrition_preferences. Returns old → new.
# ---------------------------------------------------------------------------

def _fetch_prefs(db, user_id: str) -> Dict[str, Any]:
    """Read the user's nutrition_preferences row (or {} when absent)."""
    res = (
        db.client.table("nutrition_preferences")
        .select("*")
        .eq("user_id", str(user_id))
        .maybe_single()
        .execute()
    )
    return (res.data if res and res.data else None) or {}


def apply_targets(
    db,
    user_id: str,
    recommendation: Dict[str, Any],
    *,
    tdee: Optional[int] = None,
    prefs: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Write the recommended targets onto nutrition_preferences. Returns old→new.

    `prefs` may be passed to avoid a re-read (the caller usually already has it);
    otherwise it is fetched. The write upserts so a user with no preferences row
    yet still gets one created.

    Returns:
        {
          "old": {target_calories, target_protein_g, target_carbs_g, target_fat_g},
          "new": {target_calories, target_protein_g, target_carbs_g, target_fat_g},
          "calorie_delta": int,
          "calculated_tdee": int | None,
        }
    """
    if prefs is None:
        prefs = _fetch_prefs(db, user_id)

    old = {
        "target_calories": prefs.get("target_calories"),
        "target_protein_g": prefs.get("target_protein_g"),
        "target_carbs_g": prefs.get("target_carbs_g"),
        "target_fat_g": prefs.get("target_fat_g"),
    }
    new = {
        "target_calories": recommendation["recommended_calories"],
        "target_protein_g": recommendation["recommended_protein_g"],
        "target_carbs_g": recommendation["recommended_carbs_g"],
        "target_fat_g": recommendation["recommended_fat_g"],
    }

    update_payload: Dict[str, Any] = dict(new)
    update_payload["last_recalculated_at"] = datetime.utcnow().isoformat()
    update_payload["updated_at"] = datetime.utcnow().isoformat()
    if tdee is not None:
        update_payload["calculated_tdee"] = int(tdee)

    if prefs.get("id") or prefs.get("user_id"):
        (
            db.client.table("nutrition_preferences")
            .update(update_payload)
            .eq("user_id", str(user_id))
            .execute()
        )
    else:
        update_payload["user_id"] = str(user_id)
        db.client.table("nutrition_preferences").insert(update_payload).execute()

    old_cal = old.get("target_calories")
    new_cal = new.get("target_calories")
    delta = (new_cal - old_cal) if (isinstance(old_cal, int) and isinstance(new_cal, int)) else new_cal

    return {
        "old": old,
        "new": new,
        "calorie_delta": delta,
        "calculated_tdee": int(tdee) if tdee is not None else None,
    }


# ---------------------------------------------------------------------------
# 4. Persist a PENDING recommendation (the low-confidence / not-applied path).
# ---------------------------------------------------------------------------

def leave_pending_recommendation(
    db,
    user_id: str,
    *,
    tdee: int,
    quality: float,
    recommendation: Dict[str, Any],
    today: Optional[datetime] = None,
) -> bool:
    """Insert a pending weekly_nutrition_recommendations row (user_accepted=False).

    Used when auto-apply is NOT warranted (data quality below threshold) so the
    user still SEES the suggestion via GET /nutrition/recommendations/{user_id}
    and can accept it manually. Best-effort: a failure here never breaks the
    sweep. Returns True on a successful insert.
    """
    today = today or datetime.utcnow()
    week_start = (today.date() - timedelta(days=today.weekday())).isoformat()
    row = {
        "user_id": str(user_id),
        "week_start": week_start,
        "current_goal": recommendation.get("goal", "maintain"),
        "target_rate_per_week": recommendation.get("target_rate_per_week", 0.0),
        "calculated_tdee": int(tdee),
        "recommended_calories": recommendation["recommended_calories"],
        "recommended_protein_g": recommendation["recommended_protein_g"],
        "recommended_carbs_g": recommendation["recommended_carbs_g"],
        "recommended_fat_g": recommendation["recommended_fat_g"],
        "adjustment_reason": (
            f"Based on your tracked trend (data quality {quality:.0%}). Review and "
            "apply when you're ready — confidence wasn't high enough to auto-update."
        ),
        "user_accepted": False,
        "user_modified": False,
    }
    try:
        db.client.table("weekly_nutrition_recommendations").insert(row).execute()
        return True
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[AdaptiveWeekly] pending-rec insert failed user={user_id}: {e}")
        return False


# ---------------------------------------------------------------------------
# 5. Per-user weekly run + full sweep.
# ---------------------------------------------------------------------------

def run_for_user(
    db,
    user_id: str,
    *,
    threshold: float = CONFIDENCE_THRESHOLD,
    days: int = DEFAULT_WINDOW_DAYS,
    now: Optional[datetime] = None,
    dry_run: bool = False,
) -> Dict[str, Any]:
    """Recompute + (when confident) auto-apply one user's adaptive target.

    Decision:
      * insufficient data         → {applied: False, reason: 'insufficient_data'}
      * quality < threshold       → leave a pending recommendation,
                                     {applied: False, reason: 'low_confidence'}
      * |delta| < MIN_MEANINGFUL  → {applied: False, reason: 'no_change'}
      * else                      → apply, {applied: True, old, new, ...}
    """
    calc = recompute_adaptive_tdee(db, user_id, days=days, now=now)
    if calc is None or not calc.get("tdee"):
        return {"user_id": user_id, "applied": False, "reason": "insufficient_data"}

    tdee = int(calc["tdee"])
    quality = float(calc["data_quality_score"])
    prefs = _fetch_prefs(db, user_id)
    rec = compute_recommended_targets(tdee, prefs)

    if quality < threshold:
        wrote_pending = False
        if not dry_run:
            wrote_pending = leave_pending_recommendation(
                db, user_id, tdee=tdee, quality=quality, recommendation=rec, today=now
            )
        return {
            "user_id": user_id,
            "applied": False,
            "reason": "low_confidence",
            "data_quality_score": quality,
            "threshold": threshold,
            "pending_recommendation_written": wrote_pending,
        }

    current_cal = prefs.get("target_calories")
    new_cal = rec["recommended_calories"]
    if isinstance(current_cal, int) and abs(new_cal - current_cal) < MIN_MEANINGFUL_DELTA_KCAL:
        return {
            "user_id": user_id,
            "applied": False,
            "reason": "no_change",
            "data_quality_score": quality,
            "calorie_delta": new_cal - current_cal,
        }

    if dry_run:
        return {
            "user_id": user_id,
            "applied": False,
            "reason": "dry_run",
            "data_quality_score": quality,
            "would_set_calories": new_cal,
            "current_calories": current_cal,
        }

    result = apply_targets(db, user_id, rec, tdee=tdee, prefs=prefs)

    # Cache invalidation — a target change makes the cached daily-summary /
    # patterns / home-bootstrap payloads stale (mirrors the PUT /preferences
    # path). Best-effort: imported lazily, never fail the sweep on a cache miss.
    _invalidate_target_caches(user_id)

    # TODO(push): send a "Targets updated from your trend" push reusing the
    # notification path (services/notification_service.py + push_nudge_log dedup)
    # so the user learns their numbers moved. Left as a follow-up to avoid
    # coupling the unattended sweep to the FCM stack; for now we log it.
    logger.info(
        f"🎯 [AdaptiveWeekly] auto-applied targets user={user_id} "
        f"{result['old'].get('target_calories')}→{result['new']['target_calories']} kcal "
        f"(tdee={tdee}, quality={quality:.2f})"
    )

    return {
        "user_id": user_id,
        "applied": True,
        "data_quality_score": quality,
        "calculated_tdee": tdee,
        **result,
    }


def _invalidate_target_caches(user_id: str) -> None:
    """Best-effort bust of the per-user caches a target change invalidates.

    Imported lazily (and each guarded) so a missing module / event loop in a
    plain cron process never breaks the sweep.
    """
    import asyncio

    async def _run() -> None:
        try:
            from api.v1.nutrition.summaries import invalidate_daily_summary_cache
            await invalidate_daily_summary_cache(user_id)
        except Exception as e:  # noqa: BLE001
            logger.debug(f"[AdaptiveWeekly] daily-summary cache bust skipped: {e}")
        try:
            from api.v1.nutrition.food_patterns import invalidate_patterns_cache
            await invalidate_patterns_cache(user_id)
        except Exception as e:  # noqa: BLE001
            logger.debug(f"[AdaptiveWeekly] patterns cache bust skipped: {e}")
        try:
            from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
            await invalidate_bootstrap_cache(user_id)
        except Exception as e:  # noqa: BLE001
            logger.debug(f"[AdaptiveWeekly] bootstrap cache bust skipped: {e}")

    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            # Inside an async caller (the FastAPI endpoint) — schedule it.
            loop.create_task(_run())
        else:
            loop.run_until_complete(_run())
    except RuntimeError:
        # No event loop (bare cron thread) — make one.
        try:
            asyncio.run(_run())
        except Exception as e:  # noqa: BLE001
            logger.debug(f"[AdaptiveWeekly] cache bust loop skipped: {e}")


def _iter_auto_adjust_users(db) -> List[str]:
    """All user_ids opted in to the weekly auto-adjust (auto_adjust_weekly=true)."""
    try:
        res = (
            db.client.table("nutrition_preferences")
            .select("user_id")
            .eq("auto_adjust_weekly", True)
            .execute()
        )
        return [r["user_id"] for r in (res.data or []) if r.get("user_id")]
    except Exception as e:  # noqa: BLE001
        logger.error(f"[AdaptiveWeekly] opted-in user fetch failed: {e}")
        return []


def run_full_sweep(
    db=None,
    *,
    threshold: float = CONFIDENCE_THRESHOLD,
    days: int = DEFAULT_WINDOW_DAYS,
    dry_run: bool = False,
) -> Dict[str, Any]:
    """Sweep every opted-in user. Intended to run once weekly via Render cron."""
    if db is None:
        from core.db import get_supabase_db
        db = get_supabase_db()

    user_ids = _iter_auto_adjust_users(db)
    summaries: List[Dict[str, Any]] = []
    applied = 0
    for uid in user_ids:
        try:
            summary = run_for_user(
                db, uid, threshold=threshold, days=days, dry_run=dry_run
            )
        except Exception as e:  # noqa: BLE001
            logger.error(f"[AdaptiveWeekly] user={uid} failed: {e}")
            summary = {"user_id": uid, "applied": False, "error": str(e)}
        if summary.get("applied"):
            applied += 1
        summaries.append(summary)

    logger.info(
        f"🎯 [AdaptiveWeekly] sweep done: opted_in={len(user_ids)} applied={applied} "
        f"dry_run={dry_run}"
    )
    return {
        "opted_in": len(user_ids),
        "applied": applied,
        "dry_run": dry_run,
        "summaries": summaries,
    }


# ---------------------------------------------------------------------------
# Cron entrypoint: `python -m services.adaptive_weekly_job [--dry-run]`
# Registered as the `fitwiz-adaptive-weekly` Render cron in render.yaml.
# ---------------------------------------------------------------------------

def main() -> None:
    import sys

    logging.basicConfig(level=logging.INFO)
    dry_run = "--dry-run" in sys.argv
    result = run_full_sweep(dry_run=dry_run)
    print(
        f"[AdaptiveWeekly] opted_in={result['opted_in']} "
        f"applied={result['applied']} dry_run={result['dry_run']}"
    )


if __name__ == "__main__":
    main()
