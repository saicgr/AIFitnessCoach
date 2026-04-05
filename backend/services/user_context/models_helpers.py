"""Helper functions extracted from models.
User Context Models
===================
Data models for user context tracking, including event types,
behavioral patterns, and health-related context structures.


"""
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
