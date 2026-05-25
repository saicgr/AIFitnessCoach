"""
/api/v1/share — orchestrator endpoints for URL / audio / PDF imports.

Lives in a sibling module to share.py so each file stays readable. Both
mount under the same /share URL prefix and share the same helper module
for shared_items persistence + rate limiting (re-exported from share.py).
"""
from __future__ import annotations

import asyncio
import json
import logging
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.audio_transcriber import transcribe_and_hint
from services.intent_classifier import (
    INTENT_ROUTING,
    classify_intent,
)
from services.pdf_extractor import understand_pdf
from services.share_push_notifier import notify_share_completed, notify_share_failed
from services.text_intent_normalizer import (
    fingerprints_to_signals,
    normalize as normalize_text,
)
from services.url_content_fetcher import detect_source, fetch as fetch_url
from services import url_result_cache
from services.workout_extractor import (
    extract_workout,
    match_exercises_to_library,
)

from services.text_intent_normalizer import soft_hash

from .share import (
    DAILY_CAPS,
    MAX_SIZES,
    _check_and_increment_cap,
    _detect_url_origin,
    _find_recent_softhash,
    _intent_to_category,
    _merge_tags,
    _new_shared_item,
    _sse,
    _update_shared_item,
)

logger = get_logger(__name__)
router = APIRouter(prefix="/share", tags=["Imports"])


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------

class FetchUrlRequest(BaseModel):
    url: str = Field(..., min_length=4, max_length=2000)
    locale: Optional[str] = Field(default=None, max_length=10)


# ===========================================================================
# /share/fetch-url — SSE orchestrator
# ===========================================================================

@router.post("/fetch-url")
async def fetch_url_endpoint(
    request: FetchUrlRequest,
    current_user: dict = Depends(get_current_user),
):
    """Universal URL pipeline: fetch → classify intent → extract → route.

    Streams SSE progress events. Always terminates with `{stage:"done"}`
    or `{stage:"error"}`."""
    user_id = current_user["id"]
    url = request.url.strip()
    url_hash = soft_hash(url)[:16]

    # Soft-dedupe — repeat URL share within 60s short-circuits.
    existing = _find_recent_softhash(user_id, url_hash)
    if existing:
        async def _dedupe_stream():
            yield _sse({
                "stage": "dedupe",
                "shared_item_id": existing,
                "message": "You just shared this URL. Tap to re-import?",
            })
        return StreamingResponse(_dedupe_stream(), media_type="text/event-stream")

    await _check_and_increment_cap(user_id, "url")

    source_origin = _detect_url_origin(url)
    item_id = _new_shared_item(
        user_id=user_id,
        source_kind="url",
        source_origin=source_origin,
        source_url=url,
        tags={
            "format": "url",
            "origin": source_origin,
            "soft_hash": url_hash,
        },
        status="received",
    )

    async def stream():
        try:
            yield _sse({"stage": "received", "shared_item_id": item_id, "source": source_origin})

            yield _sse({"stage": "fetching", "source": source_origin})
            # 24-hour cache — same URL + locale within a day skips the
            # heavy yt-dlp / Data API / Gemini fetch.
            content = url_result_cache.get(url, request.locale)
            if content is not None:
                yield _sse({"stage": "cache_hit"})
            else:
                content = await fetch_url(url)
                if content and not content.error:
                    url_result_cache.set_(url, content, request.locale)
            if content.error:
                _update_shared_item(item_id, user_id, {
                    "status": "failed",
                    "error_message": content.error[:500],
                })
                if content.locked:
                    yield _sse({"stage": "locked",
                                "message": "Couldn't access (private or login-walled).",
                                "shared_item_id": item_id})
                else:
                    yield _sse({"stage": "error",
                                "message": content.error,
                                "shared_item_id": item_id})
                return

            if content.author_handle or content.title:
                yield _sse({
                    "stage": "fetched",
                    "title": content.title,
                    "author": content.author_handle,
                    "has_transcript": bool(content.transcript),
                    "has_media": bool(content.media),
                })

            _merge_tags(item_id, user_id, {
                "author": content.author_handle,
                "title": content.title,
            })

            text_for_classify = content.as_text()
            if not text_for_classify:
                _update_shared_item(item_id, user_id, {
                    "status": "failed",
                    "error_message": "No extractable text or caption.",
                })
                yield _sse({"stage": "error",
                            "message": "Nothing to read from this link.",
                            "shared_item_id": item_id})
                return

            fp = normalize_text(text_for_classify)
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
                "status": "extracting",
            })
            _merge_tags(item_id, user_id, {
                "category": _intent_to_category(intent),
            })

            extracted_payload: dict = {"intent": intent, "why": result.get("why")}
            target_entity_kind = routing["target_entity_kind"]

            if intent == "workout_extract":
                yield _sse({"stage": "extracting", "intent": "workout_extract"})
                workout = await extract_workout(content, locale=request.locale)
                # RAG-match library ids (best-effort)
                workout.exercises = await match_exercises_to_library(workout.exercises)
                exercises_payload = [
                    {
                        "name": e.name, "sets": e.sets, "reps": e.reps,
                        "rest_s": e.rest_s, "weight_hint": e.weight_hint,
                        "equipment": e.equipment, "notes": e.notes,
                        "source_timestamp_s": e.source_timestamp_s,
                        "library_id": e.library_id, "confidence": e.confidence,
                    }
                    for e in workout.exercises
                ]
                extracted_payload.update({
                    "title": workout.title,
                    "estimated_duration_min": workout.estimated_duration_min,
                    "difficulty": workout.difficulty,
                    "equipment_needed": workout.equipment_needed,
                    "exercises": exercises_payload,
                    "notes": workout.notes,
                })
                # Stream exercise discoveries one-by-one for nicer UI.
                for idx, e in enumerate(exercises_payload):
                    yield _sse({
                        "stage": "exercise_found",
                        "index": idx, "of": len(exercises_payload),
                        "name": e["name"], "sets": e["sets"], "reps": e["reps"],
                    })
                _merge_tags(item_id, user_id, {
                    "exercise_count": len(exercises_payload),
                    "duration_s": (workout.estimated_duration_min or 0) * 60,
                })

            elif intent in ("recipe_extract", "meal_plan_extract", "food_log_extract",
                            "form_check", "progress_log", "tip_save",
                            "nutrition_question", "discuss"):
                # These intents don't require a heavy extractor server-side.
                # The client receives the SharedContent text + intent and
                # routes to the destination screen with prefilled content.
                extracted_payload.update({
                    "title": content.title,
                    "author": content.author_handle,
                    "caption": content.caption,
                    "body": content.body,
                    "transcript_preview": (content.transcript or "")[:2000],
                    "media_s3_keys": [m.s3_key for m in content.media],
                })

            _update_shared_item(item_id, user_id, {
                "extracted_payload": extracted_payload,
                "target_entity_kind": target_entity_kind,
                "status": "completed",
                "media_s3_keys": [m.s3_key for m in content.media],
            })

            # Best-effort push notification once the heavy lift is done.
            await _try_notify_completed(
                user_id=user_id,
                item_id=item_id,
                intent=intent,
                extracted=extracted_payload,
                source_origin=source_origin,
            )

            yield _sse({
                "stage": "done",
                "intent": intent,
                "confidence": result["confidence"],
                "secondary_intents": result.get("secondary_intents", []),
                "redirect_screen": routing["redirect_screen"],
                "shared_item_id": item_id,
                "payload": extracted_payload,
            })
        except Exception as e:
            logger.exception(f"[FetchUrl] error: {e}")
            try:
                _update_shared_item(item_id, user_id, {
                    "status": "failed",
                    "error_message": str(e)[:500],
                })
                await notify_share_failed(
                    user_id=user_id,
                    shared_item_id=item_id,
                    reason=str(e),
                )
            except Exception:
                pass
            yield _sse({"stage": "error", "message": "Something went wrong importing this link."})

    return StreamingResponse(stream(), media_type="text/event-stream")


# ---------------------------------------------------------------------------
# Notification summary helpers
# ---------------------------------------------------------------------------

async def _try_notify_completed(
    *,
    user_id: str,
    item_id: str,
    intent: str,
    extracted: dict,
    source_origin: str,
) -> None:
    """Compute a friendly summary string and push it. Best-effort."""
    try:
        if intent == "workout_extract":
            ex_count = len(extracted.get("exercises") or [])
            origin_label = {
                "youtube": "YouTube",
                "instagram": "Instagram",
                "tiktok": "TikTok",
                "reddit": "Reddit",
                "x": "X",
            }.get(source_origin, "a link")
            summary = f"{ex_count} exercises from {origin_label}"
        elif intent == "recipe_extract":
            summary = (extracted.get("title") or "a recipe")
        elif intent == "meal_plan_extract":
            summary = "a 7-day meal plan"
        elif intent == "food_log_extract":
            summary = "your meal"
        elif intent == "tip_save":
            summary = "a tip"
        elif intent == "form_check":
            summary = "your form clip"
        elif intent == "progress_log":
            summary = "a progress photo"
        else:
            summary = "the share"
        await notify_share_completed(
            user_id=user_id,
            shared_item_id=item_id,
            intent=intent,
            summary=summary,
        )
    except Exception as e:
        logger.info(f"[FetchUrl] notify_completed dropped: {e}")


# ===========================================================================
# /share/import-audio — voice memo pipeline
# ===========================================================================

@router.post("/import-audio")
async def import_audio(
    file: UploadFile = File(...),
    locale: Optional[str] = Form(default=None),
    current_user: dict = Depends(get_current_user),
):
    """Voice memo or other audio file → Gemini audio understanding →
    intent classifier → routing. SSE."""
    user_id = current_user["id"]
    await _check_and_increment_cap(user_id, "audio")

    data = await file.read()
    if len(data) > MAX_SIZES["audio"]:
        raise HTTPException(413, "Audio too large (>100 MB)")
    if len(data) < 200:
        raise HTTPException(400, "Audio file appears empty")

    mime = file.content_type or "audio/mp4"

    item_id = _new_shared_item(
        user_id=user_id,
        source_kind="audio",
        source_origin="voicememos",
        tags={"format": "audio", "origin": "voicememos"},
        status="extracting",
    )

    async def stream():
        try:
            yield _sse({"stage": "received", "shared_item_id": item_id})
            yield _sse({"stage": "transcribing", "size_bytes": len(data)})
            understanding = await transcribe_and_hint(data, mime_type=mime)

            if not understanding.transcript:
                _update_shared_item(item_id, user_id, {
                    "status": "failed",
                    "error_message": "Couldn't transcribe audio.",
                })
                yield _sse({"stage": "error",
                            "message": "We couldn't hear anything in that audio.",
                            "shared_item_id": item_id})
                return

            yield _sse({
                "stage": "transcribed",
                "transcript_preview": understanding.transcript[:500],
                "hint": understanding.content_hint,
            })

            fp = normalize_text(understanding.transcript)
            result = await classify_intent(
                text=fp.text,
                source_origin="voicememos",
                locale=locale,
                extra_signals={
                    **fingerprints_to_signals(fp),
                    "audio_hint": understanding.content_hint or "",
                },
            )
            intent = result["intent"]
            routing = INTENT_ROUTING.get(intent, INTENT_ROUTING["discuss"])

            _update_shared_item(item_id, user_id, {
                "raw_text": understanding.transcript[: MAX_SIZES["text_db_truncate_bytes"]],
                "classifier_intent": intent,
                "classifier_confidence": result["confidence"],
                "target_entity_kind": routing["target_entity_kind"],
                "status": "completed",
                "extracted_payload": {
                    "transcript": understanding.transcript[:8000],
                    "intent": intent,
                    "audio_hint": understanding.content_hint,
                },
            })
            _merge_tags(item_id, user_id, {
                "category": _intent_to_category(intent),
                "format": "audio",
                "origin": "voicememos",
                "audio_hint": understanding.content_hint,
            })

            yield _sse({
                "stage": "done",
                "intent": intent,
                "confidence": result["confidence"],
                "redirect_screen": routing["redirect_screen"],
                "shared_item_id": item_id,
                "transcript": understanding.transcript[:8000],
            })
        except Exception as e:
            logger.exception(f"[ImportAudio] error: {e}")
            try:
                _update_shared_item(item_id, user_id, {
                    "status": "failed",
                    "error_message": str(e)[:500],
                })
            except Exception:
                pass
            yield _sse({"stage": "error", "message": "Something went wrong importing that audio."})

    return StreamingResponse(stream(), media_type="text/event-stream")


# ===========================================================================
# /share/import-pdf — PDF pipeline
# ===========================================================================

@router.post("/import-pdf")
async def import_pdf(
    file: UploadFile = File(...),
    locale: Optional[str] = Form(default=None),
    current_user: dict = Depends(get_current_user),
):
    """PDF → Gemini PDF understanding → intent classifier → routing. SSE."""
    user_id = current_user["id"]
    await _check_and_increment_cap(user_id, "pdf")

    data = await file.read()
    if len(data) > MAX_SIZES["pdf"]:
        raise HTTPException(413, "PDF too large (>50 MB)")
    if len(data) < 200:
        raise HTTPException(400, "PDF appears empty")

    item_id = _new_shared_item(
        user_id=user_id,
        source_kind="pdf",
        source_origin="files",
        tags={"format": "pdf", "origin": "files"},
        status="extracting",
    )

    async def stream():
        try:
            yield _sse({"stage": "received", "shared_item_id": item_id})
            yield _sse({"stage": "reading_pdf", "size_bytes": len(data)})
            understanding = await understand_pdf(data)

            if understanding.locked:
                _update_shared_item(item_id, user_id, {
                    "status": "failed",
                    "error_message": "Password-protected or unreadable PDF.",
                })
                yield _sse({"stage": "locked",
                            "message": "This PDF is locked. Unlock it and try again."})
                return

            if not understanding.text:
                _update_shared_item(item_id, user_id, {
                    "status": "failed",
                    "error_message": understanding.error or "Couldn't read PDF.",
                })
                yield _sse({"stage": "error",
                            "message": "Couldn't read anything from that PDF."})
                return

            yield _sse({"stage": "read", "char_count": len(understanding.text)})

            fp = normalize_text(understanding.text)
            result = await classify_intent(
                text=fp.text,
                source_origin="files",
                locale=locale,
                extra_signals=fingerprints_to_signals(fp),
            )
            intent = result["intent"]
            routing = INTENT_ROUTING.get(intent, INTENT_ROUTING["discuss"])

            _update_shared_item(item_id, user_id, {
                "raw_text": understanding.text[: MAX_SIZES["text_db_truncate_bytes"]],
                "classifier_intent": intent,
                "classifier_confidence": result["confidence"],
                "target_entity_kind": routing["target_entity_kind"],
                "status": "completed",
                "extracted_payload": {
                    "intent": intent,
                    "text_preview": understanding.text[:8000],
                },
            })
            _merge_tags(item_id, user_id, {
                "category": _intent_to_category(intent),
                "format": "pdf",
                "origin": "files",
            })

            yield _sse({
                "stage": "done",
                "intent": intent,
                "confidence": result["confidence"],
                "redirect_screen": routing["redirect_screen"],
                "shared_item_id": item_id,
                "text": understanding.text[:8000],
            })
        except Exception as e:
            logger.exception(f"[ImportPdf] error: {e}")
            try:
                _update_shared_item(item_id, user_id, {
                    "status": "failed",
                    "error_message": str(e)[:500],
                })
            except Exception:
                pass
            yield _sse({"stage": "error", "message": "Something went wrong importing that PDF."})

    return StreamingResponse(stream(), media_type="text/event-stream")
