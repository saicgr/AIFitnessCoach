"""
Email lifecycle mixin: cancellation retention, trial, streak, activation emails.

Extracted from email_service.py to keep files under 1000 lines.
These methods are mixed into EmailService via multiple inheritance.
"""
import resend
from typing import List, Dict, Any

from core.logger import get_logger

logger = get_logger(__name__)


class EmailLifecycleMixin:
    """Mixin providing lifecycle email methods for EmailService.

    Expects self.from_email, self.is_configured(), and self._build_standard_email() to exist.
    """

    async def send_cancellation_retention(
        self, to_email: str, user_name: str, tier: str,
        workouts_completed: int, total_volume_kg: float, current_streak: int,
    ) -> Dict[str, Any]:
        """Send a cancellation retention email to a user who just cancelled."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Before you go, {display_name}",
            subtitle=f"You've completed {workouts_completed} workouts with FitWiz. That's real progress. We'd love to keep helping you reach your goals.",
            cta_text="Keep My Premium",
            features=[
                ("&#127947;", "Your workout history stays", f"All {workouts_completed} logged workouts and your progress data are safe even on the free plan."),
                ("&#129303;", "AI Coach goes to basics", "Free plan limits your daily AI coach messages. Premium gives unlimited access."),
                ("&#128200;", "Progress tracking limited", "Advanced analytics, strength curves, and body composition charts require Premium."),
            ],
            footer_text="You received this because you cancelled your FitWiz subscription.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"We're sorry to see you go, {display_name} -- here's an offer before you leave", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Cancellation retention email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send cancellation retention email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_trial_expired(
        self, to_email: str, user_name: str, workouts_completed: int,
    ) -> Dict[str, Any]:
        """Send an email notifying the user that their free trial has expired."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"
        workout_word = "workouts" if workouts_completed != 1 else "workout"

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Trial over. Your gains aren't, {display_name}.",
            subtitle=f"You completed {workouts_completed} {workout_word} during your trial. Don't let that momentum stop now.",
            cta_text="Subscribe Now",
            features=[
                ("&#127947;", "Pick up where you left off", "Your workout plans, history, and AI coach settings are all still there."),
                ("&#129303;", "Keep your AI coach", "Unlimited personalised workouts and coaching -- gone on the free plan."),
                ("&#9889;", "Special offer inside", "Subscribe today and get your first month at the standard price with no lock-in."),
            ],
            footer_text="You received this because your FitWiz trial ended.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"Your trial just ended -- but it's not too late, {display_name}", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Trial expired email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send trial expired email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_trial_ending(
        self, to_email: str, user_name: str, days_remaining: int,
        tier: str, workouts_during_trial: int, trial_end_date: str,
        discount_percent: int = 25,
    ) -> Dict[str, Any]:
        """Send a trial ending soon reminder email with discount offer."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"
        days_word = "days" if days_remaining != 1 else "day"

        discount_price = f"${49.99 * (1 - discount_percent / 100):.2f}"
        discount_text = f"Subscribe now and save {discount_percent}% -- just {discount_price}/year."

        features = [
            ("&#9200;", "Trial expires soon", f"After {trial_end_date}, you'll lose access to AI workouts, coaching, and all premium features."),
            ("&#127947;", f"{workouts_during_trial} workouts logged", "All your progress is saved. Subscribe to keep generating new AI plans and coaching."),
            ("&#127873;", f"Special offer: {discount_percent}% off", f"{discount_text} That's less than $0.11/day for a full AI fitness coach."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"{days_remaining} {days_word} left, {display_name}",
            subtitle=f"Your trial ends on {trial_end_date}. You've done {workouts_during_trial} workouts -- don't lose your momentum.",
            cta_text=f"Subscribe Now -- {discount_percent}% Off",
            features=features,
            footer_text="You received this because your FitWiz trial is ending soon.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"Your free trial ends in {days_remaining} {days_word} -- save {discount_percent}% today", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Trial ending email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send trial ending email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_streak_at_risk(
        self, to_email: str, user_name: str,
        current_streak: int, next_workout_name: str,
    ) -> Dict[str, Any]:
        """Send a streak-at-risk nudge email when a user hasn't logged a workout in 3 days."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Don't break your {current_streak}-day streak, {display_name}",
            subtitle="You haven't logged a workout in 3 days. One quick session today resets the clock and keeps your momentum alive.",
            cta_text="Log a Workout Now",
            features=[
                ("&#128293;", f"{current_streak} days strong", "Streaks are the single best predictor of long-term fitness results. Protect this one."),
                ("&#127947;", f"Next up: {next_workout_name}", "Your next workout is already built and waiting. Just tap Start."),
                ("&#9201;", "20 minutes is enough", "Even a shorter session counts. Getting started is the hardest part."),
            ],
            footer_text="You received this because you have streak notifications enabled.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"{display_name}, your {current_streak}-day streak is about to break -- 20 min is all it takes", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Streak at risk email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send streak at risk email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_day3_activation(
        self, to_email: str, user_name: str, workout_name: str,
        exercises: List[str], goal: str,
    ) -> Dict[str, Any]:
        """Send a day-3 activation nudge for users who signed up but haven't started working out."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"
        exercises_preview = ", ".join(exercises[:3]) + ("..." if len(exercises) > 3 else "")

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Your plan is ready, {display_name}",
            subtitle=f"You signed up 3 days ago but haven't started yet. Your AI coach already built a {goal} workout plan for you. It takes 20 minutes.",
            cta_text="Start My First Workout",
            features=[
                ("&#129303;", "AI-generated just for you", f"Your first workout -- {workout_name} -- is tailored to your goals and equipment."),
                ("&#127947;", f"First session: {exercises_preview}", "All exercises come with video demos and form tips from your AI coach."),
                ("&#128241;", "Open the app, tap Start", "Your plan is on the home screen. No setup needed -- it's ready to go."),
            ],
            footer_text="You received this because you haven't started your first workout yet.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"{display_name}, your first workout is already built -- just tap Start", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Day-3 activation email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send day-3 activation email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_onboarding_incomplete(
        self, to_email: str, user_name: str,
    ) -> Dict[str, Any]:
        """Send a nudge email to users who started but did not finish onboarding."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"You're almost there, {display_name}",
            subtitle="You started setting up FitWiz but didn't finish. Your AI coach needs just a couple more answers to build your personalised plan.",
            cta_text="Finish Setup",
            features=[
                ("&#127919;", "2 minutes to complete", "Tell us your goals, training days, and equipment. That's all your AI coach needs."),
                ("&#129303;", "Your plan generates instantly", "Once you finish setup, FitWiz builds your full monthly workout plan in seconds."),
                ("&#127947;", "Built around your life", "Your schedule, home or gym, beginner or advanced -- every detail is personalised."),
            ],
            footer_text="You received this because your FitWiz setup is incomplete.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"{display_name}, your AI coach is waiting -- 2 minutes to finish setup", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Onboarding incomplete email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send onboarding incomplete email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}
