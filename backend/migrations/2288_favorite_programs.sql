-- 2288: favorite_programs — persists the Program Detail page heart.
-- User-scoped favorites of curated `programs` library entries. Mirrors the
-- `favorite_exercises` table's RLS shape (self-scoped + a service-role bypass
-- for the FastAPI backend, which uses the service-role Supabase client).
--
-- Applied via Supabase MCP apply_migration on 2026-06-25 (project
-- hpbzfahijszqmgsybuor). This file is the repo record of that change.

CREATE TABLE IF NOT EXISTS public.favorite_programs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    program_id uuid NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    UNIQUE (user_id, program_id)
);

CREATE INDEX IF NOT EXISTS idx_favorite_programs_user_id
    ON public.favorite_programs (user_id);

ALTER TABLE public.favorite_programs ENABLE ROW LEVEL SECURITY;

-- Self-scoped policies (match favorite_exercises).
DROP POLICY IF EXISTS favorite_programs_select_policy ON public.favorite_programs;
CREATE POLICY favorite_programs_select_policy ON public.favorite_programs
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS favorite_programs_insert_policy ON public.favorite_programs;
CREATE POLICY favorite_programs_insert_policy ON public.favorite_programs
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS favorite_programs_delete_policy ON public.favorite_programs;
CREATE POLICY favorite_programs_delete_policy ON public.favorite_programs
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Service-role bypass for the FastAPI backend (service-role client).
DROP POLICY IF EXISTS favorite_programs_service_role_all ON public.favorite_programs;
CREATE POLICY favorite_programs_service_role_all ON public.favorite_programs
    FOR ALL
    USING (
        (SELECT current_setting('role')) = 'service_role'
        OR (SELECT current_setting('request.jwt.claim.role', true)) = 'service_role'
        OR (SELECT auth.role()) = 'service_role'
    )
    WITH CHECK (
        (SELECT current_setting('role')) = 'service_role'
        OR (SELECT current_setting('request.jwt.claim.role', true)) = 'service_role'
        OR (SELECT auth.role()) = 'service_role'
    );

COMMENT ON TABLE public.favorite_programs IS
    'User favorites of curated programs (Program Detail heart). Mig 2288.';
