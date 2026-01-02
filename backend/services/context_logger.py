"""
Unified Context Logger for AI Learning.

Captures user events that help the AI personalize workouts:
- Injuries and recovery
- Strain patterns
- Progression preferences
- Cardio session feedback
- Volume tracking
- Rehab exercise completion

This module provides a high-level ContextLogger class that wraps the
UserContextService and provides specialized methods for injury, strain,
progression, and cardio-related context logging.
"""

from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional
from dataclasses import dataclass, field
import logging

from core.db import get_supabase_db

logger = logging.getLogger(__name__)


# =============================================================================
# DATA CLASSES FOR INJURY & STRAIN CONTEXT
# =============================================================================

@dataclass
class InjuryContext:
    """
    Injury-related context for AI personalization.

    Provides the AI with information about:
    - Active injuries and their severity
    - Recovery progress and phases
    - Exercises to avoid
    - Past injury patterns
    """
    active_injuries: List[Dict[str, Any]] = field(default_factory=list)
    recovering_injuries: List[Dict[str, Any]] = field(default_factory=list)
    historical_injuries: List[Dict[str, Any]] = field(default_factory=list)
    exercises_to_avoid: List[str] = field(default_factory=list)
    body_parts_affected: List[str] = field(default_factory=list)
    injury_prone_areas: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "active_injuries": self.active_injuries,
            "recovering_injuries": self.recovering_injuries,
            "historical_injuries": self.historical_injuries,
            "exercises_to_avoid": self.exercises_to_avoid,
            "body_parts_affected": self.body_parts_affected,
            "injury_prone_areas": self.injury_prone_areas,
        }

    def get_ai_context(self) -> str:
        """Generate a context string for AI prompts."""
        if not self.active_injuries and not self.recovering_injuries:
            return ""

        context_parts = []

        if self.active_injuries:
            injuries_desc = [
                f"{inj.get('body_part')} ({inj.get('severity')} severity, "
                f"{inj.get('days_since_injury', 0)} days ago)"
                for inj in self.active_injuries
            ]
            context_parts.append(
                f"Active injuries: {', '.join(injuries_desc)}. "
                "Avoid exercises targeting these areas."
            )

        if self.recovering_injuries:
            recovering_desc = [
                f"{inj.get('body_part')} ({inj.get('recovery_phase')} phase)"
                for inj in self.recovering_injuries
            ]
            context_parts.append(
                f"Recovering injuries: {', '.join(recovering_desc)}. "
                "Progress slowly with these areas."
            )

        if self.exercises_to_avoid:
            context_parts.append(
                f"Avoid these exercises: {', '.join(self.exercises_to_avoid[:10])}."
            )

        if self.injury_prone_areas:
            context_parts.append(
                f"User is prone to injury in: {', '.join(self.injury_prone_areas)}. "
                "Be cautious with exercises targeting these areas."
            )

        return " ".join(context_parts)


@dataclass
class StrainContext:
    """
    Strain-related context for AI personalization.

    Tracks:
    - Recent strain detections
    - Volume warnings
    - Strain-prone muscle groups
    - Risk assessment history
    """
    recent_strain_detections: List[Dict[str, Any]] = field(default_factory=list)
    recent_volume_warnings: List[Dict[str, Any]] = field(default_factory=list)
    strain_incidents: List[Dict[str, Any]] = field(default_factory=list)
    strain_prone_muscles: List[str] = field(default_factory=list)
    current_risk_level: str = "low"  # "low", "moderate", "high"
    weekly_volume_status: str = "normal"  # "below", "normal", "high", "excessive"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "recent_strain_detections": self.recent_strain_detections,
            "recent_volume_warnings": self.recent_volume_warnings,
            "strain_incidents": self.strain_incidents,
            "strain_prone_muscles": self.strain_prone_muscles,
            "current_risk_level": self.current_risk_level,
            "weekly_volume_status": self.weekly_volume_status,
        }

    def get_ai_context(self) -> str:
        """Generate a context string for AI prompts."""
        context_parts = []

        if self.current_risk_level in ["moderate", "high"]:
            context_parts.append(
                f"Current strain risk level: {self.current_risk_level}. "
                "Reduce intensity or volume."
            )

        if self.weekly_volume_status in ["high", "excessive"]:
            context_parts.append(
                f"Weekly training volume is {self.weekly_volume_status}. "
                "Consider lighter workouts or rest days."
            )

        if self.strain_prone_muscles:
            context_parts.append(
                f"User is prone to strain in: {', '.join(self.strain_prone_muscles)}. "
                "Progress slowly in these areas and ensure adequate warm-up."
            )

        if self.strain_incidents:
            recent_incidents = [
                f"{inc.get('muscle_group')} ({inc.get('days_ago', 0)} days ago)"
                for inc in self.strain_incidents[:3]
            ]
            context_parts.append(
                f"Recent strain history: {', '.join(recent_incidents)}."
            )

        return " ".join(context_parts)


@dataclass
class ProgressionContext:
    """
    Progression-related context for AI personalization.

    Tracks user's progression preferences and history:
    - Current progression pace preference
    - Weight/rep progression history
    - Cardio progression status
    """
    progression_pace: str = "medium"  # "slow", "medium", "fast"
    pace_history: List[Dict[str, Any]] = field(default_factory=list)
    cardio_programs: List[Dict[str, Any]] = field(default_factory=list)
    active_cardio_program: Optional[Dict[str, Any]] = None
    weight_progression_style: str = "conservative"  # "conservative", "moderate", "aggressive"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "progression_pace": self.progression_pace,
            "pace_history": self.pace_history,
            "cardio_programs": self.cardio_programs,
            "active_cardio_program": self.active_cardio_program,
            "weight_progression_style": self.weight_progression_style,
        }

    def get_ai_context(self) -> str:
        """Generate a context string for AI prompts."""
        context_parts = []

        pace_descriptions = {
            "slow": "prefers gradual progression (3-4 weeks before weight increases)",
            "medium": "prefers moderate progression (1-2 weeks before weight increases)",
            "fast": "comfortable with quick progression (increase when ready)",
        }

        context_parts.append(
            f"User {pace_descriptions.get(self.progression_pace, 'prefers moderate progression')}."
        )

        if self.active_cardio_program:
            program = self.active_cardio_program
            context_parts.append(
                f"Active cardio program: {program.get('name', 'Unknown')} "
                f"(Week {program.get('current_week', 1)}, Session {program.get('current_session', 1)})."
            )

        return " ".join(context_parts)


# =============================================================================
# CONTEXT LOGGER CLASS
# =============================================================================

class ContextLogger:
    """
    Unified context logger for AI learning.

    Provides methods to:
    - Log injury, strain, and progression events
    - Retrieve context for AI prompts
    - Track user patterns for personalization
    """

    def __init__(self):
        """Initialize the context logger."""
        self.db = get_supabase_db()

    # =========================================================================
    # INJURY CONTEXT LOGGING
    # =========================================================================

    async def log_injury_reported(
        self,
        user_id: str,
        body_part: str,
        severity: str,
        exercises_avoided: List[str],
        expected_recovery_date: datetime,
        pain_level: Optional[int] = None,
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when a user reports an injury.

        This is a critical event for AI personalization - helps the AI:
        - Avoid exercises that could aggravate the injury
        - Suggest appropriate rehab exercises
        - Track injury patterns for prevention

        Args:
            user_id: User ID
            body_part: Affected body part (e.g., "shoulder", "back", "knee")
            severity: Injury severity ("mild", "moderate", "severe")
            exercises_avoided: List of exercises to avoid
            expected_recovery_date: Expected recovery date
            pain_level: Pain level 1-10 (optional)
            notes: Additional notes (optional)
            device: Device type (optional)

        Returns:
            Event ID if successful, None otherwise
        """
        event_data = {
            "body_part": body_part,
            "severity": severity,
            "exercises_avoided": exercises_avoided,
            "expected_recovery_date": expected_recovery_date.isoformat(),
            "pain_level": pain_level,
            "notes": notes,
            "reported_at": datetime.now().isoformat(),
        }

        context = self._build_context(device=device)

        logger.info(
            f"[Injury Reported] User {user_id}: {body_part} ({severity}), "
            f"avoiding {len(exercises_avoided)} exercises"
        )

        return await self._log_event(
            user_id=user_id,
            event_type="injury_reported",
            event_data=event_data,
            context=context,
            importance="high",
        )

    async def log_injury_recovered(
        self,
        user_id: str,
        body_part: str,
        original_severity: str,
        recovery_duration_days: int,
        full_recovery: bool = True,
        residual_limitations: Optional[List[str]] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when an injury is marked as healed.

        Args:
            user_id: User ID
            body_part: Recovered body part
            original_severity: Original injury severity
            recovery_duration_days: Days it took to recover
            full_recovery: Whether this is a full recovery
            residual_limitations: Any remaining limitations
            device: Device type (optional)

        Returns:
            Event ID if successful, None otherwise
        """
        event_data = {
            "body_part": body_part,
            "original_severity": original_severity,
            "recovery_duration_days": recovery_duration_days,
            "full_recovery": full_recovery,
            "residual_limitations": residual_limitations or [],
            "recovered_at": datetime.now().isoformat(),
        }

        context = self._build_context(device=device)

        logger.info(
            f"[Injury Recovered] User {user_id}: {body_part} "
            f"({'full' if full_recovery else 'partial'} recovery after {recovery_duration_days} days)"
        )

        return await self._log_event(
            user_id=user_id,
            event_type="injury_recovered",
            event_data=event_data,
            context=context,
            importance="normal",
        )

    async def log_rehab_exercise_completed(
        self,
        user_id: str,
        injury_id: str,
        body_part: str,
        exercise_name: str,
        sets_completed: int,
        recovery_phase: str,
        pain_during_exercise: Optional[int] = None,
        difficulty_rating: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user completes rehab exercises.

        Args:
            user_id: User ID
            injury_id: Associated injury ID
            body_part: Body part being rehabilitated
            exercise_name: Name of rehab exercise
            sets_completed: Number of sets completed
            recovery_phase: Current recovery phase
            pain_during_exercise: Pain level during exercise (1-10)
            difficulty_rating: How difficult it felt
            device: Device type (optional)

        Returns:
            Event ID if successful, None otherwise
        """
        event_data = {
            "injury_id": injury_id,
            "body_part": body_part,
            "exercise_name": exercise_name,
            "sets_completed": sets_completed,
            "recovery_phase": recovery_phase,
            "pain_during_exercise": pain_during_exercise,
            "difficulty_rating": difficulty_rating,
            "completed_at": datetime.now().isoformat(),
        }

        context = self._build_context(device=device)

        logger.info(
            f"[Rehab Exercise] User {user_id}: {exercise_name} for {body_part} "
            f"({sets_completed} sets, phase: {recovery_phase})"
        )

        return await self._log_event(
            user_id=user_id,
            event_type="rehab_exercise_completed",
            event_data=event_data,
            context=context,
            importance="normal",
        )

    # =========================================================================
    # STRAIN CONTEXT LOGGING
    # =========================================================================

    async def log_strain_detected(
        self,
        user_id: str,
        muscle_group: str,
        risk_level: str,
        volume_increase_percent: float,
        recommendation: str,
        contributing_factors: Optional[List[str]] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when strain prevention system detects high risk.

        Args:
            user_id: User ID
            muscle_group: Affected muscle group
            risk_level: Risk level ("low", "moderate", "high", "critical")
            volume_increase_percent: Percentage increase in volume
            recommendation: System recommendation
            contributing_factors: Factors contributing to risk
            device: Device type (optional)

        Returns:
            Event ID if successful, None otherwise
        """
        event_data = {
            "muscle_group": muscle_group,
            "risk_level": risk_level,
            "volume_increase_percent": round(volume_increase_percent, 1),
            "recommendation": recommendation,
            "contributing_factors": contributing_factors or [],
            "detected_at": datetime.now().isoformat(),
        }

        context = self._build_context(device=device)

        importance = "critical" if risk_level == "critical" else (
            "high" if risk_level == "high" else "normal"
        )

        logger.info(
            f"[Strain Detected] User {user_id}: {muscle_group} "
            f"({risk_level} risk, +{volume_increase_percent:.1f}% volume)"
        )

        return await self._log_event(
            user_id=user_id,
            event_type="strain_detected",
            event_data=event_data,
            context=context,
            importance=importance,
        )

    async def log_strain_incident(
        self,
        user_id: str,
        muscle_group: str,
        severity: str,
        during_exercise: Optional[str] = None,
        during_workout_id: Optional[str] = None,
        description: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user reports a strain.

        Args:
            user_id: User ID
            muscle_group: Strained muscle group
            severity: Strain severity ("mild", "moderate", "severe")
            during_exercise: Exercise during which strain occurred
            during_workout_id: Workout ID if applicable
            description: User's description
            device: Device type (optional)

        Returns:
            Event ID if successful, None otherwise
        """
        event_data = {
            "muscle_group": muscle_group,
            "severity": severity,
            "during_exercise": during_exercise,
            "during_workout_id": during_workout_id,
            "description": description,
            "reported_at": datetime.now().isoformat(),
        }

        context = self._build_context(device=device)

        logger.warning(
            f"[Strain Incident] User {user_id}: {muscle_group} ({severity}), "
            f"during: {during_exercise or 'unknown'}"
        )

        return await self._log_event(
            user_id=user_id,
            event_type="strain_incident",
            event_data=event_data,
            context=context,
            importance="high",
        )

    async def log_volume_warning(
        self,
        user_id: str,
        muscle_group: str,
        current_weekly_sets: int,
        recommended_max_sets: int,
        excess_percentage: float,
        recommendation: str,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when weekly volume exceeds safe limits.

        Args:
            user_id: User ID
            muscle_group: Affected muscle group
            current_weekly_sets: Current weekly sets
            recommended_max_sets: Recommended maximum sets
            excess_percentage: How much over the limit
            recommendation: System recommendation
            device: Device type (optional)

        Returns:
            Event ID if successful, None otherwise
        """
        event_data = {
            "muscle_group": muscle_group,
            "current_weekly_sets": current_weekly_sets,
            "recommended_max_sets": recommended_max_sets,
            "excess_percentage": round(excess_percentage, 1),
            "recommendation": recommendation,
            "warning_at": datetime.now().isoformat(),
        }

        context = self._build_context(device=device)

        logger.info(
            f"[Volume Warning] User {user_id}: {muscle_group} "
            f"({current_weekly_sets}/{recommended_max_sets} sets, +{excess_percentage:.1f}% over)"
        )

        return await self._log_event(
            user_id=user_id,
            event_type="volume_warning",
            event_data=event_data,
            context=context,
            importance="normal",
        )

    # =========================================================================
    # PROGRESSION CONTEXT LOGGING
    # =========================================================================

    async def log_progression_pace_changed(
        self,
        user_id: str,
        previous_pace: str,
        new_pace: str,
        reason: str,
        changed_by: str = "user_requested",
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user changes progression settings.

        Args:
            user_id: User ID
            previous_pace: Previous progression pace
            new_pace: New progression pace
            reason: Reason for change
            changed_by: Who initiated the change ("user_requested", "ai_recommended")
            device: Device type (optional)

        Returns:
            Event ID if successful, None otherwise
        """
        event_data = {
            "previous_pace": previous_pace,
            "new_pace": new_pace,
            "reason": reason,
            "changed_by": changed_by,
            "changed_at": datetime.now().isoformat(),
        }

        context = self._build_context(device=device)

        logger.info(
            f"[Progression Pace Changed] User {user_id}: {previous_pace} -> {new_pace} "
            f"({changed_by})"
        )

        return await self._log_event(
            user_id=user_id,
            event_type="progression_pace_changed",
            event_data=event_data,
            context=context,
            importance="normal",
        )

    async def log_cardio_progression_started(
        self,
        user_id: str,
        program_id: str,
        program_name: str,
        total_weeks: int,
        sessions_per_week: int,
        starting_level: str,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when user starts a C25K-style cardio program.

        Args:
            user_id: User ID
            program_id: Cardio program ID
            program_name: Name of the program (e.g., "Couch to 5K")
            total_weeks: Total weeks in program
            sessions_per_week: Sessions per week
            starting_level: User's starting fitness level
            device: Device type (optional)

        Returns:
            Event ID if successful, None otherwise
        """
        event_data = {
            "program_id": program_id,
            "program_name": program_name,
            "total_weeks": total_weeks,
            "sessions_per_week": sessions_per_week,
            "starting_level": starting_level,
            "started_at": datetime.now().isoformat(),
        }

        context = self._build_context(device=device)

        logger.info(
            f"[Cardio Progression Started] User {user_id}: {program_name} "
            f"({total_weeks} weeks, {sessions_per_week} sessions/week)"
        )

        return await self._log_event(
            user_id=user_id,
            event_type="cardio_progression_started",
            event_data=event_data,
            context=context,
            importance="normal",
        )

    async def log_cardio_session_completed(
        self,
        user_id: str,
        program_id: str,
        week_number: int,
        session_number: int,
        perceived_difficulty: str,
        strain_reported: bool,
        duration_minutes: int,
        distance_km: Optional[float] = None,
        avg_heart_rate: Optional[int] = None,
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log when cardio progression session is done.

        Args:
            user_id: User ID
            program_id: Cardio program ID
            week_number: Current week in program
            session_number: Session number in week
            perceived_difficulty: How difficult user found it
            strain_reported: Whether user reported any strain
            duration_minutes: Actual duration
            distance_km: Distance covered (optional)
            avg_heart_rate: Average heart rate (optional)
            notes: User notes (optional)
            device: Device type (optional)

        Returns:
            Event ID if successful, None otherwise
        """
        event_data = {
            "program_id": program_id,
            "week": week_number,
            "session": session_number,
            "perceived_difficulty": perceived_difficulty,
            "strain_reported": strain_reported,
            "duration_minutes": duration_minutes,
            "distance_km": distance_km,
            "avg_heart_rate": avg_heart_rate,
            "notes": notes,
            "completed_at": datetime.now().isoformat(),
        }

        context = self._build_context(device=device)

        importance = "high" if strain_reported else "normal"

        logger.info(
            f"[Cardio Session Completed] User {user_id}: Week {week_number}, "
            f"Session {session_number} ({perceived_difficulty})"
        )

        return await self._log_event(
            user_id=user_id,
            event_type="cardio_session_completed",
            event_data=event_data,
            context=context,
            importance=importance,
        )

    # =========================================================================
    # CONTEXT RETRIEVAL FOR AI PROMPTS
    # =========================================================================

    async def get_injury_context(self, user_id: str) -> InjuryContext:
        """
        Get injury-related context for AI prompts.

        Fetches recent injury history and builds context for the AI
        to understand user's injury status and limitations.

        Args:
            user_id: User ID

        Returns:
            InjuryContext with relevant injury data
        """
        try:
            # Fetch injury-related context logs from last 6 months
            cutoff = (datetime.now() - timedelta(days=180)).isoformat()

            response = self.db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", ["injury_reported", "injury_recovered", "strain_incident"]
            ).gte(
                "created_at", cutoff
            ).order(
                "created_at", desc=True
            ).limit(20).execute()

            logs = response.data or []

            context = InjuryContext()

            # Track active vs recovered injuries
            active_injuries = {}
            recovered_parts = set()

            for log in logs:
                event_type = log["event_type"]
                data = log.get("event_data", {})

                if event_type == "injury_recovered":
                    recovered_parts.add(data.get("body_part"))

                elif event_type == "injury_reported":
                    body_part = data.get("body_part")
                    if body_part and body_part not in recovered_parts:
                        if body_part not in active_injuries:
                            created_at = log.get("created_at", "")
                            if created_at:
                                try:
                                    injury_date = datetime.fromisoformat(
                                        created_at.replace("Z", "+00:00")
                                    )
                                    days_since = (datetime.now() - injury_date.replace(tzinfo=None)).days
                                except Exception:
                                    days_since = 0
                            else:
                                days_since = 0

                            active_injuries[body_part] = {
                                "body_part": body_part,
                                "severity": data.get("severity"),
                                "days_since_injury": days_since,
                                "exercises_avoided": data.get("exercises_avoided", []),
                            }

                            context.exercises_to_avoid.extend(
                                data.get("exercises_avoided", [])
                            )

                elif event_type == "strain_incident":
                    muscle = data.get("muscle_group")
                    if muscle and muscle not in context.injury_prone_areas:
                        context.injury_prone_areas.append(muscle)

            context.active_injuries = list(active_injuries.values())
            context.body_parts_affected = list(active_injuries.keys())
            context.exercises_to_avoid = list(set(context.exercises_to_avoid))

            return context

        except Exception as e:
            logger.error(f"Failed to get injury context for user {user_id}: {e}")
            return InjuryContext()

    async def get_strain_context(self, user_id: str) -> StrainContext:
        """
        Get strain history for AI prompts.

        Args:
            user_id: User ID

        Returns:
            StrainContext with strain-related data
        """
        try:
            cutoff = (datetime.now() - timedelta(days=90)).isoformat()

            response = self.db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", ["strain_detected", "strain_incident", "volume_warning"]
            ).gte(
                "created_at", cutoff
            ).order(
                "created_at", desc=True
            ).limit(15).execute()

            logs = response.data or []

            context = StrainContext()
            muscle_strain_counts: Dict[str, int] = {}

            for log in logs:
                event_type = log["event_type"]
                data = log.get("event_data", {})
                created_at = log.get("created_at", "")

                try:
                    log_date = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                    days_ago = (datetime.now() - log_date.replace(tzinfo=None)).days
                except Exception:
                    days_ago = 0

                if event_type == "strain_detected":
                    context.recent_strain_detections.append({
                        **data,
                        "days_ago": days_ago,
                    })
                    muscle = data.get("muscle_group")
                    if muscle:
                        muscle_strain_counts[muscle] = muscle_strain_counts.get(muscle, 0) + 1

                    if data.get("risk_level") in ["high", "critical"]:
                        context.current_risk_level = data.get("risk_level")

                elif event_type == "strain_incident":
                    context.strain_incidents.append({
                        **data,
                        "days_ago": days_ago,
                    })
                    muscle = data.get("muscle_group")
                    if muscle:
                        muscle_strain_counts[muscle] = muscle_strain_counts.get(muscle, 0) + 2

                elif event_type == "volume_warning":
                    context.recent_volume_warnings.append({
                        **data,
                        "days_ago": days_ago,
                    })
                    if data.get("excess_percentage", 0) > 20:
                        context.weekly_volume_status = "excessive"
                    elif data.get("excess_percentage", 0) > 10:
                        context.weekly_volume_status = "high"

            # Identify strain-prone muscles (appeared 2+ times)
            context.strain_prone_muscles = [
                muscle for muscle, count in muscle_strain_counts.items()
                if count >= 2
            ]

            return context

        except Exception as e:
            logger.error(f"Failed to get strain context for user {user_id}: {e}")
            return StrainContext()

    async def get_progression_context(self, user_id: str) -> ProgressionContext:
        """
        Get progression-related context for AI prompts.

        Args:
            user_id: User ID

        Returns:
            ProgressionContext with progression preferences
        """
        try:
            response = self.db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", ["progression_pace_changed", "cardio_progression_started"]
            ).order(
                "created_at", desc=True
            ).limit(10).execute()

            logs = response.data or []

            context = ProgressionContext()

            for log in logs:
                event_type = log["event_type"]
                data = log.get("event_data", {})

                if event_type == "progression_pace_changed":
                    if not context.pace_history:  # First (most recent) is current
                        context.progression_pace = data.get("new_pace", "medium")
                    context.pace_history.append(data)

                elif event_type == "cardio_progression_started":
                    context.cardio_programs.append(data)
                    if context.active_cardio_program is None:
                        context.active_cardio_program = data

            return context

        except Exception as e:
            logger.error(f"Failed to get progression context for user {user_id}: {e}")
            return ProgressionContext()

    async def get_full_ai_context(self, user_id: str) -> str:
        """
        Get combined context string for AI prompts.

        This method fetches all relevant context (injury, strain, progression)
        and combines them into a single string for inclusion in AI prompts.

        Args:
            user_id: User ID

        Returns:
            Combined context string for AI prompts
        """
        injury_ctx = await self.get_injury_context(user_id)
        strain_ctx = await self.get_strain_context(user_id)
        progression_ctx = await self.get_progression_context(user_id)

        context_parts = []

        injury_context = injury_ctx.get_ai_context()
        if injury_context:
            context_parts.append(f"INJURY STATUS: {injury_context}")

        strain_context = strain_ctx.get_ai_context()
        if strain_context:
            context_parts.append(f"STRAIN RISK: {strain_context}")

        progression_context = progression_ctx.get_ai_context()
        if progression_context:
            context_parts.append(f"PROGRESSION: {progression_context}")

        if not context_parts:
            return ""

        return "\n".join(context_parts)

    # =========================================================================
    # PRIVATE HELPER METHODS
    # =========================================================================

    def _build_context(
        self,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
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
        if extra_context:
            context.update(extra_context)

        return context

    def _get_time_of_day(self, dt: datetime) -> str:
        """Get time of day classification."""
        hour = dt.hour

        if 5 <= hour < 12:
            return "morning"
        elif 12 <= hour < 17:
            return "afternoon"
        elif 17 <= hour < 21:
            return "evening"
        else:
            return "night"

    async def _log_event(
        self,
        user_id: str,
        event_type: str,
        event_data: Dict[str, Any],
        context: Optional[Dict[str, Any]] = None,
        importance: str = "normal",
    ) -> Optional[str]:
        """
        Log an event to the database.

        Args:
            user_id: User ID
            event_type: Type of event
            event_data: Event-specific data
            context: Contextual information
            importance: Event importance level

        Returns:
            Event ID if successful, None otherwise
        """
        try:
            record = {
                "user_id": user_id,
                "event_type": event_type,
                "event_data": event_data,
                "context": context or {},
            }

            # Add importance to context if provided
            if importance != "normal":
                record["context"]["importance"] = importance

            response = self.db.client.table("user_context_logs").insert(record).execute()

            if response.data:
                return response.data[0].get("id")
            return None

        except Exception as e:
            logger.error(f"Failed to log event {event_type} for user {user_id}: {e}")
            return None


# =============================================================================
# SINGLETON INSTANCE
# =============================================================================

_context_logger: Optional[ContextLogger] = None


def get_context_logger() -> ContextLogger:
    """Get the ContextLogger singleton instance."""
    global _context_logger
    if _context_logger is None:
        _context_logger = ContextLogger()
    return _context_logger
