"""
Cardio refuel endpoint.

`GET /api/v1/cardio-refuel/{cardio_log_id}` returns a `RefuelPrescription`
(water + carbs + protein + rationale) for a single completed cardio
session, or 204 No Content if the session is too light to warrant a
prescription or the user has already met their macro targets.

Wiring of this endpoint into the cardio_logs insert path (so we precompute
weather snapshots etc.) is owned by a later agent — this router only
exposes a read-only on-demand prescriber.
"""
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Response

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.refuel_service import RefuelPrescription, compute_refuel

logger = get_logger(__name__)
router = APIRouter()


@router.get("/{cardio_log_id}", response_model=RefuelPrescription)
async def get_refuel_for_cardio(
    cardio_log_id: str,
    response: Response,
    current_user: dict = Depends(get_current_user),
):
    """Return the ACSM-style refuel prescription for a given cardio session.

    Returns 204 No Content when no prescription is warranted (low-intensity
    session, or daily macros already met). Returns 404 if the session
    doesn't exist or doesn't belong to the requesting user.
    """
    try:
        db = get_supabase_db()
        user_id = current_user.get("id") or current_user.get("user_id")
        if not user_id:
            raise HTTPException(status_code=401, detail="Missing user id")

        # Pull the cardio log + verify ownership in one query.
        result = (
            db.client.table("cardio_logs")
            .select("*")
            .eq("id", cardio_log_id)
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        log_row = result.data if result else None
        if not log_row:
            raise HTTPException(status_code=404, detail="Cardio log not found")

        # User weight — from the users row. Falls back to 70 kg inside
        # compute_refuel if missing.
        user_row = db.get_user(user_id) or {}
        weight_kg = user_row.get("weight_kg")

        # Today's nutrition consumption + targets.
        today_iso = date.today().isoformat()
        try:
            daily_summary = db.get_daily_nutrition_summary(user_id, today_iso) or {}
        except Exception as e:  # noqa: BLE001 — non-fatal, treat as unknown
            logger.warning(f"[CardioRefuel] nutrition summary failed: {e}")
            daily_summary = {}
        try:
            targets = db.get_user_nutrition_targets(user_id) or {}
        except Exception as e:  # noqa: BLE001
            logger.warning(f"[CardioRefuel] nutrition targets failed: {e}")
            targets = {}

        # Merge into a single dict the prescriber understands.
        macros_context = {
            "total_carbs_g": daily_summary.get("total_carbs_g") or 0,
            "total_protein_g": daily_summary.get("total_protein_g") or 0,
            "daily_carbs_target_g": targets.get("daily_carbs_target_g"),
            "daily_protein_target_g": targets.get("daily_protein_target_g"),
        }

        prescription = compute_refuel(log_row, weight_kg, macros_context)
        if prescription is None:
            # 204 No Content — there's nothing useful to render.
            response.status_code = 204
            return None
        return prescription
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[CardioRefuel] error: {e}", exc_info=True)
        raise safe_internal_error(e, "cardio_refuel")
