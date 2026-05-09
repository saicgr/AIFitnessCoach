# `/api/v1/workouts/quick-regenerate` — 1,000 Validation Scenarios

**Endpoint:** `POST https://aifitnesscoach-zqi3.onrender.com/api/v1/workouts/quick-regenerate`
**Backend:** `backend/api/v1/workouts/program.py:213`
**Body:** `QuickRegenerateRequest` — `{ user_id, reason? }` (only 2 fields)
**Surface:** "Quick reset" / "Regenerate program" button — clears the user's future incomplete workouts so the frontend can re-stream them via `/generate-stream`.

## What this endpoint actually does

Reading the code in `backend/api/v1/workouts/program.py:213-307`:

1. Validates user exists (404 otherwise).
2. Resolves `today` in user's local timezone.
3. Lists ALL of the user's workouts (`limit=1000`).
4. Filters: `scheduled_date >= today` AND (`is_completed=false` OR `status="generating"`).
5. Bulk-deletes those workouts AND their `workout_changes` rows.
6. Inserts a `user_activity` row of type `program_quick_reset` with the `reason`.
7. Returns `{ success, message, workouts_deleted, workouts_generated=0 }`.

**No AI is invoked.** No algorithm. Pure SQL deletes + activity log. Latency target: **300–500ms per call** on Render Pro.

## Why 100 calls is meaningful

Because the endpoint is purely state-mutating (deletes future workouts), call #2 onwards has nothing to delete unless future workouts are re-seeded between calls. So scenarios MUST vary the pre-call state and verify the response reflects that state correctly.

## Test user context

| Field | Value |
|---|---|
| `user_id` | `14c61bb0-3047-45b8-be8d-28246b587fb1` (hatlesscowboy90@gmail.com) |
| Active gym profile | `3ed17504-113a-4be4-88d0-67b4c70ca57c` (81 items, Thu/Sat/Sun) |

## Variable axes (per-call state + body)

| Axis | Variation |
|---|---|
| **Pre-call: number of future workouts** | 0, 1, 3, 5, 7, 14, 21, 30 |
| **Pre-call: workout statuses** | mix of (incomplete-only), (with `status="generating"` placeholders), (with already-completed today rows that must NOT be deleted), (with cancelled rows) |
| **Pre-call: dates of seeded workouts** | mix of preferred (Thu/Sat/Sun) and non-preferred days; near-future, far-future, span across month boundaries |
| **Pre-call: timezone** | seed workouts whose `scheduled_date` lands in different days depending on timezone — verify `today` is resolved in user's tz |
| **Pre-call: `workout_changes` rows** | with and without changes attached (FK delete-cascade verification) |
| **Body `reason`** | empty / 50+ varied analytics strings (see Block 5) |
| **Body `user_id`** | valid (most), wrong (one), nonexistent (one) |
| **Concurrency** | one call duplicated within 1 second (race) |

## Pre-call seeding

For most scenarios we directly INSERT minimal workout rows into Supabase via the `service_role` client (NOT via `/generate-stream`) — this is the fastest way to set up state and avoids the 30s Gemini gen per row. The harness inserts dummies with: `id` (uuid), `user_id`, `scheduled_date`, `name="QA seed"`, `is_completed=false`, `is_current=true`, `status="planned"`, `gym_profile_id`, `exercises=[]`. Cleanup happens naturally via the very call under test.

## Scenario distribution (100 calls)

### Block 1 — Volume of deletable workouts (calls 1–25)
Vary how many future incomplete workouts exist before the call. Verify `workouts_deleted` matches the seed count.

| # | seeded count | seeded distribution | reason | expected `workouts_deleted` |
|---|---|---|---|---|
| 1 | 0 | — | "no future workouts" | 0 |
| 2 | 1 | tomorrow only | "single workout" | 1 |
| 3 | 3 | next Thu/Sat/Sun | "3-workout week" | 3 |
| 4 | 5 | next 5 preferred days | "5-workout span" | 5 |
| 5 | 7 | next 7 preferred days | "week of preferred" | 7 |
| 6 | 7 | mix of 5 preferred + 2 non-preferred | "mixed week" | 7 |
| 7 | 14 | next 14 preferred days | "two-week span" | 14 |
| 8 | 21 | next 21 preferred days | "three-week span" | 21 |
| 9 | 30 | next 30 calendar days, all preferred | "month-long preferred" | 30 |
| 10 | 30 | next 30 calendar days, mixed | "month-long mixed" | 30 |
| 11 | 5 | all in next 7 days (cluster) | "this week cluster" | 5 |
| 12 | 5 | spread across next 60 days | "spread far" | 5 |
| 13 | 10 | all on same day (next Thu) | "same-day cluster" | 10 |
| 14 | 1 | far future +60d | "far-future single" | 1 |
| 15 | 1 | tomorrow but already past in user TZ | "edge: today vs tomorrow tz" | 0 or 1 (depends on tz resolution — verify) |
| 16 | 7 | with workout_changes rows attached | "FK cascade test" | 7 (verify changes also gone) |
| 17 | 3 | with `status="generating"` (placeholder) | "delete generating placeholders" | 3 |
| 18 | 5 | mixed: 3 planned + 2 generating | "mixed status" | 5 |
| 19 | 5 | 3 future-incomplete + 2 already-completed today | "must NOT delete completed" | 3 |
| 20 | 5 | 3 future-incomplete + 2 past-incomplete | "past must NOT be deleted" | 3 |
| 21 | 5 | 3 future-incomplete + 2 status="cancelled" | "cancelled future" | depends on filter (review code: cancelled IS_NOT excluded → all 5 deleted) |
| 22 | 5 | 5 future-incomplete + 1 today already-completed | "today completed survives" | 5 |
| 23 | 100 | 100 future-incomplete (limit boundary) | "limit boundary" | 100 (or capped at limit=1000 default) |
| 24 | 0 | only past completed workouts | "no future at all" | 0 |
| 25 | 5 | 5 future-incomplete with NULL gym_profile_id | "null profile" | 5 |

### Block 2 — Timezone & date resolution (calls 26–40)
The handler resolves `today` via `user_today_date(http_request, db, request.user_id)`. We test that boundary.

| # | user TZ override (if mockable, else infer from device) | seeded workouts | reason | notes |
|---|---|---|---|---|
| 26 | America/Chicago (default for user) | 1 workout at 23:59 UTC on date X | "tz boundary 1" | depending on tz, X may be "today" or "tomorrow" |
| 27 | America/New_York | 1 workout at 04:00 UTC on date X | "tz boundary 2" | |
| 28 | Asia/Tokyo | 1 workout at 18:00 UTC | "tz Tokyo" | early-day delete |
| 29 | Pacific/Auckland | 1 workout at 23:30 UTC | "tz Auckland" | late delete |
| 30 | UTC | 1 workout at midnight | "tz UTC midnight" | |
| 31 | America/Chicago | workout dated yesterday in user-TZ | "yesterday should not delete" | |
| 32 | America/Chicago | workout dated today in user-TZ, completed | "today completed survives" | |
| 33 | America/Chicago | workout dated today in user-TZ, incomplete | "today incomplete deletes" | |
| 34 | America/Chicago | workout dated tomorrow in user-TZ | "tomorrow deletes" | |
| 35 | America/Chicago | workout date is `null` | "null scheduled_date" | should be skipped |
| 36 | America/Chicago | workout `scheduled_date` is a TIMESTAMPTZ object | "timestamp object handling" | code branches `hasattr(.,'isoformat')` |
| 37 | America/Chicago | workout `scheduled_date` is a date object | "date object handling" | code branches `hasattr(.,'strftime')` |
| 38 | America/Chicago | workout `scheduled_date` is ISO string | "string handling" | most common |
| 39 | America/Chicago | DST transition spring-forward day | "DST spring fwd" | |
| 40 | America/Chicago | DST transition fall-back day | "DST fall back" | |

### Block 3 — Body validation & errors (calls 41–55)

| # | body | expected |
|---|---|---|
| 41 | `{user_id: <valid>}` (no reason) | 200, deletes work |
| 42 | `{user_id: <valid>, reason: ""}` (empty reason) | 200, reason logged as empty |
| 43 | `{user_id: <valid>, reason: "user clicked button"}` | 200 |
| 44 | `{user_id: <valid>, reason: <500 chars>}` | 200, full reason logged |
| 45 | `{user_id: <valid>, reason: <2000 chars>}` | 200 (or model max-length cap) |
| 46 | `{user_id: <valid>, reason: <unicode emoji>}` | 200 |
| 47 | `{user_id: "00000000-0000-0000-0000-000000000000"}` (nonexistent) | 404 user not found |
| 48 | `{user_id: "not-a-uuid"}` | 422 or 404 |
| 49 | `{user_id: <valid>, extra_field: "x"}` | 200 (Pydantic extra=ignore) |
| 50 | `{}` (empty body) | 422 |
| 51 | `{reason: "x"}` (missing user_id) | 422 |
| 52 | `{user_id: null}` | 422 |
| 53 | malformed JSON | 422 |
| 54 | wrong content-type (text/plain) | 422 |
| 55 | very large body (1MB string in reason) | 413 or 422 |

### Block 4 — Auth & rate limiting (calls 56–65)

| # | auth header | expected |
|---|---|---|
| 56 | valid Bearer JWT | 200 |
| 57 | missing Authorization | 401 |
| 58 | wrong-format header | 401 |
| 59 | expired JWT | 401 |
| 60 | JWT for different user, body user_id=valid | 200 (server doesn't IDOR-check on this endpoint? — verify) or 403 if check exists |
| 61 | malformed JWT | 401 |
| 62 | rapid 5 calls within 1s (rate-limit probe) | depends on limit decorator |
| 63 | `Authorization: Bearer ` (empty after Bearer) | 401 |
| 64 | service-role token (admin) | 200 |
| 65 | anon-key token | 401 |

### Block 5 — Reason analytics variety (calls 66–85)
The `reason` field is logged to `user_activity`. Vary it widely to verify storage + retrieval.

| # | reason |
|---|---|
| 66 | `quick_reset_button` (default per code comment) |
| 67 | `user_dissatisfied_with_workouts` |
| 68 | `goal_changed_strength_to_hypertrophy` |
| 69 | `equipment_changed` |
| 70 | `injury_flagged_knee` |
| 71 | `coming_back_from_break` |
| 72 | `program_too_easy` |
| 73 | `program_too_hard` |
| 74 | `wrong_focus_areas` |
| 75 | `manual_quick_regen` |
| 76 | `auto_regen_after_settings_change` |
| 77 | `crash_recovery_stale_placeholders` |
| 78 | `tester:harness_run` |
| 79 | `multi line\nreason\nwith\nnewlines` |
| 80 | `reason with "quotes" and 'apostrophes'` |
| 81 | `reason\twith\ttabs` |
| 82 | `<script>alert(1)</script>` (XSS probe — must store as-is, not execute) |
| 83 | `'; DROP TABLE workouts;--` (SQLi probe — must store safely) |
| 84 | `null` (literal string null) |
| 85 | `🏋️💪🔥` (emoji-only) |

### Block 6 — Concurrency & idempotency (calls 86–95)

| # | scenario |
|---|---|
| 86 | Two calls within 100ms (back-to-back) — only first deletes; second returns 0 |
| 87 | Five calls within 1s (concurrency stress) |
| 88 | Call → re-seed 5 workouts → call again → must delete 5 |
| 89 | Call → re-seed 0 → call → must return 0 (idempotent on empty state) |
| 90 | Call during active `/generate-stream` (race) — placeholders should still get cleaned |
| 91 | Call with seeded workouts that have `status="generating"` AND were created <1s ago — must still delete |
| 92 | Call → verify `user_activity` row inserted exactly once |
| 93 | Call when `user_activity` table is missing/insert fails — must NOT fail the operation (graceful degradation per code) |
| 94 | Call when `workout_changes` delete fails for one row — must NOT fail the whole operation (per code) |
| 95 | Call when single `delete_workout` fails — count should reflect successful deletes only |

### Block 7 — Composite & post-state verification (calls 96–100)

| # | scenario |
|---|---|
| 96 | Seed 30 workouts spanning 4 weeks (mix preferred + non-preferred + completed) → call → verify only future-incomplete are gone, completed/past survive, gym_profile unchanged |
| 97 | Seed workouts then change user's gym profile → call → verify the workout count for the new profile is unchanged (only user-level filter, not profile-scoped) |
| 98 | Seed workouts with weight_unit="lbs" + weight_unit="kg" mixed → call → all deleted (no unit filter applies) |
| 99 | Maximum-stress: seed 100 workouts then call → measure latency (acceptable < 5s) |
| 100 | After all prior 99 calls, call once more with seeded count=0 → confirms no leftover state from earlier scenarios |

### Block 8 — Multiple gym profiles (calls 101–115)
The user can have multiple gym profiles (active + inactive). Quick-regen filters by `user_id` only — verify it does NOT scope to active profile.

| # | profiles state | seeded workouts | expected |
|---|---|---|---|
| 101 | 1 active profile (default) | 5 future on active profile | 5 deleted |
| 102 | 2 profiles (1 active, 1 inactive) | 3 on active, 2 on inactive | 5 deleted (both profiles) |
| 103 | 3 profiles (1 active, 2 inactive) | 2 on each = 6 total | 6 deleted |
| 104 | 1 active + 1 with `is_active=false` | 5 on inactive only | 5 deleted (inactive workouts still cleaned) |
| 105 | 0 profiles (user has no gym profile) | 5 with `gym_profile_id=null` | 5 deleted |
| 106 | switch active profile mid-call: seed → flip active flag → call | 5 workouts | 5 deleted |
| 107 | profile soft-deleted (deleted_at not null) | 5 workouts on soft-deleted profile | 5 deleted (profile state irrelevant) |
| 108 | duplicate active profiles (data integrity bug) | 3 + 3 | 6 deleted |
| 109 | profile with non-default workout_days [Mon,Wed,Fri] | 3 workouts on those days | 3 deleted (filter is by date not by day-of-week) |
| 110 | profile with empty equipment | 3 workouts | 3 deleted |
| 111 | profile with custom_program_description set | 3 workouts | 3 deleted |
| 112 | profile referenced by workouts but missing from gym_profiles table | 3 workouts | 3 deleted (FK orphan tolerated) |
| 113 | freshly-created profile (<1s old) with seeded workouts | 3 workouts | 3 deleted |
| 114 | profile with name="" | 3 workouts | 3 deleted |
| 115 | profile owned by different user (FK leak test) | 3 workouts on user under test, 3 on other user | only the 3 for our user deleted |

### Block 9 — Workout state edge cases (calls 116–130)
Various flags + statuses.

| # | seeded count | flags / status | expected |
|---|---|---|---|
| 116 | 5 | `is_completed=false`, `status="planned"` | 5 deleted |
| 117 | 5 | `is_completed=false`, `status="generating"` | 5 deleted (placeholders) |
| 118 | 5 | `is_completed=false`, `status="in_progress"` | 5 deleted (mid-workout, edge — verify) |
| 119 | 5 | `is_completed=false`, `status="paused"` | 5 deleted |
| 120 | 5 | `is_completed=true`, `status="completed"` | 0 deleted (completed survives) |
| 121 | 5 | `is_completed=false`, `status="cancelled"` | 5 deleted (cancelled future still cleared) |
| 122 | 5 | `is_completed=false`, `status="error"` | 5 deleted |
| 123 | 5 | `is_completed=false`, `status=null` | 5 deleted |
| 124 | 10 | mix of all 7 statuses above | only non-completed deleted |
| 125 | 5 | with attached `workout_logs` (logged sets) but `is_completed=false` | 5 deleted (logs orphaned — verify FK) |
| 126 | 5 | with `notes` field populated | 5 deleted |
| 127 | 5 | with `exercises` field empty array | 5 deleted |
| 128 | 5 | with `exercises` containing 100 items | 5 deleted |
| 129 | 5 | with `is_current=false` (historical) | 5 deleted (no `is_current` filter in code) |
| 130 | 5 | `is_current=true` mix with `is_current=false` | 10 deleted |

### Block 10 — Calendar / date edge cases (calls 131–145)

| # | seeded date(s) | scenario | expected |
|---|---|---|---|
| 131 | 2026-12-31, 2027-01-01 | year boundary | both deleted |
| 132 | 2028-02-29 (leap day) | leap year Feb 29 | deleted |
| 133 | 2026-05-08 (today) at 00:00:00 vs 23:59:59 | same-day boundary | both deleted |
| 134 | scheduled_date = today + 1 minute | tomorrow but only minutes away | depends on tz day-rollover |
| 135 | scheduled_date 100 years in the future | far-future | deleted |
| 136 | scheduled_date 100 years in the past | very stale (past) | NOT deleted |
| 137 | scheduled_date one second past today end-of-day | next day | deleted |
| 138 | seeded 7 workouts spanning a Sun→Mon week boundary | week boundary | all 7 deleted |
| 139 | seeded across month boundary (Apr 30 + May 1) | month boundary | both deleted |
| 140 | seeded across DST spring-forward | DST forward | all deleted |
| 141 | seeded across DST fall-back | DST backward | all deleted |
| 142 | scheduled_date in non-ISO format (DD/MM/YYYY) | malformed date | edge — verify |
| 143 | scheduled_date with timezone suffix (`+05:30`) | non-UTC offset | deleted normalized |
| 144 | scheduled_date with microseconds | precision | deleted |
| 145 | 365 workouts seeded across full year | year-long sweep | 365 deleted (or capped at limit) |

### Block 11 — Database constraint / data quality (calls 146–160)

| # | seeded data quirk | expected |
|---|---|---|
| 146 | workout `name` = 1000-char string | deletes regardless of name length |
| 147 | workout `name` contains emoji | deletes |
| 148 | workout `name` contains SQL keywords (`'; DROP TABLE`) | deletes safely |
| 149 | workout `notes` = 10KB JSON | deletes |
| 150 | workout `exercises` = malformed JSON (corrupt row) | deletes (no parsing required) |
| 151 | workout with NULL user_id (corrupt) | NOT deleted (filter requires user_id match) |
| 152 | workout with `id` collision attempt | unique constraint enforced upstream |
| 153 | workout where `created_at` is in the future | deletes (filter is on scheduled_date) |
| 154 | workout with NULL `scheduled_date` | NOT deleted (filter skips null) |
| 155 | workout `gym_profile_id` referencing nonexistent profile | deletes (FK orphan tolerated) |
| 156 | workout `gym_profile_id=NULL` | deletes |
| 157 | workout with `is_deleted=true` (soft-delete) if column exists | NOT deleted (assuming list_workouts excludes soft-deleted) — verify code |
| 158 | workout with `parent_workout_id` (regenerated child) | deletes (chain truncation) |
| 159 | workout with `version` field >1 (multi-version) | deletes |
| 160 | workout with `ai_generated=false` (manually-created) | deletes (no ai_generated filter) |

### Block 12 — Workout_changes FK cascade (calls 161–170)

| # | seeded workout_changes attached | expected |
|---|---|---|
| 161 | 1 change per workout × 5 workouts | 5 changes also deleted |
| 162 | 5 changes per workout × 5 workouts | 25 changes deleted |
| 163 | 0 changes (workouts have no children) | 5 workouts deleted, no changes touched |
| 164 | mix: some workouts have changes, some don't | only changed ones get child deletes |
| 165 | orphan workout_changes (parent already gone) | 0 affected by call (only deletes children of current parents) |
| 166 | workout_changes pointing to past completed workout | NOT deleted (parent survives) |
| 167 | very old workout_change row (>1 year) | deleted with parent |
| 168 | workout_change with NULL workout_id | not affected |
| 169 | circular workout_change reference (self-pointing) | deleted with parent |
| 170 | 100 changes per workout (max) | all 100 deleted |

### Block 13 — Scale / performance (calls 171–180)

| # | scale | expected |
|---|---|---|
| 171 | seed 1000 workouts | latency budget — should still complete <10s |
| 172 | seed 100 workouts (typical) | should complete <2s |
| 173 | seed 50 workouts | <1s |
| 174 | seed 10 workouts | <500ms |
| 175 | seed 1 workout | <300ms |
| 176 | seed 0 workouts | <200ms (no-op) |
| 177 | seed 1000 workouts each with 5 changes (5000 child rows) | latency stress |
| 178 | concurrent: 5 quick-regen calls in parallel | rate-limit + lock contention |
| 179 | concurrent: 1 quick-regen + 1 generate-stream | no race deadlock |
| 180 | concurrent: 1 quick-regen + 1 regenerate-stream | no preview row interference |

### Block 14 — User profile state (calls 181–190)

| # | user state | expected |
|---|---|---|
| 181 | premium user | 200 |
| 182 | free user | 200 (no premium gate on quick-regen) |
| 183 | trial user | 200 |
| 184 | user with `deleted_at` set (soft-deleted) | 404 or graceful — verify |
| 185 | user with no preferences row | 200 (preferences not required) |
| 186 | user with no gym profiles at all | 200 (workouts may have null gym_profile_id) |
| 187 | user with `timezone=null` | 200 (defaults via resolve_timezone) |
| 188 | user with `timezone="Etc/UTC"` | 200 |
| 189 | user with `timezone="Invalid/Zone"` | 200 (fallback) |
| 190 | user just signed up (<1 minute old) | 200 |

### Block 15 — Activity log + side-effect verification (calls 191–200)

| # | scenario | verification |
|---|---|---|
| 191 | seed 5 + call → query `user_activity` | 1 row inserted with `activity_type='program_quick_reset'` |
| 192 | seed 5 + call → query `workout_logs` (sets logged) | 0 rows touched |
| 193 | seed 5 + call → query `food_logs` | 0 rows touched |
| 194 | seed 5 + call → query `users` | row unchanged |
| 195 | seed 5 + call → query `gym_profiles` | rows unchanged |
| 196 | seed 5 + call → query `chat_threads` | unchanged |
| 197 | seed 5 + call → query `body_analyzer_snapshots` | unchanged |
| 198 | call → check `activity_data.workouts_deleted` field | matches response |
| 199 | call → check `activity_data.reason` field | matches request body |
| 200 | call with no `reason` → check `activity_data.reason` defaults to "quick_reset_button" |


### Block 16 — Rotational sweep (calls 201–1000)

Cartesian sweep across volume × seeded-status × reason. Each row is one scenario.

- **Volumes (10):** 1, 2, 3, 5, 7, 10, 14, 21, 30, 50
- **Status keys (8):** scheduled, generating, mixed_sg, partial_completed, no_profile, with_changes, scheduled_far, scheduled_today
- **Reasons (10):** rotational sweep; boring routine; fresh start; schedule change; new program; rest week followup; back from vacation; fixing fatigue; challenge mode; deload reset
- **10 × 8 × 10 = 800 scenarios.**

| # | seeded count | seeded status | reason | expected deleted |
|---|---|---|---|---|
| 201 | 1 | scheduled | "rotational sweep" | 1 |
| 202 | 1 | scheduled | "boring routine" | 1 |
| 203 | 1 | scheduled | "fresh start" | 1 |
| 204 | 1 | scheduled | "schedule change" | 1 |
| 205 | 1 | scheduled | "new program" | 1 |
| 206 | 1 | scheduled | "rest week followup" | 1 |
| 207 | 1 | scheduled | "back from vacation" | 1 |
| 208 | 1 | scheduled | "fixing fatigue" | 1 |
| 209 | 1 | scheduled | "challenge mode" | 1 |
| 210 | 1 | scheduled | "deload reset" | 1 |
| 211 | 1 | generating placeholder | "rotational sweep" | 1 |
| 212 | 1 | generating placeholder | "boring routine" | 1 |
| 213 | 1 | generating placeholder | "fresh start" | 1 |
| 214 | 1 | generating placeholder | "schedule change" | 1 |
| 215 | 1 | generating placeholder | "new program" | 1 |
| 216 | 1 | generating placeholder | "rest week followup" | 1 |
| 217 | 1 | generating placeholder | "back from vacation" | 1 |
| 218 | 1 | generating placeholder | "fixing fatigue" | 1 |
| 219 | 1 | generating placeholder | "challenge mode" | 1 |
| 220 | 1 | generating placeholder | "deload reset" | 1 |
| 221 | 1 | mixed scheduled+generating | "rotational sweep" | 1 |
| 222 | 1 | mixed scheduled+generating | "boring routine" | 1 |
| 223 | 1 | mixed scheduled+generating | "fresh start" | 1 |
| 224 | 1 | mixed scheduled+generating | "schedule change" | 1 |
| 225 | 1 | mixed scheduled+generating | "new program" | 1 |
| 226 | 1 | mixed scheduled+generating | "rest week followup" | 1 |
| 227 | 1 | mixed scheduled+generating | "back from vacation" | 1 |
| 228 | 1 | mixed scheduled+generating | "fixing fatigue" | 1 |
| 229 | 1 | mixed scheduled+generating | "challenge mode" | 1 |
| 230 | 1 | mixed scheduled+generating | "deload reset" | 1 |
| 231 | 1 | mixed incomplete+today-completed | "rotational sweep" | 1 |
| 232 | 1 | mixed incomplete+today-completed | "boring routine" | 1 |
| 233 | 1 | mixed incomplete+today-completed | "fresh start" | 1 |
| 234 | 1 | mixed incomplete+today-completed | "schedule change" | 1 |
| 235 | 1 | mixed incomplete+today-completed | "new program" | 1 |
| 236 | 1 | mixed incomplete+today-completed | "rest week followup" | 1 |
| 237 | 1 | mixed incomplete+today-completed | "back from vacation" | 1 |
| 238 | 1 | mixed incomplete+today-completed | "fixing fatigue" | 1 |
| 239 | 1 | mixed incomplete+today-completed | "challenge mode" | 1 |
| 240 | 1 | mixed incomplete+today-completed | "deload reset" | 1 |
| 241 | 1 | scheduled with NULL gym_profile | "rotational sweep" | 1 |
| 242 | 1 | scheduled with NULL gym_profile | "boring routine" | 1 |
| 243 | 1 | scheduled with NULL gym_profile | "fresh start" | 1 |
| 244 | 1 | scheduled with NULL gym_profile | "schedule change" | 1 |
| 245 | 1 | scheduled with NULL gym_profile | "new program" | 1 |
| 246 | 1 | scheduled with NULL gym_profile | "rest week followup" | 1 |
| 247 | 1 | scheduled with NULL gym_profile | "back from vacation" | 1 |
| 248 | 1 | scheduled with NULL gym_profile | "fixing fatigue" | 1 |
| 249 | 1 | scheduled with NULL gym_profile | "challenge mode" | 1 |
| 250 | 1 | scheduled with NULL gym_profile | "deload reset" | 1 |
| 251 | 1 | scheduled + workout_changes child | "rotational sweep" | 1 |
| 252 | 1 | scheduled + workout_changes child | "boring routine" | 1 |
| 253 | 1 | scheduled + workout_changes child | "fresh start" | 1 |
| 254 | 1 | scheduled + workout_changes child | "schedule change" | 1 |
| 255 | 1 | scheduled + workout_changes child | "new program" | 1 |
| 256 | 1 | scheduled + workout_changes child | "rest week followup" | 1 |
| 257 | 1 | scheduled + workout_changes child | "back from vacation" | 1 |
| 258 | 1 | scheduled + workout_changes child | "fixing fatigue" | 1 |
| 259 | 1 | scheduled + workout_changes child | "challenge mode" | 1 |
| 260 | 1 | scheduled + workout_changes child | "deload reset" | 1 |
| 261 | 1 | scheduled 30+ days out | "rotational sweep" | 1 |
| 262 | 1 | scheduled 30+ days out | "boring routine" | 1 |
| 263 | 1 | scheduled 30+ days out | "fresh start" | 1 |
| 264 | 1 | scheduled 30+ days out | "schedule change" | 1 |
| 265 | 1 | scheduled 30+ days out | "new program" | 1 |
| 266 | 1 | scheduled 30+ days out | "rest week followup" | 1 |
| 267 | 1 | scheduled 30+ days out | "back from vacation" | 1 |
| 268 | 1 | scheduled 30+ days out | "fixing fatigue" | 1 |
| 269 | 1 | scheduled 30+ days out | "challenge mode" | 1 |
| 270 | 1 | scheduled 30+ days out | "deload reset" | 1 |
| 271 | 1 | all on today | "rotational sweep" | 1 |
| 272 | 1 | all on today | "boring routine" | 1 |
| 273 | 1 | all on today | "fresh start" | 1 |
| 274 | 1 | all on today | "schedule change" | 1 |
| 275 | 1 | all on today | "new program" | 1 |
| 276 | 1 | all on today | "rest week followup" | 1 |
| 277 | 1 | all on today | "back from vacation" | 1 |
| 278 | 1 | all on today | "fixing fatigue" | 1 |
| 279 | 1 | all on today | "challenge mode" | 1 |
| 280 | 1 | all on today | "deload reset" | 1 |
| 281 | 2 | scheduled | "rotational sweep" | 2 |
| 282 | 2 | scheduled | "boring routine" | 2 |
| 283 | 2 | scheduled | "fresh start" | 2 |
| 284 | 2 | scheduled | "schedule change" | 2 |
| 285 | 2 | scheduled | "new program" | 2 |
| 286 | 2 | scheduled | "rest week followup" | 2 |
| 287 | 2 | scheduled | "back from vacation" | 2 |
| 288 | 2 | scheduled | "fixing fatigue" | 2 |
| 289 | 2 | scheduled | "challenge mode" | 2 |
| 290 | 2 | scheduled | "deload reset" | 2 |
| 291 | 2 | generating placeholder | "rotational sweep" | 2 |
| 292 | 2 | generating placeholder | "boring routine" | 2 |
| 293 | 2 | generating placeholder | "fresh start" | 2 |
| 294 | 2 | generating placeholder | "schedule change" | 2 |
| 295 | 2 | generating placeholder | "new program" | 2 |
| 296 | 2 | generating placeholder | "rest week followup" | 2 |
| 297 | 2 | generating placeholder | "back from vacation" | 2 |
| 298 | 2 | generating placeholder | "fixing fatigue" | 2 |
| 299 | 2 | generating placeholder | "challenge mode" | 2 |
| 300 | 2 | generating placeholder | "deload reset" | 2 |
| 301 | 2 | mixed scheduled+generating | "rotational sweep" | 2 |
| 302 | 2 | mixed scheduled+generating | "boring routine" | 2 |
| 303 | 2 | mixed scheduled+generating | "fresh start" | 2 |
| 304 | 2 | mixed scheduled+generating | "schedule change" | 2 |
| 305 | 2 | mixed scheduled+generating | "new program" | 2 |
| 306 | 2 | mixed scheduled+generating | "rest week followup" | 2 |
| 307 | 2 | mixed scheduled+generating | "back from vacation" | 2 |
| 308 | 2 | mixed scheduled+generating | "fixing fatigue" | 2 |
| 309 | 2 | mixed scheduled+generating | "challenge mode" | 2 |
| 310 | 2 | mixed scheduled+generating | "deload reset" | 2 |
| 311 | 2 | mixed incomplete+today-completed | "rotational sweep" | 1 |
| 312 | 2 | mixed incomplete+today-completed | "boring routine" | 1 |
| 313 | 2 | mixed incomplete+today-completed | "fresh start" | 1 |
| 314 | 2 | mixed incomplete+today-completed | "schedule change" | 1 |
| 315 | 2 | mixed incomplete+today-completed | "new program" | 1 |
| 316 | 2 | mixed incomplete+today-completed | "rest week followup" | 1 |
| 317 | 2 | mixed incomplete+today-completed | "back from vacation" | 1 |
| 318 | 2 | mixed incomplete+today-completed | "fixing fatigue" | 1 |
| 319 | 2 | mixed incomplete+today-completed | "challenge mode" | 1 |
| 320 | 2 | mixed incomplete+today-completed | "deload reset" | 1 |
| 321 | 2 | scheduled with NULL gym_profile | "rotational sweep" | 2 |
| 322 | 2 | scheduled with NULL gym_profile | "boring routine" | 2 |
| 323 | 2 | scheduled with NULL gym_profile | "fresh start" | 2 |
| 324 | 2 | scheduled with NULL gym_profile | "schedule change" | 2 |
| 325 | 2 | scheduled with NULL gym_profile | "new program" | 2 |
| 326 | 2 | scheduled with NULL gym_profile | "rest week followup" | 2 |
| 327 | 2 | scheduled with NULL gym_profile | "back from vacation" | 2 |
| 328 | 2 | scheduled with NULL gym_profile | "fixing fatigue" | 2 |
| 329 | 2 | scheduled with NULL gym_profile | "challenge mode" | 2 |
| 330 | 2 | scheduled with NULL gym_profile | "deload reset" | 2 |
| 331 | 2 | scheduled + workout_changes child | "rotational sweep" | 2 |
| 332 | 2 | scheduled + workout_changes child | "boring routine" | 2 |
| 333 | 2 | scheduled + workout_changes child | "fresh start" | 2 |
| 334 | 2 | scheduled + workout_changes child | "schedule change" | 2 |
| 335 | 2 | scheduled + workout_changes child | "new program" | 2 |
| 336 | 2 | scheduled + workout_changes child | "rest week followup" | 2 |
| 337 | 2 | scheduled + workout_changes child | "back from vacation" | 2 |
| 338 | 2 | scheduled + workout_changes child | "fixing fatigue" | 2 |
| 339 | 2 | scheduled + workout_changes child | "challenge mode" | 2 |
| 340 | 2 | scheduled + workout_changes child | "deload reset" | 2 |
| 341 | 2 | scheduled 30+ days out | "rotational sweep" | 2 |
| 342 | 2 | scheduled 30+ days out | "boring routine" | 2 |
| 343 | 2 | scheduled 30+ days out | "fresh start" | 2 |
| 344 | 2 | scheduled 30+ days out | "schedule change" | 2 |
| 345 | 2 | scheduled 30+ days out | "new program" | 2 |
| 346 | 2 | scheduled 30+ days out | "rest week followup" | 2 |
| 347 | 2 | scheduled 30+ days out | "back from vacation" | 2 |
| 348 | 2 | scheduled 30+ days out | "fixing fatigue" | 2 |
| 349 | 2 | scheduled 30+ days out | "challenge mode" | 2 |
| 350 | 2 | scheduled 30+ days out | "deload reset" | 2 |
| 351 | 2 | all on today | "rotational sweep" | 2 |
| 352 | 2 | all on today | "boring routine" | 2 |
| 353 | 2 | all on today | "fresh start" | 2 |
| 354 | 2 | all on today | "schedule change" | 2 |
| 355 | 2 | all on today | "new program" | 2 |
| 356 | 2 | all on today | "rest week followup" | 2 |
| 357 | 2 | all on today | "back from vacation" | 2 |
| 358 | 2 | all on today | "fixing fatigue" | 2 |
| 359 | 2 | all on today | "challenge mode" | 2 |
| 360 | 2 | all on today | "deload reset" | 2 |
| 361 | 3 | scheduled | "rotational sweep" | 3 |
| 362 | 3 | scheduled | "boring routine" | 3 |
| 363 | 3 | scheduled | "fresh start" | 3 |
| 364 | 3 | scheduled | "schedule change" | 3 |
| 365 | 3 | scheduled | "new program" | 3 |
| 366 | 3 | scheduled | "rest week followup" | 3 |
| 367 | 3 | scheduled | "back from vacation" | 3 |
| 368 | 3 | scheduled | "fixing fatigue" | 3 |
| 369 | 3 | scheduled | "challenge mode" | 3 |
| 370 | 3 | scheduled | "deload reset" | 3 |
| 371 | 3 | generating placeholder | "rotational sweep" | 3 |
| 372 | 3 | generating placeholder | "boring routine" | 3 |
| 373 | 3 | generating placeholder | "fresh start" | 3 |
| 374 | 3 | generating placeholder | "schedule change" | 3 |
| 375 | 3 | generating placeholder | "new program" | 3 |
| 376 | 3 | generating placeholder | "rest week followup" | 3 |
| 377 | 3 | generating placeholder | "back from vacation" | 3 |
| 378 | 3 | generating placeholder | "fixing fatigue" | 3 |
| 379 | 3 | generating placeholder | "challenge mode" | 3 |
| 380 | 3 | generating placeholder | "deload reset" | 3 |
| 381 | 3 | mixed scheduled+generating | "rotational sweep" | 3 |
| 382 | 3 | mixed scheduled+generating | "boring routine" | 3 |
| 383 | 3 | mixed scheduled+generating | "fresh start" | 3 |
| 384 | 3 | mixed scheduled+generating | "schedule change" | 3 |
| 385 | 3 | mixed scheduled+generating | "new program" | 3 |
| 386 | 3 | mixed scheduled+generating | "rest week followup" | 3 |
| 387 | 3 | mixed scheduled+generating | "back from vacation" | 3 |
| 388 | 3 | mixed scheduled+generating | "fixing fatigue" | 3 |
| 389 | 3 | mixed scheduled+generating | "challenge mode" | 3 |
| 390 | 3 | mixed scheduled+generating | "deload reset" | 3 |
| 391 | 3 | mixed incomplete+today-completed | "rotational sweep" | 2 |
| 392 | 3 | mixed incomplete+today-completed | "boring routine" | 2 |
| 393 | 3 | mixed incomplete+today-completed | "fresh start" | 2 |
| 394 | 3 | mixed incomplete+today-completed | "schedule change" | 2 |
| 395 | 3 | mixed incomplete+today-completed | "new program" | 2 |
| 396 | 3 | mixed incomplete+today-completed | "rest week followup" | 2 |
| 397 | 3 | mixed incomplete+today-completed | "back from vacation" | 2 |
| 398 | 3 | mixed incomplete+today-completed | "fixing fatigue" | 2 |
| 399 | 3 | mixed incomplete+today-completed | "challenge mode" | 2 |
| 400 | 3 | mixed incomplete+today-completed | "deload reset" | 2 |
| 401 | 3 | scheduled with NULL gym_profile | "rotational sweep" | 3 |
| 402 | 3 | scheduled with NULL gym_profile | "boring routine" | 3 |
| 403 | 3 | scheduled with NULL gym_profile | "fresh start" | 3 |
| 404 | 3 | scheduled with NULL gym_profile | "schedule change" | 3 |
| 405 | 3 | scheduled with NULL gym_profile | "new program" | 3 |
| 406 | 3 | scheduled with NULL gym_profile | "rest week followup" | 3 |
| 407 | 3 | scheduled with NULL gym_profile | "back from vacation" | 3 |
| 408 | 3 | scheduled with NULL gym_profile | "fixing fatigue" | 3 |
| 409 | 3 | scheduled with NULL gym_profile | "challenge mode" | 3 |
| 410 | 3 | scheduled with NULL gym_profile | "deload reset" | 3 |
| 411 | 3 | scheduled + workout_changes child | "rotational sweep" | 3 |
| 412 | 3 | scheduled + workout_changes child | "boring routine" | 3 |
| 413 | 3 | scheduled + workout_changes child | "fresh start" | 3 |
| 414 | 3 | scheduled + workout_changes child | "schedule change" | 3 |
| 415 | 3 | scheduled + workout_changes child | "new program" | 3 |
| 416 | 3 | scheduled + workout_changes child | "rest week followup" | 3 |
| 417 | 3 | scheduled + workout_changes child | "back from vacation" | 3 |
| 418 | 3 | scheduled + workout_changes child | "fixing fatigue" | 3 |
| 419 | 3 | scheduled + workout_changes child | "challenge mode" | 3 |
| 420 | 3 | scheduled + workout_changes child | "deload reset" | 3 |
| 421 | 3 | scheduled 30+ days out | "rotational sweep" | 3 |
| 422 | 3 | scheduled 30+ days out | "boring routine" | 3 |
| 423 | 3 | scheduled 30+ days out | "fresh start" | 3 |
| 424 | 3 | scheduled 30+ days out | "schedule change" | 3 |
| 425 | 3 | scheduled 30+ days out | "new program" | 3 |
| 426 | 3 | scheduled 30+ days out | "rest week followup" | 3 |
| 427 | 3 | scheduled 30+ days out | "back from vacation" | 3 |
| 428 | 3 | scheduled 30+ days out | "fixing fatigue" | 3 |
| 429 | 3 | scheduled 30+ days out | "challenge mode" | 3 |
| 430 | 3 | scheduled 30+ days out | "deload reset" | 3 |
| 431 | 3 | all on today | "rotational sweep" | 3 |
| 432 | 3 | all on today | "boring routine" | 3 |
| 433 | 3 | all on today | "fresh start" | 3 |
| 434 | 3 | all on today | "schedule change" | 3 |
| 435 | 3 | all on today | "new program" | 3 |
| 436 | 3 | all on today | "rest week followup" | 3 |
| 437 | 3 | all on today | "back from vacation" | 3 |
| 438 | 3 | all on today | "fixing fatigue" | 3 |
| 439 | 3 | all on today | "challenge mode" | 3 |
| 440 | 3 | all on today | "deload reset" | 3 |
| 441 | 5 | scheduled | "rotational sweep" | 5 |
| 442 | 5 | scheduled | "boring routine" | 5 |
| 443 | 5 | scheduled | "fresh start" | 5 |
| 444 | 5 | scheduled | "schedule change" | 5 |
| 445 | 5 | scheduled | "new program" | 5 |
| 446 | 5 | scheduled | "rest week followup" | 5 |
| 447 | 5 | scheduled | "back from vacation" | 5 |
| 448 | 5 | scheduled | "fixing fatigue" | 5 |
| 449 | 5 | scheduled | "challenge mode" | 5 |
| 450 | 5 | scheduled | "deload reset" | 5 |
| 451 | 5 | generating placeholder | "rotational sweep" | 5 |
| 452 | 5 | generating placeholder | "boring routine" | 5 |
| 453 | 5 | generating placeholder | "fresh start" | 5 |
| 454 | 5 | generating placeholder | "schedule change" | 5 |
| 455 | 5 | generating placeholder | "new program" | 5 |
| 456 | 5 | generating placeholder | "rest week followup" | 5 |
| 457 | 5 | generating placeholder | "back from vacation" | 5 |
| 458 | 5 | generating placeholder | "fixing fatigue" | 5 |
| 459 | 5 | generating placeholder | "challenge mode" | 5 |
| 460 | 5 | generating placeholder | "deload reset" | 5 |
| 461 | 5 | mixed scheduled+generating | "rotational sweep" | 5 |
| 462 | 5 | mixed scheduled+generating | "boring routine" | 5 |
| 463 | 5 | mixed scheduled+generating | "fresh start" | 5 |
| 464 | 5 | mixed scheduled+generating | "schedule change" | 5 |
| 465 | 5 | mixed scheduled+generating | "new program" | 5 |
| 466 | 5 | mixed scheduled+generating | "rest week followup" | 5 |
| 467 | 5 | mixed scheduled+generating | "back from vacation" | 5 |
| 468 | 5 | mixed scheduled+generating | "fixing fatigue" | 5 |
| 469 | 5 | mixed scheduled+generating | "challenge mode" | 5 |
| 470 | 5 | mixed scheduled+generating | "deload reset" | 5 |
| 471 | 5 | mixed incomplete+today-completed | "rotational sweep" | 4 |
| 472 | 5 | mixed incomplete+today-completed | "boring routine" | 4 |
| 473 | 5 | mixed incomplete+today-completed | "fresh start" | 4 |
| 474 | 5 | mixed incomplete+today-completed | "schedule change" | 4 |
| 475 | 5 | mixed incomplete+today-completed | "new program" | 4 |
| 476 | 5 | mixed incomplete+today-completed | "rest week followup" | 4 |
| 477 | 5 | mixed incomplete+today-completed | "back from vacation" | 4 |
| 478 | 5 | mixed incomplete+today-completed | "fixing fatigue" | 4 |
| 479 | 5 | mixed incomplete+today-completed | "challenge mode" | 4 |
| 480 | 5 | mixed incomplete+today-completed | "deload reset" | 4 |
| 481 | 5 | scheduled with NULL gym_profile | "rotational sweep" | 5 |
| 482 | 5 | scheduled with NULL gym_profile | "boring routine" | 5 |
| 483 | 5 | scheduled with NULL gym_profile | "fresh start" | 5 |
| 484 | 5 | scheduled with NULL gym_profile | "schedule change" | 5 |
| 485 | 5 | scheduled with NULL gym_profile | "new program" | 5 |
| 486 | 5 | scheduled with NULL gym_profile | "rest week followup" | 5 |
| 487 | 5 | scheduled with NULL gym_profile | "back from vacation" | 5 |
| 488 | 5 | scheduled with NULL gym_profile | "fixing fatigue" | 5 |
| 489 | 5 | scheduled with NULL gym_profile | "challenge mode" | 5 |
| 490 | 5 | scheduled with NULL gym_profile | "deload reset" | 5 |
| 491 | 5 | scheduled + workout_changes child | "rotational sweep" | 5 |
| 492 | 5 | scheduled + workout_changes child | "boring routine" | 5 |
| 493 | 5 | scheduled + workout_changes child | "fresh start" | 5 |
| 494 | 5 | scheduled + workout_changes child | "schedule change" | 5 |
| 495 | 5 | scheduled + workout_changes child | "new program" | 5 |
| 496 | 5 | scheduled + workout_changes child | "rest week followup" | 5 |
| 497 | 5 | scheduled + workout_changes child | "back from vacation" | 5 |
| 498 | 5 | scheduled + workout_changes child | "fixing fatigue" | 5 |
| 499 | 5 | scheduled + workout_changes child | "challenge mode" | 5 |
| 500 | 5 | scheduled + workout_changes child | "deload reset" | 5 |
| 501 | 5 | scheduled 30+ days out | "rotational sweep" | 5 |
| 502 | 5 | scheduled 30+ days out | "boring routine" | 5 |
| 503 | 5 | scheduled 30+ days out | "fresh start" | 5 |
| 504 | 5 | scheduled 30+ days out | "schedule change" | 5 |
| 505 | 5 | scheduled 30+ days out | "new program" | 5 |
| 506 | 5 | scheduled 30+ days out | "rest week followup" | 5 |
| 507 | 5 | scheduled 30+ days out | "back from vacation" | 5 |
| 508 | 5 | scheduled 30+ days out | "fixing fatigue" | 5 |
| 509 | 5 | scheduled 30+ days out | "challenge mode" | 5 |
| 510 | 5 | scheduled 30+ days out | "deload reset" | 5 |
| 511 | 5 | all on today | "rotational sweep" | 5 |
| 512 | 5 | all on today | "boring routine" | 5 |
| 513 | 5 | all on today | "fresh start" | 5 |
| 514 | 5 | all on today | "schedule change" | 5 |
| 515 | 5 | all on today | "new program" | 5 |
| 516 | 5 | all on today | "rest week followup" | 5 |
| 517 | 5 | all on today | "back from vacation" | 5 |
| 518 | 5 | all on today | "fixing fatigue" | 5 |
| 519 | 5 | all on today | "challenge mode" | 5 |
| 520 | 5 | all on today | "deload reset" | 5 |
| 521 | 7 | scheduled | "rotational sweep" | 7 |
| 522 | 7 | scheduled | "boring routine" | 7 |
| 523 | 7 | scheduled | "fresh start" | 7 |
| 524 | 7 | scheduled | "schedule change" | 7 |
| 525 | 7 | scheduled | "new program" | 7 |
| 526 | 7 | scheduled | "rest week followup" | 7 |
| 527 | 7 | scheduled | "back from vacation" | 7 |
| 528 | 7 | scheduled | "fixing fatigue" | 7 |
| 529 | 7 | scheduled | "challenge mode" | 7 |
| 530 | 7 | scheduled | "deload reset" | 7 |
| 531 | 7 | generating placeholder | "rotational sweep" | 7 |
| 532 | 7 | generating placeholder | "boring routine" | 7 |
| 533 | 7 | generating placeholder | "fresh start" | 7 |
| 534 | 7 | generating placeholder | "schedule change" | 7 |
| 535 | 7 | generating placeholder | "new program" | 7 |
| 536 | 7 | generating placeholder | "rest week followup" | 7 |
| 537 | 7 | generating placeholder | "back from vacation" | 7 |
| 538 | 7 | generating placeholder | "fixing fatigue" | 7 |
| 539 | 7 | generating placeholder | "challenge mode" | 7 |
| 540 | 7 | generating placeholder | "deload reset" | 7 |
| 541 | 7 | mixed scheduled+generating | "rotational sweep" | 7 |
| 542 | 7 | mixed scheduled+generating | "boring routine" | 7 |
| 543 | 7 | mixed scheduled+generating | "fresh start" | 7 |
| 544 | 7 | mixed scheduled+generating | "schedule change" | 7 |
| 545 | 7 | mixed scheduled+generating | "new program" | 7 |
| 546 | 7 | mixed scheduled+generating | "rest week followup" | 7 |
| 547 | 7 | mixed scheduled+generating | "back from vacation" | 7 |
| 548 | 7 | mixed scheduled+generating | "fixing fatigue" | 7 |
| 549 | 7 | mixed scheduled+generating | "challenge mode" | 7 |
| 550 | 7 | mixed scheduled+generating | "deload reset" | 7 |
| 551 | 7 | mixed incomplete+today-completed | "rotational sweep" | 6 |
| 552 | 7 | mixed incomplete+today-completed | "boring routine" | 6 |
| 553 | 7 | mixed incomplete+today-completed | "fresh start" | 6 |
| 554 | 7 | mixed incomplete+today-completed | "schedule change" | 6 |
| 555 | 7 | mixed incomplete+today-completed | "new program" | 6 |
| 556 | 7 | mixed incomplete+today-completed | "rest week followup" | 6 |
| 557 | 7 | mixed incomplete+today-completed | "back from vacation" | 6 |
| 558 | 7 | mixed incomplete+today-completed | "fixing fatigue" | 6 |
| 559 | 7 | mixed incomplete+today-completed | "challenge mode" | 6 |
| 560 | 7 | mixed incomplete+today-completed | "deload reset" | 6 |
| 561 | 7 | scheduled with NULL gym_profile | "rotational sweep" | 7 |
| 562 | 7 | scheduled with NULL gym_profile | "boring routine" | 7 |
| 563 | 7 | scheduled with NULL gym_profile | "fresh start" | 7 |
| 564 | 7 | scheduled with NULL gym_profile | "schedule change" | 7 |
| 565 | 7 | scheduled with NULL gym_profile | "new program" | 7 |
| 566 | 7 | scheduled with NULL gym_profile | "rest week followup" | 7 |
| 567 | 7 | scheduled with NULL gym_profile | "back from vacation" | 7 |
| 568 | 7 | scheduled with NULL gym_profile | "fixing fatigue" | 7 |
| 569 | 7 | scheduled with NULL gym_profile | "challenge mode" | 7 |
| 570 | 7 | scheduled with NULL gym_profile | "deload reset" | 7 |
| 571 | 7 | scheduled + workout_changes child | "rotational sweep" | 7 |
| 572 | 7 | scheduled + workout_changes child | "boring routine" | 7 |
| 573 | 7 | scheduled + workout_changes child | "fresh start" | 7 |
| 574 | 7 | scheduled + workout_changes child | "schedule change" | 7 |
| 575 | 7 | scheduled + workout_changes child | "new program" | 7 |
| 576 | 7 | scheduled + workout_changes child | "rest week followup" | 7 |
| 577 | 7 | scheduled + workout_changes child | "back from vacation" | 7 |
| 578 | 7 | scheduled + workout_changes child | "fixing fatigue" | 7 |
| 579 | 7 | scheduled + workout_changes child | "challenge mode" | 7 |
| 580 | 7 | scheduled + workout_changes child | "deload reset" | 7 |
| 581 | 7 | scheduled 30+ days out | "rotational sweep" | 7 |
| 582 | 7 | scheduled 30+ days out | "boring routine" | 7 |
| 583 | 7 | scheduled 30+ days out | "fresh start" | 7 |
| 584 | 7 | scheduled 30+ days out | "schedule change" | 7 |
| 585 | 7 | scheduled 30+ days out | "new program" | 7 |
| 586 | 7 | scheduled 30+ days out | "rest week followup" | 7 |
| 587 | 7 | scheduled 30+ days out | "back from vacation" | 7 |
| 588 | 7 | scheduled 30+ days out | "fixing fatigue" | 7 |
| 589 | 7 | scheduled 30+ days out | "challenge mode" | 7 |
| 590 | 7 | scheduled 30+ days out | "deload reset" | 7 |
| 591 | 7 | all on today | "rotational sweep" | 7 |
| 592 | 7 | all on today | "boring routine" | 7 |
| 593 | 7 | all on today | "fresh start" | 7 |
| 594 | 7 | all on today | "schedule change" | 7 |
| 595 | 7 | all on today | "new program" | 7 |
| 596 | 7 | all on today | "rest week followup" | 7 |
| 597 | 7 | all on today | "back from vacation" | 7 |
| 598 | 7 | all on today | "fixing fatigue" | 7 |
| 599 | 7 | all on today | "challenge mode" | 7 |
| 600 | 7 | all on today | "deload reset" | 7 |
| 601 | 10 | scheduled | "rotational sweep" | 10 |
| 602 | 10 | scheduled | "boring routine" | 10 |
| 603 | 10 | scheduled | "fresh start" | 10 |
| 604 | 10 | scheduled | "schedule change" | 10 |
| 605 | 10 | scheduled | "new program" | 10 |
| 606 | 10 | scheduled | "rest week followup" | 10 |
| 607 | 10 | scheduled | "back from vacation" | 10 |
| 608 | 10 | scheduled | "fixing fatigue" | 10 |
| 609 | 10 | scheduled | "challenge mode" | 10 |
| 610 | 10 | scheduled | "deload reset" | 10 |
| 611 | 10 | generating placeholder | "rotational sweep" | 10 |
| 612 | 10 | generating placeholder | "boring routine" | 10 |
| 613 | 10 | generating placeholder | "fresh start" | 10 |
| 614 | 10 | generating placeholder | "schedule change" | 10 |
| 615 | 10 | generating placeholder | "new program" | 10 |
| 616 | 10 | generating placeholder | "rest week followup" | 10 |
| 617 | 10 | generating placeholder | "back from vacation" | 10 |
| 618 | 10 | generating placeholder | "fixing fatigue" | 10 |
| 619 | 10 | generating placeholder | "challenge mode" | 10 |
| 620 | 10 | generating placeholder | "deload reset" | 10 |
| 621 | 10 | mixed scheduled+generating | "rotational sweep" | 10 |
| 622 | 10 | mixed scheduled+generating | "boring routine" | 10 |
| 623 | 10 | mixed scheduled+generating | "fresh start" | 10 |
| 624 | 10 | mixed scheduled+generating | "schedule change" | 10 |
| 625 | 10 | mixed scheduled+generating | "new program" | 10 |
| 626 | 10 | mixed scheduled+generating | "rest week followup" | 10 |
| 627 | 10 | mixed scheduled+generating | "back from vacation" | 10 |
| 628 | 10 | mixed scheduled+generating | "fixing fatigue" | 10 |
| 629 | 10 | mixed scheduled+generating | "challenge mode" | 10 |
| 630 | 10 | mixed scheduled+generating | "deload reset" | 10 |
| 631 | 10 | mixed incomplete+today-completed | "rotational sweep" | 9 |
| 632 | 10 | mixed incomplete+today-completed | "boring routine" | 9 |
| 633 | 10 | mixed incomplete+today-completed | "fresh start" | 9 |
| 634 | 10 | mixed incomplete+today-completed | "schedule change" | 9 |
| 635 | 10 | mixed incomplete+today-completed | "new program" | 9 |
| 636 | 10 | mixed incomplete+today-completed | "rest week followup" | 9 |
| 637 | 10 | mixed incomplete+today-completed | "back from vacation" | 9 |
| 638 | 10 | mixed incomplete+today-completed | "fixing fatigue" | 9 |
| 639 | 10 | mixed incomplete+today-completed | "challenge mode" | 9 |
| 640 | 10 | mixed incomplete+today-completed | "deload reset" | 9 |
| 641 | 10 | scheduled with NULL gym_profile | "rotational sweep" | 10 |
| 642 | 10 | scheduled with NULL gym_profile | "boring routine" | 10 |
| 643 | 10 | scheduled with NULL gym_profile | "fresh start" | 10 |
| 644 | 10 | scheduled with NULL gym_profile | "schedule change" | 10 |
| 645 | 10 | scheduled with NULL gym_profile | "new program" | 10 |
| 646 | 10 | scheduled with NULL gym_profile | "rest week followup" | 10 |
| 647 | 10 | scheduled with NULL gym_profile | "back from vacation" | 10 |
| 648 | 10 | scheduled with NULL gym_profile | "fixing fatigue" | 10 |
| 649 | 10 | scheduled with NULL gym_profile | "challenge mode" | 10 |
| 650 | 10 | scheduled with NULL gym_profile | "deload reset" | 10 |
| 651 | 10 | scheduled + workout_changes child | "rotational sweep" | 10 |
| 652 | 10 | scheduled + workout_changes child | "boring routine" | 10 |
| 653 | 10 | scheduled + workout_changes child | "fresh start" | 10 |
| 654 | 10 | scheduled + workout_changes child | "schedule change" | 10 |
| 655 | 10 | scheduled + workout_changes child | "new program" | 10 |
| 656 | 10 | scheduled + workout_changes child | "rest week followup" | 10 |
| 657 | 10 | scheduled + workout_changes child | "back from vacation" | 10 |
| 658 | 10 | scheduled + workout_changes child | "fixing fatigue" | 10 |
| 659 | 10 | scheduled + workout_changes child | "challenge mode" | 10 |
| 660 | 10 | scheduled + workout_changes child | "deload reset" | 10 |
| 661 | 10 | scheduled 30+ days out | "rotational sweep" | 10 |
| 662 | 10 | scheduled 30+ days out | "boring routine" | 10 |
| 663 | 10 | scheduled 30+ days out | "fresh start" | 10 |
| 664 | 10 | scheduled 30+ days out | "schedule change" | 10 |
| 665 | 10 | scheduled 30+ days out | "new program" | 10 |
| 666 | 10 | scheduled 30+ days out | "rest week followup" | 10 |
| 667 | 10 | scheduled 30+ days out | "back from vacation" | 10 |
| 668 | 10 | scheduled 30+ days out | "fixing fatigue" | 10 |
| 669 | 10 | scheduled 30+ days out | "challenge mode" | 10 |
| 670 | 10 | scheduled 30+ days out | "deload reset" | 10 |
| 671 | 10 | all on today | "rotational sweep" | 10 |
| 672 | 10 | all on today | "boring routine" | 10 |
| 673 | 10 | all on today | "fresh start" | 10 |
| 674 | 10 | all on today | "schedule change" | 10 |
| 675 | 10 | all on today | "new program" | 10 |
| 676 | 10 | all on today | "rest week followup" | 10 |
| 677 | 10 | all on today | "back from vacation" | 10 |
| 678 | 10 | all on today | "fixing fatigue" | 10 |
| 679 | 10 | all on today | "challenge mode" | 10 |
| 680 | 10 | all on today | "deload reset" | 10 |
| 681 | 14 | scheduled | "rotational sweep" | 14 |
| 682 | 14 | scheduled | "boring routine" | 14 |
| 683 | 14 | scheduled | "fresh start" | 14 |
| 684 | 14 | scheduled | "schedule change" | 14 |
| 685 | 14 | scheduled | "new program" | 14 |
| 686 | 14 | scheduled | "rest week followup" | 14 |
| 687 | 14 | scheduled | "back from vacation" | 14 |
| 688 | 14 | scheduled | "fixing fatigue" | 14 |
| 689 | 14 | scheduled | "challenge mode" | 14 |
| 690 | 14 | scheduled | "deload reset" | 14 |
| 691 | 14 | generating placeholder | "rotational sweep" | 14 |
| 692 | 14 | generating placeholder | "boring routine" | 14 |
| 693 | 14 | generating placeholder | "fresh start" | 14 |
| 694 | 14 | generating placeholder | "schedule change" | 14 |
| 695 | 14 | generating placeholder | "new program" | 14 |
| 696 | 14 | generating placeholder | "rest week followup" | 14 |
| 697 | 14 | generating placeholder | "back from vacation" | 14 |
| 698 | 14 | generating placeholder | "fixing fatigue" | 14 |
| 699 | 14 | generating placeholder | "challenge mode" | 14 |
| 700 | 14 | generating placeholder | "deload reset" | 14 |
| 701 | 14 | mixed scheduled+generating | "rotational sweep" | 14 |
| 702 | 14 | mixed scheduled+generating | "boring routine" | 14 |
| 703 | 14 | mixed scheduled+generating | "fresh start" | 14 |
| 704 | 14 | mixed scheduled+generating | "schedule change" | 14 |
| 705 | 14 | mixed scheduled+generating | "new program" | 14 |
| 706 | 14 | mixed scheduled+generating | "rest week followup" | 14 |
| 707 | 14 | mixed scheduled+generating | "back from vacation" | 14 |
| 708 | 14 | mixed scheduled+generating | "fixing fatigue" | 14 |
| 709 | 14 | mixed scheduled+generating | "challenge mode" | 14 |
| 710 | 14 | mixed scheduled+generating | "deload reset" | 14 |
| 711 | 14 | mixed incomplete+today-completed | "rotational sweep" | 13 |
| 712 | 14 | mixed incomplete+today-completed | "boring routine" | 13 |
| 713 | 14 | mixed incomplete+today-completed | "fresh start" | 13 |
| 714 | 14 | mixed incomplete+today-completed | "schedule change" | 13 |
| 715 | 14 | mixed incomplete+today-completed | "new program" | 13 |
| 716 | 14 | mixed incomplete+today-completed | "rest week followup" | 13 |
| 717 | 14 | mixed incomplete+today-completed | "back from vacation" | 13 |
| 718 | 14 | mixed incomplete+today-completed | "fixing fatigue" | 13 |
| 719 | 14 | mixed incomplete+today-completed | "challenge mode" | 13 |
| 720 | 14 | mixed incomplete+today-completed | "deload reset" | 13 |
| 721 | 14 | scheduled with NULL gym_profile | "rotational sweep" | 14 |
| 722 | 14 | scheduled with NULL gym_profile | "boring routine" | 14 |
| 723 | 14 | scheduled with NULL gym_profile | "fresh start" | 14 |
| 724 | 14 | scheduled with NULL gym_profile | "schedule change" | 14 |
| 725 | 14 | scheduled with NULL gym_profile | "new program" | 14 |
| 726 | 14 | scheduled with NULL gym_profile | "rest week followup" | 14 |
| 727 | 14 | scheduled with NULL gym_profile | "back from vacation" | 14 |
| 728 | 14 | scheduled with NULL gym_profile | "fixing fatigue" | 14 |
| 729 | 14 | scheduled with NULL gym_profile | "challenge mode" | 14 |
| 730 | 14 | scheduled with NULL gym_profile | "deload reset" | 14 |
| 731 | 14 | scheduled + workout_changes child | "rotational sweep" | 14 |
| 732 | 14 | scheduled + workout_changes child | "boring routine" | 14 |
| 733 | 14 | scheduled + workout_changes child | "fresh start" | 14 |
| 734 | 14 | scheduled + workout_changes child | "schedule change" | 14 |
| 735 | 14 | scheduled + workout_changes child | "new program" | 14 |
| 736 | 14 | scheduled + workout_changes child | "rest week followup" | 14 |
| 737 | 14 | scheduled + workout_changes child | "back from vacation" | 14 |
| 738 | 14 | scheduled + workout_changes child | "fixing fatigue" | 14 |
| 739 | 14 | scheduled + workout_changes child | "challenge mode" | 14 |
| 740 | 14 | scheduled + workout_changes child | "deload reset" | 14 |
| 741 | 14 | scheduled 30+ days out | "rotational sweep" | 14 |
| 742 | 14 | scheduled 30+ days out | "boring routine" | 14 |
| 743 | 14 | scheduled 30+ days out | "fresh start" | 14 |
| 744 | 14 | scheduled 30+ days out | "schedule change" | 14 |
| 745 | 14 | scheduled 30+ days out | "new program" | 14 |
| 746 | 14 | scheduled 30+ days out | "rest week followup" | 14 |
| 747 | 14 | scheduled 30+ days out | "back from vacation" | 14 |
| 748 | 14 | scheduled 30+ days out | "fixing fatigue" | 14 |
| 749 | 14 | scheduled 30+ days out | "challenge mode" | 14 |
| 750 | 14 | scheduled 30+ days out | "deload reset" | 14 |
| 751 | 14 | all on today | "rotational sweep" | 14 |
| 752 | 14 | all on today | "boring routine" | 14 |
| 753 | 14 | all on today | "fresh start" | 14 |
| 754 | 14 | all on today | "schedule change" | 14 |
| 755 | 14 | all on today | "new program" | 14 |
| 756 | 14 | all on today | "rest week followup" | 14 |
| 757 | 14 | all on today | "back from vacation" | 14 |
| 758 | 14 | all on today | "fixing fatigue" | 14 |
| 759 | 14 | all on today | "challenge mode" | 14 |
| 760 | 14 | all on today | "deload reset" | 14 |
| 761 | 21 | scheduled | "rotational sweep" | 21 |
| 762 | 21 | scheduled | "boring routine" | 21 |
| 763 | 21 | scheduled | "fresh start" | 21 |
| 764 | 21 | scheduled | "schedule change" | 21 |
| 765 | 21 | scheduled | "new program" | 21 |
| 766 | 21 | scheduled | "rest week followup" | 21 |
| 767 | 21 | scheduled | "back from vacation" | 21 |
| 768 | 21 | scheduled | "fixing fatigue" | 21 |
| 769 | 21 | scheduled | "challenge mode" | 21 |
| 770 | 21 | scheduled | "deload reset" | 21 |
| 771 | 21 | generating placeholder | "rotational sweep" | 21 |
| 772 | 21 | generating placeholder | "boring routine" | 21 |
| 773 | 21 | generating placeholder | "fresh start" | 21 |
| 774 | 21 | generating placeholder | "schedule change" | 21 |
| 775 | 21 | generating placeholder | "new program" | 21 |
| 776 | 21 | generating placeholder | "rest week followup" | 21 |
| 777 | 21 | generating placeholder | "back from vacation" | 21 |
| 778 | 21 | generating placeholder | "fixing fatigue" | 21 |
| 779 | 21 | generating placeholder | "challenge mode" | 21 |
| 780 | 21 | generating placeholder | "deload reset" | 21 |
| 781 | 21 | mixed scheduled+generating | "rotational sweep" | 21 |
| 782 | 21 | mixed scheduled+generating | "boring routine" | 21 |
| 783 | 21 | mixed scheduled+generating | "fresh start" | 21 |
| 784 | 21 | mixed scheduled+generating | "schedule change" | 21 |
| 785 | 21 | mixed scheduled+generating | "new program" | 21 |
| 786 | 21 | mixed scheduled+generating | "rest week followup" | 21 |
| 787 | 21 | mixed scheduled+generating | "back from vacation" | 21 |
| 788 | 21 | mixed scheduled+generating | "fixing fatigue" | 21 |
| 789 | 21 | mixed scheduled+generating | "challenge mode" | 21 |
| 790 | 21 | mixed scheduled+generating | "deload reset" | 21 |
| 791 | 21 | mixed incomplete+today-completed | "rotational sweep" | 20 |
| 792 | 21 | mixed incomplete+today-completed | "boring routine" | 20 |
| 793 | 21 | mixed incomplete+today-completed | "fresh start" | 20 |
| 794 | 21 | mixed incomplete+today-completed | "schedule change" | 20 |
| 795 | 21 | mixed incomplete+today-completed | "new program" | 20 |
| 796 | 21 | mixed incomplete+today-completed | "rest week followup" | 20 |
| 797 | 21 | mixed incomplete+today-completed | "back from vacation" | 20 |
| 798 | 21 | mixed incomplete+today-completed | "fixing fatigue" | 20 |
| 799 | 21 | mixed incomplete+today-completed | "challenge mode" | 20 |
| 800 | 21 | mixed incomplete+today-completed | "deload reset" | 20 |
| 801 | 21 | scheduled with NULL gym_profile | "rotational sweep" | 21 |
| 802 | 21 | scheduled with NULL gym_profile | "boring routine" | 21 |
| 803 | 21 | scheduled with NULL gym_profile | "fresh start" | 21 |
| 804 | 21 | scheduled with NULL gym_profile | "schedule change" | 21 |
| 805 | 21 | scheduled with NULL gym_profile | "new program" | 21 |
| 806 | 21 | scheduled with NULL gym_profile | "rest week followup" | 21 |
| 807 | 21 | scheduled with NULL gym_profile | "back from vacation" | 21 |
| 808 | 21 | scheduled with NULL gym_profile | "fixing fatigue" | 21 |
| 809 | 21 | scheduled with NULL gym_profile | "challenge mode" | 21 |
| 810 | 21 | scheduled with NULL gym_profile | "deload reset" | 21 |
| 811 | 21 | scheduled + workout_changes child | "rotational sweep" | 21 |
| 812 | 21 | scheduled + workout_changes child | "boring routine" | 21 |
| 813 | 21 | scheduled + workout_changes child | "fresh start" | 21 |
| 814 | 21 | scheduled + workout_changes child | "schedule change" | 21 |
| 815 | 21 | scheduled + workout_changes child | "new program" | 21 |
| 816 | 21 | scheduled + workout_changes child | "rest week followup" | 21 |
| 817 | 21 | scheduled + workout_changes child | "back from vacation" | 21 |
| 818 | 21 | scheduled + workout_changes child | "fixing fatigue" | 21 |
| 819 | 21 | scheduled + workout_changes child | "challenge mode" | 21 |
| 820 | 21 | scheduled + workout_changes child | "deload reset" | 21 |
| 821 | 21 | scheduled 30+ days out | "rotational sweep" | 21 |
| 822 | 21 | scheduled 30+ days out | "boring routine" | 21 |
| 823 | 21 | scheduled 30+ days out | "fresh start" | 21 |
| 824 | 21 | scheduled 30+ days out | "schedule change" | 21 |
| 825 | 21 | scheduled 30+ days out | "new program" | 21 |
| 826 | 21 | scheduled 30+ days out | "rest week followup" | 21 |
| 827 | 21 | scheduled 30+ days out | "back from vacation" | 21 |
| 828 | 21 | scheduled 30+ days out | "fixing fatigue" | 21 |
| 829 | 21 | scheduled 30+ days out | "challenge mode" | 21 |
| 830 | 21 | scheduled 30+ days out | "deload reset" | 21 |
| 831 | 21 | all on today | "rotational sweep" | 21 |
| 832 | 21 | all on today | "boring routine" | 21 |
| 833 | 21 | all on today | "fresh start" | 21 |
| 834 | 21 | all on today | "schedule change" | 21 |
| 835 | 21 | all on today | "new program" | 21 |
| 836 | 21 | all on today | "rest week followup" | 21 |
| 837 | 21 | all on today | "back from vacation" | 21 |
| 838 | 21 | all on today | "fixing fatigue" | 21 |
| 839 | 21 | all on today | "challenge mode" | 21 |
| 840 | 21 | all on today | "deload reset" | 21 |
| 841 | 30 | scheduled | "rotational sweep" | 30 |
| 842 | 30 | scheduled | "boring routine" | 30 |
| 843 | 30 | scheduled | "fresh start" | 30 |
| 844 | 30 | scheduled | "schedule change" | 30 |
| 845 | 30 | scheduled | "new program" | 30 |
| 846 | 30 | scheduled | "rest week followup" | 30 |
| 847 | 30 | scheduled | "back from vacation" | 30 |
| 848 | 30 | scheduled | "fixing fatigue" | 30 |
| 849 | 30 | scheduled | "challenge mode" | 30 |
| 850 | 30 | scheduled | "deload reset" | 30 |
| 851 | 30 | generating placeholder | "rotational sweep" | 30 |
| 852 | 30 | generating placeholder | "boring routine" | 30 |
| 853 | 30 | generating placeholder | "fresh start" | 30 |
| 854 | 30 | generating placeholder | "schedule change" | 30 |
| 855 | 30 | generating placeholder | "new program" | 30 |
| 856 | 30 | generating placeholder | "rest week followup" | 30 |
| 857 | 30 | generating placeholder | "back from vacation" | 30 |
| 858 | 30 | generating placeholder | "fixing fatigue" | 30 |
| 859 | 30 | generating placeholder | "challenge mode" | 30 |
| 860 | 30 | generating placeholder | "deload reset" | 30 |
| 861 | 30 | mixed scheduled+generating | "rotational sweep" | 30 |
| 862 | 30 | mixed scheduled+generating | "boring routine" | 30 |
| 863 | 30 | mixed scheduled+generating | "fresh start" | 30 |
| 864 | 30 | mixed scheduled+generating | "schedule change" | 30 |
| 865 | 30 | mixed scheduled+generating | "new program" | 30 |
| 866 | 30 | mixed scheduled+generating | "rest week followup" | 30 |
| 867 | 30 | mixed scheduled+generating | "back from vacation" | 30 |
| 868 | 30 | mixed scheduled+generating | "fixing fatigue" | 30 |
| 869 | 30 | mixed scheduled+generating | "challenge mode" | 30 |
| 870 | 30 | mixed scheduled+generating | "deload reset" | 30 |
| 871 | 30 | mixed incomplete+today-completed | "rotational sweep" | 29 |
| 872 | 30 | mixed incomplete+today-completed | "boring routine" | 29 |
| 873 | 30 | mixed incomplete+today-completed | "fresh start" | 29 |
| 874 | 30 | mixed incomplete+today-completed | "schedule change" | 29 |
| 875 | 30 | mixed incomplete+today-completed | "new program" | 29 |
| 876 | 30 | mixed incomplete+today-completed | "rest week followup" | 29 |
| 877 | 30 | mixed incomplete+today-completed | "back from vacation" | 29 |
| 878 | 30 | mixed incomplete+today-completed | "fixing fatigue" | 29 |
| 879 | 30 | mixed incomplete+today-completed | "challenge mode" | 29 |
| 880 | 30 | mixed incomplete+today-completed | "deload reset" | 29 |
| 881 | 30 | scheduled with NULL gym_profile | "rotational sweep" | 30 |
| 882 | 30 | scheduled with NULL gym_profile | "boring routine" | 30 |
| 883 | 30 | scheduled with NULL gym_profile | "fresh start" | 30 |
| 884 | 30 | scheduled with NULL gym_profile | "schedule change" | 30 |
| 885 | 30 | scheduled with NULL gym_profile | "new program" | 30 |
| 886 | 30 | scheduled with NULL gym_profile | "rest week followup" | 30 |
| 887 | 30 | scheduled with NULL gym_profile | "back from vacation" | 30 |
| 888 | 30 | scheduled with NULL gym_profile | "fixing fatigue" | 30 |
| 889 | 30 | scheduled with NULL gym_profile | "challenge mode" | 30 |
| 890 | 30 | scheduled with NULL gym_profile | "deload reset" | 30 |
| 891 | 30 | scheduled + workout_changes child | "rotational sweep" | 30 |
| 892 | 30 | scheduled + workout_changes child | "boring routine" | 30 |
| 893 | 30 | scheduled + workout_changes child | "fresh start" | 30 |
| 894 | 30 | scheduled + workout_changes child | "schedule change" | 30 |
| 895 | 30 | scheduled + workout_changes child | "new program" | 30 |
| 896 | 30 | scheduled + workout_changes child | "rest week followup" | 30 |
| 897 | 30 | scheduled + workout_changes child | "back from vacation" | 30 |
| 898 | 30 | scheduled + workout_changes child | "fixing fatigue" | 30 |
| 899 | 30 | scheduled + workout_changes child | "challenge mode" | 30 |
| 900 | 30 | scheduled + workout_changes child | "deload reset" | 30 |
| 901 | 30 | scheduled 30+ days out | "rotational sweep" | 30 |
| 902 | 30 | scheduled 30+ days out | "boring routine" | 30 |
| 903 | 30 | scheduled 30+ days out | "fresh start" | 30 |
| 904 | 30 | scheduled 30+ days out | "schedule change" | 30 |
| 905 | 30 | scheduled 30+ days out | "new program" | 30 |
| 906 | 30 | scheduled 30+ days out | "rest week followup" | 30 |
| 907 | 30 | scheduled 30+ days out | "back from vacation" | 30 |
| 908 | 30 | scheduled 30+ days out | "fixing fatigue" | 30 |
| 909 | 30 | scheduled 30+ days out | "challenge mode" | 30 |
| 910 | 30 | scheduled 30+ days out | "deload reset" | 30 |
| 911 | 30 | all on today | "rotational sweep" | 30 |
| 912 | 30 | all on today | "boring routine" | 30 |
| 913 | 30 | all on today | "fresh start" | 30 |
| 914 | 30 | all on today | "schedule change" | 30 |
| 915 | 30 | all on today | "new program" | 30 |
| 916 | 30 | all on today | "rest week followup" | 30 |
| 917 | 30 | all on today | "back from vacation" | 30 |
| 918 | 30 | all on today | "fixing fatigue" | 30 |
| 919 | 30 | all on today | "challenge mode" | 30 |
| 920 | 30 | all on today | "deload reset" | 30 |
| 921 | 50 | scheduled | "rotational sweep" | 50 |
| 922 | 50 | scheduled | "boring routine" | 50 |
| 923 | 50 | scheduled | "fresh start" | 50 |
| 924 | 50 | scheduled | "schedule change" | 50 |
| 925 | 50 | scheduled | "new program" | 50 |
| 926 | 50 | scheduled | "rest week followup" | 50 |
| 927 | 50 | scheduled | "back from vacation" | 50 |
| 928 | 50 | scheduled | "fixing fatigue" | 50 |
| 929 | 50 | scheduled | "challenge mode" | 50 |
| 930 | 50 | scheduled | "deload reset" | 50 |
| 931 | 50 | generating placeholder | "rotational sweep" | 50 |
| 932 | 50 | generating placeholder | "boring routine" | 50 |
| 933 | 50 | generating placeholder | "fresh start" | 50 |
| 934 | 50 | generating placeholder | "schedule change" | 50 |
| 935 | 50 | generating placeholder | "new program" | 50 |
| 936 | 50 | generating placeholder | "rest week followup" | 50 |
| 937 | 50 | generating placeholder | "back from vacation" | 50 |
| 938 | 50 | generating placeholder | "fixing fatigue" | 50 |
| 939 | 50 | generating placeholder | "challenge mode" | 50 |
| 940 | 50 | generating placeholder | "deload reset" | 50 |
| 941 | 50 | mixed scheduled+generating | "rotational sweep" | 50 |
| 942 | 50 | mixed scheduled+generating | "boring routine" | 50 |
| 943 | 50 | mixed scheduled+generating | "fresh start" | 50 |
| 944 | 50 | mixed scheduled+generating | "schedule change" | 50 |
| 945 | 50 | mixed scheduled+generating | "new program" | 50 |
| 946 | 50 | mixed scheduled+generating | "rest week followup" | 50 |
| 947 | 50 | mixed scheduled+generating | "back from vacation" | 50 |
| 948 | 50 | mixed scheduled+generating | "fixing fatigue" | 50 |
| 949 | 50 | mixed scheduled+generating | "challenge mode" | 50 |
| 950 | 50 | mixed scheduled+generating | "deload reset" | 50 |
| 951 | 50 | mixed incomplete+today-completed | "rotational sweep" | 49 |
| 952 | 50 | mixed incomplete+today-completed | "boring routine" | 49 |
| 953 | 50 | mixed incomplete+today-completed | "fresh start" | 49 |
| 954 | 50 | mixed incomplete+today-completed | "schedule change" | 49 |
| 955 | 50 | mixed incomplete+today-completed | "new program" | 49 |
| 956 | 50 | mixed incomplete+today-completed | "rest week followup" | 49 |
| 957 | 50 | mixed incomplete+today-completed | "back from vacation" | 49 |
| 958 | 50 | mixed incomplete+today-completed | "fixing fatigue" | 49 |
| 959 | 50 | mixed incomplete+today-completed | "challenge mode" | 49 |
| 960 | 50 | mixed incomplete+today-completed | "deload reset" | 49 |
| 961 | 50 | scheduled with NULL gym_profile | "rotational sweep" | 50 |
| 962 | 50 | scheduled with NULL gym_profile | "boring routine" | 50 |
| 963 | 50 | scheduled with NULL gym_profile | "fresh start" | 50 |
| 964 | 50 | scheduled with NULL gym_profile | "schedule change" | 50 |
| 965 | 50 | scheduled with NULL gym_profile | "new program" | 50 |
| 966 | 50 | scheduled with NULL gym_profile | "rest week followup" | 50 |
| 967 | 50 | scheduled with NULL gym_profile | "back from vacation" | 50 |
| 968 | 50 | scheduled with NULL gym_profile | "fixing fatigue" | 50 |
| 969 | 50 | scheduled with NULL gym_profile | "challenge mode" | 50 |
| 970 | 50 | scheduled with NULL gym_profile | "deload reset" | 50 |
| 971 | 50 | scheduled + workout_changes child | "rotational sweep" | 50 |
| 972 | 50 | scheduled + workout_changes child | "boring routine" | 50 |
| 973 | 50 | scheduled + workout_changes child | "fresh start" | 50 |
| 974 | 50 | scheduled + workout_changes child | "schedule change" | 50 |
| 975 | 50 | scheduled + workout_changes child | "new program" | 50 |
| 976 | 50 | scheduled + workout_changes child | "rest week followup" | 50 |
| 977 | 50 | scheduled + workout_changes child | "back from vacation" | 50 |
| 978 | 50 | scheduled + workout_changes child | "fixing fatigue" | 50 |
| 979 | 50 | scheduled + workout_changes child | "challenge mode" | 50 |
| 980 | 50 | scheduled + workout_changes child | "deload reset" | 50 |
| 981 | 50 | scheduled 30+ days out | "rotational sweep" | 50 |
| 982 | 50 | scheduled 30+ days out | "boring routine" | 50 |
| 983 | 50 | scheduled 30+ days out | "fresh start" | 50 |
| 984 | 50 | scheduled 30+ days out | "schedule change" | 50 |
| 985 | 50 | scheduled 30+ days out | "new program" | 50 |
| 986 | 50 | scheduled 30+ days out | "rest week followup" | 50 |
| 987 | 50 | scheduled 30+ days out | "back from vacation" | 50 |
| 988 | 50 | scheduled 30+ days out | "fixing fatigue" | 50 |
| 989 | 50 | scheduled 30+ days out | "challenge mode" | 50 |
| 990 | 50 | scheduled 30+ days out | "deload reset" | 50 |
| 991 | 50 | all on today | "rotational sweep" | 50 |
| 992 | 50 | all on today | "boring routine" | 50 |
| 993 | 50 | all on today | "fresh start" | 50 |
| 994 | 50 | all on today | "schedule change" | 50 |
| 995 | 50 | all on today | "new program" | 50 |
| 996 | 50 | all on today | "rest week followup" | 50 |
| 997 | 50 | all on today | "back from vacation" | 50 |
| 998 | 50 | all on today | "fixing fatigue" | 50 |
| 999 | 50 | all on today | "challenge mode" | 50 |
| 1000 | 50 | all on today | "deload reset" | 50 |
## CSV columns

`idx, scenario_block, http_status, latency_ms, request_body_json, response_workouts_deleted, response_workouts_generated, response_message, response_success, pre_call_seeded_count, pre_call_seeded_dates, pre_call_seeded_statuses, post_call_remaining_future_workouts, post_call_user_activity_inserted (bool), expected_deleted, deleted_match (bool), error_message, raw_response_json`

## Implementation notes

- **Latency target**: 300–500ms per call. If any call exceeds 5s, flag it.
- **Pre-call seeding**: use `service_role` Supabase client to bulk-insert minimal workout rows directly. Do NOT use `/generate-stream` (too slow).
- **Cleanup between scenarios**: each scenario's seeding is responsible for its OWN setup. After each call, the harness queries `workouts WHERE user_id=... AND scheduled_date >= today AND is_completed=false` to record `post_call_remaining_future_workouts`.
- **Verification**: `expected_deleted` derived from seeded count + status filter logic; `deleted_match` is true when `response_workouts_deleted == expected_deleted`.
- **Auth**: `Authorization: Bearer $QA_JWT` (except Block 4 which deliberately tests auth failures).
- **Pacing**: 1 second between calls — endpoint is fast enough that we're not bound by gen latency, only by sequential setup.
- **Total time estimate**: ~10–15 minutes for all 200 calls including pre-call seed inserts (most calls under 1s; some scale-stress calls in Block 13 may run 5–10s each).
