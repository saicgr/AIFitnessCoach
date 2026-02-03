-- Migration: 211_fix_security_definer_issues.sql
-- Description: Fix security issues flagged by Supabase linter
-- Date: 2025-02-02
--
-- This migration fixes:
-- 1. SECURITY DEFINER views - setting them to SECURITY INVOKER
-- 2. Tables missing RLS - enabling RLS and adding appropriate policies
--
-- Affected views (8):
--   - program_exercises_with_media
--   - program_exercises_with_media_fallback
--   - program_exercises_with_fallback
--   - program_analysis
--   - program_exercises_flat
--   - exercise_library_cleaned
--   - unmatched_exercises
--   - all_exercises_combined
--
-- Affected tables (4):
--   - exercise_canonical
--   - exercise_demos
--   - exercise_aliases
--   - app_config

-- ============================================
-- PART 1: Fix SECURITY DEFINER views
-- Use ALTER VIEW to set security_invoker without recreating
-- ============================================

-- Set security_invoker on all affected views (if they exist)
DO $$
DECLARE
    view_name TEXT;
    view_names TEXT[] := ARRAY[
        'program_exercises_flat',
        'program_exercises_with_media',
        'program_exercises_with_media_fallback',
        'program_exercises_with_fallback',
        'program_analysis',
        'exercise_library_cleaned',
        'unmatched_exercises',
        'all_exercises_combined'
    ];
BEGIN
    FOREACH view_name IN ARRAY view_names
    LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.views
            WHERE table_name = view_name AND table_schema = 'public'
        ) THEN
            EXECUTE format('ALTER VIEW public.%I SET (security_invoker = true)', view_name);
            RAISE NOTICE 'Set security_invoker on view: %', view_name;
        ELSE
            RAISE NOTICE 'View does not exist, skipping: %', view_name;
        END IF;
    END LOOP;
END $$;

-- ============================================
-- PART 2: Enable RLS on tables missing it
-- ============================================

-- 1. exercise_canonical table
-- This is read-only reference data, all users should be able to read it
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'exercise_canonical' AND table_schema = 'public') THEN
        ALTER TABLE exercise_canonical ENABLE ROW LEVEL SECURITY;

        -- Drop existing policies if any
        DROP POLICY IF EXISTS "Anyone can read exercise_canonical" ON exercise_canonical;
        DROP POLICY IF EXISTS "Service role can modify exercise_canonical" ON exercise_canonical;

        -- Allow all users (authenticated and anon) to read
        CREATE POLICY "Anyone can read exercise_canonical" ON exercise_canonical
            FOR SELECT
            USING (true);

        -- Only service role can modify
        CREATE POLICY "Service role can modify exercise_canonical" ON exercise_canonical
            FOR ALL
            USING (auth.role() = 'service_role');

        GRANT SELECT ON exercise_canonical TO authenticated;
        GRANT SELECT ON exercise_canonical TO anon;

        RAISE NOTICE 'Enabled RLS on exercise_canonical';
    ELSE
        RAISE NOTICE 'Table exercise_canonical does not exist, skipping';
    END IF;
END $$;

-- 2. exercise_demos table
-- This is read-only reference data for exercise demonstrations
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'exercise_demos' AND table_schema = 'public') THEN
        ALTER TABLE exercise_demos ENABLE ROW LEVEL SECURITY;

        DROP POLICY IF EXISTS "Anyone can read exercise_demos" ON exercise_demos;
        DROP POLICY IF EXISTS "Service role can modify exercise_demos" ON exercise_demos;

        CREATE POLICY "Anyone can read exercise_demos" ON exercise_demos
            FOR SELECT
            USING (true);

        CREATE POLICY "Service role can modify exercise_demos" ON exercise_demos
            FOR ALL
            USING (auth.role() = 'service_role');

        GRANT SELECT ON exercise_demos TO authenticated;
        GRANT SELECT ON exercise_demos TO anon;

        RAISE NOTICE 'Enabled RLS on exercise_demos';
    ELSE
        RAISE NOTICE 'Table exercise_demos does not exist, skipping';
    END IF;
END $$;

-- 3. exercise_aliases table
-- This is read-only reference data mapping exercise names to canonical forms
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'exercise_aliases' AND table_schema = 'public') THEN
        ALTER TABLE exercise_aliases ENABLE ROW LEVEL SECURITY;

        DROP POLICY IF EXISTS "Anyone can read exercise_aliases" ON exercise_aliases;
        DROP POLICY IF EXISTS "Service role can modify exercise_aliases" ON exercise_aliases;

        CREATE POLICY "Anyone can read exercise_aliases" ON exercise_aliases
            FOR SELECT
            USING (true);

        CREATE POLICY "Service role can modify exercise_aliases" ON exercise_aliases
            FOR ALL
            USING (auth.role() = 'service_role');

        GRANT SELECT ON exercise_aliases TO authenticated;
        GRANT SELECT ON exercise_aliases TO anon;

        RAISE NOTICE 'Enabled RLS on exercise_aliases';
    ELSE
        RAISE NOTICE 'Table exercise_aliases does not exist, skipping';
    END IF;
END $$;

-- 4. app_config table
-- This is read-only configuration data
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'app_config' AND table_schema = 'public') THEN
        ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

        DROP POLICY IF EXISTS "Anyone can read app_config" ON app_config;
        DROP POLICY IF EXISTS "Service role can modify app_config" ON app_config;

        CREATE POLICY "Anyone can read app_config" ON app_config
            FOR SELECT
            USING (true);

        CREATE POLICY "Service role can modify app_config" ON app_config
            FOR ALL
            USING (auth.role() = 'service_role');

        GRANT SELECT ON app_config TO authenticated;
        GRANT SELECT ON app_config TO anon;

        RAISE NOTICE 'Enabled RLS on app_config';
    ELSE
        RAISE NOTICE 'Table app_config does not exist, skipping';
    END IF;
END $$;

-- ============================================
-- PART 3: Grant permissions on views
-- ============================================

DO $$
DECLARE
    view_name TEXT;
    view_names TEXT[] := ARRAY[
        'program_exercises_flat',
        'program_exercises_with_media',
        'program_analysis',
        'exercise_library_cleaned',
        'unmatched_exercises',
        'all_exercises_combined'
    ];
BEGIN
    FOREACH view_name IN ARRAY view_names
    LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.views
            WHERE table_name = view_name AND table_schema = 'public'
        ) THEN
            EXECUTE format('GRANT SELECT ON public.%I TO authenticated', view_name);
            EXECUTE format('GRANT SELECT ON public.%I TO anon', view_name);
            RAISE NOTICE 'Granted SELECT on view: %', view_name;
        END IF;
    END LOOP;
END $$;

-- ============================================
-- Summary
-- ============================================
-- This migration:
-- 1. Set security_invoker = true on 8 views (removes SECURITY DEFINER behavior)
-- 2. Enabled RLS on 4 tables and added appropriate policies
-- 3. All reference/read-only data is publicly readable
-- 4. Only service_role can modify reference data
