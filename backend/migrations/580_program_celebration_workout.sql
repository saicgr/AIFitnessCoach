-- Program: Celebration Workout
-- Category: Mood & Emotion Based -> mood_based
-- Priority: Low
-- Durations: [1, 2], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Celebration Workout',
    'Move when you are feeling great and want to keep the energy high',
    'mood_based',
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

-- Variant: Celebration Workout - 1w 3x/wk
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
    'Celebration Workout - 1w 3x/wk',
    'mood_based',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Celebration Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}]'::jsonb,
    'Celebration Workout',
    'Celebration Workout - 1w 3x/wk',
    'Low',
    false,
    'Move when you are feeling great and want to keep the energy high',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Celebration Workout'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Celebration Workout - 1w 4x/wk
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
    'Celebration Workout - 1w 4x/wk',
    'mood_based',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Celebration Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}]'::jsonb,
    'Celebration Workout',
    'Celebration Workout - 1w 4x/wk',
    'Low',
    false,
    'Move when you are feeling great and want to keep the energy high',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Celebration Workout'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Celebration Workout - 2w 3x/wk
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
    'Celebration Workout - 2w 3x/wk',
    'mood_based',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Celebration Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}]'::jsonb,
    'Celebration Workout',
    'Celebration Workout - 2w 3x/wk',
    'Low',
    false,
    'Move when you are feeling great and want to keep the energy high',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Celebration Workout'
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
    '[{"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}]'::jsonb,
    'Celebration Workout',
    'Celebration Workout - 2w 3x/wk',
    'Low',
    false,
    'Move when you are feeling great and want to keep the energy high',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Celebration Workout'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Celebration Workout - 2w 4x/wk
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
    'Celebration Workout - 2w 4x/wk',
    'mood_based',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Celebration Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}]'::jsonb,
    'Celebration Workout',
    'Celebration Workout - 2w 4x/wk',
    'Low',
    false,
    'Move when you are feeling great and want to keep the energy high',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Celebration Workout'
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
    '[{"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "No Cap HIIT", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up, jump and clap", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Explosive", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, maximum jump height, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Sprint pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Fast knee drives in plank position", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Snap hips, power from glutes", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate to high box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive jump, soft landing, step down", "substitution": "Squat Jump"}, {"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay in athletic stance", "substitution": "Plank Jack"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}]'::jsonb,
    'Celebration Workout',
    'Celebration Workout - 2w 4x/wk',
    'Low',
    false,
    'Move when you are feeling great and want to keep the energy high',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Celebration Workout'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
