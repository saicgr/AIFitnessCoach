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


async def _post_update_side_effects(
    *,
    user_id: str,
    profile_id: str,
    profile_name: str,
    workout_days: list,
    should_regen: bool,
    user_tz,
    changes: list,
) -> None:
    """Run ALL post-commit work for a gym-profile PUT off the response path.

    This executes in a FastAPI BackgroundTask AFTER the response has been sent,
    so nothing here can stall the request or surface to the client as an error.
    Every block is independently guarded — a failure in one step must not skip
    the others, and no failure here ever affects the already-returned profile.

    Steps:
      1. (if schedule/equipment changed on the active profile) invalidate stale
         upcoming workouts + today/profile/user caches, then enqueue a 14-day
         schedule top-up so the next /today regenerates with the new config.
      2. log the update to user_context (analytics/feature-interaction event).
    """
    # ── Step 1: cache invalidation + workout regen (only when relevant) ──────
    if should_regen:
        try:
            from api.v1.workouts.today import (
                invalidate_today_workout_cache,
                _gym_profile_cache,
                _user_record_cache,
                enqueue_schedule_top_up,
            )
            from api.v1.workouts.utils import invalidate_upcoming_workouts

            # Drop pre-generated future workouts under the old config so the
            # next /today + top-up regenerate them with new days/equipment.
            try:
                deleted = invalidate_upcoming_workouts(
                    user_id=user_id,
                    gym_profile_id=profile_id,
                    reason="profile_updated",
                )
                logger.info(f"[GymProfile] Invalidated {deleted} upcoming workouts after profile edit")
            except Exception as inv_err:
                logger.warning(f"[GymProfile] Upcoming-workout invalidation failed (non-fatal): {inv_err}", exc_info=True)

            try:
                await _gym_profile_cache.delete(user_id)
                await _user_record_cache.delete(user_id)
                await invalidate_today_workout_cache(user_id, profile_id)
            except Exception as cache_err:
                logger.warning(f"[GymProfile] Cache invalidation failed (non-fatal): {cache_err}", exc_info=True)

            if workout_days and user_tz is not None:
                try:
                    await enqueue_schedule_top_up(
                        user_id=user_id,
                        gym_profile_id=profile_id,
                        workout_days=workout_days,
                        user_tz=user_tz,
                        horizon_days=14,
                    )
                    logger.info(f"📅 [GymProfile] Queued post-edit pre-gen for '{profile_name}'")
                except Exception as regen_err:
                    logger.warning(f"[GymProfile] Post-edit pre-gen enqueue failed (non-fatal): {regen_err}", exc_info=True)
        except Exception as gen_err:
            logger.warning(f"[GymProfile] Post-edit invalidation/regen block failed (non-fatal): {gen_err}", exc_info=True)

    # ── Step 2: user-context analytics event ────────────────────────────────
    try:
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "gym_profile",
                "action": "updated",
                "profile_id": profile_id,
                "profile_name": profile_name,
                "changes": changes,
            },
            context={"source": "gym_profiles_api"},
        )
    except Exception as log_err:
        logger.warning(f"[GymProfile] user_context log_event failed (non-fatal): {log_err}", exc_info=True)


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
            raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")

        # ── COMMIT POINT ─────────────────────────────────────────────────────
        # The DB write has persisted. Everything below this line is post-commit
        # side-effect work (user-context logging, cache invalidation, workout
        # regen enqueue). NONE of it may block or fail the response — it is all
        # pushed onto background_tasks so the handler returns to the client
        # immediately after the update().execute() succeeds.
        logger.info(
            f"✅ [GymProfile] Persisted update for profile {profile_id} "
            f"(user {old_profile.get('user_id')}, fields={list(update_data.keys())})"
        )

        from .gym_profiles import row_to_gym_profile
        updated_profile = row_to_gym_profile(result.data[0])

        # Log changes (cheap, in-memory — fine to compute on the response path).
        changes = []
        if update.name and update.name != old_profile.get("name"):
            changes.append(f"name: {old_profile.get('name')} → {update.name}")
        if update.equipment and update.equipment != old_profile.get("equipment"):
            changes.append(f"equipment: {len(update.equipment)} items")
        if update.workout_environment and update.workout_environment != old_profile.get("workout_environment"):
            changes.append(f"environment: {update.workout_environment}")

        if changes:
            logger.info(f"🔄 [GymProfile] Updated {profile_id}: {', '.join(changes)}")

        # Schedule-change detection stays on the response path (pure comparison,
        # no I/O); its SIDE-EFFECTS run in the background.
        schedule_changed = (
            update.workout_days is not None
            and list(update.workout_days or []) != list(old_profile.get("workout_days") or [])
        )
        equipment_changed = (
            (update.equipment is not None and update.equipment != old_profile.get("equipment"))
            or (update.equipment_details is not None and update.equipment_details != old_profile.get("equipment_details"))
        )

        user_id_val = old_profile["user_id"]
        should_regen = (schedule_changed or equipment_changed) and updated_profile.is_active

        # Resolve timezone on the request path (needs the live `request`); the
        # actual regen + cache work runs in the background.
        user_tz = None
        if should_regen:
            try:
                db = get_supabase_db()
                user_tz = resolve_timezone(request, db, user_id_val)
            except Exception as tz_err:
                logger.warning(f"[GymProfile] Timezone resolve failed (non-fatal): {tz_err}")

        # Push ALL post-commit work onto background_tasks. Wrapped so a failure
        # here can never affect the response the client already received.
        background_tasks.add_task(
            _post_update_side_effects,
            user_id=user_id_val,
            profile_id=profile_id,
            profile_name=updated_profile.name,
            workout_days=list(updated_profile.workout_days or []),
            should_regen=should_regen,
            user_tz=user_tz,
            changes=changes,
        )

        return updated_profile

    except HTTPException:
        raise
    except Exception as e:
        if "0 rows" in str(e).lower() or "no rows" in str(e).lower():
            raise HTTPException(status_code=404, detail="Profile not found")
        logger.error(f"❌ [GymProfile] Failed to update profile: {e}", exc_info=True)
        raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")


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
    Archive (soft-delete) a gym profile.

    Per-gym progress (Gravl B-series): "delete" no longer hard-deletes. It sets
    `archived_at = now()` so the gym disappears from pickers/generation but its
    `gym_profile_id` stays on every logged set, PR, and score — history remains
    attributed and filterable under "Archived". A profile can be restored via
    POST /{id}/restore.

    Cannot archive the user's LAST live (non-archived) profile — they must keep
    at least one active gym. If the archived profile was active, the next live
    profile by display_order is activated.
    """
    logger.info(f"🗑️ [GymProfile] Archiving profile {profile_id}")

    try:
        supabase = get_supabase()

        # Get the profile to archive
        profile_result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("id", profile_id) \
            .single() \
            .execute()

        if not profile_result.data:
            raise HTTPException(status_code=404, detail="Profile not found")

        profile = profile_result.data
        user_id = profile["user_id"]

        # Already archived → idempotent success (nothing to do).
        if profile.get("archived_at") is not None:
            logger.info(f"ℹ️ [GymProfile] Profile {profile_id} already archived")
            return {"success": True, "message": "Profile already archived"}

        # Count the user's LIVE (non-archived) profiles. Mirror the old
        # last-profile guard: a user must always keep at least one live gym.
        count_result = supabase.client.table("gym_profiles") \
            .select("id", count="exact") \
            .eq("user_id", user_id) \
            .is_("archived_at", "null") \
            .execute()

        if (count_result.count or 0) <= 1:
            raise HTTPException(
                status_code=400,
                detail="Can't archive your last gym. You must keep at least one active gym profile."
            )

        was_active = profile.get("is_active", False)

        # Soft-archive: stamp archived_at and clear is_active so it leaves the
        # active/picker pool but keeps all historical attribution.
        now_iso = datetime.utcnow().isoformat()
        supabase.client.table("gym_profiles") \
            .update({"archived_at": now_iso, "is_active": False, "updated_at": now_iso}) \
            .eq("id", profile_id) \
            .execute()

        # If the archived profile was active, activate the next LIVE profile.
        if was_active:
            next_result = supabase.client.table("gym_profiles") \
                .select("id") \
                .eq("user_id", user_id) \
                .is_("archived_at", "null") \
                .neq("id", profile_id) \
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
                # carousel doesn't go empty after an archive-active.
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
                        logger.info(f"📅 [GymProfile] Queued pre-gen after archive-active fallback")
                except Exception as gen_err:
                    logger.warning(f"[GymProfile] Pre-gen on archive-fallback failed (non-fatal): {gen_err}", exc_info=True)

        # Log to user context
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "gym_profile",
                "action": "archived",
                "profile_id": profile_id,
                "profile_name": profile.get("name"),
            },
            context={"source": "gym_profiles_api"}
        )

        logger.info(f"✅ [GymProfile] Archived profile '{profile.get('name')}' (id: {profile_id})")

        return {"success": True, "message": "Profile archived successfully", "archived": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to archive profile: {e}", exc_info=True)
        raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")


# =============================================================================
# RESTORE (UN-ARCHIVE) PROFILE
# =============================================================================


@router.post("/{profile_id}/restore", response_model=GymProfile)
async def restore_gym_profile(
    profile_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Restore an archived gym profile (clears `archived_at`).

    The restored profile reappears in pickers/generation. It is NOT auto-
    activated — it returns to the live pool at its existing display_order and the
    user can activate it explicitly. Idempotent for an already-live profile.
    """
    logger.info(f"♻️ [GymProfile] Restoring profile {profile_id}")

    try:
        supabase = get_supabase()

        profile_result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("id", profile_id) \
            .single() \
            .execute()

        if not profile_result.data:
            raise HTTPException(status_code=404, detail="Profile not found")

        profile = profile_result.data
        user_id = profile["user_id"]

        if profile.get("archived_at") is None:
            # Already live — return as-is (idempotent).
            from .gym_profiles import row_to_gym_profile
            return row_to_gym_profile(profile)

        now_iso = datetime.utcnow().isoformat()
        result = supabase.client.table("gym_profiles") \
            .update({"archived_at": None, "updated_at": now_iso}) \
            .eq("id", profile_id) \
            .execute()

        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "gym_profile",
                "action": "restored",
                "profile_id": profile_id,
                "profile_name": profile.get("name"),
            },
            context={"source": "gym_profiles_api"}
        )

        logger.info(f"✅ [GymProfile] Restored profile '{profile.get('name')}' (id: {profile_id})")

        from .gym_profiles import row_to_gym_profile
        row = result.data[0] if result.data else {**profile, "archived_at": None}
        return row_to_gym_profile(row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to restore profile: {e}", exc_info=True)
        raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")


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

        # An archived gym can never be the active one — the partial unique index
        # (and the trg_gym_profiles_single_active trigger) exclude it, so honouring
        # this would deactivate the user's real gym and leave them with none.
        if profile.get("archived_at"):
            raise HTTPException(
                status_code=400,
                detail="This gym is archived. Restore it before switching to it.",
            )

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
        raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")


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
            raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")

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
        raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")


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
        raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")


# =============================================================================
# TRAVEL MODE — one-tap bodyweight gym (Feature 3B)
# =============================================================================

# Equipment a travel/hotel workout can rely on anywhere. Decision: keep this
# minimal + deterministic (bodyweight + bands). NOT a config knob.
_TRAVEL_EQUIPMENT = ["bodyweight", "resistance_bands"]
_TRAVEL_PROFILE_NAME = "Travel / Hotel"
_TRAVEL_PROFILE_ICON = "hotel"
_TRAVEL_PROFILE_ENV = "hotel"
# Fallback workout days when neither the active profile nor the user record has
# a schedule (Mon / Wed / Fri — indices 0/2/4, Mon=0).
_TRAVEL_DEFAULT_DAYS = [0, 2, 4]

# Dedicated router for the LITERAL /travel-mode/activate path. It is included by
# gym_profiles.py BEFORE the dynamic /{profile_id}/activate route so Starlette's
# in-order matching can't swallow "travel-mode" as a {profile_id}. Registering
# this on the same `router` (after the dynamic activate handler) would let the
# dynamic route win — hence the separate router.
travel_router = APIRouter()


@travel_router.post("/travel-mode/activate", response_model=ActivateProfileResponse)
async def activate_travel_mode(
    request: Request,
    background_tasks: BackgroundTasks,
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
):
    """One-tap Travel Mode: find-or-restore-or-create the user's single
    bodyweight `is_travel_managed` profile, then activate it.

    Lifecycle (idempotent, NEVER creates a duplicate — guarded by the partial
    unique index in migration 2243):
      * Travel profile exists & live  → activate it.
      * Travel profile exists archived → CLEAR archived_at (restore semantics —
        does NOT insert a new row), then activate.
      * No travel profile             → create one (bodyweight + bands, hotel
        env), then activate.

    The activate path funnels through the SAME side-effects as the normal
    /{id}/activate handler: deactivate others, set users.active_gym_profile_id,
    bust today/profile caches, and enqueue a 14-day schedule top-up.

    workout_days are copied from the currently-active profile if it has any,
    else from the user record's workout_days, else Mon/Wed/Fri.

    DECOUPLED from vacation: this endpoint never reads/writes in_vacation_mode
    and does NOT bypass the card_context 'paused' card. It emits NO push.
    """
    logger.info(f"🧳 [GymProfile] Travel Mode activate requested for user {user_id}")

    try:
        supabase = get_supabase()

        # Resolve the workout_days to seed onto the travel profile: active
        # profile's days → user's days → Mon/Wed/Fri.
        travel_days: list = []
        active_result = supabase.client.table("gym_profiles") \
            .select("workout_days") \
            .eq("user_id", user_id) \
            .eq("is_active", True) \
            .is_("archived_at", "null") \
            .limit(1) \
            .execute()
        if active_result.data and (active_result.data[0].get("workout_days") or []):
            travel_days = list(active_result.data[0]["workout_days"])
        else:
            # workout_days is not a users column — it lives in preferences JSONB
            user_result = supabase.client.table("users") \
                .select("preferences") \
                .eq("id", user_id) \
                .single() \
                .execute()
            user_days = ((user_result.data or {}).get("preferences") or {}).get("workout_days") or []
            if user_days:
                travel_days = list(user_days)
        if not travel_days:
            travel_days = list(_TRAVEL_DEFAULT_DAYS)

        now_iso = datetime.utcnow().isoformat()

        # 1) Locate the (single) travel-managed profile, archived or not.
        travel_result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("user_id", user_id) \
            .eq("is_travel_managed", True) \
            .limit(1) \
            .execute()

        if travel_result.data:
            travel_profile = travel_result.data[0]
            travel_id = travel_profile["id"]

            # If archived → restore in place (clear archived_at). Reuse restore
            # semantics: NO new row.
            if travel_profile.get("archived_at") is not None:
                logger.info(f"♻️ [GymProfile] Restoring archived travel profile {travel_id}")
                supabase.client.table("gym_profiles") \
                    .update({"archived_at": None, "updated_at": now_iso}) \
                    .eq("id", travel_id) \
                    .execute()
        else:
            # 2) No travel profile → create one at end of display order.
            order_result = supabase.client.table("gym_profiles") \
                .select("display_order") \
                .eq("user_id", user_id) \
                .order("display_order", desc=True) \
                .limit(1) \
                .execute()
            max_order = order_result.data[0]["display_order"] if order_result.data else -1

            create_data = {
                "user_id": user_id,
                "name": _TRAVEL_PROFILE_NAME,
                "icon": _TRAVEL_PROFILE_ICON,
                "color": "#F59E0B",  # amber — matches the Travel Mode quick action
                "equipment": list(_TRAVEL_EQUIPMENT),
                "equipment_details": [],
                "workout_environment": _TRAVEL_PROFILE_ENV,
                "workout_days": travel_days,
                "is_travel_managed": True,
                "display_order": max_order + 1,
                "is_active": False,
                "created_at": now_iso,
                "updated_at": now_iso,
            }
            created = supabase.client.table("gym_profiles") \
                .insert(create_data) \
                .execute()
            if not created.data:
                raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")
            travel_id = created.data[0]["id"]
            logger.info(f"✅ [GymProfile] Created travel profile {travel_id} for user {user_id}")

        # 3) Activate the travel profile — same side-effects as /{id}/activate.
        # Deactivate all, activate travel, refresh days so a stale create doesn't
        # leave empty days, point users.active_gym_profile_id at it.
        supabase.client.table("gym_profiles") \
            .update({"is_active": False}) \
            .eq("user_id", user_id) \
            .execute()
        supabase.client.table("gym_profiles") \
            .update({"is_active": True, "workout_days": travel_days, "updated_at": now_iso}) \
            .eq("id", travel_id) \
            .execute()
        supabase.client.table("users") \
            .update({"active_gym_profile_id": travel_id}) \
            .eq("id", user_id) \
            .execute()

        # Reload the activated row for the response.
        final_result = supabase.client.table("gym_profiles") \
            .select("*") \
            .eq("id", travel_id) \
            .single() \
            .execute()

        from .gym_profiles import row_to_gym_profile
        active_profile = row_to_gym_profile(final_result.data)
        active_profile.is_active = True

        logger.info(f"🧳 [GymProfile] Travel Mode active: '{active_profile.name}' (id {travel_id})")

        # Cache bust + 14-day pre-gen — identical to the normal activate path.
        try:
            from api.v1.workouts.today import (
                invalidate_today_workout_cache,
                _gym_profile_cache,
                _user_record_cache,
                enqueue_schedule_top_up,
            )
            await _gym_profile_cache.delete(user_id)
            await _user_record_cache.delete(user_id)
            await invalidate_today_workout_cache(user_id, travel_id)
        except Exception as cache_err:
            logger.warning(f"[GymProfile] Travel cache invalidation failed (non-fatal): {cache_err}")

        try:
            from api.v1.workouts.today import enqueue_schedule_top_up
            db = get_supabase_db()
            user_tz = resolve_timezone(request, db, user_id)
            if travel_days:
                background_tasks.add_task(
                    enqueue_schedule_top_up,
                    user_id=user_id,
                    gym_profile_id=travel_id,
                    workout_days=travel_days,
                    user_tz=user_tz,
                    horizon_days=14,
                )
                logger.info(f"📅 [GymProfile] Queued 14-day pre-gen for Travel Mode")
        except Exception as gen_err:
            logger.warning(f"[GymProfile] Travel pre-gen enqueue failed (non-fatal): {gen_err}", exc_info=True)

        # user-context analytics event.
        try:
            await user_context_service.log_event(
                user_id=user_id,
                event_type=EventType.FEATURE_INTERACTION,
                event_data={
                    "feature": "gym_profile",
                    "action": "travel_mode_activated",
                    "profile_id": travel_id,
                    "profile_name": active_profile.name,
                    "equipment": active_profile.equipment,
                },
                context={"source": "gym_profiles_api"},
            )
        except Exception as log_err:
            logger.warning(f"[GymProfile] Travel log_event failed (non-fatal): {log_err}")

        return ActivateProfileResponse(
            success=True,
            active_profile=active_profile,
            message="Travel Mode on. Bodyweight workouts ready.",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [GymProfile] Failed to activate Travel Mode: {e}", exc_info=True)
        raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")
