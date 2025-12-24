"""
Database modules for AI Fitness Coach.

This package contains modular database operations organized by domain:
- user_db: User CRUD operations
- workout_db: Workout and versioning operations
- exercise_db: Exercise and performance tracking
- analytics_db: Regeneration analytics and custom inputs
- nutrition_db: Food logs and nutrition targets
- activity_db: Daily activity and health metrics

Usage:
    from core.db import get_supabase_db

    db = get_supabase_db()
    user = db.get_user(user_id="...")
"""

from core.db.base import BaseDB
from core.db.user_db import UserDB
from core.db.workout_db import WorkoutDB
from core.db.exercise_db import ExerciseDB
from core.db.analytics_db import AnalyticsDB
from core.db.nutrition_db import NutritionDB
from core.db.activity_db import ActivityDB
from core.db.facade import SupabaseDB, get_supabase_db

__all__ = [
    "BaseDB",
    "UserDB",
    "WorkoutDB",
    "ExerciseDB",
    "AnalyticsDB",
    "NutritionDB",
    "ActivityDB",
    "SupabaseDB",
    "get_supabase_db",
]
