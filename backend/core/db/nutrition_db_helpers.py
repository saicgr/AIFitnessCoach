"""Helper functions extracted from nutrition_db.
Nutrition database operations.

Handles all nutrition-related CRUD operations including:
- Food log management
- Daily and weekly nutrition summaries
- User nutrition targets
- Food analysis caching (for faster AI responses)


"""
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import logging
from core.db.base import BaseDB

logger = logging.getLogger(__name__)


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
        logged_at: Optional[str] = None,
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
        # Image storage fields
        image_url: Optional[str] = None,
        image_storage_key: Optional[str] = None,
        source_type: str = "text",
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
            image_url: S3 URL of the food image (for image-based logs)
            image_storage_key: S3 storage key for the image
            source_type: 'text' or 'image' indicating how the food was logged

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
            "source_type": source_type,
        }

        # Set explicit logged_at timestamp if provided (timezone-aware)
        if logged_at:
            data["logged_at"] = logged_at

        # Add image fields if provided
        if image_url:
            data["image_url"] = image_url
        if image_storage_key:
            data["image_storage_key"] = image_storage_key

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
        result = self.client.table("food_logs").select("*").eq("id", log_id).is_("deleted_at", "null").execute()
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
        query = self.client.table("food_logs").select(
            "id, user_id, meal_type, food_items, total_calories, protein_g, "
            "carbs_g, fat_g, fiber_g, ai_feedback, health_score, logged_at, "
            "source_type, image_url"
        ).eq("user_id", user_id).is_("deleted_at", "null")

        if from_date:
            query = query.gte("logged_at", from_date)
        if to_date:
            query = query.lte("logged_at", to_date)
        if meal_type:
            query = query.eq("meal_type", meal_type)

        result = query.order("logged_at", desc=True).limit(limit).execute()
        return result.data or []

    def update_food_log(
        self,
        log_id: str,
        user_id: str,
        total_calories: int,
        protein_g: float,
        carbs_g: float,
        fat_g: float,
        fiber_g: Optional[float] = None,
        weight_g: Optional[float] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Update macros on an existing food log.

        Args:
            log_id: Food log UUID
            user_id: Owner's UUID (for authorization check)
            total_calories: Updated calorie total
            protein_g: Updated protein grams
            carbs_g: Updated carb grams
            fat_g: Updated fat grams
            fiber_g: Updated fiber grams (optional)
            weight_g: Updated weight grams (optional)

        Returns:
            Updated food log record, or None if not found / not owned
        """
        update_data: Dict[str, Any] = {
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "updated_at": datetime.utcnow().isoformat(),
        }
        if fiber_g is not None:
            update_data["fiber_g"] = fiber_g
        if weight_g is not None:
            update_data["weight_g"] = weight_g

        result = (
            self.client.table("food_logs")
            .update(update_data)
            .eq("id", log_id)
            .eq("user_id", user_id)
            .is_("deleted_at", "null")
            .execute()
        )
        return result.data[0] if result.data else None

    def delete_food_log(self, log_id: str) -> bool:
        """
        Soft-delete a food log entry (SCD2 pattern).

        Sets deleted_at timestamp instead of removing the row.

        Args:
            log_id: Food log UUID

        Returns:
            True on success
        """
        self.client.table("food_logs") \
            .update({"deleted_at": datetime.utcnow().isoformat()}) \
            .eq("id", log_id) \
            .execute()
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
        self, user_id: str, date: str, timezone_str: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get nutrition totals for a specific day.

        Args:
            user_id: User's UUID
            date: Date in YYYY-MM-DD format
            timezone_str: IANA timezone (e.g. 'America/Los_Angeles').
                          When provided, the day boundaries are computed in the
                          user's local timezone then converted to UTC for querying.

        Returns:
            Dictionary with nutrition totals and meal breakdown
        """
        if timezone_str:
            from core.timezone_utils import local_date_to_utc_range
            start_of_day, end_of_day = local_date_to_utc_range(date, timezone_str)
        else:
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
        self, user_id: str, start_date: str, timezone_str: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get nutrition totals for a week starting from start_date.

        Args:
            user_id: User's UUID
            start_date: Start date in YYYY-MM-DD format
            timezone_str: IANA timezone for day-boundary resolution

        Returns:
            List of daily nutrition summaries
        """
        start = datetime.fromisoformat(start_date)
        summaries = []

        for i in range(7):
            day = (start + timedelta(days=i)).strftime("%Y-%m-%d")
            summary = self.get_daily_nutrition_summary(user_id, day, timezone_str=timezone_str)
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
            # Sync to nutrition_preferences for consistency
            try:
                prefs_sync = {}
                if daily_calorie_target is not None:
                    prefs_sync["target_calories"] = daily_calorie_target
                if daily_protein_target_g is not None:
                    prefs_sync["target_protein_g"] = daily_protein_target_g
                if daily_carbs_target_g is not None:
                    prefs_sync["target_carbs_g"] = daily_carbs_target_g
                if daily_fat_target_g is not None:
                    prefs_sync["target_fat_g"] = daily_fat_target_g
                if prefs_sync:
                    self.client.table("nutrition_preferences").update(prefs_sync).eq("user_id", user_id).execute()
            except Exception as e:
                logger.warning(f"Failed to sync targets to nutrition_preferences: {e}")
            return result.data[0] if result.data else None
        return None

    def get_user_nutrition_targets(self, user_id: str) -> Dict[str, Any]:
        """
        Get user's daily nutrition targets.

        First tries nutrition_preferences table (where calculate_nutrition_metrics saves),
        then falls back to users table for legacy data.

        Args:
            user_id: User's UUID

        Returns:
            Dictionary with nutrition targets
        """
        # Default empty response
        empty_response = {
            "daily_calorie_target": None,
            "daily_protein_target_g": None,
            "daily_carbs_target_g": None,
            "daily_fat_target_g": None,
        }

        try:
            # First try nutrition_preferences (where calculated metrics are stored)
            result = (
                self.client.table("nutrition_preferences")
                .select("target_calories, target_protein_g, target_carbs_g, target_fat_g")
                .eq("user_id", user_id)
                .maybe_single()
                .execute()
            )
            if result and result.data:
                prefs = result.data
                return {
                    "daily_calorie_target": prefs.get("target_calories"),
                    "daily_protein_target_g": prefs.get("target_protein_g"),
                    "daily_carbs_target_g": prefs.get("target_carbs_g"),
                    "daily_fat_target_g": prefs.get("target_fat_g"),
                }
        except Exception as e:
            logger.warning(f"Error fetching nutrition_preferences for {user_id}: {e}")

        try:
            # Fallback to users table for legacy data
            result = (
                self.client.table("users")
                .select(
                    "daily_calorie_target, daily_protein_target_g, "
                    "daily_carbs_target_g, daily_fat_target_g"
                )
                .eq("id", user_id)
                .maybe_single()
                .execute()
            )
            if result and result.data:
                return result.data
        except Exception as e:
            logger.warning(f"Error fetching user nutrition targets for {user_id}: {e}")

        return empty_response

    def enrich_user_with_nutrition_targets(self, user_dict: dict) -> dict:
        """Overlay nutrition_preferences targets onto user dict.

        Ensures user dict always has the latest targets from nutrition_preferences
        (the source of truth), falling back to whatever is already in user_dict.
        """
        if not user_dict or not user_dict.get("id"):
            return user_dict
        try:
            targets = self.get_user_nutrition_targets(user_dict["id"])
            if targets:
                for col, val in targets.items():
                    if val is not None:
                        user_dict[col] = val
        except Exception as e:
            logger.warning(f"Failed to enrich user nutrition targets: {e}")
        return user_dict

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
        query = self.client.table("weight_logs").select(
            "id, user_id, weight_kg, logged_at, source, notes"
        ).eq("user_id", user_id)

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

