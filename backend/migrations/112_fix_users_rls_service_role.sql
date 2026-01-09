-- Fix users table RLS policy to allow service_role access
-- The backend uses service_role key which needs explicit permission

BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "users_insert_policy" ON public.users;
DROP POLICY IF EXISTS "users_select_policy" ON public.users;
DROP POLICY IF EXISTS "users_update_policy" ON public.users;
DROP POLICY IF EXISTS "Users can delete own data" ON public.users;

-- CREATE INSERT policy: Allow user creation or service_role
CREATE POLICY "users_insert_policy" ON public.users FOR INSERT
WITH CHECK (
    ((select auth.uid()) = auth_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

-- CREATE SELECT policy: Users can view own data or service_role can view all
CREATE POLICY "users_select_policy" ON public.users FOR SELECT
USING (
    ((select auth.uid()) = auth_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

-- CREATE UPDATE policy: Users can update own data or service_role can update all
CREATE POLICY "users_update_policy" ON public.users FOR UPDATE
USING (
    ((select auth.uid()) = auth_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

-- CREATE DELETE policy: Users can delete own data or service_role can delete all
CREATE POLICY "users_delete_policy" ON public.users FOR DELETE
USING (
    ((select auth.uid()) = auth_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

COMMIT;
