"""
Email service using Resend for sending workout reminders and notifications.
"""

import os
import json
from datetime import datetime, date
from typing import Optional, List, Dict, Any
import resend

from core.logger import get_logger

logger = get_logger(__name__)


class EmailService:
    """Service for sending emails via Resend."""

    def __init__(self):
        """Initialize the Resend client with API key from environment."""
        self.api_key = os.getenv("RESEND_API_KEY")
        if not self.api_key:
            logger.warning("RESEND_API_KEY not found in environment variables")
        else:
            resend.api_key = self.api_key
            logger.info("✅ Email service initialized with Resend")

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
        """
        Send a welcome email to a new user immediately after signup.

        Args:
            to_email: User's email address
            user_name: User's display name (may be empty)

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
            logger.error("❌ Cannot send welcome email - Resend API key not configured")
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

  <!-- Outer wrapper -->
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <!-- Card -->
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                Welcome, {display_name}!
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                You're all set. Your AI-powered training partner is ready to build your first personalised workout plan.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Open FitWiz
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Features -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Feature 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127947;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">AI-Generated Workout Plans</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Personalised monthly plans built around your goals, schedule, and equipment.</p>
                  </td>
                </tr>
              </table>

              <!-- Feature 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#129303;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Your 24/7 AI Coach</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Ask anything — form tips, nutrition advice, or swap an exercise — anytime.</p>
                  </td>
                </tr>
              </table>

              <!-- Feature 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128200;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Track Your Evolution</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Log sets, see your strength curve, and watch your body transform week by week.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom gradient bar -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because you created a FitWiz account.
              </p>
            </td>
          </tr>

        </table>
        <!-- /Card -->

      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": "Welcome to FitWiz!",
                "html": html_content,
            }

            response = resend.Emails.send(params)
            logger.info(f"✅ Welcome email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}

        except Exception as e:
            logger.error(f"❌ Failed to send welcome email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_workout_reminder(
        self,
        to_email: str,
        user_name: str,
        workout_name: str,
        workout_type: str,
        scheduled_date: date,
        exercises: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Send a workout reminder email to a user.

        Args:
            to_email: User's email address
            user_name: User's display name
            workout_name: Name of the workout
            workout_type: Type of workout (e.g., "upper_body", "legs")
            scheduled_date: Date the workout is scheduled
            exercises: List of exercises in the workout

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
            logger.error("❌ Cannot send email - Resend API key not configured")
            return {"error": "Email service not configured"}

        # Format the exercise list for the email
        exercise_list_html = ""
        for i, exercise in enumerate(exercises[:8], 1):  # Limit to first 8
            exercise_name = exercise.get("name", "Unknown Exercise")
            sets = exercise.get("sets", 3)
            reps = exercise.get("reps", 10)
            exercise_list_html += f"<li><strong>{exercise_name}</strong> - {sets} sets x {reps} reps</li>"

        if len(exercises) > 8:
            exercise_list_html += f"<li><em>...and {len(exercises) - 8} more exercises</em></li>"

        # Format the date nicely
        formatted_date = scheduled_date.strftime("%A, %B %d, %Y")

        # Build the HTML email
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                }}
                .header {{
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 30px;
                    border-radius: 12px 12px 0 0;
                    text-align: center;
                }}
                .header h1 {{
                    margin: 0;
                    font-size: 24px;
                }}
                .content {{
                    background: #f8f9fa;
                    padding: 30px;
                    border-radius: 0 0 12px 12px;
                }}
                .workout-card {{
                    background: white;
                    border-radius: 8px;
                    padding: 20px;
                    margin: 20px 0;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }}
                .workout-type {{
                    display: inline-block;
                    background: #667eea;
                    color: white;
                    padding: 4px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    text-transform: uppercase;
                }}
                .exercise-list {{
                    list-style: none;
                    padding: 0;
                }}
                .exercise-list li {{
                    padding: 10px 0;
                    border-bottom: 1px solid #eee;
                }}
                .exercise-list li:last-child {{
                    border-bottom: none;
                }}
                .cta-button {{
                    display: inline-block;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 14px 28px;
                    border-radius: 8px;
                    text-decoration: none;
                    font-weight: 600;
                    margin-top: 20px;
                }}
                .footer {{
                    text-align: center;
                    color: #666;
                    font-size: 12px;
                    margin-top: 30px;
                }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Time to Train!</h1>
            </div>
            <div class="content">
                <p>Hey {user_name or 'there'},</p>
                <p>You have a workout scheduled for <strong>{formatted_date}</strong>. Let's crush it!</p>

                <div class="workout-card">
                    <span class="workout-type">{workout_type.replace('_', ' ')}</span>
                    <h2 style="margin: 10px 0;">{workout_name}</h2>

                    <h3>Today's Exercises:</h3>
                    <ul class="exercise-list">
                        {exercise_list_html}
                    </ul>
                </div>

                <p style="text-align: center;">
                    <a href="#" class="cta-button">Open App & Start Workout</a>
                </p>

                <p style="color: #666; font-size: 14px;">
                    Remember: Consistency is key! Even a shorter workout is better than no workout.
                </p>
            </div>
            <div class="footer">
                <p>FitWiz - Your Personal Training Assistant</p>
                <p>You received this email because you have workout reminders enabled.</p>
            </div>
        </body>
        </html>
        """

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"Workout Reminder: {workout_name} - {formatted_date}",
                "html": html_content,
            }

            response = resend.Emails.send(params)
            logger.info(f"✅ Email sent successfully to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}

        except Exception as e:
            logger.error(f"❌ Failed to send email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_purchase_confirmation(
        self,
        to_email: str,
        user_name: str,
        tier: str,
        price_paid: float,
        currency: str = "USD",
    ) -> Dict[str, Any]:
        """
        Send a purchase confirmation email after a successful subscription upgrade.

        Args:
            to_email: User's email address
            user_name: User's display name
            tier: Subscription tier purchased (e.g. "premium_monthly")
            price_paid: Amount charged
            currency: Currency code (default USD)

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        tier_label = tier.replace("_", " ").title()

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Purchase Confirmation</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                You're Premium, {display_name}!
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                Your {tier_label} plan is now active. {price_paid} {currency} charged. Welcome to the full FitWiz experience.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Open FitWiz
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Features -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Feature 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127947;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Unlimited AI Workouts</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Generate new plans anytime. Your AI coach adapts to your progress every week.</p>
                  </td>
                </tr>
              </table>

              <!-- Feature 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#129303;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Priority AI Coach</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Unlimited chat with your personal coach. No daily limits, no waiting.</p>
                  </td>
                </tr>
              </table>

              <!-- Feature 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128200;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Advanced Analytics</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Deep performance metrics, strength curves, and body composition tracking.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because you upgraded your FitWiz plan.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"Welcome to FitWiz {tier_label}, {display_name} — your upgrade is live",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ Purchase confirmation email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send purchase confirmation email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_billing_issue(
        self,
        to_email: str,
        user_name: str,
        tier: str,
    ) -> Dict[str, Any]:
        """
        Send a billing issue / payment failed email.

        Args:
            to_email: User's email address
            user_name: User's display name
            tier: Subscription tier that failed to renew

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        tier_label = tier.replace("_", " ").title()

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Issue</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                Payment issue, {display_name}
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                We couldn't process your payment for FitWiz {tier_label}. Please update your payment method to keep your access.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Update Payment
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Info rows -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Row 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#9888;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Your access is at risk</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Update your payment method within the next few days to avoid losing Premium access.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128179;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Quick fix via the App Store</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Open your phone's App Store or Google Play, go to Subscriptions, and update your card.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128737;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Your data is safe</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">All your workout history, progress photos, and plans are saved and waiting for you.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because your payment failed.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": "Action required: Your FitWiz payment failed",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ Billing issue email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send billing issue email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_cancellation_retention(
        self,
        to_email: str,
        user_name: str,
        tier: str,
        workouts_completed: int,
        total_volume_kg: float,
        current_streak: int,
    ) -> Dict[str, Any]:
        """
        Send a cancellation retention email to a user who just cancelled their subscription.

        Args:
            to_email: User's email address
            user_name: User's display name
            tier: Subscription tier that was cancelled
            workouts_completed: Total workouts the user has completed
            total_volume_kg: Total volume lifted in kg
            current_streak: Current workout streak in days

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
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
  <title>Before You Go</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                Before you go, {display_name}
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                You've completed {workouts_completed} workouts with FitWiz. That's real progress. We'd love to keep helping you reach your goals.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 16px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Keep My Premium
              </a>
            </td>
          </tr>

          <!-- Below CTA small text -->
          <tr>
            <td align="center" style="padding:0 40px 40px;">
              <p style="margin:0;font-size:13px;color:#3f3f46;text-align:center;">
                Questions? Reply to this email.
              </p>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Feature rows -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Row 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127947;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Your workout history stays</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">All {workouts_completed} logged workouts and your progress data are safe even on the free plan.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#129303;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">AI Coach goes to basics</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Free plan limits your daily AI coach messages. Premium gives unlimited access.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128200;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Progress tracking limited</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Advanced analytics, strength curves, and body composition charts require Premium.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because you cancelled your FitWiz subscription.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"We're sorry to see you go, {display_name} — here's an offer before you leave",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ Cancellation retention email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send cancellation retention email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_trial_expired(
        self,
        to_email: str,
        user_name: str,
        workouts_completed: int,
    ) -> Dict[str, Any]:
        """
        Send an email notifying the user that their free trial has expired.

        Args:
            to_email: User's email address
            user_name: User's display name
            workouts_completed: Number of workouts completed during the trial

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        workout_word = "workouts" if workouts_completed != 1 else "workout"

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Trial Expired</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                Trial over. Your gains aren't, {display_name}.
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                You completed {workouts_completed} {workout_word} during your trial. Don't let that momentum stop now.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Subscribe Now
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Rows -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Row 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127947;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Pick up where you left off</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Your workout plans, history, and AI coach settings are all still there.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#129303;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Keep your AI coach</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Unlimited personalised workouts and coaching — gone on the free plan.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#9889;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Special offer inside</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Subscribe today and get your first month at the standard price with no lock-in.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because your FitWiz trial ended.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"Your trial just ended — but it's not too late, {display_name}",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ Trial expired email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send trial expired email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_trial_ending(
        self,
        to_email: str,
        user_name: str,
        days_remaining: int,
        tier: str,
        workouts_during_trial: int,
        trial_end_date: str,
    ) -> Dict[str, Any]:
        """
        Send a trial ending soon reminder email.

        Args:
            to_email: User's email address
            user_name: User's display name
            days_remaining: Number of days left in the trial
            tier: Subscription tier of the trial
            workouts_during_trial: Number of workouts completed during the trial so far
            trial_end_date: Human-readable date when the trial ends (e.g. "March 20, 2026")

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        days_word = "days" if days_remaining != 1 else "day"
        workouts_word = "workouts" if workouts_during_trial != 1 else "workout"

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Trial Ending Soon</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                {days_remaining} {days_word} left, {display_name}
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                Your trial ends on {trial_end_date}. You've done {workouts_during_trial} {workouts_word} — don't lose your momentum.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Keep Premium Access
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Rows -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Row 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#9200;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Trial expires soon</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">After {trial_end_date}, you'll drop to the free plan with limited AI coach access.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127947;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">{workouts_during_trial} workouts logged</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">All your history is safe. But generating new AI plans requires Premium.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128161;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Subscribe now, same day</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Upgrading takes 30 seconds via the app. Cancel anytime.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because your FitWiz trial is ending soon.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"Your free trial ends in {days_remaining} {days_word} — here's what you'll lose",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ Trial ending email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send trial ending email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_streak_at_risk(
        self,
        to_email: str,
        user_name: str,
        current_streak: int,
        next_workout_name: str,
    ) -> Dict[str, Any]:
        """
        Send a streak-at-risk nudge email when a user hasn't logged a workout in 3 days.

        Args:
            to_email: User's email address
            user_name: User's display name
            current_streak: Current workout streak in days
            next_workout_name: Name of the next scheduled workout

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
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
  <title>Streak At Risk</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                Don't break your {current_streak}-day streak, {display_name}
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                You haven't logged a workout in 3 days. One quick session today resets the clock and keeps your momentum alive.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Log a Workout Now
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Rows -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Row 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128293;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">{current_streak} days strong</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Streaks are the single best predictor of long-term fitness results. Protect this one.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127947;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Next up: {next_workout_name}</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Your next workout is already built and waiting. Just tap Start.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#9201;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">20 minutes is enough</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Even a shorter session counts. Getting started is the hardest part.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because you have streak notifications enabled.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"{display_name}, your {current_streak}-day streak is about to break — 20 min is all it takes",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ Streak at risk email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send streak at risk email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_day3_activation(
        self,
        to_email: str,
        user_name: str,
        workout_name: str,
        exercises: List[str],
        goal: str,
    ) -> Dict[str, Any]:
        """
        Send a day-3 activation nudge for users who signed up but haven't started working out.

        Args:
            to_email: User's email address
            user_name: User's display name
            workout_name: Name of the first generated workout
            exercises: List of exercise names in the first workout
            goal: User's stated fitness goal

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        logo_url = f"{backend_url}/static/logo.png"
        open_url = f"{backend_url}/open"
        display_name = user_name.split()[0] if user_name else "there"

        exercises_preview = ", ".join(exercises[:3]) + ("..." if len(exercises) > 3 else "")

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Plan Is Ready</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                Your plan is ready, {display_name}
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                You signed up 3 days ago but haven't started yet. Your AI coach already built a {goal} workout plan for you. It takes 20 minutes.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Start My First Workout
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Rows -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Row 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#129303;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">AI-generated just for you</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Your first workout — {workout_name} — is tailored to your goals and equipment.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127947;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">First session: {exercises_preview}</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">All exercises come with video demos and form tips from your AI coach.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128241;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Open the app, tap Start</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Your plan is on the home screen. No setup needed — it's ready to go.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because you haven't started your first workout yet.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"{display_name}, your first workout is already built — just tap Start",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ Day-3 activation email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send day-3 activation email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_onboarding_incomplete(
        self,
        to_email: str,
        user_name: str,
    ) -> Dict[str, Any]:
        """
        Send a nudge email to users who started but did not finish onboarding.

        Args:
            to_email: User's email address
            user_name: User's display name

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
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
  <title>Finish Your Setup</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                You're almost there, {display_name}
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                You started setting up FitWiz but didn't finish. Your AI coach needs just a couple more answers to build your personalised plan.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Finish Setup
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Rows -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Row 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127919;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">2 minutes to complete</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Tell us your goals, training days, and equipment. That's all your AI coach needs.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#129303;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Your plan generates instantly</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Once you finish setup, FitWiz builds your full monthly workout plan in seconds.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127947;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Built around your life</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Your schedule, home or gym, beginner or advanced — every detail is personalised.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because your FitWiz setup is incomplete.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"{display_name}, your AI coach is waiting — 2 minutes to finish setup",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ Onboarding incomplete email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send onboarding incomplete email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_win_back(
        self,
        to_email: str,
        user_name: str,
        days_since_expiry: int,
        workouts_completed: int,
        discount_percent: int = 20,
    ) -> Dict[str, Any]:
        """
        Send a win-back email to lapsed Premium users with a discount offer.

        Args:
            to_email: User's email address
            user_name: User's display name
            days_since_expiry: Number of days since their Premium subscription ended
            workouts_completed: Total workouts completed while on Premium
            discount_percent: Discount percentage to offer (default 20)

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
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
  <title>Come Back Stronger</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                Come back stronger, {display_name}
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                It's been {days_since_expiry} days since your Premium ended. You logged {workouts_completed} workouts with FitWiz. Don't lose that progress.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Claim {discount_percent}% Off
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Rows -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Row 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128170;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Your history is waiting</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">All {workouts_completed} logged workouts, your strength curves, and progress photos are safe.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127873;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">{discount_percent}% off your first month back</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">We want you to succeed. Use this offer to restart with a discounted first month.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#129303;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">New AI features since you left</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Nutrition tracking, progress photos, and an improved AI coach are ready for you.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because your FitWiz Premium subscription has lapsed.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"{display_name}, you're falling behind — come back with {discount_percent}% off",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ Win-back email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send win-back email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_14day_upsell(
        self,
        to_email: str,
        user_name: str,
        workouts_completed: int,
    ) -> Dict[str, Any]:
        """
        Send a 14-day upsell email to free-plan users who have been consistently active.

        Args:
            to_email: User's email address
            user_name: User's display name
            workouts_completed: Number of workouts completed on the free plan

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
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
  <title>Upgrade to Premium</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;overflow:hidden;border:1px solid #1a1a1a;">

          <!-- Hero gradient bar -->
          <tr>
            <td style="background:linear-gradient(135deg,#0891b2 0%,#06b6d4 50%,#22d3ee 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo + brand -->
          <tr>
            <td align="center" style="padding:48px 40px 32px;">
              <img src="{logo_url}" alt="FitWiz" width="88" height="88"
                   style="display:block;border-radius:20px;border:0;width:88px;height:88px;object-fit:cover;">
              <p style="margin:20px 0 0;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#06b6d4;">
                FITWIZ
              </p>
            </td>
          </tr>

          <!-- Headline -->
          <tr>
            <td align="center" style="padding:0 40px 12px;">
              <h1 style="margin:0;font-size:36px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
                {workouts_completed} workouts in. You're serious, {display_name}.
              </h1>
            </td>
          </tr>

          <!-- Subline -->
          <tr>
            <td align="center" style="padding:0 48px 40px;">
              <p style="margin:0;font-size:16px;line-height:1.65;color:#a1a1aa;text-align:center;">
                You've been consistent for 2 weeks on the free plan. Premium users who start at this point see 3x the progress in the next month.
              </p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding:0 40px 48px;">
              <a href="{open_url}"
                 style="display:inline-block;background:#06b6d4;color:#000000;font-size:16px;font-weight:700;
                        text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
                Upgrade to Premium
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Rows -->
          <tr>
            <td style="padding:40px 40px 16px;">

              <!-- Row 1 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#127947;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Unlimited AI workout plans</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Generate a new personalised plan anytime. Your AI coach adapts as you get stronger.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 2 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#128200;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Strength &amp; body analytics</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Strength curves, volume tracking, and body composition insights — unlocked with Premium.</p>
                  </td>
                </tr>
              </table>

              <!-- Row 3 -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:8px;">
                <tr>
                  <td width="48" valign="top">
                    <div style="width:40px;height:40px;background:#0f2733;border-radius:12px;text-align:center;line-height:40px;font-size:20px;">
                      &#129303;
                    </div>
                  </td>
                  <td style="padding-left:16px;" valign="top">
                    <p style="margin:0 0 4px;font-size:15px;font-weight:700;color:#ffffff;">Unlimited AI coach chat</p>
                    <p style="margin:0;font-size:14px;color:#71717a;line-height:1.5;">Ask anything, anytime. No daily message limits. Your coach is always available.</p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Bottom divider -->
          <tr>
            <td style="padding:40px 40px 0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 40px;">
              <p style="margin:0 0 4px;font-size:12px;color:#3f3f46;">
                FitWiz &mdash; Your Personal AI Training Assistant
              </p>
              <p style="margin:0;font-size:12px;color:#3f3f46;">
                You received this because you've been active on the FitWiz free plan.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>"""

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"You've done {workouts_completed} workouts — here's what Premium unlocks, {display_name}",
                "html": html_content,
            }
            response = resend.Emails.send(params)
            logger.info(f"✅ 14-day upsell email sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}
        except Exception as e:
            logger.error(f"❌ Failed to send 14-day upsell email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_weekly_summary(
        self,
        to_email: str,
        user_name: str,
        completed_workouts: int,
        total_workouts: int,
        total_volume_kg: float,
        top_exercises: List[str],
    ) -> Dict[str, Any]:
        """
        Send a weekly workout summary email.

        Args:
            to_email: User's email address
            user_name: User's display name
            completed_workouts: Number of workouts completed this week
            total_workouts: Total workouts scheduled this week
            total_volume_kg: Total weight lifted this week
            top_exercises: List of most performed exercises
        """
        if not self.is_configured():
            logger.error("❌ Cannot send email - Resend API key not configured")
            return {"error": "Email service not configured"}

        completion_rate = (completed_workouts / total_workouts * 100) if total_workouts > 0 else 0

        top_exercises_html = "".join([f"<li>{ex}</li>" for ex in top_exercises[:5]])

        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                }}
                .header {{
                    background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
                    color: white;
                    padding: 30px;
                    border-radius: 12px 12px 0 0;
                    text-align: center;
                }}
                .stats-grid {{
                    display: grid;
                    grid-template-columns: repeat(2, 1fr);
                    gap: 15px;
                    margin: 20px 0;
                }}
                .stat-card {{
                    background: white;
                    border-radius: 8px;
                    padding: 20px;
                    text-align: center;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }}
                .stat-value {{
                    font-size: 32px;
                    font-weight: bold;
                    color: #11998e;
                }}
                .stat-label {{
                    color: #666;
                    font-size: 14px;
                }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Your Weekly Summary</h1>
            </div>
            <div style="background: #f8f9fa; padding: 30px; border-radius: 0 0 12px 12px;">
                <p>Great work this week, {user_name or 'champ'}!</p>

                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-value">{completed_workouts}/{total_workouts}</div>
                        <div class="stat-label">Workouts Completed</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">{completion_rate:.0f}%</div>
                        <div class="stat-label">Completion Rate</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">{total_volume_kg:,.0f}</div>
                        <div class="stat-label">Total Volume (kg)</div>
                    </div>
                </div>

                <h3>Your Top Exercises:</h3>
                <ul>{top_exercises_html}</ul>

                <p>Keep up the momentum!</p>
            </div>
        </body>
        </html>
        """

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"Your Weekly Fitness Summary - {completed_workouts}/{total_workouts} Workouts",
                "html": html_content,
            }

            response = resend.Emails.send(params)
            logger.info(f"✅ Weekly summary sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}

        except Exception as e:
            logger.error(f"❌ Failed to send weekly summary to {to_email}: {e}")
            return {"error": str(e)}


# Singleton instance
_email_service: Optional[EmailService] = None


def get_email_service() -> EmailService:
    """Get or create the email service singleton."""
    global _email_service
    if _email_service is None:
        _email_service = EmailService()
    return _email_service
