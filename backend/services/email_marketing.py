"""
Email marketing mixin: win-back, upsell, and weekly summary emails.

Extracted from email_service.py to keep files under 1000 lines.
These methods are mixed into EmailService via multiple inheritance.
"""
import resend
from typing import List, Dict, Any

from core.logger import get_logger

logger = get_logger(__name__)


class EmailMarketingMixin:
    """Mixin providing marketing email methods for EmailService.

    Expects self.from_email, self.is_configured(), and self._build_standard_email() to exist.
    """

    async def send_win_back(
        self, to_email: str, user_name: str, days_since_expiry: int,
        workouts_completed: int, discount_percent: int = 25,
    ) -> Dict[str, Any]:
        """Send a win-back email to lapsed Premium users with a discount offer."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"We've been saving your spot, {display_name}",
            subtitle=f"It's been {days_since_expiry} days since your Premium expired. Your {workouts_completed} logged workouts are still here. Come back and get {discount_percent}% off.",
            cta_text=f"Get {discount_percent}% Off",
            features=[
                ("&#127947;", f"{workouts_completed} workouts logged", "All your history, personal records, and progress data are intact."),
                ("&#129303;", "Your AI coach remembers you", "It knows your preferences, injuries, and goals. No re-setup required."),
                ("&#9889;", f"{discount_percent}% off for returning members", f"Subscribe now and save {discount_percent}% on your first month back. Limited time."),
            ],
            footer_text="You received this because you were a FitWiz Premium member.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"{display_name}, your {workouts_completed} workouts are still here -- come back for {discount_percent}% off", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Win-back email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send win-back email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_14day_upsell(
        self, to_email: str, user_name: str, workouts_completed: int,
        free_workouts_remaining: int,
    ) -> Dict[str, Any]:
        """Send a 14-day upsell email to free users who are active but hitting limits."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"You're on a roll, {display_name}",
            subtitle=f"You've done {workouts_completed} workouts on the free plan. You have {free_workouts_remaining} free AI workouts left this month. Upgrade to keep your momentum.",
            cta_text="Go Premium",
            features=[
                ("&#127947;", f"{workouts_completed} workouts and counting", "You're building a habit. Premium ensures you never hit a limit."),
                ("&#129303;", "Unlimited AI coach", "Free plan caps your daily messages. Premium gives you unlimited access to your AI coach."),
                ("&#128200;", "Unlock full analytics", "See your strength curves, body composition trends, and detailed performance metrics."),
            ],
            footer_text="You received this because you've been active on the FitWiz free plan.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"{display_name}, you've done {workouts_completed} workouts -- here's what Premium unlocks", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"14-day upsell email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send 14-day upsell email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_weekly_summary(
        self, to_email: str, user_name: str,
        workouts_this_week: int, total_volume_kg: float,
        total_duration_minutes: int, streak_days: int,
        top_exercise: str, top_exercise_volume: float,
    ) -> Dict[str, Any]:
        """Send a weekly performance summary email."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        hours = total_duration_minutes // 60
        mins = total_duration_minutes % 60
        duration_str = f"{hours}h {mins}m" if hours > 0 else f"{mins}m"

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Your week in review, {display_name}",
            subtitle=f"{workouts_this_week} workouts, {total_volume_kg:,.0f} kg lifted, {duration_str} of training. Here's your full breakdown.",
            cta_text="See Full Stats",
            features=[
                ("&#127947;", f"{workouts_this_week} workouts completed", f"Total training time: {duration_str}. Total volume: {total_volume_kg:,.0f} kg."),
                ("&#128293;", f"{streak_days}-day streak", "Consistency is the key to progress. Keep showing up."),
                ("&#128170;", f"Top exercise: {top_exercise}", f"Your strongest lift this week with {top_exercise_volume:,.0f} kg total volume."),
            ],
            footer_text="You received this because you have weekly summary emails enabled.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"Your week: {workouts_this_week} workouts, {total_volume_kg:,.0f} kg lifted", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Weekly summary email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send weekly summary email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}
