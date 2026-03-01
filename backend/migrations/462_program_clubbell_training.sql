-- Program: Clubbell Training
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [2, 4, 8], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Clubbell Training',
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'equipment_specific',
    'all_levels',
    8,
    4,
    'custom',
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
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

-- Variant: Clubbell Training - 2w 3x/wk
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
    'Clubbell Training - 2w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Clubbell Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 2w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 2w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Clubbell Training - 2w 4x/wk
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
    'Clubbell Training - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Clubbell Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 2w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 2w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Clubbell Training - 4w 3x/wk
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
    4,
    'Clubbell Training - 4w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Clubbell Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 4w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Progressive overload',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 4w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Peak intensity',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 4w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 4w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Clubbell Training - 4w 4x/wk
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
    4,
    'Clubbell Training - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Clubbell Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 4w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Progressive overload',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 4w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Peak intensity',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 4w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 4w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Clubbell Training - 8w 3x/wk
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
    8,
    'Clubbell Training - 8w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Clubbell Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Progressive overload',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Progressive overload',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Peak intensity',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Peak intensity',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 3x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Clubbell Training - 8w 4x/wk
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
    8,
    'Clubbell Training - 8w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Clubbell Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Progressive overload',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Progressive overload',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Peak intensity',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Peak intensity',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Clubbell Strength", "type": "strength", "exercises": [{"name": "Clubbell Swipe", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Swing club in arc, offset weight challenges grip", "substitution": "Clubbell Mill"}, {"name": "Clubbell Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Core"], "difficulty": "intermediate", "form_cue": "Circular mill around shoulder", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Torch Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club - 4/side", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Bottom-up press, extreme grip challenge", "substitution": "Clubbell Overhead Press"}, {"name": "Clubbell Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold at chest or order position, squat", "substitution": "Clubbell Lunge"}, {"name": "Clubbell Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate club", "equipment": "Clubbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Protective casting motion around head", "substitution": "Clubbell Swipe"}, {"name": "Clubbell Hammer Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light club - 5/side", "equipment": "Clubbell", "body_part": "Arms", "primary_muscle": "Brachioradialis", "secondary_muscles": ["Biceps Brachii", "Forearms"], "difficulty": "intermediate", "form_cue": "Offset weight challenges forearms intensely", "substitution": "Clubbell Arm Cast"}]}]'::jsonb,
    'Clubbell Training',
    'Clubbell Training - 8w 4x/wk',
    'low',
    false,
    'Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Clubbell Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
