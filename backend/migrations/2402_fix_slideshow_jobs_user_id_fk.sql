-- Migration: 2402_fix_slideshow_jobs_user_id_fk.sql
-- Description: slideshow_jobs.user_id (migration 2267) was created
--              REFERENCES auth.users(id) — copied from media_analysis_jobs
--              (264) instead of matching its own sibling table workout_photos
--              (2265), which correctly targets users(id). Every write path
--              (api/v1/workout_photos.py create_slideshow) inserts
--              current_user["id"] — the backend `public.users.id` — never the
--              Supabase auth id. Any user whose public.users.id differs from
--              their auth.users.id (the normal case; they are independently
--              generated UUIDs, see core/auth.py) therefore violated
--              slideshow_jobs_user_id_fkey on every slideshow create.
--              Sentry PYTHON-FASTAPI-7N: "APIError: insert or update on table
--              "slideshow_jobs" violates foreign key constraint
--              "slideshow_jobs_user_id_fkey"" — surfaced to the client as a
--              generic 500 (rolled into the noisy PYTHON-FASTAPI-1X bucket,
--              which groups every "Response: 500 (Xms)" log line across all
--              endpoints under one Sentry issue by message-text fingerprint).
-- Created: 2026-08-05

ALTER TABLE slideshow_jobs DROP CONSTRAINT IF EXISTS slideshow_jobs_user_id_fkey;

ALTER TABLE slideshow_jobs
    ADD CONSTRAINT slideshow_jobs_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
