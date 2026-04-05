"""
Gemini Service - Backward compatibility shim.

This file re-exports all public names from the `services.gemini` package
so that existing imports like `from services.gemini_service import GeminiService`
continue to work unchanged.

The actual implementation has been split into:
    services/gemini/constants.py       - Caches, cost tracker, token logging
    services/gemini/utils.py           - Shared helpers (sanitize, equipment rules, set validation)
    services/gemini/cache_management.py - Vertex AI context cache lifecycle
    services/gemini/prompts.py         - Form analysis & nutrition cache content builders
    services/gemini/parsers.py         - JSON extraction, weight parsing, USDA lookup
    services/gemini/chat.py            - Chat, intent extraction, embeddings
    services/gemini/nutrition.py       - Food image/text analysis
    services/gemini/inflammation.py    - Ingredient inflammation analysis
    services/gemini/workout_naming.py  - Holiday themes, workout name generation
    services/gemini/workout_generation.py - Core workout plan generation
    services/gemini/workout_streaming.py  - Streaming workout generation
    services/gemini/workout_summary.py - Workout summary & exercise reasoning
    services/gemini/meal_plans.py      - Meal planning, agent personality, coach prompts
    services/gemini/hormonal.py        - Hormonal health prompts
    services/gemini/service.py         - Main GeminiService class (assembles all mixins)
"""

# Re-export everything from the gemini package for backward compatibility
from services.gemini import (  # noqa: F401
    GeminiService,
    OpenAIService,
    get_gemini_service,
    gemini_service,
    ResponseCache,
    _gemini_semaphore,
    cost_tracker,
    _log_token_usage,
    validate_set_targets_strict,
    ensure_set_targets,
    safe_join_list,
    _sanitize_for_prompt,
    _build_equipment_usage_rule,
    infer_set_type,
    HormonalHealthPrompts,
)
