"""
Health check endpoints.
"""
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
from typing import Optional
from core.config import get_settings
from core.logger import get_logger
from core.rate_limiter import limiter

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


class TestChatRequest(BaseModel):
    """Simple test request body."""
    user_id: str
    message: str


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
    """Debug endpoint to test the full chat flow including DB operations."""
    from services.langgraph_service import LangGraphCoachService
    from models.chat import ChatRequest
    from core.supabase_db import get_supabase_db
    from core.supabase_client import get_supabase
    from core.activity_logger import log_user_activity
    import traceback
    import json as json_lib
    import time

    result = {"steps": []}
    start_time = time.time()

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

        response_time_ms = int((time.time() - start_time) * 1000)

        # Test DB save (same as chat.py)
        result["steps"].append("7. Testing DB save...")
        try:
            db = get_supabase_db()
            context_dict = {
                "intent": response.intent.value if hasattr(response.intent, 'value') else str(response.intent),
                "agent_type": response.agent_type.value if hasattr(response.agent_type, 'value') else str(response.agent_type),
                "rag_context_used": response.rag_context_used,
            }
            chat_data = {
                "user_id": request.user_id,
                "user_message": request.message,
                "ai_response": response.message,
                "context_json": json_lib.dumps(context_dict) if response.intent else None,
            }
            db.create_chat_message(chat_data)
            result["steps"].append("8. DB save successful")
        except Exception as db_error:
            result["steps"].append(f"8. DB save failed (non-fatal): {db_error}")

        # Test analytics save
        result["steps"].append("9. Testing analytics save...")
        try:
            supabase = get_supabase().client
            analytics_data = {
                "user_id": request.user_id,
                "user_message_length": len(request.message),
                "ai_response_length": len(response.message),
                "coaching_style": "motivational",
                "communication_tone": "encouraging",
                "encouragement_level": 0.7,
                "response_length": "balanced",
                "use_emojis": True,
                "agent_type": response.agent_type.value if hasattr(response.agent_type, 'value') else str(response.agent_type),
                "intent": response.intent.value if hasattr(response.intent, 'value') else str(response.intent),
                "rag_context_used": response.rag_context_used or False,
                "response_time_ms": response_time_ms,
            }
            supabase.table("chat_interaction_analytics").insert(analytics_data).execute()
            result["steps"].append("10. Analytics save successful")
        except Exception as analytics_error:
            result["steps"].append(f"10. Analytics save failed (non-fatal): {analytics_error}")

        # Test activity logging
        result["steps"].append("11. Testing activity logging...")
        try:
            await log_user_activity(
                user_id=request.user_id,
                action="chat",
                endpoint="/api/v1/health/debug/chat",
                message=f"Debug test: {response.intent.value if hasattr(response.intent, 'value') else str(response.intent)}",
                metadata={
                    "intent": str(response.intent),
                    "agent_type": str(response.agent_type),
                    "rag_used": response.rag_context_used,
                },
                duration_ms=response_time_ms,
                status_code=200
            )
            result["steps"].append("12. Activity logging successful")
        except Exception as activity_error:
            result["steps"].append(f"12. Activity logging failed: {activity_error}")

        result["success"] = True
        result["intent"] = response.intent.value if hasattr(response.intent, 'value') else str(response.intent)
        result["agent_type"] = response.agent_type.value if hasattr(response.agent_type, 'value') else str(response.agent_type)
        result["message_preview"] = response.message[:100] if response.message else None
        result["response_time_ms"] = response_time_ms

    except Exception as e:
        result["success"] = False
        result["error"] = str(e)
        result["error_type"] = type(e).__name__
        result["traceback"] = traceback.format_exc()
        logger.error(f"Chat debug test failed: {e}", exc_info=True)

    return result


@router.post("/debug/chat-post")
@limiter.limit("10/minute")
async def debug_chat_post(request: TestChatRequest, http_request: Request):
    """
    Debug endpoint to test POST with rate limiter - mimics chat/send flow.
    This tests:
    1. POST request body parsing
    2. Rate limiter decorator
    3. Full chat flow
    """
    from models.chat import ChatRequest as FullChatRequest
    import traceback

    result = {"steps": [], "received": {"user_id": request.user_id, "message": request.message}}

    try:
        result["steps"].append("1. POST body received successfully")

        result["steps"].append("2. Creating full ChatRequest")
        full_request = FullChatRequest(
            user_id=request.user_id,
            message=request.message
        )
        result["steps"].append("3. ChatRequest created")

        result["steps"].append("4. Getting LangGraph service")
        from api.v1 import chat as chat_module
        if chat_module.langgraph_coach_service is None:
            result["error"] = "LangGraph service not initialized"
            return result
        result["steps"].append("5. Service found")

        result["steps"].append("6. Processing message...")
        response = await chat_module.langgraph_coach_service.process_message(full_request)
        result["steps"].append("7. Message processed successfully")

        result["success"] = True
        result["intent"] = response.intent.value if hasattr(response.intent, 'value') else str(response.intent)
        result["message_preview"] = response.message[:100] if response.message else None

    except Exception as e:
        result["success"] = False
        result["error"] = str(e)
        result["error_type"] = type(e).__name__
        result["traceback"] = traceback.format_exc()
        logger.error(f"POST chat debug failed: {e}", exc_info=True)

    return result


@router.post("/debug/echo")
async def debug_echo(request: TestChatRequest):
    """Simple POST echo endpoint - no rate limiter, no AI call."""
    return {"echo": True, "user_id": request.user_id, "message": request.message}


@router.post("/debug/echo-limited")
@limiter.limit("10/minute")
async def debug_echo_limited(request: TestChatRequest, http_request: Request):
    """Simple POST echo endpoint WITH rate limiter."""
    return {"echo": True, "rate_limited": True, "user_id": request.user_id, "message": request.message}
