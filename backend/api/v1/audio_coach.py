"""
Audio Coach API.

Endpoints:
- GET  /daily-brief        Returns today's personalised script + signed audio URL
- POST /mark-listened      Marks the current brief as listened (analytics)
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.timezone_utils import resolve_timezone, user_today_date

from services.audio_coach import (
    synthesize_coach_brief,
    upload_brief_mp3,
    get_signed_url_for_key,
)
from services.gemini.body_analyzer import generate_audio_coach_script

logger = logging.getLogger("audio_coach_api")

router = APIRouter()


class DailyBriefResponse(BaseModel):
    brief_id: str
    brief_date: str
    script_text: str
    audio_url: Optional[str] = None
    duration_seconds: Optional[int] = None
    coach_persona_id: Optional[str] = None
    listened: bool = False


class MarkListenedRequest(BaseModel):
    brief_id: str


def _collect_user_context(sb, user_id: str) -> Dict[str, Any]:
    """Pack the last-24 h user signals the Gemini script prompt needs."""
    user = sb.client.table("users").select(
        "first_name, name, email, last_workout_date, days_since_last_workout, "
        "in_comeback_mode"
    ).eq("id", user_id).maybe_single().execute()
    user_row = (user.data if user else {}) or {}

    # Streak + XP snapshot
    login_streak_row = None
    try:
        ls = sb.client.table("user_login_streaks").select(
            "current_streak, longest_streak"
        ).eq("user_id", user_id).maybe_single().execute()
        login_streak_row = ls.data if ls else None
    except Exception:
        login_streak_row = None

    # Today's scheduled workout
    today_workout = None
    try:
        tw = sb.client.table("workouts").select(
            "name, workout_type, duration_minutes"
        ).eq("user_id", user_id).eq(
            "scheduled_date", date.today().isoformat()
        ).limit(1).execute()
        if tw.data:
            today_workout = tw.data[0]
    except Exception:
        pass

    first_name = (user_row.get("first_name")
                  or (user_row.get("name") or "").split(" ")[0]
                  or (user_row.get("email") or "").split("@")[0])
    return {
        "first_name": first_name,
        "streak_days": (login_streak_row or {}).get("current_streak"),
        "longest_streak": (login_streak_row or {}).get("longest_streak"),
        "last_workout_date": user_row.get("last_workout_date"),
        "days_since_last_workout": user_row.get("days_since_last_workout"),
        "in_comeback_mode": user_row.get("in_comeback_mode"),
        "today_workout": today_workout,
    }


@router.get("/daily-brief", response_model=DailyBriefResponse)
async def daily_brief(
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        tz = resolve_timezone(request, sb, user_id)
        today = user_today_date(tz)

        # Cached row?
        existing = sb.client.table("audio_coach_briefs").select("*").eq(
            "user_id", user_id
        ).eq("brief_date", today.isoformat()).maybe_single().execute()
        if existing and existing.data:
            row = existing.data
            audio_url = get_signed_url_for_key(row["s3_key"]) if row.get("s3_key") else None
            return DailyBriefResponse(
                brief_id=row["id"],
                brief_date=row["brief_date"],
                script_text=row["script_text"],
                audio_url=audio_url,
                duration_seconds=row.get("duration_seconds"),
                coach_persona_id=row.get("coach_persona_id"),
                listened=row.get("listened_at") is not None,
            )

        # Resolve persona from ai_settings
        ai_settings_row = None
        try:
            ai_settings_row = sb.client.table("user_ai_settings").select(
                "coach_persona_id"
            ).eq("user_id", user_id).maybe_single().execute()
        except Exception:
            pass
        persona = (ai_settings_row.data.get("coach_persona_id")
                   if ai_settings_row and ai_settings_row.data else None) or "default"

        ctx = _collect_user_context(sb, user_id)
        script = await generate_audio_coach_script(
            user_context=ctx, coach_persona=persona, user_id=user_id,
        )

        # Synthesize + upload — gracefully degrade if TTS dep is missing.
        s3_key: Optional[str] = None
        signed_url: Optional[str] = None
        try:
            mp3_bytes = await synthesize_coach_brief(
                script_text=script.script_text,
                coach_persona_id=persona,
            )
            s3_key, signed_url = await upload_brief_mp3(
                user_id=user_id,
                brief_date_iso=today.isoformat(),
                mp3_bytes=mp3_bytes,
            )
        except RuntimeError as tts_err:
            logger.warning(f"[audio_coach] TTS disabled: {tts_err}")

        insert_payload = {
            "user_id": user_id,
            "brief_date": today.isoformat(),
            "coach_persona_id": persona,
            "script_text": script.script_text,
            "s3_key": s3_key,
        }
        ins = sb.client.table("audio_coach_briefs").insert(insert_payload).execute()
        if not ins.data:
            raise safe_internal_error(RuntimeError("brief insert failed"), "audio_coach")
        row = ins.data[0]

        return DailyBriefResponse(
            brief_id=row["id"],
            brief_date=row["brief_date"],
            script_text=row["script_text"],
            audio_url=signed_url,
            duration_seconds=row.get("duration_seconds"),
            coach_persona_id=row.get("coach_persona_id"),
            listened=False,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "audio_coach_daily_brief")


@router.post("/mark-listened")
async def mark_listened(
    data: MarkListenedRequest,
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]
        now = datetime.now(timezone.utc).isoformat()
        sb.client.table("audio_coach_briefs").update({
            "listened_at": now,
        }).eq("id", data.brief_id).eq("user_id", user_id).execute()
        return {"ok": True, "listened_at": now}
    except Exception as e:
        raise safe_internal_error(e, "audio_coach_mark_listened")
