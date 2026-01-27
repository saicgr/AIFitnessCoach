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
from datetime import datetime
from fastapi import APIRouter, HTTPException, Query
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
    ActivateProfileResponse,
)


router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================


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

        # If user has workout_environment in preferences, they're a new user
        # Their profile will be created during onboarding completion
        if preferences.get("workout_environment"):
            logger.info(f"User {user_id} is new user, profile will be created in onboarding")
            return None

        # If onboarding not complete, skip (profile will be created later)
        if not user.get("onboarding_completed"):
            logger.info(f"User {user_id} has not completed onboarding yet, skipping default profile")
            return None

        # Legacy user - create default profile
        logger.info(f"Creating default profile for legacy user {user_id}")

        # Create default profile from user's settings
        now = datetime.utcnow().isoformat()
        profile_data = {
            "user_id": user_id,
            "name": "My Gym",
            "icon": "fitness_center",
            "color": "#00BCD4",
            "equipment": user.get("equipment") or [],
            "equipment_details": user.get("equipment_details") or [],
            "workout_environment": preferences.get("workout_environment", "commercial_gym"),
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
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# GET ACTIVE PROFILE
# =============================================================================


@router.get("/active", response_model=Optional[GymProfile])
async def get_active_profile(
    user_id: str = Query(..., description="User ID"),
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
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# CREATE PROFILE
# =============================================================================


@router.post("/", response_model=GymProfile)
async def create_gym_profile(
    user_id: str = Query(..., description="User ID"),
    profile: GymProfileCreate = ...,
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
            raise HTTPException(status_code=500, detail="Failed to create profile")

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
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# GET SINGLE PROFILE
# =============================================================================


@router.get("/{profile_id}", response_model=GymProfile)
async def get_gym_profile(profile_id: str):
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
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# UPDATE PROFILE
# =============================================================================


@router.put("/{profile_id}", response_model=GymProfile)
async def update_gym_profile(profile_id: str, update: GymProfileUpdate):
    """
    Update a gym profile.

    Only provided fields will be updated (partial update).
    """
    logger.info(f"✏️ [GymProfile] Updating profile {profile_id}")

    try:
        supabase = get_supabase()

        # Verify profile exists
        existing = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("id", profile_id) \
            .single() \
            .execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Profile not found")

        old_profile = existing.data

        # Build update data (only non-None fields)
        update_data = {"updated_at": datetime.utcnow().isoformat()}

        if update.name is not None:
            update_data["name"] = update.name
        if update.icon is not None:
            update_data["icon"] = update.icon
        if update.color is not None:
            update_data["color"] = update.color
        if update.equipment is not None:
            update_data["equipment"] = update.equipment
        if update.equipment_details is not None:
            update_data["equipment_details"] = update.equipment_details
        if update.workout_environment is not None:
            update_data["workout_environment"] = update.workout_environment
        if update.training_split is not None:
            update_data["training_split"] = update.training_split
        if update.workout_days is not None:
            update_data["workout_days"] = update.workout_days
        if update.duration_minutes is not None:
            update_data["duration_minutes"] = update.duration_minutes
        if update.duration_minutes_min is not None:
            update_data["duration_minutes_min"] = update.duration_minutes_min
        if update.duration_minutes_max is not None:
            update_data["duration_minutes_max"] = update.duration_minutes_max
        if update.goals is not None:
            update_data["goals"] = update.goals
        if update.focus_areas is not None:
            update_data["focus_areas"] = update.focus_areas
        if update.current_program_id is not None:
            update_data["current_program_id"] = update.current_program_id
        if update.program_custom_name is not None:
            update_data["program_custom_name"] = update.program_custom_name

        result = supabase.client.table("gym_profiles") \
            .update(update_data) \
            .eq("id", profile_id) \
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update profile")

        updated_profile = row_to_gym_profile(result.data[0])

        # Log changes
        changes = []
        if update.name and update.name != old_profile.get("name"):
            changes.append(f"name: {old_profile.get('name')} → {update.name}")
        if update.equipment and update.equipment != old_profile.get("equipment"):
            changes.append(f"equipment: {len(update.equipment)} items")
        if update.workout_environment and update.workout_environment != old_profile.get("workout_environment"):
            changes.append(f"environment: {update.workout_environment}")

        if changes:
            logger.info(f"🔄 [GymProfile] Updated {profile_id}: {', '.join(changes)}")

        # Log to user context
        await user_context_service.log_event(
            user_id=old_profile["user_id"],
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "gym_profile",
                "action": "updated",
                "profile_id": profile_id,
                "profile_name": updated_profile.name,
                "changes": changes,
            },
            context={"source": "gym_profiles_api"}
        )

        return updated_profile

    except HTTPException:
        raise
    except Exception as e:
        if "0 rows" in str(e).lower() or "no rows" in str(e).lower():
            raise HTTPException(status_code=404, detail="Profile not found")
        logger.error(f"❌ [GymProfile] Failed to update profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# DELETE PROFILE
# =============================================================================


@router.delete("/{profile_id}")
async def delete_gym_profile(profile_id: str):
    """
    Delete a gym profile.

    Cannot delete the last profile - users must have at least one profile.
    If deleting the active profile, another profile will be activated.
    """
    logger.info(f"🗑️ [GymProfile] Deleting profile {profile_id}")

    try:
        supabase = get_supabase()

        # Get the profile to delete
        profile_result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("id", profile_id) \
            .single() \
            .execute()

        if not profile_result.data:
            raise HTTPException(status_code=404, detail="Profile not found")

        profile = profile_result.data
        user_id = profile["user_id"]

        # Check if this is the only profile
        count_result = supabase.client.table("gym_profiles") \
            .select("id", count="exact") \
            .eq("user_id", user_id) \
            .execute()

        if count_result.count <= 1:
            raise HTTPException(
                status_code=400,
                detail="Cannot delete the last gym profile. Users must have at least one profile."
            )

        was_active = profile.get("is_active", False)

        # Delete the profile
        supabase.client.table("gym_profiles") \
            .delete() \
            .eq("id", profile_id) \
            .execute()

        # If deleted profile was active, activate another one
        if was_active:
            # Get the first profile by display order
            next_result = supabase.client.table("gym_profiles") \
                .select("id") \
                .eq("user_id", user_id) \
                .order("display_order") \
                .limit(1) \
                .execute()

            if next_result.data:
                next_profile_id = next_result.data[0]["id"]
                supabase.client.table("gym_profiles") \
                    .update({"is_active": True}) \
                    .eq("id", next_profile_id) \
                    .execute()
                supabase.client.table("users") \
                    .update({"active_gym_profile_id": next_profile_id}) \
                    .eq("id", user_id) \
                    .execute()
                logger.info(f"🔄 [GymProfile] Activated next profile {next_profile_id}")

        # Log to user context
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "gym_profile",
                "action": "deleted",
                "profile_id": profile_id,
                "profile_name": profile.get("name"),
            },
            context={"source": "gym_profiles_api"}
        )

        logger.info(f"✅ [GymProfile] Deleted profile '{profile.get('name')}' (id: {profile_id})")

        return {"success": True, "message": "Profile deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to delete profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# ACTIVATE PROFILE
# =============================================================================


@router.post("/{profile_id}/activate", response_model=ActivateProfileResponse)
async def activate_gym_profile(profile_id: str):
    """
    Activate (switch to) a gym profile.

    Deactivates all other profiles for this user and sets the specified profile as active.
    Updates the user's active_gym_profile_id.
    """
    logger.info(f"🔄 [GymProfile] Activating profile {profile_id}")

    try:
        supabase = get_supabase()

        # Get the profile to activate
        profile_result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("id", profile_id) \
            .single() \
            .execute()

        if not profile_result.data:
            raise HTTPException(status_code=404, detail="Profile not found")

        profile = profile_result.data
        user_id = profile["user_id"]

        # Get current active profile for logging
        old_active_result = supabase.client.table("gym_profiles") \
            .select("id, name") \
            .eq("user_id", user_id) \
            .eq("is_active", True) \
            .limit(1) \
            .execute()

        old_profile_name = old_active_result.data[0]["name"] if old_active_result.data else "None"

        # Deactivate all profiles for this user
        supabase.client.table("gym_profiles") \
            .update({"is_active": False}) \
            .eq("user_id", user_id) \
            .execute()

        # Activate the requested profile
        now = datetime.utcnow().isoformat()
        supabase.client.table("gym_profiles") \
            .update({"is_active": True, "updated_at": now}) \
            .eq("id", profile_id) \
            .execute()

        # Update user's active_gym_profile_id
        supabase.client.table("users") \
            .update({"active_gym_profile_id": profile_id}) \
            .eq("id", user_id) \
            .execute()

        active_profile = row_to_gym_profile(profile)
        active_profile.is_active = True

        # Log the switch
        logger.info(f"🔄 [GymProfile] Switching from '{old_profile_name}' to '{active_profile.name}'")
        logger.info(f"🏋️ [GymProfile] Active equipment: {len(active_profile.equipment)} items")
        logger.info(f"🎯 [GymProfile] Environment: {active_profile.workout_environment}")

        # Log to user context
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "gym_profile",
                "action": "activated",
                "profile_id": profile_id,
                "profile_name": active_profile.name,
                "previous_profile": old_profile_name,
                "equipment": active_profile.equipment,
                "workout_environment": active_profile.workout_environment,
            },
            context={"source": "gym_profiles_api"}
        )

        return ActivateProfileResponse(
            success=True,
            active_profile=active_profile,
            message=f"Switched to '{active_profile.name}'"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to activate profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# REORDER PROFILES
# =============================================================================


# =============================================================================
# DUPLICATE PROFILE
# =============================================================================


@router.post("/{profile_id}/duplicate", response_model=GymProfile)
async def duplicate_gym_profile(profile_id: str):
    """
    Duplicate an existing gym profile.

    Creates a copy of the profile with "(Copy)" appended to the name.
    The duplicated profile is NOT active by default.
    Display order is set to end of list.
    """
    logger.info(f"📋 [GymProfile] Duplicating profile {profile_id}")

    try:
        supabase = get_supabase()

        # Get the profile to duplicate
        profile_result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("id", profile_id) \
            .single() \
            .execute()

        if not profile_result.data:
            raise HTTPException(status_code=404, detail="Profile not found")

        source_profile = profile_result.data
        user_id = source_profile["user_id"]

        # Get max display_order for this user
        order_result = supabase.client.table("gym_profiles") \
            .select("display_order") \
            .eq("user_id", user_id) \
            .order("display_order", desc=True) \
            .limit(1) \
            .execute()

        max_order = order_result.data[0]["display_order"] if order_result.data else 0
        new_order = max_order + 1

        # Generate copy name
        base_name = source_profile["name"]
        if base_name.endswith(" (Copy)"):
            # Already a copy, add number
            copy_name = f"{base_name[:-7]} (Copy 2)"
        elif " (Copy " in base_name and base_name.endswith(")"):
            # Already has a number, increment it
            import re
            match = re.search(r" \(Copy (\d+)\)$", base_name)
            if match:
                num = int(match.group(1)) + 1
                copy_name = re.sub(r" \(Copy \d+\)$", f" (Copy {num})", base_name)
            else:
                copy_name = f"{base_name} (Copy)"
        else:
            copy_name = f"{base_name} (Copy)"

        # Create the duplicate
        now = datetime.utcnow().isoformat()
        duplicate_data = {
            "user_id": user_id,
            "name": copy_name,
            "icon": source_profile.get("icon", "fitness_center"),
            "color": source_profile.get("color", "#00BCD4"),
            "equipment": source_profile.get("equipment") or [],
            "equipment_details": source_profile.get("equipment_details") or [],
            "workout_environment": source_profile.get("workout_environment", "commercial_gym"),
            "training_split": source_profile.get("training_split"),
            "workout_days": source_profile.get("workout_days") or [],
            "duration_minutes": source_profile.get("duration_minutes", 45),
            "duration_minutes_min": source_profile.get("duration_minutes_min"),
            "duration_minutes_max": source_profile.get("duration_minutes_max"),
            "goals": source_profile.get("goals") or [],
            "focus_areas": source_profile.get("focus_areas") or [],
            "display_order": new_order,
            "is_active": False,  # Duplicates are never active by default
            "created_at": now,
            "updated_at": now,
        }

        result = supabase.client.table("gym_profiles") \
            .insert(duplicate_data) \
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to duplicate profile")

        duplicated_profile = row_to_gym_profile(result.data[0])

        # Log to user context
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "gym_profile",
                "action": "duplicated",
                "source_profile_id": profile_id,
                "source_profile_name": source_profile.get("name"),
                "new_profile_id": duplicated_profile.id,
                "new_profile_name": duplicated_profile.name,
            },
            context={"source": "gym_profiles_api"}
        )

        logger.info(f"✅ [GymProfile] Duplicated '{source_profile.get('name')}' → '{duplicated_profile.name}'")

        return duplicated_profile

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to duplicate profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# REORDER PROFILES
# =============================================================================


@router.post("/reorder")
async def reorder_gym_profiles(
    user_id: str = Query(..., description="User ID"),
    request: ReorderProfilesRequest = ...,
):
    """
    Update the display order of gym profiles.

    Expects a list of profile IDs in the desired order.
    """
    logger.info(f"↕️ [GymProfile] Reordering profiles for user {user_id}")
    logger.info(f"📋 [GymProfile] New order: {request.profile_ids}")

    try:
        supabase = get_supabase()

        # Verify all profile IDs belong to this user
        verify_result = supabase.client.table("gym_profiles") \
            .select("id") \
            .eq("user_id", user_id) \
            .execute()

        user_profile_ids = {row["id"] for row in verify_result.data or []}

        for profile_id in request.profile_ids:
            if profile_id not in user_profile_ids:
                raise HTTPException(
                    status_code=400,
                    detail=f"Profile {profile_id} does not belong to user"
                )

        # Update display_order for each profile
        now = datetime.utcnow().isoformat()
        for index, profile_id in enumerate(request.profile_ids):
            supabase.client.table("gym_profiles") \
                .update({"display_order": index, "updated_at": now}) \
                .eq("id", profile_id) \
                .execute()

        # Log to user context
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "gym_profile",
                "action": "reordered",
                "profile_ids": request.profile_ids,
            },
            context={"source": "gym_profiles_api"}
        )

        logger.info(f"✅ [GymProfile] Reordered {len(request.profile_ids)} profiles")

        return {"success": True, "message": "Profiles reordered successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to reorder profiles: {e}")
        raise HTTPException(status_code=500, detail=str(e))
