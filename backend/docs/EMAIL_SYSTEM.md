# FitWiz Email System

## Overview

FitWiz sends lifecycle and transactional emails via **Resend** to drive engagement, convert trials, recover churned users, and retain paying subscribers.

```
Resend SDK
    ↑
EmailService (email_service.py)
    ↑                    ↑
Webhook handlers         Cron endpoint
(subscriptions.py)       (email_cron.py)
    ↑                    ↑
RevenueCat events        Render Cron Job (daily 6 AM UTC)
```

---

## Email Catalogue

| # | Type | Trigger | Subject | Preference Gate | Cooldown |
|---|------|---------|---------|----------------|---------|
| S1 | Purchase Confirmation | `_handle_initial_purchase` (non-trial) | "Welcome to FitWiz Premium, {name}" | Always send | — |
| S2 | Billing Issue | `_handle_billing_issue` | "Action required: Your FitWiz payment failed" | Always send | 1 day |
| S3 | Cancellation Retention | `_handle_cancellation` | "We're sorry to see you go — offer inside" | `promotional` | — |
| S4 | Trial Expired → Convert | `_handle_expiration` (is_trial=True) | "Your trial just ended — but it's not too late" | Always send | — |
| E1 | Trial Ending (3d + 1d) | Daily cron: trial_end_date in 3 or 1 days | "Your free trial ends in N days — here's what you'll lose" | `product_updates` | 2 days |
| E2 | Streak At Risk | Daily cron: no workout in 3 days, streak ≥ 2 | "{name}, your streak is about to break" | `workout_reminders` | 7 days |
| E3 | Day-3 Activation | Daily cron: created 3 days ago, 0 workouts | "{name}, your first workout is already built" | `workout_reminders` | 7 days |
| E4 | Weekly Summary | Cron: every Monday, ≥1 workout last 7 days | "Week recap: You lifted Xkg" | `weekly_summary` | 7 days |
| E5 | Onboarding Incomplete | Daily cron: created 24-48h ago, onboarding=false | "{name}, your AI coach is waiting" | `workout_reminders` | 7 days |
| S5 | Win-back (30 days) | Daily cron: expired ~30 days ago, free tier | "{name}, you're falling behind — come back with 20% off" | `promotional` | 30 days |
| S6 | 14-day Free Upsell | Daily cron: created 14 days ago, free, ≥3 workouts | "You've done 3 workouts — here's what Premium unlocks" | `product_updates` | 7 days |

---

## User Preference Controls

Each email is gated behind a preference flag from the `email_preferences` table. Users can toggle these in **Settings → Privacy & Data → Email Preferences** (implemented in `email_preferences_section.dart`).

| Flag | Controls |
|------|---------|
| `workout_reminders` | E2 Streak At Risk, E3 Day-3 Activation, E5 Onboarding Incomplete |
| `weekly_summary` | E4 Weekly Summary |
| `product_updates` | E1 Trial Ending, S6 14-day Upsell |
| `promotional` | S3 Cancellation Retention, S5 Win-back |
| Always send | S1 Purchase Confirmation, S2 Billing Issue, S4 Trial Expired |

---

## Adding a New Email

1. **Add method** to `EmailService` in `backend/services/email_service.py`:
   ```python
   async def send_my_new_email(self, to_email: str, user_name: str, ...) -> Dict[str, Any]:
       # Use OLED dark style (see send_welcome_email for template reference)
   ```
2. **Add HTML template** using table-based layout, #000000 bg, #06b6d4 accent.
3. **Add cron query** in `email_cron.py` (new `_job_*` function) OR hook into a webhook handler in `subscriptions.py`.
4. **Add dedup call**: `_was_recently_sent(supabase, uid, "my_email_type")` before sending.
5. **Log the send**: `_log_email_sent(supabase, uid, "my_email_type")` after success.
6. **Register cron job** in the `jobs = [...]` list in `run_email_cron()`.
7. **Update this doc** — add a row to the Email Catalogue table.

---

## Cron Job

**Schedule:** `0 6 * * *` (daily at 6 AM UTC)

**Render command:**
```bash
curl -s -X POST https://aifitnesscoach-zqi3.onrender.com/api/v1/emails/cron \
  -H "X-Cron-Secret: $CRON_SECRET" \
  -H "Content-Type: application/json" -d "{}"
```

**Manual trigger (local):**
```bash
curl -s -X POST http://localhost:8000/api/v1/emails/cron \
  -H "X-Cron-Secret: your_secret_here" \
  -H "Content-Type: application/json" -d "{}"
```

**Jobs run daily:** streak_at_risk, day3_activation, trial_ending, win_back_30, 14day_upsell, onboarding_incomplete

**Jobs run Mondays only:** weekly_summary

**Deduplication:** Before each send, `email_send_log` is checked for the `(user_id, email_type)` pair within the cooldown window. If found, the user is skipped. After a successful send, a row is inserted.

**Batch size:** 50 users per `asyncio.gather()` batch.

---

## Environment Variables

| Variable | Required | Description |
|---------|---------|-------------|
| `RESEND_API_KEY` | Yes | Resend API key (get from resend.com dashboard) |
| `RESEND_FROM_EMAIL` | No | From address (default: `FitWiz <onboarding@resend.dev>`) |
| `BACKEND_BASE_URL` | Yes | Public backend URL for logo + open links |
| `CRON_SECRET` | Yes | Random 32-char string for cron endpoint auth |

---

## Render Setup

1. **Add environment variables** in Render backend service dashboard:
   - `CRON_SECRET` = (random 32-char string, e.g., `openssl rand -hex 16`)
   - Ensure `RESEND_API_KEY` and `RESEND_FROM_EMAIL` are set

2. **Create a Render Cron Job** resource (separate from the web service):
   - Name: `fitwiz-email-cron`
   - Schedule: `0 6 * * *`
   - Command:
     ```
     curl -s -X POST https://aifitnesscoach-zqi3.onrender.com/api/v1/emails/cron -H "X-Cron-Secret: $CRON_SECRET" -H "Content-Type: application/json" -d "{}"
     ```
   - Add `CRON_SECRET` as an environment variable on the cron job resource (same value)

---

## Testing

### Test a single email method locally
```python
# In a Python shell with the backend running
import asyncio
from services.email_service import get_email_service

email_svc = get_email_service()
result = asyncio.run(email_svc.send_billing_issue(
    to_email="your@email.com",
    user_name="Test User",
    tier="premium",
))
print(result)
```

### Test the cron endpoint
```bash
# Should return 200 with jobs_run list
curl -v -X POST http://localhost:8000/api/v1/emails/cron \
  -H "X-Cron-Secret: your_local_secret" \
  -H "Content-Type: application/json" -d "{}"

# Should return 401
curl -v -X POST http://localhost:8000/api/v1/emails/cron \
  -H "X-Cron-Secret: wrong_secret" \
  -H "Content-Type: application/json" -d "{}"
```

### Bypass deduplication for testing
```sql
-- Delete send log for a specific user + type to allow re-send
DELETE FROM email_send_log
WHERE user_id = 'your-user-uuid' AND email_type = 'streak_at_risk';
```

### Verify in Resend dashboard
Check https://resend.com/emails for delivery status and opens.

---

## Troubleshooting

| Problem | Solution |
|---------|---------|
| Emails not sending | Check `RESEND_API_KEY` is set and valid in Render env vars |
| "Domain not verified" error | Verify your sending domain in Resend dashboard → Domains |
| Cron returns 503 | `CRON_SECRET` env var not set on backend service |
| Cron returns 401 | `CRON_SECRET` mismatch between cron job and backend service |
| Deduplication blocking test sends | Delete from `email_send_log` — see "Bypass deduplication" above |
| No users hit by cron job | Check DB query — users table may not have matching records |
| `RESEND_FROM_EMAIL` rejected | Use a verified domain address, not a random Gmail |
