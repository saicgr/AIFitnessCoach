# Zealova MCP Server — Deployment & Setup Guide

This guide walks through deploying the Zealova [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server. Once deployed, yearly subscribers connect Zealova to Claude Desktop, ChatGPT, Cursor, or any MCP-compatible AI client — the client then reads and writes their Zealova data through scoped tools.

> **New to MCP?** It's an open protocol (from Anthropic) that standardizes how AI assistants access external data and take actions. Think of it as "OpenAPI, but for AI agents." Instead of the user copy-pasting data between apps, their AI assistant speaks MCP directly to the Zealova backend — authenticated as that user, limited to scopes they granted.

## Two connection paths

| Path | Use case | User flow |
|---|---|---|
| **Personal Access Token (PAT)** — primary | Any end user connecting their own AI tools | Open app → Settings → AI Integrations → Create Connection → paste JSON into Claude/ChatGPT config. |
| **OAuth 2.1** — reserved | Future third-party marketplace listings (ChatGPT Apps, Claude Connector store) | Full DCR + PKCE flow with consent page. All wired server-side, not surfaced in the app. |

The rest of this doc is the same regardless of path — both go through the same server, enforce the same yearly-subscription gate, and write the same audit log.

## 1. Prerequisites

- Zealova backend deployed (this repo), typically on Render.
- Supabase project already provisioned.
- RevenueCat yearly subscription products configured. MCP is yearly-only.
- Ability to set env vars on the backend host.

## 2. Database Migrations

Apply both MCP migrations to Supabase:

| Migration | Creates | Purpose |
|---|---|---|
| `backend/migrations/1910_mcp_oauth.sql` | `mcp_oauth_clients`, `mcp_auth_codes`, `mcp_tokens`, `mcp_audit_log`, `mcp_confirmation_tokens` | OAuth 2.1 server (marketplace path). |
| `backend/migrations/1911_mcp_personal_tokens.sql` | `mcp_personal_tokens` | User-generated PATs (primary path). |

If you applied via the Supabase MCP tools in-session, skip this step.

## 3. Install / Update Dependencies

```bash
cd backend
pip install -r requirements.txt
```

New packages added for MCP:

- `mcp` — Anthropic's official Python SDK.
- `jinja2` — renders the consent UI.
- `weasyprint` — generates PDF reports (`generate_report` tool).
- `markdown` — backs HTML / Markdown report formats.

### WeasyPrint system dependencies

Render's native Python buildpack installs `Aptfile` packages before `build.sh` runs. The repo includes `backend/Aptfile` with the necessary WeasyPrint deps (`libpango-1.0-0`, `libpangoft2-1.0-0`, `libharfbuzz0b`, `libcairo2`, `libgdk-pixbuf-2.0-0`, `libffi-dev`, `shared-mime-info`, `fonts-liberation`, `fonts-dejavu`).

The build script includes a non-fatal WeasyPrint smoke test — if PDF rendering can't initialize, the build still succeeds but logs a warning. HTML and Markdown reports keep working; only PDF would 500 at runtime.

## 4. Environment Variables (Render)

Set in Render → Dashboard → your service → Environment. See [`MCP_ENV_VARS.md`](./MCP_ENV_VARS.md) for the full checklist.

**Required:**

| Variable | Purpose |
|---|---|
| `MCP_TOKEN_PEPPER` | Extra entropy for hashing all MCP tokens (OAuth + PATs). Generate with `openssl rand -hex 32`. Rotating invalidates ALL outstanding tokens — use for emergency mass-revoke. |
| `MCP_YEARLY_PRODUCT_IDS` | JSON-array of RevenueCat SKUs that grant MCP access. Example: `["fitwiz_yearly","fitwiz_premium_yearly"]`. |
| `MCP_OAUTH_ISSUER` | Your backend's canonical URL. Example: `https://aifitnesscoach-zqi3.onrender.com`. Also used to build the MCP URL in the PAT connection config. |
| `SUPABASE_ANON_KEY` | Public anon key from **Supabase → Project Settings → API → anon/public**. Required only for the OAuth consent page (browser-side sign-in). Skip if you only use the PAT flow. Same key your Flutter app uses — safe to expose. |

**Optional (sensible defaults in `backend/mcp/config.py`):**

| Variable | Default |
|---|---|
| `MCP_UPGRADE_URL` | `https://fitwiz.us/upgrade?reason=mcp` |
| `MCP_RATE_LIMIT_PER_MIN` | `30` |
| `MCP_RATE_LIMIT_PER_HOUR` | `500` |
| `MCP_WRITE_LIMIT_PER_HOUR` | `25` |
| `MCP_CHAT_LIMIT_PER_HOUR` | `10` |
| `MCP_GENERATE_LIMIT_PER_HOUR` | `5` |
| `MCP_ACCESS_TOKEN_TTL_SEC` | `3600` (OAuth only; PATs don't expire) |
| `MCP_REFRESH_TOKEN_TTL_SEC` | `2592000` (30d, OAuth only) |

The consent UI is served directly by the backend at `/mcp/consent/authorize`. No separate Vercel app is required — the embedded page is only reached if/when you list on a marketplace.

## 5. Verify the Endpoints

After deploy:

### a) OAuth metadata discovery

```
GET https://<your-backend>/mcp/oauth/.well-known/oauth-authorization-server
```

Should return JSON with `issuer`, `authorization_endpoint`, `token_endpoint`, `registration_endpoint`, `scopes_supported`. If this 404s, router isn't mounted — check `backend/main.py`.

### b) MCP integrations list (for the mobile app)

```
GET https://<your-backend>/api/v1/users/me/mcp-integrations
Authorization: Bearer <supabase JWT>
```

Should return `[]` for a new user with no connections. Returns 401 without a valid JWT.

### c) MCP transport mount

```
POST https://<your-backend>/mcp
```

The streamable-HTTP MCP transport lives at `/mcp`. `GET` typically returns `405` or a streaming initialization response — both confirm the mount exists. Use the MCP Inspector (see `MCP_TESTING.md`) for a real protocol handshake.

## 6. Post-deploy Smoke Checklist

- [ ] `/mcp/oauth/.well-known/oauth-authorization-server` returns 200 JSON.
- [ ] `MCP_TOKEN_PEPPER` is **not** the default placeholder `change-me-in-production`.
- [ ] Your test user has an active product in `MCP_YEARLY_PRODUCT_IDS`.
- [ ] Render env vars are marked **Secret** for the pepper.
- [ ] Deployed backend URL matches `MCP_OAUTH_ISSUER` exactly (trailing slash matters).
- [ ] Build logs show "✅ WeasyPrint PDF generation: OK" (or warning if you're not using PDF reports).

## 7. Troubleshooting

**"subscription_required" on every PAT creation, even for yearly subscribers.**
`MCP_YEARLY_PRODUCT_IDS` is checked as an exact `product_id` match against `user_subscriptions`. Confirm the user's row has `status='active'` and `product_id` matching one of the configured IDs. The check is cached 5 min — flush Redis or wait it out after changing the allowlist.

**`weasyprint` builds locally but not on Render.**
Check Render build logs for messages referencing `libgobject-2.0.so.0`, `cairo`, or `pango`. Ensure `backend/Aptfile` exists and wasn't accidentally deleted — Render only installs those packages if that file is present in the rootDir.

**PATs never revoke.**
Revocation is soft (flips `revoked_at`) — check Supabase `mcp_personal_tokens` directly. Row exists with `revoked_at` set = revoked. Row gone = cascade-deleted. The `last_used_at` field helps identify stale tokens.

**Claude Desktop says "connection failed" after pasting the config.**
Three checks:
1. The `url` in the config must be your actual backend URL. If `MCP_OAUTH_ISSUER` is set correctly, the generated config uses it automatically.
2. Render free tier cold-starts 10-30s — retry after waiting.
3. The token prefix must be `fwz_pat_`. If the user pasted a truncated value, it won't match in `verify_personal_token`.

## 8. What's Next

See [`MCP_TESTING.md`](./MCP_TESTING.md) for the end-to-end test flow. See [`MCP_ENV_VARS.md`](./MCP_ENV_VARS.md) for tabular env var reference.
