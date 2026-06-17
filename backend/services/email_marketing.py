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
    lifecycle_open_url,
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
        logo_url = get_settings().email_logo_url
        open_url = lifecycle_open_url(backend_url, "win_back")

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
        logo_url = get_settings().email_logo_url
        open_url = lifecycle_open_url(backend_url, "7day_upsell")

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
        progress: Optional[Any] = None,        # WeeklyProgress (the report data)
        total_duration_minutes: int = 0, top_exercise: str = "",
        top_exercise_volume_lbs: float = 0,
        percentile: Optional[float] = None,   # retained for signature compat (unused)
        percentile_tier: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Weekly progress report — the Google-Health-style numbers email.

        Renders the signature template (`email_signature_template`): orange rail,
        avatar greeting, hero card (steps, or workouts when no wearable), per-day
        step rings, rounded metric-card grids (wearable + app-native, auto-hiding
        empty tiles), an awards band when milestones fired, coach card, pill CTA.

        `progress` is a `WeeklyProgress` from `weekly_progress_service`. When it's
        absent (defensive — the cron always supplies it) we still send a minimal
        coach check-in rather than crash.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        from services import email_signature_template as sig

        backend_url = get_settings().backend_base_url
        open_url = lifecycle_open_url(backend_url, "weekly_summary")
        name = first_name_value or "there"
        coach = stats.coach_name or "Your coach"

        if progress is None:
            html_content = sig.signature_email(
                header_tag="Weekly", greeting=f"Hi, {name}.",
                greeting_sub="Your weekly check-in", avatar=name[:1],
                body_html=sig.coach_card(coach, f"Checking in, {name} — open the app to see your week.")
                + sig.pill_cta("View in app →", open_url),
                category_label="weekly reports",
            )
            subject = f"{name}, your weekly check-in"
        else:
            subject = _weekly_subject(progress, name)
            html_content = sig.signature_email(
                header_tag=f"Weekly · {progress.week_label}",
                greeting=_weekly_greeting(progress, name, stats),
                greeting_sub=f"Your stats for {progress.week_label}",
                avatar=name[:1],
                body_html=_compose_weekly_body(progress, coach, open_url),
                category_label="weekly reports",
                preheader=_weekly_preheader(progress, name),
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


# ─────────────────────────────────────────────────────────────────────
# Weekly progress report — subject / greeting / body composition.
# Consumes a `WeeklyProgress` from services.weekly_progress_service.
# ─────────────────────────────────────────────────────────────────────

_TOD_WORD = {
    "morning": "Morning", "midday": "Afternoon", "afternoon": "Afternoon",
    "evening": "Evening", "late": "Evening", "quiet": "Hi",
}


def _weekly_greeting(progress: Any, name: str, stats: UserStats) -> str:
    if progress.is_first_week:
        return f"Welcome, {name}."
    if progress.empty_week:
        return f"A quiet week, {name}."
    if progress.awards:
        return f"Big week, {name}."
    band = getattr(getattr(stats, "time_band", None), "value", "morning")
    return f"{_TOD_WORD.get(band, 'Hi')}, {name}."


def _weekly_subject(progress: Any, name: str) -> str:
    """Numbers-first subject, variant pool ≥4 (feedback_dynamic_copy_not_robotic)."""
    if progress.empty_week:
        pool = [
            f"{name}, a quiet week — we're here when you're ready",
            f"{name}, this week was light — let's reset",
            f"No pressure, {name} — your week in 30 seconds",
            f"{name}, picking back up starts with one session",
        ]
    elif progress.awards:
        n = len(progress.awards)
        pool = [
            f"Big week, {name} — {n} milestone{'s' if n != 1 else ''} unlocked",
            f"{name}, you set {n} milestone{'s' if n != 1 else ''} this week",
            f"{name}, your week was a statement",
            f"{name}, the numbers are in — and they're good",
        ]
    elif progress.has_wearable and progress.total_steps > 0:
        s = f"{progress.total_steps:,}"
        pool = [
            f"{name}, your week: {s} steps",
            f"{s} steps this week, {name}",
            f"Your weekly stats, {name} — {s} steps",
            f"{name}, here's your week in numbers",
        ]
    else:
        w = progress.workouts_this_week
        pool = [
            f"{name}, your training week: {w} workout{'s' if w != 1 else ''}",
            f"{w} workout{'s' if w != 1 else ''} this week, {name}",
            f"Your weekly stats, {name}",
            f"{name}, here's your week in numbers",
        ]
    idx = (progress.total_steps + progress.workouts_this_week + len(name)) % len(pool)
    return pool[idx]


def _weekly_preheader(progress: Any, name: str) -> str:
    if progress.has_wearable and progress.total_steps > 0:
        return f"{progress.total_steps:,} steps and {progress.workouts_this_week} workouts — your week."
    return f"{progress.workouts_this_week} workouts this week — your Zealova report."


def _weekly_coach_msg(progress: Any) -> str:
    if progress.empty_week:
        return "I'm not going anywhere. When you're ready, we pick up right where we left off."
    if progress.is_first_week:
        return "This is your baseline. Next week we measure everything against it."
    if progress.awards:
        return "Milestones stacked up this week. That's the consistency that compounds."
    if progress.best_label:
        return f"Best step day was {progress.best_label} — let's keep your daily average climbing."
    return "Solid week. Consistency is the whole game — keep showing up."


def _compose_weekly_body(progress: Any, coach: str, cta_url: str) -> str:
    from services import email_signature_template as sig

    parts: list = []
    if progress.awards:
        parts.append(sig.awards_block(progress.awards))

    if progress.empty_week:
        if progress.quiet_line:
            parts.append(sig.callout(progress.quiet_line))
    elif progress.has_wearable and progress.total_steps > 0:
        pills = [(f"Avg {progress.avg_steps:,} / day", "flat")]
        if progress.steps_delta:
            txt = progress.steps_delta + (" vs last week" if progress.steps_dir == "up" else "")
            pills.append((txt, progress.steps_dir))
        parts.append(sig.hero_card(icon="foot", big=f"{progress.total_steps:,}",
                                   caption="Total steps this week", pills=pills))
        if any(s is not None for _, s in progress.day_steps):
            best = (f"Best {progress.best_label} {progress.best_steps:,}"
                    if progress.best_label and progress.best_steps else "")
            sub = f"Avg {progress.avg_steps:,} / day" + (f" · {best}" if best else "")
            parts.append(sig.day_rings_row(progress.day_steps, progress.step_goal,
                                           progress.best_label, sub))
    else:
        pills = []
        if progress.workouts_subline:
            pills.append((progress.workouts_subline, "flat"))
        if progress.workouts_delta:
            pills.append((progress.workouts_delta, progress.workouts_dir))
        parts.append(sig.hero_card(icon="dumbbell", big=str(progress.workouts_this_week),
                                   caption="Workouts this week", pills=pills))

    if progress.activity_tiles:
        parts.append(sig.section_label("Activity"))
        parts.append(sig.metric_grid(progress.activity_tiles))
    if progress.zealova_tiles:
        parts.append(sig.section_label("Your Zealova week"))
        parts.append(sig.metric_grid(progress.zealova_tiles))

    if not progress.has_wearable and not progress.empty_week:
        parts.append(sig.callout(
            "<b>Connect a watch or phone steps</b> to unlock steps, sleep &amp; "
            "heart rate in next week's report.",
            "Connect a wearable →", cta_url))

    parts.append(sig.coach_card(coach, _weekly_coach_msg(progress)))
    cta_text = "Start a 15-minute session →" if progress.empty_week else "View in app →"
    parts.append(sig.pill_cta(cta_text, cta_url))
    return "".join(parts)
