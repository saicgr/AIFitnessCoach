"""
Body Analyzer service — Gemini Vision analysis of progress photos + derived
metrics, program retune proposals, deload auto-trigger, and body-age.

All public helpers are async and share the same `gemini_generate_with_retry`
retry/semaphore path used elsewhere in the codebase. Outputs are Pydantic-
validated via `response_schema` so callers never see malformed JSON.
"""
from __future__ import annotations

import asyncio
import base64
import hashlib
import json
import logging
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from google.genai import types

from core.config import get_settings
from core.redis_cache import RedisCache
from models.gemini_schemas import (
    AudioCoachScriptResponse,
    BodyAnalyzerGeminiResponse,
    PhotoMeasurementExtractionResponse,
    ProgramRetuneProposalResponse,
)
from services.gemini.constants import gemini_generate_with_retry

logger = logging.getLogger("body_analyzer")

_ANALYZE_CACHE = RedisCache(prefix="body_analyzer", ttl_seconds=3600, max_size=100)
_MEASURE_CACHE = RedisCache(prefix="photo_measurements", ttl_seconds=3600, max_size=100)
_RETUNE_CACHE = RedisCache(prefix="program_retune", ttl_seconds=1800, max_size=100)
_AUDIO_SCRIPT_CACHE = RedisCache(prefix="audio_coach_script", ttl_seconds=3600, max_size=200)


# =============================================================================
# Photo download helper (thin wrapper to avoid importing vision_service)
# =============================================================================

def _get_s3_client():
    """Local boto3 client — mirrors vision_service's setup to stay free of
    circular imports. Returns (client, bucket) or (None, None) if not
    configured (dev mode)."""
    import boto3
    settings = get_settings()
    if not getattr(settings, "s3_bucket_name", None):
        return None, None
    client = boto3.client(
        "s3",
        region_name=getattr(settings, "s3_region", "us-east-1"),
        aws_access_key_id=getattr(settings, "s3_access_key_id", None),
        aws_secret_access_key=getattr(settings, "s3_secret_access_key", None),
    )
    return client, settings.s3_bucket_name


async def _download_image(s3_key: str) -> bytes:
    """Fetch bytes for an S3 key (or a raw URL if prefix http)."""
    if s3_key.startswith("http"):
        import httpx
        async with httpx.AsyncClient(timeout=30) as http_client:
            resp = await http_client.get(s3_key)
            resp.raise_for_status()
            return resp.content

    client, bucket = _get_s3_client()
    if not client or not bucket:
        raise RuntimeError("S3 not configured; cannot download image")
    loop = asyncio.get_running_loop()
    obj = await loop.run_in_executor(
        None,
        lambda: client.get_object(Bucket=bucket, Key=s3_key),
    )
    return obj["Body"].read()


# =============================================================================
# 1. analyze_body_from_photos — the core Body Analyzer call
# =============================================================================

async def analyze_body_from_photos(
    *,
    photo_s3_keys: List[str],
    measurements: Dict[str, Any],
    user_context: Optional[str] = None,
    user_id: Optional[str] = None,
    model: Optional[str] = None,
) -> BodyAnalyzerGeminiResponse:
    """Run Gemini Vision body analysis.

    Args:
        photo_s3_keys: 1–4 progress-photo S3 keys (front / back / side).
        measurements: Dict with any subset of {height_cm, weight_kg,
            body_fat_percent, waist_cm, chest_cm, hip_cm, neck_cm,
            bicep_left_cm, bicep_right_cm, thigh_left_cm, thigh_right_cm,
            age, gender}.
        user_context: Optional free-text (e.g. goal: "bulk for 3 months").
        user_id: Used for per-user semaphore fairness + cost tracking.
        model: Override Gemini model (defaults to settings.gemini_model).

    Returns:
        Validated BodyAnalyzerGeminiResponse.
    """
    settings = get_settings()
    model = model or settings.gemini_model

    cache_key = hashlib.sha256(
        (
            "|".join(sorted(photo_s3_keys))
            + json.dumps(measurements, sort_keys=True, default=str)
            + (user_context or "")
        ).encode()
    ).hexdigest()
    cached = await _ANALYZE_CACHE.get(cache_key)
    if cached is not None:
        logger.info(f"[body_analyzer] cache hit for {cache_key[:12]}")
        return BodyAnalyzerGeminiResponse(**cached)

    # Parallel S3 fetch
    image_bytes_list = await asyncio.gather(
        *[_download_image(k) for k in photo_s3_keys],
    )
    image_parts = [
        types.Part.from_bytes(data=b, mime_type="image/jpeg") for b in image_bytes_list
    ]

    # Prompt: anchor to NSCA/NASM body-composition language. Tell Gemini to
    # weight visible observations over numeric inputs, since photos carry
    # information (symmetry, posture, definition) that tape measurements miss.
    prompt = _build_analyze_prompt(measurements, user_context)

    logger.info(
        f"[body_analyzer] analyze_body_from_photos | user={user_id} | "
        f"photos={len(photo_s3_keys)} | measurements_keys={list(measurements.keys())}"
    )

    response = await gemini_generate_with_retry(
        model=model,
        contents=[prompt, *image_parts],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=BodyAnalyzerGeminiResponse,
            max_output_tokens=2048,
            temperature=0.25,
        ),
        user_id=user_id,
        timeout=45.0,
        method_name="analyze_body_from_photos",
    )

    result = response.parsed if hasattr(response, "parsed") and response.parsed else None
    if result is None:
        # Fallback parse — response.text is guaranteed-JSON because of
        # response_mime_type, but handle defensively.
        try:
            payload = json.loads(response.text)
            result = BodyAnalyzerGeminiResponse(**payload)
        except Exception as parse_err:
            logger.error(
                f"[body_analyzer] Gemini response unparseable: {parse_err} | "
                f"preview={str(response.text)[:200]!r}"
            )
            raise

    # Normalize posture_findings so `issue` and `corrective_exercise_tag` align
    # with the fixed enum the DB / UI expects. Gemini occasionally invents
    # novel tags; drop those rather than break the retune pipeline.
    valid_tags = {
        "forward_head_posture", "rounded_shoulders", "anterior_pelvic_tilt",
        "uneven_shoulders", "knee_valgus", "scapular_winging",
    }
    clean_findings = [
        f for f in result.posture_findings
        if f.issue in valid_tags and f.corrective_exercise_tag in valid_tags
    ]
    result.posture_findings = clean_findings

    await _ANALYZE_CACHE.set(cache_key, result.model_dump())
    return result


def _build_analyze_prompt(
    measurements: Dict[str, Any],
    user_context: Optional[str],
) -> str:
    ctx = f"\nUser context: {user_context}" if user_context else ""
    # Render measurements compactly; empty lines where user hasn't provided
    # a value keep the prompt short rather than listing "None".
    m_lines = "\n".join(
        f"- {k}: {v}" for k, v in measurements.items() if v is not None
    )
    meas_block = f"\n\nStored measurements:\n{m_lines}" if m_lines else ""
    return f"""You are a certified strength & conditioning specialist (NSCA) reviewing a client's physique photos.

Goals for this analysis:
1. Estimate body composition: body_fat_pct (3–60), muscle_mass_pct (10–70).
2. Classify body_type as ectomorph, mesomorph, endomorph, or balanced.
3. Rate left-right symmetry 0–100 (100 = perfectly balanced).
4. Produce an overall_rating 0–100 composite of composition + symmetry + muscularity relative to body_type baselines.
5. Identify posture issues from the side/back photos using these codes ONLY:
   forward_head_posture, rounded_shoulders, anterior_pelvic_tilt,
   uneven_shoulders, knee_valgus, scapular_winging.
6. List 3–5 concrete improvement_tips the user can act on this week (e.g.
   "add 4 sets/wk of rear-delt work").
7. Prioritise 1–4 muscle groups in priority_muscles (subset of chest, back,
   shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core).
8. Write a 3–5 sentence feedback_paragraph — honest, specific, encouraging.
   Avoid hype; describe observations.

If the stored measurements conflict with the visible photo (e.g. claimed
10% body fat but photo shows 18%), trust the photo and note it in the
feedback paragraph.{meas_block}{ctx}

Return valid JSON matching the provided schema."""


# =============================================================================
# 2. extract_measurements_from_photos
# =============================================================================

async def extract_measurements_from_photos(
    *,
    photo_s3_keys: List[str],
    height_cm: Optional[float] = None,
    user_id: Optional[str] = None,
    model: Optional[str] = None,
) -> PhotoMeasurementExtractionResponse:
    """Estimate tape-measure values (waist, chest, hip, neck, arms, thighs)
    from photos. Uses the user's stated `height_cm` as primary scale anchor
    plus any detected reference object (hand spread, credit card, doorframe)
    for confidence scoring."""
    settings = get_settings()
    model = model or settings.gemini_model

    cache_key = hashlib.sha256(
        ("|".join(sorted(photo_s3_keys)) + str(height_cm)).encode()
    ).hexdigest()
    cached = await _MEASURE_CACHE.get(cache_key)
    if cached is not None:
        return PhotoMeasurementExtractionResponse(**cached)

    image_bytes_list = await asyncio.gather(
        *[_download_image(k) for k in photo_s3_keys],
    )
    image_parts = [
        types.Part.from_bytes(data=b, mime_type="image/jpeg") for b in image_bytes_list
    ]

    prompt = f"""You are estimating body measurements from progress photos.

Use the user's stated height ({height_cm or 'unknown'} cm) as the primary
scale anchor. If you detect a known-size reference (hand spread ~18 cm,
credit card 8.5 cm wide, standard doorframe 90 cm, tiled floor with
visible grout lines), use it to boost confidence.

For each measurement you can reasonably estimate, emit one entry.
Skip entries you genuinely cannot estimate — do NOT invent numbers.

Allowed `metric` values:
waist_cm, chest_cm, hip_cm, neck_cm, shoulder_cm,
thigh_left_cm, thigh_right_cm, bicep_left_cm, bicep_right_cm.

Report overall_confidence 0–1 reflecting how reliable your estimates are
as a whole (poor angles / distance / clothing → low).

Return valid JSON matching the schema."""

    response = await gemini_generate_with_retry(
        model=model,
        contents=[prompt, *image_parts],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=PhotoMeasurementExtractionResponse,
            max_output_tokens=1024,
            temperature=0.2,
        ),
        user_id=user_id,
        timeout=30.0,
        method_name="extract_measurements_from_photos",
    )
    result = response.parsed if hasattr(response, "parsed") and response.parsed else None
    if result is None:
        result = PhotoMeasurementExtractionResponse(**json.loads(response.text))

    await _MEASURE_CACHE.set(cache_key, result.model_dump())
    return result


# =============================================================================
# 3. generate_program_retune + strain cap enforcement
# =============================================================================

# Canonical muscle list used by strength_scores CHECK constraint + muscle_focus_points.
_VALID_MUSCLES = [
    "chest", "back", "shoulders", "biceps", "triceps", "forearms",
    "quads", "hamstrings", "glutes", "calves", "core", "traps",
]


async def generate_program_retune(
    *,
    snapshot: Dict[str, Any],
    current_user_profile: Dict[str, Any],
    muscle_caps: Dict[str, int],
    recent_strength_scores: List[Dict[str, Any]],
    user_id: Optional[str] = None,
    model: Optional[str] = None,
) -> ProgramRetuneProposalResponse:
    """Ask Gemini for concrete deltas to apply to public.users columns.

    Args:
        snapshot: The body_analyzer_snapshots row as a dict.
        current_user_profile: Current `users` row (muscle_focus_points,
            training_intensity_percent, primary_goal, daily_*_target).
        muscle_caps: Per-muscle weekly set caps from strain_prevention.
        recent_strength_scores: Last 4 weeks of strength_scores rows.
        user_id: Auth context.
        model: Override.

    Returns:
        Validated + cap-clipped ProgramRetuneProposalResponse.
    """
    settings = get_settings()
    model = model or settings.gemini_model

    prompt = f"""You are tuning a lifter's program based on their latest Body Analyzer snapshot.

Latest snapshot:
{json.dumps(snapshot, default=str, indent=2)}

Current user profile (inputs the generator reads):
- muscle_focus_points: {current_user_profile.get('muscle_focus_points')}
- training_intensity_percent: {current_user_profile.get('training_intensity_percent')}
- primary_goal: {current_user_profile.get('primary_goal')}
- daily_calorie_target: {current_user_profile.get('daily_calorie_target')}
- daily_protein_target_g: {current_user_profile.get('daily_protein_target_g')}
- daily_carbs_target_g: {current_user_profile.get('daily_carbs_target_g')}
- daily_fat_target_g: {current_user_profile.get('daily_fat_target_g')}

Last 4 weeks strength scores per muscle:
{json.dumps(recent_strength_scores, default=str, indent=2)}

Muscle volume caps (hard upper bounds on weekly sets):
{json.dumps(muscle_caps, indent=2)}

Propose a small, safe retune. Rules:
- muscle_focus_points_proposed: integer keys from {_VALID_MUSCLES}, values 0–5, TOTAL ≤ 5. Bias toward the snapshot's priority_muscles.
- Do not propose training_intensity_percent_delta > 15 or < -15 in one step.
- Calorie delta: never > 400 or < -400 in one step.
- Protein delta: never > 40 or < -40.
- Prefer additive moves (add volume to lagging muscle) over removing volume, unless strain/readiness signals demand it.
- posture_corrective_tags must be subset of the snapshot's posture_findings issue list.
- Include a `reasoning` a user can read in one breath (≤ 3 sentences).

Return valid JSON matching the schema."""

    response = await gemini_generate_with_retry(
        model=model,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=ProgramRetuneProposalResponse,
            max_output_tokens=1024,
            temperature=0.3,
        ),
        user_id=user_id,
        timeout=30.0,
        method_name="generate_program_retune",
    )

    proposal = response.parsed if hasattr(response, "parsed") and response.parsed else None
    if proposal is None:
        proposal = ProgramRetuneProposalResponse(**json.loads(response.text))

    # Cap enforcement — clip any muscle allocation that would breach caps.
    # Volume caps are expressed as weekly sets; muscle_focus_points is a 0–5
    # weight. We treat any non-zero focus as "generator will prioritise this
    # muscle" and simply zero-out entries for capped muscles.
    clipped: Dict[str, int] = {}
    for muscle, pts in proposal.muscle_focus_points_proposed.items():
        if muscle not in _VALID_MUSCLES:
            continue
        cap = muscle_caps.get(muscle)
        if cap is not None and cap == 0:
            continue  # muscle is strain-capped — don't focus new volume here
        clipped[muscle] = max(0, min(int(pts), 5))
    # Enforce total ≤ 5 by proportional scale-down
    total = sum(clipped.values())
    if total > 5 and total > 0:
        scale = 5.0 / total
        clipped = {k: max(0, int(round(v * scale))) for k, v in clipped.items()}
    proposal.muscle_focus_points_proposed = clipped

    # priority_muscles must also be valid
    proposal.priority_muscles = [
        m for m in proposal.priority_muscles if m in _VALID_MUSCLES
    ]

    return proposal


def preview_retune_effect(
    *,
    current_user_profile: Dict[str, Any],
    proposal: ProgramRetuneProposalResponse,
) -> Dict[str, Any]:
    """Deterministic diff — no Gemini call.

    Applies proposal deltas to a local copy of the profile and returns a
    render-ready diff dict for the Flutter retune_proposal_sheet. Shows
    `before` and `after` values so the UI can render a side-by-side.
    """
    after = dict(current_user_profile)

    # Muscle focus diff
    before_focus = dict(current_user_profile.get("muscle_focus_points") or {})
    after_focus = dict(proposal.muscle_focus_points_proposed)
    after["muscle_focus_points"] = after_focus

    # Numeric deltas
    def apply(key: str, delta: Optional[int], lo: Optional[int] = None, hi: Optional[int] = None):
        base = current_user_profile.get(key) or 0
        new = int(base) + int(delta or 0)
        if lo is not None:
            new = max(lo, new)
        if hi is not None:
            new = min(hi, new)
        after[key] = new

    apply("training_intensity_percent", proposal.training_intensity_percent_delta, lo=30, hi=150)
    apply("daily_calorie_target", proposal.daily_calorie_target_delta, lo=800, hi=6000)
    apply("daily_protein_target_g", proposal.daily_protein_target_g_delta, lo=30, hi=400)
    apply("daily_carbs_target_g", proposal.daily_carbs_target_g_delta, lo=30, hi=800)
    apply("daily_fat_target_g", proposal.daily_fat_target_g_delta, lo=10, hi=300)

    # Build a per-field diff list the UI can iterate with 'before → after'
    diff_fields = [
        "training_intensity_percent", "daily_calorie_target",
        "daily_protein_target_g", "daily_carbs_target_g", "daily_fat_target_g",
    ]
    field_diffs = [
        {
            "field": f,
            "before": current_user_profile.get(f),
            "after": after.get(f),
            "delta": (after.get(f) or 0) - (current_user_profile.get(f) or 0),
        }
        for f in diff_fields
    ]

    muscle_diffs = []
    all_muscles = set(before_focus.keys()) | set(after_focus.keys())
    for m in sorted(all_muscles):
        b = int(before_focus.get(m, 0))
        a = int(after_focus.get(m, 0))
        if b != a:
            muscle_diffs.append({"muscle": m, "before": b, "after": a, "delta": a - b})

    return {
        "before": current_user_profile,
        "after": after,
        "field_diffs": field_diffs,
        "muscle_focus_diffs": muscle_diffs,
        "rest_days_per_week_suggested": proposal.rest_days_per_week_suggested,
        "posture_corrective_tags": proposal.posture_corrective_tags,
        "priority_muscles": proposal.priority_muscles,
        "reasoning": proposal.reasoning,
        "confidence": proposal.confidence,
    }


# =============================================================================
# 4. check_and_trigger_deload — deterministic, no Gemini call
# =============================================================================

def check_and_trigger_deload(
    *,
    latest_snapshot: Optional[Dict[str, Any]],
    snapshot_30d_ago: Optional[Dict[str, Any]],
    avg_readiness_7d: Optional[float],
    open_strain_alerts: int,
) -> Tuple[bool, str]:
    """Decide whether a deload week should be inserted into the program.

    Returns (needs_deload, reason).

    Deterministic rules (from NSCA periodization + sport-science literature):
      - Body Analyzer overall_rating dropped > 10 points in 30 days.
      - OR 7-day average readiness < 50 (on 0–100 scale).
      - OR ≥ 3 open strain alerts.
    Any single condition triggers; reason explains which.
    """
    reasons: List[str] = []
    if latest_snapshot and snapshot_30d_ago:
        cur = latest_snapshot.get("overall_rating")
        old = snapshot_30d_ago.get("overall_rating")
        if cur is not None and old is not None and (old - cur) > 10:
            reasons.append(f"rating dropped {old} → {cur}")
    if avg_readiness_7d is not None and avg_readiness_7d < 50:
        reasons.append(f"7-day readiness {avg_readiness_7d:.0f}")
    if open_strain_alerts >= 3:
        reasons.append(f"{open_strain_alerts} open strain alerts")

    if reasons:
        return True, "; ".join(reasons)
    return False, ""


# =============================================================================
# 5. compute_body_age — deterministic composite metric
# =============================================================================

def compute_body_age(
    *,
    chronological_age: int,
    body_fat_percent: Optional[float],
    muscle_mass_percent: Optional[float],
    resting_heart_rate: Optional[int],
    consistency_score_30d: Optional[int],
    gender: Optional[str] = None,
) -> int:
    """Lightweight body-age estimator.

    Anchored to population reference ranges (ACSM fitness categorisation,
    ACE body-fat charts). Clamps at 18 so we never tell a teenager they
    have a negative body age.

    Formula:
      body_age = chronological_age
                 - up_to_10y for elite body-comp (BF% low for gender)
                 - up_to_8y for elite muscle-mass
                 - up_to_5y for high consistency_score (≥80 / 100)
                 - up_to_3y for low resting_heart_rate (≤55 bpm)
      clamp(body_age, 18, 120)
    """
    age = int(chronological_age or 30)
    adjust = 0

    if body_fat_percent is not None:
        # Men elite ≤10%, women elite ≤18%; linear interp down from 25%.
        if (gender or "").lower().startswith("f"):
            ref_elite, ref_avg = 18.0, 28.0
        else:
            ref_elite, ref_avg = 10.0, 20.0
        if body_fat_percent <= ref_elite:
            adjust -= 10
        elif body_fat_percent <= ref_avg:
            pct = (ref_avg - body_fat_percent) / max(ref_avg - ref_elite, 0.1)
            adjust -= int(round(10 * pct))

    if muscle_mass_percent is not None:
        # Elite muscle-mass reference: 45% men, 38% women.
        if (gender or "").lower().startswith("f"):
            ref_elite, ref_avg = 38.0, 30.0
        else:
            ref_elite, ref_avg = 45.0, 35.0
        if muscle_mass_percent >= ref_elite:
            adjust -= 8
        elif muscle_mass_percent >= ref_avg:
            pct = (muscle_mass_percent - ref_avg) / max(ref_elite - ref_avg, 0.1)
            adjust -= int(round(8 * pct))

    if consistency_score_30d is not None and consistency_score_30d >= 80:
        adjust -= 5
    elif consistency_score_30d is not None and consistency_score_30d >= 65:
        adjust -= 2

    if resting_heart_rate is not None:
        if resting_heart_rate <= 55:
            adjust -= 3
        elif resting_heart_rate <= 65:
            adjust -= 1
        elif resting_heart_rate >= 85:
            adjust += 2

    body_age = max(18, min(120, age + adjust))
    return body_age


# =============================================================================
# 6. generate_audio_coach_script — small wrapper for the TTS service to voice
# =============================================================================

async def generate_audio_coach_script(
    *,
    user_context: Dict[str, Any],
    coach_persona: str,
    user_id: Optional[str] = None,
    model: Optional[str] = None,
) -> AudioCoachScriptResponse:
    """Produce a ≤60 word personalised script for the daily audio brief.

    `user_context` should include first_name, streak_days, today_workout,
    latest_pr, last_meal_logged, etc. The script is then rendered via
    Google Cloud TTS in `services/audio_coach.py`.
    """
    settings = get_settings()
    model = model or settings.gemini_model

    ctx_hash = hashlib.sha256(
        (json.dumps(user_context, sort_keys=True, default=str) + coach_persona).encode()
    ).hexdigest()
    cached = await _AUDIO_SCRIPT_CACHE.get(ctx_hash)
    if cached is not None:
        return AudioCoachScriptResponse(**cached)

    prompt = f"""You are the user's fitness coach persona: {coach_persona}.

Generate a spoken-aloud audio coach brief the user will hear at app open.

Rules:
- ≤ 60 words (≈ 20 seconds of speech).
- Address the user by first_name on the first word if available.
- Reference ONE concrete recent signal from the context (streak, PR, logged meal, upcoming workout).
- End with a forward-looking sentence (what today's priority is).
- Tone: energetic but not hype-bro. Persona-appropriate.
- Do not include stage directions, emoji, or markdown.

Context:
{json.dumps(user_context, default=str, indent=2)}

Return valid JSON matching the schema."""

    response = await gemini_generate_with_retry(
        model=model,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=AudioCoachScriptResponse,
            max_output_tokens=256,
            temperature=0.6,
        ),
        user_id=user_id,
        timeout=15.0,
        method_name="generate_audio_coach_script",
    )
    result = response.parsed if hasattr(response, "parsed") and response.parsed else None
    if result is None:
        result = AudioCoachScriptResponse(**json.loads(response.text))

    await _AUDIO_SCRIPT_CACHE.set(ctx_hash, result.model_dump())
    return result
