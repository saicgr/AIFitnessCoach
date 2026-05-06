"""Pre-launch waitlist confirmation email.

Sent to anyone who joins the marketing-site waitlist. Pure transactional.

Voice: Founder-direct, anticipation-building. Same brand voice as the
Founding 500 lifetime emails (`feedback_coach_voice_naming.md`: lifecycle
transactional → Zealova brand voice, not coach persona).
"""
from __future__ import annotations

import os
from typing import Any, Dict, Optional

import resend

from core import branding
from core.logger import get_logger

logger = get_logger(__name__)


def _waitlist_email_html(
    *,
    logo_url: str,
    web_url: str,
    first_name: Optional[str] = None,
) -> str:
    """Anticipation-driven HTML for the waitlist confirmation.

    Visual: emerald + black, large hero numeric, three "what's coming" tiles.
    Avoids feature-list spam — leans on scarcity ("first emails go out before
    public launch") and "you're in early" framing.
    """
    greeting = f"Hey {first_name}," if first_name else "You're in."
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <title>You're on the {branding.APP_NAME} waitlist</title>
</head>
<body style="margin:0;padding:0;background:#0a0a0b;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen,Ubuntu,sans-serif;color:#e4e4e7;">
  <!-- Preheader (hidden) -->
  <div style="display:none;max-height:0;overflow:hidden;font-size:1px;line-height:1px;color:#0a0a0b;">
    Something better is coming. You'll know first.
  </div>

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:#0a0a0b;">
    <tr><td align="center" style="padding:48px 16px 0;">
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:560px;">

        <!-- Logo -->
        <tr><td align="center" style="padding-bottom:32px;">
          <img src="{logo_url}" alt="{branding.APP_NAME}" width="56" height="56" style="border-radius:14px;">
        </td></tr>

        <!-- Hero card -->
        <tr><td style="background:linear-gradient(180deg,#111114 0%,#0a0a0b 100%);border:1px solid rgba(16,185,129,0.18);border-radius:24px;padding:48px 32px;text-align:center;">

          <p style="margin:0 0 12px;font-size:11px;letter-spacing:2px;color:#10b981;font-weight:700;text-transform:uppercase;">
            ✓ You're on the list
          </p>

          <h1 style="margin:0 0 16px;font-size:40px;line-height:1.05;color:#ffffff;font-weight:800;letter-spacing:-0.02em;">
            {greeting}
          </h1>

          <p style="margin:0 0 8px;font-size:18px;color:#d4d4d8;line-height:1.5;">
            Something better than the calorie-tracker grind is almost here.
          </p>
          <p style="margin:0 0 28px;font-size:18px;color:#a1a1aa;line-height:1.5;">
            And you'll be among the first to know when it drops.
          </p>

          <!-- Big number -->
          <div style="display:inline-block;background:rgba(16,185,129,0.08);border:1px solid rgba(16,185,129,0.25);border-radius:18px;padding:20px 32px;margin:8px 0 24px;">
            <div style="font-size:11px;letter-spacing:2px;color:#10b981;font-weight:700;text-transform:uppercase;margin-bottom:6px;">
              Days until launch
            </div>
            <div style="font-size:42px;color:#ffffff;font-weight:800;letter-spacing:-0.02em;line-height:1;">
              soon
            </div>
            <div style="font-size:13px;color:#71717a;margin-top:6px;">
              Submitted to Google. Refreshing the console daily.
            </div>
          </div>

        </td></tr>

        <!-- What happens next -->
        <tr><td style="padding:32px 8px 8px;">
          <p style="margin:0 0 16px;font-size:11px;letter-spacing:2px;color:#71717a;font-weight:700;text-transform:uppercase;">
            What happens next
          </p>
        </td></tr>

        <tr><td style="padding:0 8px;">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
            <tr>
              <td style="padding:0 0 12px;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:#111114;border:1px solid #27272a;border-radius:16px;">
                  <tr><td style="padding:20px 24px;">
                    <div style="display:inline-block;width:32px;height:32px;background:rgba(16,185,129,0.1);border-radius:8px;text-align:center;line-height:32px;font-size:16px;color:#10b981;font-weight:800;">1</div>
                    <h3 style="margin:12px 0 6px;font-size:16px;color:#ffffff;font-weight:700;">The Android public link</h3>
                    <p style="margin:0;font-size:14px;color:#a1a1aa;line-height:1.6;">
                      One email the moment Google approves. No countdown timers, no fake urgency — just the link.
                    </p>
                  </td></tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:0 0 12px;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:#111114;border:1px solid #27272a;border-radius:16px;">
                  <tr><td style="padding:20px 24px;">
                    <div style="display:inline-block;width:32px;height:32px;background:rgba(16,185,129,0.1);border-radius:8px;text-align:center;line-height:32px;font-size:16px;color:#10b981;font-weight:800;">2</div>
                    <h3 style="margin:12px 0 6px;font-size:16px;color:#ffffff;font-weight:700;">iOS access, before public</h3>
                    <p style="margin:0;font-size:14px;color:#a1a1aa;line-height:1.6;">
                      iOS launches right after Android. Waitlist members get the TestFlight + App Store link before the public announcement.
                    </p>
                  </td></tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:0 0 12px;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:#111114;border:1px solid #27272a;border-radius:16px;">
                  <tr><td style="padding:20px 24px;">
                    <div style="display:inline-block;width:32px;height:32px;background:rgba(16,185,129,0.1);border-radius:8px;text-align:center;line-height:32px;font-size:16px;color:#10b981;font-weight:800;">3</div>
                    <h3 style="margin:12px 0 6px;font-size:16px;color:#ffffff;font-weight:700;">Founder updates, occasional</h3>
                    <p style="margin:0;font-size:14px;color:#a1a1aa;line-height:1.6;">
                      Honest behind-the-scenes from the build — what shipped, what broke, what's next. Roughly twice a month. Never marketing fluff.
                    </p>
                  </td></tr>
                </table>
              </td>
            </tr>
          </table>
        </td></tr>

        <!-- CTA: roadmap -->
        <tr><td align="center" style="padding:32px 8px 16px;">
          <a href="{web_url}/roadmap"
             style="display:inline-block;background:#10b981;color:#000000;font-size:15px;font-weight:700;text-decoration:none;padding:14px 36px;border-radius:50px;letter-spacing:0.2px;">
            See what we're building →
          </a>
        </td></tr>

        <!-- Why we're different -->
        <tr><td style="padding:24px 8px 8px;">
          <p style="margin:0;font-size:13px;color:#71717a;line-height:1.7;text-align:center;">
            {branding.APP_NAME} is an AI fitness + nutrition coach built for people tired of MyFitnessPal manual entry, random YouTube workouts, and ChatGPT plans nobody actually follows. Snap a meal. Get a workout. Talk to a coach.
            <br><br>
            Built solo. Honest about what works. We'll be in your inbox the moment you can try it.
          </p>
        </td></tr>

        <!-- Footer -->
        <tr><td style="padding:32px 8px 48px;text-align:center;">
          <p style="margin:0 0 8px;font-size:12px;color:#52525b;">
            You're getting this because you joined the {branding.APP_NAME} waitlist at <a href="{web_url}" style="color:#71717a;text-decoration:underline;">{branding.APP_NAME.lower()}.com</a>.
          </p>
          <p style="margin:0;font-size:12px;color:#52525b;">
            Don't want these? Just reply "unsubscribe" — I read every email.
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>"""


class WaitlistEmailService:
    """Wraps Resend send for waitlist confirmation emails."""

    def __init__(self):
        self.api_key = os.getenv("RESEND_API_KEY")
        self.from_email = os.getenv(
            "RESEND_FROM_EMAIL",
            f"{branding.APP_NAME} <onboarding@resend.dev>",
        )
        if self.api_key:
            resend.api_key = self.api_key

    def is_configured(self) -> bool:
        return bool(self.api_key)

    async def send_waitlist_confirmation(
        self,
        to_email: str,
        first_name: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Sent immediately after a user joins the marketing waitlist."""
        if not self.is_configured():
            logger.warning("Cannot send waitlist confirmation — Resend not configured")
            return {"error": "Email service not configured"}

        from core.config import get_settings
        settings = get_settings()
        logo_url = settings.email_logo_url
        web_url = settings.web_marketing_url

        html_content = _waitlist_email_html(
            logo_url=logo_url,
            web_url=web_url,
            first_name=first_name,
        )

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"You're on the {branding.APP_NAME} waitlist — here's what happens next",
                "html": html_content,
            }
            email = resend.Emails.send(params)
            logger.info(f"Waitlist confirmation sent to {to_email}: id={email.get('id')}")
            return {"id": email.get("id"), "status": "sent"}
        except Exception as e:
            logger.error(f"Failed to send waitlist confirmation: {e}", exc_info=True)
            return {"error": str(e)}
