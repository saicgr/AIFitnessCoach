-- Finding #465: exercises_json rows written by the program_template expansion
-- path (services/program_template_expander.py::_day_to_exercises_json) never
-- copied muscle_group from exercise_library, so every exercise in a session
-- except one injected via the separate staple path (which already resolves
-- target_muscle -> muscle_group, see preference_engine._build_exercise_object)
-- stores no muscle_group at all. Code fix lands alongside this migration
-- (program_template_expander.py now selects target_muscle/body_part and
-- writes muscle_group the same way staples do); this backfills exercises_json
-- already persisted before that fix, joining each element's exercise_id back
-- to exercise_library.

DO $$
DECLARE
  w RECORD;
  new_json jsonb;
  ex jsonb;
  i int;
  ex_id uuid;
  lib_muscle text;
  cleaned text;
BEGIN
  FOR w IN
    SELECT id, exercises_json
    FROM workouts
    WHERE exercises_json IS NOT NULL
      AND jsonb_typeof(exercises_json) = 'array'
      AND EXISTS (
        SELECT 1 FROM jsonb_array_elements(exercises_json) e
        WHERE (e ->> 'muscle_group') IS NULL AND (e ->> 'exercise_id') IS NOT NULL
      )
  LOOP
    new_json := w.exercises_json;
    FOR i IN 0 .. jsonb_array_length(w.exercises_json) - 1 LOOP
      ex := w.exercises_json -> i;
      IF (ex ->> 'muscle_group') IS NULL AND (ex ->> 'exercise_id') IS NOT NULL THEN
        BEGIN
          ex_id := (ex ->> 'exercise_id')::uuid;
        EXCEPTION WHEN OTHERS THEN
          ex_id := NULL;
        END;
        IF ex_id IS NOT NULL THEN
          SELECT COALESCE(target_muscle, body_part) INTO lib_muscle
          FROM exercise_library WHERE id = ex_id;
          IF lib_muscle IS NOT NULL THEN
            cleaned := NULLIF(trim(regexp_replace(lib_muscle, '\s*\(.*?\)', '', 'g')), '');
            IF cleaned IS NOT NULL THEN
              new_json := jsonb_set(new_json, ARRAY[i::text, 'muscle_group'], to_jsonb(cleaned));
            END IF;
          END IF;
        END IF;
      END IF;
    END LOOP;
    IF new_json IS DISTINCT FROM w.exercises_json THEN
      UPDATE workouts SET exercises_json = new_json WHERE id = w.id;
    END IF;
  END LOOP;
END $$;

-- VERIFY: select count(*) from workouts w, jsonb_array_elements(w.exercises_json) e where e->>'muscle_group' is null and e->>'exercise_id' is not null and (e->>'exercise_id')::uuid in (select id from exercise_library where target_muscle is not null or body_part is not null);
