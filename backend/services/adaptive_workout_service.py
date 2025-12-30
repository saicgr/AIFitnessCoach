"""
Adaptive Workout Service - Calculates workout parameters based on user history.

This service analyzes user's recent workout performance to determine optimal:
- Sets per exercise
- Reps per exercise
- Rest time between sets
- Workout intensity

Key factors considered:
- Difficulty feedback from recent workouts (too easy, just right, too hard)
- Completion rate (did they finish all sets?)
- Time taken vs expected
- Recent PRs and volume trends
"""
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class AdaptiveWorkoutService:
    """Calculates adaptive workout parameters based on performance history."""

    # Workout structure templates based on training focus
    WORKOUT_STRUCTURES = {
        "strength": {
            "sets": (4, 5),      # 4-5 sets
            "reps": (4, 6),      # 4-6 reps
            "rest_seconds": (120, 180),  # 2-3 min rest
            "rpe_target": (8, 9),
            "description": "Heavy weight, lower reps for strength gains",
            "allow_supersets": False,  # Need full rest for strength
            "allow_amrap": False,
        },
        "hypertrophy": {
            "sets": (3, 4),      # 3-4 sets
            "reps": (8, 12),     # 8-12 reps
            "rest_seconds": (60, 90),   # 60-90 sec rest
            "rpe_target": (7, 8),
            "description": "Moderate weight, higher reps for muscle growth",
            "allow_supersets": True,   # Supersets work great for hypertrophy
            "allow_amrap": True,       # AMRAP finishers for extra pump
            "allow_drop_sets": True,   # Drop sets are excellent for hypertrophy
        },
        "endurance": {
            "sets": (2, 3),      # 2-3 sets
            "reps": (15, 20),    # 15-20 reps
            "rest_seconds": (30, 45),   # 30-45 sec rest
            "rpe_target": (6, 7),
            "description": "Lower weight, high reps for muscular endurance",
            "allow_supersets": True,   # Supersets keep heart rate up
            "allow_amrap": True,
            "allow_drop_sets": True,   # Drop sets work well for endurance
        },
        "power": {
            "sets": (5, 6),      # 5-6 sets
            "reps": (1, 3),      # 1-3 reps (explosive)
            "rest_seconds": (180, 300),  # 3-5 min rest
            "rpe_target": (9, 10),
            "description": "Maximum effort, very low reps for power",
            "allow_supersets": False,  # Need full recovery
            "allow_amrap": False,
        },
        "hiit": {
            "sets": (3, 4),
            "reps": (12, 15),
            "rest_seconds": (20, 30),   # Very short rest
            "rpe_target": (8, 9),
            "description": "High intensity interval training - minimal rest",
            "allow_supersets": True,   # Perfect for HIIT
            "allow_amrap": True,
        },
        "skill": {
            "sets": (3, 5),      # 3-5 quality sets
            "reps": (3, 5),      # Low reps, high quality
            "rest_seconds": (120, 180),  # Full recovery between attempts
            "rpe_target": (7, 8),
            "description": "Technique focus - quality over quantity, stop when form degrades",
            "allow_supersets": False,  # Need full focus per movement
            "allow_amrap": False,      # Skill work shouldn't be to failure
            "progression_type": "technique_first",
        },
        "plyometric": {
            "sets": (3, 4),      # 3-4 explosive sets
            "reps": (5, 8),      # Low-moderate reps to maintain explosiveness
            "rest_seconds": (90, 120),  # Adequate recovery for power output
            "rpe_target": (8, 9),
            "description": "Explosive movements for power development",
            "allow_supersets": False,  # Need explosive power each rep
            "allow_amrap": False,
        },
    }

    # Intensity modifier thresholds
    DIFFICULTY_ADJUSTMENTS = {
        "too_easy": {"intensity_modifier": "increase", "set_delta": 1, "rest_delta": -15},
        "just_right": {"intensity_modifier": "maintain", "set_delta": 0, "rest_delta": 0},
        "too_hard": {"intensity_modifier": "decrease", "set_delta": -1, "rest_delta": 15},
    }

    # Fitness level adjustments for sets/reps
    # Beginners need lower volume to build form and prevent injury
    # These multipliers are applied to the base workout structure values
    FITNESS_LEVEL_ADJUSTMENTS = {
        "beginner": {
            "sets_max": 3,       # Cap sets at 3 for beginners
            "reps_max": 12,      # Cap reps at 12 for beginners (form focus)
            "reps_min": 6,       # Floor reps at 6 (enough stimulus)
            "rest_increase": 30,  # Add extra rest time (seconds)
            "description": "Reduced volume for form mastery and injury prevention",
        },
        "intermediate": {
            "sets_max": 5,       # Can handle more volume
            "reps_max": 15,      # Moderate rep ceiling
            "reps_min": 4,       # Can go heavier with lower reps
            "rest_increase": 0,   # Standard rest
            "description": "Standard workout parameters",
        },
        "advanced": {
            "sets_max": 8,       # High volume capability
            "reps_max": 20,      # Full rep range
            "reps_min": 1,       # Can do power singles
            "rest_increase": 0,   # Can handle shorter rest
            "description": "No restrictions - full parameter range",
        },
    }

    def __init__(self, supabase_client=None):
        self.supabase = supabase_client

    def _map_focus_to_workout_type(self, focus: str, user_goals: List[str] = None) -> str:
        """
        Map workout focus areas to workout structure types based on goals.

        Focus areas: full_body, upper, lower, push, pull, legs, chest, back, shoulders, arms, core
        Workout types: strength, hypertrophy, endurance, power, hiit, skill, plyometric
        """
        user_goals = user_goals or []
        goals_lower = [g.lower() for g in user_goals]

        # Direct mappings for specific workout types
        if focus in ["strength", "hypertrophy", "endurance", "power", "hiit", "skill", "plyometric"]:
            return focus

        # Map based on user goals (check skill-based goals first)
        if any(g in goals_lower for g in ["skill", "technique", "form", "learn", "progression"]):
            return "skill"
        if any(g in goals_lower for g in ["plyometric", "jump", "explosive power", "vertical leap", "box jump"]):
            return "plyometric"
        if any(g in goals_lower for g in ["strength", "increase strength", "build strength", "get stronger"]):
            return "strength"
        if any(g in goals_lower for g in ["muscle", "muscle_gain", "build muscle", "hypertrophy", "get bigger"]):
            return "hypertrophy"
        if any(g in goals_lower for g in ["endurance", "stamina", "cardio", "lose weight", "weight_loss", "fat loss"]):
            return "endurance"
        if any(g in goals_lower for g in ["power", "explosive", "athletic", "sports"]):
            return "power"
        if any(g in goals_lower for g in ["hiit", "burn calories", "metabolic"]):
            return "hiit"

        # Default to hypertrophy for most workout focuses (balanced approach)
        return "hypertrophy"

    async def get_adaptive_parameters(
        self,
        user_id: str,
        workout_type: str = "hypertrophy",
        user_goals: List[str] = None,
        recent_difficulty: str = None,
        fitness_level: str = None,
    ) -> Dict[str, Any]:
        """
        Calculate recommended workout parameters based on user history.

        Args:
            user_id: The user's ID
            workout_type: Type of workout OR focus area (full_body, upper, push, etc.)
            user_goals: User's fitness goals (muscle_gain, strength, endurance, weight_loss)
            recent_difficulty: Last workout's difficulty feedback
            fitness_level: User's fitness level (beginner, intermediate, advanced)

        Returns:
            Dict with recommended sets, reps, rest_seconds, intensity_modifier, rpe_target
        """
        # Map focus area to workout structure type if needed
        effective_workout_type = self._map_focus_to_workout_type(workout_type, user_goals)

        # Get base parameters from workout structure
        structure = self.WORKOUT_STRUCTURES.get(effective_workout_type, self.WORKOUT_STRUCTURES["hypertrophy"])

        # Start with mid-range values
        base_sets = (structure["sets"][0] + structure["sets"][1]) // 2
        base_reps = (structure["reps"][0] + structure["reps"][1]) // 2
        base_rest = (structure["rest_seconds"][0] + structure["rest_seconds"][1]) // 2
        base_rpe = (structure["rpe_target"][0] + structure["rpe_target"][1]) / 2

        # Get performance context if we have DB access
        performance_context = {}
        if self.supabase:
            performance_context = await self.get_performance_context(user_id)

        # Apply adjustments based on difficulty feedback
        intensity_modifier = "maintain"
        reasoning = []

        if recent_difficulty:
            adjustment = self.DIFFICULTY_ADJUSTMENTS.get(recent_difficulty, {})
            intensity_modifier = adjustment.get("intensity_modifier", "maintain")
            base_sets = max(2, base_sets + adjustment.get("set_delta", 0))
            base_rest = max(30, base_rest + adjustment.get("rest_delta", 0))

            if recent_difficulty == "too_easy":
                reasoning.append("Increasing intensity based on recent feedback")
            elif recent_difficulty == "too_hard":
                reasoning.append("Decreasing intensity based on recent feedback")

        # Apply adjustments from performance context
        if performance_context:
            # Check average completion rate
            avg_completion = performance_context.get("avg_completion_rate", 100)
            if avg_completion < 80:
                base_sets = max(2, base_sets - 1)
                base_rest = min(180, base_rest + 15)
                intensity_modifier = "decrease"
                reasoning.append(f"Reduced volume due to {avg_completion:.0f}% completion rate")

            # Check time efficiency
            avg_time_ratio = performance_context.get("avg_time_ratio", 1.0)
            if avg_time_ratio > 1.3:  # Taking 30% longer than expected
                reasoning.append("User takes longer than expected - consider shorter workouts")
            elif avg_time_ratio < 0.7:  # Finishing 30% faster
                if intensity_modifier != "decrease":
                    base_sets = min(structure["sets"][1], base_sets + 1)
                    reasoning.append("User finishes quickly - can handle more volume")

            # Check for recent PRs
            recent_prs = performance_context.get("recent_prs", 0)
            if recent_prs > 0:
                reasoning.append(f"Great progress! {recent_prs} PR(s) this week")

            # Check for potential deload
            if performance_context.get("needs_deload", False):
                base_sets = max(2, structure["sets"][0])
                base_reps = structure["reps"][1]  # Higher reps
                base_rest = structure["rest_seconds"][1]  # More rest
                intensity_modifier = "decrease"
                reasoning.append("Deload recommended - reducing volume")

        # Add reasoning for the chosen workout type
        if effective_workout_type != workout_type:
            reasoning.append(f"Mapped '{workout_type}' focus to '{effective_workout_type}' structure based on goals")

        # Apply fitness level adjustments (CRITICAL for beginners)
        # This prevents beginners from getting 4+ sets and 15-20 reps which is too much
        if fitness_level:
            level_key = fitness_level.lower()
            level_adj = self.FITNESS_LEVEL_ADJUSTMENTS.get(level_key, self.FITNESS_LEVEL_ADJUSTMENTS["intermediate"])

            original_sets = base_sets
            original_reps = base_reps
            original_rest = base_rest

            # Cap sets at fitness level maximum
            base_sets = min(base_sets, level_adj["sets_max"])

            # Clamp reps within fitness level range
            base_reps = max(level_adj["reps_min"], min(base_reps, level_adj["reps_max"]))

            # Add extra rest for beginners
            base_rest = base_rest + level_adj["rest_increase"]

            # Log the adjustment
            if original_sets != base_sets or original_reps != base_reps:
                logger.info(
                    f"[Adaptive] Adjusted for {fitness_level}: "
                    f"sets {original_sets}->{base_sets}, reps {original_reps}->{base_reps}, "
                    f"rest {original_rest}->{base_rest}s ({level_adj['description']})"
                )
                reasoning.append(f"Adjusted for {fitness_level} level: {level_adj['description']}")

        return {
            "sets": base_sets,
            "reps": base_reps,
            "rest_seconds": base_rest,
            "rpe_target": base_rpe,
            "intensity_modifier": intensity_modifier,
            "workout_focus": effective_workout_type,  # Use the mapped workout type
            "original_focus": workout_type,  # Keep original for reference
            "fitness_level": fitness_level,  # Include for context
            "reasoning": reasoning if reasoning else ["Standard parameters for your fitness level"],
            "structure_description": structure.get("description", ""),
            "allow_supersets": structure.get("allow_supersets", False),
            "allow_amrap": structure.get("allow_amrap", False),
        }

    async def get_performance_context(self, user_id: str) -> Dict[str, Any]:
        """
        Fetch recent workout performance data from the database.

        Returns:
            Dict containing:
            - avg_completion_rate: Average % of sets completed
            - avg_difficulty: Average difficulty rating
            - avg_time_ratio: Actual time / expected time
            - recent_prs: Number of PRs in last 7 days
            - workouts_completed: Number of workouts in last 7 days
            - needs_deload: Boolean if deload is recommended
        """
        if not self.supabase:
            return {}

        try:
            # Get recent workout logs (last 2 weeks)
            # Note: metadata column may not exist in all deployments
            two_weeks_ago = (datetime.now() - timedelta(days=14)).isoformat()

            # Note: workout_logs table uses 'completed_at', not 'created_at'
            logs_response = self.supabase.table("workout_logs").select(
                "id, total_time_seconds, completed_at"
            ).eq("user_id", user_id).gte("completed_at", two_weeks_ago).execute()

            logs = logs_response.data if logs_response.data else []

            if not logs:
                return {"workouts_completed": 0}

            # Calculate metrics based on available data
            # Since metadata column may not exist, we use simpler heuristics
            completion_rates = []
            time_ratios = []
            difficulty_ratings = []

            for log in logs:
                # Use total_time_seconds as a basic metric
                actual_time = log.get("total_time_seconds", 0)
                if actual_time > 0:
                    # Assume 45 min (2700s) as expected duration if not specified
                    expected_time = 2700
                    time_ratios.append(actual_time / expected_time)

            # Get recent PRs
            week_ago = (datetime.now() - timedelta(days=7)).isoformat()
            prs_response = self.supabase.table("strength_records").select(
                "id"
            ).eq("user_id", user_id).eq("is_pr", True).gte("achieved_at", week_ago).execute()

            recent_prs = len(prs_response.data) if prs_response.data else 0

            # Determine if deload is needed
            needs_deload = False
            avg_difficulty = sum(difficulty_ratings) / len(difficulty_ratings) if difficulty_ratings else 2
            if avg_difficulty > 2.5 and len(logs) >= 4:  # Consistently too hard
                needs_deload = True
            if len(completion_rates) >= 3 and sum(completion_rates) / len(completion_rates) < 70:
                needs_deload = True

            return {
                "workouts_completed": len(logs),
                "avg_completion_rate": sum(completion_rates) / len(completion_rates) if completion_rates else 100,
                "avg_time_ratio": sum(time_ratios) / len(time_ratios) if time_ratios else 1.0,
                "avg_difficulty": avg_difficulty,
                "recent_prs": recent_prs,
                "needs_deload": needs_deload,
            }

        except Exception as e:
            logger.error(f"Error fetching performance context: {e}")
            return {}

    async def get_exercise_stats(self, user_id: str, exercise_name: str = None) -> Dict[str, Any]:
        """
        Fetch per-exercise performance stats from performance_logs.

        Args:
            user_id: The user's ID
            exercise_name: Optional specific exercise name to get stats for.
                           If None, returns stats for all exercises.

        Returns:
            Dict containing:
            - total_sets: Total sets logged
            - total_volume: Total volume (weight * reps) in kg
            - max_weight: Maximum weight used
            - max_reps: Maximum reps in a single set
            - estimated_1rm: Estimated 1RM using Brzycki formula
            - avg_rpe: Average RPE across all sets
            - last_workout_date: Most recent log date
            - progression: Dict with weight/reps trend (increasing, stable, decreasing)
        """
        if not self.supabase:
            return {}

        try:
            # Query performance_logs for this user
            query = self.supabase.table("performance_logs").select(
                "exercise_name, weight_kg, reps_completed, set_type, rpe, logged_at"
            ).eq("user_id", user_id)

            if exercise_name:
                query = query.ilike("exercise_name", exercise_name)

            # Get last 90 days of data for progression analysis
            ninety_days_ago = (datetime.now() - timedelta(days=90)).isoformat()
            query = query.gte("logged_at", ninety_days_ago).order("logged_at", desc=True)

            response = query.execute()
            logs = response.data if response.data else []

            if not logs:
                return {
                    "total_sets": 0,
                    "has_data": False,
                    "message": "No performance data yet" if exercise_name else "No exercises logged yet"
                }

            # Group by exercise if no specific exercise requested
            if not exercise_name:
                return await self._aggregate_all_exercise_stats(logs)

            # Calculate stats for specific exercise
            return self._calculate_exercise_stats(logs)

        except Exception as e:
            logger.error(f"Error fetching exercise stats: {e}")
            return {"error": str(e)}

    def _calculate_exercise_stats(self, logs: List[Dict]) -> Dict[str, Any]:
        """Calculate stats for a single exercise from logs."""
        if not logs:
            return {"total_sets": 0, "has_data": False}

        total_sets = len(logs)
        weights = [l.get("weight_kg", 0) or 0 for l in logs if l.get("weight_kg")]
        reps = [l.get("reps_completed", 0) or 0 for l in logs if l.get("reps_completed")]
        rpes = [l.get("rpe", 0) for l in logs if l.get("rpe")]

        max_weight = max(weights) if weights else 0
        max_reps = max(reps) if reps else 0
        avg_rpe = sum(rpes) / len(rpes) if rpes else None

        # Calculate total volume (sum of weight * reps)
        total_volume = sum(
            (l.get("weight_kg", 0) or 0) * (l.get("reps_completed", 0) or 0)
            for l in logs
        )

        # Estimate 1RM using Brzycki formula from best set
        estimated_1rm = 0
        for log in logs:
            w = log.get("weight_kg", 0) or 0
            r = log.get("reps_completed", 0) or 0
            if w > 0 and r > 0 and r <= 15:  # Formula works best under 15 reps
                e1rm = w * (36 / (37 - r))
                if e1rm > estimated_1rm:
                    estimated_1rm = e1rm

        # Calculate progression trend (last 4 weeks vs previous 4 weeks)
        progression = self._calculate_progression(logs)

        # Most recent date
        last_workout_date = logs[0].get("logged_at") if logs else None

        return {
            "total_sets": total_sets,
            "total_volume": round(total_volume, 1),
            "max_weight": round(max_weight, 1),
            "max_reps": max_reps,
            "estimated_1rm": round(estimated_1rm, 1) if estimated_1rm > 0 else None,
            "avg_rpe": round(avg_rpe, 1) if avg_rpe else None,
            "last_workout_date": last_workout_date,
            "progression": progression,
            "has_data": True,
        }

    def _calculate_progression(self, logs: List[Dict]) -> Dict[str, str]:
        """
        Calculate if user is progressing, stable, or regressing.

        Compares average weight/volume from last 4 weeks vs previous 4 weeks.
        """
        if len(logs) < 4:
            return {"trend": "insufficient_data", "message": "Need more data"}

        # Split logs into recent (last 4 weeks) and previous (4-8 weeks ago)
        four_weeks_ago = datetime.now() - timedelta(days=28)
        eight_weeks_ago = datetime.now() - timedelta(days=56)

        recent_logs = []
        previous_logs = []

        for log in logs:
            logged_at = log.get("logged_at", "")
            if logged_at:
                try:
                    log_date = datetime.fromisoformat(logged_at.replace("Z", "+00:00"))
                    if log_date.replace(tzinfo=None) > four_weeks_ago:
                        recent_logs.append(log)
                    elif log_date.replace(tzinfo=None) > eight_weeks_ago:
                        previous_logs.append(log)
                except (ValueError, AttributeError):
                    pass

        if not recent_logs or not previous_logs:
            return {"trend": "insufficient_data", "message": "Need data from multiple weeks"}

        # Calculate average weight for each period
        recent_avg_weight = sum(l.get("weight_kg", 0) or 0 for l in recent_logs) / len(recent_logs)
        previous_avg_weight = sum(l.get("weight_kg", 0) or 0 for l in previous_logs) / len(previous_logs)

        # Determine trend
        if previous_avg_weight > 0:
            change_percent = ((recent_avg_weight - previous_avg_weight) / previous_avg_weight) * 100

            if change_percent > 5:
                return {
                    "trend": "increasing",
                    "change_percent": round(change_percent, 1),
                    "message": f"Weight increased {round(change_percent, 1)}% over 4 weeks"
                }
            elif change_percent < -5:
                return {
                    "trend": "decreasing",
                    "change_percent": round(change_percent, 1),
                    "message": f"Weight decreased {abs(round(change_percent, 1))}% over 4 weeks"
                }
            else:
                return {
                    "trend": "stable",
                    "change_percent": round(change_percent, 1),
                    "message": "Weights have been stable"
                }

        return {"trend": "unknown", "message": "Unable to calculate trend"}

    async def _aggregate_all_exercise_stats(self, logs: List[Dict]) -> Dict[str, Any]:
        """Aggregate stats grouped by exercise name."""
        exercises = {}

        for log in logs:
            name = log.get("exercise_name", "Unknown")
            if name not in exercises:
                exercises[name] = []
            exercises[name].append(log)

        # Calculate stats for each exercise
        result = {}
        for name, ex_logs in exercises.items():
            result[name] = self._calculate_exercise_stats(ex_logs)

        return {
            "exercises": result,
            "total_exercises_tracked": len(exercises),
            "total_sets_all": len(logs),
            "has_data": True,
        }

    async def get_user_exercise_history(
        self,
        user_id: str,
        limit: int = 20,
    ) -> List[Dict[str, Any]]:
        """
        Get a summary of user's exercise history with stats for each exercise.

        Args:
            user_id: The user's ID
            limit: Maximum number of exercises to return

        Returns:
            List of exercise summaries with stats
        """
        if not self.supabase:
            return []

        try:
            # Get distinct exercises with stats
            all_stats = await self.get_exercise_stats(user_id)

            if not all_stats.get("has_data"):
                return []

            exercises = all_stats.get("exercises", {})

            # Convert to sorted list by total sets (most performed first)
            exercise_list = [
                {"exercise_name": name, **stats}
                for name, stats in exercises.items()
            ]

            exercise_list.sort(key=lambda x: x.get("total_sets", 0), reverse=True)

            return exercise_list[:limit]

        except Exception as e:
            logger.error(f"Error fetching exercise history: {e}")
            return []

    def _determine_focus(
        self,
        user_goals: List[str] = None,
        performance_context: Dict[str, Any] = None,
    ) -> str:
        """
        Determine workout focus based on user goals and recent training.

        Uses undulating periodization - varies focus based on recent history.
        """
        if not user_goals:
            return "hypertrophy"

        # Map goals to workout focus
        goal_to_focus = {
            "muscle_gain": "hypertrophy",
            "build_muscle": "hypertrophy",
            "strength": "strength",
            "get_stronger": "strength",
            "weight_loss": "endurance",
            "lose_weight": "endurance",
            "endurance": "endurance",
            "athletic": "power",
            "sport_performance": "power",
            "general_fitness": "hypertrophy",
        }

        # Find primary focus from goals
        primary_focus = "hypertrophy"
        for goal in user_goals:
            goal_lower = goal.lower().replace(" ", "_")
            if goal_lower in goal_to_focus:
                primary_focus = goal_to_focus[goal_lower]
                break

        # For undulating periodization, vary the focus
        # If user has been doing a lot of one type, switch it up
        if performance_context and performance_context.get("workouts_completed", 0) > 0:
            workouts_this_week = performance_context.get("workouts_completed", 0)

            # Every 3rd workout, switch focus for variety
            if workouts_this_week % 3 == 0:
                focus_rotation = {
                    "hypertrophy": "strength",
                    "strength": "hypertrophy",
                    "endurance": "hypertrophy",
                    "power": "strength",
                }
                return focus_rotation.get(primary_focus, primary_focus)

        return primary_focus

    def get_varied_rest_time(
        self,
        exercise_type: str,
        workout_focus: str,
    ) -> int:
        """
        Get appropriate rest time based on exercise type and workout focus.

        Args:
            exercise_type: 'compound' or 'isolation'
            workout_focus: 'strength', 'hypertrophy', 'endurance', 'power'

        Returns:
            Rest time in seconds
        """
        structure = self.WORKOUT_STRUCTURES.get(workout_focus, self.WORKOUT_STRUCTURES["hypertrophy"])
        base_rest = (structure["rest_seconds"][0] + structure["rest_seconds"][1]) // 2

        # Compound exercises need more rest
        if exercise_type == "compound":
            return min(300, base_rest + 30)

        # Isolation exercises need less rest
        return max(30, base_rest - 15)

    def should_use_supersets(
        self,
        workout_focus: str,
        duration_minutes: int,
        exercise_count: int,
    ) -> bool:
        """
        Determine if supersets should be used in this workout.

        Supersets are good for:
        - Hypertrophy workouts
        - Time-efficient workouts
        - Higher volume with less rest

        Args:
            workout_focus: The type of workout
            duration_minutes: Target duration
            exercise_count: Number of exercises

        Returns:
            True if supersets should be included
        """
        structure = self.WORKOUT_STRUCTURES.get(workout_focus, self.WORKOUT_STRUCTURES["hypertrophy"])

        if not structure.get("allow_supersets", False):
            return False

        # Use supersets when:
        # 1. We have enough exercises to pair (at least 4)
        # 2. Duration is moderate (15-45 min) where time efficiency matters
        # 3. Focus allows for it
        return exercise_count >= 4 and 15 <= duration_minutes <= 45

    def should_include_amrap(
        self,
        workout_focus: str,
        user_fitness_level: str = "intermediate",
    ) -> bool:
        """
        Determine if an AMRAP finisher should be included.

        AMRAP (As Many Reps As Possible) is great for:
        - Pushing limits safely
        - Metabolic conditioning
        - Building mental toughness

        Args:
            workout_focus: The type of workout
            user_fitness_level: User's fitness level

        Returns:
            True if AMRAP should be included
        """
        structure = self.WORKOUT_STRUCTURES.get(workout_focus, self.WORKOUT_STRUCTURES["hypertrophy"])

        if not structure.get("allow_amrap", False):
            return False

        # Include AMRAP for intermediate and above
        # Beginners should focus on form and consistent reps first
        return user_fitness_level in ["intermediate", "advanced"]

    def create_superset_pairs(
        self,
        exercises: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """
        Group exercises into supersets based on muscle group antagonism.

        Pairs:
        - Chest/Back
        - Biceps/Triceps
        - Quads/Hamstrings
        - Anterior deltoids/Posterior deltoids

        Args:
            exercises: List of exercises to potentially pair

        Returns:
            Exercises with superset_group assignments
        """
        if len(exercises) < 2:
            return exercises

        # Antagonist muscle group pairs
        antagonist_pairs = {
            "chest": ["back", "lats"],
            "back": ["chest", "pectorals"],
            "lats": ["chest", "pectorals"],
            "biceps": ["triceps"],
            "triceps": ["biceps"],
            "quadriceps": ["hamstrings", "glutes"],
            "hamstrings": ["quadriceps"],
            "shoulders": ["back"],  # Front/rear delts
        }

        superset_group = 1
        assigned = set()
        result = []

        for i, ex in enumerate(exercises):
            if i in assigned:
                continue

            muscle = ex.get("muscle_group", "").lower()
            ex_copy = ex.copy()

            # Try to find a pair
            paired = False
            for j, other in enumerate(exercises):
                if j <= i or j in assigned:
                    continue

                other_muscle = other.get("muscle_group", "").lower()

                # Check if they're antagonist pairs
                if other_muscle in antagonist_pairs.get(muscle, []):
                    # Found a pair!
                    ex_copy["superset_group"] = superset_group
                    ex_copy["superset_order"] = 1

                    other_copy = other.copy()
                    other_copy["superset_group"] = superset_group
                    other_copy["superset_order"] = 2
                    other_copy["rest_seconds"] = 0  # No rest between superset exercises

                    result.append(ex_copy)
                    result.append(other_copy)
                    assigned.add(i)
                    assigned.add(j)
                    superset_group += 1
                    paired = True
                    break

            if not paired:
                result.append(ex_copy)
                assigned.add(i)

        return result

    def create_amrap_finisher(
        self,
        workout_exercises: List[Dict[str, Any]],
        workout_focus: str,
    ) -> Dict[str, Any]:
        """
        Create an AMRAP finisher exercise based on the workout.

        Args:
            workout_exercises: The exercises in the workout
            workout_focus: Type of workout

        Returns:
            AMRAP exercise dict
        """
        # Choose a suitable exercise for AMRAP based on workout type
        amrap_exercises = {
            "hypertrophy": ["Push-Ups", "Pull-Ups", "Dips", "Bodyweight Squats"],
            "endurance": ["Burpees", "Mountain Climbers", "Jumping Jacks", "High Knees"],
            "hiit": ["Burpees", "Box Jumps", "Kettlebell Swings", "Battle Ropes"],
        }

        options = amrap_exercises.get(workout_focus, amrap_exercises["hypertrophy"])

        # Pick one that's not already in the workout
        existing_names = [e.get("name", "").lower() for e in workout_exercises]
        selected = None
        for option in options:
            if option.lower() not in existing_names:
                selected = option
                break

        if not selected:
            selected = options[0]

        return {
            "name": selected,
            "sets": 1,
            "reps": 0,  # AMRAP - no fixed reps
            "is_amrap": True,
            "duration_seconds": 60,  # 1 minute AMRAP
            "rest_seconds": 0,
            "muscle_group": "Full Body",
            "equipment": "Bodyweight",
            "notes": "AMRAP - As Many Reps As Possible in 60 seconds. Push yourself!",
        }

    def should_use_drop_sets(
        self,
        workout_focus: str,
        user_fitness_level: str,
    ) -> bool:
        """
        Determine if drop sets should be used in this workout.

        Drop sets are good for:
        - Hypertrophy workouts (muscle building)
        - Endurance workouts (muscular endurance)
        - Intermediate and advanced users

        Args:
            workout_focus: The type of workout
            user_fitness_level: User's fitness level

        Returns:
            True if drop sets should be included
        """
        structure = self.WORKOUT_STRUCTURES.get(workout_focus, self.WORKOUT_STRUCTURES["hypertrophy"])

        if not structure.get("allow_drop_sets", False):
            return False

        # Only for intermediate and advanced users
        # Beginners should focus on form and consistent technique first
        return user_fitness_level in ["intermediate", "advanced"]

    def add_drop_sets_to_exercise(
        self,
        exercise: Dict[str, Any],
        drop_set_count: int = 2,
        drop_percentage: int = 20,
    ) -> Dict[str, Any]:
        """
        Configure an exercise to use drop sets.

        Drop sets involve:
        - Performing a set to near failure
        - Immediately reducing weight by a percentage
        - Continuing without rest for additional reps

        Args:
            exercise: The exercise dict to modify
            drop_set_count: Number of drop sets (typically 2-3)
            drop_percentage: Percentage to reduce weight each drop (typically 20-25%)

        Returns:
            Modified exercise dict with drop set configuration
        """
        exercise_copy = exercise.copy()
        exercise_copy["is_drop_set"] = True
        exercise_copy["drop_set_count"] = drop_set_count
        exercise_copy["drop_set_percentage"] = drop_percentage
        exercise_copy["notes"] = (
            f"Drop Set: Complete main set, then immediately reduce weight by {drop_percentage}% "
            f"and continue for {drop_set_count} more drops. No rest between drops."
        )
        return exercise_copy

    def apply_drop_sets_to_workout(
        self,
        exercises: List[Dict[str, Any]],
        workout_focus: str,
        user_fitness_level: str,
        max_drop_set_exercises: int = 2,
    ) -> List[Dict[str, Any]]:
        """
        Apply drop sets to suitable exercises in a workout.

        Best exercises for drop sets:
        - Isolation exercises (curls, extensions, flyes)
        - Machine exercises (easy to change weight)
        - Cable exercises

        Exercises to avoid for drop sets:
        - Compound barbell exercises (squats, deadlifts)
        - Power movements
        - Exercises requiring spotters

        Args:
            exercises: List of exercises in the workout
            workout_focus: Type of workout
            user_fitness_level: User's fitness level
            max_drop_set_exercises: Maximum number of exercises to apply drop sets to

        Returns:
            Modified exercise list with drop sets applied where appropriate
        """
        if not self.should_use_drop_sets(workout_focus, user_fitness_level):
            return exercises

        # Exercise types good for drop sets
        good_for_drop_sets = {
            "machine", "cable", "dumbbell", "isolation",
            "curl", "extension", "fly", "raise", "pushdown",
            "pulldown", "row"  # Machine rows are fine
        }

        # Exercise types to avoid for drop sets
        avoid_drop_sets = {
            "barbell squat", "deadlift", "bench press", "overhead press",
            "clean", "snatch", "jerk", "power", "explosive"
        }

        result = []
        drop_set_count = 0

        for exercise in exercises:
            exercise_copy = exercise.copy()
            name_lower = exercise.get("name", "").lower()
            equipment_lower = exercise.get("equipment", "").lower()

            # Check if this exercise is suitable for drop sets
            is_suitable = False
            if drop_set_count < max_drop_set_exercises:
                # Check if it's a good candidate
                for keyword in good_for_drop_sets:
                    if keyword in name_lower or keyword in equipment_lower:
                        is_suitable = True
                        break

                # Check if it should be avoided
                for keyword in avoid_drop_sets:
                    if keyword in name_lower:
                        is_suitable = False
                        break

            if is_suitable:
                exercise_copy = self.add_drop_sets_to_exercise(exercise_copy)
                drop_set_count += 1

            result.append(exercise_copy)

        return result


# Singleton instance for easy import
_adaptive_service_instance = None


def get_adaptive_workout_service(supabase_client=None) -> AdaptiveWorkoutService:
    """Get or create the AdaptiveWorkoutService singleton."""
    global _adaptive_service_instance
    if _adaptive_service_instance is None:
        _adaptive_service_instance = AdaptiveWorkoutService(supabase_client)
    return _adaptive_service_instance
