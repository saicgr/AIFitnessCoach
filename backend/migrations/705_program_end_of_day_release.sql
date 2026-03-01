-- Program: End of Day Release
-- Category: Desk Break Micro-Workouts -> desk_break
-- Priority: High
-- Durations: [1, 2, 4], Sessions: [3, 4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'End of Day Release',
    'Unwind tension accumulated from a full day at the desk',
    'desk_break',
    'all_levels',
    4,
    5,
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

-- Variant: End of Day Release - 1w 3x/wk
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
    'End of Day Release - 1w 3x/wk',
    'desk_break',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'End of Day Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 1w 3x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: End of Day Release - 1w 4x/wk
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
    'End of Day Release - 1w 4x/wk',
    'desk_break',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'End of Day Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 1w 4x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: End of Day Release - 1w 5x/wk
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
    'End of Day Release - 1w 5x/wk',
    'desk_break',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'End of Day Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 1w 5x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: End of Day Release - 2w 3x/wk
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
    'End of Day Release - 2w 3x/wk',
    'desk_break',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'End of Day Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 2w 3x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 2 - Optimize: personalized break schedule for peak productivity',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 2w 3x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: End of Day Release - 2w 4x/wk
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
    'End of Day Release - 2w 4x/wk',
    'desk_break',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'End of Day Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 2w 4x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 2 - Optimize: personalized break schedule for peak productivity',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 2w 4x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: End of Day Release - 2w 5x/wk
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
    'End of Day Release - 2w 5x/wk',
    'desk_break',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'End of Day Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 2w 5x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 2 - Optimize: personalized break schedule for peak productivity',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 2w 5x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: End of Day Release - 4w 3x/wk
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
    'End of Day Release - 4w 3x/wk',
    'desk_break',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'End of Day Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Habit: build consistent micro-break habits',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 3x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 2 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 3x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 3 - Optimize: personalized break schedule for peak productivity',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 3x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 4 - Optimize: personalized break schedule for peak productivity',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 3x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: End of Day Release - 4w 4x/wk
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
    'End of Day Release - 4w 4x/wk',
    'desk_break',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'End of Day Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Habit: build consistent micro-break habits',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 4x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 2 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 4x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 3 - Optimize: personalized break schedule for peak productivity',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 4x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 4 - Optimize: personalized break schedule for peak productivity',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 4x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: End of Day Release - 4w 5x/wk
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
    'End of Day Release - 4w 5x/wk',
    'desk_break',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'End of Day Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Habit: build consistent micro-break habits',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 5x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 2 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 5x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 3 - Optimize: personalized break schedule for peak productivity',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 5x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
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
    'Week 4 - Optimize: personalized break schedule for peak productivity',
    '[{"workout_name": "Chair Yoga Break", "type": "yoga", "duration_minutes": 5, "exercises": [{"name": "Seated Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow with breath", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Hands on knees, arch and round spine", "substitution": "Standing Cat-Cow"}, {"name": "Seated Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Chair", "body_part": "Back", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Fold forward from hips, let arms hang", "substitution": "Standing Forward Fold"}, {"name": "Seated Eagle Arms", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 sec each side", "equipment": "Chair", "body_part": "Shoulders", "primary_muscle": "Rhomboids", "secondary_muscles": ["Deltoids", "Trapezius"], "difficulty": "beginner", "form_cue": "Cross arms, wrap forearms, lift elbows", "substitution": "Seated Arm Cross"}, {"name": "Seated Pigeon", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 sec each side", "equipment": "Chair", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, lean forward", "substitution": "Seated Figure-4"}, {"name": "Seated Side Bend", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Chair", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Latissimus Dorsi"], "difficulty": "beginner", "form_cue": "Reach overhead, bend to side", "substitution": "Standing Side Bend"}]}, {"workout_name": "Posture Reset Break", "type": "flexibility", "duration_minutes": 3, "exercises": [{"name": "Chin Tuck", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make a double chin", "substitution": "Neck Stretch"}, {"name": "Shoulder Blade Squeeze", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 12, "rest_seconds": 0, "weight_guidance": "Hold 5 seconds each", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius", "Rear Deltoid"], "difficulty": "beginner", "form_cue": "Squeeze blades together and down, open chest", "substitution": "Band Pull-Apart"}, {"name": "Wall Angel", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Rhomboids", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up and down", "substitution": "Seated Y-Raise"}, {"name": "Standing Chest Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe, lean through", "substitution": "Seated Chest Opener"}]}, {"workout_name": "2-Min Desk Stretch", "type": "flexibility", "duration_minutes": 2, "exercises": [{"name": "Neck Side Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Ear toward shoulder, gentle hand pressure", "substitution": "Neck Roll"}, {"name": "Seated Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, squeeze shoulder blades", "substitution": "Doorway Stretch"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, twist from thoracic spine, breathe", "substitution": "Standing Twist"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 sec each hand", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'End of Day Release',
    'End of Day Release - 4w 5x/wk',
    'High',
    false,
    'Unwind tension accumulated from a full day at the desk',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'End of Day Release'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
