-- Program: Feeling Restless
-- Category: Mood & Emotion Based -> mood_based
-- Priority: Med
-- Durations: [1, 2], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Feeling Restless',
    'Burn off excess energy with dynamic challenging movement',
    'mood_based',
    'all_levels',
    2,
    4,
    'custom',
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
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

-- Variant: Feeling Restless - 1w 3x/wk
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
    'Feeling Restless - 1w 3x/wk',
    'mood_based',
    3,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Feeling Restless'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Feeling Restless',
    'Feeling Restless - 1w 3x/wk',
    'Med',
    false,
    'Burn off excess energy with dynamic challenging movement',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Feeling Restless'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Feeling Restless - 1w 4x/wk
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
    'Feeling Restless - 1w 4x/wk',
    'mood_based',
    4,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Feeling Restless'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Feeling Restless',
    'Feeling Restless - 1w 4x/wk',
    'Med',
    false,
    'Burn off excess energy with dynamic challenging movement',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Feeling Restless'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Feeling Restless - 2w 3x/wk
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
    'Feeling Restless - 2w 3x/wk',
    'mood_based',
    3,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Feeling Restless'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Feeling Restless',
    'Feeling Restless - 2w 3x/wk',
    'Med',
    false,
    'Burn off excess energy with dynamic challenging movement',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Feeling Restless'
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
    '[{"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Feeling Restless',
    'Feeling Restless - 2w 3x/wk',
    'Med',
    false,
    'Burn off excess energy with dynamic challenging movement',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Feeling Restless'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Feeling Restless - 2w 4x/wk
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
    'Feeling Restless - 2w 4x/wk',
    'mood_based',
    4,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Feeling Restless'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Feeling Restless',
    'Feeling Restless - 2w 4x/wk',
    'Med',
    false,
    'Burn off excess energy with dynamic challenging movement',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Feeling Restless'
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
    '[{"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Energy Boost", "type": "conditioning", "duration_minutes": 30, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Calves", "Core"], "difficulty": "beginner", "form_cue": "Full arm extension overhead, rhythmic", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Brisk pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth, pump arms for energy", "substitution": "Wall Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, rhythmic pace", "substitution": "Knee Push-Up"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Moderate pace", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core", "Calves"], "difficulty": "beginner", "form_cue": "Drive knees up, pump arms", "substitution": "Marching"}, {"name": "Plank Shoulder Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Alternate sides", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, touch opposite shoulder", "substitution": "Plank"}]}, {"workout_name": "Rage Channel", "type": "hiit", "duration_minutes": 40, "exercises": [{"name": "Battle Rope Wave", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds max effort", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Legs"], "difficulty": "intermediate", "form_cue": "Alternating waves, slam with purpose", "substitution": "Plank Jack"}, {"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy med ball, max power", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Reach high, slam down with everything", "substitution": "Burpee"}, {"name": "Heavy Bag Punching", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60 seconds per round", "equipment": "Heavy Bag", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms", "Chest"], "difficulty": "intermediate", "form_cue": "Proper form, exhale on each punch", "substitution": "Shadow Boxing"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, power from frustration", "substitution": "Dumbbell Swing"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "All out effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Channel anger into each rep", "substitution": "Squat Thrust"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, decisive, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Feeling Restless',
    'Feeling Restless - 2w 4x/wk',
    'Med',
    false,
    'Burn off excess energy with dynamic challenging movement',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Feeling Restless'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
