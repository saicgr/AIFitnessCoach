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

All three render via the shared Zealova "Signature" email design
(`services.email_signature_template`) so Founding 500 sits on the same chrome as
every other Zealova email — premium feel comes from the sparkles/gift/calendar
hero icons + the receipt-style detail_block, not a separate visual lane.
"""
from __future__ import annotations

from typing import Any, Dict, Optional

import resend

from core import branding
from core.logger import get_logger
from services import email_signature_template as sig

logger = get_logger(__name__)


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
        web_url = settings.web_marketing_url

        position_callout = ""
        if position is not None:
            position_callout = sig.callout(
                f"You're approximately #<b style=\"color:{sig.ACCENT};\">{position}</b> on the list."
            )

        body_html = (
            position_callout
            + sig.callout(
                f"Founding Lifetime is a one-time $149.99 purchase that gets you "
                f"{branding.APP_NAME} forever — every current and future Premium feature, "
                f"locked at zero recurring cost. Only 500 of these will ever exist."
            )
            + sig.section_label("What waitlist members get")
            + sig.info_rows([
                ("clock", "24-hour exclusive access", "Before public launch"),
                ("medal", "Lowest seat numbers", "First crack at #001–#500"),
                ("shield", "Email-only price promise",
                 f"Founding 500 will never be cheaper than $149.99 to you"),
            ])
            + sig.callout(
                f"We'll email you the moment checkout opens — typically within ~3 months "
                f"of the {branding.APP_NAME} launch."
            )
        )

        html_content = sig.signature_email(
            header_tag="Lifetime",
            hero_icon="sparkles",
            hero_title="You're in.",
            hero_sub="You're on the Founding 500 waitlist.",
            body_html=body_html,
            preheader=(
                f"You're on the {branding.APP_NAME} Founding 500 waitlist. "
                f"We'll email you when checkout opens."
            ),
            footer_kind="transactional",
            footer_note=(
                f"Why web-only? Apple takes 15% of every in-app purchase. Selling Founding 500 "
                f"directly on {branding.APP_NAME.lower()}.com/lifetime means we keep the savings "
                f"and pour them back into the product (and the Founder merch drop). Sent because "
                f"you joined the Founding 500 waitlist."
            ),
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

        Tone: urgent but earned. They asked to be told first; we're telling them.
        """
        if not self.is_configured():
            return {"error": "Email service not configured"}

        from core.config import get_settings
        settings = get_settings()
        web_url = settings.web_marketing_url

        urgency_callout = ""
        if seats_remaining < 500:
            urgency_callout = sig.callout(
                f"Only <b style=\"color:{sig.ACCENT};\">{seats_remaining} of 500</b> founder seats remain."
            )

        body_html = (
            sig.callout(
                f"You asked to be told first. This is that email — checkout is live, and you've "
                f"got 24 hours of exclusive access before we open it to everyone else."
            )
            + urgency_callout
            + sig.detail_block([
                ("Founding Lifetime", "$149.99"),
                ("Billing", "One-time"),
                ("Renewals", "None, ever"),
            ])
            + sig.section_label("Founder perks future members can never buy")
            + sig.info_rows([
                ("medal", "Gold Founder badge", "Permanent, on your in-app profile"),
                ("gift", "Free Founding 500 tee", "Members-only merch drop"),
                ("zap", "Priority AI queue", "Faster workout & nutrition generation"),
                ("message", "Direct line to the team", "Reply and we read it"),
            ])
            + sig.pill_cta("Claim Founding Lifetime — $149.99", f"{web_url}/lifetime")
            + sig.callout(
                f"<b style=\"color:{sig.INK};\">How it works:</b> Pay via Stripe, receive a confirmation "
                f"email with your Founder seat number, sign in to the {branding.APP_NAME} app with the "
                f"same email, and Premium unlocks automatically. 30-day refund window; after that all sales "
                f"final (it's a lifetime product). Public launch in 24 hours."
            )
        )

        html_content = sig.signature_email(
            header_tag="Lifetime",
            hero_icon="clock",
            hero_title="Founding 500 is live.",
            hero_sub="$149.99 once. Zealova forever.",
            body_html=body_html,
            preheader="Founding 500 checkout is now open. You have 24 hours of exclusive access.",
            footer_kind="transactional",
            footer_note=(
                f"Available exclusively at {branding.APP_NAME.lower()}.com/lifetime. "
                f"Sent because you joined the Founding 500 waitlist."
            ),
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
        web_url = settings.web_marketing_url

        amount_str = f"${amount_paid_cents / 100:.2f}"

        # Receipt-style detail strip — the persistent record of seat + payment.
        receipt_rows = [
            ("Founder seat", f"#{seat_number:03d} of 500"),
            ("Founding Lifetime", amount_str),
            ("Billing", "One-time"),
        ]
        receipt_block = sig.detail_block(receipt_rows)

        receipt_link_callout = ""
        if receipt_url:
            receipt_link_callout = sig.callout(
                "Need a record for your files?", "View your Stripe receipt", receipt_url
            )

        # Activation card — the single most important thing in this email:
        # which email to sign in with. Kept as a custom mono code block so the
        # address is unmistakable and copy-pasteable.
        activation_card = (
            f'<tr><td style="padding:24px 22px 0;">'
            f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" '
            f'bgcolor="{sig.CARD}" style="background:{sig.CARD};border:1px solid {sig.LINE};'
            f'border-radius:14px;"><tr><td style="padding:20px 22px;">'
            f'<div style="font-family:{sig.F_LBL};text-transform:uppercase;letter-spacing:2px;'
            f'font-size:11px;color:{sig.ACCENT};font-weight:700;">Activation</div>'
            f'<div style="font-family:{sig.F_LBL};font-size:15px;color:{sig.INK};line-height:1.6;'
            f'letter-spacing:.3px;margin-top:8px;">Sign in to the {branding.APP_NAME} app with this '
            f'email — Premium unlocks automatically:</div>'
            f'<div style="background:{sig.BG};border:1px solid {sig.LINE};border-radius:8px;'
            f'padding:12px 14px;margin-top:12px;font-family:\'SF Mono\',Menlo,monospace;font-size:14px;'
            f'color:{sig.INK};word-break:break-all;">{to_email}</div>'
            f'<div style="font-family:{sig.F_LBL};font-size:13px;color:{sig.GREY};line-height:1.6;'
            f'letter-spacing:.3px;margin-top:12px;">Don\'t have the app yet? '
            f'<a href="{web_url}" style="color:{sig.ACCENT};text-decoration:none;">Download '
            f'{branding.APP_NAME}</a> — create an account with the email above and your Lifetime '
            f'is waiting.</div>'
            f'</td></tr></table></td></tr>'
        )

        body_html = (
            sig.callout(
                f"Your Founding Lifetime is active. {branding.APP_NAME} is yours forever — every "
                f"current feature, every future feature, no renewals, no surprises."
            )
            + receipt_block
            + receipt_link_callout
            + activation_card
            + sig.section_label("Your founder perks")
            + sig.info_rows([
                ("check_circle", "Lifetime Premium", "Every current and future feature"),
                ("medal", "Gold Founder badge", "Permanent, on your in-app profile"),
                ("trophy", "Founder seat", f"#{seat_number:03d} of 500"),
                ("zap", "Priority AI queue", "Faster workout & nutrition generation"),
                ("sparkles", "Founder-only AI coach personas", "Voices future members can't get"),
                ("gift", "Free Founding 500 tee", "We'll email for shipping once we hit 500"),
                ("message", "Direct line to the founder", "Reply to this email"),
            ])
            + sig.pill_cta(f"Open {branding.APP_NAME}", web_url)
        )

        html_content = sig.signature_email(
            header_tag="Receipt",
            hero_icon="check_circle",
            hero_title=f"Welcome, Founder #{seat_number:03d}.",
            hero_sub="Your Founding Lifetime is active.",
            body_html=body_html,
            preheader=(
                f"Founder seat #{seat_number:03d}. Sign in to the {branding.APP_NAME} app "
                f"with this email."
            ),
            footer_kind="transactional",
            footer_note=(
                f"This is your receipt for a {branding.APP_NAME} Founding Lifetime purchase. "
                f"30-day refund window from purchase; after that all sales final — it's a lifetime "
                f"product. Stripe handles billing inquiries; for everything else, reply to this email."
            ),
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
