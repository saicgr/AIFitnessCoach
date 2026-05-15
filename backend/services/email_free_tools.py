"""
Email mixin for free-tool result captures.

Fires from POST /api/v1/free-tools/email-signup as a BackgroundTask when a
visitor submits their email after using a calculator (or via the exit-intent
modal). Single transactional email, no drip campaigns, no marketing.

Voice rules (project-wide):
  - No em dashes. Periods or commas only.
  - First name fallback to "there" only if email-prefix split fails.
  - One Play Store CTA, one Zealova footer. No multi-link chrome.
"""

from typing import Any, Dict, Optional
import json
import resend

from core import branding
from core.logger import get_logger
from services.email_helpers import build_social_footer_html

logger = get_logger(__name__)


# Per-tool subject + headline overrides. Any slug not in this map falls back
# to a generic "Your result from Zealova" subject + the tool slug as title.
_TOOL_COPY: Dict[str, Dict[str, str]] = {
    "tdee-calculator": {
        "subject": "Your TDEE result from Zealova",
        "headline": "Your TDEE",
    },
    "1rm-calculator": {
        "subject": "Your estimated 1RM from Zealova",
        "headline": "Your 1RM estimate",
    },
    "macro-calculator": {
        "subject": "Your macro split from Zealova",
        "headline": "Your daily macros",
    },
    "bmr-calculator": {
        "subject": "Your BMR from Zealova",
        "headline": "Your BMR",
    },
    "body-fat-calculator": {
        "subject": "Your body fat estimate from Zealova",
        "headline": "Your body fat estimate",
    },
    "ai-food-photo": {
        "subject": "Your meal analysis from Zealova",
        "headline": "Your meal",
    },
    "ai-workout-generator": {
        "subject": "Your generated workout from Zealova",
        "headline": "Your workout",
    },
    "ai-physique-analyzer": {
        "subject": "Your physique analysis from Zealova",
        "headline": "Your physique analysis",
    },
    "fat-loss-protocol-calculator": {
        "subject": "Your fat-loss protocol from Zealova",
        "headline": "Your fat-loss plan",
    },
    "workout-plan-builder": {
        "subject": "Your 4-week plan from Zealova",
        "headline": "Your 4-week plan",
    },
    "calorie-deficit-tracker": {
        "subject": "Your weekly deficit summary from Zealova",
        "headline": "Your weekly deficit",
    },
}


def _prettify_key(key: str) -> str:
    """Turn snake_case / kebab-case keys into Title Case display labels."""
    return key.replace("_", " ").replace("-", " ").strip().title()


def _build_result_rows_html(result_summary: Optional[Dict[str, Any]]) -> str:
    """Render the result_summary dict as a flat 2-column HTML table.

    Skips nested objects / arrays past 4 items to keep the email compact.
    Caller is trusted to pass a flat shape from the tool's
    `emailCaptureResult` prop.
    """
    if not result_summary:
        return ""

    rows = []
    for key, value in result_summary.items():
        # Render arrays as a comma-joined preview, dicts as JSON one-liners.
        if isinstance(value, (list, tuple)):
            display = ", ".join(str(v) for v in list(value)[:4])
            if len(value) > 4:
                display += f", and {len(value) - 4} more"
        elif isinstance(value, dict):
            try:
                display = json.dumps(value, separators=(", ", ": "))
            except (TypeError, ValueError):
                display = str(value)
        elif isinstance(value, float):
            display = f"{value:.1f}".rstrip("0").rstrip(".")
        else:
            display = str(value)

        rows.append(
            '<tr>'
            f'<td style="padding:10px 16px;border-bottom:1px solid #1f2937;color:#9ca3af;font-size:13px;letter-spacing:0.5px;text-transform:uppercase;">{_prettify_key(key)}</td>'
            f'<td style="padding:10px 16px;border-bottom:1px solid #1f2937;color:#fafafa;font-size:15px;font-weight:600;text-align:right;">{display}</td>'
            '</tr>'
        )

    return (
        '<table role="presentation" cellpadding="0" cellspacing="0" border="0" '
        'style="width:100%;border-collapse:collapse;background:#09090b;'
        'border:1px solid #1f2937;border-radius:12px;overflow:hidden;'
        'margin:24px 0;">'
        + "".join(rows)
        + "</table>"
    )


class EmailFreeToolsMixin:
    """Single transactional email for free-tool result captures."""

    async def send_free_tool_result(
        self,
        to_email: str,
        tool_slug: str,
        result_summary: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Send a one-shot result-recap email after a free-tool email capture.

        Returns dict with `success` + `id` on Resend acceptance, or `error`
        with the Resend-side message on failure. Never raises; callers
        invoke this from a FastAPI BackgroundTask so a bounce / API outage
        must not break the request.
        """
        if not getattr(self, "is_configured", lambda: False)():
            logger.error(
                "[email_free_tools] Resend not configured; skipping send to %s***",
                to_email[:3],
            )
            return {"error": "Email service not configured"}

        first_name_fallback = "there"
        try:
            local = to_email.split("@", 1)[0]
            # "sai.chetan" -> "Sai", "sai_chetan" -> "Sai"
            first = local.split(".")[0].split("_")[0]
            if first and first[0].isalpha():
                first_name_fallback = first[:24].title()
        except Exception:
            pass

        copy = _TOOL_COPY.get(
            tool_slug,
            {"subject": "Your result from Zealova", "headline": _prettify_key(tool_slug)},
        )

        result_table = _build_result_rows_html(result_summary)
        tool_url = f"https://{branding.MARKETING_DOMAIN}/free-tools/{tool_slug}"
        play_store_url = (
            "https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
            f"&referrer=utm_source%3Demail%26utm_medium%3Dfreetool%26utm_content%3D{tool_slug}"
        )

        social_footer = build_social_footer_html()

        html_content = f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{copy['subject']}</title>
</head>
<body style="margin:0;padding:0;background:#0a0a0a;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif;">
  <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background:#0a0a0a;">
    <tr>
      <td align="center" style="padding:40px 20px;">
        <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="max-width:560px;background:#0a0a0a;">
          <tr>
            <td style="padding:0 0 32px 0;">
              <p style="margin:0;color:#10b981;font-size:13px;font-weight:700;letter-spacing:2px;text-transform:uppercase;">Zealova</p>
            </td>
          </tr>
          <tr>
            <td style="padding:0 0 8px 0;">
              <p style="margin:0;color:#10b981;font-size:13px;font-weight:600;letter-spacing:1px;text-transform:uppercase;">{copy['headline']}</p>
            </td>
          </tr>
          <tr>
            <td style="padding:0 0 16px 0;">
              <h1 style="margin:0;color:#fafafa;font-size:28px;line-height:1.25;font-weight:800;letter-spacing:-0.5px;">Hi {first_name_fallback}, here's your result.</h1>
            </td>
          </tr>
          <tr>
            <td style="padding:0 0 8px 0;">
              <p style="margin:0;color:#a1a1aa;font-size:15px;line-height:1.6;">
                You asked us to save this so you wouldn't lose it. Here it is. No spam, no drip campaigns. One follow-up if Zealova for iOS launches.
              </p>
            </td>
          </tr>
          {result_table}
          <tr>
            <td style="padding:8px 0 24px 0;">
              <p style="margin:0;color:#a1a1aa;font-size:14px;line-height:1.6;">
                Open <a href="{tool_url}" style="color:#34d399;text-decoration:none;font-weight:600;">{copy['headline']}</a> any time to recompute. The math is the same in the Zealova app, but it runs against your real training and food logs and adjusts automatically.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:0 0 12px 0;">
              <a href="{play_store_url}" style="display:inline-block;padding:14px 28px;background:#10b981;color:#0a0a0a;font-size:15px;font-weight:700;text-decoration:none;border-radius:12px;">Get Zealova for Android</a>
            </td>
          </tr>
          <tr>
            <td style="padding:0 0 32px 0;">
              <p style="margin:0;color:#52525b;font-size:12px;line-height:1.6;">
                7-day free trial. $7.99/mo or $59.99/yr after. iOS launching soon.
              </p>
            </td>
          </tr>
          {social_footer}
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
                "subject": copy["subject"],
                "html": html_content,
                "tags": [
                    {"name": "category", "value": "free_tool_result"},
                    {"name": "tool", "value": tool_slug[:50]},
                ],
            }
            response = resend.Emails.send(params)
            logger.info(
                "[email_free_tools] sent to=%s*** tool=%s id=%s",
                to_email[:3],
                tool_slug,
                response.get("id") if isinstance(response, dict) else response,
            )
            return {
                "success": True,
                "id": response.get("id") if isinstance(response, dict) else None,
            }
        except Exception as e:
            logger.error(
                "[email_free_tools] send failed to=%s*** tool=%s: %s",
                to_email[:3],
                tool_slug,
                e,
                exc_info=True,
            )
            return {"error": str(e)}
