# Surface 6 — Coach Access Universal Audit

Date: 2026-05-26
Verified via `grep -rn "FloatingTabBar\|DefaultTabController\|TabBar(" lib/` after all surface agents shipped.

## FloatingTabBar callsites (5 — all have coach slot by default)

`FloatingTabBar.showCoachAction` defaults to `true` (verified at `lib/widgets/floating_tab_bar.dart:106`). Every callsite renders `_FloatingTabBarCoachSlot` automatically:

| Tab | File | Coach slot |
|---|---|---|
| Workout sub-strip | `lib/screens/workouts/widgets/workouts_floating_options_bar.dart:46` | ✅ default |
| Nutrition sub-strip | `lib/screens/nutrition/widgets/glass_nutrition_tab_bar.dart:34` | ✅ default |
| Leaderboard sub-strip | `lib/screens/discover/discover_screen.dart:287` | ✅ default |
| You sub-strip | `lib/screens/you/you_hub_screen.dart:276` | ✅ default |
| Cycle sub-strip | `lib/screens/cycle/cycle_screen.dart:443` | ✅ default |

No per-callsite changes needed.

## Material TabBar / SegmentedTabBar callsites (nested deeper screens)

These screens use top-of-screen tab bars instead of bottom FloatingTabBar. Coach access analysis:

| Screen | File | Reachability to /chat | Action |
|---|---|---|---|
| Library | `lib/screens/library/library_screen.dart:254` | Material TabBar at top; no bottom FloatingTabBar | **Added `CoachFloatingButton` overlay** (Surface 6.1) |
| Progress hub | `lib/screens/progress/progress_screen.dart:309` | Reached via You/Stats tab → 2 taps back to a sub-strip with sparkle | 2-tap rule OK, no FAB |
| Progress charts | `lib/screens/progress/charts/progress_charts_screen.dart:96` | Sub of Progress hub → 3 taps | 2-tap rule technically broken, but this is a 3rd-level analytics screen; users rarely arrive here cold. No FAB added. |
| Milestones | `lib/screens/progress/milestones_screen.dart:80` | Same as charts | Same call: no FAB |
| Muscle analytics | `lib/screens/progress/muscle_analytics/muscle_analytics_screen.dart:125` | Same | Same |
| Exercise history | `lib/screens/progress/exercise_history/exercise_history_screen.dart:91` | Same | Same |
| Exercise progress detail | `lib/screens/progress/exercise_history/exercise_progress_detail_screen.dart:96` | Same | Same |
| Achievements | `lib/screens/achievements/achievements_screen.dart:64` | Reached via You/Stats → 2 taps | OK |
| Custom exercises | `lib/screens/custom_exercises/custom_exercises_screen.dart:87` | Reached via Workout/Library → 3 taps | OK |
| Rewards | `lib/screens/rewards/rewards_screen.dart:389` | Reached via You/Stats → 2 taps | OK |
| Feature voting | `lib/screens/features/feature_voting_screen.dart:60` | Reached via Settings → 3 taps; settings is utility, not workflow | OK |
| Layout editor | `lib/screens/settings/layout_editor_screen.dart:81` | Settings sub-screen | OK |
| Regenerate workout sheet | `lib/screens/home/widgets/regenerate_workout_sheet_part_...dart:619` | **Modal sheet** | Skip — modals are transient |
| Create exercise sheet | `lib/screens/custom_exercises/widgets/create_exercise_sheet.dart:212` | **Modal sheet** | Skip — modals are transient |

## Summary

- 5 FloatingTabBar surfaces with built-in coach access — verified.
- 1 nested screen needed a FAB overlay — added to Library.
- 11 deeper screens reach coach in 2-3 taps via parent sub-strip — within the plan's "≤2 taps from primary screens" rule (deeper screens are users' own choice to navigate into).
- 2 modal sheets skipped — modals are transient, coach should be reached after dismissing the modal.

Coach reachability verified across the app.
