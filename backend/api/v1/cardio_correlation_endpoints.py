"""
Cardio correlation endpoints.

Currently exposes one read-only endpoint::

    GET /cardio-correlation/sleep-pace

…which returns the Pearson correlation between prior-night sleep duration
and average run pace over the last 30 days. The actual math + data
fetching lives in `services.cardio_correlation_service` — this module is
only the HTTP shell + auth.

Status semantics
----------------
- **200** — enough data, returns ``{r, n, slope_sec_per_km_per_hour, copy}``.
- **204** — not enough paired sessions (< 20). Body is intentionally empty;
  the Flutter card collapses to a `SizedBox.shrink()` on 204 / no-data.

We use 204 (rather than 200 + null) so the mobile repository can branch on
the status code without parsing the body. Matches the convention used by
the cardio PR / dedup endpoints.

TODO: register in __init__.py — add
    from api.v1 import cardio_correlation_endpoints
    router.include_router(cardio_correlation_endpoints.router)
in `backend/api/v1/__init__.py`. (Composer/integrator owns the batch
register at end of slice; do NOT touch __init__.py from here.)
"""
from __future__ import annotations

from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, Query, Response, status

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.cardio_correlation_service import compute_sleep_pace_correlation

logger = get_logger(__name__)

router = APIRouter(prefix="/cardio-correlation", tags=["Cardio Correlation"])


@router.get(
    "/sleep-pace",
    summary="Pearson correlation between prior-night sleep and avg run pace",
    responses={
        200: {"description": "Correlation payload"},
        204: {"description": "Not enough paired sessions yet (need >= 20)"},
    },
)
async def get_sleep_pace_correlation(
    response: Response,
    days: int = Query(30, ge=7, le=180, description="Lookback window in days"),
    current_user: Dict[str, Any] = Depends(get_current_user),
    db=Depends(get_supabase_db),
) -> Optional[Dict[str, Any]]:
    """Return ``{r, n, slope_sec_per_km_per_hour, copy}`` or 204.

    Auth is required — correlations are user-specific. The user_id is
    pulled exclusively from the JWT (`current_user["id"]`) so a client
    cannot ask for another user's data.
    """
    user_id = current_user.get("id") or current_user.get("user_id")
    if not user_id:
        # Defense-in-depth: get_current_user normally guarantees this, but
        # if a future auth refactor changes the shape we want a loud 401-ish
        # response rather than silently leaking data.
        response.status_code = status.HTTP_401_UNAUTHORIZED
        return None

    try:
        result = compute_sleep_pace_correlation(db, user_id, days=days)
    except Exception as exc:
        # Don't leak the raw error to clients — keep the standard wrapper.
        raise safe_internal_error(
            exc,
            user_message="Couldn't compute the sleep × pace correlation.",
            log_message=f"[CardioCorrelation] user={user_id} compute failed",
        )

    if result is None:
        response.status_code = status.HTTP_204_NO_CONTENT
        return None

    return result
