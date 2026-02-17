"""
Analytics database operations.

Handles workout regeneration analytics including:
- Regeneration history tracking
- Custom workout inputs (focus areas, injuries)
- Equipment usage patterns
"""
from typing import Optional, List, Dict, Any
from datetime import datetime
import hashlib
import json

from core.db.base import BaseDB


class AnalyticsDB(BaseDB):
    """
    Database operations for workout regeneration analytics.

    Tracks user preferences, custom inputs, and equipment combinations
    for improving workout recommendations.
    """

    # ==================== WORKOUT REGENERATIONS ====================

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
        """
        Record a workout regeneration event for analytics.

        Also records custom inputs and equipment combinations.

        Args:
            user_id: User's UUID
            original_workout_id: ID of the original workout
            new_workout_id: ID of the new regenerated workout
            difficulty: Selected difficulty level
            duration_minutes: Selected duration
            workout_type: Selected workout type
            equipment: List of equipment selected
            focus_areas: List of focus areas
            injuries: List of injuries to consider
            custom_focus_area: Custom user-entered focus area
            custom_injury: Custom user-entered injury
            generation_method: Method used (ai, template, etc.)
            used_rag: Whether RAG was used
            generation_time_ms: Time taken to generate

        Returns:
            Created regeneration record or None
        """
        try:
            data = {
                "user_id": user_id,
                "original_workout_id": original_workout_id,
                "new_workout_id": new_workout_id,
                "selected_difficulty": difficulty,
                "selected_duration_minutes": duration_minutes,
                "selected_workout_type": workout_type,
                "selected_equipment": json.dumps(equipment or []),
                "selected_focus_areas": json.dumps(focus_areas or []),
                "selected_injuries": json.dumps(injuries or []),
                "custom_focus_area": custom_focus_area,
                "custom_injury": custom_injury,
                "generation_method": generation_method,
                "used_rag": used_rag,
                "generation_time_ms": generation_time_ms,
            }
            result = (
                self.client.table("workout_regenerations").insert(data).execute()
            )
            regeneration = result.data[0] if result.data else None

            # Record custom focus area if provided
            if custom_focus_area and custom_focus_area.strip():
                self._upsert_custom_input(
                    user_id, "focus_area", custom_focus_area.strip()
                )

            # Record custom injury if provided
            if custom_injury and custom_injury.strip():
                self._upsert_custom_input(user_id, "injury", custom_injury.strip())

            # Record equipment combination if provided
            if equipment and len(equipment) > 0:
                self._upsert_equipment_usage(user_id, equipment)

            return regeneration
        except Exception as e:
            print(f"Warning: Failed to record regeneration analytics: {e}")
            return None

    def _upsert_custom_input(
        self, user_id: str, input_type: str, input_value: str
    ) -> None:
        """
        Upsert a custom input (focus area or injury).

        Args:
            user_id: User's UUID
            input_type: Type of input (focus_area, injury)
            input_value: The custom value entered
        """
        try:
            existing = (
                self.client.table("custom_workout_inputs")
                .select("id, usage_count")
                .eq("user_id", user_id)
                .eq("input_type", input_type)
                .eq("input_value", input_value)
                .execute()
            )

            if existing.data:
                self.client.table("custom_workout_inputs").update(
                    {
                        "usage_count": existing.data[0]["usage_count"] + 1,
                        "last_used_at": datetime.utcnow().isoformat(),
                    }
                ).eq("id", existing.data[0]["id"]).execute()
            else:
                self.client.table("custom_workout_inputs").insert(
                    {
                        "user_id": user_id,
                        "input_type": input_type,
                        "input_value": input_value,
                    }
                ).execute()
        except Exception as e:
            print(f"Warning: Failed to upsert custom input: {e}")

    def _upsert_equipment_usage(self, user_id: str, equipment: List[str]) -> None:
        """
        Upsert an equipment usage record.

        Args:
            user_id: User's UUID
            equipment: List of equipment used
        """
        try:
            equipment_json = json.dumps(sorted(equipment))
            combination_hash = hashlib.md5(equipment_json.encode()).hexdigest()

            existing = (
                self.client.table("equipment_usage_analytics")
                .select("id, usage_count")
                .eq("user_id", user_id)
                .eq("combination_hash", combination_hash)
                .execute()
            )

            if existing.data:
                self.client.table("equipment_usage_analytics").update(
                    {
                        "usage_count": existing.data[0]["usage_count"] + 1,
                        "last_used_at": datetime.utcnow().isoformat(),
                    }
                ).eq("id", existing.data[0]["id"]).execute()
            else:
                self.client.table("equipment_usage_analytics").insert(
                    {
                        "user_id": user_id,
                        "equipment_combination": equipment_json,
                        "combination_hash": combination_hash,
                    }
                ).execute()
        except Exception as e:
            print(f"Warning: Failed to upsert equipment usage: {e}")

    def get_user_regeneration_analytics(
        self, user_id: str, limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Get regeneration history for a user.

        Args:
            user_id: User's UUID
            limit: Maximum records to return

        Returns:
            List of regeneration records
        """
        result = (
            self.client.table("workout_regenerations")
            .select(
                "id, user_id, original_workout_id, new_workout_id, "
                "selected_difficulty, selected_duration_minutes, selected_workout_type, "
                "selected_equipment, selected_focus_areas, generation_method, "
                "generation_time_ms, created_at"
            )
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []

    def get_latest_user_regeneration(
        self, user_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get the most recent regeneration entry for a user.

        Args:
            user_id: User's UUID

        Returns:
            Most recent regeneration record or None
        """
        result = (
            self.client.table("workout_regenerations")
            .select(
                "id, user_id, original_workout_id, new_workout_id, "
                "selected_difficulty, selected_duration_minutes, selected_workout_type, "
                "selected_equipment, selected_focus_areas, generation_method, "
                "generation_time_ms, created_at"
            )
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None

    def get_popular_custom_inputs(
        self, input_type: str, limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Get popular custom inputs across all users for suggestions.

        Args:
            input_type: Type of input (focus_area, injury)
            limit: Maximum records to return

        Returns:
            List of popular custom inputs
        """
        result = (
            self.client.table("custom_workout_inputs")
            .select("input_value, usage_count")
            .eq("input_type", input_type)
            .order("usage_count", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []

    def get_user_custom_inputs(
        self, user_id: str, input_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get custom inputs for a specific user.

        Args:
            user_id: User's UUID
            input_type: Filter by type (optional)

        Returns:
            List of user's custom inputs
        """
        query = (
            self.client.table("custom_workout_inputs")
            .select("*")
            .eq("user_id", user_id)
        )
        if input_type:
            query = query.eq("input_type", input_type)
        result = query.order("usage_count", desc=True).execute()
        return result.data or []

    def get_user_equipment_preferences(
        self, user_id: str, limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Get user's most used equipment combinations.

        Args:
            user_id: User's UUID
            limit: Maximum records to return

        Returns:
            List of equipment usage records
        """
        result = (
            self.client.table("equipment_usage_analytics")
            .select("*")
            .eq("user_id", user_id)
            .order("usage_count", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []
