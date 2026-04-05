"""
Nutrition Logging Mixin
=======================
Nutrition preferences, meal templates, food search, AI tips,
compact view, and adaptive TDEE event logging.
"""

from datetime import datetime
from typing import Optional, List, Dict, Any
import logging

from services.user_context.models import EventType

logger = logging.getLogger(__name__)


class NutritionLoggingMixin:
    """Mixin for nutrition-related event logging."""

    async def log_nutrition_preferences_updated(self, user_id: str, disable_ai_tips: Optional[bool] = None, quick_log_mode: Optional[bool] = None, compact_tracker_view: Optional[bool] = None, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user updates their nutrition preferences."""
        event_data = {"disable_ai_tips": disable_ai_tips, "quick_log_mode": quick_log_mode, "compact_tracker_view": compact_tracker_view, "updated_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version, screen_name="nutrition_preferences", extra_context={"nutrition_tracking_version": "1.0"})
        logger.info(f"[Nutrition Preferences Updated] User {user_id}: ai_tips_disabled={disable_ai_tips}, quick_log={quick_log_mode}, compact_view={compact_tracker_view}")
        return await self.log_event(user_id=user_id, event_type=EventType.NUTRITION_PREFERENCES_UPDATED, event_data=event_data, context=context)

    async def log_nutrition_preferences_reset(self, user_id: str, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user resets their nutrition preferences to defaults."""
        event_data = {"reset_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version, screen_name="nutrition_preferences", extra_context={"nutrition_tracking_version": "1.0"})
        logger.info(f"[Nutrition Preferences Reset] User {user_id}: preferences reset to defaults")
        return await self.log_event(user_id=user_id, event_type=EventType.NUTRITION_PREFERENCES_RESET, event_data=event_data, context=context)

    async def log_quick_log_used(self, user_id: str, food_name: str, meal_type: str, calories: int, servings: float = 1.0, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user uses the quick log feature."""
        event_data = {"food_name": food_name, "meal_type": meal_type, "calories": calories, "servings": servings, "logged_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version, screen_name="nutrition_quick_log", extra_context={"nutrition_tracking_version": "1.0"})
        logger.info(f"[Quick Log Used] User {user_id}: {food_name} ({calories} cal) for {meal_type}, servings={servings}")
        return await self.log_event(user_id=user_id, event_type=EventType.QUICK_LOG_USED, event_data=event_data, context=context)

    async def log_meal_template_created(self, user_id: str, template_name: str, total_calories: int, food_count: int, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user creates a meal template."""
        event_data = {"template_name": template_name, "total_calories": total_calories, "food_count": food_count, "created_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version, screen_name="nutrition_templates", extra_context={"nutrition_tracking_version": "1.0"})
        logger.info(f"[Meal Template Created] User {user_id}: '{template_name}' ({total_calories} cal, {food_count} items)")
        return await self.log_event(user_id=user_id, event_type=EventType.MEAL_TEMPLATE_CREATED, event_data=event_data, context=context)

    async def log_meal_template_logged(self, user_id: str, template_id: str, template_name: str, meal_type: str, total_calories: int, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user logs a meal using a template."""
        event_data = {"template_id": template_id, "template_name": template_name, "meal_type": meal_type, "total_calories": total_calories, "logged_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version, screen_name="nutrition_templates", extra_context={"nutrition_tracking_version": "1.0"})
        logger.info(f"[Meal Template Logged] User {user_id}: '{template_name}' ({total_calories} cal) as {meal_type}")
        return await self.log_event(user_id=user_id, event_type=EventType.MEAL_TEMPLATE_LOGGED, event_data=event_data, context=context)

    async def log_meal_template_deleted(self, user_id: str, template_id: str, template_name: str, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user deletes a meal template."""
        event_data = {"template_id": template_id, "template_name": template_name, "deleted_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version, screen_name="nutrition_templates", extra_context={"nutrition_tracking_version": "1.0"})
        logger.info(f"[Meal Template Deleted] User {user_id}: '{template_name}'")
        return await self.log_event(user_id=user_id, event_type=EventType.MEAL_TEMPLATE_DELETED, event_data=event_data, context=context)

    async def log_food_search_performed(self, user_id: str, query: str, result_count: int, cache_hit: bool = False, source: str = "api", device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user searches for foods."""
        event_data = {"query": query, "result_count": result_count, "cache_hit": cache_hit, "source": source, "has_results": result_count > 0, "searched_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version, screen_name="nutrition_search", extra_context={"nutrition_tracking_version": "1.0"})
        logger.info(f"[Food Search Performed] User {user_id}: '{query}' (results={result_count}, cache_hit={cache_hit})")
        return await self.log_event(user_id=user_id, event_type=EventType.FOOD_SEARCH_PERFORMED, event_data=event_data, context=context)

    async def log_ai_tips_toggled(self, user_id: str, disabled: bool, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user toggles AI food tips on/off."""
        event_type = EventType.AI_TIPS_DISABLED if disabled else EventType.AI_TIPS_ENABLED
        event_data = {"disabled": disabled, "toggled_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version, screen_name="nutrition_preferences", extra_context={"nutrition_tracking_version": "1.0"})
        logger.info(f"[AI Tips {'Disabled' if disabled else 'Enabled'}] User {user_id}")
        return await self.log_event(user_id=user_id, event_type=event_type, event_data=event_data, context=context)

    async def log_compact_view_toggled(self, user_id: str, enabled: bool, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user toggles compact tracker view on/off."""
        event_type = EventType.COMPACT_VIEW_ENABLED if enabled else EventType.COMPACT_VIEW_DISABLED
        event_data = {"enabled": enabled, "toggled_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version, screen_name="nutrition_preferences", extra_context={"nutrition_tracking_version": "1.0"})
        logger.info(f"[Compact View {'Enabled' if enabled else 'Disabled'}] User {user_id}")
        return await self.log_event(user_id=user_id, event_type=event_type, event_data=event_data, context=context)

    # =========================================================================
    # ADAPTIVE TDEE / MACROFACTOR-STYLE EVENTS
    # =========================================================================

    async def log_weekly_checkin_started(self, user_id: str, trigger_source: str, days_since_last_checkin: Optional[int] = None, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user starts the weekly check-in flow."""
        event_data = {"trigger_source": trigger_source, "days_since_last_checkin": days_since_last_checkin, "started_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Weekly Check-In Started] User {user_id}, source: {trigger_source}, days_since_last: {days_since_last_checkin}")
        return await self.log_event(user_id=user_id, event_type=EventType.WEEKLY_CHECKIN_STARTED, event_data=event_data, context=context)

    async def log_weekly_checkin_completed(self, user_id: str, option_selected: Optional[str] = None, new_calories: Optional[int] = None, new_protein_g: Optional[int] = None, has_metabolic_adaptation: bool = False, sustainability_rating: Optional[str] = None, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user completes the weekly check-in and accepts new targets."""
        event_data = {"option_selected": option_selected, "new_calories": new_calories, "new_protein_g": new_protein_g, "has_metabolic_adaptation": has_metabolic_adaptation, "sustainability_rating": sustainability_rating, "completed_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Weekly Check-In Completed] User {user_id}, option: {option_selected}, calories: {new_calories}")
        return await self.log_event(user_id=user_id, event_type=EventType.WEEKLY_CHECKIN_COMPLETED, event_data=event_data, context=context)

    async def log_weekly_checkin_dismissed(self, user_id: str, reason: Optional[str] = None, time_spent_seconds: Optional[int] = None, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user dismisses the weekly check-in without completing."""
        event_data = {"reason": reason, "time_spent_seconds": time_spent_seconds, "dismissed_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Weekly Check-In Dismissed] User {user_id}, reason: {reason}")
        return await self.log_event(user_id=user_id, event_type=EventType.WEEKLY_CHECKIN_DISMISSED, event_data=event_data, context=context)

    async def log_detailed_tdee_viewed(self, user_id: str, tdee: int, confidence_low: int, confidence_high: int, uncertainty_calories: int, data_quality_score: float, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user views their detailed TDEE with confidence intervals."""
        event_data = {"tdee": tdee, "confidence_low": confidence_low, "confidence_high": confidence_high, "uncertainty_calories": uncertainty_calories, "data_quality_score": round(data_quality_score, 2), "confidence_range": f"{confidence_low}-{confidence_high}", "viewed_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Detailed TDEE Viewed] User {user_id}, TDEE: {tdee} +/-{uncertainty_calories} cal")
        return await self.log_event(user_id=user_id, event_type=EventType.DETAILED_TDEE_VIEWED, event_data=event_data, context=context)

    async def log_adherence_summary_viewed(self, user_id: str, average_adherence: float, sustainability_score: float, sustainability_rating: str, weeks_analyzed: int, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user views their adherence summary."""
        event_data = {"average_adherence": round(average_adherence, 1), "sustainability_score": round(sustainability_score, 2), "sustainability_rating": sustainability_rating, "weeks_analyzed": weeks_analyzed, "viewed_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Adherence Summary Viewed] User {user_id}, avg: {average_adherence:.1f}%, sustainability: {sustainability_rating}")
        return await self.log_event(user_id=user_id, event_type=EventType.ADHERENCE_SUMMARY_VIEWED, event_data=event_data, context=context)

    async def log_metabolic_adaptation_detected(self, user_id: str, event_type_detected: str, severity: str, suggested_action: str, tdee_drop_percent: Optional[float] = None, plateau_weeks: Optional[int] = None, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when metabolic adaptation or plateau is detected."""
        event_data = {"event_type_detected": event_type_detected, "severity": severity, "suggested_action": suggested_action, "tdee_drop_percent": round(tdee_drop_percent, 1) if tdee_drop_percent else None, "plateau_weeks": plateau_weeks, "detected_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Metabolic Adaptation Detected] User {user_id}, type: {event_type_detected}, severity: {severity}")
        return await self.log_event(user_id=user_id, event_type=EventType.METABOLIC_ADAPTATION_DETECTED, event_data=event_data, context=context)

    async def log_metabolic_adaptation_acknowledged(self, user_id: str, event_type_detected: str, action_taken: str, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user acknowledges a metabolic adaptation alert."""
        event_data = {"event_type_detected": event_type_detected, "action_taken": action_taken, "acknowledged_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Metabolic Adaptation Acknowledged] User {user_id}, action: {action_taken}")
        return await self.log_event(user_id=user_id, event_type=EventType.METABOLIC_ADAPTATION_ACKNOWLEDGED, event_data=event_data, context=context)

    async def log_recommendation_options_viewed(self, user_id: str, options_count: int, options_available: List[str], recommended_option: Optional[str] = None, has_adaptation: bool = False, adherence_score: Optional[float] = None, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user views the multi-option recommendations."""
        event_data = {"options_count": options_count, "options_available": options_available, "recommended_option": recommended_option, "has_adaptation": has_adaptation, "adherence_score": round(adherence_score, 2) if adherence_score else None, "viewed_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Recommendation Options Viewed] User {user_id}, options: {options_available}, recommended: {recommended_option}")
        return await self.log_event(user_id=user_id, event_type=EventType.RECOMMENDATION_OPTIONS_VIEWED, event_data=event_data, context=context)

    async def log_recommendation_option_selected(self, user_id: str, option_type: str, was_recommended: bool, new_calories: int, new_protein_g: int, new_carbs_g: int, new_fat_g: int, expected_weekly_change_kg: float, previous_calories: Optional[int] = None, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a user selects a recommendation option."""
        event_data = {"option_type": option_type, "was_recommended": was_recommended, "new_calories": new_calories, "new_protein_g": new_protein_g, "new_carbs_g": new_carbs_g, "new_fat_g": new_fat_g, "expected_weekly_change_kg": round(expected_weekly_change_kg, 2), "previous_calories": previous_calories, "calorie_change": new_calories - previous_calories if previous_calories else None, "selected_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Recommendation Option Selected] User {user_id}, option: {option_type}, calories: {new_calories}")
        return await self.log_event(user_id=user_id, event_type=EventType.RECOMMENDATION_OPTION_SELECTED, event_data=event_data, context=context)

    async def log_sustainability_score_calculated(self, user_id: str, score: float, rating: str, avg_adherence: float, consistency_score: float, logging_score: float, weeks_analyzed: int, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a sustainability score is calculated for the user."""
        event_data = {"score": round(score, 2), "rating": rating, "avg_adherence": round(avg_adherence, 1), "consistency_score": round(consistency_score, 2), "logging_score": round(logging_score, 2), "weeks_analyzed": weeks_analyzed, "calculated_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Sustainability Score Calculated] User {user_id}, score: {score:.2f}, rating: {rating}")
        return await self.log_event(user_id=user_id, event_type=EventType.SUSTAINABILITY_SCORE_CALCULATED, event_data=event_data, context=context)

    async def log_weight_trend_analyzed(self, user_id: str, change_kg: float, weekly_rate: float, direction: str, start_weight: Optional[float] = None, end_weight: Optional[float] = None, days_analyzed: int = 14, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a weight trend analysis is performed."""
        event_data = {"change_kg": round(change_kg, 2), "weekly_rate": round(weekly_rate, 2), "direction": direction, "start_weight": round(start_weight, 1) if start_weight else None, "end_weight": round(end_weight, 1) if end_weight else None, "days_analyzed": days_analyzed, "analyzed_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Weight Trend Analyzed] User {user_id}, direction: {direction}, rate: {weekly_rate:.2f} kg/week")
        return await self.log_event(user_id=user_id, event_type=EventType.WEIGHT_TREND_ANALYZED, event_data=event_data, context=context)

    async def log_plateau_detected(self, user_id: str, plateau_weeks: int, expected_weight_change_kg: float, actual_weight_change_kg: float, current_deficit: int, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a weight plateau is detected."""
        event_data = {"plateau_weeks": plateau_weeks, "expected_weight_change_kg": round(expected_weight_change_kg, 2), "actual_weight_change_kg": round(actual_weight_change_kg, 2), "difference_kg": round(expected_weight_change_kg - actual_weight_change_kg, 2), "current_deficit": current_deficit, "detected_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Plateau Detected] User {user_id}, weeks: {plateau_weeks}, expected: {expected_weight_change_kg:.2f}kg, actual: {actual_weight_change_kg:.2f}kg")
        return await self.log_event(user_id=user_id, event_type=EventType.PLATEAU_DETECTED, event_data=event_data, context=context)

    async def log_diet_break_suggested(self, user_id: str, reason: str, tdee_drop_percent: Optional[float] = None, suggested_duration_weeks: int = 1, maintenance_calories: Optional[int] = None, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when a diet break is suggested to the user."""
        event_data = {"reason": reason, "tdee_drop_percent": round(tdee_drop_percent, 1) if tdee_drop_percent else None, "suggested_duration_weeks": suggested_duration_weeks, "maintenance_calories": maintenance_calories, "suggested_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Diet Break Suggested] User {user_id}, reason: {reason}, duration: {suggested_duration_weeks} weeks")
        return await self.log_event(user_id=user_id, event_type=EventType.DIET_BREAK_SUGGESTED, event_data=event_data, context=context)

    async def log_refeed_suggested(self, user_id: str, reason: str, tdee_drop_percent: Optional[float] = None, refeed_days: int = 2, refeed_calories: Optional[int] = None, device: Optional[str] = None, app_version: Optional[str] = None) -> Optional[str]:
        """Log when refeed days are suggested to the user."""
        event_data = {"reason": reason, "tdee_drop_percent": round(tdee_drop_percent, 1) if tdee_drop_percent else None, "refeed_days": refeed_days, "refeed_calories": refeed_calories, "suggested_at": datetime.now().isoformat()}
        context = self._build_context(device=device, app_version=app_version)
        logger.info(f"[Refeed Suggested] User {user_id}, reason: {reason}, days: {refeed_days}")
        return await self.log_event(user_id=user_id, event_type=EventType.REFEED_SUGGESTED, event_data=event_data, context=context)
