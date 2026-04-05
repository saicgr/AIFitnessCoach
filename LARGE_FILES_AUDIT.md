# Large Files Audit - FitWiz Codebase

**Date:** 2026-04-04

Files with high line counts that should be refactored into smaller, modular files.

> Threshold: **1500+ lines** = needs attention, **3000+** = critical

---

## CRITICAL (3000+ lines)

### Flutter

| File | Lines |
|------|-------|
| `screens/nutrition/widgets/food_browser_panel.dart` | **4,302** |
| `screens/workout/workout_complete_screen.dart` | **3,884** |
| `screens/home/home_screen.dart` | **3,458** |

### Backend

None.

---

## WARNING (1500-3000 lines)

### Flutter

| File | Lines |
|------|-------|
| `screens/workout/workout_detail_screen.dart` | 2,831 |
| `screens/nutrition/weekly_checkin_sheet.dart` | 2,708 |
| `screens/nutrition/nutrition_settings_screen.dart` | 2,621 |
| `screens/diabetes/diabetes_dashboard_screen.dart` | 2,575 |
| `screens/workout/widgets/quick_workout_sheet.dart` | 2,518 |
| `screens/settings/widgets/settings_card.dart` | 2,505 |
| `screens/chat/chat_screen.dart` | 2,482 |
| `screens/xp_goals/xp_goals_screen.dart` | 2,412 |
| `screens/nutrition/log_meal_sheet.dart` | 2,384 |
| `screens/measurements/measurements_screen.dart` | 2,356 |
| `screens/neat/neat_dashboard_screen.dart` | 2,352 |
| `data/models/nutrition_preferences.dart` | 2,315 |
| `screens/workout/widgets/set_tracking_overlay.dart` | 2,285 |
| `data/services/notification_service.dart` | 2,243 |
| `data/services/context_logging_service.dart` | 2,206 |
| `navigation/app_router.dart` | 2,188 |
| `screens/home/widgets/cards/new_tiles.dart` | 2,154 |
| `screens/paywall/paywall_pricing_screen.dart` | 2,131 |
| `screens/workout/widgets/expanded_exercise_card.dart` | 2,123 |
| `screens/measurements/derived_metric_detail_screen.dart` | 2,076 |
| `data/repositories/chat_repository.dart` | 2,059 |
| `data/repositories/nutrition_repository.dart` | 2,018 |
| `screens/social/widgets/activity_card.dart` | 1,990 |
| `data/services/health_service.dart` | 1,964 |
| `screens/habits/habit_detail_screen.dart` | 1,962 |
| `data/services/social_service.dart` | 1,959 |
| `screens/library/tabs/netflix_exercises_tab.dart` | 1,950 |
| `data/providers/xp_provider.dart` | 1,950 |
| `screens/home/widgets/edit_gym_profile_sheet.dart` | 1,947 |
| `screens/habits/habits_screen.dart` | 1,927 |
| `screens/demo/demo_active_workout_screen.dart` | 1,859 |
| `screens/nutrition/food_history_screen.dart` | 1,840 |
| `screens/progress/progress_screen.dart` | 1,827 |
| `screens/library/components/exercise_detail_sheet.dart` | 1,815 |
| `screens/home/widgets/hero_workout_card.dart` | 1,797 |
| `screens/onboarding/widgets/quiz_body_metrics.dart` | 1,781 |
| `screens/onboarding/pre_auth_quiz_screen.dart` | 1,770 |
| `screens/profile/profile_screen.dart` | 1,753 |
| `screens/summaries/insights_screen.dart` | 1,740 |
| `screens/workout/widgets/rest_timer_overlay.dart` | 1,739 |
| `screens/nutrition/food_library_screen.dart` | 1,715 |
| `screens/workout/widgets/set_adjustment_sheet.dart` | 1,708 |
| `screens/settings/settings_screen.dart` | 1,705 |
| `screens/neat/widgets/neat_gamification_widgets.dart` | 1,694 |
| `screens/auth/stats_welcome_screen.dart` | 1,687 |
| `widgets/level_up_dialog.dart` | 1,637 |
| `screens/trophies/trophy_room_screen.dart` | 1,602 |
| `screens/workout/widgets/set_tracking_table.dart` | 1,598 |
| `screens/home/widgets/edit_program_sheet.dart` | 1,575 |
| `screens/measurements/measurement_detail_screen.dart` | 1,554 |
| `screens/nutrition/nutrient_explorer.dart` | 1,553 |
| `screens/schedule/schedule_screen.dart` | 1,529 |
| `screens/nutrition/recipe_builder_sheet.dart` | 1,516 |
| `screens/workout/widgets/exercise_swap_sheet.dart` | 1,514 |

### Backend

| File | Lines |
|------|-------|
| `api/v1/workouts/generation.py` | 2,688 |
| `services/email_service.py` | 2,492 |
| `api/v1/workouts_db.py` | 2,475 |
| `api/v1/workouts/crud.py` | 2,237 |
| `services/exercise_rag/service.py` | 2,111 |
| `services/food_analysis/cache_service.py` | 2,103 |
| `services/gemini/prompts.py` | 2,003 |
| `api/v1/exercise_preferences.py` | 1,983 |
| `api/v1/neat.py` | 1,964 |
| `api/v1/xp.py` | 1,866 |
| `services/neat_service.py` | 1,814 |
| `api/v1/scores.py` | 1,766 |
| `api/v1/fasting_impact.py` | 1,720 |
| `services/ingredient_inflammation/database.py` | 1,713 |
| `api/v1/personal_goals.py` | 1,702 |
| `api/v1/demo.py` | 1,690 |
| `services/notification_service.py` | 1,620 |
| `services/fatigue_detection_service.py` | 1,586 |
| `api/v1/notifications.py` | 1,572 |
| `api/v1/diabetes.py` | 1,546 |

---

## Summary

| Category | Count |
|----------|-------|
| Critical Flutter files (3000+) | 3 |
| Critical Backend files (3000+) | 0 |
| Warning Flutter files (1500-3000) | 54 |
| Warning Backend files (1500-3000) | 20 |
| **Total files needing attention** | **77** |
