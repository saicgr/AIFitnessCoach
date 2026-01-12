"""
Calibration Workout Service.

Handles generation and analysis of calibration/test workouts to assess user's
actual fitness level versus self-reported level. Used during onboarding to
create personalized baseline strength data.
"""
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
import json

from google import genai
from google.genai import types

from core.config import get_settings
from core.logger import get_logger
from models.gemini_schemas import CalibrationWorkoutResponse, PerformanceAnalysisResponse

settings = get_settings()
logger = get_logger(__name__)

# Initialize the Gemini client
client = genai.Client(api_key=settings.gemini_api_key)


class MovementPattern(Enum):
    """Key movement patterns to test in calibration workout."""
    UPPER_PUSH = "upper_push"
    UPPER_PULL = "upper_pull"
    LOWER_BODY = "lower_body"
    CORE = "core"


class FitnessLevelAssessment(Enum):
    """Assessed fitness level based on calibration results."""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


@dataclass
class CalibrationExercise:
    """An exercise performed during calibration with results."""
    name: str
    movement_pattern: str
    sets_completed: int
    reps_completed: int
    weight_used_kg: float
    suggested_weight_kg: float
    perceived_difficulty: int  # 1-10 scale
    target_reps: int
    target_sets: int
    equipment: str
    muscle_group: str
    notes: Optional[str] = None


@dataclass
class CalibrationResult:
    """Results from a completed calibration workout."""
    exercises: List[CalibrationExercise]
    total_duration_seconds: int
    overall_perceived_difficulty: int  # 1-10 scale
    completed_at: datetime
    user_comments: Optional[str] = None


@dataclass
class StrengthBaseline:
    """Estimated strength baseline for an exercise."""
    exercise_name: str
    movement_pattern: str
    weight_kg: float
    reps: int
    estimated_1rm_kg: float
    muscle_group: str


@dataclass
class CalibrationAnalysis:
    """AI analysis of calibration workout results."""
    reported_fitness_level: str
    assessed_fitness_level: str
    confidence_score: float  # 0-1 score
    level_match: bool
    insights: List[str]
    strength_assessment: Dict[str, str]  # movement_pattern -> assessment
    performance_summary: str
    recommendations: List[str]


@dataclass
class CalibrationSuggestedAdjustments:
    """Suggested profile adjustments based on calibration analysis."""
    suggested_fitness_level: Optional[str]
    suggested_intensity: Optional[str]
    weight_multipliers: Dict[str, float]  # movement_pattern -> multiplier
    message: str
    detailed_explanation: str
    should_prompt_user: bool


# Movement pattern definitions with exercise examples
MOVEMENT_PATTERN_EXERCISES = {
    MovementPattern.UPPER_PUSH: {
        "bodyweight": ["Push-up", "Pike Push-up", "Diamond Push-up", "Wall Push-up"],
        "dumbbells": ["Dumbbell Bench Press", "Dumbbell Shoulder Press", "Dumbbell Floor Press"],
        "barbell": ["Barbell Bench Press", "Overhead Press", "Incline Bench Press"],
        "resistance_bands": ["Band Push-up", "Band Chest Press", "Band Shoulder Press"],
        "machines": ["Chest Press Machine", "Shoulder Press Machine"],
    },
    MovementPattern.UPPER_PULL: {
        "bodyweight": ["Inverted Row", "Australian Pull-up", "Chin-up", "Pull-up"],
        "dumbbells": ["Dumbbell Row", "Bent Over Row", "Renegade Row"],
        "barbell": ["Barbell Row", "Pendlay Row", "T-Bar Row"],
        "resistance_bands": ["Band Row", "Band Pull-apart", "Band Face Pull"],
        "machines": ["Lat Pulldown", "Seated Row Machine", "Cable Row"],
    },
    MovementPattern.LOWER_BODY: {
        "bodyweight": ["Bodyweight Squat", "Lunge", "Split Squat", "Step-up"],
        "dumbbells": ["Goblet Squat", "Dumbbell Lunge", "Dumbbell Romanian Deadlift"],
        "barbell": ["Back Squat", "Front Squat", "Deadlift", "Romanian Deadlift"],
        "resistance_bands": ["Band Squat", "Band Leg Press", "Band Romanian Deadlift"],
        "machines": ["Leg Press", "Leg Extension", "Leg Curl"],
    },
    MovementPattern.CORE: {
        "bodyweight": ["Plank", "Dead Bug", "Bird Dog", "Mountain Climber", "Hollow Hold"],
        "dumbbells": ["Weighted Plank", "Dumbbell Side Bend", "Dumbbell Russian Twist"],
        "barbell": ["Barbell Rollout"],
        "resistance_bands": ["Band Pallof Press", "Band Anti-Rotation"],
        "machines": ["Cable Crunch", "Ab Machine"],
    },
}

# Fitness level weight guidelines (kg) by movement pattern
FITNESS_LEVEL_WEIGHT_GUIDELINES = {
    "beginner": {
        MovementPattern.UPPER_PUSH: {"male": 10, "female": 5},
        MovementPattern.UPPER_PULL: {"male": 10, "female": 5},
        MovementPattern.LOWER_BODY: {"male": 15, "female": 10},
        MovementPattern.CORE: {"male": 0, "female": 0},  # Usually bodyweight
    },
    "intermediate": {
        MovementPattern.UPPER_PUSH: {"male": 25, "female": 12.5},
        MovementPattern.UPPER_PULL: {"male": 20, "female": 10},
        MovementPattern.LOWER_BODY: {"male": 40, "female": 25},
        MovementPattern.CORE: {"male": 5, "female": 2.5},
    },
    "advanced": {
        MovementPattern.UPPER_PUSH: {"male": 45, "female": 25},
        MovementPattern.UPPER_PULL: {"male": 35, "female": 20},
        MovementPattern.LOWER_BODY: {"male": 80, "female": 50},
        MovementPattern.CORE: {"male": 10, "female": 5},
    },
}


def calculate_1rm_brzycki(weight_kg: float, reps: int) -> float:
    """
    Calculate estimated 1RM using Brzycki formula.

    Formula: 1RM = weight / (1.0278 - 0.0278 * reps)

    Most accurate for 1-10 reps.
    """
    if reps <= 0:
        return 0.0
    if reps == 1:
        return weight_kg
    if reps > 10:
        # Less accurate above 10 reps, use modified formula
        return weight_kg * (36 / (37 - reps))

    return weight_kg / (1.0278 - 0.0278 * reps)


def calculate_1rm_epley(weight_kg: float, reps: int) -> float:
    """
    Calculate estimated 1RM using Epley formula.

    Formula: 1RM = weight * (1 + reps/30)

    Alternative formula, good for higher rep ranges.
    """
    if reps <= 0:
        return 0.0
    if reps == 1:
        return weight_kg

    return weight_kg * (1 + reps / 30)


class CalibrationWorkoutService:
    """
    Service for generating and analyzing calibration/test workouts.

    Calibration workouts are quick (15 min) test workouts with 5-6 exercises
    that assess a user's actual fitness level by testing key movement patterns.
    """

    def __init__(self):
        """Initialize the calibration workout service."""
        self.model = settings.gemini_model

    async def generate_calibration_workout(
        self,
        user_data: dict
    ) -> dict:
        """
        Generate a quick 15 minute calibration workout based on onboarding data.

        Args:
            user_data: User's profile data including:
                - fitness_level: Self-reported fitness level
                - equipment: List of available equipment
                - goals: Fitness goals
                - age: User's age
                - gender: User's gender (for weight recommendations)
                - injuries: Any injuries to avoid

        Returns:
            Dict containing workout structure with exercises for each movement pattern
        """
        fitness_level = user_data.get("fitness_level", "beginner")
        equipment = user_data.get("equipment", ["bodyweight"])
        goals = user_data.get("goals", ["general_fitness"])
        age = user_data.get("age", 30)
        gender = user_data.get("gender", "male").lower()
        injuries = user_data.get("injuries", [])

        logger.info(
            f"Generating calibration workout for {fitness_level} user",
            extra={
                "fitness_level": fitness_level,
                "equipment_count": len(equipment),
                "age": age,
                "gender": gender,
            }
        )

        # Build equipment string for prompt
        equipment_str = ", ".join(equipment) if equipment else "bodyweight only"

        # Build injury avoidance string
        injury_str = ""
        if injuries:
            injury_str = f"\n- Injuries to avoid: {', '.join(injuries)}"

        # Age-specific considerations
        age_context = ""
        if age >= 60:
            age_context = "\n- Senior user (60+): Include gentler progressions, avoid explosive movements"
        elif age >= 45:
            age_context = "\n- Middle-aged user: Include moderate progressions with proper warm-up emphasis"

        # Get weight guidelines for the prompt
        upper_push_weight = FITNESS_LEVEL_WEIGHT_GUIDELINES[fitness_level][MovementPattern.UPPER_PUSH][gender]
        upper_pull_weight = FITNESS_LEVEL_WEIGHT_GUIDELINES[fitness_level][MovementPattern.UPPER_PULL][gender]
        lower_body_weight = FITNESS_LEVEL_WEIGHT_GUIDELINES[fitness_level][MovementPattern.LOWER_BODY][gender]
        core_weight = FITNESS_LEVEL_WEIGHT_GUIDELINES[fitness_level][MovementPattern.CORE][gender]

        prompt = f"""Generate a quick 15 minute calibration/assessment workout to test the user's fitness level.

USER PROFILE:
- Self-reported fitness level: {fitness_level}
- Available equipment: {equipment_str}
- Goals: {', '.join(goals)}
- Age: {age}
- Gender: {gender}{injury_str}{age_context}

CALIBRATION WORKOUT REQUIREMENTS:

1. TEST ALL FOUR MOVEMENT PATTERNS (5-6 exercises total):
   - Upper Body Push (chest, shoulders, triceps): 1-2 exercises
   - Upper Body Pull (back, biceps): 1-2 exercises
   - Lower Body (legs, glutes): 1-2 exercises
   - Core (abs, obliques): 1 exercise

2. EXERCISE SELECTION RULES:
   - Select exercises that match the user's available equipment
   - Include ONE primary compound movement per pattern
   - Each exercise should have 2-3 sets with 8-12 target reps
   - Include progressive weight options (lighter, standard, heavier)

3. WEIGHT RECOMMENDATIONS:
   For {fitness_level} level with {gender} user:
   - Upper Push: Start with {upper_push_weight}kg
   - Upper Pull: Start with {upper_pull_weight}kg
   - Lower Body: Start with {lower_body_weight}kg
   - Core: Start with {core_weight}kg

4. FORMAT:
   Each exercise should include weight options:
   - lighter_weight_kg: Weight for if standard feels too heavy
   - standard_weight_kg: Expected weight for this fitness level
   - heavier_weight_kg: Weight to try if standard feels too easy

Return ONLY valid JSON in this exact format:
{{
    "name": "Fitness Calibration Test",
    "type": "calibration",
    "duration_minutes": 18,
    "description": "A brief description of what this calibration tests",
    "exercises": [
        {{
            "name": "Exercise name",
            "movement_pattern": "upper_push|upper_pull|lower_body|core",
            "sets": 3,
            "target_reps": 10,
            "lighter_weight_kg": 5,
            "standard_weight_kg": 10,
            "heavier_weight_kg": 15,
            "rest_seconds": 60,
            "equipment": "equipment used",
            "muscle_group": "primary muscle targeted",
            "is_compound": true,
            "notes": "Form tips and what to observe"
        }}
    ],
    "instructions": [
        "Start with the standard weight recommendation",
        "If the weight feels easy (RPE <6), try the heavier option",
        "If the weight feels hard (RPE >8), use the lighter option",
        "Record your actual weights and reps for each set"
    ],
    "what_were_testing": [
        "Upper body pushing strength (chest, shoulders)",
        "Upper body pulling strength (back, biceps)",
        "Lower body strength (legs, glutes)",
        "Core stability and endurance"
    ]
}}

IMPORTANT:
- Include exactly 5-6 exercises total covering all movement patterns
- Keep rest periods short (45-60 seconds) to complete in 15 minutes
- Weight recommendations should be realistic for {fitness_level} level
- Notes should help the user understand proper form and what to observe"""

        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=CalibrationWorkoutResponse,
                    max_output_tokens=4000,
                    temperature=0.3,  # Lower temperature for consistent, accurate recommendations
                ),
            )

            content = response.text.strip()
            workout_data = json.loads(content)

            # Validate structure
            if "exercises" not in workout_data or not workout_data["exercises"]:
                raise ValueError("Calibration workout missing exercises")

            # Add metadata
            workout_data["generated_at"] = datetime.utcnow().isoformat()
            workout_data["user_fitness_level"] = fitness_level
            workout_data["user_equipment"] = equipment

            logger.info(
                f"Generated calibration workout with {len(workout_data['exercises'])} exercises",
                extra={"exercise_count": len(workout_data["exercises"])}
            )

            return workout_data

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse calibration workout JSON: {e}")
            raise ValueError(f"AI returned invalid JSON: {e}")
        except Exception as e:
            logger.error(f"Calibration workout generation failed: {e}")
            raise

    async def analyze_calibration_results(
        self,
        user_id: str,
        results: CalibrationResult,
        user_data: dict
    ) -> CalibrationAnalysis:
        """
        Analyze completed calibration workout results using AI.

        Args:
            user_id: User's ID
            results: The completed calibration results
            user_data: User's profile data including self-reported fitness level

        Returns:
            CalibrationAnalysis with insights and recommendations
        """
        reported_level = user_data.get("fitness_level", "beginner")
        gender = user_data.get("gender", "male").lower()
        age = user_data.get("age", 30)

        # Build exercise performance summary for the prompt
        exercise_summaries = []
        for ex in results.exercises:
            weight_vs_suggested = "same as" if abs(ex.weight_used_kg - ex.suggested_weight_kg) < 0.5 else \
                                  "higher than" if ex.weight_used_kg > ex.suggested_weight_kg else \
                                  "lower than"

            reps_vs_target = "met target" if ex.reps_completed >= ex.target_reps else \
                             f"fell short by {ex.target_reps - ex.reps_completed} reps"

            exercise_summaries.append(
                f"- {ex.name} ({ex.movement_pattern}): "
                f"Used {ex.weight_used_kg}kg ({weight_vs_suggested} suggested {ex.suggested_weight_kg}kg), "
                f"Completed {ex.reps_completed}/{ex.target_reps} reps ({reps_vs_target}), "
                f"Sets: {ex.sets_completed}/{ex.target_sets}, "
                f"Difficulty: {ex.perceived_difficulty}/10"
            )

        newline = chr(10)
        prompt = f"""Analyze this calibration workout to assess the user's actual fitness level.

USER PROFILE:
- Self-reported fitness level: {reported_level}
- Gender: {gender}
- Age: {age}

CALIBRATION RESULTS:
{newline.join(exercise_summaries)}

Overall workout perceived difficulty: {results.overall_perceived_difficulty}/10
Total duration: {results.total_duration_seconds // 60} minutes
User comments: {results.user_comments or "None provided"}

EXPECTED BENCHMARKS BY FITNESS LEVEL:
- Beginner: Uses lighter weights, struggles to complete full sets, RPE 7-9
- Intermediate: Uses moderate weights, completes most sets, RPE 6-8
- Advanced: Uses heavier weights, completes all sets easily, RPE 5-7

Analyze the results and determine:
1. Does the user's performance match their self-reported "{reported_level}" level?
2. What fitness level do their results actually suggest?
3. What are the strengths and weaknesses across movement patterns?

Return ONLY valid JSON:
{{
    "reported_fitness_level": "{reported_level}",
    "assessed_fitness_level": "beginner|intermediate|advanced",
    "confidence_score": 0.85,
    "level_match": true,
    "insights": [
        "Insight 1 about their performance",
        "Insight 2 about specific movement patterns"
    ],
    "strength_assessment": {{
        "upper_push": "strong|average|needs_work",
        "upper_pull": "strong|average|needs_work",
        "lower_body": "strong|average|needs_work",
        "core": "strong|average|needs_work"
    }},
    "performance_summary": "A 2-3 sentence summary of overall performance",
    "recommendations": [
        "Specific recommendation 1",
        "Specific recommendation 2"
    ]
}}"""

        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=PerformanceAnalysisResponse,
                    max_output_tokens=2000,
                    temperature=0.2,  # Very low for consistent analysis
                ),
            )

            content = response.text.strip()
            analysis_data = json.loads(content)

            analysis = CalibrationAnalysis(
                reported_fitness_level=analysis_data.get("reported_fitness_level", reported_level),
                assessed_fitness_level=analysis_data.get("assessed_fitness_level", reported_level),
                confidence_score=analysis_data.get("confidence_score", 0.5),
                level_match=analysis_data.get("level_match", True),
                insights=analysis_data.get("insights", []),
                strength_assessment=analysis_data.get("strength_assessment", {}),
                performance_summary=analysis_data.get("performance_summary", ""),
                recommendations=analysis_data.get("recommendations", []),
            )

            logger.info(
                f"Calibration analysis complete for user {user_id}",
                extra={
                    "user_id": user_id,
                    "reported_level": reported_level,
                    "assessed_level": analysis.assessed_fitness_level,
                    "level_match": analysis.level_match,
                    "confidence": analysis.confidence_score,
                }
            )

            return analysis

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse calibration analysis JSON: {e}")
            raise ValueError(f"AI returned invalid JSON: {e}")
        except Exception as e:
            logger.error(f"Calibration analysis failed: {e}")
            raise

    def calculate_strength_baselines(
        self,
        exercises: List[CalibrationExercise]
    ) -> List[StrengthBaseline]:
        """
        Calculate estimated 1RM for each exercise using Brzycki formula.

        Args:
            exercises: List of completed calibration exercises

        Returns:
            List of StrengthBaseline records with estimated 1RM values
        """
        baselines = []

        for ex in exercises:
            if ex.weight_used_kg <= 0 or ex.reps_completed <= 0:
                continue

            # Calculate 1RM using Brzycki formula
            estimated_1rm = calculate_1rm_brzycki(ex.weight_used_kg, ex.reps_completed)

            # Validate the estimate - should be reasonable
            if estimated_1rm > 0 and estimated_1rm < 500:  # Sanity check
                baseline = StrengthBaseline(
                    exercise_name=ex.name,
                    movement_pattern=ex.movement_pattern,
                    weight_kg=ex.weight_used_kg,
                    reps=ex.reps_completed,
                    estimated_1rm_kg=round(estimated_1rm, 1),
                    muscle_group=ex.muscle_group,
                )
                baselines.append(baseline)

                logger.debug(
                    f"Calculated baseline for {ex.name}: {ex.weight_used_kg}kg x {ex.reps_completed} = {round(estimated_1rm, 1)}kg 1RM"
                )

        logger.info(f"Calculated {len(baselines)} strength baselines")
        return baselines

    def suggest_adjustments(
        self,
        analysis: CalibrationAnalysis
    ) -> CalibrationSuggestedAdjustments:
        """
        Generate suggested profile adjustments based on calibration analysis.

        Args:
            analysis: The calibration analysis results

        Returns:
            CalibrationSuggestedAdjustments with specific recommendations
        """
        should_prompt = not analysis.level_match
        suggested_level = None
        suggested_intensity = None
        weight_multipliers = {}

        # Determine if we need to adjust fitness level
        if not analysis.level_match:
            suggested_level = analysis.assessed_fitness_level

        # Calculate weight multipliers based on strength assessment
        for pattern, assessment in analysis.strength_assessment.items():
            if assessment == "strong":
                weight_multipliers[pattern] = 1.15  # 15% increase
            elif assessment == "needs_work":
                weight_multipliers[pattern] = 0.85  # 15% decrease
            else:
                weight_multipliers[pattern] = 1.0  # No change

        # Determine intensity adjustment
        if analysis.confidence_score >= 0.7:
            if analysis.assessed_fitness_level == "advanced" and analysis.reported_fitness_level != "advanced":
                suggested_intensity = "hard"
            elif analysis.assessed_fitness_level == "beginner" and analysis.reported_fitness_level != "beginner":
                suggested_intensity = "easy"

        # Build user-friendly message
        if analysis.level_match:
            message = "Great news! Your performance matches your self-assessment. Your workouts will be calibrated perfectly for your fitness level."
        else:
            if analysis.assessed_fitness_level > analysis.reported_fitness_level:
                message = (
                    f"Impressive! Based on your calibration workout, you're performing at a "
                    f"{analysis.assessed_fitness_level} level - higher than your self-assessment. "
                    f"Would you like us to adjust your workouts to be more challenging?"
                )
            else:
                message = (
                    f"Based on your calibration workout, we recommend starting at the "
                    f"{analysis.assessed_fitness_level} level. This will help you build a strong "
                    f"foundation and reduce injury risk. Would you like us to adjust your settings?"
                )

        # Build detailed explanation
        detailed_parts = [analysis.performance_summary]

        for insight in analysis.insights[:3]:  # Top 3 insights
            detailed_parts.append(f"- {insight}")

        if analysis.recommendations:
            detailed_parts.append("\nRecommendations:")
            for rec in analysis.recommendations[:3]:  # Top 3 recommendations
                detailed_parts.append(f"- {rec}")

        detailed_explanation = "\n".join(detailed_parts)

        adjustments = CalibrationSuggestedAdjustments(
            suggested_fitness_level=suggested_level,
            suggested_intensity=suggested_intensity,
            weight_multipliers=weight_multipliers,
            message=message,
            detailed_explanation=detailed_explanation,
            should_prompt_user=should_prompt,
        )

        logger.info(
            "Generated calibration adjustments",
            extra={
                "should_prompt": should_prompt,
                "suggested_level": suggested_level,
                "suggested_intensity": suggested_intensity,
            }
        )

        return adjustments

    async def apply_adjustments(
        self,
        user_id: str,
        adjustments: CalibrationSuggestedAdjustments,
        supabase
    ) -> bool:
        """
        Apply calibration adjustments to user's profile.

        Args:
            user_id: User's ID
            adjustments: The suggested adjustments to apply
            supabase: Supabase client instance

        Returns:
            True if adjustments were applied successfully
        """
        try:
            # Get current user data
            user_response = supabase.table("users").select("*").eq("id", user_id).single().execute()

            if not user_response.data:
                logger.error(f"User {user_id} not found for calibration adjustment")
                return False

            current_user = user_response.data

            # Store original fitness level before changes
            original_level = current_user.get("fitness_level")

            # Prepare update data
            update_data = {
                "calibration_completed": True,
                "calibration_completed_at": datetime.utcnow().isoformat(),
                "pre_calibration_fitness_level": original_level,
            }

            # Apply fitness level change if suggested
            if adjustments.suggested_fitness_level:
                update_data["fitness_level"] = adjustments.suggested_fitness_level
                logger.info(
                    f"Updating fitness level from {original_level} to {adjustments.suggested_fitness_level}",
                    extra={"user_id": user_id}
                )

            # Store weight multipliers for future workout generation
            if adjustments.weight_multipliers:
                update_data["calibration_weight_multipliers"] = json.dumps(adjustments.weight_multipliers)

            # Apply the update
            supabase.table("users").update(update_data).eq("id", user_id).execute()

            logger.info(
                f"Applied calibration adjustments for user {user_id}",
                extra={
                    "user_id": user_id,
                    "original_level": original_level,
                    "new_level": adjustments.suggested_fitness_level or original_level,
                }
            )

            return True

        except Exception as e:
            logger.error(f"Failed to apply calibration adjustments: {e}", extra={"user_id": user_id})
            return False

    async def get_calibration_status(
        self,
        user_id: str,
        supabase
    ) -> dict:
        """
        Get current calibration status for a user.

        Args:
            user_id: User's ID
            supabase: Supabase client instance

        Returns:
            Dict with calibration status including:
                - completed: bool
                - skipped: bool
                - pending: bool
                - completed_at: datetime or None
                - pre_calibration_level: str or None
                - current_level: str
        """
        try:
            user_response = supabase.table("users").select(
                "fitness_level",
                "calibration_completed",
                "calibration_completed_at",
                "calibration_skipped",
                "pre_calibration_fitness_level",
                "calibration_weight_multipliers"
            ).eq("id", user_id).single().execute()

            if not user_response.data:
                return {
                    "completed": False,
                    "skipped": False,
                    "pending": True,
                    "completed_at": None,
                    "pre_calibration_level": None,
                    "current_level": None,
                    "weight_multipliers": None,
                }

            data = user_response.data
            completed = data.get("calibration_completed", False)
            skipped = data.get("calibration_skipped", False)

            return {
                "completed": completed,
                "skipped": skipped,
                "pending": not completed and not skipped,
                "completed_at": data.get("calibration_completed_at"),
                "pre_calibration_level": data.get("pre_calibration_fitness_level"),
                "current_level": data.get("fitness_level"),
                "weight_multipliers": json.loads(data.get("calibration_weight_multipliers", "{}")) if data.get("calibration_weight_multipliers") else None,
            }

        except Exception as e:
            logger.error(f"Failed to get calibration status: {e}", extra={"user_id": user_id})
            return {
                "completed": False,
                "skipped": False,
                "pending": True,
                "completed_at": None,
                "pre_calibration_level": None,
                "current_level": None,
                "weight_multipliers": None,
                "error": str(e),
            }

    async def skip_calibration(
        self,
        user_id: str,
        supabase,
        reason: Optional[str] = None
    ) -> bool:
        """
        Mark calibration as skipped for a user.

        Args:
            user_id: User's ID
            supabase: Supabase client instance
            reason: Optional reason for skipping

        Returns:
            True if successfully marked as skipped
        """
        try:
            update_data = {
                "calibration_skipped": True,
                "calibration_skipped_at": datetime.utcnow().isoformat(),
            }

            if reason:
                update_data["calibration_skip_reason"] = reason

            supabase.table("users").update(update_data).eq("id", user_id).execute()

            logger.info(f"User {user_id} skipped calibration", extra={"user_id": user_id, "reason": reason})
            return True

        except Exception as e:
            logger.error(f"Failed to skip calibration: {e}", extra={"user_id": user_id})
            return False


# Singleton instance
_calibration_service: Optional[CalibrationWorkoutService] = None


def get_calibration_workout_service() -> CalibrationWorkoutService:
    """Get the CalibrationWorkoutService singleton instance."""
    global _calibration_service
    if _calibration_service is None:
        _calibration_service = CalibrationWorkoutService()
    return _calibration_service
