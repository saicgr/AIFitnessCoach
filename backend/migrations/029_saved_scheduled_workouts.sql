-- Migration: Saved and Scheduled Workouts from Social Feed
-- Created: 2025-12-24
-- Description: Allow users to save, schedule, and do workouts shared by friends

-- ============================================================
-- SAVED WORKOUTS (Favorites from Social Feed)
-- ============================================================

CREATE TABLE IF NOT EXISTS saved_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Who saved it
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Where it came from
    source_activity_id UUID REFERENCES activity_feed(id) ON DELETE SET NULL,
    source_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Workout details (denormalized for persistence even if source deleted)
    workout_name VARCHAR(200) NOT NULL,
    workout_description TEXT,
    exercises JSONB NOT NULL, -- Array of {name, sets, reps, weight_kg, rest_seconds}

    -- Metadata
    total_exercises INT NOT NULL,
    estimated_duration_minutes INT,
    difficulty_level VARCHAR(20), -- 'beginner', 'intermediate', 'advanced'

    -- Organization
    folder VARCHAR(100), -- e.g., 'Favorites', 'Upper Body', 'From Friends'
    tags TEXT[], -- ['strength', 'hypertrophy', 'friend-workout']
    notes TEXT, -- User's personal notes about the workout

    -- Stats
    times_completed INT DEFAULT 0,
    last_completed_at TIMESTAMP WITH TIME ZONE,

    -- Timestamps
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Prevent duplicate saves
    UNIQUE(user_id, source_activity_id)
);

CREATE INDEX idx_saved_workouts_user ON saved_workouts(user_id);
CREATE INDEX idx_saved_workouts_source_activity ON saved_workouts(source_activity_id);
CREATE INDEX idx_saved_workouts_folder ON saved_workouts(folder);
CREATE INDEX idx_saved_workouts_tags ON saved_workouts USING GIN(tags);

COMMENT ON TABLE saved_workouts IS 'Workouts saved/favorited from social feed';

-- ============================================================
-- SCHEDULED WORKOUTS (Future Workout Plans)
-- ============================================================

CREATE TABLE IF NOT EXISTS scheduled_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Who scheduled it
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- What workout
    saved_workout_id UUID REFERENCES saved_workouts(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE CASCADE, -- From user's existing workouts

    -- When (only one should be set)
    scheduled_date DATE NOT NULL,
    scheduled_time TIME, -- Optional specific time

    -- Workout snapshot (in case source deleted)
    workout_name VARCHAR(200) NOT NULL,
    exercises JSONB NOT NULL,

    -- Status
    status VARCHAR(20) DEFAULT 'scheduled', -- 'scheduled', 'completed', 'skipped', 'rescheduled'
    completed_at TIMESTAMP WITH TIME ZONE,

    -- Reminders
    reminder_enabled BOOLEAN DEFAULT true,
    reminder_minutes_before INT DEFAULT 60, -- Notify 1 hour before

    -- Notes
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Business logic constraints
    CHECK (saved_workout_id IS NOT NULL OR workout_id IS NOT NULL)
);

CREATE INDEX idx_scheduled_workouts_user ON scheduled_workouts(user_id);
CREATE INDEX idx_scheduled_workouts_date ON scheduled_workouts(scheduled_date);
CREATE INDEX idx_scheduled_workouts_status ON scheduled_workouts(status);
CREATE INDEX idx_scheduled_workouts_user_date ON scheduled_workouts(user_id, scheduled_date);

COMMENT ON TABLE scheduled_workouts IS 'Workouts scheduled for future dates';

-- ============================================================
-- WORKOUT TEMPLATES (Shared Workout Blueprints)
-- ============================================================

CREATE TABLE IF NOT EXISTS workout_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Who shared it
    shared_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- What workout (from their actual completed workout)
    workout_log_id UUID REFERENCES workout_logs(id) ON DELETE SET NULL,
    activity_id UUID REFERENCES activity_feed(id) ON DELETE SET NULL,

    -- Share metadata
    share_count INT DEFAULT 0, -- How many times saved by others
    completion_count INT DEFAULT 0, -- How many times completed by others
    average_rating DECIMAL(3,2), -- User ratings (0-5)

    -- Visibility
    is_public BOOLEAN DEFAULT false,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(shared_by, workout_log_id)
);

CREATE INDEX idx_workout_shares_user ON workout_shares(shared_by);
CREATE INDEX idx_workout_shares_activity ON workout_shares(activity_id);
CREATE INDEX idx_workout_shares_public ON workout_shares(is_public) WHERE is_public = true;

COMMENT ON TABLE workout_shares IS 'Tracks sharing metrics for workouts';

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Update share count when workout is saved
CREATE OR REPLACE FUNCTION update_workout_share_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.source_activity_id IS NOT NULL THEN
        UPDATE workout_shares
        SET share_count = share_count + 1
        WHERE activity_id = NEW.source_activity_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_share_count
AFTER INSERT ON saved_workouts
FOR EACH ROW EXECUTE FUNCTION update_workout_share_count();

-- Update times_completed when scheduled workout is marked complete
CREATE OR REPLACE FUNCTION update_saved_workout_completion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        IF NEW.saved_workout_id IS NOT NULL THEN
            UPDATE saved_workouts
            SET
                times_completed = times_completed + 1,
                last_completed_at = NOW()
            WHERE id = NEW.saved_workout_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_saved_workout_completion
AFTER UPDATE ON scheduled_workouts
FOR EACH ROW EXECUTE FUNCTION update_saved_workout_completion();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE saved_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_shares ENABLE ROW LEVEL SECURITY;

-- Saved Workouts policies
CREATE POLICY "Users can view their own saved workouts"
    ON saved_workouts FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can save workouts"
    ON saved_workouts FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their saved workouts"
    ON saved_workouts FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete their saved workouts"
    ON saved_workouts FOR DELETE
    USING (user_id = auth.uid());

-- Scheduled Workouts policies
CREATE POLICY "Users can view their scheduled workouts"
    ON scheduled_workouts FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can schedule workouts"
    ON scheduled_workouts FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their scheduled workouts"
    ON scheduled_workouts FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete their scheduled workouts"
    ON scheduled_workouts FOR DELETE
    USING (user_id = auth.uid());

-- Workout Shares policies
CREATE POLICY "Anyone can view public workout shares"
    ON workout_shares FOR SELECT
    USING (is_public = true OR shared_by = auth.uid());

CREATE POLICY "Users can create their own shares"
    ON workout_shares FOR INSERT
    WITH CHECK (shared_by = auth.uid());

CREATE POLICY "Users can update their own shares"
    ON workout_shares FOR UPDATE
    USING (shared_by = auth.uid());

-- ============================================================
-- HELPER VIEWS
-- ============================================================

-- View: Saved Workouts with Source User Info
CREATE OR REPLACE VIEW saved_workouts_with_source AS
SELECT
    sw.*,
    u.name AS source_user_name,
    u.avatar_url AS source_user_avatar
FROM saved_workouts sw
LEFT JOIN users u ON u.id = sw.source_user_id;

-- View: Upcoming Scheduled Workouts
CREATE OR REPLACE VIEW upcoming_scheduled_workouts AS
SELECT *
FROM scheduled_workouts
WHERE status = 'scheduled'
    AND scheduled_date >= CURRENT_DATE
ORDER BY scheduled_date ASC, scheduled_time ASC NULLS LAST;

-- View: Popular Shared Workouts
CREATE OR REPLACE VIEW popular_shared_workouts AS
SELECT
    ws.*,
    af.activity_data,
    u.name AS creator_name,
    u.avatar_url AS creator_avatar
FROM workout_shares ws
JOIN activity_feed af ON af.id = ws.activity_id
JOIN users u ON u.id = ws.shared_by
WHERE ws.is_public = true
    AND ws.share_count > 0
ORDER BY ws.share_count DESC, ws.completion_count DESC;
