"""
Onboarding coach-preview chat — the "try your coach" live turn.

Stateless by design: one persona-voiced Gemini reply per call, capped small,
with NO chat_history writes and NO session creation. Onboarding previews must
never surface later inside the user's real coach chat, and a preview bug must
not be able to corrupt anything real. The client enforces a 2-live-turn cap
per coach; this endpoint adds a server-side rate limit behind it.

Failure contract: this endpoint NEVER 500s for model problems. Any Gemini
error, timeout, or safety block returns a persona-appropriate canned reply
with fallback=true so the client can visibly degrade to its curated answers
(and retire the input) instead of stranding the user mid-purchase-decision.
"""

import asyncio
from typing import Optional

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.logger import get_logger
from core.rate_limiter import limiter
from services.gemini_service import GeminiService

# Single source of truth for persona voices — same tables that power
# per-exercise coach tips, so the preview voice IS the in-app voice.
from api.v1.workouts.exercise_tips import STYLE_SYSTEM_PROMPTS, TONE_MODIFIERS

router = APIRouter()
logger = get_logger(__name__)

_gemini_service: Optional[GeminiService] = None


def _get_gemini() -> GeminiService:
    global _gemini_service
    if _gemini_service is None:
        _gemini_service = GeminiService()
    return _gemini_service


class CoachPreviewContext(BaseModel):
    """Compact quiz context the client already holds — passed through so the
    reply can be personal without a DB read (the endpoint stays stateless)."""

    goal: Optional[str] = Field(default=None, max_length=60)
    fitness_level: Optional[str] = Field(default=None, max_length=30)
    days_per_week: Optional[int] = Field(default=None, ge=1, le=7)
    injuries: Optional[str] = Field(default=None, max_length=120)


class CoachPreviewRequest(BaseModel):
    coach_id: str = Field(max_length=50)
    coach_name: str = Field(default="Coach", max_length=40)
    coaching_style: str = Field(default="motivational", max_length=30)
    communication_tone: str = Field(default="encouraging", max_length=30)
    encouragement_level: float = Field(default=0.7, ge=0.0, le=1.0)
    question: str = Field(min_length=1, max_length=200)
    # True on the user's last allowed turn — the reply should close by
    # inviting them to start training together (the conversion beat).
    final_turn: bool = False
    context: Optional[CoachPreviewContext] = None
    locale: str = Field(default="en", max_length=8)


class CoachPreviewResponse(BaseModel):
    reply: str
    fallback: bool = False


# Persona-voiced canned replies for the failure path. The client shows these
# under a visible "coach is busy" label — never as a fake live answer.
_FALLBACK_REPLIES = {
    "motivational": (
        "Great question — and the honest answer is the plan adapts to "
        "everything you log, every session. Pick me and I'll show you in "
        "your first week!"
    ),
    "scientist": (
        "Good question. The short, evidence-based answer: the plan "
        "recalibrates from every set you log. Start your first week and "
        "I'll show you the data."
    ),
    "drill-sergeant": (
        "Good question, recruit. Answer's simple: you log the work, the "
        "plan adapts. Hit the button and see for yourself."
    ),
    "zen-master": (
        "A thoughtful question. The plan bends around your life — every "
        "session adapts to you. Begin your first week and feel it."
    ),
    "hype-beast": (
        "GREAT question — short version: the plan levels up with you every "
        "single session. Smash that button and let's find out together!"
    ),
}


def _build_system_prompt(body: CoachPreviewRequest) -> str:
    style = STYLE_SYSTEM_PROMPTS.get(
        body.coaching_style, STYLE_SYSTEM_PROMPTS["motivational"]
    ).format(coach_name=body.coach_name)

    tone = TONE_MODIFIERS.get(body.communication_tone, "")
    parts = [style]
    if tone:
        parts.append(tone)
    if body.encouragement_level > 0.8:
        parts.append("Be extra encouraging and hype them up.")
    elif body.encouragement_level < 0.3:
        parts.append("Keep encouragement minimal — focus on substance.")

    parts.append(
        "Setting: the user is in app onboarding, previewing coaches before "
        "choosing one. They asked you ONE question. Answer it directly and "
        "personally in your voice, 2-4 short sentences, under 320 characters. "
        "No lists, no markdown, no hashtags. Never invent specific workout "
        "numbers, medical advice, or app features; if asked something outside "
        "fitness coaching, steer warmly back to training."
    )
    if body.final_turn:
        parts.append(
            "This is their last preview question: END your reply with one "
            "short, in-character invitation to pick you and start their "
            "first week."
        )

    ctx = body.context
    if ctx:
        facts = []
        if ctx.goal:
            facts.append(f"goal: {ctx.goal}")
        if ctx.fitness_level:
            facts.append(f"level: {ctx.fitness_level}")
        if ctx.days_per_week:
            facts.append(f"trains {ctx.days_per_week} days/week")
        if ctx.injuries:
            facts.append(f"reported limitation: {ctx.injuries}")
        if facts:
            parts.append(
                "What you know about them (weave in naturally when relevant, "
                "don't recite): " + "; ".join(facts) + "."
            )

    # Reinforce the persona voice LAST, immediately before generation — short
    # factual replies otherwise tend to default to neutral coaching language,
    # washing out what should be a clearly distinct coach-to-coach tone.
    parts.append(
        f"Stay unmistakably in {body.coach_name}'s voice described above — "
        "don't flatten into neutral, generic coaching language just because "
        "the reply is short."
    )
    return " ".join(parts)


def _fallback(body: CoachPreviewRequest) -> CoachPreviewResponse:
    reply = _FALLBACK_REPLIES.get(
        body.coaching_style, _FALLBACK_REPLIES["motivational"]
    )
    return CoachPreviewResponse(reply=reply, fallback=True)


@router.post("/coach-preview", response_model=CoachPreviewResponse)
@limiter.limit("15/hour")
async def coach_preview(
    body: CoachPreviewRequest,
    request: Request,
    user=Depends(get_current_user),
):
    """One live persona reply for the onboarding coach preview chat."""
    try:
        response = await asyncio.wait_for(
            _get_gemini().chat(
                user_message=body.question,
                system_prompt=_build_system_prompt(body),
                locale=body.locale,
            ),
            # Tighter than the service's own 60s ceiling: the client shows a
            # typing beat and gives up at 12s — replies slower than that land
            # after the client already fell back. Wider margin than before
            # (was 7s server / 8s client, ~1s of network headroom) so real
            # live replies land more often instead of silently degrading to
            # the canned _FALLBACK_REPLIES.
            timeout=6.5,
        )
        reply = (response or "").strip().strip('"').strip("'")
        if not reply:
            # Safety-filtered / empty → visible fallback, never a blank bubble.
            return _fallback(body)
        if len(reply) > 400:
            cut = reply[:400]
            period = cut.rfind(".")
            reply = cut[: period + 1] if period > 200 else cut[:397] + "..."
        return CoachPreviewResponse(reply=reply, fallback=False)
    except Exception as exc:  # noqa: BLE001 — model errors degrade, never 500
        logger.warning(
            "coach-preview fell back (coach=%s): %s", body.coach_id, exc
        )
        return _fallback(body)
