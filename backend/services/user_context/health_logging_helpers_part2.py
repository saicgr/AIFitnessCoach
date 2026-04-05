"""Second part of health_logging_helpers.py (auto-split for size)."""
from typing import Any, Dict, Optional
from datetime import datetime, timedelta, date
import logging
from services.user_context.models import EventType
from services.user_context.models_helpers import DiabetesPatterns

logger = logging.getLogger(__name__)


class HealthLoggingMixinPart2:
    """Second half of HealthLoggingMixin methods. Use as mixin."""

    async def log_health_connect_diabetes_sync(
        self,
        user_id: str,
        glucose_count: int,
        insulin_count: int,
        sync_range_hours: int = 24,
        sync_status: str = "success",
        error_message: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log Health Connect sync for diabetes data."""
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
        goal_type: str,
        target_value: float,
        current_value: Optional[float] = None,
        target_date: Optional[str] = None,
        previous_goal: Optional[float] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user sets a diabetes-related goal."""
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
        value: float,
        risk_level: str,
        workout_id: Optional[str] = None,
        action_taken: Optional[str] = None,
        recommendation: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log a pre-workout glucose check."""
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
        """Analyze user's diabetes patterns from context logs."""
        try:
            db = get_supabase_db()
            now = datetime.now()
            cutoff = (now - timedelta(days=days)).isoformat()
            today_start = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
            last_24h = (now - timedelta(hours=24)).isoformat()
            last_7_days = (now - timedelta(days=7)).isoformat()

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
                    except (ValueError, TypeError) as e:
                        logger.debug(f"Failed to parse diagnosis date: {e}")
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

                latest = glucose_events[0]["event_data"]
                patterns.latest_glucose = latest.get("value")
                patterns.latest_glucose_status = latest.get("status")
                try:
                    patterns.latest_glucose_time = datetime.fromisoformat(
                        glucose_events[0]["created_at"].replace("Z", "+00:00")
                    )
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse glucose time: {e}")

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
                    except (ValueError, TypeError) as e:
                        logger.debug(f"Failed to parse A1C date: {e}")

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
        """Get formatted diabetes context string for AI prompts."""
        patterns = await self.get_diabetes_patterns(user_id, days)
        return patterns.get_ai_context()

    async def get_diabetes_analytics(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """Get comprehensive diabetes analytics for a user."""
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
    # HORMONAL HEALTH CONTEXT
    # ==========================================================================

    async def get_hormonal_health_context(
        self,
        user_id: str,
        days: int = 7,
    ) -> HormonalHealthContext:
        """Get hormonal health context for AI personalization."""
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
                        today = date.today()
                        days_since_period = (today - context.last_period_date).days
                        cycle_day = (days_since_period % context.avg_cycle_length) + 1
                        context.cycle_day = cycle_day

                        if cycle_day <= 5:
                            context.current_cycle_phase = "menstrual"
                        elif cycle_day <= 13:
                            context.current_cycle_phase = "follicular"
                        elif cycle_day <= 16:
                            context.current_cycle_phase = "ovulation"
                        else:
                            context.current_cycle_phase = "luteal"
                    except (ValueError, TypeError) as e:
                        logger.debug(f"Failed to parse cycle phase: {e}")

            # Get recent hormone logs for symptoms
            now = datetime.now()
            cutoff = (now - timedelta(days=days)).isoformat()

            logs_response = db.client.table("hormone_logs").select(
                "symptoms, energy_level"
            ).eq("user_id", user_id).gte(
                "log_date", cutoff
            ).order("log_date", desc=True).limit(7).execute()

            if logs_response.data:
                all_symptoms = []
                for log in logs_response.data:
                    symptoms = log.get("symptoms", [])
                    if symptoms:
                        all_symptoms.extend(symptoms)

                symptom_counts = Counter(all_symptoms)
                context.recent_symptoms = [s for s, _ in symptom_counts.most_common(5)]

                latest_log = logs_response.data[0]
                latest_symptoms = latest_log.get("symptoms", [])
                if latest_symptoms:
                    symptom_count = len(latest_symptoms)
                    if symptom_count >= 4:
                        context.symptom_severity = "severe"
                    elif symptom_count >= 2:
                        context.symptom_severity = "moderate"
                    else:
                        context.symptom_severity = "mild"
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

            # Get kegel streak
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
        """Get formatted hormonal health context string for AI prompts."""
        context = await self.get_hormonal_health_context(user_id, days)
        return context.get_ai_context()

    async def get_hormonal_health_analytics(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """Get comprehensive hormonal health analytics for a user."""
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
            device=device, app_version=app_version, screen_name="hormonal_health_setup",
        )

        logger.info(f"[Hormonal Profile Created] User {user_id}, goals: {event_data['hormone_goals']}")

        return await self.log_event(
            user_id=user_id, event_type=EventType.HORMONAL_PROFILE_CREATED,
            event_data=event_data, context=context,
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
            device=device, app_version=app_version, screen_name="hormonal_health_settings",
        )

        logger.info(f"[Hormonal Profile Updated] User {user_id}, fields: {event_data['updated_fields']}")

        return await self.log_event(
            user_id=user_id, event_type=EventType.HORMONAL_PROFILE_UPDATED,
            event_data=event_data, context=context,
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
            device=device, app_version=app_version, screen_name="hormonal_health_log",
        )

        logger.info(f"[Hormone Log Added] User {user_id}, date: {event_data['log_date']}")

        return await self.log_event(
            user_id=user_id, event_type=EventType.HORMONE_LOG_ADDED,
            event_data=event_data, context=context,
        )

    async def log_period_logged(
        self,
        user_id: str,
        period_date: str,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user logs their period start date."""
        event_data = {"period_date": period_date, "logged_at": datetime.now().isoformat()}

        context = self._build_context(
            device=device, app_version=app_version, screen_name="cycle_tracker",
        )

        logger.info(f"[Period Logged] User {user_id}, date: {period_date}")

        return await self.log_event(
            user_id=user_id, event_type=EventType.PERIOD_LOGGED,
            event_data=event_data, context=context,
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
            device=device, app_version=app_version, screen_name="kegel_settings",
        )

        logger.info(f"[Kegel Preferences Updated] User {user_id}, enabled: {event_data['kegels_enabled']}")

        return await self.log_event(
            user_id=user_id, event_type=EventType.KEGEL_PREFERENCES_UPDATED,
            event_data=event_data, context=context,
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
            device=device, app_version=app_version, screen_name="kegel_session",
        )

        logger.info(
            f"[Kegel Session Logged] User {user_id}, "
            f"duration: {event_data['duration_seconds']}s, type: {event_data['session_type']}"
        )

        return await self.log_event(
            user_id=user_id, event_type=EventType.KEGEL_SESSION_LOGGED,
            event_data=event_data, context=context,
        )

    async def log_kegel_session_from_workout(
        self,
        user_id: str,
        workout_id: str,
        placement: str,
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
            device=device, app_version=app_version, screen_name="active_workout",
            extra_context={"workout_id": workout_id},
        )

        logger.info(f"[Kegel From Workout] User {user_id}, workout: {workout_id}, placement: {placement}")

        return await self.log_event(
            user_id=user_id, event_type=EventType.KEGEL_SESSION_FROM_WORKOUT,
            event_data=event_data, context=context,
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

        context = self._build_context(device=device, app_version=app_version)

        logger.info(f"[Kegel Daily Goal Met] User {user_id}, sessions: {sessions_completed}/{target_sessions}")

        return await self.log_event(
            user_id=user_id, event_type=EventType.KEGEL_DAILY_GOAL_MET,
            event_data=event_data, context=context,
        )

    async def log_kegel_streak_milestone(
        self,
        user_id: str,
        streak_days: int,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user reaches a kegel streak milestone."""
        event_data = {"streak_days": streak_days, "milestone_achieved_at": datetime.now().isoformat()}

        context = self._build_context(device=device, app_version=app_version)

        logger.info(f"[Kegel Streak Milestone] User {user_id}, streak: {streak_days} days")

        return await self.log_event(
            user_id=user_id, event_type=EventType.KEGEL_STREAK_MILESTONE,
            event_data=event_data, context=context,
        )
