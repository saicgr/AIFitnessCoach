"""
Gemini Service Package - Re-exports for backward compatibility.

All imports that previously came from `services.gemini_service` now come
from this package. The old `gemini_service.py` module is replaced by a
thin shim that imports from here.
"""
from services.gemini.service import (
    GeminiService,
    OpenAIService,
    get_gemini_service,
    gemini_service,
)
from services.gemini.constants import (
    ResponseCache,
    _gemini_semaphore,
    cost_tracker,
    _log_token_usage,
)
from services.gemini.utils import (
    validate_set_targets_strict,
    ensure_set_targets,
    safe_join_list,
    _sanitize_for_prompt,
    _build_equipment_usage_rule,
    infer_set_type,
)
from services.gemini.hormonal import HormonalHealthPrompts

__all__ = [
    "GeminiService",
    "OpenAIService",
    "get_gemini_service",
    "gemini_service",
    "ResponseCache",
    "_gemini_semaphore",
    "cost_tracker",
    "_log_token_usage",
    "validate_set_targets_strict",
    "ensure_set_targets",
    "safe_join_list",
    "_sanitize_for_prompt",
    "_build_equipment_usage_rule",
    "infer_set_type",
    "HormonalHealthPrompts",
]
