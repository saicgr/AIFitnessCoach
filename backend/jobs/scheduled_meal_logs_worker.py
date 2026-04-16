"""
Scheduled Meal Logs Worker
==========================
Hourly job that fires due reminders for scheduled_recipe_logs.

For each due schedule:
  1. Skip if the user already logged the same recipe + meal_type within the last 2 hours
     (manual-log-before-reminder edge case)
  2. Skip if storage is past expires_at on the linked cook_event (food-safety)
  3. Send a meal_reminder push with action_data:
       {action: "log_recipe", recipe_id, meal_type, servings,
        scheduled_log_id, cook_event_id?}
     — confirm-and-log bottom sheet on the device (NOT silent log) per user pref.
     If silent_log=true on the schedule, log directly via the API helper instead.
  4. Advance next_fire_at:
       - recurring → next matching weekday at local_time
       - batch     → bump next_slot_index; if past the last slot, disable schedule

Run via: `python -m jobs.scheduled_meal_logs_worker`
or scheduled hourly by Render cron.
"""
from __future__ import annotations

import asyncio
import logging
import os
import sys
from datetime import datetime, timedelta, timezone
from typing import Optional

# Make the backend package importable when run as a script
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.db import get_supabase_db  # noqa: E402

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")


_RECENT_LOG_WINDOW_HOURS = 2


def _safe_dt(s):
    if not s:
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return None


def _expand_days(kind, custom):
    if kind == "daily":
        return {0, 1, 2, 3, 4, 5, 6}
    if kind == "weekdays":
        return {1, 2, 3, 4, 5}
    if kind == "weekends":
        return {0, 6}
    return set(custom or [])


def _next_recurring_fire(schedule: dict) -> Optional[datetime]:
    try:
        from zoneinfo import ZoneInfo
        tz = ZoneInfo(schedule["timezone"])
    except Exception:
        tz = timezone.utc
    now_local = datetime.now(tz)
    days = _expand_days(schedule.get("schedule_kind"), schedule.get("days_of_week"))
    if not days:
        return None
    local_time = schedule.get("local_time")
    if not local_time:
        return None
    # local_time arrives as "HH:MM:SS" string
    try:
        h, m, *_ = local_time.split(":")
        from datetime import time as _time
        target = _time(int(h), int(m))
    except Exception:
        return None
    for offset in range(1, 8):  # tomorrow onwards (next fire is FUTURE)
        d = (now_local + timedelta(days=offset)).date()
        sun_idx = (d.weekday() + 1) % 7  # Sun=0..Sat=6
        if sun_idx in days:
            from datetime import datetime as _dt
            return _dt.combine(d, target, tzinfo=tz).astimezone(timezone.utc)
    return None


def _next_batch_fire(schedule: dict) -> Optional[datetime]:
    slots = schedule.get("batch_slots") or []
    next_idx = (schedule.get("next_slot_index") or 0) + 1
    if next_idx >= len(slots):
        return None
    try:
        from zoneinfo import ZoneInfo
        tz = ZoneInfo(schedule["timezone"])
    except Exception:
        tz = timezone.utc
    slot = slots[next_idx]
    from datetime import datetime as _dt, time as _time, date as _date
    d = _date.fromisoformat(slot["local_date"]) if isinstance(slot["local_date"], str) else slot["local_date"]
    h, m, *_ = (slot["local_time"] if isinstance(slot["local_time"], str) else "12:00").split(":")
    return _dt.combine(d, _time(int(h), int(m)), tzinfo=tz).astimezone(timezone.utc)


def _user_recently_logged(db, user_id: str, recipe_id: Optional[str], meal_type: str) -> bool:
    """Skip the reminder if the user already manually logged this recipe + meal slot recently."""
    if not recipe_id:
        return False
    cutoff = (datetime.now(timezone.utc) - timedelta(hours=_RECENT_LOG_WINDOW_HOURS)).isoformat()
    try:
        res = (
            db.client.table("food_logs")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .eq("recipe_id", recipe_id)
            .eq("meal_type", meal_type)
            .gte("logged_at", cutoff)
            .limit(1).execute()
        )
        return (res.count or 0) > 0
    except Exception:
        return False


def _cook_event_is_expired(db, cook_event_id: Optional[str]) -> bool:
    if not cook_event_id:
        return False
    try:
        res = (
            db.client.table("recipe_cook_events")
            .select("expires_at,portions_remaining")
            .eq("id", cook_event_id).limit(1).execute()
        )
        if not res.data:
            return True  # event deleted → treat as expired (skip)
        row = res.data[0]
        if (row.get("portions_remaining") or 0) <= 0:
            return True
        expires = _safe_dt(row.get("expires_at"))
        return expires is not None and expires < datetime.now(timezone.utc)
    except Exception:
        return False


def _user_first_name(db, user_id: str) -> str:
    try:
        res = (
            db.client.table("users")
            .select("first_name,display_name,email")
            .eq("id", user_id).limit(1).execute()
        )
        if res.data:
            row = res.data[0]
            name = row.get("first_name") or row.get("display_name")
            if name:
                return name
            email = row.get("email") or ""
            if email and "@" in email:
                return email.split("@")[0].title()
    except Exception:
        pass
    return "there"


def _user_is_in_quiet_or_vacation(db, user_id: str) -> bool:
    """Best-effort: check ai_settings or notification preferences for quiet hours / vacation mode.

    If the table/columns don't exist, returns False (don't skip). The settings UI
    in Phase 9 introduces these flags; the worker remains forward-compatible.
    """
    try:
        res = (
            db.client.table("ai_settings")
            .select("vacation_mode,quiet_hours_start,quiet_hours_end,timezone")
            .eq("user_id", user_id).limit(1).execute()
        )
        if not res.data:
            return False
        row = res.data[0]
        if row.get("vacation_mode"):
            return True
        # Quiet hours check
        qs = row.get("quiet_hours_start")
        qe = row.get("quiet_hours_end")
        if qs and qe:
            try:
                from zoneinfo import ZoneInfo
                tz = ZoneInfo(row.get("timezone") or "UTC")
            except Exception:
                tz = timezone.utc
            now_local = datetime.now(tz).time()
            from datetime import time as _time
            sh, sm = (qs.split(":") + ["0"])[:2]
            eh, em = (qe.split(":") + ["0"])[:2]
            start = _time(int(sh), int(sm))
            end = _time(int(eh), int(em))
            in_quiet = (
                (start <= now_local <= end)
                if start <= end
                else (now_local >= start or now_local <= end)
            )
            if in_quiet:
                return True
    except Exception:
        return False
    return False


async def _send_meal_reminder(user_id: str, schedule: dict, db) -> bool:
    """Send the actual push (or log silently if silent_log=true)."""
    recipe_name = "your meal"
    recipe_image = None
    recipe_id = schedule.get("recipe_id")
    if recipe_id:
        rec_res = (
            db.client.table("user_recipes")
            .select("name,image_url").eq("id", recipe_id).limit(1).execute()
        )
        if rec_res.data:
            recipe_name = rec_res.data[0].get("name") or recipe_name
            recipe_image = rec_res.data[0].get("image_url")

    # Silent log branch (advanced opt-in)
    if schedule.get("silent_log"):
        return await _silent_log(user_id, schedule, db, recipe_id, recipe_name)

    # Build push message
    first_name = _user_first_name(db, user_id)
    meal = (schedule.get("meal_type") or "meal").capitalize()
    title = f"{first_name}, time for {meal.lower()}?"
    body = f"Tap to log {recipe_name} ({float(schedule.get('servings') or 1):g} serving(s))."

    # Look up FCM token
    fcm_token = _fetch_fcm_token(db, user_id)
    if not fcm_token:
        logger.info("no fcm token for user %s — skipping push, advancing schedule", user_id)
        return True  # treat as fired so we don't retry every minute

    try:
        from services.notification_service_helpers import NotificationService

        ns = NotificationService()
        await ns.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type="meal_reminder",
            data={
                "action": "log_recipe",
                "recipe_id": str(recipe_id or ""),
                "meal_type": schedule.get("meal_type") or "",
                "servings": str(schedule.get("servings") or 1),
                "scheduled_log_id": str(schedule.get("id") or ""),
                "cook_event_id": str(schedule.get("cook_event_id") or ""),
            },
            image_url=recipe_image,
        )
        return True
    except Exception:
        logger.exception("[ScheduledMealLogs] push send failed for user %s", user_id)
        return False


async def _silent_log(user_id: str, schedule: dict, db, recipe_id, recipe_name) -> bool:
    """Silent-mode: directly create a food_log via the existing recipe-log endpoint logic."""
    if not recipe_id:
        return False
    try:
        # Use the recipe service's nutrition fields to compute totals
        rec_res = (
            db.client.table("user_recipes")
            .select(
                "calories_per_serving,protein_per_serving_g,carbs_per_serving_g,"
                "fat_per_serving_g,fiber_per_serving_g,sugar_per_serving_g,sodium_per_serving_mg"
            )
            .eq("id", recipe_id).limit(1).execute()
        )
        r = (rec_res.data or [{}])[0]
        mult = float(schedule.get("servings") or 1)
        import uuid as _uuid
        log_row = {
            "id": str(_uuid.uuid4()),
            "user_id": user_id,
            "meal_type": schedule.get("meal_type"),
            "logged_at": datetime.now(timezone.utc).isoformat(),
            "food_items": [{"name": recipe_name, "from_schedule": True}],
            "total_calories": int(round((r.get("calories_per_serving") or 0) * mult)),
            "protein_g": float(r.get("protein_per_serving_g") or 0) * mult,
            "carbs_g": float(r.get("carbs_per_serving_g") or 0) * mult,
            "fat_g": float(r.get("fat_per_serving_g") or 0) * mult,
            "fiber_g": float(r.get("fiber_per_serving_g") or 0) * mult,
            "sugar_g": float(r.get("sugar_per_serving_g") or 0) * mult,
            "sodium_mg": float(r.get("sodium_per_serving_mg") or 0) * mult,
            "recipe_id": recipe_id,
            "servings_consumed": mult,
            "cook_event_id": schedule.get("cook_event_id"),
            "source_type": "scheduled_log",
        }
        db.client.table("food_logs").insert(log_row).execute()
        return True
    except Exception:
        logger.exception("[ScheduledMealLogs] silent log failed for user %s", user_id)
        return False


def _fetch_fcm_token(db, user_id: str) -> Optional[str]:
    try:
        # Common location: user_devices table; falls back to users.fcm_token if present
        res = (
            db.client.table("user_devices")
            .select("fcm_token").eq("user_id", user_id).order("updated_at", desc=True)
            .limit(1).execute()
        )
        if res.data and res.data[0].get("fcm_token"):
            return res.data[0]["fcm_token"]
    except Exception:
        pass
    try:
        res = db.client.table("users").select("fcm_token").eq("id", user_id).limit(1).execute()
        if res.data and res.data[0].get("fcm_token"):
            return res.data[0]["fcm_token"]
    except Exception:
        pass
    return None


async def fire_due_schedules(db=None, dry_run: bool = False) -> dict:
    """Process all schedules where next_fire_at <= now and enabled.

    Returns: {processed, fired, skipped, errors}
    """
    db = db or get_supabase_db()
    now_iso = datetime.now(timezone.utc).isoformat()

    res = (
        db.client.table("scheduled_recipe_logs")
        .select("*")
        .eq("enabled", True)
        .is_("paused_until", "null")
        .lte("next_fire_at", now_iso)
        .order("next_fire_at")
        .limit(500)
        .execute()
    )
    schedules = res.data or []

    processed = fired = skipped = errors = 0

    for sched in schedules:
        processed += 1
        try:
            # Skip checks (manual log, expired cook event, quiet/vacation)
            if _user_recently_logged(
                db, sched["user_id"], sched.get("recipe_id"), sched.get("meal_type") or ""
            ):
                skipped += 1
                _advance_schedule(db, sched, dry_run=dry_run, fired=False)
                continue
            if _cook_event_is_expired(db, sched.get("cook_event_id")):
                skipped += 1
                _disable_schedule(db, sched["id"], reason="cook_event_expired", dry_run=dry_run)
                continue
            if _user_is_in_quiet_or_vacation(db, sched["user_id"]):
                skipped += 1
                _advance_schedule(db, sched, dry_run=dry_run, fired=False)
                continue

            # Fire the reminder
            if dry_run:
                logger.info("[dry-run] would fire schedule %s", sched["id"])
                ok = True
            else:
                ok = await _send_meal_reminder(sched["user_id"], sched, db)

            if ok:
                fired += 1
            else:
                errors += 1

            _advance_schedule(db, sched, dry_run=dry_run, fired=ok)
        except Exception:
            errors += 1
            logger.exception("[ScheduledMealLogs] error processing schedule %s", sched.get("id"))

    return {
        "processed": processed,
        "fired": fired,
        "skipped": skipped,
        "errors": errors,
    }


def _advance_schedule(db, sched: dict, dry_run: bool, fired: bool) -> None:
    """Move next_fire_at forward; for batch, advance slot index and disable when exhausted."""
    update = {
        "last_fired_at": datetime.now(timezone.utc).isoformat() if fired else sched.get("last_fired_at"),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    if sched.get("schedule_mode") == "batch":
        slots = sched.get("batch_slots") or []
        next_idx = (sched.get("next_slot_index") or 0) + 1
        if next_idx >= len(slots):
            update["enabled"] = False
            update["next_slot_index"] = next_idx
        else:
            nxt = _next_batch_fire({**sched, "next_slot_index": next_idx - 1})
            if nxt:
                update["next_fire_at"] = nxt.isoformat()
                update["next_slot_index"] = next_idx
            else:
                update["enabled"] = False
    else:
        nxt = _next_recurring_fire(sched)
        if nxt:
            update["next_fire_at"] = nxt.isoformat()
        else:
            update["enabled"] = False

    if dry_run:
        logger.info("[dry-run] would update schedule %s -> %s", sched["id"], update)
        return
    try:
        db.client.table("scheduled_recipe_logs").update(update).eq("id", sched["id"]).execute()
    except Exception:
        logger.exception("[ScheduledMealLogs] advance failed for %s", sched["id"])


def _disable_schedule(db, schedule_id: str, reason: str, dry_run: bool) -> None:
    if dry_run:
        logger.info("[dry-run] would disable %s (%s)", schedule_id, reason)
        return
    try:
        db.client.table("scheduled_recipe_logs").update(
            {"enabled": False, "updated_at": datetime.now(timezone.utc).isoformat()}
        ).eq("id", schedule_id).execute()
    except Exception:
        logger.exception("[ScheduledMealLogs] disable failed for %s", schedule_id)


def main():
    summary = asyncio.run(fire_due_schedules())
    logger.info("done: %s", summary)


if __name__ == "__main__":
    main()
