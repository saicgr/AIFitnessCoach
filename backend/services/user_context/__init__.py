"""
User Context Service Package
=============================
Re-exports the main service class and models for backwards compatibility.

All existing imports like:
    from services.user_context_service import UserContextService, EventType, user_context_service
will continue to work via the compatibility shim in user_context_service.py.
"""

from services.user_context.models import (
    EventType,
    LifetimeMemberContext,
    HormonalHealthContext,
    CardioPatterns,
    UserPatterns,
    NeatPatterns,
    SupersetPatterns,
    DiabetesPatterns,
)
from services.user_context.service import UserContextService

# Singleton instance
user_context_service = UserContextService()

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
