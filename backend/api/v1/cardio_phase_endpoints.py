"""
Cardio Phase Recommendation endpoint.

Surfaces a single endpoint powering the period-aware cardio intensity banner
shown on the cardio plan + log-cardio start screens. Auth-gated; routing /
ownership / pregnancy / contraceptive gates live in
`services.cardio_phase_service`.

TODO: register in __init__.py (cardio-composer agent / wire-up step).
    Suggested wiring:
        from api.v1 import cardio_phase_endpoints
        router.include_router(cardio_phase_endpoints.router)
"""
from __future__ import annotations

from datetime import date as _date

from fastapi import APIRouter, Depends, HTTPException, Query, Request, Response

from core.auth import get_current_user
from core.logger import get_logger
from core.supabase_client import get_supabase
from core.timezone_utils import user_today_date
from services.cardio_phase_service import get_phase_recommendation

logger = get_logger(__name__)

router = APIRouter(prefix="/cardio", tags=["Cardio Phase"])


@router.get("/phase-recommendation")
async def cardio_phase_recommendation(
    request: Request,
    date: _date | None = Query(
        None,
        description=(
            "Target local calendar date. Defaults to the user's local today."
        ),
    ),
    current_user: dict = Depends(get_current_user),
):
    """Return today's period-aware cardio intensity recommendation.

    * 200 with `{phase, recommended_intensity, rationale, evidence_citation,
      cycle_day, confidence}` when the recommendation is visible.
    * 204 (no body) when the user has opted out of cycle-aware reminders, has
      no hormonal profile, is in pregnancy mode, is post-menopausal, or is on
      hormonal contraceptives — i.e. whenever the banner must NOT render. The
      Flutter side treats 204 as "no banner" and shows nothing.
    """
    user_id = current_user.get("id") or current_user.get("user_id") or current_user.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="No user in token")
    user_id = str(user_id)

    target = date or user_today_date(request, None, user_id)
    logger.info(f"[CardioPhase] recommendation request user={user_id} date={target}")

    client = get_supabase().client
    rec = get_phase_recommendation(client, user_id, target)
    if rec is None:
        # 204 = explicitly "nothing to show" — distinct from 404 (missing) and
        # 200 with null body (which Dio sometimes parses inconsistently).
        return Response(status_code=204)

    payload = rec.to_dict()
    payload["date"] = target.isoformat()
    payload["user_id"] = user_id
    return payload
