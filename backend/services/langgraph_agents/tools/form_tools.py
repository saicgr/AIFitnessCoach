"""
Exercise form analysis tools for LangGraph agents.

Contains tools for:
- Analyzing exercise form from uploaded video/image media
- Comparing exercise form across multiple videos
"""

from typing import Any, Dict, List, Optional

from langchain_core.tools import tool

from core.logger import get_logger
from services.media_job_service import get_media_job_service
from .base import get_form_analysis_service, run_async_in_sync

logger = get_logger(__name__)


def _dispatch_async_form_job(
    user_id: str,
    job_type: str,
    s3_keys: List[str],
    mime_types: List[str],
    media_types: List[str],
    params: Dict[str, Any],
) -> Dict[str, Any]:
    """Create a background media job and return an async response."""
    try:
        service = get_media_job_service()
        job_id = service.create_job(
            user_id=user_id,
            job_type=job_type,
            s3_keys=s3_keys,
            mime_types=mime_types,
            media_types=media_types,
            params=params,
        )

        # Kick off the job in the background
        import asyncio
        from services.media_job_runner import run_media_job
        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                loop.create_task(run_media_job(job_id))
        except RuntimeError as e:
            logger.debug(f"No running loop for async job: {e}")

        action = "check_exercise_form" if job_type == "form_analysis" else "compare_exercise_form"
        logger.info(f"Dispatched async {job_type} job {job_id} for user {user_id}")

        return {
            "success": True,
            "async_job": True,
            "action": action,
            "job_id": job_id,
            "user_id": user_id,
            "message": "Analyzing your form in the background. Results will be ready shortly. You can check the status with the job ID.",
        }
    except Exception as e:
        logger.error(f"Failed to dispatch async {job_type} job for user {user_id}: {e}")
        return {
            "success": False,
            "action": "check_exercise_form",
            "user_id": user_id,
            "message": f"Failed to start form analysis: {str(e)}",
        }


@tool
def check_exercise_form(
    user_id: str,
    s3_key: str,
    mime_type: str,
    media_type: str,
    exercise_name: Optional[str] = None,
    user_message: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Analyze exercise form from an uploaded video or image.

    Uses Gemini Vision to analyze the user's exercise form, identify issues,
    score their technique, and provide actionable corrections.

    Args:
        user_id: The user's ID (UUID string)
        s3_key: S3 object key for the uploaded media
        mime_type: MIME type of the media (e.g., 'video/mp4', 'image/jpeg')
        media_type: Type of media ('video' or 'image')
        exercise_name: Optional name of the exercise being performed
        user_message: Optional message from the user about the exercise

    Returns:
        Result dict with form analysis, score, issues, and recommendations
    """
    logger.info(f"Tool: Analyzing exercise form for user {user_id}, s3_key={s3_key}, media_type={media_type}")

    try:
        # Videos are dispatched as async background jobs (they take too long for sync)
        if media_type == "video":
            params = {}
            if exercise_name:
                params["exercise_name"] = exercise_name
            if user_message:
                params["user_context"] = user_message

            return _dispatch_async_form_job(
                user_id=user_id,
                job_type="form_analysis",
                s3_keys=[s3_key],
                mime_types=[mime_type],
                media_types=[media_type],
                params=params,
            )

        # Images are fast enough for synchronous processing
        service = get_form_analysis_service()

        # Build user context from message
        user_context = user_message if user_message else None

        # Run async analysis with 120s timeout
        result = run_async_in_sync(
            service.analyze_form(
                s3_key=s3_key,
                mime_type=mime_type,
                media_type=media_type,
                exercise_name=exercise_name,
                user_context=user_context,
            ),
            timeout=120,
        )

        # Check if content is not exercise
        content_type = result.get("content_type", "exercise")
        if content_type == "not_exercise":
            reason = result.get("not_exercise_reason", "This doesn't appear to show an exercise.")
            return {
                "success": True,
                "action": "check_exercise_form",
                "content_type": "not_exercise",
                "user_id": user_id,
                "media_type": media_type,
                "message": reason,
            }

        # Format into readable message
        exercise = result.get("exercise_identified", exercise_name or "Unknown Exercise")
        score = result.get("form_score", 0)
        rep_count = result.get("rep_count", 0)
        assessment = result.get("overall_assessment", "")
        issues = result.get("issues", [])
        positives = result.get("positives", [])
        recommendations = result.get("recommendations", [])
        breathing = result.get("breathing_analysis", {})
        tempo = result.get("tempo_analysis", {})
        video_quality = result.get("video_quality", {})

        # Build score label
        if score >= 8:
            score_label = "Excellent"
        elif score >= 6:
            score_label = "Good"
        elif score >= 4:
            score_label = "Needs Work"
        else:
            score_label = "Poor - Injury Risk"

        # Build message
        message = f"**Form Analysis: {exercise}**\n\n"
        message += f"**Form Score:** {score}/10 ({score_label})\n"
        if rep_count > 0:
            message += f"**Estimated Reps:** ~{rep_count}\n"
        message += f"\n{assessment}\n"

        if positives:
            message += "\n**What You're Doing Well:**\n"
            for pos in positives:
                message += f"- {pos}\n"

        if issues:
            message += "\n**Form Issues:**\n"
            for issue in issues:
                severity = issue.get("severity", "minor").upper()
                body_part = issue.get("body_part", "")
                desc = issue.get("description", "")
                correction = issue.get("correction", "")
                ts = issue.get("timestamp_seconds")

                message += f"\n[{severity}] **{body_part}**"
                if ts is not None:
                    message += f" (at {ts:.1f}s)"
                message += f"\n{desc}\n"
                message += f"Fix: {correction}\n"

        # Breathing analysis
        if breathing:
            breathing_status = "Good" if breathing.get("is_correct") else "Needs Work"
            message += f"\n**Breathing:** {breathing_status}\n"
            if breathing.get("pattern_observed"):
                message += f"Observed: {breathing['pattern_observed']}\n"
            if breathing.get("recommendation"):
                message += f"Tip: {breathing['recommendation']}\n"

        # Tempo analysis
        if tempo:
            tempo_status = "Good" if tempo.get("is_appropriate") else "Needs Adjustment"
            message += f"\n**Tempo:** {tempo_status}\n"
            if tempo.get("observed_tempo"):
                message += f"Observed: {tempo['observed_tempo']}\n"
            if tempo.get("recommendation") and not tempo.get("is_appropriate"):
                message += f"Tip: {tempo['recommendation']}\n"

        # Video quality tip
        if video_quality:
            rerecord = video_quality.get("rerecord_suggestion", "")
            if rerecord:
                message += f"\n{rerecord}\n"

        if recommendations:
            message += "\n**Recommendations:**\n"
            for rec in recommendations:
                message += f"- {rec}\n"

        return {
            "success": True,
            "action": "check_exercise_form",
            "content_type": "exercise",
            "user_id": user_id,
            "exercise_identified": exercise,
            "form_score": score,
            "rep_count": rep_count,
            "overall_assessment": assessment,
            "issues": issues,
            "positives": positives,
            "breathing_analysis": breathing,
            "tempo_analysis": tempo,
            "video_quality": video_quality,
            "recommendations": recommendations,
            "media_type": media_type,
            "message": message,
        }

    except TimeoutError:
        logger.error(f"Form analysis timed out for user {user_id}")
        return {
            "success": False,
            "action": "check_exercise_form",
            "user_id": user_id,
            "message": "Form analysis timed out. The video may be too long or the server is busy. Please try again with a shorter clip.",
        }
    except Exception as e:
        logger.error(f"Check exercise form failed for user {user_id}: {e}")
        return {
            "success": False,
            "action": "check_exercise_form",
            "user_id": user_id,
            "message": f"Failed to analyze exercise form: {str(e)}",
        }


@tool
def compare_exercise_form(
    user_id: str,
    s3_keys: List[str],
    mime_types: List[str],
    labels: List[str],
    exercise_name: Optional[str] = None,
    user_message: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Compare exercise form across multiple videos.

    Analyzes form consistency, fatigue breakdown, and improvements
    between sets or sessions.

    Args:
        user_id: User's UUID
        s3_keys: List of S3 keys for videos to compare
        mime_types: List of MIME types
        labels: Labels for each video (e.g., ["Set 1", "Set 5"])
        exercise_name: Optional exercise name
        user_message: Optional user context

    Returns:
        Comparison result with per-video scores and delta analysis
    """
    logger.info(f"Tool: Comparing exercise form for user {user_id}, {len(s3_keys)} videos")

    # Form comparison always runs as an async background job (multiple videos)
    params = {}
    if exercise_name:
        params["exercise_name"] = exercise_name
    if user_message:
        params["user_context"] = user_message
    if labels:
        params["labels"] = labels

    media_types = ["video"] * len(s3_keys)

    return _dispatch_async_form_job(
        user_id=user_id,
        job_type="form_comparison",
        s3_keys=s3_keys,
        mime_types=mime_types,
        media_types=media_types,
        params=params,
    )
