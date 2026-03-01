-- Program: Prison Yard
-- Category: Hell Mode -> hell_mode
-- Priority: High
-- Durations: [1, 2], Sessions: [6, 7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Prison Yard',
    'Bodyweight-only extreme training, no equipment needed',
    'hell_mode',
    'advanced',
    2,
    7,
    'full_body',
    ARRAY['Build functional strength', 'Improve body control']::text[],
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

-- Variant: Prison Yard - 1w 6x/wk
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
    'Prison Yard - 1w 6x/wk',
    'hell_mode',
    6,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Prison Yard'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}]'::jsonb,
    'Prison Yard',
    'Prison Yard - 1w 6x/wk',
    'High',
    false,
    'Bodyweight-only extreme training, no equipment needed',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Prison Yard'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: Prison Yard - 1w 7x/wk
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
    'Prison Yard - 1w 7x/wk',
    'hell_mode',
    7,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Prison Yard'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}]'::jsonb,
    'Prison Yard',
    'Prison Yard - 1w 7x/wk',
    'High',
    false,
    'Bodyweight-only extreme training, no equipment needed',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Prison Yard'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: Prison Yard - 2w 6x/wk
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
    'Prison Yard - 2w 6x/wk',
    'hell_mode',
    6,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Prison Yard'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}]'::jsonb,
    'Prison Yard',
    'Prison Yard - 2w 6x/wk',
    'High',
    false,
    'Bodyweight-only extreme training, no equipment needed',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Prison Yard'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Conquer: break through mental and physical barriers',
    '[{"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}]'::jsonb,
    'Prison Yard',
    'Prison Yard - 2w 6x/wk',
    'High',
    false,
    'Bodyweight-only extreme training, no equipment needed',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Prison Yard'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: Prison Yard - 2w 7x/wk
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
    'Prison Yard - 2w 7x/wk',
    'hell_mode',
    7,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Prison Yard'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}]'::jsonb,
    'Prison Yard',
    'Prison Yard - 2w 7x/wk',
    'High',
    false,
    'Bodyweight-only extreme training, no equipment needed',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Prison Yard'
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
    'Week 2 - Conquer: break through mental and physical barriers',
    '[{"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}, {"workout_name": "Prison Yard", "type": "hell_mode", "duration_minutes": 45, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 10, "reps": 10, "rest_seconds": 15, "weight_guidance": "100 total, partition as needed", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "advanced", "form_cue": "Chest to floor, jump up, count every one", "substitution": "Squat Thrust"}, {"name": "Diamond Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 20, "weight_guidance": "Hands together", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Triceps", "secondary_muscles": ["Pectoralis Major", "Core"], "difficulty": "advanced", "form_cue": "Thumbs and index fingers form diamond, chest to hands", "substitution": "Close-Grip Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "250 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Full depth, chest up, no stopping at top", "substitution": "Half Squat"}, {"name": "Handstand Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 8, "rest_seconds": 30, "weight_guidance": "Against wall", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core", "Trapezius"], "difficulty": "advanced", "form_cue": "Head to floor, press to full lockout", "substitution": "Pike Push-Up"}, {"name": "Pistol Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core", "Hamstrings"], "difficulty": "advanced", "form_cue": "Single leg, full depth, opposite leg straight", "substitution": "Assisted Pistol"}, {"name": "Planche Lean Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Chest"], "difficulty": "advanced", "form_cue": "Lean forward in plank, shift weight to hands", "substitution": "Plank Lean"}]}]'::jsonb,
    'Prison Yard',
    'Prison Yard - 2w 7x/wk',
    'High',
    false,
    'Bodyweight-only extreme training, no equipment needed',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Prison Yard'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
