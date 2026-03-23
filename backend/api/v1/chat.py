"""
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
"""
import asyncio
import json
import time
import uuid
from fastapi import APIRouter, HTTPException, Depends, Request, BackgroundTasks, Query, UploadFile, File, Form
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from models.chat import ChatRequest, ChatResponse
from services.gemini_service import GeminiService
from services.rag_service import RAGService
from services.langgraph_service import LangGraphCoachService
from core.logger import get_logger, set_log_context
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


def _chat_send_key(request: Request) -> str:
    """Shared rate limit key for /send and /send-stream endpoints.

    Both endpoints count against the same bucket so a user cannot
    bypass the limit by alternating between them.
    """
    # Try to extract user_id from the auth dependency state
    user = getattr(request.state, "user", None) if hasattr(request, "state") else None
    if user and isinstance(user, dict):
        uid = user.get("id")
        if uid:
            return f"chat_send:{uid}"
    # Fall back to IP
    if request.client and request.client.host:
        return f"chat_send:{request.client.host}"
    return "chat_send:127.0.0.1"


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


def _save_chat_to_db(user_id: str, message: str, response_message: str, response_intent, response_agent_type, response_rag_context_used: bool, response_action_data, coach_persona_id: Optional[str] = None, media_url: Optional[str] = None, media_type: Optional[str] = None):
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
        if coach_persona_id:
            context_dict["coach_persona_id"] = coach_persona_id

        chat_data = {
            "user_id": user_id,
            "user_message": message,
            "ai_response": response_message,
            "context_json": json.dumps(context_dict) if response_intent else None,
        }
        if media_url:
            chat_data["media_url"] = media_url
        if media_type:
            chat_data["media_type"] = media_type
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


async def _retry_task(fn, *args, max_retries=3, task_name=""):
    """Retry a background task with exponential backoff. Handles both sync and async callables."""
    for attempt in range(max_retries):
        try:
            if asyncio.iscoroutinefunction(fn):
                await fn(*args)
            else:
                fn(*args)
            return
        except Exception as e:
            wait = 2 ** attempt
            logger.warning(f"[Background] {task_name} attempt {attempt + 1} failed: {e}, retrying in {wait}s")
            await asyncio.sleep(wait)
    logger.error(f"[Background] {task_name} failed after {max_retries} attempts")


@router.post("/send", response_model=ChatResponse)
@limiter.limit("10/minute", key_func=_chat_send_key)
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

    # Per-user daily AI chat budget (free: 10/day, premium: unlimited)
    from core.premium_gate import check_premium_gate, track_premium_usage
    await check_premium_gate(chat_request.user_id, "ai_chat")

    # Premium gate checks for food scanning and text-to-calories
    # Only check gates when the request actually involves these features
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
        background_tasks.add_task(track_premium_usage, chat_request.user_id, "ai_chat")
        if _chat_gate_feature:
            background_tasks.add_task(track_premium_usage, chat_request.user_id, _chat_gate_feature)

        # Move DB writes to background tasks with retry - these don't block the response.
        # Chat history is only read on subsequent requests (GET /history), not in this flow.
        _coach_persona_id = chat_request.ai_settings.coach_persona_id if chat_request.ai_settings else None
        # Derive media_type for persistence: image_base64 means image; media_ref carries its own media_type
        _media_url = chat_request.media_url
        _media_type: Optional[str] = None
        if chat_request.image_base64:
            _media_type = "image"
        elif chat_request.media_ref:
            _media_type = chat_request.media_ref.media_type
        elif chat_request.media_refs:
            _media_type = chat_request.media_refs[0].media_type
        background_tasks.add_task(
            _retry_task,
            _save_chat_to_db,
            chat_request.user_id,
            chat_request.message,
            response.message,
            response.intent,
            response.agent_type,
            response.rag_context_used,
            response.action_data,
            _coach_persona_id,
            _media_url,
            _media_type,
            task_name="save_chat_to_db",
        )

        background_tasks.add_task(
            _retry_task,
            _save_chat_analytics,
            chat_request.user_id,
            chat_request.message,
            response.message,
            response.intent,
            response.agent_type,
            response.rag_context_used,
            response_time_ms,
            chat_request.ai_settings,
            task_name="save_chat_analytics",
        )

        background_tasks.add_task(
            _retry_task,
            _log_chat_activity,
            chat_request.user_id,
            response.intent,
            response.agent_type,
            response.rag_context_used,
            response_time_ms,
            task_name="log_chat_activity",
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
    is_pinned: bool = False
    audio_url: Optional[str] = None
    audio_duration_ms: Optional[int] = None
    coach_persona_id: Optional[str] = None  # Which coach persona sent this message
    media_url: Optional[str] = None  # Public S3 URL for image/video messages
    media_type: Optional[str] = None  # 'image' or 'video'


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
        result = db.list_chat_history(user_id, limit=db_limit, offset=db_offset)

        messages: List[ChatHistoryItem] = []
        for row in result:
            timestamp = str(row.get("timestamp", ""))
            row_id = str(row.get("id", ""))

            # Parse context_json for action_data, agent_type, and coach_persona_id
            action_data = None
            agent_type = None
            coach_persona_id = None
            if row.get("context_json"):
                try:
                    context = json.loads(row.get("context_json"))
                    # Extract nested action_data if present (for "Go to Workout" button)
                    action_data = context.get("action_data")
                    agent_type = context.get("agent_type")
                    coach_persona_id = context.get("coach_persona_id")
                    if action_data:
                        logger.debug(f"Loaded action_data from history: {action_data.get('action')}")
                except Exception as e:
                    logger.warning(f"Failed to parse context_json: {e}")

            is_pinned = row.get("is_pinned", False)
            audio_url = row.get("audio_url")
            audio_duration_ms = row.get("audio_duration_ms")
            media_url = row.get("media_url")
            media_type = row.get("media_type")

            # Add user message
            if row.get("user_message"):
                messages.append(ChatHistoryItem(
                    id=f"{row_id}_user",  # Unique ID for user message
                    role="user",
                    content=row.get("user_message", ""),
                    timestamp=timestamp,
                    agent_type=None,
                    action_data=None,
                    is_pinned=is_pinned,
                    audio_url=audio_url,
                    audio_duration_ms=audio_duration_ms,
                    media_url=media_url,
                    media_type=media_type,
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
                    is_pinned=is_pinned,
                    coach_persona_id=coach_persona_id,
                ))

        logger.info(f"Returning {len(messages)} chat messages for user {user_id}")
        return messages
    except Exception as e:
        raise safe_internal_error(e, "get_chat_history")


@router.delete("/messages/{message_id}")
@limiter.limit("10/minute")
async def delete_message(
    request: Request,
    message_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a single chat message by ID. Only the owning user can delete."""
    db = get_supabase_db()
    deleted = db.delete_chat_message(message_id, current_user["id"])
    if not deleted:
        raise HTTPException(status_code=404, detail="Message not found")
    return {"status": "deleted"}


class PinToggleRequest(BaseModel):
    """Request body for toggling pin status on a chat message."""
    is_pinned: bool


@router.patch("/messages/{message_id}/pin")
@limiter.limit("10/minute")
async def toggle_message_pin(
    request: Request,
    message_id: str,
    body: PinToggleRequest,
    current_user: dict = Depends(get_current_user),
):
    """Toggle pin status on a chat message."""
    user_id = str(current_user["id"])
    try:
        db = get_supabase_db()
        db.toggle_chat_message_pin(message_id, user_id, body.is_pinned)
        return {"status": "ok", "message_id": message_id, "is_pinned": body.is_pinned}
    except Exception as e:
        logger.error(f"Failed to toggle pin for message {message_id}: {e}")
        raise safe_internal_error(e, "toggle_pin")


@router.delete("/history/{user_id}")
@limiter.limit("3/minute")
async def clear_chat_history(
    request: Request,
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Clear all chat history for a user."""
    auth_user_id = str(current_user["id"])
    # Ensure user can only clear their own history
    if auth_user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to clear this user's history")

    try:
        db = get_supabase_db()
        db.clear_chat_history(user_id)
        return {"status": "ok", "message": "Chat history cleared"}
    except Exception as e:
        logger.error(f"Failed to clear chat history for user {user_id}: {e}")
        raise safe_internal_error(e, "clear_chat_history")


class ChatSearchRequest(BaseModel):
    """Request body for chat history search."""
    query: str = Field(..., min_length=1, max_length=200)
    limit: int = Field(default=20, ge=1, le=50)


@router.post("/search")
@limiter.limit("10/minute")
async def search_chat(
    request: Request,
    body: ChatSearchRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Search chat history for the current user.

    Returns matching messages in the same ChatHistoryItem format as /history.
    """
    user_id = str(current_user["id"])
    try:
        db = get_supabase_db()
        result = db.search_chat_history(user_id, body.query, body.limit)

        messages: List[ChatHistoryItem] = []
        for row in result:
            timestamp = str(row.get("timestamp", ""))
            row_id = str(row.get("id", ""))

            action_data = None
            agent_type = None
            if row.get("context_json"):
                try:
                    context = json.loads(row.get("context_json"))
                    action_data = context.get("action_data")
                    agent_type = context.get("agent_type")
                except Exception:
                    pass

            if row.get("user_message"):
                messages.append(ChatHistoryItem(
                    id=f"{row_id}_user",
                    role="user",
                    content=row.get("user_message", ""),
                    timestamp=timestamp,
                    agent_type=None,
                    action_data=None,
                ))

            if row.get("ai_response"):
                messages.append(ChatHistoryItem(
                    id=f"{row_id}_assistant",
                    role="assistant",
                    content=row.get("ai_response", ""),
                    timestamp=timestamp,
                    agent_type=agent_type,
                    action_data=action_data,
                ))

        return messages
    except Exception as e:
        raise safe_internal_error(e, "search_chat")


@router.post("/send-stream")
@limiter.limit("10/minute", key_func=_chat_send_key)
async def send_message_stream(
    request: Request,
    chat_request: ChatRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
    coach: LangGraphCoachService = Depends(get_coach_service),
):
    """
    Send a message to the AI fitness coach with Server-Sent Events streaming.

    Streams the response in chunks:
    1. {"event": "start", "agent": "coach"}
    2. {"event": "token", "text": "..."} (20-word chunks)
    3. {"event": "done", "action_data": {...}}
    """
    if str(current_user["id"]) != str(chat_request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    # Per-user daily AI chat budget (free: 10/day, premium: unlimited)
    from core.premium_gate import check_premium_gate, track_premium_usage
    await check_premium_gate(chat_request.user_id, "ai_chat")

    from starlette.responses import StreamingResponse

    async def _stream_response():
        start_time = time.time()
        yield f"data: {json.dumps({'event': 'start', 'agent': 'coach'})}\n\n"

        try:
            response = await coach.process_message(chat_request)
            response_time_ms = int((time.time() - start_time) * 1000)

            # Chunk the response text into ~20-word segments
            words = response.message.split()
            for i in range(0, len(words), 20):
                chunk = ' '.join(words[i:i + 20])
                yield f"data: {json.dumps({'event': 'token', 'text': chunk})}\n\n"

            yield f"data: {json.dumps({'event': 'done', 'action_data': response.action_data})}\n\n"

            # Track AI chat usage for daily budget
            background_tasks.add_task(track_premium_usage, chat_request.user_id, "ai_chat")

            # Schedule background tasks for DB persistence
            _stream_coach_persona_id = chat_request.ai_settings.coach_persona_id if chat_request.ai_settings else None
            background_tasks.add_task(
                _retry_task,
                _save_chat_to_db,
                chat_request.user_id,
                chat_request.message,
                response.message,
                response.intent,
                response.agent_type,
                response.rag_context_used,
                response.action_data,
                _stream_coach_persona_id,
                task_name="save_chat_to_db",
            )
            background_tasks.add_task(
                _retry_task,
                _save_chat_analytics,
                chat_request.user_id,
                chat_request.message,
                response.message,
                response.intent,
                response.agent_type,
                response.rag_context_used,
                response_time_ms,
                chat_request.ai_settings,
                task_name="save_chat_analytics",
            )
            background_tasks.add_task(
                _retry_task,
                _log_chat_activity,
                chat_request.user_id,
                response.intent,
                response.agent_type,
                response.rag_context_used,
                response_time_ms,
                task_name="log_chat_activity",
            )
        except Exception as e:
            logger.error(f"Streaming error: {e}")
            yield f"data: {json.dumps({'event': 'error', 'message': str(e)})}\n\n"

    return StreamingResponse(
        _stream_response(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


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
