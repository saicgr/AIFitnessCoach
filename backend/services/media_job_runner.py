"""
Background runner for media analysis jobs (form check, form comparison, food analysis).

Uses an asyncio semaphore to limit concurrency and supports automatic retry
with exponential backoff for transient errors.
"""
import asyncio
from core.logger import get_logger
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
            else:
                raise ValueError(f"Unknown media job type: {job_type}")

            service.update_job_status(job_id, "completed", result=result)
            logger.info(f"Media job {job_id} completed successfully")

            # Track premium gate usage after successful form analysis/comparison
            if job_type in ("form_analysis", "form_comparison"):
                try:
                    from core.premium_gate import track_premium_usage
                    await track_premium_usage(job["user_id"], "form_video_analysis")
                except Exception as usage_err:
                    logger.warning(f"Failed to track form_video_analysis usage for job {job_id}: {usage_err}")
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
                )
                await asyncio.sleep(delay)
                asyncio.create_task(run_media_job(job_id))
            else:
                service.update_job_status(job_id, "failed", error_message=str(e))
                logger.error(f"Media job {job_id} permanently failed: {e}")


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

    return await service.analyze_form(
        s3_key=s3_keys[0],
        mime_type=mime_types[0],
        media_type=media_types[0],
        exercise_name=params.get("exercise_name"),
        user_context=params.get("user_context"),
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
        logger.error(f"Failed to resume media jobs: {e}")
