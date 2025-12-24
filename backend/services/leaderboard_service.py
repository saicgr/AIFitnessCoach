"""
Leaderboard service - Business logic layer for leaderboard operations.

This service handles all leaderboard-related business logic, keeping API endpoints thin.
"""

from typing import Optional, Dict, List, Any
from datetime import datetime, timezone

from utils.supabase_client import get_supabase_client
from services.social_rag_service import get_social_rag_service
from models.leaderboard import LeaderboardType, LeaderboardFilter


class LeaderboardService:
    """Service for leaderboard operations."""

    def __init__(self):
        self.supabase = get_supabase_client()
        self.social_rag = get_social_rag_service()

    # ============================================================
    # VIEW MAPPINGS
    # ============================================================

    VIEW_NAMES = {
        LeaderboardType.challenge_masters: "leaderboard_challenge_masters",
        LeaderboardType.volume_kings: "leaderboard_volume_kings",
        LeaderboardType.streaks: "leaderboard_streaks",
        LeaderboardType.weekly_challenges: "leaderboard_weekly_challenges",
    }

    ORDER_COLUMNS = {
        LeaderboardType.challenge_masters: "first_wins",
        LeaderboardType.volume_kings: "total_volume_lbs",
        LeaderboardType.streaks: "best_streak",
        LeaderboardType.weekly_challenges: "weekly_wins",
    }

    # ============================================================
    # UNLOCK STATUS
    # ============================================================

    def check_unlock_status(self, user_id: str) -> Dict[str, Any]:
        """Check if user has unlocked global leaderboard."""
        result = self.supabase.rpc("check_leaderboard_unlock", {"p_user_id": user_id}).execute()

        if not result.data:
            return {
                "is_unlocked": False,
                "workouts_completed": 0,
                "workouts_needed": 10,
                "days_active": 0,
            }

        return result.data[0]

    # ============================================================
    # GET LEADERBOARD DATA
    # ============================================================

    def get_leaderboard_entries(
        self,
        leaderboard_type: LeaderboardType,
        filter_type: LeaderboardFilter,
        user_id: str,
        country_code: Optional[str] = None,
        limit: int = 100,
        offset: int = 0,
    ) -> Dict[str, Any]:
        """Get leaderboard entries with filtering."""
        view_name = self.VIEW_NAMES[leaderboard_type]

        # Build query based on filter
        if filter_type == LeaderboardFilter.friends:
            friend_ids = self._get_friend_ids(user_id)
            if not friend_ids:
                return {"entries": [], "total": 0}
            query = self.supabase.table(view_name).select("*").in_("user_id", friend_ids)

        elif filter_type == LeaderboardFilter.country:
            query = self.supabase.table(view_name).select("*").eq("country_code", country_code)

        else:  # Global
            query = self.supabase.table(view_name).select("*")

        # Get total count
        count_result = query.execute()
        total = len(count_result.data) if count_result.data else 0

        # Get paginated entries
        order_column = self.ORDER_COLUMNS[leaderboard_type]
        entries_result = query.order(order_column, desc=True).range(offset, offset + limit - 1).execute()

        return {
            "entries": entries_result.data if entries_result.data else [],
            "total": total,
        }

    # ============================================================
    # USER RANK
    # ============================================================

    def get_user_rank(
        self,
        user_id: str,
        leaderboard_type: LeaderboardType,
        country_filter: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Get user's rank in specified leaderboard."""
        rank_result = self.supabase.rpc("get_user_leaderboard_rank", {
            "p_user_id": user_id,
            "p_leaderboard_type": leaderboard_type.value,
            "p_country_filter": country_filter,
        }).execute()

        if not rank_result.data:
            return None

        rank_data = rank_result.data[0]

        # Get user's stats
        view_name = self.VIEW_NAMES[leaderboard_type]
        user_stats_result = self.supabase.table(view_name).select("*").eq("user_id", user_id).execute()

        if not user_stats_result.data:
            return None

        return {
            "rank_info": rank_data,
            "stats": user_stats_result.data[0],
        }

    # ============================================================
    # LEADERBOARD STATS
    # ============================================================

    def get_leaderboard_stats(self) -> Dict[str, Any]:
        """Get overall leaderboard statistics."""
        masters = self.supabase.table("leaderboard_challenge_masters").select("country_code, first_wins").execute()
        volume = self.supabase.table("leaderboard_volume_kings").select("total_volume_lbs").execute()
        streaks = self.supabase.table("leaderboard_streaks").select("best_streak").execute()

        masters_data = masters.data if masters.data else []
        volume_data = volume.data if volume.data else []
        streaks_data = streaks.data if streaks.data else []

        # Calculate stats
        total_users = len(masters_data)
        countries = set(entry["country_code"] for entry in masters_data if entry.get("country_code"))

        # Top country
        country_counts = {}
        for entry in masters_data:
            cc = entry.get("country_code")
            if cc:
                country_counts[cc] = country_counts.get(cc, 0) + 1

        top_country = max(country_counts.items(), key=lambda x: x[1])[0] if country_counts else None

        # Stats
        total_wins = sum(entry.get("first_wins", 0) for entry in masters_data)
        avg_wins = (total_wins / total_users) if total_users > 0 else 0
        highest_streak = max((entry.get("best_streak", 0) for entry in streaks_data), default=0)
        total_volume = sum(entry.get("total_volume_lbs", 0) for entry in volume_data)

        return {
            "total_users": total_users,
            "total_countries": len(countries),
            "top_country": top_country,
            "average_wins": round(avg_wins, 1),
            "highest_streak": highest_streak,
            "total_volume_lifted": round(total_volume, 0),
        }

    # ============================================================
    # ASYNC CHALLENGE
    # ============================================================

    def create_async_challenge(
        self,
        user_id: str,
        target_user_id: str,
        workout_log_id: Optional[str] = None,
        challenge_message: str = "I'm coming for your record! 💪",
    ) -> Dict[str, Any]:
        """Create async 'Beat Their Best' challenge."""
        # Get target user
        target_user = self.supabase.table("users").select("name").eq("id", target_user_id).execute()
        if not target_user.data:
            raise ValueError("Target user not found")

        target_user_name = target_user.data[0]["name"]

        # Get workout
        if workout_log_id:
            workout = self.supabase.table("workout_logs").select("*").eq("id", workout_log_id).eq(
                "user_id", target_user_id
            ).execute()
        else:
            workout = self.supabase.table("workout_logs").select("*").eq(
                "user_id", target_user_id
            ).order("performance_data->total_volume", desc=True).limit(1).execute()

        if not workout.data:
            raise ValueError("No workouts found")

        workout_data = workout.data[0]
        perf_data = workout_data.get("performance_data", {})
        target_stats = {
            "duration_minutes": perf_data.get("duration_minutes", 0),
            "total_volume": perf_data.get("total_volume", 0),
            "exercises_count": perf_data.get("exercises_count", 0),
        }

        # Create challenge
        challenge = self.supabase.table("workout_challenges").insert({
            "from_user_id": user_id,
            "to_user_id": target_user_id,
            "workout_log_id": workout_data["id"],
            "workout_name": workout_data.get("workout_name", "Their Best Workout"),
            "workout_data": target_stats,
            "challenge_message": challenge_message,
            "status": "accepted",  # Auto-accept
            "accepted_at": datetime.now(timezone.utc).isoformat(),
            "challenger_stats": target_stats,
        }).execute()

        if not challenge.data:
            raise ValueError("Failed to create challenge")

        challenge_id = challenge.data[0]["id"]

        # Log to ChromaDB
        self._log_async_challenge(user_id, target_user_id, challenge_id, workout_data.get("workout_name"))

        return {
            "challenge_id": challenge_id,
            "target_user_name": target_user_name,
            "workout_name": workout_data.get("workout_name", "Their Best Workout"),
            "target_stats": target_stats,
        }

    # ============================================================
    # HELPER METHODS
    # ============================================================

    def _get_friend_ids(self, user_id: str) -> List[str]:
        """Get list of user's friend IDs."""
        result = self.supabase.table("connections").select("friend_id").eq(
            "user_id", user_id
        ).eq("status", "accepted").execute()

        return [f["friend_id"] for f in result.data] if result.data else []

    def _log_async_challenge(
        self,
        user_id: str,
        target_user_id: str,
        challenge_id: str,
        workout_name: str,
    ) -> None:
        """Log async challenge to ChromaDB."""
        try:
            challenger = self.supabase.table("users").select("name").eq("id", user_id).execute()
            target = self.supabase.table("users").select("name").eq("id", target_user_id).execute()

            challenger_name = challenger.data[0]["name"] if challenger.data else "User"
            target_name = target.data[0]["name"] if target.data else "User"

            collection = self.social_rag.get_social_collection()
            collection.add(
                documents=[f"{challenger_name} is attempting to BEAT {target_name}'s best workout '{workout_name}' (ASYNC challenge)"],
                metadatas=[{
                    "from_user_id": user_id,
                    "to_user_id": target_user_id,
                    "challenge_id": challenge_id,
                    "interaction_type": "async_challenge_created",
                    "workout_name": workout_name,
                    "is_async": True,
                    "created_at": datetime.now(timezone.utc).isoformat(),
                }],
                ids=[f"async_challenge_{challenge_id}"],
            )
            print(f"🏆 [Leaderboard] Async challenge logged: {challenger_name} vs {target_name}")
        except Exception as e:
            print(f"⚠️ [Leaderboard] Failed to log to ChromaDB: {e}")
