# Set Progression Edge Case Test Report

**Date**: 2026-03-28
**Tests**: 49/49 passed (10 scenarios + 5 bonus edge cases)
**Test file**: `test/models/set_progression_edge_cases_test.dart`

## Results Summary

| # | Pattern | Equipment | Display | Increment | Set Completed | RIR | Expected Next Set | Actual Next Set | Pass |
|---|---------|-----------|---------|-----------|---------------|-----|-------------------|-----------------|------|
| S1 | Pyramid Up | Dumbbell | lbs | 2.5 lbs | 20 lb x 15 | 3 | 25.0 lb x 12 | 25.0 lb x 12 | PASS |
| S2 | Pyramid Up | Barbell | kg | 2.5 kg | 60 kg x 12 | 2 | 62.5 kg x 10 | 62.5 kg x 10 | PASS |
| S3 | Rev. Pyramid | Dumbbell | kg | 2.5 kg | 20 kg x 8 | 0 | 15.0 kg x 11 | 15.0 kg x 11 | PASS |
| S4 | Straight | Machine | lbs | 10 lbs | 100 lb x 12 | 4 | 120.0 lb x 10 | 120.0 lb x 10 | PASS |
| S5 | Drop Sets | Cable | kg | 5 kg | 50 kg x 4 AMRAP | - | 35.0 kg x AMRAP | 35.0 kg x AMRAP | PASS |
| S6 | Top+BackOff | Barbell | lbs | 5 lbs | 225 lb x 4 | 1 | 185.0 lb x 6 | 185.0 lb x 6 | PASS |
| S7 | Myo-Reps | Dumbbell | kg | 2.5 kg | 15 kg x 7 | - | 12.5 kg x 5 | 12.5 kg x 5 | PASS |
| S8 | Rest-Pause | Machine | lbs | 5 lbs | 150 lb x 4 AMRAP | - | 135.0 lb x AMRAP | 135.0 lb x AMRAP | PASS |
| S9 | Endurance | Dumbbell | lbs | 2.5 lbs | 15 lb x 20 | 3 | 17.5 lb x 21 | 17.5 lb x 21 | PASS |
| S10 | Pyramid Up | Barbell | kg | 2.5 kg | 100 kg x 3 (5 sets) | 3 | 97.5 kg x 9 | 97.5 kg x 9 | PASS |

## Bonus Edge Cases

| # | Description | Expected | Actual | Pass |
|---|-------------|----------|--------|------|
| B1 | Dart rounds half away from zero | 4.5.round() = 5 | 5 | PASS |
| B1 | snap(22.5, 5) = 25 (not 20) | 25 | 25 | PASS |
| B2 | Pyramid consistency: set 3 from set 1 == set 3 from set 2 | 25.0 x 11 | 25.0 x 11 | PASS |
| B3 | Unit mismatch (kg inc, lbs display): doesn't crash | ~132.28 | ~132.28 | PASS |
| B4 | Goal clamping squashes pyramid (muscle_strength) | Sets 0,1 both 5 reps | 5, 5 | PASS |
| B5 | Empty completedSets returns originals | unchanged | unchanged | PASS |
| B5 | All sets completed returns originals | unchanged | unchanged | PASS |
| B5 | Fatigue override >25% drop | -1 increment | -1 increment | PASS |

## Scenario Details

### S1: Pyramid Up — User's exact scenario
- **Setup**: Dumbbell, lbs, 2.5 lbs increment, 3 sets
- **Flow**: 20 lbs x 15 reps, RIR 3
  - baseReps = 15 - 4 = 11 (reversed pyramid offset)
  - workingWeight = 20 + 2 x 2.5 = 25 lbs
  - Targets: [20x15, 22.5x13, 25x11]
  - Adaptive: RIR 3 + repRatio 1.0 = "too easy" -> +1 increment
  - **Result**: Set 2 = **25.0 lbs x 12 reps** (weight up, reps down)

### S2: Pyramid Up — No adjustment (on target)
- RIR 2 with full reps = on target -> no adaptive change
- **Result**: Set 2 = **62.5 kg x 10 reps** (pure pyramid progression)

### S3: Reverse Pyramid — Failure on heaviest set
- RIR 0 = went to failure -> -1 increment on remaining sets
- Weight drops MORE aggressively: 17.5 -> 15.0 kg
- **Result**: Set 2 = **15.0 kg x 11 reps** (lighter, protect user)

### S4: Straight Sets — Way too easy
- RIR 4 = "lots in the tank" -> +2 increments (aggressive jump)
- **Result**: Set 2 = **120.0 lbs x 10 reps** (+20 lbs, -2 reps)

### S5: Drop Sets — Wider drop for low reps
- Only 4 reps at 50 kg -> too heavy, use 28% drop instead of 20%
- **Result**: Set 2 = **35.0 kg x AMRAP** (vs standard 40 kg)

### S6: Top Set + Back-Off — Acceptable effort
- RIR 1 with full reps is normal for a top set
- Back-off at 83%: 225 x 0.83 = 186.75 -> snap to 185
- **Result**: Set 2 = **185.0 lbs x 6 reps** (no adjustment)

### S7: Myo-Reps — Under-reps on activation
- Only 7 reps (< 9 threshold) -> reduce mini-set weight by 15%
- 15 x 0.85 = 12.75 -> snap to 12.5 kg
- **Result**: Mini-set = **12.5 kg x 5 reps**

### S8: Rest-Pause — Can't sustain weight
- Only 4 reps (< 6 threshold) -> reduce by 10%
- 150 x 0.90 = 135 -> snap to 135
- **Result**: Set 2 = **135.0 lbs x AMRAP**

### S9: Endurance — Too easy
- RIR 3 at 20 reps -> weight bumps up, reps still increase per set
- **Result**: Set 2 = **17.5 lbs x 21 reps** (+2.5 lb, -1 from adaptive)

### S10: Catastrophic Miss — 5-set Pyramid
- Only 3 reps, baseReps floored to 6 (min effective reps), step=2
- Targets regenerated: [14, 12, 10, 8, 6]
- repRatio = 3/14 = 0.21 -> -2 increments
- **Result**: Set 2 = **97.5 kg x 14 reps** (weight DOWN, reps UP to hypertrophy range)

## Known Limitations

1. **Unit mismatch** (B3): When increment unit (kg) differs from display unit (lbs), the effective increment is 5.51 lbs which doesn't snap to clean gym weights. Weights may show as 132.3 instead of 135. Recommendation: match increment unit to display unit.

2. **Goal clamping squashes pyramid** (B4): With muscle_strength goal (1-5 reps) and low baseReps, sets 0 and 1 of a pyramid can both clamp to 5 reps, losing the pyramid's rep differentiation. Not a bug — expected behavior of rep range enforcement.

3. **Low-rep pyramid — FIXED**: baseReps now floors to 6 (minimum effective rep range). Dynamic step: ±1 for strength (≤5 baseReps), ±2 for hypertrophy (6+). Example: 5 reps on set 1 → baseReps=6, step=2 → targets [10, 8, 6]. System guides user toward proper hypertrophy range.
