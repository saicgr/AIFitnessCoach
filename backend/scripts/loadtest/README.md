# Zealova load-test harness

Reproduces the 2026-05-16 app-launch incident as a repeatable benchmark:
each virtual user fires the ~50-endpoint home-screen launch fan-out, then
polls `/workouts/today`. It is the **before/after yardstick** for every
phase of the scale-hardening plan (`ultrathink-on-all-use-...` plan file).

## Files

| File | Purpose |
|------|---------|
| `launch_burst.js` | k6 script — the launch-burst simulation |
| `gen_test_tokens.py` | mints a pool of test JWTs into `tokens.json` |
| `tokens.json` | generated — `[{user_id, token}]` pool (git-ignored) |
| `results/` | generated — JSON summaries per run |

## One-time setup

1. Install k6: `brew install k6` (macOS) — https://k6.io/docs/get-started/installation/
2. The token generator and k6 are independent — k6 is a standalone binary.

## Running a benchmark

```bash
cd backend

# 1. Mint a fresh token pool (tokens expire ~1h — always do this first).
.venv/bin/python scripts/loadtest/gen_test_tokens.py --count 200

# 2. Sanity check (20 VUs, ~1 min).
cd scripts/loadtest
k6 run -e STAGE=smoke launch_burst.js

# 3. Capture the BASELINE before any fix ships.
k6 run -e STAGE=10k -e SUMMARY=results/baseline-10k.json launch_burst.js
```

After each plan phase, re-run the same stage and compare:

```bash
k6 run -e STAGE=10k -e SUMMARY=results/phase2-10k.json launch_burst.js
```

## Options

| Env | Default | Notes |
|-----|---------|-------|
| `STAGE` | `smoke` | `smoke` \| `1k` \| `5k` \| `10k` |
| `BASE_URL` | `https://aifitnesscoach-zqi3.onrender.com` | point at staging if you have one |
| `TOKENS` | `tokens.json` | path to the token pool |
| `SUMMARY` | — | write a machine-readable JSON summary |

## What "passing" means

The k6 thresholds encode the plan's final 10K target on a single Standard
instance:

- `connection_timeouts` **< 1** — the incident signal must be gone
- `launch_burst_ok` **> 99%** — fan-out returns all-200
- `workouts_today_latency` **p95 < 800 ms**
- `http_req_failed` **< 1%**

The **baseline run is expected to FAIL these** — that is the point. Each
phase should move the numbers toward green.

## Cautions

- `5k`/`10k` against the production URL is itself a heavy load test.
  Prefer a staging deploy, or coordinate a low-traffic window.
- The harness only sends the same requests the app sends on launch; it
  does not mutate data beyond the app's own launch-time POSTs.
- Test users are namespaced `loadtest+NNNN@zealova-loadtest.dev`. Remove
  them with: `.venv/bin/python scripts/loadtest/gen_test_tokens.py --cleanup`
- Re-mint tokens before every run: `gen_test_tokens.py --refresh-only`.
  Stale (expired) tokens show up as a sub-99% `launch_burst_ok` with 401s.
```
