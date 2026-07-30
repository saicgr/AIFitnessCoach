-- Migration 2347: close the CONCURRENT hole in the one-active-gym-per-user invariant.
--
-- E2E register row #59 (2026-07-28), Sentry PYTHON-FASTAPI-6V:
--   duplicate key value violates unique constraint "idx_gym_profiles_active_per_user"
--
-- Migration 2327 added trg_gym_profiles_single_active, a BEFORE INSERT/UPDATE trigger
-- that demotes the user's other live profiles before the row lands. That cures the
-- SEQUENTIAL race. It does NOT cure the CONCURRENT one, which is the one production
-- actually hit: the app fires create_gym_profiles_from_onboarding() (name derived from
-- the REQUEST body) and create_default_profile_if_needed() (name derived from
-- users.preferences, which the same request may not have written yet) at the same
-- moment, so the two creators can pick DIFFERENT names — "Home Gym" vs
-- "Commercial Gym" — and each activates its own row.
--
-- Under READ COMMITTED, T2's BEFORE trigger cannot see T1's uncommitted row, so its
-- demotion UPDATE is a no-op, T2 inserts a second is_active=true row, blocks on the
-- partial unique index, and 23505s the instant T1 commits. The app's ON CONFLICT
-- arbiter is (user_id, name) — a DIFFERENT index — so the upsert cannot absorb it.
--
-- Reproduced against production DDL on 2026-07-29 with two connections releasing off a
-- barrier: "different names, both active" -> UniqueViolation on
-- idx_gym_profiles_active_per_user, verbatim the Render-log string.
--
-- THE FIX, at the same chokepoint 2327 chose: take a transaction-scoped advisory lock
-- keyed on the user before the demotion runs. Concurrent activations for one user now
-- serialize; T2 waits for T1 to commit, and because READ COMMITTED takes a fresh
-- snapshot per statement, T2's demotion UPDATE then SEES T1's committed row and demotes
-- it. The unique index sees exactly one candidate in every interleaving.
--
-- Why an advisory lock and not a retry loop in Python: the invariant has to hold for
-- EVERY writer (onboarding, the self-heal path, the gym switcher, community-gym import,
-- travel mode, future ones), and a per-caller retry is a guard, not a cure. The lock is
-- per-user, held for the remainder of an already-short transaction, and every writer
-- takes the same single lock in the same order, so it cannot deadlock.

CREATE OR REPLACE FUNCTION gym_profiles_enforce_single_active()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- An archived gym can never be the active one (idx_gym_profiles_active_per_user
    -- already excludes it; this stops a writer from parking is_active=true on a row
    -- that is invisible to every picker).
    IF NEW.archived_at IS NOT NULL THEN
        NEW.is_active := false;
        RETURN NEW;
    END IF;

    -- A row that is ALREADY the active one and is staying active cannot violate the
    -- invariant, so there is nothing to demote. Returning before the advisory lock is
    -- what keeps the lock ordering acyclic, and it is the hot path: every ordinary edit
    -- to the active profile (rename, equipment import, program assignment, location)
    -- satisfies the trigger's WHEN clause and used to run a pointless demotion sweep.
    --
    -- Why it must come BEFORE the lock: for an UPDATE, Postgres's GetTupleForTrigger
    -- takes an exclusive tuple lock on the target row *before* firing BEFORE ROW
    -- triggers. So an updater already holds its own row lock when it reaches the
    -- advisory lock. If that row is the user's current active profile, another
    -- transaction holding the advisory lock will block on it inside the demotion sweep
    -- while we block on the advisory lock — a deadlock, observed in a 4-way switcher
    -- race. Skipping the no-op case removes the only interleaving that can form the
    -- cycle: a transaction that reaches the advisory lock is always activating a row
    -- whose COMMITTED is_active is false, which no other transaction's demotion sweep
    -- (WHERE is_active = true) will ever try to lock.
    IF TG_OP = 'UPDATE' AND OLD.is_active IS TRUE AND OLD.archived_at IS NULL THEN
        RETURN NEW;
    END IF;

    -- Serialize concurrent activations for THIS user. Without it the demotion below
    -- runs against a snapshot that predates a racing creator's row and silently does
    -- nothing, and the partial unique index raises 23505 at commit time.
    -- 1_953_244_001 is an arbitrary fixed namespace for the gym-profile lock class,
    -- so this cannot collide with an advisory lock taken anywhere else.
    PERFORM pg_advisory_xact_lock(1953244001, hashtext(NEW.user_id::text));

    -- Activating this profile demotes the user's other live profiles first, so the
    -- partial unique index sees exactly one candidate row.
    --
    -- `name IS DISTINCT FROM NEW.name` is load-bearing, not an optimisation. Every
    -- app writer inserts with ON CONFLICT (user_id, name) DO UPDATE. Now that the
    -- advisory lock makes the trigger see a racing creator's COMMITTED row, a
    -- same-name retry would have the trigger demote the very row the ON CONFLICT is
    -- about to update — and Postgres rejects that with
    -- "ON CONFLICT DO UPDATE command cannot affect row a second time" (21000).
    -- Skipping it is safe: gym_profiles_user_name_unique is UNIQUE(user_id, name)
    -- over ALL rows, so at most one row can match, and that row is precisely the one
    -- this statement is about to (re)activate. Exactly one active row either way.
    UPDATE gym_profiles
       SET is_active = false,
           updated_at = NOW()
     WHERE user_id = NEW.user_id
       AND is_active = true
       AND archived_at IS NULL
       AND id IS DISTINCT FROM NEW.id
       AND name IS DISTINCT FROM NEW.name;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION gym_profiles_enforce_single_active() IS
    'Chokepoint for the one-active-gym-per-user invariant. Takes a per-user advisory '
    'xact lock so concurrent activations serialize, then demotes the user''s other live '
    'profiles in the same statement, so idx_gym_profiles_active_per_user can never be '
    'violated by an app write — sequentially (mig 2327) or concurrently (mig 2347). '
    'Archived rows are forced inactive.';

-- Trigger definition is unchanged from 2327 (BEFORE INSERT OR UPDATE, WHEN NEW.is_active
-- IS TRUE); replacing the function is enough. The demotion UPDATE writes is_active=false,
-- which does not satisfy the WHEN clause, so there is still no recursion.
