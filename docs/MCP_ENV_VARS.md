# FitWiz MCP Server — Environment Variable Checklist

Quick-reference for the env vars the MCP server reads. All live under the `MCP_` prefix and are parsed by `backend/mcp/config.py::MCPConfig` (Pydantic BaseSettings).

Set these in **Render → your service → Environment**. Mark secrets as "Secret" so they aren't shown in the dashboard.

## Required

| Variable | Example / Default | Required? | How to generate / choose |
|---|---|---|---|
| `MCP_TOKEN_PEPPER` | `b7f3…c42a` (64 hex chars) | **Yes** | `openssl rand -hex 32`. **Never** leave as `change-me-in-production`. Rotating this value invalidates every outstanding MCP access & refresh token (use as an emergency mass-revoke). |
| `MCP_YEARLY_PRODUCT_IDS` | `["premium_yearly","premium_yearly:yearly-base"]` | **Yes** | JSON array of RevenueCat product IDs that grant MCP access. Must exactly match the `product_id` stored in your `user_subscriptions` table. Pydantic parses env values that look like JSON arrays automatically. |
| `MCP_OAUTH_ISSUER` | `https://aifitnesscoach-zqi3.onrender.com` | **Yes** | The canonical public URL of your backend. Published in the OAuth metadata doc (`/mcp/oauth/.well-known/oauth-authorization-server`) and used to build consent / redirect URLs. No trailing slash. |
| `SUPABASE_ANON_KEY` | `eyJhbGciOi…` (long JWT-shaped string) | **Yes** for the OAuth path (not needed for PAT-only) | Public anon key from **Supabase Dashboard → Project Settings → API → anon/public**. Safe to expose to browsers — it's the same key your Flutter app uses. The MCP consent page uses this to sign users in via email/password and Google/Apple OAuth. If unset, the consent page shows a manual paste-token fallback (legacy). |

## Optional (sensible defaults in code)

| Variable | Default | Description |
|---|---|---|
| `MCP_UPGRADE_URL` | `https://fitwiz.us/upgrade?reason=mcp` | Where the consent page sends non-yearly users who hit the paywall. |
| `MCP_CONSENT_URL` | `https://aifitnesscoach-zqi3.onrender.com/mcp/consent/authorize` | The consent screen URL. Defaults to the embedded backend UI. Change this if you later move consent to `fitwiz.us` on Vercel. |
| `MCP_RATE_LIMIT_PER_MIN` | `30` | Per-user-per-client MCP request cap per minute. |
| `MCP_RATE_LIMIT_PER_HOUR` | `500` | Per-user-per-client MCP request cap per hour. |
| `MCP_WRITE_LIMIT_PER_HOUR` | `25` | Tighter cap for write-capable tools. |
| `MCP_CHAT_LIMIT_PER_HOUR` | `10` | Cap for `chat_with_coach` (expensive — Gemini + LangGraph). |
| `MCP_GENERATE_LIMIT_PER_HOUR` | `5` | Cap for `generate_workout_plan` (very expensive). |
| `MCP_ACCESS_TOKEN_TTL_SEC` | `3600` (1h) | OAuth access token lifetime. |
| `MCP_REFRESH_TOKEN_TTL_SEC` | `2592000` (30d) | OAuth refresh token lifetime. Rotates on each use. |
| `MCP_AUTH_CODE_TTL_SEC` | `60` | OAuth authorization code lifetime. Keep short — RFC recommends ≤ 60s. |
| `MCP_CONFIRMATION_TOKEN_TTL_SEC` | `300` (5m) | For destructive actions that require a confirm round-trip. |
| `MCP_SUBSCRIPTION_CACHE_TTL_SEC` | `300` (5m) | Redis cache for the "is yearly subscriber" check. Lower = faster revocation propagation; higher = fewer DB reads. |
| `MCP_ANOMALY_LOG_MEAL_PER_5MIN` | `50` | Hard tripwire: client auto-disabled if it logs more than this many meals in 5 min. |
| `MCP_ANOMALY_ANY_TOOL_PER_MIN` | `200` | Hard tripwire: client auto-disabled if it makes more than this many total calls in 1 min. |
| `MCP_ANOMALY_SIGMA_THRESHOLD` | `3.0` | Sigma threshold for the daily anomaly-detection cron (soft flag, not auto-disable). |

## Values You Typically Don't Override

These live in `MCPConfig` but rarely need env overrides:

- `SCOPES` — master scope catalog. Change in code, not env.
- `DEFAULT_SCOPES` — what's granted when a client doesn't request specific scopes.
- `CONFIRMATION_REQUIRED_TOOLS` — destructive tool allowlist.

## Example `.env.mcp` Fragment (for local dev)

```
MCP_TOKEN_PEPPER=replace_with_openssl_rand_hex_32
MCP_YEARLY_PRODUCT_IDS=["premium_yearly","premium_yearly:yearly-base"]
MCP_OAUTH_ISSUER=http://localhost:8000
MCP_CONSENT_URL=http://localhost:8000/mcp/consent/authorize
MCP_UPGRADE_URL=https://fitwiz.us/upgrade?reason=mcp

# Public anon key (for browser-side Supabase Auth on the consent page).
# Same value your Flutter app already uses for client-side Supabase calls.
SUPABASE_ANON_KEY=eyJhbGciOi…
```

## One-time Supabase Dashboard Setup (for OAuth path)

If you want users to sign in via Google or Apple on the consent page:

1. **Supabase Dashboard → Authentication → URL Configuration → Redirect URLs** — add your consent page URL so the OAuth provider can redirect back:
   - `https://aifitnesscoach-zqi3.onrender.com/mcp/consent/authorize`
   - `http://localhost:8000/mcp/consent/authorize` (for local dev)
2. **Authentication → Providers** — enable Google and/or Apple. Follow Supabase's setup steps for each. If you've already enabled them for the Flutter app, no extra work is needed.

If you only want email/password sign-in, skip both steps — `signInWithPassword` works without any dashboard config.

## Verification

After setting env vars, restart the backend, then:

```bash
curl https://<backend>/mcp/oauth/.well-known/oauth-authorization-server | jq .
```

The response should include your `MCP_OAUTH_ISSUER` value as the `issuer` field and have all the `scopes_supported` you expect.

For consent UI verification:

```bash
open https://<backend>/mcp/consent/authorize?consent=invalid
```

You should see the branded FitWiz consent page with an "invalid / expired" error — that confirms the page renders, static CSS loads, and the `peek` endpoint is reachable.

## Related Docs

- [`MCP_SETUP.md`](./MCP_SETUP.md) — full deployment walkthrough.
- [`MCP_TESTING.md`](./MCP_TESTING.md) — end-to-end test procedure.
