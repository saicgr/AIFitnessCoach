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

from core import branding
from core.logger import get_logger
from services import email_sender
from services import email_signature_template as sig

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
    """Render the result_summary dict as a signature key/value detail block.

    Skips nested objects / arrays past 4 items to keep the email compact.
    Caller is trusted to pass a flat shape from the tool's
    `emailCaptureResult` prop. Returns a signature `<tr>` fragment (or "").
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

        rows.append((_prettify_key(key), display))

    return sig.detail_block(rows)


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

        body_html = (
            sig.callout(
                "You asked us to save this so you wouldn't lose it. Here it is. "
                "No spam, no drip campaigns. One follow-up if Zealova for iOS launches."
            )
            + result_table
            + sig.callout(
                "The math is the same in the Zealova app, but it runs against your "
                "real training and food logs and adjusts automatically.",
                link_text="Recompute",
                link_url=tool_url,
            )
            + sig.pill_cta("Get Zealova for Android", play_store_url)
            + sig.callout(
                "7-day free trial. $7.99/mo or $59.99/yr after. iOS launching soon."
            )
        )

        html_content = sig.signature_email(
            header_tag="Your result",
            hero_title=f"Hi {first_name_fallback}, here's your result.",
            hero_sub=copy["headline"],
            hero_icon="activity",
            body_html=body_html,
            footer_kind="transactional",
            footer_note="You received this because you used a free Zealova tool.",
            preheader=copy["subject"],
        )

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
            # EXEMPT from the frequency cap (free-tool leads have no account, and
            # this is the one thing they explicitly asked us to send); the
            # undeliverable-domain guard still applies.
            response = email_sender.send(params, email_type="free_tool_result")
            if response.get("skipped"):
                logger.info(
                    "[email_free_tools] NOT sent to=%s*** tool=%s reason=%s",
                    to_email[:3],
                    tool_slug,
                    response.get("reason"),
                )
            else:
                logger.info(
                    "[email_free_tools] sent to=%s*** tool=%s id=%s",
                    to_email[:3],
                    tool_slug,
                    response.get("id"),
                )
            return email_sender.sent_result(response)
        except Exception as e:
            logger.error(
                "[email_free_tools] send failed to=%s*** tool=%s: %s",
                to_email[:3],
                tool_slug,
                e,
                exc_info=True,
            )
            return {"error": str(e)}
