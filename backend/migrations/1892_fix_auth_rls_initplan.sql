-- Migration 1892: Fix auth_rls_initplan performance warnings
-- Wraps auth.uid(), auth.role(), auth.jwt(), current_setting() in subselects
-- to prevent re-evaluation for every row in RLS policies.
-- Affects 548 policies across the public schema.
--
-- Generated: 2026-04-04

BEGIN;

ALTER POLICY "a1c_records_service_role_all" ON "public"."a1c_records"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "achievement_types_service_role_all" ON "public"."achievement_types"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "activity_comments_service_role_all" ON "public"."activity_comments"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "activity_feed_service_role_all" ON "public"."activity_feed"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Authenticated users can read activity_hashtags" ON "public"."activity_hashtags"
  USING (((select auth.role()) = 'authenticated'::text));

ALTER POLICY "Service role can manage activity_hashtags" ON "public"."activity_hashtags"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "activity_hashtags_service_role_all" ON "public"."activity_hashtags"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "activity_reactions_service_role_all" ON "public"."activity_reactions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "adaptive_nutrition_calculations_service_role_all" ON "public"."adaptive_nutrition_calculations"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "ai_insight_cache_service_role_all" ON "public"."ai_insight_cache"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "ai_settings_history_service_role_all" ON "public"."ai_settings_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "ai_workout_suggestions_service_role_all" ON "public"."ai_workout_suggestions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can modify app_config" ON "public"."app_config"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "app_config_service_role_all" ON "public"."app_config"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "app_errors_service_role_all" ON "public"."app_errors"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "app_tour_sessions_service_role_all" ON "public"."app_tour_sessions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "app_tour_step_events_service_role_all" ON "public"."app_tour_step_events"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "audio_preferences_service_role_all" ON "public"."audio_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "avoided_exercises_service_role_all" ON "public"."avoided_exercises"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "avoided_muscles_service_role_all" ON "public"."avoided_muscles"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "billing_notifications_service_role_all" ON "public"."billing_notifications"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "body_measurements_service_role_all" ON "public"."body_measurements"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "body_types_service_role_all" ON "public"."body_types"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "branded_programs_service_role_all" ON "public"."branded_programs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "calibration_workouts_service_role_all" ON "public"."calibration_workouts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "cancellation_feedback_service_role_all" ON "public"."cancellation_feedback"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "cancellation_requests_service_role_all" ON "public"."cancellation_requests"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "carb_entries_service_role_all" ON "public"."carb_entries"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "cardio_metrics_service_role_all" ON "public"."cardio_metrics"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "cardio_progression_programs_service_role_all" ON "public"."cardio_progression_programs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "cardio_progression_sessions_service_role_all" ON "public"."cardio_progression_sessions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "cardio_progression_templates_service_role_all" ON "public"."cardio_progression_templates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "cardio_sessions_service_role_all" ON "public"."cardio_sessions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "challenge_notifications_service_role_all" ON "public"."challenge_notifications"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "challenge_participants_service_role_all" ON "public"."challenge_participants"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "challenges_service_role_all" ON "public"."challenges"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "chat_history_insert_own" ON "public"."chat_history"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "chat_history_select_own" ON "public"."chat_history"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "chat_history_service_role_all" ON "public"."chat_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "chat_interaction_analytics_insert_own" ON "public"."chat_interaction_analytics"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "chat_interaction_analytics_service_role_all" ON "public"."chat_interaction_analytics"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can delete reports" ON "public"."chat_message_reports"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Service role can update all reports" ON "public"."chat_message_reports"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Service role can view all reports" ON "public"."chat_message_reports"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Users can create own reports" ON "public"."chat_message_reports"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can view own reports" ON "public"."chat_message_reports"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "chat_message_reports_service_role_all" ON "public"."chat_message_reports"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "checkpoint_rewards_service_role_all" ON "public"."checkpoint_rewards"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "comeback_history_service_role_all" ON "public"."comeback_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "common_foods_service_role_all" ON "public"."common_foods"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "composite_exercise_components_service_role_all" ON "public"."composite_exercise_components"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access on content_reports" ON "public"."content_reports"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Users can create reports" ON "public"."content_reports"
  WITH CHECK (((select auth.uid()) = reporter_id));

ALTER POLICY "Users can delete own reports" ON "public"."content_reports"
  USING (((select auth.uid()) = reporter_id));

ALTER POLICY "Users can view own reports" ON "public"."content_reports"
  USING (((select auth.uid()) = reporter_id));

ALTER POLICY "content_reports_service_role_all" ON "public"."content_reports"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can view their conversation participation" ON "public"."conversation_participants"
  USING (((user_id = (select auth.uid())) OR (conversation_id IN ( SELECT conversation_participants_1.conversation_id
   FROM conversation_participants conversation_participants_1
  WHERE (conversation_participants_1.user_id = (select auth.uid()))))));

ALTER POLICY "conversation_participants_service_role_all" ON "public"."conversation_participants"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can view conversations they participate in" ON "public"."conversations"
  USING ((id IN ( SELECT conversation_participants.conversation_id
   FROM conversation_participants
  WHERE (conversation_participants.user_id = (select auth.uid())))));

ALTER POLICY "conversations_service_role_all" ON "public"."conversations"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "conversion_triggers_service_role_all" ON "public"."conversion_triggers"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "cooking_conversion_factors_service_role_all" ON "public"."cooking_conversion_factors"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "cuisine_types_service_role_all" ON "public"."cuisine_types"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "custom_exercise_usage_service_role_all" ON "public"."custom_exercise_usage"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access custom_exercises" ON "public"."custom_exercises"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "Users can delete own custom_exercises" ON "public"."custom_exercises"
  USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "Users can insert own custom_exercises" ON "public"."custom_exercises"
  WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "Users can update own custom_exercises" ON "public"."custom_exercises"
  USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "Users can view own or public custom_exercises" ON "public"."custom_exercises"
  USING (((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))) OR (is_public = true)));

ALTER POLICY "custom_exercises_service_role_all" ON "public"."custom_exercises"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "custom_goals_service_role_all" ON "public"."custom_goals"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "custom_workout_inputs_service_role_all" ON "public"."custom_workout_inputs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "daily_activity_service_role_all" ON "public"."daily_activity"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can manage own adherence logs" ON "public"."daily_adherence_logs"
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "daily_adherence_logs_service_role_all" ON "public"."daily_adherence_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "daily_plan_entries_service_role_all" ON "public"."daily_plan_entries"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "daily_subjective_checkin_service_role_all" ON "public"."daily_subjective_checkin"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "daily_unified_state_service_role_all" ON "public"."daily_unified_state"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "daily_user_stats_service_role_all" ON "public"."daily_user_stats"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "demo_interactions_service_role_all" ON "public"."demo_interactions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "demo_sessions_service_role_all" ON "public"."demo_sessions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "diabetes_daily_summary_service_role_all" ON "public"."diabetes_daily_summary"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "diabetes_medications_service_role_all" ON "public"."diabetes_medications"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "diabetes_profiles_service_role_all" ON "public"."diabetes_profiles"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "difficulty_adjustments_service_role_all" ON "public"."difficulty_adjustments"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can send messages to their conversations" ON "public"."direct_messages"
  WITH CHECK ((conversation_id IN ( SELECT conversation_participants.conversation_id
   FROM conversation_participants
  WHERE (conversation_participants.user_id = (select auth.uid())))));

ALTER POLICY "Users can view messages in their conversations" ON "public"."direct_messages"
  USING ((conversation_id IN ( SELECT conversation_participants.conversation_id
   FROM conversation_participants
  WHERE (conversation_participants.user_id = (select auth.uid())))));

ALTER POLICY "direct_messages_insert_sender" ON "public"."direct_messages"
  WITH CHECK (((select auth.uid()) = sender_id));

ALTER POLICY "direct_messages_select_participant" ON "public"."direct_messages"
  USING ((((select auth.uid()) = sender_id) OR ((select auth.uid()) IN ( SELECT conversation_participants.user_id
   FROM conversation_participants
  WHERE (conversation_participants.conversation_id = direct_messages.conversation_id)))));

ALTER POLICY "direct_messages_service_role_all" ON "public"."direct_messages"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "drink_intake_logs_service_role_all" ON "public"."drink_intake_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "email_preferences_service_role_all" ON "public"."email_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access email_send_log" ON "public"."email_send_log"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "email_send_log_service_role_all" ON "public"."email_send_log"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can manage equipment_substitutions" ON "public"."equipment_substitutions"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "equipment_substitutions_service_role_all" ON "public"."equipment_substitutions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can manage equipment_types" ON "public"."equipment_types"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "equipment_types_service_role_all" ON "public"."equipment_types"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "equipment_usage_analytics_service_role_all" ON "public"."equipment_usage_analytics"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can modify exercise_aliases" ON "public"."exercise_aliases"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "exercise_aliases_service_role_all" ON "public"."exercise_aliases"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can modify exercise_canonical" ON "public"."exercise_canonical"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "exercise_canonical_service_role_all" ON "public"."exercise_canonical"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can modify exercise_demos" ON "public"."exercise_demos"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "exercise_demos_service_role_all" ON "public"."exercise_demos"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_feedback_service_role_all" ON "public"."exercise_feedback"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_intensity_overrides_service_role_all" ON "public"."exercise_intensity_overrides"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_library_service_role_all" ON "public"."exercise_library"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_muscle_mappings_service_role_all" ON "public"."exercise_muscle_mappings"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_performance_summary_service_role_all" ON "public"."exercise_performance_summary"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_personal_records_service_role_all" ON "public"."exercise_personal_records"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_progression_chains_service_role_all" ON "public"."exercise_progression_chains"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_progression_steps_service_role_all" ON "public"."exercise_progression_steps"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_queue_service_role_all" ON "public"."exercise_queue"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can delete own exercise relationships" ON "public"."exercise_relationships"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can insert own exercise relationships" ON "public"."exercise_relationships"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can update own exercise relationships" ON "public"."exercise_relationships"
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can view own exercise relationships" ON "public"."exercise_relationships"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "exercise_relationships_service_role_all" ON "public"."exercise_relationships"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_rotations_service_role_all" ON "public"."exercise_rotations"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_search_cache_service_role_all" ON "public"."exercise_search_cache"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_swaps_service_role_all" ON "public"."exercise_swaps"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_variant_chains_service_role_all" ON "public"."exercise_variant_chains"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercise_variant_steps_service_role_all" ON "public"."exercise_variant_steps"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "exercises_service_role_all" ON "public"."exercises"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fasting_goal_impact_delete_policy" ON "public"."fasting_goal_impact"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "fasting_goal_impact_insert_policy" ON "public"."fasting_goal_impact"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "fasting_goal_impact_select_policy" ON "public"."fasting_goal_impact"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "fasting_goal_impact_service_role_all" ON "public"."fasting_goal_impact"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fasting_goal_impact_update_policy" ON "public"."fasting_goal_impact"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "fasting_preferences_service_role_all" ON "public"."fasting_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fasting_records_service_role_all" ON "public"."fasting_records"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fasting_scores_service_role_all" ON "public"."fasting_scores"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fasting_streaks_service_role_all" ON "public"."fasting_streaks"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fasting_user_context_service_role_all" ON "public"."fasting_user_context"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fasting_weight_correlation_delete_policy" ON "public"."fasting_weight_correlation"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "fasting_weight_correlation_insert_policy" ON "public"."fasting_weight_correlation"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "fasting_weight_correlation_select_policy" ON "public"."fasting_weight_correlation"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "fasting_weight_correlation_service_role_all" ON "public"."fasting_weight_correlation"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fasting_weight_correlation_update_policy" ON "public"."fasting_weight_correlation"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "favorite_exercises_service_role_all" ON "public"."favorite_exercises"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "favorite_superset_pairs_service_role_all" ON "public"."favorite_superset_pairs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can insert own feature adoption" ON "public"."feature_adoption"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can update own feature adoption" ON "public"."feature_adoption"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can view own feature adoption" ON "public"."feature_adoption"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "feature_adoption_service_role_all" ON "public"."feature_adoption"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "feature_gates_service_role_all" ON "public"."feature_gates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "feature_requests_service_role_all" ON "public"."feature_requests"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "feature_usage_insert_own" ON "public"."feature_usage"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "feature_usage_select_own" ON "public"."feature_usage"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "feature_usage_service_role_all" ON "public"."feature_usage"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "feature_votes_service_role_all" ON "public"."feature_votes"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fitness_scores_service_role_all" ON "public"."fitness_scores"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service insert wrapped" ON "public"."fitness_wrapped"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users read own wrapped" ON "public"."fitness_wrapped"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "fitness_wrapped_service_role_all" ON "public"."fitness_wrapped"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "flexibility_assessments_service_role_all" ON "public"."flexibility_assessments"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "flexibility_stretch_plans_service_role_all" ON "public"."flexibility_stretch_plans"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "flexibility_tests_service_role_all" ON "public"."flexibility_tests"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "food_analysis_cache_service_role_all" ON "public"."food_analysis_cache"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "food_database_service_role_all" ON "public"."food_database"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "food_inflammation_analyses_service_role_all" ON "public"."food_inflammation_analyses"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "inflammation_analyses_service_policy" ON "public"."food_inflammation_analyses"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "food_logs_service_role_all" ON "public"."food_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "food_nutrition_overrides_service_role_all" ON "public"."food_nutrition_overrides"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "food_nutrition_overrides_backup_service_role_all" ON "public"."food_nutrition_overrides_backup"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can create own food reports" ON "public"."food_reports"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can view own food reports" ON "public"."food_reports"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "food_reports_service_role_all" ON "public"."food_reports"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "food_search_cache_service_role_all" ON "public"."food_search_cache"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "former_champions_select_own_policy" ON "public"."former_champions"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "former_champions_service_policy" ON "public"."former_champions"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "former_champions_service_role_all" ON "public"."former_champions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "fraud_flags_service_policy" ON "public"."fraud_flags"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "fraud_flags_service_role_all" ON "public"."fraud_flags"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "friend_requests_service_role_all" ON "public"."friend_requests"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "funnel_events_service_role_all" ON "public"."funnel_events"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "generated_workouts_service_role_all" ON "public"."generated_workouts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "gift_budget_select_policy" ON "public"."gift_budget_tracking"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "gift_budget_service_policy" ON "public"."gift_budget_tracking"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "gift_budget_tracking_service_role_all" ON "public"."gift_budget_tracking"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "glucose_alerts_service_role_all" ON "public"."glucose_alerts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "glucose_readings_service_role_all" ON "public"."glucose_readings"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "goal_attempts_service_role_all" ON "public"."goal_attempts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "goal_friends_cache_service_role_all" ON "public"."goal_friends_cache"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "goal_invites_service_role_all" ON "public"."goal_invites"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "goal_suggestions_service_role_all" ON "public"."goal_suggestions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can delete own gym profiles" ON "public"."gym_profiles"
  USING ((((select auth.uid()))::text = (user_id)::text));

ALTER POLICY "Users can insert own gym profiles" ON "public"."gym_profiles"
  WITH CHECK ((((select auth.uid()))::text = (user_id)::text));

ALTER POLICY "Users can update own gym profiles" ON "public"."gym_profiles"
  USING ((((select auth.uid()))::text = (user_id)::text));

ALTER POLICY "Users can view own gym profiles" ON "public"."gym_profiles"
  USING ((((select auth.uid()))::text = (user_id)::text));

ALTER POLICY "gym_profiles_service_role_all" ON "public"."gym_profiles"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "habit_logs_delete_policy" ON "public"."habit_logs"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "habit_logs_insert_policy" ON "public"."habit_logs"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "habit_logs_select_policy" ON "public"."habit_logs"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "habit_logs_service_policy" ON "public"."habit_logs"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "habit_logs_service_role_all" ON "public"."habit_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "habit_logs_update_policy" ON "public"."habit_logs"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "habit_streaks_delete_policy" ON "public"."habit_streaks"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "habit_streaks_insert_policy" ON "public"."habit_streaks"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "habit_streaks_select_policy" ON "public"."habit_streaks"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "habit_streaks_service_policy" ON "public"."habit_streaks"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "habit_streaks_service_role_all" ON "public"."habit_streaks"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "habit_streaks_update_policy" ON "public"."habit_streaks"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "habit_templates_service_policy" ON "public"."habit_templates"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "habit_templates_service_role_all" ON "public"."habit_templates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "habits_delete_policy" ON "public"."habits"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "habits_insert_policy" ON "public"."habits"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "habits_select_policy" ON "public"."habits"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "habits_service_policy" ON "public"."habits"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "habits_service_role_all" ON "public"."habits"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "habits_update_policy" ON "public"."habits"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Service role can manage hashtags" ON "public"."hashtags"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "hashtags_service_role_all" ON "public"."hashtags"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "heart_rate_samples_insert_own" ON "public"."heart_rate_samples"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "heart_rate_samples_select_own" ON "public"."heart_rate_samples"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "heart_rate_samples_service_role" ON "public"."heart_rate_samples"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "heart_rate_samples_service_role_all" ON "public"."heart_rate_samples"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "hiit_templates_service_role_all" ON "public"."hiit_templates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "home_layout_templates_service_role_all" ON "public"."home_layout_templates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "home_layouts_service_role_all" ON "public"."home_layouts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "hormonal_profiles_service_role_all" ON "public"."hormonal_profiles"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "hormone_logs_service_role_all" ON "public"."hormone_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "hormone_supportive_foods_service_role_all" ON "public"."hormone_supportive_foods"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "hydration_logs_service_role_all" ON "public"."hydration_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "injuries_service_role_all" ON "public"."injuries"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "injury_history_service_role_all" ON "public"."injury_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "injury_rehab_exercises_service_role_all" ON "public"."injury_rehab_exercises"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "injury_updates_service_role_all" ON "public"."injury_updates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "insulin_doses_service_role_all" ON "public"."insulin_doses"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "kegel_exercises_service_role_all" ON "public"."kegel_exercises"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "kegel_preferences_service_role_all" ON "public"."kegel_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "kegel_sessions_service_role_all" ON "public"."kegel_sessions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "level_rewards_service_role_all" ON "public"."level_rewards"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can manage all presence" ON "public"."live_chat_presence"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "live_chat_presence_service_role_all" ON "public"."live_chat_presence"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can manage all queue" ON "public"."live_chat_queue"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "live_chat_queue_service_role_all" ON "public"."live_chat_queue"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "low_impact_alternatives_service_role_all" ON "public"."low_impact_alternatives"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "meal_plan_templates_service_role_all" ON "public"."meal_plan_templates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "meal_templates_service_role_all" ON "public"."meal_templates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can manage all media jobs" ON "public"."media_analysis_jobs"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "Users can view their own media jobs" ON "public"."media_analysis_jobs"
  USING ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = media_analysis_jobs.user_id) AND ((users.auth_id)::text = ((select auth.uid()))::text)))));

ALTER POLICY "media_analysis_jobs_service_role_all" ON "public"."media_analysis_jobs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "merch_claims_insert_policy" ON "public"."merch_claims"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "merch_claims_select_policy" ON "public"."merch_claims"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "merch_claims_service_policy" ON "public"."merch_claims"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "merch_claims_service_role_all" ON "public"."merch_claims"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can view own adaptation events" ON "public"."metabolic_adaptation_events"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "metabolic_adaptation_events_service_role_all" ON "public"."metabolic_adaptation_events"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "migration_log_service_role_all" ON "public"."migration_log"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "milestone_definitions_service_role_all" ON "public"."milestone_definitions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "mobility_exercise_tracking_service_role_all" ON "public"."mobility_exercise_tracking"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "mood_checkins_service_role_all" ON "public"."mood_checkins"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "muscle_analytics_logs_service_role_all" ON "public"."muscle_analytics_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "muscle_volume_caps_service_role_all" ON "public"."muscle_volume_caps"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "neat_achievements_service_role_all" ON "public"."neat_achievements"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "neat_daily_scores_service_role_all" ON "public"."neat_daily_scores"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "neat_goals_service_role_all" ON "public"."neat_goals"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "neat_hourly_activity_service_role_all" ON "public"."neat_hourly_activity"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "neat_reminder_preferences_service_role_all" ON "public"."neat_reminder_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "neat_streaks_service_role_all" ON "public"."neat_streaks"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "neat_weekly_summaries_service_role_all" ON "public"."neat_weekly_summaries"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can manage notification events" ON "public"."notification_events"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "Users can view own notification events" ON "public"."notification_events"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "notification_events_service_role_all" ON "public"."notification_events"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "notification_preferences_service_role_all" ON "public"."notification_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "notification_queue_service_role_all" ON "public"."notification_queue"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "nutrient_rdas_service_role_all" ON "public"."nutrient_rdas"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "nutrition_preferences_service_role_all" ON "public"."nutrition_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "nutrition_scores_service_role_all" ON "public"."nutrition_scores"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "nutrition_streaks_service_role_all" ON "public"."nutrition_streaks"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "onboarding_analytics_service_role_all" ON "public"."onboarding_analytics"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "payment_transactions_service_role_all" ON "public"."payment_transactions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "paywall_impressions_service_role_all" ON "public"."paywall_impressions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "performance_logs_service_role_all" ON "public"."performance_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "personal_goal_records_service_role_all" ON "public"."personal_goal_records"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "personal_records_service_role_all" ON "public"."personal_records"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "photo_comparisons_service_role_all" ON "public"."photo_comparisons"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "plan_previews_service_role_all" ON "public"."plan_previews"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "preference_impact_log_service_role_all" ON "public"."preference_impact_log"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role has full access to program history" ON "public"."program_history"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "program_history_service_role_all" ON "public"."program_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "program_variant_weeks_service_role_all" ON "public"."program_variant_weeks"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Authenticated users can read program_variant_weeks_copy" ON "public"."program_variant_weeks_copy"
  USING (((select auth.role()) = 'authenticated'::text));

ALTER POLICY "Service role can manage program_variant_weeks_copy" ON "public"."program_variant_weeks_copy"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "program_variant_weeks_copy_service_role_all" ON "public"."program_variant_weeks_copy"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "program_variants_service_role_all" ON "public"."program_variants"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "programs_service_role_all" ON "public"."programs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "progress_charts_views_service_role_all" ON "public"."progress_charts_views"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "progress_photos_service_role_all" ON "public"."progress_photos"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "progression_history_service_role_all" ON "public"."progression_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "progression_pace_definitions_service_role_all" ON "public"."progression_pace_definitions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "push_nudge_log_service_role_all" ON "public"."push_nudge_log"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "push_nudge_log_user_select" ON "public"."push_nudge_log"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "quick_log_history_service_role_all" ON "public"."quick_log_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "quick_workout_preferences_service_role_all" ON "public"."quick_workout_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "rag_context_cache_service_role_all" ON "public"."rag_context_cache"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "readiness_scores_service_role_all" ON "public"."readiness_scores"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "recipe_ingredients_service_role_all" ON "public"."recipe_ingredients"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "recipe_suggestion_sessions_service_role_all" ON "public"."recipe_suggestion_sessions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "recipe_suggestions_service_role_all" ON "public"."recipe_suggestions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "record_challenges_insert_policy" ON "public"."record_challenges"
  WITH CHECK (((select auth.uid()) = challenger_id));

ALTER POLICY "record_challenges_select_own_policy" ON "public"."record_challenges"
  USING (((select auth.uid()) = challenger_id));

ALTER POLICY "record_challenges_service_policy" ON "public"."record_challenges"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "record_challenges_service_role_all" ON "public"."record_challenges"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "referral_tracking_select_referred_policy" ON "public"."referral_tracking"
  USING (((select auth.uid()) = referred_id));

ALTER POLICY "referral_tracking_select_referrer_policy" ON "public"."referral_tracking"
  USING (((select auth.uid()) = referrer_id));

ALTER POLICY "referral_tracking_service_policy" ON "public"."referral_tracking"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "referral_tracking_service_role_all" ON "public"."referral_tracking"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "refund_requests_service_role_all" ON "public"."refund_requests"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "rest_intervals_service_role_all" ON "public"."rest_intervals"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "retention_offers_service_role_all" ON "public"."retention_offers"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "retention_offers_accepted_service_role_all" ON "public"."retention_offers_accepted"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "reward_templates_service_policy" ON "public"."reward_templates"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "reward_templates_service_role_all" ON "public"."reward_templates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "s3_video_paths_service_role_all" ON "public"."s3_video_paths"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access sauna logs" ON "public"."sauna_logs"
  USING (((select current_setting('role'::text)) = 'service_role'::text));

ALTER POLICY "Users can delete own sauna logs" ON "public"."sauna_logs"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can insert own sauna logs" ON "public"."sauna_logs"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can view own sauna logs" ON "public"."sauna_logs"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "sauna_logs_service_role_all" ON "public"."sauna_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "saved_foods_service_role_all" ON "public"."saved_foods"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "saved_workouts_service_role_all" ON "public"."saved_workouts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "schedule_items_delete_own" ON "public"."schedule_items"
  USING ((((select auth.uid()) = user_id) OR (( SELECT auth.uid() AS uid) IS NULL) OR (( SELECT auth.role() AS role) = 'service_role'::text)));

ALTER POLICY "schedule_items_insert_own" ON "public"."schedule_items"
  WITH CHECK ((((select auth.uid()) = user_id) OR (( SELECT auth.uid() AS uid) IS NULL) OR (( SELECT auth.role() AS role) = 'service_role'::text)));

ALTER POLICY "schedule_items_select_own" ON "public"."schedule_items"
  USING ((((select auth.uid()) = user_id) OR (( SELECT auth.uid() AS uid) IS NULL) OR (( SELECT auth.role() AS role) = 'service_role'::text)));

ALTER POLICY "schedule_items_service_role_all" ON "public"."schedule_items"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "schedule_items_update_own" ON "public"."schedule_items"
  USING ((((select auth.uid()) = user_id) OR (( SELECT auth.uid() AS uid) IS NULL) OR (( SELECT auth.role() AS role) = 'service_role'::text)));

ALTER POLICY "scheduled_workouts_service_role_all" ON "public"."scheduled_workouts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "screen_views_service_role_all" ON "public"."screen_views"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "senior_mobility_exercises_service_role_all" ON "public"."senior_mobility_exercises"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "senior_recovery_settings_service_role_all" ON "public"."senior_recovery_settings"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "senior_settings_delete" ON "public"."senior_recovery_settings"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "senior_settings_insert" ON "public"."senior_recovery_settings"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "senior_settings_select" ON "public"."senior_recovery_settings"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "senior_settings_update" ON "public"."senior_recovery_settings"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "senior_log_delete" ON "public"."senior_workout_log"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "senior_log_insert" ON "public"."senior_workout_log"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "senior_log_select" ON "public"."senior_workout_log"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "senior_log_update" ON "public"."senior_workout_log"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "senior_workout_log_service_role_all" ON "public"."senior_workout_log"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "set_adjustments_service_role_all" ON "public"."set_adjustments"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "set_rep_accuracy_service_role_all" ON "public"."set_rep_accuracy"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "shared_goals_service_role_all" ON "public"."shared_goals"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "skip_reason_categories_service_role_all" ON "public"."skip_reason_categories"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "social_notifications_service_role_all" ON "public"."social_notifications"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "sound_preferences_service_role_all" ON "public"."sound_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "staple_exercises_service_role_all" ON "public"."staple_exercises"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access to stats gallery" ON "public"."stats_gallery"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Users can delete own stats gallery" ON "public"."stats_gallery"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can insert own stats gallery" ON "public"."stats_gallery"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can update own stats gallery" ON "public"."stats_gallery"
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can view own stats gallery" ON "public"."stats_gallery"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "stats_gallery_service_role_all" ON "public"."stats_gallery"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Authenticated users can view stories" ON "public"."stories"
  USING (((select auth.role()) = 'authenticated'::text));

ALTER POLICY "Service role full access on stories" ON "public"."stories"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Users can create own stories" ON "public"."stories"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can delete own stories" ON "public"."stories"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can update own stories" ON "public"."stories"
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "stories_service_role_all" ON "public"."stories"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access on story_views" ON "public"."story_views"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Users can insert own story views" ON "public"."story_views"
  WITH CHECK (((select auth.uid()) = viewer_id));

ALTER POLICY "story_views_service_role_all" ON "public"."story_views"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "strain_history_service_role_all" ON "public"."strain_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "strength_baselines_service_role_all" ON "public"."strength_baselines"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "strength_records_service_role_all" ON "public"."strength_records"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "strength_scores_service_role_all" ON "public"."strength_scores"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "stretches_service_role_all" ON "public"."stretches"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "subscription_discounts_service_role_all" ON "public"."subscription_discounts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "subscription_history_service_role_all" ON "public"."subscription_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "subscription_pause_history_service_role_all" ON "public"."subscription_pause_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "subscription_pauses_service_role_all" ON "public"."subscription_pauses"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "subscription_price_history_service_role_all" ON "public"."subscription_price_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "superset_preferences_service_role_all" ON "public"."superset_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can add messages" ON "public"."support_ticket_messages"
  WITH CHECK ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Service role can view all messages" ON "public"."support_ticket_messages"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "support_ticket_messages_service_role_all" ON "public"."support_ticket_messages"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can update all tickets" ON "public"."support_tickets"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Service role can view all tickets" ON "public"."support_tickets"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "support_tickets_service_role_all" ON "public"."support_tickets"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can view own sustainability scores" ON "public"."sustainability_scores"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "sustainability_scores_service_role_all" ON "public"."sustainability_scores"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can view own TDEE history" ON "public"."tdee_calculation_history"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "tdee_calculation_history_service_role_all" ON "public"."tdee_calculation_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "trial_extensions_service_role_all" ON "public"."trial_extensions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "try_workout_sessions_service_role_all" ON "public"."try_workout_sessions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_achievements_service_role_all" ON "public"."user_achievements"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_activity_log_service_role_all" ON "public"."user_activity_log"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_ai_settings_service_role_all" ON "public"."user_ai_settings"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access on user_blocks" ON "public"."user_blocks"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Users can create blocks" ON "public"."user_blocks"
  WITH CHECK (((select auth.uid()) = blocker_id));

ALTER POLICY "Users can delete own blocks" ON "public"."user_blocks"
  USING (((select auth.uid()) = blocker_id));

ALTER POLICY "Users can view own blocks" ON "public"."user_blocks"
  USING (((select auth.uid()) = blocker_id));

ALTER POLICY "user_blocks_service_role_all" ON "public"."user_blocks"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access to challenge mastery" ON "public"."user_challenge_mastery"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "Users can delete own challenge mastery" ON "public"."user_challenge_mastery"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can insert own challenge mastery" ON "public"."user_challenge_mastery"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can update own challenge mastery" ON "public"."user_challenge_mastery"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can view own challenge mastery" ON "public"."user_challenge_mastery"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_challenge_mastery_service_role_all" ON "public"."user_challenge_mastery"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can view own checkpoint progress" ON "public"."user_checkpoint_progress"
  USING ((user_id = (select auth.uid())));

ALTER POLICY "user_checkpoint_progress_service_role_all" ON "public"."user_checkpoint_progress"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_connections_service_role_all" ON "public"."user_connections"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can view own consumables" ON "public"."user_consumables"
  USING ((user_id = (select auth.uid())));

ALTER POLICY "user_consumables_service_role_all" ON "public"."user_consumables"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_context_logs_service_role_all" ON "public"."user_context_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can view own daily crates" ON "public"."user_daily_crates"
  USING ((user_id = (select auth.uid())));

ALTER POLICY "user_daily_crates_service_role_all" ON "public"."user_daily_crates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can insert own daily social xp" ON "public"."user_daily_social_xp"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can update own daily social xp" ON "public"."user_daily_social_xp"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can view own daily social xp" ON "public"."user_daily_social_xp"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_daily_social_xp_service_role_all" ON "public"."user_daily_social_xp"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access" ON "public"."user_encryption_keys"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "Users can insert own keys" ON "public"."user_encryption_keys"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "user_encryption_keys_service_role_all" ON "public"."user_encryption_keys"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service manages participation" ON "public"."user_event_participation"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "Users see own participation" ON "public"."user_event_participation"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_event_participation_select_policy" ON "public"."user_event_participation"
  USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "user_event_participation_service_policy" ON "public"."user_event_participation"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "user_event_participation_service_role_all" ON "public"."user_event_participation"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_events_service_role_all" ON "public"."user_events"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_exercise_1rm_service_role_all" ON "public"."user_exercise_1rm"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_exercise_1rms_service_role_all" ON "public"."user_exercise_1rms"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_exercise_mastery_service_role_all" ON "public"."user_exercise_mastery"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can view own first time bonuses" ON "public"."user_first_time_bonuses"
  USING ((user_id = (select auth.uid())));

ALTER POLICY "user_first_time_bonuses_service_role_all" ON "public"."user_first_time_bonuses"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_inflammation_scans_delete_policy" ON "public"."user_inflammation_scans"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_inflammation_scans_insert_policy" ON "public"."user_inflammation_scans"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "user_inflammation_scans_select_policy" ON "public"."user_inflammation_scans"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_inflammation_scans_service_role_all" ON "public"."user_inflammation_scans"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_inflammation_scans_update_policy" ON "public"."user_inflammation_scans"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_injuries_service_role_all" ON "public"."user_injuries"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_insights_service_role_all" ON "public"."user_insights"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service manages streaks" ON "public"."user_login_streaks"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "Users see own streaks" ON "public"."user_login_streaks"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_login_streaks_select_policy" ON "public"."user_login_streaks"
  USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "user_login_streaks_service_policy" ON "public"."user_login_streaks"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "user_login_streaks_service_role_all" ON "public"."user_login_streaks"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_metrics_service_role_all" ON "public"."user_metrics"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_milestones_service_role_all" ON "public"."user_milestones"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can insert own monthly achievements" ON "public"."user_monthly_achievements"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can update own monthly achievements" ON "public"."user_monthly_achievements"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can view own monthly achievements" ON "public"."user_monthly_achievements"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_monthly_achievements_service_role_all" ON "public"."user_monthly_achievements"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_neat_achievements_service_role_all" ON "public"."user_neat_achievements"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_nutrition_preferences_service_role_all" ON "public"."user_nutrition_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can manage optimal times" ON "public"."user_optimal_send_times"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "Users can view own optimal times" ON "public"."user_optimal_send_times"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_optimal_send_times_service_role_all" ON "public"."user_optimal_send_times"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_penalties_select_policy" ON "public"."user_penalties"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_penalties_service_policy" ON "public"."user_penalties"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "user_penalties_service_role_all" ON "public"."user_penalties"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_privacy_settings_service_role_all" ON "public"."user_privacy_settings"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_program_assignments_service_role_all" ON "public"."user_program_assignments"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_progression_preferences_service_role_all" ON "public"."user_progression_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_recipes_service_role_all" ON "public"."user_recipes"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_rep_range_preferences_service_role_all" ON "public"."user_rep_range_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_rewards_select_policy" ON "public"."user_rewards"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_rewards_service_policy" ON "public"."user_rewards"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "user_rewards_service_role_all" ON "public"."user_rewards"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_rewards_update_policy" ON "public"."user_rewards"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_roi_metrics_service_role_all" ON "public"."user_roi_metrics"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_scheduling_preferences_service_role_all" ON "public"."user_scheduling_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_sessions_service_role_all" ON "public"."user_sessions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_settings_service_role_all" ON "public"."user_settings"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_skill_progress_service_role_all" ON "public"."user_skill_progress"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_streaks_service_role_all" ON "public"."user_streaks"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_subscriptions_service_role_all" ON "public"."user_subscriptions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_superset_history_service_role_all" ON "public"."user_superset_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can insert own superset logs" ON "public"."user_superset_logs"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can read own superset logs" ON "public"."user_superset_logs"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_superset_logs_service_role_all" ON "public"."user_superset_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_workout_patterns_service_role_all" ON "public"."user_workout_patterns"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "user_xp_select_policy" ON "public"."user_xp"
  USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "user_xp_service_policy" ON "public"."user_xp"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "user_xp_service_role_all" ON "public"."user_xp"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "users_full_access" ON "public"."users"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.uid()) = auth_id) OR ((select auth.uid()) IS NULL)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.uid()) = auth_id) OR ((select auth.uid()) IS NULL)));

ALTER POLICY "users_service_role_all" ON "public"."users"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "volume_increase_alerts_service_role_all" ON "public"."volume_increase_alerts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "warmup_exercise_logs_insert" ON "public"."warmup_exercise_logs"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "warmup_exercise_logs_select" ON "public"."warmup_exercise_logs"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "warmup_exercise_logs_service_role_all" ON "public"."warmup_exercise_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role full access warmup_stretch_preferences" ON "public"."warmup_stretch_preferences"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "Users can delete own warmup_stretch_preferences" ON "public"."warmup_stretch_preferences"
  USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "Users can insert own warmup_stretch_preferences" ON "public"."warmup_stretch_preferences"
  WITH CHECK ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "Users can update own warmup_stretch_preferences" ON "public"."warmup_stretch_preferences"
  USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "Users can view own warmup_stretch_preferences" ON "public"."warmup_stretch_preferences"
  USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "warmup_stretch_preferences_service_role_all" ON "public"."warmup_stretch_preferences"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "warmups_service_role_all" ON "public"."warmups"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "wearos_sync_events_insert_own" ON "public"."wearos_sync_events"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "wearos_sync_events_select_own" ON "public"."wearos_sync_events"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "wearos_sync_events_service_role" ON "public"."wearos_sync_events"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "wearos_sync_events_service_role_all" ON "public"."wearos_sync_events"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "weekly_nutrition_recommendations_service_role_all" ON "public"."weekly_nutrition_recommendations"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "weekly_personal_goals_service_role_all" ON "public"."weekly_personal_goals"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "weekly_plans_service_role_all" ON "public"."weekly_plans"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "weekly_program_progress_service_role_all" ON "public"."weekly_program_progress"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "weekly_summaries_service_role_all" ON "public"."weekly_summaries"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "weekly_volume_tracking_service_role_all" ON "public"."weekly_volume_tracking"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "weekly_volumes_service_role_all" ON "public"."weekly_volumes"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can delete own weight increments" ON "public"."weight_increments"
  USING ((((select auth.uid()) = user_id) OR ((user_id)::text = (select current_setting('app.current_user_id'::text, true)))));

ALTER POLICY "Users can insert own weight increments" ON "public"."weight_increments"
  WITH CHECK ((((select auth.uid()) = user_id) OR ((user_id)::text = (select current_setting('app.current_user_id'::text, true)))));

ALTER POLICY "Users can update own weight increments" ON "public"."weight_increments"
  USING ((((select auth.uid()) = user_id) OR ((user_id)::text = (select current_setting('app.current_user_id'::text, true)))));

ALTER POLICY "Users can view own weight increments" ON "public"."weight_increments"
  USING ((((select auth.uid()) = user_id) OR ((user_id)::text = (select current_setting('app.current_user_id'::text, true)))));

ALTER POLICY "weight_increments_service_role_all" ON "public"."weight_increments"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "weight_logs_service_role_all" ON "public"."weight_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service role can manage all window mode logs" ON "public"."window_mode_logs"
  USING ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text))
  WITH CHECK ((((select auth.jwt()) ->> 'role'::text) = 'service_role'::text));

ALTER POLICY "window_mode_logs_service_role_all" ON "public"."window_mode_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_challenges_service_role_all" ON "public"."workout_challenges"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_changes_service_role_all" ON "public"."workout_changes"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_completions_insert_own" ON "public"."workout_completions"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "workout_completions_select_own" ON "public"."workout_completions"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "workout_completions_service_role" ON "public"."workout_completions"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "workout_completions_service_role_all" ON "public"."workout_completions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_exits_service_role_all" ON "public"."workout_exits"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_feedback_service_role_all" ON "public"."workout_feedback"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_gallery_images_service_role_all" ON "public"."workout_gallery_images"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_generation_jobs_service_role_all" ON "public"."workout_generation_jobs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_history_imports_service_role_all" ON "public"."workout_history_imports"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Users can manage own workout_logs" ON "public"."workout_logs"
  USING (((( SELECT auth.role() AS role) = 'service_role'::text) OR (user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid()))))));

ALTER POLICY "workout_logs_insert_own" ON "public"."workout_logs"
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "workout_logs_select_own" ON "public"."workout_logs"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "workout_logs_service_role_all" ON "public"."workout_logs"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_logs_update_own" ON "public"."workout_logs"
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "workout_performance_summary_service_role_all" ON "public"."workout_performance_summary"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_regenerations_service_role_all" ON "public"."workout_regenerations"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_scheduling_history_service_role_all" ON "public"."workout_scheduling_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_shares_service_role_all" ON "public"."workout_shares"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_subjective_feedback_service_role_all" ON "public"."workout_subjective_feedback"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_summaries_service_role_all" ON "public"."workout_summaries"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workout_validation_limits_service_policy" ON "public"."workout_validation_limits"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "workout_validation_limits_service_role_all" ON "public"."workout_validation_limits"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "workouts_service_role_all" ON "public"."workouts"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "world_record_history_service_policy" ON "public"."world_record_history"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "world_record_history_service_role_all" ON "public"."world_record_history"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "world_records_service_policy" ON "public"."world_records"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "world_records_service_role_all" ON "public"."world_records"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "xp_audit_log_service_role_all" ON "public"."xp_audit_log"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "xp_audit_select_policy" ON "public"."xp_audit_log"
  USING (((select auth.uid()) = user_id));

ALTER POLICY "xp_audit_service_policy" ON "public"."xp_audit_log"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "Service manages bonus templates" ON "public"."xp_bonus_templates"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "xp_bonus_templates_service_role_all" ON "public"."xp_bonus_templates"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "Service manages events" ON "public"."xp_events"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "xp_events_service_role_all" ON "public"."xp_events"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

ALTER POLICY "xp_transactions_select_policy" ON "public"."xp_transactions"
  USING ((user_id IN ( SELECT users.id
   FROM users
  WHERE (users.auth_id = (select auth.uid())))));

ALTER POLICY "xp_transactions_service_policy" ON "public"."xp_transactions"
  USING (((select auth.role()) = 'service_role'::text));

ALTER POLICY "xp_transactions_service_role_all" ON "public"."xp_transactions"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

COMMIT;
