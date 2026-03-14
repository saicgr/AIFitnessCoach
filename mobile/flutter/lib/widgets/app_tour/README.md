# App Tour System

Contextual, one-time tooltip overlay tours that teach new users about each screen the first time they visit it. One reusable engine powers all 5 tours.

---

## How it works

When a screen loads for the first time it calls `checkAndShow(tourId, steps)`. This reads a `SharedPreferences` flag (`has_seen_<tourId>`). If the flag is absent the tour starts; once dismissed the flag is written and the tour never shows again.

The overlay (`AppTourOverlay`) lives at the top of the `MainShell` Stack so it sits above every screen and the nav bar. It draws a dark backdrop with a rounded-rect cutout spotlighting the target widget, and a glassmorphic tooltip card below or above it.

```
User opens screen
      │
      ▼
checkAndShow('tour_id', steps)
      │
  flag set? ──yes──▶ do nothing
      │
      no
      │
      ▼
AppTourController.show() → state.isVisible = true
      │
      ▼
AppTourOverlay renders spotlight + tooltip card
      │
  Next / tap background ──▶ next step (or dismiss on last)
  Skip / Got it          ──▶ dismiss immediately
      │
      ▼
dismiss() → state.isVisible = false + writes SharedPrefs flag
```

---

## Architecture

```
lib/widgets/app_tour/
├── app_tour_controller.dart   ← Riverpod StateNotifier, AppTourKeys, AppTourStep model
├── app_tour_overlay.dart      ← Full-screen ConsumerStatefulWidget overlay
├── app_tour_spotlight.dart    ← CustomPainter: dark bg + Path.combine cutout + accent ring
└── app_tour_tooltip_card.dart ← Glassmorphic card: title, description, step dots, nav buttons
```

### Key classes

| Class | File | Role |
|-------|------|------|
| `AppTourStep` | controller | Data model: `id`, `targetKey`, `title`, `description`, `position` |
| `AppTourState` | controller | Immutable state: `tourId`, `currentStep`, `isVisible`, `steps` |
| `AppTourController` | controller | StateNotifier: `show`, `next`, `prev`, `dismiss`, `checkAndShow` |
| `appTourControllerProvider` | controller | Global Riverpod provider |
| `AppTourKeys` | controller | Static `GlobalKey` registry for all tour targets |
| `AppTourOverlay` | overlay | Reads controller state, positions spotlight + card |
| `AppTourSpotlightPainter` | spotlight | Draws overlay with hole punched at target rect |
| `AppTourTooltipCard` | tooltip_card | Card UI with animated step transitions |

### `AppTourStep` fields

```dart
AppTourStep({
  required String id,            // unique within the tour
  required GlobalKey targetKey,  // widget to spotlight (from AppTourKeys)
  required String title,
  required String description,
  TooltipPosition position,      // above | below (default) | center
})
```

### `TooltipPosition` logic

- **below** — card appears below the spotlight; falls back to above if not enough space; falls back to center if neither fits
- **above** — card appears above the spotlight; clamps to stay on-screen
- **center** — card appears vertically centered regardless of spotlight position

---

## The 5 Tours

### Tour 1 — App Navigation (`nav_tour`)
**Trigger:** Home screen `initState` → `_triggerNavTour()`
**SharedPrefs key:** `has_seen_nav_tour`

| Step | Target widget | Key | Title |
|------|--------------|-----|-------|
| 1 | Hero workout carousel | `AppTourKeys.heroCarouselKey` | Your AI Workout |
| 2 | Quick Log trends section | `AppTourKeys.quickLogKey` | Quick Log |
| 3 | Workout nav tab | `AppTourKeys.workoutNavKey` | Exercise Library |
| 4 | Floating AI chat bubble | `AppTourKeys.aiChatKey` | Your AI Coach |
| 5 | Nutrition nav tab | `AppTourKeys.nutritionNavKey` | Track Nutrition |
| 6 | Profile nav tab | `AppTourKeys.profileNavKey` | Your Progress |

---

### Tour 2 — Active Workout (`workout_tour`)
**Trigger:** `ActiveWorkoutScreen` `initState` → `_triggerWorkoutTour()`
**SharedPrefs key:** `has_seen_workout_tour`

| Step | Target widget | Key | Title |
|------|--------------|-----|-------|
| 1 | Exercise card area | `AppTourKeys.exerciseCardKey` | Current Exercise |
| 2 | Set tracking table | `AppTourKeys.setLoggingKey` | Log Your Sets |
| 3 | Rest timer | `AppTourKeys.restTimerKey` | Rest Timer |
| 4 | Swap exercise chip | `AppTourKeys.swapExerciseKey` | Can't Do This? |
| 5 | AI coach chip | `AppTourKeys.workoutAiKey` | Mid-Workout Help |

---

### Tour 3 — Nutrition (`nutrition_tour`)
**Trigger:** `NutritionScreen` `initState` → `_triggerNutritionTour()`
**SharedPrefs key:** `has_seen_nutrition_tour`

| Step | Target widget | Key | Title |
|------|--------------|-----|-------|
| 1 | Nutrition goals card | `AppTourKeys.macroGoalsKey` | Your Daily Targets |
| 2 | Meal log section | `AppTourKeys.addMealKey` | Log a Meal |
| 3 | Tab bar | `AppTourKeys.nutritionTabsKey` | More Detail |
| 4 | History button | `AppTourKeys.nutritionHistoryKey` | Track Over Time |

---

### Tour 4 — Schedule (`schedule_tour`)
**Trigger:** `ScheduleScreen` `initState` → `_triggerScheduleTour()`
**SharedPrefs key:** `has_seen_schedule_tour`

| Step | Target widget | Key | Title |
|------|--------------|-----|-------|
| 1 | Week selector | `AppTourKeys.weeklyCalendarKey` | Your Week |
| 2 | First workout card | `AppTourKeys.scheduleWorkoutCardKey` | Reschedule Easily |
| 3 | View mode toggle | `AppTourKeys.viewModeToggleKey` | Three Views |

---

### Tour 5 — Profile (`profile_tour`)
**Trigger:** `ProfileScreen` `initState` → `_triggerProfileTour()`
**SharedPrefs key:** `has_seen_profile_tour`

| Step | Target widget | Key | Title |
|------|--------------|-----|-------|
| 1 | View Stats button | `AppTourKeys.viewStatsKey` | Track Your Progress |
| 2 | Synced workouts row | `AppTourKeys.syncedWorkoutsKey` | Connect Health Apps |
| 3 | My Wrapped section | `AppTourKeys.wrappedKey` | Your Fitness Story |

---

## Adding a new tour

### 1. Add GlobalKeys to `AppTourKeys`

```dart
// In app_tour_controller.dart → AppTourKeys class
static final myNewWidgetKey = GlobalKey(debugLabel: 'tour_myNewWidget');
```

### 2. Attach the key to the target widget

```dart
// In the screen's build method — wrap the widget you want spotlighted:
Container(
  key: AppTourKeys.myNewWidgetKey,
  child: MyWidget(),
)
```

Or if the widget accepts a key directly:
```dart
MyWidget(key: AppTourKeys.myNewWidgetKey)
```

### 3. Write the trigger method in the screen

```dart
void _triggerMyTour() {
  final steps = [
    AppTourStep(
      id: 'my_tour_step_1',
      targetKey: AppTourKeys.myNewWidgetKey,
      title: 'Step Title',
      description: 'What this thing does.',
      position: TooltipPosition.below,
    ),
  ];
  ref.read(appTourControllerProvider.notifier).checkAndShow('my_tour', steps);
}
```

### 4. Call it in `initState`

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _triggerMyTour();
  });
}
```

That's it. The overlay, spotlight, and SharedPrefs persistence are handled automatically.

---

## Resetting tours (for testing)

To force a tour to show again, clear its SharedPrefs flag:

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove('has_seen_nav_tour');      // re-shows Tour 1
await prefs.remove('has_seen_workout_tour');  // re-shows Tour 2
await prefs.remove('has_seen_nutrition_tour');
await prefs.remove('has_seen_schedule_tour');
await prefs.remove('has_seen_profile_tour');
```

Or clear all app data / reinstall to reset all flags at once.

---

## Styling reference

| Property | Value |
|----------|-------|
| Overlay opacity | 75% black (`0xBF000000`) |
| Spotlight padding | 10 px around target rect |
| Spotlight corner radius | 12 px |
| Spotlight ring | 2 px stroke, current accent color |
| Tooltip card radius | 16 px |
| Tooltip card width | `min(screenWidth − 48, 360)` |
| Tooltip backdrop blur | 12 σ |
| Step transition | `AnimatedSwitcher` fade + 4 px slide Y (200 ms) |
| Spotlight transition | `TweenAnimationBuilder<Rect>` lerp (300 ms, easeInOutCubic) |
