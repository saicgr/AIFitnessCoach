-- Program: Box Breathing Workout
-- Category: Mind & Breath -> mind_body
-- Priority: High
-- Durations: [1, 2], Sessions: [7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Box Breathing Workout',
    'Master the 4-4-4-4 box breathing technique used by Navy SEALs',
    'mind_body',
    'all_levels',
    2,
    7,
    'custom',
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    true,
    true
) ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    difficulty_level = EXCLUDED.difficulty_level,
    duration_weeks = EXCLUDED.duration_weeks,
    sessions_per_week = EXCLUDED.sessions_per_week,
    split_type = EXCLUDED.split_type,
    goals = EXCLUDED.goals,
    requires_gym = EXCLUDED.requires_gym,
    updated_at = NOW();

-- Variant: Box Breathing Workout - 1w 7x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    1,
    'Box Breathing Workout - 1w 7x/wk',
    'mind_body',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Box Breathing Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: deepen practice, longer holds',
    '[{"workout_name": "Box Breathing Workout", "type": "mind_body", "duration_minutes": 15, "exercises": [{"name": "Warm-Up Belly Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Deep diaphragmatic breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Hand on belly, expand fully on inhale", "substitution": "Natural Breathing"}, {"name": "Box Breathing 4-Count", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 10, "weight_guidance": "4s in, 4s hold, 4s out, 4s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "beginner", "form_cue": "Equal counts all four phases", "substitution": "Triangle Breathing"}, {"name": "Box Breathing 6-Count", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "6s in, 6s hold, 6s out, 6s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "intermediate", "form_cue": "Longer counts for deeper practice", "substitution": "Box Breathing 4-Count"}, {"name": "Breath Retention Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 4, "rest_seconds": 30, "weight_guidance": "Gentle walk with holds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Diaphragm", "secondary_muscles": ["Legs", "Core"], "difficulty": "beginner", "form_cue": "Walk slowly during hold phase", "substitution": "Seated Breath Hold"}, {"name": "Recovery Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Natural rhythm restoration", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Let breathing normalize, observe rhythm", "substitution": "Belly Breathing"}]}, {"workout_name": "Box Breathing Workout", "type": "mind_body", "duration_minutes": 15, "exercises": [{"name": "Warm-Up Belly Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Deep diaphragmatic breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Hand on belly, expand fully on inhale", "substitution": "Natural Breathing"}, {"name": "Box Breathing 4-Count", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 10, "weight_guidance": "4s in, 4s hold, 4s out, 4s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "beginner", "form_cue": "Equal counts all four phases", "substitution": "Triangle Breathing"}, {"name": "Box Breathing 6-Count", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "6s in, 6s hold, 6s out, 6s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "intermediate", "form_cue": "Longer counts for deeper practice", "substitution": "Box Breathing 4-Count"}, {"name": "Breath Retention Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 4, "rest_seconds": 30, "weight_guidance": "Gentle walk with holds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Diaphragm", "secondary_muscles": ["Legs", "Core"], "difficulty": "beginner", "form_cue": "Walk slowly during hold phase", "substitution": "Seated Breath Hold"}, {"name": "Recovery Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Natural rhythm restoration", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Let breathing normalize, observe rhythm", "substitution": "Belly Breathing"}]}, {"workout_name": "Box Breathing Workout", "type": "mind_body", "duration_minutes": 15, "exercises": [{"name": "Warm-Up Belly Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Deep diaphragmatic breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Hand on belly, expand fully on inhale", "substitution": "Natural Breathing"}, {"name": "Box Breathing 4-Count", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 10, "weight_guidance": "4s in, 4s hold, 4s out, 4s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "beginner", "form_cue": "Equal counts all four phases", "substitution": "Triangle Breathing"}, {"name": "Box Breathing 6-Count", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "6s in, 6s hold, 6s out, 6s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "intermediate", "form_cue": "Longer counts for deeper practice", "substitution": "Box Breathing 4-Count"}, {"name": "Breath Retention Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 4, "rest_seconds": 30, "weight_guidance": "Gentle walk with holds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Diaphragm", "secondary_muscles": ["Legs", "Core"], "difficulty": "beginner", "form_cue": "Walk slowly during hold phase", "substitution": "Seated Breath Hold"}, {"name": "Recovery Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Natural rhythm restoration", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Let breathing normalize, observe rhythm", "substitution": "Belly Breathing"}]}]'::jsonb,
    'Box Breathing Workout',
    'Box Breathing Workout - 1w 7x/wk',
    'High',
    false,
    'Master the 4-4-4-4 box breathing technique used by Navy SEALs',
    'Mind & Breath'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Box Breathing Workout'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: Box Breathing Workout - 2w 7x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    2,
    'Box Breathing Workout - 2w 7x/wk',
    'mind_body',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Box Breathing Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: deepen practice, longer holds',
    '[{"workout_name": "Box Breathing Workout", "type": "mind_body", "duration_minutes": 15, "exercises": [{"name": "Warm-Up Belly Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Deep diaphragmatic breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Hand on belly, expand fully on inhale", "substitution": "Natural Breathing"}, {"name": "Box Breathing 4-Count", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 10, "weight_guidance": "4s in, 4s hold, 4s out, 4s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "beginner", "form_cue": "Equal counts all four phases", "substitution": "Triangle Breathing"}, {"name": "Box Breathing 6-Count", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "6s in, 6s hold, 6s out, 6s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "intermediate", "form_cue": "Longer counts for deeper practice", "substitution": "Box Breathing 4-Count"}, {"name": "Breath Retention Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 4, "rest_seconds": 30, "weight_guidance": "Gentle walk with holds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Diaphragm", "secondary_muscles": ["Legs", "Core"], "difficulty": "beginner", "form_cue": "Walk slowly during hold phase", "substitution": "Seated Breath Hold"}, {"name": "Recovery Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Natural rhythm restoration", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Let breathing normalize, observe rhythm", "substitution": "Belly Breathing"}]}, {"workout_name": "Box Breathing Workout", "type": "mind_body", "duration_minutes": 15, "exercises": [{"name": "Warm-Up Belly Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Deep diaphragmatic breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Hand on belly, expand fully on inhale", "substitution": "Natural Breathing"}, {"name": "Box Breathing 4-Count", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 10, "weight_guidance": "4s in, 4s hold, 4s out, 4s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "beginner", "form_cue": "Equal counts all four phases", "substitution": "Triangle Breathing"}, {"name": "Box Breathing 6-Count", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "6s in, 6s hold, 6s out, 6s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "intermediate", "form_cue": "Longer counts for deeper practice", "substitution": "Box Breathing 4-Count"}, {"name": "Breath Retention Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 4, "rest_seconds": 30, "weight_guidance": "Gentle walk with holds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Diaphragm", "secondary_muscles": ["Legs", "Core"], "difficulty": "beginner", "form_cue": "Walk slowly during hold phase", "substitution": "Seated Breath Hold"}, {"name": "Recovery Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Natural rhythm restoration", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Let breathing normalize, observe rhythm", "substitution": "Belly Breathing"}]}, {"workout_name": "Box Breathing Workout", "type": "mind_body", "duration_minutes": 15, "exercises": [{"name": "Warm-Up Belly Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Deep diaphragmatic breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Hand on belly, expand fully on inhale", "substitution": "Natural Breathing"}, {"name": "Box Breathing 4-Count", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 10, "weight_guidance": "4s in, 4s hold, 4s out, 4s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "beginner", "form_cue": "Equal counts all four phases", "substitution": "Triangle Breathing"}, {"name": "Box Breathing 6-Count", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "6s in, 6s hold, 6s out, 6s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "intermediate", "form_cue": "Longer counts for deeper practice", "substitution": "Box Breathing 4-Count"}, {"name": "Breath Retention Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 4, "rest_seconds": 30, "weight_guidance": "Gentle walk with holds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Diaphragm", "secondary_muscles": ["Legs", "Core"], "difficulty": "beginner", "form_cue": "Walk slowly during hold phase", "substitution": "Seated Breath Hold"}, {"name": "Recovery Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Natural rhythm restoration", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Let breathing normalize, observe rhythm", "substitution": "Belly Breathing"}]}]'::jsonb,
    'Box Breathing Workout',
    'Box Breathing Workout - 2w 7x/wk',
    'High',
    false,
    'Master the 4-4-4-4 box breathing technique used by Navy SEALs',
    'Mind & Breath'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Box Breathing Workout'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Peak: integrate all techniques, independent practice',
    '[{"workout_name": "Box Breathing Workout", "type": "mind_body", "duration_minutes": 15, "exercises": [{"name": "Warm-Up Belly Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Deep diaphragmatic breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Hand on belly, expand fully on inhale", "substitution": "Natural Breathing"}, {"name": "Box Breathing 4-Count", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 10, "weight_guidance": "4s in, 4s hold, 4s out, 4s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "beginner", "form_cue": "Equal counts all four phases", "substitution": "Triangle Breathing"}, {"name": "Box Breathing 6-Count", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "6s in, 6s hold, 6s out, 6s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "intermediate", "form_cue": "Longer counts for deeper practice", "substitution": "Box Breathing 4-Count"}, {"name": "Breath Retention Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 4, "rest_seconds": 30, "weight_guidance": "Gentle walk with holds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Diaphragm", "secondary_muscles": ["Legs", "Core"], "difficulty": "beginner", "form_cue": "Walk slowly during hold phase", "substitution": "Seated Breath Hold"}, {"name": "Recovery Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Natural rhythm restoration", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Let breathing normalize, observe rhythm", "substitution": "Belly Breathing"}]}, {"workout_name": "Box Breathing Workout", "type": "mind_body", "duration_minutes": 15, "exercises": [{"name": "Warm-Up Belly Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Deep diaphragmatic breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Hand on belly, expand fully on inhale", "substitution": "Natural Breathing"}, {"name": "Box Breathing 4-Count", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 10, "weight_guidance": "4s in, 4s hold, 4s out, 4s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "beginner", "form_cue": "Equal counts all four phases", "substitution": "Triangle Breathing"}, {"name": "Box Breathing 6-Count", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "6s in, 6s hold, 6s out, 6s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "intermediate", "form_cue": "Longer counts for deeper practice", "substitution": "Box Breathing 4-Count"}, {"name": "Breath Retention Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 4, "rest_seconds": 30, "weight_guidance": "Gentle walk with holds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Diaphragm", "secondary_muscles": ["Legs", "Core"], "difficulty": "beginner", "form_cue": "Walk slowly during hold phase", "substitution": "Seated Breath Hold"}, {"name": "Recovery Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Natural rhythm restoration", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Let breathing normalize, observe rhythm", "substitution": "Belly Breathing"}]}, {"workout_name": "Box Breathing Workout", "type": "mind_body", "duration_minutes": 15, "exercises": [{"name": "Warm-Up Belly Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Deep diaphragmatic breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Hand on belly, expand fully on inhale", "substitution": "Natural Breathing"}, {"name": "Box Breathing 4-Count", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 10, "weight_guidance": "4s in, 4s hold, 4s out, 4s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "beginner", "form_cue": "Equal counts all four phases", "substitution": "Triangle Breathing"}, {"name": "Box Breathing 6-Count", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "6s in, 6s hold, 6s out, 6s hold", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals", "Core"], "difficulty": "intermediate", "form_cue": "Longer counts for deeper practice", "substitution": "Box Breathing 4-Count"}, {"name": "Breath Retention Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 4, "rest_seconds": 30, "weight_guidance": "Gentle walk with holds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Diaphragm", "secondary_muscles": ["Legs", "Core"], "difficulty": "beginner", "form_cue": "Walk slowly during hold phase", "substitution": "Seated Breath Hold"}, {"name": "Recovery Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Natural rhythm restoration", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Intercostals"], "difficulty": "beginner", "form_cue": "Let breathing normalize, observe rhythm", "substitution": "Belly Breathing"}]}]'::jsonb,
    'Box Breathing Workout',
    'Box Breathing Workout - 2w 7x/wk',
    'High',
    false,
    'Master the 4-4-4-4 box breathing technique used by Navy SEALs',
    'Mind & Breath'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Box Breathing Workout'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
