"""
Activity database operations.

Handles daily activity and health metrics from:
- Health Connect (Android)
- Apple Health (iOS)
"""
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta

from core.db.base import BaseDB


class ActivityDB(BaseDB):
    """
    Database operations for daily activity tracking.

    Handles steps, calories, distance, heart rate, and other
    health metrics from mobile health platforms.
    """

    # ==================== DAILY ACTIVITY ====================

    def upsert_daily_activity(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Upsert daily activity data (from Health Connect / Apple Health).

        Uses activity_date + user_id as unique key.

        Args:
            data: Activity data including user_id, activity_date,
                  steps, calories_burned, distance_meters, etc.

        Returns:
            Upserted activity record or None
        """
        # Ensure activity_date is a string
        if isinstance(data.get("activity_date"), datetime):
            data["activity_date"] = data["activity_date"].strftime("%Y-%m-%d")

        result = self.client.table("daily_activity").upsert(
            data, on_conflict="user_id,activity_date"
        ).execute()
        return result.data[0] if result.data else None

    def get_daily_activity(
        self, user_id: str, activity_date: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get daily activity for a specific date.

        Args:
            user_id: User's UUID
            activity_date: Date in YYYY-MM-DD format

        Returns:
            Activity record or None
        """
        result = (
            self.client.table("daily_activity")
            .select(
                "id, user_id, activity_date, steps, calories_burned, "
                "distance_meters, active_minutes, resting_heart_rate, "
                "avg_heart_rate, sleep_hours, source"
            )
            .eq("user_id", user_id)
            .eq("activity_date", activity_date)
            .execute()
        )
        return result.data[0] if result.data else None

    def list_daily_activity(
        self,
        user_id: str,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
        limit: int = 30,
    ) -> List[Dict[str, Any]]:
        """
        List daily activity for a user within a date range.

        Args:
            user_id: User's UUID
            from_date: Start date filter
            to_date: End date filter
            limit: Maximum records to return

        Returns:
            List of daily activity records
        """
        query = (
            self.client.table("daily_activity").select(
                "id, user_id, activity_date, steps, calories_burned, "
                "distance_meters, active_minutes, resting_heart_rate, "
                "avg_heart_rate, sleep_hours, source"
            ).eq("user_id", user_id)
        )

        if from_date:
            query = query.gte("activity_date", from_date)
        if to_date:
            query = query.lte("activity_date", to_date)

        result = query.order("activity_date", desc=True).limit(limit).execute()
        return result.data or []

    def get_activity_summary(
        self, user_id: str, days: int = 7
    ) -> Dict[str, Any]:
        """
        Get activity summary (totals and averages) for the last N days.

        Args:
            user_id: User's UUID
            days: Number of days to include

        Returns:
            Dictionary with activity statistics
        """
        end_date = datetime.utcnow().strftime("%Y-%m-%d")
        start_date = (datetime.utcnow() - timedelta(days=days)).strftime("%Y-%m-%d")

        activities = self.list_daily_activity(
            user_id=user_id,
            from_date=start_date,
            to_date=end_date,
            limit=days,
        )

        if not activities:
            return {
                "total_steps": 0,
                "total_calories": 0,
                "total_distance_meters": 0,
                "avg_steps": 0,
                "avg_calories": 0,
                "avg_resting_hr": None,
                "days_with_data": 0,
            }

        total_steps = sum(a.get("steps", 0) or 0 for a in activities)
        total_calories = sum(a.get("calories_burned", 0) or 0 for a in activities)
        total_distance = sum(a.get("distance_meters", 0) or 0 for a in activities)
        days_with_data = len(activities)

        # Calculate average resting HR (only from days with data)
        hr_values = [
            a.get("resting_heart_rate")
            for a in activities
            if a.get("resting_heart_rate")
        ]
        avg_resting_hr = round(sum(hr_values) / len(hr_values)) if hr_values else None

        return {
            "total_steps": total_steps,
            "total_calories": round(total_calories, 1),
            "total_distance_meters": round(total_distance, 1),
            "avg_steps": round(total_steps / days_with_data) if days_with_data > 0 else 0,
            "avg_calories": (
                round(total_calories / days_with_data, 1) if days_with_data > 0 else 0
            ),
            "avg_resting_hr": avg_resting_hr,
            "days_with_data": days_with_data,
        }

    def delete_daily_activity(self, user_id: str, activity_date: str) -> bool:
        """
        Delete a specific daily activity entry.

        Args:
            user_id: User's UUID
            activity_date: Date in YYYY-MM-DD format

        Returns:
            True on success
        """
        self.client.table("daily_activity").delete().eq("user_id", user_id).eq(
            "activity_date", activity_date
        ).execute()
        return True

    def delete_daily_activity_by_user(self, user_id: str) -> bool:
        """
        Delete all daily activity for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("daily_activity").delete().eq("user_id", user_id).execute()
        return True
