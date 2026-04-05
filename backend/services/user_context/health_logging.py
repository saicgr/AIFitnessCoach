"""
Health Logging Mixin
====================
Injury tracking, strain prevention, senior fitness, progression pace,
diabetes tracking, and hormonal health event logging and analytics.
"""

from .health_logging_helpers import (  # noqa: F401
    HealthLoggingMixin,
)

from collections import Counter
from datetime import datetime, timedelta, date
from typing import Optional, List, Dict, Any
import logging

from core.db import get_supabase_db
from services.user_context.models import (
    EventType,
    DiabetesPatterns,
    HormonalHealthContext,
)

logger = logging.getLogger(__name__)


