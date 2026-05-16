"""Notify roadmap voters that a feature has shipped.

When a feature on the public /roadmap board moves to "Released", run this to
email everyone who voted for it AND opted in to ship notifications
(roadmap_votes.notify_on_ship = true). One email per address, ever.

Usage (from the backend/ directory):
    .venv/bin/python scripts/notify_roadmap_voters.py <feature_slug> "Feature Title" [--dry-run]

Examples:
    .venv/bin/python scripts/notify_roadmap_voters.py form-check-video "Form check from video" --dry-run
    .venv/bin/python scripts/notify_roadmap_voters.py form-check-video "Form check from video"

Requires RESEND_API_KEY + RESEND_FROM_EMAIL in backend/.env (same as the
waitlist confirmation email).
"""
import os
import sys

# Allow `from core...` imports when run as a standalone script.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

import resend  # noqa: E402
from core.supabase_client import get_supabase  # noqa: E402


def _email_html(feature_title: str) -> str:
    """Transactional email — Zealova brand voice (not a coach persona)."""
    app_url = "https://zealova.com"
    return f"""\
<!DOCTYPE html>
<html>
  <body style="margin:0;background:#f4f4f5;font-family:-apple-system,Segoe UI,Roboto,sans-serif;">
    <div style="max-width:480px;margin:0 auto;padding:40px 24px;">
      <div style="background:#ffffff;border-radius:16px;padding:32px;">
        <p style="margin:0 0 4px;font-size:12px;font-weight:700;letter-spacing:1px;
                  text-transform:uppercase;color:#3b82f6;">It shipped</p>
        <h1 style="margin:0 0 16px;font-size:22px;color:#18181b;line-height:1.3;">
          {feature_title} is now live
        </h1>
        <p style="margin:0 0 16px;font-size:15px;line-height:1.6;color:#3f3f46;">
          You voted for this on the Zealova roadmap. We said we'd tell you the
          day it went live &mdash; today's the day. It's in the app now.
        </p>
        <a href="{app_url}" style="display:inline-block;background:#10b981;color:#ffffff;
              text-decoration:none;font-weight:600;font-size:14px;
              padding:12px 22px;border-radius:999px;">Open Zealova</a>
        <p style="margin:24px 0 0;font-size:12px;color:#a1a1aa;line-height:1.6;">
          You're getting this because you voted for this feature and asked to be
          notified. We only email you when something you backed actually ships.
        </p>
      </div>
    </div>
  </body>
</html>
"""


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry_run = "--dry-run" in sys.argv

    if not args:
        print(__doc__)
        return 1

    feature_slug = args[0]
    feature_title = args[1] if len(args) > 1 else feature_slug

    api_key = os.getenv("RESEND_API_KEY")
    from_email = os.getenv("RESEND_FROM_EMAIL", "Zealova <hello@zealova.com>")
    if not api_key:
        print("ERROR: RESEND_API_KEY not set in backend/.env")
        return 1

    db = get_supabase()
    rows = (
        db.client.table("roadmap_votes")
        .select("email")
        .eq("feature_slug", feature_slug)
        .eq("notify_on_ship", True)
        .execute()
    )
    emails = sorted({(r["email"] or "").strip().lower() for r in (rows.data or []) if r.get("email")})

    print(f"Feature : {feature_slug}  ({feature_title!r})")
    print(f"Voters opted in to ship notice: {len(emails)}")
    if not emails:
        print("Nothing to send.")
        return 0
    if dry_run:
        print("\n-- DRY RUN — no emails sent. Recipients:")
        for e in emails:
            print(f"  {e}")
        print(f"\nRe-run without --dry-run to send to {len(emails)} address(es).")
        return 0

    resend.api_key = api_key
    html = _email_html(feature_title)
    sent, failed = 0, 0
    for email in emails:
        try:
            resend.Emails.send({
                "from": from_email,
                "to": [email],
                "subject": f"{feature_title} just shipped — you voted for it",
                "html": html,
            })
            sent += 1
        except Exception as e:  # noqa: BLE001
            failed += 1
            print(f"  FAILED {email}: {e}")

    print(f"\nDone. Sent {sent}, failed {failed}.")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
