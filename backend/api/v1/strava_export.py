"""
Strava outbound-share endpoints (Workstream E4).

- GET   /strava-export/preference            → {connected, can_write, auto_share_to_strava}
- PUT   /strava-export/preference            → set auto_share_to_strava
- POST  /workouts/{workout_id}/share-to-strava → push this completed workout now

The auto-share preference lives on the user's ``oauth_sync_accounts`` row
(provider='strava') — see migration 2266. The manual push reuses the same
``strava_export.push_workout_to_strava`` helper as the completion hook, but here
errors are surfaced to the user (the on-demand path is NOT fail-open — the user
asked for it and deserves to know if it failed).

NOTE: this pushes the *activity* only. Strava's public API has no endpoint to
attach a photo to an activity, so the post-workout photo reaches Strava via the
client OS share-sheet (the share card PNG → Strava app). The pushed activity
links back to Zealova in its description.
"""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from core.auth import get_current_user, verify_resource_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

from services.sync.oauth_base import ReauthRequiredError, SyncProviderError
from services.sync.strava_export import push_workout_to_strava

logger = logging.getLogger(__name__)

router = APIRouter()


# ─────────────────────────── Models ───────────────────────────

class StravaSharePreferenceResponse(BaseModel):
    connected: bool
    can_write: bool          # account has activity:write scope
    auto_share_to_strava: bool


class UpdateStravaSharePreferenceRequest(BaseModel):
    auto_share_to_strava: bool


class ShareToStravaResponse(BaseModel):
    status: str
    activity_id: Optional[str] = None
    strava_url: Optional[str] = None


# ─────────────────────────── Helpers ───────────────────────────

def _load_strava_row(supabase, user_id: str) -> Optional[dict]:
    res = (
        supabase.table("oauth_sync_accounts")
        .select("id, scopes, auto_share_to_strava, status")
        .eq("user_id", user_id)
        .eq("provider", "strava")
        .eq("status", "active")
        .limit(1)
        .execute()
    )
    rows = res.data or []
    return rows[0] if rows else None


# ─────────────────────────── Preference ───────────────────────────

@router.get("/strava-export/preference", response_model=StravaSharePreferenceResponse)
async def get_strava_share_preference(current_user: dict = Depends(get_current_user)):
    """Read the user's Strava auto-share preference + connection capability.

    `connected=false` means no active Strava account. `can_write=false` means
    the account is connected but lacks `activity:write` (needs reconnect) — the
    settings UI uses this to show a "reconnect to enable" hint.
    """
    db = get_supabase_db()
    row = _load_strava_row(db.client, current_user["id"])
    if not row:
        return StravaSharePreferenceResponse(
            connected=False, can_write=False, auto_share_to_strava=False
        )
    scopes = list(row.get("scopes") or [])
    return StravaSharePreferenceResponse(
        connected=True,
        can_write="activity:write" in scopes,
        auto_share_to_strava=bool(row.get("auto_share_to_strava")),
    )


@router.put("/strava-export/preference", response_model=StravaSharePreferenceResponse)
async def update_strava_share_preference(
    body: UpdateStravaSharePreferenceRequest,
    current_user: dict = Depends(get_current_user),
):
    """Toggle auto-push of completed workouts to Strava.

    Requires an active Strava connection (404 otherwise). Turning it ON does NOT
    require activity:write here — but the completion hook + manual push both gate
    on the scope, so the UI should surface `can_write` to set expectations.
    """
    db = get_supabase_db()
    row = _load_strava_row(db.client, current_user["id"])
    if not row:
        raise HTTPException(status_code=404, detail="Strava is not connected")
    try:
        db.client.table("oauth_sync_accounts").update(
            {"auto_share_to_strava": bool(body.auto_share_to_strava)}
        ).eq("id", row["id"]).execute()
    except Exception as e:
        raise safe_internal_error(e, "strava_export.update_preference")

    scopes = list(row.get("scopes") or [])
    logger.info(
        f"🔁 [strava_export] auto_share_to_strava={body.auto_share_to_strava} "
        f"for user={current_user['id']}"
    )
    return StravaSharePreferenceResponse(
        connected=True,
        can_write="activity:write" in scopes,
        auto_share_to_strava=bool(body.auto_share_to_strava),
    )


# ─────────────────────────── Manual push ───────────────────────────

@router.post("/workouts/{workout_id}/share-to-strava", response_model=ShareToStravaResponse)
async def share_workout_to_strava(
    workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Push a completed workout to Strava on demand.

    NOT fail-open — the user explicitly asked, so real errors surface:
      - 404 if the workout doesn't exist / isn't owned,
      - 400 if the workout isn't completed,
      - 409 if Strava isn't connected,
      - 401 if the account lacks `activity:write` (reconnect required),
      - 502 on a Strava API error.
    """
    db = get_supabase_db()
    supabase = db.client

    existing = db.get_workout(workout_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Workout not found")
    verify_resource_ownership(current_user, existing, "Workout")
    if not existing.get("is_completed"):
        raise HTTPException(status_code=400, detail="Workout is not completed yet")

    try:
        activity = push_workout_to_strava(
            supabase=supabase,
            user_id=current_user["id"],
            workout={
                "id": existing.get("id"),
                "name": existing.get("name"),
                "type": existing.get("type"),
                "duration_minutes": existing.get("duration_minutes"),
                "completed_at": existing.get("completed_at"),
                "scheduled_date": existing.get("scheduled_date"),
                # The workouts table stores calories under `estimated_calories`.
                "calories": existing.get("estimated_calories"),
            },
        )
    except ReauthRequiredError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except SyncProviderError as e:
        # "not connected" → 409; everything else (rate limit / API error) → 502.
        msg = str(e)
        if "not connected" in msg.lower():
            raise HTTPException(status_code=409, detail=msg)
        raise HTTPException(status_code=502, detail=msg)
    except Exception as e:
        raise safe_internal_error(e, "strava_export.share_workout")

    activity_id = str(activity.get("id")) if activity.get("id") is not None else None
    strava_url = f"https://www.strava.com/activities/{activity_id}" if activity_id else None
    return ShareToStravaResponse(status="ok", activity_id=activity_id, strava_url=strava_url)
