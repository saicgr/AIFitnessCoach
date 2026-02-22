# Training Formats & Advanced Techniques Research

**Date:** 2026-02-20
**Purpose:** Evidence-based algorithms for EMOM, AMRAP, drop sets, rest-pause, myo-reps, cluster sets, movement patterns, and minimum effective dose — for FitWiz quick workout engine.

---

## TOPIC 1: EMOM (Every Minute on the Minute)

### 1.1 Key Research

**Barba-Ruiz et al. (2024)**
"Muscular performance analysis in 'cross' modalities: comparison between AMRAP, EMOM and RFT configurations."
*Frontiers in Physiology* 15:1358191.
- DOI: 10.3389/fphys.2024.1358191
- PMID: 38505710 | PMC: PMC10950031
- Key finding: EMOM produced the **least velocity loss** across sets (8-12%) vs AMRAP (18-25%) and RFT (20-30%)
- EMOM preserves movement quality better due to built-in rest management
- Heart rate was lower in EMOM (~75-80% HRmax) vs AMRAP (~85-90% HRmax)

**Barba-Ruiz et al. (2021)**
"Analysis of Pacing Strategies in AMRAP, EMOM, and FOR TIME Training Models during 'Cross' Modalities."
*Sports* 9(11):144.
- DOI: 10.3390/sports9110144 | PMC: PMC8624389
- EMOM pacing is **self-regulated** by the clock — most stable output across rounds
- Athletes naturally reduce rep speed in final 25% of EMOM sessions

### 1.2 EMOM Algorithm for Quick Workouts

**Rep Prescription per Minute:**

| Exercise Type | Beginner | Intermediate | Advanced |
|---------------|----------|-------------|----------|
| Heavy Compound (squat, deadlift) | 3-4 reps | 5-6 reps | 6-8 reps |
| Light Compound (push-up, row) | 6-8 reps | 8-10 reps | 10-12 reps |
| Isolation | 8-10 reps | 10-12 reps | 12-15 reps |
| Bodyweight Cardio (burpee, jump) | 5-6 reps | 8-10 reps | 10-12 reps |

**Work-to-Rest Ratio Within Each Minute:**
- Target: 30-40 seconds work, 20-30 seconds rest
- If work exceeds 45 seconds, reduce reps by 1-2 next round
- Minimum rest: 15 seconds (safety floor)

**When to Use EMOM:**
- Duration: 8-20 minutes optimal (shorter = too few rounds, longer = excessive fatigue)
- Goal: Strength-endurance, power, or conditioning
- NOT ideal for pure hypertrophy (insufficient time under tension per set)

**Fatigue Management:**
- Rounds 1-4: Full prescribed reps
- Rounds 5-8: May reduce by 1 rep if completion time exceeds 45s
- Rounds 9+: Auto-reduce by 1-2 reps to maintain quality

**Format Selection:**
```
exercises_per_minute = 1 (alternating EMOM) or 2 (couplet EMOM)
total_rounds = duration_minutes
reps_per_exercise = base_reps * difficulty_multiplier
estimated_work_time = reps * time_per_rep(exercise_type)
rest_time = 60 - estimated_work_time
if rest_time < 15: reduce reps by 1
```

---

## TOPIC 2: AMRAP (As Many Rounds As Possible)

### 2.1 Key Research

**Barba-Ruiz et al. (2024)** (same as above)
- AMRAP produced the **highest total volume** but also the **greatest velocity loss** (18-25%)
- Heart rate averaged 85-90% HRmax — highest metabolic demand
- Pacing: "reverse J-shaped" — fast start, dip in middle, slight rally at end

**Pacing Research (Barba-Ruiz et al. 2021, PMC8624389):**
- Optimal pacing: Start at 85-90% of max pace, maintain steady effort
- "All-out" pacing leads to 30% performance drop in final third
- Experienced athletes use "even pacing" for better total work

### 2.2 AMRAP Algorithm

**Exercises per Round:**

| Duration | Exercises/Round | Rep Range | Notes |
|----------|----------------|-----------|-------|
| 5 min | 3 | 5-8 each | Minimal, high-intensity |
| 10 min | 3-4 | 8-12 each | Standard conditioning |
| 15 min | 4-5 | 10-15 each | Endurance-focused |
| 20 min | 5-6 | 8-12 each | Hero WOD-style |

**Movement Pattern Distribution per Round:**
- Must include: 1 push, 1 pull, 1 lower body
- Optional: 1 core, 1 cardio burst
- Alternate bilateral/unilateral across exercises

**Difficulty Scaling:**
- Easy: -20% reps, simpler exercise variations
- Medium: Standard prescription
- Hard: +20% reps, complex variations
- Hell: +30% reps, add plyometric elements

**Scoring:**
```
estimated_round_time = sum(exercise_reps * time_per_rep + transition_time)
target_rounds = duration / estimated_round_time
actual_rounds = user_completes (tracked in workout)
performance_ratio = actual_rounds / target_rounds
```

---

## TOPIC 3: Drop Sets

### 3.1 Key Research

**Coleman et al. (2023)**
"Effects of Drop Sets on Skeletal Muscle Hypertrophy: A Systematic Review and Meta-analysis."
*Sports Medicine - Open* 9:59.
- PMID: 37523092 | PMC: PMC10390395
- Drop sets produce **equivalent hypertrophy** to traditional sets when volume is matched
- Drop sets are **more time-efficient** — achieve same stimulus in ~40% less time
- Best for: isolation exercises and machine-based movements
- Diminishing returns after 2-3 drops

**Schoenfeld & Grgic (2018)**
"Can Drop Set Training Enhance Muscle Growth?"
*Strength and Conditioning Journal* 40(6):95-98.
- Recommended weight reduction: 20-25% per drop
- Optimal drops: 2-3 (beyond 3 provides minimal additional stimulus)
- No rest between drops (strip weight immediately)

### 3.2 Drop Set Algorithm

```dart
class DropSetConfig {
  final int numDrops;           // 2-3
  final double dropPercent;     // 0.20-0.25 per drop
  final int repsPerDrop;        // "to near-failure" or RPE 9-10
  final int restBetweenDrops;   // 0-10 seconds (minimal)

  // For a 20kg working weight with 2 drops at 25%:
  // Set 1: 20kg x 8-10 reps (to near failure)
  // Drop 1: 15kg x 6-8 reps (to near failure)
  // Drop 2: 11kg x 6-8 reps (to near failure)
}
```

**When to Use:**
- Best for: Last exercise of a muscle group, isolation movements
- NOT for: First exercise (need full strength), heavy compounds (safety risk)
- Time-constrained workouts: Replace 3 traditional sets with 1 drop set (saves ~3-4 min)

---

## TOPIC 4: Rest-Pause

### 4.1 Key Research

**Prestes et al. (2019)**
"Strength and Muscular Adaptations After 6 Weeks of Rest-Pause vs. Traditional Multiple-Sets Resistance Training in Trained Subjects."
*Journal of Strength and Conditioning Research* 33:S108-S116.
- PMID: 28617715
- Rest-pause produced **similar strength and hypertrophy** to traditional sets
- Total session time reduced by ~30%

**Korak et al. (2021)**
"Rest-pause and drop-set training elicit similar strength and hypertrophy adaptations compared with traditional sets in resistance-trained males."
*Journal of Sports Sciences* 40(9):1038-1048.
- PMID: 34260860
- Both rest-pause and drop sets are viable time-efficient alternatives

### 4.2 Rest-Pause Algorithm

```
Protocol:
1. Perform initial set to near-failure (RPE 9-10)
2. Rest 15-20 seconds
3. Perform 2-4 additional reps with same weight
4. Rest 15-20 seconds
5. Perform 1-3 additional reps
6. Done (total time: ~90 seconds vs ~5 minutes for 3 traditional sets)

Rep prescription:
- Initial set: target RPE 9 (1-2 RIR)
- Mini-set 1: ~50% of initial reps
- Mini-set 2: ~30% of initial reps

Example: 10 reps initial → 5 reps → 3 reps = 18 total reps
```

---

## TOPIC 5: Myo-Reps

### 5.1 Key Research

**Fagerli, B. (2012)**
"Myo-Reps: The Secret Norwegian Method to Build Lean Muscle in 70% Less Time."
- Creator's protocol definition
- Based on "effective reps" theory (Dankel et al. 2017)

**Barbell Medicine (2023)** — Protocol Summary:
- Activation set: 12-20 reps at RPE 8-9 (close to failure)
- Back-off mini-sets: 3-5 reps each
- Rest between mini-sets: 3-5 deep breaths (~10-15 seconds)
- Stop when: Can't complete target mini-set reps OR RPE reaches 10
- Typically 3-5 mini-sets after activation

### 5.2 Myo-Reps Algorithm

```dart
class MyoRepsConfig {
  final int activationReps;    // 12-20 reps to RPE 8-9
  final int miniSetReps;       // 3-5 reps
  final int restSeconds;       // 10-15 seconds (3-5 breaths)
  final int maxMiniSets;       // 3-5
  final int stopRpe;           // 10 (can't complete target)

  // Total effective reps: activation(last ~5) + all mini-set reps
  // Example: 15 activation + 4x5 mini-sets = 35 total, ~25 "effective"
}
```

**When to Use:**
- Best for: Isolation exercises, time-constrained sessions
- NOT for: Heavy compounds (fatigue-safety concern)
- Ideal duration savings: Replaces 4-5 traditional sets in ~2-3 minutes

---

## TOPIC 6: Cluster Sets

### 6.1 Key Research

**Frontiers (2024)**
"Cluster sets lead to better performance maintenance and minimize training-induced fatigue than traditional sets."
*Frontiers in Sports and Active Living* 6:1467348.
- Cluster sets maintained **higher velocity** across all reps
- Ideal for power and strength goals where bar speed matters

**PMC (2024)**
"Cluster sets and traditional sets elicit similar muscular hypertrophy."
*PMC: PMC12174233*
- When volume-matched, hypertrophy is equivalent
- Cluster sets better for maintaining quality of each rep

### 6.2 Cluster Set Algorithm

```
Protocol:
- Intra-set rest: 15-30 seconds between every 1-3 reps
- Total reps per cluster: Same as traditional set (e.g., 6 reps)
- Rest between clusters: Normal inter-set rest

Example (6 reps with clusters of 2):
  2 reps → 20s rest → 2 reps → 20s rest → 2 reps → full rest

Best for: Power day in DUP rotation, compound lifts
```

---

## TOPIC 7: Movement Pattern Classification

### 7.1 The 7 Fundamental Patterns (NSCA)

| Pattern | Examples | Primary Muscles |
|---------|----------|----------------|
| **Squat** | Back squat, goblet squat, leg press | Quads, glutes |
| **Hinge** | Deadlift, Romanian DL, hip thrust | Hamstrings, glutes, erectors |
| **Push (Horizontal)** | Bench press, push-up, chest fly | Chest, anterior delts, triceps |
| **Push (Vertical)** | Overhead press, pike push-up | Shoulders, triceps |
| **Pull (Horizontal)** | Barbell row, cable row, dumbbell row | Lats, rhomboids, biceps |
| **Pull (Vertical)** | Pull-up, lat pulldown | Lats, biceps |
| **Carry/Core** | Farmer walk, plank, pallof press | Core, grip, stabilizers |

### 7.2 Pattern Diversity Algorithm

For a balanced quick workout, enforce minimum pattern coverage:

```
// Minimum patterns per workout duration:
5 min:  2 patterns (1 push + 1 pull, or 1 upper + 1 lower)
10 min: 3 patterns (push + pull + lower)
15 min: 4 patterns (push + pull + squat + hinge)
20 min: 5 patterns (push + pull + squat + hinge + core)
30 min: 6 patterns (all)

// Pattern tracking for variety:
pattern_freshness[pattern] = e^(-0.3 * sessions_since_last_use)
prefer_patterns_with_lower_freshness
```

**Source:** NSCA Progressive Strategies for Teaching Fundamental Resistance Training Movement Patterns (PTQ 10.2)

---

## TOPIC 8: Minimum Effective Dose

### 8.1 Key Research

**Androulakis-Korakakis et al. (2020)**
"The Minimum Effective Training Dose Required to Increase 1RM Strength in Resistance-Trained Men."
*Sports Medicine* 50:751-765.
- PMID: 31797219
- **1 set at 70-85% 1RM** is the minimum effective dose for strength gains
- Trained individuals: ~4 sets/muscle/week minimum for continued progress
- Untrained: Even 1 set produces significant strength gains

**PMC (2024)**
"Resistance Exercise Minimal Dose Strategies for Increasing Muscle Strength in the General Population."
*Sports Medicine* (PMC: PMC11127831)
- Single-set protocols effective for beginners and time-constrained individuals
- Multi-set protocols (3+) provide dose-dependent benefits for intermediates

### 8.2 Minimum Dose Algorithm for Quick Workouts

```
// For a 5-minute workout:
minimum_sets_per_exercise = 1 (if trained) or 1 (if untrained)
minimum_exercises = 2-3
minimum_intensity = 70% 1RM (or RPE 7)

// For a 10-minute workout:
minimum_sets_per_exercise = 2
minimum_exercises = 3-4

// For a 15-minute workout:
minimum_sets_per_exercise = 2-3
minimum_exercises = 4-5

// Weekly accumulation target:
// Track total sets per muscle group across all sessions
// Aim for MEV (Minimum Effective Volume) per muscle per week
// Quick workouts contribute partially to weekly targets
```

### 8.3 Proximity to Failure Research

**Robinson et al. (2023)**
"Influence of Resistance Training Proximity-to-Failure on Skeletal Muscle Hypertrophy."
*Sports Medicine* 53:649-665.
- PMID: 36334240 | PMC: PMC9935748
- Training within **5 RIR** produces meaningful hypertrophy
- Training to failure (0 RIR) provides marginal additional benefit
- **RPE 7+ (3 RIR)** is the practical threshold for "stimulating" sets

**Lim & Lee (2024)**
"Similar muscle hypertrophy following eight weeks of resistance training to momentary muscular failure or with repetitions-in-reserve."
*Journal of Sports Sciences*.
- PMID: 38393985
- 0 RIR vs 2 RIR: **No significant difference** in hypertrophy
- Supports using RPE 8-9 (1-2 RIR) as the working target

---

## IMPLEMENTATION PRIORITY

| Priority | Feature | Time Saved | Effort |
|----------|---------|-----------|--------|
| 1 | EMOM format | High (auto-paced) | Medium |
| 2 | AMRAP format | High (conditioning) | Medium |
| 3 | Drop sets (last exercise) | 3-4 min/exercise | Low |
| 4 | Myo-reps (isolation) | 2-3 min/exercise | Low |
| 5 | Rest-pause | 2-3 min/exercise | Low |
| 6 | Movement pattern diversity | Quality improvement | Medium |
| 7 | Cluster sets (power day) | Quality improvement | Low |
| 8 | Minimum dose validation | Safety/correctness | Low |

---

## FULL CITATION LIST

1. Barba-Ruiz et al. (2024) "Muscular performance analysis in 'cross' modalities: comparison between AMRAP, EMOM and RFT configurations." Front. Physiol. 15:1358191. PMID: 38505710
2. Barba-Ruiz et al. (2021) "Analysis of Pacing Strategies in AMRAP, EMOM, and FOR TIME Training Models." Sports 9(11):144. PMC: PMC8624389
3. Coleman et al. (2023) "Effects of Drop Sets on Skeletal Muscle Hypertrophy: A Systematic Review and Meta-analysis." Sports Med Open 9:59. PMID: 37523092
4. Schoenfeld & Grgic (2018) "Can Drop Set Training Enhance Muscle Growth?" Strength Cond J 40(6):95-98
5. Prestes et al. (2019) "Strength and Muscular Adaptations After 6 Weeks of Rest-Pause vs. Traditional Multiple-Sets." JSCR 33:S108-S116. PMID: 28617715
6. Korak et al. (2021) "Rest-pause and drop-set training elicit similar adaptations." J Sports Sci 40(9):1038-1048. PMID: 34260860
7. Fagerli B. (2012) "Myo-Reps: The Secret Norwegian Method." borgefagerli.com
8. Androulakis-Korakakis et al. (2020) "Minimum Effective Training Dose for 1RM Strength." Sports Med 50:751-765. PMID: 31797219
9. Robinson et al. (2023) "Proximity-to-Failure on Skeletal Muscle Hypertrophy." Sports Med 53:649-665. PMID: 36334240
10. Lim & Lee (2024) "Similar hypertrophy: failure vs repetitions-in-reserve." J Sports Sci. PMID: 38393985
11. NSCA (2016) "Progressive Strategies for Teaching Fundamental Resistance Training Movement Patterns." PTQ 10.2
12. Dankel et al. (2017) "The last 5 reps before failure are the effective reps." JSCR
