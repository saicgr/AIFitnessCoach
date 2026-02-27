"""
Trophies API - Trophy and Achievement Endpoints.

Provides endpoints for:
- Trophy room summary (earned, locked, secret counts)
- List all trophies with progress
- Earned trophies
- Recently earned trophies
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from pydantic import BaseModel, Field
from enum import Enum

from core.supabase_db import get_supabase_db
from core.logger import get_logger

router = APIRouter(tags=["Trophies"])
logger = get_logger(__name__)


# ============================================
# Response Models
# ============================================

class TrophyDefinition(BaseModel):
    """Trophy definition (achievement type)."""
    id: str
    name: str
    description: str
    category: str
    icon: str
    tier: str
    tier_level: int = 1
    points: int
    threshold_value: Optional[float] = None
    threshold_unit: Optional[str] = None
    xp_reward: int = 0
    is_secret: bool = False
    is_hidden: bool = False
    hint_text: Optional[str] = None
    merch_reward: Optional[str] = None
    unlock_animation: str = "standard"
    sort_order: int = 0
    parent_achievement_id: Optional[str] = None
    rarity: str = "common"


class TrophyProgress(BaseModel):
    """Trophy with user progress."""
    trophy: TrophyDefinition
    is_earned: bool = False
    earned_at: Optional[datetime] = None
    current_value: float = 0
    progress_percentage: float = 0


class UserTrophy(BaseModel):
    """User's earned trophy."""
    id: str
    user_id: str
    achievement_id: str
    earned_at: datetime
    trigger_value: Optional[float] = None
    trigger_details: Optional[Dict[str, Any]] = None
    is_notified: bool = False
    trophy: Optional[TrophyDefinition] = None


class TrophyRoomSummary(BaseModel):
    """Trophy room summary statistics."""
    total_trophies: int = 0
    earned_trophies: int = 0
    locked_trophies: int = 0
    secret_discovered: int = 0
    total_secret: int = 0
    total_points: int = 0
    by_tier: Dict[str, int] = {}
    by_category: Dict[str, int] = {}


class TrophyFilter(str, Enum):
    """Filter options for trophy list."""
    ALL = "all"
    EARNED = "earned"
    LOCKED = "locked"
    IN_PROGRESS = "in_progress"


# ============================================
# Endpoints
# ============================================

@router.get("/trophies/{user_id}/summary", response_model=TrophyRoomSummary)
async def get_trophy_room_summary(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get trophy room summary for a user.

    Returns counts of earned, locked, secret trophies and points breakdown by tier.
    """
    logger.info(f"Getting trophy room summary for user {user_id}")

    try:
        db = get_supabase_db()

        # Get all trophy definitions
        all_trophies_result = db.client.table("achievement_types") \
            .select("id, tier, category, points, is_secret, is_hidden") \
            .execute()

        all_trophies = all_trophies_result.data or []

        # Get user's earned trophies
        earned_result = db.client.table("user_achievements") \
            .select("achievement_id") \
            .eq("user_id", user_id) \
            .execute()

        earned_ids = {row["achievement_id"] for row in (earned_result.data or [])}

        # Calculate summary
        total_trophies = len(all_trophies)
        earned_count = 0
        locked_count = 0
        secret_discovered = 0
        total_secret = 0
        total_points = 0
        by_tier: Dict[str, int] = {}
        by_category: Dict[str, int] = {}

        for trophy in all_trophies:
            trophy_id = trophy["id"]
            tier = trophy.get("tier", "bronze")
            category = trophy.get("category", "special")
            points = trophy.get("points", 0)
            is_secret = trophy.get("is_secret", False)
            is_earned = trophy_id in earned_ids

            if is_secret:
                total_secret += 1
                if is_earned:
                    secret_discovered += 1

            if is_earned:
                earned_count += 1
                total_points += points
                by_tier[tier] = by_tier.get(tier, 0) + 1
                by_category[category] = by_category.get(category, 0) + 1
            else:
                locked_count += 1

        return TrophyRoomSummary(
            total_trophies=total_trophies,
            earned_trophies=earned_count,
            locked_trophies=locked_count,
            secret_discovered=secret_discovered,
            total_secret=total_secret,
            total_points=total_points,
            by_tier=by_tier,
            by_category=by_category
        )

    except Exception as e:
        logger.error(f"Failed to get trophy summary: {e}")
        raise safe_internal_error(e, "trophies")


@router.get("/trophies/{user_id}", response_model=List[TrophyProgress])
async def get_all_trophies(
    user_id: str,
    category: Optional[str] = Query(None, description="Filter by category"),
    filter: TrophyFilter = Query(TrophyFilter.ALL, description="Filter by status"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get all trophies with progress for a user.

    Returns list of all trophies with their progress status.
    """
    logger.info(f"Getting all trophies for user {user_id}, category={category}, filter={filter}")

    try:
        db = get_supabase_db()

        # Get all trophy definitions
        query = db.client.table("achievement_types") \
            .select("*")

        if category:
            query = query.eq("category", category)

        query = query.order("sort_order", desc=False)
        all_trophies_result = query.execute()

        all_trophies = all_trophies_result.data or []

        # Get user's earned trophies
        earned_result = db.client.table("user_achievements") \
            .select("achievement_id, achieved_at, trigger_value, trigger_details") \
            .eq("user_id", user_id) \
            .execute()

        earned_map = {
            row["achievement_id"]: {
                "earned_at": row.get("achieved_at"),
                "trigger_value": row.get("trigger_value"),
            }
            for row in (earned_result.data or [])
        }

        # Get user's progress toward trophies
        progress_result = db.client.table("trophy_progress") \
            .select("achievement_id, current_value") \
            .eq("user_id", user_id) \
            .execute()

        progress_map = {
            row["achievement_id"]: row.get("current_value", 0)
            for row in (progress_result.data or [])
        }

        # Build trophy progress list
        result = []
        for trophy in all_trophies:
            trophy_id = trophy["id"]
            is_earned = trophy_id in earned_map
            is_hidden = trophy.get("is_hidden", False)

            # Get progress
            current_value = progress_map.get(trophy_id, 0)
            if is_earned:
                current_value = trophy.get("threshold_value", 0) or 0

            threshold = trophy.get("threshold_value") or 0
            progress_pct = (current_value / threshold * 100) if threshold > 0 else 0
            progress_pct = min(progress_pct, 100)  # Cap at 100%

            # Apply filter
            if filter == TrophyFilter.EARNED and not is_earned:
                continue
            if filter == TrophyFilter.LOCKED and is_earned:
                continue
            if filter == TrophyFilter.IN_PROGRESS and (is_earned or progress_pct == 0):
                continue

            trophy_def = TrophyDefinition(
                id=trophy["id"],
                name=trophy.get("name", "Unknown"),
                description=trophy.get("description", ""),
                category=trophy.get("category", "special"),
                icon=trophy.get("icon", "🏆"),
                tier=trophy.get("tier", "bronze"),
                tier_level=trophy.get("tier_level", 1),
                points=trophy.get("points", 0),
                threshold_value=trophy.get("threshold_value"),
                threshold_unit=trophy.get("threshold_unit"),
                xp_reward=trophy.get("xp_reward", 0),
                is_secret=trophy.get("is_secret", False),
                is_hidden=trophy.get("is_hidden", False),
                hint_text=trophy.get("hint_text"),
                merch_reward=trophy.get("merch_reward"),
                unlock_animation=trophy.get("unlock_animation", "standard"),
                sort_order=trophy.get("sort_order", 0),
                parent_achievement_id=trophy.get("parent_achievement_id"),
                rarity=trophy.get("rarity", "common")
            )

            earned_at = None
            if is_earned and earned_map[trophy_id].get("earned_at"):
                try:
                    earned_at = datetime.fromisoformat(
                        earned_map[trophy_id]["earned_at"].replace("Z", "+00:00")
                    )
                except Exception as e:
                    logger.debug(f"Failed to parse earned_at date: {e}")
                    earned_at = None

            result.append(TrophyProgress(
                trophy=trophy_def,
                is_earned=is_earned,
                earned_at=earned_at,
                current_value=current_value,
                progress_percentage=progress_pct if not is_earned else 100
            ))

        # Sort: earned first, then by progress, then by tier
        result.sort(key=lambda x: (
            not x.is_earned,  # Earned first
            -x.progress_percentage,  # Higher progress first
            x.trophy.tier_level  # Lower tier first
        ))

        return result

    except Exception as e:
        logger.error(f"Failed to get all trophies: {e}")
        raise safe_internal_error(e, "trophies")


@router.get("/trophies/{user_id}/earned", response_model=List[UserTrophy])
async def get_earned_trophies(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all earned trophies for a user.

    Returns list of user's earned trophies with trophy details.
    """
    logger.info(f"Getting earned trophies for user {user_id}")

    try:
        db = get_supabase_db()

        # Get earned trophies with achievement details
        earned_result = db.client.table("user_achievements") \
            .select("*, achievement_types(*)") \
            .eq("user_id", user_id) \
            .order("achieved_at", desc=True) \
            .execute()

        result = []
        for row in (earned_result.data or []):
            trophy_data = row.get("achievement_types")
            trophy_def = None

            if trophy_data:
                trophy_def = TrophyDefinition(
                    id=trophy_data["id"],
                    name=trophy_data.get("name", "Unknown"),
                    description=trophy_data.get("description", ""),
                    category=trophy_data.get("category", "special"),
                    icon=trophy_data.get("icon", "🏆"),
                    tier=trophy_data.get("tier", "bronze"),
                    tier_level=trophy_data.get("tier_level", 1),
                    points=trophy_data.get("points", 0),
                    threshold_value=trophy_data.get("threshold_value"),
                    threshold_unit=trophy_data.get("threshold_unit"),
                    xp_reward=trophy_data.get("xp_reward", 0),
                    is_secret=trophy_data.get("is_secret", False),
                    is_hidden=trophy_data.get("is_hidden", False),
                    hint_text=trophy_data.get("hint_text"),
                    merch_reward=trophy_data.get("merch_reward"),
                    unlock_animation=trophy_data.get("unlock_animation", "standard"),
                    sort_order=trophy_data.get("sort_order", 0),
                    parent_achievement_id=trophy_data.get("parent_achievement_id"),
                    rarity=trophy_data.get("rarity", "common")
                )

            earned_at = datetime.now()
            if row.get("achieved_at"):
                try:
                    earned_at = datetime.fromisoformat(
                        row["achieved_at"].replace("Z", "+00:00")
                    )
                except Exception as e:
                    logger.debug(f"Failed to parse achieved_at date: {e}")

            result.append(UserTrophy(
                id=row.get("id", ""),
                user_id=row.get("user_id", user_id),
                achievement_id=row.get("achievement_id", ""),
                earned_at=earned_at,
                trigger_value=row.get("trigger_value"),
                trigger_details=row.get("trigger_details"),
                is_notified=row.get("is_notified", False),
                trophy=trophy_def
            ))

        return result

    except Exception as e:
        logger.error(f"Failed to get earned trophies: {e}")
        raise safe_internal_error(e, "trophies")


@router.get("/trophies/{user_id}/recent", response_model=List[UserTrophy])
async def get_recent_trophies(
    user_id: str,
    limit: int = Query(5, ge=1, le=20, description="Number of recent trophies to return"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get recently earned trophies for celebration/notification.

    Returns trophies earned in the last 7 days.
    """
    logger.info(f"Getting recent trophies for user {user_id}, limit={limit}")

    try:
        db = get_supabase_db()

        # Get recent trophies (last 7 days)
        cutoff = (datetime.now() - timedelta(days=7)).isoformat()

        earned_result = db.client.table("user_achievements") \
            .select("*, achievement_types(*)") \
            .eq("user_id", user_id) \
            .gte("achieved_at", cutoff) \
            .order("achieved_at", desc=True) \
            .limit(limit) \
            .execute()

        result = []
        for row in (earned_result.data or []):
            trophy_data = row.get("achievement_types")
            trophy_def = None

            if trophy_data:
                trophy_def = TrophyDefinition(
                    id=trophy_data["id"],
                    name=trophy_data.get("name", "Unknown"),
                    description=trophy_data.get("description", ""),
                    category=trophy_data.get("category", "special"),
                    icon=trophy_data.get("icon", "🏆"),
                    tier=trophy_data.get("tier", "bronze"),
                    tier_level=trophy_data.get("tier_level", 1),
                    points=trophy_data.get("points", 0),
                    threshold_value=trophy_data.get("threshold_value"),
                    threshold_unit=trophy_data.get("threshold_unit"),
                    xp_reward=trophy_data.get("xp_reward", 0),
                    is_secret=trophy_data.get("is_secret", False),
                    is_hidden=trophy_data.get("is_hidden", False),
                    hint_text=trophy_data.get("hint_text"),
                    merch_reward=trophy_data.get("merch_reward"),
                    unlock_animation=trophy_data.get("unlock_animation", "standard"),
                    sort_order=trophy_data.get("sort_order", 0),
                    parent_achievement_id=trophy_data.get("parent_achievement_id"),
                    rarity=trophy_data.get("rarity", "common")
                )

            earned_at = datetime.now()
            if row.get("achieved_at"):
                try:
                    earned_at = datetime.fromisoformat(
                        row["achieved_at"].replace("Z", "+00:00")
                    )
                except Exception as e:
                    logger.debug(f"Failed to parse achieved_at date: {e}")

            result.append(UserTrophy(
                id=row.get("id", ""),
                user_id=row.get("user_id", user_id),
                achievement_id=row.get("achievement_id", ""),
                earned_at=earned_at,
                trigger_value=row.get("trigger_value"),
                trigger_details=row.get("trigger_details"),
                is_notified=row.get("is_notified", False),
                trophy=trophy_def
            ))

        return result

    except Exception as e:
        logger.error(f"Failed to get recent trophies: {e}")
        raise safe_internal_error(e, "trophies")


@router.post("/trophies/{user_id}/mark-notified")
async def mark_trophies_notified(
    user_id: str,
    achievement_ids: List[str],
    current_user: dict = Depends(get_current_user),
):
    """
    Mark trophies as notified (user has seen the celebration).

    Used to prevent showing the same celebration multiple times.
    """
    logger.info(f"Marking {len(achievement_ids)} trophies as notified for user {user_id}")

    try:
        db = get_supabase_db()

        for achievement_id in achievement_ids:
            db.client.table("user_achievements") \
                .update({"is_notified": True}) \
                .eq("user_id", user_id) \
                .eq("achievement_id", achievement_id) \
                .execute()

        return {
            "success": True,
            "marked_count": len(achievement_ids)
        }

    except Exception as e:
        logger.error(f"Failed to mark trophies as notified: {e}")
        raise safe_internal_error(e, "trophies")


# ============================================
# Trophy Check Endpoints
# ============================================

class TrophyCheckResponse(BaseModel):
    """Response for trophy check endpoint."""
    trophies_awarded: List[Dict[str, Any]] = []
    count: int = 0


@router.post("/trophies/{user_id}/check-all", response_model=TrophyCheckResponse)
async def check_all_user_trophies(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Check all trophy categories for a user and award any earned trophies.

    This is useful for:
    - Backfilling trophies for existing users
    - Manual refresh from the app
    - Catching any missed trophies

    Returns list of newly awarded trophies.
    """
    logger.info(f"Checking all trophies for user {user_id}")

    try:
        from api.v1.trophy_triggers import check_all_trophies

        awarded = await check_all_trophies(user_id)

        return TrophyCheckResponse(
            trophies_awarded=awarded,
            count=len(awarded)
        )

    except Exception as e:
        logger.error(f"Failed to check trophies: {e}")
        raise safe_internal_error(e, "trophies")


@router.post("/trophies/{user_id}/check-workout")
async def check_workout_trophies(
    user_id: str,
    workout_data: Dict[str, Any] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Check trophies after workout completion.

    Should be called after a workout is logged.
    Checks volume, time, consistency, and exercise mastery trophies.
    """
    logger.info(f"Checking workout trophies for user {user_id}")

    try:
        from api.v1.trophy_triggers import check_workout_completion_trophies

        workout_data = workout_data or {}
        awarded = await check_workout_completion_trophies(user_id, workout_data)

        return {
            "trophies_awarded": awarded,
            "count": len(awarded)
        }

    except Exception as e:
        logger.error(f"Failed to check workout trophies: {e}")
        raise safe_internal_error(e, "trophies")


# ============================================
# XP Endpoints (User XP Data)
# ============================================

class UserXPResponse(BaseModel):
    """User XP data response."""
    user_id: str
    total_xp: int = 0
    current_level: int = 1
    xp_in_current_level: int = 0
    xp_to_next_level: int = 25  # Level 1 -> 2 requires 25 XP (migration 227)
    xp_title: str = "Beginner"
    progress_fraction: float = 0.0


@router.get("/xp/{user_id}", response_model=UserXPResponse)
async def get_user_xp(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's XP and level data.

    Returns current XP, level, title, and progress to next level.
    """
    logger.info(f"Getting XP data for user {user_id}")

    try:
        db = get_supabase_db()

        # Get user XP from user_xp table
        xp_result = db.client.table("user_xp") \
            .select("*") \
            .eq("user_id", user_id) \
            .single() \
            .execute()

        if xp_result.data:
            data = xp_result.data
            total_xp = data.get("total_xp", 0)
            current_level = data.get("current_level", 1)

            # Calculate XP within current level and XP to next level
            # Using unified 250-level progressive system (migration 227)
            xp_for_current_level = _calculate_total_xp_for_level(current_level)
            xp_needed = _get_xp_for_level(current_level)

            xp_in_current = total_xp - xp_for_current_level
            # Ensure xp_in_current is not negative (can happen if level was manually set)
            xp_in_current = max(0, xp_in_current)

            progress = xp_in_current / xp_needed if xp_needed > 0 else 0

            # Determine title based on level
            xp_title = _get_xp_title(current_level)

            return UserXPResponse(
                user_id=user_id,
                total_xp=total_xp,
                current_level=current_level,
                xp_in_current_level=xp_in_current,
                xp_to_next_level=xp_needed,
                xp_title=xp_title,
                progress_fraction=min(progress, 1.0)
            )
        else:
            # Return default for new users (migration 227 values)
            return UserXPResponse(
                user_id=user_id,
                total_xp=0,
                current_level=1,
                xp_in_current_level=0,
                xp_to_next_level=25,  # Level 1 -> 2 requires 25 XP
                xp_title="Beginner",
                progress_fraction=0.0
            )

    except Exception as e:
        logger.error(f"Failed to get user XP: {e}")
        # Return default on error (migration 227 values)
        return UserXPResponse(
            user_id=user_id,
            total_xp=0,
            current_level=1,
            xp_in_current_level=0,
            xp_to_next_level=25,  # Level 1 -> 2 requires 25 XP
            xp_title="Beginner",
            progress_fraction=0.0
        )


# ============================================
# Unified XP System (Migration 227)
# ============================================
# 250-level progressive XP system with 11 tiers

# XP required for each level (1-175), levels 176-250 are flat 100,000 XP
_XP_TABLE = [
    # Levels 1-10 (Beginner): Quick early wins
    25, 30, 40, 50, 65, 80, 100, 120, 150, 180,
    # Levels 11-25 (Novice)
    200, 220, 240, 260, 280, 300, 320, 340, 360, 380, 400, 420, 440, 460, 500,
    # Levels 26-50 (Apprentice)
    550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300, 1350, 1400, 1450, 1500, 1550, 1600, 1650, 1700, 1800,
    # Levels 51-75 (Athlete)
    1900, 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800, 3900, 4000, 4100, 4200, 4500,
    # Levels 76-100 (Elite)
    4800, 5000, 5200, 5400, 5600, 5800, 6000, 6200, 6400, 6600, 6800, 7000, 7200, 7400, 7600, 7800, 8000, 8200, 8400, 8600, 8800, 9000, 9200, 9400, 10000,
    # Levels 101-125 (Master)
    10500, 11000, 11500, 12000, 12500, 13000, 13500, 14000, 14500, 15000, 15500, 16000, 16500, 17000, 17500, 18000, 18500, 19000, 19500, 20000, 20500, 21000, 21500, 22000, 23000,
    # Levels 126-150 (Champion)
    24000, 25000, 26000, 27000, 28000, 29000, 30000, 31000, 32000, 33000, 34000, 35000, 36000, 37000, 38000, 39000, 40000, 41000, 42000, 43000, 44000, 45000, 46000, 47000, 50000,
    # Levels 151-175 (Legend)
    52000, 54000, 56000, 58000, 60000, 62000, 64000, 66000, 68000, 70000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000, 88000, 90000, 92000, 94000, 96000, 98000, 100000
]


def _get_xp_for_level(level: int) -> int:
    """Get XP required to complete the given level (level up to next).

    Uses unified 250-level progressive system (migration 227).
    """
    if level >= 250:
        return 0  # Max level
    elif level <= 175:
        return _XP_TABLE[level - 1]
    else:
        # Levels 176-250 are flat 100,000 XP each (prestige tier)
        return 100000


def _calculate_total_xp_for_level(level: int) -> int:
    """Calculate total XP required to reach the given level.

    Uses unified 250-level progressive system (migration 227).
    """
    total = 0
    for l in range(1, level):
        total += _get_xp_for_level(l)
    return total


def _get_xp_title(level: int) -> str:
    """Get XP title based on level.

    11 tiers from Beginner to Transcendent (migration 227).
    """
    if level <= 10:
        return "Beginner"
    elif level <= 25:
        return "Novice"
    elif level <= 50:
        return "Apprentice"
    elif level <= 75:
        return "Athlete"
    elif level <= 100:
        return "Elite"
    elif level <= 125:
        return "Master"
    elif level <= 150:
        return "Champion"
    elif level <= 175:
        return "Legend"
    elif level <= 200:
        return "Mythic"
    elif level <= 225:
        return "Immortal"
    else:
        return "Transcendent"
