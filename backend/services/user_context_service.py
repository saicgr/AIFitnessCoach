"""
User Context Service
====================
Handles logging and retrieval of user interaction events for analytics,
AI personalization, and improving recommendations.

Event Types:
- mood_checkin: User selected a mood for quick workout
- workout_start: User started a workout
- workout_complete: User completed a workout
- score_view: User viewed the scoring screen
- nutrition_log: User logged food
- feature_interaction: User interacted with a feature
- screen_view: User viewed a screen
- error: Error occurred
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta, date
from typing import Optional, List, Dict, Any
from enum import Enum
import logging

from core.db import get_supabase_db
from models.cardio_session import CardioType, CardioLocation

logger = logging.getLogger(__name__)


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


@dataclass
class CardioPatterns:
    """Analyzed cardio activity patterns for AI recommendations."""
    # Recent activity (last 7 days)
    recent_sessions_count: int = 0
    recent_total_duration_minutes: int = 0
    recent_cardio_types: List[str] = field(default_factory=list)
    recent_locations: List[str] = field(default_factory=list)

    # Preferred locations (based on history)
    preferred_location: Optional[str] = None  # Most frequent location
    location_frequency: Dict[str, int] = field(default_factory=dict)
    is_outdoor_enthusiast: bool = False  # True if >60% outdoor/trail sessions
    is_treadmill_user: bool = False  # True if >40% treadmill sessions

    # Frequency tracking
    avg_cardio_sessions_per_week: float = 0.0
    cardio_streak_days: int = 0  # Consecutive days with cardio
    last_cardio_date: Optional[date] = None

    # Cardio type preferences
    primary_cardio_type: Optional[str] = None  # Most frequent type
    cardio_type_frequency: Dict[str, int] = field(default_factory=dict)

    # Balance metrics (for workout planning)
    cardio_to_strength_ratio: float = 0.0  # Cardio sessions / strength workouts
    needs_more_cardio: bool = False  # True if ratio < 0.3
    needs_more_strength: bool = False  # True if ratio > 2.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "recent_sessions_count": self.recent_sessions_count,
            "recent_total_duration_minutes": self.recent_total_duration_minutes,
            "recent_cardio_types": self.recent_cardio_types,
            "recent_locations": self.recent_locations,
            "preferred_location": self.preferred_location,
            "location_frequency": self.location_frequency,
            "is_outdoor_enthusiast": self.is_outdoor_enthusiast,
            "is_treadmill_user": self.is_treadmill_user,
            "avg_cardio_sessions_per_week": round(self.avg_cardio_sessions_per_week, 1),
            "cardio_streak_days": self.cardio_streak_days,
            "last_cardio_date": self.last_cardio_date.isoformat() if self.last_cardio_date else None,
            "primary_cardio_type": self.primary_cardio_type,
            "cardio_type_frequency": self.cardio_type_frequency,
            "cardio_to_strength_ratio": round(self.cardio_to_strength_ratio, 2),
            "needs_more_cardio": self.needs_more_cardio,
            "needs_more_strength": self.needs_more_strength,
        }

    def get_ai_recommendations_context(self) -> str:
        """
        Generate a context string for AI workout generation.

        This provides insights that help the AI make better recommendations:
        - Suggest outdoor-friendly warmups for outdoor enthusiasts
        - Recommend interval programs for treadmill users
        - Balance cardio and strength based on ratio
        """
        context_parts = []

        if self.recent_sessions_count > 0:
            context_parts.append(
                f"User completed {self.recent_sessions_count} cardio sessions in the last 7 days "
                f"({self.recent_total_duration_minutes} minutes total)."
            )

        if self.is_outdoor_enthusiast:
            context_parts.append(
                "User frequently exercises outdoors. Consider outdoor-friendly warmups "
                "and exercises that complement outdoor running/cycling."
            )
        elif self.is_treadmill_user:
            context_parts.append(
                "User primarily uses treadmill. Can recommend interval training programs "
                "and incline variations."
            )

        if self.primary_cardio_type:
            context_parts.append(f"Primary cardio activity: {self.primary_cardio_type}.")

        if self.needs_more_cardio:
            context_parts.append(
                "User's cardio-to-strength ratio is low. Consider suggesting more cardio "
                "activities or cardio-focused warmups."
            )
        elif self.needs_more_strength:
            context_parts.append(
                "User does a lot of cardio relative to strength training. "
                "Emphasize strength workouts for balanced fitness."
            )

        if self.cardio_streak_days >= 3:
            context_parts.append(
                f"User has been active for {self.cardio_streak_days} consecutive days. "
                "Consider recovery-focused suggestions."
            )

        return " ".join(context_parts) if context_parts else ""


@dataclass
class UserPatterns:
    """Analyzed user behavior patterns."""
    user_id: str

    # Mood patterns
    most_common_mood: Optional[str] = None
    mood_frequency: Dict[str, int] = None
    mood_workout_completion_rate: Dict[str, float] = None

    # Time patterns
    preferred_workout_time: Optional[str] = None  # morning/afternoon/evening/night
    most_active_day: Optional[str] = None

    # Activity patterns
    avg_workouts_per_week: float = 0
    total_events_30_days: int = 0
    nutrition_logging_rate: float = 0

    # Cardio patterns
    cardio_patterns: Optional[CardioPatterns] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "user_id": self.user_id,
            "most_common_mood": self.most_common_mood,
            "mood_frequency": self.mood_frequency or {},
            "mood_workout_completion_rate": self.mood_workout_completion_rate or {},
            "preferred_workout_time": self.preferred_workout_time,
            "most_active_day": self.most_active_day,
            "avg_workouts_per_week": round(self.avg_workouts_per_week, 1),
            "total_events_30_days": self.total_events_30_days,
            "nutrition_logging_rate": round(self.nutrition_logging_rate, 1),
            "cardio_patterns": self.cardio_patterns.to_dict() if self.cardio_patterns else None,
        }


# =============================================================================
# NEAT (NON-EXERCISE ACTIVITY THERMOGENESIS) CONTEXT
# =============================================================================

@dataclass
class NeatPatterns:
    """
    NEAT activity patterns for AI personalization and gamification.

    NEAT (Non-Exercise Activity Thermogenesis) represents calories burned through
    daily activities like walking, standing, and fidgeting - not formal exercise.
    This context helps track user's daily movement and encourage healthy habits.
    """
    # Current goals and progress
    current_step_goal: int = 7500
    initial_step_goal: int = 3000  # Starting goal when progressive goals began
    is_progressive_goal: bool = False  # True if goal auto-increases
    today_steps: int = 0
    today_step_percentage: float = 0.0

    # NEAT score (0-100 composite score)
    today_neat_score: int = 0
    week_avg_neat_score: float = 0.0
    last_week_avg_neat_score: float = 0.0
    neat_score_trend: str = "stable"  # "improving", "stable", "declining"

    # Active hours tracking
    today_active_hours: int = 0
    target_active_hours: int = 10

    # Streak tracking
    current_streak_days: int = 0
    longest_streak_days: int = 0

    # Sedentary patterns
    sedentary_alert_count_today: int = 0
    sedentary_alerts_acted_on: int = 0
    most_sedentary_period: Optional[str] = None  # e.g., "2pm-4pm weekdays"

    # Gamification
    current_level: str = "Couch Potato"  # "Couch Potato", "Casual Mover", "Active Walker", "NEAT Enthusiast", "NEAT Champion"
    current_xp: int = 0
    xp_to_next_level: int = 1000
    badges_earned: List[str] = field(default_factory=list)
    next_achievement_name: Optional[str] = None
    days_to_next_achievement: Optional[int] = None

    # Weekly stats
    weekly_step_totals: List[int] = field(default_factory=list)  # Last 7 days
    weekly_active_hours: List[int] = field(default_factory=list)  # Last 7 days

    def to_dict(self) -> Dict[str, Any]:
        return {
            "current_step_goal": self.current_step_goal,
            "initial_step_goal": self.initial_step_goal,
            "is_progressive_goal": self.is_progressive_goal,
            "today_steps": self.today_steps,
            "today_step_percentage": round(self.today_step_percentage, 1),
            "today_neat_score": self.today_neat_score,
            "week_avg_neat_score": round(self.week_avg_neat_score, 1),
            "last_week_avg_neat_score": round(self.last_week_avg_neat_score, 1),
            "neat_score_trend": self.neat_score_trend,
            "today_active_hours": self.today_active_hours,
            "target_active_hours": self.target_active_hours,
            "current_streak_days": self.current_streak_days,
            "longest_streak_days": self.longest_streak_days,
            "sedentary_alert_count_today": self.sedentary_alert_count_today,
            "sedentary_alerts_acted_on": self.sedentary_alerts_acted_on,
            "most_sedentary_period": self.most_sedentary_period,
            "current_level": self.current_level,
            "current_xp": self.current_xp,
            "xp_to_next_level": self.xp_to_next_level,
            "badges_earned": self.badges_earned,
            "next_achievement_name": self.next_achievement_name,
            "days_to_next_achievement": self.days_to_next_achievement,
            "weekly_step_totals": self.weekly_step_totals,
            "weekly_active_hours": self.weekly_active_hours,
        }

    def get_ai_context(self) -> str:
        """
        Generate a formatted context string for AI prompts.

        Returns a human-readable summary of the user's NEAT profile
        that can be included in AI prompts for personalized recommendations.
        """
        context_parts = []

        # Step goal context
        if self.is_progressive_goal:
            context_parts.append(
                f"User's NEAT profile:\n"
                f"- Current step goal: {self.current_step_goal}/day "
                f"(progressive, started at {self.initial_step_goal})"
            )
        else:
            context_parts.append(
                f"User's NEAT profile:\n"
                f"- Current step goal: {self.current_step_goal}/day"
            )

        # Today's progress
        context_parts.append(
            f"- Today's progress: {self.today_steps} steps ({self.today_step_percentage:.0f}%)"
        )

        # NEAT score trend
        if self.week_avg_neat_score > 0:
            trend_text = "Improving" if self.neat_score_trend == "improving" else \
                         "Declining" if self.neat_score_trend == "declining" else "Stable"
            context_parts.append(
                f"- NEAT score trend: {trend_text} "
                f"(avg {self.week_avg_neat_score:.0f} this week vs {self.last_week_avg_neat_score:.0f} last week)"
            )

        # Active hours
        context_parts.append(
            f"- Active hours today: {self.today_active_hours} of {self.target_active_hours} target"
        )

        # Streak
        if self.current_streak_days > 0:
            context_parts.append(
                f"- Current streak: {self.current_streak_days} days meeting step goal"
            )

        # Sedentary pattern
        if self.most_sedentary_period:
            context_parts.append(
                f"- Sedentary pattern: Most sedentary {self.most_sedentary_period}"
            )

        # Achievement focus
        if self.next_achievement_name and self.days_to_next_achievement:
            context_parts.append(
                f"- Achievement focus: {self.days_to_next_achievement} days away from "
                f"'{self.next_achievement_name}' badge"
            )

        return "\n".join(context_parts)


@dataclass
class SupersetPatterns:
    """
    Superset usage patterns for AI personalization and workout generation.

    Supersets are pairs of exercises performed back-to-back without rest,
    either targeting opposing muscle groups (antagonist) or the same muscle
    group (compound). This context helps the AI understand user preferences
    for superset-style training.
    """
    # Preferences
    supersets_enabled: bool = False
    preferred_superset_type: Optional[str] = None  # "antagonist", "compound", "both"
    max_supersets_per_workout: int = 3

    # Favorite supersets (exercise pairs user has saved)
    favorite_supersets: List[Dict[str, str]] = field(default_factory=list)

    # Recent usage (last 30 days)
    total_supersets_completed: int = 0
    total_supersets_skipped: int = 0
    recently_completed_supersets: List[Dict[str, Any]] = field(default_factory=list)
    avg_superset_completion_time_seconds: float = 0.0

    # Effectiveness metrics
    superset_completion_rate: float = 0.0  # Completed / (Completed + Skipped)
    most_completed_pair: Optional[Dict[str, str]] = None
    most_skipped_pair: Optional[Dict[str, str]] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "supersets_enabled": self.supersets_enabled,
            "preferred_superset_type": self.preferred_superset_type,
            "max_supersets_per_workout": self.max_supersets_per_workout,
            "favorite_supersets": self.favorite_supersets,
            "total_supersets_completed": self.total_supersets_completed,
            "total_supersets_skipped": self.total_supersets_skipped,
            "recently_completed_supersets": self.recently_completed_supersets[:5],
            "avg_superset_completion_time_seconds": round(self.avg_superset_completion_time_seconds, 1),
            "superset_completion_rate": round(self.superset_completion_rate, 2),
            "most_completed_pair": self.most_completed_pair,
            "most_skipped_pair": self.most_skipped_pair,
        }

    def get_ai_context(self) -> str:
        """
        Generate a context string for AI workout generation.

        This provides insights that help the AI make better superset recommendations:
        - Include supersets in workouts when user has them enabled
        - Use preferred superset type (antagonist vs compound)
        - Suggest favorite exercise pairs when appropriate
        - Avoid pairs that are frequently skipped
        """
        if not self.supersets_enabled:
            return "User has supersets disabled. Do not include superset pairings in workouts."

        context_parts = []

        context_parts.append("User has supersets enabled in their workouts.")

        if self.preferred_superset_type:
            type_descriptions = {
                "antagonist": "opposing muscle groups (e.g., biceps/triceps, chest/back)",
                "compound": "the same muscle group for increased intensity",
                "both": "both antagonist and compound superset styles",
            }
            desc = type_descriptions.get(
                self.preferred_superset_type,
                self.preferred_superset_type
            )
            context_parts.append(f"User prefers {desc} supersets.")

        if self.max_supersets_per_workout > 0:
            context_parts.append(
                f"Include up to {self.max_supersets_per_workout} superset pairs per workout."
            )

        if self.favorite_supersets:
            # List up to 3 favorite pairs
            pairs_str = ", ".join([
                f"{pair.get('exercise1', 'Unknown')}/{pair.get('exercise2', 'Unknown')}"
                for pair in self.favorite_supersets[:3]
            ])
            context_parts.append(f"User's favorite superset pairs include: {pairs_str}.")

        if self.total_supersets_completed > 0:
            context_parts.append(
                f"User has completed {self.total_supersets_completed} supersets recently."
            )

            if self.superset_completion_rate >= 0.8:
                context_parts.append(
                    "User has high superset completion rate - they enjoy this training style."
                )
            elif self.superset_completion_rate < 0.5 and self.total_supersets_skipped > 3:
                context_parts.append(
                    "User sometimes skips supersets - consider offering them as optional."
                )

        if self.most_completed_pair:
            context_parts.append(
                f"User's most successful superset: "
                f"{self.most_completed_pair.get('exercise1', '')}/{self.most_completed_pair.get('exercise2', '')}."
            )

        if self.most_skipped_pair and self.total_supersets_skipped > 2:
            context_parts.append(
                f"Avoid pairing: {self.most_skipped_pair.get('exercise1', '')} "
                f"with {self.most_skipped_pair.get('exercise2', '')} (frequently skipped)."
            )

        return " ".join(context_parts)


@dataclass
class DiabetesPatterns:
    """
    Diabetes tracking patterns for AI personalization and workout safety.

    This context helps the AI:
    - Understand the user's diabetes management status
    - Provide relevant pre-workout glucose guidance
    - Adjust recommendations based on recent glucose trends
    - Include appropriate safety reminders
    """
    # Profile info
    diabetes_type: Optional[str] = None  # "type1", "type2", "prediabetes", "gestational"
    diagnosis_date: Optional[date] = None
    
    # Recent glucose readings (last 24 hours)
    recent_readings_count: int = 0
    avg_glucose_24h: Optional[float] = None  # mg/dL
    min_glucose_24h: Optional[float] = None
    max_glucose_24h: Optional[float] = None
    latest_glucose: Optional[float] = None
    latest_glucose_status: Optional[str] = None  # "low", "normal", "high", "very_high"
    latest_glucose_time: Optional[datetime] = None
    
    # Insulin tracking (today)
    today_insulin_doses: int = 0
    today_total_units: float = 0.0
    insulin_types_used: List[str] = field(default_factory=list)  # "rapid", "long", "mixed"
    
    # A1C tracking
    current_a1c: Optional[float] = None
    a1c_date: Optional[date] = None
    a1c_goal: Optional[float] = None
    a1c_on_target: bool = False
    
    # Goals
    target_glucose_min: float = 70.0  # mg/dL
    target_glucose_max: float = 180.0
    pre_workout_target_min: float = 100.0  # Safe for exercise
    pre_workout_target_max: float = 250.0
    
    # Alerts and safety
    active_alerts: List[str] = field(default_factory=list)  # "low_glucose", "high_glucose", etc.
    hypo_events_7_days: int = 0  # Hypoglycemic events in last 7 days
    hyper_events_7_days: int = 0  # Hyperglycemic events in last 7 days
    
    # Health Connect sync status
    last_sync_time: Optional[datetime] = None
    sync_enabled: bool = False
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "diabetes_type": self.diabetes_type,
            "diagnosis_date": self.diagnosis_date.isoformat() if self.diagnosis_date else None,
            "recent_readings_count": self.recent_readings_count,
            "avg_glucose_24h": round(self.avg_glucose_24h, 1) if self.avg_glucose_24h else None,
            "min_glucose_24h": self.min_glucose_24h,
            "max_glucose_24h": self.max_glucose_24h,
            "latest_glucose": self.latest_glucose,
            "latest_glucose_status": self.latest_glucose_status,
            "latest_glucose_time": self.latest_glucose_time.isoformat() if self.latest_glucose_time else None,
            "today_insulin_doses": self.today_insulin_doses,
            "today_total_units": round(self.today_total_units, 1),
            "insulin_types_used": self.insulin_types_used,
            "current_a1c": self.current_a1c,
            "a1c_date": self.a1c_date.isoformat() if self.a1c_date else None,
            "a1c_goal": self.a1c_goal,
            "a1c_on_target": self.a1c_on_target,
            "target_glucose_min": self.target_glucose_min,
            "target_glucose_max": self.target_glucose_max,
            "pre_workout_target_min": self.pre_workout_target_min,
            "pre_workout_target_max": self.pre_workout_target_max,
            "active_alerts": self.active_alerts,
            "hypo_events_7_days": self.hypo_events_7_days,
            "hyper_events_7_days": self.hyper_events_7_days,
            "last_sync_time": self.last_sync_time.isoformat() if self.last_sync_time else None,
            "sync_enabled": self.sync_enabled,
        }

    def get_ai_context(self) -> str:
        """
        Generate a formatted context string for AI prompts.

        This provides diabetes-aware guidance for the AI coach:
        - Current glucose status and safety considerations
        - Pre-workout glucose recommendations
        - Recent patterns that may affect workout recommendations
        """
        if not self.diabetes_type:
            return ""

        context_parts = []

        # Diabetes type context
        type_descriptions = {
            "type1": "Type 1 diabetes (insulin-dependent)",
            "type2": "Type 2 diabetes",
            "prediabetes": "Prediabetes",
            "gestational": "Gestational diabetes",
        }
        type_desc = type_descriptions.get(self.diabetes_type, self.diabetes_type)
        context_parts.append(f"User has {type_desc}.")

        # Current glucose status
        if self.latest_glucose and self.latest_glucose_status:
            status_context = {
                "low": f"IMPORTANT: User's latest glucose reading is LOW ({self.latest_glucose} mg/dL). " +
                       "Suggest having fast-acting carbs before workout and consider delaying intense exercise.",
                "normal": f"User's glucose is in good range ({self.latest_glucose} mg/dL) for exercise.",
                "high": f"User's glucose is elevated ({self.latest_glucose} mg/dL). " +
                        "Light to moderate exercise may help lower it, but avoid intense exercise if above 250.",
                "very_high": f"CAUTION: User's glucose is very high ({self.latest_glucose} mg/dL). " +
                             "Suggest checking for ketones before exercising. Avoid intense exercise.",
            }
            context_parts.append(status_context.get(self.latest_glucose_status, ""))

        # A1C progress
        if self.current_a1c and self.a1c_goal:
            if self.a1c_on_target:
                context_parts.append(
                    f"User's A1C ({self.current_a1c}%) is meeting their goal of {self.a1c_goal}%. " +
                    "Acknowledge their great diabetes management."
                )
            else:
                context_parts.append(
                    f"User's A1C is {self.current_a1c}%, working toward goal of {self.a1c_goal}%. " +
                    "Regular exercise can help improve A1C."
                )

        # Recent hypo/hyper events
        if self.hypo_events_7_days > 2:
            context_parts.append(
                f"User has had {self.hypo_events_7_days} low glucose events this week. " +
                "Be extra cautious about workout intensity and ensure they have glucose tablets available."
            )

        # Active alerts
        if "low_glucose" in self.active_alerts:
            context_parts.append(
                "ACTIVE ALERT: Low glucose detected. Prioritize safety over workout completion."
            )

        # Pre-workout guidance
        if self.latest_glucose:
            if self.latest_glucose < self.pre_workout_target_min:
                context_parts.append(
                    f"Pre-workout glucose ({self.latest_glucose}) is below safe range. " +
                    f"Recommend eating 15-30g carbs before exercising."
                )
            elif self.latest_glucose > self.pre_workout_target_max:
                context_parts.append(
                    f"Pre-workout glucose ({self.latest_glucose}) is above recommended range. " +
                    "Consider light activity only and recheck glucose after 30 minutes."
                )

        return " ".join(context_parts)

    def get_pre_workout_safety_context(self) -> str:
        """
        Generate a concise pre-workout safety message for the user.

        This is shown before starting a workout if the user has diabetes.
        """
        if not self.diabetes_type:
            return ""

        if not self.latest_glucose:
            return "Remember to check your blood glucose before starting your workout."

        if self.latest_glucose < 70:
            return (
                f"Your glucose is low ({self.latest_glucose} mg/dL). " +
                "Please have 15-30g of fast-acting carbs and wait 15 minutes before exercising."
            )
        elif self.latest_glucose < 100:
            return (
                f"Your glucose ({self.latest_glucose} mg/dL) is on the lower end. " +
                "Consider having a small snack before your workout."
            )
        elif self.latest_glucose > 250:
            return (
                f"Your glucose is elevated ({self.latest_glucose} mg/dL). " +
                "Check for ketones before intense exercise. Light activity may be beneficial."
            )
        elif self.latest_glucose > 180:
            return (
                f"Your glucose ({self.latest_glucose} mg/dL) is slightly elevated. " +
                "Exercise can help bring it down. Stay hydrated."
            )
        else:
            return f"Your glucose ({self.latest_glucose} mg/dL) is in a good range for exercise."


class UserContextService:
    """Service for logging and analyzing user context."""

    def __init__(self):
        pass

    def _get_time_of_day(self, dt: Optional[datetime] = None) -> str:
        """Get time of day classification."""
        if dt is None:
            dt = datetime.now()
        hour = dt.hour

        if 5 <= hour < 12:
            return "morning"
        elif 12 <= hour < 17:
            return "afternoon"
        elif 17 <= hour < 21:
            return "evening"
        else:
            return "night"

    def _build_context(
        self,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
        screen_name: Optional[str] = None,
        session_id: Optional[str] = None,
        extra_context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Build context dictionary with common fields."""
        now = datetime.now()
        context = {
            "time_of_day": self._get_time_of_day(now),
            "day_of_week": now.strftime("%A").lower(),
            "hour": now.hour,
        }

        if device:
            context["device"] = device
        if app_version:
            context["app_version"] = app_version
        if screen_name:
            context["screen_name"] = screen_name
        if session_id:
            context["session_id"] = session_id
        if extra_context:
            context.update(extra_context)

        return context

    async def log_event(
        self,
        user_id: str,
        event_type: EventType,
        event_data: Dict[str, Any],
        context: Optional[Dict[str, Any]] = None,
    ) -> Optional[str]:
        """
        Log a user event to the database.

        Args:
            user_id: User ID
            event_type: Type of event
            event_data: Event-specific data
            context: Contextual information

        Returns:
            Event ID if successful, None otherwise
        """
        try:
            db = get_supabase_db()

            record = {
                "user_id": user_id,
                "event_type": event_type.value,
                "event_data": event_data,
                "context": context or {},
            }

            response = db.client.table("user_context_logs").insert(record).execute()

            if response.data:
                return response.data[0]["id"]
            return None

        except Exception as e:
            logger.error(f"Failed to log event: {e}")
            return None

    async def log_mood_checkin(
        self,
        user_id: str,
        mood: str,
        workout_generated: bool = False,
        workout_id: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log a mood check-in event.

        Args:
            user_id: User ID
            mood: Selected mood (great/good/tired/stressed)
            workout_generated: Whether a workout was generated
            workout_id: ID of generated workout (if any)
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "mood": mood,
            "workout_generated": workout_generated,
            "workout_id": workout_id,
        }

        context = self._build_context(device=device, app_version=app_version)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.MOOD_CHECKIN,
            event_data=event_data,
            context=context,
        )

    async def log_workout_start(
        self,
        user_id: str,
        workout_id: str,
        source: str,  # "mood", "scheduled", "manual"
        mood: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log workout start event."""
        event_data = {
            "workout_id": workout_id,
            "source": source,
            "mood": mood,
        }

        context = self._build_context(device=device)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.WORKOUT_START,
            event_data=event_data,
            context=context,
        )

    async def log_workout_complete(
        self,
        user_id: str,
        workout_id: str,
        duration_seconds: int,
        exercises_completed: int,
        exercises_total: int,
        source: str,
        mood_at_start: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log workout completion event."""
        event_data = {
            "workout_id": workout_id,
            "duration_seconds": duration_seconds,
            "exercises_completed": exercises_completed,
            "exercises_total": exercises_total,
            "completion_rate": round(exercises_completed / exercises_total * 100, 1) if exercises_total > 0 else 0,
            "source": source,
            "mood_at_start": mood_at_start,
        }

        context = self._build_context(device=device)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.WORKOUT_COMPLETE,
            event_data=event_data,
            context=context,
        )

    async def log_score_view(
        self,
        user_id: str,
        screen: str,  # "home_card", "scoring_screen", "strength_detail", etc.
        duration_ms: Optional[int] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log score view event."""
        event_data = {
            "screen": screen,
            "duration_ms": duration_ms,
        }

        context = self._build_context(device=device, screen_name=screen)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.SCORE_VIEW,
            event_data=event_data,
            context=context,
        )

    async def log_nutrition_log(
        self,
        user_id: str,
        meal_type: str,  # "breakfast", "lunch", "dinner", "snack"
        items_count: int,
        calories: float,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log nutrition logging event."""
        event_data = {
            "meal_type": meal_type,
            "items_count": items_count,
            "calories": calories,
        }

        context = self._build_context(device=device)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.NUTRITION_LOG,
            event_data=event_data,
            context=context,
        )

    async def update_mood_workout_completed(
        self,
        user_id: str,
        mood_checkin_id: str,
    ) -> bool:
        """
        Update mood check-in record to mark workout as completed.

        Args:
            user_id: User ID
            mood_checkin_id: Mood check-in ID

        Returns:
            True if successful
        """
        try:
            db = get_supabase_db()

            db.client.table("mood_checkins").update({
                "workout_completed": True,
            }).eq("id", mood_checkin_id).eq("user_id", user_id).execute()

            return True

        except Exception as e:
            logger.error(f"Failed to update mood workout completed: {e}")
            return False

    async def get_cardio_patterns(
        self,
        user_id: str,
        days: int = 30,
    ) -> CardioPatterns:
        """
        Analyze user's cardio activity patterns.

        This method fetches cardio session data and analyzes:
        - Recent activity (last 7 days)
        - Location preferences (outdoor vs indoor/treadmill)
        - Cardio frequency and streak
        - Balance with strength training

        Args:
            user_id: User ID
            days: Number of days to analyze for historical patterns

        Returns:
            CardioPatterns with analyzed cardio data
        """
        try:
            db = get_supabase_db()
            now = datetime.now()
            cutoff_30_days = (now - timedelta(days=days)).isoformat()
            cutoff_7_days = (now - timedelta(days=7)).isoformat()

            # Get all cardio sessions for the analysis period
            cardio_response = db.client.table("cardio_sessions").select("*").eq(
                "user_id", user_id
            ).gte(
                "created_at", cutoff_30_days
            ).order(
                "created_at", desc=True
            ).execute()

            all_sessions = cardio_response.data or []

            if not all_sessions:
                return CardioPatterns()

            # Filter recent sessions (last 7 days)
            recent_sessions = [
                s for s in all_sessions
                if s["created_at"] >= cutoff_7_days
            ]

            # Analyze recent activity
            recent_sessions_count = len(recent_sessions)
            recent_total_duration = sum(s.get("duration_minutes", 0) for s in recent_sessions)
            recent_cardio_types = list(set(s["cardio_type"] for s in recent_sessions))
            recent_locations = list(set(s["location"] for s in recent_sessions))

            # Analyze location preferences
            location_counts: Dict[str, int] = {}
            outdoor_count = 0
            treadmill_count = 0

            for session in all_sessions:
                location = session["location"]
                location_counts[location] = location_counts.get(location, 0) + 1

                # Track outdoor vs treadmill
                if location in [CardioLocation.OUTDOOR.value, CardioLocation.TRAIL.value, CardioLocation.TRACK.value]:
                    outdoor_count += 1
                elif location == CardioLocation.TREADMILL.value:
                    treadmill_count += 1

            total_sessions = len(all_sessions)
            preferred_location = max(location_counts.keys(), key=lambda k: location_counts[k]) if location_counts else None
            is_outdoor_enthusiast = (outdoor_count / total_sessions) > 0.6 if total_sessions > 0 else False
            is_treadmill_user = (treadmill_count / total_sessions) > 0.4 if total_sessions > 0 else False

            # Analyze cardio type preferences
            type_counts: Dict[str, int] = {}
            for session in all_sessions:
                cardio_type = session["cardio_type"]
                type_counts[cardio_type] = type_counts.get(cardio_type, 0) + 1

            primary_cardio_type = max(type_counts.keys(), key=lambda k: type_counts[k]) if type_counts else None

            # Calculate frequency
            weeks = max(1, days / 7)
            avg_cardio_sessions_per_week = total_sessions / weeks

            # Calculate streak (consecutive days with cardio)
            session_dates = sorted(set(
                datetime.fromisoformat(s["created_at"].replace("Z", "+00:00")).date()
                for s in all_sessions
            ), reverse=True)

            cardio_streak_days = 0
            last_cardio_date = session_dates[0] if session_dates else None

            if session_dates:
                today = now.date()
                # Check if there's a session today or yesterday to start counting
                if session_dates[0] >= today - timedelta(days=1):
                    cardio_streak_days = 1
                    for i in range(1, len(session_dates)):
                        expected_date = session_dates[0] - timedelta(days=i)
                        if session_dates[i] == expected_date:
                            cardio_streak_days += 1
                        else:
                            break

            # Calculate cardio to strength ratio
            # Get strength workout completions from the same period
            workout_response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).eq(
                "event_type", "workout_complete"
            ).gte(
                "created_at", cutoff_30_days
            ).execute()

            strength_workouts = len(workout_response.data or [])
            cardio_to_strength_ratio = 0.0
            needs_more_cardio = False
            needs_more_strength = False

            if strength_workouts > 0:
                cardio_to_strength_ratio = total_sessions / strength_workouts
                needs_more_cardio = cardio_to_strength_ratio < 0.3
                needs_more_strength = cardio_to_strength_ratio > 2.0
            elif total_sessions > 0:
                # All cardio, no strength
                needs_more_strength = True
                cardio_to_strength_ratio = float('inf') if total_sessions > 2 else float(total_sessions)
            else:
                # No activity at all
                needs_more_cardio = True

            return CardioPatterns(
                recent_sessions_count=recent_sessions_count,
                recent_total_duration_minutes=recent_total_duration,
                recent_cardio_types=recent_cardio_types,
                recent_locations=recent_locations,
                preferred_location=preferred_location,
                location_frequency=location_counts,
                is_outdoor_enthusiast=is_outdoor_enthusiast,
                is_treadmill_user=is_treadmill_user,
                avg_cardio_sessions_per_week=avg_cardio_sessions_per_week,
                cardio_streak_days=cardio_streak_days,
                last_cardio_date=last_cardio_date,
                primary_cardio_type=primary_cardio_type,
                cardio_type_frequency=type_counts,
                cardio_to_strength_ratio=cardio_to_strength_ratio if cardio_to_strength_ratio != float('inf') else 99.0,
                needs_more_cardio=needs_more_cardio,
                needs_more_strength=needs_more_strength,
            )

        except Exception as e:
            logger.error(f"Failed to get cardio patterns: {e}")
            return CardioPatterns()

    async def get_user_patterns(
        self,
        user_id: str,
        days: int = 30,
    ) -> UserPatterns:
        """
        Analyze user behavior patterns from context logs.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            UserPatterns with analyzed data
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            # Get all events for the period
            response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).gte(
                "created_at", cutoff
            ).execute()

            events = response.data or []

            patterns = UserPatterns(
                user_id=user_id,
                total_events_30_days=len(events),
                mood_frequency={},
                mood_workout_completion_rate={},
            )

            if not events:
                return patterns

            # Analyze mood check-ins
            mood_checkins = [e for e in events if e["event_type"] == "mood_checkin"]
            if mood_checkins:
                mood_counts = {}
                mood_completions = {}
                mood_totals = {}

                for checkin in mood_checkins:
                    mood = checkin["event_data"].get("mood")
                    if mood:
                        mood_counts[mood] = mood_counts.get(mood, 0) + 1
                        mood_totals[mood] = mood_totals.get(mood, 0) + 1

                        if checkin["event_data"].get("workout_completed"):
                            mood_completions[mood] = mood_completions.get(mood, 0) + 1

                patterns.mood_frequency = mood_counts
                patterns.most_common_mood = max(mood_counts.keys(), key=lambda k: mood_counts[k]) if mood_counts else None

                # Calculate completion rates
                for mood in mood_totals:
                    if mood_totals[mood] > 0:
                        rate = (mood_completions.get(mood, 0) / mood_totals[mood]) * 100
                        patterns.mood_workout_completion_rate[mood] = round(rate, 1)

            # Analyze workout times
            workout_starts = [e for e in events if e["event_type"] == "workout_start"]
            if workout_starts:
                time_counts = {}
                for ws in workout_starts:
                    time_of_day = ws["context"].get("time_of_day")
                    if time_of_day:
                        time_counts[time_of_day] = time_counts.get(time_of_day, 0) + 1

                if time_counts:
                    patterns.preferred_workout_time = max(time_counts.keys(), key=lambda k: time_counts[k])

            # Calculate workouts per week
            workout_completes = [e for e in events if e["event_type"] == "workout_complete"]
            weeks = max(1, days / 7)
            patterns.avg_workouts_per_week = len(workout_completes) / weeks

            # Calculate nutrition logging rate
            nutrition_logs = [e for e in events if e["event_type"] == "nutrition_log"]
            patterns.nutrition_logging_rate = (len(nutrition_logs) / days) * 100 if days > 0 else 0

            # Analyze most active day
            day_counts = {}
            for event in events:
                day = event["context"].get("day_of_week")
                if day:
                    day_counts[day] = day_counts.get(day, 0) + 1

            if day_counts:
                patterns.most_active_day = max(day_counts.keys(), key=lambda k: day_counts[k])

            # Get cardio patterns
            cardio_patterns = await self.get_cardio_patterns(user_id, days)
            patterns.cardio_patterns = cardio_patterns

            return patterns

        except Exception as e:
            logger.error(f"Failed to get user patterns: {e}")
            return UserPatterns(user_id=user_id)

    async def get_user_patterns_with_cardio_context(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get user patterns with AI-ready cardio context.

        This is a convenience method that returns user patterns along with
        a formatted context string for AI workout generation.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Dictionary with patterns and AI context string
        """
        patterns = await self.get_user_patterns(user_id, days)

        ai_context = ""
        if patterns.cardio_patterns:
            ai_context = patterns.cardio_patterns.get_ai_recommendations_context()

        return {
            "patterns": patterns.to_dict(),
            "cardio_ai_context": ai_context,
        }

    async def log_performance_comparison_viewed(
        self,
        user_id: str,
        workout_id: str,
        workout_log_id: str,
        improved_count: int = 0,
        declined_count: int = 0,
        first_time_count: int = 0,
        exercises_compared: int = 0,
        duration_diff_seconds: Optional[int] = None,
        volume_diff_percentage: Optional[float] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user views performance comparison after workout completion.

        Args:
            user_id: User ID
            workout_id: Workout ID
            workout_log_id: Workout log ID
            improved_count: Number of exercises with improvement
            declined_count: Number of exercises with decline
            first_time_count: Number of first-time exercises
            exercises_compared: Total exercises compared
            duration_diff_seconds: Difference in workout duration vs previous
            volume_diff_percentage: Percentage change in total volume
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "workout_id": workout_id,
            "workout_log_id": workout_log_id,
            "improved_count": improved_count,
            "declined_count": declined_count,
            "first_time_count": first_time_count,
            "exercises_compared": exercises_compared,
            "duration_diff_seconds": duration_diff_seconds,
            "volume_diff_percentage": volume_diff_percentage,
        }

        context = self._build_context(device=device, screen_name="workout_complete")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.PERFORMANCE_COMPARISON_VIEWED,
            event_data=event_data,
            context=context,
        )

    async def get_mood_workout_correlation(
        self,
        user_id: str,
        days: int = 30,
    ) -> List[Dict[str, Any]]:
        """
        Get correlation between mood selections and workout completion.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            List of mood correlation data
        """
        try:
            db = get_supabase_db()

            # Use the pre-built view
            response = db.client.from_("mood_workout_correlation").select("*").eq(
                "user_id", user_id
            ).execute()

            return response.data or []

        except Exception as e:
            logger.error(f"Failed to get mood workout correlation: {e}")
            return []

    async def log_difficulty_adjustment(
        self,
        user_id: str,
        adjustment: int,
        recommendation: str,
        feedback_counts: Dict[str, int],
        confidence: float,
        workout_type: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a difficulty adjustment is applied during workout generation.

        This helps track the effectiveness of the feedback loop:
        - Did users with positive adjustment get harder workouts?
        - Did users with negative adjustment find the easier workouts better?
        - How often are adjustments being made?

        Args:
            user_id: User ID
            adjustment: The difficulty adjustment applied (-2 to +2)
            recommendation: Human-readable explanation of the adjustment
            feedback_counts: Dict with too_easy, just_right, too_hard counts
            confidence: Confidence score of the adjustment (0-1)
            workout_type: Type of workout being generated (weekly, monthly, etc.)
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "adjustment": adjustment,
            "recommendation": recommendation,
            "too_easy_count": feedback_counts.get("too_easy_count", 0),
            "just_right_count": feedback_counts.get("just_right_count", 0),
            "too_hard_count": feedback_counts.get("too_hard_count", 0),
            "total_feedback_count": feedback_counts.get("total_feedback_count", 0),
            "confidence": round(confidence, 2),
            "workout_type": workout_type,
        }

        context = self._build_context(
            device=device,
            screen_name="workout_generation",
            extra_context={"feedback_loop_version": "1.0"},
        )

        logger.info(
            f"[Difficulty Adjustment Log] User {user_id}: adjustment={adjustment:+d}, "
            f"confidence={confidence:.2f}, workout_type={workout_type}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.DIFFICULTY_ADJUSTMENT_APPLIED,
            event_data=event_data,
            context=context,
        )

    async def log_user_ready_for_progression(
        self,
        user_id: str,
        exercise_name: str,
        suggested_variant: str,
        consecutive_easy_sessions: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user becomes ready for exercise progression.

        This event is logged when:
        - User has rated an exercise as "too easy" for 2+ consecutive sessions
        - A valid next variant exists in the progression chain

        Args:
            user_id: User ID
            exercise_name: Current exercise name
            suggested_variant: Suggested harder variant
            consecutive_easy_sessions: Number of consecutive easy ratings
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "exercise_name": exercise_name,
            "suggested_variant": suggested_variant,
            "consecutive_easy_sessions": consecutive_easy_sessions,
        }

        context = self._build_context(
            device=device,
            screen_name="workout_feedback",
            extra_context={"progression_system_version": "1.0"},
        )

        logger.info(
            f"[Progression Ready] User {user_id}: {exercise_name} -> {suggested_variant} "
            f"(easy sessions: {consecutive_easy_sessions})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.USER_READY_FOR_PROGRESSION,
            event_data=event_data,
            context=context,
        )

    async def log_progression_accepted(
        self,
        user_id: str,
        from_exercise: str,
        to_exercise: str,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user accepts a progression suggestion.

        This event tracks successful progression adoptions, helping us
        understand which progression suggestions are well-received.

        Args:
            user_id: User ID
            from_exercise: Original exercise name
            to_exercise: New harder exercise name
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "from_exercise": from_exercise,
            "to_exercise": to_exercise,
            "action": "accepted",
        }

        context = self._build_context(
            device=device,
            screen_name="workout_complete",
            extra_context={"progression_system_version": "1.0"},
        )

        logger.info(
            f"[Progression Accepted] User {user_id}: {from_exercise} -> {to_exercise}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.USER_ACCEPTED_PROGRESSION,
            event_data=event_data,
            context=context,
        )

    async def log_progression_declined(
        self,
        user_id: str,
        from_exercise: str,
        to_exercise: str,
        reason: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user declines a progression suggestion.

        This event helps us:
        - Apply cooldown to avoid spamming the same suggestion
        - Understand why users decline progressions
        - Improve the progression chain recommendations

        Args:
            user_id: User ID
            from_exercise: Original exercise name
            to_exercise: Suggested exercise that was declined
            reason: Optional reason for declining
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "from_exercise": from_exercise,
            "to_exercise": to_exercise,
            "action": "declined",
            "reason": reason,
        }

        context = self._build_context(
            device=device,
            screen_name="workout_complete",
            extra_context={"progression_system_version": "1.0"},
        )

        logger.info(
            f"[Progression Declined] User {user_id}: {from_exercise} -> {to_exercise} "
            f"(reason: {reason or 'not provided'})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.USER_DECLINED_PROGRESSION,
            event_data=event_data,
            context=context,
        )

    # ==========================================================================
    # TRIAL/DEMO EVENT LOGGING - For tracking what convinces users to subscribe
    # ==========================================================================

    async def log_trial_event(
        self,
        user_id: str,
        event_type: EventType,
        event_data: Dict[str, Any],
        session_id: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Generic method to log trial/demo events with consistent structure.

        Args:
            user_id: User ID (can be anonymous/temporary for pre-signup)
            event_type: Type of trial/demo event
            event_data: Event-specific data
            session_id: Unique session identifier for tracking sequences
            device: Device type (iOS, Android, etc.)
            app_version: App version string

        Returns:
            Event ID if successful
        """
        context = self._build_context(
            device=device,
            app_version=app_version,
            session_id=session_id,
            extra_context={
                "trial_tracking_version": "1.0",
                "is_trial_event": True,
            },
        )

        logger.info(
            f"[Trial Event] User {user_id}: {event_type.value} - "
            f"session={session_id}, data={event_data}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=event_data,
            context=context,
        )

    async def log_plan_preview_viewed(
        self,
        user_id: str,
        plan_type: str,
        workout_count: int,
        duration_days: int,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user sees their personalized plan preview.

        This is a key conversion moment - users see what they could get.

        Args:
            user_id: User ID
            plan_type: Type of plan shown (e.g., "strength", "weight_loss", "muscle_building")
            workout_count: Number of workouts in the plan
            duration_days: Plan duration in days
            session_id: Session identifier
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "plan_type": plan_type,
            "workout_count": workout_count,
            "duration_days": duration_days,
            "preview_shown_at": datetime.now().isoformat(),
        }

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.PLAN_PREVIEW_VIEWED,
            event_data=event_data,
            session_id=session_id,
            device=device,
            app_version=app_version,
        )

    async def log_plan_preview_scroll_depth(
        self,
        user_id: str,
        scroll_percentage: float,
        sections_viewed: List[str],
        time_spent_seconds: int,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log how far user scrolled through the plan preview.

        Higher scroll depth correlates with higher conversion.

        Args:
            user_id: User ID
            scroll_percentage: How far they scrolled (0-100)
            sections_viewed: List of sections they viewed
            time_spent_seconds: Time spent on preview screen
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "scroll_percentage": min(100, max(0, scroll_percentage)),
            "sections_viewed": sections_viewed,
            "sections_count": len(sections_viewed),
            "time_spent_seconds": time_spent_seconds,
            "engagement_score": self._calculate_engagement_score(
                scroll_percentage, len(sections_viewed), time_spent_seconds
            ),
        }

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.PLAN_PREVIEW_SCROLL_DEPTH,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    def _calculate_engagement_score(
        self,
        scroll_percentage: float,
        sections_count: int,
        time_spent_seconds: int,
    ) -> float:
        """
        Calculate an engagement score for plan preview viewing.

        Score ranges from 0-100, higher is more engaged.
        """
        # Weight: scroll (40%), sections (30%), time (30%)
        scroll_score = min(scroll_percentage, 100) * 0.4
        sections_score = min(sections_count * 10, 100) * 0.3
        # Optimal time: 30-120 seconds
        if time_spent_seconds < 5:
            time_score = 0
        elif time_spent_seconds < 30:
            time_score = (time_spent_seconds / 30) * 50
        elif time_spent_seconds <= 120:
            time_score = 100
        else:
            # Diminishing returns after 2 minutes
            time_score = max(50, 100 - (time_spent_seconds - 120) / 6)
        time_score *= 0.3

        return round(scroll_score + sections_score + time_score, 1)

    async def log_try_workout_started(
        self,
        user_id: str,
        workout_id: str,
        workout_name: str,
        exercise_count: int,
        estimated_duration_minutes: int,
        source: str,  # "plan_preview", "home", "deep_link"
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user starts the free trial workout.

        This is a strong intent signal - user is willing to try.

        Args:
            user_id: User ID
            workout_id: Trial workout ID
            workout_name: Name of the workout
            exercise_count: Number of exercises
            estimated_duration_minutes: Expected workout duration
            source: Where they started from
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "workout_id": workout_id,
            "workout_name": workout_name,
            "exercise_count": exercise_count,
            "estimated_duration_minutes": estimated_duration_minutes,
            "source": source,
            "started_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Try Workout Started] User {user_id}: {workout_name} ({exercise_count} exercises)"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRY_WORKOUT_STARTED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_try_workout_completed(
        self,
        user_id: str,
        workout_id: str,
        workout_name: str,
        duration_seconds: int,
        exercises_completed: int,
        exercises_total: int,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user finishes the trial workout.

        This is the highest conversion signal - they experienced the value.

        Args:
            user_id: User ID
            workout_id: Trial workout ID
            workout_name: Name of the workout
            duration_seconds: Actual workout duration
            exercises_completed: Exercises they finished
            exercises_total: Total exercises in workout
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        completion_rate = round(
            (exercises_completed / exercises_total * 100) if exercises_total > 0 else 0, 1
        )

        event_data = {
            "workout_id": workout_id,
            "workout_name": workout_name,
            "duration_seconds": duration_seconds,
            "duration_minutes": round(duration_seconds / 60, 1),
            "exercises_completed": exercises_completed,
            "exercises_total": exercises_total,
            "completion_rate": completion_rate,
            "completed_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Try Workout Completed] User {user_id}: {workout_name} - "
            f"{exercises_completed}/{exercises_total} ({completion_rate}%) in {round(duration_seconds / 60)}min"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRY_WORKOUT_COMPLETED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_try_workout_abandoned(
        self,
        user_id: str,
        workout_id: str,
        workout_name: str,
        duration_seconds: int,
        exercises_completed: int,
        exercises_total: int,
        last_exercise_name: Optional[str] = None,
        abandon_reason: Optional[str] = None,  # "closed_app", "back_pressed", "timeout"
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user leaves mid-workout.

        Understanding where users drop off helps improve the trial experience.

        Args:
            user_id: User ID
            workout_id: Trial workout ID
            workout_name: Name of the workout
            duration_seconds: Time spent before abandoning
            exercises_completed: Exercises completed before leaving
            exercises_total: Total exercises in workout
            last_exercise_name: The exercise they were on when leaving
            abandon_reason: Why they left (if known)
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        progress_percentage = round(
            (exercises_completed / exercises_total * 100) if exercises_total > 0 else 0, 1
        )

        event_data = {
            "workout_id": workout_id,
            "workout_name": workout_name,
            "duration_seconds": duration_seconds,
            "exercises_completed": exercises_completed,
            "exercises_total": exercises_total,
            "progress_percentage": progress_percentage,
            "last_exercise_name": last_exercise_name,
            "abandon_reason": abandon_reason,
            "abandoned_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Try Workout Abandoned] User {user_id}: {workout_name} - "
            f"dropped at {progress_percentage}% ({exercises_completed}/{exercises_total}), "
            f"reason: {abandon_reason or 'unknown'}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRY_WORKOUT_ABANDONED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_demo_day_started(
        self,
        user_id: str,
        demo_expiry: datetime,
        features_unlocked: List[str],
        source: str,  # "onboarding", "promotion", "referral"
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when 24-hour demo begins.

        Args:
            user_id: User ID
            demo_expiry: When the demo expires
            features_unlocked: List of features available during demo
            source: How they got the demo
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "demo_started_at": datetime.now().isoformat(),
            "demo_expiry": demo_expiry.isoformat(),
            "demo_duration_hours": 24,
            "features_unlocked": features_unlocked,
            "features_count": len(features_unlocked),
            "source": source,
        }

        logger.info(
            f"[Demo Day Started] User {user_id}: expires {demo_expiry.isoformat()}, "
            f"features: {len(features_unlocked)}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.DEMO_DAY_STARTED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_demo_day_expired(
        self,
        user_id: str,
        features_used: List[str],
        workouts_completed: int,
        total_active_time_minutes: int,
        converted: bool,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when demo time runs out.

        Captures what they did during the demo for attribution.

        Args:
            user_id: User ID
            features_used: Features they actually used
            workouts_completed: Number of workouts done during demo
            total_active_time_minutes: Total time spent active in app
            converted: Whether they converted before expiry
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "demo_expired_at": datetime.now().isoformat(),
            "features_used": features_used,
            "features_used_count": len(features_used),
            "workouts_completed": workouts_completed,
            "total_active_time_minutes": total_active_time_minutes,
            "converted_before_expiry": converted,
        }

        logger.info(
            f"[Demo Day Expired] User {user_id}: used {len(features_used)} features, "
            f"{workouts_completed} workouts, converted={converted}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.DEMO_DAY_EXPIRED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_trial_started(
        self,
        user_id: str,
        trial_duration_days: int,
        trial_type: str,  # "7_day", "14_day", "custom"
        source: str,  # "onboarding", "paywall", "promotion"
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user starts 7-day (or other) trial.

        Args:
            user_id: User ID
            trial_duration_days: Length of trial in days
            trial_type: Type of trial
            source: Where they started trial from
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        trial_end = datetime.now() + timedelta(days=trial_duration_days)

        event_data = {
            "trial_started_at": datetime.now().isoformat(),
            "trial_end_date": trial_end.isoformat(),
            "trial_duration_days": trial_duration_days,
            "trial_type": trial_type,
            "source": source,
        }

        logger.info(
            f"[Trial Started] User {user_id}: {trial_type} ({trial_duration_days} days), "
            f"source={source}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRIAL_STARTED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_trial_converted(
        self,
        user_id: str,
        trial_type: str,
        days_until_conversion: int,
        subscription_plan: str,
        price_paid: float,
        currency: str,
        conversion_source: str,  # "in_app", "web", "promotion"
        last_action_before_conversion: Optional[str] = None,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when trial converts to paid.

        This is the ultimate success metric - includes attribution data.

        Args:
            user_id: User ID
            trial_type: Type of trial they were on
            days_until_conversion: Days from trial start to conversion
            subscription_plan: Plan they subscribed to
            price_paid: Amount paid
            currency: Currency code
            conversion_source: Where conversion happened
            last_action_before_conversion: Last tracked action
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "converted_at": datetime.now().isoformat(),
            "trial_type": trial_type,
            "days_until_conversion": days_until_conversion,
            "subscription_plan": subscription_plan,
            "price_paid": price_paid,
            "currency": currency,
            "conversion_source": conversion_source,
            "last_action_before_conversion": last_action_before_conversion,
        }

        logger.info(
            f"[Trial Converted] User {user_id}: {trial_type} -> {subscription_plan} "
            f"({days_until_conversion} days), ${price_paid} {currency}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRIAL_CONVERTED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_paywall_viewed(
        self,
        user_id: str,
        paywall_variant: str,  # A/B test variant
        trigger: str,  # "onboarding", "feature_gate", "settings", "home"
        plans_shown: List[Dict[str, Any]],
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when paywall screen is shown.

        Args:
            user_id: User ID
            paywall_variant: Which paywall design they saw
            trigger: What triggered the paywall
            plans_shown: List of plans shown with prices
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "paywall_variant": paywall_variant,
            "trigger": trigger,
            "plans_shown": plans_shown,
            "plans_count": len(plans_shown),
            "viewed_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Paywall Viewed] User {user_id}: variant={paywall_variant}, "
            f"trigger={trigger}, plans={len(plans_shown)}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.PAYWALL_VIEWED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_paywall_skipped(
        self,
        user_id: str,
        paywall_variant: str,
        trigger: str,
        time_on_paywall_seconds: int,
        skip_method: str,  # "back_button", "close_button", "swipe"
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user skips paywall.

        Understanding why users skip helps optimize conversion.

        Args:
            user_id: User ID
            paywall_variant: Which paywall design they saw
            trigger: What triggered the paywall
            time_on_paywall_seconds: How long they looked at it
            skip_method: How they dismissed it
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "paywall_variant": paywall_variant,
            "trigger": trigger,
            "time_on_paywall_seconds": time_on_paywall_seconds,
            "skip_method": skip_method,
            "skipped_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Paywall Skipped] User {user_id}: variant={paywall_variant}, "
            f"time={time_on_paywall_seconds}s, method={skip_method}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.PAYWALL_SKIPPED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_free_feature_tapped(
        self,
        user_id: str,
        feature_name: str,
        screen_context: str,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user taps on a free feature.

        Helps understand which free features drive engagement.

        Args:
            user_id: User ID
            feature_name: Name of the feature
            screen_context: Screen where they tapped
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "feature_name": feature_name,
            "screen_context": screen_context,
            "feature_type": "free",
            "tapped_at": datetime.now().isoformat(),
        }

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.FREE_FEATURE_TAPPED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_locked_feature_tapped(
        self,
        user_id: str,
        feature_name: str,
        screen_context: str,
        showed_upgrade_prompt: bool,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user taps on a locked/premium feature.

        High-intent signal - user wants more than free tier.

        Args:
            user_id: User ID
            feature_name: Name of the feature
            screen_context: Screen where they tapped
            showed_upgrade_prompt: Whether we showed upgrade UI
            session_id: Session identifier
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "feature_name": feature_name,
            "screen_context": screen_context,
            "feature_type": "locked",
            "showed_upgrade_prompt": showed_upgrade_prompt,
            "tapped_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Locked Feature Tapped] User {user_id}: {feature_name} on {screen_context}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.LOCKED_FEATURE_TAPPED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    # ==========================================================================
    # SPLIT SCREEN USAGE LOGGING - Track multitasking behavior
    # ==========================================================================

    async def log_split_screen_entered(
        self,
        user_id: str,
        device_type: str,
        screen_width: int,
        screen_height: int,
        app_width: int,
        app_height: int,
        partner_app: Optional[str] = None,
        current_screen: Optional[str] = None,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user enters split screen mode.

        This helps understand:
        - How users multitask while using the app
        - Which screens are used in split screen mode
        - Device and screen size patterns for split screen usage

        Args:
            user_id: User ID
            device_type: Type of device (e.g., "phone", "tablet", "foldable")
            screen_width: Full screen width in pixels
            screen_height: Full screen height in pixels
            app_width: App window width in split screen
            app_height: App window height in split screen
            partner_app: Name of the app in the other split (if detectable)
            current_screen: Current screen name when entering split screen
            session_id: Session identifier
            device: Device platform (iOS, Android)
            app_version: App version

        Returns:
            Event ID if successful
        """
        # Calculate the split ratio
        split_ratio = round(app_width / screen_width, 2) if screen_width > 0 else 0.5

        event_data = {
            "device_type": device_type,
            "screen_width": screen_width,
            "screen_height": screen_height,
            "app_width": app_width,
            "app_height": app_height,
            "split_ratio": split_ratio,
            "partner_app": partner_app,
            "current_screen": current_screen,
            "entered_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name=current_screen,
            session_id=session_id,
            extra_context={
                "split_screen_tracking_version": "1.0",
                "is_split_screen": True,
            },
        )

        logger.info(
            f"[Split Screen Entered] User {user_id}: device={device_type}, "
            f"ratio={split_ratio:.0%}, partner={partner_app or 'unknown'}, "
            f"screen={current_screen}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.SPLIT_SCREEN_ENTERED,
            event_data=event_data,
            context=context,
        )

    async def log_split_screen_exited(
        self,
        user_id: str,
        duration_seconds: int,
        device_type: str,
        screens_viewed: Optional[List[str]] = None,
        features_used: Optional[List[str]] = None,
        workout_active_during_split: bool = False,
        partner_app: Optional[str] = None,
        exit_reason: Optional[str] = None,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user exits split screen mode.

        This captures:
        - Duration spent in split screen
        - Features used while in split screen
        - Whether a workout was active during split screen

        Args:
            user_id: User ID
            duration_seconds: Time spent in split screen mode
            device_type: Type of device
            screens_viewed: List of screens viewed during split screen
            features_used: List of features used during split screen
            workout_active_during_split: Whether user had an active workout
            partner_app: Name of the partner app (if detectable)
            exit_reason: Reason for exiting (e.g., "user_action", "app_closed", "partner_closed")
            session_id: Session identifier
            device: Device platform
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "duration_seconds": duration_seconds,
            "duration_minutes": round(duration_seconds / 60, 1),
            "device_type": device_type,
            "screens_viewed": screens_viewed or [],
            "screens_count": len(screens_viewed) if screens_viewed else 0,
            "features_used": features_used or [],
            "features_count": len(features_used) if features_used else 0,
            "workout_active_during_split": workout_active_during_split,
            "partner_app": partner_app,
            "exit_reason": exit_reason,
            "exited_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            session_id=session_id,
            extra_context={
                "split_screen_tracking_version": "1.0",
                "is_split_screen_exit": True,
            },
        )

        logger.info(
            f"[Split Screen Exited] User {user_id}: duration={duration_seconds}s "
            f"({round(duration_seconds / 60, 1)}min), device={device_type}, "
            f"screens={len(screens_viewed or [])}, features={len(features_used or [])}, "
            f"workout_active={workout_active_during_split}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.SPLIT_SCREEN_EXITED,
            event_data=event_data,
            context=context,
        )

    # ==========================================================================
    # QUICK WORKOUT VIA CHAT LOGGING - Track AI Coach workout generation
    # ==========================================================================

    async def log_quick_workout_chat_request(
        self,
        user_id: str,
        message: str,
        detected_duration: Optional[int] = None,
        detected_type: Optional[str] = None,
        detected_intensity: Optional[str] = None,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user requests a quick workout via the AI Coach chat.

        This tracks the initial request before workout generation begins.

        Args:
            user_id: User ID
            message: The user's message requesting the workout
            detected_duration: Detected workout duration in minutes
            detected_type: Detected workout type (full_body, upper, cardio, etc.)
            detected_intensity: Detected intensity level
            session_id: Chat session ID
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "message": message[:500],  # Truncate for storage
            "detected_duration": detected_duration,
            "detected_type": detected_type,
            "detected_intensity": detected_intensity,
            "source": "chat",
            "requested_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            session_id=session_id,
            screen_name="chat",
            extra_context={"quick_workout_version": "1.0"},
        )

        logger.info(
            f"[Quick Workout Chat Request] User {user_id}: "
            f"duration={detected_duration}min, type={detected_type}, "
            f"intensity={detected_intensity}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.QUICK_WORKOUT_CHAT_REQUEST,
            event_data=event_data,
            context=context,
        )

    async def log_quick_workout_chat_generated(
        self,
        user_id: str,
        workout_id: int,
        workout_name: str,
        duration_minutes: int,
        workout_type: str,
        intensity: str,
        exercise_count: int,
        is_new_workout: bool = True,
        generation_time_ms: Optional[int] = None,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a quick workout is successfully generated via AI Coach chat.

        This tracks successful workout generation and the resulting workout details.

        Args:
            user_id: User ID
            workout_id: The generated workout's ID
            workout_name: Name of the workout
            duration_minutes: Workout duration
            workout_type: Type of workout
            intensity: Workout intensity
            exercise_count: Number of exercises
            is_new_workout: Whether this is a new workout or update to existing
            generation_time_ms: Time taken to generate workout
            session_id: Chat session ID
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "workout_id": workout_id,
            "workout_name": workout_name,
            "duration_minutes": duration_minutes,
            "workout_type": workout_type,
            "intensity": intensity,
            "exercise_count": exercise_count,
            "is_new_workout": is_new_workout,
            "generation_time_ms": generation_time_ms,
            "source": "chat",
            "generated_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            session_id=session_id,
            screen_name="chat",
            extra_context={"quick_workout_version": "1.0"},
        )

        logger.info(
            f"[Quick Workout Chat Generated] User {user_id}: "
            f"workout_id={workout_id}, name='{workout_name}', "
            f"duration={duration_minutes}min, exercises={exercise_count}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.QUICK_WORKOUT_CHAT_GENERATED,
            event_data=event_data,
            context=context,
        )

    async def log_quick_workout_chat_failed(
        self,
        user_id: str,
        error_message: str,
        detected_duration: Optional[int] = None,
        detected_type: Optional[str] = None,
        error_code: Optional[str] = None,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when quick workout generation via chat fails.

        This tracks failed generation attempts for debugging and improvement.

        Args:
            user_id: User ID
            error_message: The error that occurred
            detected_duration: Detected workout duration
            detected_type: Detected workout type
            error_code: Error code if available
            session_id: Chat session ID
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "error_message": error_message[:500],
            "detected_duration": detected_duration,
            "detected_type": detected_type,
            "error_code": error_code,
            "source": "chat",
            "failed_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            session_id=session_id,
            screen_name="chat",
            extra_context={"quick_workout_version": "1.0"},
        )

        logger.warning(
            f"[Quick Workout Chat Failed] User {user_id}: "
            f"error='{error_message[:100]}', type={detected_type}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.QUICK_WORKOUT_CHAT_FAILED,
            event_data=event_data,
            context=context,
        )

    async def get_quick_workout_chat_analytics(
        self,
        user_id: Optional[str] = None,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get analytics for quick workout chat feature usage.

        Args:
            user_id: Optional user ID to filter by
            days: Number of days to analyze

        Returns:
            Dictionary with analytics data
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            # Build query
            query = db.client.table("user_context_logs").select("*").in_(
                "event_type", [
                    EventType.QUICK_WORKOUT_CHAT_REQUEST.value,
                    EventType.QUICK_WORKOUT_CHAT_GENERATED.value,
                    EventType.QUICK_WORKOUT_CHAT_FAILED.value,
                ]
            ).gte("created_at", cutoff)

            if user_id:
                query = query.eq("user_id", user_id)

            response = query.execute()
            events = response.data or []

            if not events:
                return {
                    "period_days": days,
                    "total_requests": 0,
                    "success_rate": 0,
                }

            requests = [e for e in events if e["event_type"] == EventType.QUICK_WORKOUT_CHAT_REQUEST.value]
            generated = [e for e in events if e["event_type"] == EventType.QUICK_WORKOUT_CHAT_GENERATED.value]
            failed = [e for e in events if e["event_type"] == EventType.QUICK_WORKOUT_CHAT_FAILED.value]

            # Analyze workout types requested
            type_counts: Dict[str, int] = {}
            duration_counts: Dict[int, int] = {}
            for e in requests:
                wtype = e["event_data"].get("detected_type")
                duration = e["event_data"].get("detected_duration")
                if wtype:
                    type_counts[wtype] = type_counts.get(wtype, 0) + 1
                if duration:
                    duration_counts[duration] = duration_counts.get(duration, 0) + 1

            success_rate = round(len(generated) / len(requests) * 100, 1) if requests else 0

            return {
                "period_days": days,
                "user_id": user_id,
                "total_requests": len(requests),
                "successful_generations": len(generated),
                "failed_generations": len(failed),
                "success_rate": success_rate,
                "workout_types_requested": type_counts,
                "most_requested_type": max(type_counts.keys(), key=lambda k: type_counts[k]) if type_counts else None,
                "durations_requested": duration_counts,
                "most_requested_duration": max(duration_counts.keys(), key=lambda k: duration_counts[k]) if duration_counts else None,
            }

        except Exception as e:
            logger.error(f"Failed to get quick workout chat analytics: {e}")
            return {"error": str(e)}

    async def get_split_screen_usage_patterns(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Analyze user's split screen usage patterns.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Dictionary with split screen usage analytics
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            # Get split screen events
            response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", [
                    EventType.SPLIT_SCREEN_ENTERED.value,
                    EventType.SPLIT_SCREEN_EXITED.value,
                ]
            ).gte(
                "created_at", cutoff
            ).order(
                "created_at", desc=False
            ).execute()

            events = response.data or []

            if not events:
                return {
                    "user_id": user_id,
                    "period_days": days,
                    "has_split_screen_usage": False,
                    "total_sessions": 0,
                }

            # Analyze patterns
            enter_events = [
                e for e in events
                if e["event_type"] == EventType.SPLIT_SCREEN_ENTERED.value
            ]
            exit_events = [
                e for e in events
                if e["event_type"] == EventType.SPLIT_SCREEN_EXITED.value
            ]

            total_duration_seconds = sum(
                e["event_data"].get("duration_seconds", 0) for e in exit_events
            )

            # Count features used in split screen
            all_features_used = []
            for e in exit_events:
                all_features_used.extend(e["event_data"].get("features_used", []))

            # Count partner apps
            partner_apps: Dict[str, int] = {}
            for e in enter_events:
                partner = e["event_data"].get("partner_app")
                if partner:
                    partner_apps[partner] = partner_apps.get(partner, 0) + 1

            # Count device types
            device_types: Dict[str, int] = {}
            for e in enter_events:
                device_type = e["event_data"].get("device_type")
                if device_type:
                    device_types[device_type] = device_types.get(device_type, 0) + 1

            # Workout correlation
            workouts_during_split = sum(
                1 for e in exit_events
                if e["event_data"].get("workout_active_during_split", False)
            )

            return {
                "user_id": user_id,
                "period_days": days,
                "has_split_screen_usage": True,
                "total_sessions": len(enter_events),
                "total_duration_seconds": total_duration_seconds,
                "total_duration_minutes": round(total_duration_seconds / 60, 1),
                "avg_duration_seconds": round(
                    total_duration_seconds / len(exit_events), 1
                ) if exit_events else 0,
                "features_used_in_split": list(set(all_features_used)),
                "features_used_count": len(set(all_features_used)),
                "partner_apps": partner_apps,
                "most_common_partner": max(
                    partner_apps.keys(), key=lambda k: partner_apps[k]
                ) if partner_apps else None,
                "device_types": device_types,
                "primary_device_type": max(
                    device_types.keys(), key=lambda k: device_types[k]
                ) if device_types else None,
                "workouts_during_split_screen": workouts_during_split,
                "split_screen_workout_rate": round(
                    workouts_during_split / len(exit_events) * 100, 1
                ) if exit_events else 0,
            }

        except Exception as e:
            logger.error(f"Failed to get split screen usage patterns: {e}")
            return {
                "user_id": user_id,
                "period_days": days,
                "error": str(e),
            }

    # ==========================================================================
    # CONVERSION ATTRIBUTION - Track what leads to conversions
    # ==========================================================================

    async def get_conversion_attribution(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get conversion attribution data for a user.

        Analyzes the sequence of actions leading to conversion (or current state).

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Dictionary with attribution data
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            # Get all trial/demo related events
            trial_event_types = [
                EventType.PLAN_PREVIEW_VIEWED.value,
                EventType.PLAN_PREVIEW_SCROLL_DEPTH.value,
                EventType.TRY_WORKOUT_STARTED.value,
                EventType.TRY_WORKOUT_COMPLETED.value,
                EventType.TRY_WORKOUT_ABANDONED.value,
                EventType.DEMO_DAY_STARTED.value,
                EventType.DEMO_DAY_EXPIRED.value,
                EventType.TRIAL_STARTED.value,
                EventType.TRIAL_CONVERTED.value,
                EventType.PAYWALL_VIEWED.value,
                EventType.PAYWALL_SKIPPED.value,
                EventType.FREE_FEATURE_TAPPED.value,
                EventType.LOCKED_FEATURE_TAPPED.value,
            ]

            response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", trial_event_types
            ).gte(
                "created_at", cutoff
            ).order(
                "created_at", desc=False
            ).execute()

            events = response.data or []

            if not events:
                return {
                    "user_id": user_id,
                    "has_trial_events": False,
                    "conversion_status": "no_trial_activity",
                }

            # Build the event sequence
            event_sequence = []
            for event in events:
                event_sequence.append({
                    "event_type": event["event_type"],
                    "timestamp": event["created_at"],
                    "data": event["event_data"],
                })

            # Check if converted
            converted = any(e["event_type"] == EventType.TRIAL_CONVERTED.value for e in events)

            # Find last action before conversion (if converted)
            last_action_before_conversion = None
            if converted:
                conversion_index = next(
                    i for i, e in enumerate(events)
                    if e["event_type"] == EventType.TRIAL_CONVERTED.value
                )
                if conversion_index > 0:
                    last_action_before_conversion = events[conversion_index - 1]["event_type"]

            # Calculate time from first interaction to conversion/now
            first_interaction = datetime.fromisoformat(
                events[0]["created_at"].replace("Z", "+00:00")
            )
            if converted:
                conversion_event = next(
                    e for e in events
                    if e["event_type"] == EventType.TRIAL_CONVERTED.value
                )
                conversion_time = datetime.fromisoformat(
                    conversion_event["created_at"].replace("Z", "+00:00")
                )
                time_to_conversion = conversion_time - first_interaction
            else:
                time_to_conversion = datetime.now(first_interaction.tzinfo) - first_interaction

            # Count key events
            event_counts = {}
            for event in events:
                event_type = event["event_type"]
                event_counts[event_type] = event_counts.get(event_type, 0) + 1

            # Identify high-intent signals
            high_intent_signals = []
            if event_counts.get(EventType.TRY_WORKOUT_COMPLETED.value, 0) > 0:
                high_intent_signals.append("completed_trial_workout")
            if event_counts.get(EventType.LOCKED_FEATURE_TAPPED.value, 0) >= 3:
                high_intent_signals.append("multiple_locked_taps")
            if event_counts.get(EventType.PLAN_PREVIEW_SCROLL_DEPTH.value, 0) > 0:
                # Check if they had high engagement
                scroll_events = [
                    e for e in events
                    if e["event_type"] == EventType.PLAN_PREVIEW_SCROLL_DEPTH.value
                ]
                for scroll_event in scroll_events:
                    if scroll_event["event_data"].get("engagement_score", 0) > 70:
                        high_intent_signals.append("high_plan_engagement")
                        break

            return {
                "user_id": user_id,
                "has_trial_events": True,
                "conversion_status": "converted" if converted else "not_converted",
                "first_interaction_date": first_interaction.isoformat(),
                "time_to_conversion_hours": round(time_to_conversion.total_seconds() / 3600, 1),
                "last_action_before_conversion": last_action_before_conversion,
                "event_sequence": event_sequence,
                "event_counts": event_counts,
                "total_trial_events": len(events),
                "high_intent_signals": high_intent_signals,
                "paywall_views": event_counts.get(EventType.PAYWALL_VIEWED.value, 0),
                "paywall_skips": event_counts.get(EventType.PAYWALL_SKIPPED.value, 0),
                "locked_feature_taps": event_counts.get(EventType.LOCKED_FEATURE_TAPPED.value, 0),
            }

        except Exception as e:
            logger.error(f"Failed to get conversion attribution: {e}")
            return {
                "user_id": user_id,
                "error": str(e),
            }

    async def get_trial_funnel_metrics(
        self,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get aggregate trial funnel metrics for all users.

        This helps understand overall conversion patterns.

        Args:
            days: Number of days to analyze

        Returns:
            Dictionary with funnel metrics
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            # Get all trial events in the period
            trial_event_types = [
                EventType.PLAN_PREVIEW_VIEWED.value,
                EventType.TRY_WORKOUT_STARTED.value,
                EventType.TRY_WORKOUT_COMPLETED.value,
                EventType.TRIAL_STARTED.value,
                EventType.TRIAL_CONVERTED.value,
                EventType.PAYWALL_VIEWED.value,
            ]

            response = db.client.table("user_context_logs").select(
                "user_id, event_type"
            ).in_(
                "event_type", trial_event_types
            ).gte(
                "created_at", cutoff
            ).execute()

            events = response.data or []

            if not events:
                return {
                    "period_days": days,
                    "no_data": True,
                }

            # Group by user
            user_events: Dict[str, set] = {}
            for event in events:
                user_id = event["user_id"]
                if user_id not in user_events:
                    user_events[user_id] = set()
                user_events[user_id].add(event["event_type"])

            # Calculate funnel stages
            plan_preview_users = sum(
                1 for events in user_events.values()
                if EventType.PLAN_PREVIEW_VIEWED.value in events
            )
            try_workout_started = sum(
                1 for events in user_events.values()
                if EventType.TRY_WORKOUT_STARTED.value in events
            )
            try_workout_completed = sum(
                1 for events in user_events.values()
                if EventType.TRY_WORKOUT_COMPLETED.value in events
            )
            trial_started = sum(
                1 for events in user_events.values()
                if EventType.TRIAL_STARTED.value in events
            )
            converted = sum(
                1 for events in user_events.values()
                if EventType.TRIAL_CONVERTED.value in events
            )

            # Calculate conversion rates
            def safe_rate(numerator: int, denominator: int) -> float:
                return round((numerator / denominator * 100), 1) if denominator > 0 else 0

            return {
                "period_days": days,
                "total_users_with_trial_events": len(user_events),
                "funnel": {
                    "plan_preview_viewed": plan_preview_users,
                    "try_workout_started": try_workout_started,
                    "try_workout_completed": try_workout_completed,
                    "trial_started": trial_started,
                    "converted": converted,
                },
                "conversion_rates": {
                    "preview_to_try": safe_rate(try_workout_started, plan_preview_users),
                    "try_to_complete": safe_rate(try_workout_completed, try_workout_started),
                    "complete_to_trial": safe_rate(trial_started, try_workout_completed),
                    "trial_to_paid": safe_rate(converted, trial_started),
                    "overall_preview_to_paid": safe_rate(converted, plan_preview_users),
                },
            }

        except Exception as e:
            logger.error(f"Failed to get trial funnel metrics: {e}")
            return {
                "period_days": days,
                "error": str(e),
            }

    # ==========================================================================
    # LIFETIME MEMBERSHIP CONTEXT - For AI personalization
    # ==========================================================================

    async def get_lifetime_member_context(
        self,
        user_id: str,
    ) -> LifetimeMemberContext:
        """
        Get lifetime membership context for AI personalization.

        This method retrieves the user's lifetime membership status and
        generates context that can be included in AI prompts for personalization.

        The AI should treat lifetime members as valued long-term customers who
        have made a significant investment in their fitness journey.

        Args:
            user_id: User ID

        Returns:
            LifetimeMemberContext with membership details and AI context
        """
        try:
            db = get_supabase_db()

            # Query user subscription for lifetime status
            response = db.client.table("user_subscriptions").select(
                "is_lifetime, lifetime_purchase_date, lifetime_original_price, "
                "lifetime_member_tier, tier, status"
            ).eq(
                "user_id", user_id
            ).single().execute()

            if not response.data:
                logger.debug(f"[Lifetime Context] No subscription found for user {user_id}")
                return LifetimeMemberContext()

            subscription = response.data

            # Check if user is a lifetime member
            is_lifetime = subscription.get("is_lifetime", False) or subscription.get("tier") == "lifetime"

            if not is_lifetime:
                return LifetimeMemberContext()

            # Parse lifetime purchase date
            lifetime_purchase_date = None
            if subscription.get("lifetime_purchase_date"):
                try:
                    lifetime_purchase_date = datetime.fromisoformat(
                        subscription["lifetime_purchase_date"].replace("Z", "+00:00")
                    )
                except (ValueError, TypeError):
                    pass

            # Calculate days as member
            days_as_member = 0
            if lifetime_purchase_date:
                days_as_member = (datetime.now(lifetime_purchase_date.tzinfo) - lifetime_purchase_date).days

            # Get or calculate member tier
            member_tier = subscription.get("lifetime_member_tier")
            if not member_tier and days_as_member > 0:
                if days_as_member >= 365:
                    member_tier = "Veteran"
                elif days_as_member >= 180:
                    member_tier = "Loyal"
                elif days_as_member >= 90:
                    member_tier = "Established"
                else:
                    member_tier = "New"

            # Calculate tier level
            tier_level_map = {"New": 1, "Established": 2, "Loyal": 3, "Veteran": 4}
            member_tier_level = tier_level_map.get(member_tier, 0)

            # Calculate estimated value received (assuming $9.99/month value)
            months_as_member = days_as_member / 30.0
            estimated_value = months_as_member * 9.99

            # Calculate value multiplier
            original_price = subscription.get("lifetime_original_price", 0) or 0
            value_multiplier = 0.0
            if original_price > 0:
                value_multiplier = estimated_value / original_price

            # All features are unlocked for lifetime members
            features_unlocked = ["all"]

            context = LifetimeMemberContext(
                is_lifetime_member=True,
                lifetime_purchase_date=lifetime_purchase_date,
                days_as_member=days_as_member,
                member_tier=member_tier,
                member_tier_level=member_tier_level,
                estimated_value_received=estimated_value,
                value_multiplier=value_multiplier,
                features_unlocked=features_unlocked,
            )

            logger.info(
                f"[Lifetime Context] User {user_id}: tier={member_tier}, "
                f"days={days_as_member}, value=${estimated_value:.2f}"
            )

            return context

        except Exception as e:
            logger.error(f"Failed to get lifetime member context: {e}")
            return LifetimeMemberContext()

    async def get_full_user_context_for_ai(
        self,
        user_id: str,
        include_patterns: bool = True,
        include_lifetime: bool = True,
        include_cardio: bool = True,
        include_diabetes: bool = True,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get comprehensive user context for AI personalization.

        This aggregates all relevant user context including:
        - Activity patterns (mood, workout times, etc.)
        - Cardio patterns (location preferences, frequency)
        - Lifetime membership status and tier
        - Diabetes management context (glucose, insulin, A1C)
        - Recent engagement metrics

        Use this method when generating AI responses that need full user context.

        Args:
            user_id: User ID
            include_patterns: Whether to include user behavior patterns
            include_lifetime: Whether to include lifetime membership context
            include_cardio: Whether to include cardio patterns
            include_diabetes: Whether to include diabetes management context
            days: Number of days to analyze for patterns

        Returns:
            Dictionary with comprehensive user context and AI-ready strings
        """
        result = {
            "user_id": user_id,
            "context_generated_at": datetime.now().isoformat(),
        }

        ai_context_parts = []

        # Get lifetime membership context
        if include_lifetime:
            lifetime_context = await self.get_lifetime_member_context(user_id)
            result["lifetime_membership"] = lifetime_context.to_dict()

            lifetime_ai_context = lifetime_context.get_ai_personalization_context()
            if lifetime_ai_context:
                ai_context_parts.append(lifetime_ai_context)

        # Get user patterns
        if include_patterns:
            patterns = await self.get_user_patterns(user_id, days)
            result["patterns"] = patterns.to_dict()

            # Add relevant pattern context for AI
            if patterns.preferred_workout_time:
                ai_context_parts.append(
                    f"User typically works out in the {patterns.preferred_workout_time}."
                )
            if patterns.most_common_mood:
                ai_context_parts.append(
                    f"User's most common mood before workouts is '{patterns.most_common_mood}'."
                )
            if patterns.avg_workouts_per_week > 0:
                ai_context_parts.append(
                    f"User completes an average of {patterns.avg_workouts_per_week:.1f} workouts per week."
                )

            # Add cardio context
            if include_cardio and patterns.cardio_patterns:
                cardio_ai_context = patterns.cardio_patterns.get_ai_recommendations_context()
                if cardio_ai_context:
                    ai_context_parts.append(cardio_ai_context)

        # Get diabetes management context
        if include_diabetes:
            diabetes_patterns = await self.get_diabetes_patterns(user_id, days=7)
            if diabetes_patterns.diabetes_type:
                result["diabetes"] = diabetes_patterns.to_dict()
                result["diabetes_pre_workout_safety"] = diabetes_patterns.get_pre_workout_safety_context()

                diabetes_ai_context = diabetes_patterns.get_ai_context()
                if diabetes_ai_context:
                    ai_context_parts.append(diabetes_ai_context)

        # Combine all AI context into a single string
        result["ai_personalization_context"] = " ".join(ai_context_parts)

        return result

    # ==========================================================================
    # LIBRARY INTERACTION LOGGING - For AI preference learning
    # ==========================================================================

    async def log_exercise_viewed(
        self,
        user_id: str,
        exercise_id: str,
        exercise_name: str,
        source: str,  # "library_browse", "search_result", "carousel", "workout_detail"
        muscle_group: Optional[str] = None,
        difficulty: Optional[str] = None,
        equipment: Optional[List[str]] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user views an exercise detail in the library.

        This helps the AI learn:
        - Which exercises the user is interested in
        - Preferred muscle groups and difficulty levels
        - Equipment preferences based on viewing patterns

        Args:
            user_id: User ID
            exercise_id: Exercise ID
            exercise_name: Name of the exercise
            source: Where they viewed from (library_browse, search_result, carousel, etc.)
            muscle_group: Target muscle group
            difficulty: Exercise difficulty level
            equipment: Equipment required
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "exercise_id": exercise_id,
            "exercise_name": exercise_name,
            "source": source,
            "muscle_group": muscle_group,
            "difficulty": difficulty,
            "equipment": equipment,
            "viewed_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="exercise_detail",
            extra_context={"library_tracking_version": "1.0"},
        )

        logger.info(
            f"[Library Exercise Viewed] User {user_id}: {exercise_name} "
            f"(source={source}, muscle={muscle_group})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.LIBRARY_EXERCISE_VIEWED,
            event_data=event_data,
            context=context,
        )

    async def log_program_viewed(
        self,
        user_id: str,
        program_id: str,
        program_name: str,
        category: Optional[str] = None,
        difficulty: Optional[str] = None,
        duration_weeks: Optional[int] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user views a program detail in the library.

        This helps the AI learn:
        - Which programs the user is interested in
        - Preferred program categories (strength, hypertrophy, etc.)
        - Preferred program duration and difficulty

        Args:
            user_id: User ID
            program_id: Program ID
            program_name: Name of the program
            category: Program category (celebrity, goal-based, sport, etc.)
            difficulty: Program difficulty level
            duration_weeks: Program duration in weeks
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "program_id": program_id,
            "program_name": program_name,
            "category": category,
            "difficulty": difficulty,
            "duration_weeks": duration_weeks,
            "viewed_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="program_detail",
            extra_context={"library_tracking_version": "1.0"},
        )

        logger.info(
            f"[Library Program Viewed] User {user_id}: {program_name} "
            f"(category={category}, difficulty={difficulty})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.LIBRARY_PROGRAM_VIEWED,
            event_data=event_data,
            context=context,
        )

    async def log_library_search(
        self,
        user_id: str,
        search_query: str,
        filters_used: Optional[Dict[str, Any]] = None,
        result_count: int = 0,
        search_type: str = "exercises",  # "exercises" or "programs"
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user searches in the library.

        This helps the AI learn:
        - What exercises/programs users are looking for
        - Common search patterns and terminology
        - Preferred filters and result expectations

        Args:
            user_id: User ID
            search_query: The search query text
            filters_used: Dictionary of filters applied (muscle_group, equipment, etc.)
            result_count: Number of results returned
            search_type: Type of search (exercises or programs)
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "search_query": search_query,
            "search_type": search_type,
            "filters_used": filters_used or {},
            "result_count": result_count,
            "has_results": result_count > 0,
            "searched_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="library_search",
            extra_context={"library_tracking_version": "1.0"},
        )

        logger.info(
            f"[Library Search] User {user_id}: '{search_query}' "
            f"(type={search_type}, results={result_count}, filters={bool(filters_used)})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.LIBRARY_SEARCH_PERFORMED,
            event_data=event_data,
            context=context,
        )

    async def log_exercise_filter_used(
        self,
        user_id: str,
        filter_type: str,  # "muscle_group", "equipment", "difficulty", "body_part", etc.
        filter_values: List[str],
        result_count: int = 0,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user applies a filter in the library.

        This helps the AI learn:
        - Preferred muscle groups and body parts
        - Equipment preferences
        - Difficulty level preferences

        Args:
            user_id: User ID
            filter_type: Type of filter (muscle_group, equipment, difficulty, etc.)
            filter_values: List of selected filter values
            result_count: Number of results after filtering
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "filter_type": filter_type,
            "filter_values": filter_values,
            "filter_values_count": len(filter_values),
            "result_count": result_count,
            "filtered_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="library_filter",
            extra_context={"library_tracking_version": "1.0"},
        )

        logger.info(
            f"[Library Filter] User {user_id}: {filter_type}={filter_values} "
            f"(results={result_count})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.LIBRARY_FILTER_USED,
            event_data=event_data,
            context=context,
        )

    # ==========================================================================
    # EXERCISE HISTORY AND MUSCLE ANALYTICS LOGGING - For AI personalization
    # ==========================================================================

    async def log_exercise_history_view(
        self,
        user_id: str,
        exercise_name: str,
        time_range: str,  # "week", "month", "3months", "6months", "year", "all"
        total_sessions: int = 0,
        total_sets: int = 0,
        max_weight: Optional[float] = None,
        progression_trend: Optional[str] = None,  # "improving", "stable", "declining"
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user views exercise history details.

        This helps the AI learn:
        - Which exercises the user is tracking progress on
        - Preferred time ranges for analysis
        - User's interest in specific exercise performance

        Args:
            user_id: User ID
            exercise_name: Name of the exercise viewed
            time_range: Time period for the history view
            total_sessions: Number of sessions in the time range
            total_sets: Total sets performed
            max_weight: Maximum weight lifted (if applicable)
            progression_trend: Direction of progress
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "exercise_name": exercise_name,
            "time_range": time_range,
            "total_sessions": total_sessions,
            "total_sets": total_sets,
            "max_weight": max_weight,
            "progression_trend": progression_trend,
            "viewed_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="exercise_history",
            extra_context={"analytics_tracking_version": "1.0"},
        )

        logger.info(
            f"[Exercise History Viewed] User {user_id}: {exercise_name} "
            f"(range={time_range}, sessions={total_sessions}, trend={progression_trend})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.EXERCISE_HISTORY_VIEWED,
            event_data=event_data,
            context=context,
        )

    async def log_muscle_analytics_view(
        self,
        user_id: str,
        view_type: str,  # "heatmap", "distribution", "balance", "weekly_volume", "recovery"
        muscle_group: Optional[str] = None,  # Specific muscle group if focused view
        time_range: str = "week",  # "week", "month", "3months"
        top_muscles_trained: Optional[List[str]] = None,
        neglected_muscles: Optional[List[str]] = None,
        balance_score: Optional[float] = None,  # 0-100 score
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user views muscle analytics.

        This helps the AI learn:
        - User interest in muscle group balance
        - Which muscles they're focusing on or neglecting
        - Training distribution preferences

        Args:
            user_id: User ID
            view_type: Type of analytics view (heatmap, distribution, etc.)
            muscle_group: Specific muscle group if focused view
            time_range: Time period for the analysis
            top_muscles_trained: Most frequently trained muscles
            neglected_muscles: Muscles that may need more attention
            balance_score: Overall muscle balance score (0-100)
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "view_type": view_type,
            "muscle_group": muscle_group,
            "time_range": time_range,
            "top_muscles_trained": top_muscles_trained or [],
            "neglected_muscles": neglected_muscles or [],
            "balance_score": balance_score,
            "viewed_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="muscle_analytics",
            extra_context={"analytics_tracking_version": "1.0"},
        )

        logger.info(
            f"[Muscle Analytics Viewed] User {user_id}: {view_type} "
            f"(muscle={muscle_group}, range={time_range}, balance={balance_score})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.MUSCLE_ANALYTICS_VIEWED,
            event_data=event_data,
            context=context,
        )

    async def log_muscle_heatmap_interaction(
        self,
        user_id: str,
        muscle_clicked: str,  # "chest", "back", "biceps", "triceps", etc.
        interaction_type: str = "tap",  # "tap", "long_press", "drill_down"
        muscle_volume_percentage: Optional[float] = None,  # How much this muscle was trained
        last_trained_date: Optional[str] = None,  # When this muscle was last worked
        sets_this_week: Optional[int] = None,
        exercises_for_muscle: Optional[List[str]] = None,  # Exercises shown for this muscle
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user interacts with the muscle heatmap.

        This helps the AI learn:
        - Which muscle groups the user is most curious about
        - Areas of potential concern (frequently clicked but undertrained)
        - Personalization opportunities for workout suggestions

        Args:
            user_id: User ID
            muscle_clicked: Name of the muscle clicked
            interaction_type: Type of interaction (tap, long_press, etc.)
            muscle_volume_percentage: Training volume percentage for this muscle
            last_trained_date: When this muscle was last worked
            sets_this_week: Number of sets for this muscle this week
            exercises_for_muscle: List of exercises targeting this muscle
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "muscle_clicked": muscle_clicked,
            "interaction_type": interaction_type,
            "muscle_volume_percentage": muscle_volume_percentage,
            "last_trained_date": last_trained_date,
            "sets_this_week": sets_this_week,
            "exercises_for_muscle": exercises_for_muscle or [],
            "interacted_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="muscle_heatmap",
            extra_context={"analytics_tracking_version": "1.0"},
        )

        logger.info(
            f"[Muscle Heatmap Interaction] User {user_id}: clicked {muscle_clicked} "
            f"(type={interaction_type}, volume={muscle_volume_percentage}%, sets={sets_this_week})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.MUSCLE_HEATMAP_INTERACTION,
            event_data=event_data,
            context=context,
        )

    async def get_library_preferences(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Analyze user's library interaction patterns for AI personalization.

        Returns insights about:
        - Most viewed muscle groups
        - Preferred difficulty levels
        - Equipment preferences
        - Common search terms

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Dictionary with library preference analytics
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            # Get library events
            library_event_types = [
                EventType.LIBRARY_EXERCISE_VIEWED.value,
                EventType.LIBRARY_PROGRAM_VIEWED.value,
                EventType.LIBRARY_SEARCH_PERFORMED.value,
                EventType.LIBRARY_FILTER_USED.value,
            ]

            response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", library_event_types
            ).gte(
                "created_at", cutoff
            ).order(
                "created_at", desc=True
            ).execute()

            events = response.data or []

            if not events:
                return {
                    "user_id": user_id,
                    "period_days": days,
                    "has_library_activity": False,
                    "total_events": 0,
                }

            # Analyze exercise views
            exercise_views = [
                e for e in events
                if e["event_type"] == EventType.LIBRARY_EXERCISE_VIEWED.value
            ]

            # Count muscle groups
            muscle_group_counts: Dict[str, int] = {}
            difficulty_counts: Dict[str, int] = {}
            equipment_counts: Dict[str, int] = {}

            for view in exercise_views:
                data = view.get("event_data", {})

                muscle = data.get("muscle_group")
                if muscle:
                    muscle_group_counts[muscle] = muscle_group_counts.get(muscle, 0) + 1

                difficulty = data.get("difficulty")
                if difficulty:
                    difficulty_counts[difficulty] = difficulty_counts.get(difficulty, 0) + 1

                equipment_list = data.get("equipment") or []
                for eq in equipment_list:
                    equipment_counts[eq] = equipment_counts.get(eq, 0) + 1

            # Analyze searches
            searches = [
                e for e in events
                if e["event_type"] == EventType.LIBRARY_SEARCH_PERFORMED.value
            ]

            search_terms = [s["event_data"].get("search_query", "").lower() for s in searches]

            # Analyze filters
            filters = [
                e for e in events
                if e["event_type"] == EventType.LIBRARY_FILTER_USED.value
            ]

            filter_type_counts: Dict[str, int] = {}
            for f in filters:
                filter_type = f["event_data"].get("filter_type")
                if filter_type:
                    filter_type_counts[filter_type] = filter_type_counts.get(filter_type, 0) + 1

            # Get program categories
            program_views = [
                e for e in events
                if e["event_type"] == EventType.LIBRARY_PROGRAM_VIEWED.value
            ]

            category_counts: Dict[str, int] = {}
            for pv in program_views:
                category = pv["event_data"].get("category")
                if category:
                    category_counts[category] = category_counts.get(category, 0) + 1

            return {
                "user_id": user_id,
                "period_days": days,
                "has_library_activity": True,
                "total_events": len(events),
                "exercise_views": {
                    "total": len(exercise_views),
                    "muscle_group_frequency": muscle_group_counts,
                    "preferred_muscle_group": max(
                        muscle_group_counts.keys(),
                        key=lambda k: muscle_group_counts[k]
                    ) if muscle_group_counts else None,
                    "difficulty_frequency": difficulty_counts,
                    "preferred_difficulty": max(
                        difficulty_counts.keys(),
                        key=lambda k: difficulty_counts[k]
                    ) if difficulty_counts else None,
                    "equipment_frequency": equipment_counts,
                    "preferred_equipment": sorted(
                        equipment_counts.keys(),
                        key=lambda k: equipment_counts[k],
                        reverse=True
                    )[:3] if equipment_counts else [],
                },
                "searches": {
                    "total": len(searches),
                    "recent_terms": search_terms[:10],
                },
                "filters": {
                    "total": len(filters),
                    "filter_type_frequency": filter_type_counts,
                },
                "program_views": {
                    "total": len(program_views),
                    "category_frequency": category_counts,
                    "preferred_category": max(
                        category_counts.keys(),
                        key=lambda k: category_counts[k]
                    ) if category_counts else None,
                },
            }

        except Exception as e:
            logger.error(f"Failed to get library preferences: {e}")
            return {
                "user_id": user_id,
                "period_days": days,
                "error": str(e),
            }

    def get_library_ai_context(
        self,
        preferences: Dict[str, Any],
    ) -> str:
        """
        Generate AI context string from library preferences.

        Args:
            preferences: Library preferences from get_library_preferences()

        Returns:
            AI-ready context string
        """
        if not preferences.get("has_library_activity"):
            return ""

        context_parts = []

        exercise_views = preferences.get("exercise_views", {})

        if exercise_views.get("preferred_muscle_group"):
            context_parts.append(
                f"User frequently browses {exercise_views['preferred_muscle_group']} exercises in the library."
            )

        if exercise_views.get("preferred_difficulty"):
            context_parts.append(
                f"User tends to view {exercise_views['preferred_difficulty']} difficulty exercises."
            )

        if exercise_views.get("preferred_equipment"):
            equipment_list = ", ".join(exercise_views['preferred_equipment'][:3])
            context_parts.append(
                f"User shows interest in exercises using: {equipment_list}."
            )

        program_views = preferences.get("program_views", {})
        if program_views.get("preferred_category"):
            context_parts.append(
                f"User is interested in {program_views['preferred_category']} programs."
            )

        searches = preferences.get("searches", {})
        if searches.get("recent_terms"):
            # Only include non-empty, meaningful terms
            terms = [t for t in searches["recent_terms"][:5] if len(t) >= 3]
            if terms:
                context_parts.append(
                    f"User has searched for: {', '.join(terms)}."
                )

        return " ".join(context_parts)

    # ==========================================================================
    # NEAT GAMIFICATION EVENT LOGGING
    # ==========================================================================

    async def log_neat_event(
        self,
        user_id: str,
        event_type: EventType,
        event_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Generic method to log NEAT-related events with consistent structure.

        Args:
            user_id: User ID
            event_type: Type of NEAT event
            event_data: Event-specific data
            device: Device type (iOS, Android, etc.)
            app_version: App version string

        Returns:
            Event ID if successful
        """
        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="neat",
            extra_context={
                "neat_tracking_version": "1.0",
                "is_neat_event": True,
            },
        )

        logger.info(
            f"[NEAT Event] User {user_id}: {event_type.value} - data={event_data}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=event_data,
            context=context,
        )

    async def log_step_goal_set(
        self,
        user_id: str,
        new_goal: int,
        previous_goal: Optional[int] = None,
        is_progressive: bool = False,
        source: str = "manual",  # "manual", "onboarding", "progressive_increase"
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user sets or changes their step goal.

        Args:
            user_id: User ID
            new_goal: New step goal value
            previous_goal: Previous step goal (if any)
            is_progressive: Whether progressive goal mode is enabled
            source: How the goal was set
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "new_goal": new_goal,
            "previous_goal": previous_goal,
            "is_progressive": is_progressive,
            "source": source,
            "goal_change": new_goal - previous_goal if previous_goal else None,
            "set_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Step Goal Set] User {user_id}: {previous_goal or 'none'} -> {new_goal} "
            f"(progressive={is_progressive}, source={source})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_STEP_GOAL_SET,
            event_data=event_data,
            device=device,
        )

    async def log_step_goal_achieved(
        self,
        user_id: str,
        goal: int,
        actual_steps: int,
        active_hours: int,
        streak_days: int,
        xp_earned: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user achieves their daily step goal.

        Args:
            user_id: User ID
            goal: The step goal that was achieved
            actual_steps: Actual steps taken
            active_hours: Active hours for the day
            streak_days: Current streak after achieving goal
            xp_earned: XP earned for achieving goal
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "goal": goal,
            "actual_steps": actual_steps,
            "steps_over_goal": actual_steps - goal,
            "completion_percentage": round((actual_steps / goal) * 100, 1) if goal > 0 else 0,
            "active_hours": active_hours,
            "streak_days": streak_days,
            "xp_earned": xp_earned,
            "achieved_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Goal Achieved] User {user_id}: {actual_steps}/{goal} steps, "
            f"streak={streak_days} days, +{xp_earned} XP"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_STEP_GOAL_ACHIEVED,
            event_data=event_data,
            device=device,
        )

    async def log_sedentary_alert_received(
        self,
        user_id: str,
        sedentary_minutes: int,
        time_of_day: str,
        day_of_week: str,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user receives a sedentary/movement reminder.

        Args:
            user_id: User ID
            sedentary_minutes: Minutes of sedentary time before alert
            time_of_day: Time of day (morning, afternoon, evening)
            day_of_week: Day of week
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "sedentary_minutes": sedentary_minutes,
            "time_of_day": time_of_day,
            "day_of_week": day_of_week,
            "received_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Sedentary Alert] User {user_id}: {sedentary_minutes} min sedentary "
            f"({time_of_day}, {day_of_week})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_SEDENTARY_ALERT_RECEIVED,
            event_data=event_data,
            device=device,
        )

    async def log_sedentary_alert_acted_on(
        self,
        user_id: str,
        response_time_seconds: int,
        steps_after_alert: int,
        active_minutes: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user responds to a sedentary alert by moving.

        Args:
            user_id: User ID
            response_time_seconds: Time between alert and movement
            steps_after_alert: Steps taken in the 15 min after alert
            active_minutes: Active minutes in the 15 min after alert
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "response_time_seconds": response_time_seconds,
            "response_time_minutes": round(response_time_seconds / 60, 1),
            "steps_after_alert": steps_after_alert,
            "active_minutes": active_minutes,
            "acted_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Alert Acted On] User {user_id}: responded in "
            f"{response_time_seconds}s, {steps_after_alert} steps"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_SEDENTARY_ALERT_ACTED_ON,
            event_data=event_data,
            device=device,
        )

    async def log_neat_score_calculated(
        self,
        user_id: str,
        score: int,
        steps: int,
        active_hours: int,
        sedentary_breaks: int,
        bonus_activities: Optional[List[str]] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log daily NEAT score calculation.

        Args:
            user_id: User ID
            score: Calculated NEAT score (0-100)
            steps: Total steps for the day
            active_hours: Active hours for the day
            sedentary_breaks: Number of sedentary breaks taken
            bonus_activities: List of bonus activities (stairs, parking far, etc.)
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "score": score,
            "steps": steps,
            "active_hours": active_hours,
            "sedentary_breaks": sedentary_breaks,
            "bonus_activities": bonus_activities or [],
            "calculated_at": datetime.now().isoformat(),
            "date": datetime.now().date().isoformat(),
        }

        logger.info(
            f"[NEAT Score] User {user_id}: score={score}, steps={steps}, "
            f"active_hrs={active_hours}"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_SCORE_CALCULATED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_achievement_earned(
        self,
        user_id: str,
        achievement_id: str,
        achievement_name: str,
        achievement_type: str,  # "badge", "milestone", "streak", "challenge"
        xp_earned: int,
        description: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user earns a NEAT achievement.

        Args:
            user_id: User ID
            achievement_id: Unique achievement ID
            achievement_name: Display name of achievement
            achievement_type: Type of achievement
            xp_earned: XP earned from achievement
            description: Achievement description
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "achievement_id": achievement_id,
            "achievement_name": achievement_name,
            "achievement_type": achievement_type,
            "xp_earned": xp_earned,
            "description": description,
            "earned_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Achievement] User {user_id}: {achievement_name} "
            f"(type={achievement_type}, +{xp_earned} XP)"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_ACHIEVEMENT_EARNED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_streak_milestone(
        self,
        user_id: str,
        streak_days: int,
        milestone_name: str,
        xp_earned: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user hits a streak milestone.

        Args:
            user_id: User ID
            streak_days: Number of days in streak
            milestone_name: Name of milestone (e.g., "1 Week Warrior")
            xp_earned: XP earned for milestone
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "streak_days": streak_days,
            "milestone_name": milestone_name,
            "xp_earned": xp_earned,
            "achieved_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Streak Milestone] User {user_id}: {streak_days} days - {milestone_name}"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_STREAK_MILESTONE,
            event_data=event_data,
            device=device,
        )

    async def log_progressive_goal_increased(
        self,
        user_id: str,
        old_goal: int,
        new_goal: int,
        increase_amount: int,
        reason: str,  # "streak_achievement", "consistent_overachievement", "scheduled"
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when system automatically increases user's step goal.

        Args:
            user_id: User ID
            old_goal: Previous goal
            new_goal: New increased goal
            increase_amount: Amount of increase
            reason: Why the goal was increased
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "old_goal": old_goal,
            "new_goal": new_goal,
            "increase_amount": increase_amount,
            "increase_percentage": round((increase_amount / old_goal) * 100, 1) if old_goal > 0 else 0,
            "reason": reason,
            "increased_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Goal Increased] User {user_id}: {old_goal} -> {new_goal} "
            f"(+{increase_amount}, reason={reason})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_PROGRESSIVE_GOAL_INCREASED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_challenge_accepted(
        self,
        user_id: str,
        challenge_id: str,
        challenge_name: str,
        target_value: int,
        unit: str,
        xp_reward: int,
        expires_at: datetime,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user accepts a daily NEAT challenge.

        Args:
            user_id: User ID
            challenge_id: Unique challenge ID
            challenge_name: Name of the challenge
            target_value: Target value to complete challenge
            unit: Unit of measurement (steps, minutes, etc.)
            xp_reward: XP reward for completion
            expires_at: When the challenge expires
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "challenge_id": challenge_id,
            "challenge_name": challenge_name,
            "target_value": target_value,
            "unit": unit,
            "xp_reward": xp_reward,
            "expires_at": expires_at.isoformat(),
            "accepted_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Challenge Accepted] User {user_id}: {challenge_name} "
            f"(target={target_value} {unit})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_CHALLENGE_ACCEPTED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_challenge_completed(
        self,
        user_id: str,
        challenge_id: str,
        challenge_name: str,
        target_value: int,
        actual_value: int,
        unit: str,
        xp_earned: int,
        time_to_complete_minutes: Optional[int] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user completes a NEAT challenge.

        Args:
            user_id: User ID
            challenge_id: Unique challenge ID
            challenge_name: Name of the challenge
            target_value: Target value
            actual_value: Actual value achieved
            unit: Unit of measurement
            xp_earned: XP earned
            time_to_complete_minutes: Time taken to complete
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "challenge_id": challenge_id,
            "challenge_name": challenge_name,
            "target_value": target_value,
            "actual_value": actual_value,
            "unit": unit,
            "completion_percentage": round((actual_value / target_value) * 100, 1) if target_value > 0 else 0,
            "xp_earned": xp_earned,
            "time_to_complete_minutes": time_to_complete_minutes,
            "completed_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Challenge Completed] User {user_id}: {challenge_name} "
            f"({actual_value}/{target_value} {unit}, +{xp_earned} XP)"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_CHALLENGE_COMPLETED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_level_up(
        self,
        user_id: str,
        old_level: str,
        new_level: str,
        old_xp: int,
        new_xp: int,
        total_xp: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user levels up in the NEAT gamification system.

        Args:
            user_id: User ID
            old_level: Previous level name
            new_level: New level name
            old_xp: XP before level up
            new_xp: XP remaining after level up
            total_xp: Total lifetime XP
            device: Device type

        Returns:
            Event ID if successful
        """
        event_data = {
            "old_level": old_level,
            "new_level": new_level,
            "old_xp": old_xp,
            "new_xp": new_xp,
            "total_xp": total_xp,
            "leveled_up_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Level Up] User {user_id}: {old_level} -> {new_level} "
            f"(total XP: {total_xp})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_LEVEL_UP,
            event_data=event_data,
            device=device,
        )

    async def get_neat_patterns(
        self,
        user_id: str,
        days: int = 30,
    ) -> NeatPatterns:
        """
        Analyze user's NEAT activity patterns from context logs.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            NeatPatterns with analyzed data
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()
            week_cutoff = (datetime.now() - timedelta(days=7)).isoformat()
            last_week_start = (datetime.now() - timedelta(days=14)).isoformat()

            # Get all NEAT events for the period
            neat_event_types = [
                EventType.NEAT_STEP_GOAL_SET.value,
                EventType.NEAT_STEP_GOAL_ACHIEVED.value,
                EventType.NEAT_SEDENTARY_ALERT_RECEIVED.value,
                EventType.NEAT_SEDENTARY_ALERT_ACTED_ON.value,
                EventType.NEAT_SCORE_CALCULATED.value,
                EventType.NEAT_ACHIEVEMENT_EARNED.value,
                EventType.NEAT_STREAK_MILESTONE.value,
                EventType.NEAT_PROGRESSIVE_GOAL_INCREASED.value,
                EventType.NEAT_LEVEL_UP.value,
            ]

            response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", neat_event_types
            ).gte(
                "created_at", cutoff
            ).order(
                "created_at", desc=True
            ).execute()

            events = response.data or []

            patterns = NeatPatterns()

            if not events:
                return patterns

            # Get most recent step goal
            goal_events = [e for e in events if e["event_type"] == EventType.NEAT_STEP_GOAL_SET.value]
            if goal_events:
                latest_goal = goal_events[0]["event_data"]
                patterns.current_step_goal = latest_goal.get("new_goal", 7500)
                patterns.is_progressive_goal = latest_goal.get("is_progressive", False)
                # Find initial goal
                if len(goal_events) > 1:
                    patterns.initial_step_goal = goal_events[-1]["event_data"].get("new_goal", 3000)

            # Analyze score events
            score_events = [e for e in events if e["event_type"] == EventType.NEAT_SCORE_CALCULATED.value]

            # This week's scores
            this_week_scores = [
                e["event_data"].get("score", 0)
                for e in score_events
                if e["created_at"] >= week_cutoff
            ]

            # Last week's scores
            last_week_scores = [
                e["event_data"].get("score", 0)
                for e in score_events
                if last_week_start <= e["created_at"] < week_cutoff
            ]

            if this_week_scores:
                patterns.week_avg_neat_score = sum(this_week_scores) / len(this_week_scores)
                # Today's score is the most recent
                patterns.today_neat_score = this_week_scores[0] if this_week_scores else 0

            if last_week_scores:
                patterns.last_week_avg_neat_score = sum(last_week_scores) / len(last_week_scores)

            # Determine trend
            if patterns.week_avg_neat_score > patterns.last_week_avg_neat_score + 5:
                patterns.neat_score_trend = "improving"
            elif patterns.week_avg_neat_score < patterns.last_week_avg_neat_score - 5:
                patterns.neat_score_trend = "declining"
            else:
                patterns.neat_score_trend = "stable"

            # Get weekly step totals
            patterns.weekly_step_totals = [
                e["event_data"].get("steps", 0)
                for e in score_events
                if e["created_at"] >= week_cutoff
            ][:7]  # Last 7 days

            patterns.weekly_active_hours = [
                e["event_data"].get("active_hours", 0)
                for e in score_events
                if e["created_at"] >= week_cutoff
            ][:7]

            # Get today's data
            today = datetime.now().date().isoformat()
            today_scores = [
                e for e in score_events
                if e["event_data"].get("date") == today
            ]
            if today_scores:
                today_data = today_scores[0]["event_data"]
                patterns.today_steps = today_data.get("steps", 0)
                patterns.today_active_hours = today_data.get("active_hours", 0)
                if patterns.current_step_goal > 0:
                    patterns.today_step_percentage = (
                        patterns.today_steps / patterns.current_step_goal
                    ) * 100

            # Analyze streaks from goal achieved events
            goal_achieved_events = [
                e for e in events
                if e["event_type"] == EventType.NEAT_STEP_GOAL_ACHIEVED.value
            ]
            if goal_achieved_events:
                latest_streak = goal_achieved_events[0]["event_data"].get("streak_days", 0)
                patterns.current_streak_days = latest_streak
                patterns.longest_streak_days = max(
                    e["event_data"].get("streak_days", 0)
                    for e in goal_achieved_events
                )

            # Analyze sedentary patterns
            sedentary_alerts = [
                e for e in events
                if e["event_type"] == EventType.NEAT_SEDENTARY_ALERT_RECEIVED.value
            ]
            sedentary_acted = [
                e for e in events
                if e["event_type"] == EventType.NEAT_SEDENTARY_ALERT_ACTED_ON.value
            ]

            # Count today's alerts
            today_alerts = [
                a for a in sedentary_alerts
                if a["created_at"][:10] == today
            ]
            patterns.sedentary_alert_count_today = len(today_alerts)
            patterns.sedentary_alerts_acted_on = len([
                a for a in sedentary_acted
                if a["created_at"][:10] == today
            ])

            # Find most sedentary period
            if sedentary_alerts:
                time_counts: Dict[str, int] = {}
                for alert in sedentary_alerts:
                    time_of_day = alert["event_data"].get("time_of_day", "")
                    day_of_week = alert["event_data"].get("day_of_week", "")
                    key = f"{time_of_day} {day_of_week}s"
                    time_counts[key] = time_counts.get(key, 0) + 1

                if time_counts:
                    patterns.most_sedentary_period = max(
                        time_counts.keys(),
                        key=lambda k: time_counts[k]
                    )

            # Get level and XP from most recent level up event
            level_up_events = [e for e in events if e["event_type"] == EventType.NEAT_LEVEL_UP.value]
            if level_up_events:
                latest_level = level_up_events[0]["event_data"]
                patterns.current_level = latest_level.get("new_level", "Couch Potato")
                patterns.current_xp = latest_level.get("total_xp", 0)

            # Get badges earned
            achievement_events = [
                e for e in events
                if e["event_type"] == EventType.NEAT_ACHIEVEMENT_EARNED.value
            ]
            patterns.badges_earned = [
                e["event_data"].get("achievement_name", "")
                for e in achievement_events
            ]

            return patterns

        except Exception as e:
            logger.error(f"Failed to get NEAT patterns: {e}")
            return NeatPatterns()

    async def get_neat_context_for_ai(
        self,
        user_id: str,
        days: int = 30,
    ) -> str:
        """
        Get formatted NEAT context string for AI prompts.

        This method retrieves the user's NEAT activity patterns and
        generates a context string that can be included in AI prompts
        for personalized workout recommendations and coaching.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Formatted context string for AI prompts
        """
        patterns = await self.get_neat_patterns(user_id, days)
        return patterns.get_ai_context()

    async def get_neat_analytics(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get comprehensive NEAT analytics for a user.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Dictionary with NEAT analytics and AI context
        """
        patterns = await self.get_neat_patterns(user_id, days)

        return {
            "user_id": user_id,
            "period_days": days,
            "patterns": patterns.to_dict(),
            "ai_context": patterns.get_ai_context(),
            "generated_at": datetime.now().isoformat(),
        }

    # ==========================================================================
    # INJURY TRACKING EVENT LOGGING - For AI personalization and safety
    # ==========================================================================

    async def log_injury_event(
        self,
        user_id: str,
        event_type: EventType,
        injury_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Generic method to log injury-related events.

        Args:
            user_id: User ID
            event_type: Type of injury event
            injury_data: Injury-specific data (body_part, severity, etc.)
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={
                "injury_tracking_version": "1.0",
            },
        )

        logger.info(
            f"[Injury Event] User {user_id}: {event_type.value} - "
            f"data={injury_data}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=injury_data,
            context=context,
        )

    async def log_injury_reported(
        self,
        user_id: str,
        body_part: str,
        injury_type: str,
        severity: str,  # "mild", "moderate", "severe"
        description: Optional[str] = None,
        exercises_to_avoid: Optional[List[str]] = None,
        expected_recovery_days: Optional[int] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user reports a new injury.

        This event triggers workout modifications and AI personalization.

        Args:
            user_id: User ID
            body_part: Affected body part (e.g., "shoulder", "lower_back", "knee")
            injury_type: Type of injury (e.g., "strain", "sprain", "soreness")
            severity: Severity level ("mild", "moderate", "severe")
            description: User's description of the injury
            exercises_to_avoid: List of exercises to avoid
            expected_recovery_days: Estimated recovery time in days
            device: Device type

        Returns:
            Event ID if successful
        """
        injury_data = {
            "body_part": body_part,
            "injury_type": injury_type,
            "severity": severity,
            "description": description,
            "exercises_to_avoid": exercises_to_avoid or [],
            "expected_recovery_days": expected_recovery_days,
            "reported_at": datetime.now().isoformat(),
        }

        return await self.log_injury_event(
            user_id=user_id,
            event_type=EventType.INJURY_REPORTED,
            injury_data=injury_data,
            device=device,
        )

    async def log_injury_healed(
        self,
        user_id: str,
        body_part: str,
        injury_type: str,
        recovery_days: int,
        exercises_resumed: Optional[List[str]] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user marks an injury as healed.

        This removes workout restrictions for the affected body part.

        Args:
            user_id: User ID
            body_part: Previously affected body part
            injury_type: Type of injury that healed
            recovery_days: Actual days taken to recover
            exercises_resumed: Exercises that can now be performed
            device: Device type

        Returns:
            Event ID if successful
        """
        injury_data = {
            "body_part": body_part,
            "injury_type": injury_type,
            "recovery_days": recovery_days,
            "exercises_resumed": exercises_resumed or [],
            "healed_at": datetime.now().isoformat(),
        }

        return await self.log_injury_event(
            user_id=user_id,
            event_type=EventType.INJURY_HEALED,
            injury_data=injury_data,
            device=device,
        )

    async def log_injury_check_in(
        self,
        user_id: str,
        body_part: str,
        pain_level: int,  # 0-10 scale
        mobility_level: str,  # "limited", "moderate", "good"
        improvement_since_last: str,  # "worse", "same", "better"
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user checks in on their injury status.

        Regular check-ins help track recovery progress.

        Args:
            user_id: User ID
            body_part: Affected body part
            pain_level: Pain level on 0-10 scale
            mobility_level: Current mobility level
            improvement_since_last: Change since last check-in
            notes: Additional notes from user
            device: Device type

        Returns:
            Event ID if successful
        """
        injury_data = {
            "body_part": body_part,
            "pain_level": pain_level,
            "mobility_level": mobility_level,
            "improvement_since_last": improvement_since_last,
            "notes": notes,
            "checked_in_at": datetime.now().isoformat(),
        }

        return await self.log_injury_event(
            user_id=user_id,
            event_type=EventType.INJURY_CHECK_IN,
            injury_data=injury_data,
            device=device,
        )

    # ==========================================================================
    # STRAIN PREVENTION EVENT LOGGING - For overtraining detection
    # ==========================================================================

    async def log_strain_event(
        self,
        user_id: str,
        event_type: EventType,
        strain_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Generic method to log strain-related events.

        Args:
            user_id: User ID
            event_type: Type of strain event
            strain_data: Strain-specific data (risk_level, muscle_groups, etc.)
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={
                "strain_prevention_version": "1.0",
            },
        )

        logger.info(
            f"[Strain Event] User {user_id}: {event_type.value} - "
            f"data={strain_data}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=strain_data,
            context=context,
        )

    async def log_strain_recorded(
        self,
        user_id: str,
        muscle_groups: List[str],
        volume_today: float,
        volume_weekly: float,
        intensity_level: str,  # "low", "moderate", "high", "extreme"
        fatigue_score: Optional[float] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log strain data after a workout session.

        Used for tracking cumulative training load.

        Args:
            user_id: User ID
            muscle_groups: Muscle groups trained
            volume_today: Training volume for the day
            volume_weekly: Cumulative weekly volume
            intensity_level: Workout intensity level
            fatigue_score: Calculated fatigue score (0-100)
            device: Device type

        Returns:
            Event ID if successful
        """
        strain_data = {
            "muscle_groups": muscle_groups,
            "volume_today": volume_today,
            "volume_weekly": volume_weekly,
            "intensity_level": intensity_level,
            "fatigue_score": fatigue_score,
            "recorded_at": datetime.now().isoformat(),
        }

        return await self.log_strain_event(
            user_id=user_id,
            event_type=EventType.STRAIN_RECORDED,
            strain_data=strain_data,
            device=device,
        )

    async def log_strain_alert_created(
        self,
        user_id: str,
        alert_type: str,  # "high_volume", "consecutive_days", "muscle_overload"
        risk_level: str,  # "warning", "high", "critical"
        affected_muscles: List[str],
        recommendation: str,
        volume_threshold_exceeded: Optional[float] = None,
        days_without_rest: Optional[int] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a strain alert is created for the user.

        Args:
            user_id: User ID
            alert_type: Type of strain alert
            risk_level: Risk severity level
            affected_muscles: Muscles at risk
            recommendation: Suggested action
            volume_threshold_exceeded: Volume threshold that was exceeded (if applicable)
            days_without_rest: Consecutive training days (if applicable)
            device: Device type

        Returns:
            Event ID if successful
        """
        strain_data = {
            "alert_type": alert_type,
            "risk_level": risk_level,
            "affected_muscles": affected_muscles,
            "recommendation": recommendation,
            "volume_threshold_exceeded": volume_threshold_exceeded,
            "days_without_rest": days_without_rest,
            "alert_created_at": datetime.now().isoformat(),
        }

        logger.warning(
            f"[Strain Alert Created] User {user_id}: {alert_type} - "
            f"risk={risk_level}, muscles={affected_muscles}"
        )

        return await self.log_strain_event(
            user_id=user_id,
            event_type=EventType.STRAIN_ALERT_CREATED,
            strain_data=strain_data,
            device=device,
        )

    async def log_strain_alert_acknowledged(
        self,
        user_id: str,
        alert_type: str,
        risk_level: str,
        action_taken: str,  # "rest_day", "reduced_intensity", "ignored", "modified_workout"
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user acknowledges a strain alert.

        Args:
            user_id: User ID
            alert_type: Type of alert acknowledged
            risk_level: Original risk level
            action_taken: What the user decided to do
            notes: Additional notes
            device: Device type

        Returns:
            Event ID if successful
        """
        strain_data = {
            "alert_type": alert_type,
            "risk_level": risk_level,
            "action_taken": action_taken,
            "notes": notes,
            "acknowledged_at": datetime.now().isoformat(),
        }

        return await self.log_strain_event(
            user_id=user_id,
            event_type=EventType.STRAIN_ALERT_ACKNOWLEDGED,
            strain_data=strain_data,
            device=device,
        )

    # ==========================================================================
    # SENIOR FITNESS EVENT LOGGING - For age-appropriate training
    # ==========================================================================

    async def log_senior_event(
        self,
        user_id: str,
        event_type: EventType,
        settings_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Generic method to log senior fitness events.

        Args:
            user_id: User ID
            event_type: Type of senior fitness event
            settings_data: Settings/recovery data
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={
                "senior_fitness_version": "1.0",
            },
        )

        logger.info(
            f"[Senior Event] User {user_id}: {event_type.value} - "
            f"data={settings_data}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=settings_data,
            context=context,
        )

    async def log_senior_settings_updated(
        self,
        user_id: str,
        age: int,
        recovery_multiplier: float,
        preferred_rest_days: int,
        joint_friendly_mode: bool,
        balance_exercises_enabled: bool,
        mobility_focus: bool,
        previous_settings: Optional[Dict[str, Any]] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when senior fitness settings are updated.

        Args:
            user_id: User ID
            age: User's age
            recovery_multiplier: Recovery time multiplier (e.g., 1.5 = 50% more rest)
            preferred_rest_days: Preferred number of rest days per week
            joint_friendly_mode: Whether to prefer low-impact exercises
            balance_exercises_enabled: Include balance work
            mobility_focus: Prioritize mobility exercises
            previous_settings: Previous settings for comparison
            device: Device type

        Returns:
            Event ID if successful
        """
        settings_data = {
            "age": age,
            "recovery_multiplier": recovery_multiplier,
            "preferred_rest_days": preferred_rest_days,
            "joint_friendly_mode": joint_friendly_mode,
            "balance_exercises_enabled": balance_exercises_enabled,
            "mobility_focus": mobility_focus,
            "previous_settings": previous_settings,
            "updated_at": datetime.now().isoformat(),
        }

        return await self.log_senior_event(
            user_id=user_id,
            event_type=EventType.SENIOR_SETTINGS_UPDATED,
            settings_data=settings_data,
            device=device,
        )

    async def log_senior_recovery_check(
        self,
        user_id: str,
        days_since_last_workout: int,
        recovery_status: str,  # "under_recovered", "recovered", "fully_recovered"
        energy_level: int,  # 1-5 scale
        soreness_level: int,  # 0-10 scale
        recommended_intensity: str,  # "light", "moderate", "normal"
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log a senior user's recovery check before workout.

        Args:
            user_id: User ID
            days_since_last_workout: Days since last training session
            recovery_status: Calculated recovery status
            energy_level: Self-reported energy (1-5)
            soreness_level: Self-reported soreness (0-10)
            recommended_intensity: AI-recommended workout intensity
            device: Device type

        Returns:
            Event ID if successful
        """
        settings_data = {
            "days_since_last_workout": days_since_last_workout,
            "recovery_status": recovery_status,
            "energy_level": energy_level,
            "soreness_level": soreness_level,
            "recommended_intensity": recommended_intensity,
            "checked_at": datetime.now().isoformat(),
        }

        return await self.log_senior_event(
            user_id=user_id,
            event_type=EventType.SENIOR_RECOVERY_CHECK,
            settings_data=settings_data,
            device=device,
        )

    # ==========================================================================
    # PROGRESSION PACE EVENT LOGGING - For tracking progression preferences
    # ==========================================================================

    async def log_progression_event(
        self,
        user_id: str,
        event_type: EventType,
        preferences_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Generic method to log progression-related events.

        Args:
            user_id: User ID
            event_type: Type of progression event
            preferences_data: Progression preferences data
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={
                "progression_tracking_version": "1.0",
            },
        )

        logger.info(
            f"[Progression Event] User {user_id}: {event_type.value} - "
            f"data={preferences_data}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=preferences_data,
            context=context,
        )

    async def log_progression_pace_changed(
        self,
        user_id: str,
        old_pace: str,
        new_pace: str,  # "conservative", "moderate", "aggressive"
        reason: Optional[str] = None,
        triggered_by: str = "user",  # "user", "ai_recommendation", "injury"
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user changes their progression pace preference.

        Args:
            user_id: User ID
            old_pace: Previous progression pace
            new_pace: New progression pace
            reason: Reason for change
            triggered_by: What triggered the change
            device: Device type

        Returns:
            Event ID if successful
        """
        preferences_data = {
            "old_pace": old_pace,
            "new_pace": new_pace,
            "reason": reason,
            "triggered_by": triggered_by,
            "changed_at": datetime.now().isoformat(),
        }

        return await self.log_progression_event(
            user_id=user_id,
            event_type=EventType.PROGRESSION_PACE_CHANGED,
            preferences_data=preferences_data,
            device=device,
        )

    async def log_workout_modified_for_safety(
        self,
        user_id: str,
        workout_id: str,
        modification_reason: str,  # "injury", "strain_risk", "recovery", "senior_adjustment"
        exercises_removed: Optional[List[str]] = None,
        exercises_substituted: Optional[Dict[str, str]] = None,  # {original: replacement}
        intensity_reduced: bool = False,
        volume_reduced: bool = False,
        reduction_percentage: Optional[float] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a workout is modified for safety reasons.

        This tracks automatic and manual workout modifications due to
        injuries, strain risk, recovery needs, or senior adjustments.

        Args:
            user_id: User ID
            workout_id: ID of the modified workout
            modification_reason: Why the workout was modified
            exercises_removed: List of exercises removed
            exercises_substituted: Dict mapping original to replacement exercises
            intensity_reduced: Whether intensity was lowered
            volume_reduced: Whether volume was reduced
            reduction_percentage: Percentage reduction applied
            device: Device type

        Returns:
            Event ID if successful
        """
        modification_data = {
            "workout_id": workout_id,
            "modification_reason": modification_reason,
            "exercises_removed": exercises_removed or [],
            "exercises_substituted": exercises_substituted or {},
            "intensity_reduced": intensity_reduced,
            "volume_reduced": volume_reduced,
            "reduction_percentage": reduction_percentage,
            "modified_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            extra_context={
                "safety_modification_version": "1.0",
            },
        )

        logger.info(
            f"[Workout Modified for Safety] User {user_id}: workout={workout_id}, "
            f"reason={modification_reason}, removed={len(exercises_removed or [])}, "
            f"substituted={len(exercises_substituted or {})}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.WORKOUT_MODIFIED_FOR_SAFETY,
            event_data=modification_data,
            context=context,
        )



    # ==========================================================================
    # DIABETES TRACKING EVENT LOGGING - For AI personalization and health safety
    # ==========================================================================

    async def log_diabetes_event(
        self,
        user_id: str,
        event_type: EventType,
        diabetes_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Generic method to log diabetes-related events.

        Args:
            user_id: User ID
            event_type: Type of diabetes event
            diabetes_data: Diabetes-specific data
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={
                "diabetes_tracking_version": "1.0",
            },
        )

        logger.info(
            f"[Diabetes Event] User {user_id}: {event_type.value} - "
            f"data={diabetes_data}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=diabetes_data,
            context=context,
        )

    async def log_diabetes_profile_created(
        self,
        user_id: str,
        diabetes_type: str,  # "type1", "type2", "prediabetes", "gestational"
        diagnosis_date: Optional[str] = None,
        target_glucose_min: float = 70.0,
        target_glucose_max: float = 180.0,
        a1c_goal: Optional[float] = None,
        uses_insulin: bool = False,
        uses_cgm: bool = False,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user creates or updates their diabetes profile.

        This establishes the user's diabetes management context for AI personalization.

        Args:
            user_id: User ID
            diabetes_type: Type of diabetes
            diagnosis_date: When diagnosed (ISO format)
            target_glucose_min: Target glucose range minimum (mg/dL)
            target_glucose_max: Target glucose range maximum (mg/dL)
            a1c_goal: Target A1C percentage
            uses_insulin: Whether user takes insulin
            uses_cgm: Whether user uses continuous glucose monitor
            device: Device type

        Returns:
            Event ID if successful
        """
        diabetes_data = {
            "diabetes_type": diabetes_type,
            "diagnosis_date": diagnosis_date,
            "target_glucose_min": target_glucose_min,
            "target_glucose_max": target_glucose_max,
            "a1c_goal": a1c_goal,
            "uses_insulin": uses_insulin,
            "uses_cgm": uses_cgm,
            "created_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Diabetes Profile Created] User {user_id}: type={diabetes_type}, "
            f"target_range={target_glucose_min}-{target_glucose_max}, a1c_goal={a1c_goal}"
        )

        return await self.log_diabetes_event(
            user_id=user_id,
            event_type=EventType.DIABETES_PROFILE_CREATED,
            diabetes_data=diabetes_data,
            device=device,
        )

    async def log_glucose_reading_logged(
        self,
        user_id: str,
        value: float,  # mg/dL
        status: str,  # "low", "normal", "high", "very_high"
        meal_context: Optional[str] = None,  # "fasting", "pre_meal", "post_meal", "bedtime"
        source: str = "manual",  # "manual", "cgm", "health_connect"
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user records a blood glucose reading.

        This tracks glucose patterns for AI-aware workout recommendations.

        Args:
            user_id: User ID
            value: Glucose reading in mg/dL
            status: Interpreted status (low/normal/high/very_high)
            meal_context: Context of the reading
            source: Where the reading came from
            notes: User notes about the reading
            device: Device type

        Returns:
            Event ID if successful
        """
        diabetes_data = {
            "value": value,
            "status": status,
            "meal_context": meal_context,
            "source": source,
            "notes": notes,
            "logged_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Glucose Reading Logged] User {user_id}: {value} mg/dL "
            f"(status={status}, context={meal_context}, source={source})"
        )

        return await self.log_diabetes_event(
            user_id=user_id,
            event_type=EventType.GLUCOSE_READING_LOGGED,
            diabetes_data=diabetes_data,
            device=device,
        )

    async def log_insulin_dose_logged(
        self,
        user_id: str,
        units: float,
        insulin_type: str,  # "rapid", "short", "intermediate", "long", "mixed"
        dose_context: Optional[str] = None,  # "meal", "correction", "basal", "exercise"
        glucose_at_dose: Optional[float] = None,
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user records an insulin dose.

        This helps the AI understand the user's insulin regimen.

        Args:
            user_id: User ID
            units: Insulin units administered
            insulin_type: Type of insulin
            dose_context: Reason for the dose
            glucose_at_dose: Glucose reading when dose was taken
            notes: User notes
            device: Device type

        Returns:
            Event ID if successful
        """
        diabetes_data = {
            "units": units,
            "insulin_type": insulin_type,
            "dose_context": dose_context,
            "glucose_at_dose": glucose_at_dose,
            "notes": notes,
            "logged_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Insulin Dose Logged] User {user_id}: {units}U {insulin_type} "
            f"(context={dose_context}, glucose={glucose_at_dose})"
        )

        return await self.log_diabetes_event(
            user_id=user_id,
            event_type=EventType.INSULIN_DOSE_LOGGED,
            diabetes_data=diabetes_data,
            device=device,
        )

    async def log_a1c_logged(
        self,
        user_id: str,
        value: float,  # A1C percentage
        test_date: Optional[str] = None,  # ISO format
        goal: Optional[float] = None,
        previous_a1c: Optional[float] = None,
        is_lab_result: bool = True,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user records an A1C result.

        A1C is a key diabetes management metric that the AI can reference.

        Args:
            user_id: User ID
            value: A1C percentage (e.g., 6.5 for 6.5%)
            test_date: Date of the A1C test
            goal: User's A1C goal
            previous_a1c: Previous A1C for comparison
            is_lab_result: Whether this is from a lab (vs home kit)
            device: Device type

        Returns:
            Event ID if successful
        """
        # Calculate change from previous
        change = None
        if previous_a1c is not None:
            change = round(value - previous_a1c, 1)

        # Determine if goal is met
        goal_met = goal is not None and value <= goal

        diabetes_data = {
            "value": value,
            "test_date": test_date,
            "goal": goal,
            "previous_a1c": previous_a1c,
            "change_from_previous": change,
            "goal_met": goal_met,
            "is_lab_result": is_lab_result,
            "logged_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[A1C Logged] User {user_id}: {value}% "
            f"(goal={goal}, previous={previous_a1c}, change={change})"
        )

        return await self.log_diabetes_event(
            user_id=user_id,
            event_type=EventType.A1C_LOGGED,
            diabetes_data=diabetes_data,
            device=device,
        )

    async def log_glucose_alert_triggered(
        self,
        user_id: str,
        alert_type: str,  # "low", "very_low", "high", "very_high", "rapid_drop", "rapid_rise"
        value: float,  # Current glucose value
        threshold: float,  # Threshold that triggered alert
        source: str = "app",  # "app", "cgm", "health_connect"
        action_suggested: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a glucose alert is triggered.

        These alerts are critical for workout safety and AI awareness.

        Args:
            user_id: User ID
            alert_type: Type of glucose alert
            value: Glucose value that triggered alert
            threshold: The threshold that was crossed
            source: Where the alert originated
            action_suggested: Recommended action
            device: Device type

        Returns:
            Event ID if successful
        """
        diabetes_data = {
            "alert_type": alert_type,
            "value": value,
            "threshold": threshold,
            "source": source,
            "action_suggested": action_suggested,
            "triggered_at": datetime.now().isoformat(),
        }

        logger.warning(
            f"[Glucose Alert] User {user_id}: {alert_type.upper()} - "
            f"{value} mg/dL (threshold={threshold}, source={source})"
        )

        return await self.log_diabetes_event(
            user_id=user_id,
            event_type=EventType.GLUCOSE_ALERT_TRIGGERED,
            diabetes_data=diabetes_data,
            device=device,
        )

    async def log_health_connect_diabetes_sync(
        self,
        user_id: str,
        glucose_count: int,
        insulin_count: int,
        sync_range_hours: int = 24,
        sync_status: str = "success",  # "success", "partial", "failed"
        error_message: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log Health Connect sync for diabetes data.

        Tracks automatic data imports from Health Connect.

        Args:
            user_id: User ID
            glucose_count: Number of glucose readings synced
            insulin_count: Number of insulin doses synced
            sync_range_hours: Time range of synced data
            sync_status: Status of the sync operation
            error_message: Error details if sync failed
            device: Device type

        Returns:
            Event ID if successful
        """
        diabetes_data = {
            "glucose_count": glucose_count,
            "insulin_count": insulin_count,
            "sync_range_hours": sync_range_hours,
            "sync_status": sync_status,
            "error_message": error_message,
            "synced_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Health Connect Diabetes Sync] User {user_id}: "
            f"{glucose_count} glucose readings, {insulin_count} insulin doses "
            f"(status={sync_status}, range={sync_range_hours}h)"
        )

        return await self.log_diabetes_event(
            user_id=user_id,
            event_type=EventType.HEALTH_CONNECT_DIABETES_SYNC,
            diabetes_data=diabetes_data,
            device=device,
        )

    async def log_diabetes_goal_set(
        self,
        user_id: str,
        goal_type: str,  # "a1c", "fasting_glucose", "time_in_range", "weight"
        target_value: float,
        current_value: Optional[float] = None,
        target_date: Optional[str] = None,  # ISO format
        previous_goal: Optional[float] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user sets a diabetes-related goal.

        These goals help personalize AI coaching messages.

        Args:
            user_id: User ID
            goal_type: Type of goal being set
            target_value: Target value to achieve
            current_value: Current value for comparison
            target_date: When user wants to achieve goal
            previous_goal: Previous goal value if updating
            device: Device type

        Returns:
            Event ID if successful
        """
        diabetes_data = {
            "goal_type": goal_type,
            "target_value": target_value,
            "current_value": current_value,
            "target_date": target_date,
            "previous_goal": previous_goal,
            "gap_to_goal": (target_value - current_value) if current_value else None,
            "set_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Diabetes Goal Set] User {user_id}: {goal_type}={target_value} "
            f"(current={current_value}, target_date={target_date})"
        )

        return await self.log_diabetes_event(
            user_id=user_id,
            event_type=EventType.DIABETES_GOAL_SET,
            diabetes_data=diabetes_data,
            device=device,
        )

    async def log_pre_workout_glucose_check(
        self,
        user_id: str,
        value: float,  # mg/dL
        risk_level: str,  # "safe", "caution", "delay_recommended", "unsafe"
        workout_id: Optional[str] = None,
        action_taken: Optional[str] = None,  # "proceeded", "delayed", "ate_snack", "cancelled"
        recommendation: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log a pre-workout glucose check.

        This is a critical safety checkpoint for users with diabetes.

        Args:
            user_id: User ID
            value: Glucose reading before workout
            risk_level: Calculated risk level for exercise
            workout_id: ID of the planned workout
            action_taken: What the user decided to do
            recommendation: System recommendation given
            device: Device type

        Returns:
            Event ID if successful
        """
        diabetes_data = {
            "value": value,
            "risk_level": risk_level,
            "workout_id": workout_id,
            "action_taken": action_taken,
            "recommendation": recommendation,
            "checked_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Pre-Workout Glucose Check] User {user_id}: {value} mg/dL "
            f"(risk={risk_level}, action={action_taken})"
        )

        return await self.log_diabetes_event(
            user_id=user_id,
            event_type=EventType.PRE_WORKOUT_GLUCOSE_CHECK,
            diabetes_data=diabetes_data,
            device=device,
        )

    async def get_diabetes_patterns(
        self,
        user_id: str,
        days: int = 7,
    ) -> DiabetesPatterns:
        """
        Analyze user's diabetes patterns from context logs.

        This provides comprehensive diabetes context for AI personalization.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            DiabetesPatterns with analyzed data
        """
        try:
            db = get_supabase_db()
            now = datetime.now()
            cutoff = (now - timedelta(days=days)).isoformat()
            today_start = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
            last_24h = (now - timedelta(hours=24)).isoformat()
            last_7_days = (now - timedelta(days=7)).isoformat()

            # Get all diabetes events for the period
            diabetes_event_types = [
                EventType.DIABETES_PROFILE_CREATED.value,
                EventType.GLUCOSE_READING_LOGGED.value,
                EventType.INSULIN_DOSE_LOGGED.value,
                EventType.A1C_LOGGED.value,
                EventType.GLUCOSE_ALERT_TRIGGERED.value,
                EventType.DIABETES_GOAL_SET.value,
                EventType.PRE_WORKOUT_GLUCOSE_CHECK.value,
            ]

            response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", diabetes_event_types
            ).gte(
                "created_at", cutoff
            ).order(
                "created_at", desc=True
            ).execute()

            events = response.data or []

            patterns = DiabetesPatterns()

            if not events:
                return patterns

            # Get diabetes profile
            profile_events = [
                e for e in events
                if e["event_type"] == EventType.DIABETES_PROFILE_CREATED.value
            ]
            if profile_events:
                latest_profile = profile_events[0]["event_data"]
                patterns.diabetes_type = latest_profile.get("diabetes_type")
                if latest_profile.get("diagnosis_date"):
                    try:
                        patterns.diagnosis_date = date.fromisoformat(
                            latest_profile["diagnosis_date"]
                        )
                    except (ValueError, TypeError):
                        pass
                patterns.target_glucose_min = latest_profile.get("target_glucose_min", 70.0)
                patterns.target_glucose_max = latest_profile.get("target_glucose_max", 180.0)

            # Analyze glucose readings from last 24 hours
            glucose_events = [
                e for e in events
                if e["event_type"] == EventType.GLUCOSE_READING_LOGGED.value
                and e["created_at"] >= last_24h
            ]

            if glucose_events:
                patterns.recent_readings_count = len(glucose_events)
                values = [e["event_data"].get("value", 0) for e in glucose_events]
                patterns.avg_glucose_24h = sum(values) / len(values)
                patterns.min_glucose_24h = min(values)
                patterns.max_glucose_24h = max(values)

                # Latest reading
                latest = glucose_events[0]["event_data"]
                patterns.latest_glucose = latest.get("value")
                patterns.latest_glucose_status = latest.get("status")
                try:
                    patterns.latest_glucose_time = datetime.fromisoformat(
                        glucose_events[0]["created_at"].replace("Z", "+00:00")
                    )
                except (ValueError, TypeError):
                    pass

            # Analyze insulin doses from today
            insulin_events = [
                e for e in events
                if e["event_type"] == EventType.INSULIN_DOSE_LOGGED.value
                and e["created_at"] >= today_start
            ]

            if insulin_events:
                patterns.today_insulin_doses = len(insulin_events)
                patterns.today_total_units = sum(
                    e["event_data"].get("units", 0) for e in insulin_events
                )
                patterns.insulin_types_used = list(set(
                    e["event_data"].get("insulin_type", "")
                    for e in insulin_events
                    if e["event_data"].get("insulin_type")
                ))

            # Get latest A1C
            a1c_events = [
                e for e in events
                if e["event_type"] == EventType.A1C_LOGGED.value
            ]
            if a1c_events:
                latest_a1c = a1c_events[0]["event_data"]
                patterns.current_a1c = latest_a1c.get("value")
                patterns.a1c_goal = latest_a1c.get("goal")
                patterns.a1c_on_target = latest_a1c.get("goal_met", False)
                if latest_a1c.get("test_date"):
                    try:
                        patterns.a1c_date = date.fromisoformat(latest_a1c["test_date"])
                    except (ValueError, TypeError):
                        pass

            # Count hypo/hyper events in last 7 days
            alert_events = [
                e for e in events
                if e["event_type"] == EventType.GLUCOSE_ALERT_TRIGGERED.value
                and e["created_at"] >= last_7_days
            ]

            for alert in alert_events:
                alert_type = alert["event_data"].get("alert_type", "")
                if "low" in alert_type:
                    patterns.hypo_events_7_days += 1
                elif "high" in alert_type:
                    patterns.hyper_events_7_days += 1

            # Get active alerts (from today)
            today_alerts = [
                e for e in alert_events
                if e["created_at"] >= today_start
            ]
            patterns.active_alerts = list(set(
                e["event_data"].get("alert_type", "")
                for e in today_alerts
                if e["event_data"].get("alert_type")
            ))

            return patterns

        except Exception as e:
            logger.error(f"Failed to get diabetes patterns: {e}")
            return DiabetesPatterns()

    async def get_diabetes_context_for_ai(
        self,
        user_id: str,
        days: int = 7,
    ) -> str:
        """
        Get formatted diabetes context string for AI prompts.

        This method retrieves the user's diabetes patterns and generates
        a context string for AI-aware workout coaching.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Formatted context string for AI prompts
        """
        patterns = await self.get_diabetes_patterns(user_id, days)
        return patterns.get_ai_context()

    async def get_diabetes_analytics(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get comprehensive diabetes analytics for a user.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Dictionary with diabetes analytics and AI context
        """
        patterns = await self.get_diabetes_patterns(user_id, days)

        return {
            "user_id": user_id,
            "period_days": days,
            "patterns": patterns.to_dict(),
            "ai_context": patterns.get_ai_context(),
            "pre_workout_safety": patterns.get_pre_workout_safety_context(),
            "generated_at": datetime.now().isoformat(),
        }

    # ==========================================================================
    # NUTRITION PREFERENCES EVENT LOGGING - For tracking nutrition feature usage
    # ==========================================================================

    async def log_nutrition_preferences_updated(
        self,
        user_id: str,
        disable_ai_tips: Optional[bool] = None,
        quick_log_mode: Optional[bool] = None,
        compact_tracker_view: Optional[bool] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user updates their nutrition preferences.

        Args:
            user_id: User ID
            disable_ai_tips: Whether AI tips are disabled
            quick_log_mode: Whether quick log mode is enabled
            compact_tracker_view: Whether compact tracker view is enabled
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "disable_ai_tips": disable_ai_tips,
            "quick_log_mode": quick_log_mode,
            "compact_tracker_view": compact_tracker_view,
            "updated_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="nutrition_preferences",
            extra_context={"nutrition_tracking_version": "1.0"},
        )

        logger.info(
            f"[Nutrition Preferences Updated] User {user_id}: "
            f"ai_tips_disabled={disable_ai_tips}, quick_log={quick_log_mode}, "
            f"compact_view={compact_tracker_view}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.NUTRITION_PREFERENCES_UPDATED,
            event_data=event_data,
            context=context,
        )

    async def log_nutrition_preferences_reset(
        self,
        user_id: str,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user resets their nutrition preferences to defaults.

        Args:
            user_id: User ID
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "reset_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="nutrition_preferences",
            extra_context={"nutrition_tracking_version": "1.0"},
        )

        logger.info(f"[Nutrition Preferences Reset] User {user_id}: preferences reset to defaults")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.NUTRITION_PREFERENCES_RESET,
            event_data=event_data,
            context=context,
        )

    async def log_quick_log_used(
        self,
        user_id: str,
        food_name: str,
        meal_type: str,
        calories: int,
        servings: float = 1.0,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user uses the quick log feature.

        Args:
            user_id: User ID
            food_name: Name of the food logged
            meal_type: Type of meal (breakfast, lunch, dinner, snack)
            calories: Calories in the food
            servings: Number of servings logged
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "food_name": food_name,
            "meal_type": meal_type,
            "calories": calories,
            "servings": servings,
            "logged_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="nutrition_quick_log",
            extra_context={"nutrition_tracking_version": "1.0"},
        )

        logger.info(
            f"[Quick Log Used] User {user_id}: {food_name} ({calories} cal) "
            f"for {meal_type}, servings={servings}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.QUICK_LOG_USED,
            event_data=event_data,
            context=context,
        )

    async def log_meal_template_created(
        self,
        user_id: str,
        template_name: str,
        total_calories: int,
        food_count: int,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user creates a meal template.

        Args:
            user_id: User ID
            template_name: Name of the template
            total_calories: Total calories in the template
            food_count: Number of food items in the template
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "template_name": template_name,
            "total_calories": total_calories,
            "food_count": food_count,
            "created_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="nutrition_templates",
            extra_context={"nutrition_tracking_version": "1.0"},
        )

        logger.info(
            f"[Meal Template Created] User {user_id}: '{template_name}' "
            f"({total_calories} cal, {food_count} items)"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.MEAL_TEMPLATE_CREATED,
            event_data=event_data,
            context=context,
        )

    async def log_meal_template_logged(
        self,
        user_id: str,
        template_id: str,
        template_name: str,
        meal_type: str,
        total_calories: int,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user logs a meal using a template.

        Args:
            user_id: User ID
            template_id: ID of the template used
            template_name: Name of the template
            meal_type: Type of meal (breakfast, lunch, dinner, snack)
            total_calories: Total calories logged from the template
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "template_id": template_id,
            "template_name": template_name,
            "meal_type": meal_type,
            "total_calories": total_calories,
            "logged_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="nutrition_templates",
            extra_context={"nutrition_tracking_version": "1.0"},
        )

        logger.info(
            f"[Meal Template Logged] User {user_id}: '{template_name}' "
            f"({total_calories} cal) as {meal_type}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.MEAL_TEMPLATE_LOGGED,
            event_data=event_data,
            context=context,
        )

    async def log_meal_template_deleted(
        self,
        user_id: str,
        template_id: str,
        template_name: str,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user deletes a meal template.

        Args:
            user_id: User ID
            template_id: ID of the template deleted
            template_name: Name of the template deleted
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "template_id": template_id,
            "template_name": template_name,
            "deleted_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="nutrition_templates",
            extra_context={"nutrition_tracking_version": "1.0"},
        )

        logger.info(f"[Meal Template Deleted] User {user_id}: '{template_name}'")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.MEAL_TEMPLATE_DELETED,
            event_data=event_data,
            context=context,
        )

    async def log_food_search_performed(
        self,
        user_id: str,
        query: str,
        result_count: int,
        cache_hit: bool = False,
        source: str = "api",  # "api", "cache", "local"
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user searches for foods.

        Args:
            user_id: User ID
            query: Search query string
            result_count: Number of results returned
            cache_hit: Whether the results came from cache
            source: Source of the search results
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "query": query,
            "result_count": result_count,
            "cache_hit": cache_hit,
            "source": source,
            "has_results": result_count > 0,
            "searched_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="nutrition_search",
            extra_context={"nutrition_tracking_version": "1.0"},
        )

        logger.info(
            f"[Food Search Performed] User {user_id}: '{query}' "
            f"(results={result_count}, cache_hit={cache_hit})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.FOOD_SEARCH_PERFORMED,
            event_data=event_data,
            context=context,
        )

    async def log_ai_tips_toggled(
        self,
        user_id: str,
        disabled: bool,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user toggles AI food tips on/off.

        Args:
            user_id: User ID
            disabled: True if AI tips were disabled, False if enabled
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_type = EventType.AI_TIPS_DISABLED if disabled else EventType.AI_TIPS_ENABLED

        event_data = {
            "disabled": disabled,
            "toggled_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="nutrition_preferences",
            extra_context={"nutrition_tracking_version": "1.0"},
        )

        logger.info(
            f"[AI Tips {'Disabled' if disabled else 'Enabled'}] User {user_id}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=event_data,
            context=context,
        )

    async def log_compact_view_toggled(
        self,
        user_id: str,
        enabled: bool,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user toggles compact tracker view on/off.

        Args:
            user_id: User ID
            enabled: True if compact view was enabled, False if disabled
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_type = EventType.COMPACT_VIEW_ENABLED if enabled else EventType.COMPACT_VIEW_DISABLED

        event_data = {
            "enabled": enabled,
            "toggled_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="nutrition_preferences",
            extra_context={"nutrition_tracking_version": "1.0"},
        )

        logger.info(
            f"[Compact View {'Enabled' if enabled else 'Disabled'}] User {user_id}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=event_data,
            context=context,
        )

    # =========================================================================
    # HORMONAL HEALTH CONTEXT METHODS
    # =========================================================================

    async def get_hormonal_health_context(
        self,
        user_id: str,
        days: int = 7,
    ) -> HormonalHealthContext:
        """
        Get hormonal health context for AI personalization.

        This method retrieves the user's hormonal profile, cycle phase,
        and kegel preferences to provide context for workout recommendations.

        Args:
            user_id: User ID
            days: Number of days to analyze for symptoms

        Returns:
            HormonalHealthContext with user's hormonal data
        """
        try:
            db = get_supabase_db()
            context = HormonalHealthContext()

            # Get user's gender from user profile
            user_response = db.client.table("users").select(
                "gender"
            ).eq("id", user_id).single().execute()

            if user_response.data:
                context.gender = user_response.data.get("gender")

            # Get hormonal profile
            profile_response = db.client.table("hormonal_profiles").select(
                "*"
            ).eq("user_id", user_id).single().execute()

            if profile_response.data:
                profile = profile_response.data
                context.hormone_goals = profile.get("hormone_goals", [])
                context.primary_goal = profile.get("primary_goal")
                context.menstrual_tracking_enabled = profile.get("menstrual_tracking_enabled", False)
                context.avg_cycle_length = profile.get("avg_cycle_length", 28)
                context.hormonal_diet_enabled = profile.get("hormonal_diet_enabled", False)
                context.dietary_restrictions = profile.get("dietary_restrictions", [])

                if profile.get("last_period_date"):
                    try:
                        context.last_period_date = date.fromisoformat(profile["last_period_date"])
                        # Calculate current cycle phase
                        today = date.today()
                        days_since_period = (today - context.last_period_date).days
                        cycle_day = (days_since_period % context.avg_cycle_length) + 1
                        context.cycle_day = cycle_day

                        # Determine phase
                        if cycle_day <= 5:
                            context.current_cycle_phase = "menstrual"
                        elif cycle_day <= 13:
                            context.current_cycle_phase = "follicular"
                        elif cycle_day <= 16:
                            context.current_cycle_phase = "ovulation"
                        else:
                            context.current_cycle_phase = "luteal"
                    except (ValueError, TypeError):
                        pass

            # Get recent hormone logs for symptoms
            now = datetime.now()
            cutoff = (now - timedelta(days=days)).isoformat()

            logs_response = db.client.table("hormone_logs").select(
                "symptoms, symptom_severity, energy_level"
            ).eq("user_id", user_id).gte(
                "log_date", cutoff
            ).order("log_date", desc=True).limit(7).execute()

            if logs_response.data:
                # Collect all symptoms from recent logs
                all_symptoms = []
                for log in logs_response.data:
                    symptoms = log.get("symptoms", [])
                    if symptoms:
                        all_symptoms.extend(symptoms)

                # Get most common symptoms
                from collections import Counter
                symptom_counts = Counter(all_symptoms)
                context.recent_symptoms = [s for s, _ in symptom_counts.most_common(5)]

                # Get latest severity and energy
                latest_log = logs_response.data[0]
                context.symptom_severity = latest_log.get("symptom_severity")
                context.energy_level_today = latest_log.get("energy_level")

            # Get kegel preferences
            kegel_response = db.client.table("kegel_preferences").select(
                "*"
            ).eq("user_id", user_id).single().execute()

            if kegel_response.data:
                prefs = kegel_response.data
                context.kegels_enabled = prefs.get("kegels_enabled", False)
                context.include_kegels_in_warmup = prefs.get("include_in_warmup", False)
                context.include_kegels_in_cooldown = prefs.get("include_in_cooldown", False)
                context.kegel_current_level = prefs.get("current_level", "beginner")
                context.kegel_focus_area = prefs.get("focus_area", "general")
                context.kegel_target_sessions = prefs.get("target_sessions_per_day", 3)

            # Get kegel stats for streak and today's sessions
            today_str = date.today().isoformat()
            sessions_response = db.client.table("kegel_sessions").select(
                "id"
            ).eq("user_id", user_id).eq(
                "session_date", today_str
            ).execute()

            context.kegel_sessions_today = len(sessions_response.data) if sessions_response.data else 0

            # Get kegel streak (simplified - count consecutive days with sessions)
            streak_response = db.client.rpc(
                "calculate_kegel_streak",
                {"p_user_id": user_id}
            ).execute()

            if streak_response.data:
                context.kegel_streak_days = streak_response.data or 0

            return context

        except Exception as e:
            logger.error(f"Failed to get hormonal health context: {e}")
            return HormonalHealthContext()

    async def get_hormonal_context_for_ai(
        self,
        user_id: str,
        days: int = 7,
    ) -> str:
        """
        Get formatted hormonal health context string for AI prompts.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Formatted context string for AI prompts
        """
        context = await self.get_hormonal_health_context(user_id, days)
        return context.get_ai_context()

    async def get_hormonal_health_analytics(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get comprehensive hormonal health analytics for a user.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Dictionary with hormonal health data and AI context
        """
        context = await self.get_hormonal_health_context(user_id, days)

        return {
            **context.to_dict(),
            "ai_context": context.get_ai_context(),
            "workout_modifications": context.get_workout_modification_context(),
        }

    async def log_hormonal_profile_created(
        self,
        user_id: str,
        profile_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user creates their hormonal health profile."""
        event_data = {
            "hormone_goals": profile_data.get("hormone_goals", []),
            "primary_goal": profile_data.get("primary_goal"),
            "menstrual_tracking_enabled": profile_data.get("menstrual_tracking_enabled", False),
            "hormonal_diet_enabled": profile_data.get("hormonal_diet_enabled", False),
            "created_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="hormonal_health_setup",
        )

        logger.info(f"[Hormonal Profile Created] User {user_id}, goals: {event_data['hormone_goals']}")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.HORMONAL_PROFILE_CREATED,
            event_data=event_data,
            context=context,
        )

    async def log_hormonal_profile_updated(
        self,
        user_id: str,
        updated_fields: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user updates their hormonal health profile."""
        event_data = {
            "updated_fields": list(updated_fields.keys()),
            "updated_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="hormonal_health_settings",
        )

        logger.info(f"[Hormonal Profile Updated] User {user_id}, fields: {event_data['updated_fields']}")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.HORMONAL_PROFILE_UPDATED,
            event_data=event_data,
            context=context,
        )

    async def log_hormone_log_added(
        self,
        user_id: str,
        log_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user adds a hormone log entry."""
        event_data = {
            "log_date": log_data.get("log_date"),
            "has_symptoms": bool(log_data.get("symptoms")),
            "symptom_count": len(log_data.get("symptoms", [])),
            "energy_level": log_data.get("energy_level"),
            "mood": log_data.get("mood"),
            "logged_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="hormonal_health_log",
        )

        logger.info(f"[Hormone Log Added] User {user_id}, date: {event_data['log_date']}")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.HORMONE_LOG_ADDED,
            event_data=event_data,
            context=context,
        )

    async def log_period_logged(
        self,
        user_id: str,
        period_date: str,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user logs their period start date."""
        event_data = {
            "period_date": period_date,
            "logged_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="cycle_tracker",
        )

        logger.info(f"[Period Logged] User {user_id}, date: {period_date}")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.PERIOD_LOGGED,
            event_data=event_data,
            context=context,
        )

    async def log_kegel_preferences_updated(
        self,
        user_id: str,
        preferences: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user updates their kegel preferences."""
        event_data = {
            "kegels_enabled": preferences.get("kegels_enabled"),
            "include_in_warmup": preferences.get("include_in_warmup"),
            "include_in_cooldown": preferences.get("include_in_cooldown"),
            "current_level": preferences.get("current_level"),
            "focus_area": preferences.get("focus_area"),
            "target_sessions_per_day": preferences.get("target_sessions_per_day"),
            "updated_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="kegel_settings",
        )

        logger.info(f"[Kegel Preferences Updated] User {user_id}, enabled: {event_data['kegels_enabled']}")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.KEGEL_PREFERENCES_UPDATED,
            event_data=event_data,
            context=context,
        )

    async def log_kegel_session(
        self,
        user_id: str,
        session_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user completes a kegel session."""
        event_data = {
            "duration_seconds": session_data.get("duration_seconds"),
            "reps_completed": session_data.get("reps_completed"),
            "session_type": session_data.get("session_type", "standard"),
            "performed_during": session_data.get("performed_during", "standalone"),
            "logged_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="kegel_session",
        )

        logger.info(
            f"[Kegel Session Logged] User {user_id}, "
            f"duration: {event_data['duration_seconds']}s, type: {event_data['session_type']}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.KEGEL_SESSION_LOGGED,
            event_data=event_data,
            context=context,
        )

    async def log_kegel_session_from_workout(
        self,
        user_id: str,
        workout_id: str,
        placement: str,  # "warmup" or "cooldown"
        duration_seconds: int,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when kegel exercises are completed as part of a workout."""
        event_data = {
            "workout_id": workout_id,
            "placement": placement,
            "duration_seconds": duration_seconds,
            "logged_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="active_workout",
            extra_context={"workout_id": workout_id},
        )

        logger.info(
            f"[Kegel From Workout] User {user_id}, "
            f"workout: {workout_id}, placement: {placement}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.KEGEL_SESSION_FROM_WORKOUT,
            event_data=event_data,
            context=context,
        )

    async def log_kegel_daily_goal_met(
        self,
        user_id: str,
        sessions_completed: int,
        target_sessions: int,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user meets their daily kegel goal."""
        event_data = {
            "sessions_completed": sessions_completed,
            "target_sessions": target_sessions,
            "achieved_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
        )

        logger.info(
            f"[Kegel Daily Goal Met] User {user_id}, "
            f"sessions: {sessions_completed}/{target_sessions}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.KEGEL_DAILY_GOAL_MET,
            event_data=event_data,
            context=context,
        )

    async def log_kegel_streak_milestone(
        self,
        user_id: str,
        streak_days: int,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user reaches a kegel streak milestone."""
        event_data = {
            "streak_days": streak_days,
            "milestone_achieved_at": datetime.now().isoformat(),
        }

        context = self._build_context(
            device=device,
            app_version=app_version,
        )

        logger.info(f"[Kegel Streak Milestone] User {user_id}, streak: {streak_days} days")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.KEGEL_STREAK_MILESTONE,
            event_data=event_data,
            context=context,
        )


# Singleton instance
user_context_service = UserContextService()
