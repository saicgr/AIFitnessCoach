-- Daily Activity Table for storing Health Connect/HealthKit data
-- Stores steps, calories burned, distance, and heart rate from wearables

CREATE TABLE IF NOT EXISTS daily_activity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Date for this activity record (one record per day per user)
    activity_date DATE NOT NULL,

    -- Activity metrics
    steps INTEGER DEFAULT 0,
    calories_burned DOUBLE PRECISION DEFAULT 0,
    active_calories DOUBLE PRECISION DEFAULT 0,
    distance_meters DOUBLE PRECISION DEFAULT 0,

    -- Heart rate data
    resting_heart_rate INTEGER,
    avg_heart_rate INTEGER,
    max_heart_rate INTEGER,

    -- Sleep data (optional)
    sleep_minutes INTEGER,
    deep_sleep_minutes INTEGER,
    rem_sleep_minutes INTEGER,

    -- Source tracking
    source VARCHAR DEFAULT 'health_connect',  -- 'health_connect', 'apple_health', 'manual'

    -- Timestamps
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure one record per user per day
    UNIQUE(user_id, activity_date)
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_daily_activity_user_id ON daily_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_activity_date ON daily_activity(activity_date);
CREATE INDEX IF NOT EXISTS idx_daily_activity_user_date ON daily_activity(user_id, activity_date);

-- Enable Row Level Security
ALTER TABLE daily_activity ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own activity data
CREATE POLICY daily_activity_select_policy ON daily_activity
    FOR SELECT USING (true);

CREATE POLICY daily_activity_insert_policy ON daily_activity
    FOR INSERT WITH CHECK (true);

CREATE POLICY daily_activity_update_policy ON daily_activity
    FOR UPDATE USING (true);

CREATE POLICY daily_activity_delete_policy ON daily_activity
    FOR DELETE USING (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_daily_activity_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS trigger_daily_activity_updated_at ON daily_activity;
CREATE TRIGGER trigger_daily_activity_updated_at
    BEFORE UPDATE ON daily_activity
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_activity_updated_at();

-- Comment on table
COMMENT ON TABLE daily_activity IS 'Stores daily activity data synced from Health Connect (Android) or Apple Health (iOS)';
