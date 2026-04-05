"""
Nutrition database operations.

Handles all nutrition-related CRUD operations including:
- Food log management
- Daily and weekly nutrition summaries
- User nutrition targets
- Food analysis caching (for faster AI responses)
"""

from .nutrition_db_helpers import (  # noqa: F401
    NutritionDB,
)
import hashlib
import logging
import re
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta

from core.db.base import BaseDB

logger = logging.getLogger(__name__)


