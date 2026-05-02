# Zealova Supabase Auth Emails — Branded Templates

These six HTML files replace the default Supabase Auth email templates.
They match the in-app Zealova design system: orange accent (#F97316),
dark mode, 88px rounded logo, cyan→orange gradient bar, single CTA pill.

## How to install (15 minutes, all in Supabase dashboard)

1. **Authentication → URL Configuration**
   - Site URL: `https://zealova.com`
   - Redirect URLs (add ALL of these to the allow-list):
     - `zealova://auth/callback`
     - `fitwiz://auth/callback`        (legacy scheme — keep until next major release)
     - `https://zealova.com/auth/callback`
     - `https://zealova.com/**`        (wildcard for future routes)

2. **Authentication → Email Templates**
   For each of the 6 templates below, paste the HTML body and update the subject:

   | Template | File | Subject |
   |---|---|---|
   | Confirm signup | `confirm_signup.html` | `Confirm your Zealova account` |
   | Invite user | `invite.html` | `You're invited to Zealova` |
   | Magic Link | `magic_link.html` | `Your Zealova sign-in link` |
   | Change Email Address | `change_email.html` | `Confirm your new Zealova email` |
   | Reset Password | `reset_password.html` | `Reset your Zealova password` |
   | Reauthentication | `reauthentication.html` | `Confirm it's really you` |

3. **Authentication → SMTP Settings → Custom SMTP**
   Enable Custom SMTP and wire your existing Resend / SendGrid / Postmark
   credentials (same provider that powers `backend/services/email_service.py`).
   - Sender name: `Zealova`
   - Sender email: `hello@zealova.com` (or whichever address has SPF/DKIM/DMARC)

   This is REQUIRED before launch — Supabase's shared sender
   `noreply@mail.app.supabase.io` lands in spam for many corporate Gmail
   tenants and is rate-limited to ~30 emails/hour.

4. **Test the round-trip**
   - Sign up with a fresh test email
   - Open inbox — confirm email arrives from `hello@zealova.com`
   - Tap "Confirm Email" — link opens app via `zealova://auth/callback?code=...`
   - `IncomingLinkService._handle()` detects callback and calls
     `Supabase.instance.client.auth.exchangeCodeForSession(code)`
   - User lands on home screen already signed in.

## Variables used in templates

These are the standard Supabase Auth Go-template variables:

- `{{ .ConfirmationURL }}` — the full link (token + redirect_to embedded)
- `{{ .Email }}` — recipient email
- `{{ .Token }}` — 6-digit OTP fallback code (for users who can't tap links)
- `{{ .SiteURL }}` — the Site URL setting from §1
- `{{ .Data.first_name }}` — only available when you pass `data: { first_name: '...' }`
  in `signUp()` from the client. Templates handle missing names gracefully.

## Web fallback page

`/Users/saichetangrandhe/AIFitnessCoach/docs/auth-emails/auth-callback.html`
deploys to `https://zealova.com/auth/callback` on the marketing site.
It serves three purposes:
1. iOS/Android with app installed → universal link auto-opens app
2. iOS/Android without app → "Open in App Store" CTA
3. Desktop → "This link is meant for mobile. Open Zealova on your phone."

## AASA (Apple App Site Association)

`/Users/saichetangrandhe/AIFitnessCoach/docs/auth-emails/apple-app-site-association.json`
deploys to `https://zealova.com/.well-known/apple-app-site-association`
(no extension, served as `application/json`). Required for universal links
on iOS — without it, taps on `https://zealova.com/auth/callback?code=...`
will open Safari instead of the app.
