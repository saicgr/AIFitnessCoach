"""
Food Database Lookup Service.

Search architecture:
  1. food_nutrition_overrides — hand-curated premium (200K+ items, DB-queried)
  2. If no match → caller uses AI text analysis (Gemini)

Provides single and batch food lookups with in-memory TTL caching.
"""

from .food_database_lookup_service_helpers import (  # noqa: F401
    FoodDatabaseLookupService,
    get_food_db_lookup_service,
)

import asyncio
import re
import time
from typing import Optional, Dict, List

from sqlalchemy import text

from core.logger import get_logger
from core.supabase_client import get_supabase
logger = get_logger(__name__)


