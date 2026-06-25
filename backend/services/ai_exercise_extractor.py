"""
AI Exercise Extractor — unified pipeline for extracting structured custom-exercise
metadata from a photo, a short video, or a free-text description.

All three methods return a dict shaped like `CustomExerciseCreate` so the caller
(`POST /custom-exercises/{user_id}/import`) can hand the dict directly to
`create_custom_exercise()`.

Design principles (see CLAUDE.md):
- NO mocks, NO silent fallbacks. Raise on unparseable responses.
- Extensive 🤖 / 🏋️ / ✅ / ⚠️ / ❌ logging.
- JSON parsing strips ```json fences before `json.loads`.
- Weight units are lbs (we don't emit any weight fields here — just reps/sec).
"""

from __future__ import annotations

import base64
import json
import logging
import os
import re
import tempfile
from typing import Any, Dict, List, Optional

import boto3
from google.genai import types

from core.config import get_settings
from services.gemini.constants import gemini_generate_with_retry
from services.keyframe_extractor import extract_key_frames

logger = logging.getLogger(__name__)


# =============================================================================
# Canonical vocabularies
# =============================================================================
# Mirrors the values used by `custom_exercises.py::VALID_MUSCLE_GROUPS` /
# `VALID_EQUIPMENT` so the resulting rows index cleanly into ChromaDB alongside
# the library taxonomy. Keep these in sync with migration 202_custom_exercises.sql.

VALID_MUSCLE_GROUPS: List[str] = [
    "chest", "back", "shoulders", "biceps", "triceps", "forearms",
    "abs", "core", "quadriceps", "hamstrings", "glutes", "calves", "full body",
]

VALID_EQUIPMENT: List[str] = [
    "bodyweight", "dumbbell", "barbell", "kettlebell", "cable",
    "machine", "resistance band", "medicine ball", "slam ball", "other",
]

VALID_EXERCISE_TYPES = ["strength", "cardio", "warmup", "stretch", "mobility", "plyometric"]
VALID_MOVEMENT_TYPES = ["static", "dynamic", "isometric"]
VALID_DIFFICULTIES = ["beginner", "intermediate", "advanced"]

# Composite/combo taxonomy — mirrors `exercises_endpoints.py::CompositeExerciseCreate.combo_type`
# and `ComponentExercise`. A combo preview built here is shaped so the frontend can hand it
# straight to `POST /custom-exercises/{user_id}/composite` (the persisting create endpoint).
VALID_COMBO_TYPES = ["superset", "compound_set", "giant_set", "complex", "hybrid"]

VALID_BODY_PARTS = [
    "chest", "back", "legs", "shoulders", "arms", "core",
    "cardio", "full body", "glutes", "calves",
]


# =============================================================================
# Prompts
# =============================================================================

# The JSON schema description we feed to Gemini. Keep the field names
# identical to the Pydantic `CustomExerciseCreate` model so we can hand the
# parsed dict straight to the create endpoint.
_SCHEMA_BLOCK = f"""{{
  "name":                      "<string — human-readable exercise name, Title Case>",
  "description":               "<string — 1-2 sentence overview (max 1000 chars)>",
  "instructions":              ["<string>", "..."],   // 3-6 concise step-by-step cues
  "body_part":                 "<one of: {', '.join(VALID_BODY_PARTS)}>",
  "target_muscles":            ["<one of: {', '.join(VALID_MUSCLE_GROUPS)}>"],
  "secondary_muscles":         ["<optional, same vocabulary as target_muscles>"],
  "equipment":                 "<one of: {', '.join(VALID_EQUIPMENT)}>",
  "exercise_type":             "<one of: {', '.join(VALID_EXERCISE_TYPES)}>",
  "movement_type":             "<one of: {', '.join(VALID_MOVEMENT_TYPES)}>",
  "difficulty_level":          "<one of: {', '.join(VALID_DIFFICULTIES)}>",
  "default_sets":              <int 1-6>,
  "default_reps":              <int 1-30, or null for time-based>,
  "default_duration_seconds":  <int 5-600, or null for rep-based>,
  "default_rest_seconds":      <int 15-240>,
  "is_warmup_suitable":        <bool>,
  "is_stretch_suitable":       <bool>,
  "is_cooldown_suitable":      <bool>
}}"""

_COMMON_RULES = """Rules:
- ALL fields MUST be present. Use your knowledge of exercise science to fill in any field not explicit in the input.
- target_muscles, secondary_muscles, equipment, exercise_type, movement_type, difficulty_level, and body_part MUST use the exact canonical values listed.
- instructions MUST be a JSON array of 3-6 concise strings (cue per step), NOT a paragraph string.
- Exactly one of default_reps / default_duration_seconds should be non-null (null the other).
- If the exercise is a stretch or mobility drill, set movement_type="static" and is_stretch_suitable=true.
- If ambiguous, pick the single most common interpretation (e.g. "row" → "Seated Cable Row").
- Return ONLY JSON — no markdown fences, no preamble.
"""

_PHOTO_PROMPT_TEMPLATE = (
    "Analyze this photo of an exercise or piece of gym equipment and extract a complete exercise record.\n"
    "{hint_block}\n"
    "Return JSON with this exact shape:\n{schema}\n\n{rules}"
)

_VIDEO_FRAME_PROMPT_TEMPLATE = (
    "This is one keyframe from a short video of someone performing an exercise. "
    "Identify the exercise and extract a complete exercise record.\n"
    "{hint_block}\n"
    "Return JSON with this exact shape:\n{schema}\n\n{rules}\n"
    "Also add a top-level field \"frame_confidence\": <float 0.0-1.0> indicating "
    "how confident you are in this extraction given the single frame."
)

_TEXT_PROMPT_TEMPLATE = (
    "Given the exercise description: '{raw_text}'{hint_suffix}, infer and return a complete exercise record.\n"
    "Return JSON with this exact shape:\n{schema}\n\n{rules}"
)


# --- Combo / composite-exercise prompt --------------------------------------
# Shaped so the parsed result maps onto `CompositeExerciseCreate` (combo_type +
# 2-5 component_exercises) for the frontend to review/edit before POSTing.

_COMBO_SCHEMA_BLOCK = f"""{{
  "name":                "<string — human-readable combo name, e.g. 'Push-up → Bench Press Superset'>",
  "combo_type":          "<one of: {', '.join(VALID_COMBO_TYPES)}>",
  "primary_muscle":      "<one of: {', '.join(VALID_MUSCLE_GROUPS)} — use 'full body' when components hit different regions>",
  "secondary_muscles":   ["<optional, same vocabulary as primary_muscle>"],
  "equipment":           "<one of: {', '.join(VALID_EQUIPMENT)}, OR the literal 'mixed' when components use different equipment>",
  "custom_notes":        "<optional string — coaching note for the whole combo, or null>",
  "component_exercises": [
    {{
      "name":             "<string — single movement name, Title Case>",
      "order":            <int — 1-based position in the sequence>,
      "reps":             <int 1-50, or null for a timed hold>,
      "duration_seconds": <int 1-600, or null for a rep-based movement>,
      "transition_note":  "<optional string — how to move into the next movement, or null>"
    }}
    // 2 to 5 components total, in performed order
  ]
}}"""

_COMBO_RULES = f"""Rules:
- Detect 2 to 5 distinct component movements performed in sequence. If you cannot find at least 2, return what you found anyway — never invent filler movements.
- combo_type — pick the single best fit:
    • superset      = 2 DIFFERENT exercises (often opposing/unrelated muscles) back-to-back.
    • compound_set  = 2 exercises for the SAME muscle group back-to-back.
    • giant_set     = 3 or more exercises performed in sequence.
    • complex       = a barbell/dumbbell sequence where the weight NEVER leaves the hands between movements.
    • hybrid        = 2 movements fused into one continuous motion (e.g. a curl-to-press, a thruster).
- order: assign sequential 1-based positions in the order the movements are performed.
- reps vs duration: infer reps for counted movements (default 10 if the user gave no count); use duration_seconds for timed holds/carries instead, with reps null.
- equipment: set to the canonical value when ALL components share it; set to the literal "mixed" when components use different equipment.
- primary_muscle: set to "full body" when the components span different regions; otherwise the shared dominant muscle.
- Use the exact canonical vocabulary for combo_type, primary_muscle, secondary_muscles, and equipment (except equipment="mixed").
- Return ONLY JSON — no markdown fences, no preamble.
"""

_COMBO_TEXT_PROMPT_TEMPLATE = (
    "A user wants to build a combo / composite exercise from this description: '{raw_text}'{hint_suffix}.\n"
    "Break it into its ordered component movements and classify the combination.\n"
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
    """Parse Gemini JSON output or raise a clear ValueError."""
    cleaned = _strip_json_fences(raw)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError as e:
        # Try to locate the first {...} blob as a last-ditch effort (no silent fallback —
        # we still raise if this fails).
        match = re.search(r"\{.*\}", cleaned, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(0))
            except json.JSONDecodeError:
                pass
        logger.error(f"❌ [AiExerciseExtractor] JSON parse failed: {e}. Raw={cleaned[:500]!r}")
        raise ValueError(f"AI returned invalid JSON: {e}") from e


def _normalize_list(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(v).strip() for v in value if str(v).strip()]
    if isinstance(value, str):
        return [value.strip()] if value.strip() else []
    return []


def _pick_canonical(value: Any, allowed: List[str], default: str) -> str:
    """Pick a canonical value from `allowed`; return `default` if no match (with ⚠️ log)."""
    if not value:
        return default
    lowered = str(value).lower().strip()
    for a in allowed:
        if a.lower() == lowered:
            return a
    # Fuzzy contains — e.g. "barbell and bench" -> "barbell"
    for a in allowed:
        if a.lower() in lowered:
            return a
    logger.warning(
        f"⚠️ [AiExerciseExtractor] Non-canonical value '{value}' (allowed={allowed}), "
        f"defaulting to '{default}'"
    )
    return default


def _coerce_int(value: Any, lo: int, hi: int, default: Optional[int]) -> Optional[int]:
    if value is None:
        return default
    try:
        v = int(value)
    except (TypeError, ValueError):
        return default
    if v < lo or v > hi:
        return default
    return v


def _normalize_payload(raw: Dict[str, Any]) -> Dict[str, Any]:
    """
    Normalize a Gemini JSON payload into the `CustomExerciseCreate` Pydantic shape.

    - instructions: array -> newline-joined string (matches TEXT column).
    - target_muscles/secondary_muscles: filtered to canonical vocabulary.
    - equipment/exercise_type/movement_type/difficulty_level/body_part: canonicalized.
    - default_sets/reps/duration/rest: coerced to valid ranges; exactly one of reps/duration set.
    """
    instructions_raw = raw.get("instructions")
    if isinstance(instructions_raw, list):
        instruction_steps = [str(s).strip() for s in instructions_raw if str(s).strip()]
        instructions_str = "\n".join(
            f"{i+1}. {step}" if not re.match(r"^\d+[\.\)]", step) else step
            for i, step in enumerate(instruction_steps)
        )
    elif isinstance(instructions_raw, str):
        instructions_str = instructions_raw.strip()
    else:
        instructions_str = ""

    target_muscles = [
        m.lower() for m in _normalize_list(raw.get("target_muscles"))
        if m.lower() in VALID_MUSCLE_GROUPS
    ]
    secondary_muscles = [
        m.lower() for m in _normalize_list(raw.get("secondary_muscles"))
        if m.lower() in VALID_MUSCLE_GROUPS and m.lower() not in target_muscles
    ]

    if not target_muscles:
        logger.warning("⚠️ [AiExerciseExtractor] No valid target_muscles — defaulting to ['full body']")
        target_muscles = ["full body"]

    equipment = _pick_canonical(raw.get("equipment"), VALID_EQUIPMENT, "other")
    exercise_type = _pick_canonical(raw.get("exercise_type"), VALID_EXERCISE_TYPES, "strength")
    movement_type = _pick_canonical(raw.get("movement_type"), VALID_MOVEMENT_TYPES, "dynamic")
    difficulty_level = _pick_canonical(raw.get("difficulty_level"), VALID_DIFFICULTIES, "intermediate")
    body_part = _pick_canonical(raw.get("body_part"), VALID_BODY_PARTS, "full body")

    default_sets = _coerce_int(raw.get("default_sets"), 1, 10, 3)
    default_reps = _coerce_int(raw.get("default_reps"), 1, 100, None)
    default_duration_seconds = _coerce_int(raw.get("default_duration_seconds"), 1, 3600, None)
    default_rest_seconds = _coerce_int(raw.get("default_rest_seconds"), 0, 600, 60)

    # Ensure at least one of reps / duration is set so the record is usable.
    if default_reps is None and default_duration_seconds is None:
        if exercise_type in ("stretch", "mobility", "cardio"):
            default_duration_seconds = 30
        else:
            default_reps = 10

    name = (raw.get("name") or "").strip() or "Untitled Exercise"
    description = (raw.get("description") or "").strip()
    if len(description) > 1000:
        description = description[:997] + "..."

    return {
        "name": name[:200],
        "description": description or None,
        "instructions": instructions_str or None,
        "body_part": body_part,
        "target_muscles": target_muscles,
        "secondary_muscles": secondary_muscles or None,
        "equipment": equipment,
        "exercise_type": exercise_type,
        "movement_type": movement_type,
        "difficulty_level": difficulty_level,
        "default_sets": default_sets,
        "default_reps": default_reps,
        "default_duration_seconds": default_duration_seconds,
        "default_rest_seconds": default_rest_seconds,
        "is_warmup_suitable": bool(raw.get("is_warmup_suitable", exercise_type == "warmup")),
        "is_stretch_suitable": bool(raw.get("is_stretch_suitable", exercise_type == "stretch")),
        "is_cooldown_suitable": bool(raw.get("is_cooldown_suitable", False)),
    }


def _normalize_combo_payload(raw: Dict[str, Any]) -> Dict[str, Any]:
    """
    Normalize a Gemini combo JSON payload into the composite-exercise preview shape
    the frontend feeds to `POST /custom-exercises/{user_id}/composite`
    (`CompositeExerciseCreate`).

    - combo_type: canonicalized to one of VALID_COMBO_TYPES (default "superset").
    - primary_muscle: canonicalized to VALID_MUSCLE_GROUPS (default "full body").
    - equipment: "mixed" passes through untouched; otherwise canonicalized to
      VALID_EQUIPMENT with a "mixed" default (components differ → caller decides).
    - secondary_muscles: filtered to VALID_MUSCLE_GROUPS, minus primary.
    - component_exercises: 2-5 validated components with sequential 1-based order,
      reps coerced to [1,50] (default 10 when no duration), duration to [1,600].

    Raises ValueError (no silent fallback, per CLAUDE.md) if fewer than 2 valid
    components survive validation.
    """
    # Normalize separators first — the model often writes "giant set"/"compound-set"
    # where our vocab uses underscores ("giant_set"/"compound_set").
    combo_type_raw = re.sub(r"[\s\-]+", "_", str(raw.get("combo_type") or "").strip().lower())
    combo_type = _pick_canonical(combo_type_raw, VALID_COMBO_TYPES, "superset")
    primary_muscle = _pick_canonical(raw.get("primary_muscle"), VALID_MUSCLE_GROUPS, "full body")

    # Equipment: honor an explicit "mixed" from the model, else canonicalize.
    equipment_raw = str(raw.get("equipment") or "").strip().lower()
    if equipment_raw == "mixed":
        equipment = "mixed"
    else:
        equipment = _pick_canonical(raw.get("equipment"), VALID_EQUIPMENT, "mixed")

    secondary_muscles = [
        m.lower() for m in _normalize_list(raw.get("secondary_muscles"))
        if m.lower() in VALID_MUSCLE_GROUPS and m.lower() != primary_muscle
    ]

    raw_components = raw.get("component_exercises")
    if not isinstance(raw_components, list):
        raw_components = []

    components: List[Dict[str, Any]] = []
    for comp in raw_components:
        if not isinstance(comp, dict):
            continue
        comp_name = (comp.get("name") or "").strip()
        if not comp_name:
            logger.warning("⚠️ [AiExerciseExtractor] combo component missing name — skipping")
            continue

        duration_seconds = _coerce_int(comp.get("duration_seconds"), 1, 600, None)
        # Prefer reps unless the model explicitly marked this a timed hold.
        if duration_seconds is not None and comp.get("reps") in (None, 0):
            reps = None
        else:
            reps = _coerce_int(comp.get("reps"), 1, 50, 10)
            duration_seconds = None

        transition = comp.get("transition_note")
        transition = transition.strip() if isinstance(transition, str) and transition.strip() else None

        components.append({
            "name": comp_name[:200],
            "order": len(components) + 1,  # sequential, reassigned below for safety
            "reps": reps,
            "duration_seconds": duration_seconds,
            "transition_note": transition,
        })
        if len(components) >= 5:
            break

    # Reassign sequential 1-based order (defensive — model order may be sparse/dup).
    for i, comp in enumerate(components):
        comp["order"] = i + 1

    if len(components) < 2:
        logger.error(
            f"❌ [AiExerciseExtractor] combo extraction yielded {len(components)} valid "
            f"component(s); need at least 2. Raw component count={len(raw_components)}"
        )
        raise ValueError(
            "Could not identify at least 2 distinct movements for the combo. "
            "Describe the sequence more explicitly (e.g. 'push-ups then bench press')."
        )

    custom_notes = raw.get("custom_notes")
    custom_notes = custom_notes.strip() if isinstance(custom_notes, str) and custom_notes.strip() else None
    if custom_notes and len(custom_notes) > 2000:
        custom_notes = custom_notes[:1997] + "..."

    name = (raw.get("name") or "").strip() or "Custom Combo"

    return {
        "name": name[:200],
        "combo_type": combo_type,
        "primary_muscle": primary_muscle,
        "secondary_muscles": secondary_muscles,
        "equipment": equipment,
        "custom_notes": custom_notes,
        "component_exercises": components,
    }


def _hint_block(user_hint: Optional[str]) -> str:
    if user_hint and user_hint.strip():
        return f"User hint: \"{user_hint.strip()}\" (use this if it resolves ambiguity)."
    return ""


# =============================================================================
# Extractor
# =============================================================================

class AiExerciseExtractor:
    """
    Extract structured custom exercise metadata from photo / video / text.

    Usage:
        extractor = AiExerciseExtractor(vision_service=get_vision_service())
        payload = await extractor.extract_from_text("seated cable row neutral grip")
        # payload is ready to pass to `CustomExerciseCreate(**payload)`
    """

    def __init__(self, vision_service: Any = None):
        self._settings = get_settings()
        self._vision_service = vision_service  # exposes _s3_client + _bucket
        # Lazy-init a boto3 client if vision_service wasn't provided
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
        """
        Extract exercise from a single photo.

        Accepts either an `s3_key` (we download the bytes) or direct `image_bytes`
        (used by `/analyze-photo` which already has base64 data).
        """
        if image_bytes is None:
            if not s3_key:
                raise ValueError("extract_from_photo requires either s3_key or image_bytes")
            image_bytes = self._download_s3_bytes(s3_key)

        logger.info(f"🤖 [AiExerciseExtractor] extract_from_photo (bytes={len(image_bytes)}, hint={user_hint!r})")

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
                temperature=0.2,
                max_output_tokens=1500,
            ),
            method_name="ai_exercise_extractor.photo",
        )

        raw_text = getattr(response, "text", "") or ""
        if not raw_text.strip():
            raise ValueError("Gemini returned empty response for photo extraction")

        raw = _parse_json_strict(raw_text)
        payload = _normalize_payload(raw)
        logger.info(f"✅ [AiExerciseExtractor] photo → '{payload['name']}' (equipment={payload['equipment']})")
        return payload

    async def extract_from_video(
        self,
        s3_key: str,
        user_hint: Optional[str] = None,
        num_frames: int = 3,
    ) -> Dict[str, Any]:
        """
        Extract exercise from a short video by analyzing `num_frames` keyframes
        and merging the highest-confidence value per field.

        Returns a dict with the normalized exercise shape PLUS a
        `keyframe_confidences: List[float]` key for observability.
        """
        if not s3_key:
            raise ValueError("extract_from_video requires s3_key")

        logger.info(f"🤖 [AiExerciseExtractor] extract_from_video s3_key={s3_key} (num_frames={num_frames})")

        video_bytes = self._download_s3_bytes(s3_key)

        # Write to temp file so keyframe_extractor (ffmpeg-based) can read it.
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

        logger.info(f"🏋️ [AiExerciseExtractor] extracted {len(frames)} keyframes for analysis")

        prompt = _VIDEO_FRAME_PROMPT_TEMPLATE.format(
            hint_block=_hint_block(user_hint),
            schema=_SCHEMA_BLOCK,
            rules=_COMMON_RULES,
        )

        frame_results: List[Dict[str, Any]] = []
        frame_confidences: List[float] = []

        for idx, (jpeg_bytes, mime) in enumerate(frames):
            try:
                image_part = types.Part.from_bytes(data=jpeg_bytes, mime_type=mime)
                response = await gemini_generate_with_retry(
                    model=self._settings.gemini_model,
                    contents=[prompt, image_part],
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        temperature=0.2,
                        max_output_tokens=1500,
                    ),
                    method_name=f"ai_exercise_extractor.video_frame_{idx}",
                )
                raw_text = getattr(response, "text", "") or ""
                if not raw_text.strip():
                    logger.warning(f"⚠️ [AiExerciseExtractor] frame {idx}: empty response")
                    continue
                raw = _parse_json_strict(raw_text)
                conf = float(raw.pop("frame_confidence", 0.5) or 0.5)
                normalized = _normalize_payload(raw)
                frame_results.append(normalized)
                frame_confidences.append(max(0.0, min(1.0, conf)))
                logger.info(
                    f"🤖 [AiExerciseExtractor] frame {idx}: '{normalized['name']}' conf={conf:.2f}"
                )
            except Exception as e:
                logger.warning(f"⚠️ [AiExerciseExtractor] frame {idx} failed: {e}", exc_info=True)
                continue

        if not frame_results:
            raise ValueError("All keyframe extractions failed — unable to identify exercise")

        merged = self._merge_frame_results(frame_results, frame_confidences)
        merged["keyframe_confidences"] = frame_confidences
        logger.info(
            f"✅ [AiExerciseExtractor] video merged → '{merged['name']}' "
            f"(equipment={merged['equipment']}, confidences={frame_confidences})"
        )
        return merged

    async def extract_from_text(
        self,
        raw_text: str,
        user_hint: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Extract exercise from a free-text description."""
        if not raw_text or not raw_text.strip():
            raise ValueError("extract_from_text requires non-empty raw_text")

        logger.info(f"🤖 [AiExerciseExtractor] extract_from_text '{raw_text[:80]}...'")

        hint_suffix = f" (user hint: '{user_hint.strip()}')" if user_hint and user_hint.strip() else ""
        prompt = _TEXT_PROMPT_TEMPLATE.format(
            raw_text=raw_text.strip().replace("'", "\\'"),
            hint_suffix=hint_suffix,
            schema=_SCHEMA_BLOCK,
            rules=_COMMON_RULES,
        )

        response = await gemini_generate_with_retry(
            model=self._settings.gemini_model,
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.2,
                max_output_tokens=1500,
            ),
            method_name="ai_exercise_extractor.text",
        )

        raw_response = getattr(response, "text", "") or ""
        if not raw_response.strip():
            raise ValueError("Gemini returned empty response for text extraction")

        raw = _parse_json_strict(raw_response)
        payload = _normalize_payload(raw)
        logger.info(f"✅ [AiExerciseExtractor] text → '{payload['name']}' (equipment={payload['equipment']})")
        return payload

    async def extract_combo_from_text(
        self,
        raw_text: str,
        user_hint: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Extract a combo / composite exercise from a free-text description.

        e.g. "superset of push-ups then barbell bench press, 10 reps each" →
        a structured preview with combo_type, primary/secondary muscles, equipment,
        and 2-5 ordered component_exercises. The returned dict maps onto
        `CompositeExerciseCreate` so the frontend can review/edit and POST it to
        `POST /custom-exercises/{user_id}/composite` (this method does NOT persist).

        Raises ValueError if the description yields fewer than 2 valid components.
        """
        if not raw_text or not raw_text.strip():
            raise ValueError("extract_combo_from_text requires non-empty raw_text")

        logger.info(f"🤖 [AiExerciseExtractor] extract_combo_from_text '{raw_text[:80]}...'")

        hint_suffix = f" (user hint: '{user_hint.strip()}')" if user_hint and user_hint.strip() else ""
        prompt = _COMBO_TEXT_PROMPT_TEMPLATE.format(
            raw_text=raw_text.strip().replace("'", "\\'"),
            hint_suffix=hint_suffix,
            schema=_COMBO_SCHEMA_BLOCK,
            rules=_COMBO_RULES,
        )

        response = await gemini_generate_with_retry(
            model=self._settings.gemini_model,
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.2,
                max_output_tokens=1500,
            ),
            method_name="ai_exercise_extractor.combo_text",
        )

        raw_response = getattr(response, "text", "") or ""
        if not raw_response.strip():
            raise ValueError("Gemini returned empty response for combo extraction")

        raw = _parse_json_strict(raw_response)
        payload = _normalize_combo_payload(raw)
        logger.info(
            f"🏋️ [AiExerciseExtractor] combo → '{payload['name']}' "
            f"(type={payload['combo_type']}, components={len(payload['component_exercises'])}, "
            f"equipment={payload['equipment']})"
        )
        return payload

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
            logger.error(f"❌ [AiExerciseExtractor] S3 download failed for {s3_key}: {e}", exc_info=True)
            raise

    def _merge_frame_results(
        self,
        results: List[Dict[str, Any]],
        confidences: List[float],
    ) -> Dict[str, Any]:
        """
        Merge per-frame extraction dicts into a single payload.

        Strategy: for each scalar field, take the value from the highest-confidence
        frame that has a truthy value. For list fields, take the union across frames
        weighted by confidence (dedup, preserve canonical ordering).
        """
        if len(results) == 1:
            return dict(results[0])

        # Sort frames by confidence desc for scalar "first-wins" tiebreak.
        order = sorted(range(len(results)), key=lambda i: confidences[i] if i < len(confidences) else 0.0, reverse=True)

        merged: Dict[str, Any] = {}

        scalar_fields = [
            "name", "description", "instructions", "body_part", "equipment",
            "exercise_type", "movement_type", "difficulty_level",
            "default_sets", "default_reps", "default_duration_seconds", "default_rest_seconds",
            "is_warmup_suitable", "is_stretch_suitable", "is_cooldown_suitable",
        ]
        for field in scalar_fields:
            for i in order:
                val = results[i].get(field)
                # Treat 0/False as valid, only skip None / empty string
                if val is None:
                    continue
                if isinstance(val, str) and not val.strip():
                    continue
                merged[field] = val
                break
            if field not in merged:
                merged[field] = results[order[0]].get(field)

        # Union list fields preserving first-seen order
        for field in ("target_muscles", "secondary_muscles"):
            seen: List[str] = []
            for i in order:
                for v in results[i].get(field) or []:
                    if v and v not in seen:
                        seen.append(v)
            merged[field] = seen or None

        # Guarantee target_muscles is never empty
        if not merged.get("target_muscles"):
            merged["target_muscles"] = ["full body"]

        return merged


# Singleton
_extractor: Optional[AiExerciseExtractor] = None


def get_ai_exercise_extractor() -> AiExerciseExtractor:
    global _extractor
    if _extractor is None:
        # Lazy-import vision_service to avoid circular imports at module load
        try:
            from services.vision_service import get_vision_service
            vs = get_vision_service()
        except Exception as e:
            logger.warning(f"⚠️ [AiExerciseExtractor] vision_service unavailable: {e}")
            vs = None
        _extractor = AiExerciseExtractor(vision_service=vs)
    return _extractor
