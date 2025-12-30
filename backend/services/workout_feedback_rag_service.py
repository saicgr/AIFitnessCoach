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

    async def index_workout_feedback(
        self,
        user_id: str,
        workout_id: str,
        overall_rating: int,
        overall_difficulty: str,
        energy_level: str,
        exercise_ratings: List[Dict[str, Any]],
        feedback_at: str,
    ) -> str:
        """
        Index user workout feedback (ratings & difficulty) for AI workout adaptation.

        This data helps the AI:
        1. Adjust exercise difficulty based on user feedback
        2. Avoid exercises users rated poorly
        3. Include more exercises users enjoyed
        4. Personalize workout intensity based on energy levels

        Args:
            user_id: User ID
            workout_id: Workout ID
            overall_rating: Overall workout rating (1-5)
            overall_difficulty: "too_easy", "just_right", "too_hard"
            energy_level: "exhausted", "tired", "good", "energized"
            exercise_ratings: List of {exercise_name, rating, difficulty_felt, would_do_again}
            feedback_at: ISO timestamp

        Returns:
            Document ID
        """
        doc_id = f"feedback_{workout_id}_{user_id}"

        # Build exercise feedback text for embedding
        exercise_texts = []
        for ex in exercise_ratings[:10]:  # Limit to 10 exercises
            ex_name = ex.get("exercise_name", "Unknown")
            ex_rating = ex.get("rating", 3)
            ex_difficulty = ex.get("difficulty_felt", "just_right")
            would_do = "yes" if ex.get("would_do_again", True) else "no"

            rating_word = {1: "poor", 2: "fair", 3: "good", 4: "great", 5: "excellent"}.get(ex_rating, "good")
            exercise_texts.append(
                f"{ex_name}: rated {rating_word} ({ex_rating}/5), difficulty {ex_difficulty}, would do again: {would_do}"
            )

        exercises_text = "\n".join(exercise_texts) if exercise_texts else "No individual exercise ratings"

        # Map difficulty to human-readable text
        difficulty_text = {
            "too_easy": "workout was too easy, user wants more challenge",
            "just_right": "workout difficulty was appropriate",
            "too_hard": "workout was too hard, user needs easier exercises"
        }.get(overall_difficulty, "appropriate difficulty")

        energy_text = {
            "exhausted": "user felt exhausted after workout",
            "tired": "user felt tired after workout",
            "good": "user felt good after workout",
            "energized": "user felt energized after workout"
        }.get(energy_level, "good energy level")

        # Create searchable text for embedding
        feedback_text = (
            f"Workout Feedback for user {user_id}\n"
            f"Overall Rating: {overall_rating}/5 stars\n"
            f"Difficulty: {difficulty_text}\n"
            f"Energy Level: {energy_text}\n"
            f"Exercise Feedback:\n{exercises_text}\n"
            f"Date: {feedback_at}"
        )

        # Get embedding
        embedding = await self.gemini_service.get_embedding_async(feedback_text)

        # Delete existing feedback for this workout
        try:
            self.collection.delete(ids=[doc_id])
        except Exception:
            pass

        # Store in ChromaDB
        self.collection.add(
            ids=[doc_id],
            embeddings=[embedding],
            documents=[feedback_text],
            metadatas=[{
                "doc_type": "workout_feedback",
                "user_id": user_id,
                "workout_id": workout_id,
                "overall_rating": overall_rating,
                "overall_difficulty": overall_difficulty,
                "energy_level": energy_level,
                "exercise_count": len(exercise_ratings),
                "exercise_ratings_json": json.dumps(exercise_ratings[:10]),
                "feedback_at": feedback_at,
            }],
        )

        print(f"🎯 Indexed workout feedback: rating={overall_rating}, difficulty={overall_difficulty}")
        return doc_id

    async def get_user_exercise_feedback(
        self,
        user_id: str,
        exercise_name: str,
        n_results: int = 5,
    ) -> List[Dict[str, Any]]:
        """
        Get user's feedback history for a specific exercise.

        This helps the AI understand:
        - Does the user generally like this exercise?
        - Is it typically too easy/hard for them?
        - Should we include it in future workouts?

        Args:
            user_id: User ID
            exercise_name: Exercise name to search for
            n_results: Number of results

        Returns:
            List of feedback entries for the exercise
        """
        if self.collection.count() == 0:
            return []

        # Search for feedback containing this exercise
        query = f"Exercise feedback: {exercise_name}"
        query_embedding = await self.gemini_service.get_embedding_async(query)

        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=min(n_results * 2, self.collection.count()),  # Get more to filter
            where={"$and": [
                {"user_id": user_id},
                {"doc_type": "workout_feedback"}
            ]},
            include=["documents", "metadatas", "distances"],
        )

        exercise_feedback = []
        for i, doc_id in enumerate(results["ids"][0] if results["ids"] else []):
            meta = results["metadatas"][0][i]

            # Parse exercise ratings
            try:
                exercise_ratings = json.loads(meta.get("exercise_ratings_json", "[]"))
            except json.JSONDecodeError:
                exercise_ratings = []

            # Find the specific exercise
            for ex in exercise_ratings:
                if exercise_name.lower() in ex.get("exercise_name", "").lower():
                    exercise_feedback.append({
                        "workout_id": meta.get("workout_id"),
                        "feedback_at": meta.get("feedback_at"),
                        "exercise_name": ex.get("exercise_name"),
                        "rating": ex.get("rating"),
                        "difficulty_felt": ex.get("difficulty_felt"),
                        "would_do_again": ex.get("would_do_again"),
                        "overall_workout_rating": meta.get("overall_rating"),
                    })
                    break  # Only one rating per workout

        # Sort by date (most recent first)
        exercise_feedback.sort(key=lambda x: x.get("feedback_at", ""), reverse=True)
        return exercise_feedback[:n_results]

    async def get_user_difficulty_preferences(
        self,
        user_id: str,
        n_results: int = 10,
    ) -> Dict[str, Any]:
        """
        Analyze user's difficulty preferences from feedback history.

        Returns aggregated stats to help AI calibrate workout intensity.

        Args:
            user_id: User ID
            n_results: Number of recent feedbacks to analyze

        Returns:
            Dict with difficulty preference analysis
        """
        if self.collection.count() == 0:
            return {"status": "no_data"}

        # Get recent feedback
        results = self.collection.get(
            where={"$and": [
                {"user_id": user_id},
                {"doc_type": "workout_feedback"}
            ]},
            include=["metadatas"],
            limit=n_results,
        )

        if not results["ids"]:
            return {"status": "no_data"}

        # Aggregate difficulty feedback
        difficulty_counts = {"too_easy": 0, "just_right": 0, "too_hard": 0}
        energy_counts = {"exhausted": 0, "tired": 0, "good": 0, "energized": 0}
        total_rating = 0
        rating_count = 0

        # Exercise-level aggregation
        exercise_difficulties = {}  # {exercise_name: {too_easy: 0, just_right: 0, too_hard: 0}}

        for meta in results["metadatas"]:
            # Overall difficulty
            diff = meta.get("overall_difficulty", "just_right")
            if diff in difficulty_counts:
                difficulty_counts[diff] += 1

            # Energy level
            energy = meta.get("energy_level", "good")
            if energy in energy_counts:
                energy_counts[energy] += 1

            # Rating
            if meta.get("overall_rating"):
                total_rating += meta["overall_rating"]
                rating_count += 1

            # Exercise-level feedback
            try:
                exercise_ratings = json.loads(meta.get("exercise_ratings_json", "[]"))
                for ex in exercise_ratings:
                    ex_name = ex.get("exercise_name", "").lower()
                    if ex_name:
                        if ex_name not in exercise_difficulties:
                            exercise_difficulties[ex_name] = {
                                "too_easy": 0, "just_right": 0, "too_hard": 0,
                                "total_rating": 0, "rating_count": 0, "would_do_again_yes": 0
                            }

                        ex_diff = ex.get("difficulty_felt", "just_right")
                        if ex_diff in exercise_difficulties[ex_name]:
                            exercise_difficulties[ex_name][ex_diff] += 1

                        ex_rating = ex.get("rating", 3)
                        exercise_difficulties[ex_name]["total_rating"] += ex_rating
                        exercise_difficulties[ex_name]["rating_count"] += 1

                        if ex.get("would_do_again", True):
                            exercise_difficulties[ex_name]["would_do_again_yes"] += 1
            except json.JSONDecodeError:
                pass

        # Calculate average rating
        avg_rating = total_rating / rating_count if rating_count > 0 else 0

        # Determine recommended intensity adjustment
        if difficulty_counts["too_hard"] > difficulty_counts["too_easy"]:
            intensity_recommendation = "decrease"
        elif difficulty_counts["too_easy"] > difficulty_counts["too_hard"]:
            intensity_recommendation = "increase"
        else:
            intensity_recommendation = "maintain"

        # Identify problematic exercises (low ratings or "too_hard")
        exercises_to_avoid = []
        exercises_to_include = []

        for ex_name, stats in exercise_difficulties.items():
            avg_ex_rating = stats["total_rating"] / stats["rating_count"] if stats["rating_count"] > 0 else 3
            would_do_ratio = stats["would_do_again_yes"] / stats["rating_count"] if stats["rating_count"] > 0 else 1

            if avg_ex_rating < 2.5 or would_do_ratio < 0.5 or stats["too_hard"] > stats["rating_count"] / 2:
                exercises_to_avoid.append({
                    "exercise": ex_name,
                    "avg_rating": round(avg_ex_rating, 1),
                    "reason": "low rating" if avg_ex_rating < 2.5 else "too hard" if stats["too_hard"] > stats["rating_count"] / 2 else "user doesn't want to repeat"
                })
            elif avg_ex_rating >= 4 and would_do_ratio >= 0.8:
                exercises_to_include.append({
                    "exercise": ex_name,
                    "avg_rating": round(avg_ex_rating, 1),
                })

        return {
            "status": "success",
            "feedback_count": len(results["ids"]),
            "average_workout_rating": round(avg_rating, 1),
            "difficulty_distribution": difficulty_counts,
            "energy_distribution": energy_counts,
            "intensity_recommendation": intensity_recommendation,
            "exercises_to_avoid": exercises_to_avoid[:5],  # Top 5 to avoid
            "exercises_user_enjoys": exercises_to_include[:5],  # Top 5 favorites
        }

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
    system_prompt = """You are a TOUGH military drill sergeant AI Fitness Coach. You give SHORT, HONEST, no-BS feedback after workouts.

YOUR PERSONALITY:
- Direct and blunt like a drill sergeant
- Call out laziness, short workouts, and lack of effort
- Respect REAL effort and achievement
- No fake praise or generic encouragement

CRITICAL RULES:
1. Keep feedback to 2-3 short sentences MAX
2. If workout was under 5 minutes, total sets is 0, or total reps is 0 → CALL IT OUT harshly. They didn't actually work out.
3. If workout was 5-15 minutes with minimal work → be skeptical and push them to do more
4. If they actually put in real effort (20+ min, real sets/reps) → acknowledge it with tough respect
5. If they improved weights → give brief, earned praise
6. Be specific about what was lacking or what was good

Examples of GOOD feedback for LAZY workouts:
- "20 seconds and 0 reps? That's not a workout, that's pressing buttons. Get back in there and actually move some weight!"
- "Under 2 minutes with zero sets completed? Come on, recruit! My grandmother works harder getting out of her chair."
- "You logged a workout but didn't do any actual work. Don't waste my time or yours. Come back when you're ready to sweat."

Examples of GOOD feedback for REAL workouts:
- "45 minutes, 28 sets, solid volume. That's what I'm talking about. Now recover and come back stronger."
- "You added 2.5kg to your bench? Earned. Keep stacking those plates."
- "Decent effort today - 35 minutes of work. Push the intensity next time and you'll see real gains."

DO NOT:
- Praise lazy/fake workouts
- Be generic or sappy
- Write long paragraphs
- Use emojis"""

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


# Singleton instance for services that need it
_workout_feedback_rag_instance: Optional[WorkoutFeedbackRAGService] = None


def get_workout_feedback_rag_service() -> WorkoutFeedbackRAGService:
    """Get or create singleton WorkoutFeedbackRAGService instance."""
    global _workout_feedback_rag_instance
    if _workout_feedback_rag_instance is None:
        from services.gemini_service import get_gemini_service
        gemini = get_gemini_service()
        _workout_feedback_rag_instance = WorkoutFeedbackRAGService(gemini)
    return _workout_feedback_rag_instance
