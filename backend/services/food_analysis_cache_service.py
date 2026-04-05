"""
Food Analysis Caching Service - backward compatibility shim.

This module has been refactored into the services.food_analysis package:
- services/food_analysis/constants.py  - Parsing constants, regexes
- services/food_analysis/modifiers.py  - Modifier data, metadata, classification
- services/food_analysis/parser.py     - ParsedFoodItem, unit converters
- services/food_analysis/cache_service.py - FoodAnalysisCacheService class

All public names are re-exported here so existing imports continue to work.
"""
from services.food_analysis import (
    FoodAnalysisCacheService,
    get_food_analysis_cache_service,
    ParsedFoodItem,
    _FOOD_MODIFIERS,
    _MODIFIER_METADATA,
    _MODIFIER_GROUPS,
    _FOOD_DEFAULT_MODIFIER_GROUPS,
    ModifierType,
    ModifierMeta,
    _classify_modifier,
    _build_default_modifiers,
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
