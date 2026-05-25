"""
audio_transcriber.py — wraps Gemini's audio-understanding endpoint.

Returns a plain-text transcript and a short content hint that the
downstream intent classifier consumes. Used by the Imports feature for
voice memos shared from the iOS / Android share sheet.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Optional

from google.genai import types

from core.config import get_settings
from services.gemini.constants import gemini_generate_with_retry

logger = logging.getLogger(__name__)
settings = get_settings()


@dataclass
class AudioUnderstanding:
    transcript: str
    content_hint: Optional[str]   # one of: workout_log | food_log | tip | question | other


_AUDIO_PROMPT = """You are a fitness-app audio-understanding helper.

Transcribe the audio EXACTLY (verbatim), then on a separate line emit a
single tag indicating what the speaker is doing. Format your reply as:

TRANSCRIPT:
<full transcript here>

HINT:
<one of: workout_log | food_log | tip | question | other>

Use:
- workout_log : narrating sets/reps/weights they just did or are planning
- food_log    : describing food they ate ("had pizza and a Coke")
- tip         : trainer-style advice, motivation, technique cue
- question    : asking the app a question
- other       : anything else
"""


async def transcribe_and_hint(audio_bytes: bytes, mime_type: str = "audio/mp4") -> AudioUnderstanding:
    """Run the Gemini audio understanding call.

    Returns an `AudioUnderstanding` even on failure (transcript=""), so the
    orchestrator can decide whether to fall back to a 'discuss' route.
    """
    try:
        audio_part = types.Part.from_bytes(data=audio_bytes, mime_type=mime_type)
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=[_AUDIO_PROMPT, audio_part],
            config=types.GenerateContentConfig(
                temperature=0.1,
                max_output_tokens=2000,
            ),
            method_name="share_audio_understand",
        )
        raw = (response.text or "").strip()
        return _parse(raw)
    except Exception as e:
        logger.warning(f"[AudioTranscriber] failed: {e}", exc_info=True)
        return AudioUnderstanding(transcript="", content_hint=None)


_VALID_HINTS = {"workout_log", "food_log", "tip", "question", "other"}


def _parse(raw: str) -> AudioUnderstanding:
    if not raw:
        return AudioUnderstanding(transcript="", content_hint=None)
    transcript = ""
    hint: Optional[str] = None
    lines = raw.splitlines()
    section = None
    for ln in lines:
        s = ln.strip()
        if s.upper().startswith("TRANSCRIPT:"):
            section = "transcript"
            tail = s.split(":", 1)[1].strip()
            if tail:
                transcript += tail + "\n"
            continue
        if s.upper().startswith("HINT:"):
            section = "hint"
            tail = s.split(":", 1)[1].strip().lower()
            if tail in _VALID_HINTS:
                hint = tail
            continue
        if section == "transcript":
            transcript += ln + "\n"
        elif section == "hint" and hint is None:
            cand = s.lower()
            if cand in _VALID_HINTS:
                hint = cand
    return AudioUnderstanding(transcript=transcript.strip(), content_hint=hint)
