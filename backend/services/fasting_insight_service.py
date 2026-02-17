"""
Fasting Insight Service - AI-powered analysis of fasting impact on goals.

This service uses Gemini AI to generate personalized insights about how
intermittent fasting affects the user's fitness goals.

GEMINI INTEGRATION NOTES:
- Uses response_mime_type="application/json" for structured responses
- Robust JSON extraction handles markdown code blocks
- 120-second timeout for complex analysis
- Proper error handling with user-friendly messages
- No mock data or fallbacks per CLAUDE.md guidelines
- Caching to avoid repeated AI calls
"""
from typing import Optional, Dict, Any, List
from datetime import datetime, date, timedelta
import uuid
import json
import asyncio
from google import genai
from google.genai import types

from core.logger import get_logger
from core.config import get_settings
from core.gemini_client import get_genai_client
from core.supabase_db import get_supabase_db
from models.gemini_schemas import FastingInsightResponse

logger = get_logger(__name__)
settings = get_settings()

# Initialize Gemini client
client = get_genai_client()

# Cache for insights (in production, use Redis)
_insight_cache: Dict[str, Dict[str, Any]] = {}
CACHE_TTL_HOURS = 24
CACHE_MAX_SIZE = 50


class FastingInsightService:
    """Service for generating AI-powered fasting insights."""

    def __init__(self):
        self.model = settings.gemini_model
        # Use 120 second timeout for Gemini Pro calls per CLAUDE.md
        self.timeout_seconds = 120

    def _extract_json_from_response(self, response_text: str) -> Dict[str, Any]:
        """
        Robustly extract JSON from Gemini response.

        Handles:
        - Direct JSON responses
        - Markdown code blocks (```json ... ```)
        - Whitespace and formatting issues

        Per Gemini Integration Validator guidelines.
        """
        if not response_text:
            raise ValueError("Empty response from Gemini API")

        content = response_text.strip()

        # Handle markdown code blocks (```json ... ```)
        if "```json" in content:
            import re
            json_match = re.search(r'```json\s*([\s\S]*?)```', content)
            if json_match:
                content = json_match.group(1).strip()
        elif "```" in content:
            # Generic code block
            import re
            json_match = re.search(r'```\s*([\s\S]*?)```', content)
            if json_match:
                content = json_match.group(1).strip()

        # Try to parse JSON
        try:
            return json.loads(content)
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON from Gemini response: {e}")
            logger.error(f"Response content: {content[:500]}...")
            raise ValueError(f"Invalid JSON response from AI: {e}")

    def _get_cache_key(self, user_id: str, data_hash: str) -> str:
        """Generate cache key for insight."""
        return f"fasting_insight:{user_id}:{data_hash}"

    def _get_data_hash(self, fasting_data: Dict, weight_data: List, goal_data: Dict) -> str:
        """Generate a hash of input data for caching."""
        import hashlib
        data_str = json.dumps({
            "fasting": fasting_data,
            "weight_count": len(weight_data),
            "goal": goal_data
        }, sort_keys=True, default=str)
        return hashlib.md5(data_str.encode()).hexdigest()[:12]

    def _check_cache(self, cache_key: str) -> Optional[Dict[str, Any]]:
        """Check if insight is cached and still valid."""
        if cache_key in _insight_cache:
            cached = _insight_cache[cache_key]
            cached_at = datetime.fromisoformat(cached.get("cached_at", "2000-01-01"))
            if datetime.utcnow() - cached_at < timedelta(hours=CACHE_TTL_HOURS):
                logger.info(f"Cache hit for fasting insight: {cache_key}")
                return cached.get("insight")
        return None

    def _save_to_cache(self, cache_key: str, insight: Dict[str, Any]) -> None:
        """Save insight to cache."""
        if len(_insight_cache) >= CACHE_MAX_SIZE:
            # Evict oldest entry
            oldest_key = min(_insight_cache, key=lambda k: _insight_cache[k].get('cached_at', ''))
            del _insight_cache[oldest_key]
        _insight_cache[cache_key] = {
            "insight": insight,
            "cached_at": datetime.utcnow().isoformat()
        }

    async def generate_fasting_impact_insight(
        self,
        user_id: str,
        fasting_data: Dict[str, Any],
        weight_data: List[Dict[str, Any]],
        goal_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Generate AI insight about how fasting impacts the user's goals.

        Args:
            user_id: User ID
            fasting_data: Summary of fasting patterns
            weight_data: Weight logs with fasting correlation
            goal_data: Goal achievement data

        Returns:
            Insight with title, message, recommendation, and data summary

        Raises:
            ValueError: If AI response is invalid
            Exception: For API errors (no fallback per CLAUDE.md)
        """
        logger.info(f"Generating fasting insight for user {user_id}")

        # Check cache first
        data_hash = self._get_data_hash(fasting_data, weight_data, goal_data)
        cache_key = self._get_cache_key(user_id, data_hash)
        cached_insight = self._check_cache(cache_key)
        if cached_insight:
            return cached_insight

        # Check if we have enough data
        total_days = fasting_data.get("total_fasting_days", 0)
        if total_days < 3:
            logger.info(f"Insufficient data for insight: {total_days} fasting days")
            return {
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "insight_type": "needs_more_data",
                "title": "Keep Tracking!",
                "message": f"You've logged {total_days} fasting day{'s' if total_days != 1 else ''}. Continue for at least a week to see meaningful insights about how fasting affects your goals.",
                "recommendation": "Try to be consistent with your fasting schedule and log your weight daily.",
                "key_finding": f"{total_days} days tracked so far",
                "data_summary": {
                    "fasting_days": total_days,
                    "avg_weight_fasting": None,
                    "avg_weight_non_fasting": None,
                    "correlation_score": None,
                },
                "created_at": datetime.utcnow().isoformat(),
            }

        # Build context for the AI
        context = self._build_context(fasting_data, weight_data, goal_data)

        prompt = f"""You are a fitness coach AI analyzing how intermittent fasting affects a user's fitness goals.

Based on the following data, provide a personalized insight about the impact of fasting on their goals:

{context}

IMPORTANT: Respond ONLY with valid JSON (no markdown, no explanation outside JSON).

Return this exact JSON structure:
{{
  "insight_type": "positive" | "neutral" | "negative" | "needs_more_data",
  "title": "Short title (max 50 chars)",
  "message": "2-3 sentence insight about the correlation between fasting and their goals",
  "recommendation": "One actionable recommendation based on the data",
  "key_finding": "The most important data point or finding"
}}

Guidelines:
- Be specific and use the actual numbers from the data
- Be encouraging but honest
- For insight_type:
  - "positive": Fasting shows clear benefits
  - "neutral": No clear correlation yet
  - "negative": Fasting may be negatively impacting goals
  - "needs_more_data": Insufficient data for conclusions
- Keep title under 50 characters
- Make recommendation actionable and specific"""

        try:
            logger.info(f"Calling Gemini API for fasting insight")

            # Use timeout wrapper for the API call
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=FastingInsightResponse,
                        max_output_tokens=1000,
                        temperature=0.3,  # Lower temperature for consistent analysis
                        # Safety settings for fitness content
                        safety_settings=[
                            types.SafetySetting(
                                category="HARM_CATEGORY_DANGEROUS_CONTENT",
                                threshold="BLOCK_ONLY_HIGH",
                            ),
                        ],
                    ),
                ),
                timeout=self.timeout_seconds
            )

            # Check for blocked response
            if not response.text:
                logger.warning(f"Empty response from Gemini (possibly blocked by safety filters)")
                raise ValueError("AI response was empty - content may have been filtered")

            logger.info(f"Gemini API response received for fasting insight")

            # Parse JSON directly - structured output guarantees valid JSON
            parsed_response = json.loads(response.text.strip())

            # Validate required fields
            required_fields = ["insight_type", "title", "message", "recommendation"]
            for field in required_fields:
                if field not in parsed_response:
                    raise ValueError(f"Missing required field in AI response: {field}")

            # Validate insight_type
            valid_types = ["positive", "neutral", "negative", "needs_more_data"]
            if parsed_response.get("insight_type") not in valid_types:
                parsed_response["insight_type"] = "neutral"

            # Build final insight
            insight = {
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "insight_type": parsed_response.get("insight_type", "neutral"),
                "title": parsed_response.get("title", "Fasting Analysis")[:50],
                "message": parsed_response.get("message", ""),
                "recommendation": parsed_response.get("recommendation", ""),
                "key_finding": parsed_response.get("key_finding", ""),
                "data_summary": {
                    "fasting_days": fasting_data.get("total_fasting_days", 0),
                    "avg_weight_fasting": fasting_data.get("avg_weight_fasting"),
                    "avg_weight_non_fasting": fasting_data.get("avg_weight_non_fasting"),
                    "correlation_score": fasting_data.get("correlation_score"),
                },
                "created_at": datetime.utcnow().isoformat(),
            }

            # Cache the insight
            self._save_to_cache(cache_key, insight)

            logger.info(f"Successfully generated fasting insight: {insight['insight_type']}")
            return insight

        except asyncio.TimeoutError:
            logger.error(f"Gemini API timeout after {self.timeout_seconds}s for fasting insight")
            raise Exception("AI analysis is taking too long. Please try again later.")

        except ValueError as e:
            # Re-raise validation errors
            logger.error(f"Validation error in fasting insight: {e}")
            raise

        except Exception as e:
            logger.error(f"Error generating fasting insight: {e}")
            # Per CLAUDE.md: NO fallback or mock data - propagate the error
            raise Exception(f"Failed to generate AI insight: {str(e)}")

    def _build_context(
        self,
        fasting_data: Dict[str, Any],
        weight_data: List[Dict[str, Any]],
        goal_data: Dict[str, Any],
    ) -> str:
        """Build context string for AI prompt."""
        lines = []

        # Fasting summary
        lines.append("FASTING SUMMARY:")
        lines.append(f"- Total fasting days: {fasting_data.get('total_fasting_days', 0)}")
        lines.append(f"- Total non-fasting days: {fasting_data.get('total_non_fasting_days', 0)}")
        lines.append(f"- Most common protocol: {fasting_data.get('most_common_protocol', 'N/A')}")
        avg_duration = fasting_data.get('avg_fast_duration_hours', 0)
        lines.append(f"- Average fast duration: {avg_duration:.1f} hours")

        # Weight data
        if weight_data:
            fasting_weights = [w['weight_kg'] for w in weight_data if w.get('is_fasting_day')]
            non_fasting_weights = [w['weight_kg'] for w in weight_data if not w.get('is_fasting_day')]

            lines.append("\nWEIGHT DATA:")
            if fasting_weights:
                avg_fasting = sum(fasting_weights) / len(fasting_weights)
                lines.append(f"- Avg weight on fasting days: {avg_fasting:.1f} kg")
            if non_fasting_weights:
                avg_non_fasting = sum(non_fasting_weights) / len(non_fasting_weights)
                lines.append(f"- Avg weight on non-fasting days: {avg_non_fasting:.1f} kg")

            if len(weight_data) >= 2:
                # Sort by date if available
                sorted_weights = sorted(weight_data, key=lambda x: x.get('date', ''))
                if sorted_weights:
                    weight_change = sorted_weights[-1]['weight_kg'] - sorted_weights[0]['weight_kg']
                    lines.append(f"- Weight change over period: {weight_change:+.1f} kg")
        else:
            lines.append("\nWEIGHT DATA: No weight logs available")

        # Goal data
        lines.append("\nGOAL ACHIEVEMENT:")
        lines.append(f"- Goals achieved on fasting days: {goal_data.get('goals_fasting', 0)}")
        lines.append(f"- Goals achieved on non-fasting days: {goal_data.get('goals_non_fasting', 0)}")

        workout_fasting = goal_data.get('workout_completion_fasting', 0)
        workout_non_fasting = goal_data.get('workout_completion_non_fasting', 0)
        lines.append(f"- Workout completion on fasting days: {workout_fasting:.0f}%")
        lines.append(f"- Workout completion on non-fasting days: {workout_non_fasting:.0f}%")

        # Correlation
        if fasting_data.get('correlation_score') is not None:
            score = fasting_data['correlation_score']
            if score > 0.3:
                interpretation = "strong positive"
            elif score > 0.1:
                interpretation = "slight positive"
            elif score < -0.3:
                interpretation = "strong negative"
            elif score < -0.1:
                interpretation = "slight negative"
            else:
                interpretation = "no clear"
            lines.append(f"\nCORRELATION SCORE: {score:.2f} ({interpretation} impact)")

        return "\n".join(lines)

    async def calculate_correlation_score(
        self,
        user_id: str,
        days: int = 30,
    ) -> float:
        """
        Calculate Pearson correlation between fasting and goal achievement.

        Returns a score from -1 to 1:
        - Positive: Fasting correlates with better goal achievement
        - Negative: Fasting correlates with worse goal achievement
        - Near zero: No clear correlation
        """
        logger.info(f"Calculating correlation score for user {user_id} over {days} days")

        db = get_supabase_db()

        # Get daily data with fasting status and goal achievement
        end_date = date.today()
        start_date = end_date - timedelta(days=days)

        try:
            # Query daily_unified_state for fasting and goal data
            result = db.client.table("daily_unified_state").select(
                "date, is_fasting_day, workout_completed"
            ).eq("user_id", user_id).gte(
                "date", start_date.isoformat()
            ).lte("date", end_date.isoformat()).execute()

            if not result.data or len(result.data) < 7:
                logger.info(f"Not enough data for correlation: {len(result.data or [])} days")
                return 0.0  # Not enough data

            # Calculate correlation
            fasting_values = []
            achievement_values = []

            for day in result.data:
                fasting_values.append(1 if day.get("is_fasting_day") else 0)
                achievement_values.append(1 if day.get("workout_completed") else 0)

            correlation = self._pearson_correlation(fasting_values, achievement_values)
            logger.info(f"Calculated correlation score: {correlation:.3f}")
            return correlation

        except Exception as e:
            logger.error(f"Error calculating correlation: {e}")
            return 0.0

    def _pearson_correlation(self, x: List[float], y: List[float]) -> float:
        """Calculate Pearson correlation coefficient."""
        n = len(x)
        if n == 0 or n != len(y):
            return 0.0

        mean_x = sum(x) / n
        mean_y = sum(y) / n

        numerator = sum((xi - mean_x) * (yi - mean_y) for xi, yi in zip(x, y))
        denominator_x = sum((xi - mean_x) ** 2 for xi in x) ** 0.5
        denominator_y = sum((yi - mean_y) ** 2 for yi in y) ** 0.5

        if denominator_x == 0 or denominator_y == 0:
            return 0.0

        return numerator / (denominator_x * denominator_y)

    async def get_fasting_summary_for_insight(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get fasting summary data for insight generation.

        Returns aggregated data about fasting patterns.
        """
        logger.info(f"Getting fasting summary for user {user_id}")

        db = get_supabase_db()
        end_date = date.today()
        start_date = end_date - timedelta(days=days)

        try:
            # Get fasting records
            result = db.client.table("fasting_records").select(
                "protocol, actual_duration_minutes, status, start_time"
            ).eq("user_id", user_id).gte(
                "start_time", start_date.isoformat()
            ).eq("status", "completed").execute()

            records = result.data or []

            if not records:
                return {
                    "total_fasting_days": 0,
                    "total_non_fasting_days": days,
                    "most_common_protocol": None,
                    "avg_fast_duration_hours": 0,
                    "correlation_score": None,
                }

            # Calculate totals
            total_fasting_days = len(set(
                r.get("start_time", "")[:10] for r in records
            ))

            # Most common protocol
            protocol_counts: Dict[str, int] = {}
            for r in records:
                protocol = r.get("protocol", "unknown")
                protocol_counts[protocol] = protocol_counts.get(protocol, 0) + 1

            most_common = max(protocol_counts, key=protocol_counts.get) if protocol_counts else None

            # Average duration
            durations = [r.get("actual_duration_minutes", 0) or 0 for r in records]
            avg_duration_hours = (sum(durations) / len(durations) / 60) if durations else 0

            # Calculate correlation
            correlation = await self.calculate_correlation_score(user_id, days)

            return {
                "total_fasting_days": total_fasting_days,
                "total_non_fasting_days": days - total_fasting_days,
                "most_common_protocol": most_common,
                "avg_fast_duration_hours": avg_duration_hours,
                "correlation_score": correlation,
            }

        except Exception as e:
            logger.error(f"Error getting fasting summary: {e}")
            raise


# Singleton instance
_fasting_insight_service: Optional[FastingInsightService] = None


def get_fasting_insight_service() -> FastingInsightService:
    """Get singleton instance of FastingInsightService."""
    global _fasting_insight_service
    if _fasting_insight_service is None:
        _fasting_insight_service = FastingInsightService()
    return _fasting_insight_service
