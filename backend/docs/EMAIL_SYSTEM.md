# Zealova Email System

Every outbound email in this backend — lifecycle, transactional, marketing, DSAR,
support — goes out through **one** function: `services/email_sender.py::send()`.
That module is the only place `resend.Emails.send` is called. The domain guard and
the global per-user frequency cap live there, so they cannot be forgotten at a call
site.

```
                     resend.Emails.send        ← the ONLY call, nowhere else
                            ▲
              services/email_sender.py::send(params, user_id=, email_type=)
                 ├─ 1. undeliverable-domain guard   (never disableable)
                 ├─ 2. RESEND_API_KEY check
                 ├─ 3. global frequency cap         (2/local day, 4/rolling 7d)
                 └─ 4. send
                            ▲
     ┌──────────────────────┴────────────────────────────────────┐
     │                                                           │
EmailService mixins                                     Direct callers
 email_service.py       (welcome, verification,          api/v1/dsar.py       (4 types)
                         purchase, billing, reminder)    api/v1/live_chat.py  (admin alert)
 email_lifecycle.py     (18 types)
 email_marketing.py     (weekly_summary, win_back_30, 7day_upsell)
 email_engagement.py    (idle/one-workout/premium-idle/welcome-back)
 email_cancel_ladder.py (6 cancel types)
 email_security.py / email_waitlist.py / email_lifetime.py / email_free_tools.py
     ▲                                                           ▲
     │                                                           │
api/v1/email_cron.py  — 26 jobs, HOURLY, per-user local time bands
api/v1/subscriptions/webhooks.py, users/auth.py, users/profile.py,
workouts/crud_completion.py, trophy_triggers.py, reminders.py, free_tools.py,
waitlist.py, subscriptions/lifetime_web.py, users/security.py — event-triggered
```

Ledger table: **`email_send_log`** (`user_id, email_type, metadata, sent_at,
sent_local_date, resend_email_id, status`). It is written **after** a successful
send (never before), and it is the cross-run source of truth for both the per-type
cooldown and the global cap.

---

## 1. Why the chokepoint exists — the 75%-bounce incident

**566 of 752 lifetime sends bounced. A 75% bounce rate. SES suspends senders above
~5%.**

Root cause: the backend had **46 direct `resend.Emails.send(...)` call sites across
13 files** and no chokepoint. Our own test harnesses create real `users` rows with
addresses that can never receive mail:

| Harness | Address minted |
|---|---|
| `scripts/injury_test_harness.py`, `injury_edge_probe.py`, `injury_count_probe.py` | `…@zealova.invalid` |
| `scripts/loadtest/gen_test_tokens.py` | `…@zealova-loadtest.dev` |
| `scripts/seed_qa_user.py` | `…@zealova.invalid` |
| Play Store pre-launch report devices | `…@cloudtestlabaccounts.com` |

Those rows are real users to the cron. Signup fired a real verification email; the
lifecycle jobs followed with `week1_*`, `day3_activation`, `email_verification_reminder`.
Every one bounced. Nothing in the send path knew the address was synthetic, because
there was no send path — there were 46 of them.

The fix is structural, not a per-call-site guard:

* `email_sender.is_undeliverable(address)` blocks any recipient whose domain has a
  reserved TLD (`invalid`, `test`, `local`, `localhost`, `example` — RFC 2606/6761),
  is in the static synthetic-domain list (`zealova-loadtest.dev`,
  `cloudtestlabaccounts.com`), is in env `EMAIL_SUPPRESS_DOMAINS` (comma-separated,
  read at call time so an ops change needs no redeploy), or is malformed.
* The guard runs **inside `send()`**, before the cap and before Resend. It is
  **never** disableable — the cap has a kill switch, the domain guard does not.
* Multi-recipient sends have undeliverable addresses *dropped*; only if nothing
  deliverable remains is the whole send blocked.

**Blocking is normal control flow, not an error.** A blocked send never raises. It
returns:

```python
{"id": None, "success": False, "skipped": True, "reason": R}
#  R ∈ {"undeliverable_domain", "frequency_cap", "not_configured"}
```

`success: False` is load-bearing: every cron job writes its `email_send_log` row
only `if result.get("success")`, so a blocked send writes **no** row and therefore
**does not burn its per-type cooldown** (14 days for `week1_*`, 365 days for
`one_workout_wonder`). A capped email is *deferred to the next hourly tick*, never
deleted.

Every call site that used to do `return {"success": True, "id": response.get("id")}`
now returns **`email_sender.sent_result(response)`**. Do not hand-build a success
dict — `sent_result` is what turns a skip into `success: False` instead of a phantom
`{"success": True, "id": None}`.

Complementary runtime defence (independent of the guard): `api/v1/email_webhooks.py`
consumes Resend's `email.bounced` / `email.complained` webhooks and flips
`email_preferences.deliverable = False` after 3 hard bounces (migration 2308).

---

## 2. `services/email_sender.py` — the API

```python
send(params: dict, *, user_id: str | None = None, email_type: str | None = None) -> dict
sent_result(response: dict | None) -> dict      # MANDATORY adapter at every call site
is_undeliverable(address: str) -> bool          # pre-check (used by email_verification.py)
is_exempt(email_type: str | None) -> bool
priority_tier(email_type: str | None) -> int    # 1-4
reset_state() -> None                           # called at the top of every cron run
drain_cap_blocks() -> dict[str, int]            # {email_type: blocked_count} for the cron response
```

* `params` is passed to Resend **untouched** apart from undeliverable recipients
  being removed from `to`. `tags`, `reply_to`, `cc`, a custom `from` all survive.
* The **success-path return shape is unchanged** (Resend's dict, containing `"id"`),
  so existing `response.get("id")` / `(resp or {}).get("id")` usage keeps working.
* `user_id` is the **recipient's** `users.id`. Pass `None` when the recipient is not
  the user in scope — DSAR (pre-auth, email-keyed), waitlist, free-tool leads, and
  `live_chat` (whose in-scope `user_id` is the *reporter*, while the recipient is the
  admin — billing support mail against a user's cap could suppress it).
* A **capped** type sent with no `user_id` logs a loud warning
  (`frequency cap NOT applied`) — an un-instrumented call site shows up in the logs,
  not in someone's inbox.

---

## 3. The global frequency cap

Per-email-type cooldowns already existed (`_was_recently_sent`). Nothing capped the
**total**. On local day 3, one new unverified free user in the MORNING band was
simultaneously eligible for `week1_day3_stalled`, `day3_activation`,
`onboarding_incomplete` and `email_verification_reminder` — four independent
coroutines, four independent cooldowns, zero cross-visibility. Four emails, one
morning.

### Limits

| Window | Limit | Constant |
|---|---|---|
| Per user-**local** day | **2** non-exempt emails | `MAX_LIFECYCLE_PER_LOCAL_DAY` |
| Per rolling **7 local days** | **4** non-exempt emails | `MAX_LIFECYCLE_PER_ROLLING_7D` |

Kill switch: `EMAIL_FREQUENCY_CAP_DISABLED=1` (cap only — the domain guard stays on).

### Exempt: never capped, never counted

Exempt mail always sends, and it does not consume a slot the weekly summary needs.
A purchase receipt must not cost a user their recap; a billing failure must go out
even if they already got 2 nudges today.

Explicit set (`EXEMPT_EMAIL_TYPES`): `verification`, `email_verification`,
`email_verification_reminder`, `welcome`, `password_reset`, `purchase_confirmation`,
`billing_issue`, `trial_expired`, `trial_ending`, `cancellation_retention`,
`new_device_signin`, `security_new_device`, `free_tool_result`, `live_chat`,
`support`, `support_reply`, `workout_reminder` (user-scheduled → transactional),
`roadmap_update`, `roadmap_ship`.

Prefix rules (`EXEMPT_PREFIXES`), applied after the set: `cancel*`, `waitlist_*`,
`lifetime_*`, `dsar_*`, `security*`, `live_chat*`.

An empty/None `email_type` is treated as exempt (uncappable) — so a call site that
forgets to declare its type escapes the cap. That is why the catalogue gate exists.

### Priority tiers

The cap itself is **first-come-first-served**. Priority is bought by
`api/v1/email_cron.py` running its job tiers **sequentially** — T1 finishes before T2
starts — so the scarce 2 daily slots go to the most valuable mail. `PRIORITY_TIER` in
`email_sender.py` is the single source of truth for that ordering.

| Tier | Contents |
|---|---|
| **T1 — transactional / revenue** | verification, email_verification_reminder, purchase_confirmation, billing_issue, trial_ending, trial_expired, cancel_grace, cancel_expired, cancel_offer_{7,14,60}d, cancel_sunset, cancellation_retention *(all exempt anyway — listed so a typo can't silently demote one)* |
| **T2 — high-value lifecycle** | weekly_summary, week1_day1, week1_day3_completed, week1_day3_stalled, week1_day5, week1_day7, day3_activation, onboarding_incomplete, comeback, first_workout_done |
| **T3 — re-engagement** | one_workout_wonder *(runs first in-tier: 365-day cooldown, one lifetime shot)*, streak_at_risk, idle_nudge, premium_idle, win_back_30, 7day_upsell, welcome_back_premium |
| **T4 — gamification** | merch_unlocked, level_milestone_celebration, merch_claim_reminder, merch_proximity, achievement_unlocked |

An **unregistered** `email_type` logs `🚨 unregistered email_type` at ERROR and
defaults to T3.

### How the cap is race-free

The 26 cron jobs run concurrently inside each tier (`asyncio.gather`). A naive
count-then-send would let two jobs both observe `day_count == 1` and both send.

* `_check_and_reserve()` is a **plain `def`** holding a `threading.RLock` and
  containing **zero `await`s**. A sync function has no yield point, so it cannot be
  preempted by another coroutine, and the lock excludes other threads. **Do not make
  it `async`. Do not put an `await` in it.** That single property is what makes the
  concurrent jobs safe.
* The slot is reserved at **send** time, not at gate time. This is essential: 22 of
  the 26 jobs can still bail *after* `_was_recently_sent` passes (almost always on
  the `stats.time_band != X` check, since the band is computed after the gate). A
  reservation claimed at gate time would leak on the common path — and for
  `one_workout_wonder` (365-day cooldown) a leaked claim would permanently kill the
  email.
* The in-process ledger is **seeded from `email_send_log`** (cross-run truth, one
  query, 8-day UTC prefilter bucketed into the user's local days) and incremented
  in-process (within-run truth — a row written by job A may not be visible to job
  B's PostgREST read yet). Invariant: in-process counts are always ≥ DB counts, so
  the cap can transiently **over-suppress** (safe — retried next hour) but never
  **over-send** (unsafe).
* `_check_and_reserve` **fails closed** on a DB error. Only non-exempt lifecycle mail
  ever reaches it (all revenue/transactional mail returned earlier), and a blocked
  send writes no log row → its cooldown is intact → it retries next hour. Fail-closed
  can never drop money mail.
* `_rollback(user_id)` releases the reservation if the Resend call raises.
* Most `email_send_log` rows have a NULL `sent_local_date` (only `trial_ending` and
  `7day_upsell` pass `local_date=`). `_row_local_date` prefers the column when set and
  otherwise derives the local day from the always-populated UTC `sent_at` in the
  user's zone. Never trust that column exclusively.

### Single-writer election

Two overlapping cron runs (a Render/GH-Actions retry, a second worker, a manual
curl) would each hold their own in-process ledger and each grant a full daily budget.
`_claim_cron_hour()` does an atomic PK insert into **`email_cron_runs`**
(`hour_bucket`) — the loser returns `{"skipped": "already_running"}`. A lock held
>30 min with no `finished_at` is reclaimed as stale. A broken lock table fails **open**
(a lock bug must never mute all email).

### Observability

`drain_cap_blocks()` is drained in the cron's `finally` and returned in the HTTP
response as `capped: {email_type: n}`. Each block also emits a PostHog
`lifecycle_email_capped` event (`kind`, `tier`, `window`, `used`, `limit`). **A
dropped email is a product event, not a log line** — if `capped` is consistently
non-empty for a type, that type is losing to higher tiers and its cadence needs
rethinking, not a bigger cap.

---

## 4. The cron

**Endpoint:** `POST /api/v1/emails/cron`, header `X-Cron-Secret: $CRON_SECRET`,
rate-limited `5/minute`.

**Schedule: hourly — `0 * * * *`.** Not daily. Each job self-filters per user by
`TimeBand` computed in **the user's own timezone**, so one hourly run reaches every
timezone at the right local moment without per-region cron entries.

| Band | Local hours |
|---|---|
| `MORNING` | 06–11 |
| `MIDDAY` | 11–14 |
| `AFTERNOON` | 14–18 |
| `EVENING` | 18–21 |
| `LATE` | 21–22:30 |
| `QUIET` | quiet window (default 22:30–06) — **always wins** over the clock band |

Computed by `services/email_helpers.py::time_band(user_tz)`; reached from the cron
only through `_get_user_stats` → `stats.time_band`. Invalid/missing `users.timezone`
falls back to UTC (the same `_safe_zone` fallback the cap uses, so band math and cap
math can never disagree about which local day it is).

**Run shape:**

```
_verify_cron_secret → _claim_cron_hour(hour_bucket) → email_sender.reset_state()
  → T1 (8 jobs, gather) → T2 (8) → T3 (6) → T4 (4)      # tiers SEQUENTIAL
  → finally: drain_cap_blocks() + _release_cron_hour()
→ {"jobs_run": [...], "results": {...}, "emails_sent": n, "capped": {...}, "hour": "..."}
```

**Every job's gate is `_was_recently_sent(supabase, uid, email_type, cooldown_days=…)`**,
which fuses five concerns and returns `True` = *skip*:

1. **Vacation** suppression (`in_vacation_mode`) — bypassed by `CRITICAL_EMAIL_TYPES`
   (`trial_ending`, `cancel_grace`, `cancel_expired`, `cancel_offer_{7,14,60}d`,
   `cancel_sunset`).
2. **Comeback** suppression (`in_comeback_mode`) — suppresses `streak_at_risk`,
   `idle_nudge`, `one_workout_wonder`, `win_back_30`, `premium_idle`
   (`COMEBACK_SUPPRESSED_EMAIL`).
3. **Unverified-address guard** — an unverified `users.email_verified` blocks
   everything except `cancel*` and `email_verification_reminder`. Fails open.
4. **Per-type cooldown** — `email_send_log` row for `(user_id, email_type)` within
   `cooldown_days`.
5. **Local-date dedup** — `sent_local_date` match, when the job passes `local_date=`.

The global cap is **not** here and must never be moved here: a `True` from this gate
means "skipped", and 22 of 26 jobs can still bail afterwards. `email_sender.send` is
the last point at which "we are definitely about to hit Resend" is true.

**Batch size:** 50 users per query batch (`BATCH_SIZE`).

---

## 5. Email catalogue

Preference flags live in `email_preferences` (`workout_reminders`, `weekly_summary`,
`coach_tips`, `product_updates`, `promotional` [opt-in, default FALSE],
`achievement_emails`, `merch_emails`, `deliverable`). Users toggle them in
**Settings → Privacy & Data → Email Preferences** (`email_preferences_section.dart`).

### 5a. Cron-scheduled (26 jobs → 27 email types)

`week1_day3` is one job that writes **two** types (`_completed` / `_stalled`).
All are gated by the vacation/comeback/verified/cooldown stack above.

| Job (tier) | `email_type` | Trigger / segment | Band | Cooldown | Pref gate | Cap |
|---|---|---|---|---|---|---|
| trial_ending (T1) | `trial_ending` | trial ends in 0 or 2 local days | MORNING | 1d + local-date | `product_updates` | **exempt** |
| email_verification_reminder (T1) | `email_verification_reminder` | `email_verified=false`, created 24h–5d ago | *any* | 2d | *none* | **exempt** |
| cancel_grace (T1) | `cancel_grace` | canceled 1d ago, access still active | MORNING | 30d | `coach_tips` | **exempt** |
| cancel_expired (T1) | `cancel_expired` | the day access ends | MORNING | 60d | `coach_tips` | **exempt** |
| cancel_offer_7d (T1) | `cancel_offer_7d` | 7d post-expiry, 10% off | MORNING | 7d | `promotional` | **exempt** |
| cancel_offer_14d (T1) | `cancel_offer_14d` | 14d post-expiry, 20% off | MORNING | 7d | `promotional` | **exempt** |
| cancel_offer_60d (T1) | `cancel_offer_60d` | 60d post-expiry, 30% off | MORNING | 7d | `promotional` | **exempt** |
| cancel_sunset (T1) | `cancel_sunset` | 90d post-expiry, final mail | MORNING | 3650d | `coach_tips` | **exempt** |
| **weekly_summary (T2)** | `weekly_summary` | **Monday** (user-local). Carries the cardio section — see §6 | MORNING | 7d | `weekly_summary` | capped |
| day3_activation (T2) | `day3_activation` | created ≤14d ago, **0** workouts ever, schedule LAUNCHES_TODAY/OVERDUE | MORNING | 14d | `workout_reminders` | capped |
| onboarding_incomplete (T2) | `onboarding_incomplete` | `onboarding_completed=false`, created 24–48h ago | MORNING/MIDDAY | 7d | `workout_reminders` | capped |
| week1_day1 (T2) | `week1_day1` | created ~1d ago | MORNING | 14d | `workout_reminders` | capped |
| week1_day3 (T2) | `week1_day3_completed` | created ~3d ago, ≥1 completed workout | MORNING | 14d | `workout_reminders` | capped |
| week1_day3 (T2) | `week1_day3_stalled` | created ~3d ago, 0 completed workouts | MORNING | 14d | `workout_reminders` | capped |
| week1_day5 (T2) | `week1_day5` | created ~5d ago | **EVENING** | 14d | `workout_reminders` | capped |
| week1_day7 (T2) | `week1_day7` | created ~7d ago | MORNING | 14d | `achievement_emails` | capped |
| comeback (T2) | `comeback` | logged today after a ≥7-day gap | EVENING | 30d | `coach_tips` | capped |
| one_workout_wonder (T3) | `one_workout_wonder` | exactly 1 lifetime workout, logged 6–8d ago | MORNING | **365d** | `coach_tips` | capped |
| streak_at_risk (T3) | `streak_at_risk` | active in 30d, nothing in 3d, streak ≥2 | EVENING | 7d | `workout_reminders` | capped |
| idle_nudge (T3) | `idle_nudge` | idle exactly 7 or 14 days | EVENING | 6d | `coach_tips` | capped |
| premium_idle (T3) | `premium_idle` | paying/trial, no workout in 14d | MORNING | 14d | `coach_tips` | capped |
| win_back_30 (T3) | `win_back_30` | expired to free ~30d ago, 25% off | MORNING | 30d | `promotional` | capped |
| 7day_upsell (T3) | `7day_upsell` | free tier, day 7 local, ≥3 workouts | MORNING | 7d + local-date | `product_updates` | capped |
| merch_unlocked (T4) | `merch_unlocked` | `merch_claims` pending_address, created ≤24h | *any* | 1d | `merch_emails` | capped |
| level_milestone_celebration (T4) | `level_milestone_celebration` | milestone level-up ≤24h (5/10/25/50/…/250) | *any* | 1d | `achievement_emails` | capped |
| merch_claim_reminder (T4) | `merch_claim_reminder` | claim unclaimed 2, 7 or 14 days | *any* | 3d | `merch_emails` | capped |
| merch_proximity (T4) | `merch_proximity` | level 47-49 / 97-99 / … / 247-249 | MORNING/EVENING | 7d | `merch_emails` | capped |

**Retired:** `cardio_digest` — was a standalone Sunday-morning send from
`_job_weekly_summary`. Deleted. Historical `email_send_log` rows are left alone. (The
cardio *push* in `api/v1/weekly_wrapped_cron.py` is a different channel and is
unaffected.)

### 5b. Event-triggered

| `email_type` | Fired by | Pref gate | Cap |
|---|---|---|---|
| `welcome` | `api/v1/users/profile.py` (profile created) | always | **exempt** |
| `verification` | `api/v1/auth/email_verification.py::issue_and_send_verification` — signup (`users/auth.py`) + `POST /auth/email/resend-verification` | always | **exempt** |
| `purchase_confirmation` | `subscriptions/webhooks.py::_handle_initial_purchase` (non-trial) | always | **exempt** |
| `billing_issue` | `subscriptions/webhooks.py::_handle_billing_issue` | always | **exempt** |
| `trial_expired` | `subscriptions/webhooks.py::_handle_expiration` (is_trial) | always | **exempt** |
| `cancellation_retention` | `subscriptions/webhooks.py::_handle_cancellation` | `promotional` | **exempt** |
| `first_workout_done` | `workouts/crud_completion.py` (first completed workout) | — | capped (T2) |
| `achievement_unlocked` | `api/v1/trophy_triggers.py` | `achievement_emails` | capped (T4) |
| `workout_reminder` | `api/v1/reminders.py` (user-scheduled reminder) | user-scheduled | **exempt** |
| `new_device_signin` | `api/v1/users/security.py` | always | **exempt** |
| `waitlist_confirmation` | `api/v1/waitlist.py` | — (lead, no user) | **exempt** |
| `lifetime_waitlist` | `subscriptions/lifetime_web.py` | — | **exempt** |
| `lifetime_checkout_open` | manual blast when Stripe opens — **no caller today** | — | **exempt** |
| `lifetime_purchase` | `subscriptions/lifetime_web.py` (Stripe webhook) | — | **exempt** |
| `free_tool_result` | `api/v1/free_tools.py` (user asked for it) | — (lead, no user) | **exempt** |
| `live_chat` | `api/v1/live_chat.py` → **admin** inbox (`user_id=None` — the recipient is not the reporter) | — | **exempt** |
| `dsar_verification` | `api/v1/dsar.py` | — (pre-auth, email-keyed) | **exempt** |
| `dsar_export_ready` | `api/v1/dsar.py` | — | **exempt** |
| `dsar_no_account` | `api/v1/dsar.py` | — | **exempt** |
| `dsar_deletion_queued` | `api/v1/dsar.py` | — | **exempt** |
| `welcome_back_premium` | **no caller anywhere** — the reactivation webhook its docstring describes does not exist | `coach_tips` | capped (T3) |
| `roadmap_update` / `roadmap_ship` | `scripts/notify_roadmap_voters.py` (manual, opt-in voters) | opt-in | **exempt** |

---

## 6. The merged weekly email

**Before:** `_job_weekly_summary` sent **two** recaps 24 hours apart, both behind the
single `weekly_summary` preference flag —

* Sunday MORNING: `cardio_digest`, via a **direct `resend.Emails.send`** inside the
  cron (a local `import resend as _resend`, the only direct Resend call in that file).
* Monday MORNING: `weekly_summary`, via `email_svc`.

Two recaps in 24h, one flag, and a hand-rolled send bypassing every guard.

**Now:** one email. The Monday summary carries the cardio data as a section.

* `services/cardio_digest_service.py::render_digest_section_html(summary, first_name)`
  returns an embeddable `<tr>`-rooted block (section label + metric grid + a tone-routed
  callout), built from the same `email_signature_template` builders as the rest of the
  email and **reusing the existing copy logic** (`_classify_tone`, pace/date formatters,
  variant salting). `compute_weekly_cardio_summary` and `format_digest_copy` are
  unchanged — the push path and its tests are untouched.
* `services/email_marketing.py::send_weekly_summary(...)` gained an optional
  `cardio=None` kwarg (inserted before the dead compat params, so every existing
  positional call still binds). It splices the section into `_compose_weekly_body`
  after the "Your Zealova week" grid.
* `api/v1/email_cron.py::_job_weekly_summary` computes
  `cardio = compute_weekly_cardio_summary(...)` on the Monday path (try/except →
  `None`) and passes it through. The Sunday block, its `_resend` import, its direct
  send and its `cardio_email_type` are **deleted**.

`cardio=None` (no cardio data, or a compute failure) → the section is omitted and the
email renders **byte-for-byte** as it did before. A malformed cardio summary can never
cost a user their weekly report. A time-only cardio week (0 km — boxing, HIIT) leads
with cardio *time*, not "0 km".

---

## 7. Regression gates

Run **both** after adding, renaming or removing any email:

```bash
cd backend && .venv/bin/python scripts/audit_email_chokepoint.py --check
cd backend && .venv/bin/python scripts/audit_email_catalogue.py --check
```

**`audit_email_chokepoint.py --check`** — fails if any file under `api/`, `services/`
or `scripts/` calls `resend.Emails.send` (or imports `resend` to send) outside
`services/email_sender.py`. This is the gate that keeps the 75%-bounce incident from
recurring: one new `import resend` in a webhook handler re-opens the hole. The only
legitimate `resend` references outside the chokepoint are **test/preview
monkeypatches** — `tests/test_email_*.py` and
`scripts/render_transactional_email_preview.py` patch `resend.Emails.send` on the
shared module object, which still intercepts *through* the chokepoint (the sender
resolves `resend.Emails.send` by attribute lookup at call time, deliberately, so those
patches keep working).

**`audit_email_catalogue.py --check`** — fails if any `email_type` literal reaching
`email_sender.send(...)` or `_log_email_sent(...)` is not registered in
`PRIORITY_TIER` (or covered by `EXEMPT_EMAIL_TYPES` / `EXEMPT_PREFIXES`), and if any
cron dispatcher key has no corresponding registration. An unregistered type silently
defaults to T3 and — if `email_type` is omitted entirely — silently escapes the cap.
This gate is the only thing standing between "I added an email" and "I added an
uncapped email".

CI also runs `tests/test_email_sender_cap.py`, which asserts the chokepoint's
behaviour directly: undeliverable domains are blocked with zero Resend calls, the cap
blocks the 3rd non-exempt send of a local day, exempt mail sends anyway, and the
success-path shape is unchanged.

---

## 8. Adding a new email — checklist

1. **Pick the `email_type` string.** It is the primary key of this whole system: it
   keys `email_send_log`, the per-type cooldown, the exemption rules, the cap tier and
   the telemetry. Kebab-free, lowercase, snake_case.
2. **Register it in `services/email_sender.py`:**
   * add it to `PRIORITY_TIER` with the right tier (T1 transactional/revenue → T4
     gamification). **Every type must be registered**, exempt or not, or it defaults to
     T3 with a loud error;
   * if it must always send (revenue, security, verification, user-requested,
     no-account), add it to `EXEMPT_EMAIL_TYPES` (or make it match an existing prefix).
     Be honest here — exempt means *uncapped*, and that is how inboxes get flooded.
3. **Write the send method** on the right `EmailService` mixin
   (`email_lifecycle.py`, `email_marketing.py`, `email_engagement.py`, …). It must:
   * take `*, user_id: Optional[str] = None` (keyword-only, defaulted — so it cannot
     break any existing positional caller);
   * build `params` and call
     `email_sender.send(params, user_id=user_id, email_type="my_type")`;
   * return **`email_sender.sent_result(response)`** — never a hand-built
     `{"success": True, ...}`;
   * log success only `if not response.get("skipped")` — a blocked send must not be
     laundered into a "sent" log line.
   * **Never** `import resend`.
4. **Build the HTML** with `services/email_signature_template.py` (`signature_email`,
   `section_label`, `metric_grid`, `callout`, `coach_card`, `pill_cta`). Table-based,
   no `linear-gradient`, no inline `<svg>` (Gmail strips it — icons are PNGs).
5. **Wire the trigger:**
   * **Cron:** add a `_job_*` coroutine in `api/v1/email_cron.py`; gate with
     `if _was_recently_sent(supabase, uid, email_type, cooldown_days=N): continue`;
     pick a `TimeBand`; send; then `if result.get("success"): _log_email_sent(...)`
     with `resend_email_id=result.get("id")`. **Register the job in the correct tier
     list** in `run_email_cron` — the tier is what buys it cap priority.
   * **Event:** call the mixin method from the handler, passing `user_id=` so the cap
     applies. If the recipient is not the user in scope (admin alert, lead, DSAR), pass
     `user_id=None` **and say why in a comment**.
6. **Add a preference gate** unless the mail is genuinely transactional. Reuse an
   existing flag on `email_preferences`; a new flag needs a migration *and* the Flutter
   settings surface (`email_preferences_section.dart`).
7. **Run both gates** (§7) and the email tests.
8. **Update this doc** — add the row to §5a or §5b.

**Do not** add a new email by widening the cap. Two per local day is the budget; if a
new type deserves a slot it takes it from something lower in the tier order, and the
`capped` telemetry will tell you what it displaced.

---

## 9. Environment

| Variable | Required | Purpose |
|---|---|---|
| `RESEND_API_KEY` | yes | Resend key. Unset → every send returns `{"skipped": True, "reason": "not_configured"}` (never raises). |
| `RESEND_FROM_EMAIL` | no | From address (default `Zealova <onboarding@resend.dev>`). |
| `BACKEND_BASE_URL` | yes | Logo + open-tracking links. |
| `CRON_SECRET` | yes | `X-Cron-Secret` auth for `POST /api/v1/emails/cron`. |
| `EMAIL_SUPPRESS_DOMAINS` | no | Extra undeliverable domains, comma-separated. Read at call time — no redeploy. |
| `EMAIL_FREQUENCY_CAP_DISABLED` | no | `1`/`true` disables the **cap only**. The domain guard is not disableable. |
| `RESEND_WEBHOOK_SECRET` | yes | Svix signature verification for `POST /api/v1/email-webhooks/resend`. |

---

## 10. Operating it

**Manual cron trigger**

```bash
curl -s -X POST https://aifitnesscoach-zqi3.onrender.com/api/v1/emails/cron \
  -H "X-Cron-Secret: $CRON_SECRET" -H "Content-Type: application/json" -d '{}'
```

Response: `{"jobs_run": [...], "results": {...}, "emails_sent": n, "capped": {...}, "hour": "2026-07-13T15"}`
— or `{"skipped": "already_running", "hour": ...}` if another run holds this hour's
lock. To force a re-run of the same hour, delete its `email_cron_runs` row.

**Render / Actions schedule:** the cron is invoked by
`.github/workflows/email-cron.yml`. The code is designed for **hourly** (`0 * * * *`)
— per-user time-band filtering only reaches every timezone if the endpoint is hit
every hour. A daily schedule silently starves every band except the one that happens
to align with that UTC hour.

**Preview the HTML without sending**

```bash
.venv312/bin/python scripts/render_transactional_email_preview.py   # writes proof HTML
.venv312/bin/python scripts/render_weekly_email_preview.py          # weekly + cardio section
```

**Re-send during testing** — the per-type cooldown is `email_send_log`:

```sql
DELETE FROM email_send_log WHERE user_id = '<uuid>' AND email_type = 'streak_at_risk';
```

To clear the **global cap** for a user, delete that user's non-exempt rows for the
local day (or set `EMAIL_FREQUENCY_CAP_DISABLED=1` in a local shell — never in prod).
The in-process ledger is reset at the top of every cron run and has a 600s TTL, so it
never needs manual clearing.

**Never** point a test harness or load-test at a real inbox, and never "temporarily"
allow `@zealova.invalid` through the guard. That is the exact move that produced 566
bounces.

---

## 11. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `{"skipped": true, "reason": "undeliverable_domain"}` | Working as intended: reserved TLD (`.invalid`/`.test`/`.local`/`.example`), a synthetic harness domain, an `EMAIL_SUPPRESS_DOMAINS` entry, or a malformed address. |
| `{"skipped": true, "reason": "frequency_cap"}` | The user already got 2 non-exempt emails today (or 4 this week). Deferred, not dropped — it retries next hour, and the cooldown was not burned. Check the `capped` map in the cron response to see what is losing. |
| `{"skipped": true, "reason": "not_configured"}` | `RESEND_API_KEY` unset in that environment. |
| `🚨 unregistered email_type` in logs | A type reached `send()` that is not in `PRIORITY_TIER`. Register it (§8.2) and run `audit_email_catalogue.py --check`. |
| `frequency cap NOT applied` warning | A **capped** type was sent with no `user_id`. Thread the recipient's `users.id` through to the mixin. |
| Cron returns `{"skipped": "already_running"}` | Another process holds this hour's `email_cron_runs` lock (or a crashed run holds it — it self-reclaims after 30 min). |
| Emails stop for one user entirely | Check, in order: `email_preferences.deliverable` (flipped false after 3 hard bounces), `users.email_verified`, `in_vacation_mode`, `in_comeback_mode`, then the cap. |
| Cron returns 401 / 503 | `CRON_SECRET` mismatch / not set on the backend service. |
| Only one timezone gets mail | The cron is not running hourly. Time-band filtering assumes `0 * * * *`. |

---

**Version:** 2.0 · **Last updated:** 2026-07-13 · rewritten after the chokepoint +
frequency-cap + weekly-merge refactor.
