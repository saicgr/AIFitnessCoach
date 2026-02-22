# Quick Workout Engine -- Algorithm Documentation

## Table of Contents

1. [Overview](#overview)
2. [Research Citations](#research-citations)
3. [Constants with Evidence Base](#constants-with-evidence-base)
4. [Algorithm Walkthrough (7 Phases)](#algorithm-walkthrough)
5. [Strategy Pattern Architecture](#strategy-pattern-architecture)
6. [Example Walkthroughs](#example-walkthroughs)
7. [Edge Cases](#edge-cases)
8. [File Architecture](#file-architecture)

---

## Overview

### Why Rule-Based Over AI?

The Quick Workout Engine is a pure-Dart, deterministic workout generator that runs entirely on-device. It was designed as the primary generation path for time-constrained users who need a workout in under a second, not 15-30 seconds.

| Metric | Rule-Based Engine | Gemini AI Generation |
|--------|------------------|---------------------|
| **Latency** | <100ms | 15-30s (network + inference) |
| **Offline** | Full support | Requires internet |
| **Consistency** | Deterministic per inputs | Variable outputs |
| **API cost** | $0 | ~$0.001-0.003 per call |
| **Reliability** | 100% (no API failures) | Subject to rate limits, safety filters, timeouts |

The engine replaces AI inference with evidence-based constants and a strategy pattern that maps user inputs (duration, focus, difficulty, mood, injuries, equipment) to a complete workout in 7 sequential phases. Every constant in the system is derived from peer-reviewed exercise science literature.

### Design Goals

- **Sub-100ms generation** on mid-range devices
- **Zero network dependency** -- works in airplane mode
- **Research-backed defaults** -- no arbitrary "magic numbers"
- **Seamless integration** with the existing Workout model and execution screen
- **Progressive overload** via 1RM-based weight calculations when data is available
- **Injury awareness** via muscle group avoidance mapping
- **Variety** via recently-used exercise tracking and randomized selection

---

## Research Citations

### ACSM Guidelines for Exercise Prescription

The American College of Sports Medicine's *Guidelines for Exercise Testing and Prescription* (11th Edition, 2021) provides foundational recommendations for sets, reps, and rest periods across training goals:

- **Strength**: 3-6 reps, 3-5 sets, 2-5 min rest (used for `difficulty: hard/hell`)
- **Hypertrophy**: 8-12 reps, 3-4 sets, 60-120s rest (used for `difficulty: medium`)
- **Endurance**: 15-20+ reps, 2-3 sets, 30-60s rest (used for `difficulty: easy`)

These ranges directly inform the `generateSetTargets()` function in `progressive_overload.dart` and the `_baseSets` / `_setsByDifficulty` tables in `quick_workout_constants.dart`.

### NSCA Strength Training Periodization

The National Strength and Conditioning Association's *Essentials of Strength Training and Conditioning* (Haff & Triplett, 4th Edition, 2016) provides the periodization framework used for difficulty scaling:

- RPE 5-6 for deload / recovery sessions (mapped to `difficulty: easy`)
- RPE 7-8 for standard hypertrophy training (mapped to `difficulty: medium`)
- RPE 8-9 for intensive training blocks (mapped to `difficulty: hard`)
- RPE 9-10 for peaking / maximal effort (mapped to `difficulty: hell`)

The progressive RPE/RIR scheme in `generateSetTargets()` (RPE 7 -> 8 -> 9 across working sets, RIR 3 -> 2 -> 1) follows NSCA autoregulation guidelines.

### Antagonist Superset Research

**Weakley et al. (2017)** -- *"The Effects of Superset Configuration on Kinetic, Kinematic, and Perceived Exertion in the Barbell Bench Press"* (Journal of Strength and Conditioning Research):
- Antagonist supersets maintain force output within 2-3% of straight sets
- Allow 40-50% reduction in total session time
- No significant impact on velocity or power metrics

**Paz et al. (2017)** -- *"Agonist-Antagonist Paired Set Resistance Training: A Brief Review"* (Journal of Sports Science & Medicine):
- Antagonist pre-activation may enhance agonist force production via reciprocal inhibition
- EMG data shows no detrimental effect on muscle activation
- Recommended rest period between paired exercises: 60-90s

These findings justify the engine's antagonist pairings (chest/back, quads/hamstrings, biceps/triceps) with 15s intra-pair rest and 75s between-pair rest, achieving meaningful time savings without compromising training quality.

### HIIT and Tabata Protocols

**Tabata et al. (1996)** -- *"Effects of moderate-intensity endurance and high-intensity intermittent training on anaerobic capacity and VO2max"* (Medicine and Science in Sports and Exercise):
- Original protocol: 20s maximal effort / 10s rest x 8 rounds = 4 minutes
- Improved both aerobic (VO2max +14%) and anaerobic capacity (+28%) in 6 weeks
- Used as the basis for the engine's `tabata` format (5-min cardio workouts)

**Gibala et al. (2012)** -- *"Physiological adaptations to low-volume, high-intensity interval training in health and disease"* (The Journal of Physiology):
- Sprint interval training (SIT): 30s all-out / 4.5 min recovery produces comparable adaptations to continuous moderate-intensity exercise
- Reduced-exertion HIIT (REHIT): even brief protocols show significant cardiometabolic benefits
- Justifies the engine's HIIT format: 30s work / 20s rest for standard, 40s/20s for hard difficulty

### Progressive Overload Principles

**Kraemer & Ratamess (2004)** -- *"Fundamentals of Resistance Training: Progression and Exercise Prescription"* (Medicine and Science in Sports and Exercise):
- Progressive overload is the foundational principle of resistance training adaptation
- Load should be prescribed as a percentage of 1RM for individualization
- Compound exercises warrant higher volume (more sets) than isolation movements
- Warm-up sets at 50% of working weight reduce injury risk

These principles are implemented in the engine's 1RM-based weight calculation, compound vs. isolation set count differentiation, and optional warm-up set generation.

---

## Constants with Evidence Base

All constants are defined in `quick_workout_constants.dart`. Each value has an exercise science rationale.

### C1. Time Estimates (seconds per exercise, all sets included)

| Constant | Value | Rationale |
|----------|-------|-----------|
| `compoundSupersetSeconds` | 150s | ~2.5 min per superset pair: 2 exercises x 30s work + 15s transition + rest. Reflects Paz et al. paired-set timing. |
| `isolationStraightSetSeconds` | 180s | 3 min per isolation exercise: 3 sets x 30s work + 60-75s rest. ACSM hypertrophy rest guidelines. |
| `circuitExerciseSeconds` | 75s | 40s work + 20s rest + 15s transition. Circuit format minimizes rest per ACSM endurance guidelines. |
| `hiitIntervalSeconds` | 55s | 30s work + 10s rest + 15s transition. Gibala-style intervals. |
| `stretchHoldSeconds` | 80s | 30s hold x 2 sides + 10s transition + 10s breathing. ACSM flexibility recommendation: 15-60s holds. |
| `warmupMovementSeconds` | 30s | 30s per dynamic warmup movement. NSCA warm-up protocol. |
| `tabataBlockSeconds` | 240s | Full 4-minute Tabata block (8 rounds x 30s). Direct from Tabata et al., 1996. |

### C2. Warm-Up Budgets (seconds)

| Duration | Budget | Rationale |
|----------|--------|-----------|
| 5 min | 0s | No warm-up for ultra-short sessions; exercises self-warm via low-intensity first round |
| 10 min | 60s | 2 dynamic movements (NSCA minimum recommendation) |
| 15 min | 120s | 4 dynamic movements covering major joints |
| 20 min | 150s | 5 movements; standard NSCA general warm-up |
| 25 min | 180s | 6 movements; includes sport-specific preparation |
| 30 min | 240s | Full warm-up protocol: general + specific + activation |

The `getWarmupSeconds()` method falls back to the nearest lower key for non-standard durations.

### C3. Difficulty Multipliers

Each difficulty level maps to a `DifficultyMultiplier` containing volume, rest, RPE range, training goal, and fitness level.

| Difficulty | Volume | Rest | RPE | Goal | Fitness Level | Evidence |
|-----------|--------|------|-----|------|--------------|----------|
| Easy | 0.7x | 1.3x | 5-6 | Endurance | Beginner | ACSM deload / recovery session guidelines; extended rest for movement learning |
| Medium | 1.0x | 1.0x | 7-8 | Hypertrophy | Intermediate | ACSM standard hypertrophy prescription; baseline multipliers |
| Hard | 1.15x | 0.8x | 8-9 | Hypertrophy | Advanced | NSCA intensive training block; reduced rest increases metabolic stress (Schoenfeld, 2010) |
| Hell | 1.3x | 0.6x | 9-10 | Strength | Advanced | NSCA peaking phase; near-failure training with minimal rest; maximal motor unit recruitment |

**Volume multiplier** scales the base exercise/set count up or down. **Rest multiplier** scales all rest periods. Both stack multiplicatively with mood multipliers.

### C3b. Mood Multipliers

Mood multipliers adjust intensity, volume, rest, and exercise selection bias based on the user's self-reported state.

| Mood | Intensity | Volume | Rest | Exercise Bias | Rationale |
|------|-----------|--------|------|---------------|-----------|
| Energized | 1.1x | 1.1x | 0.85x | Compound | High neural readiness; capitalize with heavier loads and shorter rest (Kraemer & Ratamess, 2004) |
| Tired | 0.8x | 0.8x | 1.3x | Isolation | Reduced CNS capacity; lower load prevents injury, extended rest aids recovery (NSCA fatigue management) |
| Stressed | 1.05x | 1.0x | 0.9x | Compound | Moderate intensity catharsis; compound lifts increase endorphin release (Goldstein & Leung, 2012) |
| Chill | 0.9x | 0.95x | 1.15x | Balanced | Light session; balanced selection for enjoyment rather than performance |
| Motivated | 1.15x | 1.2x | 0.8x | Compound | Peak psychological readiness; maximize volume and intensity for adaptation (NSCA autoregulation) |
| Low Energy | 0.7x | 0.75x | 1.4x | Mobility | Minimal stress session; mobility bias reduces injury risk when sympathetic tone is low |

**Stacking example**: Hard difficulty + Tired mood:
- Volume = 1.15 * 0.8 = 0.92x (net reduction despite hard difficulty)
- Rest = 0.8 * 1.3 = 1.04x (nearly standard rest)
- Intensity = 0.8x (reduced working weights)

### C4. Sets by Duration and Difficulty

Base set counts per exercise, indexed by workout duration and difficulty.

| Duration | Easy | Medium | Hard | Hell |
|----------|------|--------|------|------|
| 5 min | 1 | 1 | 1 | 1 |
| 10 min | 1 | 2 | 2 | 2 |
| 15 min | 2 | 2 | 3 | 3 |
| 20 min | 2 | 3 | 3 | 3 |
| 25 min | 2 | 3 | 3 | 4 |
| 30 min | 3 | 3 | 4 | 4 |

ACSM recommends 2-4 sets for hypertrophy and 3-6 sets for strength. The table scales conservatively for shorter durations and increases for longer sessions where more working volume fits within the time budget. After lookup, the base sets are further scaled by the stacked volume multiplier: `adjustedSets = round(baseSets * effectiveVolume).clamp(1, 5)`.

### C5. Exercise Count Target Ranges

Separate count tables exist for four scenarios: supersets on, supersets off, cardio/HIIT, and stretch. The `getExerciseCountRange()` method returns a (min, max) tuple.

**Supersets ON** (paired exercises, so counts are higher):

| Duration | Min | Max |
|----------|-----|-----|
| 5 min | 4 | 4 |
| 10 min | 6 | 6 |
| 15 min | 6 | 8 |
| 20 min | 8 | 8 |
| 25 min | 8 | 10 |
| 30 min | 10 | 12 |

**Supersets OFF** (straight sets):

| Duration | Min | Max |
|----------|-----|-----|
| 5 min | 2 | 3 |
| 10 min | 4 | 5 |
| 15 min | 4 | 6 |
| 20 min | 5 | 7 |
| 25 min | 6 | 8 |
| 30 min | 7 | 9 |

**Cardio/HIIT** (shorter per-exercise time):

| Duration | Min | Max |
|----------|-----|-----|
| 5 min | 3 | 4 |
| 10 min | 5 | 6 |
| 15 min | 6 | 7 |
| 20 min | 7 | 8 |
| 25 min | 8 | 9 |
| 30 min | 8 | 10 |

**Stretch** (longer holds, fewer transitions):

| Duration | Min | Max |
|----------|-----|-----|
| 5 min | 4 | 5 |
| 10 min | 6 | 7 |
| 15 min | 7 | 8 |
| 20 min | 8 | 9 |
| 25 min | 9 | 10 |
| 30 min | 10 | 12 |

### C6. Antagonist Superset Pairings

| Agonist | Antagonist | Reference |
|---------|-----------|-----------|
| Chest | Back | Paz et al., 2017 |
| Shoulders | Back | Functional push/pull opposition |
| Quads | Hamstrings | Weakley et al., 2017 |
| Biceps | Triceps | Classic antagonist pair |
| Abs | Lower Back | Anterior/posterior core chain |
| Glutes | Quads | Hip extension/knee extension |
| Chest | Shoulders | Horizontal/vertical push variation |

The `getAntagonist()` method performs bidirectional lookup: given either member of a pair, it returns the other.

### C7-C8. Fallback Exercise Pools

**C7: Cardio Fallbacks** -- 15 bodyweight exercises ranging from difficulty 2 (Jumping Jacks) to difficulty 8 (Burpees), covering full_body, core, and legs. Used when the exercise library is empty or has no matching cardio exercises.

**C8: Stretch Fallbacks** -- 15 bodyweight stretches ranging from difficulty 1 (Standing Hamstring Stretch, Cat-Cow) to difficulty 3 (Pigeon Pose, World's Greatest Stretch), covering all major body parts in anatomical order. Used when no matching stretch exercises exist in the library.

### C9. Workout Name Pools

Seven themed pools with 4-5 names each:
- `strength`: "Quick Strength Blast", "Express Power Session", etc.
- `cardio`: "HIIT Express", "Quick Cardio Blast", etc.
- `stretch`: "Quick Flexibility Flow", "Express Mobility", etc.
- `full_body`, `upper_body`, `lower_body`, `core`: themed names for each

`getRandomWorkoutName()` selects randomly from the focus-specific pool, falling back to `full_body` names for unknown focus values.

---

## Algorithm Walkthrough

The engine executes 7 sequential phases within a single synchronous `generate()` call.

### Phase 1: Preparation

**Inputs**: userId, durationMinutes, focus, difficulty, mood, useSupersets, equipment, injuries, exerciseLibrary, fitnessLevel, oneRepMaxes, stapleExercises, avoidedExercises, recentlyUsedExercises.

**Operations**:

1. **Resolve effective focus**: Defaults to `full_body` when no focus is specified.
2. **Look up difficulty multiplier**: Maps `difficulty` string to `DifficultyMultiplier` (volume, rest, RPE range, goal, fitness level). Defaults to `medium` if not found.
3. **Expand injuries to avoided muscles**: Calls `expandInjuriesToMuscles(injuries)` from `injury_muscle_mapping.dart`, which maps injury body parts (e.g., "knee") to a set of muscle groups to avoid (e.g., {"quads", "hamstrings", "calves", "legs", "quadriceps", "glutes"}).
4. **Force format constraints**: Cardio and stretch focus modes disable supersets regardless of user toggle.
5. **Strategy dispatch**: Looks up the `FocusStrategy` from the `focusStrategies` map -- a one-liner map lookup, no switch statement. Falls back to `FullBodyStrategy`.
6. **Stack mood multipliers**: If mood is provided, multiply the difficulty-derived volume and rest multipliers by the mood multipliers:

```
effectiveVolume  = difficultyMultiplier.volume * moodMultiplier.volume
effectiveRest    = difficultyMultiplier.rest   * moodMultiplier.rest
intensityFactor  = moodMultiplier.intensity
exerciseBias     = moodMultiplier.exerciseBias
```

### Phase 2: Time Budget Calculation

The engine partitions total workout time into three segments:

```
totalBudget   = durationMinutes * 60                        (e.g., 1200s for 20 min)
warmupBudget  = QuickWorkoutConstants.getWarmupSeconds()    (e.g., 150s for 20 min)
buffer        = 45s                                          (constant transition buffer)
workingBudget = totalBudget - warmupBudget - buffer         (e.g., 1005s for 20 min)
```

The working budget is consumed exercise-by-exercise until exhausted.

Additionally in this phase:
- **Format resolution**: The strategy's `getFormat(useSupersets, durationMinutes)` returns one of: `supersets`, `straight`, `circuit`, `hiit`, `tabata`, `flow`.
- **Base sets lookup**: `QuickWorkoutConstants.getBaseSets(duration, difficulty)` returns the per-exercise set count.
- **Adjusted sets**: `round(baseSets * effectiveVolume).clamp(1, 5)`.

### Phase 3: Exercise Selection

The strategy provides an ordered list of `QuickMuscleSlot` objects (muscle + preferCompound flag + optional supersetPartner). The engine iterates through these slots:

```
for each slot in strategy.getSlots(duration):
    cost = strategy.timeCostPerExercise(difficulty, useSupersets)
    if runningTime + cost > workingBudget: break

    exercise = _selectExerciseForSlot(slot, library, filters...)
    if exercise == null: continue    // no match found, skip slot

    add to selectedExercises
    runningTime += cost
```

**Exercise Selection Priority** (via `exercise_selector.dart`):

1. **Filter**: Match target muscle (with aliases from `muscleAliases`), check equipment availability, exclude avoided exercises, exclude avoided muscles (from injuries), check secondary muscles don't overlap with injuries, filter difficulty for beginners (difficultyNum <= 6).
2. **Variety**: Partition candidates into "fresh" (not in `recentlyUsedExercises`) and "stale". Use fresh candidates when available; fall back to full pool otherwise.
3. **Mood bias**: Override `preferCompound` based on mood's `exerciseBias` (`compound` forces compound, `isolation` forces isolation, `balanced`/`mobility` leave as-is).
4. **Select with priority**: Staple exercises > Compound exercises (if preferred) with previously-performed preference > Previously performed (have known 1RM weights) > Random.

**Cardio-specific selection** (`_selectCardioExercise`): Searches the library for cardio-pattern keywords (jump, burpee, mountain climber, high knee, sprint, etc.), merges with the 15 built-in `cardioFallbackExercises`, applies freshness filter, and for beginners filters to `difficultyNum <= 5`.

**Stretch-specific selection** (`_selectStretchExercise`): Searches the library for stretch-pattern keywords (stretch, mobility, yoga, flexibility, hold, pose, flow, etc.), matches against target muscle aliases, merges with matching `stretchFallbackExercises`. If no muscle-specific stretches are found, falls back to any unselected stretch from the fallback pool.

### Phase 4: Set Target Generation

For each selected exercise, the engine generates set targets based on the workout format:

**Flow format** (stretch):
- Hold time: 20s (easy) / 30s (medium/hard) / 45s (hell)
- 1-2 sets (adjustedSets clamped to [1, 2])
- 8s rest between sets
- isTimed: true, holdSeconds set
- Notes: "Hold for Xs, breathe deeply"

**HIIT format**:
- Work: 30s (standard) / 40s (hell difficulty)
- Rest: 20s (standard) / 30s (easy)
- Rounds: adjustedSets clamped to [2, 4]
- isTimed: true, durationSeconds set
- Notes: "HIIT: Xs all-out / Xs recovery x N"

**Tabata format**:
- Work: 20s, Rest: 10s (fixed per Tabata protocol)
- 8 rounds (fixed, regardless of adjustedSets)
- isTimed: true, durationSeconds: 20
- Notes: "Tabata: 20s max effort / 10s rest x 8"

**Circuit format** (Core strategy without supersets):
- Work: 40s per station
- Rest: round(20 * restMultiplier)
- adjustedSets rounds
- isTimed: true, durationSeconds: 40
- Notes: "Circuit: complete all exercises, rest Xs between rounds"

**Strength format** (supersets or straight):
- Delegates to `progressive_overload.generateSetTargets()` which produces:
  - Optional warmup set at 50% working weight (compound exercises with known 1RM only)
  - Working sets with progressive RPE (7 -> 8 -> 9) and RIR (3 -> 2 -> 1)
  - Rep ranges by goal: strength 3-6, hypertrophy 8-12, endurance 15-20
- Working set count is capped at `adjustedSets` (duration-aware)
- Weights are scaled by `intensityMultiplier` (from mood)
- Rest seconds from `progressive_overload.getRestSeconds()` scaled by `restMultiplier`:
  - Strength compound: 180s * rest mult
  - Hypertrophy compound: 120s * rest mult
  - Hypertrophy isolation: 75s * rest mult
  - Endurance compound: 60s * rest mult
  - Endurance isolation: 45s * rest mult

**Superset pairing** (strength format only):
- If the current slot has a `supersetPartner` and a matching exercise exists later in the selected list:
  - Both are assigned the same `supersetGroup` counter
  - First exercise: `supersetOrder = 1`, second: `supersetOrder = 2`
  - Intra-pair rest: 15s
  - Notes: "Superset: perform both exercises back-to-back, rest 75s between pairs"
- If no partner found: exercise runs as standard straight set with normal rest

**Working weight calculation** (when 1RM data exists):
```
intensity% = getIntensityPercent(goal, fitnessLevel)
workingWeight = calculateWorkingWeight(1RM, intensity%) * moodIntensityMultiplier
```

Intensity percentages by goal and level:
- Strength: 80% (beginner), 85% (intermediate), 90% (advanced)
- Hypertrophy: 67.5% (beginner), 72.5% (intermediate), 77.5% (advanced)
- Endurance: 55% (beginner), 60% (intermediate), 65% (advanced)

Weight rounding by equipment type:
- Barbell: nearest 2.5kg
- Dumbbell: nearest 2.0kg
- Machine: nearest 5.0kg
- Cable: nearest 2.5kg
- Kettlebell: nearest 4.0kg
- Bodyweight: no rounding

### Phase 5: Format Application

This is integrated with Phase 4 above. The format determines which set-target generation branch executes. The format is selected by each strategy:

| Strategy | Supersets ON | Supersets OFF |
|----------|-------------|---------------|
| Strength | `supersets` | `straight` |
| Full Body | `supersets` | `straight` |
| Upper Body | `supersets` | `straight` |
| Lower Body | `supersets` | `straight` |
| Core | `supersets` | `circuit` |
| Cardio/HIIT | N/A (forced off) | `tabata` (<=5min) or `hiit` |
| Stretch | N/A (forced off) | `flow` |

### Phase 6: Time Validation

After building all exercise targets, the engine validates total estimated time against the budget with a +/-60 second tolerance:

```dart
var estimatedSeconds = warmupSeconds + runningTime;

// Trim exercises if over budget
while (estimatedSeconds > totalBudgetSeconds + 60 && workoutExercises.length > 2) {
    workoutExercises.removeLast();
    estimatedSeconds = warmupSeconds + workoutExercises.length *
        strategy.timeCostPerExercise(difficulty, effectiveSupersets);
}

// Clamp estimated minutes to a reasonable range
final estimatedMinutes = ceil(estimatedSeconds / 60)
    .clamp(durationMinutes - 2, durationMinutes + 2);
```

The minimum of 2 exercises is never violated. The estimated minutes are stored in the workout metadata for the UI to display.

### Phase 7: Build Workout

Constructs the final `Workout` model object:

- **id**: UUID v4
- **userId**: Passed through from caller
- **name**: Random selection from themed name pools (e.g., "Quick Strength Blast", "HIIT Express")
- **type**: Effective focus (strength, cardio, stretch, full_body, etc.)
- **difficulty**: User-selected difficulty
- **scheduledDate**: Today's date (YYYY-MM-DD)
- **isCompleted**: false
- **exercisesJson**: Serialized list of WorkoutExercise objects
- **durationMinutes**: User-requested duration
- **estimatedDurationMinutes**: Calculated estimate from Phase 6
- **generationMethod**: `'quick_rule_based'`
- **generationMetadata**: Full provenance record:
  - `generator`: 'quick_workout_engine'
  - `source`: 'quick_button'
  - `quick_workout`: true
  - `focus`, `difficulty`, `mood`, `format`
  - `exercise_count`, `duration_target`, `duration_estimated`
  - `use_supersets`, `equipment`, `injuries`
  - `had_1rm_data`: Whether any 1RM data was available
  - `variety_skipped`: Whether recently-used tracking was active
  - `generation_source`: 'quick_workout'

The Workout model is fully compatible with the server format, so the generated workout can be immediately used in the workout execution screen and later saved to the backend via `POST /api/v1/workouts/quick/save`.

---

## Strategy Pattern Architecture

```
                         FocusStrategy (abstract)
                         |  getSlots(duration)
                         |  getFormat(useSupersets, duration)
                         |  timeCostPerExercise(difficulty, useSupersets)
                         |  usesTimed, usesHolds, usesDuration
                         |
              +----------+-------------------+
              |                              |
    MuscleTargetedStrategy            (Direct subclasses)
         (abstract)                         |
         format: supersets/straight    +-----+--------+
         timeCost: base * restMult     |              |
              |                   CardioHiit     Stretch
    +---------+---------+         Strategy       Strategy
    |    |    |    |    |         format:         format:
    |    |    |    |    |          tabata/hiit     flow
    |    |    |    |    |         timed:true      holds:true
    |    |    |    |    |         duration:true   timed:true
    |    |    |    |    |
    |    |    |    |  Core
    |    |    |    |  Strategy
    |    |    |    |  format: supersets/circuit
    |    |    |    |  slots: abs/lower_back/obliques
    |    |    |    |
    |    |    |  LowerBody
    |    |    |  Strategy
    |    |    |  slots: quads/hams/glutes/calves
    |    |    |
    |    |  UpperBody
    |    |  Strategy
    |    |  slots: chest/back/shoulders/biceps/triceps
    |    |
    |  FullBody
    |  Strategy
    |  slots: all major muscle groups (8 slots)
    |
  Strength
  Strategy
  slots: full list with superset partners (12 slots)
```

**FocusStrategy** defines the interface:
- `getSlots(duration)` -- Returns ordered list of `QuickMuscleSlot` (muscle + preferCompound + supersetPartner)
- `getFormat(useSupersets, duration)` -- Returns format string: supersets, straight, circuit, hiit, tabata, or flow
- `timeCostPerExercise(difficulty, useSupersets)` -- Returns seconds per exercise for budget calculation
- `usesTimed`, `usesHolds`, `usesDuration` -- Boolean format flags

**MuscleTargetedStrategy** provides shared behavior for all strength-style strategies:
- Format: `supersets` when toggle is on, `straight` when off
- Time cost: Applies difficulty rest multiplier to base time constants
  - Supersets: `round(150 * restMultiplier)`
  - Straight: `round(180 * restMultiplier)`

**CoreStrategy** overrides format to return `circuit` instead of `straight` when supersets are off.

**CardioHiitStrategy** provides:
- Dynamic slot count based on duration (4 at 5min, up to 10 at 30min)
- All slots target `full_body` (engine fills from cardio pool)
- Format: `tabata` for durations <= 5 min, `hiit` otherwise
- Time cost: `round(55 * restMultiplier)`

**StretchStrategy** provides:
- 12 slots in anatomical flow order: hamstrings -> hip_flexors -> quads -> glutes -> calves -> chest -> shoulders -> back -> neck -> abs -> full_body -> hip_flexors
- Format: always `flow`
- Time cost: fixed 80s (not multiplied by rest for stretch format)

**Strategy Registry**: A `Map<String, FocusStrategy>` enables O(1) dispatch with no branching:
```dart
final Map<String, FocusStrategy> focusStrategies = {
  'strength':   StrengthStrategy(),
  'cardio':     CardioHiitStrategy(),
  'stretch':    StretchStrategy(),
  'full_body':  FullBodyStrategy(),
  'upper_body': UpperBodyStrategy(),
  'lower_body': LowerBodyStrategy(),
  'core':       CoreStrategy(),
};
```

---

## Example Walkthroughs

### Example 1: 20-min Strength with Supersets, Medium Difficulty, Energized Mood

**Phase 1 -- Preparation**:
- Focus: `strength`, Strategy: `StrengthStrategy`
- Difficulty: `medium` -> volume=1.0, rest=1.0, RPE 7-8, goal=hypertrophy, level=intermediate
- Mood: `energized` -> intensity=1.1, volume=1.1, rest=0.85, bias=compound
- Stacked: effectiveVolume = 1.0 * 1.1 = 1.1, effectiveRest = 1.0 * 0.85 = 0.85
- Supersets: ON (strength mode allows it)

**Phase 2 -- Time Budget**:
- Total: 20 * 60 = 1200s
- Warmup: 150s (from C2 table)
- Buffer: 45s
- Working: 1200 - 150 - 45 = 1005s
- Format: `supersets`
- Base sets: 3 (20min, medium from C4 table)
- Adjusted sets: round(3 * 1.1) = 3

**Phase 3 -- Exercise Selection**:
- Time cost per exercise: round(150 * 0.85) = 128s (superset pair cost * rest multiplier)
- Maximum exercises: 1005 / 128 = ~7.8, so up to 7 exercises fit

StrengthStrategy slot iteration:
1. Chest (compound, partner=back) -> e.g., Bench Press -> 128s (running: 128)
2. Back (compound, partner=chest) -> e.g., Barbell Row -> 128s (running: 256)
3. Quads (compound, partner=hamstrings) -> e.g., Barbell Squat -> 128s (running: 384)
4. Hamstrings (compound, partner=quads) -> e.g., Romanian Deadlift -> 128s (running: 512)
5. Shoulders (compound, partner=biceps) -> e.g., Overhead Press -> 128s (running: 640)
6. Biceps (isolation, partner=triceps) -> e.g., Barbell Curl -> 128s (running: 768)
7. Triceps (isolation, partner=biceps) -> e.g., Skull Crushers -> 128s (running: 896)
8. Abs (isolation) -> 128s would make 1024 -- exceeds 1005, STOP

Result: 7 exercises selected.

**Phase 4 -- Set Targets** (strength format with supersets):
- Superset Group 1: Bench Press (order 1) + Barbell Row (order 2)
- Superset Group 2: Barbell Squat (order 1) + Romanian Deadlift (order 2)
- Superset Group 3: Barbell Curl (order 1) + Skull Crushers (order 2)
- Shoulders: no partner found in remaining list -> straight sets
- Each compound with 1RM: 1 warmup set (50% 1RM, maxReps+2) + 3 working sets
- Working weight example (Bench 1RM=100kg): 72.5% intensity * 1.1 mood = 79.75kg -> rounded to 80kg (barbell, 2.5kg increment)
- RPE progression: 7, 8, 9 across working sets; RIR: 3, 2, 1
- Superset rest: 15s intra-pair, notes mention 75s between pairs
- Shoulders rest: 120s * 0.85 = 102s (hypertrophy compound)

**Phase 6 -- Time Validation**:
- Estimated: 150 + 896 = 1046s = 17.4min
- Clamped to [18, 22] -> 18 min estimate (within +/-2 of 20)

**Phase 7 -- Build**:
- Name: random from ["Quick Strength Blast", "Express Power Session", "Rapid Strength Hit", "Speed Strength", "Power Express"]
- generationMethod: `quick_rule_based`
- Metadata records all parameters for analytics

---

### Example 2: 5-min Cardio/HIIT (Tabata), Hard Difficulty

**Phase 1 -- Preparation**:
- Focus: `cardio`, Strategy: `CardioHiitStrategy`
- Difficulty: `hard` -> volume=1.15, rest=0.8, RPE 8-9, goal=hypertrophy, level=advanced
- No mood selected
- Supersets: forced OFF (cardio focus)

**Phase 2 -- Time Budget**:
- Total: 5 * 60 = 300s
- Warmup: 0s (5-min sessions skip warm-up per C2 table)
- Buffer: 45s
- Working: 300 - 0 - 45 = 255s
- Format: `tabata` (duration <= 5)
- Base sets: 1 (5min, hard from C4 table)
- Adjusted sets: round(1 * 1.15) = 1

**Phase 3 -- Exercise Selection**:
- Time cost per exercise: round(55 * 0.8) = 44s
- CardioHiitStrategy hardcodes 4 exercises for 5-min duration
- All 4 slots target `full_body`

Selection from cardio library + fallback pool:
1. Burpees (difficulty 8, suitable for advanced) -> 44s (running: 44)
2. Mountain Climbers (difficulty 5) -> 44s (running: 88)
3. Jump Squats (difficulty 6) -> 44s (running: 132)
4. High Knees (difficulty 3) -> 44s (running: 176)

All 4 fit within 255s budget.

**Phase 4 -- Set Targets** (Tabata format):
- Fixed Tabata protocol: 20s work / 10s rest x 8 rounds
- Each exercise gets 8 SetTarget entries with targetHoldSeconds=20
- durationSeconds: 20, restSeconds: 10, isTimed: true
- Notes: "Tabata: 20s max effort / 10s rest x 8"

**Phase 6 -- Time Validation**:
- Estimated: 0 (no warmup) + 176 = 176s
- Clamped to [3, 7] -> 5 min estimate

**Phase 7 -- Build**:
- Name: random from ["HIIT Express", "Quick Cardio Blast", "Rapid Fire Cardio", "Cardio Surge", "Burn Express"]

---

### Example 3: 15-min Stretch Flow, Easy Difficulty

**Phase 1 -- Preparation**:
- Focus: `stretch`, Strategy: `StretchStrategy`
- Difficulty: `easy` -> volume=0.7, rest=1.3, RPE 5-6, goal=endurance, level=beginner
- No mood selected
- Supersets: forced OFF (stretch focus)

**Phase 2 -- Time Budget**:
- Total: 15 * 60 = 900s
- Warmup: 120s (from C2 table)
- Buffer: 45s
- Working: 900 - 120 - 45 = 735s
- Format: `flow`
- Base sets: 2 (15min, easy from C4 table)
- Adjusted sets: round(2 * 0.7) = 1

**Phase 3 -- Exercise Selection**:
- Time cost per exercise: 80s (stretchHoldTimeCost, not scaled by rest for stretch)
- Maximum exercises: 735 / 80 = ~9

StretchStrategy slots (anatomical flow order):
1. Hamstrings -> Standing Hamstring Stretch -> 80s (running: 80)
2. Hip Flexors -> Hip Flexor Stretch -> 80s (running: 160)
3. Quads -> Standing Quad Stretch -> 80s (running: 240)
4. Glutes -> Pigeon Pose -> 80s (running: 320)
5. Calves -> Calf Stretch -> 80s (running: 400)
6. Chest -> Chest Doorway Stretch -> 80s (running: 480)
7. Shoulders -> Shoulder Cross-Body Stretch -> 80s (running: 560)
8. Back -> Cat-Cow -> 80s (running: 640)
9. Neck -> Neck Circles -> 80s (running: 720)
10. Abs -> would be 800, exceeds 735 budget, STOP

Result: 9 stretches selected.

**Phase 4 -- Set Targets** (flow format):
- Hold time: 20s (easy difficulty -> `difficulty == 'easy' ? 20 : ...`)
- 1 set per exercise (adjustedSets=1, clamped to [1, 2])
- Rest: 8s between stretches
- isTimed: true, holdSeconds: 20
- Notes: "Hold for 20s, breathe deeply"

**Phase 6 -- Time Validation**:
- Estimated: 120 (warmup) + 720 (9 exercises * 80s) = 840s = 14min
- Clamped to [13, 17] -> 14 min estimate

**Phase 7 -- Build**:
- Name: random from ["Quick Flexibility Flow", "Express Mobility", "Rapid Recovery", "Flex Express", "Stretch & Release"]

---

## Edge Cases

### 1. Empty Exercise Cache -> Fallback Pools

When `exerciseLibrary` is empty (no cached exercises from the server):

- **Cardio focus**: The `_selectCardioExercise` method merges library results (empty) with `QuickWorkoutConstants.cardioFallbackExercises` -- 15 built-in bodyweight cardio exercises (Jumping Jacks, Burpees, Mountain Climbers, etc.). Workouts always generate successfully.
- **Stretch focus**: The `_selectStretchExercise` method merges library results (empty) with `QuickWorkoutConstants.stretchFallbackExercises` -- 15 built-in stretch exercises (Standing Hamstring Stretch, Hip Flexor Stretch, etc.). Always produces a valid stretch flow.
- **Strength focus**: `selector.filterExercises()` on the empty library returns no candidates for each slot. After all slots are processed, if `selectedExercises.length < 2`, the `_addFallbackExercises` method injects bodyweight exercises from the cardio fallback pool (as generic full-body options).

The engine guarantees at least 2-3 exercises in every generated workout, regardless of cache state.

### 2. Severe Injuries -> Minimum Exercise Guarantee

When a user reports multiple injuries (e.g., shoulder + knee + lower_back), the avoided muscle set can become very large:

```
shoulder   -> {shoulders, chest, triceps, delts, anterior_delts, lateral_delts, rear_delts}
knee       -> {quads, hamstrings, calves, legs, quadriceps, glutes}
lower_back -> {lower_back, back, erector_spinae, glutes, hamstrings}
```

This potentially eliminates most exercises. The engine handles this with a post-selection safety check:

```dart
if (selectedExercises.length < 2) {
    _addFallbackExercises(selected, focus, alreadySelected, avoidedMuscles, difficulty);
}
```

`_addFallbackExercises` iterates through the appropriate fallback pool and adds exercises whose `targetMuscle` is NOT in the avoided set. It stops after reaching 3 exercises. Even in extreme cases, at least 2-3 full-body bodyweight exercises (e.g., Jumping Jacks with targetMuscle `full_body`, Inchworms with targetMuscle `hamstrings`) should pass through, since `full_body` as a target muscle typically does not appear in injury avoidance lists.

### 3. Equipment Mismatch -> Bodyweight Fallback

Equipment filtering follows these rules:

- **Empty equipment list**: Treated as `['bodyweight']` only (NOT "all equipment allowed"). This prevents generating barbell/dumbbell exercises for users who forgot to select equipment.
- **Bodyweight always passes**: Any exercise with equipment containing "bodyweight", "body weight", "none", or empty string passes regardless of equipment selection.
- **No matches for slot**: If `filterExercises()` returns empty for a specific muscle slot, the engine returns `null` and the slot is skipped (`continue`). The time budget is not consumed, allowing more exercises from later slots.

Worst case: a user with no equipment and no cached exercises gets a full bodyweight workout from the fallback pools.

### 4. Variety Mechanism (SharedPreferences + Last 5 Workouts)

The engine prevents repetitive workouts across sessions using a multi-layer approach:

1. **Recently Used Tracking**: The provider passes `recentlyUsedExercises` -- a `Set<String>` of lowercase exercise names from the last 5 quick workouts, persisted in SharedPreferences.

2. **Fresh-first selection**: For each slot, candidates are partitioned into "fresh" (not recently used) and "stale":
   ```dart
   final freshCandidates = candidates
       .where((ex) => !recentlyUsedExercises.contains(name))
       .toList();
   final pool = freshCandidates.isNotEmpty ? freshCandidates : candidates;
   ```
   Fresh candidates are preferred. Only when ALL candidates are recently used does the engine fall back to the full pool.

3. **Within-workout deduplication**: `alreadySelectedNames` tracks all exercises chosen so far in the current workout, preventing any exercise from appearing twice.

4. **Randomized selection**: When multiple candidates survive all filtering, `selectForSlot()` and the cardio/stretch selectors use `Random` for final selection, providing natural variety even without the recently-used mechanism.

### 5. Superset Partner Not Found -> Degrade to Straight Sets

When a slot specifies `supersetPartner` but no matching partner exercise exists in the selected list:

```dart
final partnerIdx = _findPartnerIndex(selectedExercises, i, slot.supersetPartner, pairedIndices);
if (partnerIdx != null) {
    // Pair found: assign superset group, set intra-pair rest to 15s
} else {
    // No partner: exercise runs as standard straight set
    // No supersetGroup or supersetOrder is assigned
    // Rest period uses standard progressive_overload.getRestSeconds()
}
```

The exercise simply runs as a straight set with normal rest periods. There is no error or degraded experience -- the exercise just does not get the superset label in the UI.

Common scenarios where this happens:
- Partner muscle's exercises were all filtered out by injury avoidance
- Partner exercise was already selected for a different pairing
- Equipment filter eliminated all exercises for the partner muscle
- The time budget was exhausted before reaching the partner's slot

---

## File Architecture

```
mobile/flutter/lib/services/
|
+-- quick_workout_engine.dart          Main engine class (670 lines)
|   - QuickWorkoutEngine.generate()    7-phase generation pipeline
|   - _selectExerciseForSlot()         Delegates to exercise_selector + variety logic
|   - _selectCardioExercise()          Cardio-specific selection with keyword matching
|   - _selectStretchExercise()         Stretch-specific selection with muscle aliases
|   - _findPartnerIndex()              Superset partner matching in selected list
|   - _addFallbackExercises()          Minimum exercise guarantee (2-3 exercises)
|   - _SelectedExercise                Internal tracking class (exercise + slot + time + superset info)
|
+-- quick_workout_constants.dart       All evidence-based constants (399 lines)
|   - DifficultyMultiplier             Data class: volume, rest, RPE, goal, fitness level
|   - MoodMultiplier                   Data class: intensity, volume, rest, exercise bias
|   - QuickWorkoutConstants            Static constant tables and lookup methods:
|     - C1: Time estimates             Seconds per exercise type (7 constants)
|     - C2: Warm-up budgets            Duration -> warmup seconds (6 entries)
|     - C3: Difficulty multipliers     4 difficulty levels with 6 parameters each
|     - C3b: Mood multipliers          6 mood states with 4 parameters each
|     - C4: Sets by duration           Duration x difficulty matrix (6x4 = 24 entries)
|     - C5: Exercise count ranges      4 tables, each with 6 duration entries
|     - C6: Antagonist pairs           7 bidirectional muscle pairings
|     - C7: Cardio fallbacks           15 bodyweight cardio exercises
|     - C8: Stretch fallbacks          15 bodyweight stretch exercises
|     - C9: Workout name pools         7 categories with 4-5 names each
|
+-- quick_workout_templates.dart       Strategy pattern implementation (258 lines)
|   - QuickMuscleSlot                  Data class: muscle + preferCompound + supersetPartner
|   - FocusStrategy (abstract)         Interface: getSlots, getFormat, timeCost, boolean flags
|   - MuscleTargetedStrategy (abstract) Shared base for 5 strength-style strategies
|   - StrengthStrategy                 12 slots, full superset pairing, compound-first
|   - FullBodyStrategy                 8 slots, one per major muscle group
|   - UpperBodyStrategy                7 slots, push/pull focus
|   - LowerBodyStrategy                6 slots, legs + glutes
|   - CoreStrategy                     6 slots, circuit format option when supersets off
|   - CardioHiitStrategy               Dynamic slot count (4-10), tabata/hiit format
|   - StretchStrategy                  12 slots in anatomical flow order
|   - focusStrategies                  Map<String, FocusStrategy> registry (7 entries)
|
+-- exercise_selector.dart             Shared exercise filtering and selection (196 lines)
|   - filterExercises()                Multi-criteria filter (muscle, equipment, injury, level)
|   - selectForSlot()                  Priority: staple > compound > known 1RM > random
|   - _isLikelyCompound()             Heuristic compound detection (24 name patterns)
|
+-- progressive_overload.dart          1RM-based weight and set target generation (227 lines)
|   - calculateWorkingWeight()         1RM * intensity%, rounded to equipment increment
|   - getIntensityPercent()            Goal + fitness level -> intensity percentage
|   - detectEquipmentType()            Equipment string -> category (6 types)
|   - generateSetTargets()             Warmup + working sets with RPE/RIR progression
|   - getRestSeconds()                 Goal + compound/isolation -> rest period in seconds
|   - getDefaultReps()                 Goal -> default rep count for display
|
+-- injury_muscle_mapping.dart         Injury -> muscle avoidance (121 lines)
|   - injuryToAvoidedMuscles           Map<String, List<String>> (14 injury types)
|   - expandInjuriesToMuscles()        Flattens injury list to avoided muscle set
|
+-- workout_templates.dart             Shared utilities
    - muscleAliases                    Canonical muscle -> alias list for fuzzy matching

mobile/flutter/lib/screens/workout/widgets/
|
+-- quick_workout_sheet.dart           Bottom sheet UI (792 lines)
    - showQuickWorkoutSheet()          Entry point, manages nav bar visibility
    - _QuickWorkoutSheet               ConsumerStatefulWidget with all selectors:
    |                                    Duration (5/10/15/20/25/30 min)
    |                                    Focus (7 options)
    |                                    Mood (6 options)
    |                                    Difficulty (4 levels)
    |                                    Supersets toggle
    |                                    Equipment (6 options, multi-select)
    |                                    Injuries (8 options, multi-select)
    - _DurationCard                    Duration chip widget
    - _FocusChip                       Focus/mood chip widget with icon + color
    - _ToggleChip                      Equipment/injury toggle chip widget

mobile/flutter/lib/data/providers/
|
+-- quick_workout_provider.dart        Riverpod state management (220 lines)
    - QuickWorkoutState                isGenerating, statusMessage, generatedWorkout, error
    - QuickWorkoutNotifier             Calls API endpoint, manages generation lifecycle
    - quickWorkoutProvider             Main StateNotifierProvider
    - isQuickWorkoutGeneratingProvider Convenience bool provider
    - generatedQuickWorkoutProvider    Convenience Workout? provider
    - quickWorkoutErrorProvider        Convenience String? provider
    - quickWorkoutPreferencesProvider  FutureProvider for user preferences

backend/api/v1/workouts/
|
+-- quick.py                           POST /api/v1/workouts/quick/save endpoint
                                       Persists locally-generated workouts to Supabase
```

### Reused Infrastructure

| Component | Source File | Used For |
|-----------|------------|----------|
| `filterExercises()` | `exercise_selector.dart` | Multi-criteria exercise filtering |
| `selectForSlot()` | `exercise_selector.dart` | Priority-based exercise selection |
| `generateSetTargets()` | `progressive_overload.dart` | Warmup + working sets with RPE/RIR |
| `getRestSeconds()` | `progressive_overload.dart` | Goal-based rest period calculation |
| `calculateWorkingWeight()` | `progressive_overload.dart` | 1RM -> working weight conversion |
| `expandInjuriesToMuscles()` | `injury_muscle_mapping.dart` | Injury -> avoided muscle expansion |
| `muscleAliases` | `workout_templates.dart` | Muscle name normalization |
| `OfflineExercise` | `offline_workout_generator.dart` | Exercise data model for local use |
| `Workout`, `WorkoutExercise`, `SetTarget` | `data/models/workout.dart` | Output model |

---

*Last updated: 2026-02-20*
*Engine version: 1.0*
