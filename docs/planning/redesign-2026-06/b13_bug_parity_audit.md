# B13 — Bug-Parity Sweep vs Gravl's Fix List

**Date:** 2026-06-03
**Scope:** Audit Zealova's equivalents of the three bugs Gravl shipped fixes for
— (a) timezone date-shift in feed/calendar/weekly summaries, (b) background
rest-timer continuation, (c) logging responsiveness. Prioritize correctness over
breadth: each finding cites `file:line` and states whether it reproduces, plus
an exact fix (applied if in an owned file, INTEGRATION NEEDED otherwise).

Owned files for this workstream: `workout_generation_orchestrator.dart`,
non-generated offline service/sync files under `lib/data/local/`. The three
bug surfaces below all live OUTSIDE those owned files, so the fixes are
INTEGRATION NEEDED snippets — except where the audit verdict is "does not
reproduce / already correct".

---

## (a) Timezone date-shift — feed / calendar / weekly summaries

### Verdict: LARGELY MITIGATED on the read/display path; one real WRITE-side date-shift found.

The codebase already has centralized timezone discipline:

- `lib/utils/tz.dart` — `Tz.timestamp()` (always UTC for `*_at` fields) vs
  `Tz.localDate()` (user-local `YYYY-MM-DD` for "what day?" query params). It even
  logs a debug warning when local and UTC dates differ.
- Timeline pagination computes anchors from date-only strings, which Dart
  parses as LOCAL midnight, and re-serializes via `toIso8601String().substring(0,10)`
  (stays local for a non-UTC DateTime). See
  `lib/data/providers/timeline_provider.dart:329-332` and the local-components
  `_ymd` helper at `:391-394`. **Correct — no shift.**
- Weekly boundaries use `DateTime.now()` (local) and local `weekday`, not UTC:
  - `lib/services/weekly_volume_tracker.dart:58-77` (ISO week from local now).
  - `lib/data/providers/weekly_recap_provider.dart:10-31` (`isoWeekKey` /
    `isPastMondayMorning` both local). **Correct — no shift.**
- The home hero carousel explicitly notes and avoids the date-only-string
  timezone-shift trap: `lib/screens/home/widgets/hero_workout_carousel.dart:232`.

So the classic "feed/calendar/weekly summary shows the wrong day" read-path bug
that Gravl fixed does **not** reproduce here — the team already hardened it.

### Residual WRITE-side date-shift (REPRODUCES) — Health Connect import

**File:line:** `lib/data/providers/health_import_provider.dart:172` (and the
identical pattern at `:312`).

```dart
'scheduled_date': pending.startTime.toUtc().toIso8601String(),
```

**Repro:** Import a Health Connect / Apple Health workout performed at, e.g.,
22:00 on June 2 in CDT (UTC-5). `startTime.toUtc()` → `2026-06-03T03:00:00Z`.
If the backend buckets `scheduled_date` by the leading date portion (it stores a
`YYYY-MM-DD`-style scheduled date), the workout is filed on **June 3**, not the
June 2 the user actually trained. Every imported evening workout west of UTC
shifts forward a day on the calendar/history. This is exactly the Gravl
"timezone date-shift" class, on the write side.

**INTEGRATION NEEDED** (file not owned — `health_import_provider.dart`):
Send the LOCAL calendar date for `scheduled_date` (a "what day" field), while
keeping any true instant in a separate UTC `*_at` field. Add `import '../../utils/tz.dart';`
then change both sites:

```dart
// BEFORE
'scheduled_date': pending.startTime.toUtc().toIso8601String(),
// AFTER — local calendar day the workout actually happened on
'scheduled_date': Tz.localDate(pending.startTime),
```

Apply the same edit at `health_import_provider.dart:312`
(`enriched.startTime.toUtc().toIso8601String()` → `Tz.localDate(enriched.startTime)`).

### Minor WRITE-side note (LOW severity) — challenge end date

**File:line:** `lib/screens/social/challenge_create_sheet.dart:81` —
`'end_date': _endDate.toUtc().toIso8601String()`. A challenge whose end date is
picked as a calendar day can roll to the next/prev UTC day for users far from
UTC. If the backend treats `end_date` as a calendar day, prefer
`Tz.localDate(_endDate)`. Lower impact than the import path (user picks the date
explicitly; off-by-one is visible at creation), so flagged but not prioritized.
**INTEGRATION NEEDED** if backend buckets `end_date` by day.

---

## (b) Background rest-timer

### Verdict: REPRODUCES — in-app rest countdown desyncs after backgrounding (no wall-clock reconcile on resume).

**Files:line:**
- `lib/screens/workout/controllers/workout_timer_controller.dart:94-117`
  (`startRestTimer`) — the rest countdown is a `Timer.periodic(1s)` that
  decrements `_restSecondsRemaining`. The OS suspends/throttles Dart timers
  while the app is backgrounded (hard on iOS, throttled on Android), so the
  decrement stops.
- The controller DOES record a wall-clock end time: `_restEndsAt` at
  `:97` (and keeps it in sync on adjust at `:149`). So the data needed to
  reconcile exists.
- `lib/screens/workout/active_workout_screen_refactored.dart:1180-1185`
  (`didChangeAppLifecycleState` → `resumed`) clears the ongoing notification but
  **does NOT reconcile** `_restSecondsRemaining` against `_restEndsAt`.
- `lib/screens/workout/mixins/timer_rest_mixin.dart` has no resume hook either.

**Repro:** Start a set, begin a 90s rest, background the app for 60s, return.
On iOS the on-screen rest timer shows roughly the value it was frozen at when
backgrounded (≈90s, not ≈30s), and `onRestComplete` fires ~60s too late (or, if
the rest would have hit zero in the background, it doesn't auto-advance until you
return and the timer is already negative-overdue). The Live Activity / Dynamic
Island renders correctly because it uses the native wall-clock `restEndsAt`
(`workout_flow_mixin.dart:1018`) — so the lock screen and the in-app timer
visibly disagree. That cross-surface disagreement is precisely the Gravl
"background rest-timer" complaint.

**Note on framing:** Gravl's phrasing was the timer "continuing when
backgrounded". Our concrete defect is the inverse-but-equivalent correctness
bug: the timer FREEZES in the background and is not caught up on resume. Either
way the fix is the same — make the timer authoritative on `restEndsAt`
(wall-clock) and reconcile on resume.

**INTEGRATION NEEDED** (files not owned —
`workout_timer_controller.dart` + `active_workout_screen_refactored.dart`):

1. Add a reconcile method to `WorkoutTimerController` (insert after
   `adjustRestTime`, ~`:152`):

```dart
/// Reconcile the rest countdown against wall-clock time. Call on app
/// resume — Dart timers freeze/throttle while backgrounded, so the tick
/// loop alone drifts. Recomputes _restSecondsRemaining from _restEndsAt
/// (the authoritative wall-clock end) and fires completion if the rest
/// already elapsed in the background.
void reconcileRestFromWallClock() {
  final endsAt = _restEndsAt;
  if (endsAt == null || _isPaused) return; // not resting, or paused (frozen by design)
  final remaining = endsAt.difference(DateTime.now()).inSeconds;
  if (remaining <= 0) {
    // Rest elapsed while backgrounded — complete now.
    _restSecondsRemaining = 0;
    _endRest();
  } else if (remaining != _restSecondsRemaining) {
    _restSecondsRemaining = remaining;
    onRestTick?.call(_restSecondsRemaining);
  }
}
```

   (Paused rests must NOT advance: `_applyPause` does not currently extend
   `_restEndsAt` by the paused duration, so the guard above intentionally skips
   reconciliation while paused. If pause-during-rest is a supported flow, also
   extend `_restEndsAt` by the accumulated pause delta inside `_applyPause` when
   `_restEndsAt != null`.)

2. Call it on resume in
   `active_workout_screen_refactored.dart:1180` (the `resumed` case), before
   `cancelWorkoutNotification()`:

```dart
case AppLifecycleState.resumed:
  _isAppBackgrounded = false;
  // B13(b): catch the rest timer up to wall-clock — it froze in the
  // background, so reconcile against restEndsAt (and auto-complete if the
  // rest already elapsed while we were away).
  _timerController.reconcileRestFromWallClock();
  cancelWorkoutNotification();
  break;
```

The main workout-elapsed timer is already wall-clock-safe (it back-dates
`_startedAt` and the Live Activity reads elapsed from it), so only the REST
countdown needs the resume reconcile.

---

## (c) Logging responsiveness

### Verdict: DOES NOT REPRODUCE — the log path is already fully optimistic / local-first; nothing on the UI thread awaits the network.

**Files:line:**
- `lib/screens/workout/mixins/set_logging_mixin.dart:184-203`
  (`finalizeSetWithRpe`) — appends the `SetLog` to in-memory `completedSets`,
  pushes to the crash-safe session checkpoint synchronously, and calls
  `setState` immediately. No `await` on a network call gates the UI update.
- `lib/screens/workout/mixins/set_logging_mixin.dart:608-738` — edit / delete /
  quick-complete all mutate local state + the in-memory checkpoint synchronously,
  then `setState`. No network in the hot path.
- Persistence to the server is deferred to the offline sync queue:
  `lib/data/repositories/offline_workout_repository.dart:187-247`
  (`logSetPerformance`) writes to the local Drift DB first, then `enqueue`s the
  POST — the API round-trip never blocks the tap.
- The only intentional pre-finalize block is the mandatory effort/RPE prompt
  sheet (`set_logging_mixin.dart:162`), which is product-required UX, not a
  performance stall.

So the "laggy logging" symptom Gravl fixed is not present: a logged set paints
instantly and survives an app kill via the debounced checkpoint, with server
sync happening in the background through the retry/backoff sync engine. No fix
required.

(Adjacent confirmation that the background write pipeline is robust:
`lib/data/services/sync_engine.dart:94-296` — priority-ordered queue,
exponential backoff with jitter, dead-letter after max retries, critical
entity types like `workout_log` get 50 retries.)

---

## Summary table

| Gravl bug | Our verdict | Evidence | Disposition |
|---|---|---|---|
| (a) TZ date-shift — read/display | Does NOT reproduce | `tz.dart`, `timeline_provider.dart:329-394`, `weekly_volume_tracker.dart:58-77`, `weekly_recap_provider.dart:10-31` | Already hardened |
| (a) TZ date-shift — Health import write | **REPRODUCES** | `health_import_provider.dart:172,312` | INTEGRATION NEEDED (use `Tz.localDate`) |
| (a) TZ date-shift — challenge end_date | Possible (low) | `challenge_create_sheet.dart:81` | INTEGRATION NEEDED if backend buckets by day |
| (b) Background rest-timer | **REPRODUCES** | `workout_timer_controller.dart:94-117` (no resume reconcile); `active_workout_screen_refactored.dart:1180-1185` | INTEGRATION NEEDED (`reconcileRestFromWallClock` + resume call) |
| (c) Logging responsiveness | Does NOT reproduce | `set_logging_mixin.dart:184-203`, `offline_workout_repository.dart:187-247`, `sync_engine.dart` | No fix needed |
</content>
</invoke>
