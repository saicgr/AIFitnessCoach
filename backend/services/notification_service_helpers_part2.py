"""Second part of notification_service_helpers.py (auto-split for size)."""
import random
from typing import Any, Dict, List, Optional
from datetime import datetime
import logging
logger = logging.getLogger(__name__)

# Constant mirrored from NotificationService to avoid circular import
TYPE_AI_COACH = "ai_coach"


class NotificationServicePart2:
    """Second half of NotificationService methods. Use as mixin."""

    async def generate_accountability_message(
        self,
        nudge_type: str,
        context_dict: Dict[str, Any],
        user_name: Optional[str] = None,
        coach_name: Optional[str] = None,
        coaching_style: Optional[str] = None,
        communication_tone: Optional[str] = None,
        use_emojis: bool = True,
        accountability_intensity: str = "balanced",
        use_ai: bool = True,
    ) -> str:
        """Generate an accountability message without sending it.

        Used by push_nudge_cron.py to get the message text for saving to
        chat_messages before sending the push notification.

        Args:
            Same as send_accountability_nudge() minus fcm_token.

        Returns:
            The generated message body string.

        Notes:
            - EDGE CASE: Always returns a non-empty string (falls back to generic)
        """
        message_body = ""

        # Try Gemini personalization
        if use_ai:
            result = await self._generate_personalized_message(
                notification_type=nudge_type,
                user_name=user_name,
                streak=context_dict.get("streak"),
                workout_name=context_dict.get("workout_name"),
                days_missed=context_dict.get("days"),
                coach_name=coach_name,
                coaching_style=coaching_style,
                communication_tone=communication_tone,
                use_emojis=use_emojis,
                accountability_intensity=accountability_intensity,
            )
            if result:
                _, message_body = result

        # Fall back to template pool
        if not message_body:
            template_key = (nudge_type, accountability_intensity)

            if nudge_type.startswith("guilt_day"):
                try:
                    tier = int(nudge_type.replace("guilt_day", ""))
                except ValueError:
                    tier = 14
                template_pool = self.GUILT_ESCALATION_TEMPLATES.get(
                    (tier, accountability_intensity),
                    self.GUILT_ESCALATION_TEMPLATES.get((14, "balanced"), [])
                )
            else:
                template_pool = self.ACCOUNTABILITY_TEMPLATES.get(template_key, [])

            if template_pool:
                template = random.choice(template_pool)
                safe_context = {
                    "coach_name": coach_name or "Your Coach",
                    "name": user_name or "there",
                    "workout_name": context_dict.get("workout_name", "your workout"),
                    "streak": context_dict.get("streak", 0),
                    "days": context_dict.get("days", 0),
                    "meal_type": context_dict.get("meal_type", "meal"),
                    "incomplete_count": context_dict.get("incomplete_count", 0),
                }
                message_body = template["body"].format(**safe_context)
            else:
                message_body = f"Hey {user_name or 'there'}, {coach_name or 'your coach'} has a reminder for you!"

        return message_body

    async def send_notification(
        self,
        fcm_token: str,
        title: str,
        body: str,
        notification_type: str = TYPE_AI_COACH,
        data: Optional[Dict[str, str]] = None,
        image_url: Optional[str] = None,
    ) -> bool:
        """
        Send a push notification to a single device

        Args:
            fcm_token: The device's FCM token
            title: Notification title
            body: Notification body text
            notification_type: Type of notification for tracking/filtering
            data: Optional additional data payload
            image_url: Optional image URL for rich notifications

        Returns:
            True if sent successfully, False otherwise
        """
        try:
            from firebase_admin import messaging

            # Build the notification
            notification = messaging.Notification(
                title=title,
                body=body,
                image=image_url,
            )

            # Build data payload
            payload = {
                "type": notification_type,
                "timestamp": datetime.utcnow().isoformat(),
            }
            if data:
                payload.update(data)

            # Build Android-specific config with type-specific channel
            channel_id = self._get_channel_id(notification_type)
            android_config = messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#00D9FF",  # Cyan color
                    sound="default",
                    channel_id=channel_id,
                ),
            )

            # Build the message
            message = messaging.Message(
                notification=notification,
                data=payload,
                token=fcm_token,
                android=android_config,
            )

            # Send the message
            response = messaging.send(message)
            logger.info(f"✅ Notification sent: {response}")
            return True

        except messaging.UnregisteredError:
            logger.warning(f"⚠️ FCM token is no longer valid: {fcm_token[:20]}...", exc_info=True)
            return False
        except messaging.SenderIdMismatchError:
            logger.error(f"❌ Sender ID mismatch - FCM token belongs to different Firebase project", exc_info=True)
            return False
        except messaging.InvalidArgumentError as e:
            logger.error(f"❌ Invalid argument error: {e}", exc_info=True)
            return False
        except Exception as e:
            logger.error(f"❌ Failed to send notification: {type(e).__name__}: {e}", exc_info=True)
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}", exc_info=True)
            return False

    async def send_multicast(
        self,
        fcm_tokens: List[str],
        title: str,
        body: str,
        notification_type: str = TYPE_AI_COACH,
        data: Optional[Dict[str, str]] = None,
    ) -> Dict[str, Any]:
        """
        Send notifications to multiple devices

        Args:
            fcm_tokens: List of FCM tokens
            title: Notification title
            body: Notification body text
            notification_type: Type of notification
            data: Optional additional data payload

        Returns:
            Dictionary with success_count and failure_count
        """
        try:
            from firebase_admin import messaging

            notification = messaging.Notification(
                title=title,
                body=body,
            )

            payload = {
                "type": notification_type,
                "timestamp": datetime.utcnow().isoformat(),
            }
            if data:
                payload.update(data)

            channel_id = self._get_channel_id(notification_type)
            android_config = messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#00D9FF",
                    sound="default",
                    channel_id=channel_id,
                ),
            )

            message = messaging.MulticastMessage(
                notification=notification,
                data=payload,
                tokens=fcm_tokens,
                android=android_config,
            )

            response = messaging.send_each_for_multicast(message)

            logger.info(
                f"✅ Multicast sent: {response.success_count} success, "
                f"{response.failure_count} failed"
            )

            return {
                "success_count": response.success_count,
                "failure_count": response.failure_count,
            }

        except Exception as e:
            logger.error(f"❌ Failed to send multicast notification: {e}", exc_info=True)
            return {"success_count": 0, "failure_count": len(fcm_tokens)}

    # ─────────────────────────────────────────────────────────────────
    # Pre-built notification messages with template pools
    # ─────────────────────────────────────────────────────────────────

    async def send_workout_reminder(
        self,
        fcm_token: str,
        workout_name: str = "today's workout",
        user_name: Optional[str] = None,
        user_timezone: Optional[str] = None,
        use_ai: bool = True,
    ) -> bool:
        """Send a workout reminder notification"""
        # Try Gemini personalization first
        if use_ai and user_name:
            time_of_day = self._get_time_of_day(user_timezone)
            ai_result = await self._generate_personalized_message(
                notification_type="workout_reminder",
                user_name=user_name,
                workout_name=workout_name,
                time_of_day=time_of_day,
            )
            if ai_result:
                title, body = ai_result
                return await self.send_notification(
                    fcm_token=fcm_token,
                    title=title,
                    body=body,
                    notification_type=self.TYPE_WORKOUT_REMINDER,
                    data={"action": "open_workout"},
                )

        # Template pool fallback
        template = random.choice(self.WORKOUT_REMINDER_TEMPLATES)
        name = user_name or "there"
        title = template["title"].format(name=name, workout_name=workout_name)
        body = template["body"].format(name=name, workout_name=workout_name)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_WORKOUT_REMINDER,
            data={"action": "open_workout"},
        )

    async def send_missed_workout_guilt(
        self,
        fcm_token: str,
        days_missed: int = 1,
        user_name: Optional[str] = None,
        user_timezone: Optional[str] = None,
        use_ai: bool = True,
    ) -> bool:
        """Send an inactivity nudge notification (positive, no guilt/shame)"""
        # Try Gemini personalization first
        if use_ai and user_name:
            time_of_day = self._get_time_of_day(user_timezone)
            ai_result = await self._generate_personalized_message(
                notification_type="inactivity_nudge",
                user_name=user_name,
                days_missed=days_missed,
                time_of_day=time_of_day,
            )
            if ai_result:
                title, body = ai_result
                return await self.send_notification(
                    fcm_token=fcm_token,
                    title=title,
                    body=body,
                    notification_type=self.TYPE_AI_COACH,
                    data={"action": "open_home"},
                )

        # Template pool fallback - select tier based on days_missed
        if days_missed == 1:
            template = random.choice(self.INACTIVITY_NUDGE_1DAY)
            title = template["title"]
            body = template["body"]
        elif days_missed == 2:
            template = random.choice(self.INACTIVITY_NUDGE_2DAY)
            title = template["title"]
            body = template["body"]
        else:
            template = random.choice(self.INACTIVITY_NUDGE_3PLUS_DAY)
            title = template["title"].format(days=days_missed)
            body = template["body"].format(days=days_missed)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_AI_COACH,
            data={"action": "open_home"},
        )

    async def send_streak_celebration(
        self,
        fcm_token: str,
        streak_days: int,
        user_name: Optional[str] = None,
        user_timezone: Optional[str] = None,
        use_ai: bool = True,
    ) -> bool:
        """Send a streak celebration notification"""
        # Try Gemini personalization first
        if use_ai and user_name:
            time_of_day = self._get_time_of_day(user_timezone)
            ai_result = await self._generate_personalized_message(
                notification_type="streak_celebration",
                user_name=user_name,
                streak=streak_days,
                time_of_day=time_of_day,
            )
            if ai_result:
                title, body = ai_result
                return await self.send_notification(
                    fcm_token=fcm_token,
                    title=title,
                    body=body,
                    notification_type=self.TYPE_STREAK_ALERT,
                    data={"streak": str(streak_days)},
                )

        # Check for milestone first
        if streak_days in self.STREAK_MILESTONE_TEMPLATES:
            template = self.STREAK_MILESTONE_TEMPLATES[streak_days]
        else:
            template = random.choice(self.STREAK_CELEBRATION_TEMPLATES)

        title = template["title"].format(streak=streak_days)
        body = template["body"].format(streak=streak_days)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_STREAK_ALERT,
            data={"streak": str(streak_days)},
        )

    async def send_nutrition_reminder(
        self,
        fcm_token: str,
        meal_type: str = "meal",
    ) -> bool:
        """Send a nutrition logging reminder"""
        # Select pool based on meal type
        meal_lower = meal_type.lower()
        if meal_lower == "breakfast":
            pool = self.NUTRITION_BREAKFAST_TEMPLATES
        elif meal_lower == "lunch":
            pool = self.NUTRITION_LUNCH_TEMPLATES
        elif meal_lower == "dinner":
            pool = self.NUTRITION_DINNER_TEMPLATES
        else:
            pool = self.NUTRITION_GENERIC_TEMPLATES

        template = random.choice(pool)
        title = template["title"]
        body = template["body"]

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_NUTRITION_REMINDER,
            data={"action": "open_nutrition"},
        )

    async def send_hydration_reminder(
        self,
        fcm_token: str,
        current_ml: int = 0,
        goal_ml: int = 2000,
    ) -> bool:
        """Send a hydration reminder"""
        percent = int((current_ml / goal_ml) * 100) if goal_ml > 0 else 0

        # Select tier based on progress percentage
        if percent < 40:
            pool = self.HYDRATION_LOW_TEMPLATES
        elif percent <= 75:
            pool = self.HYDRATION_MEDIUM_TEMPLATES
        else:
            pool = self.HYDRATION_HIGH_TEMPLATES

        template = random.choice(pool)
        title = template["title"].format(percent=percent)
        body = template["body"].format(percent=percent)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_HYDRATION_REMINDER,
            data={"action": "open_hydration"},
        )

    async def send_weekly_summary_ready(
        self,
        fcm_token: str,
        workouts_completed: int = 0,
        user_name: Optional[str] = None,
        user_timezone: Optional[str] = None,
        use_ai: bool = True,
    ) -> bool:
        """Send notification that weekly summary is ready"""
        # Try Gemini personalization first
        if use_ai and user_name:
            time_of_day = self._get_time_of_day(user_timezone)
            ai_result = await self._generate_personalized_message(
                notification_type="weekly_summary",
                user_name=user_name,
                workouts_completed=workouts_completed,
                time_of_day=time_of_day,
            )
            if ai_result:
                title, body = ai_result
                return await self.send_notification(
                    fcm_token=fcm_token,
                    title=title,
                    body=body,
                    notification_type=self.TYPE_WEEKLY_SUMMARY,
                    data={"action": "open_summaries"},
                )

        # Template pool fallback
        template = random.choice(self.WEEKLY_SUMMARY_TEMPLATES)
        s = "s" if workouts_completed != 1 else ""
        title = template["title"].format(count=workouts_completed, s=s)
        body = template["body"].format(count=workouts_completed, s=s)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_WEEKLY_SUMMARY,
            data={"action": "open_summaries"},
        )

    async def send_test_notification(
        self,
        fcm_token: str,
    ) -> bool:
        """Send a test notification"""
        title = "Test Notification 🧪"
        body = "Your AI Coach is ready to help you crush your goals! 💪"

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_TEST,
        )

    # ─────────────────────────────────────────────────────────────────
    # Movement Reminder (NEAT) Methods
    # ─────────────────────────────────────────────────────────────────

    async def send_movement_reminder(
        self,
        fcm_token: str,
        current_steps: int = 0,
        threshold: int = 250,
        template_index: Optional[int] = None,
    ) -> bool:
        """
        Send a movement reminder notification to encourage the user to move.

        Args:
            fcm_token: The device's FCM token
            current_steps: Number of steps taken this hour
            threshold: Step threshold for the hour (default 250)
            template_index: Optional index to use specific template, otherwise random

        Returns:
            True if sent successfully, False otherwise
        """
        # Select a template (random or specified)
        if template_index is not None:
            template_idx = template_index % len(self.MOVEMENT_REMINDER_TEMPLATES)
        else:
            template_idx = random.randint(0, len(self.MOVEMENT_REMINDER_TEMPLATES) - 1)

        template = self.MOVEMENT_REMINDER_TEMPLATES[template_idx]

        # Format the message with step data
        title = template["title"]
        body = template["body"].format(steps=current_steps, threshold=threshold)

        logger.info(f"🚶 [Movement] Sending reminder: {title} - {body}")

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_MOVEMENT_REMINDER,
            data={
                "action": "open_home",
                "current_steps": str(current_steps),
                "threshold": str(threshold),
            },
        )

    async def send_movement_reminder_to_user(
        self,
        user_id: str,
        current_steps: int = 0,
        threshold: int = 250,
    ) -> bool:
        """
        Send a movement reminder to a user by their user_id.

        Looks up the FCM token and sends the reminder.

        Args:
            user_id: The user's ID
            current_steps: Steps taken this hour
            threshold: Step threshold

        Returns:
            True if sent successfully, False otherwise
        """
        from core.supabase_db import get_supabase_db

        try:
            db = get_supabase_db()
            user = db.get_user(user_id)

            if not user:
                logger.warning(f"🚶 [Movement] User not found: {user_id}")
                return False

            fcm_token = user.get("fcm_token")
            if not fcm_token:
                logger.warning(f"🚶 [Movement] No FCM token for user: {user_id}")
                return False

            return await self.send_movement_reminder(
                fcm_token=fcm_token,
                current_steps=current_steps,
                threshold=threshold,
            )

        except Exception as e:
            logger.error(f"❌ [Movement] Error sending reminder to user {user_id}: {e}", exc_info=True)
            return False

    # ─────────────────────────────────────────────────────────────────
    # Live Chat Support Notification Methods
    # ─────────────────────────────────────────────────────────────────

    async def send_live_chat_message_notification(
        self,
        user_id: str,
        agent_name: str,
        message_preview: str,
        ticket_id: str,
    ) -> bool:
        """
        Send a notification when a support agent sends a new message in live chat.

        Args:
            user_id: The user's ID
            agent_name: Name of the support agent
            message_preview: Preview of the message (truncated)
            ticket_id: The support ticket/chat ID

        Returns:
            True if sent successfully, False otherwise
        """
        from core.supabase_db import get_supabase_db

        try:
            db = get_supabase_db()
            user = db.get_user(user_id)

            if not user:
                logger.warning(f"💬 [LiveChat] User not found: {user_id}")
                return False

            fcm_token = user.get("fcm_token")
            if not fcm_token:
                logger.warning(f"💬 [LiveChat] No FCM token for user: {user_id}")
                return False

            # Truncate message preview if too long
            preview = message_preview[:100] + "..." if len(message_preview) > 100 else message_preview

            title = f"New message from {agent_name}"
            body = preview

            return await self.send_notification(
                fcm_token=fcm_token,
                title=title,
                body=body,
                notification_type=self.TYPE_LIVE_CHAT_MESSAGE,
                data={
                    "action": "open_live_chat",
                    "ticket_id": ticket_id,
                    "agent_name": agent_name,
                },
            )

        except Exception as e:
            logger.error(f"❌ [LiveChat] Error sending message notification to user {user_id}: {e}", exc_info=True)
            return False

    async def send_live_chat_connected_notification(
        self,
        user_id: str,
        agent_name: str,
        ticket_id: str,
    ) -> bool:
        """
        Send a notification when a support agent is assigned to the user's chat.

        Args:
            user_id: The user's ID
            agent_name: Name of the support agent
            ticket_id: The support ticket/chat ID

        Returns:
            True if sent successfully, False otherwise
        """
        from core.supabase_db import get_supabase_db

        try:
            db = get_supabase_db()
            user = db.get_user(user_id)

            if not user:
                logger.warning(f"💬 [LiveChat] User not found: {user_id}")
                return False

            fcm_token = user.get("fcm_token")
            if not fcm_token:
                logger.warning(f"💬 [LiveChat] No FCM token for user: {user_id}")
                return False

            title = "Support agent connected!"
            body = f"{agent_name} has joined your chat and is ready to help."

            return await self.send_notification(
                fcm_token=fcm_token,
                title=title,
                body=body,
                notification_type=self.TYPE_LIVE_CHAT_CONNECTED,
                data={
                    "action": "open_live_chat",
                    "ticket_id": ticket_id,
                    "agent_name": agent_name,
                },
            )

        except Exception as e:
            logger.error(f"❌ [LiveChat] Error sending connected notification to user {user_id}: {e}", exc_info=True)
            return False

    async def send_live_chat_ended_notification(
        self,
        user_id: str,
        resolution_note: str,
        ticket_id: str,
    ) -> bool:
        """
        Send a notification when a support agent ends the chat session.

        Args:
            user_id: The user's ID
            resolution_note: Note about how the issue was resolved
            ticket_id: The support ticket/chat ID

        Returns:
            True if sent successfully, False otherwise
        """
        from core.supabase_db import get_supabase_db

        try:
            db = get_supabase_db()
            user = db.get_user(user_id)

            if not user:
                logger.warning(f"💬 [LiveChat] User not found: {user_id}")
                return False

            fcm_token = user.get("fcm_token")
            if not fcm_token:
                logger.warning(f"💬 [LiveChat] No FCM token for user: {user_id}")
                return False

            title = "Chat session ended"
            # Truncate resolution note if too long
            note_preview = resolution_note[:100] + "..." if len(resolution_note) > 100 else resolution_note
            body = f"Your support chat has been resolved. {note_preview}"

            return await self.send_notification(
                fcm_token=fcm_token,
                title=title,
                body=body,
                notification_type=self.TYPE_LIVE_CHAT_ENDED,
                data={
                    "action": "open_live_chat",
                    "ticket_id": ticket_id,
                    "chat_ended": "true",
                },
            )

        except Exception as e:
            logger.error(f"❌ [LiveChat] Error sending ended notification to user {user_id}: {e}", exc_info=True)
            return False


