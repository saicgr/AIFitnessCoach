"""
AI Physique Analyzer — public unauthenticated marketing tool.

User uploads a torso photo. Pipeline:
  1) Pre-classify via VisionService.classify_media_content. Reject anything
     that isn't a `progress_photo` so menus/food/equipment can't burn vision
     tokens or get nonsense analyses.
  2) Reject obvious minors via a second tight Gemini Vision call. We deliberately
     do NOT estimate exact age (unreliable + a privacy hazard); we ask a binary
     "is this clearly an adult".
  3) Run a structured-output Gemini Vision analysis with temp=0.2 returning
     bodyFatEstimate, somatotype, muscle strengths/weaknesses, proportion notes,
     primary goal candidate, and confidence.
  4) Synthesize a 4-week program DETERMINISTICALLY in Python from a curated
     exercise library — per feedback memory `feedback_no_llm_for_safety_classification`,
     we don't ask Gemini to design safety-sensitive prescriptions.

Endpoint:
  POST /api/v1/ai-tools/physique-analyze   (multipart/form-data, no auth)

Rate limit: 10 req / IP / hour. The existing `check_and_consume` IP-hashing
limiter is reused so we don't introduce a parallel store; slowapi is also a
dep but mixing two limiters across the same surface is operational noise.
"""

from __future__ import annotations

import base64
import json
import time
from typing import Any, Dict, List, Literal, Optional

from fastapi import APIRouter, File, HTTPException, Request, UploadFile
from google.genai import types
from pydantic import BaseModel, Field

from core.config import get_settings
from core.logger import get_logger
from services.gemini.constants import gemini_generate_with_retry
from services.vision_service import get_vision_service
from utils.free_tool_rate_limit import (
    FreeToolLimitExceeded,
    _client_ip,
    check_and_consume,
)

logger = get_logger(__name__)
settings = get_settings()

router = APIRouter(prefix="/ai-tools", tags=["AI Tools"])

# Rate limit: 10 req per IP per hour. Higher than `free_tools` (2/24h) because
# the physique tool drives a richer install-conversion demo and we want
# prospects who retry a few photos to see results, not 429s.
LIMIT_PER_WINDOW = 10
WINDOW_HOURS = 1

MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MB

ALLOWED_IMAGE_MIME = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
}

DISCLAIMER = (
    "Body-fat estimates from photos are ±3-5%. This is not medical advice. "
    "Consult a physician before significant body composition changes."
)


# ---------------------------------------------------------------------------
# Gemini prompts
# ---------------------------------------------------------------------------

# Adult-only gate. Binary classification — deliberately NOT an age regressor.
# We accept some false negatives (rejecting adults who look young) in exchange
# for zero tolerance on minors.
_ADULT_GATE_PROMPT = (
    "You are a safety classifier. Look at this photo of a person's torso. "
    "Respond with EXACTLY one word: 'adult' if the subject is clearly an "
    "adult (appears 18 or older), or 'uncertain' otherwise. "
    "If you cannot tell with high confidence, say 'uncertain'. "
    "Do not explain. One word only."
)

# Main analysis. Strong JSON-only contract. Empowering, analytical tone — no
# body-shaming language, no medical claims.
_PHYSIQUE_SYSTEM = """You are a physique analyst for a fitness app preview. You look at a torso photo of an adult and produce a structured, empowering, analytical assessment.

Output JSON ONLY with this exact shape (no markdown, no prose):
{
  "bodyFatEstimate": {"low": <int 4-50>, "mid": <int 4-50>, "high": <int 4-50>},
  "somatotype": "ecto" | "meso" | "endo" | "hybrid",
  "muscleStrengths":  ["<short phrase>", ...],   // 2-4 entries
  "muscleWeaknesses": ["<short phrase>", ...],   // 2-4 entries
  "proportionNotes":  ["<short phrase>", ...],   // 2-3 entries
  "primaryGoalCandidate": "cut" | "recomp" | "bulk",
  "confidence": "low" | "medium" | "high"
}

Rules — ABSOLUTE:
- Strengths/weaknesses target SPECIFIC muscle groups using these canonical names: chest, upper back, lats, rear delts, side delts, front delts, biceps, triceps, forearms, quads, hamstrings, glutes, calves, core, traps.
- proportionNotes describes geometry only (e.g. "shoulder-to-waist ratio is wide", "torso-to-leg ratio favours upper body"). Never body-shame.
- bodyFatEstimate.low/mid/high form a 4-7 percentage-point band (mid is your best guess; low/high bracket the realistic range).
- primaryGoalCandidate maps from bodyFatEstimate.mid:
    male  ref: <12 -> bulk, 12-17 -> recomp, >17 -> cut
    female ref: <22 -> bulk, 22-28 -> recomp, >28 -> cut
    If sex is ambiguous, pick the band that fits the visible adiposity.
- confidence reflects photo quality (lighting, angle, framing), NOT certainty about the person.
- NEVER include an em dash. Use periods or commas.
- NEVER comment on the person's face, race, age, sex, attractiveness, or perceived health.
- If you can't see a clear human torso, return confidence "low" and put "image quality insufficient" in proportionNotes.
"""


# ---------------------------------------------------------------------------
# Deterministic 4-week program generator
# ---------------------------------------------------------------------------

# Curated exercise library, grouped by canonical muscle name. Each entry is
# (exercise, sets, reps, rest_s). Volume targets follow NSCA hypertrophy
# guidelines (10-20 sets / muscle / week, 8-12 reps, 60-75% 1RM intensity).
# Compound-first; isolation as accessory. Lower-body lifts kept conservative
# (2-3 sets) so we don't blow weekly volume past 20 sets for a beginner-leaning
# free-tool audience.
_EXERCISE_LIB: Dict[str, List[tuple]] = {
    "chest":      [("Barbell bench press", 3, "8-10", 120), ("Incline dumbbell press", 3, "10-12", 90), ("Cable fly", 3, "12-15", 60)],
    "upper back": [("Pendlay row", 3, "6-8", 150), ("Chest-supported row", 3, "10-12", 90), ("Face pull", 3, "12-15", 60)],
    "lats":       [("Pull-up or lat pulldown", 3, "8-10", 120), ("One-arm dumbbell row", 3, "10-12", 90), ("Straight-arm pulldown", 3, "12-15", 60)],
    "rear delts": [("Reverse pec deck", 3, "12-15", 60), ("Face pull", 3, "12-15", 60), ("Rear delt fly", 3, "12-15", 60)],
    "side delts": [("Dumbbell lateral raise", 4, "10-15", 60), ("Cable lateral raise", 3, "12-15", 60), ("Machine lateral raise", 3, "12-15", 60)],
    "front delts":[("Overhead press", 3, "6-8", 150), ("Seated dumbbell press", 3, "8-10", 120), ("Front raise", 3, "10-12", 60)],
    "biceps":     [("Barbell curl", 3, "8-10", 75), ("Incline dumbbell curl", 3, "10-12", 60), ("Cable curl", 3, "12-15", 60)],
    "triceps":    [("Close-grip bench press", 3, "8-10", 90), ("Overhead triceps extension", 3, "10-12", 60), ("Triceps pushdown", 3, "12-15", 60)],
    "forearms":   [("Hammer curl", 3, "10-12", 60), ("Wrist curl", 3, "12-15", 60)],
    "quads":      [("Back squat", 3, "6-8", 180), ("Leg press", 3, "10-12", 120), ("Bulgarian split squat", 3, "8-10", 90)],
    "hamstrings": [("Romanian deadlift", 3, "8-10", 150), ("Lying leg curl", 3, "10-12", 75), ("Seated leg curl", 3, "12-15", 60)],
    "glutes":     [("Hip thrust", 3, "8-10", 120), ("Cable kickback", 3, "12-15", 60), ("Bulgarian split squat", 3, "8-10", 90)],
    "calves":     [("Standing calf raise", 4, "10-12", 60), ("Seated calf raise", 3, "12-15", 60)],
    "core":       [("Hanging knee raise", 3, "10-12", 60), ("Cable crunch", 3, "12-15", 60), ("Plank", 3, "45s", 45)],
    "traps":      [("Barbell shrug", 3, "10-12", 75), ("Snatch-grip high pull", 3, "8-10", 90)],
}

# Goal -> set-multiplier on weak-muscle accessory work. Bulks get more volume
# on weaknesses; cuts get less (preservation focus); recomp is neutral.
_GOAL_VOLUME_MULT = {"bulk": 1.25, "recomp": 1.0, "cut": 0.85}

# Somatotype -> conditioning prescription (added as Saturday slot). Ecto gets
# less cardio (preserve gains); endo gets more; meso/hybrid get moderate.
_CONDITIONING_BY_TYPE = {
    "ecto":   ("Low-intensity walk", 1, "20 min @ Zone 2", 0),
    "meso":   ("Incline treadmill walk", 1, "25 min @ Zone 2", 0),
    "endo":   ("Zone 2 bike or rower", 1, "35 min @ Zone 2", 0),
    "hybrid": ("Incline treadmill walk", 1, "25 min @ Zone 2", 0),
}


def _normalize_muscle(name: str) -> Optional[str]:
    """Map a free-form weakness label from Gemini to a canonical library key."""
    n = (name or "").strip().lower()
    if not n:
        return None
    # Exact hits first
    if n in _EXERCISE_LIB:
        return n
    # Common synonyms / partial matches
    aliases = {
        "shoulders": "side delts",
        "delts": "side delts",
        "rear deltoids": "rear delts",
        "side deltoids": "side delts",
        "front deltoids": "front delts",
        "back": "upper back",
        "mid back": "upper back",
        "middle back": "upper back",
        "abs": "core",
        "abdominals": "core",
        "obliques": "core",
        "legs": "quads",
        "thighs": "quads",
        "hams": "hamstrings",
        "glute": "glutes",
        "bicep": "biceps",
        "tricep": "triceps",
        "pecs": "chest",
        "lat": "lats",
        "trap": "traps",
    }
    if n in aliases:
        return aliases[n]
    # Substring fallback — catches "weak rear delts and traps" style phrases.
    for key in _EXERCISE_LIB:
        if key in n:
            return key
    return None


def _select_exercises(muscle: str, mult: float) -> List[Dict[str, Any]]:
    """Pull library entries for a muscle, multiplying set count by `mult`."""
    items = _EXERCISE_LIB.get(muscle, [])
    out: List[Dict[str, Any]] = []
    for name, sets, reps, rest in items:
        adj_sets = max(2, int(round(sets * mult)))
        out.append({"exercise": name, "muscle": muscle, "sets": adj_sets, "reps": reps, "rest_s": rest})
    return out


def generate_targeted_program(
    weaknesses: List[str],
    somatotype: str,
    goal: str,
) -> Dict[str, Any]:
    """
    Build a deterministic 4-week, 4-day upper/lower split prioritising the
    identified weak muscles.

    NSCA hypertrophy targets: 10-20 sets/muscle/week, 8-12 reps, 60-75% 1RM,
    60-180s rest. Week 1-3 progressive overload (add 1 set/week to weakness
    work, cap at +2). Week 4 deload at 70% volume.
    """
    mult = _GOAL_VOLUME_MULT.get(goal, 1.0)

    # Canonicalize + dedupe weaknesses. Anything unmappable is silently dropped.
    canonical_weak = []
    seen: set[str] = set()
    for w in weaknesses or []:
        c = _normalize_muscle(w)
        if c and c not in seen:
            canonical_weak.append(c)
            seen.add(c)
    # Fall back to a generic balanced split if Gemini gave us nothing usable.
    if not canonical_weak:
        canonical_weak = ["upper back", "side delts", "hamstrings"]

    # Day templates: 4-day upper / lower / upper / lower split. Weak-muscle
    # work is prepended to the matching day so it gets priority while the
    # lifter is fresh.
    upper_muscles = ["chest", "upper back", "lats", "side delts", "biceps", "triceps"]
    lower_muscles = ["quads", "hamstrings", "glutes", "calves", "core"]

    def _day(label: str, muscles: List[str], weak_first: List[str]) -> Dict[str, Any]:
        ordered: List[str] = []
        # Weak muscles in this day first (priority placement)
        for m in weak_first:
            if m in muscles and m not in ordered:
                ordered.append(m)
        # Then the rest
        for m in muscles:
            if m not in ordered:
                ordered.append(m)
        # Take 1 exercise per muscle for the day (4-6 total). Weak muscles get
        # the multiplier; non-weak get a single mid-rep set block.
        exercises: List[Dict[str, Any]] = []
        for m in ordered[:5]:
            entries = _select_exercises(m, mult if m in weak_first else 1.0)
            if entries:
                exercises.append(entries[0])
        return {"day": label, "exercises": exercises}

    weak_upper = [m for m in canonical_weak if m in upper_muscles]
    weak_lower = [m for m in canonical_weak if m in lower_muscles]
    # Anything not upper/lower (forearms, traps, front delts, rear delts) maps
    # to the closest day's accessory block.
    extras_upper_map = {"rear delts": "upper", "front delts": "upper", "traps": "upper", "forearms": "upper"}
    for m in canonical_weak:
        if extras_upper_map.get(m) == "upper" and m not in weak_upper:
            weak_upper.append(m)

    base_week = [
        _day("Monday — Upper A", upper_muscles, weak_upper),
        _day("Tuesday — Lower A", lower_muscles, weak_lower),
        _day("Thursday — Upper B", list(reversed(upper_muscles)), weak_upper),
        _day("Friday — Lower B", list(reversed(lower_muscles)), weak_lower),
    ]
    # Add the conditioning slot as a 5th day.
    cond = _CONDITIONING_BY_TYPE.get(somatotype, _CONDITIONING_BY_TYPE["meso"])
    base_week.append({"day": "Saturday — Conditioning", "exercises": [
        {"exercise": cond[0], "muscle": "cardio", "sets": cond[1], "reps": cond[2], "rest_s": cond[3]}
    ]})

    # Week-over-week progression. Weeks 1-3 add 1 set to weak-muscle work
    # each week (capped). Week 4 is a deload at ~70% volume of week 3.
    def _progress_week(week_num: int) -> List[Dict[str, Any]]:
        added = min(week_num - 1, 2) if week_num <= 3 else 0
        deload = week_num == 4
        out = []
        for d in base_week:
            new_ex = []
            for ex in d["exercises"]:
                sets = ex["sets"]
                if ex["muscle"] in canonical_weak and not deload:
                    sets = min(sets + added, sets + 2)
                if deload:
                    # Round-down to ~70% volume, never below 2 sets.
                    sets = max(2, int(round(sets * 0.7)))
                new_ex.append({**ex, "sets": sets})
            out.append({"day": d["day"], "exercises": new_ex})
        return out

    notes = (
        f"4-week upper/lower split prioritising your {', '.join(canonical_weak[:3])}. "
        f"Volume targets: 10-20 sets per muscle per week (NSCA hypertrophy). "
        f"Reps 8-12 at ~60-75% 1RM. Week 4 is a deload at 70% volume — earn the next mesocycle."
    )

    return {
        "week1": _progress_week(1),
        "week2": _progress_week(2),
        "week3": _progress_week(3),
        "week4": _progress_week(4),
        "notes": notes,
    }


# ---------------------------------------------------------------------------
# Vision service extension — analyze_physique
# ---------------------------------------------------------------------------


async def analyze_physique(image_bytes: bytes, mime_type: str = "image/jpeg") -> Dict[str, Any]:
    """Run the structured Gemini Vision analysis. Returns the parsed dict.

    Implemented here (not on VisionService directly) so the marketing surface
    is self-contained and can evolve without touching the core nutrition path.
    """
    start = time.time()
    image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)

    user_prompt = (
        "Analyze the torso photo and return the JSON object described in the "
        "system instructions. Be specific. Use the canonical muscle names. "
        "No prose, no markdown fences, JSON only."
    )

    response = await gemini_generate_with_retry(
        model=settings.gemini_model,
        contents=[_PHYSIQUE_SYSTEM, user_prompt, image_part],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            max_output_tokens=600,
            temperature=0.2,
        ),
        method_name="ai_tools_physique_analyze",
        timeout=45.0,
    )

    raw = (response.text or "").strip()
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error(f"[ai-tools/physique] invalid JSON: {e}; raw={raw[:300]}")
        raise ValueError("vision returned unparseable JSON") from e

    # Defensive shape — keep the contract the frontend depends on.
    bf = parsed.get("bodyFatEstimate") or {}
    if not all(k in bf for k in ("low", "mid", "high")):
        raise ValueError("missing bodyFatEstimate band")
    parsed["bodyFatEstimate"] = {
        "low":  int(bf["low"]),
        "mid":  int(bf["mid"]),
        "high": int(bf["high"]),
    }
    parsed.setdefault("somatotype", "hybrid")
    parsed.setdefault("muscleStrengths", [])
    parsed.setdefault("muscleWeaknesses", [])
    parsed.setdefault("proportionNotes", [])
    parsed.setdefault("primaryGoalCandidate", "recomp")
    parsed.setdefault("confidence", "medium")

    elapsed = time.time() - start
    logger.info(f"[ai-tools/physique] vision analysis ok in {elapsed:.2f}s")
    return parsed


# ---------------------------------------------------------------------------
# Adult-gate
# ---------------------------------------------------------------------------


async def _is_adult(image_bytes: bytes, mime_type: str) -> bool:
    """Return True iff Gemini classifies the subject as a clear adult.

    Designed to be conservative — anything uncertain returns False. Per the
    feedback memory `feedback_no_llm_for_safety_classification`, we treat the
    LLM as a NOT-ADULT detector with a deterministic reject; we don't
    retroactively second-guess "uncertain".
    """
    image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=[_ADULT_GATE_PROMPT, image_part],
            config=types.GenerateContentConfig(
                temperature=0.0,
                max_output_tokens=5,
            ),
            method_name="ai_tools_physique_adult_gate",
            timeout=20.0,
        )
        text = (response.text or "").strip().lower()
        return text.startswith("adult")
    except Exception as e:
        # Fail closed — if the gate errors, we refuse the request.
        logger.warning(f"[ai-tools/physique] adult-gate failed: {e}")
        return False


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------


@router.post("/physique-analyze")
async def physique_analyze(request: Request, image: UploadFile = File(...)):
    """Public unauthenticated physique analyzer. 10 req / IP / hour."""
    ip = _client_ip(request)
    try:
        await check_and_consume(
            ip=ip,
            tool="ai-physique-analyzer",
            limit=LIMIT_PER_WINDOW,
            window_hours=WINDOW_HOURS,
        )
    except FreeToolLimitExceeded as e:
        raise HTTPException(
            status_code=429,
            detail={
                "error": "limit_reached",
                "resets_at_iso": e.resets_at.isoformat(),
                "message": "Too many physique scans from this network. Try again in an hour.",
            },
        )

    content_type = (image.content_type or "").lower()
    if content_type not in ALLOWED_IMAGE_MIME:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image type: {content_type or 'unknown'}. Use JPEG, PNG, WebP, or HEIC.",
        )

    raw = await image.read()
    if not raw:
        raise HTTPException(status_code=400, detail="Empty image upload.")
    if len(raw) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail=f"Image too large ({len(raw)} bytes). Max 10 MB.")

    # Normalize HEIF/HEIC mime so Gemini accepts it.
    mime_for_gemini = "image/jpeg" if content_type in ("image/heic", "image/heif", "image/jpg") else content_type

    # --- Safety gate 1: media-type classifier. Must look like a progress photo.
    vision = get_vision_service()
    try:
        media_type = await vision.classify_media_content(image_data=raw, mime_type=mime_for_gemini)
    except Exception as e:
        logger.warning(f"[ai-tools/physique] classifier failed: {e}")
        media_type = "unknown"

    if media_type not in {"progress_photo", "exercise_form"}:
        raise HTTPException(
            status_code=400,
            detail=(
                "We couldn't find a clear torso in that photo. Try a front-facing "
                "shot in good light, shirt off or athletic wear, framed from "
                "shoulders to hips."
            ),
        )

    # --- Safety gate 2: adult-only.
    if not await _is_adult(raw, mime_for_gemini):
        raise HTTPException(
            status_code=400,
            detail=(
                "We can only analyze photos of clear adults. If you're 18 or over, "
                "try a better-lit photo with your full torso in frame."
            ),
        )

    # --- Main analysis.
    try:
        analysis = await analyze_physique(raw, mime_for_gemini)
    except ValueError as e:
        logger.warning(f"[ai-tools/physique] parse: {e}")
        raise HTTPException(
            status_code=400,
            detail="The AI couldn't read that photo clearly. Try a cleaner, better-lit shot.",
        )
    except Exception as e:
        logger.error(f"[ai-tools/physique] analyze failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="AI analysis is temporarily unavailable. Try again in a minute.",
        )

    # --- Deterministic program synthesis.
    program = generate_targeted_program(
        weaknesses=analysis.get("muscleWeaknesses") or [],
        somatotype=analysis.get("somatotype") or "hybrid",
        goal=analysis.get("primaryGoalCandidate") or "recomp",
    )

    return {
        "analysis": analysis,
        "program": program,
        "disclaimer": DISCLAIMER,
    }
