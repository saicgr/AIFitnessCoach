-- Migration: Atomic SCD2 Versioning via DB Triggers
-- Purpose: Prevent orphaned workouts (is_current=FALSE with no replacement)
--
-- Two triggers:
--   1. BEFORE INSERT: Auto-supersede existing current workout for same date
--   2. BEFORE UPDATE: Refuse to mark workout as not-current if no replacement exists
--
-- This makes SCD2 versioning atomic at the DB level, eliminating race conditions
-- and error-interrupted flows that previously left workouts invisible.

-- ============================================================================
-- TRIGGER 1: ensure_single_current_workout (BEFORE INSERT)
-- ============================================================================
-- When a new real workout (not a placeholder) is inserted with is_current=TRUE,
-- automatically mark any existing current workout for the same
-- (user_id, scheduled_date, gym_profile_id) as superseded.

CREATE OR REPLACE FUNCTION ensure_single_current_workout()
RETURNS TRIGGER AS $$
BEGIN
    -- Only act on current workouts (skip placeholders with status='generating')
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

    -- Safety: ensure is_current defaults to TRUE for real workouts
    IF NEW.is_current IS NULL THEN
        NEW.is_current := TRUE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_ensure_single_current_workout ON workouts;
CREATE TRIGGER trg_ensure_single_current_workout
    BEFORE INSERT ON workouts
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_current_workout();


-- ============================================================================
-- TRIGGER 2: prevent_orphaned_workouts (BEFORE UPDATE)
-- ============================================================================
-- When a workout is being marked is_current=FALSE, verify that at least one
-- other current version exists for that date. If not, refuse the change
-- (self-heal by keeping it as current).

CREATE OR REPLACE FUNCTION prevent_orphaned_workouts()
RETURNS TRIGGER AS $$
BEGIN
    -- Only act when is_current is changing from TRUE to FALSE
    IF OLD.is_current = TRUE AND NEW.is_current = FALSE THEN
        -- Check if any other current workout exists for this date
        IF NOT EXISTS (
            SELECT 1 FROM workouts
            WHERE user_id = NEW.user_id
              AND scheduled_date::date = NEW.scheduled_date::date
              AND is_current = TRUE
              AND id != NEW.id
              AND COALESCE(status, 'scheduled') != 'generating'
        ) THEN
            -- No replacement exists — refuse to orphan this workout
            NEW.is_current := TRUE;
            NEW.valid_to := NULL;
            NEW.superseded_by := NULL;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_orphaned_workouts ON workouts;
CREATE TRIGGER trg_prevent_orphaned_workouts
    BEFORE UPDATE ON workouts
    FOR EACH ROW
    EXECUTE FUNCTION prevent_orphaned_workouts();


-- ============================================================================
-- ONE-TIME FIX: Re-mark orphaned workouts as current
-- ============================================================================
-- An orphaned workout is is_current=FALSE with no is_current=TRUE sibling
-- for the same (user_id, scheduled_date).

UPDATE workouts w
SET is_current = TRUE, valid_to = NULL, superseded_by = NULL
WHERE w.is_current = FALSE
  AND COALESCE(w.status, 'scheduled') != 'cancelled'
  AND NOT EXISTS (
      SELECT 1 FROM workouts w2
      WHERE w2.user_id = w.user_id
        AND w2.scheduled_date::date = w.scheduled_date::date
        AND w2.is_current = TRUE
        AND w2.id != w.id
  );
