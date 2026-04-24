-- 1971: Repoint 14 tables' user_id FK from auth.users(id) to public.users(id).
--
-- Bug: The backend treats current_user["id"] as public.users.id (see
-- backend/core/auth.py line ~200 "Backend user ID for foreign keys"), and
-- every RPC/endpoint passes that value as p_user_id. But these 14 tables
-- had user_id FK pointing at auth.users(id) — which is a different UUID.
-- Result: every write has silently failed with 23503, which is why
-- level_up_events and the other 13 tables still have 0 rows in prod and
-- the user hit a 500 on /xp/claim-daily-crate and /xp/award-goal-xp
-- as soon as award_xp RPC reached distribute_level_rewards' INSERT
-- into level_up_events.
--
-- fitness_wrapped is intentionally excluded — wrapped_service.py writes
-- auth_id there by design, so its FK to auth.users(id) is correct.
-- support_tickets.assigned_to is also excluded — it references the
-- staff member's auth.users row, not the user's public.users row.

BEGIN;

ALTER TABLE public.level_up_events DROP CONSTRAINT IF EXISTS level_up_events_user_id_fkey;
ALTER TABLE public.level_up_events ADD CONSTRAINT level_up_events_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.conversion_triggers DROP CONSTRAINT IF EXISTS conversion_triggers_user_id_fkey;
ALTER TABLE public.conversion_triggers ADD CONSTRAINT conversion_triggers_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.daily_subjective_checkin DROP CONSTRAINT IF EXISTS daily_subjective_checkin_user_id_fkey;
ALTER TABLE public.daily_subjective_checkin ADD CONSTRAINT daily_subjective_checkin_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.feature_adoption DROP CONSTRAINT IF EXISTS feature_adoption_user_id_fkey;
ALTER TABLE public.feature_adoption ADD CONSTRAINT feature_adoption_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.food_reports DROP CONSTRAINT IF EXISTS food_reports_user_id_fkey;
ALTER TABLE public.food_reports ADD CONSTRAINT food_reports_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.sauna_logs DROP CONSTRAINT IF EXISTS sauna_logs_user_id_fkey;
ALTER TABLE public.sauna_logs ADD CONSTRAINT sauna_logs_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.schedule_items DROP CONSTRAINT IF EXISTS schedule_items_user_id_fkey;
ALTER TABLE public.schedule_items ADD CONSTRAINT schedule_items_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.tier_streaks DROP CONSTRAINT IF EXISTS tier_streaks_user_id_fkey;
ALTER TABLE public.tier_streaks ADD CONSTRAINT tier_streaks_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.user_cosmetics DROP CONSTRAINT IF EXISTS user_cosmetics_user_id_fkey;
ALTER TABLE public.user_cosmetics ADD CONSTRAINT user_cosmetics_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.user_rank_shield_cooldowns DROP CONSTRAINT IF EXISTS user_rank_shield_cooldowns_user_id_fkey;
ALTER TABLE public.user_rank_shield_cooldowns ADD CONSTRAINT user_rank_shield_cooldowns_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.user_tier_cumulative DROP CONSTRAINT IF EXISTS user_tier_cumulative_user_id_fkey;
ALTER TABLE public.user_tier_cumulative ADD CONSTRAINT user_tier_cumulative_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.user_tier_history DROP CONSTRAINT IF EXISTS user_tier_history_user_id_fkey;
ALTER TABLE public.user_tier_history ADD CONSTRAINT user_tier_history_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.weekly_leaderboard_archive DROP CONSTRAINT IF EXISTS weekly_leaderboard_archive_user_id_fkey;
ALTER TABLE public.weekly_leaderboard_archive ADD CONSTRAINT weekly_leaderboard_archive_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.weekly_tier_rewards_audit DROP CONSTRAINT IF EXISTS weekly_tier_rewards_audit_user_id_fkey;
ALTER TABLE public.weekly_tier_rewards_audit ADD CONSTRAINT weekly_tier_rewards_audit_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

COMMIT;
