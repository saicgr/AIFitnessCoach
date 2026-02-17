"""
Social RAG Service - Manages social activity data in ChromaDB for AI context.

This service stores social activities, reactions, and user interactions in ChromaDB
to provide the AI with context about:
- User's recent workout activities
- Social interactions (reactions, comments)
- Friend activities and engagement patterns
- Challenge participation
"""

import json
from datetime import datetime, timezone
from typing import List, Dict, Optional
from uuid import uuid4

from core.chroma_cloud import get_chroma_cloud_client


class SocialRAGService:
    """Service for managing social data in ChromaDB."""

    def __init__(self):
        self.chroma_client = get_chroma_cloud_client()
        self.collection_name = "social_activities"
        self._collection = None

    def get_social_collection(self):
        """Get or create the social activities collection (cached)."""
        if self._collection is None:
            self._collection = self.chroma_client.get_or_create_collection(self.collection_name)
        return self._collection

    def add_activity_to_rag(
        self,
        activity_id: str,
        user_id: str,
        user_name: str,
        activity_type: str,
        activity_data: Dict,
        visibility: str,
        created_at: datetime,
    ) -> None:
        """
        Add a social activity to ChromaDB for AI context.

        Args:
            activity_id: Unique activity ID from Supabase
            user_id: User who created the activity
            user_name: User's display name
            activity_type: Type of activity (workout_completed, achievement_earned, etc.)
            activity_data: Activity details (workout name, stats, etc.)
            visibility: Activity visibility setting
            created_at: When the activity was created
        """
        # Build a natural language description for embedding
        document_text = self._build_activity_document(
            user_name=user_name,
            activity_type=activity_type,
            activity_data=activity_data,
            created_at=created_at,
        )

        # Metadata for filtering
        metadata = {
            "user_id": user_id,
            "user_name": user_name,
            "activity_type": activity_type,
            "visibility": visibility,
            "created_at": created_at.isoformat(),
            "has_exercises": "exercises_performance" in activity_data,
            "exercise_count": len(activity_data.get("exercises_performance", [])),
        }

        # Add to ChromaDB
        collection = self.get_social_collection()
        collection.add(
            documents=[document_text],
            metadatas=[metadata],
            ids=[f"activity_{activity_id}"],
        )

        print(f"✅ Added activity {activity_id} to social RAG")

    def add_reaction_to_rag(
        self,
        reaction_id: str,
        activity_id: str,
        user_id: str,
        user_name: str,
        reaction_type: str,
        activity_owner: str,
        created_at: datetime,
    ) -> None:
        """
        Add a reaction to ChromaDB for AI context (social engagement tracking).

        Args:
            reaction_id: Unique reaction ID
            activity_id: Activity being reacted to
            user_id: User who reacted
            user_name: User's display name
            reaction_type: Type of reaction (fire, cheer, strong, etc.)
            activity_owner: User who owns the activity
            created_at: When reaction was created
        """
        # Build natural language description
        document_text = f"{user_name} reacted with {reaction_type} to {activity_owner}'s activity"

        metadata = {
            "user_id": user_id,
            "user_name": user_name,
            "activity_id": activity_id,
            "activity_owner": activity_owner,
            "reaction_type": reaction_type,
            "interaction_type": "reaction",
            "created_at": created_at.isoformat(),
        }

        collection = self.get_social_collection()
        collection.add(
            documents=[document_text],
            metadatas=[metadata],
            ids=[f"reaction_{reaction_id}"],
        )

        print(f"✅ Added reaction {reaction_id} to social RAG")

    def remove_reaction_from_rag(self, reaction_id: str) -> None:
        """Remove a reaction from ChromaDB when deleted."""
        try:
            collection = self.get_social_collection()
            collection.delete(ids=[f"reaction_{reaction_id}"])
            print(f"✅ Removed reaction {reaction_id} from social RAG")
        except Exception as e:
            print(f"⚠️ Failed to remove reaction {reaction_id}: {e}")

    def get_user_recent_activities(
        self,
        user_id: str,
        n_results: int = 10,
    ) -> List[Dict]:
        """
        Get user's recent activities from ChromaDB.

        Args:
            user_id: User ID
            n_results: Number of results to return

        Returns:
            List of activity documents and metadata
        """
        collection = self.get_social_collection()

        results = collection.query(
            query_texts=[f"Recent activities for user {user_id}"],
            n_results=n_results,
            where={"user_id": user_id},
        )

        return self._format_query_results(results)

    def get_friend_activities_context(
        self,
        friend_ids: List[str],
        n_results: int = 20,
    ) -> str:
        """
        Get recent friend activities as context for AI coaching.

        Args:
            friend_ids: List of friend user IDs
            n_results: Number of results to return

        Returns:
            Formatted string of friend activities for AI context
        """
        collection = self.get_social_collection()

        # Query for friends' activities
        results = collection.get(
            where={"$and": [
                {"activity_type": {"$ne": ""}},  # Any activity
                {"visibility": {"$in": ["public", "friends"]}},
            ]},
            limit=n_results,
        )

        # Filter to friends only
        friend_activities = []
        if results and results.get("metadatas"):
            for doc, meta in zip(results["documents"], results["metadatas"]):
                if meta.get("user_id") in friend_ids:
                    friend_activities.append(f"- {doc}")

        if not friend_activities:
            return "No recent friend activity."

        return "Recent friend activity:\n" + "\n".join(friend_activities[:10])

    def get_social_engagement_context(
        self,
        user_id: str,
        days_back: int = 7,
    ) -> Dict:
        """
        Get user's social engagement metrics for AI context.

        Args:
            user_id: User ID
            days_back: Number of days to look back

        Returns:
            Dict with engagement metrics
        """
        collection = self.get_social_collection()

        # Get reactions given by user
        reactions_given = collection.query(
            query_texts=[f"Reactions by {user_id}"],
            where={
                "$and": [
                    {"user_id": user_id},
                    {"interaction_type": "reaction"},
                ]
            },
            n_results=100,
        )

        # Get reactions received (reactions to user's activities)
        reactions_received = collection.query(
            query_texts=[f"Reactions to {user_id}"],
            where={
                "$and": [
                    {"activity_owner": user_id},
                    {"interaction_type": "reaction"},
                ]
            },
            n_results=100,
        )

        return {
            "reactions_given_count": len(reactions_given.get("ids", [[]])[0]),
            "reactions_received_count": len(reactions_received.get("ids", [[]])[0]),
            "is_socially_active": len(reactions_given.get("ids", [[]])[0]) > 0,
        }

    def delete_activity_from_rag(self, activity_id: str) -> None:
        """Remove an activity from ChromaDB when deleted."""
        try:
            collection = self.get_social_collection()
            collection.delete(ids=[f"activity_{activity_id}"])
            print(f"✅ Removed activity {activity_id} from social RAG")
        except Exception as e:
            print(f"⚠️ Failed to remove activity {activity_id}: {e}")

    def _build_activity_document(
        self,
        user_name: str,
        activity_type: str,
        activity_data: Dict,
        created_at: datetime,
    ) -> str:
        """Build a natural language document from activity data."""
        date_str = created_at.strftime("%B %d, %Y")

        if activity_type == "workout_completed":
            workout_name = activity_data.get("workout_name", "a workout")
            duration = activity_data.get("duration_minutes", 0)
            exercises_count = activity_data.get("exercises_count", 0)

            doc = f"{user_name} completed {workout_name} on {date_str}. "
            doc += f"The workout took {duration} minutes and included {exercises_count} exercises. "

            # Add exercise details if available
            exercises = activity_data.get("exercises_performance", [])
            if exercises:
                doc += "Exercises performed: "
                exercise_strs = []
                for ex in exercises[:5]:  # First 5 exercises
                    name = ex.get("name", "")
                    sets = ex.get("sets", 0)
                    reps = ex.get("reps", 0)
                    weight = ex.get("weight_kg", 0)
                    exercise_strs.append(f"{name} ({sets}x{reps} @ {weight}kg)")
                doc += ", ".join(exercise_strs) + "."

            total_volume = activity_data.get("total_volume")
            if total_volume:
                doc += f" Total volume: {total_volume}kg."

        elif activity_type == "achievement_earned":
            achievement = activity_data.get("achievement_name", "an achievement")
            doc = f"{user_name} earned the achievement '{achievement}' on {date_str}."

        elif activity_type == "personal_record":
            exercise = activity_data.get("exercise_name", "an exercise")
            value = activity_data.get("pr_value", "")
            doc = f"{user_name} set a new personal record in {exercise}: {value} on {date_str}."

        elif activity_type == "streak_milestone":
            days = activity_data.get("streak_days", 0)
            doc = f"{user_name} reached a {days}-day workout streak on {date_str}!"

        elif activity_type == "weight_milestone":
            change = activity_data.get("weight_change", 0)
            direction = "lost" if change < 0 else "gained"
            doc = f"{user_name} {direction} {abs(change)} lbs as of {date_str}."

        else:
            doc = f"{user_name} had activity of type {activity_type} on {date_str}."

        return doc

    def _format_query_results(self, results: Dict) -> List[Dict]:
        """Format ChromaDB query results into a clean list."""
        formatted = []

        if not results or not results.get("ids"):
            return formatted

        ids = results["ids"][0] if results["ids"] else []
        documents = results["documents"][0] if results.get("documents") else []
        metadatas = results["metadatas"][0] if results.get("metadatas") else []

        for i, doc_id in enumerate(ids):
            formatted.append({
                "id": doc_id,
                "document": documents[i] if i < len(documents) else "",
                "metadata": metadatas[i] if i < len(metadatas) else {},
            })

        return formatted


# Singleton instance
_social_rag_service: Optional[SocialRAGService] = None


def get_social_rag_service() -> SocialRAGService:
    """Get the global Social RAG service instance."""
    global _social_rag_service
    if _social_rag_service is None:
        _social_rag_service = SocialRAGService()
    return _social_rag_service
