-- Migration 239: Add device info columns to users table
-- Stores persistent device information for analytics and backend response tailoring

-- Device model (e.g., "Pixel 9 Pro Fold", "iPhone 16 Pro")
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_model VARCHAR(100) DEFAULT NULL;

-- device_platform already exists (added for push notifications)
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS device_platform VARCHAR(20) DEFAULT NULL;

-- Foldable device flag
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_foldable BOOLEAN DEFAULT FALSE;

-- OS version (e.g., "15", "18.2")
ALTER TABLE users ADD COLUMN IF NOT EXISTS os_version VARCHAR(20) DEFAULT NULL;

-- Screen dimensions (physical pixels)
ALTER TABLE users ADD COLUMN IF NOT EXISTS screen_width INT DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS screen_height INT DEFAULT NULL;

-- Timestamp of last device info update
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_device_update TIMESTAMPTZ DEFAULT NULL;

-- Indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_users_is_foldable ON users (is_foldable) WHERE is_foldable = TRUE;
CREATE INDEX IF NOT EXISTS idx_users_device_platform ON users (device_platform) WHERE device_platform IS NOT NULL;
