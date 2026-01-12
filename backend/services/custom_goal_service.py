"""
Custom Goal Service - Generates search keywords from natural language goals using Gemini.

This service:
1. Takes user's custom goal text (e.g., "Improve box jump height")
2. Uses Gemini to analyze and extract relevant search keywords
3. Determines goal type and progression strategy
4. Caches results to minimize API calls during workout generation

Keywords are generated ONCE when the goal is created and cached in the database.
This ensures no additional latency during workout generation.
"""
from typing import Dict, List, Optional
from datetime import datetime, timedelta
import json

from google import genai
from google.genai import types

from core.config import get_settings
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.gemini_schemas import CustomGoalKeywordsResponse

logger = get_logger(__name__)
settings = get_settings()

# Refresh keywords older than this many days
KEYWORD_REFRESH_DAYS = 30


class CustomGoalService:
    """Manages custom goal keyword generation and caching."""

    def __init__(self):
        self.client = genai.Client(api_key=settings.gemini_api_key)
        self.model = settings.gemini_model
        self.db = get_supabase_db()

    async def generate_keywords_for_goal(self, goal_text: str) -> Dict:
        """
        Use Gemini to analyze a custom goal and generate search keywords.

        Args:
            goal_text: Natural language goal (e.g., "Improve box jump height")

        Returns:
            Dict with:
            - keywords: List of search keywords for RAG
            - goal_type: 'skill', 'power', 'endurance', 'sport', 'flexibility', etc.
            - target_metrics: Suggested measurable targets
            - progression_strategy: 'linear', 'wave', 'periodized', 'skill_based'
            - exercise_categories: Categories of exercises to include
            - muscle_groups: Primary muscle groups involved
            - training_notes: AI recommendations for training
        """
        prompt = f"""Analyze this fitness goal and extract training information for exercise selection.

GOAL: "{goal_text}"

Return ONLY valid JSON in this exact format:
{{
    "keywords": ["keyword1", "keyword2", "keyword3", ...],
    "goal_type": "skill|power|endurance|sport|flexibility|mobility|strength|general",
    "target_metrics": {{
        "metric_name": "target description"
    }},
    "progression_strategy": "linear|wave|periodized|skill_based",
    "exercise_categories": ["category1", "category2"],
    "muscle_groups": ["primary_muscle1", "primary_muscle2"],
    "training_frequency": "2-3x per week",
    "training_notes": "Brief training approach recommendation"
}}

KEYWORD GENERATION RULES:
1. Include specific exercise types (e.g., "plyometrics", "box jumps", "depth jumps")
2. Include muscle groups involved (e.g., "quadriceps", "glutes", "calves")
3. Include training modalities (e.g., "explosive", "power", "reactive")
4. Include equipment if relevant (e.g., "plyo box", "medicine ball")
5. Include sport-specific terms if applicable (e.g., "running economy", "lactate threshold")
6. Generate 8-15 relevant keywords that will help find appropriate exercises

GOAL TYPE DEFINITIONS:
- skill: Technique-based goals (box jump form, muscle-up, handstand)
- strength: Max strength goals (1RM increase, weighted movements)
- power: Explosive power goals (vertical leap, sprint speed, throwing)
- endurance: Cardio/stamina goals (marathon, cycling, swimming)
- sport: Sport-specific performance (basketball, tennis, soccer)
- flexibility: ROM/stretching goals (splits, shoulder flexibility)
- mobility: Joint health and movement quality
- general: Mixed or unclear goals

PROGRESSION STRATEGY:
- linear: Simple week-over-week increases (good for beginners, strength)
- wave: Alternating intensity weeks (good for preventing plateaus)
- periodized: Block training with distinct phases (good for athletes)
- skill_based: Technique focus before load increases (good for skill acquisition)

Example for "Improve box jump height":
{{
    "keywords": ["plyometrics", "box jumps", "depth jumps", "explosive power", "vertical leap", "reactive strength", "quadriceps", "glutes", "hip extension", "squat jumps", "power development", "jump training", "ground contact time"],
    "goal_type": "power",
    "target_metrics": {{"box_jump_height": "increase by 4-6 inches over 8-12 weeks"}},
    "progression_strategy": "wave",
    "exercise_categories": ["plyometrics", "lower body power", "jump training"],
    "muscle_groups": ["quadriceps", "glutes", "calves", "hamstrings", "hip flexors"],
    "training_frequency": "2-3x per week with 48-72hr recovery",
    "training_notes": "Focus on reactive strength and rate of force development. Start with low box heights and progress gradually. Quality over quantity - stop when jump quality degrades."
}}"""

        try:
            response = await self.client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=CustomGoalKeywordsResponse,
                    temperature=0.3,
                    max_output_tokens=2000,
                ),
            )

            content = response.text.strip()
            result = json.loads(content)
            logger.info(f"Generated {len(result.get('keywords', []))} keywords for goal: {goal_text[:50]}...")
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Gemini response for goal '{goal_text}': {e}")
            return self._get_fallback_keywords(goal_text)
        except Exception as e:
            logger.error(f"Failed to generate keywords for goal '{goal_text}': {e}")
            return self._get_fallback_keywords(goal_text)

    def _get_fallback_keywords(self, goal_text: str) -> Dict:
        """Return minimal fallback when AI generation fails."""
        # Extract basic words from the goal
        words = [w.lower() for w in goal_text.split() if len(w) > 3]
        return {
            "keywords": words[:5] + ["fitness", "training"],
            "goal_type": "general",
            "target_metrics": {},
            "progression_strategy": "linear",
            "exercise_categories": ["general fitness"],
            "muscle_groups": ["full body"],
            "training_frequency": "2-3x per week",
            "training_notes": "General training approach - goal analysis incomplete"
        }

    async def create_custom_goal(
        self,
        user_id: str,
        goal_text: str,
        priority: int = 3
    ) -> Dict:
        """
        Create a new custom goal with AI-generated keywords.

        Args:
            user_id: User's ID
            goal_text: Natural language goal
            priority: 1-5, higher = more focus in workout generation

        Returns:
            Created goal record with all fields
        """
        # Generate keywords using Gemini
        keyword_data = await self.generate_keywords_for_goal(goal_text)

        # Create goal record
        goal_data = {
            "user_id": user_id,
            "goal_text": goal_text,
            "search_keywords": keyword_data.get("keywords", []),
            "goal_type": keyword_data.get("goal_type", "general"),
            "target_metrics": keyword_data.get("target_metrics", {}),
            "progression_strategy": keyword_data.get("progression_strategy", "linear"),
            "exercise_categories": keyword_data.get("exercise_categories", []),
            "muscle_groups": keyword_data.get("muscle_groups", []),
            "training_notes": keyword_data.get("training_notes", ""),
            "is_active": True,
            "priority": max(1, min(5, priority)),  # Clamp to 1-5
            "keywords_updated_at": datetime.now().isoformat(),
        }

        result = self.db.client.table("custom_goals").insert(goal_data).execute()

        if result.data:
            goal = result.data[0]
            # Update user's active goal IDs cache
            await self._update_user_active_goals(user_id, goal["id"], add=True)
            logger.info(f"Created custom goal for user {user_id}: {goal_text[:50]}...")
            return goal

        raise Exception("Failed to create custom goal")

    async def get_active_goals(self, user_id: str) -> List[Dict]:
        """Get all active custom goals for a user, ordered by priority."""
        result = self.db.client.table("custom_goals").select("*").eq(
            "user_id", user_id
        ).eq("is_active", True).order("priority", desc=True).execute()

        return result.data or []

    async def get_goal_by_id(self, goal_id: str) -> Optional[Dict]:
        """Get a specific goal by ID."""
        result = self.db.client.table("custom_goals").select("*").eq(
            "id", goal_id
        ).single().execute()

        return result.data if result.data else None

    async def get_combined_keywords(self, user_id: str) -> List[str]:
        """
        Get combined search keywords from all active custom goals.

        Used by the exercise RAG service to augment search queries.
        Keywords from higher-priority goals appear first.

        Returns:
            Unique list of keywords, weighted by priority
        """
        goals = await self.get_active_goals(user_id)

        if not goals:
            return []

        all_keywords = []
        for goal in goals:
            keywords = goal.get("search_keywords", [])
            # Handle both list and JSON string formats
            if isinstance(keywords, str):
                try:
                    keywords = json.loads(keywords)
                except json.JSONDecodeError:
                    keywords = []

            # Weight keywords by priority (higher priority = more repetitions for emphasis)
            priority = goal.get("priority", 1)
            all_keywords.extend(keywords * priority)

        # Remove duplicates while preserving order (higher priority first)
        seen = set()
        unique_keywords = []
        for kw in all_keywords:
            kw_lower = kw.lower()
            if kw_lower not in seen:
                seen.add(kw_lower)
                unique_keywords.append(kw)

        logger.debug(f"Combined {len(unique_keywords)} unique keywords for user {user_id}")
        return unique_keywords

    async def update_goal(
        self,
        goal_id: str,
        is_active: Optional[bool] = None,
        priority: Optional[int] = None
    ) -> Dict:
        """
        Update a custom goal's active status or priority.

        Args:
            goal_id: Goal ID to update
            is_active: New active status (optional)
            priority: New priority 1-5 (optional)

        Returns:
            Updated goal record
        """
        update_data = {"updated_at": datetime.now().isoformat()}

        if is_active is not None:
            update_data["is_active"] = is_active
        if priority is not None:
            update_data["priority"] = max(1, min(5, priority))

        result = self.db.client.table("custom_goals").update(
            update_data
        ).eq("id", goal_id).execute()

        if result.data:
            goal = result.data[0]
            # Update user's active goals cache if activation changed
            if is_active is not None:
                await self._update_user_active_goals(
                    goal["user_id"], goal_id, add=is_active
                )
            return goal

        raise Exception(f"Goal {goal_id} not found")

    async def delete_goal(self, goal_id: str) -> bool:
        """
        Delete a custom goal.

        Args:
            goal_id: Goal ID to delete

        Returns:
            True if deleted successfully
        """
        # Get the goal first to know the user_id
        goal = await self.get_goal_by_id(goal_id)
        if not goal:
            return False

        result = self.db.client.table("custom_goals").delete().eq(
            "id", goal_id
        ).execute()

        if result.data:
            # Update user's active goals cache
            await self._update_user_active_goals(goal["user_id"], goal_id, add=False)
            logger.info(f"Deleted custom goal {goal_id}")
            return True

        return False

    async def refresh_stale_keywords(self, user_id: str) -> int:
        """
        Refresh keywords for goals that haven't been updated recently.

        This is called periodically (not during workout generation) to keep
        keywords fresh without adding latency.

        Returns:
            Number of goals refreshed
        """
        cutoff = (datetime.now() - timedelta(days=KEYWORD_REFRESH_DAYS)).isoformat()

        stale_goals = self.db.client.table("custom_goals").select("*").eq(
            "user_id", user_id
        ).eq("is_active", True).lt("keywords_updated_at", cutoff).execute()

        refreshed = 0
        for goal in stale_goals.data or []:
            try:
                keyword_data = await self.generate_keywords_for_goal(goal["goal_text"])
                self.db.client.table("custom_goals").update({
                    "search_keywords": keyword_data.get("keywords", []),
                    "goal_type": keyword_data.get("goal_type", goal.get("goal_type")),
                    "progression_strategy": keyword_data.get("progression_strategy", goal.get("progression_strategy")),
                    "keywords_updated_at": datetime.now().isoformat(),
                }).eq("id", goal["id"]).execute()
                refreshed += 1
                logger.info(f"Refreshed keywords for goal {goal['id']}")
            except Exception as e:
                logger.error(f"Failed to refresh goal {goal['id']}: {e}")

        return refreshed

    async def _update_user_active_goals(
        self,
        user_id: str,
        goal_id: str,
        add: bool = True
    ):
        """
        Update user's active_custom_goal_ids array for quick access.

        This cache allows efficient checking of whether a user has custom goals
        without querying the custom_goals table.
        """
        try:
            user = self.db.client.table("users").select(
                "active_custom_goal_ids"
            ).eq("id", user_id).single().execute()

            current_ids = user.data.get("active_custom_goal_ids", []) or []

            # Ensure it's a list
            if isinstance(current_ids, str):
                try:
                    current_ids = json.loads(current_ids)
                except json.JSONDecodeError:
                    current_ids = []

            if add and goal_id not in current_ids:
                current_ids.append(goal_id)
            elif not add and goal_id in current_ids:
                current_ids.remove(goal_id)

            self.db.client.table("users").update({
                "active_custom_goal_ids": current_ids
            }).eq("id", user_id).execute()

        except Exception as e:
            logger.warning(f"Failed to update user active goals cache: {e}")


# Singleton instance
_custom_goal_service: Optional[CustomGoalService] = None


def get_custom_goal_service() -> CustomGoalService:
    """Get or create the singleton CustomGoalService instance."""
    global _custom_goal_service
    if _custom_goal_service is None:
        _custom_goal_service = CustomGoalService()
    return _custom_goal_service
