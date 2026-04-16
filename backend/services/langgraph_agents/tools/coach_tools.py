"""
Coach-agent chat tools.

These tools let the Coach agent kick off the two new AI import flows from
within a chat conversation:

  - `import_gym_equipment`: async job that reads a gym's equipment list from
    a PDF/Word doc, photos, text, or URL — matches it against our equipment
    taxonomy, and returns a job_id for the frontend to poll.
  - `import_exercise`: photo / text run synchronously and create a custom
    exercise row + index it into the custom-exercise ChromaDB collection;
    video runs asynchronously as a media_analysis_jobs row.

Conventions:
  - NO silent fallbacks — if Gemini / DB / S3 fail, the tool raises so
    chat surfaces a real error to the user instead of claiming success.
  - action_data is set on the return dict so the Flutter chat UI can render
    the correct follow-up sheet (import_equipment_result_sheet.dart /
    import_exercise_preview_sheet.dart).
"""
from __future__ import annotations

import asyncio
from typing import Any, Dict, List, Optional

from langchain_core.tools import tool

from core.logger import get_logger

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Helpers (sync-wrapping async calls so @tool works with langchain's
# tool-executor regardless of whether the agent invokes sync or async.)
# ---------------------------------------------------------------------------

def _run_coro(coro):
    """Run an async coroutine from a sync tool callable.

    Mirrors the pattern in `tools/base.py::run_async_in_sync`. We import
    lazily to avoid a circular import during package init.
    """
    try:
        from .base import run_async_in_sync  # lazy import
        return run_async_in_sync(coro)
    except Exception:
        # Last resort — create a new loop.
        return asyncio.get_event_loop().run_until_complete(coro)


# ---------------------------------------------------------------------------
# Tool A — import_gym_equipment
# ---------------------------------------------------------------------------

@tool
async def import_gym_equipment(
    user_id: str,
    source: str,
    gym_profile_id: Optional[str] = None,
    s3_keys: Optional[List[str]] = None,
    mime_types: Optional[List[str]] = None,
    raw_text: Optional[str] = None,
    url: Optional[str] = None,
) -> Dict[str, Any]:
    """Import gym equipment from a PDF/Word document, photo(s), pasted text, or URL.

    Kicks off an async extraction job and returns a job_id. The frontend will
    poll `/media-jobs/{job_id}` and show a confirmation sheet when done.

    Args:
        user_id: The user initiating the import.
        source: One of 'file', 'images', 'text', 'url'.
        gym_profile_id: Optional — if omitted, falls back to the user's active
            gym profile. Required for the backend to know which profile to
            update once the user confirms.
        s3_keys: Required when source='file' (single key) or source='images'
            (one or more keys).
        mime_types: Parallel to `s3_keys`. For source='file' the first entry
            determines PDF/DOCX/image parsing.
        raw_text: Required when source='text'. The pasted equipment list.
        url: Required when source='url'. Generic HTML pages only.

    Returns:
        dict with keys:
          success: bool
          action: 'import_gym_equipment'
          job_id: str
          gym_profile_id: str
          message: str (chat-ready copy)
    """
    logger.info(
        f"🏋️ [coach_tool.import_gym_equipment] user={user_id} source={source} "
        f"profile={gym_profile_id}"
    )

    # Lazy imports — keep tool import time cheap.
    from core.supabase_client import get_supabase
    from services.media_job_service import get_media_job_service
    from services.media_job_runner import run_media_job

    # Validate source payload.
    src = (source or "").lower().strip()
    if src not in ("file", "images", "text", "url"):
        return {
            "success": False,
            "action": "import_gym_equipment",
            "error": f"Invalid source '{source}'. Expected one of: file, images, text, url.",
        }

    if src == "file" and not (s3_keys and mime_types):
        return {
            "success": False,
            "action": "import_gym_equipment",
            "error": "source='file' requires s3_keys[0] and mime_types[0].",
        }
    if src == "images" and not s3_keys:
        return {
            "success": False,
            "action": "import_gym_equipment",
            "error": "source='images' requires at least one S3 key.",
        }
    if src == "text" and not (raw_text and raw_text.strip()):
        return {
            "success": False,
            "action": "import_gym_equipment",
            "error": "source='text' requires non-empty raw_text.",
        }
    if src == "url" and not url:
        return {
            "success": False,
            "action": "import_gym_equipment",
            "error": "source='url' requires a url.",
        }

    # Resolve gym_profile_id if not provided — use user's active profile.
    supabase = get_supabase()
    if not gym_profile_id:
        try:
            # 1. Prefer users.active_gym_profile_id
            user_row = (
                supabase.client.table("users")
                .select("active_gym_profile_id")
                .eq("id", user_id)
                .limit(1)
                .execute()
            )
            if user_row.data and user_row.data[0].get("active_gym_profile_id"):
                gym_profile_id = user_row.data[0]["active_gym_profile_id"]
            else:
                # 2. Fallback: first is_active=true profile for this user.
                active = (
                    supabase.client.table("gym_profiles")
                    .select("id")
                    .eq("user_id", user_id)
                    .eq("is_active", True)
                    .limit(1)
                    .execute()
                )
                if active.data:
                    gym_profile_id = active.data[0]["id"]
        except Exception as e:
            logger.error(
                f"❌ [coach_tool.import_gym_equipment] Failed to resolve active profile: {e}",
                exc_info=True,
            )
            return {
                "success": False,
                "action": "import_gym_equipment",
                "error": "Could not resolve your active gym profile. Open the Gym screen and try again.",
            }

    if not gym_profile_id:
        return {
            "success": False,
            "action": "import_gym_equipment",
            "error": "No active gym profile found. Create or activate a gym profile first.",
        }

    # Build params; mirror the HTTP endpoint (gym_profiles.py) shape so the
    # same runner branch handles it.
    params: Dict[str, Any] = {"source": src, "gym_profile_id": gym_profile_id}
    job_s3_keys: List[str] = []
    job_mimes: List[str] = []
    job_media_types: List[str] = []

    if src == "file":
        job_s3_keys = [s3_keys[0]]  # type: ignore[index]
        job_mimes = [mime_types[0]]  # type: ignore[index]
        first_mime = job_mimes[0]
        job_media_types = [
            "document" if first_mime in (
                "application/pdf",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ) else "image"
        ]
        params.update({"s3_key": job_s3_keys[0], "mime_type": first_mime})
    elif src == "images":
        job_s3_keys = list(s3_keys or [])
        job_mimes = (mime_types or ["image/jpeg"] * len(job_s3_keys))
        job_media_types = ["image"] * len(job_s3_keys)
        params.update({"s3_keys": job_s3_keys})
    elif src == "text":
        params.update({"raw_text": raw_text})
    elif src == "url":
        params.update({"url": url})

    try:
        job_service = get_media_job_service()
        job_id = job_service.create_job(
            user_id=user_id,
            job_type="gym_equipment_import",
            s3_keys=job_s3_keys,
            mime_types=job_mimes,
            media_types=job_media_types,
            params=params,
        )
        # Fire-and-forget execution. Runner updates the row on its own.
        asyncio.create_task(run_media_job(job_id))
        logger.info(f"✅ [coach_tool.import_gym_equipment] dispatched job {job_id}")
    except Exception as e:
        logger.error(
            f"❌ [coach_tool.import_gym_equipment] failed to enqueue job: {e}",
            exc_info=True,
        )
        return {
            "success": False,
            "action": "import_gym_equipment",
            "error": "Failed to start equipment import. Please try again.",
        }

    return {
        "success": True,
        "action": "import_gym_equipment",
        "job_id": job_id,
        "gym_profile_id": gym_profile_id,
        "message": (
            "Analyzing your gym's equipment list — you'll see the matches in a "
            "moment. I'll let you review before saving."
        ),
    }


# ---------------------------------------------------------------------------
# Tool B — import_exercise
# ---------------------------------------------------------------------------

@tool
async def import_exercise(
    user_id: str,
    source: str,
    s3_key: Optional[str] = None,
    raw_text: Optional[str] = None,
    user_hint: Optional[str] = None,
) -> Dict[str, Any]:
    """Import a custom exercise from a photo, short video, or text description.

    Photo and text are synchronous and return the fully-persisted exercise row.
    Video is async: we enqueue a `custom_exercise_import` media job and return
    a job_id for the frontend to poll.

    Args:
        user_id: The owner of the custom exercise row.
        source: One of 'photo', 'video', 'text'.
        s3_key: Required for 'photo' and 'video'. Key of the uploaded media.
        raw_text: Required for 'text'. E.g. "cable tricep pushdown with rope".
        user_hint: Optional name hint for disambiguation (e.g. 'seated cable row').

    Returns:
        For photo/text:
          {success, action='exercise_imported', exercise: {...}, rag_indexed, duplicate, message}
        For video:
          {success, action='exercise_import_pending', job_id, message}
    """
    src = (source or "").lower().strip()
    logger.info(f"🤖 [coach_tool.import_exercise] user={user_id} source={src}")

    if src not in ("photo", "video", "text"):
        return {
            "success": False,
            "action": "import_exercise",
            "error": f"Invalid source '{source}'. Expected one of: photo, video, text.",
        }

    if src in ("photo", "video") and not s3_key:
        return {
            "success": False,
            "action": "import_exercise",
            "error": f"source='{src}' requires an s3_key.",
        }
    if src == "text" and not (raw_text and raw_text.strip()):
        return {
            "success": False,
            "action": "import_exercise",
            "error": "source='text' requires raw_text.",
        }

    # Lazy imports (avoid circular import during package init).
    from core.db import get_supabase_db
    from services.ai_exercise_extractor import get_ai_exercise_extractor
    from services.media_job_service import get_media_job_service
    from services.media_job_runner import run_media_job
    from api.v1.custom_exercises import _save_imported_exercise  # shared helper

    try:
        if src == "photo":
            extractor = get_ai_exercise_extractor()
            payload = await extractor.extract_from_photo(
                s3_key=s3_key, user_hint=user_hint,
            )
            db = get_supabase_db()
            row, rag_indexed, duplicate = await _save_imported_exercise(db, user_id, payload)
            name = row.get("name", "exercise")
            msg = (
                f"Found an existing exercise — '{name}' is already in your library."
                if duplicate else
                f"Added '{name}' to your exercises."
            )
            return {
                "success": True,
                "action": "exercise_imported",
                "exercise": row,
                "rag_indexed": rag_indexed,
                "duplicate": duplicate,
                "message": msg,
            }

        if src == "text":
            extractor = get_ai_exercise_extractor()
            payload = await extractor.extract_from_text(
                raw_text=raw_text or "", user_hint=user_hint,
            )
            db = get_supabase_db()
            row, rag_indexed, duplicate = await _save_imported_exercise(db, user_id, payload)
            name = row.get("name", "exercise")
            msg = (
                f"Found an existing exercise — '{name}' is already in your library."
                if duplicate else
                f"Added '{name}' to your exercises."
            )
            return {
                "success": True,
                "action": "exercise_imported",
                "exercise": row,
                "rag_indexed": rag_indexed,
                "duplicate": duplicate,
                "message": msg,
            }

        # Video → async job
        job_service = get_media_job_service()
        job_id = job_service.create_job(
            user_id=user_id,
            job_type="custom_exercise_import",
            s3_keys=[s3_key or ""],
            mime_types=["video/mp4"],
            media_types=["video"],
            params={
                "user_id": user_id,
                "user_hint": user_hint,
                "source": "video",
            },
        )
        asyncio.create_task(run_media_job(job_id))
        logger.info(f"✅ [coach_tool.import_exercise] dispatched video job {job_id}")
        return {
            "success": True,
            "action": "exercise_import_pending",
            "job_id": job_id,
            "message": "Analyzing your exercise video… I'll show you the details to confirm in a moment.",
        }

    except ValueError as ve:
        logger.warning(f"⚠️ [coach_tool.import_exercise] validation: {ve}")
        return {
            "success": False,
            "action": "import_exercise",
            "error": str(ve),
        }
    except Exception as e:
        logger.error(
            f"❌ [coach_tool.import_exercise] failed: {e}", exc_info=True
        )
        return {
            "success": False,
            "action": "import_exercise",
            "error": "Failed to import exercise. Please try again.",
        }
