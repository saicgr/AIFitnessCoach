"""
Inflammation Analysis API Endpoints.

ENDPOINTS:
- POST /api/v1/inflammation/analyze - Analyze ingredients from barcode scan
- GET  /api/v1/inflammation/history/{user_id} - Get user's scan history
- GET  /api/v1/inflammation/stats/{user_id} - Get user's aggregated stats
- PUT  /api/v1/inflammation/scans/{scan_id}/notes - Update scan notes
- PUT  /api/v1/inflammation/scans/{scan_id}/favorite - Toggle favorite
"""

from fastapi import APIRouter, HTTPException, Query
import logging

from services.inflammation_service import get_inflammation_service
from models.inflammation import (
    AnalyzeInflammationRequest,
    InflammationAnalysisResponse,
    UserInflammationHistoryResponse,
    UserInflammationStatsResponse,
    UpdateScanNotesRequest,
    ToggleFavoriteRequest,
)

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/analyze", response_model=InflammationAnalysisResponse)
async def analyze_inflammation(request: AnalyzeInflammationRequest):
    """
    Analyze ingredients from a barcode scan for inflammatory properties.

    Returns cached result if available, otherwise runs Gemini analysis.
    Results are cached by barcode for 90 days.
    """
    logger.info(f"Inflammation analysis request for barcode {request.barcode} by user {request.user_id}")

    try:
        service = get_inflammation_service()

        result = await service.analyze_barcode(
            user_id=request.user_id,
            barcode=request.barcode,
            product_name=request.product_name,
            ingredients_text=request.ingredients_text,
        )

        # Log user activity
        try:
            from core.activity_logger import log_user_activity
            await log_user_activity(
                user_id=request.user_id,
                action="inflammation_analysis",
                endpoint="/api/v1/inflammation/analyze",
                message=f"Analyzed {request.barcode}: score {result.overall_score}",
                metadata={
                    "barcode": request.barcode,
                    "overall_score": result.overall_score,
                    "overall_category": result.overall_category.value,
                    "from_cache": result.from_cache,
                    "inflammatory_count": len(result.inflammatory_ingredients),
                },
            )
        except Exception as log_error:
            # Don't fail the request if logging fails
            logger.warning(f"Failed to log user activity: {log_error}")

        return result

    except ValueError as e:
        logger.error(f"Inflammation analysis failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Inflammation analysis error: {e}")
        raise HTTPException(status_code=500, detail="Failed to analyze ingredients")


@router.get("/history/{user_id}", response_model=UserInflammationHistoryResponse)
async def get_inflammation_history(
    user_id: str,
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0, ge=0),
    favorited_only: bool = Query(default=False),
):
    """
    Get user's inflammation scan history.

    Supports pagination and filtering by favorites.
    """
    logger.info(f"Getting inflammation history for user {user_id}")

    try:
        service = get_inflammation_service()

        scans = await service.get_user_history(
            user_id=user_id,
            limit=limit + 1,  # Fetch one extra to check has_more
            offset=offset,
            favorited_only=favorited_only,
        )

        has_more = len(scans) > limit
        if has_more:
            scans = scans[:limit]

        return UserInflammationHistoryResponse(
            items=scans,
            total_count=len(scans),
            has_more=has_more,
        )

    except Exception as e:
        logger.error(f"Failed to get inflammation history: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve history")


@router.get("/stats/{user_id}", response_model=UserInflammationStatsResponse)
async def get_inflammation_stats(user_id: str):
    """
    Get aggregated inflammation statistics for a user.

    Returns total scans, average score, and category breakdowns.
    """
    logger.info(f"Getting inflammation stats for user {user_id}")

    try:
        service = get_inflammation_service()
        return await service.get_user_stats(user_id)

    except Exception as e:
        logger.error(f"Failed to get inflammation stats: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve statistics")


@router.put("/scans/{scan_id}/notes")
async def update_scan_notes(
    scan_id: str,
    request: UpdateScanNotesRequest,
    user_id: str = Query(..., description="User ID for authorization"),
):
    """
    Update notes on a specific scan.
    """
    try:
        service = get_inflammation_service()
        success = await service.update_scan_notes(
            user_id=user_id,
            scan_id=scan_id,
            notes=request.notes,
        )

        if not success:
            raise HTTPException(status_code=404, detail="Scan not found")

        return {"success": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update scan notes: {e}")
        raise HTTPException(status_code=500, detail="Failed to update notes")


@router.put("/scans/{scan_id}/favorite")
async def toggle_scan_favorite(
    scan_id: str,
    request: ToggleFavoriteRequest,
    user_id: str = Query(..., description="User ID for authorization"),
):
    """
    Toggle favorite status on a scan.
    """
    try:
        service = get_inflammation_service()
        success = await service.toggle_favorite(
            user_id=user_id,
            scan_id=scan_id,
            is_favorited=request.is_favorited,
        )

        if not success:
            raise HTTPException(status_code=404, detail="Scan not found")

        return {"success": True, "is_favorited": request.is_favorited}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to toggle favorite: {e}")
        raise HTTPException(status_code=500, detail="Failed to update favorite status")
