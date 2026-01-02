-- RLS Policy Performance Fix
-- Wrapping auth.uid() and auth.role() in (select ...) to prevent per-row evaluation
-- Generated automatically

BEGIN;

-- Fix policy: a1c_records_delete on a1c_records
DROP POLICY IF EXISTS "a1c_records_delete" ON public.a1c_records;
CREATE POLICY "a1c_records_delete" ON public.a1c_records FOR DELETE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = a1c_records.user_id))));

-- Fix policy: a1c_records_insert on a1c_records
DROP POLICY IF EXISTS "a1c_records_insert" ON public.a1c_records;
CREATE POLICY "a1c_records_insert" ON public.a1c_records FOR INSERT WITH CHECK (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = a1c_records.user_id))));

-- Fix policy: a1c_records_select on a1c_records
DROP POLICY IF EXISTS "a1c_records_select" ON public.a1c_records;
CREATE POLICY "a1c_records_select" ON public.a1c_records FOR SELECT USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = a1c_records.user_id))));

-- Fix policy: a1c_records_update on a1c_records
DROP POLICY IF EXISTS "a1c_records_update" ON public.a1c_records;
CREATE POLICY "a1c_records_update" ON public.a1c_records FOR UPDATE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = a1c_records.user_id))));

-- Fix policy: Users can create their own comments on activity_comments
DROP POLICY IF EXISTS "Users can create their own comments" ON public.activity_comments;
CREATE POLICY "Users can create their own comments" ON public.activity_comments FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: Users can delete their own comments on activity_comments
DROP POLICY IF EXISTS "Users can delete their own comments" ON public.activity_comments;
CREATE POLICY "Users can delete their own comments" ON public.activity_comments FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can update their own comments on activity_comments
DROP POLICY IF EXISTS "Users can update their own comments" ON public.activity_comments;
CREATE POLICY "Users can update their own comments" ON public.activity_comments FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can create their own activities on activity_feed
DROP POLICY IF EXISTS "Users can create their own activities" ON public.activity_feed;
CREATE POLICY "Users can create their own activities" ON public.activity_feed FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: Users can delete their own activities on activity_feed
DROP POLICY IF EXISTS "Users can delete their own activities" ON public.activity_feed;
CREATE POLICY "Users can delete their own activities" ON public.activity_feed FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can update their own activities on activity_feed
DROP POLICY IF EXISTS "Users can update their own activities" ON public.activity_feed;
CREATE POLICY "Users can update their own activities" ON public.activity_feed FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can view public and friends' activities on activity_feed
DROP POLICY IF EXISTS "Users can view public and friends' activities" ON public.activity_feed;
CREATE POLICY "Users can view public and friends' activities" ON public.activity_feed FOR SELECT USING ((((visibility)::text = 'public'::text) OR (user_id = (select auth.uid())) OR (((visibility)::text = 'friends'::text) AND (EXISTS ( SELECT 1 FROM user_connections WHERE ((user_connections.follower_id = (select auth.uid())) AND (user_connections.following_id = activity_feed.user_id)))))));

-- Fix policy: Users can create their own reactions on activity_reactions
DROP POLICY IF EXISTS "Users can create their own reactions" ON public.activity_reactions;
CREATE POLICY "Users can create their own reactions" ON public.activity_reactions FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: Users can delete their own reactions on activity_reactions
DROP POLICY IF EXISTS "Users can delete their own reactions" ON public.activity_reactions;
CREATE POLICY "Users can delete their own reactions" ON public.activity_reactions FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: adaptive_nutrition_calculations_insert_policy on adaptive_nutrition_calculations
DROP POLICY IF EXISTS "adaptive_nutrition_calculations_insert_policy" ON public.adaptive_nutrition_calculations;
CREATE POLICY "adaptive_nutrition_calculations_insert_policy" ON public.adaptive_nutrition_calculations FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: adaptive_nutrition_calculations_select_policy on adaptive_nutrition_calculations
DROP POLICY IF EXISTS "adaptive_nutrition_calculations_select_policy" ON public.adaptive_nutrition_calculations;
CREATE POLICY "adaptive_nutrition_calculations_select_policy" ON public.adaptive_nutrition_calculations FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: ai_settings_history_policy on ai_settings_history
DROP POLICY IF EXISTS "ai_settings_history_policy" ON public.ai_settings_history;
CREATE POLICY "ai_settings_history_policy" ON public.ai_settings_history FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: Service role full access errors on app_errors
DROP POLICY IF EXISTS "Service role full access errors" ON public.app_errors;
CREATE POLICY "Service role full access errors" ON public.app_errors FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own errors on app_errors
DROP POLICY IF EXISTS "Users can insert own errors" ON public.app_errors;
CREATE POLICY "Users can insert own errors" ON public.app_errors FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))) OR (user_id IS NULL)));

-- Fix policy: Users can read own errors on app_errors
DROP POLICY IF EXISTS "Users can read own errors" ON public.app_errors;
CREATE POLICY "Users can read own errors" ON public.app_errors FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: app_tour_sessions_insert_own on app_tour_sessions
DROP POLICY IF EXISTS "app_tour_sessions_insert_own" ON public.app_tour_sessions;
CREATE POLICY "app_tour_sessions_insert_own" ON public.app_tour_sessions FOR INSERT  TO authenticated WITH CHECK ((((select auth.uid()) = user_id) OR (user_id IS NULL)));

-- Fix policy: app_tour_sessions_select_own on app_tour_sessions
DROP POLICY IF EXISTS "app_tour_sessions_select_own" ON public.app_tour_sessions;
CREATE POLICY "app_tour_sessions_select_own" ON public.app_tour_sessions FOR SELECT  TO authenticated USING ((((select auth.uid()) = user_id) OR (user_id IS NULL)));

-- Fix policy: app_tour_sessions_update_own on app_tour_sessions
DROP POLICY IF EXISTS "app_tour_sessions_update_own" ON public.app_tour_sessions;
CREATE POLICY "app_tour_sessions_update_own" ON public.app_tour_sessions FOR UPDATE  TO authenticated USING ((((select auth.uid()) = user_id) OR (user_id IS NULL))) WITH CHECK ((((select auth.uid()) = user_id) OR (user_id IS NULL)));

-- Fix policy: app_tour_step_events_insert_own on app_tour_step_events
DROP POLICY IF EXISTS "app_tour_step_events_insert_own" ON public.app_tour_step_events;
CREATE POLICY "app_tour_step_events_insert_own" ON public.app_tour_step_events FOR INSERT  TO authenticated WITH CHECK ((EXISTS ( SELECT 1 FROM app_tour_sessions WHERE ((app_tour_sessions.id = app_tour_step_events.tour_session_id) AND ((app_tour_sessions.user_id = (select auth.uid())) OR (app_tour_sessions.user_id IS NULL))))));

-- Fix policy: app_tour_step_events_select_own on app_tour_step_events
DROP POLICY IF EXISTS "app_tour_step_events_select_own" ON public.app_tour_step_events;
CREATE POLICY "app_tour_step_events_select_own" ON public.app_tour_step_events FOR SELECT  TO authenticated USING ((EXISTS ( SELECT 1 FROM app_tour_sessions WHERE ((app_tour_sessions.id = app_tour_step_events.tour_session_id) AND ((app_tour_sessions.user_id = (select auth.uid())) OR (app_tour_sessions.user_id IS NULL))))));

-- Fix policy: Service role has full access to audio preferences on audio_preferences
DROP POLICY IF EXISTS "Service role has full access to audio preferences" ON public.audio_preferences;
CREATE POLICY "Service role has full access to audio preferences" ON public.audio_preferences FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can delete own audio preferences on audio_preferences
DROP POLICY IF EXISTS "Users can delete own audio preferences" ON public.audio_preferences;
CREATE POLICY "Users can delete own audio preferences" ON public.audio_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own audio preferences on audio_preferences
DROP POLICY IF EXISTS "Users can insert own audio preferences" ON public.audio_preferences;
CREATE POLICY "Users can insert own audio preferences" ON public.audio_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own audio preferences on audio_preferences
DROP POLICY IF EXISTS "Users can update own audio preferences" ON public.audio_preferences;
CREATE POLICY "Users can update own audio preferences" ON public.audio_preferences FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own audio preferences on audio_preferences
DROP POLICY IF EXISTS "Users can view own audio preferences" ON public.audio_preferences;
CREATE POLICY "Users can view own audio preferences" ON public.audio_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: avoided_exercises_delete_policy on avoided_exercises
DROP POLICY IF EXISTS "avoided_exercises_delete_policy" ON public.avoided_exercises;
CREATE POLICY "avoided_exercises_delete_policy" ON public.avoided_exercises FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: avoided_exercises_insert_policy on avoided_exercises
DROP POLICY IF EXISTS "avoided_exercises_insert_policy" ON public.avoided_exercises;
CREATE POLICY "avoided_exercises_insert_policy" ON public.avoided_exercises FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: avoided_exercises_select_policy on avoided_exercises
DROP POLICY IF EXISTS "avoided_exercises_select_policy" ON public.avoided_exercises;
CREATE POLICY "avoided_exercises_select_policy" ON public.avoided_exercises FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: avoided_exercises_update_policy on avoided_exercises
DROP POLICY IF EXISTS "avoided_exercises_update_policy" ON public.avoided_exercises;
CREATE POLICY "avoided_exercises_update_policy" ON public.avoided_exercises FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: avoided_muscles_delete_policy on avoided_muscles
DROP POLICY IF EXISTS "avoided_muscles_delete_policy" ON public.avoided_muscles;
CREATE POLICY "avoided_muscles_delete_policy" ON public.avoided_muscles FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: avoided_muscles_insert_policy on avoided_muscles
DROP POLICY IF EXISTS "avoided_muscles_insert_policy" ON public.avoided_muscles;
CREATE POLICY "avoided_muscles_insert_policy" ON public.avoided_muscles FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: avoided_muscles_select_policy on avoided_muscles
DROP POLICY IF EXISTS "avoided_muscles_select_policy" ON public.avoided_muscles;
CREATE POLICY "avoided_muscles_select_policy" ON public.avoided_muscles FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: avoided_muscles_update_policy on avoided_muscles
DROP POLICY IF EXISTS "avoided_muscles_update_policy" ON public.avoided_muscles;
CREATE POLICY "avoided_muscles_update_policy" ON public.avoided_muscles FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Service role full access billing notifications on billing_notifications
DROP POLICY IF EXISTS "Service role full access billing notifications" ON public.billing_notifications;
CREATE POLICY "Service role full access billing notifications" ON public.billing_notifications FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can read own billing notifications on billing_notifications
DROP POLICY IF EXISTS "Users can read own billing notifications" ON public.billing_notifications;
CREATE POLICY "Users can read own billing notifications" ON public.billing_notifications FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: body_measurements_delete_policy on body_measurements
DROP POLICY IF EXISTS "body_measurements_delete_policy" ON public.body_measurements;
CREATE POLICY "body_measurements_delete_policy" ON public.body_measurements FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: body_measurements_insert_policy on body_measurements
DROP POLICY IF EXISTS "body_measurements_insert_policy" ON public.body_measurements;
CREATE POLICY "body_measurements_insert_policy" ON public.body_measurements FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: body_measurements_select_policy on body_measurements
DROP POLICY IF EXISTS "body_measurements_select_policy" ON public.body_measurements;
CREATE POLICY "body_measurements_select_policy" ON public.body_measurements FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: body_measurements_service_policy on body_measurements
DROP POLICY IF EXISTS "body_measurements_service_policy" ON public.body_measurements;
CREATE POLICY "body_measurements_service_policy" ON public.body_measurements FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: body_measurements_update_policy on body_measurements
DROP POLICY IF EXISTS "body_measurements_update_policy" ON public.body_measurements;
CREATE POLICY "body_measurements_update_policy" ON public.body_measurements FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own calibration workouts on calibration_workouts
DROP POLICY IF EXISTS "Users can delete own calibration workouts" ON public.calibration_workouts;
CREATE POLICY "Users can delete own calibration workouts" ON public.calibration_workouts FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own calibration workouts on calibration_workouts
DROP POLICY IF EXISTS "Users can insert own calibration workouts" ON public.calibration_workouts;
CREATE POLICY "Users can insert own calibration workouts" ON public.calibration_workouts FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own calibration workouts on calibration_workouts
DROP POLICY IF EXISTS "Users can update own calibration workouts" ON public.calibration_workouts;
CREATE POLICY "Users can update own calibration workouts" ON public.calibration_workouts FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own calibration workouts on calibration_workouts
DROP POLICY IF EXISTS "Users can view own calibration workouts" ON public.calibration_workouts;
CREATE POLICY "Users can view own calibration workouts" ON public.calibration_workouts FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Service role full access to cancellation_feedback on cancellation_feedback
DROP POLICY IF EXISTS "Service role full access to cancellation_feedback" ON public.cancellation_feedback;
CREATE POLICY "Service role full access to cancellation_feedback" ON public.cancellation_feedback FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own cancellation feedback on cancellation_feedback
DROP POLICY IF EXISTS "Users can insert own cancellation feedback" ON public.cancellation_feedback;
CREATE POLICY "Users can insert own cancellation feedback" ON public.cancellation_feedback FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Service role cancellation requests on cancellation_requests
DROP POLICY IF EXISTS "Service role cancellation requests" ON public.cancellation_requests;
CREATE POLICY "Service role cancellation requests" ON public.cancellation_requests FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can read own cancellation requests on cancellation_requests
DROP POLICY IF EXISTS "Users can read own cancellation requests" ON public.cancellation_requests;
CREATE POLICY "Users can read own cancellation requests" ON public.cancellation_requests FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: carb_entries_delete on carb_entries
DROP POLICY IF EXISTS "carb_entries_delete" ON public.carb_entries;
CREATE POLICY "carb_entries_delete" ON public.carb_entries FOR DELETE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = carb_entries.user_id))));

-- Fix policy: carb_entries_insert on carb_entries
DROP POLICY IF EXISTS "carb_entries_insert" ON public.carb_entries;
CREATE POLICY "carb_entries_insert" ON public.carb_entries FOR INSERT WITH CHECK (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = carb_entries.user_id))));

-- Fix policy: carb_entries_select on carb_entries
DROP POLICY IF EXISTS "carb_entries_select" ON public.carb_entries;
CREATE POLICY "carb_entries_select" ON public.carb_entries FOR SELECT USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = carb_entries.user_id))));

-- Fix policy: carb_entries_update on carb_entries
DROP POLICY IF EXISTS "carb_entries_update" ON public.carb_entries;
CREATE POLICY "carb_entries_update" ON public.carb_entries FOR UPDATE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = carb_entries.user_id))));

-- Fix policy: Users can delete own cardio metrics on cardio_metrics
DROP POLICY IF EXISTS "Users can delete own cardio metrics" ON public.cardio_metrics;
CREATE POLICY "Users can delete own cardio metrics" ON public.cardio_metrics FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own cardio metrics on cardio_metrics
DROP POLICY IF EXISTS "Users can insert own cardio metrics" ON public.cardio_metrics;
CREATE POLICY "Users can insert own cardio metrics" ON public.cardio_metrics FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own cardio metrics on cardio_metrics
DROP POLICY IF EXISTS "Users can update own cardio metrics" ON public.cardio_metrics;
CREATE POLICY "Users can update own cardio metrics" ON public.cardio_metrics FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own cardio metrics on cardio_metrics
DROP POLICY IF EXISTS "Users can view own cardio metrics" ON public.cardio_metrics;
CREATE POLICY "Users can view own cardio metrics" ON public.cardio_metrics FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own cardio programs on cardio_progression_programs
DROP POLICY IF EXISTS "Users can delete own cardio programs" ON public.cardio_progression_programs;
CREATE POLICY "Users can delete own cardio programs" ON public.cardio_progression_programs FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own cardio programs on cardio_progression_programs
DROP POLICY IF EXISTS "Users can insert own cardio programs" ON public.cardio_progression_programs;
CREATE POLICY "Users can insert own cardio programs" ON public.cardio_progression_programs FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own cardio programs on cardio_progression_programs
DROP POLICY IF EXISTS "Users can update own cardio programs" ON public.cardio_progression_programs;
CREATE POLICY "Users can update own cardio programs" ON public.cardio_progression_programs FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own cardio programs on cardio_progression_programs
DROP POLICY IF EXISTS "Users can view own cardio programs" ON public.cardio_progression_programs;
CREATE POLICY "Users can view own cardio programs" ON public.cardio_progression_programs FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own cardio sessions on cardio_progression_sessions
DROP POLICY IF EXISTS "Users can delete own cardio sessions" ON public.cardio_progression_sessions;
CREATE POLICY "Users can delete own cardio sessions" ON public.cardio_progression_sessions FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own cardio sessions on cardio_progression_sessions
DROP POLICY IF EXISTS "Users can insert own cardio sessions" ON public.cardio_progression_sessions;
CREATE POLICY "Users can insert own cardio sessions" ON public.cardio_progression_sessions FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own cardio sessions on cardio_progression_sessions
DROP POLICY IF EXISTS "Users can update own cardio sessions" ON public.cardio_progression_sessions;
CREATE POLICY "Users can update own cardio sessions" ON public.cardio_progression_sessions FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own cardio sessions on cardio_progression_sessions
DROP POLICY IF EXISTS "Users can view own cardio sessions" ON public.cardio_progression_sessions;
CREATE POLICY "Users can view own cardio sessions" ON public.cardio_progression_sessions FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Service role has full access to cardio sessions on cardio_sessions
DROP POLICY IF EXISTS "Service role has full access to cardio sessions" ON public.cardio_sessions;
CREATE POLICY "Service role has full access to cardio sessions" ON public.cardio_sessions FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can delete own cardio sessions on cardio_sessions
DROP POLICY IF EXISTS "Users can delete own cardio sessions" ON public.cardio_sessions;
CREATE POLICY "Users can delete own cardio sessions" ON public.cardio_sessions FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own cardio sessions on cardio_sessions
DROP POLICY IF EXISTS "Users can insert own cardio sessions" ON public.cardio_sessions;
CREATE POLICY "Users can insert own cardio sessions" ON public.cardio_sessions FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own cardio sessions on cardio_sessions
DROP POLICY IF EXISTS "Users can update own cardio sessions" ON public.cardio_sessions;
CREATE POLICY "Users can update own cardio sessions" ON public.cardio_sessions FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own cardio sessions on cardio_sessions
DROP POLICY IF EXISTS "Users can view own cardio sessions" ON public.cardio_sessions;
CREATE POLICY "Users can view own cardio sessions" ON public.cardio_sessions FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can update their notifications on challenge_notifications
DROP POLICY IF EXISTS "Users can update their notifications" ON public.challenge_notifications;
CREATE POLICY "Users can update their notifications" ON public.challenge_notifications FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can view their notifications on challenge_notifications
DROP POLICY IF EXISTS "Users can view their notifications" ON public.challenge_notifications;
CREATE POLICY "Users can view their notifications" ON public.challenge_notifications FOR SELECT USING ((user_id = (select auth.uid())));

-- Fix policy: Users can join challenges on challenge_participants
DROP POLICY IF EXISTS "Users can join challenges" ON public.challenge_participants;
CREATE POLICY "Users can join challenges" ON public.challenge_participants FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: Users can leave challenges on challenge_participants
DROP POLICY IF EXISTS "Users can leave challenges" ON public.challenge_participants;
CREATE POLICY "Users can leave challenges" ON public.challenge_participants FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can update their own participation on challenge_participants
DROP POLICY IF EXISTS "Users can update their own participation" ON public.challenge_participants;
CREATE POLICY "Users can update their own participation" ON public.challenge_participants FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can create challenges on challenges
DROP POLICY IF EXISTS "Users can create challenges" ON public.challenges;
CREATE POLICY "Users can create challenges" ON public.challenges FOR INSERT WITH CHECK ((created_by = (select auth.uid())));

-- Fix policy: Users can update their own challenges on challenges
DROP POLICY IF EXISTS "Users can update their own challenges" ON public.challenges;
CREATE POLICY "Users can update their own challenges" ON public.challenges FOR UPDATE USING ((created_by = (select auth.uid())));

-- Fix policy: Users can view public challenges and those they participate in on challenges
DROP POLICY IF EXISTS "Users can view public challenges and those they participate in" ON public.challenges;
CREATE POLICY "Users can view public challenges and those they participate in" ON public.challenges FOR SELECT USING (((is_public = true) OR (created_by = (select auth.uid())) OR (EXISTS ( SELECT 1 FROM challenge_participants WHERE ((challenge_participants.challenge_id = challenges.id) AND (challenge_participants.user_id = (select auth.uid())))))));

-- Fix policy: Users can manage own chat_history on chat_history
DROP POLICY IF EXISTS "Users can manage own chat_history" ON public.chat_history;
CREATE POLICY "Users can manage own chat_history" ON public.chat_history FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: chat_interaction_analytics_policy on chat_interaction_analytics
DROP POLICY IF EXISTS "chat_interaction_analytics_policy" ON public.chat_interaction_analytics;
CREATE POLICY "chat_interaction_analytics_policy" ON public.chat_interaction_analytics FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: comeback_history_insert_policy on comeback_history
DROP POLICY IF EXISTS "comeback_history_insert_policy" ON public.comeback_history;
CREATE POLICY "comeback_history_insert_policy" ON public.comeback_history FOR INSERT WITH CHECK (((select auth.uid()) IN ( SELECT users.auth_id FROM users WHERE (users.id = comeback_history.user_id))));

-- Fix policy: comeback_history_select_policy on comeback_history
DROP POLICY IF EXISTS "comeback_history_select_policy" ON public.comeback_history;
CREATE POLICY "comeback_history_select_policy" ON public.comeback_history FOR SELECT USING (((select auth.uid()) IN ( SELECT users.auth_id FROM users WHERE (users.id = comeback_history.user_id))));

-- Fix policy: comeback_history_update_policy on comeback_history
DROP POLICY IF EXISTS "comeback_history_update_policy" ON public.comeback_history;
CREATE POLICY "comeback_history_update_policy" ON public.comeback_history FOR UPDATE USING (((select auth.uid()) IN ( SELECT users.auth_id FROM users WHERE (users.id = comeback_history.user_id))));

-- Fix policy: composite_components_delete_policy on composite_exercise_components
DROP POLICY IF EXISTS "composite_components_delete_policy" ON public.composite_exercise_components;
CREATE POLICY "composite_components_delete_policy" ON public.composite_exercise_components FOR DELETE USING ((EXISTS ( SELECT 1 FROM exercises e WHERE ((e.id = composite_exercise_components.composite_exercise_id) AND (e.created_by_user_id = (select auth.uid()))))));

-- Fix policy: composite_components_insert_policy on composite_exercise_components
DROP POLICY IF EXISTS "composite_components_insert_policy" ON public.composite_exercise_components;
CREATE POLICY "composite_components_insert_policy" ON public.composite_exercise_components FOR INSERT WITH CHECK ((EXISTS ( SELECT 1 FROM exercises e WHERE ((e.id = composite_exercise_components.composite_exercise_id) AND (e.created_by_user_id = (select auth.uid()))))));

-- Fix policy: composite_components_select_policy on composite_exercise_components
DROP POLICY IF EXISTS "composite_components_select_policy" ON public.composite_exercise_components;
CREATE POLICY "composite_components_select_policy" ON public.composite_exercise_components FOR SELECT USING ((EXISTS ( SELECT 1 FROM exercises e WHERE ((e.id = composite_exercise_components.composite_exercise_id) AND ((e.created_by_user_id = (select auth.uid())) OR (e.is_custom = false))))));

-- Fix policy: conversion_triggers_insert_policy on conversion_triggers
DROP POLICY IF EXISTS "conversion_triggers_insert_policy" ON public.conversion_triggers;
CREATE POLICY "conversion_triggers_insert_policy" ON public.conversion_triggers FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: conversion_triggers_service_policy on conversion_triggers
DROP POLICY IF EXISTS "conversion_triggers_service_policy" ON public.conversion_triggers;
CREATE POLICY "conversion_triggers_service_policy" ON public.conversion_triggers FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: conversion_triggers_user_policy on conversion_triggers
DROP POLICY IF EXISTS "conversion_triggers_user_policy" ON public.conversion_triggers;
CREATE POLICY "conversion_triggers_user_policy" ON public.conversion_triggers FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: custom_exercise_usage_delete_policy on custom_exercise_usage
DROP POLICY IF EXISTS "custom_exercise_usage_delete_policy" ON public.custom_exercise_usage;
CREATE POLICY "custom_exercise_usage_delete_policy" ON public.custom_exercise_usage FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: custom_exercise_usage_insert_policy on custom_exercise_usage
DROP POLICY IF EXISTS "custom_exercise_usage_insert_policy" ON public.custom_exercise_usage;
CREATE POLICY "custom_exercise_usage_insert_policy" ON public.custom_exercise_usage FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: custom_exercise_usage_select_policy on custom_exercise_usage
DROP POLICY IF EXISTS "custom_exercise_usage_select_policy" ON public.custom_exercise_usage;
CREATE POLICY "custom_exercise_usage_select_policy" ON public.custom_exercise_usage FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own custom_goals on custom_goals
DROP POLICY IF EXISTS "Users can delete own custom_goals" ON public.custom_goals;
CREATE POLICY "Users can delete own custom_goals" ON public.custom_goals FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can insert own custom_goals on custom_goals
DROP POLICY IF EXISTS "Users can insert own custom_goals" ON public.custom_goals;
CREATE POLICY "Users can insert own custom_goals" ON public.custom_goals FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can update own custom_goals on custom_goals
DROP POLICY IF EXISTS "Users can update own custom_goals" ON public.custom_goals;
CREATE POLICY "Users can update own custom_goals" ON public.custom_goals FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can view own custom_goals on custom_goals
DROP POLICY IF EXISTS "Users can view own custom_goals" ON public.custom_goals;
CREATE POLICY "Users can view own custom_goals" ON public.custom_goals FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can manage own custom_workout_inputs on custom_workout_inputs
DROP POLICY IF EXISTS "Users can manage own custom_workout_inputs" ON public.custom_workout_inputs;
CREATE POLICY "Users can manage own custom_workout_inputs" ON public.custom_workout_inputs FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: daily_plan_entries_delete_policy on daily_plan_entries
DROP POLICY IF EXISTS "daily_plan_entries_delete_policy" ON public.daily_plan_entries;
CREATE POLICY "daily_plan_entries_delete_policy" ON public.daily_plan_entries FOR DELETE USING ((weekly_plan_id IN ( SELECT weekly_plans.id FROM weekly_plans WHERE (weekly_plans.user_id = (select auth.uid())))));

-- Fix policy: daily_plan_entries_insert_policy on daily_plan_entries
DROP POLICY IF EXISTS "daily_plan_entries_insert_policy" ON public.daily_plan_entries;
CREATE POLICY "daily_plan_entries_insert_policy" ON public.daily_plan_entries FOR INSERT WITH CHECK ((weekly_plan_id IN ( SELECT weekly_plans.id FROM weekly_plans WHERE (weekly_plans.user_id = (select auth.uid())))));

-- Fix policy: daily_plan_entries_select_policy on daily_plan_entries
DROP POLICY IF EXISTS "daily_plan_entries_select_policy" ON public.daily_plan_entries;
CREATE POLICY "daily_plan_entries_select_policy" ON public.daily_plan_entries FOR SELECT USING ((weekly_plan_id IN ( SELECT weekly_plans.id FROM weekly_plans WHERE (weekly_plans.user_id = (select auth.uid())))));

-- Fix policy: daily_plan_entries_update_policy on daily_plan_entries
DROP POLICY IF EXISTS "daily_plan_entries_update_policy" ON public.daily_plan_entries;
CREATE POLICY "daily_plan_entries_update_policy" ON public.daily_plan_entries FOR UPDATE USING ((weekly_plan_id IN ( SELECT weekly_plans.id FROM weekly_plans WHERE (weekly_plans.user_id = (select auth.uid())))));

-- Fix policy: Users can manage own daily checkins on daily_subjective_checkin
DROP POLICY IF EXISTS "Users can manage own daily checkins" ON public.daily_subjective_checkin;
CREATE POLICY "Users can manage own daily checkins" ON public.daily_subjective_checkin FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: daily_unified_state_delete_policy on daily_unified_state
DROP POLICY IF EXISTS "daily_unified_state_delete_policy" ON public.daily_unified_state;
CREATE POLICY "daily_unified_state_delete_policy" ON public.daily_unified_state FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: daily_unified_state_insert_policy on daily_unified_state
DROP POLICY IF EXISTS "daily_unified_state_insert_policy" ON public.daily_unified_state;
CREATE POLICY "daily_unified_state_insert_policy" ON public.daily_unified_state FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: daily_unified_state_select_policy on daily_unified_state
DROP POLICY IF EXISTS "daily_unified_state_select_policy" ON public.daily_unified_state;
CREATE POLICY "daily_unified_state_select_policy" ON public.daily_unified_state FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: daily_unified_state_update_policy on daily_unified_state
DROP POLICY IF EXISTS "daily_unified_state_update_policy" ON public.daily_unified_state;
CREATE POLICY "daily_unified_state_update_policy" ON public.daily_unified_state FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Service role full access daily stats on daily_user_stats
DROP POLICY IF EXISTS "Service role full access daily stats" ON public.daily_user_stats;
CREATE POLICY "Service role full access daily stats" ON public.daily_user_stats FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can read own daily stats on daily_user_stats
DROP POLICY IF EXISTS "Users can read own daily stats" ON public.daily_user_stats;
CREATE POLICY "Users can read own daily stats" ON public.daily_user_stats FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: demo_interactions_select_policy on demo_interactions
DROP POLICY IF EXISTS "demo_interactions_select_policy" ON public.demo_interactions;
CREATE POLICY "demo_interactions_select_policy" ON public.demo_interactions FOR SELECT USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: demo_sessions_select_policy on demo_sessions
DROP POLICY IF EXISTS "demo_sessions_select_policy" ON public.demo_sessions;
CREATE POLICY "demo_sessions_select_policy" ON public.demo_sessions FOR SELECT USING ((((select auth.uid()) = converted_to_user_id) OR ((select auth.role()) = 'service_role'::text)));

-- Fix policy: diabetes_daily_summary_delete on diabetes_daily_summary
DROP POLICY IF EXISTS "diabetes_daily_summary_delete" ON public.diabetes_daily_summary;
CREATE POLICY "diabetes_daily_summary_delete" ON public.diabetes_daily_summary FOR DELETE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_daily_summary.user_id))));

-- Fix policy: diabetes_daily_summary_insert on diabetes_daily_summary
DROP POLICY IF EXISTS "diabetes_daily_summary_insert" ON public.diabetes_daily_summary;
CREATE POLICY "diabetes_daily_summary_insert" ON public.diabetes_daily_summary FOR INSERT WITH CHECK (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_daily_summary.user_id))));

-- Fix policy: diabetes_daily_summary_select on diabetes_daily_summary
DROP POLICY IF EXISTS "diabetes_daily_summary_select" ON public.diabetes_daily_summary;
CREATE POLICY "diabetes_daily_summary_select" ON public.diabetes_daily_summary FOR SELECT USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_daily_summary.user_id))));

-- Fix policy: diabetes_daily_summary_update on diabetes_daily_summary
DROP POLICY IF EXISTS "diabetes_daily_summary_update" ON public.diabetes_daily_summary;
CREATE POLICY "diabetes_daily_summary_update" ON public.diabetes_daily_summary FOR UPDATE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_daily_summary.user_id))));

-- Fix policy: diabetes_medications_delete on diabetes_medications
DROP POLICY IF EXISTS "diabetes_medications_delete" ON public.diabetes_medications;
CREATE POLICY "diabetes_medications_delete" ON public.diabetes_medications FOR DELETE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_medications.user_id))));

-- Fix policy: diabetes_medications_insert on diabetes_medications
DROP POLICY IF EXISTS "diabetes_medications_insert" ON public.diabetes_medications;
CREATE POLICY "diabetes_medications_insert" ON public.diabetes_medications FOR INSERT WITH CHECK (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_medications.user_id))));

-- Fix policy: diabetes_medications_select on diabetes_medications
DROP POLICY IF EXISTS "diabetes_medications_select" ON public.diabetes_medications;
CREATE POLICY "diabetes_medications_select" ON public.diabetes_medications FOR SELECT USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_medications.user_id))));

-- Fix policy: diabetes_medications_update on diabetes_medications
DROP POLICY IF EXISTS "diabetes_medications_update" ON public.diabetes_medications;
CREATE POLICY "diabetes_medications_update" ON public.diabetes_medications FOR UPDATE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_medications.user_id))));

-- Fix policy: diabetes_profiles_delete on diabetes_profiles
DROP POLICY IF EXISTS "diabetes_profiles_delete" ON public.diabetes_profiles;
CREATE POLICY "diabetes_profiles_delete" ON public.diabetes_profiles FOR DELETE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_profiles.user_id))));

-- Fix policy: diabetes_profiles_insert on diabetes_profiles
DROP POLICY IF EXISTS "diabetes_profiles_insert" ON public.diabetes_profiles;
CREATE POLICY "diabetes_profiles_insert" ON public.diabetes_profiles FOR INSERT WITH CHECK (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_profiles.user_id))));

-- Fix policy: diabetes_profiles_select on diabetes_profiles
DROP POLICY IF EXISTS "diabetes_profiles_select" ON public.diabetes_profiles;
CREATE POLICY "diabetes_profiles_select" ON public.diabetes_profiles FOR SELECT USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_profiles.user_id))));

-- Fix policy: diabetes_profiles_update on diabetes_profiles
DROP POLICY IF EXISTS "diabetes_profiles_update" ON public.diabetes_profiles;
CREATE POLICY "diabetes_profiles_update" ON public.diabetes_profiles FOR UPDATE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = diabetes_profiles.user_id))));

-- Fix policy: Users can delete own adjustments on difficulty_adjustments
DROP POLICY IF EXISTS "Users can delete own adjustments" ON public.difficulty_adjustments;
CREATE POLICY "Users can delete own adjustments" ON public.difficulty_adjustments FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own adjustments on difficulty_adjustments
DROP POLICY IF EXISTS "Users can view own adjustments" ON public.difficulty_adjustments;
CREATE POLICY "Users can view own adjustments" ON public.difficulty_adjustments FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert their own drink intakes on drink_intake_logs
DROP POLICY IF EXISTS "Users can insert their own drink intakes" ON public.drink_intake_logs;
CREATE POLICY "Users can insert their own drink intakes" ON public.drink_intake_logs FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own drink intakes on drink_intake_logs
DROP POLICY IF EXISTS "Users can view their own drink intakes" ON public.drink_intake_logs;
CREATE POLICY "Users can view their own drink intakes" ON public.drink_intake_logs FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Service role has full access to email preferences on email_preferences
DROP POLICY IF EXISTS "Service role has full access to email preferences" ON public.email_preferences;
CREATE POLICY "Service role has full access to email preferences" ON public.email_preferences FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can delete own email preferences on email_preferences
DROP POLICY IF EXISTS "Users can delete own email preferences" ON public.email_preferences;
CREATE POLICY "Users can delete own email preferences" ON public.email_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own email preferences on email_preferences
DROP POLICY IF EXISTS "Users can insert own email preferences" ON public.email_preferences;
CREATE POLICY "Users can insert own email preferences" ON public.email_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own email preferences on email_preferences
DROP POLICY IF EXISTS "Users can update own email preferences" ON public.email_preferences;
CREATE POLICY "Users can update own email preferences" ON public.email_preferences FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own email preferences on email_preferences
DROP POLICY IF EXISTS "Users can view own email preferences" ON public.email_preferences;
CREATE POLICY "Users can view own email preferences" ON public.email_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own equipment_usage_analytics on equipment_usage_analytics
DROP POLICY IF EXISTS "Users can manage own equipment_usage_analytics" ON public.equipment_usage_analytics;
CREATE POLICY "Users can manage own equipment_usage_analytics" ON public.equipment_usage_analytics FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: exercise_feedback_delete_policy on exercise_feedback
DROP POLICY IF EXISTS "exercise_feedback_delete_policy" ON public.exercise_feedback;
CREATE POLICY "exercise_feedback_delete_policy" ON public.exercise_feedback FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_feedback_insert_policy on exercise_feedback
DROP POLICY IF EXISTS "exercise_feedback_insert_policy" ON public.exercise_feedback;
CREATE POLICY "exercise_feedback_insert_policy" ON public.exercise_feedback FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: exercise_feedback_select_policy on exercise_feedback
DROP POLICY IF EXISTS "exercise_feedback_select_policy" ON public.exercise_feedback;
CREATE POLICY "exercise_feedback_select_policy" ON public.exercise_feedback FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_feedback_service_policy on exercise_feedback
DROP POLICY IF EXISTS "exercise_feedback_service_policy" ON public.exercise_feedback;
CREATE POLICY "exercise_feedback_service_policy" ON public.exercise_feedback FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: exercise_feedback_update_policy on exercise_feedback
DROP POLICY IF EXISTS "exercise_feedback_update_policy" ON public.exercise_feedback;
CREATE POLICY "exercise_feedback_update_policy" ON public.exercise_feedback FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_intensity_overrides_delete on exercise_intensity_overrides
DROP POLICY IF EXISTS "exercise_intensity_overrides_delete" ON public.exercise_intensity_overrides;
CREATE POLICY "exercise_intensity_overrides_delete" ON public.exercise_intensity_overrides FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_intensity_overrides_insert on exercise_intensity_overrides
DROP POLICY IF EXISTS "exercise_intensity_overrides_insert" ON public.exercise_intensity_overrides;
CREATE POLICY "exercise_intensity_overrides_insert" ON public.exercise_intensity_overrides FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: exercise_intensity_overrides_select on exercise_intensity_overrides
DROP POLICY IF EXISTS "exercise_intensity_overrides_select" ON public.exercise_intensity_overrides;
CREATE POLICY "exercise_intensity_overrides_select" ON public.exercise_intensity_overrides FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_intensity_overrides_update on exercise_intensity_overrides
DROP POLICY IF EXISTS "exercise_intensity_overrides_update" ON public.exercise_intensity_overrides;
CREATE POLICY "exercise_intensity_overrides_update" ON public.exercise_intensity_overrides FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_library_service_policy on exercise_library
DROP POLICY IF EXISTS "exercise_library_service_policy" ON public.exercise_library;
CREATE POLICY "exercise_library_service_policy" ON public.exercise_library FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Service role can manage all exercise performance on exercise_performance_summary
DROP POLICY IF EXISTS "Service role can manage all exercise performance" ON public.exercise_performance_summary;
CREATE POLICY "Service role can manage all exercise performance" ON public.exercise_performance_summary FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own exercise performance on exercise_performance_summary
DROP POLICY IF EXISTS "Users can insert own exercise performance" ON public.exercise_performance_summary;
CREATE POLICY "Users can insert own exercise performance" ON public.exercise_performance_summary FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own exercise performance on exercise_performance_summary
DROP POLICY IF EXISTS "Users can view own exercise performance" ON public.exercise_performance_summary;
CREATE POLICY "Users can view own exercise performance" ON public.exercise_performance_summary FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_personal_records_delete on exercise_personal_records
DROP POLICY IF EXISTS "exercise_personal_records_delete" ON public.exercise_personal_records;
CREATE POLICY "exercise_personal_records_delete" ON public.exercise_personal_records FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_personal_records_insert on exercise_personal_records
DROP POLICY IF EXISTS "exercise_personal_records_insert" ON public.exercise_personal_records;
CREATE POLICY "exercise_personal_records_insert" ON public.exercise_personal_records FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: exercise_personal_records_select on exercise_personal_records
DROP POLICY IF EXISTS "exercise_personal_records_select" ON public.exercise_personal_records;
CREATE POLICY "exercise_personal_records_select" ON public.exercise_personal_records FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_personal_records_update on exercise_personal_records
DROP POLICY IF EXISTS "exercise_personal_records_update" ON public.exercise_personal_records;
CREATE POLICY "exercise_personal_records_update" ON public.exercise_personal_records FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_queue_delete_policy on exercise_queue
DROP POLICY IF EXISTS "exercise_queue_delete_policy" ON public.exercise_queue;
CREATE POLICY "exercise_queue_delete_policy" ON public.exercise_queue FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_queue_insert_policy on exercise_queue
DROP POLICY IF EXISTS "exercise_queue_insert_policy" ON public.exercise_queue;
CREATE POLICY "exercise_queue_insert_policy" ON public.exercise_queue FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: exercise_queue_select_policy on exercise_queue
DROP POLICY IF EXISTS "exercise_queue_select_policy" ON public.exercise_queue;
CREATE POLICY "exercise_queue_select_policy" ON public.exercise_queue FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: exercise_queue_update_policy on exercise_queue
DROP POLICY IF EXISTS "exercise_queue_update_policy" ON public.exercise_queue;
CREATE POLICY "exercise_queue_update_policy" ON public.exercise_queue FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Service role has full access to exercise_rotations on exercise_rotations
DROP POLICY IF EXISTS "Service role has full access to exercise_rotations" ON public.exercise_rotations;
CREATE POLICY "Service role has full access to exercise_rotations" ON public.exercise_rotations FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can view their own exercise rotations on exercise_rotations
DROP POLICY IF EXISTS "Users can view their own exercise rotations" ON public.exercise_rotations;
CREATE POLICY "Users can view their own exercise rotations" ON public.exercise_rotations FOR SELECT USING (((select auth.uid()) IN ( SELECT users.auth_id FROM users WHERE (users.id = exercise_rotations.user_id))));

-- Fix policy: Users can insert their own exercise swaps on exercise_swaps
DROP POLICY IF EXISTS "Users can insert their own exercise swaps" ON public.exercise_swaps;
CREATE POLICY "Users can insert their own exercise swaps" ON public.exercise_swaps FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own exercise swaps on exercise_swaps
DROP POLICY IF EXISTS "Users can view their own exercise swaps" ON public.exercise_swaps;
CREATE POLICY "Users can view their own exercise swaps" ON public.exercise_swaps FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can create custom exercises on exercises
DROP POLICY IF EXISTS "Users can create custom exercises" ON public.exercises;
CREATE POLICY "Users can create custom exercises" ON public.exercises FOR INSERT WITH CHECK (((is_custom = true) AND (created_by_user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid()))))));

-- Fix policy: fasting_goal_impact_delete_policy on fasting_goal_impact
DROP POLICY IF EXISTS "fasting_goal_impact_delete_policy" ON public.fasting_goal_impact;
CREATE POLICY "fasting_goal_impact_delete_policy" ON public.fasting_goal_impact FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_goal_impact_insert_policy on fasting_goal_impact
DROP POLICY IF EXISTS "fasting_goal_impact_insert_policy" ON public.fasting_goal_impact;
CREATE POLICY "fasting_goal_impact_insert_policy" ON public.fasting_goal_impact FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: fasting_goal_impact_select_policy on fasting_goal_impact
DROP POLICY IF EXISTS "fasting_goal_impact_select_policy" ON public.fasting_goal_impact;
CREATE POLICY "fasting_goal_impact_select_policy" ON public.fasting_goal_impact FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_goal_impact_update_policy on fasting_goal_impact
DROP POLICY IF EXISTS "fasting_goal_impact_update_policy" ON public.fasting_goal_impact;
CREATE POLICY "fasting_goal_impact_update_policy" ON public.fasting_goal_impact FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_preferences_delete_policy on fasting_preferences
DROP POLICY IF EXISTS "fasting_preferences_delete_policy" ON public.fasting_preferences;
CREATE POLICY "fasting_preferences_delete_policy" ON public.fasting_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_preferences_insert_policy on fasting_preferences
DROP POLICY IF EXISTS "fasting_preferences_insert_policy" ON public.fasting_preferences;
CREATE POLICY "fasting_preferences_insert_policy" ON public.fasting_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: fasting_preferences_select_policy on fasting_preferences
DROP POLICY IF EXISTS "fasting_preferences_select_policy" ON public.fasting_preferences;
CREATE POLICY "fasting_preferences_select_policy" ON public.fasting_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_preferences_update_policy on fasting_preferences
DROP POLICY IF EXISTS "fasting_preferences_update_policy" ON public.fasting_preferences;
CREATE POLICY "fasting_preferences_update_policy" ON public.fasting_preferences FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_records_delete_policy on fasting_records
DROP POLICY IF EXISTS "fasting_records_delete_policy" ON public.fasting_records;
CREATE POLICY "fasting_records_delete_policy" ON public.fasting_records FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_records_insert_policy on fasting_records
DROP POLICY IF EXISTS "fasting_records_insert_policy" ON public.fasting_records;
CREATE POLICY "fasting_records_insert_policy" ON public.fasting_records FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: fasting_records_select_policy on fasting_records
DROP POLICY IF EXISTS "fasting_records_select_policy" ON public.fasting_records;
CREATE POLICY "fasting_records_select_policy" ON public.fasting_records FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_records_update_policy on fasting_records
DROP POLICY IF EXISTS "fasting_records_update_policy" ON public.fasting_records;
CREATE POLICY "fasting_records_update_policy" ON public.fasting_records FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_streaks_delete_policy on fasting_streaks
DROP POLICY IF EXISTS "fasting_streaks_delete_policy" ON public.fasting_streaks;
CREATE POLICY "fasting_streaks_delete_policy" ON public.fasting_streaks FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_streaks_insert_policy on fasting_streaks
DROP POLICY IF EXISTS "fasting_streaks_insert_policy" ON public.fasting_streaks;
CREATE POLICY "fasting_streaks_insert_policy" ON public.fasting_streaks FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: fasting_streaks_select_policy on fasting_streaks
DROP POLICY IF EXISTS "fasting_streaks_select_policy" ON public.fasting_streaks;
CREATE POLICY "fasting_streaks_select_policy" ON public.fasting_streaks FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_streaks_update_policy on fasting_streaks
DROP POLICY IF EXISTS "fasting_streaks_update_policy" ON public.fasting_streaks;
CREATE POLICY "fasting_streaks_update_policy" ON public.fasting_streaks FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_user_context_delete_policy on fasting_user_context
DROP POLICY IF EXISTS "fasting_user_context_delete_policy" ON public.fasting_user_context;
CREATE POLICY "fasting_user_context_delete_policy" ON public.fasting_user_context FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_user_context_insert_policy on fasting_user_context
DROP POLICY IF EXISTS "fasting_user_context_insert_policy" ON public.fasting_user_context;
CREATE POLICY "fasting_user_context_insert_policy" ON public.fasting_user_context FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: fasting_user_context_select_policy on fasting_user_context
DROP POLICY IF EXISTS "fasting_user_context_select_policy" ON public.fasting_user_context;
CREATE POLICY "fasting_user_context_select_policy" ON public.fasting_user_context FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_user_context_update_policy on fasting_user_context
DROP POLICY IF EXISTS "fasting_user_context_update_policy" ON public.fasting_user_context;
CREATE POLICY "fasting_user_context_update_policy" ON public.fasting_user_context FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_weight_correlation_delete_policy on fasting_weight_correlation
DROP POLICY IF EXISTS "fasting_weight_correlation_delete_policy" ON public.fasting_weight_correlation;
CREATE POLICY "fasting_weight_correlation_delete_policy" ON public.fasting_weight_correlation FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_weight_correlation_insert_policy on fasting_weight_correlation
DROP POLICY IF EXISTS "fasting_weight_correlation_insert_policy" ON public.fasting_weight_correlation;
CREATE POLICY "fasting_weight_correlation_insert_policy" ON public.fasting_weight_correlation FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: fasting_weight_correlation_select_policy on fasting_weight_correlation
DROP POLICY IF EXISTS "fasting_weight_correlation_select_policy" ON public.fasting_weight_correlation;
CREATE POLICY "fasting_weight_correlation_select_policy" ON public.fasting_weight_correlation FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: fasting_weight_correlation_update_policy on fasting_weight_correlation
DROP POLICY IF EXISTS "fasting_weight_correlation_update_policy" ON public.fasting_weight_correlation;
CREATE POLICY "fasting_weight_correlation_update_policy" ON public.fasting_weight_correlation FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: favorite_exercises_delete_policy on favorite_exercises
DROP POLICY IF EXISTS "favorite_exercises_delete_policy" ON public.favorite_exercises;
CREATE POLICY "favorite_exercises_delete_policy" ON public.favorite_exercises FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: favorite_exercises_insert_policy on favorite_exercises
DROP POLICY IF EXISTS "favorite_exercises_insert_policy" ON public.favorite_exercises;
CREATE POLICY "favorite_exercises_insert_policy" ON public.favorite_exercises FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: favorite_exercises_select_policy on favorite_exercises
DROP POLICY IF EXISTS "favorite_exercises_select_policy" ON public.favorite_exercises;
CREATE POLICY "favorite_exercises_select_policy" ON public.favorite_exercises FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can create own favorite supersets on favorite_superset_pairs
DROP POLICY IF EXISTS "Users can create own favorite supersets" ON public.favorite_superset_pairs;
CREATE POLICY "Users can create own favorite supersets" ON public.favorite_superset_pairs FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own favorite supersets on favorite_superset_pairs
DROP POLICY IF EXISTS "Users can delete own favorite supersets" ON public.favorite_superset_pairs;
CREATE POLICY "Users can delete own favorite supersets" ON public.favorite_superset_pairs FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can update own favorite supersets on favorite_superset_pairs
DROP POLICY IF EXISTS "Users can update own favorite supersets" ON public.favorite_superset_pairs;
CREATE POLICY "Users can update own favorite supersets" ON public.favorite_superset_pairs FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own favorite supersets on favorite_superset_pairs
DROP POLICY IF EXISTS "Users can view own favorite supersets" ON public.favorite_superset_pairs;
CREATE POLICY "Users can view own favorite supersets" ON public.favorite_superset_pairs FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Authenticated users can create feature requests on feature_requests
DROP POLICY IF EXISTS "Authenticated users can create feature requests" ON public.feature_requests;
CREATE POLICY "Authenticated users can create feature requests" ON public.feature_requests FOR INSERT WITH CHECK (((select auth.uid()) = created_by));

-- Fix policy: Creators can delete their own feature requests on feature_requests
DROP POLICY IF EXISTS "Creators can delete their own feature requests" ON public.feature_requests;
CREATE POLICY "Creators can delete their own feature requests" ON public.feature_requests FOR DELETE USING (((select auth.uid()) = created_by));

-- Fix policy: Creators can update their own feature requests on feature_requests
DROP POLICY IF EXISTS "Creators can update their own feature requests" ON public.feature_requests;
CREATE POLICY "Creators can update their own feature requests" ON public.feature_requests FOR UPDATE USING (((select auth.uid()) = created_by));

-- Fix policy: Users can manage own feature usage on feature_usage
DROP POLICY IF EXISTS "Users can manage own feature usage" ON public.feature_usage;
CREATE POLICY "Users can manage own feature usage" ON public.feature_usage FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can create votes on feature_votes
DROP POLICY IF EXISTS "Users can create votes" ON public.feature_votes;
CREATE POLICY "Users can create votes" ON public.feature_votes FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can delete their own votes on feature_votes
DROP POLICY IF EXISTS "Users can delete their own votes" ON public.feature_votes;
CREATE POLICY "Users can delete their own votes" ON public.feature_votes FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: fitness_scores_insert_policy on fitness_scores
DROP POLICY IF EXISTS "fitness_scores_insert_policy" ON public.fitness_scores;
CREATE POLICY "fitness_scores_insert_policy" ON public.fitness_scores FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: fitness_scores_select_policy on fitness_scores
DROP POLICY IF EXISTS "fitness_scores_select_policy" ON public.fitness_scores;
CREATE POLICY "fitness_scores_select_policy" ON public.fitness_scores FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: fitness_scores_service_policy on fitness_scores
DROP POLICY IF EXISTS "fitness_scores_service_policy" ON public.fitness_scores;
CREATE POLICY "fitness_scores_service_policy" ON public.fitness_scores FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can delete own flexibility assessments on flexibility_assessments
DROP POLICY IF EXISTS "Users can delete own flexibility assessments" ON public.flexibility_assessments;
CREATE POLICY "Users can delete own flexibility assessments" ON public.flexibility_assessments FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own flexibility assessments on flexibility_assessments
DROP POLICY IF EXISTS "Users can insert own flexibility assessments" ON public.flexibility_assessments;
CREATE POLICY "Users can insert own flexibility assessments" ON public.flexibility_assessments FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own flexibility assessments on flexibility_assessments
DROP POLICY IF EXISTS "Users can update own flexibility assessments" ON public.flexibility_assessments;
CREATE POLICY "Users can update own flexibility assessments" ON public.flexibility_assessments FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own flexibility assessments on flexibility_assessments
DROP POLICY IF EXISTS "Users can view own flexibility assessments" ON public.flexibility_assessments;
CREATE POLICY "Users can view own flexibility assessments" ON public.flexibility_assessments FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own stretch plans on flexibility_stretch_plans
DROP POLICY IF EXISTS "Users can manage own stretch plans" ON public.flexibility_stretch_plans;
CREATE POLICY "Users can manage own stretch plans" ON public.flexibility_stretch_plans FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: food_logs_delete_policy on food_logs
DROP POLICY IF EXISTS "food_logs_delete_policy" ON public.food_logs;
CREATE POLICY "food_logs_delete_policy" ON public.food_logs FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: food_logs_insert_policy on food_logs
DROP POLICY IF EXISTS "food_logs_insert_policy" ON public.food_logs;
CREATE POLICY "food_logs_insert_policy" ON public.food_logs FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: food_logs_select_policy on food_logs
DROP POLICY IF EXISTS "food_logs_select_policy" ON public.food_logs;
CREATE POLICY "food_logs_select_policy" ON public.food_logs FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: food_logs_service_policy on food_logs
DROP POLICY IF EXISTS "food_logs_service_policy" ON public.food_logs;
CREATE POLICY "food_logs_service_policy" ON public.food_logs FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: food_logs_update_policy on food_logs
DROP POLICY IF EXISTS "food_logs_update_policy" ON public.food_logs;
CREATE POLICY "food_logs_update_policy" ON public.food_logs FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Service role can manage friend requests on friend_requests
DROP POLICY IF EXISTS "Service role can manage friend requests" ON public.friend_requests;
CREATE POLICY "Service role can manage friend requests" ON public.friend_requests FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can cancel own friend requests on friend_requests
DROP POLICY IF EXISTS "Users can cancel own friend requests" ON public.friend_requests;
CREATE POLICY "Users can cancel own friend requests" ON public.friend_requests FOR DELETE USING ((((select auth.uid()))::text = (from_user_id)::text));

-- Fix policy: Users can respond to friend requests on friend_requests
DROP POLICY IF EXISTS "Users can respond to friend requests" ON public.friend_requests;
CREATE POLICY "Users can respond to friend requests" ON public.friend_requests FOR UPDATE USING ((((select auth.uid()))::text = (to_user_id)::text));

-- Fix policy: Users can send friend requests on friend_requests
DROP POLICY IF EXISTS "Users can send friend requests" ON public.friend_requests;
CREATE POLICY "Users can send friend requests" ON public.friend_requests FOR INSERT WITH CHECK ((((select auth.uid()))::text = (from_user_id)::text));

-- Fix policy: Users can view own friend requests on friend_requests
DROP POLICY IF EXISTS "Users can view own friend requests" ON public.friend_requests;
CREATE POLICY "Users can view own friend requests" ON public.friend_requests FOR SELECT USING (((((select auth.uid()))::text = (from_user_id)::text) OR (((select auth.uid()))::text = (to_user_id)::text)));

-- Fix policy: Service role full access funnel on funnel_events
DROP POLICY IF EXISTS "Service role full access funnel" ON public.funnel_events;
CREATE POLICY "Service role full access funnel" ON public.funnel_events FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own funnel events on funnel_events
DROP POLICY IF EXISTS "Users can insert own funnel events" ON public.funnel_events;
CREATE POLICY "Users can insert own funnel events" ON public.funnel_events FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))) OR (user_id IS NULL)));

-- Fix policy: Users can read own funnel events on funnel_events
DROP POLICY IF EXISTS "Users can read own funnel events" ON public.funnel_events;
CREATE POLICY "Users can read own funnel events" ON public.funnel_events FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can delete their own generated workouts on generated_workouts
DROP POLICY IF EXISTS "Users can delete their own generated workouts" ON public.generated_workouts;
CREATE POLICY "Users can delete their own generated workouts" ON public.generated_workouts FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert their own generated workouts on generated_workouts
DROP POLICY IF EXISTS "Users can insert their own generated workouts" ON public.generated_workouts;
CREATE POLICY "Users can insert their own generated workouts" ON public.generated_workouts FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update their own generated workouts on generated_workouts
DROP POLICY IF EXISTS "Users can update their own generated workouts" ON public.generated_workouts;
CREATE POLICY "Users can update their own generated workouts" ON public.generated_workouts FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own generated workouts on generated_workouts
DROP POLICY IF EXISTS "Users can view their own generated workouts" ON public.generated_workouts;
CREATE POLICY "Users can view their own generated workouts" ON public.generated_workouts FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: glucose_alerts_delete on glucose_alerts
DROP POLICY IF EXISTS "glucose_alerts_delete" ON public.glucose_alerts;
CREATE POLICY "glucose_alerts_delete" ON public.glucose_alerts FOR DELETE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = glucose_alerts.user_id))));

-- Fix policy: glucose_alerts_insert on glucose_alerts
DROP POLICY IF EXISTS "glucose_alerts_insert" ON public.glucose_alerts;
CREATE POLICY "glucose_alerts_insert" ON public.glucose_alerts FOR INSERT WITH CHECK (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = glucose_alerts.user_id))));

-- Fix policy: glucose_alerts_select on glucose_alerts
DROP POLICY IF EXISTS "glucose_alerts_select" ON public.glucose_alerts;
CREATE POLICY "glucose_alerts_select" ON public.glucose_alerts FOR SELECT USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = glucose_alerts.user_id))));

-- Fix policy: glucose_alerts_update on glucose_alerts
DROP POLICY IF EXISTS "glucose_alerts_update" ON public.glucose_alerts;
CREATE POLICY "glucose_alerts_update" ON public.glucose_alerts FOR UPDATE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = glucose_alerts.user_id))));

-- Fix policy: glucose_readings_delete on glucose_readings
DROP POLICY IF EXISTS "glucose_readings_delete" ON public.glucose_readings;
CREATE POLICY "glucose_readings_delete" ON public.glucose_readings FOR DELETE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = glucose_readings.user_id))));

-- Fix policy: glucose_readings_insert on glucose_readings
DROP POLICY IF EXISTS "glucose_readings_insert" ON public.glucose_readings;
CREATE POLICY "glucose_readings_insert" ON public.glucose_readings FOR INSERT WITH CHECK (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = glucose_readings.user_id))));

-- Fix policy: glucose_readings_select on glucose_readings
DROP POLICY IF EXISTS "glucose_readings_select" ON public.glucose_readings;
CREATE POLICY "glucose_readings_select" ON public.glucose_readings FOR SELECT USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = glucose_readings.user_id))));

-- Fix policy: glucose_readings_update on glucose_readings
DROP POLICY IF EXISTS "glucose_readings_update" ON public.glucose_readings;
CREATE POLICY "glucose_readings_update" ON public.glucose_readings FOR UPDATE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = glucose_readings.user_id))));

-- Fix policy: Users can manage their own attempts on goal_attempts
DROP POLICY IF EXISTS "Users can manage their own attempts" ON public.goal_attempts;
CREATE POLICY "Users can manage their own attempts" ON public.goal_attempts FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: goal_friends_cache_delete_policy on goal_friends_cache
DROP POLICY IF EXISTS "goal_friends_cache_delete_policy" ON public.goal_friends_cache;
CREATE POLICY "goal_friends_cache_delete_policy" ON public.goal_friends_cache FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: goal_friends_cache_insert_policy on goal_friends_cache
DROP POLICY IF EXISTS "goal_friends_cache_insert_policy" ON public.goal_friends_cache;
CREATE POLICY "goal_friends_cache_insert_policy" ON public.goal_friends_cache FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: goal_friends_cache_select_policy on goal_friends_cache
DROP POLICY IF EXISTS "goal_friends_cache_select_policy" ON public.goal_friends_cache;
CREATE POLICY "goal_friends_cache_select_policy" ON public.goal_friends_cache FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: goal_friends_cache_update_policy on goal_friends_cache
DROP POLICY IF EXISTS "goal_friends_cache_update_policy" ON public.goal_friends_cache;
CREATE POLICY "goal_friends_cache_update_policy" ON public.goal_friends_cache FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: goal_invites_delete_policy on goal_invites
DROP POLICY IF EXISTS "goal_invites_delete_policy" ON public.goal_invites;
CREATE POLICY "goal_invites_delete_policy" ON public.goal_invites FOR DELETE USING (((select auth.uid()) = inviter_id));

-- Fix policy: goal_invites_insert_policy on goal_invites
DROP POLICY IF EXISTS "goal_invites_insert_policy" ON public.goal_invites;
CREATE POLICY "goal_invites_insert_policy" ON public.goal_invites FOR INSERT WITH CHECK (((select auth.uid()) = inviter_id));

-- Fix policy: goal_invites_select_policy on goal_invites
DROP POLICY IF EXISTS "goal_invites_select_policy" ON public.goal_invites;
CREATE POLICY "goal_invites_select_policy" ON public.goal_invites FOR SELECT USING ((((select auth.uid()) = inviter_id) OR ((select auth.uid()) = invitee_id)));

-- Fix policy: goal_invites_update_policy on goal_invites
DROP POLICY IF EXISTS "goal_invites_update_policy" ON public.goal_invites;
CREATE POLICY "goal_invites_update_policy" ON public.goal_invites FOR UPDATE USING ((((select auth.uid()) = inviter_id) OR ((select auth.uid()) = invitee_id)));

-- Fix policy: goal_suggestions_delete_policy on goal_suggestions
DROP POLICY IF EXISTS "goal_suggestions_delete_policy" ON public.goal_suggestions;
CREATE POLICY "goal_suggestions_delete_policy" ON public.goal_suggestions FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: goal_suggestions_insert_policy on goal_suggestions
DROP POLICY IF EXISTS "goal_suggestions_insert_policy" ON public.goal_suggestions;
CREATE POLICY "goal_suggestions_insert_policy" ON public.goal_suggestions FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: goal_suggestions_select_policy on goal_suggestions
DROP POLICY IF EXISTS "goal_suggestions_select_policy" ON public.goal_suggestions;
CREATE POLICY "goal_suggestions_select_policy" ON public.goal_suggestions FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: goal_suggestions_update_policy on goal_suggestions
DROP POLICY IF EXISTS "goal_suggestions_update_policy" ON public.goal_suggestions;
CREATE POLICY "goal_suggestions_update_policy" ON public.goal_suggestions FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own layouts on home_layouts
DROP POLICY IF EXISTS "Users can manage own layouts" ON public.home_layouts;
CREATE POLICY "Users can manage own layouts" ON public.home_layouts FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can delete own hormonal profile on hormonal_profiles
DROP POLICY IF EXISTS "Users can delete own hormonal profile" ON public.hormonal_profiles;
CREATE POLICY "Users can delete own hormonal profile" ON public.hormonal_profiles FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own hormonal profile on hormonal_profiles
DROP POLICY IF EXISTS "Users can insert own hormonal profile" ON public.hormonal_profiles;
CREATE POLICY "Users can insert own hormonal profile" ON public.hormonal_profiles FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own hormonal profile on hormonal_profiles
DROP POLICY IF EXISTS "Users can update own hormonal profile" ON public.hormonal_profiles;
CREATE POLICY "Users can update own hormonal profile" ON public.hormonal_profiles FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own hormonal profile on hormonal_profiles
DROP POLICY IF EXISTS "Users can view own hormonal profile" ON public.hormonal_profiles;
CREATE POLICY "Users can view own hormonal profile" ON public.hormonal_profiles FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own hormone logs on hormone_logs
DROP POLICY IF EXISTS "Users can delete own hormone logs" ON public.hormone_logs;
CREATE POLICY "Users can delete own hormone logs" ON public.hormone_logs FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own hormone logs on hormone_logs
DROP POLICY IF EXISTS "Users can insert own hormone logs" ON public.hormone_logs;
CREATE POLICY "Users can insert own hormone logs" ON public.hormone_logs FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own hormone logs on hormone_logs
DROP POLICY IF EXISTS "Users can update own hormone logs" ON public.hormone_logs;
CREATE POLICY "Users can update own hormone logs" ON public.hormone_logs FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own hormone logs on hormone_logs
DROP POLICY IF EXISTS "Users can view own hormone logs" ON public.hormone_logs;
CREATE POLICY "Users can view own hormone logs" ON public.hormone_logs FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: hydration_logs_delete_policy on hydration_logs
DROP POLICY IF EXISTS "hydration_logs_delete_policy" ON public.hydration_logs;
CREATE POLICY "hydration_logs_delete_policy" ON public.hydration_logs FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: hydration_logs_insert_policy on hydration_logs
DROP POLICY IF EXISTS "hydration_logs_insert_policy" ON public.hydration_logs;
CREATE POLICY "hydration_logs_insert_policy" ON public.hydration_logs FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: hydration_logs_select_policy on hydration_logs
DROP POLICY IF EXISTS "hydration_logs_select_policy" ON public.hydration_logs;
CREATE POLICY "hydration_logs_select_policy" ON public.hydration_logs FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: hydration_logs_service_policy on hydration_logs
DROP POLICY IF EXISTS "hydration_logs_service_policy" ON public.hydration_logs;
CREATE POLICY "hydration_logs_service_policy" ON public.hydration_logs FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: hydration_logs_update_policy on hydration_logs
DROP POLICY IF EXISTS "hydration_logs_update_policy" ON public.hydration_logs;
CREATE POLICY "hydration_logs_update_policy" ON public.hydration_logs FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own injuries on injuries
DROP POLICY IF EXISTS "Users can manage own injuries" ON public.injuries;
CREATE POLICY "Users can manage own injuries" ON public.injuries FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can manage own injury_history on injury_history
DROP POLICY IF EXISTS "Users can manage own injury_history" ON public.injury_history;
CREATE POLICY "Users can manage own injury_history" ON public.injury_history FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: injury_rehab_delete_policy on injury_rehab_exercises
DROP POLICY IF EXISTS "injury_rehab_delete_policy" ON public.injury_rehab_exercises;
CREATE POLICY "injury_rehab_delete_policy" ON public.injury_rehab_exercises FOR DELETE USING ((injury_id IN ( SELECT user_injuries.id FROM user_injuries WHERE (user_injuries.user_id = (select auth.uid())))));

-- Fix policy: injury_rehab_insert_policy on injury_rehab_exercises
DROP POLICY IF EXISTS "injury_rehab_insert_policy" ON public.injury_rehab_exercises;
CREATE POLICY "injury_rehab_insert_policy" ON public.injury_rehab_exercises FOR INSERT WITH CHECK ((injury_id IN ( SELECT user_injuries.id FROM user_injuries WHERE (user_injuries.user_id = (select auth.uid())))));

-- Fix policy: injury_rehab_select_policy on injury_rehab_exercises
DROP POLICY IF EXISTS "injury_rehab_select_policy" ON public.injury_rehab_exercises;
CREATE POLICY "injury_rehab_select_policy" ON public.injury_rehab_exercises FOR SELECT USING ((injury_id IN ( SELECT user_injuries.id FROM user_injuries WHERE (user_injuries.user_id = (select auth.uid())))));

-- Fix policy: injury_rehab_update_policy on injury_rehab_exercises
DROP POLICY IF EXISTS "injury_rehab_update_policy" ON public.injury_rehab_exercises;
CREATE POLICY "injury_rehab_update_policy" ON public.injury_rehab_exercises FOR UPDATE USING ((injury_id IN ( SELECT user_injuries.id FROM user_injuries WHERE (user_injuries.user_id = (select auth.uid())))));

-- Fix policy: injury_updates_delete_policy on injury_updates
DROP POLICY IF EXISTS "injury_updates_delete_policy" ON public.injury_updates;
CREATE POLICY "injury_updates_delete_policy" ON public.injury_updates FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: injury_updates_insert_policy on injury_updates
DROP POLICY IF EXISTS "injury_updates_insert_policy" ON public.injury_updates;
CREATE POLICY "injury_updates_insert_policy" ON public.injury_updates FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: injury_updates_select_policy on injury_updates
DROP POLICY IF EXISTS "injury_updates_select_policy" ON public.injury_updates;
CREATE POLICY "injury_updates_select_policy" ON public.injury_updates FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: injury_updates_update_policy on injury_updates
DROP POLICY IF EXISTS "injury_updates_update_policy" ON public.injury_updates;
CREATE POLICY "injury_updates_update_policy" ON public.injury_updates FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: insulin_doses_delete on insulin_doses
DROP POLICY IF EXISTS "insulin_doses_delete" ON public.insulin_doses;
CREATE POLICY "insulin_doses_delete" ON public.insulin_doses FOR DELETE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = insulin_doses.user_id))));

-- Fix policy: insulin_doses_insert on insulin_doses
DROP POLICY IF EXISTS "insulin_doses_insert" ON public.insulin_doses;
CREATE POLICY "insulin_doses_insert" ON public.insulin_doses FOR INSERT WITH CHECK (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = insulin_doses.user_id))));

-- Fix policy: insulin_doses_select on insulin_doses
DROP POLICY IF EXISTS "insulin_doses_select" ON public.insulin_doses;
CREATE POLICY "insulin_doses_select" ON public.insulin_doses FOR SELECT USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = insulin_doses.user_id))));

-- Fix policy: insulin_doses_update on insulin_doses
DROP POLICY IF EXISTS "insulin_doses_update" ON public.insulin_doses;
CREATE POLICY "insulin_doses_update" ON public.insulin_doses FOR UPDATE USING (((select auth.uid()) = ( SELECT users.auth_id FROM users WHERE (users.id = insulin_doses.user_id))));

-- Fix policy: Users can delete own kegel preferences on kegel_preferences
DROP POLICY IF EXISTS "Users can delete own kegel preferences" ON public.kegel_preferences;
CREATE POLICY "Users can delete own kegel preferences" ON public.kegel_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own kegel preferences on kegel_preferences
DROP POLICY IF EXISTS "Users can insert own kegel preferences" ON public.kegel_preferences;
CREATE POLICY "Users can insert own kegel preferences" ON public.kegel_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own kegel preferences on kegel_preferences
DROP POLICY IF EXISTS "Users can update own kegel preferences" ON public.kegel_preferences;
CREATE POLICY "Users can update own kegel preferences" ON public.kegel_preferences FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own kegel preferences on kegel_preferences
DROP POLICY IF EXISTS "Users can view own kegel preferences" ON public.kegel_preferences;
CREATE POLICY "Users can view own kegel preferences" ON public.kegel_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own kegel sessions on kegel_sessions
DROP POLICY IF EXISTS "Users can delete own kegel sessions" ON public.kegel_sessions;
CREATE POLICY "Users can delete own kegel sessions" ON public.kegel_sessions FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own kegel sessions on kegel_sessions
DROP POLICY IF EXISTS "Users can insert own kegel sessions" ON public.kegel_sessions;
CREATE POLICY "Users can insert own kegel sessions" ON public.kegel_sessions FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own kegel sessions on kegel_sessions
DROP POLICY IF EXISTS "Users can update own kegel sessions" ON public.kegel_sessions;
CREATE POLICY "Users can update own kegel sessions" ON public.kegel_sessions FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own kegel sessions on kegel_sessions
DROP POLICY IF EXISTS "Users can view own kegel sessions" ON public.kegel_sessions;
CREATE POLICY "Users can view own kegel sessions" ON public.kegel_sessions FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: meal_templates_delete_policy on meal_plan_templates
DROP POLICY IF EXISTS "meal_templates_delete_policy" ON public.meal_plan_templates;
CREATE POLICY "meal_templates_delete_policy" ON public.meal_plan_templates FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: meal_templates_insert_policy on meal_plan_templates
DROP POLICY IF EXISTS "meal_templates_insert_policy" ON public.meal_plan_templates;
CREATE POLICY "meal_templates_insert_policy" ON public.meal_plan_templates FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: meal_templates_select_policy on meal_plan_templates
DROP POLICY IF EXISTS "meal_templates_select_policy" ON public.meal_plan_templates;
CREATE POLICY "meal_templates_select_policy" ON public.meal_plan_templates FOR SELECT USING ((user_id = (select auth.uid())));

-- Fix policy: meal_templates_update_policy on meal_plan_templates
DROP POLICY IF EXISTS "meal_templates_update_policy" ON public.meal_plan_templates;
CREATE POLICY "meal_templates_update_policy" ON public.meal_plan_templates FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can delete own templates on meal_templates
DROP POLICY IF EXISTS "Users can delete own templates" ON public.meal_templates;
CREATE POLICY "Users can delete own templates" ON public.meal_templates FOR DELETE USING ((((select auth.uid()) = user_id) AND (is_system_template = false)));

-- Fix policy: Users can insert own templates on meal_templates
DROP POLICY IF EXISTS "Users can insert own templates" ON public.meal_templates;
CREATE POLICY "Users can insert own templates" ON public.meal_templates FOR INSERT WITH CHECK ((((select auth.uid()) = user_id) AND (is_system_template = false)));

-- Fix policy: Users can update own templates on meal_templates
DROP POLICY IF EXISTS "Users can update own templates" ON public.meal_templates;
CREATE POLICY "Users can update own templates" ON public.meal_templates FOR UPDATE USING ((((select auth.uid()) = user_id) AND (is_system_template = false)));

-- Fix policy: Users can view own and system templates on meal_templates
DROP POLICY IF EXISTS "Users can view own and system templates" ON public.meal_templates;
CREATE POLICY "Users can view own and system templates" ON public.meal_templates FOR SELECT USING ((((select auth.uid()) = user_id) OR (is_system_template = true)));

-- Fix policy: Service role has full access to mobility_exercise_tracking on mobility_exercise_tracking
DROP POLICY IF EXISTS "Service role has full access to mobility_exercise_tracking" ON public.mobility_exercise_tracking;
CREATE POLICY "Service role has full access to mobility_exercise_tracking" ON public.mobility_exercise_tracking FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert their own mobility tracking on mobility_exercise_tracking
DROP POLICY IF EXISTS "Users can insert their own mobility tracking" ON public.mobility_exercise_tracking;
CREATE POLICY "Users can insert their own mobility tracking" ON public.mobility_exercise_tracking FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own mobility tracking on mobility_exercise_tracking
DROP POLICY IF EXISTS "Users can view their own mobility tracking" ON public.mobility_exercise_tracking;
CREATE POLICY "Users can view their own mobility tracking" ON public.mobility_exercise_tracking FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: mood_checkins_insert_policy on mood_checkins
DROP POLICY IF EXISTS "mood_checkins_insert_policy" ON public.mood_checkins;
CREATE POLICY "mood_checkins_insert_policy" ON public.mood_checkins FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: mood_checkins_select_policy on mood_checkins
DROP POLICY IF EXISTS "mood_checkins_select_policy" ON public.mood_checkins;
CREATE POLICY "mood_checkins_select_policy" ON public.mood_checkins FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: mood_checkins_service_policy on mood_checkins
DROP POLICY IF EXISTS "mood_checkins_service_policy" ON public.mood_checkins;
CREATE POLICY "mood_checkins_service_policy" ON public.mood_checkins FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: mood_checkins_update_policy on mood_checkins
DROP POLICY IF EXISTS "mood_checkins_update_policy" ON public.mood_checkins;
CREATE POLICY "mood_checkins_update_policy" ON public.mood_checkins FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: muscle_analytics_logs_insert on muscle_analytics_logs
DROP POLICY IF EXISTS "muscle_analytics_logs_insert" ON public.muscle_analytics_logs;
CREATE POLICY "muscle_analytics_logs_insert" ON public.muscle_analytics_logs FOR INSERT  TO authenticated WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: muscle_analytics_logs_select on muscle_analytics_logs
DROP POLICY IF EXISTS "muscle_analytics_logs_select" ON public.muscle_analytics_logs;
CREATE POLICY "muscle_analytics_logs_select" ON public.muscle_analytics_logs FOR SELECT  TO authenticated USING (((select auth.uid()) = user_id));

-- Fix policy: volume_caps_policy on muscle_volume_caps
DROP POLICY IF EXISTS "volume_caps_policy" ON public.muscle_volume_caps;
CREATE POLICY "volume_caps_policy" ON public.muscle_volume_caps FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: neat_achievements_service_policy on neat_achievements
DROP POLICY IF EXISTS "neat_achievements_service_policy" ON public.neat_achievements;
CREATE POLICY "neat_achievements_service_policy" ON public.neat_achievements FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: neat_daily_scores_delete_policy on neat_daily_scores
DROP POLICY IF EXISTS "neat_daily_scores_delete_policy" ON public.neat_daily_scores;
CREATE POLICY "neat_daily_scores_delete_policy" ON public.neat_daily_scores FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_daily_scores_insert_policy on neat_daily_scores
DROP POLICY IF EXISTS "neat_daily_scores_insert_policy" ON public.neat_daily_scores;
CREATE POLICY "neat_daily_scores_insert_policy" ON public.neat_daily_scores FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_daily_scores_select_policy on neat_daily_scores
DROP POLICY IF EXISTS "neat_daily_scores_select_policy" ON public.neat_daily_scores;
CREATE POLICY "neat_daily_scores_select_policy" ON public.neat_daily_scores FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_daily_scores_service_policy on neat_daily_scores
DROP POLICY IF EXISTS "neat_daily_scores_service_policy" ON public.neat_daily_scores;
CREATE POLICY "neat_daily_scores_service_policy" ON public.neat_daily_scores FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: neat_daily_scores_update_policy on neat_daily_scores
DROP POLICY IF EXISTS "neat_daily_scores_update_policy" ON public.neat_daily_scores;
CREATE POLICY "neat_daily_scores_update_policy" ON public.neat_daily_scores FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_goals_delete_policy on neat_goals
DROP POLICY IF EXISTS "neat_goals_delete_policy" ON public.neat_goals;
CREATE POLICY "neat_goals_delete_policy" ON public.neat_goals FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_goals_insert_policy on neat_goals
DROP POLICY IF EXISTS "neat_goals_insert_policy" ON public.neat_goals;
CREATE POLICY "neat_goals_insert_policy" ON public.neat_goals FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_goals_select_policy on neat_goals
DROP POLICY IF EXISTS "neat_goals_select_policy" ON public.neat_goals;
CREATE POLICY "neat_goals_select_policy" ON public.neat_goals FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_goals_service_policy on neat_goals
DROP POLICY IF EXISTS "neat_goals_service_policy" ON public.neat_goals;
CREATE POLICY "neat_goals_service_policy" ON public.neat_goals FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: neat_goals_update_policy on neat_goals
DROP POLICY IF EXISTS "neat_goals_update_policy" ON public.neat_goals;
CREATE POLICY "neat_goals_update_policy" ON public.neat_goals FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_hourly_activity_delete_policy on neat_hourly_activity
DROP POLICY IF EXISTS "neat_hourly_activity_delete_policy" ON public.neat_hourly_activity;
CREATE POLICY "neat_hourly_activity_delete_policy" ON public.neat_hourly_activity FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_hourly_activity_insert_policy on neat_hourly_activity
DROP POLICY IF EXISTS "neat_hourly_activity_insert_policy" ON public.neat_hourly_activity;
CREATE POLICY "neat_hourly_activity_insert_policy" ON public.neat_hourly_activity FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_hourly_activity_select_policy on neat_hourly_activity
DROP POLICY IF EXISTS "neat_hourly_activity_select_policy" ON public.neat_hourly_activity;
CREATE POLICY "neat_hourly_activity_select_policy" ON public.neat_hourly_activity FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_hourly_activity_service_policy on neat_hourly_activity
DROP POLICY IF EXISTS "neat_hourly_activity_service_policy" ON public.neat_hourly_activity;
CREATE POLICY "neat_hourly_activity_service_policy" ON public.neat_hourly_activity FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: neat_hourly_activity_update_policy on neat_hourly_activity
DROP POLICY IF EXISTS "neat_hourly_activity_update_policy" ON public.neat_hourly_activity;
CREATE POLICY "neat_hourly_activity_update_policy" ON public.neat_hourly_activity FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_reminder_preferences_delete_policy on neat_reminder_preferences
DROP POLICY IF EXISTS "neat_reminder_preferences_delete_policy" ON public.neat_reminder_preferences;
CREATE POLICY "neat_reminder_preferences_delete_policy" ON public.neat_reminder_preferences FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_reminder_preferences_insert_policy on neat_reminder_preferences
DROP POLICY IF EXISTS "neat_reminder_preferences_insert_policy" ON public.neat_reminder_preferences;
CREATE POLICY "neat_reminder_preferences_insert_policy" ON public.neat_reminder_preferences FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_reminder_preferences_select_policy on neat_reminder_preferences
DROP POLICY IF EXISTS "neat_reminder_preferences_select_policy" ON public.neat_reminder_preferences;
CREATE POLICY "neat_reminder_preferences_select_policy" ON public.neat_reminder_preferences FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_reminder_preferences_service_policy on neat_reminder_preferences
DROP POLICY IF EXISTS "neat_reminder_preferences_service_policy" ON public.neat_reminder_preferences;
CREATE POLICY "neat_reminder_preferences_service_policy" ON public.neat_reminder_preferences FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: neat_reminder_preferences_update_policy on neat_reminder_preferences
DROP POLICY IF EXISTS "neat_reminder_preferences_update_policy" ON public.neat_reminder_preferences;
CREATE POLICY "neat_reminder_preferences_update_policy" ON public.neat_reminder_preferences FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_streaks_delete_policy on neat_streaks
DROP POLICY IF EXISTS "neat_streaks_delete_policy" ON public.neat_streaks;
CREATE POLICY "neat_streaks_delete_policy" ON public.neat_streaks FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_streaks_insert_policy on neat_streaks
DROP POLICY IF EXISTS "neat_streaks_insert_policy" ON public.neat_streaks;
CREATE POLICY "neat_streaks_insert_policy" ON public.neat_streaks FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_streaks_select_policy on neat_streaks
DROP POLICY IF EXISTS "neat_streaks_select_policy" ON public.neat_streaks;
CREATE POLICY "neat_streaks_select_policy" ON public.neat_streaks FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_streaks_service_policy on neat_streaks
DROP POLICY IF EXISTS "neat_streaks_service_policy" ON public.neat_streaks;
CREATE POLICY "neat_streaks_service_policy" ON public.neat_streaks FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: neat_streaks_update_policy on neat_streaks
DROP POLICY IF EXISTS "neat_streaks_update_policy" ON public.neat_streaks;
CREATE POLICY "neat_streaks_update_policy" ON public.neat_streaks FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_weekly_summaries_delete_policy on neat_weekly_summaries
DROP POLICY IF EXISTS "neat_weekly_summaries_delete_policy" ON public.neat_weekly_summaries;
CREATE POLICY "neat_weekly_summaries_delete_policy" ON public.neat_weekly_summaries FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_weekly_summaries_insert_policy on neat_weekly_summaries
DROP POLICY IF EXISTS "neat_weekly_summaries_insert_policy" ON public.neat_weekly_summaries;
CREATE POLICY "neat_weekly_summaries_insert_policy" ON public.neat_weekly_summaries FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_weekly_summaries_select_policy on neat_weekly_summaries
DROP POLICY IF EXISTS "neat_weekly_summaries_select_policy" ON public.neat_weekly_summaries;
CREATE POLICY "neat_weekly_summaries_select_policy" ON public.neat_weekly_summaries FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: neat_weekly_summaries_service_policy on neat_weekly_summaries
DROP POLICY IF EXISTS "neat_weekly_summaries_service_policy" ON public.neat_weekly_summaries;
CREATE POLICY "neat_weekly_summaries_service_policy" ON public.neat_weekly_summaries FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: neat_weekly_summaries_update_policy on neat_weekly_summaries
DROP POLICY IF EXISTS "neat_weekly_summaries_update_policy" ON public.neat_weekly_summaries;
CREATE POLICY "neat_weekly_summaries_update_policy" ON public.neat_weekly_summaries FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: notification_preferences_insert_policy on notification_preferences
DROP POLICY IF EXISTS "notification_preferences_insert_policy" ON public.notification_preferences;
CREATE POLICY "notification_preferences_insert_policy" ON public.notification_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: notification_preferences_select_policy on notification_preferences
DROP POLICY IF EXISTS "notification_preferences_select_policy" ON public.notification_preferences;
CREATE POLICY "notification_preferences_select_policy" ON public.notification_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: notification_preferences_service_policy on notification_preferences
DROP POLICY IF EXISTS "notification_preferences_service_policy" ON public.notification_preferences;
CREATE POLICY "notification_preferences_service_policy" ON public.notification_preferences FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: notification_preferences_update_policy on notification_preferences
DROP POLICY IF EXISTS "notification_preferences_update_policy" ON public.notification_preferences;
CREATE POLICY "notification_preferences_update_policy" ON public.notification_preferences FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: notification_queue_service_policy on notification_queue
DROP POLICY IF EXISTS "notification_queue_service_policy" ON public.notification_queue;
CREATE POLICY "notification_queue_service_policy" ON public.notification_queue FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Service role can manage nutrient RDAs on nutrient_rdas
DROP POLICY IF EXISTS "Service role can manage nutrient RDAs" ON public.nutrient_rdas;
CREATE POLICY "Service role can manage nutrient RDAs" ON public.nutrient_rdas FOR ALL USING (((select auth.role()) = 'service_role'::text)) WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Fix policy: nutrition_preferences_delete_policy on nutrition_preferences
DROP POLICY IF EXISTS "nutrition_preferences_delete_policy" ON public.nutrition_preferences;
CREATE POLICY "nutrition_preferences_delete_policy" ON public.nutrition_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: nutrition_preferences_insert_policy on nutrition_preferences
DROP POLICY IF EXISTS "nutrition_preferences_insert_policy" ON public.nutrition_preferences;
CREATE POLICY "nutrition_preferences_insert_policy" ON public.nutrition_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: nutrition_preferences_select_policy on nutrition_preferences
DROP POLICY IF EXISTS "nutrition_preferences_select_policy" ON public.nutrition_preferences;
CREATE POLICY "nutrition_preferences_select_policy" ON public.nutrition_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: nutrition_preferences_update_policy on nutrition_preferences
DROP POLICY IF EXISTS "nutrition_preferences_update_policy" ON public.nutrition_preferences;
CREATE POLICY "nutrition_preferences_update_policy" ON public.nutrition_preferences FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: nutrition_scores_insert_policy on nutrition_scores
DROP POLICY IF EXISTS "nutrition_scores_insert_policy" ON public.nutrition_scores;
CREATE POLICY "nutrition_scores_insert_policy" ON public.nutrition_scores FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: nutrition_scores_select_policy on nutrition_scores
DROP POLICY IF EXISTS "nutrition_scores_select_policy" ON public.nutrition_scores;
CREATE POLICY "nutrition_scores_select_policy" ON public.nutrition_scores FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: nutrition_scores_service_policy on nutrition_scores
DROP POLICY IF EXISTS "nutrition_scores_service_policy" ON public.nutrition_scores;
CREATE POLICY "nutrition_scores_service_policy" ON public.nutrition_scores FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: nutrition_streaks_delete_policy on nutrition_streaks
DROP POLICY IF EXISTS "nutrition_streaks_delete_policy" ON public.nutrition_streaks;
CREATE POLICY "nutrition_streaks_delete_policy" ON public.nutrition_streaks FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: nutrition_streaks_insert_policy on nutrition_streaks
DROP POLICY IF EXISTS "nutrition_streaks_insert_policy" ON public.nutrition_streaks;
CREATE POLICY "nutrition_streaks_insert_policy" ON public.nutrition_streaks FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: nutrition_streaks_select_policy on nutrition_streaks
DROP POLICY IF EXISTS "nutrition_streaks_select_policy" ON public.nutrition_streaks;
CREATE POLICY "nutrition_streaks_select_policy" ON public.nutrition_streaks FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: nutrition_streaks_update_policy on nutrition_streaks
DROP POLICY IF EXISTS "nutrition_streaks_update_policy" ON public.nutrition_streaks;
CREATE POLICY "nutrition_streaks_update_policy" ON public.nutrition_streaks FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Service role full access onboarding on onboarding_analytics
DROP POLICY IF EXISTS "Service role full access onboarding" ON public.onboarding_analytics;
CREATE POLICY "Service role full access onboarding" ON public.onboarding_analytics FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own onboarding analytics on onboarding_analytics
DROP POLICY IF EXISTS "Users can insert own onboarding analytics" ON public.onboarding_analytics;
CREATE POLICY "Users can insert own onboarding analytics" ON public.onboarding_analytics FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))) OR (user_id IS NULL)));

-- Fix policy: Users can read own onboarding analytics on onboarding_analytics
DROP POLICY IF EXISTS "Users can read own onboarding analytics" ON public.onboarding_analytics;
CREATE POLICY "Users can read own onboarding analytics" ON public.onboarding_analytics FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Service role full access transactions on payment_transactions
DROP POLICY IF EXISTS "Service role full access transactions" ON public.payment_transactions;
CREATE POLICY "Service role full access transactions" ON public.payment_transactions FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can read own transactions on payment_transactions
DROP POLICY IF EXISTS "Users can read own transactions" ON public.payment_transactions;
CREATE POLICY "Users can read own transactions" ON public.payment_transactions FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can insert own impressions on paywall_impressions
DROP POLICY IF EXISTS "Users can insert own impressions" ON public.paywall_impressions;
CREATE POLICY "Users can insert own impressions" ON public.paywall_impressions FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))) OR (user_id IS NULL)));

-- Fix policy: Users can read own impressions on paywall_impressions
DROP POLICY IF EXISTS "Users can read own impressions" ON public.paywall_impressions;
CREATE POLICY "Users can read own impressions" ON public.paywall_impressions FOR SELECT USING (((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))) OR (user_id IS NULL)));

-- Fix policy: Users can manage own performance_logs on performance_logs
DROP POLICY IF EXISTS "Users can manage own performance_logs" ON public.performance_logs;
CREATE POLICY "Users can manage own performance_logs" ON public.performance_logs FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can manage their own records on personal_goal_records
DROP POLICY IF EXISTS "Users can manage their own records" ON public.personal_goal_records;
CREATE POLICY "Users can manage their own records" ON public.personal_goal_records FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: personal_records_insert_policy on personal_records
DROP POLICY IF EXISTS "personal_records_insert_policy" ON public.personal_records;
CREATE POLICY "personal_records_insert_policy" ON public.personal_records FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: personal_records_select_policy on personal_records
DROP POLICY IF EXISTS "personal_records_select_policy" ON public.personal_records;
CREATE POLICY "personal_records_select_policy" ON public.personal_records FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: personal_records_service_policy on personal_records
DROP POLICY IF EXISTS "personal_records_service_policy" ON public.personal_records;
CREATE POLICY "personal_records_service_policy" ON public.personal_records FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: photo_comparisons_delete_policy on photo_comparisons
DROP POLICY IF EXISTS "photo_comparisons_delete_policy" ON public.photo_comparisons;
CREATE POLICY "photo_comparisons_delete_policy" ON public.photo_comparisons FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: photo_comparisons_insert_policy on photo_comparisons
DROP POLICY IF EXISTS "photo_comparisons_insert_policy" ON public.photo_comparisons;
CREATE POLICY "photo_comparisons_insert_policy" ON public.photo_comparisons FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: photo_comparisons_select_policy on photo_comparisons
DROP POLICY IF EXISTS "photo_comparisons_select_policy" ON public.photo_comparisons;
CREATE POLICY "photo_comparisons_select_policy" ON public.photo_comparisons FOR SELECT USING ((((select auth.uid()) = user_id) OR (visibility = 'public'::text)));

-- Fix policy: photo_comparisons_service_policy on photo_comparisons
DROP POLICY IF EXISTS "photo_comparisons_service_policy" ON public.photo_comparisons;
CREATE POLICY "photo_comparisons_service_policy" ON public.photo_comparisons FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: photo_comparisons_update_policy on photo_comparisons
DROP POLICY IF EXISTS "photo_comparisons_update_policy" ON public.photo_comparisons;
CREATE POLICY "photo_comparisons_update_policy" ON public.photo_comparisons FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: plan_previews_service_policy on plan_previews
DROP POLICY IF EXISTS "plan_previews_service_policy" ON public.plan_previews;
CREATE POLICY "plan_previews_service_policy" ON public.plan_previews FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: plan_previews_update_policy on plan_previews
DROP POLICY IF EXISTS "plan_previews_update_policy" ON public.plan_previews;
CREATE POLICY "plan_previews_update_policy" ON public.plan_previews FOR UPDATE USING ((((select auth.uid()) = user_id) OR (user_id IS NULL)));

-- Fix policy: plan_previews_user_policy on plan_previews
DROP POLICY IF EXISTS "plan_previews_user_policy" ON public.plan_previews;
CREATE POLICY "plan_previews_user_policy" ON public.plan_previews FOR SELECT USING ((((select auth.uid()) = user_id) OR (user_id IS NULL)));

-- Fix policy: Service role has full access to preference_impact_log on preference_impact_log
DROP POLICY IF EXISTS "Service role has full access to preference_impact_log" ON public.preference_impact_log;
CREATE POLICY "Service role has full access to preference_impact_log" ON public.preference_impact_log FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can view their own preference impact logs on preference_impact_log
DROP POLICY IF EXISTS "Users can view their own preference impact logs" ON public.preference_impact_log;
CREATE POLICY "Users can view their own preference impact logs" ON public.preference_impact_log FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own program history on program_history
DROP POLICY IF EXISTS "Users can delete own program history" ON public.program_history;
CREATE POLICY "Users can delete own program history" ON public.program_history FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own program history on program_history
DROP POLICY IF EXISTS "Users can insert own program history" ON public.program_history;
CREATE POLICY "Users can insert own program history" ON public.program_history FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own program history on program_history
DROP POLICY IF EXISTS "Users can update own program history" ON public.program_history;
CREATE POLICY "Users can update own program history" ON public.program_history FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own program history on program_history
DROP POLICY IF EXISTS "Users can view own program history" ON public.program_history;
CREATE POLICY "Users can view own program history" ON public.program_history FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: program_variants_service_policy on program_variants
DROP POLICY IF EXISTS "program_variants_service_policy" ON public.program_variants;
CREATE POLICY "program_variants_service_policy" ON public.program_variants FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: programs_service_policy on programs
DROP POLICY IF EXISTS "programs_service_policy" ON public.programs;
CREATE POLICY "programs_service_policy" ON public.programs FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own progress chart views on progress_charts_views
DROP POLICY IF EXISTS "Users can insert own progress chart views" ON public.progress_charts_views;
CREATE POLICY "Users can insert own progress chart views" ON public.progress_charts_views FOR INSERT  TO authenticated WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own progress chart views on progress_charts_views
DROP POLICY IF EXISTS "Users can view own progress chart views" ON public.progress_charts_views;
CREATE POLICY "Users can view own progress chart views" ON public.progress_charts_views FOR SELECT  TO authenticated USING (((select auth.uid()) = user_id));

-- Fix policy: progress_photos_delete_policy on progress_photos
DROP POLICY IF EXISTS "progress_photos_delete_policy" ON public.progress_photos;
CREATE POLICY "progress_photos_delete_policy" ON public.progress_photos FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: progress_photos_insert_policy on progress_photos
DROP POLICY IF EXISTS "progress_photos_insert_policy" ON public.progress_photos;
CREATE POLICY "progress_photos_insert_policy" ON public.progress_photos FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: progress_photos_select_policy on progress_photos
DROP POLICY IF EXISTS "progress_photos_select_policy" ON public.progress_photos;
CREATE POLICY "progress_photos_select_policy" ON public.progress_photos FOR SELECT USING ((((select auth.uid()) = user_id) OR (visibility = 'public'::text) OR ((visibility = 'shared'::text) AND ((select auth.role()) = 'authenticated'::text))));

-- Fix policy: progress_photos_service_policy on progress_photos
DROP POLICY IF EXISTS "progress_photos_service_policy" ON public.progress_photos;
CREATE POLICY "progress_photos_service_policy" ON public.progress_photos FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: progress_photos_update_policy on progress_photos
DROP POLICY IF EXISTS "progress_photos_update_policy" ON public.progress_photos;
CREATE POLICY "progress_photos_update_policy" ON public.progress_photos FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users manage own progression history on progression_history
DROP POLICY IF EXISTS "Users manage own progression history" ON public.progression_history;
CREATE POLICY "Users manage own progression history" ON public.progression_history FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own quick log history on quick_log_history
DROP POLICY IF EXISTS "Users can delete own quick log history" ON public.quick_log_history;
CREATE POLICY "Users can delete own quick log history" ON public.quick_log_history FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own quick log history on quick_log_history
DROP POLICY IF EXISTS "Users can insert own quick log history" ON public.quick_log_history;
CREATE POLICY "Users can insert own quick log history" ON public.quick_log_history FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own quick log history on quick_log_history
DROP POLICY IF EXISTS "Users can update own quick log history" ON public.quick_log_history;
CREATE POLICY "Users can update own quick log history" ON public.quick_log_history FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own quick log history on quick_log_history
DROP POLICY IF EXISTS "Users can view own quick log history" ON public.quick_log_history;
CREATE POLICY "Users can view own quick log history" ON public.quick_log_history FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own quick workout preferences on quick_workout_preferences
DROP POLICY IF EXISTS "Users can delete own quick workout preferences" ON public.quick_workout_preferences;
CREATE POLICY "Users can delete own quick workout preferences" ON public.quick_workout_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own quick workout preferences on quick_workout_preferences
DROP POLICY IF EXISTS "Users can insert own quick workout preferences" ON public.quick_workout_preferences;
CREATE POLICY "Users can insert own quick workout preferences" ON public.quick_workout_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own quick workout preferences on quick_workout_preferences
DROP POLICY IF EXISTS "Users can update own quick workout preferences" ON public.quick_workout_preferences;
CREATE POLICY "Users can update own quick workout preferences" ON public.quick_workout_preferences FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own quick workout preferences on quick_workout_preferences
DROP POLICY IF EXISTS "Users can view own quick workout preferences" ON public.quick_workout_preferences;
CREATE POLICY "Users can view own quick workout preferences" ON public.quick_workout_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: readiness_scores_insert_policy on readiness_scores
DROP POLICY IF EXISTS "readiness_scores_insert_policy" ON public.readiness_scores;
CREATE POLICY "readiness_scores_insert_policy" ON public.readiness_scores FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: readiness_scores_select_policy on readiness_scores
DROP POLICY IF EXISTS "readiness_scores_select_policy" ON public.readiness_scores;
CREATE POLICY "readiness_scores_select_policy" ON public.readiness_scores FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: readiness_scores_service_policy on readiness_scores
DROP POLICY IF EXISTS "readiness_scores_service_policy" ON public.readiness_scores;
CREATE POLICY "readiness_scores_service_policy" ON public.readiness_scores FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: readiness_scores_update_policy on readiness_scores
DROP POLICY IF EXISTS "readiness_scores_update_policy" ON public.readiness_scores;
CREATE POLICY "readiness_scores_update_policy" ON public.readiness_scores FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can add ingredients to their recipes on recipe_ingredients
DROP POLICY IF EXISTS "Users can add ingredients to their recipes" ON public.recipe_ingredients;
CREATE POLICY "Users can add ingredients to their recipes" ON public.recipe_ingredients FOR INSERT WITH CHECK ((EXISTS ( SELECT 1 FROM user_recipes WHERE ((user_recipes.id = recipe_ingredients.recipe_id) AND (user_recipes.user_id = (select auth.uid()))))));

-- Fix policy: Users can delete ingredients from their recipes on recipe_ingredients
DROP POLICY IF EXISTS "Users can delete ingredients from their recipes" ON public.recipe_ingredients;
CREATE POLICY "Users can delete ingredients from their recipes" ON public.recipe_ingredients FOR DELETE USING ((EXISTS ( SELECT 1 FROM user_recipes WHERE ((user_recipes.id = recipe_ingredients.recipe_id) AND (user_recipes.user_id = (select auth.uid()))))));

-- Fix policy: Users can update ingredients of their recipes on recipe_ingredients
DROP POLICY IF EXISTS "Users can update ingredients of their recipes" ON public.recipe_ingredients;
CREATE POLICY "Users can update ingredients of their recipes" ON public.recipe_ingredients FOR UPDATE USING ((EXISTS ( SELECT 1 FROM user_recipes WHERE ((user_recipes.id = recipe_ingredients.recipe_id) AND (user_recipes.user_id = (select auth.uid()))))));

-- Fix policy: Users can view ingredients of accessible recipes on recipe_ingredients
DROP POLICY IF EXISTS "Users can view ingredients of accessible recipes" ON public.recipe_ingredients;
CREATE POLICY "Users can view ingredients of accessible recipes" ON public.recipe_ingredients FOR SELECT USING ((EXISTS ( SELECT 1 FROM user_recipes WHERE ((user_recipes.id = recipe_ingredients.recipe_id) AND ((user_recipes.user_id = (select auth.uid())) OR (user_recipes.is_public = true))))));

-- Fix policy: recipe_suggestion_sessions_insert_policy on recipe_suggestion_sessions
DROP POLICY IF EXISTS "recipe_suggestion_sessions_insert_policy" ON public.recipe_suggestion_sessions;
CREATE POLICY "recipe_suggestion_sessions_insert_policy" ON public.recipe_suggestion_sessions FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: recipe_suggestion_sessions_select_policy on recipe_suggestion_sessions
DROP POLICY IF EXISTS "recipe_suggestion_sessions_select_policy" ON public.recipe_suggestion_sessions;
CREATE POLICY "recipe_suggestion_sessions_select_policy" ON public.recipe_suggestion_sessions FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: recipe_suggestions_delete_policy on recipe_suggestions
DROP POLICY IF EXISTS "recipe_suggestions_delete_policy" ON public.recipe_suggestions;
CREATE POLICY "recipe_suggestions_delete_policy" ON public.recipe_suggestions FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: recipe_suggestions_insert_policy on recipe_suggestions
DROP POLICY IF EXISTS "recipe_suggestions_insert_policy" ON public.recipe_suggestions;
CREATE POLICY "recipe_suggestions_insert_policy" ON public.recipe_suggestions FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: recipe_suggestions_select_policy on recipe_suggestions
DROP POLICY IF EXISTS "recipe_suggestions_select_policy" ON public.recipe_suggestions;
CREATE POLICY "recipe_suggestions_select_policy" ON public.recipe_suggestions FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: recipe_suggestions_update_policy on recipe_suggestions
DROP POLICY IF EXISTS "recipe_suggestions_update_policy" ON public.recipe_suggestions;
CREATE POLICY "recipe_suggestions_update_policy" ON public.recipe_suggestions FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Service role full access refund requests on refund_requests
DROP POLICY IF EXISTS "Service role full access refund requests" ON public.refund_requests;
CREATE POLICY "Service role full access refund requests" ON public.refund_requests FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can create own refund requests on refund_requests
DROP POLICY IF EXISTS "Users can create own refund requests" ON public.refund_requests;
CREATE POLICY "Users can create own refund requests" ON public.refund_requests FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can read own refund requests on refund_requests
DROP POLICY IF EXISTS "Users can read own refund requests" ON public.refund_requests;
CREATE POLICY "Users can read own refund requests" ON public.refund_requests FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can insert their own rest intervals on rest_intervals
DROP POLICY IF EXISTS "Users can insert their own rest intervals" ON public.rest_intervals;
CREATE POLICY "Users can insert their own rest intervals" ON public.rest_intervals FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own rest intervals on rest_intervals
DROP POLICY IF EXISTS "Users can view their own rest intervals" ON public.rest_intervals;
CREATE POLICY "Users can view their own rest intervals" ON public.rest_intervals FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Service role full access to retention_offers_accepted on retention_offers_accepted
DROP POLICY IF EXISTS "Service role full access to retention_offers_accepted" ON public.retention_offers_accepted;
CREATE POLICY "Service role full access to retention_offers_accepted" ON public.retention_offers_accepted FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own retention offers on retention_offers_accepted
DROP POLICY IF EXISTS "Users can insert own retention offers" ON public.retention_offers_accepted;
CREATE POLICY "Users can insert own retention offers" ON public.retention_offers_accepted FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own retention offers on retention_offers_accepted
DROP POLICY IF EXISTS "Users can view own retention offers" ON public.retention_offers_accepted;
CREATE POLICY "Users can view own retention offers" ON public.retention_offers_accepted FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: s3_video_paths_service_policy on s3_video_paths
DROP POLICY IF EXISTS "s3_video_paths_service_policy" ON public.s3_video_paths;
CREATE POLICY "s3_video_paths_service_policy" ON public.s3_video_paths FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can delete their saved foods on saved_foods
DROP POLICY IF EXISTS "Users can delete their saved foods" ON public.saved_foods;
CREATE POLICY "Users can delete their saved foods" ON public.saved_foods FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can save foods on saved_foods
DROP POLICY IF EXISTS "Users can save foods" ON public.saved_foods;
CREATE POLICY "Users can save foods" ON public.saved_foods FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: Users can update their saved foods on saved_foods
DROP POLICY IF EXISTS "Users can update their saved foods" ON public.saved_foods;
CREATE POLICY "Users can update their saved foods" ON public.saved_foods FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can view their own saved foods on saved_foods
DROP POLICY IF EXISTS "Users can view their own saved foods" ON public.saved_foods;
CREATE POLICY "Users can view their own saved foods" ON public.saved_foods FOR SELECT USING ((user_id = (select auth.uid())));

-- Fix policy: Users can delete their saved workouts on saved_workouts
DROP POLICY IF EXISTS "Users can delete their saved workouts" ON public.saved_workouts;
CREATE POLICY "Users can delete their saved workouts" ON public.saved_workouts FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can save workouts on saved_workouts
DROP POLICY IF EXISTS "Users can save workouts" ON public.saved_workouts;
CREATE POLICY "Users can save workouts" ON public.saved_workouts FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: Users can update their saved workouts on saved_workouts
DROP POLICY IF EXISTS "Users can update their saved workouts" ON public.saved_workouts;
CREATE POLICY "Users can update their saved workouts" ON public.saved_workouts FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can view their own saved workouts on saved_workouts
DROP POLICY IF EXISTS "Users can view their own saved workouts" ON public.saved_workouts;
CREATE POLICY "Users can view their own saved workouts" ON public.saved_workouts FOR SELECT USING ((user_id = (select auth.uid())));

-- Fix policy: Users can delete their scheduled workouts on scheduled_workouts
DROP POLICY IF EXISTS "Users can delete their scheduled workouts" ON public.scheduled_workouts;
CREATE POLICY "Users can delete their scheduled workouts" ON public.scheduled_workouts FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can schedule workouts on scheduled_workouts
DROP POLICY IF EXISTS "Users can schedule workouts" ON public.scheduled_workouts;
CREATE POLICY "Users can schedule workouts" ON public.scheduled_workouts FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: Users can update their scheduled workouts on scheduled_workouts
DROP POLICY IF EXISTS "Users can update their scheduled workouts" ON public.scheduled_workouts;
CREATE POLICY "Users can update their scheduled workouts" ON public.scheduled_workouts FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can view their scheduled workouts on scheduled_workouts
DROP POLICY IF EXISTS "Users can view their scheduled workouts" ON public.scheduled_workouts;
CREATE POLICY "Users can view their scheduled workouts" ON public.scheduled_workouts FOR SELECT USING ((user_id = (select auth.uid())));

-- Fix policy: Service role full access screen views on screen_views
DROP POLICY IF EXISTS "Service role full access screen views" ON public.screen_views;
CREATE POLICY "Service role full access screen views" ON public.screen_views FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own screen views on screen_views
DROP POLICY IF EXISTS "Users can insert own screen views" ON public.screen_views;
CREATE POLICY "Users can insert own screen views" ON public.screen_views FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))) OR (user_id IS NULL)));

-- Fix policy: Users can read own screen views on screen_views
DROP POLICY IF EXISTS "Users can read own screen views" ON public.screen_views;
CREATE POLICY "Users can read own screen views" ON public.screen_views FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: senior_settings_delete on senior_recovery_settings
DROP POLICY IF EXISTS "senior_settings_delete" ON public.senior_recovery_settings;
CREATE POLICY "senior_settings_delete" ON public.senior_recovery_settings FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: senior_settings_insert on senior_recovery_settings
DROP POLICY IF EXISTS "senior_settings_insert" ON public.senior_recovery_settings;
CREATE POLICY "senior_settings_insert" ON public.senior_recovery_settings FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: senior_settings_select on senior_recovery_settings
DROP POLICY IF EXISTS "senior_settings_select" ON public.senior_recovery_settings;
CREATE POLICY "senior_settings_select" ON public.senior_recovery_settings FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: senior_settings_update on senior_recovery_settings
DROP POLICY IF EXISTS "senior_settings_update" ON public.senior_recovery_settings;
CREATE POLICY "senior_settings_update" ON public.senior_recovery_settings FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: senior_log_delete on senior_workout_log
DROP POLICY IF EXISTS "senior_log_delete" ON public.senior_workout_log;
CREATE POLICY "senior_log_delete" ON public.senior_workout_log FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: senior_log_insert on senior_workout_log
DROP POLICY IF EXISTS "senior_log_insert" ON public.senior_workout_log;
CREATE POLICY "senior_log_insert" ON public.senior_workout_log FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: senior_log_select on senior_workout_log
DROP POLICY IF EXISTS "senior_log_select" ON public.senior_workout_log;
CREATE POLICY "senior_log_select" ON public.senior_workout_log FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: senior_log_update on senior_workout_log
DROP POLICY IF EXISTS "senior_log_update" ON public.senior_workout_log;
CREATE POLICY "senior_log_update" ON public.senior_workout_log FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own set adjustments on set_adjustments
DROP POLICY IF EXISTS "Users can delete own set adjustments" ON public.set_adjustments;
CREATE POLICY "Users can delete own set adjustments" ON public.set_adjustments FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can insert own set adjustments on set_adjustments
DROP POLICY IF EXISTS "Users can insert own set adjustments" ON public.set_adjustments;
CREATE POLICY "Users can insert own set adjustments" ON public.set_adjustments FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can update own set adjustments on set_adjustments
DROP POLICY IF EXISTS "Users can update own set adjustments" ON public.set_adjustments;
CREATE POLICY "Users can update own set adjustments" ON public.set_adjustments FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid()))))) WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can view own set adjustments on set_adjustments
DROP POLICY IF EXISTS "Users can view own set adjustments" ON public.set_adjustments;
CREATE POLICY "Users can view own set adjustments" ON public.set_adjustments FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Service role can manage all rep accuracy on set_rep_accuracy
DROP POLICY IF EXISTS "Service role can manage all rep accuracy" ON public.set_rep_accuracy;
CREATE POLICY "Service role can manage all rep accuracy" ON public.set_rep_accuracy FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can delete own rep accuracy on set_rep_accuracy
DROP POLICY IF EXISTS "Users can delete own rep accuracy" ON public.set_rep_accuracy;
CREATE POLICY "Users can delete own rep accuracy" ON public.set_rep_accuracy FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can insert own rep accuracy on set_rep_accuracy
DROP POLICY IF EXISTS "Users can insert own rep accuracy" ON public.set_rep_accuracy;
CREATE POLICY "Users can insert own rep accuracy" ON public.set_rep_accuracy FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can update own rep accuracy on set_rep_accuracy
DROP POLICY IF EXISTS "Users can update own rep accuracy" ON public.set_rep_accuracy;
CREATE POLICY "Users can update own rep accuracy" ON public.set_rep_accuracy FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid()))))) WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can view own rep accuracy on set_rep_accuracy
DROP POLICY IF EXISTS "Users can view own rep accuracy" ON public.set_rep_accuracy;
CREATE POLICY "Users can view own rep accuracy" ON public.set_rep_accuracy FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: shared_goals_insert_policy on shared_goals
DROP POLICY IF EXISTS "shared_goals_insert_policy" ON public.shared_goals;
CREATE POLICY "shared_goals_insert_policy" ON public.shared_goals FOR INSERT WITH CHECK (((select auth.uid()) = joined_user_id));

-- Fix policy: shared_goals_select_policy on shared_goals
DROP POLICY IF EXISTS "shared_goals_select_policy" ON public.shared_goals;
CREATE POLICY "shared_goals_select_policy" ON public.shared_goals FOR SELECT USING ((((select auth.uid()) = source_user_id) OR ((select auth.uid()) = joined_user_id)));

-- Fix policy: shared_goals_update_policy on shared_goals
DROP POLICY IF EXISTS "shared_goals_update_policy" ON public.shared_goals;
CREATE POLICY "shared_goals_update_policy" ON public.shared_goals FOR UPDATE USING ((((select auth.uid()) = source_user_id) OR ((select auth.uid()) = joined_user_id)));

-- Fix policy: Service role can manage notifications on social_notifications
DROP POLICY IF EXISTS "Service role can manage notifications" ON public.social_notifications;
CREATE POLICY "Service role can manage notifications" ON public.social_notifications FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can delete own notifications on social_notifications
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.social_notifications;
CREATE POLICY "Users can delete own notifications" ON public.social_notifications FOR DELETE USING ((((select auth.uid()))::text = (user_id)::text));

-- Fix policy: Users can update own notifications on social_notifications
DROP POLICY IF EXISTS "Users can update own notifications" ON public.social_notifications;
CREATE POLICY "Users can update own notifications" ON public.social_notifications FOR UPDATE USING ((((select auth.uid()))::text = (user_id)::text));

-- Fix policy: Users can view own notifications on social_notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON public.social_notifications;
CREATE POLICY "Users can view own notifications" ON public.social_notifications FOR SELECT USING ((((select auth.uid()))::text = (user_id)::text));

-- Fix policy: Users can delete their own sound preferences on sound_preferences
DROP POLICY IF EXISTS "Users can delete their own sound preferences" ON public.sound_preferences;
CREATE POLICY "Users can delete their own sound preferences" ON public.sound_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert their own sound preferences on sound_preferences
DROP POLICY IF EXISTS "Users can insert their own sound preferences" ON public.sound_preferences;
CREATE POLICY "Users can insert their own sound preferences" ON public.sound_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update their own sound preferences on sound_preferences
DROP POLICY IF EXISTS "Users can update their own sound preferences" ON public.sound_preferences;
CREATE POLICY "Users can update their own sound preferences" ON public.sound_preferences FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own sound preferences on sound_preferences
DROP POLICY IF EXISTS "Users can view their own sound preferences" ON public.sound_preferences;
CREATE POLICY "Users can view their own sound preferences" ON public.sound_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Service role has full access to staple_exercises on staple_exercises
DROP POLICY IF EXISTS "Service role has full access to staple_exercises" ON public.staple_exercises;
CREATE POLICY "Service role has full access to staple_exercises" ON public.staple_exercises FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can delete their own staple exercises on staple_exercises
DROP POLICY IF EXISTS "Users can delete their own staple exercises" ON public.staple_exercises;
CREATE POLICY "Users can delete their own staple exercises" ON public.staple_exercises FOR DELETE USING (((select auth.uid()) IN ( SELECT users.auth_id FROM users WHERE (users.id = staple_exercises.user_id))));

-- Fix policy: Users can insert their own staple exercises on staple_exercises
DROP POLICY IF EXISTS "Users can insert their own staple exercises" ON public.staple_exercises;
CREATE POLICY "Users can insert their own staple exercises" ON public.staple_exercises FOR INSERT WITH CHECK (((select auth.uid()) IN ( SELECT users.auth_id FROM users WHERE (users.id = staple_exercises.user_id))));

-- Fix policy: Users can view their own staple exercises on staple_exercises
DROP POLICY IF EXISTS "Users can view their own staple exercises" ON public.staple_exercises;
CREATE POLICY "Users can view their own staple exercises" ON public.staple_exercises FOR SELECT USING (((select auth.uid()) IN ( SELECT users.auth_id FROM users WHERE (users.id = staple_exercises.user_id))));

-- Fix policy: strain_history_policy on strain_history
DROP POLICY IF EXISTS "strain_history_policy" ON public.strain_history;
CREATE POLICY "strain_history_policy" ON public.strain_history FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own strength baselines on strength_baselines
DROP POLICY IF EXISTS "Users can delete own strength baselines" ON public.strength_baselines;
CREATE POLICY "Users can delete own strength baselines" ON public.strength_baselines FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own strength baselines on strength_baselines
DROP POLICY IF EXISTS "Users can insert own strength baselines" ON public.strength_baselines;
CREATE POLICY "Users can insert own strength baselines" ON public.strength_baselines FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own strength baselines on strength_baselines
DROP POLICY IF EXISTS "Users can update own strength baselines" ON public.strength_baselines;
CREATE POLICY "Users can update own strength baselines" ON public.strength_baselines FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own strength baselines on strength_baselines
DROP POLICY IF EXISTS "Users can view own strength baselines" ON public.strength_baselines;
CREATE POLICY "Users can view own strength baselines" ON public.strength_baselines FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own strength_records on strength_records
DROP POLICY IF EXISTS "Users can manage own strength_records" ON public.strength_records;
CREATE POLICY "Users can manage own strength_records" ON public.strength_records FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: strength_scores_insert_policy on strength_scores
DROP POLICY IF EXISTS "strength_scores_insert_policy" ON public.strength_scores;
CREATE POLICY "strength_scores_insert_policy" ON public.strength_scores FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: strength_scores_select_policy on strength_scores
DROP POLICY IF EXISTS "strength_scores_select_policy" ON public.strength_scores;
CREATE POLICY "strength_scores_select_policy" ON public.strength_scores FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: strength_scores_service_policy on strength_scores
DROP POLICY IF EXISTS "strength_scores_service_policy" ON public.strength_scores;
CREATE POLICY "strength_scores_service_policy" ON public.strength_scores FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: strength_scores_update_policy on strength_scores
DROP POLICY IF EXISTS "strength_scores_update_policy" ON public.strength_scores;
CREATE POLICY "strength_scores_update_policy" ON public.strength_scores FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own stretches on stretches
DROP POLICY IF EXISTS "Users can manage own stretches" ON public.stretches;
CREATE POLICY "Users can manage own stretches" ON public.stretches FOR ALL USING ((workout_id IN ( SELECT workouts.id FROM workouts WHERE (workouts.user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))))));

-- Fix policy: Users can view own stretches on stretches
DROP POLICY IF EXISTS "Users can view own stretches" ON public.stretches;
CREATE POLICY "Users can view own stretches" ON public.stretches FOR SELECT USING ((workout_id IN ( SELECT workouts.id FROM workouts WHERE (workouts.user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))))));

-- Fix policy: Service role full access to subscription_discounts on subscription_discounts
DROP POLICY IF EXISTS "Service role full access to subscription_discounts" ON public.subscription_discounts;
CREATE POLICY "Service role full access to subscription_discounts" ON public.subscription_discounts FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own subscription discounts on subscription_discounts
DROP POLICY IF EXISTS "Users can insert own subscription discounts" ON public.subscription_discounts;
CREATE POLICY "Users can insert own subscription discounts" ON public.subscription_discounts FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own subscription discounts on subscription_discounts
DROP POLICY IF EXISTS "Users can update own subscription discounts" ON public.subscription_discounts;
CREATE POLICY "Users can update own subscription discounts" ON public.subscription_discounts FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own subscription discounts on subscription_discounts
DROP POLICY IF EXISTS "Users can view own subscription discounts" ON public.subscription_discounts;
CREATE POLICY "Users can view own subscription discounts" ON public.subscription_discounts FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Service role full access history on subscription_history
DROP POLICY IF EXISTS "Service role full access history" ON public.subscription_history;
CREATE POLICY "Service role full access history" ON public.subscription_history FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can read own subscription history on subscription_history
DROP POLICY IF EXISTS "Users can read own subscription history" ON public.subscription_history;
CREATE POLICY "Users can read own subscription history" ON public.subscription_history FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Service role pause history on subscription_pause_history
DROP POLICY IF EXISTS "Service role pause history" ON public.subscription_pause_history;
CREATE POLICY "Service role pause history" ON public.subscription_pause_history FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can read own pause history on subscription_pause_history
DROP POLICY IF EXISTS "Users can read own pause history" ON public.subscription_pause_history;
CREATE POLICY "Users can read own pause history" ON public.subscription_pause_history FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Service role full access to subscription_pauses on subscription_pauses
DROP POLICY IF EXISTS "Service role full access to subscription_pauses" ON public.subscription_pauses;
CREATE POLICY "Service role full access to subscription_pauses" ON public.subscription_pauses FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own subscription pauses on subscription_pauses
DROP POLICY IF EXISTS "Users can insert own subscription pauses" ON public.subscription_pauses;
CREATE POLICY "Users can insert own subscription pauses" ON public.subscription_pauses FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own subscription pauses on subscription_pauses
DROP POLICY IF EXISTS "Users can update own subscription pauses" ON public.subscription_pauses;
CREATE POLICY "Users can update own subscription pauses" ON public.subscription_pauses FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own subscription pauses on subscription_pauses
DROP POLICY IF EXISTS "Users can view own subscription pauses" ON public.subscription_pauses;
CREATE POLICY "Users can view own subscription pauses" ON public.subscription_pauses FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Service role full access price history on subscription_price_history
DROP POLICY IF EXISTS "Service role full access price history" ON public.subscription_price_history;
CREATE POLICY "Service role full access price history" ON public.subscription_price_history FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can read own price history on subscription_price_history
DROP POLICY IF EXISTS "Users can read own price history" ON public.subscription_price_history;
CREATE POLICY "Users can read own price history" ON public.subscription_price_history FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can create own superset preferences on superset_preferences
DROP POLICY IF EXISTS "Users can create own superset preferences" ON public.superset_preferences;
CREATE POLICY "Users can create own superset preferences" ON public.superset_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own superset preferences on superset_preferences
DROP POLICY IF EXISTS "Users can delete own superset preferences" ON public.superset_preferences;
CREATE POLICY "Users can delete own superset preferences" ON public.superset_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can update own superset preferences on superset_preferences
DROP POLICY IF EXISTS "Users can update own superset preferences" ON public.superset_preferences;
CREATE POLICY "Users can update own superset preferences" ON public.superset_preferences FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own superset preferences on superset_preferences
DROP POLICY IF EXISTS "Users can view own superset preferences" ON public.superset_preferences;
CREATE POLICY "Users can view own superset preferences" ON public.superset_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can add messages to own tickets on support_ticket_messages
DROP POLICY IF EXISTS "Users can add messages to own tickets" ON public.support_ticket_messages;
CREATE POLICY "Users can add messages to own tickets" ON public.support_ticket_messages FOR INSERT WITH CHECK (((EXISTS ( SELECT 1 FROM support_tickets WHERE ((support_tickets.id = support_ticket_messages.ticket_id) AND (support_tickets.user_id = (select auth.uid()))))) AND (sender = 'user'::text) AND (is_internal = false)));

-- Fix policy: Users can view messages on own tickets on support_ticket_messages
DROP POLICY IF EXISTS "Users can view messages on own tickets" ON public.support_ticket_messages;
CREATE POLICY "Users can view messages on own tickets" ON public.support_ticket_messages FOR SELECT USING (((EXISTS ( SELECT 1 FROM support_tickets WHERE ((support_tickets.id = support_ticket_messages.ticket_id) AND (support_tickets.user_id = (select auth.uid()))))) AND (is_internal = false)));

-- Fix policy: Users can create own tickets on support_tickets
DROP POLICY IF EXISTS "Users can create own tickets" ON public.support_tickets;
CREATE POLICY "Users can create own tickets" ON public.support_tickets FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own tickets on support_tickets
DROP POLICY IF EXISTS "Users can update own tickets" ON public.support_tickets;
CREATE POLICY "Users can update own tickets" ON public.support_tickets FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own tickets on support_tickets
DROP POLICY IF EXISTS "Users can view own tickets" ON public.support_tickets;
CREATE POLICY "Users can view own tickets" ON public.support_tickets FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: trial_extensions_insert_policy on trial_extensions
DROP POLICY IF EXISTS "trial_extensions_insert_policy" ON public.trial_extensions;
CREATE POLICY "trial_extensions_insert_policy" ON public.trial_extensions FOR INSERT WITH CHECK (((select auth.role()) = 'service_role'::text));

-- Fix policy: trial_extensions_select_policy on trial_extensions
DROP POLICY IF EXISTS "trial_extensions_select_policy" ON public.trial_extensions;
CREATE POLICY "trial_extensions_select_policy" ON public.trial_extensions FOR SELECT USING (((user_id = (select auth.uid())) OR ((select auth.role()) = 'service_role'::text)));

-- Fix policy: try_workout_service_policy on try_workout_sessions
DROP POLICY IF EXISTS "try_workout_service_policy" ON public.try_workout_sessions;
CREATE POLICY "try_workout_service_policy" ON public.try_workout_sessions FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: try_workout_update_policy on try_workout_sessions
DROP POLICY IF EXISTS "try_workout_update_policy" ON public.try_workout_sessions;
CREATE POLICY "try_workout_update_policy" ON public.try_workout_sessions FOR UPDATE USING ((((select auth.uid()) = user_id) OR (user_id IS NULL)));

-- Fix policy: try_workout_user_policy on try_workout_sessions
DROP POLICY IF EXISTS "try_workout_user_policy" ON public.try_workout_sessions;
CREATE POLICY "try_workout_user_policy" ON public.try_workout_sessions FOR SELECT USING ((((select auth.uid()) = user_id) OR (user_id IS NULL)));

-- Fix policy: user_achievements_select_policy on user_achievements
DROP POLICY IF EXISTS "user_achievements_select_policy" ON public.user_achievements;
CREATE POLICY "user_achievements_select_policy" ON public.user_achievements FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: user_achievements_service_policy on user_achievements
DROP POLICY IF EXISTS "user_achievements_service_policy" ON public.user_achievements;
CREATE POLICY "user_achievements_service_policy" ON public.user_achievements FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: users_view_own_activity_log on user_activity_log
DROP POLICY IF EXISTS "users_view_own_activity_log" ON public.user_activity_log;
CREATE POLICY "users_view_own_activity_log" ON public.user_activity_log FOR SELECT  TO authenticated USING ((((select auth.uid()))::text = user_id));

-- Fix policy: user_ai_settings_policy on user_ai_settings
DROP POLICY IF EXISTS "user_ai_settings_policy" ON public.user_ai_settings;
CREATE POLICY "user_ai_settings_policy" ON public.user_ai_settings FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: Users can create their own connections on user_connections
DROP POLICY IF EXISTS "Users can create their own connections" ON public.user_connections;
CREATE POLICY "Users can create their own connections" ON public.user_connections FOR INSERT WITH CHECK ((follower_id = (select auth.uid())));

-- Fix policy: Users can delete their own connections on user_connections
DROP POLICY IF EXISTS "Users can delete their own connections" ON public.user_connections;
CREATE POLICY "Users can delete their own connections" ON public.user_connections FOR DELETE USING ((follower_id = (select auth.uid())));

-- Fix policy: Users can view their own connections on user_connections
DROP POLICY IF EXISTS "Users can view their own connections" ON public.user_connections;
CREATE POLICY "Users can view their own connections" ON public.user_connections FOR SELECT USING (((follower_id = (select auth.uid())) OR (following_id = (select auth.uid()))));

-- Fix policy: user_context_logs_insert_policy on user_context_logs
DROP POLICY IF EXISTS "user_context_logs_insert_policy" ON public.user_context_logs;
CREATE POLICY "user_context_logs_insert_policy" ON public.user_context_logs FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: user_context_logs_select_policy on user_context_logs
DROP POLICY IF EXISTS "user_context_logs_select_policy" ON public.user_context_logs;
CREATE POLICY "user_context_logs_select_policy" ON public.user_context_logs FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: user_context_logs_service_policy on user_context_logs
DROP POLICY IF EXISTS "user_context_logs_service_policy" ON public.user_context_logs;
CREATE POLICY "user_context_logs_service_policy" ON public.user_context_logs FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Service role full access events on user_events
DROP POLICY IF EXISTS "Service role full access events" ON public.user_events;
CREATE POLICY "Service role full access events" ON public.user_events FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own events on user_events
DROP POLICY IF EXISTS "Users can insert own events" ON public.user_events;
CREATE POLICY "Users can insert own events" ON public.user_events FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))) OR (user_id IS NULL)));

-- Fix policy: Users can read own events on user_events
DROP POLICY IF EXISTS "Users can read own events" ON public.user_events;
CREATE POLICY "Users can read own events" ON public.user_events FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: user_exercise_1rms_delete on user_exercise_1rms
DROP POLICY IF EXISTS "user_exercise_1rms_delete" ON public.user_exercise_1rms;
CREATE POLICY "user_exercise_1rms_delete" ON public.user_exercise_1rms FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: user_exercise_1rms_insert on user_exercise_1rms
DROP POLICY IF EXISTS "user_exercise_1rms_insert" ON public.user_exercise_1rms;
CREATE POLICY "user_exercise_1rms_insert" ON public.user_exercise_1rms FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: user_exercise_1rms_select on user_exercise_1rms
DROP POLICY IF EXISTS "user_exercise_1rms_select" ON public.user_exercise_1rms;
CREATE POLICY "user_exercise_1rms_select" ON public.user_exercise_1rms FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: user_exercise_1rms_update on user_exercise_1rms
DROP POLICY IF EXISTS "user_exercise_1rms_update" ON public.user_exercise_1rms;
CREATE POLICY "user_exercise_1rms_update" ON public.user_exercise_1rms FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users manage own exercise mastery on user_exercise_mastery
DROP POLICY IF EXISTS "Users manage own exercise mastery" ON public.user_exercise_mastery;
CREATE POLICY "Users manage own exercise mastery" ON public.user_exercise_mastery FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: user_injuries_delete_policy on user_injuries
DROP POLICY IF EXISTS "user_injuries_delete_policy" ON public.user_injuries;
CREATE POLICY "user_injuries_delete_policy" ON public.user_injuries FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: user_injuries_insert_policy on user_injuries
DROP POLICY IF EXISTS "user_injuries_insert_policy" ON public.user_injuries;
CREATE POLICY "user_injuries_insert_policy" ON public.user_injuries FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: user_injuries_select_policy on user_injuries
DROP POLICY IF EXISTS "user_injuries_select_policy" ON public.user_injuries;
CREATE POLICY "user_injuries_select_policy" ON public.user_injuries FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: user_injuries_update_policy on user_injuries
DROP POLICY IF EXISTS "user_injuries_update_policy" ON public.user_injuries;
CREATE POLICY "user_injuries_update_policy" ON public.user_injuries FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: user_insights_select_policy on user_insights
DROP POLICY IF EXISTS "user_insights_select_policy" ON public.user_insights;
CREATE POLICY "user_insights_select_policy" ON public.user_insights FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: user_insights_service_policy on user_insights
DROP POLICY IF EXISTS "user_insights_service_policy" ON public.user_insights;
CREATE POLICY "user_insights_service_policy" ON public.user_insights FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can manage own user_metrics on user_metrics
DROP POLICY IF EXISTS "Users can manage own user_metrics" ON public.user_metrics;
CREATE POLICY "Users can manage own user_metrics" ON public.user_metrics FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can insert own milestones on user_milestones
DROP POLICY IF EXISTS "Users can insert own milestones" ON public.user_milestones;
CREATE POLICY "Users can insert own milestones" ON public.user_milestones FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own milestones on user_milestones
DROP POLICY IF EXISTS "Users can update own milestones" ON public.user_milestones;
CREATE POLICY "Users can update own milestones" ON public.user_milestones FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own milestones on user_milestones
DROP POLICY IF EXISTS "Users can view own milestones" ON public.user_milestones;
CREATE POLICY "Users can view own milestones" ON public.user_milestones FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: user_neat_achievements_delete_policy on user_neat_achievements
DROP POLICY IF EXISTS "user_neat_achievements_delete_policy" ON public.user_neat_achievements;
CREATE POLICY "user_neat_achievements_delete_policy" ON public.user_neat_achievements FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: user_neat_achievements_insert_policy on user_neat_achievements
DROP POLICY IF EXISTS "user_neat_achievements_insert_policy" ON public.user_neat_achievements;
CREATE POLICY "user_neat_achievements_insert_policy" ON public.user_neat_achievements FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: user_neat_achievements_select_policy on user_neat_achievements
DROP POLICY IF EXISTS "user_neat_achievements_select_policy" ON public.user_neat_achievements;
CREATE POLICY "user_neat_achievements_select_policy" ON public.user_neat_achievements FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: user_neat_achievements_service_policy on user_neat_achievements
DROP POLICY IF EXISTS "user_neat_achievements_service_policy" ON public.user_neat_achievements;
CREATE POLICY "user_neat_achievements_service_policy" ON public.user_neat_achievements FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: user_neat_achievements_update_policy on user_neat_achievements
DROP POLICY IF EXISTS "user_neat_achievements_update_policy" ON public.user_neat_achievements;
CREATE POLICY "user_neat_achievements_update_policy" ON public.user_neat_achievements FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can delete own nutrition preferences on user_nutrition_preferences
DROP POLICY IF EXISTS "Users can delete own nutrition preferences" ON public.user_nutrition_preferences;
CREATE POLICY "Users can delete own nutrition preferences" ON public.user_nutrition_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own nutrition preferences on user_nutrition_preferences
DROP POLICY IF EXISTS "Users can insert own nutrition preferences" ON public.user_nutrition_preferences;
CREATE POLICY "Users can insert own nutrition preferences" ON public.user_nutrition_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own nutrition preferences on user_nutrition_preferences
DROP POLICY IF EXISTS "Users can update own nutrition preferences" ON public.user_nutrition_preferences;
CREATE POLICY "Users can update own nutrition preferences" ON public.user_nutrition_preferences FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own nutrition preferences on user_nutrition_preferences
DROP POLICY IF EXISTS "Users can view own nutrition preferences" ON public.user_nutrition_preferences;
CREATE POLICY "Users can view own nutrition preferences" ON public.user_nutrition_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage their own privacy settings on user_privacy_settings
DROP POLICY IF EXISTS "Users can manage their own privacy settings" ON public.user_privacy_settings;
CREATE POLICY "Users can manage their own privacy settings" ON public.user_privacy_settings FOR ALL USING ((user_id = (select auth.uid())));

-- Fix policy: Users can view their own privacy settings on user_privacy_settings
DROP POLICY IF EXISTS "Users can view their own privacy settings" ON public.user_privacy_settings;
CREATE POLICY "Users can view their own privacy settings" ON public.user_privacy_settings FOR SELECT USING ((user_id = (select auth.uid())));

-- Fix policy: user_program_assignments_delete_own on user_program_assignments
DROP POLICY IF EXISTS "user_program_assignments_delete_own" ON public.user_program_assignments;
CREATE POLICY "user_program_assignments_delete_own" ON public.user_program_assignments FOR DELETE  TO authenticated USING (((select auth.uid()) = user_id));

-- Fix policy: user_program_assignments_insert_own on user_program_assignments
DROP POLICY IF EXISTS "user_program_assignments_insert_own" ON public.user_program_assignments;
CREATE POLICY "user_program_assignments_insert_own" ON public.user_program_assignments FOR INSERT  TO authenticated WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: user_program_assignments_select_own on user_program_assignments
DROP POLICY IF EXISTS "user_program_assignments_select_own" ON public.user_program_assignments;
CREATE POLICY "user_program_assignments_select_own" ON public.user_program_assignments FOR SELECT  TO authenticated USING (((select auth.uid()) = user_id));

-- Fix policy: user_program_assignments_update_own on user_program_assignments
DROP POLICY IF EXISTS "user_program_assignments_update_own" ON public.user_program_assignments;
CREATE POLICY "user_program_assignments_update_own" ON public.user_program_assignments FOR UPDATE  TO authenticated USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can delete their own progression preferences on user_progression_preferences
DROP POLICY IF EXISTS "Users can delete their own progression preferences" ON public.user_progression_preferences;
CREATE POLICY "Users can delete their own progression preferences" ON public.user_progression_preferences FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert their own progression preferences on user_progression_preferences
DROP POLICY IF EXISTS "Users can insert their own progression preferences" ON public.user_progression_preferences;
CREATE POLICY "Users can insert their own progression preferences" ON public.user_progression_preferences FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update their own progression preferences on user_progression_preferences
DROP POLICY IF EXISTS "Users can update their own progression preferences" ON public.user_progression_preferences;
CREATE POLICY "Users can update their own progression preferences" ON public.user_progression_preferences FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own progression preferences on user_progression_preferences
DROP POLICY IF EXISTS "Users can view their own progression preferences" ON public.user_progression_preferences;
CREATE POLICY "Users can view their own progression preferences" ON public.user_progression_preferences FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can create recipes on user_recipes
DROP POLICY IF EXISTS "Users can create recipes" ON public.user_recipes;
CREATE POLICY "Users can create recipes" ON public.user_recipes FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: Users can delete their own recipes on user_recipes
DROP POLICY IF EXISTS "Users can delete their own recipes" ON public.user_recipes;
CREATE POLICY "Users can delete their own recipes" ON public.user_recipes FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can update their own recipes on user_recipes
DROP POLICY IF EXISTS "Users can update their own recipes" ON public.user_recipes;
CREATE POLICY "Users can update their own recipes" ON public.user_recipes FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: Users can view their own recipes on user_recipes
DROP POLICY IF EXISTS "Users can view their own recipes" ON public.user_recipes;
CREATE POLICY "Users can view their own recipes" ON public.user_recipes FOR SELECT USING (((user_id = (select auth.uid())) OR (is_public = true)));

-- Fix policy: Users can manage own rep range preferences on user_rep_range_preferences
DROP POLICY IF EXISTS "Users can manage own rep range preferences" ON public.user_rep_range_preferences;
CREATE POLICY "Users can manage own rep range preferences" ON public.user_rep_range_preferences FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own ROI metrics on user_roi_metrics
DROP POLICY IF EXISTS "Users can manage own ROI metrics" ON public.user_roi_metrics;
CREATE POLICY "Users can manage own ROI metrics" ON public.user_roi_metrics FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view own ROI metrics on user_roi_metrics
DROP POLICY IF EXISTS "Users can view own ROI metrics" ON public.user_roi_metrics;
CREATE POLICY "Users can view own ROI metrics" ON public.user_roi_metrics FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own scheduling preferences on user_scheduling_preferences
DROP POLICY IF EXISTS "Users can manage own scheduling preferences" ON public.user_scheduling_preferences;
CREATE POLICY "Users can manage own scheduling preferences" ON public.user_scheduling_preferences FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can view own scheduling preferences on user_scheduling_preferences
DROP POLICY IF EXISTS "Users can view own scheduling preferences" ON public.user_scheduling_preferences;
CREATE POLICY "Users can view own scheduling preferences" ON public.user_scheduling_preferences FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Service role full access sessions on user_sessions
DROP POLICY IF EXISTS "Service role full access sessions" ON public.user_sessions;
CREATE POLICY "Service role full access sessions" ON public.user_sessions FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own sessions on user_sessions
DROP POLICY IF EXISTS "Users can insert own sessions" ON public.user_sessions;
CREATE POLICY "Users can insert own sessions" ON public.user_sessions FOR INSERT WITH CHECK (((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))) OR (user_id IS NULL)));

-- Fix policy: Users can read own sessions on user_sessions
DROP POLICY IF EXISTS "Users can read own sessions" ON public.user_sessions;
CREATE POLICY "Users can read own sessions" ON public.user_sessions FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: user_settings_insert_policy on user_settings
DROP POLICY IF EXISTS "user_settings_insert_policy" ON public.user_settings;
CREATE POLICY "user_settings_insert_policy" ON public.user_settings FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: user_settings_select_policy on user_settings
DROP POLICY IF EXISTS "user_settings_select_policy" ON public.user_settings;
CREATE POLICY "user_settings_select_policy" ON public.user_settings FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: user_settings_service_policy on user_settings
DROP POLICY IF EXISTS "user_settings_service_policy" ON public.user_settings;
CREATE POLICY "user_settings_service_policy" ON public.user_settings FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: user_settings_update_policy on user_settings
DROP POLICY IF EXISTS "user_settings_update_policy" ON public.user_settings;
CREATE POLICY "user_settings_update_policy" ON public.user_settings FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users manage own skill progress on user_skill_progress
DROP POLICY IF EXISTS "Users manage own skill progress" ON public.user_skill_progress;
CREATE POLICY "Users manage own skill progress" ON public.user_skill_progress FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: user_streaks_select_policy on user_streaks
DROP POLICY IF EXISTS "user_streaks_select_policy" ON public.user_streaks;
CREATE POLICY "user_streaks_select_policy" ON public.user_streaks FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: user_streaks_service_policy on user_streaks
DROP POLICY IF EXISTS "user_streaks_service_policy" ON public.user_streaks;
CREATE POLICY "user_streaks_service_policy" ON public.user_streaks FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Service role full access subscriptions on user_subscriptions
DROP POLICY IF EXISTS "Service role full access subscriptions" ON public.user_subscriptions;
CREATE POLICY "Service role full access subscriptions" ON public.user_subscriptions FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can read own subscription on user_subscriptions
DROP POLICY IF EXISTS "Users can read own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can read own subscription" ON public.user_subscriptions FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can create own superset history on user_superset_history
DROP POLICY IF EXISTS "Users can create own superset history" ON public.user_superset_history;
CREATE POLICY "Users can create own superset history" ON public.user_superset_history FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own superset history on user_superset_history
DROP POLICY IF EXISTS "Users can delete own superset history" ON public.user_superset_history;
CREATE POLICY "Users can delete own superset history" ON public.user_superset_history FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can update own superset history on user_superset_history
DROP POLICY IF EXISTS "Users can update own superset history" ON public.user_superset_history;
CREATE POLICY "Users can update own superset history" ON public.user_superset_history FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own superset history on user_superset_history
DROP POLICY IF EXISTS "Users can view own superset history" ON public.user_superset_history;
CREATE POLICY "Users can view own superset history" ON public.user_superset_history FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own workout patterns on user_workout_patterns
DROP POLICY IF EXISTS "Users can delete own workout patterns" ON public.user_workout_patterns;
CREATE POLICY "Users can delete own workout patterns" ON public.user_workout_patterns FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own workout patterns on user_workout_patterns
DROP POLICY IF EXISTS "Users can insert own workout patterns" ON public.user_workout_patterns;
CREATE POLICY "Users can insert own workout patterns" ON public.user_workout_patterns FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update own workout patterns on user_workout_patterns
DROP POLICY IF EXISTS "Users can update own workout patterns" ON public.user_workout_patterns;
CREATE POLICY "Users can update own workout patterns" ON public.user_workout_patterns FOR UPDATE USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own workout patterns on user_workout_patterns
DROP POLICY IF EXISTS "Users can view own workout patterns" ON public.user_workout_patterns;
CREATE POLICY "Users can view own workout patterns" ON public.user_workout_patterns FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own data on users
DROP POLICY IF EXISTS "Users can delete own data" ON public.users;
CREATE POLICY "Users can delete own data" ON public.users FOR DELETE USING ((((select auth.uid()) = auth_id) OR ((select auth.uid()) IS NULL)));

-- Fix policy: Users can insert own profile on users
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (((select auth.uid()) = auth_id));

-- Fix policy: Users can update own data on users
DROP POLICY IF EXISTS "Users can update own data" ON public.users;
CREATE POLICY "Users can update own data" ON public.users FOR UPDATE USING ((((select auth.uid()) = auth_id) OR ((select auth.uid()) IS NULL)));

-- Fix policy: Users can update own profile on users
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (((select auth.uid()) = auth_id));

-- Fix policy: Users can view own data on users
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
CREATE POLICY "Users can view own data" ON public.users FOR SELECT USING ((((select auth.uid()) = auth_id) OR ((select auth.uid()) IS NULL)));

-- Fix policy: Users can view own profile on users
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (((select auth.uid()) = auth_id));

-- Fix policy: volume_alerts_policy on volume_increase_alerts
DROP POLICY IF EXISTS "volume_alerts_policy" ON public.volume_increase_alerts;
CREATE POLICY "volume_alerts_policy" ON public.volume_increase_alerts FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own warmups on warmups
DROP POLICY IF EXISTS "Users can manage own warmups" ON public.warmups;
CREATE POLICY "Users can manage own warmups" ON public.warmups FOR ALL USING ((workout_id IN ( SELECT workouts.id FROM workouts WHERE (workouts.user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))))));

-- Fix policy: Users can view own warmups on warmups
DROP POLICY IF EXISTS "Users can view own warmups" ON public.warmups;
CREATE POLICY "Users can view own warmups" ON public.warmups FOR SELECT USING ((workout_id IN ( SELECT workouts.id FROM workouts WHERE (workouts.user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))))));

-- Fix policy: weekly_nutrition_recommendations_insert_policy on weekly_nutrition_recommendations
DROP POLICY IF EXISTS "weekly_nutrition_recommendations_insert_policy" ON public.weekly_nutrition_recommendations;
CREATE POLICY "weekly_nutrition_recommendations_insert_policy" ON public.weekly_nutrition_recommendations FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: weekly_nutrition_recommendations_select_policy on weekly_nutrition_recommendations
DROP POLICY IF EXISTS "weekly_nutrition_recommendations_select_policy" ON public.weekly_nutrition_recommendations;
CREATE POLICY "weekly_nutrition_recommendations_select_policy" ON public.weekly_nutrition_recommendations FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: weekly_nutrition_recommendations_update_policy on weekly_nutrition_recommendations
DROP POLICY IF EXISTS "weekly_nutrition_recommendations_update_policy" ON public.weekly_nutrition_recommendations;
CREATE POLICY "weekly_nutrition_recommendations_update_policy" ON public.weekly_nutrition_recommendations FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can create their own goals on weekly_personal_goals
DROP POLICY IF EXISTS "Users can create their own goals" ON public.weekly_personal_goals;
CREATE POLICY "Users can create their own goals" ON public.weekly_personal_goals FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can delete their own goals on weekly_personal_goals
DROP POLICY IF EXISTS "Users can delete their own goals" ON public.weekly_personal_goals;
CREATE POLICY "Users can delete their own goals" ON public.weekly_personal_goals FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can update their own goals on weekly_personal_goals
DROP POLICY IF EXISTS "Users can update their own goals" ON public.weekly_personal_goals;
CREATE POLICY "Users can update their own goals" ON public.weekly_personal_goals FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own goals on weekly_personal_goals
DROP POLICY IF EXISTS "Users can view their own goals" ON public.weekly_personal_goals;
CREATE POLICY "Users can view their own goals" ON public.weekly_personal_goals FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: weekly_plans_delete_policy on weekly_plans
DROP POLICY IF EXISTS "weekly_plans_delete_policy" ON public.weekly_plans;
CREATE POLICY "weekly_plans_delete_policy" ON public.weekly_plans FOR DELETE USING ((user_id = (select auth.uid())));

-- Fix policy: weekly_plans_insert_policy on weekly_plans
DROP POLICY IF EXISTS "weekly_plans_insert_policy" ON public.weekly_plans;
CREATE POLICY "weekly_plans_insert_policy" ON public.weekly_plans FOR INSERT WITH CHECK ((user_id = (select auth.uid())));

-- Fix policy: weekly_plans_select_policy on weekly_plans
DROP POLICY IF EXISTS "weekly_plans_select_policy" ON public.weekly_plans;
CREATE POLICY "weekly_plans_select_policy" ON public.weekly_plans FOR SELECT USING ((user_id = (select auth.uid())));

-- Fix policy: weekly_plans_update_policy on weekly_plans
DROP POLICY IF EXISTS "weekly_plans_update_policy" ON public.weekly_plans;
CREATE POLICY "weekly_plans_update_policy" ON public.weekly_plans FOR UPDATE USING ((user_id = (select auth.uid())));

-- Fix policy: weekly_progress_select_policy on weekly_program_progress
DROP POLICY IF EXISTS "weekly_progress_select_policy" ON public.weekly_program_progress;
CREATE POLICY "weekly_progress_select_policy" ON public.weekly_program_progress FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: weekly_progress_service_policy on weekly_program_progress
DROP POLICY IF EXISTS "weekly_progress_service_policy" ON public.weekly_program_progress;
CREATE POLICY "weekly_progress_service_policy" ON public.weekly_program_progress FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: weekly_summaries_select_policy on weekly_summaries
DROP POLICY IF EXISTS "weekly_summaries_select_policy" ON public.weekly_summaries;
CREATE POLICY "weekly_summaries_select_policy" ON public.weekly_summaries FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: weekly_summaries_service_policy on weekly_summaries
DROP POLICY IF EXISTS "weekly_summaries_service_policy" ON public.weekly_summaries;
CREATE POLICY "weekly_summaries_service_policy" ON public.weekly_summaries FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: volume_tracking_policy on weekly_volume_tracking
DROP POLICY IF EXISTS "volume_tracking_policy" ON public.weekly_volume_tracking;
CREATE POLICY "volume_tracking_policy" ON public.weekly_volume_tracking FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own weekly_volumes on weekly_volumes
DROP POLICY IF EXISTS "Users can manage own weekly_volumes" ON public.weekly_volumes;
CREATE POLICY "Users can manage own weekly_volumes" ON public.weekly_volumes FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: weight_logs_delete_policy on weight_logs
DROP POLICY IF EXISTS "weight_logs_delete_policy" ON public.weight_logs;
CREATE POLICY "weight_logs_delete_policy" ON public.weight_logs FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: weight_logs_insert_policy on weight_logs
DROP POLICY IF EXISTS "weight_logs_insert_policy" ON public.weight_logs;
CREATE POLICY "weight_logs_insert_policy" ON public.weight_logs FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: weight_logs_select_policy on weight_logs
DROP POLICY IF EXISTS "weight_logs_select_policy" ON public.weight_logs;
CREATE POLICY "weight_logs_select_policy" ON public.weight_logs FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: weight_logs_update_policy on weight_logs
DROP POLICY IF EXISTS "weight_logs_update_policy" ON public.weight_logs;
CREATE POLICY "weight_logs_update_policy" ON public.weight_logs FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert own window mode logs on window_mode_logs
DROP POLICY IF EXISTS "Users can insert own window mode logs" ON public.window_mode_logs;
CREATE POLICY "Users can insert own window mode logs" ON public.window_mode_logs FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own window mode logs on window_mode_logs
DROP POLICY IF EXISTS "Users can view own window mode logs" ON public.window_mode_logs;
CREATE POLICY "Users can view own window mode logs" ON public.window_mode_logs FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can create challenges on workout_challenges
DROP POLICY IF EXISTS "Users can create challenges" ON public.workout_challenges;
CREATE POLICY "Users can create challenges" ON public.workout_challenges FOR INSERT WITH CHECK ((from_user_id = (select auth.uid())));

-- Fix policy: Users can delete sent pending challenges on workout_challenges
DROP POLICY IF EXISTS "Users can delete sent pending challenges" ON public.workout_challenges;
CREATE POLICY "Users can delete sent pending challenges" ON public.workout_challenges FOR DELETE USING (((from_user_id = (select auth.uid())) AND ((status)::text = 'pending'::text)));

-- Fix policy: Users can update received challenges on workout_challenges
DROP POLICY IF EXISTS "Users can update received challenges" ON public.workout_challenges;
CREATE POLICY "Users can update received challenges" ON public.workout_challenges FOR UPDATE USING ((to_user_id = (select auth.uid())));

-- Fix policy: Users can view their challenges on workout_challenges
DROP POLICY IF EXISTS "Users can view their challenges" ON public.workout_challenges;
CREATE POLICY "Users can view their challenges" ON public.workout_challenges FOR SELECT USING (((from_user_id = (select auth.uid())) OR (to_user_id = (select auth.uid()))));

-- Fix policy: Users can manage own workout_changes on workout_changes
DROP POLICY IF EXISTS "Users can manage own workout_changes" ON public.workout_changes;
CREATE POLICY "Users can manage own workout_changes" ON public.workout_changes FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can insert their own workout exits on workout_exits
DROP POLICY IF EXISTS "Users can insert their own workout exits" ON public.workout_exits;
CREATE POLICY "Users can insert their own workout exits" ON public.workout_exits FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own workout exits on workout_exits
DROP POLICY IF EXISTS "Users can view their own workout exits" ON public.workout_exits;
CREATE POLICY "Users can view their own workout exits" ON public.workout_exits FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: workout_exits_insert_policy on workout_exits
DROP POLICY IF EXISTS "workout_exits_insert_policy" ON public.workout_exits;
CREATE POLICY "workout_exits_insert_policy" ON public.workout_exits FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: workout_exits_select_policy on workout_exits
DROP POLICY IF EXISTS "workout_exits_select_policy" ON public.workout_exits;
CREATE POLICY "workout_exits_select_policy" ON public.workout_exits FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: workout_exits_service_policy on workout_exits
DROP POLICY IF EXISTS "workout_exits_service_policy" ON public.workout_exits;
CREATE POLICY "workout_exits_service_policy" ON public.workout_exits FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: workout_feedback_insert_policy on workout_feedback
DROP POLICY IF EXISTS "workout_feedback_insert_policy" ON public.workout_feedback;
CREATE POLICY "workout_feedback_insert_policy" ON public.workout_feedback FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: workout_feedback_select_policy on workout_feedback
DROP POLICY IF EXISTS "workout_feedback_select_policy" ON public.workout_feedback;
CREATE POLICY "workout_feedback_select_policy" ON public.workout_feedback FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: workout_feedback_service_policy on workout_feedback
DROP POLICY IF EXISTS "workout_feedback_service_policy" ON public.workout_feedback;
CREATE POLICY "workout_feedback_service_policy" ON public.workout_feedback FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: workout_feedback_update_policy on workout_feedback
DROP POLICY IF EXISTS "workout_feedback_update_policy" ON public.workout_feedback;
CREATE POLICY "workout_feedback_update_policy" ON public.workout_feedback FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can delete own gallery images on workout_gallery_images
DROP POLICY IF EXISTS "Users can delete own gallery images" ON public.workout_gallery_images;
CREATE POLICY "Users can delete own gallery images" ON public.workout_gallery_images FOR DELETE USING ((((select auth.uid()))::text = (user_id)::text));

-- Fix policy: Users can insert own gallery images on workout_gallery_images
DROP POLICY IF EXISTS "Users can insert own gallery images" ON public.workout_gallery_images;
CREATE POLICY "Users can insert own gallery images" ON public.workout_gallery_images FOR INSERT WITH CHECK ((((select auth.uid()))::text = (user_id)::text));

-- Fix policy: Users can update own gallery images on workout_gallery_images
DROP POLICY IF EXISTS "Users can update own gallery images" ON public.workout_gallery_images;
CREATE POLICY "Users can update own gallery images" ON public.workout_gallery_images FOR UPDATE USING ((((select auth.uid()))::text = (user_id)::text));

-- Fix policy: Users can view own gallery images on workout_gallery_images
DROP POLICY IF EXISTS "Users can view own gallery images" ON public.workout_gallery_images;
CREATE POLICY "Users can view own gallery images" ON public.workout_gallery_images FOR SELECT USING ((((select auth.uid()))::text = (user_id)::text));

-- Fix policy: Service role has full access to workout_history_imports on workout_history_imports
DROP POLICY IF EXISTS "Service role has full access to workout_history_imports" ON public.workout_history_imports;
CREATE POLICY "Service role has full access to workout_history_imports" ON public.workout_history_imports FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can delete their own imported workout history on workout_history_imports
DROP POLICY IF EXISTS "Users can delete their own imported workout history" ON public.workout_history_imports;
CREATE POLICY "Users can delete their own imported workout history" ON public.workout_history_imports FOR DELETE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can insert their own imported workout history on workout_history_imports
DROP POLICY IF EXISTS "Users can insert their own imported workout history" ON public.workout_history_imports;
CREATE POLICY "Users can insert their own imported workout history" ON public.workout_history_imports FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can update their own imported workout history on workout_history_imports
DROP POLICY IF EXISTS "Users can update their own imported workout history" ON public.workout_history_imports;
CREATE POLICY "Users can update their own imported workout history" ON public.workout_history_imports FOR UPDATE USING (((select auth.uid()) = user_id));

-- Fix policy: Users can view their own imported workout history on workout_history_imports
DROP POLICY IF EXISTS "Users can view their own imported workout history" ON public.workout_history_imports;
CREATE POLICY "Users can view their own imported workout history" ON public.workout_history_imports FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own workout_logs on workout_logs
DROP POLICY IF EXISTS "Users can manage own workout_logs" ON public.workout_logs;
CREATE POLICY "Users can manage own workout_logs" ON public.workout_logs FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Service role can manage all workout performance on workout_performance_summary
DROP POLICY IF EXISTS "Service role can manage all workout performance" ON public.workout_performance_summary;
CREATE POLICY "Service role can manage all workout performance" ON public.workout_performance_summary FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can insert own workout performance on workout_performance_summary
DROP POLICY IF EXISTS "Users can insert own workout performance" ON public.workout_performance_summary;
CREATE POLICY "Users can insert own workout performance" ON public.workout_performance_summary FOR INSERT WITH CHECK (((select auth.uid()) = user_id));

-- Fix policy: Users can view own workout performance on workout_performance_summary
DROP POLICY IF EXISTS "Users can view own workout performance" ON public.workout_performance_summary;
CREATE POLICY "Users can view own workout performance" ON public.workout_performance_summary FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: Users can manage own workout_regenerations on workout_regenerations
DROP POLICY IF EXISTS "Users can manage own workout_regenerations" ON public.workout_regenerations;
CREATE POLICY "Users can manage own workout_regenerations" ON public.workout_regenerations FOR ALL USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can insert own scheduling history on workout_scheduling_history
DROP POLICY IF EXISTS "Users can insert own scheduling history" ON public.workout_scheduling_history;
CREATE POLICY "Users can insert own scheduling history" ON public.workout_scheduling_history FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can view own scheduling history on workout_scheduling_history
DROP POLICY IF EXISTS "Users can view own scheduling history" ON public.workout_scheduling_history;
CREATE POLICY "Users can view own scheduling history" ON public.workout_scheduling_history FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Anyone can view public workout shares on workout_shares
DROP POLICY IF EXISTS "Anyone can view public workout shares" ON public.workout_shares;
CREATE POLICY "Anyone can view public workout shares" ON public.workout_shares FOR SELECT USING (((is_public = true) OR (shared_by = (select auth.uid()))));

-- Fix policy: Users can create their own shares on workout_shares
DROP POLICY IF EXISTS "Users can create their own shares" ON public.workout_shares;
CREATE POLICY "Users can create their own shares" ON public.workout_shares FOR INSERT WITH CHECK ((shared_by = (select auth.uid())));

-- Fix policy: Users can update their own shares on workout_shares
DROP POLICY IF EXISTS "Users can update their own shares" ON public.workout_shares;
CREATE POLICY "Users can update their own shares" ON public.workout_shares FOR UPDATE USING ((shared_by = (select auth.uid())));

-- Fix policy: Users can manage own subjective feedback on workout_subjective_feedback
DROP POLICY IF EXISTS "Users can manage own subjective feedback" ON public.workout_subjective_feedback;
CREATE POLICY "Users can manage own subjective feedback" ON public.workout_subjective_feedback FOR ALL USING (((select auth.uid()) = user_id));

-- Fix policy: workout_summaries_select_policy on workout_summaries
DROP POLICY IF EXISTS "workout_summaries_select_policy" ON public.workout_summaries;
CREATE POLICY "workout_summaries_select_policy" ON public.workout_summaries FOR SELECT USING (((select auth.uid()) = user_id));

-- Fix policy: workout_summaries_service_policy on workout_summaries
DROP POLICY IF EXISTS "workout_summaries_service_policy" ON public.workout_summaries;
CREATE POLICY "workout_summaries_service_policy" ON public.workout_summaries FOR ALL USING (((select auth.role()) = 'service_role'::text));

-- Fix policy: Users can create own workouts on workouts
DROP POLICY IF EXISTS "Users can create own workouts" ON public.workouts;
CREATE POLICY "Users can create own workouts" ON public.workouts FOR INSERT WITH CHECK ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can delete own workouts on workouts
DROP POLICY IF EXISTS "Users can delete own workouts" ON public.workouts;
CREATE POLICY "Users can delete own workouts" ON public.workouts FOR DELETE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can update own workouts on workouts
DROP POLICY IF EXISTS "Users can update own workouts" ON public.workouts;
CREATE POLICY "Users can update own workouts" ON public.workouts FOR UPDATE USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

-- Fix policy: Users can view own workouts on workouts
DROP POLICY IF EXISTS "Users can view own workouts" ON public.workouts;
CREATE POLICY "Users can view own workouts" ON public.workouts FOR SELECT USING ((user_id IN ( SELECT users.id FROM users WHERE (users.auth_id = (select auth.uid())))));

COMMIT;

-- Total policies fixed: 648