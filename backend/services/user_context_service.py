"""
User Context Service - Backwards Compatibility Shim
====================================================
This file re-exports from the new user_context package so all existing
imports continue to work without modification.

Original module has been refactored into:
    services/user_context/__init__.py
    services/user_context/models.py
    services/user_context/service.py
    services/user_context/event_logging.py
    services/user_context/trial_logging.py
    services/user_context/feature_logging.py
    services/user_context/neat_logging.py
    services/user_context/health_logging.py
    services/user_context/nutrition_logging.py
    services/user_context/watch_logging.py
"""

# Re-export everything for backwards compatibility
from services.user_context import (  # noqa: F401
    UserContextService,
    user_context_service,
    EventType,
    LifetimeMemberContext,
    HormonalHealthContext,
    CardioPatterns,
    UserPatterns,
    NeatPatterns,
    SupersetPatterns,
    DiabetesPatterns,
)

__all__ = [
    "UserContextService",
    "user_context_service",
    "EventType",
    "LifetimeMemberContext",
    "HormonalHealthContext",
    "CardioPatterns",
    "UserPatterns",
    "NeatPatterns",
    "SupersetPatterns",
    "DiabetesPatterns",
]
