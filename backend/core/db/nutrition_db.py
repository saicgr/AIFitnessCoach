"""
Nutrition database operations.

Handles all nutrition-related CRUD operations including:
- Food log management
- Daily and weekly nutrition summaries
- User nutrition targets
- Food analysis caching (for faster AI responses)
"""
import hashlib
import logging
import re
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta

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
        self, user_id: str, date: str, timezone_str: str | None = None
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
        self, user_id: str, start_date: str, timezone_str: str | None = None
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

    # ==================== FOOD ANALYSIS CACHING ====================

    @staticmethod
    def normalize_food_query(text: str) -> str:
        """
        Normalize a food description for consistent cache keys.

        Performs:
        - Lowercase conversion
        - Trim whitespace
        - Collapse multiple spaces to single space
        - Remove special characters (keep alphanumeric and spaces)

        Args:
            text: Raw food description

        Returns:
            Normalized text for hashing
        """
        # Lowercase and trim
        normalized = text.lower().strip()
        # Collapse multiple spaces
        normalized = re.sub(r'\s+', ' ', normalized)
        # Remove special characters but keep alphanumeric and spaces
        normalized = re.sub(r'[^a-z0-9\s]', '', normalized)
        return normalized

    @staticmethod
    def hash_query(text: str) -> str:
        """
        Create SHA256 hash of normalized text for cache key.

        Args:
            text: Normalized food description

        Returns:
            SHA256 hex digest
        """
        return hashlib.sha256(text.encode('utf-8')).hexdigest()

    def get_cached_food_analysis(
        self, query_hash: str
    ) -> Optional[Dict[str, Any]]:
        """
        Check cache for existing food analysis.

        Also updates hit_count and last_accessed_at on cache hit.

        Args:
            query_hash: SHA256 hash of normalized food description

        Returns:
            Cached analysis result (JSONB) or None if not found
        """
        try:
            result = (
                self.client.table("food_analysis_cache")
                .select("id, analysis_result, hit_count")
                .eq("query_hash", query_hash)
                .maybe_single()
                .execute()
            )

            if result and result.data:
                cache_entry = result.data
                # Update hit stats (fire and forget)
                try:
                    self.client.table("food_analysis_cache").update({
                        "hit_count": cache_entry.get("hit_count", 0) + 1,
                        "last_accessed_at": datetime.utcnow().isoformat()
                    }).eq("id", cache_entry["id"]).execute()
                except Exception as e:
                    logger.warning(f"Failed to update cache hit stats: {e}")

                logger.info(f"🎯 Cache HIT for food query (hash: {query_hash[:8]}...)")
                return cache_entry.get("analysis_result")

            return None

        except Exception as e:
            logger.error(f"Error checking food analysis cache: {e}")
            return None

    def cache_food_analysis(
        self,
        food_description: str,
        analysis_result: Dict[str, Any],
        model_version: str = "gemini-2.0-flash",
        prompt_version: str = "v1"
    ) -> bool:
        """
        Cache a food analysis result.

        Args:
            food_description: Original food description
            analysis_result: Full Gemini response as dict
            model_version: AI model version used
            prompt_version: Prompt template version

        Returns:
            True if cached successfully
        """
        try:
            normalized = self.normalize_food_query(food_description)
            query_hash = self.hash_query(normalized)

            self.client.table("food_analysis_cache").upsert({
                "query_hash": query_hash,
                "food_description": food_description,
                "analysis_result": analysis_result,
                "model_version": model_version,
                "prompt_version": prompt_version,
                "last_accessed_at": datetime.utcnow().isoformat(),
            }, on_conflict="query_hash").execute()

            logger.info(f"✅ Cached food analysis for: {food_description[:50]}...")
            return True

        except Exception as e:
            logger.error(f"Error caching food analysis: {e}")
            return False

    # ==================== COMMON FOODS DATABASE ====================

    def get_common_food(
        self, name: str, confidence_threshold: float = 0.8
    ) -> Optional[Dict[str, Any]]:
        """
        Search common foods database for a match.

        Searches by:
        1. Exact name match (case-insensitive)
        2. Alias array contains match

        Args:
            name: Food name to search
            confidence_threshold: Not used currently, for future fuzzy matching

        Returns:
            Common food record or None
        """
        try:
            normalized_name = name.lower().strip()

            # First try exact name match
            result = (
                self.client.table("common_foods")
                .select("*")
                .eq("is_active", True)
                .ilike("name", normalized_name)
                .maybe_single()
                .execute()
            )

            if result and result.data:
                logger.info(f"🎯 Common food EXACT match: {name}")
                return result.data

            # Try alias match using contains
            result = (
                self.client.table("common_foods")
                .select("*")
                .eq("is_active", True)
                .contains("aliases", [normalized_name])
                .maybe_single()
                .execute()
            )

            if result and result.data:
                logger.info(f"🎯 Common food ALIAS match: {name} -> {result.data.get('name')}")
                return result.data

            return None

        except Exception as e:
            logger.error(f"Error searching common foods: {e}")
            return None

    def list_common_foods(
        self, category: Optional[str] = None, limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        List common foods, optionally filtered by category.

        Args:
            category: Filter by category (e.g., 'indian', 'protein', 'fruit')
            limit: Maximum results

        Returns:
            List of common food records
        """
        try:
            query = (
                self.client.table("common_foods")
                .select("*")
                .eq("is_active", True)
            )

            if category:
                query = query.eq("category", category)

            result = query.order("name").limit(limit).execute()
            return result.data or []

        except Exception as e:
            logger.error(f"Error listing common foods: {e}")
            return []

    def upsert_learned_food(
        self,
        name: str,
        serving_size: str,
        serving_weight_g: float,
        calories: int,
        protein_g: float,
        carbs_g: float,
        fat_g: float,
        fiber_g: float = 0,
        micronutrients: Optional[Dict[str, Any]] = None,
        category: str = "general",
        source: str = "ai_learned",
        aliases: Optional[List[str]] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Insert or update a learned food in the common_foods table.

        If a food with the same name exists, it will only update if the new
        data has more non-null micronutrient fields. New aliases are appended
        without duplicating existing ones.

        Args:
            name: Food name
            serving_size: Human-readable serving size (e.g., "1 cup")
            serving_weight_g: Weight of one serving in grams
            calories: Calories per serving
            protein_g: Protein grams per serving
            carbs_g: Carbohydrate grams per serving
            fat_g: Fat grams per serving
            fiber_g: Fiber grams per serving
            micronutrients: JSONB dict of micronutrient values
            category: Food category
            source: Data source (default 'ai_learned')
            aliases: List of alternative names

        Returns:
            Upserted common food record or None on error
        """
        try:
            normalized_name = name.lower().strip()
            new_aliases = [a.lower().strip() for a in (aliases or [])]
            new_micros = micronutrients or {}

            # Check for existing entry by name
            existing = (
                self.client.table("common_foods")
                .select("*")
                .ilike("name", normalized_name)
                .maybe_single()
                .execute()
            )

            if existing and existing.data:
                # Update only if new data has more micronutrient fields
                existing_micros = existing.data.get("micronutrients") or {}
                existing_non_null = sum(
                    1 for v in existing_micros.values() if v is not None
                )
                new_non_null = sum(
                    1 for v in new_micros.values() if v is not None
                )

                if new_non_null <= existing_non_null:
                    logger.info(
                        f"Skipping update for '{name}': existing has "
                        f"{existing_non_null} micros vs new {new_non_null}"
                    )
                    return existing.data

                # Merge aliases without duplicates
                existing_aliases = existing.data.get("aliases") or []
                merged_aliases = list(
                    dict.fromkeys(existing_aliases + new_aliases)
                )

                update_data = {
                    "serving_size": serving_size,
                    "serving_weight_g": serving_weight_g,
                    "calories": calories,
                    "protein_g": protein_g,
                    "carbs_g": carbs_g,
                    "fat_g": fat_g,
                    "fiber_g": fiber_g,
                    "micronutrients": new_micros,
                    "category": category,
                    "source": source,
                    "aliases": merged_aliases,
                    "updated_at": datetime.utcnow().isoformat(),
                }

                result = (
                    self.client.table("common_foods")
                    .update(update_data)
                    .eq("id", existing.data["id"])
                    .execute()
                )
                logger.info(f"✅ Updated learned food: {name}")
                return result.data[0] if result.data else None

            # Insert new entry
            insert_data = {
                "name": normalized_name,
                "serving_size": serving_size,
                "serving_weight_g": serving_weight_g,
                "calories": calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "micronutrients": new_micros,
                "category": category,
                "source": source,
                "aliases": new_aliases,
                "is_active": True,
            }

            result = (
                self.client.table("common_foods")
                .insert(insert_data)
                .execute()
            )
            logger.info(f"✅ Inserted new learned food: {name}")
            return result.data[0] if result.data else None

        except Exception as e:
            logger.error(f"Error upserting learned food '{name}': {e}")
            return None

    # ==================== RAG CONTEXT CACHING ====================

    def get_cached_rag_context(
        self, goal_hash: str
    ) -> Optional[Dict[str, Any]]:
        """
        Check cache for RAG context by goal hash.

        Args:
            goal_hash: SHA256 hash of user goals/preferences

        Returns:
            Cached RAG context or None if not found/expired
        """
        try:
            result = (
                self.client.table("rag_context_cache")
                .select("id, context_result, hit_count, expires_at")
                .eq("goal_hash", goal_hash)
                .maybe_single()
                .execute()
            )

            if result and result.data:
                cache_entry = result.data

                # Check if expired
                expires_at = cache_entry.get("expires_at")
                if expires_at:
                    expiry_time = datetime.fromisoformat(
                        expires_at.replace('Z', '+00:00')
                    )
                    if datetime.now(expiry_time.tzinfo) > expiry_time:
                        logger.info(f"RAG cache expired for hash: {goal_hash[:8]}...")
                        return None

                # Update hit stats
                try:
                    self.client.table("rag_context_cache").update({
                        "hit_count": cache_entry.get("hit_count", 0) + 1,
                        "last_accessed_at": datetime.utcnow().isoformat()
                    }).eq("id", cache_entry["id"]).execute()
                except Exception as e:
                    logger.warning(f"Failed to update RAG cache hit stats: {e}")

                logger.info(f"🎯 RAG cache HIT for goal hash: {goal_hash[:8]}...")
                return cache_entry.get("context_result")

            return None

        except Exception as e:
            logger.error(f"Error checking RAG context cache: {e}")
            return None

    def cache_rag_context(
        self,
        goal_hash: str,
        context_result: Dict[str, Any],
        ttl_hours: int = 1
    ) -> bool:
        """
        Cache RAG context for a user goal hash.

        Args:
            goal_hash: SHA256 hash of user goals/preferences
            context_result: RAG context documents/embeddings info
            ttl_hours: Time-to-live in hours (default 1 hour)

        Returns:
            True if cached successfully
        """
        try:
            expires_at = datetime.utcnow() + timedelta(hours=ttl_hours)

            self.client.table("rag_context_cache").upsert({
                "goal_hash": goal_hash,
                "context_result": context_result,
                "expires_at": expires_at.isoformat(),
                "last_accessed_at": datetime.utcnow().isoformat(),
            }, on_conflict="goal_hash").execute()

            logger.info(f"✅ Cached RAG context for goal hash: {goal_hash[:8]}...")
            return True

        except Exception as e:
            logger.error(f"Error caching RAG context: {e}")
            return False

    @staticmethod
    def create_goal_hash(user_goals: Dict[str, Any]) -> str:
        """
        Create a hash from user nutrition goals for RAG caching.

        Args:
            user_goals: Dict with keys like 'goal', 'target_calories', etc.

        Returns:
            SHA256 hash of sorted goal string
        """
        # Sort keys for consistent hashing
        sorted_goals = sorted(user_goals.items())
        goal_str = str(sorted_goals)
        return hashlib.sha256(goal_str.encode('utf-8')).hexdigest()
