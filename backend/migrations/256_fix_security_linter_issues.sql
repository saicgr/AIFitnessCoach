-- Migration 256: Fix Supabase security linter issues
-- 1. Change SECURITY DEFINER views to SECURITY INVOKER
-- 2. Enable RLS on public lookup tables

-- ============================================================================
-- 1. Views: Switch from SECURITY DEFINER to SECURITY INVOKER
--    These are read-only views that don't need elevated privileges.
-- ============================================================================

ALTER VIEW IF EXISTS public.user_inflammation_history SET (security_invoker = on);
ALTER VIEW IF EXISTS public.cardio_session_stats SET (security_invoker = on);
ALTER VIEW IF EXISTS public.food_database_deduped SET (security_invoker = on);
ALTER VIEW IF EXISTS public.exercise_library_cleaned SET (security_invoker = on);
ALTER VIEW IF EXISTS public.user_staples_with_details SET (security_invoker = on);
ALTER VIEW IF EXISTS public.lifetime_member_benefits SET (security_invoker = on);
ALTER VIEW IF EXISTS public.subscription_pause_metrics SET (security_invoker = on);
ALTER VIEW IF EXISTS public.upcoming_renewals SET (security_invoker = on);
ALTER VIEW IF EXISTS public.user_inflammation_stats SET (security_invoker = on);
ALTER VIEW IF EXISTS public.world_records_leaderboard SET (security_invoker = on);
ALTER VIEW IF EXISTS public.fasting_performance_summary SET (security_invoker = on);
ALTER VIEW IF EXISTS public.coach_persona_popularity SET (security_invoker = on);
ALTER VIEW IF EXISTS public.admin_pending_merch_claims SET (security_invoker = on);
ALTER VIEW IF EXISTS public.v_warmups_with_muscles SET (security_invoker = on);
ALTER VIEW IF EXISTS public.latest_cardio_metrics SET (security_invoker = on);
ALTER VIEW IF EXISTS public.neat_user_dashboard SET (security_invoker = on);
ALTER VIEW IF EXISTS public.user_milestone_progress SET (security_invoker = on);
ALTER VIEW IF EXISTS public.window_mode_analytics SET (security_invoker = on);
ALTER VIEW IF EXISTS public.user_subscription_history_readable SET (security_invoker = on);
ALTER VIEW IF EXISTS public.recent_cardio_sessions SET (security_invoker = on);
ALTER VIEW IF EXISTS public.frequently_swapped_exercises SET (security_invoker = on);
ALTER VIEW IF EXISTS public.fasting_weight_trend SET (security_invoker = on);
ALTER VIEW IF EXISTS public.saved_foods_exploded SET (security_invoker = on);
ALTER VIEW IF EXISTS public.static_hold_exercises SET (security_invoker = on);
ALTER VIEW IF EXISTS public.habit_weekly_summary_view SET (security_invoker = on);
ALTER VIEW IF EXISTS public.warmup_stretch_exercises SET (security_invoker = on);
ALTER VIEW IF EXISTS public.retention_offer_metrics SET (security_invoker = on);
ALTER VIEW IF EXISTS public.admin_fraud_dashboard SET (security_invoker = on);
ALTER VIEW IF EXISTS public.stretch_exercises_cleaned SET (security_invoker = on);
ALTER VIEW IF EXISTS public.user_swap_patterns SET (security_invoker = on);
ALTER VIEW IF EXISTS public.today_habits_view SET (security_invoker = on);
ALTER VIEW IF EXISTS public.warmup_exercises_cleaned SET (security_invoker = on);
ALTER VIEW IF EXISTS public.v_stretches_with_muscles SET (security_invoker = on);

-- ============================================================================
-- 2. Tables: Enable RLS on public lookup/reference tables
--    These are read-only reference data (no user-specific rows).
-- ============================================================================

-- checkpoint_rewards: XP reward definitions per checkpoint type
ALTER TABLE public.checkpoint_rewards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on checkpoint_rewards"
  ON public.checkpoint_rewards FOR SELECT USING (true);

-- food_database: Curated food nutrition reference (500K+ items)
ALTER TABLE public.food_database ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on food_database"
  ON public.food_database FOR SELECT USING (true);

-- level_rewards: Reward definitions per level milestone
ALTER TABLE public.level_rewards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on level_rewards"
  ON public.level_rewards FOR SELECT USING (true);
