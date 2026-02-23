"""
Progression Settings API - User progression pace preferences and AI recommendations.

This module manages workout progression pace settings including:
- Overall and category-specific progression paces (strength, cardio, flexibility)
- Weight increment preferences
- Deload and fatigue-based adjustments
- AI-recommended pace based on user profile and history
- Safety limits for volume and weight increases

Database tables:
- user_progression_preferences: User's progression settings
- progression_pace_definitions: Available pace options with metadata

ENDPOINTS:
- GET  /api/v1/progression-settings/{user_id} - Get user's progression preferences
- PUT  /api/v1/progression-settings/{user_id} - Update user's progression preferences
- GET  /api/v1/progression-settings/pace-definitions - Get all pace definition options
- GET  /api/v1/progression-settings/{user_id}/recommendation - Get AI-recommended pace
- POST /api/v1/progression-settings/{user_id}/apply-recommendation - Apply recommended settings
- GET  /api/v1/progression-settings/{user_id}/category-paces - Get pace by category
- PUT  /api/v1/progression-settings/{user_id}/category-paces - Update category-specific paces
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date, timedelta
import logging

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.timezone_utils import resolve_timezone, get_user_today

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Pydantic Models
# =============================================================================

class ProgressionPaceDefinition(BaseModel):
    """Definition of a progression pace option."""
    pace: str
    display_name: str
    description: str
    sessions_before_increase: int
    weight_increase_percent: float
    recommended_for: List[str] = []
    icon: Optional[str] = None


class ProgressionPaceDefinitionsResponse(BaseModel):
    """Response containing all available pace definitions."""
    paces: List[ProgressionPaceDefinition]
    default_pace: str = "moderate"


class ProgressionPreferences(BaseModel):
    """User's complete progression preferences."""
    user_id: str
    overall_pace: str = "moderate"
    strength_pace: str = "moderate"
    cardio_pace: str = "slow"
    flexibility_pace: str = "moderate"
    weight_increment_kg: float = Field(default=2.5, ge=0.5, le=10.0)
    min_sessions_before_progression: int = Field(default=2, ge=1, le=10)
    require_completion_percent: int = Field(default=80, ge=50, le=100)
    auto_deload_enabled: bool = True
    deload_frequency_weeks: int = Field(default=4, ge=2, le=8)
    fatigue_based_adjustment: bool = True
    max_weekly_volume_increase_percent: int = Field(default=10, ge=5, le=20)
    max_weight_increase_percent: int = Field(default=10, ge=5, le=20)
    adjust_from_feedback: bool = True
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ProgressionPreferencesUpdate(BaseModel):
    """Request to update progression preferences."""
    overall_pace: Optional[str] = Field(default=None, pattern="^(very_slow|slow|moderate|fast)$")
    strength_pace: Optional[str] = Field(default=None, pattern="^(very_slow|slow|moderate|fast)$")
    cardio_pace: Optional[str] = Field(default=None, pattern="^(very_slow|slow|moderate|fast)$")
    flexibility_pace: Optional[str] = Field(default=None, pattern="^(very_slow|slow|moderate|fast)$")
    weight_increment_kg: Optional[float] = Field(default=None, ge=0.5, le=10.0)
    min_sessions_before_progression: Optional[int] = Field(default=None, ge=1, le=10)
    require_completion_percent: Optional[int] = Field(default=None, ge=50, le=100)
    auto_deload_enabled: Optional[bool] = None
    deload_frequency_weeks: Optional[int] = Field(default=None, ge=2, le=8)
    fatigue_based_adjustment: Optional[bool] = None
    max_weekly_volume_increase_percent: Optional[int] = Field(default=None, ge=5, le=20)
    max_weight_increase_percent: Optional[int] = Field(default=None, ge=5, le=20)
    adjust_from_feedback: Optional[bool] = None


class CategoryPacesResponse(BaseModel):
    """Response for category-specific paces."""
    user_id: str
    strength_pace: str
    cardio_pace: str
    flexibility_pace: str
    strength_description: str
    cardio_description: str
    flexibility_description: str


class CategoryPacesUpdate(BaseModel):
    """Request to update category-specific paces."""
    strength_pace: Optional[str] = Field(default=None, pattern="^(very_slow|slow|moderate|fast)$")
    cardio_pace: Optional[str] = Field(default=None, pattern="^(very_slow|slow|moderate|fast)$")
    flexibility_pace: Optional[str] = Field(default=None, pattern="^(very_slow|slow|moderate|fast)$")


class PaceRecommendation(BaseModel):
    """AI-recommended progression pace with reasoning."""
    recommended_overall_pace: str
    recommended_strength_pace: str
    recommended_cardio_pace: str
    recommended_flexibility_pace: str
    confidence: float = Field(ge=0.0, le=1.0)
    reasoning: List[str] = []
    factors_analyzed: Dict[str, Any] = {}
    warnings: List[str] = []


class PaceRecommendationResponse(BaseModel):
    """Response containing pace recommendation."""
    user_id: str
    recommendation: PaceRecommendation
    current_preferences: Optional[ProgressionPreferences] = None
    would_change: bool


class ApplyRecommendationResponse(BaseModel):
    """Response after applying recommended settings."""
    user_id: str
    applied_recommendation: PaceRecommendation
    updated_preferences: ProgressionPreferences
    message: str


# =============================================================================
# Helper Functions
# =============================================================================

def get_default_preferences(user_id: str) -> dict:
    """Get default progression preferences for a user."""
    return {
        "user_id": user_id,
        "overall_pace": "moderate",
        "strength_pace": "moderate",
        "cardio_pace": "slow",
        "flexibility_pace": "moderate",
        "weight_increment_kg": 2.5,
        "min_sessions_before_progression": 2,
        "require_completion_percent": 80,
        "auto_deload_enabled": True,
        "deload_frequency_weeks": 4,
        "fatigue_based_adjustment": True,
        "max_weekly_volume_increase_percent": 10,
        "max_weight_increase_percent": 10,
        "adjust_from_feedback": True,
    }


def get_pace_definitions() -> Dict[str, ProgressionPaceDefinition]:
    """Get all pace definitions."""
    return {
        "very_slow": ProgressionPaceDefinition(
            pace="very_slow",
            display_name="Extra Cautious",
            description="Progress only after 4+ successful sessions. Ideal for injury recovery or seniors.",
            sessions_before_increase=4,
            weight_increase_percent=2.5,
            recommended_for=["seniors", "injury_recovery", "beginners"],
            icon="turtle",
        ),
        "slow": ProgressionPaceDefinition(
            pace="slow",
            display_name="Gradual",
            description="Progress after 3 successful sessions. Safe for most beginners.",
            sessions_before_increase=3,
            weight_increase_percent=5.0,
            recommended_for=["beginners", "general"],
            icon="walk",
        ),
        "moderate": ProgressionPaceDefinition(
            pace="moderate",
            display_name="Balanced",
            description="Progress after 2 successful sessions. Standard progression.",
            sessions_before_increase=2,
            weight_increase_percent=7.5,
            recommended_for=["intermediate", "general"],
            icon="run",
        ),
        "fast": ProgressionPaceDefinition(
            pace="fast",
            display_name="Aggressive",
            description="Progress as soon as ready. For experienced athletes.",
            sessions_before_increase=1,
            weight_increase_percent=10.0,
            recommended_for=["advanced", "athletes"],
            icon="rocket",
        ),
    }


async def analyze_user_for_recommendation(user_id: str, user_tz: str = "UTC") -> Dict[str, Any]:
    """Analyze user profile for pace recommendation."""
    supabase = get_supabase()
    analysis = {
        "age": None,
        "fitness_level": None,
        "is_senior": False,
        "active_injuries_count": 0,
        "injury_severity_max": None,
        "recent_strains_count": 0,
        "strain_severity_max": None,
        "current_strain_risk": None,
        "high_risk_muscles": [],
    }

    # Get user profile
    try:
        user_result = supabase.client.table("users").select(
            "age, date_of_birth, fitness_level, preferences"
        ).eq("id", user_id).execute()

        if user_result.data:
            user = user_result.data[0]
            age = user.get("age")

            if not age and user.get("date_of_birth"):
                try:
                    dob = datetime.fromisoformat(str(user.get("date_of_birth")).replace("Z", "+00:00"))
                    age = (datetime.now(dob.tzinfo) - dob).days // 365
                except Exception:
                    pass

            analysis["age"] = age
            analysis["is_senior"] = age is not None and age >= 55
            analysis["fitness_level"] = user.get("fitness_level", "beginner")
    except Exception as e:
        logger.warning(f"Could not get user profile: {e}")

    # Get active injuries
    try:
        injuries_result = supabase.client.table("user_injuries").select(
            "id, body_part, severity, status"
        ).eq("user_id", user_id).in_("status", ["active", "recovering"]).execute()

        if injuries_result.data:
            analysis["active_injuries_count"] = len(injuries_result.data)
            severities = [i.get("severity") for i in injuries_result.data if i.get("severity")]
            if severities:
                severity_order = {"severe": 3, "moderate": 2, "mild": 1}
                max_severity = max(severities, key=lambda x: severity_order.get(x, 0))
                analysis["injury_severity_max"] = max_severity
    except Exception as e:
        logger.warning(f"Could not get injuries: {e}")

    # Get strain history
    try:
        today_date = date.fromisoformat(get_user_today(user_tz))
        ninety_days_ago = (today_date - timedelta(days=90)).isoformat()
        strain_result = supabase.client.table("strain_history").select(
            "id, body_part, severity, strain_date"
        ).eq("user_id", user_id).gte("strain_date", ninety_days_ago).execute()

        if strain_result.data:
            analysis["recent_strains_count"] = len(strain_result.data)
            severities = [s.get("severity") for s in strain_result.data if s.get("severity")]
            if severities:
                severity_order = {"severe": 3, "moderate": 2, "mild": 1}
                max_severity = max(severities, key=lambda x: severity_order.get(x, 0))
                analysis["strain_severity_max"] = max_severity
    except Exception as e:
        logger.warning(f"Could not get strain history: {e}")

    return analysis


def generate_recommendation(analysis: Dict[str, Any]) -> PaceRecommendation:
    """Generate pace recommendation based on analysis."""
    reasoning = []
    warnings = []

    fitness_level = analysis.get("fitness_level", "beginner")
    base_paces = {
        "beginner": ("slow", "slow", "very_slow", "slow"),
        "intermediate": ("moderate", "moderate", "slow", "moderate"),
        "advanced": ("moderate", "moderate", "moderate", "moderate"),
    }

    overall, strength, cardio, flexibility = base_paces.get(
        fitness_level, ("moderate", "moderate", "slow", "moderate")
    )
    reasoning.append(f"Base pace for {fitness_level} fitness level: {overall}")

    # Adjust for age
    if analysis.get("is_senior"):
        age = analysis.get("age", 55)
        if age >= 65:
            overall = "very_slow"
            strength = "very_slow"
            cardio = "very_slow"
            flexibility = "slow"
            reasoning.append(f"Adjusted to very slow pace for age {age} (65+)")
        else:
            overall = "slow" if overall in ["moderate", "fast"] else overall
            strength = "slow" if strength in ["moderate", "fast"] else strength
            cardio = "very_slow"
            reasoning.append(f"Adjusted to slower pace for senior age {age}")

    # Adjust for injuries
    injury_count = analysis.get("active_injuries_count", 0)
    injury_severity = analysis.get("injury_severity_max")

    if injury_count > 0:
        if injury_severity == "severe":
            overall = "very_slow"
            strength = "very_slow"
            cardio = "very_slow"
            flexibility = "very_slow"
            reasoning.append(f"Reduced to very slow due to {injury_count} active injuries (severe)")
            warnings.append("You have a severe active injury. Consider consulting a healthcare professional.")
        elif injury_severity == "moderate":
            overall = "slow" if overall != "very_slow" else overall
            strength = "slow" if strength != "very_slow" else strength
            cardio = "slow" if cardio != "very_slow" else cardio
            reasoning.append(f"Reduced pace due to {injury_count} active injuries (moderate)")
            warnings.append("Take extra care with your injury during workouts.")

    # Adjust for strains
    strain_count = analysis.get("recent_strains_count", 0)
    strain_severity = analysis.get("strain_severity_max")

    if strain_count >= 3:
        overall = "very_slow" if overall != "very_slow" else overall
        strength = "very_slow" if strength != "very_slow" else strength
        reasoning.append(f"Reduced to very slow due to {strain_count} strains in last 90 days")
        warnings.append("Multiple recent strains detected. Consider reducing training intensity.")
    elif strain_count >= 1 and strain_severity in ["severe", "moderate"]:
        overall = "slow" if overall in ["moderate", "fast"] else overall
        strength = "slow" if strength in ["moderate", "fast"] else strength
        reasoning.append(f"Adjusted pace due to recent {strain_severity} strain")

    # Calculate confidence
    confidence_factors = [
        analysis.get("age") is not None,
        analysis.get("fitness_level") is not None,
        True,
    ]
    confidence = sum(1 for f in confidence_factors if f) / len(confidence_factors)

    if injury_count > 0 or strain_count > 0:
        confidence = min(confidence + 0.1, 1.0)

    return PaceRecommendation(
        recommended_overall_pace=overall,
        recommended_strength_pace=strength,
        recommended_cardio_pace=cardio,
        recommended_flexibility_pace=flexibility,
        confidence=round(confidence, 2),
        reasoning=reasoning,
        factors_analyzed=analysis,
        warnings=warnings,
    )


# =============================================================================
# API Endpoints
# =============================================================================

@router.get("/pace-definitions", response_model=ProgressionPaceDefinitionsResponse)
async def get_progression_pace_definitions(
    current_user: dict = Depends(get_current_user),
):
    """Get all available progression pace definitions."""
    logger.info("Getting progression pace definitions")

    definitions = get_pace_definitions()
    paces = list(definitions.values())

    pace_order = {"very_slow": 0, "slow": 1, "moderate": 2, "fast": 3}
    paces.sort(key=lambda p: pace_order.get(p.pace, 99))

    return ProgressionPaceDefinitionsResponse(
        paces=paces,
        default_pace="moderate"
    )


@router.get("/{user_id}", response_model=ProgressionPreferences)
async def get_progression_preferences(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get user's current progression preferences."""
    logger.info(f"Getting progression preferences for user {user_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("user_progression_preferences").select("*").eq(
            "user_id", user_id
        ).execute()

        if result.data and len(result.data) > 0:
            prefs = result.data[0]
            return ProgressionPreferences(
                user_id=prefs["user_id"],
                overall_pace=prefs.get("overall_pace", "moderate"),
                strength_pace=prefs.get("strength_pace", "moderate"),
                cardio_pace=prefs.get("cardio_pace", "slow"),
                flexibility_pace=prefs.get("flexibility_pace", "moderate"),
                weight_increment_kg=float(prefs.get("weight_increment_kg", 2.5)),
                min_sessions_before_progression=prefs.get("min_sessions_before_progression", 2),
                require_completion_percent=prefs.get("require_completion_percent", 80),
                auto_deload_enabled=prefs.get("auto_deload_enabled", True),
                deload_frequency_weeks=prefs.get("deload_frequency_weeks", 4),
                fatigue_based_adjustment=prefs.get("fatigue_based_adjustment", True),
                max_weekly_volume_increase_percent=prefs.get("max_weekly_volume_increase_percent", 10),
                max_weight_increase_percent=prefs.get("max_weight_increase_percent", 10),
                adjust_from_feedback=prefs.get("adjust_from_feedback", True),
                created_at=prefs.get("created_at"),
                updated_at=prefs.get("updated_at"),
            )
        else:
            defaults = get_default_preferences(user_id)
            return ProgressionPreferences(**defaults)

    except Exception as e:
        logger.error(f"Failed to get progression preferences: {e}")
        raise safe_internal_error(e, "progression_settings")


@router.put("/{user_id}", response_model=ProgressionPreferences)
async def update_progression_preferences(user_id: str, update: ProgressionPreferencesUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update user's progression preferences."""
    logger.info(f"Updating progression preferences for user {user_id}")

    try:
        supabase = get_supabase()
        now = datetime.utcnow().isoformat()

        existing = supabase.client.table("user_progression_preferences").select(
            "id"
        ).eq("user_id", user_id).execute()

        update_data = {}
        if update.overall_pace is not None:
            update_data["overall_pace"] = update.overall_pace
        if update.strength_pace is not None:
            update_data["strength_pace"] = update.strength_pace
        if update.cardio_pace is not None:
            update_data["cardio_pace"] = update.cardio_pace
        if update.flexibility_pace is not None:
            update_data["flexibility_pace"] = update.flexibility_pace
        if update.weight_increment_kg is not None:
            update_data["weight_increment_kg"] = update.weight_increment_kg
        if update.min_sessions_before_progression is not None:
            update_data["min_sessions_before_progression"] = update.min_sessions_before_progression
        if update.require_completion_percent is not None:
            update_data["require_completion_percent"] = update.require_completion_percent
        if update.auto_deload_enabled is not None:
            update_data["auto_deload_enabled"] = update.auto_deload_enabled
        if update.deload_frequency_weeks is not None:
            update_data["deload_frequency_weeks"] = update.deload_frequency_weeks
        if update.fatigue_based_adjustment is not None:
            update_data["fatigue_based_adjustment"] = update.fatigue_based_adjustment
        if update.max_weekly_volume_increase_percent is not None:
            update_data["max_weekly_volume_increase_percent"] = update.max_weekly_volume_increase_percent
        if update.max_weight_increase_percent is not None:
            update_data["max_weight_increase_percent"] = update.max_weight_increase_percent
        if update.adjust_from_feedback is not None:
            update_data["adjust_from_feedback"] = update.adjust_from_feedback

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        update_data["updated_at"] = now

        if existing.data and len(existing.data) > 0:
            result = supabase.client.table("user_progression_preferences").update(
                update_data
            ).eq("user_id", user_id).execute()
        else:
            defaults = get_default_preferences(user_id)
            insert_data = {**defaults, **update_data, "user_id": user_id, "created_at": now}
            result = supabase.client.table("user_progression_preferences").insert(
                insert_data
            ).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update preferences")

        return await get_progression_preferences(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update progression preferences: {e}")
        raise safe_internal_error(e, "progression_settings")


@router.get("/{user_id}/recommendation", response_model=PaceRecommendationResponse)
async def get_pace_recommendation(user_id: str, request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get AI-recommended progression pace based on user profile."""
    logger.info(f"Generating pace recommendation for user {user_id}")

    try:
        user_tz = resolve_timezone(request, None, user_id)
        analysis = await analyze_user_for_recommendation(user_id, user_tz)
        recommendation = generate_recommendation(analysis)

        supabase = get_supabase()
        current_result = supabase.client.table("user_progression_preferences").select("*").eq(
            "user_id", user_id
        ).execute()

        current_prefs = None
        would_change = True

        if current_result.data and len(current_result.data) > 0:
            prefs = current_result.data[0]
            current_prefs = ProgressionPreferences(
                user_id=prefs["user_id"],
                overall_pace=prefs.get("overall_pace", "moderate"),
                strength_pace=prefs.get("strength_pace", "moderate"),
                cardio_pace=prefs.get("cardio_pace", "slow"),
                flexibility_pace=prefs.get("flexibility_pace", "moderate"),
                weight_increment_kg=float(prefs.get("weight_increment_kg", 2.5)),
                min_sessions_before_progression=prefs.get("min_sessions_before_progression", 2),
                require_completion_percent=prefs.get("require_completion_percent", 80),
                auto_deload_enabled=prefs.get("auto_deload_enabled", True),
                deload_frequency_weeks=prefs.get("deload_frequency_weeks", 4),
                fatigue_based_adjustment=prefs.get("fatigue_based_adjustment", True),
                max_weekly_volume_increase_percent=prefs.get("max_weekly_volume_increase_percent", 10),
                max_weight_increase_percent=prefs.get("max_weight_increase_percent", 10),
                adjust_from_feedback=prefs.get("adjust_from_feedback", True),
                created_at=prefs.get("created_at"),
                updated_at=prefs.get("updated_at"),
            )

            would_change = (
                current_prefs.overall_pace != recommendation.recommended_overall_pace or
                current_prefs.strength_pace != recommendation.recommended_strength_pace or
                current_prefs.cardio_pace != recommendation.recommended_cardio_pace or
                current_prefs.flexibility_pace != recommendation.recommended_flexibility_pace
            )

        return PaceRecommendationResponse(
            user_id=user_id,
            recommendation=recommendation,
            current_preferences=current_prefs,
            would_change=would_change,
        )

    except Exception as e:
        logger.error(f"Failed to generate recommendation: {e}")
        raise safe_internal_error(e, "progression_settings")


@router.post("/{user_id}/apply-recommendation", response_model=ApplyRecommendationResponse)
async def apply_pace_recommendation(user_id: str, request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Apply AI-recommended progression pace settings."""
    logger.info(f"Applying pace recommendation for user {user_id}")

    try:
        user_tz = resolve_timezone(request, None, user_id)
        analysis = await analyze_user_for_recommendation(user_id, user_tz)
        recommendation = generate_recommendation(analysis)

        update = ProgressionPreferencesUpdate(
            overall_pace=recommendation.recommended_overall_pace,
            strength_pace=recommendation.recommended_strength_pace,
            cardio_pace=recommendation.recommended_cardio_pace,
            flexibility_pace=recommendation.recommended_flexibility_pace,
        )

        updated_prefs = await update_progression_preferences(user_id, update)

        return ApplyRecommendationResponse(
            user_id=user_id,
            applied_recommendation=recommendation,
            updated_preferences=updated_prefs,
            message=f"Applied recommended {recommendation.recommended_overall_pace} pace based on your profile analysis",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to apply recommendation: {e}")
        raise safe_internal_error(e, "progression_settings")


@router.get("/{user_id}/category-paces", response_model=CategoryPacesResponse)
async def get_category_paces(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get progression pace by category."""
    logger.info(f"Getting category paces for user {user_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("user_progression_preferences").select(
            "strength_pace, cardio_pace, flexibility_pace"
        ).eq("user_id", user_id).execute()

        if result.data and len(result.data) > 0:
            prefs = result.data[0]
            strength_pace = prefs.get("strength_pace", "moderate")
            cardio_pace = prefs.get("cardio_pace", "slow")
            flexibility_pace = prefs.get("flexibility_pace", "moderate")
        else:
            strength_pace = "moderate"
            cardio_pace = "slow"
            flexibility_pace = "moderate"

        definitions = get_pace_definitions()

        return CategoryPacesResponse(
            user_id=user_id,
            strength_pace=strength_pace,
            cardio_pace=cardio_pace,
            flexibility_pace=flexibility_pace,
            strength_description=definitions.get(strength_pace, definitions["moderate"]).description,
            cardio_description=definitions.get(cardio_pace, definitions["slow"]).description,
            flexibility_description=definitions.get(flexibility_pace, definitions["moderate"]).description,
        )

    except Exception as e:
        logger.error(f"Failed to get category paces: {e}")
        raise safe_internal_error(e, "progression_settings")


@router.put("/{user_id}/category-paces", response_model=CategoryPacesResponse)
async def update_category_paces(user_id: str, update: CategoryPacesUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update category-specific progression paces."""
    logger.info(f"Updating category paces for user {user_id}")

    try:
        prefs_update = ProgressionPreferencesUpdate(
            strength_pace=update.strength_pace,
            cardio_pace=update.cardio_pace,
            flexibility_pace=update.flexibility_pace,
        )

        if update.strength_pace is None and update.cardio_pace is None and update.flexibility_pace is None:
            raise HTTPException(status_code=400, detail="At least one category pace must be provided")

        await update_progression_preferences(user_id, prefs_update)

        return await get_category_paces(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update category paces: {e}")
        raise safe_internal_error(e, "progression_settings")
