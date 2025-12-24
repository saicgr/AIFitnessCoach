"""
Unified database facade for AI Fitness Coach.

Provides a single interface to all database operations while
delegating to specialized modules for maintainability.
"""
from typing import Optional, List, Dict, Any

from core.supabase_client import get_supabase, SupabaseManager
from core.db.user_db import UserDB
from core.db.workout_db import WorkoutDB
from core.db.exercise_db import ExerciseDB
from core.db.analytics_db import AnalyticsDB
from core.db.nutrition_db import NutritionDB
from core.db.activity_db import ActivityDB


class SupabaseDB:
    """
    Unified database service using Supabase PostgreSQL.

    This facade class provides backward-compatible access to all database
    operations while delegating to specialized modules internally.

    Usage:
        db = get_supabase_db()
        user = db.get_user(user_id="...")
        workouts = db.list_workouts(user_id="...")
    """

    def __init__(self, supabase_manager: Optional[SupabaseManager] = None):
        """
        Initialize the database facade.

        Args:
            supabase_manager: Optional SupabaseManager instance.
                              If not provided, uses the global singleton.
        """
        self._manager = supabase_manager or get_supabase()

        # Initialize specialized database modules
        self._user_db = UserDB(self._manager)
        self._workout_db = WorkoutDB(self._manager)
        self._exercise_db = ExerciseDB(self._manager)
        self._analytics_db = AnalyticsDB(self._manager)
        self._nutrition_db = NutritionDB(self._manager)
        self._activity_db = ActivityDB(self._manager)

    @property
    def supabase(self) -> SupabaseManager:
        """Get the Supabase manager instance."""
        return self._manager

    @property
    def client(self):
        """Get the Supabase client for direct table operations."""
        return self._manager.client

    # ==================== USER OPERATIONS ====================
    # Delegated to UserDB

    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get a user by ID (UUID string)."""
        return self._user_db.get_user(user_id)

    def get_all_users(self) -> List[Dict[str, Any]]:
        """Get all users."""
        return self._user_db.get_all_users()

    def get_user_by_auth_id(self, auth_id: str) -> Optional[Dict[str, Any]]:
        """Get a user by Supabase auth_id (UUID)."""
        return self._user_db.get_user_by_auth_id(auth_id)

    def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Get a user by email."""
        return self._user_db.get_user_by_email(email)

    def create_user(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a new user."""
        return self._user_db.create_user(data)

    def update_user(self, user_id: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update a user."""
        return self._user_db.update_user(user_id, data)

    def delete_user(self, user_id: str) -> bool:
        """Delete a user."""
        return self._user_db.delete_user(user_id)

    # User Injuries
    def list_injuries(
        self, user_id: str, is_active: Optional[bool] = None
    ) -> List[Dict[str, Any]]:
        """List injuries for a user."""
        return self._user_db.list_injuries(user_id, is_active)

    def create_injury(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create an injury record."""
        return self._user_db.create_injury(data)

    def update_injury(
        self, injury_id: int, data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """Update an injury record."""
        return self._user_db.update_injury(injury_id, data)

    def delete_injuries_by_user(self, user_id: str) -> bool:
        """Delete all injuries for a user."""
        return self._user_db.delete_injuries_by_user(user_id)

    # Injury History
    def list_injury_history(
        self,
        user_id: str,
        is_active: Optional[bool] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """List injury history for a user."""
        return self._user_db.list_injury_history(user_id, is_active, limit)

    def get_active_injuries(self, user_id: str) -> List[Dict[str, Any]]:
        """Get active injuries for a user."""
        return self._user_db.get_active_injuries(user_id)

    def create_injury_history(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create an injury history record."""
        return self._user_db.create_injury_history(data)

    def delete_injury_history_by_user(self, user_id: str) -> bool:
        """Delete all injury history for a user."""
        return self._user_db.delete_injury_history_by_user(user_id)

    # User Metrics
    def list_user_metrics(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """List user metrics history."""
        return self._user_db.list_user_metrics(user_id, limit)

    def create_user_metrics(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create user metrics record."""
        return self._user_db.create_user_metrics(data)

    def get_latest_user_metrics(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get the most recent metrics for a user."""
        return self._user_db.get_latest_user_metrics(user_id)

    def delete_user_metrics(self, metric_id: int, user_id: str) -> bool:
        """Delete a specific user metrics entry."""
        return self._user_db.delete_user_metrics(metric_id, user_id)

    def delete_user_metrics_by_user(self, user_id: str) -> bool:
        """Delete all user metrics for a user."""
        return self._user_db.delete_user_metrics_by_user(user_id)

    # Chat History
    def list_chat_history(self, user_id: str, limit: int = 100) -> List[Dict[str, Any]]:
        """List chat history for a user."""
        return self._user_db.list_chat_history(user_id, limit)

    def create_chat_message(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a chat message."""
        return self._user_db.create_chat_message(data)

    def delete_chat_history_by_user(self, user_id: str) -> bool:
        """Delete all chat history for a user."""
        return self._user_db.delete_chat_history_by_user(user_id)

    # ==================== WORKOUT OPERATIONS ====================
    # Delegated to WorkoutDB

    def get_workout(self, workout_id: str) -> Optional[Dict[str, Any]]:
        """Get a workout by ID."""
        return self._workout_db.get_workout(workout_id)

    def list_workouts(
        self,
        user_id: str,
        is_completed: Optional[bool] = None,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """List workouts for a user with filters."""
        return self._workout_db.list_workouts(
            user_id, is_completed, from_date, to_date, limit, offset
        )

    def create_workout(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a new workout."""
        return self._workout_db.create_workout(data)

    def update_workout(
        self, workout_id: str, data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """Update a workout."""
        return self._workout_db.update_workout(workout_id, data)

    def delete_workout(self, workout_id: str) -> bool:
        """Delete a workout."""
        return self._workout_db.delete_workout(workout_id)

    def get_workouts_by_date_range(
        self, user_id: str, start_date: str, end_date: str
    ) -> List[Dict[str, Any]]:
        """Get workouts in a date range."""
        return self._workout_db.get_workouts_by_date_range(user_id, start_date, end_date)

    # Workout Versioning (SCD2)
    def list_current_workouts(
        self,
        user_id: str,
        is_completed: Optional[bool] = None,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """List only current (active) workouts for a user."""
        return self._workout_db.list_current_workouts(
            user_id, is_completed, from_date, to_date, limit, offset
        )

    def get_workout_versions(self, workout_id: str) -> List[Dict[str, Any]]:
        """Get all versions of a workout."""
        return self._workout_db.get_workout_versions(workout_id)

    def supersede_workout(
        self, old_workout_id: str, new_workout_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """SCD2: Create a new version of a workout."""
        return self._workout_db.supersede_workout(old_workout_id, new_workout_data)

    def revert_workout(self, workout_id: str, target_version: int) -> Dict[str, Any]:
        """Revert a workout to a previous version."""
        return self._workout_db.revert_workout(workout_id, target_version)

    def soft_delete_workout(self, workout_id: str) -> bool:
        """Soft delete a workout by marking it as not current."""
        return self._workout_db.soft_delete_workout(workout_id)

    # Workout Logs
    def get_workout_log(self, log_id: int) -> Optional[Dict[str, Any]]:
        """Get a workout log by ID."""
        return self._workout_db.get_workout_log(log_id)

    def list_workout_logs(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """List workout logs for a user."""
        return self._workout_db.list_workout_logs(user_id, limit)

    def create_workout_log(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a workout log."""
        return self._workout_db.create_workout_log(data)

    def delete_workout_logs_by_workout(self, workout_id: str) -> bool:
        """Delete all workout logs for a workout."""
        return self._workout_db.delete_workout_logs_by_workout(workout_id)

    def delete_workout_logs_by_user(self, user_id: str) -> bool:
        """Delete all workout logs for a user."""
        return self._workout_db.delete_workout_logs_by_user(user_id)

    # Workout Changes
    def list_workout_changes(
        self,
        workout_id: Optional[int] = None,
        user_id: Optional[int] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """List workout changes."""
        return self._workout_db.list_workout_changes(workout_id, user_id, limit)

    def create_workout_change(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a workout change record."""
        return self._workout_db.create_workout_change(data)

    def delete_workout_changes_by_workout(self, workout_id: str) -> bool:
        """Delete all workout changes for a workout."""
        return self._workout_db.delete_workout_changes_by_workout(workout_id)

    def delete_workout_changes_by_user(self, user_id: str) -> bool:
        """Delete all workout changes for a user."""
        return self._workout_db.delete_workout_changes_by_user(user_id)

    # Workout Exits
    def create_workout_exit(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a workout exit log entry."""
        return self._workout_db.create_workout_exit(data)

    def list_workout_exits(
        self, user_id: str, workout_id: Optional[str] = None, limit: int = 50
    ) -> List[Dict[str, Any]]:
        """List workout exits for a user."""
        return self._workout_db.list_workout_exits(user_id, workout_id, limit)

    def delete_workout_exits_by_user(self, user_id: str) -> bool:
        """Delete all workout exits for a user."""
        return self._workout_db.delete_workout_exits_by_user(user_id)

    # Drink Intake
    def create_drink_intake(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a drink intake log entry."""
        return self._workout_db.create_drink_intake(data)

    def list_drink_intakes(
        self, user_id: str, workout_log_id: Optional[str] = None, limit: int = 100
    ) -> List[Dict[str, Any]]:
        """List drink intakes for a user."""
        return self._workout_db.list_drink_intakes(user_id, workout_log_id, limit)

    def get_workout_total_drink_intake(self, workout_log_id: str) -> int:
        """Get total drink intake for a workout in ml."""
        return self._workout_db.get_workout_total_drink_intake(workout_log_id)

    def delete_drink_intakes_by_workout_log(self, workout_log_id: str) -> bool:
        """Delete all drink intakes for a workout log."""
        return self._workout_db.delete_drink_intakes_by_workout_log(workout_log_id)

    def delete_drink_intakes_by_user(self, user_id: str) -> bool:
        """Delete all drink intakes for a user."""
        return self._workout_db.delete_drink_intakes_by_user(user_id)

    # Rest Intervals
    def create_rest_interval(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a rest interval log entry."""
        return self._workout_db.create_rest_interval(data)

    def list_rest_intervals(
        self, user_id: str, workout_log_id: Optional[str] = None, limit: int = 200
    ) -> List[Dict[str, Any]]:
        """List rest intervals for a user."""
        return self._workout_db.list_rest_intervals(user_id, workout_log_id, limit)

    def get_workout_rest_stats(self, workout_log_id: str) -> Dict[str, Any]:
        """Get rest interval statistics for a workout."""
        return self._workout_db.get_workout_rest_stats(workout_log_id)

    def delete_rest_intervals_by_workout_log(self, workout_log_id: str) -> bool:
        """Delete all rest intervals for a workout log."""
        return self._workout_db.delete_rest_intervals_by_workout_log(workout_log_id)

    def delete_rest_intervals_by_user(self, user_id: str) -> bool:
        """Delete all rest intervals for a user."""
        return self._workout_db.delete_rest_intervals_by_user(user_id)

    # ==================== EXERCISE OPERATIONS ====================
    # Delegated to ExerciseDB

    def get_exercise(self, exercise_id: int) -> Optional[Dict[str, Any]]:
        """Get an exercise by ID."""
        return self._exercise_db.get_exercise(exercise_id)

    def get_exercise_by_external_id(
        self, external_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get an exercise by external ID."""
        return self._exercise_db.get_exercise_by_external_id(external_id)

    def list_exercises(
        self,
        category: Optional[str] = None,
        body_part: Optional[str] = None,
        equipment: Optional[str] = None,
        difficulty_level: Optional[int] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """List exercises with filters."""
        return self._exercise_db.list_exercises(
            category, body_part, equipment, difficulty_level, limit, offset
        )

    def create_exercise(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a new exercise."""
        return self._exercise_db.create_exercise(data)

    def delete_exercise(self, exercise_id: int) -> bool:
        """Delete an exercise."""
        return self._exercise_db.delete_exercise(exercise_id)

    # Performance Logs
    def list_performance_logs(
        self,
        user_id: str,
        exercise_id: Optional[str] = None,
        exercise_name: Optional[str] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """List performance logs for a user."""
        return self._exercise_db.list_performance_logs(
            user_id, exercise_id, exercise_name, limit
        )

    def create_performance_log(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a performance log."""
        return self._exercise_db.create_performance_log(data)

    def delete_performance_logs_by_workout_log(self, workout_log_id: int) -> bool:
        """Delete all performance logs for a workout log."""
        return self._exercise_db.delete_performance_logs_by_workout_log(workout_log_id)

    def delete_performance_logs_by_user(self, user_id: str) -> bool:
        """Delete all performance logs for a user."""
        return self._exercise_db.delete_performance_logs_by_user(user_id)

    # Strength Records
    def list_strength_records(
        self,
        user_id: str,
        exercise_id: Optional[str] = None,
        prs_only: bool = False,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """List strength records for a user."""
        return self._exercise_db.list_strength_records(
            user_id, exercise_id, prs_only, limit
        )

    def create_strength_record(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a strength record."""
        return self._exercise_db.create_strength_record(data)

    def delete_strength_records_by_user(self, user_id: str) -> bool:
        """Delete all strength records for a user."""
        return self._exercise_db.delete_strength_records_by_user(user_id)

    # Weekly Volumes
    def list_weekly_volumes(
        self,
        user_id: str,
        week_number: Optional[int] = None,
        year: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """List weekly volumes for a user."""
        return self._exercise_db.list_weekly_volumes(user_id, week_number, year)

    def upsert_weekly_volume(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Upsert a weekly volume record."""
        return self._exercise_db.upsert_weekly_volume(data)

    def delete_weekly_volumes_by_user(self, user_id: str) -> bool:
        """Delete all weekly volumes for a user."""
        return self._exercise_db.delete_weekly_volumes_by_user(user_id)

    # ==================== ANALYTICS OPERATIONS ====================
    # Delegated to AnalyticsDB

    def record_workout_regeneration(
        self,
        user_id: str,
        original_workout_id: str,
        new_workout_id: str,
        difficulty: Optional[str] = None,
        duration_minutes: Optional[int] = None,
        workout_type: Optional[str] = None,
        equipment: Optional[List[str]] = None,
        focus_areas: Optional[List[str]] = None,
        injuries: Optional[List[str]] = None,
        custom_focus_area: Optional[str] = None,
        custom_injury: Optional[str] = None,
        generation_method: str = "ai",
        used_rag: bool = False,
        generation_time_ms: Optional[int] = None,
    ) -> Optional[Dict[str, Any]]:
        """Record a workout regeneration event for analytics."""
        return self._analytics_db.record_workout_regeneration(
            user_id,
            original_workout_id,
            new_workout_id,
            difficulty,
            duration_minutes,
            workout_type,
            equipment,
            focus_areas,
            injuries,
            custom_focus_area,
            custom_injury,
            generation_method,
            used_rag,
            generation_time_ms,
        )

    def get_user_regeneration_analytics(
        self, user_id: str, limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Get regeneration history for a user."""
        return self._analytics_db.get_user_regeneration_analytics(user_id, limit)

    def get_latest_user_regeneration(
        self, user_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get the most recent regeneration entry for a user."""
        return self._analytics_db.get_latest_user_regeneration(user_id)

    def get_popular_custom_inputs(
        self, input_type: str, limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Get popular custom inputs across all users."""
        return self._analytics_db.get_popular_custom_inputs(input_type, limit)

    def get_user_custom_inputs(
        self, user_id: str, input_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Get custom inputs for a specific user."""
        return self._analytics_db.get_user_custom_inputs(user_id, input_type)

    def get_user_equipment_preferences(
        self, user_id: str, limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get user's most used equipment combinations."""
        return self._analytics_db.get_user_equipment_preferences(user_id, limit)

    # ==================== NUTRITION OPERATIONS ====================
    # Delegated to NutritionDB

    def create_food_log(
        self,
        user_id: str,
        meal_type: str,
        food_items: list,
        total_calories: int,
        protein_g: float,
        carbs_g: float,
        fat_g: float,
        fiber_g: float = 0,
        ai_feedback: Optional[str] = None,
        health_score: Optional[int] = None,
    ) -> Optional[Dict[str, Any]]:
        """Create a food log entry from AI analysis."""
        return self._nutrition_db.create_food_log(
            user_id,
            meal_type,
            food_items,
            total_calories,
            protein_g,
            carbs_g,
            fat_g,
            fiber_g,
            ai_feedback,
            health_score,
        )

    def get_food_log(self, log_id: str) -> Optional[Dict[str, Any]]:
        """Get a food log by ID."""
        return self._nutrition_db.get_food_log(log_id)

    def list_food_logs(
        self,
        user_id: str,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
        meal_type: Optional[str] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """List food logs for a user with optional filters."""
        return self._nutrition_db.list_food_logs(
            user_id, from_date, to_date, meal_type, limit
        )

    def get_daily_nutrition_summary(
        self, user_id: str, date: str
    ) -> Dict[str, Any]:
        """Get nutrition totals for a specific day."""
        return self._nutrition_db.get_daily_nutrition_summary(user_id, date)

    def get_weekly_nutrition_summary(
        self, user_id: str, start_date: str
    ) -> List[Dict[str, Any]]:
        """Get nutrition totals for a week."""
        return self._nutrition_db.get_weekly_nutrition_summary(user_id, start_date)

    def delete_food_log(self, log_id: str) -> bool:
        """Delete a food log entry."""
        return self._nutrition_db.delete_food_log(log_id)

    def delete_food_logs_by_user(self, user_id: str) -> bool:
        """Delete all food logs for a user."""
        return self._nutrition_db.delete_food_logs_by_user(user_id)

    def update_user_nutrition_targets(
        self,
        user_id: str,
        daily_calorie_target: Optional[int] = None,
        daily_protein_target_g: Optional[float] = None,
        daily_carbs_target_g: Optional[float] = None,
        daily_fat_target_g: Optional[float] = None,
    ) -> Optional[Dict[str, Any]]:
        """Update user's daily nutrition targets."""
        return self._nutrition_db.update_user_nutrition_targets(
            user_id,
            daily_calorie_target,
            daily_protein_target_g,
            daily_carbs_target_g,
            daily_fat_target_g,
        )

    def get_user_nutrition_targets(self, user_id: str) -> Dict[str, Any]:
        """Get user's daily nutrition targets."""
        return self._nutrition_db.get_user_nutrition_targets(user_id)

    # ==================== ACTIVITY OPERATIONS ====================
    # Delegated to ActivityDB

    def upsert_daily_activity(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Upsert daily activity data."""
        return self._activity_db.upsert_daily_activity(data)

    def get_daily_activity(
        self, user_id: str, activity_date: str
    ) -> Optional[Dict[str, Any]]:
        """Get daily activity for a specific date."""
        return self._activity_db.get_daily_activity(user_id, activity_date)

    def list_daily_activity(
        self,
        user_id: str,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
        limit: int = 30,
    ) -> List[Dict[str, Any]]:
        """List daily activity for a user within a date range."""
        return self._activity_db.list_daily_activity(user_id, from_date, to_date, limit)

    def get_activity_summary(
        self, user_id: str, days: int = 7
    ) -> Dict[str, Any]:
        """Get activity summary for the last N days."""
        return self._activity_db.get_activity_summary(user_id, days)

    def delete_daily_activity(self, user_id: str, activity_date: str) -> bool:
        """Delete a specific daily activity entry."""
        return self._activity_db.delete_daily_activity(user_id, activity_date)

    def delete_daily_activity_by_user(self, user_id: str) -> bool:
        """Delete all daily activity for a user."""
        return self._activity_db.delete_daily_activity_by_user(user_id)

    # ==================== FULL USER RESET ====================

    def full_user_reset(self, user_id: str) -> bool:
        """
        Delete all data for a user (cascade delete).

        Order matters due to foreign key constraints.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        # Get workout IDs first
        workouts = self.list_workouts(user_id, limit=1000)
        workout_ids = [w["id"] for w in workouts]

        # Get workout_log IDs
        logs = self.list_workout_logs(user_id, limit=1000)
        log_ids = [log["id"] for log in logs]

        # 1. Delete performance_logs by workout_log IDs
        for log_id in log_ids:
            self.delete_performance_logs_by_workout_log(log_id)

        # 2. Delete workout_logs
        self.delete_workout_logs_by_user(user_id)

        # 3. Delete workout_changes by workout IDs
        for workout_id in workout_ids:
            self.delete_workout_changes_by_workout(workout_id)

        # 4. Delete workouts
        for workout_id in workout_ids:
            self.delete_workout(workout_id)

        # 5-10. Delete remaining user data
        self.delete_strength_records_by_user(user_id)
        self.delete_weekly_volumes_by_user(user_id)
        self.delete_injuries_by_user(user_id)
        self.delete_injury_history_by_user(user_id)
        self.delete_user_metrics_by_user(user_id)
        self.delete_chat_history_by_user(user_id)

        # 11. Delete user
        self.delete_user(user_id)

        return True


# Singleton instance
_supabase_db: Optional[SupabaseDB] = None


def get_supabase_db() -> SupabaseDB:
    """
    Get the global Supabase database instance.

    Returns:
        SupabaseDB facade instance
    """
    global _supabase_db
    if _supabase_db is None:
        _supabase_db = SupabaseDB()
    return _supabase_db
