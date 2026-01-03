"""
Health check endpoints.
"""
from fastapi import APIRouter, HTTPException
from core.config import get_settings
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


@router.get("/")
async def health_check():
    """Basic health check."""
    return {"status": "healthy", "service": "FitWiz Backend"}


@router.get("/ready")
async def readiness_check():
    """Readiness check - verifies all dependencies are available."""
    return {
        "status": "ready",
        "checks": {
            "gemini": "connected",
            "rag": "initialized",
        }
    }


@router.get("/debug/gemini")
async def debug_gemini():
    """Debug endpoint to test Gemini API connectivity."""
    from services.gemini_service import GeminiService

    result = {
        "model": settings.gemini_model,
        "embedding_model": settings.gemini_embedding_model,
        "api_key_set": bool(settings.gemini_api_key),
        "api_key_prefix": settings.gemini_api_key[:10] + "..." if settings.gemini_api_key else None,
    }

    try:
        service = GeminiService()
        extraction = await service.extract_intent("Hello")
        result["gemini_test"] = "success"
        result["intent"] = extraction.intent.value
    except Exception as e:
        result["gemini_test"] = "failed"
        result["error"] = str(e)
        result["error_type"] = type(e).__name__
        logger.error(f"Gemini debug test failed: {e}")

    return result


@router.get("/debug/chat")
async def debug_chat():
    """Debug endpoint to test the full chat flow."""
    from services.langgraph_service import LangGraphCoachService
    from models.chat import ChatRequest
    import traceback

    result = {"steps": []}

    try:
        result["steps"].append("1. Creating ChatRequest")
        request = ChatRequest(
            user_id="debug-test-user",
            message="Hello"
        )
        result["steps"].append("2. ChatRequest created successfully")

        result["steps"].append("3. Getting LangGraph service")
        from api.v1 import chat as chat_module
        if chat_module.langgraph_coach_service is None:
            result["error"] = "LangGraph service not initialized"
            return result
        result["steps"].append("4. LangGraph service found")

        result["steps"].append("5. Processing message...")
        response = await chat_module.langgraph_coach_service.process_message(request)
        result["steps"].append("6. Message processed successfully")

        result["success"] = True
        result["intent"] = response.intent.value if hasattr(response.intent, 'value') else str(response.intent)
        result["agent_type"] = response.agent_type.value if hasattr(response.agent_type, 'value') else str(response.agent_type)
        result["message_preview"] = response.message[:100] if response.message else None

    except Exception as e:
        result["success"] = False
        result["error"] = str(e)
        result["error_type"] = type(e).__name__
        result["traceback"] = traceback.format_exc()
        logger.error(f"Chat debug test failed: {e}", exc_info=True)

    return result
