#!/usr/bin/env python3
"""Fix migration 1881: Split BEFORE INSERT trigger into BEFORE + AFTER.

The original trigger set `superseded_by = NEW.id` inside a BEFORE INSERT trigger.
This violates the FK constraint because NEW.id doesn't exist in the table yet.

Fix: Move the auto-supersede UPDATE to an AFTER INSERT trigger (where the new
row already exists), and keep only the is_current default in BEFORE INSERT.
"""
import os
import sys
import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")

SQL = """
-- Step 1: Create a minimal BEFORE INSERT trigger for the is_current default
CREATE OR REPLACE FUNCTION default_workout_is_current()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_current IS NULL THEN
        NEW.is_current := TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Drop the old combined BEFORE INSERT trigger
DROP TRIGGER IF EXISTS trg_ensure_single_current_workout ON workouts;

-- Step 3: Create the new BEFORE INSERT trigger (is_current default only)
DROP TRIGGER IF EXISTS trg_default_workout_is_current ON workouts;
CREATE TRIGGER trg_default_workout_is_current
    BEFORE INSERT ON workouts
    FOR EACH ROW
    EXECUTE FUNCTION default_workout_is_current();

-- Step 4: Redefine the function to return NULL (required for AFTER triggers)
CREATE OR REPLACE FUNCTION ensure_single_current_workout()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_current = TRUE AND COALESCE(NEW.status, 'scheduled') != 'generating' THEN
        UPDATE workouts
        SET is_current = FALSE,
            valid_to = NOW(),
            superseded_by = NEW.id
        WHERE user_id = NEW.user_id
          AND scheduled_date::date = NEW.scheduled_date::date
          AND is_current = TRUE
          AND id != NEW.id
          AND COALESCE(status, 'scheduled') != 'generating'
          AND (
              NEW.gym_profile_id IS NULL
              OR gym_profile_id IS NULL
              OR gym_profile_id = NEW.gym_profile_id
          );
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Create the AFTER INSERT trigger for auto-supersede
DROP TRIGGER IF EXISTS trg_ensure_single_current_after ON workouts;
CREATE TRIGGER trg_ensure_single_current_after
    AFTER INSERT ON workouts
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_current_workout();
"""

def main():
    print("Connecting to database...")
    conn = psycopg2.connect(
        host=DATABASE_HOST,
        port=DATABASE_PORT,
        dbname=DATABASE_NAME,
        user=DATABASE_USER,
        password=DATABASE_PASSWORD,
    )
    conn.autocommit = False
    cur = conn.cursor()

    try:
        print("Applying trigger fix...")
        cur.execute(SQL)
        conn.commit()
        print("Migration applied successfully.")

        # Verify
        cur.execute("""
            SELECT trigger_name, action_timing, event_manipulation
            FROM information_schema.triggers
            WHERE event_object_table = 'workouts'
              AND trigger_name IN (
                  'trg_default_workout_is_current',
                  'trg_ensure_single_current_after',
                  'trg_ensure_single_current_workout'
              )
            ORDER BY trigger_name;
        """)
        rows = cur.fetchall()
        print(f"\nTrigger verification ({len(rows)} triggers):")
        for name, timing, event in rows:
            print(f"  {name}: {timing} {event}")

        # Ensure old trigger is gone
        old_exists = any(r[0] == 'trg_ensure_single_current_workout' for r in rows)
        if old_exists:
            print("\nWARNING: Old trigger still exists!")
        else:
            print("\nOld BEFORE INSERT trigger removed successfully.")

    except Exception as e:
        conn.rollback()
        print(f"ERROR: {e}")
        sys.exit(1)
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
