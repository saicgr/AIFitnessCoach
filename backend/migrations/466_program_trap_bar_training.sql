-- Program: Trap Bar Training
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [2, 4, 8], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Trap Bar Training',
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
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

-- Variant: Trap Bar Training - 2w 3x/wk
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
    'Trap Bar Training - 2w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Trap Bar Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 2w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 2w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Trap Bar Training - 2w 4x/wk
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
    'Trap Bar Training - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Trap Bar Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 2w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 2w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Trap Bar Training - 4w 3x/wk
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
    'Trap Bar Training - 4w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Trap Bar Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 4w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 4w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 4w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 4w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Trap Bar Training - 4w 4x/wk
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
    'Trap Bar Training - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Trap Bar Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 4w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 4w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 4w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 4w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Trap Bar Training - 8w 3x/wk
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
    'Trap Bar Training - 8w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Trap Bar Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 3x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Trap Bar Training - 8w 4x/wk
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
    'Trap Bar Training - 8w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Trap Bar Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
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
    '[{"workout_name": "Day 1 - Trap Bar Strength", "type": "strength", "exercises": [{"name": "Trap Bar Deadlift", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Quadriceps", "Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Neutral grip, push floor away, lockout", "substitution": "Trap Bar Romanian Deadlift"}, {"name": "Trap Bar Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 75, "weight_guidance": "Moderate-heavy", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "High handles, squat pattern with neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Farmer''s Walk", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 45, "weight_guidance": "Heavy - 30 sec", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Trapezius", "Core"], "difficulty": "intermediate", "form_cue": "Walk controlled with heavy load", "substitution": "Trap Bar Hold"}, {"name": "Trap Bar Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Trap Bar", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "intermediate", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Hinge at hips, neutral grip", "substitution": "Trap Bar Deadlift"}, {"name": "Trap Bar Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light", "equipment": "Trap Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, reset", "substitution": "Trap Bar Deadlift"}]}]'::jsonb,
    'Trap Bar Training',
    'Trap Bar Training - 8w 4x/wk',
    'low',
    true,
    'Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Trap Bar Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
