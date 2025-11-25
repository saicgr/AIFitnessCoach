"""
Chat API endpoints.

ENDPOINTS:
- POST /api/v1/chat/send - Send a message to the AI coach
- GET  /api/v1/chat/rag/stats - Get RAG system statistics
- POST /api/v1/chat/rag/search - Search similar past conversations
"""
from fastapi import APIRouter, HTTPException, Depends
from typing import List, Optional
from pydantic import BaseModel
from models.chat import ChatRequest, ChatResponse
from services.openai_service import OpenAIService
from services.rag_service import RAGService
from services.langgraph_service import LangGraphCoachService
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)

# Service instances (will be initialized on startup)
openai_service: Optional[OpenAIService] = None
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
async def send_message(
    request: ChatRequest,
    coach: LangGraphCoachService = Depends(get_coach_service),
):
    """
    Send a message to the AI fitness coach.

    This endpoint:
    1. Extracts intent from the message
    2. Retrieves similar past conversations (RAG)
    3. Generates an AI response with context
    4. Stores the Q&A for future RAG
    5. Returns action data for workout modifications
    """
    logger.info(f"Chat request from user {request.user_id}: {request.message[:50]}...")
    if request.current_workout:
        logger.debug(f"Current workout: {request.current_workout.name} (id={request.current_workout.id})")
    if request.workout_schedule:
        logger.debug(f"Workout schedule: yesterday={request.workout_schedule.yesterday is not None}, today={request.workout_schedule.today is not None}, tomorrow={request.workout_schedule.tomorrow is not None}, thisWeek={len(request.workout_schedule.thisWeek)}")

    try:
        response = await coach.process_message(request)
        logger.info(f"Chat response sent: intent={response.intent}, rag_used={response.rag_context_used}")
        return response
    except Exception as e:
        logger.error(f"Failed to process message: {e}")
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


def get_openai_service() -> OpenAIService:
    """Dependency to get OpenAI service."""
    if openai_service is None:
        raise HTTPException(status_code=503, detail="OpenAI service not initialized")
    return openai_service


@router.post("/extract-intent", response_model=ExtractIntentResponse)
async def extract_intent(
    request: ExtractIntentRequest,
    openai: OpenAIService = Depends(get_openai_service),
):
    """
    Extract intent and structured data from a user message.
    """
    logger.debug(f"Extracting intent from: {request.message[:50]}...")
    try:
        extraction = await openai.extract_intent(request.message)
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
    user_id: Optional[int] = None


class RAGSearchResult(BaseModel):
    """Single RAG search result."""
    question: str
    answer: str
    intent: str
    similarity: float


@router.post("/rag/search", response_model=List[RAGSearchResult])
async def search_similar(
    request: RAGSearchRequest,
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
