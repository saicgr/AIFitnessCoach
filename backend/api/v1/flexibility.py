"""
Flexibility Assessment API endpoints.

Tracks flexibility test results and progress over time.
Provides personalized stretch recommendations based on assessment results.
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from typing import List, Optional
from datetime import datetime
import uuid

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from services.flexibility import (
    evaluate_flexibility,
    get_recommendations,
    get_flexibility_assessment_service,
    FLEXIBILITY_TESTS,
)
from models.flexibility import (
    FlexibilityTest,
    FlexibilityAssessment,
    FlexibilityAssessmentWithEvaluation,
    FlexibilityProgress,
    FlexibilityTrend,
    FlexibilityTestSummary,
    FlexibilitySummary,
    FlexibilityStretchPlan,
    RecordAssessmentRequest,
    RecordAssessmentResponse,
    FlexibilityScoreResponse,
)

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# Helper Functions
# ============================================

def _parse_assessment(data: dict) -> FlexibilityAssessment:
    """Parse a flexibility assessment from database row."""
    return FlexibilityAssessment(
        id=str(data["id"]),
        user_id=data["user_id"],
        test_type=data["test_type"],
        measurement=float(data["measurement"]),
        unit=data.get("unit", "inches"),
        rating=data.get("rating"),
        percentile=data.get("percentile"),
        notes=data.get("notes"),
        assessed_at=data.get("assessed_at") or datetime.utcnow(),
        created_at=data.get("created_at"),
        updated_at=data.get("updated_at"),
    )


def _parse_test(data: dict) -> FlexibilityTest:
    """Parse a flexibility test from database row."""
    return FlexibilityTest(
        id=data["id"],
        name=data["name"],
        description=data.get("description", ""),
        instructions=data.get("instructions") or [],
        unit=data.get("unit", "inches"),
        target_muscles=data.get("target_muscles") or [],
        equipment_needed=data.get("equipment_needed") or [],
        higher_is_better=data.get("higher_is_better", True),
        tips=data.get("tips") or [],
        common_mistakes=data.get("common_mistakes") or [],
        video_url=data.get("video_url"),
        image_url=data.get("image_url"),
        is_active=data.get("is_active", True),
        created_at=data.get("created_at"),
    )


async def _get_user_profile(user_id: str) -> dict:
    """Get user profile for age and gender."""
    db = get_supabase_db()
    result = db.client.table("users").select(
        "gender, date_of_birth"
    ).eq("id", user_id).execute()

    if not result.data:
        # Default values if user not found
        return {"gender": "male", "age": 30}

    user = result.data[0]
    gender = user.get("gender", "male") or "male"

    # Calculate age from date of birth
    dob = user.get("date_of_birth")
    if dob:
        try:
            birth_date = datetime.fromisoformat(dob.replace("Z", "+00:00"))
            age = (datetime.now() - birth_date).days // 365
        except Exception:
            age = 30
    else:
        age = 30

    return {"gender": gender, "age": age}


# ============================================
# Flexibility Tests Endpoints
# ============================================

@router.get("/tests", response_model=List[FlexibilityTest])
async def get_all_flexibility_tests(current_user: dict = Depends(get_current_user)):
    """
    Get all available flexibility tests with their instructions.

    Returns a list of all flexibility tests that users can perform,
    including instructions, target muscles, and tips.
    """
    logger.info("Getting all flexibility tests")

    try:
        db = get_supabase_db()
        result = db.client.table("flexibility_tests").select("*").eq(
            "is_active", True
        ).order("name").execute()

        if result.data:
            return [_parse_test(t) for t in result.data]

        # Fallback to in-memory tests if database is empty
        service = get_flexibility_assessment_service()
        return [FlexibilityTest(**t) for t in service.get_all_tests()]

    except Exception as e:
        logger.error(f"Failed to get flexibility tests: {e}")
        # Return from service as fallback
        service = get_flexibility_assessment_service()
        return [FlexibilityTest(**t) for t in service.get_all_tests()]


@router.get("/tests/{test_id}", response_model=FlexibilityTest)
async def get_flexibility_test(test_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get a specific flexibility test by ID.

    Returns detailed information about a single flexibility test,
    including full instructions and tips.
    """
    logger.info(f"Getting flexibility test: {test_id}")

    try:
        db = get_supabase_db()
        result = db.client.table("flexibility_tests").select("*").eq(
            "id", test_id
        ).execute()

        if result.data:
            return _parse_test(result.data[0])

        # Fallback to service
        service = get_flexibility_assessment_service()
        test_data = service.get_test_by_id(test_id)
        if test_data:
            return FlexibilityTest(**test_data)

        raise HTTPException(status_code=404, detail="Flexibility test not found")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get flexibility test: {e}")
        raise safe_internal_error(e, "flexibility")


@router.get("/tests/by-muscle/{muscle}")
async def get_tests_by_muscle(muscle: str, current_user: dict = Depends(get_current_user)):
    """
    Get flexibility tests that target a specific muscle group.

    Useful for finding tests related to a particular area of concern.
    """
    logger.info(f"Getting flexibility tests for muscle: {muscle}")

    try:
        service = get_flexibility_assessment_service()
        tests = service.get_tests_by_muscle(muscle)

        if not tests:
            return {"tests": [], "message": f"No tests found for muscle: {muscle}"}

        return {"tests": tests, "count": len(tests)}

    except Exception as e:
        logger.error(f"Failed to get tests by muscle: {e}")
        raise safe_internal_error(e, "flexibility")


# ============================================
# Assessment Recording Endpoints
# ============================================

@router.post("/user/{user_id}/assessment", response_model=RecordAssessmentResponse)
async def record_flexibility_assessment(
    user_id: str,
    request: RecordAssessmentRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Record a new flexibility assessment for a user.

    Evaluates the measurement against age and gender norms,
    calculates percentile, and provides personalized recommendations.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Recording flexibility assessment for user {user_id}: {request.test_type}")

    try:
        db = get_supabase_db()

        # Get user profile for evaluation
        user_profile = await _get_user_profile(user_id)

        # Evaluate the measurement
        evaluation = evaluate_flexibility(
            test_type=request.test_type,
            measurement=request.measurement,
            gender=user_profile["gender"],
            age=user_profile["age"],
            notes=request.notes,
        )

        if "error" in evaluation:
            raise HTTPException(status_code=400, detail=evaluation["error"])

        # Check for improvement from previous assessment
        previous = db.client.table("flexibility_assessments").select(
            "measurement, rating"
        ).eq("user_id", user_id).eq(
            "test_type", request.test_type
        ).order("assessed_at", desc=True).limit(1).execute()

        is_improvement = False
        rating_improved = False
        if previous.data:
            prev = previous.data[0]
            test_info = FLEXIBILITY_TESTS.get(request.test_type)
            if test_info:
                if test_info.higher_is_better:
                    is_improvement = request.measurement > prev["measurement"]
                else:
                    is_improvement = request.measurement < prev["measurement"]

            rating_order = ["poor", "fair", "good", "excellent"]
            if prev.get("rating") and evaluation.get("rating"):
                old_idx = rating_order.index(prev["rating"]) if prev["rating"] in rating_order else 0
                new_idx = rating_order.index(evaluation["rating"]) if evaluation["rating"] in rating_order else 0
                rating_improved = new_idx > old_idx

        # Get unit from test definition
        test_info = FLEXIBILITY_TESTS.get(request.test_type)
        unit = test_info.unit if test_info else "inches"

        # Create assessment record
        now = datetime.utcnow().isoformat()
        assessment_data = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "test_type": request.test_type,
            "measurement": request.measurement,
            "unit": unit,
            "rating": evaluation.get("rating"),
            "percentile": evaluation.get("percentile"),
            "notes": request.notes,
            "assessed_at": now,
            "created_at": now,
            "updated_at": now,
        }

        result = db.client.table("flexibility_assessments").insert(assessment_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save assessment")

        assessment = _parse_assessment(result.data[0])

        # Create enriched assessment with evaluation details
        assessment_with_eval = FlexibilityAssessmentWithEvaluation(
            **assessment.model_dump(),
            test_name=evaluation.get("test_name"),
            target_muscles=evaluation.get("target_muscles", []),
            recommendations=evaluation.get("recommendations", []),
            improvement_message=evaluation.get("improvement_message"),
            tips=evaluation.get("tips", []),
            common_mistakes=evaluation.get("common_mistakes", []),
        )

        # Update stretch plan based on new rating
        recommendations = evaluation.get("recommendations", [])
        if recommendations:
            await _update_stretch_plan(
                db, user_id, request.test_type,
                evaluation.get("rating", "fair"), recommendations
            )

        # Build response message
        if is_improvement and rating_improved:
            message = f"Great improvement! Your {evaluation.get('test_name', 'flexibility')} rating improved to {evaluation.get('rating', 'fair')}!"
        elif is_improvement:
            message = f"Good progress! Your measurement improved from the last assessment."
        elif rating_improved:
            message = f"Congratulations! You've moved up to the '{evaluation.get('rating')}' rating level!"
        else:
            message = f"Assessment recorded. Your rating is '{evaluation.get('rating')}' (top {100 - evaluation.get('percentile', 50)}% of your demographic)."

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="flexibility_assessment_recorded",
            endpoint=f"/api/v1/flexibility/user/{user_id}/assessment",
            message=f"Recorded {request.test_type} assessment: {request.measurement} {unit}",
            metadata={
                "test_type": request.test_type,
                "measurement": request.measurement,
                "rating": evaluation.get("rating"),
                "percentile": evaluation.get("percentile"),
            },
            status_code=200
        )

        return RecordAssessmentResponse(
            success=True,
            message=message,
            assessment=assessment_with_eval,
            is_improvement=is_improvement,
            rating_improved=rating_improved,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to record flexibility assessment: {e}")
        await log_user_error(
            user_id=user_id,
            action="flexibility_assessment_recorded",
            error=e,
            endpoint=f"/api/v1/flexibility/user/{user_id}/assessment",
            status_code=500
        )
        raise safe_internal_error(e, "flexibility")


async def _update_stretch_plan(db, user_id: str, test_type: str, rating: str, stretches: list):
    """Update the user's stretch plan for a specific test type."""
    try:
        now = datetime.utcnow().isoformat()
        plan_data = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "test_type": test_type,
            "rating": rating,
            "stretches": stretches,
            "is_active": True,
            "created_at": now,
            "updated_at": now,
        }

        # Upsert the stretch plan
        db.client.table("flexibility_stretch_plans").upsert(
            plan_data,
            on_conflict="user_id,test_type"
        ).execute()
    except Exception as e:
        logger.warning(f"Failed to update stretch plan: {e}")


# ============================================
# Assessment History Endpoints
# ============================================

@router.get("/user/{user_id}/assessments", response_model=List[FlexibilityAssessment])
async def get_user_assessments(
    user_id: str,
    test_type: Optional[str] = Query(default=None, description="Filter by test type"),
    limit: int = Query(default=50, ge=1, le=200, description="Maximum records to return"),
    days: Optional[int] = Query(default=None, ge=1, le=365, description="Filter by days ago"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get a user's flexibility assessment history.

    Optionally filter by test type and date range.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting flexibility assessments for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("flexibility_assessments").select("*").eq("user_id", user_id)

        if test_type:
            query = query.eq("test_type", test_type)

        if days:
            from datetime import timedelta
            cutoff = (datetime.utcnow() - timedelta(days=days)).isoformat()
            query = query.gte("assessed_at", cutoff)

        result = query.order("assessed_at", desc=True).limit(limit).execute()

        return [_parse_assessment(a) for a in result.data]

    except Exception as e:
        logger.error(f"Failed to get user assessments: {e}")
        raise safe_internal_error(e, "flexibility")


@router.get("/user/{user_id}/assessments/latest")
async def get_latest_assessments(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get the latest assessment for each test type.

    Useful for showing current flexibility status across all tests.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting latest assessments for user {user_id}")

    try:
        db = get_supabase_db()

        # Use the view for latest assessments
        result = db.client.table("latest_flexibility_assessments").select(
            "*"
        ).eq("user_id", user_id).execute()

        if not result.data:
            return {"assessments": [], "message": "No assessments found"}

        assessments = [_parse_assessment(a) for a in result.data]

        # Get test names for each
        test_names = {}
        for test_id, test_info in FLEXIBILITY_TESTS.items():
            test_names[test_id] = test_info.name

        enriched = []
        for a in assessments:
            data = a.model_dump()
            data["test_name"] = test_names.get(a.test_type, a.test_type)
            enriched.append(data)

        return {"assessments": enriched, "count": len(enriched)}

    except Exception as e:
        logger.error(f"Failed to get latest assessments: {e}")
        raise safe_internal_error(e, "flexibility")


@router.delete("/user/{user_id}/assessment/{assessment_id}")
async def delete_assessment(user_id: str, assessment_id: str, current_user: dict = Depends(get_current_user)):
    """
    Delete a flexibility assessment.

    Users can only delete their own assessments.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Deleting assessment {assessment_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        check = db.client.table("flexibility_assessments").select("id").eq(
            "id", assessment_id
        ).eq("user_id", user_id).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Assessment not found")

        db.client.table("flexibility_assessments").delete().eq(
            "id", assessment_id
        ).execute()

        return {"success": True, "message": "Assessment deleted"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete assessment: {e}")
        raise safe_internal_error(e, "flexibility")


# ============================================
# Progress Tracking Endpoints
# ============================================

@router.get("/user/{user_id}/progress/{test_type}", response_model=FlexibilityTrend)
async def get_flexibility_progress(
    user_id: str,
    test_type: str,
    days: int = Query(default=90, ge=7, le=365, description="Number of days to include"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get flexibility progress for a specific test type.

    Shows trend data with improvement calculations.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting flexibility progress for user {user_id}, test: {test_type}")

    try:
        db = get_supabase_db()

        # Get assessments for the period
        from datetime import timedelta
        cutoff = (datetime.utcnow() - timedelta(days=days)).isoformat()

        result = db.client.table("flexibility_assessments").select("*").eq(
            "user_id", user_id
        ).eq("test_type", test_type).gte(
            "assessed_at", cutoff
        ).order("assessed_at").execute()

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail=f"No assessments found for test type: {test_type}"
            )

        assessments = [_parse_assessment(a) for a in result.data]

        # Get test info
        test_info = FLEXIBILITY_TESTS.get(test_type)
        test_name = test_info.name if test_info else test_type
        unit = test_info.unit if test_info else "inches"
        higher_is_better = test_info.higher_is_better if test_info else True

        first = assessments[0]
        last = assessments[-1]

        # Calculate improvement
        improvement_abs = last.measurement - first.measurement
        if not higher_is_better:
            improvement_abs = -improvement_abs  # Invert for lower-is-better tests

        improvement_pct = 0
        if first.measurement != 0:
            improvement_pct = (improvement_abs / abs(first.measurement)) * 100

        rating_order = ["poor", "fair", "good", "excellent"]
        first_rating_idx = rating_order.index(first.rating) if first.rating in rating_order else 0
        last_rating_idx = rating_order.index(last.rating) if last.rating in rating_order else 0
        rating_change = last_rating_idx - first_rating_idx

        return FlexibilityTrend(
            test_type=test_type,
            test_name=test_name,
            unit=unit,
            first_assessment={
                "measurement": first.measurement,
                "rating": first.rating,
                "percentile": first.percentile,
                "date": first.assessed_at.isoformat(),
            },
            latest_assessment={
                "measurement": last.measurement,
                "rating": last.rating,
                "percentile": last.percentile,
                "date": last.assessed_at.isoformat(),
            },
            total_assessments=len(assessments),
            improvement={
                "absolute": round(improvement_abs, 2),
                "percentage": round(improvement_pct, 1),
                "is_positive": improvement_abs > 0,
                "rating_levels_gained": rating_change,
            },
            trend_data=[
                {
                    "measurement": a.measurement,
                    "rating": a.rating,
                    "date": a.assessed_at.isoformat(),
                }
                for a in assessments
            ]
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get flexibility progress: {e}")
        raise safe_internal_error(e, "flexibility")


@router.get("/user/{user_id}/summary", response_model=FlexibilitySummary)
async def get_flexibility_summary(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get overall flexibility summary for a user.

    Includes overall score, ratings by category, and improvement priorities.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting flexibility summary for user {user_id}")

    try:
        db = get_supabase_db()

        # Get latest assessments
        latest = db.client.table("latest_flexibility_assessments").select(
            "*"
        ).eq("user_id", user_id).execute()

        if not latest.data:
            return FlexibilitySummary(
                overall_score=0,
                overall_rating="not_assessed",
                tests_completed=0,
                total_assessments=0,
            )

        assessments = {a["test_type"]: _parse_assessment(a) for a in latest.data}

        # Get summary stats
        summary = db.client.table("flexibility_summary").select(
            "*"
        ).eq("user_id", user_id).execute()

        summary_data = summary.data[0] if summary.data else {}

        # Use service to calculate overall score
        service = get_flexibility_assessment_service()
        assessment_results = {}
        for test_type, assessment in assessments.items():
            assessment_results[test_type] = {
                "rating": assessment.rating,
                "percentile": assessment.percentile,
                "measurement": assessment.measurement,
                "assessed_at": assessment.assessed_at.isoformat(),
            }

        score_data = service.get_overall_flexibility_score(assessment_results)

        return FlexibilitySummary(
            overall_score=score_data.get("overall_score", 0),
            overall_rating=score_data.get("overall_rating", "fair"),
            tests_completed=len(assessments),
            total_assessments=summary_data.get("total_assessments", len(assessments)),
            first_assessment=summary_data.get("first_assessment"),
            latest_assessment=summary_data.get("latest_assessment"),
            category_ratings=score_data.get("category_ratings", {}),
            areas_needing_improvement=[
                p["test_type"] for p in score_data.get("improvement_priority", [])
            ],
            improvement_priority=score_data.get("improvement_priority", []),
        )

    except Exception as e:
        logger.error(f"Failed to get flexibility summary: {e}")
        raise safe_internal_error(e, "flexibility")


@router.get("/user/{user_id}/score", response_model=FlexibilityScoreResponse)
async def get_flexibility_score(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get the overall flexibility score for a user.

    Uses the database function for efficient calculation.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting flexibility score for user {user_id}")

    try:
        db = get_supabase_db()

        # Call the database function
        result = db.client.rpc("get_flexibility_score", {"p_user_id": user_id}).execute()

        if not result.data:
            return FlexibilityScoreResponse(
                overall_score=0,
                overall_rating="not_assessed",
                tests_completed=0,
                areas_needing_improvement=[],
            )

        data = result.data[0] if isinstance(result.data, list) else result.data

        return FlexibilityScoreResponse(
            overall_score=float(data.get("overall_score", 0)),
            overall_rating=data.get("overall_rating", "fair"),
            tests_completed=data.get("tests_completed", 0),
            areas_needing_improvement=data.get("areas_needing_improvement") or [],
        )

    except Exception as e:
        logger.error(f"Failed to get flexibility score: {e}")
        raise safe_internal_error(e, "flexibility")


# ============================================
# Stretch Plan Endpoints
# ============================================

@router.get("/user/{user_id}/stretch-plans")
async def get_user_stretch_plans(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get all active stretch plans for a user.

    Returns personalized stretch recommendations based on flexibility assessments.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting stretch plans for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("flexibility_stretch_plans").select("*").eq(
            "user_id", user_id
        ).eq("is_active", True).execute()

        if not result.data:
            return {"plans": [], "message": "No stretch plans yet. Complete some flexibility assessments to get personalized recommendations."}

        # Enrich with test names
        plans = []
        for plan in result.data:
            test_info = FLEXIBILITY_TESTS.get(plan["test_type"])
            plans.append({
                "test_type": plan["test_type"],
                "test_name": test_info.name if test_info else plan["test_type"],
                "rating": plan["rating"],
                "stretches": plan["stretches"],
                "created_at": plan["created_at"],
            })

        return {"plans": plans, "count": len(plans)}

    except Exception as e:
        logger.error(f"Failed to get stretch plans: {e}")
        raise safe_internal_error(e, "flexibility")


@router.get("/user/{user_id}/stretch-plan/{test_type}")
async def get_stretch_plan_for_test(user_id: str, test_type: str, current_user: dict = Depends(get_current_user)):
    """
    Get the stretch plan for a specific test type.

    If no plan exists, generates one based on a default fair rating.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting stretch plan for user {user_id}, test: {test_type}")

    try:
        db = get_supabase_db()

        result = db.client.table("flexibility_stretch_plans").select("*").eq(
            "user_id", user_id
        ).eq("test_type", test_type).eq("is_active", True).execute()

        if result.data:
            plan = result.data[0]
            test_info = FLEXIBILITY_TESTS.get(test_type)
            return {
                "test_type": test_type,
                "test_name": test_info.name if test_info else test_type,
                "rating": plan["rating"],
                "stretches": plan["stretches"],
                "created_at": plan["created_at"],
            }

        # No plan exists - generate default recommendations
        recommendations = get_recommendations(test_type, "fair")
        test_info = FLEXIBILITY_TESTS.get(test_type)

        return {
            "test_type": test_type,
            "test_name": test_info.name if test_info else test_type,
            "rating": "not_assessed",
            "stretches": recommendations,
            "message": "Complete a flexibility assessment to get personalized recommendations",
        }

    except Exception as e:
        logger.error(f"Failed to get stretch plan: {e}")
        raise safe_internal_error(e, "flexibility")


# ============================================
# Evaluation Endpoints (Without Saving)
# ============================================

@router.post("/evaluate")
async def evaluate_measurement(
    test_type: str,
    measurement: float,
    gender: str,
    age: int,
    current_user: dict = Depends(get_current_user),
):
    """
    Evaluate a flexibility measurement without saving.

    Useful for quick evaluations or previewing results before recording.
    """
    logger.info(f"Evaluating {test_type}: {measurement} for {gender}, age {age}")

    try:
        result = evaluate_flexibility(
            test_type=test_type,
            measurement=measurement,
            gender=gender,
            age=age,
        )

        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to evaluate measurement: {e}")
        raise safe_internal_error(e, "flexibility")


@router.get("/recommendations/{test_type}/{rating}")
async def get_stretch_recommendations(test_type: str, rating: str, current_user: dict = Depends(get_current_user)):
    """
    Get stretch recommendations for a specific test type and rating.

    Useful for showing recommendations without saving an assessment.
    """
    logger.info(f"Getting recommendations for {test_type}, rating: {rating}")

    try:
        recommendations = get_recommendations(test_type, rating)

        if not recommendations:
            return {
                "test_type": test_type,
                "rating": rating,
                "recommendations": [],
                "message": f"No specific recommendations for {test_type} at {rating} level",
            }

        test_info = FLEXIBILITY_TESTS.get(test_type)

        return {
            "test_type": test_type,
            "test_name": test_info.name if test_info else test_type,
            "rating": rating,
            "recommendations": recommendations,
        }

    except Exception as e:
        logger.error(f"Failed to get recommendations: {e}")
        raise safe_internal_error(e, "flexibility")
