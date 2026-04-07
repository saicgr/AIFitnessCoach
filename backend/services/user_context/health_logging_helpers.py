"""Helper functions extracted from health_logging.
Health Logging Mixin
====================
Injury tracking, strain prevention, senior fitness, progression pace,
diabetes tracking, and hormonal health event logging and analytics.


"""
from typing import Any, Dict, List, Optional
from datetime import datetime
import logging
from services.user_context.models import EventType
from services.user_context.health_logging_helpers_part2 import HealthLoggingMixinPart2

logger = logging.getLogger(__name__)


class HealthLoggingMixin(HealthLoggingMixinPart2):
    """Mixin for health-related event logging and analytics."""

    # ==========================================================================
    # INJURY TRACKING
    # ==========================================================================

    async def log_injury_event(
        self,
        user_id: str,
        event_type: EventType,
        injury_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Generic method to log injury-related events."""
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={"injury_tracking_version": "1.0"},
        )

        logger.info(
            f"[Injury Event] User {user_id}: {event_type.value} - data={injury_data}"
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
        severity: str,
        description: Optional[str] = None,
        exercises_to_avoid: Optional[List[str]] = None,
        expected_recovery_days: Optional[int] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user reports a new injury."""
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
        """Log when a user marks an injury as healed."""
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
        pain_level: int,
        mobility_level: str,
        improvement_since_last: str,
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user checks in on their injury status."""
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
    # STRAIN PREVENTION
    # ==========================================================================

    async def log_strain_event(
        self,
        user_id: str,
        event_type: EventType,
        strain_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Generic method to log strain-related events."""
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={"strain_prevention_version": "1.0"},
        )

        logger.info(
            f"[Strain Event] User {user_id}: {event_type.value} - data={strain_data}"
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
        intensity_level: str,
        fatigue_score: Optional[float] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log strain data after a workout session."""
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
        alert_type: str,
        risk_level: str,
        affected_muscles: List[str],
        recommendation: str,
        volume_threshold_exceeded: Optional[float] = None,
        days_without_rest: Optional[int] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a strain alert is created for the user."""
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
        action_taken: str,
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user acknowledges a strain alert."""
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
    # SENIOR FITNESS
    # ==========================================================================

    async def log_senior_event(
        self,
        user_id: str,
        event_type: EventType,
        settings_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Generic method to log senior fitness events."""
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={"senior_fitness_version": "1.0"},
        )

        logger.info(
            f"[Senior Event] User {user_id}: {event_type.value} - data={settings_data}"
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
        """Log when senior fitness settings are updated."""
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
        recovery_status: str,
        energy_level: int,
        soreness_level: int,
        recommended_intensity: str,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log a senior user's recovery check before workout."""
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
    # PROGRESSION PACE
    # ==========================================================================

    async def log_progression_event(
        self,
        user_id: str,
        event_type: EventType,
        preferences_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Generic method to log progression-related events."""
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={"progression_tracking_version": "1.0"},
        )

        logger.info(
            f"[Progression Event] User {user_id}: {event_type.value} - data={preferences_data}"
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
        new_pace: str,
        reason: Optional[str] = None,
        triggered_by: str = "user",
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user changes their progression pace preference."""
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
        modification_reason: str,
        exercises_removed: Optional[List[str]] = None,
        exercises_substituted: Optional[Dict[str, str]] = None,
        intensity_reduced: bool = False,
        volume_reduced: bool = False,
        reduction_percentage: Optional[float] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a workout is modified for safety reasons."""
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
            extra_context={"safety_modification_version": "1.0"},
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
    # DIABETES TRACKING
    # ==========================================================================

    async def log_diabetes_event(
        self,
        user_id: str,
        event_type: EventType,
        diabetes_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Generic method to log diabetes-related events."""
        context = self._build_context(
            device=device,
            app_version=app_version,
            extra_context={"diabetes_tracking_version": "1.0"},
        )

        logger.info(
            f"[Diabetes Event] User {user_id}: {event_type.value} - data={diabetes_data}"
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
        diabetes_type: str,
        diagnosis_date: Optional[str] = None,
        target_glucose_min: float = 70.0,
        target_glucose_max: float = 180.0,
        a1c_goal: Optional[float] = None,
        uses_insulin: bool = False,
        uses_cgm: bool = False,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user creates or updates their diabetes profile."""
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
        value: float,
        status: str,
        meal_context: Optional[str] = None,
        source: str = "manual",
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user records a blood glucose reading."""
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
        insulin_type: str,
        dose_context: Optional[str] = None,
        glucose_at_dose: Optional[float] = None,
        notes: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user records an insulin dose."""
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
        value: float,
        test_date: Optional[str] = None,
        goal: Optional[float] = None,
        previous_a1c: Optional[float] = None,
        is_lab_result: bool = True,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user records an A1C result."""
        change = None
        if previous_a1c is not None:
            change = round(value - previous_a1c, 1)

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
        alert_type: str,
        value: float,
        threshold: float,
        source: str = "app",
        action_suggested: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a glucose alert is triggered."""
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

