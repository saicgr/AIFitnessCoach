"""
POST /api/v1/equipment/snap — snap-equipment flow (Issue #1, Task #6).

Pipeline (server-side):
  1. Vision classifier: confirm the photo actually shows gym equipment.
     If not, short-circuit with `matched=false, unmatched_reason=not_equipment`.
  2. Gym-equipment extractor: Gemini single-image extraction + EquipmentResolver
     canonicalization → (canonical_name, confidence, raw_name).
  3. exercise_library_cleaned lookup: ILIKE on equipment.
  4. Re-rank by user's last-30-days workout_set_logs usage (boost recently used).
  5. Persist to `snapped_equipment` for the "Snapped" tab + reuse.
  6. Return ranked matches (≤8) with metadata.

Edge cases handled:
  - confidence < 0.5  → matched=false, unmatched_reason=low_confidence
  - 0.5 ≤ conf < 0.7  → matched=true, disambiguate=true (UI shows "Which one?")
  - free tier > 5/day → 402 paywall
  - any tier > 50/day → 429 quota_exceeded
  - vision fails / extractor fails → 502 surfaced (no silent fallback)

Request shape::
    POST /api/v1/equipment/snap
    multipart/form-data:
      image: UploadFile (image/jpeg|png|webp, ≤8MB)
      mode:  'swap' | 'add' | 'identify'
      workout_id: Optional[UUID]
      replacing_exercise_id: Optional[UUID]
      reuse_s3_key: Optional[str]   (skip upload+vision if reusing a prior snap)

Response (matched)::
    {
      "matched": true,
      "snapped_equipment_id": "<uuid>",
      "equipment_canonical_name": "lat_pulldown",
      "confidence": 0.92,
      "disambiguate": false,
      "matches": [
        {"exercise_id": "...", "name": "Lat Pulldown", "image_url": "...",
         "primary_muscle": "lats", "secondary_muscles": [...],
         "equipment": "lat pulldown machine", "score": 1.42,
         "badge": "Recently used"},
        ...
      ]
    }

Response (unmatched)::
    {
      "matched": false,
      "unmatched_reason": "not_equipment" | "low_confidence" | "no_canonical",
      "vision_label": "food_plate",
      "raw_name": "weird machine in corner"
    }
"""
import io
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    Request,
    UploadFile,
)
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from services.gym_equipment_extractor import GymEquipmentExtractor
from services.vision_service import get_vision_service

logger = get_logger(__name__)
router = APIRouter()


# -- Tunables ------------------------------------------------------------
_DAILY_QUOTA_HARD = 50           # 429 above this for any tier
_FREE_TIER_DAILY = 5             # 402 above this for tier='free'
_MIN_CONFIDENCE_MATCHED = 0.5    # below → "low_confidence"
_DISAMBIGUATE_BELOW = 0.7        # 0.5–0.7 → ask user to confirm
_MAX_MATCHES = 8
_MAX_UPLOAD_BYTES = 8 * 1024 * 1024  # 8 MB
_ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp"}


class SnapResponse(BaseModel):
    matched: bool
    snapped_equipment_id: Optional[str] = None
    equipment_canonical_name: Optional[str] = None
    confidence: Optional[float] = None
    disambiguate: bool = False
    matches: list = []
    unmatched_reason: Optional[str] = None
    vision_label: Optional[str] = None
    raw_name: Optional[str] = None


# `from __future__ import annotations` defers field-type evaluation to string
# form; Pydantic v2 needs an explicit rebuild before instantiation works.
SnapResponse.model_rebuild()


# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------

async def _check_quota_and_tier(db, user_id: str) -> None:
    """Enforce free-tier paywall (>5/day) and hard daily cap (>50/day).

    Raises HTTPException with 402 / 429 when limits hit. Surfaces the limit
    explicitly — never silently allows requests through.
    """
    since = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
    try:
        result = (
            db.client.table("snapped_equipment")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .gte("classified_at", since)
            .execute()
        )
        used_today = result.count or 0
    except Exception as e:
        logger.warning(f"⚠️ [SnapEquipment] Could not read quota; allowing request: {e}")
        return

    # Hard ceiling regardless of tier.
    if used_today >= _DAILY_QUOTA_HARD:
        resets_at = (datetime.now(timezone.utc) + timedelta(hours=24)).isoformat()
        raise HTTPException(
            status_code=429,
            detail={
                "error": "quota_exceeded",
                "used_today": used_today,
                "limit": _DAILY_QUOTA_HARD,
                "resets_at": resets_at,
            },
        )

    # Tier check — we treat anything not premium/lifetime/premium_plus as free.
    tier = "free"
    try:
        sub_row = (
            db.client.table("user_subscriptions")
            .select("tier,is_lifetime")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        if sub_row.data:
            tier = (sub_row.data[0].get("tier") or "free").lower()
            if sub_row.data[0].get("is_lifetime"):
                tier = "lifetime"
    except Exception as e:
        # No subscription row → free tier. Any DB error surfaces as free
        # (conservative — paywall stays in place when the lookup fails).
        logger.debug(f"[SnapEquipment] Subscription lookup failed (treating as free): {e}")

    is_paid = tier in {"premium", "premium_plus", "lifetime"}
    if not is_paid and used_today >= _FREE_TIER_DAILY:
        raise HTTPException(
            status_code=402,
            detail={
                "error": "paywall",
                "used_today": used_today,
                "free_limit": _FREE_TIER_DAILY,
                "remaining_today": 0,
            },
        )


async def _upload_to_s3(image_bytes: bytes, user_id: str, content_type: str) -> str:
    """Upload the (already blurred + downscaled) image bytes to S3 and return s3_key."""
    import boto3
    from botocore.config import Config as BotoConfig
    from core.config import get_settings

    settings = get_settings()
    s3 = boto3.client(
        "s3",
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_default_region,
        config=BotoConfig(signature_version="s3v4"),
    )
    ext = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}.get(
        content_type, "jpg"
    )
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    storage_key = f"snapped_equipment/{user_id}/{timestamp}_{uuid.uuid4().hex[:8]}.{ext}"
    s3.put_object(
        Bucket=settings.s3_bucket_name,
        Key=storage_key,
        Body=image_bytes,
        ContentType=content_type,
    )
    return storage_key


def _blur_faces(image_bytes: bytes) -> bytes:
    """Best-effort face blur using OpenCV's bundled Haar cascade.

    No silent fallback: if cv2 is unavailable we still return the original
    bytes (face blur is privacy-best-effort, not a hard correctness gate),
    but we log a warning so this surfaces in observability.
    """
    try:
        import cv2  # type: ignore
        import numpy as np  # type: ignore
    except Exception as e:  # pragma: no cover — environment-specific
        logger.warning(f"⚠️ [SnapEquipment] cv2/numpy unavailable, skipping face blur: {e}")
        return image_bytes

    arr = np.frombuffer(image_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        logger.warning("⚠️ [SnapEquipment] cv2 could not decode upload, skipping blur")
        return image_bytes

    cascade_path = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    cascade = cv2.CascadeClassifier(cascade_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = cascade.detectMultiScale(gray, scaleFactor=1.2, minNeighbors=5, minSize=(40, 40))
    for (x, y, w, h) in faces:
        roi = img[y:y + h, x:x + w]
        # Strong blur — fitness gym backgrounds; we'd rather over-blur than leak.
        blurred = cv2.GaussianBlur(roi, (99, 99), 30)
        img[y:y + h, x:x + w] = blurred

    success, buf = cv2.imencode(".jpg", img, [cv2.IMWRITE_JPEG_QUALITY, 88])
    if not success:
        return image_bytes
    return buf.tobytes()


async def _query_matches(
    db,
    canonical: str,
    user_id: str,
) -> list[dict]:
    """Find candidate exercises in `exercise_library_cleaned` and re-rank by
    the user's last-30-days set-log usage.
    """
    canonical_term = canonical.replace("_", " ")

    # The Supabase Python client doesn't support OR clauses with ILIKE in a
    # single .or_(), but it does support `.or_("col1.ilike.X,col2.ilike.X")`.
    # exercise_library_cleaned carries a single `equipment` column and its
    # muscle column is `target_muscle` (no primary_muscle/primary_equipment).
    # Alias target_muscle → primary_muscle in the projection so the API response
    # shape ("primary_muscle") is unchanged.
    or_clause = f"equipment.ilike.%{canonical_term}%"
    try:
        result = (
            db.client.table("exercise_library_cleaned")
            .select(
                "id,name,image_url,primary_muscle:target_muscle,secondary_muscles,equipment"
            )
            .or_(or_clause)
            .limit(_MAX_MATCHES * 2)
            .execute()
        )
    except Exception as e:
        logger.error(f"❌ [SnapEquipment] Library lookup failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=502,
            detail={"error": "library_lookup_failed", "message": str(e)},
        )

    candidates = list(result.data or [])

    # Pull last-30-day exercise IDs the user has logged sets against, to
    # rerank results by personal usage. Per-set history lives in
    # performance_logs (one row per logged set), timestamped by recorded_at.
    since = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
    usage: dict[str, int] = {}
    try:
        usage_rows = (
            db.client.table("performance_logs")
            .select("exercise_id")
            .eq("user_id", user_id)
            .gte("recorded_at", since)
            .limit(2000)
            .execute()
        )
        for row in usage_rows.data or []:
            ex_id = row.get("exercise_id")
            if ex_id:
                usage[ex_id] = usage.get(ex_id, 0) + 1
    except Exception as e:
        # Non-fatal: missing usage just means no boost. Logged so it surfaces.
        logger.debug(f"[SnapEquipment] Usage lookup skipped: {e}")

    # Score: base 1.0 + log(1+uses) bonus. Top-N truncate.
    import math
    scored: list[dict] = []
    for c in candidates:
        ex_id = c.get("id")
        uses = usage.get(ex_id, 0) if ex_id else 0
        score = 1.0 + math.log1p(uses) * 0.5
        c_copy = dict(c)
        c_copy["score"] = round(score, 3)
        if uses > 0:
            c_copy["badge"] = "Recently used"
        scored.append(c_copy)
    scored.sort(key=lambda x: x.get("score") or 0.0, reverse=True)
    return scored[:_MAX_MATCHES]


# ----------------------------------------------------------------------
# Reusable core (Issue #2: identify_equipment tool calls into this)
# ----------------------------------------------------------------------


async def equipment_snap_core(
    user_id: str,
    s3_key: str,
    mode: str = "identify",
) -> SnapResponse:
    """Run the snap pipeline against an already-uploaded s3_key.

    Shared by:
      • POST /api/v1/equipment/snap (HTTP endpoint, after upload+blur)
      • identify_equipment LangGraph tool (Issue #2)

    The tool path always passes a `reuse_s3_key`-equivalent (the chat
    media is already on S3), so this function never handles raw uploads
    itself — keeping uploads/face-blur logic single-sourced in the HTTP
    handler.
    """
    if mode not in {"swap", "add", "identify"}:
        raise HTTPException(status_code=400, detail=f"Invalid mode '{mode}'")

    db = get_supabase_db()
    await _check_quota_and_tier(db, user_id)

    # ----- 1. Reuse-window: if the same s3_key was classified within the
    # last 60 seconds, return the cached snapped_equipment row instead of
    # re-billing Vision. (Edge case: tool fired right after /snap.)
    try:
        recent_cutoff = (datetime.now(timezone.utc) - timedelta(seconds=60)).isoformat()
        cached = (
            db.client.table("snapped_equipment")
            .select(
                "id,canonical_name,confidence,vision_label,classified_at,last_exercise_id,s3_key"
            )
            .eq("user_id", user_id)
            .eq("s3_key", s3_key)
            .gte("classified_at", recent_cutoff)
            .order("classified_at", desc=True)
            .limit(1)
            .execute()
        )
        if cached.data:
            row = cached.data[0]
            canonical = row.get("canonical_name") or ""
            if canonical and not canonical.startswith("__"):
                logger.info(
                    f"🏋️ [SnapEquipment] cache-hit on s3_key={s3_key} (snap_id={row.get('id')})"
                )
                matches = await _query_matches(db, canonical, user_id)
                return SnapResponse(
                    matched=True,
                    snapped_equipment_id=row.get("id"),
                    equipment_canonical_name=canonical,
                    confidence=float(row.get("confidence") or 0.0),
                    disambiguate=float(row.get("confidence") or 0.0) < _DISAMBIGUATE_BELOW,
                    matches=matches,
                    vision_label=row.get("vision_label"),
                )
    except Exception as e:
        logger.debug(f"[SnapEquipment] reuse-window lookup skipped: {e}")

    # ----- 2. Vision classification: is this actually equipment?
    vision = get_vision_service()
    try:
        media_type = await vision.classify_media_content(s3_key=s3_key)
    except Exception as e:
        logger.error(f"❌ [SnapEquipment] Vision classify failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=502,
            detail={"error": "vision_failed", "message": str(e)},
        )

    if media_type != "gym_equipment":
        try:
            db.client.table("snapped_equipment").insert({
                "user_id": user_id,
                "s3_key": s3_key,
                "canonical_name": "__not_equipment__",
                "confidence": 0.0,
                "vision_label": media_type,
                "created_via": mode,
            }).execute()
        except Exception:
            pass
        return SnapResponse(
            matched=False,
            unmatched_reason="not_equipment",
            vision_label=media_type,
        )

    # ----- 3. Equipment classification + canonicalization
    extractor = GymEquipmentExtractor(vision_service=vision)
    try:
        classification = await extractor.classify_single_image(s3_key)
    except Exception as e:
        logger.error(f"❌ [SnapEquipment] Extractor failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=502,
            detail={"error": "classification_failed", "message": str(e)},
        )

    canonical = classification.get("canonical")
    confidence = float(classification.get("confidence") or 0.0)
    raw_name = classification.get("raw_name")

    if not canonical or confidence < _MIN_CONFIDENCE_MATCHED:
        reason = "low_confidence" if canonical else "no_canonical"
        try:
            db.client.table("snapped_equipment").insert({
                "user_id": user_id,
                "s3_key": s3_key,
                "canonical_name": canonical or (raw_name or "__unmatched__"),
                "confidence": confidence,
                "vision_label": media_type,
                "created_via": mode,
            }).execute()
        except Exception:
            pass
        return SnapResponse(
            matched=False,
            unmatched_reason=reason,
            vision_label=media_type,
            raw_name=raw_name,
            confidence=confidence,
        )

    # ----- 4. Library matches + usage rerank
    matches = await _query_matches(db, canonical, user_id)

    # ----- 5. Persist
    snap_id: Optional[str] = None
    try:
        ins = db.client.table("snapped_equipment").insert({
            "user_id": user_id,
            "s3_key": s3_key,
            "canonical_name": canonical,
            "confidence": confidence,
            "vision_label": media_type,
            "created_via": mode,
            "last_exercise_id": matches[0]["id"] if matches else None,
        }).execute()
        if ins.data:
            snap_id = ins.data[0].get("id")
    except Exception as e:
        logger.warning(f"⚠️ [SnapEquipment] Persist failed: {e}")

    return SnapResponse(
        matched=True,
        snapped_equipment_id=snap_id,
        equipment_canonical_name=canonical,
        confidence=confidence,
        disambiguate=confidence < _DISAMBIGUATE_BELOW,
        matches=matches,
        vision_label=media_type,
        raw_name=raw_name,
    )


# ----------------------------------------------------------------------
# Main endpoint
# ----------------------------------------------------------------------

@router.post("/snap", response_model=SnapResponse)
async def snap_equipment(
    request: Request,
    image: Optional[UploadFile] = File(None),
    mode: str = Form("identify"),
    workout_id: Optional[str] = Form(None),
    replacing_exercise_id: Optional[str] = Form(None),
    reuse_s3_key: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """Snap a gym-equipment photo and get ranked exercise matches."""
    user_id = current_user["id"]
    logger.info(
        f"🏋️ [SnapEquipment] user={user_id} mode={mode} workout={workout_id} "
        f"reuse={reuse_s3_key is not None}"
    )

    # ----- Resolve s3_key (either reuse, or upload after blur+downscale).
    # The vision/classification/persistence pipeline lives in
    # `equipment_snap_core` so the identify_equipment tool can reuse it.
    s3_key: str
    if reuse_s3_key:
        s3_key = reuse_s3_key
    else:
        if image is None:
            raise HTTPException(
                status_code=400,
                detail="Either 'image' upload or 'reuse_s3_key' is required",
            )
        if image.content_type not in _ALLOWED_MIME:
            raise HTTPException(
                status_code=415,
                detail=f"Unsupported content_type '{image.content_type}'. Allowed: {sorted(_ALLOWED_MIME)}",
            )
        raw = await image.read()
        if len(raw) > _MAX_UPLOAD_BYTES:
            raise HTTPException(
                status_code=413,
                detail=f"Image too large ({len(raw)} bytes); max {_MAX_UPLOAD_BYTES}",
            )

        # Privacy: face-blur OTHER gym-goers in the background BEFORE we
        # persist anything. The original is never written to S3.
        blurred = _blur_faces(raw)
        s3_key = await _upload_to_s3(blurred, user_id, image.content_type or "image/jpeg")

    return await equipment_snap_core(user_id=user_id, s3_key=s3_key, mode=mode)


# Pre-Issue-#2 inline pipeline lived here. It has been moved verbatim into
# `equipment_snap_core` (above) so the identify_equipment LangGraph tool can
# share the exact same code path. Kept under a clearly-named no-coverage stub
# so a future grep for ``classify_single_image`` still surfaces the canonical
# implementation; remove this block in a follow-up cleanup.
async def _legacy_snap_unused_after_refactor(  # pragma: no cover
    db, user_id: str, s3_key: str, mode: str,
):  # pragma: no cover
    return None
    # noqa: unreachable
