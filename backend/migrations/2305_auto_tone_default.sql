-- ============================================================================
-- 2305: Coach tone defaults to "auto" (adaptive, gentle-first)
-- ============================================================================
-- The adaptive-tone bandit (_select_tone_for_user) only engages when
-- accountability_intensity == 'auto', but migration 1873 seeded 'balanced',
-- so no user ever got adaptive tone. The engine has never fired in production
-- (push_nudge_log was empty until the 2026-07 engagement-cron wiring), so the
-- seeded value was never a lived-in user choice — flip seeded 'balanced' to
-- 'auto'. Users who later pick an explicit tone in Settings keep it.

UPDATE users
SET notification_preferences = notification_preferences || '{"accountability_intensity": "auto"}'::jsonb
WHERE notification_preferences IS NOT NULL
  AND notification_preferences->>'accountability_intensity' = 'balanced';
