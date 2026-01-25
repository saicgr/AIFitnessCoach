"""
AI Coach Service - Main orchestration layer.

This service coordinates between Gemini, RAG, and workout logic.

EASY TO MODIFY:
- Change how context is built: Modify _build_context()
- Change how intents are handled: Modify _handle_intent()
- Add new capabilities: Add new methods following existing patterns
"""
import json
from typing import List, Dict, Any, Optional
from models.chat import (
    ChatRequest, ChatResponse, IntentExtraction, CoachIntent,
    UserProfile, WorkoutContext
)
from services.gemini_service import GeminiService
from services.rag_service import RAGService
from services.workout_modifier import WorkoutModifier
from core.logger import get_logger

logger = get_logger(__name__)


class CoachService:
    """
    Main AI Coach service.

    Orchestrates:
    1. Intent extraction
    2. RAG context retrieval
    3. Response generation
    4. Q&A storage for future RAG
    """

    def __init__(self, gemini_service: GeminiService, rag_service: RAGService):
        self.gemini = gemini_service
        self.rag = rag_service
        self.workout_modifier = WorkoutModifier()

    async def process_message(self, request: ChatRequest) -> ChatResponse:
        """
        Process a user message and generate a response.

        This is the main entry point for chat functionality.
        """
        logger.info(f"USER MESSAGE: {request.message}")

        # Log workout context for debugging
        if request.current_workout:
            exercise_names = [e.get("name", "Unknown") for e in request.current_workout.exercises]
            logger.info(f"WORKOUT CONTEXT: {request.current_workout.name} with exercises: {exercise_names}")
        else:
            logger.warning("NO WORKOUT CONTEXT: current_workout is None")

        # Step 1: Extract intent using AI
        intent_extraction = await self.gemini.extract_intent(request.message)
        logger.info(f"Intent: {intent_extraction.intent.value}")
        if intent_extraction.exercises:
            logger.info(f"Exercises mentioned: {intent_extraction.exercises}")
        if intent_extraction.muscle_groups:
            logger.info(f"Muscle groups: {intent_extraction.muscle_groups}")

        # Step 2: Find similar past Q&As for context (RAG)
        logger.debug("Step 2: Searching RAG")
        similar_docs = await self.rag.find_similar(
            query=request.message,
            user_id=request.user_id,
        )
        rag_context = self.rag.format_context(similar_docs)
        rag_used = len(similar_docs) > 0
        logger.debug(f"RAG found {len(similar_docs)} similar conversations")

        # Step 3: Build full context for AI
        logger.debug("Step 3: Building context")
        full_context = self._build_context(
            user_profile=request.user_profile,
            current_workout=request.current_workout,
            rag_context=rag_context,
        )

        # Step 4: Generate response
        system_prompt = self.gemini.get_coach_system_prompt(full_context)
        ai_response = await self.gemini.chat(
            user_message=request.message,
            system_prompt=system_prompt,
            conversation_history=request.conversation_history,
        )
        logger.info(f"AI RESPONSE: {ai_response[:500]}{'...' if len(ai_response) > 500 else ''}")

        # Step 4.5: Re-extract exercises from AI response for add/remove intents
        # This ensures we add the exercises the AI ACTUALLY mentioned, not just what was in user's message
        if intent_extraction.intent in [CoachIntent.ADD_EXERCISE, CoachIntent.REMOVE_EXERCISE]:
            response_extraction = await self.gemini.extract_exercises_from_response(ai_response)
            if response_extraction:
                logger.info(f"Exercises extracted from AI response: {response_extraction}")
                # Merge exercises: use AI response exercises as authoritative source
                intent_extraction.exercises = response_extraction
            else:
                logger.warning("No exercises extracted from AI response, using original intent extraction")

        # Step 4.6: Execute workout modifications based on intent
        if request.current_workout:
            await self._execute_workout_modifications(
                intent=intent_extraction,
                current_workout=request.current_workout,
                user_message=request.message,
            )

        # Step 5: Build action data based on intent
        action_data = self._build_action_data(
            intent=intent_extraction,
            current_workout=request.current_workout,
            user_message=request.message,
        )

        # Step 6: Store Q&A for future RAG (async, fire-and-forget style)
        await self.rag.add_qa_pair(
            question=request.message,
            answer=ai_response,
            intent=intent_extraction.intent.value,
            user_id=request.user_id,
            metadata={
                "exercises": json.dumps(intent_extraction.exercises),
                "muscle_groups": json.dumps(intent_extraction.muscle_groups),
            }
        )

        # Step 7: Return response
        return ChatResponse(
            message=ai_response,
            intent=intent_extraction.intent,
            action_data=action_data,
            rag_context_used=rag_used,
            similar_questions=[
                doc["metadata"]["question"]
                for doc in similar_docs[:3]
            ],
        )

    def _build_context(
        self,
        user_profile: Optional[UserProfile],
        current_workout: Optional[WorkoutContext],
        rag_context: str,
    ) -> str:
        """
        Build context string for the AI prompt.

        MODIFY THIS to change what context the AI sees.
        """
        context_parts = []

        # User profile context
        if user_profile:
            # Safely join lists - handle case where items might be dicts
            def safe_join(items):
                if not items:
                    return "Not specified"
                result = []
                for item in items:
                    if isinstance(item, str):
                        result.append(item)
                    elif isinstance(item, dict):
                        # Try common keys for name
                        name = item.get("name") or item.get("goal") or item.get("title") or str(item)
                        result.append(str(name))
                    else:
                        result.append(str(item))
                return ", ".join(result) if result else "Not specified"

            context_parts.extend([
                "USER PROFILE:",
                f"- Fitness Level: {user_profile.fitness_level}",
                f"- Goals: {safe_join(user_profile.goals)}",
                f"- Equipment: {safe_join(user_profile.equipment)}",
            ])
            if user_profile.active_injuries:
                context_parts.append(
                    f"- Active Injuries: {safe_join(user_profile.active_injuries)}"
                )

        # Current workout context
        if current_workout:
            exercise_names = [e.get("name", "Unknown") for e in current_workout.exercises]
            context_parts.extend([
                "",
                "TODAY'S WORKOUT:",
                f"- Name: {current_workout.name}",
                f"- Type: {current_workout.type}",
                f"- Difficulty: {current_workout.difficulty}",
                f"- Exercises: {', '.join(exercise_names)}",
            ])

        # RAG context
        if rag_context:
            context_parts.extend(["", rag_context])

        return "\n".join(context_parts)

    def _build_action_data(
        self,
        intent: IntentExtraction,
        current_workout: Optional[WorkoutContext],
        user_message: str,
    ) -> Optional[Dict[str, Any]]:
        """
        Build action data for workout modifications.

        MODIFY THIS to change how workout actions work.
        """
        if not current_workout:
            return None

        action_map = {
            CoachIntent.ADD_EXERCISE: {
                "action": "add_exercise",
                "workout_id": current_workout.id,
                "exercise_names": intent.exercises,
                "muscle_groups": intent.muscle_groups,
            },
            CoachIntent.REMOVE_EXERCISE: {
                "action": "remove_exercise",
                "workout_id": current_workout.id,
                "exercise_names": intent.exercises,
                "muscle_groups": intent.muscle_groups,
            },
            CoachIntent.SWAP_WORKOUT: {
                "action": "swap_workout",
                "original_workout_id": current_workout.id,
                "reason": user_message,
            },
            CoachIntent.MODIFY_INTENSITY: {
                "action": "modify_intensity",
                "workout_id": current_workout.id,
                "modification": intent.modification or "adjust",
            },
            CoachIntent.RESCHEDULE: {
                "action": "reschedule",
                "workout_id": current_workout.id,
            },
            CoachIntent.REPORT_INJURY: {
                "action": "report_injury",
                "description": user_message,
                "body_part": intent.body_part or "general",
            },
        }

        return action_map.get(intent.intent)

    async def _execute_workout_modifications(
        self,
        intent: IntentExtraction,
        current_workout: WorkoutContext,
        user_message: str,
    ) -> None:
        """
        Execute actual workout modifications based on intent.

        This method calls WorkoutModifier to update the database.
        """
        workout_id = current_workout.id

        if intent.intent == CoachIntent.ADD_EXERCISE:
            if intent.exercises:
                logger.info(f"EXECUTING: Adding exercises {intent.exercises} to workout {workout_id}")
                success = self.workout_modifier.add_exercises_to_workout(
                    workout_id=workout_id,
                    exercise_names=intent.exercises,
                    muscle_groups=intent.muscle_groups,
                )
                if success:
                    logger.info(f"Successfully added exercises to workout {workout_id}")
                else:
                    logger.error(f"Failed to add exercises to workout {workout_id}")
            else:
                logger.warning("ADD_EXERCISE intent but no exercises specified")

        elif intent.intent == CoachIntent.REMOVE_EXERCISE:
            if intent.exercises:
                logger.info(f"EXECUTING: Removing exercises {intent.exercises} from workout {workout_id}")
                success = self.workout_modifier.remove_exercises_from_workout(
                    workout_id=workout_id,
                    exercise_names=intent.exercises,
                )
                if success:
                    logger.info(f"Successfully removed exercises from workout {workout_id}")
                else:
                    logger.error(f"Failed to remove exercises from workout {workout_id}")
            else:
                logger.warning("REMOVE_EXERCISE intent but no exercises specified")

        elif intent.intent == CoachIntent.MODIFY_INTENSITY:
            logger.info(f"EXECUTING: Modifying intensity for workout {workout_id}")
            modification = intent.modification or user_message
            success = self.workout_modifier.modify_workout_intensity(
                workout_id=workout_id,
                modification=modification,
            )
            if success:
                logger.info(f"Successfully modified intensity for workout {workout_id}")
            else:
                logger.error(f"Failed to modify intensity for workout {workout_id}")
