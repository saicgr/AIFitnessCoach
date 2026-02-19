"""
Push Notification Service using Firebase Admin SDK
Sends push notifications to users via Firebase Cloud Messaging (FCM)
"""

import os
import json
import logging
import random
from typing import Optional, Dict, Any, List, Tuple
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

    # ─────────────────────────────────────────────────────────────────
    # Phase 1: Template Pools
    # ─────────────────────────────────────────────────────────────────

    # 1a. Workout reminder templates with {name} and {workout_name} placeholders
    WORKOUT_REMINDER_TEMPLATES = [
        {"title": "Hey {name}, your {workout_name} is ready!", "body": "Your body is primed and waiting. Let's make today count."},
        {"title": "Today's plan: {workout_name}", "body": "Everything's set, {name}. Just press play."},
        {"title": "{name}, ready to train?", "body": "One session closer to your goals."},
        {"title": "Time to move, {name}!", "body": "Your {workout_name} won't do itself. Let's go!"},
        {"title": "{workout_name} awaits!", "body": "Show up today and your future self will thank you."},
        {"title": "Let's get after it, {name}!", "body": "Your {workout_name} is loaded and ready to roll."},
        {"title": "Training time!", "body": "{name}, your {workout_name} is calling. Answer with action."},
        {"title": "Your workout is set!", "body": "{workout_name} is ready. Lace up and let's do this, {name}."},
        {"title": "Ready when you are, {name}!", "body": "Today's {workout_name} is waiting. Let's build something great."},
        {"title": "Rise and grind!", "body": "{name}, your {workout_name} is prepped. Time to earn it."},
    ]

    # 1b. Inactivity nudge templates - 3 tiers, positive/progress-affirming (NO guilt/shame)
    INACTIVITY_NUDGE_1DAY = [
        {"title": "Pick up where you left off!", "body": "Your next workout is ready whenever you are."},
        {"title": "Quick check-in!", "body": "Yesterday was rest -- today's a fresh start."},
        {"title": "One day off, no worries!", "body": "Consistency is about the long game. Ready to jump back in?"},
        {"title": "Your workout is waiting!", "body": "A single session can set the tone for the whole week."},
    ]
    INACTIVITY_NUDGE_2DAY = [
        {"title": "Two days off -- feeling rested?", "body": "Sometimes rest is progress. Ready to move again?"},
        {"title": "Recharged and ready?", "body": "Two rest days in the bank. Time to spend that energy!"},
        {"title": "Your body's had a break!", "body": "A quick session today can feel amazing after some rest."},
        {"title": "Fresh start today?", "body": "Two days off means your muscles are recovered. Let's use that."},
    ]
    INACTIVITY_NUDGE_3PLUS_DAY = [
        {"title": "Welcome back anytime!", "body": "It's been {days} days. No pressure -- just pick one exercise to start."},
        {"title": "We saved your spot!", "body": "{days} days away, but your plan is still here. Start small."},
        {"title": "Every comeback starts with one rep!", "body": "It's been {days} days. A 10-minute session is all it takes."},
        {"title": "No judgment, just progress!", "body": "{days} days off? That's okay. Today is a great day to start fresh."},
    ]

    # 1c. Streak celebration templates with {streak} placeholder
    STREAK_CELEBRATION_TEMPLATES = [
        {"title": "{streak}-day streak!", "body": "You've shown up {streak} days in a row. That's real dedication."},
        {"title": "Streak: {streak} days!", "body": "Consistency is your superpower. Keep it rolling!"},
        {"title": "{streak} days strong!", "body": "Every day you show up, you're building a better you."},
        {"title": "On fire: {streak} days!", "body": "This streak is proof that discipline beats motivation."},
        {"title": "{streak} and counting!", "body": "You're not stopping anytime soon. Incredible work!"},
        {"title": "Day {streak} -- unstoppable!", "body": "Most people quit by now. You didn't. Respect."},
        {"title": "Still going: {streak} days!", "body": "Your future self is cheering right now."},
        {"title": "{streak}-day champion!", "body": "This is what commitment looks like. Keep going!"},
    ]
    # Special milestone messages
    STREAK_MILESTONE_TEMPLATES = {
        7: {"title": "1 Week Streak!", "body": "7 days strong! You've built a real habit. This is just the beginning."},
        14: {"title": "2 Week Streak!", "body": "14 days of consistency. You're officially in a groove!"},
        30: {"title": "30-Day Streak!", "body": "A full month! You've proven this isn't a phase -- it's a lifestyle."},
        50: {"title": "50 Days!", "body": "Half a hundred days of dedication. You're in elite company now."},
        100: {"title": "100-Day Streak!", "body": "Triple digits! This is extraordinary discipline. Be proud."},
        365: {"title": "365-Day Streak!", "body": "ONE FULL YEAR. You are a legend. Absolutely incredible."},
    }

    # 1d. Nutrition reminder templates per meal type
    NUTRITION_BREAKFAST_TEMPLATES = [
        {"title": "Good morning! Log your breakfast", "body": "Start your day right -- track what fuels your morning."},
        {"title": "Breakfast time!", "body": "Snap a pic or log your meal to stay on track."},
        {"title": "Fuel up!", "body": "A logged breakfast sets the tone for the whole day."},
        {"title": "Morning fuel check!", "body": "What's on the plate? Log your breakfast to keep your streak."},
        {"title": "Rise and eat!", "body": "Track your breakfast and start the day with intention."},
        {"title": "Breakfast check-in!", "body": "Log your morning meal -- it takes 10 seconds."},
        {"title": "Don't skip tracking!", "body": "Your breakfast matters. Log it to see your full picture."},
        {"title": "Morning nutrition!", "body": "Quick -- log what you're eating before the day gets busy."},
    ]
    NUTRITION_LUNCH_TEMPLATES = [
        {"title": "Lunchtime! Log your meal", "body": "Midday fuel matters. Keep your nutrition on point."},
        {"title": "Lunch check-in!", "body": "What are you having? Log it in under 10 seconds."},
        {"title": "Midday fuel!", "body": "Track your lunch to keep your nutrition goals on track."},
        {"title": "Time to log lunch!", "body": "A quick snap or log keeps your day on track."},
        {"title": "Lunch break = log break!", "body": "Take a sec to track what you're eating."},
        {"title": "Halfway through the day!", "body": "Log your lunch to see how your macros are looking."},
        {"title": "Fuel check!", "body": "Lunchtime logging keeps you aware and in control."},
        {"title": "What's for lunch?", "body": "Log it now so you don't forget later!"},
    ]
    NUTRITION_DINNER_TEMPLATES = [
        {"title": "Dinner time! Log your meal", "body": "End your day strong -- track your evening nutrition."},
        {"title": "Evening fuel!", "body": "Log your dinner to complete today's nutrition picture."},
        {"title": "Last meal of the day!", "body": "Track your dinner and see how you did today."},
        {"title": "Dinner check-in!", "body": "What's on the plate tonight? Log it to stay on track."},
        {"title": "Wrap up your nutrition!", "body": "Log dinner and you'll have a full day of tracking."},
        {"title": "Time to log dinner!", "body": "A quick entry completes your daily nutrition log."},
        {"title": "Evening nutrition check!", "body": "Track your dinner -- your tomorrow self will appreciate it."},
        {"title": "Finish strong!", "body": "Log your dinner to close out today's nutrition."},
    ]
    NUTRITION_GENERIC_TEMPLATES = [
        {"title": "Time to log your meal!", "body": "Tracking your food takes 10 seconds and pays off big."},
        {"title": "Meal check-in!", "body": "Snap a photo or log what you're eating to stay on target."},
        {"title": "Fuel your progress!", "body": "Log your meal to keep your nutrition goals on track."},
        {"title": "Track your nutrition!", "body": "Quick -- log what you're eating before you forget."},
        {"title": "Nutrition reminder!", "body": "Every meal logged is a step closer to your goals."},
        {"title": "Don't forget to log!", "body": "A few taps now means better insights later."},
        {"title": "Food tracking time!", "body": "Stay consistent with your logging. You're doing great!"},
        {"title": "Log your meal!", "body": "Keeping track of nutrition is half the battle. You've got this."},
    ]

    # 1e. Hydration reminder templates - 3 tiers based on progress
    # Low tier: <40% of goal
    HYDRATION_LOW_TEMPLATES = [
        {"title": "Time to hydrate!", "body": "You're at {percent}% of your water goal. Your body needs fuel!"},
        {"title": "Water check!", "body": "Only {percent}% of your hydration goal so far. Grab a glass!"},
        {"title": "Stay hydrated!", "body": "You're at {percent}%. A few glasses can make a big difference."},
        {"title": "Drink up!", "body": "{percent}% of your water goal. Even a small sip counts!"},
        {"title": "Hydration alert!", "body": "You're behind at {percent}%. Time to catch up on water."},
        {"title": "Your body needs water!", "body": "At {percent}% of your goal. Pour yourself a tall glass!"},
    ]
    # Medium tier: 40-75% of goal
    HYDRATION_MEDIUM_TEMPLATES = [
        {"title": "Solid progress!", "body": "You're at {percent}% of your water goal. Keep sipping!"},
        {"title": "Halfway there!", "body": "{percent}% of your hydration goal reached. Keep it up!"},
        {"title": "Good hydration!", "body": "You're at {percent}%. A few more glasses to hit your target."},
        {"title": "Keep drinking!", "body": "{percent}% done. You're on pace -- don't slow down now!"},
    ]
    # High tier: >75% of goal
    HYDRATION_HIGH_TEMPLATES = [
        {"title": "Almost there!", "body": "You're at {percent}% of your water goal. The finish line is close!"},
        {"title": "So close!", "body": "{percent}% hydrated. Just a little more to hit your goal!"},
        {"title": "Final stretch!", "body": "You're at {percent}%. One or two more glasses and you're done!"},
        {"title": "Crushing it!", "body": "{percent}% of your water goal. You're almost at 100%!"},
    ]

    # 1f. Weekly summary templates with {count} placeholder
    WEEKLY_SUMMARY_TEMPLATES = [
        {"title": "Your weekly report is ready!", "body": "You completed {count} workout{s} this week. Check your progress!"},
        {"title": "Week in review!", "body": "{count} workout{s} done this week. See how you stacked up!"},
        {"title": "Weekly recap is here!", "body": "{count} session{s} this week. Tap to see your full breakdown."},
        {"title": "Your progress this week!", "body": "{count} workout{s} completed. Let's see the numbers!"},
        {"title": "Weekly summary ready!", "body": "This week: {count} workout{s}. Your report has all the details."},
        {"title": "How'd your week go?", "body": "{count} training session{s} logged. Check your trends and stats!"},
        {"title": "Time for your weekly review!", "body": "{count} workout{s} in the books. See your progress report."},
        {"title": "Week complete!", "body": "You trained {count} time{s} this week. Your summary awaits!"},
    ]

    # Default channel
    DEFAULT_CHANNEL_ID = "fitwiz_notifications"

    def __init__(self):
        """Initialize the notification service"""
        initialize_firebase()

    def _get_channel_id(self, notification_type: str) -> str:
        """Get the Android notification channel ID for a notification type"""
        return self.CHANNEL_IDS.get(notification_type, self.DEFAULT_CHANNEL_ID)

    @staticmethod
    def _get_time_of_day(user_timezone: Optional[str] = None) -> str:
        """Get the time of day based on user's timezone.

        Returns: 'morning' (5-12), 'afternoon' (12-17), 'evening' (17-21), 'night' (21-5)
        """
        try:
            if user_timezone:
                import pytz
                tz = pytz.timezone(user_timezone)
                hour = datetime.now(tz).hour
            else:
                hour = datetime.utcnow().hour
        except Exception:
            hour = datetime.utcnow().hour

        if 5 <= hour < 12:
            return "morning"
        elif 12 <= hour < 17:
            return "afternoon"
        elif 17 <= hour < 21:
            return "evening"
        else:
            return "night"

    # ─────────────────────────────────────────────────────────────────
    # Phase 3: Gemini-Powered Personalization
    # ─────────────────────────────────────────────────────────────────

    async def _generate_personalized_message(
        self,
        notification_type: str,
        user_name: Optional[str] = None,
        streak: Optional[int] = None,
        workout_name: Optional[str] = None,
        time_of_day: Optional[str] = None,
        days_missed: Optional[int] = None,
        workouts_completed: Optional[int] = None,
    ) -> Optional[Tuple[str, str]]:
        """Generate a personalized notification message using Gemini.

        Returns (title, body) tuple, or None on any failure (falls back to template).
        """
        try:
            from google import genai
            from core.gemini_client import get_genai_client
            from core.config import get_settings

            settings = get_settings()
            client = get_genai_client()

            # Build context string
            context_parts = []
            if user_name:
                context_parts.append(f"User name: {user_name}")
            if streak is not None:
                context_parts.append(f"Current streak: {streak} days")
            if workout_name:
                context_parts.append(f"Workout: {workout_name}")
            if time_of_day:
                context_parts.append(f"Time of day: {time_of_day}")
            if days_missed is not None:
                context_parts.append(f"Days since last workout: {days_missed}")
            if workouts_completed is not None:
                context_parts.append(f"Workouts completed this week: {workouts_completed}")

            context_str = ". ".join(context_parts)

            prompt = (
                "You are a fitness app notification writer. Write a single push notification "
                f"for type: {notification_type}. Context: {context_str}. "
                "Be motivating, concise, and positive. No guilt or shame. No emojis. "
                "Reply ONLY in this exact format on two lines:\n"
                "TITLE: <title text>\n"
                "BODY: <body text>"
            )

            response = client.models.generate_content(
                model=settings.gemini_model,
                contents=prompt,
                config=genai.types.GenerateContentConfig(
                    max_output_tokens=60,
                    temperature=0.9,
                ),
            )

            text = response.text.strip()
            lines = text.split("\n")

            title = None
            body = None
            for line in lines:
                line = line.strip()
                if line.upper().startswith("TITLE:"):
                    title = line[6:].strip()
                elif line.upper().startswith("BODY:"):
                    body = line[5:].strip()

            if title and body:
                logger.info(f"🤖 [Notification] Gemini personalized: {title}")
                return (title, body)

            logger.warning(f"🤖 [Notification] Gemini response unparseable: {text[:100]}")
            return None

        except Exception as e:
            logger.warning(f"🤖 [Notification] Gemini personalization failed: {e}")
            return None

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
