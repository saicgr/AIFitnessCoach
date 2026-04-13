"""
User profile CRUD endpoints: get, update, delete, reset, photo upload/delete.
"""
from core.db import get_supabase_db
import json
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Request
from core.auth import get_current_user, get_verified_auth_token, verify_user_ownership, get_admin_user
from core.exceptions import safe_internal_error
from typing import Optional, List

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.rate_limiter import limiter
from core.activity_logger import log_user_activity, log_user_error
from models.schemas import User, UserCreate, UserUpdate

from api.v1.users.models import (
    DestructiveActionRequest,
    ProgramPreferences,
    row_to_user,
    merge_extended_fields_into_preferences,
)
from api.v1.users.onboarding import create_gym_profiles_from_onboarding

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=User)
@limiter.limit("5/minute")
async def create_user(request, user: UserCreate,
    current_user: dict = Depends(get_current_user),
):
    """Create a new user."""
    logger.info(f"Creating user: level={user.fitness_level}")

    try:
        db = get_supabase_db()

        # Parse JSON strings to actual types for Supabase JSONB
        goals = json.loads(user.goals) if isinstance(user.goals, str) else user.goals
        equipment = json.loads(user.equipment) if isinstance(user.equipment, str) else user.equipment
        active_injuries = json.loads(user.active_injuries) if isinstance(user.active_injuries, str) else user.active_injuries

        # Merge extended onboarding fields into preferences
        final_preferences = merge_extended_fields_into_preferences(
            user.preferences,
            user.days_per_week,
            user.workout_duration,
            user.training_split,
            user.intensity_preference,
            user.preferred_time,
            user.progression_pace,
            user.workout_type_preference,
            user.workout_environment,
            user.gym_name,
            workout_variety=user.workout_variety,
        )
        logger.debug(f"User preferences: {final_preferences}")

        user_data = {
            "fitness_level": user.fitness_level,
            "goals": goals,
            "equipment": equipment,
            "preferences": final_preferences,
            "active_injuries": active_injuries,
        }

        created = db.create_user(user_data)
        logger.info(f"User created: id={created['id']}")

        # Log user creation
        await log_user_activity(
            user_id=created['id'],
            action="user_created",
            endpoint="/api/v1/users/",
            message=f"New user created (fitness_level: {user.fitness_level})",
            metadata={"fitness_level": user.fitness_level},
            status_code=200
        )

        return row_to_user(created)

    except Exception as e:
        logger.error(f"Failed to create user: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.get("/", response_model=List[User])
async def get_all_users(
    current_user: dict = Depends(get_admin_user),
):
    """Get all users."""
    logger.info("Fetching all users")
    try:
        db = get_supabase_db()
        rows = db.get_all_users()
        return [row_to_user(row) for row in rows]
    except Exception as e:
        logger.error(f"Failed to get users: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.get("/by-auth/{auth_id}", response_model=User)
async def get_user_by_auth(auth_id: str,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Get a user by their Supabase auth_id.

    This endpoint is used during session restore when we have the Supabase Auth ID
    but need to look up the user's internal database ID.

    Uses get_verified_auth_token (not get_current_user) because if the user
    doesn't have a DB row yet, get_current_user would fail with 404 before
    this endpoint runs — making it impossible to detect a missing DB row.
    """
    logger.info(f"Fetching user by auth_id: {auth_id}")
    # Security: users can only look up their own auth record
    if verified_token["auth_id"] != auth_id:
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        db = get_supabase_db()
        row = db.get_user_by_auth_id(auth_id)

        if not row:
            logger.warning(f"User not found by auth_id: {auth_id}")
            raise HTTPException(status_code=404, detail="User not found")

        logger.debug(f"User found by auth_id: id={row.get('id')}, auth_id={auth_id}")
        return row_to_user(row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user by auth_id: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a user by ID."""
    logger.info(f"Fetching user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        row = db.get_user(user_id)

        if not row:
            logger.warning(f"User not found: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        logger.debug(f"User found: id={user_id}, level={row.get('fitness_level')}")
        return row_to_user(row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.get("/{user_id}/program-preferences", response_model=ProgramPreferences)
async def get_program_preferences(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's current program preferences for the customize program sheet.

    Merges preferences from:
    1. users.preferences JSONB (base preferences)
    2. Most recent workout_regenerations entry (latest selections)

    Returns unified preferences for pre-populating the edit form.
    """
    logger.info(f"Fetching program preferences for user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Get user data
        user_row = db.get_user(user_id)
        if not user_row:
            logger.warning(f"User not found: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Get base preferences from user record
        base_prefs = user_row.get("preferences", {})
        if isinstance(base_prefs, str):
            try:
                base_prefs = json.loads(base_prefs)
            except json.JSONDecodeError:
                base_prefs = {}

        # Get user's equipment from user record
        user_equipment = user_row.get("equipment", [])
        if isinstance(user_equipment, str):
            try:
                user_equipment = json.loads(user_equipment)
            except json.JSONDecodeError:
                user_equipment = []

        # Get user's active injuries
        user_injuries = user_row.get("active_injuries", [])
        if isinstance(user_injuries, str):
            try:
                user_injuries = json.loads(user_injuries)
            except json.JSONDecodeError:
                user_injuries = []

        # Get most recent regeneration for latest selections
        latest_regen = db.get_latest_user_regeneration(user_id)

        # Helper to safely parse list fields (may be JSON strings or actual lists)
        def safe_list(value, default=None):
            if default is None:
                default = []
            if value is None:
                return default
            if isinstance(value, list):
                return value
            if isinstance(value, str):
                try:
                    parsed = json.loads(value)
                    return parsed if isinstance(parsed, list) else default
                except json.JSONDecodeError:
                    return default
            return default

        # Build response - latest regeneration takes precedence
        result = ProgramPreferences(
            difficulty=latest_regen.get("selected_difficulty") if latest_regen else base_prefs.get("intensity_preference"),
            duration_minutes=latest_regen.get("selected_duration_minutes") if latest_regen else base_prefs.get("workout_duration"),
            workout_type=latest_regen.get("selected_workout_type") if latest_regen else base_prefs.get("training_split"),
            training_split=base_prefs.get("training_split"),
            workout_days=_get_workout_days(base_prefs, latest_regen),
            equipment=safe_list(latest_regen.get("selected_equipment")) if latest_regen else user_equipment,
            focus_areas=safe_list(latest_regen.get("selected_focus_areas")) if latest_regen else [],
            injuries=safe_list(latest_regen.get("selected_injuries")) if latest_regen else user_injuries,
            last_updated=latest_regen.get("created_at") if latest_regen else user_row.get("updated_at"),
            dumbbell_count=base_prefs.get("dumbbell_count", 2),
            kettlebell_count=base_prefs.get("kettlebell_count", 2),
            workout_environment=base_prefs.get("workout_environment"),
        )

        logger.info(f"Program preferences fetched for user {user_id}")
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get program preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


def _get_workout_days(base_prefs: dict, latest_regen: Optional[dict]) -> List[str]:
    """Extract workout days from preferences or regeneration data."""
    day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    # Check latest regeneration first (if it has workout_days)
    if latest_regen and latest_regen.get("selected_workout_days"):
        selected_days = latest_regen["selected_workout_days"]
        if isinstance(selected_days, list):
            # Could be indices or day names
            if selected_days and isinstance(selected_days[0], int):
                return [day_names[i] for i in selected_days if 0 <= i < 7]
            elif selected_days and isinstance(selected_days[0], str):
                return selected_days

    # Check base preferences - try multiple key names for compatibility
    # Try "workout_days" first (Flutter app uses this)
    workout_days = base_prefs.get("workout_days", [])
    if workout_days:
        if isinstance(workout_days, list):
            # Could be indices or day names
            if workout_days and isinstance(workout_days[0], int):
                return [day_names[i] for i in workout_days if 0 <= i < 7]
            elif workout_days and isinstance(workout_days[0], str):
                return workout_days

    # Try "selected_days" as fallback
    selected_days = base_prefs.get("selected_days", [])
    if selected_days:
        if isinstance(selected_days, list):
            if selected_days and isinstance(selected_days[0], int):
                return [day_names[i] for i in selected_days if 0 <= i < 7]
            elif selected_days and isinstance(selected_days[0], str):
                return selected_days

    # Fall back to days_per_week and generate default days
    days_per_week = base_prefs.get("days_per_week", 3)

    # Default: spread days evenly across the week
    if days_per_week == 2:
        return ["Mon", "Thu"]
    elif days_per_week == 3:
        return ["Mon", "Wed", "Fri"]
    elif days_per_week == 4:
        return ["Mon", "Tue", "Thu", "Fri"]
    elif days_per_week == 5:
        return ["Mon", "Tue", "Wed", "Thu", "Fri"]
    elif days_per_week == 6:
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    elif days_per_week == 7:
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    else:
        return ["Mon", "Wed", "Fri"]


@router.put("/{user_id}", response_model=User)
async def update_user(user_id: str, user: UserUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating user: id={user_id}")
    # DEBUG: Log incoming data
    logger.info(f"🔍 [DEBUG] Incoming user data:")
    logger.info(f"🔍 [DEBUG] preferences: {user.preferences}")
    logger.info(f"🔍 [DEBUG] equipment: {user.equipment}")
    logger.info(f"🔍 [DEBUG] goals: {user.goals}")
    try:
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for update: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Build update data
        update_data = {}

        if user.fitness_level is not None:
            update_data["fitness_level"] = user.fitness_level
        if user.goals is not None:
            update_data["goals"] = json.loads(user.goals) if isinstance(user.goals, str) else user.goals
        if user.equipment is not None:
            update_data["equipment"] = json.loads(user.equipment) if isinstance(user.equipment, str) else user.equipment
        if user.custom_equipment is not None:
            update_data["custom_equipment"] = json.loads(user.custom_equipment) if isinstance(user.custom_equipment, str) else user.custom_equipment
            logger.info(f"Updating custom_equipment for user {user_id}")
        if user.active_injuries is not None:
            update_data["active_injuries"] = json.loads(user.active_injuries) if isinstance(user.active_injuries, str) else user.active_injuries
        if user.onboarding_completed is not None:
            update_data["onboarding_completed"] = user.onboarding_completed
            # Set timestamp when onboarding is marked as completed
            if user.onboarding_completed:
                from datetime import datetime, timezone
                update_data["onboarding_completed_at"] = datetime.now(timezone.utc).isoformat()
        if user.coach_selected is not None:
            update_data["coach_selected"] = user.coach_selected
        if user.paywall_completed is not None:
            update_data["paywall_completed"] = user.paywall_completed

        # Handle extended onboarding fields - merge into preferences
        has_extended_fields = any([
            user.days_per_week, user.workout_duration, user.training_split,
            user.intensity_preference, user.preferred_time,
            user.progression_pace, user.workout_type_preference,
            user.workout_environment, user.gym_name, user.workout_variety
        ])

        if user.preferences is not None or has_extended_fields:
            current_prefs = existing.get("preferences", {})
            final_preferences = merge_extended_fields_into_preferences(
                user.preferences if user.preferences else current_prefs,
                user.days_per_week,
                user.workout_duration,
                user.training_split,
                user.intensity_preference,
                user.preferred_time,
                user.progression_pace,
                user.workout_type_preference,
                user.workout_environment,
                user.gym_name,
                workout_variety=user.workout_variety,
            )
            update_data["preferences"] = final_preferences
            logger.info(f"🔍 [DEBUG] Final preferences to save: {final_preferences}")

        # Handle personal/health fields
        if user.name is not None:
            update_data["name"] = user.name
        if user.gender is not None:
            update_data["gender"] = user.gender
        if user.age is not None:
            update_data["age"] = user.age
        if user.date_of_birth is not None:
            update_data["date_of_birth"] = user.date_of_birth
        if user.height_cm is not None:
            update_data["height_cm"] = user.height_cm
        if user.weight_kg is not None:
            update_data["weight_kg"] = user.weight_kg
        if user.target_weight_kg is not None:
            update_data["target_weight_kg"] = user.target_weight_kg
        if user.activity_level is not None:
            update_data["activity_level"] = user.activity_level

        # Handle weight unit preference (kg or lbs)
        if user.weight_unit is not None:
            update_data["weight_unit"] = user.weight_unit
            logger.info(f"Updating weight_unit for user {user_id}: {user.weight_unit}")

        # Handle body measurement unit preference (cm or in)
        if user.measurement_unit is not None:
            update_data["measurement_unit"] = user.measurement_unit
            logger.info(f"Updating measurement_unit for user {user_id}: {user.measurement_unit}")

        # Handle FCM token and device platform for push notifications
        if user.fcm_token is not None:
            update_data["fcm_token"] = user.fcm_token
            logger.info(f"Updating FCM token for user {user_id}")

        if user.device_platform is not None:
            update_data["device_platform"] = user.device_platform
            logger.info(f"Updating device platform for user {user_id}: {user.device_platform}")

        # Handle device info fields
        if user.device_model is not None:
            update_data["device_model"] = user.device_model
        if user.is_foldable is not None:
            update_data["is_foldable"] = user.is_foldable
        if user.os_version is not None:
            update_data["os_version"] = user.os_version
        if user.screen_width is not None:
            update_data["screen_width"] = user.screen_width
        if user.screen_height is not None:
            update_data["screen_height"] = user.screen_height

        # Auto-set last_device_update when any device field is present
        has_device_fields = any([
            user.device_model is not None,
            user.device_platform is not None,
            user.is_foldable is not None,
            user.os_version is not None,
            user.screen_width is not None,
            user.screen_height is not None,
        ])
        if has_device_fields:
            from datetime import datetime as dt, timezone as tz
            update_data["last_device_update"] = dt.now(tz.utc).isoformat()
            logger.info(f"Updating device info for user {user_id}: model={user.device_model}, foldable={user.is_foldable}")

        # Handle notification preferences
        if user.notification_preferences is not None:
            # Merge with existing notification preferences if any
            existing_notif_prefs = existing.get("notification_preferences", {})
            if isinstance(existing_notif_prefs, str):
                try:
                    existing_notif_prefs = json.loads(existing_notif_prefs)
                except json.JSONDecodeError:
                    existing_notif_prefs = {}

            # Merge the new preferences with existing
            merged_prefs = {**existing_notif_prefs, **user.notification_preferences}
            update_data["notification_preferences"] = merged_prefs
            logger.info(f"Updating notification preferences for user {user_id}")

        # Handle detailed equipment with quantities and weights
        if user.equipment_details is not None:
            update_data["equipment_details"] = user.equipment_details
            logger.info(f"Updating equipment_details for user {user_id}: {len(user.equipment_details)} items")

        # Handle bio field
        if user.bio is not None:
            update_data["bio"] = user.bio

        # Handle primary training goal
        if user.primary_goal is not None:
            update_data["primary_goal"] = user.primary_goal
            logger.info(f"Updating primary_goal for user {user_id}: {user.primary_goal}")

        # Handle muscle focus points (validate max 5 points)
        if user.muscle_focus_points is not None:
            total_points = sum(user.muscle_focus_points.values()) if user.muscle_focus_points else 0
            if total_points > 5:
                raise HTTPException(
                    status_code=400,
                    detail=f"Muscle focus points cannot exceed 5. Current total: {total_points}"
                )
            update_data["muscle_focus_points"] = user.muscle_focus_points
            logger.info(f"Updating muscle_focus_points for user {user_id}: {user.muscle_focus_points}")

        logger.info(f"🔍 [DEBUG] Final update_data to save: {update_data}")
        if update_data:
            updated = db.update_user(user_id, update_data)
            logger.debug(f"Updated {len(update_data)} fields for user {user_id}")

            # NEW: Create gym profile(s) when onboarding is completed
            if user.onboarding_completed and update_data.get("onboarding_completed"):
                # Fetch fresh user data to get equipment saved by the preferences endpoint
                # (equipment is saved in a separate prior request, not in this update_data)
                try:
                    user_row = db.client.table("users").select(
                        "equipment, equipment_details, preferences"
                    ).eq("id", user_id).single().execute().data
                except Exception:
                    user_row = {}

                db_equipment = user_row.get("equipment") or []
                if isinstance(db_equipment, str):
                    try:
                        db_equipment = json.loads(db_equipment)
                    except (json.JSONDecodeError, TypeError):
                        db_equipment = []
                db_equipment_details = user_row.get("equipment_details") or []
                if isinstance(db_equipment_details, str):
                    try:
                        db_equipment_details = json.loads(db_equipment_details)
                    except (json.JSONDecodeError, TypeError):
                        db_equipment_details = []
                db_prefs = user_row.get("preferences") or {}
                if isinstance(db_prefs, str):
                    try:
                        db_prefs = json.loads(db_prefs)
                    except (json.JSONDecodeError, TypeError):
                        db_prefs = {}

                prefs = update_data.get("preferences", {}) or db_prefs

                try:
                    logger.info(f"🏋️ [GymProfile] Onboarding completed - preferences: {prefs}")
                    logger.info(f"🏋️ [GymProfile] Equipment (from DB): {db_equipment}")
                    logger.info(f"🏋️ [GymProfile] Equipment details: {len(db_equipment_details)} items")

                    await create_gym_profiles_from_onboarding(
                        user_id=user_id,
                        gym_name=prefs.get("gym_name"),
                        workout_environment=prefs.get("workout_environment") or db_prefs.get("workout_environment"),
                        equipment=db_equipment,
                        equipment_details=db_equipment_details,
                        preferences=prefs if prefs else db_prefs,
                    )
                    logger.info(f"🏋️ [GymProfile] ✅ Created gym profile(s) for user {user_id} during onboarding")
                except Exception as gym_error:
                    logger.error(f"⚠️ [GymProfile] Failed to create gym profiles during onboarding: {gym_error}", exc_info=True)
                    import traceback
                    logger.error(f"⚠️ [GymProfile] Traceback: {traceback.format_exc()}", exc_info=True)
                    # Don't fail onboarding if gym profile creation fails

                # Index preferences to ChromaDB for AI
                try:
                    from services.rag_service import WorkoutRAGService
                    from services.gemini_service import GeminiService

                    gemini_service = GeminiService()
                    rag_service = WorkoutRAGService(gemini_service)

                    # Parse goals from update_data (stored as JSON string)
                    goals_data = update_data.get("goals")
                    if isinstance(goals_data, str):
                        try:
                            goals_data = json.loads(goals_data)
                        except json.JSONDecodeError:
                            goals_data = [goals_data] if goals_data else []

                    await rag_service.index_program_preferences(
                        user_id=user_id,
                        difficulty=prefs.get("intensity_preference"),
                        duration_minutes=prefs.get("workout_duration"),
                        workout_type=prefs.get("training_split"),
                        workout_days=prefs.get("workout_days"),
                        equipment=db_equipment,
                        focus_areas=prefs.get("focus_areas"),
                        injuries=update_data.get("active_injuries", []),
                        goals=goals_data if isinstance(goals_data, list) else None,
                        motivations=prefs.get("motivations"),
                        dumbbell_count=prefs.get("dumbbell_count"),
                        kettlebell_count=prefs.get("kettlebell_count"),
                        training_experience=prefs.get("training_experience"),
                        workout_environment=prefs.get("workout_environment") or db_prefs.get("workout_environment"),
                        change_reason="onboarding_completed",
                    )
                    logger.info(f"📊 Indexed onboarding preferences to ChromaDB for user {user_id}")
                except Exception as rag_error:
                    logger.warning(f"⚠️ Could not index preferences to ChromaDB: {rag_error}", exc_info=True)

            # Index training settings changes to ChromaDB for AI context
            has_training_settings = any([
                user.progression_pace, user.workout_type_preference, user.training_split
            ])
            if has_training_settings:
                try:
                    from services.rag_service import WorkoutRAGService
                    from services.gemini_service import GeminiService

                    gemini_service = GeminiService()
                    rag_service = WorkoutRAGService(gemini_service)

                    await rag_service.index_training_settings(
                        user_id=user_id,
                        action="update_training_preferences",
                        progression_pace=user.progression_pace,
                        training_split=user.training_split,
                        workout_type=user.workout_type_preference,
                    )
                    logger.info(f"📊 Indexed training settings to ChromaDB for user {user_id}")
                except Exception as rag_error:
                    logger.warning(f"⚠️ Could not index training settings to ChromaDB: {rag_error}", exc_info=True)

            # Index exercise variety/consistency settings to ChromaDB for AI context
            prefs = update_data.get("preferences", {})
            if isinstance(prefs, str):
                prefs = json.loads(prefs)

            has_exercise_variety_settings = any([
                prefs.get("exercise_consistency"),
                prefs.get("variation_percentage") is not None,
            ])

            if has_exercise_variety_settings:
                try:
                    from services.rag_service import WorkoutRAGService
                    from services.gemini_service import GeminiService

                    gemini_service = GeminiService()
                    rag_service = WorkoutRAGService(gemini_service)

                    await rag_service.index_training_settings(
                        user_id=user_id,
                        action="update_exercise_variety",
                        exercise_consistency=prefs.get("exercise_consistency"),
                        variation_percentage=prefs.get("variation_percentage"),
                    )
                    logger.info(f"📊 Indexed exercise variety settings to ChromaDB for user {user_id}")
                except Exception as rag_error:
                    logger.warning(f"⚠️ Could not index exercise variety settings to ChromaDB: {rag_error}", exc_info=True)
        else:
            updated = existing

        logger.info(f"User updated: id={user_id}")

        # Log user update
        await log_user_activity(
            user_id=user_id,
            action="user_updated",
            endpoint=f"/api/v1/users/{user_id}",
            message="User profile updated",
            metadata={"fields_updated": list(update_data.keys())},
            status_code=200
        )

        return row_to_user(updated)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update user: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="user_updated",
            error=e,
            endpoint=f"/api/v1/users/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}")
async def delete_user(user_id: str,
    body: DestructiveActionRequest,
    current_user: dict = Depends(get_current_user),
):
    """Delete a user. SECURITY: Requires password re-authentication."""
    logger.info(f"Deleting user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)

        # SECURITY: Re-authenticate before destructive action
        supabase = get_supabase()
        try:
            supabase.auth_client.auth.sign_in_with_password({
                "email": current_user["email"],
                "password": body.password,
            })
        except Exception:
            raise HTTPException(status_code=401, detail="Invalid password — re-authentication required")

        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for deletion: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        db.delete_user(user_id)
        logger.info(f"User deleted: id={user_id}")

        # Log user deletion
        await log_user_activity(
            user_id=user_id,
            action="user_deleted",
            endpoint=f"/api/v1/users/{user_id}",
            message="User account deleted",
            status_code=200
        )

        return {"message": "User deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete user: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="user_deleted",
            error=e,
            endpoint=f"/api/v1/users/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/reset-onboarding")
async def reset_onboarding(user_id: str,
    body: DestructiveActionRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Reset onboarding - clears workouts and resets onboarding status.
    SECURITY: Requires password re-authentication.
    """
    logger.info(f"Resetting onboarding for user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)

        # SECURITY: Re-authenticate before destructive action
        supabase = get_supabase()
        try:
            supabase.auth_client.auth.sign_in_with_password({
                "email": current_user["email"],
                "password": body.password,
            })
        except Exception:
            raise HTTPException(status_code=401, detail="Invalid password — re-authentication required")

        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for onboarding reset: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Get workout IDs first
        workouts = db.list_workouts(user_id, limit=1000)
        workout_ids = [w["id"] for w in workouts]

        # Get workout_log IDs
        logs = db.list_workout_logs(user_id, limit=1000)
        log_ids = [log["id"] for log in logs]

        # Delete performance_logs by workout_log IDs
        for log_id in log_ids:
            db.delete_performance_logs_by_workout_log(log_id)

        # Delete workout_logs
        db.delete_workout_logs_by_user(user_id)

        # Delete workout_changes by workout IDs
        for workout_id in workout_ids:
            db.delete_workout_changes_by_workout(workout_id)

        # Delete workouts
        for workout_id in workout_ids:
            db.delete_workout(workout_id)

        # Delete achievements and streaks
        try:
            db.client.table("user_achievements").delete().eq("user_id", user_id).execute()
            db.client.table("user_streaks").delete().eq("user_id", user_id).execute()
        except Exception as e:
            logger.warning(f"Could not delete achievements/streaks: {e}", exc_info=True)

        # Reset onboarding status
        db.update_user(user_id, {
            "onboarding_completed": False,
            "onboarding_conversation": None,
            "onboarding_conversation_completed_at": None
        })

        logger.info(f"Onboarding reset complete for user {user_id}")

        # Return updated user
        updated_user = db.get_user(user_id)
        return row_to_user(updated_user)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to reset onboarding: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}/reset")
async def full_reset(user_id: str,
    body: DestructiveActionRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Full reset - delete ALL user data and return to fresh state.
    SECURITY: Requires password re-authentication.

    This deletes (in order to respect FK constraints):
    1. performance_logs (via workout_logs)
    2. workout_logs
    3. workout_changes
    4. workouts
    5. strength_records
    6. weekly_volumes
    7. injuries
    8. injury_history
    9. user_metrics
    10. chat_history
    11. user record itself
    """
    logger.info(f"Full reset for user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)

        # SECURITY: Re-authenticate before destructive action
        # For OAuth users (Google), password is not available — JWT auth is sufficient
        auth_provider = current_user.get("app_metadata", {}).get("provider", "email")
        if auth_provider == "email":
            if not body.password:
                raise HTTPException(status_code=400, detail="Password required for email accounts")
            supabase = get_supabase()
            try:
                supabase.auth_client.auth.sign_in_with_password({
                    "email": current_user["email"],
                    "password": body.password,
                })
            except Exception:
                raise HTTPException(status_code=401, detail="Invalid password — re-authentication required")
        # For OAuth providers (google, apple, etc.), JWT auth via get_current_user() is sufficient

        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for reset: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Use the full reset method from supabase_db
        db.full_user_reset(user_id)
        logger.info(f"Full reset complete for user {user_id}")

        return {
            "message": "Full reset successful. All user data has been deleted.",
            "user_id": user_id
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to reset user: {e}", exc_info=True)
        raise safe_internal_error(e, "users")
