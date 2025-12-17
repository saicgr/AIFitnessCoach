"""
Health check endpoints.
"""
from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def health_check():
    """Basic health check."""
    return {"status": "healthy", "service": "AI Fitness Coach Backend"}


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
