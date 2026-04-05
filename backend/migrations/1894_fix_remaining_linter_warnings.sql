-- Migration 1894: Fix remaining Supabase linter warnings
-- Date: 2026-04-04
--
-- Fixes 4 categories:
--   1. function_search_path_mutable (86 functions) - SET search_path = public
--   2. unindexed_foreign_keys (20 FKs) - CREATE INDEX CONCURRENTLY
--   3. materialized_view_in_api (4 views) - REVOKE SELECT from anon/authenticated
--   4. extension_in_public (1 extension) - Move pg_trgm to extensions schema
--
-- NOTE: CREATE INDEX CONCURRENTLY cannot run inside a transaction block.
--       The runner script handles this by executing index creation outside transactions.

-- ============================================================================
-- PART 1: Fix function_search_path_mutable (86 custom functions)
-- ============================================================================
-- These ALTER FUNCTION statements set an immutable search_path on each function
-- so that the function always resolves unqualified names in the public schema.
-- pg_trgm extension functions (31) are excluded -- they move with the extension.

ALTER FUNCTION public.attempt_world_record(p_user_id uuid, p_record_type text, p_new_value numeric, p_exercise_name text) SET search_path = public;
ALTER FUNCTION public.award_reward(p_user_id uuid, p_reward_template_id character varying, p_trigger_description text) SET search_path = public;
ALTER FUNCTION public.award_xp(p_user_id uuid, p_xp_amount integer, p_source text, p_source_id text, p_description text, p_is_verified boolean) SET search_path = public;
ALTER FUNCTION public.calculate_estimated_1rm(p_weight numeric, p_reps integer) SET search_path = public;
ALTER FUNCTION public.calculate_fasting_weight_correlation(p_user_id uuid, p_start_date date, p_end_date date) SET search_path = public;
ALTER FUNCTION public.calculate_user_roi_metrics(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.can_participate_in_records(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.check_and_award_milestones(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.claim_reward(p_user_id uuid, p_reward_id uuid, p_delivery_email text, p_delivery_details jsonb) SET search_path = public;
ALTER FUNCTION public.cleanup_expired_insight_cache() SET search_path = public;
ALTER FUNCTION public.create_default_gym_profile_if_needed(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.enable_double_xp_event(p_event_name text, p_event_type text, p_multiplier numeric, p_duration_hours integer, p_admin_id uuid) SET search_path = public;
ALTER FUNCTION public.ensure_single_active_gym_profile() SET search_path = public;
ALTER FUNCTION public.ensure_single_current_workout() SET search_path = public;
ALTER FUNCTION public.expire_old_penalties() SET search_path = public;
ALTER FUNCTION public.find_next_exercise_variant(p_exercise_name character varying) SET search_path = public;
ALTER FUNCTION public.fuzzy_search_exercises(search_term text, limit_count integer) SET search_path = public;
ALTER FUNCTION public.fuzzy_search_exercises_api(search_term text, equipment_filter text, body_part_filter text, limit_count integer) SET search_path = public;
ALTER FUNCTION public.get_achievement_progress(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_active_xp_events() SET search_path = public;
ALTER FUNCTION public.get_exercise_history(p_user_id uuid, p_exercise_name text, p_limit integer) SET search_path = public;
ALTER FUNCTION public.get_fasting_score_trend(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_feed_for_user(p_user_id uuid, p_activity_type text, p_limit integer, p_offset integer, p_sort_by text) SET search_path = public;
ALTER FUNCTION public.get_flexibility_score(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_flexibility_trend(p_user_id uuid, p_test_type character varying, p_days integer) SET search_path = public;
ALTER FUNCTION public.get_friend_suggestions_rpc(p_user_id uuid, p_limit integer) SET search_path = public;
ALTER FUNCTION public.get_friends_on_goal(p_user_id uuid, p_exercise_name character varying, p_goal_type character varying, p_week_start date) SET search_path = public;
ALTER FUNCTION public.get_hormone_supportive_exercises(p_hormone_goals text[], p_cycle_phase text, p_gender text, p_limit integer) SET search_path = public;
ALTER FUNCTION public.get_hyrox_division_weights(p_division text) SET search_path = public;
ALTER FUNCTION public.get_hyrox_program_tier(p_race_date date) SET search_path = public;
ALTER FUNCTION public.get_kegel_exercises_by_focus(p_focus_area text, p_difficulty_level integer) SET search_path = public;
ALTER FUNCTION public.get_latest_strength_baseline(p_user_id uuid, p_exercise_name character varying) SET search_path = public;
ALTER FUNCTION public.get_latest_sustainability(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_latest_tdee(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_level_info(p_level integer) SET search_path = public;
ALTER FUNCTION public.get_login_streak(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_or_create_conversation(user1_id uuid, user2_id uuid) SET search_path = public;
ALTER FUNCTION public.get_primary_nutrition_goal(goals text[]) SET search_path = public;
ALTER FUNCTION public.get_tdee_trend(p_user_id uuid, p_weeks integer) SET search_path = public;
ALTER FUNCTION public.get_user_conversations(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_user_leaderboard_rank(p_user_id uuid, p_leaderboard_type character varying, p_country_filter character varying) SET search_path = public;
ALTER FUNCTION public.get_user_rewards(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_user_world_records(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_user_xp_summary(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.get_workout_counts(p_user_ids uuid[]) SET search_path = public;
ALTER FUNCTION public.get_world_records() SET search_path = public;
ALTER FUNCTION public.get_xp_title(p_level integer, p_prestige integer) SET search_path = public;
ALTER FUNCTION public.increment_feature_usage(p_user_id uuid, p_feature_key character varying, p_usage_date date, p_metadata jsonb) SET search_path = public;
ALTER FUNCTION public.initialize_user_xp() SET search_path = public;
ALTER FUNCTION public.is_user_on_probation(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.log_xp_action(p_user_id uuid, p_action text, p_amount integer, p_reason text, p_source_type text, p_source_id text, p_ip_address inet, p_device_fingerprint text, p_is_verified boolean) SET search_path = public;
ALTER FUNCTION public.normalize_exercise_name(name text) SET search_path = public;
ALTER FUNCTION public.prevent_orphaned_workouts() SET search_path = public;
ALTER FUNCTION public.prevent_sentinel_user_delete() SET search_path = public;
ALTER FUNCTION public.process_referral_milestone(p_referred_id uuid, p_milestone text) SET search_path = public;
ALTER FUNCTION public.record_workout_regeneration(p_user_id uuid, p_original_workout_id uuid, p_new_workout_id uuid, p_difficulty character varying, p_duration_minutes integer, p_workout_type character varying, p_equipment jsonb, p_focus_areas jsonb, p_injuries jsonb, p_custom_focus_area character varying, p_custom_injury character varying, p_generation_method character varying, p_used_rag boolean, p_generation_time_ms integer) SET search_path = public;
ALTER FUNCTION public.resolve_equipment_name(raw_name text) SET search_path = public;
ALTER FUNCTION public.revoke_xp(p_user_id uuid, p_amount integer, p_reason text, p_admin_id uuid) SET search_path = public;
ALTER FUNCTION public.save_user_profile(p_user_id uuid, p_name character varying, p_email text, p_fitness_level character varying, p_goals character varying, p_equipment character varying, p_preferences jsonb, p_active_injuries jsonb, p_height_cm double precision, p_weight_kg double precision, p_target_weight_kg double precision, p_age integer, p_date_of_birth date, p_gender character varying, p_activity_level character varying, p_onboarding_completed boolean, p_coach_selected boolean, p_paywall_completed boolean, p_timezone text) SET search_path = public;
ALTER FUNCTION public.scheduled_update_trust_levels() SET search_path = public;
ALTER FUNCTION public.sync_variant_text() SET search_path = public;
ALTER FUNCTION public.trigger_check_milestones_on_workout() SET search_path = public;
ALTER FUNCTION public.update_1rm_timestamp() SET search_path = public;
ALTER FUNCTION public.update_adherence_timestamp() SET search_path = public;
ALTER FUNCTION public.update_chat_message_reports_updated_at() SET search_path = public;
ALTER FUNCTION public.update_cooking_conversion_updated_at() SET search_path = public;
ALTER FUNCTION public.update_exercise_relationships_updated_at() SET search_path = public;
ALTER FUNCTION public.update_fasting_weight_correlation() SET search_path = public;
ALTER FUNCTION public.update_food_overrides_updated_at() SET search_path = public;
ALTER FUNCTION public.update_gym_profiles_updated_at() SET search_path = public;
ALTER FUNCTION public.update_habit_streaks_updated_at() SET search_path = public;
ALTER FUNCTION public.update_habits_updated_at() SET search_path = public;
ALTER FUNCTION public.update_hashtag_post_count() SET search_path = public;
ALTER FUNCTION public.update_photo_comparisons_updated_at() SET search_path = public;
ALTER FUNCTION public.update_recipe_log_count() SET search_path = public;
ALTER FUNCTION public.update_sound_preferences_updated_at() SET search_path = public;
ALTER FUNCTION public.update_stats_gallery_updated_at() SET search_path = public;
ALTER FUNCTION public.update_trust_level(p_user_id uuid) SET search_path = public;
ALTER FUNCTION public.update_updated_at_column() SET search_path = public;
ALTER FUNCTION public.upsert_daily_adherence(p_user_id uuid, p_log_date date, p_target_calories integer, p_target_protein_g numeric, p_target_carbs_g numeric, p_target_fat_g numeric, p_actual_calories integer, p_actual_protein_g numeric, p_actual_carbs_g numeric, p_actual_fat_g numeric, p_calorie_adherence_pct numeric, p_protein_adherence_pct numeric, p_carbs_adherence_pct numeric, p_fat_adherence_pct numeric, p_overall_adherence_pct numeric, p_calories_over boolean, p_protein_over boolean, p_meals_logged integer) SET search_path = public;
ALTER FUNCTION public.user_frequently_swaps(p_user_id uuid, p_exercise text) SET search_path = public;
ALTER FUNCTION public.user_needs_recalibration(p_user_id uuid, p_days_threshold integer) SET search_path = public;
ALTER FUNCTION public.validate_hiit_no_static_holds(p_workout_id uuid) SET search_path = public;
ALTER FUNCTION public.validate_muscle_focus_points() SET search_path = public;
ALTER FUNCTION public.validate_workout_data(p_user_id uuid, p_workout_data jsonb) SET search_path = public;
ALTER FUNCTION public.validate_workout_insert() SET search_path = public;


-- ============================================================================
-- PART 2: Fix unindexed_foreign_keys (20 indexes)
-- ============================================================================
-- These must be run OUTSIDE a transaction block (CREATE INDEX CONCURRENTLY).
-- The runner script executes these individually with autocommit.

-- INDEX: activity_hashtags.hashtag_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_activity_hashtags_hashtag_id ON public.activity_hashtags (hashtag_id);

-- INDEX: activity_reactions.user_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_activity_reactions_user_id ON public.activity_reactions (user_id);

-- INDEX: challenge_participants.user_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_challenge_participants_user_id ON public.challenge_participants (user_id);

-- INDEX: conversation_participants.user_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_conversation_participants_user_id ON public.conversation_participants (user_id);

-- INDEX: equipment_substitutions.target_equipment
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_equipment_substitutions_target_equipment ON public.equipment_substitutions (target_equipment);

-- INDEX: friend_requests.to_user_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_friend_requests_to_user_id ON public.friend_requests (to_user_id);

-- INDEX: goal_invites.invitee_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_goal_invites_invitee_id ON public.goal_invites (invitee_id);

-- INDEX: referral_tracking.referred_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_referral_tracking_referred_id ON public.referral_tracking (referred_id);

-- INDEX: saved_workouts.source_activity_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_saved_workouts_source_activity_id ON public.saved_workouts (source_activity_id);

-- INDEX: shared_goals.joined_user_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shared_goals_joined_user_id ON public.shared_goals (joined_user_id);

-- INDEX: story_views.viewer_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_story_views_viewer_id ON public.story_views (viewer_id);

-- INDEX: user_blocks.blocked_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_blocks_blocked_id ON public.user_blocks (blocked_id);

-- INDEX: user_connections.following_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_connections_following_id ON public.user_connections (following_id);

-- INDEX: user_event_participation.event_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_event_participation_event_id ON public.user_event_participation (event_id);

-- INDEX: user_milestones.milestone_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_milestones_milestone_id ON public.user_milestones (milestone_id);

-- INDEX: user_neat_achievements.achievement_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_neat_achievements_achievement_id ON public.user_neat_achievements (achievement_id);

-- INDEX: user_skill_progress.chain_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_skill_progress_chain_id ON public.user_skill_progress (chain_id);

-- INDEX: workout_feedback.workout_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_workout_feedback_workout_id ON public.workout_feedback (workout_id);

-- INDEX: workout_shares.workout_log_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_workout_shares_workout_log_id ON public.workout_shares (workout_log_id);

-- INDEX: workout_summaries.user_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_workout_summaries_user_id ON public.workout_summaries (user_id);


-- ============================================================================
-- PART 3: Fix materialized_view_in_api (4 materialized views)
-- ============================================================================
-- Revoke API access so PostgREST does not expose these materialized views.

REVOKE SELECT ON public.leaderboard_challenge_masters FROM anon, authenticated;
REVOKE SELECT ON public.leaderboard_streaks FROM anon, authenticated;
REVOKE SELECT ON public.leaderboard_volume_kings FROM anon, authenticated;
REVOKE SELECT ON public.leaderboard_weekly_challenges FROM anon, authenticated;


-- ============================================================================
-- PART 4: Fix extension_in_public (move pg_trgm to extensions schema)
-- ============================================================================
-- Moving the extension also moves all its 31 functions/operators/types out of public.
-- This resolves both the extension_in_public warning AND 31 of the function_search_path_mutable
-- warnings (since extension functions are no longer in public schema).

ALTER EXTENSION pg_trgm SET SCHEMA extensions;
