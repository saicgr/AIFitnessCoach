"""
Share AI endpoints — Workstream F cost-gated AI (F1, F2, F3).

  F1  POST /share/ai-restyle        explicit-trigger, daily-capped, cached image transform
      GET  /share/ai-restyle/quota  read-only quota snapshot for the UI
  F2  GET  /share/insight-line      deterministic-first one-liner + roast/hype toggle
  F3  GET  /share/day-in-proof      deterministic cross-domain card (+ one cached F2 line)

All paths are LITERAL and live under the /share prefix WITHOUT colliding with
the existing Imports module (share.py: /classify, /import-*, /history; and
share_orchestrator.py: /fetch-url, /import-audio, /import-pdf). These three new
nouns (ai-restyle, insight-line, day-in-proof) are distinct.

Cost discipline is enforced in services.share_ai_service (kill-switch flags,
per-user daily cap, sha256+style cache, deterministic-first insight) and
services.share_data_service (pure SQL assembly).
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile

from core.auth import get_current_user
from core.logger import get_logger
from services import share_ai_service, share_data_service

logger = get_logger(__name__)
router = APIRouter()

_ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/heic", "image/heif"}
_MAX_IMAGE_BYTES = 12 * 1024 * 1024  # 12MB


# --------------------------------------------------------------------------- #
# F1 — AI photo-transform (explicit trigger, capped, cached).
# --------------------------------------------------------------------------- #
@router.post("/share/ai-restyle")
async def ai_restyle(
    user_id: str = Form(...),
    style: str = Form(..., description="figurine | anime | comic | trading_card"),
    file: Optional[UploadFile] = File(None, description="image to transform (or pass image_key)"),
    image_key: Optional[str] = Form(None, description="existing S3 key to transform instead of uploading"),
    current_user: dict = Depends(get_current_user),
):
    """Transform a chosen photo into a preset AI style. Cache hit = free + cap
    untouched. Output carries a visible AI watermark/disclosure in metadata."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    # Resolve image bytes either from upload or an existing S3 key.
    if file is not None:
        if file.content_type and file.content_type.lower() not in _ALLOWED_IMAGE_TYPES:
            raise HTTPException(status_code=400, detail=f"Invalid image type {file.content_type}")
        image_bytes = await file.read()
        mime = (file.content_type or "image/jpeg").lower()
    elif image_key:
        from services.s3_service import get_s3_service
        try:
            image_bytes = get_s3_service().download_bytes(image_key)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Could not read image_key: {e}")
        mime = "image/jpeg"
    else:
        raise HTTPException(status_code=400, detail="Provide either a file or an image_key")

    if not image_bytes:
        raise HTTPException(status_code=400, detail="Empty image")
    if len(image_bytes) > _MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="Image too large (max 12MB)")

    try:
        result = share_ai_service.restyle_photo(
            user_id=user_id, image_bytes=image_bytes, style=style, mime_type=mime,
        )
    except share_ai_service.FeatureDisabled as e:
        raise HTTPException(status_code=503, detail=str(e))
    except share_ai_service.DailyCapReached as e:
        raise HTTPException(status_code=429, detail=str(e))
    except share_ai_service.ShareAIError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return result


@router.get("/share/ai-restyle/quota")
async def ai_restyle_quota(current_user: dict = Depends(get_current_user)):
    """Read-only quota snapshot (used today / cap / remaining / enabled)."""
    return share_ai_service.restyle_quota(str(current_user["id"]))


# --------------------------------------------------------------------------- #
# F2 — insight line + roast/hype toggle (deterministic-first, cached).
# --------------------------------------------------------------------------- #
@router.get("/share/insight-line")
async def insight_line(
    workout_id: Optional[str] = Query(None),
    food_log_id: Optional[str] = Query(None),
    date: Optional[str] = Query(None, description="YYYY-MM-DD (food/day variant)"),
    tone: str = Query("supportive", description="supportive | savage"),
    current_user: dict = Depends(get_current_user),
):
    """One-liner for any share card. Reuses cached coach insight / deterministic
    pool before any AI call; caches per (workout|day)+tone so re-opens are free.

    Provide one of: workout_id (workout card), food_log_id or date (food/day card).
    """
    user_id = str(current_user["id"])
    from core.db.facade import get_supabase_db
    db = get_supabase_db()

    if workout_id:
        wr = (
            db.client.table("workouts")
            .select("name, duration_minutes, estimated_calories, completed_at, exercises_json")
            .eq("id", workout_id).eq("user_id", user_id).limit(1).execute()
        )
        if not wr.data:
            raise HTTPException(status_code=404, detail="Workout not found")
        w = wr.data[0]
        local_date = (w.get("completed_at") or "")[:10] or None
        # Top PR for that workout (if any) elevates the line.
        top_pr = None
        try:
            pr = (
                db.client.table("personal_records")
                .select("exercise_name, record_value, record_unit, improvement_percent")
                .eq("user_id", user_id).eq("workout_id", workout_id)
                .order("record_value", desc=True).limit(1).execute()
            )
            if pr.data:
                r = pr.data[0]
                top_pr = {
                    "value": f"{r.get('record_value')} {r.get('record_unit') or ''}".strip(),
                    "exercise": r.get("exercise_name"),
                    "pct": round(float(r.get("improvement_percent") or 0), 1),
                }
        except Exception:
            pass
        stats = {"name": w.get("name") or "Workout"}
        if w.get("duration_minutes"):
            stats["metric"] = f"{w['duration_minutes']} min"
        if top_pr:
            stats["top_pr"] = top_pr
        res = share_ai_service.insight_line(
            user_id=user_id, kind="workout", tone=tone,
            cache_key=f"workout:{workout_id}", local_date=local_date, stats=stats,
        )
        return res

    if food_log_id:
        fr = (
            db.client.table("food_logs")
            .select("food_name, health_score, total_calories, protein_g, logged_at")
            .eq("id", food_log_id).eq("user_id", user_id).limit(1).execute()
        )
        if not fr.data:
            raise HTTPException(status_code=404, detail="Food log not found")
        f = fr.data[0]
        stats = {}
        if f.get("health_score") is not None:
            stats["health_score"] = f["health_score"]
        if f.get("protein_g"):
            stats["metric"] = f"{round(float(f['protein_g']))}g protein"
        elif f.get("total_calories"):
            stats["metric"] = f"{f['total_calories']} kcal"
        res = share_ai_service.insight_line(
            user_id=user_id, kind="food", tone=tone,
            cache_key=f"food:{food_log_id}", local_date=(f.get("logged_at") or "")[:10] or None,
            stats=stats,
        )
        return res

    if date:
        # Day-level food line from that day's aggregate.
        grade = share_data_service._meal_grade_for_day(user_id, date)
        stats = {}
        if grade:
            stats = {"health_score": grade["score"], "metric": f"{grade['protein_g']}g protein"}
        res = share_ai_service.insight_line(
            user_id=user_id, kind="food", tone=tone,
            cache_key=f"day-food:{user_id}:{date}", local_date=date, stats=stats,
        )
        return res

    raise HTTPException(status_code=400, detail="Provide workout_id, food_log_id, or date")


# --------------------------------------------------------------------------- #
# F3 — Day in Proof (deterministic + one cached F2 line).
# --------------------------------------------------------------------------- #
@router.get("/share/day-in-proof")
async def day_in_proof(
    user_id: Optional[str] = Query(None),
    date: Optional[str] = Query(None, description="YYYY-MM-DD (defaults to today UTC)"),
    current_user: dict = Depends(get_current_user),
):
    """Cross-domain card: top PR + meal letter-grade + streak + one cached line.
    Pure SQL assembly; no new LLM call beyond the cached F2 line."""
    uid = str(current_user["id"])
    if user_id and str(user_id) != uid:
        raise HTTPException(status_code=403, detail="Access denied")
    date_iso = date or datetime.now(timezone.utc).date().isoformat()
    try:
        return share_data_service.day_in_proof(uid, date_iso)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date (use YYYY-MM-DD)")
