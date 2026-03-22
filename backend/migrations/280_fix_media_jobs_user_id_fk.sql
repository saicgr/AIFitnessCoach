-- Fix media_analysis_jobs.user_id FK: change reference from auth.users(id) to users(id).
--
-- The backend consistently uses users.id (backend DB UUID) for all operations.
-- The original migration referenced auth.users(id) but the backend passes users.id,
-- causing FK violations on every job insert.
--
-- Also update the SELECT RLS policy to correctly resolve auth_id via the users table.

-- Step 1: Drop old policies (must drop before changing FK)
DROP POLICY IF EXISTS "Users can view their own media jobs" ON media_analysis_jobs;

-- Step 2: Drop old FK constraint
ALTER TABLE media_analysis_jobs
    DROP CONSTRAINT IF EXISTS media_analysis_jobs_user_id_fkey;

-- Step 3: Add new FK referencing users(id)
ALTER TABLE media_analysis_jobs
    ADD CONSTRAINT media_analysis_jobs_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 4: Re-add SELECT policy using auth_id lookup
CREATE POLICY "Users can view their own media jobs"
    ON media_analysis_jobs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = media_analysis_jobs.user_id
              AND users.auth_id::text = auth.uid()::text
        )
    );
