"""
Share artifact generation tool for the coach agent.

Lets the AI coach mint a public share link in-conversation when the user
asks "share my week", "share today's workout", "share my PRs this month",
"give me a YTD summary I can post", etc.

Returns a `share_artifact_generated` action_data payload that the Flutter
chat screen renders as a card with two CTAs (copy/share + open-in-app).
"""
from datetime import date, datetime, timedelta
from typing import Any, Dict, Optional

from core.db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

VALID_SCOPES = {"workout", "plan", "prs", "one_rm", "summary"}
VALID_PERIODS = {"today", "week", "month", "ytd", "custom"}


def _resolve_dates(period: str, anchor: Optional[date] = None) -> tuple[date, date]:
    """Translate friendly period names into concrete date ranges."""
    today = anchor or date.today()
    if period == "today":
        return today, today
    if period == "week":
        monday = today - timedelta(days=today.weekday())
        return monday, monday + timedelta(days=6)
    if period == "month":
        first = today.replace(day=1)
        if first.month == 12:
            next_first = first.replace(year=first.year + 1, month=1)
        else:
            next_first = first.replace(month=first.month + 1)
        return first, next_first - timedelta(days=1)
    if period == "ytd":
        return date(today.year, 1, 1), today
    return today, today


async def generate_share_artifact(
    user_id: str,
    scope: str,
    period: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> Dict[str, Any]:
    """Mint a public share link for the user.

    `scope=workout` looks up today's workout for the user, calls the
    existing single-workout share endpoint pattern (insert/return token).
    All other scopes go through the new `shared_plans` table.

    Returns the action_data payload (no Flutter dispatch — the caller
    embeds this in the chat response).
    """
    if scope not in VALID_SCOPES:
        return {"success": False, "error": f"Unknown scope: {scope}"}
    if period not in VALID_PERIODS:
        return {"success": False, "error": f"Unknown period: {period}"}

    db = get_supabase_db()

    # ── workout scope: try today's workout ──────────────────────────────
    if scope == "workout":
        try:
            today = date.today().isoformat()
            row = (
                db.client.table("workouts")
                .select("id,share_token,is_completed")
                .eq("user_id", user_id)
                .gte("scheduled_date", today)
                .lte("scheduled_date", today)
                .order("scheduled_date", desc=False)
                .limit(1)
                .execute()
            )
            workouts = row.data or []
            if not workouts:
                return {
                    "success": False,
                    "error": "No workout scheduled today to share.",
                }
            wkt = workouts[0]
            token = wkt.get("share_token")
            if not token:
                # Generate one inline. Reuse the same alphabet as share_link.py.
                import secrets
                alphabet = "abcdefghijkmnpqrstuvwxyz23456789"
                token = "".join(secrets.choice(alphabet) for _ in range(8))
                db.client.table("workouts").update({"share_token": token}).eq(
                    "id", wkt["id"]
                ).execute()
            return {
                "success": True,
                "type": "share_artifact_generated",
                "url": f"https://zealova.com/w/{token}",
                "scope": "workout",
                "period": "today",
                "deep_link": f"fitwiz://share?scope=workout&token={token}",
            }
        except Exception as exc:  # noqa: BLE001
            logger.warning("share_artifact workout failed: %s", exc)
            return {"success": False, "error": "Could not share today's workout."}

    # ── plan / prs / one_rm / summary scopes: new shared_plans table ─────
    try:
        if start_date:
            anchor = date.fromisoformat(start_date[:10])
        else:
            anchor = None
        start, end = _resolve_dates(period, anchor)
        if end_date:
            try:
                end = date.fromisoformat(end_date[:10])
            except ValueError:
                pass
        # Build snapshot for plan scope; stub for others (server can hydrate later).
        if scope == "plan":
            rows = db.list_workouts(
                user_id=user_id,
                from_date=start.isoformat(),
                to_date=end.isoformat(),
                limit=200,
                order_asc=True,
            )
            workouts = [dict(r) for r in rows]
            snapshot: Dict[str, Any] = {
                "workouts": [
                    {
                        "id": w.get("id"),
                        "name": w.get("name"),
                        "type": w.get("type"),
                        "scheduled_date": str(w.get("scheduled_date", ""))[:10],
                        "is_completed": bool(w.get("is_completed")),
                        "completed_at": w.get("completed_at"),
                        "duration_minutes": w.get("duration_minutes") or 0,
                        "estimated_calories": w.get("estimated_calories"),
                        "exercises": w.get("exercises_json") or w.get("exercises") or [],
                    }
                    for w in workouts
                ],
                "summary": {
                    "total_workouts": len(workouts),
                    "completed_workouts": sum(
                        1 for w in workouts if w.get("is_completed")
                    ),
                    "total_duration_minutes": sum(
                        int(w.get("duration_minutes") or 0) for w in workouts
                    ),
                    "date_range": {
                        "start": start.isoformat(),
                        "end": end.isoformat(),
                    },
                },
            }
        else:
            snapshot = {"placeholder": True, "scope": scope}

        import secrets
        alphabet = "abcdefghijkmnpqrstuvwxyz23456789"
        token: Optional[str] = None
        last_err: Optional[Exception] = None
        for _ in range(3):
            candidate = "".join(secrets.choice(alphabet) for _ in range(8))
            try:
                ins = (
                    db.client.table("shared_plans")
                    .insert(
                        {
                            "user_id": user_id,
                            "share_token": candidate,
                            "scope": scope,
                            # Map "today" → "day" to match shared_plans CHECK constraint
                            "period": "day" if period == "today" else period,
                            "start_date": start.isoformat(),
                            "end_date": end.isoformat(),
                            "snapshot": snapshot,
                        }
                    )
                    .execute()
                )
                if ins.data:
                    token = candidate
                    break
            except Exception as exc:  # noqa: BLE001
                last_err = exc
                logger.warning("share_artifact insert retry: %s", exc)
        if not token:
            logger.error("share_artifact final failure: %s", last_err)
            return {"success": False, "error": "Could not create share link."}

        return {
            "success": True,
            "type": "share_artifact_generated",
            "url": f"https://zealova.com/p/{token}",
            "scope": scope,
            "period": period,
            "deep_link": (
                f"fitwiz://share?scope={scope}&period={period}"
                f"&start={start.isoformat()}&end={end.isoformat()}"
            ),
        }
    except Exception as exc:  # noqa: BLE001
        logger.error("share_artifact unexpected: %s", exc)
        return {"success": False, "error": "Something went wrong."}
