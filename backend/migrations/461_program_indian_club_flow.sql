-- Program: Indian Club Flow
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [2, 4, 8], Sessions: [4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Indian Club Flow',
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'equipment_specific',
    'all_levels',
    8,
    5,
    'flow',
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
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

-- Variant: Indian Club Flow - 2w 4x/wk
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
    'Indian Club Flow - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Indian Club Flow'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 2w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 2w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Indian Club Flow - 2w 5x/wk
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
    'Indian Club Flow - 2w 5x/wk',
    'equipment_specific',
    5,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Indian Club Flow'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 2w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 2w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Indian Club Flow - 4w 4x/wk
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
    'Indian Club Flow - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Indian Club Flow'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 4w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 4w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 4w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 4w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Indian Club Flow - 4w 5x/wk
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
    'Indian Club Flow - 4w 5x/wk',
    'equipment_specific',
    5,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Indian Club Flow'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 4w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Progressive overload',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 4w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Peak intensity',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 4w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 4w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Indian Club Flow - 8w 4x/wk
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
    'Indian Club Flow - 8w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Indian Club Flow'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
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
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 4x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Indian Club Flow - 8w 5x/wk
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
    'Indian Club Flow - 8w 5x/wk',
    'equipment_specific',
    5,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Indian Club Flow'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Progressive overload',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Progressive overload',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Peak intensity',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Peak intensity',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Indian Club Shoulder Flow", "type": "flexibility", "exercises": [{"name": "Club Arm Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff", "Forearms"], "difficulty": "beginner", "form_cue": "Swing club behind shoulder, cast forward", "substitution": "Club Shield Cast"}, {"name": "Club Shield Cast", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Side protection motion, like casting a shield", "substitution": "Club Arm Cast"}, {"name": "Club Mill", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club - 4/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Deltoids", "Forearms"], "difficulty": "beginner", "form_cue": "Circular motion around shoulder joint", "substitution": "Club Arm Cast"}, {"name": "Club Front Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Grip Strength"], "difficulty": "beginner", "form_cue": "Forward pendulum swing with control", "substitution": "Club Side Swing"}, {"name": "Club Side Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light club - 5/side", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Lateral swing motion, both directions", "substitution": "Club Front Swing"}, {"name": "Club Figure 8", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 20, "weight_guidance": "Light club", "equipment": "Indian Club", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "beginner", "form_cue": "Weave club in figure-8 pattern around body", "substitution": "Club Mill"}]}]'::jsonb,
    'Indian Club Flow',
    'Indian Club Flow - 8w 5x/wk',
    'low',
    false,
    'Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Indian Club Flow'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
