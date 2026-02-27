"""
Chat API endpoints.

ENDPOINTS:
- POST /api/v1/chat/send - Send a message to the AI coach
- POST /api/v1/chat/media/presign - Get presigned S3 URL for media upload
- POST /api/v1/chat/media/presign-batch - Get batch presigned S3 URLs
- GET  /api/v1/chat/history/{user_id} - Get chat history for a user
- GET  /api/v1/chat/rag/stats - Get RAG system statistics
- POST /api/v1/chat/rag/search - Search similar past conversations

RATE LIMITS:
- /send: 10 requests/minute (AI-intensive)
- /media/presign: 3 requests/minute
- /media/presign-batch: 3 requests/minute
- /extract-intent: 10 requests/minute (AI-intensive)
- /rag/search: 20 requests/minute
- /history: 30 requests/minute
"""
import json
import time
import uuid
from fastapi import APIRouter, HTTPException, Depends, Request, BackgroundTasks, Query
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from models.chat import ChatRequest, ChatResponse
from services.gemini_service import GeminiService
from services.rag_service import RAGService
from services.langgraph_service import LangGraphCoachService
from core.logger import get_logger
from core.supabase_db import get_supabase_db
from core.supabase_client import get_supabase
from core.rate_limiter import limiter
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.config import get_settings

router = APIRouter()
logger = get_logger(__name__)

# Service instances (will be initialized on startup)
gemini_service: Optional[GeminiService] = None
rag_service: Optional[RAGService] = None
langgraph_coach_service: Optional[LangGraphCoachService] = None


def get_coach_service() -> LangGraphCoachService:
    """Dependency to get LangGraph coach service."""
    if langgraph_coach_service is None:
        raise HTTPException(status_code=503, detail="LangGraph service not initialized")
    return langgraph_coach_service


def get_rag_service() -> RAGService:
    """Dependency to get RAG service."""
    if rag_service is None:
        raise HTTPException(status_code=503, detail="RAG service not initialized")
    return rag_service


def _save_chat_to_db(user_id: str, message: str, response_message: str, response_intent, response_agent_type, response_rag_context_used: bool, response_action_data):
    """Background task: Save chat message to database for persistence."""
    try:
        db = get_supabase_db()
        context_dict = {
            "intent": response_intent.value if hasattr(response_intent, 'value') else str(response_intent),
            "agent_type": response_agent_type.value if hasattr(response_agent_type, 'value') else str(response_agent_type),
            "rag_context_used": response_rag_context_used,
        }
        if response_action_data:
            context_dict["action_data"] = response_action_data

        chat_data = {
            "user_id": user_id,
            "user_message": message,
            "ai_response": response_message,
            "context_json": json.dumps(context_dict) if response_intent else None,
        }
        db.create_chat_message(chat_data)
        logger.debug(f"[Background] Chat message saved to database for user {user_id}, intent={response_intent}, agent={response_agent_type}")
    except Exception as db_error:
        logger.warning(f"[Background] Failed to save chat to database: {db_error}")


def _save_chat_analytics(user_id: str, message: str, response_message: str, response_intent, response_agent_type, response_rag_context_used: bool, response_time_ms: int, ai_settings):
    """Background task: Record chat interaction analytics with AI settings snapshot."""
    try:
        supabase = get_supabase().client
        analytics_data = {
            "user_id": user_id,
            "user_message_length": len(message),
            "ai_response_length": len(response_message),
            "coaching_style": ai_settings.coaching_style if ai_settings else "motivational",
            "communication_tone": ai_settings.communication_tone if ai_settings else "encouraging",
            "encouragement_level": ai_settings.encouragement_level if ai_settings else 0.7,
            "response_length": ai_settings.response_length if ai_settings else "balanced",
            "use_emojis": ai_settings.use_emojis if ai_settings else True,
            "agent_type": response_agent_type.value if hasattr(response_agent_type, 'value') else str(response_agent_type),
            "intent": response_intent.value if hasattr(response_intent, 'value') else str(response_intent),
            "rag_context_used": response_rag_context_used or False,
            "response_time_ms": response_time_ms,
        }
        supabase.table("chat_interaction_analytics").insert(analytics_data).execute()
        logger.debug(f"[Background] Chat analytics recorded for user {user_id}")
    except Exception as analytics_error:
        logger.warning(f"[Background] Failed to save chat analytics: {analytics_error}")


async def _log_chat_activity(user_id: str, response_intent, response_agent_type, response_rag_context_used: bool, response_time_ms: int):
    """Background task: Log successful chat activity."""
    try:
        await log_user_activity(
            user_id=user_id,
            action="chat",
            endpoint="/api/v1/chat/send",
            message=f"Chat: {response_intent.value if hasattr(response_intent, 'value') else str(response_intent)}",
            metadata={
                "intent": str(response_intent),
                "agent_type": str(response_agent_type),
                "rag_used": response_rag_context_used,
            },
            duration_ms=response_time_ms,
            status_code=200
        )
    except Exception as activity_error:
        logger.warning(f"[Background] Failed to log chat activity: {activity_error}")


@router.post("/send", response_model=ChatResponse)
@limiter.limit("10/minute")
async def send_message(
    request: Request,  # Must be named 'request' for slowapi rate limiter
    chat_request: ChatRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
    coach: LangGraphCoachService = Depends(get_coach_service),
):
    """
    Send a message to the AI fitness coach.

    This endpoint:
    1. Extracts intent from the message
    2. Retrieves similar past conversations (RAG)
    3. Generates an AI response with context
    4. Stores the Q&A for future RAG (background)
    5. Records analytics with AI settings snapshot (background)
    6. Returns action data for workout modifications
    """
    if str(current_user["id"]) != str(chat_request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Chat request from user {chat_request.user_id}: {chat_request.message[:50]}...")
    if chat_request.current_workout:
        logger.debug(f"Current workout: {chat_request.current_workout.name} (id={chat_request.current_workout.id})")
    if chat_request.workout_schedule:
        logger.debug(f"Workout schedule: yesterday={chat_request.workout_schedule.yesterday is not None}, today={chat_request.workout_schedule.today is not None}, tomorrow={chat_request.workout_schedule.tomorrow is not None}, thisWeek={len(chat_request.workout_schedule.thisWeek)}")

    # Premium gate checks for food scanning and text-to-calories
    # Only check gates when the request actually involves these features
    from core.premium_gate import check_premium_gate, track_premium_usage
    _chat_gate_feature = None  # Track which gate was checked for post-success usage increment

    has_image_media = bool(
        chat_request.image_base64
        or (chat_request.media_ref and chat_request.media_ref.media_type == "image")
        or (chat_request.media_refs and any(m.media_type == "image" for m in chat_request.media_refs))
    )

    if has_image_media:
        await check_premium_gate(chat_request.user_id, "food_scanning")
        _chat_gate_feature = "food_scanning"
    else:
        # Check for text-to-calories intent (calorie/nutrition text queries without images)
        msg_lower = chat_request.message.lower()
        calorie_keywords = ["calorie", "calories", "kcal", "how many cal", "nutrition info", "macros for", "macros in", "how much protein"]
        if any(kw in msg_lower for kw in calorie_keywords):
            await check_premium_gate(chat_request.user_id, "text_to_calories")
            _chat_gate_feature = "text_to_calories"

    # Track response time for analytics
    start_time = time.time()

    try:
        response = await coach.process_message(chat_request)
        response_time_ms = int((time.time() - start_time) * 1000)
        logger.info(f"Chat response sent: intent={response.intent}, rag_used={response.rag_context_used}, time={response_time_ms}ms")

        # Track premium gate usage after successful processing
        if _chat_gate_feature:
            background_tasks.add_task(track_premium_usage, chat_request.user_id, _chat_gate_feature)

        # Move DB writes to background tasks - these don't block the response.
        # Chat history is only read on subsequent requests (GET /history), not in this flow.
        background_tasks.add_task(
            _save_chat_to_db,
            chat_request.user_id,
            chat_request.message,
            response.message,
            response.intent,
            response.agent_type,
            response.rag_context_used,
            response.action_data,
        )

        background_tasks.add_task(
            _save_chat_analytics,
            chat_request.user_id,
            chat_request.message,
            response.message,
            response.intent,
            response.agent_type,
            response.rag_context_used,
            response_time_ms,
            chat_request.ai_settings,
        )

        background_tasks.add_task(
            _log_chat_activity,
            chat_request.user_id,
            response.intent,
            response.agent_type,
            response.rag_context_used,
            response_time_ms,
        )

        return response
    except Exception as e:
        logger.error(f"Failed to process message: {e}")
        # Log error to database with webhook alert
        await log_user_error(
            user_id=chat_request.user_id,
            action="chat",
            error=e,
            endpoint="/api/v1/chat/send",
            metadata={"message": chat_request.message[:200]},
            duration_ms=int((time.time() - start_time) * 1000),
            status_code=500
        )
        raise safe_internal_error(e, "chat_send_message")


class ChatHistoryItem(BaseModel):
    """Single chat history item."""
    id: str  # UUID string from Supabase
    role: str  # 'user' or 'assistant'
    content: str
    timestamp: str
    agent_type: Optional[str] = None  # "coach", "nutrition", "workout", "injury", "hydration"
    action_data: Optional[dict] = None


@router.get("/history/{user_id}", response_model=List[ChatHistoryItem])
@limiter.limit("30/minute")
async def get_chat_history(
    request: Request,
    user_id: str,
    current_user: dict = Depends(get_current_user),
    limit: int = Query(default=50, ge=1, le=200, description="Maximum number of messages to return"),
    offset: int = Query(default=0, ge=0, description="Number of messages to skip"),
):
    """
    Get chat history for a user with pagination.

    Returns messages in chronological order (oldest first).
    Each row in DB contains user_message + ai_response, so we expand to 2 messages.

    Args:
        user_id: The user's ID
        limit: Max messages to return (default 50, max 200)
        offset: Number of messages to skip (default 0)
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching chat history for user {user_id}, limit={limit}, offset={offset}")
    try:
        db = get_supabase_db()
        # Limit divided by 2 since each row becomes 2 messages
        # Offset also divided by 2 for the same reason
        db_limit = (limit + 1) // 2
        db_offset = offset // 2
        result = db.list_chat_history(user_id, limit=db_limit + db_offset)
        # Apply offset by slicing: skip the first db_offset rows
        result = result[db_offset:db_offset + db_limit]

        messages: List[ChatHistoryItem] = []
        for row in result:
            timestamp = str(row.get("timestamp", ""))
            row_id = str(row.get("id", ""))

            # Parse context_json for action_data and agent_type
            action_data = None
            agent_type = None
            if row.get("context_json"):
                try:
                    context = json.loads(row.get("context_json"))
                    # Extract nested action_data if present (for "Go to Workout" button)
                    action_data = context.get("action_data")
                    agent_type = context.get("agent_type")
                    if action_data:
                        logger.debug(f"Loaded action_data from history: {action_data.get('action')}")
                except Exception as e:
                    logger.warning(f"Failed to parse context_json: {e}")

            # Add user message
            if row.get("user_message"):
                messages.append(ChatHistoryItem(
                    id=f"{row_id}_user",  # Unique ID for user message
                    role="user",
                    content=row.get("user_message", ""),
                    timestamp=timestamp,
                    agent_type=None,
                    action_data=None,
                ))

            # Add assistant response
            if row.get("ai_response"):
                messages.append(ChatHistoryItem(
                    id=f"{row_id}_assistant",  # Unique ID for assistant message
                    role="assistant",
                    content=row.get("ai_response", ""),
                    timestamp=timestamp,
                    agent_type=agent_type,
                    action_data=action_data,
                ))

        logger.info(f"Returning {len(messages)} chat messages for user {user_id}")
        return messages
    except Exception as e:
        raise safe_internal_error(e, "get_chat_history")


class ExtractIntentRequest(BaseModel):
    """Request for intent extraction."""
    message: str


class ExtractIntentResponse(BaseModel):
    """Response from intent extraction."""
    intent: str
    exercises: List[str] = []
    muscleGroups: List[str] = []
    modification: Optional[str] = None
    bodyPart: Optional[str] = None


def get_gemini_service_dep() -> GeminiService:
    """Dependency to get Gemini service."""
    if gemini_service is None:
        raise HTTPException(status_code=503, detail="Gemini service not initialized")
    return gemini_service


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
}

# Size limits in bytes
MAX_IMAGE_SIZE = 10 * 1024 * 1024   # 10 MB
MAX_VIDEO_SIZE = 50 * 1024 * 1024   # 50 MB

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
}


class MediaPresignRequest(BaseModel):
    """Request body for generating a presigned S3 upload URL."""
    filename: str = Field(..., min_length=1, max_length=255, description="Original filename")
    content_type: str = Field(..., max_length=50, description="MIME type (e.g., 'video/mp4', 'image/jpeg')")
    media_type: str = Field(..., max_length=10, description="'image' or 'video'")
    expected_size_bytes: int = Field(..., gt=0, description="Expected file size in bytes")


class MediaPresignResponse(BaseModel):
    """Response with presigned S3 POST URL and fields."""
    presigned_url: str = Field(..., description="URL to POST the file to")
    presigned_fields: Dict[str, str] = Field(..., description="Form fields to include in the POST")
    s3_key: str = Field(..., description="S3 object key for referencing in ChatRequest.media_ref")
    expires_in: int = Field(..., description="Seconds until the presigned URL expires")


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
    max_size = MAX_VIDEO_SIZE if media_type == "video" else MAX_IMAGE_SIZE
    if expected_size_bytes > max_size:
        max_mb = max_size // (1024 * 1024)
        raise HTTPException(
            status_code=400,
            detail=f"{media_type.title()} too large. Maximum size: {max_mb}MB"
        )


def _generate_presigned_post(s3_client, bucket: str, s3_key: str, content_type: str, media_type: str) -> dict:
    """Generate a presigned S3 POST for a single file."""
    max_size = MAX_VIDEO_SIZE if media_type == "video" else MAX_IMAGE_SIZE
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

        return MediaPresignResponse(
            presigned_url=presigned["url"],
            presigned_fields=presigned["fields"],
            s3_key=s3_key,
            expires_in=PRESIGN_EXPIRY_SECONDS,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate presigned URL for user {user_id}: {e}")
        raise safe_internal_error(e, "media_presign")


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

            items.append(BatchPresignResponseItem(
                presigned_url=presigned["url"],
                presigned_fields=presigned["fields"],
                s3_key=s3_key,
                expires_in=PRESIGN_EXPIRY_SECONDS,
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
