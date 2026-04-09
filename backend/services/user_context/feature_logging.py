"""
Feature Logging Mixin
=====================
Split screen, quick workout chat, library, exercise history,
and muscle analytics event logging and analytics.
"""

from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
import logging

from core.db import get_supabase_db
from services.user_context.models import EventType

logger = logging.getLogger(__name__)


class FeatureLoggingMixin:
    """Mixin for feature interaction logging and analytics."""

    # ==========================================================================
    # SPLIT SCREEN USAGE LOGGING
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
        """Log when user enters split screen mode."""
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
        """Log when user exits split screen mode."""
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
    # QUICK WORKOUT VIA CHAT LOGGING
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
        """Log when a user requests a quick workout via the AI Coach chat."""
        event_data = {
            "message": message[:500],
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
        """Log when a quick workout is successfully generated via AI Coach chat."""
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
        """Log when quick workout generation via chat fails."""
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
        """Get analytics for quick workout chat feature usage."""
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

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
            logger.error(f"Failed to get quick workout chat analytics: {e}", exc_info=True)
            return {"error": str(e)}

    async def get_split_screen_usage_patterns(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """Analyze user's split screen usage patterns."""
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

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

            all_features_used = []
            for e in exit_events:
                all_features_used.extend(e["event_data"].get("features_used", []))

            partner_apps: Dict[str, int] = {}
            for e in enter_events:
                partner = e["event_data"].get("partner_app")
                if partner:
                    partner_apps[partner] = partner_apps.get(partner, 0) + 1

            device_types: Dict[str, int] = {}
            for e in enter_events:
                device_type = e["event_data"].get("device_type")
                if device_type:
                    device_types[device_type] = device_types.get(device_type, 0) + 1

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
            logger.error(f"Failed to get split screen usage patterns: {e}", exc_info=True)
            return {
                "user_id": user_id,
                "period_days": days,
                "error": str(e),
            }

    # ==========================================================================
    # LIBRARY INTERACTION LOGGING
    # ==========================================================================

    async def log_exercise_viewed(
        self,
        user_id: str,
        exercise_id: str,
        exercise_name: str,
        source: str,
        muscle_group: Optional[str] = None,
        difficulty: Optional[str] = None,
        equipment: Optional[List[str]] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user views an exercise detail in the library."""
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
        """Log when a user views a program detail in the library."""
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
        search_type: str = "exercises",
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user searches in the library."""
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
        filter_type: str,
        filter_values: List[str],
        result_count: int = 0,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user applies a filter in the library."""
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
    # EXERCISE HISTORY AND MUSCLE ANALYTICS LOGGING
    # ==========================================================================

    async def log_exercise_history_view(
        self,
        user_id: str,
        exercise_name: str,
        time_range: str,
        total_sessions: int = 0,
        total_sets: int = 0,
        max_weight: Optional[float] = None,
        progression_trend: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user views exercise history details."""
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
        view_type: str,
        muscle_group: Optional[str] = None,
        time_range: str = "week",
        top_muscles_trained: Optional[List[str]] = None,
        neglected_muscles: Optional[List[str]] = None,
        balance_score: Optional[float] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user views muscle analytics."""
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
        muscle_clicked: str,
        interaction_type: str = "tap",
        muscle_volume_percentage: Optional[float] = None,
        last_trained_date: Optional[str] = None,
        sets_this_week: Optional[int] = None,
        exercises_for_muscle: Optional[List[str]] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user interacts with the muscle heatmap."""
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
        """Analyze user's library interaction patterns for AI personalization."""
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

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

            exercise_views = [
                e for e in events
                if e["event_type"] == EventType.LIBRARY_EXERCISE_VIEWED.value
            ]

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

            searches = [
                e for e in events
                if e["event_type"] == EventType.LIBRARY_SEARCH_PERFORMED.value
            ]

            search_terms = [s["event_data"].get("search_query", "").lower() for s in searches]

            filters = [
                e for e in events
                if e["event_type"] == EventType.LIBRARY_FILTER_USED.value
            ]

            filter_type_counts: Dict[str, int] = {}
            for f in filters:
                filter_type = f["event_data"].get("filter_type")
                if filter_type:
                    filter_type_counts[filter_type] = filter_type_counts.get(filter_type, 0) + 1

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
            logger.error(f"Failed to get library preferences: {e}", exc_info=True)
            return {
                "user_id": user_id,
                "period_days": days,
                "error": str(e),
            }

    def get_library_ai_context(
        self,
        preferences: Dict[str, Any],
    ) -> str:
        """Generate AI context string from library preferences."""
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
            terms = [t for t in searches["recent_terms"][:5] if len(t) >= 3]
            if terms:
                context_parts.append(
                    f"User has searched for: {', '.join(terms)}."
                )

        return " ".join(context_parts)
