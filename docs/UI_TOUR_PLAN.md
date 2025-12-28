# Plan: Context-Aware UI Tours for First-Time Users

## Overview
Add guided UI tutorials that show first-time users how to use each major screen. Tours trigger automatically when a user visits a screen for the first time, with skip option. AI Coach can also help navigate and trigger tutorials on demand.

---

## Tour System Architecture

### Tour Trigger Logic (with Skip Option)
```
User visits screen for first time
           ↓
Show "Quick Tour?" prompt:
  ┌─────────────────────────────────┐
  │  Welcome to [Screen Name]!      │
  │                                 │
  │  Want a quick tour of this      │
  │  screen's features?             │
  │                                 │
  │  [Take Tour]  [Skip for Now]    │
  └─────────────────────────────────┘
           ↓
Take Tour → Show guided tour → Mark seen
Skip → Mark seen → Normal screen
```

### AI Coach Navigation Integration
```
User asks AI Coach: "How do I log a meal?"
           ↓
AI Coach responds with:
1. Text explanation of how to do it
2. "Would you like me to show you?" button
           ↓
User taps button → Navigate to Nutrition screen + trigger tour
```

### Tours to Implement

| Screen | Trigger | Key Elements to Highlight |
|--------|---------|---------------------------|
| **Home** | After paywall (first visit) | Workout card, Quick actions, AI Coach, Weekly progress, Bottom nav |
| **Nutrition** | First visit to nutrition tab | Meal logging options (photo/text/barcode), AI health score, Daily summary |
| **Active Workout** | First time starting a workout | Exercise video, Set logging, Rest timer, Form cues, Phase indicator |
| **Library** | First visit to library tab | Search, Filters, Exercise cards, Categories |

---

## Step 1: Add Package
**File:** `mobile/flutter/pubspec.yaml`
```yaml
dependencies:
  tutorial_coach_mark: ^1.2.11
```

---

## Step 2: Create Tour State Provider
**File:** `mobile/flutter/lib/providers/ui_tour_provider.dart` (NEW)

```dart
// Keys for SharedPreferences
const kSeenHomeTour = 'seen_home_tour';
const kSeenNutritionTour = 'seen_nutrition_tour';
const kSeenWorkoutTour = 'seen_workout_tour';
const kSeenLibraryTour = 'seen_library_tour';

// Provider to check/set tour status
final uiTourProvider = StateNotifierProvider<UiTourNotifier, UiTourState>
```

---

## Step 3: Create Reusable Tour Components
**File:** `mobile/flutter/lib/widgets/ui_tour/tour_overlay.dart` (NEW)

- Custom tooltip design (glass morphism, matches app theme)
- "Next" and "Skip" buttons
- Step indicator (1 of 5)
- Animations using flutter_animate

---

## Step 4: Home Screen Tour

**File:** `mobile/flutter/lib/screens/home/home_screen.dart`

### Tour Steps (6 steps):

| Step | Target | Title | Description |
|------|--------|-------|-------------|
| 1 | Next Workout Card | "Your Workouts" | "Your AI-generated workout plan is ready! Tap to see today's exercises and start training." |
| 2 | Quick Actions Row | "Quick Actions" | "One-tap access to log meals, track water intake, and record body measurements." |
| 3 | Weekly Progress | "Weekly Progress" | "See your activity streak, completed workouts, and weekly goals at a glance." |
| 4 | Chat Bubble | "AI Fitness Coach" | "Have questions about workouts, nutrition, or injuries? Chat with your personal AI coach anytime!" |
| 5 | Bottom Navigation | "Explore the App" | "Navigate to Nutrition tracking, Stats & analytics, Social challenges, and your Profile." |
| 6 | Features Banner (if visible) | "Premium Features" | "Unlock AI chat, meal photo analysis, personalized plans, and detailed analytics!" |

### Implementation:
```dart
// Add GlobalKeys
final _workoutCardKey = GlobalKey();
final _quickActionsKey = GlobalKey();
final _weeklyProgressKey = GlobalKey();
final _chatBubbleKey = GlobalKey();
final _bottomNavKey = GlobalKey();

// Trigger in initState after build
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkAndShowHomeTour();
  });
}
```

---

## Step 5: Nutrition Screen Tour

**File:** `mobile/flutter/lib/screens/nutrition/nutrition_screen.dart`

### Tour Steps (4 steps):

| Step | Target | Title | Description |
|------|--------|-------|-------------|
| 1 | Log Meal Button | "Log Your Meals" | "Track what you eat by taking a photo, typing a description, or scanning a barcode." |
| 2 | AI Health Score | "AI Health Score" | "Get an instant health rating (1-10) for each meal with personalized recommendations." |
| 3 | Daily Summary | "Daily Nutrition" | "See your calories, protein, carbs, and fats at a glance." |
| 4 | Meal History | "Meal History" | "Review all your logged meals and their nutritional breakdown." |

---

## Step 6: Active Workout Tour

**File:** `mobile/flutter/lib/screens/workout/active_workout_screen.dart`

### Tour Steps (5 steps):

| Step | Target | Title | Description |
|------|--------|-------|-------------|
| 1 | Exercise Video | "Exercise Demo" | "Watch the video to learn proper form. Tap to pause or replay." |
| 2 | Set Logging | "Log Your Sets" | "Tap the circles to mark sets complete. Enter weight and reps for each set." |
| 3 | Rest Timer | "Rest Timer" | "A timer appears between sets. Rest or skip to continue." |
| 4 | Form Cues | "Form Tips" | "Swipe to see important form cues and avoid injuries." |
| 5 | Phase Indicator | "Workout Phases" | "Workouts have 3 phases: Warmup, Active exercises, and Stretch/Cooldown." |

---

## Step 7: Library Screen Tour

**File:** `mobile/flutter/lib/screens/library/library_screen.dart`

### Tour Steps (3 steps):

| Step | Target | Title | Description |
|------|--------|-------|-------------|
| 1 | Search Bar | "Search Exercises" | "Find any exercise from our library of 1,700+ exercises." |
| 2 | Filter Button | "Filter & Sort" | "Filter by muscle group, equipment, difficulty, and more." |
| 3 | Exercise Card | "Exercise Details" | "Tap any exercise to see video demos, instructions, and form tips." |

---

## Tour Styling (Match App Theme)

```dart
// Overlay
backgroundColor: Colors.black.withOpacity(0.85)

// Highlight
highlightColor: AppColors.cyan
highlightShape: ShapeLightFocus.RRect (rounded rectangle)

// Tooltip Card
decoration: BoxDecoration(
  gradient: LinearGradient(colors: [purple.withOpacity(0.3), cyan.withOpacity(0.3)]),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: cyan.withOpacity(0.5)),
)

// Text
titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
descriptionStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary)

// Buttons
nextButton: Cyan filled button with "Next" or "Got it!"
skipButton: Text button "Skip Tour"
```

---

## AI Coach Navigation & Tutorial Triggers

**File:** `backend/services/langgraph_coach_service.py` (MODIFY)

### Navigation Commands AI Coach Should Understand:

| User Query | AI Response | Action Button |
|------------|-------------|---------------|
| "How do I log a meal?" | Explains meal logging | "Show me" → Navigate to /nutrition + tour |
| "Where can I see my workouts?" | Explains workout section | "Take me there" → Navigate to /home |
| "How do I track water?" | Explains hydration | "Show me" → Navigate to /hydration |
| "Show me around the app" | Offers full tour | "Start Tour" → Trigger home tour |
| "I'm lost / Help me navigate" | Lists main sections | Quick action buttons for each section |
| "How do I start a workout?" | Explains workout flow | "Show me" → Navigate to workout + tour |

### Implementation:

1. **Add navigation intent detection** in AI Coach prompt:
```python
# In system prompt, add:
"When users ask HOW to do something in the app, provide:
1. A brief text explanation
2. Offer to navigate them there with a special action tag:
   [NAVIGATE:/nutrition?tour=true] or [NAVIGATE:/home]"
```

2. **Parse AI response in Flutter** for navigation tags:
```dart
// In chat message parsing
if (message.contains('[NAVIGATE:')) {
  final route = extractRoute(message);
  final showTour = route.contains('tour=true');
  // Show "Take me there" button that navigates + triggers tour
}
```

3. **Add quick action buttons** in chat for common navigation:
```dart
// After AI explains something, show:
Row(
  children: [
    ActionChip(label: Text("Show me"), onPressed: () => navigateWithTour()),
    ActionChip(label: Text("Got it"), onPressed: () => dismissChat()),
  ],
)
```

---

## Re-trigger Tours (Settings + AI Coach)

### Settings Screen Option:
Add "App Tours" section in Settings:
- "Replay Home Tour"
- "Replay Nutrition Tour"
- "Replay Workout Tour"
- "Reset All Tours" (shows all tours again)

### AI Coach Trigger:
User can say: "Show me around" or "Give me a tour" anytime to trigger tours.

---

## Files to Create/Modify Summary

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | MODIFY | Add tutorial_coach_mark: ^1.2.11 |
| `lib/providers/ui_tour_provider.dart` | CREATE | Tour state management with SharedPreferences |
| `lib/widgets/ui_tour/tour_overlay.dart` | CREATE | Custom tooltip widget matching app theme |
| `lib/widgets/ui_tour/tour_prompt.dart` | CREATE | "Take Tour?" prompt dialog |
| `lib/widgets/ui_tour/tour_step.dart` | CREATE | Tour step data model |
| `lib/screens/home/home_screen.dart` | MODIFY | Add GlobalKeys + home tour logic |
| `lib/screens/nutrition/nutrition_screen.dart` | MODIFY | Add GlobalKeys + nutrition tour logic |
| `lib/screens/workout/active_workout_screen.dart` | MODIFY | Add GlobalKeys + workout tour logic |
| `lib/screens/library/library_screen.dart` | MODIFY | Add GlobalKeys + library tour logic |
| `lib/widgets/main_shell.dart` | MODIFY | Add GlobalKey for bottom navigation |
| `lib/screens/chat/chat_screen.dart` | MODIFY | Parse navigation tags, add action buttons |
| `lib/screens/settings/settings_screen.dart` | MODIFY | Add "App Tours" section |
| `backend/services/langgraph_coach_service.py` | MODIFY | Add navigation intent handling in prompts |

---

## Success Criteria

- [ ] "Take Tour?" prompt shows on first visit (with skip option)
- [ ] Home tour shows after onboarding (if user accepts)
- [ ] Nutrition tour shows on first visit to nutrition tab
- [ ] Workout tour shows when starting first workout
- [ ] Users can skip any tour with "Skip for Now"
- [ ] AI Coach can navigate users to screens on request
- [ ] AI Coach can trigger tours when explaining features
- [ ] "Show me" buttons appear in chat after explanations
- [ ] Tour progress persists across app restarts
- [ ] Tours match app's visual theme (dark mode, glass morphism)
- [ ] Option to replay tours from Settings
- [ ] User can say "give me a tour" to AI Coach anytime
