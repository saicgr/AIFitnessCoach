"""
User API endpoints.

ENDPOINTS:
- POST /api/v1/users/auth/google - Authenticate with Google OAuth via Supabase
- POST /api/v1/users/ - Create a new user
- GET  /api/v1/users/{id} - Get user by ID
- PUT  /api/v1/users/{id} - Update user
- DELETE /api/v1/users/{id} - Delete user
- DELETE /api/v1/users/{id}/reset - Full reset (delete all user data)
- POST /api/v1/users/demo - Create/get demo user
"""
import json
from fastapi import APIRouter, HTTPException
from typing import Optional
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.supabase_client import get_supabase
from core.logger import get_logger
from models.schemas import User, UserCreate, UserUpdate


class GoogleAuthRequest(BaseModel):
    """Request body for Google OAuth authentication."""
    access_token: str

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

    preferences = row.get("preferences")
    if isinstance(preferences, dict):
        preferences = json.dumps(preferences)
    elif preferences is None:
        preferences = "{}"

    active_injuries = row.get("active_injuries")
    if isinstance(active_injuries, list):
        active_injuries = json.dumps(active_injuries)
    elif active_injuries is None:
        active_injuries = "[]"

    return User(
        id=row.get("id"),
        username=row.get("email"),  # Use email as username
        name=row.get("name"),
        onboarding_completed=row.get("onboarding_completed", False),
        fitness_level=row.get("fitness_level", "beginner"),
        goals=goals,
        equipment=equipment,
        preferences=preferences,
        active_injuries=active_injuries,
        created_at=row.get("created_at"),
    )


@router.post("/auth/google", response_model=User)
async def google_auth(request: GoogleAuthRequest):
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
        user_response = supabase_client.auth.get_user(request.access_token)

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
        new_user_data = {
            "auth_id": supabase_user_id,
            "email": email,
            "name": full_name,
            "onboarding_completed": False,
            "fitness_level": "beginner",
            "goals": [],
            "equipment": [],
            "preferences": {"name": full_name, "email": email},
            "active_injuries": [],
        }

        created = db.create_user(new_user_data)
        logger.info(f"New user created via Google OAuth: id={created['id']}, email={email}")

        return row_to_user(created)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Google auth failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def merge_extended_fields_into_preferences(
    base_preferences: str,
    days_per_week: Optional[int],
    workout_duration: Optional[int],
    training_split: Optional[str],
    intensity_preference: Optional[str],
    preferred_time: Optional[str],
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

    return prefs


@router.post("/", response_model=User)
async def create_user(user: UserCreate):
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

        return row_to_user(created)

    except Exception as e:
        logger.error(f"Failed to create user: {e}")
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
        if user.active_injuries is not None:
            update_data["active_injuries"] = json.loads(user.active_injuries) if isinstance(user.active_injuries, str) else user.active_injuries
        if user.onboarding_completed is not None:
            update_data["onboarding_completed"] = user.onboarding_completed

        # Handle extended onboarding fields - merge into preferences
        has_extended_fields = any([
            user.days_per_week, user.workout_duration, user.training_split,
            user.intensity_preference, user.preferred_time
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
            )
            update_data["preferences"] = final_preferences

        if update_data:
            updated = db.update_user(user_id, update_data)
            logger.debug(f"Updated {len(update_data)} fields for user {user_id}")
        else:
            updated = existing

        logger.info(f"User updated: id={user_id}")
        return row_to_user(updated)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update user: {e}")
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

        return {"message": "User deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/demo", response_model=User)
async def create_demo_user():
    """
    Create or get a demo user with pre-populated data.
    Demo user is identified by email 'demo@aifitnesscoach.app'.
    If already exists, returns existing user.
    """
    DEMO_EMAIL = "demo@aifitnesscoach.app"
    logger.info("Creating/getting demo user")

    try:
        db = get_supabase_db()

        # Check if demo user already exists by email
        existing = db.get_user_by_email(DEMO_EMAIL)

        if existing:
            logger.info(f"Demo user already exists: id={existing['id']}")
            return row_to_user(existing)

        # Create demo user with rich profile data (let Supabase auto-generate ID)
        demo_data = {
            "email": DEMO_EMAIL,
            "name": "Demo User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": ["Build Muscle", "Improve Endurance", "Stay Healthy"],
            "equipment": ["Dumbbells", "Barbell", "Pull-up Bar", "Bench", "Resistance Bands"],
            "preferences": {
                "days_per_week": 4,
                "workout_duration": 60,
                "training_split": "push_pull_legs",
                "intensity_preference": "moderate",
                "preferred_time": "morning",
                "selected_days": [0, 1, 3, 4],
                "name": "Demo User",
                "workout_variety": "varied"
            },
            "active_injuries": [],
        }

        created = db.create_user(demo_data)
        logger.info(f"Demo user created: id={created['id']}")

        return row_to_user(created)

    except Exception as e:
        logger.error(f"Failed to create demo user: {e}")
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
