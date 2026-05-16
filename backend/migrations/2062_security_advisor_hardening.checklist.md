# Supabase Security Advisor — Manual Action Checklist

Companion to migration `2062_security_advisor_hardening.sql` (applied 2026-05-13).

## Done by migration 2062

- Revoked EXECUTE on 254 SECURITY DEFINER `public` functions from `anon` + PUBLIC. `authenticated` and `service_role` retain access via explicit grants. Closes `anon_security_definer_function_executable` (254 rows).
- Pinned `search_path = public, pg_temp` on 14 plpgsql functions. Closes `function_search_path_mutable` (14 rows).
- Revoked SELECT on `exercise_safety_index_mat` and `exercise_library_cleaned` from `anon`, `authenticated`. Closes `materialized_view_in_api` (2 rows). Backend reads these via `service_role` (unchanged) and clients should hit RPCs that wrap them.

## Still open — needs manual action

### 1. Enable leaked-password protection (Auth dashboard)
- Dashboard → Authentication → Policies → Password Security
- Turn on **"Check passwords against HaveIBeenPwned"**
- Closes `auth_leaked_password_protection`.

### 2. Move `unaccent` extension out of `public` (deferred)
- Cannot do safely in a single ALTER — `unaccent` is used inside generated columns / indexes / RPCs (food normalization path). Moving requires:
  1. Audit every callsite: `grep -r unaccent backend/migrations` and check `public.normalize_food_name_sql`, `public.lemmatize_food_word`, any GIN indexes using `unaccent(...)`.
  2. Create new schema `extensions` (if not present) and `CREATE EXTENSION unaccent SCHEMA extensions`.
  3. Update every callsite to `extensions.unaccent(...)`, rebuild dependent indexes.
- Tracking only; defer until we touch food-search again.

### 3. Public Data API table-exposure default — **opted in early**
- Applied via `2063_optin_data_api_grants.sql` on 2026-05-13.
- New tables in `public` no longer auto-grant to `anon`/`authenticated`. Every new client-facing table must use the GRANT + RLS template in `backend/migrations/README.md` ("New `public` table template" section). Service-role-only tables can skip GRANTs entirely.
- Existing tables unaffected (verified by querying `has_table_privilege` against `public.users` post-migration).

## Intentionally left as-is

- **`rls_policy_always_true` on `public.waitlist` INSERT (anon + auth)** — public signup form, by design. Mitigation already in place is upstream rate limiting; if abuse appears, add a `check (length(email) < 320 and email ~ '...@')` or a per-IP rate limit table.
- **`rls_enabled_no_policy` (INFO) on 9 tables** — `chat_pending_proposals`, `exercise_image_aliases`, `exercise_library_name_backup_2026_05_09`, `lifetime_founder_seats`, `lifetime_waitlist`, `program_exercise_name_map`, `web_lifetime_purchases`, `x_oauth_state`, `x_pending_drafts`. RLS-on + zero policies = deny-all to `anon`/`authenticated`; only `service_role` (which bypasses RLS) can touch them. That's the intended posture for service-only / backup / internal-join tables. Adding explicit deny policies would be no-op noise.
- **`authenticated_security_definer_function_executable`** — these are the RPCs the mobile app calls. They run as `postgres` (definer) but their bodies key off `auth.uid()` / `p_user_id` checks; that's the whole point of SECURITY DEFINER here. Revoking would break the app.
