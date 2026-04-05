"""Secondary endpoints for notifications.  Sub-router included by main module."""
Push Notification API endpoints.

ENDPOINTS:
- POST /api/v1/notifications/test - Send a test notification
- POST /api/v1/notifications/register - Register FCM token for a user
- GET  /api/v1/notifications/billing/{user_id} - Get upcoming billing reminders
- POST /api/v1/notifications/billing/{user_id}/preferences - Update billing notification preferences
- POST /api/v1/notifications/billing/{user_id}/dismiss-banner - Dismiss renewal banner
- POST /api/v1/notifications/scheduler/send-billing-reminders - Send due billing reminders
- POST /api/v1/notifications/track-interaction - Track notification open/interaction
- POST /api/v1/notifications/scheduler/recalculate-optimal-times - Recalculate optimal send times

from .notifications_models import (
    TestNotificationRequest,
    RegisterTokenRequest,
    SendNotificationRequest,
    BillingNotificationResponse,
    UpcomingRenewalResponse,
    BillingPreferencesRequest,
    DismissBannerRequest,
    TrackInteractionRequest,
    MovementReminderRequest,
)

router = APIRouter()

@router.get("/billing/{user_id}", response_model=UpcomingRenewalResponse)
async def get_billing_reminders(user_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "notifications")


@router.post("/billing/{user_id}/preferences")
async def update_billing_preferences(user_id: str, request: BillingPreferencesRequest,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "notifications")


@router.post("/billing/{user_id}/dismiss-banner")
async def dismiss_renewal_banner(user_id: str, request: DismissBannerRequest,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "notifications")


@router.post("/scheduler/send-billing-reminders")
async def send_billing_reminders(
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "notifications")


@router.post("/billing/{user_id}/send-plan-change")
async def send_plan_change_notification(
    user_id: str,
    old_plan: str,
    new_plan: str,
    old_price: Optional[float] = None,
    new_price: Optional[float] = None,
    current_user: dict = Depends(get_current_user),
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
        raise safe_internal_error(e, "notifications")


@router.post("/billing/{user_id}/send-refund-confirmation")
async def send_refund_confirmation(
    user_id: str,
    amount: float,
    currency: str = "USD",
    current_user: dict = Depends(get_current_user),
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
        raise safe_internal_error(e, "notifications")


def _is_upgrade(old_plan: str, new_plan: str) -> bool:
    """Determine if a plan change is an upgrade."""
    tier_levels = {"free": 0, "premium": 1, "premium_plus": 2, "lifetime": 3}
    old_level = tier_levels.get(old_plan.lower(), 0)
    new_level = tier_levels.get(new_plan.lower(), 0)
    return new_level > old_level


# ─────────────────────────────────────────────────────────────────────────────
# NOTIFICATION INTERACTION TRACKING + OPTIMAL TIME ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────


class TrackInteractionRequest(BaseModel):
    """Request body for tracking a notification interaction."""
    notification_type: str
    opened_at: str  # ISO timestamp


@router.post("/track-interaction")
async def track_notification_interaction(
    request: TrackInteractionRequest,
    user_id: str = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Track when a user opens/interacts with a notification.

    Updates the most recent matching notification_event for this user/type
    that hasn't been opened yet.
    """
    if not user_id:
        raise HTTPException(status_code=400, detail="user_id query parameter is required")

    logger.info(f"Tracking notification interaction for user {user_id}: {request.notification_type}")

    try:
        supabase = get_supabase()

        # Parse the opened_at timestamp
        try:
            opened_dt = datetime.fromisoformat(request.opened_at.replace("Z", "+00:00"))
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid opened_at timestamp format")

        local_hour_opened = opened_dt.hour

        # Find the most recent unread notification event for this user/type
        event_resp = supabase.client.table("notification_events").select(
            "id"
        ).eq("user_id", user_id).eq(
            "notification_type", request.notification_type
        ).is_("opened_at", "null").order(
            "sent_at", desc=True
        ).limit(1).execute()

        if not event_resp.data:
            # No matching unread event found - create a new interaction record
            supabase.client.table("notification_events").insert({
                "user_id": user_id,
                "notification_type": request.notification_type,
                "sent_at": request.opened_at,
                "opened_at": request.opened_at,
                "local_hour_opened": local_hour_opened,
            }).execute()

            return {
                "success": True,
                "message": "Interaction recorded (new event created)",
                "user_id": user_id,
            }

        # Update the existing event
        event_id = event_resp.data[0]["id"]
        supabase.client.table("notification_events").update({
            "opened_at": request.opened_at,
            "local_hour_opened": local_hour_opened,
        }).eq("id", event_id).execute()

        return {
            "success": True,
            "message": "Interaction tracked",
            "user_id": user_id,
            "event_id": event_id,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error tracking notification interaction: {e}")
        raise safe_internal_error(e, "notifications")


@router.post("/scheduler/recalculate-optimal-times")
async def recalculate_optimal_times(
    current_user: dict = Depends(get_current_user),
):
    """
    Recalculate optimal notification send times for all active users.

    This endpoint should be called daily by a cron job (recommended: 3am UTC).
    Uses notification open events and app activity data to determine the best
    hour to send each type of notification per user.
    """
    logger.info("Running scheduler: recalculating optimal notification times")

    try:
        results = await recalculate_all_optimal_times()
        logger.info(f"Optimal times recalculation complete: {results}")
        return results
    except Exception as e:
        logger.error(f"Error recalculating optimal times: {e}")
        raise safe_internal_error(e, "notifications")


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
    current_user: dict = Depends(get_current_user),
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
        raise safe_internal_error(e, "notifications")


@router.post("/scheduler/send-movement-reminders")
async def send_movement_reminders(
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "notifications")


@router.get("/movement-reminder/status/{user_id}")
async def get_movement_reminder_status(user_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "notifications")
