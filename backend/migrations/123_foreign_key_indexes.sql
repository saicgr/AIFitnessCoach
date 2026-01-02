-- Migration: 123_foreign_key_indexes.sql
-- Description: Add indexes for unindexed foreign key columns to improve JOIN performance
-- This addresses Supabase linter INFO warnings for 52 foreign keys needing indexes
-- Created: 2026-01-01

-- ============================================================================
-- FOREIGN KEY INDEXES
-- Naming convention: idx_<table>_<column>
-- Using IF NOT EXISTS to make migration idempotent
-- ============================================================================

-- activity_feed
CREATE INDEX IF NOT EXISTS idx_activity_feed_achievement_id ON public.activity_feed(achievement_id);
CREATE INDEX IF NOT EXISTS idx_activity_feed_pr_id ON public.activity_feed(pr_id);
CREATE INDEX IF NOT EXISTS idx_activity_feed_workout_log_id ON public.activity_feed(workout_log_id);

-- billing_notifications
CREATE INDEX IF NOT EXISTS idx_billing_notifications_subscription_id ON public.billing_notifications(subscription_id);

-- carb_entries
CREATE INDEX IF NOT EXISTS idx_carb_entries_linked_glucose_reading_id ON public.carb_entries(linked_glucose_reading_id);
CREATE INDEX IF NOT EXISTS idx_carb_entries_linked_insulin_dose_id ON public.carb_entries(linked_insulin_dose_id);

-- challenge_notifications
CREATE INDEX IF NOT EXISTS idx_challenge_notifications_challenge_id ON public.challenge_notifications(challenge_id);

-- composite_exercise_components
CREATE INDEX IF NOT EXISTS idx_composite_exercise_components_component_exercise_id ON public.composite_exercise_components(component_exercise_id);

-- custom_exercise_usage
CREATE INDEX IF NOT EXISTS idx_custom_exercise_usage_workout_id ON public.custom_exercise_usage(workout_id);

-- daily_unified_state
CREATE INDEX IF NOT EXISTS idx_daily_unified_state_fasting_record_id ON public.daily_unified_state(fasting_record_id);

-- exercise_muscle_mappings
CREATE INDEX IF NOT EXISTS idx_exercise_muscle_mappings_exercise_id ON public.exercise_muscle_mappings(exercise_id);

-- exercise_performance_summary
CREATE INDEX IF NOT EXISTS idx_exercise_performance_summary_workout_id ON public.exercise_performance_summary(workout_id);

-- exercise_personal_records
CREATE INDEX IF NOT EXISTS idx_exercise_personal_records_workout_log_id ON public.exercise_personal_records(workout_log_id);

-- generated_workouts
CREATE INDEX IF NOT EXISTS idx_generated_workouts_user_id ON public.generated_workouts(user_id);

-- home_layouts
CREATE INDEX IF NOT EXISTS idx_home_layouts_template_id ON public.home_layouts(template_id);

-- mobility_exercise_tracking
CREATE INDEX IF NOT EXISTS idx_mobility_exercise_tracking_workout_id ON public.mobility_exercise_tracking(workout_id);

-- payment_transactions
CREATE INDEX IF NOT EXISTS idx_payment_transactions_subscription_id ON public.payment_transactions(subscription_id);

-- performance_logs
CREATE INDEX IF NOT EXISTS idx_performance_logs_workout_log_id ON public.performance_logs(workout_log_id);

-- personal_goal_records
CREATE INDEX IF NOT EXISTS idx_personal_goal_records_goal_id ON public.personal_goal_records(goal_id);

-- personal_records
CREATE INDEX IF NOT EXISTS idx_personal_records_workout_id ON public.personal_records(workout_id);

-- photo_comparisons
CREATE INDEX IF NOT EXISTS idx_photo_comparisons_after_photo_id ON public.photo_comparisons(after_photo_id);
CREATE INDEX IF NOT EXISTS idx_photo_comparisons_before_photo_id ON public.photo_comparisons(before_photo_id);

-- progress_photos
CREATE INDEX IF NOT EXISTS idx_progress_photos_measurement_id ON public.progress_photos(measurement_id);

-- progression_history
CREATE INDEX IF NOT EXISTS idx_progression_history_chain_id ON public.progression_history(chain_id);

-- recipe_suggestions
CREATE INDEX IF NOT EXISTS idx_recipe_suggestions_converted_to_recipe_id ON public.recipe_suggestions(converted_to_recipe_id);

-- refund_requests
CREATE INDEX IF NOT EXISTS idx_refund_requests_subscription_id ON public.refund_requests(subscription_id);

-- saved_workouts
CREATE INDEX IF NOT EXISTS idx_saved_workouts_source_user_id ON public.saved_workouts(source_user_id);

-- scheduled_workouts
CREATE INDEX IF NOT EXISTS idx_scheduled_workouts_saved_workout_id ON public.scheduled_workouts(saved_workout_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_workouts_workout_id ON public.scheduled_workouts(workout_id);

-- senior_workout_log
CREATE INDEX IF NOT EXISTS idx_senior_workout_log_workout_id ON public.senior_workout_log(workout_id);

-- set_rep_accuracy
CREATE INDEX IF NOT EXISTS idx_set_rep_accuracy_workout_id ON public.set_rep_accuracy(workout_id);

-- shared_goals
CREATE INDEX IF NOT EXISTS idx_shared_goals_joined_goal_id ON public.shared_goals(joined_goal_id);

-- social_notifications
CREATE INDEX IF NOT EXISTS idx_social_notifications_from_user_id ON public.social_notifications(from_user_id);

-- staple_exercises
CREATE INDEX IF NOT EXISTS idx_staple_exercises_library_id ON public.staple_exercises(library_id);

-- stretches
CREATE INDEX IF NOT EXISTS idx_stretches_superseded_by ON public.stretches(superseded_by);

-- subscription_history
CREATE INDEX IF NOT EXISTS idx_subscription_history_subscription_id ON public.subscription_history(subscription_id);

-- subscription_pauses
CREATE INDEX IF NOT EXISTS idx_subscription_pauses_subscription_id ON public.subscription_pauses(subscription_id);

-- user_exercise_mastery
CREATE INDEX IF NOT EXISTS idx_user_exercise_mastery_progression_chain_id ON public.user_exercise_mastery(progression_chain_id);

-- user_milestones
CREATE INDEX IF NOT EXISTS idx_user_milestones_milestone_id ON public.user_milestones(milestone_id);

-- warmups
CREATE INDEX IF NOT EXISTS idx_warmups_superseded_by ON public.warmups(superseded_by);

-- weekly_personal_goals
CREATE INDEX IF NOT EXISTS idx_weekly_personal_goals_source_suggestion_id ON public.weekly_personal_goals(source_suggestion_id);

-- workout_challenges
CREATE INDEX IF NOT EXISTS idx_workout_challenges_activity_id ON public.workout_challenges(activity_id);
CREATE INDEX IF NOT EXISTS idx_workout_challenges_workout_log_id ON public.workout_challenges(workout_log_id);

-- workout_performance_summary
CREATE INDEX IF NOT EXISTS idx_workout_performance_summary_workout_id ON public.workout_performance_summary(workout_id);

-- workout_regenerations
CREATE INDEX IF NOT EXISTS idx_workout_regenerations_new_workout_id ON public.workout_regenerations(new_workout_id);

-- workout_scheduling_history
CREATE INDEX IF NOT EXISTS idx_workout_scheduling_history_swapped_workout_id ON public.workout_scheduling_history(swapped_workout_id);

-- workout_shares
CREATE INDEX IF NOT EXISTS idx_workout_shares_workout_log_id ON public.workout_shares(workout_log_id);

-- workouts
CREATE INDEX IF NOT EXISTS idx_workouts_rescheduled_from_workout_id ON public.workouts(rescheduled_from_workout_id);
CREATE INDEX IF NOT EXISTS idx_workouts_superseded_by ON public.workouts(superseded_by);

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Total indexes created: 52
--
-- Tables affected:
-- - activity_feed (3 indexes)
-- - billing_notifications (1 index)
-- - carb_entries (2 indexes)
-- - challenge_notifications (1 index)
-- - composite_exercise_components (1 index)
-- - custom_exercise_usage (1 index)
-- - daily_unified_state (1 index)
-- - exercise_muscle_mappings (1 index)
-- - exercise_performance_summary (1 index)
-- - exercise_personal_records (1 index)
-- - generated_workouts (1 index)
-- - home_layouts (1 index)
-- - mobility_exercise_tracking (1 index)
-- - payment_transactions (1 index)
-- - performance_logs (1 index)
-- - personal_goal_records (1 index)
-- - personal_records (1 index)
-- - photo_comparisons (2 indexes)
-- - progress_photos (1 index)
-- - progression_history (1 index)
-- - recipe_suggestions (1 index)
-- - refund_requests (1 index)
-- - saved_workouts (1 index)
-- - scheduled_workouts (2 indexes)
-- - senior_workout_log (1 index)
-- - set_rep_accuracy (1 index)
-- - shared_goals (1 index)
-- - social_notifications (1 index)
-- - staple_exercises (1 index)
-- - stretches (1 index)
-- - subscription_history (1 index)
-- - subscription_pauses (1 index)
-- - user_exercise_mastery (1 index)
-- - user_milestones (1 index)
-- - warmups (1 index)
-- - weekly_personal_goals (1 index)
-- - workout_challenges (2 indexes)
-- - workout_performance_summary (1 index)
-- - workout_regenerations (1 index)
-- - workout_scheduling_history (1 index)
-- - workout_shares (1 index)
-- - workouts (2 indexes)
-- ============================================================================
