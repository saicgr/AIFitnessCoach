"""
Nutrition database operations.

Handles all nutrition-related CRUD operations including:
- Food log management
- Daily and weekly nutrition summaries
- User nutrition targets
"""
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta

from core.db.base import BaseDB


class NutritionDB(BaseDB):
    """
    Database operations for nutrition tracking.

    Handles food logs, nutrition summaries, and user dietary targets.
    """

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
        ai_feedback: Optional[str] = None,
        health_score: Optional[int] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a food log entry from AI analysis.

        Args:
            user_id: User's UUID
            meal_type: Type of meal (breakfast, lunch, dinner, snack)
            food_items: List of food items consumed
            total_calories: Total calories in the meal
            protein_g: Grams of protein
            carbs_g: Grams of carbohydrates
            fat_g: Grams of fat
            fiber_g: Grams of fiber
            ai_feedback: AI-generated feedback on the meal
            health_score: Health score (0-100)

        Returns:
            Created food log record or None
        """
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
        """
        Get a food log by ID.

        Args:
            log_id: Food log UUID

        Returns:
            Food log record or None
        """
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
        """
        List food logs for a user with optional filters.

        Args:
            user_id: User's UUID
            from_date: Filter from date
            to_date: Filter to date
            meal_type: Filter by meal type
            limit: Maximum records to return

        Returns:
            List of food log records
        """
        query = self.client.table("food_logs").select("*").eq("user_id", user_id)

        if from_date:
            query = query.gte("logged_at", from_date)
        if to_date:
            query = query.lte("logged_at", to_date)
        if meal_type:
            query = query.eq("meal_type", meal_type)

        result = query.order("logged_at", desc=True).limit(limit).execute()
        return result.data or []

    def delete_food_log(self, log_id: str) -> bool:
        """
        Delete a food log entry.

        Args:
            log_id: Food log UUID

        Returns:
            True on success
        """
        self.client.table("food_logs").delete().eq("id", log_id).execute()
        return True

    def delete_food_logs_by_user(self, user_id: str) -> bool:
        """
        Delete all food logs for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("food_logs").delete().eq("user_id", user_id).execute()
        return True

    # ==================== NUTRITION SUMMARIES ====================

    def get_daily_nutrition_summary(
        self, user_id: str, date: str
    ) -> Dict[str, Any]:
        """
        Get nutrition totals for a specific day.

        Args:
            user_id: User's UUID
            date: Date in YYYY-MM-DD format

        Returns:
            Dictionary with nutrition totals and meal breakdown
        """
        start_of_day = f"{date}T00:00:00"
        end_of_day = f"{date}T23:59:59"

        logs = self.list_food_logs(
            user_id, from_date=start_of_day, to_date=end_of_day, limit=100
        )

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

    def get_weekly_nutrition_summary(
        self, user_id: str, start_date: str
    ) -> List[Dict[str, Any]]:
        """
        Get nutrition totals for a week starting from start_date.

        Args:
            user_id: User's UUID
            start_date: Start date in YYYY-MM-DD format

        Returns:
            List of daily nutrition summaries
        """
        start = datetime.fromisoformat(start_date)
        summaries = []

        for i in range(7):
            day = (start + timedelta(days=i)).strftime("%Y-%m-%d")
            summary = self.get_daily_nutrition_summary(user_id, day)
            summaries.append(summary)

        return summaries

    # ==================== USER NUTRITION TARGETS ====================

    def update_user_nutrition_targets(
        self,
        user_id: str,
        daily_calorie_target: Optional[int] = None,
        daily_protein_target_g: Optional[float] = None,
        daily_carbs_target_g: Optional[float] = None,
        daily_fat_target_g: Optional[float] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Update user's daily nutrition targets.

        Args:
            user_id: User's UUID
            daily_calorie_target: Daily calorie goal
            daily_protein_target_g: Daily protein goal in grams
            daily_carbs_target_g: Daily carbs goal in grams
            daily_fat_target_g: Daily fat goal in grams

        Returns:
            Updated user record or None
        """
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
            result = (
                self.client.table("users").update(data).eq("id", user_id).execute()
            )
            return result.data[0] if result.data else None
        return None

    def get_user_nutrition_targets(self, user_id: str) -> Dict[str, Any]:
        """
        Get user's daily nutrition targets.

        Args:
            user_id: User's UUID

        Returns:
            Dictionary with nutrition targets
        """
        result = (
            self.client.table("users")
            .select(
                "daily_calorie_target, daily_protein_target_g, "
                "daily_carbs_target_g, daily_fat_target_g"
            )
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
