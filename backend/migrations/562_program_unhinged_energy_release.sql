-- Program: Unhinged Energy Release
-- Category: Gen Z Vibes -> gen_z
-- Priority: Med
-- Durations: [1, 2], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Unhinged Energy Release',
    'Let that feral energy out safely with maximum intensity',
    'gen_z',
    'all_levels',
    2,
    4,
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

-- Variant: Unhinged Energy Release - 1w 3x/wk
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
    'Unhinged Energy Release - 1w 3x/wk',
    'gen_z',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Unhinged Energy Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}]'::jsonb,
    'Unhinged Energy Release',
    'Unhinged Energy Release - 1w 3x/wk',
    'Med',
    false,
    'Let that feral energy out safely with maximum intensity',
    'Gen Z Vibes'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Unhinged Energy Release'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Unhinged Energy Release - 1w 4x/wk
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
    'Unhinged Energy Release - 1w 4x/wk',
    'gen_z',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Unhinged Energy Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}]'::jsonb,
    'Unhinged Energy Release',
    'Unhinged Energy Release - 1w 4x/wk',
    'Med',
    false,
    'Let that feral energy out safely with maximum intensity',
    'Gen Z Vibes'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Unhinged Energy Release'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Unhinged Energy Release - 2w 3x/wk
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
    'Unhinged Energy Release - 2w 3x/wk',
    'gen_z',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Unhinged Energy Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}]'::jsonb,
    'Unhinged Energy Release',
    'Unhinged Energy Release - 2w 3x/wk',
    'Med',
    false,
    'Let that feral energy out safely with maximum intensity',
    'Gen Z Vibes'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Unhinged Energy Release'
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
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}]'::jsonb,
    'Unhinged Energy Release',
    'Unhinged Energy Release - 2w 3x/wk',
    'Med',
    false,
    'Let that feral energy out safely with maximum intensity',
    'Gen Z Vibes'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Unhinged Energy Release'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Unhinged Energy Release - 2w 4x/wk
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
    'Unhinged Energy Release - 2w 4x/wk',
    'gen_z',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Unhinged Energy Release'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}]'::jsonb,
    'Unhinged Energy Release',
    'Unhinged Energy Release - 2w 4x/wk',
    'Med',
    false,
    'Let that feral energy out safely with maximum intensity',
    'Gen Z Vibes'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Unhinged Energy Release'
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
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}]'::jsonb,
    'Unhinged Energy Release',
    'Unhinged Energy Release - 2w 4x/wk',
    'Med',
    false,
    'Let that feral energy out safely with maximum intensity',
    'Gen Z Vibes'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Unhinged Energy Release'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
