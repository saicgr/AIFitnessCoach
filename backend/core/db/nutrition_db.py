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
        # Micronutrients
        sodium_mg: Optional[float] = None,
        sugar_g: Optional[float] = None,
        saturated_fat_g: Optional[float] = None,
        cholesterol_mg: Optional[float] = None,
        potassium_mg: Optional[float] = None,
        vitamin_a_ug: Optional[float] = None,
        vitamin_c_mg: Optional[float] = None,
        vitamin_d_iu: Optional[float] = None,
        vitamin_e_mg: Optional[float] = None,
        vitamin_k_ug: Optional[float] = None,
        vitamin_b1_mg: Optional[float] = None,
        vitamin_b2_mg: Optional[float] = None,
        vitamin_b3_mg: Optional[float] = None,
        vitamin_b5_mg: Optional[float] = None,
        vitamin_b6_mg: Optional[float] = None,
        vitamin_b7_ug: Optional[float] = None,
        vitamin_b9_ug: Optional[float] = None,
        vitamin_b12_ug: Optional[float] = None,
        calcium_mg: Optional[float] = None,
        iron_mg: Optional[float] = None,
        magnesium_mg: Optional[float] = None,
        zinc_mg: Optional[float] = None,
        phosphorus_mg: Optional[float] = None,
        copper_mg: Optional[float] = None,
        manganese_mg: Optional[float] = None,
        selenium_ug: Optional[float] = None,
        choline_mg: Optional[float] = None,
        omega3_g: Optional[float] = None,
        omega6_g: Optional[float] = None,
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
            + micronutrients: vitamins, minerals, etc.

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

        # Add micronutrients if provided (only include non-None values)
        micronutrients = {
            "sodium_mg": sodium_mg,
            "sugar_g": sugar_g,
            "saturated_fat_g": saturated_fat_g,
            "cholesterol_mg": cholesterol_mg,
            "potassium_mg": potassium_mg,
            "vitamin_a_ug": vitamin_a_ug,
            "vitamin_c_mg": vitamin_c_mg,
            "vitamin_d_iu": vitamin_d_iu,
            "vitamin_e_mg": vitamin_e_mg,
            "vitamin_k_ug": vitamin_k_ug,
            "vitamin_b1_mg": vitamin_b1_mg,
            "vitamin_b2_mg": vitamin_b2_mg,
            "vitamin_b3_mg": vitamin_b3_mg,
            "vitamin_b5_mg": vitamin_b5_mg,
            "vitamin_b6_mg": vitamin_b6_mg,
            "vitamin_b7_ug": vitamin_b7_ug,
            "vitamin_b9_ug": vitamin_b9_ug,
            "vitamin_b12_ug": vitamin_b12_ug,
            "calcium_mg": calcium_mg,
            "iron_mg": iron_mg,
            "magnesium_mg": magnesium_mg,
            "zinc_mg": zinc_mg,
            "phosphorus_mg": phosphorus_mg,
            "copper_mg": copper_mg,
            "manganese_mg": manganese_mg,
            "selenium_ug": selenium_ug,
            "choline_mg": choline_mg,
            "omega3_g": omega3_g,
            "omega6_g": omega6_g,
        }

        # Only add non-None micronutrients to data
        for key, value in micronutrients.items():
            if value is not None:
                data[key] = value

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

    # ==================== WEIGHT LOGS ====================

    def create_weight_log(
        self,
        user_id: str,
        weight_kg: float,
        logged_at: Optional[datetime] = None,
        source: str = "manual",
        notes: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a weight log entry.

        Args:
            user_id: User's UUID
            weight_kg: Weight in kilograms
            logged_at: When the weight was logged (defaults to now)
            source: Source of the weight log (manual, apple_health, etc.)
            notes: Optional notes

        Returns:
            Created weight log record or None
        """
        data = {
            "user_id": user_id,
            "weight_kg": weight_kg,
            "logged_at": (logged_at or datetime.utcnow()).isoformat(),
            "source": source,
            "notes": notes,
        }
        result = self.client.table("weight_logs").insert(data).execute()
        return result.data[0] if result.data else None

    def get_weight_logs(
        self,
        user_id: str,
        limit: int = 30,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get weight logs for a user.

        Args:
            user_id: User's UUID
            limit: Maximum records to return
            from_date: Filter from date
            to_date: Filter to date

        Returns:
            List of weight log records ordered by date (newest first)
        """
        query = self.client.table("weight_logs").select("*").eq("user_id", user_id)

        if from_date:
            query = query.gte("logged_at", from_date)
        if to_date:
            query = query.lte("logged_at", to_date)

        result = query.order("logged_at", desc=True).limit(limit).execute()
        return result.data or []

    def delete_weight_log(self, log_id: str, user_id: str) -> bool:
        """
        Delete a weight log entry.

        Args:
            log_id: Weight log UUID
            user_id: User's UUID (for verification)

        Returns:
            True if deleted
        """
        result = (
            self.client.table("weight_logs")
            .delete()
            .eq("id", log_id)
            .eq("user_id", user_id)
            .execute()
        )
        return len(result.data or []) > 0

    # ==================== NUTRITION PREFERENCES ====================

    def get_nutrition_preferences(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get nutrition preferences for a user.

        Args:
            user_id: User's UUID

        Returns:
            Nutrition preferences record or None
        """
        result = (
            self.client.table("nutrition_preferences")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def upsert_nutrition_preferences(
        self, user_id: str, preferences: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Create or update nutrition preferences.

        Args:
            user_id: User's UUID
            preferences: Preferences data

        Returns:
            Created/updated preferences record
        """
        data = {"user_id": user_id, **preferences}
        result = (
            self.client.table("nutrition_preferences")
            .upsert(data, on_conflict="user_id")
            .execute()
        )
        return result.data[0] if result.data else None

    # ==================== NUTRITION STREAKS ====================

    def get_nutrition_streak(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get nutrition streak for a user.

        Args:
            user_id: User's UUID

        Returns:
            Streak record or None
        """
        result = (
            self.client.table("nutrition_streaks")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def upsert_nutrition_streak(
        self, user_id: str, streak_data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Create or update nutrition streak.

        Args:
            user_id: User's UUID
            streak_data: Streak data to update

        Returns:
            Created/updated streak record
        """
        data = {"user_id": user_id, **streak_data}
        result = (
            self.client.table("nutrition_streaks")
            .upsert(data, on_conflict="user_id")
            .execute()
        )
        return result.data[0] if result.data else None

    # ==================== ADAPTIVE NUTRITION ====================

    def get_latest_adaptive_calculation(
        self, user_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get the most recent adaptive TDEE calculation for a user.

        Args:
            user_id: User's UUID

        Returns:
            Latest calculation record or None
        """
        result = (
            self.client.table("adaptive_nutrition_calculations")
            .select("*")
            .eq("user_id", user_id)
            .order("calculated_at", desc=True)
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None

    def create_adaptive_calculation(
        self, user_id: str, calculation_data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Create a new adaptive TDEE calculation record.

        Args:
            user_id: User's UUID
            calculation_data: Calculation results

        Returns:
            Created calculation record
        """
        data = {"user_id": user_id, **calculation_data}
        result = (
            self.client.table("adaptive_nutrition_calculations")
            .insert(data)
            .execute()
        )
        return result.data[0] if result.data else None

    # ==================== WEEKLY RECOMMENDATIONS ====================

    def get_weekly_recommendation(
        self, recommendation_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get a weekly nutrition recommendation by ID.

        Args:
            recommendation_id: Recommendation UUID

        Returns:
            Recommendation record or None
        """
        result = (
            self.client.table("weekly_nutrition_recommendations")
            .select("*")
            .eq("id", recommendation_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def get_pending_recommendations(
        self, user_id: str
    ) -> List[Dict[str, Any]]:
        """
        Get pending (not yet responded to) recommendations for a user.

        Args:
            user_id: User's UUID

        Returns:
            List of pending recommendations
        """
        result = (
            self.client.table("weekly_nutrition_recommendations")
            .select("*")
            .eq("user_id", user_id)
            .is_("user_accepted", "null")
            .order("created_at", desc=True)
            .execute()
        )
        return result.data or []

    def create_weekly_recommendation(
        self, user_id: str, recommendation_data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Create a new weekly nutrition recommendation.

        Args:
            user_id: User's UUID
            recommendation_data: Recommendation details

        Returns:
            Created recommendation record
        """
        data = {"user_id": user_id, **recommendation_data}
        result = (
            self.client.table("weekly_nutrition_recommendations")
            .insert(data)
            .execute()
        )
        return result.data[0] if result.data else None

    def update_recommendation_response(
        self, recommendation_id: str, accepted: bool
    ) -> Optional[Dict[str, Any]]:
        """
        Update user response to a recommendation.

        Args:
            recommendation_id: Recommendation UUID
            accepted: Whether the user accepted the recommendation

        Returns:
            Updated recommendation record
        """
        result = (
            self.client.table("weekly_nutrition_recommendations")
            .update({"user_accepted": accepted})
            .eq("id", recommendation_id)
            .execute()
        )
        return result.data[0] if result.data else None
