"""Timeline aggregator endpoint.

`GET /api/v1/timeline?user_id=X&date=YYYY-MM-DD&days=1`

Aggregates every logged event for a user across all domains into a
journal-style chronological feed (workouts, food, water, sleep, weight,
mood, habits) with per-day summary headers (steps, calories, water,
sleep, streak), insights (rule-based one-liners), and inline
achievement chips (PRs, e1RM, weight trends).

Inspired by Zepp's Journal layout. Renders below "Your Habits" on the
home screen and under the MySpace edit-tile picker.

Cache: 60s TTL keyed on (user_id, date, days). Invalidated by every
write site via api/v1/timeline_cache.invalidate_timeline_cache.
"""
import asyncio
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from api.v1.timeline_cache import get_timeline_cache, set_timeline_cache
from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from core.timezone_utils import (
    get_user_today,
    local_date_to_utc_range,
    resolve_timezone,
)

logger = get_logger(__name__)
router = APIRouter()


# ---------------------------------------------------------------------------
# Source label mapping
# ---------------------------------------------------------------------------

SOURCE_LABELS = {
    # workouts
    "chat": ("Chat", "chat_bubble"),
    "manual": ("Manual", "edit"),
    "manual_log": ("Manual", "edit"),
    "voice": ("Voice", "mic"),
    "ai_plan": ("AI Plan", "auto_awesome"),
    "gemini_generation": ("AI Plan", "auto_awesome"),
    "streaming_generation": ("AI Plan", "auto_awesome"),
    "regenerate_stream_endpoint": ("AI Plan", "auto_awesome"),
    "mood_generation": ("Mood Pick", "mood"),
    "quick_workout": ("Quick", "bolt"),
    "library": ("Library", "library_books"),
    "onboarding": ("Onboarding", "celebration"),
    "safety_pipeline_replacement": ("Auto-replaced", "shield"),
    "auto_workout": ("Auto", "auto_awesome"),
    "health_connect": ("Health Connect", "watch"),
    "wearable_sync_apple_health": ("Apple Health", "favorite"),
    "wearable_sync_fitbit": ("Fitbit", "watch"),
    "wearable_sync_garmin": ("Garmin", "watch"),
    "wearable_sync_health_connect": ("Health Connect", "watch"),
    # food
    "menu_scan": ("Menu Scan", "restaurant_menu"),
    "camera": ("Camera", "photo_camera"),
    "barcode": ("Barcode", "qr_code_scanner"),
    "image": ("Camera", "photo_camera"),
    "text": ("Manual", "edit"),
    "direct": ("Manual", "edit"),
    "recipe": ("Recipe", "menu_book"),
    # hydration
    "workout": ("Auto (workout)", "fitness_center"),
    "auto_inference": ("Auto", "auto_awesome"),
}


def _label_source(raw: Optional[str]) -> Dict[str, str]:
    if not raw:
        return {"kind": "unknown", "label": "Logged", "icon": "edit"}
    key = raw.lower().strip()
    label, icon = SOURCE_LABELS.get(key, (raw.title().replace("_", " "), "edit"))
    return {"kind": key, "label": label, "icon": icon}


# ---------------------------------------------------------------------------
# Per-domain → TimelineEntry adapters
# ---------------------------------------------------------------------------

def _workout_to_entry(row: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    if not row.get("is_completed"):
        return None
    occurred_at = row.get("completed_at") or row.get("scheduled_date")
    if not occurred_at:
        return None
    name = row.get("name") or "Workout"
    duration = row.get("duration_minutes") or row.get("estimated_duration_minutes")
    calories = row.get("estimated_calories")
    type_ = (row.get("type") or "workout").lower()
    is_sleep = type_ == "sleep"
    icon = "bedtime" if is_sleep else "fitness_center"

    subtitle_bits = []
    if duration:
        if is_sleep:
            h, m = divmod(int(duration), 60)
            subtitle_bits.append(f"{h}h {m}m" if h else f"{m}m")
        else:
            subtitle_bits.append(f"{int(duration)} min")
    if calories and not is_sleep:
        subtitle_bits.append(f"{int(calories)} kcal")

    return {
        "id": f"{'sleep' if is_sleep else 'workout'}:{row['id']}",
        "type": "sleep" if is_sleep else "workout",
        "occurred_at": occurred_at,
        "title": name,
        "subtitle": " · ".join(subtitle_bits) or None,
        "icon": icon,
        "source": _label_source(row.get("generation_source")),
        "metadata": {
            "duration_minutes": duration,
            "calories": calories,
            "type": type_,
            "exercises_count": len(row.get("exercises_json") or []),
        },
        "actions": ["edit", "delete", "reLog", "share"],
    }


def _food_to_entry(row: Dict[str, Any]) -> Dict[str, Any]:
    occurred_at = row.get("logged_at") or row.get("created_at")
    title = row.get("food_name") or row.get("meal_type", "Food").title()
    cal = row.get("total_calories")
    p, c, f = row.get("protein_g"), row.get("carbs_g"), row.get("fat_g")
    subtitle_bits = []
    if cal:
        subtitle_bits.append(f"{int(cal)} kcal")
    if p:
        subtitle_bits.append(f"P {int(p)}g")
    return {
        "id": f"food:{row['id']}",
        "type": "food",
        "occurred_at": occurred_at,
        "title": title,
        "subtitle": " · ".join(subtitle_bits) or None,
        "icon": "restaurant",
        "source": _label_source(row.get("source_type") or row.get("input_type")),
        "metadata": {
            "calories": cal, "protein_g": p, "carbs_g": c, "fat_g": f,
            "meal_type": row.get("meal_type"),
        },
        "attachments": [{"kind": "photo", "url": row["image_url"]}] if row.get("image_url") else [],
        "actions": ["edit", "delete", "share"],
    }


def _water_to_entry(row: Dict[str, Any]) -> Dict[str, Any]:
    occurred_at = row.get("logged_at") or row.get("created_at")
    ml = row.get("amount_ml") or 0
    oz = round(ml / 29.5735, 1)
    return {
        "id": f"water:{row['id']}",
        "type": "water",
        "occurred_at": occurred_at,
        "title": f"{ml} ml water",
        "subtitle": f"{oz} oz" if ml else None,
        "icon": "water_drop",
        "source": _label_source(row.get("source")),
        "metadata": {"amount_ml": ml},
        "actions": ["edit", "delete"],
    }


def _weight_to_entry(row: Dict[str, Any]) -> Dict[str, Any]:
    occurred_at = row.get("measured_at") or row.get("created_at")
    kg = row.get("weight_kg")
    lbs = round(kg * 2.20462, 1) if kg else None
    return {
        "id": f"weight:{row['id']}",
        "type": "weight",
        "occurred_at": occurred_at,
        "title": "Weight logged",
        "subtitle": f"{kg:.1f} kg · {lbs} lbs" if kg else None,
        "icon": "monitor_weight",
        "source": _label_source(row.get("measurement_source")),
        "metadata": {"weight_kg": kg, "weight_lbs": lbs,
                     "body_fat_percent": row.get("body_fat_percent")},
        "actions": ["edit", "delete"],
    }


def _mood_to_entry(row: Dict[str, Any]) -> Dict[str, Any]:
    occurred_at = row.get("occurred_at") or row.get("logged_at") or row.get("created_at")
    return {
        "id": f"mood:{row['id']}",
        "type": "mood",
        "occurred_at": occurred_at,
        "title": f"Mood: {row.get('mood', '').title()}",
        "subtitle": (
            f"Energy {row['energy_level']}/5"
            if row.get("energy_level") else None
        ),
        "icon": "mood",
        "source": _label_source(row.get("source")),
        "metadata": {"mood": row.get("mood"), "energy_level": row.get("energy_level")},
        "actions": ["edit", "delete"],
    }


def _habit_to_entry(row: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    occurred_at = row.get("completed_at") or row.get("logged_at") or row.get("created_at")
    if not occurred_at:
        return None
    name = row.get("habit_name") or row.get("name") or "Habit"
    return {
        "id": f"habit:{row['id']}",
        "type": "habit",
        "occurred_at": occurred_at,
        "title": f"✓ {name}",
        "subtitle": None,
        "icon": "check_circle",
        "source": _label_source("manual"),
        "metadata": {},
        "actions": ["delete"],
    }


# ---------------------------------------------------------------------------
# Insights (rule-based — no LLM call)
# ---------------------------------------------------------------------------

def _build_insights(summary: Dict[str, Any], entries: List[Dict[str, Any]]) -> List[str]:
    out: List[str] = []
    streak = summary.get("streak_day") or 0
    if streak in (3, 7, 14, 30, 60, 90, 100, 365):
        out.append(f"🔥 Day {streak} of your streak — keep going")
    elif streak >= 3:
        out.append(f"🔥 {streak}-day streak alive")

    water_ml = summary.get("water_ml") or 0
    water_goal = summary.get("water_goal_ml") or 0
    if water_goal and water_ml < water_goal * 0.5:
        local_hour = datetime.now().hour
        if local_hour >= 17:
            out.append(f"💧 Behind on water — only {int(water_ml/water_goal*100)}% of goal")

    workouts_count = summary.get("workouts_count") or 0
    if workouts_count >= 2:
        out.append(f"💪 {workouts_count} sessions today — recovery matters tomorrow")

    sleep_min = summary.get("sleep_minutes") or 0
    if 0 < sleep_min < 360:
        out.append(f"🛌 Light night ({sleep_min // 60}h {sleep_min % 60}m) — prioritize sleep tonight")

    return out[:3]


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------

@router.get("/timeline")
async def get_timeline(
    request: Request,
    user_id: str = Query(..., max_length=64),
    date: Optional[str] = Query(None, description="YYYY-MM-DD, user-local. Defaults to today."),
    days: int = Query(1, ge=1, le=30, description="How many consecutive days to return (going back from `date`)."),
    limit: int = Query(200, ge=1, le=500, description="Max entries per day"),
    metrics_only: bool = Query(
        False,
        description="When true, omit each day's `entries` array and return only "
        "`date`/`day_label`/`summary`/`insights`. Used by the Home trend rail "
        "(a 14-day fetch) so the payload stays tiny.",
    ),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    target_date = date or get_user_today(user_tz)

    # Cache lookup (best-effort — a cache-layer hiccup must not fail the request)
    try:
        cached = await get_timeline_cache(user_id, target_date, days, metrics_only)
        if cached:
            return cached
    except Exception as e:
        logger.warning(f"[Timeline] cache read failed (continuing): {e}")

    # Resolve UTC range covering all `days` ending at target_date
    base_dt = datetime.strptime(target_date, "%Y-%m-%d").date()
    earliest = (base_dt - timedelta(days=days - 1)).isoformat()
    range_start, _ = local_date_to_utc_range(earliest, user_tz)
    _, range_end = local_date_to_utc_range(target_date, user_tz)

    # Run all domain queries in parallel
    loop = asyncio.get_event_loop()

    def _q_workouts():
        return db.client.table("workouts").select(
            "id, name, type, scheduled_date, completed_at, is_completed, status, "
            "duration_minutes, estimated_duration_minutes, estimated_calories, "
            "exercises_json, generation_source, generation_method"
        ).eq("user_id", user_id).eq("is_completed", True).gte(
            "completed_at", range_start
        ).lte("completed_at", range_end).execute()

    def _q_food():
        return db.client.table("food_logs").select(
            "id, food_name, meal_type, total_calories, protein_g, carbs_g, fat_g, "
            "logged_at, image_url, source_type, input_type, deleted_at"
        ).eq("user_id", user_id).gte("logged_at", range_start).lte(
            "logged_at", range_end
        ).is_("deleted_at", "null").execute()

    def _q_water():
        return db.client.table("hydration_logs").select(
            "id, amount_ml, drink_type, logged_at, source"
        ).eq("user_id", user_id).gte("logged_at", range_start).lte(
            "logged_at", range_end
        ).execute()

    def _q_weight():
        return db.client.table("body_measurements").select(
            "id, weight_kg, body_fat_percent, measured_at, measurement_source"
        ).eq("user_id", user_id).gte("measured_at", range_start).lte(
            "measured_at", range_end
        ).execute()

    def _q_mood():
        return db.client.table("mood_log").select(
            "id, mood, energy_level, source, occurred_at, deleted_at"
        ).eq("user_id", user_id).gte("occurred_at", range_start).lte(
            "occurred_at", range_end
        ).is_("deleted_at", "null").execute()

    def _q_habits():
        return db.client.table("habit_logs").select(
            "id, habit_id, completed_at, value"
        ).eq("user_id", user_id).gte("completed_at", range_start).lte(
            "completed_at", range_end
        ).execute()

    def _q_streak():
        return db.client.table("user_streaks").select(
            "current_streak, longest_streak, streak_type"
        ).eq("user_id", user_id).execute()

    def _q_xp():
        return db.client.table("user_xp").select(
            "total_xp, current_level"
        ).eq("user_id", user_id).limit(1).execute()

    def _q_personal_records():
        return db.client.table("personal_records").select(
            "id, exercise_name, record_type, record_value, record_unit, "
            "achieved_at, workout_id, improvement_percent, is_all_time_pr"
        ).eq("user_id", user_id).gte("achieved_at", range_start).lte(
            "achieved_at", range_end
        ).execute()

    # Resilient fan-out: one flaky domain query must NEVER 500 the whole
    # timeline. `return_exceptions=True` collects per-query results; a domain
    # that raised is logged and treated as empty so the feed degrades to
    # "whatever succeeded" instead of failing wholesale. The per-domain log
    # surfaces exactly which query is flaky for a permanent fix.
    _DOMAIN_NAMES = [
        "workouts", "food", "water", "weight", "mood",
        "habits", "streak", "xp", "personal_records",
    ]
    try:
        results = await asyncio.gather(
            loop.run_in_executor(None, _q_workouts),
            loop.run_in_executor(None, _q_food),
            loop.run_in_executor(None, _q_water),
            loop.run_in_executor(None, _q_weight),
            loop.run_in_executor(None, _q_mood),
            loop.run_in_executor(None, _q_habits),
            loop.run_in_executor(None, _q_streak),
            loop.run_in_executor(None, _q_xp),
            loop.run_in_executor(None, _q_personal_records),
            return_exceptions=True,
        )
    except Exception as e:
        # gather() with return_exceptions=True effectively never raises; this
        # only fires on a catastrophic scheduling failure.
        logger.error(f"[Timeline] aggregator scheduling failed: {e}", exc_info=True)
        results = [None] * len(_DOMAIN_NAMES)

    def _rows(idx: int) -> List[Dict[str, Any]]:
        r = results[idx]
        if isinstance(r, Exception):
            logger.warning(f"[Timeline] {_DOMAIN_NAMES[idx]} query failed: {r}")
            return []
        return (getattr(r, "data", None) or []) if r is not None else []

    workouts_rows = _rows(0)
    food_rows = _rows(1)
    water_rows = _rows(2)
    weight_rows = _rows(3)
    mood_rows = _rows(4)
    habits_rows = _rows(5)
    streak_rows = _rows(6)
    xp_rows = _rows(7)
    pr_rows = _rows(8)

    # Build entries — each row is converted defensively so one malformed row
    # (or a builder bug) can't blow up the whole feed.
    raw_entries: List[Dict[str, Any]] = []

    def _safe_build(rows, builder, *, domain: str):
        for r in rows:
            try:
                e = builder(r)
                if e:
                    raw_entries.append(e)
            except Exception as ex:
                logger.warning(f"[Timeline] {domain} row skipped: {ex}")

    _safe_build(workouts_rows, _workout_to_entry, domain="workout")
    _safe_build(food_rows, _food_to_entry, domain="food")
    _safe_build(water_rows, _water_to_entry, domain="water")
    _safe_build(weight_rows, _weight_to_entry, domain="weight")
    _safe_build(mood_rows, _mood_to_entry, domain="mood")
    _safe_build(habits_rows, _habit_to_entry, domain="habit")

    # Achievement chips: index PRs by workout_id for inline annotation
    pr_by_workout: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
    for pr in pr_rows:
        wid = pr.get("workout_id")
        if not wid:
            continue
        # Build a chip
        record_type = pr.get("record_type", "")
        if record_type.startswith("weight_"):
            pr_by_workout[wid].append({
                "kind": "strength_pr",
                "label": f"🏆 New PR · {pr['exercise_name']} {pr['record_value']:g} {pr['record_unit']}",
                "icon": "emoji_events",
            })
        elif record_type == "e1rm":
            pr_by_workout[wid].append({
                "kind": "e1rm_pr",
                "label": f"📈 e1RM · {pr['exercise_name']} {pr['record_value']:.1f} {pr['record_unit']}",
                "icon": "trending_up",
            })

    for entry in raw_entries:
        wid = entry["id"].split(":", 1)[1] if entry["id"].startswith("workout:") else None
        if wid and wid in pr_by_workout:
            entry["achievement_chips"] = pr_by_workout[wid][:3]

    # Group by user-local date.
    #
    # NB on overlapping/cross-day events:
    # - Sleep blocks store occurred_at = WAKE time (the moment the user
    #   "completed" the sleep), so a 11pm→7am block lands on the wake day,
    #   not the bedtime day. Matches Zepp/Fitbit Journal convention.
    #   Bedtime is preserved in metadata (`bedtime`/`wake_time`) for the
    #   detail sheet.
    # - Workouts use completed_at — a 90-min session ending today falls
    #   on today even if it started yesterday late.
    # - Two events at the same exact UTC second are sorted by domain
    #   priority (workout > sleep > food > water > weight > mood > habit)
    #   above so the order stays stable across refreshes.
    by_day: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
    for e in raw_entries:
        occ = e["occurred_at"]
        # Convert UTC ISO to user-local date
        try:
            dt = datetime.fromisoformat(occ.replace("Z", "+00:00"))
            import pytz
            local_dt = dt.astimezone(pytz.timezone(user_tz))
            local_date = local_dt.strftime("%Y-%m-%d")
        except Exception:
            local_date = occ[:10]
        by_day[local_date].append(e)

    # Sort entries within each day, occurred_at DESC, then by domain priority
    # so two events at the exact same timestamp render in a stable, sensible
    # order (workout > sleep > food > water > weight > mood > habit) instead
    # of whatever order Postgres returned them. Prevents flicker on refresh.
    _DOMAIN_PRIORITY = {
        "workout": 0, "sleep": 1, "food": 2, "water": 3,
        "weight": 4, "mood": 5, "habit": 6, "achievement": 7,
    }
    for d in by_day:
        by_day[d].sort(
            key=lambda e: (
                e["occurred_at"],
                -_DOMAIN_PRIORITY.get(e.get("type", ""), 99),
            ),
            reverse=True,
        )
        by_day[d] = by_day[d][:limit]

    # Overlap annotation pass: for each food/water entry, check whether it
    # falls inside any workout block (occurred_at + duration). If so, attach
    # a `during_workout` flag + the workout's title so the UI can render
    # "During Yoga session" beneath the entry. This converts visual
    # ambiguity ("why is water log nested under yoga?") into clear context.
    def _entry_window(e: Dict[str, Any]) -> Optional[tuple]:
        """Return (start_utc, end_utc) for a workout/sleep entry."""
        if e.get("type") not in ("workout", "sleep"):
            return None
        try:
            start = datetime.fromisoformat(e["occurred_at"].replace("Z", "+00:00"))
            dur = (e.get("metadata") or {}).get("duration_minutes") or 0
            end = start + timedelta(minutes=int(dur))
            return (start, end)
        except Exception:
            return None

    for d in by_day:
        windows = []
        for e in by_day[d]:
            w = _entry_window(e)
            if w:
                windows.append((w, e))
        if not windows:
            continue
        for e in by_day[d]:
            if e.get("type") in ("workout", "sleep"):
                continue
            try:
                ts = datetime.fromisoformat(e["occurred_at"].replace("Z", "+00:00"))
            except Exception:
                continue
            for (w_start, w_end), w_entry in windows:
                # NB: workout entries timestamp == completed_at, so the
                # window is (start - duration) → start. For sleep entries
                # the timestamp is wake_at, same logic.
                actual_start = w_start - timedelta(
                    minutes=(w_entry.get("metadata") or {}).get("duration_minutes") or 0
                )
                if actual_start <= ts <= w_start:
                    e.setdefault("metadata", {})["during"] = w_entry["title"]
                    break

    # Wearable + chat duplicate detection: if there's a chat-logged workout
    # AND a wearable-imported workout with the same activity_type and
    # overlapping time window (within ±20min), tag the older one with a
    # "duplicate of {newer.id}" warning so the UI can collapse them with
    # an "Apple Health also logged this" note rather than showing two rows.
    for d in by_day:
        workouts = [e for e in by_day[d] if e.get("type") == "workout"]
        for i, a in enumerate(workouts):
            for b in workouts[i + 1:]:
                a_src = (a.get("source") or {}).get("kind", "")
                b_src = (b.get("source") or {}).get("kind", "")
                # Different sources, similar timing, same activity?
                if a_src == b_src:
                    continue
                if not ({a_src, b_src} & {"chat", "wearable_sync_apple_health",
                                           "wearable_sync_fitbit", "wearable_sync_garmin",
                                           "wearable_sync_health_connect", "health_connect"}):
                    continue
                try:
                    ta = datetime.fromisoformat(a["occurred_at"].replace("Z", "+00:00"))
                    tb = datetime.fromisoformat(b["occurred_at"].replace("Z", "+00:00"))
                except Exception:
                    continue
                if abs((ta - tb).total_seconds()) > 20 * 60:
                    continue
                a_title = (a.get("title") or "").lower().split()[0]
                b_title = (b.get("title") or "").lower().split()[0]
                if a_title and a_title == b_title:
                    older = a if ta < tb else b
                    newer = b if older is a else a
                    older.setdefault("metadata", {})["likely_duplicate_of"] = newer["id"]
                    older["coach_note"] = (
                        f"Possibly the same as {newer['source']['label']}'s "
                        f"{newer.get('subtitle') or newer['title']}"
                    )

    # Build day summaries
    streak_day = 0
    if streak_rows:
        # Pick the workout streak if present, else max
        for s in streak_rows:
            if s.get("streak_type") == "workout":
                streak_day = s.get("current_streak") or 0
                break
        if not streak_day:
            streak_day = max((s.get("current_streak") or 0) for s in streak_rows)

    xp = (xp_rows[0].get("total_xp", 0) if xp_rows else 0)

    days_payload: List[Dict[str, Any]] = []
    today_str = get_user_today(user_tz)
    for offset in range(days):
        d = (base_dt - timedelta(days=offset)).isoformat()
        entries = by_day.get(d, [])

        # Per-day summary
        workouts_today = [e for e in entries if e["type"] == "workout"]
        sleep_today = [e for e in entries if e["type"] == "sleep"]
        food_today = [e for e in entries if e["type"] == "food"]
        water_today = [e for e in entries if e["type"] == "water"]
        habits_today = [e for e in entries if e["type"] == "habit"]
        mood_today = [e for e in entries if e["type"] == "mood"]

        summary = {
            "workouts_count": len(workouts_today),
            "workouts_total_minutes": sum(
                e["metadata"].get("duration_minutes") or 0 for e in workouts_today
            ),
            "calories_burned": sum(
                e["metadata"].get("calories") or 0 for e in workouts_today
            ),
            "calories_eaten": sum(
                e["metadata"].get("calories") or 0 for e in food_today
            ),
            "protein_g": sum(e["metadata"].get("protein_g") or 0 for e in food_today),
            "water_ml": sum(e["metadata"].get("amount_ml") or 0 for e in water_today),
            "water_goal_ml": 2400,  # default until per-user goal wiring lands
            "sleep_minutes": sum(
                e["metadata"].get("duration_minutes") or 0 for e in sleep_today
            ),
            "habits_completed": len(habits_today),
            "mood": mood_today[0]["metadata"]["mood"] if mood_today else None,
            "streak_day": streak_day if d == today_str else None,
            "xp_earned": xp if d == today_str else None,
        }
        # net calories (positive = surplus, negative = deficit)
        summary["calories_net"] = (summary["calories_eaten"]
                                   - summary["calories_burned"])

        day_label = "Today" if d == today_str else (
            "Yesterday" if d == (base_dt - timedelta(days=1)).isoformat() else
            datetime.strptime(d, "%Y-%m-%d").strftime("%a, %b %-d")
        )
        insights = _build_insights(summary, entries)

        days_payload.append({
            "date": d,
            "day_label": day_label,
            "summary": summary,
            "insights": insights,
            # summaries-only mode drops the (potentially large) entries array;
            # the summary above is still computed from the full entry set.
            "entries": [] if metrics_only else entries,
        })

    payload = {
        "user_id": user_id,
        "user_tz": user_tz,
        "days": days_payload,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }

    try:
        await set_timeline_cache(user_id, target_date, payload, days, metrics_only)
    except Exception as e:
        logger.warning(f"[Timeline] cache write failed (continuing): {e}")
    return payload
