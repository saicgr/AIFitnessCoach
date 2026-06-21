# AMP for Email — infra track (deferred, not blocking)

**Status:** blocked on infra. Documented 2026-06-21 so it isn't lost. CSS-kinetic
interactivity ships first (works on the current Resend infra); AMP is a follow-up.

## Why it's blocked

AMP for Email delivers true in-inbox interactivity (live data, forms, carousels,
accordions) in **Gmail, Yahoo Mail, Mail.ru**. It is delivered as an extra MIME part
with content type `text/x-amp-html`, alongside the regular `text/html` fallback.

**Resend cannot send that part.** The Resend send-email endpoint accepts only
`from, to, subject, bcc, cc, scheduled_at, reply_to, html, text, react, headers,
topic_id, attachments, tags, template` (verified against
https://resend.com/docs/api-reference/emails/send-email — no `amp_html` / AMP field).

## What enabling AMP would require (in order)

1. **Move to (or add) an AMP-capable ESP.** Providers with a documented AMP/`amp_html`
   field: **Amazon SES, SendGrid, SparkPost, Mailgun**. This touches:
   - All `resend.Emails.send(...)` call sites in `backend/services/email_*.py`
     (wrap behind a thin sender interface so the ESP is swappable).
   - Domain auth — SPF / DKIM / DMARC re-config for the new sending domain.
   - Sender reputation / warm-up; bounce + complaint webhooks re-wired.
2. **Register the sender with Google** for AMP rendering in Gmail:
   https://amp.dev/documentation/guides-and-tutorials/start/email_sender_distribution
   — requires production AMP samples, a real (not no-reply) reply-to, DKIM/SPF aligned,
   and low spam rates. Review takes time and can be rejected.
3. **Author the AMP MIME part** per email (valid AMP4EMAIL: `<html ⚡4email>`, allowed
   `amp-*` components only, `amp-form`/`amp-list`/`amp-carousel`/`amp-accordion`).
   The CSS-kinetic HTML built now stays as the mandatory fallback for Apple Mail/Outlook
   (which ignore AMP), so AMP is purely additive.

## Recommendation

Revisit only if analytics show a large Gmail-open share AND a concrete interactive
use-case that CSS-kinetic can't cover (e.g. submit-a-form-in-email, real-time data).
For tabs/accordions/carousels/hover, CSS-kinetic already covers Apple/iOS Mail with a
clean Gmail fallback — AMP's marginal gain there doesn't justify an ESP migration.
