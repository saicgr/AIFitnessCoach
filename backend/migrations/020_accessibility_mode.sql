-- Migration 020: Add accessibility mode support
-- Adds accessibility_mode column to users table for Senior/Normal mode selection

-- Add accessibility_mode column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS accessibility_mode VARCHAR(20) DEFAULT 'normal';

-- Add accessibility_settings JSONB column for detailed settings
ALTER TABLE users ADD COLUMN IF NOT EXISTS accessibility_settings JSONB DEFAULT '{}';

-- Add comment for documentation
COMMENT ON COLUMN users.accessibility_mode IS 'Accessibility mode: normal, senior, kids';
COMMENT ON COLUMN users.accessibility_settings IS 'Detailed accessibility settings (font_scale, high_contrast, etc.)';

-- Create index for querying by mode (useful for analytics)
CREATE INDEX IF NOT EXISTS idx_users_accessibility_mode ON users(accessibility_mode);

-- Analytics: Track accessibility mode changes
CREATE TABLE IF NOT EXISTS accessibility_mode_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    old_mode VARCHAR(20),
    new_mode VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    change_source VARCHAR(50) DEFAULT 'app',
    device_platform VARCHAR(50)
);

-- Index for user lookup
CREATE INDEX IF NOT EXISTS idx_accessibility_analytics_user ON accessibility_mode_analytics(user_id);

-- RLS for accessibility analytics
ALTER TABLE accessibility_mode_analytics ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own analytics
CREATE POLICY "Users can view their own accessibility analytics"
ON accessibility_mode_analytics
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own analytics
CREATE POLICY "Users can insert their own accessibility analytics"
ON accessibility_mode_analytics
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- View: Accessibility mode distribution (for admin analytics)
CREATE OR REPLACE VIEW accessibility_mode_distribution AS
SELECT
    accessibility_mode,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 2) as percentage
FROM users
WHERE accessibility_mode IS NOT NULL
GROUP BY accessibility_mode
ORDER BY user_count DESC;

-- Grant access to the view
GRANT SELECT ON accessibility_mode_distribution TO authenticated;
