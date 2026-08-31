-- 2437: gate the four paid surfaces server-side.
--
-- WHY: the app shipped as "single-tier paid" but only SIX features were ever
-- enforced on the server (ai_chat_messages, ai_chat, ai_workout_generation,
-- food_scanning, form_video_analysis, text_to_calories). Everything else —
-- the curated program library, AI body analysis, the audio daily brief, the
-- in-app data export — had NO backend entitlement check, so any user who
-- tapped "Maybe later" on the paywall kept them permanently. That is
-- freemium-by-omission, not a product decision.
--
-- free_limit 0 + minimum_tier 'premium' == paid-only, never metered: the tier
-- check in core/premium_gate.check_premium_gate() raises 402 before usage is
-- counted. reset_period is therefore inert BUT must still be a valid value —
-- a NULL is what once turned a daily cap into a lifetime one (see 2330/2380).
--
-- Deliberately NOT gated here (and must stay ungated):
--   * manual workout / food logging — never lock a user out of data they
--     already recorded.
--   * browsing programs + exercises — the free evaluation surface.
--   * health sync + basic stats — cheap, and the retention hook.
--   * GDPR DSAR export (api/v1/dsar.py) — statutory right, cannot be paywalled.
--     `data_export` below is the SEPARATE in-app convenience export from
--     Settings -> Data & Privacy, which the Flutter client has always rendered
--     behind `isSubscribed`; this makes the server agree with the UI.
--
-- Mirrors core/premium_gate._get_fallback_gate() so an unseeded table and a
-- seeded one behave identically.

INSERT INTO feature_gates (feature_key, display_name, minimum_tier, free_limit, reset_period, is_enabled)
VALUES
  ('program_start',  'Start a Curated Program', 'premium', 0, 'daily', true),
  ('body_analysis',  'AI Body Analysis',        'premium', 0, 'daily', true),
  ('audio_coach',    'Audio Daily Brief',       'premium', 0, 'daily', true),
  ('data_export',    'Export My Data',          'premium', 0, 'daily', true)
ON CONFLICT (feature_key) DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  minimum_tier  = EXCLUDED.minimum_tier,
  free_limit    = EXCLUDED.free_limit,
  reset_period  = EXCLUDED.reset_period,
  is_enabled    = EXCLUDED.is_enabled;

-- ---------------------------------------------------------------------------
-- Part 2: realign the METERED free limits with the documented policy.
--
-- Applying part 1 surfaced that the live feature_gates rows had drifted far
-- looser than core/premium_gate._get_fallback_gate(), which is supposed to
-- mirror them:
--
--   feature                 live DB (before)   fallback constant   effect
--   ai_workout_generation   100 / monthly      2 / monthly         ~unlimited
--   food_scanning           100 / monthly      1 / daily           ~unlimited
--   text_to_calories        100 / monthly      3 / daily           ~unlimited
--
-- The DB row WINS over the constant (the constant is only a fallback for a
-- missing row), so the advertised free caps were never the enforced ones — a
-- free user got ~100 AI workout generations and ~100 food scans per month.
-- That is not a metered tier, it is an unmetered one with a large number
-- written next to it. Realigned so the DB and the code agree.

UPDATE feature_gates SET free_limit = 2, reset_period = 'monthly' WHERE feature_key = 'ai_workout_generation';
UPDATE feature_gates SET free_limit = 1, reset_period = 'daily'   WHERE feature_key = 'food_scanning';
UPDATE feature_gates SET free_limit = 3, reset_period = 'daily'   WHERE feature_key = 'text_to_calories';
