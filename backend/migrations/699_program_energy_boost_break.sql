-- Program: Energy Boost Break
-- Category: Desk Break Micro-Workouts -> desk_break
-- Priority: High
-- Durations: [1, 2, 4], Sessions: [3, 4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Energy Boost Break',
    'Quick movement to fight afternoon energy slump',
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

-- Variant: Energy Boost Break - 1w 3x/wk
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
    'Energy Boost Break - 1w 3x/wk',
    'desk_break',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Energy Boost Break'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 1w 3x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Energy Boost Break - 1w 4x/wk
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
    'Energy Boost Break - 1w 4x/wk',
    'desk_break',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Energy Boost Break'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 1w 4x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Energy Boost Break - 1w 5x/wk
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
    'Energy Boost Break - 1w 5x/wk',
    'desk_break',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Energy Boost Break'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 1w 5x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Energy Boost Break - 2w 3x/wk
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
    'Energy Boost Break - 2w 3x/wk',
    'desk_break',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Energy Boost Break'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 2w 3x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 2w 3x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Energy Boost Break - 2w 4x/wk
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
    'Energy Boost Break - 2w 4x/wk',
    'desk_break',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Energy Boost Break'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 2w 4x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 2w 4x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Energy Boost Break - 2w 5x/wk
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
    'Energy Boost Break - 2w 5x/wk',
    'desk_break',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Energy Boost Break'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Expand: add variety and duration to breaks',
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 2w 5x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 2w 5x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Energy Boost Break - 4w 3x/wk
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
    'Energy Boost Break - 4w 3x/wk',
    'desk_break',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Energy Boost Break'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Habit: build consistent micro-break habits',
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 3x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 3x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 3x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 3x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Energy Boost Break - 4w 4x/wk
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
    'Energy Boost Break - 4w 4x/wk',
    'desk_break',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Energy Boost Break'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Habit: build consistent micro-break habits',
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 4x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 4x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 4x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 4x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Energy Boost Break - 4w 5x/wk
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
    'Energy Boost Break - 4w 5x/wk',
    'desk_break',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Energy Boost Break'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Habit: build consistent micro-break habits',
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 5x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 5x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 5x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
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
    '[{"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}, {"workout_name": "Energy Boost Break", "type": "circuit", "duration_minutes": 3, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "beginner", "form_cue": "Get heart rate up quickly", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick squats, pump blood to legs", "substitution": "Chair Squat"}, {"name": "Arm Swing", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Dynamic big swings", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Back"], "difficulty": "beginner", "form_cue": "Cross arms in front, swing wide, rhythmic", "substitution": "Arm Circle"}, {"name": "March in Place", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "High knees pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Exaggerated marching, pump arms", "substitution": "Walking"}]}]'::jsonb,
    'Energy Boost Break',
    'Energy Boost Break - 4w 5x/wk',
    'High',
    false,
    'Quick movement to fight afternoon energy slump',
    'Desk Break Micro-Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Energy Boost Break'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
