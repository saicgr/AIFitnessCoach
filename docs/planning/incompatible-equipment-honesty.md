# Honesty on Incompatible Equipment Picks (Studio + Program Editor)

**Status:** Design doc only — not implemented. (2026-06-24)

## The report
> "Selecting Rowing Machine for an Upper day yields no matching exercises. Use the existing
> Impact preview in the studio to surface 'No Upper-Body exercises use Rowing Machine' instead
> of silently ignoring it … if no signal exists, compute client-side: chosen equipment not
> present in any resulting exercise."

## Factual finding (investigated against the live DB)
The premise "rowing machine exercises don't exist" is **false** — there are **18 rowing-machine
exercises**:
- `exercise_library` (base): **6**, all classified `body_part=cardio, category=cardio`
  — "Gym Rowing Machine Fast/Normal/Sprint Speed" (+ _female).
- `exercise_library_manual`: **12** — "Rowing Machine Easy / Moderate / Intervals / Arms Only /
  Legs Only / Pick Drill".

**Why the pick still yields nothing on an Upper day:** rowing is a **cardio-classified, full-body
/ posterior-chain** movement. An "Upper" (or strength-style) focus filters the candidate pool to
upper-body *strength* exercises, and the cardio-tagged rowing rows don't satisfy that focus →
**0 matches for `{equipment: Rowing Machine} ∩ {focus: Upper, style: strength}`**. So this is an
**equipment×focus×style incompatibility**, not missing data. The same class of mismatch happens
for e.g. SkiErg/treadmill on an upper-strength day, or a leg-press machine on an arms day.

## Current state — the feature ALREADY mostly exists
This is an **enhancement of existing behavior**, not new construction:

1. **Client-side unsatisfied-equipment compute (works today):**
   `mobile/flutter/lib/screens/workout/customization_studio_sheet.dart`
   - `_unsatisfiedEquipment()` (≈L815–842): returns the user's explicitly-chosen equipment tokens
     that **no exercise in the current preview** (main + warmup + cooldown) actually uses, by
     canonical-token comparison.
   - `_buildUnsatisfiedEquipmentNote()` (≈L1079–1112): renders an **amber banner** —
     `"No exercises in this workout use: <labels>"`.
   - Recomputed live on every debounced preview (`_runPreview`, ≈L149).

2. **Backend constraint signal (generic):** `POST /workouts/customize`
   (`backend/api/v1/workouts/studio.py`) → `workout_builder.build_adapted_workout()` returns
   `BuiltWorkout.relaxed_constraints: List[str]` (model: `data/models/workout_studio_models.dart`,
   ≈L40–51,146–149). On under-fill the builder broadens equipment and appends a human string
   like *"Broadened equipment to find enough exercises."* It does **not** say WHICH equipment was
   dropped. (Equipment filtering: `exercise_rag/service.py` `fetch_safe_candidates` ≈L205–216 +
   `filters.py` `filter_by_equipment` ≈L658–807; rejects are logged "equipment mismatch" but not
   returned.)

**Conclusion:** there IS already both a client-side compute AND a backend signal. The gaps are
(a) the message isn't **focus-aware**, (b) it likely isn't wired in **every** equipment-picking
surface, (c) the backend signal is too coarse to power rich messaging.

## What to improve (the actual work)

### 1. Make the message focus-aware (highest value, low effort)
Today: *"No exercises in this workout use: Rowing Machine."*
Target: *"No Upper-Body exercises use Rowing Machine."* — include the active focus/split so the
user understands the *incompatibility*, not just non-use. The studio already has the chosen
`focus_areas` (`_params`) — interpolate the human focus label into
`_buildUnsatisfiedEquipmentNote()`. Optionally suggest a fix: *"Rowing Machine is a cardio
movement — add it on a Cardio/Conditioning day, or pick dumbbells/cable for Upper."*

### 2. Wire it into every equipment-picking surface
`_unsatisfiedEquipment()` lives only in `customization_studio_sheet.dart`. The same honesty must
appear wherever a user picks equipment for a session/day and a preview/exercise set results:
- **Program editor** (unified 6-step editor — see `project_program_editing_overhaul`) per-day
  equipment / per-day gym (`PER_DAY_GYM_ASSIGNMENT`).
- **Equipment edit on an existing workout** (`edit_workout_equipment_sheet.dart`) — after a swap,
  surface any chosen equipment that ended up unused.
Extract the compute into a shared helper (e.g. `unsatisfiedEquipment(chosen, exercises)`),
reuse everywhere.

### 3. (Optional) Typed backend signal for richer, scalable honesty
Add `unsatisfied_equipment: List[{token, reason, suggestion}]` to `BuiltWorkout` and compute it
in `workout_builder` after RAG selection (it already knows the chosen equipment vs. the final
exercise set). Reasons: `no_match_for_focus`, `cardio_only_equipment`, `relaxed_to_bodyweight`.
This lets non-studio paths (adapt/shuffle/auto-regen) be honest too, and lets the message name
*why* (e.g. "Rowing Machine is cardio-only"). Path A (client-only) is enough for the studio; do
Path B only if we want this honesty on server-driven generation surfaces.

## Decision tree (what to show, per scenario)
For each user-**explicitly-chosen** equipment token `E` and the resulting preview:
- `E` used by ≥1 preview exercise → **nothing** (it's satisfied).
- `E` unused AND `E` exists in the library but only under categories incompatible with the focus
  (e.g. rowing = cardio on an Upper/strength day) → **"No <Focus> exercises use <E>. <E> is a
  <category> movement — try it on a <compatible-focus> day."**
- `E` unused AND `E` has no library coverage at all → **"No exercises use <E> yet."** (different,
  rarer — true data gap.)
- Multiple unused `E`s → list them; if ALL chosen equipment is unsatisfied, make it prominent
  (the workout silently became bodyweight/other).
Never silently drop the pick (matches `feedback_no_silent_fallbacks`).

## Notes / data nuance
- Rowing/SkiErg/treadmill/bike etc. are intentionally `category=cardio`. Reclassifying rowing as
  "back/upper" would make it appear in upper-strength pools — probably **not** desired (it's a
  conditioning tool). Better to keep the classification and be **honest in the UI** than to
  mis-tag the data. (If we ever want "rowing as a back finisher," that's a separate tagging
  decision, not part of this honesty fix.)
- Canonicalization already exists (`_canonEquip`) — reuse it so "Rowing Machine" vs
  "rowing_machine" vs "rowing machine" compare correctly.

## Verification (when implemented)
- Studio: pick **Rowing Machine** + **Upper** focus → amber banner reads *"No Upper-Body
  exercises use Rowing Machine"* (not the generic version), preview still builds (bodyweight/
  other), pick is never silently honored.
- Pick a *compatible* combo (Rowing Machine + Cardio/Full-body) → **no** banner, rowing appears.
- Same behavior in the program editor + equipment-edit sheet (after shared-helper extraction).
- Backend (only if Path B): `/workouts/customize` response includes `unsatisfied_equipment` with
  the right token + reason for the Rowing-Machine-on-Upper case.

## Files (reference)
- `mobile/flutter/lib/screens/workout/customization_studio_sheet.dart` — `_unsatisfiedEquipment`,
  `_buildUnsatisfiedEquipmentNote`, `_canonEquip`, `_runPreview`.
- `mobile/flutter/lib/data/models/workout_studio_models.dart` — `WorkoutBuildParams`,
  `BuiltWorkout.relaxedConstraints`.
- `mobile/flutter/lib/data/services/workout_studio_service.dart` — `/workouts/customize` call.
- `mobile/flutter/lib/screens/workout/widgets/edit_workout_equipment_sheet.dart` — equipment edit.
- `backend/api/v1/workouts/studio.py`, `backend/services/workout_builder.py`,
  `backend/services/exercise_rag/{service,filters}.py`.
