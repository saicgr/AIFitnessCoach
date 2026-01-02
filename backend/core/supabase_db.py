"""
Supabase Database Service for FitWiz.

This module provides backward compatibility by re-exporting from the
modular database package. New code should import directly from core.db.

Usage (backward compatible):
    from core.supabase_db import get_supabase_db

    db = get_supabase_db()
    user = db.get_user(user_id="...")

Usage (new recommended):
    from core.db import get_supabase_db

    db = get_supabase_db()
    user = db.get_user(user_id="...")
"""

# Re-export everything from the modular database package
from core.db.facade import SupabaseDB, get_supabase_db

# Also export individual modules for direct access if needed
from core.db.user_db import UserDB
from core.db.workout_db import WorkoutDB
from core.db.exercise_db import ExerciseDB
from core.db.analytics_db import AnalyticsDB
from core.db.nutrition_db import NutritionDB
from core.db.activity_db import ActivityDB
from core.db.base import BaseDB

__all__ = [
    "SupabaseDB",
    "get_supabase_db",
    "UserDB",
    "WorkoutDB",
    "ExerciseDB",
    "AnalyticsDB",
    "NutritionDB",
    "ActivityDB",
    "BaseDB",
]
