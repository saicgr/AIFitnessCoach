-- Migration 1946: fix 3 Supabase security linter errors.
-- Applied to prod Supabase 2026-04-18 via MCP.

-- 1. weekly_user_stats view: runs as view creator (elevated). Switch to
--    security_invoker so the view enforces the querying user's RLS + perms.
ALTER VIEW public.weekly_user_stats SET (security_invoker = true);

-- 2. public.share_events: RLS disabled. Users only see their own rows;
--    service role handles all writes.
ALTER TABLE public.share_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS share_events_select_own ON public.share_events;
CREATE POLICY share_events_select_own ON public.share_events
  FOR SELECT USING (
    user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
  );

DROP POLICY IF EXISTS share_events_insert_own ON public.share_events;
CREATE POLICY share_events_insert_own ON public.share_events
  FOR INSERT WITH CHECK (
    user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
  );

DROP POLICY IF EXISTS share_events_service_all ON public.share_events;
CREATE POLICY share_events_service_all ON public.share_events
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- 3. public.cosmetics: public catalog (badges, frames, chat titles).
--    Authenticated users can SELECT active rows; service role mutates.
ALTER TABLE public.cosmetics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cosmetics_select_active ON public.cosmetics;
CREATE POLICY cosmetics_select_active ON public.cosmetics
  FOR SELECT USING (is_active = TRUE);

DROP POLICY IF EXISTS cosmetics_service_all ON public.cosmetics;
CREATE POLICY cosmetics_service_all ON public.cosmetics
  FOR ALL TO service_role USING (true) WITH CHECK (true);
