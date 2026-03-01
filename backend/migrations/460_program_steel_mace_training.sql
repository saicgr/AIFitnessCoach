-- Program: Steel Mace Training
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [2, 4, 8, 12], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Steel Mace Training',
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'equipment_specific',
    'all_levels',
    12,
    4,
    'flow',
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness']::text[],
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

-- Variant: Steel Mace Training - 2w 3x/wk
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
    'Steel Mace Training - 2w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Steel Mace Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 2w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 2w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Steel Mace Training - 2w 4x/wk
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
    'Steel Mace Training - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Steel Mace Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 2w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 2w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Steel Mace Training - 4w 3x/wk
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
    'Steel Mace Training - 4w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Steel Mace Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 4w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 4w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 4w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 4w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Steel Mace Training - 4w 4x/wk
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
    'Steel Mace Training - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Steel Mace Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 4w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 4w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 4w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 4w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Steel Mace Training - 8w 3x/wk
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
    'Steel Mace Training - 8w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Steel Mace Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Steel Mace Training - 8w 4x/wk
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
    'Steel Mace Training - 8w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Steel Mace Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 8w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Steel Mace Training - 12w 3x/wk
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
    12,
    'Steel Mace Training - 12w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Steel Mace Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Foundation (Base Building)',
    'Week 3 - Foundation',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Build (Progressive Overload)',
    'Week 5 - Progressive overload',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Build (Progressive Overload)',
    'Week 6 - Progressive overload',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Peak (Intensification)',
    'Week 7 - Peak intensity',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Peak (Intensification)',
    'Week 8 - Peak intensity',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    9,
    'Peak (Intensification)',
    'Week 9 - Peak intensity',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    10,
    'Taper (Deload)',
    'Week 10 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    11,
    'Test/Maintenance',
    'Week 11 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    12,
    'Test/Maintenance',
    'Week 12 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 3x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Steel Mace Training - 12w 4x/wk
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
    12,
    'Steel Mace Training - 12w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Steel Mace Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Foundation (Base Building)',
    'Week 3 - Foundation',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
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
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Build (Progressive Overload)',
    'Week 5 - Progressive overload',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Build (Progressive Overload)',
    'Week 6 - Progressive overload',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Peak (Intensification)',
    'Week 7 - Peak intensity',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Peak (Intensification)',
    'Week 8 - Peak intensity',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    9,
    'Peak (Intensification)',
    'Week 9 - Peak intensity',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    10,
    'Taper (Deload)',
    'Week 10 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    11,
    'Test/Maintenance',
    'Week 11 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    12,
    'Test/Maintenance',
    'Week 12 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Steel Mace Rotational Strength", "type": "strength", "exercises": [{"name": "Mace 360 Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate mace", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Full circle around head, control the offset weight", "substitution": "Mace 10-to-2"}, {"name": "Mace Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Hold mace at chest, squat deep", "substitution": "Mace Lunge"}, {"name": "Mace Gravedigger", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Diagonal shovel motion, rotate hips", "substitution": "Mace Woodchop"}, {"name": "Mace Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light-moderate mace - 4/side", "equipment": "Steel Mace", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press from shoulder, offset challenges stability", "substitution": "Mace Push Press"}, {"name": "Mace Barbarian Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate mace", "equipment": "Steel Mace", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Switch grip squat, overhead between reps", "substitution": "Mace 360 to Squat"}, {"name": "Mace Paddle Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light mace", "equipment": "Steel Mace", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Forearms"], "difficulty": "beginner", "form_cue": "Horizontal swing side to side like paddling", "substitution": "Mace 360"}]}]'::jsonb,
    'Steel Mace Training',
    'Steel Mace Training - 12w 4x/wk',
    'low',
    false,
    'Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Steel Mace Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
