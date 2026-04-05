"""
Gemini Service Workout Generation - Core workout plan generation.
"""

from .workout_generation_helpers import (  # noqa: F401
    WorkoutGenerationMixin,
)
import asyncio
import json
import logging
import time
import re
import hashlib
from typing import List, Dict, Optional
from datetime import datetime

from google.genai import types
from core.config import get_settings
from core.anonymize import age_to_bracket
from models.gemini_schemas import (
    GeneratedWorkoutResponse,
    WorkoutNamesResponse,
    WorkoutNamingResponse,
)
from services.split_descriptions import SPLIT_DESCRIPTIONS, get_split_context
from services.gemini.constants import (
    client, cost_tracker, _log_token_usage, _gemini_semaphore, settings,
)
from services.gemini.utils import (
    _sanitize_for_prompt, safe_join_list,
    _build_equipment_usage_rule, validate_set_targets_strict,
)

logger = logging.getLogger("gemini")


