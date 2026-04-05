"""
Food Analysis package.

Splits the monolithic food_analysis_cache_service.py into:
- constants.py: Parsing constants, regexes, filler patterns
- modifiers.py: Food modifier data, metadata, classification, builder functions
- parser.py: ParsedFoodItem dataclass, parsing helper functions
- cache_service.py: FoodAnalysisCacheService class (core analysis + caching logic)

Re-exports the public API so existing imports keep working:
    from services.food_analysis_cache_service import (
        get_food_analysis_cache_service,
        _FOOD_MODIFIERS,
        _MODIFIER_METADATA,
        _classify_modifier,
        _build_default_modifiers,
        ModifierType,
    )
"""
from services.food_analysis.modifiers import (
    _FOOD_MODIFIERS,
    _MODIFIER_METADATA,
    _MODIFIER_GROUPS,
    _FOOD_DEFAULT_MODIFIER_GROUPS,
    ModifierType,
    ModifierMeta,
    _classify_modifier,
    _build_default_modifiers,
)
from services.food_analysis.parser import ParsedFoodItem
from services.food_analysis.cache_service import (
    FoodAnalysisCacheService,
    get_food_analysis_cache_service,
)

__all__ = [
    "FoodAnalysisCacheService",
    "get_food_analysis_cache_service",
    "ParsedFoodItem",
    "_FOOD_MODIFIERS",
    "_MODIFIER_METADATA",
    "_MODIFIER_GROUPS",
    "_FOOD_DEFAULT_MODIFIER_GROUPS",
    "ModifierType",
    "ModifierMeta",
    "_classify_modifier",
    "_build_default_modifiers",
]
