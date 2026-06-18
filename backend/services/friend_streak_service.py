"""
Friend Streak service — Workstream F14.

1:1 shared streak (workout | food). No public feed (project_gamification_role).
A streak increments by 1 once per shared LOCAL day when BOTH members logged the
streak's kind that day. Deterministic; no LLM.

  - create_invite(user_a, kind)       -> {invite_code, deep link via referral_service}
  - accept_invite(invite_code, user_b)
  - list_streaks(user_id)
  - mark_logged(user_id, kind, day)   -> idempotent per-day signal; called by the
                                          completion/food-log hooks (or the daily
                                          evaluator). Increments when both sides
                                          have logged on the same day.

"Logged today" is derived deterministically:
  workout -> a completed workout with completed_at in [day, day+1)
  food    -> a non-deleted food_log with logged_at in [day, day+1)
"""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.db.facade import get_supabase_db
from core.logger import get_logger
from services import referral_service

logger = get_logger(__name__)

VALID_KINDS = ("workout", "food")


def _day_bounds(d: date) -> tuple[str, str]:
    start = datetime(d.year, d.month, d.day, tzinfo=timezone.utc)
    return start.isoformat(), (start + timedelta(days=1)).isoformat()


def _logged_on(user_id: str, kind: str, d: date) -> bool:
    """Did the user log the kind on local day d (UTC bounds)?"""
    db = get_supabase_db()
    start, end = _day_bounds(d)
    try:
        if kind == "workout":
            r = (
                db.client.table("workouts").select("id")
                .eq("user_id", user_id).eq("is_completed", True)
                .gte("completed_at", start).lt("completed_at", end).limit(1).execute()
            )
        else:
            r = (
                db.client.table("food_logs").select("id")
                .eq("user_id", user_id)
                .gte("logged_at", start).lt("logged_at", end)
                .is_("deleted_at", "null").limit(1).execute()
            )
        return bool(r.data)
    except Exception as e:
        logger.warning(f"[FriendStreak] _logged_on failed: {e}")
        return False


def create_invite(user_a: str, kind: str = "workout") -> Dict[str, Any]:
    """Create a pending friend-streak invite + a shareable deep link."""
    if kind not in VALID_KINDS:
        raise ValueError(f"kind must be one of {VALID_KINDS}")
    db = get_supabase_db()
    import random
    import string

    code = "".join(random.choices("abcdefghijkmnpqrstuvwxyz23456789", k=8))
    db.client.table("friend_streaks").insert(
        {"user_a": user_a, "kind": kind, "invite_code": code, "status": "pending"}
    ).execute()

    link = referral_service._mint_link(
        kind="friend_streak", user_id=user_a, payload={"invite_code": code, "streak_kind": kind},
    )
    return {"invite_code": code, "kind": kind, "status": "pending", **link}


def accept_invite(invite_code: str, user_b: str) -> Dict[str, Any]:
    db = get_supabase_db()
    row = (
        db.client.table("friend_streaks").select("*")
        .eq("invite_code", invite_code).limit(1).execute()
    )
    if not row.data:
        raise KeyError("Unknown invite code")
    s = row.data[0]
    if s["status"] != "pending":
        raise ValueError("Invite already accepted or ended")
    if s["user_a"] == user_b:
        raise ValueError("You cannot accept your own invite")

    db.client.table("friend_streaks").update(
        {"user_b": user_b, "status": "active", "updated_at": datetime.now(timezone.utc).isoformat()}
    ).eq("id", s["id"]).execute()
    return {"id": s["id"], "kind": s["kind"], "status": "active"}


def list_streaks(user_id: str) -> List[Dict[str, Any]]:
    db = get_supabase_db()
    res = (
        db.client.table("friend_streaks").select("*")
        .or_(f"user_a.eq.{user_id},user_b.eq.{user_id}")
        .neq("status", "ended")
        .order("current_streak", desc=True).execute()
    )
    return res.data or []


def evaluate_streak(streak_row: Dict[str, Any], day: Optional[date] = None) -> Dict[str, Any]:
    """Core deterministic evaluator for one active streak on a given local day.

    Increments current_streak by 1 (once per day, guarded by last_incremented_on)
    when BOTH members logged the kind on `day`. If a full day passed with the
    shared streak unmet, it resets to 0. Returns the updated row delta.
    """
    if streak_row["status"] != "active" or not streak_row.get("user_b"):
        return {"changed": False, "reason": "not_active"}
    day = day or datetime.now(timezone.utc).date()
    db = get_supabase_db()

    a_logged = _logged_on(streak_row["user_a"], streak_row["kind"], day)
    b_logged = _logged_on(streak_row["user_b"], streak_row["kind"], day)

    updates: Dict[str, Any] = {"updated_at": datetime.now(timezone.utc).isoformat()}
    if a_logged:
        updates["last_a_at"] = day.isoformat()
    if b_logged:
        updates["last_b_at"] = day.isoformat()

    last_inc = streak_row.get("last_incremented_on")
    changed = False
    if a_logged and b_logged and last_inc != day.isoformat():
        new_streak = int(streak_row.get("current_streak") or 0) + 1
        updates["current_streak"] = new_streak
        updates["longest_streak"] = max(int(streak_row.get("longest_streak") or 0), new_streak)
        updates["last_incremented_on"] = day.isoformat()
        changed = True
    else:
        # Reset if the PREVIOUS day was missed by either side and we never
        # incremented for it (a gap day). Only reset when last increment is
        # older than yesterday.
        if last_inc:
            try:
                last_d = date.fromisoformat(last_inc)
                if (day - last_d).days >= 2 and int(streak_row.get("current_streak") or 0) > 0:
                    updates["current_streak"] = 0
                    changed = True
            except ValueError:
                pass

    if updates.keys() - {"updated_at"}:
        db.client.table("friend_streaks").update(updates).eq("id", streak_row["id"]).execute()

    return {
        "changed": changed,
        "a_logged": a_logged,
        "b_logged": b_logged,
        "current_streak": updates.get("current_streak", streak_row.get("current_streak", 0)),
    }


def mark_logged(user_id: str, kind: str, day: Optional[date] = None) -> List[Dict[str, Any]]:
    """Hook for completion / food-log paths: re-evaluate every active streak of
    `kind` this user belongs to. Returns per-streak deltas."""
    if kind not in VALID_KINDS:
        return []
    day = day or datetime.now(timezone.utc).date()
    db = get_supabase_db()
    res = (
        db.client.table("friend_streaks").select("*")
        .or_(f"user_a.eq.{user_id},user_b.eq.{user_id}")
        .eq("kind", kind).eq("status", "active").execute()
    )
    out = []
    for row in (res.data or []):
        out.append({"id": row["id"], **evaluate_streak(row, day)})
    return out


def run_daily_evaluator(day: Optional[date] = None) -> Dict[str, Any]:
    """Daily cron: evaluate every active streak for `day` (defaults to today).
    Also resets streaks where yesterday was a gap. Returns a summary."""
    day = day or datetime.now(timezone.utc).date()
    db = get_supabase_db()
    res = db.client.table("friend_streaks").select("*").eq("status", "active").execute()
    evaluated = incremented = 0
    for row in (res.data or []):
        delta = evaluate_streak(row, day)
        evaluated += 1
        if delta.get("changed") and delta.get("a_logged") and delta.get("b_logged"):
            incremented += 1
    return {"day": day.isoformat(), "evaluated": evaluated, "incremented": incremented}
