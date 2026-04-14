"""
Engagement-bucket emails — nudges tuned to specific user states that were
previously falling through the cracks.

Covers:
- Idle nudge (day 7 / day 14 of inactivity, fills gap between streak-at-risk and win-back)
- One-workout-wonder (logged exactly 1 workout, then silent ≥7 days)
- Premium-idle (paying but inactive 14+ days — refund-risk mitigation)
- Welcome-back-premium (one-shot celebrate when a churned user resubscribes)

Motivational voice throughout — persona-driven, stats-heavy.
"""
import resend
from typing import Dict, Any

from core.logger import get_logger
from models.email import UserStats
from services.email_helpers import (
    build_persona_signature_html,
    build_stats_grid_html,
)

logger = get_logger(__name__)


class EmailEngagementMixin:
    """Engagement-bucket email methods mixed into EmailService."""

    async def send_idle_nudge(
        self, to_email: str, first_name_value: str, stats: UserStats,
        days_idle: int,
    ) -> Dict[str, Any]:
        """Mid-gap nudge — fires at day 7 or 14 of inactivity.

        Persona voice, moderate guilt. Positioned between streak-at-risk (day 3)
        and win-back (day 30+) so active-then-quiet users don't get silence.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name
        last_name = stats.last_workout_name or "your last workout"

        if days_idle <= 7:
            subject = f"{name}. {days_idle} days. {coach} is still here."
            title = f"{days_idle} days since {last_name}"
            subtitle = (
                f"{coach} knows life gets in the way. But one short session today "
                f"resets everything. Pick any workout — even the easy one."
            )
        else:
            subject = f"{name}, {coach} is getting concerned."
            title = f"Two weeks, {name}"
            subtitle = (
                f"{days_idle} days since {last_name}. {coach} can still rebuild the plan, "
                f"but you have to show up. Fifteen minutes is the whole ask."
            )

        features = [
            ("&#127947;", f"Up next: {stats.next_workout_name or 'your next session'}",
             f"Ready. Adapted. {coach} adjusted the load after the gap."),
            ("&#9201;", "15 minutes is plenty",
             "Shorter than a coffee break. Keeps the door open."),
            ("&#128293;", f"{stats.workouts_total} workouts on record",
             "Your history doesn't disappear. But it stops growing today if nothing changes."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Get back on",
            features=features,
            footer_text="You received this because you're still signed up for motivational nudges.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats) if stats.has_any_activity else "",
            category_name="motivational check-ins",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Idle nudge ({days_idle}d) sent to {to_email}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send idle nudge to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_one_workout_wonder(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """Fires 7 days after a user with exactly one lifetime workout.

        Distinct from day-3 activation (which never fires for users with
        ≥1 workout). Targets the specific drop-off where someone tried once
        and didn't come back.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name
        last_name = stats.last_workout_name or "that first workout"

        subject = f"{name}, {coach} is curious."
        title = f"You did one workout, {name}"
        subtitle = (
            f"{last_name} was great. Then silence. {coach} wants to know — "
            f"was the workout too hard? Too easy? Something else? "
            f"Tell us and we'll adapt."
        )

        features = [
            ("&#128172;", "Tell us what didn't land",
             "Two-tap feedback form. Difficulty, time, equipment — whatever made it not stick."),
            ("&#127947;", f"Up next: {stats.next_workout_name or 'a lighter session'}",
             f"{coach} already adjusted down from your first one. Fifteen minutes, lower intensity."),
            ("&#128293;", "The second workout is the game",
             "First workouts are easy — you had motivation. Second ones are where the habit forms."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Try a shorter session",
            features=features,
            footer_text="You received this because you logged one workout and we haven't seen you since.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="motivational check-ins",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"One-workout-wonder email sent to {to_email}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send one-workout-wonder email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_premium_idle(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """Refund-risk mitigation for paid users who haven't used the app in 14+ days.

        Targets the annual-plan trap: paid upfront, forgot, never engaged. If
        we don't re-engage they'll chargeback or refund. Hybrid voice — persona
        at top, FitWiz-value-reminder at bottom.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name

        subject = f"You're paying for this, {name}."
        title = f"{name}, FitWiz is yours"
        subtitle = (
            f"You've had FitWiz Premium for 14+ days without logging. "
            f"{coach} isn't judging — but you're paying. Let's put that to use."
        )

        features = [
            ("&#127947;", "Your plan is already built",
             f"{coach} queued {stats.next_workout_name or 'your next session'}. Zero setup left."),
            ("&#128172;", "Free unlimited coach chat",
             f"Ask {coach} anything. Form, nutrition, scheduling. Premium has no cap."),
            ("&#128200;", "Advanced analytics are live",
             "Strength curves, body trends, nutrition correlations — all unlocked for you."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Open my plan",
            features=features,
            footer_text="You received this because you're an active Premium subscriber.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats) if stats.has_any_activity else "",
            category_name="motivational check-ins",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Premium-idle email sent to {to_email}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send premium-idle email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_welcome_back_premium(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """One-shot celebration when a churned user resubscribes to Premium.

        Fires inline from the subscription reactivation webhook (or periodic
        reconciliation job) — not a cron. One-shot dedup via email_send_log.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name

        subject = f"{name}. Welcome back to Premium."
        title = f"Welcome back, {name}"
        subtitle = (
            f"{coach} kept everything. Your {stats.workouts_total} logged workouts, "
            f"your settings, your history. Let's pick up where we left off."
        )

        features = [
            ("&#127942;", "Full access restored",
             "Unlimited workouts, unlimited coach chat, advanced analytics — all active."),
            ("&#127947;", f"Up next: {stats.next_workout_name or 'your next session'}",
             f"{coach} adapted the plan based on the time off. You won't be thrown in the deep end."),
            ("&#128202;", "Your history is intact",
             f"{stats.xp_total:,} XP, your PRs, progress photos — everything that was there is still here."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="See my plan",
            features=features,
            footer_text="You received this because you reactivated your FitWiz Premium subscription.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="billing & account",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Welcome-back-premium email sent to {to_email}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send welcome-back-premium email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}
