"""
Workout Photos API Endpoints
============================
Casual per-workout photos (gym selfie / lift snapshot) captured optionally at
workout completion. Foundation for the shareables photo-first flow + the
slideshow / Strava-photo features.

Modeled on progress_photos.py:
- magic-byte content validation,
- S3 storage via the shared `S3Service.upload_bytes(key_prefix="workout-photos")`,
- presigned GET URLs on read (so the row stores only the storage_key + base url),
- ownership enforced against the authenticated user.
"""

import uuid
from datetime import datetime
from typing import List, Optional

import boto3
from botocore.config import Config as BotoConfig
from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Query, Depends, BackgroundTasks
from pydantic import BaseModel, Field

from core.db import get_supabase_db
from core.config import get_settings
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.s3_service import get_s3_service

logger = get_logger(__name__)

PRESIGNED_URL_EXPIRATION = 3600  # 1 hour

# 10MB upload cap (matches progress_photos)
MAX_FILE_SIZE = 10 * 1024 * 1024

# Content-type allowlist → magic-byte prefixes for validation.
ALLOWED_TYPES = {
    'image/jpeg': [b'\xff\xd8\xff'],
    'image/png': [b'\x89PNG\r\n\x1a\n'],
    'image/webp': [b'RIFF'],
    'image/heic': [b'ftyp'],  # HEIC carries an 'ftyp' box near the start
}

EXT_FROM_CONTENT_TYPE = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'image/heic': 'heic',
}

router = APIRouter()


# ============================================================================
# Pydantic Models
# ============================================================================

class WorkoutPhotoResponse(BaseModel):
    id: str
    user_id: str
    workout_id: Optional[str] = None
    photo_url: str
    thumbnail_url: Optional[str] = None
    storage_key: Optional[str] = None
    taken_at: datetime
    caption: Optional[str] = None
    visibility: str = 'private'
    created_at: datetime = Field(default_factory=datetime.utcnow)


# ---- Slideshow / transformation-video models ----

VALID_SLIDESHOW_SOURCES = {"workout_photos", "progress_photos", "food"}


class CountUpParams(BaseModel):
    """F9 count-up reveal — a number ticks 0 → final_value over a few seconds."""
    final_value: float
    label: str
    unit: str = ""
    value_format: str = "int"  # int | float1
    background_key: Optional[str] = None


class BeforeAfterParams(BaseModel):
    """F4 before/after reveal — two S3 keys + one UPSTREAM-generated caption.
    The caption is produced (and cached) by the caller; this endpoint never
    calls an LLM."""
    before_key: str
    after_key: str
    caption: str
    style: str = "wipe"  # wipe | fade


class SlideshowRequest(BaseModel):
    source: str = Field(..., description="workout_photos | progress_photos | food")
    date_from: Optional[str] = Field(None, description="ISO date/time lower bound")
    date_to: Optional[str] = Field(None, description="ISO date/time upper bound")
    style: str = Field("kenburns", description="kenburns | flat")
    count_up: Optional[CountUpParams] = None
    before_after: Optional[BeforeAfterParams] = None


class SlideshowJobResponse(BaseModel):
    job_id: str
    status: str
    source: str
    result_url: Optional[str] = None
    error: Optional[str] = None
    created_at: Optional[datetime] = None


# ============================================================================
# S3 helpers (presign / delete) — mirrors progress_photos.py
# ============================================================================

def _get_s3_client():
    """Boto3 S3 client with s3v4 signatures for presigning + deletion."""
    settings = get_settings()
    return boto3.client(
        's3',
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_default_region,
        config=BotoConfig(signature_version='s3v4'),
    )


def _presign_photo(photo: dict) -> dict:
    """Replace photo_url with a presigned S3 URL using the stored storage_key."""
    storage_key = photo.get('storage_key')
    if storage_key:
        try:
            settings = get_settings()
            s3 = _get_s3_client()
            photo['photo_url'] = s3.generate_presigned_url(
                'get_object',
                Params={'Bucket': settings.s3_bucket_name, 'Key': storage_key},
                ExpiresIn=PRESIGNED_URL_EXPIRATION,
            )
        except Exception as e:
            logger.debug(f"Presigned URL generation failed: {e}")
    return photo


def _delete_from_s3(storage_key: str) -> bool:
    """Best-effort S3 object delete. Runs in a BackgroundTask."""
    try:
        settings = get_settings()
        s3 = _get_s3_client()
        s3.delete_object(Bucket=settings.s3_bucket_name, Key=storage_key)
        logger.info(f"🗑️ [WorkoutPhotos] Deleted S3 object {storage_key}")
        return True
    except Exception as e:
        logger.error(f"❌ [WorkoutPhotos] S3 delete failed for {storage_key}: {e}", exc_info=True)
        return False


# ============================================================================
# Endpoints
# ============================================================================

@router.post("/workout-photos", response_model=WorkoutPhotoResponse)
async def upload_workout_photo(
    user_id: str = Form(...),
    file: UploadFile = File(...),
    workout_id: Optional[str] = Form(None),
    taken_at: Optional[str] = Form(None),
    caption: Optional[str] = Form(None),
    visibility: str = Form('private'),
    current_user: dict = Depends(get_current_user),
):
    """Upload a casual per-workout photo.

    - **user_id**: owner (must match the authenticated user)
    - **file**: image (JPEG / PNG / WebP / HEIC)
    - **workout_id**: optional link to the completed workout
    - **taken_at**: ISO timestamp (defaults to now)
    - **caption**: optional free text
    - **visibility**: 'private' | 'shared' | 'public'
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Must be one of: {list(ALLOWED_TYPES.keys())}",
        )

    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail="File too large. Maximum size is 10MB.")
    if not contents:
        raise HTTPException(status_code=400, detail="Empty file")

    # Magic-byte validation — header must match the declared content type.
    header = contents[:16]
    expected = ALLOWED_TYPES[file.content_type]
    if file.content_type == 'image/heic':
        if b'ftyp' not in header:
            raise HTTPException(status_code=400, detail="File content does not match declared content type")
    elif not any(header.startswith(m) for m in expected):
        raise HTTPException(status_code=400, detail="File content does not match declared content type")

    try:
        ext = EXT_FROM_CONTENT_TYPE.get(file.content_type, 'jpg')
        filename = f"workout_{uuid.uuid4().hex[:8]}.{ext}"

        # Upload via the shared byte-oriented S3 helper.
        s3 = get_s3_service()
        storage_key = s3.upload_bytes(
            contents,
            key_prefix=f"workout-photos/{user_id}",
            filename=filename,
            content_type=file.content_type or 'image/jpeg',
        )

        settings = get_settings()
        photo_url = (
            f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}"
            f".amazonaws.com/{storage_key}"
        )

        photo_taken_at = datetime.fromisoformat(taken_at) if taken_at else datetime.utcnow()

        db = get_supabase_db()
        result = db.client.table('workout_photos').insert({
            'user_id': user_id,
            'workout_id': workout_id,
            'photo_url': photo_url,
            'storage_key': storage_key,
            'taken_at': photo_taken_at.isoformat(),
            'caption': caption,
            'visibility': visibility,
        }).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to save photo record"), "workout_photos")

        logger.info(f"📸 [WorkoutPhotos] Stored photo {result.data[0].get('id')} for {user_id}")
        return WorkoutPhotoResponse(**_presign_photo(result.data[0]))

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "upload_workout_photo")


@router.get("/workout-photos/{user_id}", response_model=List[WorkoutPhotoResponse])
async def get_workout_photos(
    user_id: str,
    current_user: dict = Depends(get_current_user),
    workout_id: Optional[str] = Query(None, description="Filter by workout"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    from_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
):
    """List a user's workout photos, optionally filtered by workout / date range."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    db = get_supabase_db()
    try:
        query = db.client.table('workout_photos') \
            .select('*') \
            .eq('user_id', user_id) \
            .order('taken_at', desc=True) \
            .limit(limit) \
            .offset(offset)

        if workout_id:
            query = query.eq('workout_id', workout_id)
        if from_date:
            query = query.gte('taken_at', from_date)
        if to_date:
            query = query.lte('taken_at', to_date)

        result = query.execute()
        return [WorkoutPhotoResponse(**_presign_photo(photo)) for photo in (result.data or [])]

    except Exception as e:
        raise safe_internal_error(e, "get_workout_photos")


@router.delete("/workout-photos/{photo_id}")
async def delete_workout_photo(
    photo_id: str,
    background_tasks: BackgroundTasks,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """Delete a workout photo (S3 object + DB row). Ownership enforced."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    db = get_supabase_db()
    try:
        photo = db.client.table('workout_photos') \
            .select('storage_key') \
            .eq('id', photo_id) \
            .eq('user_id', user_id) \
            .maybe_single() \
            .execute()

        if not photo.data:
            raise HTTPException(status_code=404, detail="Photo not found")

        db.client.table('workout_photos') \
            .delete() \
            .eq('id', photo_id) \
            .eq('user_id', user_id) \
            .execute()

        # Defer the S3 delete so the response returns immediately.
        storage_key = photo.data.get('storage_key')
        if storage_key:
            background_tasks.add_task(_delete_from_s3, storage_key)

        return {"status": "deleted", "photo_id": photo_id}

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "delete_workout_photo")


# ============================================================================
# Slideshow / transformation video (Workstream D)
# ============================================================================
#
# POST /workout-photos/slideshow → create a slideshow_jobs row + kick a
# FastAPI BackgroundTask that renders the MP4 and writes result_url back.
# GET  /workout-photos/slideshow/{job_id} → poll status + presigned result_url.
#
# The render itself lives in services/slideshow_service.py (ffmpeg composite of
# the user's REAL photos — no per-frame AI). Three render shapes:
#   * full montage      (default)            — render_slideshow
#   * F9 count-up reveal (request.count_up)   — render_count_up
#   * F4 before/after    (request.before_after) — render_before_after
# ============================================================================


def _run_slideshow_job(job_id: str, user_id: str, payload: dict) -> None:
    """Background worker: render the requested video, persist result/error.

    Runs OUTSIDE the request lifecycle, so it uses the service-role Supabase
    client (`get_supabase_db()`) for its status writes — no per-request auth
    context is available here. Every failure is captured onto the job row
    (status='error') rather than swallowed, so the client always learns the
    outcome (no silent fallback — CLAUDE.md).
    """
    db = get_supabase_db()

    def _update(fields: dict) -> None:
        try:
            fields["updated_at"] = datetime.utcnow().isoformat()
            db.client.table("slideshow_jobs").update(fields).eq("id", job_id).execute()
        except Exception as e:
            logger.error(f"❌ [Slideshow] job {job_id} status write failed: {e}", exc_info=True)

    _update({"status": "processing"})
    try:
        # Lazy import — keeps ffmpeg/imageio off the hot import path for the
        # rest of the API and lets a render-only dependency fail gracefully.
        from services import slideshow_service as ss

        count_up = payload.get("count_up")
        before_after = payload.get("before_after")

        if before_after:
            result = ss.render_before_after(
                user_id,
                before_key=before_after["before_key"],
                after_key=before_after["after_key"],
                caption=before_after.get("caption", ""),
                style=before_after.get("style", "wipe"),
            )
        elif count_up:
            result = ss.render_count_up(
                user_id,
                final_value=float(count_up["final_value"]),
                label=count_up.get("label", ""),
                unit=count_up.get("unit", ""),
                value_format=count_up.get("value_format", "int"),
                background_key=count_up.get("background_key"),
            )
        else:
            result = ss.render_slideshow(
                user_id,
                source=payload["source"],
                date_from=payload.get("date_from"),
                date_to=payload.get("date_to"),
                style=payload.get("style", "kenburns"),
            )

        _update({
            "status": "done",
            "result_url": result["result_url"],
            "storage_key": result.get("storage_key"),
            "error": None,
        })
        logger.info(f"✅ [Slideshow] job {job_id} done → {result.get('storage_key')}")
    except Exception as e:
        logger.error(f"❌ [Slideshow] job {job_id} render failed: {e}", exc_info=True)
        _update({"status": "error", "error": str(e)[:500]})


@router.post("/workout-photos/slideshow", response_model=SlideshowJobResponse)
async def create_slideshow(
    request: SlideshowRequest,
    background_tasks: BackgroundTasks,
    user_id: str = Query(..., description="Owner (must match the authenticated user)"),
    current_user: dict = Depends(get_current_user),
):
    """Enqueue a transformation-video / reveal render and return its job_id.

    The actual render runs in a BackgroundTask; poll
    `GET /workout-photos/slideshow/{job_id}` for the presigned MP4 URL.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    if request.source not in VALID_SLIDESHOW_SOURCES:
        raise HTTPException(
            status_code=400,
            detail=f"source must be one of {sorted(VALID_SLIDESHOW_SOURCES)}",
        )

    payload = {
        "source": request.source,
        "date_from": request.date_from,
        "date_to": request.date_to,
        "style": request.style,
    }
    if request.count_up is not None:
        payload["count_up"] = request.count_up.model_dump()
    if request.before_after is not None:
        payload["before_after"] = request.before_after.model_dump()

    db = get_supabase_db()
    try:
        result = db.client.table("slideshow_jobs").insert({
            "user_id": user_id,
            "status": "pending",
            "source": request.source,
            "params": payload,
        }).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to create slideshow job"), "slideshow")

        job = result.data[0]
        job_id = job["id"]

        background_tasks.add_task(_run_slideshow_job, job_id, user_id, payload)

        logger.info(f"🎬 [Slideshow] enqueued job {job_id} source={request.source} for {user_id}")
        return SlideshowJobResponse(
            job_id=job_id,
            status="pending",
            source=request.source,
            created_at=_parse_created(job.get("created_at")),
        )

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "create_slideshow")


@router.get("/workout-photos/slideshow/{job_id}", response_model=SlideshowJobResponse)
async def get_slideshow_job(
    job_id: str,
    user_id: str = Query(..., description="Owner (must match the authenticated user)"),
    current_user: dict = Depends(get_current_user),
):
    """Poll a slideshow render job. When status='done', `result_url` is a fresh
    presigned MP4 URL (re-presigned on every read so it never serves expired)."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    db = get_supabase_db()
    try:
        res = db.client.table("slideshow_jobs") \
            .select("*") \
            .eq("id", job_id) \
            .eq("user_id", user_id) \
            .maybe_single() \
            .execute()

        if not res.data:
            raise HTTPException(status_code=404, detail="Slideshow job not found")

        job = res.data
        result_url = job.get("result_url")
        # Re-presign from the stored key so a long-polling client never hits an
        # expired URL even if the job finished hours ago.
        storage_key = job.get("storage_key")
        if storage_key and job.get("status") == "done":
            try:
                from services import slideshow_service as ss
                result_url = ss._presign(storage_key)
            except Exception as e:
                logger.debug(f"🔍 [Slideshow] re-presign failed for {storage_key}: {e}")

        return SlideshowJobResponse(
            job_id=job["id"],
            status=job.get("status", "pending"),
            source=job.get("source", ""),
            result_url=result_url,
            error=job.get("error"),
            created_at=_parse_created(job.get("created_at")),
        )

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "get_slideshow_job")


def _parse_created(value) -> Optional[datetime]:
    if not value:
        return None
    if isinstance(value, datetime):
        return value
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except Exception:
        return None
