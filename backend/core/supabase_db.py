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

    def get_all_users(self) -> List[Dict[str, Any]]:
        """Get all users."""
        result = self.client.table("users").select("*").execute()
        return result.data or []

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

    def get_workout(self, workout_id: str) -> Optional[Dict[str, Any]]:
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

    def update_workout(self, workout_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Update a workout."""
        result = self.client.table("workouts").update(data).eq("id", workout_id).execute()
        return result.data[0] if result.data else None

    def delete_workout(self, workout_id: str) -> bool:
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

    # ==================== WORKOUT VERSIONING (SCD2) ====================

    def list_current_workouts(
        self,
        user_id: str,
        is_completed: Optional[bool] = None,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """List only current (active) workouts for a user - excludes superseded versions."""
        query = self.client.table("workouts").select("*").eq("user_id", user_id).eq("is_current", True)

        if is_completed is not None:
            query = query.eq("is_completed", is_completed)
        if from_date:
            query = query.gte("scheduled_date", from_date)
        if to_date:
            query = query.lte("scheduled_date", to_date)

        result = query.order("scheduled_date", desc=True).range(offset, offset + limit - 1).execute()
        return result.data or []

    def get_workout_versions(self, workout_id: str) -> List[Dict[str, Any]]:
        """
        Get all versions of a workout (including the original).
        Returns versions ordered by version_number descending (newest first).
        """
        # First get the workout to find its parent_workout_id
        workout = self.get_workout(workout_id)
        if not workout:
            return []

        # Determine the original workout ID (parent or self)
        original_id = workout.get("parent_workout_id") or workout_id

        # Get all workouts in the version chain
        result = (
            self.client.table("workouts")
            .select("*")
            .or_(f"id.eq.{original_id},parent_workout_id.eq.{original_id}")
            .order("version_number", desc=True)
            .execute()
        )
        return result.data or []

    def supersede_workout(
        self, old_workout_id: str, new_workout_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        SCD2: Create a new version of a workout, marking the old one as superseded.

        This method:
        1. Gets the old workout and its version info
        2. Marks the old workout as not current (is_current=False, valid_to=now)
        3. Creates a new workout with incremented version and parent reference
        4. Updates the old workout's superseded_by to point to the new one

        Returns the new workout.
        """
        now = datetime.utcnow().isoformat()

        # Get the old workout
        old_workout = self.get_workout(old_workout_id)
        if not old_workout:
            raise ValueError(f"Workout {old_workout_id} not found")

        # Determine the parent (original) workout ID
        parent_id = old_workout.get("parent_workout_id") or old_workout_id
        old_version = old_workout.get("version_number", 1)

        # Prepare new workout data with versioning fields
        new_workout_data["version_number"] = old_version + 1
        new_workout_data["is_current"] = True
        new_workout_data["valid_from"] = now
        new_workout_data["valid_to"] = None
        new_workout_data["parent_workout_id"] = parent_id
        new_workout_data["superseded_by"] = None

        # Create the new workout
        new_workout = self.create_workout(new_workout_data)

        # Mark the old workout as superseded
        self.client.table("workouts").update({
            "is_current": False,
            "valid_to": now,
            "superseded_by": new_workout["id"]
        }).eq("id", old_workout_id).execute()

        return new_workout

    def revert_workout(self, workout_id: str, target_version: int) -> Dict[str, Any]:
        """
        Revert a workout to a previous version by creating a new version
        with the content of the target version.

        This preserves the full history (SCD2 style) - we don't delete versions,
        we create a new version that copies the old content.

        Returns the new (reverted) workout.
        """
        # Get all versions
        versions = self.get_workout_versions(workout_id)
        if not versions:
            raise ValueError(f"No versions found for workout {workout_id}")

        # Find the target version
        target_workout = None
        for v in versions:
            if v.get("version_number") == target_version:
                target_workout = v
                break

        if not target_workout:
            raise ValueError(f"Version {target_version} not found for workout {workout_id}")

        # Find the current version
        current_workout = None
        for v in versions:
            if v.get("is_current"):
                current_workout = v
                break

        if not current_workout:
            raise ValueError("No current version found")

        # Create new workout data from target version (excluding ID and versioning fields)
        new_workout_data = {
            "user_id": target_workout["user_id"],
            "name": target_workout["name"],
            "type": target_workout["type"],
            "difficulty": target_workout["difficulty"],
            "scheduled_date": target_workout["scheduled_date"],
            "is_completed": False,  # Reset completion status on revert
            "exercises_json": target_workout["exercises_json"],
            "duration_minutes": target_workout.get("duration_minutes", 45),
            "generation_method": "revert",
            "generation_source": f"reverted_from_v{target_version}",
            "generation_metadata": json.dumps({
                "reverted_from_version": target_version,
                "reverted_from_id": target_workout["id"],
                "reverted_at": datetime.utcnow().isoformat()
            }),
        }

        # Use supersede to create the new version
        return self.supersede_workout(current_workout["id"], new_workout_data)

    def soft_delete_workout(self, workout_id: str) -> bool:
        """
        Soft delete a workout by marking it as not current.
        Unlike hard delete, this preserves history for potential recovery.
        """
        now = datetime.utcnow().isoformat()
        self.client.table("workouts").update({
            "is_current": False,
            "valid_to": now
        }).eq("id", workout_id).execute()
        return True

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

    def delete_workout_logs_by_workout(self, workout_id: str) -> bool:
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
            .order("timestamp", desc=False)
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

    def delete_workout_changes_by_workout(self, workout_id: str) -> bool:
        """Delete all workout changes for a workout."""
        self.client.table("workout_changes").delete().eq("workout_id", workout_id).execute()
        return True

    def delete_workout_changes_by_user(self, user_id: str) -> bool:
        """Delete all workout changes for a user."""
        self.client.table("workout_changes").delete().eq("user_id", user_id).execute()
        return True

    # ==================== FOOD LOGS ====================

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
        ai_feedback: str = None,
        health_score: int = None,
    ) -> Dict[str, Any]:
        """Create a food log entry from AI analysis."""
        data = {
            "user_id": user_id,
            "meal_type": meal_type,
            "food_items": food_items,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "ai_feedback": ai_feedback,
            "health_score": health_score,
        }
        result = self.client.table("food_logs").insert(data).execute()
        return result.data[0] if result.data else None

    def get_food_log(self, log_id: str) -> Optional[Dict[str, Any]]:
        """Get a food log by ID."""
        result = self.client.table("food_logs").select("*").eq("id", log_id).execute()
        return result.data[0] if result.data else None

    def list_food_logs(
        self,
        user_id: str,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
        meal_type: Optional[str] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """List food logs for a user with optional filters."""
        query = self.client.table("food_logs").select("*").eq("user_id", user_id)

        if from_date:
            query = query.gte("logged_at", from_date)
        if to_date:
            query = query.lte("logged_at", to_date)
        if meal_type:
            query = query.eq("meal_type", meal_type)

        result = query.order("logged_at", desc=True).limit(limit).execute()
        return result.data or []

    def get_daily_nutrition_summary(self, user_id: str, date: str) -> Dict[str, Any]:
        """Get nutrition totals for a specific day."""
        # Query logs for the given date (using date range for the day)
        start_of_day = f"{date}T00:00:00"
        end_of_day = f"{date}T23:59:59"

        logs = self.list_food_logs(user_id, from_date=start_of_day, to_date=end_of_day, limit=100)

        return {
            "date": date,
            "total_calories": sum(log.get("total_calories") or 0 for log in logs),
            "total_protein_g": sum(float(log.get("protein_g") or 0) for log in logs),
            "total_carbs_g": sum(float(log.get("carbs_g") or 0) for log in logs),
            "total_fat_g": sum(float(log.get("fat_g") or 0) for log in logs),
            "total_fiber_g": sum(float(log.get("fiber_g") or 0) for log in logs),
            "meal_count": len(logs),
            "meals": logs,
        }

    def get_weekly_nutrition_summary(self, user_id: str, start_date: str) -> List[Dict[str, Any]]:
        """Get nutrition totals for a week starting from start_date."""
        from datetime import datetime, timedelta

        start = datetime.fromisoformat(start_date)
        summaries = []

        for i in range(7):
            day = (start + timedelta(days=i)).strftime("%Y-%m-%d")
            summary = self.get_daily_nutrition_summary(user_id, day)
            summaries.append(summary)

        return summaries

    def delete_food_log(self, log_id: str) -> bool:
        """Delete a food log entry."""
        self.client.table("food_logs").delete().eq("id", log_id).execute()
        return True

    def delete_food_logs_by_user(self, user_id: str) -> bool:
        """Delete all food logs for a user."""
        self.client.table("food_logs").delete().eq("user_id", user_id).execute()
        return True

    # ==================== USER NUTRITION TARGETS ====================

    def update_user_nutrition_targets(
        self,
        user_id: str,
        daily_calorie_target: Optional[int] = None,
        daily_protein_target_g: Optional[float] = None,
        daily_carbs_target_g: Optional[float] = None,
        daily_fat_target_g: Optional[float] = None,
    ) -> Dict[str, Any]:
        """Update user's daily nutrition targets."""
        data = {}
        if daily_calorie_target is not None:
            data["daily_calorie_target"] = daily_calorie_target
        if daily_protein_target_g is not None:
            data["daily_protein_target_g"] = daily_protein_target_g
        if daily_carbs_target_g is not None:
            data["daily_carbs_target_g"] = daily_carbs_target_g
        if daily_fat_target_g is not None:
            data["daily_fat_target_g"] = daily_fat_target_g

        if data:
            result = self.client.table("users").update(data).eq("id", user_id).execute()
            return result.data[0] if result.data else None
        return None

    def get_user_nutrition_targets(self, user_id: str) -> Dict[str, Any]:
        """Get user's daily nutrition targets."""
        result = (
            self.client.table("users")
            .select("daily_calorie_target, daily_protein_target_g, daily_carbs_target_g, daily_fat_target_g")
            .eq("id", user_id)
            .execute()
        )
        if result.data:
            return result.data[0]
        return {
            "daily_calorie_target": None,
            "daily_protein_target_g": None,
            "daily_carbs_target_g": None,
            "daily_fat_target_g": None,
        }

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
