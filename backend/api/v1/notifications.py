"""
Push Notification API endpoints.

ENDPOINTS:
- POST /api/v1/notifications/test - Send a test notification
- POST /api/v1/notifications/register - Register FCM token for a user
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.notification_service import get_notification_service

router = APIRouter()
logger = get_logger(__name__)


class TestNotificationRequest(BaseModel):
    """Request body for sending a test notification."""
    user_id: str
    fcm_token: str


class RegisterTokenRequest(BaseModel):
    """Request body for registering FCM token."""
    user_id: str
    fcm_token: str


class SendNotificationRequest(BaseModel):
    """Request body for sending a custom notification."""
    user_id: str
    title: str
    body: str
    notification_type: Optional[str] = "ai_coach"
    data: Optional[dict] = None


@router.post("/test")
async def send_test_notification(request: TestNotificationRequest):
    """
    Send a test notification to verify push notifications are working.

    This also registers the FCM token with the user's account.
    """
    logger.info(f"Sending test notification to user {request.user_id}")

    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(request.user_id)
        if not user:
            logger.warning(f"User not found: {request.user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Update FCM token for user
        db.update_user(request.user_id, {"fcm_token": request.fcm_token})
        logger.info(f"FCM token registered for user {request.user_id}")

        # Send test notification
        notification_service = get_notification_service()
        success = await notification_service.send_test_notification(request.fcm_token)

        if success:
            logger.info(f"✅ Test notification sent successfully to user {request.user_id}")
            return {
                "success": True,
                "message": "Test notification sent successfully",
                "user_id": request.user_id
            }
        else:
            logger.error(f"❌ Failed to send test notification to user {request.user_id}")
            raise HTTPException(
                status_code=500,
                detail="Failed to send notification. Token may be invalid."
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error sending test notification: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/register")
async def register_fcm_token(request: RegisterTokenRequest):
    """
    Register or update FCM token for a user.

    This should be called when:
    - User logs in
    - FCM token is refreshed
    - App is reinstalled
    """
    logger.info(f"Registering FCM token for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(request.user_id)
        if not user:
            logger.warning(f"User not found: {request.user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Update FCM token
        db.update_user(request.user_id, {"fcm_token": request.fcm_token})
        logger.info(f"✅ FCM token registered for user {request.user_id}")

        return {
            "success": True,
            "message": "FCM token registered successfully",
            "user_id": request.user_id
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error registering FCM token: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/send")
async def send_notification(request: SendNotificationRequest):
    """
    Send a custom notification to a user.

    This endpoint is for internal use (scheduled jobs, AI agents, etc.)
    """
    logger.info(f"Sending notification to user {request.user_id}: {request.title}")

    try:
        db = get_supabase_db()

        # Get user and their FCM token
        user = db.get_user(request.user_id)
        if not user:
            logger.warning(f"User not found: {request.user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            logger.warning(f"No FCM token for user {request.user_id}")
            raise HTTPException(
                status_code=400,
                detail="User has no registered FCM token"
            )

        # Send notification
        notification_service = get_notification_service()
        success = await notification_service.send_notification(
            fcm_token=fcm_token,
            title=request.title,
            body=request.body,
            notification_type=request.notification_type,
            data=request.data,
        )

        if success:
            logger.info(f"✅ Notification sent to user {request.user_id}")
            return {
                "success": True,
                "message": "Notification sent successfully",
                "user_id": request.user_id
            }
        else:
            logger.error(f"❌ Failed to send notification to user {request.user_id}")
            raise HTTPException(
                status_code=500,
                detail="Failed to send notification"
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error sending notification: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/workout-reminder/{user_id}")
async def send_workout_reminder(user_id: str, workout_name: str = "today's workout"):
    """
    Send a workout reminder notification to a user.
    """
    logger.info(f"Sending workout reminder to user {user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            raise HTTPException(status_code=400, detail="User has no FCM token")

        user_name = user.get("name")
        notification_service = get_notification_service()
        success = await notification_service.send_workout_reminder(
            fcm_token=fcm_token,
            workout_name=workout_name,
            user_name=user_name,
        )

        return {"success": success, "user_id": user_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending workout reminder: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/guilt/{user_id}")
async def send_guilt_notification(user_id: str, days_missed: int = 1):
    """
    Send a guilt notification for missed workouts (Duolingo-style).
    """
    logger.info(f"Sending guilt notification to user {user_id} (missed {days_missed} days)")

    try:
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            raise HTTPException(status_code=400, detail="User has no FCM token")

        notification_service = get_notification_service()
        success = await notification_service.send_missed_workout_guilt(
            fcm_token=fcm_token,
            days_missed=days_missed,
        )

        return {"success": success, "user_id": user_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending guilt notification: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/nutrition-reminder/{user_id}")
async def send_nutrition_reminder(user_id: str, meal_type: str = "meal"):
    """
    Send a nutrition logging reminder.
    """
    logger.info(f"Sending nutrition reminder to user {user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            raise HTTPException(status_code=400, detail="User has no FCM token")

        notification_service = get_notification_service()
        success = await notification_service.send_nutrition_reminder(
            fcm_token=fcm_token,
            meal_type=meal_type,
        )

        return {"success": success, "user_id": user_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending nutrition reminder: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/hydration-reminder/{user_id}")
async def send_hydration_reminder(user_id: str, current_ml: int = 0, goal_ml: int = 2000):
    """
    Send a hydration reminder.
    """
    logger.info(f"Sending hydration reminder to user {user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            raise HTTPException(status_code=400, detail="User has no FCM token")

        notification_service = get_notification_service()
        success = await notification_service.send_hydration_reminder(
            fcm_token=fcm_token,
            current_ml=current_ml,
            goal_ml=goal_ml,
        )

        return {"success": success, "user_id": user_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending hydration reminder: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────────────────────────────────────
# SCHEDULER ENDPOINTS
# These are called by external schedulers (e.g., cron jobs, Render cron)
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/scheduler/check-inactive-users")
async def check_inactive_users():
    """
    Check for users who haven't worked out recently and send guilt notifications.

    This endpoint should be called daily by a cron job.

    Logic:
    - 1 day missed: "Your muscles miss you!"
    - 2 days missed: "Your AI Coach is getting lonely..."
    - 3+ days missed: "It's been X days!"
    """
    logger.info("🔔 Running scheduler: checking for inactive users")

    try:
        db = get_supabase_db()
        notification_service = get_notification_service()

        # Get all users with FCM tokens
        users_response = db.client.table("users").select(
            "id, name, fcm_token, notification_preferences"
        ).not_.is_("fcm_token", "null").execute()

        users = users_response.data if users_response.data else []
        logger.info(f"Found {len(users)} users with FCM tokens")

        results = {
            "total_users": len(users),
            "notifications_sent": 0,
            "skipped_preferences": 0,
            "skipped_no_token": 0,
            "errors": 0,
            "details": []
        }

        from datetime import datetime, timedelta
        today = datetime.utcnow().date()

        for user in users:
            user_id = user["id"]
            fcm_token = user.get("fcm_token")

            if not fcm_token:
                results["skipped_no_token"] += 1
                continue

            # Check notification preferences
            prefs = user.get("notification_preferences") or {}
            if prefs.get("streak_alerts") is False:
                results["skipped_preferences"] += 1
                continue

            try:
                # Get user's last workout completion
                workouts_response = db.client.table("workout_summaries").select(
                    "created_at"
                ).eq("user_id", user_id).order(
                    "created_at", desc=True
                ).limit(1).execute()

                if not workouts_response.data:
                    # User has never completed a workout - don't guilt them yet
                    continue

                last_workout_str = workouts_response.data[0]["created_at"]
                last_workout_date = datetime.fromisoformat(
                    last_workout_str.replace("Z", "+00:00")
                ).date()

                days_missed = (today - last_workout_date).days

                # Only send if they've missed at least 1 day
                if days_missed >= 1:
                    success = await notification_service.send_missed_workout_guilt(
                        fcm_token=fcm_token,
                        days_missed=days_missed,
                    )

                    if success:
                        results["notifications_sent"] += 1
                        results["details"].append({
                            "user_id": user_id,
                            "days_missed": days_missed,
                            "status": "sent"
                        })
                    else:
                        results["errors"] += 1
                        results["details"].append({
                            "user_id": user_id,
                            "days_missed": days_missed,
                            "status": "failed"
                        })

            except Exception as e:
                logger.error(f"Error processing user {user_id}: {e}")
                results["errors"] += 1

        logger.info(f"✅ Scheduler complete: {results['notifications_sent']} notifications sent")
        return results

    except Exception as e:
        logger.error(f"❌ Error in scheduler: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/scheduler/send-workout-reminders")
async def send_workout_reminders():
    """
    Send workout reminders to users who have workouts scheduled for today.

    This endpoint should be called in the morning by a cron job.
    """
    logger.info("🔔 Running scheduler: sending workout reminders")

    try:
        db = get_supabase_db()
        notification_service = get_notification_service()

        from datetime import datetime
        today = datetime.utcnow().date()
        today_str = today.isoformat()

        # Get all workouts scheduled for today
        workouts_response = db.client.table("workouts").select(
            "id, name, user_id"
        ).eq("scheduled_date", today_str).execute()

        workouts = workouts_response.data if workouts_response.data else []
        logger.info(f"Found {len(workouts)} workouts scheduled for today")

        results = {
            "total_workouts": len(workouts),
            "notifications_sent": 0,
            "skipped_preferences": 0,
            "skipped_no_token": 0,
            "errors": 0
        }

        # Get unique user IDs
        user_ids = list(set(w["user_id"] for w in workouts))

        for user_id in user_ids:
            try:
                user = db.get_user(user_id)
                if not user:
                    continue

                fcm_token = user.get("fcm_token")
                if not fcm_token:
                    results["skipped_no_token"] += 1
                    continue

                # Check notification preferences
                prefs = user.get("notification_preferences") or {}
                if prefs.get("workout_reminders") is False:
                    results["skipped_preferences"] += 1
                    continue

                # Get workout name for this user
                user_workouts = [w for w in workouts if w["user_id"] == user_id]
                workout_name = user_workouts[0]["name"] if user_workouts else "today's workout"

                success = await notification_service.send_workout_reminder(
                    fcm_token=fcm_token,
                    workout_name=workout_name,
                    user_name=user.get("name"),
                )

                if success:
                    results["notifications_sent"] += 1
                else:
                    results["errors"] += 1

            except Exception as e:
                logger.error(f"Error sending reminder to user {user_id}: {e}")
                results["errors"] += 1

        logger.info(f"✅ Workout reminders complete: {results['notifications_sent']} sent")
        return results

    except Exception as e:
        logger.error(f"❌ Error sending workout reminders: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/scheduler/status")
async def scheduler_status():
    """
    Get information about scheduler endpoints.

    Returns available scheduler endpoints and their descriptions.
    """
    return {
        "status": "ok",
        "endpoints": [
            {
                "path": "/scheduler/check-inactive-users",
                "method": "POST",
                "description": "Send guilt notifications to users who haven't worked out",
                "recommended_schedule": "Daily at 6pm local time"
            },
            {
                "path": "/scheduler/send-workout-reminders",
                "method": "POST",
                "description": "Send reminders to users with workouts scheduled today",
                "recommended_schedule": "Daily at 8am local time"
            }
        ],
        "notes": [
            "These endpoints should be called by external cron jobs (e.g., Render cron, AWS CloudWatch)",
            "Each endpoint respects user notification preferences",
            "Users without FCM tokens are skipped"
        ]
    }
