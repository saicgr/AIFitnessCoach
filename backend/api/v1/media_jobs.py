"""
Media Analysis Jobs — top-level polling endpoint.

Exposes `GET /api/v1/media-jobs/{job_id}` so any feature that kicks off a
media_analysis_jobs row (gym equipment import, custom exercise import, form
analysis, etc.) can poll status uniformly — independent of the chat module.

The chat-nested `GET /chat/media/job/{id}` still exists for backward
compatibility; this router just mirrors that handler at the top level with a
response shape matching what both the gym_profile and custom_exercise Flutter
repositories expect (`result_json`, `job_type`, `error_message`).
"""
import asyncio
from typing import Dict

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from slowapi import Limiter
from slowapi.util import get_remote_address

from core.auth import get_current_user
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()

# Reuse slowapi Limiter (mirrors chat_endpoints.py's limiter).
limiter = Limiter(key_func=get_remote_address)


class FormAnalysisSubmitRequest(BaseModel):
    """Submit a video (already uploaded to S3 via /chat/media/presign) for AI
    form analysis from OUTSIDE chat — e.g. the in-workout Form pill or the
    standalone Form Check quick action."""
    s3_key: str = Field(..., description="S3 key of the uploaded form video")
    mime_type: str = Field(default="video/mp4", description="Video MIME type")
    exercise_name: str | None = Field(
        default=None,
        description="Exercise being performed. Optional — the analyzer "
                    "auto-identifies the movement when omitted.",
    )
    exercise_id: str | None = Field(
        default=None,
        description="Exercise UUID this analysis is bound to. Stored in params "
                    "so the per-exercise Form history can filter by exact id.",
    )
    gym_profile_id: str | None = Field(
        default=None,
        description="Gym profile this analysis was performed at. Persisted on the "
                    "media_analysis_jobs.gym_profile_id column for per-gym history.",
    )


@router.post("/form-analysis")
@limiter.limit("10/minute")
async def submit_form_analysis(
    request: Request,
    body: FormAnalysisSubmitRequest,
    current_user: dict = Depends(get_current_user),
):
    """Enqueue a `form_analysis` media job for an already-uploaded video and
    return its job_id. Poll `GET /media-jobs/{job_id}` for the scored result.

    This is the non-chat entry point used by the workout UI (Form pill +
    quick-action). Reuses the exact same job runner + premium gate as the chat
    path, so the result shape matches `FormAnalysisService.analyze_form`.
    """
    from services.media_job_service import get_media_job_service
    from services.media_job_runner import run_media_job

    user_id = str(current_user.get("id") or current_user.get("user_id") or "")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    service = get_media_job_service()
    try:
        job_id = service.create_job(
            user_id=user_id,
            job_type="form_analysis",
            s3_keys=[body.s3_key],
            mime_types=[body.mime_type],
            media_types=["video"],
            params={
                "exercise_name": body.exercise_name,
                "exercise_id": body.exercise_id,
                "source": "workout",
            },
            gym_profile_id=body.gym_profile_id,
        )
    except HTTPException:
        # create_job raises 402 when the free-tier form-analysis gate is hit.
        raise
    except Exception as e:
        logger.error(f"[MediaJobs] form-analysis submit failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not start form analysis")

    asyncio.create_task(run_media_job(job_id))
    logger.info(f"🎥 [MediaJobs] form_analysis job {job_id} enqueued for user {user_id}")
    return {"job_id": job_id, "status": "pending"}


@router.get("/form-analyses/list")
@limiter.limit("30/minute")
async def list_form_analyses(
    request: Request,
    exercise: str | None = None,
    exercise_id: str | None = None,
    gym_profile_id: str | None = None,
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
):
    """List the user's completed form-analysis results, newest first.

    Powers the per-exercise / per-gym Form history tab.

    Filtering:
      - `exercise_id`  → EXACT match on the bound exercise UUID stored in
        params.exercise_id (preferred — precise, not fuzzy).
      - `exercise`     → fuzzy fallback when no id: case-insensitive substring
        either way ('Cable Row' matches 'Seated Cable Row').
      - `gym_profile_id` → only analyses performed at that gym.

    Returns {job_id, created_at, completed_at, gym_profile_id, gym_name, result}
    where `result` is the same scored payload `FormAnalysisService.analyze_form`
    returns (so the client renders it with the shared form gauge).
    """
    from core.db import get_supabase_db

    user_id = str(current_user.get("id") or current_user.get("user_id") or "")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    try:
        db = get_supabase_db()
        query = (
            db.client.table("media_analysis_jobs")
            .select("id, result, params, gym_profile_id, created_at, completed_at")
            .eq("user_id", user_id)
            .eq("job_type", "form_analysis")
            .eq("status", "completed")
        )
        # Push the gym filter to the DB (the column is indexed).
        if gym_profile_id:
            query = query.eq("gym_profile_id", gym_profile_id)
        rows = (
            query.order("completed_at", desc=True)
            .limit(min(max(limit, 1), 100))
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[MediaJobs] form-analyses list failed for {user_id}: {e}")
        return {"items": []}

    # Resolve gym names in one round-trip (null-safe; older rows have no gym).
    gym_names: Dict[str, str] = {}
    gym_ids = {r.get("gym_profile_id") for r in rows if r.get("gym_profile_id")}
    if gym_ids:
        try:
            gp_rows = (
                db.client.table("gym_profiles")
                .select("id, name")
                .in_("id", list(gym_ids))
                .execute()
            ).data or []
            gym_names = {g["id"]: g.get("name") for g in gp_rows}
        except Exception as e:
            logger.warning(f"[MediaJobs] gym name lookup failed: {e}")

    want_id = (exercise_id or "").strip()
    needle = (exercise or "").strip().lower()
    items = []
    for r in rows:
        result = r.get("result") or {}
        if not isinstance(result, dict):
            continue
        params = r.get("params") or {}

        if want_id:
            # Exact exercise_id match (precise, not fuzzy).
            if str(params.get("exercise_id") or "") != want_id:
                continue
        elif needle:
            identified = str(
                result.get("exercise_identified")
                or params.get("exercise_name")
                or ""
            ).lower()
            if not identified or (needle not in identified and identified not in needle):
                continue

        gid = r.get("gym_profile_id")
        items.append({
            "job_id": r.get("id"),
            "created_at": r.get("created_at"),
            "completed_at": r.get("completed_at"),
            "gym_profile_id": gid,
            "gym_name": gym_names.get(gid) if gid else None,
            "result": result,
        })
    return {"items": items}


@router.get("/{job_id}")
@limiter.limit("30/minute")
async def get_media_job(
    request: Request,
    job_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Poll status of a media analysis job (any job_type).

    Response shape matches Flutter client expectations:
      {
        "id": "uuid",
        "status": "pending" | "in_progress" | "completed" | "failed" | "cancelled",
        "job_type": "gym_equipment_import" | "custom_exercise_import" | "form_analysis" | ...,
        "result_json": {...} | null,       // populated when status=completed
        "error_message": "..." | null      // populated when status=failed
      }
    """
    from services.media_job_service import get_media_job_service

    # get_current_user may return a dict (chat_endpoints) or a bare string id
    # (some wrappers). Normalise to a string.
    if isinstance(current_user, dict):
        user_id = str(current_user.get("id") or current_user.get("user_id") or "")
    else:
        user_id = str(current_user)

    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    service = get_media_job_service()
    job = service.get_job(job_id)

    if not job:
        logger.info(f"🔍 [MediaJobs] Job {job_id} not found")
        raise HTTPException(status_code=404, detail="Job not found")

    # Ownership check — 404 to avoid leaking job existence.
    if str(job.get("user_id")) != user_id:
        logger.warning(
            f"⚠️ [MediaJobs] User {user_id} attempted to access job {job_id} "
            f"owned by {job.get('user_id')}"
        )
        raise HTTPException(status_code=404, detail="Job not found")

    return {
        "id": job.get("id", job_id),
        "status": job.get("status"),
        "job_type": job.get("job_type"),
        # media_job_service stores the completed payload under "result";
        # Flutter expects "result_json" — we alias here.
        "result_json": job.get("result"),
        "error_message": job.get("error_message"),
        "created_at": job.get("created_at"),
        "updated_at": job.get("updated_at"),
        "retry_count": job.get("retry_count", 0),
    }
