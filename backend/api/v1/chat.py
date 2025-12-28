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
from fastapi import APIRouter, HTTPException, Depends, Request
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


@router.post("/send", response_model=ChatResponse)
@limiter.limit("10/minute")
async def send_message(
    request: ChatRequest,
    http_request: Request,
    coach: LangGraphCoachService = Depends(get_coach_service),
):
    """
    Send a message to the AI fitness coach.

    This endpoint:
    1. Extracts intent from the message
    2. Retrieves similar past conversations (RAG)
    3. Generates an AI response with context
    4. Stores the Q&A for future RAG
    5. Records analytics with AI settings snapshot
    6. Returns action data for workout modifications
    """
    logger.info(f"Chat request from user {request.user_id}: {request.message[:50]}...")
    if request.current_workout:
        logger.debug(f"Current workout: {request.current_workout.name} (id={request.current_workout.id})")
    if request.workout_schedule:
        logger.debug(f"Workout schedule: yesterday={request.workout_schedule.yesterday is not None}, today={request.workout_schedule.today is not None}, tomorrow={request.workout_schedule.tomorrow is not None}, thisWeek={len(request.workout_schedule.thisWeek)}")

    # Track response time for analytics
    start_time = time.time()

    try:
        response = await coach.process_message(request)
        response_time_ms = int((time.time() - start_time) * 1000)
        logger.info(f"Chat response sent: intent={response.intent}, rag_used={response.rag_context_used}, time={response_time_ms}ms")

        # Save chat message to database for persistence
        # The chat_history table stores user_message + ai_response per row
        try:
            db = get_supabase_db()
            chat_data = {
                "user_id": request.user_id,
                "user_message": request.message,
                "ai_response": response.message,
                "context_json": json.dumps({
                    "intent": response.intent.value if hasattr(response.intent, 'value') else str(response.intent),
                    "agent_type": response.agent_type.value if hasattr(response.agent_type, 'value') else str(response.agent_type),
                    "rag_context_used": response.rag_context_used,
                }) if response.intent else None,
            }
            db.create_chat_message(chat_data)
            logger.debug(f"Chat message saved to database for user {request.user_id}, intent={response.intent}, agent={response.agent_type}")
        except Exception as db_error:
            # Log but don't fail the request if DB save fails
            logger.warning(f"Failed to save chat to database: {db_error}")

        # Record chat interaction analytics with AI settings snapshot
        try:
            supabase = get_supabase().client
            ai_settings = request.ai_settings

            analytics_data = {
                "user_id": request.user_id,
                "user_message_length": len(request.message),
                "ai_response_length": len(response.message),
                "coaching_style": ai_settings.coaching_style if ai_settings else "motivational",
                "communication_tone": ai_settings.communication_tone if ai_settings else "encouraging",
                "encouragement_level": ai_settings.encouragement_level if ai_settings else 0.7,
                "response_length": ai_settings.response_length if ai_settings else "balanced",
                "use_emojis": ai_settings.use_emojis if ai_settings else True,
                "agent_type": response.agent_type.value if hasattr(response.agent_type, 'value') else str(response.agent_type),
                "intent": response.intent.value if hasattr(response.intent, 'value') else str(response.intent),
                "rag_context_used": response.rag_context_used or False,
                "response_time_ms": response_time_ms,
            }
            supabase.table("chat_interaction_analytics").insert(analytics_data).execute()
            logger.debug(f"Chat analytics recorded for user {request.user_id}")
        except Exception as analytics_error:
            # Log but don't fail the request if analytics save fails
            logger.warning(f"Failed to save chat analytics: {analytics_error}")

        return response
    except Exception as e:
        logger.error(f"Failed to process message: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
async def get_chat_history(request: Request, user_id: str, limit: int = 100):
    """
    Get chat history for a user.

    Returns messages in chronological order (oldest first).
    Each row in DB contains user_message + ai_response, so we expand to 2 messages.
    """
    logger.info(f"Fetching chat history for user {user_id}, limit={limit}")
    try:
        db = get_supabase_db()
        # Limit divided by 2 since each row becomes 2 messages
        result = db.list_chat_history(user_id, limit=(limit + 1) // 2)

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
                    action_data = context
                    agent_type = context.get("agent_type")
                except:
                    pass

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
        logger.error(f"Failed to fetch chat history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
    request: ExtractIntentRequest,
    http_request: Request,
    gemini: GeminiService = Depends(get_gemini_service_dep),
):
    """
    Extract intent and structured data from a user message.
    """
    logger.debug(f"Extracting intent from: {request.message[:50]}...")
    try:
        extraction = await gemini.extract_intent(request.message)
        logger.debug(f"Intent extracted: {extraction.intent.value}")
        return ExtractIntentResponse(
            intent=extraction.intent.value,
            exercises=extraction.exercises,
            muscleGroups=extraction.muscle_groups,
            modification=extraction.modification if extraction.modification else None,
            bodyPart=extraction.body_part if extraction.body_part else None,
        )
    except Exception as e:
        logger.error(f"Failed to extract intent: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
    request: RAGSearchRequest,
    http_request: Request,
    rag: RAGService = Depends(get_rag_service),
):
    """
    Search for similar past conversations in RAG system.
    """
    logger.debug(f"RAG search: {request.query[:50]}...")
    try:
        results = await rag.find_similar(
            query=request.query,
            n_results=request.n_results,
            user_id=request.user_id,
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
        logger.error(f"RAG search failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/rag/stats")
async def get_rag_stats(rag: RAGService = Depends(get_rag_service)):
    """Get RAG system statistics."""
    return rag.get_stats()


@router.delete("/rag/clear")
async def clear_rag(rag: RAGService = Depends(get_rag_service)):
    """Clear all RAG data. USE WITH CAUTION!"""
    logger.warning("Clearing all RAG data")
    await rag.clear_all()
    return {"status": "cleared", "message": "All RAG data has been deleted"}
