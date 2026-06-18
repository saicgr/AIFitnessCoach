"""
Strava outbound export (Workstream E3/E4).

Pushes a *completed Zealova workout* to Strava as a manual activity, linking
the Zealova app in the activity description. This is the "advise → act" loop
for the share/Strava feature.

Two entry points:

    maybe_push_to_strava(...)   — the FAIL-OPEN completion hook. Loads the
        user's Strava account, checks the `auto_share_to_strava` toggle + the
        `activity:write` scope, refreshes the token if expired, and pushes.
        EVERY failure is swallowed + logged — a Strava error must NEVER affect
        workout completion (feedback_workout_gen_zero_regression).

    push_workout_to_strava(...) — the on-demand push used by the manual
        ``POST /workouts/{id}/share-to-strava`` endpoint. Raises real errors so
        the caller can surface them (no silent fallback).

IMPORTANT — photos: Strava's PUBLIC API has NO endpoint to attach a photo to an
activity (``/uploads`` accepts only fit/gpx/tcx activity *files*, not images).
So we do NOT upload the post-workout photo server-side. The pushed activity's
description links back to Zealova; the photo reaches Strava via the OS
share-sheet to the Strava app on the CLIENT. We never fake a photo upload.

Activity-type mapping: a Zealova workout `type` is a coarse string
(strength/cardio/hiit/yoga/…). Strava wants a `sport_type` — we map the common
ones and default strength-y sessions to ``WeightTraining``.
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, Optional

from core.config import get_settings
from core.db import get_supabase_db
from services.sync.oauth_base import (
    ReauthRequiredError,
    SyncAccount,
    SyncProviderError,
)
from services.sync.strava import StravaProvider
from services.sync.token_encryption import encrypt_token

logger = logging.getLogger(__name__)

# Zealova workout `type` → Strava `sport_type`. Strava's manual-activity API
# accepts a fixed enum; anything strength-shaped maps to WeightTraining, and a
# few cardio types map to their Strava equivalents. Unknown → Workout (a valid
# generic Strava type) so we never 400 on an unexpected string.
_WORKOUT_TYPE_TO_STRAVA: Dict[str, str] = {
    "strength": "WeightTraining",
    "weights": "WeightTraining",
    "weight_training": "WeightTraining",
    "hypertrophy": "WeightTraining",
    "powerlifting": "WeightTraining",
    "bodyweight": "WeightTraining",
    "calisthenics": "WeightTraining",
    "hiit": "Workout",
    "circuit": "Workout",
    "crossfit": "Crossfit",
    "cardio": "Workout",
    "yoga": "Yoga",
    "mobility": "Yoga",
    "stretching": "Yoga",
    "pilates": "Pilates",
    "run": "Run",
    "running": "Run",
    "cycle": "Ride",
    "cycling": "Ride",
    "swim": "Swim",
    "swimming": "Swim",
    "row": "Rowing",
    "rowing": "Rowing",
}


def _strava_sport_type(workout_type: Optional[str]) -> str:
    if not workout_type:
        return "WeightTraining"
    return _WORKOUT_TYPE_TO_STRAVA.get(str(workout_type).strip().lower(), "Workout")


def _build_description(workout: Dict[str, Any], has_photo: bool) -> str:
    """Compose the activity description that links back to Zealova.

    Includes the workout name + a Zealova attribution line. If a post-workout
    photo exists we mention it (the photo itself is shared client-side via the
    OS share-sheet, not uploaded here).
    """
    settings = get_settings()
    site = (getattr(settings, "web_marketing_url", None) or "https://zealova.com").rstrip("/")
    name = workout.get("name") or "Workout"
    lines = [f"Completed with Zealova — {name}."]
    duration_min = workout.get("duration_minutes")
    if duration_min:
        try:
            lines.append(f"{int(duration_min)} min session.")
        except (TypeError, ValueError):
            pass
    if has_photo:
        lines.append("Photo shared from Zealova.")
    lines.append(f"Train smarter with AI coaching → {site}")
    return "\n".join(lines)


def _resolve_start_dt(workout: Dict[str, Any]) -> datetime:
    """Best start timestamp for the Strava activity.

    Prefer ``completed_at`` (the workout just finished), fall back to
    ``scheduled_date``, then to now. Always returned tz-aware UTC.
    """
    for key in ("completed_at", "scheduled_date"):
        raw = workout.get(key)
        if not raw:
            continue
        if isinstance(raw, datetime):
            return raw if raw.tzinfo else raw.replace(tzinfo=timezone.utc)
        s = str(raw)
        if s.endswith("Z"):
            s = s[:-1] + "+00:00"
        try:
            dt = datetime.fromisoformat(s)
            return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return datetime.now(timezone.utc)


def _load_strava_account_row(supabase, user_id: str) -> Optional[Dict[str, Any]]:
    """Fetch the user's active Strava ``oauth_sync_accounts`` row (or None).

    Returns the raw DB row (encrypted tokens + scopes + auto_share_to_strava) so
    callers can inflate a ``SyncAccount`` and read the toggle. Does not raise on
    "not connected" — that's a normal not-found, returns None.
    """
    res = (
        supabase.table("oauth_sync_accounts")
        .select("*")
        .eq("user_id", user_id)
        .eq("provider", "strava")
        .eq("status", "active")
        .limit(1)
        .execute()
    )
    rows = res.data or []
    return rows[0] if rows else None


def _ensure_fresh_token(supabase, account: SyncAccount, row: Dict[str, Any]) -> SyncAccount:
    """Refresh the Strava access token if it's expired, persist the new token.

    Mirrors the orchestrator's refresh-and-persist path so a stale token doesn't
    fail the push. Returns a SyncAccount with a live access_token. Raises
    ``ReauthRequiredError`` if the refresh token is dead.
    """
    expires_at = account.expires_at
    needs_refresh = expires_at is not None and (
        (expires_at - datetime.now(timezone.utc)).total_seconds() < 60
    )
    if not needs_refresh:
        return account

    provider = StravaProvider()
    bundle = provider.refresh_token(account)  # raises ReauthRequiredError if dead
    # Persist the refreshed token so the next push (and the next pull-sync)
    # reuses it instead of refreshing again.
    try:
        supabase.table("oauth_sync_accounts").update({
            "access_token_encrypted": encrypt_token(bundle.access_token),
            "refresh_token_encrypted": (
                encrypt_token(bundle.refresh_token) if bundle.refresh_token else row.get("refresh_token_encrypted")
            ),
            "expires_at": bundle.expires_at.isoformat() if bundle.expires_at else None,
        }).eq("id", str(account.id)).execute()
    except Exception as persist_err:  # pragma: no cover — DB flake
        logger.warning(f"[strava_export] token persist after refresh failed: {persist_err}")

    # Return an account carrying the live token.
    account.access_token = bundle.access_token
    account.refresh_token = bundle.refresh_token or account.refresh_token
    account.expires_at = bundle.expires_at
    return account


def _has_workout_photo(supabase, workout_id: Optional[str]) -> bool:
    """Whether a per-workout photo exists (Workstream C). Used only to enrich
    the description text — we never upload it. Best-effort, returns False on any
    error."""
    if not workout_id:
        return False
    try:
        res = (
            supabase.table("workout_photos")
            .select("id")
            .eq("workout_id", workout_id)
            .limit(1)
            .execute()
        )
        return bool(res.data)
    except Exception:
        return False


def push_workout_to_strava(
    *,
    supabase,
    user_id: str,
    workout: Dict[str, Any],
) -> Dict[str, Any]:
    """Push one completed workout to Strava as a manual activity.

    RAISES on error (no silent fallback) — the on-demand endpoint surfaces these
    to the user. Returns the created Strava activity JSON (includes ``id``).

    Preconditions checked here (all raise a clear error):
      - a Strava account is connected (``SyncProviderError`` if not),
      - the account has ``activity:write`` scope (``ReauthRequiredError``).
    """
    row = _load_strava_account_row(supabase, user_id)
    if not row:
        raise SyncProviderError("Strava is not connected for this user")

    account = SyncAccount.from_db_row(row)
    if "activity:write" not in (account.scopes or []):
        raise ReauthRequiredError(
            "Strava account is missing the activity:write scope — reconnect Strava to enable sharing"
        )

    account = _ensure_fresh_token(supabase, account, row)

    provider = StravaProvider()
    has_photo = _has_workout_photo(supabase, str(workout.get("id") or "") or None)
    duration_sec = int((workout.get("duration_minutes") or 0)) * 60
    # Strava requires elapsed_time >= 1; create_activity already clamps it.
    activity = provider.create_activity(
        account,
        name=workout.get("name") or "Zealova Workout",
        activity_type=_strava_sport_type(workout.get("type")),
        start_date=_resolve_start_dt(workout),
        elapsed_time_sec=duration_sec or 1,
        description=_build_description(workout, has_photo),
        calories=_to_float(workout.get("calories")),
    )
    logger.info(
        f"🏋️ [strava_export] pushed workout={workout.get('id')} → strava activity={activity.get('id')} "
        f"for user={user_id}"
    )
    return activity


def maybe_push_to_strava(*, user_id: str, workout_id: str) -> None:
    """FAIL-OPEN completion hook (E3). Auto-push the workout to Strava iff:
      - the user has an active Strava account,
      - ``auto_share_to_strava`` is on for that account,
      - the account has ``activity:write`` scope.

    EVERY failure is caught + logged here. This runs as a FastAPI
    BackgroundTask after workout completion; a Strava outage, a dead token, a
    missing scope, or a 4xx must NEVER bubble up or affect the completion
    response (feedback_workout_gen_zero_regression).
    """
    try:
        db = get_supabase_db()
        supabase = db.client

        row = _load_strava_account_row(supabase, user_id)
        if not row:
            return  # Strava not connected — nothing to do.
        if not bool(row.get("auto_share_to_strava")):
            return  # toggle off — respect the user's choice silently.
        if "activity:write" not in list(row.get("scopes") or []):
            logger.info(
                f"[strava_export] auto-share on but account lacks activity:write — "
                f"skipping push for user={user_id}"
            )
            return

        workout_res = (
            supabase.table("workouts")
            .select("id, name, type, duration_minutes, completed_at, scheduled_date, estimated_calories")
            .eq("id", workout_id)
            .limit(1)
            .execute()
        )
        if not workout_res.data:
            logger.warning(f"[strava_export] workout {workout_id} not found for auto-push")
            return
        workout = dict(workout_res.data[0])
        # The workouts table stores calories under `estimated_calories`; normalize
        # to the `calories` key the push helper reads.
        workout["calories"] = workout.get("estimated_calories")

        push_workout_to_strava(supabase=supabase, user_id=user_id, workout=workout)
    except ReauthRequiredError as e:
        # Token/scope dead — log, don't raise. The settings screen surfaces the
        # reconnect prompt on the next account refresh.
        logger.info(f"[strava_export] auto-push reauth required for user={user_id}: {e}")
    except Exception as e:
        # Fail-open: a Strava failure must never affect workout completion.
        logger.warning(
            f"[strava_export] auto-push to Strava failed (non-blocking) for user={user_id}, "
            f"workout={workout_id}: {e}",
            exc_info=True,
        )


def _to_float(v: Any) -> Optional[float]:
    if v is None:
        return None
    try:
        return float(v)
    except (TypeError, ValueError):
        return None
