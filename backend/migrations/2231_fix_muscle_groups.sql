-- Migration 2231 — Fix wrong / over-broad primary muscle groups on common
-- compound lifts (community ask: "fix workouts showing the correct muscle
-- groups").
--
-- WHY
--   exercise_library.target_muscle (primary) and secondary_muscles feed the
--   in-workout "muscles worked" surface AND the shareable muscle-map card.
--   Several canonical hip-hinge rows had their primary/secondary INVERTED:
--   they listed the erector spinae (a stabilizer) as the PRIMARY mover and the
--   hamstrings (the prime mover) as a secondary. That is the textbook source of
--   the "wrong muscle group" complaint and it corrupts the share muscle map.
--
-- WHAT (deterministic, source-grounded — NO guessing)
--   The Romanian deadlift is a hip-hinge whose prime movers are the hamstrings
--   and gluteus maximus; the erector spinae works isometrically as a stabilizer
--   (NSCA, Essentials of Strength Training & Conditioning, 4th ed., ch. 14 —
--   hip-hinge / RDL technique; ACSM Guidelines for Exercise Testing &
--   Prescription, 11th ed.). We move hamstrings to PRIMARY and demote the
--   erector spinae to SECONDARY for the RDL rows, and fix the conventional
--   band deadlift whose primary listed Quadriceps + Lower Back while OMITTING
--   the glutes entirely — the conventional deadlift's prime movers are the
--   gluteus maximus, hamstrings, and erector spinae, with the quads as an
--   assisting (secondary) muscle off the floor.
--
-- SCOPE — intentionally conservative. Only rows with an unambiguous, citable
--   anatomical error are touched. Good-mornings, stiff-leg deadlifts, leg
--   curls, hip thrusts, squats, and rows were audited and left as-is (their
--   mappings are anatomically defensible). Each UPDATE is guarded on the
--   exact wrong value so re-running is a no-op (idempotent) and so it will NOT
--   clobber a row that was already corrected.
--
-- AFTER APPLYING: refresh the materialized view that the app actually serves:
--   REFRESH MATERIALIZED VIEW CONCURRENTLY public.exercise_library_cleaned;
--   (Cannot run inside this transaction — the orchestrator/apply script runs it
--   separately, exactly as apply_2084_rewrite.py does.)

-- ---------------------------------------------------------------------------
-- 1. Romanian deadlift — barbell (id b1c78e62-…)
--    primary: Back (Erector Spinae) -> Hamstrings + Glutes
--    secondary: add Lower Back (Erector Spinae) as the stabilizer; keep grip
-- ---------------------------------------------------------------------------
UPDATE public.exercise_library
SET target_muscle = 'Hamstrings (Biceps Femoris, Semitendinosus, Semimembranosus), Glutes (Gluteus Maximus)',
    secondary_muscles = ARRAY[
        'Lower Back (Erector Spinae)',
        'Forearms (Grip)'
    ]
WHERE id = 'b1c78e62-97f8-4e23-96da-08cb95ecbebc'
  AND target_muscle = 'Back (Erector Spinae), Glutes (Gluteus Maximus)';

-- ---------------------------------------------------------------------------
-- 2. Landmine Romanian deadlift (id ef5aa777-…)
-- ---------------------------------------------------------------------------
UPDATE public.exercise_library
SET target_muscle = 'Hamstrings (Biceps Femoris, Semitendinosus, Semimembranosus), Glutes (Gluteus Maximus)',
    secondary_muscles = ARRAY[
        'Lower Back (Erector Spinae)',
        'Forearms (Grip)'
    ]
WHERE id = 'ef5aa777-b4e1-4140-a0dc-ced7bbc09b7c'
  AND target_muscle = 'Back (Erector Spinae), Glutes (Gluteus Maximus)';

-- ---------------------------------------------------------------------------
-- 3. Landmine Romanian deadlift — female-illustration variant (id b0f3df0c-…)
-- ---------------------------------------------------------------------------
UPDATE public.exercise_library
SET target_muscle = 'Hamstrings (Biceps Femoris, Semitendinosus, Semimembranosus), Glutes (Gluteus Maximus)',
    secondary_muscles = ARRAY[
        'Lower Back (Erector Spinae)',
        'Forearms (Grip)'
    ]
WHERE id = 'b0f3df0c-655b-4ba2-a479-d843c7c058af'
  AND target_muscle = 'Back (Erector Spinae), Glutes (Gluteus Maximus)';

-- ---------------------------------------------------------------------------
-- 4. Band deadlift — conventional pull (id 596d606d-…)
--    primary listed Quadriceps + Lower Back and OMITTED the glutes.
--    Conventional deadlift prime movers = Glutes + Hamstrings + Erector Spinae;
--    quads assist off the floor -> secondary.
-- ---------------------------------------------------------------------------
UPDATE public.exercise_library
SET target_muscle = 'Glutes (Gluteus Maximus), Hamstrings (Biceps Femoris, Semitendinosus, Semimembranosus), Lower Back (Erector Spinae)',
    secondary_muscles = ARRAY[
        'Quadriceps (Quadriceps Femoris)',
        'Forearms (Grip)'
    ]
WHERE id = '596d606d-6357-4016-98ac-52d06aec3b15'
  AND target_muscle = 'Quadriceps (Quadriceps Femoris), Lower Back (Erector Spinae)';

-- ---------------------------------------------------------------------------
-- Verification (run after the MV refresh):
--   SELECT name, target_muscle, secondary_muscles
--   FROM public.exercise_library_cleaned
--   WHERE id IN ('b1c78e62-97f8-4e23-96da-08cb95ecbebc',
--                'ef5aa777-b4e1-4140-a0dc-ced7bbc09b7c',
--                'b0f3df0c-655b-4ba2-a479-d843c7c058af',
--                '596d606d-6357-4016-98ac-52d06aec3b15');
-- ---------------------------------------------------------------------------
