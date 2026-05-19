# Zealova Load-Test Harness

This directory holds k6 load-test harnesses for the Zealova backend.

| Harness | Script | Token minter | What it does |
|---------|--------|--------------|--------------|
| **Home hot path (Phase C)** | `home_flow.js` | `mint_test_tokens.py` | Staged ramp **100 → 1k → 5k → 10k** at `GET /api/v1/home/bootstrap` + the Home follow-up call. Finds the saturation point. **This runbook.** |
| Launch burst (pre-existing) | `launch_burst.js` | `gen_test_tokens.py` | Reproduces the 2026-05-16 app-launch fan-out incident as a before/after yardstick. See the "Launch-burst harness" section at the bottom. |

---

# Home Hot-Path Load Test — Runbook (Phase C)

A k6 load-test harness for the Zealova **Home screen hot path**. It drives a
staged ramp of virtual users — **100 → 1k → 5k → 10k** — at the
`GET /api/v1/home/bootstrap` endpoint (plus one realistic follow-up call) so the
team can measure the **~10k-concurrent saturation point** and feed the numbers
into Phase D tuning (workers, DB pool size, Redis sizing).

> ## ⚠️ STAGING ONLY — READ THIS FIRST
>
> **Never run this against production.** A 10k-VU ramp will saturate the
> Supabase connection pool and Render CPU.
>
> * `home_flow.js` **requires** an explicit `BASE_URL` — there is no default.
> * It **refuses to run** if `BASE_URL` looks like a prod host
>   (`fitwiz-backend.onrender.com`, `api.zealova.com`, `zealova.com`).
> * Point it at the **staging** Render service and your **staging** Supabase
>   project. If staging and prod share a Supabase project, run off-peak and
>   clean up disposable users immediately afterward.

---

## Files used by this harness

| File | Purpose |
|------|---------|
| `home_flow.js` | The k6 script — staged ramp, thresholds, checks. |
| `mint_test_tokens.py` | Creates N **disposable** test users + JWTs into `tokens.txt`. |
| `tokens.txt` | Generated token pool (gitignored — holds live JWTs). |
| `loadtest-summary.json` | Generated results artifact (gitignored). |

---

## 1. Install k6

k6 is a single static binary (it is **not** a Node package — the `.js` script is
run by k6's own Go-embedded JS runtime).

```bash
# macOS
brew install k6

# Debian / Ubuntu
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6

# Verify
k6 version
```

---

## 2. Mint a batch of test-user JWTs

The Home endpoint is authenticated — `core/auth.py:get_current_user` validates a
Supabase-signed JWT **and** requires a matching `public.users` row. The harness
therefore needs real, signed-in test users, not fabricated tokens.

`mint_test_tokens.py` does this end-to-end using the **service-role** key from
`backend/.env` (`SUPABASE_URL` / `SUPABASE_KEY`):

1. Creates an `auth.users` row per user via the Supabase admin API.
2. Creates a linked `public.users` row (so `get_current_user`'s join succeeds).
3. Signs each user in to obtain a real access-token (JWT).
4. Writes `<jwt>\t<public_users_id>` lines to `tokens.txt`.

Every account is **clearly labelled disposable**: email
`loadtest+<n>-<runid>@zealova-loadtest.invalid`, `preferences.loadtest_disposable = true`.

```bash
cd backend
# Mint ~200 disposable users. >=200 keeps the cache-hit / cold-path mix realistic
# at 10k VUs (too few users => everything is a Redis hit and you under-measure).
.venv/bin/python scripts/loadtest/mint_test_tokens.py --count 200 --yes
```

This writes `backend/scripts/loadtest/tokens.txt` (gitignored).

**Supabase JWTs expire after ~1 hour.** A full ramp runs ~25–30 min, which fits
in one token lifetime — but if you re-run later, re-mint fresh JWTs for the same
users (no new accounts created):

```bash
.venv/bin/python scripts/loadtest/mint_test_tokens.py --refresh --yes
```

### Alternative: bring your own tokens

If you already have staging JWTs, skip the minter and create `tokens.txt`
yourself — one token per line, optionally `<jwt>\t<user_id>` (if the user_id is
omitted the script decodes it from the JWT `sub` claim). Lines starting with `#`
are ignored. Or pass them inline: `-e TOKENS="$(cat my_tokens.txt)"`.

### Cleanup (do this right after the test)

```bash
.venv/bin/python scripts/loadtest/mint_test_tokens.py --cleanup --yes
```

Deletes **every** `auth.users` + `public.users` row whose email ends with
`@zealova-loadtest.invalid`, and removes `tokens.txt`. Idempotent.

---

## 3. Run the ramp

```bash
cd backend/scripts/loadtest

# Smoke test first — 20 VUs for ~2 min — to confirm wiring before the big run:
k6 run -e SMOKE=1 -e BASE_URL=https://fitwiz-backend-staging.onrender.com home_flow.js

# Full staged ramp: 100 -> 1k -> 5k -> 10k with holds, then ramp-down (~29 min):
k6 run \
  -e BASE_URL=https://fitwiz-backend-staging.onrender.com \
  home_flow.js
```

Tunable env flags (all optional): `TOKENS_FILE` (default `tokens.txt`),
`THINK_MIN` / `THINK_MAX` (per-request think time, seconds), `TOKENS` (inline
pool), `SMOKE=1` (short profile).

Results: a human summary prints to stdout, and a machine-readable
`loadtest-summary.json` is written next to the script.

### Generating from one box vs distributed

A single machine running 10k VUs needs real headroom — bump file-descriptor
limits (`ulimit -n 1048576`) and expect a few CPU cores fully busy on the
**load generator**. If the generator itself saturates, your numbers measure the
generator, not the backend. If one box can't sustain 10k cleanly, split the run
across 2–3 machines (each running the ramp scaled to ~4k VUs) or use k6 Cloud /
a distributed k6-operator setup. A saturated generator shows up as
`http_req_blocked` / `http_req_connecting` climbing while server-side CPU is
still moderate.

---

## 4. What to watch alongside the run

Run these on a second screen **while the ramp is in progress**. The saturation
point is wherever one of these resources tops out — that, not the k6 number
alone, is the real ceiling.

### Supabase — Postgres connection pool (the usual first bottleneck)

```sql
-- Total active connections. Watch this climb each ramp stage.
SELECT count(*) FROM pg_stat_activity;

-- Broken down by state — 'active' vs 'idle in transaction' matters most.
SELECT state, count(*) FROM pg_stat_activity GROUP BY state ORDER BY 2 DESC;

-- How close to the ceiling:
SHOW max_connections;
```

The bootstrap endpoint fans out to 5 parallel synchronous DB queries through a
`ThreadPoolExecutor(max_workers=10)`, across 2 Gunicorn workers. If
`count(*)` flat-lines near `max_connections` (or the pooler's limit) while p95
latency spikes, **the DB pool is the saturation point** — Phase D should add a
PgBouncer/Supavisor transaction-pool tier or raise the pool ceiling.

### Render — service CPU / RAM

Render dashboard → `fitwiz-backend(-staging)` → **Metrics**. The prod plan is
Standard (1 CPU / 2 GB, 2 Gunicorn workers — see `render.yaml`). Watch:

* **CPU** pinned at ~100% → compute-bound; Phase D scales workers/instances.
* **RAM** climbing toward 2 GB → risk of OOM-restart under load.
* **Instance restart / health-check failures** → hard ceiling reached.

### Redis — cache hit rate

The bootstrap response is Redis-cached (30-min TTL). Higher hit rate ⇒ less DB
load ⇒ higher achievable RPS.

```bash
redis-cli -u "$REDIS_URL" INFO stats | grep -E 'keyspace_(hits|misses)'
redis-cli -u "$REDIS_URL" INFO clients | grep connected_clients
# hit rate = keyspace_hits / (keyspace_hits + keyspace_misses)
```

The k6 summary also reports `home_bootstrap_cache_hits` / `..._cache_misses` —
a coarse latency-band proxy (sub-80ms ≈ hit). Treat Redis `INFO` as
authoritative; treat the k6 counters as a directional cross-check.

---

## 5. Interpreting the results

The k6 summary reports per-endpoint metrics (bootstrap is tagged
`endpoint:bootstrap`, isolated from the `endpoint:today` follow-up).

| Metric | What it means | Phase D action |
|--------|---------------|----------------|
| `home_bootstrap_latency` p95 | Server response time for the hot path. **Pass line: p95 < 800ms.** | If p95 degrades sharply at a ramp stage, that stage's VU count is near saturation. |
| `home_bootstrap_latency` p99 | Tail latency — the slow 1%. Pass line: p99 < 2s. | A p99 that diverges from p95 = contention bursts (GC, pool waits). |
| `home_bootstrap_error_rate` | Functional errors (non-200 or wrong body shape). **Pass line: < 1%.** | Non-zero before CPU/DB max out = a code/config bug, not a capacity limit. |
| `http_req_failed{endpoint:bootstrap}` | Transport-level + 5xx failures. **Pass line: < 2%.** | A spike here = the server is shedding load (saturated). |
| `checks` rate | Fraction of assertions passing. Pass line: > 98%. | Drop = correctness breaking under load (truncated/empty bodies). |
| `http_reqs` rate (RPS) | Throughput. | The **saturation RPS** is the throughput at the last ramp stage where p95/errors still pass. |

### Finding the saturation point

1. Walk the ramp stages 100 → 1k → 5k → 10k.
2. The **saturation point** is the highest VU level where p95 < 800ms **and**
   error rate < 1% **and** `http_req_failed` < 2% all still hold.
3. Record the **RPS at that stage** — that is the Home path's safe sustained
   throughput. Above it, latency climbs and/or the server starts shedding.
4. Cross-reference with §4: whichever resource (DB connections, Render CPU,
   Redis) topped out *at that same moment* is the **binding constraint**.

The script also has a built-in guard: if bootstrap p95 stays above **3s** for
a sustained minute, k6 aborts the run early (`abortOnFail`) — the backend is
clearly saturated and there's no value in pushing further.

### Feeding Phase D

| If the binding constraint is… | Phase D should tune… |
|-------------------------------|----------------------|
| Postgres connections at ceiling | Add Supavisor/PgBouncer transaction pooling; rebalance `ThreadPoolExecutor` vs pool sizing; consider read replicas. |
| Render CPU pinned at 100% | Scale horizontally (more instances) or up; add Gunicorn workers per the new instance size. |
| Redis hit rate low / cold path dominates | Tune the 30-min bootstrap TTL, pre-warm on login, or widen `max_size`. |
| Errors before any resource maxes out | Not a capacity problem — fix the bug surfaced by the failing checks. |

Capture the stdout summary and `loadtest-summary.json` from each run and attach
them to the Phase D tuning ticket so the before/after comparison is concrete.

---

# Launch-burst harness (pre-existing)

`launch_burst.js` + `gen_test_tokens.py` are a separate, earlier harness that
reproduces the 2026-05-16 app-launch fan-out incident. It is unrelated to the
Phase C Home hot-path test above and is left intact.

```bash
cd backend
.venv/bin/python scripts/loadtest/gen_test_tokens.py --count 200
cd scripts/loadtest
k6 run -e STAGE=10k -e SUMMARY=results/phase2-10k.json launch_burst.js
```

`STAGE` = `smoke` | `1k` | `5k` | `10k`. Note that `launch_burst.js` defaults
`BASE_URL` to a production URL — always pass `-e BASE_URL=<staging>` explicitly.
