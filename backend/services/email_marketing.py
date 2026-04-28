"""
Email marketing mixin: win-back, upsell, weekly summary emails.

All methods take pre-resolved `first_name_value` + populated `UserStats`.
Weekly summary is the premier nutrition-showcase email; win-back references
the user's actual lifetime stats as re-engagement hooks.
"""
import resend
from typing import Dict, Any, Optional

from core import branding
from core.logger import get_logger
from models.email import UserStats
from services.email_helpers import (
    build_persona_signature_html,
    build_stats_grid_html,
    build_nutrition_grid_html,
)

logger = get_logger(__name__)


class EmailMarketingMixin:
    """Marketing email methods mixed into EmailService.

    Expects `self.from_email`, `self.is_configured()`, `self._build_standard_email()`.
    """

    async def send_win_back(
        self, to_email: str, first_name_value: str, stats: UserStats,
        days_since_expiry: int, discount_percent: int = 25,
    ) -> Dict[str, Any]:
        """Win-back email for lapsed users — 30-day post-cancel ladder entry.

        Persona voice + specific stats ("30 days. {coach} has receipts.").
        Stats grid shows lifetime totals so the user sees what they built
        and is remembering what they lost.
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
        longest = stats.longest_streak_days or stats.current_streak_days

        subject = f"{name}. {days_since_expiry} days. {coach} has receipts."
        title = f"{coach} kept your seat, {name}"
        subtitle = (
            f"{days_since_expiry} days since your Premium ended. "
            f"You logged {workouts} workouts with us"
            + (f", hit a {longest}-day streak," if longest > 0 else "")
            + f" and then disappeared. {coach} kept all of it. Come back for {discount_percent}% off."
        )

        features = [
            ("&#128202;", f"{workouts} workouts still on the record",
             "Your history, PRs, and progress data are exactly where you left them."),
            ("&#129303;", f"{coach} remembers you",
             "Your preferences, injuries, and goals — no re-onboarding. Just tap resume."),
            ("&#9889;", f"{discount_percent}% off for returning members",
             f"Lock in now and save {discount_percent}%. Offer expires in 7 days."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text=f"Come back — {discount_percent}% off",
            features=features,
            footer_text=f"You received this because you were a {branding.APP_NAME} Premium member.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats) if stats.has_any_activity else "",
            category_name="offers",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Win-back email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send win-back email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_7day_upsell(
        self, to_email: str, first_name_value: str, stats: UserStats,
        free_workouts_remaining: int = 0,
    ) -> Dict[str, Any]:
        """7-day upsell for free-tier users at trial end (trial is 7 days).

        `free_workouts_remaining` is optional (default 0). Template only mentions
        it if the caller passes a non-zero value — avoids the old signature bug
        where the cron didn't pass this field at all.
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

        subject = f"Your free trial just ended, {name}."
        title = f"Your 7-day trial is up, {name}"
        limit_line = (
            f"You have {free_workouts_remaining} free workouts left this month — "
            if free_workouts_remaining > 0
            else ""
        )
        subtitle = (
            f"7 days. {workouts} workouts with {coach}. "
            + limit_line
            + "Premium removes every cap, unlocks unlimited coaching, and adapts the plan to you every week."
        )

        features = [
            ("&#127947;", f"{workouts} workouts and climbing",
             f"{coach} thinks you're ready for unlimited."),
            ("&#129303;", "Unlimited coach access",
             "Free plan caps daily messages. Premium removes the cap entirely."),
            ("&#128200;", "Advanced analytics",
             "Strength curves, body composition trends, nutrition correlations."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Go Premium",
            features=features,
            footer_text=f"You received this because you've been active on the {branding.APP_NAME} free plan.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="offers",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"7-day upsell email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send 7-day upsell email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_weekly_summary(
        self, to_email: str, first_name_value: str, stats: UserStats,
        total_duration_minutes: int = 0, top_exercise: str = "",
        top_exercise_volume_lbs: float = 0,
        percentile: Optional[float] = None,   # W5: 0-100 among active users
        percentile_tier: Optional[str] = None,  # 'legendary' | 'top' | 'elite' | 'rising' | 'active'
    ) -> Dict[str, Any]:
        """Weekly summary — the nutrition showcase email.

        Renders two stat grids: the workouts/streak/volume grid, AND the
        dedicated nutrition grid showing days logged, avg calories, avg protein,
        and whether they logged today. When user has never touched nutrition,
        the nutrition block shows a gentle "start logging" nudge instead of
        an empty grid.

        Persona signature + mood emoji adapt: impressed when active, concerned
        when sparse. The subject uses specific numbers ("3 workouts, 2,341 lbs")
        so the user reads the value before even opening.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name

        hours = total_duration_minutes // 60
        mins = total_duration_minutes % 60
        duration_str = f"{hours}h {mins}m" if hours > 0 else f"{mins}m" if mins else ""

        # Dynamic subject — the numbers go first, the name second.
        # W5: prefer percentile when the user is in the top 30% and has logged
        # workouts this week. This is Duolingo-style social-proof copy — research
        # shows this is one of the strongest drivers of app consistency.
        top_percent_text = None
        if percentile is not None and percentile > 0 and stats.workouts_this_week >= 1:
            top_pct = max(1, int(round(100 - percentile)))  # invert: percentile 95 → top 5%
            if top_pct <= 30:
                top_percent_text = f"top {top_pct}%"

        if stats.workouts_this_week >= 1:
            summary_bits = [f"{stats.workouts_this_week} workouts"]
            if stats.nutrition_days_logged_this_week:
                summary_bits.append(f"{stats.nutrition_days_logged_this_week}/7 meal days")
            if stats.nutrition_avg_protein_g_week:
                summary_bits.append(f"{stats.nutrition_avg_protein_g_week}g protein avg")

            if top_percent_text is not None:
                subject = f"🏆 {name}, you're in the {top_percent_text} this week"
                title = f"You're in the {top_percent_text}, {name}"
            else:
                subject = f"{name}, your week: " + " · ".join(summary_bits)
                title = f"Your week, {name}"

            if stats.workouts_this_week >= 3:
                mood_line = f"{coach} is impressed."
            else:
                mood_line = f"{coach} noticed."
            subtitle = f"Here's what you pulled off" + (f" · {duration_str} of training." if duration_str else ".")
        else:
            subject = f"{name}, empty week — {coach} is here when you're ready"
            title = f"A quiet week, {name}"
            subtitle = (
                f"You didn't log a workout this week. "
                f"{coach} isn't mad — just checking in. Ready to restart?"
            )
            mood_line = ""

        # Feature blocks — workouts, nutrition, next steps.
        features = [
            ("&#127947;", f"{stats.workouts_this_week} workouts done",
             f"Lifetime total: {stats.workouts_total}." + (f" Current streak: {stats.current_streak_days} 🔥" if stats.current_streak_days else "")),
            ("&#128202;", "Nutrition this week",
             _nutrition_summary_line(stats)),
        ]
        # W5: add percentile block prominently when we have it
        if top_percent_text is not None:
            features.append((
                "&#127942;",
                f"You're in the {top_percent_text} of active users",
                "That's real consistency. Keep showing up — most people don't.",
            ))
        features.append((
            "&#128293;", "Coming up",
            f"Up next: {stats.next_workout_name or 'your next session'}." + (" " + mood_line if mood_line else "")
        ))

        # The core content: workouts grid + nutrition grid, stacked.
        stats_row = build_stats_grid_html(stats) + build_nutrition_grid_html(stats)

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="See full stats",
            features=features,
            footer_text="You received this because you have weekly summaries enabled.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=stats_row,
            category_name="weekly summary",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Weekly summary email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send weekly summary email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}


def _nutrition_summary_line(stats: UserStats) -> str:
    """One-liner describing the user's nutrition week for the feature block.

    Adapts to zero-state vs logged: "You logged 3 meals this week, averaging
    1,840 cal and 120g protein." vs "Nothing logged. Nutrition is blind."
    """
    if stats.nutrition_days_logged_this_week == 0:
        return "Nothing logged this week. Coach can't see what you eat if you don't tell us."
    parts = [f"{stats.nutrition_days_logged_this_week}/7 days logged"]
    if stats.nutrition_avg_calories_week:
        parts.append(f"~{stats.nutrition_avg_calories_week:,} cal/day")
    if stats.nutrition_avg_protein_g_week:
        parts.append(f"~{stats.nutrition_avg_protein_g_week}g protein/day")
    return ". ".join(parts) + "."
