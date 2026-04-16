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
from fastapi import APIRouter, Depends, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from core.auth import get_current_user
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()

# Reuse slowapi Limiter (mirrors chat_endpoints.py's limiter).
limiter = Limiter(key_func=get_remote_address)


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
