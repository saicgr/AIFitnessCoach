"""
Chat API endpoints.

ENDPOINTS:
- POST /api/v1/chat/send - Send a message to the AI coach
- GET  /api/v1/chat/history/{user_id} - Get chat history for a user
- GET  /api/v1/chat/rag/stats - Get RAG system statistics
- POST /api/v1/chat/rag/search - Search similar past conversations

RATE LIMITS:
- /send: 10 requests/minute (AI-intensive)
- /extract-intent: 10 requests/minute (AI-intensive)
- /rag/search: 20 requests/minute
- /history: 30 requests/minute
"""
import json
import time
from fastapi import APIRouter, HTTPException, Depends, Request, BackgroundTasks, Query
from typing import List, Optional
from pydantic import BaseModel
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

    # Track response time for analytics
    start_time = time.time()

    try:
        response = await coach.process_message(chat_request)
        response_time_ms = int((time.time() - start_time) * 1000)
        logger.info(f"Chat response sent: intent={response.intent}, rag_used={response.rag_context_used}, time={response_time_ms}ms")

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
