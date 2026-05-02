"""
Email mixin for the Founding 500 Lifetime program (web-only, Stripe-fulfilled).

Three transactional emails:
- send_lifetime_waitlist_confirmation: immediate after they join the waitlist
- send_lifetime_checkout_open: blast to the waitlist when Stripe opens (Phase 2 cutover)
- send_lifetime_purchase_confirmation: post-Stripe-webhook activation guide

CRITICAL: These emails reference web-only purchase flows. Never link to the
mobile app's IAP paywall from them — Apple anti-steering rule applies in
reverse for transactional emails too if they were ever displayed in-app.
These are pure transactional emails sent via Resend, never rendered in-app.

Voice: Founding 500 messaging is "founder voice" (you helped build this) — not
the in-app coach persona. Per `feedback_coach_voice_naming.md` rule: lifecycle
transactional → Zealova brand voice; motivational → user's coach persona.
This is brand voice.
"""
from __future__ import annotations

from typing import Any, Dict, Optional

import resend

from core import branding
from core.logger import get_logger

logger = get_logger(__name__)


def _email_shell(
    *,
    logo_url: str,
    preheader: str,
    accent_color: str = "#fbbf24",  # amber-400 — matches the /lifetime page hero
    eyebrow: str,
    title: str,
    body_html: str,
    cta_label: Optional[str] = None,
    cta_url: Optional[str] = None,
    footer_html: str = "",
) -> str:
    """Lightweight email layout shared by all three lifetime templates.

    Distinct visual identity from the in-app `_build_standard_email` (cyan)
    so Founding 500 emails are immediately recognizable as the gold/amber
    Founder lane vs. the regular Premium lifecycle lane.
    """
    cta_block = ""
    if cta_label and cta_url:
        cta_block = f"""
          <tr><td align="center" style="padding:32px 40px 8px;">
            <a href="{cta_url}"
               style="display:inline-block;background:{accent_color};color:#000000;font-size:16px;font-weight:800;text-decoration:none;padding:16px 44px;border-radius:50px;letter-spacing:0.2px;">
              {cta_label}
            </a>
          </td></tr>"""

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title}</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <!-- Preheader (hidden in-body, shows in inbox preview) -->
  <div style="display:none;font-size:1px;color:#000000;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">
    {preheader}
  </div>
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#000000;min-height:100vh;">
    <tr><td align="center" style="padding:40px 16px;">
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
             style="max-width:560px;background-color:#0a0a0a;border-radius:20px;overflow:hidden;border:1px solid #1f1f1f;">
        <!-- Gold accent stripe -->
        <tr><td style="background:linear-gradient(135deg,#fde68a 0%,{accent_color} 50%,#f59e0b 100%);height:4px;font-size:0;line-height:0;">&nbsp;</td></tr>
        <!-- Logo -->
        <tr><td align="center" style="padding:48px 40px 16px;">
          <img src="{logo_url}" alt="{branding.APP_NAME}" width="72" height="72"
               style="display:block;border-radius:18px;border:0;width:72px;height:72px;object-fit:cover;">
        </td></tr>
        <!-- Eyebrow -->
        <tr><td align="center" style="padding:8px 40px 0;">
          <p style="margin:0;font-size:11px;font-weight:800;letter-spacing:3px;text-transform:uppercase;color:{accent_color};">
            {eyebrow}
          </p>
        </td></tr>
        <!-- Title -->
        <tr><td align="center" style="padding:18px 40px 8px;">
          <h1 style="margin:0;font-size:30px;line-height:1.2;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">{title}</h1>
        </td></tr>
        <!-- Body -->
        <tr><td style="padding:16px 40px 0;">
          <div style="font-size:16px;line-height:1.65;color:#d4d4d8;">
            {body_html}
          </div>
        </td></tr>
        {cta_block}
        <!-- Footer block (per-template) -->
        {footer_html}
        <!-- Brand footer -->
        <tr><td align="center" style="padding:32px 40px 36px;border-top:1px solid #1a1a1a;">
          <p style="margin:0 0 6px;font-size:12px;color:#52525b;">
            {branding.APP_NAME} &mdash; Web-only Founding 500 program
          </p>
          <p style="margin:0;font-size:11px;color:#3f3f46;">
            Sent because you joined the {branding.APP_NAME} Founding 500 waitlist on {branding.MARKETING_DOMAIN if hasattr(branding, 'MARKETING_DOMAIN') else 'zealova.com'}.
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>"""


class EmailLifetimeMixin:
    """Founding 500 transactional email methods.

    Mixed into EmailService alongside the other email mixins. Expects:
    - self.from_email
    - self.is_configured()
    """

    async def send_lifetime_waitlist_confirmation(
        self,
        to_email: str,
        position: Optional[int] = None,
    ) -> Dict[str, Any]:
        """Sent immediately after a user joins the Founding 500 waitlist.

        Sets up the relationship: "you'll hear from us before everyone else"
        and primes the eventual purchase intent without being pushy.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        settings = get_settings()
        logo_url = settings.email_logo_url
        web_url = settings.web_marketing_url

        position_line = ""
        if position is not None:
            position_line = (
                f'<p style="margin:0 0 16px;color:#a1a1aa;">'
                f'You&apos;re approximately #<strong style="color:#fbbf24;">{position}</strong> on the list.'
                f'</p>'
            )

        body_html = f"""
          <p style="margin:0 0 16px;">You&apos;re on the list.</p>
          {position_line}
          <p style="margin:0 0 16px;">
            Founding Lifetime is a one-time $149.99 purchase that gets you {branding.APP_NAME} forever — every current
            and future Premium feature, locked at zero recurring cost. Only 500 of these will ever exist.
          </p>
          <p style="margin:0 0 16px;">
            Here&apos;s what waitlist members get:
          </p>
          <ul style="margin:0 0 8px;padding:0 0 0 20px;color:#d4d4d8;line-height:1.7;">
            <li><strong>24-hour exclusive access</strong> before public launch</li>
            <li>First crack at the lowest seat numbers (#001–#500)</li>
            <li>Email-only price promise — Founding 500 will never be cheaper than $149.99 to you</li>
          </ul>
          <p style="margin:24px 0 8px;color:#a1a1aa;font-size:14px;">
            We&apos;ll email you the moment checkout opens — typically within ~3 months of the {branding.APP_NAME} launch.
          </p>
        """

        footer_html = f"""
          <tr><td style="padding:0 40px 8px;">
            <p style="margin:24px 0 0;font-size:13px;color:#71717a;line-height:1.6;">
              Why web-only? Apple takes 15% of every in-app purchase. Selling Founding 500 directly on
              <a href="{web_url}/lifetime" style="color:#fbbf24;">{branding.APP_NAME.lower()}.com/lifetime</a> means we keep the savings
              and pour them back into the product (and into the Founder merch drop).
            </p>
          </td></tr>
        """

        html_content = _email_shell(
            logo_url=logo_url,
            preheader=f"You're on the {branding.APP_NAME} Founding 500 waitlist. We'll email you when checkout opens.",
            eyebrow="WAITLIST CONFIRMED",
            title="You&apos;re in.",
            body_html=body_html,
            footer_html=footer_html,
        )

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"You&apos;re on the {branding.APP_NAME} Founding 500 waitlist",
                "html": html_content,
            }
            email = resend.Emails.send(params)
            logger.info(f"Lifetime waitlist confirmation sent to {to_email}")
            return {"id": email.get("id"), "status": "sent"}
        except Exception as e:
            logger.error(f"Failed to send lifetime waitlist confirmation: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_lifetime_checkout_open(
        self,
        to_email: str,
        seats_remaining: int = 500,
    ) -> Dict[str, Any]:
        """Sent to ALL waitlist members the moment Stripe checkout flips on.

        This is the single highest-leverage email in the Founding 500 program —
        it converts the warmest leads. Send via the cron when toggling
        `lifetime_checkout_enabled = True` in production.

        Tone: urgent but earned. They asked to be told first; we&apos;re telling them.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        settings = get_settings()
        logo_url = settings.email_logo_url
        web_url = settings.web_marketing_url

        urgency_line = ""
        if seats_remaining < 500:
            urgency_line = (
                f'<p style="margin:0 0 16px;color:#fbbf24;font-weight:700;">'
                f'Only {seats_remaining} of 500 founder seats remain.'
                f'</p>'
            )

        body_html = f"""
          <p style="margin:0 0 16px;font-size:18px;color:#ffffff;font-weight:600;">
            Founding 500 is open.
          </p>
          <p style="margin:0 0 16px;">
            You asked to be told first. This is that email — checkout is live, and you&apos;ve got 24 hours
            of exclusive access before we open it to everyone else.
          </p>
          {urgency_line}
          <p style="margin:0 0 16px;">
            <strong style="color:#ffffff;">$149.99 once. {branding.APP_NAME} forever.</strong> No subscriptions, no renewals,
            no &quot;upgrade to the next tier&quot; trap. Plus the gold Founder badge, free Founding 500 tee,
            priority AI queue, and direct line to the team — perks future members can never buy.
          </p>
        """

        footer_html = f"""
          <tr><td style="padding:24px 40px 8px;">
            <p style="margin:0;font-size:13px;color:#a1a1aa;line-height:1.6;">
              <strong style="color:#ffffff;">How it works:</strong> Pay via Stripe → receive a confirmation email with your
              Founder seat number → sign in to the {branding.APP_NAME} app with the same email → Premium unlocks automatically.
            </p>
          </td></tr>
          <tr><td style="padding:16px 40px 8px;">
            <p style="margin:0;font-size:12px;color:#71717a;line-height:1.6;">
              30-day refund window if it isn&apos;t for you. After 30 days all sales final (it&apos;s a lifetime product).
              Available exclusively at <a href="{web_url}/lifetime" style="color:#fbbf24;">{branding.APP_NAME.lower()}.com/lifetime</a>.
              Public launch in 24 hours.
            </p>
          </td></tr>
        """

        html_content = _email_shell(
            logo_url=logo_url,
            preheader=f"Founding 500 checkout is now open. You have 24 hours of exclusive access.",
            eyebrow="WAITLIST EARLY ACCESS · 24-HOUR WINDOW",
            title="Founding 500 is live.",
            body_html=body_html,
            cta_label=f"Claim Founding Lifetime — $149.99",
            cta_url=f"{web_url}/lifetime",
            footer_html=footer_html,
        )

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"It&apos;s open. {branding.APP_NAME} Founding 500 — your 24-hour early access starts now",
                "html": html_content,
            }
            email = resend.Emails.send(params)
            logger.info(f"Lifetime checkout-open email sent to {to_email}")
            return {"id": email.get("id"), "status": "sent"}
        except Exception as e:
            logger.error(f"Failed to send lifetime checkout-open email: {e}", exc_info=True)
            return {"error": str(e)}

    async def send_lifetime_purchase_confirmation(
        self,
        to_email: str,
        seat_number: int,
        amount_paid_cents: int = 14999,
        receipt_url: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Sent post-checkout-success webhook. Their permanent activation guide.

        This email is the ONLY persistent record they have of:
        - Which email to sign into the app with
        - Their Founder seat number (for badge / merch fulfillment)
        - Stripe receipt link

        Should never be sent twice for the same purchase. Webhook idempotency
        in lifetime_web.py guarantees that.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        settings = get_settings()
        logo_url = settings.email_logo_url
        web_url = settings.web_marketing_url

        amount_str = f"${amount_paid_cents / 100:.2f}"
        receipt_block = ""
        if receipt_url:
            receipt_block = (
                f'<p style="margin:0 0 12px;font-size:13px;color:#a1a1aa;">'
                f'<a href="{receipt_url}" style="color:#fbbf24;">View your Stripe receipt &rarr;</a>'
                f'</p>'
            )

        body_html = f"""
          <p style="margin:0 0 20px;font-size:18px;color:#ffffff;font-weight:600;">
            Welcome, Founding Member #{seat_number:03d}.
          </p>
          <p style="margin:0 0 24px;">
            Your Founding Lifetime is active. {branding.APP_NAME} is yours forever — every current feature,
            every future feature, no renewals, no surprises.
          </p>

          <!-- Activation card -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
                 style="background:#161616;border:1px solid #2a2a2a;border-radius:14px;margin-bottom:8px;">
            <tr><td style="padding:20px 24px;">
              <p style="margin:0 0 8px;font-size:11px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:#fbbf24;">
                ACTIVATION
              </p>
              <p style="margin:0 0 12px;font-size:15px;color:#ffffff;line-height:1.6;">
                Sign in to the {branding.APP_NAME} app with this email — Premium unlocks automatically:
              </p>
              <div style="background:#0a0a0a;border:1px solid #2a2a2a;border-radius:8px;padding:12px 14px;font-family:'SF Mono',Menlo,monospace;font-size:14px;color:#fafafa;word-break:break-all;">
                {to_email}
              </div>
              <p style="margin:14px 0 0;font-size:13px;color:#a1a1aa;line-height:1.6;">
                Don&apos;t have the app yet? <a href="{web_url}" style="color:#fbbf24;">Download {branding.APP_NAME}</a> &mdash;
                create an account with the email above and your Lifetime is waiting.
              </p>
            </td></tr>
          </table>

          <!-- Founder perks -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
                 style="margin-top:24px;">
            <tr><td style="padding:0;">
              <p style="margin:0 0 12px;font-size:13px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:#71717a;">
                YOUR FOUNDER PERKS
              </p>
            </td></tr>
            <tr><td style="padding:8px 0;border-top:1px solid #1a1a1a;font-size:14px;color:#d4d4d8;">
              <span style="color:#fbbf24;">&#x2713;</span> &nbsp;Lifetime Premium &mdash; every current and future feature
            </td></tr>
            <tr><td style="padding:8px 0;border-top:1px solid #1a1a1a;font-size:14px;color:#d4d4d8;">
              <span style="color:#fbbf24;">&#x2713;</span> &nbsp;Permanent gold Founder badge on your in-app profile
            </td></tr>
            <tr><td style="padding:8px 0;border-top:1px solid #1a1a1a;font-size:14px;color:#d4d4d8;">
              <span style="color:#fbbf24;">&#x2713;</span> &nbsp;Founder seat #{seat_number:03d} of 500
            </td></tr>
            <tr><td style="padding:8px 0;border-top:1px solid #1a1a1a;font-size:14px;color:#d4d4d8;">
              <span style="color:#fbbf24;">&#x2713;</span> &nbsp;Priority queue on AI workout / nutrition generation
            </td></tr>
            <tr><td style="padding:8px 0;border-top:1px solid #1a1a1a;font-size:14px;color:#d4d4d8;">
              <span style="color:#fbbf24;">&#x2713;</span> &nbsp;Founder-only AI coach personas
            </td></tr>
            <tr><td style="padding:8px 0;border-top:1px solid #1a1a1a;font-size:14px;color:#d4d4d8;">
              <span style="color:#fbbf24;">&#x2713;</span> &nbsp;Free Founding 500 tee &mdash; we&apos;ll email you to collect shipping info once we hit 500
            </td></tr>
            <tr><td style="padding:8px 0;border-top:1px solid #1a1a1a;font-size:14px;color:#d4d4d8;">
              <span style="color:#fbbf24;">&#x2713;</span> &nbsp;Direct line to the founder &mdash; reply to this email
            </td></tr>
          </table>
        """

        footer_html = f"""
          <tr><td style="padding:24px 40px 0;">
            <p style="margin:0 0 8px;font-size:13px;font-weight:700;color:#a1a1aa;">Receipt</p>
            <p style="margin:0 0 4px;font-size:13px;color:#71717a;">
              Founding Lifetime &middot; {amount_str} &middot; one-time
            </p>
            {receipt_block}
            <p style="margin:12px 0 0;font-size:12px;color:#52525b;line-height:1.6;">
              30-day refund window from purchase. After that, all sales final &mdash; it&apos;s a lifetime product.
              Stripe handles all billing inquiries. For everything else, just reply to this email.
            </p>
          </td></tr>
        """

        html_content = _email_shell(
            logo_url=logo_url,
            preheader=f"Founder seat #{seat_number:03d}. Sign in to the {branding.APP_NAME} app with this email.",
            eyebrow=f"FOUNDER #{seat_number:03d} OF 500",
            title=f"Welcome, Founder.",
            body_html=body_html,
            cta_label=f"Open {branding.APP_NAME} &rarr;",
            cta_url=web_url,
            footer_html=footer_html,
        )

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"You&apos;re Founder #{seat_number:03d}. Activate {branding.APP_NAME} Lifetime in 30 seconds.",
                "html": html_content,
            }
            email = resend.Emails.send(params)
            logger.info(f"Lifetime purchase confirmation sent to {to_email} (seat #{seat_number})")
            return {"id": email.get("id"), "status": "sent"}
        except Exception as e:
            logger.error(f"Failed to send lifetime purchase confirmation: {e}", exc_info=True)
            return {"error": str(e)}
