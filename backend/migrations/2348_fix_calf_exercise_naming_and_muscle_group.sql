-- Migration 2348: fix the "Calve" misspelling and the wrong muscle group on the
-- calf-exercise family.
--
-- E2E register row #64: the app lists an exercise called "Calve Stretch From Wall To
-- Floor" ("Calve" is not a word — the singular of calves is "calf") and labels it
-- "Full Body (Multiple Muscle Groups)", which is what the schedule/detail subtitle
-- renders, for a movement that stretches exactly one muscle group.
--
-- WHOLE CLASS, not one row. Two independent defects, each with siblings:
--
--   (1) MISSPELLING — 7 exercise_library rows carry "Calve": the two Calve Stretch
--       pairs (base + _Female), the Cable Calve Raise pair, and
--       "barbell seated on knee calve raises".
--
--   (2) PLACEHOLDER MUSCLE GROUP — a bulk import stamped
--       target_muscle = 'Full Body (Multiple Muscle Groups)' /
--       secondary_muscles = {'Core (Rectus Abdominis)'} on rows it could not classify.
--       Catalog-wide that is 67 rows; of the 10 in category='stretching', EIGHT are
--       the calf family (Calve Stretch Foot on Wall ±_Female, Calve Stretch From Wall
--       to Floor ±_Female, Calves Stretch on Step ±_Female, Foam Roller Calves
--       ±_Female). A ninth, "Cable Calve Raise_Female", diverged from its own base
--       twin and claims 'Quadriceps … Glutes …' for a calf raise.
--       The remaining rows (cardio/yoga/Bulgarian Split Squat Stretch) are NOT calf
--       movements and are deliberately left for a separate content pass rather than
--       guessed at here.
--
-- MEDIA SAFETY — the 2026-07-04 rule ("non-null is not the same as exists"):
--   * `exercise_library.image_s3_path` / `video_s3_path` are NOT touched. The S3
--     objects really are named "Calve Stretch From Wall To Floor.jpg"; renaming the
--     path would 404 every one of them. The name column and the media columns are
--     independent, so the display name can be corrected while the paths keep pointing
--     at the real objects.
--   * `exercise_demos` is NOT touched at all — `original_exercise_name` there tracks
--     the S3 object, which is exactly the trap that broke 2,376 media rows in July.
--   * `exercise_canonical.canonical_name` is NOT renamed either: it is the join key
--     `exercise_demos.canonical_exercise_id` resolves through, and it is never shown
--     to a user.
--   * Instead, per the register's own guidance, BOTH spellings are registered in
--     `exercise_aliases`, which is what `resolve_exercise_demo_media()` (mig 2290,
--     the fallback behind GET /exercise-images/{name}) keys on. So a workout row that
--     already stores the old "Calve …" name and a newly generated one that stores
--     "Calf …" both resolve to the same canonical demo media.
--   * `exercise_safety_index` and `exercise_safety_index_mat` are a VIEW and a
--     MATERIALIZED VIEW over `exercise_library_cleaned`, which is itself a MV over
--     `exercise_library` — so three of the four id-spaces inherit both fixes from the
--     single UPDATE below. They are refreshed at the end.
--   * `display_body_part` in exercise_library_cleaned is derived from `target_muscle`
--     by a CASE that maps /calf|calves|gastrocnemius|soleus/ to 'Calves', so fixing
--     target_muscle also fixes the body-part chip.
--
-- Verified before and after with:
--   .venv/bin/python scripts/audit_exercise_media_urls.py --check     (all 4 columns OK)

BEGIN;

-- `_Female` / `_Male` is glued on with an underscore, and Postgres ARE counts `_` as a
-- word character — so '\mcalves\M' does NOT match "Foam Roller Calves_Female". Every
-- calf predicate below therefore matches against the gender-stripped name.
CREATE OR REPLACE FUNCTION exercise_name_is_calf(p_name text)
RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$
  SELECT regexp_replace(COALESCE(p_name, ''), '_(female|male)$', '', 'i')
         ~* '\m(calf|calve|calves)\M';
$$;

-- Reversible snapshot of every row this migration touches. Append-safe so re-running
-- the migration never overwrites the ORIGINAL pre-migration values.
CREATE TABLE IF NOT EXISTS exercise_library_calf_backup_2348 (
    id uuid,
    exercise_name text,
    body_part text,
    target_muscle text,
    secondary_muscles text[]
);
INSERT INTO exercise_library_calf_backup_2348
SELECT e.id, e.exercise_name, e.body_part, e.target_muscle, e.secondary_muscles
FROM exercise_library e
WHERE (e.exercise_name ~* '\mcalve\M'
       OR (exercise_name_is_calf(e.exercise_name)
           AND e.target_muscle IN ('Full Body (Multiple Muscle Groups)',
                                   'Quadriceps (Quadriceps Femoris), Glutes (Gluteus Maximus)')))
  AND NOT EXISTS (SELECT 1 FROM exercise_library_calf_backup_2348 b WHERE b.id = e.id);

CREATE TABLE IF NOT EXISTS exercise_library_i18n_calf_backup_2348 (
    exercise_id text,
    locale text,
    name text
);
INSERT INTO exercise_library_i18n_calf_backup_2348
SELECT i.exercise_id, i.locale, i.name
FROM exercise_library_i18n i
WHERE i.name ~* '\mcalve\M'
  AND NOT EXISTS (
      SELECT 1 FROM exercise_library_i18n_calf_backup_2348 b
      WHERE b.exercise_id = i.exercise_id AND b.locale = i.locale
  );


-- ---------------------------------------------------------------------------
-- 1. Muscle group: the calf family stops claiming to be a full-body movement.
-- ---------------------------------------------------------------------------
-- Wall / step calf stretches and the foam-roll variants. Secondary muscles are the
-- structures a calf stretch actually loads, replacing the import's placeholder
-- '{Core (Rectus Abdominis)}'.
-- Rows that already carry real anatomy in secondary_muscles (Foam Roller Calves lists
-- soleus/popliteus/tibialis posterior) keep it — only the placeholder is replaced.
UPDATE exercise_library
   SET target_muscle = 'Calves (Gastrocnemius, Soleus)',
       secondary_muscles = CASE
           WHEN secondary_muscles IS NULL
             OR secondary_muscles = ARRAY['Core (Rectus Abdominis)']::text[]
           THEN ARRAY['Soleus', 'Achilles tendon', 'Plantar fascia']::text[]
           ELSE secondary_muscles
       END
 WHERE target_muscle = 'Full Body (Multiple Muscle Groups)'
   AND category = 'stretching'
   AND exercise_name_is_calf(exercise_name);

-- Same placeholder, different stamp: the leg-press import wrote
-- 'Quadriceps (Quadriceps Femoris), Glutes (Gluteus Maximus)' onto every row on that
-- machine, including the four "Horizontal Leg Press Calf Raise" variants — whose OWN
-- secondary_muscles already list soleus / gastrocnemius / tibialis posterior, so the
-- primary is unambiguously wrong. A calf raise trains calves on any machine.
UPDATE exercise_library
   SET target_muscle = 'Calves (Gastrocnemius, Soleus)'
 WHERE target_muscle = 'Quadriceps (Quadriceps Femoris), Glutes (Gluteus Maximus)'
   AND exercise_name_is_calf(exercise_name)
   AND exercise_name ~* '\mraise';

-- A `_Female`/`_Male` twin must never disagree with its base row about which muscle
-- it trains. "Cable Calve Raise_Female" claimed Quadriceps + Glutes while
-- "Cable Calve Raise" correctly said Calves. Re-sync every calf twin from its base.
UPDATE exercise_library AS suffixed
   SET target_muscle = base.target_muscle,
       secondary_muscles = base.secondary_muscles
  FROM exercise_library AS base
 WHERE suffixed.exercise_name ~* '_(female|male)$'
   AND base.exercise_name = regexp_replace(suffixed.exercise_name, '_(female|male)$', '', 'i')
   AND exercise_name_is_calf(suffixed.exercise_name)
   AND base.target_muscle IS NOT NULL
   AND base.target_muscle <> 'Full Body (Multiple Muscle Groups)'
   AND suffixed.target_muscle IS DISTINCT FROM base.target_muscle;


-- ---------------------------------------------------------------------------
-- 2. Spelling: "Calve" -> "Calf" on the DISPLAY side only.
-- ---------------------------------------------------------------------------
-- Word-boundary match, so "Calves" (a correct plural) is never touched and neither
-- is any S3 path — image_s3_path / video_s3_path are not in the SET list.
-- Driven by a correction table rather than one hand-written UPDATE per typo, so the
-- next misspelling found by scripts/audit_exercise_naming.py is a one-line addition.
-- Only spellings that are wrong in any register are listed: "tricep"/"bicep" are
-- colloquial in fitness copy (58 catalogue rows use them deliberately) and stay.
CREATE TEMP TABLE _name_corrections(wrong text, right_ text) ON COMMIT DROP;
INSERT INTO _name_corrections VALUES
    ('Calve',   'Calf'),      -- register #64
    ('Dumbell', 'Dumbbell');  -- found by the new naming gate while fixing #64

UPDATE exercise_library e
   SET exercise_name = regexp_replace(e.exercise_name, '\m' || c.wrong || '\M', c.right_, 'gi')
  FROM _name_corrections c
 WHERE e.exercise_name ~* ('\m' || c.wrong || '\M');

-- Localised names: only the locales that never got translated still contain the
-- literal English "Calve". The real translations (ja/ko/zh/es/…) do not match the
-- word-boundary pattern and are left exactly as they are.
UPDATE exercise_library_i18n i
   SET name = regexp_replace(i.name, '\m' || c.wrong || '\M', c.right_, 'gi'),
       updated_at = NOW()
  FROM _name_corrections c
 WHERE i.name ~* ('\m' || c.wrong || '\M');


-- ---------------------------------------------------------------------------
-- 3. Aliases: BOTH spellings resolve to the same canonical demo media.
-- ---------------------------------------------------------------------------
-- exercise_demos still carries the "Calve" S3-tracking name, so without these the
-- corrected names would have no entry in the alias table the media/instruction
-- resolvers key on, and already-persisted workouts would keep the old one.
INSERT INTO exercise_aliases (alias_name, alias_name_normalized, canonical_exercise_id, match_type, match_confidence, is_verified)
SELECT v.alias_name,
       normalize_exercise_name(v.alias_name),
       v.canonical_id,
       'manual',
       1.0,
       true
FROM (VALUES
    ('Calf Stretch From Wall to Floor', '86c512c0-29c2-45f9-acfc-433f8317811e'::uuid),
    ('Calve Stretch From Wall to Floor', '86c512c0-29c2-45f9-acfc-433f8317811e'::uuid),
    ('Calf Stretch Foot on Wall',        '28e6d80f-89cf-48c0-b4a7-c5fb4f773318'::uuid),
    ('Calve Stretch Foot on Wall',       '28e6d80f-89cf-48c0-b4a7-c5fb4f773318'::uuid),
    ('Calves Stretch on Step',           '8e190174-cfea-41ce-8022-fa032cdb05e4'::uuid),
    ('Cable Calf Raise',                 'afe59bfc-e76f-4df5-81e0-35a6b01356c5'::uuid),
    ('Cable Calve Raise',                'afe59bfc-e76f-4df5-81e0-35a6b01356c5'::uuid),
    ('Barbell Seated On Knee Calf Raises',  '2d6d4d56-936a-4c41-b69c-e643e6c3fd5d'::uuid),
    ('Barbell Seated On Knee Calve Raises', '2d6d4d56-936a-4c41-b69c-e643e6c3fd5d'::uuid),
    ('Foam Roller Calves',               '193c0b03-d399-4fc1-831c-dc8a97b2d8de'::uuid),
    ('Dumbbell Burpee',                  '82f58a7a-4a27-420c-aad4-2b57e68c5b19'::uuid),
    ('Dumbell Burpee',                   '82f58a7a-4a27-420c-aad4-2b57e68c5b19'::uuid)
) AS v(alias_name, canonical_id)
ON CONFLICT (alias_name_normalized) DO NOTHING;

COMMIT;

-- ---------------------------------------------------------------------------
-- 4. Propagate to the derived read paths (outside the transaction —
--    REFRESH … CONCURRENTLY cannot run inside one).
--    exercise_library -> exercise_library_cleaned -> exercise_safety_index(_mat)
-- ---------------------------------------------------------------------------
REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned;
REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_safety_index_mat;
