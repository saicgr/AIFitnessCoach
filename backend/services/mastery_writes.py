"""
Mastery write path.

Reads authoritative aggregates from the tables that actually exist in
production and upserts the six seeded masteries:
    steps | calories | running | active_minutes | sessions | elevation

Source tables (verified against live schema):
  - `workouts`             — AI-generated + Health Connect / Apple Health
                              imports. `is_completed=true` + name +
                              scheduled_date + duration_minutes. Rich
                              `generation_metadata` jsonb with per-import
                              extras (calories_burned, distance_m, hr_samples
                              when available, etc.).
  - `workout_logs`         — per-session log of an app-completed workout
                              (status='completed', duration_minutes).
  - `cardio_logs`          — file-imported / OAuth-streamed cardio.
  - `workout_history_imports` — file-imported strength (multiple rows per
                                session; group by date).

Called from the sync path (apple_health_push) and the completion path
(workouts/complete). Existing read endpoint `GET /masteries/{user_id}`
stays untouched; it reads `user_masteries`.

Thresholds + level math intentionally mirror `api/v1/masteries.py` — if
thresholds change both files must move together.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Dict, List

from core.logger import get_logger
from core.supabase_db import get_supabase_db

logger = get_logger(__name__)


RUNNING_ACTIVITY_TYPES = ("run", "trail_run", "treadmill")
RUNNING_WORKOUT_TYPES = ("running", "run", "jog", "jogging")


def _level_for_value(thresholds: List[int], current_value: int) -> int:
    level = 0
    for t in thresholds:
        if current_value >= t:
            level += 1
        else:
            break
    if thresholds and current_value >= thresholds[-1]:
        last = int(thresholds[-1])
        step = last * 2
        while current_value >= step:
            level += 1
            step *= 2
    return level


def _fetch_definitions(db) -> Dict[str, List[int]]:
    rows = (
        db.client.table("mastery_definitions")
        .select("key, level_thresholds")
        .execute()
    )
    out: Dict[str, List[int]] = {}
    for r in (rows.data or []):
        thresholds = r.get("level_thresholds") or []
        out[r["key"]] = [int(t) for t in thresholds]
    return out


def _coerce_metadata(raw: Any) -> Dict[str, Any]:
    """`generation_metadata` is sometimes stored as a JSON-encoded string
    inside a jsonb column. Unwrap both shapes so callers get a dict."""
    if raw is None:
        return {}
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        try:
            decoded = json.loads(raw)
            return decoded if isinstance(decoded, dict) else {}
        except Exception:
            return {}
    return {}


def _compute_aggregates(db, user_id: str) -> Dict[str, int]:
    """SQL aggregates for every mastery key.

    Returns {'steps': …, 'calories': …, 'running': …, 'active_minutes': …,
    'sessions': …, 'elevation': …} with 0 for anything we can't find.

    Units:
      calories       → kcal Σ (cardio_logs.calories +
                               workouts.generation_metadata.calories_burned)
      running        → km Σ (distance_m / 1000) across running activities
                       (cardio_logs) + running-type completed workouts
      active_minutes → minutes Σ (duration across completed workouts +
                       cardio_logs)
      sessions       → count(completed workouts) + count(cardio_logs) +
                       count(import session-days)
      elevation      → metres Σ elevation_gain_m (cardio_logs)
      steps          → 0 for now (no dedicated source; Apple Health step
                       stream lands in `activity_logs`, out of scope here)
    """
    agg: Dict[str, int] = {
        "steps": 0,
        "calories": 0,
        "running": 0,
        "active_minutes": 0,
        "sessions": 0,
        "elevation": 0,
    }

    # ── Completed app + imported workouts from the main `workouts` table.
    # Covers both AI-generated sessions (AI workouts have is_completed set
    # on /workouts/{id}/complete) and Health Connect / Apple Health
    # imports (generation_method = 'health_connect_import' stores calories
    # in generation_metadata.calories_burned).
    try:
        workouts = (
            db.client.table("workouts")
            .select(
                "id, type, duration_minutes, generation_metadata, "
                "generation_method"
            )
            .eq("user_id", user_id)
            .eq("is_completed", True)
            .execute()
        )
        for w in (workouts.data or []):
            agg["sessions"] += 1
            dur_m = int(w.get("duration_minutes") or 0)
            agg["active_minutes"] += max(0, dur_m)
            meta = _coerce_metadata(w.get("generation_metadata"))
            kcal = meta.get("calories_burned") or meta.get("calories_active") \
                   or meta.get("calories_total") or meta.get("calories")
            if isinstance(kcal, (int, float)) and kcal > 0:
                agg["calories"] += int(kcal)
            dist_m = meta.get("distance_m") or meta.get("distance_meters")
            w_type = (w.get("type") or "").lower()
            if isinstance(dist_m, (int, float)) and dist_m > 0 \
                    and (w_type in RUNNING_WORKOUT_TYPES):
                agg["running"] += int(float(dist_m) / 1000.0)
            elev = meta.get("elevation_gain_m")
            if isinstance(elev, (int, float)) and elev > 0:
                agg["elevation"] += int(elev)
    except Exception as e:
        logger.warning(f"[mastery_writes] workouts rollup failed for {user_id}: {e}")

    # ── workout_logs — the per-session log used by strength workouts.
    # Session count here is strictly additive *only for logs without an
    # attached `workouts` row* (otherwise we'd double-count). Most logs do
    # have workout_id → we already counted those above. Keep the rollup
    # narrow to duration for logs that don't join back.
    #
    # Simpler safe approach: skip workout_logs entirely here to avoid
    # double-counting. The `workouts` loop above already covers completed
    # sessions.
    #
    # (Kept as a block for future extension.)

    # ── cardio_logs (file imports / OAuth streams) — independent of the
    # `workouts` table, so count freely.
    try:
        cardio = (
            db.client.table("cardio_logs")
            .select(
                "activity_type, duration_seconds, distance_m, "
                "elevation_gain_m, calories"
            )
            .eq("user_id", user_id)
            .execute()
        )
        for r in (cardio.data or []):
            agg["sessions"] += 1
            kcal = int(r.get("calories") or 0)
            agg["calories"] += max(0, kcal)
            dur_s = int(r.get("duration_seconds") or 0)
            agg["active_minutes"] += max(0, dur_s // 60)
            elev = r.get("elevation_gain_m")
            if elev is not None:
                agg["elevation"] += int(float(elev))
            activity = (r.get("activity_type") or "").lower()
            if activity in RUNNING_ACTIVITY_TYPES:
                dist_m = r.get("distance_m")
                if dist_m is not None:
                    agg["running"] += int(float(dist_m) / 1000.0)
    except Exception as e:
        logger.warning(f"[mastery_writes] cardio rollup failed for {user_id}: {e}")

    # ── workout_history_imports — strength imports, one "session" per
    # distinct performed_at date (adapter can emit many rows per session).
    try:
        imports = (
            db.client.table("workout_history_imports")
            .select("performed_at")
            .eq("user_id", user_id)
            .execute()
        )
        unique_days: set = set()
        for r in (imports.data or []):
            ts = r.get("performed_at")
            if ts:
                unique_days.add(str(ts)[:10])
        agg["sessions"] += len(unique_days)
    except Exception as e:
        logger.warning(f"[mastery_writes] imports rollup failed for {user_id}: {e}")

    return agg


def recompute_masteries(user_id: str) -> Dict[str, int]:
    """Re-aggregate + upsert user_masteries. Idempotent, swallows errors."""
    try:
        db = get_supabase_db()
        defs = _fetch_definitions(db)
        if not defs:
            logger.warning(
                f"[mastery_writes] no mastery_definitions rows, skipping "
                f"for user={user_id}"
            )
            return {}

        aggregates = _compute_aggregates(db, user_id)
        now_iso = datetime.now(timezone.utc).isoformat()

        rows_to_upsert = []
        for key, thresholds in defs.items():
            value = int(aggregates.get(key, 0))
            level = _level_for_value(thresholds, value)
            rows_to_upsert.append({
                "user_id": user_id,
                "mastery_key": key,
                "current_value": value,
                "current_level": level,
                "updated_at": now_iso,
            })

        if rows_to_upsert:
            db.client.table("user_masteries").upsert(
                rows_to_upsert,
                on_conflict="user_id,mastery_key",
            ).execute()

        logger.info(
            f"🏅 [mastery_writes] user={user_id} recomputed "
            f"{len(rows_to_upsert)} mastery rows: {aggregates}"
        )
        return aggregates
    except Exception as e:
        logger.error(
            f"[mastery_writes] recompute_masteries failed for {user_id}: {e}",
            exc_info=True,
        )
        return {}


async def check_all_trophies_and_masteries(user_id: str) -> None:
    """Fire trophy check + mastery recompute. Swallows every error so a
    broken trophy path can't 500 the caller."""
    try:
        from api.v1.trophy_triggers import check_all_trophies
        await check_all_trophies(user_id)
    except Exception as e:
        logger.error(
            f"[mastery_writes] check_all_trophies failed for {user_id}: {e}",
            exc_info=True,
        )
    recompute_masteries(user_id)
