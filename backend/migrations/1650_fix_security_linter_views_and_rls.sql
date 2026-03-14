-- ============================================================================
-- Migration 1650: Fix Supabase security linter issues
-- Date: 2026-03-12
-- ============================================================================
--
-- This migration fixes two categories of issues flagged by the Supabase
-- database security linter:
--
-- 1. SECURITY DEFINER views (2 views) - convert to SECURITY INVOKER
-- 2. Tables without RLS (9 tables) - enable RLS and add appropriate policies
--
-- IMPORTANT: The backend connects via service_role key which bypasses RLS.
-- These policies only affect direct PostgREST / Supabase client access.
--
-- ============================================================================

-- ============================================================================
-- PART 1: Fix SECURITY DEFINER views
-- ============================================================================

-- 1a. exercise_library_cleaned - public read-only exercise data
ALTER VIEW public.exercise_library_cleaned SET (security_invoker = true);

-- 1b. user_staples_with_details - user-scoped staple exercises with joins
ALTER VIEW public.user_staples_with_details SET (security_invoker = true);

-- ============================================================================
-- PART 2: Enable RLS on 9 tables and add appropriate policies
-- ============================================================================

-- ============================================================================
-- 2a. user_blocks (user data - blocker_id scoped)
-- ============================================================================

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

-- Users can see blocks they created
CREATE POLICY "Users can view own blocks"
    ON public.user_blocks FOR SELECT
    USING (auth.uid() = blocker_id);

-- Users can create blocks where they are the blocker
CREATE POLICY "Users can create blocks"
    ON public.user_blocks FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

-- Users can delete their own blocks (unblock)
CREATE POLICY "Users can delete own blocks"
    ON public.user_blocks FOR DELETE
    USING (auth.uid() = blocker_id);

-- Service role bypass for backend operations
CREATE POLICY "Service role full access on user_blocks"
    ON public.user_blocks FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- 2b. content_reports (user data - reporter_id scoped)
-- ============================================================================

ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

-- Users can see reports they created
CREATE POLICY "Users can view own reports"
    ON public.content_reports FOR SELECT
    USING (auth.uid() = reporter_id);

-- Users can create reports where they are the reporter
CREATE POLICY "Users can create reports"
    ON public.content_reports FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

-- Users can delete their own reports
CREATE POLICY "Users can delete own reports"
    ON public.content_reports FOR DELETE
    USING (auth.uid() = reporter_id);

-- Service role bypass for backend/admin operations
CREATE POLICY "Service role full access on content_reports"
    ON public.content_reports FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- 2c. stories (user data - user_id scoped, publicly readable)
-- ============================================================================

ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;

-- All authenticated users can see stories (social/public content)
CREATE POLICY "Authenticated users can view stories"
    ON public.stories FOR SELECT
    USING (auth.role() = 'authenticated');

-- Users can create their own stories
CREATE POLICY "Users can create own stories"
    ON public.stories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own stories
CREATE POLICY "Users can update own stories"
    ON public.stories FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own stories
CREATE POLICY "Users can delete own stories"
    ON public.stories FOR DELETE
    USING (auth.uid() = user_id);

-- Service role bypass for backend operations
CREATE POLICY "Service role full access on stories"
    ON public.stories FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- 2d. story_views (user data - viewer_id scoped)
-- ============================================================================

ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;

-- Authenticated users can see story views (story owners need to see who viewed)
CREATE POLICY "Authenticated users can view story_views"
    ON public.story_views FOR SELECT
    USING (auth.role() = 'authenticated');

-- Users can record their own views
CREATE POLICY "Users can insert own story views"
    ON public.story_views FOR INSERT
    WITH CHECK (auth.uid() = viewer_id);

-- Service role bypass for backend operations
CREATE POLICY "Service role full access on story_views"
    ON public.story_views FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- 2e. equipment_types (reference data - public read, admin write)
-- ============================================================================

ALTER TABLE public.equipment_types ENABLE ROW LEVEL SECURITY;

-- Everyone can read equipment types (reference data)
CREATE POLICY "Anyone can read equipment_types"
    ON public.equipment_types FOR SELECT
    USING (true);

-- Only service role can modify (admin operations)
CREATE POLICY "Service role can manage equipment_types"
    ON public.equipment_types FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- 2f. equipment_substitutions (reference data - public read, admin write)
-- ============================================================================

ALTER TABLE public.equipment_substitutions ENABLE ROW LEVEL SECURITY;

-- Everyone can read equipment substitutions (reference data)
CREATE POLICY "Anyone can read equipment_substitutions"
    ON public.equipment_substitutions FOR SELECT
    USING (true);

-- Only service role can modify (admin operations)
CREATE POLICY "Service role can manage equipment_substitutions"
    ON public.equipment_substitutions FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- 2g. hashtags (reference/social data - public read, admin write)
-- ============================================================================

ALTER TABLE public.hashtags ENABLE ROW LEVEL SECURITY;

-- Everyone can read hashtags (reference data used in social features)
CREATE POLICY "Anyone can read hashtags"
    ON public.hashtags FOR SELECT
    USING (true);

-- Only service role can modify (created via triggers/backend)
CREATE POLICY "Service role can manage hashtags"
    ON public.hashtags FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- 2h. activity_hashtags (join table - public read, admin write)
-- ============================================================================

ALTER TABLE public.activity_hashtags ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read activity hashtags
CREATE POLICY "Authenticated users can read activity_hashtags"
    ON public.activity_hashtags FOR SELECT
    USING (auth.role() = 'authenticated');

-- Only service role can modify (created via backend)
CREATE POLICY "Service role can manage activity_hashtags"
    ON public.activity_hashtags FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- 2i. program_variant_weeks_copy (backup table - public read, admin write)
-- ============================================================================

ALTER TABLE public.program_variant_weeks_copy ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read (reference/backup data)
CREATE POLICY "Authenticated users can read program_variant_weeks_copy"
    ON public.program_variant_weeks_copy FOR SELECT
    USING (auth.role() = 'authenticated');

-- Only service role can modify
CREATE POLICY "Service role can manage program_variant_weeks_copy"
    ON public.program_variant_weeks_copy FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- PART 3: Grant permissions on views (ensure authenticated can read)
-- ============================================================================

GRANT SELECT ON public.exercise_library_cleaned TO authenticated;
GRANT SELECT ON public.exercise_library_cleaned TO anon;
GRANT SELECT ON public.user_staples_with_details TO authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Summary:
--   - 2 views converted from SECURITY DEFINER to SECURITY INVOKER
--   - 9 tables now have RLS enabled with appropriate policies
--   - User-scoped tables: user_blocks, content_reports, stories, story_views
--   - Reference/lookup tables: equipment_types, equipment_substitutions, hashtags
--   - Social join table: activity_hashtags
--   - Backup table: program_variant_weeks_copy
-- ============================================================================
