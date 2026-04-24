"""
Background runner for media analysis jobs (form check, form comparison, food analysis).

Uses an asyncio semaphore to limit concurrency and supports automatic retry
with exponential backoff for transient errors.
"""
import asyncio
from core.logger import get_logger, set_log_context
from services.media_job_service import get_media_job_service

logger = get_logger(__name__)

# Limit concurrent media analysis jobs (heavy GPU/API calls)
_MEDIA_SEMAPHORE = asyncio.Semaphore(3)


async def run_media_job(job_id: str):
    """Execute a media analysis job with retry logic."""
    service = get_media_job_service()
    job = service.get_job(job_id)
    if not job:
        logger.error(f"Media job {job_id} not found")
        return

    # Set log context so all logs in this task include user_id
    uid = job.get("user_id")
    if uid:
        truncated = f"...{uid[-4:]}" if len(uid) > 4 else uid
        set_log_context(user_id=truncated)

    async with _MEDIA_SEMAPHORE:
        service.update_job_status(job_id, "in_progress")
        try:
            job_type = job["job_type"]
            if job_type == "form_analysis":
                result = await _execute_form_analysis(job)
            elif job_type == "form_comparison":
                result = await _execute_form_comparison(job)
            elif job_type == "food_analysis":
                result = await _execute_food_analysis(job)
            elif job_type == "gym_equipment_import":
                result = await _execute_gym_equipment_import(job)
            # === AI_EXERCISE_IMPORT_BRANCH ===
            elif job_type == "custom_exercise_import":
                result = await _execute_custom_exercise_import(job)
            # === WORKOUT_HISTORY_IMPORT_BRANCH ===
            elif job_type == "workout_history_import":
                result = await _execute_workout_history_import(job)
            else:
                raise ValueError(f"Unknown media job type: {job_type}")

            service.update_job_status(job_id, "completed", result=result)
            logger.info(f"Media job {job_id} completed successfully")

            # Track premium gate usage after successful form analysis/comparison
            if job_type in ("form_analysis", "form_comparison"):
                try:
                    from core.premium_gate import track_premium_usage
                    await track_premium_usage(job["user_id"], "form_video_analysis", "UTC")
                except Exception as usage_err:
                    logger.warning(f"Failed to track form_video_analysis usage for job {job_id}: {usage_err}", exc_info=True)
        except Exception as e:
            retry_count = job.get("retry_count", 0)
            if _is_transient_error(e) and retry_count < 3:
                # Schedule retry with exponential backoff
                delay = 5 * (2 ** retry_count)
                service.update_job_status(
                    job_id, "pending",
                    retry_count=retry_count + 1,
                    error_message=str(e),
                )
                logger.warning(
                    f"Media job {job_id} failed (attempt {retry_count + 1}), "
                    f"retrying in {delay}s: {e}"
                , exc_info=True)
                await asyncio.sleep(delay)
                asyncio.create_task(run_media_job(job_id))
            else:
                service.update_job_status(job_id, "failed", error_message=str(e))
                logger.error(f"Media job {job_id} permanently failed: {e}", exc_info=True)


def _is_transient_error(e: Exception) -> bool:
    """Check if error is transient (timeout, API rate limit, etc.)."""
    transient_types = (TimeoutError, ConnectionError, asyncio.TimeoutError)
    if isinstance(e, transient_types):
        return True
    error_str = str(e).lower()
    return any(kw in error_str for kw in ["timeout", "rate limit", "429", "503", "502"])


async def _execute_form_analysis(job: dict) -> dict:
    """Run single-video/image form analysis."""
    from services.form_analysis_service import FormAnalysisService

    service = FormAnalysisService()
    params = job.get("params", {})
    s3_keys = job.get("s3_keys", [])
    mime_types = job.get("mime_types", [])
    media_types = job.get("media_types", [])

    gemini_file_name = params.get("gemini_file_name")
    video_frames = params.get("video_frames")

    if gemini_file_name:
        logger.info(f"Using pre-uploaded Gemini file: {gemini_file_name} (skipping S3 download)")
    elif video_frames:
        logger.info(f"Using {len(video_frames)} pre-extracted frames (skipping S3 download)")

    return await service.analyze_form(
        s3_key=s3_keys[0] if s3_keys else "",
        mime_type=mime_types[0] if mime_types else "video/mp4",
        media_type=media_types[0] if media_types else "video",
        exercise_name=params.get("exercise_name"),
        user_context=params.get("user_context"),
        video_frames=video_frames,
        gemini_file_name=gemini_file_name,
    )


async def _execute_form_comparison(job: dict) -> dict:
    """Run side-by-side form comparison analysis."""
    from services.form_analysis_service import FormAnalysisService

    service = FormAnalysisService()
    params = job.get("params", {})

    return await service.analyze_form_comparison(
        s3_keys=job.get("s3_keys", []),
        mime_types=job.get("mime_types", []),
        labels=params.get("labels", []),
        exercise_name=params.get("exercise_name"),
        user_context=params.get("user_context"),
    )


async def _execute_food_analysis(job: dict) -> dict:
    """Run food/nutrition image analysis."""
    from services.vision_service import get_vision_service

    service = get_vision_service()
    params = job.get("params", {})

    return await service.analyze_food_from_s3_keys(
        s3_keys=job.get("s3_keys", []),
        mime_types=job.get("mime_types", []),
        user_context=params.get("user_context"),
        analysis_mode=params.get("analysis_mode", "auto"),
        nutrition_context=params.get("nutrition_context"),
    )


async def _execute_gym_equipment_import(job: dict) -> dict:
    """Run AI gym-equipment extraction for a media_analysis_jobs row.

    Input contract: job['params'] contains the dispatcher body:
      {
        "source": "file" | "images" | "text" | "url",
        # one of:
        "s3_key": "...", "mime_type": "application/pdf" | ... | "image/*",
        "s3_keys": [...],
        "raw_text": "...",
        "url": "..."
      }

    Returns the full extractor result dict (persisted into result_json by the runner).
    """
    from services.gym_equipment_extractor import GymEquipmentExtractor

    params = job.get("params") or {}
    source = params.get("source")
    if not source:
        raise ValueError("gym_equipment_import job is missing params.source")

    logger.info(f"🏋️ [MediaJobRunner] gym_equipment_import starting (source={source})")

    extractor = GymEquipmentExtractor()

    # Forward only the keys relevant to each source so extra fields don't leak through.
    if source == "file":
        return await extractor.extract(
            source="file",
            s3_key=params.get("s3_key"),
            mime_type=params.get("mime_type"),
        )
    if source == "images":
        return await extractor.extract(
            source="images",
            s3_keys=params.get("s3_keys") or job.get("s3_keys") or [],
        )
    if source == "text":
        return await extractor.extract(source="text", raw_text=params.get("raw_text"))
    if source == "url":
        return await extractor.extract(source="url", url=params.get("url"))

    raise ValueError(f"Unknown gym_equipment_import source: {source}")


# === AI_EXERCISE_IMPORT_BRANCH ===
async def _execute_custom_exercise_import(job: dict) -> dict:
    """
    Run AI custom-exercise extraction for a video upload, persist the resulting
    custom_exercises row, and index it into ChromaDB.

    Input contract: job['s3_keys'][0] is the video s3_key; job['params'] contains:
      { "user_id": "...", "user_hint": <str|None>, "source": "video" }

    Returns a dict shaped like:
      {
        "exercise": <full CustomExercise row>,
        "rag_indexed": true|false,
        "keyframe_confidences": [0.8, 0.9, 0.7],
        "duplicate": false
      }
    """
    from services.ai_exercise_extractor import get_ai_exercise_extractor
    from services.exercise_rag.service import get_exercise_rag_service
    from core.db import get_supabase_db

    params = job.get("params") or {}
    user_id = params.get("user_id") or job.get("user_id")
    user_hint = params.get("user_hint")
    s3_keys = job.get("s3_keys") or []
    if not user_id:
        raise ValueError("custom_exercise_import job missing user_id")
    if not s3_keys:
        raise ValueError("custom_exercise_import job missing s3_keys")

    s3_key = s3_keys[0]
    logger.info(
        f"🤖 [MediaJobRunner] custom_exercise_import starting "
        f"(user={user_id}, s3_key={s3_key}, hint={user_hint!r})"
    )

    extractor = get_ai_exercise_extractor()
    payload = await extractor.extract_from_video(
        s3_key=s3_key,
        user_hint=user_hint,
        num_frames=3,
    )

    keyframe_confidences = payload.pop("keyframe_confidences", [])

    # Persist + dedupe + RAG index. Mirrors `_save_imported_exercise` but lives
    # in the runner context (no FastAPI request).
    db = get_supabase_db()
    name = (payload.get("name") or "").strip()
    if not name:
        raise ValueError("Extracted exercise has no name")

    duplicate = False
    row = None
    try:
        existing = (
            db.client.table("custom_exercises")
            .select("*")
            .eq("user_id", user_id)
            .ilike("name", name)
            .limit(1)
            .execute()
        )
        if existing and existing.data:
            row = existing.data[0]
            duplicate = True
            logger.info(f"🏋️ Duplicate import detected for '{name}' — reusing existing row {row.get('id')}")
    except Exception as e:
        logger.warning(f"⚠️ Duplicate-check query failed (continuing with insert): {e}", exc_info=True)

    if not duplicate:
        # Pydantic import deferred to avoid FastAPI startup cost.
        from api.v1.custom_exercises import CustomExerciseCreate

        allowed_keys = set(CustomExerciseCreate.model_fields.keys())
        insert_data = {k: v for k, v in payload.items() if k in allowed_keys}
        insert_data["user_id"] = user_id
        insert_data.setdefault("is_public", False)

        result = db.client.table("custom_exercises").insert(insert_data).execute()
        if not result.data:
            raise RuntimeError("Failed to persist imported custom exercise (insert returned no rows)")
        row = result.data[0]
        logger.info(f"🏋️ Imported custom exercise '{name}' for user {user_id} (id={row.get('id')})")

    rag_indexed = False
    try:
        rag_service = get_exercise_rag_service()
        rag_indexed = await rag_service.index_custom_exercise(row)
    except Exception as rag_err:
        logger.warning(
            f"⚠️ RAG indexing failed (non-fatal) for imported exercise {row.get('id')}: {rag_err}",
            exc_info=True,
        )

    return {
        "exercise": row,
        "rag_indexed": rag_indexed,
        "keyframe_confidences": keyframe_confidences,
        "duplicate": duplicate,
    }


# === WORKOUT_HISTORY_IMPORT_BRANCH ===
async def _execute_workout_history_import(job: dict) -> dict:
    """Run bulk workout-history + cardio + program-template import for a
    media_analysis_jobs row.

    Input contract: job['s3_keys'][0] is the uploaded file s3_key; job['params']:
      {
        "user_id": "...",
        "unit_hint": "kg" | "lb",            # user-specified at upload time
        "timezone_hint": "America/Chicago",  # user-specified (null = UTC)
        "source_app_hint": "hevy" | ... | null,  # optional override for detector
        "filename": "workout_history.csv",
        "dry_run": false,                    # true = preview only, no DB writes
      }

    Returns the import summary dict (persisted into result_json).
    """
    from services.workout_import.service import WorkoutHistoryImporter

    importer = WorkoutHistoryImporter()
    summary = await importer.run(job)
    return summary


async def resume_pending_media_jobs():
    """Resume pending media jobs on server startup."""
    try:
        service = get_media_job_service()
        service.cancel_stale_jobs(older_than_hours=2)
        pending = service.get_pending_jobs()
        if pending:
            logger.info(f"Resuming {len(pending)} pending media analysis jobs")
            for job in pending:
                asyncio.create_task(run_media_job(job["id"]))
        else:
            logger.info("No pending media analysis jobs to resume")
    except Exception as e:
        logger.error(f"Failed to resume media jobs: {e}", exc_info=True)
