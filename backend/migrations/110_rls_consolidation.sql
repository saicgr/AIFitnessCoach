-- RLS Policy Consolidation and auth.jwt() Fix Migration
-- Fixes:
-- 1. Policies using auth.jwt() ->> 'role' instead of (select auth.role())
-- 2. Consolidates multiple permissive policies into single combined policies
--    Each table gets one policy per command (SELECT, INSERT, UPDATE, DELETE)
--    with OR logic combining user access and service role access

BEGIN;

-- =====================================================
-- PART 1: Fix auth.jwt() policies to use (select auth.role())
-- Note: Some tables will be further consolidated in Part 2
-- =====================================================

-- =====================================================
-- PART 2: Consolidate multiple permissive policies
-- =====================================================

-- Table: app_errors
DROP POLICY IF EXISTS "Service role full access errors" ON public.app_errors;
DROP POLICY IF EXISTS "Users can insert own errors" ON public.app_errors;
DROP POLICY IF EXISTS "Users can read own errors" ON public.app_errors;
CREATE POLICY "app_errors_delete_policy" ON public.app_errors FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "app_errors_insert_policy" ON public.app_errors FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "app_errors_select_policy" ON public.app_errors FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "app_errors_update_policy" ON public.app_errors FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: audio_preferences
DROP POLICY IF EXISTS "Service role has full access to audio preferences" ON public.audio_preferences;
DROP POLICY IF EXISTS "Users can delete own audio preferences" ON public.audio_preferences;
DROP POLICY IF EXISTS "Users can insert own audio preferences" ON public.audio_preferences;
DROP POLICY IF EXISTS "Users can view own audio preferences" ON public.audio_preferences;
DROP POLICY IF EXISTS "Users can update own audio preferences" ON public.audio_preferences;
CREATE POLICY "audio_preferences_delete_policy" ON public.audio_preferences FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "audio_preferences_insert_policy" ON public.audio_preferences FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "audio_preferences_select_policy" ON public.audio_preferences FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "audio_preferences_update_policy" ON public.audio_preferences FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: billing_notifications
DROP POLICY IF EXISTS "Service role full access billing notifications" ON public.billing_notifications;
DROP POLICY IF EXISTS "Users can read own billing notifications" ON public.billing_notifications;
CREATE POLICY "billing_notifications_delete_policy" ON public.billing_notifications FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "billing_notifications_insert_policy" ON public.billing_notifications FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "billing_notifications_select_policy" ON public.billing_notifications FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "billing_notifications_update_policy" ON public.billing_notifications FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: body_measurements
DROP POLICY IF EXISTS "body_measurements_service_policy" ON public.body_measurements;
DROP POLICY IF EXISTS "body_measurements_delete_policy" ON public.body_measurements;
DROP POLICY IF EXISTS "body_measurements_insert_policy" ON public.body_measurements;
DROP POLICY IF EXISTS "body_measurements_select_policy" ON public.body_measurements;
DROP POLICY IF EXISTS "body_measurements_update_policy" ON public.body_measurements;
CREATE POLICY "body_measurements_delete_policy" ON public.body_measurements FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "body_measurements_insert_policy" ON public.body_measurements FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "body_measurements_select_policy" ON public.body_measurements FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "body_measurements_update_policy" ON public.body_measurements FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: cancellation_feedback
DROP POLICY IF EXISTS "Service role full access to cancellation_feedback" ON public.cancellation_feedback;
DROP POLICY IF EXISTS "Users can insert own cancellation feedback" ON public.cancellation_feedback;
CREATE POLICY "cancellation_feedback_delete_policy" ON public.cancellation_feedback FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "cancellation_feedback_insert_policy" ON public.cancellation_feedback FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "cancellation_feedback_select_policy" ON public.cancellation_feedback FOR SELECT USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "cancellation_feedback_update_policy" ON public.cancellation_feedback FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: cancellation_requests
DROP POLICY IF EXISTS "Service role cancellation requests" ON public.cancellation_requests;
DROP POLICY IF EXISTS "Users can read own cancellation requests" ON public.cancellation_requests;
CREATE POLICY "cancellation_requests_delete_policy" ON public.cancellation_requests FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "cancellation_requests_insert_policy" ON public.cancellation_requests FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "cancellation_requests_select_policy" ON public.cancellation_requests FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "cancellation_requests_update_policy" ON public.cancellation_requests FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: cardio_sessions
DROP POLICY IF EXISTS "Service role has full access to cardio sessions" ON public.cardio_sessions;
DROP POLICY IF EXISTS "Users can delete own cardio sessions" ON public.cardio_sessions;
DROP POLICY IF EXISTS "Users can insert own cardio sessions" ON public.cardio_sessions;
DROP POLICY IF EXISTS "Users can view own cardio sessions" ON public.cardio_sessions;
DROP POLICY IF EXISTS "Users can update own cardio sessions" ON public.cardio_sessions;
CREATE POLICY "cardio_sessions_delete_policy" ON public.cardio_sessions FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "cardio_sessions_insert_policy" ON public.cardio_sessions FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "cardio_sessions_select_policy" ON public.cardio_sessions FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "cardio_sessions_update_policy" ON public.cardio_sessions FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: conversion_triggers
DROP POLICY IF EXISTS "conversion_triggers_service_policy" ON public.conversion_triggers;
DROP POLICY IF EXISTS "conversion_triggers_insert_policy" ON public.conversion_triggers;
DROP POLICY IF EXISTS "conversion_triggers_user_policy" ON public.conversion_triggers;
CREATE POLICY "conversion_triggers_delete_policy" ON public.conversion_triggers FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "conversion_triggers_insert_policy" ON public.conversion_triggers FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "conversion_triggers_select_policy" ON public.conversion_triggers FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "conversion_triggers_update_policy" ON public.conversion_triggers FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: daily_user_stats
DROP POLICY IF EXISTS "Service role full access daily stats" ON public.daily_user_stats;
DROP POLICY IF EXISTS "Users can read own daily stats" ON public.daily_user_stats;
CREATE POLICY "daily_user_stats_delete_policy" ON public.daily_user_stats FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "daily_user_stats_insert_policy" ON public.daily_user_stats FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "daily_user_stats_select_policy" ON public.daily_user_stats FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "daily_user_stats_update_policy" ON public.daily_user_stats FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: drink_intake_logs
DROP POLICY IF EXISTS "Service role can manage drink intakes" ON public.drink_intake_logs;
DROP POLICY IF EXISTS "Users can insert their own drink intakes" ON public.drink_intake_logs;
DROP POLICY IF EXISTS "Users can view their own drink intakes" ON public.drink_intake_logs;
CREATE POLICY "drink_intake_logs_delete_policy" ON public.drink_intake_logs FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "drink_intake_logs_insert_policy" ON public.drink_intake_logs FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "drink_intake_logs_select_policy" ON public.drink_intake_logs FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "drink_intake_logs_update_policy" ON public.drink_intake_logs FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: email_preferences
DROP POLICY IF EXISTS "Service role has full access to email preferences" ON public.email_preferences;
DROP POLICY IF EXISTS "Users can delete own email preferences" ON public.email_preferences;
DROP POLICY IF EXISTS "Users can insert own email preferences" ON public.email_preferences;
DROP POLICY IF EXISTS "Users can view own email preferences" ON public.email_preferences;
DROP POLICY IF EXISTS "Users can update own email preferences" ON public.email_preferences;
CREATE POLICY "email_preferences_delete_policy" ON public.email_preferences FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "email_preferences_insert_policy" ON public.email_preferences FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "email_preferences_select_policy" ON public.email_preferences FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "email_preferences_update_policy" ON public.email_preferences FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: exercise_feedback
DROP POLICY IF EXISTS "exercise_feedback_service_policy" ON public.exercise_feedback;
DROP POLICY IF EXISTS "exercise_feedback_delete_policy" ON public.exercise_feedback;
DROP POLICY IF EXISTS "exercise_feedback_insert_policy" ON public.exercise_feedback;
DROP POLICY IF EXISTS "exercise_feedback_select_policy" ON public.exercise_feedback;
DROP POLICY IF EXISTS "exercise_feedback_update_policy" ON public.exercise_feedback;
CREATE POLICY "exercise_feedback_delete_policy" ON public.exercise_feedback FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "exercise_feedback_insert_policy" ON public.exercise_feedback FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "exercise_feedback_select_policy" ON public.exercise_feedback FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "exercise_feedback_update_policy" ON public.exercise_feedback FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: exercise_performance_summary
DROP POLICY IF EXISTS "Service role can manage all exercise performance" ON public.exercise_performance_summary;
DROP POLICY IF EXISTS "Users can insert own exercise performance" ON public.exercise_performance_summary;
DROP POLICY IF EXISTS "Users can view own exercise performance" ON public.exercise_performance_summary;
CREATE POLICY "exercise_performance_summary_delete_policy" ON public.exercise_performance_summary FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "exercise_performance_summary_insert_policy" ON public.exercise_performance_summary FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "exercise_performance_summary_select_policy" ON public.exercise_performance_summary FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "exercise_performance_summary_update_policy" ON public.exercise_performance_summary FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: exercise_rotations
DROP POLICY IF EXISTS "Service role has full access to exercise_rotations" ON public.exercise_rotations;
DROP POLICY IF EXISTS "Users can view their own exercise rotations" ON public.exercise_rotations;
CREATE POLICY "exercise_rotations_delete_policy" ON public.exercise_rotations FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "exercise_rotations_insert_policy" ON public.exercise_rotations FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "exercise_rotations_select_policy" ON public.exercise_rotations FOR SELECT USING ((( SELECT auth.uid() AS uid) IN ( SELECT users.auth_id
   FROM users
  WHERE (users.id = exercise_rotations.user_id))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "exercise_rotations_update_policy" ON public.exercise_rotations FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: fitness_scores
DROP POLICY IF EXISTS "fitness_scores_service_policy" ON public.fitness_scores;
DROP POLICY IF EXISTS "fitness_scores_insert_policy" ON public.fitness_scores;
DROP POLICY IF EXISTS "fitness_scores_select_policy" ON public.fitness_scores;
CREATE POLICY "fitness_scores_delete_policy" ON public.fitness_scores FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "fitness_scores_insert_policy" ON public.fitness_scores FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "fitness_scores_select_policy" ON public.fitness_scores FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "fitness_scores_update_policy" ON public.fitness_scores FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: food_logs
DROP POLICY IF EXISTS "food_logs_service_policy" ON public.food_logs;
DROP POLICY IF EXISTS "food_logs_delete_policy" ON public.food_logs;
DROP POLICY IF EXISTS "food_logs_insert_policy" ON public.food_logs;
DROP POLICY IF EXISTS "food_logs_select_policy" ON public.food_logs;
DROP POLICY IF EXISTS "food_logs_update_policy" ON public.food_logs;
CREATE POLICY "food_logs_delete_policy" ON public.food_logs FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "food_logs_insert_policy" ON public.food_logs FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "food_logs_select_policy" ON public.food_logs FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "food_logs_update_policy" ON public.food_logs FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: friend_requests
DROP POLICY IF EXISTS "Service role can manage friend requests" ON public.friend_requests;
DROP POLICY IF EXISTS "Users can cancel own friend requests" ON public.friend_requests;
DROP POLICY IF EXISTS "Users can send friend requests" ON public.friend_requests;
DROP POLICY IF EXISTS "Users can view own friend requests" ON public.friend_requests;
DROP POLICY IF EXISTS "Users can respond to friend requests" ON public.friend_requests;
CREATE POLICY "friend_requests_delete_policy" ON public.friend_requests FOR DELETE USING (((( SELECT auth.uid() AS uid))::text = (from_user_id)::text) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "friend_requests_insert_policy" ON public.friend_requests FOR INSERT WITH CHECK (((( SELECT auth.uid() AS uid))::text = (from_user_id)::text) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "friend_requests_select_policy" ON public.friend_requests FOR SELECT USING ((((( SELECT auth.uid() AS uid))::text = (from_user_id)::text) OR ((( SELECT auth.uid() AS uid))::text = (to_user_id)::text)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "friend_requests_update_policy" ON public.friend_requests FOR UPDATE USING (((( SELECT auth.uid() AS uid))::text = (to_user_id)::text) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK (((( SELECT auth.uid() AS uid))::text = (to_user_id)::text) OR ((select auth.role()) = 'service_role'::text));

-- Table: funnel_events
DROP POLICY IF EXISTS "Service role full access funnel" ON public.funnel_events;
DROP POLICY IF EXISTS "Users can insert own funnel events" ON public.funnel_events;
DROP POLICY IF EXISTS "Users can read own funnel events" ON public.funnel_events;
CREATE POLICY "funnel_events_delete_policy" ON public.funnel_events FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "funnel_events_insert_policy" ON public.funnel_events FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "funnel_events_select_policy" ON public.funnel_events FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "funnel_events_update_policy" ON public.funnel_events FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: hydration_logs
DROP POLICY IF EXISTS "hydration_logs_service_policy" ON public.hydration_logs;
DROP POLICY IF EXISTS "hydration_logs_delete_policy" ON public.hydration_logs;
DROP POLICY IF EXISTS "hydration_logs_insert_policy" ON public.hydration_logs;
DROP POLICY IF EXISTS "hydration_logs_select_policy" ON public.hydration_logs;
DROP POLICY IF EXISTS "hydration_logs_update_policy" ON public.hydration_logs;
CREATE POLICY "hydration_logs_delete_policy" ON public.hydration_logs FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "hydration_logs_insert_policy" ON public.hydration_logs FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "hydration_logs_select_policy" ON public.hydration_logs FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "hydration_logs_update_policy" ON public.hydration_logs FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: mobility_exercise_tracking
DROP POLICY IF EXISTS "Service role has full access to mobility_exercise_tracking" ON public.mobility_exercise_tracking;
DROP POLICY IF EXISTS "Users can insert their own mobility tracking" ON public.mobility_exercise_tracking;
DROP POLICY IF EXISTS "Users can view their own mobility tracking" ON public.mobility_exercise_tracking;
CREATE POLICY "mobility_exercise_tracking_delete_policy" ON public.mobility_exercise_tracking FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "mobility_exercise_tracking_insert_policy" ON public.mobility_exercise_tracking FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "mobility_exercise_tracking_select_policy" ON public.mobility_exercise_tracking FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "mobility_exercise_tracking_update_policy" ON public.mobility_exercise_tracking FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: mood_checkins
DROP POLICY IF EXISTS "mood_checkins_service_policy" ON public.mood_checkins;
DROP POLICY IF EXISTS "mood_checkins_insert_policy" ON public.mood_checkins;
DROP POLICY IF EXISTS "mood_checkins_select_policy" ON public.mood_checkins;
DROP POLICY IF EXISTS "mood_checkins_update_policy" ON public.mood_checkins;
CREATE POLICY "mood_checkins_delete_policy" ON public.mood_checkins FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "mood_checkins_insert_policy" ON public.mood_checkins FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "mood_checkins_select_policy" ON public.mood_checkins FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "mood_checkins_update_policy" ON public.mood_checkins FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: neat_daily_scores
DROP POLICY IF EXISTS "neat_daily_scores_service_policy" ON public.neat_daily_scores;
DROP POLICY IF EXISTS "neat_daily_scores_delete_policy" ON public.neat_daily_scores;
DROP POLICY IF EXISTS "neat_daily_scores_insert_policy" ON public.neat_daily_scores;
DROP POLICY IF EXISTS "neat_daily_scores_select_policy" ON public.neat_daily_scores;
DROP POLICY IF EXISTS "neat_daily_scores_update_policy" ON public.neat_daily_scores;
CREATE POLICY "neat_daily_scores_delete_policy" ON public.neat_daily_scores FOR DELETE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_daily_scores_insert_policy" ON public.neat_daily_scores FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_daily_scores_select_policy" ON public.neat_daily_scores FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_daily_scores_update_policy" ON public.neat_daily_scores FOR UPDATE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));

-- Table: neat_goals
DROP POLICY IF EXISTS "neat_goals_service_policy" ON public.neat_goals;
DROP POLICY IF EXISTS "neat_goals_delete_policy" ON public.neat_goals;
DROP POLICY IF EXISTS "neat_goals_insert_policy" ON public.neat_goals;
DROP POLICY IF EXISTS "neat_goals_select_policy" ON public.neat_goals;
DROP POLICY IF EXISTS "neat_goals_update_policy" ON public.neat_goals;
CREATE POLICY "neat_goals_delete_policy" ON public.neat_goals FOR DELETE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_goals_insert_policy" ON public.neat_goals FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_goals_select_policy" ON public.neat_goals FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_goals_update_policy" ON public.neat_goals FOR UPDATE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));

-- Table: neat_hourly_activity
DROP POLICY IF EXISTS "neat_hourly_activity_service_policy" ON public.neat_hourly_activity;
DROP POLICY IF EXISTS "neat_hourly_activity_delete_policy" ON public.neat_hourly_activity;
DROP POLICY IF EXISTS "neat_hourly_activity_insert_policy" ON public.neat_hourly_activity;
DROP POLICY IF EXISTS "neat_hourly_activity_select_policy" ON public.neat_hourly_activity;
DROP POLICY IF EXISTS "neat_hourly_activity_update_policy" ON public.neat_hourly_activity;
CREATE POLICY "neat_hourly_activity_delete_policy" ON public.neat_hourly_activity FOR DELETE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_hourly_activity_insert_policy" ON public.neat_hourly_activity FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_hourly_activity_select_policy" ON public.neat_hourly_activity FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_hourly_activity_update_policy" ON public.neat_hourly_activity FOR UPDATE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));

-- Table: neat_reminder_preferences
DROP POLICY IF EXISTS "neat_reminder_preferences_service_policy" ON public.neat_reminder_preferences;
DROP POLICY IF EXISTS "neat_reminder_preferences_delete_policy" ON public.neat_reminder_preferences;
DROP POLICY IF EXISTS "neat_reminder_preferences_insert_policy" ON public.neat_reminder_preferences;
DROP POLICY IF EXISTS "neat_reminder_preferences_select_policy" ON public.neat_reminder_preferences;
DROP POLICY IF EXISTS "neat_reminder_preferences_update_policy" ON public.neat_reminder_preferences;
CREATE POLICY "neat_reminder_preferences_delete_policy" ON public.neat_reminder_preferences FOR DELETE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_reminder_preferences_insert_policy" ON public.neat_reminder_preferences FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_reminder_preferences_select_policy" ON public.neat_reminder_preferences FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_reminder_preferences_update_policy" ON public.neat_reminder_preferences FOR UPDATE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));

-- Table: neat_streaks
DROP POLICY IF EXISTS "neat_streaks_service_policy" ON public.neat_streaks;
DROP POLICY IF EXISTS "neat_streaks_delete_policy" ON public.neat_streaks;
DROP POLICY IF EXISTS "neat_streaks_insert_policy" ON public.neat_streaks;
DROP POLICY IF EXISTS "neat_streaks_select_policy" ON public.neat_streaks;
DROP POLICY IF EXISTS "neat_streaks_update_policy" ON public.neat_streaks;
CREATE POLICY "neat_streaks_delete_policy" ON public.neat_streaks FOR DELETE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_streaks_insert_policy" ON public.neat_streaks FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_streaks_select_policy" ON public.neat_streaks FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_streaks_update_policy" ON public.neat_streaks FOR UPDATE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));

-- Table: neat_weekly_summaries
DROP POLICY IF EXISTS "neat_weekly_summaries_service_policy" ON public.neat_weekly_summaries;
DROP POLICY IF EXISTS "neat_weekly_summaries_delete_policy" ON public.neat_weekly_summaries;
DROP POLICY IF EXISTS "neat_weekly_summaries_insert_policy" ON public.neat_weekly_summaries;
DROP POLICY IF EXISTS "neat_weekly_summaries_select_policy" ON public.neat_weekly_summaries;
DROP POLICY IF EXISTS "neat_weekly_summaries_update_policy" ON public.neat_weekly_summaries;
CREATE POLICY "neat_weekly_summaries_delete_policy" ON public.neat_weekly_summaries FOR DELETE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_weekly_summaries_insert_policy" ON public.neat_weekly_summaries FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_weekly_summaries_select_policy" ON public.neat_weekly_summaries FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "neat_weekly_summaries_update_policy" ON public.neat_weekly_summaries FOR UPDATE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));

-- Table: notification_preferences
DROP POLICY IF EXISTS "notification_preferences_service_policy" ON public.notification_preferences;
DROP POLICY IF EXISTS "notification_preferences_insert_policy" ON public.notification_preferences;
DROP POLICY IF EXISTS "notification_preferences_select_policy" ON public.notification_preferences;
DROP POLICY IF EXISTS "notification_preferences_update_policy" ON public.notification_preferences;
CREATE POLICY "notification_preferences_delete_policy" ON public.notification_preferences FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "notification_preferences_insert_policy" ON public.notification_preferences FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "notification_preferences_select_policy" ON public.notification_preferences FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "notification_preferences_update_policy" ON public.notification_preferences FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: nutrition_scores
DROP POLICY IF EXISTS "nutrition_scores_service_policy" ON public.nutrition_scores;
DROP POLICY IF EXISTS "nutrition_scores_insert_policy" ON public.nutrition_scores;
DROP POLICY IF EXISTS "nutrition_scores_select_policy" ON public.nutrition_scores;
CREATE POLICY "nutrition_scores_delete_policy" ON public.nutrition_scores FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "nutrition_scores_insert_policy" ON public.nutrition_scores FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "nutrition_scores_select_policy" ON public.nutrition_scores FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "nutrition_scores_update_policy" ON public.nutrition_scores FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: onboarding_analytics
DROP POLICY IF EXISTS "Service role full access onboarding" ON public.onboarding_analytics;
DROP POLICY IF EXISTS "Users can insert own onboarding analytics" ON public.onboarding_analytics;
DROP POLICY IF EXISTS "Users can read own onboarding analytics" ON public.onboarding_analytics;
CREATE POLICY "onboarding_analytics_delete_policy" ON public.onboarding_analytics FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "onboarding_analytics_insert_policy" ON public.onboarding_analytics FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "onboarding_analytics_select_policy" ON public.onboarding_analytics FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "onboarding_analytics_update_policy" ON public.onboarding_analytics FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: payment_transactions
DROP POLICY IF EXISTS "Service role full access transactions" ON public.payment_transactions;
DROP POLICY IF EXISTS "Users can read own transactions" ON public.payment_transactions;
CREATE POLICY "payment_transactions_delete_policy" ON public.payment_transactions FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "payment_transactions_insert_policy" ON public.payment_transactions FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "payment_transactions_select_policy" ON public.payment_transactions FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "payment_transactions_update_policy" ON public.payment_transactions FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: personal_records
DROP POLICY IF EXISTS "personal_records_service_policy" ON public.personal_records;
DROP POLICY IF EXISTS "personal_records_insert_policy" ON public.personal_records;
DROP POLICY IF EXISTS "personal_records_select_policy" ON public.personal_records;
CREATE POLICY "personal_records_delete_policy" ON public.personal_records FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "personal_records_insert_policy" ON public.personal_records FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "personal_records_select_policy" ON public.personal_records FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "personal_records_update_policy" ON public.personal_records FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: photo_comparisons
DROP POLICY IF EXISTS "photo_comparisons_service_policy" ON public.photo_comparisons;
DROP POLICY IF EXISTS "photo_comparisons_delete_policy" ON public.photo_comparisons;
DROP POLICY IF EXISTS "photo_comparisons_insert_policy" ON public.photo_comparisons;
DROP POLICY IF EXISTS "photo_comparisons_select_policy" ON public.photo_comparisons;
DROP POLICY IF EXISTS "photo_comparisons_update_policy" ON public.photo_comparisons;
CREATE POLICY "photo_comparisons_delete_policy" ON public.photo_comparisons FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "photo_comparisons_insert_policy" ON public.photo_comparisons FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "photo_comparisons_select_policy" ON public.photo_comparisons FOR SELECT USING (((( SELECT auth.uid() AS uid) = user_id) OR (visibility = 'public'::text)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "photo_comparisons_update_policy" ON public.photo_comparisons FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: plan_previews
DROP POLICY IF EXISTS "plan_previews_service_policy" ON public.plan_previews;
DROP POLICY IF EXISTS "plan_previews_insert_policy" ON public.plan_previews;
DROP POLICY IF EXISTS "plan_previews_user_policy" ON public.plan_previews;
DROP POLICY IF EXISTS "plan_previews_update_policy" ON public.plan_previews;
CREATE POLICY "plan_previews_delete_policy" ON public.plan_previews FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "plan_previews_insert_policy" ON public.plan_previews FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "plan_previews_select_policy" ON public.plan_previews FOR SELECT USING (((( SELECT auth.uid() AS uid) = user_id) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "plan_previews_update_policy" ON public.plan_previews FOR UPDATE USING (((( SELECT auth.uid() AS uid) = user_id) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK (((( SELECT auth.uid() AS uid) = user_id) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));

-- Table: preference_impact_log
DROP POLICY IF EXISTS "Service role has full access to preference_impact_log" ON public.preference_impact_log;
DROP POLICY IF EXISTS "Users can view their own preference impact logs" ON public.preference_impact_log;
CREATE POLICY "preference_impact_log_delete_policy" ON public.preference_impact_log FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "preference_impact_log_insert_policy" ON public.preference_impact_log FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "preference_impact_log_select_policy" ON public.preference_impact_log FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "preference_impact_log_update_policy" ON public.preference_impact_log FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: program_history
DROP POLICY IF EXISTS "Service role has full access to program history" ON public.program_history;
DROP POLICY IF EXISTS "Users can delete own program history" ON public.program_history;
DROP POLICY IF EXISTS "Users can insert own program history" ON public.program_history;
DROP POLICY IF EXISTS "Users can view own program history" ON public.program_history;
DROP POLICY IF EXISTS "Users can update own program history" ON public.program_history;
CREATE POLICY "program_history_delete_policy" ON public.program_history FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "program_history_insert_policy" ON public.program_history FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "program_history_select_policy" ON public.program_history FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "program_history_update_policy" ON public.program_history FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: progress_photos
DROP POLICY IF EXISTS "progress_photos_service_policy" ON public.progress_photos;
DROP POLICY IF EXISTS "progress_photos_delete_policy" ON public.progress_photos;
DROP POLICY IF EXISTS "progress_photos_insert_policy" ON public.progress_photos;
DROP POLICY IF EXISTS "progress_photos_select_policy" ON public.progress_photos;
DROP POLICY IF EXISTS "progress_photos_update_policy" ON public.progress_photos;
CREATE POLICY "progress_photos_delete_policy" ON public.progress_photos FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "progress_photos_insert_policy" ON public.progress_photos FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "progress_photos_select_policy" ON public.progress_photos FOR SELECT USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "progress_photos_update_policy" ON public.progress_photos FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: readiness_scores
DROP POLICY IF EXISTS "readiness_scores_service_policy" ON public.readiness_scores;
DROP POLICY IF EXISTS "readiness_scores_insert_policy" ON public.readiness_scores;
DROP POLICY IF EXISTS "readiness_scores_select_policy" ON public.readiness_scores;
DROP POLICY IF EXISTS "readiness_scores_update_policy" ON public.readiness_scores;
CREATE POLICY "readiness_scores_delete_policy" ON public.readiness_scores FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "readiness_scores_insert_policy" ON public.readiness_scores FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "readiness_scores_select_policy" ON public.readiness_scores FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "readiness_scores_update_policy" ON public.readiness_scores FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: refund_requests
DROP POLICY IF EXISTS "Service role full access refund requests" ON public.refund_requests;
DROP POLICY IF EXISTS "Users can create own refund requests" ON public.refund_requests;
DROP POLICY IF EXISTS "Users can read own refund requests" ON public.refund_requests;
CREATE POLICY "refund_requests_delete_policy" ON public.refund_requests FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "refund_requests_insert_policy" ON public.refund_requests FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "refund_requests_select_policy" ON public.refund_requests FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "refund_requests_update_policy" ON public.refund_requests FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: rest_intervals
DROP POLICY IF EXISTS "Service role can manage rest intervals" ON public.rest_intervals;
DROP POLICY IF EXISTS "Users can insert their own rest intervals" ON public.rest_intervals;
DROP POLICY IF EXISTS "Users can view their own rest intervals" ON public.rest_intervals;
CREATE POLICY "rest_intervals_delete_policy" ON public.rest_intervals FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "rest_intervals_insert_policy" ON public.rest_intervals FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "rest_intervals_select_policy" ON public.rest_intervals FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "rest_intervals_update_policy" ON public.rest_intervals FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: retention_offers_accepted
DROP POLICY IF EXISTS "Service role full access to retention_offers_accepted" ON public.retention_offers_accepted;
DROP POLICY IF EXISTS "Users can insert own retention offers" ON public.retention_offers_accepted;
DROP POLICY IF EXISTS "Users can view own retention offers" ON public.retention_offers_accepted;
CREATE POLICY "retention_offers_accepted_delete_policy" ON public.retention_offers_accepted FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "retention_offers_accepted_insert_policy" ON public.retention_offers_accepted FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "retention_offers_accepted_select_policy" ON public.retention_offers_accepted FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "retention_offers_accepted_update_policy" ON public.retention_offers_accepted FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: screen_views
DROP POLICY IF EXISTS "Service role full access screen views" ON public.screen_views;
DROP POLICY IF EXISTS "Users can insert own screen views" ON public.screen_views;
DROP POLICY IF EXISTS "Users can read own screen views" ON public.screen_views;
CREATE POLICY "screen_views_delete_policy" ON public.screen_views FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "screen_views_insert_policy" ON public.screen_views FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "screen_views_select_policy" ON public.screen_views FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "screen_views_update_policy" ON public.screen_views FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: set_rep_accuracy
DROP POLICY IF EXISTS "Service role can manage all rep accuracy" ON public.set_rep_accuracy;
DROP POLICY IF EXISTS "Users can delete own rep accuracy" ON public.set_rep_accuracy;
DROP POLICY IF EXISTS "Users can insert own rep accuracy" ON public.set_rep_accuracy;
DROP POLICY IF EXISTS "Users can view own rep accuracy" ON public.set_rep_accuracy;
DROP POLICY IF EXISTS "Users can update own rep accuracy" ON public.set_rep_accuracy;
CREATE POLICY "set_rep_accuracy_delete_policy" ON public.set_rep_accuracy FOR DELETE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "set_rep_accuracy_insert_policy" ON public.set_rep_accuracy FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "set_rep_accuracy_select_policy" ON public.set_rep_accuracy FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "set_rep_accuracy_update_policy" ON public.set_rep_accuracy FOR UPDATE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));

-- Table: social_notifications
DROP POLICY IF EXISTS "Service role can manage notifications" ON public.social_notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.social_notifications;
DROP POLICY IF EXISTS "Users can view own notifications" ON public.social_notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.social_notifications;
CREATE POLICY "social_notifications_delete_policy" ON public.social_notifications FOR DELETE USING (((( SELECT auth.uid() AS uid))::text = (user_id)::text) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "social_notifications_insert_policy" ON public.social_notifications FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "social_notifications_select_policy" ON public.social_notifications FOR SELECT USING (((( SELECT auth.uid() AS uid))::text = (user_id)::text) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "social_notifications_update_policy" ON public.social_notifications FOR UPDATE USING (((( SELECT auth.uid() AS uid))::text = (user_id)::text) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK (((( SELECT auth.uid() AS uid))::text = (user_id)::text) OR ((select auth.role()) = 'service_role'::text));

-- Table: staple_exercises
DROP POLICY IF EXISTS "Service role has full access to staple_exercises" ON public.staple_exercises;
DROP POLICY IF EXISTS "Users can delete their own staple exercises" ON public.staple_exercises;
DROP POLICY IF EXISTS "Users can insert their own staple exercises" ON public.staple_exercises;
DROP POLICY IF EXISTS "Users can view their own staple exercises" ON public.staple_exercises;
CREATE POLICY "staple_exercises_delete_policy" ON public.staple_exercises FOR DELETE USING ((( SELECT auth.uid() AS uid) IN ( SELECT users.auth_id
   FROM users
  WHERE (users.id = staple_exercises.user_id))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "staple_exercises_insert_policy" ON public.staple_exercises FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) IN ( SELECT users.auth_id
   FROM users
  WHERE (users.id = staple_exercises.user_id))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "staple_exercises_select_policy" ON public.staple_exercises FOR SELECT USING ((( SELECT auth.uid() AS uid) IN ( SELECT users.auth_id
   FROM users
  WHERE (users.id = staple_exercises.user_id))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "staple_exercises_update_policy" ON public.staple_exercises FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: strength_scores
DROP POLICY IF EXISTS "strength_scores_service_policy" ON public.strength_scores;
DROP POLICY IF EXISTS "strength_scores_insert_policy" ON public.strength_scores;
DROP POLICY IF EXISTS "strength_scores_select_policy" ON public.strength_scores;
DROP POLICY IF EXISTS "strength_scores_update_policy" ON public.strength_scores;
CREATE POLICY "strength_scores_delete_policy" ON public.strength_scores FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "strength_scores_insert_policy" ON public.strength_scores FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "strength_scores_select_policy" ON public.strength_scores FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "strength_scores_update_policy" ON public.strength_scores FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: subscription_discounts
DROP POLICY IF EXISTS "Service role full access to subscription_discounts" ON public.subscription_discounts;
DROP POLICY IF EXISTS "Users can insert own subscription discounts" ON public.subscription_discounts;
DROP POLICY IF EXISTS "Users can view own subscription discounts" ON public.subscription_discounts;
DROP POLICY IF EXISTS "Users can update own subscription discounts" ON public.subscription_discounts;
CREATE POLICY "subscription_discounts_delete_policy" ON public.subscription_discounts FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_discounts_insert_policy" ON public.subscription_discounts FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_discounts_select_policy" ON public.subscription_discounts FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_discounts_update_policy" ON public.subscription_discounts FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: subscription_history
DROP POLICY IF EXISTS "Service role full access history" ON public.subscription_history;
DROP POLICY IF EXISTS "Users can read own subscription history" ON public.subscription_history;
CREATE POLICY "subscription_history_delete_policy" ON public.subscription_history FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_history_insert_policy" ON public.subscription_history FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_history_select_policy" ON public.subscription_history FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_history_update_policy" ON public.subscription_history FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: subscription_pause_history
DROP POLICY IF EXISTS "Service role pause history" ON public.subscription_pause_history;
DROP POLICY IF EXISTS "Users can read own pause history" ON public.subscription_pause_history;
CREATE POLICY "subscription_pause_history_delete_policy" ON public.subscription_pause_history FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_pause_history_insert_policy" ON public.subscription_pause_history FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_pause_history_select_policy" ON public.subscription_pause_history FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_pause_history_update_policy" ON public.subscription_pause_history FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: subscription_pauses
DROP POLICY IF EXISTS "Service role full access to subscription_pauses" ON public.subscription_pauses;
DROP POLICY IF EXISTS "Users can insert own subscription pauses" ON public.subscription_pauses;
DROP POLICY IF EXISTS "Users can view own subscription pauses" ON public.subscription_pauses;
DROP POLICY IF EXISTS "Users can update own subscription pauses" ON public.subscription_pauses;
CREATE POLICY "subscription_pauses_delete_policy" ON public.subscription_pauses FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_pauses_insert_policy" ON public.subscription_pauses FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_pauses_select_policy" ON public.subscription_pauses FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_pauses_update_policy" ON public.subscription_pauses FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: subscription_price_history
DROP POLICY IF EXISTS "Service role full access price history" ON public.subscription_price_history;
DROP POLICY IF EXISTS "Users can read own price history" ON public.subscription_price_history;
CREATE POLICY "subscription_price_history_delete_policy" ON public.subscription_price_history FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_price_history_insert_policy" ON public.subscription_price_history FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_price_history_select_policy" ON public.subscription_price_history FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "subscription_price_history_update_policy" ON public.subscription_price_history FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: support_ticket_messages
DROP POLICY IF EXISTS "Service role can add messages" ON public.support_ticket_messages;
DROP POLICY IF EXISTS "Users can add messages to own tickets" ON public.support_ticket_messages;
DROP POLICY IF EXISTS "Service role can view all messages" ON public.support_ticket_messages;
DROP POLICY IF EXISTS "Users can view messages on own tickets" ON public.support_ticket_messages;
CREATE POLICY "support_ticket_messages_insert_policy" ON public.support_ticket_messages FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM support_tickets
  WHERE ((support_tickets.id = support_ticket_messages.ticket_id) AND (support_tickets.user_id = ( SELECT auth.uid() AS uid))))) AND (sender = 'user'::text) AND (is_internal = false)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "support_ticket_messages_select_policy" ON public.support_ticket_messages FOR SELECT USING (((EXISTS ( SELECT 1
   FROM support_tickets
  WHERE ((support_tickets.id = support_ticket_messages.ticket_id) AND (support_tickets.user_id = ( SELECT auth.uid() AS uid))))) AND (is_internal = false)) OR ((select auth.role()) = 'service_role'::text));

-- Table: support_tickets
DROP POLICY IF EXISTS "Users can create own tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Service role can view all tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Users can view own tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Service role can update all tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Users can update own tickets" ON public.support_tickets;
CREATE POLICY "support_tickets_insert_policy" ON public.support_tickets FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "support_tickets_select_policy" ON public.support_tickets FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "support_tickets_update_policy" ON public.support_tickets FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: try_workout_sessions
DROP POLICY IF EXISTS "try_workout_service_policy" ON public.try_workout_sessions;
DROP POLICY IF EXISTS "try_workout_insert_policy" ON public.try_workout_sessions;
DROP POLICY IF EXISTS "try_workout_user_policy" ON public.try_workout_sessions;
DROP POLICY IF EXISTS "try_workout_update_policy" ON public.try_workout_sessions;
CREATE POLICY "try_workout_sessions_delete_policy" ON public.try_workout_sessions FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "try_workout_sessions_insert_policy" ON public.try_workout_sessions FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "try_workout_sessions_select_policy" ON public.try_workout_sessions FOR SELECT USING (((( SELECT auth.uid() AS uid) = user_id) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "try_workout_sessions_update_policy" ON public.try_workout_sessions FOR UPDATE USING (((( SELECT auth.uid() AS uid) = user_id) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK (((( SELECT auth.uid() AS uid) = user_id) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));

-- Table: user_achievements
DROP POLICY IF EXISTS "user_achievements_service_policy" ON public.user_achievements;
DROP POLICY IF EXISTS "user_achievements_select_policy" ON public.user_achievements;
CREATE POLICY "user_achievements_delete_policy" ON public.user_achievements FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_achievements_insert_policy" ON public.user_achievements FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_achievements_select_policy" ON public.user_achievements FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_achievements_update_policy" ON public.user_achievements FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: user_context_logs
DROP POLICY IF EXISTS "user_context_logs_service_policy" ON public.user_context_logs;
DROP POLICY IF EXISTS "user_context_logs_insert_policy" ON public.user_context_logs;
DROP POLICY IF EXISTS "user_context_logs_select_policy" ON public.user_context_logs;
CREATE POLICY "user_context_logs_delete_policy" ON public.user_context_logs FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_context_logs_insert_policy" ON public.user_context_logs FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_context_logs_select_policy" ON public.user_context_logs FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_context_logs_update_policy" ON public.user_context_logs FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: user_events
DROP POLICY IF EXISTS "Service role full access events" ON public.user_events;
DROP POLICY IF EXISTS "Users can insert own events" ON public.user_events;
DROP POLICY IF EXISTS "Users can read own events" ON public.user_events;
CREATE POLICY "user_events_delete_policy" ON public.user_events FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_events_insert_policy" ON public.user_events FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_events_select_policy" ON public.user_events FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_events_update_policy" ON public.user_events FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: user_insights
DROP POLICY IF EXISTS "user_insights_service_policy" ON public.user_insights;
DROP POLICY IF EXISTS "user_insights_select_policy" ON public.user_insights;
CREATE POLICY "user_insights_delete_policy" ON public.user_insights FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_insights_insert_policy" ON public.user_insights FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_insights_select_policy" ON public.user_insights FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_insights_update_policy" ON public.user_insights FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: user_neat_achievements
DROP POLICY IF EXISTS "user_neat_achievements_service_policy" ON public.user_neat_achievements;
DROP POLICY IF EXISTS "user_neat_achievements_delete_policy" ON public.user_neat_achievements;
DROP POLICY IF EXISTS "user_neat_achievements_insert_policy" ON public.user_neat_achievements;
DROP POLICY IF EXISTS "user_neat_achievements_select_policy" ON public.user_neat_achievements;
DROP POLICY IF EXISTS "user_neat_achievements_update_policy" ON public.user_neat_achievements;
CREATE POLICY "user_neat_achievements_delete_policy" ON public.user_neat_achievements FOR DELETE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_neat_achievements_insert_policy" ON public.user_neat_achievements FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_neat_achievements_select_policy" ON public.user_neat_achievements FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_neat_achievements_update_policy" ON public.user_neat_achievements FOR UPDATE USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));

-- Table: user_sessions
DROP POLICY IF EXISTS "Service role full access sessions" ON public.user_sessions;
DROP POLICY IF EXISTS "Users can insert own sessions" ON public.user_sessions;
DROP POLICY IF EXISTS "Users can read own sessions" ON public.user_sessions;
CREATE POLICY "user_sessions_delete_policy" ON public.user_sessions FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_sessions_insert_policy" ON public.user_sessions FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR (user_id IS NULL)) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_sessions_select_policy" ON public.user_sessions FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_sessions_update_policy" ON public.user_sessions FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: user_settings
DROP POLICY IF EXISTS "user_settings_service_policy" ON public.user_settings;
DROP POLICY IF EXISTS "user_settings_insert_policy" ON public.user_settings;
DROP POLICY IF EXISTS "user_settings_select_policy" ON public.user_settings;
DROP POLICY IF EXISTS "user_settings_update_policy" ON public.user_settings;
CREATE POLICY "user_settings_delete_policy" ON public.user_settings FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_settings_insert_policy" ON public.user_settings FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_settings_select_policy" ON public.user_settings FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_settings_update_policy" ON public.user_settings FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: user_streaks
DROP POLICY IF EXISTS "user_streaks_service_policy" ON public.user_streaks;
DROP POLICY IF EXISTS "user_streaks_select_policy" ON public.user_streaks;
CREATE POLICY "user_streaks_delete_policy" ON public.user_streaks FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_streaks_insert_policy" ON public.user_streaks FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_streaks_select_policy" ON public.user_streaks FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_streaks_update_policy" ON public.user_streaks FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: user_subscriptions
DROP POLICY IF EXISTS "Service role full access subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can read own subscription" ON public.user_subscriptions;
CREATE POLICY "user_subscriptions_delete_policy" ON public.user_subscriptions FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_subscriptions_insert_policy" ON public.user_subscriptions FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_subscriptions_select_policy" ON public.user_subscriptions FOR SELECT USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = ( SELECT auth.uid() AS uid)))) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "user_subscriptions_update_policy" ON public.user_subscriptions FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: weekly_program_progress
DROP POLICY IF EXISTS "weekly_progress_service_policy" ON public.weekly_program_progress;
DROP POLICY IF EXISTS "weekly_progress_select_policy" ON public.weekly_program_progress;
CREATE POLICY "weekly_program_progress_delete_policy" ON public.weekly_program_progress FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "weekly_program_progress_insert_policy" ON public.weekly_program_progress FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "weekly_program_progress_select_policy" ON public.weekly_program_progress FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "weekly_program_progress_update_policy" ON public.weekly_program_progress FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: weekly_summaries
DROP POLICY IF EXISTS "weekly_summaries_service_policy" ON public.weekly_summaries;
DROP POLICY IF EXISTS "weekly_summaries_select_policy" ON public.weekly_summaries;
CREATE POLICY "weekly_summaries_delete_policy" ON public.weekly_summaries FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "weekly_summaries_insert_policy" ON public.weekly_summaries FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "weekly_summaries_select_policy" ON public.weekly_summaries FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "weekly_summaries_update_policy" ON public.weekly_summaries FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: window_mode_logs
DROP POLICY IF EXISTS "Service role can manage all window mode logs" ON public.window_mode_logs;
DROP POLICY IF EXISTS "Users can insert own window mode logs" ON public.window_mode_logs;
DROP POLICY IF EXISTS "Users can view own window mode logs" ON public.window_mode_logs;
CREATE POLICY "window_mode_logs_delete_policy" ON public.window_mode_logs FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "window_mode_logs_insert_policy" ON public.window_mode_logs FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "window_mode_logs_select_policy" ON public.window_mode_logs FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "window_mode_logs_update_policy" ON public.window_mode_logs FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: workout_exits
DROP POLICY IF EXISTS "Service role can manage workout exits" ON public.workout_exits;
DROP POLICY IF EXISTS "workout_exits_service_policy" ON public.workout_exits;
DROP POLICY IF EXISTS "Users can insert their own workout exits" ON public.workout_exits;
DROP POLICY IF EXISTS "workout_exits_insert_policy" ON public.workout_exits;
DROP POLICY IF EXISTS "Users can view their own workout exits" ON public.workout_exits;
DROP POLICY IF EXISTS "workout_exits_select_policy" ON public.workout_exits;
CREATE POLICY "workout_exits_delete_policy" ON public.workout_exits FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_exits_insert_policy" ON public.workout_exits FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_exits_select_policy" ON public.workout_exits FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_exits_update_policy" ON public.workout_exits FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: workout_feedback
DROP POLICY IF EXISTS "workout_feedback_service_policy" ON public.workout_feedback;
DROP POLICY IF EXISTS "workout_feedback_insert_policy" ON public.workout_feedback;
DROP POLICY IF EXISTS "workout_feedback_select_policy" ON public.workout_feedback;
DROP POLICY IF EXISTS "workout_feedback_update_policy" ON public.workout_feedback;
CREATE POLICY "workout_feedback_delete_policy" ON public.workout_feedback FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_feedback_insert_policy" ON public.workout_feedback FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_feedback_select_policy" ON public.workout_feedback FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_feedback_update_policy" ON public.workout_feedback FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: workout_history_imports
DROP POLICY IF EXISTS "Service role has full access to workout_history_imports" ON public.workout_history_imports;
DROP POLICY IF EXISTS "Users can delete their own imported workout history" ON public.workout_history_imports;
DROP POLICY IF EXISTS "Users can insert their own imported workout history" ON public.workout_history_imports;
DROP POLICY IF EXISTS "Users can view their own imported workout history" ON public.workout_history_imports;
DROP POLICY IF EXISTS "Users can update their own imported workout history" ON public.workout_history_imports;
CREATE POLICY "workout_history_imports_delete_policy" ON public.workout_history_imports FOR DELETE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_history_imports_insert_policy" ON public.workout_history_imports FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_history_imports_select_policy" ON public.workout_history_imports FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_history_imports_update_policy" ON public.workout_history_imports FOR UPDATE USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));

-- Table: workout_performance_summary
DROP POLICY IF EXISTS "Service role can manage all workout performance" ON public.workout_performance_summary;
DROP POLICY IF EXISTS "Users can insert own workout performance" ON public.workout_performance_summary;
DROP POLICY IF EXISTS "Users can view own workout performance" ON public.workout_performance_summary;
CREATE POLICY "workout_performance_summary_delete_policy" ON public.workout_performance_summary FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_performance_summary_insert_policy" ON public.workout_performance_summary FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_performance_summary_select_policy" ON public.workout_performance_summary FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_performance_summary_update_policy" ON public.workout_performance_summary FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Table: workout_summaries
DROP POLICY IF EXISTS "workout_summaries_service_policy" ON public.workout_summaries;
DROP POLICY IF EXISTS "workout_summaries_select_policy" ON public.workout_summaries;
CREATE POLICY "workout_summaries_delete_policy" ON public.workout_summaries FOR DELETE USING (((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_summaries_insert_policy" ON public.workout_summaries FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_summaries_select_policy" ON public.workout_summaries FOR SELECT USING ((( SELECT auth.uid() AS uid) = user_id) OR ((select auth.role()) = 'service_role'::text));
CREATE POLICY "workout_summaries_update_policy" ON public.workout_summaries FOR UPDATE USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

COMMIT;

-- Total tables consolidated: 71