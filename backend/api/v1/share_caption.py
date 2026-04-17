"""Share caption generator — AI-written humble-brag + roast captions.

POST /api/v1/share-templates/caption

Input: workout stats (name, volume, sets, duration, top exercise, PR
info, mode=hype|humble|roast). Output: a short (< 240 char) caption
suitable for paste-into-Instagram with optional emoji.

Uses the existing GeminiService so we don't add another model dep.
"""
from typing import Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.logger import get_logger
from services.gemini_service import GeminiService

router = APIRouter()
logger = get_logger(__name__)


class CaptionBody(BaseModel):
    workout_name: str
    volume_display: str = Field(..., description="e.g. '6,670 lb' or '3,025 kg'")
    sets: int
    duration_seconds: int
    top_exercise: Optional[str] = None
    pr_count: int = 0
    mode: str = Field(default="hype", description="'hype' | 'humble' | 'roast'")


@router.post("/share-templates/caption")
async def generate_caption(
    body: CaptionBody,
    current_user: dict = Depends(get_current_user),
) -> dict:
    mins = max(1, body.duration_seconds // 60)
    mode = body.mode if body.mode in ("hype", "humble", "roast") else "hype"
    tone = {
        "hype": "HYPED and celebratory, use strong verbs and an emoji or two",
        "humble": "understated and humble, no hashtags, no emojis",
        "roast": "self-deprecating roast-comedy, mock the user gently about how hard they go",
    }[mode]
    pr_line = f"They hit {body.pr_count} new PR(s)." if body.pr_count > 0 else ""
    top_line = f"Biggest move: {body.top_exercise}." if body.top_exercise else ""

    prompt = f"""Write a short Instagram caption (under 220 characters) for a gym workout share.
Tone: {tone}.
Workout: {body.workout_name}. {body.sets} sets across {mins} minutes. Total volume {body.volume_display}.
{top_line}
{pr_line}

Rules:
- Single line, no line breaks.
- Under 220 chars INCLUDING any emoji.
- Never put the user's name in the caption.
- Never use generic clichés like "hard work pays off" or "no pain no gain".
- The caption is POSTED BY the lifter about their own workout; first person is fine.
- Return ONLY the caption text. No quotes, no explanation.
""".strip()

    try:
        svc = GeminiService()
        resp = await svc.chat_response(
            prompt,
            system_instruction="You are a copywriter who writes tight, specific, shareable social captions.",
            temperature=0.9,
        )
        text = (resp or "").strip().strip('"').strip("'")
        if not text:
            raise ValueError("empty response")
        # Trim to hard 240 char cap
        if len(text) > 240:
            text = text[:237].rstrip() + "..."
        return {"caption": text, "mode": mode}
    except Exception as e:
        logger.warning(f"[share-caption] Gemini failed, using fallback: {e}")
        fallback = _fallback_caption(body, mode)
        return {"caption": fallback, "mode": mode, "fallback": True}


def _fallback_caption(body: CaptionBody, mode: str) -> str:
    mins = max(1, body.duration_seconds // 60)
    base = f"{body.workout_name} · {body.volume_display} · {body.sets} sets · {mins} min"
    if mode == "roast":
        return f"{base}. Someone tell my back I'm sorry."
    if mode == "humble":
        return f"{base}. Trying to stay consistent."
    return f"🔥 Crushed {base}."
