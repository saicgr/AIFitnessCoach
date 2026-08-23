-- Migration: 2412_fix_share_rate_counters_user_id_fk.sql
-- Description: share_rate_counters.user_id (migration 2107) was created
--              REFERENCES auth.users(id) instead of users(id). Every write
--              path (api/v1/share.py _check_and_increment_cap, called from
--              share_orchestrator.py for url/audio/pdf imports and share.py
--              for image/text imports) inserts current_user["id"] — the
--              backend `public.users.id` — never the Supabase auth id. Any
--              user whose public.users.id differs from their auth.users.id
--              (the normal case; they are independently generated UUIDs, see
--              core/auth.py) therefore violates share_rate_counters_user_id_fkey
--              on the very first share/import of the day, 500ing before the
--              AI pipeline (Gemini) ever runs. Same identity-split family as
--              2402 (slideshow_jobs) and rows 50/262 (paste-import 500).
-- Created: 2026-08-23

ALTER TABLE share_rate_counters DROP CONSTRAINT IF EXISTS share_rate_counters_user_id_fkey;

ALTER TABLE share_rate_counters
    ADD CONSTRAINT share_rate_counters_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
