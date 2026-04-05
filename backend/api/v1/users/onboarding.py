"""
Onboarding-related endpoints: preferences, nutrition targets, fasting sync, gym profiles.
"""
from core.db import get_supabase_db
import asyncio
import json
from datetime import datetime
from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException
from core.auth import get_current_user, get_verified_auth_token, verify_user_ownership
from core.exceptions import safe_internal_error
from typing import Optional, List

from core.supabase_db import get_supabase_db
from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.username_generator import generate_username_sync
from services.admin_service import get_admin_service

from api.v1.users.models import (
    UserPreferencesRequest,
    NutritionCalculationRequest,
    NutritionMetricsResponse,
    SyncFastingRequest,
    SyncFastingResponse,
    get_default_equipment_for_environment,
    row_to_user,
    merge_extended_fields_into_preferences,
)

router = APIRouter()
logger = get_logger(__name__)


@router.post("/{user_id}/preferences")
async def save_user_preferences(user_id: str, request: UserPreferencesRequest,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Save user preferences from pre-auth quiz.

    This endpoint is called after coach selection to persist all quiz data.
    Data is merged into the user's preferences JSON and relevant columns.

    Uses get_verified_auth_token (not get_current_user) so it works even when
    the user exists in Supabase Auth but doesn't have a backend DB row yet.
    Auto-creates a minimal user record in that case.
    """
    auth_id = verified_token["auth_id"]
    email = verified_token.get("email") or ""

    logger.info(f"Saving preferences for user: id={user_id}, auth_id={auth_id}")
    actual_user_id = user_id  # fallback for error logging
    try:
        db = get_supabase_db()

        # Look up by auth_id (canonical) — the URL user_id may be stale
        existing = db.get_user_by_auth_id(auth_id)
        if not existing:
            # User in Supabase Auth but not in our DB — create a minimal record
            logger.warning(f"User not in DB for auth_id={auth_id}, auto-creating")
            user_metadata = verified_token.get("user_metadata") or {}
            full_name = (
                user_metadata.get("full_name")
                or user_metadata.get("name")
                or (request.name if hasattr(request, "name") else None)
                or email.split("@")[0]
                or "User"
            )
            unique_username = generate_username_sync(name=full_name, email=email)
            admin_service = get_admin_service()
            is_admin = admin_service.should_be_admin(email)
            is_support = admin_service.should_be_support_user(email)
            new_user_data = {
                "auth_id": auth_id,
                "email": email,
                "name": full_name,
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
            existing = db.create_user(new_user_data)
            logger.info(f"Auto-created user: id={existing['id']} for auth_id={auth_id}")

        # Use the canonical ID from the DB row (not the potentially stale URL user_id)
        actual_user_id = existing["id"]

        # Build update data
        update_data = {}

        # If coach was selected as part of this submission, mark onboarding steps complete
        # so the app doesn't loop back to onboarding even if the separate PUT call fails
        if request.coach_id is not None:
            update_data["coach_selected"] = True
            update_data["onboarding_completed"] = True
            update_data["onboarding_completed_at"] = datetime.utcnow().isoformat()

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
            request.meals_per_day,
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
            # Focus areas
            focus_areas=request.focus_areas,
        )
        update_data["preferences"] = final_preferences

        # Perform update
        logger.info(f"🔍 [DEBUG] save_user_preferences - update_data: {update_data}")
        logger.info(f"🔍 [DEBUG] save_user_preferences - equipment: {update_data.get('equipment')}")
        logger.info(f"🔍 [DEBUG] save_user_preferences - preferences: {update_data.get('preferences')}")
        if update_data:
            result = db.update_user(actual_user_id, update_data)
            logger.info(f"Saved {len(update_data)} preference fields for user {actual_user_id}")
            logger.info(f"🔍 [DEBUG] save_user_preferences - update result: {result}")

        # Log activity
        await log_user_activity(
            user_id=actual_user_id,
            action="preferences_saved",
            endpoint=f"/api/v1/users/{actual_user_id}/preferences",
            message="Pre-auth quiz preferences saved",
            metadata={"fields_count": len(update_data)},
            status_code=200
        )

        return {"success": True, "message": "Preferences saved successfully", "user_id": actual_user_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to save preferences: {e}")
        await log_user_error(
            user_id=actual_user_id,
            action="preferences_saved",
            error=e,
            endpoint=f"/api/v1/users/{user_id}/preferences",
            status_code=500
        )
        raise safe_internal_error(e, "users")


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
        verify_user_ownership(current_user, user_id)
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

        # Explicitly save nutrition_goals to nutrition_preferences.
        # The RPC saves macros/calories but does NOT update the nutrition_goals array,
        # so the profile goal always falls back to "maintain" without this explicit write.
        try:
            await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: db.client.table("nutrition_preferences").upsert(
                    {
                        "user_id": user_id,
                        "nutrition_goals": nutrition_goals,
                        "nutrition_goal": nutrition_goals[0] if nutrition_goals else "maintain",
                        "rate_of_change": request.weight_change_rate or "moderate",
                    },
                    on_conflict="user_id",
                ).execute()
            )
            logger.info(f"Saved nutrition_goals={nutrition_goals} to nutrition_preferences for user {user_id}")
        except Exception as _goal_save_err:
            logger.warning(f"Could not persist nutrition_goals to nutrition_preferences: {_goal_save_err}")

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
        verify_user_ownership(current_user, user_id)
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
        verify_user_ownership(current_user, user_id)
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


_COACH_COLORS = {
    "coach_mike": "#FF9800",    # Orange
    "dr_sarah": "#2196F3",      # Blue
    "sergeant_max": "#F44336",  # Red
    "zen_maya": "#4CAF50",      # Green
    "hype_danny": "#9C27B0",    # Purple
}


async def create_gym_profiles_from_onboarding(
    user_id: str,
    gym_name: Optional[str],
    workout_environment: Optional[str],
    equipment: list,
    equipment_details: list,
    preferences: dict,
    coach_id: Optional[str] = None,
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

    # Resolve coach color (fall back to orange — the default accent — if no coach matched)
    resolved_coach_id = coach_id or preferences.get("coach_id")
    profile_color = _COACH_COLORS.get(resolved_coach_id, "#FF9800")
    logger.info(f"🎨 [GymProfile] Coach '{resolved_coach_id}' → color {profile_color}")

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
            "color": profile_color,
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
