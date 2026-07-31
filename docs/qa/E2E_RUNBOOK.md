# Zealova — E2E test runbook

How to run a full end-to-end pass against the **shipping iOS build on a simulator**, with every
claim corroborated against **Render logs** and **production Supabase**.

Written after the 2026-07-28/30 run, which produced `E2E_ISSUES_2026-07-28.md` (147 rows). Most of
this document exists because something went wrong the first time — the failure modes are called out
so you don't repeat them.

---

## 0. The one rule that matters

**A screenshot is never sufficient evidence.** Neither is a green API response.

The most valuable findings of the last run came from *disagreement between layers*: the screen said
one thing, the database said another. The worst findings — four of them, later retracted — came from
trusting a screen alone.

So for every claim, ask: **what does the DB say, and what does Render say?** Examples from the run:

- An endless "Generating your workout…" looked like a frontend spinner bug. One SQL query showed a
  healthy workout existed under a *different* `gym_profile_id` than the active one.
- A "Save button does nothing" looked like a dead button. Render showed
  `record "new" has no field "workout_id"` (42703) — a trigger 500ing on every tap, swallowed by the client.
- `POST /scores/readiness` returns **500** while the row **commits successfully**. Screen and DB
  disagree completely; only checking both reveals it.

---

## 1. Prime directive — evidence discipline

The first pass logged **four false findings**, every one caused by simulator geometry drift making
taps land somewhere else. "The control did nothing" is the most dangerous claim you can make.

**To report any control as broken you need all three:**

1. **A control tap** — tap a neighbouring element and show that it *does* respond. Proves taps land in that region.
2. **Repetition** — 2+ attempts, geometry re-read each time.
3. **Backend corroboration** — SQL showing the row was/wasn't written, and/or a Render line showing
   the request arrived, never arrived, or 500'd.

Without all three the finding is **`NOT REPRO`**, never `OPEN`. A register full of false OPENs is
worse than a short honest one.

Also: **distinguish "this is broken" from "I can't test this here."** A simulator has no camera and
few share targets. Those are harness ceilings, not defects.

**Retractions are first-class results.** Four rows in the last run were labelled FIXED by a
code-reading pass and were still broken on screen (#15, #41, #47, #94); one CRIT I filed myself was
tester error (#128). Write the retraction into the row rather than deleting it.

---

## 2. Environment

### Pin the device — never use `booted`

Multiple simulators may be booted, and `booted` is ambiguous. Resolve once:

```bash
xcrun simctl list devices booted
xcrun simctl listapps <UDID> | grep com.zealova.app   # which one actually has the app
```

Then use that UDID for every `simctl` call, and match the Simulator window **by name**, not `window 1`.

### Build fresh — always

The last run tested a **day-old binary** for hours. 151 Dart files had changed underneath it.

```bash
cd mobile/flutter && flutter build ios --simulator --debug
rm -rf /tmp/RunnerInstall.app && cp -R build/ios/iphonesimulator/Runner.app /tmp/RunnerInstall.app
rm -rf /tmp/RunnerInstall.app/PlugIns        # .appex placeholder blocks install; extension not in E2E scope
xcrun simctl install <UDID> /tmp/RunnerInstall.app
xcrun simctl launch  <UDID> com.zealova.app
```

Verify freshness before trusting anything:

```bash
find mobile/flutter/lib -name "*.dart" -newer /tmp/RunnerInstall.app/Frameworks/App.framework/flutter_assets/kernel_blob.bin | grep -v l10n/generated | wc -l
```

Non-zero means your build is stale. Rebuild.

### Derive tap geometry — never hardcode it

Two things move: **the window drifts** (observed `(12,103)` → `(23,80)` mid-session) and **the device
can change** (`iPhone 17 Pro 1206×2622 / 402×926` → `iPhone 16e 1170×2532 / 390×896`). A hardcoded
scale silently mis-aims every tap.

```
scale  = screenshot_px_width / window_width_pt          # 3.0 on current devices
chrome = window_height_pt - screenshot_px_height / scale # ~52 pt title bar
screen_x = origin_x + px_x / scale
screen_y = origin_y + chrome + px_y / scale
```

Re-read window position **and** size **and** screenshot size on **every tap**. A working helper lives
in the session scratchpad as `t.sh` — copy it forward.

**Before testing anything: tap a tab-bar item and confirm it navigates.** If it doesn't, fix geometry
first. Every "broken control" found before that check is an artefact.

### Simulator quirks — do not log these as app bugs

- **The first tap after idle often misses.** Retry once.
- **`cliclick t:` drops characters on multi-char strings** — the field shows the full text while the
  app received only the first char. This was logged as a HIGH bug and had to be retracted. Use the clipboard:
  `printf 'text' | xcrun simctl pbcopy <UDID>` → `cliclick kd:cmd t:v ku:cmd` → tap **Allow Paste**.
  To genuinely test typing, type one character per second.
- **Sheets cover the tab bar**; pushed routes (Library, program detail) have **no** tab bar — go Back first.
- **Re-measure a button from a FRESH screenshot immediately before tapping**, especially inside
  draggable sheets whose footer moves as content loads. One agent burned most of a run on stale pixel reads.
- **No camera** (barcode/photo capture) and **few share targets**. Add fixtures instead:
  `xcrun simctl addmedia <UDID> <file>` — e.g. `backend/tests/fixtures/test_food.jpg`, or generate an
  EAN-13 barcode PNG.
- If taps stop landing everywhere: check the app's CPU and
  `xcrun simctl spawn <UDID> log show --last 45s --style compact | grep "flutter:"`. A busy render loop
  looks identical to "app is broken". Relaunch to clear.

---

## 3. Render + Supabase — mandatory, not optional

**Infra:** Render service `srv-d4o6oker433s73d8pu0g` · Supabase project `hpbzfahijszqmgsybuor`
(use `mcp__plugin_supabase_supabase__execute_sql`).

**Before** each flow, start an error tail; **after** each flow, check it:

```bash
render logs --resources srv-d4o6oker433s73d8pu0g --limit 50 --level error -o json --confirm
```

App-side logs are equally valuable:

```bash
xcrun simctl spawn <UDID> log show --last 60s --style compact | grep "flutter:"
```

**When the screen and the data disagree, the data wins — and that disagreement is the finding.**

### Schema traps that will waste your time

Column names are not what you'd guess. **Query `information_schema.columns` rather than guessing twice.**

| Table | Gotcha |
|---|---|
| `food_logs` | `total_calories`, not `calories` |
| `performance_logs` | `reps_completed` / `weight_kg`, not `reps` / `weight` |
| `programs` | `program_name`, not `name` |
| `exercise_library` | `exercise_name` |
| `exercise_demos` | `original_exercise_name` |
| `program_variants` | links via `base_program_id`, not `program_id` |
| `saved_workouts` | has `updated_at`, no `created_at` |
| chat | `chat_history` (`user_message`/`ai_response`) — there is **no** `chat_messages` table |

Other traps:

- **`workouts.scheduled_date` is a timestamptz stored at NOON local** (e.g. `17:00+00` = noon CDT).
  A bare-date `.eq` matches nothing — window it: `>= dayT00:00+00` and `< nextDayT00:00+00`.
- **`/today` is gym-profile aware.** Always read `gym_profile_id` on any workout row you reason about.
- **Local vs UTC:** the test account is `America/Chicago`. An evening log lands on the *next* UTC date —
  correct, not a bug. Bucket by local date before calling anything mis-dated.
- `public.users` vs `auth.users` — an unqualified `users` query can hit the wrong one.

---

## 4. Run the invariant gates

Cheap and high-signal. Run **all** of them and report pass/fail with counts.

```bash
python backend/scripts/audit_supabase_column_drift.py --check
python backend/scripts/audit_maybe_single_guards.py --check
cd backend && .venv/bin/python scripts/audit_timezone_usage.py --check          # baseline-diff: NEW findings only
cd backend && set -a && source ./.env && set +a && .venv/bin/python scripts/audit_exercise_media_urls.py --check
python scripts/audit_exercise_instructions.py --check                            # baseline: 6 templated
cd backend && set -a && source ./.env && set +a && .venv/bin/python scripts/audit_program_copy_clarity.py --check
cd mobile/flutter && dart run lib/core/theme/accent_source_gate.dart --check
python backend/scripts/audit_beginner_program_exercise_difficulty.py --check
python backend/scripts/audit_injury_guard_terminal.py --check
python backend/scripts/audit_trigger_function_columns.py --check
python backend/scripts/audit_route_shadowing.py --check
```

Enumerate `backend/scripts/audit_*.py` yourself — don't rely on this list being current.

**Reading the results:**
- For each phantom-column finding, establish whether it sits on a **mounted, reachable route**. That
  distinction is what separated a real bug from noise last run.
- `audit_program_exercise_name_consistency.py` reports ~11k findings but **has no pass/fail logic** —
  it's a dry-run report and they all resolve via alias. Don't mistake the count for a failure.
- `audit_exercise_media_urls` **cannot** catch a name that resolves to no row at all — it only
  HEAD-checks paths that *are* referenced. It passes while 20,332 exercise slots show placeholders.
- The local `.venv` is python3.9 and app code needs 3.10+. If a gate can't import, **say so** rather
  than reporting a false pass.

---

## 5. What to test

Coverage first, depth second. Don't sink the whole run into one screen.

1. **Home** — hero/today card, coach card, streak, health banner. Does the state match the DB?
2. **Workout tab** — today's workout, date strip, **Start a curated program** (browse → preview →
   schedule → START). Verify: `user_program_assignments` row created, dated `workouts` expanded
   (noon-anchored), schedule shows the daily sessions.
3. **Active workout** — start, log real sets (weight + reps), rest timer, instructions/video/notes,
   **finish**, then the summary and **Share**. Verify sets in `performance_logs`
   (`reps_completed` must match what you entered) and the session in `workout_logs`.
4. **Easy/Advanced toggle** — does it switch, preserve position, and **persist**
   (`users.workout_ui_mode`)?
5. **Add / swap workout / swap exercise** — with an injured account, the backend returns
   **HTTP 409 `EXERCISE_UNSAFE_FOR_INJURY`**. Check how the UI presents it.
6. **Quick Generate** and **Regenerate** ("Make it different").
7. **Nutrition** — text log, photo scan, menu scan, barcode, voice, Describe/Snap; then **edit** a
   logged meal (quantity + remove) and confirm totals recompute and persist.
8. **Coach** — send a message, have it build a workout, then try to **keep** it (Start / Save /
   Schedule) and verify with SQL that something actually persists.
9. **Injury safety** — on an account with a real injury, assert returned exercises against
   `exercise_safety_index` (`knee_safe` etc.). **Prefer the API over taps here** — it's cheaper and
   far stronger evidence than a screenshot.
10. **Library / Programs / You / Settings** — fast pass for anything visibly broken.

---

## 6. Look at the screens

The automated checks verify that things *work*. They walk straight past things that are only visible
by looking. In the last run the user found the old sign-in logo, a truncated gym name, a sticky toast
on the wrong tab, and a missing exercise image — none of which any gate or API test would ever catch.

While walking each flow, watch for:

- **Missing images** — a grey placeholder where an illustration belongs (a program exercise whose
  authored name resolves to no library row).
- **Placeholder / debug copy** — the Quick Generate sheet shipped literal `Title` / `Subtitle`.
- **Flutter overflow banners** — the red/black "BOTTOM OVERFLOWED BY N PIXELS" stripe is a real layout bug.
- **Clipped or truncated text** — labels cut mid-word; identifiers truncated to "COMMER…".
- **Accent inconsistency** — orange app chrome beside cyan/purple/neon controls on the same screen.
- **Floating layers covering content** — FABs and avatars sitting on top of the first list row.
- **Numbers that contradict each other on one screen** — "1 ITEM" beside "3 ITEMS"; a card claiming
  0 g protein when 601 g is logged; a headline about steps above a protein chart.
- **Impossible states** — "SET 3 OF 2".
- **Unlabeled values** — a glowing "8" with no unit or scale.

---

## 7. Output

Append to `docs/qa/E2E_ISSUES_<YYYY-MM-DD>.md`, or create it if absent. **One master table** — not
several per-area tables.

```markdown
| # | Sev | Area | Issue | Evidence / root cause | Status |
```

- **Severity:** `CRIT` corrupts data or blocks the core loop · `HIGH` a headline feature silently does
  nothing, or the app looks broken/untrustworthy · `MED` wrong/misleading but recoverable · `LOW` polish.
- **The evidence column carries the proof**: the SQL result, the log line, the tap coords and
  changed-height, before/after numbers. A row a reader can't check isn't finished.
- **Root-cause it** where you can — file, function, line. "Button doesn't work" is a symptom; "a trigger
  references `NEW.workout_id`, which doesn't exist, so the insert 500s" is a finding.
- **Log passes too.** "Program Start completes end to end, 56/56 workouts expanded" is worth as much
  as a bug.
- **Cite the real commit.** A bulk pass once stamped 53 rows with two unrelated hashes; verify with
  `git log -1 <sha>` before writing one down.
- **Record what you did NOT test** in a coverage section. A 147-row register reads like full coverage
  and isn't.
- **Do not commit the register** unless asked — it's reviewed first.

---

## 8. Parallelism

**Taps cannot be parallelised.** One simulator, one cursor: two agents tapping simultaneously destroy
each other's runs and manufacture exactly the false findings this document exists to prevent.
Booting a second simulator does not help — the cursor is global.

What works:

- **One serial UI lane.**
- **Parallel non-UI work alongside it** — gate sweeps, API smokes, SQL measurement, code audits. This
  is where fan-out pays.
- Have agents **report in-thread, not to a file** — the harness blocks subagent file writes, and three
  agents lost completed work that way.
- **Spot-check agent claims before merging.** Two were materially wrong: a "function is never defined
  anywhere" that was actually defined in a sibling module (turning a rewrite into a one-line import),
  and four code-verified FIXED rows that were still broken on screen.

---

## 9. Cleanup

Restore anything you mutate: injuries, gym profile, targets. Delete test rows you create
(`food_logs`, `saved_workouts`, readiness check-ins). Prefer far-future dates for test writes so you
don't collide with another agent working the near-term calendar on the same account.

Test accounts are in the register header. **Do not delete them** — they're reused across runs.
