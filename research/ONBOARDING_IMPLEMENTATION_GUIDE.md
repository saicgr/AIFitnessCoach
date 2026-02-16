# FitWiz Onboarding Redesign - Implementation Guide

## ✅ Completed Components

### 1. Data Layer (100% Complete)
- ✅ **PreAuthQuizData Model** - Added `nutritionEnabled` and `limitations` fields
- ✅ **SharedPreferences Integration** - New keys for all fields
- ✅ **Setter Methods** - `setNutritionEnabled()` and `setLimitations()` in PreAuthQuizNotifier
- ✅ **All 23 Setter Methods Updated** - Include new fields in state constructors

### 2. Payload Building (100% Complete)
- ✅ **GeminiProfilePayloadBuilder** - [gemini_profile_payload.dart](mobile/flutter/lib/data/models/gemini_profile_payload.dart:1)
  - Conditional field inclusion (Phase 1/2/3)
  - Validation method
  - Debugging utility with readable string output
  - Empty array handling for `dietaryRestrictions`

### 3. Analytics (100% Complete)
- ✅ **AnalyticsService** - [analytics_service.dart](mobile/flutter/lib/core/services/analytics_service.dart:1)
  - Screen view tracking
  - Onboarding completion events
  - Nutrition opt-in tracking
  - Workout generation events
  - User property setting
  - Drop-off tracking
  - Duration tracking

### 4. New Widgets (100% Complete)
All widgets follow app design system with:
- ✅ Proper dark/light mode support
- ✅ AppColors.orange accent color
- ✅ Glassmorphic cards
- ✅ Smooth animations with flutter_animate
- ✅ Haptic feedback on interactions

**Completed Widgets:**
1. ✅ **QuizPersonalizationGate** - [quiz_personalization_gate.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_personalization_gate.dart:1)
   - Benefits list with icons
   - "Yes, Personalize" and "Skip for Now" CTAs

2. ✅ **QuizNutritionGate** - [quiz_nutrition_gate.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_nutrition_gate.dart:1)
   - Conditional "Recommended ⭐" badge based on goals
   - Benefits list
   - "Yes, Set Nutrition" and "Not Now" CTAs

3. ✅ **QuizTrainingStyle** - [quiz_training_style.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_training_style.dart:1)
   - Training split selection (AI Decide, PPL, Full Body, etc.)
   - Workout type chips (Strength, Cardio, Mixed)
   - Compatibility warnings for split vs. days/week mismatch

4. ✅ **QuizProgressionConstraints** - [quiz_progression_constraints.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_progression_constraints.dart:1)
   - Progression pace cards (Slow, Balanced, Fast)
   - Recommended pace based on fitness level
   - Physical limitations chips (None, Knees, Shoulders, Lower Back, Other)
   - Smart "None" handling (deselects others)

### 5. Backend Integration (100% Complete)
- ✅ **CoachSelectionScreen Updated** - Now uses `GeminiProfilePayloadBuilder`
  - Logs payload in debug mode
  - Validates required fields
  - Sends complete data to backend
  - Includes new `nutritionEnabled` and `limitations` fields

---

## 🚧 Remaining Work

### Priority 1: Navigation Logic (CRITICAL)

**File:** [pre_auth_quiz_screen.dart](mobile/flutter/lib/screens/onboarding/pre_auth_quiz_screen.dart:1400)

#### Task 1.1: Update _buildCurrentQuestion() Method

**Current:** Lines 1907-1996 handle 12 questions
**New:** Need to handle 12 screens with new structure

```dart
Widget _buildCurrentQuestion() {
  // Add state variables for new screens
  bool _skipPersonalization = false; // Track if user skipped Phase 2

  switch (_currentQuestion) {
    case 0: // Goals - NO CHANGES
      return QuizMultiSelect(/* existing implementation */);

    case 1: // Fitness Level + Training Experience (combined)
      return QuizFitnessLevel(
        selectedLevel: _selectedLevel,
        selectedExperience: _trainingExperience, // Make optional
        onLevelChanged: (level) => setState(() => _selectedLevel = level),
        onExperienceChanged: (exp) => setState(() => _trainingExperience = exp),
      );

    case 2: // Schedule (days/week + duration)
      return _buildScheduleScreen(); // Combine days selector + duration

    case 3: // Workout Days [CONDITIONAL]
      // Only show if feature flag enabled
      const featureFlagWorkoutDays = false;
      if (!featureFlagWorkoutDays) {
        // Skip this screen - handled in _nextQuestion()
      }
      return QuizDaysSelector(/* existing */);

    case 4: // Equipment (2-step: environment + equipment)
      return QuizEquipment(
        selectedEnvironment: _workoutEnvironment,
        onEnvironmentChanged: (env) => setState(() => _workoutEnvironment = env),
        selectedEquipment: _selectedEquipment,
        onEquipmentToggled: _toggleEquipment,
        // ... other params
      );

    case 5: // Training Focus + Generate
      return QuizPrimaryGoal(
        selectedGoal: _primaryGoal,
        onGoalChanged: (goal) => setState(() => _primaryGoal = goal),
        onGenerate: _generateAndShowPreview, // NEW METHOD
      );

    case 6: // Personalization Gate
      return QuizPersonalizationGate(
        onPersonalize: () => setState(() => _skipPersonalization = false),
        onSkip: () {
          setState(() => _skipPersonalization = true);
          _jumpToScreen(10); // Jump to nutrition gate
        },
      );

    case 7: // Muscle Focus Points (existing widget)
      return QuizMuscleFocus(/* existing */);

    case 8: // Training Style
      return QuizTrainingStyle(
        selectedSplit: _trainingSplit,
        selectedWorkoutType: _workoutTypePreference,
        daysPerWeek: _daysPerWeek ?? 4,
        onSplitChanged: (split) => setState(() => _trainingSplit = split),
        onWorkoutTypeChanged: (type) => setState(() => _workoutTypePreference = type),
      );

    case 9: // Progression + Constraints
      return QuizProgressionConstraints(
        selectedPace: _progressionPace,
        selectedLimitations: _selectedLimitations,
        fitnessLevel: _selectedLevel ?? 'intermediate',
        onPaceChanged: (pace) => setState(() => _progressionPace = pace),
        onLimitationsChanged: (limitations) => setState(() => _selectedLimitations = limitations),
      );

    case 10: // Nutrition Opt-In Gate
      return QuizNutritionGate(
        goals: _selectedGoals.toList(),
        onSetNutrition: () async {
          await ref.read(preAuthQuizProvider.notifier).setNutritionEnabled(true);
          setState(() => _nutritionEnabled = true);
        },
        onSkip: () async {
          await ref.read(preAuthQuizProvider.notifier).setNutritionEnabled(false);
          _finishOnboarding();
        },
      );

    case 11: // Nutrition Details (merged QuizNutritionGoals + QuizFasting)
      return _buildNutritionDetailsScreen(); // NEW METHOD

    default:
      return const SizedBox.shrink();
  }
}
```

#### Task 1.2: Update _nextQuestion() Method

```dart
Future<void> _nextQuestion() async {
  HapticFeedback.mediumImpact();

  // Save current question data
  await _saveCurrentQuestionData();

  // Log analytics
  AnalyticsService.logScreenView('onboarding_screen_$_currentQuestion');

  // Special handling for Screen 5 (Training Focus + Generate)
  if (_currentQuestion == 5) {
    await _generateAndShowPreview();
    return; // Preview screen handles navigation to Screen 6 or 10
  }

  // Special handling for Screen 2 -> 3/4 (conditional workout days screen)
  if (_currentQuestion == 2) {
    const featureFlagWorkoutDays = false;
    if (!featureFlagWorkoutDays) {
      setState(() => _currentQuestion = 4); // Skip Screen 3
      return;
    }
  }

  // Check if last question
  if (_currentQuestion == _totalQuestions - 1) {
    _finishOnboarding();
    return;
  }

  setState(() => _currentQuestion++);
  _questionController.forward(from: 0);
}
```

#### Task 1.3: Add _generateAndShowPreview() Method

```dart
Future<void> _generateAndShowPreview() async {
  try {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      ),
    );

    // Build payload for preview generation
    final quizData = ref.read(preAuthQuizProvider);
    final payload = GeminiProfilePayloadBuilder.buildPayload(quizData);

    // Generate sample workout (call API or mock)
    // TODO: Call workout generation API with preview flag
    // final workout = await _generatePreviewWorkout(payload);

    if (mounted) Navigator.of(context).pop(); // Close loading

    // Navigate to plan preview screen
    final shouldContinue = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanPreviewScreen(
          quizData: quizData,
          // workout: workout,
          onContinue: () => Navigator.of(context).pop(true),
          onSkipToNutrition: () => Navigator.of(context).pop(false),
        ),
      ),
    );

    if (shouldContinue == true) {
      // User chose "Continue" -> Go to Screen 6 (Personalization Gate)
      setState(() => _currentQuestion = 6);
    } else {
      // User chose "Start Training Now" -> Skip to Screen 10 (Nutrition Gate)
      setState(() => _currentQuestion = 10);
    }
  } catch (e) {
    if (mounted) Navigator.of(context).pop(); // Close loading
    // Show error and allow retry
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to generate preview: $e')),
    );
  }
}
```

#### Task 1.4: Update _totalQuestions Getter

```dart
int get _totalQuestions {
  int total = 12; // Base: 12 screens

  // Conditionally exclude workout days screen
  const featureFlagWorkoutDays = false;
  if (!featureFlagWorkoutDays) {
    total -= 1; // 11 screens total
  }

  return total;
}
```

#### Task 1.5: Update _finishOnboarding() Method

```dart
Future<void> _finishOnboarding() async {
  // Log analytics
  AnalyticsService.logOnboardingCompleted(
    totalScreens: _totalQuestions,
    skippedScreens: _skipPersonalization ? 4 : 0, // Screens 6-9
    nutritionOptedIn: _nutritionEnabled ?? false,
    personalizationCompleted: !_skipPersonalization,
  );

  // Mark nutrition opt-in status
  await ref.read(preAuthQuizProvider.notifier)
      .setNutritionEnabled(_nutritionEnabled ?? false);

  // Navigate to coach selection (skip weight projection)
  if (mounted) {
    context.go('/coach-selection');
  }
}
```

---

### Priority 2: Widget Refactoring (IMPORTANT)

#### Task 2.1: Refactor QuizEquipment Widget

**File:** [quiz_equipment.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_equipment.dart:24)

**Changes needed:**
1. Add Part A: Environment selection (4 large cards in 2x2 grid)
2. Pre-populate equipment based on environment
3. Move dumbbell/kettlebell counts to collapsed "Advanced" section
4. Remove "full_gym" as equipment item (use environment instead)

**Environment Cards:**
```dart
// Add to top of widget before equipment list
Row(
  children: [
    _buildEnvironmentCard('commercial_gym', '🏢', 'Gym', isDark),
    SizedBox(width: 12),
    _buildEnvironmentCard('home', '🏡', 'Home', isDark),
  ],
),
SizedBox(height: 12),
Row(
  children: [
    _buildEnvironmentCard('home_gym', '🏠', 'Home Gym', isDark),
    SizedBox(width: 12),
    _buildEnvironmentCard('hotel', '🧳', 'Hotel', isDark),
  ],
),
```

#### Task 2.2: Refactor QuizFitnessLevel Widget

**File:** [quiz_fitness_level.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_fitness_level.dart:1)

**Changes needed:**
1. Make training experience OPTIONAL (collapsed "Advanced" section)
2. Remove activity level (not needed in Phase 1)
3. Set default: beginner + skip experience → "never"

#### Task 2.3: Merge QuizNutritionGoals + QuizFasting

**New File:** Create `quiz_nutrition_details.dart` combining both widgets

**Structure:**
```dart
Column(
  children: [
    // Always visible
    Text('Nutrition Goals'),
    _buildNutritionGoalsMultiSelect(),

    Text('Dietary Restrictions'),
    _buildDietaryRestrictionsMultiSelect(),

    Text('Meals Per Day'),
    _buildMealsPerDaySlider(),

    // Collapsed Advanced section
    ExpansionTile(
      title: Text('Advanced: Fasting'),
      children: [
        _buildFastingToggle(),
        if (_interestedInFasting) ...[
          _buildFastingProtocolDropdown(),
          _buildWakeTimeField(),
          _buildSleepTimeField(),
        ],
      ],
    ),
  ],
)
```

---

### Priority 3: Legacy File Cleanup (LOW PRIORITY)

#### Task 3.1: Delete Post-Auth Onboarding Files

```bash
rm -rf mobile/flutter/lib/screens/onboarding/onboarding_screen.dart
rm -rf mobile/flutter/lib/screens/onboarding/steps/
rm mobile/flutter/lib/screens/onboarding/onboarding_data.dart
```

#### Task 3.2: Update app_router.dart

Remove route:
```dart
// DELETE THIS ROUTE
GoRoute(
  path: '/onboarding',
  pageBuilder: (context, state) => CustomTransitionPage(
    child: const OnboardingScreen(), // OLD 6-step form
  ),
),
```

Update redirect logic:
```dart
String? getNextOnboardingStep(User user) {
  if (!user.isCoachSelected) {
    return '/coach-selection';
  }
  if (!user.isPaywallComplete) {
    return '/paywall-features';
  }
  return null; // Complete → home
}
```

---

## 🔄 Data Flow Verification

### From UI → SharedPreferences → Supabase → Gemini

1. **User fills Screen 9 (Progression + Constraints)**
   ```
   User selects "Slow" pace + "Knees" limitation
   ↓
   QuizProgressionConstraints calls:
   - onPaceChanged('slow')
   - onLimitationsChanged(['knees'])
   ↓
   PreAuthQuizScreen updates state:
   - setState(() => _progressionPace = 'slow')
   - setState(() => _selectedLimitations = ['knees'])
   ↓
   _saveCurrentQuestionData() calls:
   - ref.read(preAuthQuizProvider.notifier).setProgressionPace('slow')
   - ref.read(preAuthQuizProvider.notifier).setLimitations(['knees'])
   ↓
   PreAuthQuizNotifier updates SharedPreferences:
   - prefs.setString('preAuth_progressionPace', 'slow')
   - prefs.setStringList('preAuth_limitations', ['knees'])
   ↓
   PreAuthQuizNotifier updates state with new PreAuthQuizData
   ```

2. **User finishes onboarding → Coach Selection**
   ```
   CoachSelectionScreen._submitUserPreferencesAndFlags()
   ↓
   Reads: ref.read(preAuthQuizProvider)
   ↓
   Calls: GeminiProfilePayloadBuilder.buildPayload(quizData)
   ↓
   Returns Map with conditional fields:
   {
     "goals": [...],
     "fitness_level": "intermediate",
     "workouts_per_week": 4,
     "progression_pace": "slow",      // FROM SCREEN 9
     "limitations": ["knees"],         // FROM SCREEN 9
     "nutrition_enabled": true,        // FROM SCREEN 10
     ...
   }
   ↓
   Submits to backend:
   POST /users/{userId}/preferences
   ↓
   Backend stores in Supabase:
   - users table: primary_goal, fitness_level, etc.
   - preferences JSON: progression_pace, limitations, etc.
   ↓
   Backend uses for workout generation:
   - Sends payload to Gemini API
   - Gemini generates workouts with:
     * Slower progression (pace = slow)
     * Avoids knee-intensive exercises (limitations = knees)
   ```

---

## ⚙️ Feature Flags

Add to `lib/core/config/feature_flags.dart`:

```dart
class FeatureFlags {
  // Onboarding
  static const bool onboardingCollectWorkoutDays = false; // Skip Screen 3
  static const bool onboardingShowWeightProjection = false;
  static const bool onboardingPersonalizationPhase = true; // Show Screens 6-9
  static const bool onboardingNutritionPhase = true; // Show Screens 10-11

  // Preview
  static const bool onboardingGeneratePreview = true; // Generate sample workout at Screen 5
}
```

---

## 🧪 Testing Checklist

### Manual Testing
- [ ] Complete full flow: Screen 0 → Coach Selection
- [ ] Test skip logic:
  - [ ] Skip personalization (Screen 6 → Screen 10)
  - [ ] Skip nutrition (Screen 10 → Coach Selection)
- [ ] Test conditional screens:
  - [ ] Workout days screen shows/hides based on feature flag
- [ ] Test data persistence:
  - [ ] Kill app mid-onboarding, reopen, verify data restored
- [ ] Test backend submission:
  - [ ] Check Supabase users table has all fields
  - [ ] Check preferences JSON has correct structure
- [ ] Test Gemini payload:
  - [ ] Check debug logs show correct payload
  - [ ] Verify validation passes
  - [ ] Verify workout generation uses correct data

### Validation Queries
```sql
-- Check user preferences after onboarding
SELECT
  id,
  primary_goal,
  fitness_level,
  preferences::json->'progression_pace' as progression_pace,
  preferences::json->'limitations' as limitations,
  preferences::json->'nutrition_enabled' as nutrition_enabled
FROM users
WHERE id = '<user_id>';
```

---

## 📊 Success Metrics

Track these with `AnalyticsService`:

1. **Time to First Workout:** ≤ 90 seconds for Phase 1 (Screens 0-5)
2. **Completion Rate:** ≥ 85% complete Phase 1
3. **Personalization Opt-In:** ≥ 40% complete Phase 2
4. **Nutrition Opt-In:** ≥ 60% with weight loss goals
5. **Drop-Off Points:** < 10% per screen in Phase 1

---

## 🎯 Quick Start Commands

### Run analysis
```bash
flutter analyze lib/screens/onboarding/
```

### Format code
```bash
flutter format lib/screens/onboarding/ lib/data/models/gemini_profile_payload.dart lib/core/services/analytics_service.dart
```

### Test payload builder
```dart
// Add to main() for testing
final testData = PreAuthQuizData(
  goals: ['build_muscle'],
  fitnessLevel: 'intermediate',
  daysPerWeek: 4,
  workoutDuration: 45,
  workoutEnvironment: 'home_gym',
  equipment: ['dumbbells', 'barbell'],
  primaryGoal: 'muscle_hypertrophy',
  progressionPace: 'slow',
  limitations: ['knees'],
  nutritionEnabled: true,
);

final payload = GeminiProfilePayloadBuilder.buildPayload(testData);
print(GeminiProfilePayloadBuilder.toReadableString(payload));
```

---

## 🔗 Key Files Reference

### Completed
- ✅ [gemini_profile_payload.dart](mobile/flutter/lib/data/models/gemini_profile_payload.dart:1)
- ✅ [analytics_service.dart](mobile/flutter/lib/core/services/analytics_service.dart:1)
- ✅ [quiz_personalization_gate.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_personalization_gate.dart:1)
- ✅ [quiz_nutrition_gate.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_nutrition_gate.dart:1)
- ✅ [quiz_training_style.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_training_style.dart:1)
- ✅ [quiz_progression_constraints.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_progression_constraints.dart:1)
- ✅ [coach_selection_screen.dart](mobile/flutter/lib/screens/onboarding/coach_selection_screen.dart:153) (updated)

### To Modify
- 🚧 [pre_auth_quiz_screen.dart](mobile/flutter/lib/screens/onboarding/pre_auth_quiz_screen.dart:1400) - Navigation logic
- 🚧 [quiz_equipment.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_equipment.dart:24) - Add environment selection
- 🚧 [quiz_fitness_level.dart](mobile/flutter/lib/screens/onboarding/widgets/quiz_fitness_level.dart:1) - Make experience optional
- 🚧 Create `quiz_nutrition_details.dart` - Merge nutrition + fasting
- 🚧 [app_router.dart](mobile/flutter/lib/navigation/app_router.dart:150) - Remove old routes

---

## 📝 Notes

- All new widgets use **AppColors.orange** for accent color
- All widgets support **dark/light mode** with proper contrast
- All interactive elements have **haptic feedback**
- All screens log to **AnalyticsService** for tracking
- Payload validation happens **before** API submission
- Empty array `[]` used for `dietaryRestrictions` when none selected (no "none" sentinel)
