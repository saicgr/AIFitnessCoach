"""
Chat-session title generation (migration 2218).

Generates a concise 3-5 word title from a session's first user message, the way
ChatGPT/Gemini name conversations. Runs as a BackgroundTask after the first
reply, so it never adds latency. Falls back to a cleaned, truncated version of
the message on any failure — a session always ends up with a usable title.
"""
from __future__ import annotations

import logging
import re
from typing import Optional

from google.genai import types

from core.config import get_settings
from services.gemini.constants import gemini_generate_with_retry

logger = logging.getLogger("coach_session_title")

_SYSTEM = (
    "You title a fitness-app chat conversation. Given the user's first message, "
    "return a SHORT 3-5 word title in Title Case, no quotes, no trailing "
    "punctuation, no emoji. Capture the topic, not the phrasing. "
    "Examples: 'Full Body Workout Plan', 'Post-Workout Nutrition', "
    "'Lower Back Pain Help', 'Cutting Macros Setup'. Return ONLY the title."
)


def _fallback_title(message: str) -> str:
    """Cleaned, truncated first message — the deterministic fallback."""
    s = re.sub(r"\s+", " ", (message or "").strip())
    if not s:
        return "New chat"
    words = s.split(" ")
    title = " ".join(words[:6])
    if len(title) > 48:
        title = title[:45].rstrip() + "..."
    return title[0].upper() + title[1:] if title else "New chat"


async def generate_title(*, user_id: str, first_message: str) -> str:
    """Return a generated title, or a deterministic fallback on any failure."""
    msg = (first_message or "").strip()
    if not msg:
        return "New chat"
    settings = get_settings()
    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=msg[:500],
            config=types.GenerateContentConfig(
                system_instruction=_SYSTEM,
                max_output_tokens=20,
                temperature=0.3,
            ),
            user_id=user_id,
            timeout=8.0,
            method_name="session_title",
        )
        text = (getattr(response, "text", None) or "").strip()
        # Strip stray quotes / fences / trailing punctuation.
        text = text.strip().strip('"').strip("'").rstrip(".!").strip()
        text = re.sub(r"\s+", " ", text)
        if text and 1 <= len(text.split(" ")) <= 7 and len(text) <= 60:
            return text
    except Exception as e:
        logger.warning(f"[session_title] generation failed: {e}")
    return _fallback_title(msg)


async def generate_and_store_title(*, user_id: str, session_id: str, first_message: str) -> None:
    """BackgroundTask entry: generate a title and store it only if the session
    still has none (won't clobber a user rename). Never raises."""
    try:
        from core.db import get_supabase_db
        title = await generate_title(user_id=user_id, first_message=first_message)
        get_supabase_db().sessions.set_title_if_unset(session_id, user_id, title)
    except Exception as e:
        logger.warning(f"[session_title] store failed for {session_id}: {e}")
