-- Migration: 225_daily_schedule.sql
-- Description: Create schedule_items table for the Daily Schedule Planner feature
-- Created: 2026-02-08

-- ============================================================================
-- SCHEDULE ITEMS TABLE
-- ============================================================================
-- Stores user schedule items: workouts, activities, meals, fasting windows, habits.
-- Used by the Schedule screen's timeline, agenda, and week views.

CREATE TABLE IF NOT EXISTS schedule_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Item details
    title TEXT NOT NULL,
    item_type TEXT NOT NULL DEFAULT 'activity'
        CHECK (item_type IN ('workout', 'activity', 'meal', 'fasting', 'habit')),
    scheduled_date DATE NOT NULL,
    start_time TEXT NOT NULL,           -- "HH:MM" format
    end_time TEXT,                      -- "HH:MM" format
    duration_minutes INTEGER,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'in_progress', 'completed', 'skipped', 'missed')),

    -- Linked entities (optional foreign keys)
    workout_id UUID,
    habit_id UUID,
    fasting_record_id UUID,

    -- Activity-specific fields
    activity_type TEXT,
    activity_target TEXT,
    activity_icon TEXT,
    activity_color TEXT,

    -- Meal-specific fields
    meal_type TEXT CHECK (meal_type IS NULL OR meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),

    -- Recurrence
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_rule TEXT,               -- RRULE string

    -- Notifications
    notify_before_minutes INTEGER DEFAULT 15,

    -- Google Calendar integration
    sync_to_google_calendar BOOLEAN DEFAULT FALSE,
    google_calendar_event_id TEXT,
    google_calendar_synced_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Primary lookup: daily schedule for a user
CREATE INDEX IF NOT EXISTS idx_schedule_items_user_date
    ON schedule_items(user_id, scheduled_date);

-- Up-next query: upcoming items by status
CREATE INDEX IF NOT EXISTS idx_schedule_items_user_status
    ON schedule_items(user_id, status);

-- Time-based ordering within a day
CREATE INDEX IF NOT EXISTS idx_schedule_items_date_time
    ON schedule_items(scheduled_date, start_time);

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_schedule_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trigger_schedule_items_updated_at ON schedule_items;
CREATE TRIGGER trigger_schedule_items_updated_at
    BEFORE UPDATE ON schedule_items
    FOR EACH ROW
    EXECUTE FUNCTION update_schedule_items_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE schedule_items ENABLE ROW LEVEL SECURITY;

-- Users can SELECT their own rows (+ server-side / service_role access)
CREATE POLICY "schedule_items_select_own"
    ON schedule_items FOR SELECT
    USING (
        auth.uid() = user_id
        OR (SELECT auth.uid()) IS NULL
        OR (SELECT auth.role()) = 'service_role'
    );

-- Users can INSERT their own rows (+ server-side / service_role access)
CREATE POLICY "schedule_items_insert_own"
    ON schedule_items FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        OR (SELECT auth.uid()) IS NULL
        OR (SELECT auth.role()) = 'service_role'
    );

-- Users can UPDATE their own rows (+ server-side / service_role access)
CREATE POLICY "schedule_items_update_own"
    ON schedule_items FOR UPDATE
    USING (
        auth.uid() = user_id
        OR (SELECT auth.uid()) IS NULL
        OR (SELECT auth.role()) = 'service_role'
    );

-- Users can DELETE their own rows (+ server-side / service_role access)
CREATE POLICY "schedule_items_delete_own"
    ON schedule_items FOR DELETE
    USING (
        auth.uid() = user_id
        OR (SELECT auth.uid()) IS NULL
        OR (SELECT auth.role()) = 'service_role'
    );
