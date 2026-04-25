"""
Public shareable plan / period links.

POST   /api/v1/plans/share-link
    Owner-only. Snapshots the user's plan for a period and returns a public
    share token + URL (https://fitwiz.us/p/{token}).

GET    /api/v1/plans/public/{token}
    Anonymous. Reads the security-definer view `public_plans_v` and returns
    the snapshot, displayName, and username — safe to render on
    fitwiz.us/p/[token].

DELETE /api/v1/plans/share-link/{token}
    Owner-only. Sets `revoked_at`, hiding the row from the public view.

Mirrors the per-workout pattern in api/v1/workouts/share_link.py and uses the
`shared_plans` table + views created in migration `shared_plans_and_public_views`.
"""
import os
import secrets
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Path
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from api.v1.workouts.utils import parse_json_field

router = APIRouter()
logger = get_logger(__name__)

PUBLIC_BASE_URL = os.environ.get(
    "PUBLIC_PLAN_SHARE_BASE_URL", "https://fitwiz.us/p"
)
TOKEN_LEN = 8
TOKEN_ALPHABET = "abcdefghijkmnpqrstuvwxyz23456789"

VALID_PERIODS = {"day", "week", "month", "ytd", "custom"}
VALID_SCOPES = {"plan", "prs", "one_rm", "summary"}


def _make_token() -> str:
    return "".join(secrets.choice(TOKEN_ALPHABET) for _ in range(TOKEN_LEN))


def _resolve_date_range(
    period: str,
    start_date: Optional[str],
    end_date: Optional[str],
) -> tuple[date, date]:
    """Compute (start, end) inclusive given period + optional anchors.

    Defaults: period=day → today, period=week → most-recent Monday,
    period=month → first of current month, period=ytd → Jan 1, period=custom
    requires both start_date and end_date.
    """
    today = date.today()

    if start_date:
        try:
            anchor = date.fromisoformat(start_date[:10])
        except ValueError:
            raise HTTPException(status_code=400, detail="start_date must be YYYY-MM-DD")
    else:
        anchor = today

    if period == "day":
        return anchor, anchor
    if period == "week":
        # Snap anchor back to the Monday of its ISO week
        monday = anchor - timedelta(days=anchor.weekday())
        return monday, monday + timedelta(days=6)
    if period == "month":
        first = anchor.replace(day=1)
        # Last day of month: jump to first of next month, subtract 1 day
        if first.month == 12:
            next_first = first.replace(year=first.year + 1, month=1)
        else:
            next_first = first.replace(month=first.month + 1)
        return first, next_first - timedelta(days=1)
    if period == "ytd":
        jan1 = date(today.year, 1, 1)
        return jan1, today
    if period == "custom":
        if not end_date:
            raise HTTPException(
                status_code=400, detail="custom period requires end_date"
            )
        try:
            end = date.fromisoformat(end_date[:10])
        except ValueError:
            raise HTTPException(status_code=400, detail="end_date must be YYYY-MM-DD")
        if end < anchor:
            raise HTTPException(status_code=400, detail="end_date must be >= start_date")
        return anchor, end
    raise HTTPException(status_code=400, detail=f"Invalid period: {period}")


def _build_snapshot(
    user_id: str, scope: str, start: date, end: date
) -> Dict[str, Any]:
    """Build the JSONB snapshot stored in shared_plans.snapshot.

    For scope=plan: list of workouts in the date range with their full
    exercises_json. Other scopes return a stub for now and can be expanded
    incrementally without breaking the public contract.
    """
    if scope != "plan":
        return {"placeholder": True, "scope": scope}

    db = get_supabase_db()
    rows = db.list_workouts(
        user_id=user_id,
        from_date=start.isoformat(),
        to_date=end.isoformat(),
        limit=200,
        order_asc=True,
    )

    workouts: List[Dict[str, Any]] = []
    completed = 0
    total_duration = 0
    for row in rows:
        w = dict(row)
        raw = w.get("exercises_json") or w.get("exercises")
        exercises = parse_json_field(raw, [])
        sched = str(w.get("scheduled_date", ""))[:10]
        is_completed = bool(w.get("is_completed"))
        if is_completed:
            completed += 1
        duration = int(w.get("duration_minutes") or 0)
        total_duration += duration
        workouts.append(
            {
                "id": w.get("id"),
                "name": w.get("name"),
                "type": w.get("type"),
                "scheduled_date": sched,
                "is_completed": is_completed,
                "completed_at": w.get("completed_at"),
                "duration_minutes": duration,
                "estimated_calories": w.get("estimated_calories"),
                "exercises": exercises,
            }
        )

    return {
        "workouts": workouts,
        "summary": {
            "total_workouts": len(workouts),
            "completed_workouts": completed,
            "total_duration_minutes": total_duration,
            "date_range": {
                "start": start.isoformat(),
                "end": end.isoformat(),
            },
        },
    }


class CreatePlanShareRequest(BaseModel):
    period: str = Field(..., description="day | week | month | ytd | custom")
    scope: str = Field("plan", description="plan | prs | one_rm | summary")
    start_date: Optional[str] = Field(None, description="YYYY-MM-DD anchor")
    end_date: Optional[str] = Field(None, description="YYYY-MM-DD (custom only)")


class ShareLinkResponse(BaseModel):
    url: str
    token: str
    scope: str
    period: str
    start_date: str
    end_date: str
    deep_link: str


@router.post("/share-link", response_model=ShareLinkResponse)
async def create_plan_share_link(
    req: CreatePlanShareRequest,
    current_user: dict = Depends(get_current_user),
) -> ShareLinkResponse:
    if req.period not in VALID_PERIODS:
        raise HTTPException(status_code=400, detail=f"Invalid period: {req.period}")
    if req.scope not in VALID_SCOPES:
        raise HTTPException(status_code=400, detail=f"Invalid scope: {req.scope}")

    user_id = current_user["id"]
    start, end = _resolve_date_range(req.period, req.start_date, req.end_date)
    snapshot = _build_snapshot(user_id, req.scope, start, end)

    db = get_supabase_db()
    token: Optional[str] = None
    last_err: Optional[Exception] = None
    for _ in range(3):
        candidate = _make_token()
        try:
            insert = (
                db.client.table("shared_plans")
                .insert(
                    {
                        "user_id": user_id,
                        "share_token": candidate,
                        "scope": req.scope,
                        "period": req.period,
                        "start_date": start.isoformat(),
                        "end_date": end.isoformat(),
                        "snapshot": snapshot,
                    }
                )
                .execute()
            )
            if insert.data:
                token = candidate
                break
        except Exception as exc:  # token collision or other
            last_err = exc
            logger.warning("plan share token insert retry: %s", exc)

    if not token:
        logger.error("Failed to insert plan share row: %s", last_err)
        raise HTTPException(status_code=500, detail="Could not create share link")

    deep_link = (
        f"fitwiz://share?scope={req.scope}&period={req.period}"
        f"&start={start.isoformat()}&end={end.isoformat()}"
    )

    return ShareLinkResponse(
        url=f"{PUBLIC_BASE_URL}/{token}",
        token=token,
        scope=req.scope,
        period=req.period,
        start_date=start.isoformat(),
        end_date=end.isoformat(),
        deep_link=deep_link,
    )


@router.delete("/share-link/{token}")
async def revoke_plan_share_link(
    token: str = Path(..., min_length=4, max_length=32),
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    user_id = current_user["id"]
    db = get_supabase_db()

    row = (
        db.client.table("shared_plans")
        .select("id,user_id,revoked_at")
        .eq("share_token", token)
        .maybe_single()
        .execute()
    )
    data = row.data if row else None
    if not data:
        raise HTTPException(status_code=404, detail="Share link not found")
    if data["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not your share link")
    if data.get("revoked_at"):
        return {"revoked": True, "already": True}

    db.client.table("shared_plans").update(
        {"revoked_at": datetime.utcnow().isoformat()}
    ).eq("id", data["id"]).execute()
    return {"revoked": True}


@router.get("/public/{token}")
async def get_public_plan(
    token: str = Path(..., min_length=4, max_length=32),
) -> Dict[str, Any]:
    """Anonymous read — looks up the public view by token."""
    db = get_supabase_db()
    try:
        row = (
            db.client.table("public_plans_v")
            .select("*")
            .eq("share_token", token)
            .maybe_single()
            .execute()
        )
    except Exception as exc:
        logger.warning("public plan lookup failed: %s", exc)
        raise HTTPException(status_code=404, detail="Share not found")

    data = row.data if row else None
    if not data:
        raise HTTPException(status_code=404, detail="Share not found")
    return data
