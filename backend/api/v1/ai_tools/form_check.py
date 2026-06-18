"""
AI Form Check — public unauthenticated marketing tool (the flagship one).

User uploads a short lift video (<= 30s) of a squat, bench press, or deadlift.
Pipeline:
  1) Validate the upload (mime type, size). Reject non-video / oversized files.
  2) Write the bytes to a temp file and extract ~5 evenly-spaced keyframes via
     the EXISTING `services.keyframe_extractor.extract_key_frames` helper — the
     same FFmpeg-based extractor the authenticated app's UC3 form-video flow
     uses. We do NOT rebuild keyframe extraction.
  3) Send the keyframes to Gemini Vision with a structured, coaching-standard
     prompt (NSCA / Starting Strength / Rippetoe cues) at temperature 0.2.
  4) Return rep-by-rep structured form analysis: overall score, per-fault
     detection, rep count, and 2-3 concrete fix cues.

Safety: if Gemini can't see a clear human performing the named lift, we return
a 400 with actionable filming guidance rather than a nonsense analysis.

Endpoint:
  POST /api/v1/ai-tools/form-check   (multipart/form-data, no auth)

Rate limit: 3 req / IP / 24h. Tighter than the physique analyzer (10/h)
because video keyframe analysis is the most expensive AI-tool call.
"""

import json
import os
import tempfile
import time
from typing import Any, Dict, List

from fastapi import APIRouter, File, Form, HTTPException, Request, UploadFile
from google.genai import types

from core.config import get_settings
from core.logger import get_logger
from services.gemini.constants import gemini_generate_with_retry
from services.keyframe_extractor import extract_key_frames
from utils.free_tool_rate_limit import (
    FreeToolLimitExceeded,
    GlobalCapExceeded,
    _client_ip,
    check_and_consume,
    check_global_cap,
)

logger = get_logger(__name__)
settings = get_settings()

router = APIRouter(prefix="/ai-tools", tags=["AI Tools"])

# Per-IP limit: 3 video analyses / 24h. Video keyframe analysis is the most
# expensive AI-tool call (5 vision images per request), so we keep this lower
# than the physique analyzer's 10/h.
LIMIT_PER_WINDOW = 3
WINDOW_HOURS = 24

# 50 MB ceiling. A 30s phone clip at 1080p is typically 15-40 MB.
MAX_VIDEO_BYTES = 50 * 1024 * 1024

# Number of keyframes to extract. 5 frames across the set captures the
# eccentric, bottom, and concentric phases of multiple reps for a short clip
# without burning excess vision tokens.
NUM_KEYFRAMES = 5

ALLOWED_VIDEO_MIME = {
    "video/mp4",
    "video/quicktime",
    "video/webm",
}

# Canonical exercise keys -> human label used in prompts + error copy.
EXERCISE_LABELS = {
    "squat": "barbell back squat",
    "bench": "barbell bench press",
    "deadlift": "barbell deadlift",
}

DISCLAIMER = (
    "AI form analysis is a guide, not a substitute for an in-person coach. "
    "It reads a handful of frames, not your full range of motion, and cannot "
    "feel load, fatigue, or pain. Use it to spot patterns, then confirm with a "
    "qualified coach before chasing a heavy PR."
)


# ---------------------------------------------------------------------------
# Gemini prompt — form scoring rubric grounded in real coaching standards.
# ---------------------------------------------------------------------------

# Per-exercise fault vocabulary + coaching references. We cite real standards
# (NSCA Essentials of Strength Training, Rippetoe's Starting Strength) so the
# model scores against established biomechanics, not invented ones.
_FAULT_REFERENCE = {
    "squat": (
        "SQUAT faults to check (Starting Strength / NSCA): "
        "depth (hip crease should drop below the top of the knee), "
        "knee cave / valgus collapse (knees tracking inside the toes), "
        "butt wink (posterior pelvic tilt + lumbar flexion at the bottom), "
        "heels lifting / weight shifting to toes, "
        "excessive forward torso lean (bar drifting forward of midfoot), "
        "hips shooting up faster than the chest out of the hole, "
        "asymmetric loading. Cues: 'knees out', 'chest up', 'drive through midfoot'."
    ),
    "bench": (
        "BENCH PRESS faults to check (NSCA / Starting Strength): "
        "elbow flare past ~75 degrees from the torso (shoulder-impingement risk), "
        "bar path drift (bar should touch lower chest/sternum and travel a slight "
        "J-curve back over the shoulders), "
        "loss of upper-back arch / scapular retraction, "
        "hips lifting off the bench, "
        "uneven bar (one side higher), "
        "bouncing the bar off the chest, "
        "wrists bent back under the bar. Cues: 'tuck the elbows', 'bend the bar', 'leg drive'."
    ),
    "deadlift": (
        "DEADLIFT faults to check (NSCA / Starting Strength): "
        "lumbar flexion / rounded lower back under load, "
        "bar drifting away from the shins/thighs instead of dragging close, "
        "hips shooting up first leaving the bar behind (turning it into a stiff-leg + back extension), "
        "starting with hips too low (squatting the deadlift), "
        "hyperextending / leaning back at lockout, "
        "soft / unbraced lats letting the bar swing, "
        "jerking the bar off the floor instead of taking out slack. "
        "Cues: 'chest up, take the slack out', 'push the floor away', 'drag the bar up the legs'."
    ),
}

_SYSTEM_PROMPT = """You are a strength coach analyzing lift form for a fitness app preview. You are shown several key frames extracted at even intervals from a short video of one set. Score the form against established coaching standards (NSCA Essentials of Strength Training, Mark Rippetoe's Starting Strength). Do NOT invent biomechanics.

Output JSON ONLY with this exact shape (no markdown, no prose, no code fences):
{
  "subject_visible": true | false,
  "exercise_matches": true | false,
  "overall_score": <int 0-100>,
  "rep_count": <int>,
  "exercise": "<the lift name>",
  "faults": [
    {
      "name": "<short fault name, e.g. 'Knee cave'>",
      "severity": "minor" | "moderate" | "major",
      "detected_at": "rep N" | "throughout",
      "explanation": "<one sentence: what you see and why it matters>"
    }
  ],
  "top_cues": ["<actionable cue>", "<actionable cue>", "<actionable cue>"],
  "confidence": "low" | "medium" | "high"
}

Rules — ABSOLUTE:
- subject_visible: false if you cannot see a clear human performing a barbell lift in the frames.
- exercise_matches: false if the visible lift is clearly NOT the exercise the user named.
- If subject_visible is false OR exercise_matches is false, set overall_score 0, rep_count 0, faults [], top_cues [], confidence "low", and STOP — do not fabricate analysis.
- overall_score: 90-100 textbook, 75-89 solid with minor tweaks, 50-74 has moderate faults worth fixing, below 50 has a major fault that risks injury or a failed lift.
- rep_count: count complete repetitions visible across the frames. If frames are too sparse to be sure, give your best estimate and set confidence "low".
- faults: 0-5 entries, most severe first. Only list faults you can actually see in the frames. severity 'major' is reserved for injury-risk faults (lumbar flexion under load, valgus collapse, elbow flare with shoulder pain risk).
- detected_at: "throughout" if the fault appears in most frames, otherwise the rep where it is worst.
- top_cues: 2-3 short, concrete, coach-style cues that fix the TOP faults. Quote standard cues where they apply. If form is already excellent, give cues to maintain/progress.
- confidence reflects frame quality, angle, and how much of the lifter is in view — NOT certainty about the person.
- NEVER include an em dash. Use periods or commas.
- NEVER comment on the person's body, weight, race, age, or appearance. Only their lifting technique.
"""


# ---------------------------------------------------------------------------
# Core analysis
# ---------------------------------------------------------------------------


async def analyze_lift_form(video_bytes: bytes, exercise: str) -> Dict[str, Any]:
    """Extract keyframes from the video and run a structured Gemini form analysis.

    Args:
        video_bytes: Raw uploaded video bytes.
        exercise: Canonical exercise key — 'squat' | 'bench' | 'deadlift'.

    Returns:
        Parsed analysis dict matching the JSON contract in `_SYSTEM_PROMPT`.

    Raises:
        ValueError: keyframe extraction failed, no frames, or unparseable JSON.
        LookupError: the named lift / a clear human subject was not visible
            (the endpoint maps this to a 400 with actionable filming guidance).
    """
    start = time.time()
    label = EXERCISE_LABELS.get(exercise, exercise)

    # Write to a temp file — the FFmpeg-based extractor reads from a path.
    tmp_path = None
    try:
        fd, tmp_path = tempfile.mkstemp(suffix=".mp4", prefix="form_check_")
        os.close(fd)
        with open(tmp_path, "wb") as fh:
            fh.write(video_bytes)

        # REUSE the existing keyframe extractor (services/keyframe_extractor.py)
        # — the same FFmpeg helper the authenticated UC3 form-video flow uses.
        frames = await extract_key_frames(tmp_path, num_frames=NUM_KEYFRAMES)
    finally:
        if tmp_path and os.path.exists(tmp_path):
            try:
                os.unlink(tmp_path)
            except OSError as e:
                logger.warning(f"[ai-tools/form-check] temp cleanup failed: {e}")

    if not frames:
        logger.warning("[ai-tools/form-check] keyframe extraction returned 0 frames")
        raise ValueError("Could not read any frames from that video.")

    # Build the multimodal request: keyframe images + the user prompt.
    parts: List[Any] = []
    for jpeg_bytes, frame_mime in frames:
        parts.append(types.Part.from_bytes(data=jpeg_bytes, mime_type=frame_mime))

    user_prompt = (
        f"These are {len(frames)} key frames extracted at even intervals from a "
        f"short video of one set. The user says they are performing a {label}. "
        f"{_FAULT_REFERENCE.get(exercise, '')} "
        "Analyze the progression across the frames and return the JSON object "
        "described in the system instructions. JSON only, no markdown."
    )
    parts.append(types.Part.from_text(text=user_prompt))

    response = await gemini_generate_with_retry(
        model=settings.gemini_model,
        contents=[_SYSTEM_PROMPT, types.Content(parts=parts)],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            max_output_tokens=900,
            temperature=0.2,
        ),
        method_name="ai_tools_form_check",
        # flash-lite vision over ~5 keyframes returns in ~3-8s. Cap tightly so a
        # stalled call fails fast (and the client can retry) instead of hanging
        # the user on a spinner for up to two minutes.
        timeout=20.0,
    )

    raw = (response.text or "").strip()
    if not raw:
        logger.warning("[ai-tools/form-check] Gemini returned empty response")
        raise ValueError("The AI could not analyze this video.")

    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error(f"[ai-tools/form-check] invalid JSON: {e}; raw={raw[:300]}")
        raise ValueError("vision returned unparseable JSON") from e

    # Safety gate: the model itself tells us if it could not see the lift.
    if not parsed.get("subject_visible", True) or not parsed.get("exercise_matches", True):
        raise LookupError(exercise)

    # Defensive shape — keep the contract the frontend depends on.
    parsed["overall_score"] = int(parsed.get("overall_score", 0))
    parsed["rep_count"] = int(parsed.get("rep_count", 0))
    parsed.setdefault("exercise", label)
    faults = parsed.get("faults") or []
    norm_faults: List[Dict[str, Any]] = []
    for f in faults[:5]:
        sev = str(f.get("severity", "minor")).lower()
        if sev not in ("minor", "moderate", "major"):
            sev = "minor"
        norm_faults.append({
            "name": str(f.get("name", "Form note")),
            "severity": sev,
            "detected_at": str(f.get("detected_at", "throughout")),
            "explanation": str(f.get("explanation", "")),
        })
    parsed["faults"] = norm_faults
    parsed["top_cues"] = [str(c) for c in (parsed.get("top_cues") or [])][:3]
    conf = str(parsed.get("confidence", "medium")).lower()
    parsed["confidence"] = conf if conf in ("low", "medium", "high") else "medium"
    # Internal-only flags — drop before returning.
    parsed.pop("subject_visible", None)
    parsed.pop("exercise_matches", None)

    elapsed = time.time() - start
    logger.info(
        f"[ai-tools/form-check] analysis ok in {elapsed:.2f}s "
        f"({len(frames)} frames, score={parsed['overall_score']}, reps={parsed['rep_count']})"
    )
    return parsed


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------


@router.post("/form-check")
async def form_check(
    request: Request,
    video: UploadFile = File(...),
    exercise: str = Form(...),
):
    """Public unauthenticated AI form check. 3 req / IP / 24h."""
    ip = _client_ip(request)

    # --- Rate limiting. Global cap first so a budget-locked tool rejects
    #     without consuming the caller's per-IP slot.
    try:
        await check_global_cap("ai-form-check")
    except GlobalCapExceeded as e:
        raise HTTPException(
            status_code=429,
            detail={
                "error": "capacity_reached",
                "resets_at_iso": e.resets_at.isoformat(),
                "message": (
                    "The AI form check is at capacity right now. "
                    "Get unlimited, instant form analysis in the Zealova app."
                ),
            },
        )
    try:
        await check_and_consume(
            ip=ip,
            tool="ai-form-check",
            limit=LIMIT_PER_WINDOW,
            window_hours=WINDOW_HOURS,
        )
    except FreeToolLimitExceeded as e:
        raise HTTPException(
            status_code=429,
            detail={
                "error": "limit_reached",
                "resets_at_iso": e.resets_at.isoformat(),
                "message": "You've used your 3 free form checks today. Resets in 24 hours.",
            },
        )

    # --- Validate the exercise selection.
    exercise = (exercise or "").strip().lower()
    if exercise not in EXERCISE_LABELS:
        raise HTTPException(
            status_code=400,
            detail="Pick a lift: squat, bench, or deadlift.",
        )

    # --- Validate the video upload.
    content_type = (video.content_type or "").lower()
    if content_type not in ALLOWED_VIDEO_MIME:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Unsupported video type: {content_type or 'unknown'}. "
                "Upload an MP4, MOV, or WebM clip."
            ),
        )

    raw = await video.read()
    if not raw:
        raise HTTPException(status_code=400, detail="Empty video upload.")
    if len(raw) > MAX_VIDEO_BYTES:
        raise HTTPException(
            status_code=400,
            detail=f"Video too large ({len(raw) // (1024 * 1024)} MB). Max 50 MB. Keep it under 30 seconds.",
        )

    # --- Run the analysis.
    try:
        analysis = await analyze_lift_form(raw, exercise)
    except LookupError:
        label = EXERCISE_LABELS[exercise]
        raise HTTPException(
            status_code=400,
            detail=(
                f"We couldn't see a clear {label} in this video. "
                "Film from the side, full body in frame, with good lighting, "
                "and capture one full set."
            ),
        )
    except ValueError as e:
        logger.warning(f"[ai-tools/form-check] analysis ValueError: {e}")
        raise HTTPException(
            status_code=400,
            detail=(
                "The AI couldn't analyze that clip. Try a shorter video (under "
                "30 seconds) filmed from the side with the full lift in frame."
            ),
        )
    except Exception as e:
        logger.error(f"[ai-tools/form-check] analysis failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="AI form analysis is temporarily unavailable. Try again in a minute.",
        )

    return {
        "analysis": analysis,
        "disclaimer": DISCLAIMER,
    }
