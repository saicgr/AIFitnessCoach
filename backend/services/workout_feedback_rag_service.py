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
import asyncio
import uuid
import json

from pydantic import BaseModel, Field

from core.config import get_settings
from core.chroma_cloud import get_chroma_cloud_client
from core.logger import get_logger
from services.gemini_service import GeminiService
from services.langgraph_agents.personality import build_personality_prompt
from models.chat import AISettings

settings = get_settings()
logger = get_logger(__name__)


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

        try:
            _count = self.collection.count()
        except Exception as e:
            logger.warning(f"Failed to get collection count: {e}", exc_info=True)
            _count = "unknown"
        logger.info(f"Workout Feedback RAG initialized: {_count} sessions")

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
        # User preferences for RAG context
        training_intensity_percent: int = 75,
        progression_pace: str = "medium",
        has_1rm_data: bool = False,
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
            training_intensity_percent: User's training intensity setting (50-100)
            progression_pace: User's progression pace (slow, medium, fast)
            has_1rm_data: Whether user has 1RM data for personalization

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

        # Create searchable text for embedding (include preferences for context)
        session_text = (
            f"Workout: {workout_name}\n"
            f"Type: {workout_type}\n"
            f"Exercises: {exercise_text}\n"
            f"Duration: {total_time_seconds // 60} minutes\n"
            f"Rest Time: {total_rest_seconds // 60} minutes (avg {avg_rest_seconds:.0f}s between sets)\n"
            f"Calories: {calories_burned} kcal\n"
            f"Sets: {total_sets}, Reps: {total_reps}, Volume: {total_volume_kg:.1f}kg\n"
            f"Training Intensity: {training_intensity_percent}%\n"
            f"Progression Pace: {progression_pace}\n"
            f"Date: {completed_at}"
        )

        # Get embedding
        embedding = await self.gemini_service.get_embedding_async(session_text)

        # Upsert to collection
        try:
            await self.collection.adelete(ids=[doc_id])
        except Exception as e:
            logger.debug(f"ChromaDB delete before upsert: {e}")

        await self.collection.aadd(
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
                # User preferences for RAG filtering/context
                "training_intensity_percent": training_intensity_percent,
                "progression_pace": progression_pace,
                "has_1rm_data": has_1rm_data,
            }],
        )

        logger.info(f"Indexed workout session: {workout_name} for user {user_id} (intensity={training_intensity_percent}%, pace={progression_pace})")
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
        # Build where filter
        where_filter = {"user_id": user_id}
        if workout_type:
            where_filter["workout_type"] = workout_type

        # Get all matching sessions
        results = await self.collection.aget(
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
                except json.JSONDecodeError as e:
                    logger.debug(f"Failed to parse exercises JSON: {e}")

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
        # Search for sessions containing this exercise
        query = f"Exercise: {exercise_name}"
        query_embedding = await self.gemini_service.get_embedding_async(query)

        results = await self.collection.aquery(
            query_embeddings=[query_embedding],
            n_results=n_results,
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
                    except json.JSONDecodeError as e:
                        logger.debug(f"Failed to parse exercises JSON: {e}")

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

        # Get completed exercises and planned exercises
        exercises = current_session.get('exercises', [])
        planned_exercises = current_session.get('planned_exercises', [])

        # Detect skipped exercises
        completed_names = {ex.get('name', '').lower() for ex in exercises if ex.get('name')}
        planned_names = {ex.get('name', '').lower() for ex in planned_exercises if ex.get('name')}
        skipped_names = planned_names - completed_names

        # Calculate completion rate
        total_planned = len(planned_exercises) if planned_exercises else len(exercises)
        total_completed = len(exercises)
        completion_rate = (total_completed / total_planned * 100) if total_planned > 0 else 100.0

        # Add skip analysis to context
        if planned_exercises and skipped_names:
            context_parts.append(f"""
WORKOUT COMPLETION ANALYSIS:
- Planned: {len(planned_exercises)} exercises
- Completed: {len(exercises)} exercises
- Skipped: {len(skipped_names)} exercises ({', '.join(skipped_names)})
- Completion Rate: {completion_rate:.0f}%
""")
        elif planned_exercises:
            context_parts.append(f"""
WORKOUT COMPLETION ANALYSIS:
- Planned: {len(planned_exercises)} exercises
- Completed: {len(exercises)} exercises
- Completion Rate: {completion_rate:.0f}%
""")

        # Current exercises with enhanced details (timing, weight per set)
        if exercises:
            context_parts.append("\nPER-EXERCISE BREAKDOWN:")
            rushed_exercises = []
            for ex in exercises:
                ex_name = ex.get('name', 'Unknown')
                ex_sets = ex.get('sets', 0)
                ex_reps = ex.get('reps', 0)
                ex_weight = ex.get('weight_kg', 0)
                ex_time = ex.get('time_seconds', 0)
                ex_time_min = ex_time / 60 if ex_time > 0 else 0

                # Find target weight if available
                target_weight = None
                for planned in planned_exercises:
                    if planned.get('name', '').lower() == ex_name.lower():
                        target_weight = planned.get('target_weight_kg', 0)
                        break

                # Build exercise line
                ex_line = f"  - {ex_name}: {ex_sets} sets x {ex_reps} reps @ {ex_weight}kg"

                # Add timing info
                if ex_time > 0:
                    ex_line += f" ({ex_time_min:.1f} min spent)"
                    if ex_time < 180:  # Less than 3 minutes = rushed
                        rushed_exercises.append(ex_name)

                # Add weight comparison to target
                if target_weight and target_weight > 0:
                    weight_diff = ex_weight - target_weight
                    if weight_diff > 0:
                        ex_line += f" [+{weight_diff:.1f}kg above target - nice progression!]"
                    elif weight_diff < 0:
                        ex_line += f" [{weight_diff:.1f}kg below target]"

                context_parts.append(ex_line)

                # Add set details if available
                set_details = ex.get('set_details', [])
                if set_details and len(set_details) > 1:
                    weights = [s.get('weight_kg', 0) for s in set_details]
                    if max(weights) != min(weights):
                        set_strs = [f"{s.get('reps')}x{s.get('weight_kg')}kg" for s in set_details]
                        context_parts.append(f"      Sets: {', '.join(set_strs)}")

            # Note rushed exercises
            if rushed_exercises:
                context_parts.append(f"\nRUSHED EXERCISES (< 3 min): {', '.join(rushed_exercises)}")

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
            await self.collection.adelete(ids=[doc_id])
        except Exception as e:
            logger.debug(f"ChromaDB delete before upsert: {e}")

        # Store in ChromaDB
        await self.collection.aadd(
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

        logger.info(f"Indexed workout feedback: rating={overall_rating}, difficulty={overall_difficulty}")
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
        # Search for feedback containing this exercise
        query = f"Exercise feedback: {exercise_name}"
        query_embedding = await self.gemini_service.get_embedding_async(query)

        results = await self.collection.aquery(
            query_embeddings=[query_embedding],
            n_results=n_results * 2,  # Get more to filter
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
        # Get recent feedback
        results = await self.collection.aget(
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
            except json.JSONDecodeError as e:
                logger.debug(f"Failed to parse exercise ratings: {e}")

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
        try:
            c = self.collection.count()
            total = c if c >= 0 else -1
        except Exception as e:
            logger.warning(f"Failed to get feedback count: {e}", exc_info=True)
            total = -1
        return {
            "total_sessions": total,
            "storage": "chroma_cloud",
            "collection": self.COLLECTION_NAME,
        }


async def generate_workout_feedback(
    gemini_service: GeminiService,
    rag_service: WorkoutFeedbackRAGService,
    user_id: str,
    current_session: Dict[str, Any],
    coach_name: Optional[str] = None,
    coaching_style: Optional[str] = None,
    communication_tone: Optional[str] = None,
    encouragement_level: Optional[float] = None,
    # Trophy/achievement context for personalized feedback
    earned_prs: Optional[List[Dict[str, Any]]] = None,
    earned_achievements: Optional[List[Dict[str, Any]]] = None,
    total_workouts_completed: Optional[int] = None,
    next_milestone: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Generate AI Coach feedback for a completed workout.

    Args:
        gemini_service: Gemini service for LLM
        rag_service: Workout feedback RAG service
        user_id: User ID
        current_session: Current workout session data
        coach_name: Name of the coach (e.g., "Danny", "Coach Mike")
        coaching_style: Style of coaching (e.g., "motivational", "drill_sergeant", "buddy")
        communication_tone: Tone of communication (e.g., "encouraging", "direct", "friendly")
        encouragement_level: Level of encouragement (0.0-1.0)
        earned_prs: List of PRs earned this session
        earned_achievements: List of achievements unlocked this session
        total_workouts_completed: Total number of workouts completed
        next_milestone: Next workout milestone to reach

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

    # Build AI settings from provided parameters
    ai_settings = AISettings(
        coach_name=coach_name or "Coach",
        coaching_style=coaching_style or "motivational",
        communication_tone=communication_tone or "encouraging",
        encouragement_level=encouragement_level if encouragement_level is not None else 0.5,
        response_length="concise",  # Always concise for workout feedback
        use_emojis=True,  # Let personality module decide based on style
        include_tips=False,  # Keep feedback focused
    )

    # Get personality prompt from centralized personality module
    personality_prompt = build_personality_prompt(
        ai_settings=ai_settings,
        agent_name="Coach",
        agent_specialty="workout feedback"
    )

    # Build workout-specific system prompt
    system_prompt = f"""{personality_prompt}

WORKOUT FEEDBACK SPECIFIC INSTRUCTIONS:
You are providing SHORT, HONEST feedback after a completed workout.

CRITICAL RULES:
1. Keep feedback to 2-3 short sentences MAX
2. If workout was under 5 minutes with minimal sets/reps → they didn't really work out. Be honest about it.
3. If workout was 5-15 minutes → acknowledge the effort but push for more next time
4. If they put in real effort (20+ min, solid sets/reps) → give appropriate recognition
5. If they improved weights → acknowledge it
6. Be specific about what was done or what was lacking
7. REACT TO SKIPPED EXERCISES according to your coaching style:
   - If completion rate < 50% → this needs to be called out, express concern/disappointment
   - If completion rate 50-80% → acknowledge but push for full workout next time
   - If completion rate > 80% → can praise if workout was solid
8. Call out RUSHED exercises (< 3 min): "You blew through X pretty fast - slow down!"
9. Note weight progression: If they increased weight → acknowledge the growth
10. Note if weight was BELOW target: "Your squat weight was down - feeling tired?"

COMPLETION RATE GUIDELINES:
- < 30%: "You skipped most of the workout. What happened?"
- 30-50%: "Only half done? Push through the whole thing next time."
- 50-70%: "Decent, but you left some exercises on the table."
- 70-90%: "Almost complete! Just a few more exercises to crush it fully."
- 90-100%: Can give praise if effort was real.

DO NOT:
- Give fake praise for lazy or incomplete workouts
- Say "Great job!" when they skipped half the exercises
- Be generic with no specifics
- Write long paragraphs
- Ignore skipped exercises in the data

TROPHY/ACHIEVEMENT RULES (PRIORITY OVER OTHER FEEDBACK):
- If PRs were earned: Congratulate SPECIFICALLY on the PR(s) by exercise name! This is a BIG DEAL!
- If achievements unlocked: Celebrate them! Make the user feel accomplished.
- If close to a milestone: Mention it to motivate them ("Just X more workouts to hit Y!")
- Trophies > generic feedback. Prioritize celebrating achievements over workout critique.
- If no trophies, focus on the workout performance itself."""

    # Build trophy context if any trophies were earned
    trophy_context = ""
    if earned_prs:
        pr_names = [pr.get('exercise_name', 'exercise') for pr in earned_prs[:3]]
        trophy_context += f"\n🏆 PRs EARNED THIS SESSION: {', '.join(pr_names)}"
    if earned_achievements:
        ach_names = [a.get('name', 'achievement') for a in earned_achievements[:3]]
        trophy_context += f"\n🎖️ ACHIEVEMENTS UNLOCKED: {', '.join(ach_names)}"
    if next_milestone:
        remaining = next_milestone.get('remaining', 0)
        target = next_milestone.get('value', 0)
        if remaining <= 5:  # Only mention if close
            trophy_context += f"\n📊 NEXT MILESTONE: {target} workouts (only {remaining} more to go!)"
    if total_workouts_completed:
        # Check if this is a milestone workout
        milestones = [5, 10, 25, 50, 100, 150, 200, 250, 500, 1000]
        if total_workouts_completed in milestones:
            trophy_context += f"\n🎯 MILESTONE REACHED: {total_workouts_completed} total workouts!"

    user_prompt = f"""Based on this workout data, provide SHORT personalized feedback (2-3 sentences max):

{context}
{trophy_context}

Remember: Be specific, encouraging, and brief! If they earned trophies, CELEBRATE THEM!"""

    # Call Gemini using the chat method
    feedback = await gemini_service.chat(
        user_message=user_prompt,
        system_prompt=system_prompt,
    )

    if not feedback:
        feedback = "Great workout! Keep up the momentum!"
    logger.info(f"Generated feedback for user {user_id}: {feedback[:50]}...")

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


# =============================================================================
# B8 — PERSISTED POST-WORKOUT AI RECAP (deeper than a one-line feedback string)
#
# Distinct from `generate_workout_feedback` (an ephemeral coach one-liner held in
# RAG only). The recap is STRUCTURED + PERSISTED (migration 2232): total volume
# vs the last COMPARABLE session, PRs hit, "what stood out", and ONE concrete
# coaching cue for next time. Multi-modal-ready: it can reference logged notes.
# =============================================================================


class WorkoutRecapVolumeComparison(BaseModel):
    """How this session's volume stacks against the last comparable session."""
    current_volume_kg: float = Field(
        ..., description="Total volume (kg) lifted this session."
    )
    previous_volume_kg: Optional[float] = Field(
        default=None,
        description="Total volume (kg) of the last comparable session, or null if none.",
    )
    delta_pct: Optional[float] = Field(
        default=None,
        description="Percent change vs the comparable session (positive = up). Null if no comparable session.",
    )
    comparable_workout_name: Optional[str] = Field(
        default=None,
        description="Name of the comparable session being compared against, if any.",
    )
    summary: str = Field(
        ...,
        description="One human sentence on the volume trend, e.g. 'Up 12% over your last Push day.'",
    )


class WorkoutRecapPR(BaseModel):
    """A personal record hit this session."""
    exercise_name: str = Field(..., description="Exercise the PR was set on.")
    detail: str = Field(
        ..., description="Short description, e.g. 'New 5-rep max at 80kg.'"
    )


class WorkoutAiRecapPayload(BaseModel):
    """Structured, persisted post-workout recap (B8).

    Used both as the Gemini `response_schema` (guaranteed-valid JSON) and as the
    shape stored in `workout_ai_recaps.payload` and returned to the client.
    """
    headline: str = Field(
        ..., description="Punchy one-line summary of the session (no emojis)."
    )
    what_stood_out: List[str] = Field(
        default_factory=list,
        description="1-3 specific highlights: a weak point that progressed, "
        "consistency, a strong lift, completion. Each is one short sentence.",
    )
    volume_comparison: WorkoutRecapVolumeComparison = Field(
        ..., description="Volume vs the last comparable session."
    )
    prs: List[WorkoutRecapPR] = Field(
        default_factory=list, description="PRs hit this session (may be empty)."
    )
    coaching_cue: str = Field(
        ...,
        description="EXACTLY ONE concrete, actionable cue for next time "
        "(e.g. 'Add 2.5kg to your bench next session — your last set had 2 reps in reserve.').",
    )
    notes_reference: Optional[str] = Field(
        default=None,
        description="If the user logged notes this session, one sentence acknowledging "
        "or acting on them; otherwise null.",
    )


# =============================================================================
# Enrichment block builders (B / A2 / A3)
#
# These distill the rich DB context (ExerciseContext, injuries, rest, effort,
# active-workout signals) into compact prompt lines. Every block is OMITTED when
# empty so the token budget only pays for signal that exists. None of these make
# DB calls — they consume what the endpoint already assembled.
# =============================================================================


def _fmt_kg(value: Optional[float], use_kg: bool) -> str:
    """Compact kg/lb formatting for prompt lines (storage is kg)."""
    if value is None:
        return "bodyweight"
    if value <= 0:
        return "bodyweight"
    if use_kg:
        return f"{value:.0f}kg" if value >= 10 else f"{value:.1f}kg"
    lb = value * _LB_PER_KG
    return f"{lb:.0f}lb" if lb >= 10 else f"{lb:.1f}lb"


def build_history_pr_block(
    exercise_contexts: Optional[Dict[str, Any]],
    use_kg: bool,
    max_exercises: int = 5,
) -> str:
    """PRIOR HISTORY & PRS block: per exercise, last 3 top sets + PR/1RM + flags.

    `exercise_contexts` is {name -> ExerciseContext}. Returns '' when there's no
    history for any exercise (block omitted).
    """
    if not exercise_contexts:
        return ""
    lines: List[str] = []
    for name, ctx in list(exercise_contexts.items())[:max_exercises]:
        if not getattr(ctx, "has_history", False) and not getattr(ctx, "current_pr", None):
            continue
        # Last up-to-3 sessions, top set each.
        sess_bits: List[str] = []
        for sess in (getattr(ctx, "recent_sessions", []) or [])[:3]:
            sets = sess.get("sets") or []
            if not sets:
                continue
            top = max(sets, key=lambda s: (s.get("weight_kg") or 0, s.get("reps") or 0))
            w = _fmt_kg(top.get("weight_kg"), use_kg)
            sess_bits.append(f"{sess.get('date','?')}: {int(top.get('reps') or 0)}x{w}")
        parts = []
        if sess_bits:
            parts.append("recent top sets " + "; ".join(sess_bits))
        atb = getattr(ctx, "all_time_best_1rm_kg", None)
        eff = getattr(ctx, "effective_1rm_kg", None)
        if atb:
            parts.append(f"all-time best 1RM ~{_fmt_kg(atb, use_kg)}")
        if eff and (not atb or abs(eff - atb) > 0.5):
            parts.append(f"effective 1RM ~{_fmt_kg(eff, use_kg)}")
        flag = ""
        if getattr(ctx, "is_pr", False):
            flag = " — TODAY IS A PR"
        elif getattr(ctx, "is_near_pr", False):
            flag = " — NEAR PR (within ~2.5% of best)"
        if parts or flag:
            lines.append(f"- {name}: {'; '.join(parts) if parts else 'first logged session'}{flag}")
    if not lines:
        return ""
    return "PRIOR HISTORY & PRS (use only these numbers):\n" + "\n".join(lines)


def build_effort_block(exercise_contexts: Optional[Dict[str, Any]], max_exercises: int = 5) -> str:
    """EFFORT block: per-exercise average RIR/RPE logged THIS session."""
    if not exercise_contexts:
        return ""
    lines: List[str] = []
    for name, ctx in list(exercise_contexts.items())[:max_exercises]:
        rir = getattr(ctx, "avg_rir", None)
        rpe = getattr(ctx, "avg_rpe", None)
        bits = []
        if rir is not None:
            bits.append(f"avg RIR {rir:g}")
        if rpe is not None:
            bits.append(f"avg RPE {rpe:g}")
        if bits:
            lines.append(f"- {name}: {', '.join(bits)}")
    if not lines:
        return ""
    return "EFFORT (reps in reserve / perceived exertion this session):\n" + "\n".join(lines)


def build_rest_block(rest_analysis: Optional[Dict[str, Any]]) -> str:
    """REST block: prescribed vs actual rest per exercise.

    `rest_analysis` is {exercise_name -> {avg_actual_s, avg_prescribed_s}}.
    """
    if not rest_analysis:
        return ""
    lines: List[str] = []
    for name, r in list(rest_analysis.items())[:5]:
        actual = r.get("avg_actual_s")
        presc = r.get("avg_prescribed_s")
        if actual is None:
            continue
        if presc:
            lines.append(
                f"- {name}: rested ~{int(actual)}s vs prescribed ~{int(presc)}s"
            )
        else:
            lines.append(f"- {name}: rested ~{int(actual)}s")
    if not lines:
        return ""
    return "REST (actual vs prescribed):\n" + "\n".join(lines)


def build_injury_block(injury_context: Optional[Any]) -> str:
    """INJURY/PAIN block. Omitted entirely when there's nothing active."""
    if injury_context is None:
        return ""
    injuries = getattr(injury_context, "injuries", None) or []
    pain_flagged = getattr(injury_context, "pain_flagged_exercises", None) or []
    if not injuries and not pain_flagged:
        return ""
    lines: List[str] = []
    for inj in injuries[:4]:
        bits = [inj.get("body_part") or "an area"]
        if inj.get("injury_type"):
            bits.append(str(inj.get("injury_type")))
        if inj.get("severity"):
            bits.append(f"{inj.get('severity')} severity")
        if inj.get("pain_level") is not None:
            bits.append(f"pain {inj.get('pain_level')}/10")
        if inj.get("recovery_phase"):
            bits.append(f"{inj.get('recovery_phase')} phase")
        affects = inj.get("affects_exercises") or []
        if affects:
            bits.append("affects: " + ", ".join(str(a) for a in affects[:4]))
        lines.append("- " + " — ".join(b for b in bits if b))
    if pain_flagged:
        lines.append("- Pain-flagged movements: " + ", ".join(pain_flagged[:6]))
    return (
        "INJURY / PAIN (RESPECT THIS — do not push load on affected movements; "
        "favor pain-free range and recovery):\n" + "\n".join(lines)
    )


def build_form_block(exercise_contexts: Optional[Dict[str, Any]]) -> str:
    """FORM block: cite the SINGLE lowest-scoring exercise's form note, if any."""
    if not exercise_contexts:
        return ""
    scored = []
    for name, ctx in exercise_contexts.items():
        form = getattr(ctx, "form", None)
        if form and form.get("form_score") is not None:
            scored.append((name, form))
    if not scored:
        return ""
    name, form = min(scored, key=lambda x: x[1].get("form_score") or 99)
    issues = form.get("top_issues") or []
    issue_txt = ""
    if issues:
        i0 = issues[0]
        issue_txt = f" Top issue: {i0.get('description')}"
        if i0.get("correction"):
            issue_txt += f" (fix: {i0.get('correction')})"
    return f"FORM CHECK ({name}): form_score {form.get('form_score')}/10.{issue_txt}"


def summarize_session_signals(
    metadata: Optional[Dict[str, Any]],
    sets_json: Optional[List[Dict[str, Any]]],
) -> List[str]:
    """Distill high-value active-workout signals into compact prompt lines (A2).

    NO DB cost — everything here is already in the completion payload the client
    sent. Only NON-DEFAULT / notable signals are emitted (so a normal session adds
    a handful of lines, not 95). Covers: progression-vs-last (per-set
    previous_weight_kg/previous_reps), target-vs-actual, set types
    (failure/amrap/dropset), exit reason, warmup/stretch status, ai_interactions.*,
    heart_rate, drink behavior, rest behavior, and per-set notes.
    """
    metadata = metadata or {}
    sets_json = sets_json or []
    lines: List[str] = []

    # --- Exit reason (sets TONE) ---
    exit_reason = (metadata.get("exitReason") or metadata.get("exit_reason") or "").lower()
    if exit_reason and exit_reason not in ("completed", "complete", "finished", ""):
        lines.append(f"Session ended early — reason: {exit_reason} (adjust tone; do not over-cheerlead).")

    # --- Warmup / stretch adherence ---
    warmup = metadata.get("warmup") or {}
    if isinstance(warmup, dict) and (warmup.get("status") == "skipped" or warmup.get("skipped")):
        lines.append("Warmup was skipped.")
    stretch = metadata.get("stretch") or metadata.get("cooldown") or {}
    if isinstance(stretch, dict) and (stretch.get("status") == "skipped" or stretch.get("skipped")):
        lines.append("Cooldown/stretch was skipped.")

    # --- AI interaction counters ---
    ai = metadata.get("ai_interactions") or metadata.get("aiInteractions") or {}
    if isinstance(ai, dict):
        if ai.get("fatigue_alerts_triggered"):
            lines.append(f"Pushed through {ai.get('fatigue_alerts_triggered')} fatigue alert(s).")
        accepted = ai.get("weight_suggestions_accepted")
        if accepted:
            lines.append(f"Accepted {accepted} coach weight suggestion(s).")
        if ai.get("exercise_swaps_requested"):
            lines.append(f"Requested {ai.get('exercise_swaps_requested')} exercise swap(s).")

    # --- Heart rate (intensity proxy) ---
    hr = metadata.get("heart_rate") or metadata.get("heartRate") or {}
    if isinstance(hr, dict) and hr.get("avg_bpm"):
        hr_bits = f"avg {int(hr['avg_bpm'])} bpm"
        if hr.get("max_bpm"):
            hr_bits += f", peak {int(hr['max_bpm'])} bpm"
        lines.append(f"Heart rate this session: {hr_bits}.")

    # --- Hydration behavior ---
    drink_events = metadata.get("drink_events") or metadata.get("drinkEvents") or []
    drink_ml = metadata.get("drink_intake_ml") or metadata.get("drinkIntakeMl")
    if drink_events:
        lines.append(f"Logged {len(drink_events)} hydration break(s) mid-session.")
    elif drink_ml:
        lines.append(f"Drank ~{int(drink_ml)}ml during the session.")

    # --- Set-level signals from sets_json: progression vs last, targets, set types ---
    set_type_flags: Dict[str, int] = {}
    progressed = 0
    regressed = 0
    missed_target = 0
    for s in sets_json:
        stype = (s.get("set_type") or s.get("setType") or "").lower()
        if stype in ("failure", "amrap", "dropset", "drop_set", "drop-set"):
            set_type_flags[stype] = set_type_flags.get(stype, 0) + 1

        # Progression vs last time (per-set previous_*).
        prev_w = s.get("previous_weight_kg")
        if prev_w is None:
            prev_w = s.get("previousWeightKg")
        cur_w = s.get("weight_kg")
        if cur_w is None:
            cur_w = s.get("weightKg")
        if prev_w is not None and cur_w is not None:
            try:
                if float(cur_w) > float(prev_w) + 0.1:
                    progressed += 1
                elif float(cur_w) < float(prev_w) - 0.1:
                    regressed += 1
            except (TypeError, ValueError):
                pass

        # Target adherence.
        tgt_w = s.get("target_weight_kg")
        if tgt_w is None:
            tgt_w = s.get("targetWeightKg")
        if tgt_w is not None and cur_w is not None:
            try:
                if float(cur_w) < float(tgt_w) - 0.1:
                    missed_target += 1
            except (TypeError, ValueError):
                pass

    if progressed and progressed >= regressed:
        lines.append(f"Added load on {progressed} set(s) vs last time.")
    elif regressed > progressed and regressed:
        lines.append(f"Backed off load on {regressed} set(s) vs last time.")
    for stype, count in set_type_flags.items():
        label = stype.replace("_", " ")
        lines.append(f"Logged {count} {label} set(s) — notable effort.")
    if missed_target:
        lines.append(f"Came in under the prescribed load on {missed_target} set(s).")

    return lines


def _signals_prompt_block(signals: Optional[List[str]]) -> str:
    if not signals:
        return ""
    return "SESSION SIGNALS:\n" + "\n".join(f"- {s}" for s in signals[:10])


def _find_last_comparable_session(
    current_session: Dict[str, Any],
    past_sessions: List[Dict[str, Any]],
) -> Optional[Dict[str, Any]]:
    """Pick the most recent PAST session comparable to the current one.

    Comparability, best-effort and deterministic (NOT an LLM call):
      1. Same workout_id (the same plan repeated) — strongest signal.
      2. Else same workout_type (e.g. another 'strength'/'push' day).
      3. Else the most recent session of any kind.

    Excludes the current session itself (by workout_log_id) so re-completing a
    workout never compares against its own row.
    """
    current_log_id = str(current_session.get("workout_log_id") or "")
    current_workout_id = str(current_session.get("workout_id") or "")
    current_type = (current_session.get("workout_type") or "").lower()

    def _meta(s: Dict[str, Any]) -> Dict[str, Any]:
        return s.get("metadata", {}) or {}

    # Drop the current session + sort most-recent-first.
    candidates = [
        s for s in past_sessions
        if str(_meta(s).get("workout_log_id") or "") != current_log_id
    ]
    candidates.sort(
        key=lambda s: _meta(s).get("completed_at") or "", reverse=True
    )

    # Tier 1: same workout_id.
    if current_workout_id:
        for s in candidates:
            if str(_meta(s).get("workout_id") or "") == current_workout_id:
                return s
    # Tier 2: same workout_type.
    if current_type:
        for s in candidates:
            if (_meta(s).get("workout_type") or "").lower() == current_type:
                return s
    # Tier 3: most recent anything.
    return candidates[0] if candidates else None


async def generate_workout_recap(
    gemini_service: GeminiService,
    rag_service: WorkoutFeedbackRAGService,
    user_id: str,
    current_session: Dict[str, Any],
    earned_prs: Optional[List[Dict[str, Any]]] = None,
    logged_notes: Optional[List[str]] = None,
    total_workouts_completed: Optional[int] = None,
    exercise_contexts: Optional[Dict[str, Any]] = None,
    injury_context: Optional[Any] = None,
    rest_analysis: Optional[Dict[str, Any]] = None,
    session_signals: Optional[List[str]] = None,
    use_kg: bool = False,
) -> Dict[str, Any]:
    """Generate a STRUCTURED post-workout recap (B8).

    Args:
        gemini_service: Gemini service for the LLM call.
        rag_service: Workout feedback RAG service (history + weight progressions).
        user_id: User ID.
        current_session: Completed session dict (same shape `generate_workout_feedback`
            consumes — workout_name, workout_type, exercises, totals, etc.).
        earned_prs: PRs hit this session (exercise_name + optional detail).
        logged_notes: Free-text set/workout notes the user logged this session
            (multi-modal-ready signal). Empty/None => recap won't reference notes.
        total_workouts_completed: Lifetime workout count, for consistency framing.
        exercise_contexts: {name -> ExerciseContext} from exercise_context_service.
            When supplied, replaces the thin ChromaDB weight-history loop and feeds
            the richer PRIOR HISTORY & PRS / EFFORT / FORM blocks. Optional.
        injury_context: InjuryContext (active injuries + pain-flagged moves). When
            non-empty, adds the INJURY/PAIN block. Optional.
        rest_analysis: {name -> {avg_actual_s, avg_prescribed_s}} for the REST block.
        session_signals: distilled active-workout signals (see summarize_session_signals).
        use_kg: when False, weights in prompt blocks are phrased in lb.

    Returns:
        Dict matching WorkoutAiRecapPayload, PLUS denormalized derived fields the
        endpoint persists: `_volume_delta_pct`, `_pr_count`, `_referenced_notes`,
        `_total_volume_kg`. Never raises for an empty model response — falls back
        to a deterministic recap so the card is never blank.
    """
    from google.genai import types
    from services.gemini.constants import gemini_generate_with_retry

    # --- Gather comparison context (deterministic, no LLM) ----------------
    # Fetch workout history + per-exercise weight histories CONCURRENTLY. These
    # are independent ChromaDB/embedding round-trips; running them in parallel
    # (instead of a sequential await loop) cuts ~5-10s of latency to ~1-2s.
    ex_names = [
        ex.get("name", "")
        for ex in (current_session.get("exercises", []) or [])[:5]
        if ex.get("name")
    ]
    # When the endpoint already assembled rich per-exercise context (the B path),
    # we ONLY need the session-level workout history for the volume comparison —
    # the thin ChromaDB per-exercise weight loop is superseded by exercise_contexts.
    if exercise_contexts:
        history_result = await rag_service.get_user_workout_history(user_id, n_results=10)
        weight_progressions: Dict[str, List[Dict[str, Any]]] = {}
        if isinstance(history_result, Exception):
            logger.warning(f"[recap] workout history fetch failed: {history_result}")
            past_sessions = []
        else:
            past_sessions = history_result
    else:
        gathered = await asyncio.gather(
            rag_service.get_user_workout_history(user_id, n_results=10),
            *[
                rag_service.get_exercise_weight_history(user_id, n, n_results=5)
                for n in ex_names
            ],
            return_exceptions=True,
        )
        history_result = gathered[0]
        past_sessions = history_result if not isinstance(history_result, Exception) else []
        if isinstance(history_result, Exception):
            logger.warning(f"[recap] workout history fetch failed: {history_result}")

        # Per-exercise weight progression (reuse existing RAG helper).
        weight_progressions = {}
        for ex_name, history in zip(ex_names, gathered[1:]):
            if history and not isinstance(history, Exception):
                weight_progressions[ex_name] = history

    comparable = _find_last_comparable_session(current_session, past_sessions)

    current_volume = float(current_session.get("total_volume_kg", 0) or 0)
    previous_volume: Optional[float] = None
    comparable_name: Optional[str] = None
    delta_pct: Optional[float] = None
    if comparable:
        cmeta = comparable.get("metadata", {}) or {}
        comparable_name = cmeta.get("workout_name")
        try:
            previous_volume = float(cmeta.get("total_volume_kg", 0) or 0)
        except (TypeError, ValueError):
            previous_volume = None
        if previous_volume and previous_volume > 0:
            delta_pct = round((current_volume - previous_volume) / previous_volume * 100, 1)

    context = rag_service.format_feedback_context(
        current_session, past_sessions, weight_progressions
    )

    # --- 0kg GUARDRAIL ---------------------------------------------------------
    # A marked-done / no-load session has zero logged volume. NEVER say "0kg",
    # "baseline of 0", or emit a volume delta — that's the AI-slop the redesign
    # exists to kill. Force a completion-framed comparison and guard delta math.
    marked_done_no_load = current_volume <= 0
    if marked_done_no_load:
        previous_volume = None
        delta_pct = None
        vol_line = (
            "This session was marked complete with no logged load (no per-set "
            "weights recorded). Do NOT mention volume, kilograms, '0kg', or any "
            "baseline number — speak only to completion and consistency."
        )
    elif previous_volume and delta_pct is not None:
        direction = "up" if delta_pct >= 0 else "down"
        vol_line = (
            f"Total volume this session: {current_volume:.0f}kg. "
            f"Last comparable session ('{comparable_name}'): {previous_volume:.0f}kg "
            f"({direction} {abs(delta_pct):.1f}%)."
        )
    else:
        vol_line = (
            f"Total volume this session: {current_volume:.0f}kg. "
            f"No comparable prior session to compare against (first of its kind)."
        )

    # --- Enrichment blocks (B / A2 / A3) — omitted when empty ------------------
    history_block = build_history_pr_block(exercise_contexts, use_kg)
    effort_block = build_effort_block(exercise_contexts)
    rest_block = build_rest_block(rest_analysis)
    injury_block = build_injury_block(injury_context)
    form_block = build_form_block(exercise_contexts)
    signals_block = _signals_prompt_block(session_signals)

    pr_lines = ""
    if earned_prs:
        pr_lines = "PRs HIT THIS SESSION:\n" + "\n".join(
            f"- {pr.get('exercise_name', 'exercise')}: {pr.get('detail') or pr.get('description') or 'new personal record'}"
            for pr in earned_prs[:5]
        )

    notes_block = ""
    has_notes = bool(logged_notes)
    if has_notes:
        notes_block = "USER LOGGED NOTES THIS SESSION:\n" + "\n".join(
            f"- {n}" for n in logged_notes[:8] if n
        )

    consistency_line = ""
    if total_workouts_completed:
        consistency_line = f"Lifetime workouts completed: {total_workouts_completed}."

    zero_load_rule = (
        " This session has NO logged load — NEVER write '0kg', 'baseline', or a "
        "volume number; frame it purely as a completed session and what to do next."
        if marked_done_no_load else ""
    )
    system_prompt = (
        "You are an elite strength coach writing a SHORT, data-grounded recap of a "
        "client's just-finished workout. Be specific and honest; never generic. "
        "Use ONLY the numbers provided — do not invent volume, weights, PRs, RIR, "
        "or rest figures. When an INJURY/PAIN block is present, respect it: never "
        "tell the client to push load on an affected movement. "
        "No emojis. No markdown. The coaching cue must be ONE concrete, actionable "
        "instruction for the next session, tied to the actual data." + zero_load_rule
    )

    extra_blocks = "\n\n".join(
        b for b in (history_block, effort_block, rest_block, injury_block, form_block, signals_block) if b
    )

    user_prompt = f"""Write a structured recap of this workout.

{context}

VOLUME COMPARISON (use these exact numbers):
{vol_line}

{extra_blocks}

{pr_lines}

{notes_block}

{consistency_line}

Requirements:
- headline: punchy one-liner about THIS session.
- what_stood_out: 1-3 specific highlights (a PR / near-PR, weak point progressed, consistency streak, strongest lift, completion). Each one short sentence.
- volume_comparison: fill from the VOLUME COMPARISON numbers above (do not change them).
- prs: only the PRs listed above (empty if none).
- coaching_cue: EXACTLY ONE concrete cue for next time, grounded in the data{' (respect any injury/pain noted above)' if injury_block else ''}.
- notes_reference: {"one sentence acknowledging/acting on the user's notes above" if has_notes else "null (no notes were logged)"}.
"""

    payload_dict: Dict[str, Any]
    try:
        response = await gemini_generate_with_retry(
            model=gemini_service.model,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                response_mime_type="application/json",
                response_schema=WorkoutAiRecapPayload,
                temperature=0.6,
                max_output_tokens=1200,
            ),
            timeout=30,
            method_name="workout_recap",
        )
        parsed = response.parsed
        if parsed:
            payload_dict = parsed.model_dump()
        else:
            raise ValueError("Empty recap response")
    except Exception as e:
        logger.warning(f"[recap] LLM recap failed, using deterministic fallback: {e}")
        payload_dict = _deterministic_recap(
            current_session, current_volume, previous_volume,
            delta_pct, comparable_name, earned_prs, has_notes,
        )

    # Force the volume_comparison numbers to the deterministic truth (the model
    # is told to use them, but we never trust it to echo numbers correctly).
    if marked_done_no_load:
        # 0kg guardrail: no volume numbers, no delta, completion-framed summary.
        forced_summary = (
            "Marked complete — log your sets next time to unlock volume and "
            "progress insights."
        )
    else:
        forced_summary = (
            payload_dict.get("volume_comparison", {}).get("summary")
            if isinstance(payload_dict.get("volume_comparison"), dict)
            else None
        ) or _volume_summary(delta_pct, comparable_name)
    payload_dict["volume_comparison"] = {
        "current_volume_kg": current_volume,
        "previous_volume_kg": previous_volume,
        "delta_pct": delta_pct,
        "comparable_workout_name": comparable_name,
        "summary": forced_summary,
    }

    # If the user logged no notes, never fabricate a notes reference.
    if not has_notes:
        payload_dict["notes_reference"] = None

    referenced_notes = has_notes and bool(payload_dict.get("notes_reference"))

    # Attach denormalized derived fields for the endpoint to persist.
    payload_dict["_volume_delta_pct"] = delta_pct
    payload_dict["_pr_count"] = len(payload_dict.get("prs", []) or [])
    payload_dict["_referenced_notes"] = referenced_notes
    payload_dict["_total_volume_kg"] = current_volume

    logger.info(
        f"[recap] Generated for user {user_id}: "
        f"{payload_dict.get('headline', '')[:60]!r} (Δvol={delta_pct})"
    )
    return payload_dict


def _volume_summary(delta_pct: Optional[float], comparable_name: Optional[str]) -> str:
    """Deterministic one-liner for the volume trend."""
    if delta_pct is None:
        return "First session of its kind — this is your new baseline to beat."
    where = f" your last {comparable_name}" if comparable_name else " your last comparable session"
    if delta_pct >= 1:
        return f"Up {delta_pct:.0f}% in total volume over{where}."
    if delta_pct <= -1:
        return f"Down {abs(delta_pct):.0f}% in total volume vs{where} — recovery or a lighter day."
    return f"Right in line with{where} on total volume."


def _deterministic_recap(
    current_session: Dict[str, Any],
    current_volume: float,
    previous_volume: Optional[float],
    delta_pct: Optional[float],
    comparable_name: Optional[str],
    earned_prs: Optional[List[Dict[str, Any]]],
    has_notes: bool,
) -> Dict[str, Any]:
    """Build a usable recap with NO LLM (used on model failure so the card is
    never blank). Honest and data-grounded from the session totals."""
    name = current_session.get("workout_name", "your workout")
    total_sets = current_session.get("total_sets", 0)
    duration_min = (current_session.get("total_time_seconds", 0) or 0) // 60

    stood_out: List[str] = []
    if delta_pct is not None and delta_pct >= 1:
        stood_out.append(f"You moved {delta_pct:.0f}% more total volume than last time.")
    if total_sets:
        stood_out.append(f"You logged {total_sets} working sets across {duration_min} minutes.")
    if earned_prs:
        stood_out.append(f"You set {len(earned_prs)} personal record(s) this session.")
    if not stood_out:
        stood_out.append("You showed up and got the work in — consistency compounds.")

    prs = [
        {
            "exercise_name": pr.get("exercise_name", "exercise"),
            "detail": pr.get("detail") or pr.get("description") or "New personal record.",
        }
        for pr in (earned_prs or [])[:5]
    ]

    if delta_pct is not None and delta_pct < -1:
        cue = "Next time, aim to match last session's top set before adding load."
    elif earned_prs:
        cue = "Repeat the load that earned today's PR for one more session to cement it before progressing."
    else:
        cue = "Add a small load increase (about 2.5kg) on your strongest lift next session."

    return {
        "headline": f"{name} done — {total_sets} sets, {duration_min} min in the books.",
        "what_stood_out": stood_out[:3],
        "volume_comparison": {
            "current_volume_kg": current_volume,
            "previous_volume_kg": previous_volume,
            "delta_pct": delta_pct,
            "comparable_workout_name": comparable_name,
            "summary": _volume_summary(delta_pct, comparable_name),
        },
        "prs": prs,
        "coaching_cue": cue,
        "notes_reference": None,
    }


# =============================================================================
# Signature v2 — per-exercise AI critique + detailed post-workout breakdown
#
# Two MARKDOWN-emitting coach surfaces, distinct from the structured-JSON recap
# above:
#   - generate_exercise_critique: a short, strict critique of the sets just
#     logged for ONE exercise (bold lead sentence + <=3 bullets, exactly one
#     concrete cue). Used inline as the user finishes an exercise.
#   - generate_detailed_workout_summary: a longer, sectioned post-workout
#     breakdown (**Strengths** / **Weaknesses** / **What to improve** /
#     **What to do next**), persisted per (user, workout) like /recap.
#
# Both ground STRICTLY in the numbers handed to them, never invent figures, and
# FAIL OPEN to a deterministic markdown string so the client is never blank.
# =============================================================================

_LB_PER_KG = 2.2046226218


def _fmt_weight(weight_kg: Optional[float], use_kg: bool) -> str:
    """Format a kg-stored weight for display in the user's preferred unit.

    Workouts are logged in lb for this user (see feedback_weight_units), so when
    use_kg is False we convert and label in lb; otherwise we keep kg.
    """
    if weight_kg is None:
        return "bodyweight"
    if weight_kg <= 0:
        return "bodyweight"
    if use_kg:
        return f"{weight_kg:.0f}kg" if weight_kg >= 10 else f"{weight_kg:.1f}kg"
    lb = weight_kg * _LB_PER_KG
    return f"{lb:.0f}lb" if lb >= 10 else f"{lb:.1f}lb"


def _summarize_exercise_sets(
    sets: List[Dict[str, Any]],
    use_kg: bool,
) -> Dict[str, Any]:
    """Deterministic stats over the logged sets for one exercise (no LLM).

    Returns total working sets, total reps, top set, whether load dropped across
    sets (fatigue), whether RIR was logged, and a human per-set line list. Used
    both to build the model prompt and the deterministic fallback critique.
    """
    working = [
        s for s in sets
        if (s.get("set_type") or "working") not in ("warmup", "warm_up", "warm-up")
    ]
    considered = working or sets or []

    weights = [float(s.get("weight_kg") or 0) for s in considered]
    reps = [int(s.get("reps") or 0) for s in considered]
    rirs = [s.get("rir") for s in considered if s.get("rir") is not None]
    durations = [
        int(s.get("duration_seconds") or 0)
        for s in considered
        if s.get("duration_seconds")
    ]

    total_reps = sum(reps)
    top_weight = max(weights) if weights else 0.0
    top_reps = 0
    for w, r in zip(weights, reps):
        if w == top_weight:
            top_reps = max(top_reps, r)

    # Fatigue signal: load fell from the first to the last working set.
    load_dropped = bool(len(weights) >= 2 and weights[-1] < weights[0])
    # Rep dropoff: reps fell across sets at a roughly held load.
    rep_dropped = bool(len(reps) >= 2 and reps[-1] < reps[0])

    set_lines = []
    for i, s in enumerate(considered, 1):
        w = _fmt_weight(s.get("weight_kg"), use_kg)
        r = int(s.get("reps") or 0)
        dur = s.get("duration_seconds")
        if dur:
            set_lines.append(f"Set {i}: {int(dur)}s @ {w}")
        else:
            line = f"Set {i}: {r} reps @ {w}"
            if s.get("rir") is not None:
                line += f" (RIR {s.get('rir')})"
            set_lines.append(line)

    return {
        "set_count": len(considered),
        "total_reps": total_reps,
        "top_weight_kg": top_weight,
        "top_reps": top_reps,
        "rirs": rirs,
        "avg_rir": (sum(rirs) / len(rirs)) if rirs else None,
        "has_rir": bool(rirs),
        "load_dropped": load_dropped,
        "rep_dropped": rep_dropped,
        "durations": durations,
        "set_lines": set_lines,
    }


def _deterministic_exercise_critique(
    exercise_name: str,
    target: Optional[Dict[str, Any]],
    stats: Dict[str, Any],
    use_kg: bool,
) -> str:
    """No-LLM, data-grounded critique markdown (bold lead + <=3 bullets, ONE cue).

    Used on model failure / missing API key so the critique card is never blank.
    """
    set_count = stats["set_count"]
    top_w = _fmt_weight(stats["top_weight_kg"], use_kg) if stats["top_weight_kg"] else "bodyweight"

    if set_count == 0:
        return (
            f"**No sets were logged for {exercise_name}, so there is nothing to critique yet.**\n"
            f"- Log at least one working set next time so progress can be tracked.\n"
            f"- **Next time:** record reps and load for every set so the numbers tell the story."
        )

    lead = (
        f"**Solid work on {exercise_name} — {set_count} "
        f"{'set' if set_count == 1 else 'sets'} logged, top set {stats['top_reps']} reps at {top_w}.**"
    )

    bullets: List[str] = []

    # Compare to target if provided.
    if target:
        tgt_w = target.get("weight_kg")
        tgt_reps = target.get("reps")
        if tgt_w and stats["top_weight_kg"]:
            diff = stats["top_weight_kg"] - float(tgt_w)
            if diff >= 1:
                bullets.append(
                    f"- You went heavier than the {_fmt_weight(tgt_w, use_kg)} target — clean progression."
                )
            elif diff <= -1:
                bullets.append(
                    f"- Top set was below the {_fmt_weight(tgt_w, use_kg)} target; aim to close that gap next time."
                )
        if tgt_reps and stats["top_reps"] and stats["top_reps"] < int(tgt_reps):
            bullets.append(
                f"- You fell short of the {int(tgt_reps)}-rep target on your top set — chase those last reps."
            )

    if stats["load_dropped"]:
        bullets.append("- Load dropped across your sets, a normal fatigue signal — keep the top set as the benchmark.")
    elif stats["rep_dropped"]:
        bullets.append("- Reps tapered off across sets; tighten rest a touch to hold output if that wasn't intentional.")

    if stats["has_rir"] and stats["avg_rir"] is not None:
        if stats["avg_rir"] >= 3:
            bullets.append(
                f"- You averaged ~{stats['avg_rir']:.0f} reps in reserve — there's room to add load."
            )
        elif stats["avg_rir"] <= 0.5:
            bullets.append("- You took these close to failure — strong intent, watch recovery.")

    # Always end on exactly one concrete cue.
    if stats["has_rir"] and stats["avg_rir"] is not None and stats["avg_rir"] >= 2:
        cue = "- **Next time:** add a small load increase (about 2.5kg) — your reps in reserve say you have it."
    elif stats["load_dropped"]:
        cue = "- **Next time:** repeat today's top-set load and try to hold it across all sets before adding weight."
    else:
        cue = "- **Next time:** add one rep to your top set, then add load once you clear the rep target."

    # Cap to 3 bullets total INCLUDING the cue.
    bullets = bullets[:2]
    bullets.append(cue)
    return lead + "\n" + "\n".join(bullets)


async def generate_exercise_critique(
    gemini_service: GeminiService,
    exercise_name: str,
    sets: List[Dict[str, Any]],
    target: Optional[Dict[str, Any]] = None,
    use_kg: bool = False,
    exercise_id: Optional[str] = None,
    context: Optional[Any] = None,
    injury: Optional[Any] = None,
    rest: Optional[Dict[str, Any]] = None,
    form: Optional[Dict[str, Any]] = None,
    session_signals: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """Short, strict, honest AI critique of the sets just logged for ONE exercise.

    Mirrors `generate_workout_recap`'s contract: same Gemini client, strict
    system prompt (elite coach, data-grounded, NEVER invent numbers), exactly
    ONE concrete actionable cue. Output is short MARKDOWN (bold lead sentence +
    <=3 bullets). FAILS OPEN to a deterministic critique from the numbers.

    Args:
        gemini_service: Gemini service for the LLM call.
        exercise_name: Display name of the exercise.
        sets: Logged sets, each {weight_kg, reps, rir, duration_seconds, set_type}.
        target: Optional {weight_kg, reps, rir} prescription to compare against.
        use_kg: When False, weights are phrased in lb (this user trains in lb).
        exercise_id: Optional exercise UUID (passed through, not required).
        context: Optional ExerciseContext (prior sessions, PR status, 1RM) to add
            PRIOR SESSIONS / PR STATUS blocks. Optional.
        injury: Optional InjuryContext — when this exercise is pain-flagged or an
            active injury affects it, adds a PAIN block (don't push load).
        rest: Optional {avg_actual_s, avg_prescribed_s} for this exercise.
        form: Optional {form_score, top_issues} most-recent form analysis.
        session_signals: Optional distilled signals scoped to this exercise.

    Returns:
        {"critique_markdown": str, "is_fallback": bool}. Never raises.
    """
    from google.genai import types
    from services.gemini.constants import gemini_generate_with_retry

    stats = _summarize_exercise_sets(sets or [], use_kg)

    # 0-load guardrail: if no set carries weight, talk reps/RIR, never "0kg"/"0lb".
    no_load = (stats.get("top_weight_kg") or 0) <= 0 and stats.get("set_count", 0) > 0

    # Build the deterministic, numbers-only context the model must ground on.
    set_block = "\n".join(stats["set_lines"]) if stats["set_lines"] else "No sets logged."
    target_line = "No target prescribed."
    if target:
        tw = _fmt_weight(target.get("weight_kg"), use_kg)
        tr = target.get("reps")
        trir = target.get("rir")
        target_line = f"Target: {tr if tr is not None else '?'} reps @ {tw}"
        if trir is not None:
            target_line += f" (RIR {trir})"

    unit = "kilograms" if use_kg else "pounds"

    # --- Enrichment blocks for ONE exercise (omitted when empty) ---
    enrich_lines: List[str] = []
    if context is not None:
        hb = build_history_pr_block({exercise_name: context}, use_kg)
        if hb:
            enrich_lines.append(hb)
        if getattr(context, "is_pr", False):
            enrich_lines.append("PR STATUS: today's top set is a NEW PR for this exercise.")
        elif getattr(context, "is_near_pr", False):
            enrich_lines.append("PR STATUS: today's top set is within ~2.5% of the all-time best (near PR).")
    if rest:
        rb = build_rest_block({exercise_name: rest})
        if rb:
            enrich_lines.append(rb)
    if form:
        # Reuse the form block builder via a one-item context.
        class _FormHolder:
            pass
        holder = _FormHolder()
        holder.form = form
        fb = build_form_block({exercise_name: holder})
        if fb:
            enrich_lines.append(fb)
    # Pain: only inject when THIS exercise is affected.
    if injury is not None:
        pain_names = [n.lower() for n in (getattr(injury, "pain_flagged_exercises", None) or [])]
        affected = exercise_name.lower() in pain_names
        if not affected:
            for inj in (getattr(injury, "injuries", None) or []):
                aff = [str(a).lower() for a in (inj.get("affects_exercises") or [])]
                if exercise_name.lower() in aff:
                    affected = True
                    break
        if affected:
            enrich_lines.append(
                "PAIN: this movement is flagged for pain/injury — do NOT cue adding "
                "load; favor pain-free range and recovery."
            )
    if session_signals:
        sb = _signals_prompt_block(session_signals)
        if sb:
            enrich_lines.append(sb)
    enrich_block = ("\n\n" + "\n\n".join(enrich_lines)) if enrich_lines else ""

    zero_load_rule = (
        " The sets carry NO external load (bodyweight or unweighted) — speak to "
        "reps and reps-in-reserve, NEVER mention weight, '0kg', or '0lb'."
        if no_load else ""
    )
    pain_rule = (
        " A PAIN block may be present — if so, never cue adding load on this movement."
    )
    system_prompt = (
        "You are an elite strength coach giving a SHORT, honest, data-grounded "
        "critique of the sets a client just logged for ONE exercise. Be specific; "
        "never generic. Use ONLY the numbers provided — NEVER invent reps, loads, "
        "or RIR. Weights are in " + unit + "; keep them in that unit. "
        "Output MARKDOWN: a single bold lead sentence, then AT MOST 3 bullet "
        "points. Exactly ONE bullet is a concrete, actionable cue for next time, "
        "tied to the actual numbers. No emojis. No headers. Keep it tight."
        + zero_load_rule + pain_rule
    )

    top_set_str = (
        f"{stats['top_reps']} reps at {_fmt_weight(stats['top_weight_kg'], use_kg)}"
        if stats['top_weight_kg'] else f"{stats['top_reps']} reps (bodyweight)"
    )
    user_prompt = f"""Critique this exercise based ONLY on the data below.

Exercise: {exercise_name}
{target_line}

Sets logged:
{set_block}

Summary (use these, do not change them):
- Working sets: {stats['set_count']}
- Total reps: {stats['total_reps']}
- Top set: {top_set_str}
- Reps in reserve logged: {'yes, avg ' + format(stats['avg_rir'], '.1f') if stats['has_rir'] else 'no'}
- Load dropped across sets: {'yes' if stats['load_dropped'] else 'no'}
{enrich_block}

Write a bold one-sentence lead, then up to 3 bullets, one of which is a single concrete cue for next time."""

    try:
        response = await gemini_generate_with_retry(
            model=gemini_service.model,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                temperature=0.55,
                max_output_tokens=400,
            ),
            timeout=20,
            method_name="exercise_critique",
        )
        text = (response.text or "").strip()
        if not text:
            raise ValueError("Empty critique response")
        logger.info(f"[critique] Generated for {exercise_name}: {text[:50]!r}")
        return {"critique_markdown": text, "is_fallback": False}
    except Exception as e:
        logger.warning(f"[critique] LLM critique failed, using deterministic fallback: {e}")
        return {
            "critique_markdown": _deterministic_exercise_critique(
                exercise_name, target, stats, use_kg
            ),
            "is_fallback": True,
        }


# ---------------------------------------------------------------------------
# Detailed post-workout summary (sectioned markdown), persisted like /recap.
# ---------------------------------------------------------------------------

_DETAILED_SECTIONS = ("Strengths", "Weaknesses", "What to improve", "What to do next")


def _deterministic_detailed_summary(
    current_session: Dict[str, Any],
    current_volume: float,
    previous_volume: Optional[float],
    delta_pct: Optional[float],
    comparable_name: Optional[str],
    earned_prs: Optional[List[Dict[str, Any]]],
    skipped_names: List[str],
    completion_rate: float,
) -> str:
    """No-LLM sectioned markdown breakdown (used on model failure / no API key).

    Sections, in order: **Strengths**, **Weaknesses**, **What to improve**,
    **What to do next** — honest and grounded in the session totals.
    """
    name = current_session.get("workout_name", "your workout")
    total_sets = current_session.get("total_sets", 0)
    duration_min = (current_session.get("total_time_seconds", 0) or 0) // 60

    strengths: List[str] = []
    if delta_pct is not None and delta_pct >= 1:
        strengths.append(f"Total volume was up {delta_pct:.0f}% over your last {comparable_name or 'comparable session'}.")
    if earned_prs:
        pr_names = ", ".join(p.get("exercise_name", "a lift") for p in earned_prs[:3])
        strengths.append(f"You set {len(earned_prs)} personal record(s) — {pr_names}.")
    if completion_rate >= 90:
        strengths.append(f"You completed {completion_rate:.0f}% of the planned work — full effort.")
    if total_sets:
        strengths.append(f"You logged {total_sets} working sets across {duration_min} minutes.")
    if not strengths:
        strengths.append("You showed up and got the session in — consistency is the foundation.")

    weaknesses: List[str] = []
    if skipped_names:
        weaknesses.append(f"You skipped {len(skipped_names)} exercise(s): {', '.join(skipped_names)}.")
    if delta_pct is not None and delta_pct < -5:
        weaknesses.append(f"Total volume fell {abs(delta_pct):.0f}% versus your last comparable session.")
    if completion_rate < 70:
        weaknesses.append(f"Only {completion_rate:.0f}% of the planned work was completed.")
    if not weaknesses:
        weaknesses.append("Nothing major stood out as a weakness — keep the standard high.")

    improve: List[str] = []
    if skipped_names:
        improve.append("Protect time for the full session so nothing gets dropped at the end.")
    if delta_pct is not None and delta_pct < -1:
        improve.append("Rebuild volume gradually — match last session's top sets before adding load.")
    improve.append("Log reps in reserve on your main lifts so load can be tuned precisely.")

    next_steps: List[str] = []
    if earned_prs:
        next_steps.append("Repeat the load that earned today's PR once more to cement it before progressing.")
    else:
        next_steps.append("Add a small load increase (about 2.5kg) on your strongest lift next session.")
    if skipped_names:
        next_steps.append(f"Prioritize {skipped_names[0]} early in your next session.")

    def _bullets(items: List[str]) -> str:
        return "\n".join(f"- {x}" for x in items)

    return (
        f"**Strengths**\n{_bullets(strengths[:4])}\n\n"
        f"**Weaknesses**\n{_bullets(weaknesses[:4])}\n\n"
        f"**What to improve**\n{_bullets(improve[:4])}\n\n"
        f"**What to do next**\n{_bullets(next_steps[:4])}"
    )


async def generate_detailed_workout_summary(
    gemini_service: GeminiService,
    rag_service: WorkoutFeedbackRAGService,
    user_id: str,
    current_session: Dict[str, Any],
    earned_prs: Optional[List[Dict[str, Any]]] = None,
    logged_notes: Optional[List[str]] = None,
    total_workouts_completed: Optional[int] = None,
    exercise_contexts: Optional[Dict[str, Any]] = None,
    injury_context: Optional[Any] = None,
    rest_analysis: Optional[Dict[str, Any]] = None,
    session_signals: Optional[List[str]] = None,
    use_kg: bool = False,
) -> Dict[str, Any]:
    """Longer, strict, honest post-workout breakdown as sectioned MARKDOWN.

    Sections, exactly and in order: **Strengths**, **Weaknesses**,
    **What to improve**, **What to do next**. Grounded ONLY in the provided data
    (volume vs last comparable session, PRs, completion %, skipped exercises,
    rest, RIR). FAILS OPEN to a deterministic structured summary.

    Reuses the same comparison machinery as `generate_workout_recap`.

    Returns:
        {"summary_markdown": str, "is_fallback": bool}. Never raises.
    """
    from google.genai import types
    from services.gemini.constants import gemini_generate_with_retry

    # --- Gather comparison context (deterministic, no LLM), concurrently. ---
    ex_names = [
        ex.get("name", "")
        for ex in (current_session.get("exercises", []) or [])[:5]
        if ex.get("name")
    ]
    # See generate_workout_recap: when exercise_contexts are supplied we only need
    # the session-level history (the per-exercise ChromaDB loop is superseded).
    if exercise_contexts:
        history_result = await rag_service.get_user_workout_history(user_id, n_results=10)
        weight_progressions: Dict[str, List[Dict[str, Any]]] = {}
        if isinstance(history_result, Exception):
            logger.warning(f"[detailed] workout history fetch failed: {history_result}")
            past_sessions = []
        else:
            past_sessions = history_result
    else:
        gathered = await asyncio.gather(
            rag_service.get_user_workout_history(user_id, n_results=10),
            *[
                rag_service.get_exercise_weight_history(user_id, n, n_results=5)
                for n in ex_names
            ],
            return_exceptions=True,
        )
        history_result = gathered[0]
        past_sessions = history_result if not isinstance(history_result, Exception) else []
        if isinstance(history_result, Exception):
            logger.warning(f"[detailed] workout history fetch failed: {history_result}")

        weight_progressions = {}
        for ex_name, history in zip(ex_names, gathered[1:]):
            if history and not isinstance(history, Exception):
                weight_progressions[ex_name] = history

    comparable = _find_last_comparable_session(current_session, past_sessions)

    current_volume = float(current_session.get("total_volume_kg", 0) or 0)
    previous_volume: Optional[float] = None
    comparable_name: Optional[str] = None
    delta_pct: Optional[float] = None
    if comparable:
        cmeta = comparable.get("metadata", {}) or {}
        comparable_name = cmeta.get("workout_name")
        try:
            previous_volume = float(cmeta.get("total_volume_kg", 0) or 0)
        except (TypeError, ValueError):
            previous_volume = None
        if previous_volume and previous_volume > 0:
            delta_pct = round((current_volume - previous_volume) / previous_volume * 100, 1)

    # Completion / skip analysis (deterministic). Compare case-insensitively but
    # keep the planned exercise's ORIGINAL casing for display.
    exercises = current_session.get("exercises", []) or []
    planned = current_session.get("planned_exercises", []) or []
    completed_lower = {e.get("name", "").lower() for e in exercises if e.get("name")}
    skipped_names = [
        e.get("name")
        for e in planned
        if e.get("name") and e.get("name", "").lower() not in completed_lower
    ]
    total_planned = len(planned) if planned else len(exercises)
    completion_rate = (len(exercises) / total_planned * 100) if total_planned > 0 else 100.0

    context = rag_service.format_feedback_context(
        current_session, past_sessions, weight_progressions
    )

    # --- 0kg GUARDRAIL (same as the recap) ---
    marked_done_no_load = current_volume <= 0
    if marked_done_no_load:
        previous_volume = None
        delta_pct = None
        vol_line = (
            "This session was marked complete with no logged load (no per-set "
            "weights). Do NOT mention volume, kilograms, '0kg', or any baseline "
            "number — speak only to completion, adherence, and what to log next time."
        )
    elif previous_volume and delta_pct is not None:
        direction = "up" if delta_pct >= 0 else "down"
        vol_line = (
            f"Total volume this session: {current_volume:.0f}kg. "
            f"Last comparable session ('{comparable_name}'): {previous_volume:.0f}kg "
            f"({direction} {abs(delta_pct):.1f}%)."
        )
    else:
        vol_line = (
            f"Total volume this session: {current_volume:.0f}kg. "
            f"No comparable prior session (first of its kind)."
        )

    # Enrichment blocks (B / A2 / A3) — omitted when empty.
    history_block = build_history_pr_block(exercise_contexts, use_kg)
    effort_block = build_effort_block(exercise_contexts)
    rest_block = build_rest_block(rest_analysis)
    injury_block = build_injury_block(injury_context)
    form_block = build_form_block(exercise_contexts)
    signals_block = _signals_prompt_block(session_signals)
    extra_blocks = "\n\n".join(
        b for b in (history_block, effort_block, rest_block, injury_block, form_block, signals_block) if b
    )

    pr_lines = ""
    if earned_prs:
        pr_lines = "PRs hit this session:\n" + "\n".join(
            f"- {pr.get('exercise_name', 'exercise')}: {pr.get('detail') or pr.get('description') or 'new personal record'}"
            for pr in earned_prs[:5]
        )

    notes_block = ""
    if logged_notes:
        notes_block = "User logged notes this session:\n" + "\n".join(
            f"- {n}" for n in logged_notes[:8] if n
        )

    consistency_line = ""
    if total_workouts_completed:
        consistency_line = f"Lifetime workouts completed: {total_workouts_completed}."

    zero_load_rule = (
        " This session has NO logged load — NEVER write '0kg', 'baseline', or a "
        "volume figure anywhere; frame strengths/weaknesses around completion, "
        "adherence, and logging discipline."
        if marked_done_no_load else ""
    )
    system_prompt = (
        "You are an elite strength coach writing a HONEST, data-grounded breakdown "
        "of a client's just-finished workout. Be specific; never generic. Use ONLY "
        "the numbers provided — NEVER invent volume, weights, PRs, RIR, rest, or "
        "completion figures. When an INJURY/PAIN block is present, respect it — "
        "never advise pushing load on an affected movement. Output MARKDOWN with "
        "EXACTLY these four bold section headers, in this order, each followed by "
        "1-4 bullet points:\n"
        "**Strengths**\n**Weaknesses**\n**What to improve**\n**What to do next**\n"
        "Do not add other sections or headers. No emojis. Keep each bullet to one "
        "sentence. 'What to do next' must contain concrete, actionable steps tied "
        "to the data." + zero_load_rule
    )

    user_prompt = f"""Write the four-section breakdown of this workout, grounded only in the data below.

{context}

{extra_blocks}

VOLUME COMPARISON (use these exact numbers):
{vol_line}

COMPLETION: {len(exercises)}/{total_planned} exercises completed ({completion_rate:.0f}%).{(' Skipped: ' + ', '.join(skipped_names) + '.') if skipped_names else ''}

{pr_lines}

{notes_block}

{consistency_line}

Output the four bold sections (**Strengths**, **Weaknesses**, **What to improve**, **What to do next**), each with 1-4 one-sentence bullets, honest and specific."""

    try:
        response = await gemini_generate_with_retry(
            model=gemini_service.model,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                temperature=0.6,
                max_output_tokens=1100,
            ),
            timeout=30,
            method_name="detailed_summary",
        )
        text = (response.text or "").strip()
        # Validate the four required headers are present; otherwise fall open so
        # the client always gets the agreed structure.
        if not text or not all(f"**{s}**" in text for s in _DETAILED_SECTIONS):
            raise ValueError("Detailed summary missing required sections")
        logger.info(f"[detailed] Generated for user {user_id} (Δvol={delta_pct})")
        return {"summary_markdown": text, "is_fallback": False}
    except Exception as e:
        logger.warning(f"[detailed] LLM summary failed, using deterministic fallback: {e}")
        return {
            "summary_markdown": _deterministic_detailed_summary(
                current_session, current_volume, previous_volume, delta_pct,
                comparable_name, earned_prs, skipped_names, completion_rate,
            ),
            "is_fallback": True,
        }
