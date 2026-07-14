"""
Security/audit emails — sent when a security-relevant event happens on the
account (new device sign-in today; password reset, etc.).

These are Zealova-voice (transactional, not motivational) and ALWAYS send
regardless of marketing-email preferences — the user can't opt out of being
told someone signed into their account from an unrecognized device. Honors
the per-category toggle `notification_preferences.security_alerts` (default
true) but ignores the master "marketing emails off" switch.
"""
from datetime import datetime, timezone
from typing import Any, Dict, Optional

from core import branding
from core.logger import get_logger
from services import email_sender
from services import email_signature_template as sig

logger = get_logger(__name__)


class EmailSecurityMixin:
    """Security-alert email methods mixed into EmailService."""

    async def send_new_device_signin_email(
        self,
        to_email: str,
        first_name: Optional[str],
        device_label: str,
        platform: Optional[str],
        location: Optional[str],
        ip: Optional[str],
        signed_in_at: Optional[datetime] = None,
        sign_out_url: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Send the "new sign-in to your account" alert.

        device_label: human string like "iPhone 15 Pro" or "OkHttp / Android 14".
        location: best-effort city/country from IP geolocation, or None.
        sign_out_url: deep-link the user can tap to revoke this session
                      (handled by /api/v1/users/me/security/revoke-device).
        """
        if not self.is_configured():
            logger.error("Cannot send new-device alert — Resend API key missing")
            return {"error": "Email service not configured"}

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        # Sign-out URL is opaque to the email; the backend resolves the
        # device_id token from the link. None → hide the button rather than
        # ship a broken link.
        revoke_url = sign_out_url

        when = (signed_in_at or datetime.now(timezone.utc)).strftime(
            "%B %-d, %-I:%M%p UTC"
        )
        display_name = (first_name or "there").split()[0]
        safe_device = device_label or "Unknown device"
        safe_location = location or "Unknown location"
        safe_ip = ip or "Unknown IP"

        subject = f"New sign-in to your {branding.APP_NAME} account, {display_name}"

        # Signature design — centered Anton hero + key/value detail card. The
        # detail rows mirror the original (Device / Location / IP / When); the
        # revoke CTA renders only when we have a working link.
        detail_rows = [
            ("Device", safe_device),
            ("Location", safe_location),
            ("IP", safe_ip),
            ("When", when),
        ]
        body_html = sig.detail_block(detail_rows)
        if revoke_url:
            body_html += sig.pill_cta(
                "This wasn't me — secure my account", revoke_url
            )

        html_content = sig.signature_email(
            header_tag="Security",
            hero_title="New sign-in",
            hero_sub=(
                f"Hi {display_name}, a new device just signed into your "
                f"{branding.APP_NAME} account. If this was you, you're all set — "
                "if not, secure your account below and change your password."
            ),
            hero_icon="shield_check",
            body_html=body_html,
            footer_kind="security",
            footer_note="Security alerts are always sent and can't be turned off.",
            preheader=f"New sign-in to your {branding.APP_NAME} account",
        )

        try:
            params: Dict[str, Any] = {
                "from": self.from_email,
                "to": [to_email],
                "subject": subject,
                "html": html_content,
                "tags": [
                    {"name": "category", "value": "security_alert"},
                    {"name": "type", "value": "new_device_signin"},
                ],
            }
            # EXEMPT from the frequency cap (security mail always goes out); the
            # undeliverable-domain guard still applies.
            email = email_sender.send(params, email_type="new_device_signin")
            if email.get("skipped"):
                logger.info(
                    f"New-device alert NOT sent to {to_email} "
                    f"(reason={email.get('reason')})"
                )
                return {
                    "success": False,
                    "skipped": True,
                    "reason": email.get("reason"),
                    "email_id": None,
                }
            logger.info(
                f"Sent new-device alert to {to_email} (device={safe_device}, "
                f"location={safe_location}, id={email.get('id') if email else '?'})"
            )
            return {"success": True, "email_id": email.get("id") if email else None}
        except Exception as e:
            logger.exception(f"Failed to send new-device alert to {to_email}: {e}")
            return {"error": str(e)}
