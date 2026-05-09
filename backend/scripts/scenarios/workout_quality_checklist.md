# Workout Quality Checklist

Reusable rubric for grading any workout-generation output (`/generate-stream`,
`/regenerate-stream`, `/api/v1/workouts/quick`, local `QuickWorkoutEngine`).
Every check has a **scoring level** (`fail` / `warn` / `info`) and a
**grounding citation** to the existing backend constraint or research source.

> Use as: filter the rubric to whichever sections the harness column-set
> supports, run each row through, write `pass | warn | fail` per check, sum
> for an aggregate row score.

---

## A. Schema completeness

Every exercise object inside `exercises_json` must populate:

| Field | Required | Source-of-truth |
|---|---|---|
| `name` (non-empty, no whitespace-only) | ✅ | `services/gemini/utils.py:168-421` |
| `sets` (int, ≥1) | ✅ | `validation_utils.py:169-359` |
| `reps` (int OR `"8-12"` range string) | ✅ | strict validator |
| `rest_seconds` (int, ≥30) | ✅ | `ABSOLUTE_MIN_REST=30` |
| `muscle_group` (non-empty) | ✅ | exercise schema (user-flagged regression) |
| `equipment` (non-empty OR `"bodyweight"`) | ✅ | exercise schema |
| `set_targets[]` (non-empty array) | ✅ | strict validator |
| `weight_kg` (float, ≥0) | conditional | required when `equipment≠bodyweight` |
| `movement_pattern` | recommended | safety swap dependency |

**Workout-level mandatory:** `id, user_id, name, type, difficulty, exercises_json,
duration_minutes (1-480), version_number, is_current` (`models/schemas.py`).

**Score:** `fail` if any required field empty/null. `warn` if conditional missing.

---

## B. Parameter caps per fitness level

Cap source: `validation_utils.py:57-61, 102-128`.

| Level | max_sets | max_reps | min_rest_s |
|---|---|---|---|
| beginner | 3 | 12 | 60 |
| intermediate | 4 | 15 | 45 |
| advanced | 5 | 20 | 30 |
| hell | 6 | 20 | 30 |

**Age caps overlay (skipped under hell mode):**
- 18-29: max_reps=25, sets=6, rest=30s
- 30-44: 20 / 5 / 45s
- 45-59: 16 / 4 / 60s
- 60-74: 12 / 3 / 75s
- 75+: 10 / 3 / 90s

**High-rep bonus:** crunches/sit-ups/calf-raises/lateral-raises/glute-bridges/
burpees get +8 reps on top of the level cap (capped at `ABSOLUTE_MAX_REPS=30`).

**Score:** `fail` if any per-exercise sets/reps/rest violates the level OR age cap.

---

## C. Difficulty alignment

- `workout.difficulty` ⊆ {easy, medium, hard, hell}.
- Request `fitness_level=beginner` ⇒ output `difficulty ∈ {easy, medium}`.
  Beginner ceiling is **strict** per `workout_safety_validator.py:67-76`.
- Request `fitness_level=advanced` + non-mobility focus ⇒ `difficulty ∈
  {medium, hard, hell}`. `easy` only legitimate for mobility/recovery sessions.
- Hell mode skips age caps but keeps absolute ceilings (sets ≤6, reps ≤30).

**Score:** `fail` on mismatch.

---

## D. Goal-driven prescription

Source: `quick_workout_constants.dart:111-135` + `progressive_overload.dart:126-225`.

| Goal | Reps | Sets compound | Rest compound |
|---|---|---|---|
| strength | 3-6 | 5 | 180s |
| power | 1-5 | 5 | 240s |
| hypertrophy | 8-12 | 4 | 120s |
| endurance | 15-20 | 3 | 60s |

**Specific failure modes:**
- `goal=strength` AND every exercise reps>10 → `fail`
- `goal=hypertrophy` AND every exercise sets<3 → `fail`
- `goal=endurance` AND every exercise rest>90s → `fail`
- `goal=power` AND no top-set rest ≥150s → `warn`
- `goal=mobility` with weighted compound lifts (squat/deadlift/press) → `fail`
- `goal=fat_loss` with classic 3×10/120s rest schema → `warn` (more aligned
  with hypertrophy than fat-loss conditioning)

---

## E. Density (exercise count vs duration)

- Strength: ~1 exercise per 7 min (≈4 ex / 30 min, 6 / 45 min, 8 / 60 min).
- Circuit / cardio / HIIT: 1.5–2× that density.
- **`fail`** if `duration_minutes / n_exercises < 4` for non-circuit workouts.
- **`warn`** if `< 5`.

---

## F. Movement-pattern diversity

Source: `mobile/flutter/lib/services/movement_patterns.dart`.

7 canonical patterns: squat, hinge, push-horizontal, pull-horizontal,
push-vertical, pull-vertical, carry.

| Duration | Patterns required |
|---|---|
| 5 min | ≥2 |
| 10-15 min | ≥3-4 |
| 20+ min | ≥5-6 |

**Score:** `fail` if pattern count below threshold.

---

## G. Compound-vs-isolation balance

Source: `quick_workout_templates.dart:82-165`.
- Strength / full-body: compound lifts FIRST; supersets pair antagonists
  (chest↔back, quads↔hams, biceps↔triceps).
- Core / cardio: circuit-style; isolation OK.
- **`fail`** if first 2 exercises in a strength session are both isolation
  (e.g. lateral raises + bicep curls).

---

## H. Injury safety

Source: `workout_safety_validator.py:53-62, 394-589`.

8 supported joints. Per-injury blocked patterns:

| Injury | Blocked patterns |
|---|---|
| shoulder | overhead press, behind-the-neck, weighted dips |
| lower_back | conventional deadlift, good morning, loaded twist |
| knee | deep squat, jump squat, plyometric, lunges with full ROM |
| elbow | heavy skullcrusher, close-grip bench |
| wrist | flat-palm push-ups, front-rack work |
| ankle | box jumps, single-leg plyometric |
| hip | wide-stance squat, deep hinge |
| neck | shrug, weighted front squat, headstand |

Validator is **fail-closed**: NULL safety flag = unsafe.

**Score:** `fail` if any output exercise hits a blocked pattern for a flagged
injury.

---

## I. Schema integrity edges (data-shape gotchas)

- `sets=0` or `reps=0` → `fail` (degenerate).
- Negative `weight_kg`, `rest_seconds`, `duration_minutes` → `fail`.
- NaN / Infinity / null in any numeric field → `fail`.
- `reps` form (int vs `"8-12"` range): preserve original; collapsing silently → `warn`.
- `set_targets[]` length must equal `sets` count → `fail` on mismatch
  (common Gemini hallucination).
- Duplicate exercise NAME within the same workout → `fail`.
- Whitespace-only or empty `name` → `fail`.
- Unicode bombs (emoji / RTL Arabic / 200-char Chinese) in name → `warn`
  (verify backend `max_length=200` enforced).
- Set-target weight inconsistency (warmup > working weight) → `warn`.
- `superset_group` integers must come in pairs (regular supersets) or triples
  (trisets) — odd group counts → `warn`.

---

## J. Physiological safety beyond stated injuries

- Senior (75+) with `difficulty=hell` → must auto-cap to `medium`. `fail` if escapes.
- Pregnancy (`ai_prompt` contains "pregnant"/"trimester"): no supine work
  after T2 (~week 16). `fail` if violated.
- Menstrual phase (`get_user_hormonal_context`):
  - Luteal: −1 RPE, +10s rest expected.
  - Menstrual: deload OR mobility focus.
- Cardiac/BP red flags (`ai_prompt` mentions "heart"/"blood pressure"):
  no Valsalva-required heavy lifts; max RPE 8.
- Concussion / neck: no inversions, headstands, weighted neck flexion.
- Beginner total-volume ceiling: ≤30 working sets per session
  (NSCA guideline). `fail` if exceeded.
- BFR mention: `warn` for trainer review (cuff pressure not API-communicable).

---

## K. Movement-pattern balance (beyond raw count)

- Push:Pull ratio: 0.5–2.0 (no extreme).
- Squat:Hinge for legs days: ≤3:1.
- Bilateral:Unilateral mix: at least one unilateral movement in `full_body`
  workouts ≥45 min.
- Plane diversity: sagittal-only sessions → `warn` if no frontal/transverse
  in 7-day window.
- Anti-rotation core (Pallof, dead-bug, bird-dog): mandatory in core-focused
  sessions ≥20 min. `fail` if absent.
- Anterior:Posterior chain: posterior gets ≥40% of work in
  `goal=general_fitness` sessions (postural correction). `warn` if violated.

---

## L. Programming structure (warmup / working / cooldown)

- Warmup budget per `quick_workout_constants.dart:81-105`:

  | Duration | Warmup secs | Notes |
  |---|---|---|
  | 5 min | 0 | — |
  | 10 min | 60 | light mobility |
  | 15-20 min | 120-150 | general + specific prep |
  | 25-30 min | 180-240 | comprehensive |

- Activation drills before compound lifts (e.g. glute activation before squat) → `info`.
- Compound-before-isolation ordering (hypertrophy/strength) → `fail` if reversed.
- AMRAP/failure sets: ONLY on last set of an exercise. Mid-block → `fail`.
- Drop sets: only last 1-2 sets, with `is_drop_set=true` AND `drop_set_count`
  + `drop_set_percentage` populated. Otherwise `warn`.
- Failure-set frequency cap: beginners 1/session, intermediates 2,
  advanced 3, elite 4. `fail` if exceeded.
- Superset structure: `superset_group` IDs must pair (even count for true
  supersets, multiples of 3 for trisets). Odd groups → `warn`.
- Cooldown / `stretch_json` present for sessions ≥45 min → `info`.

---

## M. Variety & freshness

- Identical exercise list across 2+ scenarios with different request bodies
  → `fail` (variety regression — same call ≠ same output).
- Same workout name reused within 14 days for same user → `warn`.
- Same exercise appearing in >3 of last 7 sessions → `warn`.
- Equipment monotony: only one equipment family for 5 consecutive sessions
  → `warn`.
- Muscle group untouched >9 days → `warn` (atrophy risk per Israetel).
- Adjacent-day overlap: if `adjacent_day_exercises=[X,Y]` provided in
  request, output MUST NOT include X or Y → `fail`.
- Exclude-list compliance: `exclude_exercises` items must be absent → `fail`.

---

## N. Volume landmarks (Israetel MEV/MAV/MRV)

Source: `volume_landmark_service.dart:113-158` + `volume_landmarks.json`.

- No single muscle group gets >MAV/2 working sets in one session → `fail`.
- Total weekly volume across simulated 7-day plan stays MEV ≤ x ≤ MRV.
- Recovery-score modifier: Recovery <60% → cap session at MAV×0.85.
- Avg RPE <6.5 across 3+ sessions → MEV × 1.10 (room to grow).

---

## O. Equipment-context fidelity

- Output exercises only use equipment from request `equipment[]` OR resolved
  gym_profile equipment list → `fail` on mismatch.
- "Bodyweight" sessions (`equipment=[]`): no bench, no pull-up bar, no rings.
  Pull-ups/dips when `equipment=[]` → `fail`.
- `dumbbell_count=1` → no exercises requiring 2 DBs (alternating DB press OK;
  bilateral DB bench NOT OK) → `fail` if violated.
- `kettlebell_count=1` → same single-bell rule.
- Custom equipment (TRX bands, yoga wheel) in user profile must be honored
  when present; generic substitution → `warn`.
- Empty equipment + non-bodyweight focus → server should fall back to
  bodyweight-feasible exercises, NOT fail. `fail` if empty exercise list.

---

## P. User-state awareness

- New user (0 workout history) → conservative caps (sets ≤3, reps 8-12).
  Otherwise `warn`.
- Returning user (>30d break) → comeback mode reduces sets ≤−1 and reps
  ×0.7 per `validation_utils.py:313-316`. `fail` if comeback context
  provided but reductions absent.
- Active streak ≥8 sessions → progressive overload should trigger
  (weight ↑ ~2.5% OR reps +1 vs last session for same exercise) → `info`.
- Plateau (3 sessions same weight on key lift) → deload OR variation
  expected → `warn` if neither.
- 1RM-aware weighting: if `oneRepMaxes` provided, `weight_kg` should be
  0.6-0.85 × 1RM for working sets. Never 100% 1RM unless explicit
  power/test session. `fail` if violated.

---

## Q. Hormonal & cycle context

Source: `get_user_hormonal_context`.

- Phase modifiers:
  - **Follicular**: progress aggressively.
  - **Ovulation**: peak strength window — encourage PRs.
  - **Luteal**: −1 RPE, +10s rest.
  - **Menstrual**: deload OR mobility focus.
- `kegels_enabled=true`: warmup OR cooldown blocks include pelvic-floor
  activation → `fail` if missing.

---

## R. Personalization & coaching voice

- `notes` field non-empty AND specific. Generic ("Focus on form") → `warn`.
- Identical notes across multiple scenarios → `warn`.
- Workout name reflects intent (strength → power-themed; mobility → flow-
  themed). Generic "Workout {N}" → `fail`.
- Holiday/seasonal theming when `_get_holiday_theme` triggers (Halloween,
  Thanksgiving, etc.) → `info` if absent.
- First-name personalization in notes: appears at most ONCE if user has
  `first_name`. Multiple occurrences → `warn`.

---

## S. Streaming health & pathology

- `sse_event_count > 0` always → `fail` if 0 events.
- TTFB (first chunk) <500ms → `warn` if exceeded.
- Periodic progress events every ~3 chunks
  (`generation_streaming.py:469-476`).
- Stall taxonomy (`error_message="sse_error: ... stalled at chunk N"`):
  - Track stall chunk-N distribution. Clustered (<5 OR >50) → deterministic
    timeout / token-limit suspect.
  - Uniform → transient Gemini stream issue.
- "Empty stream" — `sse_event_count==1` (only `started`) and no further
  chunks → distinct from stall.
- Final event present but `exercises_json="[]"` → schema-valid but semantic
  failure → `fail`.
- `total_time_ms` from final event ≤30s (Render timeout) → `warn` if exceeded.
- 502/504: cold-start lambda → harness retries once.
- Idempotency: duplicate POST within 1s for same `user_id, scheduled_date`
  → must return `event: already_generating`.

---

## T. Cross-call consistency / regression detection

- Same `user_id` + same body → `difficulty` and `n_exercises` should be ±1,
  not wildly different.
- Sequential calls share at most 50% exercise overlap (variety check) →
  `warn` if >50%.
- `workout.duration_minutes` field within ±10% of estimated from
  `Σ(sets × reps × 3s + rest_seconds + 30s setup)` math → `warn` if drift.

---

## U. Locale & i18n

- Workout name encoding: UTF-8 round-trip safe.
- Multi-byte characters preserved in CSV (proper RFC-4180 quoting).
- AI prompts in non-English (Spanish, Mandarin, Arabic) → output should
  honor language hints. RTL languages must round-trip.

---

## V-bis. set_targets ↔ sets length contract (clarification)

**Convention** (verified against 115/100 rows of run 20260508_111252):
- `sets` = number of **WORKING** sets only (excludes warmup).
- `set_targets[]` = ALL set targets including warmup.
- Typical: `len(set_targets) == sets + 1` (1 warmup + N working).

**Score:**
- `len(set_targets) == sets`: pure-working-set contract (no warmup) — `info`.
- `len(set_targets) == sets + 1` AND first entry has `set_type=warmup`: standard — `pass`.
- `len(set_targets) > sets + 1`: extra warmups OK if all flagged — `info`.
- `working_count_in_set_targets < sets`: under-stimulus → `fail`.
- `set_targets` empty → `fail` (strict validator should reject, but verify).

This convention is NOT documented in the schema — clarified here so future
analyses don't false-flag.

## W. exclude_exercises and adjacent_day_exercises hard compliance

**Real-data finding** (run 20260508_111252):
- idx 93: `exclude_exercises=['bench press', 'barbell squat', 'deadlift']` →
  output STILL contained "bench press" + "deadlift". 🔴 PRODUCTION BUG.
- idx 94: `adjacent_day_exercises=['bench press', 'squat', 'deadlift', 'pullup', 'row']` →
  output contained "bench press" + "row". 🔴 VARIETY-DEDUP BROKEN.

**Hard contract:**
- `exclude_exercises[]` items must be ABSENT from output exercise names
  (case-insensitive substring match) → `fail` per violation.
- `adjacent_day_exercises[]` items must be ABSENT from output → `fail` per
  violation.
- Both checks AFTER Gemini, BEFORE returning to client. If output contains
  forbidden items, swap or re-prompt.

**Recommended fix path:** post-process Gemini output; if any exclude/adjacent
items appear, perform safety swap using `workout_safety_validator.find_safe_swap`
with the forbidden item as a virtual injury.

## X. Duration request ↔ response drift

**Real-data finding** (12/92 success rows drifted >5 min):
- idx 6: req=30min, response=60min (DOUBLED).
- idx 8: req=60min, response=30min (HALVED).
- idx 11: req=20min, response=45min.
- idx 51, 54, 55, 56, 57, etc.

**Contract:**
- Server-returned `duration_minutes` should be within ±10% (or ±5 min,
  whichever is greater) of request `duration_minutes` → `fail` if drift larger.
- For range requests (`duration_minutes_min` + `_max`), server-returned value
  must fall inside the range → `fail` if outside.

**Likely cause:** the server uses `estimated_duration_minutes` from sum(sets ×
reps × 3 + rest) math, which can drift far from the requested target if Gemini
returns aggressive sets/rest. Fix: enforce request value as authoritative
unless `truncate_exercises_to_duration` was triggered.

## Y. workout_type ↔ focus_areas consistency

**Real-data finding** (idx 52):
- request `focus_areas=['mobility']` → output `workout_type="strength"`.
- That's an internal contradiction — mobility focus shouldn't be a strength
  workout type.

**Contract:**
- `workout_type ∈ {strength, hypertrophy, cardio, hiit, mobility, recovery,
  hybrid}`.
- Mapping (loose):
  - focus=`mobility` or `stretch` → workout_type ∈ `{mobility, recovery}`.
  - focus=`cardio` → workout_type ∈ `{cardio, hiit}`.
  - focus=`push|pull|legs|upper|lower|full_body` → workout_type ∈
    `{strength, hypertrophy, hybrid}`.
  - focus=`core` → workout_type ∈ `{strength, hybrid, mobility}` (core can be
    strength-focused or mobility-focused).
- Mismatch → `warn` (not fail — Gemini's hybrid-style outputs are sometimes
  legitimate cross-categorical).

## Z. Stream-failure correlations (Block 1 stress test)

**Real-data finding** (8 stream failures all in Block 1):
- 4/8 had `focus_areas=['full_body']` (50% concentration vs ~25% baseline)
- Long durations (60-90 min) overrepresented (3/8 ≥ 60 min)
- Equipment list size: bimodal — 0 items (3/8) or 5+ items (4/8).

**Hypothesis:** prompt-token budget tipping at full_body + many equipment +
long duration combinations → Gemini stream truncates mid-generation.

**Action items:**
- Track: stall-rate by `focus_areas[0]`. Flag if any focus value's stall rate
  >2× baseline.
- Track: stall-rate by `len(equipment)`. Flag if linear increase.
- **Mitigation already shipped** (this session): retry-with-backoff now catches
  "stalled" / "stream stall" / "streaming failed" / "incomplete chunked read"
  / "connection reset" / "premature" — see `services/gemini/constants.py:_is_transient_gemini_error`.

## AA. workout_type ↔ exercise CONTENT consistency (not just declared focus)

**Real-data finding** (run 20260508_111252):
- 88/92 success rows labeled `workout_type=strength` (96%) — broken default.
- idx 15, 37, 56: 100% cardio content (treadmill, rowing, bike, elliptical) but
  `workout_type=strength`. Home carousel filter would mis-categorize these.

**Hard contract** (heuristic check on exercise names):
- If ≥50% of exercises match cardio keywords (treadmill, rowing machine,
  stationary bike, elliptical, sprint, jump rope) → `workout_type` MUST be
  `cardio` or `hiit`. Else `fail`.
- If ≥50% match stretch keywords (stretch, pose, foam roll, release, flow)
  → `workout_type` MUST be `mobility` or `recovery`. Else `fail`.
- Run-level: if any single `workout_type` value covers >70% of rows in a
  varied-scenario sweep, suspect default-fallback bug → `warn`.

## BB. Distribution sanity (run-aggregate, not per-row)

For a sweep that varies inputs, verify outputs vary too:
- No single `workout_type` value >70% of rows.
- No single `difficulty` value >75% of rows for varied fitness_level inputs.
- No single workout_name appearing in >5% of rows.
- Mean exercise count by `duration_minutes` bucket should rise monotonically
  (15 < 30 < 45 < 60 < 90).
- Output `workout.difficulty` distribution should approximately match request
  `fitness_level` distribution (within ±15% per bucket).

## CC. Duration range honoring

- If request has `duration_minutes_min` AND `_max`, response `duration_minutes`
  MUST fall inside [min, max]. `fail` if outside.
- If only `duration_minutes` provided, response within ±10% (or ±5 min
  whichever larger). `fail` otherwise.

## DD. Equipment naming normalization

- Equipment field should be lowercase snake_case ('pull_up_bar' not
  'Pull-up Bar' or 'Pull Up Bar' or 'pull-up bar'). `warn` on inconsistencies
  within the same workout.
- The same logical equipment must use the same string across exercises in a
  run (no 'dumbbells' vs 'dumbbell' vs 'DBs' mixing).

## EE. Equipment provenance (output uses only what was declared)

- Every exercise's `equipment` field must match an item in:
  `request.equipment[]` ∪ `gym_profile.equipment[]` (case-insensitive).
- `fail` per exercise that uses equipment not in either list.
- "bodyweight" / "none" / "" always allowed.
- Fuzzy match for synonyms (e.g., "barbell" ↔ "olympic barbell").

## FF. Reps progression sanity within an exercise

Per `per_exercise_reps` like `8|10|12|10|12`:
- Strict random reps across sets is suspicious. Acceptable patterns:
  - **Constant**: 10|10|10|10
  - **Ascending pyramid**: 5|7|9|11
  - **Descending pyramid**: 12|10|8|6
  - **Reverse pyramid (warmup pad)**: 12|8|8|8
  - **Drop set**: 10|10|10|max
- Random oscillation (e.g., 5|12|7|14|3) → `warn`.
- Last rep value of `1` is OK only if exercise is timed (cardio collapse).
  Otherwise → `fail`.

## GG. Set count uniformity

- Most exercises in a workout should share a set count (e.g., all 4 sets, or
  4|4|4|3 acceptable).
- Wild variance (5|2|7|3|6|1) → `warn` (suggests Gemini didn't follow
  programming structure).

## HH. target_rpe progression in set_targets

- Per-exercise: warmup RPE 4-6 → working RPE 7-8 → final RPE 8-9.
- `fail` if working sets RPE > final set RPE (RPE can only increase or hold
  in standard programming).
- `fail` if warmup RPE > 7 (defeats the purpose of warmup).

## II. Workout name semantics

- Length: 8 < `len(name)` ≤ 80 chars. `fail` outside this range.
- Should not lie about duration: a name like "5-Minute Express" should not
  appear on a 60-min workout. Regex-check name for embedded duration claims.
- Should not lie about exercise count: "10-Move Blast" should match
  `n_exercises ≈ 10` (±2).
- Generic names (`"Workout"`, `"Training Session"`, single-word)  → `warn`.

## JJ. Cooldown / finisher for long sessions

- Sessions ≥45 min should have a cooldown stretch or low-intensity finisher
  in the LAST 1-2 exercises.
- `warn` if last exercise in a 60-min strength session is a heavy compound.

## KK. Warmup placement

- First exercise should NOT be a heavy compound at working intensity.
- Either: explicit warmup as first exercise (set_type=warmup, low RPE), OR
  first compound has a warmup set within `set_targets[0]`.
- `fail` if first exercise jumps straight to RPE ≥7 working sets.

## LL. set_type ordering within set_targets

- Order MUST be: warmup → working → drop/failure/amrap (last set).
- `fail` if any drop/failure set appears before working sets.
- `fail` if a warmup set appears AFTER a working set.

## MM. Exercise equipment tag matches exercise name

- If exercise name contains "Barbell …", `equipment` field MUST contain
  "barbell". Same for Dumbbell, Kettlebell, Cable, Machine, Band.
- `fail` per name-equipment mismatch (e.g., "Barbell Squat" with
  `equipment="bodyweight"`).

## NN. set_number uniqueness within an exercise

- `set_targets[*].set_number` must be unique 1..N for an exercise of N sets
  (with possible warmup set_number=1, working starting at 2).
- Duplicate set_number → `fail`.
- Gap (1, 2, 4) → `warn`.

## OO. estimated_calories sanity

- Calories per minute, by intensity:
  - Easy/mobility: 4-7 kcal/min
  - Medium strength: 6-10 kcal/min
  - Hard strength / cardio: 10-14 kcal/min
  - Hell mode: 12-18 kcal/min
- `fail` if `estimated_calories / duration_minutes` outside [3, 22] kcal/min.
- `warn` if = 0 or unset.

## PP. generation_source tagging

- `workout.generation_method` ∈ {ai, algorithm}.
- `workout.generation_source` ∈ {streaming_generation, regenerate, onboarding,
  quick_button, mood, custom_program}.
- `fail` if either is empty / `"fallback"` / `"mock"` / `"unknown"` —
  indicates a fallback path was hit (no mock-data rule per CLAUDE.md).

## QQ. target_muscles vs muscle_group consistency

- `muscle_group` (primary) MUST be in `target_muscles` (set of all targeted).
- Secondary/stabilizer muscles in `target_muscles` should not duplicate the
  primary entry.

## RR-pre. Goal-specific workout_type tagging

**Real-data finding** (run 20260508_111252):
- All 7 `goal=hypertrophy` rows had `workout_type=strength` (0/7 used the
  more-specific "hypertrophy" type). Pydantic schema allows `hypertrophy` but
  Gemini defaults to `strength`.

**Hard contract:**
- `request.goals` ∈ `{strength, hypertrophy, power, endurance, fat_loss,
  general_fitness, mobility, athletic_performance}`.
- Output `workout_type` must reflect goal:
  - `goal=hypertrophy` → `workout_type ∈ {hypertrophy, strength}` (with
    hypertrophy preferred).
  - `goal=strength` → `workout_type ∈ {strength}`.
  - `goal=power` → `workout_type ∈ {strength, hybrid, power}`.
  - `goal=endurance` → `workout_type ∈ {cardio, hiit, hybrid, endurance}`.
  - `goal=fat_loss` → `workout_type ∈ {cardio, hiit, hybrid}`.
  - `goal=mobility` → `workout_type ∈ {mobility, recovery}`.
- `warn` if mismatch (Gemini may use canonical name); `fail` if outright wrong
  (e.g. goal=mobility → type=strength).

**Fix gap:** my AA-fix overrode cardio/stretch heavy content but NOT
strength↔hypertrophy. Extend `_focus_to_type` or add a goal-keyed override.

## RR-pre-2. Goal-specific programming (per goal vs observed numbers)

Hypertrophy-specific (most common goal, deserves its own check):
- Reps: 80%+ of working sets in [6, 15] range. `fail` if median outside.
- Sets per exercise: avg 3-5 (under 3 = under-stimulus; over 5 = junk volume).
- Rest: avg 60-120s (40-150s acceptable). `fail` outside.
- TUT (time under tension) — if eccentric/concentric tempo provided, sum
  per-set should be 30-70s for hypertrophy.
- Volume per muscle: 10-20 working sets/week per major muscle (Israetel
  MEV-MAV range).
- Compound:isolation ratio: 60:40 to 40:60. Pure compound = strength bias;
  pure isolation = pump-only, suboptimal hypertrophy.
- Intensity: 65-85% 1RM if `oneRepMaxes` provided.

Strength-specific:
- Reps: 1-6 working sets, avg 4. Rest 180-300s.
- Compound-dominant (≥70% compound exercises).
- High intensity: 80-95% 1RM.

Power-specific:
- Reps: 1-5 working. Rest 180-300s. Triple-extension movements (clean,
  snatch, jerk, jump variations) preferred.
- Velocity-based — explicit "explosive" / "fast" cues in description.

Endurance-specific:
- Reps: 15+ OR timed sets. Rest 30-60s.
- Cardio modalities or high-rep circuits.
- Heart-rate zones (Z2-Z3) referenced if HR data available.

## RR. Adjacent-day muscle-group balance

When server generates multiple days in batch:
- No single muscle_group should appear as the primary in 3+ consecutive days.
- 7-day rolling: each major muscle group gets at least 2 sessions.
- `warn` if violated.

## SS. Weight progression within a single exercise

(Validation 2026-05-08 audited 583 exercises; 0 violations. Document the
contract so this stays clean.)

- Warmup `target_weight_kg` ≤ working sets `target_weight_kg`. `fail` otherwise.
- Working set ramp patterns (any of these is valid):
  - **Straight sets**: 80|80|80|80 (fixed load, RPE rises with fatigue) — most common.
  - **Top-set ramp**: 60→80→85→90 (linear ramp toward a top set) — strength bias.
  - **Pyramid up**: 8 reps × heavier each set.
  - **Reverse pyramid**: heaviest first, drop weight after.
- `fail` if working weight DROPS mid-block without a `set_type=drop` flag.

## TT. Per-set RPE progression

(Validation 2026-05-08: 275× canonical (7,8,9) sequence — strong baseline.)

- Warmup RPE ≤ 6.
- Working sets: monotonically rising or flat (no descending RPE without a
  cooldown context). Common patterns:
  - **(7, 8, 9)** — textbook hypertrophy/strength → `pass`
  - **(7, 7, 8)** — moderate intermediate → `pass`
  - **(8, 8, 9)** — advanced grinding → `pass`
  - **(8, 9, 10)** — advanced near-failure → `pass` (tag `set_type=failure` on the 10)
  - **Descending** (e.g. 8→7→6) → `fail` UNLESS the exercise is a cardio cooldown.
- Final-set RPE ≥ 7 for any goal except mobility/recovery → `pass`.
- Cardio/cooldown: RPE may descend (e.g. 4|3|2 cooldown) — `info` not fail.

## UU. `sets` field semantics ambiguity

**Real-data finding:** the `sets` integer field is INCONSISTENT across rows:
- Sometimes `sets` = working-set count (e.g. sets=3, set_targets has 1 warmup
  + 3 working = 4 entries).
- Sometimes `sets` = total count including warmup (e.g. sets=4, set_targets
  has 1 warmup + 3 working = 4 entries).

**Action:** the schema needs a documentation update (or a separate
`working_sets_count` field). Until then, harness checks should:
- Compute `working_count = len([s for s in set_targets if s.set_type in
  ('working','drop','failure','amrap')])`.
- Flag `working_count < 3` → `fail` (under-stimulus).
- Flag `working_count` consistently <`sets` for >50% of exercises in a run →
  schema-drift `warn`.

## VV. Cross-session progressive overload

(Verification mode — needs multi-call test, not single-shot.)

When `strength_history` is provided to the streaming generator (e.g. user
has logged previous sets):
- Same exercise across consecutive sessions: weight should rise ~2-5% per
  session (or reps +1 same weight) for `progression_pace=medium`.
- `fail` if same exercise weight drops session-over-session (without
  `comeback_mode` or `recovery_low` flag).
- `fail` if weight is held constant for 3+ consecutive sessions on a
  major lift (plateau without deload programming).

Multi-call test design: generate workout day 1, log sets, generate day 2,
verify weights ramp; repeat for 5 sessions to detect plateau handling.

## WW. RAG provenance (architecture finding 2026-05-08)

**Verified via code read:** `/api/v1/workouts/generate-stream` does **NOT**
pre-seed Gemini with library exercises. Architecture is:

1. Gemini freely generates exercise names from training data.
2. POST-Gemini, RAG-style filters drop:
   - Equipment-incompatible exercises (`generation_streaming.py:745`).
   - Off-region exercises (line 781).
   - Duplicates (line 808).
3. Final exercises returned.

**Implication for checklist:**
- Exercise names may not match library entries → `image_s3_path` may 404.
- Variety dedup harder (Gemini doesn't know user's recent history unless
  explicitly told via `adjacent_day_exercises`).
- New: track `exercise_id` populated rate. If <70% of exercises have a
  library `exercise_id`, the AI is hallucinating exercises that don't exist
  in our database → bad UX (no video, no image).
  - `fail` per exercise without `exercise_id` AND without `video_url`.

Compare: `/api/v1/workouts/generate` (non-streaming) DOES pre-seed via
`generate_workout_from_library` — Gemini gets a pre-filtered list. That's
the proper RAG flow.

## XX. Cross-discipline contamination (no punches/stretches in wrong contexts)

**Real-data finding** (run 20260508_111252): 0 violations on a 92-row sample.

**🛡️ ENFORCED IN CODE (2026-05-08):** `services/exercise_rag/filters.py:filter_main_exercises()` now drops:
- Stretches from any workout where focus is NOT mobility/stretch/recovery
- Combat moves (punches/kicks/MMA) from any workout where focus is NOT cardio/HIIT/boxing/combat

The check below should always pass after the next deploy. If a violation appears, it's a filter regression.

The AI must NOT contaminate workouts with movements from a different
discipline than what was requested.

### Stretch contamination (yoga / mobility moves in strength workouts)

Search exercise names for these patterns:
```
" stretch", " pose", "foam roll", "release", "flow", "child pose",
"cobra pose", "pigeon pose", "warrior pose", "downward dog",
"lying twist", "seated twist", "dynamic stretch", "static stretch",
"wall stretch", "quad stretch", "hamstring stretch", "hip opener",
"shoulder stretch", "chest stretch", "calf stretch", "lats stretch",
"back stretch", "cat-cow", "sun salutation"
```

**Hard contract:**
- ANY of these patterns appearing in a workout with `focus_areas` NOT in
  `{mobility, stretch, recovery, cooldown}` AND `workout_type` NOT in
  `{mobility, recovery, stretch}` → `fail`.
- Note: leading-space prefixes ("` stretch`") avoid false positives like
  "Stretching the band" inside an exercise description.
- Scoring: 1 fail per contaminated exercise.

### Punch / martial-arts contamination (boxing moves in strength/hypertrophy)

Search for:
```
" punch", " jab", " cross-jab", "uppercut", "hook punch", "boxing",
"shadow box", "bag work", "muay thai", "elbow strike", "round house",
"roundhouse", "front kick", "side kick", "back kick"
```

**Hard contract:**
- Any of these in a workout with `focus_areas` NOT in
  `{cardio, hiit, conditioning, boxing, combat}` AND `workout_type` NOT in
  `{cardio, hiit, combat, boxing}` → `fail`.
- Important false-positive guard: "kick" alone matches "Cable Glute
  Kickbacks" / "Donkey Kicks" which are legitimate posterior-chain
  exercises. Always check for "kick" in `front kick` / `side kick` /
  `back kick` / `roundhouse kick` patterns, NOT bare "kick".

### Excessive stretch content (over-stretching in non-mobility)

- If `n_stretch_exercises / n_exercises > 0.3` AND focus is not mobility →
  `fail`. The workout has effectively become a stretch session under a
  strength label.

### Power/plyometric contamination in beginner+injury contexts

Search for: `box jump`, `plyo`, `jump squat`, `jumping`, `bound`,
`tuck jump`, `clap push-up`, `power clean`.

**Contract:**
- These in workouts where `fitness_level=beginner` AND any injury flagged →
  `fail` (existing safety validator should catch but defense-in-depth).

### Olympic-lift contamination in beginner workouts

Search for: `clean and jerk`, `snatch`, `power clean`, `hang clean`,
`split jerk`, `push jerk`.

**Contract:**
- These in `fitness_level=beginner` workouts → `fail` (advanced exercise
  blocklist per `validation_utils.py:32-54` — verify the blocklist is
  catching them).

### Static-hold contamination in pure-cardio workouts

Search for: `plank`, `wall sit`, `dead hang`, `hollow hold`, `l-sit`.

**Contract:**
- These as the PRIMARY exercises (≥3 of the workout) when `focus=cardio`
  → `warn`. A static hold isn't cardio.

### Aggregate "discipline purity" score

For each workout, compute:
- Strength % (compound + isolation lifts)
- Cardio % (treadmill/bike/row/elliptical/sprint/burpee/jumping)
- Mobility % (stretch/pose/release patterns above)
- Plyometric % (jump/box/bound/explosive)
- Combat % (punch/jab/kick patterns above)

Then for the requested workout type, the dominant discipline % must match:

| `workout_type` | Required dominant discipline % |
|---|---|
| strength | strength ≥ 70% |
| hypertrophy | strength ≥ 60%, mobility < 20% |
| cardio | cardio ≥ 60% |
| hiit | cardio + plyo ≥ 70% |
| mobility | mobility ≥ 70% |
| recovery | mobility ≥ 70%, no plyo |
| hybrid | no single discipline >70% (intentional mix) |

Otherwise → `fail`.

## XX-bis. Focus-scope contamination (upper/lower/core leak across body halves)

**Real-data finding** (run `quick_workout_engine_20260508T205650`, 1137 scenarios):
- 210 cases of upper_body workouts containing lower-body exercises
  (e.g. `Plank Lunges`, `Bulgarian Split Squat`, `Dumbbell Goblet Curtsy Lunge`,
  `Trap Bar Deadlift`).
- Lower_body workouts containing upper-body exercises (presses, curls).
- **Two root causes:**
  1. **Library data quality** — many entries pack secondary muscles into the same
     `target_muscle` string (e.g. `"Quadriceps, Glutes, Shoulders (Deltoids)"` for
     "Overhead Lunge"). Substring-matching the `shoulders` slot pulls the lunge
     into an upper-body workout.
  2. **Movement-pattern diversity check** force-injects `squat`/`hinge` patterns
     (which always map to `quads`/`hamstrings` muscles) even into upper-body
     workouts via `getMissingPatterns()` + `patternToMuscle()`.

**🛡️ ENFORCED IN CODE (2026-05-08):** `quick_workout_engine_ui.dart`:
- New `_isLowerBodyMovement()` and `_isUpperBodyMovement()` name-keyword filters
  drop cross-contamination from the library before slot selection when
  `focus ∈ {upper_body, lower_body, core}`.
- Movement-pattern diversity check now skipped for opinionated focuses; only
  `full_body` and `strength` run pattern-fill.

**Hard contract:**

| Focus | Forbidden movement keywords |
|---|---|
| `upper_body` | lunge, squat, deadlift, rdl, romanian, split squat, pistol, step up, leg press, leg curl, leg extension, calf raise, glute bridge, glute kickback, hip thrust, good morning, kettlebell swing, box jump |
| `lower_body` | bench press, chest press, shoulder press, overhead press, military press, push press, arnold press, bicep curl, hammer curl, preacher curl, tricep, skull crusher, kickback, lat pulldown, lat pull, pull up, chin up, row, fly, flye, pec deck, lateral raise, front raise, rear delt, face pull, push up, dip |
| `core` | both upper- AND lower-body movement keywords above |

**Score:** `fail` per exercise that violates the focus-scope filter.

**Re-run guarantee:** validation harness `quick_workout_engine_20260508T210700`
showed 0 violations after the fix. If a violation reappears, it's a regression
in the keyword filter or a new library entry whose name doesn't match any
keyword (extend the keyword list).

---

## XX-ter. Minimum-exercise floor (no 2-exercise workouts)

**Real-data finding** (run `quick_workout_engine_20260508T205650`):
- 70 workouts shipped with `n_exercises < 3` (mostly `n=2`).
- All concentrated in 5/10-min "easy" budgets.
- Root cause: budget loop `if (runningTime + cost > workingBudget) break;` exits
  at 2 exercises when supersets are on (cost ≈ 195s on easy-difficulty rest
  multiplier × 1.3) and the budget is tight. The fallback only triggered below
  2, and the Phase-5 prune-loop trimmed back to 2.

**🛡️ ENFORCED IN CODE (2026-05-08):** `quick_workout_engine_ui.dart`:
- Budget loop now keeps adding slots until ≥3 exercises (`if (... > workingBudget
  && selectedExercises.length >= 3) break;`).
- Fallback trigger raised from `< 2` to `< 3`.
- Phase-5 over-budget prune-loop floor raised from `> 2` to `> 3` so the trim
  step never undoes the minimum-exercise guarantee.

**Hard contract:**

| Workout type | Minimum exercises |
|---|---|
| Any (regardless of duration / difficulty / equipment / supersets) | ≥3 |
| 5-min `cardio` (HIIT/Tabata) | ≥4 (per `CardioHiitStrategy._cardioExerciseCount`) |
| 10+ min any focus | ≥4 typical, ≥3 hard floor |

**Score:** `fail` per workout with `n_exercises < 3`.

**Trade-off:** in a 5-min budget where 3 exercises naturally exceed the time
window, the engine prefers shipping 3 short exercises (~6-7 min effective)
over a 2-exercise "real workout" that fits exactly in 5 min. UX research
showed users do not perceive a 2-exercise workout as a workout.

---

## XX-quad. Movement-pattern diversity scope (only for whole-body focuses)

**Real-data finding** (run `quick_workout_engine_20260508T205650`):
- The diversity-fill step in `quick_workout_engine_ui.dart` was the primary
  source of cross-contamination (210 cases). It calls `getMissingPatterns()`
  which prioritizes `squat`/`hinge` patterns and `patternToMuscle()` which maps
  those to `quads`/`hamstrings`, then force-swaps the last exercise — injecting
  lower-body work into upper-body sessions.

**🛡️ ENFORCED IN CODE (2026-05-08):** Diversity check now gated to
`effectiveFocus ∈ {full_body, strength}` only. Excluded: `upper_body`,
`lower_body`, `core`, `cardio`, `stretch`, `emom`, `amrap`.

**Hard contract:**
- `requiredPatternCount(durationMinutes)` only applies to whole-body focuses.
- For opinionated focuses, exercise selection is bounded by the strategy's
  slot list — pattern coverage is whatever the strategy naturally provides.
- `fail` if a non-whole-body focus invokes pattern-fill swap (regression
  detection — should be impossible after the gate).

---

## YY. Exercise sequencing & ordering (CNS-demand cascade)

Order matters as much as exercise selection. The CNS is freshest at the
start; complex/high-skill movements need that freshness; isolation work
at the end pre-fatigued; mobility at start (warmup) or end (cooldown).

**Real-data findings** (run 20260508_111252, 92 success rows audited):
- 11 rows had compound exercises AFTER isolation (suboptimal CNS sequencing)
- 3 rows had 4+ consecutive isolations in a strength workout
- 1 row started with a static hold (`Hollow Body Hold`) before compounds
- 3 rows started with cardio in a labeled-strength workout (already covered by AA)
- 2 rows had core-only content with no compounds (covered by RR-pre-2)

### Canonical ordering for strength/hypertrophy workouts

The standard CNS-demand cascade (research-backed, NSCA / Israetel):

```
1. Mobility/dynamic warmup (optional, 0-5 min)
2. Power / plyometric / explosive  (highest CNS, ~60 sec rest between sets)
3. Heavy compound (squat, deadlift, bench)  (180s rest, 70-90% 1RM)
4. Secondary compound (lighter, supplemental)  (120-180s rest)
5. Isolation accessories  (60-90s rest, 8-12 reps)
6. Metabolic finisher (drop sets, AMRAP, conditioning)  (30-60s rest)
7. Core stability & abs  (60s rest)
8. Static stretches / cooldown (optional)
```

**Hard contract (server-side or harness-side check):**

| Rule | Severity | Notes |
|---|---|---|
| First exercise NOT a heavy compound for beginners | warn | Beginners should warm up first; advanced can launch into compounds w/ first-set warmup |
| Compound after isolation | fail | 11 violations in last run — the model interspersed compounds late |
| 4+ consecutive isolations in strength workout | warn | Suggests no compound-isolation alternation |
| Core/static-hold as FIRST exercise (strength workout) | fail | Pre-fatigues spine stability before heavy lifts |
| Cardio as FIRST exercise (non-cardio workout) | fail | Glycogen depletion before lifting |
| Cardio in MIDDLE of strength workout | fail | Breaks lifting flow |
| Plyometric AFTER isolation (power/strength goal) | fail | Plyo needs fresh CNS |
| Stretch in MIDDLE of workout (non-mobility) | fail | Stretches go at end (cooldown) |

### Set-type sequencing within an exercise

(Already in section L; reinforced here.)

| Rule | Severity |
|---|---|
| Warmup → Working → Drop/Failure/AMRAP order | fail if violated |
| AMRAP only on last set of an exercise | fail if mid-block |
| AMRAP/Failure NOT on first exercise of a workout | fail (reserved for last 1-2 exercises) |
| Drop sets only last 1-2 sets, with `is_drop_set=true` | fail if mid-block |

### Exercise-level sequencing rules

| Rule | Detail |
|---|---|
| **Pre-exhaustion** (legit hypertrophy technique) | Isolation BEFORE its target compound (e.g. cable fly → bench press) is OK if explicitly tagged; otherwise compound-first. |
| **Unilateral after bilateral** | Bilateral compound (Barbell Squat) before unilateral assistance (Bulgarian Split Squat) within the same muscle group. |
| **Heavy → light** within a muscle | Highest-load compound first, lighter compounds second, isolation last. Bench Press → Incline DB Press → Cable Fly. |
| **Antagonist superset adjacency** | Push/pull supersets (`superset_group=N`, order=1,2) must be adjacent in the exercise list. |
| **Equipment transition** | Avoid more than 2-3 equipment changes per workout (hops between barbell ↔ cable ↔ DB). Group by equipment family. |
| **Bilateral after unilateral** | Reverse case: when unilateral is the primary stimulus (e.g. injury rehab), bilateral may follow as accessory. |

### Workout-flow patterns by goal

| Goal | Preferred ordering pattern |
|---|---|
| **Strength** | Power/plyo → Heavy compound (1-2 lifts at 75-90% 1RM) → Secondary compounds → Optional isolation → Core |
| **Hypertrophy** | Compound (warmup → working) → Secondary compound → 2-3 isolations → Drop set / metabolic finisher → Core |
| **Power** | Power/plyo (max CNS) → Heavy strength lift → Lighter assistance → Optional core |
| **Endurance** | Warmup → 4-6 circuit rounds (mixed compound + isolation) → Cooldown |
| **Fat-loss / HIIT** | Warmup → 2-3 metabolic blocks (compound + isolation supersets) → Conditioning finisher → Cooldown |
| **Mobility** | Dynamic warmup → Mobility flows (CARS, dynamic stretches) → Hold-based stretches → Foam roll |
| **Recovery** | Light cardio (5 min Z2) → Static stretches (30-60s holds) → Foam rolling → Breathwork |

### Block-level structure (long sessions)

For workouts ≥45 min, structured blocks improve adherence:
- **Block 1 (warmup)**: 5-10% of duration — dynamic mobility + activation
- **Block 2 (strength/power)**: 50-60% of duration — main compounds
- **Block 3 (accessory)**: 25-30% of duration — isolation + assistance
- **Block 4 (cooldown)**: 5-10% of duration — stretches/mobility

Each block can be inferred from set_targets RPE pattern (warmup low RPE,
main blocks high RPE, cooldown low again).

### Verification points

For any workout in CSV output, manually (or via tooling) check each:

- [ ] First exercise is NOT cardio (in non-cardio workouts).
- [ ] First exercise is NOT a static hold (when compound work follows).
- [ ] First exercise is NOT core (in strength/hypertrophy/power workouts).
- [ ] No compound exercise appears AFTER an isolation in the sequence.
- [ ] Plyometric/explosive exercises (if any) appear in the first half.
- [ ] No more than 3 consecutive isolations without a compound break.
- [ ] Stretches (if present in mobility workout) are NOT interrupted by strength work.
- [ ] Static holds (planks, hollow holds) appear in the LAST third of compound workouts.
- [ ] Cardio (if present in hybrid session) appears in the LAST 1-2 slots.
- [ ] AMRAP/failure sets are on the LAST set of an exercise, not first.
- [ ] AMRAP/failure exercises are in the LAST 1-2 of the workout, not the first.
- [ ] Drop sets appear only on last 1-2 sets of an exercise.
- [ ] Supersets (`superset_group=N`) stay adjacent in the listing.
- [ ] For ≥45 min sessions: structure follows warmup (5-10%) → main (50-60%) → accessory (25-30%) → cooldown (5-10%).

**🛡️ ENFORCED IN CODE (2026-05-08):** `validation_utils.py:reorder_exercises_canonically()` runs server-side post-Gemini in all 4 AI endpoints. Most ordering violations should be auto-corrected before the response. Use this checklist to verify the auto-correction held.

## CSV / log integrity (harness-side)

- Every CSV row has consistent column count (no embedded unescaped newlines
  breaking parser) → `fail` on parse error.
- `raw_json_payload` round-trips: re-parsing it must reproduce the row's
  per-exercise fields exactly.
- `idx` column is contiguous 1..N (no gaps from killed runs unless resume
  mode marks them explicitly).
- Header row matches `CSV_COLS` in code — no schema drift between runs.

---

## Scoring formula

For each row, compute:

```
checks_run        = number of applicable sections (skip if column missing)
fails             = count of `fail` verdicts
warns             = count of `warn` verdicts
infos             = count of `info` verdicts

row_score = "PASS"  if fails == 0 and warns == 0
          = "WARN"  if fails == 0 and warns > 0
          = "FAIL"  if fails > 0
```

**Run aggregate:**
```
pass_rate = (rows with PASS) / total
warn_rate = (rows with WARN) / total
fail_rate = (rows with FAIL) / total
```

**Subset audits** (run a subset of sections):
- **Schema-only**: A + I + V
- **Safety-only**: B + C + H + J
- **Programming-quality**: D + E + F + G + K + L + N
- **Variety**: M + R + T
- **Operations**: S + V

---

## Cohort labels for analysis (used in ANALYSIS.md)

- **Schema-violation cohort** — A or I failures.
- **Difficulty-mismatch cohort** — C failures.
- **Density-violation cohort** — E failures.
- **Variety-regression cohort** — M failures.
- **Stream-failure cohort** — S failures.
- **Equipment-mismatch cohort** — O failures.
- **Hidden cohort** — all hard checks pass but warn-flagged on M / R / T
  (technically valid but boring/repetitive).

---

## Maintenance

When new validators ship in `backend/api/v1/workouts/validation_utils.py`
or `backend/services/workout_safety_validator.py`, add a section here.
The checklist is the contract; the harness is the meter.

---

## Fixes shipped (2026-05-08 — by validation harness run 20260508_111252)

These are now enforced server-side. Re-runs should show 0 violations on the
corresponding sections.

| Section | Fix | File |
|---|---|---|
| **C** Difficulty ceiling | beginner→hard/hell forced to medium; advanced→easy bumped to medium (non-mobility); mobility/stretch focus → never hard/hell, capped at easy | `api/v1/workouts/generation_streaming.py` (lines ~530-560), `api/v1/workouts/generation_endpoints.py` (lines ~702-720) |
| **E** Density cap | New `cap_exercise_count_by_density()` drops exercises beyond ~1 per 7 min strength / ~1 per 4 min cardio; tightens to 5 min/ex floor for ≤15-min sessions; 30-min strength → 5 ex; 30-min HIIT → 7 ex | `api/v1/workouts/validation_utils.py:449-490` (new func); wired in both gen endpoints |
| **S/Z** Stream stall retry | `gemini_generate_with_retry` now treats "stalled", "stream stall", "streaming failed", "incomplete chunked read", "connection reset", "premature" as transient → 3 retries with [2s, 5s, 10s] + jitter | `services/gemini/constants.py:_is_transient_gemini_error` |
| **M** Variety entropy | Streaming Gemini temperature 0.7 → 0.85 (both call sites) to reduce byte-identical-output regressions | `services/gemini/workout_streaming.py` lines 296, 528 |
| (NEW) Speed | Home carousel batch backfill: today-first single call, then bounded parallel (`_PARALLEL_BG_GEN=3`) for remaining days. 5-day backfill drops from ~60s to ~24s. | `api/v1/workouts/today.py:_sequential_generate_workouts` |
| **W** | exclude_exercises + adjacent_day_exercises post-Gemini filter — drops any exercise whose name matches forbidden list. | `generation_streaming.py:582-600` |
| **X** | Duration drift fix — final SSE event pins `duration_minutes` to resolved `target_duration` (request authoritative, not estimated). | `generation_streaming.py:980` |
| **Y** | workout_type ↔ focus override — mobility/cardio focus forces matching type when Gemini returns generic 'strength'. | `generation_streaming.py:570-585` |
| **R** | Workout name de-templating — zodiac-season theming gated to 15% probability + softened to "OPTIONAL flavor". | `services/gemini/workout_naming.py:431-455` |
| **AA** | workout_type derived from focus when Gemini omits it (was hardcoded "strength" default → 96% strength bug); content override on cardio/stretch heavy workouts. | `generation_streaming.py:528-580` |
| **XX-bis** | Focus-scope contamination filter (210 cross-body leaks → 0). Library pre-filtered by name-keyword for `upper_body` / `lower_body` / `core` focuses. | `mobile/flutter/lib/services/quick_workout_engine_ui.dart` (`_isLowerBodyMovement` / `_isUpperBodyMovement`) |
| **XX-ter** | Minimum 3-exercise floor enforced in slot loop, fallback trigger, and Phase-5 prune-loop (70 → 0 sub-3 workouts). | `mobile/flutter/lib/services/quick_workout_engine_ui.dart` |
| **XX-quad** | Movement-pattern diversity gated to `full_body`/`strength` only — upper/lower/core no longer force-inject opposite-half patterns. | `mobile/flutter/lib/services/quick_workout_engine_ui.dart` |

## Still-broken (real bugs found in this run, fixes deferred)

| Section | Bug | Suggested fix |
|---|---|---|
| **W** | `exclude_exercises` not honored (idx 93: requested no bench/squat/deadlift, got bench+deadlift) | Post-process Gemini output; reject + swap if any excluded name appears |
| **W** | `adjacent_day_exercises` not honored (idx 94: 2/5 forbidden items leaked through) | Same post-process |
| **X** | Duration drift (12/92 rows drifted >5min from request) | Use `truncate_exercises_to_duration` more aggressively; enforce request as authoritative |
| **R** | Workout-name templating (60+ workouts prefix "Taurus Iron …", reused 7× same name) | Expand naming variant pool; inject per-call uuid seed; use user first_name |
| **L/Y** | workout_type vs focus mismatch (idx 52: focus=mobility but type=strength) | Server-side override: derive type from focus when inconsistent |

## Known non-issues (don't false-flag in future analyses)

- **Empty `weight_kg` at exercise top level**: weights live in `set_targets[].target_weight_kg` per the schema. Top-level field is optional/legacy.
- **`reps=1` on cardio/timed exercises**: intentional collapse per `services/gemini/utils.py:354-407` — cardio has `target_duration_seconds` instead of reps.
- **`len(set_targets) == sets + 1`**: standard convention (warmup + N working). See V-bis.
- **Block 4 (injuries) all passed**: validator does its job; don't break it.

---

## NEW (post-2026-05-08 ultrathink) — algorithmic-endpoint sections

These are reusable rubrics for the *non-AI* endpoints (`/suggest-substitutes`,
`/quick-regenerate`, future deterministic endpoints). They have STRICTER guarantees
than AI endpoints because there is no model-randomness excuse for failures.

### AAA. Algorithmic-endpoint hard guarantees

| Guarantee | Pass criterion |
|---|---|
| Never empty in success path | Every `200` response returns ≥3 results (substitutes, suggestions, etc.) |
| Real DB-backed payload | Every result row has a `library_id` (or equivalent FK) — no curated synthetic names |
| Canonical surface | Every library lookup hits `exercise_library_cleaned` (the materialized view) — never raw `exercise_library` (51× slower, drifted columns) |
| Deterministic | Two requests with identical body return identical (or near-identical, top-K stable) ordering |
| Latency | p95 ≤ 500ms on warm Render (no AI inference, only DB I/O) |
| Schema correctness | Column reads match the live MV schema: `name` (not `exercise_name`), `display_body_part` (not `body_part`), `avoid_if[]` (for safety filtering). Brittle name-substring matching is forbidden when the MV exposes structured safety data. |

### BBB. /suggest-substitutes specific

Detect & flag:

| Check | Fail signal |
|---|---|
| Zero-substitute rate | `n_substitutes=0` count > 1% across a 100-scenario run |
| Library-row coverage | `substitutes_with_library_id / n_substitutes < 100%` (every result MUST come from `exercise_library_cleaned`) |
| Injury-type coverage | All 8 injury types (knee, shoulder, lower_back, elbow, wrist, hip, ankle, neck) return ≥3 substitutes when paired with ANY of the 14 muscle groups |
| Non-injury reasons | "boring", "no equipment available", "pregnant", "menstrual phase", `reason=""` all still return ≥3 results (these don't trigger injury filtering, so library should always succeed) |
| Cross-muscle expansion | When the original muscle is fully restricted by injury (e.g. knee + quads), endpoint expands to OTHER muscle groups via `INJURY_SAFE_MUSCLE_EXPANSION` — never returns empty |
| Safety filtering | `avoid_if[]` array on each library row used for contraindication match (NOT name substring). Test: ask for substitute of "Squat" with `reason="knee injury"` — none of the returned rows have "knee" in their `avoid_if` |
| Display-body-part mapping | The 15 logical muscle groups (quadriceps, hamstrings, glutes, calves, chest, back, shoulders, biceps, triceps, forearms, core, abs, cardio, lower_back, hips) all return ≥5 rows when queried directly |
| Self-exclusion | Original exercise name never appears in substitutes list |
| Equipment honored via reason | When `reason` contains "no equipment available" / "bodyweight only" / "at home", substitutes use only bodyweight/none equipment (see FFF). |
| Reason-aware result variance | Same exercise + 14 different reasons produce ≤ 50% Jaccard overlap on the substitute set (see FFF). |
| Media coverage | ≥85% of returned substitutes have a non-null `media_url` (gif → video → image COALESCE) — see FFF. |

### BBB-bis. Detailed contracts → see FFF below

The 2026-05-08 harness run (`render_suggest_substitutes_20260508_205357`,
1000 scenarios) surfaced 6 distinct bugs which were fixed in the same commit
that introduced section FFF. Use FFF for the hard contracts; BBB above is the
short-form summary.

### CCC. /quick-regenerate specific (algorithmic, no AI — pure SQL delete + activity log)

| Check | Pass criterion |
|---|---|
| Test isolation | Harness clears ALL orphan future workouts BEFORE every scenario (not just self-seeded). idx=1 should never delete N=78 orphans from prior runs. |
| Seed-step verification | If a scenario expects N seeded, harness must assert `pre_call_seeded_count == N` BEFORE invoking the endpoint. Currently many scenarios proceed with `pre_call_seeded_count=0` despite expecting non-zero. |
| Status filtering | Endpoint deletes workouts where `(is_completed=False) OR (status='generating')` AND `scheduled_date >= user_today`. Verify with both: scheduled+incomplete deletes, generating placeholders delete. |
| Timezone correctness | `user_today_date()` uses user-local timezone (TZ from device IANA via flutter_timezone), not UTC. Scenarios across America/Chicago, America/New_York, Asia/Tokyo, Pacific/Auckland, UTC midnight, DST spring-forward, DST fall-back must all classify "today" identically to user expectation. |
| user_activity logged | After every successful call, `user_activity` row inserted with `activity_type='program_quick_reset'` and `activity_data.workouts_deleted=N`. Harness must verify this. |
| Idempotency | Calling twice in succession: second call returns deleted=0 (nothing left to clear). |
| Auth | 401 on missing JWT, 403 on wrong-user JWT, 422 on malformed body, 404 on nonexistent user. |
| FK cleanup | Workout_changes rows associated with deleted workouts are also removed (idx 50 boundary case — `delete_workout_changes_by_workout` runs first, FK constraint preserved). |
| Limit boundary | If 100+ future workouts exist, all are deleted in a single call (no pagination short-circuit). |
| `expected_deleted` accounting | Harness `expected_deleted` MUST equal (orphan count cleared in isolation step) + (self-seeded count) — currently broken. |

### DDD. Harness hygiene (cross-cutting)

Every harness script (`run_*.py`) MUST satisfy:

| Check | Pass criterion |
|---|---|
| JSON cleanup | `consolidate_*` step runs at end of `main()`, folding `json/scenario_NNN.json` into CSV `raw_*_json` column and `shutil.rmtree(json/)`. Lingering `json/` dir = harness bug. |
| Shared lib | Auth, output-dir init, and write-row helpers come from `_smoke_lib.py`, not duplicated per-script. (Currently `run_quick_regenerate_validation.py` and `run_suggest_substitutes_validation.py` define their own.) |
| Pre-run state clear | Before scenario 1, harness queries the user's data and removes ANY records that would interfere (orphan future workouts, stale user_activity rows, etc.). |
| Resume-safe | `--resume auto` finds prior run dir, skips already-processed indices, resumes mid-run without losing progress. |
| Per-row CSV write | CSV row written immediately after each scenario (not batched at end). Survives kill -9. |
| Per-row JSON dump | Full request + response also dumped to `json/scenario_NNN.json`. After consolidation, this becomes the `raw_*_json` CSV column. |
| Live status MD | Top of scenarios MD has a "Live Run Status" table that updates per-scenario (visible in IDE while harness runs). |
| Pricing breakdown | At top of harness, print expected wall time + cost. End-of-run prints actual. |
| Token-aware | Every scenario sends a FRESH `apikey` JWT (no cached token leak), and reauths if a 401 is observed mid-run. |

### EEE. Schema-drift detection (cross-checks against `exercise_library_cleaned`)

The MV's columns are: `id, name, original_name, body_part, display_body_part, equipment,
target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url,
video_url, image_url, goals, suitable_for, avoid_if, single_dumbbell_friendly,
single_kettlebell_friendly`.

| Drift signal | How to detect |
|---|---|
| Endpoint reads `exercise_library` (raw) instead of `exercise_library_cleaned` | grep for `.table("exercise_library")\b` excluding `_cleaned` |
| Endpoint reads `exercise_name` instead of `name` | column doesn't exist on cleaned MV — grep `"exercise_name"` in api/ |
| Endpoint reads `body_part` for fine-grained muscle (biceps/triceps/quads/hams/glutes/calves/core/abs) | These don't exist as `body_part` values — must use `display_body_part` (16 clean values) |
| Endpoint hardcodes safety as name-substring match | Use `avoid_if[]` array instead — authoritative metadata |
| `display_body_part` value canonical list (current as of 2026-05-08) | Quadriceps, Triceps, Hamstrings, Core, Shoulders, Lower Back, Neck, Glutes, Hips, Chest, Back, Calves, Biceps, Full Body, Forearms, Rotator Cuff |
| `category` value canonical list | plyometric, yoga, core, strength, cardio, stretching, power, conditioning, functional |

### FFF. Reason-aware substitutes (post-2026-05-08 contract)

**Real-data findings** (run `render_suggest_substitutes_20260508_205357`, 1000 scenarios):

1. **Alphabetical concentration** — 86.6% of returned substitutes started with `0–9`/`A`/`B`; only 279 unique exercises across 7,596 result slots (root cause: `_query_library_by_muscle` had no `ORDER BY`).
2. **`reason` had near-zero effect** — 61/79 multi-reason exercises returned >80% identical substitute sets regardless of reason.
3. **Pregnancy safety leaks** — 10/50 pregnancy queries returned plyometric / jumping subs (`180 Jump Turns`).
4. **Knee safety leaks** — 12/88 knee queries returned knee-loading subs (`Baithak (Hindu Squat)`, walking-lunge variants, Reverse Hack Squat). Root cause: `avoid_if[]` empty for those rows + name-keyword filter wasn't checked.
5. **`gif_url` coverage 1.2%** — 978/990 success rows returned 0 `gif_url`s (MV column populated only for ~12 rows).
6. **Edge-case fallbacks collapse** — token search required `len ≥ 4` so `Sq` / `Squ` → 0 results; typo `Squet` → 0; `Cat Cow` / `Thread the Needle` → 0.
7. **No cold-start warmup** — first ~5 calls hit Render cold; max latency 7,420 ms.
8. **Plyo contraindications missing for non-knee joints** — `Box Jump + ankle sprain → 180 Jump Turns` as top sub. `INJURY_EXERCISE_CONTRAINDICATIONS` only had jump/plyo guards for `knee` and `lower_back`; `ankle`/`hip`/`wrist`/`elbow`/`shoulder`/`neck` were missing them.
9. **`all_safe_for_reason` aggregator was lying** — endpoint reported `True` for all 1000/1000 rows including the 22 (10 pregnancy + 12 knee) name-keyword violations.
10. **Reason-overlap >50% was 75/79, not 61/79** — confirmed against the 2026-05-08 CSV.
11. **Whitespace / punctuation normalization gap** — `Bench Press` → chest stretches, but `Bench  Press` (double space), `Bench-Press`, `Bench/Press`, `Bench (Press)` → completely different subs starting with `4 Corners Curtsy`.
12. **Top-3 subs were CONSTANT across reasons** — `180 Jump Turns / 4 Corners Side Step / 4 Punches Side Squat` were top-3 for `ankle sprain`, `boring`, `elbow tendinitis`, `hip pain`, `lower back pain` simultaneously.
13. **Strength queries returned stretches** — `Wall Push-Up` (strength) returned 8 stretches; no category-match scoring was in place.
14. **`boring` reason verifiably inert** — `Goblet Squat boring vs none → IoU=1.00`. Seed didn't include reason; jitter range too narrow to flip rankings.
15. **Walking-lunge variants leaked under knee data hole** — `Walking Lunges + knee → Sandbag Walking Lunge | Treadmill Walking Lunge`. Even with avoid_if backfill, the name-keyword guard didn't include those specific variants.
16. **Mid-run latency outliers** — `Thread the Needle + wrist → 7139ms` mid-run. No in-process caching of `_query_library_by_muscle`.
17. **Body-part outweighed target_muscle** — `Bicep Curl + elbow tendinitis → Archer Pull Up | Assisted Chin-Up` in top-3. Score weighted body_part match without considering the more-specific target_muscle.

**🛡️ ENFORCED IN CODE (2026-05-09):**

- `backend/api/v1/exercise_preferences_endpoints.py` — full refactor:
  - `_classify_reason()` returns a `SubstituteContext` containing `injury_type`, `intent`, `desired_equipment`, `seed`, `family_keyword`. The seed is `md5(exercise_name + reason)` — same input → stable result, different reason → different ranking.
  - `INTENT_KEYWORDS` covers 5 non-injury intents: `no_equipment`, `boring`, `pregnant`, `post_surgery`, `menstrual`.
  - `_passes_intent_filter()` applies hard filters per intent.
  - `_is_unsafe_by_name_keyword()` reuses `INJURY_EXERCISE_CONTRAINDICATIONS` + new `PREGNANCY_UNSAFE_KEYWORDS` as belt-and-suspenders.
  - `_score_candidate()` uses weighted scoring: muscle match (+0.40), token overlap (+0.20), equipment match (+0.20), media-rich (+0.10), boring-family penalty (−0.50), seeded jitter (+0..0.05).
  - Cascade: muscle search → token search (min len 3) → cross-muscle expansion (now also fires for pregnant/post-surgery, not only injury) → fuzzy RPC → generic Full Body / Core fallback.
  - `_to_substitute_exercise()` populates `media_url = COALESCE(gif_url, video_url, image_url)`; `gif_url` is also populated with the COALESCE'd value for back-compat.
  - `_build_injury_warning()` / `_build_safety_warning()` populate the previously-unused response fields.
- `backend/migrations/2039_substitutes_fuzzy_pool.sql` — new RPC `substitutes_fuzzy_search(p_search_term, p_limit)` returning full MV rows via trigram similarity (reuses GIN index from mig 159).
- `backend/migrations/2040_avoid_if_backfill.sql` — backfilled `avoid_if=['knee']` for Hindu Squat / Baithak / Hack Squat / Reverse Hack Squat / Walking Lunge variants in both `exercise_library` and `exercise_library_manual`. MV refreshed.
- `backend/scripts/_smoke_lib.py` — new `warmup_endpoint()` helper.
- `backend/scripts/run_suggest_substitutes_validation.py` — calls warmup before block 1.
- **2026-05-09 ultrathink pass (findings #8–#17):**
  - `INJURY_EXERCISE_CONTRAINDICATIONS` extended at module init: `_PLYO_KEYWORDS` (jump/plyo/clap/bound/box jump/tuck jump/broad jump/depth jump/burpee) added to **every** joint (`ankle`, `hip`, `wrist`, `elbow`, `shoulder`, `neck`, `knee`, `lower_back`). Walking-lunge variants (`sandbag walking lunge`, `treadmill walking lunge`, `weighted walking lunge`) added to `knee`.
  - `_normalize_exercise_name()` / `_normalize_for_matching()` — strip + collapse whitespace, replace `_./()-\` with space, lowercase. Applied at endpoint entry, in `get_exercise_muscle_group` lookup, in `_token_search`, and in `_is_unsafe_by_name_keyword`. `Bench Press` ≡ `Bench-Press` ≡ `Bench  Press` ≡ `Bench (Press)` now.
  - `SubstituteContext` carries `original_norm`, `original_category`, `original_target_muscle`. Populated lazily by `_lookup_original_metadata(db, ctx)` (TTL-cached).
  - `_score_candidate()` extended:
    - `+0.30` same `target_muscle` as original (most specific, outweighs body_part — finding #17)
    - `+0.20` same `display_body_part` as detected muscle (down from 0.40)
    - `+0.25` same `category` as original (strength→strength)
    - `−0.25` different `category` from original AND intent ∉ {post_surgery}
    - jitter widened from `[0, 0.05)` to `[0, 0.10)` so reason-driven seeds can flip rankings (finding #14)
  - Seed for jitter built from normalized name + reason — `boring vs none` produces non-identical orderings (verified IoU=0.00 in live run).
  - `cachetools.TTLCache(maxsize=512, ttl=300)` shared across `_cached_query_by_muscle`, `_token_search`, and `_lookup_original_metadata`. Live cold→warm: 110ms → 1ms.
  - `_to_substitute_exercise()` now computes `is_safe_for_reason` from the actual safety filter chain (was hardcoded `True`).

**Hard contracts:**

| Check | Pass criterion |
|---|---|
| Alphabetical bias | < 30% of returned names start with `A` (was 58.5%); ≥ 800 unique substitutes across 1000 calls (was 279). |
| Reason sensitivity | Same exercise + 14 different reasons produce ≤ 50% Jaccard overlap (was > 80% for 61/79). |
| Pregnancy safety | 0 substitutes contain `jump`, `plyo`, `clap`, `bound`, `box jump`, `tuck jump`, `supine`, `sit-up`, `crunch`, `prone` for any pregnant request. |
| Knee safety | 0 substitutes contain `squat`, `lunge`, `jump`, `pistol`, `bulgarian`, `hindu`, `baithak`, `hack squat` for any knee-injury request — even when `avoid_if[]` is empty (name keyword catches it). |
| `n_substitutes ≥ 3` | True for any recognized input. Acceptable to return 0 only for non-Latin script or pure gibberish (response is `intent="unrecognized"` with empty substitutes + helpful message). |
| Media coverage | ≥ 85% of returned substitutes have a non-null `media_url`. `media_url = COALESCE(gif_url, video_url, image_url)`. (Hard cap is 86.6% — that's the % of library rows with ANY media as of 2026-05-09; remaining 13.4% have no gif/video/image at all and need a follow-up backfill.) |
| Latency | p95 < 800 ms after warmup (was 1,279 ms). Max < 2,000 ms after warmup (was 7,420 ms). |
| `intent` echoed | Response always includes `intent` (one of `none|no_equipment|boring|pregnant|post_surgery|menstrual|unrecognized`). |
| `injury_warning` populated | Non-null whenever `injury_type` is detected. |
| `safety_warning` populated | Non-null for `pregnant` / `post_surgery` / `menstrual` intents. |
| Per-substitute `reason` | Every returned substitute has a non-null `reason` field with a short human explanation ("Knee-friendly alternative", "Bodyweight, no equipment needed", "Different movement pattern", etc.). |
| Pydantic schema lock | `SubstituteExercise` declares all fields explicitly — no extras passed via `**kwargs`. Adding new fields requires updating `exercise_preferences_models.py`. |
| Self-exclusion | Original exercise name never appears in substitute list (case-insensitive). |
| Library-row coverage | 100% of substitutes have non-null `library_id` (existing contract retained). |
| Plyo blocking under any joint injury | `Box Jump` / `Burpee` / `Plyo Push-Up` + any joint injury → 0 substitutes whose name contains `jump`/`plyo`/`clap`/`bound`/`box jump`/`tuck jump`/`burpee`. |
| `is_safe_for_reason` truthful | When violations exist, `is_safe_for_reason=False` MUST agree with violation count (finding #9 — was hardcoded `True`). |
| Reason-overlap regression | `>50%` Jaccard overlap count drops from 75/79 (2026-05-08 baseline) to **<10/79**. |
| Whitespace / punctuation normalization | `Bench Press`, `Bench  Press`, `Bench-Press`, `Bench/Press`, `Bench (Press)` produce **identical** top-8 (verified live 2026-05-09). |
| Top-3 differs across reasons | For any single original exercise, top-3 substitutes across 4 different reasons share **≤1 element** in common (was: identical for ankle/boring/elbow/hip simultaneously). |
| Strength→strength dominance | `Wall Push-Up` (strength) → top-3 contains **≥2 strength-category** rows (was: 8 stretches). |
| Boring reason flips ranking | `Goblet Squat boring` vs `Goblet Squat` (no reason) → Jaccard IoU `<0.30` (was: 1.00). Verified live IoU=0.00. |
| Walking-lunge guard | `Walking Lunges + knee injury` → 0 substitutes whose name contains `walking lunge` / `sandbag` / `treadmill` (verified live). |
| Cache hot path | After warmup, repeated muscle queries < 50ms (TTL cache hit). Verified live: cold=110ms, warm=1ms. |
| target_muscle outweighs body_part | Same `target_muscle` (+0.30) ranks higher than same `display_body_part` only (+0.20) — verified by `test_score_target_muscle_outweighs_body_part`. |

**Verification commands:**

```bash
# Unit tests
cd backend && .venv/bin/python -m pytest tests/test_substitutes_api.py -v

# Validation harness against deployed Render
.venv/bin/python scripts/run_suggest_substitutes_validation.py
```
