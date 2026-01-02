"""
Push Notification API endpoints.

ENDPOINTS:
- POST /api/v1/notifications/test - Send a test notification
- POST /api/v1/notifications/register - Register FCM token for a user
- GET  /api/v1/notifications/billing/{user_id} - Get upcoming billing reminders
- POST /api/v1/notifications/billing/{user_id}/preferences - Update billing notification preferences
- POST /api/v1/notifications/billing/{user_id}/dismiss-banner - Dismiss renewal banner
- POST /api/v1/notifications/scheduler/send-billing-reminders - Send due billing reminders
"""

from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List

from core.supabase_db import get_supabase_db
from core.supabase_client import get_supabase
from core.logger import get_logger
from services.notification_service import get_notification_service
from core.activity_logger import log_user_activity, log_user_error

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

        # Log FCM registration
        await log_user_activity(
            user_id=request.user_id,
            action="fcm_token_registered",
            endpoint="/api/v1/notifications/register",
            message="FCM token registered",
            status_code=200
        )

        return {
            "success": True,
            "message": "FCM token registered successfully",
            "user_id": request.user_id
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error registering FCM token: {e}")
        await log_user_error(
            user_id=request.user_id,
            action="fcm_token_registered",
            error=e,
            endpoint="/api/v1/notifications/register",
            status_code=500
        )
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

            # Log notification sent
            await log_user_activity(
                user_id=request.user_id,
                action="notification_sent",
                endpoint="/api/v1/notifications/send",
                message=f"Sent notification: {request.title}",
                metadata={"title": request.title, "notification_type": request.notification_type},
                status_code=200
            )

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
        await log_user_error(
            user_id=request.user_id,
            action="notification_sent",
            error=e,
            endpoint="/api/v1/notifications/send",
            status_code=500
        )
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
            },
            {
                "path": "/scheduler/send-billing-reminders",
                "method": "POST",
                "description": "Send billing reminder notifications for upcoming renewals",
                "recommended_schedule": "Daily at 10am UTC"
            },
            {
                "path": "/scheduler/send-movement-reminders",
                "method": "POST",
                "description": "Send NEAT movement reminders to sedentary users",
                "recommended_schedule": "Hourly (on the hour, e.g., 9am, 10am, ...)"
            }
        ],
        "notes": [
            "These endpoints should be called by external cron jobs (e.g., Render cron, AWS CloudWatch)",
            "Each endpoint respects user notification preferences",
            "Users without FCM tokens are skipped",
            "Movement reminders require step data synced from the mobile app"
        ]
    }


# ─────────────────────────────────────────────────────────────────────────────
# BILLING NOTIFICATION ENDPOINTS
# For subscription transparency and renewal reminders
# ─────────────────────────────────────────────────────────────────────────────


class BillingNotificationResponse(BaseModel):
    """Response for a billing notification."""
    id: str
    notification_type: str
    scheduled_for: str
    sent_at: Optional[str] = None
    renewal_amount: Optional[float] = None
    currency: str = "USD"
    product_id: Optional[str] = None
    status: str
    metadata: Optional[dict] = None


class UpcomingRenewalResponse(BaseModel):
    """Response with upcoming renewal info for in-app banner."""
    has_upcoming_renewal: bool
    renewal_date: Optional[str] = None
    days_until_renewal: Optional[int] = None
    renewal_amount: Optional[float] = None
    currency: str = "USD"
    tier: Optional[str] = None
    product_id: Optional[str] = None
    show_banner: bool = False
    notifications: List[BillingNotificationResponse] = []


class BillingPreferencesRequest(BaseModel):
    """Request to update billing notification preferences."""
    billing_notifications_enabled: bool


class DismissBannerRequest(BaseModel):
    """Request to dismiss the renewal banner."""
    dismiss_until: Optional[str] = None  # ISO date string, defaults to renewal date


@router.get("/billing/{user_id}", response_model=UpcomingRenewalResponse)
async def get_billing_reminders(user_id: str):
    """
    Get upcoming billing reminders and renewal information for a user.

    Returns:
    - Upcoming renewal date and amount
    - Whether to show the renewal banner
    - List of pending/sent billing notifications
    """
    logger.info(f"Getting billing reminders for user {user_id}")

    try:
        supabase = get_supabase()

        # Get user's subscription
        sub_result = supabase.client.table("user_subscriptions").select(
            "id, tier, status, product_id, current_period_end, price_paid, currency"
        ).eq("user_id", user_id).single().execute()

        if not sub_result.data:
            return UpcomingRenewalResponse(
                has_upcoming_renewal=False,
                show_banner=False,
                notifications=[]
            )

        sub = sub_result.data

        # Check if subscription is active and has a renewal date
        if sub["status"] not in ("active", "trial") or not sub.get("current_period_end"):
            return UpcomingRenewalResponse(
                has_upcoming_renewal=False,
                show_banner=False,
                notifications=[]
            )

        renewal_date = datetime.fromisoformat(sub["current_period_end"].replace("Z", "+00:00"))
        now = datetime.utcnow().replace(tzinfo=renewal_date.tzinfo)
        days_until = (renewal_date - now).days

        # Get user's banner dismissal status
        user_result = supabase.client.table("users").select(
            "billing_notifications_enabled, renewal_banner_dismissed_until"
        ).eq("id", user_id).single().execute()

        user_data = user_result.data or {}
        billing_enabled = user_data.get("billing_notifications_enabled", True)
        dismissed_until_str = user_data.get("renewal_banner_dismissed_until")

        # Determine if banner should be shown
        show_banner = False
        if billing_enabled and days_until <= 5 and days_until >= 0:
            show_banner = True
            # Check if user dismissed the banner
            if dismissed_until_str:
                dismissed_until = datetime.fromisoformat(dismissed_until_str.replace("Z", "+00:00"))
                if now < dismissed_until:
                    show_banner = False

        # Get billing notifications for this user
        notif_result = supabase.client.table("billing_notifications").select(
            "id, notification_type, scheduled_for, sent_at, renewal_amount, currency, product_id, status, metadata"
        ).eq("user_id", user_id).order("scheduled_for", desc=True).limit(10).execute()

        notifications = []
        for n in notif_result.data or []:
            notifications.append(BillingNotificationResponse(
                id=n["id"],
                notification_type=n["notification_type"],
                scheduled_for=n["scheduled_for"],
                sent_at=n.get("sent_at"),
                renewal_amount=float(n["renewal_amount"]) if n.get("renewal_amount") else None,
                currency=n.get("currency", "USD"),
                product_id=n.get("product_id"),
                status=n["status"],
                metadata=n.get("metadata")
            ))

        return UpcomingRenewalResponse(
            has_upcoming_renewal=True,
            renewal_date=sub["current_period_end"],
            days_until_renewal=days_until,
            renewal_amount=float(sub["price_paid"]) if sub.get("price_paid") else None,
            currency=sub.get("currency", "USD"),
            tier=sub["tier"],
            product_id=sub.get("product_id"),
            show_banner=show_banner,
            notifications=notifications
        )

    except Exception as e:
        logger.error(f"Error getting billing reminders: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/billing/{user_id}/preferences")
async def update_billing_preferences(user_id: str, request: BillingPreferencesRequest):
    """
    Update billing notification preferences for a user.
    """
    logger.info(f"Updating billing preferences for user {user_id}: enabled={request.billing_notifications_enabled}")

    try:
        supabase = get_supabase()

        # Update user's billing notification preference
        supabase.client.table("users").update({
            "billing_notifications_enabled": request.billing_notifications_enabled
        }).eq("id", user_id).execute()

        await log_user_activity(
            user_id=user_id,
            action="billing_preferences_updated",
            endpoint="/api/v1/notifications/billing/preferences",
            message=f"Billing notifications {'enabled' if request.billing_notifications_enabled else 'disabled'}",
            status_code=200
        )

        return {
            "success": True,
            "billing_notifications_enabled": request.billing_notifications_enabled
        }

    except Exception as e:
        logger.error(f"Error updating billing preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/billing/{user_id}/dismiss-banner")
async def dismiss_renewal_banner(user_id: str, request: DismissBannerRequest):
    """
    Dismiss the renewal reminder banner until a specified date.

    If no date is provided, dismisses until the renewal date.
    """
    logger.info(f"Dismissing renewal banner for user {user_id}")

    try:
        supabase = get_supabase()

        # Get the dismiss until date
        dismiss_until = request.dismiss_until

        if not dismiss_until:
            # Default to the renewal date
            sub_result = supabase.client.table("user_subscriptions").select(
                "current_period_end"
            ).eq("user_id", user_id).single().execute()

            if sub_result.data and sub_result.data.get("current_period_end"):
                dismiss_until = sub_result.data["current_period_end"]
            else:
                # Default to 7 days from now
                dismiss_until = (datetime.utcnow() + timedelta(days=7)).isoformat()

        # Update user's banner dismissal
        supabase.client.table("users").update({
            "renewal_banner_dismissed_until": dismiss_until
        }).eq("id", user_id).execute()

        return {
            "success": True,
            "dismissed_until": dismiss_until
        }

    except Exception as e:
        logger.error(f"Error dismissing renewal banner: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/scheduler/send-billing-reminders")
async def send_billing_reminders():
    """
    Send billing reminder notifications for subscriptions renewing soon.

    This endpoint should be called daily by a cron job (recommended: 10am UTC).

    Sends:
    - 5-day renewal reminders
    - 1-day renewal reminders

    Respects user billing notification preferences.
    """
    logger.info("🔔 Running scheduler: sending billing reminders")

    try:
        supabase = get_supabase()
        notification_service = get_notification_service()

        now = datetime.utcnow()

        # Get all pending billing notifications that are due
        notif_result = supabase.client.table("billing_notifications").select(
            "id, user_id, subscription_id, notification_type, scheduled_for, renewal_amount, currency, product_id"
        ).eq("status", "pending").lte("scheduled_for", now.isoformat()).execute()

        notifications = notif_result.data or []
        logger.info(f"Found {len(notifications)} pending billing notifications")

        results = {
            "total_pending": len(notifications),
            "notifications_sent": 0,
            "skipped_preferences": 0,
            "skipped_no_token": 0,
            "errors": 0,
            "details": []
        }

        for notif in notifications:
            user_id = notif["user_id"]
            notif_id = notif["id"]
            notif_type = notif["notification_type"]

            try:
                # Get user info
                db = get_supabase_db()
                user = db.get_user(user_id)

                if not user:
                    logger.warning(f"User not found for notification {notif_id}")
                    results["errors"] += 1
                    continue

                # Check if user has billing notifications enabled
                if user.get("billing_notifications_enabled") is False:
                    results["skipped_preferences"] += 1
                    # Mark as cancelled since user opted out
                    supabase.client.table("billing_notifications").update({
                        "status": "cancelled",
                        "updated_at": now.isoformat()
                    }).eq("id", notif_id).execute()
                    continue

                fcm_token = user.get("fcm_token")
                if not fcm_token:
                    results["skipped_no_token"] += 1
                    continue

                # Format notification message
                amount = notif.get("renewal_amount")
                currency = notif.get("currency", "USD")
                currency_symbol = "$" if currency == "USD" else currency

                if notif_type == "renewal_reminder_5day":
                    title = "Subscription renewing soon"
                    body = f"Your Premium subscription renews in 5 days"
                    if amount:
                        body += f" for {currency_symbol}{amount:.2f}"
                    body += ". Tap to manage."
                elif notif_type == "renewal_reminder_1day":
                    title = "Subscription renews tomorrow"
                    body = f"Your Premium subscription renews tomorrow"
                    if amount:
                        body += f" for {currency_symbol}{amount:.2f}"
                    body += ". Tap to manage."
                elif notif_type == "plan_change":
                    title = "Plan change confirmed"
                    body = "Your subscription plan has been updated."
                elif notif_type == "refund_received":
                    title = "Refund processed"
                    body = "Your refund request has been processed."
                else:
                    title = "Subscription update"
                    body = "There's an update about your subscription."

                # Send the notification
                success = await notification_service.send_notification(
                    fcm_token=fcm_token,
                    title=title,
                    body=body,
                    notification_type="billing_reminder",
                    data={
                        "action": "open_subscription",
                        "notification_id": notif_id,
                        "type": notif_type
                    }
                )

                if success:
                    # Update notification status to sent
                    supabase.client.table("billing_notifications").update({
                        "status": "sent",
                        "sent_at": now.isoformat(),
                        "title": title,
                        "body": body,
                        "updated_at": now.isoformat()
                    }).eq("id", notif_id).execute()

                    results["notifications_sent"] += 1
                    results["details"].append({
                        "notification_id": notif_id,
                        "user_id": user_id,
                        "type": notif_type,
                        "status": "sent"
                    })
                else:
                    # Update notification status to failed
                    supabase.client.table("billing_notifications").update({
                        "status": "failed",
                        "error_message": "Failed to send FCM notification",
                        "updated_at": now.isoformat()
                    }).eq("id", notif_id).execute()

                    results["errors"] += 1
                    results["details"].append({
                        "notification_id": notif_id,
                        "user_id": user_id,
                        "type": notif_type,
                        "status": "failed"
                    })

            except Exception as e:
                logger.error(f"Error processing notification {notif_id}: {e}")
                results["errors"] += 1

                # Update notification with error
                supabase.client.table("billing_notifications").update({
                    "status": "failed",
                    "error_message": str(e),
                    "updated_at": now.isoformat()
                }).eq("id", notif_id).execute()

        logger.info(f"✅ Billing reminders complete: {results['notifications_sent']} sent, {results['errors']} errors")
        return results

    except Exception as e:
        logger.error(f"❌ Error sending billing reminders: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/billing/{user_id}/send-plan-change")
async def send_plan_change_notification(
    user_id: str,
    old_plan: str,
    new_plan: str,
    old_price: Optional[float] = None,
    new_price: Optional[float] = None
):
    """
    Send a plan change confirmation notification.

    Called when user upgrades/downgrades their subscription.
    """
    logger.info(f"Sending plan change notification to user {user_id}: {old_plan} -> {new_plan}")

    try:
        db = get_supabase_db()
        notification_service = get_notification_service()

        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Check if user has billing notifications enabled
        if user.get("billing_notifications_enabled") is False:
            return {"success": False, "reason": "User has disabled billing notifications"}

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            return {"success": False, "reason": "User has no FCM token"}

        # Format message
        is_upgrade = _is_upgrade(old_plan, new_plan)
        action = "upgraded" if is_upgrade else "changed"

        title = f"Plan {action} successfully"
        body = f"Your plan has been {action} from {old_plan.title()} to {new_plan.title()}."

        if new_price is not None:
            body += f" Your new rate is ${new_price:.2f}."

        success = await notification_service.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type="billing_reminder",
            data={
                "action": "open_subscription",
                "type": "plan_change",
                "old_plan": old_plan,
                "new_plan": new_plan
            }
        )

        return {"success": success, "user_id": user_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending plan change notification: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/billing/{user_id}/send-refund-confirmation")
async def send_refund_confirmation(
    user_id: str,
    amount: float,
    currency: str = "USD"
):
    """
    Send a refund confirmation notification.

    Called when a refund is processed.
    """
    logger.info(f"Sending refund confirmation to user {user_id}: {currency} {amount}")

    try:
        db = get_supabase_db()
        notification_service = get_notification_service()

        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            return {"success": False, "reason": "User has no FCM token"}

        currency_symbol = "$" if currency == "USD" else currency
        title = "Refund processed"
        body = f"Your refund of {currency_symbol}{amount:.2f} has been processed and will be credited to your original payment method."

        success = await notification_service.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type="billing_reminder",
            data={
                "action": "open_subscription",
                "type": "refund_received",
                "amount": str(amount),
                "currency": currency
            }
        )

        # Record the notification
        supabase = get_supabase()
        supabase.client.table("billing_notifications").insert({
            "user_id": user_id,
            "notification_type": "refund_received",
            "scheduled_for": datetime.utcnow().isoformat(),
            "sent_at": datetime.utcnow().isoformat() if success else None,
            "renewal_amount": amount,
            "currency": currency,
            "status": "sent" if success else "failed",
            "title": title,
            "body": body
        }).execute()

        return {"success": success, "user_id": user_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending refund confirmation: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def _is_upgrade(old_plan: str, new_plan: str) -> bool:
    """Determine if a plan change is an upgrade."""
    tier_levels = {"free": 0, "premium": 1, "ultra": 2, "lifetime": 3}
    old_level = tier_levels.get(old_plan.lower(), 0)
    new_level = tier_levels.get(new_plan.lower(), 0)
    return new_level > old_level


# ─────────────────────────────────────────────────────────────────────────────
# MOVEMENT REMINDER (NEAT) ENDPOINTS
# For Non-Exercise Activity Thermogenesis reminders
# ─────────────────────────────────────────────────────────────────────────────


class MovementReminderRequest(BaseModel):
    """Request body for sending a movement reminder."""
    user_id: str
    current_steps: int = 0
    threshold: int = 250


@router.post("/movement-reminder/{user_id}")
async def send_movement_reminder(
    user_id: str,
    current_steps: int = 0,
    threshold: int = 250,
):
    """
    Send a movement reminder notification to a specific user.

    Used when sedentary behavior is detected (steps below threshold).
    """
    logger.info(f"🚶 [Movement] Sending reminder to user {user_id}: {current_steps}/{threshold} steps")

    try:
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Check if user has movement reminders enabled
        notification_prefs = user.get("notification_preferences") or {}
        if notification_prefs.get("movement_reminders") is False:
            logger.info(f"🚶 [Movement] User {user_id} has movement reminders disabled")
            return {"success": False, "reason": "Movement reminders disabled by user"}

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            logger.warning(f"🚶 [Movement] No FCM token for user {user_id}")
            return {"success": False, "reason": "No FCM token"}

        notification_service = get_notification_service()
        success = await notification_service.send_movement_reminder(
            fcm_token=fcm_token,
            current_steps=current_steps,
            threshold=threshold,
        )

        return {"success": success, "user_id": user_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [Movement] Error sending reminder: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/scheduler/send-movement-reminders")
async def send_movement_reminders():
    """
    Send movement reminder notifications to users who are sedentary.

    This endpoint should be called hourly by a cron job (recommended: on the hour).

    Logic:
    - Gets all users with movement reminders enabled
    - Checks their last recorded hourly step count from daily_activity table
    - Sends reminder if below threshold (default 250 steps)
    - Respects quiet hours and work hours settings

    Note: This requires the mobile app to sync step data to the backend.
    For real-time step monitoring, the mobile app handles this locally.
    This endpoint is for server-side reminders when app is in background.
    """
    logger.info("🚶 [Movement] Running scheduler: checking for sedentary users")

    try:
        supabase = get_supabase()
        notification_service = get_notification_service()

        now = datetime.utcnow()
        current_hour = now.hour

        # Get all users with FCM tokens and movement reminders enabled
        users_response = supabase.client.table("users").select(
            "id, name, fcm_token, notification_preferences, timezone"
        ).not_.is_("fcm_token", "null").execute()

        users = users_response.data if users_response.data else []
        logger.info(f"🚶 [Movement] Found {len(users)} users with FCM tokens")

        results = {
            "total_users": len(users),
            "notifications_sent": 0,
            "skipped_disabled": 0,
            "skipped_no_token": 0,
            "skipped_outside_hours": 0,
            "skipped_quiet_hours": 0,
            "skipped_not_sedentary": 0,
            "skipped_no_activity_data": 0,
            "errors": 0,
            "details": []
        }

        for user in users:
            user_id = user["id"]
            fcm_token = user.get("fcm_token")

            if not fcm_token:
                results["skipped_no_token"] += 1
                continue

            # Check notification preferences
            prefs = user.get("notification_preferences") or {}

            # Skip if movement reminders disabled
            if prefs.get("movement_reminders") is False:
                results["skipped_disabled"] += 1
                continue

            # Get user's timezone for hour calculations
            user_timezone = user.get("timezone") or "UTC"

            try:
                # Calculate user's local hour
                from pytz import timezone as pytz_tz
                from datetime import timezone
                user_tz = pytz_tz(user_timezone)
                user_local_time = now.replace(tzinfo=timezone.utc).astimezone(user_tz)
                user_hour = user_local_time.hour

                # Check if within movement reminder hours (default 9-17)
                movement_start = prefs.get("movement_reminder_start_time", "09:00")
                movement_end = prefs.get("movement_reminder_end_time", "17:00")

                start_hour = int(movement_start.split(":")[0])
                end_hour = int(movement_end.split(":")[0])

                if user_hour < start_hour or user_hour > end_hour:
                    results["skipped_outside_hours"] += 1
                    continue

                # Check quiet hours
                quiet_start = prefs.get("quiet_hours_start", "22:00")
                quiet_end = prefs.get("quiet_hours_end", "08:00")

                quiet_start_hour = int(quiet_start.split(":")[0])
                quiet_end_hour = int(quiet_end.split(":")[0])

                # Handle overnight quiet hours
                if quiet_start_hour > quiet_end_hour:
                    # Overnight (e.g., 22:00 to 08:00)
                    if user_hour >= quiet_start_hour or user_hour <= quiet_end_hour:
                        results["skipped_quiet_hours"] += 1
                        continue
                else:
                    if quiet_start_hour <= user_hour <= quiet_end_hour:
                        results["skipped_quiet_hours"] += 1
                        continue

                # Get user's activity data for the current hour
                # Look for daily_activity records from today
                today_start = user_local_time.replace(
                    hour=0, minute=0, second=0, microsecond=0
                ).isoformat()

                activity_response = supabase.client.table("daily_activity").select(
                    "steps, hourly_steps"
                ).eq("user_id", user_id).gte(
                    "date", today_start.split("T")[0]
                ).order("date", desc=True).limit(1).execute()

                if not activity_response.data:
                    # No activity data - might mean user hasn't synced or isn't using step tracking
                    results["skipped_no_activity_data"] += 1
                    continue

                activity = activity_response.data[0]

                # Get hourly steps for current hour if available
                hourly_steps = activity.get("hourly_steps") or {}
                current_hour_key = str(user_hour)
                current_steps = hourly_steps.get(current_hour_key, 0)

                # Get threshold from preferences or use default
                threshold = prefs.get("movement_step_threshold", 250)

                # Check if sedentary (below threshold)
                if current_steps >= threshold:
                    results["skipped_not_sedentary"] += 1
                    continue

                # Send movement reminder
                success = await notification_service.send_movement_reminder(
                    fcm_token=fcm_token,
                    current_steps=current_steps,
                    threshold=threshold,
                )

                if success:
                    results["notifications_sent"] += 1
                    results["details"].append({
                        "user_id": user_id,
                        "steps": current_steps,
                        "threshold": threshold,
                        "status": "sent"
                    })

                    # Log the reminder
                    await log_user_activity(
                        user_id=user_id,
                        action="movement_reminder_sent",
                        endpoint="/api/v1/notifications/scheduler/send-movement-reminders",
                        message=f"Movement reminder sent: {current_steps}/{threshold} steps",
                        metadata={
                            "current_steps": current_steps,
                            "threshold": threshold,
                            "user_hour": user_hour,
                        },
                        status_code=200
                    )
                else:
                    results["errors"] += 1
                    results["details"].append({
                        "user_id": user_id,
                        "steps": current_steps,
                        "threshold": threshold,
                        "status": "failed"
                    })

            except Exception as e:
                logger.error(f"🚶 [Movement] Error processing user {user_id}: {e}")
                results["errors"] += 1

        logger.info(
            f"✅ [Movement] Scheduler complete: {results['notifications_sent']} reminders sent, "
            f"{results['skipped_not_sedentary']} active users, "
            f"{results['errors']} errors"
        )
        return results

    except Exception as e:
        logger.error(f"❌ [Movement] Error in scheduler: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/movement-reminder/status/{user_id}")
async def get_movement_reminder_status(user_id: str):
    """
    Get the current movement reminder status for a user.

    Returns:
    - Whether movement reminders are enabled
    - Current hour step count (if available)
    - Step threshold
    - Whether user is currently sedentary
    """
    logger.info(f"🚶 [Movement] Getting status for user {user_id}")

    try:
        supabase = get_supabase()
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        prefs = user.get("notification_preferences") or {}
        movement_enabled = prefs.get("movement_reminders", True)
        threshold = prefs.get("movement_step_threshold", 250)
        start_time = prefs.get("movement_reminder_start_time", "09:00")
        end_time = prefs.get("movement_reminder_end_time", "17:00")

        # Get today's activity
        today = datetime.utcnow().date().isoformat()
        activity_response = supabase.client.table("daily_activity").select(
            "steps, hourly_steps"
        ).eq("user_id", user_id).eq("date", today).limit(1).execute()

        current_hour = datetime.utcnow().hour
        current_hour_steps = 0
        total_steps_today = 0

        if activity_response.data:
            activity = activity_response.data[0]
            total_steps_today = activity.get("steps", 0)
            hourly_steps = activity.get("hourly_steps") or {}
            current_hour_steps = hourly_steps.get(str(current_hour), 0)

        return {
            "user_id": user_id,
            "movement_reminders_enabled": movement_enabled,
            "step_threshold": threshold,
            "active_hours": {
                "start": start_time,
                "end": end_time,
            },
            "current_hour": current_hour,
            "current_hour_steps": current_hour_steps,
            "total_steps_today": total_steps_today,
            "is_sedentary": current_hour_steps < threshold,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [Movement] Error getting status: {e}")
        raise HTTPException(status_code=500, detail=str(e))
