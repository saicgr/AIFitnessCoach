-- user_encryption_keys: stores X25519 public keys
CREATE TABLE user_encryption_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  public_key TEXT NOT NULL,
  algorithm TEXT NOT NULL DEFAULT 'x25519',
  key_version INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT now(),
  revoked_at TIMESTAMPTZ,
  UNIQUE(user_id, key_version)
);

-- RLS
ALTER TABLE user_encryption_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view any public key"
  ON user_encryption_keys FOR SELECT USING (true);

CREATE POLICY "Users can insert own keys"
  ON user_encryption_keys FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role full access"
  ON user_encryption_keys FOR ALL USING (auth.role() = 'service_role');

-- Add encryption fields to direct_messages
ALTER TABLE direct_messages
  ADD COLUMN IF NOT EXISTS encrypted_content TEXT,
  ADD COLUMN IF NOT EXISTS encryption_nonce TEXT,
  ADD COLUMN IF NOT EXISTS encryption_version INT DEFAULT 0;

-- Allow content to be NULL for encrypted messages
ALTER TABLE direct_messages ALTER COLUMN content DROP NOT NULL;
