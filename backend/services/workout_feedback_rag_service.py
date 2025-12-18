"""
Workout Feedback RAG Service.

This service stores and retrieves workout performance data for AI Coach feedback.
Uses ChromaDB to store workout session data including:
- Sets, reps, weights
- Rest intervals
- Time taken
- Calories burned
- Weight progression

The AI Coach uses this data to provide personalized, short feedback after each workout.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime
import uuid
import json

from core.config import get_settings
from core.chroma_cloud import get_chroma_cloud_client
from services.gemini_service import GeminiService

settings = get_settings()


class WorkoutFeedbackRAGService:
    """
    RAG service for workout performance feedback.

    Stores completed workout sessions with all performance metrics,
    enabling the AI Coach to:
    1. Compare current session to previous sessions
    2. Track weight progression on exercises
    3. Analyze rest patterns
    4. Provide personalized feedback
    """

    COLLECTION_NAME = "workout_performance_feedback"

    def __init__(self, gemini_service: GeminiService):
        self.gemini_service = gemini_service

        # Get Chroma Cloud client
        self.chroma_client = get_chroma_cloud_client()

        # Collection for workout performance data
        self.collection = self.chroma_client.get_or_create_collection(
            self.COLLECTION_NAME
        )

        print(f"✅ Workout Feedback RAG initialized: {self.collection.count()} sessions")

    async def index_workout_session(
        self,
        workout_log_id: str,
        workout_id: str,
        user_id: str,
        workout_name: str,
        workout_type: str,
        exercises: List[Dict[str, Any]],  # List of {name, sets, reps, weight_kg}
        total_time_seconds: int,
        total_rest_seconds: int,
        avg_rest_seconds: float,
        calories_burned: int,
        total_sets: int,
        total_reps: int,
        total_volume_kg: float,
        completed_at: str,
    ) -> str:
        """
        Index a completed workout session for RAG retrieval.

        Args:
            workout_log_id: Unique workout log ID
            workout_id: Reference to workout template
            user_id: User ID
            workout_name: Name of workout
            workout_type: Type (strength, cardio, etc.)
            exercises: List of exercises with sets/reps/weights
            total_time_seconds: Total workout duration
            total_rest_seconds: Total rest time
            avg_rest_seconds: Average rest between sets
            calories_burned: Estimated calories burned
            total_sets: Total sets completed
            total_reps: Total reps completed
            total_volume_kg: Total weight volume (sets * reps * weight)
            completed_at: ISO timestamp when completed

        Returns:
            Document ID
        """
        doc_id = f"session_{workout_log_id}"

        # Build exercise summary for embedding
        exercise_summaries = []
        for ex in exercises[:10]:  # Limit to 10 exercises for embedding
            ex_summary = f"{ex.get('name', 'Unknown')}"
            if ex.get('weight_kg'):
                ex_summary += f" @ {ex['weight_kg']}kg"
            if ex.get('reps'):
                ex_summary += f" x {ex['reps']} reps"
            exercise_summaries.append(ex_summary)

        exercise_text = ", ".join(exercise_summaries)

        # Create searchable text for embedding
        session_text = (
            f"Workout: {workout_name}\n"
            f"Type: {workout_type}\n"
            f"Exercises: {exercise_text}\n"
            f"Duration: {total_time_seconds // 60} minutes\n"
            f"Rest Time: {total_rest_seconds // 60} minutes (avg {avg_rest_seconds:.0f}s between sets)\n"
            f"Calories: {calories_burned} kcal\n"
            f"Sets: {total_sets}, Reps: {total_reps}, Volume: {total_volume_kg:.1f}kg\n"
            f"Date: {completed_at}"
        )

        # Get embedding
        embedding = await self.gemini_service.get_embedding_async(session_text)

        # Upsert to collection
        try:
            self.collection.delete(ids=[doc_id])
        except Exception:
            pass

        self.collection.add(
            ids=[doc_id],
            embeddings=[embedding],
            documents=[session_text],
            metadatas=[{
                "workout_log_id": workout_log_id,
                "workout_id": workout_id,
                "user_id": user_id,
                "workout_name": workout_name,
                "workout_type": workout_type,
                "exercise_count": len(exercises),
                "exercises_json": json.dumps(exercises[:10]),  # Store up to 10 exercises
                "total_time_seconds": total_time_seconds,
                "total_rest_seconds": total_rest_seconds,
                "avg_rest_seconds": avg_rest_seconds,
                "calories_burned": calories_burned,
                "total_sets": total_sets,
                "total_reps": total_reps,
                "total_volume_kg": total_volume_kg,
                "completed_at": completed_at,
            }],
        )

        print(f"🏋️ Indexed workout session: {workout_name} for user {user_id}")
        return doc_id

    async def get_user_workout_history(
        self,
        user_id: str,
        n_results: int = 10,
        workout_type: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get a user's workout history.

        Args:
            user_id: User ID
            n_results: Number of results
            workout_type: Optional filter by workout type

        Returns:
            List of workout sessions
        """
        if self.collection.count() == 0:
            return []

        # Build where filter
        where_filter = {"user_id": user_id}
        if workout_type:
            where_filter["workout_type"] = workout_type

        # Get all matching sessions
        results = self.collection.get(
            where=where_filter,
            include=["documents", "metadatas"],
            limit=n_results,
        )

        sessions = []
        for i, doc_id in enumerate(results["ids"]):
            meta = results["metadatas"][i]
            # Parse exercises JSON
            exercises = []
            if meta.get("exercises_json"):
                try:
                    exercises = json.loads(meta["exercises_json"])
                except json.JSONDecodeError:
                    pass

            sessions.append({
                "id": doc_id,
                "document": results["documents"][i],
                "metadata": {**meta, "exercises": exercises},
            })

        return sessions

    async def find_similar_exercise_sessions(
        self,
        exercise_name: str,
        user_id: str,
        n_results: int = 5,
    ) -> List[Dict[str, Any]]:
        """
        Find past sessions with similar exercises for weight comparison.

        Args:
            exercise_name: Name of exercise to search for
            user_id: User ID
            n_results: Number of results

        Returns:
            List of sessions containing the exercise
        """
        if self.collection.count() == 0:
            return []

        # Search for sessions containing this exercise
        query = f"Exercise: {exercise_name}"
        query_embedding = await self.gemini_service.get_embedding_async(query)

        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=min(n_results, self.collection.count()),
            where={"user_id": user_id},
            include=["documents", "metadatas", "distances"],
        )

        similar_sessions = []
        for i, doc_id in enumerate(results["ids"][0]):
            distance = results["distances"][0][i]
            # Cosine distance: 0-2 range, convert to similarity 0-1
            similarity = 1 - (distance / 2)

            if similarity >= 0.5:  # Lower threshold for exercise matching
                meta = results["metadatas"][0][i]
                exercises = []
                if meta.get("exercises_json"):
                    try:
                        exercises = json.loads(meta["exercises_json"])
                    except json.JSONDecodeError:
                        pass

                # Check if exercise is actually in this session
                has_exercise = any(
                    exercise_name.lower() in ex.get("name", "").lower()
                    for ex in exercises
                )

                if has_exercise:
                    similar_sessions.append({
                        "id": doc_id,
                        "document": results["documents"][0][i],
                        "metadata": {**meta, "exercises": exercises},
                        "similarity": similarity,
                    })

        return similar_sessions

    async def get_exercise_weight_history(
        self,
        user_id: str,
        exercise_name: str,
        n_results: int = 10,
    ) -> List[Dict[str, Any]]:
        """
        Get weight history for a specific exercise.

        Args:
            user_id: User ID
            exercise_name: Exercise name
            n_results: Number of results

        Returns:
            List of {date, weight_kg, reps} for the exercise
        """
        sessions = await self.find_similar_exercise_sessions(
            exercise_name, user_id, n_results
        )

        weight_history = []
        for session in sessions:
            exercises = session["metadata"].get("exercises", [])
            for ex in exercises:
                if exercise_name.lower() in ex.get("name", "").lower():
                    weight_history.append({
                        "date": session["metadata"].get("completed_at"),
                        "weight_kg": ex.get("weight_kg", 0),
                        "reps": ex.get("reps", 0),
                        "sets": ex.get("sets", 0),
                        "workout_name": session["metadata"].get("workout_name"),
                    })

        # Sort by date (most recent first)
        weight_history.sort(key=lambda x: x["date"] or "", reverse=True)
        return weight_history

    def format_feedback_context(
        self,
        current_session: Dict[str, Any],
        past_sessions: List[Dict[str, Any]],
        weight_progressions: Dict[str, List[Dict[str, Any]]],
    ) -> str:
        """
        Format workout data into context for AI feedback generation.

        Args:
            current_session: Current workout session data
            past_sessions: List of past sessions for comparison
            weight_progressions: Dict of {exercise_name: weight_history}

        Returns:
            Formatted context string for AI prompt
        """
        context_parts = ["CURRENT WORKOUT SESSION:"]

        # Current session details
        context_parts.append(f"""
Workout: {current_session.get('workout_name', 'Unknown')}
Duration: {current_session.get('total_time_seconds', 0) // 60} minutes
Total Rest: {current_session.get('total_rest_seconds', 0) // 60} minutes
Average Rest Between Sets: {current_session.get('avg_rest_seconds', 0):.0f} seconds
Calories Burned: {current_session.get('calories_burned', 0)} kcal
Sets Completed: {current_session.get('total_sets', 0)}
Total Reps: {current_session.get('total_reps', 0)}
Total Volume: {current_session.get('total_volume_kg', 0):.1f} kg
""")

        # Current exercises
        exercises = current_session.get('exercises', [])
        if exercises:
            context_parts.append("\nExercises Performed:")
            for ex in exercises:
                context_parts.append(
                    f"  - {ex.get('name', 'Unknown')}: "
                    f"{ex.get('sets', 0)} sets x {ex.get('reps', 0)} reps @ {ex.get('weight_kg', 0)}kg"
                )

        # Weight progressions
        if weight_progressions:
            context_parts.append("\n\nWEIGHT PROGRESSION COMPARISON:")
            for exercise_name, history in weight_progressions.items():
                if len(history) >= 2:
                    current = history[0]
                    previous = history[1]
                    diff = current.get('weight_kg', 0) - previous.get('weight_kg', 0)
                    if diff > 0:
                        context_parts.append(
                            f"  - {exercise_name}: +{diff}kg improvement "
                            f"(previous: {previous.get('weight_kg', 0)}kg -> now: {current.get('weight_kg', 0)}kg)"
                        )
                    elif diff < 0:
                        context_parts.append(
                            f"  - {exercise_name}: {diff}kg decrease "
                            f"(previous: {previous.get('weight_kg', 0)}kg -> now: {current.get('weight_kg', 0)}kg)"
                        )
                    else:
                        context_parts.append(
                            f"  - {exercise_name}: maintained at {current.get('weight_kg', 0)}kg"
                        )

        # Past session comparison
        if past_sessions:
            context_parts.append("\n\nRECENT WORKOUT HISTORY:")
            for i, session in enumerate(past_sessions[:3], 1):
                meta = session.get("metadata", {})
                context_parts.append(
                    f"  {i}. {meta.get('workout_name', 'Unknown')} "
                    f"({meta.get('completed_at', 'Unknown date')[:10]}): "
                    f"{meta.get('total_time_seconds', 0) // 60}min, "
                    f"{meta.get('total_sets', 0)} sets, "
                    f"{meta.get('calories_burned', 0)} kcal"
                )

        return "\n".join(context_parts)

    def get_stats(self) -> Dict[str, Any]:
        """Get workout feedback RAG statistics."""
        return {
            "total_sessions": self.collection.count(),
            "storage": "chroma_cloud",
            "collection": self.COLLECTION_NAME,
        }


async def generate_workout_feedback(
    gemini_service: GeminiService,
    rag_service: WorkoutFeedbackRAGService,
    user_id: str,
    current_session: Dict[str, Any],
) -> str:
    """
    Generate AI Coach feedback for a completed workout.

    Args:
        gemini_service: Gemini service for LLM
        rag_service: Workout feedback RAG service
        user_id: User ID
        current_session: Current workout session data

    Returns:
        Short, personalized AI Coach feedback
    """
    # Get past sessions for comparison
    past_sessions = await rag_service.get_user_workout_history(user_id, n_results=5)

    # Get weight progressions for each exercise
    exercises = current_session.get("exercises", [])
    weight_progressions = {}
    for ex in exercises[:5]:  # Limit to 5 exercises
        exercise_name = ex.get("name", "")
        if exercise_name:
            history = await rag_service.get_exercise_weight_history(
                user_id, exercise_name, n_results=5
            )
            if history:
                weight_progressions[exercise_name] = history

    # Format context for AI
    context = rag_service.format_feedback_context(
        current_session, past_sessions, weight_progressions
    )

    # Generate feedback using Gemini
    system_prompt = """You are a supportive AI Fitness Coach providing short, personalized feedback after a workout.

IMPORTANT RULES:
1. Keep feedback to 2-3 short sentences MAX
2. Be encouraging but specific
3. Mention ONE specific achievement (weight increase, time improvement, etc.)
4. If user improved weights, celebrate it!
5. If rest times were short/long, provide ONE quick tip
6. End with a brief motivational note

Examples of good feedback:
- "Great session! You increased your bench press by 2.5kg - that's real progress. Keep pushing!"
- "Solid 45-minute workout with 320 calories burned. Your rest times were consistent. You're building great habits!"
- "You crushed 28 sets today! I noticed you went heavier on squats - your legs are getting stronger."

DO NOT:
- Write long paragraphs
- List multiple points
- Be generic
- Use too many emojis"""

    user_prompt = f"""Based on this workout data, provide SHORT personalized feedback (2-3 sentences max):

{context}

Remember: Be specific, encouraging, and brief!"""

    # Call Gemini using the chat method
    feedback = await gemini_service.chat(
        user_message=user_prompt,
        system_prompt=system_prompt,
    )

    if not feedback:
        feedback = "Great workout! Keep up the momentum!"
    print(f"🎯 Generated feedback for user {user_id}: {feedback[:50]}...")

    return feedback
