"""
Exercise database operations.

Handles all exercise-related CRUD operations including:
- Exercise catalog management
- Performance logging
- Strength records and PRs
- Weekly volume tracking
"""
from typing import Optional, List, Dict, Any

from core.db.base import BaseDB


class ExerciseDB(BaseDB):
    """
    Database operations for exercise management and performance tracking.

    Handles the exercise catalog, performance logs, strength records,
    and weekly volume calculations.
    """

    # ==================== EXERCISES ====================

    def get_exercise(self, exercise_id: int) -> Optional[Dict[str, Any]]:
        """
        Get an exercise by ID.

        Args:
            exercise_id: Exercise record ID

        Returns:
            Exercise data dict or None
        """
        result = (
            self.client.table("exercises").select("*").eq("id", exercise_id).execute()
        )
        return result.data[0] if result.data else None

    def get_exercise_by_external_id(
        self, external_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get an exercise by external ID.

        Args:
            external_id: External exercise ID

        Returns:
            Exercise data dict or None
        """
        result = (
            self.client.table("exercises")
            .select("*")
            .eq("external_id", external_id)
            .execute()
        )
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
        """
        List exercises with filters.

        Args:
            category: Filter by category
            body_part: Filter by body part
            equipment: Filter by equipment
            difficulty_level: Filter by difficulty level
            limit: Maximum exercises to return
            offset: Number to skip

        Returns:
            List of exercise records
        """
        query = self.client.table("exercises").select(
            "id, external_id, name, category, body_part, equipment, "
            "difficulty_level, description, instructions, primary_muscles, "
            "secondary_muscles"
        )

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

    def create_exercise(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a new exercise.

        Args:
            data: Exercise data to insert

        Returns:
            Created exercise record or None
        """
        result = self.client.table("exercises").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_exercise(self, exercise_id: int) -> bool:
        """
        Delete an exercise.

        Args:
            exercise_id: Exercise record ID

        Returns:
            True on success
        """
        self.client.table("exercises").delete().eq("id", exercise_id).execute()
        return True

    # ==================== PERFORMANCE LOGS ====================

    def list_performance_logs(
        self,
        user_id: str,
        exercise_id: Optional[str] = None,
        exercise_name: Optional[str] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """
        List performance logs for a user.

        Args:
            user_id: User's UUID
            exercise_id: Filter by exercise ID
            exercise_name: Filter by exercise name (case-insensitive)
            limit: Maximum records to return

        Returns:
            List of performance log records
        """
        query = (
            self.client.table("performance_logs").select(
                "id, user_id, workout_log_id, exercise_id, exercise_name, "
                "sets_completed, reps_completed, weight_kg, volume_kg, "
                "one_rep_max, recorded_at"
            ).eq("user_id", user_id)
        )

        if exercise_id:
            query = query.eq("exercise_id", exercise_id)

        if exercise_name:
            query = query.ilike("exercise_name", exercise_name)

        result = query.order("recorded_at", desc=True).limit(limit).execute()
        return result.data or []

    def create_performance_log(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a performance log.

        Args:
            data: Performance log data to insert

        Returns:
            Created record or None
        """
        result = self.client.table("performance_logs").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_performance_logs_by_workout_log(self, workout_log_id: int) -> bool:
        """
        Delete all performance logs for a workout log.

        Args:
            workout_log_id: Workout log ID

        Returns:
            True on success
        """
        self.client.table("performance_logs").delete().eq(
            "workout_log_id", workout_log_id
        ).execute()
        return True

    def delete_performance_logs_by_user(self, user_id: str) -> bool:
        """
        Delete all performance logs for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
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
        """
        List strength records for a user.

        Args:
            user_id: User's UUID
            exercise_id: Filter by exercise ID
            prs_only: If True, only return personal records
            limit: Maximum records to return

        Returns:
            List of strength records
        """
        query = (
            self.client.table("strength_records").select(
                "id, user_id, exercise_id, exercise_name, weight_kg, reps, "
                "one_rep_max, is_pr, achieved_at"
            ).eq("user_id", user_id)
        )

        if exercise_id:
            query = query.eq("exercise_id", exercise_id)
        if prs_only:
            query = query.eq("is_pr", True)

        result = query.order("achieved_at", desc=True).limit(limit).execute()
        return result.data or []

    def create_strength_record(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a strength record.

        Args:
            data: Strength record data to insert

        Returns:
            Created record or None
        """
        result = self.client.table("strength_records").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_strength_records_by_user(self, user_id: str) -> bool:
        """
        Delete all strength records for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("strength_records").delete().eq("user_id", user_id).execute()
        return True

    # ==================== WEEKLY VOLUMES ====================

    def list_weekly_volumes(
        self,
        user_id: str,
        week_number: Optional[int] = None,
        year: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        List weekly volumes for a user.

        Args:
            user_id: User's UUID
            week_number: Filter by week number
            year: Filter by year

        Returns:
            List of weekly volume records
        """
        query = (
            self.client.table("weekly_volumes").select(
                "id, user_id, muscle_group, total_sets, total_volume_kg, "
                "week_number, year"
            ).eq("user_id", user_id)
        )

        if week_number is not None:
            query = query.eq("week_number", week_number)
        if year is not None:
            query = query.eq("year", year)

        result = (
            query.order("year", desc=True)
            .order("week_number", desc=True)
            .order("muscle_group")
            .execute()
        )
        return result.data or []

    def upsert_weekly_volume(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Upsert a weekly volume record.

        Creates or updates based on user_id + muscle_group + week_number + year.

        Args:
            data: Weekly volume data

        Returns:
            Upserted record or None
        """
        query = (
            self.client.table("weekly_volumes")
            .select("id")
            .eq("user_id", data["user_id"])
            .eq("muscle_group", data["muscle_group"])
            .eq("week_number", data["week_number"])
            .eq("year", data["year"])
        )
        existing = query.execute()

        if existing.data:
            result = (
                self.client.table("weekly_volumes")
                .update(data)
                .eq("id", existing.data[0]["id"])
                .execute()
            )
        else:
            result = self.client.table("weekly_volumes").insert(data).execute()

        return result.data[0] if result.data else None

    def delete_weekly_volumes_by_user(self, user_id: str) -> bool:
        """
        Delete all weekly volumes for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("weekly_volumes").delete().eq("user_id", user_id).execute()
        return True
