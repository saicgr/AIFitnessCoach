"""
Supabase Database Service for AI Fitness Coach.
Provides CRUD operations for all tables using Supabase PostgreSQL.
Replaces the local DuckDB implementation.
"""
from typing import Optional, List, Dict, Any
from datetime import datetime
import json

from core.supabase_client import get_supabase


class SupabaseDB:
    """
    Database service using Supabase PostgreSQL.

    Usage:
        db = get_supabase_db()
        user = db.get_user(user_id=1)
        workouts = db.list_workouts(user_id=1)
    """

    def __init__(self):
        self.supabase = get_supabase()
        self.client = self.supabase.client

    # ==================== USERS ====================

    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get a user by ID (UUID string)."""
        result = self.client.table("users").select("*").eq("id", user_id).execute()
        return result.data[0] if result.data else None

    def get_user_by_auth_id(self, auth_id: str) -> Optional[Dict[str, Any]]:
        """Get a user by Supabase auth_id (UUID)."""
        result = self.client.table("users").select("*").eq("auth_id", auth_id).execute()
        return result.data[0] if result.data else None

    def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Get a user by email."""
        result = self.client.table("users").select("*").eq("email", email).execute()
        return result.data[0] if result.data else None

    def create_user(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new user."""
        result = self.client.table("users").insert(data).execute()
        return result.data[0] if result.data else None

    def update_user(self, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Update a user."""
        result = self.client.table("users").update(data).eq("id", user_id).execute()
        return result.data[0] if result.data else None

    def delete_user(self, user_id: str) -> bool:
        """Delete a user."""
        self.client.table("users").delete().eq("id", user_id).execute()
        return True

    # ==================== WORKOUTS ====================

    def get_workout(self, workout_id: int) -> Optional[Dict[str, Any]]:
        """Get a workout by ID."""
        result = self.client.table("workouts").select("*").eq("id", workout_id).execute()
        return result.data[0] if result.data else None

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
        query = self.client.table("workouts").select("*").eq("user_id", user_id)

        if is_completed is not None:
            query = query.eq("is_completed", is_completed)
        if from_date:
            query = query.gte("scheduled_date", from_date)
        if to_date:
            query = query.lte("scheduled_date", to_date)

        result = query.order("scheduled_date", desc=True).range(offset, offset + limit - 1).execute()
        return result.data or []

    def create_workout(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new workout."""
        result = self.client.table("workouts").insert(data).execute()
        return result.data[0] if result.data else None

    def update_workout(self, workout_id: int, data: Dict[str, Any]) -> Dict[str, Any]:
        """Update a workout."""
        result = self.client.table("workouts").update(data).eq("id", workout_id).execute()
        return result.data[0] if result.data else None

    def delete_workout(self, workout_id: int) -> bool:
        """Delete a workout."""
        self.client.table("workouts").delete().eq("id", workout_id).execute()
        return True

    def get_workouts_by_date_range(
        self, user_id: str, start_date: str, end_date: str
    ) -> List[Dict[str, Any]]:
        """Get workouts in a date range."""
        result = (
            self.client.table("workouts")
            .select("*")
            .eq("user_id", user_id)
            .gte("scheduled_date", start_date)
            .lte("scheduled_date", end_date)
            .execute()
        )
        return result.data or []

    # ==================== EXERCISES ====================

    def get_exercise(self, exercise_id: int) -> Optional[Dict[str, Any]]:
        """Get an exercise by ID."""
        result = self.client.table("exercises").select("*").eq("id", exercise_id).execute()
        return result.data[0] if result.data else None

    def get_exercise_by_external_id(self, external_id: str) -> Optional[Dict[str, Any]]:
        """Get an exercise by external ID."""
        result = self.client.table("exercises").select("*").eq("external_id", external_id).execute()
        return result.data[0] if result.data else None

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
        query = self.client.table("exercises").select("*")

        if category:
            query = query.eq("category", category)
        if body_part:
            query = query.eq("body_part", body_part)
        if equipment:
            query = query.eq("equipment", equipment)
        if difficulty_level:
            query = query.eq("difficulty_level", difficulty_level)

        result = query.order("name").range(offset, offset + limit - 1).execute()
        return result.data or []

    def create_exercise(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new exercise."""
        result = self.client.table("exercises").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_exercise(self, exercise_id: int) -> bool:
        """Delete an exercise."""
        self.client.table("exercises").delete().eq("id", exercise_id).execute()
        return True

    # ==================== WORKOUT LOGS ====================

    def get_workout_log(self, log_id: int) -> Optional[Dict[str, Any]]:
        """Get a workout log by ID."""
        result = self.client.table("workout_logs").select("*").eq("id", log_id).execute()
        return result.data[0] if result.data else None

    def list_workout_logs(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """List workout logs for a user."""
        result = (
            self.client.table("workout_logs")
            .select("*")
            .eq("user_id", user_id)
            .order("completed_at", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []

    def create_workout_log(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a workout log."""
        result = self.client.table("workout_logs").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_workout_logs_by_workout(self, workout_id: int) -> bool:
        """Delete all workout logs for a workout."""
        self.client.table("workout_logs").delete().eq("workout_id", workout_id).execute()
        return True

    def delete_workout_logs_by_user(self, user_id: str) -> bool:
        """Delete all workout logs for a user."""
        self.client.table("workout_logs").delete().eq("user_id", user_id).execute()
        return True

    # ==================== PERFORMANCE LOGS ====================

    def list_performance_logs(
        self, user_id: str, exercise_id: Optional[str] = None, limit: int = 50
    ) -> List[Dict[str, Any]]:
        """List performance logs for a user."""
        query = self.client.table("performance_logs").select("*").eq("user_id", user_id)

        if exercise_id:
            query = query.eq("exercise_id", exercise_id)

        result = query.order("recorded_at", desc=True).limit(limit).execute()
        return result.data or []

    def create_performance_log(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a performance log."""
        result = self.client.table("performance_logs").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_performance_logs_by_workout_log(self, workout_log_id: int) -> bool:
        """Delete all performance logs for a workout log."""
        self.client.table("performance_logs").delete().eq("workout_log_id", workout_log_id).execute()
        return True

    def delete_performance_logs_by_user(self, user_id: str) -> bool:
        """Delete all performance logs for a user."""
        self.client.table("performance_logs").delete().eq("user_id", user_id).execute()
        return True

    # ==================== STRENGTH RECORDS ====================

    def list_strength_records(
        self,
        user_id: str,
        exercise_id: Optional[str] = None,
        prs_only: bool = False,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """List strength records for a user."""
        query = self.client.table("strength_records").select("*").eq("user_id", user_id)

        if exercise_id:
            query = query.eq("exercise_id", exercise_id)
        if prs_only:
            query = query.eq("is_pr", True)

        result = query.order("achieved_at", desc=True).limit(limit).execute()
        return result.data or []

    def create_strength_record(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a strength record."""
        result = self.client.table("strength_records").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_strength_records_by_user(self, user_id: str) -> bool:
        """Delete all strength records for a user."""
        self.client.table("strength_records").delete().eq("user_id", user_id).execute()
        return True

    # ==================== WEEKLY VOLUMES ====================

    def list_weekly_volumes(
        self,
        user_id: str,
        week_number: Optional[int] = None,
        year: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """List weekly volumes for a user."""
        query = self.client.table("weekly_volumes").select("*").eq("user_id", user_id)

        if week_number is not None:
            query = query.eq("week_number", week_number)
        if year is not None:
            query = query.eq("year", year)

        result = query.order("year", desc=True).order("week_number", desc=True).order("muscle_group").execute()
        return result.data or []

    def upsert_weekly_volume(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Upsert a weekly volume record."""
        # First check if record exists
        query = self.client.table("weekly_volumes").select("id").eq("user_id", data["user_id"]).eq("muscle_group", data["muscle_group"]).eq("week_number", data["week_number"]).eq("year", data["year"])
        existing = query.execute()
        if existing.data:
            # Update existing record
            result = self.client.table("weekly_volumes").update(data).eq("id", existing.data[0]["id"]).execute()
        else:
            # Insert new record
            result = self.client.table("weekly_volumes").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_weekly_volumes_by_user(self, user_id: str) -> bool:
        """Delete all weekly volumes for a user."""
        self.client.table("weekly_volumes").delete().eq("user_id", user_id).execute()
        return True

    # ==================== CHAT HISTORY ====================

    def list_chat_history(self, user_id: str, limit: int = 100) -> List[Dict[str, Any]]:
        """List chat history for a user."""
        result = (
            self.client.table("chat_history")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=False)
            .limit(limit)
            .execute()
        )
        return result.data or []

    def create_chat_message(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a chat message."""
        result = self.client.table("chat_history").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_chat_history_by_user(self, user_id: str) -> bool:
        """Delete all chat history for a user."""
        self.client.table("chat_history").delete().eq("user_id", user_id).execute()
        return True

    # ==================== INJURIES ====================

    def list_injuries(self, user_id: str, is_active: Optional[bool] = None) -> List[Dict[str, Any]]:
        """List injuries for a user."""
        query = self.client.table("injuries").select("*").eq("user_id", user_id)

        if is_active is not None:
            query = query.eq("is_active", is_active)

        result = query.order("created_at", desc=True).execute()
        return result.data or []

    def create_injury(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create an injury record."""
        result = self.client.table("injuries").insert(data).execute()
        return result.data[0] if result.data else None

    def update_injury(self, injury_id: int, data: Dict[str, Any]) -> Dict[str, Any]:
        """Update an injury record."""
        result = self.client.table("injuries").update(data).eq("id", injury_id).execute()
        return result.data[0] if result.data else None

    def delete_injuries_by_user(self, user_id: str) -> bool:
        """Delete all injuries for a user."""
        self.client.table("injuries").delete().eq("user_id", user_id).execute()
        return True

    # ==================== USER METRICS ====================

    def list_user_metrics(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """List user metrics history."""
        result = (
            self.client.table("user_metrics")
            .select("*")
            .eq("user_id", user_id)
            .order("recorded_at", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []

    def create_user_metrics(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create user metrics record."""
        result = self.client.table("user_metrics").insert(data).execute()
        return result.data[0] if result.data else None

    def get_latest_user_metrics(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get the most recent metrics for a user."""
        result = (
            self.client.table("user_metrics")
            .select("*")
            .eq("user_id", user_id)
            .order("recorded_at", desc=True)
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None

    def delete_user_metrics(self, metric_id: int, user_id: str) -> bool:
        """Delete a specific user metrics entry."""
        result = self.client.table("user_metrics").delete().eq("id", metric_id).eq("user_id", user_id).execute()
        return len(result.data) > 0 if result.data else False

    def delete_user_metrics_by_user(self, user_id: str) -> bool:
        """Delete all user metrics for a user."""
        self.client.table("user_metrics").delete().eq("user_id", user_id).execute()
        return True

    # ==================== INJURY HISTORY ====================

    def list_injury_history(self, user_id: str, is_active: Optional[bool] = None, limit: int = 50) -> List[Dict[str, Any]]:
        """List injury history for a user."""
        query = self.client.table("injury_history").select("*").eq("user_id", user_id)

        if is_active is not None:
            query = query.eq("is_active", is_active)

        result = query.order("reported_at", desc=True).limit(limit).execute()
        return result.data or []

    def get_active_injuries(self, user_id: str) -> List[Dict[str, Any]]:
        """Get active injuries for a user."""
        result = (
            self.client.table("injury_history")
            .select("*")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .order("reported_at", desc=True)
            .execute()
        )
        return result.data or []

    def create_injury_history(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create an injury history record."""
        result = self.client.table("injury_history").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_injury_history_by_user(self, user_id: str) -> bool:
        """Delete all injury history for a user."""
        self.client.table("injury_history").delete().eq("user_id", user_id).execute()
        return True

    # ==================== WORKOUT CHANGES ====================

    def list_workout_changes(
        self, workout_id: Optional[int] = None, user_id: Optional[int] = None, limit: int = 50
    ) -> List[Dict[str, Any]]:
        """List workout changes."""
        query = self.client.table("workout_changes").select("*")

        if workout_id:
            query = query.eq("workout_id", workout_id)
        if user_id:
            query = query.eq("user_id", user_id)

        result = query.order("created_at", desc=True).limit(limit).execute()
        return result.data or []

    def create_workout_change(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a workout change record."""
        result = self.client.table("workout_changes").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_workout_changes_by_workout(self, workout_id: int) -> bool:
        """Delete all workout changes for a workout."""
        self.client.table("workout_changes").delete().eq("workout_id", workout_id).execute()
        return True

    def delete_workout_changes_by_user(self, user_id: str) -> bool:
        """Delete all workout changes for a user."""
        self.client.table("workout_changes").delete().eq("user_id", user_id).execute()
        return True

    # ==================== FULL USER RESET ====================

    def full_user_reset(self, user_id: str) -> bool:
        """
        Delete all data for a user (cascade delete).

        Order matters due to foreign key constraints:
        1. performance_logs (via workout_logs)
        2. workout_logs
        3. workout_changes
        4. workouts
        5. strength_records
        6. weekly_volumes
        7. injuries
        8. injury_history
        9. user_metrics
        10. chat_history
        11. user record
        """
        # Get workout IDs first
        workouts = self.list_workouts(user_id, limit=1000)
        workout_ids = [w["id"] for w in workouts]

        # Get workout_log IDs
        logs = self.list_workout_logs(user_id, limit=1000)
        log_ids = [l["id"] for l in logs]

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
    """Get the global Supabase database instance."""
    global _supabase_db
    if _supabase_db is None:
        _supabase_db = SupabaseDB()
    return _supabase_db
