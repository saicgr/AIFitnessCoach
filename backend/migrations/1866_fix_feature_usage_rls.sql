-- Fix feature_usage RLS: restrict to SELECT + INSERT only
-- Users could previously UPDATE/DELETE their own rows via PostgREST,
-- allowing them to reset usage_count and bypass free-tier limits.

DROP POLICY IF EXISTS "Users can manage own feature usage" ON feature_usage;

CREATE POLICY "Users can read own feature usage" ON feature_usage
    FOR SELECT USING (
        user_id IN (SELECT id FROM users WHERE auth_id = (select auth.uid()))
    );

CREATE POLICY "Users can insert own feature usage" ON feature_usage
    FOR INSERT WITH CHECK (
        user_id IN (SELECT id FROM users WHERE auth_id = (select auth.uid()))
    );

-- UPDATE and DELETE are now only possible via service_role (backend).
