# Phase-2 Food-Scan — Operations Runbook

Operational reference for the Phase-2 food-scan latency cut (60s → 2-3s).
Covers kill switches, env vars, monitoring, rollback procedures, and the
cross-user promotion job.

**Last reviewed:** 2026-05-15
**Owner:** ChetanG
**Related plan:** `~/.claude/plans/what-is-the-plan-enumerated-teacup.md`

---

## Kill switches (ordered by blast-radius)

### 1. Vision-pipeline kill switch — **`PHASE2_VISION_PIPELINE`**

**What it controls:** Whether `/analyze-image-stream` uses the new Phase-2
Stage-1 + cache-stack path or reverts to the legacy heavyweight
`vision_service.analyze_food_image()` (the pre-Phase-2 30-60s flow).

**Where to set:** Render dashboard → `fitwiz-backend` service → Environment.
Add a key `PHASE2_VISION_PIPELINE` with value `0` to disable Phase 2.

**Default behavior:** When unset (or any value other than `"0"`), Phase 2 is
ENABLED. Code at `backend/api/v1/nutrition/food_logging_stream.py` reads:

```python
use_phase2 = os.environ.get("PHASE2_VISION_PIPELINE", "1") != "0"
```

**When to use:**
- Phase-2 cache lookup throws unexpected errors in production
- Stage-1 Vision returns malformed responses for >5% of scans
- DB load spikes when many users hit `analyze_dishes_from_vision` simultaneously
- Any user-visible regression in scan accuracy

**Rollback procedure:**
1. Render dashboard → fitwiz-backend → Environment → Add `PHASE2_VISION_PIPELINE=0`
2. Save → triggers automatic rolling restart (~60s)
3. Verify revert: `curl <api>/api/v1/nutrition/analyze-image-stream` test scan; check
   logs for `Stage-1` references — should be ABSENT in legacy path
4. To re-enable: delete the env var (or set to `1`) → restart

**Does NOT need to be set in Render normally** — leave unset for default Phase-2 ON.

---

### 2. Promotion-job dry-run — **`PROMOTION_DRY_RUN`**

**What it controls:** The daily cron job (`backend/scripts/promote_user_contributed.py`)
that promotes convergent user-contributed dishes to canonical.

**Where to set:** Per-invocation env, OR `fitwiz-promote-user-contributed`
cron service in Render. Set `PROMOTION_DRY_RUN=1` to log what would be
promoted without writing to DB.

**Default behavior:** Unset → writes happen normally (cron mode). The cron
service in `render.yaml` does NOT set this var, so promotion is live.

**When to use:**
- After major changes to the promotion criteria — verify the right rows would be
  picked before letting them ship to production canonical
- After loosening `PROMOTION_MIN_USERS` or `PROMOTION_MAX_CV` — sanity check
- Anytime you want to peek at "what's about to get promoted today" without
  side effects

**Manual run with dry-run:**
```bash
cd /Users/saichetangrandhe/AIFitnessCoach
PROMOTION_DRY_RUN=1 backend/.venv/bin/python -m backend.scripts.promote_user_contributed
```

The script logs the top 30 candidate dishes with user-count + mean kcal +
std-dev, then exits without DB writes.

---

### 3. Promotion-job tuning knobs

**`PROMOTION_MIN_USERS`** (default `5`) — minimum distinct users required
before a dish is eligible for promotion. Set lower (e.g. `3`) to be more
aggressive about populating canonical from user data; higher (`10`) to be
more conservative.

**`PROMOTION_MAX_CV`** (default `0.20`) — max coefficient of variation on
calories across users for a dish to be eligible. Lower = stricter (only
super-converged dishes). Higher = more lenient.

These can be tuned per-cron-run via Render dashboard env vars on the
`fitwiz-promote-user-contributed` service.

---

### 4. SQL backout for accidentally-promoted data

**Scenario:** A bug in the promotion job (or a coordinated brigading attack
where many users log the same wrong macros) lands bad data in
`food_nutrition_overrides` with `nutrient_source='auto_promoted'`.

**Backout — restores the previous Gemini-estimated values:**
```sql
-- Reverts ALL auto-promoted rows back to gemini_estimate source
UPDATE food_nutrition_overrides
SET nutrient_source = 'gemini_estimate',
    auto_promoted_at = NULL
WHERE auto_promoted_at IS NOT NULL;
```

**Targeted backout — single dish:**
```sql
UPDATE food_nutrition_overrides
SET nutrient_source = 'gemini_estimate',
    auto_promoted_at = NULL
WHERE food_name_normalized = 'suspicious_dish_name'
  AND auto_promoted_at IS NOT NULL;
```

**After backout:** the canonical view automatically reflects the change
(it's a live view, not a materialized view — see mig 2071). Hot caches
(per-worker `RedisCache`) take up to 24h to expire on `_canonical_cache`;
flush by triggering a Render rolling restart of `fitwiz-backend` (changes
any env var to force restart).

---

## Per-user opt-out endpoints

User-facing controls (Settings → Privacy & Data):

| Endpoint | What it does |
|---|---|
| `PATCH /api/v1/users/me/contribute-food-data` | Toggle whether NEW novel-dish writes go into `food_overrides_user_contributed` for this user. Existing rows untouched. |
| `DELETE /api/v1/users/me/contributed-foods` | Permanently delete all of THIS user's rows from `food_overrides_user_contributed`. Their existing food_log rows stay intact. |

When a user opts out via PATCH:
- Their existing user_contributed rows still serve their own future lookups
- New novel dishes don't write to user_contributed
- Cross-user promotion job skips their data (via `WHERE` filter on `users.contribute_food_data = TRUE`)

When a user clicks Delete:
- All their user_contributed rows are removed
- They'll pay full Gemini cost on every novel dish until they re-opt-in

---

## Required env vars summary

| Var | Required by | Default | Purpose |
|---|---|---|---|
| `DATABASE_URL` | backend, promotion cron | (set) | Supabase pooler URL |
| `GEMINI_API_KEY` | backend | (set) | Gemini API key |
| `GEMINI_MODEL` | backend | `gemini-3-flash-preview` | Default Gemini model |
| `PHASE2_VISION_PIPELINE` | backend | `1` (Phase-2 ON) | Set to `0` to disable Phase 2 vision pipeline |
| `PROMOTION_MIN_USERS` | promotion cron | `5` | Min users for cross-user promotion |
| `PROMOTION_MAX_CV` | promotion cron | `0.20` | Max calorie CV for promotion |
| `PROMOTION_DRY_RUN` | promotion cron | `0` (write mode) | Set to `1` for dry-run |
| `REDIS_URL` | backend (optional) | (unset → in-memory fallback) | Shared cache for hot tiers |

**Render-side:** only `DATABASE_URL` and `GEMINI_API_KEY` are required for the
promotion cron. Knobs (`PROMOTION_*`) and kill switch (`PHASE2_VISION_PIPELINE`)
should be UNSET unless you specifically want to override defaults.

---

## Health check / monitoring

### Live progress queries

**Are users self-warming the cache?**
```sql
SELECT COUNT(*) AS rows,
       COUNT(DISTINCT user_id) AS users,
       MAX(last_logged_at) AS most_recent
FROM food_overrides_user_contributed;
```

**Is the promotion job working?**
```sql
SELECT COUNT(*) AS auto_promoted_dishes,
       MAX(auto_promoted_at) AS last_promotion
FROM food_nutrition_overrides
WHERE nutrient_source = 'auto_promoted';
```

**What's the menu_scan_cache hit rate?**
```sql
SELECT restaurant_name,
       SUM(scan_count) AS total_scans,
       COUNT(DISTINCT menu_hash) AS unique_menus
FROM menu_scan_cache
GROUP BY restaurant_name
ORDER BY total_scans DESC LIMIT 20;
```

**Latency check — is `/analyze-image-stream` actually fast?**
Look for `[ANALYZE-STREAM:req_*] Stage-1 done:` log lines on Render. The
follow-up SSE `done` event timestamp minus the START log line gives end-to-
end latency. Phase-2 target: < 4s for cached dishes, < 8s for novel.

---

## Re-enable / tweak procedures

### Tighten promotion criteria mid-flight
1. Render → `fitwiz-promote-user-contributed` → Env: add `PROMOTION_MIN_USERS=10`
2. Save (no restart needed for cron — applies on next 03:00 UTC run)
3. Manually trigger via Render dashboard "Trigger Job" if you want it now

### Bust hot cache
The 3-tier `RedisCache` (canonical 24h, user_contributed 1h, menu 1h)
auto-flushes on TTL. Force-flush by triggering a `fitwiz-backend` rolling
restart (any env-var change). For Redis-backed mode, can also delete keys
matching prefix `zealova:food_canonical_v1:*`.

### Verify a single user's contributed-food state
```sql
SELECT food_name_normalized, log_count, user_edited, promoted_to_canonical,
       last_logged_at
FROM food_overrides_user_contributed
WHERE user_id = '<uuid>'
ORDER BY last_logged_at DESC;
```
