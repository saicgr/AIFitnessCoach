-- Program: Sandbag Training
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [2, 4, 8], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Sandbag Training',
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'equipment_specific',
    'all_levels',
    8,
    4,
    'full_body',
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

-- Variant: Sandbag Training - 2w 3x/wk
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
    'Sandbag Training - 2w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Sandbag Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 2w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 2w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Sandbag Training - 2w 4x/wk
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
    'Sandbag Training - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Sandbag Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 2w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 2w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Sandbag Training - 4w 3x/wk
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
    'Sandbag Training - 4w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Sandbag Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 4w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 4w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 4w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 4w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Sandbag Training - 4w 4x/wk
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
    'Sandbag Training - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Sandbag Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 4w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 4w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 4w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 4w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Sandbag Training - 8w 3x/wk
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
    'Sandbag Training - 8w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Sandbag Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 3x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Sandbag Training - 8w 4x/wk
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
    'Sandbag Training - 8w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Sandbag Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
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
    '[{"workout_name": "Day 1 - Sandbag Functional", "type": "strength", "exercises": [{"name": "Sandbag Bear Hug Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate sandbag", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, squat deep", "substitution": "Sandbag Front Squat"}, {"name": "Sandbag Clean and Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to chest, press overhead", "substitution": "Sandbag Shoulder"}, {"name": "Sandbag Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to chest", "substitution": "Sandbag High Pull"}, {"name": "Sandbag Carry", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Grip Strength"], "difficulty": "intermediate", "form_cue": "Bear hug or shoulder carry, walk controlled", "substitution": "Sandbag Drag"}, {"name": "Sandbag Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bag close to body", "substitution": "Sandbag Deadlift"}, {"name": "Sandbag Rotational Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Sandbag", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Pick up, rotate, slam to other side", "substitution": "Sandbag Russian Twist"}]}]'::jsonb,
    'Sandbag Training',
    'Sandbag Training - 8w 4x/wk',
    'low',
    true,
    'Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Sandbag Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
