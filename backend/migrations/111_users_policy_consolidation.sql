-- Fix duplicate policies on users table
-- Consolidates multiple INSERT/SELECT/UPDATE policies into single policies

BEGIN;

-- Drop all duplicate policies
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Allow user creation" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own data" ON public.users;

-- Create consolidated policies
-- INSERT: Allow user creation (needed for signup) OR own profile insert
CREATE POLICY "users_insert_policy" ON public.users FOR INSERT 
WITH CHECK (((select auth.uid()) = auth_id) OR ((select auth.uid()) IS NULL));

-- SELECT: Users can view own data (includes null check for anonymous/system access)
CREATE POLICY "users_select_policy" ON public.users FOR SELECT 
USING ((((select auth.uid()) = auth_id) OR ((select auth.uid()) IS NULL)));

-- UPDATE: Users can update own data (includes null check for system access)
CREATE POLICY "users_update_policy" ON public.users FOR UPDATE 
USING ((((select auth.uid()) = auth_id) OR ((select auth.uid()) IS NULL)));

COMMIT;
