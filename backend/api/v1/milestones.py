"""
Progress Milestones & ROI Communication API endpoints.

Provides endpoints for:
- GET /api/v1/progress/milestones - Get achieved and upcoming milestones
- GET /api/v1/progress/roi - Get ROI metrics
- GET /api/v1/progress/roi/summary - Get compact ROI summary for home screen
- GET /api/v1/progress/milestones/uncelebrated - Get milestones pending celebration
- POST /api/v1/progress/milestones/celebrate - Mark milestones as celebrated
- POST /api/v1/progress/milestones/share - Record milestone share
- POST /api/v1/progress/milestones/check - Manually trigger milestone check
- GET /api/v1/progress/milestones/definitions - Get all milestone definitions
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from datetime import datetime

from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.milestones import (
    MilestoneCategory,
    MilestoneDefinition,
    UserMilestone,
    MilestoneProgress,
    MilestonesResponse,
    ROIMetrics,
    ROISummary,
    MilestoneCheckResult,
    MilestoneShareRequest,
    MarkMilestoneCelebratedRequest,
)
from services.milestone_service import milestone_service
from services.user_context_service import user_context_service, EventType

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# Milestone Definitions
# ============================================

@router.get("/milestones/definitions", response_model=List[MilestoneDefinition])
async def get_milestone_definitions(
    category: Optional[MilestoneCategory] = Query(
        None, description="Filter by category"
    ),
):
    """
    Get all milestone definitions.

    Optionally filter by category (workouts, streak, strength, volume, time, weight).
    """
    logger.info(f"Getting milestone definitions, category={category}")

    try:
        definitions = await milestone_service.get_all_milestone_definitions(
            category=category
        )
        return definitions
    except Exception as e:
        logger.error(f"Error getting milestone definitions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# User Milestones
# ============================================

@router.get("/milestones/{user_id}", response_model=MilestonesResponse)
async def get_user_milestones(user_id: str):
    """
    Get complete milestone progress for a user.

    Returns:
    - achieved: List of achieved milestones with details
    - upcoming: List of upcoming milestones with progress percentage
    - total_points: Total points earned from milestones
    - total_achieved: Count of achieved milestones
    - next_milestone: Closest milestone to being achieved
    - uncelebrated: Milestones that need celebration dialog
    """
    logger.info(f"Getting milestones for user: {user_id}")

    try:
        progress = await milestone_service.get_milestone_progress(user_id)

        # Log milestone view
        await log_user_activity(
            user_id=user_id,
            action="milestones_viewed",
            endpoint=f"/api/v1/progress/milestones/{user_id}",
            message=f"Viewed milestones: {progress.total_achieved} achieved, {len(progress.upcoming)} upcoming",
            metadata={
                "total_achieved": progress.total_achieved,
                "total_points": progress.total_points,
                "upcoming_count": len(progress.upcoming),
            },
            status_code=200,
        )

        return progress
    except Exception as e:
        logger.error(f"Error getting user milestones: {e}")
        await log_user_error(
            user_id=user_id,
            action="milestones_viewed",
            error=e,
            endpoint=f"/api/v1/progress/milestones/{user_id}",
            status_code=500,
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/milestones/{user_id}/uncelebrated", response_model=List[UserMilestone])
async def get_uncelebrated_milestones(user_id: str):
    """
    Get milestones that haven't been celebrated yet.

    These are milestones that the user has achieved but hasn't seen
    the celebration dialog for. Use this to trigger celebration UI.
    """
    logger.info(f"Getting uncelebrated milestones for user: {user_id}")

    try:
        uncelebrated = await milestone_service.get_uncelebrated_milestones(user_id)
        return uncelebrated
    except Exception as e:
        logger.error(f"Error getting uncelebrated milestones: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/milestones/{user_id}/celebrate")
async def mark_milestones_celebrated(
    user_id: str,
    request: MarkMilestoneCelebratedRequest,
):
    """
    Mark milestones as celebrated (user has seen celebration dialog).

    Call this after showing the celebration dialog to prevent
    showing it again.
    """
    logger.info(f"Marking milestones celebrated for user: {user_id}")

    try:
        success = await milestone_service.mark_milestones_celebrated(
            user_id=user_id,
            milestone_ids=request.milestone_ids,
        )

        if success:
            # Log milestone celebration
            await user_context_service.log_event(
                user_id=user_id,
                event_type=EventType.FEATURE_INTERACTION,
                event_data={
                    "feature": "milestone_celebration",
                    "milestone_ids": request.milestone_ids,
                    "count": len(request.milestone_ids),
                },
            )

        return {"success": success}
    except Exception as e:
        logger.error(f"Error marking milestones celebrated: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/milestones/{user_id}/share")
async def record_milestone_share(
    user_id: str,
    request: MilestoneShareRequest,
):
    """
    Record that a user shared a milestone.

    Track which platform was used for analytics.
    """
    logger.info(f"Recording milestone share for user: {user_id}")

    try:
        success = await milestone_service.record_milestone_share(
            user_id=user_id,
            milestone_id=request.milestone_id,
            platform=request.platform,
        )

        if success:
            # Log milestone share
            await user_context_service.log_event(
                user_id=user_id,
                event_type=EventType.FEATURE_INTERACTION,
                event_data={
                    "feature": "milestone_share",
                    "milestone_id": request.milestone_id,
                    "platform": request.platform,
                },
            )

            await log_user_activity(
                user_id=user_id,
                action="milestone_shared",
                endpoint=f"/api/v1/progress/milestones/{user_id}/share",
                message=f"Shared milestone on {request.platform}",
                metadata={
                    "milestone_id": request.milestone_id,
                    "platform": request.platform,
                },
                status_code=200,
            )

        return {"success": success}
    except Exception as e:
        logger.error(f"Error recording milestone share: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/milestones/{user_id}/check", response_model=MilestoneCheckResult)
async def check_milestones(user_id: str):
    """
    Manually trigger a milestone check.

    This is normally done automatically after workout completion,
    but can be called manually to ensure milestones are up to date.
    """
    logger.info(f"Checking milestones for user: {user_id}")

    try:
        result = await milestone_service.check_and_award_milestones(user_id)

        if result.new_milestones:
            # Log new milestone achievements
            for milestone in result.new_milestones:
                await log_user_activity(
                    user_id=user_id,
                    action="milestone_achieved",
                    endpoint=f"/api/v1/progress/milestones/{user_id}/check",
                    message=f"Achieved milestone: {milestone.milestone_name}",
                    metadata={
                        "milestone_id": milestone.milestone_id,
                        "milestone_name": milestone.milestone_name,
                        "tier": milestone.milestone_tier,
                        "points": milestone.points,
                    },
                    status_code=200,
                )

        return result
    except Exception as e:
        logger.error(f"Error checking milestones: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ROI Metrics
# ============================================

@router.get("/roi/{user_id}", response_model=ROIMetrics)
async def get_roi_metrics(
    user_id: str,
    recalculate: bool = Query(
        False, description="Force recalculation of metrics"
    ),
):
    """
    Get detailed ROI metrics for a user.

    Returns comprehensive metrics including:
    - Total workouts completed
    - Total time invested (hours)
    - Total weight lifted
    - Estimated calories burned
    - Strength increase percentage
    - PRs achieved
    - Streak information
    - Journey duration
    """
    logger.info(f"Getting ROI metrics for user: {user_id}, recalculate={recalculate}")

    try:
        metrics = await milestone_service.get_roi_metrics(
            user_id=user_id,
            recalculate=recalculate,
        )

        # Log ROI view
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.SCORE_VIEW,
            event_data={
                "screen": "roi_metrics",
                "total_workouts": metrics.total_workouts_completed,
                "total_hours": metrics.total_workout_time_hours,
            },
        )

        return metrics
    except Exception as e:
        logger.error(f"Error getting ROI metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/roi/{user_id}/summary", response_model=ROISummary)
async def get_roi_summary(user_id: str):
    """
    Get a compact ROI summary for the home screen.

    Returns key metrics formatted for display:
    - Total workouts
    - Hours invested
    - Estimated calories burned
    - Total weight lifted (formatted string)
    - Strength increase text
    - Current streak
    - Motivational message
    """
    logger.info(f"Getting ROI summary for user: {user_id}")

    try:
        summary = await milestone_service.get_roi_summary(user_id)
        return summary
    except Exception as e:
        logger.error(f"Error getting ROI summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Combined Progress Endpoint
# ============================================

@router.get("/{user_id}")
async def get_progress_overview(user_id: str):
    """
    Get complete progress overview including milestones and ROI.

    Combines milestone progress and ROI summary in one response
    for efficient home screen loading.
    """
    logger.info(f"Getting progress overview for user: {user_id}")

    try:
        # Fetch both in parallel
        milestones = await milestone_service.get_milestone_progress(user_id)
        roi_summary = await milestone_service.get_roi_summary(user_id)

        return {
            "milestones": milestones,
            "roi": roi_summary,
        }
    except Exception as e:
        logger.error(f"Error getting progress overview: {e}")
        raise HTTPException(status_code=500, detail=str(e))
