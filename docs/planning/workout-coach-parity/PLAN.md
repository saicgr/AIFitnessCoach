# Google Health Coach Parity — Workout Creation, Customization Studio & Chat Go-To Buttons

**Status:** Approved scope, awaiting "go" to execute.
**Date:** 2026-05-28
**Owner:** Claude / Zealova

---

## 0. Verification verdict (what already exists)

The core Google-Health loop is **already shipped**: chat → generate (`generate_quick_workout`) →
inline tappable result (`GoToWorkoutButton`, `chat_message_bubble.dart:392`) → `/workout/:id`
→ `WorkoutDetailScreen` (warm-up / main / cool-down, thumbnails, sets/reps) → "Let's Go" →
active session → completion + ratings.

Confirmed gaps we are closing:
- Save any generated workout to a personal library + rename (backend save is activity-keyed only; no frontend save/rename, no workouts library UI).
- Conversational + on-screen **adaptation** with a free-text/constraint input ("I have back pain", "make it easier").
- Quick "I've done this" mark-done on the detail screen (no live session).
- Thumbs up/down on a workout.
- A richer inline workout **card** (today it's a plain "Go to X" button).
- Inline **go-to buttons** for exercises, PRs/progress, hydration, weight, schedule.
- Recipe detail screen + "View Recipe" button.

**Known non-goal:** true "Repeat circuit N times" block (supersets cover pairing; a real
circuit-repeat primitive is a larger model change, not requested).

---

## 1. Performance principle — instant = RAG-select + deterministic rules, never a fresh LLM call

Every customization / adaptation control re-runs the existing fast path:
`exercise_rag_service.select_exercises_for_workout()` (ChromaDB vector lookup) +
`adaptive_workout_service` deterministic params (sets/reps/rest) + library metadata filters
(`avoid_if` / `suitable_for` for pain & impact). Sub-second, live-preview while dragging a slider.

The LLM is used **only in chat** to parse free text into structured params
("knees hurt, keep it short" → `avoid=[knees], impact=low, duration=10`). The rebuild itself is
RAG + rules. (Matches `feedback_prefer_local_algo_over_rag`.)

---

## 2. Shared engine (built first — everything calls it)

**`backend/services/` — `build_adapted_workout(...)`** extracted from `generate_quick_workout`
(`workout_tools.py:603`). Params:
- target muscles / focus area(s)
- equipment (available-today)
- intensity / fitness ceiling
- duration → exercise count
- training style (strength / hypertrophy / endurance / circuit) → rep range + rest + structure
- avoid_exercises
- transient sore/pain body areas (session-only, NOT written to profile injuries)
- impact level (low / normal / high) → `avoid_if` / `suitable_for` filter
- warm-up minutes, cool-down minutes (scaled deterministic blocks)
- supersets on/off, AMRAP on/off
- prioritize staples

Returns a structured workout: scaled warm-up block + main + cool-down block, with per-exercise
media (image/video) enriched from `exercise_library_cleaned`.

Callers: chat tool, `/workouts/{id}/adapt`, `/workouts/customize`, preset apply, shuffle,
trim/extend, equipment bulk swap.

---

## 3. Workstreams (ship continuously — no per-workstream approval gate, per CLAUDE.md)

### W1 — Rich inline workout card + chat go-to buttons
**Backend** (agents emit `actionData`):
- workout/coach agent: `reference_exercise {exercise_id, name}` when it names a movement.
- coach agent: `reference_progress {kind: 'pr'|'progress', exercise_name?}` when referencing a PR/progress.
- hydration agent: `log_hydration` affordance; coach: `log_weight`; workout card: `schedule_workout`.
**Frontend**:
- Upgrade `GoToWorkoutButton` → **`WorkoutResultCard`** (`chat_media_widgets.dart`): title, duration,
  exercise count, thumbnail strip, + inline actions **Start · Adjust · Save** + thumbs (W6).
- New inline widgets: **"How to do X"** → `/exercise-detail`; **"View PRs / Progress"** →
  `/stats/personal-records` or `/progress/*`; **"Log water"** → `/hydration`; **"Log weight"** →
  `/measurements`; **"Schedule"** → schedule dialog (`scheduleWorkout()`).
- New `has*` getters on `chat_message.dart` for each actionData type; wire into `chat_message_bubble.dart`.

### W2 — Save to library + rename + Workouts tab
**Backend**: `POST /saved-workouts/from-workout {workout_id, name?}` (no activity_id;
`source_activity_id` already optional). Rename via existing `PUT /saved-workouts/{id}`.
**Frontend**:
- `saved_workouts_service.dart`: `saveFromWorkout()`, `updateSavedWorkout()` (rename).
- "Save to library" sheet on `workout_detail_screen` + on the chat card (prefilled `Copy of <name>`).
- New `screens/library/tabs/workouts_tab.dart`: custom-workouts grid; Do-now / Schedule / Rename / Delete.
- `library_screen.dart`: TabController 3→4, labels `['Discover','Exercises','Workouts','Saved']`.

### W3 — Customization Studio (instant, RAG-backed) — all 4 control groups
**Backend**: `POST /workouts/customize {params}` (builds fresh) wrapping `build_adapted_workout`.
Warm-up/cool-down scaling honors requested minutes. Impact/pain filter via library metadata.
**Frontend** — new **Customization Studio** sheet with live preview:
- Core: time / warm-up / cool-down / count sliders; intensity; target-muscle chips.
- Equipment & style: equipment-today multi-select; training-style; rest length; supersets / AMRAP toggles.
- Pain & joint: **body-map sore/pain selector** (reusable widget); impact level; per-exercise "this hurts" instant swap.
- Presets & staples: "Save as preset"; prioritize-staples toggle.

### W4 — Adapt / regenerate unification (chat + detail)
**Backend**: `POST /workouts/{id}/adapt {params|constraints_text, replace_in_place}` wrapping the core.
Chat adaptation creates a **new** workout (preserves original). LangGraph workout-agent prompt
extracts constraints from free text → core params.
**Frontend**: detail-screen **"Adjust workout"** button opens the Studio (in-place + one-tap Undo
via existing revert/backup pattern). Chat renders the new adapted `WorkoutResultCard`.

### W5 — Quick "I've done this"
**Backend**: ensure workout-complete endpoint accepts manual completion (planned set targets as
performed, `completion_method='manual'`); add if missing.
**Frontend**: `workout_detail_screen` "Mark as done" → logs completion without live session.

### W6 — Thumbs up/down
**Backend**: `workout_feedback` table + `POST /workouts/{id}/feedback {thumbs, reason?}`; biases
future generation / never-recommend.
**Frontend**: thumbs on the chat card + detail header; thumbs-down → opens the Studio.

### W7 — Extra one-tap features (reuse the core)
- **Shuffle / Surprise me**: core with same params + current exercises in avoid-list.
- **Time-budget trim/extend**: "only 10 min" → new duration→count, keep highest-priority exercises.
- **Equipment bulk swap**: "no barbell today" → core with that equipment excluded.
- **Active-recovery mode**: preset params (mobility/flexibility focus, low impact, light intensity).

### W8 — Recipe detail + "View Recipe" button (recipe choice = "1 and 3")
**Backend**: nutrition agent emits `reference_recipe {recipe payload or id}`. Recipe-detail fetch
endpoint if needed.
**Frontend**: new **recipe-detail screen** + route; inline **"View Recipe"** button → recipe detail;
secondary "Browse recipe ideas" → existing `/recipe-suggestions`.

---

## 4. New backend endpoints
- `POST /saved-workouts/from-workout`
- `POST /workouts/customize`
- `POST /workouts/{id}/adapt`
- `POST /workouts/{id}/feedback`
- (verify) manual-complete on workout-complete endpoint
- (W8) recipe-detail fetch if not present

## 5. New DB tables (migrations run directly via backend/.venv + .env DATABASE_URL)
- `workout_presets` (user_id, name, params jsonb, timestamps)
- `workout_feedback` (user_id, workout_id, thumbs, reason, created_at)
- `saved_workouts` already exists.

## 6. Verification (run before declaring done)
- `flutter analyze` clean on all touched files.
- Targeted curls for every new endpoint (no paid Gemini sweeps, per `feedback_validation_sweep_cost`).
- Manual trace: chat-adapt → new card · detail Adjust → in-place+undo · Studio slider → instant
  preview · sore body-map → safe substitutions · save → rename → appears in Workouts tab ·
  mark-done → logged · thumbs-down → Studio · How-to/PR/water/weight/schedule buttons → correct route ·
  View Recipe → recipe detail.

## 6b. Edge cases & decision trees

Format: **Trigger → Decision.** Pain/injury avoidance is a HARD constraint everywhere
(never relaxed). Pain→exercise-avoidance mapping is **deterministic** (body-part → movement
avoid-list, cited NSCA/NASM), never LLM (`feedback_no_llm_for_safety_classification`); the LLM only
parses "back pain" → `body_part='back'`.

### Shared engine / RAG
- **Over-constrained → 0 exercises** (e.g. no equipment + avoid legs/back/shoulders + low impact):
  progressively broaden in priority order — drop *variety* first, then *equipment-pref*, then *impact*,
  then *focus* — and tell the user what was relaxed. **Never** relax pain/injury. Never return empty,
  never 422 (`feedback_no_preflight_rejection_for_injury_focus`). If still empty → pivot to
  active-recovery/mobility.
- **Fewer than requested count** → fill with what fits, note "only N matched your constraints."
- **Pain conflicts with focus** (wants legs, legs are sore) → pain wins; offer low-impact alternative
  or different focus; surface the conflict in copy (variant pool, not robotic — `feedback_dynamic_copy_not_robotic`).
- **Transient sore areas MERGE with profile injuries** (both avoided); session sore areas are NEVER
  written to the profile.
- **warm-up + cool-down minutes ≥ total duration** → clamp proportionally; warn.
- **Staple conflicts with pain/equipment** → skip the staple, note it.
- **Duplicate exercise across warm-up/main/cool-down** → dedup.
- **Determinism:** same params → same result (seeded), so Studio preview == applied workout.
  Shuffle is the ONLY intentionally-random path. Weights stay in **lbs** (`feedback_weight_units`).
  Calorie/duration estimates recalculated on every adapt.

### Customization Studio (live preview)
- **Rapid slider drags** → debounce (~300ms) + cancel in-flight, apply only the latest; keep last good
  preview, subtle "updating" shimmer; Apply disabled until settled. Check `mounted` on async returns.
- **Preview must NOT persist a workout per change** → customize *preview* returns exercises in-memory
  (no `workouts` row); persist only on **Apply/Save**. Prevents orphaned-row DB bloat + preview≠apply drift.
- **Small device (SE) / tablet** → Studio sheet scrollable, `Wrap` not `Row`, body-map scales
  (`feedback_no_overflow_adaptive_screens`).
- New card + Studio respect **AccentColorScope** (today `GoToWorkoutButton` hardcodes cyan/purple — fix).

### Adapt / regenerate (chat + detail)
- **"I have back pain" with no workout in context** → generate a NEW back-safe workout (don't adapt nothing).
- **Adapt references a stale/deleted workout_id** → regenerate fresh.
- **Chat adapt preserves the original** (forks a new workout); detail "Adjust" is in-place + Undo.
- **Adapting a COMPLETED or logged workout** → fork a new one, never mutate history.
- **Adapting today's planned/scheduled workout** → keep the same date; if it would alter plan
  progression, fork into an "extra today" workout (`extra_today_workouts`) rather than overwrite the plan.
- **Conflicting free-text** ("harder but I'm injured") → injury caps difficulty; explain.
- **Unmappable free-text** ("make it better", "my left pinky hurts") → ask one clarifying follow-up
  rather than guess; best-effort body-part map, note what we couldn't target.
- **Undo** must restore the FULL prior state (exercises + the user's manual set/weight edits), so flush
  any pending debounced autosave into the snapshot before adapting. Single-level undo (last good).

### Save to library + rename + Workouts tab
- **SCHEMA GAP:** `saved_workouts.ExerciseTemplate` is reps-only (`reps: int ge=1`). Saving a
  timed/hold/AMRAP/superset/set-targets workout would be **lossy** (planks have no reps; supersets/RIR
  dropped). → **Extend `ExerciseTemplate`** to carry `duration_seconds`, `hold_seconds`, `set_targets`,
  `superset_group/order`, drop-set fields before W2 ships.
- **Save same workout twice** → allow copies (Google does "Copy of X"); auto-suffix on name collision,
  no forced uniqueness (from-workout has no `source_activity_id`, so the unique constraint won't fire).
- **Rename** empty/whitespace-only → reject; trim; clamp 200 chars (model max).
- **Saved copy is a snapshot** → independent of source deletion. Missing library media → fallback icon.
- **Do-now from a saved template** → instantiate a real `workouts` row from the template.
- **Empty Workouts tab** → helpful empty state; paginate large lists.
- **Save/schedule offline** → surface error, never silent loss (`feedback_no_silent_fallbacks`).

### Quick "I've done this"
- **Already completed** → idempotent, disable the button.
- **Manual-done must NOT create PRs** (no performed weights → no fake PRs); but DOES count for
  streak/XP. `completion_method='manual'`.
- **Future-scheduled workout** → log against its scheduled date; allow today/past, block far-future.
- **Mark-done on an unsaved generated workout** → persist first.
- **Start after marking done** → prompt "already logged — log again?".

### Thumbs feedback
- **Toggle / double-tap** → idempotent up↔down↔none.
- **Thumbs-down → Studio**, but record the thumbs-down immediately (Studio is optional follow-up).
- **Thumbs is a SOFT signal**, distinct from per-exercise "never recommend" — one down-vote never
  globally bans an exercise.

### Go-to buttons (inline)
- **"How to do X" where the exercise isn't in the library** (custom/typo/foreign-language name) →
  fuzzy-match to a library id; render the button ONLY if it resolves (no dead links). exercise-detail
  needs a `WorkoutExercise` → look up by name → construct; handle not-found.
- **Multiple exercises named in one message** → render up to N chips, one per resolved exercise.
- **"View PRs/Progress" with no data yet** → suppress the button (or empty-state the screen, no crash).
- **"Log water / weight"** → open the logger with a quick-add + undo; do NOT auto-log a guessed amount.
- **"Schedule" a one-off generated workout** → persist/save it first.
- **Buttons on OLD messages after the entity changed/deleted** → graceful "not found".
- **Malformed actionData (missing id)** → `has*` getter guards render-off (same pattern as
  `hasGeneratedWorkout`). All new labels localized (.arb); locale-aware exercise matching.

### Recipe detail + View Recipe
- **Suggestion is name-only / can't be re-fetched** → embed enough payload in `actionData` to render
  detail without a round-trip; else fall back to `/recipe-suggestions`.
- **Missing image/macros** → graceful render.

### Chat rendering / concurrency
- **Generation partially failed (0 exercises)** → don't render the card / show error (no empty workout).
- **Streaming race** → validate `workout_id` is persisted before the tap target renders.
- **Adapt in chat while same workout open on detail** → refresh detail on focus (stale-state guard).

## 7. Execution rules
- Work in a git worktree (background-job isolation).
- Multi-screen redesign touches ≥3 screens → file-level backup of `lib/` per CLAUDE.md before first edit.
- Ship all workstreams continuously in one run; no per-surface check-ins.
