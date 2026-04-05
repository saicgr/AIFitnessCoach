"""
Food Analysis Caching Service.

Wraps Gemini food analysis with intelligent caching to dramatically
reduce response times for repeated queries.

Cache Strategy:
0a. Saved Foods - User's personal saved meals (instant, user-scoped)
0b. Food Nutrition Overrides - 6,949 curated items (instant)
1. Common Foods DB - Instant lookup (bypasses AI entirely)
1b. Multi-item lookup (overrides + common foods)
1c. Modified override (base item + modifiers like "extra patty", "no cheese")
2. Food Analysis Cache - Cached AI responses (~100ms)
3. Gemini AI - Fresh analysis (30-90s)

Expected Performance:
- Saved food / override hit: < 10ms
- Common food: < 1 second
- Cache hit: < 2 seconds
- Cache miss (first time): 30-60 seconds
"""

from .cache_service_helpers import (  # noqa: F401
    FoodAnalysisCacheService,
    get_food_analysis_cache_service,
)
import asyncio
import hashlib
import json
import logging
import re
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List, Tuple

from sqlalchemy import text

from core.db.facade import get_supabase_db
from core.db.nutrition_db import NutritionDB
from core.supabase_client import get_supabase
from services.food_database_lookup_service import get_food_db_lookup_service
from services.gemini_service import GeminiService
from core.redis_cache import RedisCache

from services.food_analysis.constants import (
    _WORD_NUMBERS,
    _COUNT_UNITS,
    _WEIGHT_REGEX,
    _WEIGHT_AFTER_REGEX,
    _VOLUME_REGEX,
    _VOLUME_AFTER_REGEX,
    _FILLER_REGEX,
)
from services.food_analysis.parser import (
    ParsedFoodItem,
    _weight_unit_to_grams,
    _volume_unit_to_ml,
)
from services.food_analysis.modifiers import (
    _FOOD_MODIFIERS,
    _MODIFIER_METADATA,
    _MODIFIER_GROUPS,
    _FOOD_DEFAULT_MODIFIER_GROUPS,
    ModifierType,
    ModifierMeta,
    _classify_modifier,
    _build_default_modifiers,
    _MODIFIER_PHRASES_SORTED,
    _MODIFIER_REGEX,
    _BULLET_REGEX,
    _NUM_UNIT_REGEX,
    _WORD_NUM_UNIT_REGEX,
    _BARE_NUM_REGEX,
    _FRACTION_REGEX,
)

logger = logging.getLogger(__name__)

_food_analysis_cache = RedisCache(prefix="food_analysis", ttl_seconds=86400, max_size=200)

