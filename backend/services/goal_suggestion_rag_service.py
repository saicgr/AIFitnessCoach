"""
Goal Suggestion RAG Service - Intelligent goal suggestions using ChromaDB.

This service analyzes:
1. User's workout history from ChromaDB
2. User's personal records
3. Friends' current goals
4. Exercise patterns and preferences

To generate intelligent, personalized goal suggestions.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta, timezone
import json
from core.chroma_cloud import get_chroma_cloud_client, ChromaCloudClient
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.gemini_service import GeminiService, get_gemini_service

logger = get_logger(__name__)


class GoalSuggestionRAGService:
    """
    RAG service for generating intelligent goal suggestions.

    Uses ChromaDB to:
    1. Find exercises user has performed frequently
    2. Analyze workout patterns and progress
    3. Identify exercises user excels at or should improve
    4. Consider user preferences and equipment
    """

    def __init__(self, gemini_service: Optional[GeminiService] = None):
        self.gemini_service = gemini_service or get_gemini_service()
        self.chroma_client: ChromaCloudClient = get_chroma_cloud_client()

        # Collections
        self.workout_collection = self.chroma_client.get_workout_collection()

        logger.info(f"GoalSuggestionRAGService initialized with {self.workout_collection.count()} workout docs")

    async def analyze_workout_history(
        self,
        user_id: str,
        n_results: int = 20,
    ) -> Dict[str, Any]:
        """
        Analyze user's workout history from ChromaDB.

        Returns exercise frequencies, recent performance, and patterns.
        """
        try:
            # Query workout collection for user's workouts
            results = self.workout_collection.get(
                where={"user_id": user_id},
                include=["documents", "metadatas"],
                limit=n_results,
            )

            if not results or not results.get("ids"):
                logger.info(f"No workout history found for user {user_id}")
                return {
                    "exercise_counts": {},
                    "recent_workouts": [],
                    "workout_types": {},
                    "total_workouts": 0,
                }

            exercise_counts = {}
            workout_types = {}
            recent_workouts = []

            for i, metadata in enumerate(results.get("metadatas", [])):
                if not metadata:
                    continue

                # Track workout types
                wtype = metadata.get("type", "unknown")
                workout_types[wtype] = workout_types.get(wtype, 0) + 1

                # Parse exercises from document text
                doc_text = results["documents"][i] if i < len(results.get("documents", [])) else ""
                if "Exercises:" in doc_text:
                    exercises_str = doc_text.split("Exercises:")[1].split("\n")[0].strip()
                    for exercise in exercises_str.split(","):
                        exercise = exercise.strip()
                        if exercise and "more" not in exercise:
                            exercise_counts[exercise] = exercise_counts.get(exercise, 0) + 1

                recent_workouts.append({
                    "name": metadata.get("name", "Unknown"),
                    "type": wtype,
                    "date": metadata.get("scheduled_date", ""),
                    "completed": metadata.get("is_completed", False),
                    "exercise_count": metadata.get("exercise_count", 0),
                })

            return {
                "exercise_counts": exercise_counts,
                "recent_workouts": recent_workouts,
                "workout_types": workout_types,
                "total_workouts": len(results.get("ids", [])),
            }

        except Exception as e:
            logger.error(f"Error analyzing workout history: {e}")
            return {
                "exercise_counts": {},
                "recent_workouts": [],
                "workout_types": {},
                "total_workouts": 0,
            }

    async def get_user_exercise_performance(
        self,
        user_id: str,
    ) -> Dict[str, Dict[str, Any]]:
        """
        Get user's performance data for exercises from personal records.
        """
        try:
            db = get_supabase_db()

            # Get personal records
            records = db.client.table("personal_goal_records").select("*").eq(
                "user_id", user_id
            ).execute()

            # Get recent goal history
            past_goals = db.client.table("weekly_personal_goals").select("*").eq(
                "user_id", user_id
            ).order("week_end", desc=True).limit(50).execute()

            performance = {}

            # Process records
            for record in records.data:
                exercise = record["exercise_name"]
                goal_type = record["goal_type"]
                key = f"{exercise}_{goal_type}"

                performance[key] = {
                    "exercise_name": exercise,
                    "goal_type": goal_type,
                    "personal_best": record["record_value"],
                    "achieved_at": record["achieved_at"],
                    "weekly_values": [],
                    "completion_rate": 0,
                    "improvement_trend": 0,
                }

            # Add weekly data
            for goal in past_goals.data:
                key = f"{goal['exercise_name']}_{goal['goal_type']}"

                if key not in performance:
                    performance[key] = {
                        "exercise_name": goal["exercise_name"],
                        "goal_type": goal["goal_type"],
                        "personal_best": goal.get("personal_best"),
                        "achieved_at": None,
                        "weekly_values": [],
                        "completion_rate": 0,
                        "improvement_trend": 0,
                    }

                if goal["current_value"] > 0:
                    performance[key]["weekly_values"].append({
                        "value": goal["current_value"],
                        "target": goal["target_value"],
                        "week": goal["week_start"],
                        "status": goal["status"],
                    })

            # Calculate metrics
            for key, data in performance.items():
                values = data["weekly_values"]
                if values:
                    completed = sum(1 for v in values if v["status"] == "completed")
                    data["completion_rate"] = completed / len(values)

                    # Trend: compare recent values to older ones
                    if len(values) >= 3:
                        recent = sum(v["value"] for v in values[:2]) / 2
                        older = sum(v["value"] for v in values[-2:]) / 2
                        if older > 0:
                            data["improvement_trend"] = (recent - older) / older

            return performance

        except Exception as e:
            logger.error(f"Error getting user exercise performance: {e}")
            return {}

    async def find_similar_exercises(
        self,
        query: str,
        n_results: int = 5,
    ) -> List[Dict[str, Any]]:
        """
        Find exercises similar to the query using ChromaDB.
        """
        try:
            # Get exercise collection
            exercise_collection = self.chroma_client.get_exercise_collection()

            if exercise_collection.count() == 0:
                return []

            # Get query embedding
            query_embedding = await self.gemini_service.get_embedding_async(query)

            results = exercise_collection.query(
                query_embeddings=[query_embedding],
                n_results=min(n_results, exercise_collection.count()),
                include=["documents", "metadatas", "distances"],
            )

            exercises = []
            for i, doc_id in enumerate(results.get("ids", [[]])[0]):
                metadata = results["metadatas"][0][i] if results.get("metadatas") else {}
                distance = results["distances"][0][i] if results.get("distances") else 1.0
                similarity = 1 - (distance / 2)

                exercises.append({
                    "id": doc_id,
                    "name": metadata.get("name", doc_id),
                    "muscle_group": metadata.get("muscle_group", ""),
                    "equipment": metadata.get("equipment", []),
                    "difficulty": metadata.get("difficulty", ""),
                    "similarity": similarity,
                })

            return exercises

        except Exception as e:
            logger.error(f"Error finding similar exercises: {e}")
            return []

    async def generate_ai_suggestions(
        self,
        user_id: str,
        workout_history: Dict[str, Any],
        performance_data: Dict[str, Dict[str, Any]],
        friends_goals: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """
        Use Gemini AI to generate personalized goal suggestions.
        """
        try:
            # Build context
            context_parts = []

            # Workout history context
            if workout_history["total_workouts"] > 0:
                top_exercises = sorted(
                    workout_history["exercise_counts"].items(),
                    key=lambda x: x[1],
                    reverse=True
                )[:10]
                context_parts.append(f"User's most performed exercises: {', '.join(e[0] for e in top_exercises)}")
                context_parts.append(f"Total indexed workouts: {workout_history['total_workouts']}")

            # Performance context
            if performance_data:
                for key, data in list(performance_data.items())[:5]:
                    pb = data.get("personal_best")
                    if pb:
                        context_parts.append(
                            f"- {data['exercise_name']} ({data['goal_type']}): "
                            f"PB={pb}, Completion rate={data['completion_rate']:.0%}, "
                            f"Trend={data['improvement_trend']:+.0%}"
                        )

            # Friends context
            if friends_goals:
                friend_exercises = set(g["exercise_name"] for g in friends_goals[:10])
                context_parts.append(f"Friends are doing: {', '.join(friend_exercises)}")

            context = "\n".join(context_parts)

            prompt = f"""Based on this user's fitness data, suggest 6 weekly goals.

USER CONTEXT:
{context}

Generate suggestions in these categories:
1. "beat_your_records" - Goals to beat existing PRs (suggest 10-15% increase)
2. "popular_with_friends" - Goals friends are doing (if available)
3. "new_challenges" - New exercises to try

For each suggestion, provide:
- exercise_name: The exercise
- goal_type: "single_max" (max reps in one set) or "weekly_volume" (total reps over week)
- target: Numeric target
- reasoning: 1 sentence motivation
- category: One of the three categories above

Return ONLY valid JSON array. Example:
[
  {{"exercise_name": "Push-ups", "goal_type": "single_max", "target": 35, "reasoning": "Beat your PR of 32!", "category": "beat_your_records"}},
  {{"exercise_name": "Squats", "goal_type": "weekly_volume", "target": 150, "reasoning": "3 friends are crushing squats this week!", "category": "popular_with_friends"}}
]

Return exactly 6 suggestions (2 per category)."""

            response = await self.gemini_service.generate_content_async(
                prompt,
                system_instruction="You are a fitness AI that generates goal suggestions. Return ONLY valid JSON array, no markdown."
            )

            # Parse response
            response_text = response.text.strip()

            # Clean markdown if present
            if response_text.startswith("```"):
                response_text = response_text.split("```")[1]
                if response_text.startswith("json"):
                    response_text = response_text[4:]
            if response_text.endswith("```"):
                response_text = response_text[:-3]

            suggestions = json.loads(response_text.strip())

            logger.info(f"AI generated {len(suggestions)} suggestions for user {user_id}")
            return suggestions

        except Exception as e:
            logger.error(f"Error generating AI suggestions: {e}")
            return []

    async def get_friends_current_goals(
        self,
        user_id: str,
        week_start: date,
    ) -> List[Dict[str, Any]]:
        """
        Get goals that the user's friends are currently doing.
        """
        try:
            db = get_supabase_db()

            # Get user's friends
            friends_result = db.client.table("user_connections").select(
                "following_id, follower_id"
            ).or_(
                f"follower_id.eq.{user_id},following_id.eq.{user_id}"
            ).eq("status", "active").execute()

            friend_ids = set()
            for conn in friends_result.data:
                if conn["follower_id"] == user_id:
                    friend_ids.add(conn["following_id"])
                else:
                    friend_ids.add(conn["follower_id"])

            if not friend_ids:
                return []

            # Get friends' goals with user info
            goals_result = db.client.table("weekly_personal_goals").select(
                "*, users(id, display_name, photo_url)"
            ).in_("user_id", list(friend_ids)).eq(
                "week_start", week_start.isoformat()
            ).eq("status", "active").in_(
                "visibility", ["friends", "public"]
            ).execute()

            goals = []
            for goal in goals_result.data:
                user_data = goal.get("users", {}) or {}
                goals.append({
                    "exercise_name": goal["exercise_name"],
                    "goal_type": goal["goal_type"],
                    "target_value": goal["target_value"],
                    "current_value": goal["current_value"],
                    "friend_id": goal["user_id"],
                    "friend_name": user_data.get("display_name", "Friend"),
                    "friend_avatar": user_data.get("photo_url"),
                    "progress": (goal["current_value"] / goal["target_value"] * 100) if goal["target_value"] > 0 else 0,
                })

            return goals

        except Exception as e:
            logger.error(f"Error getting friends' goals: {e}")
            return []

    async def generate_enhanced_suggestions(
        self,
        user_id: str,
        week_start: date,
        use_ai: bool = True,
    ) -> Dict[str, List[Dict[str, Any]]]:
        """
        Generate enhanced goal suggestions using ChromaDB and optional AI.

        Returns suggestions organized by category.
        """
        try:
            # Gather data
            workout_history = await self.analyze_workout_history(user_id)
            performance_data = await self.get_user_exercise_performance(user_id)
            friends_goals = await self.get_friends_current_goals(user_id, week_start)

            suggestions = {
                "beat_your_records": [],
                "popular_with_friends": [],
                "new_challenges": [],
            }

            # 1. Performance-based suggestions (Beat Your Records)
            for key, data in performance_data.items():
                pb = data.get("personal_best")
                if pb and pb > 0:
                    # Suggest 10% increase
                    target = int(pb * 1.10)
                    suggestions["beat_your_records"].append({
                        "exercise_name": data["exercise_name"],
                        "goal_type": data["goal_type"],
                        "target": target,
                        "reasoning": f"Your best is {pb}. Go for {target}!",
                        "confidence": 0.85,
                        "source_data": {
                            "personal_best": pb,
                            "completion_rate": data.get("completion_rate", 0),
                            "improvement_trend": data.get("improvement_trend", 0),
                        },
                    })

            # 2. Friends suggestions
            goal_counts = {}
            for goal in friends_goals:
                key = f"{goal['exercise_name']}_{goal['goal_type']}"
                if key not in goal_counts:
                    goal_counts[key] = {
                        "exercise_name": goal["exercise_name"],
                        "goal_type": goal["goal_type"],
                        "count": 0,
                        "targets": [],
                        "friends": [],
                    }
                goal_counts[key]["count"] += 1
                goal_counts[key]["targets"].append(goal["target_value"])
                goal_counts[key]["friends"].append({
                    "id": goal["friend_id"],
                    "name": goal["friend_name"],
                    "avatar": goal["friend_avatar"],
                    "progress": goal["progress"],
                })

            sorted_friend_goals = sorted(
                goal_counts.values(),
                key=lambda x: x["count"],
                reverse=True
            )

            for data in sorted_friend_goals:
                avg_target = int(sum(data["targets"]) / len(data["targets"]))
                count = data["count"]
                suggestions["popular_with_friends"].append({
                    "exercise_name": data["exercise_name"],
                    "goal_type": data["goal_type"],
                    "target": avg_target,
                    "reasoning": f"{count} friend{'s' if count > 1 else ''} doing this!",
                    "confidence": min(0.9, 0.5 + (count * 0.1)),
                    "source_data": {
                        "friend_count": count,
                        "friends": data["friends"][:5],
                        "average_target": avg_target,
                    },
                })

            # 3. New challenges (exercises not tried or from workout history)
            done_exercises = set(d["exercise_name"] for d in performance_data.values())
            frequent_exercises = workout_history.get("exercise_counts", {})

            # Suggest exercises user does often but hasn't set goals for
            for exercise, count in sorted(frequent_exercises.items(), key=lambda x: x[1], reverse=True)[:5]:
                if exercise not in done_exercises:
                    suggestions["new_challenges"].append({
                        "exercise_name": exercise,
                        "goal_type": "weekly_volume",
                        "target": 50,  # Default target
                        "reasoning": f"You do {exercise} often - set a weekly goal!",
                        "confidence": 0.7,
                        "source_data": {"workout_frequency": count},
                    })

            # Add default challenges if needed
            if len(suggestions["new_challenges"]) < 2:
                defaults = [
                    ("Push-ups", "single_max", 30, "Classic test of strength!"),
                    ("Squats", "weekly_volume", 100, "Build leg power!"),
                    ("Burpees", "weekly_volume", 50, "Full-body challenge!"),
                    ("Plank", "single_max", 60, "Core stability test!"),
                ]
                for exercise, gtype, target, reason in defaults:
                    if exercise not in done_exercises and len(suggestions["new_challenges"]) < 4:
                        suggestions["new_challenges"].append({
                            "exercise_name": exercise,
                            "goal_type": gtype,
                            "target": target,
                            "reasoning": reason,
                            "confidence": 0.6,
                            "source_data": {"type": "default"},
                        })

            # Optionally enhance with AI
            if use_ai and (workout_history["total_workouts"] > 0 or performance_data):
                ai_suggestions = await self.generate_ai_suggestions(
                    user_id, workout_history, performance_data, friends_goals
                )

                # Merge AI suggestions (don't duplicate)
                existing_keys = set()
                for cat, items in suggestions.items():
                    for item in items:
                        existing_keys.add(f"{item['exercise_name']}_{item['goal_type']}")

                for ai_sugg in ai_suggestions:
                    key = f"{ai_sugg['exercise_name']}_{ai_sugg['goal_type']}"
                    category = ai_sugg.get("category", "new_challenges")

                    if key not in existing_keys and category in suggestions:
                        suggestions[category].append({
                            "exercise_name": ai_sugg["exercise_name"],
                            "goal_type": ai_sugg["goal_type"],
                            "target": ai_sugg["target"],
                            "reasoning": ai_sugg["reasoning"],
                            "confidence": 0.75,
                            "source_data": {"source": "ai"},
                        })
                        existing_keys.add(key)

            # Limit each category
            for cat in suggestions:
                suggestions[cat] = suggestions[cat][:4]

            logger.info(
                f"Generated suggestions for user {user_id}: "
                f"records={len(suggestions['beat_your_records'])}, "
                f"friends={len(suggestions['popular_with_friends'])}, "
                f"new={len(suggestions['new_challenges'])}"
            )

            return suggestions

        except Exception as e:
            logger.error(f"Error generating enhanced suggestions: {e}")
            return {
                "beat_your_records": [],
                "popular_with_friends": [],
                "new_challenges": [],
            }

    def get_stats(self) -> Dict[str, Any]:
        """Get RAG service statistics."""
        return {
            "workout_documents": self.workout_collection.count(),
            "storage": "chroma_cloud",
        }


# Singleton instance
_goal_suggestion_rag_service: Optional[GoalSuggestionRAGService] = None


def get_goal_suggestion_rag_service() -> GoalSuggestionRAGService:
    """Get the global GoalSuggestionRAGService instance."""
    global _goal_suggestion_rag_service
    if _goal_suggestion_rag_service is None:
        _goal_suggestion_rag_service = GoalSuggestionRAGService()
    return _goal_suggestion_rag_service
