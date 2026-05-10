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


PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"


def _waitlist_email_html(
    *,
    logo_url: str,
    web_url: str,
    first_name: Optional[str] = None,
) -> str:
    """Post-launch waitlist confirmation HTML.

    Android shipped on 2026-05-10. The waitlist is now primarily an iOS
    waitlist, but Android signups need the install link immediately —
    making them wait for an "approval" that already happened is the
    fastest way to lose the conversion (~60-80% open rate window).

    Structure (research-backed for confirmation emails):
      1. Confirm + set context in <100 words (people skim).
      2. ONE primary CTA — Get Zealova on Google Play.
      3. Two short tiles for what comes next on iOS + founder updates.
      4. Reply-friendly footer (founder voice, "I read every reply").
    """
    greeting = f"Hey {first_name} —" if first_name else "You're in."
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <title>You're on the {branding.APP_NAME} list — Android's live</title>
</head>
<body style="margin:0;padding:0;background:#0a0a0b;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen,Ubuntu,sans-serif;color:#e4e4e7;">
  <!-- Preheader (hidden, shows in inbox preview) -->
  <div style="display:none;max-height:0;overflow:hidden;font-size:1px;line-height:1px;color:#0a0a0b;">
    Android is live on the Play Store. iOS is right behind — waitlist gets it first.
  </div>

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:#0a0a0b;">
    <tr><td align="center" style="padding:48px 16px 0;">
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:560px;">

        <!-- Logo -->
        <tr><td align="center" style="padding-bottom:32px;">
          <img src="{logo_url}" alt="{branding.APP_NAME}" width="56" height="56" style="border-radius:14px;">
        </td></tr>

        <!-- Hero card -->
        <tr><td style="background:linear-gradient(180deg,#111114 0%,#0a0a0b 100%);border:1px solid rgba(16,185,129,0.18);border-radius:24px;padding:44px 32px 36px;text-align:center;">

          <p style="margin:0 0 12px;font-size:11px;letter-spacing:2px;color:#10b981;font-weight:700;text-transform:uppercase;">
            ✓ You're on the list
          </p>

          <h1 style="margin:0 0 14px;font-size:40px;line-height:1.05;color:#ffffff;font-weight:800;letter-spacing:-0.02em;">
            {greeting}
          </h1>

          <p style="margin:0 0 8px;font-size:18px;color:#d4d4d8;line-height:1.5;">
            Android just went live on the Play Store.
          </p>
          <p style="margin:0 0 28px;font-size:16px;color:#a1a1aa;line-height:1.5;">
            iOS is right behind — and you'll get TestFlight before the public link drops.
          </p>

          <!-- PRIMARY CTA -->
          <a href="{PLAY_STORE_URL}"
             style="display:inline-block;background:#10b981;color:#000000;font-size:16px;font-weight:800;text-decoration:none;padding:16px 40px;border-radius:50px;letter-spacing:0.2px;">
            Get {branding.APP_NAME} on Google Play →
          </a>

          <p style="margin:18px 0 0;font-size:12px;color:#71717a;">
            7-day free trial · $7.99/mo or $59.99/yr · cancel anytime
          </p>

        </td></tr>

        <!-- What happens next -->
        <tr><td style="padding:36px 8px 8px;">
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
                    <h3 style="margin:12px 0 6px;font-size:16px;color:#ffffff;font-weight:700;">iOS — TestFlight first</h3>
                    <p style="margin:0;font-size:14px;color:#a1a1aa;line-height:1.6;">
                      You'll get a TestFlight invite link before the public App Store launch. No countdown timers, no fake urgency — just the link in your inbox the day it's ready.
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

        <!-- Why we're different -->
        <tr><td style="padding:28px 8px 8px;">
          <p style="margin:0;font-size:13px;color:#a1a1aa;line-height:1.7;text-align:center;">
            {branding.APP_NAME} is an AI fitness + nutrition coach built for people tired of manual MyFitnessPal entry, generic YouTube workouts, and ChatGPT plans nobody actually follows. Snap a meal. Get a workout that fits your gym. Talk to a coach that knows your history.
          </p>
        </td></tr>

        <!-- Soft secondary CTA -->
        <tr><td align="center" style="padding:24px 8px 8px;">
          <a href="{web_url}/roadmap"
             style="font-size:13px;color:#10b981;text-decoration:none;font-weight:600;">
            See what's shipping next →
          </a>
        </td></tr>

        <!-- Founder sign-off -->
        <tr><td style="padding:32px 8px 8px;">
          <p style="margin:0;font-size:13px;color:#a1a1aa;line-height:1.7;text-align:center;">
            Built solo. If you have feedback, questions, or anything broken — just hit reply. I read every email.
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
                "subject": f"You're in — and {branding.APP_NAME} just went live on Android",
                "html": html_content,
            }
            email = resend.Emails.send(params)
            logger.info(f"Waitlist confirmation sent to {to_email}: id={email.get('id')}")
            return {"id": email.get("id"), "status": "sent"}
        except Exception as e:
            logger.error(f"Failed to send waitlist confirmation: {e}", exc_info=True)
            return {"error": str(e)}
