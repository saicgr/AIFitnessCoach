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

import resend

from core import branding
from core.logger import get_logger

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
        logo_url = f"{backend_url}/static/logo.png"
        # Sign-out URL is opaque to the email; the backend resolves the
        # device_id token from the link. None → hide the button rather than
        # ship a broken link.
        revoke_url = sign_out_url

        when = (signed_in_at or datetime.now(timezone.utc)).strftime(
            "%B %-d, %-I:%M%p UTC"
        )
        display_name = (first_name or "there").split()[0]
        platform_label = (platform or "").lower()
        device_emoji = (
            "&#128241;" if platform_label in ("ios", "android") else "&#128187;"
        )
        safe_device = device_label or "Unknown device"
        safe_location = location or "Unknown location"
        safe_ip = ip or "Unknown IP"

        subject = f"New sign-in to your {branding.APP_NAME} account, {display_name}"

        revoke_block = ""
        if revoke_url:
            revoke_block = f"""
            <tr>
              <td align="center" style="padding:8px 40px 32px;">
                <a href="{revoke_url}"
                   style="display:inline-block;padding:14px 28px;background:#ef4444;color:#ffffff;
                          text-decoration:none;font-size:14px;font-weight:600;border-radius:10px;">
                  Sign out of this device
                </a>
                <p style="margin:14px 0 0;font-size:12px;color:#71717a;line-height:1.5;">
                  If the link doesn't work, open the {branding.APP_NAME} app → Settings → Security → Manage devices.
                </p>
              </td>
            </tr>"""

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>New sign-in to your {branding.APP_NAME} account</title>
</head>
<body style="margin:0;padding:0;background-color:#000000;
             font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color:#000000;min-height:100vh;">
    <tr>
      <td align="center" style="padding:40px 16px;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
               style="max-width:560px;background-color:#0f0f0f;border-radius:20px;
                      overflow:hidden;border:1px solid #1a1a1a;">
          <tr>
            <td style="background:linear-gradient(135deg,#dc2626 0%,#f97316 100%);
                       height:4px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>
          <tr>
            <td align="center" style="padding:36px 40px 12px;">
              <img src="{logo_url}" alt="{branding.APP_NAME}" width="64" height="64"
                   style="display:block;border-radius:14px;border:0;width:64px;height:64px;object-fit:cover;">
              <p style="margin:14px 0 0;font-size:11px;font-weight:700;letter-spacing:3px;
                        text-transform:uppercase;color:#a1a1aa;">FITWIZ &middot; SECURITY</p>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding:8px 40px 24px;">
              <h1 style="margin:0;font-size:22px;font-weight:700;color:#ffffff;line-height:1.3;">
                New sign-in to your account
              </h1>
              <p style="margin:14px 0 0;font-size:14px;color:#a1a1aa;line-height:1.6;">
                Hi {display_name}, a new device just signed into your {branding.APP_NAME} account.
                If this was you, no action is needed. If you don't recognize it,
                sign out below and change your password.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:0 32px 24px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
                     style="background-color:#171717;border-radius:14px;border:1px solid #262626;">
                <tr>
                  <td style="padding:18px 22px;">
                    <p style="margin:0 0 4px;font-size:11px;color:#71717a;
                              letter-spacing:1.5px;text-transform:uppercase;font-weight:600;">Device</p>
                    <p style="margin:0;font-size:15px;color:#ffffff;font-weight:600;">
                      {device_emoji} &nbsp; {safe_device}
                    </p>
                  </td>
                </tr>
                <tr><td style="padding:0 22px;"><div style="height:1px;background:#262626;"></div></td></tr>
                <tr>
                  <td style="padding:18px 22px;">
                    <p style="margin:0 0 4px;font-size:11px;color:#71717a;
                              letter-spacing:1.5px;text-transform:uppercase;font-weight:600;">Location</p>
                    <p style="margin:0;font-size:15px;color:#ffffff;">{safe_location}</p>
                    <p style="margin:6px 0 0;font-size:12px;color:#71717a;font-family:monospace;">{safe_ip}</p>
                  </td>
                </tr>
                <tr><td style="padding:0 22px;"><div style="height:1px;background:#262626;"></div></td></tr>
                <tr>
                  <td style="padding:18px 22px;">
                    <p style="margin:0 0 4px;font-size:11px;color:#71717a;
                              letter-spacing:1.5px;text-transform:uppercase;font-weight:600;">When</p>
                    <p style="margin:0;font-size:15px;color:#ffffff;">{when}</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          {revoke_block}
          <tr>
            <td style="padding:0 40px 28px;">
              <p style="margin:0;font-size:12px;color:#52525b;line-height:1.6;">
                You're receiving this because we detected a sign-in from a device that hadn't
                accessed your {branding.APP_NAME} account before. Security alerts can't be turned off — they
                protect your account. Questions? Reach us on
                <a href="{branding.DISCORD_URL}" style="color:#a1a1aa;">Discord</a> or
                <a href="{branding.INSTAGRAM_URL}" style="color:#a1a1aa;">Instagram</a>.
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
            email = resend.Emails.send(params)
            logger.info(
                f"Sent new-device alert to {to_email} (device={safe_device}, "
                f"location={safe_location}, id={email.get('id') if email else '?'})"
            )
            return {"success": True, "email_id": email.get("id") if email else None}
        except Exception as e:
            logger.exception(f"Failed to send new-device alert to {to_email}: {e}")
            return {"error": str(e)}
