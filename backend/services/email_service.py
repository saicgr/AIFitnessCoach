"""
Email service using Resend for sending workout reminders and notifications.

Split into mixins for manageability:
- EmailLifecycleMixin: cancellation_retention, trial_expired, trial_ending,
  streak_at_risk, day3_activation, onboarding_incomplete
- EmailMarketingMixin: win_back, 14day_upsell, weekly_summary

Core methods stay here: welcome, workout_reminder, purchase_confirmation, billing_issue
"""

import os
import json
from datetime import datetime, date
from typing import Optional, List, Dict, Any
import resend

from core.logger import get_logger

# Import mixins (defined in sibling files)
from services.email_lifecycle import EmailLifecycleMixin
from services.email_marketing import EmailMarketingMixin

logger = get_logger(__name__)


class EmailService(EmailLifecycleMixin, EmailMarketingMixin):
    """Service for sending emails via Resend.

    Core transactional emails are defined here.
    Lifecycle emails (trial, cancellation, streak) are in EmailLifecycleMixin.
    Marketing emails (win-back, upsell, weekly summary) are in EmailMarketingMixin.
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
        self.from_email = os.getenv("RESEND_FROM_EMAIL", "FitWiz <onboarding@resend.dev>")

    def is_configured(self) -> bool:
        """Check if the email service is properly configured."""
        return bool(self.api_key)

    async def send_welcome_email(
        self,
        to_email: str,
        user_name: str,
    ) -> Dict[str, Any]:
        """Send a welcome email to a new user immediately after signup."""
        if not self.is_configured():
            logger.error("Cannot send welcome email - Resend API key not configured")
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"

        display_name = user_name.split()[0] if user_name else "there"

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to FitWiz</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">FITWIZ</p>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">Welcome, {display_name}!</h1>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                You're all set. Your AI-powered training partner is ready to build your first personalised workout plan.
              </p>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}" style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">Open FitWiz</a>
            </td>
          </tr>
          <tr><td style="padding:0 32px;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr></table></td></tr>
          <tr>
            <td style="padding:40px 40px 16px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;"><tr><td width="48" valign="top"><div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">&#127947;</div></td><td style="padding-left:16px;" valign="top"><p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">AI-Generated Workout Plans</p><p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Personalised monthly plans built around your goals, schedule, and equipment.</p></td></tr></table>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;"><tr><td width="48" valign="top"><div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">&#129303;</div></td><td style="padding-left:16px;" valign="top"><p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Your 24/7 AI Coach</p><p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Ask anything -- form tips, nutrition advice, or swap an exercise -- anytime.</p></td></tr></table>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;"><tr><td width="48" valign="top"><div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">&#128200;</div></td><td style="padding-left:16px;" valign="top"><p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Track Your Evolution</p><p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Log sets, see your strength curve, and watch your body transform week by week.</p></td></tr></table>
            </td>
          </tr>
          <tr><td style="padding:40px 40px 0;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr></table></td></tr>
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">FitWiz &mdash; Your Personal AI Training Assistant</p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">You received this because you created a FitWiz account.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": "Welcome to FitWiz!", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Welcome email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send welcome email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_workout_reminder(
        self, to_email: str, user_name: str, workout_name: str,
        workout_type: str, scheduled_date: date, exercises: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """Send a workout reminder email to a user."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        exercise_list_html = ""
        for i, exercise in enumerate(exercises[:8], 1):
            exercise_name = exercise.get("name", "Unknown Exercise")
            sets = exercise.get("sets", 3)
            reps = exercise.get("reps", 10)
            exercise_list_html += f"<li><strong>{exercise_name}</strong> - {sets} sets x {reps} reps</li>"
        if len(exercises) > 8:
            exercise_list_html += f"<li><em>...and {len(exercises) - 8} more exercises</em></li>"

        formatted_date = scheduled_date.strftime("%A, %B %d, %Y")

        html_content = f"""<!DOCTYPE html><html><head><style>
body{{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;line-height:1.6;color:#333;max-width:600px;margin:0 auto;padding:20px;}}
.header{{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;padding:30px;border-radius:12px 12px 0 0;text-align:center;}}
.header h1{{margin:0;font-size:24px;}}
.content{{background:#f8f9fa;padding:30px;border-radius:0 0 12px 12px;}}
.workout-card{{background:white;border-radius:8px;padding:20px;margin:20px 0;box-shadow:0 2px 8px rgba(0,0,0,0.1);}}
.workout-type{{display:inline-block;background:#667eea;color:white;padding:4px 12px;border-radius:20px;font-size:12px;text-transform:uppercase;}}
.exercise-list{{list-style:none;padding:0;}}
.exercise-list li{{padding:10px 0;border-bottom:1px solid #eee;}}
.exercise-list li:last-child{{border-bottom:none;}}
.cta-button{{display:inline-block;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;padding:14px 28px;border-radius:8px;text-decoration:none;font-weight:600;margin-top:20px;}}
.footer{{text-align:center;color:#666;font-size:12px;margin-top:30px;}}
</style></head><body>
<div class="header"><h1>Time to Train!</h1></div>
<div class="content">
<p>Hey {user_name or 'there'},</p>
<p>You have a workout scheduled for <strong>{formatted_date}</strong>. Let's crush it!</p>
<div class="workout-card">
<span class="workout-type">{workout_type.replace('_', ' ')}</span>
<h2 style="margin:10px 0;">{workout_name}</h2>
<h3>Today's Exercises:</h3>
<ul class="exercise-list">{exercise_list_html}</ul>
</div>
<p style="text-align:center;"><a href="#" class="cta-button">Open App & Start Workout</a></p>
<p style="color:#666;font-size:14px;">Remember: Consistency is key! Even a shorter workout is better than no workout.</p>
</div>
<div class="footer"><p>FitWiz - Your Personal Training Assistant</p><p>You received this email because you have workout reminders enabled.</p></div>
</body></html>"""

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"Workout Reminder: {workout_name} - {formatted_date}", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Email sent successfully to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {e}")
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
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"
        tier_label = tier.replace("_", " ").title()

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"You're Premium, {display_name}!",
            subtitle=f"Your {tier_label} plan is now active. {price_paid} {currency} charged. Welcome to the full FitWiz experience.",
            cta_text="Open FitWiz",
            features=[
                ("&#127947;", "Unlimited AI Workouts", "Generate new plans anytime. Your AI coach adapts to your progress every week."),
                ("&#129303;", "Priority AI Coach", "Unlimited chat with your personal coach. No daily limits, no waiting."),
                ("&#128200;", "Advanced Analytics", "Deep performance metrics, strength curves, and body composition tracking."),
            ],
            footer_text="You received this because you upgraded your FitWiz plan.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": f"Welcome to FitWiz {tier_label}, {display_name} -- your upgrade is live", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Purchase confirmation email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send purchase confirmation email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_billing_issue(
        self, to_email: str, user_name: str, tier: str,
    ) -> Dict[str, Any]:
        """Send a billing issue / payment failed email."""
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"
        tier_label = tier.replace("_", " ").title()

        html_content = self._build_standard_email(
            logo_url=logo_url, open_url=open_url,
            title=f"Payment issue, {display_name}",
            subtitle=f"We couldn't process your payment for FitWiz {tier_label}. Please update your payment method to keep your access.",
            cta_text="Update Payment",
            features=[
                ("&#9888;", "Your access is at risk", "Update your payment method within the next few days to avoid losing Premium access."),
                ("&#128179;", "Quick fix via the App Store", "Open your phone's App Store or Google Play, go to Subscriptions, and update your card."),
                ("&#128737;", "Your data is safe", "All your workout history, progress photos, and plans are saved and waiting for you."),
            ],
            footer_text="You received this because your payment failed.",
        )

        try:
            params = {"from": self.from_email, "to": [to_email], "subject": "Action required: Your FitWiz payment failed", "html": html_content}
            response = resend.Emails.send(params)
            logger.info(f"Billing issue email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"Failed to send billing issue email to {to_email}: {e}")
            return {"error": str(e)}

    def _build_standard_email(
        self, logo_url: str, open_url: str, title: str, subtitle: str,
        cta_text: str, features: List[tuple], footer_text: str,
    ) -> str:
        """Build a standard FitWiz email template with consistent styling.

        Args:
            logo_url: URL to the FitWiz logo
            open_url: URL for CTA button
            title: Email headline
            subtitle: Email subheadline
            cta_text: CTA button text
            features: List of (emoji_code, feature_title, feature_desc) tuples
            footer_text: Footer explanation text

        Returns:
            Complete HTML email string
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
          <tr><td align="center" style="padding:48px 40px 32px;"><img src="{logo_url}" alt="FitWiz" width="88" height="88" style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;"><p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">FITWIZ</p></td></tr>
          <tr><td align="center" style="padding:0 40px 12px;"><h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">{title}</h1></td></tr>
          <tr><td align="center" style="padding:0 48px 40px;"><p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">{subtitle}</p></td></tr>
          <tr><td align="center" style="padding:0 40px 48px;"><a href="{open_url}" style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">{cta_text}</a></td></tr>
          <tr><td style="padding:0 32px;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr></table></td></tr>
          <tr><td style="padding:40px 40px 16px;">{features_html}</td></tr>
          <tr><td style="padding:40px 40px 0;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr></table></td></tr>
          <tr><td align="center" style="padding:28px 40px 40px;"><p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">FitWiz &mdash; Your Personal AI Training Assistant</p><p style="margin:0;font-size:12px;color:#3f3f46;">{footer_text}</p></td></tr>
        </table>
    </td></tr>
  </table>
</body>
</html>"""

    # Lifecycle email methods (cancellation_retention, trial_expired, trial_ending,
    # streak_at_risk, day3_activation, onboarding_incomplete) are inherited from
    # EmailLifecycleMixin in services/email_lifecycle.py.
    #
    # Marketing email methods (win_back, 14day_upsell, weekly_summary) are inherited
    # from EmailMarketingMixin in services/email_marketing.py.


# Singleton instance
_email_service: Optional[EmailService] = None


def get_email_service() -> EmailService:
    """Get or create the email service singleton."""
    global _email_service
    if _email_service is None:
        _email_service = EmailService()
    return _email_service
