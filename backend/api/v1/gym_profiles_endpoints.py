"""Secondary endpoints for gym_profiles.  Sub-router included by main module.
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
from typing import Optional
from datetime import datetime
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, Request
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.timezone_utils import resolve_timezone
from models.gym_profile import (
    GymProfile, GymProfileCreate, GymProfileUpdate,
    GymProfileWithStats, GymProfileListResponse,
    ReorderProfilesRequest, ActivateProfileResponse,
    DuplicateProfileRequest,
)
from core.supabase_client import get_supabase
from services.user_context_service import user_context_service, EventType

router = APIRouter()
@router.put("/{profile_id}", response_model=GymProfile)
async def update_gym_profile(
    profile_id: str, update: GymProfileUpdate,
    request: Request,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
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
        # Location fields
        if update.address is not None:
            update_data["address"] = update.address
        if update.city is not None:
            update_data["city"] = update.city
        if update.latitude is not None:
            update_data["latitude"] = update.latitude
        if update.longitude is not None:
            update_data["longitude"] = update.longitude
        if update.place_id is not None:
            update_data["place_id"] = update.place_id
        if update.location_radius_meters is not None:
            update_data["location_radius_meters"] = update.location_radius_meters
        if update.auto_switch_enabled is not None:
            update_data["auto_switch_enabled"] = update.auto_switch_enabled
        # Workout preferences
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
            raise safe_internal_error(e, "endpoint")

        from .gym_profiles import row_to_gym_profile
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

        # If schedule-impacting fields changed AND this is the active profile,
        # invalidate stale future workouts (not started, not completed) and
        # refill the 14-day horizon. Today's already-started workout is left
        # alone via the is_completed=False + status checks in the helper.
        schedule_changed = (
            update.workout_days is not None
            and list(update.workout_days or []) != list(old_profile.get("workout_days") or [])
        )
        equipment_changed = (
            (update.equipment is not None and update.equipment != old_profile.get("equipment"))
            or (update.equipment_details is not None and update.equipment_details != old_profile.get("equipment_details"))
        )
        if (schedule_changed or equipment_changed) and updated_profile.is_active:
            try:
                from api.v1.workouts.today import (
                    invalidate_today_workout_cache,
                    _gym_profile_cache,
                    _user_record_cache,
                    enqueue_schedule_top_up,
                )
                from api.v1.workouts.utils import invalidate_upcoming_workouts

                user_id_val = old_profile["user_id"]
                # Drop pre-generated future workouts under the old config so
                # the next /today + top-up regenerate them with new days/equipment.
                deleted = invalidate_upcoming_workouts(
                    user_id=user_id_val,
                    gym_profile_id=profile_id,
                    reason="profile_updated",
                )
                logger.info(f"[GymProfile] Invalidated {deleted} upcoming workouts after profile edit")

                await _gym_profile_cache.delete(user_id_val)
                await _user_record_cache.delete(user_id_val)
                await invalidate_today_workout_cache(user_id_val, profile_id)

                workout_days = updated_profile.workout_days or []
                if workout_days:
                    db = get_supabase_db()
                    user_tz = resolve_timezone(request, db, user_id_val)
                    background_tasks.add_task(
                        enqueue_schedule_top_up,
                        user_id=user_id_val,
                        gym_profile_id=profile_id,
                        workout_days=workout_days,
                        user_tz=user_tz,
                        horizon_days=14,
                    )
                    logger.info(f"📅 [GymProfile] Queued post-edit pre-gen for '{updated_profile.name}'")
            except Exception as gen_err:
                logger.warning(f"[GymProfile] Post-edit invalidation/regen failed (non-fatal): {gen_err}", exc_info=True)

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
        logger.error(f"❌ [GymProfile] Failed to update profile: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# DELETE PROFILE
# =============================================================================


@router.delete("/{profile_id}")
async def delete_gym_profile(
    profile_id: str,
    request: Request,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
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

                # Refill 14 days for the newly active profile so the home
                # carousel doesn't go empty after a delete-active.
                try:
                    from api.v1.workouts.today import (
                        invalidate_today_workout_cache,
                        _gym_profile_cache,
                        _user_record_cache,
                        enqueue_schedule_top_up,
                    )
                    await _gym_profile_cache.delete(user_id)
                    await _user_record_cache.delete(user_id)
                    await invalidate_today_workout_cache(user_id, next_profile_id)

                    next_full = supabase.client.table("gym_profiles") \
                        .select("workout_days") \
                        .eq("id", next_profile_id) \
                        .single() \
                        .execute()
                    next_workout_days = (next_full.data or {}).get("workout_days") or []
                    if next_workout_days:
                        db = get_supabase_db()
                        user_tz = resolve_timezone(request, db, user_id)
                        background_tasks.add_task(
                            enqueue_schedule_top_up,
                            user_id=user_id,
                            gym_profile_id=next_profile_id,
                            workout_days=next_workout_days,
                            user_tz=user_tz,
                            horizon_days=14,
                        )
                        logger.info(f"📅 [GymProfile] Queued pre-gen after delete-active fallback")
                except Exception as gen_err:
                    logger.warning(f"[GymProfile] Pre-gen on delete-fallback failed (non-fatal): {gen_err}", exc_info=True)

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
        logger.error(f"❌ [GymProfile] Failed to delete profile: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# ACTIVATE PROFILE
# =============================================================================


@router.post("/{profile_id}/activate", response_model=ActivateProfileResponse)
async def activate_gym_profile(
    profile_id: str,
    request: Request,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
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

        from .gym_profiles import row_to_gym_profile
        active_profile = row_to_gym_profile(profile)
        active_profile.is_active = True

        # Log the switch
        logger.info(f"🔄 [GymProfile] Switching from '{old_profile_name}' to '{active_profile.name}'")
        logger.info(f"🏋️ [GymProfile] Active equipment: {len(active_profile.equipment)} items")
        logger.info(f"🎯 [GymProfile] Environment: {active_profile.workout_environment}")

        # Bust the today/profile caches so the next /today read sees the new
        # active profile immediately instead of serving the previous one's
        # cached response.
        try:
            from api.v1.workouts.today import (
                invalidate_today_workout_cache,
                _gym_profile_cache,
                _user_record_cache,
                enqueue_schedule_top_up,
            )
            await _gym_profile_cache.delete(user_id)
            await _user_record_cache.delete(user_id)
            await invalidate_today_workout_cache(user_id, profile_id)
        except Exception as cache_err:
            logger.warning(f"[GymProfile] Cache invalidation failed (non-fatal): {cache_err}")

        # Background: pre-generate the next 14 days of workouts for the new
        # profile. Uses the profile's workout_days schedule and equipment.
        # Does not block the activate response — Sequential generation can
        # take ~10-30s depending on Gemini latency.
        try:
            db = get_supabase_db()
            user_tz = resolve_timezone(request, db, user_id)
            workout_days = active_profile.workout_days or []
            if workout_days:
                background_tasks.add_task(
                    enqueue_schedule_top_up,
                    user_id=user_id,
                    gym_profile_id=profile_id,
                    workout_days=workout_days,
                    user_tz=user_tz,
                    horizon_days=14,
                )
                logger.info(f"📅 [GymProfile] Queued 14-day pre-generation for '{active_profile.name}'")
            else:
                logger.info(f"⚠️  [GymProfile] '{active_profile.name}' has no workout_days set; skipping pre-gen")
        except Exception as gen_err:
            logger.warning(f"[GymProfile] Pre-gen scheduling failed (non-fatal): {gen_err}", exc_info=True)

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
        logger.error(f"❌ [GymProfile] Failed to activate profile: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# REORDER PROFILES
# =============================================================================


# =============================================================================
# DUPLICATE PROFILE
# =============================================================================


@router.post("/{profile_id}/duplicate", response_model=GymProfile)
async def duplicate_gym_profile(
    profile_id: str,
    request: Optional[DuplicateProfileRequest] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Duplicate an existing gym profile.

    Creates a copy of the profile with the specified name or "(Copy)" appended.
    The duplicated profile is NOT active by default.
    Display order is set to end of list.
    Fails if a profile with the same name already exists.
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

        # Use custom name if provided, otherwise generate copy name
        if request and request.name:
            copy_name = request.name.strip()
            # Check if name already exists
            existing_result = supabase.client.table("gym_profiles") \
                .select("id") \
                .eq("user_id", user_id) \
                .ilike("name", copy_name) \
                .execute()
            if existing_result.data:
                raise HTTPException(
                    status_code=409,
                    detail=f"A gym profile named '{copy_name}' already exists"
                )
        else:
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
            raise safe_internal_error(e, "endpoint")

        from .gym_profiles import row_to_gym_profile
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
        logger.error(f"❌ [GymProfile] Failed to duplicate profile: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# REORDER PROFILES
# =============================================================================


@router.post("/reorder")
async def reorder_gym_profiles(
    user_id: str = Query(..., description="User ID"),
    request: ReorderProfilesRequest = ...,
    current_user: dict = Depends(get_current_user),
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
        logger.error(f"❌ [GymProfile] Failed to reorder profiles: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")
