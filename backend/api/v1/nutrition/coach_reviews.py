"""AI nutrition-pro review endpoints for recipes and meal plans."""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from models.coach_review import (
    CoachReview,
    CoachReviewKind,
    CoachReviewRequest,
    CoachReviewSubject,
    HumanProRequestResponse,
)
from services.coach_review_service import get_coach_review_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/recipes/{recipe_id}/coach-review", response_model=CoachReview)
async def review_recipe(
    recipe_id: str,
    request: CoachReviewRequest = CoachReviewRequest(),
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    try:
        return await get_coach_review_service().review_recipe(
            user_id=user_id, recipe_id=recipe_id, kind=request.review_kind
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.post("/meal-plans/{plan_id}/coach-review", response_model=CoachReview)
async def review_meal_plan(
    plan_id: str,
    request: CoachReviewRequest = CoachReviewRequest(),
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    try:
        return await get_coach_review_service().review_meal_plan(
            user_id=user_id, plan_id=plan_id, kind=request.review_kind
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.get("/coach-reviews/latest", response_model=Optional[CoachReview])
async def latest_review(
    subject_type: CoachReviewSubject = Query(...),
    subject_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    return await get_coach_review_service().latest(subject_type, subject_id)


@router.post("/coach-reviews/{review_id}/request-human-pro", response_model=HumanProRequestResponse)
async def request_human_pro_review(review_id: str, current_user: dict = Depends(get_current_user)):
    """Stub — queues for the future human-coach feature.

    No human reviewer infra exists yet; we just acknowledge the request so the UI
    can show a friendly message and track interest for launch.
    """
    return HumanProRequestResponse(queued=True)
