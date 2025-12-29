-- Migration: Fix Supabase Security Linter Issues
-- Date: 2024-12-28
-- Fixes:
-- 1. Change SECURITY DEFINER views to SECURITY INVOKER
-- 2. Enable RLS on program_history table

-- ============================================
-- FIX 1: Change views from SECURITY DEFINER to SECURITY INVOKER
-- ============================================

-- Fix coach_persona_popularity view
ALTER VIEW public.coach_persona_popularity SET (security_invoker = true);

-- Fix user_activity_summary view
ALTER VIEW public.user_activity_summary SET (security_invoker = true);

-- Fix recent_errors view
ALTER VIEW public.recent_errors SET (security_invoker = true);

-- ============================================
-- FIX 2: Enable RLS on program_history table
-- ============================================

-- Enable RLS on program_history
ALTER TABLE public.program_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for program_history
-- Users can only see their own program history
CREATE POLICY "Users can view own program history"
    ON public.program_history
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own program history
CREATE POLICY "Users can insert own program history"
    ON public.program_history
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own program history
CREATE POLICY "Users can update own program history"
    ON public.program_history
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own program history
CREATE POLICY "Users can delete own program history"
    ON public.program_history
    FOR DELETE
    USING (auth.uid() = user_id);

-- Service role bypass for backend operations
CREATE POLICY "Service role has full access to program history"
    ON public.program_history
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');
