"""
One-time backfill: index existing completed workouts, daily food-log days,
and nightly sleep into the three `user_*_history` Chroma collections.

Plan: §1b.9.

Idempotent: each doc id is `{user_id}:{event_id_or_date}`. Re-running the
script skips already-indexed events via `doc_exists()`.

Usage:
    python -m backend.scripts.backfill_user_history_rag [--user-id UUID]
                                                        [--limit-users N]
                                                        [--days 365]

The script is intentionally synchronous + chunked so progress is visible.
DO NOT run automatically in CI — invoke once per release if the user-history
shape changes. See `feedback_run_migrations_directly.md` for the standing
backend/.venv invocation pattern.
"""
from __future__ import annotations

import argparse
import logging
import sys
from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s %(levelname)s %(name)s | %(message)s")
logger = logging.getLogger("backfill_user_history_rag")


def _iter_users(sb, limit: Optional[int] = None) -> List[str]:
    """Pull active users (onboarding completed). Best-effort — falls back
    to all users if the join fails."""
    try:
        q = sb.client.table("users").select("id").eq("onboarding_completed", True)
        if limit:
            q = q.limit(limit)
        res = q.execute()
        return [r["id"] for r in (res.data or []) if r.get("id")]
    except Exception as e:
        logger.error(f"user list failed: {e}")
        return []


def _backfill_workouts(sb, user_id: str, since_iso: str, progress: Dict[str, int]) -> int:
    from services.chroma.user_history_collection import (
        WORKOUT_COLLECTION, doc_exists, index_workout,
    )
    inserted = 0
    try:
        wr = sb.client.table("workouts").select(
            "id, name, scheduled_date, completed_at, is_completed, "
            "exercises_json, duration_minutes, generation_metadata"
        ).eq("user_id", user_id).gte(
            "scheduled_date", since_iso
        ).order("scheduled_date").execute()
        for row in (wr.data or []):
            if not (row.get("completed_at") or row.get("is_completed")):
                continue
            wid = row.get("id")
            if not wid:
                continue
            if doc_exists(WORKOUT_COLLECTION, f"{user_id}:{wid}"):
                continue
            if index_workout(user_id, row):
                inserted += 1
                progress["docs"] += 1
                if progress["docs"] % 100 == 0:
                    logger.info(f"  ... {progress['docs']} docs indexed")
    except Exception as e:
        logger.warning(f"[backfill] workouts user={user_id} failed: {e}")
    return inserted


def _backfill_nutrition(sb, user_id: str, since_iso: str, progress: Dict[str, int]) -> int:
    from services.chroma.user_history_collection import (
        NUTRITION_COLLECTION, doc_exists, index_nutrition_day,
    )
    inserted = 0
    try:
        # User targets (best-effort).
        ur = sb.client.table("users").select(
            "daily_calorie_target, daily_protein_target_g"
        ).eq("id", user_id).maybe_single().execute()
        cal_target = (ur.data or {}).get("daily_calorie_target") if ur and ur.data else None
        prot_target = (ur.data or {}).get("daily_protein_target_g") if ur and ur.data else None

        fl = sb.client.table("food_logs").select(
            "total_calories, protein_g, logged_at, meal_type, deleted_at, food_name"
        ).eq("user_id", user_id).gte("logged_at", since_iso).is_(
            "deleted_at", "null"
        ).execute()
        by_day: Dict[str, Dict[str, Any]] = defaultdict(
            lambda: {"kcal": 0, "protein": 0.0, "meals": []}
        )
        for r in (fl.data or []):
            ts = r.get("logged_at")
            if not ts:
                continue
            d = ts[:10]
            by_day[d]["kcal"] += int(r.get("total_calories") or 0)
            by_day[d]["protein"] += float(r.get("protein_g") or 0)
            name = r.get("food_name") or r.get("meal_type")
            if name and isinstance(name, str):
                by_day[d]["meals"].append(name[:30])
        for d, agg in sorted(by_day.items()):
            if doc_exists(NUTRITION_COLLECTION, f"{user_id}:{d}"):
                continue
            if index_nutrition_day(
                user_id, d,
                kcal=agg["kcal"] or None,
                protein_g=round(agg["protein"], 1) or None,
                meals=agg["meals"][:6],
                calorie_target=cal_target,
                protein_target=float(prot_target) if prot_target else None,
            ):
                inserted += 1
                progress["docs"] += 1
                if progress["docs"] % 100 == 0:
                    logger.info(f"  ... {progress['docs']} docs indexed")
    except Exception as e:
        logger.warning(f"[backfill] nutrition user={user_id} failed: {e}")
    return inserted


def _backfill_sleep(sb, user_id: str, since_date: str, progress: Dict[str, int]) -> int:
    from services.chroma.user_history_collection import (
        SLEEP_COLLECTION, doc_exists, index_sleep_night,
    )
    inserted = 0
    try:
        da = sb.client.table("daily_activity").select(
            "activity_date, sleep_minutes, sleep_start"
        ).eq("user_id", user_id).gte(
            "activity_date", since_date
        ).execute()
        for row in (da.data or []):
            sm = row.get("sleep_minutes") or 0
            if sm <= 0:
                continue
            d = row.get("activity_date")
            if not d:
                continue
            if doc_exists(SLEEP_COLLECTION, f"{user_id}:{d}"):
                continue
            bedtime = None
            bt = row.get("sleep_start")
            if bt:
                try:
                    dt = datetime.fromisoformat(bt.replace("Z", "+00:00"))
                    bedtime = dt.strftime("%H:%M")
                except Exception:
                    bedtime = None
            if index_sleep_night(user_id, d, minutes=int(sm), bedtime=bedtime):
                inserted += 1
                progress["docs"] += 1
                if progress["docs"] % 100 == 0:
                    logger.info(f"  ... {progress['docs']} docs indexed")
    except Exception as e:
        logger.warning(f"[backfill] sleep user={user_id} failed: {e}")
    return inserted


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-id", help="Single user UUID (skips iteration)")
    parser.add_argument("--limit-users", type=int, default=None)
    parser.add_argument("--days", type=int, default=365,
                        help="How far back to index (default: 365d)")
    args = parser.parse_args()

    # Lazy imports — ensures module compiles even if backend env is missing.
    try:
        from core.db import get_supabase_db  # noqa: F401
        from services.chroma.user_history_collection import ensure_collections
    except Exception as e:
        logger.error(f"backend env not importable: {e}")
        sys.exit(1)

    init = ensure_collections()
    logger.info(f"Collection init: {init}")

    from core.db import get_supabase_db
    sb = get_supabase_db()

    if args.user_id:
        user_ids = [args.user_id]
    else:
        user_ids = _iter_users(sb, args.limit_users)
        logger.info(f"Indexing {len(user_ids)} users")

    cutoff = date.today() - timedelta(days=args.days)
    since_date = cutoff.isoformat()
    since_iso = f"{since_date}T00:00:00+00:00"
    progress = {"docs": 0}

    totals = {"workouts": 0, "nutrition": 0, "sleep": 0}
    for i, uid in enumerate(user_ids, 1):
        logger.info(f"[{i}/{len(user_ids)}] user={uid}")
        totals["workouts"] += _backfill_workouts(sb, uid, since_iso, progress)
        totals["nutrition"] += _backfill_nutrition(sb, uid, since_iso, progress)
        totals["sleep"] += _backfill_sleep(sb, uid, since_date, progress)

    logger.info(f"DONE. {progress['docs']} total docs. breakdown={totals}")


if __name__ == "__main__":
    main()
