"""
AI Insights Service - Gemini-powered analysis for scores and progress.

Generates personalized insights for:
- Strength score analysis and muscle imbalance recommendations
- Readiness-based workout recommendations
- PR celebration messages
- Weekly progress summaries

Uses the existing Gemini service for AI generation.
"""
from typing import Dict, List, Optional, Any
from datetime import datetime, date
import logging
import json

from services.gemini_service import gemini_service
from services.strength_calculator_service import StrengthLevel, MuscleGroup
from services.readiness_service import ReadinessLevel, WorkoutIntensity

logger = logging.getLogger(__name__)


# ============================================================================
# Prompt Templates
# ============================================================================

STRENGTH_INSIGHT_PROMPT = """You are a fitness coach AI analyzing a user's strength scores.

## User's Strength Scores by Muscle Group:
{strength_scores}

## User Profile:
- Goals: {goals}
- Fitness Level: {fitness_level}
- Training Experience: {training_experience}

## Recent Workout History (Last 2 Weeks):
{recent_workouts}

## Analysis Task:
Provide a brief, encouraging analysis (under 200 words) that includes:
1. Top 2-3 strongest muscle groups (celebrate progress!)
2. Top 2-3 muscle groups that could use more focus
3. One specific exercise recommendation to address imbalances
4. Brief encouragement based on their overall progress

## Coach Personality:
{coach_style}

## Response Guidelines:
- Be {communication_tone}
- Focus on actionable advice
- Celebrate strengths before mentioning areas to improve
- Keep response conversational and supportive
- NO bullet points - use natural sentences
- NO technical jargon unless necessary

Response:"""

READINESS_RECOMMENDATION_PROMPT = """You are a fitness coach AI providing workout guidance based on today's readiness check-in.

## Today's Readiness Check-In:
- Sleep Quality: {sleep}/7 (1=excellent, 7=poor)
- Fatigue Level: {fatigue}/7 (1=fresh, 7=exhausted)
- Stress Level: {stress}/7 (1=relaxed, 7=stressed)
- Muscle Soreness: {soreness}/7 (1=none, 7=severe)
- Calculated Readiness Score: {readiness_score}/100
- Readiness Level: {readiness_level}

## Today's Scheduled Workout:
{scheduled_workout}

## User Profile:
- Fitness Level: {fitness_level}
- Goals: {goals}

## Coach Personality:
{coach_style}

## Task:
Provide a brief recommendation (under 100 words) that includes:
1. Should they proceed with the workout? (yes/modify/rest)
2. If modify, specific adjustments (e.g., "reduce sets by 20%", "lower intensity")
3. A brief motivational message

## Response Guidelines:
- Be {communication_tone}
- Be direct but supportive
- Don't over-explain
- If recommending rest, make them feel good about it
- Acknowledge their check-in data specifically

Response:"""

PR_CELEBRATION_PROMPT = """You are a fitness coach AI celebrating a personal record!

## PR Details:
- Exercise: {exercise_name}
- Weight Lifted: {weight_kg} kg x {reps} reps
- Estimated 1RM: {estimated_1rm} kg
- Previous Best: {previous_1rm} kg
- Improvement: {improvement_kg} kg ({improvement_percent}%)
- Time Since Last PR: {days_since_last_pr} days

## User Profile:
- Name: {user_name}
- Goals: {goals}

## Coach Personality:
{coach_style}

## Task:
Write a brief, enthusiastic celebration message (2-3 sentences max) for this PR.

## Response Guidelines:
- Be {communication_tone}
- Be genuinely excited for them
- Mention the specific achievement
- Include encouragement for future progress
- Keep it short and punchy
- Make them feel accomplished!

Response:"""

WEEKLY_PROGRESS_PROMPT = """You are a fitness coach AI providing a weekly progress summary.

## This Week's Metrics:
- Workouts Completed: {workouts_completed}/{workouts_scheduled}
- Average Readiness Score: {avg_readiness}/100
- Personal Records Set: {pr_count}
- Total Volume: {total_volume} kg
- Most Trained Muscle: {most_trained_muscle}

## Strength Score Changes:
{strength_changes}

## Nutrition Summary:
- Average Daily Calories: {avg_calories}
- Average Daily Protein: {avg_protein}g
- Days Logged: {nutrition_days_logged}/7

## User Profile:
- Goals: {goals}
- Fitness Level: {fitness_level}

## Coach Personality:
{coach_style}

## Task:
Write a brief weekly summary (under 150 words) that:
1. Celebrates wins (even small ones)
2. Notes any areas that need attention
3. Provides one specific focus for next week
4. Ends with encouragement

## Response Guidelines:
- Be {communication_tone}
- Start with something positive
- Be constructive, not critical
- Make next week's focus actionable
- Keep the tone supportive

Response:"""


class AIInsightsService:
    """
    Generates AI-powered insights using Gemini.

    All methods handle errors gracefully and return fallback
    messages if AI generation fails.
    """

    def __init__(self):
        self.gemini = gemini_service

    # -------------------------------------------------------------------------
    # Strength Insights
    # -------------------------------------------------------------------------

    async def generate_strength_insights(
        self,
        strength_scores: Dict[str, Dict],
        user_profile: Dict,
        recent_workouts: Optional[List[Dict]] = None,
        coach_style: str = "motivational",
        communication_tone: str = "encouraging",
    ) -> str:
        """
        Generate AI insights about strength scores and muscle balance.

        Args:
            strength_scores: Dict of muscle group -> score data
            user_profile: User's profile data (goals, fitness level, etc.)
            recent_workouts: Recent workout history
            coach_style: Coach personality style
            communication_tone: Communication tone preference

        Returns:
            AI-generated insight string
        """
        try:
            # Format strength scores for prompt
            scores_text = "\n".join([
                f"- {mg.replace('_', ' ').title()}: {data.get('strength_score', 0)}/100 ({data.get('strength_level', 'beginner')})"
                for mg, data in strength_scores.items()
            ])

            # Format recent workouts
            workouts_text = "No recent workouts" if not recent_workouts else "\n".join([
                f"- {w.get('name', 'Workout')}: {w.get('exercises_count', 0)} exercises, {w.get('total_volume', 0)}kg volume"
                for w in recent_workouts[:5]
            ])

            prompt = STRENGTH_INSIGHT_PROMPT.format(
                strength_scores=scores_text,
                goals=", ".join(user_profile.get("goals", ["general fitness"])),
                fitness_level=user_profile.get("fitness_level", "intermediate"),
                training_experience=user_profile.get("training_experience", "moderate"),
                recent_workouts=workouts_text,
                coach_style=coach_style,
                communication_tone=communication_tone,
            )

            response = await self.gemini.chat(
                message=prompt,
                user_id=user_profile.get("id"),
                context="strength_insights",
            )

            return response.get("response", self._fallback_strength_insight(strength_scores))

        except Exception as e:
            logger.error(f"Error generating strength insights: {e}")
            return self._fallback_strength_insight(strength_scores)

    def _fallback_strength_insight(self, strength_scores: Dict) -> str:
        """Generate fallback insight if AI fails."""
        # Find strongest and weakest
        sorted_scores = sorted(
            strength_scores.items(),
            key=lambda x: x[1].get("strength_score", 0),
            reverse=True,
        )

        if not sorted_scores:
            return "Keep training consistently to build your strength profile!"

        strongest = sorted_scores[0][0].replace("_", " ").title()
        weakest = sorted_scores[-1][0].replace("_", " ").title() if len(sorted_scores) > 1 else None

        if weakest and weakest != strongest:
            return f"Great progress on your {strongest}! Consider adding some focused work on your {weakest} to improve overall balance."
        return f"Strong work on your {strongest}! Keep up the consistent training."

    # -------------------------------------------------------------------------
    # Readiness Recommendations
    # -------------------------------------------------------------------------

    async def generate_readiness_recommendation(
        self,
        readiness_data: Dict,
        scheduled_workout: Optional[Dict] = None,
        user_profile: Dict = None,
        coach_style: str = "motivational",
        communication_tone: str = "encouraging",
    ) -> str:
        """
        Generate AI recommendation based on readiness check-in.

        Args:
            readiness_data: Today's readiness check-in data
            scheduled_workout: Optional scheduled workout for today
            user_profile: User's profile data
            coach_style: Coach personality style
            communication_tone: Communication tone preference

        Returns:
            AI-generated recommendation string
        """
        user_profile = user_profile or {}

        try:
            # Format workout info
            workout_text = "No workout scheduled" if not scheduled_workout else (
                f"{scheduled_workout.get('name', 'Workout')}: "
                f"{scheduled_workout.get('type', 'strength')} workout, "
                f"~{scheduled_workout.get('duration_minutes', 45)} minutes, "
                f"{scheduled_workout.get('exercises_count', 6)} exercises"
            )

            prompt = READINESS_RECOMMENDATION_PROMPT.format(
                sleep=readiness_data.get("sleep_quality", 4),
                fatigue=readiness_data.get("fatigue_level", 4),
                stress=readiness_data.get("stress_level", 4),
                soreness=readiness_data.get("muscle_soreness", 4),
                readiness_score=readiness_data.get("readiness_score", 50),
                readiness_level=readiness_data.get("readiness_level", "moderate"),
                scheduled_workout=workout_text,
                fitness_level=user_profile.get("fitness_level", "intermediate"),
                goals=", ".join(user_profile.get("goals", ["general fitness"])),
                coach_style=coach_style,
                communication_tone=communication_tone,
            )

            response = await self.gemini.chat(
                message=prompt,
                user_id=user_profile.get("id"),
                context="readiness_recommendation",
            )

            return response.get("response", self._fallback_readiness_recommendation(readiness_data))

        except Exception as e:
            logger.error(f"Error generating readiness recommendation: {e}")
            return self._fallback_readiness_recommendation(readiness_data)

    def _fallback_readiness_recommendation(self, readiness_data: Dict) -> str:
        """Generate fallback recommendation if AI fails."""
        score = readiness_data.get("readiness_score", 50)

        if score >= 80:
            return "You're feeling great today! Perfect time for a challenging workout. Push yourself!"
        elif score >= 60:
            return "You're ready for a normal training session. Stay hydrated and listen to your body."
        elif score >= 40:
            return "Consider a lighter workout today. Maybe reduce the intensity or volume by 20-30%."
        else:
            return "Rest day recommended. Light movement like walking or stretching is fine, but give your body time to recover."

    # -------------------------------------------------------------------------
    # PR Celebration
    # -------------------------------------------------------------------------

    async def generate_pr_celebration(
        self,
        pr_data: Dict,
        user_profile: Dict = None,
        coach_style: str = "motivational",
        communication_tone: str = "encouraging",
    ) -> str:
        """
        Generate personalized PR celebration message.

        Args:
            pr_data: Personal record data
            user_profile: User's profile data
            coach_style: Coach personality style
            communication_tone: Communication tone preference

        Returns:
            AI-generated celebration message
        """
        user_profile = user_profile or {}

        try:
            prompt = PR_CELEBRATION_PROMPT.format(
                exercise_name=pr_data.get("exercise_name", "exercise").replace("_", " ").title(),
                weight_kg=pr_data.get("weight_kg", 0),
                reps=pr_data.get("reps", 0),
                estimated_1rm=pr_data.get("estimated_1rm_kg", 0),
                previous_1rm=pr_data.get("previous_1rm_kg", 0) or "N/A",
                improvement_kg=pr_data.get("improvement_kg", 0) or "first PR!",
                improvement_percent=pr_data.get("improvement_percent", 0) or "N/A",
                days_since_last_pr=pr_data.get("days_since_last_pr", "N/A"),
                user_name=user_profile.get("name", "Champion"),
                goals=", ".join(user_profile.get("goals", ["getting stronger"])),
                coach_style=coach_style,
                communication_tone=communication_tone,
            )

            response = await self.gemini.chat(
                message=prompt,
                user_id=user_profile.get("id"),
                context="pr_celebration",
            )

            return response.get("response", self._fallback_pr_celebration(pr_data))

        except Exception as e:
            logger.error(f"Error generating PR celebration: {e}")
            return self._fallback_pr_celebration(pr_data)

    def _fallback_pr_celebration(self, pr_data: Dict) -> str:
        """Generate fallback celebration if AI fails."""
        exercise = pr_data.get("exercise_name", "exercise").replace("_", " ").title()
        improvement = pr_data.get("improvement_percent")

        if improvement and improvement > 10:
            return f"INCREDIBLE! New PR on {exercise} with a {improvement:.1f}% improvement! Your hard work is paying off!"
        elif improvement:
            return f"NEW PR! {exercise} just got stronger by {improvement:.1f}%! Keep pushing!"
        else:
            return f"PR achieved on {exercise}! First one recorded - this is where the journey begins!"

    # -------------------------------------------------------------------------
    # Weekly Progress Summary
    # -------------------------------------------------------------------------

    async def generate_weekly_summary(
        self,
        weekly_metrics: Dict,
        strength_changes: Dict[str, int],
        nutrition_summary: Dict,
        user_profile: Dict = None,
        coach_style: str = "motivational",
        communication_tone: str = "encouraging",
    ) -> str:
        """
        Generate weekly progress summary.

        Args:
            weekly_metrics: Workout and activity metrics for the week
            strength_changes: Changes in strength scores by muscle group
            nutrition_summary: Weekly nutrition data
            user_profile: User's profile data
            coach_style: Coach personality style
            communication_tone: Communication tone preference

        Returns:
            AI-generated weekly summary
        """
        user_profile = user_profile or {}

        try:
            # Format strength changes
            changes_text = "\n".join([
                f"- {mg.replace('_', ' ').title()}: {'+' if change > 0 else ''}{change} points"
                for mg, change in strength_changes.items()
                if change != 0
            ]) or "No significant changes this week"

            prompt = WEEKLY_PROGRESS_PROMPT.format(
                workouts_completed=weekly_metrics.get("workouts_completed", 0),
                workouts_scheduled=weekly_metrics.get("workouts_scheduled", 0),
                avg_readiness=weekly_metrics.get("avg_readiness", 0),
                pr_count=weekly_metrics.get("pr_count", 0),
                total_volume=weekly_metrics.get("total_volume", 0),
                most_trained_muscle=weekly_metrics.get("most_trained_muscle", "N/A"),
                strength_changes=changes_text,
                avg_calories=nutrition_summary.get("avg_calories", 0),
                avg_protein=nutrition_summary.get("avg_protein", 0),
                nutrition_days_logged=nutrition_summary.get("days_logged", 0),
                goals=", ".join(user_profile.get("goals", ["general fitness"])),
                fitness_level=user_profile.get("fitness_level", "intermediate"),
                coach_style=coach_style,
                communication_tone=communication_tone,
            )

            response = await self.gemini.chat(
                message=prompt,
                user_id=user_profile.get("id"),
                context="weekly_summary",
            )

            return response.get("response", self._fallback_weekly_summary(weekly_metrics))

        except Exception as e:
            logger.error(f"Error generating weekly summary: {e}")
            return self._fallback_weekly_summary(weekly_metrics)

    def _fallback_weekly_summary(self, weekly_metrics: Dict) -> str:
        """Generate fallback weekly summary if AI fails."""
        completed = weekly_metrics.get("workouts_completed", 0)
        scheduled = weekly_metrics.get("workouts_scheduled", 0)
        prs = weekly_metrics.get("pr_count", 0)

        parts = []

        if completed > 0:
            if completed >= scheduled:
                parts.append(f"Great week! You completed all {completed} scheduled workouts.")
            else:
                parts.append(f"You completed {completed} of {scheduled} workouts this week.")

        if prs > 0:
            parts.append(f"You set {prs} personal record{'s' if prs > 1 else ''}!")

        parts.append("Keep up the momentum next week!")

        return " ".join(parts)


# Singleton instance
ai_insights_service = AIInsightsService()
