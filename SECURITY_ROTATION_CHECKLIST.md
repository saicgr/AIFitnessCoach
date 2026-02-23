# Security Credential Rotation Checklist

All credentials listed below were previously hardcoded in source files and must be rotated immediately. After rotation, update the corresponding environment variables in Render and any other deployment targets.

---

## Exposed Credentials

| # | Variable | Exposure Location | Where to Rotate |
|---|----------|------------------|-----------------|
| 1 | `DATABASE_PASSWORD` / `SUPABASE_DB_PASSWORD` | 57 files in `backend/scripts/*.py` | Supabase Dashboard > Settings > Database |
| 2 | `SUPABASE_KEY` (service_role) | `backend/scripts/test_nutrition_calculation.py`, `add_sample_features.py`, `test_daily_crate_fix.py`, `.claude/settings.local.json` | Supabase Dashboard > Settings > API |
| 3 | `SUPPORT_PASSWORD` | `backend/setup_support_user.py` | Set new value in Render env vars |
| 4 | `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` | Backend env / config | AWS IAM Console |
| 5 | `GEMINI_API_KEY` | Backend env / config | Google AI Studio |
| 6 | `OPENAI_API_KEY` | Backend env / config | OpenAI Dashboard |
| 7 | `CHROMA_CLOUD_API_KEY` | Backend env / config | Chroma Dashboard |
| 8 | `RESEND_API_KEY` | Backend env / config | Resend Dashboard |
| 9 | `REVENUECAT_WEBHOOK_SECRET` | Backend env / config | RevenueCat Dashboard |
| 10 | `GCP_OAUTH_CLIENT_SECRET` | Backend env / config | Google Cloud Console |

---

## Step-by-Step Rotation Instructions

### 1. `DATABASE_PASSWORD` / `SUPABASE_DB_PASSWORD`

1. Go to **Supabase Dashboard** > **Settings** > **Database**
2. Click **Reset database password**
3. Copy the new password
4. Update env vars: `DATABASE_PASSWORD`, `SUPABASE_DB_PASSWORD`, and `DATABASE_URL` (which contains the password inline)

### 2. `SUPABASE_KEY` (service_role)

1. Go to **Supabase Dashboard** > **Settings** > **API**
2. Under **Project API keys**, regenerate the **service_role** key
3. Copy the new key
4. Update env var: `SUPABASE_KEY`

> Note: The `anon` key was also exposed in `.claude/settings.local.json`. Consider regenerating it as well from the same page.

### 3. `SUPPORT_PASSWORD`

1. Choose a new strong password (min 16 chars, mixed case, numbers, symbols)
2. Update the `SUPPORT_PASSWORD` env var in Render
3. After deployment, use the new password to log in as the support user and verify access

### 4. `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`

1. Go to **AWS IAM Console** > **Users** > select the relevant user
2. Go to **Security credentials** tab
3. Under **Access keys**, create a new access key
4. Update env vars: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
5. Deactivate and then delete the old access key after verifying the new one works

### 5. `GEMINI_API_KEY`

1. Go to **Google AI Studio** (https://aistudio.google.com/)
2. Navigate to **API keys**
3. Create a new API key (or regenerate existing)
4. Update env var: `GEMINI_API_KEY`
5. Delete/revoke the old key

### 6. `OPENAI_API_KEY`

1. Go to **OpenAI Dashboard** (https://platform.openai.com/)
2. Navigate to **API keys**
3. Create a new secret key
4. Update env var: `OPENAI_API_KEY`
5. Revoke the old key

### 7. `CHROMA_CLOUD_API_KEY`

1. Go to **Chroma Dashboard**
2. Navigate to API key management
3. Generate a new API key
4. Update env var: `CHROMA_CLOUD_API_KEY`
5. Revoke the old key

### 8. `RESEND_API_KEY`

1. Go to **Resend Dashboard** (https://resend.com/api-keys)
2. Create a new API key
3. Update env var: `RESEND_API_KEY`
4. Delete the old key

### 9. `REVENUECAT_WEBHOOK_SECRET`

1. Go to **RevenueCat Dashboard** > **Project Settings** > **Webhooks**
2. Generate a new webhook authorization header / secret
3. Update env var: `REVENUECAT_WEBHOOK_SECRET`

### 10. `GCP_OAUTH_CLIENT_SECRET`

1. Go to **Google Cloud Console** > **APIs & Services** > **Credentials**
2. Select the OAuth 2.0 Client ID
3. Reset the client secret
4. Update env var: `GCP_OAUTH_CLIENT_SECRET`

---

## Render Environment Variable Update Checklist

After rotating each credential, update the corresponding env var in Render:

- [ ] `DATABASE_PASSWORD` - new Supabase DB password
- [ ] `SUPABASE_DB_PASSWORD` - same new Supabase DB password
- [ ] `DATABASE_URL` - full connection string with new password
- [ ] `SUPABASE_KEY` - new service_role JWT
- [ ] `SUPPORT_PASSWORD` - new support admin password
- [ ] `AWS_ACCESS_KEY_ID` - new AWS access key
- [ ] `AWS_SECRET_ACCESS_KEY` - new AWS secret key
- [ ] `GEMINI_API_KEY` - new Gemini API key
- [ ] `OPENAI_API_KEY` - new OpenAI API key
- [ ] `CHROMA_CLOUD_API_KEY` - new Chroma API key
- [ ] `RESEND_API_KEY` - new Resend API key
- [ ] `REVENUECAT_WEBHOOK_SECRET` - new RevenueCat webhook secret
- [ ] `GCP_OAUTH_CLIENT_SECRET` - new GCP OAuth client secret

---

## Post-Rotation Verification Steps

After updating all credentials in Render, verify each service is working:

- [ ] **Backend starts successfully** - Check Render deploy logs for startup without errors
- [ ] **Database connectivity** - Hit any authenticated endpoint and confirm DB queries work
- [ ] **Supabase Auth** - Log in via the mobile app and confirm JWT validation succeeds
- [ ] **Gemini AI** - Send a chat message or generate a workout to confirm Gemini responds
- [ ] **OpenAI** - Trigger any feature that uses OpenAI and confirm it works
- [ ] **ChromaDB** - Test exercise search / RAG features
- [ ] **AWS S3** - Upload or retrieve a progress photo
- [ ] **Resend email** - Trigger an email notification (e.g., password reset)
- [ ] **RevenueCat webhooks** - Verify subscription events are still received
- [ ] **Support user login** - Log in with the new support password
- [ ] **Run migration scripts** - Verify scripts work with `DATABASE_PASSWORD` env var set

---

## Render Configuration Changes Required After Security Fixes

These are **code-driven changes** that require matching Render env var updates:

### Must Set / Change
| Variable | Required Value | Why |
|----------|---------------|-----|
| `DEBUG` | `false` | Was defaulting to `true`; disables Swagger docs in prod, tightens CORS, reduces log verbosity |
| `CORS_ORIGINS` | `["https://fitwiz-zqi3.onrender.com"]` | Remove localhost origins in production (only include production domains) |

### Must Verify Already Set
| Variable | Notes |
|----------|-------|
| `RENDER` | Auto-set by Render to `true`. Used by rate limiter to trust `X-Forwarded-For` from Render proxy only |
| `SUPABASE_URL` | Ensure set (no default in code after cleanup) |
| `GEMINI_MODEL` | Ensure set if using non-default model |
| `AWS_DEFAULT_REGION` | Required for S3 photo uploads |
| `S3_BUCKET_NAME` | Required for S3 photo uploads |
| `CHROMA_CLOUD_HOST` | Required for RAG features |
| `CHROMA_TENANT` | Required for RAG features |
| `CHROMA_DATABASE` | Required for RAG features |

### New Env Vars Required by Security Fixes
| Variable | Purpose | What Happens If Missing |
|----------|---------|------------------------|
| `DATABASE_PASSWORD` | Used by migration scripts (no more hardcoded fallback) | Scripts exit with error instead of using hardcoded password |
| `SUPPORT_PASSWORD` | Used by `setup_support_user.py` (no more hardcoded fallback) | Script exits with error |

### Complete Required Env Vars for Production
```
# Core
SUPABASE_URL=<your-supabase-url>
SUPABASE_KEY=<rotated-service-role-key>
DATABASE_URL=<full-connection-string-with-rotated-password>
DATABASE_PASSWORD=<rotated-password>
GEMINI_API_KEY=<rotated-key>

# Storage
AWS_ACCESS_KEY_ID=<rotated-key>
AWS_SECRET_ACCESS_KEY=<rotated-secret>
AWS_DEFAULT_REGION=<your-region>
S3_BUCKET_NAME=<your-bucket>

# RAG
CHROMA_CLOUD_HOST=<host>
CHROMA_CLOUD_API_KEY=<rotated-key>
CHROMA_TENANT=<tenant>
CHROMA_DATABASE=<database>

# Payments
REVCAT_API_KEY=<key>
REVENUECAT_WEBHOOK_SECRET=<rotated-secret>

# Auth
GCP_OAUTH_CLIENT_ID=<client-id>
GCP_OAUTH_CLIENT_SECRET=<rotated-secret>

# Config (NEW/CHANGED)
DEBUG=false
CORS_ORIGINS=["https://fitwiz-zqi3.onrender.com"]

# Optional
REDIS_URL=<if-using-redis>
SLACK_SUPPORT_WEBHOOK=<if-using-slack-alerts>
USDA_API_KEY=<if-registered-for-production-key>
SUPPORT_PASSWORD=<new-strong-password>
OPENAI_API_KEY=<rotated-key>
RESEND_API_KEY=<rotated-key>
```

### What Changes on Deploy (automatic from code changes)
1. **Swagger/ReDoc disabled** — `/docs` and `/redoc` return 404 in production (`DEBUG=false`)
2. **Rate limiting enforced** — 34 additional Gemini-calling endpoints now have 5-10/min limits
3. **Auth required on all endpoints** — Requests without `Authorization: Bearer <token>` header get 401
4. **Webhook verification strict** — RevenueCat webhooks without valid `Authorization` header get 401
5. **Error messages sanitized** — 500 errors return generic "An internal error occurred" instead of stack traces
6. **python-multipart updated** — CVE-2024-24762 patched

### Post-Deploy Smoke Test Checklist
- [ ] Backend starts without errors in Render logs
- [ ] `GET /health` returns 200 (no auth needed)
- [ ] `GET /docs` returns 404 (Swagger disabled)
- [ ] Login via mobile app works (auth flow intact)
- [ ] Generate a workout (Gemini + auth working)
- [ ] Send a chat message (LangGraph + auth working)
- [ ] Log a meal via text (nutrition + rate limit working)
- [ ] Upload a progress photo (S3 + auth working)
- [ ] Check subscription status (RevenueCat + auth working)
- [ ] Rapid-fire 10+ requests to `/nutrition/log-image` — should get 429 after 10

---

## Important Notes

- Rotate credentials **in the order listed** to minimize downtime (database first, then dependent services)
- Keep the old credentials active in Render until the new ones are verified
- After successful verification, **revoke/delete all old credentials** from their respective dashboards
- Consider adding git-secrets or a pre-commit hook to prevent future credential leaks
- The `.claude/settings.local.json` file had 10 permission entries removed that contained embedded secrets
