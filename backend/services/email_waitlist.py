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
from services import email_signature_template as sig

logger = get_logger(__name__)


PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"


def _waitlist_email_html(
    *,
    logo_url: str,
    web_url: str,
    first_name: Optional[str] = None,
) -> str:
    """Post-launch waitlist confirmation HTML — Zealova "Signature" design.

    Android shipped on 2026-05-10. The waitlist is now primarily an iOS
    waitlist, but Android signups need the install link immediately —
    making them wait for an "approval" that already happened is the
    fastest way to lose the conversion (~60-80% open rate window).

    Built on `email_signature_template` (typographic ZEALOVA lockup, orange
    accent, Lucide icons, zero emoji). Structure:
      1. Anton hero — "You're in" + a confirmation sub-line (personalized).
      2. Three signature info rows: Android-now / iOS-TestFlight / updates.
      3. ONE pill CTA — Get Zealova on Google Play.
      4. Callout positioning line + "what's shipping next" link.
      5. Transactional footer (founder voice, "I read every email").

    `logo_url` is accepted for caller compatibility but unused — the Signature
    design uses the typographic header lockup, not an <img> logo.
    """
    del logo_url  # Signature design uses the typographic lockup, not an <img>.
    hero_sub = (
        f"Hey {first_name} — Android just went live on the Play Store, and iOS is "
        "right behind. You'll get TestFlight before the public link drops."
        if first_name else
        "Android just went live on the Play Store, and iOS is right behind. "
        "You'll get TestFlight before the public link drops."
    )
    body_html = (
        sig.info_rows([
            ("smartphone", "Get it on Android now",
             "Live on the Play Store today. 7-day free trial, then $7.99/mo or "
             "$59.99/yr — cancel anytime."),
            ("clock", "iOS — TestFlight first",
             "You'll get the TestFlight invite before the public App Store launch. "
             "No countdown timers, no fake urgency — just the link the day it's ready."),
            ("mail", "Founder updates, occasional",
             "Honest behind-the-scenes from the build — what shipped, what broke, "
             "what's next. Roughly twice a month. Never marketing fluff."),
        ])
        + sig.pill_cta(f"Get {branding.APP_NAME} on Google Play", PLAY_STORE_URL)
        + sig.callout(
            f"{branding.APP_NAME} is an AI fitness + nutrition coach for people tired "
            "of manual MyFitnessPal entry, generic YouTube workouts, and ChatGPT plans "
            "nobody follows. Snap a meal. Get a workout that fits your gym. Talk to a "
            "coach that knows your history.",
            link_text="See what's shipping next",
            link_url=f"{web_url}/roadmap",
        )
    )
    return sig.signature_email(
        header_tag="Waitlist",
        hero_title="You're in",
        hero_sub=hero_sub,
        hero_icon="check_circle",
        body_html=body_html,
        footer_kind="transactional",
        footer_note=(
            f"You received this because you joined the {branding.APP_NAME} waitlist. "
            "Reply \"unsubscribe\" to stop — the founder reads every email."
        ),
        preheader=(
            "Android is live on the Play Store. iOS is right behind — "
            "waitlist gets it first."
        ),
        category_label="waitlist updates",
    )


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
