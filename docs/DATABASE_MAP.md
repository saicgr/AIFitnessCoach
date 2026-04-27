# Zealova Database Map

Development reference mapping all Supabase tables/views to their purpose and consuming API endpoints.

**Last updated:** 2026-02-27 | **Total tables:** 315+ | **Migrations:** 001–270

---

## Food & Nutrition Tables

| Table/View | Purpose | Used By |
|---|---|---|
| `food_database` | Base 716K food nutrition entries (USDA, OpenFoodFacts, CNF, INDB) | `batch_lookup_foods()` RPC |
| `food_database_deduped` | View: `WHERE is_primary = TRUE` — deduped entries | All food search queries via `search_food_database()` RPC |
| `food_nutrition_overrides` | **Curated corrections** — priority over base DB for known-wrong entries (dosa, eggs) | `FoodDatabaseLookupService` override layer |
| `saved_foods` | User-saved meals and favorites | `search_food_database_unified()` RPC, `nutrition.py` |
| `saved_foods_exploded` | View: exploded items from saved meals for search | Unified search |
| `food_logs` | Logged meals with full nutrition breakdown | `nutrition.py` |
| `food_reports` | User-submitted food data correction reports | Admin review |
| `food_search_cache` | Cached search results (7-day TTL) | Barcode/search endpoints |
| `food_analysis_cache` | AI food image analysis caching | Internal |
| `common_foods` | Pre-analyzed common food items | Internal |
| `nutrition_preferences` | Per-user settings (calorie target, dietary type, macro split) | `nutrition_preferences.py`, `onboarding.py` |
| `user_nutrition_preferences` | Extended nutrition tracking settings | `nutrition.py` |
| `adaptive_nutrition_calculations` | Dynamic TDEE adjustments | `nutrition_preferences.py` |
| `weekly_nutrition_recommendations` | AI-generated weekly nutrition plans | `nutrition_preferences.py` |
| `nutrition_scores` | Nutrition adherence scoring | `scores.py` |
| `nutrient_rdas` | RDA reference values | `nutrition.py` |
| `quick_log_history` | Quick meal logging history | `nutrition.py` |

### Data Flow: Food Logging

```
User input (text/image)
    → Gemini parses food items (name, amount, count, weight_g)
    → _enhance_food_items_with_nutrition_db()
        → FoodDatabaseLookupService.batch_lookup_foods()
            → Check overrides (exact match on food_name_normalized + variant_names)
            → If override: use override cal/100g + override_weight_per_piece_g
            → Else: query food_database_deduped via batch_lookup_foods() RPC
            → Else: USDA API fallback
            → Else: keep AI estimate
        → Apply weight correction:
            → If override has default_weight_per_piece_g AND weight_source != 'exact':
                correct weight_g = count × override_weight
            → Calculate: calories = cal_per_100g × (weight_g / 100)
    → Store in food_logs
```

### Override Priority Chain

```
food_nutrition_overrides > food_database_deduped > USDA API > AI estimate
```

---

## Workout & Exercise Tables

| Table/View | Purpose | Used By |
|---|---|---|
| `exercises` | Exercise library (name, muscles, equipment, form cues, video URLs) | `workouts/exercises.py`, `workouts/generation.py` |
| `custom_exercises` | User-created custom exercises | `custom_exercises.py` |
| `workouts` | Scheduled workouts for users | `workouts/crud.py`, `workouts/today.py` |
| `workout_logs` | Completion records for workouts | `workouts_db.py`, `consistency.py` |
| `performance_logs` | Per-exercise set/rep/weight data from completed workouts | `performance_db.py`, `exercise_history.py` |
| `strength_records` | Personal records (PRs) | `exercise_history.py`, `trophies.py` |
| `program_variants` | Program/periodization variants | `programs.py` |
| `program_history` | User's program history | `workouts/program_history.py` |
| `branded_programs` | Pre-built program templates | `library/branded_programs.py` |
| `workout_exits` | When/why users exit workouts mid-session | `workouts/exit_tracking.py` |
| `quick_workout_preferences` | Quick workout settings | `workouts/quick.py` |
| `saved_workouts` | User's saved workouts | `saved_workouts.py` |
| `ai_workout_suggestions` | AI-suggested workouts | `workouts/suggestions.py` |

## Consistency & Streaks

| Table/View | Purpose | Used By |
|---|---|---|
| `user_streaks` | Workout streak tracking | `achievements.py` |
| `streak_history` | Historical streak data | `consistency.py` |
| `daily_consistency_metrics` | Daily consistency scoring | `consistency.py` |
| `comeback_history` | Break detection and comeback tracking | `consistency.py` |
| `user_login_streaks` | Login streak for XP bonuses | `xp.py` |

## Gamification & XP

| Table/View | Purpose | Used By |
|---|---|---|
| `user_xp` | Total XP balance per user | `xp.py` |
| `xp_transactions` | XP earning/spending history | `xp.py` |
| `achievement_types` | Master achievement definitions | `achievements.py` |
| `user_achievements` | Earned achievements per user | `achievements.py`, `trophies.py` |
| `checkpoint_rewards` | Milestone/checkpoint rewards | `xp.py` |
| `level_rewards` | Level-based reward unlocks | `xp.py` |

## Social Features

| Table/View | Purpose | Used By |
|---|---|---|
| `user_connections` | Friends/followers | `social/connections.py` |
| `activity_feed` | Workout/achievement posts | `social/feed.py` |
| `activity_reactions` | Reactions to posts | `social/reactions.py` |
| `activity_comments` | Comments on posts | `social/comments.py` |
| `challenges` | Social challenges | `social/challenges.py` |
| `direct_messages` | DM content | `social/messages.py` |
| `user_privacy_settings` | Privacy controls | `social/privacy.py` |

## Goals & Planning

| Table/View | Purpose | Used By |
|---|---|---|
| `custom_goals` | User-defined custom goals | `custom_goals.py` |
| `weekly_personal_goals` | Weekly goal targets | `personal_goals.py` |
| `weekly_plans` | Weekly holistic plans | `weekly_plans.py` |
| `schedule_items` | Daily schedule items | `daily_schedule.py` |

## Progress & Analytics

| Table/View | Purpose | Used By |
|---|---|---|
| `progress_photos` | Before/after photo uploads | `progress_photos.py` |
| `photo_comparisons` | Side-by-side comparisons | `progress_photos.py` |
| `weight_logs` | Weight measurements over time | `hydration.py`, `progress.py` |
| `body_measurements` | Full body composition | `progress.py` |
| `user_insights` | AI-generated insights | `insights.py` |
| `exercise_performance_summary` | Aggregated per-exercise stats | `stats.py` |

## Health Tracking

| Table/View | Purpose | Used By |
|---|---|---|
| `drink_intake_logs` | Water/hydration logging | `hydration.py` |
| `fasting_records` | Intermittent fasting sessions | `fasting.py` |
| `fasting_preferences` | User fasting protocol | `fasting.py` |
| `diabetes_profiles` | Diabetes management | `diabetes.py` |
| `glucose_readings` | Blood glucose data | `diabetes.py` |
| `injuries` | Active injury tracker | `injuries.py` |

## Habits & NEAT

| Table/View | Purpose | Used By |
|---|---|---|
| `habits` | Habit definitions | `habits.py` |
| `habit_logs` | Habit completion logs | `habits.py` |
| `neat_goals` | NEAT activity goals | `neat.py` |
| `neat_daily_scores` | Daily NEAT scores | `neat.py` |

## Progression & Intensity

| Table/View | Purpose | Used By |
|---|---|---|
| `user_exercise_1rms` | 1RM estimates per exercise | `training_intensity.py` |
| `exercise_intensity_overrides` | Custom intensity adjustments | `training_intensity.py` |
| `exercise_progression_chains` | Skill progression chains | `skill_progressions.py` |
| `user_skill_progress` | User progress through chains | `skill_progressions.py` |
| `set_adjustments` | User set/rep adjustments | `workouts/set_adjustments.py` |

## Chat & Support

| Table/View | Purpose | Used By |
|---|---|---|
| `chat_history` | Chat conversation history | `chat.py` |
| `chat_message_reports` | Reported messages | `chat_reports.py` |
| `support_tickets` | Customer support tickets | `support.py` |

## User Settings & Preferences

| Table/View | Purpose | Used By |
|---|---|---|
| `users` | Core user profile (measurements, settings) | `users.py`, `onboarding.py` |
| `user_ai_settings` | AI coach persona settings | `ai_settings.py` |
| `notification_preferences` | Notification settings | `notifications.py` |
| `home_layouts` | Home screen layout configs | `layouts.py` |
| `gym_profiles` | Gym equipment/profile | `gym_profiles.py` |

## Subscriptions & Billing

| Table/View | Purpose | Used By |
|---|---|---|
| `user_subscriptions` | Current subscription status | `subscriptions.py` |
| `subscription_history` | Historical changes | `subscriptions.py` |
| `payment_transactions` | Payment records | `subscriptions.py` |
| `feature_gates` | Feature access control | `features.py` |

## Analytics & Telemetry

| Table/View | Purpose | Used By |
|---|---|---|
| `user_sessions` | App session tracking | `analytics.py` |
| `screen_views` | Screen view analytics | `analytics.py` |
| `onboarding_analytics` | Onboarding flow analytics | `analytics.py` |
| `weekly_summaries` | AI-generated weekly summaries | `summaries.py` |
| `fitness_wrapped` | Year-end fitness summary | `wrapped.py` |
