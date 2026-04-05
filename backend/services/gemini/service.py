"""
Gemini Service - Main orchestrator class.

Assembles all domain-specific mixins into a single GeminiService class.
This is the only class that should be instantiated by the rest of the application.

Uses the new google-genai SDK (unified SDK for Gemini API).
"""
import asyncio
import logging
from typing import Optional

from core.config import get_settings

from services.gemini.cache_management import CacheManagementMixin
from services.gemini.prompts import PromptsMixin
from services.gemini.parsers import ParsersMixin
from services.gemini.chat import ChatMixin
from services.gemini.nutrition import NutritionMixin
from services.gemini.inflammation import InflammationMixin
from services.gemini.workout_naming import WorkoutNamingMixin
from services.gemini.workout_generation import WorkoutGenerationMixin
from services.gemini.workout_streaming import WorkoutStreamingMixin
from services.gemini.workout_summary import WorkoutSummaryMixin
from services.gemini.meal_plans import MealPlansMixin

settings = get_settings()
logger = logging.getLogger("gemini")


class GeminiService(
    CacheManagementMixin,
    PromptsMixin,
    ParsersMixin,
    ChatMixin,
    NutritionMixin,
    InflammationMixin,
    WorkoutNamingMixin,
    WorkoutGenerationMixin,
    WorkoutStreamingMixin,
    WorkoutSummaryMixin,
    MealPlansMixin,
):
    """
    Wrapper for Gemini API calls using the new google-genai SDK.

    Usage:
        service = GeminiService()
        response = await service.chat("Hello!")
    """

    # Class-level cache storage (shared across all instances)
    _workout_cache = None
    _workout_cache_created_at = None
    _cache_lock = None  # Will be initialized as asyncio.Lock()
    _form_analysis_cache: Optional[str] = None
    _form_analysis_cache_created_at = None
    _form_cache_lock = None  # Will be initialized as asyncio.Lock()
    _nutrition_analysis_cache: Optional[str] = None
    _nutrition_analysis_cache_created_at = None
    _nutrition_cache_lock = None  # Will be initialized as asyncio.Lock()
    _initialized = False

    def __init__(self):
        self.model = settings.gemini_model
        self.embedding_model = settings.gemini_embedding_model
        # Initialize the async locks if not already done
        if GeminiService._cache_lock is None:
            GeminiService._cache_lock = asyncio.Lock()
        if GeminiService._form_cache_lock is None:
            GeminiService._form_cache_lock = asyncio.Lock()
        if GeminiService._nutrition_cache_lock is None:
            GeminiService._nutrition_cache_lock = asyncio.Lock()


# Backward compatibility alias
OpenAIService = GeminiService


# Singleton instance for services that need it
_gemini_service_instance: Optional[GeminiService] = None


def get_gemini_service() -> GeminiService:
    """Get or create singleton GeminiService instance."""
    global _gemini_service_instance
    if _gemini_service_instance is None:
        _gemini_service_instance = GeminiService()
    return _gemini_service_instance


# Module-level singleton for backward compatibility
gemini_service = GeminiService()
