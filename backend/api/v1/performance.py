"""
Performance Analytics API endpoints.

ENDPOINTS:
- GET  /api/v1/performance/analytics - Get performance analytics and trends
- GET  /api/v1/performance/prs - Get personal records
- GET  /api/v1/performance/volume - Get weekly volume by muscle group
- GET  /api/v1/performance/strength-curve/{exercise_id} - Get strength progression
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime, timedelta

from models.performance import (
    AnalyticsRequest, AnalyticsResponse,
    StrengthRecord, WeeklyPerformanceSummary,
    MuscleGroupVolume,
)
from services.progressive_overload_service import ProgressiveOverloadService

router = APIRouter()

# Service instance
progressive_overload_service: Optional[ProgressiveOverloadService] = None


def get_progressive_overload() -> ProgressiveOverloadService:
    """Get progressive overload service instance."""
    global progressive_overload_service
    if progressive_overload_service is None:
        progressive_overload_service = ProgressiveOverloadService()
    return progressive_overload_service


# ============ Analytics ============

class AnalyticsQueryParams(BaseModel):
    """Query parameters for analytics."""
    user_id: str
    days: int = 30
    exercise_ids: Optional[List[str]] = None


@router.get("/analytics")
async def get_analytics(
    user_id: str,
    days: int = Query(default=30, ge=7, le=365),
):
    """
    Get comprehensive performance analytics.

    Returns:
    - Weekly performance summaries
    - Volume trends
    - Strength progression
    - Top PRs

    Example response:
    ```json
    {
        "user_id": 1,
        "period_start": "2024-01-01",
        "period_end": "2024-01-31",
        "summary": {
            "workouts_completed": 12,
            "total_volume_kg": 45000,
            "total_sets": 180,
            "average_session_rpe": 7.2,
            "new_prs": 5
        },
        "trends": {
            "volume_change": 15.5,
            "strength_change": 8.2,
            "consistency": 85
        }
    }
    ```
    """
    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)

        # In production, fetch real data from database
        # For now, return mock analytics
        return {
            "user_id": user_id,
            "period_start": start_date.isoformat(),
            "period_end": end_date.isoformat(),
            "summary": {
                "workouts_completed": 12,
                "workouts_planned": 14,
                "total_volume_kg": 45000,
                "total_sets": 180,
                "total_reps": 1800,
                "average_session_rpe": 7.2,
                "new_prs": 5,
                "adherence_rate": 85.7,
            },
            "trends": {
                "volume_change_percent": 15.5,
                "strength_change_percent": 8.2,
                "consistency_percent": 85.7,
                "trend_direction": "improving",
            },
            "recommendations": [
                "Volume is trending up - consider a deload in 2 weeks",
                "Chest is lagging - add 2-3 sets per week",
                "Great progress on squat - keep current progression",
            ],
        }

    except Exception as e:
        print(f"❌ Error getting analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Personal Records ============

class PRResponse(BaseModel):
    """Personal record response."""
    exercise_name: str
    weight_kg: float
    reps: int
    estimated_1rm: float
    date: datetime
    improvement_percent: Optional[float] = None


@router.get("/prs")
async def get_personal_records(
    user_id: str,
    limit: int = Query(default=10, ge=1, le=50),
):
    """
    Get personal records for the user.

    Returns top PRs across all exercises with estimated 1RM.

    Example response:
    ```json
    {
        "user_id": 1,
        "prs": [
            {
                "exercise_name": "Bench Press",
                "weight_kg": 100,
                "reps": 5,
                "estimated_1rm": 112.5,
                "date": "2024-01-15",
                "improvement_percent": 5.2
            },
            ...
        ]
    }
    ```
    """
    try:
        prog_service = get_progressive_overload()

        # In production, fetch from database
        # For now, return mock data
        mock_prs = [
            PRResponse(
                exercise_name="Bench Press",
                weight_kg=100,
                reps=5,
                estimated_1rm=StrengthRecord.calculate_1rm(100, 5),
                date=datetime.now() - timedelta(days=3),
                improvement_percent=5.2,
            ),
            PRResponse(
                exercise_name="Squat",
                weight_kg=140,
                reps=5,
                estimated_1rm=StrengthRecord.calculate_1rm(140, 5),
                date=datetime.now() - timedelta(days=7),
                improvement_percent=3.8,
            ),
            PRResponse(
                exercise_name="Deadlift",
                weight_kg=180,
                reps=3,
                estimated_1rm=StrengthRecord.calculate_1rm(180, 3),
                date=datetime.now() - timedelta(days=10),
                improvement_percent=4.5,
            ),
        ]

        return {
            "user_id": user_id,
            "prs": mock_prs[:limit],
            "total_prs": len(mock_prs),
        }

    except Exception as e:
        print(f"❌ Error getting PRs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Volume Tracking ============

@router.get("/volume")
async def get_weekly_volume(
    user_id: str,
    weeks: int = Query(default=4, ge=1, le=12),
):
    """
    Get weekly volume breakdown by muscle group.

    Helps identify:
    - Undertrained muscle groups
    - Overtrained muscle groups
    - Volume progression over time

    Example response:
    ```json
    {
        "user_id": 1,
        "current_week": {
            "chest": {"sets": 12, "volume_kg": 4800, "status": "optimal"},
            "back": {"sets": 15, "volume_kg": 6000, "status": "optimal"},
            "legs": {"sets": 8, "volume_kg": 8000, "status": "undertrained"}
        },
        "trends": [...]
    }
    ```
    """
    try:
        # Mock weekly volume data
        current_week = {
            "chest": {
                "sets": 12,
                "reps": 96,
                "volume_kg": 4800,
                "frequency": 2,
                "target_sets": 14,
                "status": "optimal",
            },
            "back": {
                "sets": 15,
                "reps": 120,
                "volume_kg": 6000,
                "frequency": 2,
                "target_sets": 14,
                "status": "optimal",
            },
            "shoulders": {
                "sets": 8,
                "reps": 80,
                "volume_kg": 2400,
                "frequency": 2,
                "target_sets": 12,
                "status": "undertrained",
            },
            "biceps": {
                "sets": 10,
                "reps": 100,
                "volume_kg": 1500,
                "frequency": 2,
                "target_sets": 10,
                "status": "optimal",
            },
            "triceps": {
                "sets": 6,
                "reps": 60,
                "volume_kg": 900,
                "frequency": 1,
                "target_sets": 10,
                "status": "undertrained",
            },
            "quadriceps": {
                "sets": 12,
                "reps": 96,
                "volume_kg": 9600,
                "frequency": 2,
                "target_sets": 14,
                "status": "optimal",
            },
            "hamstrings": {
                "sets": 8,
                "reps": 64,
                "volume_kg": 4800,
                "frequency": 2,
                "target_sets": 12,
                "status": "undertrained",
            },
        }

        # Weekly trend (mock)
        weekly_trends = []
        for i in range(weeks):
            weekly_trends.append({
                "week": i + 1,
                "total_volume_kg": 35000 + (i * 2000),
                "total_sets": 120 + (i * 5),
            })

        return {
            "user_id": user_id,
            "current_week": current_week,
            "weekly_trends": weekly_trends,
            "recommendations": [
                "Consider adding 2-3 more sets for shoulders",
                "Triceps frequency could be increased to 2x/week",
                "Hamstring volume is below target - add leg curls",
            ],
        }

    except Exception as e:
        print(f"❌ Error getting volume: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Strength Curve ============

@router.get("/strength-curve/{exercise_id}")
async def get_strength_curve(
    exercise_id: str,
    user_id: str,
    days: int = Query(default=90, ge=30, le=365),
):
    """
    Get strength progression curve for an exercise.

    Shows estimated 1RM over time to visualize progress.

    Example response:
    ```json
    {
        "exercise_id": "bench_press",
        "exercise_name": "Bench Press",
        "data_points": [
            {"date": "2024-01-01", "estimated_1rm": 100, "actual_weight": 85, "reps": 8},
            {"date": "2024-01-08", "estimated_1rm": 102.5, "actual_weight": 87.5, "reps": 8},
            ...
        ],
        "trend": {
            "direction": "improving",
            "weekly_rate": 1.5,
            "projected_1rm_30d": 110
        }
    }
    ```
    """
    try:
        # Map exercise_id to name (in production, from database)
        exercise_names = {
            "bench_press": "Bench Press",
            "squat": "Squat",
            "deadlift": "Deadlift",
            "overhead_press": "Overhead Press",
        }

        exercise_name = exercise_names.get(exercise_id, exercise_id.replace("_", " ").title())

        # Generate mock strength curve data
        data_points = []
        base_1rm = 100
        for i in range(days // 7):
            date = datetime.now() - timedelta(days=days - (i * 7))
            progress = i * 1.5  # 1.5kg improvement per week
            data_points.append({
                "date": date.isoformat(),
                "estimated_1rm": round(base_1rm + progress, 1),
                "actual_weight": round((base_1rm + progress) * 0.85, 1),  # ~85% of 1RM
                "reps": 8,
            })

        current_1rm = data_points[-1]["estimated_1rm"] if data_points else base_1rm
        weekly_rate = 1.5  # kg per week

        return {
            "exercise_id": exercise_id,
            "exercise_name": exercise_name,
            "user_id": user_id,
            "data_points": data_points,
            "current_1rm": current_1rm,
            "trend": {
                "direction": "improving",
                "weekly_rate_kg": weekly_rate,
                "monthly_rate_kg": weekly_rate * 4,
                "projected_1rm_30d": round(current_1rm + (weekly_rate * 4), 1),
                "projected_1rm_90d": round(current_1rm + (weekly_rate * 12), 1),
            },
            "milestones": {
                "first_plate": {"target": 60, "achieved": True, "date": "2023-06-15"},
                "bodyweight": {"target": 80, "achieved": True, "date": "2023-10-01"},
                "two_plates": {"target": 100, "achieved": True, "date": "2024-01-10"},
                "next_milestone": {"target": 120, "achieved": False, "projected_date": "2024-04-15"},
            },
        }

    except Exception as e:
        print(f"❌ Error getting strength curve: {e}")
        raise HTTPException(status_code=500, detail=str(e))
