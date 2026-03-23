-- Migration 1875: RLS Audit Safety Net
--
-- Purpose: Ensure Row Level Security is enabled and proper policies exist on
-- sensitive user-data tables that may not have been covered by previous migrations.
-- This is a safety-net audit — all statements are idempotent and safe to re-run.
--
-- Tables covered:
--   chat_history, workout_logs, direct_messages,
--   demo_sessions, chat_interaction_analytics, feature_usage
--
-- Date: 2026-03-23

-- =============================================================================
-- 1. Enable RLS on all target tables (idempotent — no-op if already enabled)
-- =============================================================================

ALTER TABLE chat_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE demo_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_interaction_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_usage ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 2. Create policies (using DO blocks to handle duplicate_object gracefully)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- chat_history
--   SELECT: own rows only
--   INSERT: own rows only
--   No UPDATE/DELETE for anon users (service_role only)
-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE POLICY "chat_history_select_own"
    ON chat_history FOR SELECT
    USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "chat_history_insert_own"
    ON chat_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- -----------------------------------------------------------------------------
-- workout_logs
--   SELECT: own rows only
--   INSERT: own rows only
--   UPDATE: own rows only
-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE POLICY "workout_logs_select_own"
    ON workout_logs FOR SELECT
    USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "workout_logs_insert_own"
    ON workout_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "workout_logs_update_own"
    ON workout_logs FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- -----------------------------------------------------------------------------
-- direct_messages
--   SELECT: sender or participant in the conversation
--   INSERT: sender only
-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE POLICY "direct_messages_select_participant"
    ON direct_messages FOR SELECT
    USING (
      auth.uid() = sender_id
      OR auth.uid() IN (
        SELECT user_id
        FROM conversation_participants
        WHERE conversation_id = direct_messages.conversation_id
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "direct_messages_insert_sender"
    ON direct_messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- -----------------------------------------------------------------------------
-- demo_sessions
--   No access for authenticated/anon users — service_role only.
--   We achieve this by enabling RLS (done above) and creating NO permissive
--   policies, which means all non-service_role requests are denied by default.
--   The explicit restrictive policy below documents the intent.
-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE POLICY "demo_sessions_deny_all"
    ON demo_sessions
    AS RESTRICTIVE
    FOR ALL
    USING (false);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- -----------------------------------------------------------------------------
-- chat_interaction_analytics
--   No SELECT for anon/authenticated (service_role only — analytics are backend-only)
--   INSERT: allow backend writes when user_id matches
-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE POLICY "chat_interaction_analytics_deny_select"
    ON chat_interaction_analytics
    AS RESTRICTIVE
    FOR SELECT
    USING (false);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "chat_interaction_analytics_insert_own"
    ON chat_interaction_analytics FOR INSERT
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- -----------------------------------------------------------------------------
-- feature_usage
--   SELECT: own rows only
--   INSERT: own rows only
--   No UPDATE/DELETE (already handled in migration 1866)
-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE POLICY "feature_usage_select_own"
    ON feature_usage FOR SELECT
    USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "feature_usage_insert_own"
    ON feature_usage FOR INSERT
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
