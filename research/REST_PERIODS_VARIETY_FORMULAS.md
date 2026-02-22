# Deep Research Findings for Quick Workout Engine Improvements

**Date:** 2026-02-20
**Purpose:** Evidence-based algorithms, formulas, and citations for improving FitWiz's quick workout generation engine.

---

## TOPIC 1: REST PERIOD OPTIMIZATION

### 1.1 Key Meta-Analyses and Systematic Reviews

**Primary Citation (2024):**
Singer A, Wolf M, Generoso L, et al. "Give it a rest: a systematic review with Bayesian meta-analysis on the effect of inter-set rest interval duration on muscle hypertrophy." *Front. Sports Act. Living* 6:1429789 (2024).
- DOI: 10.3389/fspor.2024.1429789
- PMID: 39205815
- 9 studies, 19 measurements, 313 participants
- Short rest SMD: 0.48 (95%CrI: 0.19-0.81)
- Long rest SMD: 0.56 (95%CrI: 0.24-0.86)
- **Key finding:** Substantial overlap between short and long rest for hypertrophy. Rest >60s shows small benefit; >90s shows no appreciable additional benefit.

**De Salles et al. (2009):**
De Salles BF, Simao R, Miranda F, et al. "Rest interval between sets in strength training." *Sports Med* 39(9):765-777 (2009).
- PMID: 19691365
- Foundational review establishing goal-based rest recommendations

**Schoenfeld et al. (2016):**
Schoenfeld BJ, Pope ZK, et al. "Longer interset rest periods enhance muscle strength and hypertrophy in resistance-trained men." *J Strength Cond Res* 30(7):1805-1812 (2016).
- PMID: 26605807
- 3-minute rest > 1-minute rest for both strength AND hypertrophy in trained men

**Willardson (2006):**
Willardson JM. "A brief review: factors affecting the length of the rest interval between resistance exercise sets." *J Strength Cond Res* 20(4):978-984 (2006).
- PMID: 17194236
- Rest should be individualized based on training goal AND exercise type

**Henselmans & Schoenfeld (2014):**
"The effect of inter-set rest intervals on resistance exercise-induced muscle hypertrophy." *Sports Med* 44(12):1635-1643 (2014).
- PMID: 25047853
- Previous short-rest recommendations for hypertrophy were based on acute hormonal responses, NOT longitudinal hypertrophy data
- No study found superior hypertrophy with shorter rest

**2025 Meta-Analysis (preprint):**
"Investigating the impact of less than or greater than 60 seconds of inter-set rest on muscle hypertrophy and strength increases in males with >1 year of resistance training experience."
- medRxiv: 10.1101/2025.09.22.25336351v1
- Longer rest led to small improvements in both hypertrophy and strength in trained males

### 1.2 Does Rest Period Matter Less Than Previously Thought?

**YES, for hypertrophy specifically:**

The 2024 Singer et al. Bayesian meta-analysis is the most definitive evidence. Key nuances:

1. **Untrained individuals:** Rest period has negligible effect on arm and whole-body hypertrophy (SMD = 0.02 and -0.05). Slight benefit from longer rest for quadriceps only (SMD = 0.17).
2. **Trained individuals:** Trend favors longer rest (>=90s), but insufficient data for strong conclusion.
3. **Threshold finding:** Rest <60s appears suboptimal. Beyond 60s, differences are small.
4. **For strength:** Rest period matters MORE. Longer rest (2-5 min) clearly superior for maximal strength development.

**Practical minimum thresholds (below which adaptation is impaired):**
- Hypertrophy: 60 seconds (below this, volume completion suffers)
- Strength: 120 seconds (insufficient phosphocreatine recovery)
- Power: 180 seconds (ATP-PC system needs full recovery)
- Endurance: 30 seconds (shorter rest is the stimulus itself)

### 1.3 Rest Periods in Superset Context

**Key Citation (2025):**
"Superset Versus Traditional Resistance Training Prescriptions: A Systematic Review and Meta-analysis." *Sports Med* (2025).
- PMID: 39903375
- PMC: PMC12011898
- 19 studies, 313 participants
- Superset sessions completed in **36% less time** than traditional training
- **Similar chronic adaptations** in strength, hypertrophy, and endurance

**Paz et al. (2014):**
"Effects of different rest intervals between antagonist paired sets on repetition performance and muscle activation." *J Sports Sci* (2014).
- PMID: 25148302
- 15 recreationally trained men
- **Key finding:** No rest or short rest (30s) between agonist-antagonist pairs produced GREATER agonist muscle activation and repetition enhancement vs. longer rest (3-5 min)
- Greater EMG activity in RF and VM muscles during no-rest and 30s protocols

**Paz et al. (2020):**
"The effect of different rest intervals between agonist-antagonist paired sets on training performance and efficiency."
- PMID: 32541619

**Intra-superset rest (between the two exercises in a pair):**
- Agonist-antagonist: 0-30 seconds optimal (enhances reciprocal inhibition)
- Same-muscle (compound sets): 10-15 seconds (just enough to transition)

**Inter-superset rest (between complete rounds/pairs):**
- Agonist-antagonist: 60-120 seconds
- Same-muscle: 120-180 seconds (higher fatigue accumulation)

**Superset type affects optimal rest:**
- Agonist-antagonist supersets: Maintain volume load, allow shorter rest, greater efficiency
- Same-muscle (compound sets): Compromise volume load, need longer inter-set rest, higher perceived exertion
- Self-selected rest in studies averaged ~146 +/- 48 seconds between pairs

### 1.4 Rest Period Scaling with Time Constraints

**Research consensus:**
When time is constrained, the research suggests a clear hierarchy:
1. **Maintain adequate rest for heavy compounds** (never below 90s for strength movements)
2. **Reduce volume (fewer sets) rather than drastically cutting rest** for strength/hypertrophy goals
3. **Use supersets** to double time efficiency without sacrificing adaptations
4. **Reduce rest on isolation exercises first** (they recover faster)

Evidence from Barbell Medicine and the 2024 meta-analysis:
- Rest periods of 2-4 minutes produce best results when time is unlimited
- Compound exercises: 4-5 min ideal, but 2-3 min acceptable under time pressure
- Isolation exercises: 2-3 min ideal, 60-90s acceptable
- When rest is shortened too much, force production drops and mechanical tension is insufficient

**For the quick workout engine, this means:**
- Short workouts (5-10 min): Use circuits/supersets, reduce volume, maintain minimum rest thresholds
- Medium workouts (15-20 min): Use supersets with proper intra/inter rest, moderate volume
- Long workouts (25-30 min): Can approach standard rest periods with full volume

### 1.5 Evidence-Based Rest Period Lookup Table (seconds)

```
REST PERIOD LOOKUP TABLE (seconds)
==================================

STRAIGHT SETS:
                    | Compound  | Isolation
--------------------|-----------|----------
Strength            |           |
  Beginner          | 150-180   | 90-120
  Intermediate      | 180-240   | 120-150
  Advanced          | 240-300   | 150-180
Hypertrophy         |           |
  Beginner          | 90-120    | 60-90
  Intermediate      | 90-150    | 60-90
  Advanced          | 120-180   | 75-120
Endurance           |           |
  Beginner          | 45-60     | 30-45
  Intermediate      | 30-60     | 30-45
  Advanced          | 30-45     | 20-30
Power               |           |
  Beginner          | 180-240   | N/A
  Intermediate      | 240-300   | N/A
  Advanced          | 300-360   | N/A

SUPERSETS (Agonist-Antagonist):
  Intra-pair rest:  0-15 seconds (just transition time)
  Inter-pair rest:
                    | Value (seconds)
--------------------|----------------
  Strength          | 120-150
  Hypertrophy       | 75-120
  Endurance         | 30-60

SUPERSETS (Same-Muscle / Compound Sets):
  Intra-pair rest:  10-15 seconds
  Inter-pair rest:
                    | Value (seconds)
--------------------|----------------
  Strength          | 150-210
  Hypertrophy       | 120-150
  Endurance         | 45-75

CIRCUIT TRAINING:
  Between exercises: 15-30 seconds (transition time)
  Between rounds:    60-120 seconds (goal-dependent)

HIIT/TABATA:
  Work:Rest ratios
  Tabata: 20s work / 10s rest
  HIIT standard: 30s work / 30s rest (1:1)
  HIIT advanced: 40s work / 20s rest (2:1)
```

**Sources for table values:**
- NSCA CSCS Essentials (Haff & Triplett, 4th ed.)
- De Salles et al. 2009 (PMID: 19691365)
- Singer et al. 2024 (PMID: 39205815)
- Willardson 2006 (PMID: 17194236)
- Schoenfeld et al. 2016 (PMID: 26605807)

### 1.6 Current Engine Gap Analysis

**Current implementation in `progressive_overload.dart`:**
```dart
// Current (simplified, no training status differentiation):
case 'strength':    return isCompound ? 180 : 120;
case 'endurance':   return isCompound ? 60 : 45;
default:            return isCompound ? 120 : 75;  // hypertrophy
```

**What's missing:**
1. No training status (beginner/intermediate/advanced) differentiation
2. No power goal rest periods
3. No superset-specific rest (intra vs inter)
4. Hardcoded 15s intra-superset rest (reasonable but not parameterized)
5. Hardcoded 75s inter-superset rest (mentioned in notes string only)
6. No time-constrained rest scaling
7. No format-specific rest (circuit rest vs straight set rest)

---

## TOPIC 2: SEPARATING TRAINING GOAL FROM DIFFICULTY

### 2.1 Exercise Science Definitions

**NSCA Framework (CSCS Chapter 17):**
The NSCA distinguishes between:
- **Training Goal** (adaptation target): What physiological adaptation you're pursuing
  - Strength: Maximal force production (1-6 reps, 80-100% 1RM)
  - Hypertrophy: Muscle cross-sectional area (6-12 reps, 67-85% 1RM)
  - Endurance: Sustained submaximal performance (12+ reps, <67% 1RM)
  - Power: Rate of force development (1-6 reps, 75-90% 1RM, explosive)
- **Training Intensity/Effort** (how hard you push): Proximity to failure
  - RPE/RIR scale measures this independently of goal

**Schoenfeld et al. (2021) - Re-examination of the Repetition Continuum:**
"Loading Recommendations for Muscle Strength, Hypertrophy, and Local Endurance: A Re-Examination of the Repetition Continuum." *Sports* 9(2):32 (2021).
- PMID: 33671664
- PMC: PMC7927075
- **Key insight:** The traditional "repetition continuum" overstates the exclusivity of loading zones. Hypertrophy can occur across a WIDE spectrum of loads (30-85% 1RM) as long as effort is sufficient.
- Strength is more load-specific (heavy loads > light loads for 1RM improvement)
- Hypertrophy is more effort-specific (proximity to failure matters more than exact load)

**RIR-Based RPE Scale (Helms et al., 2016):**
"Application of the Repetitions in Reserve-Based Rating of Perceived Exertion Scale for Resistance Training." *Strength Cond J* 38(4):42-49 (2016).
- PMC: PMC4961270
- RPE 10 = 0 RIR (failure), RPE 9 = 1 RIR, RPE 8 = 2 RIR, RPE 7 = 3 RIR, RPE 6 = 4 RIR

**Can you train for hypertrophy at different RPE levels?**
YES. Proximity-to-failure meta-analysis (Robinson et al., 2023, PMID: PMC9935748) shows:
- RPE 7-8 (2-3 RIR): Effective for hypertrophy, less fatigue accumulation, better for higher volume
- RPE 9-10 (0-1 RIR): Also effective, but more fatigue, may limit total weekly volume
- The critical threshold: sets performed within ~4 RIR count as "stimulating sets" (Baz-Valle et al., 2021)

### 2.2 How Competitors Separate Goal from Difficulty

**Fitbod:**
- User sets a **Goal** (General Fitness, Muscle Building, Strength Training, etc.)
- Goal determines: rep ranges, rest periods, exercise selection emphasis
- **Difficulty** is handled via dynamic load progression: the algorithm auto-adjusts weights based on performance feedback
- No explicit "difficulty slider" - it's implicit through progressive overload
- Source: https://fitbod.zendesk.com/hc/en-us/articles/15948615409687-Fitness-Goals

**RP Hypertrophy App:**
- Goal is **fixed**: hypertrophy (that's the app's purpose)
- **Intensity manipulation within mesocycle:** RIR progression over 4-6 weeks
  - Week 1: 4 RIR (easy)
  - Week 2: 3 RIR
  - Week 3: 2 RIR
  - Week 4: 1 RIR (hard)
  - Deload
- Volume also increases week-over-week
- User feedback on soreness, pump, and performance adjusts next session
- Source: https://rpstrength.com/blogs/articles/progressing-for-hypertrophy

**Juggernaut AI:**
- Goal is set during onboarding (powerlifting focus)
- Uses **RPE-based autoregulation**: after main sets, user rates difficulty 1-10
- If RPE is low (easy), increases load; if high (hard), reduces load and/or volume
- Phases cycle through: Accumulation (high volume) -> Intensification (heavier) -> Realization (peaking)
- Over 10 quadrillion possible program permutations
- Source: https://www.juggernautai.app/

### 2.3 The Problem with the Current FitWiz Implementation

**Current in `quick_workout_constants.dart`:**
```dart
'easy': DifficultyMultiplier(
  goalMap: 'endurance',        // <-- WRONG: Easy != Endurance
  fitnessLevelMap: 'beginner', // <-- WRONG: Easy != Beginner
),
'medium': DifficultyMultiplier(
  goalMap: 'hypertrophy',
  fitnessLevelMap: 'intermediate',
),
'hell': DifficultyMultiplier(
  goalMap: 'strength',         // <-- WRONG: Hard != Strength
  fitnessLevelMap: 'advanced',
),
```

**This conflates two independent axes:**
1. "Easy" difficulty forces endurance goal and beginner programming (but an advanced user doing an easy hypertrophy session should NOT get endurance programming)
2. "Hell" difficulty forces strength goal (but a user who wants hypertrophy at maximum effort should still get hypertrophy rep ranges, just pushed harder)

### 2.4 Proposed Two-Axis Model

**Axis 1: Training Goal (set by user or inferred from profile)**
Determines: rep range, %1RM band, rest period band, exercise type emphasis

**Axis 2: Difficulty/Effort (the "Easy/Medium/Hard/Hell" slider)**
Determines: proximity to failure (RPE/RIR), volume adjustment, rest adjustment within goal's band

```
PROPOSED MAPPING:
=================

GOAL: STRENGTH (1-6 reps, 80-95% 1RM)
  Easy:   4-6 reps, 80% 1RM, RPE 6-7, 3 RIR, rest 180s, 2-3 sets
  Medium: 3-5 reps, 85% 1RM, RPE 7-8, 2 RIR, rest 210s, 3-4 sets
  Hard:   2-4 reps, 88% 1RM, RPE 8-9, 1 RIR, rest 240s, 4-5 sets
  Hell:   1-3 reps, 92% 1RM, RPE 9-10, 0 RIR, rest 270s, 4-5 sets

GOAL: HYPERTROPHY (6-15 reps, 65-80% 1RM)
  Easy:   10-15 reps, 65% 1RM, RPE 6-7, 3-4 RIR, rest 90s, 2 sets
  Medium: 8-12 reps, 72% 1RM, RPE 7-8, 2-3 RIR, rest 105s, 3 sets
  Hard:   6-10 reps, 77% 1RM, RPE 8-9, 1-2 RIR, rest 120s, 3-4 sets
  Hell:   6-8 reps, 80% 1RM, RPE 9-10, 0-1 RIR, rest 135s, 4 sets

GOAL: ENDURANCE (12-25 reps, 50-67% 1RM)
  Easy:   15-25 reps, 50% 1RM, RPE 5-6, 4-5 RIR, rest 45s, 2 sets
  Medium: 12-20 reps, 57% 1RM, RPE 7-8, 2-3 RIR, rest 45s, 2-3 sets
  Hard:   12-18 reps, 62% 1RM, RPE 8-9, 1-2 RIR, rest 35s, 3 sets
  Hell:   12-15 reps, 67% 1RM, RPE 9-10, 0 RIR, rest 30s, 3-4 sets

GOAL: POWER (1-5 reps, 75-90% 1RM, explosive)
  Easy:   3-5 reps, 75% 1RM, RPE 6-7, 3 RIR, rest 240s, 2-3 sets
  Medium: 2-5 reps, 80% 1RM, RPE 7-8, 2 RIR, rest 270s, 3-4 sets
  Hard:   1-3 reps, 85% 1RM, RPE 8-9, 1 RIR, rest 300s, 4-5 sets
  Hell:   1-3 reps, 90% 1RM, RPE 9-10, 0 RIR, rest 300s, 4-5 sets
```

**What each difficulty level modifies (goal-INDEPENDENT):**
- **Volume multiplier:** Easy=0.7, Medium=1.0, Hard=1.15, Hell=1.3 (existing, keep)
- **Rest multiplier:** Easy=1.2, Medium=1.0, Hard=0.9, Hell=0.8 (slightly adjusted)
- **RPE/RIR target:** Easy=6-7/3-4, Medium=7-8/2-3, Hard=8-9/1-2, Hell=9-10/0-1
- **Intensity shift within goal band:** Easy=-5% 1RM, Medium=0%, Hard=+3%, Hell=+5%

**What the GOAL determines (difficulty-INDEPENDENT):**
- Base rep range
- Base %1RM band
- Base rest period
- Exercise selection bias (compound vs isolation ratio)
- Warm-up set structure

### 2.5 Implementation Recommendation

Replace the current `DifficultyMultiplier` class with a two-class system:

```dart
class GoalParameters {
  final int repsMin;
  final int repsMax;
  final double intensityMin;  // %1RM lower bound
  final double intensityMax;  // %1RM upper bound
  final int restCompound;     // base rest for compound (seconds)
  final int restIsolation;    // base rest for isolation (seconds)
  final double compoundRatio; // 0-1, how much to prefer compounds
  final bool includeWarmup;
}

class DifficultyModifiers {
  final double volumeMultiplier;
  final double restMultiplier;
  final double intensityShift; // %1RM adjustment within goal band
  final int rpeMin;
  final int rpeMax;
  final int rirMin;
  final int rirMax;
}
```

---

## TOPIC 3: VARIETY AND EXERCISE ROTATION ALGORITHMS

### 3.1 Research on Exercise Variety for Hypertrophy

**Fonseca et al. (2014):**
"Changes in exercises are more effective than in loading schemes to improve muscle strength." *J Strength Cond Res* 28(11):3085-3092 (2014).
- PMID: 24832974
- 49 subjects, 12 weeks, 4 training conditions (CICE, CIVE, VICE, VIVE)
- **Key findings:**
  - All groups achieved similar quadriceps hypertrophy (~10-12% CSA increase)
  - CIVE (constant intensity, varied exercise) produced GREATEST strength gains (ES: 1.41-2.28 vs other groups)
  - Exercise variation groups (CIVE, VIVE) achieved hypertrophy in ALL quad heads, while constant exercise groups missed vastus medialis and/or rectus femoris
  - **Takeaway:** Exercise variation improves REGIONAL hypertrophy coverage and strength transfer

**Baz-Valle et al. (2019):**
"The effects of exercise variation in muscle thickness, maximal strength and motivation in resistance trained men." *PLoS One* 14(12):e0226989 (2019).
- PMID: 31881066
- PMC: PMC6934277
- 21 trained men, 8 weeks, 4x/week
- Fixed vs randomly varied exercises each session
- **Key findings:**
  - Similar hypertrophy in both groups (VL and RF)
  - Similar strength gains in both groups
  - **Varied group had significantly higher motivation to train**
  - Random variation did NOT hurt adaptations, but didn't improve them either

**Kassiano et al. (2022):**
"Does varying resistance exercises promote superior muscle hypertrophy and strength gains? A systematic review." *J Strength Cond Res* 36(6):1753-1762 (2022).
- PMID: 35438660
- 8 studies, 241 young men
- **Critical conclusion:**
  - "Systematic variation enhances regional hypertrophic adaptations and maximizes dynamic strength"
  - "Excessive, random variation may compromise muscular gains"
  - Variation should be based on anatomical and biomechanical constructs (e.g., varying ANGLE, not just randomly swapping exercises)
  - Exercises providing redundant stimulus or excessive rotation frequency may hinder adaptation

### 3.2 How Much Variety is Optimal?

Based on the systematic review evidence:

1. **Per muscle group per mesocycle (4-6 weeks):** 2-3 exercise variations
2. **Rotation frequency:** Every 3-4 weeks for main lifts, can vary accessories weekly
3. **Systematic > Random:** Change exercises that target different REGIONS of a muscle (e.g., incline vs flat for upper vs lower pec)
4. **Progressive overload takes priority:** If you change exercises too often, you can't track and progress loads

**For a quick workout engine generating individual sessions:**
- Maintain a "core" set of exercises that repeat for tracking (staple exercises)
- Rotate "accessory" exercises for variety and regional coverage
- Use a recency penalty but NOT full avoidance of recent exercises

### 3.3 Movement Angle Rotation Research

**Bench Press Angles (Lauver et al., 2015):**
"Influence of bench angle on upper extremity muscular activation during bench press exercise." *Int J Exerc Sci* (2015).
- PMID: 25799093
- 0 (flat), 30, 45, -15 degrees tested
- Upper pec: significantly higher activation at 30 and 45 vs flat and -15 during mid-contraction
- Lower pec: higher at -15, flat, and 30 vs 45
- **Practical takeaway:** Rotate between flat and incline (30) for complete pec development

**Schoenfeld (2024):**
"Optimizing Resistance Training Technique to Maximize Muscle Hypertrophy: A Narrative Review." *J Funct Morphol Kinesiol* 9(1):9 (2024).
- Different angles/positions create different force-length relationships
- Regional hypertrophy is a real phenomenon: muscles grow differentially based on exercise selection

**Exercise Selection and Regional Hypertrophy (2024):**
"Exercise selection differentially influences lower body regional muscle development." *J Sci Sport Exerc* (2024).
- Multi-joint vs single-joint exercises produce different regional adaptations in quadriceps

### 3.4 Algorithmic Approaches to Variety

**3.4.1 Recency-Weighted Scoring (Recommended Approach)**

Instead of binary "was recently used / was not," apply a continuous decay score:

```
freshness_score(exercise) = e^(-lambda * days_since_last_use)
```

Where:
- `lambda` = decay rate (recommended: 0.15 for weekly rotation, 0.05 for monthly)
- `days_since_last_use` = days since this exercise was last performed
- Score ranges from 0 (just performed) to 1.0 (long time ago)

**For session-based tracking (simpler, for quick workouts):**
```
freshness_score(exercise) = e^(-0.3 * sessions_since_last_use)
```

Example scores:
- Just used: e^0 = 1.0 (lowest freshness, highest penalty)
- 1 session ago: e^-0.3 = 0.74
- 2 sessions ago: e^-0.6 = 0.55
- 3 sessions ago: e^-0.9 = 0.41
- 5 sessions ago: e^-1.5 = 0.22
- 7+ sessions ago: ~0.1 or less (essentially "fresh")

**Penalty application:**
```
selection_score = base_score * (1 - freshness_penalty_weight * freshness_score)
```
Where `freshness_penalty_weight` = 0.3-0.5 (controls how much recency matters)

**3.4.2 Fitbod's Approach (Reverse-Engineered)**

Fitbod uses three variability settings:
1. **More Consistent:** Retains most exercises from previous weeks, minimal rotation
2. **Balanced (default):** Mix of consistency and variety, retains ~50% of exercises
3. **More Varied:** Higher rotation, introduces new exercises frequently

Their algorithm tracks:
- Per-muscle-group "freshness" scores
- Exercise preference history (manually added exercises get boosted)
- Session history used to weight future recommendations
- Source: https://fitbod.zendesk.com/hc/en-us/articles/16254175592215-Fitbod-s-Algorithm-Q-A

**3.4.3 Slot-Based Rotation Algorithm (Recommended for FitWiz)**

```
For each muscle slot in the workout template:
  1. Get all valid candidate exercises for this slot
  2. Score each candidate:
     a. base_score = 1.0
     b. +0.3 if exercise is in user's staple list
     c. +0.2 if user has 1RM data (enables better load prescription)
     d. -0.3 * freshness_score (recency penalty)
     e. +0.15 if exercise targets a different REGION than the
        last exercise used for this muscle group (angle diversity)
     f. +0.1 if exercise uses different equipment than last time
        (movement variety)
  3. Apply weighted random selection using scores as probabilities
     (NOT greedy max-score, to maintain some randomness)
```

**Weighted random selection formula:**
```
probability(exercise_i) = score_i / sum(all_scores)
```

### 3.5 Current Engine Gap Analysis

**Current implementation:**
```dart
// Binary freshness filter (all or nothing):
final freshCandidates = candidates
    .where((ex) => !recentlyUsedExercises.contains(name))
    .toList();
final pool = freshCandidates.isNotEmpty ? freshCandidates : candidates;
```

**Problems:**
1. Binary: exercise is either "fresh" or "recently used" with no gradient
2. No angle/region rotation tracking
3. No weighted selection - uses `selectForSlot` which has its own priority logic but no freshness weighting
4. `recentlyUsedExercises` is a flat set with no temporal information (when was it used?)
5. No distinction between "used yesterday" and "used 5 days ago"

---

## TOPIC 4: REP ADJUSTMENT FORMULAS

### 4.1 1RM Prediction Equations - Complete Reference

**Epley (1985):**
```
1RM = weight * (1 + reps / 30)
```
- Most accurate for low reps (2-5), errors under 3%
- Linear relationship assumed between reps and load
- Validation: +2.7kg error from 3RM loads (0.013%)

**Brzycki (1993):**
```
1RM = weight * (36 / (37 - reps))
```
- Equivalent form: 1RM = weight / (1.0278 - 0.0278 * reps)
- Most accurate for moderate reps (6-10), errors under 5%
- Validation: -3.1kg error from 5RM loads (0.015%)
- Returns identical results to Epley at exactly 10 reps
- Below 10 reps: slightly lower estimate than Epley
- Mathematically undefined at 37 reps (asymptote)

**Lombardi (1989):**
```
1RM = weight * reps^0.10
```
- Most accurate for bench press and squat in men (2024 IUSCA study)
- Simple power function
- Performs well across ranges but tends to underestimate at high reps

**Mayhew et al. (1992):**
```
1RM = (100 * weight) / (52.2 + 41.9 * e^(-0.055 * reps))
```
- Based on 435 college students
- Best accuracy for high rep ranges (8-15+)
- Exponential model captures non-linear rep-load relationship better
- Accuracy maintained up to ~20 reps, degrades beyond

**O'Conner et al. (1989):**
```
1RM = weight * (1 + 0.025 * reps)
```
- Simplest formula, linear
- Reasonable for quick estimates
- Less accurate at extremes

**Wathen (1994):**
```
1RM = (100 * weight) / (48.8 + 53.8 * e^(-0.075 * reps))
```
- Similar structure to Mayhew but different coefficients
- Good accuracy for low rep ranges (2-5)

**Accuracy Comparison Table:**
```
Rep Range | Best Formula    | Typical Error
----------|-----------------|---------------
1-3       | Epley, Wathen   | 1-3%
4-6       | Epley, Lombardi | 2-4%
7-10      | Brzycki, Mayhew | 3-5%
11-15     | Mayhew          | 4-7%
16-20     | Mayhew          | 5-10%
20+       | None reliable   | 10%+
```

**Source:** Lombardi accuracy study - International Journal of Strength and Conditioning (2024): "Accuracy of 1RM Prediction Equations Before and After Resistance Training in Three Different Lifts"

### 4.2 Inverse Application: Calculating Target Reps from Weight

Given a known 1RM and a specific weight, we can invert the formulas to prescribe rep targets:

**Inverse Epley:**
```
reps = 30 * (1RM / weight - 1)
```

**Inverse Brzycki:**
```
reps = (37 * weight - 36 * 1RM) / (weight - 1RM)  [simplified]
reps = 37 - 36 / (weight / 1RM)                    [cleaner form]
```
Or equivalently:
```
reps = (1.0278 - weight/1RM) / 0.0278
```

**Inverse Mayhew:**
```
reps = ln((100 * weight / (1RM) - 52.2) / 41.9) / (-0.055)
```
Note: Only valid when `100 * weight / 1RM > 52.2` (i.e., weight > 52.2% of 1RM)

**Recommended approach for the engine:**
Use inverse Epley for simplicity and reasonable accuracy across the working range:
```dart
int targetReps(double oneRepMax, double workingWeight) {
  if (workingWeight >= oneRepMax) return 1;
  if (workingWeight <= 0) return 20;
  final reps = 30.0 * (oneRepMax / workingWeight - 1.0);
  return reps.round().clamp(1, 30);
}
```

**For "equivalent stimulus" when weight changes (e.g., equipment snap):**
If original prescription was W1 x R1, and weight snaps to W2:
```
R2 = R1 * (W1 / W2)^1.1  // slightly super-linear to account for fatigue
```
This ensures volume-load (sets x reps x weight) is approximately preserved while accounting for the non-linear relationship between load and reps-to-failure.

### 4.3 Volume-Load and Effective Reps Research

**Is sets x reps x weight a valid proxy for training stimulus?**

**Baz-Valle et al. (2018/2021):**
- "Total Number of Sets as a Training Volume Quantification Method for Muscle Hypertrophy." *J Strength Cond Res* (2018). PMID: 30063555
- When hypertrophy is the goal, volume should be counted as **number of "hard sets"** (sets within 4 RIR of failure), NOT total volume-load
- Volume-load (sets x reps x weight) is NOT a reliable proxy because:
  - A set of 3x100kg (volume-load: 300) can be harder than 10x30kg (volume-load: 300)
  - What matters is motor unit recruitment, which requires sufficient effort

**Dankel et al. (2017):**
- Proximity to failure is essential for optimal hypertrophy stimulus
- Motor unit recruitment increases as you approach failure regardless of load
- The last ~5 reps before failure ("effective reps" or "stimulating reps") drive most of the hypertrophic signal

**Robinson et al. (2023):**
"Influence of Resistance Training Proximity-to-Failure on Skeletal Muscle Hypertrophy." *Sports Med* 53(3):649-665 (2023).
- PMC: PMC9935748
- Sets to failure vs non-failure: trivial difference when volume-load equated
- No moderating effect of volume-load on hypertrophy outcomes

**Practical "Effective Reps" Model:**
```
effective_reps = min(5, total_reps - max(0, reps_remaining_to_failure))
```
Where `reps_remaining_to_failure` = RIR

Example: 10 reps at 3 RIR -> 10 - 3 = 7 reps "past threshold" -> effective_reps = min(5, 7) = 5
Example: 5 reps at 0 RIR -> 5 - 0 = 5 -> effective_reps = 5
Example: 10 reps at 7 RIR -> 10 - 7 = 3 -> effective_reps = 3

**For the engine, this means:**
- Don't optimize for volume-load
- Optimize for number of sets within appropriate RIR range for the difficulty level
- A set of 5 reps at RPE 9 (1 RIR) is as stimulating as a set of 12 reps at RPE 9 (1 RIR) for hypertrophy

### 4.4 RPE to %1RM Conversion Table (Tuchscherer/RTS)

Based on Mike Tuchscherer's Reactive Training Systems chart:

```
REPS |  RPE 6  |  RPE 7  |  RPE 8  |  RPE 9  |  RPE 10
     | (4 RIR) | (3 RIR) | (2 RIR) | (1 RIR) | (0 RIR)
-----|---------|---------|---------|---------|--------
  1  |  85.0%  |  89.2%  |  92.2%  |  95.5%  | 100.0%
  2  |  82.0%  |  86.3%  |  89.2%  |  92.2%  |  95.5%
  3  |  79.5%  |  83.7%  |  86.3%  |  89.2%  |  92.2%
  4  |  77.0%  |  81.1%  |  83.7%  |  86.3%  |  89.2%
  5  |  74.5%  |  78.6%  |  81.1%  |  83.7%  |  86.3%
  6  |  72.0%  |  76.2%  |  78.6%  |  81.1%  |  83.7%
  7  |  69.5%  |  73.9%  |  76.2%  |  78.6%  |  81.1%
  8  |  67.5%  |  71.7%  |  73.9%  |  76.2%  |  78.6%
  9  |  65.5%  |  69.5%  |  71.7%  |  73.9%  |  76.2%
 10  |  63.5%  |  67.5%  |  69.5%  |  71.7%  |  73.9%
 12  |  60.0%  |  63.5%  |  65.5%  |  67.5%  |  69.5%
```

**Source:** Tuchscherer M, Reactive Training Systems (2008). Note: these values are population averages and individual variation is significant. Each column decreases by ~2.3-4.5% per rep added.

**Algorithmic formula to approximate the table:**
```
percent_1rm(reps, rpe) ≈ 100 * (1 - (reps + (10 - rpe)) / 30.0)
```
This is essentially the inverse Epley formula where total_reps = actual_reps + RIR.

More precisely:
```dart
double percent1RM(int reps, double rpe) {
  final rir = 10.0 - rpe;
  final effectiveReps = reps + rir;
  // Epley inverse: %1RM = 1 / (1 + effectiveReps/30)
  return 100.0 / (1.0 + effectiveReps / 30.0);
}
```

---

## TOPIC 5: POST-GENERATION EXERCISE SWAP LOGIC

### 5.1 Exercise Substitution Frameworks

**ExRx.net Classification System:**
ExRx.net categorizes exercises along multiple dimensions:
1. **Movement pattern:** Push (horizontal/vertical), Pull (horizontal/vertical), Hip Hinge, Squat, Lunge, Carry, Rotation
2. **Joint type:** Single-joint (isolation) vs Multi-joint (compound)
3. **Basic vs Auxiliary:** Basic = principal exercises using large muscle mass; Auxiliary = supplementary exercises for specific muscles/heads
4. **Target muscle:** Primary muscle the exercise trains
5. **Synergists:** Muscles that assist
6. **Stabilizers:** Muscles that stabilize during the movement
7. **Equipment required**

**Fitness Volt Algorithm:**
Uses weighted Jaccard similarity across exercise attributes to find substitutes from 1,600+ exercises. The algorithm analyzes:
- Primary/secondary muscles targeted
- Movement pattern
- Equipment required
- Difficulty level
- Source: https://fitnessvolt.com/substitute-exercises/

**Fitbod Auto-Substitution:**
- When user changes gym/equipment, Fitbod auto-substitutes exercises targeting same muscles with equivalent intensity
- Balances push/pull/legs
- Factors in muscle freshness
- Source: https://fitbod.me/blog/what-fitness-app-is-best-for-you-how-fitbod-adapts-to-any-fitness-level-goal-or-gym-setup/

### 5.2 Exercise Similarity Scoring Algorithm

**Recommended multi-attribute similarity function:**

```
similarity(exercise_A, exercise_B) =
    w1 * primary_muscle_match(A, B) +
    w2 * movement_pattern_match(A, B) +
    w3 * equipment_compatibility(A, B) +
    w4 * secondary_muscle_overlap(A, B) +
    w5 * difficulty_proximity(A, B) +
    w6 * joint_type_match(A, B)
```

**Recommended weights:**
```
w1 = 0.35  (primary muscle: MUST match or be very close)
w2 = 0.25  (movement pattern: horizontal push should swap with horizontal push)
w3 = 0.15  (equipment: must be available, prefer same category)
w4 = 0.10  (secondary muscles: nice to have overlap)
w5 = 0.10  (difficulty: should be comparable)
w6 = 0.05  (compound/isolation: nice to match)
```

**Individual scoring functions:**

```dart
// Primary muscle match (0.0 or 1.0, with alias expansion)
double primaryMuscleMatch(Exercise a, Exercise b) {
  final aliasesA = getAliases(a.primaryMuscle); // e.g., {'chest', 'pecs', 'pectorals'}
  final aliasesB = getAliases(b.primaryMuscle);
  return aliasesA.intersection(aliasesB).isNotEmpty ? 1.0 : 0.0;
}

// Movement pattern match (0.0, 0.5, or 1.0)
double movementPatternMatch(Exercise a, Exercise b) {
  if (a.movementPattern == b.movementPattern) return 1.0;
  if (areSameCategory(a.movementPattern, b.movementPattern)) return 0.5;
  // e.g., horizontal_push and vertical_push are same category (push)
  return 0.0;
}

// Equipment compatibility (0.0 or 1.0)
double equipmentCompatibility(Exercise b, List<String> availableEquipment) {
  return availableEquipment.contains(b.equipment) ? 1.0 : 0.0;
}

// Secondary muscle overlap (Jaccard index)
double secondaryMuscleOverlap(Exercise a, Exercise b) {
  final setA = a.secondaryMuscles.toSet();
  final setB = b.secondaryMuscles.toSet();
  if (setA.isEmpty && setB.isEmpty) return 1.0;
  final union = setA.union(setB);
  if (union.isEmpty) return 1.0;
  return setA.intersection(setB).length / union.length;
}

// Difficulty proximity (1.0 = same, 0.0 = max difference)
double difficultyProximity(Exercise a, Exercise b) {
  final diff = (a.difficultyNum - b.difficultyNum).abs();
  return 1.0 - (diff / 10.0).clamp(0.0, 1.0);
}
```

### 5.3 Constraint Satisfaction for Swap Candidates

When a user requests a swap, the algorithm should:

```
1. HARD CONSTRAINTS (must satisfy ALL):
   a. Primary muscle matches (with alias expansion)
   b. Equipment is available to user
   c. Exercise is NOT already in the current workout
   d. Exercise is NOT in user's avoided list
   e. Exercise doesn't target an injured muscle

2. SOFT CONSTRAINTS (scored, not required):
   a. Movement pattern similarity (same pattern > same category > different)
   b. Secondary muscle overlap
   c. Difficulty level proximity
   d. Compound/isolation type match
   e. Recency (prefer exercises not recently performed)
   f. User preference (boost exercises from user's history)

3. RANKING:
   a. Filter by hard constraints
   b. Score remaining candidates by soft constraints
   c. Return top 3-5 candidates sorted by score
   d. Let user pick from the list
```

### 5.4 Movement Pattern Taxonomy for Swap Logic

```
MOVEMENT PATTERNS:
  PUSH:
    horizontal_push: bench press, push-up, chest press, chest fly
    vertical_push: overhead press, pike push-up, arnold press

  PULL:
    horizontal_pull: bent-over row, cable row, seated row
    vertical_pull: pull-up, lat pulldown, chin-up

  HIP_HINGE:
    deadlift, romanian deadlift, good morning, hip thrust, kettlebell swing

  SQUAT:
    back squat, front squat, goblet squat, leg press, hack squat

  LUNGE:
    walking lunge, reverse lunge, bulgarian split squat, step-up

  ISOLATION_UPPER:
    bicep_curl, tricep_extension, lateral_raise, face_pull, shrug

  ISOLATION_LOWER:
    leg_extension, leg_curl, calf_raise, hip_abduction, hip_adduction

  CORE:
    crunch, plank, russian_twist, leg_raise, cable_woodchop

SWAP COMPATIBILITY MATRIX:
  Same pattern = 1.0 (bench press <-> dumbbell bench press)
  Same category = 0.5 (bench press <-> overhead press, both "push")
  Related = 0.25 (squat <-> lunge, both knee-dominant)
  Unrelated = 0.0 (bench press <-> squat)
```

### 5.5 Current Engine Gap Analysis

The current engine has NO swap functionality. The `_selectExerciseForSlot` method selects exercises during generation but there is no post-generation swap mechanism.

**What needs to be built:**
1. `getSwapCandidates(exercise, workout, userContext)` -> ranked list
2. Movement pattern tags for each exercise (currently not in the data model)
3. Similarity scoring function
4. UI for presenting swap options and confirming selection

---

## IMPLEMENTATION PRIORITY MATRIX

Based on impact, research strength, and development complexity:

| Priority | Feature | Impact | Effort | Research Confidence |
|----------|---------|--------|--------|---------------------|
| 1 | Separate goal from difficulty (Topic 2) | HIGH | MEDIUM | Very High |
| 2 | Evidence-based rest period table (Topic 1) | HIGH | LOW | Very High |
| 3 | Recency-weighted exercise scoring (Topic 3) | MEDIUM | LOW | High |
| 4 | Superset-specific rest periods (Topic 1.3) | MEDIUM | LOW | High |
| 5 | Exercise swap logic (Topic 5) | HIGH | HIGH | Medium |
| 6 | Inverse 1RM for rep adjustment (Topic 4) | MEDIUM | LOW | Very High |
| 7 | Slot-based rotation with angle diversity (Topic 3) | MEDIUM | MEDIUM | Medium |
| 8 | Effective reps model (Topic 4.3) | LOW | MEDIUM | High |

### Recommended Implementation Order:
1. **Phase 1 (Quick wins):** Topics 1.5 (rest table), 2.4 (goal/difficulty separation), 3.4.1 (recency scoring)
2. **Phase 2 (Core improvements):** Topics 1.3 (superset rest), 4.2 (inverse 1RM), 3.4.3 (slot rotation)
3. **Phase 3 (Advanced features):** Topics 5 (swap logic), 4.3 (effective reps), 3.3 (angle diversity)

---

## FULL CITATION LIST

1. Singer A et al. (2024) "Give it a rest: a systematic review with Bayesian meta-analysis on the effect of inter-set rest interval duration on muscle hypertrophy." Front. Sports Act. Living 6:1429789. PMID: 39205815
2. De Salles BF et al. (2009) "Rest interval between sets in strength training." Sports Med 39(9):765-777. PMID: 19691365
3. Schoenfeld BJ et al. (2016) "Longer interset rest periods enhance muscle strength and hypertrophy in resistance-trained men." J Strength Cond Res 30(7):1805-1812. PMID: 26605807
4. Willardson JM (2006) "A brief review: factors affecting the length of the rest interval between resistance exercise sets." J Strength Cond Res 20(4):978-984. PMID: 17194236
5. Henselmans M & Schoenfeld BJ (2014) "The effect of inter-set rest intervals on resistance exercise-induced muscle hypertrophy." Sports Med 44(12):1635-1643. PMID: 25047853
6. Superset meta-analysis (2025) "Superset Versus Traditional Resistance Training Prescriptions." Sports Med. PMID: 39903375. PMC: PMC12011898
7. Paz GA et al. (2014) "Effects of different rest intervals between antagonist paired sets on repetition performance and muscle activation." J Sports Sci. PMID: 25148302
8. Paz GA et al. (2020) "The effect of different rest intervals between agonist-antagonist paired sets on training performance and efficiency." PMID: 32541619
9. Fonseca RM et al. (2014) "Changes in exercises are more effective than in loading schemes to improve muscle strength." J Strength Cond Res 28(11):3085-3092. PMID: 24832974
10. Baz-Valle E et al. (2019) "The effects of exercise variation in muscle thickness, maximal strength and motivation in resistance trained men." PLoS One 14(12):e0226989. PMID: 31881066. PMC: PMC6934277
11. Kassiano W et al. (2022) "Does varying resistance exercises promote superior muscle hypertrophy and strength gains? A systematic review." J Strength Cond Res 36(6):1753-1762. PMID: 35438660
12. Schoenfeld BJ et al. (2021) "Loading Recommendations for Muscle Strength, Hypertrophy, and Local Endurance: A Re-Examination of the Repetition Continuum." Sports 9(2):32. PMID: 33671664. PMC: PMC7927075
13. Helms ER et al. (2016) "Application of the Repetitions in Reserve-Based Rating of Perceived Exertion Scale for Resistance Training." Strength Cond J 38(4):42-49. PMC: PMC4961270
14. Robinson ZP et al. (2023) "Influence of Resistance Training Proximity-to-Failure on Skeletal Muscle Hypertrophy." Sports Med 53(3):649-665. PMC: PMC9935748
15. Baz-Valle E et al. (2018) "Total Number of Sets as a Training Volume Quantification Method for Muscle Hypertrophy." J Strength Cond Res. PMID: 30063555
16. Lauver JD et al. (2015) "Influence of bench angle on upper extremity muscular activation during bench press exercise." Int J Exerc Sci. PMID: 25799093
17. Schoenfeld BJ (2024) "Optimizing Resistance Training Technique to Maximize Muscle Hypertrophy: A Narrative Review." J Funct Morphol Kinesiol 9(1):9
18. Lombardi 1RM accuracy (2024) "Accuracy of 1RM Prediction Equations Before and After Resistance Training in Three Different Lifts." Int J Strength Cond
19. Mayhew JL et al. (1992) "Prediction of 1 repetition maximum in the bench press from a submaximal repetition set." J Teach Phys Educ 11:328-332
20. NSCA (Haff GG & Triplett NT, eds.) Essentials of Strength Training and Conditioning, 4th ed. Human Kinetics, 2016 (CSCS Chapter 17: Program Design)
