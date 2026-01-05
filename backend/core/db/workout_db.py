"""
Workout database operations.

Handles all workout-related CRUD operations including:
- Workout creation, listing, and filtering
- SCD2 versioning (supersede, revert, soft delete)
- Workout logs and changes tracking
- Workout exits and rest intervals
"""
from typing import Optional, List, Dict, Any
from datetime import datetime
import json

from core.db.base import BaseDB


class WorkoutDB(BaseDB):
    """
    Database operations for workout management.

    Implements SCD2 (Slowly Changing Dimension Type 2) pattern for workout versioning.
    """

    # ==================== WORKOUTS ====================

    def get_workout(self, workout_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a workout by ID.

        Args:
            workout_id: Workout UUID

        Returns:
            Workout data dict or None if not found
        """
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
        order_asc: bool = False,
    ) -> List[Dict[str, Any]]:
        """
        List workouts for a user with filters.

        Only returns current (non-superseded) workouts and deduplicates by scheduled_date.

        Args:
            user_id: User's UUID
            is_completed: Filter by completion status
            from_date: Filter workouts from this date (inclusive)
            to_date: Filter workouts to this date (inclusive)
            limit: Maximum workouts to return
            offset: Number of workouts to skip

        Returns:
            List of workout records
        """
        query = self.client.table("workouts").select("*").eq("user_id", user_id)

        # Only show current workouts (filter out superseded versions from SCD2)
        query = query.eq("is_current", True)

        if is_completed is not None:
            query = query.eq("is_completed", is_completed)
        if from_date:
            query = query.gte("scheduled_date", from_date)
        if to_date:
            query = query.lte("scheduled_date", to_date)

        # Fetch more than needed to account for duplicates, then deduplicate
        fetch_limit = (limit + offset) * 3
        # order_asc=True for getting earliest workouts first (used by /today endpoint)
        # order_asc=False (default) for getting latest workouts first
        result = (
            query.order("scheduled_date", desc=not order_asc)
            .order("created_at", desc=not order_asc)
            .limit(fetch_limit)
            .execute()
        )

        if not result.data:
            return []

        # Deduplicate: keep only the most recently created workout per scheduled_date
        seen_dates = set()
        deduplicated = []
        for workout in result.data:
            scheduled_date = workout.get("scheduled_date", "")
            if scheduled_date:
                date_only = scheduled_date.split("T")[0]
            else:
                date_only = workout.get("id")

            if date_only not in seen_dates:
                seen_dates.add(date_only)
                deduplicated.append(workout)

        return deduplicated[offset : offset + limit]

    def create_workout(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a new workout.

        Args:
            data: Workout data to insert

        Returns:
            Created workout record or None
        """
        result = self.client.table("workouts").insert(data).execute()
        return result.data[0] if result.data else None

    def update_workout(
        self, workout_id: str, data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Update a workout.

        Args:
            workout_id: Workout UUID
            data: Fields to update

        Returns:
            Updated workout record or None
        """
        result = (
            self.client.table("workouts").update(data).eq("id", workout_id).execute()
        )
        return result.data[0] if result.data else None

    def delete_workout(self, workout_id: str) -> bool:
        """
        Delete a workout.

        Args:
            workout_id: Workout UUID

        Returns:
            True on success
        """
        self.client.table("workouts").delete().eq("id", workout_id).execute()
        return True

    def get_workouts_by_date_range(
        self, user_id: str, start_date: str, end_date: str
    ) -> List[Dict[str, Any]]:
        """
        Get workouts in a date range.

        Args:
            user_id: User's UUID
            start_date: Start date (inclusive)
            end_date: End date (inclusive)

        Returns:
            List of workout records
        """
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
        """
        List only current (active) workouts for a user.

        Excludes superseded versions from SCD2.

        Args:
            user_id: User's UUID
            is_completed: Filter by completion status
            from_date: Filter from date
            to_date: Filter to date
            limit: Maximum results
            offset: Results to skip

        Returns:
            List of current workout records
        """
        query = (
            self.client.table("workouts")
            .select("*")
            .eq("user_id", user_id)
            .eq("is_current", True)
        )

        if is_completed is not None:
            query = query.eq("is_completed", is_completed)
        if from_date:
            query = query.gte("scheduled_date", from_date)
        if to_date:
            query = query.lte("scheduled_date", to_date)

        result = (
            query.order("scheduled_date", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        return result.data or []

    def get_workout_versions(self, workout_id: str) -> List[Dict[str, Any]]:
        """
        Get all versions of a workout (including the original).

        Returns versions ordered by version_number descending (newest first).

        Args:
            workout_id: Any workout ID in the version chain

        Returns:
            List of all versions
        """
        workout = self.get_workout(workout_id)
        if not workout:
            return []

        original_id = workout.get("parent_workout_id") or workout_id

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

        Args:
            old_workout_id: ID of workout to supersede
            new_workout_data: Data for the new version

        Returns:
            The new workout record

        Raises:
            ValueError: If old workout not found
        """
        now = datetime.utcnow().isoformat()

        old_workout = self.get_workout(old_workout_id)
        if not old_workout:
            raise ValueError(f"Workout {old_workout_id} not found")

        parent_id = old_workout.get("parent_workout_id") or old_workout_id
        old_version = old_workout.get("version_number", 1)

        new_workout_data["version_number"] = old_version + 1
        new_workout_data["is_current"] = True
        new_workout_data["valid_from"] = now
        new_workout_data["valid_to"] = None
        new_workout_data["parent_workout_id"] = parent_id
        new_workout_data["superseded_by"] = None

        new_workout = self.create_workout(new_workout_data)

        self.client.table("workouts").update(
            {"is_current": False, "valid_to": now, "superseded_by": new_workout["id"]}
        ).eq("id", old_workout_id).execute()

        return new_workout

    def revert_workout(self, workout_id: str, target_version: int) -> Dict[str, Any]:
        """
        Revert a workout to a previous version.

        Creates a new version with the content of the target version.
        Preserves full history (SCD2 style).

        Args:
            workout_id: Any workout ID in the version chain
            target_version: Version number to revert to

        Returns:
            The new (reverted) workout record

        Raises:
            ValueError: If versions not found
        """
        versions = self.get_workout_versions(workout_id)
        if not versions:
            raise ValueError(f"No versions found for workout {workout_id}")

        target_workout = None
        for v in versions:
            if v.get("version_number") == target_version:
                target_workout = v
                break

        if not target_workout:
            raise ValueError(f"Version {target_version} not found for workout {workout_id}")

        current_workout = None
        for v in versions:
            if v.get("is_current"):
                current_workout = v
                break

        if not current_workout:
            raise ValueError("No current version found")

        new_workout_data = {
            "user_id": target_workout["user_id"],
            "name": target_workout["name"],
            "type": target_workout["type"],
            "difficulty": target_workout["difficulty"],
            "scheduled_date": target_workout["scheduled_date"],
            "is_completed": False,
            "exercises_json": target_workout["exercises_json"],
            "duration_minutes": target_workout.get("duration_minutes", 45),
            "generation_method": "revert",
            "generation_source": f"reverted_from_v{target_version}",
            "generation_metadata": json.dumps(
                {
                    "reverted_from_version": target_version,
                    "reverted_from_id": target_workout["id"],
                    "reverted_at": datetime.utcnow().isoformat(),
                }
            ),
        }

        return self.supersede_workout(current_workout["id"], new_workout_data)

    def soft_delete_workout(self, workout_id: str) -> bool:
        """
        Soft delete a workout by marking it as not current.

        Unlike hard delete, this preserves history for potential recovery.

        Args:
            workout_id: Workout UUID

        Returns:
            True on success
        """
        now = datetime.utcnow().isoformat()
        self.client.table("workouts").update(
            {"is_current": False, "valid_to": now}
        ).eq("id", workout_id).execute()
        return True

    # ==================== WORKOUT LOGS ====================

    def get_workout_log(self, log_id: int) -> Optional[Dict[str, Any]]:
        """
        Get a workout log by ID.

        Args:
            log_id: Log record ID

        Returns:
            Workout log record or None
        """
        result = (
            self.client.table("workout_logs").select("*").eq("id", log_id).execute()
        )
        return result.data[0] if result.data else None

    def list_workout_logs(
        self, user_id: str, limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        List workout logs for a user.

        Args:
            user_id: User's UUID
            limit: Maximum logs to return

        Returns:
            List of workout log records
        """
        result = (
            self.client.table("workout_logs")
            .select("*")
            .eq("user_id", user_id)
            .order("completed_at", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []

    def create_workout_log(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a workout log.

        Args:
            data: Workout log data

        Returns:
            Created log record or None
        """
        result = self.client.table("workout_logs").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_workout_logs_by_workout(self, workout_id: str) -> bool:
        """
        Delete all workout logs for a workout.

        Args:
            workout_id: Workout UUID

        Returns:
            True on success
        """
        self.client.table("workout_logs").delete().eq("workout_id", workout_id).execute()
        return True

    def delete_workout_logs_by_user(self, user_id: str) -> bool:
        """
        Delete all workout logs for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("workout_logs").delete().eq("user_id", user_id).execute()
        return True

    # ==================== WORKOUT CHANGES ====================

    def list_workout_changes(
        self,
        workout_id: Optional[int] = None,
        user_id: Optional[int] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """
        List workout changes.

        Args:
            workout_id: Filter by workout (optional)
            user_id: Filter by user (optional)
            limit: Maximum records to return

        Returns:
            List of workout change records
        """
        query = self.client.table("workout_changes").select("*")

        if workout_id:
            query = query.eq("workout_id", workout_id)
        if user_id:
            query = query.eq("user_id", user_id)

        result = query.order("created_at", desc=True).limit(limit).execute()
        return result.data or []

    def create_workout_change(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a workout change record.

        Args:
            data: Change record data

        Returns:
            Created record or None
        """
        result = self.client.table("workout_changes").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_workout_changes_by_workout(self, workout_id: str) -> bool:
        """
        Delete all workout changes for a workout.

        Args:
            workout_id: Workout UUID

        Returns:
            True on success
        """
        self.client.table("workout_changes").delete().eq(
            "workout_id", workout_id
        ).execute()
        return True

    def delete_workout_changes_by_user(self, user_id: str) -> bool:
        """
        Delete all workout changes for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("workout_changes").delete().eq("user_id", user_id).execute()
        return True

    # ==================== WORKOUT EXITS ====================

    def create_workout_exit(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a workout exit log entry.

        Args:
            data: Exit log data

        Returns:
            Created record or None
        """
        result = self.client.table("workout_exits").insert(data).execute()
        return result.data[0] if result.data else None

    def list_workout_exits(
        self,
        user_id: str,
        workout_id: Optional[str] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """
        List workout exits for a user.

        Args:
            user_id: User's UUID
            workout_id: Filter by workout (optional)
            limit: Maximum records

        Returns:
            List of workout exit records
        """
        query = self.client.table("workout_exits").select("*").eq("user_id", user_id)
        if workout_id:
            query = query.eq("workout_id", workout_id)
        result = query.order("exited_at", desc=True).limit(limit).execute()
        return result.data or []

    def delete_workout_exits_by_user(self, user_id: str) -> bool:
        """
        Delete all workout exits for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("workout_exits").delete().eq("user_id", user_id).execute()
        return True

    # ==================== DRINK INTAKE ====================

    def create_drink_intake(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a drink intake log entry.

        Args:
            data: Drink intake data

        Returns:
            Created record or None
        """
        result = self.client.table("drink_intake_logs").insert(data).execute()
        return result.data[0] if result.data else None

    def list_drink_intakes(
        self,
        user_id: str,
        workout_log_id: Optional[str] = None,
        limit: int = 100,
    ) -> List[Dict[str, Any]]:
        """
        List drink intakes for a user.

        Args:
            user_id: User's UUID
            workout_log_id: Filter by workout log (optional)
            limit: Maximum records

        Returns:
            List of drink intake records
        """
        query = (
            self.client.table("drink_intake_logs").select("*").eq("user_id", user_id)
        )
        if workout_log_id:
            query = query.eq("workout_log_id", workout_log_id)
        result = query.order("logged_at", desc=True).limit(limit).execute()
        return result.data or []

    def get_workout_total_drink_intake(self, workout_log_id: str) -> int:
        """
        Get total drink intake for a workout in ml.

        Args:
            workout_log_id: Workout log ID

        Returns:
            Total ml consumed during workout
        """
        result = (
            self.client.table("drink_intake_logs")
            .select("amount_ml")
            .eq("workout_log_id", workout_log_id)
            .execute()
        )
        return sum(row.get("amount_ml", 0) for row in (result.data or []))

    def delete_drink_intakes_by_workout_log(self, workout_log_id: str) -> bool:
        """
        Delete all drink intakes for a workout log.

        Args:
            workout_log_id: Workout log ID

        Returns:
            True on success
        """
        self.client.table("drink_intake_logs").delete().eq(
            "workout_log_id", workout_log_id
        ).execute()
        return True

    def delete_drink_intakes_by_user(self, user_id: str) -> bool:
        """
        Delete all drink intakes for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("drink_intake_logs").delete().eq("user_id", user_id).execute()
        return True

    # ==================== REST INTERVALS ====================

    def create_rest_interval(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a rest interval log entry.

        Args:
            data: Rest interval data

        Returns:
            Created record or None
        """
        result = self.client.table("rest_intervals").insert(data).execute()
        return result.data[0] if result.data else None

    def list_rest_intervals(
        self,
        user_id: str,
        workout_log_id: Optional[str] = None,
        limit: int = 200,
    ) -> List[Dict[str, Any]]:
        """
        List rest intervals for a user.

        Args:
            user_id: User's UUID
            workout_log_id: Filter by workout log (optional)
            limit: Maximum records

        Returns:
            List of rest interval records
        """
        query = self.client.table("rest_intervals").select("*").eq("user_id", user_id)
        if workout_log_id:
            query = query.eq("workout_log_id", workout_log_id)
        result = query.order("logged_at", desc=True).limit(limit).execute()
        return result.data or []

    def get_workout_rest_stats(self, workout_log_id: str) -> Dict[str, Any]:
        """
        Get rest interval statistics for a workout.

        Args:
            workout_log_id: Workout log ID

        Returns:
            Dictionary with rest statistics
        """
        result = (
            self.client.table("rest_intervals")
            .select("rest_duration_seconds, rest_type")
            .eq("workout_log_id", workout_log_id)
            .execute()
        )
        intervals = result.data or []
        if not intervals:
            return {
                "total_rest_seconds": 0,
                "avg_rest_seconds": 0,
                "interval_count": 0,
                "between_sets_count": 0,
                "between_exercises_count": 0,
            }

        total = sum(i.get("rest_duration_seconds", 0) for i in intervals)
        between_sets = sum(1 for i in intervals if i.get("rest_type") == "between_sets")
        between_exercises = sum(
            1 for i in intervals if i.get("rest_type") == "between_exercises"
        )

        return {
            "total_rest_seconds": total,
            "avg_rest_seconds": total / len(intervals) if intervals else 0,
            "interval_count": len(intervals),
            "between_sets_count": between_sets,
            "between_exercises_count": between_exercises,
        }

    def delete_rest_intervals_by_workout_log(self, workout_log_id: str) -> bool:
        """
        Delete all rest intervals for a workout log.

        Args:
            workout_log_id: Workout log ID

        Returns:
            True on success
        """
        self.client.table("rest_intervals").delete().eq(
            "workout_log_id", workout_log_id
        ).execute()
        return True

    def delete_rest_intervals_by_user(self, user_id: str) -> bool:
        """
        Delete all rest intervals for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("rest_intervals").delete().eq("user_id", user_id).execute()
        return True
