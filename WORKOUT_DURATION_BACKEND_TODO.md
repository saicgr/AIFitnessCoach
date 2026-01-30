# Workout Duration Backend Implementation TODO

## Problem
Currently, the workout duration is stored as a single exact number (e.g., "45 minutes"), but it should be treated as a time constraint/range that Gemini respects when generating workouts.

## Frontend Changes (COMPLETED ✅)
1. ✅ Updated UI to show duration ranges instead of exact numbers:
   - `<30` instead of `30`
   - `30-45` instead of `45`
   - `45-60` instead of `60`
   - `60-75` instead of `75`
   - `75-90` instead of `90`

2. ✅ Updated subtitle to clarify: "Your workout duration target (AI will generate within this range)"

3. ✅ Location: `mobile/flutter/lib/screens/onboarding/widgets/quiz_days_selector.dart:35-41`

## Backend Changes Required (COMPLETED ✅)

### 1. Update Gemini Prompt Instructions ✅
**File:** `backend/services/gemini_service.py` (Lines 2369-2372, 2852-2855)

**Status:** ALREADY IMPLEMENTED - Gemini service already supports duration ranges!
- Uses range text like "30-45 minutes" when min/max provided
- Falls back to single duration when only one value provided
- Includes both `duration_minutes_min` and `duration_minutes_max` in JSON response structure

### 2. Add Duration Range Support to `/generate-stream` Endpoint ✅
**File:** `mobile/flutter/lib/data/repositories/workout_repository.dart:347-399`

**Status:** COMPLETED
```dart
Stream<WorkoutGenerationProgress> generateWorkoutStreaming({
  required String userId,
  String? fitnessLevel,
  List<String>? goals,
  List<String>? equipment,
  int durationMinutes = 45,
  int? durationMinutesMin,    // ✅ ADDED
  int? durationMinutesMax,    // ✅ ADDED
  List<String>? focusAreas,
  String? scheduledDate,
}) async* {
  // ...
  final response = await streamingDio.post(
    '${ApiConstants.workouts}/generate-stream',
    data: {
      'user_id': userId,
      'duration_minutes': durationMinutes,
      if (durationMinutesMin != null) 'duration_minutes_min': durationMinutesMin,  // ✅ ADDED
      if (durationMinutesMax != null) 'duration_minutes_max': durationMinutesMax,  // ✅ ADDED
      // ...
    },
  );
}
```

### 3. Update Backend API `/workouts/generate-stream` Endpoint ✅
**File:** `backend/api/v1/workouts/generation.py:686-831`

**Status:** COMPLETED
```python
# Line 807-812: Updated to pass duration_minutes_min and duration_minutes_max
async for chunk in gemini_service.generate_workout_plan_streaming(
    fitness_level=fitness_level or "intermediate",
    goals=goals if isinstance(goals, list) else [],
    equipment=equipment if isinstance(equipment, list) else [],
    duration_minutes=body.duration_minutes or 45,
    duration_minutes_min=body.duration_minutes_min,  # ✅ ADDED
    duration_minutes_max=body.duration_minutes_max,  # ✅ ADDED
    focus_areas=body.focus_areas,
    intensity_preference=intensity_preference,
    # ...
):
```

**Note:** `GenerateWorkoutRequest` model already had `duration_minutes_min` and `duration_minutes_max` fields in `backend/models/schemas.py` (lines 180-181)!

### 4. Update workout_generation_screen.dart to Calculate Duration Ranges ✅
**File:** `mobile/flutter/lib/screens/onboarding/workout_generation_screen.dart:90-130`

**Status:** COMPLETED
```dart
// Calculate duration range based on selected duration
int? durationMin;
int? durationMax;

if (workoutDuration == 30) {
  // <30 min range
  durationMin = null;
  durationMax = 30;
} else if (workoutDuration == 45) {
  // 30-45 min range
  durationMin = 30;
  durationMax = 45;
} else if (workoutDuration == 60) {
  // 45-60 min range
  durationMin = 45;
  durationMax = 60;
} else if (workoutDuration == 75) {
  // 60-75 min range
  durationMin = 60;
  durationMax = 75;
} else if (workoutDuration == 90) {
  // 75-90 min range
  durationMin = 75;
  durationMax = 90;
}

final stream = repository.generateWorkoutStreaming(
  userId: userId,
  durationMinutes: workoutDuration,
  durationMinutesMin: durationMin,    // ✅ PASSED
  durationMinutesMax: durationMax,    // ✅ PASSED
);
```

### 5. Ask Gemini to Calculate and Return Actual Workout Duration ✅
**File:** `backend/services/gemini_service.py` (Lines 2407, 2437-2464, 2894, 2914-2916)

**Status:** COMPLETED

**Prompt Updates:**
- Added `"estimated_duration_minutes": null` to JSON schema
- Added detailed calculation instructions for Gemini:
  ```
  ⏱️ ESTIMATED DURATION CALCULATION (CRITICAL):
  After generating the workout, you MUST calculate the actual estimated duration and set "estimated_duration_minutes".
  Calculate it as: SUM of (each exercise's sets × (reps × 3 seconds + rest_seconds)) / 60
  Include time for transitions between exercises (add ~30 seconds per exercise).
  Round to nearest integer.
  ```

**Duration Constraint Instructions:**
```
🚨 DURATION CONSTRAINT (MANDATORY):
- If duration_minutes_max is provided, the calculated estimated_duration_minutes MUST be ≤ duration_minutes_max
- If duration_minutes_min is provided, aim for estimated_duration_minutes to be ≥ duration_minutes_min
- If range is 30-45 min, aim for 35-42 min (comfortably within range)
- Adjust number of exercises or sets to fit within the time constraint
- NEVER exceed the maximum duration - users have limited time!
```

**Backend Validation Added:**
File: `backend/api/v1/workouts/generation.py` (Lines 861-870)
```python
# DURATION VALIDATION: Check if estimated duration is within range
if estimated_duration and body.duration_minutes_max:
    if estimated_duration > body.duration_minutes_max:
        logger.warning(f"⚠️ [Streaming Duration] Estimated duration {estimated_duration} min exceeds max {body.duration_minutes_max} min")
    else:
        logger.info(f"✅ [Streaming Duration] Estimated {estimated_duration} min is within range")
```

Now Gemini will:
1. Calculate the actual workout duration based on exercises generated
2. Return it as `estimated_duration_minutes` in the response
3. Ensure it fits within the user's time constraint
4. Backend logs validation results for monitoring

### 6. Database Migration ✅
**File:** `backend/migrations/184_add_estimated_duration_minutes.sql`

**Status:** COMPLETED ✅

- Added `estimated_duration_minutes INTEGER` column to workouts table
- Added check constraint (1-480 minutes)
- Added column documentation
- Migration executed successfully

**File:** `mobile/flutter/lib/data/models/workout.dart`

**Status:** COMPLETED ✅

- Added `estimatedDurationMinutes` field to Workout model
- Updated `formattedDurationShort` getter to show "~38m" when estimated duration available
- Updated `formattedDuration` getter to show "~38 min" when estimated duration available
- Flutter model files regenerated with build_runner

### 7. Frontend Update to Display Actual Duration (AUTOMATIC ✅)
The frontend ALREADY displays the estimated duration automatically!

**How it works:**
- The `Workout` model's `formattedDuration` and `formattedDurationShort` getters now prefer `estimatedDurationMinutes`
- Any screen using these getters (like `workout_detail_screen.dart`, `active_workout_screen.dart`) will automatically show "~38 min" instead of "30-45 min"
- No additional UI changes needed!

## Testing Checklist
- [x] Frontend updated to show duration ranges (`<30`, `30-45`, `45-60`, `60-75`, `75-90`)
- [x] Flutter repository updated to accept and pass duration_minutes_min/max
- [x] Backend endpoint updated to pass duration ranges to Gemini service
- [x] Workout generation screen calculates correct ranges based on selection
- [x] Gemini prompt updated to calculate estimated_duration_minutes
- [x] Backend validation logs duration constraint compliance
- [ ] **MANUAL TEST REQUIRED:** User selects "30-45 min" → Gemini generates workout with estimated_duration ≤ 45 minutes
- [ ] **MANUAL TEST REQUIRED:** User selects "<30 min" → Gemini generates workout with estimated_duration ≤ 30 minutes
- [ ] **MANUAL TEST REQUIRED:** User selects "75-90 min" → Gemini generates workout with estimated_duration ≤ 90 minutes
- [ ] **MANUAL TEST REQUIRED:** Backend logs show estimated_duration_minutes in response
- [ ] **MANUAL TEST REQUIRED:** Workout generation logs confirm duration constraint validation
- [ ] Frontend displays actual estimated duration (e.g., "42 min") from backend (future enhancement - requires UI update)

## Implementation Summary

### ✅ COMPLETED (All Core Features)
1. **Frontend UI Update:** Duration selector now shows ranges instead of exact numbers (`<30`, `30-45`, `45-60`, `60-75`, `75-90`)
2. **Flutter Repository:** `generateWorkoutStreaming` method now accepts `durationMinutesMin` and `durationMinutesMax`
3. **Backend Endpoint:** `/generate-stream` endpoint now passes duration ranges to Gemini service
4. **Workout Generation Screen:** Calculates correct min/max based on selected duration and passes to API
5. **Gemini Service:** Already had full support for duration constraints (was already implemented!)
6. **Gemini Duration Calculation:** Prompt now instructs Gemini to calculate `estimated_duration_minutes` based on exercises
7. **Backend Validation:** Logs validation of duration constraints and warns if exceeded
8. **Database Migration:** Added `estimated_duration_minutes` column to workouts table with constraints
9. **Flutter Model Update:** Added `estimatedDurationMinutes` field and updated duration getters
10. **Auto-Truncation Utility:** Created `truncate_exercises_to_duration()` function (available but disabled by default)

### 🎯 Key Improvements (ALL COMPLETE ✅)
- **User selects range** → Frontend shows "30-45 min" instead of "45 min" ✅
- **Gemini receives constraint** → "Generate workout within 30-45 minutes, max 45 min" ✅
- **Gemini calculates actual time** → Returns `estimated_duration_minutes: 38` ✅
- **Backend validates** → Logs ✅ if within range, ⚠️ if exceeded ✅
- **Backend saves to DB** → Stores all three duration fields (min, max, estimated) ✅
- **Frontend displays** → Automatically shows "~38 min" via updated getters ✅

### 📋 FUTURE ENHANCEMENTS (Low Priority)
1. ~~Update frontend to display actual `estimated_duration_minutes` instead of selected range~~ ✅ DONE (automatic via getters)
2. Enable auto-truncation in backend validation (currently just logs warning, truncation function exists but is commented out)
3. Add frontend UI to show actual vs target duration comparison in workout details screen
4. Add A/B test to measure if Gemini accurately respects duration constraints

## Notes
- The duration the user selects should be treated as a **maximum constraint**, not an exact target
- Gemini should aim to generate workouts that fit comfortably within the range (e.g., for "30-45 min", aim for 35-40 min)
- Include rest periods in the total time calculation
- Warm-up and cool-down should also count toward total duration
