"""
Push Notification Service using Firebase Admin SDK
Sends push notifications to users via Firebase Cloud Messaging (FCM)
"""

import os
import json
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, messaging

logger = logging.getLogger(__name__)

# Global Firebase app instance
_firebase_app = None


def initialize_firebase():
    """Initialize Firebase Admin SDK"""
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
    TYPE_TEST = "test"

    def __init__(self):
        """Initialize the notification service"""
        initialize_firebase()

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

            # Build Android-specific config
            android_config = messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#00D9FF",  # Cyan color
                    sound="default",
                    channel_id="ai_fitness_coach_notifications",
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

            android_config = messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#00D9FF",
                    sound="default",
                    channel_id="ai_fitness_coach_notifications",
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


# Singleton instance
_notification_service: Optional[NotificationService] = None


def get_notification_service() -> NotificationService:
    """Get or create the notification service singleton"""
    global _notification_service
    if _notification_service is None:
        _notification_service = NotificationService()
    return _notification_service
