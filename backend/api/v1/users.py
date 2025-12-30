"""
User API endpoints.

ENDPOINTS:
- POST /api/v1/users/auth/google - Authenticate with Google OAuth via Supabase
- POST /api/v1/users/ - Create a new user
- GET  /api/v1/users/ - Get all users
- GET  /api/v1/users/{id} - Get user by ID
- GET  /api/v1/users/{id}/program-preferences - Get user's program preferences
- GET  /api/v1/users/{id}/export - Export all user data as ZIP
- POST /api/v1/users/{id}/import - Import user data from ZIP
- PUT  /api/v1/users/{id} - Update user
- DELETE /api/v1/users/{id} - Delete user
- DELETE /api/v1/users/{id}/reset - Full reset (delete all user data)

RATE LIMITS:
- /auth/google: 5 requests/minute (authentication)
- / (POST create): 5 requests/minute
- Other endpoints: default global limit
"""
import json
from datetime import datetime
from fastapi import APIRouter, HTTPException, UploadFile, File, Request
from fastapi.responses import StreamingResponse
from typing import Optional, List
from pydantic import BaseModel
import io

from core.supabase_db import get_supabase_db
from core.supabase_client import get_supabase
from core.logger import get_logger
from core.rate_limiter import limiter
from core.activity_logger import log_user_activity, log_user_error
from models.schemas import User, UserCreate, UserUpdate


class GoogleAuthRequest(BaseModel):
    """Request body for Google OAuth authentication."""
    access_token: str


class ProgramPreferences(BaseModel):
    """User's current program preferences for customization."""
    difficulty: Optional[str] = None
    duration_minutes: Optional[int] = None
    workout_type: Optional[str] = None
    training_split: Optional[str] = None
    workout_days: List[str] = []
    equipment: List[str] = []
    focus_areas: List[str] = []
    injuries: List[str] = []
    last_updated: Optional[str] = None
    dumbbell_count: Optional[int] = None
    kettlebell_count: Optional[int] = None
    workout_environment: Optional[str] = None  # commercial_gym, home_gym, home, outdoors, hotel, etc.

router = APIRouter()
logger = get_logger(__name__)


def row_to_user(row: dict) -> User:
    """Convert a Supabase row dict to User model."""
    # Handle JSONB fields - they come as dicts/lists from Supabase
    goals = row.get("goals")
    if isinstance(goals, list):
        goals = json.dumps(goals)
    elif goals is None:
        goals = "[]"

    equipment = row.get("equipment")
    if isinstance(equipment, list):
        equipment = json.dumps(equipment)
    elif equipment is None:
        equipment = "[]"

    # Get preferences as dict for fallback lookups
    prefs_raw = row.get("preferences")
    prefs_dict = prefs_raw if isinstance(prefs_raw, dict) else {}

    preferences = prefs_raw
    if isinstance(preferences, dict):
        preferences = json.dumps(preferences)
    elif preferences is None:
        preferences = "{}"

    active_injuries = row.get("active_injuries")
    if isinstance(active_injuries, list):
        active_injuries = json.dumps(active_injuries)
    elif active_injuries is None:
        active_injuries = "[]"

    # Helper to get value from column or fall back to preferences JSON
    def get_with_fallback(column_name: str, prefs_key: str = None, default_values: list = None):
        """Get value from dedicated column, or fall back to preferences JSON.

        Args:
            column_name: Name of the database column
            prefs_key: Key in preferences JSON (defaults to column_name)
            default_values: List of values to treat as "not set" (fall back to prefs)
        """
        value = row.get(column_name)
        # If value is None or a default placeholder, try preferences
        if value is None or (default_values and value in default_values):
            pref_value = prefs_dict.get(prefs_key or column_name)
            if pref_value is not None:
                return pref_value
        return value

    return User(
        id=row.get("id"),
        username=row.get("email"),  # Use email as username
        name=row.get("name") or prefs_dict.get("name"),
        email=row.get("email"),  # Include email in response
        onboarding_completed=row.get("onboarding_completed", False),
        coach_selected=row.get("coach_selected", False),
        paywall_completed=row.get("paywall_completed", False),
        fitness_level=row.get("fitness_level", "beginner"),
        goals=goals,
        equipment=equipment,
        preferences=preferences,
        active_injuries=active_injuries,
        created_at=row.get("created_at"),
        # Personal info fields - fall back to preferences JSON if column is empty
        height_cm=get_with_fallback("height_cm"),
        weight_kg=get_with_fallback("weight_kg"),
        target_weight_kg=get_with_fallback("target_weight_kg"),
        age=get_with_fallback("age"),
        date_of_birth=str(get_with_fallback("date_of_birth")) if get_with_fallback("date_of_birth") else None,
        gender=get_with_fallback("gender", default_values=["prefer_not_to_say"]),
        activity_level=get_with_fallback("activity_level", default_values=["lightly_active"]),
        # Detailed equipment with quantities and weights
        equipment_details=row.get("equipment_details"),
    )


@router.post("/auth/google", response_model=User)
@limiter.limit("5/minute")
async def google_auth(request: Request, body: GoogleAuthRequest):
    """
    Authenticate with Google OAuth via Supabase.

    - Verifies the access token with Supabase
    - Gets or creates user in our database
    - Returns user object with onboarding status
    """
    logger.info("Google OAuth authentication attempt")

    try:
        # Verify token with Supabase and get user info
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.client

        # Get user from Supabase using the access token
        user_response = supabase_client.auth.get_user(body.access_token)

        if not user_response or not user_response.user:
            logger.warning("Invalid or expired access token")
            raise HTTPException(status_code=401, detail="Invalid or expired access token")

        supabase_user = user_response.user
        supabase_user_id = supabase_user.id
        email = supabase_user.email
        full_name = supabase_user.user_metadata.get("full_name") or supabase_user.user_metadata.get("name", "")

        logger.info(f"Supabase user verified: id={supabase_user_id}, email={email}")

        db = get_supabase_db()

        # Check if user already exists by auth_id (supabase user id)
        existing = db.get_user_by_auth_id(supabase_user_id)

        if existing:
            logger.info(f"Existing user found: id={existing['id']}")
            return row_to_user(existing)

        # Create new user
        # Note: goals and equipment are VARCHAR columns, not JSONB,
        # so we need to pass them as JSON strings
        new_user_data = {
            "auth_id": supabase_user_id,
            "email": email,
            "name": full_name,
            "onboarding_completed": False,
            "fitness_level": "beginner",
            "goals": "[]",  # VARCHAR column - needs JSON string
            "equipment": "[]",  # VARCHAR column - needs JSON string
            "preferences": {"name": full_name, "email": email},  # JSONB - can be dict
            "active_injuries": [],  # JSONB - can be list
        }

        created = db.create_user(new_user_data)
        logger.info(f"New user created via Google OAuth: id={created['id']}, email={email}")

        return row_to_user(created)

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        full_traceback = traceback.format_exc()
        logger.error(f"Google auth failed: {e}")
        logger.error(f"Full traceback: {full_traceback}")
        raise HTTPException(status_code=500, detail=f"Google auth error: {str(e)}")


def merge_extended_fields_into_preferences(
    base_preferences: str,
    days_per_week: Optional[int],
    workout_duration: Optional[int],
    training_split: Optional[str],
    intensity_preference: Optional[str],
    preferred_time: Optional[str],
    progression_pace: Optional[str] = None,
    workout_type_preference: Optional[str] = None,
    workout_environment: Optional[str] = None,
) -> dict:
    """Merge extended onboarding fields into preferences dict."""
    try:
        if isinstance(base_preferences, dict):
            prefs = base_preferences
        else:
            prefs = json.loads(base_preferences or "{}")
    except json.JSONDecodeError:
        prefs = {}

    if days_per_week is not None:
        prefs["days_per_week"] = days_per_week
    if workout_duration is not None:
        prefs["workout_duration"] = workout_duration
    if training_split is not None:
        prefs["training_split"] = training_split
    if intensity_preference is not None:
        prefs["intensity_preference"] = intensity_preference
    if preferred_time is not None:
        prefs["preferred_time"] = preferred_time
    # New preferences for competitor feedback fixes
    if progression_pace is not None:
        prefs["progression_pace"] = progression_pace
    if workout_type_preference is not None:
        prefs["workout_type_preference"] = workout_type_preference
    if workout_environment is not None:
        prefs["workout_environment"] = workout_environment

    return prefs


@router.post("/", response_model=User)
@limiter.limit("5/minute")
async def create_user(request: Request, user: UserCreate):
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
        logger.error(f"Failed to create user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/", response_model=List[User])
async def get_all_users():
    """Get all users."""
    logger.info("Fetching all users")
    try:
        db = get_supabase_db()
        rows = db.get_all_users()
        return [row_to_user(row) for row in rows]
    except Exception as e:
        logger.error(f"Failed to get users: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str):
    """Get a user by ID."""
    logger.info(f"Fetching user: id={user_id}")
    try:
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
        logger.error(f"Failed to get user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/program-preferences", response_model=ProgramPreferences)
async def get_program_preferences(user_id: str):
    """
    Get user's current program preferences for the customize program sheet.

    Merges preferences from:
    1. users.preferences JSONB (base preferences)
    2. Most recent workout_regenerations entry (latest selections)

    Returns unified preferences for pre-populating the edit form.
    """
    logger.info(f"Fetching program preferences for user: id={user_id}")
    try:
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
        logger.error(f"Failed to get program preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
async def update_user(user_id: str, user: UserUpdate):
    """Update a user."""
    logger.info(f"Updating user: id={user_id}")
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
        if user.coach_selected is not None:
            update_data["coach_selected"] = user.coach_selected
        if user.paywall_completed is not None:
            update_data["paywall_completed"] = user.paywall_completed

        # Handle extended onboarding fields - merge into preferences
        has_extended_fields = any([
            user.days_per_week, user.workout_duration, user.training_split,
            user.intensity_preference, user.preferred_time,
            user.progression_pace, user.workout_type_preference,
            user.workout_environment
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
            )
            update_data["preferences"] = final_preferences

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

        # Handle FCM token and device platform for push notifications
        if user.fcm_token is not None:
            update_data["fcm_token"] = user.fcm_token
            logger.info(f"Updating FCM token for user {user_id}")

        if user.device_platform is not None:
            update_data["device_platform"] = user.device_platform
            logger.info(f"Updating device platform for user {user_id}: {user.device_platform}")

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

        if update_data:
            updated = db.update_user(user_id, update_data)
            logger.debug(f"Updated {len(update_data)} fields for user {user_id}")

            # If onboarding was just completed, index preferences to ChromaDB for AI
            if user.onboarding_completed and update_data.get("onboarding_completed"):
                try:
                    from services.rag_service import WorkoutRAGService
                    from services.gemini_service import GeminiService
                    from core.config import get_settings

                    settings = get_settings()
                    gemini_service = GeminiService(settings)
                    rag_service = WorkoutRAGService(gemini_service)

                    # Get preferences from the update
                    prefs = update_data.get("preferences", {})
                    if isinstance(prefs, str):
                        # json is already imported at module level
                        prefs = json.loads(prefs)

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
                        equipment=update_data.get("equipment", []),
                        focus_areas=prefs.get("focus_areas"),
                        injuries=update_data.get("active_injuries", []),
                        goals=goals_data if isinstance(goals_data, list) else None,
                        motivations=prefs.get("motivations"),
                        dumbbell_count=prefs.get("dumbbell_count"),
                        kettlebell_count=prefs.get("kettlebell_count"),
                        training_experience=prefs.get("training_experience"),
                        workout_environment=prefs.get("workout_environment"),
                        change_reason="onboarding_completed",
                    )
                    logger.info(f"📊 Indexed onboarding preferences to ChromaDB for user {user_id}")
                except Exception as rag_error:
                    logger.warning(f"⚠️ Could not index preferences to ChromaDB: {rag_error}")
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
        logger.error(f"Failed to update user: {e}")
        await log_user_error(
            user_id=user_id,
            action="user_updated",
            error=e,
            endpoint=f"/api/v1/users/{user_id}",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}")
async def delete_user(user_id: str):
    """Delete a user."""
    logger.info(f"Deleting user: id={user_id}")
    try:
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
        logger.error(f"Failed to delete user: {e}")
        await log_user_error(
            user_id=user_id,
            action="user_deleted",
            error=e,
            endpoint=f"/api/v1/users/{user_id}",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/reset-onboarding")
async def reset_onboarding(user_id: str):
    """
    Reset onboarding - clears workouts and resets onboarding status.

    This allows the user to go through onboarding again without
    deleting their account.
    """
    logger.info(f"Resetting onboarding for user: id={user_id}")
    try:
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
            logger.warning(f"Could not delete achievements/streaks: {e}")

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
        logger.error(f"Failed to reset onboarding: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/reset")
async def full_reset(user_id: str):
    """
    Full reset - delete ALL user data and return to fresh state.

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
        logger.error(f"Failed to reset user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== DATA EXPORT/IMPORT ====================


@router.get("/{user_id}/export")
async def export_user_data(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
):
    """
    Export all user data as a ZIP file containing CSV files.

    Query parameters:
    - start_date: Optional ISO date string (YYYY-MM-DD) for filtering data from this date
    - end_date: Optional ISO date string (YYYY-MM-DD) for filtering data until this date

    The ZIP contains:
    - profile.csv - User profile and settings
    - body_metrics.csv - Historical body measurements
    - workouts.csv - All workout plans
    - workout_logs.csv - Completed workout sessions
    - exercise_sets.csv - Per-set performance data
    - strength_records.csv - Personal records
    - achievements.csv - Earned achievements
    - streaks.csv - Streak history
    - _metadata.csv - Export metadata for import validation
    """
    import time
    start_time = time.time()
    logger.info(f"🔄 Starting data export for user: id={user_id}, date_range={start_date} to {end_date}")

    try:
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for export: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        logger.info(f"✅ User verified, generating export...")

        # Import here to avoid circular imports
        from services.data_export import export_user_data as do_export

        # Generate ZIP file with date filters
        zip_bytes = do_export(user_id, start_date=start_date, end_date=end_date)

        # Create filename with date
        date_str = datetime.utcnow().strftime("%Y-%m-%d")
        filename = f"fitness_data_{date_str}.zip"

        elapsed = time.time() - start_time
        logger.info(f"✅ Data export complete for user {user_id} in {elapsed:.2f}s, size: {len(zip_bytes)} bytes")

        # Return as streaming response
        return StreamingResponse(
            io.BytesIO(zip_bytes),
            media_type="application/zip",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
                "Content-Length": str(len(zip_bytes)),
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        elapsed = time.time() - start_time
        logger.error(f"❌ Failed to export user data after {elapsed:.2f}s: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/import")
async def import_user_data(user_id: str, file: UploadFile = File(...)):
    """
    Import user data from a previously exported ZIP file.

    This will:
    1. Validate the ZIP structure and metadata
    2. Parse all CSV files
    3. Import data with new IDs (preserving relationships)
    4. Update user profile with imported settings

    WARNING: This may replace existing data. Use with caution.
    """
    logger.info(f"Importing data for user: id={user_id}, filename={file.filename}")
    try:
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for import: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Validate file type
        if not file.filename.endswith('.zip'):
            raise HTTPException(status_code=400, detail="File must be a ZIP archive")

        # Read file content
        content = await file.read()
        if len(content) > 50 * 1024 * 1024:  # 50MB limit
            raise HTTPException(status_code=400, detail="File too large. Maximum size is 50MB.")

        # Import here to avoid circular imports
        from services.data_import import import_user_data as do_import

        # Perform import
        result = do_import(user_id, content)

        logger.info(f"Data import complete for user {user_id}: {result}")

        return {
            "message": "Data import successful",
            "user_id": user_id,
            "imported": result
        }

    except HTTPException:
        raise
    except ValueError as e:
        logger.error(f"Import validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to import user data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# FAVORITE EXERCISES ENDPOINTS
# =============================================================================

class FavoriteExerciseRequest(BaseModel):
    """Request body for adding a favorite exercise."""
    exercise_name: str
    exercise_id: Optional[str] = None


class FavoriteExercise(BaseModel):
    """Response model for a favorite exercise."""
    id: str
    user_id: str
    exercise_name: str
    exercise_id: Optional[str] = None
    added_at: str


@router.get("/{user_id}/favorite-exercises", response_model=List[FavoriteExercise])
async def get_favorite_exercises(user_id: str):
    """Get all favorite exercises for a user.

    Used by the workout generation system to prioritize exercises
    the user prefers. Addresses competitor feedback about favoriting
    exercises not helping with AI selection.
    """
    logger.info(f"Getting favorite exercises for user: {user_id}")
    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get favorites
        result = db.client.table("favorite_exercises").select("*").eq(
            "user_id", user_id
        ).order("added_at", desc=True).execute()

        favorites = []
        for row in result.data:
            favorites.append(FavoriteExercise(
                id=row["id"],
                user_id=row["user_id"],
                exercise_name=row["exercise_name"],
                exercise_id=row.get("exercise_id"),
                added_at=row["added_at"],
            ))

        logger.info(f"Found {len(favorites)} favorite exercises for user {user_id}")
        return favorites

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get favorite exercises: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/favorite-exercises", response_model=FavoriteExercise)
async def add_favorite_exercise(user_id: str, request: FavoriteExerciseRequest):
    """Add an exercise to user's favorites.

    Favorited exercises get a 50% boost in similarity score during
    workout generation, making them more likely to be selected.
    """
    logger.info(f"Adding favorite exercise for user {user_id}: {request.exercise_name}")
    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Check if already favorited
        existing = db.client.table("favorite_exercises").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="Exercise is already in favorites"
            )

        # Add to favorites
        result = db.client.table("favorite_exercises").insert({
            "user_id": user_id,
            "exercise_name": request.exercise_name,
            "exercise_id": request.exercise_id,
        }).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to add favorite")

        row = result.data[0]
        logger.info(f"Added favorite exercise: {request.exercise_name} for user {user_id}")

        return FavoriteExercise(
            id=row["id"],
            user_id=row["user_id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            added_at=row["added_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add favorite exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/favorite-exercises/{exercise_name}")
async def remove_favorite_exercise(user_id: str, exercise_name: str):
    """Remove an exercise from user's favorites.

    The exercise_name is URL-encoded, so spaces become %20.
    """
    # URL decode the exercise name
    from urllib.parse import unquote
    decoded_name = unquote(exercise_name)

    logger.info(f"Removing favorite exercise for user {user_id}: {decoded_name}")
    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Delete the favorite
        result = db.client.table("favorite_exercises").delete().eq(
            "user_id", user_id
        ).eq("exercise_name", decoded_name).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Favorite not found")

        logger.info(f"Removed favorite exercise: {decoded_name} for user {user_id}")

        return {"message": "Favorite removed successfully", "exercise_name": decoded_name}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove favorite exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# EXERCISE QUEUE ENDPOINTS
# =============================================================================

class QueueExerciseRequest(BaseModel):
    """Request body for queuing an exercise."""
    exercise_name: str
    exercise_id: Optional[str] = None
    priority: Optional[int] = 0
    target_muscle_group: Optional[str] = None


class QueuedExercise(BaseModel):
    """Response model for a queued exercise."""
    id: str
    user_id: str
    exercise_name: str
    exercise_id: Optional[str] = None
    priority: int
    target_muscle_group: Optional[str] = None
    added_at: str
    expires_at: str
    used_at: Optional[str] = None


@router.get("/{user_id}/exercise-queue", response_model=List[QueuedExercise])
async def get_exercise_queue(user_id: str):
    """Get all queued exercises for a user.

    Only returns active (not expired, not used) exercises.
    Used by the workout generation system to include queued exercises.
    """
    logger.info(f"Getting exercise queue for user: {user_id}")
    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get active queue items (not expired, not used)
        from datetime import datetime
        now = datetime.now().isoformat()

        result = db.client.table("exercise_queue").select("*").eq(
            "user_id", user_id
        ).is_("used_at", "null").gte(
            "expires_at", now
        ).order("priority", desc=False).order("added_at", desc=False).execute()

        queue = []
        for row in result.data:
            queue.append(QueuedExercise(
                id=row["id"],
                user_id=row["user_id"],
                exercise_name=row["exercise_name"],
                exercise_id=row.get("exercise_id"),
                priority=row.get("priority", 0),
                target_muscle_group=row.get("target_muscle_group"),
                added_at=row["added_at"],
                expires_at=row["expires_at"],
                used_at=row.get("used_at"),
            ))

        logger.info(f"Found {len(queue)} queued exercises for user {user_id}")
        return queue

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get exercise queue: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/exercise-queue", response_model=QueuedExercise)
async def add_to_exercise_queue(user_id: str, request: QueueExerciseRequest):
    """Add an exercise to user's workout queue.

    Queued exercises are included in the next matching workout.
    """
    logger.info(f"Adding to exercise queue for user {user_id}: {request.exercise_name}")
    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Check if already queued
        existing = db.client.table("exercise_queue").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).is_("used_at", "null").execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="Exercise is already in queue"
            )

        # Add to queue
        result = db.client.table("exercise_queue").insert({
            "user_id": user_id,
            "exercise_name": request.exercise_name,
            "exercise_id": request.exercise_id,
            "priority": request.priority or 0,
            "target_muscle_group": request.target_muscle_group,
        }).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to add to queue")

        row = result.data[0]
        logger.info(f"Added to queue: {request.exercise_name} for user {user_id}")

        return QueuedExercise(
            id=row["id"],
            user_id=row["user_id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            priority=row.get("priority", 0),
            target_muscle_group=row.get("target_muscle_group"),
            added_at=row["added_at"],
            expires_at=row["expires_at"],
            used_at=row.get("used_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add to exercise queue: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/exercise-queue/{exercise_name}")
async def remove_from_exercise_queue(user_id: str, exercise_name: str):
    """Remove an exercise from user's workout queue."""
    from urllib.parse import unquote
    decoded_name = unquote(exercise_name)

    logger.info(f"Removing from exercise queue for user {user_id}: {decoded_name}")
    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Delete from queue
        result = db.client.table("exercise_queue").delete().eq(
            "user_id", user_id
        ).eq("exercise_name", decoded_name).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found in queue")

        logger.info(f"Removed from queue: {decoded_name} for user {user_id}")

        return {"message": "Removed from queue successfully", "exercise_name": decoded_name}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove from exercise queue: {e}")
        raise HTTPException(status_code=500, detail=str(e))
