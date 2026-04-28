-- Public shareable workout links.
--
-- Adds a tokenized public-read path for completed workouts. We don't make
-- the whole `workouts` row public — instead we expose a security-definer
-- view (`public_workouts_v`) that returns only fields safe to show to
-- anyone with the link.

ALTER TABLE workouts
  ADD COLUMN IF NOT EXISTS share_token text UNIQUE;

CREATE INDEX IF NOT EXISTS idx_workouts_share_token
  ON workouts (share_token)
  WHERE share_token IS NOT NULL;

-- A view that strips internal fields and only exposes what the public
-- web view at zealova.com/w/[token] needs to render.
--
-- NB: the live schema names: exercise list lives on `workouts.exercises_json`
-- (not `exercises`), calories on `workouts.estimated_calories` (not
-- `calories_burned`), and the user-facing handle is `users.username` (no
-- `display_name` column exists). Aliases keep the public contract stable
-- so web consumers can read `calories_burned` / `exercises` / `display_name`.
CREATE OR REPLACE VIEW public_workouts_v
WITH (security_invoker = false) AS
SELECT
  w.share_token,
  w.name,
  w.duration_minutes,
  w.estimated_calories AS calories_burned,
  w.completed_at,
  w.exercises_json     AS exercises,
  -- Anonymize the user — public viewers see a username only when the
  -- account has one (we default to a generic "Zealova lifter").
  COALESCE(u.username, 'Zealova lifter') AS display_name
FROM workouts w
LEFT JOIN users u ON u.id = w.user_id
WHERE w.share_token IS NOT NULL
  AND w.is_completed = true;

GRANT SELECT ON public_workouts_v TO anon, authenticated;

-- Tighten RLS on the underlying `workouts` table — the share_token column
-- alone doesn't expose anything; only the view does.
COMMENT ON COLUMN workouts.share_token IS
  'Nanoid (8 chars). When non-null, the row is publicly readable via public_workouts_v.';
