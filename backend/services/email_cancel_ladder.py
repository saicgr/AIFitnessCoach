"""
Post-cancel re-engagement ladder (C1-C7).

Fills the gap where the old system went silent for 30 days after a user
cancelled. Now each stage references the user's actual completed workouts
and stats history as a reason to come back.

All methods take `first_name_value` + `UserStats`. The first two (grace,
access-expired) are transactional in tone (FitWiz voice opens) and the
offers (C3-C6) + sunset (C7) use the persona voice for warmth.

Stages:
- C1 Grace Period          — T+1d post-cancel, access still active
- C2 Access Expired        — at subscription expiry
- C3 Post-cancel +7d       — first soft discount (10%)
- C4 Post-cancel +14d      — mid discount (20%)
- C6 Post-cancel +60d      — strongest discount (30%)
- C7 Post-cancel +90d      — sunset, one-click re-opt-in
"""
import resend
from typing import Dict, Any, Optional

from core.logger import get_logger
from models.email import UserStats
from services.email_helpers import (
    build_persona_signature_html,
    build_stats_grid_html,
)

logger = get_logger(__name__)


class EmailCancelLadderMixin:
    """Post-cancel ladder emails mixed into EmailService."""

    async def send_grace_period(
        self, to_email: str, first_name_value: str, stats: UserStats,
        days_until_expiry: int,
    ) -> Dict[str, Any]:
        """C1. Day after cancel, while access still active. Hybrid voice.

        Opens with FitWiz framing on the billing fact, closes with persona
        voice asking what went wrong. Includes a "tell us what didn't click"
        soft-feedback link as an alternative to the subscribe CTA.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name
        workouts = stats.workouts_total

        subject = f"{days_until_expiry} days of FitWiz left, {name}. What happened?"
        title = f"{days_until_expiry} days left, {name}"
        subtitle = (
            f"You cancelled FitWiz yesterday. You've got {days_until_expiry} days of access "
            f"before it winds down. {coach} is wondering what stopped working."
        )

        features = [
            ("&#128172;", "Tell us what didn't click",
             "Two-minute feedback form. Even if you're gone for good, it helps the next person."),
            ("&#127947;", f"{workouts} workouts still on file",
             "Resubscribe anytime within the grace period and pick up exactly where you left off."),
            ("&#129303;", f"{coach} is still here",
             "No re-onboarding. No lost settings. Same plan, same history."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Reactivate",
            features=features,
            footer_text="You received this because you cancelled your FitWiz subscription.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats) if stats.has_any_activity else "",
            category_name="offers",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"C1 grace period email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send grace period email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_access_expired(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """C2. Sent the day access actually ends. FitWiz brand voice — this is
        a billing fact, not a guilt trip. But we use their stats as nostalgia."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        workouts = stats.workouts_total

        subject = f"You're on the free plan now, {name}."
        title = f"You're on the free plan now, {name}"
        subtitle = (
            f"Your FitWiz Premium access ended today. "
            + (f"You logged {workouts} workouts along the way — all of that history stays. "
               if workouts > 0 else "")
            + f"Here's what the free plan looks like."
        )

        features = [
            ("&#128200;", "Your history stays",
             "Every workout, every PR, every photo you logged is still yours to access."),
            ("&#128274;", "Plan adaptation pauses",
             "FitWiz will stop adjusting your plan week-to-week. Premium is what re-runs the math."),
            ("&#128172;", "Coach chat limited",
             "Daily message cap on free tier. Premium gives unlimited conversations."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Come back to Premium",
            features=features,
            footer_text="You received this because your FitWiz subscription ended.",
            persona_signature_html="",  # transactional, brand voice only
            stats_row_html=build_stats_grid_html(stats) if stats.has_any_activity else "",
            category_name="billing & account",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"C2 access expired email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send access expired email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_post_cancel_offer(
        self, to_email: str, first_name_value: str, stats: UserStats,
        days_since_expiry: int, discount_percent: int,
    ) -> Dict[str, Any]:
        """C3/C4/C6. Tiered discount offers post-expiry. Persona voice.

        The discount_percent is chosen by the cron caller based on days since
        expiry (10/20/30). Copy adjusts tone: week 1 is conversational, week
        2+ is more urgent, week 8 is "last chance."
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name
        workouts = stats.workouts_total
        last_name = stats.last_workout_name or "your last session"

        # Copy band by days-since-expiry
        if days_since_expiry <= 10:
            subject = f"{coach} kept your plan, {name}."
            title = f"{coach} kept your seat"
            subtitle = (
                f"It's been {days_since_expiry} days. Your {last_name} is still saved. "
                f"Come back for {discount_percent}% off."
            )
        elif days_since_expiry <= 20:
            subject = f"{name}. Those {workouts} workouts? They matter."
            title = f"Your run doesn't have to end, {name}"
            subtitle = (
                f"{workouts} workouts logged. You were on to something. "
                f"{discount_percent}% off to pick it back up."
            )
        else:
            subject = f"Final call, {name}."
            title = f"Final call, {name}"
            subtitle = (
                f"{days_since_expiry} days. This is the last offer we'll send. "
                f"{discount_percent}% off — locked in for as long as you stay."
            )

        features = [
            ("&#127873;", f"{discount_percent}% off",
             f"Best price we can do. Expires in 7 days."),
            ("&#128202;", "Your data is ready",
             f"{workouts} workouts, {stats.nutrition_days_logged_this_week} nutrition logs this week, "
             f"{stats.xp_total:,} XP. All still here."),
            ("&#129303;", f"{coach} is still yours",
             "Same persona, same memory of your goals and equipment."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text=f"Come back — {discount_percent}% off",
            features=features,
            footer_text="You received this because you were a FitWiz Premium member.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats) if stats.has_any_activity else "",
            category_name="offers",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Post-cancel offer ({days_since_expiry}d, {discount_percent}%) sent to {to_email}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send post-cancel offer to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_sunset(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """C7. Final email before going quiet — compliance-friendly, respectful.

        One-click re-opt-in link. Bare transactional aspect remains ("we will
        still email you about billing") — marketing goes silent after this.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        workouts = stats.workouts_total

        subject = f"We'll stop emailing you, {name}."
        title = f"Going quiet, {name}"
        subtitle = (
            f"You've been off FitWiz for 90+ days. We'll stop sending nudges now — "
            + (f"but your {workouts} logged workouts and your account stay. " if workouts > 0 else "")
            + "Tap below if you ever want to hear from us again."
        )

        features = [
            ("&#128279;", "Keep me on the list",
             "One tap re-subscribes you to motivational emails. No commitment."),
            ("&#128229;", "Still get billing emails",
             "Anything about your account or payments still comes through — required by law."),
            ("&#128172;", "Your account is safe",
             "Data, history, and settings all stay. Log in any time."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Keep me on the list",
            features=features,
            footer_text="You received this final email before we stop sending marketing messages.",
            persona_signature_html="",  # respectful, no mascot on the sunset
            stats_row_html="",
            category_name="billing & account",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"C7 sunset email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send sunset email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}
