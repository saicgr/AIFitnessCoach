# App Tour System

Contextual, one-time tooltip overlay tours that teach new users about each screen the first time they visit it.

> **Two tour systems exist.** This `AppTour` engine (`lib/widgets/app_tour/`) powers the nav tour, the tier active-workout tours, and the log-meal tour. A separate **`EmptyStateTipTour`** engine (`lib/widgets/empty_state_tip_tour.dart`, tours in `lib/widgets/tooltips/tours/`) powers the first-run spotlight tours on the Discover, Nutrition, Workouts, and Menu-Analysis screens. They are independent — don't confuse the two.

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

## Tours

### Wired tours (live)

#### App Navigation (`nav_tour`)
**Trigger:** Home screen `initState` post-frame → `_triggerNavTour()` (`home_screen.dart`), fired ~800 ms after critical data loads. Skipped this session if Home has navigated away (e.g. the post-onboarding permissions primer) — it re-fires on the next Home visit.
**SharedPrefs key:** `has_seen_nav_tour`

| Step | Key | Title |
|------|-----|-------|
| 1 | `AppTourKeys.topBarKey` | Your Command Center |
| 2 | `AppTourKeys.heroCarouselKey` | Your AI Workout |
| 3 | `AppTourKeys.quickLogKey` | Quick Actions |
| 4 | `AppTourKeys.workoutNavKey` | Workouts |
| 5 | `AppTourKeys.nutritionNavKey` | Track Nutrition |
| 6 | `AppTourKeys.profileNavKey` | Your Progress |

#### Active Workout — tier-aware (`workout_tour_advanced` / `workout_tour_easy`)
**Trigger:** `triggerWorkoutTour()` in `workout_flow_mixin.dart`. Fired from the active-workout screen's `initState` AND re-fired by `handleWarmupComplete()` — it is **gated on `currentPhase == WorkoutPhase.active`** so it never burns against the warmup/stretch screens.
**Step lists:** tier-dependent, defined in `lib/core/services/workout_tour_steps.dart` (`stepsForTier` — Easy = 3, Advanced = 7; Simple currently reuses the Easy id).
**SharedPrefs keys:** canonical per-tier flags `tour_seen_easy` / `tour_seen_advanced` (the controller's `has_seen_<tourId>` flags are mirrored into these). Tier switches mid-tour abort and re-fire for the new tier.

#### Log-Meal (`nutrition_log_tour`)
**Trigger:** `log_meal_sheet` — fired once a meal analysis completes, anchored on the always-present Log button.
**SharedPrefs key:** `has_seen_nutrition_log_tour`

### Planned tours — scaffolded, NOT wired

`AppTourKeys` declares GlobalKeys for three more tours, but **no trigger method exists** for them and the keys are **not attached to any widget** — they are placeholders for future work. Do not assume these run:

| Tour id | Scaffolded keys | Status |
|---------|-----------------|--------|
| `nutrition_tour` | `macroGoals`, `addMeal`, `nutritionTabs`, `nutritionHistory` | Not wired. Nutrition's first-run tour is currently the `EmptyStateTipTour` `nutrition_v1`, not this. |
| `schedule_tour` | `weeklyCalendar`, `scheduleWorkoutCard`, `viewModeToggle` | Not wired — no `_triggerScheduleTour()`. |
| `profile_tour` | `viewStats`, `syncedWorkouts`, `wrapped` | Not wired — no `_triggerProfileTour()`. |

The Easy/Simple tier-screen keys (`easyExerciseHeader`, `easyStepper`, `simpleRail`, …) are likewise scaffolding — attached once those tier screens ship; until then the tier tours spotlight the nearest Advanced-screen widgets.

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
await prefs.remove('has_seen_nav_tour');            // re-shows the nav tour
await prefs.remove('has_seen_nutrition_log_tour');  // re-shows the log-meal tour
await prefs.remove('tour_seen_easy');               // re-shows the Easy tier tour
await prefs.remove('tour_seen_advanced');           // re-shows the Advanced tier tour
// (the tier tours also write has_seen_workout_tour_<tier> — clear those too
//  if you reset via the controller's own flag rather than the canonical keys)
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
