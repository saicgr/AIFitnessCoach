"""
Email marketing mixin: win-back, upsell, weekly summary emails.

All methods take pre-resolved `first_name_value` + populated `UserStats`.
Weekly summary is the premier nutrition-showcase email; win-back references
the user's actual lifetime stats as re-engagement hooks.
"""
import copy
import dataclasses
from typing import Dict, Any, Optional, Tuple

from core import branding
from core.logger import get_logger
from models.email import UserStats
from services import email_sender
from services.email_helpers import (
    build_persona_signature_html,
    build_stats_grid_html,
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
        user_id: Optional[str] = None,
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
            response = email_sender.send(params, user_id=user_id, email_type="win_back_30")
            logger.info(f"Win-back email sent to {to_email}: {response}")
            return email_sender.sent_result(response)
        except Exception as e:
            logger.error(f"Failed to send win-back email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_7day_upsell(
        self, to_email: str, first_name_value: str, stats: UserStats,
        free_workouts_remaining: int = 0,
        user_id: Optional[str] = None,
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
            response = email_sender.send(params, user_id=user_id, email_type="7day_upsell")
            logger.info(f"7-day upsell email sent to {to_email}: {response}")
            return email_sender.sent_result(response)
        except Exception as e:
            logger.error(f"Failed to send 7-day upsell email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_weekly_summary(
        self, to_email: str, first_name_value: str, stats: UserStats,
        progress: Optional[Any] = None,        # WeeklyProgress (the report data)
        cardio: Optional[Any] = None,          # WeeklyCardioSummary — absorbs the old Sunday digest
        total_duration_minutes: int = 0, top_exercise: str = "",
        top_exercise_volume_lbs: float = 0,
        percentile: Optional[float] = None,   # retained for signature compat (unused)
        percentile_tier: Optional[str] = None,
        user_id: Optional[str] = None,        # recipient's users.id — arms the frequency cap
    ) -> Dict[str, Any]:
        """Weekly progress report — the one Monday recap.

        Renders the signature template (`email_signature_template`): orange rail,
        avatar greeting, hero card (steps, or workouts when no wearable), per-day
        step rings, rounded metric-card grids (wearable + app-native, auto-hiding
        empty tiles), an awards band when milestones fired, coach card, pill CTA.

        `progress` is a `WeeklyProgress` from `weekly_progress_service`. When it's
        absent (defensive — the cron always supplies it) we still send a minimal
        coach check-in rather than crash.

        `cardio` is a `WeeklyCardioSummary` from `cardio_digest_service`. It is the
        MERGE: what used to be a separate Sunday-morning cardio digest is now a
        "Your cardio week" band inside this email — one recap a week, not two 24h
        apart. It is `None` for a user with no cardio in the window, and then this
        email renders exactly as it did before (zero visual diff).

        Cardio also counts as ACTIVITY: `progress.empty_week` is computed without
        ever reading `cardio_logs`, so it is reconciled here (`_reconcile_cardio_week`)
        before any copy branches on it.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        from services import email_signature_template as sig

        backend_url = get_settings().backend_base_url
        open_url = lifecycle_open_url(backend_url, "weekly_summary")
        name = first_name_value or "there"
        coach = stats.coach_name or "Your coach"

        # THE chokepoint: reconcile the quiet-week verdict with cardio ONCE, before
        # subject/greeting/preheader/body read `progress.empty_week`.
        progress, cardio_led = _reconcile_cardio_week(progress, cardio)

        if progress is None:
            html_content = sig.signature_email(
                header_tag="Weekly", greeting=f"Hi, {name}.",
                greeting_sub="Your weekly check-in", avatar=name[:1],
                body_html=sig.coach_card(coach, f"Checking in, {name} — open the app to see your week.")
                + _cardio_section(cardio, first_name_value)
                + sig.pill_cta("View in app →", open_url),
                category_label="weekly reports",
            )
            subject = f"{name}, your weekly check-in"
        else:
            subject = _weekly_subject(progress, name, cardio if cardio_led else None)
            html_content = sig.signature_email(
                header_tag=f"Weekly · {progress.week_label}",
                greeting=_weekly_greeting(progress, name, stats),
                greeting_sub=f"Your stats for {progress.week_label}",
                avatar=name[:1],
                body_html=_compose_weekly_body(progress, coach, open_url,
                                               cardio=cardio, name=first_name_value,
                                               cardio_led=cardio_led),
                category_label="weekly reports",
                preheader=_weekly_preheader(progress, name,
                                            cardio if cardio_led else None),
            )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = email_sender.send(params, user_id=user_id, email_type="weekly_summary")
            logger.info(f"Weekly summary email sent to {to_email}: {response}")
            return email_sender.sent_result(response)
        except Exception as e:
            logger.error(f"Failed to send weekly summary email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}


# ─────────────────────────────────────────────────────────────────────
# Weekly progress report — subject / greeting / body composition.
# Consumes a `WeeklyProgress` from services.weekly_progress_service.
# ─────────────────────────────────────────────────────────────────────

_TOD_WORD = {
    "morning": "Morning", "midday": "Afternoon", "afternoon": "Afternoon",
    "evening": "Evening", "late": "Evening", "quiet": "Hi",
}


def _cardio_is_active(cardio: Optional[Any]) -> bool:
    """True when the WeeklyCardioSummary carries real activity in the window."""
    if cardio is None:
        return False
    try:
        sessions = int(getattr(cardio, "session_count", 0) or 0)
        km = float(getattr(cardio, "km_this_week", 0) or 0)
    except (TypeError, ValueError):
        return False
    return sessions > 0 or km > 0


def _reconcile_cardio_week(progress: Optional[Any],
                           cardio: Optional[Any]) -> Tuple[Optional[Any], bool]:
    """Cardio is activity — reconcile it into the quiet-week verdict, once.

    `weekly_progress_service.compute_weekly_progress` derives `empty_week` from
    steps + `workout_logs` + nutrition days + awards. It never reads `cardio_logs`
    (a disjoint table written by manual entry and the Strava/Garmin import
    pipeline), so a runner who logs only cardio and has no step sync is classified
    "quiet" — and the email then said "You logged 0 steps and 0 workouts this week"
    directly above a cardio band reading "21.4 km · 4 sessions".

    Four call sites read `empty_week` (subject, greeting, coach message, body), so
    the fix belongs here — at the one place that owns both objects — not as a guard
    in each of them. Returns `(progress, cardio_led)`; `cardio_led` is True when
    cardio is the ONLY activity of the week, which makes it the week's headline
    (the workouts hero would otherwise read "0").
    """
    if progress is None or not _cardio_is_active(cardio):
        return progress, False
    if not getattr(progress, "empty_week", False):
        return progress, False

    fields = {"empty_week": False, "quiet_line": ""}
    try:
        progress = dataclasses.replace(progress, **fields)
    except TypeError:
        # Not a dataclass instance (e.g. a test double) — never mutate the caller's
        # object; shallow-copy and override.
        progress = copy.copy(progress)
        for key, value in fields.items():
            setattr(progress, key, value)
    return progress, True


def _fmt_km(km: float) -> str:
    return f"{km:.1f}".rstrip("0").rstrip(".")


def _cardio_headline(cardio: Any) -> Tuple[str, int]:
    """(km string, session count) for cardio-led subject/preheader copy."""
    try:
        km = float(getattr(cardio, "km_this_week", 0) or 0)
    except (TypeError, ValueError):
        km = 0.0
    try:
        sessions = int(getattr(cardio, "session_count", 0) or 0)
    except (TypeError, ValueError):
        sessions = 0
    return _fmt_km(km), sessions


def _weekly_greeting(progress: Any, name: str, stats: UserStats) -> str:
    if progress.is_first_week:
        return f"Welcome, {name}."
    if progress.empty_week:
        return f"A quiet week, {name}."
    if progress.awards:
        return f"Big week, {name}."
    band = getattr(getattr(stats, "time_band", None), "value", "morning")
    return f"{_TOD_WORD.get(band, 'Hi')}, {name}."


def _weekly_subject(progress: Any, name: str, cardio: Optional[Any] = None) -> str:
    """Numbers-first subject, variant pool ≥4 (feedback_dynamic_copy_not_robotic).

    `cardio` is supplied ONLY when the week was cardio-led (see
    `_reconcile_cardio_week`) — the week's numbers live in `cardio`, not in
    `progress`, so the subject must lead with distance, never "0 workouts".
    """
    if cardio is not None:
        km, sessions = _cardio_headline(cardio)
        s = "s" if sessions != 1 else ""
        pool = [
            f"{name}, your cardio week: {km} km",
            f"{km} km this week, {name}",
            f"{name}, {sessions} cardio session{s} — here's your week",
            f"Your weekly stats, {name} — {km} km logged",
        ]
        idx = (sessions + len(name)) % len(pool)
        return pool[idx]
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


def _weekly_preheader(progress: Any, name: str, cardio: Optional[Any] = None) -> str:
    if cardio is not None:
        km, sessions = _cardio_headline(cardio)
        return (f"{km} km across {sessions} cardio session"
                f"{'s' if sessions != 1 else ''} — your week.")
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


def _cardio_section(cardio: Optional[Any], name: str) -> str:
    """The absorbed cardio digest, as an embeddable band. "" when the user logged
    no cardio (`compute_weekly_cardio_summary` returns None) — the email is then
    byte-for-byte what it was before the merge.

    Rendering lives in `cardio_digest_service` (it owns the rollup and the copy);
    this is only the splice point.

    The band renders IFF cardio counted as activity (`_cardio_is_active`) — the
    same predicate that clears the quiet-week verdict. A 0 km / 0 session band
    under quiet-week copy would be the same contradiction in the other direction.
    """
    if not _cardio_is_active(cardio):
        return ""
    from services import cardio_digest_service as cardio_svc

    try:
        return cardio_svc.render_digest_section_html(cardio, name)
    except Exception as e:
        # A malformed summary must never cost the user their weekly report — the
        # rest of the email is independent of this band.
        logger.error(f"Weekly summary: cardio section render failed: {e}", exc_info=True)
        return ""


def _compose_weekly_body(progress: Any, coach: str, cta_url: str,
                         cardio: Optional[Any] = None, name: str = "",
                         cardio_led: bool = False) -> str:
    from services import email_signature_template as sig

    parts: list = []
    if progress.awards:
        parts.append(sig.awards_block(progress.awards))

    if progress.empty_week:
        if progress.quiet_line:
            parts.append(sig.callout(progress.quiet_line))
    elif cardio_led:
        # Cardio was the week's only activity (see `_reconcile_cardio_week`): the
        # cardio band below IS the hero. A workouts hero here would read "0".
        pass
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

    # The absorbed cardio digest — a third labelled data band, parallel to
    # "Activity" and "Your Zealova week". It sits AFTER the grids (so it doesn't
    # compete with the steps hero, which is also distance/effort) and BEFORE the
    # coach card (so the coach's read of the week lands after all the numbers).
    parts.append(_cardio_section(cardio, name))

    if not progress.has_wearable and not progress.empty_week:
        parts.append(sig.callout(
            "<b>Connect a watch or phone steps</b> to unlock steps, sleep &amp; "
            "heart rate in next week's report.",
            "Connect a wearable →", cta_url))

    parts.append(sig.coach_card(coach, _weekly_coach_msg(progress)))
    cta_text = "Start a 15-minute session →" if progress.empty_week else "View in app →"
    parts.append(sig.pill_cta(cta_text, cta_url))
    return "".join(parts)
