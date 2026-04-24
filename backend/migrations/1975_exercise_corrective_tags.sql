-- 1975: Corrective-exercise tagging on exercise_library.
-- Values drawn from NSCA/NASM corrective-exercise literature.

BEGIN;

ALTER TABLE public.exercise_library
  ADD COLUMN IF NOT EXISTS corrective_for text[] DEFAULT '{}'::text[];

COMMENT ON COLUMN public.exercise_library.corrective_for IS
  'Array of posture issues this exercise corrects: forward_head_posture, rounded_shoulders, anterior_pelvic_tilt, uneven_shoulders, knee_valgus, scapular_winging.';

CREATE INDEX IF NOT EXISTS idx_exercise_library_corrective_for
  ON public.exercise_library USING GIN (corrective_for);

UPDATE public.exercise_library
SET corrective_for = ARRAY['rounded_shoulders','forward_head_posture']::text[]
WHERE lower(exercise_name) LIKE '%wall angel%'
   OR lower(exercise_name) LIKE '%face pull%'
   OR lower(exercise_name) LIKE '%band pull%apart%'
   OR lower(exercise_name) LIKE '%chin tuck%'
   OR lower(exercise_name) LIKE '%prone y t w%'
   OR lower(exercise_name) LIKE '%prone cobra%';

UPDATE public.exercise_library
SET corrective_for = ARRAY['scapular_winging','rounded_shoulders']::text[]
WHERE lower(exercise_name) LIKE '%scapular push%up%'
   OR lower(exercise_name) LIKE '%serratus%wall%slide%'
   OR lower(exercise_name) LIKE '%scapular pull%';

UPDATE public.exercise_library
SET corrective_for = ARRAY['anterior_pelvic_tilt']::text[]
WHERE lower(exercise_name) LIKE '%dead bug%'
   OR lower(exercise_name) LIKE '%glute bridge%'
   OR lower(exercise_name) LIKE '%hip flexor stretch%'
   OR lower(exercise_name) LIKE '%pelvic tilt%'
   OR lower(exercise_name) LIKE '%bird dog%';

UPDATE public.exercise_library
SET corrective_for = ARRAY['knee_valgus']::text[]
WHERE lower(exercise_name) LIKE '%clamshell%'
   OR lower(exercise_name) LIKE '%banded side walk%'
   OR lower(exercise_name) LIKE '%monster walk%'
   OR lower(exercise_name) LIKE '%lateral band walk%'
   OR lower(exercise_name) LIKE '%single%leg glute bridge%';

UPDATE public.exercise_library
SET corrective_for = ARRAY['uneven_shoulders']::text[]
WHERE lower(exercise_name) LIKE '%single%arm dumbbell row%'
   OR lower(exercise_name) LIKE '%single%arm landmine press%'
   OR lower(exercise_name) LIKE '%single%arm shoulder press%';

COMMIT;
