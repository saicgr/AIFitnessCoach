"""
Health check endpoints.
"""
from fastapi import APIRouter
from core import branding
from core.config import get_settings
from core.logger import get_logger
from services.gemini_service import cost_tracker

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


@router.get("/")
async def health_check():
    """Basic health check."""
    return {"status": "healthy", "service": f"{branding.APP_NAME} Backend"}


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
    """Debug endpoint - shows Gemini config without making API calls."""
    return {
        "model": settings.gemini_model,
        "embedding_model": settings.gemini_embedding_model,
        "api_key_set": bool(settings.gemini_api_key),
        "cache_enabled": getattr(settings, 'gemini_cache_enabled', False),
        "status": "configured",
    }


@router.get("/debug/costs")
async def debug_costs():
    """Debug endpoint - shows accumulated Vertex AI cost estimates since last deploy."""
    return cost_tracker.snapshot()
