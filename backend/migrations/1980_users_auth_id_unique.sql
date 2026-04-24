-- Migration: Add UNIQUE constraint on users.auth_id
--
-- Context: In April 2026 production logs showed two different `users` rows
-- created for the same Supabase auth_id within a 2-minute window. The
-- /auth/google endpoint used to do a SELECT-then-INSERT without any
-- synchronization, so two concurrent requests could both observe "no
-- existing user" and both insert. The app-level fix (auth.py now catches
-- unique-violation and returns the existing row) requires this DB-level
-- guarantee to work. Without the constraint, the race window stays open.
--
-- Safety: verified there are zero duplicate auth_ids in production at
-- application time (see 2026-04-24 audit); the CREATE UNIQUE below will
-- succeed cleanly with no pre-dedupe step. If future environments do
-- hold duplicates, this migration will fail — run a reconcile script
-- keyed on FK cascades before retrying.
--
-- Existing infra preserved: the non-unique index idx_users_auth_id
-- (migration 001) is left in place. Postgres creates a backing index
-- for the UNIQUE constraint automatically; the older index is harmless
-- and keeps any EXPLAIN plans that name it working.

ALTER TABLE public.users
  ADD CONSTRAINT users_auth_id_unique UNIQUE (auth_id);
