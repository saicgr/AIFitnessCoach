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

# Import mixins (defined in sibling files)
from services.email_lifecycle import EmailLifecycleMixin
from services.email_marketing import EmailMarketingMixin
from services.email_cancel_ladder import EmailCancelLadderMixin
from services.email_engagement import EmailEngagementMixin
from services.email_security import EmailSecurityMixin
from services.email_lifetime import EmailLifetimeMixin

logger = get_logger(__name__)


class EmailService(
    EmailLifecycleMixin,
    EmailMarketingMixin,
    EmailCancelLadderMixin,
    EmailEngagementMixin,
    EmailSecurityMixin,
    EmailLifetimeMixin,
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

        # ── 4. Macro grid (4 pills, only if all four values present) ─────────
        macros_html = ""
        if all(v is not None for v in (daily_calories, protein_g, carbs_g, fat_g)):
            pill = (
                "display:inline-block;background:#1a1a1a;border:1px solid #2a2a2a;"
                "border-radius:14px;padding:14px 6px;text-align:center;width:22%;"
                "box-sizing:border-box;margin:0 1%;vertical-align:top;"
            )
            label_style = "margin:0;font-size:11px;color:#71717a;letter-spacing:1.2px;text-transform:uppercase;"
            value_style = "margin:4px 0 0;font-size:18px;font-weight:800;color:#ffffff;"
            macros_html = f"""
          <tr>
            <td style="padding:0 32px 8px;">
              <p style="margin:0 0 12px;font-size:13px;font-weight:700;color:#F97316;letter-spacing:1.5px;text-transform:uppercase;text-align:center;">Your daily targets</p>
              <div style="text-align:center;font-size:0;">
                <div style="{pill}">
                  <p style="{value_style}">{daily_calories}</p>
                  <p style="{label_style}">cal</p>
                </div>
                <div style="{pill}">
                  <p style="{value_style}">{protein_g}g</p>
                  <p style="{label_style}">protein</p>
                </div>
                <div style="{pill}">
                  <p style="{value_style}">{carbs_g}g</p>
                  <p style="{label_style}">carbs</p>
                </div>
                <div style="{pill}">
                  <p style="{value_style}">{fat_g}g</p>
                  <p style="{label_style}">fat</p>
                </div>
              </div>
            </td>
          </tr>"""

        # ── 5. Tomorrow's workout block (skip if no name) ────────────────────
        tomorrow_html = ""
        if first_workout_name:
            duration_part = (
                f" ({first_workout_duration} min)"
                if first_workout_duration
                else ""
            )
            ex_lines_html = ""
            for i, ex in enumerate((first_workout_exercises or [])[:3], start=1):
                if not isinstance(ex, dict):
                    continue
                ename = ex.get("name") or "Exercise"
                sets = ex.get("sets")
                reps = ex.get("reps")
                if sets and reps:
                    detail = f"{sets} × {reps}"
                elif reps:
                    detail = f"{reps} reps"
                elif sets:
                    detail = f"{sets} sets"
                else:
                    detail = ""
                detail_html = (
                    f' <span style="color:#71717a;">· {detail}</span>'
                    if detail
                    else ""
                )
                ex_lines_html += (
                    f'<p style="margin:6px 0;font-size:14px;color:#e4e4e7;line-height:1.55;">'
                    f'<span style="color:#F97316;font-weight:700;">{i}.</span> '
                    f'{ename}{detail_html}</p>'
                )
            tomorrow_html = f"""
          <tr>
            <td style="padding:8px 32px 8px;">
              <div style="background:#0a0a0a;border:1px solid #1a1a1a;border-radius:16px;padding:20px 22px;">
                <p style="margin:0 0 6px;font-size:11px;font-weight:700;color:#FB923C;letter-spacing:1.5px;text-transform:uppercase;">Tomorrow</p>
                <h3 style="margin:0 0 12px;font-size:18px;font-weight:800;color:#ffffff;line-height:1.3;">{first_workout_name}{duration_part}</h3>
                {ex_lines_html or '<p style="margin:0;font-size:14px;color:#71717a;">Open the app to see the full workout.</p>'}
              </div>
            </td>
          </tr>"""

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
                        "display:inline-block;background:#F97316;color:#000000;"
                        "font-weight:800;width:36px;height:36px;line-height:36px;"
                        "border-radius:50%;text-align:center;font-size:14px;margin:0 3px;"
                    )
                else:
                    style = (
                        "display:inline-block;background:transparent;color:#52525b;"
                        "font-weight:600;width:36px;height:36px;line-height:34px;"
                        "border-radius:50%;text-align:center;font-size:14px;margin:0 3px;"
                        "border:1px solid #2a2a2a;"
                    )
                pills.append(f'<span style="{style}">{label}</span>')
            schedule_html = f"""
          <tr>
            <td align="center" style="padding:8px 32px 4px;">
              <p style="margin:0 0 12px;font-size:11px;font-weight:700;color:#71717a;letter-spacing:1.5px;text-transform:uppercase;">Your week</p>
              <div style="text-align:center;font-size:0;">{''.join(pills)}</div>
            </td>
          </tr>"""

        # ── 7. Coach quote (always shown) ────────────────────────────────────
        # TODO: read users.ai_coach_persona to personalise the voice. For now
        # use a generic Zealova line so the email never ships without a quote.
        coach_quote_html = """
          <tr>
            <td align="center" style="padding:20px 40px 8px;">
              <p style="margin:0;font-size:14px;font-style:italic;color:#a1a1aa;line-height:1.6;text-align:center;">&ldquo;Show up tomorrow. Future-you is watching.&rdquo;</p>
            </td>
          </tr>"""

        # ── 8. Final HTML assembly ───────────────────────────────────────────
        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{subject}</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">
          <tr>
            <td style="background:linear-gradient(135deg,#06b6d4 0%,#FB923C 50%,#F97316 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>
          <tr>
            <td align="center" style="padding:48px 40px 24px;">
              <img src="{logo_url}" alt="{branding.APP_NAME}" width="88" height="88" style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:18px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#F97316;">{branding.APP_NAME.upper()}</p>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding:0 40px 8px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">{headline}</h1>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding:8px 48px 24px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">{lead_text}</p>
            </td>
          </tr>
          {macros_html}
          {tomorrow_html}
          {schedule_html}
          {coach_quote_html}
          <tr>
            <td align="center" style="padding:24px 40px 40px;">
              <a href="{open_url}" style="display:inline-block;background:#F97316;color:#000000;font-size:16px;font-weight:800;text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">Open {branding.APP_NAME}</a>
            </td>
          </tr>
          <tr><td style="padding:0 32px;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr></table></td></tr>
          <tr>
            <td style="padding:36px 40px 16px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:24px;"><tr><td width="48" valign="top"><div style="width:40px;height:40px;background:#2a1505;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">&#127947;</div></td><td style="padding-left:16px;" valign="top"><p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Your workout plan, built for you</p><p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Personalised monthly plans built around your goals, schedule, and equipment.</p></td></tr></table>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:24px;"><tr><td width="48" valign="top"><div style="width:40px;height:40px;background:#2a1505;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">&#129303;</div></td><td style="padding-left:16px;" valign="top"><p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Your 24/7 coach</p><p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Ask anything &mdash; form tips, nutrition advice, or swap an exercise &mdash; anytime.</p></td></tr></table>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;"><tr><td width="48" valign="top"><div style="width:40px;height:40px;background:#2a1505;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">&#128200;</div></td><td style="padding-left:16px;" valign="top"><p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Track your evolution</p><p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Log sets, see your strength curve, and watch your body transform week by week.</p></td></tr></table>
            </td>
          </tr>
          <tr><td style="padding:24px 40px 0;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr></table></td></tr>
          <tr>
            <td align="center" style="padding:24px 40px 12px;">
              <p style="margin:0 0 8px;font-size:15px;font-weight:700;color:#ffffff;">Join the community</p>
              <p style="margin:0 0 20px;font-size:14px;color:#71717a;line-height:1.5;">Get help, share progress, and hang out with other {branding.APP_NAME} users.</p>
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin:0 auto;">
                <tr>
                  <td style="padding:0 6px;">
                    <a href="https://discord.gg/WAYNZpVgsK" style="display:inline-block;background:#5865F2;color:#ffffff;font-size:14px;font-weight:700;text-decoration:none;padding:10px 22px;border-radius:50px;line-height:20px;">
                      <img src="https://cdn.simpleicons.org/discord/ffffff" alt="" width="16" height="16" style="display:inline-block;vertical-align:middle;margin-right:8px;border:0;" />
                      <span style="vertical-align:middle;">Discord</span>
                    </a>
                  </td>
                  <td style="padding:0 6px;">
                    <a href="{branding.INSTAGRAM_URL}" style="display:inline-block;background:linear-gradient(135deg,#833AB4,#FD1D1D,#FCB045);color:#ffffff;font-size:14px;font-weight:700;text-decoration:none;padding:10px 22px;border-radius:50px;line-height:20px;">
                      <img src="https://cdn.simpleicons.org/instagram/ffffff" alt="" width="16" height="16" style="display:inline-block;vertical-align:middle;margin-right:8px;border:0;" />
                      <span style="vertical-align:middle;">Instagram</span>
                    </a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr><td style="padding:24px 40px 0;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr></table></td></tr>
          <tr>
            <td align="center" style="padding:24px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">{branding.APP_NAME} &mdash; Your Personal Training Assistant</p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">You received this because you finished onboarding your {branding.APP_NAME} account.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""

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
            category_name="billing & account",
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
            category_name="billing & account",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"{display_name}, your {branding.APP_NAME} access is paused", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Billing issue email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send billing issue email to {to_email}: {e}", exc_info=True)
            return {"error": str(e)}

    def _build_standard_email(
        self, logo_url: str, open_url: str, title: str, subtitle: str,
        cta_text: str, features: List[tuple], footer_text: str,
        *,
        persona_signature_html: str = "",
        stats_row_html: str = "",
        unsubscribe_url: Optional[str] = None,
        category_name: Optional[str] = None,
    ) -> str:
        """Build a standard Zealova email template with consistent styling.

        Args:
            logo_url: URL to the Zealova logo
            open_url: URL for CTA button
            title: Email headline
            subtitle: Email subheadline
            cta_text: CTA button text
            features: List of (emoji_code, feature_title, feature_desc) tuples
            footer_text: Footer explanation text
            persona_signature_html: Optional <tr> from build_persona_signature_html;
                motivational emails inject a coach-name + mood card here.
            stats_row_html: Optional <tr> with a zero-state line or 2x2 stats grid.
            unsubscribe_url: Optional per-category unsubscribe link for the footer.
            category_name: Human label ("streak alerts") for the unsubscribe line.

        Returns:
            Complete HTML email string.
        """
        features_html = ""
        for i, (emoji, feat_title, feat_desc) in enumerate(features):
            margin = "margin-bottom:28px;" if i < len(features) - 1 else "margin-bottom:8px;"
            features_html += f"""
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="{margin}">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">{emoji}</div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">{feat_title}</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">{feat_desc}</p>
                  </td>
                </tr>
              </table>"""

        return f"""<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#000000;min-height:100vh;">
    <tr><td align="center" style="padding:40px 16px;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">
          <tr><td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td></tr>
          <tr><td align="center" style="padding:48px 40px 24px;"><img src="{logo_url}" alt="{branding.APP_NAME}" width="88" height="88" style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;"><p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">{branding.APP_NAME.upper()}</p></td></tr>
          {persona_signature_html}
          <tr><td align="center" style="padding:24px 40px 12px;"><h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">{title}</h1></td></tr>
          <tr><td align="center" style="padding:0 48px 20px;"><p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">{subtitle}</p></td></tr>
          {stats_row_html}
          <tr><td align="center" style="padding:28px 40px 40px;"><a href="{open_url}" style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">{cta_text}</a></td></tr>
          <tr><td style="padding:0 32px;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr></table></td></tr>
          <tr><td style="padding:40px 40px 16px;">{features_html}</td></tr>
          {build_social_footer_html(unsubscribe_url=unsubscribe_url, category_name=category_name)}
          <tr><td align="center" style="padding:28px 40px 40px;"><p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">{branding.APP_NAME} &mdash; Your Personal Training Assistant</p><p style="margin:0;font-size:12px;color:#3f3f46;">{footer_text}</p></td></tr>
        </table>
    </td></tr>
  </table>
</body>
</html>"""

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
