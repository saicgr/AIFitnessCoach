-- Migration 266: Fitness Wrapped (monthly recap cards)
-- Stores aggregated monthly stats and AI-generated personality data

CREATE TABLE IF NOT EXISTS fitness_wrapped (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  period_type TEXT NOT NULL DEFAULT 'monthly',
  period_key TEXT NOT NULL,
  stats JSONB NOT NULL,
  ai_personality JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, period_type, period_key)
);

ALTER TABLE fitness_wrapped ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own wrapped" ON fitness_wrapped
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service insert wrapped" ON fitness_wrapped
  FOR INSERT WITH CHECK (auth.uid() = user_id);
