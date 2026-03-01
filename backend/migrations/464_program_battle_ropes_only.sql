-- Program: Battle Ropes Only
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [1, 2, 4], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Battle Ropes Only',
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'equipment_specific',
    'all_levels',
    4,
    4,
    'circuit',
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
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

-- Variant: Battle Ropes Only - 1w 3x/wk
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
    'Battle Ropes Only - 1w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Battle Ropes Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 1w 3x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Battle Ropes Only - 1w 4x/wk
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
    'Battle Ropes Only - 1w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Battle Ropes Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 1w 4x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Battle Ropes Only - 2w 3x/wk
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
    'Battle Ropes Only - 2w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Battle Ropes Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 2w 3x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
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
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 2w 3x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Battle Ropes Only - 2w 4x/wk
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
    'Battle Ropes Only - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Battle Ropes Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 2w 4x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
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
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 2w 4x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Battle Ropes Only - 4w 3x/wk
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
    'Battle Ropes Only - 4w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Battle Ropes Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 4w 3x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
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
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 4w 3x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
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
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 4w 3x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
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
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 4w 3x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Battle Ropes Only - 4w 4x/wk
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
    'Battle Ropes Only - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Battle Ropes Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 4w 4x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
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
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 4w 4x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
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
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 4w 4x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
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
    '[{"workout_name": "Day 1 - Battle Ropes Conditioning", "type": "hiit", "exercises": [{"name": "Alternating Wave", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Fast alternating arms, create waves", "substitution": "Double Wave"}, {"name": "Double Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Both arms together, slam down", "substitution": "Alternating Wave"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Raise overhead, slam to floor", "substitution": "Double Wave"}, {"name": "Snake Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Move arms side to side, snake on floor", "substitution": "Alternating Wave"}, {"name": "Clap Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Swing ropes together and apart", "substitution": "Double Wave"}, {"name": "Squat Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 sec work", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Alternating waves while in squat position", "substitution": "Alternating Wave"}]}]'::jsonb,
    'Battle Ropes Only',
    'Battle Ropes Only - 4w 4x/wk',
    'low',
    false,
    'Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Battle Ropes Only'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
