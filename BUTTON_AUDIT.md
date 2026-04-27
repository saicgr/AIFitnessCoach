# Zealova Button & Interactive Elements Audit
**Date:** 2026-03-24 | **Scope:** All screens across the Flutter mobile app

---

## CRITICAL: Broken Buttons (Empty/TODO Handlers)

These buttons are visible to users but do **nothing** when tapped.

| # | Screen | Button | File | Line | Issue |
|---|--------|--------|------|------|-------|
| 1 | Active Workout | **Add Exercise** (plan drawer) | `screens/workout/active_workout_screen_refactored.dart` | 6096 | Empty handler — `// TODO: Open exercise add sheet` |
| 2 | Active Workout | **Swap Exercise** (plan drawer) | `screens/workout/active_workout_screen_refactored.dart` | 6028 | Shows SnackBar placeholder only — no swap sheet |
| 3 | Active Workout | **Add to Superset** | `screens/workout/active_workout_screen_refactored.dart` | 6397 | Empty handler — `// TODO: Implement superset functionality` |
| 4 | List Workout | **History** button | `screens/workout/list_workout_screen.dart` | 457 | Empty handler — `// TODO: Show workout history` |
| 5 | List Workout | **Add Exercise** button | `screens/workout/list_workout_screen.dart` | 496 | Empty handler — `// TODO: Show exercise picker` |
| 6 | Injuries | **Check-in** button | `screens/injuries/injuries_screen.dart` | 174 | Shows SnackBar placeholder — no check-in dialog |
| 7 | Injury Detail | **View All** rehab exercises | `screens/injuries/injury_detail_screen.dart` | 726 | Empty handler — `// TODO: Navigate to rehab exercise list` |
| 8 | Injury Detail | **Toggle Rehab Complete** | `screens/injuries/injury_detail_screen.dart` | 740 | Empty handler — `// TODO: Toggle completion` |
| 9 | Diabetes Dashboard | **See All** blood glucose | `screens/diabetes/diabetes_dashboard_screen.dart` | 2223 | Empty handler — `// TODO: Navigate to full history` |
| 10 | NEAT Dashboard | **Quiet Hours** picker | `screens/neat/neat_dashboard_screen.dart` | 2244 | Empty handler — `// TODO: Implement time range picker` |
| 11 | Exercise Analytics | **Invite Friend** button | `screens/workout/widgets/exercise_analytics_page.dart` | 182 | Empty handler — `// TODO: Implement friend invite` |

---

## HIGH: Broken API / Routing

| # | Screen | Button | File | Line | Issue |
|---|--------|--------|------|------|-------|
| 12 | Nutrition | **Edit Goals in Settings** | `screens/nutrition/nutrition_screen.dart` | 1045 | Uses `Navigator.pushNamed('/nutrition/settings')` — route doesn't exist. Should be `context.push('/nutrition-settings')` |

---

## MEDIUM: Incomplete Save/Persist Logic

These buttons update UI locally but don't save to the backend.

| # | Screen | Button | File | Line | Issue |
|---|--------|--------|------|------|-------|
| 13 | Nutrient Explorer | **Pin Nutrients** toggle | `screens/nutrition/nutrient_explorer.dart` | 699 | Toggles local state only — `// TODO: Call repository to update pinned nutrients` |
| 14 | Equipment Settings | **Save Custom Environment** | `screens/settings/equipment/environment_list_screen.dart` | 118 | Pops sheet but doesn't save — `// TODO: Save custom environment` |
| 15 | Exercise Queue | **Reorder** (drag) | `screens/settings/exercise_preferences/exercise_queue_screen.dart` | 191 | `onReorder` has TODO — priority change not persisted |
| 16 | PR Share Card | **Share as Image** | `screens/workout/widgets/share_templates/pr_share_card.dart` | 650 | `_shareImage()` has TODO — capture/share not implemented |

---

## LOW: UX Inconsistencies

| # | Screen | Button | Issue |
|---|--------|--------|-------|
| 17 | Chat (Quick Actions) | Report a Problem | Routes to `/support-tickets/create` (create form) |
| 18 | Chat (Options Menu) | Report a Problem | Routes to `/support-tickets` (list screen) — inconsistent with #17 |

---

## LOW: Navigation Pattern Violations

These work but use deprecated `Navigator.push(MaterialPageRoute(...))` instead of `context.push()` (GoRouter):

| File | Line | Button |
|------|------|--------|
| `screens/profile/profile_screen.dart` | 2086 | Synced workout detail tap |
| `screens/settings/equipment/environment_list_screen.dart` | 89 | Environment selection |
| `screens/settings/subscription/request_refund_screen.dart` | 106 | Post-refund navigation |

---

## Intentionally Disabled (Not Broken)

Social features are commented out pending user base growth:

| File | Line | Feature |
|------|------|---------|
| `screens/stats/widgets/share_stats_sheet.dart` | 544 | Share stats to feed |
| `screens/profile/workout_gallery_screen.dart` | 530 | Post workout to feed |
| `screens/workout/widgets/share_workout_sheet.dart` | 677 | Share workout to social |
| `screens/settings/pages/privacy_data_page.dart` | 26 | Social privacy settings |

---

## Verified Working (All Clear)

The following areas were fully audited with **no issues found**:

- **Home Screen** — All carousel buttons (START, View Details, Regenerate, Skip, Mark Done, Share), quick actions, goals section, navigation
- **Workout Detail** — Start, favorite, share, regenerate, AI insights, all menu options
- **Workout Complete** — Submit feedback, AI review, extend workout, sauna logging, share
- **Workout Summary** — Share, revert buttons
- **Profile** — Edit profile, fitness card, training setup, all settings navigation
- **Settings** — All 15+ settings rows navigate to correct screens
- **Chat** — Send message, search, options menu (Change Coach, Clear History, About AI Coach)
- **Nutrition** — Date navigation, tabs, meal logging, hydration, edit targets
- **Onboarding** — Full quiz flow, continue/skip buttons
- **Auth** — Login, Google sign-in
- **Library** — Exercise cards, programs, filters
- **Support Tickets** — Create, reply, close

---

## Recommended Fix Priority

1. **Fix #12** (broken route) — one-line fix, currently crashes
2. **Fixes #1-3** (active workout) — users encounter these mid-workout
3. **Fixes #4-11** — either implement or hide buttons to avoid dead taps
4. **Fixes #13-16** — add backend persistence for save operations
