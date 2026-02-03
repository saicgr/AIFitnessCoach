-- =============================================================================
-- Migration 216: Fix ALL Foreign Key References to Use public.users(id)
-- =============================================================================
-- This migration fixes 44 tables that incorrectly reference auth.users
-- instead of public.users(id). The backend always uses users.id via
-- get_current_user(), so all FKs must point to public.users(id).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- XP System (Migration 166) - 4 tables
-- -----------------------------------------------------------------------------
ALTER TABLE user_login_streaks DROP CONSTRAINT IF EXISTS user_login_streaks_user_id_fkey;
ALTER TABLE user_login_streaks ADD CONSTRAINT user_login_streaks_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE xp_events DROP CONSTRAINT IF EXISTS xp_events_created_by_fkey;
ALTER TABLE xp_events ADD CONSTRAINT xp_events_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE user_event_participation DROP CONSTRAINT IF EXISTS user_event_participation_user_id_fkey;
ALTER TABLE user_event_participation ADD CONSTRAINT user_event_participation_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE user_checkpoint_progress DROP CONSTRAINT IF EXISTS user_checkpoint_progress_user_id_fkey;
ALTER TABLE user_checkpoint_progress ADD CONSTRAINT user_checkpoint_progress_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- Milestones (Migration 100) - 2 tables
-- -----------------------------------------------------------------------------
ALTER TABLE user_milestones DROP CONSTRAINT IF EXISTS user_milestones_user_id_fkey;
ALTER TABLE user_milestones ADD CONSTRAINT user_milestones_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE user_roi_metrics DROP CONSTRAINT IF EXISTS user_roi_metrics_user_id_fkey;
ALTER TABLE user_roi_metrics ADD CONSTRAINT user_roi_metrics_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- Habits (Migration 128) - 3 tables
-- -----------------------------------------------------------------------------
ALTER TABLE habits DROP CONSTRAINT IF EXISTS habits_user_id_fkey;
ALTER TABLE habits ADD CONSTRAINT habits_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE habit_logs DROP CONSTRAINT IF EXISTS habit_logs_user_id_fkey;
ALTER TABLE habit_logs ADD CONSTRAINT habit_logs_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE habit_streaks DROP CONSTRAINT IF EXISTS habit_streaks_user_id_fkey;
ALTER TABLE habit_streaks ADD CONSTRAINT habit_streaks_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- Cardio (Migrations 082, 089, 109) - 4 tables
-- -----------------------------------------------------------------------------
ALTER TABLE cardio_metrics DROP CONSTRAINT IF EXISTS cardio_metrics_user_id_fkey;
ALTER TABLE cardio_metrics ADD CONSTRAINT cardio_metrics_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE cardio_sessions DROP CONSTRAINT IF EXISTS cardio_sessions_user_id_fkey;
ALTER TABLE cardio_sessions ADD CONSTRAINT cardio_sessions_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE cardio_progression_programs DROP CONSTRAINT IF EXISTS cardio_progression_programs_user_id_fkey;
ALTER TABLE cardio_progression_programs ADD CONSTRAINT cardio_progression_programs_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE cardio_progression_sessions DROP CONSTRAINT IF EXISTS cardio_progression_sessions_user_id_fkey;
ALTER TABLE cardio_progression_sessions ADD CONSTRAINT cardio_progression_sessions_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- Analytics (Migrations 096, 097, 098, 115, 116) - 8 tables
-- -----------------------------------------------------------------------------
ALTER TABLE progress_charts_views DROP CONSTRAINT IF EXISTS progress_charts_views_user_id_fkey;
ALTER TABLE progress_charts_views ADD CONSTRAINT progress_charts_views_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE workout_subjective_feedback DROP CONSTRAINT IF EXISTS workout_subjective_feedback_user_id_fkey;
ALTER TABLE workout_subjective_feedback ADD CONSTRAINT workout_subjective_feedback_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE streak_history DROP CONSTRAINT IF EXISTS streak_history_user_id_fkey;
ALTER TABLE streak_history ADD CONSTRAINT streak_history_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE workout_time_patterns DROP CONSTRAINT IF EXISTS workout_time_patterns_user_id_fkey;
ALTER TABLE workout_time_patterns ADD CONSTRAINT workout_time_patterns_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE streak_recovery_attempts DROP CONSTRAINT IF EXISTS streak_recovery_attempts_user_id_fkey;
ALTER TABLE streak_recovery_attempts ADD CONSTRAINT streak_recovery_attempts_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE daily_consistency_metrics DROP CONSTRAINT IF EXISTS daily_consistency_metrics_user_id_fkey;
ALTER TABLE daily_consistency_metrics ADD CONSTRAINT daily_consistency_metrics_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE exercise_personal_records DROP CONSTRAINT IF EXISTS exercise_personal_records_user_id_fkey;
ALTER TABLE exercise_personal_records ADD CONSTRAINT exercise_personal_records_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE muscle_analytics_logs DROP CONSTRAINT IF EXISTS muscle_analytics_logs_user_id_fkey;
ALTER TABLE muscle_analytics_logs ADD CONSTRAINT muscle_analytics_logs_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- Settings/Preferences (Migrations 018, 091, 093, 101) - 4 tables
-- -----------------------------------------------------------------------------
ALTER TABLE user_ai_settings DROP CONSTRAINT IF EXISTS user_ai_settings_user_id_fkey;
ALTER TABLE user_ai_settings ADD CONSTRAINT user_ai_settings_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE audio_preferences DROP CONSTRAINT IF EXISTS audio_preferences_user_id_fkey;
ALTER TABLE audio_preferences ADD CONSTRAINT audio_preferences_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE sound_preferences DROP CONSTRAINT IF EXISTS sound_preferences_user_id_fkey;
ALTER TABLE sound_preferences ADD CONSTRAINT sound_preferences_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE quick_workout_preferences DROP CONSTRAINT IF EXISTS quick_workout_preferences_user_id_fkey;
ALTER TABLE quick_workout_preferences ADD CONSTRAINT quick_workout_preferences_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- Support/Chat (Migrations 079, 126, 127) - 5 tables
-- -----------------------------------------------------------------------------
ALTER TABLE support_tickets DROP CONSTRAINT IF EXISTS support_tickets_user_id_fkey;
ALTER TABLE support_tickets ADD CONSTRAINT support_tickets_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE support_tickets DROP CONSTRAINT IF EXISTS support_tickets_agent_id_fkey;
ALTER TABLE support_tickets ADD CONSTRAINT support_tickets_agent_id_fkey
  FOREIGN KEY (agent_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE chat_message_reports DROP CONSTRAINT IF EXISTS chat_message_reports_user_id_fkey;
ALTER TABLE chat_message_reports ADD CONSTRAINT chat_message_reports_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE live_chat_presence DROP CONSTRAINT IF EXISTS live_chat_presence_user_id_fkey;
ALTER TABLE live_chat_presence ADD CONSTRAINT live_chat_presence_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE live_chat_queue DROP CONSTRAINT IF EXISTS live_chat_queue_user_id_fkey;
ALTER TABLE live_chat_queue ADD CONSTRAINT live_chat_queue_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- Feature Voting (Migration 046) - 2 tables
-- -----------------------------------------------------------------------------
ALTER TABLE feature_requests DROP CONSTRAINT IF EXISTS feature_requests_created_by_fkey;
ALTER TABLE feature_requests ADD CONSTRAINT feature_requests_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE feature_votes DROP CONSTRAINT IF EXISTS feature_votes_user_id_fkey;
ALTER TABLE feature_votes ADD CONSTRAINT feature_votes_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- Other Tables - 11 tables
-- -----------------------------------------------------------------------------
ALTER TABLE user_workout_patterns DROP CONSTRAINT IF EXISTS user_workout_patterns_user_id_fkey;
ALTER TABLE user_workout_patterns ADD CONSTRAINT user_workout_patterns_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE exercise_swaps DROP CONSTRAINT IF EXISTS exercise_swaps_user_id_fkey;
ALTER TABLE exercise_swaps ADD CONSTRAINT exercise_swaps_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE plan_previews DROP CONSTRAINT IF EXISTS plan_previews_user_id_fkey;
ALTER TABLE plan_previews ADD CONSTRAINT plan_previews_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE try_workout_sessions DROP CONSTRAINT IF EXISTS try_workout_sessions_user_id_fkey;
ALTER TABLE try_workout_sessions ADD CONSTRAINT try_workout_sessions_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE app_tour_sessions DROP CONSTRAINT IF EXISTS app_tour_sessions_user_id_fkey;
ALTER TABLE app_tour_sessions ADD CONSTRAINT app_tour_sessions_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE window_mode_logs DROP CONSTRAINT IF EXISTS window_mode_logs_user_id_fkey;
ALTER TABLE window_mode_logs ADD CONSTRAINT window_mode_logs_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE calibration_workouts DROP CONSTRAINT IF EXISTS calibration_workouts_user_id_fkey;
ALTER TABLE calibration_workouts ADD CONSTRAINT calibration_workouts_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE strength_baselines DROP CONSTRAINT IF EXISTS strength_baselines_user_id_fkey;
ALTER TABLE strength_baselines ADD CONSTRAINT strength_baselines_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE user_challenge_mastery DROP CONSTRAINT IF EXISTS user_challenge_mastery_user_id_fkey;
ALTER TABLE user_challenge_mastery ADD CONSTRAINT user_challenge_mastery_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE stats_gallery DROP CONSTRAINT IF EXISTS stats_gallery_user_id_fkey;
ALTER TABLE stats_gallery ADD CONSTRAINT stats_gallery_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE user_superset_logs DROP CONSTRAINT IF EXISTS user_superset_logs_user_id_fkey;
ALTER TABLE user_superset_logs ADD CONSTRAINT user_superset_logs_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- Fix RLS Policies for XP tables (use subquery for auth lookup)
-- The user_id column contains backend users.id, not auth.uid(), so we need
-- to lookup the users table to find the matching backend user
-- -----------------------------------------------------------------------------

-- user_xp RLS (from migration 161)
DROP POLICY IF EXISTS user_xp_select_policy ON user_xp;
CREATE POLICY user_xp_select_policy ON user_xp
    FOR SELECT
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- xp_transactions RLS (from migration 161)
DROP POLICY IF EXISTS xp_transactions_select_policy ON xp_transactions;
CREATE POLICY xp_transactions_select_policy ON xp_transactions
    FOR SELECT
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- user_login_streaks RLS
ALTER TABLE user_login_streaks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS user_login_streaks_select_policy ON user_login_streaks;
CREATE POLICY user_login_streaks_select_policy ON user_login_streaks
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
DROP POLICY IF EXISTS user_login_streaks_service_policy ON user_login_streaks;
CREATE POLICY user_login_streaks_service_policy ON user_login_streaks
    FOR ALL USING (auth.role() = 'service_role');

-- user_event_participation RLS
ALTER TABLE user_event_participation ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS user_event_participation_select_policy ON user_event_participation;
CREATE POLICY user_event_participation_select_policy ON user_event_participation
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
DROP POLICY IF EXISTS user_event_participation_service_policy ON user_event_participation;
CREATE POLICY user_event_participation_service_policy ON user_event_participation
    FOR ALL USING (auth.role() = 'service_role');

-- user_checkpoint_progress RLS
ALTER TABLE user_checkpoint_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS user_checkpoint_progress_select_policy ON user_checkpoint_progress;
CREATE POLICY user_checkpoint_progress_select_policy ON user_checkpoint_progress
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
DROP POLICY IF EXISTS user_checkpoint_progress_service_policy ON user_checkpoint_progress;
CREATE POLICY user_checkpoint_progress_service_policy ON user_checkpoint_progress
    FOR ALL USING (auth.role() = 'service_role');
