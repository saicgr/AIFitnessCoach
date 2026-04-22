"""
Set-note media presign endpoint.

Mirrors `social/images/presign` but targets the per-set note audio + photo
columns on the `set_performances` table (`notes_audio_url`,
`notes_photo_urls`). Photos already have a presign endpoint via the social
router (same bucket); audio needs its own route because the social
endpoint only whitelists image + video mime types.

Client: `mobile/flutter/lib/data/services/set_note_media_service.dart`
uploads the local `.m4a` recording captured by `EnhancedNotesSheet` via
the returned `upload_url` (S3 put_object) and then persists the
`public_url` on `SetLog.notesAudioPath` → DB column `notes_audio_url`.
"""
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from starlette.requests import Request

from core.auth import get_current_user, verify_user_ownership
from core.config import get_settings
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.rate_limiter import limiter

# Reuse the S3 client singleton already exported by the social feed module
# so all presign paths share the same boto3 connection.
from ..social.feed import get_s3_client

logger = get_logger(__name__)

router = APIRouter(prefix="/set-notes", tags=["workouts"])


# Whitelisted audio mime types — match what `flutter_sound` / `record` emit.
_ALLOWED_AUDIO_TYPES = {
    "audio/m4a",
    "audio/mp4",
    "audio/aac",
    "audio/mpeg",   # mp3
    "audio/wav",
    "audio/x-wav",
    "audio/ogg",
}

_MAX_AUDIO_MB = 25  # voice notes are short; 25 MB is a very generous cap


@router.post("/audio/presign")
@limiter.limit("15/minute")
async def get_audio_presign(
    request: Request,
    user_id: str = Query(..., description="User ID requesting upload"),
    file_extension: str = Query("m4a", description="File extension"),
    content_type: str = Query("audio/m4a", description="MIME content type"),
    current_user: dict = Depends(get_current_user),
):
    """
    Return a pre-signed S3 PUT URL for uploading a per-set voice note.
    Client uploads directly to S3 — zero bytes through the API server.

    Response:
      - `upload_url`   — 10-minute presigned PUT URL
      - `storage_key`  — S3 object key
      - `public_url`   — canonical URL persisted on SetLog.notesAudioPath
    """
    verify_user_ownership(current_user, user_id)

    ct = (content_type or "").lower()
    if ct not in _ALLOWED_AUDIO_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid audio content type '{content_type}'. "
                f"Allowed: {', '.join(sorted(_ALLOWED_AUDIO_TYPES))}"
            ),
        )

    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    storage_key = (
        f"set_note_audio/{user_id}/"
        f"{timestamp}_{uuid.uuid4().hex[:8]}.{file_extension}"
    )

    try:
        s3 = get_s3_client()
        settings = get_settings()

        presigned_url = s3.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": settings.s3_bucket_name,
                "Key": storage_key,
                "ContentType": content_type,
            },
            ExpiresIn=600,  # 10 minutes
        )

        public_url = (
            f"https://{settings.s3_bucket_name}.s3."
            f"{settings.aws_default_region}.amazonaws.com/{storage_key}"
        )

        logger.info(
            "[SetNoteAudio] Issued presigned PUT for user=%s key=%s (max %dMB)",
            user_id, storage_key, _MAX_AUDIO_MB,
        )

        return {
            "upload_url": presigned_url,
            "storage_key": storage_key,
            "public_url": public_url,
        }
    except Exception as e:
        logger.error(
            "[SetNoteAudio] Presign failed for user=%s: %s", user_id, e,
            exc_info=True,
        )
        raise safe_internal_error(e, "set_note_audio_presign")
