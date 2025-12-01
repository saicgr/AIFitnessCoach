"""
Email Reminder API endpoints.

ENDPOINTS:
- POST /api/v1/reminders/send-daily - Send workout reminders for today's scheduled workouts
- POST /api/v1/reminders/send-user/{user_id} - Send reminder to a specific user
- GET  /api/v1/reminders/status - Check email service status
"""

import json
from datetime import date, datetime
from typing import List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.email_service import get_email_service

router = APIRouter()
logger = get_logger(__name__)


class ReminderResponse(BaseModel):
    """Response for reminder operations."""
    success: bool
    sent_count: int
    failed_count: int
    details: List[dict]


class SingleReminderResponse(BaseModel):
    """Response for single user reminder."""
    success: bool
    message: str
    email_id: Optional[str] = None


@router.get("/status")
async def get_email_status():
    """
    Check if the email service is properly configured.

    Returns:
        Status of the email service configuration.
    """
    email_service = get_email_service()
    return {
        "configured": email_service.is_configured(),
        "from_email": email_service.from_email,
    }


@router.post("/send-daily", response_model=ReminderResponse)
async def send_daily_reminders(target_date: Optional[str] = None):
    """
    Send workout reminder emails to all users who have workouts scheduled for today.

    This endpoint is designed to be called by a scheduled task (cron job).

    Args:
        target_date: Optional ISO date string (YYYY-MM-DD). Defaults to today.

    Returns:
        Summary of sent reminders.
    """
    logger.info("Starting daily workout reminder job")

    email_service = get_email_service()

    if not email_service.is_configured():
        logger.error("Email service not configured - cannot send reminders")
        raise HTTPException(
            status_code=503,
            detail="Email service not configured. Please set RESEND_API_KEY."
        )

    db = get_supabase_db()

    # Determine target date
    if target_date:
        try:
            reminder_date = datetime.strptime(target_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")
    else:
        reminder_date = date.today()

    date_str = reminder_date.isoformat()
    logger.info(f"Sending reminders for date: {date_str}")

    # Get all users with workouts scheduled for this date
    all_users = db.get_all_users()

    sent_count = 0
    failed_count = 0
    details = []

    for user in all_users:
        user_id = user["id"]

        # Get user's scheduled workouts for today (only current, not completed)
        workouts = db.list_current_workouts(
            user_id=user_id,
            is_completed=False,
            from_date=date_str,
            to_date=date_str,
        )

        if not workouts:
            continue

        # Get user's email from preferences
        preferences = user.get("preferences", {})
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        email = preferences.get("email") or user.get("email")
        user_name = preferences.get("name") or user.get("name") or "Fitness Enthusiast"

        if not email:
            logger.warning(f"No email found for user {user_id}, skipping reminder")
            failed_count += 1
            details.append({
                "user_id": user_id,
                "success": False,
                "error": "No email address found"
            })
            continue

        # For each workout scheduled today, send a reminder
        for workout in workouts:
            workout_name = workout.get("name", "Your Workout")
            workout_type = workout.get("type", "workout")

            # Parse exercises from JSON
            exercises_json = workout.get("exercises_json", "[]")
            if isinstance(exercises_json, str):
                try:
                    exercises = json.loads(exercises_json)
                except json.JSONDecodeError:
                    exercises = []
            else:
                exercises = exercises_json or []

            # Send the reminder email
            result = await email_service.send_workout_reminder(
                to_email=email,
                user_name=user_name,
                workout_name=workout_name,
                workout_type=workout_type,
                scheduled_date=reminder_date,
                exercises=exercises,
            )

            if result.get("success"):
                sent_count += 1
                details.append({
                    "user_id": user_id,
                    "workout_id": workout.get("id"),
                    "success": True,
                    "email_id": result.get("id")
                })
                logger.info(f"✅ Sent reminder to {email} for workout {workout_name}")
            else:
                failed_count += 1
                details.append({
                    "user_id": user_id,
                    "workout_id": workout.get("id"),
                    "success": False,
                    "error": result.get("error")
                })
                logger.error(f"❌ Failed to send reminder to {email}: {result.get('error')}")

    logger.info(f"Daily reminders complete: {sent_count} sent, {failed_count} failed")

    return ReminderResponse(
        success=failed_count == 0,
        sent_count=sent_count,
        failed_count=failed_count,
        details=details,
    )


@router.post("/send-user/{user_id}", response_model=SingleReminderResponse)
async def send_user_reminder(user_id: str, target_date: Optional[str] = None):
    """
    Send a workout reminder to a specific user.

    Args:
        user_id: The user's UUID
        target_date: Optional ISO date string (YYYY-MM-DD). Defaults to today.

    Returns:
        Result of the reminder attempt.
    """
    logger.info(f"Sending reminder to user {user_id}")

    email_service = get_email_service()

    if not email_service.is_configured():
        raise HTTPException(
            status_code=503,
            detail="Email service not configured. Please set RESEND_API_KEY."
        )

    db = get_supabase_db()

    # Get user
    user = db.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Determine target date
    if target_date:
        try:
            reminder_date = datetime.strptime(target_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")
    else:
        reminder_date = date.today()

    date_str = reminder_date.isoformat()

    # Get user's scheduled workouts for the date
    workouts = db.list_current_workouts(
        user_id=user_id,
        is_completed=False,
        from_date=date_str,
        to_date=date_str,
    )

    if not workouts:
        return SingleReminderResponse(
            success=False,
            message=f"No workouts scheduled for {date_str}"
        )

    # Get user's email
    preferences = user.get("preferences", {})
    if isinstance(preferences, str):
        try:
            preferences = json.loads(preferences)
        except json.JSONDecodeError:
            preferences = {}

    email = preferences.get("email") or user.get("email")
    user_name = preferences.get("name") or user.get("name") or "Fitness Enthusiast"

    if not email:
        raise HTTPException(status_code=400, detail="User has no email address configured")

    # Send reminder for the first workout (or combine if multiple)
    workout = workouts[0]
    workout_name = workout.get("name", "Your Workout")
    workout_type = workout.get("type", "workout")

    # Parse exercises from JSON
    exercises_json = workout.get("exercises_json", "[]")
    if isinstance(exercises_json, str):
        try:
            exercises = json.loads(exercises_json)
        except json.JSONDecodeError:
            exercises = []
    else:
        exercises = exercises_json or []

    # Send the reminder email
    result = await email_service.send_workout_reminder(
        to_email=email,
        user_name=user_name,
        workout_name=workout_name,
        workout_type=workout_type,
        scheduled_date=reminder_date,
        exercises=exercises,
    )

    if result.get("success"):
        return SingleReminderResponse(
            success=True,
            message=f"Reminder sent to {email}",
            email_id=result.get("id")
        )
    else:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send email: {result.get('error')}"
        )


@router.post("/test")
async def send_test_reminder(to_email: str):
    """
    Send a test reminder email to verify the email service is working.

    Args:
        to_email: Email address to send test to

    Returns:
        Result of the test email.
    """
    logger.info(f"Sending test reminder to {to_email}")

    email_service = get_email_service()

    if not email_service.is_configured():
        raise HTTPException(
            status_code=503,
            detail="Email service not configured. Please set RESEND_API_KEY."
        )

    # Send a test workout reminder
    result = await email_service.send_workout_reminder(
        to_email=to_email,
        user_name="Test User",
        workout_name="Test Workout - Upper Body",
        workout_type="upper_body",
        scheduled_date=date.today(),
        exercises=[
            {"name": "Bench Press", "sets": 4, "reps": 8},
            {"name": "Shoulder Press", "sets": 3, "reps": 10},
            {"name": "Lat Pulldown", "sets": 3, "reps": 12},
            {"name": "Bicep Curls", "sets": 3, "reps": 15},
        ],
    )

    if result.get("success"):
        return {
            "success": True,
            "message": f"Test email sent to {to_email}",
            "email_id": result.get("id")
        }
    else:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send test email: {result.get('error')}"
        )
