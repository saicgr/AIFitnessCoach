"""
Gym Profiles API endpoints.

Multi-gym profile system allowing users to create different gym/location setups
with unique equipment configurations. Each profile generates workouts tailored
to its specific equipment.

ENDPOINTS:
- GET  /api/v1/gym-profiles/ - List user's gym profiles
- POST /api/v1/gym-profiles/ - Create new gym profile
- GET  /api/v1/gym-profiles/{id} - Get single gym profile
- PUT  /api/v1/gym-profiles/{id} - Update gym profile
- DELETE /api/v1/gym-profiles/{id} - Delete gym profile
- POST /api/v1/gym-profiles/{id}/activate - Activate (switch to) a profile
- POST /api/v1/gym-profiles/reorder - Update display order of profiles
- GET  /api/v1/gym-profiles/active - Get user's currently active profile
"""
from .gym_profiles_endpoints import router as _endpoints_router

from datetime import datetime
from fastapi import APIRouter, HTTPException, Query, Depends
from typing import Optional, List

from core.supabase_client import get_supabase
from core.logger import get_logger
from services.user_context_service import user_context_service, EventType
from models.gym_profile import (
    GymProfileCreate,
    GymProfileUpdate,
    GymProfile,
    GymProfileWithStats,
    GymProfileListResponse,
    ReorderProfilesRequest,
    DuplicateProfileRequest,
    ActivateProfileResponse,
)
from core.auth import get_current_user
from core.exceptions import safe_internal_error


router = APIRouter()
logger = get_logger(__name__)

_COACH_COLORS = {
    "coach_mike": "#FF9800",    # Orange
    "dr_sarah": "#2196F3",      # Blue
    "sergeant_max": "#F44336",  # Red
    "zen_maya": "#4CAF50",      # Green
    "hype_danny": "#9C27B0",    # Purple
}


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================


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


def row_to_gym_profile(row: dict) -> GymProfile:
    """Convert database row to GymProfile model."""
    return GymProfile(
        id=row["id"],
        user_id=row["user_id"],
        name=row["name"],
        icon=row.get("icon", "fitness_center"),
        color=row.get("color", "#00BCD4"),
        equipment=row.get("equipment") or [],
        equipment_details=row.get("equipment_details") or [],
        workout_environment=row.get("workout_environment", "commercial_gym"),
        # Location fields
        address=row.get("address"),
        city=row.get("city"),
        latitude=row.get("latitude"),
        longitude=row.get("longitude"),
        place_id=row.get("place_id"),
        location_radius_meters=row.get("location_radius_meters", 100),
        auto_switch_enabled=row.get("auto_switch_enabled", True),
        # Workout preferences
        training_split=row.get("training_split"),
        workout_days=row.get("workout_days") or [],
        duration_minutes=row.get("duration_minutes", 45),
        duration_minutes_min=row.get("duration_minutes_min"),
        duration_minutes_max=row.get("duration_minutes_max"),
        goals=row.get("goals") or [],
        focus_areas=row.get("focus_areas") or [],
        current_program_id=row.get("current_program_id"),
        program_custom_name=row.get("program_custom_name"),
        display_order=row.get("display_order", 0),
        is_active=row.get("is_active", False),
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )


async def create_default_profile_if_needed(user_id: str) -> Optional[GymProfile]:
    """
    Create a default gym profile ONLY for legacy users who completed onboarding
    before gym profiles feature was added.

    New users (with onboarding data containing workout_environment) get profiles
    created during onboarding.

    Returns the created profile or None if profiles already exist or user is new.
    """
    try:
        supabase = get_supabase()

        # Check if user already has profiles
        existing = supabase.client.table("gym_profiles") \
            .select("id") \
            .eq("user_id", user_id) \
            .limit(1) \
            .execute()

        if existing.data:
            # User already has profiles
            return None

        # Fetch user to check if they have workout_environment set
        user_result = supabase.client.table("users") \
            .select("equipment, equipment_details, preferences, onboarding_completed") \
            .eq("id", user_id) \
            .single() \
            .execute()

        if not user_result.data:
            logger.warning(f"User {user_id} not found when creating default profile")
            return None

        user = user_result.data
        preferences = user.get("preferences") or {}

        # If onboarding not complete, skip (profile will be created later)
        if not user.get("onboarding_completed"):
            logger.info(f"User {user_id} has not completed onboarding yet, skipping default profile")
            return None

        # User completed onboarding but no profile exists - create one
        # This handles both legacy users and users whose profile creation failed during onboarding
        logger.info(f"Creating default profile for user {user_id} (no existing profile)")

        # Get equipment from user record
        import json
        user_equipment = user.get("equipment") or []
        if isinstance(user_equipment, str):
            try:
                user_equipment = json.loads(user_equipment)
            except Exception as e:
                logger.debug(f"Failed to parse user equipment JSON: {e}")
                user_equipment = []

        # Get workout environment
        workout_environment = preferences.get("workout_environment", "commercial_gym")

        # Auto-populate equipment based on environment if empty
        if not user_equipment:
            user_equipment = get_default_equipment_for_environment(workout_environment)
            logger.info(f"🏋️ [GymProfile] Auto-populated equipment for {workout_environment}: {user_equipment}")

        # Create default profile from user's settings
        now = datetime.utcnow().isoformat()
        coach_id = preferences.get("coach_id")
        profile_color = _COACH_COLORS.get(coach_id, "#FF9800")
        profile_data = {
            "user_id": user_id,
            "name": "My Gym",
            "icon": "fitness_center",
            "color": profile_color,
            "equipment": user_equipment,
            "equipment_details": user.get("equipment_details") or [],
            "workout_environment": workout_environment,
            "training_split": preferences.get("training_split"),
            "workout_days": preferences.get("workout_days") or [],
            "duration_minutes": preferences.get("workout_duration", 45),
            "goals": [],
            "focus_areas": [],
            "display_order": 0,
            "is_active": True,
            "created_at": now,
            "updated_at": now,
        }

        result = supabase.client.table("gym_profiles") \
            .insert(profile_data) \
            .execute()

        if not result.data:
            logger.error(f"Failed to create default profile for user {user_id}")
            return None

        profile = row_to_gym_profile(result.data[0])

        # Update user's active_gym_profile_id
        supabase.client.table("users") \
            .update({"active_gym_profile_id": profile.id}) \
            .eq("id", user_id) \
            .execute()

        # Link existing workouts to this profile
        supabase.client.table("workouts") \
            .update({"gym_profile_id": profile.id}) \
            .eq("user_id", user_id) \
            .is_("gym_profile_id", "null") \
            .execute()

        logger.info(f"✅ [GymProfile] Created default profile for user {user_id}: {profile.name}")
        logger.info(f"🏋️ [GymProfile] Migrated {len(profile.equipment)} equipment items")

        return profile

    except Exception as e:
        logger.error(f"Failed to create default profile for user {user_id}: {e}")
        return None


# =============================================================================
# LIST PROFILES
# =============================================================================


@router.get("/", response_model=GymProfileListResponse)
async def list_gym_profiles(
    user_id: str = Query(..., description="User ID"),
    include_stats: bool = Query(False, description="Include workout stats per profile"),
    current_user: dict = Depends(get_current_user),
):
    """
    List all gym profiles for a user.

    Creates a default profile from user's current settings if no profiles exist.
    Returns profiles ordered by display_order.
    """
    logger.info(f"📋 [GymProfile] Listing profiles for user {user_id}")

    try:
        supabase = get_supabase()

        # First check if user has any profiles
        profiles_result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("user_id", user_id) \
            .order("display_order") \
            .execute()

        profiles = profiles_result.data or []

        # Auto-create default profile if none exist
        if not profiles:
            logger.info(f"🔄 [GymProfile] No profiles found, creating default for user {user_id}")
            default_profile = await create_default_profile_if_needed(user_id)
            if default_profile:
                profiles = [default_profile.__dict__]
            else:
                profiles = []

        # Convert to models
        profile_models = [row_to_gym_profile(row) for row in profiles]

        # Find active profile ID
        active_profile_id = None
        for profile in profile_models:
            if profile.is_active:
                active_profile_id = profile.id
                break

        # Optionally add workout stats
        if include_stats and profile_models:
            profile_ids = [p.id for p in profile_models]
            # Get workout counts per profile
            for profile in profile_models:
                workout_count_result = supabase.client.table("workouts") \
                    .select("id", count="exact") \
                    .eq("gym_profile_id", profile.id) \
                    .execute()
                # This would need to be enhanced to properly get counts

        logger.info(f"✅ [GymProfile] Found {len(profile_models)} profiles for user {user_id}")

        return GymProfileListResponse(
            profiles=profile_models,
            active_profile_id=active_profile_id,
            count=len(profile_models),
        )

    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to list profiles: {e}")
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# GET ACTIVE PROFILE
# =============================================================================


@router.get("/active", response_model=Optional[GymProfile])
async def get_active_profile(
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get the user's currently active gym profile.

    Creates a default profile if none exists.
    """
    logger.info(f"🔍 [GymProfile] Getting active profile for user {user_id}")

    try:
        supabase = get_supabase()

        # Try to get active profile
        result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("user_id", user_id) \
            .eq("is_active", True) \
            .single() \
            .execute()

        if result.data:
            profile = row_to_gym_profile(result.data)

            # Auto-heal: Fix empty equipment based on environment
            if not profile.equipment or len(profile.equipment) == 0:
                default_equipment = get_default_equipment_for_environment(
                    profile.workout_environment or 'commercial_gym'
                )
                logger.info(f"🔧 [GymProfile] Auto-healing empty equipment for profile {profile.id}: {default_equipment}")

                # Update the profile in database
                supabase.client.table("gym_profiles") \
                    .update({"equipment": default_equipment, "updated_at": datetime.utcnow().isoformat()}) \
                    .eq("id", profile.id) \
                    .execute()

                # Update the profile object to return
                profile = GymProfile(
                    id=profile.id,
                    user_id=profile.user_id,
                    name=profile.name,
                    icon=profile.icon,
                    color=profile.color,
                    equipment=default_equipment,
                    equipment_details=profile.equipment_details,
                    workout_environment=profile.workout_environment,
                    training_split=profile.training_split,
                    workout_days=profile.workout_days,
                    duration_minutes=profile.duration_minutes,
                    goals=profile.goals,
                    focus_areas=profile.focus_areas,
                    display_order=profile.display_order,
                    is_active=profile.is_active,
                    created_at=profile.created_at,
                    updated_at=datetime.utcnow(),
                )

            logger.info(f"✅ [GymProfile] Active profile: {profile.name}")
            return profile

        # No active profile found, try to create default
        default_profile = await create_default_profile_if_needed(user_id)
        if default_profile:
            return default_profile

        # Check if any profiles exist and activate the first one
        any_result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("user_id", user_id) \
            .order("display_order") \
            .limit(1) \
            .execute()

        if any_result.data:
            # Activate the first profile
            profile_id = any_result.data[0]["id"]
            supabase.client.table("gym_profiles") \
                .update({"is_active": True}) \
                .eq("id", profile_id) \
                .execute()
            return row_to_gym_profile(any_result.data[0])

        return None

    except Exception as e:
        # Handle case where no rows found
        if "0 rows" in str(e).lower() or "no rows" in str(e).lower():
            # Try to create default profile
            default_profile = await create_default_profile_if_needed(user_id)
            return default_profile
        logger.error(f"❌ [GymProfile] Failed to get active profile: {e}")
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# CREATE PROFILE
# =============================================================================


@router.post("/", response_model=GymProfile)
async def create_gym_profile(
    user_id: str = Query(..., description="User ID"),
    profile: GymProfileCreate = ...,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a new gym profile for a user.

    The new profile will be added at the end of the display order.
    """
    logger.info(f"➕ [GymProfile] Creating profile '{profile.name}' for user {user_id}")
    logger.info(f"🏋️ [GymProfile] Equipment: {profile.equipment}")
    logger.info(f"📍 [GymProfile] Environment: {profile.workout_environment}")
    logger.info(f"🎨 [GymProfile] Color: {profile.color}")

    try:
        supabase = get_supabase()

        # Verify user exists
        user_result = supabase.client.table("users") \
            .select("id") \
            .eq("id", user_id) \
            .single() \
            .execute()

        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")

        # Get max display_order for this user
        order_result = supabase.client.table("gym_profiles") \
            .select("display_order") \
            .eq("user_id", user_id) \
            .order("display_order", desc=True) \
            .limit(1) \
            .execute()

        max_order = order_result.data[0]["display_order"] if order_result.data else -1
        new_order = max_order + 1

        # Check if this is the first profile (should be active)
        is_first_profile = max_order == -1

        now = datetime.utcnow().isoformat()
        profile_data = {
            "user_id": user_id,
            "name": profile.name,
            "icon": profile.icon,
            "color": profile.color,
            "equipment": profile.equipment,
            "equipment_details": profile.equipment_details,
            "workout_environment": profile.workout_environment,
            # Location fields
            "address": profile.address,
            "city": profile.city,
            "latitude": profile.latitude,
            "longitude": profile.longitude,
            "place_id": profile.place_id,
            "location_radius_meters": profile.location_radius_meters,
            "auto_switch_enabled": profile.auto_switch_enabled,
            # Workout preferences
            "training_split": profile.training_split,
            "workout_days": profile.workout_days,
            "duration_minutes": profile.duration_minutes,
            "duration_minutes_min": profile.duration_minutes_min,
            "duration_minutes_max": profile.duration_minutes_max,
            "goals": profile.goals,
            "focus_areas": profile.focus_areas,
            "display_order": new_order,
            "is_active": is_first_profile,
            "created_at": now,
            "updated_at": now,
        }

        result = supabase.client.table("gym_profiles") \
            .insert(profile_data) \
            .execute()

        if not result.data:
            raise safe_internal_error(e, "endpoint")

        created_profile = row_to_gym_profile(result.data[0])

        # If first profile, update user's active_gym_profile_id
        if is_first_profile:
            supabase.client.table("users") \
                .update({"active_gym_profile_id": created_profile.id}) \
                .eq("id", user_id) \
                .execute()

        # Log to user context
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "gym_profile",
                "action": "created",
                "profile_id": created_profile.id,
                "profile_name": created_profile.name,
                "equipment_count": len(created_profile.equipment),
                "workout_environment": created_profile.workout_environment,
            },
            context={"source": "gym_profiles_api"}
        )

        logger.info(f"✅ [GymProfile] Created profile '{created_profile.name}' (id: {created_profile.id})")

        return created_profile

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to create profile: {e}")
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# GET SINGLE PROFILE
# =============================================================================


@router.get("/{profile_id}", response_model=GymProfile)
async def get_gym_profile(
    profile_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a single gym profile by ID."""
    logger.info(f"🔍 [GymProfile] Fetching profile {profile_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("id", profile_id) \
            .single() \
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Profile not found")

        return row_to_gym_profile(result.data)

    except HTTPException:
        raise
    except Exception as e:
        if "0 rows" in str(e).lower() or "no rows" in str(e).lower():
            raise HTTPException(status_code=404, detail="Profile not found")
        logger.error(f"❌ [GymProfile] Failed to get profile: {e}")
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# UPDATE PROFILE
# =============================================================================



# Include secondary endpoints
router.include_router(_endpoints_router)
