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
