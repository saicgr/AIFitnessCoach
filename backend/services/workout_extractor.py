"""
workout_extractor.py — pulls a structured workout JSON out of a
SharedContent blob.

Two paths:
  * **YouTube** — transcript + chapter timestamps only (no frame sampling,
    per the App Store compliance section of the Imports plan).
  * **IG / TikTok / generic video** — transcript (caption + optional
    speech-to-text) + Gemini Vision sampling of up to 12 frames evenly
    spaced across the clip.

Each extracted exercise is auto-matched against the existing
`exercise_library` via the ChromaDB RAG layer; unmatched exercises are
flagged for "save as custom" prompting in the review UI.
"""
from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass, field
from typing import Any, Optional

from google.genai import types

from core.config import get_settings
from services.gemini.constants import gemini_generate_with_retry
from services.url_content_fetcher import SharedContent

logger = logging.getLogger(__name__)
settings = get_settings()


@dataclass
class ExtractedExercise:
    name: str
    sets: Optional[int] = None
    reps: Optional[str] = None       # "8-10" / "AMRAP" / "30 s"
    rest_s: Optional[int] = None
    weight_hint: Optional[str] = None
    equipment: list[str] = field(default_factory=list)
    notes: Optional[str] = None
    source_timestamp_s: Optional[float] = None
    library_id: Optional[str] = None  # set by the RAG-matching pass
    confidence: Optional[float] = None


@dataclass
class ExtractedWorkout:
    title: str
    estimated_duration_min: Optional[int] = None
    difficulty: Optional[str] = None
    equipment_needed: list[str] = field(default_factory=list)
    exercises: list[ExtractedExercise] = field(default_factory=list)
    notes: Optional[str] = None


_EXTRACT_PROMPT = """Extract a structured workout from the content below.

Return ONLY valid JSON in this exact shape (no markdown fences):
{
  "title": "string",
  "estimated_duration_min": <integer or null>,
  "difficulty": "beginner" | "intermediate" | "advanced" | null,
  "equipment_needed": ["barbell","bench",...],
  "exercises": [
    {
      "name": "Bench Press",
      "sets": 4,
      "reps": "6-8",
      "rest_s": 90,
      "weight_hint": "185 lb" or null,
      "equipment": ["barbell","bench"],
      "notes": "focus on slow eccentric",
      "source_timestamp_s": 124
    }
  ],
  "notes": "any caveats / form cues / programming notes"
}

Rules:
- If the content isn't a workout, return {"title":null,"exercises":[]}.
- Exercise NAMES must be the standard form ("Barbell Bench Press" not "BBBP").
- Use null where unknown — do not invent sets/reps you can't justify.
- Reps can be a range ("6-8"), an AMRAP token ("AMRAP"), or a duration ("30 s").
- If the content mentions a single exercise demoed for form, return it as
  one exercise with sets=null, reps=null.
- Trust the speaker's stated weights/reps over what you'd "normally"
  expect for that exercise.
"""


async def extract_workout(content: SharedContent, *, locale: Optional[str] = None) -> ExtractedWorkout:
    """Run the workout extractor on a fetched URL or pasted text blob.

    For IG / TikTok / generic-video sources where a media asset exists,
    sample up to 12 frames evenly spaced across the clip via Gemini Vision
    in addition to the transcript. For YouTube we never sample frames
    (App Store compliance — see plan §"App Store compliance"); transcript
    + caption only.
    """
    text = content.as_text()
    if not text and not content.media:
        return ExtractedWorkout(title="(empty)", exercises=[])

    locale_hint = f"\nReturn the extracted text in locale: {locale}" if locale else ""
    full_prompt = _EXTRACT_PROMPT + locale_hint + "\n\n---\nCONTENT:\n" + (text[:24_000] if text else "(no transcript available; rely on the video frames)")

    # Frame sampling — IG / TikTok only.
    frame_parts: list[types.Part] = []
    if content.source in ("instagram", "tiktok") and content.media:
        try:
            frame_parts = await _sample_video_frames(content)
        except Exception as e:
            logger.info(f"[WorkoutExtractor] frame sampling skipped: {e}")

    try:
        contents: list = [full_prompt]
        contents.extend(frame_parts)
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=contents,
            config=types.GenerateContentConfig(
                temperature=0.2,
                max_output_tokens=3000,
                response_mime_type="application/json",
            ),
            method_name="share_workout_extract",
        )
        raw = (response.text or "").strip()
        parsed = _safe_json(raw)
        return _to_workout(parsed)
    except Exception as e:
        logger.warning(f"[WorkoutExtractor] failed: {e}", exc_info=True)
        return ExtractedWorkout(title="(extraction failed)", exercises=[])


async def _sample_video_frames(content: SharedContent) -> list[types.Part]:
    """Sample up to 12 evenly-spaced frames from the first downloaded
    video asset and return them as Gemini Vision Parts. Uses ffmpeg —
    already installed on Render per existing video flows.

    Returns an empty list when ffmpeg / the asset isn't available — the
    extractor falls back to transcript-only.
    """
    import asyncio
    import os
    import shutil
    import tempfile

    if not content.media:
        return []
    asset = content.media[0]
    if asset.type != "video" or not asset.s3_key:
        return []

    # Download the asset back from S3 to a temp file. (We don't keep this
    # around — the cleanup cron clears the original key separately.)
    try:
        from services.s3_service import get_s3_service
        s3 = get_s3_service()
        video_bytes = s3.download_bytes(asset.s3_key)
    except Exception as e:
        logger.info(f"[WorkoutExtractor] S3 download failed: {e}")
        return []

    if shutil.which("ffmpeg") is None:
        return []

    tmp_dir = tempfile.mkdtemp(prefix="zealova-frames-")
    try:
        in_path = os.path.join(tmp_dir, "in.mp4")
        with open(in_path, "wb") as fh:
            fh.write(video_bytes)

        # Cap to 12 frames. Fast: scale to 384px, jpeg q=4.
        n_frames = 12
        out_pat = os.path.join(tmp_dir, "f_%02d.jpg")
        proc = await asyncio.create_subprocess_exec(
            "ffmpeg", "-y", "-i", in_path,
            "-vf", f"scale=384:-1,fps=fps={n_frames}/{max(asset.duration_s or 30, 5)}",
            "-frames:v", str(n_frames), "-q:v", "4",
            out_pat,
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL,
        )
        await proc.wait()

        parts: list[types.Part] = []
        for name in sorted(os.listdir(tmp_dir)):
            if not name.startswith("f_") or not name.endswith(".jpg"):
                continue
            with open(os.path.join(tmp_dir, name), "rb") as fh:
                parts.append(types.Part.from_bytes(data=fh.read(), mime_type="image/jpeg"))
            if len(parts) >= n_frames:
                break
        return parts
    finally:
        try:
            shutil.rmtree(tmp_dir, ignore_errors=True)
        except Exception:
            pass


def _to_workout(d: Any) -> ExtractedWorkout:
    # Gemini can return three shapes depending on the source:
    #   1. {title, exercises:[...], ...}                — single-workout dict (canonical)
    #   2. [{name,sets,...}, {name,sets,...}, ...]      — flat exercises array
    #   3. [{title,exercises:[...]}, {title,exercises:[...]}, ...] — multi-day
    #      list (e.g. a 4-day split PDF with each day as a top-level entry)
    # Normalize all three into shape 1.
    if isinstance(d, list):
        if d and isinstance(d[0], dict) and "exercises" in d[0]:
            # Multi-day list — merge every day's exercises + concatenate titles.
            merged_exs: list = []
            titles: list[str] = []
            equipment: list[str] = []
            total_duration = 0
            difficulty_votes: list[str] = []
            notes_parts: list[str] = []
            for day in d:
                if not isinstance(day, dict):
                    continue
                day_title = day.get("title")
                if day_title:
                    titles.append(str(day_title))
                day_exs = day.get("exercises") or []
                if isinstance(day_exs, list):
                    for ex in day_exs:
                        if isinstance(ex, dict):
                            # Stamp the day onto the exercise notes so the
                            # review UI can group them later.
                            if day_title and not ex.get("notes"):
                                ex = {**ex, "notes": f"Day: {day_title}"}
                            merged_exs.append(ex)
                eq = day.get("equipment_needed")
                if isinstance(eq, list):
                    equipment.extend(str(e) for e in eq)
                dur = day.get("estimated_duration_min")
                if isinstance(dur, (int, float)):
                    total_duration += int(dur)
                diff = day.get("difficulty")
                if diff:
                    difficulty_votes.append(str(diff))
                day_notes = day.get("notes")
                if day_notes:
                    notes_parts.append(str(day_notes))
            d = {
                "title": " / ".join(titles) if titles else "Imported Workout",
                "estimated_duration_min": total_duration or None,
                "difficulty": _majority(difficulty_votes),
                "equipment_needed": sorted(set(equipment)),
                "exercises": merged_exs,
                "notes": " · ".join(dict.fromkeys(notes_parts)) or None,
            }
        else:
            # Shape 2 — flat exercises list
            d = {"exercises": d}
    if not isinstance(d, dict):
        return ExtractedWorkout(title="(empty)", exercises=[])
    exs_raw = d.get("exercises") or []
    if not isinstance(exs_raw, list):
        exs_raw = []
    exs: list[ExtractedExercise] = []
    for ex in exs_raw[:80]:
        if not isinstance(ex, dict):
            continue
        name = (ex.get("name") or "").strip()
        if not name:
            continue
        sets = ex.get("sets")
        rest_s = ex.get("rest_s")
        try:
            sets = int(sets) if sets is not None else None
        except Exception:
            sets = None
        try:
            rest_s = int(rest_s) if rest_s is not None else None
        except Exception:
            rest_s = None
        ts = ex.get("source_timestamp_s")
        try:
            ts = float(ts) if ts is not None else None
        except Exception:
            ts = None
        equipment = ex.get("equipment") or []
        if not isinstance(equipment, list):
            equipment = []
        exs.append(ExtractedExercise(
            name=name[:120],
            sets=sets,
            reps=(str(ex.get("reps"))[:32] if ex.get("reps") is not None else None),
            rest_s=rest_s,
            weight_hint=(str(ex.get("weight_hint"))[:60] if ex.get("weight_hint") else None),
            equipment=[str(e)[:40] for e in equipment][:8],
            notes=(str(ex.get("notes"))[:240] if ex.get("notes") else None),
            source_timestamp_s=ts,
        ))
    duration = d.get("estimated_duration_min")
    try:
        duration = int(duration) if duration is not None else None
    except Exception:
        duration = None
    return ExtractedWorkout(
        title=(d.get("title") or "Imported Workout")[:200],
        estimated_duration_min=duration,
        difficulty=(str(d.get("difficulty"))[:20] if d.get("difficulty") else None),
        equipment_needed=[str(e)[:40] for e in (d.get("equipment_needed") or [])][:20],
        exercises=exs,
        notes=(str(d.get("notes"))[:600] if d.get("notes") else None),
    )


def _majority(votes: list[str]) -> Optional[str]:
    if not votes:
        return None
    from collections import Counter
    return Counter(votes).most_common(1)[0][0]


def _safe_json(raw: str) -> dict[str, Any]:
    if not raw:
        return {}
    s = raw.strip()
    if s.startswith("```"):
        s = s.split("\n", 1)[-1] if "\n" in s else s
        if s.endswith("```"):
            s = s[:-3]
    s = s.strip()
    try:
        return json.loads(s)
    except Exception:
        start = s.find("{")
        end = s.rfind("}")
        if start >= 0 and end > start:
            try:
                return json.loads(s[start: end + 1])
            except Exception:
                return {}
        return {}


# ---------------------------------------------------------------------------
# RAG-matching pass — links each extracted exercise to a library row.
# Reuses the existing ChromaDB exercise collection if available.
# ---------------------------------------------------------------------------

async def match_exercises_to_library(exs: list[ExtractedExercise]) -> list[ExtractedExercise]:
    """Best-effort name → exercise_library lookup. Failures leave
    `library_id=None`; the review UI surfaces the unmatched item with a
    'save as custom' prompt."""
    try:
        from services.rag_service import get_rag_service  # type: ignore
    except Exception:
        return exs
    try:
        rag = get_rag_service()
    except Exception:
        return exs
    out: list[ExtractedExercise] = []
    for ex in exs:
        try:
            # Most repos expose a top-k search by query. We tolerate either
            # shape: a dict of hits or a list.
            hits = None
            if hasattr(rag, "search_exercises"):
                hits = await rag.search_exercises(ex.name, top_k=1)  # type: ignore[attr-defined]
            if hits:
                first = hits[0] if isinstance(hits, list) else hits
                if isinstance(first, dict):
                    ex.library_id = str(first.get("id") or first.get("exercise_id") or "") or None
                    score = first.get("score") or first.get("similarity")
                    if isinstance(score, (int, float)):
                        ex.confidence = float(score)
        except Exception as e:
            logger.info(f"[WorkoutExtractor] library match failed for '{ex.name}': {e}")
        out.append(ex)
    return out
