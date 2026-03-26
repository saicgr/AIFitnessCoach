"""
Fitness Wrapped Service - Monthly recap generation.

Aggregates workout, nutrition, social, and streak stats for a given month,
then calls Gemini to produce a fun AI personality card.  Results are cached
in the fitness_wrapped table so subsequent requests return instantly.
"""
import asyncio
import json
import re
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from collections import Counter

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.gemini_service import GeminiService

# Thread pool for running synchronous Supabase calls concurrently
_db_executor = ThreadPoolExecutor(max_workers=10)

logger = get_logger(__name__)


async def get_or_generate_wrapped(user_id: str, period_key: str, auth_id: str = None) -> Dict[str, Any]:
    """
    Return an existing wrapped or generate a new one.

    Args:
        user_id: The backend users.id (for workout_logs queries).
        period_key: Month string, e.g. "2026-02".
        auth_id: The Supabase auth.users.id (for fitness_wrapped table FK).

    Returns:
        Dict with keys: period_key, stats, ai_personality.
    """
    db = get_supabase_db()
    # fitness_wrapped.user_id references auth.users(id), not public.users(id)
    wrapped_uid = auth_id or user_id

    # 1. Check if already generated
    existing = (
        db.client.table("fitness_wrapped")
        .select("*")
        .eq("user_id", wrapped_uid)
        .eq("period_type", "monthly")
        .eq("period_key", period_key)
        .execute()
    )

    if existing.data:
        row = existing.data[0]
        return _row_to_response(row)

    # 2. Aggregate stats
    stats = await _aggregate_stats(db, user_id, period_key)

    # 3. Generate AI personality via Gemini
    ai_personality = await _generate_ai_personality(stats)

    # 4. Store in DB (use wrapped_uid for auth.users FK)
    insert_data = {
        "user_id": wrapped_uid,
        "period_type": "monthly",
        "period_key": period_key,
        "stats": json.dumps(stats),
        "ai_personality": json.dumps(ai_personality),
    }

    result = db.client.table("fitness_wrapped").insert(insert_data).execute()

    if result.data:
        return _row_to_response(result.data[0])

    # If insert failed (e.g. race condition), try reading again
    retry = (
        db.client.table("fitness_wrapped")
        .select("*")
        .eq("user_id", wrapped_uid)
        .eq("period_type", "monthly")
        .eq("period_key", period_key)
        .execute()
    )
    if retry.data:
        return _row_to_response(retry.data[0])

    # Return computed data even if DB insert failed
    logger.error(f"Failed to persist wrapped for user={wrapped_uid} period={period_key}")
    return {
        "period_key": period_key,
        "stats": stats,
        "ai_personality": ai_personality,
    }


async def get_available_periods(user_id: str) -> List[str]:
    """
    Return month strings (e.g. ["2026-02", "2026-01"]) where the user
    completed at least 3 workouts, ordered newest first.
    """
    db = get_supabase_db()

    # Pull completed workout logs for this user (limit to last 2 years max)
    # Only fetch the completed_at column needed for month aggregation
    two_years_ago = (datetime.now() - timedelta(days=730)).isoformat()
    result = (
        db.client.table("workout_logs")
        .select("completed_at")
        .eq("user_id", user_id)
        .not_.is_("completed_at", "null")
        .gte("completed_at", two_years_ago)
        .order("completed_at", desc=True)
        .limit(5000)
        .execute()
    )

    if not result.data:
        return []

    # Count workouts per month
    month_counts: Counter = Counter()
    for row in result.data:
        completed = row.get("completed_at")
        if completed:
            try:
                dt = datetime.fromisoformat(str(completed).replace("Z", "+00:00"))
                month_key = dt.strftime("%Y-%m")
                month_counts[month_key] += 1
            except (ValueError, TypeError):
                continue

    # Filter to months with 3+ workouts, sorted newest first
    eligible = sorted(
        [m for m, c in month_counts.items() if c >= 3],
        reverse=True,
    )
    return eligible


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _row_to_response(row: Dict[str, Any]) -> Dict[str, Any]:
    """Convert a DB row to the API response shape."""
    stats = row.get("stats", {})
    if isinstance(stats, str):
        stats = json.loads(stats)

    ai_personality = row.get("ai_personality")
    if isinstance(ai_personality, str):
        ai_personality = json.loads(ai_personality)

    return {
        "period_key": row["period_key"],
        "stats": stats,
        "ai_personality": ai_personality,
    }


async def _aggregate_stats(db, user_id: str, period_key: str) -> Dict[str, Any]:
    """
    Aggregate workout, nutrition, social, and streak stats for the month.

    All 6 independent DB queries run in parallel via asyncio.gather() to
    reduce latency from ~1000-1400ms (sequential) to ~200-300ms.
    The social_reactions query (7th) depends on social_activities results
    so it runs in a second phase only when needed.
    """
    # Parse month boundaries
    year, month = map(int, period_key.split("-"))
    start_date = datetime(year, month, 1)
    if month == 12:
        end_date = datetime(year + 1, 1, 1)
    else:
        end_date = datetime(year, month + 1, 1)

    start_str = start_date.isoformat()
    end_str = end_date.isoformat()

    loop = asyncio.get_event_loop()

    # --- Phase 1: Run 6 independent queries in parallel ---
    def _query_workout_logs():
        return (
            db.client.table("workout_logs")
            .select("*")
            .eq("user_id", user_id)
            .gte("completed_at", start_str)
            .lt("completed_at", end_str)
            .not_.is_("completed_at", "null")
            .execute()
        )

    def _query_personal_records():
        return (
            db.client.table("personal_records")
            .select("*")
            .eq("user_id", user_id)
            .gte("achieved_at", start_str)
            .lt("achieved_at", end_str)
            .execute()
        )

    def _query_user_streaks():
        return (
            db.client.table("user_streaks")
            .select("*")
            .eq("user_id", user_id)
            .eq("streak_type", "workout")
            .execute()
        )

    def _query_nutrition_logs():
        return (
            db.client.table("nutrition_logs")
            .select("calories, protein_g")
            .eq("user_id", user_id)
            .gte("logged_at", start_str)
            .lt("logged_at", end_str)
            .execute()
        )

    def _query_social_activities():
        return (
            db.client.table("social_activities")
            .select("id, activity_type")
            .eq("user_id", user_id)
            .gte("created_at", start_str)
            .lt("created_at", end_str)
            .execute()
        )

    def _query_xp_events():
        return (
            db.client.table("xp_events")
            .select("xp_amount")
            .eq("user_id", user_id)
            .gte("created_at", start_str)
            .lt("created_at", end_str)
            .execute()
        )

    (
        logs_result,
        pr_result,
        streak_result,
        nutrition_result,
        social_result,
        xp_result,
    ) = await asyncio.gather(
        loop.run_in_executor(_db_executor, _query_workout_logs),
        loop.run_in_executor(_db_executor, _query_personal_records),
        loop.run_in_executor(_db_executor, _query_user_streaks),
        loop.run_in_executor(_db_executor, _query_nutrition_logs),
        loop.run_in_executor(_db_executor, _query_social_activities),
        loop.run_in_executor(_db_executor, _query_xp_events),
    )

    # --- Process workout logs ---
    logs = logs_result.data or []

    total_workouts = len(logs)
    total_duration_minutes = 0
    total_volume_lbs = 0
    total_exercises = 0
    total_sets = 0
    total_reps = 0
    exercise_counter: Counter = Counter()
    muscle_counter: Counter = Counter()
    day_counter: Counter = Counter()
    hour_counter: Counter = Counter()
    longest_workout = 0
    shortest_workout = float("inf") if logs else 0

    for log in logs:
        duration = log.get("duration_minutes") or 0
        total_duration_minutes += duration
        longest_workout = max(longest_workout, duration)
        if duration > 0:
            shortest_workout = min(shortest_workout, duration)

        # Parse completed_at for day-of-week / hour analysis
        completed_at = log.get("completed_at")
        if completed_at:
            try:
                dt = datetime.fromisoformat(str(completed_at).replace("Z", "+00:00"))
                day_counter[dt.strftime("%A")] += 1
                hour_counter[dt.hour] += 1
            except (ValueError, TypeError) as e:
                logger.debug(f"Failed to parse completed_at: {e}")

        # Parse exercises
        exercises_json = log.get("exercises_completed") or "[]"
        try:
            exercises = json.loads(exercises_json) if isinstance(exercises_json, str) else exercises_json
        except (json.JSONDecodeError, TypeError):
            exercises = []

        if isinstance(exercises, list):
            total_exercises += len(exercises)
            for ex in exercises:
                name = ex.get("name", "Unknown")
                exercise_counter[name] += 1

                muscle = ex.get("muscle_group") or ex.get("primary_muscle") or ""
                if muscle:
                    muscle_counter[muscle] += 1

                sets_data = ex.get("sets") or ex.get("sets_completed") or []
                if isinstance(sets_data, list):
                    total_sets += len(sets_data)
                    for s in sets_data:
                        reps = s.get("reps") or s.get("actual_reps") or 0
                        weight = s.get("weight") or s.get("actual_weight") or 0
                        total_reps += int(reps) if reps else 0
                        total_volume_lbs += (int(reps) if reps else 0) * (float(weight) if weight else 0)
                elif isinstance(sets_data, (int, float)):
                    total_sets += int(sets_data)

    if shortest_workout == float("inf"):
        shortest_workout = 0

    def _top(counter):
        mc = counter.most_common(1)
        return mc[0][0] if mc else None

    favorite_exercise = _top(exercise_counter)
    favorite_muscle_group = _top(muscle_counter)
    most_active_day = _top(day_counter)
    most_active_hour = _top(hour_counter)

    # --- Process personal records ---
    prs = pr_result.data or []
    personal_records_count = len(prs)
    best_pr = None
    if prs:
        best_pr = {
            "exercise": prs[0].get("exercise_name", "Unknown"),
            "value": prs[0].get("record_value"),
            "unit": prs[0].get("record_unit", "lbs"),
        }

    # --- Process streaks ---
    streak_data = streak_result.data[0] if streak_result.data else {}
    streak_best = streak_data.get("longest_streak", 0)
    streak_current = streak_data.get("current_streak", 0)

    # --- Process nutrition ---
    nutrition_logs = nutrition_result.data or []
    total_calories = sum(n.get("calories") or 0 for n in nutrition_logs)
    total_protein = sum(n.get("protein_g") or 0 for n in nutrition_logs)
    avg_protein = round(total_protein / len(nutrition_logs), 1) if nutrition_logs else 0

    # --- Process social ---
    social_data = social_result.data or []
    social_posts_count = len([s for s in social_data if s.get("activity_type") == "post"])

    # --- Phase 2: Reactions query (depends on social_activities IDs) ---
    # Fixed: filter by user's activity IDs instead of full table scan
    user_activity_ids = [s["id"] for s in social_data]
    social_reactions_received = 0
    if user_activity_ids:
        def _query_social_reactions():
            return (
                db.client.table("social_reactions")
                .select("id", count="exact")
                .in_("activity_id", user_activity_ids)
                .execute()
            )

        reactions_result = await loop.run_in_executor(
            _db_executor, _query_social_reactions
        )
        social_reactions_received = reactions_result.count or 0

    # --- Consistency ---
    days_in_month = (end_date - start_date).days
    # Assume ~5 workout days per week as target
    expected_workouts = round(days_in_month * 5 / 7)
    workout_consistency_pct = round(
        (total_workouts / expected_workouts * 100) if expected_workouts > 0 else 0,
        1,
    )

    # --- Process XP ---
    xp_earned = sum(x.get("xp_amount", 0) for x in (xp_result.data or []))

    return {
        "total_workouts": total_workouts,
        "total_duration_minutes": total_duration_minutes,
        "total_volume_lbs": round(total_volume_lbs, 1),
        "total_exercises": total_exercises,
        "total_sets": total_sets,
        "total_reps": total_reps,
        "favorite_exercise": favorite_exercise,
        "favorite_muscle_group": favorite_muscle_group,
        "longest_workout_minutes": longest_workout,
        "shortest_workout_minutes": shortest_workout,
        "personal_records_count": personal_records_count,
        "best_pr": best_pr,
        "streak_best": streak_best,
        "streak_current": streak_current,
        "total_calories_logged": total_calories,
        "avg_protein_g": avg_protein,
        "most_active_day_of_week": most_active_day,
        "most_active_hour": most_active_hour,
        "workout_consistency_pct": workout_consistency_pct,
        "social_reactions_received": social_reactions_received,
        "social_posts_count": social_posts_count,
        "xp_earned": xp_earned,
    }


async def get_wrapped_summary(user_id: str, auth_id: str) -> Dict[str, Any]:
    """
    Return a summary of all wrapped periods, current month progress,
    and collected personalities for the summary/overview screen.

    Args:
        user_id: The backend users.id (for workout_logs / personal_records queries).
        auth_id: The Supabase auth.users.id (for fitness_wrapped table FK).

    Returns:
        Dict with keys: available, current_month, personalities_collected.
    """
    db = get_supabase_db()
    loop = asyncio.get_event_loop()

    now = datetime.now()
    current_period = now.strftime("%Y-%m")

    # Current month boundaries
    month_start = datetime(now.year, now.month, 1)
    if now.month == 12:
        month_end = datetime(now.year + 1, 1, 1)
    else:
        month_end = datetime(now.year, now.month + 1, 1)

    month_start_str = month_start.isoformat()
    month_end_str = month_end.isoformat()

    # --- Phase 1: Run 3 independent queries in parallel ---
    def _query_all_wrapped():
        return (
            db.client.table("fitness_wrapped")
            .select("period_key, stats, ai_personality")
            .eq("user_id", auth_id)
            .eq("period_type", "monthly")
            .order("period_key", desc=True)
            .execute()
        )

    def _query_current_month_logs():
        return (
            db.client.table("workout_logs")
            .select("exercises_completed, total_time_seconds")
            .eq("user_id", user_id)
            .not_.is_("completed_at", "null")
            .gte("completed_at", month_start_str)
            .lt("completed_at", month_end_str)
            .execute()
        )

    def _query_current_month_prs():
        return (
            db.client.table("personal_records")
            .select("id")
            .eq("user_id", user_id)
            .gte("achieved_at", month_start_str)
            .lt("achieved_at", month_end_str)
            .execute()
        )

    wrapped_result, logs_result, prs_result = await asyncio.gather(
        loop.run_in_executor(_db_executor, _query_all_wrapped),
        loop.run_in_executor(_db_executor, _query_current_month_logs),
        loop.run_in_executor(_db_executor, _query_current_month_prs),
    )

    # --- Build "available" list from fitness_wrapped rows ---
    available = []
    personality_set = set()

    for row in (wrapped_result.data or []):
        stats_data = row.get("stats", {})
        if isinstance(stats_data, str):
            try:
                stats_data = json.loads(stats_data)
            except (json.JSONDecodeError, TypeError):
                stats_data = {}

        ai_personality = row.get("ai_personality")
        if isinstance(ai_personality, str):
            try:
                ai_personality = json.loads(ai_personality)
            except (json.JSONDecodeError, TypeError):
                ai_personality = {}

        personality_name = None
        if isinstance(ai_personality, dict):
            personality_name = ai_personality.get("fitness_personality")
            if personality_name:
                personality_set.add(personality_name)

        available.append({
            "period": row.get("period_key"),
            "viewed": True,
            "personality": personality_name,
            "total_workouts": stats_data.get("total_workouts", 0),
            "total_volume_lbs": stats_data.get("total_volume_lbs", 0),
        })

    # --- Build "current_month" from workout_logs ---
    current_logs = logs_result.data or []
    workouts_so_far = len(current_logs)

    # Calculate volume using same parsing logic as _aggregate_stats
    volume_so_far = 0
    for log in current_logs:
        exercises_json = log.get("exercises_completed") or "[]"
        try:
            exercises = json.loads(exercises_json) if isinstance(exercises_json, str) else exercises_json
        except (json.JSONDecodeError, TypeError):
            exercises = []

        if isinstance(exercises, list):
            for ex in exercises:
                sets_data = ex.get("sets") or ex.get("sets_completed") or []
                if isinstance(sets_data, list):
                    for s in sets_data:
                        reps = s.get("reps") or s.get("actual_reps") or 0
                        weight = s.get("weight") or s.get("actual_weight") or 0
                        volume_so_far += (int(reps) if reps else 0) * (float(weight) if weight else 0)

    prs_so_far = len(prs_result.data or [])
    days_until_drop = (month_end - now).days

    current_month = {
        "period": current_period,
        "workouts_so_far": workouts_so_far,
        "volume_so_far": round(volume_so_far, 1),
        "prs_so_far": prs_so_far,
        "days_until_drop": days_until_drop,
        "eligible": workouts_so_far >= 3,
    }

    return {
        "available": available,
        "current_month": current_month,
        "personalities_collected": len(personality_set),
    }


async def _generate_ai_personality(stats: Dict[str, Any]) -> Dict[str, Any]:
    """
    Call Gemini to produce a fun fitness personality based on monthly stats.
    Returns dict with: fitness_personality, personality_description, fun_fact, motivation_quote.
    """
    gemini = GeminiService()

    prompt = f"""You are a creative fitness personality generator. Based on these monthly workout stats, create a fun fitness personality profile.

Stats:
- Total workouts: {stats['total_workouts']}
- Total duration: {stats['total_duration_minutes']} minutes
- Total volume lifted: {stats['total_volume_lbs']} lbs
- Total exercises: {stats['total_exercises']}
- Total sets: {stats['total_sets']}
- Total reps: {stats['total_reps']}
- Favorite exercise: {stats['favorite_exercise']}
- Favorite muscle group: {stats['favorite_muscle_group']}
- Longest workout: {stats['longest_workout_minutes']} min
- Personal records: {stats['personal_records_count']}
- Current streak: {stats['streak_current']} days
- Best streak: {stats['streak_best']} days
- Consistency: {stats['workout_consistency_pct']}%
- XP earned: {stats['xp_earned']}
- Social posts: {stats['social_posts_count']}
- Most active day: {stats['most_active_day_of_week']}

Return ONLY valid JSON with exactly these 4 fields:
{{
  "fitness_personality": "A creative 2-4 word title (e.g. 'The Iron Monk', 'Cardio Tornado', 'The Volume King')",
  "personality_description": "A fun 2-sentence description of this fitness personality type",
  "fun_fact": "One surprising or interesting stat observation (e.g. 'You lifted the equivalent of 3 Toyota Camrys this month!')",
  "motivation_quote": "A short motivational quote that fits this personality"
}}

Be creative, fun, and encouraging. Make it feel like a Spotify Wrapped reveal."""

    try:
        response = await gemini.chat(
            user_message=prompt,
            system_prompt="You are a creative fitness personality generator. Respond with valid JSON only.",
        )

        # Extract JSON from response
        json_match = re.search(r'\{[\s\S]*\}', response)
        if json_match:
            parsed = json.loads(json_match.group())
            return {
                "fitness_personality": parsed.get("fitness_personality", "The Dedicated One"),
                "personality_description": parsed.get("personality_description", "You showed up and put in the work."),
                "fun_fact": parsed.get("fun_fact", f"You completed {stats['total_workouts']} workouts this month!"),
                "motivation_quote": parsed.get("motivation_quote", "Consistency beats intensity."),
            }
    except Exception as e:
        logger.error(f"Failed to generate AI personality: {e}")

    # Fallback personality
    return {
        "fitness_personality": "The Dedicated One",
        "personality_description": f"You crushed {stats['total_workouts']} workouts this month. That kind of consistency speaks for itself.",
        "fun_fact": f"You lifted a total of {stats['total_volume_lbs']:,.0f} lbs this month!",
        "motivation_quote": "Consistency beats intensity. Keep showing up.",
    }
