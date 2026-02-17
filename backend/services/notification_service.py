"""
Push Notification Service using Firebase Admin SDK
Sends push notifications to users via Firebase Cloud Messaging (FCM)
"""

import os
import json
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime

logger = logging.getLogger(__name__)

# Global Firebase app instance
_firebase_app = None


def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    import firebase_admin
    from firebase_admin import credentials

    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    try:
        # Check for credentials file path
        cred_path = os.environ.get('FIREBASE_CREDENTIALS_PATH')

        if cred_path and os.path.exists(cred_path):
            # Use credentials file
            cred = credentials.Certificate(cred_path)
            _firebase_app = firebase_admin.initialize_app(cred)
            logger.info("✅ Firebase initialized with credentials file")
        else:
            # Try to use credentials from environment variable (JSON string)
            cred_json = os.environ.get('FIREBASE_CREDENTIALS_JSON')
            if cred_json:
                cred_dict = json.loads(cred_json)
                cred = credentials.Certificate(cred_dict)
                _firebase_app = firebase_admin.initialize_app(cred)
                logger.info("✅ Firebase initialized with credentials from environment")
            else:
                # Use default credentials (for GCP environments)
                _firebase_app = firebase_admin.initialize_app()
                logger.info("✅ Firebase initialized with default credentials")

        return _firebase_app
    except Exception as e:
        logger.error(f"❌ Failed to initialize Firebase: {e}")
        raise


class NotificationService:
    """Service for sending push notifications via FCM"""

    # Notification types
    TYPE_WORKOUT_REMINDER = "workout_reminder"
    TYPE_NUTRITION_REMINDER = "nutrition_reminder"
    TYPE_HYDRATION_REMINDER = "hydration_reminder"
    TYPE_AI_COACH = "ai_coach"
    TYPE_STREAK_ALERT = "streak_alert"
    TYPE_WEEKLY_SUMMARY = "weekly_summary"
    TYPE_BILLING_REMINDER = "billing_reminder"
    TYPE_MOVEMENT_REMINDER = "movement_reminder"
    TYPE_LIVE_CHAT_MESSAGE = "live_chat_message"
    TYPE_LIVE_CHAT_CONNECTED = "live_chat_connected"
    TYPE_LIVE_CHAT_ENDED = "live_chat_ended"
    TYPE_TEST = "test"

    # Android notification channel IDs (must match Flutter side)
    CHANNEL_IDS = {
        TYPE_WORKOUT_REMINDER: "workout_coach",
        TYPE_NUTRITION_REMINDER: "nutrition_coach",
        TYPE_HYDRATION_REMINDER: "hydration_coach",
        TYPE_STREAK_ALERT: "streak_coach",
        TYPE_WEEKLY_SUMMARY: "progress_coach",
        TYPE_AI_COACH: "ai_coach",
        TYPE_BILLING_REMINDER: "billing_coach",
        TYPE_MOVEMENT_REMINDER: "movement_coach",
        TYPE_LIVE_CHAT_MESSAGE: "live_chat",
        TYPE_LIVE_CHAT_CONNECTED: "live_chat",
        TYPE_LIVE_CHAT_ENDED: "live_chat",
        TYPE_TEST: "test_notifications",
    }

    # Movement reminder message templates (variety to avoid notification fatigue)
    MOVEMENT_REMINDER_TEMPLATES = [
        {
            "title": "Time to move!",
            "body": "You've only taken {steps} steps this hour. A short walk can boost your energy!",
        },
        {
            "title": "Stand up and stretch!",
            "body": "Your body will thank you. Take 2 minutes to move around!",
        },
        {
            "title": "Quick walk?",
            "body": "Just {steps} steps this hour. A quick walk improves circulation and focus.",
        },
        {
            "title": "Get moving!",
            "body": "Reduce sedentary time - every step counts! You're at {steps}/{threshold} steps.",
        },
        {
            "title": "Movement check!",
            "body": "Time to shake off the stiffness. Stand up and take a quick walk!",
        },
        {
            "title": "Desk break time!",
            "body": "Walking improves your mood and productivity. You've taken {steps} steps this hour.",
        },
        {
            "title": "Walk break!",
            "body": "Get up and get those steps in! Small movements add up over time.",
        },
        {
            "title": "Stretch it out!",
            "body": "Only {steps} steps so far. Stand up and move around for a few minutes!",
        },
    ]

    # Default channel
    DEFAULT_CHANNEL_ID = "fitwiz_notifications"

    def __init__(self):
        """Initialize the notification service"""
        initialize_firebase()

    def _get_channel_id(self, notification_type: str) -> str:
        """Get the Android notification channel ID for a notification type"""
        return self.CHANNEL_IDS.get(notification_type, self.DEFAULT_CHANNEL_ID)

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
            logger.warning(f"⚠️ FCM token is no longer valid: {fcm_token[:20]}...")
            return False
        except messaging.SenderIdMismatchError:
            logger.error(f"❌ Sender ID mismatch - FCM token belongs to different Firebase project")
            return False
        except messaging.InvalidArgumentError as e:
            logger.error(f"❌ Invalid argument error: {e}")
            return False
        except Exception as e:
            logger.error(f"❌ Failed to send notification: {type(e).__name__}: {e}")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
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
            logger.error(f"❌ Failed to send multicast notification: {e}")
            return {"success_count": 0, "failure_count": len(fcm_tokens)}

    # ─────────────────────────────────────────────────────────────────
    # Pre-built notification messages (Duolingo-style)
    # ─────────────────────────────────────────────────────────────────

    async def send_workout_reminder(
        self,
        fcm_token: str,
        workout_name: str = "today's workout",
        user_name: Optional[str] = None,
    ) -> bool:
        """Send a workout reminder notification"""
        greeting = f"Hey {user_name}! " if user_name else ""
        title = f"{greeting}Time to train! 💪"
        body = f"Your {workout_name} is ready and waiting. Let's crush it!"

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
    ) -> bool:
        """Send a guilt notification for missed workouts"""
        if days_missed == 1:
            title = "Your muscles miss you! 💪"
            body = "It's been a day since your last workout. Don't break your streak!"
        elif days_missed == 2:
            title = "Your AI Coach is getting lonely... 🥺"
            body = "2 days without training. Let's get back on track!"
        else:
            title = f"It's been {days_missed} days! 😱"
            body = "Your fitness journey is calling. Time to answer!"

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
    ) -> bool:
        """Send a streak celebration notification"""
        title = f"🔥 {streak_days}-day streak!"
        body = f"You've worked out {streak_days} days in a row! Keep the fire burning!"

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
        title = f"Time to log your {meal_type}! 📸"
        body = "Snap a photo to track your nutrition and stay on target."

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

        if percent < 50:
            title = "Stay hydrated! 💧"
            body = f"You're at {percent}% of your water goal. Drink up!"
        else:
            title = "Keep it up! 💧"
            body = f"You're at {percent}% of your water goal. Almost there!"

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
    ) -> bool:
        """Send notification that weekly summary is ready"""
        title = "Your weekly report is ready! 📊"
        body = f"You completed {workouts_completed} workout{'s' if workouts_completed != 1 else ''} this week. Check your progress!"

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
        import random

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
            logger.error(f"❌ [Movement] Error sending reminder to user {user_id}: {e}")
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
            logger.error(f"❌ [LiveChat] Error sending message notification to user {user_id}: {e}")
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
            logger.error(f"❌ [LiveChat] Error sending connected notification to user {user_id}: {e}")
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
            logger.error(f"❌ [LiveChat] Error sending ended notification to user {user_id}: {e}")
            return False


# Singleton instance
_notification_service: Optional[NotificationService] = None


def get_notification_service() -> NotificationService:
    """Get or create the notification service singleton"""
    global _notification_service
    if _notification_service is None:
        _notification_service = NotificationService()
    return _notification_service
