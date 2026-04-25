"""
User Context Models
===================
Data models for user context tracking, including event types,
behavioral patterns, and health-related context structures.
"""

from .models_helpers import (  # noqa: F401
    CardioPatterns,
    UserPatterns,
    NeatPatterns,
    SupersetPatterns,
    DiabetesPatterns,
)

from dataclasses import dataclass, field
from datetime import datetime, date
from typing import Optional, List, Dict, Any
from enum import Enum


# =============================================================================
# LIFETIME MEMBERSHIP CONTEXT
# =============================================================================

@dataclass
class LifetimeMemberContext:
    """
    Lifetime membership information for AI personalization.

    This context helps the AI treat lifetime members as valued long-term
    customers who have made a significant investment in their fitness journey.
    """
    is_lifetime_member: bool = False
    lifetime_purchase_date: Optional[datetime] = None
    days_as_member: int = 0
    member_tier: Optional[str] = None  # "Veteran", "Loyal", "Established", "New"
    member_tier_level: int = 0  # 1=New, 2=Established, 3=Loyal, 4=Veteran
    estimated_value_received: float = 0.0
    value_multiplier: float = 0.0
    features_unlocked: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "is_lifetime_member": self.is_lifetime_member,
            "lifetime_purchase_date": self.lifetime_purchase_date.isoformat() if self.lifetime_purchase_date else None,
            "days_as_member": self.days_as_member,
            "member_tier": self.member_tier,
            "member_tier_level": self.member_tier_level,
            "estimated_value_received": round(self.estimated_value_received, 2),
            "value_multiplier": round(self.value_multiplier, 2),
            "features_unlocked": self.features_unlocked,
        }

    def get_ai_personalization_context(self) -> str:
        """
        Generate a context string for AI personalization.

        This helps the AI understand that this user is a valued lifetime member
        and should be treated accordingly in workout recommendations, responses,
        and overall interaction style.
        """
        if not self.is_lifetime_member:
            return ""

        context_parts = []

        # Core lifetime member acknowledgment
        if self.lifetime_purchase_date:
            purchase_date_str = self.lifetime_purchase_date.strftime("%B %d, %Y")
            context_parts.append(
                f"This user is a valued lifetime member since {purchase_date_str}. "
                "Treat them as a long-term committed customer who has invested in their fitness journey."
            )
        else:
            context_parts.append(
                "This user is a valued lifetime member. "
                "Treat them as a long-term committed customer who has invested in their fitness journey."
            )

        # Tier-specific context
        if self.member_tier == "Veteran":
            context_parts.append(
                f"They have been with us for over a year ({self.days_as_member} days). "
                "This is a highly loyal user who has shown long-term dedication to fitness. "
                "Reference their journey and progress over time when relevant."
            )
        elif self.member_tier == "Loyal":
            context_parts.append(
                f"They have been with us for {self.days_as_member} days (6+ months). "
                "This user has shown consistent commitment. "
                "Encourage them on their journey to becoming a Veteran member."
            )
        elif self.member_tier == "Established":
            context_parts.append(
                f"They have been with us for {self.days_as_member} days (3+ months). "
                "This user is building a solid foundation. "
                "Help them establish lasting habits."
            )
        elif self.member_tier == "New":
            context_parts.append(
                f"They recently became a lifetime member ({self.days_as_member} days ago). "
                "Make them feel welcomed and valued for their commitment. "
                "Help them get the most out of their investment."
            )

        # Value acknowledgment for long-term members
        if self.estimated_value_received > 100 and self.value_multiplier > 1.5:
            context_parts.append(
                f"They have received significant value (${self.estimated_value_received:.0f} equivalent) "
                f"from their investment, showing excellent ROI on their commitment."
            )

        # Feature context
        if "all" in self.features_unlocked or len(self.features_unlocked) > 5:
            context_parts.append(
                "They have access to all premium features. "
                "Feel free to suggest advanced features and personalization options."
            )

        return " ".join(context_parts)


class EventType(str, Enum):
    """Types of user events to track."""
    MOOD_CHECKIN = "mood_checkin"
    WORKOUT_START = "workout_start"
    WORKOUT_COMPLETE = "workout_complete"
    SCORE_VIEW = "score_view"
    NUTRITION_LOG = "nutrition_log"
    FEATURE_INTERACTION = "feature_interaction"
    SOCIAL_INTERACTION = "social_interaction"
    SCREEN_VIEW = "screen_view"
    ERROR = "error"
    # Custom exercises
    CUSTOM_EXERCISE_CREATED = "custom_exercise_created"
    CUSTOM_EXERCISE_USED = "custom_exercise_used"
    CUSTOM_EXERCISE_DELETED = "custom_exercise_deleted"
    COMPOSITE_EXERCISE_CREATED = "composite_exercise_created"
    # Performance comparison
    PERFORMANCE_COMPARISON_VIEWED = "performance_comparison_viewed"
    # Support tickets
    SUPPORT_TICKET_CREATED = "support_ticket_created"
    SUPPORT_TICKET_REPLIED = "support_ticket_replied"
    SUPPORT_TICKET_CLOSED = "support_ticket_closed"
    # Feedback-based difficulty adjustment
    DIFFICULTY_ADJUSTMENT_APPLIED = "difficulty_adjustment_applied"
    # Exercise progression events
    USER_READY_FOR_PROGRESSION = "user_ready_for_progression"
    USER_ACCEPTED_PROGRESSION = "user_accepted_progression"
    USER_DECLINED_PROGRESSION = "user_declined_progression"
    # Demo/Trial events - for tracking pre-signup behavior
    DEMO_SESSION_STARTED = "demo_session_started"
    DEMO_SCREEN_VIEWED = "demo_screen_viewed"
    DEMO_FEATURE_ATTEMPTED = "demo_feature_attempted"
    DEMO_WORKOUT_PREVIEWED = "demo_workout_previewed"
    DEMO_SESSION_CONVERTED = "demo_session_converted"
    TRIAL_STARTED = "trial_started"
    TRIAL_FEATURE_USED = "trial_feature_used"
    TRIAL_EXPIRED = "trial_expired"
    TRIAL_CONVERTED = "trial_converted"
    # Plan preview and trial workout tracking (conversion funnel)
    PLAN_PREVIEW_VIEWED = "plan_preview_viewed"
    PLAN_PREVIEW_SCROLL_DEPTH = "plan_preview_scroll_depth"
    TRY_WORKOUT_STARTED = "try_workout_started"
    TRY_WORKOUT_COMPLETED = "try_workout_completed"
    TRY_WORKOUT_ABANDONED = "try_workout_abandoned"
    # Demo day (24-hour demo) events
    DEMO_DAY_STARTED = "demo_day_started"
    DEMO_DAY_EXPIRED = "demo_day_expired"
    # Paywall interaction events
    PAYWALL_VIEWED = "paywall_viewed"
    PAYWALL_SKIPPED = "paywall_skipped"
    # Feature interaction during trial/demo
    FREE_FEATURE_TAPPED = "free_feature_tapped"
    LOCKED_FEATURE_TAPPED = "locked_feature_tapped"
    # Quick start widget events
    QUICK_START_VIEWED = "quick_start_viewed"
    QUICK_START_TAPPED = "quick_start_tapped"
    # Subjective feedback / Feel results events
    SUBJECTIVE_PRE_CHECKIN = "subjective_pre_checkin"
    SUBJECTIVE_POST_CHECKIN = "subjective_post_checkin"
    FEEL_RESULTS_VIEWED = "feel_results_viewed"
    FEELING_STRONGER_REPORTED = "feeling_stronger_reported"
    # Milestone and ROI events
    MILESTONE_ACHIEVED = "milestone_achieved"
    MILESTONE_CELEBRATED = "milestone_celebrated"
    MILESTONE_SHARED = "milestone_shared"
    MILESTONES_VIEWED = "milestones_viewed"
    ROI_VIEWED = "roi_viewed"
    MILESTONE_PROGRESS_CHECKED = "milestone_progress_checked"
    # Split screen usage events
    SPLIT_SCREEN_ENTERED = "split_screen_entered"
    SPLIT_SCREEN_EXITED = "split_screen_exited"
    # Quick workout via chat events
    QUICK_WORKOUT_CHAT_REQUEST = "quick_workout_chat_request"
    QUICK_WORKOUT_CHAT_GENERATED = "quick_workout_chat_generated"
    QUICK_WORKOUT_CHAT_FAILED = "quick_workout_chat_failed"
    # RIR (Reps in Reserve) feedback events - for auto-weight adjustment
    SET_RIR_FEEDBACK = "set_rir_feedback"
    WEIGHT_AUTO_ADJUSTED = "weight_auto_adjusted"
    # Library interaction events - for AI preference learning
    LIBRARY_EXERCISE_VIEWED = "library_exercise_viewed"
    LIBRARY_PROGRAM_VIEWED = "library_program_viewed"
    LIBRARY_SEARCH_PERFORMED = "library_search_performed"
    LIBRARY_FILTER_USED = "library_filter_used"
    # NEAT (Non-Exercise Activity Thermogenesis) gamification events
    NEAT_STEP_GOAL_SET = "neat_step_goal_set"
    NEAT_STEP_GOAL_ACHIEVED = "neat_step_goal_achieved"
    NEAT_SEDENTARY_ALERT_RECEIVED = "neat_sedentary_alert_received"
    NEAT_SEDENTARY_ALERT_ACTED_ON = "neat_sedentary_alert_acted_on"
    NEAT_SCORE_CALCULATED = "neat_score_calculated"
    NEAT_ACHIEVEMENT_EARNED = "neat_achievement_earned"
    NEAT_STREAK_MILESTONE = "neat_streak_milestone"
    NEAT_PROGRESSIVE_GOAL_INCREASED = "neat_progressive_goal_increased"
    NEAT_CHALLENGE_ACCEPTED = "neat_challenge_accepted"
    NEAT_CHALLENGE_COMPLETED = "neat_challenge_completed"
    NEAT_LEVEL_UP = "neat_level_up"
    # Superset events - for tracking superset preferences and usage
    SUPERSET_PREFERENCES_UPDATED = "superset_preferences_updated"
    SUPERSET_CREATED_MANUALLY = "superset_created_manually"
    SUPERSET_COMPLETED = "superset_completed"
    SUPERSET_SKIPPED = "superset_skipped"
    FAVORITE_SUPERSET_SAVED = "favorite_superset_saved"
    # Injury tracking events - for AI personalization and workout modification
    INJURY_REPORTED = "injury_reported"
    INJURY_RECOVERED = "injury_recovered"
    INJURY_HEALED = "injury_healed"
    INJURY_PROGRESS_UPDATED = "injury_progress_updated"
    INJURY_CHECK_IN = "injury_check_in"
    REHAB_EXERCISE_COMPLETED = "rehab_exercise_completed"
    # Strain prevention events - for overtraining detection
    STRAIN_DETECTED = "strain_detected"
    STRAIN_INCIDENT = "strain_incident"
    STRAIN_RECORDED = "strain_recorded"
    STRAIN_ALERT_CREATED = "strain_alert_created"
    STRAIN_ALERT_ACKNOWLEDGED = "strain_alert_acknowledged"
    VOLUME_WARNING = "volume_warning"
    STRAIN_RISK_ASSESSED = "strain_risk_assessed"
    # Senior fitness events - for age-appropriate training adjustments
    SENIOR_SETTINGS_UPDATED = "senior_settings_updated"
    SENIOR_RECOVERY_CHECK = "senior_recovery_check"
    # Progression tracking events - for pace and weight progression
    PROGRESSION_PACE_CHANGED = "progression_pace_changed"
    PROGRESSION_WEIGHT_INCREASED = "progression_weight_increased"
    PROGRESSION_DELOAD_TRIGGERED = "progression_deload_triggered"
    # Workout modification events - for safety-related changes
    WORKOUT_MODIFIED_FOR_SAFETY = "workout_modified_for_safety"
    # Cardio progression events - for C25K-style programs
    CARDIO_PROGRESSION_STARTED = "cardio_progression_started"
    CARDIO_SESSION_COMPLETED = "cardio_session_completed"
    CARDIO_PROGRESSION_COMPLETED = "cardio_progression_completed"
    CARDIO_WEEK_REPEATED = "cardio_week_repeated"
    # Diabetes tracking events - for AI personalization and health safety
    DIABETES_PROFILE_CREATED = "diabetes_profile_created"
    GLUCOSE_READING_LOGGED = "glucose_reading_logged"
    INSULIN_DOSE_LOGGED = "insulin_dose_logged"
    A1C_LOGGED = "a1c_logged"
    GLUCOSE_ALERT_TRIGGERED = "glucose_alert_triggered"
    HEALTH_CONNECT_DIABETES_SYNC = "health_connect_diabetes_sync"
    DIABETES_GOAL_SET = "diabetes_goal_set"
    PRE_WORKOUT_GLUCOSE_CHECK = "pre_workout_glucose_check"
    # Exercise history and muscle analytics events - for AI personalization
    EXERCISE_HISTORY_VIEWED = "exercise_history_viewed"
    MUSCLE_ANALYTICS_VIEWED = "muscle_analytics_viewed"
    MUSCLE_HEATMAP_INTERACTION = "muscle_heatmap_interaction"
    # Nutrition preferences events - for tracking nutrition feature usage
    NUTRITION_PREFERENCES_UPDATED = "nutrition_preferences_updated"
    NUTRITION_PREFERENCES_RESET = "nutrition_preferences_reset"
    QUICK_LOG_USED = "quick_log_used"
    MEAL_TEMPLATE_CREATED = "meal_template_created"
    MEAL_TEMPLATE_LOGGED = "meal_template_logged"
    MEAL_TEMPLATE_DELETED = "meal_template_deleted"
    FOOD_SEARCH_PERFORMED = "food_search_performed"
    AI_TIPS_DISABLED = "ai_tips_disabled"
    AI_TIPS_ENABLED = "ai_tips_enabled"
    COMPACT_VIEW_ENABLED = "compact_view_enabled"
    COMPACT_VIEW_DISABLED = "compact_view_disabled"
    # Hormonal health events - for cycle tracking and hormone optimization
    HORMONAL_PROFILE_CREATED = "hormonal_profile_created"
    HORMONAL_PROFILE_UPDATED = "hormonal_profile_updated"
    HORMONE_LOG_ADDED = "hormone_log_added"
    CYCLE_PHASE_CHECKED = "cycle_phase_checked"
    PERIOD_LOGGED = "period_logged"
    HORMONAL_INSIGHTS_VIEWED = "hormonal_insights_viewed"
    HORMONAL_FOODS_VIEWED = "hormonal_foods_viewed"
    # Kegel/pelvic floor events - for tracking kegel preferences and sessions
    KEGEL_PREFERENCES_UPDATED = "kegel_preferences_updated"
    KEGEL_SESSION_LOGGED = "kegel_session_logged"
    KEGEL_SESSION_FROM_WORKOUT = "kegel_session_from_workout"
    KEGEL_STATS_VIEWED = "kegel_stats_viewed"
    KEGEL_EXERCISES_VIEWED = "kegel_exercises_viewed"
    KEGEL_DAILY_GOAL_MET = "kegel_daily_goal_met"
    KEGEL_STREAK_MILESTONE = "kegel_streak_milestone"
    # Weekly plan events - for holistic plan tracking
    WEEKLY_PLAN_GENERATED = "weekly_plan_generated"
    WEEKLY_PLAN_VIEWED = "weekly_plan_viewed"
    DAILY_PLAN_VIEWED = "daily_plan_viewed"
    MEAL_SUGGESTION_LOGGED = "meal_suggestion_logged"
    MEAL_SUGGESTION_SKIPPED = "meal_suggestion_skipped"
    MEAL_SUGGESTION_REGENERATED = "meal_suggestion_regenerated"
    PLAN_COORDINATION_WARNING_VIEWED = "plan_coordination_warning_viewed"
    WEEKLY_PLAN_ARCHIVED = "weekly_plan_archived"
    # Inflammation analysis events - for food ingredient analysis
    INFLAMMATION_SCAN_PERFORMED = "inflammation_scan_performed"
    INFLAMMATION_HISTORY_VIEWED = "inflammation_history_viewed"
    INFLAMMATION_SCAN_FAVORITED = "inflammation_scan_favorited"
    INFLAMMATION_SCAN_NOTES_UPDATED = "inflammation_scan_notes_updated"
    # MacroFactor-style adaptive TDEE events - for metabolic tracking
    WEEKLY_CHECKIN_STARTED = "weekly_checkin_started"
    WEEKLY_CHECKIN_COMPLETED = "weekly_checkin_completed"
    WEEKLY_CHECKIN_DISMISSED = "weekly_checkin_dismissed"
    DETAILED_TDEE_VIEWED = "detailed_tdee_viewed"
    ADHERENCE_SUMMARY_VIEWED = "adherence_summary_viewed"
    METABOLIC_ADAPTATION_DETECTED = "metabolic_adaptation_detected"
    METABOLIC_ADAPTATION_ACKNOWLEDGED = "metabolic_adaptation_acknowledged"
    RECOMMENDATION_OPTIONS_VIEWED = "recommendation_options_viewed"
    RECOMMENDATION_OPTION_SELECTED = "recommendation_option_selected"
    SUSTAINABILITY_SCORE_CALCULATED = "sustainability_score_calculated"
    TDEE_CONFIDENCE_VIEWED = "tdee_confidence_viewed"
    WEIGHT_TREND_ANALYZED = "weight_trend_analyzed"
    PLATEAU_DETECTED = "plateau_detected"
    DIET_BREAK_SUGGESTED = "diet_break_suggested"
    REFEED_SUGGESTED = "refeed_suggested"
    # WearOS watch sync events - for tracking data from smartwatch
    WATCH_SYNC_COMPLETED = "watch_sync_completed"
    WATCH_WORKOUT_LOGGED = "watch_workout_logged"
    WATCH_SET_LOGGED = "watch_set_logged"
    WATCH_FOOD_LOGGED = "watch_food_logged"
    WATCH_FASTING_EVENT = "watch_fasting_event"
    WATCH_ACTIVITY_SYNCED = "watch_activity_synced"
    WATCH_CONNECTED = "watch_connected"
    WATCH_DISCONNECTED = "watch_disconnected"


@dataclass
class HormonalHealthContext:
    """
    Hormonal health context for AI personalization and gender-specific recommendations.

    This context helps the AI:
    - Understand the user's hormonal goals (testosterone optimization, estrogen balance, etc.)
    - Provide cycle-aware workout recommendations for menstruating individuals
    - Suggest hormone-supportive nutrition
    - Include appropriate kegel/pelvic floor exercises when enabled
    """
    # Gender and basic info
    gender: Optional[str] = None  # "male", "female", "non_binary", "prefer_not_to_say"

    # Hormonal goals
    hormone_goals: List[str] = field(default_factory=list)  # ["testosterone_optimization", "estrogen_balance", "pcos_management", etc.]
    primary_goal: Optional[str] = None

    # Menstrual cycle tracking (for those who menstruate)
    menstrual_tracking_enabled: bool = False
    current_cycle_phase: Optional[str] = None  # "menstrual", "follicular", "ovulation", "luteal"
    cycle_day: Optional[int] = None  # Current day in cycle
    avg_cycle_length: int = 28
    last_period_date: Optional[date] = None

    # Recent symptoms (last 7 days)
    recent_symptoms: List[str] = field(default_factory=list)  # ["fatigue", "cramps", "mood_swings", etc.]
    symptom_severity: Optional[str] = None  # "mild", "moderate", "severe"

    # Energy and workout capacity
    energy_level_today: Optional[int] = None  # 1-10
    recommended_intensity: Optional[str] = None  # Based on cycle phase

    # Kegel/pelvic floor settings
    kegels_enabled: bool = False
    include_kegels_in_warmup: bool = False
    include_kegels_in_cooldown: bool = False
    kegel_current_level: Optional[str] = None  # "beginner", "intermediate", "advanced"
    kegel_focus_area: Optional[str] = None  # "general", "male_specific", "female_specific", "postpartum", "prostate_health"
    kegel_streak_days: int = 0
    kegel_sessions_today: int = 0
    kegel_target_sessions: int = 3

    # Dietary preferences for hormonal support
    hormonal_diet_enabled: bool = False
    dietary_restrictions: List[str] = field(default_factory=list)  # For AI meal suggestions

    def to_dict(self) -> Dict[str, Any]:
        return {
            "gender": self.gender,
            "hormone_goals": self.hormone_goals,
            "primary_goal": self.primary_goal,
            "menstrual_tracking_enabled": self.menstrual_tracking_enabled,
            "current_cycle_phase": self.current_cycle_phase,
            "cycle_day": self.cycle_day,
            "avg_cycle_length": self.avg_cycle_length,
            "last_period_date": self.last_period_date.isoformat() if self.last_period_date else None,
            "recent_symptoms": self.recent_symptoms,
            "symptom_severity": self.symptom_severity,
            "energy_level_today": self.energy_level_today,
            "recommended_intensity": self.recommended_intensity,
            "kegels_enabled": self.kegels_enabled,
            "include_kegels_in_warmup": self.include_kegels_in_warmup,
            "include_kegels_in_cooldown": self.include_kegels_in_cooldown,
            "kegel_current_level": self.kegel_current_level,
            "kegel_focus_area": self.kegel_focus_area,
            "kegel_streak_days": self.kegel_streak_days,
            "kegel_sessions_today": self.kegel_sessions_today,
            "kegel_target_sessions": self.kegel_target_sessions,
            "hormonal_diet_enabled": self.hormonal_diet_enabled,
            "dietary_restrictions": self.dietary_restrictions,
        }

    def get_ai_context(self) -> str:
        """
        Generate a formatted context string for AI prompts.

        This provides hormone-aware guidance for the AI coach:
        - Cycle phase-specific workout recommendations
        - Gender-specific exercise suggestions
        - Hormonal goal context
        - Kegel/pelvic floor inclusion preferences
        """
        context_parts = []

        # Gender and goal context
        if self.gender and self.primary_goal:
            goal_descriptions = {
                "testosterone_optimization": "optimizing testosterone levels through strength training and nutrition",
                "estrogen_balance": "maintaining healthy estrogen balance",
                "pcos_management": "managing PCOS through exercise and diet",
                "menopause_support": "supporting menopausal health transition",
                "fertility_support": "supporting fertility and reproductive health",
                "postpartum_recovery": "recovering postpartum strength and pelvic floor health",
            }
            goal_desc = goal_descriptions.get(self.primary_goal, self.primary_goal.replace("_", " "))
            context_parts.append(f"User is focused on {goal_desc}.")

        # Cycle phase context (for menstruating individuals)
        if self.menstrual_tracking_enabled and self.current_cycle_phase:
            phase_recommendations = {
                "menstrual": (
                    f"User is in the menstrual phase (day {self.cycle_day or '?'} of cycle). "
                    "This is a lower energy phase. Recommend lighter workouts, yoga, walking, "
                    "and avoid high-intensity training. Focus on recovery and gentle movement."
                ),
                "follicular": (
                    f"User is in the follicular phase (day {self.cycle_day or '?'}). "
                    "Energy is rising. This is a great time for trying new exercises, "
                    "building strength, and gradually increasing intensity."
                ),
                "ovulation": (
                    f"User is in the ovulation phase (day {self.cycle_day or '?'}). "
                    "Energy and strength are typically at peak. Great time for high-intensity "
                    "workouts, PRs, and challenging sessions. Note: injury risk may be slightly elevated."
                ),
                "luteal": (
                    f"User is in the luteal phase (day {self.cycle_day or '?'}). "
                    "Energy may decrease, especially in late luteal. Focus on moderate intensity, "
                    "steady-state cardio, and strength maintenance rather than PRs."
                ),
            }
            context_parts.append(phase_recommendations.get(self.current_cycle_phase, ""))

        # Symptoms context
        if self.recent_symptoms and self.symptom_severity:
            severity_context = {
                "mild": "User has reported mild symptoms",
                "moderate": "User is experiencing moderate symptoms - be mindful of modifications",
                "severe": "User has severe symptoms - prioritize gentle movement and recovery",
            }
            context_parts.append(
                f"{severity_context.get(self.symptom_severity, '')} "
                f"including: {', '.join(self.recent_symptoms[:3])}."
            )

        # Energy level
        if self.energy_level_today:
            if self.energy_level_today <= 3:
                context_parts.append(
                    f"User's energy is low today ({self.energy_level_today}/10). "
                    "Suggest shorter, lower-intensity workouts."
                )
            elif self.energy_level_today >= 8:
                context_parts.append(
                    f"User's energy is high today ({self.energy_level_today}/10). "
                    "Great day for challenging workouts."
                )

        # Kegel context
        if self.kegels_enabled:
            kegel_context = ["User has pelvic floor exercises (kegels) enabled."]

            if self.include_kegels_in_warmup:
                kegel_context.append("Include kegel exercises in warmup.")
            if self.include_kegels_in_cooldown:
                kegel_context.append("Include kegel exercises in cooldown.")

            if self.kegel_focus_area:
                focus_descriptions = {
                    "male_specific": "Focus on prostate and bladder health",
                    "female_specific": "Focus on pelvic floor strength",
                    "postpartum": "Focus on postpartum recovery",
                    "prostate_health": "Focus on prostate health benefits",
                }
                if self.kegel_focus_area in focus_descriptions:
                    kegel_context.append(f"{focus_descriptions[self.kegel_focus_area]}.")

            if self.kegel_streak_days >= 7:
                kegel_context.append(
                    f"User has a {self.kegel_streak_days}-day kegel streak - "
                    "acknowledge their consistency."
                )

            context_parts.append(" ".join(kegel_context))

        # Testosterone optimization context for males
        if self.gender == "male" and "testosterone_optimization" in self.hormone_goals:
            context_parts.append(
                "For testosterone optimization: emphasize compound movements (squats, deadlifts, bench press), "
                "adequate rest between sets (2-3 min), and avoid overtraining which can lower testosterone."
            )

        # Hormonal diet context
        if self.hormonal_diet_enabled:
            context_parts.append(
                "User wants hormone-supportive nutrition. Include relevant food suggestions "
                "in any nutrition advice based on their hormonal goals."
            )

        return " ".join(context_parts) if context_parts else ""

    def get_workout_modification_context(self) -> str:
        """
        Generate specific workout modification recommendations based on hormonal context.
        """
        modifications = []

        if self.current_cycle_phase == "menstrual" and self.symptom_severity in ["moderate", "severe"]:
            modifications.append("Reduce workout intensity by 20-30%")
            modifications.append("Prioritize gentle stretching and mobility work")
            modifications.append("Shorter rest periods are OK if user prefers to keep moving")

        if self.current_cycle_phase == "ovulation":
            modifications.append("User may be at slightly higher injury risk - emphasize proper form")
            modifications.append("Good time for strength testing if user wants")

        if self.kegels_enabled and self.include_kegels_in_warmup:
            modifications.append(f"Add {self.kegel_current_level or 'beginner'}-level kegel exercises to warmup")

        if self.kegels_enabled and self.include_kegels_in_cooldown:
            modifications.append(f"Add {self.kegel_current_level or 'beginner'}-level kegel exercises to cooldown")

        return " | ".join(modifications) if modifications else ""
