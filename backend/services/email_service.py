"""
Email service using Resend for sending workout reminders and notifications.

Split into mixins for manageability:
- EmailLifecycleMixin: cancellation_retention, trial_expired, trial_ending,
  streak_at_risk, day3_activation, onboarding_incomplete
- EmailMarketingMixin: win_back, 7day_upsell, weekly_summary

Core methods stay here: welcome, workout_reminder, purchase_confirmation, billing_issue
"""

import os
import json
from datetime import datetime, date
from typing import Optional, List, Dict, Any
import resend

from core import branding
from core.logger import get_logger
from services.email_helpers import build_social_footer_html
from services import email_signature_template as sig

# Emoji → Lucide icon key for the Signature design (zero-emoji rule). Callers pass
# feature rows as (emoji, title, detail); the chokepoint rewrites the emoji to a
# monoline Lucide glyph. Keyed by HTML entity AND raw char; unknown → "sparkles".
EMOJI_TO_ICON = {
    "&#127947;": "dumbbell", "&#128170;": "dumbbell",        # 🏋 💪
    "&#129303;": "message", "&#128172;": "message", "&#129309;": "message",  # 🤗 💬 🤝
    "&#128202;": "bars", "&#128200;": "trending_up",         # 📊 📈
    "&#128293;": "flame", "&#127942;": "trophy", "&#127941;": "medal", "&#127881;": "sparkles",  # 🔥 🏆 🏅 🎉
    "&#127873;": "gift", "&#128230;": "gift", "&#128229;": "mail",  # 🎁 📦 📥
    "&#127919;": "zap", "&#128640;": "zap", "&#128279;": "zap",     # 🎯 🚀 🔗
    "&#128241;": "smartphone", "&#128274;": "lock", "&#128276;": "bell",  # 📱 🔒 🔔
    "&#128737;": "shield", "&#128064;": "user", "&#128104;": "user",      # 🛡 👀 👨
    "&#128179;": "credit_card", "&#127939;": "activity", "&#9888;": "alert",
    "🎁": "gift", "🏆": "trophy", "🏅": "medal", "🎉": "sparkles", "🙄": "user", "💪": "dumbbell",
}

# Import mixins (defined in sibling files)
from services.email_lifecycle import EmailLifecycleMixin
from services.email_marketing import EmailMarketingMixin
from services.email_cancel_ladder import EmailCancelLadderMixin
from services.email_engagement import EmailEngagementMixin
from services.email_security import EmailSecurityMixin
from services.email_lifetime import EmailLifetimeMixin
from services.email_free_tools import EmailFreeToolsMixin

logger = get_logger(__name__)


class EmailService(
    EmailLifecycleMixin,
    EmailMarketingMixin,
    EmailCancelLadderMixin,
    EmailEngagementMixin,
    EmailSecurityMixin,
    EmailLifetimeMixin,
    EmailFreeToolsMixin,
):
    """Service for sending emails via Resend.

    Core transactional methods are defined here (welcome, workout_reminder,
    purchase_confirmation, billing_issue). Everything else lives in a mixin:
    - EmailLifecycleMixin: trial / streak / day-3 / onboarding / N1/N2/N3
    - EmailMarketingMixin: win-back / 14-day upsell / weekly summary
    - EmailCancelLadderMixin: C1-C7 post-cancel re-engagement
    - EmailEngagementMixin: idle-nudge / one-workout-wonder / premium-idle / welcome-back
    - EmailSecurityMixin: new-device sign-in alerts (cannot be opted out of)
    """

    def __init__(self):
        """Initialize the Resend client with API key from environment."""
        self.api_key = os.getenv("RESEND_API_KEY")
        if not self.api_key:
            logger.warning("RESEND_API_KEY not found in environment variables")
        else:
            resend.api_key = self.api_key
            logger.info("Email service initialized with Resend")

        # Default sender email (must be verified in Resend)
        # Default falls back to a derived literal if RESEND_FROM_EMAIL is unset.
        # Centralized in core.branding so a rename only edits one constant.
        self.from_email = os.getenv(
            "RESEND_FROM_EMAIL",
            f"{branding.APP_NAME} <onboarding@resend.dev>",
        )

    def is_configured(self) -> bool:
        """Check if the email service is properly configured."""
        return bool(self.api_key)

    async def send_welcome_email(
        self,
        to_email: str,
        first_name: str,
        goal: Optional[str] = None,
        days_per_week: Optional[int] = None,
        weight_kg: Optional[float] = None,
        goal_weight_kg: Optional[float] = None,
        weight_direction: Optional[str] = None,
        daily_calories: Optional[int] = None,
        protein_g: Optional[int] = None,
        carbs_g: Optional[int] = None,
        fat_g: Optional[int] = None,
        first_workout_name: Optional[str] = None,
        first_workout_duration: Optional[int] = None,
        first_workout_exercises: Optional[List[Dict[str, Any]]] = None,
        training_days: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Send the founder-voice welcome email AFTER onboarding completes.

        This fires once the user has finished onboarding (profile + quiz +
        first plan generation) so we can show real numbers — macros,
        tomorrow's workout, the schedule strip — instead of "Welcome, there."

        Brand palette: cyan→orange gradient (matches docs/auth-emails/
        confirm_signup.html). CTA is solid orange #F97316 with black text.
        """
        if not self.is_configured():
            logger.error("Cannot send welcome email - Resend API key not configured")
            return {"error": "Email service not configured"}

        from core.config import get_settings
        logo_url = get_settings().email_logo_url
        # Web fallback that triggers the universal link → app.
        # See /docs/auth-emails/auth-callback.html for the redirect pattern.
        open_url = "https://zealova.com/open"

        # ── 1. Compute display name (first-name only, with fallback) ─────────
        display_first = (first_name or "").strip().split(" ")[0] if first_name else ""

        # ── 2. Compute lead copy from goal + weight delta ────────────────────
        # Mirrors mobile/flutter/lib/screens/auth/sign_in_screen.dart:725-770.
        lead_text: str
        delta_lb: Optional[int] = None
        if (
            weight_kg is not None
            and goal_weight_kg is not None
            and weight_kg > 0
            and goal_weight_kg > 0
        ):
            try:
                delta_lb = int(round(abs(float(weight_kg) - float(goal_weight_kg)) * 2.20462))
            except (TypeError, ValueError):
                delta_lb = None

        if delta_lb is not None and delta_lb >= 1:
            # Direction: prefer explicit weight_direction, else infer from delta.
            losing = (
                (weight_direction or "").lower() == "lose"
                or (
                    weight_direction is None
                    and weight_kg is not None
                    and goal_weight_kg is not None
                    and weight_kg > goal_weight_kg
                )
            )
            verb = "drop" if losing else "put on"
            lead_text = (
                f"I built your plan to {verb} {delta_lb} lb. "
                "Save it and let's start tomorrow."
            )
        else:
            goal_l = (goal or "").lower().strip()
            goal_map = {
                "muscle": "I built you a plan to put on real muscle.",
                "strength": "I built you a plan to get stronger every week.",
                "endurance": "I built you a plan to outlast everyone.",
                "active": "I built you a plan to actually keep moving.",
                "athletic": "I built you a plan to perform like an athlete.",
            }
            base = goal_map.get(
                goal_l, "Your plan is ready and shaped around what you told me."
            )
            lead_text = f"{base} Save it and let's start tomorrow."

        # ── 3. Headline + subject ────────────────────────────────────────────
        if display_first:
            headline = f"Hey {display_first}."
            subject = f"{display_first}, your plan is ready."
        else:
            headline = "Hey,"
            subject = f"Your {branding.APP_NAME} plan is ready."

        # ── 4. Macro grid (Signature 4-up card, only if all four present) ────
        macros_inner = ""
        if all(v is not None for v in (daily_calories, protein_g, carbs_g, fat_g)):
            def _mt(value: str, label: str) -> str:
                return (
                    f'<td width="25%" style="padding:4px;"><div style="background:{sig.CARD};'
                    f'border:1px solid {sig.LINE};border-radius:14px;padding:14px 4px;text-align:center;">'
                    f'<div style="font-family:{sig.F_DISP};font-size:20px;color:{sig.INK};">{value}</div>'
                    f'<div style="font-family:{sig.F_LBL};text-transform:uppercase;letter-spacing:1px;'
                    f'font-size:10px;color:{sig.GREY};margin-top:4px;">{label}</div></div></td>'
                )
            macros_inner = (
                '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>'
                f'{_mt(str(daily_calories), "Cal")}{_mt(f"{protein_g}g", "Protein")}'
                f'{_mt(f"{carbs_g}g", "Carbs")}{_mt(f"{fat_g}g", "Fat")}</tr></table>'
            )

        # ── 5. Tomorrow's workout card + full-list (for the accordion) ───────
        tomorrow_inner = ""
        full_workout_inner = ""
        if first_workout_name:
            dur = f" · {first_workout_duration} min" if first_workout_duration else ""
            tomorrow_inner = (
                f'<div style="background:{sig.CARD};border:1px solid {sig.LINE};border-radius:16px;'
                f'padding:18px 20px;">'
                f'<div style="font-family:{sig.F_LBL};text-transform:uppercase;letter-spacing:2px;'
                f'font-size:11px;color:{sig.ACCENT};margin-bottom:6px;">Tomorrow</div>'
                f'<div style="font-family:{sig.F_DISP};font-size:20px;color:{sig.INK};'
                f'letter-spacing:.4px;">{first_workout_name}{dur}</div></div>'
            )
            exs = [e for e in (first_workout_exercises or []) if isinstance(e, dict)]
            for i, ex in enumerate(exs, start=1):
                ename = ex.get("name") or "Exercise"
                sets, reps = ex.get("sets"), ex.get("reps")
                if sets and reps:
                    detail = f"{sets} × {reps}"
                elif reps:
                    detail = f"{reps} reps"
                elif sets:
                    detail = f"{sets} sets"
                else:
                    detail = ""
                det = f' <span style="color:{sig.GREY};">· {detail}</span>' if detail else ""
                full_workout_inner += (
                    f'<div style="font-family:{sig.F_LBL};font-size:14.5px;color:#e4e4e7;'
                    f'line-height:1.95;letter-spacing:.3px;">'
                    f'<span style="color:{sig.ACCENT};font-weight:700;">{i}.</span> {ename}{det}</div>'
                )

        # ── 6. 7-day schedule strip (skip if no training_days) ───────────────
        schedule_html = ""
        if training_days:
            day_keys = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
            day_labels = ["M", "T", "W", "T", "F", "S", "S"]
            # Normalise the user's training_days entries to lowercase 3-letter keys.
            normalised = set()
            for d in training_days:
                if not d:
                    continue
                k = str(d).strip().lower()[:3]
                # Some callers pass "monday" → "mon"; some pass weekday integers.
                if k in day_keys:
                    normalised.add(k)
                else:
                    # Tolerate full-word variants we didn't slice cleanly.
                    full = str(d).strip().lower()
                    for short in day_keys:
                        if full.startswith(short):
                            normalised.add(short)
                            break
            pills = []
            for key, label in zip(day_keys, day_labels):
                if key in normalised:
                    style = (
                        f"display:inline-block;background:{sig.ACCENT};color:{sig.BG};"
                        f"font-family:{sig.F_DISP};width:34px;height:34px;line-height:34px;"
                        "border-radius:50%;text-align:center;font-size:13px;margin:0 3px;"
                    )
                else:
                    style = (
                        f"display:inline-block;color:{sig.FAINT};font-family:{sig.F_LBL};"
                        "font-weight:700;width:34px;height:34px;line-height:32px;"
                        f"border-radius:50%;text-align:center;font-size:13px;margin:0 3px;"
                        f"border:1px solid {sig.TRACK};"
                    )
                pills.append(f'<span style="{style}">{label}</span>')
            week_inner = (
                '<div style="text-align:center;padding:6px 0 2px;font-size:0;">'
                f'{"".join(pills)}</div>'
            )
        else:
            week_inner = ""

        # ── 7. Coach quote (always shown; generic Zealova voice for now) ─────
        coach_quote = "Show up tomorrow. Future-you is watching."

        # ── 8. Final HTML assembly (Signature design) ────────────────────────
        panels = []
        if tomorrow_inner:
            panels.append(("Today", tomorrow_inner))
        if macros_inner:
            panels.append(("Nutrition", macros_inner))
        if week_inner:
            panels.append(("This week", week_inner))

        body = sig.callout(lead_text)
        # Interactive tabs when ≥2 sections exist; single section renders plain;
        # both degrade gracefully (Gmail/Outlook stack all panels — see KINETIC_CSS).
        if len(panels) >= 2:
            body += sig.tabs(panels, uid="wel")
        elif panels:
            body += f'<tr><td style="padding:14px 22px 0;">{panels[0][1]}</td></tr>'
        if full_workout_inner:
            body += sig.accordion("See full workout", full_workout_inner, "welwk")
        body += sig.coach_card("Zealova", coach_quote)
        body += sig.info_rows([
            ("dumbbell", "Your workout plan, built for you",
             "Personalised monthly plans built around your goals, schedule, and equipment."),
            ("message", "Your 24/7 coach",
             "Ask anything — form tips, nutrition advice, or swap an exercise — anytime."),
            ("trending_up", "Track your evolution",
             "Log sets, see your strength curve, and watch your body transform week by week."),
        ])
        body += sig.pill_cta(f"Open {branding.APP_NAME}", open_url)

        greeting_line = f"Hey, {display_first}." if display_first else "Hey there."
        html_content = sig.signature_email(
            header_tag="Welcome",
            greeting=greeting_line,
            greeting_sub="Your plan is ready",
            avatar=(display_first[:1] if display_first else "Z"),
            body_html=body,
            preheader=lead_text,
            footer_kind="transactional",
            footer_note=f"You received this because you finished onboarding your {branding.APP_NAME} account.",
            footer_socials=True,
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Welcome email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send welcome email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_workout_reminder(
        self, to_email: str, first_name_value: str, stats,
        workout_name: str, workout_type: str, scheduled_date: date,
        exercises: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """Workout reminder email — persona voice, stats grid, full social footer.

        Brought under the standard-email template so it inherits the social
        footer, persona signature, and design system. Imports UserStats locally
        to avoid circular-import risk between email_service and email_helpers.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        # Local imports: avoid importing models.email at module top since this
        # file is imported early in app startup and model imports could fan out.
        from services.email_helpers import build_persona_signature_html, build_stats_grid_html

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = get_settings().email_logo_url
        open_url = f"{backend_url}/open"

        name = first_name_value or "there"
        coach = stats.coach_name if stats else "Your Coach"
        formatted_date = scheduled_date.strftime("%A, %B %d")

        # Build exercise preview (top 3 for subtitle)
        preview_names = [e.get("name", "move") for e in exercises[:3]]
        preview_line = ", ".join(preview_names)
        if len(exercises) > 3:
            preview_line += f" · +{len(exercises) - 3} more"

        subject = f"{name}. {workout_name}. {formatted_date}."
        title = f"{workout_name}, {name}"
        subtitle = (
            f"{coach} has you down for {workout_type.replace('_', ' ')} today: "
            f"{preview_line}. Keep it simple — one set at a time."
        )

        # Build exercise feature blocks (up to 3, compact)
        features = []
        for exercise in exercises[:3]:
            ename = exercise.get("name", "Exercise")
            sets = exercise.get("sets", 3)
            reps = exercise.get("reps", 10)
            features.append((
                "&#127947;", ename, f"{sets} sets × {reps} reps",
            ))
        if len(exercises) > 3:
            features.append((
                "&#128202;", f"+{len(exercises) - 3} more exercises",
                "See the full workout in the app. Warm-up and cool-down included.",
            ))

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=title, subtitle=subtitle,
            cta_text="Start workout",
            features=features or [("&#127947;", workout_name, "Open the app to see the full workout.")],
            footer_text="You received this because you have workout reminders enabled.",
            persona_signature_html=build_persona_signature_html(stats) if stats else "",
            stats_row_html=build_stats_grid_html(stats) if stats else "",
            category_name="workout reminders",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Workout reminder sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send workout reminder to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_purchase_confirmation(
        self, to_email: str, user_name: str, tier: str,
        price_paid: float, currency: str = "USD",
    ) -> Dict[str, Any]:
        """Send a purchase confirmation email after a successful subscription upgrade."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = get_settings().email_logo_url
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"
        tier_label = tier.replace("_", " ").title()

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"You're in, {display_name}",
            subtitle=f"Your {branding.APP_NAME} {tier_label} plan is now active. {price_paid} {currency} charged. Your coach is unlimited from here.",
            cta_text=f"Open {branding.APP_NAME}",
            features=[
                ("&#127947;", "Unlimited workouts", "Generate new plans anytime. Your coach adapts to your progress every week."),
                ("&#129303;", "Priority coach access", "Unlimited chat with your personal coach. No daily limits, no waiting."),
                ("&#128200;", "Advanced analytics", "Deep performance metrics, strength curves, and body composition tracking."),
            ],
            footer_text=f"You received this because you upgraded your {branding.APP_NAME} plan.",
            header_tag="Receipt",
            hero_icon="check_circle",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"You're in, {display_name}. {branding.APP_NAME} {tier_label} is active.", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Purchase confirmation email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send purchase confirmation email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_billing_issue(
        self, to_email: str, user_name: str, tier: str,
    ) -> Dict[str, Any]:
        """Send a billing issue / payment failed email."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = get_settings().email_logo_url
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"
        tier_label = tier.replace("_", " ").title()

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"{display_name}, your {branding.APP_NAME} access is paused",
            subtitle=f"We couldn't process your payment for {branding.APP_NAME} {tier_label}. Update your payment method to keep your plan active.",
            cta_text="Update payment",
            features=[
                ("&#9888;", "Access paused until resolved", f"Once your payment method is updated, {branding.APP_NAME} resumes immediately."),
                ("&#128179;", "Quick fix via the app store", "Open the App Store / Google Play, go to Subscriptions, update your card."),
                ("&#128737;", "Your data is safe", "All workout history, progress photos, and plans are saved and waiting."),
            ],
            footer_text="You received this because your payment failed.",
            header_tag="Billing",
            hero_icon="alert",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"{display_name}, your {branding.APP_NAME} access is paused", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Billing issue email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send billing issue email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_verification_email(
        self, to_email: str, first_name: str, verify_url: str,
        plan: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Branded email-verification email.

        Transactional/security mail — it is sent regardless of notification
        preferences (there is no opt-out for verifying your own account).

        `plan` (optional) carries the onboarding answers the user gave before the
        email step (goal / experience / days / weight target). When present, a
        "Your plan so far" recap card is rendered so the email reinforces value,
        not just asks for a verification tap.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        logo_url = get_settings().email_logo_url

        # At email-signup the name isn't collected yet (we ask it on the next
        # screen), so first_name is empty / the legacy "there" placeholder. A
        # wrong fallback name reads worse than none — drop it entirely.
        name = (first_name or "").strip()
        if name.lower() in ("", "there", "user"):
            name = ""
        subject = f"Verify your {branding.APP_NAME} email"
        title = f"Verify your email, {name}" if name else "Verify your email"
        subtitle = (
            "Tap the button below to confirm this is your email. It keeps your "
            "account secure and makes sure your trial reminders and coaching "
            "updates actually reach you."
        )
        features = [
            ("&#128274;", "Keeps your account secure",
             "Confirms this inbox is yours, so a password reset always reaches you."),
            ("&#128276;", "Never miss a reminder",
             "Trial reminders and coaching updates land in the right inbox."),
        ]
        plan_card = sig.plan_recap(self._plan_recap_rows(plan))
        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=verify_url,
            title=title, subtitle=subtitle,
            cta_text="Verify my email",
            features=features,
            body_after_cta_html=plan_card,
            footer_text=(
                f"You received this because an account was created with this "
                f"email on {branding.APP_NAME}. If that was not you, you can "
                f"safely ignore this message."
            ),
            header_tag="Account",
            hero_icon="mail",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": subject, "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Verification email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send verification email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    # Humanized labels for the common goal keys. Unknown keys fall back to a
    # Title-cased version of the raw key (no brittle whitelist — display-only).
    _GOAL_LABELS = {
        "build_muscle": "Build muscle", "gain_muscle": "Build muscle",
        "muscle_gain": "Build muscle", "hypertrophy": "Build muscle",
        "lose_weight": "Lose weight", "weight_loss": "Lose weight",
        "lose_fat": "Lose fat", "fat_loss": "Lose fat",
        "get_stronger": "Get stronger", "strength": "Get stronger",
        "build_strength": "Get stronger", "gain_strength": "Get stronger",
        "improve_endurance": "Improve endurance", "endurance": "Improve endurance",
        "cardio": "Improve endurance", "general_fitness": "General fitness",
        "stay_fit": "Stay fit", "tone_up": "Tone up", "toning": "Tone up",
        "athletic_performance": "Athletic performance", "performance": "Athletic performance",
        "flexibility": "Flexibility & mobility", "mobility": "Flexibility & mobility",
    }

    @staticmethod
    def _plan_recap_rows(plan: Optional[Dict[str, Any]]) -> List[tuple]:
        """Map onboarding answers → (icon_key, label, value) rows for `sig.plan_recap`.
        Best-effort: only includes rows whose data is present; returns [] when there
        is nothing usable (so the recap card is omitted entirely)."""
        if not plan:
            return []
        rows: List[tuple] = []

        goal = str(plan.get("goal") or "").strip()
        if goal:
            gl = goal.lower()
            label = EmailService._GOAL_LABELS.get(
                gl, goal.replace("_", " ").replace("-", " ").strip().title()
            )
            icon = "dumbbell"
            if "lose" in gl or "fat" in gl or ("weight" in gl and "loss" in gl):
                icon = "flame"
            elif "endur" in gl or "cardio" in gl or "run" in gl:
                icon = "activity"
            elif "flex" in gl or "mobil" in gl:
                icon = "leaf"
            rows.append((icon, "Goal", label))

        level = str(plan.get("fitness_level") or "").strip()
        if level:
            rows.append(("trending_up", "Experience", level.replace("_", " ").title()))

        days = plan.get("days_per_week")
        try:
            days = int(days) if days is not None else None
        except (TypeError, ValueError):
            days = None
        if days and days > 0:
            unit = "day" if days == 1 else "days"
            rows.append(("calendar", "Training", f"{days} {unit} / week"))

        # Weight target in lb (US-dominant audience / app's primary display unit).
        # Only when a lose/gain direction + a target weight are both present.
        direction = str(plan.get("weight_direction") or "").strip().lower()
        goal_kg = plan.get("goal_weight_kg")
        try:
            goal_kg = float(goal_kg) if goal_kg is not None else None
        except (TypeError, ValueError):
            goal_kg = None
        if direction in ("lose", "gain") and goal_kg and goal_kg > 0:
            rows.append(("scale", "Target weight", f"{round(goal_kg * 2.2046)} lb"))

        return rows

    @staticmethod
    def _feature_icon(emoji: str) -> str:
        """Map a feature-row emoji (HTML entity or raw char) to a Lucide key."""
        return EMOJI_TO_ICON.get((emoji or "").strip(), "sparkles")

    def _build_standard_email(
        self, logo_url: str, open_url: str, title: str, subtitle: str,
        cta_text: str, features: List[tuple], footer_text: str,
        *,
        persona_signature_html: str = "",
        stats_row_html: str = "",
        body_after_cta_html: str = "",
        unsubscribe_url: Optional[str] = None,
        category_name: Optional[str] = None,
        header_tag: str = "",
        hero_icon: str = "",
    ) -> str:
        """Build a standard Zealova email on the **Signature design**.

        This is the chokepoint every standard email routes through — verification,
        billing, purchase, workout reminder, and all lifecycle / cancel-ladder /
        engagement / standard-marketing emails. Rewriting it here converts them all
        to the Signature look at once (orange rail, ZEALOVA lockup, Anton hero,
        Barlow/Fraunces, monoline Lucide icons, zero emoji) via
        `email_signature_template` (`sig`).

        The parameter shape is unchanged so callers don't change. Mapping:
          - title/subtitle → centered Anton hero (`sig.hero`).
          - features (emoji, title, desc) → `sig.info_rows`, emoji rewritten to Lucide.
          - cta_text + open_url → `sig.pill_cta` (with :hover).
          - persona_signature_html / stats_row_html → injected as-is (re-paletted in
            email_helpers to match the Signature chrome).
          - footer: opt-out variant when unsubscribe_url+category_name are given
            (lifecycle/marketing), else a transactional note (footer_text).

        Args:
            logo_url: retained for back-compat; unused (Signature uses the typographic
                ZEALOVA lockup, not an 88px logo image).
            header_tag: short top-right tag ("Account", "Billing"); defaults from
                category_name or "Account".
            hero_icon: optional Lucide key for the hero icon chip.
        """
        rows = [(self._feature_icon(emoji), t, d) for (emoji, t, d) in features]

        body = persona_signature_html + stats_row_html
        if cta_text and open_url:
            body += sig.pill_cta(cta_text, open_url)
        body += body_after_cta_html
        body += sig.info_rows(rows)

        is_pref = bool(unsubscribe_url and category_name)
        tag = header_tag or (category_name.title() if category_name else "Account")
        return sig.signature_email(
            header_tag=tag,
            hero_title=title,
            hero_sub=subtitle,
            hero_icon=hero_icon,
            body_html=body,
            unsubscribe_url=unsubscribe_url,
            category_label=category_name or "updates",
            footer_kind="preference" if is_pref else "transactional",
            footer_note="" if is_pref else footer_text,
        )

    # Lifecycle email methods (cancellation_retention, trial_expired, trial_ending,
    # streak_at_risk, day3_activation, onboarding_incomplete) are inherited from
    # EmailLifecycleMixin in services/email_lifecycle.py.
    #
    # Marketing email methods (win_back, 7day_upsell, weekly_summary) are inherited
    # from EmailMarketingMixin in services/email_marketing.py.


# Singleton instance
_email_service: Optional[EmailService] = None


def get_email_service() -> EmailService:
    """Get or create the email service singleton."""
    global _email_service
    if _email_service is None:
        _email_service = EmailService()
    return _email_service
