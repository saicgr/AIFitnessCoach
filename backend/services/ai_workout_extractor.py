"""
AI Workout Extractor — unified pipeline for extracting a structured, reviewable
workout from a photo / screenshot, a short video, or pasted free text.

All three methods return a dict shaped like:

    {
      "name": "Push Day A",
      "workout_type": "strength",
      "difficulty": "medium",                 # easy | medium | hard | hell
      "estimated_duration_minutes": 45,
      "exercises": [
        {"name": "Barbell Bench Press", "sets": 4, "reps": 8,
         "rest_seconds": 120, "duration_seconds": null, "weight_kg": 60.0,
         "muscle_group": "chest", "notes": null},
        ...
      ],
      "confidence": 0.82                        # photo/text omit; video includes
    }

The caller (`POST /saved-workouts/import-ai`) returns this dict to the client
for review; on confirm the client calls `POST /saved-workouts/import-ai/save`
which persists it into the `workouts` table tagged generation_method/source =
'ai_import' (so the Custom pill shows it).

Design principles (mirrors ai_exercise_extractor.py + CLAUDE.md):
- NO mocks, NO silent fallbacks. Raise on unparseable / empty responses.
- Extensive 🤖 / 🏋️ / ✅ / ⚠️ / ❌ logging.
- JSON parsing strips ```json fences before json.loads.
- Difficulty is normalised to the workouts namespace {easy, medium, hard, hell}.
- Weights are emitted in KILOGRAMS (the workouts table stores weight_kg); the
  Flutter layer converts to the user's display unit (lbs) downstream.
"""

from __future__ import annotations

import json
import logging
import os
import re
import tempfile
from typing import Any, Dict, List, Optional

import boto3
from google.genai import types

from core.config import get_settings
from models.gemini_schemas import ImportedWorkoutResponse
from services.gemini.constants import gemini_generate_with_retry
from services.keyframe_extractor import extract_key_frames

logger = logging.getLogger(__name__)


# =============================================================================
# Canonical vocabularies
# =============================================================================

# `workouts.difficulty` is strictly {easy, medium, hard, hell} (see
# models/schemas.py::ALLOWED_WORKOUT_DIFFICULTIES). Map the fitness-level and
# AI-synonym drift the same way the schema validator does, so the reviewed
# workout never 500s the create path.
VALID_DIFFICULTIES = ["easy", "medium", "hard", "hell"]
_DIFFICULTY_ALIASES = {
    "beginner": "easy",
    "intermediate": "medium",
    "advanced": "hard",
    "moderate": "medium",
    "normal": "medium",
    "intense": "hard",
    "extreme": "hell",
    "insane": "hell",
}

# Loose vocabulary for workout_type — kept permissive (it's a free-text column
# on `workouts.type`) but normalised to a known set when we recognise it.
VALID_WORKOUT_TYPES = [
    "strength", "cardio", "hiit", "mobility", "full_body",
    "push", "pull", "legs", "upper", "lower", "core",
]


# =============================================================================
# Prompts
# =============================================================================

_SCHEMA_BLOCK = """{
  "name":                        "<string — concise workout title; infer one if absent>",
  "workout_type":                "<one of: strength, cardio, hiit, mobility, full_body, push, pull, legs, upper, lower, core>",
  "difficulty":                  "<one of: easy, medium, hard, hell>",
  "estimated_duration_minutes":  <int 1-480>,
  "exercises": [
    {
      "name":             "<string — standard gym name, expand abbreviations>",
      "sets":             <int 1-20>,
      "reps":             <int 1-100; use a representative value for ranges, 1 for timed>,
      "rest_seconds":     <int or null>,
      "duration_seconds": <int or null — for timed moves>,
      "weight_kg":        <float or null — KG; convert lbs*0.4536>,
      "muscle_group":     "<string or null>",
      "notes":            "<string or null — only if explicitly present>"
    }
  ],
  "confidence": <float 0.0-1.0>
}"""

_COMMON_RULES = """Rules:
- Extract EVERY exercise in source order. Do NOT invent exercises that aren't present.
- name MUST be standard gym terminology with abbreviations expanded (OHP -> Overhead Press, RDL -> Romanian Deadlift, BB -> Barbell, DB -> Dumbbell).
- difficulty MUST be exactly one of: easy, medium, hard, hell (map beginner->easy, intermediate->medium, advanced->hard).
- weight_kg MUST be in kilograms. If the source uses lbs, convert (lbs * 0.4536). Use null when no load is given or the move is bodyweight.
- Use reps for rep-based moves and duration_seconds for timed moves (plank, carry, interval). Exactly one of the two should be meaningful per exercise.
- Only populate notes with a modifier ACTUALLY present in the source (AMRAP, each side, tempo, drop set). Never fabricate cues.
- Return ONLY JSON matching the shape — no markdown fences, no preamble.
"""

_PHOTO_PROMPT_TEMPLATE = (
    "You are reading a workout from an image — it may be a gym whiteboard, a "
    "screenshot of another fitness app, a handwritten plan, or a printed routine. "
    "Extract the complete workout as structured data.\n"
    "{hint_block}\n"
    "Return JSON with this exact shape:\n{schema}\n\n{rules}"
)

_VIDEO_FRAME_PROMPT_TEMPLATE = (
    "This is one keyframe from a short video that shows a workout plan (a screen "
    "recording of an app, a coach reading off a board, or a written routine). "
    "Extract the complete workout visible in this frame.\n"
    "{hint_block}\n"
    "Return JSON with this exact shape:\n{schema}\n\n{rules}\n"
    "Set \"confidence\" honestly given that this is a single frame."
)

_TEXT_PROMPT_TEMPLATE = (
    "Parse the following workout text into a structured workout. The text may be "
    "a pasted routine, a list of exercises, or a loosely-formatted plan:\n"
    "'''{raw_text}'''\n"
    "{hint_block}\n"
    "Return JSON with this exact shape:\n{schema}\n\n{rules}"
)


# =============================================================================
# Helpers
# =============================================================================

def _strip_json_fences(text: str) -> str:
    """Remove ```json ... ``` fences Gemini sometimes emits despite mime_type=application/json."""
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = re.sub(r"^```(?:json)?\s*", "", stripped)
        stripped = re.sub(r"\s*```$", "", stripped)
    return stripped.strip()


def _parse_json_strict(raw: str) -> Dict[str, Any]:
    """Parse Gemini JSON output or raise a clear ValueError (no silent fallback)."""
    cleaned = _strip_json_fences(raw)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError as e:
        match = re.search(r"\{.*\}", cleaned, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(0))
            except json.JSONDecodeError:
                pass
        logger.error(f"❌ [AiWorkoutExtractor] JSON parse failed: {e}. Raw={cleaned[:500]!r}")
        raise ValueError(f"AI returned invalid JSON: {e}") from e


def _coerce_int(value: Any, lo: int, hi: int, default: Optional[int]) -> Optional[int]:
    if value is None:
        return default
    try:
        v = int(round(float(value)))
    except (TypeError, ValueError):
        return default
    return max(lo, min(hi, v))


def _coerce_float(value: Any, lo: float, hi: float) -> Optional[float]:
    if value is None:
        return None
    try:
        v = float(value)
    except (TypeError, ValueError):
        return None
    if v <= 0:
        return None
    return max(lo, min(hi, v))


def _normalize_difficulty(value: Any) -> str:
    if not value:
        return "medium"
    v = str(value).strip().lower()
    if v in VALID_DIFFICULTIES:
        return v
    return _DIFFICULTY_ALIASES.get(v, "medium")


def _normalize_workout_type(value: Any) -> str:
    if not value:
        return "strength"
    v = str(value).strip().lower().replace(" ", "_").replace("-", "_")
    if v in VALID_WORKOUT_TYPES:
        return v
    # Light fuzzy: pick the first known type contained in the string.
    for t in VALID_WORKOUT_TYPES:
        if t in v:
            return t
    return "strength"


def _normalize_exercise(raw: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Normalise a single extracted exercise dict; return None if it has no name."""
    name = (raw.get("name") or "").strip()
    if not name:
        return None

    sets = _coerce_int(raw.get("sets"), 1, 20, 3)
    reps = _coerce_int(raw.get("reps"), 1, 100, None)
    duration_seconds = _coerce_int(raw.get("duration_seconds"), 1, 3600, None)
    rest_seconds = _coerce_int(raw.get("rest_seconds"), 0, 600, None)
    weight_kg = _coerce_float(raw.get("weight_kg"), 0.5, 1000.0)

    # Guarantee at least one of reps / duration so the move is runnable.
    if reps is None and duration_seconds is None:
        reps = 10

    notes = (raw.get("notes") or "").strip() or None
    muscle_group = (raw.get("muscle_group") or "").strip() or None

    return {
        "name": name[:200],
        "sets": sets,
        "reps": reps,
        "rest_seconds": rest_seconds if rest_seconds is not None else 60,
        "duration_seconds": duration_seconds,
        "weight_kg": weight_kg,
        "muscle_group": muscle_group,
        "notes": notes,
    }


def _normalize_payload(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Normalise a Gemini JSON payload into the reviewable workout shape."""
    exercises_raw = raw.get("exercises")
    if not isinstance(exercises_raw, list):
        raise ValueError("AI response missing an 'exercises' list")

    exercises: List[Dict[str, Any]] = []
    for ex in exercises_raw:
        if isinstance(ex, dict):
            normalized = _normalize_exercise(ex)
            if normalized:
                exercises.append(normalized)

    if not exercises:
        raise ValueError("No exercises could be extracted from the source")

    name = (raw.get("name") or "").strip() or "Imported Workout"
    duration = _coerce_int(raw.get("estimated_duration_minutes"), 1, 480, None)
    if duration is None:
        # Rough estimate: ~5 min per exercise, clamped to the column range.
        duration = max(1, min(480, len(exercises) * 5))

    confidence = _coerce_float(raw.get("confidence"), 0.0, 1.0)

    return {
        "name": name[:200],
        "workout_type": _normalize_workout_type(raw.get("workout_type") or raw.get("type")),
        "difficulty": _normalize_difficulty(raw.get("difficulty")),
        "estimated_duration_minutes": duration,
        "exercises": exercises,
        "confidence": confidence,
    }


def _hint_block(user_hint: Optional[str]) -> str:
    if user_hint and user_hint.strip():
        return f'User hint: "{user_hint.strip()}" (use this if it resolves ambiguity).'
    return ""


# =============================================================================
# Extractor
# =============================================================================

class AiWorkoutExtractor:
    """
    Extract a structured, reviewable workout from photo / video / text.

    Usage:
        extractor = get_ai_workout_extractor()
        workout = await extractor.extract_from_text("Push day: bench 4x8, OHP 3x10...")
        # workout is ready to return to the client for review.
    """

    def __init__(self, vision_service: Any = None):
        self._settings = get_settings()
        self._vision_service = vision_service  # exposes _s3_client + _bucket
        self._s3_client = None
        self._bucket = None
        if vision_service is not None:
            self._s3_client = getattr(vision_service, "_s3_client", None)
            self._bucket = getattr(vision_service, "_bucket", None)
        if self._s3_client is None and self._settings.aws_access_key_id:
            self._s3_client = boto3.client(
                "s3",
                aws_access_key_id=self._settings.aws_access_key_id,
                aws_secret_access_key=self._settings.aws_secret_access_key,
                region_name=self._settings.aws_default_region,
            )
            self._bucket = self._settings.s3_bucket_name

    # ---------------------------------------------------------------- Public API

    async def extract_from_photo(
        self,
        s3_key: Optional[str] = None,
        user_hint: Optional[str] = None,
        *,
        image_bytes: Optional[bytes] = None,
        mime_type: str = "image/jpeg",
    ) -> Dict[str, Any]:
        """Extract a workout from a single photo/screenshot.

        Accepts either an `s3_key` (we download the bytes) or direct `image_bytes`.
        """
        if image_bytes is None:
            if not s3_key:
                raise ValueError("extract_from_photo requires either s3_key or image_bytes")
            image_bytes = self._download_s3_bytes(s3_key)

        logger.info(f"🤖 [AiWorkoutExtractor] extract_from_photo (bytes={len(image_bytes)}, hint={user_hint!r})")

        prompt = _PHOTO_PROMPT_TEMPLATE.format(
            hint_block=_hint_block(user_hint),
            schema=_SCHEMA_BLOCK,
            rules=_COMMON_RULES,
        )

        image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
        response = await gemini_generate_with_retry(
            model=self._settings.gemini_model,
            contents=[prompt, image_part],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=ImportedWorkoutResponse,
                temperature=0.2,
                max_output_tokens=3000,
            ),
            method_name="ai_workout_extractor.photo",
        )

        raw_text = getattr(response, "text", "") or ""
        if not raw_text.strip():
            raise ValueError("Gemini returned empty response for photo workout extraction")

        payload = _normalize_payload(_parse_json_strict(raw_text))
        logger.info(
            f"✅ [AiWorkoutExtractor] photo → '{payload['name']}' "
            f"({len(payload['exercises'])} exercises, {payload['difficulty']})"
        )
        return payload

    async def extract_from_text(
        self,
        raw_text: str,
        user_hint: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Extract a workout from pasted free text."""
        if not raw_text or not raw_text.strip():
            raise ValueError("extract_from_text requires non-empty raw_text")

        logger.info(f"🤖 [AiWorkoutExtractor] extract_from_text '{raw_text[:80]}...'")

        prompt = _TEXT_PROMPT_TEMPLATE.format(
            raw_text=raw_text.strip()[:8000],
            hint_block=_hint_block(user_hint),
            schema=_SCHEMA_BLOCK,
            rules=_COMMON_RULES,
        )

        response = await gemini_generate_with_retry(
            model=self._settings.gemini_model,
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=ImportedWorkoutResponse,
                temperature=0.2,
                max_output_tokens=3000,
            ),
            method_name="ai_workout_extractor.text",
        )

        raw_response = getattr(response, "text", "") or ""
        if not raw_response.strip():
            raise ValueError("Gemini returned empty response for text workout extraction")

        payload = _normalize_payload(_parse_json_strict(raw_response))
        logger.info(
            f"✅ [AiWorkoutExtractor] text → '{payload['name']}' "
            f"({len(payload['exercises'])} exercises, {payload['difficulty']})"
        )
        return payload

    async def extract_from_video(
        self,
        s3_key: str,
        user_hint: Optional[str] = None,
        num_frames: int = 3,
    ) -> Dict[str, Any]:
        """
        Extract a workout from a short video by analysing `num_frames` keyframes
        and merging into the most complete extraction (most exercises wins, ties
        broken by confidence).
        """
        if not s3_key:
            raise ValueError("extract_from_video requires s3_key")

        logger.info(f"🤖 [AiWorkoutExtractor] extract_from_video s3_key={s3_key} (num_frames={num_frames})")

        video_bytes = self._download_s3_bytes(s3_key)

        suffix = os.path.splitext(s3_key)[1] or ".mp4"
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            tmp.write(video_bytes)
            tmp_path = tmp.name

        try:
            frames = await extract_key_frames(tmp_path, num_frames=num_frames)
        finally:
            try:
                os.unlink(tmp_path)
            except OSError:
                pass

        if not frames:
            raise ValueError("Failed to extract any keyframes from video — file may be corrupt or unsupported")

        logger.info(f"🏋️ [AiWorkoutExtractor] extracted {len(frames)} keyframes for analysis")

        prompt = _VIDEO_FRAME_PROMPT_TEMPLATE.format(
            hint_block=_hint_block(user_hint),
            schema=_SCHEMA_BLOCK,
            rules=_COMMON_RULES,
        )

        frame_results: List[Dict[str, Any]] = []
        for idx, (jpeg_bytes, mime) in enumerate(frames):
            try:
                image_part = types.Part.from_bytes(data=jpeg_bytes, mime_type=mime)
                response = await gemini_generate_with_retry(
                    model=self._settings.gemini_model,
                    contents=[prompt, image_part],
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=ImportedWorkoutResponse,
                        temperature=0.2,
                        max_output_tokens=3000,
                    ),
                    method_name=f"ai_workout_extractor.video_frame_{idx}",
                )
                raw_text = getattr(response, "text", "") or ""
                if not raw_text.strip():
                    logger.warning(f"⚠️ [AiWorkoutExtractor] frame {idx}: empty response")
                    continue
                payload = _normalize_payload(_parse_json_strict(raw_text))
                frame_results.append(payload)
                logger.info(
                    f"🤖 [AiWorkoutExtractor] frame {idx}: '{payload['name']}' "
                    f"({len(payload['exercises'])} exercises, conf={payload.get('confidence')})"
                )
            except Exception as e:
                logger.warning(f"⚠️ [AiWorkoutExtractor] frame {idx} failed: {e}", exc_info=True)
                continue

        if not frame_results:
            raise ValueError("All keyframe extractions failed — unable to read the workout")

        # Pick the richest extraction: most exercises, then highest confidence.
        best = max(
            frame_results,
            key=lambda p: (len(p["exercises"]), p.get("confidence") or 0.0),
        )
        logger.info(
            f"✅ [AiWorkoutExtractor] video merged → '{best['name']}' "
            f"({len(best['exercises'])} exercises) from {len(frame_results)} frame(s)"
        )
        return best

    # --------------------------------------------------------------- Internals

    def _download_s3_bytes(self, s3_key: str) -> bytes:
        """Download an object from S3 and return its bytes. Raises on error."""
        if self._s3_client is None or not self._bucket:
            raise RuntimeError(
                "S3 client unavailable — cannot download s3_key. "
                "Check AWS credentials and S3_BUCKET_NAME config."
            )
        try:
            resp = self._s3_client.get_object(Bucket=self._bucket, Key=s3_key)
            return resp["Body"].read()
        except Exception as e:
            logger.error(f"❌ [AiWorkoutExtractor] S3 download failed for {s3_key}: {e}", exc_info=True)
            raise


# Singleton
_extractor: Optional[AiWorkoutExtractor] = None


def get_ai_workout_extractor() -> AiWorkoutExtractor:
    global _extractor
    if _extractor is None:
        try:
            from services.vision_service import get_vision_service
            vs = get_vision_service()
        except Exception as e:
            logger.warning(f"⚠️ [AiWorkoutExtractor] vision_service unavailable: {e}")
            vs = None
        _extractor = AiWorkoutExtractor(vision_service=vs)
    return _extractor
