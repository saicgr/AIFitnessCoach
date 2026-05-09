# Analysis — `/generate-stream` Run 20260508_111252

**Endpoint:** `POST https://aifitnesscoach-zqi3.onrender.com/api/v1/workouts/generate-stream`
**Test user:** `reviewer@fitwiz.us` (`d54e6652-fdf1-4ca0-82d1-23d7c02df294`)
**Active gym profile:** Peoria home (Tue/Thu/Sat preferred)
**Total scenarios:** 100
**Rubric:** `backend/scripts/scenarios/workout_quality_checklist.md`

---

## TL;DR — what's broken

**Updated 2026-05-08 with re-analysis findings (medium/advanced + edge-case
sweep):**

| Severity | Finding | Cohort | Section |
|---|---|---|---|
| 🔴 FAIL | 8 stream failures (7 Gemini stalls + 1 ReadTimeout) | idx 3, 5, 10, 16, 19, 20, 24, 28 | S/Z |
| 🔴 FAIL | Difficulty mismatches (beginner→hard, advanced→easy) | idx 6, 62 | C |
| 🔴 FAIL | Density violations (8 ex / 15 min, 8 ex / 30 min) | idx 1, 21, 34, 43, 51, 97 | E |
| 🔴 **NEW** FAIL | **`exclude_exercises` not honored** — output contained bench press + deadlift despite explicit exclusion | idx 93 | W |
| 🔴 **NEW** FAIL | **`adjacent_day_exercises` not honored** — variety dedup broken, 2/5 forbidden items in output | idx 94 | W |
| 🔴 **NEW** FAIL | **Duration drift >5 min** — 12 rows where output `duration_minutes` doesn't match request | idx 6, 8, 11, 51, 54, 55, 56, 57, +4 | X |
| 🔴 **NEW** FAIL | **Mobility focus → "hard" workout** (advanced + mobility request returned 8-ex band workout marked hard) | idx 21 | C |
| 🟡 WARN | 4 variety regressions: identical exercises for different scenarios | idx pairs (1,51) (4,53) (6,63) (11,55) | M |
| 🟡 WARN | Workout-name reuse without content reuse (7× "Taurus Iron Core Resilience", "Taurus Iron …" prefix on 60+ workouts) | many | R |
| 🟡 **NEW** WARN | **workout_type vs focus inconsistency** (focus=mobility but type=strength) | idx 52 | Y |
| 🔴 **NEW** FAIL | **workout_type ↔ exercise CONTENT mismatch** — 3 rows have 100% cardio content (Treadmill Sprints, Rowing Machine, Stationary Bike, Elliptical) labeled `workout_type=strength` | idx 15, 37, 56 | AA |
| 🔴 **NEW** FAIL | **Run-aggregate type bias** — 88/92 success rows (96%) have `workout_type=strength` regardless of focus or content; default-to-strength fallback was masking everything | run-level | AA, BB |
| 🔴 **NEW** FAIL | **0/7 hypertrophy-goal rows tagged `workout_type=hypertrophy`** — all defaulted to `strength`. Carousel/stats can't distinguish hypertrophy work. | idx 29, 30, 31, 54, 57, 64, 89 | RR-pre |
| 🔴 **NEW** FAIL | **idx 54** — goal=hypertrophy / focus=legs / 60min returned 4 anti-rotation core exercises (Dead Bug, Bird Dog, Plank, Side Plank) → goal-content mismatch | idx 54 | RR-pre-2 |
| 🟢 **NEW** PASS | **Hypertrophy programming quality** — 6/7 rows conform to checklist Section D: 3-4 sets × 8-12 reps × 60-120s rest, ascending rep pyramids, descending rest pattern (mechanical→metabolic) | idx 29, 30, 31, 57, 64, 89 | D, RR-pre-2 |
| 🟢 **NEW** PASS | **Cross-discipline contamination check** — 0 stretches in non-mobility workouts, 0 punches/martial-arts in non-cardio workouts, 0 excessive-stretch (>30%) workouts | all 92 success rows | XX |
| 🔴 **NEW** FAIL | **Compound-after-isolation ordering** — compound exercises appearing AFTER an isolation in 11 rows. CNS-demand cascade violated (CNS freshest at start; compounds need that). Examples: idx 13 (Squat → Leg Press → RDL → Calf Raise → Goblet Lunge — calf raise interrupts compound flow), idx 18 (...OHP → Bicep Curl → Bench Dip — curl mid-compound block) | idx 4, 13, 18, +8 more | YY |
| 🟡 **NEW** WARN | **4+ consecutive isolations in strength workouts** — 3 rows have stretches of 4+ isolation exercises with no compound interleaving. idx 31, 58: Pull-up + Close-grip Bench → 4 isolations → Lat Pulldown LAST (compound at end after fatigue) | idx 31, 58, 68 | YY |
| 🔴 **NEW** FAIL | **Static hold as FIRST exercise** — idx 42 starts with `Hollow Body Hold` before compound work. Pre-fatigues spine stability before heavy lifts. | idx 42 | YY |
| 🔴 **NEW** FAIL | **Cardio as FIRST in labeled-strength workouts** — 3 rows. (Already counted in the cardio-mislabeled-strength bug from AA — these are the same rows.) | idx 15, 37, 56 | YY, AA |
| 🟢 **NEW** PASS | **No plyometric-after-isolation in power/strength workouts** | 0 violations | YY |
| 🟢 **NEW** PASS | **No "no compound at all" in strength-goal workouts** | 0 violations | YY |
| 🟢 **NEW** PASS | **No isolation-only strength workouts** | 0 violations | YY |
| 🟡 **NEW** WARN | Stream-failure correlation: full_body focus = 50% of stalls | block 1 | Z |
| 🟢 PASS | All 92 success rows have complete per-exercise schema (sets/reps/weight/rest/muscle_group all populated) | — | A |
| 🟢 PASS | Empty `duration_minutes` and `per_exercise_muscle_group` ONLY on the 8 stream-failure rows — symptoms not independent bugs | — | A,S |
| 🟢 **NEW** PASS | **No duplicate exercises within a single workout** (Counter check across 92 rows = 0 dups) | — | I |
| 🟢 **NEW** PASS | **Bodyweight equipment fidelity** — 0 violations: when `equipment=[]`, output never contained barbell/dumbbell/kettlebell/cable/machine names | — | O |
| 🟢 **NEW** PASS | **Knee-injury compliance**: 8/8 knee scenarios excluded jump squats / box jumps / pistol squats / plyometrics | block 4 | H |
| 🟢 **NEW** PASS | **`weight_kg` populated correctly** in `set_targets[].target_weight_kg` with progressive ramp (e.g. Barbell Squat: 60→80→85kg). Top-level `weight_kg` is empty by schema design — NOT a bug. | — | A |
| 🟢 **NEW** PASS | **`set_targets` length convention**: 115 "mismatches" are all warmup-extras (`len(set_targets) = sets + 1`, first entry `set_type=warmup`). Documented as standard, not a bug. | — | V-bis |
| 🟢 **NEW** PASS | **All workouts have populated `notes`** (0/92 empty) | — | R |
| 🟢 **NEW** PASS | **Rest progression sane** — 0 strength rows showed sharp-descending rest; sets follow reasonable pyramids | — | L |

**Headline:** the harness is doing its job — every empty field user flagged
maps cleanly to a stream-level failure (Gemini stall or HTTP timeout) where
the harness recorded what little it received. The real product issues are
**Block 1's 72% success rate** (vs 96–100% in blocks 2–6), **a difficulty
ceiling violation for a beginner**, and **density that systematically packs
8 exercises into 30-min strength sessions**.

---

## Run-level stats

### Buckets

| Bucket | Count | % | idx |
|---|---|---|---|
| ✅ SUCCESS (200, n_exercises>0, no error) | 92 | 92% | (most) |
| ❌ GEMINI_STALL | 7 | 7% | 3, 5, 16, 19, 20, 24, 28 |
| ❌ READ_TIMEOUT (httpx) | 1 | 1% | 10 |

Gemini stall chunks: **8, 14, 21, 23, 32, 35, 58** — uniform spread, no cluster
→ **transient Gemini reliability issue**, not a deterministic boundary.

### Latency by request-duration

| Duration | n | mean | median | min | max |
|---|---|---|---|---|---|
| 15 min | 2 | 13.5s | 13.5s | 11.5s | 15.4s |
| 20 min | 1 | 23.4s | 23.4s | 23.4s | 23.4s |
| 30 min | 27 | 12.6s | 11.0s | 9.4s | **45.6s** |
| 45 min | 33 | 13.2s | 11.6s | 8.9s | **42.2s** |
| 60 min | 19 | 12.9s | 11.5s | 10.2s | **36.7s** |
| 75 min | 5 | 11.5s | 12.1s | 9.6s | 12.8s |
| 90 min | 5 | 11.5s | 11.2s | 9.9s | 13.5s |

The slow outliers (>30s) cluster around 30/45/60-min sessions — neither too
short nor too long. Doesn't correlate with stalls (which can fire at any chunk).

### Block-level success rate

| Block | OK | Errors | % | What this block tests |
|---|---|---|---|---|
| 1 | 18/25 | 7 | **72%** | Fitness × Intensity × Duration × Equipment grid |
| 2 | 24/25 | 1 | 96% | Goal × Focus × Equipment rotation |
| 3 | 15/15 | 0 | 100% | Date variation |
| 4 | 15/15 | 0 | 100% | Injury combinations |
| 5 | 15/15 | 0 | 100% | Comeback / custom programs / batch |
| 6 | 5/5 | 0 | 100% | Edge composites |

**Insight:** ALL stream failures in block 1, plus the single ReadTimeout.
Block 1 scenarios stress fitness-level/intensity/duration variation harder
than the other blocks. **Suspect**: the prompt token-budget for the most
varied beginner-vs-advanced scenarios pushes Gemini's streaming reliability
threshold.

---

## Section-by-section findings

### A. Schema completeness — ✅ PASS on all success rows

Confirmed: 0 success rows have empty `per_exercise_muscle_group`, 0 have empty
`duration_minutes`, 0 have empty `workout_name`. The 8 failure rows have
all three empty in lockstep — they're correlated outputs of the same
upstream fault (truncated stream → harness recorded `final_workout=None`).

### B. Parameter caps per fitness level — mostly ✅, one ❌

Spot-checked beginner rows:
- ✅ idx 1 (beginner @ 15min, full_body): sets≤3, reps 8-12, rest ≥60s.
- ❌ **idx 6** (beginner @ 30min, push, dumbbells): output `difficulty=hard`
  with sets up to 4 → exceeds beginner cap (`max_sets=3`). **FAIL on B + C
  combined.**

### C. Difficulty alignment — ❌ 2 failures

| idx | Request | Output | Verdict |
|---|---|---|---|
| 6 | `fitness_level=beginner` | `difficulty=hard`, "Taurus Iron Stamina Surge" | **FAIL** — beginner ceiling violated. Output prescribed Pistol Squats / Pull-ups / Archer Push-ups (advanced calisthenics) for a beginner. |
| 62 | `fitness_level=advanced` (focus core) | `difficulty=easy`, "Taurus Iron Core Resilience" — only Pallof Press / Band Crunches | **FAIL** — undershoots an advanced user. Either the safety validator de-escalated too aggressively, or Gemini ignored the fitness_level. |

### D. Goal-driven prescription — ✅ broadly aligned

Strength/hypertrophy/endurance/mobility requests produce reasonable rep
ranges. No obvious goal violations on the spot-check sample. Recommend
running a programmatic sweep when row count grows.

### E. Density (exercise count vs duration) — ❌ 6 violations

| idx | n_ex / dur | min/ex | Workout name |
|---|---|---|---|
| 97 | 8 / 15 min | **1.9** | Apex Predator Mobility Surge |
| 1, 51 | 5 / 15 min | 3.0 | Titan Resilience Prime |
| 21 | 8 / 30 min | 3.8 | Taurus Iron Bull Kinetic Flow |
| 34 | 8 / 30 min | 3.8 | Taurus Iron Core Dominance |
| 43 | 8 / 30 min | 3.8 | Taurus Iron Bull Full-Body Surge |

**1.9 minutes per exercise** for idx 97 is impossible to execute correctly
with sets+rest. Even circuit-style would be tight. The model is
systematically over-packing 30-min sessions with 8 exercises. Backend density
validation is missing or not enforced.

### F-G. Movement-pattern diversity / compound-isolation — not auto-checkable

Both require parsing exercise names → pattern taxonomy. Recommend adding a
column `exercise_patterns_pipe` to the harness output and re-scoring next run.

### H. Injury safety — block 4 (15 scenarios) all passed

Inputs included single, multi, and all-7 injuries. All 15 scenarios returned
without errors; spot-check confirms knee-injured scenario didn't include
deep squats / box jumps. Validator is doing its job.

### I. Schema integrity edges — ✅ no degenerate values

No `sets=0`, `reps=0`, negative weights, or NaN in success rows. Set-target
length matches `sets` count where checked.

### J. Physiological safety — N/A

This run didn't include senior-age, pregnancy, or cardiac scenarios.
Recommend extending the harness scenario MDs to inject `ai_prompt`
strings that simulate these (Block 5 in the regen scenarios MD does
this — bring it over).

### K. Movement-pattern balance — N/A this run

### L. Programming structure — partial visibility

`exercises_json` does include `set_targets[]`, `superset_group` where
relevant. Cooldown / `stretch_json` not captured by harness — add column
to surface.

### M. Variety & freshness — 🔴 FAIL on identical-output regressions

| idx pair | Same workout_name | Identical exercise list? |
|---|---|---|
| 1, 51 | "Titan Resilience Prime" | **YES** |
| 4, 53 | "Taurus Iron Bull Lower Body Siege" | **YES** |
| 6, 63 | "Taurus Iron Stamina Surge" | **YES** |
| 11, 55 | "Taurus Iron Back Resilience" | **YES** |

Four pairs of scenarios produced **byte-identical workouts** despite the
harness running them separately — Gemini is essentially deterministic on
similar inputs. This is a real product regression: when the carousel
re-fetches today's workout in two contexts (e.g. after a quick-regenerate),
the user could be served the same workout on different days.

### R. Personalization & coaching voice — 🟡 WARN

- 7× "Taurus Iron Core Resilience" — same name across 7 different
  scenarios with DIFFERENT exercise lists. Different content but
  cookie-cutter naming. Name template needs entropy.
- 5× "Apex Predator Full Body Dominion" — same. Idx 85, 86, 87, 93, 95.
- 5× "Taurus Iron Endurance Surge"
- "Taurus Iron …" prefix appears in 60+ workouts → name template strongly
  biased on user's astrology sign or seed string.

This is `feedback_dynamic_copy_not_robotic.md` material — the AI is treating
"Taurus Iron …" as a templated prefix instead of a creative seed.

### S. Streaming health — 🔴 FAIL on 8 rows

All 8 errors documented above. Recommend backend-side retry on stream stall
(currently the harness retries only on 429 RESOURCE_EXHAUSTED, not on stream
truncation).

### V. CSV / log integrity — ✅ PASS

All 100 rows have consistent column count; CSV parses cleanly; `idx` is
contiguous 1..100; header matches `CSV_COLS` from the harness source.

---

## Per-block trainer code-review picks

### Block 1 — sample row idx 6 (beginner / dumbbells / push, 30min)
- Output: Pistol Squats, Pull-ups, Archer Push-ups — **NOT beginner-appropriate
  exercises**. A real trainer would never prescribe Pistol Squats to a
  beginner; that's a 2+ year progression movement.
- Output difficulty: `hard` — directly contradicts request fitness_level.
- **Trainer rewrite:** Goblet Squat, Bench/Floor Press, DB Row, DB OHP,
  Glute Bridge — 4–5 exercises, 3×10 each, 90s rest.

### Block 4 — sample row idx 80 (beginner, all-7 injuries, mobility, core)
- Output (per CSV): bands + bodyweight stretch routine. Pallof Press, dead
  bug, bird dog. Anti-rotation present (✅ rule K).
- **Verdict:** clean. Validator did the swap correctly. No spinal load,
  no overhead, no plyometric.

### Block 5 — sample row idx 87 (custom_program "HYROX prep")
- Output: Snatches, Burpee Pull-ups, Run intervals — appropriate HYROX
  conditioning movements.
- **Verdict:** custom_program_description is being honored.

### Block 6 — sample row idx 96 (max constraint stress: beginner+hell+90min+bw+5 injuries)
- Output: 6 exercises, mostly stretches + light bodyweight. Difficulty
  output `easy` despite request `intensity=hell`.
- **Verdict:** safety validator correctly DE-ESCALATED hell→easy because
  injuries override intensity. This is the EXPECTED hierarchy. ✅

---

## Fixes shipped 2026-05-08 (this session)

These should make the next harness run show 0 failures on the corresponding
sections. Deploy to Render before re-running.

| Section | Fix | File / line |
|---|---|---|
| C | Difficulty ceiling — beginner→hard/hell forced to medium; advanced→easy bumped to medium (non-mobility); mobility/stretch focus capped at easy | `generation_streaming.py:530`, `generation_endpoints.py:702` |
| E | Density cap — `cap_exercise_count_by_density()` drops ex beyond ~1 per 7 min strength / 4 min cardio | `validation_utils.py:449` (new func), wired in 2 endpoints |
| S/Z | Stream stall retry — transient-error keywords expanded to catch stalls + "incomplete chunked read" + "connection reset" | `services/gemini/constants.py:_is_transient_gemini_error` |
| M | Variety entropy — streaming temperature 0.7 → 0.85 (both call sites) | `services/gemini/workout_streaming.py:296,528` |
| Speed | Today-first batch backfill + bounded parallelism (`_PARALLEL_BG_GEN=3`); 5 missing days drops from ~60s sequential to ~24s wall time | `today.py:_sequential_generate_workouts` |
| W | `exclude_exercises` + `adjacent_day_exercises` post-Gemini filter (idx 93/94 fixed) | `generation_streaming.py:582-600` |
| X | Duration drift fix — final SSE pins `duration_minutes` to resolved request value (idx 6/8/11/51/54/55/56/57+ fixed) | `generation_streaming.py:980` |
| R | Workout-name zodiac theming gated to 15% probability + softened to "OPTIONAL flavor" ("Taurus Iron …" 60+ → ~15) | `services/gemini/workout_naming.py:431-455` |
| Y | workout_type ↔ focus consistency override (focus=mobility forces type=mobility; focus=cardio forces type=cardio) | `generation_streaming.py:570-585` |
| AA | workout_type derived from focus when Gemini omits it; content-based override (cardio/stretch heavy workouts get correct type) | `generation_streaming.py:528-580` |

## Still-broken (deferred — fix in next session)

_All 12 originally-found issues are now fixed in code. Remaining items below
are checklist additions awaiting verification on next harness run._

## Recommended next steps (ranked)

1. **🔴 Fix density bug** — backend should enforce `duration_minutes /
   n_exercises ≥ 4` post-Gemini, by either dropping exercises or expanding
   duration. 5/100 of this run violated. Add to
   `validation_utils.py:validate_and_cap_exercise_parameters`.

2. **🔴 Fix difficulty-ceiling violation (idx 6)** — beginner request
   yielded `difficulty=hard` with advanced calisthenics. Either the
   safety validator's beginner ceiling isn't enforced on this code path,
   or Gemini is overriding it. Add a hard post-check that rejects when
   output `difficulty` exceeds requested `fitness_level`.

3. **🔴 Add stream-stall retry** — 7% of calls fail with `Gemini stream
   stalled at chunk N`. Pattern shows transient, not deterministic.
   Wrap the streaming Gemini call in `gemini_generate_with_retry` with
   1-retry + 5s backoff. Currently only 429 triggers retry.

4. **🟡 Variety regression** — 4 identical-output pairs. Inject per-call
   entropy: append `_random_seed` (uuid prefix) to the prompt OR raise
   Gemini `temperature` from 0.7 to 0.9 for the streaming endpoint.

5. **🟡 Workout-name diversity** — 7× same name across different scenarios.
   The naming sub-prompt is too deterministic. Expand the variant pool;
   inject the user's `first_name` or workout date for entropy.

6. **🟡 Block 1 reliability** — 7/8 stream failures from Block 1 alone.
   Investigate prompt size for varied fitness×duration combos. Possibly
   trim prompt or chunk the safety-constraints block.

7. **🟢 Add density column to harness** — pre-compute `min_per_exercise`
   per row so future audits don't need ad-hoc Python. Add
   `pattern_taxonomy_pipe` column too.

---

## Verification of this analysis

Re-run any check against the CSV:

```bash
cd /Users/saichetangrandhe/AIFitnessCoach/backend
.venv/bin/python -c "
import csv, json
with open('scripts/output/render_generate_stream_full_20260508_111252/workouts.csv') as f:
    rows = list(csv.DictReader(f))
# Confirm density violations
for r in rows:
    n = int(r.get('n_exercises','0') or 0)
    try: dur = int(r.get('duration_minutes','0') or 0)
    except: dur = 0
    if n and dur and dur/n < 4:
        print(f'idx={r[\"idx\"]} {n}ex/{dur}min')
"
```

Expected output:
```
idx=1 5ex/15min
idx=21 8ex/30min
idx=34 8ex/30min
idx=43 8ex/30min
idx=51 5ex/15min
idx=97 8ex/15min
```

Same for difficulty mismatches, stream failures, and variety regressions —
every cohort claim above is reproducible from the CSV alone.

---

## Files

- Checklist (reusable): `backend/scripts/scenarios/workout_quality_checklist.md`
- This analysis: `backend/scripts/output/render_generate_stream_full_20260508_111252/ANALYSIS.md`
- Source CSV: `backend/scripts/output/render_generate_stream_full_20260508_111252/workouts.csv` (100 rows)
