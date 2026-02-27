"""
User API endpoints.

ENDPOINTS:
- POST /api/v1/users/auth/google - Authenticate with Google OAuth via Supabase
- POST /api/v1/users/ - Create a new user
- GET  /api/v1/users/ - Get all users
- GET  /api/v1/users/{id} - Get user by ID
- GET  /api/v1/users/{id}/program-preferences - Get user's program preferences
- GET  /api/v1/users/{id}/export - Export all user data as ZIP
- GET  /api/v1/users/{id}/export-text - Export workout logs as plain text
- POST /api/v1/users/{id}/import - Import user data from ZIP
- PUT  /api/v1/users/{id} - Update user
- DELETE /api/v1/users/{id} - Delete user
- DELETE /api/v1/users/{id}/reset - Full reset (delete all user data)

RATE LIMITS:
- /auth/google: 5 requests/minute (authentication)
- / (POST create): 5 requests/minute
- Other endpoints: default global limit
"""
import asyncio
import json
import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException, UploadFile, File, Request, Form
from core.auth import get_current_user, get_verified_auth_token
from core.exceptions import safe_internal_error
from fastapi.responses import StreamingResponse
from typing import Optional, List
from pydantic import BaseModel
import io
import boto3

from core.supabase_db import get_supabase_db
from core.supabase_client import get_supabase
from core.logger import get_logger
from core.rate_limiter import limiter
from core.activity_logger import log_user_activity, log_user_error
from core.username_generator import generate_username_sync
from models.schemas import User, UserCreate, UserUpdate
from services.admin_service import get_admin_service, SUPPORT_EMAIL
from core.config import get_settings


def get_default_equipment_for_environment(environment: str) -> list:
    """
    Returns default equipment for a workout environment.
    The RAG filter expands 'full_gym' and 'home_gym' to full equipment lists.
    """
    if environment == 'commercial_gym':
        return ['full_gym']
    elif environment == 'home_gym':
        return ['home_gym']
    else:
        return ['bodyweight']


class GoogleAuthRequest(BaseModel):
    """Request body for Google OAuth authentication."""
    access_token: str


class EmailAuthRequest(BaseModel):
    """Request body for email/password authentication."""
    email: str
    password: str


class EmailSignupRequest(BaseModel):
    """Request body for email/password signup."""
    email: str
    password: str
    name: Optional[str] = None


class ForgotPasswordRequest(BaseModel):
    """Request body for forgot password."""
    email: str


class ResetPasswordRequest(BaseModel):
    """Request body for password reset."""
    access_token: str
    new_password: str


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


def row_to_user(row: dict, is_new_user: bool = False, support_friend_added: bool = False) -> User:
    """Convert a Supabase row dict to User model.

    Args:
        row: Database row as dict
        is_new_user: True if this is the user's first login (show welcome message)
        support_friend_added: True if FitWiz Support was auto-added as friend
    """
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
    def get_with_fallback(column_name: str, prefs_key: str = None):
        """Get value from dedicated column, or fall back to preferences JSON.

        Args:
            column_name: Name of the database column
            prefs_key: Key in preferences JSON (defaults to column_name)

        Note: Only falls back to preferences if column value is None.
        This ensures explicit user selections in columns are preserved.
        """
        value = row.get(column_name)
        # Only fall back to preferences if value is None (not set)
        # Don't treat default values as "not set" - user may have explicitly chosen them
        if value is None:
            pref_value = prefs_dict.get(prefs_key or column_name)
            if pref_value is not None:
                return pref_value
        return value

    return User(
        id=row.get("id"),
        username=row.get("username"),  # Use actual username field
        name=row.get("name") or prefs_dict.get("name"),
        email=row.get("email"),  # Include email in response
        role=row.get("role", "user"),  # Admin role support
        is_support_user=row.get("is_support_user", False),  # Support user flag
        is_new_user=is_new_user,  # True on first login
        support_friend_added=support_friend_added,  # True when support friend was added
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
        gender=get_with_fallback("gender"),
        activity_level=get_with_fallback("activity_level"),
        # Detailed equipment with quantities and weights
        equipment_details=row.get("equipment_details"),
        # Weight unit preference (kg or lbs)
        weight_unit=row.get("weight_unit") or "kg",
        # Profile photo URL
        photo_url=row.get("photo_url"),
        # Device info fields
        device_model=row.get("device_model"),
        device_platform=row.get("device_platform"),
        is_foldable=row.get("is_foldable", False),
        os_version=row.get("os_version"),
        screen_width=row.get("screen_width"),
        screen_height=row.get("screen_height"),
        last_device_update=row.get("last_device_update"),
    )


@router.post("/auth/google", response_model=User)
@limiter.limit("5/minute")
async def google_auth(request: Request, body: GoogleAuthRequest,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Authenticate with Google OAuth via Supabase.

    - Verifies the access token with Supabase
    - Gets or creates user in our database
    - Returns user object with onboarding status

    Uses get_verified_auth_token (not get_current_user) because new Google
    sign-in users won't have a row in the `users` table yet.
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
        # Generate unique username from name/email
        unique_username = generate_username_sync(name=full_name, email=email)
        logger.info(f"Generated unique username: {unique_username}")

        # Check if this email should be an admin (support@fitwiz.us)
        admin_service = get_admin_service()
        is_admin = admin_service.should_be_admin(email)
        is_support = admin_service.should_be_support_user(email)

        # Note: goals and equipment are VARCHAR columns, not JSONB,
        # so we need to pass them as JSON strings
        new_user_data = {
            "auth_id": supabase_user_id,
            "email": email,
            "name": full_name,
            "username": unique_username,  # Auto-generated unique username
            "role": "admin" if is_admin else "user",
            "is_support_user": is_support,
            "onboarding_completed": False,
            "coach_selected": False,  # Explicitly set for new users to trigger coach selection
            "paywall_completed": False,  # Explicitly set for new users to trigger paywall flow
            "fitness_level": "beginner",
            "goals": "[]",  # VARCHAR column - needs JSON string
            "equipment": "[]",  # VARCHAR column - needs JSON string
            "preferences": {"name": full_name, "email": email},  # JSONB - can be dict
            "active_injuries": [],  # JSONB - can be list
        }

        created = db.create_user(new_user_data)
        logger.info(f"New user created via Google OAuth: id={created['id']}, email={email}, role={created.get('role', 'user')}")

        # Auto-add support user as friend to new users (if support user exists)
        support_friend_added = False
        if not is_support:
            try:
                support_friend_added = await admin_service.add_support_friend_to_user(created['id'])
                if support_friend_added:
                    logger.info(f"Auto-added FitWiz Support as friend for new user {created['id']}")
                    # Send welcome message from support user
                    try:
                        await admin_service.send_welcome_message_to_user(created['id'])
                        logger.info(f"Sent welcome message to new user {created['id']}")
                    except Exception as msg_error:
                        logger.warning(f"Failed to send welcome message: {msg_error}")
            except Exception as friend_error:
                logger.warning(f"Failed to auto-add support friend: {friend_error}")

        return row_to_user(created, is_new_user=True, support_friend_added=support_friend_added)

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        full_traceback = traceback.format_exc()
        logger.error(f"Google auth failed: {e}")
        logger.error(f"Full traceback: {full_traceback}")
        raise safe_internal_error(e, "google_auth")


@router.post("/auth/email", response_model=User)
@limiter.limit("5/minute")
async def email_auth(request: Request, body: EmailAuthRequest,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Authenticate with email and password via Supabase.

    - Signs in with Supabase Auth
    - Gets or creates user in our database
    - Returns user object with onboarding status

    Uses get_verified_auth_token (not get_current_user) because new email
    sign-in users won't have a row in the `users` table yet.
    """
    logger.info(f"Email authentication attempt for: {body.email}")

    try:
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.client

        # Sign in with Supabase Auth
        auth_response = supabase_client.auth.sign_in_with_password({
            "email": body.email,
            "password": body.password,
        })

        if not auth_response or not auth_response.user:
            logger.warning(f"Invalid email or password for: {body.email}")
            raise HTTPException(status_code=401, detail="Invalid email or password")

        supabase_user = auth_response.user
        supabase_user_id = supabase_user.id
        email = supabase_user.email
        full_name = supabase_user.user_metadata.get("full_name") or supabase_user.user_metadata.get("name", "")

        logger.info(f"Supabase user verified: id={supabase_user_id}, email={email}")

        db = get_supabase_db()

        # Check if user already exists by auth_id
        existing = db.get_user_by_auth_id(supabase_user_id)

        if existing:
            logger.info(f"Existing user found: id={existing['id']}")
            return row_to_user(existing)

        # Create new user (rare case - user exists in Supabase Auth but not in our DB)
        unique_username = generate_username_sync(name=full_name, email=email)
        logger.info(f"Generated unique username: {unique_username}")

        # Check if this email should be an admin
        admin_service = get_admin_service()
        is_admin = admin_service.should_be_admin(email)
        is_support = admin_service.should_be_support_user(email)

        new_user_data = {
            "auth_id": supabase_user_id,
            "email": email,
            "name": full_name or "User",
            "username": unique_username,
            "role": "admin" if is_admin else "user",
            "is_support_user": is_support,
            "onboarding_completed": False,
            "coach_selected": False,
            "paywall_completed": False,
            "fitness_level": "beginner",
            "goals": "[]",
            "equipment": "[]",
            "preferences": {"name": full_name, "email": email},
            "active_injuries": [],
        }

        created = db.create_user(new_user_data)
        logger.info(f"New user created via email auth: id={created['id']}, email={email}, role={created.get('role', 'user')}")

        # Auto-add support user as friend to new users
        support_friend_added = False
        if not is_support:
            try:
                support_friend_added = await admin_service.add_support_friend_to_user(created['id'])
                if support_friend_added:
                    logger.info(f"Auto-added FitWiz Support as friend for new user {created['id']}")
                    # Send welcome message from support user
                    try:
                        await admin_service.send_welcome_message_to_user(created['id'])
                        logger.info(f"Sent welcome message to new user {created['id']}")
                    except Exception as msg_error:
                        logger.warning(f"Failed to send welcome message: {msg_error}")
            except Exception as friend_error:
                logger.warning(f"Failed to auto-add support friend: {friend_error}")

        return row_to_user(created, is_new_user=True, support_friend_added=support_friend_added)

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        full_traceback = traceback.format_exc()
        logger.error(f"Email auth failed: {e}")
        logger.error(f"Full traceback: {full_traceback}")
        raise HTTPException(status_code=401, detail="Invalid email or password")


@router.post("/auth/email/signup", response_model=User)
@limiter.limit("5/minute")
async def email_signup(request: Request, body: EmailSignupRequest,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Create a new account with email and password via Supabase.

    - Creates user in Supabase Auth
    - Creates user in our database
    - Returns user object

    Uses get_verified_auth_token (not get_current_user) because signup users
    will never have a row in the `users` table yet.
    """
    logger.info(f"Email signup attempt for: {body.email}")

    try:
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.client

        # Sign up with Supabase Auth
        auth_response = supabase_client.auth.sign_up({
            "email": body.email,
            "password": body.password,
            "options": {
                "data": {
                    "full_name": body.name or "",
                }
            }
        })

        if not auth_response or not auth_response.user:
            logger.warning(f"Signup failed for: {body.email}")
            raise HTTPException(status_code=400, detail="Failed to create account. Email may already be in use.")

        supabase_user = auth_response.user
        supabase_user_id = supabase_user.id
        email = supabase_user.email
        full_name = body.name or ""

        logger.info(f"Supabase user created: id={supabase_user_id}, email={email}")

        db = get_supabase_db()

        # Generate unique username
        unique_username = generate_username_sync(name=full_name, email=email)
        logger.info(f"Generated unique username: {unique_username}")

        # Check if this email should be an admin
        admin_service = get_admin_service()
        is_admin = admin_service.should_be_admin(email)
        is_support = admin_service.should_be_support_user(email)

        new_user_data = {
            "auth_id": supabase_user_id,
            "email": email,
            "name": full_name or "User",
            "username": unique_username,
            "role": "admin" if is_admin else "user",
            "is_support_user": is_support,
            "onboarding_completed": False,
            "coach_selected": False,
            "paywall_completed": False,
            "fitness_level": "beginner",
            "goals": "[]",
            "equipment": "[]",
            "preferences": {"name": full_name, "email": email},
            "active_injuries": [],
        }

        created = db.create_user(new_user_data)
        logger.info(f"New user created via email signup: id={created['id']}, email={email}, role={created.get('role', 'user')}")

        # Auto-add support user as friend to new users
        support_friend_added = False
        if not is_support:
            try:
                support_friend_added = await admin_service.add_support_friend_to_user(created['id'])
                if support_friend_added:
                    logger.info(f"Auto-added FitWiz Support as friend for new user {created['id']}")
                    # Send welcome message from support user
                    try:
                        await admin_service.send_welcome_message_to_user(created['id'])
                        logger.info(f"Sent welcome message to new user {created['id']}")
                    except Exception as msg_error:
                        logger.warning(f"Failed to send welcome message: {msg_error}")
            except Exception as friend_error:
                logger.warning(f"Failed to auto-add support friend: {friend_error}")

        return row_to_user(created, is_new_user=True, support_friend_added=support_friend_added)

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        full_traceback = traceback.format_exc()
        logger.error(f"Email signup failed: {e}")
        logger.error(f"Full traceback: {full_traceback}")
        raise HTTPException(status_code=400, detail=f"Signup failed: {str(e)}")


@router.post("/auth/forgot-password")
@limiter.limit("3/minute")
async def forgot_password(request: Request, body: ForgotPasswordRequest):
    """
    Send password reset email via Supabase.

    No auth required — the user forgot their password and can't authenticate.
    Returns success regardless of whether email exists (security).
    """
    logger.info(f"Password reset requested for: {body.email}")

    try:
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.client

        # Request password reset from Supabase
        # Note: Supabase will send an email with a reset link
        supabase_client.auth.reset_password_for_email(body.email)

        logger.info(f"Password reset email sent to: {body.email}")

        # Always return success for security (don't reveal if email exists)
        return {"message": "If an account exists with this email, a password reset link has been sent."}

    except Exception as e:
        logger.error(f"Password reset failed: {e}")
        # Still return success for security
        return {"message": "If an account exists with this email, a password reset link has been sent."}


@router.post("/auth/reset-password")
@limiter.limit("5/minute")
async def reset_password(request: Request, body: ResetPasswordRequest,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Reset password using the token from reset email.

    Uses get_verified_auth_token (not get_current_user) because the user
    authenticates with a reset token, not a regular session.
    """
    logger.info("Password reset attempt with token")

    try:
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.client

        # Update the user's password using the access token from the reset link
        # The client should have exchanged the reset link for an access token
        user_response = supabase_client.auth.get_user(body.access_token)

        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired reset token")

        # Update password
        supabase_client.auth.update_user({
            "password": body.new_password
        })

        logger.info(f"Password reset successful for user: {user_response.user.email}")
        return {"message": "Password has been reset successfully."}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Password reset failed: {e}")
        raise HTTPException(status_code=400, detail="Failed to reset password. Token may be expired.")


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
    gym_name: Optional[str] = None,
    # Enhanced pre-auth quiz fields
    sleep_quality: Optional[str] = None,
    obstacles: Optional[List[str]] = None,
    dietary_restrictions: Optional[List[str]] = None,
    weight_direction: Optional[str] = None,
    weight_change_amount: Optional[float] = None,
    motivations: Optional[List[str]] = None,
    nutrition_goals: Optional[List[str]] = None,
    interested_in_fasting: Optional[bool] = None,
    fasting_protocol: Optional[str] = None,
    coach_id: Optional[str] = None,
    training_experience: Optional[str] = None,
    workout_days: Optional[List[int]] = None,  # List of day indices [0=Mon, 1=Tue, ..., 6=Sun]
    # Sleep schedule for fasting optimization
    wake_time: Optional[str] = None,
    sleep_time: Optional[str] = None,
    # Duration range for flexible workout generation
    workout_duration_min: Optional[int] = None,
    workout_duration_max: Optional[int] = None,
    # Exercise consistency preference
    workout_variety: Optional[str] = None,  # 'consistent' or 'varied'
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
    # Duration range for flexible workout generation
    if workout_duration_min is not None:
        prefs["workout_duration_min"] = workout_duration_min
    if workout_duration_max is not None:
        prefs["workout_duration_max"] = workout_duration_max
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
    if gym_name is not None:
        prefs["gym_name"] = gym_name
    # Enhanced pre-auth quiz fields
    if sleep_quality is not None:
        prefs["sleep_quality"] = sleep_quality
    if obstacles is not None:
        prefs["obstacles"] = obstacles
    if dietary_restrictions is not None:
        prefs["dietary_restrictions"] = dietary_restrictions
    if weight_direction is not None:
        prefs["weight_direction"] = weight_direction
    if weight_change_amount is not None:
        prefs["weight_change_amount"] = weight_change_amount
    if motivations is not None:
        prefs["motivations"] = motivations
    if nutrition_goals is not None:
        prefs["nutrition_goals"] = nutrition_goals
    if interested_in_fasting is not None:
        prefs["interested_in_fasting"] = interested_in_fasting
    if fasting_protocol is not None:
        prefs["fasting_protocol"] = fasting_protocol
    if coach_id is not None:
        prefs["coach_id"] = coach_id
    if training_experience is not None:
        prefs["training_experience"] = training_experience
    if workout_days is not None:
        prefs["workout_days"] = workout_days
    # Sleep schedule for fasting optimization
    if wake_time is not None:
        prefs["wake_time"] = wake_time
    if sleep_time is not None:
        prefs["sleep_time"] = sleep_time
    # Exercise consistency preference (workout_variety from frontend -> exercise_consistency in backend)
    if workout_variety is not None:
        prefs["exercise_consistency"] = workout_variety

    return prefs


@router.post("/", response_model=User)
@limiter.limit("5/minute")
async def create_user(request: Request, user: UserCreate,
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
        logger.error(f"Failed to create user: {e}")
        raise safe_internal_error(e, "users")


@router.get("/", response_model=List[User])
async def get_all_users(
    current_user: dict = Depends(get_current_user),
):
    """Get all users."""
    logger.info("Fetching all users")
    try:
        db = get_supabase_db()
        rows = db.get_all_users()
        return [row_to_user(row) for row in rows]
    except Exception as e:
        logger.error(f"Failed to get users: {e}")
        raise safe_internal_error(e, "users")


@router.get("/by-auth/{auth_id}", response_model=User)
async def get_user_by_auth(auth_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get a user by their Supabase auth_id.

    This endpoint is used during session restore when we have the Supabase Auth ID
    but need to look up the user's internal database ID.
    """
    logger.info(f"Fetching user by auth_id: {auth_id}")
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
        logger.error(f"Failed to get user by auth_id: {e}")
        raise safe_internal_error(e, "users")


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str,
    current_user: dict = Depends(get_current_user),
):
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


class UserPreferencesRequest(BaseModel):
    """Request body for updating user preferences from pre-auth quiz."""
    # Goals & Fitness
    goals: Optional[List[str]] = None
    fitness_level: Optional[str] = None
    training_experience: Optional[str] = None
    activity_level: Optional[str] = None

    # Body Metrics
    age: Optional[int] = None
    gender: Optional[str] = None  # 'male' or 'female'
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    goal_weight_kg: Optional[float] = None
    weight_direction: Optional[str] = None  # lose, gain, maintain
    weight_change_amount: Optional[float] = None
    weight_change_rate: Optional[str] = None  # slow, moderate, fast, aggressive

    # Schedule
    days_per_week: Optional[int] = None
    selected_days: Optional[List[int]] = None  # List of day indices [0=Mon, 1=Tue, ..., 6=Sun]
    workout_duration: Optional[int] = None  # Duration in minutes (kept for backwards compatibility)
    workout_duration_min: Optional[int] = None  # Min duration in range (e.g., 45 for "45-60")
    workout_duration_max: Optional[int] = None  # Max duration in range (e.g., 60 for "45-60")

    # Equipment
    equipment: Optional[List[str]] = None
    custom_equipment: Optional[List[str]] = None

    # Training Preferences
    training_split: Optional[str] = None
    workout_type: Optional[str] = None
    progression_pace: Optional[str] = None
    workout_environment: Optional[str] = None  # commercial_gym, home_gym, home, outdoors
    workout_variety: Optional[str] = None  # 'consistent' or 'varied'

    # Coach
    coach_id: Optional[str] = None

    # Lifestyle
    sleep_quality: Optional[str] = None
    obstacles: Optional[List[str]] = None

    # Nutrition
    nutrition_goals: Optional[List[str]] = None
    dietary_restrictions: Optional[List[str]] = None

    # Fasting
    interested_in_fasting: Optional[bool] = None
    fasting_protocol: Optional[str] = None

    # Sleep schedule for fasting optimization
    wake_time: Optional[str] = None  # HH:MM format, e.g., "07:00"
    sleep_time: Optional[str] = None  # HH:MM format, e.g., "23:00"

    # Motivations
    motivations: Optional[List[str]] = None

    # Coach
    coach_id: Optional[str] = None


@router.post("/{user_id}/preferences")
async def save_user_preferences(user_id: str, request: UserPreferencesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Save user preferences from pre-auth quiz.

    This endpoint is called after coach selection to persist all quiz data.
    Data is merged into the user's preferences JSON and relevant columns.
    """
    logger.info(f"Saving preferences for user: id={user_id}")
    try:
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for preferences: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Build update data
        update_data = {}

        # Direct column updates
        if request.fitness_level is not None:
            update_data["fitness_level"] = request.fitness_level
        if request.height_cm is not None:
            update_data["height_cm"] = request.height_cm
        if request.weight_kg is not None:
            update_data["weight_kg"] = request.weight_kg
        if request.goal_weight_kg is not None:
            update_data["target_weight_kg"] = request.goal_weight_kg
        if request.activity_level is not None:
            update_data["activity_level"] = request.activity_level
        if request.goals is not None:
            # goals column is VARCHAR, needs JSON string
            update_data["goals"] = json.dumps(request.goals) if isinstance(request.goals, list) else request.goals
        if request.equipment is not None:
            # equipment column is VARCHAR, needs JSON string
            update_data["equipment"] = json.dumps(request.equipment) if isinstance(request.equipment, list) else request.equipment
        if request.custom_equipment is not None:
            # custom_equipment column is VARCHAR, needs JSON string
            update_data["custom_equipment"] = json.dumps(request.custom_equipment) if isinstance(request.custom_equipment, list) else request.custom_equipment
        if request.age is not None:
            update_data["age"] = request.age
        if request.gender is not None:
            update_data["gender"] = request.gender

        # Merge into preferences JSON
        current_prefs = existing.get("preferences", {})
        if isinstance(current_prefs, str):
            try:
                current_prefs = json.loads(current_prefs)
            except json.JSONDecodeError:
                current_prefs = {}

        final_preferences = merge_extended_fields_into_preferences(
            current_prefs,
            request.days_per_week,
            request.workout_duration,
            request.training_split,
            None,  # intensity_preference
            None,  # preferred_time
            request.progression_pace,
            request.workout_type,
            request.workout_environment,  # Where they train: commercial_gym, home_gym, home, outdoors
            None,  # gym_name - not used in this endpoint (quick updates)
            # Enhanced pre-auth quiz fields
            request.sleep_quality,
            request.obstacles,
            request.dietary_restrictions,
            request.weight_direction,
            request.weight_change_amount,
            request.motivations,
            request.nutrition_goals,
            request.interested_in_fasting,
            request.fasting_protocol,
            request.coach_id,
            request.training_experience,
            request.selected_days,
            # Sleep schedule for fasting optimization
            request.wake_time,
            request.sleep_time,
            # Duration range for flexible workout generation
            request.workout_duration_min,
            request.workout_duration_max,
            # Exercise consistency preference
            workout_variety=request.workout_variety,
        )
        update_data["preferences"] = final_preferences

        # Perform update
        logger.info(f"🔍 [DEBUG] save_user_preferences - update_data: {update_data}")
        logger.info(f"🔍 [DEBUG] save_user_preferences - equipment: {update_data.get('equipment')}")
        logger.info(f"🔍 [DEBUG] save_user_preferences - preferences: {update_data.get('preferences')}")
        if update_data:
            result = db.update_user(user_id, update_data)
            logger.info(f"Saved {len(update_data)} preference fields for user {user_id}")
            logger.info(f"🔍 [DEBUG] save_user_preferences - update result: {result}")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="preferences_saved",
            endpoint=f"/api/v1/users/{user_id}/preferences",
            message="Pre-auth quiz preferences saved",
            metadata={"fields_count": len(update_data)},
            status_code=200
        )

        return {"success": True, "message": "Preferences saved successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to save preferences: {e}")
        await log_user_error(
            user_id=user_id,
            action="preferences_saved",
            error=e,
            endpoint=f"/api/v1/users/{user_id}/preferences",
            status_code=500
        )
        raise safe_internal_error(e, "users")


@router.put("/{user_id}", response_model=User)
async def update_user(user_id: str, user: UserUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update a user."""
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
                try:
                    prefs = update_data.get("preferences", {})
                    logger.info(f"🏋️ [GymProfile] Onboarding completed - preferences: {prefs}")
                    logger.info(f"🏋️ [GymProfile] Equipment: {update_data.get('equipment', [])}")
                    logger.info(f"🏋️ [GymProfile] Equipment details: {len(update_data.get('equipment_details', []))} items")

                    await create_gym_profiles_from_onboarding(
                        user_id=user_id,
                        gym_name=prefs.get("gym_name"),
                        workout_environment=prefs.get("workout_environment"),
                        equipment=update_data.get("equipment", []),
                        equipment_details=update_data.get("equipment_details", []),
                        preferences=prefs,
                    )
                    logger.info(f"🏋️ [GymProfile] ✅ Created gym profile(s) for user {user_id} during onboarding")
                except Exception as gym_error:
                    logger.error(f"⚠️ [GymProfile] Failed to create gym profiles during onboarding: {gym_error}")
                    import traceback
                    logger.error(f"⚠️ [GymProfile] Traceback: {traceback.format_exc()}")
                    # Don't fail onboarding if gym profile creation fails

            # If onboarding was just completed, index preferences to ChromaDB for AI
            if user.onboarding_completed and update_data.get("onboarding_completed"):
                try:
                    from services.rag_service import WorkoutRAGService
                    from services.gemini_service import GeminiService

                    gemini_service = GeminiService()
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
                    logger.warning(f"⚠️ Could not index training settings to ChromaDB: {rag_error}")

            # Index exercise variety/consistency settings to ChromaDB for AI context
            prefs = update_data.get("preferences", {})
            if isinstance(prefs, str):
                import json
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
                    logger.warning(f"⚠️ Could not index exercise variety settings to ChromaDB: {rag_error}")
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
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}")
async def delete_user(user_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/reset-onboarding")
async def reset_onboarding(user_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}/reset")
async def full_reset(user_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "users")


# ==================== DATA EXPORT/IMPORT ====================


@router.get("/{user_id}/export")
async def export_user_data(
    user_id: str,
    format: str = "csv",
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Export all user data in the specified format.

    Query parameters:
    - format: Export format - "csv" (ZIP of CSVs), "json", "xlsx", or "parquet" (ZIP of Parquet files). Default: "csv"
    - start_date: Optional ISO date string (YYYY-MM-DD) for filtering data from this date
    - end_date: Optional ISO date string (YYYY-MM-DD) for filtering data until this date
    """
    import time
    start_time = time.time()
    logger.info(f"Starting data export for user: id={user_id}, format={format}, date_range={start_date} to {end_date}")

    if format not in ("csv", "json", "xlsx", "parquet"):
        raise HTTPException(status_code=400, detail=f"Unsupported export format: {format}. Use csv, json, xlsx, or parquet.")

    try:
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for export: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        logger.info(f"User verified, generating {format} export...")

        date_str = datetime.utcnow().strftime("%Y-%m-%d")

        if format == "json":
            from services.data_export import export_user_data_json
            data = export_user_data_json(user_id, start_date=start_date, end_date=end_date)
            from fastapi.responses import JSONResponse
            elapsed = time.time() - start_time
            logger.info(f"JSON export complete for user {user_id} in {elapsed:.2f}s")
            return JSONResponse(
                content=data,
                headers={
                    "Content-Disposition": f'attachment; filename="fitness_data_{date_str}.json"',
                }
            )

        elif format == "xlsx":
            from services.data_export import export_user_data_excel
            xlsx_bytes = export_user_data_excel(user_id, start_date=start_date, end_date=end_date)
            elapsed = time.time() - start_time
            logger.info(f"Excel export complete for user {user_id} in {elapsed:.2f}s, size: {len(xlsx_bytes)} bytes")
            return StreamingResponse(
                io.BytesIO(xlsx_bytes),
                media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                headers={
                    "Content-Disposition": f'attachment; filename="fitness_data_{date_str}.xlsx"',
                    "Content-Length": str(len(xlsx_bytes)),
                }
            )

        elif format == "parquet":
            from services.data_export import export_user_data_parquet
            parquet_bytes = export_user_data_parquet(user_id, start_date=start_date, end_date=end_date)
            elapsed = time.time() - start_time
            logger.info(f"Parquet export complete for user {user_id} in {elapsed:.2f}s, size: {len(parquet_bytes)} bytes")
            return StreamingResponse(
                io.BytesIO(parquet_bytes),
                media_type="application/octet-stream",
                headers={
                    "Content-Disposition": f'attachment; filename="fitness_data_{date_str}.zip"',
                    "Content-Length": str(len(parquet_bytes)),
                }
            )

        else:
            # Default: CSV ZIP
            from services.data_export import export_user_data as do_export
            zip_bytes = do_export(user_id, start_date=start_date, end_date=end_date)
            elapsed = time.time() - start_time
            logger.info(f"CSV export complete for user {user_id} in {elapsed:.2f}s, size: {len(zip_bytes)} bytes")
            return StreamingResponse(
                io.BytesIO(zip_bytes),
                media_type="application/zip",
                headers={
                    "Content-Disposition": f'attachment; filename="fitness_data_{date_str}.zip"',
                    "Content-Length": str(len(zip_bytes)),
                }
            )

    except HTTPException:
        raise
    except Exception as e:
        elapsed = time.time() - start_time
        logger.error(f"Failed to export user data after {elapsed:.2f}s: {e}")
        raise safe_internal_error(e, "users")


@router.get("/{user_id}/export-text")
async def export_user_data_text(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Export workout logs as a plain text file.

    Query parameters:
    - start_date: Optional ISO date string (YYYY-MM-DD) for filtering data from this date
    - end_date: Optional ISO date string (YYYY-MM-DD) for filtering data until this date

    Returns a formatted plain text file with workout history including:
    - Workout name, date, duration
    - Each exercise with sets, reps, weight, RPE
    - Notes if present
    - Calculated totals (total sets, total reps, total volume)
    """
    import time
    start_time = time.time()
    logger.info(f"Starting text export for user: id={user_id}, date_range={start_date} to {end_date}")

    try:
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for text export: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        logger.info(f"User verified, generating text export...")

        # Import here to avoid circular imports
        from services.data_export import export_workout_logs_text

        # Generate text content with date filters
        text_content = export_workout_logs_text(user_id, start_date=start_date, end_date=end_date)

        # Create filename with date
        date_str = datetime.utcnow().strftime("%Y-%m-%d")
        filename = f"workout_log_{date_str}.txt"

        elapsed = time.time() - start_time
        logger.info(f"Text export complete for user {user_id} in {elapsed:.2f}s, size: {len(text_content)} chars")

        # Return as plain text response
        from fastapi.responses import Response
        return Response(
            content=text_content,
            media_type="text/plain; charset=utf-8",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
                "Content-Length": str(len(text_content.encode('utf-8'))),
            }
        )

    except HTTPException:
        raise
    except ValueError as e:
        logger.error(f"Text export validation error: {e}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        elapsed = time.time() - start_time
        logger.error(f"Failed to export user data as text after {elapsed:.2f}s: {e}")
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/import")
async def import_user_data(user_id: str, file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "users")


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
async def get_favorite_exercises(user_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/favorite-exercises", response_model=FavoriteExercise)
async def add_favorite_exercise(user_id: str, request: FavoriteExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}/favorite-exercises/{exercise_name}")
async def remove_favorite_exercise(user_id: str, exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "users")


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
async def get_exercise_queue(user_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/exercise-queue", response_model=QueuedExercise)
async def add_to_exercise_queue(user_id: str, request: QueueExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
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

        # Invalidate only the next upcoming workout so it includes the queued exercise
        from api.v1.workouts.utils import invalidate_upcoming_workouts
        invalidate_upcoming_workouts(user_id, reason=f"exercise queued: {request.exercise_name}", only_next=True)

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
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}/exercise-queue/{exercise_name}")
async def remove_from_exercise_queue(user_id: str, exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "users")


# =============================================================================
# NUTRITION METRICS CALCULATION
# =============================================================================

class NutritionCalculationRequest(BaseModel):
    """Request body for calculating nutrition metrics."""
    weight_kg: float
    height_cm: float
    age: int
    gender: str  # 'male' or 'female'
    activity_level: Optional[str] = 'lightly_active'
    weight_direction: Optional[str] = 'maintain'
    weight_change_rate: Optional[str] = 'moderate'
    goal_weight_kg: Optional[float] = None
    nutrition_goals: Optional[List[str]] = None
    workout_days_per_week: Optional[int] = 3


class NutritionMetricsResponse(BaseModel):
    """Response model for calculated nutrition metrics."""
    calories: int
    protein: int
    carbs: int
    fat: int
    water_liters: float
    metabolic_age: int
    max_safe_deficit: int
    body_fat_percent: float
    lean_mass: float
    fat_mass: float
    protein_per_kg: float
    ideal_weight_min: float
    ideal_weight_max: float
    goal_date: Optional[str] = None
    weeks_to_goal: Optional[int] = None
    bmr: int
    tdee: int


@router.post("/{user_id}/calculate-nutrition-targets", response_model=NutritionMetricsResponse)
async def calculate_nutrition_targets(user_id: str, request: NutritionCalculationRequest, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate and save all nutrition metrics for a user.

    This endpoint:
    1. Calculates all nutrition metrics (BMR, TDEE, macros, metabolic age, etc.)
    2. Saves them to the nutrition_preferences table
    3. Indexes them for RAG/AI context (background)
    4. Returns the calculated metrics

    Called after quiz completion or when user updates their profile.
    """
    logger.info(f"Calculating nutrition targets for user: {user_id}")
    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Derive nutrition_goals from weight_direction if client sent stale default
        nutrition_goals = request.nutrition_goals
        if (not nutrition_goals or nutrition_goals == ['maintain']) and request.weight_direction:
            direction_map = {'lose': ['lose_fat'], 'gain': ['build_muscle']}
            nutrition_goals = direction_map.get(request.weight_direction, nutrition_goals or ['maintain'])
            if nutrition_goals != request.nutrition_goals:
                logger.info(f"Derived nutrition_goals={nutrition_goals} from weight_direction={request.weight_direction} for user {user_id}")

        # Call the Supabase function to calculate and save metrics
        # Timeout at 90s — well under Gunicorn's 120s worker timeout
        try:
            result = await asyncio.wait_for(
                asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: db.client.rpc(
                        'calculate_nutrition_metrics',
                        {
                            'p_user_id': user_id,
                            'p_weight_kg': request.weight_kg,
                            'p_height_cm': request.height_cm,
                            'p_age': request.age,
                            'p_gender': request.gender,
                            'p_activity_level': request.activity_level,
                            'p_weight_direction': request.weight_direction,
                            'p_weight_change_rate': request.weight_change_rate,
                            'p_goal_weight_kg': request.goal_weight_kg,
                            'p_nutrition_goals': nutrition_goals,
                            'p_workout_days_per_week': request.workout_days_per_week,
                        }
                    ).execute()
                ),
                timeout=90
            )
        except asyncio.TimeoutError:
            logger.error(f"Nutrition calculation timed out for user {user_id}")
            raise HTTPException(status_code=504, detail="Calculation timed out. Please try again.")

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to calculate nutrition metrics")

        metrics = result.data

        logger.info(f"Calculated nutrition targets for user {user_id}: {metrics.get('calories')} cal")

        # Index for RAG in background (non-blocking)
        async def _index_rag():
            try:
                from services.nutrition_rag_service import index_user_nutrition_metrics
                await index_user_nutrition_metrics(user_id, metrics)
                logger.info(f"Indexed nutrition metrics to RAG for user {user_id}")
            except Exception as rag_error:
                logger.warning(f"Could not index nutrition metrics to RAG: {rag_error}")

        background_tasks.add_task(_index_rag)

        # Log activity in background
        background_tasks.add_task(
            log_user_activity,
            user_id=user_id,
            action="nutrition_targets_calculated",
            endpoint=f"/api/v1/users/{user_id}/calculate-nutrition-targets",
            message="Nutrition targets calculated",
            metadata={
                "calories": metrics.get('calories'),
                "protein": metrics.get('protein'),
            },
            status_code=200
        )

        return NutritionMetricsResponse(
            calories=metrics['calories'],
            protein=metrics['protein'],
            carbs=metrics['carbs'],
            fat=metrics['fat'],
            water_liters=metrics['water_liters'],
            metabolic_age=metrics['metabolic_age'],
            max_safe_deficit=metrics['max_safe_deficit'],
            body_fat_percent=metrics['body_fat_percent'],
            lean_mass=metrics['lean_mass'],
            fat_mass=metrics['fat_mass'],
            protein_per_kg=metrics['protein_per_kg'],
            ideal_weight_min=metrics['ideal_weight_min'],
            ideal_weight_max=metrics['ideal_weight_max'],
            goal_date=str(metrics['goal_date']) if metrics.get('goal_date') else None,
            weeks_to_goal=metrics.get('weeks_to_goal'),
            bmr=metrics['bmr'],
            tdee=metrics['tdee'],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to calculate nutrition targets: {e}")
        await log_user_error(
            user_id=user_id,
            action="nutrition_targets_calculated",
            error=e,
            endpoint=f"/api/v1/users/{user_id}/calculate-nutrition-targets",
            status_code=500
        )
        raise safe_internal_error(e, "users")


@router.get("/{user_id}/nutrition-targets", response_model=NutritionMetricsResponse)
async def get_nutrition_targets(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get the user's calculated nutrition targets.

    Returns the most recently calculated nutrition metrics from the database.
    """
    logger.info(f"Getting nutrition targets for user: {user_id}")
    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get nutrition preferences
        result = db.client.table('nutrition_preferences').select('*').eq(
            'user_id', user_id
        ).single().execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Nutrition targets not found. Please complete the quiz first.")

        prefs = result.data

        # Check if metrics have been calculated
        if prefs.get('target_calories') is None:
            raise HTTPException(
                status_code=404,
                detail="Nutrition metrics not yet calculated. Please complete the body metrics in the quiz."
            )

        return NutritionMetricsResponse(
            calories=prefs['target_calories'],
            protein=prefs['target_protein_g'],
            carbs=prefs['target_carbs_g'],
            fat=prefs['target_fat_g'],
            water_liters=prefs.get('water_intake_liters', 2.5),
            metabolic_age=prefs.get('metabolic_age', 0),
            max_safe_deficit=prefs.get('max_safe_deficit', 500),
            body_fat_percent=prefs.get('estimated_body_fat_percent', 20.0),
            lean_mass=prefs.get('lean_mass_kg', 60.0),
            fat_mass=prefs.get('fat_mass_kg', 15.0),
            protein_per_kg=prefs.get('protein_per_kg', 1.6),
            ideal_weight_min=prefs.get('ideal_weight_min_kg', 60.0),
            ideal_weight_max=prefs.get('ideal_weight_max_kg', 80.0),
            goal_date=str(prefs['goal_date']) if prefs.get('goal_date') else None,
            weeks_to_goal=prefs.get('weeks_to_goal'),
            bmr=prefs['calculated_bmr'],
            tdee=prefs['calculated_tdee'],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get nutrition targets: {e}")
        raise safe_internal_error(e, "users")


class SyncFastingRequest(BaseModel):
    """Request to sync fasting preferences from onboarding."""
    interested_in_fasting: bool
    fasting_protocol: Optional[str] = None


class SyncFastingResponse(BaseModel):
    """Response from fasting sync."""
    success: bool
    message: str
    created: bool
    protocol: Optional[str] = None


@router.post("/{user_id}/sync-fasting-preferences", response_model=SyncFastingResponse)
async def sync_fasting_preferences(user_id: str, request: SyncFastingRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Sync fasting preferences from onboarding quiz to fasting_preferences table.

    This endpoint should be called after onboarding when the user has selected
    fasting options. It creates or updates the fasting_preferences record.
    """
    logger.info(f"Syncing fasting preferences for user: {user_id}")
    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # If not interested in fasting, don't create preferences
        if not request.interested_in_fasting:
            return SyncFastingResponse(
                success=True,
                message="User not interested in fasting",
                created=False,
                protocol=None,
            )

        # Normalize protocol format
        protocol = request.fasting_protocol or "16:8"

        # Handle custom protocol format from onboarding (e.g., "custom:16:8")
        if protocol.startswith("custom:"):
            protocol = "16:8"  # Default for custom

        now = datetime.now().isoformat()

        # Check if fasting_preferences already exists
        existing = db.client.table("fasting_preferences").select("id").eq(
            "user_id", user_id
        ).execute()

        if existing.data:
            # Update existing record
            db.client.table("fasting_preferences").update({
                "default_protocol": protocol,
                "fasting_onboarding_completed": True,
                "updated_at": now,
            }).eq("user_id", user_id).execute()

            logger.info(f"Updated fasting preferences for user {user_id}: protocol={protocol}")
            return SyncFastingResponse(
                success=True,
                message="Fasting preferences updated from onboarding",
                created=False,
                protocol=protocol,
            )
        else:
            # Insert new record
            db.client.table("fasting_preferences").insert({
                "user_id": user_id,
                "default_protocol": protocol,
                "fasting_onboarding_completed": True,
                "onboarding_completed_at": now,
                "experience_level": "beginner",
                "updated_at": now,
            }).execute()

            logger.info(f"Created fasting preferences for user {user_id}: protocol={protocol}")
            return SyncFastingResponse(
                success=True,
                message="Fasting preferences synced from onboarding",
                created=True,
                protocol=protocol,
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to sync fasting preferences: {e}")
        raise safe_internal_error(e, "users")


# =============================================================================
# GYM PROFILE CREATION FROM ONBOARDING
# =============================================================================


async def create_gym_profiles_from_onboarding(
    user_id: str,
    gym_name: Optional[str],
    workout_environment: Optional[str],
    equipment: list,
    equipment_details: list,
    preferences: dict,
):
    """
    Create gym profile(s) from onboarding data.

    Handles three scenarios:
    1. Single profile (home_gym, commercial_gym, other)
    2. Both home and gym - creates 2 profiles
    3. Fallback to "My Gym" if no data provided

    Args:
        user_id: User ID
        gym_name: User-provided gym name (optional)
        workout_environment: 'home_gym', 'commercial_gym', 'both', 'other'
        equipment: List of equipment strings
        equipment_details: Detailed equipment with quantities/weights
        preferences: Full preferences dict with training settings
    """
    from datetime import datetime
    supabase = get_supabase()

    # Default values
    gym_name = gym_name or "My Gym"
    workout_environment = workout_environment or "commercial_gym"

    # Auto-populate equipment based on environment if not provided
    if not equipment:
        equipment = get_default_equipment_for_environment(workout_environment)
        logger.info(f"🏋️ [GymProfile] Auto-populated equipment for {workout_environment}: {equipment}")

    logger.info(f"🏋️ [GymProfile] Creating gym profile(s) for user {user_id}")
    logger.info(f"🏋️ [GymProfile] Environment: {workout_environment}, Name: {gym_name}")

    # Helper function to create a single profile
    def create_profile_data(name: str, environment: str, is_active: bool, display_order: int = 0) -> dict:
        now = datetime.utcnow().isoformat()
        icon = "fitness_center" if environment == "commercial_gym" else "home"

        return {
            "user_id": user_id,
            "name": name,
            "icon": icon,
            "color": "#00BCD4",
            "equipment": equipment,
            "equipment_details": equipment_details,
            "workout_environment": environment,
            "training_split": preferences.get("training_split"),
            "workout_days": preferences.get("workout_days", []),
            "duration_minutes": preferences.get("workout_duration", 45),
            "goals": [],
            "focus_areas": [],
            "display_order": display_order,
            "is_active": is_active,
            "created_at": now,
            "updated_at": now,
        }

    try:
        profiles_created = []

        if workout_environment == "both":
            # Create two profiles: Home (active) and Commercial Gym (inactive)
            logger.info("🏋️ [GymProfile] Creating 2 profiles for 'both' scenario")

            # Home profile (active by default)
            home_profile = create_profile_data(
                name="Home Gym",
                environment="home_gym",
                is_active=True,
                display_order=0
            )
            result_home = supabase.client.table("gym_profiles").insert(home_profile).execute()
            if result_home.data:
                profiles_created.append(result_home.data[0])
                logger.info(f"✅ [GymProfile] Created Home Gym profile (active)")

            # Commercial gym profile (inactive)
            gym_profile_name = gym_name if "Gym" in gym_name else f"{gym_name} Gym"
            commercial_profile = create_profile_data(
                name=gym_profile_name,
                environment="commercial_gym",
                is_active=False,
                display_order=1
            )
            result_commercial = supabase.client.table("gym_profiles").insert(commercial_profile).execute()
            if result_commercial.data:
                profiles_created.append(result_commercial.data[0])
                logger.info(f"✅ [GymProfile] Created {gym_profile_name} profile (inactive)")

            # Set Home Gym as active profile
            if result_home.data:
                active_profile_id = result_home.data[0]["id"]
                supabase.client.table("users") \
                    .update({"active_gym_profile_id": active_profile_id}) \
                    .eq("id", user_id) \
                    .execute()

        else:
            # Single profile
            logger.info("🏋️ [GymProfile] Creating single profile")
            profile_data = create_profile_data(
                name=gym_name,
                environment=workout_environment,
                is_active=True,
                display_order=0
            )
            result = supabase.client.table("gym_profiles").insert(profile_data).execute()

            if result.data:
                profiles_created.append(result.data[0])
                profile_id = result.data[0]["id"]
                logger.info(f"✅ [GymProfile] Created {gym_name} profile (active)")

                # Set as active profile
                supabase.client.table("users") \
                    .update({"active_gym_profile_id": profile_id}) \
                    .eq("id", user_id) \
                    .execute()

        logger.info(f"🏋️ [GymProfile] Successfully created {len(profiles_created)} profile(s)")
        return profiles_created

    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to create gym profiles: {e}")
        raise


# ============================================================================
# Profile Photo Upload
# ============================================================================

def get_s3_client():
    """Get boto3 S3 client with credentials from settings."""
    settings = get_settings()
    return boto3.client(
        's3',
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_default_region,
    )


async def upload_profile_photo_to_s3(
    file: UploadFile,
    user_id: str,
) -> tuple[str, str]:
    """
    Upload profile photo to S3 and return (photo_url, storage_key).
    """
    # Generate unique key
    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    ext = file.filename.split('.')[-1] if file.filename else 'jpg'
    storage_key = f"profile_photos/{user_id}/{timestamp}_{uuid.uuid4().hex[:8]}.{ext}"

    # Upload to S3
    s3 = get_s3_client()
    contents = await file.read()

    settings = get_settings()
    s3.put_object(
        Bucket=settings.s3_bucket_name,
        Key=storage_key,
        Body=contents,
        ContentType=file.content_type or 'image/jpeg',
    )

    # Generate URL
    photo_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{storage_key}"

    return photo_url, storage_key


async def delete_profile_photo_from_s3(storage_key: str) -> bool:
    """Delete profile photo from S3."""
    try:
        settings = get_settings()
        s3 = get_s3_client()
        s3.delete_object(
            Bucket=settings.s3_bucket_name,
            Key=storage_key,
        )
        return True
    except Exception as e:
        logger.error(f"Error deleting profile photo from S3: {e}")
        return False


class ProfilePhotoResponse(BaseModel):
    """Response for profile photo upload."""
    photo_url: str
    message: str


@router.post("/{id}/photo", response_model=ProfilePhotoResponse)
async def upload_profile_photo(
    id: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Upload a profile photo for a user.

    - Uploads the image to S3
    - Updates the user's photo_url in the database
    - Returns the new photo URL
    """
    logger.info(f"📸 [ProfilePhoto] Upload request for user {id}")

    # Validate file type
    if file.content_type not in ['image/jpeg', 'image/png', 'image/gif', 'image/webp']:
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Only JPEG, PNG, GIF, and WebP images are allowed."
        )

    # Check file size (max 5MB)
    contents = await file.read()
    if len(contents) > 5 * 1024 * 1024:
        raise HTTPException(
            status_code=400,
            detail="File too large. Maximum size is 5MB."
        )
    # Reset file position after reading
    await file.seek(0)

    try:
        db = get_supabase_db()

        # Check if user exists
        result = db.client.table("users").select("id, photo_url").eq("id", id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user = result.data[0]
        old_photo_url = user.get("photo_url")

        # Upload new photo to S3
        photo_url, storage_key = await upload_profile_photo_to_s3(file, id)
        logger.info(f"✅ [ProfilePhoto] Uploaded to S3: {storage_key}")

        # Update user's photo_url in database
        db.client.table("users").update({
            "photo_url": photo_url,
        }).eq("id", id).execute()
        logger.info(f"✅ [ProfilePhoto] Updated user record with new photo URL")

        # Delete old photo from S3 if it exists
        if old_photo_url and "profile_photos/" in old_photo_url:
            # Extract storage key from URL
            try:
                old_storage_key = old_photo_url.split(".amazonaws.com/")[1]
                await delete_profile_photo_from_s3(old_storage_key)
                logger.info(f"🗑️ [ProfilePhoto] Deleted old photo: {old_storage_key}")
            except Exception as e:
                logger.warning(f"⚠️ [ProfilePhoto] Could not delete old photo: {e}")

        return ProfilePhotoResponse(
            photo_url=photo_url,
            message="Profile photo uploaded successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [ProfilePhoto] Upload failed: {e}")
        raise safe_internal_error(e, "profile_photo_upload")


@router.delete("/{id}/photo")
async def delete_profile_photo(id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a user's profile photo.

    - Removes the photo from S3
    - Sets photo_url to null in the database
    """
    logger.info(f"🗑️ [ProfilePhoto] Delete request for user {id}")

    try:
        db = get_supabase_db()

        # Get user and current photo URL
        result = db.client.table("users").select("id, photo_url").eq("id", id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user = result.data[0]
        photo_url = user.get("photo_url")

        if not photo_url:
            return {"message": "No profile photo to delete"}

        # Delete from S3 if it's our photo
        if "profile_photos/" in photo_url:
            try:
                storage_key = photo_url.split(".amazonaws.com/")[1]
                await delete_profile_photo_from_s3(storage_key)
                logger.info(f"✅ [ProfilePhoto] Deleted from S3: {storage_key}")
            except Exception as e:
                logger.warning(f"⚠️ [ProfilePhoto] Could not delete from S3: {e}")

        # Update user's photo_url to null
        db.client.table("users").update({
            "photo_url": None,
        }).eq("id", id).execute()
        logger.info(f"✅ [ProfilePhoto] Cleared photo URL from user record")

        return {"message": "Profile photo deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [ProfilePhoto] Delete failed: {e}")
        raise safe_internal_error(e, "profile_photo_delete")
