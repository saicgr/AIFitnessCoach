-- 2063_optin_data_api_grants.sql
-- Opt in early to Supabase's Oct 30, 2026 Data API default change:
-- new tables in `public` will NOT be auto-exposed to PostgREST. Every
-- new table must add explicit GRANTs (see backend/migrations/README.md
-- "New `public` table template" section).
--
-- Effect:
--   - From now on, `CREATE TABLE public.X` produces a table that anon
--     and authenticated CANNOT read/write via the Data API until the
--     migration adds explicit GRANTs.
--   - Existing tables are unaffected — DEFAULT PRIVILEGES only apply
--     to objects created AFTER this statement.
--   - service_role still bypasses everything (it has BYPASSRLS and
--     superuser-equivalent grants), so the backend keeps working.
--
-- If a future table is created without GRANTs, PostgREST returns a
-- 42501 with the exact GRANT line to add — easy to catch in dev.
--
-- To revert (not recommended): the inverse GRANT in DEFAULT PRIVILEGES.

BEGIN;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE ALL ON TABLES FROM anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE ALL ON SEQUENCES FROM anon, authenticated;

COMMIT;
