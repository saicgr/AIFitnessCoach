# Deep Research: Muscle Recovery, DUP, Post-Workout Feedback, and Volume Landmarks

**Date:** 2026-02-20
**Purpose:** Algorithmic constants, formulas, and research citations for FitWiz workout engine implementation

---

## TOPIC 1: Muscle Recovery Scoring Algorithms

### 1.1 Fitbod's Recovery Model (Reverse-Engineered)

Fitbod assigns a 0-100% recovery score per muscle group. Based on their public documentation, blog posts, and help center articles, here is what is known:

**Core Mechanics:**
- After logging a workout, Fitbod estimates how much each muscle group was worked by computing `sets x reps x weight` (volume load) for each muscle group
- A recovery percentage (0-100%) is assigned per muscle group based on this fatigue estimate
- Muscles are considered fully recovered (100%) after **7 days** of complete rest
- The algorithm scores each of 800+ exercises based on how recovered the primary muscles are
- If a muscle group is fatigued but must be included, Fitbod suggests lower-intensity exercises or alternative movements

**What We Know About the Scoring:**
- 0-40%: Heavily fatigued, avoid training
- 40-79%: Partially recovered, can train with reduced intensity
- 80-100%: Fresh, ready for full training
- The algorithm uses "dynamic adaptation" meaning sets, reps, and weights vary to maximize growth and strength
- Integration with external apps (like running apps) affects leg muscle recovery scores

**What Fitbod Does NOT Publicly Reveal:**
- The exact mathematical decay function (exponential vs linear)
- How they weight sets vs reps vs load in the fatigue calculation
- How primary vs secondary muscle contributions are weighted
- Whether training experience modifies the decay rate
- No patent filings were found in public USPTO databases

**Sources:**
- [How Fitbod's AI Knows When You Should Lift Heavier](https://fitbod.me/blog/how-fitbods-ai-knows-exactly-when-you-should-lift-heavier-and-when-to-recover/)
- [Fitbod Algorithm Blog](https://fitbod.me/blog/fitbod-algorithm/)
- [Muscle Recovery Help Center](https://fitbod.zendesk.com/hc/en-us/articles/360006269014-Muscle-Recovery)
- [How Fitbod Creates Your Workout](https://fitbod.zendesk.com/hc/en-us/articles/360004429814-How-Fitbod-Creates-Your-Workout)

---

### 1.2 Research Papers on Muscle Recovery Timelines

#### 1.2.1 Muscle Protein Synthesis (MPS) Time Course

**MacDougall et al. (1995)** - "The time course for elevated muscle protein synthesis following heavy resistance exercise"
- PubMed ID: 8563679
- DOI: 10.1139/h95-038

Key findings:
- MPS elevated **50% above baseline** at 4 hours post-training
- MPS elevated **109% above baseline** at 24 hours post-training
- MPS drops to only **14% above baseline** by 36 hours
- MPS returns to baseline by approximately 48 hours in trained individuals

This gives us the foundational decay curve. The pattern is NOT simple exponential decay; it is a **delayed-peak exponential decay** (rises, peaks at ~24h, then decays).

#### 1.2.2 Damas et al. (2016) - Training Status Effects

**Citation:** Damas F, Phillips SM, Libardi CA, et al. "Resistance training-induced changes in integrated myofibrillar protein synthesis are related to hypertrophy only after attenuation of muscle damage."
- PubMed ID: 27219125
- DOI: 10.1113/JP272472
- Published in: The Journal of Physiology, 2016

Key findings:
- **Untrained individuals:** MPS elevated for longer duration (up to 72+ hours) but much of it is directed at muscle damage repair, NOT hypertrophy
- **Trained individuals (3+ weeks):** MPS duration is shorter (~48 hours) but more of it is directed toward actual muscle growth
- Muscle damage is highest in Week 1, lower in Week 3, minimal by Week 10
- **Implication for algorithm:** Beginners need MORE recovery time per session but for different reasons (damage repair); advanced lifters recover faster but need higher volume to trigger growth

#### 1.2.3 McLester et al. (2003) & Jones et al. (2006) - Recovery Timelines

**McLester et al.** - "A series of studies--a practical protocol for testing muscular endurance recovery"
- PubMed ID: 12741861

**Jones et al. (2006)** - "Stability of a practical measure of recovery from resistance training"
- PubMed ID: 17194226

Key findings (3 sets to failure at 10RM):
- **24 hours:** 0% of subjects fully recovered
- **48 hours:** 40% of subjects fully recovered
- **72 hours:** 80% of subjects fully recovered
- **96 hours:** 80% of subjects fully recovered
- **Supercompensation effect:** At 72 hours, performance was significantly ABOVE baseline (subjects could do more reps than at baseline)

#### 1.2.4 Large vs Small Muscle Group Recovery

**Clark (2020)** - "Recoverability of large vs small muscle groups"
- Source: University of Northern Iowa thesis (scholarworks.uni.edu)

Key findings (IMPORTANT - contradicts common belief):
- Muscle SIZE alone does NOT determine recovery rate
- **Muscle fiber type composition** and **voluntary activation level** are the primary determinants
- Quads recover FASTER than expected (high slow-twitch, low voluntary activation)
- Biceps and triceps recover SLOWER than expected (high fast-twitch, high voluntary activation)
- Calves recover very fast (high slow-twitch fiber composition)

#### 1.2.5 Practical Recovery Windows by Muscle Group

Based on synthesizing the above research plus Schoenfeld (2016, PMID: 27102172) and the RP frequency recommendations:

| Muscle Group   | Base Recovery (hours) | Frequency/week | Fiber Type Factor | Notes |
|----------------|----------------------|-----------------|-------------------|-------|
| Quads          | 48-72                | 1.5-3x          | Slow-twitch dominant | Recovers faster than size suggests |
| Hamstrings     | 48-72                | 2-3x             | Mixed               | |
| Glutes         | 48-72                | 2-3x             | Mixed               | |
| Chest          | 48-72                | 1.5-3x           | Fast-twitch dominant | Standard recovery |
| Back (lats)    | 48-72                | 2-4x             | Mixed               | Can handle high frequency |
| Shoulders      | 36-48                | 2-6x (rear/side) | Mixed              | Front delts: limited direct training needed |
| Biceps         | 48-72                | 2-6x             | Fast-twitch dominant | Slower recovery than size suggests |
| Triceps        | 48-72                | 2-4x             | Fast-twitch dominant | Slower recovery than size suggests |
| Calves         | 24-48                | 2-4x             | Slow-twitch dominant | Very fast recovery |
| Abs            | 24-48                | 3-5x             | Slow-twitch dominant | Fast recovery |
| Forearms       | 24-48                | 2-6x             | Slow-twitch dominant | Fast recovery, high endurance |
| Traps          | 36-48                | 2-6x             | Mixed               | |

---

### 1.3 Concrete Recovery Scoring Algorithm

Based on the research above, here is a proposed per-muscle recovery function.

#### Mathematical Model: Modified Exponential Decay with Delayed Peak

The recovery curve follows a **complementary sigmoid-exponential hybrid** rather than pure exponential decay:

```
Recovery(t) = 100 * (1 - fatigue_remaining(t))

fatigue_remaining(t) = initial_fatigue * e^(-k * t)

where:
  t = hours since training
  k = muscle-specific decay constant (1/hours)
  initial_fatigue = f(volume_load, intensity, training_status)
```

#### Input Variables

```dart
class RecoveryInput {
  final String muscleGroup;
  final double volumeLoad;        // sets * reps * weight (kg)
  final double intensityPercent;  // % of 1RM used (0-100)
  final int setsPerformed;        // total working sets
  final double hoursSinceTraining;
  final String trainingStatus;    // 'beginner', 'intermediate', 'advanced'
  final double contributionRatio; // 1.0 for primary, 0.5-0.7 for secondary, 0.2-0.3 for tertiary
  final bool wasSupersetted;      // affects fatigue differently
}
```

#### Muscle-Specific Decay Constants (k)

These determine how fast each muscle recovers (higher k = faster recovery):

```dart
const Map<String, double> muscleDecayConstants = {
  // k values calibrated so that recovery reaches ~95% at the research-indicated time
  // Formula: k = -ln(0.05) / recovery_hours = 3.0 / recovery_hours
  'quads':      0.050,   // ~60 hours to 95% recovery
  'hamstrings': 0.042,   // ~72 hours
  'glutes':     0.050,   // ~60 hours
  'chest':      0.042,   // ~72 hours
  'back':       0.050,   // ~60 hours
  'shoulders':  0.063,   // ~48 hours
  'biceps':     0.042,   // ~72 hours (slower than size suggests)
  'triceps':    0.042,   // ~72 hours (slower than size suggests)
  'calves':     0.083,   // ~36 hours (very fast)
  'abs':        0.083,   // ~36 hours (very fast)
  'forearms':   0.083,   // ~36 hours
  'traps':      0.063,   // ~48 hours
  'lower_back': 0.042,   // ~72 hours
};
```

#### Initial Fatigue Calculation

```dart
double calculateInitialFatigue({
  required int sets,
  required double intensityPercent,
  required String trainingStatus,
  required double contributionRatio,
  required bool wasSupersetted,
}) {
  // Base fatigue from volume (sets)
  // Research: 3 sets at 10RM produces ~60% fatigue at 24h
  // Scale linearly with sets, with diminishing returns after 5 sets
  double volumeFatigue = min(1.0, sets / 6.0);  // 6 sets = max fatigue

  // Intensity modifier
  // Higher % 1RM = more fatigue per set
  // Research: strength sessions (85%+) require longer recovery
  double intensityModifier;
  if (intensityPercent >= 85) {
    intensityModifier = 1.3;  // Heavy strength work
  } else if (intensityPercent >= 70) {
    intensityModifier = 1.0;  // Hypertrophy range
  } else if (intensityPercent >= 60) {
    intensityModifier = 0.8;  // Endurance range
  } else {
    intensityModifier = 0.5;  // Light/warmup
  }

  // Training status modifier
  // Research (Damas 2016): untrained have MORE fatigue initially
  double statusModifier;
  switch (trainingStatus) {
    case 'beginner':
      statusModifier = 1.3;  // More muscle damage, longer recovery
    case 'intermediate':
      statusModifier = 1.0;
    case 'advanced':
      statusModifier = 0.85; // Better recovery capacity
  }

  // Superset modifier
  // Research: Agonist-antagonist supersets produce similar fatigue
  // Same-muscle supersets increase fatigue
  double supersetModifier = wasSupersetted ? 0.90 : 1.0;
  // Antagonist supersets don't increase per-muscle fatigue significantly

  // Contribution ratio: secondary muscles receive proportional fatigue
  // e.g., triceps during bench press get ~50% of chest fatigue

  double initialFatigue = volumeFatigue
    * intensityModifier
    * statusModifier
    * supersetModifier
    * contributionRatio;

  return initialFatigue.clamp(0.0, 1.0);
}
```

#### Recovery Score Function

```dart
double calculateRecoveryScore({
  required String muscleGroup,
  required double hoursSinceTraining,
  required double initialFatigue,
}) {
  final k = muscleDecayConstants[muscleGroup] ?? 0.042;

  // Exponential decay of fatigue
  double remainingFatigue = initialFatigue * exp(-k * hoursSinceTraining);

  // Recovery score is complement of remaining fatigue, as percentage
  double recovery = (1.0 - remainingFatigue) * 100.0;

  return recovery.clamp(0.0, 100.0);
}
```

#### Handling Multiple Recent Sessions (Overlapping Fatigue)

When a muscle has been trained multiple times recently, sum the remaining fatigue from each session:

```dart
double calculateCompositeRecovery({
  required String muscleGroup,
  required List<TrainingSession> recentSessions,
}) {
  final k = muscleDecayConstants[muscleGroup] ?? 0.042;

  double totalRemainingFatigue = 0.0;

  for (final session in recentSessions) {
    double initialFatigue = calculateInitialFatigue(
      sets: session.sets,
      intensityPercent: session.intensityPercent,
      trainingStatus: session.trainingStatus,
      contributionRatio: session.muscleContributions[muscleGroup] ?? 0.0,
      wasSupersetted: session.wasSupersetted,
    );

    double remaining = initialFatigue * exp(-k * session.hoursSinceTraining);
    totalRemainingFatigue += remaining;
  }

  // Cap total fatigue at 1.0 (can't be more than 100% fatigued)
  totalRemainingFatigue = totalRemainingFatigue.clamp(0.0, 1.0);

  return ((1.0 - totalRemainingFatigue) * 100.0).clamp(0.0, 100.0);
}
```

#### Primary/Secondary Muscle Contribution Ratios

Based on EMG research, here are contribution ratios for common compound exercises:

```dart
const Map<String, Map<String, double>> exerciseMuscleContributions = {
  // Format: exerciseType -> { muscleGroup: contributionRatio }
  // 1.0 = primary, 0.5 = secondary, 0.25 = tertiary

  'bench_press': {
    'chest': 1.0,
    'triceps': 0.65,
    'shoulders': 0.50,  // anterior deltoid
  },
  'incline_bench_press': {
    'chest': 0.85,       // upper chest emphasis
    'shoulders': 0.70,   // more anterior deltoid
    'triceps': 0.60,
  },
  'overhead_press': {
    'shoulders': 1.0,
    'triceps': 0.60,
    'chest': 0.20,       // upper chest minor
  },
  'squat': {
    'quads': 1.0,
    'glutes': 0.70,
    'hamstrings': 0.40,
    'lower_back': 0.35,
    'abs': 0.25,
  },
  'deadlift': {
    'back': 0.85,
    'hamstrings': 0.80,
    'glutes': 0.75,
    'quads': 0.40,
    'forearms': 0.50,    // grip
    'traps': 0.45,
    'lower_back': 0.70,
  },
  'barbell_row': {
    'back': 1.0,
    'biceps': 0.60,
    'rear_delts': 0.45,
    'forearms': 0.35,
  },
  'pull_up': {
    'back': 1.0,
    'biceps': 0.65,
    'forearms': 0.40,
    'abs': 0.20,
  },
  'dip': {
    'triceps': 0.85,
    'chest': 0.75,
    'shoulders': 0.40,
  },
  'lunges': {
    'quads': 0.85,
    'glutes': 0.75,
    'hamstrings': 0.45,
  },
  'romanian_deadlift': {
    'hamstrings': 1.0,
    'glutes': 0.70,
    'lower_back': 0.55,
    'forearms': 0.30,
  },
};

// Generic fallback based on exercise classification
const Map<String, double> defaultContributions = {
  'primary': 1.0,
  'secondary': 0.50,
  'tertiary': 0.25,
};
```

#### How Supersets Affect Recovery Differently

Research from the 2025 meta-analysis (PMC12011898) shows:

1. **Agonist-antagonist supersets** (e.g., chest + back): No significant increase in per-muscle fatigue. Each muscle gets adequate rest while the opposing muscle works. Use `supersetModifier = 0.90`.

2. **Same-muscle supersets** (e.g., bench press + chest fly): Significantly higher fatigue, higher blood lactate, greater perceived exertion. Use `supersetModifier = 1.20`.

3. **Alternate peripheral supersets** (e.g., upper body + lower body): Similar to agonist-antagonist. Use `supersetModifier = 0.90`.

---

### 1.4 How Other Apps Track Recovery

#### JEFIT
- Uses subjective feedback: RPE, RIR, bar speed, recovery quality
- Integrates wearable data: heart rate variability (HRV)
- NSPI (JEFIT Strength Performance Index) score tracks overall readiness
- No public details on specific muscle-level scoring algorithm

#### Dr. Muscle
- Prescribes loads based on user feedback per set
- Auto-regulates: progresses OR regresses load based on objective + subjective measures
- Prescribes deload weeks when plateaus occur
- Uses DUP to vary rep ranges automatically

#### RP Hypertrophy App
- Tracks fatigue via daily readiness scores
- Users rate: pump, soreness, perceived effort, "disruption" (general fatigue), joint pain, performance
- Auto-adjusts volume, intensity, and exercise selection based on readiness
- Uses MV/MEV/MAV/MRV framework to bound volume
- If RPE exceeds target (e.g., user reports RPE 8.5 vs planned RPE 7), app instantly adjusts: reduces final set reps, adds rest time, swaps next day's work

#### Tonal
- Displays muscle diagram showing fresh vs fatigued muscle groups
- Estimates 1RM per movement from performance history
- Strength Score is a composite of all individual lifts
- Recency-weighted: gives more importance to most recent sets

#### Juggernaut AI
- Readiness assessment before every workout: motivation, sleep quality, nutrition, muscle soreness (each 1-5 scale)
- If high leg fatigue reported, automatically reduces squat volume or intensity
- Uses block + DUP periodization blend
- Accumulation -> Intensification -> Realization phases

---

## TOPIC 2: Daily Undulating Periodization (DUP) Algorithms

### 2.1 Research Papers on DUP

#### 2.1.1 Zourdos et al. (2016) - Modified DUP

**Citation:** Zourdos MC, Jo E, Khamoui AV, et al. "Modified Daily Undulating Periodization Model Produces Greater Performance Than a Traditional Configuration in Powerlifters."
- PubMed ID: 26332783
- DOI: 10.1519/JSC.0000000000001276
- Journal of Strength and Conditioning Research, 2016

**Protocol:**
- 18 male college-aged powerlifters, 6 weeks
- Two groups: HSP (Hypertrophy-Strength-Power) vs HPS (Hypertrophy-Power-Strength)
- 3 non-consecutive training days per week
- Exercises: squat, bench press, deadlift

**Specific Loading:**
- **Hypertrophy day:** 5x8 at 75% 1RM (Week 1-2), 4x8 (Week 3-4), 3x8 (Week 5-6)
- **Strength day:** Reps to failure at given percentage
- **Power day:** Lower intensity, focus on bar speed

**Key Finding:** HPS (Hypertrophy-Power-Strength) rotation > HSP (Hypertrophy-Strength-Power). The power day between hypertrophy and strength provides better recovery, leading to higher total volume and better strength outcomes on the key strength day.

#### 2.1.2 Colquhoun et al. (2017) - Flexible DUP

**Citation:** Colquhoun RJ, Gai CM, Aguilar D, et al. "Comparison of Powerlifting Performance in Trained Men Using Traditional and Flexible Daily Undulating Periodization."
- PubMed ID: 28129275
- DOI: 10.1519/JSC.0000000000001816

**Key findings:**
- Flexible DUP (athletes choose which day to do which type) vs Traditional DUP (fixed order)
- Results: Nearly identical improvements
  - FDUP: bench +6.5kg, squat +15.6kg, deadlift +14.8kg
  - DUP: bench +8.8kg, squat +18.0kg, deadlift +13.6kg
- **Implication:** The specific day-to-day ordering matters LESS than ensuring all three stimulus types are included each week

#### 2.1.3 Meta-Analysis: DUP vs Linear (2022)

**Citation:** Moesgaard L, Beck MM, et al. "Effects of Periodization on Strength and Muscle Hypertrophy in Volume-Equated Resistance Training Programs: A Systematic Review and Meta-analysis"
- PubMed ID: 35044672
- Sports Medicine, 2022

**Key findings:**
- When volume is equated, undulating periodization (UP) produces greater 1RM increases than linear periodization (LP)
- For hypertrophy, the difference between LP and DUP is negligible
- **Trained individuals benefit more from DUP** than untrained
- Effect size for strength: DUP > LP (small but significant advantage)

#### 2.1.4 Nuckols (Stronger by Science) - DUP Analysis

**Citation:** Greg Nuckols, "Daily Undulating Periodization," Stronger by Science
- URL: https://www.strongerbyscience.com/daily-undulating-periodization/

**Key data:**
- DUP group: 3x8 Day 1, 3x6 Day 2, 3x4 Day 3 (12-week study)
- LP group: same average volume and intensity
- Results: DUP = 28.8% bench improvement, 55.8% leg press improvement
- LP: 14.4% bench, 25.7% leg press
- **DUP produced roughly 2x the strength gains of LP**

---

### 2.2 Concrete DUP Rotation Algorithm for Quick Workouts

For a context where users train 2-7x/week unpredictably, here is a practical DUP implementation:

#### Day Type Definitions

```dart
enum DUPDayType {
  hypertrophy,  // High volume, moderate intensity
  strength,     // Low volume, high intensity
  power,        // Moderate volume, low-moderate intensity, speed focus
  endurance,    // High reps, low intensity
}
```

#### DUP Day Parameters

```dart
const Map<DUPDayType, DUPParameters> dupParameters = {
  DUPDayType.hypertrophy: DUPParameters(
    repRange: (8, 12),
    intensityPercent: (65, 75),  // % 1RM
    sets: (3, 4),
    restSeconds: (60, 90),
    rpe: (7, 8),
    focus: 'time under tension',
  ),
  DUPDayType.strength: DUPParameters(
    repRange: (3, 6),
    intensityPercent: (80, 90),
    sets: (4, 5),
    restSeconds: (120, 180),
    rpe: (8, 9),
    focus: 'max force production',
  ),
  DUPDayType.power: DUPParameters(
    repRange: (3, 5),
    intensityPercent: (55, 70),
    sets: (3, 5),
    restSeconds: (90, 120),
    rpe: (6, 7),
    focus: 'bar speed and explosiveness',
  ),
  DUPDayType.endurance: DUPParameters(
    repRange: (15, 20),
    intensityPercent: (50, 65),
    sets: (2, 3),
    restSeconds: (30, 60),
    rpe: (6, 8),
    focus: 'muscular endurance',
  ),
};
```

#### State Machine Approach for Irregular Training

```dart
/// DUP Rotation State Machine
///
/// Tracks the LAST day type performed and rotates to the NEXT one,
/// regardless of calendar days elapsed. This handles irregular
/// training frequency gracefully.
class DUPRotationEngine {
  // Preferred rotation order (based on Zourdos HPS finding):
  // Hypertrophy -> Power -> Strength -> repeat
  // (Power between hypertrophy and strength provides recovery)
  static const List<DUPDayType> rotationOrder = [
    DUPDayType.hypertrophy,
    DUPDayType.power,
    DUPDayType.strength,
  ];

  /// Determine next day type based on history
  static DUPDayType getNextDayType({
    required DUPDayType? lastDayType,
    required double hoursSinceLastWorkout,
    required Map<String, double> muscleRecoveryScores,
    required String userGoal,   // 'strength', 'hypertrophy', 'general'
  }) {
    // If no history, start with hypertrophy (safest entry point)
    if (lastDayType == null) return DUPDayType.hypertrophy;

    // Get next in rotation
    final currentIdx = rotationOrder.indexOf(lastDayType);
    final nextIdx = (currentIdx + 1) % rotationOrder.length;
    DUPDayType proposed = rotationOrder[nextIdx];

    // Recovery-based override:
    // If training within 24 hours (back-to-back), prefer lighter day
    if (hoursSinceLastWorkout < 24) {
      if (proposed == DUPDayType.strength) {
        proposed = DUPDayType.endurance;  // Too soon for heavy work
      }
    }

    // If recovery scores are low (avg < 60%), force lighter day
    final avgRecovery = muscleRecoveryScores.values.isEmpty
      ? 100.0
      : muscleRecoveryScores.values.reduce((a, b) => a + b) / muscleRecoveryScores.values.length;

    if (avgRecovery < 50 && proposed == DUPDayType.strength) {
      proposed = DUPDayType.endurance;
    } else if (avgRecovery < 60 && proposed == DUPDayType.strength) {
      proposed = DUPDayType.power; // Power is less fatiguing
    }

    // Goal-based bias:
    // For strength-focused users, include strength day more often
    if (userGoal == 'strength' && hoursSinceLastWorkout > 72 && avgRecovery > 80) {
      proposed = DUPDayType.strength;
    }

    return proposed;
  }
}
```

#### Lookup Table Approach (Simpler Alternative)

```dart
/// Simple lookup for DUP day type based on workout count within current week
///
/// Handles 2-7 workouts per week with appropriate DUP distribution
const Map<int, List<DUPDayType>> weeklyDUPSchedules = {
  2: [DUPDayType.hypertrophy, DUPDayType.strength],
  3: [DUPDayType.hypertrophy, DUPDayType.power, DUPDayType.strength],
  4: [DUPDayType.hypertrophy, DUPDayType.power, DUPDayType.strength, DUPDayType.hypertrophy],
  5: [DUPDayType.hypertrophy, DUPDayType.power, DUPDayType.strength, DUPDayType.hypertrophy, DUPDayType.endurance],
  6: [DUPDayType.hypertrophy, DUPDayType.power, DUPDayType.strength, DUPDayType.hypertrophy, DUPDayType.power, DUPDayType.strength],
  7: [DUPDayType.hypertrophy, DUPDayType.power, DUPDayType.strength, DUPDayType.hypertrophy, DUPDayType.endurance, DUPDayType.power, DUPDayType.strength],
};
```

---

### 2.3 How Competitors Implement DUP

#### Fitbod
- Uses "non-linear periodization" - their term for DUP-like approach
- Sets, reps, and weights vary across sessions automatically
- Analyzes logged volume, intensity, fatigue patterns then recommends micro-adjustments
- Changes volume, intensity, and/or exercise selection to keep the body challenged

#### Dr. Muscle
- Explicitly uses DUP, citing Arizona State University research (29% vs 14% bench press improvement)
- AI predicts what user should lift based on performance history
- Adjusts in real-time and varies rep ranges through DUP
- Prescribes loads for each set based on user feedback
- Algorithm progresses or regresses based on objective + subjective measures

#### Juggernaut AI
- Blends block periodization WITH daily undulating periods each week
- Accumulation (high volume) -> Intensification (heavy loads) -> Realization (peaking)
- Within each block, daily undulation still occurs
- Readiness assessment before every workout modifies that day's parameters

---

## TOPIC 3: Post-Workout Feedback Algorithms

### 3.1 Data to Collect Post-Workout

```dart
class PostWorkoutFeedback {
  // Objective data (auto-captured)
  final Map<String, SetCompletion> completedSets;  // exercise -> completion
  final Duration totalTime;
  final Duration estimatedTime;
  final double completionRate;  // % of prescribed exercises completed

  // Subjective data (user input)
  final int overallRPE;        // 1-10, session RPE
  final int? soreness;         // 1-5, next day
  final int? energyLevel;      // 1-5, post-workout
  final String? generalFeel;   // 'too_easy', 'just_right', 'too_hard', 'destroyed'
}

class SetCompletion {
  final int prescribedReps;
  final int actualReps;
  final double prescribedWeight;
  final double actualWeight;
  final int? targetRPE;
  final int? actualRPE;
  final bool completed;
}
```

#### Algorithmic Uses of Each Data Point

| Data Point | Algorithmic Use |
|-----------|----------------|
| Completed sets vs prescribed | Adjust volume for next session |
| Actual weight vs prescribed | Update estimated 1RM |
| Actual RPE vs target RPE | If RPE consistently lower: increase weight. If higher: decrease |
| Completion rate | If < 80%: reduce volume next time. If 100%: consider adding |
| Time vs estimated | Calibrate time estimates for future workouts |
| Session RPE | Overall fatigue indicator; informs recovery scoring |

---

### 3.2 1RM Estimation Formulas

#### The Three Primary Formulas

```dart
/// Epley Formula (1985)
/// Best for: 2-5 reps (low rep ranges)
/// Slightly overestimates at high reps
double epley1RM(double weight, int reps) {
  if (reps <= 0) return weight;
  if (reps == 1) return weight;
  return weight * (1 + reps / 30.0);
}

/// Brzycki Formula (1993)
/// Best for: 6-10 reps (moderate rep ranges)
/// More conservative than Epley at low reps
double brzycki1RM(double weight, int reps) {
  if (reps <= 0) return weight;
  if (reps == 1) return weight;
  if (reps >= 37) return weight;  // Formula breaks at 37+ reps
  return weight / (1.0278 - 0.0278 * reps);
}

/// Mayhew Formula (1992)
/// Best for: 10-20 reps (high rep ranges)
/// Uses exponential decay, more stable at high reps
double mayhew1RM(double weight, int reps) {
  if (reps <= 0) return weight;
  if (reps == 1) return weight;
  return (100 * weight) / (52.2 + 41.9 * exp(-0.055 * reps));
}
```

#### Accuracy by Rep Range (Research Summary)

| Rep Range | Best Formula | Typical Error |
|-----------|-------------|---------------|
| 1-3       | Epley       | 2-3%          |
| 3-5       | Epley/Wathen | 2-4%         |
| 6-10      | Brzycki     | 3-5%          |
| 10-15     | Mayhew      | 5-8%          |
| 15-20     | Mayhew      | 8-12%         |
| 20+       | All poor    | 12%+          |

**Sources:**
- [1RM Formulas Explained](https://maxcalculator.com/guides/1rm-formulas)
- [Wikipedia: One-repetition maximum](https://en.wikipedia.org/wiki/One-repetition_maximum)
- [Validation of Brzycki and Epley](https://opensiuc.lib.siu.edu/cgi/viewcontent.cgi?article=1744&context=gs_rp)

#### Composite Formula (Recommended for Implementation)

Use the best formula based on rep range for maximum accuracy:

```dart
/// Adaptive 1RM estimation using the most accurate formula for the rep range
double estimate1RM(double weight, int reps) {
  if (reps <= 0) return weight;
  if (reps == 1) return weight;

  if (reps <= 5) {
    return epley1RM(weight, reps);
  } else if (reps <= 10) {
    // Blend Epley and Brzycki in the transition zone
    final e = epley1RM(weight, reps);
    final b = brzycki1RM(weight, reps);
    return (e + b) / 2.0;
  } else {
    return mayhew1RM(weight, reps);
  }
}
```

#### Incremental 1RM Updates (Exponential Moving Average)

Instead of replacing the 1RM with every new estimate, use an EMA to smooth out noise:

```dart
/// Update 1RM estimate using Exponential Moving Average
///
/// Alpha controls how much weight new data gets:
/// - alpha = 0.3: responsive to recent performance (recommended)
/// - alpha = 0.1: very conservative, slow to change
/// - alpha = 0.5: very responsive, volatile
double updateEstimated1RM({
  required double current1RM,
  required double newEstimate,
  double alpha = 0.3,
  int? repsPerformed,
}) {
  // Adjust alpha based on confidence (lower reps = more confident estimate)
  double adjustedAlpha = alpha;
  if (repsPerformed != null) {
    if (repsPerformed <= 3) {
      adjustedAlpha = alpha * 1.5;  // High confidence, respond faster
    } else if (repsPerformed >= 15) {
      adjustedAlpha = alpha * 0.5;  // Low confidence, respond slower
    }
  }
  adjustedAlpha = adjustedAlpha.clamp(0.05, 0.7);

  // Guard against clearly erroneous estimates
  // (> 20% change in a single session is suspicious)
  final ratio = newEstimate / current1RM;
  if (ratio > 1.20 || ratio < 0.80) {
    adjustedAlpha *= 0.3;  // Heavily dampen suspicious changes
  }

  return current1RM * (1 - adjustedAlpha) + newEstimate * adjustedAlpha;
}
```

---

### 3.3 Progressive Overload Decision Algorithms

#### RPE-to-%1RM Conversion Table

Based on the Tuchscherer RPE scale:

```dart
/// RPE to %1RM conversion matrix
/// Rows: reps (1-12), Columns: RPE (6-10 in 0.5 increments)
/// Values: percentage of 1RM
const Map<int, Map<double, double>> rpeToPercent = {
  1:  {10.0: 100.0, 9.5: 97.8, 9.0: 95.5, 8.5: 93.9, 8.0: 92.2, 7.5: 90.7, 7.0: 89.2, 6.5: 87.6, 6.0: 86.3},
  2:  {10.0: 95.5, 9.5: 93.9, 9.0: 92.2, 8.5: 90.7, 8.0: 89.2, 7.5: 87.6, 7.0: 86.3, 6.5: 85.0, 6.0: 83.7},
  3:  {10.0: 92.2, 9.5: 90.7, 9.0: 89.2, 8.5: 87.6, 8.0: 86.3, 7.5: 85.0, 7.0: 83.7, 6.5: 82.4, 6.0: 81.1},
  4:  {10.0: 89.2, 9.5: 87.6, 9.0: 86.3, 8.5: 85.0, 8.0: 83.7, 7.5: 82.4, 7.0: 81.1, 6.5: 79.9, 6.0: 78.6},
  5:  {10.0: 86.3, 9.5: 85.0, 9.0: 83.7, 8.5: 82.4, 8.0: 81.1, 7.5: 79.9, 7.0: 78.6, 6.5: 77.4, 6.0: 76.2},
  6:  {10.0: 83.7, 9.5: 82.4, 9.0: 81.1, 8.5: 79.9, 8.0: 78.6, 7.5: 77.4, 7.0: 76.2, 6.5: 75.1, 6.0: 73.9},
  7:  {10.0: 81.1, 9.5: 79.9, 9.0: 78.6, 8.5: 77.4, 8.0: 76.2, 7.5: 75.1, 7.0: 73.9, 6.5: 72.3, 6.0: 70.7},
  8:  {10.0: 78.6, 9.5: 77.4, 9.0: 76.2, 8.5: 75.1, 8.0: 73.9, 7.5: 72.3, 7.0: 70.7, 6.5: 69.4, 6.0: 68.0},
  9:  {10.0: 76.2, 9.5: 75.1, 9.0: 73.9, 8.5: 72.3, 8.0: 70.7, 7.5: 69.4, 7.0: 68.0, 6.5: 66.7, 6.0: 65.3},
  10: {10.0: 73.9, 9.5: 72.3, 9.0: 70.7, 8.5: 69.4, 8.0: 68.0, 7.5: 66.7, 7.0: 65.3, 6.5: 64.0, 6.0: 62.6},
  12: {10.0: 70.7, 9.5: 69.4, 9.0: 68.0, 8.5: 66.7, 8.0: 65.3, 7.5: 64.0, 7.0: 62.6, 6.5: 61.3, 6.0: 59.9},
};
```

#### Double Progression Algorithm

The most practical progressive overload method for app users:

```dart
/// Double Progression Decision Engine
///
/// Step 1: Perform sets at bottom of rep range with current weight
/// Step 2: Each session, try to add reps until top of range
/// Step 3: When ALL sets are at top of range with target RPE, increase weight
/// Step 4: Drop reps back to bottom of range at new weight
///
/// Example for hypertrophy (8-12 reps):
/// Week 1: 60kg x 8, 8, 8 reps
/// Week 2: 60kg x 9, 9, 8 reps
/// Week 3: 60kg x 10, 10, 9 reps
/// Week 4: 60kg x 12, 11, 11 reps
/// Week 5: 60kg x 12, 12, 12 reps  -> PROGRESSION TRIGGER
/// Week 6: 62.5kg x 8, 8, 8 reps   -> Weight increased, reps reset

class DoubleProgressionEngine {

  /// Determine the next session's prescription based on last performance
  static ProgressionDecision decide({
    required String goal,
    required List<SetCompletion> lastSessionSets,
    required double currentWeight,
    required double estimated1RM,
    required String equipmentType,
    required String trainingStatus,
  }) {
    final (minReps, maxReps) = _getRepRange(goal);

    // Count how many working sets hit the top of the rep range
    final workingSets = lastSessionSets.where((s) => s.completed).toList();
    if (workingSets.isEmpty) {
      return ProgressionDecision.maintain(currentWeight, minReps);
    }

    final allAtMax = workingSets.every((s) => s.actualReps >= maxReps);
    final avgReps = workingSets.map((s) => s.actualReps).reduce((a, b) => a + b) / workingSets.length;
    final avgRPE = workingSets.where((s) => s.actualRPE != null)
        .map((s) => s.actualRPE!)
        .fold<double>(0, (a, b) => a + b) /
        workingSets.where((s) => s.actualRPE != null).length;

    // Check for RPE-based auto-regulation
    if (avgRPE < 6.0 && avgReps >= maxReps) {
      // Too easy even at max reps - increase weight immediately
      return ProgressionDecision.increaseWeight(
        currentWeight,
        _getWeightIncrement(equipmentType, trainingStatus),
        minReps,
        'RPE too low - increase weight',
      );
    }

    if (avgRPE > 9.5) {
      // Too hard - decrease weight
      return ProgressionDecision.decreaseWeight(
        currentWeight,
        _getWeightIncrement(equipmentType, trainingStatus),
        (minReps + maxReps) ~/ 2,
        'RPE too high - reduce weight for better quality reps',
      );
    }

    // Standard double progression logic
    if (allAtMax && avgRPE <= 8.5) {
      // All sets at top of range with manageable RPE -> increase weight
      return ProgressionDecision.increaseWeight(
        currentWeight,
        _getWeightIncrement(equipmentType, trainingStatus),
        minReps,
        'All sets at top of rep range - increasing weight',
      );
    }

    if (avgReps >= minReps) {
      // Making progress but not ready to increase weight yet
      final targetReps = min(maxReps, (avgReps + 1).round());
      return ProgressionDecision.increaseReps(
        currentWeight,
        targetReps,
        'Progressing reps toward top of range',
      );
    }

    // Struggling at current weight
    return ProgressionDecision.maintain(currentWeight, minReps);
  }

  static (int, int) _getRepRange(String goal) {
    switch (goal) {
      case 'strength': return (3, 6);
      case 'hypertrophy': return (8, 12);
      case 'endurance': return (15, 20);
      default: return (8, 12);
    }
  }

  static double _getWeightIncrement(String equipmentType, String trainingStatus) {
    // Smaller increments for advanced lifters (they're closer to max)
    final base = {
      'barbell': 2.5,
      'dumbbell': 2.0,
      'machine': 5.0,
      'cable': 2.5,
      'kettlebell': 4.0,
    }[equipmentType] ?? 2.5;

    // Advanced lifters use smaller increments
    if (trainingStatus == 'advanced') return base * 0.5;
    if (trainingStatus == 'beginner') return base;
    return base;  // intermediate
  }
}

class ProgressionDecision {
  final double weight;
  final int targetReps;
  final String action;  // 'increase_weight', 'increase_reps', 'maintain', 'decrease_weight'
  final String reason;

  ProgressionDecision.increaseWeight(double current, double increment, int reps, this.reason)
    : weight = current + increment, targetReps = reps, action = 'increase_weight';

  ProgressionDecision.increaseReps(this.weight, this.targetReps, this.reason)
    : action = 'increase_reps';

  ProgressionDecision.maintain(this.weight, this.targetReps)
    : action = 'maintain', reason = 'Continue working at current weight';

  ProgressionDecision.decreaseWeight(double current, double decrement, int reps, this.reason)
    : weight = current - decrement, targetReps = reps, action = 'decrease_weight';
}
```

#### RPE-Based Auto-Regulation Decision Tree

```
Input: targetRPE, actualRPE, completedReps, targetReps

IF actualRPE > targetRPE + 1.5:
  -> DELOAD: Reduce weight 5-10%, reduce sets by 1

ELIF actualRPE > targetRPE + 0.5:
  -> SLIGHT REGRESSION: Reduce weight 2.5-5%

ELIF actualRPE == targetRPE +/- 0.5:
  -> ON TRACK: Maintain weight, follow double progression

ELIF actualRPE < targetRPE - 0.5:
  -> READY TO PROGRESS: Increase weight by 1 increment

ELIF actualRPE < targetRPE - 1.5:
  -> SIGNIFICANTLY UNDER-CHALLENGED: Increase weight by 2 increments
  -> Flag: 1RM estimate may be outdated
```

---

## TOPIC 4: Volume Landmarks (MEV/MAV/MRV)

### 4.1 Dr. Mike Israetel's Volume Landmark Data

Based on RP Strength publications, RP Hypertrophy app documentation, and the Israetel training volume landmark series:

#### Complete Volume Landmarks Table (Sets per Week)

```dart
class VolumeLandmarks {
  final int mv;       // Maintenance Volume
  final int mev;      // Minimum Effective Volume
  final int mavLow;   // MAV lower bound
  final int mavHigh;  // MAV upper bound
  final int mrv;      // Maximum Recoverable Volume
  final double freqMin; // Minimum training frequency per week
  final double freqMax; // Maximum training frequency per week

  const VolumeLandmarks({
    required this.mv,
    required this.mev,
    required this.mavLow,
    required this.mavHigh,
    required this.mrv,
    required this.freqMin,
    required this.freqMax,
  });
}

const Map<String, VolumeLandmarks> volumeLandmarksIntermediate = {
  'chest':        VolumeLandmarks(mv: 8,  mev: 10, mavLow: 12, mavHigh: 20, mrv: 22, freqMin: 1.5, freqMax: 3.0),
  'back':         VolumeLandmarks(mv: 8,  mev: 10, mavLow: 14, mavHigh: 22, mrv: 25, freqMin: 2.0, freqMax: 4.0),
  'quads':        VolumeLandmarks(mv: 6,  mev: 8,  mavLow: 12, mavHigh: 18, mrv: 20, freqMin: 1.5, freqMax: 3.0),
  'hamstrings':   VolumeLandmarks(mv: 4,  mev: 6,  mavLow: 10, mavHigh: 16, mrv: 20, freqMin: 2.0, freqMax: 3.0),
  'glutes':       VolumeLandmarks(mv: 0,  mev: 0,  mavLow: 4,  mavHigh: 12, mrv: 16, freqMin: 2.0, freqMax: 3.0),
  'shoulders':    VolumeLandmarks(mv: 0,  mev: 0,  mavLow: 6,  mavHigh: 8,  mrv: 12, freqMin: 1.0, freqMax: 2.0), // front delts
  'rear_delts':   VolumeLandmarks(mv: 0,  mev: 8,  mavLow: 16, mavHigh: 22, mrv: 26, freqMin: 2.0, freqMax: 6.0),
  'side_delts':   VolumeLandmarks(mv: 0,  mev: 8,  mavLow: 16, mavHigh: 22, mrv: 26, freqMin: 2.0, freqMax: 6.0),
  'biceps':       VolumeLandmarks(mv: 5,  mev: 8,  mavLow: 14, mavHigh: 20, mrv: 26, freqMin: 2.0, freqMax: 6.0),
  'triceps':      VolumeLandmarks(mv: 4,  mev: 6,  mavLow: 10, mavHigh: 14, mrv: 18, freqMin: 2.0, freqMax: 4.0),
  'calves':       VolumeLandmarks(mv: 6,  mev: 8,  mavLow: 12, mavHigh: 16, mrv: 20, freqMin: 2.0, freqMax: 4.0),
  'abs':          VolumeLandmarks(mv: 0,  mev: 0,  mavLow: 16, mavHigh: 20, mrv: 25, freqMin: 3.0, freqMax: 5.0),
  'traps':        VolumeLandmarks(mv: 0,  mev: 0,  mavLow: 12, mavHigh: 20, mrv: 26, freqMin: 2.0, freqMax: 6.0),
  'forearms':     VolumeLandmarks(mv: 0,  mev: 0,  mavLow: 6,  mavHigh: 12, mrv: 16, freqMin: 2.0, freqMax: 6.0),
};
```

#### Training Status Adjustments

```dart
/// Adjust volume landmarks based on training experience
///
/// Beginners: MEV is lower, MRV is lower
/// Advanced: MEV is higher, MRV is higher
VolumeLandmarks adjustForTrainingStatus(VolumeLandmarks base, String status) {
  switch (status) {
    case 'beginner':
      return VolumeLandmarks(
        mv: (base.mv * 0.75).round(),
        mev: max(2, (base.mev * 0.6).round()),   // Beginners grow from less
        mavLow: (base.mavLow * 0.7).round(),
        mavHigh: (base.mavHigh * 0.7).round(),
        mrv: (base.mrv * 0.65).round(),           // Can't handle as much
        freqMin: base.freqMin,
        freqMax: min(base.freqMax, 3.0),
      );
    case 'advanced':
      return VolumeLandmarks(
        mv: base.mv,
        mev: (base.mev * 1.3).round(),            // Need more to grow
        mavLow: (base.mavLow * 1.2).round(),
        mavHigh: (base.mavHigh * 1.2).round(),
        mrv: (base.mrv * 1.25).round(),            // Can handle more
        freqMin: base.freqMin,
        freqMax: base.freqMax,
      );
    default: // intermediate
      return base;
  }
}
```

**Key Definitions Recap:**
- **MV (Maintenance Volume):** Sets per week to maintain current muscle mass. Typically ~6 sets/week when training 2x/week. Front delts, glutes, abs, and traps often need 0 direct maintenance because compound movements cover them.
- **MEV (Minimum Effective Volume):** Minimum sets per week to produce measurable muscle growth. The starting point for a mesocycle.
- **MAV (Maximum Adaptive Volume):** The sweet spot range where most of your training should live for optimal gains. NOT a single number but a range that you progress through during a mesocycle.
- **MRV (Maximum Recoverable Volume):** The ceiling. Training above this leads to overtraining and regression. The end point of a mesocycle before deloading.

**Sources:**
- [RP Strength: Training Volume Landmarks for Muscle Growth](https://rpstrength.com/blogs/articles/training-volume-landmarks-muscle-growth)
- [RP Strength: Chest Hypertrophy Training Tips](https://rpstrength.com/blogs/articles/chest-hypertrophy-training-tips)
- [RP Strength: Back Hypertrophy Training Tips](https://rpstrength.com/blogs/articles/back-hypertrophy-training-tips)
- [RP Strength: Bicep Hypertrophy Training Tips](https://rpstrength.com/blogs/articles/bicep-hypertrophy-training-tips)
- [RP Strength: Quad Hypertrophy Training Tips](https://rpstrength.com/blogs/articles/quad-hypertrophy-training-tips)
- [Volume Landmarks Vercel App](https://volume-landmarks-rp-rals.vercel.app/)
- [Scribd: Dr. Mike Israetel Training Volume Landmarks](https://www.scribd.com/document/475029266/Dr-Mike-Israetel-Training-Volume-Landmarks-Hypertrophy-Routine-LiftVault-com-Sets-Per-Week-Summary)

---

### 4.2 Quick Workout Session Volume Analysis

#### Can You Reach MEV in a Single 15-Minute Session?

**Analysis based on the data:**

For a 15-minute session with ~120 seconds of warmup, you have ~780 seconds of working time.

- Straight sets: ~180 seconds per exercise = ~4 exercises
- With supersets: ~150 seconds per paired exercise = ~5-6 exercises
- At 2-3 sets per exercise = **6-9 total sets per session**

**Per-muscle MEV analysis for single session:**

| Muscle Group | MEV (sets/week) | Sets possible in 15min | Can reach MEV in 1 session? |
|-------------|-----------------|----------------------|---------------------------|
| Chest       | 10              | 3-4 (2 exercises)    | No - need ~3 sessions/week |
| Back        | 10              | 3-4                   | No - need ~3 sessions/week |
| Quads       | 8               | 3-4                   | Borderline - 2-3 sessions  |
| Hamstrings  | 6               | 2-3                   | Borderline - 2-3 sessions  |
| Glutes      | 0 (compound covers) | 2-3              | Yes - compounds cover it   |
| Biceps      | 8               | 2-3                   | No - need 3+ sessions      |
| Triceps     | 6               | 2-3                   | Borderline - 2-3 sessions  |
| Calves      | 8               | 2-3                   | No - need 3+ sessions      |
| Abs         | 0               | 3-4                   | Yes - easily covered        |
| Front delts | 0               | -                     | Yes - pressing covers it    |
| Rear delts  | 8               | 2-3                   | No - need 3+ sessions      |

**Conclusion:** A single 15-minute session CANNOT reach MEV for most muscle groups. The strategy should be:
1. Focus on 2-3 muscle groups per session
2. Use compound movements to hit multiple muscle groups simultaneously
3. Track weekly volume accumulation across multiple quick sessions
4. Ensure weekly total meets MEV targets

#### Minimum Stimulus Per Session

**Research (PMID: 31797219):** A single set of 6-12 repetitions at 70-85% 1RM, performed 2-3x/week, is the minimum effective training dose to increase 1RM strength in resistance-trained men.

**Research (PMID: 30558493):** 4 sets per muscle group per week is supported as a practical minimum to induce meaningful hypertrophy.

**Practical minimum per session for stimulus:**
- **2 sets** per muscle group is the absolute minimum per session to generate any meaningful signal (when combined with 2+ sessions per week for that muscle)
- **3-4 sets** per muscle group per session is the practical sweet spot for quick workouts
- Intensity must be high (RPE 7-9) when volume is minimal

#### Weekly Volume Distribution Algorithm

```dart
/// Distribute weekly volume targets across quick sessions
///
/// For users training with quick workouts only, calculate per-session
/// volume targets to accumulate MEV+ over the week.
class WeeklyVolumeDistributor {

  /// Calculate sets per muscle group per session
  static Map<String, int> distributeVolume({
    required Map<String, VolumeLandmarks> landmarks,
    required int sessionsPerWeek,
    required int sessionDurationMinutes,
    required List<String> targetMuscleGroups,
    required String trainingStatus,
  }) {
    final result = <String, int>{};

    // Calculate available sets per session
    // (based on session duration and format)
    final warmupSeconds = QuickWorkoutConstants.getWarmupSeconds(sessionDurationMinutes);
    final workingSeconds = (sessionDurationMinutes * 60) - warmupSeconds - 45;
    final availableSetsPerSession = (workingSeconds / 120).floor(); // ~120s per set including rest

    // Target: MAV midpoint distributed across sessions
    for (final muscle in targetMuscleGroups) {
      final vl = landmarks[muscle];
      if (vl == null) continue;

      // Target weekly volume: midpoint of MAV range
      final weeklyTarget = ((vl.mavLow + vl.mavHigh) / 2).round();

      // Sets per session for this muscle
      int setsPerSession = (weeklyTarget / sessionsPerWeek).ceil();

      // Minimum 2 sets per session for meaningful stimulus
      setsPerSession = setsPerSession.clamp(2, 6);

      result[muscle] = setsPerSession;
    }

    // Validate total doesn't exceed available time
    final totalSets = result.values.fold<int>(0, (a, b) => a + b);
    if (totalSets > availableSetsPerSession) {
      // Scale down proportionally
      final ratio = availableSetsPerSession / totalSets;
      for (final key in result.keys.toList()) {
        result[key] = max(2, (result[key]! * ratio).round());
      }
    }

    return result;
  }
}
```

---

## SUPPLEMENTARY: Mathematical Model References

### Fatigue-Recovery Biomechanical Models

**Three-Compartment Controller (3CC) Model** for muscle fatigue:
- Source: Xia & Frey Law (2008), "A theoretical approach for modeling peripheral muscle fatigue and recovery"
- PubMed ID: 18977478
- Model: Muscle exists in three states: Resting (MR), Activated (MA), Fatigued (MF)
- MR + MA + MF = 1.0 at all times
- Recovery rate R and fatigue rate F govern transitions
- During rest: MF -> MR at rate R (exponential recovery)
- During work: MA -> MF at rate F

**Fitness-Fatigue Model (Banister):**
- Source: Banister et al. (1975), "A systems model of training for athletic performance"
- Performance(t) = Fitness(t) - Fatigue(t)
- Fitness(t) = sum of training impulses * e^(-t/tau_fitness)
- Fatigue(t) = sum of training impulses * e^(-t/tau_fatigue)
- tau_fitness ~ 45 days (slow decay)
- tau_fatigue ~ 15 days (fast decay)
- This is for overall performance, not per-muscle recovery, but the exponential decay principle applies

### Recent Meta-Analysis (2025)

**Pelland et al. (2025)** - "The Resistance Training Dose Response: Meta-Regressions Exploring the Effects of Weekly Volume and Frequency on Muscle Hypertrophy and Strength Gains"
- PubMed ID: 41343037
- SportRxiv preprint + published in Sports Medicine
- 67 studies, 2058 participants
- Key finding: Hypertrophy increases with volume (diminishing returns) at ~0.24% per additional set at the average of 12.25 sets/week
- Frequency effect on hypertrophy: negligible when volume is equated
- **Critical finding:** Distinguishing between direct and indirect sets matters for predicting adaptations

---

## Summary of Key Constants for Implementation

### Recovery Constants
```
Decay constants (k, per hour):
  Fast recovery group (calves, abs, forearms):  k = 0.083 (~36h to 95%)
  Medium recovery group (shoulders, traps):      k = 0.063 (~48h to 95%)
  Standard recovery group (all others):          k = 0.042 (~72h to 95%)
```

### DUP Rotation
```
Preferred order: Hypertrophy -> Power -> Strength (HPS per Zourdos)
Hypertrophy: 8-12 reps, 65-75% 1RM, RPE 7-8
Power: 3-5 reps, 55-70% 1RM, RPE 6-7
Strength: 3-6 reps, 80-90% 1RM, RPE 8-9
Endurance: 15-20 reps, 50-65% 1RM, RPE 6-8
```

### 1RM Formulas
```
Epley:   1RM = W * (1 + R/30)                    [best for 2-5 reps]
Brzycki: 1RM = W / (1.0278 - 0.0278 * R)         [best for 6-10 reps]
Mayhew:  1RM = (100 * W) / (52.2 + 41.9 * e^(-0.055*R))  [best for 10+ reps]
EMA update: new1RM = current * (1-alpha) + estimate * alpha  [alpha=0.3]
```

### Progressive Overload
```
Double Progression:
  1. Start at bottom of rep range with current weight
  2. Add reps each session until all sets at top of range
  3. Increase weight by 1 increment, reset reps to bottom
  Weight increments: Barbell 2.5kg, Dumbbell 2.0kg, Machine 5.0kg
  RPE overshoot (>1.5 above target): deload
  RPE undershoot (<1.5 below target): increase weight by 2 increments
```

### Volume Landmarks (Intermediate, sets/week)
```
Muscle     | MV | MEV | MAV       | MRV
-----------|----|----|-----------|----
Chest      | 8  | 10 | 12-20    | 22
Back       | 8  | 10 | 14-22    | 25
Quads      | 6  | 8  | 12-18    | 20
Hamstrings | 4  | 6  | 10-16    | 20
Glutes     | 0  | 0  | 4-12     | 16
Shoulders  | 0  | 0  | 6-8      | 12
Biceps     | 5  | 8  | 14-20    | 26
Triceps    | 4  | 6  | 10-14    | 18
Calves     | 6  | 8  | 12-16    | 20
Abs        | 0  | 0  | 16-20    | 25
```
