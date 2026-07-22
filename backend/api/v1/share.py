"""
/api/v1/share — Imports feature endpoints.

Owns every payload that arrives via the system share sheet (iOS Share
Extension, Android ACTION_SEND) or the web upload page, plus the
universal `shared_items` history surface that Profile → Imports renders.

Endpoints in this module:

  POST  /share/classify          single image classification (multipart or s3_key)
  POST  /share/classify-batch    multi-image classification
  POST  /share/classify-url      pure host-rule URL classifier (no LLM)
  POST  /share/import-text       SSE: text payload → intent → extract → route
  POST  /share/import-workout    save a reviewed extracted workout (custom workout)
  GET   /share/history           list + filter + paginate
  GET   /share/history/{id}      detail
  POST  /share/history/{id}/retry        re-run the pipeline for a failed row
  POST  /share/history/bulk      bulk delete / reclassify
  DELETE /share/history/{id}     delete one
  DELETE /share/history          bulk clear (Privacy → Clear shared history)

`/share/fetch-url`, `/share/import-audio`, `/share/import-pdf` live in a
sibling module (share_orchestrator.py) so this file stays readable.

Auth: every endpoint requires `get_current_user`. RLS at the DB layer
enforces row isolation; we never trust user_id from the request body.
"""
from __future__ import annotations

import json
import logging
from datetime import date, datetime, timezone
from typing import Any, Optional
from urllib.parse import urlparse
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from models.saved_workouts import DifficultyLevel
from services.intent_classifier import (
    INTENT_ROUTING,
    VALID_INTENTS,
    classify_intent,
)
from services.text_intent_normalizer import (
    fingerprints_to_signals,
    normalize as normalize_text,
    soft_hash,
)
from services.vision_service import get_vision_service

logger = get_logger(__name__)
router = APIRouter(prefix="/share", tags=["Imports"])


# ---------------------------------------------------------------------------
# Constants — daily rate-limit caps (Zealova is single-tier Premium)
# ---------------------------------------------------------------------------

DAILY_CAPS: dict[str, int] = {
    "url": 25,
    "image": 50,
    "text": 50,
    "audio": 20,
    "pdf": 10,
}

# Soft-dedupe window for identical share payloads
DEDUPE_WINDOW_SECONDS = 60

# Size limits — server-side enforcement, matched in Flutter client
MAX_SIZES = {
    "image": 50 * 1024 * 1024,           # 50 MB
    "video": 500 * 1024 * 1024,          # 500 MB
    "audio": 100 * 1024 * 1024,          # 100 MB
    "pdf": 50 * 1024 * 1024,             # 50 MB
    "text_inline_bytes": 200 * 1024,     # 200 kB
    "text_db_truncate_bytes": 8 * 1024,  # 8 kB stored inline; rest spilled to S3
}

# Hosts considered "social video" sources — used by /share/classify-url and
# the URL orchestrator. The orchestrator picks the right fetcher per host.
SOCIAL_VIDEO_HOSTS = {
    "youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be",
    "instagram.com", "www.instagram.com",
    "tiktok.com", "www.tiktok.com", "vm.tiktok.com",
}
REDDIT_HOSTS = {"reddit.com", "www.reddit.com", "old.reddit.com", "redd.it"}
X_HOSTS = {"x.com", "www.x.com", "twitter.com", "www.twitter.com"}


# ---------------------------------------------------------------------------
# SSE helper
# ---------------------------------------------------------------------------

def _sse(event: dict) -> bytes:
    return f"data: {json.dumps(event, ensure_ascii=False)}\n\n".encode("utf-8")


# ---------------------------------------------------------------------------
# Rate-limit helpers
# ---------------------------------------------------------------------------

async def _check_and_increment_cap(user_id: str, bucket: str) -> None:
    """Raise 429 if the user has exceeded today's cap for `bucket`. Otherwise
    increment the counter atomically.

    Counter resets at user-local midnight (best-effort: UTC date is used as
    the partition key here; can be upgraded to user-local date once a
    timezone field is reliably populated for every user).
    """
    if bucket not in DAILY_CAPS:
        return
    db = get_supabase_db()
    today = date.today().isoformat()
    # Upsert counter and read the new value.
    res = db.client.rpc(
        "share_rate_increment",
        {"p_user_id": user_id, "p_day": today, "p_bucket": bucket},
    ).execute()
    new_count = None
    if res.data:
        if isinstance(res.data, list) and res.data:
            new_count = res.data[0].get("count") if isinstance(res.data[0], dict) else res.data[0]
        elif isinstance(res.data, int):
            new_count = res.data
    if new_count is None:
        # RPC not yet deployed — fall back to direct upsert.
        existing = (
            db.client.table("share_rate_counters")
            .select("count")
            .eq("user_id", user_id)
            .eq("day_local", today)
            .eq("bucket", bucket)
            .limit(1)
            .execute()
        )
        prev = (existing.data[0]["count"] if existing.data else 0) or 0
        new_count = prev + 1
        db.client.table("share_rate_counters").upsert(
            {
                "user_id": user_id,
                "day_local": today,
                "bucket": bucket,
                "count": new_count,
            },
            on_conflict="user_id,day_local,bucket",
        ).execute()

    if new_count > DAILY_CAPS[bucket]:
        raise HTTPException(
            status_code=429,
            detail={
                "code": "share_daily_cap_reached",
                "bucket": bucket,
                "cap": DAILY_CAPS[bucket],
                "message_key": "share.error.daily_cap_reached",
            },
        )


# ---------------------------------------------------------------------------
# shared_items helpers
# ---------------------------------------------------------------------------

def _new_shared_item(
    *,
    user_id: str,
    source_kind: str,
    source_origin: Optional[str] = None,
    source_url: Optional[str] = None,
    raw_text: Optional[str] = None,
    media_s3_keys: Optional[list[str]] = None,
    tags: Optional[dict[str, Any]] = None,
    status: str = "received",
) -> str:
    """Insert a shared_items row and return its id."""
    db = get_supabase_db()
    payload: dict[str, Any] = {
        "user_id": user_id,
        "source_kind": source_kind,
        "source_origin": source_origin,
        "source_url": source_url,
        "raw_text": (raw_text or "")[: MAX_SIZES["text_db_truncate_bytes"]] or None,
        "media_s3_keys": media_s3_keys or [],
        "status": status,
        "tags": tags or {"format": source_kind, "origin": source_origin or "other"},
    }
    res = db.client.table("shared_items").insert(payload).execute()
    if not res.data:
        raise HTTPException(500, "Failed to create shared_items row")
    return str(res.data[0]["id"])


def _update_shared_item(item_id: str, user_id: str, fields: dict[str, Any]) -> None:
    """Update a shared_items row scoped to user_id (defence-in-depth on top
    of RLS)."""
    db = get_supabase_db()
    db.client.table("shared_items").update(fields).eq("id", item_id).eq(
        "user_id", user_id
    ).execute()


def _merge_tags(item_id: str, user_id: str, extra: dict[str, Any]) -> None:
    """Read-modify-write of the tags jsonb — small table, simple is fine."""
    db = get_supabase_db()
    row = (
        db.client.table("shared_items")
        .select("tags")
        .eq("id", item_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    cur = (row.data[0]["tags"] if row.data else {}) or {}
    cur.update({k: v for k, v in extra.items() if v is not None})
    _update_shared_item(item_id, user_id, {"tags": cur})


def _find_recent_softhash(user_id: str, text_hash: str) -> Optional[str]:
    """Returns the id of a shared_items row created in the past 60s by
    `user_id` whose `tags->>'soft_hash'` matches `text_hash`. None when
    no recent duplicate exists or the RPC fails."""
    if not text_hash:
        return None
    try:
        db = get_supabase_db()
        res = db.client.rpc(
            "share_recent_softhash",
            {
                "p_user_id": user_id,
                "p_soft_hash": text_hash,
                "p_window_seconds": DEDUPE_WINDOW_SECONDS,
            },
        ).execute()
        if res.data:
            first = res.data[0] if isinstance(res.data, list) else res.data
            if isinstance(first, dict) and first.get("id"):
                return str(first["id"])
    except Exception as e:
        logger.info(f"[share_dedupe] RPC failed (continuing): {e}")
    return None


def _detect_url_origin(url: str) -> str:
    """Map a URL to a source_origin tag."""
    try:
        host = urlparse(url).hostname or ""
    except Exception:
        return "web"
    host = host.lower()
    if any(host == h or host.endswith("." + h) for h in ("youtube.com", "youtu.be")):
        return "youtube"
    if "instagram.com" in host:
        return "instagram"
    if "tiktok.com" in host:
        return "tiktok"
    if "reddit.com" in host or host == "redd.it":
        return "reddit"
    if host in {"x.com", "www.x.com", "twitter.com", "www.twitter.com"}:
        return "x"
    return "web"


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------

class ClassifyByKeyRequest(BaseModel):
    s3_key: str = Field(..., min_length=1, max_length=512)
    user_message: Optional[str] = Field(default=None, max_length=500)


class ClassifyResponse(BaseModel):
    content_type: str
    confidence: str            # high|medium|low (heuristic — see _classify_confidence)
    routing_hint: str
    s3_key: Optional[str] = None
    shared_item_id: Optional[str] = None


class ClassifyBatchRequest(BaseModel):
    s3_keys: list[str] = Field(..., min_length=1, max_length=10)


class ClassifyUrlRequest(BaseModel):
    url: str = Field(..., min_length=4, max_length=2000)


class ImportTextRequest(BaseModel):
    text: str = Field(..., min_length=1)
    source_hint: Optional[str] = Field(default=None, max_length=40)
    source_url: Optional[str] = Field(default=None, max_length=2000)
    locale: Optional[str] = Field(default=None, max_length=10)


class ImportWorkoutRequest(BaseModel):
    """Submit an extracted-and-reviewed workout for persistence as a custom
    workout. Wraps the existing custom-workout persistence path; this
    endpoint specifically tags it back to its shared_items row."""

    shared_item_id: Optional[str] = None
    title: str = Field(..., min_length=1, max_length=200)
    estimated_duration_min: Optional[int] = Field(default=None, ge=1, le=600)
    exercises: list[dict[str, Any]] = Field(..., min_length=1, max_length=100)
    equipment_needed: list[str] = Field(default_factory=list, max_length=40)
    difficulty: Optional[str] = Field(default=None, max_length=20)
    source_url: Optional[str] = Field(default=None, max_length=2000)
    notes: Optional[str] = Field(default=None, max_length=2000)


class HistoryRow(BaseModel):
    id: str
    source_kind: str
    source_origin: Optional[str] = None
    source_url: Optional[str] = None
    classifier_intent: Optional[str] = None
    user_override_intent: Optional[str] = None
    target_entity_kind: Optional[str] = None
    target_entity_id: Optional[str] = None
    status: str
    error_message: Optional[str] = None
    tags: dict[str, Any] = Field(default_factory=dict)
    raw_text_preview: Optional[str] = None
    created_at: str
    updated_at: str


class HistoryListResponse(BaseModel):
    rows: list[HistoryRow]
    next_cursor: Optional[str] = None


class HistoryBulkRequest(BaseModel):
    action: str = Field(..., pattern="^(delete|reclassify)$")
    ids: list[str] = Field(..., min_length=1, max_length=100)


# ---------------------------------------------------------------------------
# Confidence heuristic — VisionService.classify_media_content returns the
# class but not a confidence value. We derive one from the result + length
# of the returned token. "unknown" / "document" → low; everything else →
# high (the classifier is configured at temperature=0.1 with max_output_tokens=15
# so its output is essentially a one-shot best guess).
# ---------------------------------------------------------------------------

def _classify_confidence(content_type: str) -> str:
    if content_type in {"unknown", "document"}:
        return "low"
    return "high"


_CONTENT_TYPE_TO_ROUTING_HINT: dict[str, str] = {
    "food_plate":         "log_food",
    "food_buffet":        "log_food",
    "food_menu":          "scan_menu",
    "nutrition_label":    "scan_nutrition_label",
    "app_screenshot":     "parse_app_screenshot",
    "exercise_form":      "form_check",
    "progress_photo":     "progress_upload",
    "gym_equipment":      "equipment_import",
    "recipe_handwritten": "recipe_photo_import",
    "pantry_photo":       "pantry_log",
    "document":           "chat_document",
    "unknown":            "chooser",
}


# ===========================================================================
# /share/classify — single image
# ===========================================================================

@router.post("/classify", response_model=ClassifyResponse)
async def classify_single(
    s3_key: Optional[str] = Form(default=None),
    user_message: Optional[str] = Form(default=None),
    source_origin: Optional[str] = Form(default=None),
    track: bool = Form(default=True),
    file: Optional[UploadFile] = File(default=None),
    current_user: dict = Depends(get_current_user),
):
    """Classify a single image — multipart `file` OR `s3_key` (one required).

    Used by the share extension after upload, and by the Flutter
    ShareRouterScreen for any single-image payload.

    When `track=true` (default), a `shared_items` row is created and
    updated with the classifier result so the Imports screen reflects the
    share. The created row id is returned in the response.
    """
    user_id = current_user["id"]
    if not s3_key and not file:
        raise HTTPException(400, "Either `file` or `s3_key` is required")

    try:
        await _check_and_increment_cap(user_id, "image")

        # Create the shared_items row up-front so it shows in Imports even
        # if classification fails.
        item_id: Optional[str] = None
        if track:
            item_id = _new_shared_item(
                user_id=user_id,
                source_kind="photo",
                source_origin=(source_origin or "photos"),
                media_s3_keys=[s3_key] if s3_key else [],
                tags={"format": "image", "origin": source_origin or "photos"},
                status="classifying",
            )

        svc = get_vision_service()
        if file is not None:
            data = await file.read()
            if len(data) > MAX_SIZES["image"]:
                if item_id:
                    _update_shared_item(item_id, user_id, {
                        "status": "failed",
                        "error_message": "Image too large (>50 MB).",
                    })
                raise HTTPException(413, "Image too large (>50 MB)")
            content_type = await svc.classify_media_content(
                image_data=data,
                mime_type=file.content_type or "image/jpeg",
                user_message=user_message,
            )
        else:
            content_type = await svc.classify_media_content(
                s3_key=s3_key,
                user_message=user_message,
            )

        confidence = _classify_confidence(content_type)
        routing_hint = _CONTENT_TYPE_TO_ROUTING_HINT.get(content_type, "chooser")

        if item_id:
            # Map content_type to a coarse category for the Imports filter
            # rail (image-classifier categories differ from intent-classifier
            # categories; both feed `tags.category`).
            cat = {
                "food_plate":         "food_log",
                "food_buffet":        "food_log",
                "food_menu":          "menu",
                "nutrition_label":    "nutrition_label",
                "app_screenshot":     "food_log",
                "exercise_form":      "form_check",
                "progress_photo":     "progress",
                "gym_equipment":      "equipment",
                "recipe_handwritten": "recipe",
                "pantry_photo":       "food_log",
                "document":           "document",
                "unknown":            "other",
            }.get(content_type, "other")
            _update_shared_item(item_id, user_id, {
                "classifier_intent": None,  # content-type, not intent
                "classifier_confidence": confidence,
                "extracted_payload": {
                    "content_type": content_type,
                    "routing_hint": routing_hint,
                },
                "status": "completed",
            })
            _merge_tags(item_id, user_id, {
                "category": cat,
                "format": "image",
                "origin": source_origin or "photos",
                "content_type": content_type,
            })

        return ClassifyResponse(
            content_type=content_type,
            confidence=confidence,
            routing_hint=routing_hint,
            s3_key=s3_key,
            shared_item_id=item_id,
        )
    except HTTPException:
        raise
    except Exception as exc:
        raise safe_internal_error(exc, "share_classify")


# ===========================================================================
# /share/classify-batch — multi-image carousel
# ===========================================================================

@router.post("/classify-batch")
async def classify_batch(
    request: ClassifyBatchRequest,
    current_user: dict = Depends(get_current_user),
):
    """Classify up to 10 images in parallel. Useful for IG carousels and
    Photos multi-select share."""
    import asyncio

    user_id = current_user["id"]
    svc = get_vision_service()

    # Increment cap once per image.
    for _ in request.s3_keys:
        await _check_and_increment_cap(user_id, "image")

    async def _one(k: str) -> dict[str, Any]:
        try:
            content_type = await svc.classify_media_content(s3_key=k)
            return {
                "s3_key": k,
                "content_type": content_type,
                "confidence": _classify_confidence(content_type),
                "routing_hint": _CONTENT_TYPE_TO_ROUTING_HINT.get(content_type, "chooser"),
            }
        except Exception as e:
            logger.warning(f"[ShareClassifyBatch] {k} failed: {e}")
            return {"s3_key": k, "content_type": "unknown", "confidence": "low",
                    "routing_hint": "chooser"}

    results = await asyncio.gather(*[_one(k) for k in request.s3_keys])

    # Group by routing_hint so the client can decide batch vs grouped chooser.
    by_hint: dict[str, list[str]] = {}
    for r in results:
        by_hint.setdefault(r["routing_hint"], []).append(r["s3_key"])

    return {
        "results": results,
        "grouped": [
            {"routing_hint": h, "s3_keys": keys}
            for h, keys in by_hint.items()
        ],
        "single_bucket": len(by_hint) == 1,
    }


# ===========================================================================
# /share/classify-url — pure host-rule (no LLM)
# ===========================================================================

@router.post("/classify-url")
async def classify_url(
    request: ClassifyUrlRequest,
    current_user: dict = Depends(get_current_user),
):
    """Cheap host-based hint for the client BEFORE deciding whether to
    invoke the heavier `/share/fetch-url` SSE orchestrator."""
    try:
        parsed = urlparse(request.url)
    except Exception:
        raise HTTPException(400, "Invalid URL")
    host = (parsed.hostname or "").lower()
    if not host:
        raise HTTPException(400, "Invalid URL")

    kind = "web"
    if any(host == h or host.endswith("." + h) for h in ("youtube.com", "youtu.be")):
        kind = "youtube"
    elif "instagram.com" in host:
        kind = "instagram"
    elif "tiktok.com" in host:
        kind = "tiktok"
    elif "reddit.com" in host or host == "redd.it":
        kind = "reddit"
    elif host in {"x.com", "www.x.com", "twitter.com", "www.twitter.com"}:
        kind = "x"

    # Provisional routing hint — the orchestrator may override after fetch.
    if kind in {"youtube", "instagram", "tiktok"}:
        provisional = "video_or_recipe"
    elif kind in {"reddit", "x"}:
        provisional = "social_thread"
    else:
        provisional = "recipe_or_web"

    return {"host": host, "kind": kind, "provisional": provisional}


# ===========================================================================
# /share/import-text — text payload pipeline (SSE)
# ===========================================================================

@router.post("/import-text")
async def import_text(
    request: ImportTextRequest,
    current_user: dict = Depends(get_current_user),
):
    """Text payload (pasted from ChatGPT/Claude/Notes/iMessage) → intent
    classifier → routing decision. SSE streams progress.

    Does NOT run downstream extractors (recipe, workout) — the client
    drives those by navigating to the destination screen with prefilled
    text. This keeps the endpoint fast and the orchestration explicit.
    """
    user_id = current_user["id"]

    text_size_bytes = len(request.text.encode("utf-8"))
    if text_size_bytes > MAX_SIZES["text_inline_bytes"]:
        raise HTTPException(413, "Text too large (>200 kB)")

    source_origin = (request.source_hint or "manual_paste").lower()
    text_hash = soft_hash(request.text)[:16]

    # Soft-dedupe — if the user just shared the same text in the past 60s,
    # surface the existing row instead of double-creating. Counts against
    # cap once.
    existing = _find_recent_softhash(user_id, text_hash)
    if existing:
        async def _existing_stream():
            yield _sse({
                "stage": "dedupe",
                "shared_item_id": existing,
                "message": "You just shared this. Tap to re-import?",
            })
        return StreamingResponse(_existing_stream(), media_type="text/event-stream")

    await _check_and_increment_cap(user_id, "text")

    item_id = _new_shared_item(
        user_id=user_id,
        source_kind="text",
        source_origin=source_origin,
        source_url=request.source_url,
        raw_text=request.text,
        tags={
            "format": "text",
            "origin": source_origin,
            "soft_hash": text_hash,
        },
        status="classifying",
    )

    async def stream():
        try:
            yield _sse({"stage": "received", "shared_item_id": item_id})

            fp = normalize_text(request.text)
            yield _sse({
                "stage": "normalized",
                "char_count": fp.char_count,
                "signals": fingerprints_to_signals(fp),
            })

            yield _sse({"stage": "classifying"})
            result = await classify_intent(
                text=fp.text,
                source_origin=source_origin,
                locale=request.locale,
                extra_signals=fingerprints_to_signals(fp),
            )
            intent = result["intent"]
            routing = INTENT_ROUTING.get(intent, INTENT_ROUTING["discuss"])

            _update_shared_item(item_id, user_id, {
                "classifier_intent": intent,
                "classifier_confidence": result["confidence"],
                "extracted_payload": {"why": result.get("why")},
                "target_entity_kind": routing["target_entity_kind"],
                "status": "completed",
            })
            _merge_tags(item_id, user_id, {
                "category": _intent_to_category(intent),
                "format": "text",
                "origin": source_origin,
            })

            yield _sse({
                "stage": "done",
                "intent": intent,
                "confidence": result["confidence"],
                "secondary_intents": result.get("secondary_intents", []),
                "why": result.get("why", ""),
                "redirect_screen": routing["redirect_screen"],
                "shared_item_id": item_id,
            })
        except Exception as e:
            logger.exception(f"[ShareImportText] error: {e}")
            _update_shared_item(item_id, user_id, {
                "status": "failed",
                "error_message": str(e)[:500],
            })
            yield _sse({"stage": "error", "message": "Couldn't classify this text."})

    return StreamingResponse(stream(), media_type="text/event-stream")


def _intent_to_category(intent: str) -> str:
    return {
        "workout_extract": "workout",
        "recipe_extract": "recipe",
        "meal_plan_extract": "meal_plan",
        "food_log_extract": "food_log",
        "form_check": "form_check",
        "progress_log": "progress",
        "tip_save": "tip",
        "nutrition_question": "other",
        "discuss": "other",
    }.get(intent, "other")


# ===========================================================================
# /share/import-workout — persist a reviewed extracted workout
# ===========================================================================

@router.post("/import-workout")
async def import_workout(
    request: ImportWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """Save a reviewed extracted workout into the user's custom-workout
    library. Wraps the existing custom-workout persistence path and tags
    the shared_items row with the resulting workout id."""
    user_id = current_user["id"]
    db = get_supabase_db()

    # Persist as a "saved workout" row using the REAL saved_workouts columns
    # (migration 029): workout_name / workout_description / exercises /
    # total_exercises / estimated_duration_minutes / difficulty_level / folder /
    # tags / notes. There is no `title`, `exercises_json` or catch-all `data`
    # column — those three keys 42703'd the whole insert, so every share-funnel
    # workout import failed. Mirrors api/v1/saved_workouts.py's insert.
    #
    # difficulty_level is read back through models.saved_workouts.DifficultyLevel,
    # so an out-of-vocabulary extraction value must become NULL rather than
    # poison every later GET.
    difficulty_level: Optional[str] = None
    if request.difficulty:
        candidate = request.difficulty.strip().lower()
        if candidate in {d.value for d in DifficultyLevel}:
            difficulty_level = candidate

    # The origin URL has no column of its own; workout_description is the
    # human-readable provenance line (saved_workouts.py writes "Saved from
    # <friend>'s workout" there), so the import source goes in the same place.
    description = (
        f"Imported from {request.source_url}"
        if request.source_url
        else "Imported from a shared link"
    )

    saved_payload = {
        "user_id": user_id,
        "workout_name": request.title,
        "workout_description": description,
        "exercises": request.exercises,
        "total_exercises": len(request.exercises),  # NOT NULL column
        "estimated_duration_minutes": request.estimated_duration_min,
        "difficulty_level": difficulty_level,
        "folder": "Imported",
        "tags": ["imported", "share_funnel"],
        "notes": request.notes,
    }
    try:
        res = db.client.table("saved_workouts").insert(saved_payload).execute()
    except Exception as exc:
        # No fallback store: the import must surface as an error rather than
        # report success for a workout that was never persisted.
        logger.warning(f"[ImportWorkout] saved_workouts insert failed: {exc}")
        raise safe_internal_error(exc, "share_import_workout")

    entity_id: Optional[str] = None
    if res.data:
        entity_id = str(res.data[0].get("id") or "")

    if request.shared_item_id:
        _update_shared_item(request.shared_item_id, user_id, {
            "status": "completed",
            "target_entity_kind": "workout",
            "target_entity_id": entity_id,
            "extracted_payload": {
                "exercises_count": len(request.exercises),
                "duration_min": request.estimated_duration_min,
                # saved_workouts has no equipment column; keep the reviewed
                # equipment list on the shared_items row (real jsonb column,
                # surfaced by /share/history) instead of dropping it.
                "equipment_needed": request.equipment_needed,
            },
        })
        _merge_tags(request.shared_item_id, user_id, {
            "category": "workout",
            "exercise_count": len(request.exercises),
            "duration_s": (request.estimated_duration_min or 0) * 60,
        })

    return {"workout_id": entity_id, "shared_item_id": request.shared_item_id}


# ===========================================================================
# /share/history — list + filter
# ===========================================================================

@router.get("/history", response_model=HistoryListResponse)
async def history_list(
    category: Optional[str] = Query(default=None),
    format: Optional[str] = Query(default=None, alias="format"),
    origin: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None),
    q: Optional[str] = Query(default=None, max_length=200),
    limit: int = Query(default=30, ge=1, le=100),
    cursor: Optional[str] = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    """Paginated list of the user's imports, filterable by category /
    format / origin tags + free-text title search."""
    user_id = current_user["id"]
    db = get_supabase_db()
    qb = (
        db.client.table("shared_items")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(limit + 1)
    )
    if cursor:
        qb = qb.lt("created_at", cursor)
    if status:
        qb = qb.eq("status", status)
    if format:
        qb = qb.eq("source_kind", format)
    if origin:
        qb = qb.eq("source_origin", origin)
    if category:
        # JSONB filter via cs (contains) on tags
        qb = qb.contains("tags", {"category": category})
    if q:
        # Title-ish search — match raw_text prefix or source_url substring
        qb = qb.or_(
            f"raw_text.ilike.%{q}%,source_url.ilike.%{q}%"
        )
    res = qb.execute()
    rows = list(res.data or [])

    next_cursor = None
    if len(rows) > limit:
        next_cursor = rows[limit - 1]["created_at"]
        rows = rows[:limit]

    return HistoryListResponse(
        rows=[
            HistoryRow(
                id=str(r["id"]),
                source_kind=r["source_kind"],
                source_origin=r.get("source_origin"),
                source_url=r.get("source_url"),
                classifier_intent=r.get("classifier_intent"),
                user_override_intent=r.get("user_override_intent"),
                target_entity_kind=r.get("target_entity_kind"),
                target_entity_id=str(r["target_entity_id"]) if r.get("target_entity_id") else None,
                status=r["status"],
                error_message=r.get("error_message"),
                tags=r.get("tags") or {},
                raw_text_preview=(r.get("raw_text") or "")[:140] or None,
                created_at=r["created_at"],
                updated_at=r["updated_at"],
            )
            for r in rows
        ],
        next_cursor=next_cursor,
    )


# ===========================================================================
# /share/history/export — CSV export of the user's imports
# ===========================================================================

@router.get("/history/export")
async def history_export(
    current_user: dict = Depends(get_current_user),
):
    """Stream a CSV of every imports row the caller owns. Suitable for
    backing up / data portability. Columns are stable — clients can
    import into a spreadsheet."""
    import csv
    import io
    from fastapi.responses import StreamingResponse as _StreamingResponse

    user_id = current_user["id"]
    db = get_supabase_db()

    def stream():
        buf = io.StringIO()
        writer = csv.writer(buf)
        writer.writerow([
            "id", "created_at", "source_kind", "source_origin", "source_url",
            "classifier_intent", "user_override_intent", "classifier_confidence",
            "target_entity_kind", "target_entity_id", "status",
            "category", "format", "origin",
            "raw_text_preview",
        ])
        yield buf.getvalue()
        buf.seek(0)
        buf.truncate(0)

        page_size = 200
        cursor = None
        while True:
            qb = (
                db.client.table("shared_items")
                .select("*")
                .eq("user_id", user_id)
                .order("created_at", desc=True)
                .limit(page_size)
            )
            if cursor:
                qb = qb.lt("created_at", cursor)
            res = qb.execute()
            rows = res.data or []
            if not rows:
                break
            for r in rows:
                tags = (r.get("tags") or {})
                writer.writerow([
                    r["id"], r["created_at"], r["source_kind"],
                    r.get("source_origin") or "", r.get("source_url") or "",
                    r.get("classifier_intent") or "",
                    r.get("user_override_intent") or "",
                    r.get("classifier_confidence") or "",
                    r.get("target_entity_kind") or "",
                    str(r.get("target_entity_id") or ""),
                    r.get("status") or "",
                    str(tags.get("category") or ""),
                    str(tags.get("format") or ""),
                    str(tags.get("origin") or ""),
                    (r.get("raw_text") or "").replace("\n", " ")[:200],
                ])
                yield buf.getvalue()
                buf.seek(0)
                buf.truncate(0)
            if len(rows) < page_size:
                break
            cursor = rows[-1]["created_at"]

    return _StreamingResponse(
        stream(),
        media_type="text/csv",
        headers={"Content-Disposition": 'attachment; filename="zealova-imports.csv"'},
    )


# NOTE: /history/export MUST stay above /history/{item_id} — see backend/scripts/audit_route_shadowing.py
@router.get("/history/{item_id}")
async def history_detail(
    item_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()
    res = (
        db.client.table("shared_items")
        .select("*")
        .eq("id", item_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not res.data:
        raise HTTPException(404, "Not found")
    return res.data[0]


@router.post("/history/{item_id}/retry")
async def history_retry(
    item_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Re-run the pipeline for a failed/interrupted row. Returns the kind
    of payload so the client can route to the right endpoint
    (`/share/import-text`, `/share/fetch-url`, etc.). We do NOT re-run the
    pipeline server-side automatically — that would re-charge the rate
    limiter and pile on hidden cost. The client decides."""
    user_id = current_user["id"]
    db = get_supabase_db()
    res = (
        db.client.table("shared_items")
        .select("*")
        .eq("id", item_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not res.data:
        raise HTTPException(404, "Not found")
    row = res.data[0]
    if row["status"] not in {"failed", "interrupted", "discarded"}:
        raise HTTPException(409, "Row is not in a retryable state")

    db.client.table("shared_items").update({
        "status": "received",
        "error_message": None,
    }).eq("id", item_id).eq("user_id", user_id).execute()

    return {
        "id": item_id,
        "source_kind": row["source_kind"],
        "source_url": row.get("source_url"),
        "raw_text": row.get("raw_text"),
        "media_s3_keys": row.get("media_s3_keys") or [],
        "hint_endpoint": _retry_endpoint_hint(row),
    }


def _retry_endpoint_hint(row: dict[str, Any]) -> str:
    sk = row["source_kind"]
    if sk == "text":
        return "/api/v1/share/import-text"
    if sk == "url":
        return "/api/v1/share/fetch-url"
    if sk == "audio":
        return "/api/v1/share/import-audio"
    if sk == "pdf":
        return "/api/v1/share/import-pdf"
    return "/api/v1/share/classify"


@router.post("/history/bulk")
async def history_bulk(
    request: HistoryBulkRequest,
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()
    if request.action == "delete":
        db.client.table("shared_items").delete().in_("id", request.ids).eq(
            "user_id", user_id
        ).execute()
        return {"deleted": len(request.ids)}
    if request.action == "reclassify":
        db.client.table("shared_items").update({
            "status": "received",
            "user_override_intent": None,
            "extracted_payload": None,
            "target_entity_id": None,
        }).in_("id", request.ids).eq("user_id", user_id).execute()
        return {"reclassified": len(request.ids)}
    raise HTTPException(400, "Unknown action")


@router.delete("/history/{item_id}")
async def history_delete_one(
    item_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()
    db.client.table("shared_items").delete().eq("id", item_id).eq(
        "user_id", user_id
    ).execute()
    return {"id": item_id, "deleted": True}


@router.delete("/history")
async def history_clear(
    current_user: dict = Depends(get_current_user),
):
    """Privacy → Clear shared history. Hard-delete every row owned by the
    user. Media S3 keys are scheduled for cleanup by the existing media
    cleanup cron."""
    user_id = current_user["id"]
    db = get_supabase_db()
    db.client.table("shared_items").delete().eq("user_id", user_id).execute()
    return {"cleared": True}


