-- Program: Post-Push Day Recovery
-- Category: Lift Mobility -> mobility
-- Priority: Med
-- Durations: [1, 2], Sessions: [3]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Post-Push Day Recovery',
    'Recovery work after chest and shoulder sessions targeting pecs, triceps, and thoracic spine',
    'mobility',
    'all_levels',
    2,
    3,
    'flow',
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
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

-- Variant: Post-Push Day Recovery - 1w 3x/wk
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
    'Post-Push Day Recovery - 1w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Push Day Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build',
    '[{"workout_name": "Post-Push Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Pecs", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Lie face down on roller angled under pec", "substitution": "Lacrosse Ball Pec Release"}, {"name": "Doorway Pec Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm at 90 degrees in doorframe, step through", "substitution": "Floor Pec Stretch"}, {"name": "Overhead Tricep Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Reach behind head, use other hand to press elbow", "substitution": "Tricep Wall Stretch"}, {"name": "Foam Roll Triceps", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Arm extended, roll from elbow to armpit area", "substitution": "Lacrosse Ball Tricep"}, {"name": "Prone Y-T-W Raises", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Light or no weight", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rear Deltoid", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Lie face down, arms in Y then T then W shapes", "substitution": "Band Pull-Apart"}, {"name": "Thoracic Rotation", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Side-lying, rotate top arm open to the floor", "substitution": "Seated Thoracic Rotation"}]}]'::jsonb,
    'Post-Push Day Recovery',
    'Post-Push Day Recovery - 1w 3x/wk',
    'Med',
    false,
    'Recovery work after chest and shoulder sessions targeting pecs, triceps, and thoracic spine',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Push Day Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Post-Push Day Recovery - 2w 3x/wk
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
    'Post-Push Day Recovery - 2w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Push Day Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build',
    '[{"workout_name": "Post-Push Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Pecs", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Lie face down on roller angled under pec", "substitution": "Lacrosse Ball Pec Release"}, {"name": "Doorway Pec Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm at 90 degrees in doorframe, step through", "substitution": "Floor Pec Stretch"}, {"name": "Overhead Tricep Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Reach behind head, use other hand to press elbow", "substitution": "Tricep Wall Stretch"}, {"name": "Foam Roll Triceps", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Arm extended, roll from elbow to armpit area", "substitution": "Lacrosse Ball Tricep"}, {"name": "Prone Y-T-W Raises", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Light or no weight", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rear Deltoid", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Lie face down, arms in Y then T then W shapes", "substitution": "Band Pull-Apart"}, {"name": "Thoracic Rotation", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Side-lying, rotate top arm open to the floor", "substitution": "Seated Thoracic Rotation"}]}, {"workout_name": "Post-Push Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Pecs", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Lie face down on roller angled under pec", "substitution": "Lacrosse Ball Pec Release"}, {"name": "Doorway Pec Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm at 90 degrees in doorframe, step through", "substitution": "Floor Pec Stretch"}, {"name": "Overhead Tricep Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Reach behind head, use other hand to press elbow", "substitution": "Tricep Wall Stretch"}, {"name": "Foam Roll Triceps", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Arm extended, roll from elbow to armpit area", "substitution": "Lacrosse Ball Tricep"}, {"name": "Prone Y-T-W Raises", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Light or no weight", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rear Deltoid", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Lie face down, arms in Y then T then W shapes", "substitution": "Band Pull-Apart"}, {"name": "Thoracic Rotation", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Side-lying, rotate top arm open to the floor", "substitution": "Seated Thoracic Rotation"}]}]'::jsonb,
    'Post-Push Day Recovery',
    'Post-Push Day Recovery - 2w 3x/wk',
    'Med',
    false,
    'Recovery work after chest and shoulder sessions targeting pecs, triceps, and thoracic spine',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Push Day Recovery'
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
    'Week 2 - Peak',
    '[{"workout_name": "Post-Push Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Pecs", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Lie face down on roller angled under pec", "substitution": "Lacrosse Ball Pec Release"}, {"name": "Doorway Pec Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm at 90 degrees in doorframe, step through", "substitution": "Floor Pec Stretch"}, {"name": "Overhead Tricep Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Reach behind head, use other hand to press elbow", "substitution": "Tricep Wall Stretch"}, {"name": "Foam Roll Triceps", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Arm extended, roll from elbow to armpit area", "substitution": "Lacrosse Ball Tricep"}, {"name": "Prone Y-T-W Raises", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Light or no weight", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rear Deltoid", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Lie face down, arms in Y then T then W shapes", "substitution": "Band Pull-Apart"}, {"name": "Thoracic Rotation", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Side-lying, rotate top arm open to the floor", "substitution": "Seated Thoracic Rotation"}]}, {"workout_name": "Post-Push Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Pecs", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Lie face down on roller angled under pec", "substitution": "Lacrosse Ball Pec Release"}, {"name": "Doorway Pec Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm at 90 degrees in doorframe, step through", "substitution": "Floor Pec Stretch"}, {"name": "Overhead Tricep Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Reach behind head, use other hand to press elbow", "substitution": "Tricep Wall Stretch"}, {"name": "Foam Roll Triceps", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Arm extended, roll from elbow to armpit area", "substitution": "Lacrosse Ball Tricep"}, {"name": "Prone Y-T-W Raises", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Light or no weight", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rear Deltoid", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Lie face down, arms in Y then T then W shapes", "substitution": "Band Pull-Apart"}, {"name": "Thoracic Rotation", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Side-lying, rotate top arm open to the floor", "substitution": "Seated Thoracic Rotation"}]}]'::jsonb,
    'Post-Push Day Recovery',
    'Post-Push Day Recovery - 2w 3x/wk',
    'Med',
    false,
    'Recovery work after chest and shoulder sessions targeting pecs, triceps, and thoracic spine',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Push Day Recovery'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;
