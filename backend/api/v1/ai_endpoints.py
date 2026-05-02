"""
AI utility endpoints
====================
Lightweight AI-powered helpers that don't fit into a larger feature router.

Currently:
- POST /ai/exercise-insights — generate form cues, common mistakes, and a pro tip
  for a given exercise. Used by the Workout Active screen's exercise info bottom
  sheet (mobile/flutter/lib/core/services/exercise_info_service.dart).
"""

import json
import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.config import get_settings
from core.exceptions import safe_internal_error

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/ai", tags=["AI Utilities"])


# ---------------------------------------------------------------------------
# Request / response models
# ---------------------------------------------------------------------------

class ExerciseInsightsRequest(BaseModel):
    exercise_name: str = Field(..., min_length=1, max_length=200)
    primary_muscle: Optional[str] = Field(default=None, max_length=100)
    equipment: Optional[str] = Field(default=None, max_length=100)
    difficulty: Optional[str] = Field(default=None, max_length=50)


class ExerciseInsightsResponse(BaseModel):
    form_cues: str = ""
    common_mistakes: str = ""
    pro_tip: str = ""
    muscles_focused: List[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------

@router.post("/exercise-insights", response_model=ExerciseInsightsResponse)
async def generate_exercise_insights(
    body: ExerciseInsightsRequest,
    current_user=Depends(get_current_user),
):
    """Generate AI-powered form cues, common mistakes, and a pro tip for an exercise.

    Returns a structured JSON object the Flutter client renders in the exercise
    info bottom sheet. Falls back to empty fields on Gemini failure so the
    caller's local fallback logic can take over (it caches by exercise name).
    """
    try:
        # Lazy imports — keep cold-start cost off the hot path of unrelated routes.
        from google.genai import types
        from services.gemini.constants import gemini_generate_with_retry

        settings = get_settings()
        user_id = current_user.get("id") if isinstance(current_user, dict) else None

        details_lines = [f"Exercise: {body.exercise_name}"]
        if body.primary_muscle:
            details_lines.append(f"Primary muscle: {body.primary_muscle}")
        if body.equipment:
            details_lines.append(f"Equipment: {body.equipment}")
        if body.difficulty:
            details_lines.append(f"Difficulty: {body.difficulty}")
        details_block = "\n".join(details_lines)

        system_prompt = (
            "You are a certified strength coach (NSCA-CSCS). Generate concise, "
            "high-signal form coaching for a single exercise. Output STRICT JSON "
            "with this shape (no markdown, no commentary):\n"
            "{\n"
            '  "form_cues": "1-2 short sentences with the most important setup + execution cues",\n'
            '  "common_mistakes": "1-2 short sentences naming the most common form errors",\n'
            '  "pro_tip": "1 short sentence with an advanced cue or progression tip",\n'
            '  "muscles_focused": ["primary mover", "secondary mover", "stabilizer"]\n'
            "}\n\n"
            "Constraints:\n"
            "- Each text field <= 220 characters.\n"
            "- muscles_focused: 1-4 lowercase muscle names (e.g. 'quadriceps', 'glutes').\n"
            "- No emojis, no fluff, no disclaimers.\n"
        )

        prompt = f"{system_prompt}\n\n{details_block}\n\nReturn JSON only."

        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.4,
                max_output_tokens=600,
            ),
            user_id=user_id,
            method_name="exercise_insights",
            timeout=15.0,
        )

        raw = (response.text or "").strip()
        if not raw:
            logger.warning(
                f"[ai/exercise-insights] empty Gemini response for {body.exercise_name!r}"
            )
            return ExerciseInsightsResponse()

        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            # Strip markdown code fences if Gemini ignored response_mime_type.
            cleaned = raw
            if cleaned.startswith("```"):
                cleaned = cleaned.split("```", 2)[-1]
                if cleaned.lstrip().lower().startswith("json"):
                    cleaned = cleaned.lstrip()[4:]
                cleaned = cleaned.rsplit("```", 1)[0].strip()
            try:
                parsed = json.loads(cleaned)
            except json.JSONDecodeError as e:
                logger.error(
                    f"[ai/exercise-insights] JSON parse failed for {body.exercise_name!r}: {e} | raw={raw[:200]}"
                )
                return ExerciseInsightsResponse()

        if not isinstance(parsed, dict):
            return ExerciseInsightsResponse()

        muscles = parsed.get("muscles_focused") or []
        if not isinstance(muscles, list):
            muscles = []
        muscles = [str(m).strip() for m in muscles if str(m).strip()][:6]

        return ExerciseInsightsResponse(
            form_cues=str(parsed.get("form_cues") or "").strip(),
            common_mistakes=str(parsed.get("common_mistakes") or "").strip(),
            pro_tip=str(parsed.get("pro_tip") or "").strip(),
            muscles_focused=muscles,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"[ai/exercise-insights] failed for {body.exercise_name!r}: {e}",
            exc_info=True,
        )
        # Return empty insights rather than 500 so the Flutter client's local
        # fallback logic (in exercise_info_service.dart) seamlessly takes over.
        return ExerciseInsightsResponse()
