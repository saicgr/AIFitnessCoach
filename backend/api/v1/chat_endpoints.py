"""Secondary endpoints for chat.  Sub-router included by main module."""
Chat API endpoints.

ENDPOINTS:
- POST   /api/v1/chat/send - Send a message to the AI coach
- POST   /api/v1/chat/send-stream - Send a message with SSE streaming response
- DELETE  /api/v1/chat/messages/{message_id} - Delete a single chat message
- PATCH   /api/v1/chat/messages/{message_id}/pin - Toggle pin on a message
- POST   /api/v1/chat/search - Search chat history by keyword
- POST   /api/v1/chat/media/presign - Get presigned S3 URL for media upload
- POST   /api/v1/chat/media/presign-batch - Get batch presigned S3 URLs
- GET    /api/v1/chat/history/{user_id} - Get chat history for a user
- DELETE  /api/v1/chat/history/{user_id} - Clear all chat history for a user
- GET    /api/v1/chat/rag/stats - Get RAG system statistics
- POST   /api/v1/chat/rag/search - Search similar past conversations

RATE LIMITS:
- /send + /send-stream: 10 requests/minute SHARED (AI-intensive)
- /messages/{id}: 10 requests/minute
- /messages/{id}/pin: 10 requests/minute
- /search: 10 requests/minute
- /media/presign: 3 requests/minute
- /media/presign-batch: 3 requests/minute
- /extract-intent: 10 requests/minute (AI-intensive)
- /rag/search: 20 requests/minute
- /history GET: 30 requests/minute
- /history DELETE: 3 requests/minute

from .chat_models import (
    ChatHistoryItem,
    PinToggleRequest,
    ChatSearchRequest,
    ExtractIntentRequest,
    ExtractIntentResponse,
    RAGSearchRequest,
    RAGSearchResult,
    MediaPresignRequest,
    MediaPresignResponse,
    MediaUploadResponse,
    BatchPresignFileRequest,
    BatchPresignRequest,
    BatchPresignResponseItem,
    BatchPresignResponse,
)

router = APIRouter()

@router.post("/extract-intent", response_model=ExtractIntentResponse)
@limiter.limit("10/minute")
async def extract_intent(
    body: ExtractIntentRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
    gemini: GeminiService = Depends(get_gemini_service_dep),
):
    """
    Extract intent and structured data from a user message.
    """
    logger.debug(f"Extracting intent from: {body.message[:50]}...")
    try:
        extraction = await gemini.extract_intent(body.message)
        logger.debug(f"Intent extracted: {extraction.intent.value}")
        return ExtractIntentResponse(
            intent=extraction.intent.value,
            exercises=extraction.exercises,
            muscleGroups=extraction.muscle_groups,
            modification=extraction.modification if extraction.modification else None,
            bodyPart=extraction.body_part if extraction.body_part else None,
        )
    except Exception as e:
        raise safe_internal_error(e, "extract_intent")


class RAGSearchRequest(BaseModel):
    """Request for RAG search."""
    query: str
    n_results: int = 5
    user_id: Optional[str] = None  # UUID from Supabase


class RAGSearchResult(BaseModel):
    """Single RAG search result."""
    question: str
    answer: str
    intent: str
    similarity: float


@router.post("/rag/search", response_model=List[RAGSearchResult])
@limiter.limit("20/minute")
async def search_similar(
    body: RAGSearchRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
    rag: RAGService = Depends(get_rag_service),
):
    """
    Search for similar past conversations in RAG system.
    """
    logger.debug(f"RAG search: {body.query[:50]}...")
    try:
        results = await rag.find_similar(
            query=body.query,
            n_results=body.n_results,
            user_id=body.user_id,
        )
        logger.debug(f"RAG found {len(results)} results")

        return [
            RAGSearchResult(
                question=r["metadata"]["question"],
                answer=r["metadata"]["answer"][:500] + "..." if len(r["metadata"]["answer"]) > 500 else r["metadata"]["answer"],
                intent=r["metadata"]["intent"],
                similarity=r["similarity"],
            )
            for r in results
        ]
    except Exception as e:
        raise safe_internal_error(e, "rag_search")


@router.get("/rag/stats")
async def get_rag_stats(current_user: dict = Depends(get_current_user), rag: RAGService = Depends(get_rag_service)):
    """Get RAG system statistics."""
    return rag.get_stats()


@router.delete("/rag/clear")
async def clear_rag(current_user: dict = Depends(get_current_user), rag: RAGService = Depends(get_rag_service)):
    """Clear all RAG data. USE WITH CAUTION!"""
    logger.warning("Clearing all RAG data")
    await rag.clear_all()
    return {"status": "cleared", "message": "All RAG data has been deleted"}


# ── Media Upload (Presigned S3 POST) ────────────────────────────────

# Allowed MIME types for media upload
ALLOWED_CONTENT_TYPES = {
    # Images
    "image/jpeg", "image/png", "image/webp",
    # Videos
    "video/mp4", "video/quicktime", "video/webm",
    # Audio
    "audio/m4a", "audio/mp4", "audio/aac", "audio/mpeg", "audio/wav",
}

# Size limits in bytes
MAX_IMAGE_SIZE = 10 * 1024 * 1024   # 10 MB
MAX_VIDEO_SIZE = 50 * 1024 * 1024   # 50 MB
MAX_AUDIO_SIZE = 25 * 1024 * 1024   # 25 MB

# Presigned URL expiry
PRESIGN_EXPIRY_SECONDS = 300  # 5 minutes

# Extension map for content types
EXT_MAP = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "video/mp4": "mp4",
    "video/quicktime": "mov",
    "video/webm": "webm",
    "audio/m4a": "m4a",
    "audio/mp4": "m4a",
    "audio/aac": "aac",
    "audio/mpeg": "mp3",
    "audio/wav": "wav",
}


class MediaPresignRequest(BaseModel):
    """Request body for generating a presigned S3 upload URL."""
    filename: str = Field(..., min_length=1, max_length=255, description="Original filename")
    content_type: str = Field(..., max_length=50, description="MIME type (e.g., 'video/mp4', 'image/jpeg')")
    media_type: str = Field(..., max_length=10, description="'image', 'video', or 'audio'")
    expected_size_bytes: int = Field(..., gt=0, description="Expected file size in bytes")


class MediaPresignResponse(BaseModel):
    """Response with presigned S3 POST URL and fields."""
    presigned_url: str = Field(..., description="URL to POST the file to")
    presigned_fields: Dict[str, str] = Field(..., description="Form fields to include in the POST")
    s3_key: str = Field(..., description="S3 object key for referencing in ChatRequest.media_ref")
    expires_in: int = Field(..., description="Seconds until the presigned URL expires")
    public_url: str = Field(..., description="Persistent public URL for the uploaded file")


def _validate_media_file(content_type: str, media_type: str, expected_size_bytes: int):
    """Validate a single media file's content type and size. Raises HTTPException on failure."""
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported content type: {content_type}. Allowed: {', '.join(sorted(ALLOWED_CONTENT_TYPES))}"
        )
    if media_type == "video" and not content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="media_type 'video' requires a video/* content_type")
    if media_type == "image" and not content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="media_type 'image' requires an image/* content_type")
    if media_type == "audio" and not content_type.startswith("audio/"):
        raise HTTPException(status_code=400, detail="media_type 'audio' requires an audio/* content_type")
    if media_type == "audio":
        max_size = MAX_AUDIO_SIZE
    elif media_type == "video":
        max_size = MAX_VIDEO_SIZE
    else:
        max_size = MAX_IMAGE_SIZE
    if expected_size_bytes > max_size:
        max_mb = max_size // (1024 * 1024)
        raise HTTPException(
            status_code=400,
            detail=f"{media_type.title()} too large. Maximum size: {max_mb}MB"
        )


def _generate_presigned_post(s3_client, bucket: str, s3_key: str, content_type: str, media_type: str) -> dict:
    """Generate a presigned S3 POST for a single file."""
    if media_type == "audio":
        max_size = MAX_AUDIO_SIZE
    elif media_type == "video":
        max_size = MAX_VIDEO_SIZE
    else:
        max_size = MAX_IMAGE_SIZE
    return s3_client.generate_presigned_post(
        Bucket=bucket,
        Key=s3_key,
        Fields={"Content-Type": content_type},
        Conditions=[
            {"Content-Type": content_type},
            ["content-length-range", 1, max_size],
        ],
        ExpiresIn=PRESIGN_EXPIRY_SECONDS,
    )


@router.post("/media/presign", response_model=MediaPresignResponse)
@limiter.limit("3/minute")
async def presign_media_upload(
    request: Request,
    body: MediaPresignRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate a presigned S3 POST URL for uploading media (video/image)
    for exercise form analysis.

    The client uploads directly to S3 using the returned URL and fields,
    then includes the s3_key in the ChatRequest.media_ref.
    """
    user_id = str(current_user["id"])

    _validate_media_file(body.content_type, body.media_type, body.expected_size_bytes)

    ext = EXT_MAP.get(body.content_type, "bin")
    s3_key = f"chat_media/{user_id}/{uuid.uuid4().hex}.{ext}"

    logger.info(f"Generating presigned POST for user {user_id}: {s3_key} ({body.content_type}, {body.expected_size_bytes} bytes)")

    try:
        settings = get_settings()

        if not settings.s3_bucket_name:
            raise HTTPException(status_code=503, detail="Media upload not configured")

        import boto3
        s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_default_region,
        )

        presigned = _generate_presigned_post(s3_client, settings.s3_bucket_name, s3_key, body.content_type, body.media_type)

        public_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{s3_key}"

        return MediaPresignResponse(
            presigned_url=presigned["url"],
            presigned_fields=presigned["fields"],
            s3_key=s3_key,
            expires_in=PRESIGN_EXPIRY_SECONDS,
            public_url=public_url,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate presigned URL for user {user_id}: {e}")
        raise safe_internal_error(e, "media_presign")


# ── Direct Media Upload (S3 + Gemini Files API in parallel) ─────────

class MediaUploadResponse(BaseModel):
    """Response from direct video upload — both S3 and Gemini file are ready."""
    s3_key: str
    public_url: str
    gemini_file_name: str  # e.g. "files/abc123xyz" — pass back in media_ref
    mime_type: str


@router.post("/media/upload", response_model=MediaUploadResponse)
@limiter.limit("10/minute")
async def upload_media_for_analysis(
    request: Request,
    file: UploadFile = File(...),
    media_type: str = Form(...),  # "video" or "image"
    duration_seconds: Optional[float] = Form(default=None),
    current_user: dict = Depends(get_current_user),
):
    """
    Upload media directly to the server.
    Backend simultaneously uploads to S3 (storage) and Gemini Files API (analysis).
    Returns both references so form analysis can skip S3 download entirely.

    Use instead of /media/presign for video form analysis to enable parallel
    S3 + Gemini upload and eliminate the S3 download step.
    """
    import tempfile
    import os
    import boto3
    from google.genai import types as genai_types
    from core.gemini_client import get_genai_client

    user_id = str(current_user["id"])
    set_log_context(user_id=f"...{user_id[-4:]}" if len(user_id) > 4 else user_id)
    mime_type = file.content_type or "video/mp4"

    # Validate content type and media type only (size validated after reading)
    if mime_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported content type: {mime_type}. Allowed: {', '.join(sorted(ALLOWED_CONTENT_TYPES))}"
        )
    if media_type == "video" and not mime_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="media_type 'video' requires a video/* content_type")
    if media_type == "image" and not mime_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="media_type 'image' requires an image/* content_type")

    ext = EXT_MAP.get(mime_type, "bin")
    s3_key = f"chat_media/{user_id}/{uuid.uuid4().hex}.{ext}"

    logger.info(f"Direct upload for user {user_id}: {s3_key} ({mime_type})")

    # Read file bytes once
    file_bytes = await file.read()
    file_size = len(file_bytes)
    logger.info(f"Received {file_size} bytes for upload")

    # Validate size after reading
    _validate_media_file(mime_type, media_type, file_size)

    settings = get_settings()

    if not settings.s3_bucket_name:
        raise HTTPException(status_code=503, detail="Media upload not configured")

    # Write to temp file for Gemini Files API (needs a file path)
    fd, tmp_path = tempfile.mkstemp(suffix=f".{ext}", prefix="upload_")
    os.close(fd)
    try:
        with open(tmp_path, "wb") as f:
            f.write(file_bytes)

        async def upload_to_s3():
            s3_client = boto3.client(
                "s3",
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
                region_name=settings.aws_default_region,
            )
            await asyncio.to_thread(
                s3_client.put_object,
                Bucket=settings.s3_bucket_name,
                Key=s3_key,
                Body=file_bytes,
                ContentType=mime_type,
            )
            logger.info(f"S3 upload complete: {s3_key}")

        async def upload_to_gemini():
            client = get_genai_client()
            gemini_file = await asyncio.to_thread(
                client.files.upload,
                file=tmp_path,
                config=genai_types.UploadFileConfig(
                    mime_type=mime_type,
                    display_name=f"form_{uuid.uuid4().hex[:8]}",
                ),
            )
            logger.info(f"Gemini upload complete: {gemini_file.name}, state={gemini_file.state}")
            return gemini_file

        # Upload to S3 and Gemini in parallel
        _, gemini_file = await asyncio.gather(
            upload_to_s3(),
            upload_to_gemini(),
        )

        public_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{s3_key}"

        return MediaUploadResponse(
            s3_key=s3_key,
            public_url=public_url,
            gemini_file_name=gemini_file.name,
            mime_type=mime_type,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Direct media upload failed for user {user_id}: {e}")
        raise safe_internal_error(e, "media_upload")
    finally:
        if os.path.exists(tmp_path):
            try:
                os.unlink(tmp_path)
            except OSError:
                pass


# ── Batch Media Upload (Presigned S3 POST) ──────────────────────────

class BatchPresignFileRequest(BaseModel):
    """Single file in a batch presign request."""
    filename: str = Field(..., min_length=1, max_length=255)
    content_type: str = Field(..., max_length=50)
    media_type: str = Field(..., max_length=10)
    expected_size_bytes: int = Field(..., gt=0)


class BatchPresignRequest(BaseModel):
    """Request body for batch presigned S3 upload URLs."""
    files: List[BatchPresignFileRequest] = Field(..., min_length=1, max_length=5)


class BatchPresignResponseItem(BaseModel):
    """Single item in a batch presign response."""
    presigned_url: str
    presigned_fields: Dict[str, str]
    s3_key: str
    expires_in: int
    public_url: str


class BatchPresignResponse(BaseModel):
    """Response with batch presigned S3 POST URLs."""
    items: List[BatchPresignResponseItem]


@router.post("/media/presign-batch", response_model=BatchPresignResponse)
@limiter.limit("3/minute")
async def presign_media_upload_batch(
    request: Request,
    body: BatchPresignRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate presigned S3 POST URLs for uploading multiple media files.

    Validates:
    - Each file's content type and size
    - Total batch: max 5 files
    - Max 5 images, max 3 videos
    - Total size: max 25MB for images-only, max 50MB if contains video
    """
    user_id = str(current_user["id"])

    # Count media types
    image_count = sum(1 for f in body.files if f.media_type == "image")
    video_count = sum(1 for f in body.files if f.media_type == "video")
    has_video = video_count > 0

    # Validate counts
    if image_count > 5:
        raise HTTPException(status_code=400, detail="Maximum 5 images per batch")
    if video_count > 3:
        raise HTTPException(status_code=400, detail="Maximum 3 videos per batch")

    # Validate total size
    total_size = sum(f.expected_size_bytes for f in body.files)
    max_total = 50 * 1024 * 1024 if has_video else 25 * 1024 * 1024
    if total_size > max_total:
        max_total_mb = max_total // (1024 * 1024)
        raise HTTPException(
            status_code=400,
            detail=f"Total batch size ({total_size // (1024 * 1024)}MB) exceeds maximum ({max_total_mb}MB)"
        )

    # Validate each file individually
    for f in body.files:
        _validate_media_file(f.content_type, f.media_type, f.expected_size_bytes)

    logger.info(f"Generating batch presigned POST for user {user_id}: {len(body.files)} files ({image_count} images, {video_count} videos)")

    try:
        settings = get_settings()

        if not settings.s3_bucket_name:
            raise HTTPException(status_code=503, detail="Media upload not configured")

        import boto3
        s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_default_region,
        )

        items = []
        for f in body.files:
            ext = EXT_MAP.get(f.content_type, "bin")
            s3_key = f"chat_media/{user_id}/{uuid.uuid4().hex}.{ext}"

            presigned = _generate_presigned_post(
                s3_client, settings.s3_bucket_name, s3_key, f.content_type, f.media_type
            )

            public_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{s3_key}"

            items.append(BatchPresignResponseItem(
                presigned_url=presigned["url"],
                presigned_fields=presigned["fields"],
                s3_key=s3_key,
                expires_in=PRESIGN_EXPIRY_SECONDS,
                public_url=public_url,
            ))

        return BatchPresignResponse(items=items)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate batch presigned URLs for user {user_id}: {e}")
        raise safe_internal_error(e, "media_presign_batch")


# ── Media Analysis Job Polling ──────────────────────────────────────────────


@router.get("/media/job/{job_id}")
@limiter.limit("30/minute")
async def get_media_job_status(
    request: Request,
    job_id: str,
    user_id: str = Depends(get_current_user),
):
    """
    Poll status of a background media analysis job.

    Returns job status, result (if completed), or error message (if failed).
    """
    from services.media_job_service import get_media_job_service

    service = get_media_job_service()
    job = service.get_job(job_id)

    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # Ensure user can only see their own jobs
    if job.get("user_id") != user_id:
        raise HTTPException(status_code=404, detail="Job not found")

    return {
        "job_id": job.get("id", job_id),
        "status": job.get("status"),
        "job_type": job.get("job_type"),
        "result": job.get("result"),
        "error_message": job.get("error_message"),
        "created_at": job.get("created_at"),
        "retry_count": job.get("retry_count", 0),
    }
