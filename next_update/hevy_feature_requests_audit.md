# Zealova — Hevy / Fitbod / Gravl Community Feedback Audit

**Source:** Five community threads pasted in-session on 2026-07-05 — an Android Play Store review + iOS comments about drag-reorder past the screen edge (Fitbod/Gravl comparison); a Hevy Head-of-Product "what we shipped" update post; two Hevy Reddit comment threads on that post; and a Hevy in-app A/B test post for a notes-system prototype.

**Verified:** 2026-07-05 against actual Zealova code by 4 parallel codebase-verification agents (Flutter `mobile/flutter/lib/` + `backend/`), synthesized into an artifact, then reviewed live.

**Tag legend** (same scheme as `gravl_feature_requests_audit.md` / `amy_feature_requests_audit.md`):
- **✅ SHIPS** (don't rebuild — cite file) · **🟡 PARTIAL** (have half) · **🔴 GAP** (true opportunity) · **⚪ N/A** (deliberate non-goal) · **⭐ WE WIN** (we beat the competitor here)

**Headline finding:** of ~25 distinct asks traced, **15 already ship, 8 are half-built, and only 2 are genuine gaps.** One additional ask (native Garmin/Zepp/Coros/Apple Watch companion apps) was reviewed and explicitly marked a non-goal, not a gap — HealthKit/Health Connect passthrough plus direct BLE heart-rate pairing is the intended integration ceiling here.

---

## Effort ranking — the 10 open items, easiest to hardest

Sized by how much of the hard part is already built. **S** = existing infra covers most of it, mainly a field/toggle/UI addition · **M** = new model + endpoint + UI, self-contained · **L** = touches a generation/scheduling pipeline, real regression risk.

| # | Effort | Item | Why it's this size |
|---|---|---|---|
| 1 | **S** | Routine-level notes | `program_template_builder_screen.dart` already has a `description` field pattern to copy — add a `notes` column + a text field, no new architecture. |
| 2 | **S** | Custom-exercise sharing toggle | Backend `is_public` + RLS already exist (`202_custom_exercises.sql`, `custom_exercises.py`). Just wire an `isPublic` checkbox into the create/edit sheet and pass it on save. (A full public-browse screen is a fast-follow, not required to ship the toggle.) |
| 3 | **S** | Calendar colored by workout split | `synced_workout_kinds.dart` already defines a `KindPalette` per workout type — recolor heatmap cells by that palette (or add a view toggle) instead of building a new color system. |
| 4 | **M** | Session/"temporary" notes that clear after one use | Reuses the existing rich notes storage (`performance_logs.notes[]`) — only need a "show once" flag plus a consume-on-view step. No new note infrastructure, but the auto-clear state machine needs care. |
| 5 | **M** | Per-side dumbbell weight logging | `isUnilateral` flag and UI labels already exist (`exercise.dart:137-138`) — needs an explicit log-time toggle plus doubling math threaded through volume analytics. |
| 6 | **M** | Persistent per-exercise notes (any library move) | Conceptually the same shape as `custom_notes` on `CustomExercise`, just keyed by `(user_id, exercise_id)` for standard library exercises instead of only custom ones — new table + simple CRUD + a UI entry point. |
| 7 | **M** | Private vs. shared per-note visibility | Needs a visibility flag per note plus a check in the social feed's rendering path — self-contained, but touches two surfaces (workout notes + activity feed) instead of one. |
| 8 | **M/L** | Programs that actually end/cycle | Needs a default `durationWeeks` (kill the silent `'Flexible'` fallback) plus a "your program is ending — refresh?" prompt wired into generation. Touches the shared program-generation path, so worth a regression pass across curated + AI-generated programs. |
| 9 | **L** | Day-reorder inside a recurring program | The most-repeated ask, but also the most involved: a drag-reorder UI over `ProgramDay.dayIndex`, backend logic to reassign indices, and regeneration of already-scheduled future workout instances — without touching workouts a user has already completed. |
| 10 | **Blocked** | Full granular Health Connect/HealthKit export | `writeWorkoutSession()` is already at the ceiling the `health` plugin and platform workout schema support — this isn't a "we haven't built it yet" gap, it's a platform API limitation Hevy's own team names too. Not a quick win regardless of effort spent. |

**Right now, in order:** #1 → #2 → #3 are same-day, low-risk wins. #4 and #6 are natural next steps since they build on notes infra you already have. Save #9 (day-reorder) for when you can dedicate real focus — it's the highest-value ask on the whole list, but it's not a quick one.

---

## 🔴 GAP — the 2 real gaps

| Ask | Where it came from | Detail |
|---|---|---|
| **Reorder days inside a recurring program** (move "Upper 1" from Tuesday to Monday) | Hevy PM post + top Reddit comment (25 votes, "skip workout to get to Lower 1 on Monday, skip through to Upper 1 Tuesday") + a second commenter agreeing | Can toggle which weekdays a program occupies (`program_manage_sheet.dart:65-131`) and drag one already-generated instance to a new date (`schedule_screen.dart:1005-1275`) — but can't resequence which *named session* sits on which weekday inside the repeating template. `ProgramDay.dayIndex` (`program_template.dart:378-448`) is sequential with no drag-reorder over it. **Most-repeated ask across two separate threads — act on this first.** |
| **Session/"temporary" notes that show once, then auto-clear** | Hevy's notes-prototype post | Every note type found (custom-exercise notes, template notes, set notes) is either permanent or an ever-growing list. Nothing stages a note for exactly the next occurrence of a workout and then clears. The harder pieces (rich, persistent, multi-note storage with audio/photo) are already built — this is the one state machine missing on top of that. |

---

## 🟡 PARTIAL — 8 half-built

| Ask | Detail |
|---|---|
| **Programs that end/cycle instead of running forever** | Curated programs have real week counts, deload cadence (`deloadEveryNWeeks`, default 5), and progression strategy (`program_template.dart:465-620`) — but `program.dart:77` falls back to open-ended `'Flexible'` when no week count is set, so some programs never prompt the "time to switch it up" moment several Hevy commenters asked for independently. |
| **Share a custom exercise with another user** | Backend already has `is_public` + correct row-level security (`backend/migrations/202_custom_exercises.sql`, `backend/api/v1/custom_exercises.py`). The Flutter `CustomExercise` model and create/edit sheet expose **no toggle and no public-browse screen** — a client-only gap, not a schema one. |
| **Per-side dumbbell weight logging** ("5kg per side" vs. combined) | `isUnilateral`/`isSingleSide` flag exists with "PER DB" / "PER ARM" UI labels (`exercise.dart:137-138,363`), but there's no logging-time toggle to declare combined-vs-per-side, and no doubling math found in volume analytics. |
| **Calendar/history colored by workout split** (legs=red, push=yellow…) | The activity heatmap (`activity_heatmap.dart:534-575`) colors cells by training-volume intensity on a blue ramp, not by categorical split/type. |
| **Full workout detail synced to Health Connect** (sets/reps/weight, not just calories) | `health_service.dart:1026-1055` `writeWorkoutSession()` only pushes activity type, duration, and total calories. Same ceiling Hevy's own team names as a platform limitation, not a choice they're avoiding. |
| **A note that follows an exercise everywhere it appears** (e.g. "pin-loaded machine, seat height 4" on any library move) | Only custom user-created exercises carry a `custom_notes` field, and it's a static description set once at creation — not something edited mid-workout that then sticks to every future appearance of a standard exercise like Bench Press. |
| **Routine-level notes** | User-built routines only have a generic `description` field. A true `notes` column exists — just on imported creator templates (`workout_program_templates`) and `saved_workouts`, not on routines people build themselves in `program_template_builder_screen.dart`. |
| **Private vs. shared notes** | Visibility is set per whole activity post (`public\|friends\|family\|private` on `activity_feed`), not per individual note — no way to keep one note private while sharing the rest of a workout. |

---

## ⚪ N/A — deliberate non-goal

| Ask | Why it's not a gap |
|---|---|
| **Native Garmin / Zepp / Coros / Apple Watch companion app** | Reachable only indirectly through HealthKit/Health Connect passthrough, plus direct BLE heart-rate-strap pairing (`ble_heart_rate_section.dart` — explicitly supports Polar, Wahoo, Garmin broadcast mode, Amazfit, Galaxy Watch). Reviewed 2026-07-05 and decided passthrough is the intended ceiling, not worth a dedicated watch app. |

---

## ✅ SHIPS — 15 already built (several ⭐ ahead of the competitor)

- **Exercise swap, per-session or permanent, with progressive-overload continuity** — `workout_repository_exercises.dart:331-372` (`swapExercise(applyToFuture)`), sheet toggle "Apply to future workouts — keep your progress." ⭐ Hevy is still beta-rolling this exact feature; here, every history/1RM lookup is keyed by canonical `exercise_id` (`progressive_overload_service.py:37-92`), so a swap can't sever the trend line — the systemic fix for what a Hevy user described losing.
- **Full-week program view** — `program_detail_screen.dart:946-967` week-selector chips + `schedule_screen.dart` agenda/week/timeline modes.
- **Personalized, per-exercise rest timers** — `exercise.dart:99-100`, editable in both builders, live ±15s mid-set nudge (`workout_timer_controller.dart:143`).
- **Injury management** — ⭐ already gates program generation via an injury-directive system; Hevy lists this as "coming."
- **Autoscroll while dragging an exercise to reorder** — `workout_plan_drawer.dart:157-207` runs on stock `ReorderableListView` without disabling scroll physics, so the Fitbod/Gravl "can't drag past the screen edge" complaint doesn't reproduce here (worth one on-device confirmation, not code-blocked).
- **Ultrasets (3+ exercise groups, not just 2-exercise supersets)** — `exercise_navigation_mixin_ui.dart:220-320`, group size uncapped.
- **Direct Bluetooth HR strap pairing** — independent of HealthKit, names Polar/Wahoo/Garmin/Amazfit/Galaxy Watch.
- **Claude/ChatGPT MCP data connector** — full OAuth + personal-access-token server (`backend/mcp/`), user-facing config generator, gated behind yearly plan.
- **Gym tagging** — `Workout.gymProfileId`, full multi-gym profile system.
- **Stretching/mobility/yoga as a distinct colored type with a hold timer** — separate `KindPalette`, `stretchHoldSeconds` timer strategy.
- **Linear vs. double progression** — `progressionStrategy` enum: `linear | wave | double | none`.
- **Import reliability from Strong/other apps** — per-row fallback on batch failure, logged not silently dropped, remap-with-undo UI. ⭐ More robust than the exact stuck-import bug a Hevy user has had open for over a week.
- **No battery-drain anomaly found** — Wakelock paired correctly on enter/exit; no GPS/Bluetooth left scanning; the one geofencing feature (gym auto-switch) is opt-in and debounced.
- **Set-level notes (text/voice/photo, multiple per set)** — `performance_logs` (`notes[]`, `notes_audio_url`, `notes_photo_urls`), referenced by the AI workout recap. ⭐ More advanced than Hevy's own notes prototype.
- **Notes surfaced in the post-workout summary** — dedicated notes-viewer sheet in `summary_exercise_table.dart:601-759`.

---

## Not audited this pass

Strava sync · cardio-recommended-before/after-lifting logic · EMOM/interval tagging as a distinct set type · in-app direct messaging · meso-cycle-length stats · a program built around an external running plan · exercise-library breadth (e.g. lateral-movement coverage). Flag any of these if you want them checked next.

---

## If you act on two of these

1. **Day-reorder inside a program template** — the single most-repeated ask across two threads, confirmed absent in code, not just under-discovered.
2. **Session notes that clear after one use** — Hevy is prototyping this right now and hasn't shipped it; the hard infrastructure already exists here, only the "show once, then clear" state is missing.
