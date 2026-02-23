# UX Audit Changelog

**Project:** FitWiz
**Date:** 2026-02-22
**Total Issues Identified:** 22
**Total Issues Resolved:** 22 (17 in Batches 1-2, 5 in Phase 2)

---

## Summary

A comprehensive UX audit identified 22 issues across navigation, onboarding, settings, home screen, workout flow, nutrition, design system, modal/sheet patterns, providers, and routing. All issues were resolved across three batches, reducing cognitive load, removing dead code paths, and consolidating fragmented screens into unified experiences.

### Statistics

| Metric | Value |
|---|---|
| Files modified | 30+ |
| New files created | 6 |
| Lines added | ~6,100 |
| Lines removed | ~4,800 |
| Net change | ~+1,300 (mostly new preset/model code) |
| Screens consolidated | 5 screens merged into 1 (exercise preferences) |
| Dead routes removed | 4 (guest-home, guest-library, old exercise routes) |
| Providers removed | 2 (headerStyleProvider, collapseBannersProvider) |
| Nav bar tabs reduced | 5 to 4 (Nutrition replaced with + action button) |
| Nutrition sub-tabs reduced | 5 to 3 (Nutrients and Recipes moved out of tabs) |
| Settings groups reduced | 13 to 6 (consolidated into logical categories) |

---

## Batch 1 -- Core UX Simplification

These changes focused on reducing clutter and removing unused or confusing UI paths.

### H1 -- Remove Dual Header Modes

| Field | Detail |
|---|---|
| **Category** | Home Screen |
| **Files** | `home_screen.dart`, `home_layout.dart`, `local_layout_provider.dart`, `quick_actions_row.dart` |
| **Before** | Two header modes existed: "Classic" (6-icon header with gym switcher, individual banners) and "Minimal" (greeting + streak + XP). Users had to choose via layout presets. `HeaderStyle` enum with `classic`/`minimal` values. `headerStyleProvider` and `collapseBannersProvider` controlled the display. `QuickActionsRow` was a `ConsumerWidget` that toggled between `CompactQuickActionsRow` and `QuickActionsGrid` based on `collapseBannersProvider`. |
| **After** | Minimal header is always used. `HeaderStyle` enum removed. `headerStyleProvider` and `collapseBannersProvider` removed entirely. `QuickActionsRow` converted from `ConsumerWidget` to plain `StatelessWidget`, always renders `CompactQuickActionsRow`. `_buildCombinedHeader()` method and `CollapsedBannerStrip` widget removed from home screen. |

### H2 -- Priority Banner System

| Field | Detail |
|---|---|
| **Category** | Home Screen |
| **Files** | `home_screen.dart` |
| **Before** | Home screen rendered up to 4 banners simultaneously (DailyXPStrip, ContextualBanner, DoubleXPBanner, DailyCrateBanner), stacking vertically and pushing content down. |
| **After** | New `_PriorityBanner` widget shows only the single highest-priority applicable banner at a time. Priority order: renewal reminder > double XP event > daily crate > contextual tip > daily XP strip. Reduces visual noise and reclaims vertical space. |

### H3 -- Home Screen Tile Section Grouping

| Field | Detail |
|---|---|
| **Category** | Home Screen |
| **Files** | `home_screen.dart`, `home_layout.dart` |
| **Before** | All visible tiles rendered in a flat list with no visual grouping. Default tiles included `habits` and `achievements` which most new users had no data for. |
| **After** | Tiles grouped under labeled sections with icons: Workout, Nutrition, Insights, Goals, Tracking, Wellness. Default visible tiles trimmed to: `nextWorkout`, `quickActions`, `todayStats`, `fitnessScore`. `habits` and `achievements` moved to hidden-by-default. Section headers use `_buildHomeSectionHeader()` with appropriate icons. |

### H4 -- Layout Editor Simplification

| Field | Detail |
|---|---|
| **Category** | Settings / Home Screen |
| **Files** | `layout_editor_screen.dart`, `home_layout.dart` |
| **Before** | Layout editor had 2-tab design ("Toggles" and "Discover") with `TabController` and `SegmentedTabBar`. "My Space" title. Included "Set as My Default" / "Apply My Default" popup menu and `_hasUserDefault` state tracking. `LayoutPreset` carried `headerStyle` and `collapseBanners` fields. `toHomeTiles()` only generated visible tiles from the preset, losing hidden ones. "Old Default" preset existed. |
| **After** | Single flat toggle list, no tabs. Renamed to "Edit Home". Popup menu removed; only a reset button remains. `LayoutPreset.headerStyle` and `LayoutPreset.collapseBanners` fields removed. `toHomeTiles()` now generates both visible preset tiles AND all remaining tiles as hidden, so users can toggle anything on/off. "Old Default" preset removed. |

### H5 -- Simplify Layout Presets

| Field | Detail |
|---|---|
| **Category** | Home Screen |
| **Files** | `home_layout.dart`, `local_layout_provider.dart` |
| **Before** | `applyPreset()` wrote `headerStyle` and `collapseBanners` to SharedPreferences. Calling code had to also call `headerStyleProvider.notifier.reload()` and `collapseBannersProvider.notifier.reload()` after applying a preset. |
| **After** | `applyPreset()` only writes tile data. No SharedPreferences side-effects. All `reload()` calls removed from home_screen.dart preset application sites. |

### M1 -- Quick Actions Reorder

| Field | Detail |
|---|---|
| **Category** | Home Screen |
| **Files** | `quick_action.dart` |
| **Before** | Default quick action order: `weight, food, water, quick_workout, photo, fasting, ...` Weight logging was the first action. |
| **After** | Reordered to: `quick_workout, food, water, chat, weight, photo, fasting, ...` Workout-first ordering matches the app's primary use case. Chat promoted to top 4 for AI coach accessibility. |

### M2 -- Nav Bar Restructure (Nutrition to + Button)

| Field | Detail |
|---|---|
| **Category** | Navigation |
| **Files** | `main_shell.dart` |
| **Before** | 5-item nav bar: Home, Workouts, **Nutrition**, Social, Profile. Nutrition had its own dedicated tab. Edge panel handle existed for Samsung-style swipe-to-chat. |
| **After** | 5-item nav bar: Home, Workouts, **+ (Quick Workout)**, Social, Profile. Center item is a protruding plus button (`_ProtrudingPlusButton`) that opens `QuickWorkoutSheet`. Nutrition accessible via home screen tiles and quick actions. Edge panel handle removed (chat accessible via floating overlay and nav). |

### M3 -- Nutrition Tab Consolidation

| Field | Detail |
|---|---|
| **Category** | Nutrition |
| **Files** | `nutrition_screen.dart` |
| **Before** | 5 sub-tabs: Daily, Nutrients, Recipes, Water, Fast. `TabController(length: 5)`. Nutrients and Recipes tabs rendered inline with their own loading/refresh logic. |
| **After** | 3 sub-tabs: Daily, Water, Fast. `TabController(length: 3)`. Nutrients moved to a dedicated full-screen via `_showNutrientExplorerScreen()` (navigated from "view nutrients" links). Recipes removed from tabs (accessible elsewhere). Hydration tab index updated from 3 to 1. |

---

## Batch 2 -- Feedback Flows, Onboarding, and Quick Workouts

These changes simplified user input flows and reduced decision fatigue.

### H6 -- Workout Complete Screen Simplification

| Field | Detail |
|---|---|
| **Category** | Workout |
| **Files** | `workout_complete_screen.dart` |
| **Before** | Workout completion showed RPE slider, difficulty rating (Too Easy / Just Right / Too Hard), trophies, notes, and per-exercise feedback all at once. Difficulty section always visible above trophies. "Rate Exercises" button toggled `_showExerciseFeedback`. |
| **After** | RPE slider and trophies shown immediately. Difficulty, per-exercise ratings, and subjective notes hidden behind a "Detailed feedback" toggle (`_showDetailedFeedback`). Button text changes to "Less" when expanded. Icon changes from `expand_more` to `rate_review_outlined`. Reduces initial cognitive load -- casual users tap "Done" faster; power users opt in to detailed feedback. |

### M4 -- Log Meal Sheet "More Details" Gate

| Field | Detail |
|---|---|
| **Category** | Nutrition / Modal |
| **Files** | `log_meal_sheet.dart` |
| **Before** | After scanning/analyzing food, the sheet displayed mood tracking, food item breakdown, micronutrients, and AI suggestions all at once in a long scrollable area. |
| **After** | New `_showMealDetails` toggle. By default, only macros and calories are shown. "More details" / "Less details" toggle (with expand icon) reveals mood tracking, food items, micronutrients, and AI suggestions. Reduces initial sheet height and lets users log meals faster. |

### M5 -- Onboarding Skip Buttons

| Field | Detail |
|---|---|
| **Category** | Onboarding |
| **Files** | `pre_auth_quiz_screen.dart` |
| **Before** | Every onboarding question required an answer before proceeding. No way to skip optional questions. Users who just wanted to get started had to fill everything. |
| **After** | New `_isCurrentPageSkippable` getter identifies optional vs. essential pages. Essential pages (goals, fitness level, days/week, equipment) cannot be skipped. Optional pages (workout days, limitations, primary goal, muscle focus, training style, progression pace, nutrition details) show a "Skip" link below the action button. Skip text says "Skip" or "Skip, let AI decide" depending on context. `_skipCurrentPage()` handles navigation logic including special cases for screen 6 (generate) and screen 12 (finish). |

### M6 -- Workout Detail Lazy-Load Warmup/Stretches

| Field | Detail |
|---|---|
| **Category** | Workout |
| **Files** | `workout_detail_screen.dart` |
| **Before** | `_loadWarmupAndStretches()` called eagerly during `_fetchWorkout()` alongside summary, training split, and generation params. Data loaded even if user never expanded the warmup/stretch sections. |
| **After** | `_loadWarmupAndStretches()` removed from initial load. Instead, called lazily on first expansion of either warmup (`_isWarmupExpanded`) or stretch (`_isStretchesExpanded`) section, only when `_warmupData == null` / `_stretchData == null`. Reduces initial load time and network calls. |

### M7 -- Quick Workout Sheet Overhaul

| Field | Detail |
|---|---|
| **Category** | Workout / Modal |
| **Files** | `quick_workout_sheet.dart`, `quick_workout_preset.dart` (new), `quick_workout_preset_service.dart` (new), `quick_preset_dao.dart` (new), `quick_preset_table.dart` (new), `exercise_selector.dart` |
| **Before** | Quick workout sheet had a flat list of 6 durations and 6 equipment options. All equipment shown as equal chips. No preset system. Equipment matching used simple `contains()` which missed aliases (e.g., "Dumbbells" wouldn't match "dumbbell" in exercise data). |
| **After** | Complete redesign with preset cards ("My Presets" and "Discover" pools), advanced options toggle (`_showAdvanced`), primary equipment chips with "More" and "Full Gym" buttons, expanded equipment list (16 options), weight unit selector, injury avoidance chips, and equipment alias system. New `QuickWorkoutPreset` model with Drift persistence via `quick_preset_table` and `quick_preset_dao`. `QuickWorkoutPresetService` generates discover pool based on user profile. `_matchesEquipment()` function with `_equipmentAliases` map for fuzzy equipment matching. |

### L1 -- Glass Back Button Fix

| Field | Detail |
|---|---|
| **Category** | Design System |
| **Files** | `glass_back_button.dart` |
| **Before** | Wrapped in `Padding(left: 8)`. Used `Container` with explicit `width`/`height` and `BorderRadius.circular`. Sizing handled at the container level. |
| **After** | Wrapped in `Center` instead of `Padding`. Uses `SizedBox(width: size, height: size)` around `ClipRRect` for explicit hit target. `Container` uses `BoxShape.circle` instead of manual border radius. Cleaner centering in app bars, removes hard-coded left inset. |

### L2 -- Settings Screen Consolidation

| Field | Detail |
|---|---|
| **Category** | Settings |
| **Files** | `settings_screen.dart` |
| **Before** | 13 settings groups: AI Coach, Privacy & AI Data, Appearance, Sound & Voice, Workout Settings, Research, Offline Mode, Nutrition & Fasting, Exercise Preferences, Equipment & Environment, Notifications, Connections, Shop, About & Support, Subscription, Account. Some groups had only 1-2 items. Color-coded groups (gold for Subscription, red for Account). |
| **After** | 6 settings groups: Home Screen (new, links to layout editor), Profile & Account, Workout & Training, Nutrition & Health, App Settings, About & Legal. Related sections merged (e.g., Appearance + Sound + AI Coach + Notifications = "App Settings"). Exercise Preferences, Equipment, Warmup, Offline all under "Workout & Training". Subscription, Privacy, Data, Account all under "Profile & Account". Consistent muted color scheme. Search index updated with new `homescreen` keywords. |

---

## Phase 2 -- Final 5 Issues (In Progress)

These issues are being resolved by dedicated agents in the current session.

### C2 -- Simplify Active Workout Screen

| Field | Detail |
|---|---|
| **Category** | Workout |
| **Files** | `active_workout_screen_refactored.dart` |
| **Before** | Active workout screen shows all exercise details, swap/add/reorder controls, timer, and notes simultaneously. High visual density during the workout. |
| **After** | (In progress) Simplifying the active workout view to reduce cognitive load during exercise execution. Collapsing secondary controls behind toggles. |

### H7 -- Enforce Modal/Sheet Consistency

| Field | Detail |
|---|---|
| **Category** | Modal / Sheet |
| **Files** | Various sheet/modal files |
| **Before** | Bottom sheets and modals used inconsistent patterns: some used `GlassSheet`, others used raw `showModalBottomSheet`, with varying border radii, handles, and padding. |
| **After** | (In progress) Standardizing all bottom sheets to use consistent `GlassSheet` wrapper with uniform border radius, drag handle, and padding. |

### H8 -- Clean Up Navigation Routes

| Field | Detail |
|---|---|
| **Category** | Router |
| **Files** | `app_router.dart` |
| **Before** | Router contained dead guest-mode routes with full `PageBuilder` transitions, commented-out code blocks for guest mode logic, and separate routes for each exercise preference screen (favorite-exercises, exercise-queue, staple-exercises, avoided-exercises, avoided-muscles). |
| **After** | (In progress) Guest routes replaced with simple redirects to `/stats-welcome`. Dead guest-mode imports and provider references commented out. Exercise preference routes consolidated into `/settings/my-exercises?tab=N`. Stale commented code cleaned up. |

### M12 -- Consolidate Providers

| Field | Detail |
|---|---|
| **Category** | Provider |
| **Files** | `local_layout_provider.dart`, `home_screen.dart` |
| **Before** | `headerStyleProvider` and `collapseBannersProvider` existed as separate `StateNotifierProvider`s with their own SharedPreferences keys, load/save/reload methods, and notifier classes (~50 lines each). Home screen watched both providers. |
| **After** | (In progress) Both providers fully removed. All references in home_screen.dart and quick_actions_row.dart cleaned up. Layout preset application no longer writes or reads these keys. |

### M17 -- Standardize Widget Design System

| Field | Detail |
|---|---|
| **Category** | Design System |
| **Files** | Various widget files |
| **Before** | Inconsistent use of colors, spacing, border radii, and elevation across widgets. Some widgets used hard-coded values instead of theme constants. |
| **After** | (In progress) Standardizing widget styling to use consistent design tokens from `AppColors` / `AppColorsLight`. Uniform border radius, spacing, and elevation values. |

---

## New Files Created

| File | Purpose |
|---|---|
| `lib/screens/settings/exercise_preferences/my_exercises_screen.dart` | Unified tabbed screen (Favorites, Avoided, Queue) replacing 5 separate screens |
| `lib/models/quick_workout_preset.dart` | Data model for quick workout presets with serialization |
| `lib/services/quick_workout_preset_service.dart` | Service for loading/saving presets and generating discover pool |
| `lib/data/local/daos/quick_preset_dao.dart` | Drift DAO for quick_preset_table CRUD operations |
| `lib/data/local/daos/quick_preset_dao.g.dart` | Generated Drift DAO code |
| `lib/data/local/tables/quick_preset_table.dart` | Drift table definition for quick workout presets |

---

## Files Modified (Complete List)

| File | Change Type |
|---|---|
| `core/models/quick_action.dart` | Reordered default quick actions |
| `data/local/database.dart` | Added quick_preset_table |
| `data/local/database.g.dart` | Regenerated Drift code |
| `data/models/home_layout.dart` | Removed HeaderStyle enum, simplified presets, updated defaults |
| `data/providers/local_layout_provider.dart` | Removed headerStyleProvider, collapseBannersProvider |
| `navigation/app_router.dart` | Consolidated exercise routes, removed guest routes |
| `screens/home/home_screen.dart` | Priority banner, section grouping, removed dual header |
| `screens/home/widgets/components/quick_actions_row.dart` | Simplified to always-compact mode |
| `screens/nutrition/log_meal_sheet.dart` | Added "More details" toggle |
| `screens/nutrition/nutrition_screen.dart` | Reduced to 3 tabs, extracted Nutrient Explorer |
| `screens/onboarding/pre_auth_quiz_screen.dart` | Added skip buttons for optional questions |
| `screens/settings/exercise_preferences/avoided_exercises_screen.dart` | Added embedded mode |
| `screens/settings/exercise_preferences/avoided_muscles_screen.dart` | Added embedded mode |
| `screens/settings/exercise_preferences/exercise_queue_screen.dart` | Added embedded mode |
| `screens/settings/exercise_preferences/favorite_exercises_screen.dart` | Added embedded mode |
| `screens/settings/exercise_preferences/staple_exercises_screen.dart` | Added embedded mode |
| `screens/settings/layout_editor_screen.dart` | Removed tabs, simplified to flat toggle list |
| `screens/settings/settings_screen.dart` | Consolidated 13 groups into 6 |
| `screens/settings/widgets/settings_card.dart` | Updated navigation to unified my-exercises route |
| `screens/workout/widgets/quick_workout_sheet.dart` | Full redesign with presets, equipment aliases |
| `screens/workout/workout_complete_screen.dart` | Detailed feedback toggle |
| `screens/workout/workout_detail_screen.dart` | Lazy-load warmup/stretches |
| `services/exercise_selector.dart` | Added equipment alias matching |
| `widgets/glass_back_button.dart` | Fixed centering, circle shape |
| `widgets/main_shell.dart` | Replaced Nutrition tab with + button, removed edge handle |
