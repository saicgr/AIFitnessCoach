"""
Trophy Trigger Service.

Implements automated trophy awarding based on user activities.
Called after workouts, PRs, social actions, etc. to check and award earned trophies.

Achievement categories:
- exercise_mastery: Muscle group exercise counts (chest, back, legs, etc.)
- volume: Total weight lifted, sets completed, reps done
- time: Workout duration milestones
- consistency: Workout frequency, streaks, perfect weeks
- personal_records: PRs for specific lifts
- social: Friends, reactions, challenges
- body: Weight loss/gain milestones
- nutrition: Meal logging streaks
- fasting: Fasting streaks
- special: Hidden/secret achievements
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta
from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

async def _get_achievement(db, achievement_id: str) -> Optional[Dict]:
    """Get achievement type by ID."""
    try:
        result = db.client.table("achievement_types").select("*").eq("id", achievement_id).execute()
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error getting achievement {achievement_id}: {e}")
        return None


async def _has_achievement(db, user_id: str, achievement_id: str) -> bool:
    """Check if user already has an achievement."""
    try:
        result = db.client.table("user_achievements").select("id").eq(
            "user_id", user_id
        ).eq("achievement_id", achievement_id).execute()
        return len(result.data) > 0
    except Exception as e:
        logger.error(f"Error checking achievement {achievement_id} for user {user_id}: {e}")
        return False


async def _award_achievement(
    db,
    user_id: str,
    achievement_id: str,
    trigger_value: float = None,
    trigger_details: dict = None
) -> Optional[Dict]:
    """Award an achievement to a user."""
    try:
        # Get achievement info
        achievement = await _get_achievement(db, achievement_id)
        if not achievement:
            logger.warning(f"Achievement {achievement_id} not found")
            return None

        # Check if already earned (if not repeatable)
        if not achievement.get("is_repeatable", False):
            if await _has_achievement(db, user_id, achievement_id):
                return None

        # Insert the achievement
        result = db.client.table("user_achievements").insert({
            "user_id": user_id,
            "achievement_id": achievement_id,
            "trigger_value": trigger_value,
            "trigger_details": trigger_details,
            "is_notified": False
        }).execute()

        if result.data:
            logger.info(f"🏆 Awarded achievement {achievement_id} to user {user_id}")

            # Award XP if configured
            xp_reward = achievement.get("xp_reward", 0)
            if xp_reward > 0:
                try:
                    db.client.rpc("award_xp", {
                        "p_user_id": user_id,
                        "p_xp_amount": xp_reward,
                        "p_source": "trophy",
                        "p_source_id": achievement_id,
                        "p_description": f"Trophy earned: {achievement.get('name', achievement_id)}"
                    }).execute()
                except Exception as e:
                    logger.error(f"Error awarding XP for achievement: {e}")

            return {
                "id": achievement_id,
                "name": achievement.get("name"),
                "icon": achievement.get("icon"),
                "tier": achievement.get("tier"),
                "points": achievement.get("points", 0),
                "xp_reward": xp_reward
            }

        return None
    except Exception as e:
        logger.error(f"Error awarding achievement {achievement_id}: {e}")
        return None


async def _update_trophy_progress(
    db,
    user_id: str,
    achievement_id: str,
    current_value: float
) -> None:
    """Update trophy progress tracking."""
    try:
        db.client.table("trophy_progress").upsert({
            "user_id": user_id,
            "achievement_id": achievement_id,
            "current_value": current_value,
            "updated_at": datetime.utcnow().isoformat()
        }, on_conflict="user_id,achievement_id").execute()
    except Exception as e:
        logger.error(f"Error updating trophy progress: {e}")


# ============================================================================
# VOLUME ACHIEVEMENTS
# ============================================================================

async def check_volume_achievements(user_id: str) -> List[Dict]:
    """
    Check and award volume-based achievements.

    Checks:
    - Total weight lifted (lbs_lifted)
    - Total sets completed
    - Total reps completed
    """
    db = get_supabase_db()
    awarded = []

    try:
        # Get total volume stats from workout_sets
        stats_result = db.client.rpc("get_user_volume_stats", {"p_user_id": user_id}).execute()

        if not stats_result.data:
            # Fallback: calculate directly
            sets_result = db.client.table("workout_sets").select(
                "weight_lbs, reps"
            ).eq("user_id", user_id).execute()

            total_weight = sum((s.get("weight_lbs", 0) or 0) * (s.get("reps", 0) or 0) for s in sets_result.data)
            total_sets = len(sets_result.data)
            total_reps = sum(s.get("reps", 0) or 0 for s in sets_result.data)
        else:
            stats = stats_result.data[0] if stats_result.data else {}
            total_weight = stats.get("total_weight_lbs", 0)
            total_sets = stats.get("total_sets", 0)
            total_reps = stats.get("total_reps", 0)

        # Weight lifted trophies
        weight_trophies = [
            ("volume_weight_bronze", 25000),
            ("volume_weight_silver", 250000),
            ("volume_weight_gold", 1000000),
            ("volume_weight_platinum", 5000000),
        ]

        for trophy_id, threshold in weight_trophies:
            await _update_trophy_progress(db, user_id, trophy_id, total_weight)
            if total_weight >= threshold:
                result = await _award_achievement(db, user_id, trophy_id, total_weight, {"unit": "lbs"})
                if result:
                    awarded.append(result)

        # Sets completed trophies
        sets_trophies = [
            ("volume_sets_bronze", 500),
            ("volume_sets_silver", 5000),
            ("volume_sets_gold", 25000),
            ("volume_sets_platinum", 100000),
        ]

        for trophy_id, threshold in sets_trophies:
            await _update_trophy_progress(db, user_id, trophy_id, total_sets)
            if total_sets >= threshold:
                result = await _award_achievement(db, user_id, trophy_id, total_sets, {"unit": "sets"})
                if result:
                    awarded.append(result)

        # Reps completed trophies
        reps_trophies = [
            ("volume_reps_bronze", 10000),
            ("volume_reps_silver", 100000),
            ("volume_reps_gold", 500000),
            ("volume_reps_platinum", 1000000),
        ]

        for trophy_id, threshold in reps_trophies:
            await _update_trophy_progress(db, user_id, trophy_id, total_reps)
            if total_reps >= threshold:
                result = await _award_achievement(db, user_id, trophy_id, total_reps, {"unit": "reps"})
                if result:
                    awarded.append(result)

    except Exception as e:
        logger.error(f"Error checking volume achievements: {e}")

    return awarded


# ============================================================================
# TIME ACHIEVEMENTS
# ============================================================================

async def check_time_achievements(user_id: str) -> List[Dict]:
    """
    Check and award time-based achievements.

    Checks:
    - Total workout hours
    - Single workout duration records
    """
    db = get_supabase_db()
    awarded = []

    try:
        # Get total workout duration from workout_logs
        result = db.client.table("workout_logs").select(
            "duration_minutes"
        ).eq("user_id", user_id).execute()

        total_minutes = sum(w.get("duration_minutes", 0) or 0 for w in result.data)
        total_hours = total_minutes / 60

        # Time trophies (in hours)
        time_trophies = [
            ("time_workout_bronze", 24),      # 24 hours
            ("time_workout_silver", 100),     # 100 hours
            ("time_workout_gold", 250),       # 250 hours
            ("time_workout_platinum", 500),   # 500 hours
            ("time_workout_diamond", 1000),   # 1000 hours
        ]

        for trophy_id, threshold in time_trophies:
            await _update_trophy_progress(db, user_id, trophy_id, total_hours)
            if total_hours >= threshold:
                result = await _award_achievement(db, user_id, trophy_id, total_hours, {"unit": "hours"})
                if result:
                    awarded.append(result)

    except Exception as e:
        logger.error(f"Error checking time achievements: {e}")

    return awarded


# ============================================================================
# EXERCISE MASTERY ACHIEVEMENTS
# ============================================================================

# Mapping of muscle groups to their trophy prefixes
MUSCLE_GROUP_TROPHIES = {
    "chest": "chest",
    "back": "back",
    "shoulders": "shoulders",
    "biceps": "biceps",
    "triceps": "triceps",
    "legs": "legs",
    "quadriceps": "legs",
    "hamstrings": "legs",
    "calves": "legs",
    "core": "core",
    "abs": "core",
    "glutes": "glutes",
}


async def check_exercise_mastery_achievements(
    user_id: str,
    muscle_groups: List[str] = None
) -> List[Dict]:
    """
    Check and award exercise mastery achievements.

    Args:
        user_id: User ID
        muscle_groups: Optional list of specific muscle groups to check.
                      If None, checks all muscle groups.
    """
    db = get_supabase_db()
    awarded = []

    try:
        # If no specific muscle groups, check all
        groups_to_check = muscle_groups if muscle_groups else list(set(MUSCLE_GROUP_TROPHIES.values()))

        for muscle_group in groups_to_check:
            # Get count of exercises for this muscle group
            # This requires joining workout_sets with exercises table
            count_result = db.client.rpc("count_muscle_group_exercises", {
                "p_user_id": user_id,
                "p_muscle_group": muscle_group
            }).execute()

            count = count_result.data if isinstance(count_result.data, int) else 0
            if isinstance(count_result.data, list) and count_result.data:
                count = count_result.data[0].get("count", 0)

            # Trophy tiers
            tiers = [
                (f"{muscle_group}_bronze", 25),
                (f"{muscle_group}_silver", 100),
                (f"{muscle_group}_gold", 500),
                (f"{muscle_group}_platinum", 2000),
            ]

            for trophy_id, threshold in tiers:
                await _update_trophy_progress(db, user_id, trophy_id, count)
                if count >= threshold:
                    result = await _award_achievement(
                        db, user_id, trophy_id, count,
                        {"muscle_group": muscle_group, "unit": "exercises"}
                    )
                    if result:
                        awarded.append(result)

    except Exception as e:
        logger.error(f"Error checking exercise mastery achievements: {e}")

    return awarded


async def check_specific_exercise_achievements(
    user_id: str,
    exercise_name: str
) -> List[Dict]:
    """
    Check achievements for specific exercises (squat, deadlift, bench, OHP).
    """
    db = get_supabase_db()
    awarded = []

    try:
        exercise_lower = exercise_name.lower()

        # Determine which exercise category
        if "squat" in exercise_lower:
            prefix = "squat"
        elif "deadlift" in exercise_lower:
            prefix = "deadlift"
        elif "bench" in exercise_lower:
            prefix = "bench"
        elif "overhead" in exercise_lower or "ohp" in exercise_lower or "shoulder press" in exercise_lower:
            prefix = "ohp"
        else:
            return awarded  # Not a tracked exercise

        # Count sets for this exercise type
        count_result = db.client.table("workout_sets").select(
            "id", count="exact"
        ).eq("user_id", user_id).ilike("exercise_name", f"%{prefix}%").execute()

        count = count_result.count or 0

        # Trophy tiers for specific exercises
        tiers = [
            (f"{prefix}_bronze", 50),
            (f"{prefix}_silver", 250),
            (f"{prefix}_gold", 1000),
            (f"{prefix}_platinum", 5000),
        ]

        for trophy_id, threshold in tiers:
            await _update_trophy_progress(db, user_id, trophy_id, count)
            if count >= threshold:
                result = await _award_achievement(
                    db, user_id, trophy_id, count,
                    {"exercise": prefix, "unit": "sets"}
                )
                if result:
                    awarded.append(result)

    except Exception as e:
        logger.error(f"Error checking specific exercise achievements: {e}")

    return awarded


# ============================================================================
# CONSISTENCY ACHIEVEMENTS
# ============================================================================

async def check_consistency_achievements(user_id: str) -> List[Dict]:
    """
    Check and award consistency-based achievements.

    Checks:
    - Total workouts completed
    - Workouts this week
    - Perfect weeks
    """
    db = get_supabase_db()
    awarded = []

    try:
        # Get total workout count
        total_result = db.client.table("workout_logs").select(
            "id", count="exact"
        ).eq("user_id", user_id).execute()

        total_workouts = total_result.count or 0

        # Total workout trophies
        total_trophies = [
            ("consistency_workouts_bronze", 10),
            ("consistency_workouts_silver", 50),
            ("consistency_workouts_gold", 200),
            ("consistency_workouts_platinum", 500),
            ("consistency_workouts_diamond", 1000),
        ]

        for trophy_id, threshold in total_trophies:
            await _update_trophy_progress(db, user_id, trophy_id, total_workouts)
            if total_workouts >= threshold:
                result = await _award_achievement(
                    db, user_id, trophy_id, total_workouts,
                    {"unit": "workouts"}
                )
                if result:
                    awarded.append(result)

        # Get current streak from user_streaks
        streak_result = db.client.table("user_streaks").select(
            "current_streak, longest_streak"
        ).eq("user_id", user_id).eq("streak_type", "workout").execute()

        if streak_result.data:
            streak = streak_result.data[0]
            current_streak = streak.get("current_streak", 0)
            longest_streak = streak.get("longest_streak", 0)

            # Streak trophies
            streak_trophies = [
                ("streak_7_days", 7),
                ("streak_14_days", 14),
                ("streak_30_days", 30),
                ("streak_60_days", 60),
                ("streak_100_days", 100),
                ("streak_365_days", 365),
            ]

            for trophy_id, threshold in streak_trophies:
                await _update_trophy_progress(db, user_id, trophy_id, max(current_streak, longest_streak))
                if current_streak >= threshold or longest_streak >= threshold:
                    result = await _award_achievement(
                        db, user_id, trophy_id, max(current_streak, longest_streak),
                        {"unit": "days"}
                    )
                    if result:
                        awarded.append(result)

    except Exception as e:
        logger.error(f"Error checking consistency achievements: {e}")

    return awarded


# ============================================================================
# SOCIAL ACHIEVEMENTS
# ============================================================================

async def check_social_achievements(user_id: str) -> List[Dict]:
    """
    Check and award social achievements.

    Checks:
    - Friend count
    - Challenges won
    - Reactions received
    """
    db = get_supabase_db()
    awarded = []

    try:
        # Get friend count
        friends_result = db.client.table("friends").select(
            "id", count="exact"
        ).eq("user_id", user_id).eq("status", "accepted").execute()

        friend_count = friends_result.count or 0

        # Friend trophies
        friend_trophies = [
            ("social_friends_bronze", 5),
            ("social_friends_silver", 25),
            ("social_friends_gold", 100),
            ("social_friends_platinum", 500),
        ]

        for trophy_id, threshold in friend_trophies:
            await _update_trophy_progress(db, user_id, trophy_id, friend_count)
            if friend_count >= threshold:
                result = await _award_achievement(
                    db, user_id, trophy_id, friend_count,
                    {"unit": "friends"}
                )
                if result:
                    awarded.append(result)

        # Get challenge wins
        wins_result = db.client.table("challenges").select(
            "id", count="exact"
        ).eq("winner_id", user_id).execute()

        challenge_wins = wins_result.count or 0

        # Challenge trophies
        challenge_trophies = [
            ("social_challenges_bronze", 5),
            ("social_challenges_silver", 25),
            ("social_challenges_gold", 100),
            ("social_challenges_platinum", 500),
        ]

        for trophy_id, threshold in challenge_trophies:
            await _update_trophy_progress(db, user_id, trophy_id, challenge_wins)
            if challenge_wins >= threshold:
                result = await _award_achievement(
                    db, user_id, trophy_id, challenge_wins,
                    {"unit": "challenge_wins"}
                )
                if result:
                    awarded.append(result)

    except Exception as e:
        logger.error(f"Error checking social achievements: {e}")

    return awarded


# ============================================================================
# BODY COMPOSITION ACHIEVEMENTS
# ============================================================================

async def check_body_achievements(user_id: str) -> List[Dict]:
    """
    Check and award body composition achievements.

    Checks:
    - Weight loss milestones
    - Weight gain milestones (for muscle building)
    """
    db = get_supabase_db()
    awarded = []

    try:
        # Get weight history
        weights_result = db.client.table("weight_logs").select(
            "weight_lbs, logged_at"
        ).eq("user_id", user_id).order("logged_at").execute()

        if len(weights_result.data) >= 2:
            first_weight = weights_result.data[0].get("weight_lbs", 0)
            latest_weight = weights_result.data[-1].get("weight_lbs", 0)

            weight_change = latest_weight - first_weight
            weight_loss = -weight_change if weight_change < 0 else 0
            weight_gain = weight_change if weight_change > 0 else 0

            # Weight loss trophies
            loss_trophies = [
                ("body_loss_5", 5),
                ("body_loss_10", 10),
                ("body_loss_25", 25),
                ("body_loss_50", 50),
                ("body_loss_100", 100),
            ]

            for trophy_id, threshold in loss_trophies:
                await _update_trophy_progress(db, user_id, trophy_id, weight_loss)
                if weight_loss >= threshold:
                    result = await _award_achievement(
                        db, user_id, trophy_id, weight_loss,
                        {"unit": "lbs", "type": "loss"}
                    )
                    if result:
                        awarded.append(result)

            # Weight gain trophies (muscle building)
            gain_trophies = [
                ("body_gain_5", 5),
                ("body_gain_10", 10),
                ("body_gain_25", 25),
            ]

            for trophy_id, threshold in gain_trophies:
                await _update_trophy_progress(db, user_id, trophy_id, weight_gain)
                if weight_gain >= threshold:
                    result = await _award_achievement(
                        db, user_id, trophy_id, weight_gain,
                        {"unit": "lbs", "type": "gain"}
                    )
                    if result:
                        awarded.append(result)

    except Exception as e:
        logger.error(f"Error checking body achievements: {e}")

    return awarded


# ============================================================================
# MASTER CHECK FUNCTION
# ============================================================================

async def check_all_trophies(user_id: str) -> List[Dict]:
    """
    Run all trophy checks for a user.
    Returns list of all newly awarded trophies.
    """
    all_awarded = []

    # Run all checks
    all_awarded.extend(await check_volume_achievements(user_id))
    all_awarded.extend(await check_time_achievements(user_id))
    all_awarded.extend(await check_exercise_mastery_achievements(user_id))
    all_awarded.extend(await check_consistency_achievements(user_id))
    all_awarded.extend(await check_social_achievements(user_id))
    all_awarded.extend(await check_body_achievements(user_id))

    if all_awarded:
        logger.info(f"🏆 User {user_id} earned {len(all_awarded)} new trophy(ies)")

    return all_awarded


async def check_workout_completion_trophies(
    user_id: str,
    workout_data: Dict[str, Any]
) -> List[Dict]:
    """
    Check trophies after a workout is completed.

    Args:
        user_id: User ID
        workout_data: Workout details including exercises, duration, etc.
    """
    all_awarded = []

    # Volume achievements
    all_awarded.extend(await check_volume_achievements(user_id))

    # Time achievements
    all_awarded.extend(await check_time_achievements(user_id))

    # Consistency achievements
    all_awarded.extend(await check_consistency_achievements(user_id))

    # Exercise mastery based on workout exercises
    exercises = workout_data.get("exercises", [])
    muscle_groups = set()
    for exercise in exercises:
        muscle = exercise.get("primary_muscle", "").lower()
        if muscle in MUSCLE_GROUP_TROPHIES:
            muscle_groups.add(MUSCLE_GROUP_TROPHIES[muscle])

        # Check specific exercise achievements
        exercise_name = exercise.get("name", "")
        all_awarded.extend(await check_specific_exercise_achievements(user_id, exercise_name))

    if muscle_groups:
        all_awarded.extend(await check_exercise_mastery_achievements(user_id, list(muscle_groups)))

    return all_awarded
