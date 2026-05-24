"""
Cardio Personal Records API endpoints.

Reads cardio PRs from the same `personal_records` table as strength PRs —
just filtered to rows where `sport IS NOT NULL` (migration 2094). Writes
happen elsewhere (cardio_pr_service.persist_prs is invoked from the
cardio-log insert path; that wiring is owned by the later cardio-pr-wire
agent).
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from services.cardio_pr_service import cardio_pr_service

logger = get_logger(__name__)
router = APIRouter(prefix="/cardio-prs", tags=["Cardio PRs"])


@router.get("")
async def get_cardio_prs(
    current_user: dict = Depends(get_current_user),
):
    """Return all-time cardio PRs for the current user, grouped per (sport, kind).

    Each item carries `record_value`, `record_unit`, `previous_value`,
    `improvement_percent`, `is_first_time_activity`, `achieved_at`, plus a
    small `sparkline` (last 10 attempts) so the Flutter sheet doesn't need
    a second round-trip for the inline chart.
    """
    user_id = current_user.get("id") or current_user.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="No user in token")

    db = get_supabase_db()
    items = cardio_pr_service.list_cardio_prs_for_user(db, str(user_id))

    # Group server-side by sport so Flutter can render section headers
    # without re-bucketing.
    by_sport: dict = {}
    for it in items:
        by_sport.setdefault(it["sport"], []).append(it)

    return {
        "user_id": str(user_id),
        "groups": [
            {"sport": sport, "items": its}
            for sport, its in sorted(by_sport.items())
        ],
        "total": len(items),
    }


@router.get("/{kind}/history")
async def get_cardio_pr_history(
    kind: str,
    sport: Optional[str] = Query(None, description="Optional sport filter — e.g. 'running'"),
    limit: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(get_current_user),
):
    """Time-series of attempts for a single (kind[, sport]).

    Powers the inline sparkline that expands when a user taps a PR row in
    the cardio_pr_history_sheet.
    """
    user_id = current_user.get("id") or current_user.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="No user in token")

    db = get_supabase_db()
    series = cardio_pr_service.history_for_kind(
        db, str(user_id), kind, sport=sport, limit=limit,
    )
    return {
        "user_id": str(user_id),
        "kind": kind,
        "sport": sport,
        "points": series,
    }
