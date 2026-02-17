"""
Achievements and Milestones API endpoints.

Tracks user achievements like:
- Personal Records (PRs)
- Weight milestones
- Workout consistency streaks
- Habit streaks (hydration, protein, sleep)
"""

from fastapi import APIRouter, HTTPException
from typing import List, Optional
from datetime import datetime, date, timedelta

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.schemas import (
    AchievementType, UserAchievement, UserStreak, PersonalRecord,
    AchievementsSummary, NewAchievementNotification
)

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# In-memory cache for static achievement types (1-hour TTL)
# ============================================
_achievement_types_cache: Optional[dict] = None  # {"fetched_at": datetime, "all": [...], "by_category": {...}}
_ACHIEVEMENT_CACHE_TTL = timedelta(hours=1)


def _get_cached_types() -> Optional[dict]:
    """Return cached achievement types if still valid."""
    if _achievement_types_cache and (
        datetime.utcnow() - _achievement_types_cache["fetched_at"] < _ACHIEVEMENT_CACHE_TTL
    ):
        return _achievement_types_cache
    return None


def _build_types_cache(rows: list) -> dict:
    """Build the cache dict from raw DB rows."""
    all_types = [
        AchievementType(
            id=a["id"],
            name=a["name"],
            description=a["description"],
            category=a["category"],
            icon=a["icon"],
            tier=a["tier"],
            points=a["points"],
            threshold_value=a.get("threshold_value"),
            threshold_unit=a.get("threshold_unit"),
            is_repeatable=a.get("is_repeatable", False),
        )
        for a in rows
    ]
    by_category: dict = {}
    for t in all_types:
        by_category.setdefault(t.category, []).append(t)
    return {"fetched_at": datetime.utcnow(), "all": all_types, "by_category": by_category}


async def _ensure_types_cached() -> dict:
    """Ensure achievement types are cached, fetching from DB if needed."""
    global _achievement_types_cache
    cached = _get_cached_types()
    if cached:
        return cached
    db = get_supabase_db()
    result = db.client.table("achievement_types").select("*").execute()
    _achievement_types_cache = _build_types_cache(result.data or [])
    return _achievement_types_cache


# ============================================
# Achievement Types Endpoints
# ============================================

@router.get("/types", response_model=List[AchievementType])
async def get_all_achievement_types():
    """Get all available achievement types (cached for 1 hour)."""
    logger.info("Getting all achievement types")

    try:
        cache = await _ensure_types_cached()
        return cache["all"]

    except Exception as e:
        logger.error(f"Failed to get achievement types: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/types/category/{category}", response_model=List[AchievementType])
async def get_achievements_by_category(category: str):
    """Get achievement types by category (cached for 1 hour)."""
    logger.info(f"Getting achievements for category: {category}")

    try:
        cache = await _ensure_types_cached()
        return cache["by_category"].get(category, [])

    except Exception as e:
        logger.error(f"Failed to get achievements by category: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# User Achievements Endpoints
# ============================================

@router.get("/user/{user_id}", response_model=List[UserAchievement])
async def get_user_achievements(user_id: str):
    """Get all achievements earned by a user."""
    logger.info(f"Getting achievements for user: {user_id}")

    try:
        db = get_supabase_db()

        # Get user achievements with joined achievement type info
        result = db.client.table("user_achievements").select(
            "*, achievement_types(*)"
        ).eq("user_id", user_id).order("earned_at", desc=True).execute()

        achievements = []
        for ua in result.data:
            achievement_type = None
            if ua.get("achievement_types"):
                at = ua["achievement_types"]
                achievement_type = AchievementType(
                    id=at["id"],
                    name=at["name"],
                    description=at["description"],
                    category=at["category"],
                    icon=at["icon"],
                    tier=at["tier"],
                    points=at["points"],
                    threshold_value=at.get("threshold_value"),
                    threshold_unit=at.get("threshold_unit"),
                    is_repeatable=at.get("is_repeatable", False)
                )

            achievements.append(UserAchievement(
                id=str(ua["id"]),
                user_id=ua["user_id"],
                achievement_id=ua["achievement_id"],
                earned_at=ua["earned_at"],
                trigger_value=ua.get("trigger_value"),
                trigger_details=ua.get("trigger_details"),
                is_notified=ua.get("is_notified", False),
                achievement=achievement_type
            ))

        return achievements

    except Exception as e:
        logger.error(f"Failed to get user achievements: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}/summary", response_model=AchievementsSummary)
async def get_achievements_summary(user_id: str):
    """Get a summary of user's achievements, streaks, and PRs."""
    logger.info(f"Getting achievements summary for user: {user_id}")

    try:
        db = get_supabase_db()

        # Get all achievements with type info
        achievements_result = db.client.table("user_achievements").select(
            "*, achievement_types(*)"
        ).eq("user_id", user_id).order("earned_at", desc=True).execute()

        # Get current streaks
        streaks_result = db.client.table("user_streaks").select("*").eq(
            "user_id", user_id
        ).execute()

        # Get recent PRs
        prs_result = db.client.table("personal_records").select("*").eq(
            "user_id", user_id
        ).order("achieved_at", desc=True).limit(10).execute()

        # Calculate totals
        total_points = 0
        achievements_by_category = {}
        recent_achievements = []

        for ua in achievements_result.data:
            at = ua.get("achievement_types", {})
            if at:
                total_points += at.get("points", 0)
                cat = at.get("category", "other")
                achievements_by_category[cat] = achievements_by_category.get(cat, 0) + 1

            achievement_type = None
            if at:
                achievement_type = AchievementType(
                    id=at["id"],
                    name=at["name"],
                    description=at["description"],
                    category=at["category"],
                    icon=at["icon"],
                    tier=at["tier"],
                    points=at["points"],
                    threshold_value=at.get("threshold_value"),
                    threshold_unit=at.get("threshold_unit"),
                    is_repeatable=at.get("is_repeatable", False)
                )

            if len(recent_achievements) < 5:
                recent_achievements.append(UserAchievement(
                    id=str(ua["id"]),
                    user_id=ua["user_id"],
                    achievement_id=ua["achievement_id"],
                    earned_at=ua["earned_at"],
                    trigger_value=ua.get("trigger_value"),
                    trigger_details=ua.get("trigger_details"),
                    is_notified=ua.get("is_notified", False),
                    achievement=achievement_type
                ))

        # Build streaks list
        current_streaks = [
            UserStreak(
                id=str(s["id"]),
                user_id=s["user_id"],
                streak_type=s["streak_type"],
                current_streak=s["current_streak"],
                longest_streak=s["longest_streak"],
                last_activity_date=str(s["last_activity_date"]) if s.get("last_activity_date") else None,
                streak_start_date=str(s["streak_start_date"]) if s.get("streak_start_date") else None
            )
            for s in streaks_result.data
        ]

        # Build PRs list
        personal_records = [
            PersonalRecord(
                id=str(pr["id"]),
                user_id=pr["user_id"],
                exercise_name=pr["exercise_name"],
                record_type=pr["record_type"],
                record_value=pr["record_value"],
                record_unit=pr["record_unit"],
                previous_value=pr.get("previous_value"),
                improvement_percentage=pr.get("improvement_percentage"),
                workout_id=pr.get("workout_id"),
                achieved_at=pr["achieved_at"]
            )
            for pr in prs_result.data
        ]

        return AchievementsSummary(
            total_points=total_points,
            total_achievements=len(achievements_result.data),
            recent_achievements=recent_achievements,
            current_streaks=current_streaks,
            personal_records=personal_records,
            achievements_by_category=achievements_by_category
        )

    except Exception as e:
        logger.error(f"Failed to get achievements summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}/unnotified", response_model=List[NewAchievementNotification])
async def get_unnotified_achievements(user_id: str):
    """Get achievements that haven't been shown to the user yet."""
    logger.info(f"Getting unnotified achievements for user: {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("user_achievements").select(
            "*, achievement_types(*)"
        ).eq("user_id", user_id).eq("is_notified", False).execute()

        notifications = []
        for ua in result.data:
            at = ua.get("achievement_types", {})
            if at:
                notifications.append(NewAchievementNotification(
                    achievement=AchievementType(
                        id=at["id"],
                        name=at["name"],
                        description=at["description"],
                        category=at["category"],
                        icon=at["icon"],
                        tier=at["tier"],
                        points=at["points"],
                        threshold_value=at.get("threshold_value"),
                        threshold_unit=at.get("threshold_unit"),
                        is_repeatable=at.get("is_repeatable", False)
                    ),
                    earned_at=ua["earned_at"],
                    trigger_value=ua.get("trigger_value"),
                    trigger_details=ua.get("trigger_details"),
                    is_first_time=True
                ))

        return notifications

    except Exception as e:
        logger.error(f"Failed to get unnotified achievements: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/user/{user_id}/mark-notified")
async def mark_achievements_notified(user_id: str, achievement_ids: List[str] = None):
    """Mark achievements as notified (user has seen them)."""
    logger.info(f"Marking achievements as notified for user: {user_id}")

    try:
        db = get_supabase_db()

        if achievement_ids:
            # Mark specific achievements
            for aid in achievement_ids:
                db.client.table("user_achievements").update({
                    "is_notified": True
                }).eq("id", aid).eq("user_id", user_id).execute()
        else:
            # Mark all unnotified achievements
            db.client.table("user_achievements").update({
                "is_notified": True
            }).eq("user_id", user_id).eq("is_notified", False).execute()

        return {"success": True}

    except Exception as e:
        logger.error(f"Failed to mark achievements as notified: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Streaks Endpoints
# ============================================

@router.get("/user/{user_id}/streaks", response_model=List[UserStreak])
async def get_user_streaks(user_id: str):
    """Get all streak data for a user."""
    logger.info(f"Getting streaks for user: {user_id}")

    try:
        db = get_supabase_db()
        result = db.client.table("user_streaks").select("*").eq(
            "user_id", user_id
        ).execute()

        return [
            UserStreak(
                id=str(s["id"]),
                user_id=s["user_id"],
                streak_type=s["streak_type"],
                current_streak=s["current_streak"],
                longest_streak=s["longest_streak"],
                last_activity_date=str(s["last_activity_date"]) if s.get("last_activity_date") else None,
                streak_start_date=str(s["streak_start_date"]) if s.get("streak_start_date") else None
            )
            for s in result.data
        ]

    except Exception as e:
        logger.error(f"Failed to get user streaks: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/user/{user_id}/streaks/{streak_type}/update")
async def update_streak(user_id: str, streak_type: str):
    """
    Update a user's streak. Called when the user completes an activity.

    Returns any new achievements unlocked by this streak update.
    """
    logger.info(f"Updating {streak_type} streak for user: {user_id}")

    try:
        db = get_supabase_db()
        today = date.today()
        new_achievements = []

        # Get current streak record
        result = db.client.table("user_streaks").select("*").eq(
            "user_id", user_id
        ).eq("streak_type", streak_type).execute()

        if result.data:
            streak = result.data[0]
            last_date = streak.get("last_activity_date")

            if last_date:
                last_date = date.fromisoformat(str(last_date))

                if last_date == today:
                    # Already updated today
                    return {"success": True, "message": "Already updated today", "new_achievements": []}
                elif last_date == today - timedelta(days=1):
                    # Continuing streak
                    new_streak = streak["current_streak"] + 1
                    longest = max(streak["longest_streak"], new_streak)

                    db.client.table("user_streaks").update({
                        "current_streak": new_streak,
                        "longest_streak": longest,
                        "last_activity_date": str(today),
                        "updated_at": datetime.utcnow().isoformat()
                    }).eq("id", streak["id"]).execute()

                    # Check for streak achievements
                    new_achievements = await _check_streak_achievements(
                        db, user_id, streak_type, new_streak
                    )
                else:
                    # Streak broken, start new
                    db.client.table("user_streaks").update({
                        "current_streak": 1,
                        "last_activity_date": str(today),
                        "streak_start_date": str(today),
                        "updated_at": datetime.utcnow().isoformat()
                    }).eq("id", streak["id"]).execute()
            else:
                # First activity
                db.client.table("user_streaks").update({
                    "current_streak": 1,
                    "last_activity_date": str(today),
                    "streak_start_date": str(today),
                    "updated_at": datetime.utcnow().isoformat()
                }).eq("id", streak["id"]).execute()
        else:
            # Create new streak record
            db.client.table("user_streaks").insert({
                "user_id": user_id,
                "streak_type": streak_type,
                "current_streak": 1,
                "longest_streak": 1,
                "last_activity_date": str(today),
                "streak_start_date": str(today)
            }).execute()

        # Log streak update
        await log_user_activity(
            user_id=user_id,
            action="streak_updated",
            endpoint=f"/api/v1/achievements/user/{user_id}/streaks/{streak_type}/update",
            message=f"Updated {streak_type} streak",
            metadata={"streak_type": streak_type, "new_achievements_count": len(new_achievements)},
            status_code=200
        )

        return {"success": True, "new_achievements": new_achievements}

    except Exception as e:
        logger.error(f"Failed to update streak: {e}")
        await log_user_error(
            user_id=user_id,
            action="streak_updated",
            error=e,
            endpoint=f"/api/v1/achievements/user/{user_id}/streaks/{streak_type}/update",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


async def _check_streak_achievements(db, user_id: str, streak_type: str, streak_count: int) -> List[dict]:
    """Check if streak count unlocks any achievements."""
    new_achievements = []

    # Map streak types to achievement prefixes
    prefix_map = {
        "workout": "streak_",
        "hydration": "hydration_",
        "protein": "protein_",
        "sleep": "sleep_"
    }

    # Streak milestones to check
    milestones = [7, 14, 30, 60, 100]

    for milestone in milestones:
        if streak_count >= milestone:
            achievement_id = f"{prefix_map.get(streak_type, 'streak_')}{milestone}_days"

            # Check if achievement exists
            achievement = db.client.table("achievement_types").select("*").eq(
                "id", achievement_id
            ).execute()

            if achievement.data:
                at = achievement.data[0]

                # Check if user already has this (non-repeatable)
                if not at.get("is_repeatable"):
                    existing = db.client.table("user_achievements").select("id").eq(
                        "user_id", user_id
                    ).eq("achievement_id", achievement_id).execute()

                    if existing.data:
                        continue

                # Award the achievement
                db.client.table("user_achievements").insert({
                    "user_id": user_id,
                    "achievement_id": achievement_id,
                    "trigger_value": streak_count,
                    "trigger_details": {"streak_type": streak_type},
                    "is_notified": False
                }).execute()

                new_achievements.append({
                    "id": achievement_id,
                    "name": at["name"],
                    "icon": at["icon"],
                    "points": at["points"]
                })

    return new_achievements


# ============================================
# Personal Records Endpoints
# ============================================

@router.get("/user/{user_id}/prs", response_model=List[PersonalRecord])
async def get_user_prs(user_id: str, exercise_name: Optional[str] = None):
    """Get personal records for a user, optionally filtered by exercise."""
    logger.info(f"Getting PRs for user: {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("personal_records").select("*").eq(
            "user_id", user_id
        )

        if exercise_name:
            query = query.eq("exercise_name", exercise_name)

        result = query.order("achieved_at", desc=True).execute()

        return [
            PersonalRecord(
                id=str(pr["id"]),
                user_id=pr["user_id"],
                exercise_name=pr["exercise_name"],
                record_type=pr["record_type"],
                record_value=pr["record_value"],
                record_unit=pr["record_unit"],
                previous_value=pr.get("previous_value"),
                improvement_percentage=pr.get("improvement_percentage"),
                workout_id=pr.get("workout_id"),
                achieved_at=pr["achieved_at"]
            )
            for pr in result.data
        ]

    except Exception as e:
        logger.error(f"Failed to get user PRs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/user/{user_id}/prs/check")
async def check_and_record_pr(
    user_id: str,
    exercise_name: str,
    record_type: str,  # 'weight', 'reps', 'time', 'distance'
    value: float,
    unit: str,
    workout_id: Optional[str] = None
):
    """
    Check if a value is a new PR and record it if so.

    Returns the new PR if one was set, or None if not a PR.
    """
    logger.info(f"Checking PR for user {user_id}: {exercise_name} {value} {unit}")

    try:
        db = get_supabase_db()

        # Get current PR
        existing = db.client.table("personal_records").select("*").eq(
            "user_id", user_id
        ).eq("exercise_name", exercise_name).eq("record_type", record_type).execute()

        is_new_pr = False
        previous_value = None

        if existing.data:
            current_pr = existing.data[0]
            previous_value = current_pr["record_value"]

            # Check if new value beats current PR
            # For 'time' lower is better, for others higher is better
            if record_type == "time":
                is_new_pr = value < current_pr["record_value"]
            else:
                is_new_pr = value > current_pr["record_value"]
        else:
            # First record for this exercise/type
            is_new_pr = True

        if is_new_pr:
            # Calculate improvement percentage
            improvement = None
            if previous_value:
                if record_type == "time":
                    improvement = ((previous_value - value) / previous_value) * 100
                else:
                    improvement = ((value - previous_value) / previous_value) * 100

            # Upsert the PR
            pr_data = {
                "user_id": user_id,
                "exercise_name": exercise_name,
                "record_type": record_type,
                "record_value": value,
                "record_unit": unit,
                "previous_value": previous_value,
                "improvement_percentage": round(improvement, 2) if improvement else None,
                "workout_id": workout_id,
                "achieved_at": datetime.utcnow().isoformat()
            }

            if existing.data:
                result = db.client.table("personal_records").update(
                    pr_data
                ).eq("id", existing.data[0]["id"]).execute()
            else:
                result = db.client.table("personal_records").insert(pr_data).execute()

            if result.data:
                pr = result.data[0]

                # Award PR achievement
                await _award_pr_achievement(db, user_id, exercise_name, value, previous_value)

                return {
                    "is_new_pr": True,
                    "pr": PersonalRecord(
                        id=str(pr["id"]),
                        user_id=pr["user_id"],
                        exercise_name=pr["exercise_name"],
                        record_type=pr["record_type"],
                        record_value=pr["record_value"],
                        record_unit=pr["record_unit"],
                        previous_value=pr.get("previous_value"),
                        improvement_percentage=pr.get("improvement_percentage"),
                        workout_id=pr.get("workout_id"),
                        achieved_at=pr["achieved_at"]
                    )
                }

        return {"is_new_pr": False, "pr": None}

    except Exception as e:
        logger.error(f"Failed to check/record PR: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def _award_pr_achievement(db, user_id: str, exercise_name: str, value: float, previous_value: float):
    """Award a PR achievement."""
    try:
        # Determine which achievement to award
        exercise_lower = exercise_name.lower()

        if "bench" in exercise_lower:
            achievement_id = "pr_bench"
        elif "squat" in exercise_lower:
            achievement_id = "pr_squat"
        elif "deadlift" in exercise_lower:
            achievement_id = "pr_deadlift"
        else:
            achievement_id = "pr_any"

        # Award the achievement (repeatable)
        db.client.table("user_achievements").insert({
            "user_id": user_id,
            "achievement_id": achievement_id,
            "trigger_value": value,
            "trigger_details": {
                "exercise_name": exercise_name,
                "previous_value": previous_value
            },
            "is_notified": False
        }).execute()

        logger.info(f"Awarded {achievement_id} to user {user_id}")

    except Exception as e:
        logger.error(f"Failed to award PR achievement: {e}")
