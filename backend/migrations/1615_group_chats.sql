-- F12: Group chat columns
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS is_group BOOLEAN DEFAULT false;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS group_name TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS group_avatar_url TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE conversation_participants ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'member';
ALTER TABLE conversation_participants ADD COLUMN IF NOT EXISTS left_at TIMESTAMPTZ;
