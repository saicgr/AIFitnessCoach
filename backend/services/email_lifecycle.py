"""
Email lifecycle mixin: cancellation retention, trial, streak, activation emails.

Extracted from email_service.py. Mixed into EmailService via multiple inheritance.

Voice split (see plan):
- Motivational/lifecycle emails (day3, streak, trial-ending, onboarding-incomplete)
  use the user's selected coach persona (`stats.coach_name`), branch on
  `stats.schedule_state`/`stats.time_band`, and carry a stats grid.
- Transactional emails (cancellation retention, trial expired) use the FitWiz
  brand voice — no mascot, no persona signature.

All methods take a pre-resolved `first_name_value` from the caller (via
`first_name()` helper) plus a populated `UserStats`. The caller is responsible
for applying schedule-state and time-band gates before calling us; send methods
render safety-net variants rather than crashing if called in an unexpected state.
"""
import resend
from typing import Dict, Any, Optional

from core.logger import get_logger
from models.email import UserStats, ScheduleState, TimeBand
from services.email_helpers import (
    build_persona_signature_html,
    build_stats_grid_html,
    build_zero_state_row_html,
    build_nutrition_grid_html,
    overdue_tier,
)

logger = get_logger(__name__)


class EmailLifecycleMixin:
    """Lifecycle email methods mixed into EmailService.

    Expects `self.from_email`, `self.is_configured()`, `self._build_standard_email()`.
    """

    # ────────────────────────────────────────────────────────────────────────
    # Transactional — FitWiz brand voice
    # ────────────────────────────────────────────────────────────────────────

    async def send_cancellation_retention(
        self, to_email: str, first_name_value: str, stats: UserStats, tier: str,
    ) -> Dict[str, Any]:
        """Transactional cancellation email with user's real stats as reason to stay.

        Opens with FitWiz brand voice on the cancel fact; closes with the persona's
        voice on what they'll lose. References their actual workout count so it
        feels earned, not generic.
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
        streak = stats.longest_streak_days or stats.current_streak_days

        subject = f"{name}, before you leave FitWiz"
        title = f"Before you go, {name}"
        subtitle = (
            f"You've logged {workouts} workouts with FitWiz"
            + (f" and built a {streak}-day streak" if streak > 0 else "")
            + f". {coach} remembers all of it. Don't throw it out."
        )

        features = [
            ("&#128202;", "Your history stays, but frozen",
             f"All {workouts} logged workouts stay visible — but your plan stops adapting on the free tier."),
            ("&#129303;", f"{coach} goes generic",
             f"Unlimited chat with {coach} is premium. Free tier caps daily messages and loses personalisation over time."),
            ("&#128200;", "Progress tracking simplifies",
             "Advanced analytics, strength curves, and body composition charts are premium features."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Keep my access",
            features=features,
            footer_text="You received this because you cancelled your FitWiz subscription.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats) if stats.has_any_activity else build_zero_state_row_html(stats),
            category_name="offers",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Cancellation retention email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send cancellation retention email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_trial_expired(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """Trial-expired email — FitWiz voice (transactional) with stats as loss aversion."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        workouts = stats.workouts_total
        workout_word = "workouts" if workouts != 1 else "workout"

        subject = f"Your FitWiz trial just ended, {name}."
        title = f"Your FitWiz trial just ended, {name}"
        subtitle = (
            f"You completed {workouts} {workout_word} during your trial. "
            f"That's real progress. Subscribe now to keep it going."
        )

        features = [
            ("&#128202;", "Pick up where you left off",
             "Your workout plans, history, and coach settings are all still here."),
            ("&#129303;", "Keep your personal coach",
             "Unlimited personalised workouts and coach chat — capped on the free plan."),
            ("&#9889;", "Your momentum is the hardest part",
             f"You built it over your trial. Don't let day 1 back be from zero."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Subscribe now",
            features=features,
            footer_text="You received this because your FitWiz trial ended.",
            persona_signature_html="",  # transactional, no persona card
            stats_row_html=build_stats_grid_html(stats) if stats.has_any_activity else "",
            category_name="offers",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Trial expired email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send trial expired email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    # ────────────────────────────────────────────────────────────────────────
    # Hybrid — FitWiz for billing fact, persona for loss aversion
    # ────────────────────────────────────────────────────────────────────────

    async def send_trial_ending(
        self, to_email: str, first_name_value: str, stats: UserStats,
        days_remaining: int, trial_end_date: str, discount_percent: int = 25,
    ) -> Dict[str, Any]:
        """Trial ending soon — FitWiz opens, persona closes. Uses stats for urgency."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name
        days_word = "days" if days_remaining != 1 else "day"
        workouts = stats.workouts_total

        subject = f"{days_remaining} {days_word} left on your FitWiz trial, {name}."
        title = f"{days_remaining} {days_word} left, {name}"
        subtitle = (
            f"Your trial ends {trial_end_date}. "
            f"You've done {workouts} workouts with {coach} so far — "
            f"{coach} doesn't want to start over with someone new."
        )

        discount_price = f"${49.99 * (1 - discount_percent / 100):.2f}"
        features = [
            ("&#9200;", "Trial expires soon",
             f"After {trial_end_date}, your unlimited coach access and adaptive plans go away."),
            ("&#127947;", f"{workouts} workouts already done",
             "All your progress stays — but without Premium, {coach} stops adapting to it.".replace("{coach}", coach)),
            ("&#127873;", f"Save {discount_percent}% if you lock in now",
             f"Subscribe and pay {discount_price}/year instead of full price. Offer expires when your trial does."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text=f"Subscribe — save {discount_percent}%",
            features=features,
            footer_text="You received this because your FitWiz trial is ending soon.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats) if stats.has_any_activity else "",
            category_name="offers",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Trial ending email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send trial ending email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    # ────────────────────────────────────────────────────────────────────────
    # Motivational — persona voice, stats-driven, time-band aware
    # ────────────────────────────────────────────────────────────────────────

    async def send_streak_at_risk(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """Streak-at-risk nudge. Persona voice, full stats grid including nutrition.

        Assumes caller has validated `stats.current_streak_days >= 2` before
        calling — we don't want to send "protect your 1-day streak" messages.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name
        streak = stats.current_streak_days
        last = stats.last_workout_name or "your last workout"
        days_ago = stats.last_workout_days_ago or 3
        next_name = stats.next_workout_name or "Your Next Workout"

        subject = f"Your {streak}-day streak is worth protecting, {name}"
        title = f"Let's protect this, {name}"
        subtitle = (
            f"{coach} noticed it's been {days_ago} days since {last}. "
            f"{streak} days of work is worth protecting. 20 minutes tonight keeps it alive."
        )

        features = [
            ("&#128293;", f"{streak} days on the board",
             "Streaks are the single best predictor of long-term results. Protect this one."),
            ("&#127947;", f"Up next: {next_name}",
             "Already built. Already waiting. Just tap Start."),
            ("&#9201;", "A short session still counts",
             f"Even 15 minutes keeps the streak alive. {coach} isn't picky about duration — only consistency."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Log a workout now",
            features=features,
            footer_text="You received this because you have streak alerts enabled.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="streak alerts",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Streak at risk email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send streak at risk email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_day3_activation(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """The Day-3 activation email with schedule- and time-aware voice.

        Branches on `stats.schedule_state`:
          - LAUNCHES_TODAY  → anticipatory tone, no guilt (time_band further nuances)
          - OVERDUE         → passive-aggressive guilt, uses days_overdue count
          - LAUNCHES_FUTURE → caller should skip; safety-net "starts soon" variant
          - NO_PLAN         → caller should route to onboarding-incomplete; safety net
          - ON_TRACK        → caller should skip

        Args:
            to_email: recipient
            first_name_value: pre-resolved via `first_name()` helper
            stats: pre-populated via `_get_user_stats()`
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name
        goal = stats.next_workout_goal or "fitness"
        workout_name = stats.next_workout_name or "Your First Workout"

        if stats.schedule_state == ScheduleState.LAUNCHES_TODAY:
            if stats.time_band == TimeBand.MORNING:
                subject = f"{name}, today's the day."
                title = f"Today's the day, {name}"
                subtitle = (
                    f"{coach} built your {goal} plan and it starts today. "
                    f"First session takes about 20 minutes — open the app when you're ready."
                )
            elif stats.time_band in (TimeBand.MIDDAY, TimeBand.AFTERNOON):
                subject = f"{name}, your first workout is today."
                title = f"Your first workout is today, {name}"
                subtitle = (
                    f"{coach} has your {goal} plan ready. "
                    f"Still plenty of time — about 20 minutes is all you need."
                )
            else:
                subject = f"{name}, don't let day one slip."
                title = f"A few hours left, {name}"
                subtitle = (
                    f"{coach} built your {goal} plan for today. "
                    f"One workout tonight keeps day one on the board."
                )
            features = [
                ("&#127919;", "Built for you",
                 f"{workout_name} uses your equipment, your goal, your schedule."),
                ("&#127947;", "About 20 minutes",
                 "Warm-up, main session, cool-down. Form tips on every move."),
                ("&#128241;", "One tap to start",
                 "Your plan is waiting on the home screen. No setup left."),
            ]
            stats_row = build_zero_state_row_html(stats)

        elif stats.schedule_state == ScheduleState.OVERDUE:
            days = stats.days_overdue or 3
            day_word = "day" if days == 1 else "days"
            # Three-tier escalation driven by `coach_style` (gentle/balanced/
            # tough_love). See `_overdue_thresholds()` in email_helpers for the
            # day cutoffs — users who picked "gentle" never see the firm tier;
            # "balanced" gets ~2 weeks of runway before guilt kicks in;
            # "tough_love" escalates within days. Previously a single missed
            # day would trigger "Disappointed" copy regardless of preference.
            tier = overdue_tier(stats)
            if tier == "nudge":
                if days == 1:
                    subject = f"{name}, your plan's waiting."
                    title = f"Your plan started yesterday, {name}"
                else:
                    subject = f"{name}, ready when you are."
                    title = f"Your plan's been ready for {days} {day_word}, {name}"
                subtitle = (
                    f"{coach} built your {goal} plan and it's sitting on the home "
                    f"screen. 20 minutes whenever you're ready — no pressure."
                )
            elif tier == "concerned":
                subject = f"{name}, still want to get started?"
                title = f"It's been {days} {day_word}, {name}"
                subtitle = (
                    f"{coach} checked in on your {goal} plan — still untouched. "
                    f"Life gets in the way. 20 minutes is enough to get day one done."
                )
            else:  # firm
                subject = f"{name}, your {goal} plan is still waiting"
                title = f"Your plan started {days} {day_word} ago, {name}"
                subtitle = (
                    f"{coach} built your {goal} plan on day one — it's ready whenever you are. "
                    f"20 minutes is all it takes. Less time than a lunch break."
                )
            features = [
                ("&#127919;", "Built for you",
                 f"{workout_name} was tailored to your goals and equipment."),
                ("&#127947;", "20 minutes, that's it",
                 "Warm-up, main session, cool-down. Form tips on every move."),
                ("&#128241;", "One tap to start",
                 "Your plan is still waiting on the home screen."),
            ]
            stats_row = build_zero_state_row_html(stats)

        elif stats.schedule_state == ScheduleState.LAUNCHES_FUTURE:
            days = stats.days_until_first_workout or 0
            day_word = "day" if days == 1 else "days"
            subject = f"{name}, your plan starts in {days} {day_word}."
            title = f"Your plan starts in {days} {day_word}, {name}"
            subtitle = f"{coach} has your {goal} plan queued. You'll get a nudge on day one."
            features = [
                ("&#127919;", "Plan's locked in",
                 f"First session — {workout_name} — is on the schedule."),
                ("&#127942;", "Before day one",
                 "Skim the exercises. Watch a demo or two. Get the layout."),
                ("&#128241;", "Open the app anytime",
                 "Your plan is there when you're ready."),
            ]
            stats_row = ""

        else:  # NO_PLAN or ON_TRACK — safety net
            subject = f"{name}, finish setting up your plan."
            title = f"Your plan isn't built yet, {name}"
            subtitle = (
                f"{coach} needs a couple more answers to build your workout plan. "
                f"Two minutes, tops."
            )
            features = [
                ("&#127919;", f"Tell {coach} about you",
                 "Goals, training days, equipment. That's all."),
                ("&#129303;", "Plan generates instantly",
                 "Your full monthly plan builds in seconds."),
                ("&#127947;", "Made for your life",
                 "Your schedule, home or gym, beginner or advanced."),
            ]
            stats_row = ""

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Start my first workout",
            features=features,
            footer_text="You received this because you haven't started your first workout yet.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=stats_row,
            category_name="motivational check-ins",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Day-3 activation email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send day-3 activation email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_onboarding_incomplete(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """Motivational nudge for users who started but didn't finish onboarding.

        Persona voice, no guilt (not yet — they haven't failed anything, just
        stalled). The persona card uses "Watching" mood to reinforce that
        someone's waiting on them.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name

        subject = f"{name}, 2 answers left."
        title = f"You're almost there, {name}"
        subtitle = (
            f"{coach} can't build your plan until you finish the setup. "
            f"Two minutes. That's it."
        )
        features = [
            ("&#127919;", "2 minutes to finish",
             f"Goals, training days, equipment. {coach} only needs what makes your plan yours."),
            ("&#129303;", "Plan generates instantly",
             "Once you finish setup, FitWiz builds your full monthly workout plan in seconds."),
            ("&#127947;", "Built around your life",
             "Your schedule, home or gym, beginner or advanced — every detail is yours."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Finish setup",
            features=features,
            footer_text="You received this because your FitWiz setup is incomplete.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html="",
            category_name="motivational check-ins",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Onboarding incomplete email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send onboarding incomplete email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    # ────────────────────────────────────────────────────────────────────────
    # New email types introduced in the redesign
    # ────────────────────────────────────────────────────────────────────────

    async def send_first_workout_done(
        self, to_email: str, first_name_value: str, stats: UserStats,
        workout_name: str, duration_min: int = 20,
    ) -> Dict[str, Any]:
        """N2. One-shot celebration when the user's first-ever workout is logged.

        Fires inline from the workout-completion endpoint, not from a cron.
        Gated by `workouts_total == 1` (enforced by caller) + `email_send_log`
        dedup with a one-year cooldown (effectively one-shot per user).
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name
        next_name = stats.next_workout_name or "your next session"

        subject = f"Your first workout is in the books, {name}."
        title = f"First one's done, {name}."
        subtitle = (
            f"{coach} saw that. {duration_min} minutes of work that puts you ahead "
            f"of every person who never started."
        )
        features = [
            ("&#127942;", "Day one, cleared",
             "The first workout is the hardest because it's the most decision-heavy. It gets easier."),
            ("&#127947;", f"Up next: {next_name}",
             f"Already scheduled. {coach} adapts the load based on what you just did."),
            ("&#128202;", "Track everything",
             "Weight, reps, rest — the more you log, the sharper the plan gets."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="See my next workout",
            features=features,
            footer_text="You received this because you logged your first workout.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="achievements",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"First-workout-done email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send first-workout-done email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_achievement_unlocked(
        self, to_email: str, first_name_value: str, stats: UserStats,
        achievement_name: str, achievement_description: Optional[str] = None,
    ) -> Dict[str, Any]:
        """N1. Real-time send when a trophy/achievement is granted.

        Rate-limited at the caller (max 1 per 24h). Multiple trophies in a
        single session roll up into one email with the primary one named.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name
        desc = achievement_description or "Another marker on the path."

        subject = f"🏆 {achievement_name}. {coach} saw that, {name}."
        title = f"New trophy, {name}"
        subtitle = f"🏆 {achievement_name} — {desc}"

        features = [
            ("&#127942;", "Earned, not given",
             f"{achievement_name} is on the record. {coach} noticed."),
            ("&#128202;", f"Level {stats.xp_level}",
             f"{stats.xp_total:,} XP total" + (f" · {stats.xp_to_next_level:,} to next level" if stats.xp_to_next_level else "")),
            ("&#128293;", "Momentum compounds",
             "Each trophy is proof of consistency. Consistency is the entire game."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="See all trophies",
            features=features,
            footer_text="You received this because you unlocked a new achievement.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="achievements",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Achievement email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send achievement email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_comeback(
        self, to_email: str, first_name_value: str, stats: UserStats,
        days_gone: int,
    ) -> Dict[str, Any]:
        """N3. Celebrate when a user returns after a ≥7-day gap and logs a workout.

        Persona voice, warm not guilt. Uses lifetime stats as context to reframe
        the gap: "you've done X — one skip doesn't erase that."
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name

        subject = f"Welcome back, {name}. {coach} missed you."
        title = f"Welcome back, {name}"
        subtitle = (
            f"{days_gone} days off the map — and you still came back. "
            f"That's {stats.workouts_total} lifetime workouts. One gap doesn't erase any of them."
        )

        features = [
            ("&#128279;", "Pick up where you were",
             f"{coach} already adjusted the next session's load for the time off."),
            ("&#127947;", f"Up next: {stats.next_workout_name or 'your next session'}",
             "Scheduled, adapted, ready."),
            ("&#128640;", "Day one of the next streak",
             "Every streak starts with a workout after a gap. This is yours."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="See my next workout",
            features=features,
            footer_text="You received this because you came back after a break.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="motivational check-ins",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Comeback email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send comeback email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    # ─── Week-1 Retention Emails (W4) ───────────────────────────────────
    # Day 1/3/5/7 lifecycle emails timed to the exact week-1 churn cliff.

    async def send_week1_day1(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """Day 1 email for users who haven't completed their first workout yet."""
        if not self.is_configured():
            return {"error": "Email service not configured"}
        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        name = first_name_value or "there"
        coach = stats.coach_name or "Your Coach"
        subject = f"{name}, day 1 of your plan is ready"
        features = [
            ("&#127921;", "Your plan is loaded",
             f"{coach} built it around your goals. 20 minutes is all it takes."),
            ("&#128293;", "The first session is the hardest",
             "Once you show up once, the pattern starts. That's the whole game."),
            ("&#128104;&#127996;&#8205;&#127939;&#65039;", "You're not alone",
             f"{coach} is here for the whole journey — not just day 1."),
        ]
        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Day 1, {name}",
            subtitle="Your plan is ready — 20 minutes starts the pattern.",
            cta_text="Open FitWiz",
            features=features,
            footer_text="You received this because you just joined FitWiz.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="onboarding",
        )
        try:
            response = resend.Emails.send({
                "from": self.from_email, "to": [to_email], "subject": subject, "html": html_content,
            })
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"send_week1_day1 failed for {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_week1_day3_completed(
        self, to_email: str, first_name_value: str, stats: UserStats, workouts_count: int,
    ) -> Dict[str, Any]:
        """Day 3 for users who've done at least 1 workout — celebrate + encourage."""
        if not self.is_configured():
            return {"error": "Email service not configured"}
        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        name = first_name_value or "there"
        coach = stats.coach_name or "Your Coach"
        subject = f"{name}, 3 days in — you're building something"
        features = [
            ("&#128170;", f"{workouts_count} workout{'s' if workouts_count != 1 else ''} logged",
             "The hardest part is showing up. You just did it three days in a row."),
            ("&#128200;", "Research says week 1 is the cliff",
             "Users daily-active in week 1 are 80% more likely to stick for 6 months. You're clearing the cliff."),
            ("&#127941;", "Day 4 is waiting",
             f"{coach} has the next session ready — 20 minutes to keep the momentum."),
        ]
        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"3 days in, {name}",
            subtitle="Most people who make it past day 3 are still here in month 3. You're one of them.",
            cta_text="Keep going",
            features=features,
            footer_text="You received this because you're crushing week 1.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="onboarding",
        )
        try:
            response = resend.Emails.send({
                "from": self.from_email, "to": [to_email], "subject": subject, "html": html_content,
            })
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"send_week1_day3_completed failed for {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_week1_day3_stalled(
        self, to_email: str, first_name_value: str, stats: UserStats,
    ) -> Dict[str, Any]:
        """Day 3 for users who haven't started — gentle, compassionate re-engage."""
        if not self.is_configured():
            return {"error": "Email service not configured"}
        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        name = first_name_value or "there"
        coach = stats.coach_name or "Your Coach"
        subject = f"{name}, no judgment — here when you're ready"
        features = [
            ("&#128064;", "Life happens",
             f"{coach} knows day 3 without starting is normal. What matters is the next 20 minutes."),
            ("&#9202;", "10 minutes is enough to restart",
             "Open the app, pick the shortest session. That's all — tomorrow gets easier from there."),
            ("&#127942;", "You still have week 1 to start",
             "The research says week 1 activity predicts 6-month retention. There's still time."),
        ]
        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Ready when you are, {name}",
            subtitle="Your plan is warm. 10 minutes flips the week.",
            cta_text="Start small",
            features=features,
            footer_text="You received this because your plan is still waiting.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="onboarding",
        )
        try:
            response = resend.Emails.send({
                "from": self.from_email, "to": [to_email], "subject": subject, "html": html_content,
            })
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"send_week1_day3_stalled failed for {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_week1_day5(
        self, to_email: str, first_name_value: str, stats: UserStats, workouts_count: int,
    ) -> Dict[str, Any]:
        """Day 5 — halfway through week 1."""
        if not self.is_configured():
            return {"error": "Email service not configured"}
        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        name = first_name_value or "there"
        coach = stats.coach_name or "Your Coach"
        subject = f"{name}, halfway through week one"
        features = [
            ("&#129309;", f"{workouts_count} workout{'s' if workouts_count != 1 else ''} this week so far",
             "Every session is a deposit in the habit bank."),
            ("&#128202;", "Your body is learning the pattern",
             f"{coach} is watching your progress — strength gains kick in around week 2."),
            ("&#127925;", "Day 7 is a milestone",
             "Two more days and you clear the week-1 cliff. Keep the thread going."),
        ]
        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Halfway, {name}",
            subtitle="You're building the pattern that sticks for 6 months. Keep showing up.",
            cta_text="Open FitWiz",
            features=features,
            footer_text="You received this because you're halfway through week 1.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="onboarding",
        )
        try:
            response = resend.Emails.send({
                "from": self.from_email, "to": [to_email], "subject": subject, "html": html_content,
            })
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"send_week1_day5 failed for {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_week1_day7(
        self, to_email: str, first_name_value: str, stats: UserStats, workouts_count: int,
    ) -> Dict[str, Any]:
        """Day 7 — full week-1 celebration recap."""
        if not self.is_configured():
            return {"error": "Email service not configured"}
        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        name = first_name_value or "there"
        coach = stats.coach_name or "Your Coach"
        subject = f"🎉 {name}, week 1 complete"
        features = [
            ("&#127942;", f"{workouts_count} workout{'s' if workouts_count != 1 else ''} this week",
             "You showed up. That's the whole game in week 1."),
            ("&#128293;", "You cleared the cliff",
             "80% of FitWiz users who hit day 7 are still active in month 3. You're officially one of them."),
            ("&#128640;", "Week 2 builds on week 1",
             f"{coach} has next week's plan ready — slightly harder, because you can handle it now."),
        ]
        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Week 1 done, {name}",
            subtitle="The hardest week is behind you. Let's build.",
            cta_text="See my recap",
            features=features,
            footer_text="You received this because you made it through week 1.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="onboarding",
        )
        try:
            response = resend.Emails.send({
                "from": self.from_email, "to": [to_email], "subject": subject, "html": html_content,
            })
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"send_week1_day7 failed for {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    # ─── Merch Milestone Emails (migration 1931) ────────────────────────

    MERCH_DISPLAY_NAMES = {
        "sticker_pack": "FitWiz Sticker Pack",
        "t_shirt": "FitWiz T-Shirt",
        "hoodie": "FitWiz Hoodie",
        "full_merch_kit": "Full Merch Kit (Tee + Hoodie + Shaker)",
        "signed_premium_kit": "Signed Premium Kit",
    }

    async def send_merch_proximity(
        self, to_email: str, first_name_value: str, stats: UserStats,
        merch_type: str, next_level: int, levels_away: int,
    ) -> Dict[str, Any]:
        """User is 1-3 levels from a merch tier. Encourage the final push."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        merch_name = self.MERCH_DISPLAY_NAMES.get(merch_type, merch_type)
        subject = f"🎁 {name}, you're {levels_away} levels from a FREE {merch_name}"

        features = [
            ("&#127873;", f"FREE {merch_name} at Level {next_level}",
             f"Keep earning XP and real FitWiz gear ships to you — on us."),
            ("&#128202;", f"Level {stats.xp_level} · {stats.xp_total:,} XP",
             f"{stats.xp_to_next_level:,} XP to next level" if stats.xp_to_next_level else "Keep pushing."),
            ("&#128293;", "No subscriptions, no catches",
             "Just real merch for real consistency. One tap to accept when you unlock it."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"So close, {name}",
            subtitle=f"{levels_away} levels stand between you and a FREE {merch_name}.",
            cta_text="Open FitWiz",
            features=features,
            footer_text="You received this because you're close to a merch milestone. Manage notifications in Settings.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="achievements",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send merch_proximity email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_merch_unlocked(
        self, to_email: str, first_name_value: str, stats: UserStats,
        merch_type: str, awarded_at_level: int,
    ) -> Dict[str, Any]:
        """User just hit a merch-tier level. Celebrate + CTA to accept in-app."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        merch_name = self.MERCH_DISPLAY_NAMES.get(merch_type, merch_type)
        subject = f"🎁 {name}, your FREE {merch_name} is unlocked!"

        features = [
            ("&#127873;", f"FREE {merch_name} — earned at Level {awarded_at_level}",
             "Real FitWiz gear, shipped to you. No purchase needed."),
            ("&#9989;", "Tap Accept in the Rewards tab",
             "We'll email you when we're ready to ship to collect your size and shipping address."),
            ("&#128293;", f"Level {stats.xp_level} · {stats.xp_total:,} XP",
             "You earned this through consistent work. That's the whole point."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"You did it, {name}",
            subtitle=f"🎁 FREE {merch_name} unlocked at Level {awarded_at_level}",
            cta_text="Accept my reward",
            features=features,
            footer_text="You received this because you unlocked a physical reward.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="achievements",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send merch_unlocked email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_level_milestone_celebration(
        self, to_email: str, first_name_value: str, stats: UserStats,
        level_reached: int, rewards_summary: str, has_merch: bool = False,
    ) -> Dict[str, Any]:
        """Celebrate when user hits a major XP milestone (L5/10/25/50/75/100/...)."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        subject = f"🏅 Level {level_reached} unlocked, {name}"

        features = [
            ("&#127941;", f"Level {level_reached}",
             f"You crossed {stats.xp_total:,} XP total. That's earned, not given."),
            ("&#128230;", "Rewards in your inventory",
             rewards_summary or "New consumables ready to use."),
        ]
        if has_merch:
            features.append((
                "&#127873;", "FREE physical reward",
                "Open Merch Rewards to accept — we'll email you to collect shipping details.",
            ))
        else:
            features.append((
                "&#128640;", "Keep the momentum",
                "The next milestone is closer than you think. One more session.",
            ))

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Level {level_reached}, {name}",
            subtitle=f"You earned every bit of this. {rewards_summary}",
            cta_text="Open my rewards",
            features=features,
            footer_text="You received this because you reached a level milestone.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="achievements",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send level_milestone_celebration to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_merch_claim_reminder(
        self, to_email: str, first_name_value: str, stats: UserStats,
        merch_type: str, awarded_at_level: int, days_waiting: int,
    ) -> Dict[str, Any]:
        """Claim still unaccepted after D+1/D+3/D+7. Reminder to tap Accept."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        merch_name = self.MERCH_DISPLAY_NAMES.get(merch_type, merch_type)
        subject = f"🎁 {name}, your FREE {merch_name} is waiting"

        features = [
            ("&#127873;", f"Your FREE {merch_name} is unclaimed",
             f"Earned at Level {awarded_at_level}, sitting in the Rewards tab for {days_waiting} day{'s' if days_waiting != 1 else ''}."),
            ("&#9989;", "One tap to accept",
             "We'll email you to collect shipping details when it's time to ship."),
            ("&#128064;", "Don't let it expire",
             "Accept it and we'll take it from there."),
        ]

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Still waiting, {name}",
            subtitle=f"Your FREE {merch_name} needs one tap to accept.",
            cta_text="Accept it now",
            features=features,
            footer_text="You received this because you have an unclaimed reward.",
            persona_signature_html=build_persona_signature_html(stats),
            stats_row_html=build_stats_grid_html(stats),
            category_name="achievements",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send merch_claim_reminder email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}
